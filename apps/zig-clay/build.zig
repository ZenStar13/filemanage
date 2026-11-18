const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // ---- Core: domain + application + infrastructure (no UI deps) ----------
    // Kept as its own module so the dependency rule is enforced by the build:
    // the core cannot import raylib or clay.
    const core = b.createModule(.{
        .root_source_file = b.path("src/core.zig"),
        .target = target,
        .optimize = optimize,
    });

    // ---- UI dependencies ----------------------------------------------------
    const zclay_dep = b.dependency("zclay", .{ .target = target, .optimize = optimize });
    const raylib_dep = b.dependency("raylib_zig", .{ .target = target, .optimize = optimize });
    const renderer = zclay_dep.module("renderer_raylib");
    renderer.addImport("raylib", raylib_dep.module("raylib"));

    // The shared font lives at the repository root; expose it as an import so
    // it can be embedded with @embedFile.
    const font = b.createModule(.{ .root_source_file = b.path("../../assets/fonts/0xProtoNerdFont-Regular.ttf") });
    const font_bold = b.createModule(.{ .root_source_file = b.path("../../assets/fonts/0xProtoNerdFont-Bold.ttf") });

    // ---- Executable (presentation + platform + composition root) -----------
    const exe_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{
            .{ .name = "core", .module = core },
            .{ .name = "zclay", .module = zclay_dep.module("zclay") },
            .{ .name = "raylib", .module = raylib_dep.module("raylib") },
            .{ .name = "renderer_raylib", .module = renderer },
            .{ .name = "font_regular", .module = font },
            .{ .name = "font_bold", .module = font_bold },
        },
    });
    exe_module.linkLibrary(raylib_dep.artifact("raylib"));

    const exe = b.addExecutable(.{ .name = "fm-clay", .root_module = exe_module });
    b.installArtifact(exe);

    const run = b.addRunArtifact(exe);
    run.step.dependOn(b.getInstallStep());
    run.addPassthruArgs();
    b.step("run", "Run the file manager").dependOn(&run.step);

    // ---- Tests ---------------------------------------------------------------
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&b.addRunArtifact(b.addTest(.{ .root_module = core })).step);
    const presentation_tests = b.addTest(.{ .root_module = b.createModule(.{
        .root_source_file = b.path("src/presentation/tests.zig"),
        .target = target,
        .optimize = optimize,
        .imports = &.{.{ .name = "core", .module = core }},
    }) });
    test_step.dependOn(&b.addRunArtifact(presentation_tests).step);
}
