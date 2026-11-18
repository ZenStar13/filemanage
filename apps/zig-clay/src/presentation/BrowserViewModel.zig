//! View model of the browser screen (immediate-mode MVVM): views read its
//! state through `*const` access every frame and emit `Intent`s; `apply` is
//! the only mutation entry point and `tick` integrates background loads.
//! No Clay or raylib code lives here.

const std = @import("std");
const core = @import("core");
const Intent = @import("Intent.zig").Intent;
const TextField = @import("TextField.zig");

const domain = core.domain;
const BrowseDirectory = core.application.BrowseDirectory;
const Io = std.Io;

const BrowserViewModel = @This();

const Navigation = enum { visit, back, forward, reload };

/// Mailbox shared with worker threads. Reference-counted so a worker may
/// finish after the view model is gone (e.g. a slow mount while quitting).
const Inbox = struct {
    mutex: Io.Mutex = .init,
    latest: ?Completed = null,
    refs: std.atomic.Value(u32) = .init(1),

    const Completed = struct {
        ticket: u64,
        result: domain.FsError!domain.DirectoryListing,
    };

    fn release(inbox: *Inbox, gpa: std.mem.Allocator) void {
        if (inbox.refs.fetchSub(1, .acq_rel) != 1) return;
        if (inbox.latest) |*done| if (done.result) |*listing| listing.deinit() else |_| {};
        gpa.destroy(inbox);
    }
};

gpa: std.mem.Allocator,
io: Io,
browse: BrowseDirectory,
history: domain.NavigationHistory,
places: []domain.Place,
free_places: *const fn (std.mem.Allocator, []domain.Place) void,
listing: ?domain.DirectoryListing = null,
visibility: domain.Visibility = .hide_hidden,
/// Index into `listing.entries` (stable across visibility toggles).
selected: ?usize = null,
error_message: ?[]u8 = null,
loading: bool = false,
ticket: u64 = 0,
pending: Navigation = .reload,
/// Bumped when the keyboard moves the selection, so the list can reveal it.
reveal_revision: u64 = 0,
inbox: *Inbox,
/// Home folder (owned copy), for Go → Home and `~` in the location bar.
home: domain.DirectoryPath,
/// Text input of the location row; meaningful while `editing_location`.
location: TextField,
editing_location: bool = false,
/// Path of the latest request, for error messages.
last_request: [std.fs.max_path_bytes]u8 = undefined,
last_request_len: usize = 0,

pub const Dependencies = struct {
    gpa: std.mem.Allocator,
    io: Io,
    browse: BrowseDirectory,
    places: core.application.ListPlaces,
    free_places: *const fn (std.mem.Allocator, []domain.Place) void,
};

pub fn init(deps: Dependencies) !BrowserViewModel {
    const inbox = try deps.gpa.create(Inbox);
    inbox.* = .{};
    var vm: BrowserViewModel = .{
        .gpa = deps.gpa,
        .io = deps.io,
        .browse = deps.browse,
        .history = try .init(deps.gpa, deps.places.startLocation()),
        .places = try deps.places.execute(deps.gpa),
        .home = try deps.places.startLocation().dupe(deps.gpa),
        .location = .{ .gpa = deps.gpa },
        .free_places = deps.free_places,
        .inbox = inbox,
    };
    vm.load(vm.history.current, .reload);
    return vm;
}

pub fn deinit(self: *BrowserViewModel) void {
    if (self.listing) |*listing| listing.deinit();
    if (self.error_message) |m| self.gpa.free(m);
    self.free_places(self.gpa, self.places);
    self.history.deinit();
    self.location.deinit();
    self.gpa.free(self.home.value);
    self.inbox.release(self.gpa);
    self.* = undefined;
}

// ---- State ------------------------------------------------------------------

pub fn current(self: *const BrowserViewModel) domain.DirectoryPath {
    return self.history.current;
}

pub fn entries(self: *const BrowserViewModel) []const domain.FileEntry {
    return if (self.listing) |l| l.entries else &.{};
}

pub fn isVisible(self: *const BrowserViewModel, entry: domain.FileEntry) bool {
    return domain.DirectoryListing.isVisible(entry, self.visibility);
}

pub fn visibleCount(self: *const BrowserViewModel) usize {
    return if (self.listing) |l| l.visibleCount(self.visibility) else 0;
}

pub fn summary(self: *const BrowserViewModel) ?domain.Summary {
    return if (self.listing) |l| l.summary(self.visibility) else null;
}

pub fn showsHidden(self: *const BrowserViewModel) bool {
    return self.visibility == .show_hidden;
}

/// Position of the selection among *visible* rows.
pub fn selectedRow(self: *const BrowserViewModel) ?usize {
    const selected = self.selected orelse return null;
    var row: usize = 0;
    for (self.entries(), 0..) |entry, index| {
        if (!self.isVisible(entry)) continue;
        if (index == selected) return row;
        row += 1;
    }
    return null;
}

// ---- Behaviour ----------------------------------------------------------------

