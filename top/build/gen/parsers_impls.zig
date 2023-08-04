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
const output_mode_decls: bool = false;

const Array = mem.StaticString(64 * 1024 * 1024);
const Array256 = mem.StaticString(256);
const open_spec: file.OpenSpec = .{
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
fn writeIfElse(array: *Array) void {
    array.writeMany("}else\n");
}
fn writeIfClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeElse(array: *Array) void {
    array.writeMany("}else{\n");
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
    if (output_mode_decls) {
        array.writeMany("eql(\"");
    } else {
        array.writeMany("mem.testEqualString(\"");
    }
    array.writeMany(opt_string);
    array.writeMany("\",");
    writeArgSliceFromTo(array, 0, opt_string.len);
    array.writeMany(")");
}
fn writeEquals(array: *Array, opt_string: []const u8) void {
    if (output_mode_decls) {
        array.writeMany("eql(\"");
    } else {
        array.writeMany("mem.testEqualString(\"");
    }
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
fn writeArgCurIndex(array: *Array) void {
    if (output_mode_decls) {
        array.writeMany("str(args[args_idx])");
    } else {
        array.writeMany("mem.terminate(args[args_idx], 0)");
    }
}
fn writeArgAnyIndex(array: *Array, index: usize) void {
    if (output_mode_decls) {
        array.writeMany("str(args[");
    } else {
        array.writeMany("mem.terminate(args[");
    }
    array.writeFormat(fmt.ud64(index));
    if (output_mode_decls) {
        array.writeMany("])");
    } else {
        array.writeMany("], 0)");
    }
}
fn writeArgAddIndex(array: *Array, offset: usize) void {
    if (output_mode_decls) {
        array.writeMany("str(args[args_idx+%");
    } else {
        array.writeMany("mem.terminate(args[args_idx+%");
    }
    array.writeFormat(fmt.ud64(offset));

    if (output_mode_decls) {
        array.writeMany("])");
    } else {
        array.writeMany("],0)");
    }
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
            array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg[");
            array.writeFormat(fmt.ud64(offset));
            array.writeMany("..])};\n");
        },
        .no => |type_descr| {
            array.writeMany(".{.no=");
            array.writeFormat(type_descr);
            array.writeMany(".formatParseArgs(allocator,args[0..args_len],&args_idx,arg[");
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
                for (param_spec.type.parse.?.type_decl.defn.?.fields) |field| {
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
            .optional_repeatable_formatter_field => {
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
    array.writeMany("pub export fn ");
    array.writeMany(attributes.fn_name);
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
    if (output_mode_decls) {
        array.writeMany("const eql=if(builtin.output_mode==.Lib)");
        array.writeMany("mem.testEqualString else mach.testEqualMany8;\n");
        array.writeMany("const str=if(builtin.output_mode==.Lib)");
        array.writeMany("meta.manyToSlice else mach.manyToSlice80;\n");
    }
    array.writeMany("while(args_idx!=args_len):(args_idx+%=1){\n");
    if (output_mode_decls) {
        array.writeMany("var arg:[:0]const u8=str(args[args_idx]);\n");
    } else {
        array.writeMany("var arg:[:0]const u8=mem.terminate(args[args_idx],0);\n");
    }
}
fn writeFlagWithInverse(array: *Array, param_spec: types.ParamSpec, no_param_spec: types.InverseParamSpec) void {
    var yes_idx: usize = 0;
    var no_idx: usize = 0;
    const yes_string: []const u8 = param_spec.string;
    const no_string: []const u8 = no_param_spec.string;
    var yes_array: Array256 = undefined;
    var no_array: Array256 = undefined;
    var no: bool = false;
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
fn writeParserFunctionHelp(array: *Array, attributes: types.Attributes) void {
    array.writeMany("const ");
    array.writeMany(attributes.fn_name);
    array.writeMany("_help: [*:0]const u8 = ");
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
                for (0..max_width -% string_len) |_| array.writeMany(" ");
                array.writeMany(param_spec.descr[0]);
                for (param_spec.descr[1..]) |string| {
                    array.writeMany("\n\\\\    ");
                    for (0..max_width) |_| array.writeMany(" ");
                    array.writeMany(string);
                }
            }
            array.writeMany("\n");
        }
    }
    array.writeMany("\n;");
}
fn writeParserFunction(array: *Array, attributes: types.Attributes) void {
    writeParserFunctionSignature(array, attributes);
    writeParserFunctionBody(array, attributes);
    writeParserFunctionSpec(array, attributes);
}
pub fn main() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    const array: *Array = allocator.create(Array);
    const len: usize = try gen.readFile(.{ .return_type = usize }, config.parsers_template_path, array.referAllUndefined());
    array.define(len);
    for (attr.all) |attributes| {
        writeParserFunction(array, attributes);
    }
    for (attr.all) |attributes| {
        writeParserFunctionHelp(array, attributes);
    }
    try gen.truncateFile(.{ .return_type = void }, config.parsers_path, array.readAll());
}
