const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.objcopy = .{
        .write = zl.builder.ObjcopyCommand.write,
        .length = zl.builder.ObjcopyCommand.length,
        .formatParseArgs = zl.builder.ObjcopyCommand.formatParseArgs,
    };
}
