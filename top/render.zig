const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const lit = @import("./lit.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
const abstract = @import("./abstract.zig");

pub const RenderSpec = struct {
    radix: u16 = render_radix,
    radix_field_name_suffixes: ?[]const RadixFieldName = null,

    string_literal: ?bool = true,
    multi_line_string_literal: ?bool = false,

    omit_default_fields: bool = true,
    omit_container_decls: bool = true,
    omit_trailing_comma: ?bool = null,
    omit_type_names: bool = false,
    infer_type_names: bool = false,
    infer_type_names_recursively: bool = false,
    zig_type_names: bool = false,
    type_cast_generic: bool = true,

    inline_field_types: bool = true,
    enable_comptime_iterator: bool = false,

    ignore_formatter_decls: bool = true,
    ignore_container_decls: bool = false,

    const RadixFieldName = struct {
        radix: u16 = render_radix,
        prefix: ?[]const u8 = null,
        suffix: ?[]const u8 = null,
    };
    const default: RenderSpec = .{};
};

const render_radix: u16 = builtin.config("render_radix", u16, 10);

pub inline fn any(value: anytype) AnyFormat(RenderSpec.default, @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn render(comptime spec: RenderSpec, value: anytype) AnyFormat(spec, @TypeOf(value)) {
    return .{ .value = value };
}
inline fn typeName(comptime T: type, comptime spec: RenderSpec) []const u8 {
    if (spec.infer_type_names or
        spec.infer_type_names_recursively)
    {
        return ".";
    } else if (spec.omit_type_names) {
        return "";
    } else {
        return fmt.typeName(T);
    }
}
fn writeFieldInitializer(array: anytype, field_name_format: fmt.IdentifierFormat, field_format: anytype) void {
    array.writeOne('.');
    field_name_format.formatWrite(array);
    array.writeCount(3, " = ".*);
    field_format.formatWrite(array);
    array.writeCount(2, ", ".*);
}

pub fn AnyFormat(comptime spec: RenderSpec, comptime Type: type) type {
    if (Type == meta.Generic) {
        return GenericFormat(spec);
    }
    return switch (@typeInfo(Type)) {
        .Array => ArrayFormat(spec, Type),
        .Bool => BoolFormat,
        .Type => TypeFormat(spec),
        .Struct => StructFormat(spec, Type),
        .Union => UnionFormat(spec, Type),
        .Enum => EnumFormat(Type),
        .EnumLiteral => EnumLiteralFormat(spec, Type),
        .ComptimeInt => ComptimeIntFormat,
        .Int => IntFormat(spec, Type),
        .Pointer => |pointer_info| switch (pointer_info.size) {
            .One => PointerOneFormat(spec, Type),
            .Many => PointerManyFormat(spec, Type),
            .Slice => PointerSliceFormat(spec, Type),
            else => @compileError(@typeName(Type)),
        },
        .Optional => OptionalFormat(spec, Type),
        .Null => NullFormat,
        .Void => VoidFormat,
        .NoReturn => NoReturnFormat,
        .Vector => VectorFormat(spec, Type),
        .ErrorUnion => ErrorUnionFormat(spec, Type),
        .ErrorSet => ErrorSetFormat(spec, Type),
        else => @compileError(@typeName(Type)),
    };
}

fn GenericRenderFormat(comptime Format: type) type {
    comptime {
        builtin.static.assertNotEqual(builtin.TypeId, @typeInfo(Format), .Pointer);
    }
    return struct {
        pub fn formatConvert(format: anytype) mem.StaticString(if (@hasDecl(Format, "max_len"))
            Format.max_len
        else
            Format.formatLength(format.*)) {
            var array: mem.StaticString(if (@hasDecl(Format, "max_len"))
                Format.max_len
            else
                Format.formatLength(format.*)) = .{};
            array.writeFormat(format.*);
            return array;
        }
        fn checkLen(len: u64) u64 {
            if (@hasDecl(Format, "max_len") and len != Format.max_len) {
                builtin.debug.logFault("formatter max length exceeded");
            }
            return len;
        }
    };
}
fn GenericFormat(comptime spec: RenderSpec) type {
    return struct {
        value: meta.Generic,
        const Format = @This();
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            AnyFormat(spec, format.value.type).formatWrite(.{ .value = meta.typeCast(format.value) }, array);
        }
        pub fn formatLength(comptime format: Format) u64 {
            return AnyFormat(spec, format.value.type).formatLength(.{ .value = meta.typeCast(format.value) });
        }
    };
}
pub fn ArrayFormat(comptime spec: RenderSpec, comptime Array: type) type {
    return struct {
        value: Array,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child_spec, child);
        const array_info: builtin.Type = @typeInfo(Array);
        const child: type = array_info.Array.child;
        const type_name: []const u8 = typeName(Array, spec);
        const max_len: u64 = (type_name.len + 2) + array_info.Array.len * (ChildFormat.max_len + 2);
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
        const child_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = @typeInfo(child) == .Struct;
            break :blk tmp;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (format.value.len == 0) {
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (comptime spec.enable_comptime_iterator and fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        sub_format.formatWrite(array);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        sub_format.formatWrite(array);
                        array.writeCount(2, ", ".*);
                    }
                }
                if (omit_trailing_comma) {
                    array.overwriteCountBack(2, " }".*);
                } else {
                    array.writeOne('}');
                }
            }
        }
        pub fn formatLength(format: anytype) u64 {
            var len: u64 = type_name.len + 2;
            if (comptime spec.enable_comptime_iterator and fmt.requireComptime(child)) {
                inline for (format.value) |value| {
                    len +%= ChildFormat.formatLength(.{ .value = value }) + 2;
                }
            } else {
                for (format.value) |value| {
                    len +%= ChildFormat.formatLength(.{ .value = value }) + 2;
                }
            }
            if (!omit_trailing_comma and format.value.len != 0) {
                len +%= 1;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub const BoolFormat = struct {
    value: bool,
    const Format: type = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.value) {
            array.writeCount(4, "true".*);
        } else {
            array.writeCount(5, "false".*);
        }
    }
    pub fn formatLength(format: Format) u64 {
        return if (format.value) 4 else 5;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
pub fn TypeFormat(comptime spec: RenderSpec) type {
    return struct {
        const Format: type = @This();
        value: type,

        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse false;
        const default_value_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = true;
            break :blk tmp;
        };
        const field_type_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = false;
            break :blk tmp;
        };
        fn writeDecl(comptime format: Format, array: anytype, comptime decl: builtin.Declaration) void {
            if (!decl.is_pub) {
                return;
            }
            const decl_type: type = @TypeOf(@field(format.value, decl.name));
            if (@typeInfo(decl_type) == .Fn) {
                return;
            }
            const decl_value: decl_type = @field(format.value, decl.name);
            const decl_name_format: fmt.IdentifierFormat = .{ .value = decl.name };
            const decl_format: AnyFormat(default_value_spec, decl_type) = .{ .value = decl_value };
            array.writeMany("pub const ");
            decl_name_format.formatWrite(array);
            array.writeMany(": " ++ comptime typeName(decl_type, field_type_spec) ++ " = ");
            decl_format.formatWrite(array);
            array.writeCount(2, "; ".*);
        }
        fn lengthDecl(comptime format: Format, comptime decl: builtin.Declaration) u64 {
            if (!decl.is_pub) {
                return 0;
            }
            const decl_type: type = @TypeOf(@field(format.value, decl.name));
            if (@typeInfo(decl_type) == .Fn) {
                return 0;
            }
            var len: u64 = 0;
            const decl_value: decl_type = @field(format.value, decl.name);
            const DeclFormat = AnyFormat(default_value_spec, decl_type);
            len +%= 10;
            len +%= fmt.IdentifierFormat.formatLength(.{ .value = decl.name });
            len +%= 2 +% typeName(decl_type, field_type_spec).len +% 3;
            len +%= DeclFormat.formatLength(.{ .value = decl_value });
            len +%= 2;
            return len;
        }
        fn writeStructField(array: anytype, field_name: []const u8, comptime field_type: type, field_default_value: ?field_type) void {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            if (spec.inline_field_types) {
                const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                field_name_format.formatWrite(array);
                array.writeMany(": ");
                type_format.formatWrite(array);
            } else {
                const field_type_name: []const u8 = comptime typeName(field_type, field_type_spec);
                field_name_format.formatWrite(array);
                array.writeMany(": " ++ field_type_name);
            }
            if (field_default_value) |default_value| {
                const field_format: AnyFormat(default_value_spec, field_type) = .{ .value = default_value };
                array.writeMany(" = ");
                field_format.formatWrite(array);
            }
            array.writeCount(2, ", ".*);
        }
        fn writeUnionField(array: anytype, field_name: []const u8, comptime field_type: type) void {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            if (field_type == void) {
                array.appendFormat(field_name_format);
                array.writeMany(", ");
            } else {
                if (spec.inline_field_types) {
                    field_name_format.formatWrite(array);
                    array.writeMany(": ");
                    const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                    type_format.formatWrite(array);
                } else {
                    const field_type_name: []const u8 = typeName(field_type, field_type_spec);
                    field_name_format.formatWrite(array);
                    array.writeMany(": " ++ field_type_name);
                }
                array.writeCount(2, ", ".*);
            }
        }
        fn writeEnumField(array: anytype, field_name: []const u8) void {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            field_name_format.formatWrite(array);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const type_info: builtin.Type = @typeInfo(format.value);
            switch (type_info) {
                .Struct => |struct_info| {
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (struct_info.fields) |field| {
                            writeStructField(array, field.name, field.type, meta.defaultValue(field));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            formatWriteOmitTrailingComma(
                                array,
                                omit_trailing_comma,
                                struct_info.fields.len + struct_info.decls.len,
                            );
                        } else {
                            formatWriteOmitTrailingComma(array, omit_trailing_comma, struct_info.fields.len);
                        }
                    }
                },
                .Union => |union_info| {
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (union_info.fields) |field| {
                            writeUnionField(array, field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            formatWriteOmitTrailingComma(
                                array,
                                omit_trailing_comma,
                                union_info.fields.len + union_info.decls.len,
                            );
                        } else {
                            formatWriteOmitTrailingComma(array, omit_trailing_comma, union_info.fields.len);
                        }
                    }
                },
                .Enum => |enum_info| {
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (enum_info.fields) |field| {
                            writeEnumField(array, field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            formatWriteOmitTrailingComma(
                                array,
                                omit_trailing_comma,
                                enum_info.fields.len + enum_info.decls.len,
                            );
                        } else {
                            formatWriteOmitTrailingComma(array, omit_trailing_comma, enum_info.fields.len);
                        }
                    }
                },
                else => {
                    array.writeMany(typeName(format.value, spec));
                },
            }
        }
        pub fn formatLength(comptime format: Format) u64 {
            const type_info: builtin.Type = @typeInfo(format.value);
            var len: u64 = 0;
            switch (type_info) {
                .Struct => |struct_info| {
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (struct_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            if (spec.inline_field_types) {
                                const type_format: TypeFormat(field_type_spec) = .{ .value = field.type };
                                len +%= field_name_format.formatLength() + 2;
                                len +%= type_format.formatLength();
                            } else {
                                len +%= field_name_format.formatLength() + 2 + typeName(field.type, field_type_spec).len;
                            }
                            if (meta.defaultValue(field)) |default_value| {
                                const field_format: AnyFormat(default_value_spec, field.type) = .{ .value = default_value };
                                len +%= 3;
                                len +%= field_format.formatLength();
                            }
                            len +%= 2;
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                            len +%= formatLengthOmitTrailingComma(
                                omit_trailing_comma,
                                struct_info.fields.len + struct_info.decls.len,
                            );
                        } else {
                            len +%= formatLengthOmitTrailingComma(omit_trailing_comma, struct_info.fields.len);
                        }
                        len +%= 1;
                    }
                },
                .Union => |union_info| {
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (union_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            if (field.type == void) {
                                len +%= field_name_format.formatLength() + 2;
                            } else {
                                if (spec.inline_field_types) {
                                    len +%= field_name_format.formatLength() + 2;
                                    const type_format: TypeFormat(field_type_spec) = .{ .value = field.type };
                                    len +%= type_format.formatLength();
                                } else {
                                    len +%= field_name_format.formatLength() + 2 + typeName(field.type, field_type_spec).len;
                                }
                                len +%= 2;
                            }
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                            len +%= formatLengthOmitTrailingComma(
                                omit_trailing_comma,
                                union_info.fields.len + union_info.decls.len,
                            );
                        } else {
                            len +%= formatLengthOmitTrailingComma(omit_trailing_comma, union_info.fields.len);
                        }
                        len +%= 1;
                    }
                },
                .Enum => |enum_info| {
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len +%= comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (enum_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            len +%= field_name_format.formatLength() + 2;
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                            len +%= formatLengthOmitTrailingComma(
                                omit_trailing_comma,
                                enum_info.fields.len + enum_info.decls.len,
                            );
                        } else {
                            len +%= formatLengthOmitTrailingComma(omit_trailing_comma, enum_info.fields.len);
                        }
                        len +%= 1;
                    }
                },
                else => {
                    len +%= typeName(format.value, spec).len;
                },
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
inline fn formatWriteOmitTrailingComma(array: anytype, comptime omit_trailing_comma: bool, fields_len: u64) void {
    if (fields_len == 0) {
        array.overwriteOneBack('}');
    } else {
        if (omit_trailing_comma) {
            array.overwriteManyBack(" }");
        } else {
            array.writeOne('}');
        }
    }
}
inline fn formatLengthOmitTrailingComma(comptime omit_trailing_comma: bool, fields_len: u64) u64 {
    return builtin.int2a(u64, !omit_trailing_comma, fields_len != 0);
}

