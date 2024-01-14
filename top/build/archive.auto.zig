const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.archive = .{
        .write = zl.builder.ArchiveCommand.write,
        .length = zl.builder.ArchiveCommand.length,
        .formatParseArgs = zl.builder.ArchiveCommand.formatParseArgs,
    };
}
