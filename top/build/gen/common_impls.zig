const fmt = @import("../../fmt.zig");
const mem = @import("../../mem.zig");
const mach = @import("../../mach.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
const context: types.Context = @import("root").context;
const notation: enum { slice, ptrcast, memcpy } = .slice;
const memcpy: enum { builtin, mach } = .builtin;
const combine_char: bool = true;
pub const Array = mem.StaticString(64 * 1024 * 1024);
pub const Array2 = mem.StaticString(64 * 1024);
pub const Array256 = mem.StaticString(256);
fn writeSetRuntimeSafety(array: *Array) void {
    array.writeMany("@setRuntimeSafety(false);\n");
}
fn writeDeclareLength(array: *Array) void {
    array.writeMany("var len:usize=0;\n");
}
fn writeDeclarePointer(array: *Array) void {
    array.writeMany("var ptr:[*]u8=buf;\n");
}
fn writeReturnLength(array: *Array) void {
    array.writeMany("return len;\n");
}
fn writeReturnPointerDiff(array: *Array) void {
    array.writeMany("return @intFromPtr(ptr)-%@intFromPtr(buf);\n");
}
fn writeIf(array: *Array, value_name: []const u8) void {
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany("){\n");
}
fn writeIfField(array: *Array, field_name: []const u8) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeIfOptionalField(array: *Array, field_name: []const u8, capture_name: []const u8) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeIfOptional(array: *Array, value_name: []const u8, capture_name: []const u8) void {
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeForEach(array: *Array, values_name: []const u8, value_name: []const u8) void {
    array.writeMany("for(");
    array.writeMany(values_name);
    array.writeMany(")|");
    array.writeMany(value_name);
    array.writeMany("|{\n");
}
fn writeSwitch(array: *Array, value_name: []const u8) void {
    array.writeMany("switch(");
    array.writeMany(value_name);
    array.writeMany("){\n");
}
fn writeProng(array: *Array, tag_name: []const u8) void {
    array.writeMany(".");
    array.writeMany(tag_name);
    array.writeMany("=>{\n");
}
fn writeRequiredProng(array: *Array, tag_name: []const u8, capture_name: []const u8) void {
    array.writeMany(".");
    array.writeMany(tag_name);
    array.writeMany("=>|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeElse(array: *Array) void {
    array.writeMany("}else{\n");
}
fn writeContinue(array: *Array) void {
    array.writeMany("continue;\n");
}
fn writeIfElse(array: *Array) void {
    array.writeMany("}else\n");
}
fn writeIfClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeSwitchClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeProngClose(array: *Array) void {
    array.writeMany("},\n");
}
fn writeFieldTagname(array: *Array, field_name: []const u8) void {
    array.writeMany("@tagName(cmd.");
    array.writeMany(field_name);
    array.writeMany(")");
}
fn writeFieldTagnameLen(array: *Array, field_name: []const u8) void {
    writeFieldTagname(array, field_name);
    array.writeMany(".len");
}
fn writeFieldTagnamePtr(array: *Array, field_name: []const u8) void {
    writeFieldTagname(array, field_name);
    array.writeMany(".ptr");
}
fn writeOptFieldTagname(array: *Array, symbol_name: []const u8) void {
    array.writeMany("@tagName(");
    array.writeMany(symbol_name);
    array.writeMany(")");
}
fn writeOptFieldTagnameLen(array: *Array, symbol_name: []const u8) void {
    writeOptFieldTagname(array, symbol_name);
    array.writeMany(".len");
}
fn writeOptFieldTagnamePtr(array: *Array, symbol_name: []const u8) void {
    writeOptFieldTagname(array, symbol_name);
    array.writeMany(".ptr");
}
fn writeNull(array: *Array, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
                array.writeMany("ptr[0]=0;\nptr+=1;\n");
            } else {
                array.writeMany("buf[len]=0;\nlen+%=1;\n");
            }
        },
        .write => {
            array.writeMany("array.writeOne(0);\n");
        },
        .length => array.writeMany("len+%=1;\n"),
    }
}
fn writeOne(array: *Array, one: u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
                array.writeMany("ptr[0]=");
                array.writeFormat(fmt.ud8(one));
                array.writeMany(";\nptr+=1;\n");
            } else {
                array.writeMany("buf[len]=");
                array.writeFormat(fmt.ud8(one));
                array.writeMany(";\nlen+%=1;\n");
            }
        },
        .write => {
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(");\n");
        },
        .length => array.writeMany("len+%=1;\n"),
    }
}
fn writeIntegerString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
                array.writeMany("ptr+=fmt.Type.Ud64.formatWriteBuf(.{.value=");
                array.writeMany(arg_string);
                array.writeMany("},ptr);\n");
            } else {
                array.writeMany("len+%=fmt.Type.Ud64.formatWriteBuf(.{.value=");
                array.writeMany(arg_string);
                array.writeMany("},buf+len);\n");
            }
        },
        .write => {
            array.writeMany("array.writeFormat(fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=fmt.Type.Ud64.formatLength(.{.value=");
            array.writeMany(arg_string);
            array.writeMany("});\n");
        },
    }
}
fn writeKindString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (memcpy == .builtin) {
                if (notation == .slice) {
                    array.writeMany("@memcpy(ptr,");
                    writeFieldTagname(array, arg_string);
                    array.writeMany(");\n");
                } else {
                    array.writeMany("@memcpy(buf+len,");
                    writeFieldTagname(array, arg_string);
                    array.writeMany(");\n");
                }
            } else {
                if (notation == .slice) {
                    array.writeMany("mach.memcpy(ptr,");
                    writeFieldTagnamePtr(array, arg_string);
                    array.writeMany(",");
                    writeFieldTagnameLen(array, arg_string);
                    array.writeMany(");\n");
                } else {
                    array.writeMany("mach.memcpy(buf+len,");
                    writeFieldTagnamePtr(array, arg_string);
                    array.writeMany(",");
                    writeFieldTagnameLen(array, arg_string);
                    array.writeMany(");\n");
                }
            }
            if (notation == .slice) {
                array.writeMany("ptr+=");
                writeFieldTagnameLen(array, arg_string);
                array.writeMany(";\n");
            } else {
                writeKindString(array, arg_string, .length);
            }
        },
        .write => {
            array.writeMany("array.writeMany(@tagName(cmd.");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=");
            writeFieldTagnameLen(array, arg_string);
            array.writeMany(";\n");
        },
    }
}
fn writeTagString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (memcpy == .builtin) {
                if (notation == .slice) {
                    array.writeMany("@memcpy(ptr,");
                    writeOptFieldTagname(array, arg_string);
                    array.writeMany(");\n");
                    array.writeMany("ptr+=@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").len;\n");
                } else {
                    array.writeMany("@memcpy(buf+len,");
                    writeOptFieldTagname(array, arg_string);
                    array.writeMany(");\n");
                    writeTagString(array, arg_string, .length);
                }
            } else {
                if (notation == .slice) {
                    array.writeMany("mach.memcpy(ptr,@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").ptr,@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").len);\n");
                    array.writeMany("ptr+=@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").len;\n");
                } else {
                    array.writeMany("mach.memcpy(buf+len,@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").ptr,@tagName(");
                    array.writeMany(arg_string);
                    array.writeMany(").len);\n");
                    writeTagString(array, arg_string, .length);
                }
            }
        },
        .write => {
            array.writeMany("array.writeMany(@tagName(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len;\n");
        },
    }
}
fn writeArgString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (memcpy == .builtin) {
                if (notation == .slice) {
                    array.writeMany("@memcpy(ptr,");
                    array.writeMany(arg_string);
                    array.writeMany(");\n");
                } else {
                    array.writeMany("@memcpy(buf+len,");
                    array.writeMany(arg_string);
                    array.writeMany(");\n");
                }
            } else {
                if (notation == .slice) {
                    array.writeMany("mach.memcpy(ptr,");
                    array.writeMany(arg_string);
                    array.writeMany(".ptr,");
                    array.writeMany(arg_string);
                    array.writeMany(".len);\n");
                } else {
                    array.writeMany("mach.memcpy(buf+len,");
                    array.writeMany(arg_string);
                    array.writeMany(".ptr,");
                    array.writeMany(arg_string);
                    array.writeMany(".len);\n");
                }
            }
            if (notation == .slice) {
                array.writeMany("ptr+=");
                array.writeMany(arg_string);
                array.writeMany(".len;\n");
            } else {
                writeArgString(array, arg_string, .length);
            }
        },
        .write => {
            array.writeMany("array.writeMany(");
            array.writeMany(arg_string);
            array.writeMany(");\n");
        },
        .length => {
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".len;\n");
        },
    }
}
fn writeFormatterInternal(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
                array.writeMany("ptr+=");
                array.writeMany(arg_string);
                array.writeMany(".formatWriteBuf(ptr);\n");
            } else {
                array.writeMany("len+%=");
                array.writeMany(arg_string);
                array.writeMany(".formatWriteBuf(buf+len);\n");
            }
        },
        .write => {
            array.writeMany("array.writeFormat(");
            array.writeMany(arg_string);
            array.writeMany(");\n");
        },
        .length => {
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".formatLength();\n");
        },
    }
}
fn writeMapped(
    array: *Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    to: types.ProtoTypeDescr,
    char: u8,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, variant, char);
    }
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
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
        .write => {
            array.writeMany("array.writeFormat(");
            array.writeFormat(to);
            array.writeMany("{.value=");
            array.writeMany(arg_string);
            array.writeMany("});\n");
        },
        .length => {
            array.writeMany("len+%=");
            array.writeFormat(to);
            array.writeMany(".formatLength(.{.value=");
            array.writeMany(arg_string);
            array.writeMany("});\n");
        },
    }
}
fn writeCharacteristic(array: *Array, variant: types.Variant, char: u8) void {
    if (combine_char) return;
    switch (variant) {
        .write_buf => {
            if (notation == .slice) {
                array.writeMany("ptr[0]=");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(";\n");
            } else {
                array.writeMany("buf[len]=");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(";\n");
            }
            writeCharacteristic(array, .length, char);
        },
        .write => {
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(char));
            array.writeMany(");\n");
        },
        .length => {
            array.writeMany("len+%=1;\n");
        },
    }
}
fn writeOptString(
    array: *Array,
    opt_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    switch (variant) {
        .write_buf => {
            switch (notation) {
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
                    array.writeMany("ptr[0..");
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len));
                    }
                    array.writeMany("].*=\"");
                    array.writeMany(opt_string);
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.esc(char));
                    }
                    array.writeMany("\".*;\n");
                },
                .memcpy => if (memcpy == .builtin) {
                    array.writeMany("@memcpy(buf+len,\"");
                    array.writeMany(opt_string);
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.esc(char));
                    }
                    array.writeMany("\");\n");
                } else {
                    array.writeMany("mach.memcpy(buf+len,\"");
                    array.writeMany(opt_string);
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.esc(char));
                    }
                    array.writeMany("\",");
                    if (combine_char and char != types.ParamSpec.immediate) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len));
                    }
                    array.writeMany(");\n");
                },
            }
            if (notation == .slice) {
                array.writeMany("ptr+=");
                if (combine_char and char != types.ParamSpec.immediate) {
                    array.writeFormat(fmt.ud64(opt_string.len +% 1));
                } else {
                    array.writeFormat(fmt.ud64(opt_string.len));
                }
                array.writeMany(";\n");
            } else {
                writeOptString(array, opt_string, .length, char);
            }
        },
        .write => {
            array.writeMany("array.writeMany(\"");
            array.writeMany(opt_string);
            if (combine_char and char != types.ParamSpec.immediate) {
                array.writeFormat(fmt.esc(char));
            }
            array.writeMany("\");\n");
        },
        .length => {
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
    array: *Array,
    opt_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (combine_char) {
        writeOptString(array, opt_string, variant, char);
    } else {
        writeOptString(array, opt_string, variant, char);
        if (char != types.ParamSpec.immediate) {
            writeCharacteristic(array, variant, char);
        }
    }
}
fn writeArgStringExtra(
    array: *Array,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    writeArgString(array, arg_string, variant);
    if (char != types.ParamSpec.immediate) {
        writeOne(array, char, variant);
    }
}
fn writeOptArgInteger(
    array: *Array,
    opt_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    writeOptStringExtra(array, opt_string, variant, char);
    writeIntegerString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptArgString(
    array: *Array,
    opt_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    writeOptStringExtra(array, opt_string, variant, char);
    writeArgString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptTagString(
    array: *Array,
    opt_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    writeOptStringExtra(array, opt_string, variant, char);
    writeTagString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeFormatter(
    array: *Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, variant, char);
    }
    writeFormatterInternal(array, arg_string, variant);
}
fn writeOptionalFormatter(
    array: *Array,
    opt_switch_string: []const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, variant, char);
    }
    writeFormatterInternal(array, arg_string, variant);
}
fn writeWriterFunctionBody(array: *Array, params: []const types.ParamSpec, variant: types.Variant) void {
    writeSetRuntimeSafety(array);
    if (variant == .write_buf and notation == .slice) {
        writeDeclarePointer(array);
    } else if (variant != .write) {
        writeDeclareLength(array);
    }
    for (params) |param_spec| {
        if (!param_spec.flags.do_write) {
            continue;
        }
        if (param_spec.and_no) |no_param_spec| switch (param_spec.tag) {
            .field => |field| switch (no_param_spec.tag) {
                .field => |no_field| switch (field) {
                    .boolean => switch (no_field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name);
                            writeIf(array, param_spec.name);
                            writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                            writeElse(array);
                            writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                            writeIfClose(array);
                            writeIfClose(array);
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    .string => switch (no_param_spec.tag.field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name);
                            writeSwitch(array, param_spec.name);
                            writeRequiredProng(array, "yes", "arg");
                            writeOptArgString(array, param_spec.string, "arg", variant, param_spec.char orelse '\x00');
                            writeProngClose(array);
                            writeProng(array, "no");
                            writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                            writeProngClose(array);
                            writeIfClose(array);
                            writeIfClose(array);
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    .formatter => switch (no_param_spec.tag.field) {
                        .boolean => {
                            writeIfOptionalField(array, param_spec.name, param_spec.name);
                            writeSwitch(array, param_spec.name);
                            writeRequiredProng(array, "yes", "arg");
                            writeFormatter(array, param_spec.string, "arg", variant, param_spec.char orelse '\x00');
                            writeProngClose(array);
                            writeProng(array, "no");
                            writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                            writeProngClose(array);
                            writeIfClose(array);
                            writeIfClose(array);
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
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeSwitch(array, param_spec.name);
                        writeRequiredProng(array, "yes", "yes");
                        writeIfOptional(array, "yes", "arg");
                        writeOptionalFormatter(array, param_spec.string, "arg", variant, param_spec.char orelse '=');
                        writeElse(array);
                        writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeProngClose(array);
                        writeProng(array, "no");
                        writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                        writeProngClose(array);
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
            },
            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
        } else switch (param_spec.tag) {
            .param => |param| switch (param) {
                .string => writeArgStringExtra(array, param_spec.name, variant, param_spec.char orelse '\x00'),
                .formatter => writeFormatter(array, &.{}, param_spec.name, variant, param_spec.char orelse '\x00'),
                .repeatable_formatter => {
                    writeForEach(array, param_spec.name, "value");
                    writeFormatter(array, &.{}, "value", variant, param_spec.char orelse '\x00');
                    writeIfClose(array);
                },
            },
            .literal => |literal| switch (literal) {
                .string => writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00'),
                else => unhandledCommandField(param_spec),
            },
            .field => |field| switch (field) {
                .boolean => {
                    writeIfField(array, param_spec.name);
                    writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                    writeIfClose(array);
                },
                .tag => {
                    writeKindString(array, param_spec.name, variant);
                    writeNull(array, variant);
                },
                else => unhandledCommandField(param_spec),
            },
            .optional_field => |optional_field| {
                switch (optional_field) {
                    .string => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeOptArgString(array, param_spec.string, param_spec.name, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .tag => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeOptTagString(array, param_spec.string, param_spec.name, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .integer => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeOptArgInteger(array, param_spec.string, param_spec.name, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .formatter => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeFormatter(array, &.{}, param_spec.name, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .mapped => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeMapped(array, &.{}, param_spec.name, variant, param_spec.type.write.?.*, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .repeatable_formatter => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeForEach(array, param_spec.name, "value");
                        writeFormatter(array, &.{}, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    .repeatable_string => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeForEach(array, param_spec.name, "value");
                        writeOptArgString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    .repeatable_tag => {
                        writeIfOptionalField(array, param_spec.name, param_spec.name);
                        writeForEach(array, param_spec.name, "value");
                        writeOptTagString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    else => unhandledCommandField(param_spec),
                }
            },
        }
    }
    if (variant == .write_buf and notation == .slice) {
        writeReturnPointerDiff(array);
    } else if (variant != .write) {
        writeReturnLength(array);
    }
    writeIfClose(array);
}
fn writeWriterFunctionSignature(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    if (context == .Lib) {
        array.writeMany("export fn ");
    } else {
        array.writeMany("pub fn ");
    }
    switch (variant) {
        .write => array.writeMany("formatWrite"),
        .write_buf => array.writeMany("formatWriteBuf"),
        .length => array.writeMany("formatLength"),
    }
    if (context == .Lib) {
        array.writeMany(attributes.type_name);
    }
    array.writeMany("(cmd:*types.");
    array.writeMany(attributes.type_name);
    array.writeMany(",");
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param) {
            if (context == .Lib) {
                array.writeMany(param_spec.name);
                switch (param_spec.tag.param) {
                    .string, .repeatable_formatter => {
                        array.writeMany("_ptr:[*]const ");
                        if (param_spec.type.write) |wrty| {
                            wrty.formatWrite(array);
                        } else {
                            array.writeMany("u8");
                        }
                        array.writeMany(",");
                        array.writeMany(param_spec.name);
                        array.writeMany("_len:usize");
                    },
                    else => {
                        array.writeMany(":");
                        param_spec.type.store.formatWrite(array);
                    },
                }
                array.writeMany(",");
            } else {
                array.writeMany(param_spec.name);
                array.writeMany(":");
                array.writeFormat(param_spec.type.store.*);
                array.writeMany(",");
            }
        }
    }
    if (variant == .length) {
        array.undefine(1);
    }
    if (context == .Lib) {
        switch (variant) {
            .write => array.writeMany("array:anytype)callconv(.C)void{\n"),
            .write_buf => array.writeMany("buf:[*]u8)callconv(.C)usize{\n"),
            .length => array.writeMany(")callconv(.C)usize{\n"),
        }
    } else {
        switch (variant) {
            .write => array.writeMany("array:anytype)void{\n"),
            .write_buf => array.writeMany("buf:[*]u8)usize{\n"),
            .length => array.writeMany(")usize{\n"),
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
fn writeType(fields_array: *Array, param_spec: types.ParamSpec) void {
    if (param_spec.and_no) |no_param_spec| {
        const yes_bool: bool = param_spec.tag == .field and param_spec.tag.field == .boolean;
        const no_bool: bool = no_param_spec.tag == .field and no_param_spec.tag.field == .boolean;
        if (yes_bool != no_bool) {
            const new_type: types.ProtoTypeDescr = .{ .type_ref = .{
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
            fields_array.writeFormat(comptime types.ProtoTypeDescr.init(?bool));
        }
    } else {
        fields_array.writeFormat(param_spec.type.store.*);
    }
}

fn writeWriterFunction(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    writeWriterFunctionSignature(array, attributes, variant);
    writeWriterFunctionBody(array, attributes.params, variant);
}
fn isSquishable(opt_string: []const u8) bool {
    return opt_string.len == 2 and
        opt_string[0] == '-' and
        opt_string[1] != '-';
}
fn writeIncrementArgsIndex(array: *Array) void {
    array.writeMany("args_idx+%=1;\n");
}
fn writeStartsWith(array: *Array, opt_string: []const u8) void {
    array.writeMany("mem.testEqualString(\"");
    array.writeMany(opt_string);
    array.writeMany("\",");
    writeArgSliceFromTo(array, 0, opt_string.len);
    array.writeMany(")");
}
fn writeEquals(array: *Array, opt_string: []const u8) void {
    array.writeMany("mem.testEqualString(\"");
    array.writeMany(opt_string);
    array.writeMany("\",");
    array.writeMany("arg");
    array.writeMany(")");
}
fn writeOpenIfStartsWith(
    array: *Array,
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
    array: *Array,
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
    array: *Array,
    field_name: []const u8,
    capture_name: []const u8,
) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeMemcpy(
    array: *Array,
    dest: []const u8,
    src: []const u8,
) void {
    array.writeMany("@memcpy(");
    array.writeMany(dest);
    array.writeMany(",");
    array.writeMany(src);
    array.writeMany(");\n");
}
fn writeParseArgsFrom(
    array: *Array,
    type_name: []const u8,
) void {
    array.writeMany(type_name);
    array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg)");
}
fn writeAllocateRaw(array: *Array, type_name: []const u8, mb_size: ?usize, mb_alignment: ?usize) void {
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
fn writeAllocateRawIncrement(array: *Array, type_name: []const u8, mb_size: ?usize, mb_alignment: ?usize) void {
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
fn writeAddOptionalRepeatableFormatter(
    array: *Array,
    field_name: []const u8,
    type_name: []const u8,
) void {
    writeOpenOptionalField(array, field_name, "src");
    writeAllocateRawIncrement(array, type_name, null, null);
    writeMemcpy(array, "dest", "src");
    array.writeMany("dest[src.len]=");
    writeParseArgsFrom(array, type_name);
    array.writeMany(";\n");
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..src.len+%1];\n");
    writeElse(array);
    writeAllocateRaw(array, type_name, null, null);
    array.writeMany("dest[0]=");
    writeParseArgsFrom(array, type_name);
    array.writeMany(";\n");
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..1];\n");
    writeIfClose(array);
}
fn writeAddOptionalRepeatableString(
    array: *Array,
    field_name: []const u8,
) void {
    writeOpenOptionalField(array, field_name, "src");
    writeAllocateRawIncrement(array, "[]const u8", 16, 8);
    writeMemcpy(array, "dest", "src");
    array.writeMany("dest[src.len]=arg;\n");
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..src.len+%1];\n");
    writeElse(array);
    writeAllocateRaw(array, "[]const u8", 16, 8);
    array.writeMany("dest[0]=arg;\n");
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..1];\n");
    writeIfClose(array);
}
fn writeAddOptionalRepeatableTag(
    array: *Array,
    field_name: []const u8,
    type_name: []const u8,
) void {
    array.writeMany("const ");
    array.writeMany(field_name);
    array.writeMany(":*");
    array.writeMany(type_name);
    array.writeMany("=blk:{");
    writeOpenOptionalField(array, field_name, "src");
    writeAllocateRawIncrement(array, type_name, null, null);
    array.writeMany("for(dest,src)|*ptr,val|ptr.*=val;\n");
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..src.len+%1];\n");
    array.writeMany("break:blk &dest[src.len];\n");
    writeElse(array);
    writeAllocateRaw(array, type_name, null, null);
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=dest[0..1];\n");
    array.writeMany("break:blk &dest[0];\n");
    writeIfClose(array);
    array.writeMany("};\n");
}
fn writeReturnIfIndexEqualToLength(array: *Array) void {
    array.writeMany("if(args_idx==args_len){\n");
    array.writeMany("return;\n");
    array.writeMany("}\n");
}
fn writeAssignIfIndexNotEqualToLength(array: *Array, field_name: []const u8) void {
    array.writeMany("if(args_idx!=args_len){\n");
    writeAssignArgCurIndex(array, field_name);
    writeElse(array);
    array.writeMany("return;\n");
    writeIfClose(array);
}
fn writeAssignIfIntegerIfIndexNotEqualToLength(array: *Array, field_name: []const u8) void {
    array.writeMany("if(args_idx!=args_len){\n");
    writeAssignIfIntegerArgCurIndex(array, field_name);
    writeElse(array);
    array.writeMany("return;\n");
    writeIfClose(array);
}
fn writeArgCurIndex(array: *Array) void {
    array.writeMany("mem.terminate(args[args_idx], 0)");
}
fn writeArgAnyIndex(array: *Array, index: usize) void {
    array.writeMany("mem.terminate(args[");
    array.writeFormat(fmt.ud64(index));
    array.writeMany("], 0)");
}
fn writeArgAddIndex(array: *Array, offset: usize) void {
    array.writeMany("mem.terminate(args[args_idx+%");
    array.writeFormat(fmt.ud64(offset));
    array.writeMany("],0)");
}
fn writeByteAtIndex(array: *Array, offset: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(offset));
    array.writeMany("]");
}
fn writeArgSliceFrom(array: *Array, index: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(index));
    array.writeMany("..]");
}
fn writeArgSliceFromTo(array: *Array, start: usize, end: usize) void {
    array.writeMany("arg[");
    array.writeFormat(fmt.ud64(start));
    array.writeMany("..");
    array.writeFormat(fmt.ud64(end));
    array.writeMany("]");
}
fn writeAssignCurIndex(array: *Array) void {
    array.writeMany("arg=");
    writeArgCurIndex(array);
    array.writeMany(";\n");
}
fn writeNext(array: *Array) void {
    writeIncrementArgsIndex(array);
    writeReturnIfIndexEqualToLength(array);
    writeAssignCurIndex(array);
}
fn writeCmpArgLength(array: *Array, symbol: []const u8, length: usize) void {
    array.writeMany("arg.len");
    array.writeMany(symbol);
    array.writeFormat(fmt.ud64(length));
}
fn writeCmpByteAtIndex(array: *Array, symbol: []const u8, byte: u8, index: usize) void {
    writeByteAtIndex(array, index);
    array.writeMany(symbol);
    array.writeOne('\'');
    array.writeOne(byte);
    array.writeOne('\'');
}
fn writeOpenIfArgCmpLength(array: *Array, symbol: []const u8, length: usize) void {
    array.writeMany("if(");
    writeCmpArgLength(array, symbol, length);
    array.writeMany("){\n");
}
fn writeAssignArgToArgFrom(array: *Array, offset: usize) void {
    array.writeMany("arg=");
    writeArgSliceFrom(array, offset);
    array.writeMany(";\n");
}
fn writeNextIfArgEqualToLength(array: *Array, length: usize) void {
    writeOpenIfArgCmpLength(array, "==", length);
    writeNext(array);
    writeElse(array);
    writeAssignArgToArgFrom(array, length);
    writeIfClose(array);
}
fn writeAssignArgNextIfArgEqualToLength(array: *Array, length: usize) void {
    writeOpenIfArgCmpLength(array, "==", length);
    writeNext(array);
    writeElse(array);
    writeAssignArgToArgFrom(array, length);
    writeIfClose(array);
}
fn writeAssignTag(array: *Array, field_name: []const u8, tag_name: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=.");
    array.writeFormat(fmt.IdentifierFormat{ .value = tag_name });
    array.writeMany(";\n");
}
fn writeAssignTagToPtr(array: *Array, field_name: []const u8, tag_name: []const u8) void {
    array.writeMany(field_name);
    array.writeMany(".*=.");
    array.writeFormat(fmt.IdentifierFormat{ .value = tag_name });
    array.writeMany(";\n");
}
fn writeAssignBoolean(array: *Array, field_name: []const u8, value: bool) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeOne('=');
    array.writeMany(if (value) "true" else "false");
    array.writeMany(";\n");
}
fn writeAssignArg(array: *Array, field_name: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=arg;\n");
}
fn writeAssignIfIntegerArg(array: *Array, field_name: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=parse.ud(usize,arg);\n");
}
fn writeAssignIfIntegerArgCurIndex(array: *Array, field_name: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=parse.ud(usize,");
    writeArgCurIndex(array);
    array.writeMany(");\n");
}
fn writeAssignArgCurIndex(array: *Array, field_name: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=");
    writeArgCurIndex(array);
    array.writeMany(";\n");
}
fn writeOpenIfOptional(
    array: *Array,
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
    array: *Array,
    field_name: []const u8,
    specifier: union(enum) { yes: ?[]const u8, no: ?[]const u8 },
) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
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
    array: *Array,
    field_name: []const u8,
    offset: usize,
    specifier: union(enum) { yes: types.ProtoTypeDescr, no: types.ProtoTypeDescr },
) void {
    array.writeMany("cmd.");
    array.writeMany(field_name);
    array.writeMany("=");
    switch (specifier) {
        .yes => |type_descr| {
            array.writeMany(".{.yes=");
            array.writeFormat(type_descr);
            array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg[");
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..],)};\n");
        },
        .no => |type_descr| {
            array.writeMany(".{.no=");
            array.writeFormat(type_descr);
            array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg[");
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..],)};\n");
        },
    }
}
fn writeParserFunctionBody(array: *Array, attributes: types.Attributes) void {
    var do_discard: bool = true;
    for (attributes.params) |param_spec| {
        if (param_spec.string.len == 0 or !param_spec.flags.do_parse) {
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
                                writeAssignBoolean(array, param_spec.name, true);
                                writeIfElse(array);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignBoolean(array, param_spec.name, false);
                                writeIfElse(array);
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        .string => switch (no_field) {
                            .boolean => {
                                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                                writeNext(array);
                                writeAssignSpecifier(array, param_spec.name, .{ .yes = "arg" });
                                writeIfElse(array);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignSpecifier(array, param_spec.name, .{ .no = null });
                                writeIfElse(array);
                            },
                            else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                        },
                        .formatter => switch (no_field) {
                            .boolean => {
                                writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                                writeIfElse(array);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignBoolean(array, param_spec.name, false);
                                writeIfElse(array);
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
                                writeOpenIfOptional(array, param_spec.name, param_spec.string, param_spec.char orelse '=');
                                writeAssignSpecifierFormatParser(
                                    array,
                                    param_spec.name,
                                    param_spec.string.len +% 1,
                                    .{ .yes = param_spec.type.parse.?.* },
                                );
                                writeElse(array);
                                writeAssignSpecifier(array, param_spec.name, .{ .yes = "null" });
                                writeIfClose(array);
                                writeIfElse(array);
                                writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                                writeAssignSpecifier(array, param_spec.name, .{ .no = null });
                                writeIfElse(array);
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
                        writeAssignBoolean(array, param_spec.name, true);
                        writeIfElse(array);
                    },
                    .tag => {
                        writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                        writeIfElse(array);
                    },
                    else => unhandledCommandField(param_spec),
                },
                .optional_field => |optional_field| switch (optional_field) {
                    .string => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                            writeAssignArg(array, param_spec.name);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeIncrementArgsIndex(array);
                            writeAssignIfIndexNotEqualToLength(array, param_spec.name);
                        }
                        writeIfElse(array);
                    },
                    .integer => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                            writeAssignIfIntegerArg(array, param_spec.name);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeIncrementArgsIndex(array);
                            writeAssignIfIntegerIfIndexNotEqualToLength(array, param_spec.name);
                        }
                        writeIfElse(array);
                    },
                    .tag => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeNext(array);
                        }
                        for (param_spec.type.parse.?.type_decl.defn.?.fields) |field| {
                            writeOpenIfEqualTo(array, param_spec.name, field.name);
                            writeAssignTag(array, param_spec.name, field.name);
                            writeIfElse(array);
                        }
                        array.undefine(5);
                        writeIfElse(array);
                    },
                    .mapped => {
                        writeOpenIfOptional(array, param_spec.name, param_spec.string, param_spec.char orelse '=');
                        writeAssignSpecifierFormatParser(
                            array,
                            param_spec.name,
                            param_spec.string.len +% 1,
                            .{ .yes = param_spec.type.parse.?.* },
                        );
                        writeElse(array);
                        writeAssignSpecifier(array, param_spec.name, .{ .yes = "null" });
                        writeIfClose(array);
                        writeIfElse(array);
                    },
                    .repeatable_string => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeNext(array);
                        }
                        writeAddOptionalRepeatableString(array, param_spec.name);
                        do_discard = false;
                        writeIfElse(array);
                    },
                    .repeatable_tag => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeNext(array);
                        }
                        writeAddOptionalRepeatableTag(array, param_spec.name, param_spec.type.parse.?.type_decl.name.?);
                        for (param_spec.type.store.type_ref.type.type_ref.type.type_decl.defn.?.fields) |field| {
                            writeOpenIfEqualTo(array, param_spec.name, field.name);
                            writeAssignTagToPtr(array, param_spec.name, field.name);
                            writeIfElse(array);
                        }
                        array.undefine(5);
                        do_discard = false;
                        writeIfElse(array);
                    },
                    .repeatable_formatter => {
                        if (isSquishable(param_spec.string)) {
                            writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                            writeNextIfArgEqualToLength(array, param_spec.string.len);
                        } else {
                            writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                            writeNext(array);
                        }
                        writeAddOptionalRepeatableFormatter(array, param_spec.name, param_spec.type.parse.?.type_decl.name.?);
                        do_discard = false;
                        writeIfElse(array);
                    },
                    else => unhandledCommandField(param_spec),
                },
                .literal => {},
                else => unhandledCommandField(param_spec),
            }
        }
    }
    array.undefine(5);
    array.writeMany("else if (mem.testEqualString(\"--help\", arg)){\n");
    array.writeMany("debug.write(");
    array.writeMany(attributes.fn_name);
    array.writeMany("_help);\n");
    array.writeMany("}\n");
    if (do_discard) {
        array.writeMany("_=allocator;");
    }
    writeIfClose(array);
    writeIfClose(array);
}
fn writeParserFunctionSpec(array: *Array, attributes: types.Attributes) void {
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
fn writeParserFunctionSignature(array: *Array, attributes: types.Attributes) void {
    array.writeMany("export fn formatParseArgs");
    array.writeMany(attributes.type_name);
    array.writeMany("(cmd:*types.");
    array.writeMany(attributes.type_name);
    if (config.allow_comptime_configure_parser) {
        array.writeMany(",comptime spec:types.");
        array.writeMany(attributes.type_name);
        array.writeMany("ParserSpec");
    }
    array.writeMany(",allocator:*types.Allocator,args:[*][*:0]u8,args_len:usize)void{\n");
    array.writeMany("@setRuntimeSafety(false);\n");
    array.writeMany("var args_idx:usize=0;\n");
    array.writeMany("while(args_idx!=args_len):(args_idx+%=1){\n");
    array.writeMany("var arg:[:0]const u8=mem.terminate(args[args_idx],0);\n");
}
fn writeFlagWithInverse(array: *Array, param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var yes_idx: usize = 0;
    var no_idx: usize = 0;
    var no: bool = false;
    const yes_string: []const u8 = param_spec.string;
    const no_string: []const u8 = no_param_spec.string;
    var yes_array: Array256 = undefined;
    var no_array: Array256 = undefined;
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
fn writeParserFunctionExternSignature(array: *Array, attributes: types.Attributes) void {
    array.writeMany("formatParseArgs");
    array.writeMany(attributes.type_name);
    array.writeMany(":*fn(*types.");
    array.writeMany(attributes.type_name);
    array.writeMany(",*types.Allocator,[*][*:0]u8,usize)void = @ptrFromInt(8),\n");
}
fn writeWriterFunctionExternSignature(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    if (variant == .write_buf) {
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
    if (variant == .length) {
        array.undefine(1);
    }
    switch (variant) {
        .write => array.writeMany("anytype)void"),
        .write_buf => array.writeMany("[*]u8)callconv(.C)usize"),
        .length => array.writeMany(")callconv(.C)usize"),
    }
    array.writeMany(" = @ptrFromInt(8),\n");
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
fn unhandledCommandField(param_spec: types.ParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    @memcpy(buf[len..].ptr, param_spec.name);
    len +%= param_spec.name.len;
    buf[len..][0..5].* = "tag: ".*;
    len +%= 5;
    len +%= fmt.render(.{ .infer_type_names = true }, param_spec.tag).formatWriteBuf(buf[len..].ptr);
    @panic(buf[0..len]);
}
pub fn writeParserFunction(array: *Array, attributes: types.Attributes) void {
    writeParserFunctionSignature(array, attributes);
    writeParserFunctionBody(array, attributes);
    writeParserFunctionSpec(array, attributes);
}
pub fn writeParserFunctionHelp(array: *Array, attributes: types.Attributes) void {
    array.writeMany("const ");
    array.writeMany(attributes.fn_name);
    array.writeMany("_help:[:0]const u8=");
    var max_width: usize = 0;
    for (attributes.params) |param_spec| {
        if (param_spec.string.len != 0) {
            const start: usize = array.len();
            if (param_spec.and_no) |no_param_spec| {
                writeFlagWithInverse(array, param_spec, no_param_spec);
            } else {
                array.writeMany(param_spec.string);
            }
            const finish: usize = array.len();
            max_width = @max(max_width, mach.alignA64(4 +% (finish -% start), 4));
            array.undefine(finish -% start);
        }
    }
    for (attributes.params) |param_spec| {
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
    }
    array.writeMany("\n;");
}
pub fn writeFields(array: *Array, attributes: types.Attributes) void {
    var types_array: Array2 = undefined;
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
                array.writeMany("/// ");
                array.writeMany(line);
                array.writeMany("\n");
            }
            array.writeMany(param_spec.name);
            array.writeMany(":");
            writeType(array, param_spec);
            if (param_spec.tag == .field) {
                if (param_spec.and_no != null) {
                    array.writeMany("=null");
                } else if (param_spec.tag.field == .boolean) {
                    array.writeMany("=false");
                }
            }
            if (param_spec.tag == .optional_field) {
                array.writeMany("=null");
            }
            array.writeMany(",\n");
        }
    }
    array.writeMany(types_array.readAll());
}
pub fn writeDeclarations(array: *Array, attributes: types.Attributes) void {
    for (attributes.type_decls) |type_decl| {
        array.writeFormat(type_decl);
    }
}
pub fn writeWriterFunctions(array: *Array, attributes: types.Attributes) void {
    writeWriterFunction(array, attributes, .write_buf);
    writeWriterFunction(array, attributes, .length);
    if (context == .Exe) {
        writeWriterFunction(array, attributes, .write);
    }
}
pub fn writeFunctionExternSignatures(array: *Array, attribute: types.Attributes) void {
    writeParserFunctionExternSignature(array, attribute);
    writeWriterFunctionExternSignature(array, attribute, .write_buf);
    writeWriterFunctionExternSignature(array, attribute, .length);
}
