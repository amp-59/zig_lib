const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const lit = @import("./lit.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub fn AnyFormat(comptime Type: type) type {
    return switch (@typeInfo(Type)) {
        .Array => ArrayFormat(Type),
        //            .Fn => FnFormat(Type),
        //            .Bool => BoolFormat,
        //            .Type => TypeFormat,
        //            .Struct => StructFormat(Type),
        //            .Union => UnionFormat(Type),
        //            .Enum => EnumFormat(Type),
        //            .EnumLiteral => EnumLiteralFormat(Type),
        .ComptimeInt => ComptimeIntFormat,
        .Int => IntFormat(Type),
        //            .Pointer => |pointer_info| switch (pointer_info.size) {
        //                .One => PointerOneFormat(Type),
        //                .Many => PointerManyFormat(Type),
        //                .Slice => PointerSliceFormat(Type),
        //                else => @compileError(comptime shortTypeName(Type)),
        //            },
        //            .Optional => OptionalFormat(Type),
        //            .Null => NullFormat(Type),
        //            .Void => VoidFormat,
        //            .Vector => VectorFormat(Type),
        //            .ErrorUnion => ErrorUnionFormat(Type),
        else => @compileError(comptime fmt.shortTypeName(Type)),
    };
}

fn GenericRenderFormat(comptime Format: type) type {
    return struct {
        const StaticString = mem.StaticString(Format.max_len);
        pub fn formatConvert(format: Format) StaticString {
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

const RenderSpec = struct {
    type: type,
    options: Options,
    const Options = struct {};
};

// Array
pub fn ArrayFormat(comptime Array: type) type {
    return struct {
        value: Array,
        const Format = @This();
        const ElementFormat = AnyFormat(child);
        const array_info: builtin.Type = @typeInfo(Array);
        const child: type = array_info.Array.child;
        const type_name: []const u8 = fmt.shortTypeName(Array);
        const max_len: u64 = (type_name.len + 2) +
            array_info.Array.len * (ElementFormat.max_len + 2);
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeMany((type_name ++ "{ "));
            for (format.value) |element| {
                const element_format: ElementFormat = .{ .value = element };
                element_format.formatWrite(array);
                array.writeMany(", ");
            }
            array.overwriteManyBack(" }");
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            len += type_name.len + 2;
            for (format.value) |element| {
                const element_format: ElementFormat = .{ .value = element };
                len += element_format.formatLength() + 2;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
//  Function
//  Boolean
//
//  Type
//
pub const TypeFormat = struct {
    const Format = @This();
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
                        const FieldFormat = AnyFormat(field.field_type);
                        if (render_composite_field_type_recursively) {
                            const field_type_format: TypeFormat = .{ .value = field.field_type };
                            array.writeMany(field.name ++ ": ");
                            field_type_format.formatWrite(array);
                        } else {
                            array.writeMany(field.name ++ ": " ++ @typeName(field.field_type));
                        }
                        if (meta.defaultValue(field)) |default_value| {
                            const field_format: FieldFormat = .{ .value = default_value };
                            array.writeMany(" = ");
                            field_format.formatWrite(array);
                        }
                        array.writeMany(", ");
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
                        if (field.field_type == void) {
                            array.writeMany(field.name ++ ", ");
                        } else {
                            if (render_composite_field_type_recursively) {
                                array.writeMany(field.name ++ ": ");
                                const field_type_format: TypeFormat = .{ .value = field.field_type };
                                field_type_format.formatWrite(array);
                            } else {
                                array.writeMany(field.name ++ ": " ++ @typeName(field.field_type));
                            }
                            array.writeMany(", ");
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
                        array.writeMany(field.name ++ ", ");
                    }
                    array.writeMany("}");
                }
            },
            .Int, .Type, .Optional, .ComptimeInt, .Bool, .Pointer => {
                array.writeMany(@typeName(format.value));
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
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}").len;
                } else {
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ").len;
                    inline for (struct_info.fields) |field| {
                        const FieldFormat = AnyFormat(field.field_type);
                        if (render_composite_field_type_recursively) {
                            const field_type_format: TypeFormat = .{ .value = field.field_type };
                            len += (field.name ++ ": ").len;
                            len += field_type_format.formatLength();
                        } else {
                            len += (field.name ++ ": " ++ @typeName(field.field_type)).len;
                        }
                        if (meta.defaultValue(field)) |default_value| {
                            const field_format: FieldFormat = .{ .value = default_value };
                            len += (" = ").len;
                            len += field_format.formatLength();
                        }
                        len += (", ").len;
                    }
                    len += ("}").len;
                }
            },
            .Union => |union_info| {
                if (union_info.fields.len == 0) {
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}").len;
                } else {
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ").len;
                    inline for (union_info.fields) |field| {
                        if (field.field_type == void) {
                            len += (field.name ++ ", ").len;
                        } else {
                            if (render_composite_field_type_recursively) {
                                len += (field.name ++ ": ").len;
                                const field_type_format: TypeFormat = .{ .value = field.field_type };
                                len += field_type_format.formatLength();
                            } else {
                                len += (field.name ++ ": " ++ @typeName(field.field_type)).len;
                            }
                            len += (", ").len;
                        }
                    }
                    len += ("}").len;
                }
            },
            .Enum => |enum_info| {
                if (enum_info.fields.len == 0) {
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {}").len;
                } else {
                    len += (comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " { ").len;
                    inline for (enum_info.fields) |field| {
                        len += (field.name ++ ", ").len;
                    }
                    len += ("}").len;
                }
            },
            .Int, .Type, .Optional, .ComptimeInt, .Bool, .Pointer => {
                len += @typeName(format.value).len;
            },
            else => @compileError("???: " ++ @tagName(@typeInfo(format.value))),
        }
        return len;
    }
};

