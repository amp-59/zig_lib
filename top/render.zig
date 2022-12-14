const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const lit = @import("./lit.zig");
const zig = @import("./zig.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
const abstract = @import("./abstract.zig");

pub const RenderSpec = struct {
    radix: u16 = render_radix,
    radix_field_name_suffixes: ?[]const RadixFieldName = null,
    string_literal: ?bool = true,
    multi_line_string_literal: ?bool = false,
    omit_trailing_comma: ?bool = null,
    omit_default_fields: bool = true,
    infer_type_name: bool = false,
    infer_type_name_recursively: bool = false,
    inline_field_types: bool = false,
    enable_comptime_iterator: bool = false,

    const RadixFieldName = struct {
        radix: u16 = render_radix,
        prefix: ?[]const u8 = null,
        suffix: ?[]const u8 = null,
    };
    const default: RenderSpec = .{};
};

const render_type_names: bool = builtin.config("render_type_names", bool, true);
const render_radix: u16 = builtin.config("render_radix", u16, 10);

pub fn any(value: anytype) AnyFormat(@TypeOf(value), RenderSpec.default) {
    return .{ .value = value };
}
pub fn render(comptime options: RenderSpec, value: anytype) AnyFormat(@TypeOf(value), options) {
    return .{ .value = value };
}
fn typeName(comptime T: type) []const u8 {
    return @typeName(T);
}

pub fn AnyFormat(comptime Type: type, comptime options: RenderSpec) type {
    return switch (@typeInfo(Type)) {
        .Array => ArrayFormat(Type, options),
        .Bool => BoolFormat,
        .Type => TypeFormat(options),
        .Struct => StructFormat(Type, options),
        .Union => UnionFormat(Type, options),
        .Enum => EnumFormat(Type),
        .EnumLiteral => EnumLiteralFormat(Type, options),
        .ComptimeInt => ComptimeIntFormat(options),
        .Int => IntFormat(Type, options),
        .Pointer => |pointer_info| switch (pointer_info.size) {
            .One => PointerOneFormat(Type, options),
            .Many => PointerManyFormat(Type, options),
            .Slice => PointerSliceFormat(Type, options),
            else => @compileError(typeName(Type)),
        },
        .Optional => OptionalFormat(Type, options),
        .Null => NullFormat,
        .Void => VoidFormat,
        .NoReturn => NoReturnFormat,
        .Vector => VectorFormat(Type, options),
        .ErrorUnion => ErrorUnionFormat(Type),
        .ErrorSet => ErrorSetFormat(Type, options),
        else => @compileError(typeName(Type)),
    };
}
fn GenericRenderFormat(comptime Format: type) type {
    return struct {
        const StaticString = mem.StaticString(Format.max_len);
        fn formatConvert(format: Format) StaticString {
            var array: StaticString = .{};
            array.writeFormat(format);
            return array;
        }
        fn checkLen(len: u64) u64 {
            if (@hasDecl(Format, "max_len") and len != Format.max_len) {
                @panic("formatter max length exceeded");
            }
            return len;
        }
    };
}
pub fn ArrayFormat(comptime Array: type, comptime options: RenderSpec) type {
    return struct {
        value: Array,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child, child_options);
        const array_info: builtin.Type = @typeInfo(Array);
        const child: type = array_info.Array.child;
        const type_name: []const u8 = if (render_type_names) typeName(Array) else ".";
        const max_len: u64 = (type_name.len + 2) + array_info.Array.len * (ChildFormat.max_len + 2);
        const omit_trailing_comma: bool = options.omit_trailing_comma orelse true;
        const child_options: RenderSpec = blk: {
            var tmp: RenderSpec = options;
            tmp.infer_type_name = @typeInfo(child) == .Struct;
            break :blk tmp;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (format.value.len == 0) {
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (comptime options.enable_comptime_iterator and fmt.requireComptime(child)) {
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
            if (comptime options.enable_comptime_iterator and fmt.requireComptime(child)) {
                inline for (format.value) |value| {
                    len += ChildFormat.formatLength(.{ .value = value }) + 2;
                }
            } else {
                for (format.value) |value| {
                    len += ChildFormat.formatLength(.{ .value = value }) + 2;
                }
            }
            if (!omit_trailing_comma and format.value.len != 0) {
                len += 1;
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
pub fn TypeFormat(comptime options: RenderSpec) type {
    return struct {
        const Format: type = @This();
        value: type,
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const type_info: builtin.Type = @typeInfo(format.value);
            switch (type_info) {
                .Struct => |struct_info| {
                    if (struct_info.fields.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (struct_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            const FieldFormat = AnyFormat(field.type, options);
                            if (options.inline_field_types) {
                                const type_format: TypeFormat(options) = .{ .value = field.type };
                                field_name_format.formatWrite(array);
                                array.writeMany(": ");
                                type_format.formatWrite(array);
                            } else {
                                array.writeMany(field.name ++ ": " ++ comptime typeName(field.type));
                            }
                            if (meta.defaultValue(field)) |default_value| {
                                const field_format: FieldFormat = .{ .value = default_value };
                                array.writeMany(" = ");
                                field_format.formatWrite(array);
                            }
                            array.writeCount(2, ", ".*);
                        }
                        array.writeMany("}");
                    }
                },
                .Union => |union_info| {
                    if (union_info.fields.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (union_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            if (field.type == void) {
                                array.writeMany(field.name ++ ", ");
                            } else {
                                if (options.inline_field_types) {
                                    field_name_format.formatWrite(array);
                                    array.writeMany(": ");
                                    const type_format: TypeFormat(options) = .{ .value = field.type };
                                    type_format.formatWrite(array);
                                } else {
                                    array.writeMany(field.name ++ ": " ++ comptime typeName(field.type));
                                }
                                array.writeCount(2, ", ".*);
                            }
                        }
                        array.writeMany("}");
                    }
                },
                .Enum => |enum_info| {
                    if (enum_info.fields.len == 0) {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (enum_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            field_name_format.formatWrite(array);
                            array.writeCount(2, ", ".*);
                        }
                        array.writeMany("}");
                    }
                },
                .Int, .Type, .Optional, .ComptimeInt, .Bool, .Pointer, .Array, .NoReturn, .Void => {
                    array.writeMany(typeName(format.value));
                },
                else => @compileError("???: " ++ @tagName(@typeInfo(format.value))),
            }
        }
        pub fn formatLength(comptime format: Format) u64 {
            const type_info: builtin.Type = @typeInfo(format.value);
            var len: u64 = 0;
            switch (type_info) {
                .Struct => |struct_info| {
                    if (struct_info.fields.len == 0) {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (struct_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            const FieldFormat = AnyFormat(field.type, options);
                            if (options.inline_field_types) {
                                const type_format: TypeFormat(options) = .{ .value = field.type };
                                len += field_name_format.formatLength() + 2;
                                len += type_format.formatLength();
                            } else {
                                len += field_name_format.formatLength() + 2 + typeName(field.type).len;
                            }
                            if (meta.defaultValue(field)) |default_value| {
                                const field_format: FieldFormat = .{ .value = default_value };
                                len += 3;
                                len += field_format.formatLength();
                            }
                            len += 2;
                        }
                        len += 1;
                    }
                },
                .Union => |union_info| {
                    if (union_info.fields.len == 0) {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (union_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            if (field.type == void) {
                                len += field_name_format.formatLength() + 2;
                            } else {
                                if (options.inline_field_types) {
                                    len += field_name_format.formatLength() + 2;
                                    const type_format: TypeFormat(options) = .{ .value = field.type };
                                    len += type_format.formatLength();
                                } else {
                                    len += field_name_format.formatLength() + 2 + typeName(field.type).len;
                                }
                                len += 2;
                            }
                        }
                        len += 1;
                    }
                },
                .Enum => |enum_info| {
                    if (enum_info.fields.len == 0) {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    } else {
                        len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                        inline for (enum_info.fields) |field| {
                            const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                            len += field_name_format.formatLength() + 2;
                        }
                        len += 1;
                    }
                },
                .Int, .Type, .Optional, .ComptimeInt, .Bool, .Pointer, .Array, .NoReturn, .Void => {
                    len += typeName(format.value).len;
                },
                else => @compileError("???: " ++ @tagName(@typeInfo(format.value))),
            }
            return len;
        }
    };
}
fn formatWriteField(array: anytype, field_name_format: anytype, field_format: anytype) void {
    array.writeOne('.');
    field_name_format.formatWrite(array);
    array.writeCount(3, " = ".*);
    field_format.formatWrite(array);
    array.writeCount(2, ", ".*);
}
fn StructFormat(comptime Struct: type, comptime options: RenderSpec) type {
    return struct {
        value: Struct,
        const Format: type = @This();
        const type_name: []const u8 = if (render_type_names) typeName(Struct) else ".";
        const fields: []const builtin.StructField = @typeInfo(Struct).Struct.fields;
        const omit_trailing_comma: bool = options.omit_trailing_comma orelse false;
        const max_len: u64 = blk: {
            var len: u64 = 0;
            if (options.infer_type_name) {
                len += 3;
            } else {
                len += type_name.len + 2;
            }
            if (fields.len == 0) {
                len += 1;
            } else {
                inline for (fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    len += 1 + field_name_format.formatLength() + 3;
                    len += AnyFormat(field.type, options).max_len;
                    len += 2;
                }
            }
            break :blk len;
        };
        const field_options: RenderSpec = blk: {
            var tmp: RenderSpec = options;
            tmp.infer_type_name = options.infer_type_name_recursively;
            break :blk tmp;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (fields.len == 0) {
                if (options.infer_type_name) {
                    array.writeMany(".{}");
                } else {
                    array.writeMany(type_name ++ "{}");
                }
            } else {
                var fields_len: usize = 0;
                if (options.infer_type_name) {
                    array.writeMany(".{ ");
                } else {
                    array.writeMany(type_name ++ "{ ");
                }
                inline for (fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    const FieldFormat = AnyFormat(field.type, field_options);
                    const field_value: field.type = @field(format.value, field.name);
                    const field_format: FieldFormat = .{ .value = field_value };
                    if (options.omit_default_fields and field.default_value != null and
                        comptime meta.isTriviallyComparable(field.type))
                    {
                        if (field_value != mem.pointerOpaque(field.type, field.default_value.?).*) {
                            formatWriteField(array, field_name_format, field_format);
                            fields_len += 1;
                        }
                    } else {
                        formatWriteField(array, field_name_format, field_format);
                        fields_len += 1;
                    }
                }
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
        }
        pub fn formatLength(format: anytype) u64 {
            var len: u64 = 0;
            if (options.infer_type_name) {
                len += 3;
            } else {
                len += type_name.len + 2;
            }
            var fields_len: usize = 0;
            inline for (fields) |field| {
                const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                const FieldFormat = AnyFormat(field.type, field_options);
                const field_value: field.type = @field(format.value, field.name);
                if (options.omit_default_fields and field.default_value != null and
                    comptime meta.isTriviallyComparable(field.type))
                {
                    if (field_value != mem.pointerOpaque(field.type, field.default_value.?).*) {
                        const field_format: FieldFormat = .{ .value = field_value };
                        len += 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
                        fields_len += 1;
                    }
                } else {
                    const field_format: FieldFormat = .{ .value = field_value };
                    len += 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
                    fields_len += 1;
                }
            }
            if (!omit_trailing_comma and fields_len != 0) {
                len += 1;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn UnionFormat(comptime Union: type, comptime options: RenderSpec) type {
    return struct {
        value: Union,
        const Format: type = @This();
        const fields: []const builtin.UnionField = @typeInfo(Union).Union.fields;
        const type_name: []const u8 = if (render_type_names) typeName(Union) else ".";
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
                    len += field_name_format.formatLength();
                }
                len += fields.len * 3;
                // The length of 'bit_field('
                len += 10;
                // The length of the integer tag_type name
                len += typeName(enum_info.Enum.tag_type);
                // The length of ') {'
                len += 3;
                // The length of '}'
                len += 1;
                // The number of fields - 1, for each potential '|' between
                // tag names.
                len += fields.len - 1;
                // The maximum length of the potential remainder value + 4; the
                // remainder is separated by "~|", to show the bits of the value
                // which did not match, and has spaces on each side.
                len += 2 + 1 + IntFormat(enum_info.Enum.tag_type).max_len + 1;
                break :blk len;
            } else {
                var max_field_len: u64 = 0;
                inline for (fields) |field| {
                    max_field_len = @max(max_field_len, AnyFormat(field.type, options).max_len);
                }
                break :blk (type_name.len + 2) + 1 + meta.maxDeclLength(Union) + 3 + max_field_len + 2;
            }
        };
        pub fn formatWriteEnumField(format: Format, array: anytype) void {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            array.writeMany("bit_field(" ++ comptime typeName(enum_info.Enum.tag_type) ++ "){ ");
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -= 1;
                const field: builtin.EnumField = enum_info.Enum.fields[i];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        array.writeMany("." ++ field.name ++ " | ");
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    array.writeFormat(IntFormat(enum_info.Enum.tag_type, options){ .value = x });
                    array.writeCount(2, " }".*);
                } else {
                    array.undefine(1);
                    array.overwriteCountBack(2, " }".*);
                }
            } else {
                if (x != 0) {
                    array.writeFormat(IntFormat(enum_info.Enum.tag_type, options){ .value = x });
                    array.writeCount(2, " }".*);
                } else {
                    array.overwriteOneBack('}');
                }
            }
        }
        pub fn formatLengthEnumField(format: Format) u64 {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            var len: u64 = 10 + typeName(enum_info.Enum.tag_type).len + 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -= 1;
                const field: builtin.EnumField = enum_info.Enum.fields[i];
                const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        len += 1 + field_name_format.formatLength() + 3;
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                len -= 1;
            }
            return len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            if (show_enum_field) {
                return formatWriteEnumField(format, array);
            }
            if (fields.len == 0) {
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (comptime @typeInfo(Union).Union.tag_type) |tag_type| {
                    inline for (fields) |field| {
                        const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        if (format.value == @field(tag_type, field.name)) {
                            const FieldFormat: type = AnyFormat(field.type, options);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            formatWriteField(field_name_format, field_format);
                        }
                    }
                    array.overwriteManyBack(" }");
                } else {
                    array.overwriteManyBack("}");
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
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    if (format.value == @field(tag_type, field.name)) {
                        const FieldFormat = AnyFormat(field.type, options);
                        const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                        len += 1 + field_name_format.formatLength() + 3 + field_format.formatLength() + 2;
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
        const tag_name = @tagName(format.value);
        array.writeMany("." ++ tag_name);
    }
    pub fn formatLength(comptime format: Format) u64 {
        return 1 + @tagName(format.value).len;
    }
    pub usingnamespace GenericRenderFormat(Format);
};
pub fn ComptimeIntFormat(comptime options: RenderSpec) type {
    return struct {
        value: comptime_int,
        const Format: type = @This();
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const Int: type = meta.LeastRealBitSize(format.value);
            const real_format: IntFormat(Int, options) = .{ .value = format.value };
            return real_format.formatWrite(array);
        }
        pub fn formatLength(comptime format: Format) u64 {
            const Int: type = meta.LeastRealBitSize(format.value);
            const real_format: IntFormat(Int, options) = .{ .value = format.value };
            return real_format.formatLength();
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn IntFormat(comptime Int: type, comptime options: RenderSpec) type {
    return struct {
        value: Int,
        const Format: type = @This();
        const Abs: type = @Type(.{ .Int = .{ .bits = type_info.Int.bits, .signedness = .unsigned } });
        const type_info: builtin.Type = @typeInfo(Int);
        const max_abs_value: Abs = ~@as(Abs, 0);
        const radix: Abs = @min(max_abs_value, options.radix);
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
            const start: u64 = array.impl.next();
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
            array.impl.define(next - start);
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
fn PointerOneFormat(comptime Pointer: type, comptime options: RenderSpec) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const SubFormat = meta.Return(fmt.ux64);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: u64 = (4 + typeName(Pointer).len + 3) + AnyFormat(child, options).max_len + 1;
        pub fn formatWrite(format: Format, array: anytype) void {
            const type_name: []const u8 = comptime typeName(Pointer);
            if (child == anyopaque) {
                array.writeMany("@intToPtr(" ++ type_name ++ ", ");
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                array.writeFormat(sub_format);
            } else {
                array.writeMany(("@as(" ++ type_name ++ ", &"));
                const sub_format: AnyFormat(child, options) = .{ .value = format.value.* };
                sub_format.formatWrite(array);
            }
            array.writeMany(")");
        }
        pub fn formatLength(format: Format) u64 {
            const type_name: []const u8 = typeName(Pointer);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                return 10 + type_name.len + 2 + sub_format.formatLength() + 1;
            } else {
                const sub_format: AnyFormat(child, options) = .{ .value = format.value.* };
                return 4 + type_name.len + 3 + sub_format.formatLength() + 1;
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub fn PointerSliceFormat(comptime Pointer: type, comptime options: RenderSpec) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child, options);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: u64 = 65536;
        const omit_trailing_comma: bool = options.omit_trailing_comma orelse true;
        pub fn formatLengthAny(format: anytype) u64 {
            const type_name = comptime if (render_type_names) typeName(Pointer) else "&.";
            var len: u64 = type_name.len + 2;
            if (comptime options.enable_comptime_iterator and fmt.requireComptime(child)) {
                inline for (format.value) |value| {
                    len += AnyFormat(child, options).formatLength(.{ .value = value }) + 2;
                }
            } else {
                for (format.value) |value| {
                    len += AnyFormat(child, options).formatLength(.{ .value = value }) + 2;
                }
            }
            if (!omit_trailing_comma and format.value.len != 0) {
                len += 1;
            }
            return len;
        }
        pub fn formatWriteAny(format: anytype, array: anytype) void {
            const type_name = comptime if (render_type_names) typeName(Pointer) else "&.";
            if (format.value.len == 0) {
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (comptime options.enable_comptime_iterator and fmt.requireComptime(child)) {
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
            len += 1;
            for (format.value) |c| {
                len += lit.lit_hex_sequences[c].len;
            }
            len += 1;
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
            len += 1;
            return len;
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (comptime child == u8) {
                if (options.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) return formatWriteMultiLineStringLiteral(format, array);
                }
                if (options.string_literal) |render_string_literal| {
                    if (render_string_literal) return formatWriteStringLiteral(format, array);
                }
            }
            return formatWriteAny(format, array);
        }
        pub fn formatLength(format: anytype) u64 {
            if (comptime child == u8) {
                if (options.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) return formatLengthMultiLineStringLiteral(format);
                }
                if (options.string_literal) |render_string_literal| {
                    if (render_string_literal) return formatLengthStringLiteral(format);
                }
            }
            return formatLengthAny(format);
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
pub fn PointerManyFormat(comptime Pointer: type, comptime options: RenderSpec) type {
    return struct {
        value: Pointer,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child, options);
        const type_info: builtin.Type = @typeInfo(Pointer);
        const child: type = type_info.Pointer.child;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (type_info.Pointer.sentinel == null) {
                const type_name: []const u8 = comptime typeName(Pointer);
                array.writeMany(type_name ++ "{ ... }");
            } else {
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(Slice, options);
                const slice_fmt: slice_fmt_type = .{ .value = meta.manyToSlice(format.value) };
                return slice_fmt.formatWrite(array);
            }
        }
        pub fn formatLength(format: Format) u64 {
            if (type_info.Pointer.sentinel == null) {
                const type_name: []const u8 = comptime typeName(Pointer);
                return type_name.len + 7;
            } else {
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(Slice, options);
                const slice_fmt: slice_fmt_type = .{ .value = meta.manyToSlice(format.value) };
                return slice_fmt.formatLength();
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn OptionalFormat(comptime Optional: type, comptime options: RenderSpec) type {
    return struct {
        value: Optional,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child, options);
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
                len += 4 + type_name.len + 2;
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                len += sub_format.formatLength();
            } else {
                len += 4;
            }
            if (!render_readable) {
                len += 1;
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
fn VectorFormat(comptime Vector: type, comptime options: RenderSpec) type {
    return struct {
        value: Vector,
        const Format: type = @This();
        const ChildFormat: type = AnyFormat(child, options);
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
                len += element_format.formatLength() + 2;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
fn ErrorUnionFormat(comptime ErrorUnion: type, comptime options: RenderSpec) type {
    return struct {
        value: ErrorUnion,
        const Format: type = @This();
        const type_info: builtin.Type = @typeInfo(ErrorUnion);
        const PayloadFormat: type = AnyFormat(type_info.ErrorUnion.payload, options);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                array.writeFormat(payload_format);
            } else |any_error| {
                array.writeMany("error.");
                array.writeMany(@errorName(any_error));
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                len += payload_format.formatLength();
            } else |any_error| {
                len += 6;
                len += @errorName(any_error).len;
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
