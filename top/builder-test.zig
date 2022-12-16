const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const builder = @import("./builder.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = true;

fn globalCacheDir(vars: [][*:0]u8, buf: [:0]u8) ![:0]u8 {
    const home_pathname: [:0]const u8 = try file.home(vars);
    var len: u64 = 0;
    for (home_pathname) |c, i| buf[len + i] = c;
    len += home_pathname.len;
    for ("/.cache/zig") |c, i| buf[len + i] = c;
    return buf[0 .. len + 11 :0];
}
const thread_spec = proc.CloneSpec{
    .errors = sys.clone_errors,
    .return_type = void,
    .options = .{
        .address_space = true,
        .thread = true,
        .file_system = true,
        .files = true,
        .signal_handlers = true,
        .sysvsem = true,
        .set_thread_local_storage = true,
        .set_parent_thread_id = true,
        .set_child_thread_id = true,
        .clear_child_thread_id = true,
        .io = false,
    },
};
fn runTest(vars: [][*:0]u8, name: [:0]const u8, pathname: [:0]const u8) !void {
    var global_cache_dir_buf: [4096:0]u8 = .{0} ** 4096;
    var cmd: builder.BuildCmd = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = .ReleaseFast,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = builtin.lib_build_root ++ "/zig-cache",
        .macros = &.{
            .{ .name = "is_verbose", .value = "0" },
            .{ .name = "is_correct", .value = "1" },
            .{ .name = "build_root", .value = "\"" ++ builtin.build_root.? ++ "\"" },
        },
    };
    _ = try cmd.executeS(vars);
}
pub fn main(_: [][*:0]u8, vars: [][*:0]u8) !void {
    const arg_set = .{
        .{ vars, "builtin_test", "top/builtin-test.zig" },
        .{ vars, "elf_test", "test/readelf.zig" },
        .{ vars, "mem_test", "top/mem-test.zig" },
        .{ vars, "file_test", "top/file-test.zig" },
        .{ vars, "fmt_test", "top/fmt-test.zig" },
        .{ vars, "list_test", "top/list-test.zig" },
    };
    inline for (arg_set) |args| {
        try @call(.auto, runTest, args);
    }
}
