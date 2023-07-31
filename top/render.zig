const tab = @import("./tab.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const RenderSpec = struct {
    radix: u7 = 10,
    string_literal: ?bool = true,
    multi_line_string_literal: ?bool = false,
    omit_default_fields: bool = true,
    omit_container_decls: bool = true,
    omit_trailing_comma: ?bool = null,
    omit_type_names: bool = false,
    enum_to_int: bool = false,
    infer_type_names: bool = false,
    infer_type_names_recursively: bool = false,
    char_literal_formatter: type = fmt.Type.Esc,
    inline_field_types: bool = true,
    enable_comptime_iterator: bool = false,
    address_view: bool = false,
    names: struct {
        len_field_suffix: []const u8 = "_len",
        max_len_field_suffix: []const u8 = "_max_len",
        tag_field_suffix: []const u8 = "_tag",
    } = .{},
    views: packed struct(u6) {
        /// Represents a normal slice where all values are to be shown, maybe used in extern structs.
        /// field_name: [*]T,
        /// field_name_len: usize,
        extern_slice: bool = false,
        /// Represents a slice where only `field_name_len` values are to be shown.
        /// field_name: []T
        /// field_name_len: usize,
        zig_resizeable: bool = false,
        /// Represents a statically sized buffer  where only `field_name_len` values are to be shown.
        /// field_name: [n]T
        /// field_name_len: usize,
        static_resizeable: bool = false,
        /// Represents a buffer with length and capacity, maybe used in extern structs.
        /// field_name: [*]T,
        /// field_name_max_len: usize,
        /// field_name_len: usize,
        extern_resizeable: bool = false,
        /// Represents a union with length and capacity, maybe used in extern structs.
        /// field_name: U,
        /// field_name_tag: E,
        extern_tagged_union: bool = false,
        /// Represents `anytype`
        generic_type_cast: bool = true,
    } = .{},
    decls: packed struct(u2) {
        /// Prefer existing formatter declarations if present (unions and structs)
        forward_formatter: bool = false,
        /// Prefer `ContainerFormat` over `StructFormat` for apparent library
        /// container types.
        forward_container: bool = false,
    } = .{},
};
pub inline fn any(value: anytype) AnyFormat(.{}, @TypeOf(value)) {
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
        return comptime fmt.typeName(T);
    }
}
inline fn writeFormat(array: anytype, format: anytype) void {
    if (builtin.runtime_assertions) {
        array.writeFormat(format);
    } else {
        format.formatWrite(array);
    }
}
pub fn AnyFormat(comptime spec: RenderSpec, comptime Type: type) type {
    @setEvalBranchQuota(~@as(u32, 0));
    if (Type == meta.Generic) {
        return GenericFormat(spec);
    }
    switch (@typeInfo(Type)) {
        .Array => return ArrayFormat(spec, Type),
        .Bool => return BoolFormat,
        .Type => return TypeFormat(spec),
        .Struct => return StructFormat(spec, Type),
        .Union => return UnionFormat(spec, Type),
        .Enum => return EnumFormat(spec, Type),
        .EnumLiteral => return EnumLiteralFormat(spec, Type),
        .ComptimeInt => return ComptimeIntFormat,
        .Int => return IntFormat(spec, Type),
        .Pointer => |pointer_info| switch (pointer_info.size) {
            .One => return PointerOneFormat(spec, Type),
            .Many => return PointerManyFormat(spec, Type),
            .Slice => return PointerSliceFormat(spec, Type),
            else => @compileError(@typeName(Type)),
        },
        .Optional => return OptionalFormat(spec, Type),
        .Null => return NullFormat,
        .Void => return VoidFormat,
        .NoReturn => return NoReturnFormat,
        .Vector => return VectorFormat(spec, Type),
        .ErrorUnion => return ErrorUnionFormat(spec, Type),
        .ErrorSet => return ErrorSetFormat(Type),
        else => @compileError(@typeName(Type)),
    }
}
pub fn GenericFormat(comptime spec: RenderSpec) type {
    const T = struct {
        value: meta.Generic,
        const Format = @This();
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const type_format: AnyFormat(spec, format.value.type) = .{ .value = meta.typeCast(format.value) };
            writeFormat(array, type_format);
        }
        pub fn formatLength(comptime format: Format) usize {
            const type_format: AnyFormat(spec, format.value.type) = .{ .value = meta.typeCast(format.value) };
            return type_format.formatLength();
        }
    };
    return T;
}
pub fn ArrayFormat(comptime spec: RenderSpec, comptime Array: type) type {
    const T = struct {
        value: Array,
        const Format = @This();
        const ChildFormat: type = AnyFormat(child_spec, child);
        const array_info: builtin.Type = @typeInfo(Array);
        const child: type = array_info.Array.child;
        const type_name: []const u8 = typeName(Array, spec);
        const max_len: usize = (type_name.len +% 2) +% array_info.Array.len *% (ChildFormat.max_len +% 2);
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
                if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
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
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = type_name.len;
            @memcpy(buf, type_name);
            if (format.value.len == 0) {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const element_format: ChildFormat = .{ .value = element };
                        len +%= element_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                } else {
                    for (format.value) |element| {
                        const element_format: ChildFormat = .{ .value = element };
                        len +%= element_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                }
                if (omit_trailing_comma) {
                    @as(*[2]u8, @ptrCast(buf + (len - 2))).* = " }".*;
                } else {
                    buf[len] = '}';
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = type_name.len +% 2;
            if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                inline for (format.value) |value| {
                    const element_format: ChildFormat = .{ .value = value };
                    len +%= element_format.formatLength() +% 2;
                }
            } else {
                for (format.value) |value| {
                    const element_format: ChildFormat = .{ .value = value };
                    len +%= element_format.formatLength() +% 2;
                }
            }
            if (!omit_trailing_comma and format.value.len != 0) {
                len +%= 1;
            }
            return len;
        }
    };
    return T;
}
pub const BoolFormat = struct {
    value: bool,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.value) {
            array.writeCount(4, "true".*);
        } else {
            array.writeCount(5, "false".*);
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (format.value) {
            buf[0..4].* = "true".*;
            return 4;
        } else {
            buf[0..5].* = "false".*;
            return 5;
        }
    }
    pub inline fn formatLength(format: Format) usize {
        return if (format.value) 4 else 5;
    }
};
pub fn TypeFormat(comptime spec: RenderSpec) type {
    const T = struct {
        const Format = @This();
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
        fn writeDecl(comptime format: anytype, array: anytype, comptime decl: builtin.Type.Declaration) void {
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
            writeFormat(array, decl_name_format);
            array.writeMany(": " ++ comptime typeName(decl_type, field_type_spec) ++ " = ");
            writeFormat(array, decl_format);
            array.writeCount(2, "; ".*);
        }
        fn lengthDecl(comptime format: anytype, comptime decl: builtin.Type.Declaration) u64 {
            if (!decl.is_pub) {
                return 0;
            }
            const decl_type: type = @TypeOf(@field(format.value, decl.name));
            if (@typeInfo(decl_type) == .Fn) {
                return 0;
            }
            var len: usize = 0;
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
                writeFormat(array, field_name_format);
                array.writeMany(": ");
                writeFormat(array, type_format);
            } else {
                writeFormat(array, field_name_format);
                array.writeMany(": " ++ @typeName(field_type));
            }
            if (field_default_value) |default_value| {
                const field_format: AnyFormat(default_value_spec, field_type) = .{ .value = default_value };
                array.writeMany(" = ");
                writeFormat(array, field_format);
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
                    writeFormat(array, field_name_format);
                    array.writeMany(": ");
                    const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                    writeFormat(array, type_format);
                } else {
                    writeFormat(array, field_name_format);
                    array.writeMany(": " ++ @typeName(field_type));
                }
                array.writeCount(2, ", ".*);
            }
        }
        fn writeEnumField(array: anytype, field_name: []const u8) void {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            writeFormat(array, field_name_format);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const type_info: builtin.Type = @typeInfo(format.value);
            switch (type_info) {
                .Struct => |struct_info| {
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (struct_info.fields) |field| {
                            writeStructField(array, field.name, field.type, meta.defaultValue(field));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            writeTrailingComma(
                                array,
                                omit_trailing_comma,
                                struct_info.fields.len +% struct_info.decls.len,
                            );
                        } else {
                            writeTrailingComma(array, omit_trailing_comma, struct_info.fields.len);
                        }
                    }
                },
                .Union => |union_info| {
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (union_info.fields) |field| {
                            writeUnionField(array, field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            writeTrailingComma(
                                array,
                                omit_trailing_comma,
                                union_info.fields.len +% union_info.decls.len,
                            );
                        } else {
                            writeTrailingComma(array, omit_trailing_comma, union_info.fields.len);
                        }
                    }
                },
                .Enum => |enum_info| {
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " {}");
                    } else {
                        array.writeMany(comptime fmt.typeDeclSpecifier(type_info) ++ " { ");
                        inline for (enum_info.fields) |field| {
                            writeEnumField(array, field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                writeDecl(format, array, decl);
                            }
                            writeTrailingComma(
                                array,
                                omit_trailing_comma,
                                enum_info.fields.len +% enum_info.decls.len,
                            );
                        } else {
                            writeTrailingComma(array, omit_trailing_comma, enum_info.fields.len);
                        }
                    }
                },
                else => {
                    array.writeMany(typeName(format.value, spec));
                },
            }
        }
        fn writeDeclBuf(comptime format: Format, buf: [*]u8, comptime decl: builtin.Type.Declaration) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (!decl.is_pub) {
                return 0;
            }
            const decl_type: type = @TypeOf(@field(format.value, decl.name));
            if (@typeInfo(decl_type) == .Fn) {
                return 0;
            }
            const decl_value: decl_type = @field(format.value, decl.name);
            const decl_name_format: fmt.IdentifierFormat = .{ .value = decl.name };
            const decl_format: AnyFormat(default_value_spec, decl_type) = .{ .value = decl_value };
            const type_name_s: []const u8 = comptime typeName(decl_type, field_type_spec);
            var len: usize = 0;
            @as(*[16]u8, @ptrCast(buf + len)).* = "pub const ";
            len +%= 16;
            len +%= decl_name_format.formatWriteBuf(buf + len);
            @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
            len +%= 2;
            @memcpy(buf + len, type_name_s);
            len +%= type_name_s.len;
            @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
            len +%= 3;
            decl_format.formatWriteBuf(buf + len);
            @as(*[2]u8, @ptrCast(buf + len)).* = "; ".*;
            len +%= 2;
            return len;
        }
        fn writeStructFieldBuf(buf: [*]u8, field_name: []const u8, comptime field_type: type, field_default_value: ?field_type) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (spec.inline_field_types) {
                const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                len +%= field_name_format.formatWriteBuf(buf);
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                len +%= type_format.formatWriteBuf(buf + len);
            } else {
                len +%= field_name_format.formatWriteBuf(buf);
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                @as(meta.TypeName(field_type), @ptrCast(buf + len)).* = @typeName(field_type).*;
                len +%= @typeName(field_type).len;
            }
            if (field_default_value) |default_value| {
                const field_format: AnyFormat(default_value_spec, field_type) = .{ .value = default_value };
                @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
                len +%= 3;
                len +%= field_format.formatWriteBuf(buf + len);
            }
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        fn writeUnionFieldBuf(buf: [*]u8, field_name: []const u8, comptime field_type: type) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (field_type == void) {
                len +%= field_name_format.formatWriteBuf(buf + len);
                @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                len +%= 2;
            } else {
                if (spec.inline_field_types) {
                    const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                    len +%= field_name_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                    len +%= 2;
                    len +%= type_format.formatWriteBuf(buf + len);
                } else {
                    len +%= field_name_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                    len +%= 2;
                    @as(meta.TypeName(field_type), @ptrCast(buf + len)).* = @typeName(field_type).*;
                    len +%= @typeName(field_type).len;
                }
                @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                len +%= 2;
            }
            return len;
        }
        fn writeEnumFieldBuf(buf: [*]u8, field_name: []const u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            len +%= field_name_format.formatWriteBuf(buf);
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        pub fn formatWriteBuf(comptime format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const type_info: builtin.Type = @typeInfo(format.value);
            var len: usize = 0;
            switch (type_info) {
                .Struct => |struct_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (struct_info.fields) |field| {
                            len +%= writeStructFieldBuf(buf + len, field.name, field.type, meta.defaultValue(field));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                len +%= writeDeclBuf(format, buf + len, decl);
                            }
                            len +%= writeTrailingComma(
                                buf + (len - 1),
                                omit_trailing_comma,
                                struct_info.fields.len +% struct_info.decls.len,
                            );
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len - 1), omit_trailing_comma, struct_info.fields.len);
                        }
                    }
                },
                .Union => |union_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (union_info.fields) |field| {
                            len +%= writeUnionFieldBuf(buf + len, field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                len +%= writeDeclBuf(format, buf + len, decl);
                            }
                            len +%= writeTrailingCommaBuf(
                                buf + (len - 1),
                                omit_trailing_comma,
                                union_info.fields.len +% union_info.decls.len,
                            );
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len - 1), omit_trailing_comma, union_info.fields.len);
                        }
                    }
                },
                .Enum => |enum_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (enum_info.fields) |field| {
                            len +%= writeEnumFieldBuf(buf + len, field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                len +%= writeDeclBuf(format, buf + len, decl);
                            }
                            len +%= writeTrailingCommaBuf(
                                buf + (len - 1),
                                omit_trailing_comma,
                                enum_info.fields.len +% enum_info.decls.len,
                            );
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len - 1), omit_trailing_comma, enum_info.fields.len);
                        }
                    }
                },
                else => {
                    const type_name_s: []const u8 = comptime typeName(format.value, spec);
                    @memcpy(buf + len, type_name_s);
                    len +%= type_name_s.len;
                },
            }
            return len;
        }
        fn lengthStructField(field_name: []const u8, comptime field_type: type, field_default_value: ?field_type) usize {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (spec.inline_field_types) {
                const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                len +%= field_name_format.formatLength();
                len +%= 2;
                len +%= type_format.formatLength();
            } else {
                len +%= field_name_format.formatLength();
                len +%= 2;
                len +%= @typeName(field_type).len;
            }
            if (field_default_value) |default_value| {
                const field_format: AnyFormat(default_value_spec, field_type) = .{ .value = default_value };
                len +%= 3;
                len +%= field_format.formatLength();
            }
            len +%= 2;
            return len;
        }
        fn lengthUnionField(field_name: []const u8, comptime field_type: type) usize {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (field_type == void) {
                len +%= field_name_format.formatLength();
                len +%= 2;
            } else {
                if (spec.inline_field_types) {
                    const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                    len +%= field_name_format.formatLength();
                    len +%= 2;
                    len +%= type_format.formatLength();
                } else {
                    len +%= field_name_format.formatLength();
                    len +%= 2;
                    len +%= @typeName(field_type).len;
                }
                len +%= 2;
            }
            return len;
        }
        fn lengthEnumField(field_name: []const u8) usize {
            const field_name_format: fmt.IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            len +%= field_name_format.formatLength();
            len +%= 2;
            return len;
        }
        pub fn formatLength(comptime format: anytype) usize {
            var len: usize = 0;
            const type_info: builtin.Type = @typeInfo(format.value);
            switch (type_info) {
                .Struct => |struct_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                    } else {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                        inline for (struct_info.fields) |field| {
                            len +%= lengthStructField(field.name, field.type, meta.defaultValue(field));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                        }
                        len +%= @intFromBool(struct_info.fields.len != 0 and !omit_trailing_comma);
                    }
                },
                .Union => |union_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                    } else {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                        inline for (union_info.fields) |field| {
                            len +%= lengthUnionField(field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                        }
                        len +%= @intFromBool(union_info.fields.len != 0 and !omit_trailing_comma);
                    }
                },
                .Enum => |enum_info| {
                    const decl_spec_s = comptime meta.sliceToArrayPointer(fmt.typeDeclSpecifier(type_info)).*;
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                    } else {
                        len +%= decl_spec_s.len;
                        len +%= 3;
                        inline for (enum_info.fields) |field| {
                            len +%= lengthEnumField(field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                len +%= lengthDecl(format, decl);
                            }
                        }
                        len +%= @intFromBool(enum_info.fields.len != 0 and !omit_trailing_comma);
                    }
                },
                else => {
                    const type_name_s: []const u8 = comptime typeName(format.value, spec);
                    len +%= type_name_s.len;
                },
            }
            return len;
        }
    };
    return T;
}
inline fn writeTrailingComma(array: anytype, comptime omit_trailing_comma: bool, fields_len: usize) void {
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
fn writeTrailingCommaBuf(buf: [*]u8, omit_trailing_comma: bool, fields_len: usize) usize {
    // The length starting at -1 is a workaround for compiler TODO implement sema comptime pointer subtract.
    var len: usize = 0;
    if (fields_len == 0) {
        buf[0] = '}';
    } else {
        if (omit_trailing_comma) {
            (buf + len)[1..3].* = " }".*;
        } else {
            buf[1] = '}';
            len +%= 1;
        }
    }
    return len;
}
pub fn StructFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    if (spec.decls.forward_formatter) {
        if (@hasDecl(Struct, "formatWrite") and @hasDecl(Struct, "formatLength")) {
            return FormatFormat(Struct);
        }
    }
    if (spec.decls.forward_container) {
        if (@hasDecl(Struct, "readAll") and @hasDecl(Struct, "len")) {
            return ContainerFormat(spec, Struct);
        }
    }
    const T = struct {
        value: Struct,
        const Format = @This();
        const undef: Struct = @as(Struct, undefined);
        const fields: []const builtin.Type.StructField = @typeInfo(Struct).Struct.fields;
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse false;
        const max_len: usize = blk: {
            var len: usize = 0;
            len +%= @typeName(Struct).len +% 2;
            if (fields.len == 0) {
                len +%= 1;
            } else {
                inline for (fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type)) field_spec_if_type else field_spec_if_not_type;
                    len +%= 1 +% field_name_format.formatLength() +% 3;
                    len +%= AnyFormat(field.type, field_spec).max_len;
                    len +%= 2;
                }
            }
            break :blk len;
        };
        const field_spec_if_not_type: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = true;
            break :blk tmp;
        };
        const field_spec_if_type: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = false;
            break :blk tmp;
        };
        fn writeFieldInitializer(array: anytype, field_name_format: fmt.IdentifierFormat, field_format: anytype) void {
            array.writeOne('.');
            writeFormat(array, field_name_format);
            array.writeCount(3, " = ".*);
            writeFormat(array, field_format);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.infer_type_names) {
                array.writeOne('.');
            } else {
                array.writeMany(@typeName(Struct));
            }
            if (fields.len == 0) {
                array.writeMany("{}");
            } else {
                comptime var field_idx: usize = 0;
                var fields_len: usize = 0;
                array.writeMany("{ ");
                inline while (field_idx != fields.len) : (field_idx +%= 1) {
                    const field: builtin.Type.StructField = fields[field_idx];
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    const field_value: field.type = @field(format.value, field.name);
                    const field_type_info: builtin.Type = @typeInfo(field.type);
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    if (field_type_info == .Union) {
                        if (field_type_info.Union.layout != .Auto) {
                            const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                            if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                                const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(format.value, tag_field_name));
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Pointer) {
                        const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                        if (field_type_info.Pointer.size == .Many) {
                            if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                            if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (field_type_info.Pointer.size == .Slice) {
                            if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Array) {
                        const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                        if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            writeFieldInitializer(array, field_name_format, render(field_spec, view));
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                    if (spec.omit_default_fields and field.default_value != null) {
                        if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            writeFieldInitializer(array, field_name_format, field_format);
                            fields_len +%= 1;
                        }
                    } else {
                        writeFieldInitializer(array, field_name_format, field_format);
                        fields_len +%= 1;
                    }
                }
                writeTrailingComma(array, omit_trailing_comma, fields_len);
            }
        }
        fn writeFieldInitializerBuf(buf: [*]u8, field_name_format: fmt.IdentifierFormat, field_format: anytype) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            buf[0] = '.';
            len +%= 1;
            len +%= field_name_format.formatWriteBuf(buf + len);
            @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
            len +%= 3;
            len +%= field_format.formatWriteBuf(buf + len);
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (spec.infer_type_names) {
                buf[len] = '.';
                len +%= 1;
            } else {
                @as(meta.TypeName(Struct), @ptrCast(buf)).* = @typeName(Struct).*;
                len +%= @typeName(Struct).len;
            }
            if (fields.len == 0) {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                comptime var field_idx: usize = 0;
                var fields_len: usize = 0;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                inline while (field_idx != fields.len) : (field_idx +%= 1) {
                    const field: builtin.Type.StructField = fields[field_idx];
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    const field_value: field.type = @field(format.value, field.name);
                    const field_type_info: builtin.Type = @typeInfo(field.type);
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    if (field_type_info == .Union) {
                        if (field_type_info.Union.layout != .Auto) {
                            const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                            if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                                const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(format.value, tag_field_name));
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Pointer) {
                        const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                        if (field_type_info.Pointer.size == .Many) {
                            if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                            if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (field_type_info.Pointer.size == .Slice) {
                            if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Array) {
                        const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                        if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                    if (spec.omit_default_fields and field.default_value != null) {
                        if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= writeFieldInitializerBuf(buf + len, field_name_format, field_format);
                            fields_len +%= 1;
                        }
                    } else {
                        len +%= writeFieldInitializerBuf(buf + len, field_name_format, field_format);
                        fields_len +%= 1;
                    }
                }
                len +%= writeTrailingCommaBuf(buf + (len - 1), omit_trailing_comma, fields_len);
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (spec.infer_type_names) {
                len +%= 3;
            } else {
                len +%= @typeName(Struct).len +% 2;
            }
            comptime var field_idx: usize = 0;
            var fields_len: usize = 0;
            inline while (field_idx != fields.len) : (field_idx +%= 1) {
                const field: builtin.Type.StructField = fields[field_idx];
                const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                const field_value: field.type = @field(format.value, field.name);
                const field_type_info: builtin.Type = @typeInfo(field.type);
                if (field_type_info == .Union) {
                    if (field_type_info.Union.layout != .Auto) {
                        const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                        if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                            const view = meta.tagUnion(field.type, meta.Field(tag_field_name), field_value, @field(format.value, tag_field_name));
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                } else if (field_type_info == .Pointer) {
                    const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                    if (field_type_info.Pointer.size == .Many) {
                        if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                        if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    if (field_type_info.Pointer.size == .Slice) {
                        if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                } else if (field_type_info == .Array) {
                    const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                    if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                        const view = field_value[0..@field(format.value, len_field_name)];
                        len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                        fields_len +%= 1;
                        continue;
                    }
                }
                const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                if (spec.omit_default_fields and field.default_value != null) {
                    if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                        len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                        fields_len +%= 1;
                    }
                } else {
                    len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                    fields_len +%= 1;
                }
            }
            len +%= @intFromBool(!omit_trailing_comma and fields_len != 0);
            return len;
        }
    };
    return T;
}
pub fn UnionFormat(comptime spec: RenderSpec, comptime Union: type) type {
    if (spec.decls.forward_formatter) {
        if (@hasDecl(Union, "formatWrite") and @hasDecl(Union, "formatLength")) {
            return FormatFormat(Union);
        }
    }
    const T = struct {
        value: Union,
        const Format = @This();
        const fields: []const builtin.Type.UnionField = @typeInfo(Union).Union.fields;
        const type_name: []const u8 = typeName(Union, spec);
        // This is the actual tag type
        const tag_type: ?type = @typeInfo(Union).Union.tag_type;
        // This is the bit-field tag type name
        const tag_type_name: []const u8 = typeName(@typeInfo(fields[0].type).Enum.tag_type, spec);
        const show_enum_field: bool = fields.len == 2 and (@typeInfo(fields[0].type) == .Enum and
            fields[1].type == @typeInfo(fields[0].type).Enum.tag_type);
        const Int: type = meta.LeastRealBitSize(Union);
        const max_len: usize = blk: {
            if (show_enum_field) {
                // e.g. bit_field(u32){ .PHDR | .NOTE | .DYNAMIC }
                // The combined length of every field name + 3; every name has
                // a space and a dot to its left, and a space to its right.
                var len: usize = 0;
                const enum_info: builtin.Type = @typeInfo(fields[0].type);
                inline for (enum_info.Enum.fields) |field| {
                    const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                    len +%= field_name_format.formatLength();
                }
                len +%= fields.len *% 3;
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
                len +%= fields.len -% 1;
                // The maximum length of the potential remainder value + 4; the
                // remainder is separated by "~|", to show the bits of the value
                // which did not match, and has spaces on each side.
                len +%= 2 +% 1 +% IntFormat(enum_info.Enum.tag_type).max_len +% 1;
                break :blk len;
            } else {
                var max_field_len: usize = 0;
                inline for (fields) |field| {
                    max_field_len = @max(max_field_len, AnyFormat(spec, field.type).max_len);
                }
                break :blk (type_name.len +% 2) +% 1 +% meta.maxDeclLength(Union) +% 3 +% max_field_len +% 2;
            }
        };
        pub fn formatWriteEnumField(format: Format, array: anytype) void {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            array.writeMany("bit_field(" ++ @typeName(enum_info.Enum.tag_type) ++ "){ ");
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[i];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        array.writeOne('.');
                        const tag_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        writeFormat(array, tag_name_format);
                        array.writeMany(" | ");
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    writeFormat(array, int_format);
                    array.writeCount(2, " }".*);
                } else {
                    array.undefine(1);
                    array.overwriteCountBack(2, " }".*);
                }
            } else {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    writeFormat(array, int_format);
                    array.writeCount(2, " }".*);
                } else {
                    array.overwriteOneBack('}');
                }
            }
        }
        pub fn formatWriteBufEnumField(format: Format, buf: [*]u8) usize {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            @as(*[10]u8, @ptrCast(buf)).* = "bit_field(".*;
            var len: usize = 10;
            @as(meta.TypeName(enum_info.Enum.tag_type), @ptrCast(buf + len)).* = @typeName(enum_info.Enum.tag_type).*;
            len +%= @typeName(enum_info.Enum.tag_type).len;
            @as(*[3]u8, @ptrCast(buf + len)).* = "){ ".*;
            len +%= 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var idx: u64 = enum_info.Enum.fields.len;
            inline while (idx != 0) {
                idx -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[idx];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        buf[len] = '.';
                        len +%= 1;
                        const tag_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        len +%= tag_name_format.formatWriteBuf(buf + len);
                        @as(*[3]u8, @ptrCast(buf + len)).* = " | ".*;
                        len +%= 3;
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    len +%= int_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = " }".*;
                    len +%= 2;
                } else {
                    @as(*[2]u8, @ptrCast(buf + (len -% 1))).* = " }".*;
                    len +%= 1;
                }
            } else {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    len +%= int_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = " }".*;
                    len +%= 2;
                } else {
                    (buf - 1)[len] = '}';
                }
            }
            return len;
        }
        pub fn formatLengthEnumField(format: Format) u64 {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            var len: usize = 10 +% @typeName(enum_info.Enum.tag_type).len +% 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var i: u64 = enum_info.Enum.fields.len;
            inline while (i != 0) {
                i -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[i];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        len +%= 1;
                        const tag_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        len +%= tag_name_format.formatLength() +% 3;
                        x &= ~y;
                    }
                }
            }
            if (x != 0) {
                const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                len +%= int_format.formatLength() +% 2;
            }
            if (x != w) {
                if (x == 0) {
                    len -%= 1;
                }
            }
            return len;
        }
        fn formatWriteUntagged(format: Format, array: anytype) void {
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                const tagged_format: TaggedFormat = .{ .value = format.value.tagged() };
                writeFormat(array, tagged_format);
            } else {
                if (@sizeOf(Union) > @sizeOf(usize)) {
                    array.writeMany(type_name ++ "{}");
                } else {
                    const int_format: fmt.Type.Ub(Int) = .{ .value = meta.leastRealBitCast(format.value) };
                    array.writeMany("@bitCast(" ++ @typeName(Union) ++ ", ");
                    writeFormat(array, int_format);
                    array.writeMany(")");
                }
            }
        }
        fn formatLengthUntagged(format: Format) u64 {
            var len: usize = 0;
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                len +%= TaggedFormat.formatLength(.{ .value = format.value.tagged() });
            } else {
                if (@sizeOf(Union) > @sizeOf(usize)) {
                    len +%= type_name.len +% 2;
                } else {
                    const int_format: fmt.Type.Ub(Int) = .{ .value = meta.leastRealBitCast(format.value) };
                    len +%= ("@bitCast(" ++ @typeName(Union) ++ ", ").len;
                    len +%= int_format.formatLength();
                    len +%= 1;
                }
            }
            return len;
        }
        fn formatWriteField(array: anytype, field_name_format: fmt.IdentifierFormat, field_format: anytype) void {
            array.writeOne('.');
            writeFormat(array, field_name_format);
            array.writeCount(3, " = ".*);
            writeFormat(array, field_format);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (show_enum_field) {
                format.formatWriteEnumField(array);
            } else if (tag_type == null) {
                format.formatWriteUntagged(array);
            } else if (fields.len == 0) {
                array.writeMany(type_name ++ "{}");
            } else {
                array.writeMany(type_name ++ "{ ");
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            array.undefine(2);
                            return writeFormat(array, field_name_format);
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            formatWriteField(array, field_name_format, field_format);
                        }
                    }
                }
                array.overwriteCountBack(2, " }".*);
            }
        }
        fn formatWriteBufField(buf: [*]u8, field_name_format: fmt.IdentifierFormat, field_format: anytype) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            buf[len] = '.';
            len +%= 1;
            len +%= field_name_format.formatWriteBuf(buf + len);
            @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
            len +%= 3;
            len +%= field_format.formatWriteBuf(buf + len);
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (show_enum_field) {
                len +%= format.formatWriteBufEnumField(buf);
            } else if (tag_type == null) {
                len +%= format.formatWriteBufUntagged(buf);
            } else if (fields.len == 0) {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            len -%= 2;
                            len +%= field_name_format.formatWriteBuf(buf + len);
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            len +%= formatWriteBufField(buf, field_name_format, field_format);
                        }
                    }
                }
                @as(*[2]u8, @ptrCast(buf + len - 2)).* = " }".*;
            }
            return len;
        }
        fn formatLengthField(field_name_format: fmt.IdentifierFormat, field_format: anytype) u64 {
            return 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (show_enum_field) {
                len +%= format.formatLengthEnumField();
            } else if (tag_type == null) {
                len +%= format.formatLengthUntagged();
            } else if (fields.len == 0) {
                len +%= type_name.len +% 2;
            } else {
                len +%= type_name.len +% 2;
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: fmt.IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            return len +% field_name_format.formatLength();
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            len +%= formatLengthField(field_name_format, field_format);
                        }
                    }
                }
            }
            return len;
        }
    };
    return T;
}
pub fn EnumFormat(comptime spec: RenderSpec, comptime Enum: type) type {
    const T = struct {
        value: Enum,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(Enum);
        const max_len: usize = 1 +% meta.maxDeclLength(Enum);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatWrite(.{ .value = @intFromEnum(format.value) }, array);
            }
            const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
            array.writeOne('.');
            writeFormat(array, tag_name_format);
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatWriteBuf(.{ .value = @intFromEnum(format.value) }, buf);
            }
            const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
            buf[0] = '.';
            return 1 +% tag_name_format.formatWriteBuf(buf + 1);
        }
        pub fn formatLength(format: Format) usize {
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatLength(.{ .value = @intFromEnum(format.value) });
            }
            const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
            return 1 +% tag_name_format.formatLength();
        }
    };
    return T;
}
pub const EnumLiteralFormat = struct {
    value: @Type(.EnumLiteral),
    const Format = @This();
    const max_len: usize = undefined;
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
        array.writeOne('.');
        writeFormat(array, tag_name_format);
    }
    pub fn formatWriteBuf(comptime format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
        buf[0] = '.';
        return 1 +% tag_name_format.formatWriteBuf(buf + 1);
    }
    pub fn formatLength(comptime format: Format) usize {
        const tag_name_format: fmt.IdentifierFormat = .{ .value = @tagName(format.value) };
        return 1 +% tag_name_format.formatLength();
    }
};
pub const ComptimeIntFormat = struct {
    value: comptime_int,
    const Format = @This();
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        array.writeMany(fmt.ci(format.value));
    }
    pub fn formatLength(comptime format: Format) usize {
        return fmt.ci(format.value).len;
    }
};
pub fn IntFormat(comptime spec: RenderSpec, comptime Int: type) type {
    const T = struct {
        value: Int,
        const Format = @This();
        const Abs: type = @Type(.{ .Int = .{ .bits = type_info.Int.bits, .signedness = .unsigned } });
        const type_info: builtin.Type = @typeInfo(Int);
        const max_abs_value: Abs = ~@as(Abs, 0);
        const radix: Abs = @min(max_abs_value, spec.radix);
        const max_digits_count: comptime_int = fmt.length(Abs, max_abs_value, radix);
        const prefix = meta.sliceToArrayPointer(tab.int_prefixes[radix]);
        const max_len: usize = blk: {
            var len: usize = max_digits_count;
            if (radix != 10) {
                len +%= prefix.len;
            }
            if (type_info.Int.signedness == .signed) {
                len +%= 1;
            }
            break :blk len;
        };
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (Abs != Int) {
                buf[0] = '-';
            }
            len +%= @intFromBool(format.value < 0);
            if (radix != 10) {
                @as(*[prefix.len]u8, @ptrCast(buf + len)).* = prefix.*;
                len +%= prefix.len;
            }
            if (radix > max_abs_value) {
                buf[len] = '0' +% @as(u8, @intFromBool(format.value != 0));
                len +%= 1;
            } else {
                var value: Abs = if (format.value < 0)
                    1 +% ~@as(Abs, @bitCast(format.value))
                else
                    @as(Abs, @bitCast(format.value));
                const count: usize = fmt.length(Abs, value, radix);
                len +%= count;
                var pos: usize = 0;
                while (pos != count) : (value /= radix) {
                    pos +%= 1;
                    buf[len -% pos] =
                        fmt.toSymbol(Abs, value, radix);
                }
            }
            return len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            array.define(@call(.always_inline, formatWriteBuf, .{
                format,
                @as([*]u8, @ptrCast(array.referOneUndefined())),
            }));
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = prefix.len;
            if (format.value < 0) {
                len +%= 1;
            }
            const absolute: Abs = if (format.value < 0)
                1 +% ~@as(Abs, @bitCast(format.value))
            else
                @as(Abs, @bitCast(format.value));
            return len +% fmt.length(Abs, absolute, radix);
        }
    };
    return T;
}
const AddressFormat = struct {
    value: usize,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        const addr_format = fmt.uxsize(format.value);
        array.writeMany("@(");
        writeFormat(addr_format, array);
        array.writeMany(")");
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        const addr_format = fmt.uxsize(format.value);
        @as(*[2]u8, @ptrCast(buf)).* = "@(".*;
        len +%= 2;
        len +%= addr_format.formatWriteBuf(buf + len);
        buf[len] = ')';
        len +%= 1;
        return len;
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 0;
        const addr_format = fmt.uxsize(format.value);
        len +%= 2;
        len +%= addr_format.formatLength();
        len +%= 1;
        return len;
    }
};
pub fn PointerOneFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const T = struct {
        value: Pointer,
        const Format = @This();
        const SubFormat = meta.Return(fmt.ux64);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: usize = (4 +% typeName(Pointer, spec).len +% 3) +% AnyFormat(spec, child).max_len +% 1;
        pub fn formatWrite(format: anytype, array: anytype) void {
            const address: usize = @intFromPtr(format.value);
            const type_name: []const u8 = comptime typeName(Pointer, spec);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                array.writeCount(14 +% type_name.len, ("@intFromPtr(" ++ type_name ++ ", ").*);
                writeFormat(array, sub_format);
                array.writeOne(')');
            } else {
                if (spec.address_view) {
                    const addr_view_format: AddressFormat = .{ .value = address };
                    writeFormat(array, addr_view_format);
                }
                if (@typeInfo(child) == .Fn) {
                    array.writeMany("*call");
                } else {
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    if (!spec.infer_type_names) {
                        array.writeCount(6 +% type_name.len, ("@as(" ++ type_name ++ ", ").*);
                    }
                    array.writeOne('&');
                    writeFormat(array, sub_format);
                    if (!spec.infer_type_names) {
                        array.writeOne(')');
                    }
                }
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const address: usize = @intFromPtr(format.value);
            const type_name: []const u8 = comptime typeName(Pointer, spec);
            var len: usize = 0;
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                @as(*[14 +% type_name.len]u8, @ptrCast(buf + len)).* = ("@intFromPtr(" ++ type_name ++ ", ").*;
                len +%= 14 +% type_name.len;
                len +%= sub_format.formatWriteBuf(buf + len);
                buf[len] = ')';
                len +%= 1;
            } else {
                if (spec.address_view) {
                    const addr_view_format: AddressFormat = .{ .value = address };
                    len +%= addr_view_format.formatWriteBuf(buf);
                }
                if (@typeInfo(child) == .Fn) {
                    @as(*[5]u8, @ptrCast(buf + len)).* = "*call";
                } else {
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    if (!spec.infer_type_names) {
                        @as(*[6 +% type_name.len]u8, @ptrCast(buf + len)).* = ("@as(" ++ type_name ++ ", ").*;
                        len +%= 6 +% type_name.len;
                    }
                    buf[len] = '&';
                    len +%= 1;
                    len +%= sub_format.formatWriteBuf(buf + len);
                    if (!spec.infer_type_names) {
                        buf[len] = ')';
                        len +%= 1;
                    }
                }
            }
            return len;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            const address: usize = @intFromPtr(format.value);
            const type_name: []const u8 = comptime typeName(Pointer, spec);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                len +%= 12 +% type_name.len;
                len +%= sub_format.formatLength();
                len +%= 1;
            } else {
                if (spec.address_view) {
                    const addr_view_format: AddressFormat = .{ .value = address };
                    len +%= addr_view_format.formatLength();
                }
                if (@typeInfo(child) == .Fn) {
                    len +%= 5;
                } else {
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    if (!spec.infer_type_names) {
                        len +%= 6 +% type_name.len;
                    }
                    len +%= 1;
                    len +%= sub_format.formatLength();
                    if (!spec.infer_type_names) {
                        len +%= 1;
                    }
                }
            }
            return len;
        }
    };
    return T;
}
pub fn PointerSliceFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const T = struct {
        value: Pointer,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: usize = 65536;
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
        const type_name: []const u8 = typeName(Pointer, spec);
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
                if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
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
        pub fn formatWriteBufAny(format: anytype, buf: [*]u8) usize {
            var len: usize = 0;
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    buf[0] = '&';
                    len +%= 1;
                }
                @memcpy(buf + len, type_name);
                len +%= type_name.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                if (spec.infer_type_names) {
                    buf[0] = '&';
                    len +%= 1;
                }
                @memcpy(buf + len, type_name);
                len +%= type_name.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                }
                if (omit_trailing_comma) {
                    @as(*[2]u8, @ptrCast(buf + len - 2)).* = " }".*;
                } else {
                    buf[len] = '}';
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLengthAny(format: anytype) u64 {
            var len: usize = 0;
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    len +%= 1;
                }
                len +%= type_name.len +% 2;
            } else {
                if (spec.infer_type_names) {
                    len +%= 1;
                }
                len +%= type_name.len +% 2;
                if (spec.enable_comptime_iterator and comptime fmt.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatLength() +% 2;
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatLength() +% 2;
                    }
                }
                if (!omit_trailing_comma) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLengthStringLiteral(format: anytype) u64 {
            var len: usize = 1;
            for (format.value) |c| {
                len +%= fmt.esc(c).formatLength();
            }
            return len +% 1;
        }
        pub fn formatLengthMultiLineStringLiteral(format: anytype) u64 {
            var len: usize = 3;
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => len +%= 3,
                    '\t' => len +%= 2,
                    else => len +%= 1,
                }
            }
            return len +% 1;
        }
        pub fn formatWriteStringLiteral(format: anytype, array: anytype) void {
            array.writeOne('"');
            for (format.value) |byte| {
                array.writeFormat(fmt.esc(byte));
            }
            array.writeOne('"');
        }
        pub fn formatWriteMultiLineStringLiteral(format: anytype, array: anytype) void {
            array.writeMany("\n\\\\");
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => array.writeMany("\n\\\\"),
                    '\t' => array.writeMany("\\t"),
                    else => array.writeOne(byte),
                }
            }
            array.writeOne('\n');
        }
        pub fn formatWriteBufStringLiteral(format: anytype, buf: [*]u8) usize {
            var len: usize = 1;
            buf[0] = '"';
            for (format.value) |byte| {
                len +%= fmt.esc(byte).formatWriteBuf(buf + len);
            }
            buf[len] = '"';
            return len +% 1;
        }
        pub fn formatWriteBufMultiLineStringLiteral(format: anytype, buf: [*]u8) usize {
            var len: usize = 3;
            @as(*[3]u8, @ptrCast(buf)).* = "\n\\\\".*;
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => {
                        @as(*[3]u8, @ptrCast(buf + len)).* = "\n\\\\".*;
                        len +%= 3;
                    },
                    '\t' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\t".*;
                        len +%= 2;
                    },
                    else => {
                        buf[len] = byte;
                        len +%= 1;
                    },
                }
            }
            buf[len] = '\n';
            return len +% 1;
        }
        fn isMultiLine(values: []const u8) bool {
            for (values) |value| {
                if (value == '\n') return true;
            }
            return false;
        }
        const StringLiteral = fmt.GenericEscapedStringFormat(.{});
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.address_view) {
                const addr_view_format: AddressFormat = .{ .value = @intFromPtr(format.value.ptr) };
                writeFormat(array, addr_view_format);
            }
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return formatWriteMultiLineStringLiteral(format, array);
                        } else {
                            return formatWriteStringLiteral(format, array);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        const str_fmt: StringLiteral = .{ .value = format.value };
                        return str_fmt.formatWrite(array);
                    }
                }
            }
            return formatWriteAny(format, array);
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (spec.address_view) {
                const addr_view_format: AddressFormat = .{ .value = @intFromPtr(format.value.ptr) };
                len +%= addr_view_format.formatWriteBuf(buf);
            }
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return len +% formatWriteBufMultiLineStringLiteral(format, buf);
                        } else {
                            return len +% formatWriteBufStringLiteral(format, buf);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        const str_fmt: StringLiteral = .{ .value = format.value };
                        return len +% str_fmt.formatWriteBuf(buf);
                    }
                }
            }
            return len +% formatWriteBufAny(format, buf);
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (spec.address_view) {
                len +%= AddressFormat.formatLength(.{ .value = @intFromPtr(format.value.ptr) });
            }
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return len +% formatLengthMultiLineStringLiteral(format);
                        } else {
                            return len +% formatLengthStringLiteral(format);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        const str_fmt: StringLiteral = .{ .value = format.value };
                        return len +% str_fmt.formatLength();
                    }
                }
            }
            return len +% formatLengthAny(format);
        }
    };
    return T;
}
pub fn PointerManyFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const T = struct {
        value: Pointer,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const type_info: builtin.Type = @typeInfo(Pointer);
        const type_name: []const u8 = typeName(Pointer, spec);
        const child: type = type_info.Pointer.child;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                var len: usize = 0;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                writeFormat(array, slice_fmt);
            } else {
                array.writeMany(type_name ++ "{ ... }");
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                len = slice_fmt.formatWriteBuf(buf);
            } else {
                @as(*[7]u8, @ptrCast(buf)).* = "{ ... }".*;
                len +%= 7;
            }
            return len;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                len +%= slice_fmt.formatLength();
            } else {
                len +%= 7;
            }
            return len;
        }
    };
    return T;
}
pub fn OptionalFormat(comptime spec: RenderSpec, comptime Optional: type) type {
    comptime var odr: ?meta.Generic = null;
    const T = struct {
        value: Optional,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Optional).Optional.child;
        const type_name: []const u8 = typeName(Optional);
        const max_len: usize = (4 +% type_name.len +% 2) +% @max(1 +% ChildFormat.max_len, 5);
        const render_readable: bool = true;
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (odr) |prev| {
                return prev.cast()(format, array);
            }
            if (!render_readable) {
                array.writeCount(4, "@as(".*);
                array.writeMany(type_name);
                array.writeCount(2, ", ".*);
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                writeFormat(array, sub_format);
            } else {
                array.writeCount(4, "null".*);
            }
            if (!render_readable) {
                array.writeOne(')');
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (!render_readable) {
                @as(*[4]u8, @ptrCast(buf)).* = "@as(".*;
                len +%= 4;
                @as(meta.TypeName(Optional), buf + len).* = @typeName(Optional).*;
                len +%= @typeName(Optional).len;
                @as(*[2]u8, @ptrCast(buf)).* = ", ".*;
                len +%= 2;
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                len +%= sub_format.formatWriteBuf(buf);
            } else {
                @as(*[4]u8, @ptrCast(buf)).* = "null".*;
                len +%= 4;
            }
            if (!render_readable) {
                buf[len] = ')';
                len +%= 1;
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (!render_readable) {
                len +%= 4 +% type_name.len +% 2;
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
    };
    return T;
}
pub const NullFormat = struct {
    comptime value: @TypeOf(null) = null,
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format = @This();
    const max_len: usize = 4;
    pub fn formatWrite(array: anytype) void {
        array.writeMany("null");
    }
    pub fn formatLength() usize {
        return 4;
    }
};
pub const VoidFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format = @This();
    const max_len: usize = 2;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "{}".*);
    }
    pub fn formatLength() usize {
        return 2;
    }
};
pub const NoReturnFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () u64 = formatLength,
    const Format = @This();
    const max_len: usize = 8;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "noreturn".*);
    }
    pub fn formatLength() usize {
        return 8;
    }
};
pub fn VectorFormat(comptime spec: RenderSpec, comptime Vector: type) type {
    const T = struct {
        value: Vector,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const vector_info: builtin.Type = @typeInfo(Vector);
        const child: type = vector_info.Vector.child;
        const type_name: []const u8 = typeName(Vector);
        const max_len: usize = (type_name.len +% 2) +
            vector_info.Vector.len *% (ChildFormat.max_len +% 2);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (vector_info.Vector.len == 0) {
                array.writeMany(type_name);
                array.writeMany("{}");
            } else {
                array.writeMany(type_name);
                array.writeMany("{ ");
                comptime var i: u64 = 0;
                inline while (i != vector_info.Vector.len) : (i +%= 1) {
                    const element_format: ChildFormat = .{ .value = format.value[i] };
                    writeFormat(array, element_format);
                    array.writeCount(2, ", ".*);
                }
                array.overwriteManyBack(" }");
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = type_name.len +% 2;
            comptime var i: u64 = 0;
            inline while (i != vector_info.Vector.len) : (i +%= 1) {
                const element_format: ChildFormat = .{ .value = format.value[i] };
                len +%= element_format.formatLength() +% 2;
            }
            return len;
        }
    };
    return T;
}
pub fn ErrorUnionFormat(comptime spec: RenderSpec, comptime ErrorUnion: type) type {
    const T = struct {
        value: ErrorUnion,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(ErrorUnion);
        const PayloadFormat: type = AnyFormat(spec, type_info.ErrorUnion.payload);
        pub fn formatWrite(format: Format, array: anytype) void {
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                writeFormat(array, payload_format);
            } else |any_error| {
                array.writeMany("error.");
                array.writeMany(@errorName(any_error));
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                len +%= payload_format.formatLength();
            } else |any_error| {
                len +%= 6;
                len +%= @errorName(any_error).len;
            }
            return len;
        }
    };
    return T;
}
pub fn ErrorSetFormat(comptime ErrorSet: type) type {
    const T = struct {
        value: ErrorSet,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeMany("error.");
            array.writeMany(@errorName(format.value));
        }
        pub fn formatLength(format: Format) usize {
            return 6 +% @errorName(format.value).len;
        }
    };
    return T;
}
pub fn ContainerFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    const T = struct {
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
                writeFormat(array, values_format);
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                writeFormat(array, values_format);
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
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
    return T;
}
pub fn FormatFormat(comptime Struct: type) type {
    const T = struct {
        value: Struct,
        const Format = @This();
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return writeFormat(array, format.value);
        }
        pub inline fn formatLength(format: Format) usize {
            return format.value.formatLength();
        }
    };
    return T;
}
pub const TypeDescrFormatSpec = struct {
    token: type = []const u8,
    depth: u64 = 0,
    decls: bool = false,
    identifier_name: bool = true,
    tokens: Tokens = .{},
    default_field_values: DefaultFieldValues = .{ .exact = .{} },
    const DefaultFieldValues = union(enum) {
        omit,
        fast,
        exact: RenderSpec,
    };
    const Tokens = struct {
        decl: [:0]const u8 = "pub const ",
        lbrace: [:0]const u8 = " {\n",
        equal: [:0]const u8 = " = ",
        rbrace: [:0]const u8 = "}",
        next: [:0]const u8 = ",\n",
        end: [:0]const u8 = ";\n",
        colon: [:0]const u8 = ": ",
        indent: [:0]const u8 = "    ",
    };
};
pub fn GenericTypeDescrFormat(comptime spec: TypeDescrFormatSpec) type {
    const U = union(enum) {
        type_decl: Declaration,
        type_ref: Reference,
        const Format = @This();
        var depth: u64 = spec.depth;
        pub var scope: []const Declaration = &.{};
        const tab = .{
            .decl = spec.tokens.decl[0..spec.tokens.decl.len].*,
            .lbrace = spec.tokens.lbrace[0..spec.tokens.lbrace.len].*,
            .equal = spec.tokens.equal[0..spec.tokens.equal.len].*,
            .rbrace = spec.tokens.rbrace[0..spec.tokens.rbrace.len].*,
            .next = spec.tokens.next[0..spec.tokens.next.len].*,
            .end = spec.tokens.end[0..spec.tokens.end.len].*,
            .colon = spec.tokens.colon[0..spec.tokens.colon.len].*,
            .indent = spec.tokens.indent[0..spec.tokens.indent.len].*,
        };
        pub const Reference = struct { spec: spec.token, type: *const Format };
        pub const Container = struct {
            spec: spec.token,
            fields: []const Field,
            decls: []const Declaration = &.{},
            pub fn formatWrite(format: Container, array: anytype) void {
                for (scope) |decl| {
                    if (mem.testEqualMemory(Container, format, decl.defn.?)) {
                        return Format.formatWrite(.{ .type_decl = .{ .name = decl.name } }, array);
                    }
                }
                array.writeMany(format.spec);
                depth +%= 1;
                array.writeMany(spec.tokens.lbrace);
                for (0..depth) |_| array.writeMany(spec.tokens.indent);
                for (format.fields) |field| {
                    writeFormat(array, field);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        writeFormat(array, field);
                    }
                }
                array.undefine(spec.tokens.indent.len);
                array.writeMany(spec.tokens.rbrace);
                depth -%= 1;
            }
            pub fn formatWriteBuf(format: Container, buf: [*]u8) usize {
                for (scope) |decl| {
                    if (mem.testEqualMemory(Container, format, decl.defn.?)) {
                        return Format.formatWrite(.{ .type_decl = .{ .name = decl.name } }, buf);
                    }
                }
                var len: usize = 0;
                @memcpy(buf + len, format.spec);
                len +%= format.spec.len;
                depth +%= 1;
                @as(*@TypeOf(Format.tab.lbrace), @ptrCast(buf + len)).* = Format.tab.lbrace;
                len +%= Format.tab.lbrace.len;
                for (0..depth) |_| {
                    @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                    len +%= Format.tab.indent.len;
                }
                for (format.fields) |field| {
                    len +%= field.formatWriteBuf(buf + len);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        len +%= field.formatWriteBuf(buf + len);
                    }
                }
                len -%= spec.tokens.indent.len;
                @as(*@TypeOf(Format.tab.rbrace), @ptrCast(buf + len)).* = Format.tab.rbrace;
                len +%= Format.tab.rbrace.len;
                depth -%= 1;
                return len;
            }
            pub fn formatLength(format: Container) usize {
                for (scope) |decl| {
                    if (mem.testEqualMemory(Container, format, decl.defn.?)) {
                        return Format.formatLength(.{ .type_decl = .{ .name = decl.name } });
                    }
                }
                var len: usize = 0;
                len +%= format.spec.len;
                depth +%= 1;
                len +%= Format.tab.lbrace.len;
                len +%= depth *% Format.tab.indent.len;
                for (format.fields) |field| {
                    len +%= field.formatLength();
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        len +%= field.formatLength();
                    }
                }
                len -%= spec.tokens.indent.len;
                len +%= Format.tab.rbrace.len;
                depth -%= 1;
                return len;
            }
        };
        pub const Declaration = struct {
            name: ?spec.token = null,
            defn: ?Container = null,
        };
        pub const Field = struct {
            name: spec.token,
            type: ?Format = null,
            value: Value = .{ .default = null },
            const Value = union(enum) {
                default: ?spec.token,
                enumeration: usize,
            };
            pub fn formatWrite(format: Field, array: anytype) void {
                if (spec.identifier_name) {
                    array.writeFormat(fmt.IdentifierFormat{ .value = format.name });
                } else {
                    array.writeMany(format.name);
                }
                if (format.type) |field_type| {
                    array.writeMany(spec.tokens.colon);
                    writeFormat(array, field_type);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            array.writeMany(spec.tokens.equal);
                            array.writeMany(default_value);
                        }
                    },
                    .enumeration => {
                        array.writeMany(spec.tokens.equal);
                        array.writeFormat(fmt.ud64(format.value.enumeration));
                    },
                }
                array.writeMany(spec.tokens.next);
                for (0..depth) |_| array.writeMany(spec.tokens.indent);
            }
            pub fn formatWriteBuf(format: Field, buf: [*]u8) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = 0;
                if (spec.identifier_name) {
                    len +%= fmt.IdentifierFormat.formatWriteBuf(.{ .value = format.name }, buf);
                } else {
                    @memcpy(buf, format.name);
                    len +%= format.name;
                }
                if (format.type) |field_type| {
                    @as(*@TypeOf(Format.tab.colon), @ptrCast(buf + len)).* = Format.tab.colon;
                    len +%= Format.tab.colon.len;
                    len +%= field_type.formatWriteBuf(buf + len);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                            len +%= Format.tab.equal.len;
                            @memcpy(buf + len, default_value);
                            len +%= default_value.len;
                        }
                    },
                    .enumeration => {
                        @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                        len +%= Format.tab.equal.len;
                        len +%= fmt.ud64(format.value.enumeration).formatWriteBuf(buf + len);
                    },
                }
                @as(*@TypeOf(Format.tab.next), @ptrCast(buf + len)).* = Format.tab.next;
                len +%= Format.tab.next.len;
                for (0..depth) |_| {
                    @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                    len +%= Format.tab.indent.len;
                }
                return len;
            }
            pub fn formatLength(format: Field) usize {
                var len: usize = 0;
                if (spec.identifier_name) {
                    len +%= fmt.identifier(format.name).formatLength();
                } else {
                    len +%= format.name.len;
                }
                if (format.type) |field_type| {
                    len +%= spec.tokens.colon.len;
                    len +%= field_type.formatLength();
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            len +%= Format.tab.equal.len;
                            len +%= default_value.len;
                        }
                    },
                    .enumeration => {
                        len +%= Format.tab.equal.len;
                        len +%= fmt.ud64(format.value.enumeration).formatLength();
                    },
                }
                len +%= spec.tokens.next.len;
                len +%= depth *% spec.tokens.indent.len;
                return len;
            }
        };
        pub fn formatWrite(type_descr: Format, array: anytype) void {
            switch (type_descr) {
                .type_ref => |type_ref| {
                    array.writeMany(type_ref.spec);
                    type_ref.type.formatWrite(array);
                },
                .type_decl => |type_decl| {
                    if (spec.depth != 0 and
                        spec.depth != depth)
                    {
                        for (0..depth) |_| array.writeMany(spec.tokens.indent);
                    }
                    if (type_decl.name) |type_name| {
                        if (type_decl.defn) |type_defn| {
                            array.writeMany(spec.tokens.decl);
                            if (spec.identifier_name) {
                                array.writeFormat(fmt.identifier(type_name));
                            } else {
                                array.writeMany(type_name);
                            }
                            array.writeMany(spec.tokens.equal);
                            writeFormat(array, type_defn);
                            array.writeMany(spec.tokens.end);
                            for (0..depth) |_| array.writeMany(spec.tokens.indent);
                        } else {
                            array.writeMany(type_name);
                        }
                    } else {
                        if (type_decl.defn) |type_defn| {
                            writeFormat(array, type_defn);
                        }
                    }
                },
            }
        }
        pub fn formatWriteBuf(type_descr: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            switch (type_descr) {
                .type_ref => |type_ref| {
                    @memcpy(buf + len, type_ref.spec);
                    len +%= type_ref.spec.len;
                    len +%= type_ref.type.formatWriteBuf(buf + len);
                },
                .type_decl => |type_decl| {
                    if (spec.depth != 0 and
                        spec.depth != depth)
                    {
                        for (0..depth) |_| {
                            @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                            len +%= Format.tab.indent.len;
                        }
                    }
                    if (type_decl.name) |type_name| {
                        if (type_decl.defn) |type_defn| {
                            @as(*@TypeOf(Format.tab.decl), @ptrCast(buf + len)).* = Format.tab.decl;
                            len +%= Format.tab.decl.len;
                            if (spec.identifier_name) {
                                len +%= fmt.identifier(type_name).formatWriteBuf(buf);
                            } else {
                                @memcpy(buf, type_name);
                                len +%= type_name.len;
                            }
                            @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                            len +%= Format.tab.equal.len;
                            len +%= type_defn.formatWriteBuf(buf + len);
                            @as(*@TypeOf(Format.tab.end), @ptrCast(buf + len)).* = Format.tab.end;
                            len +%= Format.tab.end.len;
                            for (0..depth) |_| {
                                @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                                len +%= Format.tab.indent.len;
                            }
                        } else {
                            @memcpy(buf, type_name);
                            len +%= type_name.len;
                        }
                    } else {
                        if (type_decl.defn) |type_defn| {
                            len +%= type_defn.formatWriteBuf(buf);
                        }
                    }
                },
            }
            return len;
        }
        pub fn formatLength(type_descr: Format) usize {
            var len: usize = 0;
            switch (type_descr) {
                .type_ref => |type_ref| {
                    len +%= type_ref.spec.len;
                    len +%= type_ref.type.formatLength();
                },
                .type_decl => |type_decl| {
                    if (spec.depth != 0 and
                        spec.depth != depth)
                    {
                        len +%= depth *% Format.tab.indent.len;
                    }
                    if (type_decl.name) |type_name| {
                        if (type_decl.defn) |type_defn| {
                            len +%= Format.tab.decl.len;
                            if (spec.identifier_name) {
                                len +%= fmt.identifier(type_name).formatLength();
                            } else {
                                len +%= type_name.len;
                            }
                            len +%= Format.tab.equal.len;
                            len +%= type_defn.formatLength();
                            len +%= Format.tab.end.len;
                            len +%= depth *% Format.tab.indent.len;
                        } else {
                            len +%= type_name.len;
                        }
                    } else {
                        if (type_decl.defn) |type_defn| {
                            len +%= type_defn.formatLength();
                        }
                    }
                },
            }
            return len;
        }
        pub fn cast(type_descr: anytype, comptime cast_spec: TypeDescrFormatSpec) GenericFormat(cast_spec) {
            debug.assert(
                cast_spec.default_field_values ==
                    spec.default_field_values,
            );
            return @as(*const GenericFormat(cast_spec), @ptrCast(type_descr)).*;
        }
        inline fn defaultFieldValue(comptime field_type: type, comptime default_value_opt: ?*const anyopaque) ?spec.token {
            if (default_value_opt) |default_value_ptr| {
                switch (spec.default_field_values) {
                    .omit => return null,
                    .fast => return fmt.cx(default_value_ptr),
                    .exact => |render_spec| {
                        const value_fmt = render(render_spec, mem.pointerOpaque(field_type, default_value_ptr).*);
                        const len: usize = value_fmt.formatLength();
                        var buf: [len]u8 = undefined;
                        debug.assertEqual(usize, len, value_fmt.formatWriteBuf(&buf));
                        return buf[0..len];
                    },
                }
            } else {
                return null;
            }
        }
        inline fn defaultDeclareCriteria(comptime T: type, comptime decl: builtin.Type.Declaration) ?type {
            if (decl.is_pub) {
                const u = @field(T, decl.name);
                const U = @TypeOf(u);
                if (U == type and meta.isContainer(u) and u != T) {
                    return u;
                }
            }
            return null;
        }
        const TypeDecl = struct { []const u8, type };
        const types: *[]const TypeDecl = blk: {
            var res: []const TypeDecl = &.{};
            break :blk &res;
        };
        pub inline fn declare(comptime name: []const u8, comptime T: type) Format {
            comptime {
                const type_info: builtin.Type = @typeInfo(T);
                for (types.*) |type_decl| {
                    if (type_decl[1] == T) {
                        return .{ .type_name = type_decl[0] };
                    }
                } else {
                    types.* = types.* ++ [1]TypeDecl{.{ name, T }};
                }
                switch (type_info) {
                    else => return .{ .type_name = @typeName(T) },
                    .Struct => |struct_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (struct_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Union => |union_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (union_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Enum => |enum_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (enum_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = field.value },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = field.value },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Optional => |optional_info| {
                        return .{ .type_ref = .{
                            .spec = fmt.typeDeclSpecifier(type_info),
                            .type = &init(optional_info.child),
                        } };
                    },
                    .Pointer => |pointer_info| {
                        return .{ .type_ref = .{ .name = name, .defn = .{
                            .spec = fmt.typeDeclSpecifier(type_info),
                            .type = &init(pointer_info.child),
                        } } };
                    },
                }
            }
        }
        pub fn init(comptime T: type) Format {
            comptime {
                for (types.*) |type_decl| {
                    if (type_decl[1] == T) {
                        return .{ .type_decl = .{ .name = type_decl[0] } };
                    }
                }
                const type_info: builtin.Type = @typeInfo(T);
                switch (type_info) {
                    else => return .{ .type_decl = .{ .name = @typeName(T) } },
                    .Struct => |struct_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (struct_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Union => |union_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (union_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Enum => |enum_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (enum_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{.{
                                        .name = decl.name,
                                        .type = declare(decl.name, U),
                                    }};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = field.value },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = field.value },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = fmt.typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Optional => |optional_info| {
                        return .{ .type_ref = .{
                            .spec = fmt.typeDeclSpecifier(type_info),
                            .type = &init(optional_info.child),
                        } };
                    },
                    .Pointer => |pointer_info| {
                        return .{ .type_ref = .{
                            .spec = fmt.typeDeclSpecifier(type_info),
                            .type = &init(pointer_info.child),
                        } };
                    },
                }
            }
        }
    };
    return U;
}
