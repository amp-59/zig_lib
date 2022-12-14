const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
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
        //            .ComptimeInt => ComptimeIntFormat,
        //            .Int => IntFormat(Type),
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
        //            else => @compileError(comptime shortTypeName(Type)),
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
        pub usingnamespace fmt.GenericFormat(Format);
    };
}

//  Function
//  Boolean
//  Type
//  Struct
//  Union
//  Enum
//  EnumLiteral
//  ComptimeInt
//  Int
//  Pointer
//      One
//      Many
//      Slice
//  Optional
//  Null
//  Void
//  Vector
//  ErrorUnion

