const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;

pub fn main() void {
    zl.debug.__panic(.{ .access_inactive_field = .{ .type_name = "Union", .expected = "a", .found = "b" } }, @errorReturnTrace(), @returnAddress());
    zl.debug.write("\n");
    zl.debug.__panic(.{ .access_out_of_bounds = .{ .type_name = "u8", .index = 256, .length = 128 } }, @errorReturnTrace(), @returnAddress());
    zl.debug.write("\n");
    zl.debug.__panic(.{ .access_out_of_order = .{ .type_name = "u8", .start = 256, .finish = 128 } }, @errorReturnTrace(), @returnAddress());
    zl.debug.write("\n");
    zl.debug.__panic(.{ .cast_to_error_from_invalid = .{ .type_name = "ErrorSet", .code = 32768 } }, @errorReturnTrace(), @returnAddress());
    zl.debug.write("\n");
}
