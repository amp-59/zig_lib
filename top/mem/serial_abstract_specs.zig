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
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.abstract_specs_path, val.*);
}
export fn deserializeAbstractSpecs(allocator: *config.Allocator, ptr: *[]types.AbstractSpecification) void {
    ptr.* = serial.serialRead(config.serial_spec, []types.AbstractSpecification, allocator, config.abstract_specs_path);
}
