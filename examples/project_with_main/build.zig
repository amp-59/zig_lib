//! Example build program. Use `zig_lib/support/switch_build_runner.sh` to
//! switch build runner.

// This has to be public so that the zl build runner can use the build import.
// The standard does not require this, as it is implicitly available as
// a module and can import itself from anywhere.
pub const zig_lib = @import("zig_lib/zig_lib.zig");

const spec = zig_lib.spec;
const build = zig_lib.build;

pub const Builder: type = build.GenericBuilder(spec.builder.default);

/// This is a template compile command to build the target.
var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mods = &.{.{
        .name = "zig_lib",
        .path = "zig_lib/zig_lib.zig",
    }},
    .deps = &.{.{ .name = "zig_lib" }},
};

// zl looks for `buildMain` instead of `build` or `main`, because `main` is
// actually in build_runner.zig and might be useful for the name of one of the
// target (as below), and `build` is the name of import containing build system
// components.
pub fn buildMain(allocator: *Builder.Allocator, builder: *Builder) !void {
    const all: *Builder.Group = try builder.addGroup(allocator, "all");

    _ = try all.addTarget(allocator, .{ .build = build_cmd }, "main", "./src/main.zig");
}
