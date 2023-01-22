const lit = @import("./lit.zig");
const proc = @import("./proc.zig");
const algo = @import("./algo.zig");
const file = @import("./file.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

const show_best_cases: bool = true;

fn write(buf: []u8, off: u64, ss: []const []const u8) u64 {
    var len: u64 = 0;
    for (ss) |s| {
        for (s) |c, i| buf[off + len + i] = c;
        len += s.len;
    }
    return len;
}
fn print(buf: []u8, off: u64, ss: []const []const u8) void {
    file.noexcept.write(2, buf[0 .. off + write(buf, off, ss)]);
}
pub fn main() void {
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    var n_aligned_bytes: u32 = 1;
    var total_requested: u64 = 0;
    var total_returned: u64 = 0;

    while (n_aligned_bytes < lit.max_bit_u32) : (n_aligned_bytes += 1) {
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
