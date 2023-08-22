const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const math = @import("./math.zig");
const mach = @import("./mach.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
pub const Empty = struct {};
pub const empty = &.{};
pub const default = .{};
pub const SliceProperty = struct { comptime_int, type };
pub const number_types: []const builtin.TypeId = integer_types ++ float_types;
pub const integer_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Int, .ComptimeInt };
pub const float_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Float, .ComptimeFloat };
pub const enum_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Int, .ComptimeInt, .Enum, .EnumLiteral };
pub const tag_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Type, .ErrorUnion, .Enum, .EnumLiteral };
pub const fn_types: []const builtin.TypeId = &[_]builtin.TypeId{.Fn};
pub const data_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Union };
pub const decl_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Union, .Enum };
pub const container_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Enum, .Union, .Opaque };
pub const enum_info_base: builtin.Type.Enum = .{ .tag_type = u0, .fields = &.{}, .decls = &.{}, .is_exhaustive = true };
pub const enum_field_base: builtin.Type.EnumField = .{ .name = &.{}, .value = 0 };
pub const union_info_base: builtin.Type.Union = .{ .tag_type = null, .layout = .Auto, .fields = &.{}, .decls = &.{} };
pub const union_field_base: builtin.Type.UnionField = .{ .name = undefined, .type = undefined, .alignment = 0 };
pub const struct_info_base: builtin.Type.Struct = .{ .fields = &.{}, .decls = &.{}, .layout = .Auto, .is_tuple = false };
pub const struct_field_base: builtin.Type.StructField = .{ .name = undefined, .type = undefined, .default_value = null, .alignment = 0, .is_comptime = false };
pub const tuple_info_base: builtin.Type.Struct = .{ .fields = &.{}, .decls = &.{}, .layout = .Auto, .is_tuple = true };
pub const opaque_info_base: builtin.Type.Opaque = .{ .decls = &.{} };

pub const Generic = struct {
    type: type,
    value: *const anyopaque,
    pub fn cast(comptime any: Generic) any.type {
        return @as(*align(@max(@alignOf(any.type), 1)) const any.type, @ptrCast(@alignCast(any.value))).*;
    }
};
inline fn isTypeType(comptime T: type, comptime type_types: []const builtin.TypeId) bool {
    inline for (type_types) |type_type| {
        if (@typeInfo(T) == type_type) {
            return true;
        }
    }
    return false;
}
pub inline fn isNumber(comptime T: type) bool {
    return comptime isTypeType(T, number_types);
}
pub inline fn isInteger(comptime T: type) bool {
    return comptime isTypeType(T, integer_types);
}
pub inline fn isFloat(comptime T: type) bool {
    return comptime isTypeType(T, float_types);
}
pub inline fn isEnum(comptime T: type) bool {
    return comptime isTypeType(T, enum_types);
}
pub inline fn isTag(comptime T: type) bool {
    return comptime isTypeType(T, tag_types);
}
pub inline fn isFunction(comptime T: type) bool {
    return comptime isTypeType(T, fn_types);
}
pub inline fn isContainer(comptime T: type) bool {
    return comptime isTypeType(T, container_types);
}
pub fn assertType(comptime T: type, comptime tag: builtin.TypeId) void {
    if (builtin.comptime_assertions) {
        const type_info: builtin.Type = @typeInfo(T);
        if (type_info != tag) {
            about.unexpectedTypeTypeError(T, type_info, tag);
        }
    }
}
pub fn assertHasDecl(comptime T: type, decl_name: []const u8) void {
    if (builtin.comptime_assertions) {
        if (!@hasDecl(T, decl_name)) {
            about.declError(T, decl_name);
        }
    }
}
pub fn assertHasField(comptime T: type, field_name: []const u8) void {
    if (builtin.comptime_assertions) {
        if (!@hasField(T, field_name)) {
            about.fieldError(T, field_name);
        }
    }
}
pub fn assertContinuousEnumeration(comptime E: type) void {
    var value: @typeInfo(E).Enum.tag_type = 0;
    inline for (@typeInfo(E).Enum.fields) |field| {
        if (field.value != value) {
            about.enumFieldValueNotContinuous(E, value, field.name, field.value);
        }
        value +%= 1;
    }
}
/// If the input is a union return the active field else return the input.
pub inline fn resolve(comptime any: anytype) if (@typeInfo(@TypeOf(any)) == .Union)
    @TypeOf(comptime @field(any, @tagName(any)))
