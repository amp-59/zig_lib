const types = @import("./types.zig");
const config = @import("./config.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");
pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
export fn serializeOptions(allocator: *config.Allocator, val: *const []const []const types.Technique) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.options_path, val.*);
}
export fn deserializeOptions(allocator: *config.Allocator, ptr: *[][]types.Technique) void {
    ptr.* = serial.serialRead(config.serial_spec, [][]types.Technique, allocator, config.options_path);
}
