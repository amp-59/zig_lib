const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.format = .{
        .formatWriteBuf = zl.build.GenericCommand(zl.build.FormatCommand).formatWriteBuf,
        .formatLength = zl.build.GenericCommand(zl.build.FormatCommand).formatLength,
        .formatParseArgs = zl.build.GenericCommand(zl.build.FormatCommand).formatParseArgs,
    };
}
