const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
const rm_bits: []const [:0]const u8 = &.{
    ".section\t\".note.GNU-stack\",\"\",@progbits",
};
pub fn main(args_in: [][*:0]u8) !void {
    if (args_in.len == 1) {
        return;
    }
    for (args_in[1..]) |arg_in| {
        const arg: [:0]const u8 = zl.mem.terminate(arg_in, 0);
        const fd: usize = zl.file.open(.{}, .{ .read_write = true, .append = true, .no_follow = false }, arg) catch {
            continue;
        };
        const size: u64 = try zl.file.seek(.{}, fd, 0, .end);
        defer zl.file.close(.{ .errors = .{} }, fd);
        const addr: u64 = 0x40000000;
        const len: u64 = zl.bits.alignA64(size, 4096);
        try zl.file.map(.{}, .{}, .{ .visibility = .shared }, fd, addr, len, 0);
        defer zl.mem.unmap(.{ .errors = .{} }, addr, len);
        const section_s: [:0]const u8 = "\t.section";
        const segment_s: [:0]const u8 = "LBB";
        const unnamed_s: [:0]const u8 = "L__unnamed";
        const buf: []u8 = zl.mem.pointerSlice(u8, addr, size);
        var idx: u64 = 0;
        while (idx != buf.len) : (idx +%= 1) {
            if (zl.mem.testEqualMany(u8, segment_s, buf[idx .. idx + segment_s.len])) {
                buf[idx] = 'X';
            }
            if (zl.mem.testEqualMany(u8, unnamed_s, buf[idx .. idx + unnamed_s.len])) {
                buf[idx] = 'X';
            }
        }
        idx = 0;
        while (idx != buf.len) : (idx +%= 1) {
            if (zl.mem.testEqualMany(u8, section_s, buf[idx .. idx + section_s.len])) {
                break;
            }
        }
        const beg: u64 = idx;
        idx = 0;
        while (beg +% idx != buf.len) : (idx +%= 1) {
            buf[idx] = buf[beg +% idx];
        }
        if (zl.mem.indexOfLastEqualMany(u8, rm_bits[0], buf)) |pos| {
            try zl.file.truncate(.{}, fd, pos);
        } else {
            try zl.file.truncate(.{}, fd, idx);
        }
    }
}
