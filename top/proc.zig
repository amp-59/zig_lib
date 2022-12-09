const sys = @import("./sys.zig");
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
    /// Where to store PID file descriptor
    /// (int *)
    pidfd: u64,
    /// Where to store child TID,
    /// in child's memory (pid_t *)
    child_tid: u64,
    /// Where to store child TID,
    /// in parent's memory (pid_t *)
    parent_tid: u64,
    /// Signal to deliver to parent on
    /// child termination
    exit_signal: u64,
    /// Pointer to lowest byte of stack
    stack: u64,
    /// Size of stack
    stack_size: u64,
    /// Location of new TLS
    tls: u64,
    /// Pointer to a pid_t array
    /// (since Linux 5.5)
    set_tid: u64,
    /// Number of elements in set_tid
    /// (since Linux 5.5)
    set_tid_size: u64,
    /// File descriptor for target cgroup
    /// of child (since Linux 5.7)
    cgroup: u64,
};
pub const WaitSpec = struct {
    options: Options = .{},
    errors: ?[]const sys.ErrorCode = sys.wait_errors,
    logging: bool = builtin.is_verbose,
    return_type: type = u64,
    const Specification = @This();
    const Options = struct {
        exited: bool = false,
        stopped: bool = false,
        continued: bool = false,
    };
    const For = union(enum) { pid: usize, pgid: usize, ppid, any };
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
    fn pid(id: For) u64 {
        const val: isize = switch (id) {
            .pid => |val| @intCast(isize, val),
            .pgid => |val| @intCast(isize, val),
            .ppid => 0,
            .any => -1,
        };
        return @bitCast(usize, val);
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const WaitIdSpec = struct {
    id_type: IdType,
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.wait_errors,
    logging: bool = builtin.is_verbose,
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
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const ForkSpec = struct {
    errors: ?[]const sys.ErrorCode = sys.fork_errors,
    logging: bool = builtin.is_verbose,
    return_type: ?type = u64,
    const Specification = @This();
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const ExecuteSpec = struct {
    options: Options = .{},
    errors: ?[]const sys.ErrorCode = sys.execve_errors,
    return_type: type = void,
    args_type: type = [][*:0]u8,
    vars_type: type = [][*:0]u8,
    logging: bool = builtin.is_verbose,
    const Specification = @This();
    const Options = struct { no_follow: bool = false };
    fn flags(comptime spec: ExecuteSpec) Execute {
        var flags_bitfield: Execute = .{ .val = 0 };
        if (spec.options.no_follow) {
            flags_bitfield.set(.no_follow);
        }
        return flags_bitfield;
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub const CloneSpec = struct {
    options: Options,
    errors: ?[]const sys.ErrorCode = sys.clone_errors,
    return_type: type = isize,
    logging: bool = builtin.is_verbose,
    const Options = struct {
        address_space: bool,
        file_system: bool,
        files: bool,
        signal_handlers: bool,
        thread: bool,
        sysvsem: bool,
        set_thread_local_storage: bool,
        set_parent_thread_id: bool,
        set_child_thread_id: bool,
        clear_child_thread_id: bool,
        io: bool,
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
            .pidfd = 0,
            .child_tid = stack_addr + 0x1000 - 0x10,
            .parent_tid = stack_addr + 0x1000 - 0x8,
            .exit_signal = 0,
            .stack = stack_addr,
            .stack_size = 4096,
            .tls = stack_addr + 0x8,
            .set_tid = 0,
            .set_tid_size = 0,
            .cgroup = 0,
        };
    }
    pub usingnamespace sys.FunctionInterfaceSpec(Specification);
};
pub fn exec(comptime spec: ExecuteSpec, pathname: [:0]const u8, args: spec.options.args_type, vars: spec.vars_type) spec.Unwrapped(.execve) {
    const filename_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    if (spec.call(.execve, .{ filename_buf_addr, args_addr, vars_addr })) {
        unreachable;
    } else |execve_error| {
        if (spec.logging or builtin.is_debug) {
            debug.executeError(execve_error, pathname, args);
        }
        return execve_error;
    }
}
pub fn execHandle(comptime spec: ExecuteSpec, fd: u64, args: spec.options.args_type, vars: spec.vars_type) spec.Unwrapped(.execveat) {
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: Execute = spec.flags();
    if (spec.call(.execveat, .{ fd, @ptrToInt(""), args_addr, vars_addr, flags.val })) {
        unreachable;
    } else |execve_error| {
        if (spec.logging or builtin.is_debug) {
            debug.executeError(execve_error, args[0], args);
        }
        return execve_error;
    }
}
pub fn execAt(comptime spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) spec.Unwrapped(.execveat) {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const flags: Execute = spec.flags();
    if (spec.call(.execveat, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val })) {
        unreachable;
    } else |execve_error| {
        if (spec.logging or builtin.is_debug) {
            debug.executeError(execve_error, name, args);
        }
        return execve_error;
    }
}
pub fn waitPid(comptime spec: WaitSpec, id: WaitSpec.For) spec.Unwrapped(.wait4) {
    var status: u64 = 0;
    if (spec.call(.wait4, .{ WaitSpec.pid(id), @ptrToInt(&status), 0, 0 })) |pid| {
        return pid;
    } else |wait_error| {
        if (spec.logging or builtin.is_verbose) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn waitId(comptime spec: WaitIdSpec, id: u64) spec.Unwrapped(.wait4) {
    const idtype: IdType = spec.id_type;
    const flags: WaitId = spec.flags();
    var info: SignalInfo = undefined;
    if (spec.call(.wait4, .{ idtype.val, id, @ptrToInt(&info), flags.val })) |pid| {
        return pid;
    } else |wait_error| {
        if (spec.logging or builtin.is_verbose) {
            debug.waitError(wait_error);
        }
        return wait_error;
    }
}
pub fn fork(comptime spec: ForkSpec) spec.Unwrapped(.fork) {
    if (spec.call(.fork, .{})) |pid| {
        return pid;
    } else |fork_error| {
        if (spec.logging or builtin.is_debug) {
            debug.forkError(fork_error);
        }
        return fork_error;
    }
}
pub fn command(comptime spec: ExecuteSpec, pathname: [:0]const u8, args: spec.options.args_type, vars: spec.vars_type) !u64 {
    const filename_buf_addr: u64 = @ptrToInt(pathname.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const pid: u64 = try sys.fork();
    if (pid == 0) {
        if (spec.call(.execve, .{ filename_buf_addr, args_addr, vars_addr })) {
            unreachable;
        } else |execve_error| {
            if (spec.logging or builtin.is_debug) {
                debug.executeError(execve_error, pathname, args);
            }
            return execve_error;
        }
    }
    if (spec.logging) {
        debug.executeNotice(pathname, args);
    }
    return waitPid(pid);
}
pub fn commandAt(comptime spec: ExecuteSpec, dir_fd: u64, name: [:0]const u8, args: spec.args_type, vars: spec.vars_type) !u64 {
    const name_buf_addr: u64 = @ptrToInt(name.ptr);
    const args_addr: u64 = @ptrToInt(args.ptr);
    const vars_addr: u64 = @ptrToInt(vars.ptr);
    const pid: u64 = try fork(.{});
    if (pid == 0) {
        const flags: Execute = spec.flags();
        if (spec.call(.execveat, .{ dir_fd, name_buf_addr, args_addr, vars_addr, flags.val })) {
            unreachable;
        } else |execve_error| {
            if (spec.logging or builtin.is_debug) {
                debug.executeError(execve_error, name, args);
            }
            return execve_error;
        }
    }
    if (spec.logging) {
        debug.executeNotice(name, args);
    }
    return waitPid(.{}, .{ .pid = pid });
}
pub const start = opaque {
    pub export fn _start() callconv(.Naked) noreturn {
        const entry_stack_address = asm volatile (
            \\xorq  %%rbp,  %%rbp
            : [argc] "={rsp}" (-> u64),
        );
        callMain(entry_stack_address);
    }
    pub noinline fn panic(msg: []const u8, _: @TypeOf(@errorReturnTrace()), _: ?usize) noreturn {
        @setCold(true);
        sys.noexcept.write(2, @ptrToInt(msg.ptr), msg.len);
        sys.exit(2);
    }
    pub noinline fn panicUnwrapError(_: @TypeOf(@errorReturnTrace()), _: anyerror) noreturn {
        @compileError("error is discarded");
    }
    pub noinline fn panicOutOfBounds(max_len: u64, idx: u64) noreturn {
        @setCold(true);
        var msg: [1024]u8 = undefined;
        if (max_len == 0) {
            debug.print(&msg, &[_][]const u8{
                debug.about_error_s,             "indexing (",
                builtin.fmt.ud64(idx).readAll(), ") into empty array is not allowed\n",
            });
        } else {
            debug.print(&msg, &[_][]const u8{
                debug.about_error_s,                      "index ",
                builtin.fmt.ud64(idx).readAll(),          " above maximum ",
                builtin.fmt.ud64(max_len -% 1).readAll(), "\n",
            });
        }
        sys.exit(2);
    }
    //pub fn panicSentinelMismatch(expected: anytype, actual: @TypeOf(expected)) noreturn {
    //    @setCold(true);
    //    var msg: [1024]u8 = undefined;
    //    var len: u64 = 0;
    //    for ([_][]const u8{
    //        debug.about_error_s, "sentinel mismatch: expected ",
    //        expected,            ", found ",
    //        actual,              "\n",
    //    }) |s| {
    //        for (s) |c, i| msg[len +% i] = c;
    //        len +%= s.len;
    //    }
    //    sys.noexcept.write(2, @ptrToInt(&msg), len);
    //    sys.exit(2);
    //}
    pub fn panicStartGreaterThanEnd(lower: usize, upper: usize) noreturn {
        @setCold(true);
        var msg: [1024]u8 = undefined;
        debug.print(&msg, [_][]const u8{
            debug.about_error_s,               "start index ",
            builtin.fmt.ud64(lower).readAll(), " is larger than end index ",
            builtin.fmt.ud64(upper).readAll(), "\n",
        });
        sys.exit(2);
    }
    pub fn panicInactiveUnionField(active: anytype, wanted: @TypeOf(active)) noreturn {
        @setCold(true);
        var msg: [1024]u8 = undefined;
        debug.print(&msg, &[_][]const u8{
            debug.about_error_s, "access of union field '",
            @tagName(wanted),    "' while field '",
            @tagName(active),    "' is active",
        });
        sys.exit(2);
    }
};
pub const exception = opaque {
    fn updateExceptionHandlers(act: *const SignalAction) void {
        setSignalAction(sys.SIG.SEGV, act, null);
        setSignalAction(sys.SIG.ILL, act, null);
        setSignalAction(sys.SIG.BUS, act, null);
        setSignalAction(sys.SIG.FPE, act, null);
    }
    pub fn enableExceptionHandlers() void {
        var act = SignalAction{
            .handler = @ptrToInt(&exceptionHandler),
            .flags = (sys.SA.SIGINFO | sys.SA.RESTART | sys.SA.RESETHAND | sys.SA.RESTORER),
            .restorer = @ptrToInt(&restoreRunTime),
        };
        updateExceptionHandlers(&act);
    }
    pub fn disableExceptionHandlers() void {
        var act = SignalAction{
            .handler = sys.SIG.DFL,
            .flags = sys.SA.RESTORER,
            .restorer = @ptrToInt(&restoreRunTime),
        };
        updateExceptionHandlers(&act);
    }
    fn setSignalAction(signo: u64, noalias new_action: *const SignalAction, noalias old_action: ?*SignalAction) void {
        const sa_new_addr: u64 = @ptrToInt(new_action);
        const sa_old_addr: u64 = if (old_action) |action| @ptrToInt(action) else 0;
        sys.noexcept.rt_sigaction(signo, sa_new_addr, sa_old_addr, @sizeOf(@TypeOf(new_action.mask)));
    }
    fn resetExceptionHandlers() void {
        var act = SignalAction{ .handler = sys.SIG.DFL, .flags = 0, .restorer = 0 };
        updateExceptionHandlers(&act);
    }
    pub fn exceptionHandler(sig: u32, info: *const SignalInfo, _: ?*const anyopaque) noreturn {
        resetExceptionHandlers();
        debug.exceptionFaultAtAddress(switch (sig) {
            sys.SIG.SEGV => "SIGSEGV",
            sys.SIG.ILL => "SIGILL",
            sys.SIG.BUS => "SIGBUS",
            sys.SIG.FPE => "SIGFPE",
            else => unreachable,
        }, info.fields.fault.addr);
        sys.exit(2);
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
};
fn exitWithError(any_error: anytype) void {
    @setCold(true);
    var buf: [16 + 4096 + 512 + 1]u8 = undefined;
    debug.zigErrorReturnedByMain(&buf, @errorName(any_error));
    sys.exit(2);
}
pub noinline fn callMain(stack_addr: u64) noreturn {
    @setAlignStack(16);
    if (@hasDecl(builtin.root, "main")) {
        const Main: type = @TypeOf(builtin.root.main);
        const main: Main = builtin.root.main;
        const Type: type = @TypeOf(@typeInfo(Main));
        const main_type_info: Type = @typeInfo(Main);
        const main_return_type: type = main_type_info.Fn.return_type.?;
        const main_return_type_info: Type = @typeInfo(main_return_type);
        const params = blk_0: {
            if (main_type_info.Fn.args.len == 0) {
                break :blk_0 .{};
            }
            if (main_type_info.Fn.args.len == 1) {
                const args_len: u64 = @intToPtr(*u64, stack_addr).*;
                const args_addr: u64 = stack_addr + 8;
                const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
                break :blk_0 .{args[0..args_len]};
            }
            if (main_type_info.Fn.args.len == 2) {
                const args_len: u64 = @intToPtr(*u64, stack_addr).*;
                const args_addr: u64 = stack_addr + 8;
                const vars_addr: u64 = stack_addr + 16 + (args_len * 8);
                const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
                const vars: [*][*:0]u8 = @intToPtr([*][*:0]u8, vars_addr);
                const vars_len: u64 = blk_1: {
                    var len: u64 = 0;
                    while (@ptrToInt(vars[len]) != 0) len += 1;
                    break :blk_1 len;
                };
                break :blk_0 .{ args[0..args_len], vars[0..vars_len] };
            }
            if (main_type_info.Fn.args.len == 3) {
                const auxv_type: type = main_type_info.Fn.args[2].arg_type.?;
                const args_len: u64 = @intToPtr(*u64, stack_addr).*;
                const args_addr: u64 = stack_addr + 8;
                const vars_addr: u64 = args_addr + 8 + (args_len * 8);
                const args: [*][*:0]u8 = @intToPtr([*][*:0]u8, args_addr);
                const vars: [*][*:0]u8 = @intToPtr([*][*:0]u8, vars_addr);
                const vars_len: u64 = blk_1: {
                    var len: u64 = 0;
                    while (@ptrToInt(vars[len]) != 0) len += 1;
                    break :blk_1 len;
                };
                const auxv_addr: u64 = vars_addr + 8 + (vars_len * 8);
                const auxv: auxv_type = @intToPtr(auxv_type, auxv_addr);
                break :blk_0 .{ args[0..args_len], vars[0..vars_len], auxv };
            }
        };
        if (@hasDecl(builtin.root, "enableExceptionHandlers")) {
            builtin.root.enableExceptionHandlers();
        }
        if (main_return_type == void) {
            @call(.{ .modifier = .always_inline }, main, params);
            sys.exit(0);
        }
        if (main_return_type == u8) {
            sys.exit(@call(.{ .modifier = .always_inline }, main, params));
        }
        if (main_return_type_info.ErrorUnion.payload == void) {
            if (@call(.{ .modifier = .always_inline }, main, params)) {
                sys.exit(0);
            } else |err| {
                @setCold(true);
                exitWithError(err);
                sys.exit(@intCast(u8, @errorToInt(err)));
            }
        }
        if (main_return_type_info.ErrorUnion.payload == u8) {
            if (@call(.{ .modifier = .always_inline }, builtin.root.main, params)) |rc| {
                sys.exit(rc);
            } else |err| {
                @setCold(true);
                exitWithError(err);
                sys.exit(@intCast(u8, @errorToInt(err)));
            }
        }
    } else if (builtin.zig.output_mode == .Exe) {
        @compileError("main not defined in source root");
    }
    unreachable;
}

pub noinline fn callClone(comptime spec: CloneSpec, stack_addr: u64, result_ptr: anytype, comptime function: anytype, args: anytype) spec.Unwrapped(.clone3) {
    const Fn: type = @TypeOf(function);
    const Return = meta.Return(function);
    const cl_args: CloneArgs = spec.args(stack_addr);
    const cl_args_addr: u64 = @ptrToInt(&cl_args);
    const cl_args_size: u64 = @sizeOf(CloneArgs);
    const cl_sysno: u64 = @enumToInt(sys.Function.clone3);
    const ret_off: u64 = 0;
    const fn_off: u64 = 8;
    const args_off: u64 = 16;
    @intToPtr(**const Fn, stack_addr + fn_off).* = &function;
    @intToPtr(*Args(Fn), stack_addr + args_off).* = args;
    if (@TypeOf(result_ptr) != void) {
        @intToPtr(**Return, stack_addr + ret_off).* = result_ptr;
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
        if (comptime @TypeOf(result_ptr) != void) {
            @intToPtr(**Return, tl_stack_addr + ret_off).*.* = @call(
                .{ .modifier = .never_inline },
                @intToPtr(**Fn, tl_stack_addr + fn_off).*,
                @intToPtr(*Args(Fn), tl_stack_addr + args_off).*,
            );
        } else {
            @call(
                .{ .modifier = .never_inline },
                @intToPtr(**Fn, tl_stack_addr + fn_off).*,
                @intToPtr(*Args(Fn), tl_stack_addr + args_off).*,
            );
        }
        asm volatile (
            \\movq  $60,    %rax
            \\movq  $0,     %rdi
            \\syscall
            ::: "rax", "rdi");
        unreachable;
    }
    if (spec.errors) |errors| {
        if (rc < 0) return sys.zigError(errors, rc);
    }
    if (spec.return_type == void) {
        return;
    }
    if (spec.return_type != noreturn) {
        return @intCast(spec.return_type, rc);
    }
    unreachable;
}
fn Args(comptime Fn: type) type {
    var fields: []const meta.StructField = meta.empty;
    inline for (@typeInfo(Fn).Fn.args) |arg, i| {
        fields = fields ++ meta.parcel(meta.structField(arg.arg_type.?, builtin.fmt.u8(i).readAll(), null));
    }
    return @Type(meta.simpleTuple(fields));
}
pub fn auxiliaryValue(auxv: *const anyopaque, comptime tag: AuxiliaryVectorEntry) ?u64 {
    var addr: u64 = @ptrToInt(auxv);
    while (@intToPtr(*u64, addr).* != 0) : (addr += 16) {
        if (@enumToInt(tag) == @intToPtr(*u64, addr).*) {
            return @intToPtr(*u64, addr + 8).*;
        }
    }
    return null;
}
const debug = opaque {
    const about_error_s: []const u8 = "error:          ";
    const about_fork_0_s: []const u8 = "fork:           ";
    const about_fork_1_s: []const u8 = "fork-error:     ";
    const about_wait_0_s: []const u8 = "wait:           ";
    const about_wait_1_s: []const u8 = "wait-error:     ";
    const about_execve_0_s: []const u8 = "execve:         ";
    const about_execve_1_s: []const u8 = "execve-error:   ";
    const about_execveat_1_s: []const u8 = "execveat-error: ";

    fn write(buf: []u8, ss: []const []const u8) u64 {
        var len: u64 = 0;
        for (ss) |s| {
            for (s) |c, i| buf[len + i] = c;
            len += s.len;
        }
        return len;
    }
    fn print(buf: []u8, ss: []const []const u8) void {
        sys.noexcept.write(2, @ptrToInt(buf.ptr), write(buf, ss));
    }
    fn writeExecutablePathname(buf: []u8) u64 {
        const rc: i64 = sys.noexcept.readlink(
            @ptrToInt("/proc/self/exe"),
            @ptrToInt(buf.ptr),
            buf.len,
        );
        if (rc < 0) {
            return ~@as(u64, 0);
        } else {
            return @intCast(u64, rc);
        }
    }

    fn zigErrorReturnedByMain(buf: []u8, symbol: []const u8) void {
        var len: u64 = 0;
        for (about_error_s) |c, i| buf[len + i] = c;
        len +%= about_error_s.len;
        len +%= writeExecutablePathname(buf[len..]);
        len +%= write(buf[len..], &[_][]const u8{ " (", symbol, ")\n" });
        sys.noexcept.write(2, @ptrToInt(buf.ptr), len);
    }
    fn exceptionFaultAtAddress(symbol: []const u8, fault_addr: u64) void {
        var buf: [4096]u8 = undefined;
        print(&buf, &[_][]const u8{ symbol, " at address ", builtin.fmt.ux64(fault_addr).readAll(), "\n" });
    }

    fn forkError(fork_error: anytype) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        print(&buf, &[_][]const u8{ about_fork_1_s, " (", @errorName(fork_error), ")\n" });
    }
    // TODO: Report more information, such as pid, idtype, conditions
    fn waitError(wait_error: anytype) void {
        var buf: [16 + 32 + 512]u8 = undefined;
        print(&buf, [_][]const u8{ about_wait_1_s, " (", @errorName(wait_error), ")\n" });
    }
    fn strlen(s: [*:0]const u8) u64 {
        var len: u64 = 0;
        while (s[len] != 0) len += 1;
        return len;
    }
    // Try to make these two less original
    pub fn executeError(exec_error: anytype, filename: [:0]const u8, args: []const [*:0]const u8) void {
        const max_len: u64 = 4096 + 128;
        var buf: [max_len]u8 = undefined;
        var len: u64 = 0;
        for ([_][]const u8{ about_execve_1_s, "(", @errorName(exec_error), ")", filename }) |s| {
            for (s) |c, i| buf[len + i] = c;
            len += s.len;
        }
        buf[len] = ' ';
        len += 1;
        var argc: u16 = @intCast(u16, args.len);
        var i: u16 = 0;
        while (i != argc) : (i += 1) {
            const arg_len: u64 = strlen(args[i]);
            if (len + arg_len >= max_len - 37) {
                break;
            }
            for (args[i][0..arg_len]) |c, j| buf[len + j] = c;
            len += arg_len;
            buf[len] = ' ';
            len += 1;
        }
        if (argc != i) {
            for ([_][]const u8{ " ... and ", builtin.fmt.ud64(argc - i).readAll(), " more args ... \n" }) |s| {
                for (s) |c, j| buf[len + j] = c;
                len += s.len;
            }
        } else {
            buf[len] = '\n';
            len += 1;
        }
        sys.noexcept.write(2, @ptrToInt(&buf), len);
    }
    pub fn executeNotice(filename: [:0]const u8, args: []const [*:0]const u8) void {
        var buf: [4096 + 128]u8 = undefined;
        var len: u64 = 0;
        for ([_][]const u8{ about_execve_0_s, filename }) |s| {
            for (s) |c, i| buf[len + i] = c;
            len += s.len;
        }
        buf[len] = ' ';
        len += 1;
        var argc: u16 = @intCast(u16, args.len);
        var i: u16 = 0;
        while (i != argc) : (i += 1) {
            const arg_len: u64 = strlen(args[i]);
            if (len + arg_len >= buf.len - 37) {
                break;
            }
            for (args[i][0..arg_len]) |c, j| buf[len + j] = c;
            len += arg_len;
            buf[len] = ' ';
            len += 1;
        }
        if (argc != i) {
            for ([_][]const u8{ " ... and ", builtin.fmt.ud64(argc - i).readAll(), " more args ... \n" }) |s| {
                for (s) |c, j| buf[len + j] = c;
                len += s.len;
            }
        } else {
            buf[len] = '\n';
            len += 1;
        }
        sys.noexcept.write(2, @ptrToInt(&buf), len);
    }
};
