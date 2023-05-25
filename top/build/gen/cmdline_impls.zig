const fmt = @import("../../fmt.zig");
const mem = @import("../../mem.zig");
const gen = @import("../../gen.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const spec = @import("../../spec.zig");
const testing = @import("../../testing.zig");
const builtin = @import("../../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const Array = mem.StaticString(64 * 1024 * 1024);
const open_spec: file.OpenSpec = .{ .errors = .{}, .logging = .{} };
const create_spec: file.CreateSpec = .{ .errors = .{}, .logging = .{}, .options = .{ .exclusive = false } };
const write_spec: file.WriteSpec = .{ .errors = .{}, .logging = .{} };
const read_spec: file.ReadSpec = .{ .errors = .{}, .logging = .{} };
const close_spec: file.CloseSpec = .{ .errors = .{}, .logging = .{} };
const primitive: bool = true;
const compile: bool = false;
const prefer_ptrcast: bool = true;
const combine_char: bool = true;
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
fn writeNull(array: *Array, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("buf[len]=0;\nlen+%=1;\n");
        } else {
            array.writeMany("array.writeOne(0);\n");
        },
        .length => array.writeMany("len+%=1;\n"),
    }
}
fn writeOne(array: *Array, one: u8, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(";\nlen+%=1;\n");
        } else {
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(");\n");
        },
        .length => array.writeMany("len+%=1;\n"),
    }
}
fn writeIntegerString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("const s:[]const u8=builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll();\n");
            array.writeMany("mach.memcpy(buf+len,s.ptr,s.len);\n");
            array.writeMany("len=len+s.len;\n");
        } else {
            array.writeMany("array.writeFormat(fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll().len;\n");
        },
    }
}
fn writeKindString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("mach.memcpy(buf+len,@tagName(cmd.");
            array.writeMany(arg_string);
            array.writeMany(").ptr,@tagName(cmd.");
            array.writeMany(arg_string);
            array.writeMany(").len);\n");
            writeKindString(array, arg_string, .length);
        } else {
            array.writeMany("array.writeMany(@tagName(cmd.");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=@tagName(cmd.");
            array.writeMany(arg_string);
            array.writeMany(").len;\n");
        },
    }
}
fn writeTagString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("mach.memcpy(buf+len,@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").ptr,@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len);\n");
            writeTagString(array, arg_string, .length);
        } else {
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
        .write => if (primitive) {
            array.writeMany("mach.memcpy(buf+len,");
            array.writeMany(arg_string);
            array.writeMany(".ptr,");
            array.writeMany(arg_string);
            array.writeMany(".len);\n");
            writeArgString(array, arg_string, .length);
        } else {
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
        .write => if (primitive) {
            array.writeMany("len+%=");
            array.writeMany(arg_string);
            array.writeMany(".formatWriteBuf(buf+len);\n");
        } else {
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
    char: u8,
) void {
    if (opt_switch_string.len != 0) {
        writeOptStringExtra(array, opt_switch_string, variant, char);
    }
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("len+%=formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatWriteBuf(buf+len);\n");
        } else {
            array.writeMany("array.writeFormat(formatMap(");
            array.writeMany(arg_string);
            array.writeMany("));\n");
        },
        .length => {
            array.writeMany("len+%=formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatLength();\n");
        },
    }
}
fn writeCharacteristic(array: *Array, variant: types.Variant, char: u8) void {
    if (combine_char) return;
    switch (variant) {
        .write => {
            if (primitive) {
                array.writeMany("buf[len]=");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(";\n");
                writeCharacteristic(array, .length, char);
            } else {
                array.writeMany("array.writeOne(");
                array.writeFormat(fmt.ud8(char));
                array.writeMany(");\n");
            }
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
        if (char != types.ParamInfo.immediate) {
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
    if (char != types.ParamInfo.immediate) {
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
        .write => if (primitive) {
            if (prefer_ptrcast) {
                array.writeMany("@ptrCast(");
                array.writeMany("*[");
                if (combine_char and char != types.ParamInfo.immediate) {
                    array.writeFormat(fmt.ud64(opt_string.len +% 1));
                } else {
                    array.writeFormat(fmt.ud64(opt_string.len));
                }
                array.writeMany("]u8,buf+len).*=\"");
                array.writeMany(opt_string);
                if (combine_char and char != types.ParamInfo.immediate) {
                    array.writeFormat(fmt.esc(char));
                }
                array.writeMany("\".*;\n");
            } else {
                array.writeMany("mach.memcpy(buf+len,\"");
                array.writeMany(opt_string);
                if (combine_char and char != types.ParamInfo.immediate) {
                    array.writeFormat(fmt.esc(char));
                }
                array.writeMany("\",");
                if (combine_char and char != types.ParamInfo.immediate) {
                    array.writeFormat(fmt.ud64(opt_string.len +% 1));
                } else {
                    array.writeFormat(fmt.ud64(opt_string.len));
                }
                array.writeMany(");\n");
            }
            writeOptString(array, opt_string, .length, char);
        } else {
            array.writeMany("array.writeMany(\"");
            array.writeMany(opt_string);
            if (combine_char and char != types.ParamInfo.immediate) {
                array.writeFormat(fmt.esc(char));
            }
            array.writeMany("\");\n");
        },
        .length => {
            array.writeMany("len+%=");
            if (combine_char and char != types.ParamInfo.immediate) {
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
    if (primitive or variant == .length) {
        array.writeMany("var len:u64=0;\n");
    }
    for (options) |opt_spec| {
        const if_boolean_field_value: []const u8 = opt_spec.name;
        const if_optional_field_value: []const u8 = opt_spec.name;
        const if_optional_field_capture: []const u8 = opt_spec.name;
        if (opt_spec.info.tag == .string_param) {
            writeArgStringExtra(array, opt_spec.name, variant, opt_spec.info.char orelse '\x00');
            continue;
        }
        if (opt_spec.info.tag == .formatter_param) {
            writeFormatter(array, &.{}, opt_spec.name, variant, opt_spec.info.char orelse '\x00');
            continue;
        }
        if (opt_spec.info.tag == .mapped_param) {
            writeMapped(array, &.{}, opt_spec.name, variant, opt_spec.info.char orelse '\x00');
            continue;
        }
        if (opt_spec.info.tag == .string_literal) {
            writeOptStringExtra(array, opt_spec.string, variant, opt_spec.info.char orelse '\x00');
            continue;
        }
        if (opt_spec.and_no) |no_opt_spec| {
            if (opt_spec.info.tag == .boolean_field and no_opt_spec.info.tag == .boolean_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeIf(array, if_optional_field_capture);
                writeOptStringExtra(array, opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeElse(array);
                writeOptStringExtra(array, no_opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .string_field and
                no_opt_spec.info.tag == .boolean_field)
            {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "arg");
                writeOptArgString(array, opt_spec.string, "arg", variant, opt_spec.info.char orelse '\x00');
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .formatter_field and
                no_opt_spec.info.tag == .boolean_field)
            {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "arg");
                writeFormatter(array, opt_spec.string, "arg", variant, opt_spec.info.char orelse '\x00');
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .optional_formatter_field and
                no_opt_spec.info.tag == .boolean_field)
            {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "yes");
                writeIfOptional(array, "yes", "arg");
                writeOptionalFormatter(array, opt_spec.string, "arg", variant, opt_spec.info.char orelse '=');
                writeElse(array);
                writeOptStringExtra(array, opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            unhandledCommandFieldAndNo(opt_spec, no_opt_spec);
        } else {
            if (opt_spec.info.tag == .boolean_field) {
                writeIfField(array, if_boolean_field_value);
                writeOptStringExtra(array, opt_spec.string, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .tag_field) {
                writeKindString(array, opt_spec.name, variant);
                writeNull(array, variant);
                continue;
            }
            if (opt_spec.info.tag == .optional_string_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgString(array, opt_spec.string, if_optional_field_capture, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .optional_tag_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptTagString(array, opt_spec.string, if_optional_field_capture, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .optional_integer_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgInteger(array, opt_spec.string, if_optional_field_capture, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .optional_formatter_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeFormatter(array, opt_spec.string, if_optional_field_capture, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .optional_mapped_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeMapped(array, opt_spec.string, if_optional_field_capture, variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .repeatable_string_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptArgString(array, opt_spec.string, "value", variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.info.tag == .repeatable_tag_field) {
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptTagString(array, opt_spec.string, "value", variant, opt_spec.info.char orelse '\x00');
                writeIfClose(array);
                writeIfClose(array);
                continue;
            }
            unhandledCommandField(opt_spec);
        }
    }
    if (primitive or variant == .length) {
        array.writeMany("return len;\n");
    }
}
fn unhandledCommandFieldAndNo(opt_spec: types.ParamSpec, no_opt_spec: types.InverseParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.info.tag), "+", @tagName(no_opt_spec.info.tag),
    });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn unhandledCommandField(opt_spec: types.ParamSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.info.tag), "\n",
    });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn writeFile(array: *Array, pathname: [:0]const u8) void {
    const build_fd: u64 = file.create(create_spec, pathname, file.mode.regular);
    file.writeSlice(write_spec, build_fd, array.readAll());
    file.close(close_spec, build_fd);
}
fn writeFunctionSignatureFromAttributes(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    array.writeMany("pub fn ");
    array.writeMany(attributes.fn_name);
    if (variant == .write) {
        array.writeMany("Write");
        if (primitive) {
            array.writeMany("Buf");
        }
    } else {
        array.writeMany("Length");
    }
    array.writeMany("(cmd:*tasks.");
    array.writeMany(attributes.type_name);
    array.writeMany(",");
    for (attributes.params) |param_spec| {
        if (param_spec.info.isFnParam()) {
            array.writeMany(param_spec.name);
            array.writeMany(":");
            array.writeFormat(param_spec.info.type);
            array.writeMany(",");
        }
    }
    if (variant == .write) {
        if (primitive) {
            array.writeMany("buf:[*]u8)u64");
        } else {
            array.writeMany("array:anytype)void");
        }
    } else {
        array.undefine(1);
        array.writeMany(")u64");
    }
}
fn writeFunctionSurrounds(array: *Array, attributes: types.Attributes, variant: types.Variant) void {
    writeFunctionSignatureFromAttributes(array, attributes, variant);
    array.writeMany("{\n");
    writeFunctionBody(array, attributes.params, variant);
    array.writeMany("}\n");
}
fn writeCommandLineFromAttributes(array: *Array, attributes: types.Attributes) void {
    writeFunctionSurrounds(array, attributes, .write);
    writeFunctionSurrounds(array, attributes, .length);
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    var fd: u64 = file.open(open_spec, config.cmdline_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    writeCommandLineFromAttributes(array, attr.zig_build_command_attributes);
    writeCommandLineFromAttributes(array, attr.zig_format_command_attributes);
    writeCommandLineFromAttributes(array, attr.zig_ar_command_attributes);
    writeCommandLineFromAttributes(array, attr.llvm_tblgen_command_attributes);
    writeCommandLineFromAttributes(array, attr.harec_attributes);
    gen.truncateFile(write_spec, config.cmdline_path, array.readAll());
}