else
    @TypeOf(any) {
    if (@typeInfo(@TypeOf(any)) == .Union) {
        return @field(any, @tagName(any));
    } else {
        return any;
    }
}
pub fn untaggedActiveField(comptime value: anytype) builtin.Type.UnionField {
    const S: type = @TypeOf(value);
    const fields: []const builtin.Type.UnionField = @typeInfo(S).Union.fields;
    const T = [:value]S;
    comptime {
        if (@typeName(T)[6..][0] == ' ' and @typeName(T)[6..][1] == '=') {
            return fields[0];
        }
        for (fields) |field| {
            if (@typeName(T)[6..].len < field.name.len +% 2) {
                continue;
            }
            for (@typeName(T)[6..][0..field.name.len], field.name) |s, t| {
                if (s != t) {
                    break;
                }
            } else {
                return field;
            }
        }
    }
}
/// A parceled value can be concatenated using `++`
pub fn parcel(comptime T: type, arg: T) []const T {
    return &[1]T{arg};
}
pub fn concat(comptime T: type, comptime arg1: []const T, comptime arg2: T) []const T {
    return arg1 ++ comptime parcel(T, arg2);
}
/// A wrapped value can be unwrapped using `try`
pub inline fn wrap(any: anytype) blk: {
    const T: type = @TypeOf(any);
    if (@typeInfo(T) == .ErrorUnion) {
        break :blk T;
    }
    break :blk error{}!T;
} {
    return any;
}
/// Return T if cond is true, else a type of the same kind with zero size.
pub fn maybe(comptime cond: bool, comptime T: type) type {
    if (cond) return T;
    const type_info: builtin.Type = @typeInfo(T);
    switch (type_info) {
        .Int => return u0,
        .Struct => return struct {},
        .Opaque => return opaque {},
        .Enum => return enum {},
        else => {
            about.unexpectedTypeTypesError(type_info, T, .{ .Int, .Struct, .Opaque, .Enum });
        },
    }
}
pub fn TypeName(comptime T: type) type {
    return @TypeOf(@constCast(@typeName(T)));
}
/// Return a simple struct field
pub fn structField(comptime T: type, comptime field_name: []const u8, comptime default_value_opt: ?T) builtin.Type.StructField {
    if (default_value_opt) |default_value| {
        return .{
            .name = field_name,
            .type = T,
            .default_value = blk: {
                if (@TypeOf(default_value) == ?*const anyopaque) {
                    break :blk @ptrCast(&default_value);
                } else {
                    break :blk &default_value;
                }
            },
            .is_comptime = false,
            .alignment = 0,
        };
    } else {
        return .{
            .name = field_name,
            .type = T,
            .default_value = null,
            .is_comptime = false,
            .alignment = 0,
        };
    }
}
pub inline fn fieldNames(comptime T: type) []const []const u8 {
    comptime {
        var symbols: []const []const u8 = &.{};
        for (resolve(@typeInfo(T)).fields) |field| {
            symbols = symbols ++ [1][]const u8{field.name};
        }
        return symbols;
    }
}
/// Assist creation of struct types
pub fn structInfo(
    comptime layout: builtin.Type.ContainerLayout,
    comptime fields: []const builtin.Type.StructField,
) builtin.Type {
    var ret: builtin.Type.Struct = struct_info_base;
    ret.fields = fields;
    ret.layout = layout;
    return .{ .Struct = ret };
}
/// Assist creation of tuple types
pub fn tupleInfo(comptime fields: []const builtin.Type.StructField) builtin.Type {
    var ret: builtin.Type.Struct = tuple_info_base;
    ret.fields = fields;
    return .{ .Struct = ret };
}
pub fn defaultValue(comptime struct_field: builtin.Type.StructField) ?struct_field.type {
    if (struct_field.default_value) |default_value_ptr| {
        const ret: *align(@max(1, @alignOf(struct_field.type))) const struct_field.type = @ptrCast(@alignCast(default_value_ptr));
        return ret.*;
    }
    return null;
}
pub fn Tuple(comptime T: type) type {
    return @Type(tupleInfo(@typeInfo(T).Struct.fields));
}
pub fn Args(comptime Fn: type) type {
    var tuple_info: builtin.Type.Struct = tuple_info_base;
    for (@typeInfo(Fn).Fn.params, 0..) |arg, i| {
        tuple_info.fields = tuple_info.fields ++ [1]builtin.Type.StructField{structField(arg.type.?, fmt.ci(i), null)};
    }
    return @Type(.{ .Struct = tuple_info });
}
pub inline fn tuple(any: anytype) Tuple(@TypeOf(any)) {
    return any;
}
pub inline fn call(comptime function: anytype, arguments: anytype) @TypeOf(@call(.auto, function, arguments)) {
    switch (builtin.zig.mode) {
        .Debug => {
            return @call(.never_inline, function, arguments);
        },
        .ReleaseSmall, .ReleaseSafe => {
            return @call(.auto, function, arguments);
        },
        .ReleaseFast => {
            return @call(.always_inline, function, arguments);
        },
    }
}
/// Align `count` below to bitSizeOf smallest real word bit count
pub fn alignBitSizeBelow(comptime count: comptime_int) u16 {
    switch (count) {
        0...7 => return 0,
        8...15 => return 8,
        16...31 => return 16,
        32...63 => return 32,
        64...127 => return 64,
        128...255 => return 128,
        256...511 => return 256,
        else => return 512,
    }
}
/// Align `count` above to bitSizeOf smallest real word bit count
pub fn alignBitSizeAbove(comptime count: comptime_int) u16 {
    switch (count) {
        0 => return 0,
        1...8 => return 8,
        9...16 => return 16,
        17...32 => return 32,
        33...64 => return 64,
        65...128 => return 128,
        129...256 => return 256,
        else => return 512,
    }
}
/// Return the smallest real bitSizeOf the integer type required to store the
/// comptime integer.
pub fn realBitSizeOf(comptime value: comptime_int) u16 {
    if (value > 0) {
        switch (value) {
            0...~@as(u8, 0) => return 8,
            @as(u9, 1) << 8...~@as(u16, 0) => return 16,
            @as(u17, 1) << 16...~@as(u32, 0) => return 32,
            @as(u33, 1) << 32...~@as(u64, 0) => return 64,
            @as(u65, 1) << 64...~@as(u128, 0) => return 128,
            @as(u129, 1) << 128...~@as(u256, 0) => return 256,
            @as(u257, 1) << 256...~@as(u512, 0) => return 512,
            else => return @compileLog(value),
        }
    } else {
        const xi8: math.Extrema = math.extrema(i8);
        const xi16: math.Extrema = math.extrema(i16);
        const xi32: math.Extrema = math.extrema(i32);
        const xi64: math.Extrema = math.extrema(i64);
        const xi128: math.Extrema = math.extrema(i128);
        const xi256: math.Extrema = math.extrema(i256);
        const xi512: math.Extrema = math.extrema(i512);
        switch (value) {
            xi8.min...xi8.max => return 8,
            xi16.min...xi8.min - 1, xi8.max + 1...xi16.max => return 16,
            xi32.min...xi16.min - 1, xi16.max + 1...xi32.max => return 32,
            xi64.min...xi32.min - 1, xi32.max + 1...xi64.max => return 64,
            xi128.min...xi64.min - 1, xi64.max + 1...xi128.max => return 128,
            xi256.min...xi128.min - 1, xi128.max + 1...xi256.max => return 128,
            xi512.min...xi256.min - 1, xi256.max + 1...xi512.max => return 128,
            else => return @compileLog(value),
        }
    }
}
pub inline fn alignBitSizeOfBelow(comptime T: type) u16 {
    return alignBitSizeBelow(@bitSizeOf(T));
}
pub inline fn alignBitSizeOfAbove(comptime T: type) u16 {
    return alignBitSizeAbove(@bitSizeOf(T));
}
pub fn AlignBitSizeBelow(comptime T: type) type {
    var int_type_info: builtin.Type.Int = @typeInfo(T).Int;
    int_type_info.bits = alignBitSizeBelow(int_type_info.bits);
    return @Type(.{ .Int = int_type_info });
}
pub fn AlignBitSizeAbove(comptime T: type) type {
    var int_type_info: builtin.Type.Int = @typeInfo(T).Int;
    int_type_info.bits = alignBitSizeAbove(int_type_info.bits);
    return @Type(.{ .Int = int_type_info });
}

