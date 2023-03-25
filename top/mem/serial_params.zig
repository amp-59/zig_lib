const types = @import("./types.zig");
const config = @import("./config.zig");
const serial = @import("../serial.zig");

export fn serializeParams(allocator: *config.Allocator, val: *const []const []const types.Specifier) void {
    serial.serialize(allocator, config.params_path, val.*) catch return undefined;
}
export fn deserializeParams(allocator: *config.Allocator, ptr: *[][]types.Specifier) void {
    ptr.* = serial.deserialize([][]types.Specifier, allocator, config.params_path) catch return undefined;
}
