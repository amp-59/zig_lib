const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.archive = .{
        .write = zl.build.ArchiveCommand.write,
        .length = zl.build.ArchiveCommand.length,
        .formatParseArgs = zl.build.ArchiveCommand.formatParseArgs,
    };
}
