const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .write_caret = true,
        .tokens = .{
            .sidebar_fill = ": ",
            .sidebar = "│",
            .syntax = &.{.{ .tags = &.{.identifier}, .style = "\x1b[96m" }},
        },
    },
};
fn causeAssertionFailed() void {
    var x: u64 = 0x10000;
    var y: u64 = 0x10010;
    zl.debug.assertEqual(u64, x, y);
}
pub fn main() void {
    causeAssertionFailed();
}
