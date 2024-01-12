const zl = @import("../../../zig_lib.zig");
const fmt = zl.fmt;
const debug = zl.debug;
pub usingnamespace zl.start;
const Arch = @TypeOf(@import("builtin").cpu.arch);
const Argument = struct {
    name: []const u8,
    type: Type,
};
const Register = union(enum) {
    arg: *const Argument,
    imm: isize,
};
const Syscall = struct {
    arch: Arch,
    syscall: ?[]const u8 = null,
    sysno: ?[]const u8 = null,
    ret: ?[]const u8 = null,
    ret2: ?[]const u8 = null,
    err: ?[]const u8 = null,
    regs: []const []const u8 = &.{},
};
const Fn = struct {
    name: []const u8,
    tag: zl.sys.Fn,
    args: []const *const Argument,
    regs: []const Register,
    return_ty: ?Type = null,
    detail: Detail = .{},
};
const Detail = struct {
    spec_name: ?[]const u8 = null,
    error_name: ?[]const u8 = null,
    notice_fn_name: ?[]const u8 = null,
    error_fn_name: ?[]const u8 = null,
    about_str_name: ?[]const u8 = null,
    error_codes_name: ?[]const u8 = null,
    spec_ty_name: ?[]const u8 = null,
    return_ty: ?Type = null,
    logging: zl.debug.Logging.Default = .{
        .Attempt = false,
        .Success = true,
        .Acquire = false,
        .Release = false,
        .Error = true,
        .Fault = true,
    },
};
pub const Type = fmt.GenericTypeDescrFormat(.{
    .default_field_values = .fast,
    .option_5 = true,
    .tokens = .{
        .lbrace = "{\n",
        .equal = "=",
        .rbrace = "}",
        .next = ",\n",
        .colon = ":",
        .indent = "",
    },
});
inline fn td(comptime T: type) Type {
    comptime {
        switch (T) {
            void, usize, isize, [:0]const u8, []const u8, [*]u8 => return Type.init(T),
            else => switch (@typeInfo(T)) {
                .Int, .Float => return Type.init(T),
                else => return .{ .type_decl = .{ .name = @typeName(T)["build_root.top.".len..] } },
            },
        }
    }
}
fn writeLoggingType(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    buf[0..14].* = "debug.Logging.".*;
    var ptr: [*]u8 = buf[14..];
    inline for (@typeInfo(debug.Logging.Default).Struct.fields) |field| {
        if (@field(fn_spec.detail.logging, field.name)) {
            ptr[0..field.name.len].* = field.name[0..field.name.len].*;
            ptr += field.name.len;
        }
    }
    return ptr;
}
fn writeLogging(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "const logging:");
    ptr = writeLoggingType(ptr, fn_spec);
    ptr[0..10].* = "=comptime ".*;
    ptr = writeSpecName(ptr + 10, fn_spec);
    return zl.fmt.strcpyEqu(ptr, ".logging.override();\n");
}
fn writeErrorCodesName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.error_codes_name) |error_codes_names| {
        return zl.fmt.strcpyEqu(buf, error_codes_names);
    } else {
        buf[0..14].* = ".{.throw=spec.".*;
        const ptr: [*]u8 = zl.fmt.strcpyEqu(buf + 14, @tagName(fn_spec.tag));
        ptr[0..14].* = ".errors.all},\n".*;
        return ptr + 14;
    }
}
fn writeSpecName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.spec_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_spec");
    }
}
fn writeSpecTypeName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.spec_ty_name) |spec_ty_name| {
        return zl.fmt.strcpyEqu(buf, spec_ty_name);
    } else {
        const ptr: [*]u8 = zl.fmt.writeToTitlecase(buf, fn_spec.name);
        return zl.fmt.strcpyEqu(ptr, "Spec");
    }
}
fn writeErrorName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.error_name) |error_name| {
        return zl.fmt.strcpyEqu(buf, error_name);
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_error");
    }
}
fn writeAboutStrName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.about_str_name) |about_str_name| {
        return zl.fmt.strcpyEqu(buf, about_str_name);
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_s");
    }
}
fn writeErrorFnName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.error_fn_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else {
        var ptr: [*]u8 = buf;
        for (fn_spec.args) |arg| {
            ptr = zl.fmt.writeToTitlecase(ptr, arg.name);
        }
        ptr[0..5].* = "Error".*;
        return ptr + 5;
    }
}
fn writeNoticeFnName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    if (fn_spec.detail.error_fn_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else {
        var ptr: [*]u8 = buf;
        for (fn_spec.args) |arg| {
            ptr = zl.fmt.writeToTitlecase(ptr, arg.name);
        }
        ptr[0..6].* = "Notice".*;
        return ptr + 6;
    }
}
fn writeThrowBlock(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..3].* = "if(".*;
    ptr = writeSpecName(ptr + 3, fn_spec);
    ptr[0..23].* = ".errors.throw.len!=0){\n".*;
    ptr[23..51].* = "builtin.throw(sys.ErrorCode,".*;
    ptr = writeSpecName(ptr + 51, fn_spec);
    ptr[0..24].* = ".errors.throw,ret)catch|".*;
    ptr = writeErrorName(ptr + 24, fn_spec);
    ptr[0..3].* = "|{\n".*;
    ptr += 3;
    if (fn_spec.detail.logging.Error) {
        ptr[0..19].* = "if(logging.Error){\n".*;
        ptr[19..30].* = "about.about".*;
        ptr = writeErrorFnName(ptr + 30, fn_spec);
        ptr[0] = '(';
        ptr[1..7].* = "about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0..12].* = ",@errorName(".*;
        ptr = writeErrorName(ptr + 12, fn_spec);
        ptr[0..2].* = "),".*;
        ptr += 2;
        for (fn_spec.args) |param| {
            ptr = zl.fmt.strcpyEqu(ptr, param.name);
            ptr[0] = ',';
            ptr += 1;
        }
        ptr -= 1;
        ptr[0..3].* = ");\n".*;
        ptr += 3;
        ptr[0..2].* = "}\n".*;
        ptr += 2;
    }
    ptr[0..7].* = "return ".*;
    ptr = writeErrorName(ptr + 7, fn_spec);
    ptr[0..2].* = ";\n".*;
    ptr += 2;
    ptr[0..3].* = "};\n".*;
    ptr += 3;
    ptr[0..2].* = "}\n".*;
    ptr += 2;
    return ptr;
}
fn writeAbortBlock(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..3].* = "if(".*;
    ptr = writeSpecName(ptr + 3, fn_spec);
    ptr[0..23].* = ".errors.abort.len!=0){\n".*;
    ptr[23..51].* = "builtin.throw(sys.ErrorCode,".*;
    ptr = writeSpecName(ptr + 51, fn_spec);
    ptr[0..24].* = ".errors.abort,ret)catch|".*;
    ptr = writeErrorName(ptr + 24, fn_spec);
    ptr[0..3].* = "|{\n".*;
    ptr += 3;
    if (fn_spec.detail.logging.Fault) {
        ptr[0..19].* = "if(logging.Fault){\n".*;
        ptr[19..30].* = "about.about".*;
        ptr = writeErrorFnName(ptr + 30, fn_spec);
        ptr[0] = '(';
        ptr[1..7].* = "about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0..12].* = ",@errorName(".*;
        ptr = writeErrorName(ptr + 12, fn_spec);
        ptr[0..2].* = "),".*;
        ptr += 2;
        for (fn_spec.args) |param| {
            ptr = zl.fmt.strcpyEqu(ptr, param.name);
            ptr[0] = ',';
            ptr += 1;
        }
        ptr -= 1;
        ptr[0..3].* = ");\n".*;
        ptr += 3;
        ptr[0..2].* = "}\n".*;
        ptr += 2;
    }
    ptr[0..15].* = "proc.exitError(".*;
    ptr = writeErrorName(ptr + 15, fn_spec);
    ptr[0..5].* = ",2);\n".*;
    ptr += 5;
    ptr[0..3].* = "};\n".*;
    ptr += 3;
    ptr[0..2].* = "}\n".*;
    ptr += 2;
    return ptr;
}
fn writeNoticeBlock(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    blk: {
        if (fn_spec.detail.logging.Success) {
            ptr[0..21].* = "if(logging.Success){\n".*;
        } else if (fn_spec.detail.logging.Acquire) {
            ptr[0..21].* = "if(logging.Acquire){\n".*;
        } else if (fn_spec.detail.logging.Release) {
            ptr[0..21].* = "if(logging.Release){\n".*;
        } else {
            break :blk;
        }
        ptr[21..32].* = "about.about".*;
        ptr = writeNoticeFnName(ptr + 32, fn_spec);
        ptr[0..7].* = "(about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0] = ',';
        ptr += 1;
        for (fn_spec.args) |param| {
            ptr = zl.fmt.strcpyEqu(ptr, param.name);
            ptr[0] = ',';
            ptr += 1;
        }
        ptr -= 1;
        ptr[0..3].* = ");\n".*;
        ptr += 3;
        ptr[0..2].* = "}\n".*;
        ptr += 2;
    }
    return ptr;
}
fn writeFunctionSignature(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..7].* = "pub fn ".*;
    ptr = zl.fmt.strcpyEqu(ptr + 7, fn_spec.name);
    ptr[0] = '(';
    ptr = zl.fmt.strcpyEqu(ptr + 1, "comptime ");
    ptr = writeSpecName(ptr, fn_spec);
    ptr[0] = ':';
    ptr = writeSpecTypeName(ptr + 1, fn_spec);
    ptr[0] = ',';
    ptr += 1;
    for (fn_spec.args) |arg| {
        ptr = fmt.strcpyEqu(ptr, arg.name);
        ptr[0] = ':';
        ptr = Type.write(ptr + 1, arg.type);
        ptr[0] = ',';
        ptr += 1;
    }
    ptr[0] = ')';
    ptr += 1;
    ptr[0..15].* = "sys.ErrorUnion(".*;
    ptr = writeSpecName(ptr + 15, fn_spec);
    ptr[0..8].* = ".errors,".*;
    ptr = writeSpecName(ptr + 8, fn_spec);
    ptr[0..15].* = ".return_type){\n".*;
    return ptr + 15;
}
fn writeInlineAsm(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..30].* = "const ret:isize=asm volatile (".*;
    ptr += 30;
    ptr[0..11].* = "\\\\syscall #".*;
    ptr = zl.fmt.strcpyEqu(ptr + 11, @tagName(fn_spec.tag));
    ptr[0] = '\n';
    ptr += 1;
    ptr[0..25].* = ":[ret]\"={rax}\"(->isize),\n".*;
    ptr += 25;
    ptr[0..31].* = ":[_]\"{rax}\"(@intFromEnum(sys.Fn".*;
    ptr = zl.fmt.EnumFormat(.{}, zl.sys.Fn).write(ptr + 31, fn_spec.tag);
    ptr[0..4].* = ")),\n".*;
    ptr += 4;
    for (fn_spec.regs, 0..) |reg, argn| {
        ptr[0..5].* = "[_]\"{".*;
        ptr = zl.fmt.strcpyEqu(ptr + 5, cpu_arch.regs[argn]);
        ptr[0..3].* = "}\"(".*;
        switch (reg) {
            .arg => |arg| ptr = zl.fmt.strcpyEqu(ptr + 3, arg.name),
            .imm => |imm| ptr = zl.fmt.Udsize.write(ptr + 3, @bitCast(imm)),
        }
        ptr[0..3].* = "),\n".*;
        ptr += 3;
    }
    ptr[0..25].* = ": \"rcx\", \"r11\", \"memory\"\n".*;
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeReturnType(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    if (fn_spec.detail.return_ty) |return_ty| {
        ptr = Type.write(ptr, return_ty);
    } else {
        ptr = Type.write(ptr, td(void));
    }
    return ptr;
}
fn writeSpecificationType(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    buf[0..10].* = "pub const ".*;
    var ptr: [*]u8 = zl.fmt.writeToTitlecase(buf + 10, fn_spec.name);
    ptr[0..13].* = "Spec=struct{\n".*;
    ptr += 13;
    ptr[0..23].* = "errors:sys.ErrorPolicy=".*;
    ptr = writeErrorCodesName(ptr + 23, fn_spec);
    ptr[0] = '\n';
    ptr[0..8].* = "logging:".*;
    ptr = writeLoggingType(ptr + 8, fn_spec);
    ptr[0..6].* = "=.{},\n".*;
    ptr += 6;
    ptr[0..17].* = "return_type:type=".*;
    ptr = writeReturnType(ptr + 17, fn_spec);
    ptr[0..2].* = ",\n".*;
    ptr += 2;
    ptr[0..3].* = "};\n".*;
    return ptr + 3;
}
fn writeFunctionExit(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "if(");
    ptr = writeSpecName(ptr, fn_spec);
    ptr = zl.fmt.strcpyEqu(ptr, ".return_type!=void){");
    ptr = zl.fmt.strcpyEqu(ptr, "return @intCast(ret);\n");
    ptr = zl.fmt.strcpyEqu(ptr, "}\n");
    ptr[0..2].* = "}\n".*;
    return ptr + 2;
}
const cpu_arch = archs[archs.len - 2];
const archs: []const Syscall = &.{ .{
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
}, .{
    .arch = .xtensa,
    .syscall = "syscall",
    .sysno = "a2",
    .ret = "a2",
    .regs = &.{ "a6", "a3", "a4", "a5", "a8", "a9" },
} };
const addr_arg: Argument = .{ .name = "addr", .type = td(usize) };
const len_arg: Argument = .{ .name = "len", .type = td(usize) };
const old_addr_arg: Argument = .{ .name = "old_addr", .type = td(usize) };
const old_len_arg: Argument = .{ .name = "old_len", .type = td(usize) };
const new_addr_arg: Argument = .{ .name = "new_addr", .type = td(usize) };
const new_len_arg: Argument = .{ .name = "new_len", .type = td(usize) };
const name_arg: Argument = .{ .name = "name", .type = td([:0]const u8) };
const mmap_prot_arg: Argument = .{ .name = "prot", .type = td(zl.sys.flags.MemProt) };
const mmap_flags_arg: Argument = .{ .name = "flags", .type = td(zl.sys.flags.MemMap) };
const mremap_flags_arg: Argument = .{ .name = "flags", .type = td(zl.sys.flags.Remap) };
const madvise_advice_arg: Argument = .{ .name = "advice", .type = td(zl.sys.flags.MAdvise) };
const memfd_create_flags: Argument = .{ .name = "flags", .type = td(zl.sys.flags.MemFd) };
const msync_flags: Argument = .{ .name = "flags", .type = td(zl.sys.flags.MemSync) };

