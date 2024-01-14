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
          [_] "{r8}" (18446744073709551615),
          [_] "{r9}" (0),
        : "memory", "rcx", "r11"
    );
    if (map_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.throw, ret) catch |map_error| {
            if (logging.Error) {
                about.aboutProtFlagsAddrLenError(about.map_s, @errorName(map_error), prot, flags, addr, len);
            }
            return map_error;
        };
    }
    if (map_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, map_spec.errors.abort, ret) catch |map_error| {
            if (logging.Fault) {
                about.aboutProtFlagsAddrLenError(about.map_s, @errorName(map_error), prot, flags, addr, len);
            }
            proc.exitError(map_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutProtFlagsAddrLenNotice(about.map_s, prot, flags, addr, len);
    }
    if (map_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const UnmapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.munmap.errors.all },
    logging: debug.Logging.ReleaseErrorFault = .{},
    return_type: type = void,
};
pub fn unmap(
    comptime unmap_spec: UnmapSpec,
    addr: usize,
    len: usize,
) sys.ErrorUnion(unmap_spec.errors, unmap_spec.return_type) {
    const logging: debug.Logging.ReleaseErrorFault = comptime unmap_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #munmap
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.munmap)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
        : "memory", "rcx", "r11"
    );
    if (unmap_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, unmap_spec.errors.throw, ret) catch |unmap_error| {
            if (logging.Error) {
                about.aboutAddrLenError(about.unmap_s, @errorName(unmap_error), addr, len);
            }
            return unmap_error;
        };
    }
    if (unmap_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, unmap_spec.errors.abort, ret) catch |unmap_error| {
            if (logging.Fault) {
                about.aboutAddrLenError(about.unmap_s, @errorName(unmap_error), addr, len);
            }
            proc.exitError(unmap_error, 2);
        };
    }
    if (logging.Release) {
        about.aboutAddrLenNotice(about.unmap_s, addr, len);
    }
    if (unmap_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const RemapSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mremap.errors.all },
    logging: debug.Logging.AcquireErrorFault = .{},
    return_type: type = void,
};
pub fn remap(
    comptime remap_spec: RemapSpec,
    flags: sys.flags.Remap,
    old_addr: usize,
    old_len: usize,
    new_addr: usize,
    new_len: usize,
) sys.ErrorUnion(remap_spec.errors, remap_spec.return_type) {
    const logging: debug.Logging.AcquireErrorFault = comptime remap_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #mremap
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.mremap)),
          [_] "{rdi}" (old_addr),
          [_] "{rsi}" (old_len),
          [_] "{rdx}" (new_len),
          [_] "{r10}" (flags),
          [_] "{r8}" (new_addr),
        : "memory", "rcx", "r11"
    );
    if (remap_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, remap_spec.errors.throw, ret) catch |remap_error| {
            if (logging.Error) {
                about.aboutFlagsOldAddrOldLenNewAddrNewLenError(about.remap_s, @errorName(remap_error), flags, old_addr, old_len, new_addr, new_len);
            }
            return remap_error;
        };
    }
    if (remap_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, remap_spec.errors.abort, ret) catch |remap_error| {
            if (logging.Fault) {
                about.aboutFlagsOldAddrOldLenNewAddrNewLenError(about.remap_s, @errorName(remap_error), flags, old_addr, old_len, new_addr, new_len);
            }
            proc.exitError(remap_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutFlagsOldAddrOldLenNewAddrNewLenNotice(about.remap_s, flags, old_addr, old_len, new_addr, new_len);
    }
    if (remap_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const ProtectSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.mprotect.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn protect(
    comptime protect_spec: ProtectSpec,
    prot: sys.flags.MemProt,
    addr: usize,
    len: usize,
) sys.ErrorUnion(protect_spec.errors, protect_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime protect_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #mprotect
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.mprotect)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (prot),
        : "memory", "rcx", "r11"
    );
    if (protect_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, protect_spec.errors.throw, ret) catch |protect_error| {
            if (logging.Error) {
                about.aboutProtAddrLenError(about.protect_s, @errorName(protect_error), prot, addr, len);
            }
            return protect_error;
        };
    }
    if (protect_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, protect_spec.errors.abort, ret) catch |protect_error| {
            if (logging.Fault) {
                about.aboutProtAddrLenError(about.protect_s, @errorName(protect_error), prot, addr, len);
            }
            proc.exitError(protect_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutProtAddrLenNotice(about.protect_s, prot, addr, len);
    }
    if (protect_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const AdviseSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.madvise.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn advise(
    comptime advise_spec: AdviseSpec,
    advice: sys.flags.MAdvise,
    addr: usize,
    len: usize,
) sys.ErrorUnion(advise_spec.errors, advise_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime advise_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #madvise
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.madvise)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (advice),
        : "memory", "rcx", "r11"
    );
    if (advise_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, advise_spec.errors.throw, ret) catch |advise_error| {
            if (logging.Error) {
                about.aboutAdviceAddrLenError(about.advise_s, @errorName(advise_error), advice, addr, len);
            }
            return advise_error;
        };
    }
    if (advise_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, advise_spec.errors.abort, ret) catch |advise_error| {
            if (logging.Fault) {
                about.aboutAdviceAddrLenError(about.advise_s, @errorName(advise_error), advice, addr, len);
            }
            proc.exitError(advise_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutAdviceAddrLenNotice(about.advise_s, advice, addr, len);
    }
    if (advise_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const FdSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.memfd_create.errors.all },
    logging: debug.Logging.AcquireErrorFault = .{},
    return_type: type = void,
};
pub fn fd(
    comptime fd_spec: FdSpec,
    flags: sys.flags.MemFd,
    name: [:0]const u8,
) sys.ErrorUnion(fd_spec.errors, fd_spec.return_type) {
    const logging: debug.Logging.AcquireErrorFault = comptime fd_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #memfd_create
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.memfd_create)),
          [_] "{rdi}" (name.ptr),
          [_] "{rsi}" (flags),
        : "memory", "rcx", "r11"
    );
    if (fd_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, fd_spec.errors.throw, ret) catch |fd_error| {
            if (logging.Error) {
                about.aboutFlagsNameError(about.fd_s, @errorName(fd_error), flags, name);
            }
            return fd_error;
        };
    }
    if (fd_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, fd_spec.errors.abort, ret) catch |fd_error| {
            if (logging.Fault) {
                about.aboutFlagsNameError(about.fd_s, @errorName(fd_error), flags, name);
            }
            proc.exitError(fd_error, 2);
        };
    }
    if (logging.Acquire) {
        about.aboutFlagsNameNotice(about.fd_s, flags, name);
    }
    if (fd_spec.return_type != void) {
        return @intCast(ret);
    }
}
pub const SyncSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = spec.msync.errors.all },
    logging: debug.Logging.SuccessErrorFault = .{},
    return_type: type = void,
};
pub fn sync(
    comptime sync_spec: SyncSpec,
    flags: sys.flags.MemSync,
    addr: usize,
    len: usize,
) sys.ErrorUnion(sync_spec.errors, sync_spec.return_type) {
    const logging: debug.Logging.SuccessErrorFault = comptime sync_spec.logging.override();
    const ret: isize = asm volatile (
        \\syscall #msync
        : [_] "={rax}" (-> isize),
        : [_] "{rax}" (@intFromEnum(sys.Fn.msync)),
          [_] "{rdi}" (addr),
          [_] "{rsi}" (len),
          [_] "{rdx}" (flags),
        : "memory", "rcx", "r11"
    );
    if (sync_spec.errors.throw.len != 0) {
        builtin.throw(sys.ErrorCode, sync_spec.errors.throw, ret) catch |sync_error| {
            if (logging.Error) {
                about.aboutFlagsAddrLenError(about.sync_s, @errorName(sync_error), flags, addr, len);
            }
            return sync_error;
        };
    }
    if (sync_spec.errors.abort.len != 0) {
        builtin.throw(sys.ErrorCode, sync_spec.errors.abort, ret) catch |sync_error| {
            if (logging.Fault) {
                about.aboutFlagsAddrLenError(about.sync_s, @errorName(sync_error), flags, addr, len);
            }
            proc.exitError(sync_error, 2);
        };
    }
    if (logging.Success) {
        about.aboutFlagsAddrLenNotice(about.sync_s, flags, addr, len);
    }
    if (sync_spec.return_type != void) {
        return @intCast(ret);
    }
}
const about = struct {
    const fmt = @import("../fmt.zig");
    const map_s: fmt.AboutSrc = fmt.about("mmap");
    const unmap_s: fmt.AboutSrc = fmt.about("munmap");
    const remap_s: fmt.AboutSrc = fmt.about("mremap");
    const protect_s: fmt.AboutSrc = fmt.about("mprotect");
    const advise_s: fmt.AboutSrc = fmt.about("madvise");
    const fd_s: fmt.AboutSrc = fmt.about("memfd_create");
    const sync_s: fmt.AboutSrc = fmt.about("msync");
    fn aboutProtFlagsAddrLenNotice(
        about_s: fmt.AboutSrc,
        prot: sys.flags.MemProt,
        flags: sys.flags.MemMap,
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
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAddrLenNotice(
        about_s: fmt.AboutSrc,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..5].* = "addr=".*;
        ptr = fmt.Uxsize.write(ptr + 5, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsOldAddrOldLenNewAddrNewLenNotice(
        about_s: fmt.AboutSrc,
        flags: sys.flags.Remap,
        old_addr: usize,
        old_len: usize,
        new_addr: usize,
        new_len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.Remap).write(ptr + 6, flags);
        ptr[0..11].* = ", old_addr=".*;
        ptr = fmt.Udsize.write(ptr + 11, old_addr);
        ptr[0..10].* = ", old_len=".*;
        ptr = fmt.Udsize.write(ptr + 10, old_len);
        ptr[0..11].* = ", new_addr=".*;
        ptr = fmt.Udsize.write(ptr + 11, new_addr);
        ptr[0..10].* = ", new_len=".*;
        ptr = fmt.Udsize.write(ptr + 10, new_len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutProtAddrLenNotice(
        about_s: fmt.AboutSrc,
        prot: sys.flags.MemProt,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..5].* = "prot=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemProt).write(ptr + 5, prot);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAdviceAddrLenNotice(
        about_s: fmt.AboutSrc,
        advice: sys.flags.MAdvise,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..7].* = "advice=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MAdvise).write(ptr + 7, advice);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsNameNotice(
        about_s: fmt.AboutSrc,
        flags: sys.flags.MemFd,
        name: [:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemFd).write(ptr + 6, flags);
        ptr[0..7].* = ", name=".*;
        ptr = fmt.AnyFormat(.{}, [:0]const u8).write(ptr + 7, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsAddrLenNotice(
        about_s: fmt.AboutSrc,
        flags: sys.flags.MemSync,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        buf[0..about_s.len].* = about_s.*;
        var ptr: [*]u8 = buf[about_s.len..];
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemSync).write(ptr + 6, flags);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutProtFlagsAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        prot: sys.flags.MemProt,
        flags: sys.flags.MemMap,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..5].* = "prot=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemProt).write(ptr + 5, prot);
        ptr[0..8].* = ", flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemMap).write(ptr + 8, flags);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..5].* = "addr=".*;
        ptr = fmt.Uxsize.write(ptr + 5, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsOldAddrOldLenNewAddrNewLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        flags: sys.flags.Remap,
        old_addr: usize,
        old_len: usize,
        new_addr: usize,
        new_len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.Remap).write(ptr + 6, flags);
        ptr[0..11].* = ", old_addr=".*;
        ptr = fmt.Udsize.write(ptr + 11, old_addr);
        ptr[0..10].* = ", old_len=".*;
        ptr = fmt.Udsize.write(ptr + 10, old_len);
        ptr[0..11].* = ", new_addr=".*;
        ptr = fmt.Udsize.write(ptr + 11, new_addr);
        ptr[0..10].* = ", new_len=".*;
        ptr = fmt.Udsize.write(ptr + 10, new_len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutProtAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        prot: sys.flags.MemProt,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..5].* = "prot=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemProt).write(ptr + 5, prot);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutAdviceAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        advice: sys.flags.MAdvise,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..7].* = "advice=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MAdvise).write(ptr + 7, advice);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsNameError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        flags: sys.flags.MemFd,
        name: [:0]const u8,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemFd).write(ptr + 6, flags);
        ptr[0..7].* = ", name=".*;
        ptr = fmt.AnyFormat(.{}, [:0]const u8).write(ptr + 7, name);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
    fn aboutFlagsAddrLenError(
        about_s: fmt.AboutSrc,
        error_name: []const u8,
        flags: sys.flags.MemSync,
        addr: usize,
        len: usize,
    ) void {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = debug.about.writeAboutError(&buf, about_s, error_name);
        ptr[0..6].* = "flags=".*;
        ptr = fmt.AnyFormat(.{}, sys.flags.MemSync).write(ptr + 6, flags);
        ptr[0..7].* = ", addr=".*;
        ptr = fmt.Uxsize.write(ptr + 7, addr);
        ptr[0..6].* = ", len=".*;
        ptr = fmt.Udsize.write(ptr + 6, len);
        ptr[0] = '\n';
        debug.write(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)]);
    }
};
