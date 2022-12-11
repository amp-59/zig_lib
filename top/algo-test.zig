const lit = @import("./lit.zig");
const proc = @import("./proc.zig");
const algo = @import("./algo.zig");
const file = @import("./file.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

var show_best_cases: bool = false;

fn write(buf: []u8, ss: []const []const u8) u64 {
    var len: u64 = 0;
    for (ss) |s| {
        for (s) |c, i| buf[len + i] = c;
        len += s.len;
    }
    return len;
}
fn print(buf: []u8, ss: []const []const u8) void {
    file.noexcept.write(2, buf[0..write(buf, ss)]);
}
pub fn main() void {
    var buf: [4096]u8 = undefined;
    var s_count: u32 = 1;
    while (s_count != lit.max_val_u32) : (s_count += 1) {
        const s_lu_counts: u32 = algo.packDoubleApproxB(s_count);
        const t_count: u64 = algo.unpackDoubleApproxB(s_lu_counts);
        if (t_count - s_count == 0 and show_best_cases) {
            print(&buf, &[_][]const u8{
                builtin.fmt.ud32(s_count).readAll(), " ",
                builtin.fmt.ub32(s_count).readAll(), "\n",
            });
        }
    }
}
