const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.objcopy = .{
        .formatWriteBuf = zl.build.GenericCommand(zl.build.ObjcopyCommand).formatWriteBuf,
        .formatLength = zl.build.GenericCommand(zl.build.ObjcopyCommand).formatLength,
        .formatParseArgs = zl.build.GenericCommand(zl.build.ObjcopyCommand).formatParseArgs,
    };
}
