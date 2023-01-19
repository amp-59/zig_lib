pub const build = if (true) @import("build/build-aux.zig").main else main;
pub const srg = @import("./zig_lib.zig");

const mem = srg.mem;
const meta = srg.meta;
const builder = srg.builder;
const builtin = srg.builtin;

const BuildCmd = builder.BuildCmd;

fn relative(ctx: *builder.Context, relative_pathname: [:0]const u8) mem.StaticString(4096) {
    var ret: mem.StaticString(4096) = .{};
    ret.writeMany(ctx.build_root);
    ret.writeOne('/');
    ret.writeMany(relative_pathname);
    return ret;
}
fn macroString(pathname: [:0]const u8) mem.StaticString(4096) {
    var ret: mem.StaticString(4096) = .{};
    ret.writeOne('\"');
    ret.writeMany(pathname);
    ret.writeOne('\"');
    return ret;
}
pub fn main(ctx: *builder.Context) !void {
    var cmds: mem.StaticArray(BuildCmd, 64) = .{};
    const packages = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
    const minor_test_args = .{ .is_correct = true, .is_verbose = true, .packages = packages };
    const algo_test_args = .{ .is_correct = true, .is_verbose = true, .build_mode = .ReleaseSmall, .packages = packages };
    const fmt_test_args = .{ .is_correct = true, .is_verbose = true, .build_mode = .Debug, .packages = packages };
    const fast_test_args = .{ .is_correct = false, .is_verbose = false, .build_mode = .ReleaseFast, .packages = packages };
    const small_test_args = .{ .is_correct = false, .is_verbose = false, .build_mode = .ReleaseSmall, .packages = packages };

    cmds.writeOne(ctx.addExecutable("builtin_test", "top/builtin-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("meta_test", "top/meta-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("mem_test", "top/mem-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("algo_test", "top/algo-test.zig", algo_test_args));
    cmds.writeOne(ctx.addExecutable("file_test", "top/file-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("list_test", "top/list-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("fmt_test", "top/fmt-test.zig", fmt_test_args));
    cmds.writeOne(ctx.addExecutable("render_test", "top/render-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("thread_test", "top/thread-test.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("virtual_test", "top/virtual-test.zig", minor_test_args));

    // More complete test programs:
    cmds.writeOne(ctx.addExecutable("buildgen", "test/buildgen.zig", small_test_args));
    cmds.writeOne(ctx.addExecutable("mca", "test/mca.zig", fast_test_args));
    cmds.writeOne(ctx.addExecutable("treez", "test/treez.zig", small_test_args));
    cmds.writeOne(ctx.addExecutable("itos", "test/itos.zig", small_test_args));
    cmds.writeOne(ctx.addExecutable("cat", "test/cat.zig", fast_test_args));
    cmds.writeOne(ctx.addExecutable("hello", "test/hello.zig", small_test_args));
    cmds.writeOne(ctx.addExecutable("readelf", "test/readelf.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("parsedir", "test/parsedir.zig", fast_test_args));
    cmds.writeOne(ctx.addExecutable("example", "test/example.zig", minor_test_args));
    cmds.writeOne(ctx.addExecutable("page", "test/page.zig", fmt_test_args));

    // Other test programs:
    cmds.writeOne(ctx.addExecutable("impl_test", "top/impl-test.zig", .{ .is_large_test = true }));
    cmds.writeOne(ctx.addExecutable("container_test", "top/container-test.zig", .{ .is_large_test = true }));
    cmds.writeOne(ctx.addExecutable("parse_test", "top/parse-test.zig", .{ .is_correct = true, .is_verbose = true, .is_large_test = true }));

    for (ctx.args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualMany(u8, name, "all")) {
            for (cmds.readAll()) |cmd| {
                _ = try cmd.exec(ctx.vars);
            }
            return;
        }
        for (cmds.readAll()) |cmd| {
            if (cmd.name) |cmd_name| {
                if (mem.testEqualMany(u8, name, cmd_name)) {
                    _ = try cmd.exec(ctx.vars);
                }
            }
        }
    }
}
