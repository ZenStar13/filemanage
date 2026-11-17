//! User intents emitted by views and applied by the view model after the
//! frame has been rendered. Paths are borrowed from view-model state and are
//! only valid until the intent is applied.

const core = @import("core");

pub const Intent = union(enum) {
    open: core.domain.DirectoryPath,
    back,
    forward,
    up,
    refresh,
    toggle_hidden,
    dismiss_error,
    /// Index into the listing's (unfiltered) entries.
    select: usize,
    activate: usize,
    activate_selection,
    move_selection: i32,
};
