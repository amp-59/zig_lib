const sys = @import("./sys.zig");
const lit = @import("./lit.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub const SignalAction = extern struct {
    handler: u64,
    flags: u64,
    restorer: u64,
    mask: [2]u32 = .{0} ** 2,
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
const Execute = meta.EnumBitField(enum(u64) {
    empty_path = AT.EMPTY_PATH,
    no_follow = AT.SYMLINK.NOFOLLOW,
    const AT = sys.AT;
});
pub const Clone = meta.EnumBitField(enum(u64) {
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
pub const IdType = meta.EnumBitField(enum(u64) {
    pid = ID.PID,
    all = ID.ALL,
    group = ID.PGID,
    file = ID.PIDFD,
    const ID = sys.ID;
});
pub const WaitId = meta.EnumBitField(enum(u64) {
    exited = WAIT.EXITED,
    stopped = WAIT.STOPPED,
    continued = WAIT.CONTINUED,
    no_wait = WAIT.NOWAIT,
    clone = WAIT.CLONE,
    no_thread = WAIT.NOTHREAD,
    all = WAIT.ALL,
    const WAIT = sys.WAIT;
});
pub const Wait = meta.EnumBitField(enum(u64) {
    exited = WAIT.NOHANG,
    continued = WAIT.CONTINUED,
    untraced = WAIT.UNTRACED,
    const WAIT = sys.WAIT;
});
pub const CloneArgs = extern struct {
    /// Flags bit mask
    flags: Clone,
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
    stack_len: u64 = 4096,
    /// Location of new TLS
    tls_addr: u64,
    /// Pointer to a pid_t array
    set_tid_addr: u64 = 0,
    /// Number of elements in set_tid
    set_tid_len: u64 = 0,
    /// File descriptor for target cgroup
    cgroup: u64 = 0,
};

pub const WaitSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    logging: builtin.Logging = .{},
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
            .pid => |val| @intCast(isize, val),
            .pgid => |val| @intCast(isize, val),
            .ppid => 0,
            .any => -1,
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
    id_type: IdType,
    options: Options,
    errors: sys.ErrorPolicy = .{ .throw = sys.wait_errors },
    logging: builtin.Logging = .{},
    return_type: type = u64,
    const Specification = @This();
    const Options = struct {
        exited: bool,
        stopped: bool,
        continued: bool,
        clone: bool,
        no_thread: bool,
        all: bool,
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
    logging: builtin.Logging = .{},
    return_type: type = u64,
    const Specification = @This();
};
pub const ExecuteSpec = struct {
    options: Options = .{},
    errors: sys.ErrorPolicy = .{ .throw = sys.execve_errors },
    return_type: type = void,
    args_type: type = []const [*:0]u8,
    vars_type: type = []const [*:0]u8,
    logging: builtin.Logging = .{},
    const Specification = @This();
    const Options = struct {
        no_follow: bool = false,
    };
    fn flags(comptime spec: ExecuteSpec) Execute {
        var flags_bitfield: Execute = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
};
pub const CloneSpec = struct {
    options: Options,
    errors: sys.ErrorPolicy = .{ .throw = sys.clone_errors },
    return_type: type = isize,
    logging: builtin.Logging = .{},
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
    pub fn flags(comptime spec: CloneSpec) Clone {
        var clone_flags: Clone = .{ .val = 0 };
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
    pub inline fn args(comptime spec: CloneSpec, stack_addr: u64) CloneArgs {
        return .{
            .flags = spec.flags(),
            .child_tid_addr = builtin.add(u64, stack_addr, 0x1000 - 0x10),
            .parent_tid_addr = builtin.add(u64, stack_addr, 0x1000 - 0x8),
            .stack_addr = stack_addr,
            .stack_len = 0x1000,
            .tls_addr = builtin.add(u64, stack_addr, 0x8),
        };
    }
};
pub fn exec(comptime spec: ExecuteSpec, pathname: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors.throw, spec.return_type) {
    const filename_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    if (meta.wrap(sys.call(.execve, spec.errors, spec.return_type, .{ filename_buf_addr, args_addr, vars_addr }))) {
        unreachable;
    } else |execve_error| {
        if (spec.logging.Error) {
            debug.executeError(execve_error, pathname, args);
        }
        return execve_error;
    }
}
pub fn execHandle(comptime spec: ExecuteSpec, fd: u64, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors.throw, spec.return_type) {
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: Execute = spec.flags();
    if (meta.wrap(sys.call(.execveat, spec.errors, spec.return_type, .{ fd, @ptrToInt(""), args_addr, vars_addr, flags.val }))) {
        unreachable;
    } else |execve_error| {
        if (spec.logging.Error) {
            debug.executeError(execve_error, args[0], args);
        }
        return execve_error;
    }
}
pub fn execAt(comptime spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) sys.Call(spec.errors.throw, spec.return_type) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: Execute = spec.flags();
    if (meta.wrap(sys.call(.execveat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val }))) {
        unreachable;
    } else |execve_error| {
        if (spec.logging.Error) {
            debug.executeError(execve_error, name, args);
        }
        return execve_error;
    }
}
pub const Status = struct {
    pub inline fn exitStatus(status: u32) u8 {
        return @intCast(u8, (status & 0xff00) >> 8);
    }
    pub inline fn termSignal(status: u32) u32 {
        return status & 0x7f;
    }
    pub inline fn stopSignal(status: u32) u32 {
        return exitStatus(status);
    }
    pub inline fn ifExited(status: u32) bool {
        return termSignal(status) == 0;
    }
    pub inline fn ifSignaled(status: u32) bool {
        return ((status & 0x7f) + 1) >> 1 > 0;
    }
    pub inline fn ifStopped(status: u32) bool {
        return (status & 0xff) == 0x7f;
    }
    pub inline fn ifContinued(status: u32) bool {
        return status == 0xffff;
    }
    pub inline fn coreDump(status: u32) u32 {
        return status & 0x80;
    }
};

pub fn waitPid(comptime spec: WaitSpec, id: WaitSpec.For, status_opt: ?*u32) sys.Call(spec.errors.throw, spec.return_type) {
    if (meta.wrap(sys.call(.wait4, spec.errors, spec.return_type, .{ WaitSpec.pid(id), if (status_opt) |status| @ptrToInt(status) else 0, 0, 0, 0 }))) |pid| {
        return pid;
    } else |wait_error| {
        if (spec.logging.Error) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn waitId(comptime spec: WaitIdSpec, id: u64, info: *SignalInfo) sys.Call(spec.errors.throw, spec.return_type) {
    const idtype: IdType = spec.id_type;
    const flags: WaitId = spec.flags();
    if (meta.wrap(sys.call(.waitid, spec.errors, spec.return_type, .{ idtype.val, id, @ptrToInt(&info), flags.val, 0 }))) |pid| {
        return pid;
    } else |wait_error| {
        if (spec.logging.Error) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn fork(comptime spec: ForkSpec) sys.Call(spec.errors.throw, spec.return_type) {
    if (meta.wrap(sys.call(.fork, spec.errors, spec.return_type, .{}))) |pid| {
        return pid;
    } else |fork_error| {
        if (spec.logging.Error) {
            debug.forkError(fork_error);
        }
        return fork_error;
    }
}
pub fn command(comptime spec: ExecuteSpec, pathname: [:0]const u8, args: spec.args_type, vars: spec.vars_type) !u8 {
    const filename_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const pid: u64 = try fork(.{});
    var status: u32 = 0;
    if (pid == 0) {
        if (meta.wrap(sys.call(.execve, spec.errors, spec.return_type, .{ filename_buf_addr, args_addr, vars_addr }))) {
            unreachable;
        } else |execve_error| {
            if (spec.logging.Error) {
                debug.executeError(execve_error, pathname, args);
            }
            return execve_error;
        }
    }
    if (spec.logging.Success) {
        debug.executeNotice(pathname, args);
    }
    builtin.assertEqual(u64, pid, try waitPid(.{}, .{ .pid = pid }, &status));
    return Status.exitStatus(status);
}
pub fn commandAt(comptime spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) !u8 {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const pid: u64 = try fork(.{});
    var status: u32 = 0;
    if (pid == 0) {
        const flags: Execute = spec.flags();
        if (meta.wrap(sys.call(.execveat, spec.errors, spec.return_type, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val }))) {
            unreachable;
        } else |execve_error| {
            if (spec.logging.Error) {
                debug.executeError(execve_error, name, args);
            }
            return execve_error;
        }
    }
    if (spec.logging.Success) {
        debug.executeNotice(name, args);
    }
    builtin.assertEqual(u64, pid, try waitPid(.{}, .{ .pid = pid }, &status));
    return Status.exitStatus(status);
}
pub const start = opaque {
    pub export fn _start() callconv(.Naked) noreturn {
        static.stack_addr = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        @call(.never_inline, callMain, .{});
    }
    pub noinline fn panic(msg: []const u8, _: @TypeOf(@errorReturnTrace()), _: ?usize) noreturn {
        @setCold(true);
        sys.call(.write, .{}, void, .{ 2, @ptrToInt(msg.ptr), msg.len });
        sys.call(.exit, .{}, noreturn, .{2});
    }
    pub noinline fn panicOutOfBounds(idx: u64, max_len: u64) noreturn {
        @setCold(true);
        var buf: [1024]u8 = undefined;
        if (max_len == 0) {
            builtin.debug.logFaultAIO(&buf, &[_][]const u8{
                debug.about_error_s,             "indexing (",
                builtin.fmt.ud64(idx).readAll(), ") into empty array is not allowed\n",
            });
        } else {
            builtin.debug.logFaultAIO(&buf, &[_][]const u8{
                debug.about_error_s,                      "index ",
                builtin.fmt.ud64(idx).readAll(),          " above maximum ",
                builtin.fmt.ud64(max_len -% 1).readAll(), "\n",
            });
        }
        sys.call(.exit, .{}, noreturn, .{2});
    }
    pub noinline fn panicSentinelMismatch(expected: anytype, actual: @TypeOf(expected)) noreturn {
        @setCold(true);
        var buf: [1024]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{
            debug.about_error_s,                 "sentinel mismatch: expected ",
            builtin.fmt.int(expected).readAll(), ", found ",
            builtin.fmt.int(actual).readAll(),   "\n",
        });
    }
    pub noinline fn panicStartGreaterThanEnd(lower: usize, upper: usize) noreturn {
        @setCold(true);
        var buf: [1024]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{
            debug.about_error_s,               "start index ",
            builtin.fmt.ud64(lower).readAll(), " is larger than end index ",
            builtin.fmt.ud64(upper).readAll(), "\n",
        });
    }
    pub noinline fn panicInactiveUnionField(active: anytype, wanted: @TypeOf(active)) noreturn {
        @setCold(true);
        var buf: [1024]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{
            debug.about_error_s, "access of union field '",
            @tagName(wanted),    "' while field '",
            @tagName(active),    "' is active",
        });
        sys.call(.exit, .{}, noreturn, .{2});
    }
    pub noinline fn panicUnwrapError(_: @TypeOf(@errorReturnTrace()), _: anyerror) noreturn {
        @compileError("error is discarded");
    }
    fn unexpectedReturnCodeValueError(rc: u64) void {
        var buf: [512]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{
            "unexpected return value: ", builtin.fmt.ud64(rc).readAll(),
            "\n",
        });
    }
};
pub const exception = opaque {
    pub fn updateSignalHandler(signo: u32, handler_function: anytype) void {
        var act = SignalAction{
            .handler = @ptrToInt(&handler_function),
            .flags = (SA.SIGINFO | SA.RESTART | SA.RESETHAND | SA.RESTORER),
            .restorer = @ptrToInt(&exception.restoreRunTime),
        };
        setSignalAction(signo, &act, null);
    }
    fn updateExceptionHandlers(act: *const SignalAction) void {
        setSignalAction(SIG.SEGV, act, null);
        setSignalAction(SIG.ILL, act, null);
        setSignalAction(SIG.BUS, act, null);
        setSignalAction(SIG.FPE, act, null);
    }
    pub fn enableExceptionHandlers() void {
        var act = SignalAction{
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
        sys.call(.rt_sigaction, .{}, void, .{ signo, sa_new_addr, sa_old_addr, @sizeOf(@TypeOf(new_action.mask)) });
    }
    fn resetExceptionHandlers() void {
        var act = SignalAction{ .handler = sys.SIG.DFL, .flags = 0, .restorer = 0 };
        updateExceptionHandlers(&act);
    }
    pub fn exceptionHandler(sig: u32, info: *const SignalInfo, _: ?*const anyopaque) noreturn {
        resetExceptionHandlers();
        debug.exceptionFaultAtAddress(switch (sig) {
            SIG.SEGV => "SIGSEGV",
            SIG.ILL => "SIGILL",
            SIG.BUS => "SIGBUS",
            SIG.FPE => "SIGFPE",
            else => unreachable,
        }, info.fields.fault.addr);
        sys.call(.exit, .{}, noreturn, .{2});
    }
    pub fn restoreRunTime() callconv(.Naked) void {
        switch (builtin.zig.zig_backend) {
            .stage2_c => return asm volatile (
                \\ movl %[number], %%eax
                \\ syscall
                \\ retq
                :
                : [number] "i" (15),
                : "rcx", "r11", "memory"
            ),
            else => return asm volatile ("syscall"
                :
                : [number] "{rax}" (15),
                : "rcx", "r11", "memory"
            ),
        }
    }
    const SA = sys.SA;
    const SIG = sys.SIG;
};
fn exitWithError(error_name: []const u8) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    builtin.debug.logAbort(&buf, error_name);
    sys.call(.exit, .{}, noreturn, .{2});
}
const static = opaque {
    var stack_addr: u64 = 0;
};
pub noinline fn callMain() noreturn {
    @setAlignStack(16);
    if (@hasDecl(builtin.root, "main")) {
        const Main: type = @TypeOf(builtin.root.main);
        const main: Main = builtin.root.main;
        const Type: type = @TypeOf(@typeInfo(Main));
        const main_type_info: Type = @typeInfo(Main);
        const main_return_type: type = main_type_info.Fn.return_type.?;
        const main_return_type_info: Type = @typeInfo(main_return_type);
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
        if (@hasDecl(builtin.root, "enableExceptionHandlers")) {
            builtin.root.enableExceptionHandlers();
        }
        if (main_return_type == void) {
            @call(.auto, main, params);
            sys.call(.exit, .{}, noreturn, .{0});
        }
        if (main_return_type == u8) {
            sys.call(.exit, .{}, noreturn, .{@call(.auto, main, params)});
        }
        if (main_return_type_info == .ErrorUnion and
            main_return_type_info.ErrorUnion.payload == void)
        {
            if (@call(.auto, main, params)) {
                sys.call(.exit, .{}, noreturn, .{0});
            } else |err| {
                @setCold(true);
                exitWithError(@errorName(err));
                sys.call(.exit, .{}, noreturn, .{@intCast(u8, @errorToInt(err))});
            }
        }
        if (main_return_type_info == .ErrorUnion and
            main_return_type_info.ErrorUnion.payload == u8)
        {
            if (@call(.auto, builtin.root.main, params)) |rc| {
                sys.call(.exit, .{}, noreturn, .{rc});
            } else |err| {
                @setCold(true);
                exitWithError(@errorName(err));
                sys.call(.exit, .{}, noreturn, .{@intCast(u8, @errorToInt(err))});
            }
        }
        if (main_return_type_info == .ErrorSet) {
            @compileError("main always return an error: " ++ @typeName(main_return_type));
        }
    } else if (builtin.zig.output_mode == .Exe) {
        @compileError("main not public/defined in source root");
    }
    unreachable;
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

pub noinline fn callClone(
    comptime spec: CloneSpec,
    stack_addr: u64,
    result_ptr: anytype,
    function: anytype,
    args: anytype,
) sys.Call(spec.errors.throw, spec.return_type) {
    const Fn: type = @TypeOf(function);
    const cl_args: CloneArgs = spec.args(stack_addr);
    const cl_args_addr: u64 = @ptrToInt(&cl_args);
    const cl_args_size: u64 = @sizeOf(CloneArgs);
    const cl_sysno: u64 = @enumToInt(sys.Fn.clone3);
    const ret_off: u64 = 0;
    const call_off: u64 = 8;
    const args_off: u64 = 16;
    @intToPtr(**const Fn, stack_addr +% call_off).* = &function;
    @intToPtr(*meta.Args(Fn), stack_addr +% args_off).* = args;
    if (@TypeOf(result_ptr) != void) {
        @intToPtr(*@TypeOf(result_ptr), stack_addr +% ret_off).* = result_ptr;
    }
    const rc: i64 = asm volatile (
        \\syscall
        : [ret] "={rax}" (-> i64),
        : [cl_sysno] "{rax}" (cl_sysno),
          [cl_args_addr] "{rdi}" (cl_args_addr),
          [cl_args_size] "{rsi}" (cl_args_size),
        : "rcx", "r11", "memory"
    );
    if (rc == 0) {
        const tl_stack_addr: u64 = asm volatile (
            \\xorq  %rbp,   %rbp
            \\subq  $4096,  %rsp
            \\movq  %rsp,   %[tl_stack_addr]
            : [tl_stack_addr] "=r" (-> u64),
            :
            : "rbp", "rsp", "memory"
        );
        const ret_addr: u64 = tl_stack_addr +% ret_off;
        const call_addr: u64 = tl_stack_addr +% call_off;
        const args_addr: u64 = tl_stack_addr +% args_off;
        if (@TypeOf(result_ptr) != void) {
            if (@sizeOf(@TypeOf(result_ptr.*)) <= @sizeOf(usize) or
                @typeInfo(@TypeOf(result_ptr.*)) != .ErrorUnion)
            {
                @intToPtr(**meta.Return(Fn), ret_addr).*.* = @call(
                    .never_inline,
                    @intToPtr(**Fn, call_addr).*,
                    @intToPtr(*meta.Args(Fn), args_addr).*,
                );
            } else {
                @call(
                    .never_inline,
                    callErrorOrMediaReturnValueFunction,
                    .{ @TypeOf(function), ret_addr, call_addr, args_addr },
                );
            }
        } else {
            @call(
                .never_inline,
                @intToPtr(**Fn, call_addr).*,
                @intToPtr(*meta.Args(Fn), args_addr).*,
            );
        }
        asm volatile (
            \\movq  $60,    %rax
            \\movq  $0,     %rdi
            \\syscall
            ::: "rax", "rdi");
        unreachable;
    }
    if (spec.errors.throw) |errors| {
        if (rc < 0) return meta.zigErrorThrow(errors, rc);
    }
    if (spec.errors.abort) |errors| {
        if (rc < 0) return meta.zigErrorAbort(errors, rc);
    }
    if (spec.return_type == void) {
        return;
    }
    if (spec.return_type != noreturn) {
        return @intCast(spec.return_type, rc);
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
    args.* = args.*[0 .. args.len - 1];
}
pub const ArgsIterator = struct {
    args: [][*:0]u8,
    index: u64 = 1,
    pub fn init(args: [][*:0]u8) ArgsIterator {
        return .{ .args = args };
    }
    pub fn readOne(itr: *ArgsIterator) ?[:0]const u8 {
        if (itr.index <= itr.args.len) {
            const arg: [*:0]const u8 = itr.args[itr.index];
            itr.index +%= 1;
            return arg[0..strlen(arg) :0];
        }
        return null;
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
pub fn GenericOptions(comptime Options: type) type {
    return struct {
        field_name: []const u8,
        short: ?[]const u8 = null,
        // short_prefix: []const u8 = "-",
        // short_anti_prefix: []const u8 = "+",
        long: ?[]const u8 = null,
        // long_prefix: []const u8 = "--",
        // long_anti_prefix: []const u8 = "--no-",
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
                .Enum => tagCast(any),
                else => anyCast(child, any),
            };
        }
        fn getOptInternal(comptime flag: Option, options: *Options, args: *[][*:0]u8, index: u64, offset: u64) void {
            const field = &@field(options, flag.field_name);
            const Field = @TypeOf(field.*);
            switch (flag.assign) {
                .boolean => |value| {
                    shift(args, index);
                    field.* = value;
                },
                .argument => {
                    if (offset == 0) {
                        shift(args, index);
                    }
                    field.* = meta.manyToSlice(args.*[index])[offset..];
                    shift(args, index);
                },
                .convert => |convert| {
                    if (offset == 0) {
                        shift(args, index);
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
            var buf: []const u8 = "option flags:\n";
            var max_width: comptime_int = 0;
            for (opt_map) |option| {
                var width: u64 = 0;
                if (option.short) |short_switch| {
                    width += 1 +% short_switch.len;
                }
                if (option.long) |long_switch| {
                    width += 2 +% long_switch.len;
                }
                if (option.assign == .argument) {
                    width += 3 +% option.assign.argument.len;
                }
                max_width = @max(width, max_width);
            }
            max_width += 7;
            max_width &= -8;
            for (opt_map) |option| {
                buf = buf ++ " " ** 4;
                if (option.short) |short_switch| {
                    var tmp: []const u8 = short_switch;
                    if (option.long) |long_switch| {
                        tmp = tmp ++ ", " ++ long_switch;
                    }
                    if (option.descr) |descr| {
                        tmp = tmp ++ " " ** (4 +% (max_width - tmp.len)) ++ descr;
                    }
                    if (option.assign == .argument) {
                        tmp = tmp ++ " <" ++ option.assign.argument ++ ">";
                    }
                    buf = buf ++ tmp ++ "\n";
                } else {
                    var tmp: []const u8 = option.long.?;
                    if (option.descr) |descr| {
                        tmp = tmp ++ " " ** (4 +% (max_width - tmp.len)) ++ descr;
                    }
                    buf = buf ++ tmp ++ "\n";
                }
            }
            return buf;
        }
    };
}
pub inline fn getOpts(comptime Options: type, args: *[][*:0]u8, comptime all_options: []const GenericOptions(Options)) Options {
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
                if (builtin.testEqual([]const u8, long_switch, arg1)) {
                    option.getOptInternal(&options, args, index, 0);
                    continue :lo;
                }
                if (option.assign == .boolean) {
                    break :blk;
                }
                const assign_long_switch: []const u8 = long_switch ++ "=";
                if (arg1.len >= assign_long_switch.len and
                    builtin.testEqual([]const u8, assign_long_switch, arg1[0..assign_long_switch.len]))
                {
                    option.getOptInternal(&options, args, index, assign_long_switch.len);
                    continue :lo;
                }
            }
            if (option.short) |short_switch| blk: {
                if (builtin.testEqual([]const u8, short_switch, arg1)) {
                    option.getOptInternal(&options, args, index, 0);
                    continue :lo;
                }
                if (option.assign == .boolean) {
                    break :blk;
                }
                if (arg1.len >= short_switch.len and
                    builtin.testEqual([]const u8, short_switch, arg1[0..short_switch.len]))
                {
                    option.getOptInternal(&options, args, index, short_switch.len);
                    continue :lo;
                }
            }
        }
        const arg1: [:0]const u8 = meta.manyToSlice(args.*[index]);
        if (builtin.testEqual([]const u8, "--", arg1)) {
            shift(args, index);
            break :lo;
        }
        if (builtin.testEqual([]const u8, "--help", arg1)) {
            debug.optionNotice(Options, all_options);
            sys.call(.exit, .{}, noreturn, .{0});
        }
        if (arg1.len != 0 and arg1[0] == '-') {
            debug.optionError(Options, all_options, arg1);
            sys.call(.exit, .{}, noreturn, .{2});
        }
        index += 1;
    }
    return options;
}
const debug = opaque {
    const about_stop_s: []const u8 = "\nstop parsing options with '--'\n";
    const about_opt_0_s: []const u8 = "opt:            '";
    const about_opt_1_s: []const u8 = "opt-error:      '";
    const about_error_s: []const u8 = "error:          ";
    const about_fork_0_s: []const u8 = "fork:           ";
    const about_fork_1_s: []const u8 = "fork-error:     ";
    const about_wait_0_s: []const u8 = "wait:           ";
    const about_wait_1_s: []const u8 = "wait-error:     ";
    const about_execve_0_s: []const u8 = "execve:         ";
    const about_execve_1_s: []const u8 = "execve-error:   ";
    const about_execveat_1_s: []const u8 = "execveat-error: ";

    fn optionNotice(comptime Options: type, comptime opt_map: []const Options.Map) void {
        const buf: []const u8 = comptime Options.Map.helpMessage(opt_map);
        builtin.debug.write(buf);
    }
    pub fn executeNotice(filename: [:0]const u8, args: []const [*:0]const u8) void {
        var buf: [4096 +% 128]u8 = undefined;
        var len: u64 = 0;
        len += builtin.debug.writeMany(buf[len..], about_execve_0_s);
        len += builtin.debug.writeMany(buf[len..], filename);
        buf[len] = ' ';
        len += 1;
        var argc: u16 = @intCast(u16, args.len);
        var i: u16 = 0;
        while (i != argc) : (i += 1) {
            const arg_len: u64 = strlen(args[i]);
            if (arg_len == 0) {
                buf[len] = '\'';
                len +%= 1;
                buf[len] = '\'';
                len +%= 1;
            }
            if (len +% arg_len >= buf.len - 37) {
                break;
            }
            for (args[i][0..arg_len]) |c, j| buf[len +% j] = c;
            len += arg_len;
            buf[len] = ' ';
            len += 1;
        }
        if (argc != i) {
            len += builtin.debug.writeMany(buf[len..], " ... and ");
            len += builtin.debug.writeMany(buf[len..], builtin.fmt.ud64(argc - i).readAll());
            len += builtin.debug.writeMany(buf[len..], " more args ... \n");
        } else {
            buf[len] = '\n';
            len += 1;
        }
        builtin.debug.write(buf[0..len]);
    }
    fn exceptionFaultAtAddress(symbol: []const u8, fault_addr: u64) void {
        var buf: [4096]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{ symbol, " at address ", builtin.fmt.ux64(fault_addr).readAll(), "\n" });
    }
    fn forkError(fork_error: anytype) void {
        var buf: [16 +% 32 +% 512]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{ about_fork_1_s, " (", @errorName(fork_error), ")\n" });
    }
    fn waitError(wait_error: anytype) void { // TODO: Report more information, such as pid, idtype, conditions
        var buf: [16 +% 32 +% 512]u8 = undefined;
        builtin.debug.logFaultAIO(&buf, &[_][]const u8{ about_wait_1_s, " (", @errorName(wait_error), ")\n" });
    }
    fn optionError(comptime Options: type, all_options: []const Options.Map, arg: [:0]const u8) void {
        var buf: [4096 +% 128]u8 = undefined;
        var len: u64 = 0;
        const bad_opt: []const u8 = blk: {
            var idx: u64 = 0;
            while (idx != arg.len) : (idx += 1) {
                if (arg[idx] == '=') {
                    break :blk arg[0..idx];
                }
            }
            break :blk arg;
        };
        len += builtin.debug.writeMulti(buf[len..], &[_][]const u8{ about_opt_1_s, bad_opt, "'\n" });
        for (all_options) |option| {
            const min: u64 = len;
            if (option.long) |long_switch| {
                const mats: u64 = blk: {
                    var l_idx: u64 = 0;
                    var mats: u64 = 0;
                    lo: while (true) : (l_idx += 1) {
                        var r_idx: u64 = 0;
                        while (r_idx < long_switch.len) : (r_idx += 1) {
                            if (l_idx +% mats >= bad_opt.len) {
                                break :lo;
                            }
                            mats += @boolToInt(bad_opt[l_idx +% mats] == long_switch[r_idx]);
                        }
                    }
                    break :blk mats;
                };
                if (builtin.diff(u64, mats, long_switch.len) < 3) {
                    len += builtin.debug.writeMany(buf[len..], about_opt_0_s);
                    if (option.short) |short_switch| {
                        len += builtin.debug.writeMany(buf[len..], short_switch);
                        len += builtin.debug.writeMany(buf[len..], "', '");
                    }
                    len += builtin.debug.writeMany(buf[len..], long_switch);
                }
            }
            if (min != len) {
                len += builtin.debug.writeMany(buf[len..], "'");
                if (option.descr) |descr| {
                    buf[len] = '\t';
                    len += 1;
                    len += builtin.debug.writeMany(buf[len..], descr);
                }
                buf[len] = '\n';
                len += 1;
            }
        }
        len += builtin.debug.writeMany(buf[len..], about_stop_s);
        builtin.debug.write(buf[0..len]);
    }
    // Try to make these two less original
    pub fn executeError(exec_error: anytype, filename: [:0]const u8, args: []const [*:0]const u8) void {
        const max_len: u64 = 4096 +% 128;
        var buf: [max_len]u8 = undefined;
        var len: u64 = 0;
        len += builtin.debug.writeMany(buf[len..], about_execve_1_s);
        len += builtin.debug.writeMany(buf[len..], "(");
        len += builtin.debug.writeMany(buf[len..], @errorName(exec_error));
        len += builtin.debug.writeMany(buf[len..], ")");
        len += builtin.debug.writeMany(buf[len..], filename);
        buf[len] = ' ';
        len += 1;
        var argc: u16 = @intCast(u16, args.len);
        var i: u16 = 0;
        while (i != argc) : (i += 1) {
            const arg_len: u64 = strlen(args[i]);
            if (arg_len == 0) {
                buf[len] = '\'';
                len +%= 1;
                buf[len] = '\'';
                len +%= 1;
            }
            if (len +% arg_len >= max_len - 37) {
                break;
            }
            for (args[i][0..arg_len]) |c, j| buf[len +% j] = c;
            len += arg_len;
            buf[len] = ' ';
            len += 1;
        }
        if (argc != i) {
            len += builtin.debug.writeMany(buf[len..], " ... and ");
            len += builtin.debug.writeMany(buf[len..], builtin.fmt.ud64(argc - i).readAll());
            len += builtin.debug.writeMany(buf[len..], " more args ... \n");
        } else {
            buf[len] = '\n';
            len += 1;
        }
        builtin.debug.write(buf[0..len]);
    }
};
// Common utility functions:
fn strlen(s: [*:0]const u8) u64 {
    var len: u64 = 0;
    while (s[len] != 0) len += 1;
    return len;
}
