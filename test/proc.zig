const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;

pub const runtime_assertions: bool = true;
pub const is_safe: bool = true;
pub const logging_override: zl.debug.Logging.Override = zl.debug.spec.logging.override.verbose;

pub const signal_handlers: zl.debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
const ThreadSafeSet = zl.mem.ThreadSafeSet(8, u16, u16);
const Array = zl.mem.UnstructuredStreamView(8, 8, struct {}, .{});
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
    const len: u64 = zl.fmt.ux64(x).formatWriteBuf(&buf);
    zl.debug.write(buf[0..len]);
    zl.debug.write("\n");
}
fn testFutexWake(futex2: *u32) void {
    zl.proc.futexWake(.{}, futex2, 1) catch {};
}
fn testFutexWait(futex1: *u32) void {
    zl.proc.futexWait(.{}, futex1, 0x10, &.{ .sec = 10 }) catch {};
    futex1.* +%= 16;
}
fn testFutexWakeOp(futex1: *u32, futex2: *u32) void {
    zl.proc.futexWakeOp(.{}, futex1, futex2, 1, 1, .{ .op = .Assign, .cmp = .Equal, .to = 0x20, .from = 0x10 }) catch {};
}
fn testCloneAndFutex() !void {
    var ret: void = {};
    var allocator: zl.mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try zl.proc.clone(.{ .function_type = @TypeOf(&testFutexWait) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWait, .{&futex1});
    try zl.time.sleep(.{}, .{ .nsec = 0x10000 });
    try zl.proc.clone(.{ .function_type = @TypeOf(&testFutexWakeOp) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWakeOp, .{ &futex1, &futex2 });
    try zl.time.sleep(.{}, .{ .nsec = 0x20000 });
    try zl.proc.clone(.{ .function_type = @TypeOf(&testFutexWake) }, .{}, allocator.allocateRaw(65536, 16), 65536, &ret, testFutexWake, .{&futex2});
    try zl.debug.expectEqual(u32, 32, futex1);
    try zl.debug.expectEqual(u32, 32, futex2);
}
fn testFindNameInPath(vars: [][*:0]u8) !void {
    var itr: zl.proc.PathIterator = .{
        .paths = zl.proc.environmentValue(vars, "PATH").?,
    };
    const open_spec: zl.file.OpenSpec = .{};
    while (itr.next()) |path| {
        const dir_fd: usize = zl.file.path(.{}, .{ .directory = true, .path = true }, path) catch continue;
        defer zl.file.close(.{ .errors = .{} }, dir_fd);
        const fd: usize = zl.file.openAt(open_spec, .{ .no_follow = false }, dir_fd, "zig") catch continue;
        defer zl.file.close(.{ .errors = .{} }, fd);
        if (try zl.file.accessAt(.{}, .{}, dir_fd, "zig", .{ .exec = true })) {
            break itr.done();
        }
    }
    while (itr.next()) |path| {
        const dir_fd: usize = zl.file.path(.{}, .{ .directory = true, .path = true }, path) catch continue;
        defer zl.file.close(.{ .errors = .{} }, dir_fd);
        const fd: usize = zl.file.openAt(open_spec, .{ .no_follow = false }, dir_fd, "zig") catch continue;
        defer zl.file.close(.{ .errors = .{} }, fd);
        if (try zl.file.accessAt(.{}, .{}, dir_fd, "zig", .{ .exec = true })) {
            break itr.done();
        }
    }
}
fn sleepAndSet(tss: *ThreadSafeSet) void {
    zl.time.sleep(.{ .errors = .{} }, .{ .nsec = 5000000 });
    tss.set(0, 0);
    zl.proc.futexWake(.{ .errors = .{} }, tss.mutex(0), 1);
}
pub fn testFutexOnThreadSafeSet() !void {
    var tss: ThreadSafeSet = .{};
    tss.set(0, 2);
    try zl.debug.expectEqual(u16, tss.get(0), 2);
    const futex: *u32 = tss.mutex(0);
    var ret: void = {};
    var buf: [4096]u8 = undefined;
    try zl.proc.cloneFromBuf(.{ .function_type = @TypeOf(&sleepAndSet) }, .{}, &buf, &ret, &sleepAndSet, .{&tss});
    const exp: u32 = futex.*;
    try zl.proc.futexWait(.{}, futex, exp, &.{ .sec = 1 });
}
pub fn testUpdateSignal() !void {
    const new_action: zl.proc.SignalAction = .{
        .flags = .{},
        .handler = .{ .set = .ignore },
    };
    try zl.proc.updateSignalAction(.{}, .SEGV, new_action, null);
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    _ = args;
    if (zl.builtin.strip_debug_info) {
        try testCloneAndFutex();
        try testFutexOnThreadSafeSet();
    }
    try testUpdateSignal();
    try testFindNameInPath(vars);
    zl.proc.about.sampleAllReports();
}
