const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
pub const logging_default = zl.debug.spec.logging.default.verbose;
pub const panic_return_value: u8 = 0;
export fn function() void {
    @import("./stack_overflow.zig").main();
}
