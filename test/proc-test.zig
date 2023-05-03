const top = @import("../zig_lib.zig");
const mem = top.mem;
const sys = top.sys;
const fmt = top.fmt;
const exe = top.exe;
const proc = top.proc;
const time = top.time;
const meta = top.meta;
const file = top.file;
const spec = top.spec;
const build = top.build;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const shdr_size: u64 = @sizeOf(exe.Elf64_Shdr);
const phdr_size: u64 = @sizeOf(exe.Elf64_Phdr);

const Array = mem.UnstructuredStreamView(8, 8, struct {}, .{});

const Mapping = extern struct {
    lb_addr: u64,
    up_addr: u64,
    perms: packed struct {
        read: bool,
        write: bool,
        execute: bool,
        shared: bool,
        private: bool,
    },
    offset: u32,
    device: struct {
        minor: u8,
        major: u8,
    },
    inode: u64,
    pathname: []const u8,
};
fn testCheckResourcesNoErrors() void {
    var buf: [4096]u8 = undefined;
    const dir_fd: u64 = file.open(.{ .errors = .{}, .options = .{ .directory = true } }, "/proc/self/fd");
    var len: u64 = file.getDirectoryEntries(.{ .errors = .{} }, dir_fd, &buf);
    var off: u64 = 0;
    while (off != len) {
        const ent: file.DirectoryEntry = builtin.ptrCast(*const file.DirectoryEntry, buf[off..]).*;
        const name: [:0]const u8 = meta.manyToSlice(builtin.ptrCast([*:0]u8, &ent.array));
        if (ent.kind == sys.S.IFLNKR) {
            const pathname: [:0]const u8 = file.readLinkAt(.{ .errors = .{} }, dir_fd, name, buf[len..]);
            builtin.debug.write(name);
            builtin.debug.write(" -> ");
            builtin.debug.write(pathname);
            builtin.debug.write("\n");
        }
        off +%= ent.reclen;
    }
    file.close(.{ .errors = .{} }, dir_fd);
    const maps_fd: u64 = file.open(.{ .errors = .{} }, "/proc/self/maps");
    len = file.readSlice(.{ .errors = .{} }, maps_fd, &buf);
    builtin.debug.write(buf[0..len]);
    file.close(.{ .errors = .{} }, maps_fd);
}

pub fn main(_: [][*:0]u8, _: [][*:0]u8, aux: *const anyopaque) !void {
    testCheckResourcesNoErrors();

    const vdso_addr: u64 = proc.auxiliaryValue(aux, .vdso_addr).?;
    const clock_gettime: time.ClockGetTime = proc.getVSyscall(time.ClockGetTime, vdso_addr, "clock_gettime").?;

    var vts: time.TimeSpec = undefined;
    _ = clock_gettime(.realtime, &vts);

    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    const ts_diff: time.TimeSpec = time.diff(ts, vts);

    try builtin.expectEqual(u64, ts_diff.sec, 0);
    try builtin.expectBelowOrEqual(u64, ts_diff.nsec, 100);
}
