const types = @import("./types.zig");
const config = @import("./config.zig");
const spec = @import("../spec.zig");
const debug = @import("../debug.zig");
const serial = @import("../serial.zig");
const builtin = @import("../builtin.zig");
pub const logging_override: debug.Logging.Override = spec.logging.override.silent;
export fn serializeTechs(allocator: *config.Allocator, val: *const []const []const []const types.Technique) void {
    serial.serialWrite(config.serial_spec, @TypeOf(val.*), allocator, config.tech_sets_path, val.*);
}
export fn deserializeTechs(allocator: *config.Allocator, ptr: *[][][]types.Technique) void {
    ptr.* = serial.serialRead(config.serial_spec, [][][]types.Technique, allocator, config.tech_sets_path);
}
