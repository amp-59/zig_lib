const fmt = @import("../../fmt.zig");
const mem = @import("../../mem.zig");
const bits = @import("../../bits.zig");
const safety = @import("../../safety.zig");
const types = @import("types.zig");
const config = @import("config.zig");
const context: types.Context = @import("root").context;
const combine_char: bool = true;
const memcpy_threshold: usize = 4;
const combine_len: bool = true;
var allocator_used: bool = false;
fn writeSetRuntimeSafety(array: *types.Array) void {
    array.writeMany("@setRuntimeSafety(false);\n");
}
fn writeAllocateRawDecls(array: *types.Array, language: types.Extra.Language) void {
    switch (language) {
        .C => {
            array.writeMany("unsigned long size_of = sizeof();\n");
            array.writeMany("unsigned long align_of = alignof();\n");
        },
        .Zig => {
            array.writeMany("pub const size_of: comptime_int = @sizeOf(@This());\n");
            array.writeMany("pub const align_of: comptime_int = @alignOf(@This());\n");
        },
    }
}
fn writeDeclarePointer(array: *types.Array) void {
    array.writeMany("var ptr:[*]u8=buf;\n");
}
fn writeDeclareLength(array: *types.Array, extra: *types.Extra) void {
    array.writeMany("var len:usize=0;\n");
    extra.len.decl = true;
}
fn writeReturnLength(array: *types.Array, extra: *types.Extra) void {
    if (extra.len.val != 0 and extra.len.strings.len() != 0) {
        array.writeMany("return len+%");
        array.writeFormat(fmt.udsize(extra.len.val));
        array.writeMany(extra.len.strings.readAll());
        array.writeMany(";\n");
    } else if (extra.len.val != 0) {
        array.writeMany("return len+%");
        array.writeFormat(fmt.udsize(extra.len.val));
        array.writeMany(";\n");
    } else if (extra.len.strings.len() != 0) {
        array.writeMany("return len");
        array.writeMany(extra.len.strings.readAll());
        array.writeMany(";\n");
    } else {
        array.writeMany("return len;\n");
    }
    extra.len.val = 0;
    extra.len.decl = false;
    extra.len.strings.undefineAll();
}
fn writeCombinedLength(array: *types.Array, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            if (extra.len.val != 0 and extra.len.strings.len() != 0) {
                array.writeMany("ptr+=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(extra.len.strings.readAll());
                array.writeMany(";\n");
            } else if (extra.len.val != 0) {
                array.writeMany("ptr+=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(";\n");
            } else if (extra.len.strings.len() != 0) {
                array.writeMany("ptr=ptr");
                array.writeMany(extra.len.strings.readAll());
                array.writeMany(";\n");
            }
        },
        .length => if (extra.len.decl) {
            if (extra.len.val != 0 and extra.len.strings.len() != 0) {
                array.writeMany("len+%=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(extra.len.strings.readAll());
                array.writeMany(";\n");
            } else if (extra.len.val != 0) {
                array.writeMany("len+%=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(";\n");
            } else if (extra.len.strings.len() != 0) {
                array.writeMany("len=len");
                array.writeMany(extra.len.strings.readAll());
                array.writeMany(";\n");
            }
        } else {
            if (extra.len.val != 0 and extra.len.strings.len() != 0) {
                array.writeMany("var len:usize=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(extra.len.strings.readAll());
                array.writeMany(";\n");
            } else if (extra.len.strings.len() != 0) {
                array.writeMany("var len:usize=");
                array.writeMany(extra.len.strings.readAll()[2..]);
                array.writeMany(";\n");
            } else {
                array.writeMany("var len:usize=");
                array.writeFormat(fmt.udsize(extra.len.val));
                array.writeMany(";\n");
            }
            extra.len.decl = true;
        },
        else => return,
    }
    extra.len.val = 0;
    extra.len.strings.undefineAll();
}
fn writeReturnPointerDiff(array: *types.Array) void {
    array.writeMany("return @intFromPtr(ptr)-%@intFromPtr(buf);\n");
}
fn writeReturnPointer(array: *types.Array) void {
    array.writeMany("return ptr;\n");
}
pub fn writeOpenStruct(array: *types.Array, language: types.Extra.Language, attributes: types.Attributes) void {
    switch (language) {
        .Zig => {
            array.writeMany("pub const ");
            array.writeMany(attributes.type_name);
            array.writeMany("=struct{\n");
        },
        .C => {
            array.writeMany("struct ");
            array.writeMany(attributes.type_name);
            array.writeMany("{\n");
        },
    }
}
pub fn writeCloseContainer(array: *types.Array) void {
    array.writeMany("};\n");
}
fn writeIf(
    array: *types.Array,
    value_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany("){\n");
}
fn writeIfField(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("if(");
    array.writeMany(extra.ptr_name);
    array.writeMany(".");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeIfOptionalField(
    array: *types.Array,
    field_name: []const u8,
    capture_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("if(");
    array.writeMany(extra.ptr_name);
    array.writeMany(".");
    array.writeMany(field_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeIfOptional(
    array: *types.Array,
    value_name: []const u8,
    capture_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeForEach(
    array: *types.Array,
    values_name: []const u8,
    value_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("for(");
    array.writeMany(values_name);
    array.writeMany(")|");
    array.writeMany(value_name);
    array.writeMany("|{\n");
}
fn writeSwitch(
    array: *types.Array,
    value_name: []const u8,
    extra: *types.Extra,
) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("switch(");
    array.writeMany(value_name);
    array.writeMany("){\n");
}
fn writeProng(array: *types.Array, tag_name: []const u8) void {
    array.writeMany(".");
    array.writeMany(tag_name);
    array.writeMany("=>{\n");
}
fn writeRequiredProng(array: *types.Array, tag_name: []const u8, capture_name: []const u8) void {
    array.writeMany(".");
    array.writeMany(tag_name);
    array.writeMany("=>|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeElse(array: *types.Array, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("}else{\n");
}
fn writeContinue(array: *types.Array, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("continue;\n");
}
fn writeIfElse(array: *types.Array, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("}else\n");
}
fn writeCloseIf(array: *types.Array, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("}\n");
}
fn writeCloseFn(array: *types.Array, extra: *types.Extra) void {
    extra.len.decl = false;
    array.writeMany("}\n");
}
fn writeCloseSwitch(array: *types.Array) void {
    array.writeMany("}\n");
}
fn writeCloseProng(array: *types.Array, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("},\n");
}
fn writeFieldTagname(
    array: anytype,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany("@tagName(");
    array.writeMany(extra.ptr_name);
    array.writeMany(".");
    array.writeMany(field_name);
    array.writeMany(")");
}
fn writeFieldTagnameLen(array: anytype, field_name: []const u8, extra: *types.Extra) void {
    writeFieldTagname(array, field_name, extra);
    array.writeMany(".len");
}
fn writeFieldTagnamePtr(array: anytype, field_name: []const u8, extra: *types.Extra) void {
    writeFieldTagname(array, field_name, extra);
    array.writeMany(".ptr");
}
fn writeOptFieldTagname(array: anytype, symbol_name: []const u8) void {
    array.writeMany("@tagName(");
    array.writeMany(symbol_name);
    array.writeMany(")");
}
fn writeOptFieldTagnameLen(array: anytype, symbol_name: []const u8) void {
    writeOptFieldTagname(array, symbol_name);
    array.writeMany(".len");
}
fn writeOptFieldTagnamePtr(array: anytype, symbol_name: []const u8) void {
    writeOptFieldTagname(array, symbol_name);
    array.writeMany(".ptr");
}
fn writeNull(array: *types.Array, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            array.writeMany("ptr[0]=0;\n");
            if (combine_len) {
                extra.len.val +%= 1;
            } else {
                array.writeMany("ptr+=1;\n");
            }
        },
        .formatWrite => {
            array.writeMany("array.writeOne(0);\n");
        },
        .length => if (combine_len) {
            extra.len.val +%= 1;
        } else {
            array.writeMany("len+%=1;\n");
        },
    }
}
fn writeOne(array: *types.Array, one: u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            if (extra.notation == .slice) {
                array.writeMany("ptr[0]=");
                array.writeFormat(fmt.ud8(one));
                array.writeMany(";\n");
                if (combine_len) {
                    extra.len.val +%= 1;
                } else {
                    array.writeMany("ptr+=1;\n");
                }
            } else {
                array.writeMany("buf[len]=");
                array.writeFormat(fmt.ud8(one));
                array.writeMany(";\nlen+%=1;\n");
            }
        },
        .formatWrite => {
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(");\n");
        },
        .length => if (combine_len) {
            extra.len.val +%= 1;
        } else {
            array.writeMany("len+%=1;\n");
        },
    }
}
fn writeIntegerString(array: *types.Array, arg_string: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            if (extra.notation == .slice) {
                array.writeMany("ptr=fmt.Ud64.write(ptr,");
                array.writeMany(arg_string);
                array.writeMany(");\n");
            } else {
                array.writeMany("len+%=fmt.Ud64.formatWriteBuf(.{.value=");
                array.writeMany(arg_string);
                array.writeMany("},buf+len);\n");
            }
        },
        .formatWrite => {
            array.writeMany("array.writeFormat(fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%fmt.Ud64.length(");
            extra.len.strings.writeMany(arg_string);
            extra.len.strings.writeMany(")");
        } else {
            array.writeMany("len+%=fmt.Ud64.length(");
            array.writeMany(arg_string);
            array.writeMany(");\n");
        },
    }
}
fn writeWriteString(array: *types.Array, extra: *types.Extra) void {
    if (extra.len.val != 0) {
        array.writeMany("ptr=fmt.strcpyEqu(ptr+");
        array.writeFormat(fmt.udsize(extra.len.val));
        array.writeMany(",");
        extra.len.val = 0;
    } else {
        array.writeMany("ptr=fmt.strcpyEqu(ptr,");
    }
}
fn writeKindString(array: *types.Array, arg_string: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => |function| {
            switch (extra.memcpy) {
                .builtin => {
                    if (extra.notation == .slice) {
                        array.writeMany("@memcpy(ptr,");
                        writeFieldTagname(array, arg_string, extra);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("@memcpy(buf+len,");
                        writeFieldTagname(array, arg_string, extra);
                        array.writeMany(");\n");
                    }
                },
                .fmt => {
                    if (extra.notation == .slice) {
                        writeWriteString(array, extra);
                        writeFieldTagname(array, arg_string, extra);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("len+%=fmt.strcpy(buf+len,");
                        writeFieldTagname(array, arg_string, extra);
                        array.writeMany(");\n");
                    }
                },
            }
            if (extra.memcpy != .fmt) {
                if (extra.notation == .slice) {
                    array.writeMany("ptr+=");
                    writeFieldTagnameLen(array, arg_string, extra);
                    array.writeMany(";\n");
                } else {
                    writeKindString(array, arg_string, lengthExtra(extra));
                    extra.function = function;
                }
            }
        },
        .formatWrite => {
            array.writeMany("array.writeMany(@tagName(");
            array.writeMany(extra.ptr_name);
            array.writeMany(".");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%");
            writeFieldTagnameLen(&extra.len.strings, arg_string, extra);
        } else {
            array.writeMany("len+%=");
            writeFieldTagnameLen(array, arg_string, extra);
            array.writeMany(";\n");
        },
    }
}
fn lengthExtra(extra: *types.Extra) *types.Extra {
    switch (extra.function) {
        .formatWrite => {
            extra.function = .length;
        },
        .write => {
            extra.function = .length;
        },
        else => return extra,
    }
    return extra;
}
fn writeTagString(array: *types.Array, arg_string: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            switch (extra.memcpy) {
                .builtin => {
                    if (extra.notation == .slice) {
                        array.writeMany("@memcpy(ptr,");
                        writeOptFieldTagname(array, arg_string);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("@memcpy(buf+len,");
                        writeOptFieldTagname(array, arg_string);
                        array.writeMany(");\n");
                    }
                },
                .fmt => {
                    if (extra.notation == .slice) {
                        writeWriteString(array, extra);
                        writeOptFieldTagname(array, arg_string);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("len+=fmt.strcpy(buf+len,");
                        writeOptFieldTagname(array, arg_string);
                        array.writeMany(");\n");
                    }
                },
            }
            if (extra.memcpy != .fmt) {
                if (extra.notation == .slice) {
                    array.writeMany("ptr+=@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").len;\n");
                } else {
                    writeTagString(array, arg_string, extra);
                }
            }
        },
        .formatWrite => {
            array.writeMany("array.writeMany(@tagName(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%@tagName(");
            extra.len.strings.writeMany(arg_string);
            extra.len.strings.writeMany(").len");
        } else {
            array.writeMany("len+%=@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len;\n");
        },
    }
}
fn writeArgString(array: *types.Array, arg_string: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => |function| {
            switch (extra.memcpy) {
                .builtin => {
                    if (extra.notation == .slice) {
                        array.writeMany("@memcpy(ptr,");
                        array.writeMany(arg_string);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("@memcpy(buf+len,");
                        array.writeMany(arg_string);
                        array.writeMany(");\n");
                    }
                },
                .fmt => {
                    if (extra.notation == .slice) {
                        writeWriteString(array, extra);
                    } else {
                        array.writeMany("len+%=fmt.strcpy(buf+len,");
                    }
                    array.writeMany(arg_string);
                    array.writeMany(");\n");
                },
            }
            if (extra.memcpy != .fmt) {
                if (extra.notation == .slice) {
                    array.writeMany("ptr+=");
                    array.writeMany(arg_string);
                    array.writeMany(".len;\n");
                } else {
                    writeArgString(array, arg_string, lengthExtra(extra));
                    extra.function = function;
                }
            }
        },
        .formatWrite => {
            array.writeMany("array.writeMany(");
            array.writeMany(arg_string);
            array.writeMany(");\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%");
            extra.len.strings.writeMany(arg_string);
            extra.len.strings.writeMany(".len");
        } else {
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".len;\n");
        },
    }
}
fn writeFieldAccess(array: *types.Array, field_name: []const u8, extra: *types.Extra) void {
    array.writeMany(extra.ptr_name);
    array.writeMany(".");
    array.writeMany(field_name);
}
fn writeFieldString(array: *types.Array, field_name: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => |function| {
            switch (extra.memcpy) {
                .builtin => {
                    if (extra.notation == .slice) {
                        array.writeMany("@memcpy(ptr,");
                        writeFieldAccess(array, field_name, extra);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("@memcpy(buf+len,");
                        writeFieldAccess(array, field_name, extra);
                        array.writeMany(");\n");
                    }
                },
                .fmt => {
                    if (extra.notation == .slice) {
                        writeWriteString(array, extra);
                        writeFieldAccess(array, field_name, extra);
                        array.writeMany(");\n");
                    } else {
                        array.writeMany("len+%=fmt.strcpy(buf+len,");
                        writeFieldAccess(array, field_name, extra);
                        array.writeMany(");\n");
                    }
                },
            }
            if (extra.memcpy != .fmt) {
                if (extra.notation == .slice) {
                    array.writeMany("ptr+=");
                    writeFieldAccess(array, field_name, extra);
                    array.writeMany(".len;\n");
                } else {
                    writeFieldString(array, field_name, lengthExtra(extra));
                    extra.function = function;
                }
            }
        },
        .formatWrite => {
            array.writeMany("array.writeMany(");
            array.writeMany(field_name);
            array.writeMany(");\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%");
            extra.len.strings.writeMany(extra.ptr_name);
            extra.len.strings.writeMany(".");
            extra.len.strings.writeMany(field_name);
            extra.len.strings.writeMany(".len");
        } else {
            array.writeMany("len+%=");
            writeFieldAccess(array, field_name, extra);
            array.writeMany(".len;\n");
        },
    }
}
fn writeFormatterInternal(array: *types.Array, arg_string: []const u8, extra: *types.Extra) void {
    switch (extra.function) {
        .write => {
            if (extra.notation == .slice) {
                array.writeMany("ptr+=");
                array.writeMany(arg_string);
                array.writeMany(".formatWriteBuf(ptr);\n");
            } else {
                array.writeMany("len+%=");
                array.writeMany(arg_string);
                array.writeMany(".formatWriteBuf(buf+len);\n");
            }
        },
        .formatWrite => {
            array.writeMany("array.writeFormat(");
            array.writeMany(arg_string);
            array.writeMany(");\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%");
            extra.len.strings.writeMany(arg_string);
            extra.len.strings.writeMany(".formatLength()");
        } else {
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".formatLength();\n");
        },
    }
}
fn writeMapped(
    array: *types.Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    to: types.BGTypeDescr,
    char: u8,
    extra: *types.Extra,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, char, extra);
    }
    switch (extra.function) {
        .write => {
            if (extra.notation == .slice) {
                array.writeMany("ptr+=");
                array.writeFormat(to);
                array.writeMany(".formatWriteBuf(.{.value=");
                array.writeMany(arg_string);
                array.writeMany("}, ptr);\n");
            } else {
                array.writeMany("len+%=");
                array.writeFormat(to);
                array.writeMany(".formatWriteBuf(.{.value=");
                array.writeMany(arg_string);
                array.writeMany("}, buf+len);\n");
            }
        },
        .formatWrite => {
            array.writeMany("array.writeFormat(");
            array.writeFormat(to);
            array.writeMany("{.value=");
            array.writeMany(arg_string);
            array.writeMany("});\n");
        },
        .length => if (combine_len) {
            extra.len.strings.writeMany("+%");
            extra.len.strings.writeFormat(to);
            extra.len.strings.writeMany(".formatLength(.{.value=");
            extra.len.strings.writeMany(arg_string);
            extra.len.strings.writeMany("})");
        } else {
            array.writeMany("len+%=");
            array.writeFormat(to);
            array.writeMany(".formatLength(.{.value=");
            array.writeMany(arg_string);
            array.writeMany("});\n");
        },
    }
}
fn writeCharacteristic(array: *types.Array, char: u8, extra: *types.Extra) void {
    if (combine_char) return;
    switch (extra.function) {
        .write => |function| {
            if (extra.notation == .slice) {
                array.writeMany("ptr[0]=");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(";\n");
            } else {
                array.writeMany("buf[len]=");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(";\n");
            }
            writeCharacteristic(array, lengthExtra(extra), char);
            extra.function = function;
        },
        .formatWrite => {
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(char));
            array.writeMany(");\n");
        },
        .length => if (combine_len) {
            extra.len.val +%= 1;
        } else {
            array.writeMany("len+%=1;\n");
        },
    }
}
fn writeOptString(
    array: *types.Array,
    opt_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    switch (extra.function) {
        .write => |function| {
            switch (extra.notation) {
                .ptrcast => {
                    array.writeMany("@as(*[");
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len));
                    }
                    array.writeMany("]u8,@ptrCast(buf+len)).*=\"");
                    array.writeMany(opt_string);
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.esc(char));
                    }
                    array.writeMany("\".*;\n");
                },
                .slice => {
                    if (opt_string.len > memcpy_threshold and extra.memcpy == .fmt) {
                        writeWriteString(array, extra);
                        array.writeMany("\"");
                        for (opt_string) |byte| {
                            array.writeMany(fmt.stringLiteralChar(byte));
                        }
                        if (combine_char and char != types.ParamSpec.immediate) {
                            array.writeFormat(fmt.esc(char));
                        }
                        array.writeMany("\");\n");
                    } else {
                        array.writeMany("ptr[");
                        if (combine_char and char != types.ParamSpec.immediate) {
                            array.writeFormat(fmt.ud64(extra.len.val));
                        } else {
                            array.writeFormat(fmt.ud64(extra.len.val));
                        }
                        array.writeMany("..");
                        if (combine_char and char != types.ParamSpec.immediate) {
                            array.writeFormat(fmt.ud64(opt_string.len +% 1 +% extra.len.val));
                        } else {
                            array.writeFormat(fmt.ud64(opt_string.len +% extra.len.val));
                        }
                        array.writeMany("].*=\"");
                        for (opt_string) |byte| {
                            array.writeMany(fmt.stringLiteralChar(byte));
                        }
                        if (combine_char and char != types.ParamSpec.immediate) {
                            array.writeFormat(fmt.esc(char));
                        }
                        array.writeMany("\".*;\n");
                    }
                },
                .memcpy => switch (extra.memcpy) {
                    .builtin => {
                        array.writeMany("@memcpy(buf+len,\"");
                        array.writeMany(opt_string);
                        if (combine_char and char != types.ParamSpec.immediate) {
                            array.writeFormat(fmt.esc(char));
                        }
                        array.writeMany("\");\n");
                    },
                    .fmt => {},
                },
            }
            if (extra.notation == .slice) {
                if (extra.memcpy != .fmt or opt_string.len <= memcpy_threshold) {
                    array.writeMany("ptr+=");
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1 +% extra.len.val));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len +% extra.len.val));
                    }
                    extra.len.val = 0;
                    array.writeMany(";\n");
                }
            } else {
                writeOptString(array, opt_string, char, lengthExtra(extra));
                extra.function = function;
            }
        },
        .formatWrite => {
            array.writeMany("array.writeMany(\"");
            array.writeMany(opt_string);
            if (combine_char and char != types.ParamSpec.immediate) {
                array.writeFormat(fmt.esc(char));
            }
            array.writeMany("\");\n");
        },
        .length => if (combine_len) {
            if (combine_char and char != types.ParamSpec.immediate) {
                extra.len.val +%= opt_string.len +% 1;
            } else {
                extra.len.val +%= opt_string.len;
            }
        } else {
            array.writeMany("len+%=");
            if (combine_char and char != types.ParamSpec.immediate) {
                array.writeFormat(fmt.ud64(opt_string.len +% 1));
            } else {
                array.writeFormat(fmt.ud64(opt_string.len));
            }
            array.writeMany(";\n");
        },
    }
}
fn writeOptStringExtra(
    array: *types.Array,
    opt_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    if (combine_char) {
        writeOptString(array, opt_string, char, extra);
    } else {
        writeOptString(array, opt_string, char, extra);
        if (char != types.ParamSpec.immediate) {
            writeCharacteristic(array, char, extra);
        }
    }
}
fn writeArgStringExtra(
    array: *types.Array,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    writeArgString(array, arg_string, extra);
    if (char != types.ParamSpec.immediate) {
        writeOne(array, char, extra);
    }
}
fn writeOptArgInteger(
    array: *types.Array,
    opt_string: []const u8,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    writeOptStringExtra(array, opt_string, char, extra);
    writeIntegerString(array, arg_string, extra);
    writeNull(array, extra);
}
fn writeOptArgString(
    array: *types.Array,
    opt_string: []const u8,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    writeOptStringExtra(array, opt_string, char, extra);
    writeArgString(array, arg_string, extra);
    writeNull(array, extra);
}
fn writeOptTagString(
    array: *types.Array,
    opt_string: []const u8,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    writeOptStringExtra(array, opt_string, char, extra);
    writeTagString(array, arg_string, extra);
    writeNull(array, extra);
}
fn writeFormatter(
    array: *types.Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, char, extra);
    }
    writeFormatterInternal(array, arg_string, extra);
}
fn writeOptionalFormatter(
    array: *types.Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    char: u8,
    extra: *types.Extra,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, char, extra);
    }
    writeFormatterInternal(array, arg_string, extra);
}
fn writeWriterFunctionBody(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    if (extra.flags.want_fn_intro) {
        writeSetRuntimeSafety(array);
        if (extra.function == .write and extra.notation == .slice) {
            writeDeclarePointer(array);
        }
        if (!combine_len and extra.function == .length) {
            writeDeclareLength(array, extra);
        }
    }
    for (attributes.params) |param_spec| {
        if (!param_spec.flags.do_write) {
            continue;
        }
        if (param_spec.special.write) |write| {
            write(array, param_spec, extra);
            continue;
        }
        if (param_spec.and_no) |no_param_spec| switch (param_spec.tag) {
            .field => |field| switch (no_param_spec.tag) {
                .field => |no_field| switch (field) {
                    .boolean => switch (no_field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                            writeIf(array, param_spec.name, extra);
                            writeOptStringExtra(array, param_spec.string, param_spec.char orelse '\x00', extra);
                            writeElse(array, extra);
                            writeOptStringExtra(array, no_param_spec.string, no_param_spec.char orelse '\x00', extra);
                            writeCloseIf(array, extra);
                            writeCloseIf(array, extra);
                        },
                        .integer => {},
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    .string => switch (no_param_spec.tag.field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                            writeSwitch(array, param_spec.name, extra);
                            writeRequiredProng(array, "yes", "arg");
                            writeOptArgString(array, param_spec.string, "arg", param_spec.char orelse '\x00', extra);
                            writeCloseProng(array, extra);
                            writeProng(array, "no");
                            writeOptStringExtra(array, no_param_spec.string, no_param_spec.char orelse '\x00', extra);
                            writeCloseProng(array, extra);
                            writeCloseIf(array, extra);
                            writeCloseIf(array, extra);
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    .formatter => switch (no_param_spec.tag.field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                            writeSwitch(array, param_spec.name, extra);
                            writeRequiredProng(array, "yes", "arg");
                            writeFormatter(array, param_spec.string, "arg", param_spec.char orelse '\x00', extra);
                            writeCloseProng(array, extra);
                            writeProng(array, "no");
                            writeOptStringExtra(array, no_param_spec.string, no_param_spec.char orelse '\x00', extra);
                            writeCloseProng(array, extra);
                            writeCloseIf(array, extra);
                            writeCloseIf(array, extra);
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
            },
            .optional_field => switch (no_param_spec.tag) {
                .field => |field| switch (field) {
                    .boolean => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeSwitch(array, param_spec.name, extra);
                        writeRequiredProng(array, "yes", "yes");
                        writeIfOptional(array, "yes", "arg", extra);
                        writeOptionalFormatter(array, param_spec.string, "arg", param_spec.char orelse '=', extra);
                        writeElse(array, extra);
                        writeOptStringExtra(array, param_spec.string, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                        writeCloseProng(array, extra);
                        writeProng(array, "no");
                        writeOptStringExtra(array, no_param_spec.string, no_param_spec.char orelse '\x00', extra);
                        writeCloseProng(array, extra);
                        writeCloseIf(array, extra);
                        writeCloseIf(array, extra);
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
            },
            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
        } else switch (param_spec.tag) {
            .param => |param| switch (param) {
                .string => writeArgStringExtra(array, param_spec.name, param_spec.char orelse '\x00', extra),
                .formatter => writeFormatter(array, &.{}, param_spec.name, param_spec.char orelse '\x00', extra),
                .repeatable_formatter => {
                    writeForEach(array, param_spec.name, "value", extra);
                    writeFormatter(array, &.{}, "value", param_spec.char orelse '\x00', extra);
                    writeCloseIf(array, extra);
                },
            },
            .literal => |literal| switch (literal) {
                .string => writeOptStringExtra(array, param_spec.string, param_spec.char orelse '\x00', extra),
                else => unhandledCommandField(param_spec, @src()),
            },
            .field => |field| switch (field) {
                .boolean => {
                    writeIfField(array, param_spec.name, extra);
                    writeOptStringExtra(array, param_spec.string, param_spec.char orelse '\x00', extra);
                    writeCloseIf(array, extra);
                },
                .tag => {
                    writeKindString(array, param_spec.name, extra);
                    writeNull(array, extra);
                },
                .string => {
                    //writeFieldString(array, param_spec.name, extra);
                    //writeNull(array, extra);
                },
                .integer => {},
                else => unhandledCommandField(param_spec, @src()),
            },
            .optional_field => |optional_field| {
                switch (optional_field) {
                    .string => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeOptArgString(array, param_spec.string, param_spec.name, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                    },
                    .tag => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeOptTagString(array, param_spec.string, param_spec.name, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                    },
                    .integer => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeOptArgInteger(array, param_spec.string, param_spec.name, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                    },
                    .formatter => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeFormatter(array, &.{}, param_spec.name, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                    },
                    .mapped => if (param_spec.type.write) |w| {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeMapped(array, &.{}, param_spec.name, w.*, param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                    },
                    .repeatable_formatter => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeForEach(array, param_spec.name, "value", extra);
                        writeFormatter(array, &.{}, "value", param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                        writeCloseIf(array, extra);
                    },
                    .repeatable_string => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeForEach(array, param_spec.name, "value", extra);
                        writeOptArgString(array, param_spec.string, "value", param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                        writeCloseIf(array, extra);
                    },
                    .repeatable_tag => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name, extra);
                        writeForEach(array, param_spec.name, "value", extra);
                        writeOptTagString(array, param_spec.string, "value", param_spec.char orelse '\x00', extra);
                        writeCloseIf(array, extra);
                        writeCloseIf(array, extra);
                    },
                    else => unhandledCommandField(param_spec, @src()),
                }
            },
        }
    }
    if (extra.flags.want_fn_exit) {
        if (extra.function == .write) {
            writeReturnPointer(array);
        }
        if (extra.function == .length) {
            writeReturnLength(array, extra);
        }
    }
}
fn writeWriterFunctionSignature(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    if (context == .Lib) {
        array.writeMany("export fn ");
    } else {
        array.writeMany("pub fn ");
    }
    switch (extra.function) {
        .formatWrite => array.writeMany("formatWrite"),
        .write => array.writeMany("write"),
        .length => array.writeMany("length"),
    }
    if (context == .Lib) {
        array.writeMany(attributes.type_name);
    }
    array.writeMany("(");
    if (extra.function == .write) {
        array.writeMany("buf:[*]u8,");
    }
    array.writeMany(extra.ptr_name);
    array.writeMany(":*");
    if (context == .Lib) {
        array.writeMany("tasks.");
    }
    array.writeMany(attributes.type_name);
    array.writeMany(",");
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param) {
            array.writeMany(param_spec.name);
            array.writeMany(":");
            array.writeFormat(param_spec.type.store.*);
            array.writeMany(",");
        }
    }
    if (extra.function == .length) {
        array.undefine(1);
    }
    if (context == .Lib) {
        switch (extra.function) {
            .length => array.writeMany(")callconv(.C)usize{\n"),
            .write => array.writeMany(")callconv(.C)[*]u8{\n"),
            .formatWrite => array.writeMany("array:anytype)callconv(.C)void{\n"),
            .formatLength => array.writeMany(")callconv(.C)usize{\n"),
        }
    } else {
        switch (extra.function) {
            .length => array.writeMany(")usize{\n"),
            .write => array.writeMany(")[*]u8{\n"),
            .formatWrite => array.writeMany("array:anytype)void{\n"),
        }
    }
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param) {
            if (context == .Lib) {
                if (param_spec.tag.param == .string or
                    param_spec.tag.param == .repeatable_formatter)
                {
                    array.writeMany("const ");
                    array.writeMany(param_spec.name);
                    array.writeMany(":");
                    array.writeFormat(param_spec.type.store.*);
                    array.writeMany("=");
                    array.writeMany(param_spec.name);
                    array.writeMany("_ptr[0..");
                    array.writeMany(param_spec.name);
                    array.writeMany("_len];");
                }
            }
        }
    }
}
fn writeType(fields_array: *types.Array, param_spec: types.ParamSpec) void {
    if (param_spec.and_no) |no_param_spec| {
        const yes_bool: bool = param_spec.tag == .field and param_spec.tag.field == .boolean;
        const no_bool: bool = no_param_spec.tag == .field and no_param_spec.tag.field == .boolean;
        if (yes_bool != no_bool) {
            const new_type: types.BGTypeDescr = .{ .type_ref = .{
                .spec = "?",
                .type = &.{ .type_decl = .{ .defn = .{
                    .spec = "union(enum)",
                    .fields = &.{
                        .{ .name = "yes", .type = if (yes_bool) null else param_spec.type.store.* },
                        .{ .name = "no", .type = if (no_bool) null else no_param_spec.type.store.* },
                    },
                } } },
            } };
            fields_array.writeFormat(new_type);
        } else {
            fields_array.writeFormat(comptime types.BGTypeDescr.init(?bool));
        }
    } else {
        fields_array.writeFormat(param_spec.type.store.*);
    }
}
pub fn writeWriterFunction(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    writeWriterFunctionSignature(array, attributes, extra);
    writeWriterFunctionBody(array, attributes, extra);
    writeCloseFn(array, extra);
}
fn isSquishable(opt_string: []const u8) bool {
    return opt_string.len == 2 and
        opt_string[0] == '-' and
        opt_string[1] != '-';
}
fn writeIncrementArgsIndex(array: *types.Array) void {
    array.writeMany("args_idx+%=1;\n");
}
fn writeStartsWith(array: *types.Array, opt_string: []const u8) void {
    array.writeMany("mem.testEqualString(\"");
    array.writeMany(opt_string);
    array.writeMany("\",");
    writeArgSliceFromTo(array, 0, opt_string.len);
    array.writeMany(")");
}
fn writeEquals(array: *types.Array, opt_string: []const u8) void {
    array.writeMany("mem.testEqualString(\"");
    array.writeMany(opt_string);
    array.writeMany("\",");
    array.writeMany("arg");
    array.writeMany(")");
}
fn writeOpenIfStartsWith(
    array: *types.Array,
    field_name: []const u8,
    opt_string: []const u8,
) void {
    if (config.allow_comptime_configure_parser) {
        array.writeMany("if(spec.");
        array.writeMany(field_name);
        array.writeMany(" and ");
    } else {
        array.writeMany("if(");
    }
    writeStartsWith(array, opt_string);
    array.writeMany("){\n");
}
fn writeOpenIfEqualTo(
    array: *types.Array,
    field_name: []const u8,
    opt_string: []const u8,
) void {
    if (config.allow_comptime_configure_parser) {
        array.writeMany("if(spec.");
        array.writeMany(field_name);
        array.writeMany(" and ");
    } else {
        array.writeMany("if(");
    }
    writeEquals(array, opt_string);
    array.writeMany("){\n");
}
fn writeOpenOptionalField(
    array: *types.Array,
    field_name: []const u8,
    capture_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany("if(");
    writeFieldAccess(array, field_name, extra);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeMemcpy(
    array: *types.Array,
    dest: []const u8,
    src: []const u8,
) void {
    array.writeMany("for(");
    array.writeMany(dest);
    array.writeMany(",");
    array.writeMany(src);
    array.writeMany(")|*xx,yy|xx.*=yy;\n");
}
fn writeParseArgsFrom(
    array: *types.Array,
    type_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany(type_name);
    switch (extra.language) {
        .C => array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg)"),
        .Zig => array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg)"),
    }
}
fn writeAllocateRaw(array: *types.Array, type_name: []const u8, mb_size: ?usize, mb_alignment: ?usize) void {
    array.writeMany("const dest:[*]");
    array.writeMany(type_name);
    array.writeMany("=@ptrFromInt(allocator.allocateRaw(");
    if (mb_size) |size| {
        array.writeFormat(fmt.ud64(size));
    } else {
        array.writeMany("@sizeOf(");
        array.writeMany(type_name);
        array.writeMany(")");
    }
    array.writeMany(",");
    if (mb_alignment) |alignment| {
        array.writeFormat(fmt.ud64(alignment));
    } else {
        array.writeMany("@alignOf(");
        array.writeMany(type_name);
        array.writeMany("),");
    }
    array.writeMany("));\n");
}
fn writeAllocateRawIncrement(array: *types.Array, type_name: []const u8, mb_size: ?usize, mb_alignment: ?usize) void {
    if (false) {
        array.writeMany("const dest: [*]");
        array.writeMany(type_name);
        array.writeMany(" = @ptrFromInt(allocator.addGeneric(");
        if (mb_size) |size| {
            array.writeFormat(fmt.ud64(size));
        } else {
            array.writeMany("@sizeOf(");
            array.writeMany(type_name);
            array.writeMany(")");
        }
        array.writeMany(" *% (src.len +% 1),");
        if (mb_alignment) |alignment| {
            array.writeFormat(fmt.ud64(alignment));
            array.writeMany(",");
        } else {
            array.writeMany("@alignOf(");
            array.writeMany(type_name);
            array.writeMany("),");
        }
        array.writeMany("src.len,");
        array.writeMany("@ptrCast(@constCast(src.ptr)),");
        array.writeMany("&src.len,");
        array.writeMany("src.len +% 1");
        array.writeMany("));");
    } else {
        array.writeMany("const dest:[*]");
        array.writeMany(type_name);
        array.writeMany("=@ptrFromInt(allocator.allocateRaw(");
        if (mb_size) |size| {
            array.writeFormat(fmt.ud64(size));
        } else {
            array.writeMany("@sizeOf(");
            array.writeMany(type_name);
            array.writeMany(")");
        }
        array.writeMany("*%(src.len+%1),");
        if (mb_alignment) |alignment| {
            array.writeFormat(fmt.ud64(alignment));
        } else {
            array.writeMany("@alignOf(");
            array.writeMany(type_name);
            array.writeMany("),");
        }
        array.writeMany("));\n");
    }
}
fn writeAddOptionalRepeatableFormatter(
    array: *types.Array,
    field_name: []const u8,
    type_name: []const u8,
    extra: *types.Extra,
) void {
    writeOpenOptionalField(array, field_name, "src", extra);
    writeAllocateRawIncrement(array, type_name, null, null);
    writeMemcpy(array, "dest", "src");
    array.writeMany("dest[src.len]=");
    writeParseArgsFrom(array, type_name, extra);
    array.writeMany(";\n");
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..src.len+%1];\n");
    writeElse(array, extra);
    writeAllocateRaw(array, type_name, null, null);
    array.writeMany("dest[0]=");
    writeParseArgsFrom(array, type_name, extra);
    array.writeMany(";\n");
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..1];\n");
    writeCloseIf(array, extra);
}
fn writeAddOptionalFormatter(
    array: *types.Array,
    field_name: []const u8,
    type_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=");
    writeParseArgsFrom(array, type_name, extra);
    array.writeMany(";\n");
}
fn writeAddOptionalRepeatableString(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    writeOpenOptionalField(array, field_name, "src", extra);
    writeAllocateRawIncrement(array, "[]const u8", 16, 8);
    writeMemcpy(array, "dest", "src");
    array.writeMany("dest[src.len]=arg;\n");
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..src.len+%1];\n");
    writeElse(array, extra);
    writeAllocateRaw(array, "[]const u8", 16, 8);
    array.writeMany("dest[0]=arg;\n");
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..1];\n");
    writeCloseIf(array, extra);
}
fn writeAddOptionalRepeatableTag(
    array: *types.Array,
    field_name: []const u8,
    type_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany("const ");
    array.writeMany(field_name);
    array.writeMany(":*");
    array.writeMany(type_name);
    array.writeMany("=blk:{");
    writeOpenOptionalField(array, field_name, "src", extra);
    writeAllocateRawIncrement(array, type_name, null, null);
    array.writeMany("for(dest,src)|*ptr,val|ptr.*=val;\n");
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..src.len+%1];\n");
    array.writeMany("break:blk &dest[src.len];\n");
    writeElse(array, extra);
    writeAllocateRaw(array, type_name, null, null);
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=dest[0..1];\n");
    array.writeMany("break:blk &dest[0];\n");
    writeCloseIf(array, extra);
    array.writeMany("};\n");
}
fn writeArgsLen(array: *types.Array, extra: *types.Extra) void {
    switch (extra.language) {
        .C => array.writeMany("args_len"),
        .Zig => array.writeMany("args.len"),
    }
}
fn writeReturnIfIndexEqualToLength(array: *types.Array, extra: *types.Extra) void {
    array.writeMany("if(args_idx==");
    writeArgsLen(array, extra);
    array.writeMany("){\n");
    array.writeMany("return;\n");
    array.writeMany("}\n");
}
fn writeShiftArgs(array: *types.Array) void {
    array.writeMany("proc.shift(&args, args_idx);\n");
}
fn writeAssignIfIndexNotEqualToLength(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany("if(args_idx!=");
    writeArgsLen(array, extra);
    array.writeMany("){\n");
    writeAssignArgCurIndex(array, field_name, extra);
    writeElse(array, extra);
    array.writeMany("return;\n");
    writeCloseIf(array, extra);
}
fn writeAssignIfIntegerIfIndexNotEqualToLength(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    array.writeMany("if(args_idx!=");
    writeArgsLen(array, extra);
    array.writeMany("){\n");
    writeAssignIfIntegerArgCurIndex(array, field_name, extra);
    writeElse(array, extra);
    array.writeMany("return;\n");
    writeCloseIf(array, extra);
}
fn writeArgCurIndex(array: *types.Array) void {
    array.writeMany("mem.terminate(args[args_idx],0)");
}
fn writeArgAnyIndex(array: *types.Array, index: usize) void {
    array.writeMany("mem.terminate(args[");
    array.writeFormat(fmt.ud64(index));
    array.writeMany("],0)");
}
fn writeArgAddIndex(array: *types.Array, offset: usize) void {
    array.writeMany("mem.terminate(args[args_idx+%");
    array.writeFormat(fmt.ud64(offset));
    array.writeMany("],0)");
}
fn writeByteAtIndex(array: *types.Array, offset: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(offset));
    array.writeMany("]");
}
fn writeArgSliceFrom(array: *types.Array, index: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(index));
    array.writeMany("..]");
}
fn writeArgSliceFromTo(array: *types.Array, start: usize, end: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(start));
    array.writeMany("..@min(arg.len,");
    array.writeFormat(fmt.ud64(end));
    array.writeMany(")]");
}
fn writeAssignCurIndex(array: *types.Array) void {
    array.writeMany("arg=");
    writeArgCurIndex(array);
    array.writeMany(";\n");
}
fn writeNext(array: *types.Array, extra: *types.Extra) void {
    writeIncrementArgsIndex(array);
    writeReturnIfIndexEqualToLength(array, extra);
    writeAssignCurIndex(array);
}
fn writeCmpArgLength(array: *types.Array, symbol: []const u8, length: usize) void {
    array.writeMany("arg.len");
    array.writeMany(symbol);
    array.writeFormat(fmt.ud64(length));
}
fn writeCmpByteAtIndex(array: *types.Array, symbol: []const u8, byte: u8, index: usize) void {
    writeByteAtIndex(array, index);
    array.writeMany(symbol);
    array.writeOne('\'');
    array.writeOne(byte);
    array.writeOne('\'');
}
fn writeOpenIfArgCmpLength(array: *types.Array, symbol: []const u8, length: usize) void {
    array.writeMany("if(");
    writeCmpArgLength(array, symbol, length);
    array.writeMany("){\n");
}
fn writeAssignArgToArgFrom(array: *types.Array, offset: usize) void {
    array.writeMany("arg=");
    writeArgSliceFrom(array, offset);
    array.writeMany(";\n");
}
fn writeNextIfArgEqualToLength(
    array: *types.Array,
    length: usize,
    extra: *types.Extra,
) void {
    writeOpenIfArgCmpLength(array, "==", length);
    writeNext(array, extra);
    writeElse(array, extra);
    writeAssignArgToArgFrom(array, length);
    writeCloseIf(array, extra);
}
fn writeAssignArgNextIfArgEqualToLength(
    array: *types.Array,
    length: usize,
    extra: *types.Extra,
) void {
    writeOpenIfArgCmpLength(array, "==", length);
    writeNext(array, extra);
    writeElse(array, extra);
    writeAssignArgToArgFrom(array, length);
    writeCloseIf(array, extra);
}
fn writeAssignTagToPtr(
    array: *types.Array,
    field_name: []const u8,
    tag_name: []const u8,
) void {
    array.writeMany(field_name);
    array.writeMany(".*=.");
    array.writeFormat(fmt.IdentifierFormat{ .value = tag_name });
    array.writeMany(";\n");
}
fn writeAssignTag(
    array: *types.Array,
    field_name: []const u8,
    tag_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=.");
    array.writeFormat(fmt.IdentifierFormat{ .value = tag_name });
    array.writeMany(";\n");
}
fn writeAssignBoolean(
    array: *types.Array,
    field_name: []const u8,
    value: bool,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeOne('=');
    array.writeMany(if (value) "true" else "false");
    array.writeMany(";\n");
}
fn writeAssignArg(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=arg;\n");
}
fn writeAssignIfIntegerArg(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=parse.noexcept.unsigned(arg);\n");
}
fn writeAssignIfIntegerArgCurIndex(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=parse.noexcept.unsigned(");
    writeArgCurIndex(array);
    array.writeMany(");\n");
}
fn writeAssignArgCurIndex(
    array: *types.Array,
    field_name: []const u8,
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=");
    writeArgCurIndex(array);
    array.writeMany(";\n");
}
fn writeOpenIfOptional(
    array: *types.Array,
    field_name: []const u8,
    opt_string: []const u8,
    char: u8,
) void {
    writeOpenIfStartsWith(array, field_name, opt_string);
    array.writeMany("if(");
    writeCmpArgLength(array, ">", opt_string.len +% 1);
    array.writeMany(" and ");
    writeCmpByteAtIndex(array, "==", char, opt_string.len);
    array.writeMany("){\n");
}
fn writeAssignSpecifier(
    array: *types.Array,
    field_name: []const u8,
    specifier: union(enum) { yes: ?[]const u8, no: ?[]const u8 },
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=");
    switch (specifier) {
        .yes => |mb_string| {
            if (mb_string) |string| {
                array.writeMany(".{.yes=");
                array.writeMany(string);
                array.writeMany("};\n");
            } else {
                array.writeMany(".yes;\n");
            }
        },
        .no => |mb_string| {
            if (mb_string) |string| {
                array.writeMany(".{.no=");
                array.writeMany(string);
                array.writeMany("};\n");
            } else {
                array.writeMany(".no;\n");
            }
        },
    }
}
fn writeAssignSpecifierFormatParser(
    array: *types.Array,
    field_name: []const u8,
    offset: usize,
    specifier: union(enum) { yes: types.BGTypeDescr, no: types.BGTypeDescr },
    extra: *types.Extra,
) void {
    writeFieldAccess(array, field_name, extra);
    array.writeMany("=");
    switch (specifier) {
        .yes => |type_descr| {
            array.writeMany(".{.yes=");
            array.writeFormat(type_descr);
            switch (extra.language) {
                .C => array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg["),
                .Zig => array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg["),
            }
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..],)};\n");
        },
        .no => |type_descr| {
            array.writeMany(".{.no=");
            array.writeFormat(type_descr);
            switch (extra.language) {
                .C => array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg["),
                .Zig => array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg["),
            }
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..],)};\n");
        },
    }
}
fn writeParserFunctionBody(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    if (extra.flags.want_fn_intro) {
        writeSetRuntimeSafety(array);
        array.writeMany("var args:[][*:0]u8=allocator.allocate([*:0]u8,args_in.len);\n");
        array.writeMany("var args_idx:usize=0;\n");
        array.writeMany("var arg:[:0]u8=undefined;\n");
        array.writeMany("@memcpy(args[0..args_in.len], args_in.ptr);\n");
        array.writeMany("while(args_idx!=args.len){\n");
        array.writeMany("arg=mem.terminate(args[args_idx],0);\n");
    }
    for (attributes.params) |param_spec| {
        if (!param_spec.flags.do_parse) {
            continue;
        }
        if (param_spec.special.parse) |parse| {
            parse(array, param_spec, extra);
            continue;
        }
        if (param_spec.string.len == 0) {
            continue;
        }
        if (param_spec.and_no) |no_param_spec| {
            switch (param_spec.tag) {
                .literal => {},
                .param => {},
                .field => |field| switch (no_param_spec.tag) {
                    .field => |no_field| switch (field) {
                        .boolean => switch (no_field) {
                            .boolean => {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeAssignBoolean(array, param_spec.name, true, extra);
                                writeIfElse(array, extra);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignBoolean(array, param_spec.name, false, extra);
                                writeIfElse(array, extra);
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        .string => switch (no_field) {
                            .boolean => {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array, extra);
                                writeAssignSpecifier(array, param_spec.name, .{ .yes = "arg" }, extra);
                                writeIfElse(array, extra);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignSpecifier(array, param_spec.name, .{ .no = null }, extra);
                                writeIfElse(array, extra);
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        .formatter => switch (no_field) {
                            .boolean => {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeIfElse(array, extra);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignBoolean(array, param_spec.name, false, extra);
                                writeIfElse(array, extra);
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                .optional_field => |optional_field| switch (no_param_spec.tag) {
                    .field => |no_field| switch (optional_field) {
                        .formatter => switch (no_field) {
                            .boolean => {
                                if (param_spec.type.parse) |p| {
                                    writeOpenIfOptional(array, param_spec.name, param_spec.string, param_spec.char orelse '=');
                                    writeAssignSpecifierFormatParser(
                                        array,
                                        param_spec.name,
                                        param_spec.string.len +% 1,
                                        .{ .yes = p.* },
                                        extra,
                                    );
                                    writeElse(array, extra);
                                    writeAssignSpecifier(array, param_spec.name, .{ .yes = "null" }, extra);
                                    writeCloseIf(array, extra);
                                    writeIfElse(array, extra);
                                    writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                    writeAssignSpecifier(array, param_spec.name, .{ .no = null }, extra);
                                    writeIfElse(array, extra);
                                }
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
            }
        } else {
            switch (param_spec.tag) {
                .field => |field| switch (field) {
                    .boolean => {
                        writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                        writeAssignBoolean(array, param_spec.name, true, extra);
                        writeIfElse(array, extra);
                    },
                    .tag => {
                        writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                        writeIfElse(array, extra);
                    },
                    .repeatable_task => {},
                    else => unhandledCommandField(param_spec, @src()),
                },
                .optional_field => |optional_field| switch (optional_field) {
                    .string => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            writeAssignArg(array, param_spec.name, extra);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeIncrementArgsIndex(array);
                            writeAssignIfIndexNotEqualToLength(array, param_spec.name, extra);
                        }
                        writeIfElse(array, extra);
                    },
                    .integer => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            writeAssignIfIntegerArg(array, param_spec.name, extra);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeIncrementArgsIndex(array);
                            writeAssignIfIntegerIfIndexNotEqualToLength(array, param_spec.name, extra);
                        }
                        writeIfElse(array, extra);
                    },
                    .tag => {
                        if (param_spec.type.parse) |p| {
                            if (isSquishable(param_spec.string)) {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            } else {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array, extra);
                            }
                            if (p.type_decl.defn) |d| {
                                for (d.fields) |field| {
                                    writeOpenIfEqualTo(array, param_spec.name, field.name);
                                    writeAssignTag(array, param_spec.name, field.name, extra);
                                    writeIfElse(array, extra);
                                }
                                array.undefine(5);
                            }
                            writeIfElse(array, extra);
                        }
                    },
                    .mapped => {
                        if (param_spec.type.parse) |p| {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeAddOptionalFormatter(
                                array,
                                param_spec.name,
                                p.type_decl.name.?,
                                extra,
                            );
                            writeIfElse(array, extra);
                        }
                    },
                    .repeatable_string => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeNext(array, extra);
                        }
                        writeAddOptionalRepeatableString(array, param_spec.name, extra);
                        writeIfElse(array, extra);
                    },
                    .repeatable_tag => {
                        if (param_spec.type.parse) |p| {
                            if (isSquishable(param_spec.string)) {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            } else {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array, extra);
                            }
                            writeAddOptionalRepeatableTag(array, param_spec.name, p.type_decl.name.?, extra);
                            for (param_spec.type.store.type_ref.type.type_ref.type.type_decl.defn.?.fields) |field| {
                                writeOpenIfEqualTo(array, param_spec.name, field.name);
                                writeAssignTagToPtr(array, param_spec.name, field.name);
                                writeIfElse(array, extra);
                            }
                            array.undefine(5);
                            writeIfElse(array, extra);
                        }
                    },
                    .repeatable_formatter => {
                        if (param_spec.type.parse) |p| {
                            if (isSquishable(param_spec.string)) {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            } else {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array, extra);
                            }
                            writeAddOptionalRepeatableFormatter(
                                array,
                                param_spec.name,
                                p.type_decl.name.?,
                                extra,
                            );
                            writeIfElse(array, extra);
                        }
                    },
                    .formatter => {
                        if (param_spec.type.parse) |parse| {
                            if (isSquishable(param_spec.string)) {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeNextIfArgEqualToLength(array, param_spec.string.len, extra);
                            } else {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array, extra);
                            }
                            writeAddOptionalFormatter(
                                array,
                                param_spec.name,
                                parse.type_decl.name.?,
                                extra,
                            );
                            writeIfElse(array, extra);
                        }
                    },
                    else => unhandledCommandField(param_spec, @src()),
                },
                .literal => {},
                else => unhandledCommandField(param_spec, @src()),
            }
        }
    }
    if (extra.flags.want_fn_exit) {
        array.undefine(5);
        array.writeMany("else{\n");
        array.writeMany("args_idx+%=1;\n");
        array.writeMany("continue;\n");
        writeCloseIf(array, extra);
        writeShiftArgs(array);
        writeCloseIf(array, extra);
    }
}
fn writeParserFunctionSpec(array: *types.Array, attributes: types.Attributes) void {
    if (config.allow_comptime_configure_parser) {
        array.writeMany("pub const ");
        array.writeMany(attributes.type_name);
        array.writeMany("ParserSpec=packed struct{\n");
        for (attributes.params) |param_spec| {
            if (param_spec.name.len != 0) {
                array.writeMany(param_spec.name);
                array.writeMany(if (param_spec.flags.do_parse) ":bool=true,\n" else ":bool=false,\n");
            }
        }
        array.writeMany("};\n");
    }
}
fn writeParserFunctionSignature(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    switch (extra.language) {
        .C => {
            array.writeMany("export fn formatParseArgs");
            array.writeMany(attributes.type_name);
        },
        .Zig => array.writeMany("pub fn formatParseArgs"),
    }
    array.writeMany("(");
    array.writeMany(extra.ptr_name);
    array.writeMany(":*");
    if (context == .Lib) {
        array.writeMany("tasks.");
    }
    array.writeMany(attributes.type_name);
    switch (extra.language) {
        .C => array.writeMany(",allocator:*types.Allocator,args_in:[*][*:0]u8,args_len:usize)void{\n"),
        .Zig => array.writeMany(",allocator:*types.Allocator,args_in:[][*:0]u8)void{\n"),
    }
}
fn writeFlagWithInverse(array: *types.Array, param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var yes_idx: usize = 0;
    var no_idx: usize = 0;
    var no: bool = false;
    const yes_string: []const u8 = param_spec.string;
    const no_string: []const u8 = no_param_spec.string;
    var yes_array: types.Array256 = undefined;
    var no_array: types.Array256 = undefined;
    yes_array.undefineAll();
    no_array.undefineAll();
    while (true) {
        if (no_idx == no_string.len) {
            break;
        }
        if (yes_idx == yes_string.len) {
            break;
        }
        const yes_slice: []const u8 = yes_string[yes_idx..];
        const no_slice: []const u8 = no_string[no_idx..];
        if (yes_string[yes_idx] == no_string[no_idx]) {
            if (no) {
                if (mem.testEqualString(yes_slice, no_slice)) {
                    if (yes_array.len() != 0 and no_array.len() != 0) {
                        array.writeOne('(');
                        array.writeMany(yes_array.readAll());
                        array.writeOne('|');
                        array.writeMany(no_array.readAll());
                        array.writeOne(')');
                    } else if (no_array.len() != 0) {
                        array.writeOne('[');
                        array.writeMany(no_array.readAll());
                        array.writeOne(']');
                    }
                    break array.writeMany(yes_slice);
                } else {
                    if (yes_slice.len > no_slice.len) {
                        yes_array.writeOne(yes_string[yes_idx]);
                        yes_idx +%= 1;
                    } else {
                        no_array.writeOne(no_string[no_idx]);
                        no_idx +%= 1;
                    }
                }
            } else {
                array.writeOne(yes_string[yes_idx]);
                yes_idx +%= 1;
                no_idx +%= 1;
            }
        } else {
            no = true;
            if (yes_slice.len > no_slice.len) {
                yes_array.writeOne(yes_string[yes_idx]);
                yes_idx +%= 1;
            } else {
                no_array.writeOne(no_string[no_idx]);
                no_idx +%= 1;
            }
        }
    }
    if (param_spec.char) |char| {
        array.writeOne('[');
        array.writeOne(char);
        array.writeOne(']');
    }
}
fn writeParserFunctionExternSignature(array: *types.Array, attributes: types.Attributes) void {
    array.writeMany("formatParseArgs");
    array.writeMany(attributes.type_name);
    array.writeMany(":*fn(*types.");
    array.writeMany(attributes.type_name);
    array.writeMany(",*types.Allocator,[*][*:0]u8,usize)void = @ptrFromInt(8),\n");
}
fn writeWriterFunctionExternSignature(array: *types.Array, attributes: types.Attributes, extra: *types.Extra) void {
    if (extra.function == .formatWriteBuf) {
        array.writeMany("formatWriteBuf");
    } else {
        array.writeMany("formatLength");
    }
    array.writeMany(attributes.type_name);
    array.writeMany(":*fn(*types.");
    array.writeMany(attributes.type_name);
    array.writeMany(",");
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param) {
            switch (param_spec.tag.param) {
                .string, .repeatable_formatter => {
                    array.writeMany("[*]const ");
                    if (param_spec.type.write) |wrty| {
                        wrty.formatWrite(array);
                    } else {
                        array.writeMany("u8");
                    }
                    array.writeMany(",usize");
                },
                else => {
                    param_spec.type.store.formatWrite(array);
                },
            }
            array.writeMany(",");
        }
    }
    if (extra.function == .formatLength or
        extra.function == .length)
    {
        array.undefine(1);
    }
    switch (extra.function) {
        .formatWrite => array.writeMany("anytype)void"),
        .length => array.writeMany(")callconv(.C)usize{\n"),
        .write => array.writeMany(")callconv(.C)[*]u8{\n"),
    }
    array.writeMany(" = @ptrFromInt(8),\n");
}
fn generatePanicCauseParameters() []const u8 {
    const fields = @typeInfo(safety.RuntimeSafetyCheck).Struct.fields;
    comptime var params: [fields.len]types.ParamSpec = undefined;
    inline for (fields, 0..) |field, field_idx| {
        comptime var descr: []const []const u8 = &.{"Enables panic causes:"};
        inline for (comptime safety.RuntimeSafetyCheck.causes(@field(safety.RuntimeSafetyCheck.Tag, field.name))) |cause| {
            descr = descr ++ [1][]const u8{"  " ++ @tagName(cause)};
        }
        const name: []const u8 = "panic_" ++ field.name;
        comptime var string: [name.len]u8 = undefined;
        comptime {
            for (name, 0..) |byte, idx| {
                if (byte == '_') {
                    string[idx] = '-';
                } else {
                    string[idx] = byte;
                }
            }
        }
        params[field_idx] = types.ParamSpec{
            .name = name,
            .string = "-f" ++ string,
            .and_no = .{ .string = "-fno-" ++ string },
            .descr = descr,
        };
    }
    return params;
}
fn unhandledCommandFieldAndNo(param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    @memcpy(buf[len..].ptr, param_spec.name);
    len +%= param_spec.name.len;
    buf[len..][0..5].* = "tag: ".*;
    len +%= 5;
    len +%= fmt.render(.{ .infer_type_names = true }, no_param_spec.tag).formatWriteBuf(buf[len..].ptr);
    buf[len..][0..2].* = ", ".*;
    len +%= 2;
    @panic(buf[0..len]);
}
fn unhandledCommandField(param_spec: types.ParamSpec, src: anytype) void {
    var buf: [4096]u8 = undefined;
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, param_spec.name);
    ptr[0..5].* = "tag: ".*;
    ptr += fmt.sourceLocation(src, @returnAddress()).formatWriteBuf(ptr);
    ptr[0..2].* = ": ".*;
    ptr += 2;
    ptr += fmt.render(.{ .infer_type_names = true }, param_spec.tag).formatWriteBuf(ptr);
    @panic(fmt.slice(ptr, &buf));
}
pub fn writeParserFunction(
    array: *types.Array,
    attributes: types.Attributes,
    extra: *types.Extra,
) void {
    writeParserFunctionSignature(array, attributes, extra);
    writeParserFunctionBody(array, attributes, extra);
    writeCloseIf(array, extra);
    writeParserFunctionSpec(array, attributes);
}
fn simplifyArgumentHelper(param_spec: types.ParamSpec) []const u8 {
    switch (param_spec.tag) {
        inline .field, .optional_field => |f| switch (f) {
            .boolean => return "",
            inline .tag, .string, .integer => |_, tag| if (isSquishable(param_spec.string))
                return ("<" ++ @tagName(tag) ++ ">")
            else
                return ("=<" ++ @tagName(tag) ++ ">"),
            else => if (isSquishable(param_spec.string))
                return "<string>"
            else
                return "=<string>",
        },
        else => return "",
    }
}
pub fn writeParserFunctionHelp(array: *types.Array, attributes: types.Attributes) void {
    array.writeMany("const ");
    array.writeMany(attributes.fn_name);
    array.writeMany("_help:[:0]const u8=");
    var max_width: usize = 0;
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param or
            param_spec.tag == .literal or
            param_spec.string.len == 0)
        {
            continue;
        }
        const helper: []const u8 = simplifyArgumentHelper(param_spec);
        if (param_spec.string.len != 0) {
            const start: usize = array.len();
            if (param_spec.and_no) |no_param_spec| {
                if (param_spec.tag == .field and param_spec.tag.field == .boolean) {
                    writeFlagWithInverse(array, param_spec, no_param_spec);
                } else {
                    array.writeMany(param_spec.string);
                }
            } else {
                array.writeMany(param_spec.string);
            }
            const finish: usize = array.len();
            max_width = @max(max_width, bits.alignA64(4 +% (finish -% start) +% helper.len, 4));
            array.undefine(finish -% start);
        }
    }
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param or
            param_spec.tag == .literal or
            param_spec.string.len == 0)
        {
            continue;
        }
        const helper: []const u8 = simplifyArgumentHelper(param_spec);
        if (param_spec.tag == .field and
            param_spec.tag.field == .boolean)
        {
            if (param_spec.string.len != 0) {
                array.writeMany("\\\\    ");
                const start: usize = array.len();
                if (param_spec.and_no) |no_param_spec| {
                    writeFlagWithInverse(array, param_spec, no_param_spec);
                } else {
                    array.writeMany(param_spec.string);
                }
                const finish: usize = array.len();
                const string_len: usize = finish -% start;
                if (param_spec.descr.len != 0) {
                    for (0..max_width -% string_len) |_| array.writeOne(' ');
                    array.writeMany(param_spec.descr[0]);
                    for (param_spec.descr[1..]) |string| {
                        array.writeMany("\n\\\\    ");
                        for (0..max_width) |_| array.writeOne(' ');
                        array.writeMany(string);
                    }
                }
                array.writeMany("\n");
            }
        } else {
            array.writeMany("\\\\    ");
            const start: usize = array.len();
            array.writeMany(param_spec.string);
            array.writeMany(helper);
            const finish: usize = array.len();
            const string_len: usize = finish -% start;
            if (param_spec.descr.len != 0) {
                for (0..max_width -% string_len) |_| array.writeOne(' ');
                array.writeMany(param_spec.descr[0]);
                for (param_spec.descr[1..]) |string| {
                    array.writeMany("\n\\\\    ");
                    for (0..max_width) |_| array.writeOne(' ');
                    array.writeMany(string);
                }
            }
            array.writeMany("\n");
            if (param_spec.and_no) |no_param_spec| {
                array.writeMany("\\\\    ");
                array.writeMany(no_param_spec.string);
                array.writeMany("\n");
            }
        }
    }
    array.writeMany("\\\\\n");
    array.writeMany("\\\\\n");
    array.writeMany("\n;");
}
pub fn writeCommandStruct(array: *types.Array, language: types.Extra.Language, attributes_set: []const types.Attributes) void {
    switch (language) {
        .Zig => {
            array.writeMany("pub const Command=struct{\n");
            for (attributes_set) |attributes| {
                array.writeMany(attributes.fn_name);
                array.writeMany(":*");
                array.writeMany(attributes.type_name);
                array.writeMany(",\n");
            }
            array.writeMany("};\n");
        },
        .C => {},
    }
}
pub fn writeFields(array: *types.Array, language: types.Extra.Language, attributes: types.Attributes) void {
    var types_array: types.Array2 = undefined;
    switch (language) {
        .Zig => {
            types_array.undefineAll();
            for (attributes.params) |param_spec| {
                if (!param_spec.flags.do_write) {
                    continue;
                }
                if (param_spec.name.len == 0) {
                    continue;
                }
                if (param_spec.tag == .field or
                    param_spec.tag == .optional_field)
                {
                    for (param_spec.descr) |line| {
                        if (line.len != 0) {
                            array.writeMany("/// ");
                            array.writeMany(line);
                            array.writeMany("\n");
                        }
                    }
                    array.writeMany(param_spec.name);
                    array.writeMany(":");
                    writeType(array, param_spec);
                    if (param_spec.tag == .field) {
                        array.writeMany("=");
                        if (param_spec.default) |default_value| {
                            array.writeMany(default_value);
                        } else if (param_spec.and_no != null) {
                            array.writeMany("null");
                        } else if (param_spec.tag.field == .boolean) {
                            array.writeMany("false");
                        } else {
                            array.undefine(1);
                        }
                    }
                    if (param_spec.tag == .optional_field) {
                        array.writeMany("=null");
                    }
                    array.writeMany(",\n");
                }
            }
            array.writeMany(types_array.readAll());
        },
        .C => {
            types_array.undefineAll();
            for (attributes.params) |param_spec| {
                if (!param_spec.flags.do_write) {
                    continue;
                }
                if (param_spec.name.len == 0) {
                    continue;
                }
                if (param_spec.tag == .field or
                    param_spec.tag == .optional_field)
                {
                    for (param_spec.descr) |line| {
                        if (line.len != 0) {
                            array.writeMany("/// ");
                            array.writeMany(line);
                            array.writeMany("\n");
                        }
                    }
                    writeType(array, param_spec);
                    array.writeMany(" ");
                    array.writeMany(param_spec.name);
                    array.writeMany(";\n");
                }
            }
            array.writeMany(types_array.readAll());
        },
    }
}
pub fn writeDeclarations(array: *types.Array, language: types.Extra.Language, attributes: types.Attributes) void {
    for (attributes.type_decls) |type_decl| {
        array.writeFormat(type_decl);
    }
    writeAllocateRawDecls(array, language);
}
pub fn writeWriterFunctions(array: *types.Array, attributes: types.Attributes) void {
    writeWriterFunction(array, attributes, .{ .function = .write, .language = .Zig, .notation = .slice });
    writeWriterFunction(array, attributes, .{ .function = .length, .language = .Zig });
    if (context == .Exe) {
        writeWriterFunction(array, attributes, .{ .function = .formatWrite, .language = .Zig });
    }
}
pub fn writeFunctionExternSignatures(array: *types.Array, attribute: types.Attributes) void {
    writeParserFunctionExternSignature(array, attribute);
    writeWriterFunctionExternSignature(array, attribute, .write);
    writeWriterFunctionExternSignature(array, attribute, .length);
}
pub fn writeWriteModules(array: *types.Array, param_spec: types.ParamSpec, extra: *types.Extra) void {
    if (combine_len) {
        writeCombinedLength(array, extra);
    }
    array.writeMany("for(");
    writeFieldAccess(array, "mods", extra);
    array.writeMany(",0..)|mod,mod_idx|{\n");
    const ptr_name: []const u8 = extra.ptr_name;
    const flags: types.Extra.Flags = extra.flags;
    extra.ptr_name = "mod";
    extra.flags = .{
        .want_fn_exit = false,
        .want_fn_intro = false,
    };
    writeWriterFunctionBody(array, param_spec.tag.field.repeatable_task.*, extra);
    writeFieldString(array, "name", extra);
    writeNull(array, extra);
    writeCombinedLength(array, extra);
    switch (extra.function) {
        .write => {
            array.writeMany("ptr=file.CompoundPath.write(ptr, zig_mod_paths[mod_idx]);\n");
        },
        .length => {
            array.writeMany("len+%=file.CompoundPath.length(zig_mod_paths[mod_idx]);\n");
        },
        .formatWrite => {
            array.writeMany("zig_mod_paths[mod_idx]].formatWrite(array);\n");
        },
    }
    extra.ptr_name = ptr_name;
    extra.flags = flags;
    writeCloseIf(array, extra);
}
pub fn writeParseModules(array: *types.Array, param_spec: types.ParamSpec, extra: *types.Extra) void {
    const ptr_name: []const u8 = extra.ptr_name;
    const flags: types.Extra.Flags = extra.flags;
    extra.ptr_name = "cmd.mods[0]";
    extra.flags = .{
        .want_fn_exit = false,
        .want_fn_intro = false,
    };
    writeParserFunctionBody(array, param_spec.tag.field.repeatable_task.*, extra);
    extra.ptr_name = ptr_name;
    extra.flags = flags;
}
