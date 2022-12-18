const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const thread = @import("./thread.zig");
const builder = @import("./builder.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = true;

const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .logging = mem.alloc_silent });

const try_multi_threaded: bool = false;

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
    var cmd: builder.BuildCmd(.{}) = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = builtin.zig.mode,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = builtin.lib_build_root ++ "/zig-cache",
        .stack = 8388608,
        .macros = &.{
            .{ .name = "is_verbose", .value = "0" },
            .{ .name = "is_correct", .value = "1" },
            .{ .name = "build_root", .value = "\"" ++ builtin.lib_build_root ++ "\"" },
        },
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.exec(vars);
}
fn runTestTestUsingAllocator(vars: [][*:0]u8, allocator: *Allocator, name: [:0]const u8, pathname: [:0]const u8) !void {
    var global_cache_dir_buf: [4096:0]u8 = .{0} ** 4096;
    var cmd: builder.BuildCmd(.{ .Allocator = Allocator }) = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = builtin.zig.mode,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = builtin.lib_build_root ++ "/zig-cache",
        .stack = 8388608,
        .macros = &.{
            .{ .name = "is_verbose", .value = "0" },
            .{ .name = "is_correct", .value = "1" },
            .{ .name = "build_root", .value = "\"" ++ builtin.lib_build_root ++ "\"" },
        },
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.allocateExec(vars, allocator);
}

pub fn main(_: [][*:0]u8, vars: [][*:0]u8) !void {
    {
        const arg_set = .{
            .{ vars, "builtin_test", "top/builtin-test.zig" },
            .{ vars, "elf_test", "test/readelf.zig" },
            .{ vars, "mem_test", "top/mem-test.zig" },
            .{ vars, "file_test", "top/file-test.zig" },
            .{ vars, "fmt_test", "top/fmt-test.zig" },
            .{ vars, "list_test", "top/list-test.zig" },
        };
        inline for (arg_set) |args, i| {
            if (try_multi_threaded) {
                var result: meta.Return(runTest) = undefined;

                try proc.callClone(thread_spec, try thread.map(.{ .options = .{} }, i), &result, runTest, args);
            } else {
                try @call(.auto, runTest, args);
            }
        }
    }
    {
        var address_space: mem.AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        const arg_set = .{
            .{ vars, &allocator, "builtin_test", "top/builtin-test.zig" },
            .{ vars, &allocator, "elf_test", "test/readelf.zig" },
            .{ vars, &allocator, "mem_test", "top/mem-test.zig" },
            .{ vars, &allocator, "file_test", "top/file-test.zig" },
            .{ vars, &allocator, "fmt_test", "top/fmt-test.zig" },
            .{ vars, &allocator, "list_test", "top/list-test.zig" },
        };
        inline for (arg_set) |args, i| {
            if (try_multi_threaded) {
                var result: meta.Return(runTest) = undefined;

                try proc.callClone(thread_spec, try thread.map(.{ .options = .{} }, i), &result, runTest, args);
            } else {
                try @call(.auto, runTestTestUsingAllocator, args);
            }
        }
    }
}
