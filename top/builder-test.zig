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

pub const AddressSpace = preset.address_space.formulaic_128;
pub const is_verbose: bool = false;
pub const is_correct: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});

const try_multi_threaded: bool = false;

const cache_dir: [:0]const u8 = builtin.build_root.? ++ "/zig-cache";

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
    .options = .{},
};
fn runTest(vars: [][*:0]u8, name: []const u8, pathname: [:0]const u8, mode: @TypeOf(builtin.zig.mode), macros: builder.Macros) !void {
    var global_cache_dir_buf: [4096:0]u8 = .{0} ** 4096;
    var cmd: builder.BuildCmd(.{}) = .{
        .root = pathname,
        .cmd = .run,
        .name = name,
        .O = mode,
        .strip = true,
        .enable_cache = false,
        .global_cache_dir = try globalCacheDir(vars, &global_cache_dir_buf),
        .cache_dir = builtin.build_root.? ++ "/zig-cache",
        .stack = 8388608,
        .macros = macros,
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.exec(vars);
}
fn runTestTestUsingAllocator(vars: [][*:0]u8, allocator: *Allocator, name: [:0]const u8, pathname: [:0]const u8, mode: @TypeOf(builtin.zig.mode), macros: builder.Macros) !void {
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
    .{ .name = "build_root", .value = "\"" ++ builtin.build_root.? ++ "\"" },
};
const parsedir_std_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = "\"std\"" }};
const parsedir_lib_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = "\"lib\"" }};

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    if (false) {
        var address_space: builtin.AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        var args: [][*:0]u8 = args_in;
        if (args.len == 1) return;
        for (args[1..]) |arg| {
            const pathname: [:0]const u8 = meta.manyToSlice(arg);
            const basename: [:0]const u8 = mem.readAfterLastEqualOneOrElseWithSentinel(u8, 0, '/', pathname);
            if (mem.readBeforeLastEqualMany(u8, ".zig", basename)) |name| {
                if (false) {
                    try runTestTestUsingAllocator(vars, &allocator, name[0.. :0], pathname, builtin.zig.mode, general_macros);
                } else {
                    try runTest(vars, name, pathname, builtin.zig.mode, general_macros);
                }
            }
        }
    }
    const S = [:0]const u8;
    if (true) {
        const Args = struct { @TypeOf(vars), S, S, @TypeOf(builtin.zig.mode), @TypeOf(general_macros) };
        const args_set = [_]Args{
            .{ vars, "parsedir", "test/parsedir.zig", .ReleaseFast, parsedir_lib_macros },
            .{ vars, "parsedir", "test/parsedir.zig", .ReleaseFast, parsedir_std_macros },
        };
        for (args_set) |args, i| {
            if (try_multi_threaded) {
                var result: meta.Return(runTest) = undefined;
                try proc.callClone(thread_spec, try thread.map(.{ .options = .{} }, @intCast(u8, i)), &result, runTest, args);
            } else {
                try @call(.auto, runTest, args);
            }
        }
    }
    if (false) {
        const AllocArgs = struct { @TypeOf(vars), *Allocator, S, S, @TypeOf(builtin.zig.mode), @TypeOf(general_macros) };
        var address_space: builtin.AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        const arg_sets = [_]AllocArgs{
            .{ vars, &allocator, "treez", "test/treez.zig", builtin.zig.mode, general_macros },
            .{ vars, &allocator, "readelf", "test/readelf.zig", builtin.zig.mode, general_macros },
        };
        for (arg_sets) |args, i| {
            if (try_multi_threaded) {
                var result: meta.Return(runTest) = undefined;
                try proc.callClone(thread_spec, try thread.map(.{ .options = .{} }, i), &result, runTest, args);
            } else {
                try @call(.auto, runTestTestUsingAllocator, args);
            }
        }
    }
}
