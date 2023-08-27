const build = @import("./types.zig");
const source = build.GenericCommand(build.BuildCommand);
renderWriteBuf: *const fn (
    p_0: *const build.BuildCommand,
    p_1: [*]u8,
) usize = @ptrFromInt(8),
fieldEditDistance: *const fn (
    p_0: *build.BuildCommand,
    p_1: *build.BuildCommand,
) usize = @ptrFromInt(8),
writeFieldEditDistance: *const fn (
    p_0: [*]u8,
    p_1: []const u8,
    p_2: *build.BuildCommand,
    p_3: *build.BuildCommand,
    p_4: bool,
) usize = @ptrFromInt(8),
indexOfCommonLeastDifference: *const fn (
    p_0: *build.Allocator,
    p_1: []*build.BuildCommand,
) usize = @ptrFromInt(8),
formatWriteBuf: *const fn (
    p_0: *build.BuildCommand,
    p_1: []const u8,
    p_2: []const build.Path,
    p_3: [*]u8,
) usize = @ptrFromInt(8),
formatLength: *const fn (
    p_0: *build.BuildCommand,
    p_1: []const u8,
    p_2: []const build.Path,
) usize = @ptrFromInt(8),
formatParseArgs: *const fn (
    p_0: *build.BuildCommand,
    p_1: *build.Allocator,
    p_2: [][*:0]u8,
) void = @ptrFromInt(8),
fn load(ptrs: *@This()) callconv(.C) void {
    ptrs.renderWriteBuf = @ptrCast(&source.renderWriteBuf);
    ptrs.fieldEditDistance = @ptrCast(&source.fieldEditDistance);
    ptrs.writeFieldEditDistance = @ptrCast(&source.writeFieldEditDistance);
    ptrs.indexOfCommonLeastDifference = @ptrCast(&source.indexOfCommonLeastDifference);
    ptrs.formatWriteBuf = @ptrCast(&source.formatWriteBuf);
    ptrs.formatLength = @ptrCast(&source.formatLength);
    ptrs.formatParseArgs = @ptrCast(&source.formatParseArgs);
}
comptime {
    if (@import("builtin").output_mode != .Exe) {
        @export(load, .{ .name = "load", .linkage = .Strong });
    }
}
