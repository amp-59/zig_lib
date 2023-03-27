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
    serial.serialize(allocator, config.options_path, val.*) catch return undefined;
}
export fn deserializeOptions(allocator: *config.Allocator, ptr: *[][]types.Technique) void {
    ptr.* = serial.deserialize([][]types.Technique, allocator, config.options_path) catch return undefined;
}