const acq_err_fault = .{ .Attempt = false, .Acquire = true, .Success = false, .Release = false, .Fault = true, .Error = true };
const rel_err_fault = .{ .Attempt = false, .Acquire = false, .Success = false, .Release = true, .Fault = true, .Error = true };

const mem = [_]Fn{
    .{
        .name = "map",
        .tag = .mmap,
        .args = &.{ &mmap_prot_arg, &mmap_flags_arg, &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &mmap_prot_arg },
            .{ .arg = &mmap_flags_arg },
            .{ .imm = -1 }, // fd
            .{ .imm = 0 }, // offset
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "unmap",
        .tag = .munmap,
        .args = &.{ &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
        },
        .detail = .{ .logging = rel_err_fault },
    },
    .{
        .name = "remap",
        .tag = .mremap,
        .args = &.{ &mremap_flags_arg, &old_addr_arg, &old_len_arg, &new_addr_arg, &new_len_arg },
        .regs = &.{
            .{ .arg = &old_addr_arg },
            .{ .arg = &old_len_arg },
            .{ .arg = &new_len_arg },
            .{ .arg = &mremap_flags_arg },
            .{ .arg = &new_addr_arg },
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "protect",
        .tag = .mprotect,
        .args = &.{ &mmap_prot_arg, &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &mmap_prot_arg },
        },
    },
    .{
        .name = "advise",
        .tag = .madvise,
        .args = &.{ &madvise_advice_arg, &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &madvise_advice_arg },
        },
    },
    .{
        .name = "fd",
        .tag = .memfd_create,
        .args = &.{ &memfd_create_flags, &name_arg },
        .regs = &.{
            .{ .arg = &name_arg },
            .{ .arg = &memfd_create_flags },
        },
        .detail = .{ .logging = acq_err_fault },
    },
    .{
        .name = "sync",
        .tag = .msync,
        .args = &.{ &msync_flags, &addr_arg, &len_arg },
        .regs = &.{
            .{ .arg = &addr_arg },
            .{ .arg = &len_arg },
            .{ .arg = &msync_flags },
        },
    },
};
pub fn main() void {
    @setEvalBranchQuota(~@as(u32, 0));
    var allocator: zl.mem.SimpleAllocator = .{};
    const buf: [*]u8 = @ptrFromInt(allocator.allocateAtomic(1024 * 1024, 1));
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "const sys=@import(\"sys.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const proc=@import(\"proc.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const debug=@import(\"debug.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const builtin=@import(\"builtin.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const about=struct{};\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const spec=struct{};\n");
    for (&mem) |*fn_spec| {
        ptr = writeSpecificationType(ptr, fn_spec);
        ptr = writeFunctionSignature(ptr, fn_spec);
        ptr = writeLogging(ptr, fn_spec);
        ptr = writeInlineAsm(ptr, fn_spec);
        ptr = writeThrowBlock(ptr, fn_spec);
        ptr = writeAbortBlock(ptr, fn_spec);
        ptr = writeNoticeBlock(ptr, fn_spec);
        ptr = writeFunctionExit(ptr, fn_spec);
    }
    zl.file.write(.{ .errors = .{} }, 1, zl.fmt.slice(ptr, buf));
}
