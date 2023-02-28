//! Example build program. Use `zig_lib/support/switch_build_runner.sh` to
//! switch build runner.

// This has to be public so that the zl build runner can use the build import.
// The standard does not require this, as it is implicitly available as
// a module and can import itself from anywhere.
pub const zig_lib = @import("zig_lib/zig_lib.zig");

const build = zig_lib.build;

// zl dependencies and modules:
const deps: []const []const u8 = &.{"zig_lib"};
const mods: []const build.Module = &.{.{
    .name = "zig_lib",
    .path = "zig_lib/zig_lib.zig",
}};
const basic_target_spec: build.TargetSpec = .{
    .mods = mods,
    .deps = deps,
};

// zl looks for `buildMain` instead of `build` or `main`, because `main` is
// actually in build_runner.zig and might be useful for the name of one of the
// target (as below), and `build` is the name of import containing build system
// components.
pub fn buildMain(allocator: *build.Allocator, builder: *build.Builder) !void {
    const main: *build.Target = builder.addTarget(basic_target_spec, allocator, "main", "./src/main.zig");

    main.addFormat(allocator, .{});
}
