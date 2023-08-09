const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const mach = @import("../../mach.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace @import("../../start.zig");
pub const runtime_assertions: bool = false;
const Array = mem.StaticString(64 * 1024 * 1024);
const Array2 = mem.StaticString(64 * 1024);
const notation: enum { slice, ptrcast, memcpy } = .slice;
const memcpy: enum { builtin, mach } = .builtin;
const usage: enum { lib, exe } = .exe;
const combine_char: bool = true;
const open_spec: file.OpenSpec = .{
    .errors = .{},
    .logging = .{},
};
const create_spec: file.CreateSpec = .{
    .errors = .{},
    .logging = .{},
    .options = .{ .exclusive = false },
};
const write_spec: file.WriteSpec = .{
    .errors = .{},
    .logging = .{},
};
const read_spec: file.ReadSpec = .{
    .errors = .{},
    .logging = .{},
};
const close_spec: file.CloseSpec = .{
    .errors = .{},
    .logging = .{},
};
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
fn writeSetRuntimeSafety(array: *Array) void {
    array.writeMany("@setRuntimeSafety(builtin.is_safe);\n");
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
                array.writeMany("ptr[0]=0;\nptr=ptr+1;\n");
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
                array.writeMany(";\nptr=ptr+1;\n");
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
                array.writeMany("ptr=ptr+fmt.Type.Ud64.formatWriteBuf(.{.value=");
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
                array.writeMany("ptr=ptr+");
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
                    array.writeMany("ptr=ptr+@tagName(");
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
                    array.writeMany("ptr=ptr+@tagName(");
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
                array.writeMany("ptr=ptr+");
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
                array.writeMany("ptr=ptr+");
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
                array.writeMany("ptr=ptr+");
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
                array.writeMany("ptr=ptr+");
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
                .mapped => writeMapped(array, &.{}, param_spec.name, variant, param_spec.type.write.?.*, param_spec.char orelse '\x00'),
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
fn writeUsingFunctions(array: *Array, attributes: types.Attributes) void {
    if (attributes.type_fn_name) |type_fn_name| {
        array.writeMany("pub usingnamespace types.");
        array.writeMany(type_fn_name);
        array.writeMany("(");
        array.writeMany(attributes.type_name);
        array.writeMany(");\n");
    }
}
fn writeWriterFunctionSignature(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    array.writeMany("pub fn ");
    switch (variant) {
        .write => array.writeMany("formatWrite"),
        .write_buf => array.writeMany("formatWriteBuf"),
        .length => array.writeMany("formatLength"),
    }
    array.writeMany("(cmd:*");
    array.writeMany(attributes.type_name);
    array.writeMany(",");
    for (attributes.params) |param_spec| {
        if (param_spec.tag == .param) {
            if (usage == .lib) {
                array.writeMany(",");
                array.writeMany(param_spec.name);
                array.writeMany("_len:usize,");
            } else {
                array.writeMany(param_spec.name);
                array.writeMany(":");
                array.writeFormat(param_spec.type.store.*);
                array.writeMany(",");
            }
        }
    }
    array.undefine(builtin.int(u1, variant == .length));
    switch (variant) {
        .write => array.writeMany("array:anytype)void{\n"),
        .write_buf => array.writeMany("buf:[*]u8)u64{\n"),
        .length => array.writeMany(")u64{\n"),
    }
}
fn writeFields(allocator: *mem.SimpleAllocator, array: *Array, attributes: types.Attributes) void {
    var types_array: *Array2 = allocator.create(Array2);
    const save: u64 = allocator.next;
    defer allocator.next = save;
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
fn writeDeclarations(array: *Array, attributes: types.Attributes) void {
    for (attributes.type_decls) |type_decl| {
        array.writeFormat(type_decl);
    }
}
fn writeWriterFunction(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    writeWriterFunctionSignature(array, attributes, variant);
    writeWriterFunctionBody(array, attributes.params, variant);
}
fn writeParserFunctionSignature(array: *Array, attributes: types.Attributes) void {
    array.writeMany("pub var ");
    array.writeMany(attributes.fn_name);
    array.writeMany("FormatParseArgs:*allowzero fn(*");
    array.writeMany(attributes.type_name);
    if (config.allow_comptime_configure_parser) {
        array.writeMany(",comptime spec:");
        array.writeMany(attributes.type_name);
        array.writeMany("ParserSpec");
    }
    array.writeMany(",*types.Allocator,[*][*:0]u8,usize)void=@ptrFromInt(0);\n");
}
fn writeParserStructMember(array: *Array, attributes: types.Attributes) void {
    array.writeMany(attributes.fn_name);
    array.writeMany(":*fn(*");
    array.writeMany(attributes.type_name);
    array.writeMany(",*types.Allocator,[*][*:0]u8,usize)void,\n");
}
fn writeTaskStructFromAttributes(allocator: *mem.SimpleAllocator, array: *Array, attributes: types.Attributes) void {
    array.writeMany("pub const ");
    array.writeMany(attributes.type_name);
    array.writeMany("=struct{\n");
    writeFields(allocator, array, attributes);
    writeDeclarations(array, attributes);
    writeWriterFunction(array, attributes, .write);
    writeWriterFunction(array, attributes, .write_buf);
    writeWriterFunction(array, attributes, .length);
    writeUsingFunctions(array, attributes);
    array.writeMany("};\n");
}
fn writeStructs(allocator: *mem.SimpleAllocator, array: *Array, attributes_set: []const types.Attributes) void {
    for (attributes_set) |attributes| {
        writeTaskStructFromAttributes(allocator, array, attributes);
    }
    array.writeMany("pub const ParseCommand=extern struct{\n");
    for (attributes_set) |attributes| {
        writeParserStructMember(array, attributes);
    }
    array.writeMany("};\n");
}
fn unhandledCommandFieldAndNo(param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    @memcpy(buf[len..].ptr, param_spec.name);
    len +%= param_spec.name.len;
    buf[len..][0..2].* = ": ".*;
    len +%= 2;
    len +%= fmt.render(.{ .infer_type_names = true }, no_param_spec.tag).formatWriteBuf(buf[len..].ptr);
    buf[len..][0..2].* = ", ".*;
    len +%= 2;
    proc.exitFault(buf[0..len], 2);
}
fn unhandledCommandField(param_spec: types.ParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    @memcpy(buf[len..].ptr, param_spec.name);
    len +%= param_spec.name.len;
    buf[len..][0..2].* = ": ".*;
    len +%= 2;
    len +%= fmt.render(.{ .infer_type_names = true }, param_spec.tag).formatWriteBuf(buf[len..].ptr);
    proc.exitFault(buf[0..len], 2);
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    const fd: u64 = file.open(open_spec, config.tasks_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    for (attr.scope) |decl| {
        array.writeFormat(types.ProtoTypeDescr{ .type_decl = decl });
    }
    types.ProtoTypeDescr.scope = attr.scope;
    writeStructs(&allocator, array, attr.all);
    try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll());
}
