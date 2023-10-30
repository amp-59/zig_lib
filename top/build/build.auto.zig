const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.build = .{
        .formatWriteBuf = zl.build.GenericCommand(zl.build.BuildCommand).formatWriteBuf,
        .formatLength = zl.build.GenericCommand(zl.build.BuildCommand).formatLength,
        .formatParseArgs = zl.build.GenericCommand(zl.build.BuildCommand).formatParseArgs,
        .fieldEditDistance = zl.build.GenericCommand(zl.build.BuildCommand).fieldEditDistance,
        .writeFieldEditDistance = zl.build.GenericCommand(zl.build.BuildCommand).writeFieldEditDistance,
        .indexOfCommonLeastDifference = zl.build.GenericCommand(zl.build.BuildCommand).indexOfCommonLeastDifference,
    };
}
