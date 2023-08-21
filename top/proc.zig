const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const elf = @import("./elf.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const SignalAction = extern struct {
    handler: Handler = .{ .set = .default },
    flags: Options = .{},
    restorer: *const fn () callconv(.Naked) void = restoreRunTime,
    mask: [2]u32 = .{0} ** 2,
    const Options = packed struct(usize) {
        no_child_stop: bool = false,
        no_child_wait: bool = false,
        siginfo: bool = true,
        zb3: u7 = 0,
        unsupported: bool = false,
        expose_tagbits: bool = false,
        zb12: u14 = 0,
        restorer: bool = true,
        on_stack: bool = false,
        restart: bool = true,
        zb29: u1 = 0,
        no_defer: bool = false,
        reset_handler: bool = true,
        zb32: u32 = 0,
    };
    const Handler = extern union {
        set: enum(usize) { ignore = 1, default = 0 },
        handler: *const fn (sys.SignalCode) void,
        action: *const fn (sys.SignalCode, *const SignalInfo, ?*const anyopaque) void,
    };
};
pub const SignalInfo = extern struct {
    signo: u32,
    errno: u32,
    code: u32,
    _: u32,
    fields: Fields,
    const Fields = extern union {
        _: [28]u32,
        kill: Kill,
        timer: Timer,
        rt: Runtime,
        child: Child,
        fault: Fault,
        poll: Poll,
        sys: Sys,
    };
    const Val = extern union {
        int: u64,
        ptr: u64,
    };
    const AddrBound = extern struct {
        lower: u64,
        upper: u64,
    };
    const Kill = extern struct {
        pid: u32,
        uid: u32,
    };
    const Timer = extern struct {
        tid: u32,
        overrun: u32,
        sigval: Val,
    };
    const Runtime = extern struct {
        pid: u32,
        uid: u32,
        sigval: Val,
    };
    const Bounds = extern struct {
        addr_bnd: AddrBound,
        pkey: u32,
    };
    const Child = extern struct {
        pid: u32,
        uid: u32,
        status: u32,
        utime: u64,
        stime: u64,
    };
    const Fault = extern struct {
        addr: u64,
        addr_lsb: u16,
        bounds: Bounds,
    };
    const Poll = extern struct {
        band: u64,
        fd: u32,
    };
    const Sys = extern struct {
        call_addr: u64,
        syscall: u32,
        arch: u32,
    };
};
pub const AuxiliaryVectorEntry = enum(u64) {
    null = 0,
    exec_fd = AUX.EXECFD,
    phdr_addr = AUX.PHDR,
    phdr_entry_size = AUX.PHENT,
    phdr_num = AUX.PHNUM,
    page_size = AUX.PAGESZ,
    base_addr = AUX.BASE,
    flags = AUX.FLAGS,
    entry_addr = AUX.ENTRY,
    euid = AUX.EUID,
    gid = AUX.GID,
    egid = AUX.EGID,
    platform = AUX.PLATFORM,
    hwcap = AUX.HWCAP,
    clock_freq = AUX.CLKTCK,
    fpu_ctrl = AUX.FPUCW,
    d_cache_blk_size = AUX.DCACHEBSIZE,
    i_cache_blk_size = AUX.ICACHEBSIZE,
    u_cache_blk_size = AUX.UCACHEBSIZE,
    secure = AUX.SECURE,
    base_platform = AUX.BASE_PLATFORM,
    random = AUX.RANDOM,
    name = AUX.EXECFN,
    vsyscall_addr = AUX.SYSINFO,
    vdso_addr = AUX.SYSINFO_EHDR,
    l1i_cache_size = AUX.L1I_CACHESIZE,
    l1i_cache_geometry = AUX.L1I_CACHEGEOMETRY,
    l1d_cache_size = AUX.L1D_CACHESIZE,
    l1d_cache_geometry = AUX.L1D_CACHEGEOMETRY,
    l2_cache_size = AUX.L2_CACHESIZE,
    l2_cache_geometry = AUX.L2_CACHEGEOMETRY,
    l3_cache_size = AUX.L3_CACHESIZE,
    l3_cache_geometry = AUX.L3_CACHEGEOMETRY,
    const AUX = sys.AUX;
};
pub const Clone = struct {
    const Options = meta.EnumBitField(enum(u64) {
        new_time = CLONE.NEWTIME,
        pid_fd = CLONE.PIDFD,
        thread = CLONE.THREAD,
        set_thread_local_storage = CLONE.SETTLS,
        set_parent_thread_id = CLONE.PARENT_SETTID,
        set_child_thread_id = CLONE.CHILD_SETTID,
        clear_child_thread_id = CLONE.CHILD_CLEARTID,
        traced = CLONE.PTRACE,
        untraced = CLONE.UNTRACED,
        signal_handlers = CLONE.SIGHAND,
        clear_signal_handlers = CLONE.CLEAR_SIGHAND,
        new_namespace = CLONE.NEWNS,
        new_ipc = CLONE.NEWIPC,
        new_uts = CLONE.NEWUTS,
        new_user = CLONE.NEWUSER,
        new_net = CLONE.NEWNET,
        new_pid = CLONE.NEWPID,
        sysvsem = CLONE.SYSVSEM,
        detached = CLONE.DETACHED,
        vfork = CLONE.VFORK,
        files = CLONE.FILES,
        vm = CLONE.VM,
        fs = CLONE.FS,
        io = CLONE.IO,
        new_cgroup = CLONE.NEWCGROUP,
        const CLONE = sys.CLONE;
    });
};
pub const IdType = enum(u64) {
    pid = ID.PID,
    all = ID.ALL,
    group = ID.PGID,
    file = ID.PIDFD,
    const ID = sys.ID;
};
pub const WaitId = struct {
    const Options = meta.EnumBitField(enum(u64) {
        exited = WAIT.EXITED,
        stopped = WAIT.STOPPED,
        continued = WAIT.CONTINUED,
        no_wait = WAIT.NOWAIT,
        clone = WAIT.CLONE,
        no_thread = WAIT.NOTHREAD,
        all = WAIT.ALL,
        const WAIT = sys.WAIT;
    });
};
pub const Wait = struct {
    const Options = meta.EnumBitField(enum(u64) {
        exited = WAIT.NOHANG,
        continued = WAIT.CONTINUED,
        untraced = WAIT.UNTRACED,
        const WAIT = sys.WAIT;
    });
};
pub const Return = extern struct {
    pid: u32,
    status: u32,
};
pub const CloneArgs = extern struct {
    /// Flags bit mask
    flags: Clone.Options,
    /// Where to store PID file descriptor (int *)
    pidfd_addr: u64 = 0,
    /// Where to store child TID in child's memory (pid_t *)
    child_tid_addr: u64,
    /// Where to store child TID in parent's memory (pid_t *)
    parent_tid_addr: u64,
    /// Signal to deliver to parent on
    /// child termination
    exit_signal: u64 = 0,
    /// Pointer to lowest byte of stack
    stack_addr: u64,
    /// Size of stack
    stack_len: u64,
    /// Location of new TLS
    tls_addr: u64,
    /// Pointer to a pid_t array
    set_tid_addr: u64 = 0,
    /// Number of elements in set_tid
    set_tid_len: u64 = 0,
    /// File descriptor for target cgroup
    cgroup: u64 = 0,
};
pub const FutexOp = enum(u64) {
    wait = 0,
    wake = 1,
    requeue = 3,
    cmp_requeue = 4,
    wake_op = 5,
    wait_bitset = 9,
    wake_bitset = 10,
    wait_requeue_pi = 11,
    cmp_requeue_pi = 12,
    lock_pi2 = 13,
    pub const Options = packed struct(u2) {
        private: bool = false,
        clock_realtime: bool = false,
    };
    pub const WakeOp = packed struct(u32) {
        from: u12,
        to: u12,
        cmp: enum(u4) {
            Equal = 0,
            NotEqual = 1,
            Below = 2,
            BelowOrEqual = 3,
            Above = 4,
            AboveOrEqual = 5,
        },
        shl: bool = false,
        op: enum(u3) {
            Assign = 0,
            Add = 1,
            Or = 2,
            AndN = 3,
            Xor = 4,
        },
    };
};
pub const WaitSpec = struct {
    options: Options = .{},
    return_type: type = Return,
    errors: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    logging: debug.Logging.SuccessError = .{},
    const Specification = @This();
    const Options = struct {
        exited: bool = false,
        stopped: bool = false,
        continued: bool = false,
    };
    const For = union(enum) {
        pid: usize,
        pgid: usize,
        ppid,
        any,
    };
    fn pid(id: For) u64 {
        const val: isize = switch (id) {
            .ppid => 0,
            .any => -1,
            .pid => |val| @intCast(val),
            .pgid => |val| @intCast(val),
        };
        return @bitCast(val);
    }
    fn flags(comptime spec: WaitSpec) Wait {
        var ret: Wait = .{ .val = 0 };
        if (spec.options.exited) {
            ret.set(.exited);
        }
        if (spec.options.stopped) {
            ret.set(.stopped);
        }
        if (spec.options.continued) {
            ret.set(.continued);
        }
    }
};
pub const WaitIdSpec = struct {
    id_type: IdType = .pid,
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    logging: debug.Logging.SuccessError = .{},
    return_type: type = u64,
    const Specification = @This();
    const Options = struct {
        exited: bool = true,
        stopped: bool = false,
        continued: bool = false,
        clone: bool = false,
        no_thread: bool = false,
        all: bool = false,
    };
    fn flags(comptime spec: WaitIdSpec) WaitId {
        var ret: WaitId = .{ .val = 0 };
        if (spec.options.exited) {
            ret.set(.exited);
        }
        if (spec.options.stopped) {
            ret.set(.stopped);
        }
        if (spec.options.continued) {
            ret.set(.continued);
        }
        if (spec.options.clone) {
            ret.set(.clone);
        }
        if (spec.options.no_thread) {
            ret.set(.no_thread);
        }
        if (spec.options.all) {
            ret.set(.all);
        }
        return ret;
    }
};
pub const ForkSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.fork_errors },
    logging: debug.Logging.SuccessError = .{},
    return_type: type = u64,
    const Specification = @This();
};
pub const CommandSpec = struct {
    options: Options = .{},
    errors: Errors = .{},
    logging: Logging = .{},
    return_type: type = void,
    args_type: type = []const [*:0]u8,
    vars_type: type = []const [*:0]u8,
    const Specification = @This();
    pub const Options = struct {
        no_follow: bool = false,
    };
    pub const Logging = packed struct {
        execve: debug.Logging.AttemptError = .{},
        fork: debug.Logging.SuccessError = .{},
        waitpid: debug.Logging.SuccessError = .{},
    };
    pub const Errors = struct {
        execve: sys.ErrorPolicy = .{ .throw = sys.execve_errors },
        fork: sys.ErrorPolicy = .{ .throw = sys.fork_errors },
        waitpid: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    };
    fn fork(comptime spec: CommandSpec) ForkSpec {
        return .{
            .errors = spec.errors.fork,
            .logging = spec.logging.fork,
        };
    }
    fn waitpid(comptime spec: CommandSpec) WaitSpec {
        return .{
            .errors = spec.errors.waitpid,
            .logging = spec.logging.waitpid,
            .return_type = Return,
        };
    }
    fn exec(comptime spec: CommandSpec) file.ExecuteSpec {
        comptime return .{
            .errors = spec.errors.execve,
            .logging = spec.logging.execve,
            .args_type = spec.args_type,
            .vars_type = spec.vars_type,
        };
    }
    fn flags(comptime spec: CommandSpec) file.Execute {
        var flags_bitfield: file.Execute = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
};
pub const CloneSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.clone_errors },
    return_type: type = usize,
    logging: debug.Logging.SuccessError = .{},
    const Options = struct {
        address_space: bool = true,
        file_system: bool = true,
        files: bool = true,
        signal_handlers: bool = true,
        thread: bool = true,
        sysvsem: bool = true,
        set_thread_local_storage: bool = true,
        set_parent_thread_id: bool = true,
        set_child_thread_id: bool = true,
        clear_child_thread_id: bool = true,
        io: bool = false,
    };
    const Specification = @This();
    const CLONE = sys.CLONE;
    pub inline fn flags(comptime spec: CloneSpec) Clone.Options {
        var clone_flags: Clone.Options = .{ .val = 0 };
        if (spec.options.address_space) {
            clone_flags.set(.vm);
        }
        if (spec.options.file_system) {
            clone_flags.set(.fs);
        }
        if (spec.options.files) {
            clone_flags.set(.files);
        }
        if (spec.options.thread) {
            clone_flags.set(.thread);
        }
        if (spec.options.signal_handlers) {
            clone_flags.set(.signal_handlers);
        }
        if (spec.options.set_thread_local_storage) {
            clone_flags.set(.set_thread_local_storage);
        }
        if (spec.options.set_parent_thread_id) {
            clone_flags.set(.set_parent_thread_id);
        }
        if (spec.options.set_child_thread_id) {
            clone_flags.set(.set_child_thread_id);
        }
        if (spec.options.clear_child_thread_id) {
            clone_flags.set(.clear_child_thread_id);
        }
        if (spec.options.io) {
            clone_flags.set(.io);
        }
        return clone_flags;
    }
};
pub const FutexSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.futex_errors },
    return_type: type = void,
    logging: debug.Logging.AttemptSuccessAcquireReleaseError = .{},
};
pub const Status = struct {
    pub inline fn exit(status: u32) u8 {
        return mach.shr32T(u8, status & 0xff00, 8);
    }
    pub inline fn term(status: u32) u32 {
        return status & 0x7f;
    }
    pub inline fn stop(status: u32) u32 {
        return Status.exit(status);
    }
    pub inline fn ifExited(status: u32) bool {
        return Status.term(status) == 0;
    }
    pub inline fn ifSignaled(status: u32) bool {
        return status & 0x7f >= 2;
    }
    pub inline fn ifStopped(status: u32) bool {
        return status & 0xff == 0x7f;
    }
    pub inline fn ifContinued(status: u32) bool {
        return status == 0xffff;
    }
    pub inline fn coreDump(status: u32) u32 {
        return status & 0x80;
    }
};
pub fn getUserId() u16 {
    return @as(u16, @truncate(sys.call(.getuid, .{}, u64, .{})));
}
pub fn getEffectiveUserId() u16 {
    return @as(u16, @truncate(sys.call(.geteuid, .{}, u64, .{})));
}
pub fn getGroupId() u16 {
    return @as(u16, @truncate(sys.call(.getgid, .{}, u64, .{})));
}
pub fn getEffectiveGroupId() u16 {
    return @as(u16, @truncate(sys.call(.getegid, .{}, u64, .{})));
}
pub fn waitPid(comptime spec: WaitSpec, id: WaitSpec.For) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    var ret: Return = comptime builtin.all(Return);
    const status_addr: u64 = @intFromPtr(&ret.status);
    if (meta.wrap(sys.call(.wait4, spec.errors, u32, .{ WaitSpec.pid(id), status_addr, 0, 0, 0 }))) |pid| {
        ret.pid = pid;
        if (logging.Success) {
            about.waitNotice(id, ret);
        }
        if (spec.return_type == Return) {
            return ret;
        }
    } else |wait_error| {
        if (logging.Error) {
            debug.about.aboutError(about.wait_s, @errorName(wait_error));
        }
        return wait_error;
    }
}
pub fn waitId(comptime spec: WaitIdSpec, id: u64, siginfo: *SignalInfo) sys.ErrorUnion(spec.errors, spec.return_type) {
    const id_type: u64 = @intFromEnum(spec.id_type);
    const siginfo_buf_addr: u64 = @intFromPtr(siginfo);
    const flags: WaitId = comptime spec.flags();
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.waitid, spec.errors, spec.return_type, .{ id_type, id, siginfo_buf_addr, flags.val, 0 }))) |pid| {
        return pid;
    } else |wait_error| {
        if (logging.Error) {
            debug.about.aboutError(about.wait_s, @errorName(wait_error));
        }
        return wait_error;
    }
}
pub fn fork(comptime spec: ForkSpec) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: debug.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.fork, spec.errors, spec.return_type, .{}))) |pid| {
        if (logging.Success and pid != 0) {
            about.forkNotice(pid);
        }
        return pid;
    } else |fork_error| {
        if (logging.Error) {
            debug.about.aboutError(about.fork_s, @errorName(fork_error));
        }
        return fork_error;
    }
}
pub fn command(comptime spec: CommandSpec, pathname: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.ErrorUnion(.{
    .throw = spec.errors.execve.throw ++ spec.errors.fork.throw ++ spec.errors.waitpid.throw,
    .abort = spec.errors.execve.abort ++ spec.errors.fork.abort ++ spec.errors.waitpid.abort,
}, u8) {
    const fork_spec: ForkSpec = comptime spec.fork();
    const wait_spec: WaitSpec = comptime spec.waitpid();
    const exec_spec: file.ExecuteSpec = comptime spec.exec();
    const pid: u64 = try meta.wrap(fork(fork_spec));
    if (pid == 0) {
        try meta.wrap(file.execPath(exec_spec, pathname, args, vars));
    }
    const ret: wait_spec.return_type = try meta.wrap(waitPid(wait_spec, .{ .pid = pid }));
    if (wait_spec.return_type != void) {
        return Status.exit(ret.status);
    }
}
pub fn commandAt(comptime spec: CommandSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.ErrorUnion(.{
    .throw = spec.errors.execve.throw ++ spec.errors.fork.throw ++ spec.errors.waitpid.throw,
    .abort = spec.errors.execve.abort ++ spec.errors.fork.abort ++ spec.errors.waitpid.abort,
}, u8) {
    const fork_spec: ForkSpec = comptime spec.fork();
    const wait_spec: WaitSpec = comptime spec.waitpid();
    const exec_spec: file.ExecuteSpec = comptime spec.exec();
    const pid: u64 = try meta.wrap(fork(fork_spec));
    if (pid == 0) {
        try meta.wrap(file.execAt(exec_spec, dir_fd, name, args, vars));
    }
    var status: u32 = 0;
    try meta.wrap(waitPid(wait_spec, .{ .pid = pid }, &status));
    return Status.exit(status);
}
pub fn futexWait(comptime futex_spec: FutexSpec, futex: *u32, value: u32, timeout: *const time.TimeSpec) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    const logging: debug.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        about.futexWaitNotice(futex, value, timeout);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, futex_spec.return_type, [6]usize{ @intFromPtr(futex), 0, value, @intFromPtr(timeout), 0, 0 }))) |ret| {
        if (logging.Acquire) {
            about.futexWaitNotice(futex, value, timeout);
        }
        return ret;
    } else |futex_error| {
        if (logging.Error) {
            about.futexWaitError(futex_error, futex, value, timeout);
        }
        return futex_error;
    }
}
pub fn futexWake(comptime futex_spec: FutexSpec, futex: *u32, count: u32) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    const logging: debug.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        about.futexWakeAttempt(futex, count);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, u32, [6]usize{ @intFromPtr(futex), 1, count, 0, 0, 0 }))) |ret| {
        if (logging.Release) {
            about.futexWakeNotice(futex, count, ret);
        }
        if (futex_spec.return_type != void) {
            return ret;
        }
    } else |futex_error| {
        if (logging.Error) {
            about.futexWakeError(futex_error, futex, count);
        }
        return futex_error;
    }
}
pub fn futexWakeOp(comptime futex_spec: FutexSpec, futex1: *u32, futex2: *u32, count1: u32, count2: u32, wake_op: FutexOp.WakeOp) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    const logging: debug.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        about.futexWakeOpAttempt(futex1, futex2, count1, count2, wake_op);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, u32, [6]usize{
        @intFromPtr(futex1), 5, count1, count2, @intFromPtr(futex2), @as(u32, @bitCast(wake_op)),
    }))) |ret| {
        if (logging.Acquire) {
            about.futexWakeOpNotice(futex1, futex2, count1, count2, wake_op, ret);
        }
    } else |futex_error| {
        if (logging.Error) {
            about.futexWakeOpError(futex_error, futex1, futex2, count1, count2, wake_op);
        }
        return futex_error;
    }
}
fn futexRequeue(comptime futex_spec: FutexSpec, futex1: *u32, futex2: *u32, count1: u32, count2: u32, from: ?u32) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    @setRuntimeSafety(false);
    const logging: debug.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        //
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, futex_spec.return_type, [6]usize{
        @intFromPtr(futex1), 3 +% @intFromBool(from != 0), count1, count2, @intFromPtr(futex2), from.?,
    }))) {
        if (logging.Acquire) {
            //
        }
    } else |futex_error| {
        if (logging.Error) {
            //
        }
        return futex_error;
    }
}
const SignalActionSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.sigaction_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    options: Options = .{},
    const Options = packed struct {
        no_child_stop: bool = false,
        no_child_wait: bool = false,
        no_defer: bool = false,
        on_stack: bool = false,
        restart: bool = true,
        reset: bool = true,
        restorer: bool = false,
        siginfo: bool = true,
        unsupported: bool = false,
    };
    fn flags(comptime spec: SignalActionSpec) SignalAction.Options {
        var flags_bitfield: SignalAction.Options = .{ .val = 0 };
        if (spec.options.no_child_stop) {
            flags_bitfield.set(.no_child_stop);
        }
        if (spec.options.no_child_wait) {
            flags_bitfield.set(.no_child_wait);
        }
        if (spec.options.no_defer) {
            flags_bitfield.set(.no_defer);
        }
        if (spec.options.on_stack) {
            flags_bitfield.set(.on_stack);
        }
        if (spec.options.restart) {
            flags_bitfield.set(.restart);
        }
        if (spec.options.reset) {
            flags_bitfield.set(.reset);
        }
        if (spec.options.restorer) {
            flags_bitfield.set(.restorer);
        }
        if (spec.options.siginfo) {
            flags_bitfield.set(.siginfo);
        }
        if (spec.options.unsupported) {
            flags_bitfield.set(.unsupported);
        }
        return flags_bitfield;
    }
};
pub const SignalStack = extern struct {
    addr: u64,
    flags: Options = .{},
    len: u64,
    const Options = packed struct(u32) {
        on_stack: bool = true,
        disable: bool = false,
        zb2: u29 = 0,
        auto_disarm: bool = false,
    };
};
const SignalStackSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.sigaction_errors },
    return_type: type = void,
    logging: debug.Logging.SuccessError = .{},
    fn flags(comptime spec: SignalActionSpec) SignalAction.Options {
        var flags_bitfield: SignalAction.Options = .{ .val = 0 };
        if (spec.options.no_child_stop) {
            flags_bitfield.set(.no_child_stop);
        }
        if (spec.options.no_child_wait) {
            flags_bitfield.set(.no_child_wait);
        }
        if (spec.options.no_defer) {
            flags_bitfield.set(.no_defer);
        }
        if (spec.options.on_stack) {
            flags_bitfield.set(.on_stack);
        }
        if (spec.options.restart) {
            flags_bitfield.set(.restart);
        }
        if (spec.options.reset) {
            flags_bitfield.set(.reset);
        }
        if (spec.options.restorer) {
            flags_bitfield.set(.restorer);
        }
        if (spec.options.siginfo) {
            flags_bitfield.set(.siginfo);
        }
        if (spec.options.unsupported) {
            flags_bitfield.set(.unsupported);
        }
        return flags_bitfield;
    }
};
pub fn updateSignalAction(
    comptime sigaction_spec: SignalActionSpec,
    signo: sys.SignalCode,
    new_action: SignalAction,
    old_action: ?*SignalAction,
) sys.ErrorUnion(sigaction_spec.errors, sigaction_spec.return_type) {
    @setRuntimeSafety(false);
    const logging: debug.Logging.SuccessError = comptime sigaction_spec.logging.override();
    const new_action_buf_addr: u64 = @intFromPtr(&new_action);
    const old_action_buf_addr: u64 = @intFromPtr(old_action.?);
    if (meta.wrap(sys.call(.rt_sigaction, sigaction_spec.errors, sigaction_spec.return_type, .{
        @intFromEnum(signo), new_action_buf_addr, old_action_buf_addr, 8,
    }))) {
        if (logging.Success) {
            debug.signalActionNotice(signo, new_action.handler);
        }
    } else |rt_sigaction_error| {
        if (logging.Error) {
            debug.signalActionError(rt_sigaction_error, signo, new_action.handler);
        }
        return rt_sigaction_error;
    }
}
pub fn updateSignalStack(
    comptime sigaltstack_spec: SignalStackSpec,
    new_stack: SignalStack,
    old_stack: ?*SignalStack,
) sys.ErrorUnion(
    sigaltstack_spec.errors,
    sigaltstack_spec.return_type,
) {
    @setRuntimeSafety(false);
    const logging: debug.Logging.SuccessError = comptime sigaltstack_spec.logging.override();
    const new_stack_buf_addr: u64 = @intFromPtr(&new_stack);
    const old_stack_buf_addr: u64 = if (old_stack) |old| @intFromPtr(old) else 0;
    if (meta.wrap(sys.call(.sigaltstack, sigaltstack_spec.errors, sigaltstack_spec.return_type, .{
        new_stack_buf_addr, old_stack_buf_addr, 8,
    }))) {
        if (logging.Success) {
            debug.signalStackNotice(new_stack, old_stack);
        }
    } else |sigaltstack_error| {
        if (logging.Error) {
            debug.signalStackError(sigaltstack_error, new_stack);
        }
        return sigaltstack_error;
    }
}
// If the return value is greater than word size or is a zig error union, this
// internal call can never be inlined.
noinline fn callErrorOrMediaReturnValueFunction(comptime Fn: type, result_addr: u64, call_addr: u64, args_addr: u64) void {
    @as(**meta.Return(Fn), @ptrFromInt(result_addr)).*.* = @call(
        .never_inline,
        @as(**Fn, @ptrFromInt(call_addr)).*,
        @as(*meta.Args(Fn), @ptrFromInt(args_addr)).*,
    );
}
pub fn clone(comptime spec: CloneSpec, stack_addr: u64, stack_len: u64, result_ptr: anytype, comptime function: anytype, args: meta.Args(@TypeOf(function))) sys.ErrorUnion(spec.errors, spec.return_type) {
    @setRuntimeSafety(false);
    const Context = struct {
        call: *const @TypeOf(function),
        ret: *meta.Return(@TypeOf(function)),
        args: meta.Args(@TypeOf(function)),
    };
    const cl_args: CloneArgs = .{
        .flags = comptime spec.flags(),
        .stack_addr = stack_addr,
        .stack_len = stack_len,
        .child_tid_addr = stack_addr,
        .parent_tid_addr = stack_addr +% 0x10,
        .tls_addr = stack_addr +% 0x20,
    };
    const ret = if (@TypeOf(result_ptr) == void) @constCast(&result_ptr) else result_ptr;
    const cl_args_addr: u64 = @intFromPtr(&cl_args);
    const cl_args_size: u64 = @sizeOf(CloneArgs);
    const cl_ctx: *Context = @ptrFromInt(stack_addr +% (stack_len -% @sizeOf(Context)));
    cl_ctx.* = .{ .call = &function, .ret = ret, .args = args };
    const rc: i64 = asm volatile (
        \\syscall # clone3
        : [ret] "={rax}" (-> i64),
        : [cl_sysno] "{rax}" (sys.Fn.clone3),
          [cl_args_addr] "{rdi}" (cl_args_addr),
          [cl_args_size] "{rsi}" (cl_args_size),
        : "rcx", "r11", "memory"
    );
    if (rc == 0) {
        const tl_stack_addr: u64 = asm volatile (
            \\xorq  %%rbp,  %%rbp
            \\movq  %%rsp,  %[tl_stack_addr]
            : [tl_stack_addr] "=r" (-> u64),
            :
            : "rbp", "rsp", "memory"
        );
        const tl_ctx: *Context = @ptrFromInt(tl_stack_addr -% @sizeOf(Context));
        tl_ctx.ret.* = @call(.never_inline, tl_ctx.call, tl_ctx.args);
        exit(0);
    }
    if (spec.errors.throw.len != 0) {
        if (rc < 0) try builtin.zigErrorThrow(sys.ErrorCode, spec.errors.throw, rc);
    }
    if (spec.errors.abort.len != 0) {
        if (rc < 0) builtin.zigErrorAbort(sys.ErrorCode, spec.errors.abort, rc);
    }
    if (spec.return_type == void) {
        return;
    }
    if (spec.return_type != noreturn) {
        return @as(spec.return_type, @intCast(rc));
    }
    unreachable;
}
/// Replaces argument at `index` with argument at `index` +% 1
/// This is useful for extracting information from the program arguments in
/// rounds.
pub fn shift(args: *[][*:0]u8, index: u64) void {
    if (args.len > index +% 1) {
        var this: *[*:0]u8 = &args.*[index];
        for (args.*[index +% 1 ..]) |*next| {
            this.* = next.*;
            this = next;
        }
    }
    args.* = args.*[0 .. args.len -% 1];
}
/// init: ArgsIterator{ .args = args }
pub const ArgsIterator = struct {
    args: [][*:0]u8,
    args_idx: usize = 1,
    pub fn next(itr: *ArgsIterator) ?[:0]const u8 {
        if (itr.args_idx <= itr.args.len) {
            const arg: [*:0]const u8 = itr.args[itr.args_idx];
            itr.args_idx +%= 1;
            var arg_len: u64 = 0;
            while (itr.args[itr.args_idx][arg_len] != 0) {
                arg_len +%= 1;
            }
            return arg[0..arg_len :0];
        }
        return null;
    }
};
pub const PathIterator = struct {
    /// environmentValue(vars, "PATH").?
    paths: [:0]u8,
    paths_idx: usize = 0,
    pub fn next(itr: *PathIterator) ?[:0]u8 {
        if (itr.paths_idx == itr.paths.len) {
            return null;
        }
        const idx: usize = itr.paths_idx;
        while (itr.paths_idx != itr.paths.len) : (itr.paths_idx +%= 1) {
            if (itr.paths[itr.paths_idx] == ':') {
                const end: u64 = itr.paths_idx;
                itr.paths[end] = 0;
                itr.paths_idx +%= 1;
                return itr.paths[idx..end :0];
            }
        } else {
            return itr.paths[idx..itr.paths_idx :0];
        }
    }
    pub fn done(itr: *PathIterator) void {
        var idx: usize = 0;
        while (idx != itr.paths_idx) : (idx +%= 1) {
            if (itr.paths[idx] == 0) {
                itr.paths[idx] = ':';
            }
        }
        itr.paths_idx = 0;
    }
};
pub fn auxiliaryValue(auxv: *const anyopaque, comptime tag: AuxiliaryVectorEntry) ?u64 {
    var addr: u64 = @intFromPtr(auxv);
    while (@as(*u64, @ptrFromInt(addr)).* != 0) : (addr +%= 16) {
        if (@intFromEnum(tag) == @as(*u64, @ptrFromInt(addr)).*) {
            return @as(*u64, @ptrFromInt(addr +% 8)).*;
        }
    }
    return null;
}
pub fn environmentValue(vars: [][*:0]u8, key: [:0]const u8) ?[:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    for (vars) |key_value| {
        const key_len: u64 = blk: {
            var idx: usize = 0;
            while (key_value[idx] != '=') idx +%= 1;
            break :blk idx;
        };
        if (!mem.testEqualString(key, key_value[0..key_len])) {
            continue;
        }
        const val_idx: usize = key_len +% 1;
        const end_idx: usize = blk: {
            var idx: usize = val_idx;
            while (key_value[idx] != 0) idx +%= 1;
            break :blk idx;
        };
        return key_value[val_idx..end_idx :0];
    }
    return null;
}
pub fn restoreRunTime() callconv(.Naked) void {
    switch (builtin.zig_backend) {
        .stage2_c => asm volatile (
            \\ movl %[number], %%eax
            \\ syscall # rt_sigreturn
            \\ retq
            :
            : [number] "i" (15),
            : "rcx", "r11", "memory"
        ),
        else => asm volatile ("syscall # rt_sigreturn"
            :
            : [number] "{rax}" (15),
            : "rcx", "r11", "memory"
        ),
    }
}
pub fn enableExceptionHandlers() void {
    @setRuntimeSafety(false);
    if (builtin.signal_stack) |stack| {
        sys.call_noexcept(.mmap, void, .{
            stack.addr, stack.len, 0x1 | 0x2, 0x20 | 0x02 | 0x100000, ~@as(u64, 0), 0,
        });
        sys.call_noexcept(.sigaltstack, void, .{
            @intFromPtr(&SignalStack{ .addr = stack.addr, .len = stack.len }), 0, 0,
        });
    }
    updateExceptionHandlers(&.{
        .flags = .{ .on_stack = builtin.signal_stack != null },
        .handler = .{ .action = about.exceptionHandler },
        .restorer = restoreRunTime,
    });
}
fn updateExceptionHandlers(act: *const SignalAction) void {
    @setRuntimeSafety(false);
    const sa_new_addr: u64 = @intFromPtr(act);
    inline for ([_]struct { bool, u32 }{
        .{ builtin.signal_handlers.SegmentationFault, sys.SIG.SEGV },
        .{ builtin.signal_handlers.IllegalInstruction, sys.SIG.ILL },
        .{ builtin.signal_handlers.BusError, sys.SIG.BUS },
        .{ builtin.signal_handlers.FloatingPointError, sys.SIG.FPE },
    }) |pair| {
        if (pair[0]) {
            sys.call_noexcept(.rt_sigaction, void, .{ pair[1], sa_new_addr, 0, @sizeOf(@TypeOf(act.mask)) });
        }
    }
}
fn setSignalAction(signo: u64, noalias new_action: *const SignalAction, noalias old_action: ?*SignalAction) void {
    const sa_new_addr: u64 = @intFromPtr(new_action);
    const sa_old_addr: u64 = if (old_action) |action| @intFromPtr(action) else 0;
    sys.call_noexcept(.rt_sigaction, void, .{ signo, sa_new_addr, sa_old_addr, @sizeOf(@TypeOf(new_action.mask)) });
}
pub const about = opaque {
    const sig_s: fmt.AboutSrc = fmt.about("sig");
    const fork_s: fmt.AboutSrc = fmt.about("fork");
    const wait_s: fmt.AboutSrc = fmt.about("wait");
    const futex_wait_s: fmt.AboutSrc = fmt.about("futex-wait");
    const futex_wake_s: fmt.AboutSrc = fmt.about("futex-wake");
    const futex_wake_op_s: fmt.AboutSrc = fmt.about("futex-wake-op");
    pub inline fn exe(buf: []u8) u64 {
        const rc: i64 = asm volatile (
            \\syscall
            : [_] "={rax}" (-> isize),
            : [_] "{rax}" (89), // linux sys_readlink
              [_] "{rdi}" ("/proc/self/exe"), // symlink to executable
              [_] "{rsi}" (buf.ptr), // message buf ptr
              [_] "{rdx}" (buf.len), // message buf len
            : "rcx", "r11", "memory"
        );
        return if (rc < 0) ~@as(u64, 0) else @as(u64, @intCast(rc));
    }
    fn forkNotice(pid: u64) void {
        var buf: [560]u8 = undefined;
        const ud64: fmt.Type.Ud64 = @bitCast(@as(u64, pid));
        buf[0..fork_s.len].* = fork_s.*;
        var ptr: [*]u8 = buf[fork_s.len..];
        ptr[0..4].* = "pid=".*;
        ptr += 4;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) + 1]);
    }
    fn waitNotice(id: WaitSpec.For, ret: Return) void {
        const if_signaled: bool = Status.ifSignaled(ret.status);
        const if_stopped: bool = Status.ifStopped(ret.status);
        const code: u64 = if (if_signaled) Status.stop(ret.status) else if (if_stopped) Status.stop(ret.status) else Status.exit(ret.status);
        const status_s: []const u8 =
            if (if_signaled) ", sig=" else if (if_stopped) ", stop=" else ", exit=";
        var ud64: fmt.Type.Ud64 = @bitCast(@as(u64, ret.pid));
        var buf: [560]u8 = undefined;
        buf[0..wait_s.len].* = wait_s.*;
        var ptr: [*]u8 = buf[wait_s.len..];
        @memcpy(ptr, @tagName(id));
        ptr += @tagName(id).len;
        ptr[0..6].* = ", pid=".*;
        ptr += 6;
        ptr += ud64.formatWriteBuf(ptr);
        @memcpy(ptr, status_s);
        ptr += status_s.len;
        ud64 = @bitCast(code);
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) + 1]);
    }
    fn signalActionNotice(signo: sys.SignalCode, handler: SignalAction.Handler) void {
        if (return) {}
        const handler_raw: usize = @as(usize, @bitCast(handler));
        const handler_addr_s: []const u8 = fmt.old.ux64(handler_raw).readAll();
        const handler_set_s: []const u8 = if (handler_raw == 1) "ignore" else "default";
        const handler_s: []const u8 = if (handler_raw > 1) handler_addr_s else handler_set_s;
        var buf: [560]u8 = undefined;
        debug.logAlwaysAIO(&buf, &[_][]const u8{ sig_s, "SIG", @tagName(signo), " -> ", handler_s, "\n" });
    }
    fn signalStackNotice(new_st: SignalStack, maybe_old_st: ?*SignalStack) void {
        if (return) {}
        var buf: [560]u8 = undefined;
        if (maybe_old_st) |old_st| {
            debug.logAlwaysAIO(&buf, &[_][]const u8{
                sig_s,  fmt.old.ux64(old_st.addr).readAll(),
                "..",   fmt.old.ux64(old_st.addr +% old_st.len).readAll(),
                " -> ", fmt.old.ux64(new_st.addr).readAll(),
                "..",   fmt.old.ux64(new_st.addr +% new_st.len).readAll(),
                "\n",
            });
        } else {
            debug.logAlwaysAIO(&buf, &[_][]const u8{
                sig_s, fmt.old.ux64(new_st.addr).readAll(),
                "..",  fmt.old.ux64(new_st.addr +% new_st.len).readAll(),
                "\n",
            });
        }
    }
    fn futexWaitNotice(futex: *u32, value: u32, timeout: *const time.TimeSpec) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex.* };
        buf[0..futex_wait_s.len].* = futex_wait_s.*;
        var ptr: [*]u8 = buf[futex_wait_s.len..];
        ptr[0..7].* = "futex1=".*;
        ptr += 7;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word1=".*;
        ptr += 8;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", val=".*;
        ptr += 6;
        ud64.value = value;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", sec=".*;
        ptr += 6;
        ud64.value = timeout.sec;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", nsec=".*;
        ptr += 7;
        ud64.value = timeout.nsec;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeAttempt(futex: *u32, count: u64) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex.* };
        buf[0..futex_wake_s.len].* = futex_wake_s.*;
        var ptr: [*]u8 = buf[futex_wake_s.len..];
        ptr[0..6].* = "futex=".*;
        ptr += 6;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..7].* = ", word=".*;
        ptr += 7;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", max=".*;
        ptr += 6;
        ud64.value = count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeNotice(futex: *u32, count: u64, ret: u64) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex.* };
        buf[0..futex_wake_s.len].* = futex_wake_s.*;
        var ptr: [*]u8 = buf[futex_wake_s.len..];
        ptr[0..6].* = "futex=".*;
        ptr += 6;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..7].* = ", word=".*;
        ptr += 7;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", max=".*;
        ptr += 6;
        ud64.value = count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", ret=".*;
        ptr += 6;
        ud64.value = ret;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeOpAttempt(futex1: *u32, futex2: *u32, count1: u32, count2: u32, _: FutexOp.WakeOp) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex1) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex1.* };
        buf[0..futex_wake_s.len].* = futex_wake_s.*;
        var ptr: [*]u8 = buf[futex_wake_s.len..];
        ptr[0..7].* = "futex1=".*;
        ptr += 7;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word1=".*;
        ptr += 8;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max1=".*;
        ptr += 7;
        ud64.value = count1;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..9].* = ", futex2=".*;
        ptr += 9;
        ux64.value = @intFromPtr(futex2);
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word2=".*;
        ptr += 8;
        ud64.value = futex2.*;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max2=".*;
        ptr += 7;
        ud64.value = count2;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeOpNotice(futex1: *u32, futex2: *u32, count1: u32, count2: u32, _: FutexOp.WakeOp, ret: u64) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex1) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex1.* };
        buf[0..futex_wake_s.len].* = futex_wake_s.*;
        var ptr: [*]u8 = buf[futex_wake_s.len..];
        ptr[0..7].* = "futex1=".*;
        ptr += 7;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word1=".*;
        ptr += 8;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max1=".*;
        ptr += 7;
        ud64.value = count1;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..9].* = ", futex2=".*;
        ptr += 9;
        ux64.value = @intFromPtr(futex2);
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word2=".*;
        ptr += 8;
        ud64.value = futex2.*;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max2=".*;
        ptr += 7;
        ud64.value = count2;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", ret=".*;
        ptr += 6;
        ud64.value = ret;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn signalActionError(rt_sigaction_error: anytype, signo: sys.SignalCode, handler: SignalAction.Handler) void {
        const handler_raw: usize = @bitCast(handler);
        var ux64: fmt.Type.Ux64 = @bitCast(handler_raw);
        var buf: [256]u8 = undefined;
        buf[0..sig_s.len].* = sig_s.*;
        var ptr: [*]u8 = buf[sig_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(rt_sigaction_error));
        ptr += @errorName(rt_sigaction_error).len;
        ptr[0..5].* = ", SIG".*;
        ptr += 5;
        @memcpy(ptr, @tagName(signo));
        ptr += @tagName(signo).len;
        ptr[0..4].* = " -> ".*;
        ptr += 4;
        if (handler_raw > 1) {
            ptr += ux64.formatWriteBuf(ptr);
        } else {
            @memcpy(ptr, if (handler_raw == 1) "ignore" else "default");
            ptr += (8 -% handler_raw);
        }
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr - @intFromPtr(&buf)) +% 1]);
    }
    fn signalStackError(sigaltstack_error: anytype, new_st: SignalStack) void {
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ux64 = .{ .value = new_st.addr };
        buf[0..sig_s.len].* = sig_s.*;
        var ptr: [*]u8 = buf[sig_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(sigaltstack_error));
        ptr += @errorName(sigaltstack_error).len;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..2].* = "..".*;
        ptr += 2;
        ux64.value = new_st.addr +% new_st.len;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWaitError(futex_error: anytype, futex: *u32, value: u32, timeout: *const time.TimeSpec) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ud64 = .{ .value = @intFromPtr(futex) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex.* };
        buf[0..futex_wait_s.len].* = futex_wait_s.*;
        var ptr: [*]u8 = buf[futex_wait_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(futex_error));
        ptr += @errorName(futex_error).len;
        ptr[0..8].* = ", futex=".*;
        ptr += 8;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..7].* = ", word=".*;
        ptr += 7;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", val=".*;
        ptr += 6;
        ud64.value = value;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", sec=".*;
        ud64.value = timeout.sec;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", nsec=".*;
        ud64.value = timeout.nsec;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeError(futex_error: anytype, futex: *u32, count: u64) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [256]u8 = undefined;
        var ux64: fmt.Type.Ud64 = .{ .value = @intFromPtr(futex) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex.* };
        buf[0..futex_wait_s.len].* = futex_wait_s.*;
        var ptr: [*]u8 = buf[futex_wait_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(futex_error));
        ptr += @errorName(futex_error).len;
        ptr[0..7].* = "futex=@".*;
        ptr += 7;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..7].* = ", word=".*;
        ptr += 7;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..6].* = ", max=".*;
        ptr += 6;
        ud64.value = count;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    fn futexWakeOpError(futex_error: anytype, futex1: *u32, futex2: *u32, count1: u32, count2: u32, _: FutexOp.WakeOp) void {
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        buf[0..futex_wait_s.len].* = futex_wait_s.*;
        var ptr: [*]u8 = buf[futex_wait_s.len..];
        ptr[0..debug.about.error_s.len].* = debug.about.error_s.*;
        ptr += debug.about.error_s.len;
        @memcpy(ptr, @errorName(futex_error));
        ptr += @errorName(futex_error).len;
        var ux64: fmt.Type.Ud64 = .{ .value = @intFromPtr(futex1) };
        var ud64: fmt.Type.Ud64 = .{ .value = futex1.* };
        ptr[0..10].* = ", futex1=@".*;
        ptr += 10;
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word1=".*;
        ptr += 8;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max1=".*;
        ptr += 7;
        ud64.value = count1;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..10].* = ", futex2=@".*;
        ptr += 10;
        ux64.value = @intFromPtr(futex2);
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..8].* = ", word2=".*;
        ptr += 8;
        ud64.value = futex2.*;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..7].* = ", max2=".*;
        ptr += 7;
        ud64.value = count2;
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0] = '\n';
        debug.write(buf[0..(@intFromPtr(ptr - @intFromPtr(&buf)) +% 1)]);
    }
    pub fn exceptionHandler(sig: sys.SignalCode, info: *const SignalInfo, ctx: ?*const anyopaque) noreturn {
        @setRuntimeSafety(false);
        var act: SignalAction = undefined;
        updateExceptionHandlers(&act);
        var buf: [8192]u8 = undefined;
        buf[0..3].* = "SIG".*;
        var ptr: [*]u8 = buf[3..];
        @memcpy(ptr, @tagName(sig));
        ptr += @tagName(sig).len;
        ptr[0..12].* = " at address ".*;
        ptr += 12;
        ptr += fmt.ux64(info.fields.fault.addr).formatWriteBuf(ptr);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += about.exe(ptr[0..4096]);
        debug.panicSignal(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))], ctx.?);
    }
    pub fn sampleAllReports() void {
        var futex0: u32 = 0xf0;
        var futex1: u32 = 0xf1;
        const timeout: time.TimeSpec = .{ .sec = 50, .nsec = 25 };
        forkNotice(1024);
        waitNotice(.{ .pid = 4096 }, undefined);
        signalActionNotice(.SEGV, .{ .set = .default });
        signalActionError(error.BadSignal, .SEGV, .{ .set = .default });
        futexWaitError(error.FutexError, &futex0, 25, &timeout);
        futexWakeError(error.FutexError, &futex0, 1);
        futexWakeOpError(error.FutexError, &futex0, &futex1, 1, 0, .{ .from = 10, .to = 20, .cmp = .Equal, .op = .Add });
    }
};
pub fn GenericOptions(comptime Options: type) type {
    return struct {
        field_name: []const u8,
        short: ?[]const u8 = null,
        long: ?[]const u8 = null,
        assign: union(enum) {
            boolean: bool,
            argument: []const u8,
            any: *const anyopaque,
            action: *const fn (*Options) void,
            convert: *const fn (*Options, [:0]const u8) void,
        },
        descr: ?[]const u8 = null,
        clobber: bool = true,
        const Option = @This();
        comptime {
            debug.assert(@hasDecl(Options, "Map"));
            debug.assert(Options.Map == @This());
        }
        fn tagCast(comptime child: type, comptime any: *const anyopaque) @Type(.EnumLiteral) {
            return @as(*align(@alignOf(child)) const @Type(.EnumLiteral), @ptrCast(any)).*;
        }
        fn anyCast(comptime child: type, comptime any: *const anyopaque) child {
            return @as(*const child, @ptrCast(any)).*;
        }
        fn setAny(comptime child: type, comptime any: *const anyopaque) child {
            return switch (@typeInfo(child)) {
                .Optional => |optional_info| switch (@typeInfo(optional_info.child)) {
                    .Enum => tagCast(optional_info.child, any),
                    else => anyCast(optional_info.child, any),
                },
                .Enum => tagCast(child, any),
                else => anyCast(child, any),
            };
        }
        fn getOptInternalArrityError(arg: [:0]const u8) void {
            var buf: [4096]u8 = undefined;
            var ptr: [*]u8 = &buf;
            ptr[0] = '\'';
            ptr += 1;
            @memcpy(ptr, arg);
            ptr += arg.len;
            ptr[0..23].* = "' requires an argument\n".*;
            ptr += 23;
            debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
        }
        fn getOptInternal(comptime flag: Option, options: *Options, args: *[][*:0]u8, index: u64, offset: u64) void {
            const field = &@field(options, flag.field_name);
            const Field = @TypeOf(field.*);
            const arg: [:0]const u8 = mem.terminate(args.*[index], 0);
            switch (flag.assign) {
                .boolean => |value| {
                    shift(args, index);
                    field.* = value;
                },
                .argument => {
                    if (offset == 0) {
                        shift(args, index);
                    }
                    if (args.len == index) {
                        getOptInternalArrityError(arg);
                    }
                    field.* = mem.terminate(args.*[index], 0)[offset..];
                    shift(args, index);
                },
                .convert => |convert| {
                    if (offset == 0) {
                        shift(args, index);
                    }
                    if (args.len == index) {
                        getOptInternalArrityError(arg);
                    }
                    convert(options, mem.terminate(args.*[index], 0)[offset..]);
                    shift(args, index);
                },
                .action => |action| {
                    action(options);
                    shift(args, index);
                },
                .any => |any| {
                    field.* = setAny(Field, any);
                    shift(args, index);
                },
            }
        }
        pub fn helpMessage(comptime opt_map: []const Option) []const u8 {
            const alignment: u64 = 4;
            var buf: []const u8 = "option flags:\n";
            var max_width: u64 = 0;
            for (opt_map) |option| {
                var width: u64 = 0;
                if (option.short) |short_switch| {
                    width +%= 1 +% short_switch.len;
                }
                if (option.long) |long_switch| {
                    width +%= 2 +% long_switch.len;
                }
                if (option.assign == .argument) {
                    width +%= 3 +% option.assign.argument.len;
                }
                max_width = @max(width, max_width);
            }
            max_width +%= alignment;
            max_width &= ~(alignment -% 1);
            for (opt_map) |option| {
                buf = buf ++ " " ** 4;
                if (option.short) |short_switch| {
                    var tmp: []const u8 = short_switch;
                    if (option.long) |long_switch| {
                        tmp = tmp ++ ", " ++ long_switch;
                    }
                    if (option.descr) |descr| {
                        tmp = tmp ++ " " ** ((4 +% max_width) -% tmp.len) ++ descr;
                    }
                    if (option.assign == .argument) {
                        tmp = tmp ++ " <" ++ option.assign.argument ++ ">";
                    }
                    buf = buf ++ tmp ++ "\n";
                } else {
                    var tmp: []const u8 = option.long.?;
                    if (option.descr) |descr| {
                        tmp = tmp ++ " " ** ((4 +% max_width) -% tmp.len) ++ descr;
                    }
                    buf = buf ++ tmp ++ "\n";
                }
            }
            return buf;
        }
        pub inline fn getOpts(args: *[][*:0]u8, comptime all_options: []const Option) Options {
            var options: Options = .{};
            if (args.len == 0) {
                return options;
            }
            var index: u64 = 1;
            lo: while (index != args.len) {
                inline for (all_options) |option| {
                    if (index == args.len) {
                        break :lo;
                    }
                    const arg1: [:0]const u8 = mem.terminate(args.*[index], 0);
                    if (option.long) |long_switch| blk: {
                        if (mach.testEqualMany8(long_switch, arg1)) {
                            option.getOptInternal(&options, args, index, 0);
                            continue :lo;
                        }
                        if (option.assign == .boolean) {
                            break :blk;
                        }
                        const assign_long_switch: []const u8 = long_switch ++ "=";
                        if (arg1.len >= assign_long_switch.len and
                            mach.testEqualMany8(assign_long_switch, arg1[0..assign_long_switch.len]))
                        {
                            option.getOptInternal(&options, args, index, assign_long_switch.len);
                            continue :lo;
                        }
                    }
                    if (option.short) |short_switch| blk: {
                        if (mach.testEqualMany8(short_switch, arg1)) {
                            option.getOptInternal(&options, args, index, 0);
                            continue :lo;
                        }
                        if (option.assign == .boolean) {
                            break :blk;
                        }
                        if (arg1.len >= short_switch.len and
                            mach.testEqualMany8(short_switch, arg1[0..short_switch.len]))
                        {
                            option.getOptInternal(&options, args, index, short_switch.len);
                            continue :lo;
                        }
                    }
                }
                const arg1: [:0]const u8 = mem.terminate(args.*[index], 0);
                if (mach.testEqualMany8("--", arg1)) {
                    shift(args, index);
                    break :lo;
                }
                if (mach.testEqualMany8("--help", arg1)) {
                    Option.about.optionNotice(all_options);
                    exitNotice(0);
                }
                if (arg1.len != 0 and arg1[0] == '-') {
                    Option.about.optionError(all_options, arg1);
                    exitNotice(0);
                }
                index += 1;
            }
            return options;
        }
        const about = struct {
            const about_opt_s: fmt.AboutSrc = fmt.about("opt");
            const about_opt_1_s: fmt.AboutSrc = fmt.about("opt-error");
            const about_stop_s: *const [32]u8 = "\nstop parsing options with '--'\n";
            fn optionNotice(comptime all_options: []const Options.Map) void {
                const buf: []const u8 = comptime Options.Map.helpMessage(all_options);
                debug.write(buf);
            }
            fn optionError(all_options: []const Options.Map, arg: [:0]const u8) void {
                @setRuntimeSafety(false);
                var buf: [4224]u8 = undefined;
                var ptr: [*]u8 = &buf;
                const bad_opt: []const u8 = getBadOpt(arg);
                @memcpy(ptr, about_opt_s);
                ptr += about_opt_s.len;
                @memcpy(ptr, debug.about.error_s);
                ptr += debug.about.error_s.len;
                ptr[0] = '\'';
                ptr += 1;
                @memcpy(ptr, bad_opt);
                ptr += bad_opt.len;
                ptr[0..2].* = "'\n".*;
                ptr += 2;
                for (all_options) |option| {
                    const min: u64 = @intFromPtr(ptr - @intFromPtr(&buf));
                    if (option.long) |long_switch| {
                        if (mem.orderedMatches(u8, bad_opt, long_switch) >
                            @max(bad_opt.len, long_switch.len) / 2)
                        {
                            @memcpy(ptr, about_opt_s);
                            ptr += about_opt_s.len;
                            if (option.short) |short_switch| {
                                ptr[0] = '\'';
                                ptr += 1;
                                @memcpy(ptr, short_switch);
                                ptr += short_switch.len;
                                ptr[0..3].* = "', ".*;
                                ptr += 3;
                            }
                            ptr[0] = '\'';
                            ptr += 1;
                            @memcpy(ptr, long_switch);
                            ptr += long_switch.len;
                            ptr[0] = '\'';
                            ptr += 1;
                        }
                    }
                    if (min != @intFromPtr(ptr - @intFromPtr(&buf))) {
                        if (option.descr) |descr| {
                            ptr[0] = '\t';
                            ptr += 1;
                            @memcpy(ptr, descr);
                            ptr += descr.len;
                        }
                        ptr[0] = '\n';
                        ptr += 1;
                    }
                }
                @memcpy(ptr, about_stop_s);
                ptr += about_stop_s.len;
                debug.write(buf[0..@intFromPtr(ptr - @intFromPtr(&buf))]);
            }
            fn getBadOpt(arg: [:0]const u8) []const u8 {
                var idx: usize = 0;
                while (idx != arg.len) : (idx +%= 1) {
                    if (arg[idx] == '=') {
                        return arg[0..idx];
                    }
                }
                return arg;
            }
            fn matchLongSwitch(bad_opt: []const u8, long_switch: []const u8) u64 {
                var l_idx: usize = 0;
                var mats: u64 = 0;
                lo: while (true) : (l_idx +%= 1) {
                    var r_idx: usize = 0;
                    while (r_idx < long_switch.len) : (r_idx +%= 1) {
                        if (l_idx +% mats >= bad_opt.len) {
                            break :lo;
                        }
                        mats +%= @intFromBool(bad_opt[l_idx +% mats] == long_switch[r_idx]);
                    }
                }
                return mats;
            }
        };
    };
}
pub fn exitNotice(return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Success) {
        debug.about.exitRcNotice(return_code);
    }
    exit(return_code);
}
pub fn exitGroupNotice(return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Success) {
        debug.about.exitRcNotice(return_code);
    }
    exitGroup(return_code);
}
pub fn exitError(exit_error: anytype, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault) {
        debug.about.errorRcNotice(@errorName(exit_error), return_code);
    }
    exit(return_code);
}
pub fn exitGroupError(exit_error: anytype, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault) {
        debug.about.errorRcNotice(@errorName(exit_error), return_code);
    }
    exitGroup(return_code);
}
pub fn exitFault(message: []const u8, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault) {
        debug.about.faultRcNotice(message, return_code);
    }
    exit(return_code);
}
pub fn exitGroupFault(message: []const u8, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault) {
        debug.about.faultRcNotice(message, return_code);
    }
    exitGroup(return_code);
}
pub fn exitErrorFault(exit_error: anytype, message: []const u8, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault and
        debug.logging_general.Error)
    {
        debug.about.errorFaultRcNotice(@errorName(exit_error), message, return_code);
    } else if (debug.logging_general.Fault) {
        debug.about.faultRcNotice(message, return_code);
    } else if (debug.logging_general.Error) {
        debug.about.errorRcNotice(@errorName(exit_error), return_code);
    }
    exitGroup(return_code);
}
pub fn exitGroupErrorFault(exit_error: anytype, message: []const u8, return_code: u8) noreturn {
    @setCold(true);
    if (debug.logging_general.Fault and
        debug.logging_general.Error)
    {
        debug.about.exitErrorFault(@errorName(exit_error), message, return_code);
    } else if (debug.logging_general.Fault) {
        debug.about.exitFault(message, return_code);
    } else if (debug.logging_general.Error) {
        debug.about.exitErrorRc(@errorName(exit_error), return_code);
    }
    exitGroup(return_code);
}
pub fn exit(rc: u8) noreturn {
    asm volatile (
        \\syscall
        :
        : [sysno] "{rax}" (60), // linux sys_exit
          [arg1] "{rdi}" (rc), // exit code
    );
    unreachable;
}
pub fn exitGroup(rc: u8) noreturn {
    asm volatile (
        \\syscall
        :
        : [sysno] "{rax}" (231), // linux sys_exit_group
          [arg1] "{rdi}" (rc), // exit code
    );
    unreachable;
}
