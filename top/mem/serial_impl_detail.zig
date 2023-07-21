const types = @import("./types.zig");
const config = @import("./config.zig");
const spec = @import("../spec.zig");
const debug = @import("../debug.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");
pub const logging_override: debug.Logging.Override = spec.logging.override.silent;
export fn serializeImplDetail(allocator: *config.Allocator, val: *const []const types.Implementation) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.impl_detail_path, val.*);
}
export fn deserializeImplDetail(allocator: *config.Allocator, ptr: *[]types.Implementation) void {
    ptr.* = serial.serialRead(config.serial_spec, []types.Implementation, allocator, config.impl_detail_path);
}
