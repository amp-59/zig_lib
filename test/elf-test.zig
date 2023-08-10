const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const mem = zl.mem;
const fmt = zl.fmt;
const elf = zl.elf;
const spec = zl.spec;
const file = zl.file;
const mach = zl.mach;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
const Allocator = mem.SimpleAllocator;
pub const logging_default = spec.logging.default.verbose;

pub const want_stack_traces: bool = false;

const ElfInfo = elf.GenericElfInfo(.{
    .Allocator = mem.SimpleAllocator,
});

pub fn loadAll(comptime Pointers: type, pathname: [:0]const u8, ptrs: *Pointers) void {
    @setRuntimeSafety(false);
    const static = struct {
        var addr: usize = 0x80000000;
    };
    {
        const fd: u64 = file.open(.{ .errors = .{} }, pathname);
        const st: file.Status = file.status(.{ .errors = .{} }, fd);
        const len: usize = mach.alignA64(st.size, 4096);

        file.map(.{ .errors = .{} }, .{ .exec = true }, .{}, fd, static.addr, len, 0);
        var elf_info: ElfInfo = ElfInfo.init(static.addr, len);
        ElfInfo.about.readElfNotice(&elf_info);
        elf_info.remap(fd);
        elf_info.loadAll(Pointers, ptrs);
        file.close(.{ .errors = .{} }, fd);
        static.addr +%= len;
    }
}
pub fn main(args: [][*:0]u8) !void {
    var ptrs: build.Fns = undefined;
    loadAll(build.Fns, "zig-out/lib/libcmd_writers.so", &ptrs);
    loadAll(build.Fns, "zig-out/lib/libcmd_parsers.so", &ptrs);
    var build_cmd: build.BuildCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};

    ptrs.formatParseArgsBuildCommand(&build_cmd, &allocator, args.ptr, args.len);
}
