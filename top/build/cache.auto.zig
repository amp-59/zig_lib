const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.cache = .{ .checkCache = zl.builtin.root.Builder.about.checkCache };
}
