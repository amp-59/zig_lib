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

pub const want_stack_traces: bool = true;
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
    futex1.* +%= 16;
}
fn testFutexWakeOp(futex1: *u32, futex2: *u32) void {
    proc.futexWakeOp(.{}, futex1, futex2, 1, 1, .{ .op = .Assign, .cmp = .Equal, .to = 0x20, .from = 0x10 }) catch {};
}
fn testCloneAndFutex() !void {
    var allocator: mem.SimpleAllocator = .{};
    var futex1: u32 = 16;
    var futex2: u32 = 16;
    try proc.clone(.{ .return_type = void }, .{}, allocator.allocateRaw(65536, 16), 65536, {}, &testFutexWait, .{&futex1});
    try time.sleep(.{}, .{ .nsec = 0x10000 });
    try proc.clone(.{ .return_type = void }, .{}, allocator.allocateRaw(65536, 16), 65536, {}, &testFutexWakeOp, .{ &futex1, &futex2 });
    try time.sleep(.{}, .{ .nsec = 0x20000 });
    try proc.clone(.{ .return_type = void }, .{}, allocator.allocateRaw(65536, 16), 65536, {}, &testFutexWake, .{&futex2});
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
pub fn testUpdateSignal() !void {
    var new_action: proc.SignalAction = .{
        .flags = .{},
        .handler = .{ .set = .ignore },
    };
    try proc.updateSignalAction(.{}, .SEGV, new_action, null);
}
pub fn main(_: [][*:0]u8, vars: [][*:0]u8, aux: anytype) !void {
    _ = aux;
    if (builtin.strip_debug_info) {
        try testCloneAndFutex();
    }
    try testUpdateSignal();
    try testFindNameInPath(vars);
    proc.about.sampleAllReports();
}
