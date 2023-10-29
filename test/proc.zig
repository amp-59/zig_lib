const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const sys = zl.sys;
const fmt = zl.fmt;
const elf = zl.elf;
const proc = zl.proc;
const mach = zl.mach;
const time = zl.time;
const meta = zl.meta;
const file = zl.file;
const debug = zl.debug;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;

pub const runtime_assertions: bool = true;
pub const is_safe: bool = true;
pub const logging_override: debug.Logging.Override = debug.spec.logging.override.verbose;

pub const signal_handlers: debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
const ThreadSafeSet = mem.ThreadSafeSet(8, u16, u16);
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
    futex1.* +%= 16;
}
fn testFutexWakeOp(futex1: *u32, futex2: *u32) void {
    proc.futexWakeOp(.{}, futex1, futex2, 1, 1, .{ .op = .Assign, .cmp = .Equal, .to = 0x20, .from = 0x10 }) catch {};
}
fn testCloneAndFutex() !void {
    var ret: void = {};
    var allocator: mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try proc.clone(.{ .function_type = @TypeOf(&testFutexWait) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWait, .{&futex1});
    try time.sleep(.{}, .{ .nsec = 0x10000 });
    try proc.clone(.{ .function_type = @TypeOf(&testFutexWakeOp) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWakeOp, .{ &futex1, &futex2 });
    try time.sleep(.{}, .{ .nsec = 0x20000 });
    try proc.clone(.{ .function_type = @TypeOf(&testFutexWake) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWake, .{&futex2});
    try debug.expectEqual(u32, 32, futex1);
    try debug.expectEqual(u32, 32, futex2);
}
fn testFindNameInPath(vars: [][*:0]u8) !void {
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    const open_spec: file.OpenSpec = .{};
    while (itr.next()) |path| {
        const dir_fd: usize = file.path(.{}, .{ .directory = true, .path = true }, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: usize = file.openAt(open_spec, .{ .no_follow = false }, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        if (try file.accessAt(.{}, .{}, dir_fd, "zig", .{ .exec = true })) {
            break itr.done();
        }
    }
    while (itr.next()) |path| {
        const dir_fd: usize = file.path(.{}, .{ .directory = true, .path = true }, path) catch continue;
        defer file.close(.{ .errors = .{} }, dir_fd);
        const fd: usize = file.openAt(open_spec, .{ .no_follow = false }, dir_fd, "zig") catch continue;
        defer file.close(.{ .errors = .{} }, fd);
        if (try file.accessAt(.{}, .{}, dir_fd, "zig", .{ .exec = true })) {
            break itr.done();
        }
    }
}
fn sleepAndSet(tss: *ThreadSafeSet) void {
    time.sleep(.{ .errors = .{} }, .{ .nsec = 5000000 });
    tss.set(0, 0);
    proc.futexWake(.{ .errors = .{} }, tss.mutex(0), 1);
}
pub fn testFutexOnThreadSafeSet() !void {
    var tss: ThreadSafeSet = .{};
    tss.set(0, 2);
    try debug.expectEqual(u16, tss.get(0), 2);
    const futex: *u32 = tss.mutex(0);
    var ret: void = {};
    var buf: [4096]u8 = undefined;
    try proc.cloneFromBuf(.{ .function_type = @TypeOf(&sleepAndSet) }, .{}, &buf, &ret, &sleepAndSet, .{&tss});
    var exp: u32 = futex.*;
    try proc.futexWait(.{}, futex, exp, &.{ .sec = 1 });
}
pub fn testUpdateSignal() !void {
    var new_action: proc.SignalAction = .{
        .flags = .{},
        .handler = .{ .set = .ignore },
    };
    try proc.updateSignalAction(.{}, .SEGV, new_action, null);
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    _ = args;
    if (builtin.strip_debug_info) {
        try testCloneAndFutex();
        try testFutexOnThreadSafeSet();
    }
    try testUpdateSignal();
    try testFindNameInPath(vars);
    proc.about.sampleAllReports();
}
