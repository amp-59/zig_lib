const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.objcopy = .{
        .write = zl.build.ObjcopyCommand.write,
        .length = zl.build.ObjcopyCommand.length,
        .formatParseArgs = zl.build.ObjcopyCommand.formatParseArgs,
    };
}
