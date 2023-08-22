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
    const from_fd: usize = try file.open(.{ .options = .{ .no_follow = true, .read_write = true } }, src_pathname);
    const to_fd: usize = try file.create(.{ .options = .{ .exclusive = false, .write = true } }, dest_pathname, file.mode.regular);
    const from_st: file.Status = try file.status(.{}, from_fd);
    if (from_st.size != 0) {
        debug.assertEqual(u64, from_st.size, try file.copy(.{}, to_fd, null, from_fd, null, from_st.size));
    }
}
pub fn main(args: [][*:0]u8) !void {
    if (args.len != 3) {
        return;
    }
    const src_pathname: [:0]const u8 = mem.terminate(args[1], 0);
    const dest_pathname: [:0]const u8 = mem.terminate(args[2], 0);
    try copy(src_pathname, dest_pathname);
}
