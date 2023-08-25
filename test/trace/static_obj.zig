const zl = @import("../../zig_lib.zig");
const spec = zl.spec;
pub usingnamespace zl.start;

pub const logging_default = spec.logging.default.verbose;

pub const panic_return_value: u8 = 0;

export fn function() void {
    @import("./assertion_failed.zig").main();
}
