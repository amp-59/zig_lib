const zl = @import("../../../zig_lib.zig");
const fmt = zl.fmt;
const debug = zl.debug;
const attr = @import("attr.zig");
const types = @import("types.zig");
pub usingnamespace zl.start;
pub const logging_override = zl.debug.spec.logging.override.verbose;
fn argCount(tag: types.Fn.Tag) usize {
    switch (tag) {
        .getpid,
        .gettid,
        .fork,
        .getuid,
        .getgid,
        .geteuid,
        .getegid,
        .sync,
        => return 0,
        .rmdir,
        .dup,
        .close,
        .brk,
        .unlink,
        .exit,
        .chdir,
        .syncfs,
        .fsync,
        .fdatasync,
        .fchdir,
        => return 1,
        .memfd_create,
        .stat,
        .fstat,
        .lstat,
        .munmap,
        .getcwd,
        .truncate,
        .ftruncate,
        .mkdir,
        .clock_gettime,
        .nanosleep,
        .dup2,
        .clone3,
        .pipe2,
        .listen,
        .symlink,
        .link,
        .access,
        .shutdown,
        => return 2,
        .dup3,
        .read,
        .write,
        .open,
        .socket,
        .ioctl,
        .madvise,
        .mprotect,
        .mknod,
        .execve,
        .getdents64,
        .readlink,
        .getrandom,
        .unlinkat,
        .mkdirat,
        .open_by_handle_at,
        .poll,
        .bind,
        .lseek,
        .connect,
        .symlinkat,
        .sigaltstack,
        .futimesat,
        .msync,
        .accept,
        => return 3,
        .newfstatat,
        .mknodat,
        .readlinkat,
        .openat,
        .rt_sigaction,
        .sendfile,
        .faccessat2,
        .socketpair,
        => return 4,
        .mremap,
        .statx,
        .wait4,
        .waitid,
        .clone,
        .execveat,
        .name_to_handle_at,
        .linkat,
        .perf_event_open,
        .renameat2,
        => return 5,
        .preadv2,
        .pwritev2,
        .copy_file_range,
        .futex,
        .mmap,
        .recvfrom,
        .sendto,
        => return 6,
        //
        else => if (@inComptime())
            @compileError(@tagName(tag))
        else
            @panic(@tagName(tag)),
    }
}
fn writeRegisterValue(buf: [*]u8, reg: types.Register) [*]u8 {
    if (reg == .imm) {
        return zl.fmt.Udsize.write(buf, @bitCast(reg.imm));
    }
    if (reg.arg.value) |value| {
        return value(buf, reg.arg);
    }
    return zl.fmt.strcpyEqu(buf, reg.arg.name);
}
fn writeLoggingType(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
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
fn writeLogging(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "const logging:");
    ptr = writeLoggingType(ptr, fn_spec);
    ptr[0..10].* = "=comptime ".*;
    ptr = writeSpecName(ptr + 10, fn_spec);
    ptr[0..21].* = ".logging.override();\n".*;
    return ptr + 21;
}
fn writeErrorCodesName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.error_codes_name) |error_codes_names| {
        return zl.fmt.strcpyEqu(buf, error_codes_names);
    } else {
        buf[0..14].* = ".{.throw=spec.".*;
        const ptr: [*]u8 = zl.fmt.strcpyEqu(buf + 14, @tagName(fn_spec.tag));
        ptr[0..14].* = ".errors.all},\n".*;
        return ptr + 14;
    }
}
fn writeSpecName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.spec_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else if (fn_spec.basename) |name| {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, name), "_spec");
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_spec");
    }
}
fn writeSpecTypeName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.spec_ty_name) |spec_ty_name| {
        return zl.fmt.strcpyEqu(buf, spec_ty_name);
    } else {
        const ptr: [*]u8 = zl.fmt.writeToTitlecase(buf, fn_spec.name);
        return zl.fmt.strcpyEqu(ptr, "Spec");
    }
}
fn writeErrorName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.error_name) |error_name| {
        return zl.fmt.strcpyEqu(buf, error_name);
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_error");
    }
}
fn writeAboutStrName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.about_str_name) |about_str_name| {
        return zl.fmt.strcpyEqu(buf, about_str_name);
    } else if (fn_spec.basename) |name| {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, name), "_s");
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_s");
    }
}
fn writeErrorFnName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.error_fn_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else {
        buf[0..5].* = "about".*;
        var ptr: [*]u8 = buf[5..];
        for (fn_spec.detail.error_args orelse fn_spec.args) |arg| {
            ptr = zl.fmt.writeToTitlecase(ptr, arg.name);
        }
        ptr[0..5].* = "Error".*;
        return ptr + 5;
    }
}
fn writeNoticeFnName(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    if (fn_spec.detail.error_fn_name) |spec_name| {
        return zl.fmt.strcpyEqu(buf, spec_name);
    } else {
        buf[0..5].* = "about".*;
        var ptr: [*]u8 = buf[5..];
        for (fn_spec.detail.notice_args orelse fn_spec.args) |arg| {
            ptr = zl.fmt.writeToTitlecase(ptr, arg.name);
        }
        ptr[0..6].* = "Notice".*;
        return ptr + 6;
    }
}
fn writeThrowBlock(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
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
        ptr[19..25].* = "about.".*;
        ptr = writeErrorFnName(ptr + 25, fn_spec);
        ptr[0] = '(';
        ptr[1..7].* = "about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0..12].* = ",@errorName(".*;
        ptr = writeErrorName(ptr + 12, fn_spec);
        ptr[0..2].* = "),".*;
        ptr += 2;
        for (fn_spec.detail.error_args orelse fn_spec.args) |param| {
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
fn writeAbortBlock(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
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
        ptr[19..25].* = "about.".*;
        ptr = writeErrorFnName(ptr + 25, fn_spec);
        ptr[0] = '(';
        ptr[1..7].* = "about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0..12].* = ",@errorName(".*;
        ptr = writeErrorName(ptr + 12, fn_spec);
        ptr[0..2].* = "),".*;
        ptr += 2;
        for (fn_spec.detail.error_args orelse fn_spec.args) |param| {
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
fn writeNoticeBlock(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
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
        ptr[21..27].* = "about.".*;
        ptr = writeNoticeFnName(ptr + 27, fn_spec);
        ptr[0..7].* = "(about.".*;
        ptr = writeAboutStrName(ptr + 7, fn_spec);
        ptr[0] = ',';
        ptr += 1;
        for (fn_spec.detail.notice_args orelse fn_spec.args) |param| {
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
fn writeFunctionParameters(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    for (fn_spec.args) |arg| {
        ptr = fmt.strcpyEqu(ptr, arg.name);
        ptr[0] = ':';
        ptr = types.Type.write(ptr + 1, arg.type);
        ptr[0] = ',';
        ptr += 1;
    }
    return ptr;
}
fn writeFunctionSignature(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..7].* = "pub fn ".*;
    ptr = zl.fmt.strcpyEqu(ptr + 7, fn_spec.name);
    ptr[0] = '(';
    ptr = zl.fmt.strcpyEqu(ptr + 1, "comptime ");
    ptr = writeSpecName(ptr, fn_spec);
    ptr[0] = ':';
    ptr = writeSpecTypeName(ptr + 1, fn_spec);
    ptr[0] = ',';
    ptr = writeFunctionParameters(ptr + 1, fn_spec);
    ptr[0] = ')';
    ptr += 1;
    ptr[0..15].* = "sys.ErrorUnion(".*;
    ptr = writeSpecName(ptr + 15, fn_spec);
    ptr[0..8].* = ".errors,".*;
    ptr = writeSpecName(ptr + 8, fn_spec);
    ptr[0..15].* = ".return_type){\n".*;
    return ptr + 15;
}
fn writeInlineAsm(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    ptr[0..30].* = "const ret:isize=asm volatile (".*;
    ptr += 30;
    ptr[0..11].* = "\\\\syscall #".*;
    ptr = zl.fmt.strcpyEqu(ptr + 11, @tagName(fn_spec.tag));
    ptr[0] = '\n';
    ptr += 1;
    ptr[0..23].* = ":[_]\"={rax}\"(->isize),\n".*;
    ptr += 23;
    ptr[0..31].* = ":[_]\"{rax}\"(@intFromEnum(sys.Fn".*;
    ptr = zl.fmt.EnumFormat(.{}, zl.sys.Fn).write(ptr + 31, fn_spec.tag);
    ptr[0..4].* = ")),\n".*;
    ptr += 4;
    for (fn_spec.regs, 0..) |reg, argn| {
        ptr[0..5].* = "[_]\"{".*;
        ptr = zl.fmt.strcpyEqu(ptr + 5, attr.cpu_arch.regs[argn]);
        ptr[0..3].* = "}\"(".*;
        ptr = writeRegisterValue(ptr + 3, reg);
        ptr[0..3].* = "),\n".*;
        ptr += 3;
    }
    ptr[0..11].* = ": \"memory\",".*;
    ptr += 11;
    for (attr.cpu_arch.clobbers) |where| {
        ptr = zl.fmt.StringLiteralFormat.write(ptr, where);
        ptr[0] = ',';
        ptr += 1;
    }
    ptr[0] = '\n';
    ptr += 1;
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeReturnType(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    if (fn_spec.detail.spec_return_ty) |return_ty| {
        ptr = types.Type.write(ptr, return_ty);
    } else {
        ptr = types.Type.write(ptr, comptime types.Type.init(void));
    }
    return ptr;
}
fn writeSpecificationType(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
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
fn writeFunctionExit(buf: [*]u8, fn_spec: *const types.Fn) [*]u8 {
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, "if(");
    ptr = writeSpecName(ptr, fn_spec);
    ptr = zl.fmt.strcpyEqu(ptr, ".return_type!=void){");
    ptr = zl.fmt.strcpyEqu(ptr, "return @intCast(ret);\n");
    ptr = zl.fmt.strcpyEqu(ptr, "}\n");
    ptr[0..2].* = "}\n".*;
    return ptr + 2;
}
fn writeArgIsFormat(buf: [*]u8, extra: *types.Extra, type_name: []const u8, arg: *const types.Argument) [*]u8 {
    var ptr: [*]u8 = writeWriteStringLiteralConcat(buf, extra, &.{ extra.arg_prefix, arg.name, "=" });
    ptr[0..8].* = "ptr=fmt.".*;
    ptr = zl.fmt.strcpyEqu(ptr + 8, type_name);
    ptr[0..7].* = ".write(".*;
    ptr = writeNextPtr(ptr + 7, extra);
    ptr[0] = ',';
    ptr = fmt.strcpyEqu(ptr + 1, arg.name);
    ptr[0..3].* = ");\n".*;
    ptr += 3;
    return ptr;
}
fn writeArgIsAnyFormat(buf: [*]u8, extra: *types.Extra, arg: *const types.Argument) [*]u8 {
    var ptr: [*]u8 = writeWriteStringLiteralConcat(buf, extra, &.{ extra.arg_prefix, arg.name, "=" });
    ptr[0..22].* = "ptr=fmt.AnyFormat(.{},".*;
    ptr = types.Type.write(ptr + 22, arg.type);
    ptr[0..8].* = ").write(".*;
    ptr = writeNextPtr(ptr + 8, extra);
    ptr[0] = ',';
    ptr = fmt.strcpyEqu(ptr + 1, arg.name);
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeWriteParameters(buf: [*]u8, extra: *types.Extra, args: []const *const types.Argument) [*]u8 {
    var ptr: [*]u8 = buf;
    defer extra.arg_prefix = "";
    for (args) |arg| {
        defer extra.arg_prefix = ", ";
        if (zl.mem.testEqualString("addr", arg.name)) {
            ptr = writeArgIsFormat(ptr, extra, "Uxsize", arg);
            continue;
        }
        if (zl.mem.testEqualString("off", arg.name) or
            zl.mem.testEqualString("len", arg.name))
        {
            ptr = writeArgIsFormat(ptr, extra, "Udsize", arg);
            continue;
        }
        if (arg.type == .type_decl) {
            if (arg.type.type_decl.name) |name| {
                if (name.ptr == "usize".ptr) {
                    ptr = writeArgIsFormat(ptr, extra, "Udsize", arg);
                    continue;
                }
            }
        }
        ptr = writeArgIsAnyFormat(ptr, extra, arg);
    }
    return ptr;
}
fn writeNoticeFunction(buf: [*]u8, extra: *types.Extra, fn_spec: *const types.Fn) [*]u8 {
    buf[0..3].* = "fn ".*;
    var ptr: [*]u8 = writeNoticeFnName(buf[3..], fn_spec);
    ptr[0] = '(';
    ptr = fmt.strcpyEqu(ptr + 1, "about_s:fmt.AboutSrc,");
    for (fn_spec.detail.notice_args orelse fn_spec.args) |param| {
        ptr = fmt.strcpyEqu(ptr, param.name);
        ptr[0] = ':';
        ptr = types.Type.write(ptr + 1, param.type);
        ptr[0] = ',';
        ptr += 1;
    }
    ptr[0..7].* = ")void{\n".*;
    ptr += 7;
    ptr = zl.fmt.strcpyEqu(ptr,
        \\var buf:[4096]u8=undefined;
        \\buf[0..about_s.len].*=about_s.*;
        \\var ptr:[*]u8=buf[about_s.len..];
        \\
    );
    ptr = writeWriteParameters(ptr, extra, fn_spec.detail.notice_args orelse fn_spec.args);
    ptr = zl.fmt.strcpyEqu(ptr,
        \\ptr[0] = '\n';
        \\debug.write(buf[0..@intFromPtr(ptr+1)-%@intFromPtr(&buf)]);
        \\
    );
    ptr[0..2].* = "}\n".*;
    return ptr + 2;
}
fn writeErrorFunction(buf: [*]u8, extra: *types.Extra, fn_spec: *const types.Fn) [*]u8 {
    buf[0..3].* = "fn ".*;
    var ptr: [*]u8 = writeErrorFnName(buf[3..], fn_spec);
    ptr[0] = '(';
    ptr = fmt.strcpyEqu(ptr + 1, "about_s:fmt.AboutSrc,error_name:[]const u8,");
    for (fn_spec.detail.error_args orelse fn_spec.args) |param| {
        ptr = fmt.strcpyEqu(ptr, param.name);
        ptr[0] = ':';
        ptr = types.Type.write(ptr + 1, param.type);
        ptr[0] = ',';
        ptr += 1;
    }
    ptr[0..7].* = ")void{\n".*;
    ptr += 7;
    ptr[0..28].* = "var buf:[4096]u8=undefined;\n".*;
    ptr += 28;
    ptr[0..68].* = "var ptr:[*]u8=debug.about.writeAboutError(&buf,about_s,error_name);\n".*;
    ptr = writeWriteParameters(ptr + 68, extra, fn_spec.detail.error_args orelse fn_spec.args);
    ptr = zl.fmt.strcpyEqu(ptr,
        \\ptr[0] = '\n';
        \\debug.write(buf[0..@intFromPtr(ptr+1)-%@intFromPtr(&buf)]);
        \\
    );
    ptr[0..2].* = "}\n".*;
    return ptr + 2;
}
fn writeNextPtrInc(buf: [*]u8, extra: *types.Extra) [*]u8 {
    var ptr: [*]u8 = buf;
    if (extra.len.val != 0 and extra.len.ptr != &extra.len.str) {
        ptr[0..5].* = "ptr+=".*;
        ptr = fmt.Udsize.write(ptr + 5, extra.len.val);
        ptr = fmt.strcpyEqu(ptr, zl.fmt.slice(extra.len.ptr, &extra.len.str));
        ptr[0..2].* = ";\n".*;
        ptr += 2;
    } else if (extra.len.val != 0 and extra.len.ptr != &extra.len.str) {
        ptr[0..5].* = "ptr+=".*;
        ptr = fmt.Udsize.write(ptr + 5, extra.len.val);
        ptr[0..2].* = ";\n".*;
        ptr += 2;
    } else if (extra.len.ptr != &extra.len.str) {
        ptr[0..5].* = "ptr+=".*;
        ptr = fmt.strcpyEqu(ptr + 5, zl.fmt.slice(extra.len.ptr, &extra.len.str));
        ptr[0..2].* = ";\n".*;
        ptr += 2;
    }
    extra.len.val = 0;
    extra.len.ptr = &extra.len.str;
    return ptr;
}
fn writeNextPtr(buf: [*]u8, extra: *types.Extra) [*]u8 {
    var ptr: [*]u8 = buf;
    if (extra.len.val != 0 and extra.len.ptr != &extra.len.str) {
        ptr[0..4].* = "ptr+".*;
        ptr = fmt.Udsize.write(ptr + 4, extra.len.val);
        ptr = fmt.strcpyEqu(ptr, zl.fmt.slice(extra.len.ptr, &extra.len.str));
    } else if (extra.len.val != 0) {
        ptr[0..4].* = "ptr+".*;
        ptr = fmt.Udsize.write(ptr + 4, extra.len.val);
    } else if (extra.len.ptr != &extra.len.str) {
        ptr[0..4].* = "ptr+".*;
        ptr = fmt.strcpyEqu(ptr + 4, zl.fmt.slice(extra.len.ptr, &extra.len.str));
    } else {
        ptr[0..3].* = "ptr".*;
        ptr += 3;
    }
    extra.len.val = 0;
    extra.len.ptr = &extra.len.str;
    return ptr;
}
fn writeWriteString(buf: [*]u8, extra: *types.Extra, string: []const u8) [*]u8 {
    defer extra.len.val += string.len;
    var ptr: [*]u8 = buf;
    ptr[0..2].* = "ptr=fmt.strcpyEqu(,".*;
    ptr = writeNextPtr(ptr, extra);
    ptr = zl.fmt.strcpyEqu(ptr, string);
    ptr[0..3].* = ");\n".*;
    return ptr + 2;
}
fn writeWriteStringLiteral(buf: [*]u8, extra: *types.Extra, string: []const u8) [*]u8 {
    defer extra.len.val += string.len;
    var ptr: [*]u8 = buf;
    ptr = writeNextPtrInc(buf, extra);
    ptr[0..4].* = "ptr[".*;
    ptr = zl.fmt.Udsize.write(ptr + 4, extra.len.val);
    ptr[0..2].* = "..".*;
    ptr = zl.fmt.Udsize.write(ptr + 2, string.len + extra.len.val);
    ptr[0..4].* = "].*=".*;
    ptr = zl.fmt.StringLiteralFormat.write(ptr + 4, string);
    ptr[0..4].* = ".*;\n".*;
    return ptr + 4;
}
fn writeWriteStringLiteralConcat(buf: [*]u8, extra: *types.Extra, strings: []const []const u8) [*]u8 {
    var tmp: [4096]u8 = undefined;
    var ptr: [*]u8 = &tmp;
    for (strings) |string| ptr = zl.fmt.strcpyEqu(ptr, string);
    return writeWriteStringLiteral(buf, extra, zl.fmt.slice(ptr, &tmp));
}
const about = struct {
    fn missingRegisters(fn_spec: *const types.Fn) void {
        var buf: [64]u8 = undefined;
        var ptr: [*]u8 = zl.fmt.strcpyEqu(&buf, fn_spec.name);
        ptr[0..12].* = ", expected: ".*;
        ptr = zl.fmt.Udsize.write(ptr + 12, argCount(fn_spec.tag));
        ptr[0..9].* = ", found: ".*;
        ptr = zl.fmt.Udsize.write(ptr + 9, fn_spec.regs.len);
        ptr[0] = '\n';
        zl.fmt.print(ptr + 1, &buf);
    }
};
fn optimiseAttributes() void {
    var args: [1024]*const types.Argument = undefined;
    var args_len: usize = 0;
    for (attr.proc ++ attr.mem ++ attr.file) |*fn_spec| {
        lo: for (fn_spec.args) |arg| {
            for (args[0..args_len]) |unique_arg| {
                if (zl.mem.testEqualMemory(*const types.Argument, arg, unique_arg)) {
                    continue :lo;
                }
            }
            args[args_len] = arg;
            args_len += 1;
        }
    }
    for (args[0..args_len]) |arg| {
        zl.testing.printBufN(65536, arg);
    }
}
fn writeNamespace(buf: [*]u8, fns: []const types.Fn, pathname: [:0]const u8, extra: *types.Extra) !void {
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "const sys=@import(\"../sys.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const proc=@import(\"../proc.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const debug=@import(\"../debug.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const builtin=@import(\"../builtin.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const spec=struct{};\n");
    for (fns) |*fn_spec| {
        if (argCount(fn_spec.tag) == fn_spec.regs.len) {
            ptr = writeSpecificationType(ptr, fn_spec);
            ptr = writeFunctionSignature(ptr, fn_spec);
            ptr = writeLogging(ptr, fn_spec);
            ptr = writeInlineAsm(ptr, fn_spec);
            ptr = writeThrowBlock(ptr, fn_spec);
            ptr = writeAbortBlock(ptr, fn_spec);
            ptr = writeNoticeBlock(ptr, fn_spec);
            ptr = writeFunctionExit(ptr, fn_spec);
        } else {
            about.missingRegisters(fn_spec);
        }
    }
    ptr = zl.fmt.strcpyEqu(ptr, "const about=struct{\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const fmt=@import(\"../fmt.zig\");\n");
    for (fns) |*fn_spec| {
        if (argCount(fn_spec.tag) == fn_spec.regs.len) {
            ptr[0..6].* = "const ".*;
            ptr = writeAboutStrName(ptr + 6, fn_spec);
            ptr[0..24].* = ":fmt.AboutSrc=fmt.about(".*;
            ptr = zl.fmt.StringLiteralFormat.write(ptr + 24, @tagName(fn_spec.tag));
            ptr[0..3].* = ");\n".*;
            ptr += 3;
        }
    }
    for (fns) |*fn_spec| {
        if (argCount(fn_spec.tag) == fn_spec.regs.len) {
            ptr = writeNoticeFunction(ptr, extra, fn_spec);
        }
    }
    for (fns) |*fn_spec| {
        if (argCount(fn_spec.tag) == fn_spec.regs.len) {
            ptr = writeErrorFunction(ptr, extra, fn_spec);
        }
    }
    ptr = zl.fmt.strcpyEqu(ptr, "};\n");
    try zl.gen.truncateFile(.{}, pathname, zl.fmt.slice(ptr, buf));
}
pub fn main() !void {
    @setRuntimeSafety(false);
    @setEvalBranchQuota(~@as(u32, 0));
    var allocator: zl.mem.SimpleAllocator = .{};
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    @memset(buf[0 .. 1024 * 1024], '@');
    const extra: *types.Extra = @ptrFromInt(allocator.allocateRaw(@sizeOf(types.Extra), @alignOf(types.Extra)));
    extra.arg_prefix = "";
    extra.len.ptr = &extra.len.str;
    @memset(&extra.len.str, '@');
    try writeNamespace(buf, attr.mem, zl.builtin.lib_root ++ "/top/sys/mem.zig", extra);
    try writeNamespace(buf, attr.file, zl.builtin.lib_root ++ "/top/sys/file.zig", extra);
    try writeNamespace(buf, attr.proc, zl.builtin.lib_root ++ "/top/sys/proc.zig", extra);
}
