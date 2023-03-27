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
export fn serializeImplDetail(allocator: *config.Allocator, val: *const []const types.Implementation) void {
    serial.serialize(allocator, config.impl_detail_path, val.*) catch return undefined;
}
export fn deserializeImplDetail(allocator: *config.Allocator, ptr: *[]types.Implementation) void {
    ptr.* = serial.deserialize([]types.Implementation, allocator, config.impl_detail_path) catch return undefined;
}
