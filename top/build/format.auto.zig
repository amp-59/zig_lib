const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.format = .{
        .write = zl.build.FormatCommand.write,
        .formatLength = zl.build.FormatCommand.formatLength,
        .formatParseArgs = zl.build.FormatCommand.formatParseArgs,
    };
}