/// Return the smallest integer type capable of storing `value`
pub fn LeastBitSize(comptime value: anytype) type {
    const T: type = @TypeOf(value);
    if (T == type) {
        return LeastBitSize(@as(value, undefined));
    }
    if (@sizeOf(T) == 0) {
        if (value < 0) {
            var U: type = i1;
            while (value < @as(U, @truncate(value))) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) + 1,
                    .signedness = .signed,
                } });
            }
            return U;
        } else {
            var U: type = u1;
            while (value > @as(U, @truncate(value))) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) + 1,
                    .signedness = .unsigned,
                } });
            }
            return U;
        }
    }
    return @Type(.{
        .Int = .{
            .bits = @bitSizeOf(T) - @clz(leastBitCast(value)),
            .signedness = .unsigned,
        },
    });
}
/// Return the smallest register sized integer type capable of storing `value`
pub fn LeastRealBitSize(comptime value: anytype) type {
    const T: type = @TypeOf(value);
    if (T == type) {
        return LeastBitSize(@as(value, undefined));
    }
    if (@sizeOf(T) == 0) {
        if (value < 0) {
            var U: type = i8;
            while (value < @as(U, @truncate(value))) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) << 1,
                    .signedness = .signed,
                } });
            }
            return U;
        } else {
            var U: type = u8;
            while (value > @as(U, @truncate(value))) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) << 1,
                    .signedness = .unsigned,
                } });
            }
            return U;
        }
    }
    return @Type(.{
        .Int = .{
            .bits = alignBitSizeAbove(@bitSizeOf(T) - @clz(value)),
            .signedness = .unsigned,
        },
    });
}
/// This is for miscellaneous special cases that normally Zig refuses to cast.
/// The user of this function gets what they ask for.
pub inline fn bitCast(comptime T: type, any: anytype) T {
    @setRuntimeSafety(false);
    const S: type = @TypeOf(any);
    const s_type_info: builtin.Type = @typeInfo(S);
    const t_type_info: builtin.Type = @typeInfo(T);
    switch (s_type_info) {
        .Int => {
            switch (t_type_info) {
                .Int => {
                    return @as(T, @intCast(any));
                },
                .Enum => {
                    return @as(T, @enumFromInt(any));
                },
                else => {},
            }
        },
        .Bool => {
            switch (t_type_info) {
                .Enum => {
                    return @as(T, @enumFromInt(@intFromBool(any)));
                },
            }
        },
        .ComptimeInt => {
            return @as(T, any);
        },
        .Pointer => {
            switch (t_type_info) {
                .Int => {
                    return @as(T, @intCast(@intFromPtr(any)));
                },
                else => {},
            }
        },
        .Enum => {
            switch (t_type_info) {
                .Struct => {
                    return @as(T, @bitCast(@intFromEnum(any)));
                },
                else => {},
            }
        },
        .Struct => {
            switch (t_type_info) {
                .Int => {
                    return @as(T, @intCast(@as(s_type_info.Struct.backing_integer.?, @bitCast(any))));
                },
                else => {},
            }
        },
        else => {},
    }
    @compileError("uncased combination of types: '" ++ @typeName(S) ++ "' and '" ++ @typeName(T) ++ "'");
}
pub inline fn leastBitCast(any: anytype) @Type(.{ .Int = .{
    .bits = @bitSizeOf(@TypeOf(any)),
    .signedness = .unsigned,
} }) {
    const T: type = @TypeOf(any);
    const U: type = @Type(.{ .Int = .{
        .bits = @bitSizeOf(T),
        .signedness = .unsigned,
    } });
    return @as(U, @bitCast(any));
}
pub inline fn leastRealBitCast(any: anytype) @Type(.{ .Int = .{
    .bits = alignBitSizeAbove(@bitSizeOf(@TypeOf(any))),
    .signedness = .unsigned,
} }) {
    return leastBitCast(any);
}
pub fn Allowzero(comptime T: type) type {
    var type_info: builtin.Type = @typeInfo(T);
    type_info.Pointer.is_allowzero = true;
    return @Type(type_info);
}
pub fn ArrayPointerToSlice(comptime T: type) type {
    const type_info: builtin.Type = @typeInfo(T);
    const child_type_info: builtin.Type = @typeInfo(type_info.Pointer.child);
    return @Type(.{ .Pointer = .{
        .size = .Slice,
        .alignment = type_info.Pointer.alignment,
        .address_space = type_info.Pointer.address_space,
        .is_const = type_info.Pointer.is_const,
        .is_volatile = type_info.Pointer.is_volatile,
        .is_allowzero = type_info.Pointer.is_allowzero,
        .sentinel = child_type_info.Array.sentinel,
        .child = child_type_info.Array.child,
    } });
}
pub fn SliceToArrayPointer(comptime T: type, comptime len: comptime_int) type {
    const type_info: builtin.Type = @typeInfo(T);
    return @Type(.{ .Pointer = .{
        .size = .One,
        .alignment = type_info.Pointer.alignment,
        .address_space = type_info.Pointer.address_space,
        .is_const = type_info.Pointer.is_const,
        .is_volatile = type_info.Pointer.is_volatile,
        .is_allowzero = type_info.Pointer.is_allowzero,
        .sentinel = null,
        .child = @Type(.{ .Array = .{
            .len = len,
            .sentinel = type_info.Pointer.sentinel,
            .child = type_info.Pointer.child,
        } }),
    } });
}
pub inline fn arrayPointerToSlice(any: anytype) ArrayPointerToSlice(@TypeOf(any)) {
    return @as(ArrayPointerToSlice(@TypeOf(any)), any);
}
pub inline fn sliceToArrayPointer(comptime any: anytype) SliceToArrayPointer(@TypeOf(any), any.len) {
    return @as(SliceToArrayPointer(@TypeOf(any), any.len), @ptrCast(any.ptr));
}
/// Extracts types like:
/// Int                 => Int,
/// Enum(Int)           => Int,
/// Struct(Int)         => Int,
/// Union(Enum(Int))    => Int,
/// Optional(Any)       => Any,
/// Array(Any)          => Any,
/// Pointer(Any)        => Any,
pub fn Child(comptime T: type) type {
    switch (@typeInfo(T)) {
        else => |type_info| {
            about.unexpectedTypeTypesError(T, type_info, .{ .Optional, .Array, .Pointer, .Enum, .Int, .Struct, .Union });
        },
        .Array, .Pointer => {
            return Element(T);
        },
        .Int => {
            return T;
        },
        .Enum => |enum_info| {
            return enum_info.tag_type;
        },
        .Struct => |struct_info| {
            if (struct_info.backing_integer) |backing_integer| {
                return backing_integer;
            } else {
                @compileError("'" ++ @typeName(T) ++ "' not a packed struct");
            }
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                return Child(tag_type);
            } else {
                @compileError("'" ++ @typeName(T) ++ "' not a tagged union");
            }
        },
        .Optional => |optional_info| {
            return optional_info.child;
        },
    }
}
pub fn Element(comptime T: type) type {
    switch (@typeInfo(T)) {
        else => |type_info| {
            about.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
        },
        .Array => |array_info| {
            return array_info.child;
        },
        .Pointer => |pointer_info| {
            if (pointer_info.size == .Slice or pointer_info.size == .Many) {
                return pointer_info.child;
            }
            switch (@typeInfo(pointer_info.child)) {
                .Array => |array_info| {
                    return array_info.child;
                },
                else => |child_type_info| {
                    about.unexpectedTypeTypeError(T, child_type_info, .Array);
                },
            }
        },
    }
}
pub fn sentinel(comptime T: type) ?Element(T) {
    switch (@typeInfo(T)) {
        else => |type_info| {
            about.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
        },
        .Array => |array_info| {
            if (array_info.sentinel) |sentinel_ptr| {
                const ret: *align(@alignOf(array_info.child)) const array_info.child = @ptrCast(@alignCast(sentinel_ptr));
                return ret.*;
            }
        },
        .Pointer => |pointer_info| {
            if (pointer_info.sentinel) |sentinel_ptr| {
                const ret: *align(@alignOf(pointer_info.child)) const pointer_info.child = @ptrCast(@alignCast(sentinel_ptr));
                return ret.*;
            }
        },
    }
    return null;
}
fn testEqualBytes(arg1: anytype, arg2: anytype) bool {
    const bytes1: []const u8 = &toBytes(arg1);
    const bytes2: []const u8 = &toBytes(arg2);
    if (bytes1.len != bytes2.len) {
        return false;
    }
    var i: u64 = 0;
    while (i != bytes1.len) : (i += 1) {
        if (bytes1[i] != bytes2[i]) {
            return false;
        }
    }
    return true;
}
pub inline fn sliceToBytes(comptime E: type, values: []const E) []const u8 {
    return @as([*]const u8, @ptrCast(values.ptr))[0 .. @sizeOf(E) * values.len];
}
pub inline fn bytesToSlice(comptime E: type, bytes: []const u8) []const E {
    return @as([*]const E, @ptrCast(bytes.ptr))[0..@divExact(bytes.len, @sizeOf(E))];
}
pub inline fn toBytes(any: anytype) [@sizeOf(@TypeOf(any))]u8 {
    return @as(*const [@sizeOf(@TypeOf(any))]u8, @ptrCast(&any)).*;
}
pub inline fn toBytes2(any: anytype) [@sizeOf(@TypeOf(any))]u8 {
    var dest: [@sizeOf(@TypeOf(any))]u8 = undefined;
    const src: *const [@sizeOf(@TypeOf(any))]u8 = @ptrCast(&any);
    @memcpy(&dest, src);
    return dest;
}
pub fn bytesTo(comptime E: type, comptime bytes: []const u8) E {
    const ret: *const E = @ptrCast(bytes.ptr);
    return ret.*;
}
/// Returns the degree of optional
pub fn optionalLevel(comptime T: type) comptime_int {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Optional and
        type_info.Pointer.size == .Slice)
    {
        return optionalLevel(type_info.Optional.child) + 1;
    }
    return 0;
}
/// Returns the degree of indirection
pub fn sliceLevel(comptime T: type) comptime_int {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Pointer and
        type_info.Pointer.size == .Slice)
    {
        return sliceLevel(type_info.Pointer.child) + 1;
    }
    return 0;
}
pub fn SliceChild(comptime T: type) type {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Pointer and
        type_info.Pointer.size == .Slice)
    {
        return SliceChild(type_info.Pointer.child);
    }
    return T;
}
pub fn DistalChild(comptime T: type) type {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Pointer) {
        return DistalChild(type_info.Pointer.child);
    }
    if (type_info == .Optional) {
        return DistalChild(type_info.Optional.child);
    }
    return T;
}
pub fn Mutable(comptime T: type) type {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Pointer) {
        var ret: builtin.Type = type_info;
        const child_type_info: builtin.Type = @typeInfo(type_info.Pointer.child);
        ret.Pointer.is_const = false;
        if (child_type_info == .Pointer) {
            ret.Pointer.child = Mutable(type_info.Pointer.child);
        }
        return @Type(.{ .Pointer = ret.Pointer });
    }
    return T;
}
pub fn manyToSlice(any: anytype) ManyToSlice(@TypeOf(any)) {
    const T: type = @TypeOf(any);
    const type_info: builtin.Type = @typeInfo(T);
    const len: u64 = switch (@typeInfo(type_info.Pointer.child)) {
        .Pointer => blk: {
            var len: u64 = 0;
            while (@intFromPtr(any[len]) != 0) {
                len += 1;
            }
            break :blk len;
        },
        else => blk: {
            if (type_info == .Array) {
                break :blk type_info.Array.len;
            }
            if (type_info == .Pointer) {
                var len: u64 = 0;
                while (!testEqualBytes(any[len], comptime sentinel(T).?)) {
                    len += 1;
                }
                break :blk len;
            }
            about.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
        },
    };
    return any[0..len :comptime sentinel(T).?];
}
pub fn ManyToSlice(comptime T: type) type {
    var type_info: builtin.Type = @typeInfo(T);
    type_info.Pointer.size = .Slice;
    return @Type(type_info);
}
/// A useful meta type for representing bit fields with uncertain values.
/// Properly rendered by `fmt.any`. E must be an enumeration type.
pub fn EnumBitField(comptime E: type) type {
    debug.assert(isEnum(E));
    return (packed union {
        tag: Tag,
        val: Int,
        const BitField = @This();
        pub const Tag = E;
        pub const Int = @typeInfo(Tag).Enum.tag_type;
        pub inline fn check(bit_field: *const BitField, tag: Tag) bool {
            return bit_field.val & @intFromEnum(tag) == @intFromEnum(tag);
        }
        pub inline fn set(bit_field: *BitField, tag: Tag) void {
            bit_field.val |= @intFromEnum(tag);
        }
        pub inline fn unset(bit_field: *BitField, tag: Tag) void {
            bit_field.val &= ~@intFromEnum(tag);
        }
    });
}
pub fn GenericBitFieldSet(comptime backing_integer: type) type {
    return struct {
        tag: enum { E, F },
        pairs: []const BitFieldPair,
        const BitFieldSet = @This();
        const BitFieldPair = struct {
            name: []const u8,
            value: backing_integer,
        };
        fn sortSets(sets: []const BitFieldSet) []const BitFieldSet {
            var sorted: [sets.len]BitFieldSet = sliceToArrayPointer(sets).*;
            var l_idx: comptime_int = 1;
            while (l_idx < sets.len) : (l_idx +%= 1) {
                const set: BitFieldSet = sorted[l_idx];
                var r_idx: u64 = l_idx -% 1;
                while (r_idx < sets.len and
                    sorted[r_idx].pairs[0].value > set.pairs[0].value) : (r_idx -%= 1)
                {
                    sorted[r_idx +% 1] = sorted[r_idx];
                }
                sorted[r_idx +% 1] = set;
            }
            return &sorted;
        }
        fn sortPairs(pairs: []const BitFieldPair) []const BitFieldPair {
            var sorted: [pairs.len]BitFieldPair = sliceToArrayPointer(pairs).*;
            var l_idx: usize = 1;
            while (l_idx < pairs.len) : (l_idx +%= 1) {
                const x: BitFieldPair = sorted[l_idx];
                var r_idx: usize = l_idx -% 1;
                while (r_idx < pairs.len and
                    sorted[r_idx].value > x.value) : (r_idx -%= 1)
                {
                    sorted[r_idx +% 1] = sorted[r_idx];
                }
                sorted[r_idx +% 1] = x;
            }
            return &sorted;
        }
    };
}
fn sortDecls(comptime Container: type) []const builtin.Type.Declaration {
    const type_info: builtin.Type = @typeInfo(Container);
    const decls: []const builtin.Type.Declaration = resolve(type_info).decls;
    var ret: []const builtin.Type.Declaration = &.{};
    var sorted: [decls.len]builtin.Type.Declaration = sliceToArrayPointer(decls).*;
    var l_idx: usize = 1;
    while (l_idx < sorted.len) : (l_idx +%= 1) {
        var r_idx: usize = l_idx -% 1;
        const x: builtin.Type.Declaration = sorted[l_idx];
        const x_val = if (@TypeOf(@field(Container, x.name)) != type) @field(Container, x.name) else 0;
        while (r_idx < sorted.len) : (r_idx -%= 1) {
            const y: builtin.Type.Declaration = sorted[r_idx];
            const y_val = @field(Container, y.name);
            if (@TypeOf(y_val) == type) {
                break;
            }
            if (y_val <= x_val) {
                break;
            }
            sorted[r_idx +% 1] = y;
        }
        sorted[r_idx +% 1] = x;
    }
    for (sorted) |decl| {
        const decl_val = @field(Container, decl.name);
        if (@TypeOf(decl_val) == type) {
            continue;
        }
        ret = ret ++ [1]builtin.Type.Declaration{decl};
    }
    return ret;
}
pub fn containerDeclsToBitFieldSets(comptime Container: type, comptime backing_integer: type) []const GenericBitFieldSet(backing_integer) {
    @setEvalBranchQuota(~@as(u32, 0));
    const BitFieldSet = GenericBitFieldSet(backing_integer);
    const BitFieldPair = BitFieldSet.BitFieldPair;
    const decls: []const builtin.Type.Declaration = sortDecls(Container);
    var done: [decls.len]bool = .{false} ** decls.len;
    var c_sets: []const BitFieldSet = &.{};
    var c_set: []const BitFieldPair = &.{};
    var x_pairs: []const BitFieldPair = &.{};
    var c_val: backing_integer = 0;
    var l_decl_idx: usize = 0;
    lo: while (l_decl_idx != decls.len) : (l_decl_idx +%= 1) {
        const l_decl: builtin.Type.Declaration = decls[l_decl_idx];
        if (done[l_decl_idx]) {
            continue;
        }
        const l_field = @field(Container, l_decl.name);
        if (@TypeOf(l_field) == type) {
            continue;
        }
        const l_val: backing_integer = l_field;
        if (c_val == 0) {
            c_val = l_val;
        }
        if (l_val == 0) {
            x_pairs = x_pairs ++ [1]BitFieldPair{
                .{ .name = l_decl.name, .value = l_val },
            };
            done[l_decl_idx] = true;
            continue :lo;
        }
        var r_decl_idx: usize = 0;
        while (r_decl_idx != decls.len) : (r_decl_idx +%= 1) {
            if (done[r_decl_idx]) {
                continue;
            }
            const r_decl: builtin.Type.Declaration = decls[r_decl_idx];
            const r_field = @field(Container, r_decl.name);
            if (@TypeOf(r_field) == type) {
                continue;
            }
            const r_val: backing_integer = r_field;
            if (l_decl_idx != r_decl_idx) {
                if (c_val & r_val != 0 or c_val == r_val) {
                    if (x_pairs.len != 0) {
                        c_sets = c_sets ++ [1]BitFieldSet{
                            .{ .tag = .F, .pairs = BitFieldSet.sortPairs(x_pairs) },
                        };
                        x_pairs = &.{};
                    }
                    if (!done[l_decl_idx]) {
                        if (c_set.len == 0) {
                            c_set = c_set ++ [1]BitFieldPair{
                                .{ .name = l_decl.name, .value = l_val },
                            };
                            done[l_decl_idx] = true;
                        }
                    }
                    if (!done[r_decl_idx]) {
                        c_set = c_set ++ [1]BitFieldPair{
                            .{ .name = r_decl.name, .value = r_val },
                        };
                        c_val |= r_val;
                        done[r_decl_idx] = true;
                        r_decl_idx = 0;
                    }
                }
            }
        }
        if (c_set.len != 0) {
            c_sets = c_sets ++ [1]BitFieldSet{
                .{ .tag = .E, .pairs = BitFieldSet.sortPairs(c_set) },
            };
            c_set = &.{};
        }
        if (!done[l_decl_idx]) {
            x_pairs = x_pairs ++ [1]BitFieldPair{
                .{ .name = l_decl.name, .value = l_val },
            };
            done[l_decl_idx] = true;
        }
    }
    if (x_pairs.len != 0) {
        c_sets = c_sets ++ [1]BitFieldSet{
            .{ .tag = .F, .pairs = BitFieldSet.sortPairs(x_pairs) },
        };
        x_pairs = &.{};
    }
    if (c_sets.len == 2 and
        c_sets[0].tag == .E and
        c_sets[1].tag == .F and c_sets[1].pairs.len == 1)
    {
        return &[1]BitFieldSet{.{
            .tag = .E,
            .pairs = c_sets[0].pairs ++ [1]BitFieldPair{c_sets[1].pairs[0]},
        }};
    }
    return BitFieldSet.sortSets(c_sets);
}
pub fn tagList(comptime E: type) []const E {
    const enum_info: builtin.Type.Enum = @typeInfo(E).Enum;
    var ret: [enum_info.fields.len]E = undefined;
    for (enum_info.fields, 0..) |field, index| {
        ret[index] = @as(E, @enumFromInt(field.value));
    }
    return &ret;
}
pub fn TagFromList(comptime names: []const []const u8) type {
    const tag_type: type = @Type(.{ .Int = .{ .bits = realBitSizeOf(names.len), .signedness = .unsigned } });
    var fields: [names.len]builtin.Type.EnumField = undefined;
    for (names, 0..) |name, value| {
        fields[value] = .{ .name = name, .value = value };
    }
    return @Type(.{ .Enum = .{ .tag_type = tag_type, .fields = &fields, .decls = &.{}, .is_exhaustive = true } });
}
pub fn valueList(comptime E: type) []const E {
    const enum_info: builtin.Type.Enum = @typeInfo(E).Enum;
    var ret: [enum_info.fields.len]LeastRealBitSize(enum_info.tag_type) = undefined;
    for (enum_info.fields, 0..) |field, index| {
        ret[index] = field.value;
    }
    return &ret;
}
pub fn tagNameList(comptime E: type, comptime tag_list: []const E) []const []const u8 {
    var ret: [tag_list.len][]const u8 = undefined;
    for (tag_list, 0..) |tag, index| {
        ret[index] = @tagName(tag);
    }
    return &ret;
}
pub fn tagNamesEnum(comptime names: []const []const u8) type {
    var enum_fields: []const builtin.Type.EnumField = &.{};
    for (names, 0..) |name, idx| {
        enum_fields = enum_fields ++ [1]builtin.Type.EnumField{.{
            .name = name,
            .value = idx,
        }};
    }
    return @Type(.{ .Enum = .{
        .fields = enum_fields,
        .tag_type = LeastRealBitSize(enum_fields.len),
        .is_exhaustive = true,
        .decls = &.{},
    } });
}
pub fn GenericStructOfBool(comptime Struct: type) type {
    return struct {
        pub const tag_type: type = @typeInfo(Struct).Struct.backing_integer.?;
        pub const Tag = blk: {
            const struct_info: builtin.Type.Struct = @typeInfo(Struct).Struct;
            var enum_fields: []const builtin.Type.EnumField = &.{};
            for (struct_info.fields) |field| {
                enum_fields = enum_fields ++ [1]builtin.Type.EnumField{.{
                    .name = field.name,
                    .value = 1 << @bitOffsetOf(Struct, field.name),
                }};
            }
            break :blk @Type(.{ .Enum = .{
                .tag_type = struct_info.backing_integer.?,
                .decls = &.{},
                .fields = enum_fields,
                .is_exhaustive = false,
            } });
        };
        pub fn detail(tags: []const Tag) Struct {
            var int: tag_type = 0;
            for (tags) |tag| {
                int |= @intFromEnum(tag);
            }
            return @as(Struct, @bitCast(int));
        }
        pub const tag_list: []const Tag = tagList(Tag);
        pub fn countTrue(bit_field: Struct) u64 {
            var ret: u64 = 0;
            inline for (@typeInfo(Struct).Struct.fields) |field| {
                ret +%= @intFromBool(@field(bit_field, field.name));
            }
            return ret;
        }
        pub fn has(bit_field: Struct, tag: Tag) bool {
            return @as(tag_type, @bitCast(bit_field)) & @intFromEnum(tag) != 0;
        }
    };
}
pub fn TagUnion(comptime Union: type, comptime tag_type: type) type {
    var union_info: builtin.Type = union_info_base;
    union_info.fields = @typeInfo(Union).Union.fields;
    union_info.tag_type = tag_type;
    return @Type(.{ .Union = union_info });
}
pub fn tagUnion(comptime Union: type, comptime tag_type: type, value: Union, tag: tag_type) TagUnion(Union, tag_type) {
    switch (tag) {
        inline else => |tag_tag| return @unionInit(
            TagUnion(Union, tag_type),
            @tagName(tag_tag),
            @field(value, @tagName(tag_tag)),
        ),
    }
}
pub fn TaggedUnion(comptime Union: type) type {
    var tag_type_fields: []const builtin.Type.EnumField = empty;
    for (@typeInfo(Union).Union.fields, 0..) |field, value| {
        tag_type_fields = tag_type_fields ++ [1]builtin.Type.EnumField{.{
            .name = field.name,
            .value = value,
        }};
    }
    return @Type(.{ .Enum = .{ .fields = tag_type_fields } });
}
pub fn Field(comptime T: type, comptime field_name: []const u8) type {
    return @TypeOf(@field(@as(T, undefined), field_name));
}
pub fn unionFields(comptime Union: type) []const builtin.Type.UnionField {
    return @typeInfo(Union).Union.fields;
}
pub fn enumFields(comptime Enum: type) []const builtin.Type.EnumField {
    return @typeInfo(Enum).Enum.fields;
}
pub fn structFields(comptime Struct: type) []const builtin.Type.StructField {
    return @typeInfo(Struct).Struct.fields;
}
pub fn FieldN(comptime T: type, comptime field_index: usize) type {
    switch (@typeInfo(T)) {
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, decl_types);
        },
        .Struct => |struct_info| {
            return struct_info.fields[field_index].type;
        },
        .Union => |union_info| {
            return union_info.fields[field_index].type;
        },
        .Enum => |enum_info| {
            return enum_info.fields[field_index].type;
        },
    }
}
pub fn fnParams(comptime function: anytype) []const builtin.Type.Fn.Param {
    return @typeInfo(@TypeOf(function)).Fn.params;
}
pub fn FnParam0(comptime function: anytype) type {
    return fnParams(function)[0].type.?;
}
pub fn FnParam1(comptime function: anytype) type {
    return fnParams(function)[1].type.?;
}
pub fn FnParam2(comptime function: anytype) type {
    return fnParams(function)[2].type.?;
}
pub fn FnParam3(comptime function: anytype) type {
    return fnParams(function)[3].type.?;
}
pub fn FnParamN(comptime function: anytype, comptime index: u64) type {
    return fnParams(function)[index].type.?;
}
pub fn Return(comptime function: anytype) type {
    if (@TypeOf(function) == type) {
        return @typeInfo(function).Fn.return_type.?;
    } else {
        return @typeInfo(@TypeOf(function)).Fn.return_type.?;
    }
}
pub fn GenericReturn(comptime function: anytype) ?type {
    if (@TypeOf(function) == type) {
        return @typeInfo(function).Fn.return_type;
    } else {
        return @typeInfo(@TypeOf(function)).Fn.return_type;
    }
}
/// Return the error part of a function error union return type, etc.
pub fn ReturnErrorSet(comptime any_function: anytype) type {
    const T: type = @TypeOf(any_function);
    switch (@typeInfo(T)) {
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{ .Fn, .Struct });
        },
        .Fn => {
            const type_info: builtin.Type = @typeInfo(@typeInfo(@TypeOf(any_function)).Fn.return_type.?);
            if (type_info == .ErrorUnion) {
                return type_info.ErrorUnion.error_set;
            } else {
                return error{};
            }
        },
        .Struct => {
            var errors: type = error{};
            for (any_function) |arg| {
                errors = errors || ReturnErrorSet(arg);
            }
            return errors;
        },
        .Type => {
            switch (@typeInfo(any_function)) {
                .ErrorUnion => {
                    return @typeInfo(any_function).ErrorUnion.error_set;
                },
                .ErrorSet => {
                    return any_function;
                },
                else => {
                    return error{};
                },
            }
        },
        .ErrorSet => {
            return T;
        },
    }
}
/// Return the value part of a function error union return type.
pub fn ReturnPayload(comptime any_function: anytype) type {
    const T: type = @TypeOf(any_function);
    switch (@typeInfo(T)) {
        .Fn => {
            return @typeInfo(@typeInfo(@TypeOf(any_function)).Fn.return_type.?).ErrorUnion.payload;
        },
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{.Fn});
        },
    }
}
/// Attempts to replicate the structure of an error union. Experimental.
pub fn ErrorUnion(comptime any_function: anytype) type {
    const return_type_info: builtin.Type =
        @typeInfo(@typeInfo(@TypeOf(any_function)).Fn.return_type.?);
    switch (return_type_info) {
        .ErrorUnion => |error_set_info| {
            return union(enum) {
                err: Error,
                val: Value,
                const Error: type = error_set_info.error_set;
                const Value: type = error_set_info.payload;
                fn unwrap(u: @This()) Error!Value {
                    switch (u) {
                        .err => |err| return err,
                        .val => |val| return val,
                    }
                }
            };
        },
        else => {
            return @Type(return_type_info);
        },
    }
}
pub inline fn mergeExternalErrorPolicies(
    comptime E: type,
    comptime any: anytype,
) builtin.ExternalError(E) {
    var throw: []const E = &.{};
    var abort: []const E = &.{};
    inline for (@typeInfo(@TypeOf(any)).Struct.fields) |field| {
        throw = throw ++ @field(field.name, any).throw;
        abort = abort ++ @field(field.name, any).abort;
    }
    return .{ .throw = throw, .abort = abort };
}
/// Return the length of the longest field name in a container type
pub fn maxNameLength(comptime T: type) u64 {
    var len: u64 = 0;
    switch (@typeInfo(T)) {
        .ErrorSet => |error_set_info| {
            if (error_set_info) |error_set| {
                for (error_set) |e| {
                    len = @max(len, e.name.len);
                }
            }
        },
        .Struct => |struct_info| {
            for (struct_info.fields) |field| {
                len = @max(len, field.name.len);
            }
        },
        .Enum => |enum_info| {
            for (enum_info.fields) |field| {
                len = @max(len, field.name.len);
            }
        },
        .Union => |union_info| {
            for (union_info.fields) |field| {
                len = @max(len, field.name.len);
            }
        },
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{ .ErrorSet, .Struct, .Enum, .Union });
        },
    }
    return len;
}
/// Return whether values of this type can be compared for equality.
pub fn isTriviallyComparable(comptime T: type) bool {
    const type_info: builtin.Type = @typeInfo(T);
    switch (type_info) {
        .Type => return true,
        .Void => return true,
        .Bool => return true,
        .Int => return true,
        .Float => return true,
        .ComptimeFloat => return true,
        .ComptimeInt => return true,
        .Null => return true,
        .ErrorSet => return true,
        .Enum => return true,
        .Opaque => return true,
        .AnyFrame => return true,
        .EnumLiteral => return true,
        .Fn => return false,
        .NoReturn => return false,
        .Array => return false,
        .Struct => return false,
        .ErrorUnion => return false,
        .Union => return false,
        .Frame => return false,
        .Vector => return false,
        .Pointer => |pointer_info| return @typeInfo(pointer_info.child) != .Fn and pointer_info.size != .Slice,
        .Optional => |optional_info| return @typeInfo(optional_info.child) == .Pointer and
            @typeInfo(optional_info.child).Pointer.size != .Slice and
            @typeInfo(optional_info.child).Pointer.size != .C,
        .Undefined => unreachable,
    }
}
fn fieldIdInternalNoOp(comptime T: type, id: u64) u64 {
    const type_info: builtin.Type = @typeInfo(T);
    var ret: u64 = id;
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            ret = fieldIdInternalNoOp(field.type, ret);
        }
    }
    if (type_info == .Enum) {
        inline for (type_info.Enum.fields) |_| {
            ret += 1;
        }
    }
    return ret;
}
pub fn fieldIdNoOp(comptime T: type) usize {
    const type_info: builtin.Type = @typeInfo(T);
    var ret: usize = 0;
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            ret = fieldIdInternalNoOp(field.type, ret);
        }
    }
    if (type_info == .Enum) {
        inline for (type_info.Enum.fields) |_| {
            ret += 1;
        }
    }
    return ret;
}
fn fieldIdInternal(comptime T: type, t: T, id: usize) usize {
    const type_info: builtin.Type = @typeInfo(T);
    var ret: u64 = id;
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            if (static.testEqualString(field.name, @tagName(t))) {
                return fieldIdInternal(field.type, @field(t, field.name), ret);
            } else {
                ret = fieldIdInternalNoOp(field.type, ret);
            }
        }
    }
    if (type_info == .Enum) {
        inline for (type_info.Enum.fields) |field| {
            if (static.testEqualString(field.name, @tagName(t))) {
                return ret;
            }
            ret += 1;
        }
    }
    return ret;
}
pub fn fieldId(comptime T: type, t: T) usize {
    const type_info: builtin.Type = @typeInfo(T);
    var ret: usize = 0;
    if (type_info == .Union) {
        inline for (type_info.Union.fields) |field| {
            if (static.testEqualString(field.name, @tagName(t))) {
                ret = fieldIdInternal(field.type, @field(t, field.name), ret);
                break;
            } else {
                ret = fieldIdInternalNoOp(field.type, ret);
            }
        }
    }
    if (type_info == .Enum) {
        inline for (type_info.Enum.fields) |field| {
            if (static.testEqualString(field.name, @tagName(t))) {
                break;
            }
            ret += 1;
        }
    }
    return ret;
}
pub inline fn analysisBegin(comptime name: []const u8) void {
    asm volatile ("# LLVM-MCA-BEGIN " ++ name);
}
pub inline fn analysisEnd(comptime name: []const u8) void {
    asm volatile ("# LLVM-MCA-END " ++ name);
}
pub const Initializer = struct {
    dest_off: u64,
    src_addr: u64,
    src_len: u64,
};
pub fn initializers(comptime T: type, comptime any: T) [@typeInfo(@TypeOf(any)).Struct.fields.len]Initializer {
    const fields: []const builtin.Type.StructField = @typeInfo(@TypeOf(any)).Struct.fields;
    var inits: [fields.len]Initializer = undefined;
    inline for (fields, 0..) |field, idx| {
        const field_type: type = Field(T, field.name);
        inits[idx] = .{
            .dest_off = @offsetOf(T, field.name),
            .src_addr = @intFromPtr(&@as(field_type, @field(any, field.name))),
            .src_len = @sizeOf(field_type),
        };
    }
    return inits;
}
pub fn initialize(comptime T: type, inits: []const Initializer) T {
    var ret: T = undefined;
    for (inits) |init| {
        mach.memcpy(
            @as([*]u8, @ptrFromInt(@intFromPtr(&ret) +% init.dest_off)),
            @as([*]const u8, @ptrFromInt(init.src_addr)),
            init.src_len,
        );
    }
    return ret;
}
pub fn UniformData(comptime bits: u16) type {
    const word_size: u16 = @bitSizeOf(usize);
    const real_bits: u16 = alignBitSizeAbove(bits);
    switch (bits) {
        0...word_size => {
            return @Type(.{ .Int = .{ .bits = real_bits, .signedness = .unsigned } });
        },
        else => {
            return [(bits / word_size) + @intFromBool(@rem(bits, word_size) != 0)]usize;
        },
    }
}
pub fn uniformData(any: anytype) UniformData(@bitSizeOf(@TypeOf(any))) {
    const T: type = @TypeOf(any);
    const U: type = UniformData(@bitSizeOf(T));
    return @as(*const U, @ptrCast(&any)).*;
}
pub fn genericCast(comptime T: type, comptime value: T) Generic {
    return .{ .type = T, .value = &value };
}
pub fn generic(comptime value: anytype) Generic {
    return genericCast(@TypeOf(value), value);
}
pub fn genericSlice(comptime transform: anytype, comptime values: anytype) []const Generic {
    var ret: []const Generic = empty;
    for (values) |value| {
        ret = concat(Generic, ret, transform(value));
    }
    return ret;
}
pub fn refAllDeclsInternal(comptime T: type, comptime types: []const type, comptime black_list: ?[]const []const u8) void {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime {
        if (@typeInfo(T) == .Struct or
            @typeInfo(T) == .Union or
            @typeInfo(T) == .Enum or
            @typeInfo(T) == .Opaque)
        {
            lo: for (resolve(@typeInfo(T)).decls) |decl| {
                if (black_list) |names| {
                    for (names) |name| {
                        if (mem.testEqualMemory([]const u8, decl.name, name)) {
                            continue :lo;
                        }
                    }
                }
                if (@hasDecl(T, decl.name)) {
                    if (@TypeOf(@field(T, decl.name)) == type) {
                        for (types) |U| {
                            if (@field(T, decl.name) == U) {
                                continue :lo;
                            }
                        }
                        refAllDeclsInternal(@field(T, decl.name), types ++ [1]type{@field(T, decl.name)}, black_list);
                    }
                }
            }
        }
    }
}
pub fn refAllDecls(comptime T: type, comptime black_list: ?[]const []const u8) void {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime {
        var types: []const type = &.{};
        if (@typeInfo(T) == .Struct or
            @typeInfo(T) == .Union or
            @typeInfo(T) == .Enum or
            @typeInfo(T) == .Opaque)
        {
            lo: for (resolve(@typeInfo(T)).decls) |decl| {
                if (black_list) |names| {
                    for (names) |name| {
                        if (mem.testEqualMemory([]const u8, decl.name, name)) {
                            continue :lo;
                        }
                    }
                }
                if (@hasDecl(T, decl.name)) {
                    if (@TypeOf(@field(T, decl.name)) == type) {
                        refAllDeclsInternal(@field(T, decl.name), types ++ [1]type{@field(T, decl.name)}, black_list);
                    }
                }
            }
        }
    }
}
const about = opaque {
    fn typeTypeName(comptime any: builtin.TypeId) []const u8 {
        switch (any) {
            .Type => return "type",
            .Void => return "void",
            .Bool => return "bool",
            .NoReturn => return "noreturn",
            .Int => return "integer",
            .Float => return "float",
            .Pointer => return "pointer",
            .Array => return "array",
            .Struct => return "struct",
            .ComptimeFloat => return "comptime_float",
            .ComptimeInt => return "comptime_int",
            .Undefined => return "undefined",
            .Null => return "null",
            .Optional => return "optional",
            .ErrorUnion => return "error union",
            .ErrorSet => return "error set",
            .Enum => return "enum",
            .Union => return "union",
            .Fn => return "function",
            .Opaque => return "opaque",
            .Frame => return "frame",
            .AnyFrame => return "anyframe",
            .Vector => return "vector",
            .EnumLiteral => return "(enum literal)",
        }
    }
    fn genericTypeList(comptime kind: builtin.Type, any: anytype) []const u8 {
        var buf: []const u8 = empty;
        var last: u64 = 0;
        var i: u64 = 0;
        while (i < any.len) : (i += 1) {
            last = buf.len;
            switch (kind) {
                .type => {
                    buf = buf ++ ", " ++ @typeName(any[i]);
                },
                .type_type => {
                    buf = buf ++ ", " ++ typeTypeName(any[i]);
                },
            }
        }
        if (i > 2) {
            return buf[2 .. last + 1] ++ " or " ++ buf[last + 2 ..];
        } else if (i == 2) {
            return buf[2..last] ++ " or " ++ buf[last + 2 ..];
        } else if (i == 1) {
            return buf[2..];
        } else {
            return "(none)";
        }
    }
    fn typeList(comptime any: []const type) []const u8 {
        return genericTypeList(.type, any);
    }
    fn typeTypeList(comptime any: anytype) []const u8 {
        return genericTypeList(.type_type, any);
    }
    fn fieldList(comptime type_info: builtin.Type) []const u8 {
        var buf: []const u8 = empty;
        const container_info: builtin.Type = switch (type_info) {
            .Enum => |enum_info| enum_info,
            .Struct => |struct_info| struct_info,
            .Union => |union_info| union_info,
            else => {
                unexpectedTypeTypesError(type_info, &[_]builtin.TypeId{ .Enum, .Struct, .Union });
            },
        };
        var last: u64 = 0;
        var i: u64 = 0;
        inline for (container_info.fields) |field| {
            last = buf.len;
            buf = buf ++ ", '" ++ field.name ++ "'";
        }
        return terminateAndList(buf, i, last);
    }
    fn terminateAndList(comptime buf: []const u8, n: u64, len: u64) []const u8 {
        if (buf.len > 2) {
            return if (n >= 3 and n < 150)
                buf[2 .. len + 1] ++ " and " ++ buf[len + 2 ..]
            else if (n > 1)
                buf[2..len] ++ " and " ++ buf[len + 2 ..]
            else
                buf[2..];
        } else {
            return buf;
        }
    }
    fn declList(comptime buf: []const u8, comptime type_info: builtin.Type) []const u8 {
        var pub_str: []const u8 = "";
        var pub_num: u64 = 0;
        const container_info = switch (type_info) {
            .Enum => |enum_info| enum_info,
            .Struct => |struct_info| struct_info,
            .Union => |union_info| union_info,
            else => unexpectedTypeTypesError(type_info, container_types),
        };
        for (container_info.decls) |decl| {
            pub_num += 1;
            pub_str = pub_str ++ ", '" ++ decl.name;
        }
        if (pub_num == 1) {
            return buf[0 .. buf.len - 3] ++ ": " ++ pub_str[2..pub_str.len] ++ "'";
        } else {
            return buf ++ pub_str[2..pub_str.len] ++ "'";
        }
    }
    fn unexpectedTypesError(comptime T: type, comptime any: []const type) noreturn {
        @compileError("expected any " ++ typeList(any) ++ ", found " ++ @typeName(T));
    }
    fn unexpectedTypeError(comptime T: type, comptime any: type) noreturn {
        @compileError("expected " ++ @typeName(any) ++ ", found " ++ @typeName(T));
    }
    fn unexpectedTypeTypesError(comptime T: type, comptime type_info: builtin.Type, comptime any: anytype) noreturn {
        @compileError("expected any " ++ typeTypeList(any) ++ ", found " ++ typeTypeName(type_info) ++ " '" ++ @typeName(T) ++ "'");
    }
    fn unexpectedTypeTypeError(comptime T: type, comptime type_info: builtin.Type, comptime any: builtin.TypeId) noreturn {
        @compileError("expected " ++ typeTypeName(any) ++ ", found " ++ typeTypeName(type_info) ++ " '" ++ @typeName(T) ++ "'");
    }
    fn fieldError(comptime T: type, comptime field: []const u8) noreturn {
        @compileError("no member named '" ++ field ++ "' in struct '" ++
            @typeName(T) ++ "' with fields: " ++ fieldList(@typeInfo(T)));
    }
    fn declError(comptime T: type, comptime identifier: []const u8) noreturn {
        @compileError(declList("undeclared identifier '" ++ identifier ++
            "' in container '" ++ @typeName(T) ++ "' with declarations: ", declList(@typeInfo(T))));
    }
    fn enumFieldValueNotContinuous(comptime T: type, value: anytype, field_name: []const u8, field_value: anytype) noreturn {
        @compileError("field '" ++ field_name ++ "' of index tag type '" ++ @typeName(T) ++
            "' is not continuous: expected value " ++ fmt.old.ci(value) ++ ", found value " ++ fmt.old.ci(field_value));
    }
};
const static = opaque {
    fn testEqualString(arg1: []const u8, arg2: []const u8) bool {
        if (arg1.len != arg2.len) {
            return false;
        }
        var idx: usize = 0;
        while (idx != arg1.len) : (idx += 1) {
            if (arg1[idx] != arg2[idx]) {
                return false;
            }
        }
        return true;
    }
};
pub const Bits64 = @Vector(64, bool);
pub const Bits32 = @Vector(32, bool);
pub const Bits16 = @Vector(16, bool);
pub const Bits8 = @Vector(8, bool);
