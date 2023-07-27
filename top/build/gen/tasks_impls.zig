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
pub const logging_default: debug.Logging.Default = spec.logging.default.silent;
const Array = mem.StaticString(64 * 1024 * 1024);
const Array2 = mem.StaticString(64 * 1024);
const prefer_ptrcast: bool = true;
const prefer_builtin_memcpy: bool = true;
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
fn writeType(fields_array: *Array, types_array: *Array2, param_spec: types.ParamSpec) void {
    if (param_spec.and_no) |no_param_spec| {
        const yes_bool: bool = param_spec.tag == .boolean_field;
        const no_bool: bool = no_param_spec.tag == .boolean_field;
        const yes_type: ?types.ProtoTypeDescr = if (yes_bool) null else param_spec.type.store.*;
        const no_type: ?types.ProtoTypeDescr = if (no_bool) null else no_param_spec.type.store.*;
        if (yes_bool != no_bool) {
            if (config.declare_task_field_types) {
                fields_array.writeMany("?");
                fields_array.writeMany(param_spec.name);
                fields_array.writeMany("_type");
                types_array.writeMany("pub const ");
                types_array.writeMany(param_spec.name);
                types_array.writeMany("_type=");
                types_array.writeFormat(types.ProtoTypeDescr{
                    .type_decl = .{ .Composition = .{
                        .spec = "union(enum)",
                        .fields = &.{
                            .{ .name = "yes", .type = yes_type },
                            .{ .name = "no", .type = no_type },
                        },
                    } },
                });
                types_array.writeMany(";\n");
            } else {
                fields_array.writeFormat(types.ProtoTypeDescr{ .type_refer = .{
                    .spec = "?",
                    .type = &.{ .type_decl = .{ .Composition = .{
                        .spec = "union(enum)",
                        .fields = &.{
                            .{ .name = "yes", .type = yes_type },
                            .{ .name = "no", .type = no_type },
                        },
                    } } },
                } });
            }
        } else {
            fields_array.writeFormat(types.ProtoTypeDescr.init(?bool));
        }
    } else {
        const need_decl: bool =
            param_spec.tag == .optional_tag_field or
            param_spec.tag == .optional_repeatable_tag_field;
        if (config.declare_task_field_types and need_decl) {
            fields_array.writeMany("?");
            fields_array.writeMany(param_spec.name);
            fields_array.writeMany("_type");
            types_array.writeMany("pub const ");
            types_array.writeMany(param_spec.name);
            types_array.writeMany("_type=");
            types_array.writeFormat(param_spec.type.store.*);
            types_array.writeMany(";\n");
        } else {
            fields_array.writeFormat(param_spec.type.store.*);
        }
    }
}
fn writeSetRuntimeSafety(array: *Array) void {
    array.writeMany("@setRuntimeSafety(builtin.is_safe);\n");
}
fn writeDeclareLength(array: *Array) void {
    array.writeMany("var len:usize=0;\n");
}
fn writeReturnLength(array: *Array) void {
    array.writeMany("return len;\n");
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
            array.writeMany("buf[len]=0;\nlen+%=1;\n");
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
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(";\nlen+%=1;\n");
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
            array.writeMany("len+%=fmt.Type.Ud64.formatWriteBuf(.{.value=");
            array.writeMany(arg_string);
            array.writeMany("},buf+len);\n");
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
            if (prefer_builtin_memcpy) {
                array.writeMany("@memcpy(buf+len,");
                writeFieldTagname(array, arg_string);
                array.writeMany(");\n");
            } else {
                array.writeMany("mach.memcpy(buf+len,");
                writeFieldTagnamePtr(array, arg_string);
                array.writeMany(",");
                writeFieldTagnameLen(array, arg_string);
                array.writeMany(");\n");
            }
            writeKindString(array, arg_string, .length);
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
            if (prefer_builtin_memcpy) {
                array.writeMany("@memcpy(buf+len,");
                writeOptFieldTagname(array, arg_string);
                array.writeMany(");\n");
                writeTagString(array, arg_string, .length);
            } else {
                array.writeMany("mach.memcpy(buf+len,@tagName(");
                array.writeMany(arg_string);
                array.writeMany(").ptr,@tagName(");
                array.writeMany(arg_string);
                array.writeMany(").len);\n");
                writeTagString(array, arg_string, .length);
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
            if (prefer_builtin_memcpy) {
                array.writeMany("@memcpy(buf+len,");
                array.writeMany(arg_string);
                array.writeMany(");\n");
            } else {
                array.writeMany("mach.memcpy(buf+len,");
                array.writeMany(arg_string);
                array.writeMany(".ptr,");
                array.writeMany(arg_string);
                array.writeMany(".len);\n");
            }
            writeArgString(array, arg_string, .length);
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
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".formatWriteBuf(buf+len);\n");
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
            array.writeMany("len+%=");
            array.writeFormat(to);
            array.writeMany(".formatWriteBuf(.{.value=");
            array.writeMany(arg_string);
            array.writeMany("}, buf+len);\n");
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
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(char));
            array.writeMany(";\n");
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
            if (prefer_ptrcast and opt_string.len < 32) {
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
            } else {
                if (prefer_builtin_memcpy) {
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
                }
            }
            writeOptString(array, opt_string, .length, char);
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
pub fn writeWriterFunctionBody(array: *Array, params: []const types.ParamSpec, variant: types.Variant) void {
    writeSetRuntimeSafety(array);
    if (variant != .write) {
        writeDeclareLength(array);
    }
    for (params) |param_spec| {
        if (!param_spec.flags.do_write) {
            continue;
        }
        const if_boolean_field_value: []const u8 = param_spec.name;
        const if_optional_field_value: []const u8 = param_spec.name;
        const if_optional_field_capture: []const u8 = param_spec.name;
        switch (param_spec.tag) {
            .string_param => writeArgStringExtra(array, param_spec.name, variant, param_spec.char orelse '\x00'),
            .string_literal => writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00'),
            .formatter_param => writeFormatter(array, &.{}, param_spec.name, variant, param_spec.char orelse '\x00'),
            .mapped_param => writeMapped(array, &.{}, param_spec.name, variant, param_spec.type.write.?.*, param_spec.char orelse '\x00'),
            else => if (param_spec.and_no) |no_param_spec| {
                switch (param_spec.tag) {
                    .boolean_field => switch (no_param_spec.tag) {
                        .boolean_field => {
                            writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                            writeIf(array, if_optional_field_capture);
                            writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                            writeElse(array);
                            writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                            writeIfClose(array);
                            writeIfClose(array);
                        },
                        else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                    },
                    .string_field => switch (no_param_spec.tag) {
                        .boolean_field => {
                            writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                            writeSwitch(array, if_optional_field_capture);
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
                    .formatter_field => switch (no_param_spec.tag) {
                        .boolean_field => {
                            writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                            writeSwitch(array, if_optional_field_capture);
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
                    .optional_formatter_field => switch (no_param_spec.tag) {
                        .boolean_field => {
                            writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                            writeSwitch(array, if_optional_field_capture);
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
                }
            } else {
                switch (param_spec.tag) {
                    .boolean_field => {
                        writeIfField(array, if_boolean_field_value);
                        writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .tag_field => {
                        writeKindString(array, param_spec.name, variant);
                        writeNull(array, variant);
                    },
                    .optional_string_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeOptArgString(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .optional_tag_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeOptTagString(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .optional_integer_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeOptArgInteger(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .optional_formatter_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeFormatter(array, &.{}, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .optional_mapped_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeMapped(array, &.{}, if_optional_field_capture, variant, param_spec.type.write.?.*, param_spec.char orelse '\x00');
                        writeIfClose(array);
                    },
                    .optional_repeatable_formatter_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeForEach(array, if_optional_field_capture, "value");
                        writeFormatter(array, &.{}, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    .optional_repeatable_string_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeForEach(array, if_optional_field_capture, "value");
                        writeOptArgString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    .optional_repeatable_tag_field => {
                        writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                        writeForEach(array, if_optional_field_capture, "value");
                        writeOptTagString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                        writeIfClose(array);
                        writeIfClose(array);
                    },
                    else => unhandledCommandField(param_spec),
                }
            },
        }
    }
    if (variant != .write) {
        writeReturnLength(array);
    }
    writeIfClose(array);
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
    array.writeMany("eql(\"");
    array.writeMany(opt_string);
    array.writeMany("\",");
    writeArgSliceFromTo(array, 0, opt_string.len);
    array.writeMany(")");
}
fn writeEquals(array: *Array, opt_string: []const u8) void {
    array.writeMany("eql(\"");
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
    array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg)");
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
    array.writeMany("if(args_idx==args.len){\n");
    array.writeMany("return;\n");
    array.writeMany("}\n");
}
fn writeAssignIfIndexNotEqualToLength(array: *Array, field_name: []const u8) void {
    array.writeMany("if(args_idx!=args.len){\n");
    writeAssignArgCurIndex(array, field_name);
    writeElse(array);
    array.writeMany("return;\n");
    writeIfClose(array);
}
fn writeArgCurIndex(array: *Array) void {
    array.writeMany("str(args[args_idx])");
}
fn writeArgAnyIndex(array: *Array, index: usize) void {
    array.writeMany("str(args[");
    array.writeFormat(fmt.ud64(index));
    array.writeMany("])");
}
fn writeArgAddIndex(array: *Array, offset: usize) void {
    array.writeMany("str(args[args_idx+%");
    array.writeFormat(fmt.ud64(offset));
    array.writeMany("])");
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
            array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg[");
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..])};\n");
        },
        .no => |type_descr| {
            array.writeMany(".{.no=");
            array.writeFormat(type_descr);
            array.writeMany(".formatParseArgs(allocator,args,&args_idx,arg[");
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..])};\n");
        },
    }
}
fn writeParserFunctionBody(array: *Array, attributes: types.Attributes) void {
    var do_discard: bool = true;
    for (attributes.params) |param_spec| {
        if (param_spec.string.len == 0 or
            param_spec.tag == .string_literal or
            !param_spec.flags.do_parse)
        {
            continue;
        }
        if (param_spec.and_no) |no_param_spec| {
            switch (param_spec.tag) {
                .boolean_field => switch (no_param_spec.tag) {
                    .boolean_field => {
                        writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                        writeAssignBoolean(array, param_spec.name, true);
                        writeIfElse(array);
                        writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                        writeAssignBoolean(array, param_spec.name, false);
                        writeIfElse(array);
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                .string_field => switch (no_param_spec.tag) {
                    .boolean_field => {
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
                .formatter_field => switch (no_param_spec.tag) {
                    .boolean_field => {
                        writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                        writeIfElse(array);
                        writeOpenIfEqualTo(array, param_spec.name, no_param_spec.string);
                        writeAssignBoolean(array, param_spec.name, false);
                        writeIfElse(array);
                    },
                    else => unhandledCommandFieldAndNo(param_spec, no_param_spec),
                },
                .optional_formatter_field => switch (no_param_spec.tag) {
                    .boolean_field => {
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
            }
        } else switch (param_spec.tag) {
            .boolean_field => {
                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                writeAssignBoolean(array, param_spec.name, true);
                writeIfElse(array);
            },
            .tag_field => {
                writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                writeIfElse(array);
            },
            .optional_string_field => {
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
            .optional_tag_field => {
                if (isSquishable(param_spec.string)) {
                    writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                    writeNextIfArgEqualToLength(array, param_spec.string.len);
                } else {
                    writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                    writeNext(array);
                }
                for (param_spec.type.parse.?.type_decl.Enumeration.fields) |field| {
                    writeOpenIfEqualTo(array, param_spec.name, field.name);
                    writeAssignTag(array, param_spec.name, field.name);
                    writeIfElse(array);
                }
                array.undefine(5);
                writeIfElse(array);
            },
            .optional_integer_field => {},
            .optional_formatter_field => {},
            .optional_mapped_field => {
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
            .optional_repeatable_string_field => {
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
            .optional_repeatable_tag_field => {
                if (isSquishable(param_spec.string)) {
                    writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                    writeNextIfArgEqualToLength(array, param_spec.string.len);
                } else {
                    writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                    writeNext(array);
                }
                writeAddOptionalRepeatableTag(array, param_spec.name, param_spec.type.parse.?.type_name);
                for (param_spec.type.store.type_refer.type.type_refer.type.type_decl.Enumeration.fields) |field| {
                    writeOpenIfEqualTo(array, param_spec.name, field.name);
                    writeAssignTagToPtr(array, param_spec.name, field.name);
                    writeIfElse(array);
                }
                array.undefine(5);
                do_discard = false;
                writeIfElse(array);
            },
            .optional_repeatable_formatter_field => {
                if (isSquishable(param_spec.string)) {
                    writeOpenIfStartsWith(array, param_spec.name, param_spec.string);
                    writeNextIfArgEqualToLength(array, param_spec.string.len);
                } else {
                    writeOpenIfEqualTo(array, param_spec.name, param_spec.string);
                    writeNext(array);
                }
                writeAddOptionalRepeatableFormatter(array, param_spec.name, param_spec.type.parse.?.type_name);
                do_discard = false;
                writeIfElse(array);
            },
            else => unhandledCommandField(param_spec),
        }
    }
    array.undefine(5);
    if (do_discard) {
        array.writeMany("_=allocator;");
    }
    writeIfClose(array);
    writeIfClose(array);
}
fn unhandledCommandFieldAndNo(param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = mach.memcpyMulti(&buf, &.{ param_spec.name, ": ", @tagName(param_spec.tag), "+", @tagName(no_param_spec.tag) });
    proc.exitFault(buf[0..len], 2);
}
fn unhandledCommandField(param_spec: types.ParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = mach.memcpyMulti(&buf, &.{ param_spec.name, ": ", @tagName(param_spec.tag), "\n" });
    proc.exitFault(buf[0..len], 2);
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
    array.writeMany("pub fn formatParseArgs(cmd:*");
    array.writeMany(attributes.type_name);
    if (config.allow_comptime_configure_parser) {
        array.writeMany(",comptime spec:");
        array.writeMany(attributes.type_name);
        array.writeMany("ParserSpec");
    }
    array.writeMany(",allocator:anytype,args:[][*:0]u8)void{\n");
    array.writeMany("@setRuntimeSafety(false);\n");
    array.writeMany("var args_idx:usize=0;\n");
    array.writeMany("const eql=if (builtin.output_mode==.Lib)");
    array.writeMany("mem.testEqualString else mach.testEqualMany8;\n");
    array.writeMany("const str=if (builtin.output_mode==.Lib)");
    array.writeMany("meta.manyToSlice else mach.manyToSlice80;\n");
    array.writeMany("while(args_idx!=args.len):(args_idx+%=1){\n");
    array.writeMany("var arg:[:0]const u8=str(args[args_idx]);");
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
        if (param_spec.isFnParam()) {
            array.writeMany(param_spec.name);
            array.writeMany(":");
            array.writeFormat(param_spec.type.store.*);
            array.writeMany(",");
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
        if (param_spec.isField()) {
            for (param_spec.descr) |line| {
                array.writeMany("/// ");
                array.writeMany(line);
                array.writeMany("\n");
            }
            array.writeMany(param_spec.name);
            array.writeMany(":");
            writeType(array, types_array, param_spec);
            if (param_spec.and_no == null and
                param_spec.tag == .boolean_field)
            {
                array.writeMany("=false,\n");
            } else if (param_spec.tag != .tag_field) {
                array.writeMany("=null,\n");
            } else {
                array.writeMany(",\n");
            }
        }
    }
    array.writeMany(types_array.readAll());
}
fn writeParserFunction(array: *Array, attributes: types.Attributes) void {
    writeParserFunctionSignature(array, attributes);
    writeParserFunctionBody(array, attributes);
    writeParserFunctionSpec(array, attributes);
}
fn writeWriterFunction(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    writeWriterFunctionSignature(array, attributes, variant);
    writeWriterFunctionBody(array, attributes.params, variant);
}
fn writeParserFnPtrDecl(array: *Array, attributes: types.Attributes) void {
    array.writeMany("pub var ");
    array.writeMany(attributes.fn_name);
    array.writeMany("FormatParseArgs: ?*fn(allocator:*types.Allocator,");
    array.writeMany(attributes.fn_name);
    array.writeMany("_cmd: *types.");
    array.writeMany(attributes.type_name);
    array.writeMany(",args:[*][*:0]u8,args_len:usize,)callconv(.C)void = null;\n");
}
fn writeTaskStructFromAttributes(allocator: *mem.SimpleAllocator, array: *Array, attributes: types.Attributes) void {
    array.writeMany("pub const ");
    array.writeMany(attributes.type_name);
    array.writeMany("=struct{\n");
    writeFields(allocator, array, attributes);
    writeWriterFunction(array, attributes, .write);
    writeWriterFunction(array, attributes, .write_buf);
    writeWriterFunction(array, attributes, .length);
    writeParserFnPtrDecl(array, attributes);
    writeParserFunction(array, attributes);
    writeUsingFunctions(array, attributes);
    array.writeMany("};\n");
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    const fd: u64 = file.open(open_spec, config.tasks_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    for ([_]types.Attributes{
        attr.zig_build_command_attributes,
        attr.zig_format_command_attributes,
        attr.zig_ar_command_attributes,
        attr.zig_objcopy_command_attributes,
        attr.llvm_tblgen_command_attributes,
        attr.harec_attributes,
    }) |attributes| {
        writeTaskStructFromAttributes(&allocator, array, attributes);
    }
    try gen.truncateFile(.{ .return_type = void }, config.tasks_path, array.readAll());
}
