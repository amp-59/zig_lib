const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.archive = .{
        .formatWriteBuf = zl.build.GenericCommand(zl.build.ArchiveCommand).formatWriteBuf,
        .formatLength = zl.build.GenericCommand(zl.build.ArchiveCommand).formatLength,
        .formatParseArgs = zl.build.GenericCommand(zl.build.ArchiveCommand).formatParseArgs,
    };
}
