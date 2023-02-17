const lit = @import("./lit.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const algo = @import("./algo.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
const show_best_cases: bool = false;

fn write(buf: []u8, off: u64, ss: []const []const u8) u64 {
    var len: u64 = 0;
    for (ss) |s| {
        for (s) |c, i| buf[off + len + i] = c;
        len += s.len;
    }
    return len;
}
fn print(buf: []u8, off: u64, ss: []const []const u8) void {
    file.noexcept.write(1, buf[0 .. off + write(buf, off, ss)]);
}
fn compareLayeredShellShort() !void {
    const size = 0x400000;
    try mem.map(.{ .options = .{} }, size, size);
    try mem.map(.{ .options = .{} }, size + size, size);
    const rnbuf: []u8 = @intToPtr([*]u8, size)[0..size];
    file.readRandom(rnbuf);
    const values_1 = @intToPtr([*]u64, size)[0..(size / 0x8)];
    @memcpy(@intToPtr([*]u8, size + size), @intToPtr([*]const u8, size), size);
    const values_2 = @intToPtr([*]u64, size + size)[0..(size / 0x8)];
    {
        const t_0 = try time.get(.{}, .realtime);
        algo.shellSortAsc(u64, values_1);
        const t_1 = try time.get(.{}, .realtime);
        testing.printN(4096, .{ fmt.any(time.diff(t_1, t_0)), '\n' });
    }
    {
        const t_0 = try time.get(.{}, .realtime);
        algo.layeredShellSortAsc(u64, values_2);
        const t_1 = try time.get(.{}, .realtime);
        testing.printN(4096, .{ fmt.any(time.diff(t_1, t_0)), '\n' });
    }
    for (values_1) |value, index| {
        builtin.assertEqual(u64, value, values_2[index]);
    }
}
fn approximationTest() void {
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    var n_aligned_bytes: u32 = 1;
    var total_requested: u64 = 0;
    var total_returned: u64 = 0;
    while (n_aligned_bytes < lit.max_bit_u16) : (n_aligned_bytes += 1) {
        const s_lb_counts: u16 = algo.partialPackSingleApprox(n_aligned_bytes);
        const o_aligned_bytes: u64 = algo.partialUnpackSingleApprox(s_lb_counts);
        const s_ub_counts: u16 = algo.partialPackDoubleApprox(n_aligned_bytes, o_aligned_bytes);
        const s_aligned_bytes: u64 = algo.partialUnpackDoubleApprox(o_aligned_bytes, s_ub_counts);
        total_requested += n_aligned_bytes;
        total_returned += s_aligned_bytes;
        if (n_aligned_bytes - s_aligned_bytes == 0 and show_best_cases) {
            const ss: []const []const u8 = &[_][]const u8{
                builtin.fmt.ud32(@intCast(u32, s_aligned_bytes)).readAll(), " ",
                builtin.fmt.ub32(@intCast(u32, s_aligned_bytes)).readAll(), "\n",
            };
            if (len + 128 > buf.len) {
                print(&buf, len, ss);
                len = 0;
            } else {
                len += write(&buf, len, ss);
            }
        }
    }
    // The error is below 2 percent.
    builtin.assertBelow(u64, total_returned - total_requested, (2 * total_requested) / 100);
}
pub fn main() !void {
    try compareLayeredShellShort();
    approximationTest();
}
