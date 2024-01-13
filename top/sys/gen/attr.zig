const zl = @import("../../../zig_lib.zig");
const types = @import("types.zig");
pub const cpu_arch = archs[archs.len - 2];
pub const archs: []const types.Syscall = &.{ .{
    .arch = .arc,
    .syscall = "trap0",
    .sysno = "r8",
    .ret = "r0",
    .regs = &.{ "r0", "r1", "r2", "r3", "r4", "r5" },
}, .{
    .arch = .aarch64,
    .syscall = "svc #0",
    .sysno = "w8",
    .ret = "x0",
    .ret2 = "x1",
    .regs = &.{ "x0", "x1", "x2", "x3", "x4", "x5" },
}, .{
    .arch = .x86,
    .syscall = "int $0x80",
    .sysno = "eax",
    .ret = "eax",
    .ret2 = "edx",
    .regs = &.{ "ebx", "ecx", "edx", "esi", "edi", "ebp" },
}, .{
    .arch = .m68k,
    .syscall = "trap #0",
    .sysno = "d0",
    .ret = "d0",
    .regs = &.{ "d1", "d2", "d3", "d4", "d5", "a0" },
}, .{
    .arch = .mips64,
    .syscall = "syscall",
    .sysno = "v0",
    .ret = "v0",
    .ret2 = "v1",
    .err = "a3",
    .regs = &.{ "a0", "a1", "a2", "a3" },
}, .{
    .arch = .powerpc,
    .syscall = "sc",
    .sysno = "r0",
    .ret = "r3",
    .err = "r0",
    .regs = &.{ "r3", "r4", "r5", "r6", "r7", "r8" },
}, .{
    .arch = .powerpc64,
    .syscall = "sc",
    .sysno = "r0",
    .ret = "r3",
    .err = "cr0.SO",
    .regs = &.{ "r3", "r4", "r5", "r6", "r7", "r8" },
}, .{
    .arch = .riscv32,
    .syscall = "ecall",
    .sysno = "a7",
    .ret = "a0",
    .ret2 = "a1",
    .regs = &.{ "a0", "a1", "a2", "a3", "a4", "a5" },
}, .{
    .arch = .riscv64,
    .syscall = "ecall",
    .sysno = "a7",
    .ret = "a0",
    .ret2 = "a1",
    .regs = &.{ "a0", "a1", "a2", "a3", "a4", "a5" },
}, .{
    .arch = .s390x,
    .syscall = "svc 0",
    .sysno = "r1",
    .ret = "r2",
    .ret2 = "r3",
    .regs = &.{ "r2", "r3", "r4", "r5", "r6", "r7" },
}, .{
    .arch = .sparc,
    .syscall = "t 0x10",
    .sysno = "g1",
    .ret = "o0",
    .ret2 = "o1",
    .err = "psr/csr",
    .regs = &.{ "o0", "o1", "o2", "o3", "o4", "o5" },
}, .{
    .arch = .sparc64,
    .syscall = "t 0x6d",
    .sysno = "g1",
    .ret = "o0",
    .ret2 = "o1",
    .err = "psr/csr",
    .regs = &.{ "o0", "o1", "o2", "o3", "o4", "o5" },
}, .{
    .arch = .x86_64,
    .syscall = "syscall",
    .sysno = "rax",
    .ret = "rax",
    .ret2 = "rdx",
    .regs = &.{ "rdi", "rsi", "rdx", "r10", "r8", "r9" },
    .clobbers = &.{ "rcx", "r11" },
}, .{
    .arch = .xtensa,
    .syscall = "syscall",
    .sysno = "a2",
    .ret = "a2",
    .regs = &.{ "a6", "a3", "a4", "a5", "a8", "a9" },
} };
const ret_arg: *const types.Argument = &.{ .name = "ret", .type = td(isize) };
const addr_arg: *const types.Argument = &.{ .name = "addr", .type = td(usize) };
const len_arg: *const types.Argument = &.{ .name = "len", .type = td(usize) };
const off_arg: *const types.Argument = &.{ .name = "off", .type = td(usize) };
const old_addr_arg: *const types.Argument = &.{ .name = "old_addr", .type = td(usize) };
const old_len_arg: *const types.Argument = &.{ .name = "old_len", .type = td(usize) };
const new_addr_arg: *const types.Argument = &.{ .name = "new_addr", .type = td(usize) };
const new_len_arg: *const types.Argument = &.{ .name = "new_len", .type = td(usize) };
const fd_arg: *const types.Argument = &.{ .name = "fd", .type = td(usize) };
const dir_fd_arg: *const types.Argument = &.{ .name = "dir_fd", .type = td(usize) };
const src_fd_arg: *const types.Argument = &.{ .name = "src_fd", .type = td(usize) };
const dest_fd_arg: *const types.Argument = &.{ .name = "dest_fd", .type = td(usize) };
const mmap_prot_arg: *const types.Argument = &.{ .name = "prot", .type = td(zl.sys.flags.MemProt) };
const mmap_flags_arg: *const types.Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemMap) };
const mremap_flags_arg: *const types.Argument = &.{ .name = "flags", .type = td(zl.sys.flags.Remap) };
const madvise_advice_arg: *const types.Argument = &.{ .name = "advice", .type = td(zl.sys.flags.MAdvise) };
const memfd_flags_args: *const types.Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemFd) };
const msync_flags: *const types.Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemSync) };
const at_flags_arg: *const types.Argument = &.{ .name = "at", .type = td(zl.sys.flags.At) };
const access_at_flags_arg: *const types.Argument = &.{ .name = "at", .type = td(zl.sys.flags.AtAccess) };
const statx_at_flags_arg: *const types.Argument = &.{ .name = "at", .type = td(zl.sys.flags.AtStatX) };
const name_arg: *const types.Argument = &.{
    .name = "name",
    .type = td([:0]const u8),
    .value = types.Argument.writeValueSlicePtr,
};
const pathname_arg: *const types.Argument = &.{
    .name = "pathname",
    .type = td([:0]const u8),
    .value = types.Argument.writeValueSlicePtr,
};
const exec_args_arg: *const types.Argument = &.{
    .name = "args",
    .type = td([]const [*:0]const u8),
    .value = types.Argument.writeValueSlicePtr,
};
const exec_vars_arg: *const types.Argument = &.{
    .name = "vars",
    .type = td([]const [*:0]const u8),
    .value = types.Argument.writeValueSlicePtr,
};
const write_buf_arg: *const types.Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]write_spec.child_type" } },
    .value = types.Argument.writeValueSlicePtr,
};
const write_buf_arg_len: *const types.Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]write_spec.child_type" } },
    .value = types.Argument.writeValueSliceLen,
};
const read_buf_arg: *const types.Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]const read_spec.child_type" } },
    .value = types.Argument.writeValueSlicePtr,
};
const read_buf_arg_len: *const types.Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]const read_spec.child_type" } },
    .value = types.Argument.writeValueSliceLen,
};
const acq_err_fault = .{ .Attempt = false, .Acquire = true, .Success = false, .Release = false, .Fault = true, .Error = true };
const rel_err_fault = .{ .Attempt = false, .Acquire = false, .Success = false, .Release = true, .Fault = true, .Error = true };
pub const mem: []const types.Fn = &.{
    .{
        .name = "map",
        .tag = .mmap,
        .args = &.{ mmap_prot_arg, mmap_flags_arg, addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
            .{ .arg = mmap_prot_arg },
            .{ .arg = mmap_flags_arg },
            .{ .imm = -1 }, // fd
            .{ .imm = 0 }, // offset
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "unmap",
        .tag = .munmap,
        .args = &.{ addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
        },
        .detail = .{ .logging = rel_err_fault },
    },
    .{
        .name = "remap",
        .tag = .mremap,
        .args = &.{ mremap_flags_arg, old_addr_arg, old_len_arg, new_addr_arg, new_len_arg },
        .regs = &.{
            .{ .arg = old_addr_arg },
            .{ .arg = old_len_arg },
            .{ .arg = new_len_arg },
            .{ .arg = mremap_flags_arg },
            .{ .arg = new_addr_arg },
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "protect",
        .tag = .mprotect,
        .args = &.{ mmap_prot_arg, addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
            .{ .arg = mmap_prot_arg },
        },
    },
    .{
        .name = "advise",
        .tag = .madvise,
        .args = &.{ madvise_advice_arg, addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
            .{ .arg = madvise_advice_arg },
        },
    },
    .{
        .name = "fd",
        .tag = .memfd_create,
        .args = &.{ memfd_flags_args, name_arg },
        .regs = &.{
            .{ .arg = name_arg },
            .{ .arg = memfd_flags_args },
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "sync",
        .tag = .msync,
        .args = &.{ msync_flags, addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
            .{ .arg = msync_flags },
        },
    },
};
pub const file: []const types.Fn = &.{
    .{
        .name = "map",
        .tag = .mmap,
        .args = &.{ mmap_prot_arg, mmap_flags_arg, fd_arg, off_arg, addr_arg, len_arg },
        .regs = &.{
            .{ .arg = addr_arg },
            .{ .arg = len_arg },
            .{ .arg = mmap_prot_arg },
            .{ .arg = mmap_flags_arg },
            .{ .arg = fd_arg },
            .{ .arg = off_arg },
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{ //extern fn execPath(pathname: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) void;
        .name = "execPath",
        .tag = .execve,
        .args = &.{ pathname_arg, exec_args_arg, exec_vars_arg },
        .regs = &.{
            .{ .arg = pathname_arg },
            .{ .arg = exec_args_arg },
            .{ .arg = exec_vars_arg },
        },
    },
    .{ //extern fn exec(fd: usize, args: exec_spec.args_type, vars: exec_spec.vars_type) void;
        .name = "exec",
        .tag = .execveat,
        .args = &.{ fd_arg, exec_args_arg, exec_vars_arg },
        .regs = &.{
            .{ .arg = fd_arg },
            .{ .imm = 0 },
            .{ .arg = exec_args_arg },
            .{ .arg = exec_vars_arg },
            .{ .imm = 0 },
        },
    },
    .{ //extern fn execAt(flags: sys.flags.At, dir_fd: usize, name: [:0]const u8, args: exec_spec.args_type, vars: exec_spec.vars_type) void;
        .name = "execAt",
        .tag = .execveat,
        .args = &.{ at_flags_arg, dir_fd_arg, name_arg, exec_args_arg, exec_vars_arg },
    },
    .{ //extern fn read(fd: usize, read_buf: []read_spec.child) void;
        .name = "read",
        .tag = .read,
        .args = &.{ fd_arg, read_buf_arg },
        .regs = &.{
            .{ .arg = fd_arg },
            .{ .arg = read_buf_arg },
            .{ .arg = read_buf_arg_len },
        },
        .detail = .{
            .notice_args = &.{ fd_arg, ret_arg },
            .error_args = &.{fd_arg},
        },
    },
    .{ //extern fn write(fd: usize, write_buf: []const write_spec.child) void;
        .name = "write",
        .tag = .write,
        .args = &.{ fd_arg, write_buf_arg },
        .regs = &.{
            .{ .arg = fd_arg },
            .{ .arg = write_buf_arg },
            .{ .arg = write_buf_arg_len },
        },
    },
    .{
        .name = "read2",
        .tag = .preadv2,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.ReadWrite) },
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "read_buf", .type = td([]const zl.mem.Vector) },
            &.{ .name = "offset", .type = td(usize) },
        },
    },
    .{
        .name = "write2",
        .tag = .pwritev2,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.ReadWrite) },
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "write_buf", .type = td([]const zl.mem.Vector) },
            &.{ .name = "offset", .type = td(usize) },
        },
    },
    .{
        .name = "open",
        .tag = .open,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.Open) },
            &.{ .name = "pathname", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "openAt",
        .tag = .openat,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.Open) },
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "socket",
        .tag = .socket,
        .args = &.{
            &.{ .name = "domain", .type = td(zl.file.Socket.Domain) },
            &.{ .name = "flags", .type = td(zl.file.Flags.Socket) },
            &.{ .name = "protocol", .type = td(zl.file.Socket.Protocol) },
        },
    },
    .{
        .name = "socketPair",
        .tag = .socketpair,
        .args = &.{
            &.{ .name = "domain", .type = td(zl.file.Socket.Domain) },
            &.{ .name = "flags", .type = td(zl.file.Flags.Socket) },
            &.{ .name = "fds", .type = td(*[2]u32) },
        },
    },
    .{
        .name = "listen",
        .tag = .listen,
        .args = &.{
            &.{ .name = "sock_fd", .type = td(usize) },
            &.{ .name = "backlog", .type = td(u64) },
        },
    },
    .{
        .name = "bind",
        .tag = .bind,
        .args = &.{
            &.{ .name = "sock_fd", .type = td(usize) },
            &.{ .name = "addr", .type = td(*zl.file.Socket.Address) },
            &.{ .name = "addrlen", .type = td(u32) },
        },
    },
    .{
        .name = "accept",
        .tag = .accept,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "addr", .type = td(*zl.file.Socket.Address) },
            &.{ .name = "addrlen", .type = td(*u32) },
        },
    },
    .{
        .name = "connect",
        .tag = .connect,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "addr", .type = td(*const zl.file.Socket.Address) },
            &.{ .name = "addrlen", .type = td(u64) },
        },
    },
    .{
        .name = "sendTo",
        .tag = .sendto,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "buf", .type = td([]u8) },
            &.{ .name = "flags", .type = td(u32) },
            &.{ .name = "addr", .type = td(*zl.file.Socket.Address) },
            &.{ .name = "addrlen", .type = td(u32) },
        },
    },
    .{
        .name = "receiveFrom",
        .tag = .recvfrom,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "buf", .type = td([]u8) },
            &.{ .name = "flags", .type = td(u32) },
            &.{ .name = "addr", .type = td(*zl.file.Socket.Address) },
            &.{ .name = "addrlen", .type = td(*u32) },
        },
    },
    .{
        .name = "shutdown",
        .tag = .shutdown,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "how", .type = td(zl.file.Shutdown) },
        },
    },
    .{
        .name = "path",
        .tag = .open,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.file.Flags.Open) },
            &.{ .name = "pathname", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "pathAt",
        .tag = .openat,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.file.Flags.Open) },
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "makePathAt",
        .tag = .mkdir,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "makePath",
        .tag = .mkdir,
        .args = &.{
            &.{ .name = "pathname", .type = td([]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "create",
        .tag = .open,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.Create) },
            &.{ .name = "pathname", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "createAt",
        .tag = .openat,
        .args = &.{
            &.{ .name = "flags", .type = td(zl.sys.flags.Create) },
            &.{ .name = "at", .type = td(zl.sys.flags.At) },
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "close",
        .tag = .close,
        .args = &.{&.{ .name = "fd", .type = td(usize) }},
    },
    .{
        .name = "makeDir",
        .tag = .mkdir,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "makeDirAt",
        .tag = .mkdirat,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
        },
    },
    .{
        .name = "getDirectoryEntries",
        .tag = .getdents64,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "stream_buf", .type = td([]u8) },
        },
    },
    .{
        .name = "makeNode",
        .tag = .mknod,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
            &.{ .name = "dev", .type = td(zl.file.Device) },
        },
    },
    .{
        .name = "makeNodeAt",
        .tag = .mknodat,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "file_mode", .type = td(zl.file.Mode) },
            &.{ .name = "dev", .type = td(zl.file.Device) },
        },
    },
    .{
        .name = "changeCwd",
        .tag = .chdir,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "getCwd",
        .tag = .getcwd,
        .args = &.{
            &.{ .name = "buf", .type = td([]u8) },
        },
    },
    .{
        .name = "readLink",
        .tag = .readlink,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
            &.{ .name = "buf", .type = td([]u8) },
        },
    },
    .{
        .name = "readLinkAt",
        .tag = .readlinkat,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "buf", .type = td([]u8) },
        },
    },
    .{
        .name = "unlink",
        .tag = .unlink,
        .args = &.{&.{ .name = "pathname", .type = td([:0]const u8) }},
    },
    .{
        .name = "unlinkAt",
        .tag = .unlinkat,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "removeDir",
        .tag = .rmdir,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
        },
    },
    .{
        .name = "pathStatus",
        .tag = .stat,
        .args = &.{
            &.{ .name = "pathname", .type = td([:0]const u8) },
            &.{ .name = "st", .type = td(*zl.file.Status) },
        },
    },
    .{
        .name = "setTimesAt",
        .tag = .futimesat,
        .args = &.{
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "times", .type = td(?*const [2]zl.time.TimeSpec) },
        },
    },
    .{
        .name = "status",
        .tag = .fstat,
        .args = &.{
            &.{ .name = "fd", .type = td(usize) },
            &.{ .name = "st", .type = td(*zl.file.Status) },
        },
    },
    .{
        .name = "statusAt",
        .tag = .newfstatat,
        .args = &.{
            &.{ .name = "at", .type = td(zl.sys.flags.At) },
            &.{ .name = "dir_fd", .type = td(usize) },
            &.{ .name = "name", .type = td([:0]const u8) },
            &.{ .name = "st", .type = td(*zl.file.Status) },
        },
    },
};
pub const proc: []const types.Fn = &.{};
inline fn td(comptime T: type) types.Type {
    comptime {
        switch (@typeInfo(T)) {
            else => return types.Type.init(T),
            .Pointer => |pointer_info| {
                const decl_spec: []const u8 = zl.fmt.typeDeclSpecifier(@typeInfo(T));
                return .{ .type_ref = .{
                    .spec = decl_spec,
                    .type = &td(pointer_info.child),
                } };
            },
            .Struct, .Enum, .Opaque, .Union => {
                return .{ .type_decl = .{ .name = @typeName(T)["build_root.top.".len..] } };
            },
        }
    }
}
