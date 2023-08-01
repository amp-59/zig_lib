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

pub fn loadAll(comptime Pointers: type, pathname: [:0]const u8, args: anytype) !void {
    var ptrs: Pointers = undefined;
    {
        var addr: usize = 0x80000000;
        const fd: u64 = file.open(.{ .errors = .{} }, pathname);
        const st: file.Status = file.status(.{ .errors = .{} }, fd);
        const len: usize = mach.alignA64(st.size, 4096);
        file.map(.{ .errors = .{} }, .{}, .{}, fd, addr, len, 0);
        const elf_info: elf.ElfInfo = elf.ElfInfo.init(addr);
        addr +%= elf_info.executableOffset();
        file.map(.{ .errors = .{} }, .{ .exec = true }, .{}, fd, addr, len, 0);
        ptrs = elf_info.loadAll(Pointers);
    }
    var build_cmd: build.BuildCommand = .{ .kind = .exe };
    var allocator: mem.SimpleAllocator = .{};
    ptrs.build(&build_cmd, &allocator, args.ptr, args.len);
    var buf: [4096]u8 = undefined;
    const len: usize = fmt.any(build_cmd).formatWriteBuf(&buf);
    buf[len] = 0xa;
    debug.write(buf[0 .. len +% 1]);
}
pub fn main(args: anytype) !void {
    try loadAll(build.ParseCommand, "zig-out/lib/libparse.so", args);
}
