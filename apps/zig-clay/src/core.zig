//! Framework-agnostic core of the file manager (hexagonal architecture):
//!
//! * `domain`         – entities, value objects, aggregates and ports. Pure.
//! * `application`    – use cases orchestrating the domain through ports.
//! * `infrastructure` – adapters implementing the ports for Linux.
//!
//! Dependencies point inwards only. The UI lives in a separate module.

pub const domain = @import("domain/domain.zig");
pub const application = @import("application/application.zig");
pub const infrastructure = @import("infrastructure/infrastructure.zig");

test {
    const std = @import("std");
    std.testing.refAllDecls(domain);
    std.testing.refAllDecls(application);
    std.testing.refAllDecls(infrastructure);
}
