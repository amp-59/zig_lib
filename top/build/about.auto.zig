const zl = @import("zl");
pub usingnamespace zl.start;
export fn load(fp: *zl.builtin.root.Builder.FunctionPointers) void {
    fp.about = .{
        .perf = .{
            .openFds = zl.builtin.root.Builder.PerfEvents.openFds,
            .readResults = zl.builtin.root.Builder.PerfEvents.readResults,
            .writeResults = zl.builtin.root.Builder.PerfEvents.writeResults,
        },
        .elf = .{
            .writeBinary = zl.builtin.root.Builder.DynamicLoader.about.writeBinary,
            .writeBinaryDifference = zl.builtin.root.Builder.DynamicLoader.about.writeBinaryDifference,
        },
        .generic = .{
            .taskNotice = zl.builtin.root.Builder.about.taskNotice,
        },
    };
}
