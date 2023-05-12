const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const gen = @import("../gen.zig");
const proc = @import("../proc.zig");
const file = @import("../file.zig");
const spec = @import("../spec.zig");
const testing = @import("../testing.zig");
const builtin = @import("../builtin.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const primitive: bool = true;
const abstract: bool = false;
const compile: bool = false;
const prefer_ptrcast: bool = true;
const combine_char: bool = true;
const max_len: u64 = attr.format_command_options.len + attr.build_command_options.len;
const Array = mem.StaticString(64 * 1024 * 1024);
const Arrays = mem.StaticArray([]const u8, max_len);
const Indices = mem.StaticArray(u64, max_len);
const open_spec: file.OpenSpec = .{ .errors = .{}, .logging = .{} };
const create_spec: file.CreateSpec = .{ .errors = .{}, .logging = .{}, .options = .{ .exclusive = false } };
const write_spec: file.WriteSpec = .{ .errors = .{}, .logging = .{} };
const read_spec: file.ReadSpec = .{ .errors = .{}, .logging = .{} };
const close_spec: file.CloseSpec = .{ .errors = .{}, .logging = .{} };
fn writeIf(array: *Array, value_name: []const u8) void {
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany("){\n");
}
fn writeIfField(array: *Array, field_name: []const u8) void {
    array.writeMany(if (abstract) "if(" else "if(cmd.");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeIfOptionalField(array: *Array, field_name: []const u8, capture_name: []const u8) void {
    array.writeMany(if (abstract) "if(" else "if(cmd.");
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
            array.writeMany("array.writeOne(\'\\x00\');\n");
        },
        .length => array.writeMany("len+%=1;\n"),
    }
}
fn writeOne(array: *Array, one: u8, variant: types.Variant) void {
    switch (variant) {
        .write => if (primitive) {
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(";\nlen+%=1\n");
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
            array.writeMany("const s: []const u8 = builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll();");
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
    opt_switch_string: ?[]const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (opt_switch_string) |switch_string| {
        writeOptStringExtra(array, switch_string, variant, char);
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
            if (abstract) {
                if (primitive) {
                    array.writeMany("buf[len]=c;\n");
                    writeCharacteristic(array, .length, char);
                } else {
                    array.writeMany("array.writeOne(c);\n");
                }
            } else {
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
            }
        },
        .length => {
            array.writeMany("len+%=1;\n");
        },
    }
}
const CharacteristicFormat = fmt.PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .width = .max,
    .radix = 16,
    .prefix = null,
});
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
        writeCharacteristic(array, variant, char);
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
            if (abstract) {
                array.writeMany("mach.memcpy(buf+len,opt_switch.ptr,opt_switch.len);\n");
            } else {
                if (prefer_ptrcast) {
                    array.writeMany("@ptrCast(");
                    array.writeMany("*[");
                    if (combine_char) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len));
                    }
                    array.writeMany("]u8,buf+len).*=\"");
                    array.writeMany(opt_string);
                    if (combine_char) {
                        array.writeMany("\\x");
                        array.writeFormat(CharacteristicFormat{ .value = char });
                    }
                    array.writeMany("\".*;\n");
                } else {
                    array.writeMany("mach.memcpy(buf+len,\"");
                    array.writeMany(opt_string);
                    if (combine_char) {
                        array.writeMany("\\x");
                        array.writeFormat(CharacteristicFormat{ .value = char });
                    }
                    array.writeMany("\",");
                    if (combine_char) {
                        array.writeFormat(fmt.ud64(opt_string.len +% 1));
                    } else {
                        array.writeFormat(fmt.ud64(opt_string.len));
                    }
                    array.writeMany(");\n");
                }
            }
            writeOptString(array, opt_string, .length, char);
        } else {
            if (abstract) {
                array.writeMany("array.writeMany(opt_switch);\n");
            } else {
                array.writeMany("array.writeMany(\"");
                array.writeMany(opt_string);
                if (combine_char) {
                    array.writeMany("\\x");
                    array.writeFormat(CharacteristicFormat{ .value = char });
                }
                array.writeMany("\");\n");
            }
        },
        .length => {
            if (abstract) {
                array.writeMany("len+%=opt_switch.len;\n");
            } else {
                array.writeMany("len+%=");
                if (combine_char) {
                    array.writeFormat(fmt.ud64(opt_string.len +% 1));
                } else {
                    array.writeFormat(fmt.ud64(opt_string.len));
                }
                array.writeMany(";\n");
            }
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
    opt_switch_string: ?[]const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (opt_switch_string) |switch_string| {
        writeOptStringExtra(array, switch_string, variant, char);
    }
    writeFormatterInternal(array, arg_string, variant);
}
fn writeOptionalFormatter(
    array: *Array,
    opt_switch_string: ?[]const u8,
    arg_string: []const u8,
    variant: types.Variant,
    char: u8,
) void {
    if (opt_switch_string) |switch_string| {
        writeOptStringExtra(array, switch_string, variant, char);
    }
    writeFormatterInternal(array, arg_string, variant);
}
fn writeFunctionSignature(array: *Array, opt_spec: types.OptionSpec, variant: types.Variant) void {
    if (abstract) {
        array.writeMany("fn ");
        array.writeMany(@tagName(variant));
        array.writeMany("_");
        array.writeMany(@tagName(opt_spec.arg_info.tag));
        switch (variant) {
            .write => {
                if (opt_spec.arg_info.tag == .boolean) {
                    array.writeMany("(buf:[*]u8,opt_switch:[]const u8,boolean:bool)u64{\n");
                } else {
                    array.writeMany("(buf:[*]u8,opt_switch:[]const u8,optional:anytype,c:u8)u64{\n");
                }
            },
            .length => {
                if (opt_spec.arg_info.tag == .boolean) {
                    array.writeMany("(opt_switch:[]const u8,boolean:bool)u64{\n");
                } else {
                    array.writeMany("(opt_switch:[]const u8,optional:anytype)u64{\n");
                }
            },
        }
        array.writeMany("var len:u64=0;\n");
    }
}
fn writeFunctionSignature2(array: *Array, opt_spec: types.OptionSpec, no_opt_spec: types.InverseOptionSpec, variant: types.Variant) void {
    if (abstract) {
        array.writeMany("fn ");
        array.writeMany(@tagName(variant));
        array.writeMany("_");
        array.writeMany(@tagName(opt_spec.arg_info.tag));
        array.writeMany("_");
        array.writeMany(@tagName(no_opt_spec.arg_info.tag));
        if (variant == .write) {
            array.writeMany("(buf:[*]u8,opt_switch:[]const u8,optional:anytype,c:u8)u64{\n");
        } else {
            array.writeMany("(opt_switch:[]const u8,optional:anytype)u64{\n");
        }
        array.writeMany("var len:u64=0;\n");
    }
}
fn writeFunctionReturn(array: *Array) void {
    if (abstract) {
        array.writeMany("return len;\n");
        array.writeMany("}\n");
    }
}
fn writeUniqueBlock(array: *Array, arrays: *Arrays, indices: *Indices, off: u64, idx: u64) u64 {
    const new_blk: []const u8 = array.readManyBack(array.len() -% off);
    if (abstract) {
        for (arrays.readAll(), 0..) |unique_blk, unique_idx| {
            if (builtin.testEqualMemory([]const u8, unique_blk, new_blk)) {
                indices.overwriteOneAt(idx, unique_idx);
                array.undefine(new_blk.len);
                return off;
            }
        } else {
            arrays.writeOne(new_blk);
        }
    }
    return off +% new_blk.len;
}
pub fn writeFunctionBody(array: *Array, options: []const types.OptionSpec, variant: types.Variant, arrays: *Arrays, indices: *Indices) void {
    var off: u64 = array.len();
    for (options, 0..) |opt_spec, idx| {
        off = writeUniqueBlock(array, arrays, indices, off, idx);
        const if_boolean_field_value: []const u8 = if (abstract) "boolean" else opt_spec.name;
        const if_optional_field_value: []const u8 = if (abstract) "optional" else opt_spec.name;
        const if_optional_field_capture: []const u8 = if (abstract) "capture" else opt_spec.name;
        if (opt_spec.and_no) |no_opt_spec| {
            if (opt_spec.arg_info.tag == .boolean and no_opt_spec.arg_info.tag == .boolean) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature2(array, opt_spec, no_opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeIf(array, if_optional_field_capture);
                writeOptStringExtra(array, opt_spec.string.?, variant, char);
                writeElse(array);
                writeOptStringExtra(array, no_opt_spec.string.?, variant, char);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .string and
                no_opt_spec.arg_info.tag == .boolean)
            {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature2(array, opt_spec, no_opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "arg");
                writeOptArgString(array, opt_spec.string.?, "arg", variant, char);
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string.?, variant, char);
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .formatter and no_opt_spec.arg_info.tag == .boolean) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature2(array, opt_spec, no_opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "arg");
                writeFormatter(array, opt_spec.string, "arg", variant, char);
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string.?, variant, char);
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_formatter and no_opt_spec.arg_info.tag == .boolean) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature2(array, opt_spec, no_opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeSwitch(array, if_optional_field_capture);
                writeRequiredProng(array, "yes", "yes");
                writeIfOptional(array, "yes", "arg");
                writeOptionalFormatter(array, opt_spec.string, "arg", variant, opt_spec.arg_info.char orelse '=');
                writeElse(array);
                writeOptStringExtra(array, opt_spec.string.?, variant, char);
                writeIfClose(array);
                writeProngClose(array);
                writeProng(array, "no");
                writeOptStringExtra(array, no_opt_spec.string.?, variant, char);
                writeProngClose(array);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            unhandledCommandFieldAndNo(opt_spec, no_opt_spec);
        } else {
            if (opt_spec.arg_info.tag == .boolean) {
                writeFunctionSignature(array, opt_spec, variant);
                writeIfField(array, if_boolean_field_value);
                writeOptStringExtra(array, opt_spec.string.?, variant, '\x00');
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_string) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgString(array, opt_spec.string.?, if_optional_field_capture, variant, char);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_tag) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptTagString(array, opt_spec.string.?, if_optional_field_capture, variant, char);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_integer) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeOptArgInteger(array, opt_spec.string.?, if_optional_field_capture, variant, char);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_formatter) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeFormatter(array, opt_spec.string, if_optional_field_capture, variant, char);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_mapped) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeMapped(array, opt_spec.string, if_optional_field_capture, variant, char);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .repeatable_string) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptArgString(array, opt_spec.string.?, "value", variant, char);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .repeatable_tag) {
                const char: u8 = opt_spec.arg_info.char orelse '\x00';
                writeFunctionSignature(array, opt_spec, variant);
                writeIfOptionalField(array, if_optional_field_value, if_optional_field_capture);
                writeForEach(array, if_optional_field_capture, "value");
                writeOptTagString(array, opt_spec.string.?, "value", variant, char);
                writeIfClose(array);
                writeIfClose(array);
                writeFunctionReturn(array);
                continue;
            }
            unhandledCommandField(opt_spec);
        }
    }
}
fn unhandledCommandFieldAndNo(opt_spec: types.OptionSpec, no_opt_spec: types.InverseOptionSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.arg_info.tag), "+", @tagName(no_opt_spec.arg_info.tag),
    });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn unhandledCommandField(opt_spec: types.OptionSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.arg_info.tag), "\n",
    });
    builtin.proc.exitFault(buf[0..len], 2);
}
fn writeFile(array: *Array, pathname: [:0]const u8) void {
    const build_fd: u64 = file.create(create_spec, pathname, file.mode.regular);
    file.writeSlice(write_spec, build_fd, array.readAll());
    file.close(close_spec, build_fd);
}
fn writeBuildWrite(array: *Array, arrays: *Arrays, indices: *Indices) void {
    if (!abstract) {
        if (primitive) {
            array.writeMany(
                \\pub fn buildWriteBuf(cmd:*const tasks.BuildCommand,zig_exe:[]const u8,root_path:types.Path,buf:[*]u8)u64{
                \\@setRuntimeSafety(false);
                \\mach.memcpy(buf,zig_exe.ptr,zig_exe.len);
                \\var len:u64=zig_exe.len;
                \\buf[len]=0;
                \\len+%=1;
                \\mach.memcpy(buf+len,"build-",6);
                \\len+%=6;
                \\mach.memcpy(buf+len,@tagName(cmd.kind).ptr,@tagName(cmd.kind).len);
                \\len+%=@tagName(cmd.kind).len;
                \\buf[len]=0;
                \\len+%=1;
                \\
            );
        } else {
            array.writeMany(
                \\pub fn buildWrite(cmd:*const tasks.BuildCommand,zig_exe:[]const u8,root_path:types.Path,array:anytype)void{
                \\array.writeMany(zig_exe);
                \\array.writeOne('\x00');
                \\array.writeMany("build-");
                \\array.writeMany(@tagName(cmd.kind));
                \\array.writeOne('\x00');
                \\
            );
        }
    }
    writeFunctionBody(array, attr.build_command_options, .write, arrays, indices);
    if (!abstract) {
        if (primitive) {
            array.writeMany(
                \\len+%=root_path.formatWriteBuf(buf+len);
                \\buf[len]=0;
                \\return len;
                \\
            );
        } else {
            array.writeMany(
                \\array.writeFormat(root_path);
                \\
            );
        }
        array.writeMany("}\n");
        array.writeMany(
            \\pub fn buildLength(cmd:*const tasks.BuildCommand,zig_exe:[]const u8,root_path:types.Path)u64{
            \\@setRuntimeSafety(false);
            \\var len:u64=zig_exe.len+%@tagName(cmd.kind).len+%8;
            \\
        );
    }
    writeFunctionBody(array, attr.build_command_options, .length, arrays, indices);
    if (!abstract) {
        array.writeMany(
            \\return len+%root_path.formatLength()+%1;
            \\
        );
        array.writeMany("}\n");
    }
}
fn writeFormatWrite(array: *Array, arrays: *Arrays, indices: *Indices) void {
    if (!abstract) {
        if (primitive) {
            array.writeMany(
                \\pub fn formatWriteBuf(cmd:*const tasks.FormatCommand,zig_exe:[]const u8,root_path:types.Path,buf:[*]u8)u64{
                \\@setRuntimeSafety(false);
                \\mach.memcpy(buf,zig_exe.ptr,zig_exe.len);
                \\var len:u64=zig_exe.len;
                \\buf[len]=0;
                \\len+%=1;
                \\mach.memcpy(buf+len,"fmt\x00",4);
                \\len+%=4;
                \\
            );
        } else {
            array.writeMany(
                \\pub fn formatWrite(cmd:*const tasks.FormatCommand,zig_exe:[]const u8,root_path:types.Path,array:anytype)void{
                \\@setRuntimeSafety(false);
                \\array.writeMany(zig_exe);
                \\array.writeOne('\x00');
                \\array.writeMany("fmt\x00");
                \\
            );
        }
    }
    writeFunctionBody(array, attr.format_command_options, .write, arrays, indices);
    if (!abstract) {
        if (primitive) {
            array.writeMany(
                \\len+%=root_path.formatWriteBuf(buf+len);
                \\buf[len]=0;
                \\return len;
                \\
            );
        } else {
            array.writeMany(
                \\array.writeFormat(root_path);
                \\
            );
        }
        array.writeMany("}\n");
        array.writeMany(
            \\pub fn formatLength(cmd:*const tasks.FormatCommand,zig_exe:[]const u8,root_path:types.Path)u64{
            \\@setRuntimeSafety(false);
            \\var len:u64=zig_exe.len+%5;
            \\
        );
    }
    writeFunctionBody(array, attr.format_command_options, .length, arrays, indices);
    if (!abstract) {
        array.writeMany(
            \\return len+%root_path.formatLength()+%1;
            \\
        );
        array.writeMany("}\n");
    }
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    const arrays: *Arrays = allocator.create(Arrays);
    const build_idc: *Indices = allocator.create(Indices);
    const format_idc: *Indices = allocator.create(Indices);
    var fd: u64 = file.open(open_spec, config.command_line_template_path);
    array.define(file.read(read_spec, fd, array.referAllUndefined()));
    file.close(close_spec, fd);
    writeBuildWrite(array, arrays, build_idc);
    writeFormatWrite(array, arrays, format_idc);
    if (compile) {
        array.writeMany("comptime {" ++
            (if (primitive) "_ = buildWriteBuf;" else "_ = buildWrite;") ++ "_ = buildLength;" ++
            (if (primitive) "_ = formatWriteBuf;" else "_ = formatWrite;") ++ "_ = formatLength;" ++
            "}\n");
    }
    if (!primitive) {
        array.writeMany("const fmt=@import(\"../fmt.zig\");\n");
    }
    if (abstract) {
        file.write(write_spec, 1, array.readAll());
    } else {
        gen.truncateFile(write_spec, config.command_line_path, array.readAll());
    }
    array.undefineAll();
}
