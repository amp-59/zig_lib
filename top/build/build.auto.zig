const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.build = .{
        .formatWriteBuf = zl.build.GenericCommand(zl.build.BuildCommand).formatWriteBuf,
        .formatLength = zl.build.GenericCommand(zl.build.BuildCommand).formatLength,
        .formatParseArgs = zl.build.GenericCommand(zl.build.BuildCommand).formatParseArgs,
    };
}
