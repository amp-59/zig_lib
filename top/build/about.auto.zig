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
            .writeBinary = zl.builtin.root.Builder.DynamicLoader.compare.writeBinary,
            .writeBinaryDifference = zl.builtin.root.Builder.DynamicLoader.compare.writeBinaryDifference,
        },
        .generic = .{
            .aboutTask = zl.builtin.root.Builder.about.aboutTask,
            .printErrors = zl.builtin.root.Builder.about.printErrors,
            .writeTaskDataConfig = zl.builtin.root.Builder.about.writeTaskDataConfig,
        },
    };
}
