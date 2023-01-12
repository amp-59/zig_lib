const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const builder = @import("./builder.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = true;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
});

const try_multi_threaded: bool = false;

const cache_dir: [:0]const u8 = builtin.lib_build_root ++ "/zig-cache";

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
fn runTest(
    vars: [][*:0]u8,
    name: [:0]const u8,
    pathname: [:0]const u8,
    mode: anytype,
    macros: builder.Macros,
) !void {
    var global_cache_dir_buf: [4096:0]u8 = .{0} ** 4096;
    var cmd: builder.BuildCmd(.{}) = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = mode,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = builtin.lib_build_root ++ "/zig-cache",
        .stack = 8388608,
        .macros = macros,
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.exec(vars);
}
fn runTestTestUsingAllocator(
    vars: [][*:0]u8,
    allocator: *Allocator,
    name: [:0]const u8,
    pathname: [:0]const u8,
    mode: anytype,
    macros: builder.Macros,
) !void {
    var global_cache_dir_buf: [4096:0]u8 = .{0} ** 4096;
    var cmd: builder.BuildCmd(.{ .Allocator = Allocator }) = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = mode,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = cache_dir,
        .stack = 8388608,
        .macros = macros,
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.allocateExec(vars, allocator);
}

const general_macros: builder.Macros = &.{
    .{ .name = "is_verbose", .value = "0" },
    .{ .name = "is_correct", .value = "0" },
    .{ .name = "build_root", .value = "\"" ++ builtin.lib_build_root ++ "\"" },
};
const parsedir_std_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = "\"std\"" }};
const parsedir_lib_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = "\"lib\"" }};

pub fn main(_: [][*:0]u8, vars: [][*:0]u8) !void {
    {
        const arg_set = .{
            .{ vars, "readelf", "test/readelf.zig", builtin.zig.mode, general_macros },
            .{ vars, "parsedir", "test/parsedir.zig", .ReleaseFast, parsedir_lib_macros },
            .{ vars, "parsedir", "test/parsedir.zig", .ReleaseFast, parsedir_std_macros },
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
        var address_space: builtin.AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        const arg_set = .{
            .{ vars, &allocator, "treez", "test/treez.zig", builtin.zig.mode, general_macros },
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
