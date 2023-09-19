pub const fmt = @import("../fmt.zig");
pub const debug = @import("../debug.zig");
pub const builtin = @import("../builtin.zig");
pub const extra = @import("./extra.zig");
pub const Clone = packed struct(u32) {
    zb0: u7 = 0,
    new_time: bool = false,
    vm: bool = false,
    fs: bool = false,
    files: bool = false,
    signal_handlers: bool = false,
    pid_fd: bool = false,
    traced: bool = false,
    vfork: bool = false,
    zb15: u1 = 0,
    thread: bool = false,
    new_namespace: bool = false,
    sysvsem: bool = false,
    set_thread_local_storage: bool = false,
    set_parent_thread_id: bool = false,
    clear_child_thread_id: bool = false,
    detached: bool = false,
    untraced: bool = false,
    set_child_thread_id: bool = false,
    new_cgroup: bool = false,
    new_uts: bool = false,
    new_ipc: bool = false,
    new_user: bool = false,
    new_pid: bool = false,
    new_net: bool = false,
    io: bool = false,
    fn assert(flags: @This(), val: u32) void {
        debug.assertEqual(u32, @as(u32, @bitCast(flags)), val);
    }
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: u32 = @bitCast(format);
        for ([_]struct { []const u8, u6 }{
            .{ "new_time", 7 },
            .{ "vm", 1 },
            .{ "fs", 1 },
            .{ "files", 1 },
            .{ "signal_handlers", 1 },
            .{ "pid_fd", 1 },
            .{ "traced", 1 },
            .{ "vfork", 1 },
            .{ "thread", 2 },
            .{ "new_namespace", 1 },
            .{ "sysvsem", 1 },
            .{ "set_thread_local_storage", 1 },
            .{ "set_parent_thread_id", 1 },
            .{ "clear_child_thread_id", 1 },
            .{ "detached", 1 },
            .{ "untraced", 1 },
            .{ "set_child_thread_id", 1 },
            .{ "new_cgroup", 1 },
            .{ "new_uts", 1 },
            .{ "new_ipc", 1 },
            .{ "new_user", 1 },
            .{ "new_pid", 1 },
            .{ "new_net", 1 },
            .{ "io", 1 },
        }) |pair| {
            tmp >>= pair[1];
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        if (format.clear_signal_handlers) {
            len += 21;
        }
        if (format.new_time) {
            len += 8;
        }
        if (format.vm) {
            len += 2;
        }
        if (format.fs) {
            len += 2;
        }
        if (format.files) {
            len += 5;
        }
        if (format.signal_handlers) {
            len += 15;
        }
        if (format.pid_fd) {
            len += 6;
        }
        if (format.traced) {
            len += 6;
        }
        if (format.vfork) {
            len += 5;
        }
        if (format.thread) {
            len += 6;
        }
        if (format.new_namespace) {
            len += 13;
        }
        if (format.sysvsem) {
            len += 7;
        }
        if (format.set_thread_local_storage) {
            len += 24;
        }
        if (format.set_parent_thread_id) {
            len += 20;
        }
        if (format.clear_child_thread_id) {
            len += 21;
        }
        if (format.detached) {
            len += 8;
        }
        if (format.untraced) {
            len += 8;
        }
        if (format.set_child_thread_id) {
            len += 19;
        }
        if (format.new_cgroup) {
            len += 10;
        }
        if (format.new_uts) {
            len += 7;
        }
        if (format.new_ipc) {
            len += 7;
        }
        if (format.new_user) {
            len += 8;
        }
        if (format.new_pid) {
            len += 7;
        }
        if (format.new_net) {
            len += 7;
        }
        if (format.io) {
            len += 2;
        }
    }
    comptime {
        if (builtin.comptime_assertions) {
            assert(.{ .new_time = true }, 0x80);
            assert(.{ .vm = true }, 0x100);
            assert(.{ .fs = true }, 0x200);
            assert(.{ .files = true }, 0x400);
            assert(.{ .signal_handlers = true }, 0x800);
            assert(.{ .pid_fd = true }, 0x1000);
            assert(.{ .traced = true }, 0x2000);
            assert(.{ .vfork = true }, 0x4000);
            assert(.{ .thread = true }, 0x10000);
            assert(.{ .new_namespace = true }, 0x20000);
            assert(.{ .sysvsem = true }, 0x40000);
            assert(.{ .set_thread_local_storage = true }, 0x80000);
            assert(.{ .set_parent_thread_id = true }, 0x100000);
            assert(.{ .clear_child_thread_id = true }, 0x200000);
            assert(.{ .detached = true }, 0x400000);
            assert(.{ .untraced = true }, 0x800000);
            assert(.{ .set_child_thread_id = true }, 0x1000000);
            assert(.{ .new_cgroup = true }, 0x2000000);
            assert(.{ .new_uts = true }, 0x4000000);
            assert(.{ .new_ipc = true }, 0x8000000);
            assert(.{ .new_user = true }, 0x10000000);
            assert(.{ .new_pid = true }, 0x20000000);
            assert(.{ .new_net = true }, 0x40000000);
            assert(.{ .io = true }, 0x80000000);
        }
    }
};
pub const SignalAction = packed struct(usize) {
    no_child_stop: bool = false,
    no_child_wait: bool = false,
    siginfo: bool = false,
    zb3: u7 = 0,
    unsupported: bool = false,
    expose_tagbits: bool = false,
    zb12: u14 = 0,
    restorer: bool = false,
    on_stack: bool = false,
    restart: bool = false,
    zb29: u1 = 0,
    no_defer: bool = false,
    reset_handler: bool = false,
    zb32: u32 = 0,
    fn assert(flags: @This(), val: usize) void {
        debug.assertEqual(usize, @as(usize, @bitCast(flags)), val);
    }
    pub fn formatWriteBuf(format: @This(), buf: [*]u8) usize {
        var ptr: [*]u8 = buf;
        var tmp: usize = @bitCast(format);
        for ([_]struct { []const u8, u6 }{
            .{ "no_child_stop", 0 },
            .{ "no_child_wait", 1 },
            .{ "siginfo", 1 },
            .{ "unsupported", 8 },
            .{ "expose_tagbits", 1 },
            .{ "restorer", 15 },
            .{ "on_stack", 1 },
            .{ "restart", 1 },
            .{ "no_defer", 2 },
            .{ "reset_handler", 1 },
        }) |pair| {
            tmp >>= pair[1];
            if (tmp & 1 != 0) {
                ptr[0] = '|';
                ptr = fmt.strcpyEqu(ptr + @intFromBool(ptr != buf), pair[0]);
            }
        }
        return fmt.strlen(ptr, buf);
    }
    pub fn formatLength(format: @This()) usize {
        var len: usize = 0;
        if (format.no_child_stop) {
            len += 13;
        }
        if (format.no_child_wait) {
            len += 13;
        }
        if (format.siginfo) {
            len += 7;
        }
        if (format.unsupported) {
            len += 11;
        }
        if (format.expose_tagbits) {
            len += 14;
        }
        if (format.restorer) {
            len += 8;
        }
        if (format.on_stack) {
            len += 8;
        }
        if (format.restart) {
            len += 7;
        }
        if (format.no_defer) {
            len += 8;
        }
        if (format.reset_handler) {
            len += 13;
        }
    }
    comptime {
        if (builtin.comptime_assertions) {
            assert(.{ .no_child_stop = true }, 0x1);
            assert(.{ .no_child_wait = true }, 0x2);
            assert(.{ .siginfo = true }, 0x4);
            assert(.{ .unsupported = true }, 0x400);
            assert(.{ .expose_tagbits = true }, 0x800);
            assert(.{ .restorer = true }, 0x4000000);
            assert(.{ .on_stack = true }, 0x8000000);
            assert(.{ .restart = true }, 0x10000000);
            assert(.{ .no_defer = true }, 0x40000000);
            assert(.{ .reset_handler = true }, 0x80000000);
        }
    }
};
