const build = @import("./types.zig");
const source = build.GenericCommand(build.FormatCommand);
renderWriteBuf: *const fn (
    p_0: *const build.FormatCommand,
    p_1: [*]u8,
) usize = @ptrFromInt(8),
fieldEditDistance: *const fn (
    p_0: *build.FormatCommand,
    p_1: *build.FormatCommand,
) usize = @ptrFromInt(8),
writeFieldEditDistance: *const fn (
    p_0: [*]u8,
    p_1: []const u8,
    p_2: *build.FormatCommand,
    p_3: *build.FormatCommand,
    p_4: bool,
) usize = @ptrFromInt(8),
indexOfCommonLeastDifference: *const fn (
    p_0: *build.Allocator,
    p_1: []*build.FormatCommand,
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
