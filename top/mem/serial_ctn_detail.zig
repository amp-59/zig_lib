const types = @import("./types.zig");
const config = @import("./config.zig");
const spec = @import("../spec.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
export fn serializeCtnDetail(allocator: *config.Allocator, val: *const []const types.Container) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.ctn_detail_path, val.*);
}
export fn deserializeCtnDetail(allocator: *config.Allocator, ptr: *[]types.Container) void {
    ptr.* = serial.serialRead(config.serial_spec, []types.Container, allocator, config.ctn_detail_path);
}
