const srg = @import("../zig_lib.zig");
const sys = srg.sys;
const mem = srg.mem;
const proc = srg.proc;
const file = srg.file;
const mach = srg.mach;
const meta = srg.meta;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = .{
    .Attempt = false,
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};

pub fn main(args_in: [][*:0]u8) !void {
    if (args_in.len == 1) {
        return;
    }
    const from: [:0]const u8 = meta.manyToSlice(args_in[1]);
    const to: [:0]const u8 = meta.manyToSlice(args_in[2]);
    const from_fd: u64 = file.open(.{ .errors = .{}, .options = .{ .read = true, .no_follow = true } }, from);
    const to_fd: u64 = file.create(.{ .errors = .{}, .options = .{ .exclusive = false } }, to, file.mode.regular);
    file.assert(.{ .errors = .{} }, from_fd, .regular);
    file.assert(.{ .errors = .{} }, to_fd, .regular);
    var buf: [4096]u8 = undefined;
    var len: u64 = file.read(.{ .errors = .{} }, from_fd, &buf);
    while (len != 0) : (len = file.read(.{ .errors = .{} }, from_fd, &buf)) {
        file.write(.{ .errors = .{} }, to_fd, buf[0..len]);
    }
}
