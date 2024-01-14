const sys = @import("../sys.zig");
const proc = @import("../proc.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const spec = struct {};
pub const MapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mmap.errors.all },
    logging: debug.Logging.AcquireErrorFault = .{},
    return_type: type = void,
};
pub fn map(
    comptime map_spec: MapSpec,
    prot: sys.flags.MemProt,
    flags: sys.flags.MemMap,
    fd: usize,
    off: usize,
    addr: usize,
    len: usize,
) sys.ErrorUnion(map_spec.errors, map_spec.return_type) {
    const logging: debug.Logging.AcquireErrorFault = comptime map_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #mmap
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.mmap)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (prot),
          [_] "{r10}" (flags),
          [_] "{r8}" (fd),
          [_] "{r9}" (off),
        : "memory", "rcx", "r11"
    );
    if (map_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.throw, ret) catch |map_error| {
            if (logging.Error) {
                about.aboutProtFlagsFdOffAddrLenError(about.map_s, @errorName(map_error), prot, flags, fd, off, addr, len);
            }
            return map_error;
        };
    }
    if (map_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.abort, ret) catch |map_error| {
            if (logging.Fault) {
                about.aboutProtFlagsFdOffAddrLenError(about.map_s, @errorName(map_error), prot, flags, fd, off, addr, len);
            }
            proc.exitError(map_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutProtFlagsFdOffAddrLenNotice(about.map_s, prot, flags, fd, off, addr, len);
    }
    if (map_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const ExecPathSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.execve.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn execPath(
    comptime execPath_spec: ExecPathSpec,
    pathname: [:0]const u8,
    args: []const [*:0]const u8,
    vars: []const [*:0]const u8,
) sys.ErrorUnion(execPath_spec.errors, execPath_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime execPath_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #execve
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.execve)),
          [_] "{rdi}" (pathname.ptr),
          [_] "{rsi}" (args.ptr),
          [_] "{rdx}" (vars.ptr),
        : "memory", "rcx", "r11"
    );
    if (execPath_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, execPath_spec.errors.throw, ret) catch |execPath_error| {
            if (logging.Error) {
                about.aboutPathnameArgsVarsError(about.execPath_s, @errorName(execPath_error), pathname, args, vars);
            }
            return execPath_error;
        };
    }
    if (execPath_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, execPath_spec.errors.abort, ret) catch |execPath_error| {
            if (logging.Fault) {
                about.aboutPathnameArgsVarsError(about.execPath_s, @errorName(execPath_error), pathname, args, vars);
            }
            proc.exitError(execPath_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutPathnameArgsVarsNotice(about.execPath_s, pathname, args, vars);
    }
    if (execPath_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const ExecSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.execveat.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn exec(
    comptime exec_spec: ExecSpec,
    fd: usize,
    args: []const [*:0]const u8,
    vars: []const [*:0]const u8,
) sys.ErrorUnion(exec_spec.errors, exec_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime exec_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #execveat
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.execveat)),
          [_] "{rdi}" (fd),
          [_] "{rsi}" (0),
          [_] "{rdx}" (args.ptr),
          [_] "{r10}" (vars.ptr),
          [_] "{r8}" (0),
        : "memory", "rcx", "r11"
    );
    if (exec_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, exec_spec.errors.throw, ret) catch |exec_error| {
            if (logging.Error) {
                about.aboutFdArgsVarsError(about.exec_s, @errorName(exec_error), fd, args, vars);
            }
            return exec_error;
        };
    }
    if (exec_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, exec_spec.errors.abort, ret) catch |exec_error| {
            if (logging.Fault) {
                about.aboutFdArgsVarsError(about.exec_s, @errorName(exec_error), fd, args, vars);
            }
            proc.exitError(exec_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutFdArgsVarsNotice(about.exec_s, fd, args, vars);
    }
    if (exec_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const ReadSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.read.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn read(
    comptime read_spec: ReadSpec,
    fd: usize,
    buf: []const read_spec.child_type,
) sys.ErrorUnion(read_spec.errors, read_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime read_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #read
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.read)),
          [_] "{rdi}" (fd),
          [_] "{rsi}" (buf.ptr),
          [_] "{rdx}" (buf.len),
        : "memory", "rcx", "r11"
    );
    if (read_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, read_spec.errors.throw, ret) catch |read_error| {
            if (logging.Error) {
                about.aboutFdError(about.read_s, @errorName(read_error), fd);
            }
            return read_error;
        };
    }
    if (read_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, read_spec.errors.abort, ret) catch |read_error| {
            if (logging.Fault) {
                about.aboutFdError(about.read_s, @errorName(read_error), fd);
            }
            proc.exitError(read_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutFdRetNotice(about.read_s, fd, ret);
    }
    if (read_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const WriteSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.write.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn write(
    comptime write_spec: WriteSpec,
    fd: usize,
    buf: []write_spec.child_type,
) sys.ErrorUnion(write_spec.errors, write_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime write_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #write
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.write)),
          [_] "{rdi}" (fd),
          [_] "{rsi}" (buf.ptr),
          [_] "{rdx}" (buf.len),
        : "memory", "rcx", "r11"
    );
    if (write_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, write_spec.errors.throw, ret) catch |write_error| {
            if (logging.Error) {
                about.aboutFdBufError(about.write_s, @errorName(write_error), fd, buf);
            }
            return write_error;
        };
    }
    if (write_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, write_spec.errors.abort, ret) catch |write_error| {
            if (logging.Fault) {
                about.aboutFdBufError(about.write_s, @errorName(write_error), fd, buf);
            }
            proc.exitError(write_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutFdBufNotice(about.write_s, fd, buf);
    }
    if (write_spec.return_type != void) {
        return @intCast(ret);
    }
}
const about = struct {
    const fmt = @import("../fmt.zig");
    const map_s: fmt.AboutSrc = fmt.about("mmap");
    const execPath_s: fmt.AboutSrc = fmt.about("execve");
    const exec_s: fmt.AboutSrc = fmt.about("execveat");
    const read_s: fmt.AboutSrc = fmt.about("read");
    const write_s: fmt.AboutSrc = fmt.about("write");
    fn aboutProtFlagsFdOffAddrLenNotice(
        about_s: fmt.AboutSrc,
        prot: sys.flags.MemProt,
        flags: sys.flags.MemMap,
        fd: usize,
        off: usize,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..5].* = "prot=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemProt).write(ptr + 5, prot);
        ptr[0..8].* = ", flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemMap).write(ptr + 8, flags);
        ptr[0..5].* = ", fd=".*;
        ptr = fmt.Udsize.write(ptr + 5, fd);
        ptr[0..6].* = ", off=".*;
        ptr = fmt.Udsize.write(ptr + 6, off);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameArgsVarsNotice(
        about_s: fmt.AboutSrc,
        pathname: [:0]const u8,
        args: []const [*:0]const u8,
        vars: []const [*:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..9].* = "pathname=".*;
        ptr = fmt.AnyFormat(.{}, [:0]const u8).write(ptr + 9, pathname);
        ptr[0..7].* = ", args=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, args);
        ptr[0..7].* = ", vars=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, vars);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdArgsVarsNotice(
        about_s: fmt.AboutSrc,
        fd: usize,
        args: []const [*:0]const u8,
        vars: []const [*:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0..7].* = ", args=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, args);
        ptr[0..7].* = ", vars=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, vars);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdRetNotice(
        about_s: fmt.AboutSrc,
        fd: usize,
        ret: isize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0..6].* = ", ret=".*;
        ptr = fmt.AnyFormat(.{}, isize).write(ptr + 6, ret);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdBufNotice(
        about_s: fmt.AboutSrc,
        fd: usize,
        buf: []write_spec.child_type,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0..6].* = ", buf=".*;
        ptr = fmt.AnyFormat(.{}, []write_spec.child_type).write(ptr + 6, buf);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutProtFlagsFdOffAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        prot: sys.flags.MemProt,
        flags: sys.flags.MemMap,
        fd: usize,
        off: usize,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..5].* = "prot=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemProt).write(ptr + 5, prot);
        ptr[0..8].* = ", flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemMap).write(ptr + 8, flags);
        ptr[0..5].* = ", fd=".*;
        ptr = fmt.Udsize.write(ptr + 5, fd);
        ptr[0..6].* = ", off=".*;
        ptr = fmt.Udsize.write(ptr + 6, off);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutPathnameArgsVarsError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        pathname: [:0]const u8,
        args: []const [*:0]const u8,
        vars: []const [*:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..9].* = "pathname=".*;
        ptr = fmt.AnyFormat(.{}, [:0]const u8).write(ptr + 9, pathname);
        ptr[0..7].* = ", args=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, args);
        ptr[0..7].* = ", vars=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, vars);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdArgsVarsError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        fd: usize,
        args: []const [*:0]const u8,
        vars: []const [*:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0..7].* = ", args=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, args);
        ptr[0..7].* = ", vars=".*;
        ptr = fmt.AnyFormat(.{}, []const [*:0]const u8).write(ptr + 7, vars);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        fd: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFdBufError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        fd: usize,
        buf: []write_spec.child_type,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..3].* = "fd=".*;
        ptr = fmt.Udsize.write(ptr + 3, fd);
        ptr[0..6].* = ", buf=".*;
        ptr = fmt.AnyFormat(.{}, []write_spec.child_type).write(ptr + 6, buf);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
};
