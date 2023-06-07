const top = @import("../zig_lib.zig");
const mem = top.mem;
const sys = top.sys;
const fmt = top.fmt;
const exe = top.exe;
const proc = top.proc;
const mach = top.mach;
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

pub const signal_handlers: builtin.SignalHandlers = .{
    .segmentation_fault = true,
    .bus_error = true,
    .illegal_instruction = true,
    .floating_point_error = true,
};

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
    len = file.read(.{ .errors = .{} }, maps_fd, &buf);
    builtin.debug.write(buf[0..len]);
    file.close(.{ .errors = .{} }, maps_fd);
}

fn printHere(x: u64) void {
    var buf: [512]u8 = undefined;
    var len: u64 = fmt.ux64(x).formatWriteBuf(&buf);
    builtin.debug.write(buf[0..len]);
    builtin.debug.write("\n");
}
fn testFutexWake(futex2: *u32) void {
    proc.futexWake(.{}, futex2, 1) catch {};
}
fn testFutexWait(futex1: *u32) void {
    proc.futexWait(.{}, futex1, 0x10, &.{ .sec = 10 }) catch {};
}
fn testFutexWakeOp(futex1: *u32, futex2: *u32) void {
    proc.futexWakeOp(.{}, futex1, futex2, 1, 1, .{ .op = .Assign, .cmp = .Equal, .to = 0x20, .from = 0x10 }) catch {};
}

fn testCloneAndFutex() !void {
    if (builtin.zig.mode == .Debug) return;
    var allocator: mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try proc.callClone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWait, .{&futex1});
    try time.sleep(.{}, .{ .nsec = 0x10000 });
    try proc.callClone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWakeOp, .{ &futex1, &futex2 });
    try time.sleep(.{}, .{ .nsec = 0x20000 });
    try proc.callClone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWake, .{&futex2});
    try builtin.expectEqual(u32, 16, futex1);
    try builtin.expectEqual(u32, 32, futex2);
}
fn testFindNameInPath(vars: [][*:0]u8) !void {
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    const open_spec: file.OpenSpec = .{
        .options = .{ .no_follow = false },
    };
    while (itr.next()) |path| {
        const dir_fd: u64 = file.path(.{}, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: u64 = file.openAt(open_spec, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = try file.status(.{}, fd);
        if (st.isExecutable(proc.getUserId(), proc.getGroupId())) {
            break itr.done();
        }
    }
    while (itr.next()) |path| {
        const dir_fd: u64 = file.path(.{}, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: u64 = file.openAt(open_spec, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        const st: file.Status = try file.status(.{}, fd);
        if (st.isExecutable(proc.getUserId(), proc.getGroupId())) {
            break itr.done();
        }
    }
}
fn testVClockGettime(aux: *const anyopaque) !void {
    const vdso_addr: u64 = proc.auxiliaryValue(aux, .vdso_addr).?;
    const clock_gettime: time.ClockGetTime = proc.getVSyscall(time.ClockGetTime, vdso_addr, "clock_gettime").?;
    var vts: time.TimeSpec = undefined;
    _ = clock_gettime(.realtime, &vts);
    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    const ts_diff: time.TimeSpec = time.diff(ts, vts);
    try builtin.expectEqual(u64, ts_diff.sec, 0);
    try builtin.expectBelowOrEqual(u64, ts_diff.nsec, 1000);
}

pub fn main(_: [][*:0]u8, vars: [][*:0]u8, aux: *const anyopaque) !void {
    try testCloneAndFutex();
    testCheckResourcesNoErrors();
    try testFindNameInPath(vars);
    try testVClockGettime(aux);
}
