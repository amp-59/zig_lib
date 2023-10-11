const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const panic_return_value: u8 = 0;
pub const trace: zl.debug.Trace = .{};
fn startGreaterThanEnd() void {
    var a: [4096]u8 = undefined;
    const b: [:0]u8 = a[@intFromPtr(&a)..512 :0];
    b[256] = 'b';
}
pub fn main() void {
    startGreaterThanEnd();
}
