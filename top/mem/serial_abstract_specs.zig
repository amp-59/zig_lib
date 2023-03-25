const types = @import("./types.zig");
const config = @import("./config.zig");
const serial = @import("../serial.zig");

export fn serializeAbstractSpecs(allocator: *config.Allocator, val: *const []const types.AbstractSpecification) void {
    serial.serialize(allocator, config.abstract_specs_path, val.*) catch return undefined;
}
export fn deserializeAbstractSpecs(allocator: *config.Allocator, ptr: *[]types.AbstractSpecification) void {
    ptr.* = serial.deserialize([]types.AbstractSpecification, allocator, config.abstract_specs_path) catch return undefined;
}
