const types = @import("./types.zig");
const config = @import("./config.zig");
const spec = @import("../spec.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
export fn serializeSpecs(allocator: *config.Allocator, val: *const []const []const []const types.Specifier) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.spec_sets_path, val.*);
}
export fn deserializeSpecs(allocator: *config.Allocator, ptr: *[][][]types.Specifier) void {
    ptr.* = serial.serialRead(config.serial_spec, [][][]types.Specifier, allocator, config.spec_sets_path);
}
