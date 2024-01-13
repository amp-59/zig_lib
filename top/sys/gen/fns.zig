const zl = @import("../../../zig_lib.zig");
const fmt = zl.fmt;
const debug = zl.debug;
pub usingnamespace zl.start;

pub const logging_override = zl.debug.spec.logging.override.verbose;

const Arch = @TypeOf(@import("builtin").cpu.arch);
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
    clobbers: []const []const u8 = &.{},
};
const Fn = struct {
    name: []const u8,
    basename: ?[]const u8 = null,
    tag: zl.sys.Fn,
    args: []const *const Argument,
    regs: []const Register = &.{},
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
    spec_return_ty: ?Type = null,
    error_args: ?[]const *const Argument = null,
    notice_args: ?[]const *const Argument = null,
    logging: zl.debug.Logging.Default = .{
        .Attempt = false,
        .Success = true,
        .Acquire = false,
        .Release = false,
        .Error = true,
        .Fault = true,
    },
};
const Argument = struct {
    name: []const u8,
    type: Type,
    format: ?*const fn (buf: [*]u8, *const Argument) [*]u8 = null,
    value: ?*const fn (buf: [*]u8, *const Argument) [*]u8 = null,
    fn writeValueSlicePtr(buf: [*]u8, arg: *const Argument) [*]u8 {
        var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, arg.name);
        ptr[0..4].* = ".ptr".*;
        return ptr + 4;
    }
    fn writeValueSliceLen(buf: [*]u8, arg: *const Argument) [*]u8 {
        var ptr: [*]u8 = zl.fmt.strcpyEqu(buf, arg.name);
        ptr[0..4].* = ".len".*;
        return ptr + 4;
    }
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
        switch (@typeInfo(T)) {
            else => return Type.init(T),
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
fn writeRegisterValue(buf: [*]u8, reg: Register) [*]u8 {
    if (reg == .imm) {
        return zl.fmt.Udsize.write(buf, @bitCast(reg.imm));
    }
    if (reg.arg.value) |value| {
        return value(buf, reg.arg);
    }
    return zl.fmt.strcpyEqu(buf, reg.arg.name);
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
    ptr[0..21].* = ".logging.override();\n".*;
    return ptr + 21;
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
    } else if (fn_spec.basename) |name| {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, name), "_spec");
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
    } else if (fn_spec.basename) |name| {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, name), "_s");
    } else {
        return zl.fmt.strcpyEqu(zl.fmt.strcpyEqu(buf, fn_spec.name), "_s");
    }
}
fn writeErrorFnName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
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
fn writeNoticeFnName(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
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
fn writeFunctionParameters(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    for (fn_spec.args) |arg| {
        ptr = fmt.strcpyEqu(ptr, arg.name);
        ptr[0] = ':';
        ptr = Type.write(ptr + 1, arg.type);
        ptr[0] = ',';
        ptr += 1;
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
fn writeInlineAsm(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
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
        ptr = zl.fmt.strcpyEqu(ptr + 5, cpu_arch.regs[argn]);
        ptr[0..3].* = "}\"(".*;
        ptr = writeRegisterValue(ptr + 3, reg);
        ptr[0..3].* = "),\n".*;
        ptr += 3;
    }
    ptr[0..11].* = ": \"memory\",".*;
    ptr += 11;
    for (cpu_arch.clobbers) |where| {
        ptr = zl.fmt.StringLiteralFormat.write(ptr, where);
        ptr[0] = ',';
        ptr += 1;
    }
    ptr[0] = '\n';
    ptr += 1;
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}
fn writeReturnType(buf: [*]u8, fn_spec: *const Fn) [*]u8 {
    var ptr: [*]u8 = buf;
    if (fn_spec.detail.spec_return_ty) |return_ty| {
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

const Extra = struct {
    ptr_decl: bool = false,
    arg_prefix: []const u8 = "",
    len: struct {
        val: usize = 0,
        str: [4096]u8 = undefined,
        ptr: [*]u8 = undefined,
    },
};

fn writeArgIsFormat(buf: [*]u8, extra: *Extra, type_name: []const u8, arg: *const Argument) [*]u8 {
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
fn writeArgIsAnyFormat(buf: [*]u8, extra: *Extra, arg: *const Argument) [*]u8 {
    var ptr: [*]u8 = writeWriteStringLiteralConcat(buf, extra, &.{ extra.arg_prefix, arg.name, "=" });
    ptr[0..22].* = "ptr=fmt.AnyFormat(.{},".*;
    ptr = Type.write(ptr + 22, arg.type);
    ptr[0..8].* = ").write(".*;
    ptr = writeNextPtr(ptr + 8, extra);
    ptr[0] = ',';
    ptr = fmt.strcpyEqu(ptr + 1, arg.name);
    ptr[0..3].* = ");\n".*;
    return ptr + 3;
}

fn writeWriteParameters(buf: [*]u8, extra: *Extra, args: []const *const Argument) [*]u8 {
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
fn writeNoticeFunction(buf: [*]u8, extra: *Extra, fn_spec: *const Fn) [*]u8 {
    buf[0..3].* = "fn ".*;
    var ptr: [*]u8 = writeNoticeFnName(buf[3..], fn_spec);
    ptr[0] = '(';
    ptr = fmt.strcpyEqu(ptr + 1, "about_s:fmt.AboutSrc,");
    for (fn_spec.detail.notice_args orelse fn_spec.args) |param| {
        ptr = fmt.strcpyEqu(ptr, param.name);
        ptr[0] = ':';
        ptr = Type.write(ptr + 1, param.type);
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
fn writeErrorFunction(buf: [*]u8, extra: *Extra, fn_spec: *const Fn) [*]u8 {
    buf[0..3].* = "fn ".*;
    var ptr: [*]u8 = writeErrorFnName(buf[3..], fn_spec);
    ptr[0] = '(';
    ptr = fmt.strcpyEqu(ptr + 1, "about_s:fmt.AboutSrc,error_name:[]const u8,");
    for (fn_spec.detail.error_args orelse fn_spec.args) |param| {
        ptr = fmt.strcpyEqu(ptr, param.name);
        ptr[0] = ':';
        ptr = Type.write(ptr + 1, param.type);
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
fn writeNextPtrInc(buf: [*]u8, extra: *Extra) [*]u8 {
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
fn writeNextPtr(buf: [*]u8, extra: *Extra) [*]u8 {
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
fn writeWriteString(buf: [*]u8, extra: *Extra, string: []const u8) [*]u8 {
    defer extra.len.val += string.len;
    var ptr: [*]u8 = buf;
    ptr[0..2].* = "ptr=fmt.strcpyEqu(,".*;
    ptr = writeNextPtr(ptr, extra);
    ptr = zl.fmt.strcpyEqu(ptr, string);
    ptr[0..3].* = ");\n".*;
    return ptr + 2;
}
fn writeWriteStringLiteral(buf: [*]u8, extra: *Extra, string: []const u8) [*]u8 {
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
fn writeWriteStringLiteralConcat(buf: [*]u8, extra: *Extra, strings: []const []const u8) [*]u8 {
    var tmp: [4096]u8 = undefined;
    var ptr: [*]u8 = &tmp;
    for (strings) |string| ptr = zl.fmt.strcpyEqu(ptr, string);
    return writeWriteStringLiteral(buf, extra, zl.fmt.slice(ptr, &tmp));
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
    .clobbers = &.{ "rcx", "r11" },
}, .{
    .arch = .xtensa,
    .syscall = "syscall",
    .sysno = "a2",
    .ret = "a2",
    .regs = &.{ "a6", "a3", "a4", "a5", "a8", "a9" },
} };

const ret_arg: *const Argument = &.{ .name = "ret", .type = td(isize) };
const addr_arg: *const Argument = &.{ .name = "addr", .type = td(usize) };
const len_arg: *const Argument = &.{ .name = "len", .type = td(usize) };
const off_arg: *const Argument = &.{ .name = "off", .type = td(usize) };
const old_addr_arg: *const Argument = &.{ .name = "old_addr", .type = td(usize) };
const old_len_arg: *const Argument = &.{ .name = "old_len", .type = td(usize) };
const new_addr_arg: *const Argument = &.{ .name = "new_addr", .type = td(usize) };
const new_len_arg: *const Argument = &.{ .name = "new_len", .type = td(usize) };
const fd_arg: *const Argument = &.{ .name = "fd", .type = td(usize) };
const dir_fd_arg: *const Argument = &.{ .name = "dir_fd", .type = td(usize) };
const src_fd_arg: *const Argument = &.{ .name = "src_fd", .type = td(usize) };
const dest_fd_arg: *const Argument = &.{ .name = "dest_fd", .type = td(usize) };

const mmap_prot_arg: *const Argument = &.{ .name = "prot", .type = td(zl.sys.flags.MemProt) };
const mmap_flags_arg: *const Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemMap) };
const mremap_flags_arg: *const Argument = &.{ .name = "flags", .type = td(zl.sys.flags.Remap) };
const madvise_advice_arg: *const Argument = &.{ .name = "advice", .type = td(zl.sys.flags.MAdvise) };
const memfd_flags_args: *const Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemFd) };
const msync_flags: *const Argument = &.{ .name = "flags", .type = td(zl.sys.flags.MemSync) };
const at_flags_arg: *const Argument = &.{ .name = "at", .type = td(zl.sys.flags.At) };
const access_at_flags_arg: *const Argument = &.{ .name = "at", .type = td(zl.sys.flags.AtAccess) };
const statx_at_flags_arg: *const Argument = &.{ .name = "at", .type = td(zl.sys.flags.AtStatX) };

const name_arg: *const Argument = &.{
    .name = "name",
    .type = td([:0]const u8),
    .value = Argument.writeValueSlicePtr,
};
const pathname_arg: *const Argument = &.{
    .name = "pathname",
    .type = td([:0]const u8),
    .value = Argument.writeValueSlicePtr,
};
const exec_args_arg: *const Argument = &.{
    .name = "args",
    .type = td([]const [*:0]const u8),
    .value = Argument.writeValueSlicePtr,
};
const exec_vars_arg: *const Argument = &.{
    .name = "vars",
    .type = td([]const [*:0]const u8),
    .value = Argument.writeValueSlicePtr,
};
const write_buf_arg: *const Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]write_spec.child_type" } },
    .value = Argument.writeValueSlicePtr,
};
const write_buf_arg_len: *const Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]write_spec.child_type" } },
    .value = Argument.writeValueSliceLen,
};
const read_buf_arg: *const Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]const read_spec.child_type" } },
    .value = Argument.writeValueSlicePtr,
};
const read_buf_arg_len: *const Argument = &.{
    .name = "buf",
    .type = .{ .type_decl = .{ .name = "[]const read_spec.child_type" } },
    .value = Argument.writeValueSliceLen,
};

const acq_err_fault = .{ .Attempt = false, .Acquire = true, .Success = false, .Release = false, .Fault = true, .Error = true };
const rel_err_fault = .{ .Attempt = false, .Acquire = false, .Success = false, .Release = true, .Fault = true, .Error = true };

const mem = [_]Fn{
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

const file = [_]Fn{
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
const proc = [_]Fn{};

const about = struct {
    fn missingRegisters(fn_spec: *const Fn) void {
        var buf: [64]u8 = undefined;
        var ptr: [*]u8 = zl.fmt.strcpyEqu(&buf, fn_spec.name);
        ptr[0..12].* = ", expected: ".*;
        ptr = zl.fmt.Udsize.write(ptr + 12, fn_spec.tag.args());
        ptr[0..9].* = ", found: ".*;
        ptr = zl.fmt.Udsize.write(ptr + 9, fn_spec.regs.len);
        ptr[0] = '\n';
        zl.fmt.print(ptr + 1, &buf);
    }
};

fn optimiseAttributes() void {
    var args: [1024]*const Argument = undefined;
    var args_len: usize = 0;
    for (&proc ++ mem ++ file) |*fn_spec| {
        lo: for (fn_spec.args) |arg| {
            for (args[0..args_len]) |unique_arg| {
                if (zl.mem.testEqualMemory(*const Argument, arg, unique_arg)) {
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

fn writeNamespace(buf: [*]u8, fns: []const Fn, pathname: [:0]const u8, extra: *Extra) !void {
    var ptr: [*]u8 = buf;
    ptr = zl.fmt.strcpyEqu(ptr, "const sys=@import(\"../sys.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const proc=@import(\"../proc.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const debug=@import(\"../debug.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const builtin=@import(\"../builtin.zig\");\n");
    ptr = zl.fmt.strcpyEqu(ptr, "const spec=struct{};\n");
    for (fns) |*fn_spec| {
        if (fn_spec.tag.args() == fn_spec.regs.len) {
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
        if (fn_spec.tag.args() == fn_spec.regs.len) {
            ptr[0..6].* = "const ".*;
            ptr = writeAboutStrName(ptr + 6, fn_spec);
            ptr[0..24].* = ":fmt.AboutSrc=fmt.about(".*;
            ptr = zl.fmt.StringLiteralFormat.write(ptr + 24, @tagName(fn_spec.tag));
            ptr[0..3].* = ");\n".*;
            ptr += 3;
        }
    }
    for (fns) |*fn_spec| {
        if (fn_spec.tag.args() == fn_spec.regs.len) {
            ptr = writeNoticeFunction(ptr, extra, fn_spec);
        }
    }
    for (fns) |*fn_spec| {
        if (fn_spec.tag.args() == fn_spec.regs.len) {
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
    const extra: *Extra = @ptrFromInt(allocator.allocateRaw(@sizeOf(Extra), @alignOf(Extra)));
    extra.arg_prefix = "";
    extra.len.ptr = &extra.len.str;
    @memset(&extra.len.str, '@');

    try writeNamespace(buf, &mem, zl.builtin.lib_root ++ "/top/sys/mem.zig", extra);
    try writeNamespace(buf, &file, zl.builtin.lib_root ++ "/top/sys/file.zig", extra);
    try writeNamespace(buf, &proc, zl.builtin.lib_root ++ "/top/sys/proc.zig", extra);
}
