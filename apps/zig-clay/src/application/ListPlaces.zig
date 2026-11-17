//! Use case: sidebar shortcuts and the starting location.

const std = @import("std");
const domain = @import("../domain/domain.zig");

const ListPlaces = @This();

provider: domain.ports.PlacesProvider,

pub fn execute(self: ListPlaces, gpa: std.mem.Allocator) error{OutOfMemory}![]domain.Place {
    return self.provider.places(gpa);
}

pub fn startLocation(self: ListPlaces) domain.DirectoryPath {
    return self.provider.home();
}
