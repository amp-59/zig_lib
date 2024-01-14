const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.format = .{
        .write = zl.builder.FormatCommand.write,
        .length = zl.builder.FormatCommand.length,
        .formatParseArgs = zl.builder.FormatCommand.formatParseArgs,
    };
}
