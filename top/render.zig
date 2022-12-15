const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const lit = @import("./lit.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

const render_composite_field_type_recursively: bool = true;
const render_string_literal: bool = true;
const render_multi_line_string_literal: bool = false;

pub fn AnyFormat(comptime Type: type) type {
    return switch (@typeInfo(Type)) {
        .Array => ArrayFormat(Type),
        //            .Fn => FnFormat(Type),
        .Bool => BoolFormat,
        .Type => TypeFormat,
        .Struct => StructFormat(Type),
        .Union => UnionFormat(Type),
        .Enum => EnumFormat(Type),
        //            .EnumLiteral => EnumLiteralFormat(Type),
        .ComptimeInt => ComptimeIntFormat,
        .Int => IntFormat(Type),
        .Pointer => |pointer_info| switch (pointer_info.size) {
            .One => PointerOneFormat(Type),
            //                .Many => PointerManyFormat(Type),
            .Slice => PointerSliceFormat(Type),
            else => @compileError(comptime fmt.typeName(Type)),
        },
        .Optional => OptionalFormat(Type),
        //            .Null => NullFormat(Type),
        //            .Void => VoidFormat,
        .Vector => VectorFormat(Type),
        //            .ErrorUnion => ErrorUnionFormat(Type),
        else => @compileError(comptime fmt.typeName(Type)),
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
        const type_name: []const u8 = fmt.typeName(Array);
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
pub const BoolFormat = struct {
    value: bool,
    const Format = @This();
    const max_len: u64 = @max(true_s.len, false_s.len);
    const t_s: []const u8 = if (render_minimal) "t" else "true";
    const f_s: []const u8 = if (render_minimal) "f" else "false";
    const true_s = if (render_effects) "\x1b[1m" ++ t_s ++ "\x1b[0m" else t_s;
    const false_s = if (render_effects) "\x1b[2m" ++ f_s ++ "\x1b[0m" else f_s;
    const render_minimal: bool = false;
    const render_effects: bool = false;
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.value) {
            array.writeMany(true_s);
        } else {
            array.writeMany(false_s);
        }
    }
    pub fn formatLength(format: Format) u64 {
        return if (format.value) true_s.len else false_s.len;
    }
    pub usingnamespace GenericRenderFormat(Format);
};

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
                    len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                } else {
                    len += comptime builtin.fmt.typeDeclSpecifier(type_info).len + 3;
                    inline for (struct_info.fields) |field| {
                        const FieldFormat = AnyFormat(field.field_type);
                        if (render_composite_field_type_recursively) {
                            const field_type_format: TypeFormat = .{ .value = field.field_type };
                            len += field.name.len + 2;
                            len += field_type_format.formatLength();
                        } else {
                            len += field.name.len + 2 + @typeName(field.field_type).len;
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
                        if (field.field_type == void) {
                            len += field.name.len + 2;
                        } else {
                            if (render_composite_field_type_recursively) {
                                len += field.name.len + 2;
                                const field_type_format: TypeFormat = .{ .value = field.field_type };
                                len += field_type_format.formatLength();
                            } else {
                                len += field.name.len + 2 + @typeName(field.field_type).len;
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
                        len += field.name.len + 2;
                    }
                    len += 1;
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
        const type_name: []const u8 = fmt.typeName(Struct);
        const fields: []const builtin.StructField = @typeInfo(Struct).Struct.fields;

        const omit_default_fields: bool = true;
        const omit_compiler_given_names: bool = true;

        const max_len: u64 = blk: {
            var len: u64 = 0;
            if (omit_compiler_given_names and mem.testEqualManyFront(u8, "struct:", type_name)) {
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
                if (omit_compiler_given_names and mem.testEqualManyFront(u8, "struct:", type_name)) {
                    array.writeMany(".{}");
                } else {
                    array.writeMany(type_name ++ "{}");
                }
            } else {
                if (omit_compiler_given_names and mem.testEqualManyFront(u8, "struct:", type_name)) {
                    array.writeMany(".{");
                } else {
                    array.writeMany(type_name ++ "{ ");
                }
                inline for (fields) |field| {
                    const FieldFormat = AnyFormat(field.field_type);
                    const field_value: field.field_type = @field(format.value, field.name);
                    if (omit_default_fields and field.default_value != null and
                        comptime meta.isTriviallyComparable(field.field_type))
                    {
                        const default_value: field.field_type =
                            mem.pointerOpaque(field.field_type, field.default_value.?).*;
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
                if (mem.testEqualMany(u8, array.readManyBack(2), "{ ")) {
                    array.overwriteOneBack('}');
                } else {
                    array.overwriteManyBack(" }");
                }
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (omit_default_fields and mem.testEqualManyFront(u8, "struct:", type_name)) {
                len += 2;
            } else {
                len += type_name.len + 2;
            }
            inline for (fields) |field| {
                const FieldFormat = AnyFormat(field.field_type);
                const field_value: field.field_type = @field(format.value, field.name);
                if (omit_default_fields and field.default_value != null and
                    comptime meta.isTriviallyComparable(field.field_type))
                {
                    const default_value: field.field_type =
                        mem.pointerOpaque(field.field_type, field.default_value.?).*;
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

pub fn UnionFormat(comptime Union: type) type {
    return struct {
        value: Union,
        const Format = @This();
        const fields: []const builtin.UnionField = @typeInfo(Union).Union.fields;
        const type_name: []const u8 = fmt.typeName(Union);
        const show_enum_field: bool = fields.len == 2 and (@typeInfo(fields[0].field_type) == .Enum and
            fields[1].field_type == @typeInfo(fields[0].field_type).Enum.tag_type);
        const max_len: u64 = blk: {
            if (show_enum_field) {
                // e.g. bit_field(u32){ .PHDR | .NOTE | .DYNAMIC }
                // The combined length of every field name + 3; every name has
                // a space and a dot to its left, and a space to its right.
                var len: u64 = 0;
                const enum_info: builtin.Type = @typeInfo(fields[0].field_type);
                inline for (enum_info.Enum.fields) |field| {
                    len += field.len;
                }
                len += fields.len * 3;
                // The length of 'bit_field('
                len += 10;
                // The length of the integer tag_type name
                len += @typeName(enum_info.Enum.tag_type);
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
                    max_field_len = @max(max_field_len, AnyFormat(field.field_type).max_len);
                }
                break :blk (type_name.len + 2) + 1 + meta.maxDeclLength(Union) + 3 + max_field_len + 2;
            }
        };
        pub fn formatWriteEnumField(format: Format, array: anytype) void {
            const enum_info: builtin.Type = @typeInfo(fields[0].field_type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            array.writeMany("bit_field(" ++ @typeName(enum_info.Enum.tag_type) ++ "){ ");
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
                    array.writeFormat(IntFormat(enum_info.Enum.tag_type){ .value = x });
                    array.writeMany(" }");
                } else {
                    array.undefine(1);
                    array.overwriteManyBack(" }");
                }
            } else {
                if (x != 0) {
                    array.writeFormat(IntFormat(enum_info.Enum.tag_type){ .value = x });
                    array.writeMany(" }");
                } else {
                    array.overwriteManyBack("}");
                }
            }
        }
        pub fn formatLengthEnumField(format: Format) u64 {
            const enum_info: builtin.Type = @typeInfo(fields[0].field_type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            var len: u64 = 10 + @typeName(enum_info.Enum.tag_type).len + 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -= 1;
                const field: builtin.EnumField = enum_info.Enum.fields[i];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        len += 1 + field.name.len + 3;
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
                array.writeMany((type_name ++ "{}"));
            } else {
                array.writeMany((type_name ++ "{ "));
                if (@typeInfo(Union).Union.tag_type) |tag_type| {
                    inline for (fields) |field| {
                        if (format.value == @field(tag_type, field.name)) {
                            const FieldFormat = AnyFormat(field.field_type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            array.writeMany(("." ++ field.name ++ " = "));
                            field_format.formatWrite(array);
                            array.writeMany(", ");
                        }
                    }
                    array.overwriteManyBack(" }");
                } else {
                    inline for (fields) |field| {
                        const FieldFormat = AnyFormat(field.field_type);
                        const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                        array.writeMany(("." ++ field.name ++ " = "));
                        field_format.formatWrite(array);
                        array.writeMany(" | ");
                    }
                    array.undefine(1);
                    array.overwriteManyBack(" }");
                }
            }
        }
        pub fn formatLength(format: anytype) u64 {
            if (show_enum_field) {
                return format.formatLengthEnumField();
            }
            var len: u64 = type_name.len + 2;
            if (@typeInfo(Union).Union.tag_type) |tag_type| {
                inline for (fields) |field| {
                    if (format.value == @field(tag_type, field.name)) {
                        const FieldFormat = AnyFormat(field.field_type);
                        const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                        len += 1 + field.name.len + 3 + field_format.formatLength() + 2;
                    }
                }
            } else {
                inline for (fields) |field| {
                    const FieldFormat = AnyFormat(field.field_type);
                    const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                    len += 1 + field.name.len + 3 + field_format.formatLength() + 3;
                }
                len -= 1;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}

//  Enum
//
pub fn EnumFormat(comptime T: type) type {
    return struct {
        value: T,
        const Format = @This();
        const max_len: u64 = 1 + meta.maxDeclLength(T);
        pub fn formatWrite(format: Format, array: anytype) void {
            const tag_name = @tagName(format.value);
            array.writeOne('.');
            array.writeMany(tag_name);
        }
        pub fn formatLength(format: Format) u64 {
            return 1 + @tagName(format.value).len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}

//  EnumLiteral
//
//
//  ComptimeInt
//
pub const ComptimeIntFormat = struct {
    value: comptime_int,
    const Format = @This();
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        const Int: type = meta.LeastRealBitSize(format.value);
        const real_format: IntFormat(Int) = .{ .value = format.value };
        return real_format.formatWrite(array);
    }
    pub fn formatLength(comptime format: Format) u64 {
        const Int: type = meta.LeastRealBitSize(format.value);
        const real_format: IntFormat(Int) = .{ .value = format.value };
        return real_format.formatLength();
    }
    pub usingnamespace GenericRenderFormat(Format);
};

//
//  Int
//
pub fn IntFormat(comptime Int: type) type {
    return struct {
        value: Int,
        const Format = @This();
        const Abs: type = @Type(.{ .Int = .{ .bits = type_info.Int.bits, .signedness = .unsigned } });
        const type_info: builtin.Type = @typeInfo(Int);
        const radix: Abs = 10;
        const max_abs_value: Abs = ~@as(Abs, 0);
        const max_digits_count: u16 = builtin.fmt.length(Abs, max_abs_value, radix);
        const prefix: [2]u8 = lit.int_prefixes[radix].*;
        const max_len: u64 = blk: {
            var len: u64 = max_digits_count;
            if (radix != 10) {
                len += prefix.len;
            }
            if (type_info.Int.signedness == .signed) {
                len += 1;
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
                @intToPtr(*[prefix.len]u8, next).* = prefix;
                next += prefix.len;
            }
            var value: Abs = format.absolute();
            if (format.value == 0) {
                @intToPtr(*u8, next).* = '0';
            }
            const count: u64 = format.digits();
            next += count;
            var len: u64 = 0;
            while (len != count) : (value /= radix) {
                len +%= 1;
                @intToPtr(*u8, next - len).* =
                    builtin.fmt.toSymbol(Abs, value, radix);
            }
            array.impl.define(next - start);
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (radix != 10) {
                len += prefix.len;
            }
            if (format.value < 0) {
                len += 1;
            }
            return len + format.digits();
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}

//
//  Pointer
//
//
//      One
//
pub fn PointerOneFormat(comptime Pointer: type) type {
    return struct {
        value: Pointer,
        const Format = @This();
        const SubFormat = meta.Return(fmt.ux64);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const type_name: []const u8 = fmt.typeName(Pointer);
        const max_len: u64 = (4 + type_name.len + 3) + AnyFormat(child).max_len + 1;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (child == anyopaque) {
                array.writeMany("@intToPtr(" ++ type_name ++ ", ");
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                array.writeFormat(sub_format);
            } else {
                array.writeMany(("@as(" ++ type_name ++ ", &"));
                const sub_format: AnyFormat(child) = .{ .value = format.value.* };
                sub_format.formatWrite(array);
            }
            array.writeMany(")");
        }
        pub fn formatLength(format: Format) u64 {
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = @ptrToInt(format.value) };
                return 10 + type_name.len + 2 + sub_format.formatLength() + 1;
            } else {
                const sub_format: AnyFormat(child) = .{ .value = format.value.* };
                return 4 + type_name.len + 3 + sub_format.formatLength() + 1;
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}

//
//     Slice
//
pub fn PointerSliceFormat(comptime Pointer: type) type {
    return struct {
        value: Pointer,
        const Format = @This();
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: u64 = 65536;

        fn formatLengthAny(format: Format) u64 {
            const type_name = comptime fmt.typeName(Pointer);
            var len: u64 = type_name.len + 2;
            if (format.value.len != 0) {
                for (format.value) |value| {
                    const sub_format: AnyFormat(child) = .{ .value = value };
                    len += sub_format.formatLength() + 2;
                }
            }
            return len;
        }
        fn formatWriteAny(format: Format, array: anytype) void {
            const type_name = comptime fmt.typeName(Pointer);
            if (format.value.len == 0) {
                array.writeMany(type_name ++ "{}");
            } else {
                array.writeMany(type_name ++ "{ ");
                for (format.value) |element| {
                    const sub_format: AnyFormat(child) = .{ .value = element };
                    sub_format.formatWrite(array);
                    array.writeMany(", ");
                }
                array.overwriteManyBack(" }");
            }
        }
        fn formatLengthStringLiteral(format: Format) u64 {
            var len: u64 = 0;
            len += 1;
            for (format.value) |c| {
                len += switch (c) {
                    '"' => "\\\"".len,
                    '\'' => "\\\'".len,
                    '\\' => "\\\\".len,
                    '\t' => "\\t".len,
                    '\n' => "\\n".len,
                    else => 1,
                };
            }
            len += 1;
            return len;
        }
        fn formatWriteStringLiteral(format: Format, array: anytype) void {
            array.writeOne('"');
            for (format.value) |c| {
                switch (c) {
                    '"' => array.writeMany("\\\""),
                    '\'' => array.writeMany("\\\'"),
                    '\\' => array.writeMany("\\\\"),
                    '\t' => array.writeMany("\\t"),
                    '\n' => array.writeMany("\\n"),
                    else => array.writeOne(c),
                }
            }
            array.writeOne('"');
        }
        fn formatWriteMultiLineStringLiteral(format: Format, array: anytype) void {
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
        fn formatLengthMultiLineStringLiteral(format: Format) u64 {
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
        pub fn formatWrite(format: Format, array: anytype) void {
            if (comptime child == u8) {
                if (render_multi_line_string_literal) {
                    return formatWriteMultiLineStringLiteral(format, array);
                } else if (render_string_literal) {
                    return formatWriteStringLiteral(format, array);
                }
            }
            return formatWriteAny(format, array);
        }
        pub fn formatLength(format: Format) u64 {
            if (comptime child == u8) {
                if (render_multi_line_string_literal) {
                    return formatLengthMultiLineStringLiteral(format);
                } else if (render_string_literal) {
                    return formatLengthStringLiteral(format);
                }
            } else {
                return formatLengthAny(format);
            }
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
//
//      Many
//
//
//  Optional
//
pub fn OptionalFormat(comptime Optional: type) type {
    return struct {
        value: Optional,
        const Format = @This();
        const child: type = @typeInfo(Optional).Optional.child;
        const type_name: []const u8 = fmt.typeName(Optional);
        const max_len: u64 = (4 + type_name.len + 2) + @max(1 + AnyFormat(child).max_len, 5);
        const render_readable: bool = true;
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (!render_readable) {
                array.writeMany("@as(" ++ type_name ++ ", ");
            }
            if (format.value) |optional| {
                const sub_format: AnyFormat(child) = .{ .value = optional };
                sub_format.formatWrite(array);
            } else {
                array.writeMany("null");
            }
            if (!render_readable) {
                array.writeMany(")");
            }
        }
        pub fn formatLength(format: anytype) u64 {
            var len: u64 = 0;
            if (!render_readable) {
                len += 4 + type_name.len + 2;
            }
            if (format.value) |optional| {
                const sub_format: AnyFormat(child) = .{ .value = optional };
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

//
//  Null
//
//
//  Void
//
//
//  Vector
pub fn VectorFormat(comptime Vector: type) type {
    return struct {
        value: Vector,
        const Format = @This();
        const ElementFormat = AnyFormat(child);
        const vector_info: builtin.Type = @typeInfo(Vector);
        const child: type = vector_info.Vector.child;
        const type_name: []const u8 = fmt.typeName(Vector);
        const max_len: u64 = (type_name.len + 2) +
            vector_info.Array.len * (ElementFormat.max_len + 2);
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeMany(type_name ++ "{ ");
            var i: u64 = 0;
            while (i != vector_info.Vector.len) : (i += 1) {
                const element: child = format.value[i];
                const element_format: ElementFormat = .{ .value = element };
                element_format.formatWrite(array);
                array.writeMany(", ");
            }
            array.overwriteManyBack(" }");
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = type_name.len + 2;
            var i: u64 = 0;
            while (i != vector_info.Vector.len) : (i += 1) {
                const element: child = format.value[i];
                const element_format: ElementFormat = .{ .value = element };
                len += element_format.formatLength() + 2;
            }
            return len;
        }
        pub usingnamespace GenericRenderFormat(Format);
    };
}
//
//  ErrorUnion
//
pub fn ErrorUnionFormat(comptime ErrorUnion: type) type {
    return struct {
        value: ErrorUnion,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(ErrorUnion);
        const PayloadFormat = AnyFormat(type_info.ErrorUnion.payload);
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
