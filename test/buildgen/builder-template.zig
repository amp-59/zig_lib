const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");

const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = mem.fmt_wr_spec;
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
        const StaticString: type = mem.StaticString(spec.max_len);
        const Pointers: type = mem.StaticArray([*:0]u8, spec.max_args);
        cmd: enum { exe, lib, obj, fmt, ast_check, run },
        root: [:0]const u8,
        _: void,
        pub fn allocateShow(build: Builder, allocator: *Allocator) !void {
            var ad: BuildCmd.ArgData = try build.parcelDataV(&allocator);
            for (ad.ptrs.readAll()) |argp| {
                try file.write(2, mem.manyToSlice(argp));
                try file.write(2, "\n");
            }
            allocator.discard();
        }
        pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
            return genericExec(vars, try build.allocateCommandString(allocator));
        }
        pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
            return genericExec(vars, try build.commandString());
        }
        fn genericExec(vars: [][*:0]u8, array: anytype) !u64 {
            const dir_fd: u64 = try file.find(vars, "zig");
            defer file.close(.{ .errors = null }, dir_fd);
            var args: Pointers = .{};
            var idx: u64 = 0;
            for (array.readAll()) |c, i| {
                if (c == 0) {
                    args.writeOne(array.referAll()[idx..i :0].ptr);
                    idx = i + 1;
                }
            }
            if (args.impl.start() != args.impl.next()) {
                mem.set(args.impl.next(), @as(u64, 0), 1);
            }
            if (args.count() != 0) {
                return proc.commandAt(.{}, dir_fd, "zig", args.referAll(), vars);
            }
            return 0;
        }
    };
}
