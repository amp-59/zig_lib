const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .write_caret = false,
        .break_line_count = 1,
    },
};
fn causeOutOfBounds() void {
    var idx: usize = 512;
    var a: [512]u8 = undefined;
    a[idx] = 'a';
}
pub fn main() void {
    causeOutOfBounds();
}
