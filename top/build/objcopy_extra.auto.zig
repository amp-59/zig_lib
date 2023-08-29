const build = @import("./types.zig");
comptime {
    _ = @import("../mach.zig");
}
const source = build.GenericExtraCommand(build.ObjcopyCommand);
renderWriteBuf: *const fn (
    p_0: *const build.ObjcopyCommand,
    p_1: [*]u8,
) usize = @ptrFromInt(8),
fieldEditDistance: *const fn (
    p_0: *build.ObjcopyCommand,
    p_1: *build.ObjcopyCommand,
) usize = @ptrFromInt(8),
writeFieldEditDistance: *const fn (
    p_0: [*]u8,
    p_1: []const u8,
    p_2: *build.ObjcopyCommand,
    p_3: *build.ObjcopyCommand,
    p_4: bool,
) usize = @ptrFromInt(8),
indexOfCommonLeastDifference: *const fn (
    p_0: *build.Allocator,
    p_1: []*build.ObjcopyCommand,
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
