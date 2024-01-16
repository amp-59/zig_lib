//! Example build program. Use `zig_lib/support/switch_build_runner.sh` to
//! switch build runner or use `zig build --build-runner zig_lib/build_runner.zig`.

// This has to be public so that the zl.builder runner can use the build import.
// The standard does not require this, as it is implicitly available as
// a module and can import itself from anywhere.
pub const zl = @import("zig_lib/zig_lib.zig");

const spec = zl.spec;
const build = zl.builder;

pub const Builder: type = build.GenericBuilder(.{});

/// This is a template compile command to build the target.
var build_cmd: build.BuildCommand = .{
    .kind = .exe,
};
var mod_cmd: build.BuildCommand.Module = .{
    .mode = .ReleaseFast,
    .deps = &.{.{ .name = "zig_lib" }},
};

// zl looks for `buildMain` instead of `build` or `main`, because `main` is
// actually in build_runner.zig and might be useful for the name of one of the
// target (as below), and `build` is the name of import containing build system
// components.
pub fn buildMain(allocator: *build.types.Allocator, top: *Builder.Node) !void {
    const main: *Builder.Node = top.addBuild(allocator, build_cmd, mod_cmd, "main", "./src/main.zig");
    main.descr = "Main project binary";
    main.addModule(allocator, .{ .name = "zig_lib" }, "zig_lib/zig_lib.zig");
}
