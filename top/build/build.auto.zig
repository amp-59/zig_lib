const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.build = .{
        .write = zl.build.BuildCommand.write,
        .length = zl.build.BuildCommand.length,
        .formatParseArgs = zl.build.BuildCommand.formatParseArgs,
    };
}
