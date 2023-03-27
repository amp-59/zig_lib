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
export fn serializeAbstractSpecs(allocator: *config.Allocator, val: *const []const types.AbstractSpecification) void {
    serial.serialize(allocator, config.abstract_specs_path, val.*) catch return undefined;
}
export fn deserializeAbstractSpecs(allocator: *config.Allocator, ptr: *[]types.AbstractSpecification) void {
    ptr.* = serial.deserialize([]types.AbstractSpecification, allocator, config.abstract_specs_path) catch return undefined;
}
