const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.build = .{
        .formatWriteBuf = zl.build.BuildCommand.formatWriteBuf,
        .formatLength = zl.build.BuildCommand.formatLength,
        .formatParseArgs = zl.build.BuildCommand.formatParseArgs,
    };
}