fn StructFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    if (!spec.ignore_formatter_decls) {
        if (@hasDecl(Struct, "formatWrite") and @hasDecl(Struct, "formatLength")) {
            return FormatFormat(Struct);
        }
    }
    if (!spec.ignore_container_decls) {
        if (@hasDecl(Struct, "readAll") and @hasDecl(Struct, "len")) {
            return ContainerFormat(spec, Struct);
        }
    }
    return struct {
        value: Struct,
        const Format: type = @This();
        const type_name: []const u8 = typeName(Struct, spec);
        const fields: []const builtin.Type.StructField = @typeInfo(Struct).Struct.fields;
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse false;
        const max_len: u64 = blk: {
            var len: u64 = 0;
            len +%= type_name.len + 2;
            if (fields.len == 0) {
                len +%= 1;
            } else {
                inline for (fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    len +%= 1 + field_name_format.formatLength() + 3;
                    len +%= AnyFormat(field.type, field_spec).max_len;
                    len +%= 2;
                }
            }
            break :blk len;
        };
        const field_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = true;
            break :blk tmp;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (fields.len == 0) {
                array.writeMany(type_name ++ "{}");
            } else {
                var fields_len: usize = 0;
                array.writeMany(type_name ++ "{ ");
                inline for (fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    const field_value: field.type = @field(format.value, field.name);
                    const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                    if (spec.omit_default_fields and field.default_value != null) {
                        if (!builtin.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            writeFieldInitializer(array, field_name_format, field_format);
                            fields_len +%= 1;
                        }
                    } else {
                        writeFieldInitializer(array, field_name_format, field_format);
                        fields_len +%= 1;
                    }
                }
                formatWriteOmitTrailingComma(array, omit_trailing_comma, fields_len);
            }
        }
        pub fn formatLength(format: anytype) u64 {
            var len: u64 = 0;
            len +%= type_name.len + 2;
            var fields_len: usize = 0;
            inline for (fields) |field| {
                const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                const FieldFormat = AnyFormat(field_spec, field.type);
                const field_value: field.type = @field(format.value, field.name);
                if (spec.omit_default_fields and field.default_value != null) {
                    if (!builtin.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                        const field_format: FieldFormat = .{ .value = field_value };
                        len +%= 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
                        fields_len +%= 1;
                    }
                } else {
                    const field_format: FieldFormat = .{ .value = field_value };
                    len +%= 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
                    fields_len +%= 1;
                }
            }
            len +%= formatLengthOmitTrailingComma(omit_trailing_comma, fields_len);
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn UnionFormat(comptime spec: RenderSpec, comptime Union: type) type {
    if (!spec.ignore_formatter_decls) {
        if (@hasDecl(Union, "formatWrite") and @hasDecl(Union, "formatLength")) {
            return FormatFormat(Union);
        }
    }
    return struct {
        value: Union,
        const Format: type = @This();
        const fields: []const builtin.UnionField = @typeInfo(Union).Union.fields;
        const type_name: []const u8 = typeName(Union, spec);
        const tag_type_name: []const u8 = typeName(@typeInfo(fields[0].type).Enum.tag_type, spec);
        const show_enum_field: bool = fields.len == 2 and (@typeInfo(fields[0].type) == .Enum and
            fields[1].type == @typeInfo(fields[0].type).Enum.tag_type);
        const max_len: u64 = blk: {
            if (show_enum_field) {
                // e.g. bit_field(u32){ .PHDR | .NOTE | .DYNAMIC }
                // The combined length of every field name + 3; every name has
                // a space and a dot to its left, and a space to its right.
                var len: u64 = 0;
                const enum_info: builtin.Type = @typeInfo(fields[0].type);
                inline for (enum_info.Enum.fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    len +%= field_name_format.formatLength();
                }
                len +%= fields.len * 3;
                // The length of 'bit_field('
                len +%= 10;
                // The length of the integer tag_type name
                len +%= tag_type_name.len;
                // The length of ') {'
                len +%= 3;
                // The length of '}'
                len +%= 1;
                // The number of fields - 1, for each potential '|' between
                // tag names.
                len +%= fields.len - 1;
                // The maximum length of the potential remainder value + 4; the
                // remainder is separated by "~|", to show the bits of the value
                // which did not match, and has spaces on each side.
                len +%= 2 + 1 + IntFormat(enum_info.Enum.tag_type).max_len + 1;
                break :blk len;
            } else {
                var max_field_len: u64 = 0;
                inline for (fields) |field| {
                    max_field_len = @max(max_field_len, AnyFormat(spec, field.type).max_len);
                }
                break :blk (type_name.len + 2) + 1 + meta.maxDeclLength(Union) + 3 + max_field_len + 2;
            }
        };
        pub fn formatWriteEnumField(format: Format, array: anytype) void {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            array.writeMany("bit_field(" ++ comptime typeName(enum_info.Enum.tag_type, spec) ++ "){ ");
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -= 1;
                const field: builtin.EnumField = enum_info.Enum.fields[i];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        array.writeOne('.');
                        array.writeFormat(fmt.IdentifierFormat{ .value = field.name });
                        array.writeMany(" | ");
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    array.writeFormat(spec, IntFormat(enum_info.Enum.tag_type){ .value = x });
                    array.writeCount(2, " }".*);
                } else {
                    array.undefine(1);
                    array.overwriteCountBack(2, " }".*);
                }
            } else {
                if (x != 0) {
                    array.writeFormat(spec, IntFormat(enum_info.Enum.tag_type){ .value = x });
                    array.writeCount(2, " }".*);
                } else {
                    array.overwriteOneBack('}');
                }
            }
        }
        pub fn formatLengthEnumField(format: Format) u64 {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            var len: u64 = 10 + typeName(enum_info.Enum.tag_type, spec).len + 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -= 1;
                const field: builtin.EnumField = enum_info.Enum.fields[i];
                const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        len +%= 1 + field_name_format.formatLength() + 3;
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                len -= 1;
            }
            return len;
        }
        fn formatWriteField(array: anytype, field_name_format: fmt.IdentifierFormat, field_format: anytype) void {
            array.writeOne('.');
            field_name_format.formatWrite(array);
            array.writeCount(3, " = ".*);
            field_format.formatWrite(array);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            if (show_enum_field) {
                return formatWriteEnumField(format, array);
            }
            if (fields.len == 0) {
                array.writeMany(type_name ++ "{}");
            } else {
                array.writeMany(type_name ++ "{ ");
                if (comptime @typeInfo(Union).Union.tag_type) |tag_type| {
                    inline for (fields) |field| {
                        if (format.value == @field(tag_type, field.name)) {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            if (field.type == void) {
                                array.undefine(2);
                                return field_name_format.formatWrite(array);
                            } else {
                                const FieldFormat: type = AnyFormat(spec, field.type);
                                const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                                formatWriteField(array, field_name_format, field_format);
                            }
                        }
                    }
                    array.overwriteCountBack(2, " }".*);
                } else {
                    array.overwriteOneBack('}');
                }
            }
        }
        pub fn formatLength(format: anytype) u64 {
            if (show_enum_field) {
                return format.formatLengthEnumField();
            }
            var len: u64 = type_name.len + 2;
            if (comptime @typeInfo(Union).Union.tag_type) |tag_type| {
                inline for (fields) |field| {
                    if (format.value == @field(tag_type, field.name)) {
                        const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            return len + 1 + field_name_format.formatLength();
                        } else {
                            const FieldFormat = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            len +%= 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
                        }
                    }
                }
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn EnumFormat(comptime T: type) type {
    return struct {
        value: T,
        const Format: type = @This();
        const max_len: u64 = 1 + meta.maxDeclLength(T);
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeOne('.');
            array.writeFormat(fmt.IdentifierFormat{ .value = @tagName(format.value) });
        }
        pub fn formatLength(format: Format) u64 {
            return 1 + fmt.IdentifierFormat.formatLength(.{ .value = @tagName(format.value) });
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub const EnumLiteralFormat = struct {
    value: @Type(.EnumLiteral),
    const Format: type = @This();
    const max_len: u64 = undefined;
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
        array.writeOne('.');
        tag_name_format.formatWrite(array);
    }
    pub fn formatLength(comptime format: Format) u64 {
        const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
        return 1 + tag_name_format.formatLength();
    }
    pub usingnamespace GenericRenderFormat(Format);
};
pub const ComptimeIntFormat = struct {
    value: comptime_int,
    const Format: type = @This();
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        array.writeMany(builtin.fmt.ci(format.value));
    }
    pub fn formatLength(comptime format: Format) u64 {
        return builtin.fmt.ci(format.value).len;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
fn IntFormat(comptime spec: RenderSpec, comptime Int: type) type {
    return struct {
        value: Int,
        const Format: type = @This();
        const Abs: type = @Type(.{ .Int = .{ .bits = type_info.Int.bits, .signedness = .unsigned } });
        const type_info: builtin.Type = @typeInfo(Int);
        const max_abs_value: Abs = ~@as(Abs, 0);
        const radix: Abs = @min(max_abs_value, spec.radix);
        const max_digits_count: u16 = builtin.fmt.length(Abs, max_abs_value, radix);
        const prefix: []const u8 = lit.int_prefixes[radix];
        const max_len: u64 = blk: {
            var len: u64 = max_digits_count;
            if (radix != 10) {
                len +%= prefix.len;
            }
            if (type_info.Int.signedness == .signed) {
                len +%= 1;
            }
            break :blk len;
        };
        inline fn absolute(format: Format) Abs {
            if (format.value < 0) {
                return 1 +% ~@bitCast(Abs, format.value);
            } else {
                return @bitCast(Abs, format.value);
            }
        }
        inline fn digits(format: Format) u64 {
            return builtin.fmt.length(Abs, format.absolute(), radix);
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            const start: u64 = @ptrToInt(array.referOneUndefined());
            var next: u64 = start;
            if (Abs != Int) {
                @intToPtr(*u8, next).* = '-';
            }
            next += @boolToInt(format.value < 0);
            if (radix != 10) {
                @intToPtr(*[prefix.len]u8, next).* =
                    @ptrCast(*const [prefix.len]u8, prefix.ptr).*;
                next +%= prefix.len;
            }
            var value: Abs = format.absolute();
            if (radix > max_abs_value) {
                @intToPtr(*u8, next).* = @as(u8, '0') +
                    @boolToInt(format.value != 0);
                next += 1;
            } else {
                const count: u64 = format.digits();
                next += count;
                var len: u64 = 0;
                while (len != count) : (value /= radix) {
                    len +%= 1;
                    @intToPtr(*u8, next -% len).* =
                        builtin.fmt.toSymbol(Abs, value, radix);
                }
            }
            array.define(next - start);
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = prefix.len;
            if (format.value < 0) {
                len +%= 1;
            }
            return len +% format.digits();
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn PointerOneFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const SubFormat = meta.Return(fmt.ux64);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: u64 = (4 + typeName(Pointer, spec).len + 3) + AnyFormat(spec, child).max_len + 1;
        pub fn formatWrite(format: Format, array: anytype) void {
            const type_name: []const u8 = comptime typeName(Pointer, spec);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                array.writeCount(12 + type_name.len, ("@intToPtr(" ++ type_name ++ ", ").*);
                sub_format.formatWrite(array);
                array.writeOne(')');
            } else if (@typeInfo(child) == .Fn) {
                array.writeMany("*call");
            } else {
                const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                if (!spec.infer_type_names) {
                    array.writeCount(6 + type_name.len, ("@as(" ++ type_name ++ ", ").*);
                }
                array.writeOne('&');
                sub_format.formatWrite(array);
                if (!spec.infer_type_names) {
                    array.writeOne(')');
                }
            }
        }
        pub fn formatLength(format: Format) u64 {
            const type_name: []const u8 = comptime typeName(Pointer, spec);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                return 10 + type_name.len + 2 + sub_format.formatLength() + 1;
            } else if (@typeInfo(child) == .Fn) {
                return 5;
            } else {
                const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                return 4 + type_name.len + 3 + sub_format.formatLength() + 1;
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub fn PointerSliceFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: u64 = 65536;
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
        const type_name: []const u8 = typeName(Pointer, spec);
        pub fn formatLengthAny(format: anytype) u64 {
            var len: u64 = @boolToInt(spec.infer_type_names) + type_name.len + 2;
            if (comptime spec.enable_comptime_iterator and fmt.requireComptime(child)) {
                inline for (format.value) |value| {
                    len +%= AnyFormat(spec, child).formatLength(.{ .value = value }) + 2;
                }
            } else {
                for (format.value) |value| {
                    len +%= AnyFormat(spec, child).formatLength(.{ .value = value }) + 2;
                }
            }
            if (!omit_trailing_comma and format.value.len != 0) {
                len +%= 1;
            }
            return len;
        }
        pub fn formatWriteAny(format: anytype, array: anytype) void {
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    array.writeOne('&');
                }
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                if (spec.infer_type_names) {
                    array.writeOne('&');
                }
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (comptime spec.enable_comptime_iterator and fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        sub_format.formatWrite(array);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        sub_format.formatWrite(array);
                        array.writeCount(2, ", ".*);
                    }
                }
                if (omit_trailing_comma) {
                    array.overwriteCountBack(2, " }".*);
                } else {
                    array.writeOne('}');
                }
            }
        }
        pub fn formatLengthStringLiteral(format: anytype) u64 {
            var len: u64 = 0;
            len +%= 1;
            for (format.value) |c| {
                len +%= lit.lit_hex_sequences[c].len;
            }
            len +%= 1;
            return len;
        }
        pub fn formatWriteStringLiteral(format: anytype, array: anytype) void {
            array.writeOne('"');
            for (format.value) |c| {
                array.writeMany(lit.lit_hex_sequences[c]);
            }
            array.writeOne('"');
        }
        pub fn formatWriteMultiLineStringLiteral(format: anytype, array: anytype) void {
            array.writeMany("\n\\\\");
            for (format.value) |c| {
                switch (c) {
                    '\t' => array.writeMany("\\t"),
                    '\n' => array.writeMany("\n\\\\"),
                    else => array.writeOne(c),
                }
            }
            array.writeOne('\n');
        }
        pub fn formatLengthMultiLineStringLiteral(format: Format) u64 {
            var len: u64 = 3;
            for (format.value) |c| {
                switch (c) {
                    '\t' => 2,
                    '\n' => 3,
                    else => 1,
                }
            }
            len +%= 1;
            return len;
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (comptime child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return formatWriteMultiLineStringLiteral(format, array);
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return formatWriteStringLiteral(format, array);
                    }
                }
            }
            return formatWriteAny(format, array);
        }
        pub fn formatLength(format: anytype) u64 {
            if (comptime child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return formatLengthMultiLineStringLiteral(format);
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return formatLengthStringLiteral(format);
                    }
                }
            }
            return formatLengthAny(format);
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub fn PointerManyFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const type_info: builtin.Type = @typeInfo(Pointer);
        const type_name: []const u8 = typeName(Pointer, spec);
        const child: type = type_info.Pointer.child;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (type_info.Pointer.sentinel == null) {
                array.writeMany(type_name ++ "{ ... }");
            } else {
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = meta.manyToSlice(format.value) };
                return slice_fmt.formatWrite(array);
            }
        }
        pub fn formatLength(format: Format) u64 {
            if (type_info.Pointer.sentinel == null) {
                return type_name.len + 7;
            } else {
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = meta.manyToSlice(format.value) };
                return slice_fmt.formatLength();
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn OptionalFormat(comptime spec: RenderSpec, comptime Optional: type) type {
    return struct {
        value: Optional,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Optional).Optional.child;
        const type_name: []const u8 = typeName(Optional);
        const max_len: u64 = (4 + type_name.len + 2) + @max(1 + ChildFormat.max_len, 5);
        const render_readable: bool = true;
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (!render_readable) {
                array.writeCount(4, "@as(".*);
                array.writeMany(type_name);
                array.writeCount(2, ", ".*);
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                sub_format.formatWrite(array);
            } else {
                array.writeCount(4, "null".*);
            }
            if (!render_readable) {
                array.writeOne(')');
            }
        }
        pub fn formatLength(format: anytype) u64 {
            var len: u64 = 0;
            if (!render_readable) {
                len +%= 4 + type_name.len + 2;
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                len +%= sub_format.formatLength();
            } else {
                len +%= 4;
            }
            if (!render_readable) {
                len +%= 1;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub const NullFormat = struct {
    comptime value: @TypeOf(null) = null,
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format: type = @This();
    const max_len: u64 = 4;
    pub fn formatWrite(array: anytype) void {
        array.writeMany("null");
    }
    pub fn formatLength() u64 {
        return 4;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
pub const VoidFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format: type = @This();
    const max_len: u64 = 2;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "{}".*);
    }
    pub fn formatLength() u64 {
        return 2;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
pub const NoReturnFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format: type = @This();
    const max_len: u64 = 8;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "noreturn".*);
    }
    pub fn formatLength() u64 {
        return 8;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
fn VectorFormat(comptime spec: RenderSpec, comptime Vector: type) type {
    return struct {
        value: Vector,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const vector_info: builtin.Type = @typeInfo(Vector);
        const child: type = vector_info.Vector.child;
        const type_name: []const u8 = typeName(Vector);
        const max_len: u64 = (type_name.len + 2) +
            vector_info.Vector.len * (ChildFormat.max_len + 2);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (vector_info.Vector.len == 0) {
                array.writeMany(type_name);
                array.writeMany("{}");
            } else {
                array.writeMany(type_name);
                array.writeMany("{ ");
                comptime var i: u64 = 0;
                inline while (i != vector_info.Vector.len) : (i += 1) {
                    const element_format: ChildFormat = .{ .value = format.value[i] };
                    element_format.formatWrite(array);
                    array.writeCount(2, ", ".*);
                }
                array.overwriteManyBack(" }");
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = type_name.len + 2;
            comptime var i: u64 = 0;
            inline while (i != vector_info.Vector.len) : (i += 1) {
                const element_format: ChildFormat = .{ .value = format.value[i] };
                len +%= element_format.formatLength() + 2;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn ErrorUnionFormat(comptime spec: RenderSpec, comptime ErrorUnion: type) type {
    return struct {
        value: ErrorUnion,
        const Format: type = @This();
        const type_info: builtin.Type = @typeInfo(ErrorUnion);
        const PayloadFormat: type = AnyFormat(spec, type_info.ErrorUnion.payload);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                payload_format.formatWrite(array);
            } else |any_error| {
                array.writeMany("error.");
                array.writeMany(@errorName(any_error));
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                len +%= payload_format.formatLength();
            } else |any_error| {
                len +%= 6;
                len +%= @errorName(any_error).len;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn ErrorSetFormat(comptime ErrorSet: type, comptime _: RenderSpec) type {
    return struct {
        value: ErrorSet,
        const Format: type = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeMany("error.");
            array.writeMany(@errorName(format.value));
        }
        pub fn formatLength(format: Format) u64 {
            return 6 + @errorName(format.value).len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub fn ContainerFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    return struct {
        value: Struct,
        const Format = @This();
        const values_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.omit_type_names = true;
            break :blk spec;
        };
        pub fn formatWrite(format: Format, array: anytype) void {
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                const values_format: ValuesFormat = .{ .value = format.value.readAll() };
                values_format.formatWrite(array);
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                values_format.formatWrite(array);
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                const values_format: ValuesFormat = .{ .value = format.value.readAll() };
                len +%= values_format.formatLength();
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                len +%= values_format.formatLength();
            }
            return len;
        }
    };
}
pub fn FormatFormat(comptime Struct: type) type {
    return struct {
        value: Struct,
        const Format = @This();
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return format.value.formatWrite(array);
        }
        pub inline fn formatLength(format: Format) u64 {
            return format.value.formatLength();
        }
    };
}
