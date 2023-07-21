const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const sys = zl.sys;
const fmt = zl.fmt;
const exe = zl.exe;
const proc = zl.proc;
const mach = zl.mach;
const time = zl.time;
const meta = zl.meta;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub const signal_handlers: debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
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
fn printHere(x: u64) void {
    var buf: [512]u8 = undefined;
    var len: u64 = fmt.ux64(x).formatWriteBuf(&buf);
    debug.write(buf[0..len]);
    debug.write("\n");
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
    if (builtin.mode == .Debug) return;
    var allocator: mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWait, .{&futex1});
    try time.sleep(.{}, .{ .nsec = 0x10000 });
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWakeOp, .{ &futex1, &futex2 });
    try time.sleep(.{}, .{ .nsec = 0x20000 });
    try proc.clone(.{ .return_type = void }, allocator.allocateRaw(4096, 16), 4096, {}, testFutexWake, .{&futex2});
    try debug.expectEqual(u32, 16, futex1);
    try debug.expectEqual(u32, 32, futex2);
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
    const clock_gettime: time.ClockGetTime = proc.load(time.ClockGetTime, vdso_addr, "clock_gettime").?;
    var vts: time.TimeSpec = undefined;
    _ = clock_gettime(.realtime, &vts);
    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    const ts_diff: time.TimeSpec = time.diff(ts, vts);
    try debug.expectEqual(u64, ts_diff.sec, 0);
    try debug.expectBelowOrEqual(u64, ts_diff.nsec, 1000);
}
fn handlerFn(_: sys.SignalCode) void {}
fn handlerSigInfoFn(_: sys.SignalCode, _: *const proc.SignalInfo, _: ?*const anyopaque) void {
    proc.exit(0);
}
fn testUpdateSignalAction() !void {
    var buf: [4096]u8 = undefined;
    recursion(&buf);
}
fn fault() void {
    var addr: u64 = 0x4000000;
    @as(*u8, @ptrFromInt(addr)).* = '0';
}
fn recursion(buf: *[4096]u8) void {
    var next: [4096]u8 = undefined;
    @memcpy(&next, buf);
    recursion(&next);
}
export fn addTwo(arg1: u64, arg2: u64) u64 {
    return arg1 +% arg2;
}
fn testGetOtherSymbol(args: [][*:0]u8) !void {
    var fd: u64 = try file.open(.{}, meta.manyToSlice(args[0]));
    const st: file.Status = try file.status(.{}, fd);
    const len: usize = mach.alignA64(st.size, 4096);
    try file.map(.{}, .{}, spec.file.map.flags.regular, fd, 0x40000000, len);
    const add = proc.load(*@TypeOf(addTwo), 0x40000000, "addTwo").?;
    try debug.expectEqual(u64, 11, add(5, 6));
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8, aux: anytype) !void {
    try testCloneAndFutex();
    try testFindNameInPath(vars);
    try testGetOtherSymbol(args);
    try testVClockGettime(aux);
    try testUpdateSignalAction();
    proc.about.sampleAllReports();
}
