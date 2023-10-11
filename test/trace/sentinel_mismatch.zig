const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const want_stack_traces: bool = true;
pub const trace: zl.debug.Trace = .{
    .options = .{
        .show_line_no = true,
        .write_caret = false,
        .context_line_count = 1,
    },
};
fn causeSentinelMismatch() void {
    var a: [4096]u8 = undefined;
    const b: [:0]u8 = a[0..512 :0];
    b[256] = 'b';
}
pub fn main() void {
    causeSentinelMismatch();
}
