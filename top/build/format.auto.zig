const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.format = .{
        .write = zl.build.FormatCommand.write,
        .length = zl.build.FormatCommand.length,
        .formatParseArgs = zl.build.FormatCommand.formatParseArgs,
    };
}
