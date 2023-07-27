const types = @import("./types.zig");
pub usingnamespace @import("../start.zig");
pub export fn buildFormatParseArgs(allocator: *types.Allocator, build_cmd: *types.BuildCommand, args: [*][*:0]u8, args_len: usize) void {
    build_cmd.formatParseArgs(allocator, args[0..args_len]);
}
pub export fn formatFormatParseArgs(allocator: *types.Allocator, format_cmd: *types.FormatCommand, args: [*][*:0]u8, args_len: usize) void {
    format_cmd.formatParseArgs(allocator, args[0..args_len]);
}
pub export fn archiveFormatParseArgs(allocator: *types.Allocator, archive_cmd: *types.ArchiveCommand, args: [*][*:0]u8, args_len: usize) void {
    archive_cmd.formatParseArgs(allocator, args[0..args_len]);
}
pub export fn objcopyFormatParseArgs(allocator: *types.Allocator, objcopy_cmd: *types.ObjcopyCommand, args: [*][*:0]u8, args_len: usize) void {
    objcopy_cmd.formatParseArgs(allocator, args[0..args_len]);
}
pub export fn tblgenFormatParseArgs(allocator: *types.Allocator, tblgen_cmd: *types.TableGenCommand, args: [*][*:0]u8, args_len: usize) void {
    tblgen_cmd.formatParseArgs(allocator, args[0..args_len]);
}
pub export fn harecFormatParseArgs(allocator: *types.Allocator, harec_cmd: *types.HarecCommand, args: [*][*:0]u8, args_len: usize) void {
    harec_cmd.formatParseArgs(allocator, args[0..args_len]);
}
