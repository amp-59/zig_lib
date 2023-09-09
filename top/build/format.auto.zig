const types = @import("./types.zig");
pub usingnamespace @import("../start.zig");
const source = types.GenericCommand(types.FormatCommand);
formatWriteBuf: *const fn (
    p_0: *types.FormatCommand,
    p_1: []const u8,
    p_2: types.Path,
    p_3: [*]u8,
) usize = @ptrFromInt(8),
formatLength: *const fn (
    p_0: *types.FormatCommand,
    p_1: []const u8,
    p_2: types.Path,
) usize = @ptrFromInt(8),
formatParseArgs: *const fn (
    p_0: *types.FormatCommand,
    p_1: *types.Allocator,
    p_2: [][*:0]u8,
) void = @ptrFromInt(8),
fn load(ptrs: *@This()) callconv(.C) void {
    ptrs.formatWriteBuf = @ptrCast(&source.formatWriteBuf);
    ptrs.formatLength = @ptrCast(&source.formatLength);
    ptrs.formatParseArgs = @ptrCast(&source.formatParseArgs);
}
comptime {
    if (@import("builtin").output_mode != .Exe) {
        @export(load, .{ .name = "load", .linkage = .Strong });
    }
}
