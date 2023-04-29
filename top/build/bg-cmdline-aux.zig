const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const proc = @import("../proc.zig");
const file = @import("../file.zig");
const spec = @import("../spec.zig");
const testing = @import("../testing.zig");
const builtin = @import("../builtin.zig");

const attr = @import("./attr.zig");
const types = @import("./types.zig");

pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

pub const primitive: bool = true;

const Array = mem.StaticString(1024 * 1024);
const build_root: [:0]const u8 = builtin.buildRoot();
const command_line_path: [:0]const u8 = build_root ++ "/top/build/command_line3.zig";
const command_line_template_path: [:0]const u8 = build_root ++ "/top/build/command_line-template.zig";

const open_spec: file.OpenSpec = .{
    .errors = .{},
    .logging = .{},
};
const creat_spec: file.CreateSpec = .{
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
const path_spec: file.PathSpec = .{
    .errors = .{},
    .logging = .{},
};
const stat_spec: file.StatusSpec = .{
    .errors = .{},
    .logging = .{},
};
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
fn writeIfOptionalField(array: *Array, field_name: []const u8) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany(")|");
    array.writeMany(field_name);
    array.writeMany("|{\n");
}
fn writeIfOptional(array: *Array, value_name: []const u8, capture_name: []const u8) void {
    array.writeMany("if(");
    array.writeMany(value_name);
    array.writeMany(")|");
    array.writeMany(capture_name);
    array.writeMany("|{\n");
}
fn writeYesOptionalIf(array: *Array) void {
    array.writeMany("if(yes_optional_arg)|yes_arg|{\n");
}
fn writeNoOptionalIf(array: *Array) void {
    array.writeMany("if(no_optional_arg)|no_arg|{\n");
}
fn writeSwitch(array: *Array, field_name: []const u8) void {
    array.writeMany("switch(");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeDefaultProng(array: *Array) void {
    array.writeMany(".default=>{\n");
}
fn writeExplicitProng(array: *Array) void {
    array.writeMany(".explicit=>|how|{\n");
}
fn writeNoProng(array: *Array) void {
    array.writeMany(".no=>{\n");
}
fn writeYesProng(array: *Array) void {
    array.writeMany(".yes=>{\n");
}
fn writeNoRequiredProng(array: *Array) void {
    array.writeMany(".no=>|no_arg|{\n");
}
fn writeYesRequiredProng(array: *Array) void {
    array.writeMany(".yes=>|yes_arg|{\n");
}
fn writeYesOptionalProng(array: *Array) void {
    array.writeMany(".yes=>|yes_optional_arg|{\n");
}
fn writeNoOptionalProng(array: *Array) void {
    array.writeMany(".no=>|no_optional_arg|{\n");
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
        .length => array.writeMany("len=len+%1;\n"),
        .write => array.writeMany("buf[len]=0;\nlen=len+%1;\n"),
    }
}
fn writeOne(array: *Array, one: u8, variant: types.Variant) void {
    switch (variant) {
        .length => array.writeMany("len=len+%1;\n"),
        .write => {
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(";len=len+%1\n");
        },
    }
}
fn writeIntegerString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("const s: []const u8 = builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll();\n@memcpy(buf+len,s.ptr,s.len);\n");
            writeOptString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll().len;\n");
        },
    }
}
fn writeTagString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").ptr,@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len);\n");
            writeTagString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len;\n");
        },
    }
}
fn writeOptString(array: *Array, opt_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,\"");
            array.writeMany(opt_string);
            array.writeMany("\\x00\",");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(");\n");
            writeOptString(array, opt_string, .length);
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(";\n");
        },
    }
}
fn writeOptAssignString(array: *Array, opt_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,\"");
            array.writeMany(opt_string);
            array.writeMany("=\",");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(");\n");
            writeOptAssignString(array, opt_string, .length);
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(";\n");
        },
    }
}
fn writeArgString(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,");
            array.writeMany(arg_string);
            array.writeMany(".ptr,");
            array.writeMany(arg_string);
            array.writeMany(".len);\n");
            writeArgString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".len;\n");
        },
    }
}
fn writeFormatterInternal(array: *Array, arg_string: []const u8, variant: types.Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".formatWriteBuf(buf+len);\n");
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".formatLength();\n");
        },
    }
}
fn writeMapped(array: *Array, opt_switch_string: ?[]const u8, arg_string: []const u8, variant: types.Variant) void {
    if (opt_switch_string) |switch_string| {
        writeOptString(array, switch_string, variant);
    }
    switch (variant) {
        .write => {
            array.writeMany("len=len+%formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatWriteBuf(buf+len);\n");
        },
        .length => {
            array.writeMany("len=len+%formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatLength();\n");
        },
    }
}
fn writeOptArgInteger(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: types.Variant) void {
    writeOptString(array, opt_string, variant);
    writeIntegerString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptArgString(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: types.Variant) void {
    writeOptString(array, opt_string, variant);
    writeArgString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptTagString(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: types.Variant) void {
    writeOptString(array, opt_string, variant);
    writeTagString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeFormatter(array: *Array, opt_switch_string: ?[]const u8, arg_string: []const u8, variant: types.Variant) void {
    if (opt_switch_string) |switch_string| {
        writeOptString(array, switch_string, variant);
    }
    writeFormatterInternal(array, arg_string, variant);
}
fn writeOptionalFormatter(array: *Array, opt_switch_string: ?[]const u8, arg_string: []const u8, variant: types.Variant) void {
    if (opt_switch_string) |switch_string| {
        writeOptAssignString(array, switch_string, variant);
    }
    writeFormatterInternal(array, arg_string, variant);
}
pub fn writeFunctionBody(array: *Array, options: []const types.OptionSpec, variant: types.Variant) void {
    for (options) |opt_spec| {
        if (opt_spec.and_no) |no_opt_spec| {
            if (opt_spec.arg_info.tag == .boolean) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeIf(array, opt_spec.name);
                    writeOptString(array, opt_spec.string.?, variant);
                    writeElse(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            if (opt_spec.arg_info.tag == .string) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeSwitch(array, opt_spec.name);
                    writeYesRequiredProng(array);
                    writeOptArgString(array, opt_spec.string.?, "yes_arg", variant);
                    writeProngClose(array);
                    writeNoProng(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeProngClose(array);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            if (opt_spec.arg_info.tag == .formatter) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeSwitch(array, opt_spec.name);
                    writeYesRequiredProng(array);
                    writeFormatter(array, opt_spec.string, "yes_arg", variant);
                    writeProngClose(array);
                    writeNoProng(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeProngClose(array);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            if (opt_spec.arg_info.tag == .optional_formatter) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeSwitch(array, opt_spec.name);
                    writeYesRequiredProng(array);
                    writeIfOptional(array, "yes_arg", "yes_optional_arg");
                    writeOptionalFormatter(array, opt_spec.string, "yes_optional_arg", variant);
                    writeElse(array);
                    writeOptString(array, opt_spec.string.?, variant);
                    writeIfClose(array);
                    writeProngClose(array);
                    writeNoProng(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeProngClose(array);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            unhandledCommandFieldAndNo(opt_spec, no_opt_spec);
        } else {
            if (opt_spec.arg_info.tag == .boolean) {
                writeIfField(array, opt_spec.name);
                writeOptString(array, opt_spec.string.?, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_string) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptArgString(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_tag) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptTagString(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_integer) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptArgInteger(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_formatter) {
                writeIfOptionalField(array, opt_spec.name);
                writeFormatter(array, opt_spec.string, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_mapped) {
                writeIfOptionalField(array, opt_spec.name);
                writeMapped(array, opt_spec.string, opt_spec.name, variant);
                writeIfClose(array);
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
    builtin.proc.exitWithFaultMessage(buf[0..len], 2);
}
fn unhandledCommandField(opt_spec: types.OptionSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.arg_info.tag), "\n",
    });
    builtin.proc.exitWithFaultMessage(buf[0..len], 2);
}
fn writeFile(array: Array, pathname: [:0]const u8) void {
    const build_fd: u64 = file.create(creat_spec, pathname, file.file_mode);
    file.writeSlice(write_spec, build_fd, array.readAll());
    file.close(close_spec, build_fd);
}
pub fn main() !void {
    var array: Array = undefined;
    array.undefineAll();
    var st: file.Status = file.pathStatus(stat_spec, command_line_path);
    var fd: u64 = file.open(open_spec, command_line_template_path);
    array.define(file.readSlice(read_spec, fd, array.referAllUndefined()[0..st.size]));
    file.close(close_spec, fd);
    array.writeMany("pub fn buildWrite(cmd:*const tasks.BuildCommand,buf:[*]u8)u64{\n");
    array.writeMany("var len:u64=0;\n");
    writeFunctionBody(&array, attr.build_command_options, .write);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn buildLength(cmd: *const tasks.BuildCommand)u64{\n");
    array.writeMany("var len:u64=0;\n");
    writeFunctionBody(&array, attr.build_command_options, .length);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn formatLength(cmd:*const tasks.FormatCommand)u64{\n");
    array.writeMany("var len: u64 = 0;\n");
    writeFunctionBody(&array, attr.format_command_options, .length);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn formatWrite(cmd:*const tasks.FormatCommand,buf:[*]u8)u64{\n");
    array.writeMany("var len: u64 = 0;\n");
    writeFunctionBody(&array, attr.format_command_options, .write);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    writeFile(array, command_line_path);
    array.undefineAll();
}
