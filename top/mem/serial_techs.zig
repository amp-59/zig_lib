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
export fn serializeTechs(allocator: *config.Allocator, val: *const []const []const []const types.Technique) void {
    serial.serialize(allocator, config.tech_sets_path, val.*) catch return undefined;
}
export fn deserializeTechs(allocator: *config.Allocator, ptr: *[][][]types.Technique) void {
    ptr.* = serial.deserialize([][][]types.Technique, allocator, config.tech_sets_path) catch return undefined;
}
