const types = @import("./types.zig");
pub usingnamespace @import("../start.zig");
const source = types.GenericExtraCommand(types.FormatCommand);
renderWriteBuf: *const fn (
    p_0: *const types.FormatCommand,
    p_1: [*]u8,
) usize = @ptrFromInt(8),
fieldEditDistance: *const fn (
    p_0: *types.FormatCommand,
    p_1: *types.FormatCommand,
) usize = @ptrFromInt(8),
writeFieldEditDistance: *const fn (
    p_0: [*]u8,
    p_1: []const u8,
    p_2: *types.FormatCommand,
    p_3: *types.FormatCommand,
    p_4: bool,
) usize = @ptrFromInt(8),
indexOfCommonLeastDifference: *const fn (
    p_0: *types.Allocator,
    p_1: []*types.FormatCommand,
) usize = @ptrFromInt(8),
fn load(ptrs: *@This()) callconv(.C) void {
    ptrs.renderWriteBuf = @ptrCast(&source.renderWriteBuf);
    ptrs.fieldEditDistance = @ptrCast(&source.fieldEditDistance);
    ptrs.writeFieldEditDistance = @ptrCast(&source.writeFieldEditDistance);
    ptrs.indexOfCommonLeastDifference = @ptrCast(&source.indexOfCommonLeastDifference);
}
comptime {
    if (@import("builtin").output_mode != .Exe) {
        @export(load, .{ .name = "load", .linkage = .Strong });
    }
}
