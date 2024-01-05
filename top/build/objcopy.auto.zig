const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.objcopy = .{
        .write = zl.build.ObjcopyCommand.write,
        .formatLength = zl.build.ObjcopyCommand.formatLength,
        .formatParseArgs = zl.build.ObjcopyCommand.formatParseArgs,
    };
}