pub fn apply(self: *BrowserViewModel, intent: Intent) void {
    switch (intent) {
        .open => |path| self.load(path, .visit),
        .back => if (self.history.peekBack()) |path| self.load(path, .back),
        .forward => if (self.history.peekForward()) |path| self.load(path, .forward),
        .up => if (self.history.current.parent()) |path| self.load(path, .visit),
        .refresh => self.load(self.history.current, .reload),
        .toggle_hidden => {
            self.visibility = self.visibility.toggled();
            if (self.selected) |i| if (!self.isVisible(self.entries()[i])) {
                self.selected = null;
            };
        },
        .dismiss_error => self.setError(null),
        .select => |index| self.selected = index,
        .activate => |index| self.activate(index),
        .activate_selection => if (self.selected) |index| self.activate(index),
        .move_selection => |delta| self.moveSelection(delta),
        .go_home => self.load(self.home, .visit),
        .start_edit_location => {
            self.location.reset(self.history.current.value) catch return self.setError("Out of memory");
            self.editing_location = true;
        },
        .edit_location => |edit| if (self.editing_location) {
            self.location.apply(edit) catch self.setError("Out of memory");
        },
        .submit_location => self.submitLocation(),
        .cancel => {
            if (self.editing_location) {
                self.editing_location = false;
            } else {
                self.setError(null);
            }
        },
    }
}

/// Integrates the newest finished load, if any. Call once per frame.
pub fn tick(self: *BrowserViewModel) void {
    const completed = blk: {
        self.inbox.mutex.lockUncancelable(self.io);
        defer self.inbox.mutex.unlock(self.io);
        const latest = self.inbox.latest orelse return;
        if (latest.ticket != self.ticket) return; // Still waiting for the newest request.
        self.inbox.latest = null;
        break :blk latest;
    };
    self.loading = false;

    if (completed.result) |listing| {
        self.commit(listing.path) catch {
            var owned = listing;
            owned.deinit();
            self.setError("Out of memory");
            return;
        };
        if (self.listing) |*old| old.deinit();
        self.listing = listing;
        self.selected = null;
        self.editing_location = false;
        self.setError(null);
    } else |err| {
        var buffer: [1024]u8 = undefined;
        self.setError(domain.describeError(err, self.pendingPathForError(), &buffer));
    }
}

fn submitLocation(self: *BrowserViewModel) void {
    self.editing_location = false;
    const resolved = domain.DirectoryPath.resolveUserInput(self.gpa, self.location.text(), self.history.current, self.home) catch
        return self.setError("Out of memory");
    const destination = resolved orelse return;
    defer self.gpa.free(destination.value);
    self.load(destination, .visit);
}

fn pendingPathForError(self: *const BrowserViewModel) []const u8 {
    return self.last_request[0..self.last_request_len];
}

fn commit(self: *BrowserViewModel, destination: domain.DirectoryPath) !void {
    switch (self.pending) {
        .visit => try self.history.visit(destination),
        .back => _ = try self.history.goBack(),
        .forward => _ = try self.history.goForward(),
        .reload => {},
    }
}

fn setError(self: *BrowserViewModel, message: ?[]const u8) void {
    if (self.error_message) |m| self.gpa.free(m);
    self.error_message = if (message) |m| self.gpa.dupe(u8, m) catch null else null;
}

fn activate(self: *BrowserViewModel, index: usize) void {
    const all = self.entries();
    if (index >= all.len) return;
    const entry = all[index];
    if (!entry.isNavigable()) {
        self.selected = index; // Opening files is out of scope for this draft.
        return;
    }
    var buffer: [std.fs.max_path_bytes]u8 = undefined;
    const joined = if (self.history.current.isRoot())
        std.fmt.bufPrint(&buffer, "/{s}", .{entry.name})
    else
        std.fmt.bufPrint(&buffer, "{s}/{s}", .{ self.history.current.value, entry.name });
    const path = joined catch return;
    if (domain.DirectoryPath.init(path)) |destination| self.load(destination, .visit);
}

fn moveSelection(self: *BrowserViewModel, delta: i32) void {
    const count = self.visibleCount();
    if (count == 0) return;
    const current_row: i64 = if (self.selectedRow()) |r| @intCast(r) else -1;
    const target_row: usize = if (current_row < 0) 0 else @intCast(std.math.clamp(current_row + delta, 0, @as(i64, @intCast(count - 1))));
    var row: usize = 0;
    for (self.entries(), 0..) |entry, index| {
        if (!self.isVisible(entry)) continue;
        if (row == target_row) {
            self.selected = index;
            self.reveal_revision += 1;
            return;
        }
        row += 1;
    }
}

/// Starts a background read. History is committed in `tick` only if the
/// load succeeds and is still the newest request.
fn load(self: *BrowserViewModel, path: domain.DirectoryPath, navigation: Navigation) void {
    const owned = self.gpa.dupe(u8, path.value) catch return self.setError("Out of memory");
    self.last_request_len = @min(path.value.len, self.last_request.len);
    @memcpy(self.last_request[0..self.last_request_len], path.value[0..self.last_request_len]);

    self.ticket += 1;
    self.pending = navigation;
    self.loading = true;

    _ = self.inbox.refs.fetchAdd(1, .monotonic);
    const thread = std.Thread.spawn(.{}, work, .{ self.inbox, self.browse, self.io, self.gpa, self.ticket, owned }) catch {
        self.inbox.release(self.gpa);
        self.gpa.free(owned);
        self.loading = false;
        return self.setError("Could not start a background task");
    };
    thread.detach();
}

fn work(inbox: *Inbox, browse: BrowseDirectory, io: Io, gpa: std.mem.Allocator, ticket: u64, path: []u8) void {
    defer inbox.release(gpa);
    defer gpa.free(path);
    var result = browse.execute(.{ .value = path });

    inbox.mutex.lockUncancelable(io);
    defer inbox.mutex.unlock(io);
    if (inbox.latest) |*older| {
        if (older.ticket > ticket) {
            if (result) |*listing| listing.deinit() else |_| {}
            return;
        }
        if (older.result) |*listing| listing.deinit() else |_| {}
    }
    inbox.latest = .{ .ticket = ticket, .result = result };
}
