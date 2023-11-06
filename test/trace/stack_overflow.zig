const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .context_line_count = 1,
        .break_line_count = 1,
        .write_caret = true,
        .tokens = zl.builtin.zl_trace.options.tokens,
    },
};
fn causeStackOverflow() void {
    var a: [4096]u8 = undefined;
    a[0] = 'a';
    causeStackOverflow();
    unreachable;
}
pub fn main() void {
    causeStackOverflow();
}
