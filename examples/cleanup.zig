const srg = @import("../zig_lib.zig");
const mem = srg.mem;
const proc = srg.proc;
const file = srg.file;
const mach = srg.mach;
const meta = srg.meta;
const builtin = srg.builtin;

pub usingnamespace proc.start;

const rm_bits: []const [:0]const u8 = &.{
    ".section\t\".note.GNU-stack\",\"\",@progbits",
};

pub fn main(args_in: [][*:0]u8) !void {
    if (args_in.len == 1) {
        return;
    }
    for (args_in[1..]) |arg_in| {
        const arg: [:0]const u8 = meta.manyToSlice(arg_in);
        const fd: u64 = file.open(.{ .options = .{ .read_write = true, .append = true, .no_follow = false } }, arg) catch {
            continue;
        };
        const size: u64 = try file.seek(.{}, fd, 0, .end);
        defer file.close(.{ .errors = .{} }, fd);
        const addr: u64 = 0x40000000;

        const len: u64 = mach.alignA64(size, 4096);
        try file.map(.{}, .{}, .{ .visibility = .shared }, fd, addr, len);
        defer mem.unmap(.{ .errors = .{} }, addr, len);

        const section_s: [:0]const u8 = "\t.section";
        const segment_s: [:0]const u8 = "LBB";
        const unnamed_s: [:0]const u8 = "L__unnamed";

        const buf: []u8 = mem.pointerSlice(u8, addr, size);
        var idx: u64 = 0;
        while (idx != buf.len) : (idx +%= 1) {
            if (mem.testEqualMany(u8, segment_s, buf[idx .. idx + segment_s.len])) {
                buf[idx] = 'X';
            }
            if (mem.testEqualMany(u8, unnamed_s, buf[idx .. idx + unnamed_s.len])) {
                buf[idx] = 'X';
            }
        }
        idx = 0;
        while (idx != buf.len) : (idx +%= 1) {
            if (mem.testEqualMany(u8, section_s, buf[idx .. idx + section_s.len])) {
                break;
            }
        }
        const beg: u64 = idx;
        idx = 0;
        while (beg +% idx != buf.len) : (idx +%= 1) {
            buf[idx] = buf[beg +% idx];
        }
        if (mem.indexOfLastEqualMany(u8, rm_bits[0], buf)) |pos| {
            try file.truncate(.{}, fd, pos);
        } else {
            try file.truncate(.{}, fd, idx);
        }
    }
}
