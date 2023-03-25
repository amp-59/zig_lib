const types = @import("./types.zig");
const config = @import("./config.zig");
const serial = @import("../serial.zig");

export fn serializeOptions(allocator: *config.Allocator, val: *const []const []const types.Technique) void {
    serial.serialize(allocator, config.options_path, val.*) catch return undefined;
}
export fn deserializeOptions(allocator: *config.Allocator, ptr: *[][]types.Technique) void {
    ptr.* = serial.deserialize([][]types.Technique, allocator, config.options_path) catch return undefined;
}
