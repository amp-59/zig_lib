const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .show_pc_addr = true,
    },
};
fn reachUnreachableCode() void {
    unreachable;
}
pub fn main() void {
    reachUnreachableCode();
}
