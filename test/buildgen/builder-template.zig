const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.fmt;
    tmp.integral = .{ .format = .dec };
    break :blk tmp;
};
pub const BuildCmdSpec = struct {
    max_len: u64 = 1024 * 1024,
    max_args: u64 = 1024,
    Allocator: ?type = null,
};
pub fn BuildCmd(comptime spec: BuildCmdSpec) type {
    return struct {
        const Builder: type = @This();
        const Allocator: type = spec.Allocator.?;
        const String: type = Allocator.StructuredVectorLowAligned(u8, 8);
        const Pointers: type = Allocator.StructuredVector([*:0]u8);
        const StaticString: type = mem.StructuredAutomaticVector(u8, null, spec.max_len, 8, .{});
        const StaticPointers: type = mem.StructuredAutomaticVector([*:0]u8, null, spec.max_args, 8, .{});
        const zig: [:0]const u8 = "zig";
        cmd: enum { exe, lib, obj, fmt, ast_check, run },
        root: [:0]const u8,
        _: void,
        pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
            var array: String = try meta.wrap(String.init(allocator, build.buildLength()));
            defer array.deinit(allocator);
            var args: Pointers = try meta.wrap(Pointers.init(allocator, build.buildWrite(&array)));
            builtin.assertAboveOrEqual(u64, spec.max_args, makeArgs(array, &args));
            builtin.assertAboveOrEqual(u64, spec.max_len, array.len());
            defer args.deinit(allocator);
            return genericExec(args.referAllDefined(), vars);
        }
        pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
            var array: StaticString = .{};
            var args: StaticPointers = .{};
            builtin.assertAboveOrEqual(u64, spec.max_args, build.buildWrite(&array));
            builtin.assertAboveOrEqual(u64, spec.max_args, makeArgs(&array, &args));
            return genericExec(args.referAllDefined(), vars);
        }
        fn genericExec(args: [][*:0]u8, vars: [][*:0]u8) !u64 {
            const dir_fd: u64 = try file.find(vars, Builder.zig);
            defer file.close(.{ .errors = null }, dir_fd);
            return proc.commandAt(.{}, dir_fd, Builder.zig, args, vars);
        }
    };
}
/// Environment variables needed to find user home directory
pub fn zigCacheDirGlobal(vars: [][*:0]u8, buf: [:0]u8) ![:0]u8 {
    const home_pathname: [:0]const u8 = try file.home(vars);
    var len: u64 = 0;
    for (home_pathname) |c, i| buf[len + i] = c;
    len += home_pathname.len;
    for ("/.cache/zig") |c, i| buf[len + i] = c;
    return buf[0 .. len + 11 :0];
}
fn countArgs(array: anytype) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count += 1;
        }
    }
    return count + 1;
}
fn makeArgs(array: anytype, args: anytype) u64 {
    var idx: u64 = 0;
    for (array.readAll()) |c, i| {
        if (c == 0) {
            args.writeOne(array.referManyWithSentinelAt(idx, 0).ptr);
            idx = i + 1;
        }
    }
    if (args.len() != 0) {
        mem.set(args.impl.next(), @as(u64, 0), 1);
    }
    return args.len();
}
