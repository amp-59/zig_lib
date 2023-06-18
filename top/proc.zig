const sys = @import("./sys.zig");
const lit = @import("./lit.zig");
const exe = @import("./exe.zig");
const meta = @import("./meta.zig");
const time = @import("./time.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

pub const SignalAction = extern struct {
    handler: u64,
    flags: u64,
    restorer: u64,
    mask: [2]u32 = .{0} ** 2,
    const Options = meta.EnumBitField(enum(usize) {
        no_child_stop = SA.NOCLDSTOP,
        no_child_wait = SA.NOCLDWAIT,
        no_defer = SA.NODEFER,
        on_stack = SA.ONSTACK,
        restart = SA.RESTART,
        reset = SA.RESETHAND,
        restorer = SA.RESTORER,
        siginfo = SA.SIGINFO,
        unsupported = SA.UNSUPPORTED,
        const SA = sys.SA;
    });
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
    exec_fd = AT.EXECFD,
    phdr_addr = AT.PHDR,
    phdr_entry_size = AT.PHENT,
    phdr_num = AT.PHNUM,
    page_size = AT.PAGESZ,
    base_addr = AT.BASE,
    flags = AT.FLAGS,
    entry_addr = AT.ENTRY,
    euid = AT.EUID,
    gid = AT.GID,
    egid = AT.EGID,
    platform = AT.PLATFORM,
    hwcap = AT.HWCAP,
    clock_freq = AT.CLKTCK,
    fpu_ctrl = AT.FPUCW,
    d_cache_blk_size = AT.DCACHEBSIZE,
    i_cache_blk_size = AT.ICACHEBSIZE,
    u_cache_blk_size = AT.UCACHEBSIZE,
    secure = AT.SECURE,
    base_platform = AT.BASE_PLATFORM,
    random = AT.RANDOM,
    name = AT.EXECFN,
    vsyscall_addr = AT.SYSINFO,
    vdso_addr = AT.SYSINFO_EHDR,
    l1i_cache_size = AT.L1I_CACHESIZE,
    l1i_cache_geometry = AT.L1I_CACHEGEOMETRY,
    l1d_cache_size = AT.L1D_CACHESIZE,
    l1d_cache_geometry = AT.L1D_CACHEGEOMETRY,
    l2_cache_size = AT.L2_CACHESIZE,
    l2_cache_geometry = AT.L2_CACHEGEOMETRY,
    l3_cache_size = AT.L3_CACHESIZE,
    l3_cache_geometry = AT.L3_CACHEGEOMETRY,
    const AT = sys.AT;
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
pub const Return = struct {
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
    errors: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    logging: builtin.Logging.SuccessError = .{},
    return_type: type = u64,
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
            .pid => |val| @intCast(isize, val),
            .pgid => |val| @intCast(isize, val),
        };
        return @bitCast(usize, val);
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
    logging: builtin.Logging.SuccessError = .{},
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
    logging: builtin.Logging.SuccessError = .{},
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
        execve: builtin.Logging.AttemptError = .{},
        fork: builtin.Logging.SuccessError = .{},
        waitpid: builtin.Logging.SuccessError = .{},
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
    logging: builtin.Logging.SuccessError = .{},
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
    logging: builtin.Logging.AttemptSuccessAcquireReleaseError = .{},
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
    return @truncate(u16, sys.call(.getuid, .{}, u64, .{}));
}
pub fn getEffectiveUserId() u16 {
    return @truncate(u16, sys.call(.geteuid, .{}, u64, .{}));
}
pub fn getGroupId() u16 {
    return @truncate(u16, sys.call(.getgid, .{}, u64, .{}));
}
pub fn getEffectiveGroupId() u16 {
    return @truncate(u16, sys.call(.getegid, .{}, u64, .{}));
}
pub fn waitPid(comptime spec: WaitSpec, id: WaitSpec.For) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    var ret: Return = undefined;
    const status_addr: u64 = @ptrToInt(&ret.status);
    if (meta.wrap(sys.call(.wait4, spec.errors, u32, .{ WaitSpec.pid(id), status_addr, 0, 0, 0 }))) |pid| {
        ret.pid = pid;
        if (logging.Success) {
            debug.waitNotice(id, ret);
        }
        if (spec.return_type == Return) {
            return ret;
        }
    } else |wait_error| {
        if (logging.Error) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn waitId(comptime spec: WaitIdSpec, id: u64, siginfo: *SignalInfo) sys.ErrorUnion(spec.errors, spec.return_type) {
    const id_type: u64 = @enumToInt(spec.id_type);
    const siginfo_buf_addr: u64 = @ptrToInt(siginfo);
    const flags: WaitId = comptime spec.flags();
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.waitid, spec.errors, spec.return_type, .{ id_type, id, siginfo_buf_addr, flags.val, 0 }))) |pid| {
        return pid;
    } else |wait_error| {
        if (logging.Error) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn fork(comptime spec: ForkSpec) sys.ErrorUnion(spec.errors, spec.return_type) {
    const logging: builtin.Logging.SuccessError = comptime spec.logging.override();
    if (meta.wrap(sys.call(.fork, spec.errors, spec.return_type, .{}))) |pid| {
        if (logging.Success and pid != 0) {
            debug.forkNotice(pid);
        }
        return pid;
    } else |fork_error| {
        if (logging.Error) {
            debug.forkError(fork_error);
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
    const logging: builtin.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        debug.futexWaitAttempt(futex, value, timeout);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, futex_spec.return_type, .{ @ptrToInt(futex), 0, value, @ptrToInt(timeout), 0, 0 }))) |ret| {
        if (logging.Acquire) {
            debug.futexWaitNotice(futex, value, timeout);
        }
        return ret;
    } else |futex_error| {
        if (logging.Error) {
            debug.futexWaitError(futex_error, futex, value, timeout);
        }
        return futex_error;
    }
}
pub fn futexWake(comptime futex_spec: FutexSpec, futex: *u32, count: u32) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    const logging: builtin.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        debug.futexWakeAttempt(futex, count);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, u32, .{ @ptrToInt(futex), 1, count, 0, 0, 0 }))) |ret| {
        if (logging.Release) {
            debug.futexWakeNotice(futex, count, ret);
        }
        if (futex_spec.return_type != void) {
            return ret;
        }
    } else |futex_error| {
        if (logging.Error) {
            debug.futexWakeError(futex_error, futex, count);
        }
        return futex_error;
    }
}
pub fn futexWakeOp(comptime futex_spec: FutexSpec, futex1: *u32, futex2: *u32, count1: u32, count2: u32, wake_op: FutexOp.WakeOp) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    const logging: builtin.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        debug.futexWakeOpAttempt(futex1, futex2, count1, count2, wake_op);
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, u32, .{
        @ptrToInt(futex1), 5, count1, count2, @ptrToInt(futex2), @bitCast(u32, wake_op),
    }))) |ret| {
        if (logging.Acquire) {
            debug.futexWakeOpNotice(futex1, futex2, count1, count2, wake_op, ret);
        }
    } else |futex_error| {
        if (logging.Error) {
            debug.futexWakeOpError(futex_error, futex1, futex2, count1, count2, wake_op);
        }
        return futex_error;
    }
}
fn futexRequeue(comptime futex_spec: FutexSpec, futex1: *u32, futex2: *u32, count1: u32, count2: u32, from: ?u32) sys.ErrorUnion(
    futex_spec.errors,
    futex_spec.return_type,
) {
    @setRuntimeSafety(false);
    const logging: builtin.Logging.AttemptSuccessAcquireReleaseError = comptime futex_spec.logging.override();
    if (logging.Attempt) {
        //
    }
    if (meta.wrap(sys.call(.futex, futex_spec.errors, futex_spec.return_type, .{
        @ptrToInt(futex1), 3 +% @boolToInt(from != 0), count1, count2, @ptrToInt(futex2), from.?,
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
pub const start = struct {
    pub export fn _start() callconv(.Naked) noreturn {
        static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, callMain, .{});
    }
    pub usingnamespace builtin.debug;
};
const SignalActionSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.sigaction_errors },
    return_type: type = void,
    logging: builtin.Logging.SuccessError = .{},
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
const Handler = extern union {
    set: enum(usize) {
        ignore = 1,
        default = 0,
    },
    handler: *const fn (sys.SignalCode) void,
    action: *const fn (sys.SignalCode, *const SignalInfo, ?*const anyopaque) void,
};
pub fn updateSignalAction(comptime sigaction_spec: SignalActionSpec, signo: sys.SignalCode, to: Handler) sys.ErrorUnion(
    sigaction_spec.errors,
    sigaction_spec.return_type,
) {
    const logging: builtin.Logging.SuccessError = comptime sigaction_spec.logging.override();
    const flags: SignalAction.Options = comptime sigaction_spec.flags();
    const action: SignalAction = .{ .handler = @enumToInt(to.set), .flags = flags.val, .restorer = 0 };
    if (meta.wrap(sys.call(.rt_sigaction, sigaction_spec.errors, sigaction_spec.return_type, .{
        @enumToInt(signo), @ptrToInt(&action), 0, @sizeOf(@TypeOf(action.mask)),
    }))) {
        if (logging.Success) {
            debug.signalActionNotice(signo, to);
        }
    } else |rt_sigaction_error| {
        if (logging.Error) {
            debug.signalActionError(rt_sigaction_error, signo, to);
        }
        return rt_sigaction_error;
    }
}
pub const exception = struct {
    fn updateExceptionHandlers(act: *const SignalAction) void {
        @setRuntimeSafety(false);
        const sa_new_addr: u64 = @ptrToInt(act);
        inline for ([_]struct { bool, u32 }{
            .{ builtin.signal_handlers.segmentation_fault, SIG.SEGV },
            .{ builtin.signal_handlers.illegal_instruction, SIG.ILL },
            .{ builtin.signal_handlers.bus_error, SIG.BUS },
            .{ builtin.signal_handlers.floating_point_error, SIG.FPE },
        }) |pair| {
            if (pair[0]) {
                sys.call_noexcept(.rt_sigaction, void, .{ pair[1], sa_new_addr, 0, @sizeOf(@TypeOf(act.mask)) });
            }
        }
    }
    pub fn enableExceptionHandlers() void {
        @setRuntimeSafety(false);
        var act: SignalAction = .{
            .handler = @ptrToInt(&exceptionHandler),
            .flags = (SA.SIGINFO | SA.RESTART | SA.RESETHAND | SA.RESTORER),
            .restorer = @ptrToInt(&restoreRunTime),
        };
        updateExceptionHandlers(&act);
    }
    pub fn disableExceptionHandlers() void {
        var act = SignalAction{
            .handler = SIG.DFL,
            .flags = SA.RESTORER,
            .restorer = @ptrToInt(&restoreRunTime),
        };
        updateExceptionHandlers(&act);
    }
    fn setSignalAction(signo: u64, noalias new_action: *const SignalAction, noalias old_action: ?*SignalAction) void {
        const sa_new_addr: u64 = @ptrToInt(new_action);
        const sa_old_addr: u64 = if (old_action) |action| @ptrToInt(action) else 0;
        sys.call_noexcept(.rt_sigaction, void, .{ signo, sa_new_addr, sa_old_addr, @sizeOf(@TypeOf(new_action.mask)) });
    }
    pub fn exceptionHandler(sig: sys.SignalCode, info: *const SignalInfo, _: ?*const anyopaque) noreturn {
        @setRuntimeSafety(false);
        var act: SignalAction = .{ .handler = 0, .flags = 0, .restorer = 0 };
        updateExceptionHandlers(&act);
        const fault_addr_s: []const u8 = builtin.fmt.ux64(info.fields.fault.addr).readAll();
        var buf: [8192]u8 = undefined;
        var pathname: [4096]u8 = undefined;
        const link_s: []const u8 = pathname[0..builtin.debug.name(&pathname)];
        const len: u64 = mach.memcpyMulti(&buf, &.{ "SIG", @tagName(sig), " at address ", fault_addr_s, ", ", link_s });
        @panic(buf[0..len]);
    }
    pub fn restoreRunTime() callconv(.Naked) void {
        switch (builtin.zig.zig_backend) {
            .stage2_c => return asm volatile (
                \\ movl %[number], %%eax
                \\ syscall # rt_sigreturn
                \\ retq
                :
                : [number] "i" (15),
                : "rcx", "r11", "memory"
            ),
            else => return asm volatile ("syscall # rt_sigreturn"
                :
                : [number] "{rax}" (15),
                : "rcx", "r11", "memory"
            ),
        }
    }
    const SA = sys.SA;
    const SIG = sys.SIG;
};
const static = opaque {
    var stack_addr: u64 = 0;
};
pub noinline fn callMain() noreturn {
    @setRuntimeSafety(false);
    @setAlignStack(16);
    if (builtin.zig.output_mode != .Exe) {
        unreachable;
    }
    const Main: type = @TypeOf(builtin.root.main);
    const main: Main = builtin.root.main;
    const main_type_info: builtin.Type = @typeInfo(Main);
    const main_return_type: type = main_type_info.Fn.return_type.?;
    const main_return_type_info: builtin.Type = @typeInfo(main_return_type);
    const params = blk_0: {
        if (main_type_info.Fn.params.len == 0) {
            break :blk_0 .{};
        }
        if (main_type_info.Fn.params.len == 1) {
            const args_len: u64 = @intToPtr(*u64, static.stack_addr).*;
            const args_addr: u64 = static.stack_addr +% 8;
            const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
            break :blk_0 .{args[0..args_len]};
        }
        if (main_type_info.Fn.params.len == 2) {
            const args_len: u64 = @intToPtr(*u64, static.stack_addr).*;
            const args_addr: u64 = static.stack_addr +% 8;
            const vars_addr: u64 = static.stack_addr +% 16 +% (args_len * 8);
            const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
            const vars: [*][*:0]u8 = @intToPtr([*][*:0]u8, vars_addr);
            const vars_len: u64 = blk_1: {
                var len: u64 = 0;
                while (@ptrToInt(vars[len]) != 0) len += 1;
                break :blk_1 len;
            };
            break :blk_0 .{ args[0..args_len], vars[0..vars_len] };
        }
        if (main_type_info.Fn.params.len == 3) {
            const auxv_type: type = main_type_info.Fn.params[2].type orelse *const anyopaque;
            const args_len: u64 = @intToPtr(*u64, static.stack_addr).*;
            const args_addr: u64 = static.stack_addr +% 8;
            const vars_addr: u64 = args_addr +% 8 +% (args_len * 8);
            const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
            const vars: [*][*:0]u8 = @intToPtr([*][*:0]u8, vars_addr);
            const vars_len: u64 = blk_1: {
                var len: u64 = 0;
                while (@ptrToInt(vars[len]) != 0) len += 1;
                break :blk_1 len;
            };
            const auxv_addr: u64 = vars_addr +% 8 +% (vars_len * 8);
            const auxv: auxv_type = @intToPtr(auxv_type, auxv_addr);
            break :blk_0 .{ args[0..args_len], vars[0..vars_len], auxv };
        }
    };
    if (@bitCast(u5, builtin.signal_handlers) != 0) {
        exception.enableExceptionHandlers();
    }
    if (main_return_type == void) {
        @call(.auto, main, params);
        builtin.proc.exitNotice(0);
    }
    if (main_return_type == u8) {
        builtin.proc.exitNotice(@call(.auto, main, params));
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == void)
    {
        if (@call(.auto, main, params)) {
            builtin.proc.exitNotice(0);
        } else |err| {
            builtin.proc.exitError(err, @intCast(u8, @errorToInt(err)));
        }
    }
    if (main_return_type_info == .ErrorUnion and
        main_return_type_info.ErrorUnion.payload == u8)
    {
        if (@call(.auto, builtin.root.main, params)) |rc| {
            builtin.proc.exitNotice(rc);
        } else |err| {
            builtin.proc.exitError(err, @intCast(u8, @errorToInt(err)));
        }
    }
    builtin.static.assert(main_return_type_info != .ErrorSet);
}
// If the return value is greater than word size or is a zig error union, this
// internal call can never be inlined.
noinline fn callErrorOrMediaReturnValueFunction(comptime Fn: type, result_addr: u64, call_addr: u64, args_addr: u64) void {
    @intToPtr(**meta.Return(Fn), result_addr).*.* = @call(
        .never_inline,
        @intToPtr(**Fn, call_addr).*,
        @intToPtr(*meta.Args(Fn), args_addr).*,
    );
}
pub fn callClone(comptime spec: CloneSpec, stack_addr: u64, stack_len: u64, result_ptr: anytype, comptime function: anytype, args: meta.Args(@TypeOf(function))) sys.ErrorUnion(spec.errors, spec.return_type) {
    @setRuntimeSafety(false);
    const Fn: type = @TypeOf(function);
    const Args: type = meta.Args(@TypeOf(function));
    const cl_args: CloneArgs = .{
        .flags = comptime spec.flags(),
        .stack_addr = stack_addr,
        .stack_len = stack_len,
        .child_tid_addr = stack_addr,
        .parent_tid_addr = stack_addr +% 0x10,
        .tls_addr = stack_addr +% 0x20,
    };
    const cl_args_addr: u64 = @ptrToInt(&cl_args);
    const cl_args_size: u64 = @sizeOf(CloneArgs);
    const ret_off: u64 = stack_len -% @sizeOf(u64);
    const call_off: u64 = ret_off -% @sizeOf(u64);
    const args_off: u64 = call_off -% @sizeOf(Args);
    @intToPtr(**const Fn, stack_addr +% call_off).* = &function;
    if (@TypeOf(result_ptr) != void) {
        @intToPtr(*u64, stack_addr +% ret_off).* = @ptrToInt(result_ptr);
    }
    @intToPtr(*Args, stack_addr +% args_off).* = args;

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
        const tl_ret_addr: u64 = tl_stack_addr -% @sizeOf(u64);
        const tl_call_addr: u64 = tl_ret_addr -% @sizeOf(u64);
        const tl_args_addr: u64 = tl_call_addr -% @sizeOf(Args);
        if (@TypeOf(result_ptr) != void) {
            if (@sizeOf(@TypeOf(result_ptr.*)) <= @sizeOf(usize) or
                @typeInfo(@TypeOf(result_ptr.*)) != .ErrorUnion)
            {
                @intToPtr(**meta.Return(Fn), tl_ret_addr).*.* =
                    @call(.never_inline, @intToPtr(**Fn, tl_call_addr).*, @intToPtr(*meta.Args(Fn), tl_args_addr).*);
            } else {
                @call(.never_inline, callErrorOrMediaReturnValueFunction, .{
                    @TypeOf(function), tl_ret_addr, tl_call_addr, tl_args_addr,
                });
            }
        } else {
            @call(.never_inline, @intToPtr(**Fn, tl_call_addr).*, @intToPtr(*meta.Args(Fn), tl_args_addr).*);
        }
        asm volatile (
            \\movq  $60,    %%rax
            \\movq  $0,     %%rdi
            \\syscall # exit
            ::: "rax", "rdi");
        unreachable;
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
        return @intCast(spec.return_type, rc);
    }
    unreachable;
}
pub fn getVSyscall(comptime Fn: type, vdso_addr: u64, symbol: [:0]const u8) ?Fn {
    if (programOffset(vdso_addr)) |offset| {
        if (sectionAddress(vdso_addr, symbol)) |addr| {
            return @intToPtr(Fn, addr +% offset);
        }
    }
    return null;
}
pub fn programOffset(ehdr_addr: u64) ?u64 {
    const ehdr: *exe.Elf64_Ehdr = @intToPtr(*exe.Elf64_Ehdr, ehdr_addr);
    var addr: u64 = ehdr_addr +% ehdr.e_phoff;
    var idx: u64 = 0;
    while (idx != ehdr.e_phnum) : ({
        idx +%= 1;
        addr +%= @sizeOf(exe.Elf64_Phdr);
    }) {
        const phdr: *exe.Elf64_Phdr = @intToPtr(*exe.Elf64_Phdr, addr);
        if (phdr.p_flags.check(.X)) {
            return phdr.p_offset -% phdr.p_paddr;
        }
    }
    return null;
}
pub fn sectionAddress(ehdr_addr: u64, symbol: [:0]const u8) ?u64 {
    const ehdr: *exe.Elf64_Ehdr = @intToPtr(*exe.Elf64_Ehdr, ehdr_addr);
    var symtab_addr: u64 = 0;
    var strtab_addr: u64 = 0;
    var symtab_ents: u64 = 0;
    var dynsym_size: u64 = 0;
    var addr: u64 = ehdr_addr +% ehdr.e_shoff;
    var idx: u64 = 0;
    while (idx != ehdr.e_shnum) : ({
        idx +%= 1;
        addr = addr +% @sizeOf(exe.Elf64_Shdr);
    }) {
        const shdr: *exe.Elf64_Shdr = @intToPtr(*exe.Elf64_Shdr, addr);
        if (shdr.sh_type == .DYNSYM) {
            dynsym_size = shdr.sh_size;
        }
        if (shdr.sh_type == .DYNAMIC) {
            const dyn: [*]exe.Elf64_Dyn = @intToPtr([*]exe.Elf64_Dyn, ehdr_addr +% shdr.sh_offset);
            var dyn_idx: u64 = 0;
            while (true) : (dyn_idx +%= 1) {
                if (dyn[dyn_idx].d_tag == .SYMTAB) {
                    symtab_addr = ehdr_addr +% dyn[dyn_idx].d_val;
                    dyn_idx +%= 1;
                }
                if (dyn[dyn_idx].d_tag == .SYMENT) {
                    symtab_ents = dyn[dyn_idx].d_val;
                    dyn_idx +%= 1;
                }
                if (dyn[dyn_idx].d_tag == .STRTAB) {
                    strtab_addr = ehdr_addr +% dyn[dyn_idx].d_val;
                }
                if (symtab_addr != 0 and
                    symtab_ents != 0 and
                    strtab_addr != 0)
                {
                    const strtab: [*:0]u8 = @intToPtr([*:0]u8, strtab_addr);
                    const symtab: [*]exe.Elf64_Sym = @intToPtr([*]exe.Elf64_Sym, symtab_addr);
                    var st_idx: u64 = 1;
                    lo: while (st_idx *% symtab_ents != dynsym_size) : (st_idx +%= 1) {
                        for (symbol, strtab + symtab[st_idx].st_name) |x, y| {
                            if (x != y) {
                                continue :lo;
                            }
                        }
                        return ehdr_addr +% symtab[st_idx].st_value;
                    }
                    break;
                }
            }
        }
    }
    return null;
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
    args_idx: u64 = 1,
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
    paths_idx: u64 = 0,
    pub fn next(itr: *PathIterator) ?[:0]u8 {
        if (itr.paths_idx == itr.paths.len) {
            return null;
        }
        const idx: u64 = itr.paths_idx;
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
        var idx: u64 = 0;
        while (idx != itr.paths_idx) : (idx +%= 1) {
            if (itr.paths[idx] == 0) {
                itr.paths[idx] = ':';
            }
        }
        itr.paths_idx = 0;
    }
};
pub fn auxiliaryValue(auxv: *const anyopaque, comptime tag: AuxiliaryVectorEntry) ?u64 {
    var addr: u64 = @ptrToInt(auxv);
    while (@intToPtr(*u64, addr).* != 0) : (addr +%= 16) {
        if (@enumToInt(tag) == @intToPtr(*u64, addr).*) {
            return @intToPtr(*u64, addr +% 8).*;
        }
    }
    return null;
}
pub fn environmentValue(vars: [][*:0]u8, key: [:0]const u8) ?[:0]u8 {
    for (vars) |key_value| {
        const key_len: u64 = blk: {
            var idx: u64 = 0;
            while (key_value[idx] != '=') idx +%= 1;
            break :blk idx;
        };
        if (!mach.testEqualMany8(key, key_value[0..key_len])) {
            continue;
        }
        const val_idx: u64 = key_len +% 1;
        const end_idx: u64 = blk: {
            var idx: u64 = val_idx;
            while (key_value[idx] != 0) idx +%= 1;
            break :blk idx;
        };
        return key_value[val_idx..end_idx :0];
    }
    return null;
}
const debug = opaque {
    const about_sig_0_s: [:0]const u8 = builtin.fmt.about("sig");
    const about_sig_1_s: [:0]const u8 = builtin.fmt.about("sig-error");
    const about_fork_0_s: [:0]const u8 = builtin.fmt.about("fork");
    const about_fork_1_s: [:0]const u8 = builtin.fmt.about("fork-error");
    const about_wait_0_s: [:0]const u8 = builtin.fmt.about("wait");
    const about_wait_1_s: [:0]const u8 = builtin.fmt.about("wait-error");
    const about_futex_wait_0_s: [:0]const u8 = builtin.fmt.about("futex-wait");
    const about_futex_wake_0_s: [:0]const u8 = builtin.fmt.about("futex-wake");
    const about_futex_wake_op_0_s: [:0]const u8 = builtin.fmt.about("futex-wake-op");
    const about_futex_1_s: [:0]const u8 = builtin.fmt.about("futex-error");
    fn exceptionFaultAtAddress(symbol: []const u8, fault_addr: u64) void {
        const fault_addr_s: []const u8 = builtin.fmt.ux64(fault_addr).readAll();
        var buf: [8192]u8 = undefined;
        var pathname: [4096]u8 = undefined;
        const link_s: []const u8 = pathname[0..builtin.debug.name(&pathname)];
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{ builtin.debug.about_fault_p0_s, symbol, " at address ", fault_addr_s, ", ", link_s, "\n" });
    }
    fn forkNotice(pid: u64) void {
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_fork_0_s, "pid=", builtin.fmt.ud64(pid).readAll(), "\n" });
    }
    fn waitNotice(id: WaitSpec.For, ret: Return) void {
        const pid_s: []const u8 = builtin.fmt.ud64(ret.pid).readAll();
        const if_signaled: bool = Status.ifSignaled(ret.status);
        const if_stopped: bool = Status.ifStopped(ret.status);
        const about_s: []const u8 = if (if_signaled) ", sig=" else if (if_stopped) ", stop=" else ", exit=";
        const code: u64 = if (if_signaled) Status.stop(ret.status) else if (if_stopped) Status.stop(ret.status) else Status.exit(ret.status);
        const code_s: []const u8 = builtin.fmt.ud64(code).readAll();
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_wait_0_s, @tagName(id), ", pid=", pid_s, about_s, code_s, "\n" });
    }
    fn signalActionNotice(signo: sys.SignalCode, handler: Handler) void {
        const handler_raw: usize = @bitCast(usize, handler);
        const handler_addr_s: []const u8 = builtin.fmt.ux64(handler_raw).readAll();
        const handler_set_s: []const u8 = if (handler_raw == 1) "ignore" else "default";
        const handler_s: []const u8 = if (handler_raw > 1) handler_addr_s else handler_set_s;
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_sig_0_s, "SIG", @tagName(signo), " -> ", handler_s, "\n" });
    }
    fn futexWaitAttempt(futex: *u32, value: u32, timeout: *const time.TimeSpec) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const value_s: []const u8 = builtin.fmt.ud64(value).readAll();
        const sec_s: []const u8 = builtin.fmt.ud64(timeout.sec).readAll();
        const nsec_s: []const u8 = builtin.fmt.ud64(timeout.nsec).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_wait_0_s, addr_s, ", word=", word_s, ", val=", value_s, ", sec=", sec_s, ", nsec=", nsec_s, "\n" });
    }
    fn futexWaitNotice(futex: *u32, value: u32, timeout: *const time.TimeSpec) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const value_s: []const u8 = builtin.fmt.ud64(value).readAll();
        const sec_s: []const u8 = builtin.fmt.ud64(timeout.sec).readAll();
        const nsec_s: []const u8 = builtin.fmt.ud64(timeout.nsec).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_wait_0_s, addr_s, ", word=", word_s, ", val=", value_s, ", sec=", sec_s, ", nsec=", nsec_s, "\n" });
    }
    fn futexWakeAttempt(futex: *u32, count: u64) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_wake_0_s, addr_s, ", word=", word_s, ", max=", count_s, "\n" });
    }
    fn futexWakeNotice(futex: *u32, count: u64, ret: u64) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
        const ret_s: []const u8 = builtin.fmt.ud64(ret).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_wake_0_s, addr_s, ", word=", word_s, ", max=", count_s, ", res=", ret_s, "\n" });
    }
    fn futexWakeOpAttempt(futex1: *u32, futex2: *u32, count1: u32, count2: u32, wake_op: FutexOp.WakeOp) void {
        _ = wake_op;
        const addr1_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex1)).readAll();
        const word1_s: []const u8 = builtin.fmt.ud64(futex1.*).readAll();
        const addr2_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex2)).readAll();
        const word2_s: []const u8 = builtin.fmt.ud64(futex2.*).readAll();
        const count1_s: []const u8 = builtin.fmt.ud64(count1).readAll();
        const count2_s: []const u8 = builtin.fmt.ud64(count2).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_futex_wake_0_s, "futex1=@",
            addr1_s,              ", word1=",
            word1_s,              ", max1=",
            count1_s,             ", futex2=@",
            addr2_s,              ", word2=",
            word2_s,              ", max2=",
            count2_s,             "\n",
        });
    }
    fn futexWakeOpNotice(futex1: *u32, futex2: *u32, count1: u32, count2: u32, wake_op: FutexOp.WakeOp, ret: u64) void {
        _ = wake_op;
        const addr1_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex1)).readAll();
        const word1_s: []const u8 = builtin.fmt.ud64(futex1.*).readAll();
        const addr2_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex2)).readAll();
        const word2_s: []const u8 = builtin.fmt.ud64(futex2.*).readAll();
        const count1_s: []const u8 = builtin.fmt.ud64(count1).readAll();
        const count2_s: []const u8 = builtin.fmt.ud64(count2).readAll();
        const ret_s: []const u8 = builtin.fmt.ud64(ret).readAll();
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_futex_wake_0_s, "futex1=@",
            addr1_s,              ", word1=",
            word1_s,              ", max1=",
            count1_s,             ", futex2=@",
            addr2_s,              ", word2=",
            word2_s,              ", max2=",
            count2_s,             ", res=",
            ret_s,                "\n",
        });
    }
    fn forkError(fork_error: anytype) void {
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_fork_1_s, " (", @errorName(fork_error), ")\n" });
    }
    fn waitError(wait_error: anytype) void {
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_wait_1_s, " (", @errorName(wait_error), ")\n" });
    }
    fn signalActionError(rt_sigaction_error: anytype, signo: sys.SignalCode, handler: Handler) void {
        const handler_raw: usize = @bitCast(usize, handler);
        const handler_addr_s: []const u8 = builtin.fmt.ux64(handler_raw).readAll();
        const handler_set_s: []const u8 = if (handler_raw == 1) "ignore" else "default";
        const handler_s: []const u8 = if (handler_raw > 1) handler_addr_s else handler_set_s;
        var buf: [560]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_sig_1_s, "SIG", @tagName(signo), " -> ", handler_s, " (", @errorName(rt_sigaction_error), ")\n" });
    }
    fn futexWaitError(futex_error: anytype, futex: *u32, value: u32, timeout: *const time.TimeSpec) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const value_s: []const u8 = builtin.fmt.ud64(value).readAll();
        const sec_s: []const u8 = builtin.fmt.ud64(timeout.sec).readAll();
        const nsec_s: []const u8 = builtin.fmt.ud64(timeout.nsec).readAll();
        const error_s: []const u8 = @errorName(futex_error);
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_1_s, addr_s, ", word=", word_s, ", val=", value_s, ", sec=", sec_s, ", nsec=", nsec_s, " (", error_s, ")\n" });
    }
    fn futexWakeError(futex_error: anytype, futex: *u32, count: u64) void {
        const addr_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex)).readAll();
        const word_s: []const u8 = builtin.fmt.ud64(futex.*).readAll();
        const count_s: []const u8 = builtin.fmt.ud64(count).readAll();
        const error_s: []const u8 = @errorName(futex_error);
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{ about_futex_1_s, addr_s, ", word=", word_s, ", max=", count_s, " (", error_s, ")\n" });
    }
    fn futexWakeOpError(futex_error: anytype, futex1: *u32, futex2: *u32, count1: u32, count2: u32, wake_op: FutexOp.WakeOp) void {
        _ = wake_op;
        const addr1_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex1)).readAll();
        const word1_s: []const u8 = builtin.fmt.ud64(futex1.*).readAll();
        const addr2_s: []const u8 = builtin.fmt.ux64(@ptrToInt(futex2)).readAll();
        const word2_s: []const u8 = builtin.fmt.ud64(futex2.*).readAll();
        const count1_s: []const u8 = builtin.fmt.ud64(count1).readAll();
        const count2_s: []const u8 = builtin.fmt.ud64(count2).readAll();
        const error_s: []const u8 = @errorName(futex_error);
        var buf: [3072]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
            about_futex_wake_0_s, "futex1=@",
            addr1_s,              ", word1=",
            word1_s,              ", max1=",
            count1_s,             ", futex2=@",
            addr2_s,              ", word2=",
            word2_s,              ", max2=",
            count2_s,             " (",
            error_s,              ")\n",
        });
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
            builtin.static.assert(@hasDecl(Options, "Map"));
            builtin.static.assert(Options.Map == @This());
        }
        fn tagCast(comptime child: type, comptime any: *const anyopaque) @Type(.EnumLiteral) {
            return @ptrCast(*const @Type(.EnumLiteral), @alignCast(@alignOf(child), any)).*;
        }
        fn anyCast(comptime child: type, comptime any: *const anyopaque) child {
            return @ptrCast(*const child, @alignCast(@alignOf(child), any)).*;
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
            builtin.debug.logFaultAIO(&buf, &.{ "'", arg, "' requires an argument\n" });
        }
        fn getOptInternal(comptime flag: Option, options: *Options, args: *[][*:0]u8, index: u64, offset: u64) void {
            const field = &@field(options, flag.field_name);
            const Field = @TypeOf(field.*);
            const arg: [:0]const u8 = meta.manyToSlice(args.*[index]);
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
                    field.* = meta.manyToSlice(args.*[index])[offset..];
                    shift(args, index);
                },
                .convert => |convert| {
                    if (offset == 0) {
                        shift(args, index);
                    }
                    if (args.len == index) {
                        getOptInternalArrityError(arg);
                    }
                    convert(options, meta.manyToSlice(args.*[index])[offset..]);
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
                    const arg1: [:0]const u8 = meta.manyToSlice(args.*[index]);
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
                const arg1: [:0]const u8 = meta.manyToSlice(args.*[index]);
                if (mach.testEqualMany8("--", arg1)) {
                    shift(args, index);
                    break :lo;
                }
                if (mach.testEqualMany8("--help", arg1)) {
                    Option.debug.optionNotice(all_options);
                    builtin.proc.exitNotice(0);
                }
                if (arg1.len != 0 and arg1[0] == '-') {
                    Option.debug.optionError(all_options, arg1);
                    builtin.proc.exitNotice(0);
                }
                index += 1;
            }
            return options;
        }
        const debug = struct {
            const about_opt_0_s: []const u8 = builtin.fmt.about("opt");
            const about_opt_1_s: []const u8 = builtin.fmt.about("opt-error");
            const about_stop_s: []const u8 = "\nstop parsing options with '--'\n";
            fn optionNotice(comptime all_options: []const Options.Map) void {
                const buf: []const u8 = comptime Options.Map.helpMessage(all_options);
                builtin.debug.write(buf);
            }
            fn optionError(all_options: []const Options.Map, arg: [:0]const u8) void {
                var buf: [4224]u8 = undefined;
                var len: u64 = 0;
                const bad_opt: []const u8 = getBadOpt(arg);
                len += mach.memcpyMulti(buf[len..].ptr, &[_][]const u8{ about_opt_1_s, "'", bad_opt, "'\n" });
                for (all_options) |option| {
                    const min: u64 = len;
                    if (option.long) |long_switch| {
                        const mats: u64 = matchLongSwitch(bad_opt, long_switch);
                        if (builtin.diff(u64, mats, long_switch.len) < 3) {
                            mach.memcpy(buf[len..].ptr, about_opt_0_s.ptr, about_opt_0_s.len);
                            len +%= about_opt_0_s.len;
                            if (option.short) |short_switch| {
                                len +%= mach.memcpyMulti(buf[len..].ptr, &.{ "'", short_switch, "', '" });
                            }
                            mach.memcpy(buf[len..].ptr, long_switch.ptr, long_switch.len);
                            len +%= long_switch.len;
                        }
                    }
                    if (min != len) {
                        buf[len] = '\'';
                        len +%= 1;
                        if (option.descr) |descr| {
                            buf[len] = '\t';
                            len +%= 1;
                            mach.memcpy(buf[len..].ptr, descr.ptr, descr.len);
                            len +%= descr.len;
                        }
                        buf[len] = '\n';
                        len +%= 1;
                    }
                }
                mach.memcpy(buf[len..].ptr, about_stop_s.ptr, about_stop_s.len);
                len +%= about_stop_s.len;
                builtin.debug.write(buf[0..len]);
            }
            fn getBadOpt(arg: [:0]const u8) []const u8 {
                var idx: u64 = 0;
                while (idx != arg.len) : (idx +%= 1) {
                    if (arg[idx] == '=') {
                        return arg[0..idx];
                    }
                }
                return arg;
            }
            fn matchLongSwitch(bad_opt: []const u8, long_switch: []const u8) u64 {
                var l_idx: u64 = 0;
                var mats: u64 = 0;
                lo: while (true) : (l_idx +%= 1) {
                    var r_idx: u64 = 0;
                    while (r_idx < long_switch.len) : (r_idx +%= 1) {
                        if (l_idx +% mats >= bad_opt.len) {
                            break :lo;
                        }
                        mats +%= @boolToInt(bad_opt[l_idx +% mats] == long_switch[r_idx]);
                    }
                }
                return mats;
            }
        };
    };
}
