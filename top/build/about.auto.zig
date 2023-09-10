const zl = @import("zl");
const types = zl.build;
const start = zl.start;
pub usingnamespace start;
pub fn _start() void {}
export fn load(vtable: *zl.builtin.root.Builder.VTable) void {
    vtable.about.elf.aboutBinary = &zl.builtin.root.Builder.DynamicLoader.about.aboutBinary;
    vtable.about.elf.aboutBinaryDifference = &zl.builtin.root.Builder.DynamicLoader.about.aboutBinaryDifference;
    vtable.about.perf.openFds = &zl.builtin.root.Builder.PerfEvents.openFds;
    vtable.about.perf.readResults = &zl.builtin.root.Builder.PerfEvents.readResults;
    vtable.about.perf.writeResults = &zl.builtin.root.Builder.PerfEvents.writeResults;
}
