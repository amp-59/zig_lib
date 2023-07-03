const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const fmt = @import("../../fmt.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const mach = @import("../../mach.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const max_len: u64 = attr.format_command_options.len + attr.build_command_options.len;
const Array = mem.StaticString(64 * 1024 * 1024);
const Array2 = mem.StaticString(64 * 1024);
const Arrays = mem.StaticArray([]const u8, max_len);
const Indices = mem.StaticArray(u64, max_len);
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
        const yes_type: ?types.ProtoTypeDescr = if (yes_bool) null else param_spec.parameter();
        const no_type: ?types.ProtoTypeDescr = if (no_bool) null else no_param_spec.parameter();
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
            param_spec.tag == .repeatable_tag_field;
        if (config.declare_task_field_types and need_decl) {
            fields_array.writeMany("?");
            fields_array.writeMany(param_spec.name);
            fields_array.writeMany("_type");
            types_array.writeMany("pub const ");
            types_array.writeMany(param_spec.name);
            types_array.writeMany("_type=");
            types_array.writeFormat(param_spec.parameter());
            types_array.writeMany(";\n");
        } else {
            fields_array.writeFormat(param_spec.parameter());
        }
    }
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
            array.writeMany("const s:[]const u8=ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll();\n");
            if (prefer_builtin_memcpy) {
                array.writeMany("@memcpy(buf+len,s);\n");
            } else {
                array.writeMany("mach.memcpy(buf+len,s.ptr,s.len);\n");
            }
            array.writeMany("len=len+s.len;\n");
        },
        .write => {
            array.writeMany("array.writeFormat(fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll().len;\n");
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
pub fn writeFunctionBody(array: *Array, options: []const types.ParamSpec, variant: types.Variant) void {
    array.writeMany("@setRuntimeSafety(safety);\n");
    if (variant != .write) {
        array.writeMany("var len:u64=0;\n");
    }
    for (options) |param_spec| {
        const if_boolean_field_value: []const u8 = param_spec.name;
        const if_optional_field_value: []const u8 = param_spec.name;
        const if_optional_field_capture: []const u8 = param_spec.name;
        if (param_spec.tag == .string_param) {
            writeArgStringExtra(array, param_spec.name, variant, param_spec.char orelse '\x00');
            continue;
        }
        if (param_spec.tag == .formatter_param) {
            writeFormatter(array, &.{}, param_spec.name, variant, param_spec.char orelse '\x00');
            continue;
        }
        if (param_spec.tag == .mapped_param) {
            writeMapped(array, &.{}, param_spec.name, variant, param_spec.formatter(), param_spec.char orelse '\x00');
            continue;
        }
        if (param_spec.tag == .string_literal) {
            writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
            continue;
        }
        if (param_spec.name.len == 0) {
            continue;
        }
        if (param_spec.and_no) |no_param_spec| {
            if (param_spec.tag == .boolean_field and no_param_spec.tag == .boolean_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeIf(array, if_optional_field_capture);
                writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                writeElse(array);
                writeOptStringExtra(array, no_param_spec.string, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .string_field and
                no_param_spec.tag == .boolean_field)
            {
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
                continue;
            }
            if (param_spec.tag == .formatter_field and
                no_param_spec.tag == .boolean_field)
            {
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
                continue;
            }
            if (param_spec.tag == .optional_formatter_field and
                no_param_spec.tag == .boolean_field)
            {
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
                continue;
            }
            unhandledCommandFieldAndNo(param_spec, no_param_spec);
        } else {
            if (param_spec.tag == .boolean_field) {
                array.writeMany("if(cmd.");
                array.writeMany(if_boolean_field_value);
                array.writeMany("){\n");
                writeOptStringExtra(array, param_spec.string, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .tag_field) {
                writeKindString(array, param_spec.name, variant);
                writeNull(array, variant);
                continue;
            }
            if (param_spec.tag == .optional_string_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgString(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .optional_tag_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptTagString(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .optional_integer_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgInteger(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .optional_formatter_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeFormatter(array, param_spec.string, if_optional_field_capture, variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .optional_mapped_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeMapped(array, param_spec.string, if_optional_field_capture, variant, param_spec.formatter(), param_spec.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .repeatable_string_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptArgString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (param_spec.tag == .repeatable_tag_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptTagString(array, param_spec.string, "value", variant, param_spec.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            unhandledCommandField(param_spec);
        }
    }
    if (variant != .write) {
        array.writeMany("return len;\n");
    }
}
fn unhandledCommandFieldAndNo(param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = mach.memcpyMulti(&buf, &.{ param_spec.name, ": ", @tagName(param_spec.tag), "+", @tagName(no_param_spec.tag) });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn unhandledCommandField(param_spec: types.ParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = mach.memcpyMulti(&buf, &.{ param_spec.name, ": ", @tagName(param_spec.tag), "\n" });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn writeFile(array: *Array, pathname: [:0]const u8) void {
    const build_fd: u64 = file.create(create_spec, pathname, file.mode.regular);
    file.writeSlice(write_spec, build_fd, array.readAll());
    file.close(close_spec, build_fd);
}
fn writeFunctionSignatureFromAttributes(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
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
            array.writeFormat(param_spec.parameter());
            array.writeMany(",");
        }
    }
    array.undefine(builtin.int(u1, variant == .length));
    switch (variant) {
        .write => array.writeMany("array:anytype)void"),
        .write_buf => array.writeMany("buf:[*]u8)u64"),
        .length => array.writeMany(")u64"),
    }
}
fn writeFields(allocator: *mem.SimpleAllocator, array: *Array, attributes: types.Attributes) void {
    var types_array: *Array2 = allocator.create(Array2);
    const save: u64 = allocator.next;
    defer allocator.next = save;
    for (attributes.params) |param_spec| {
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
fn writeFunction(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    writeFunctionSignatureFromAttributes(array, attributes, variant);
    array.writeMany("{\n");
    writeFunctionBody(array, attributes.params, variant);
    array.writeMany("}\n");
}
fn writeTaskStructFromAttributes(allocator: *mem.SimpleAllocator, array: *Array, attributes: types.Attributes) void {
    array.writeMany("pub const ");
    array.writeMany(attributes.type_name);
    array.writeMany("=struct{\n");
    writeFields(allocator, array, attributes);
    writeFunction(array, attributes, .write);
    writeFunction(array, attributes, .write_buf);
    writeFunction(array, attributes, .length);
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
    array.undefineAll();
}