//
//  Struct
//
pub fn StructFormat(comptime Struct: type) type {
    return struct {
        value: Struct,
        const Format = @This();
        const type_name: []const u8 = fmt.shortTypeName(Struct);
        const fields: []const builtin.Structield = @typeInfo(Struct).Struct.fields;

        const omit_default_fields: bool = true;
        const omit_compiler_given_names: bool = true;

        const max_len: u64 = blk: {
            var len: u64 = 0;
            if (omit_compiler_given_names and mem.startsWith(u8, "struct:", type_name)) {
                len += 3;
            } else {
                len += type_name.len + 2;
            }
            if (fields.len == 0) {
                len += 1;
            } else {
                inline for (fields) |field| {
                    len += 1 + field.name.len + 3;
                    len += AnyFormat(field.field_type).max_len;
                    len += 2;
                }
            }
            break :blk len;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (fields.len == 0) {
                if (omit_compiler_given_names and mem.startsWith(u8, "struct:", type_name)) {
                    array.writeMany(".{}");
                } else {
                    array.writeMany(type_name ++ "{}");
                }
            } else {
                if (omit_compiler_given_names and mem.startsWith(u8, "struct:", type_name)) {
                    array.writeMany(".{");
                } else {
                    array.writeMany(type_name ++ "{ ");
                }
                inline for (fields) |field| {
                    const FieldFormat = AnyFormat(field.field_type);
                    const field_value: field.field_type = @field(format.value, field.name);
                    if (omit_default_fields and field.default_value != null and
                        meta.isTriviallyComparable(field.field_type))
                    {
                        const default_value: field.field_type =
                            mem.pointerOpaque(field.field_type, field.default_value.?);
                        if (field_value != default_value) {
                            const field_format: FieldFormat = .{ .value = field_value };
                            array.writeMany(("." ++ field.name ++ " = "));
                            field_format.formatWrite(array);
                            array.writeMany(", ");
                        }
                    } else {
                        const field_format: FieldFormat = .{ .value = field_value };
                        array.writeMany("." ++ field.name ++ " = ");
                        field_format.formatWrite(array);
                        array.writeMany(", ");
                    }
                }
                if (mem.equalMany(u8, array.rereadMany(2), "{ ")) {
                    array.rewriteOne('}');
                } else {
                    array.rewriteMany(" }");
                }
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (omit_default_fields and mem.startsWith(u8, "struct:", type_name)) {
                len += 2;
            } else {
                len += type_name.len + 2;
            }
            inline for (fields) |field| {
                const FieldFormat = AnyFormat(field.field_type);
                const field_value: field.field_type = @field(format.value, field.name);
                if (omit_default_fields and field.default_value != null and
                    meta.isTriviallyComparable(field.field_type))
                {
                    const default_value: field.field_type =
                        mem.pointerOpaque(field.field_type, field.default_value.?);
                    if (field_value != default_value) {
                        const field_format: FieldFormat = .{ .value = field_value };
                        len += 1 + field.name.len + 3 + field_format.formatLength() + 2;
                    }
                } else {
                    const field_format: FieldFormat = .{ .value = field_value };
                    len += 1 + field.name.len + 3 + field_format.formatLength() + 2;
                }
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
//
//  Union
//
//
//  Enum
//
//
//  EnumLiteral
//
//
//  ComptimeInt
//
//
//  Int
//
//
//  Pointer
//
//
//      One
//
//
//      Many
//
//
//      Slice
//
//
//  Optional
//
//
//  Null
//
//
//  Void
//
//
//  Vector
//
//
//  ErrorUnion
//
//
const render_composite_field_type_recursively: bool = true;
