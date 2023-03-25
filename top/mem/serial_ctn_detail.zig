const types = @import("./types.zig");
const config = @import("./config.zig");
const serial = @import("../serial.zig");

export fn deserializeCtnDetail(allocator: *config.Allocator, ptr: *[]types.Container) void {
    ptr.* = serial.deserialize([]types.Container, allocator, config.ctn_detail_path) catch return undefined;
}
export fn serializeCtnDetail(allocator: *config.Allocator, val: *const []const types.Container) void {
    serial.serialize(allocator, config.ctn_detail_path, val.*) catch return undefined;
}
