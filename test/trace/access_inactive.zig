const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{
    .options = .{ .show_line_no = false },
};
fn accessInactiveUnionField() void {
    var u: union(enum) {
        a: u64,
        b: u32,
    } = .{ .a = 25 };
    u.a = u.b;
}
pub fn main() void {
    accessInactiveUnionField();
}
