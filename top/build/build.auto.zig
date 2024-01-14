const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.build = .{
        .write = zl.builder.BuildCommand.write,
        .length = zl.builder.BuildCommand.length,
        .formatParseArgs = zl.builder.BuildCommand.formatParseArgs,
    };
}
