const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const mem = zl.mem;
const proc = zl.proc;
const spec = zl.spec;
const file = zl.file;
const mach = zl.mach;
const meta = zl.meta;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub fn copy(src_pathname: [:0]const u8, dest_pathname: [:0]const u8) !void {
    blk: {
        const from_fd: u64 = file.open(.{ .errors = .{}, .options = .{ .read = true, .no_follow = true } }, src_pathname);
        if (from_fd > 1024) break :blk;
        const to_fd: u64 = file.create(.{ .errors = .{}, .options = .{ .exclusive = false } }, dest_pathname, file.mode.executable);
        if (to_fd > 1024) break :blk;
        const size: u64 = file.status(.{ .errors = .{} }, from_fd).size;
        if (size == 0) break :blk;
        debug.assertEqual(u64, size, file.copy(.{ .errors = .{} }, from_fd, null, to_fd, null, size));
    }
}
pub fn main(args: [][*:0]u8) !void {
    if (args.len != 3) {
        return;
    }
    const src_pathname: [:0]const u8 = mach.manyToSlice80(args[1]);
    const dest_pathname: [:0]const u8 = mach.manyToSlice80(args[2]);
    try copy(src_pathname, dest_pathname);
}
