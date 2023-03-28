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
export fn serializeSpecs(allocator: *config.Allocator, val: *const []const []const []const types.Specifier) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.spec_sets_path, val.*);
}
export fn deserializeSpecs(allocator: *config.Allocator, ptr: *[][][]types.Specifier) void {
    ptr.* = serial.serialRead(config.serial_spec, [][][]types.Specifier, allocator, config.spec_sets_path);
}
