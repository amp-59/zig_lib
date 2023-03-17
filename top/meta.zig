const builtin = @import("./builtin.zig");

pub const Empty = struct {};
pub const empty = &.{};
pub const default = .{};
pub const Generic = struct { type: type, value: *const anyopaque };

pub const number_types: []const builtin.TypeId = integer_types ++ float_types;
pub const integer_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Int, .ComptimeInt };
pub const float_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Float, .ComptimeFloat };
pub const enum_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Int, .ComptimeInt, .Enum, .EnumLiteral };
pub const tag_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Type, .ErrorUnion, .Enum, .EnumLiteral };
pub const fn_types: []const builtin.TypeId = &[_]builtin.TypeId{.Fn};
pub const data_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Union };
pub const decl_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Union, .Enum };
pub const container_types: []const builtin.TypeId = &[_]builtin.TypeId{ .Struct, .Enum, .Union, .Opaque };

fn isTypeType(comptime T: type, comptime type_types: []const builtin.TypeId) bool {
    inline for (type_types) |type_type| {
        if (@typeInfo(T) == type_type) {
            return true;
        }
    }
    return false;
}
pub fn isNumber(comptime T: type) bool {
    return isTypeType(T, number_types);
}
pub fn isInteger(comptime T: type) bool {
    return isTypeType(T, integer_types);
}
pub fn isFloat(comptime T: type) bool {
    return isTypeType(T, float_types);
}
pub fn isEnum(comptime T: type) bool {
    return isTypeType(T, enum_types);
}
pub fn isTag(comptime T: type) bool {
    return isTypeType(T, tag_types);
}
pub fn isFunction(comptime T: type) bool {
    return isTypeType(T, fn_types);
}
pub fn isContainer(comptime T: type) bool {
    return isTypeType(T, container_types);
}
pub fn assertType(comptime T: type, comptime tag: builtin.TypeId) void {
    if (builtin.comptime_assertions) {
        const type_info: builtin.Type = @typeInfo(T);
        if (type_info != tag) {
            debug.unexpectedTypeTypeError(T, type_info, tag);
        }
    }
}
pub fn assertHasDecl(comptime T: type, decl_name: []const u8) void {
    if (builtin.comptime_assertions) {
        if (!@hasDecl(T, decl_name)) {
            debug.declError(T, decl_name);
        }
    }
}
pub fn assertHasField(comptime T: type, field_name: []const u8) void {
    if (builtin.comptime_assertions) {
        if (!@hasField(T, field_name)) {
            debug.fieldError(T, field_name);
        }
    }
}
/// If the input is a union return the active field else return the input.
pub fn resolve(comptime any: anytype) if (@typeInfo(@TypeOf(any)) == .Union)
    @TypeOf(comptime @field(any, @tagName(any)))
else
    @TypeOf(any) {
    if (@typeInfo(@TypeOf(any)) == .Union) {
        return @field(any, @tagName(any));
    } else {
        return any;
    }
}
pub fn slice(comptime T: type, values: anytype) []const T {
    return &@as([values.len]T, values);
}
/// A parceled value can be concatenated using `++`
pub fn parcel(comptime T: type, arg: T) []const T {
    return &[1]T{arg};
}
pub fn concat(comptime T: type, comptime arg1: []const T, comptime arg2: T) []const T {
    return arg1 ++ comptime parcel(T, arg2);
}
pub fn concatEqu(comptime T: type, arg1: *[]const T, arg2: T) void {
    arg1.* = concat(T, arg1.*, arg2);
}
pub fn concatEquPtr(comptime T: type, arg1: *[]const T, arg2: anytype) void {
    arg1.* = concat(T, arg1.*, @ptrCast(*const T, @alignCast(@alignOf(T), arg2)).*);
}
/// A wrapped value can be unwrapped using `try`
pub fn wrap(any: anytype) blk: {
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
            debug.unexpectedTypeTypesError(type_info, T, .{ .Int, .Struct, .Opaque, .Enum });
        },
    }
}

/// Return a simple struct field
pub fn structField(comptime T: type, comptime field_name: []const u8, comptime default_value_opt: ?T) builtin.Type.StructField {
    if (default_value_opt) |default_value| {
        return .{
            .name = field_name,
            .type = T,
            .default_value = blk: {
                if (@TypeOf(default_value) == ?*const anyopaque) {
                    break :blk @ptrCast(*const anyopaque, &default_value);
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
/// Assist creation of struct types
pub fn structInfo(
    comptime layout: builtin.Type.ContainerLayout,
    comptime fields: []const builtin.Type.StructField,
) builtin.Type {
    return .{ .Struct = .{ .layout = layout, .fields = fields, .decls = empty, .is_tuple = false } };
}
/// Assist creation of tuple types
pub fn tupleInfo(comptime fields: []const builtin.Type.StructField) builtin.Type {
    return .{ .Struct = .{ .layout = .Auto, .fields = fields, .decls = empty, .is_tuple = true } };
}
pub fn defaultValue(comptime struct_field: builtin.Type.StructField) ?struct_field.type {
    if (struct_field.default_value) |default_value_ptr| {
        return @ptrCast(*const struct_field.type, @alignCast(@alignOf(struct_field.type), default_value_ptr)).*;
    }
    return null;
}
pub inline fn Tuple(comptime T: type) type {
    return @Type(tupleInfo(@typeInfo(T).Struct.fields));
}
pub inline fn Args(comptime Fn: type) type {
    var fields: []const builtin.Type.StructField = empty;
    inline for (@typeInfo(Fn).Fn.params, 0..) |arg, i| {
        fields = concat(builtin.Type.StructField, fields, structField(arg.type.?, builtin.fmt.ci(i), null));
    }
    return @Type(tupleInfo(fields));
}
pub inline fn tuple(any: anytype) Tuple(@TypeOf(any)) {
    return any;
}

/// Align `count` below to bitSizeOf smallest real word bit count
pub fn alignBW(comptime count: comptime_int) u16 {
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
pub fn alignAW(comptime count: comptime_int) u16 {
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
const Extrema = struct { min: comptime_int, max: comptime_int };
/// Find the maximum and minimum arithmetical values for an integer type.
pub fn extrema(comptime I: type) Extrema {
    const U = @Type(.{ .Int = .{
        .signedness = .unsigned,
        .bits = @bitSizeOf(I),
    } });
    const umax: U = ~@as(U, 0);
    if (@typeInfo(I).Int.signedness == .unsigned) {
        return .{ .min = 0, .max = umax };
    } else {
        const imax: U = umax >> 1;
        return .{
            .min = @bitCast(I, ~imax),
            .max = @bitCast(I, imax),
        };
    }
}
/// Return the smallest real bitSizeOf the integer type required to store the
/// comptime integer.
pub fn alignCX(comptime value: comptime_int) u16 { // Needs a better name
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
        const xi8: Extrema = extrema(i8);
        const xi16: Extrema = extrema(i16);
        const xi32: Extrema = extrema(i32);
        const xi64: Extrema = extrema(i64);
        const xi128: Extrema = extrema(i128);
        const xi256: Extrema = extrema(i256);
        const xi512: Extrema = extrema(i512);
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
pub fn alignSizeBW(comptime T: type) u16 { // Needs a better name
    const bits: u16 = @bitSizeOf(T);
    return alignBW(bits);
}
pub fn alignSizeAW(comptime T: type) u16 { // Needs a better name
    const bits: u16 = @bitSizeOf(T);
    return alignAW(bits);
}
pub fn AlignSizeAW(comptime T: type) type { // Needs a better name
    var int_type_info: builtin.Type.Int = @typeInfo(T).Int;
    int_type_info.bits = alignAW(int_type_info.bits);
    return @Type(.{ .Int = int_type_info });
}
pub fn AlignSizeBW(comptime T: type) type { // Needs a better name
    var int_type_info: builtin.Type.Int = @typeInfo(T).Int;
    int_type_info.bits = alignBW(int_type_info.bits);
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
            while (value < @truncate(U, value)) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) + 1,
                    .signedness = .signed,
                } });
            }
            return U;
        } else {
            var U: type = u1;
            while (value > @truncate(U, value)) {
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
    if (@sizeOf(T) == 0) {
        if (value < 0) {
            var U: type = i8;
            while (value < @truncate(U, value)) {
                U = @Type(.{ .Int = .{
                    .bits = @bitSizeOf(U) << 1,
                    .signedness = .signed,
                } });
            }
            return U;
        } else {
            var U: type = u8;
            while (value > @truncate(U, value)) {
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
            .bits = alignAW(@bitSizeOf(T) - @clz(value)),
            .signedness = .unsigned,
        },
    });
}
/// This is for miscellaneous special cases that normally Zig refuses to cast.
/// The user of this function gets what they ask for.
pub fn bitCast(comptime T: type, any: anytype) T {
    const S: type = @TypeOf(any);
    const s_type_info: builtin.Type = @typeInfo(S);
    const t_type_info: builtin.Type = @typeInfo(T);
    if (s_type_info == .Enum) {
        if (t_type_info == .Struct) {
            const i: t_type_info.Struct.backing_integer.? = @enumToInt(any);
            return @bitCast(T, i);
        }
    }
}
pub fn leastBitCast(any: anytype) @Type(.{ .Int = .{
    .bits = @bitSizeOf(@TypeOf(any)),
    .signedness = .unsigned,
} }) {
    const T: type = @TypeOf(any);
    const U: type = @Type(.{ .Int = .{
        .bits = @bitSizeOf(T),
        .signedness = .unsigned,
    } });
    return @bitCast(U, any);
}
pub fn leastRealBitCast(any: anytype) @Type(.{ .Int = .{
    .bits = alignAW(@bitSizeOf(@TypeOf(any))),
    .signedness = .unsigned,
} }) {
    return leastBitCast(any);
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
pub fn arrayPointerToSlice(any: anytype) ArrayPointerToSlice(@TypeOf(any)) {
    return @as(ArrayPointerToSlice(@TypeOf(any)), any);
}
pub fn sliceToArrayPointer(comptime any: anytype) SliceToArrayPointer(@TypeOf(any), any.len) {
    return @ptrCast(SliceToArrayPointer(@TypeOf(any), any.len), any.ptr);
}
pub fn Child(comptime T: type) type {
    switch (@typeInfo(T)) {
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{ .Optional, .Array, .Pointer, .Enum, .Struct, .Union });
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
        .Array => |array_info| {
            return array_info.child;
        },
        .Pointer => |pointer_info| {
            if (pointer_info.size == .Slice or
                pointer_info.size == .Many)
            {
                return pointer_info.child;
            }
            switch (@typeInfo(pointer_info.child)) {
                .Array => |array_info| {
                    return array_info.child;
                },
                else => {
                    return pointer_info.child;
                },
            }
        },
    }
}
pub fn Element(comptime T: type) type {
    switch (@typeInfo(T)) {
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
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
                    debug.unexpectedTypeTypeError(T, child_type_info, .Array);
                },
            }
        },
    }
}
pub fn sentinel(comptime T: type) ?Element(T) {
    switch (@typeInfo(T)) {
        else => |type_info| {
            debug.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
        },
        .Array => |array_info| {
            if (array_info.sentinel) |sentinel_ptr| {
                return @ptrCast(*const array_info.child, @alignCast(@alignOf(array_info.child), sentinel_ptr)).*;
            }
        },
        .Pointer => |pointer_info| {
            if (pointer_info.sentinel) |sentinel_ptr| {
                const ret: pointer_info.child = @ptrCast(*const pointer_info.child, @alignCast(@alignOf(pointer_info.child), sentinel_ptr)).*;
                return ret;
            }
        },
    }
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

pub fn sliceToBytes(comptime E: type, values: []const E) []const u8 {
    return @ptrCast([*]const u8, values.ptr)[0 .. @sizeOf(E) * values.len];
}
pub fn bytesToSlice(comptime E: type, bytes: []const u8) []const E {
    return @ptrCast([*]const E, @alignCast(@alignOf(E), bytes.ptr))[0..@divExact(bytes.len, @sizeOf(E))];
}
pub fn toBytes(any: anytype) [@sizeOf(@TypeOf(any))]u8 {
    return @ptrCast(*const [@sizeOf(@TypeOf(any))]u8, &any).*;
}
pub fn bytesTo(comptime E: type, comptime bytes: []const u8) E {
    return @ptrCast(*const E, @alignCast(@alignOf(E), bytes.ptr)).*;
}
pub fn sliceLevel(comptime T: type) comptime_int {
    if (@typeInfo(T) == .Pointer and
        @typeInfo(T).Pointer.size == .Slice)
    {
        return sliceLevel(@typeInfo(T).Pointer.child) + 1;
    }
    return 0;
}
pub fn sliceChild(comptime T: type) type {
    if (@typeInfo(T) == .Pointer and
        @typeInfo(T).Pointer.size == .Slice)
    {
        return sliceChild(@typeInfo(T).Pointer.child);
    }
    return T;
}
pub fn sliceProperty(comptime T: type) struct { comptime_int, type } {
    return .{ sliceLevel(T), sliceChild(T) };
}
pub fn manyToSlice(any: anytype) ManyToSlice(@TypeOf(any)) {
    const T: type = @TypeOf(any);
    const type_info: builtin.Type = @typeInfo(T);
    const len: u64 = switch (@typeInfo(type_info.Pointer.child)) {
        .Pointer => blk: {
            var len: u64 = 0;
            while (@ptrToInt(any[len]) != 0) {
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
            debug.unexpectedTypeTypesError(T, type_info, .{ .Array, .Pointer });
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
    builtin.assert(isEnum(E));
    return (packed union {
        tag: Tag,
        val: Int,
        const BitField = @This();
        pub const Tag = E;
        pub const Int = @typeInfo(Tag).Enum.tag_type;
        pub fn value(tag: Tag) Int {
            return @enumToInt(tag);
        }
        pub fn check(bit_field: *const BitField, tag: Tag) bool {
            return bit_field.val & @enumToInt(tag) == @enumToInt(tag);
        }
        pub fn set(bit_field: *BitField, tag: Tag) void {
            bit_field.val |= @enumToInt(tag);
        }
        pub fn unset(bit_field: *BitField, tag: Tag) void {
            bit_field.val &= ~@enumToInt(tag);
        }
    });
}
pub fn tagList(comptime E: type) []const E {
    const enum_info: builtin.Type.Enum = @typeInfo(E).Enum;
    var ret: [enum_info.fields.len]E = undefined;
    for (enum_info.fields, 0..) |field, index| {
        ret[index] = @intToEnum(E, field.value);
    }
    return &ret;
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
pub fn TaggedUnion(comptime Union: type) type {
    var tag_type_fields: []const builtin.Type.EnumField = empty;
    var value: comptime_int = 0;
    for (@typeInfo(Union).Union.fields) |field| {
        tag_type_fields = tag_type_fields ++ [1]builtin.Type.EnumField{.{
            .name = field.name,
            .value = value,
        }};
        value +%= 1;
    }
    return @Type(.{ .Enum = .{ .fields = tag_type_fields } });
}

pub fn unionFields(comptime Union: type) []const builtin.UnionField {
    return @typeInfo(Union).Union.fields;
}
pub fn enumFields(comptime Enum: type) []const builtin.EnumField {
    return @typeInfo(Enum).Enum.fields;
}
pub fn structFields(comptime Struct: type) []const builtin.Type.StructField {
    return @typeInfo(Struct).Struct.fields;
}
pub fn Field(comptime T: type, comptime field_name: []const u8) type {
    return @TypeOf(@field(@as(T, undefined), field_name));
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
            return @typeInfo(@typeInfo(@TypeOf(any_function)).Fn.return_type.?).ErrorUnion.error_set;
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

pub fn UniformData(comptime bits: u16) type {
    const word_size: u16 = @bitSizeOf(usize);
    const real_bits: u16 = alignAW(bits);
    switch (bits) {
        0...word_size => {
            return @Type(.{ .Int = .{ .bits = real_bits, .signedness = .unsigned } });
        },
        else => {
            return [(bits / word_size) + @boolToInt(@rem(bits, word_size) != 0)]usize;
        },
    }
}
pub fn uniformData(any: anytype) UniformData(@bitSizeOf(@TypeOf(any))) {
    const T: type = @TypeOf(any);
    const U: type = UniformData(@bitSizeOf(T));
    return @ptrCast(*const U, &any).*;
}
pub fn typeCast(comptime generic: Generic) generic.type {
    return @ptrCast(*const generic.type, @alignCast(@max(1, @alignOf(generic.type)), generic.value)).*;
}
pub fn anyTypeCast(comptime value: anytype) Generic {
    return .{ .type = @TypeOf(value), .value = &value };
}
pub fn genericCast(comptime T: type, comptime value: T) Generic {
    return .{ .type = T, .value = &value };
}
pub fn genericSlice(comptime transform: anytype, comptime values: anytype) []const Generic {
    var ret: []const Generic = empty;
    for (values) |value| {
        ret = concat(Generic, ret, transform(value));
    }
    return ret;
}
const debug = opaque {
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
    fn genericTypeList(comptime kind: builtin.TypeKind, any: anytype) []const u8 {
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
            if (decl.is_pub) {
                pub_num += 1;
                pub_str = pub_str ++ ", '" ++ decl.name;
            }
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
    fn invalidTypeErrorDescr(comptime Invalid: type, comptime descr: []const u8) noreturn {
        @compileError("invalid type `" ++ @typeName(Invalid) ++ "': " ++ descr ++ "\n");
    }
    fn standardNoDeclError(comptime T: type, decl_name: []const u8) noreturn {
        @compileError("container '" ++ @typeName(T) ++ "' has no member called '" ++ decl_name ++ "'");
    }
    fn standardNoFieldError(comptime T: type, field_name: []const u8) noreturn {
        @compileError("no member named '" ++ field_name ++ "' in " ++ typeTypeName(@typeInfo(T)) ++ " '" ++ @typeName(T) ++ "'");
    }
    fn unexpectedTypeBytesError(comptime T: type, bytes: u64) void {
        const required_bytes_s: []const u8 = builtin.fmt.ud(bytes).readAll();
        const found_bytes_s: []const u8 = builtin.fmt.ud(@sizeOf(T)).readAll();
        @compileError("static assertion failed: object '" ++ @typeName(T) ++
            "' size " ++ found_bytes_s ++ " does not match requirement " ++ required_bytes_s);
    }
    fn unexpectedTypeBitsError(comptime T: type, bits: u64) void {
        const required_bits_s: []const u8 = builtin.fmt.ud(bits).readAll();
        const found_bits_s: []const u8 = builtin.fmt.ud(@bitSizeOf(T)).readAll();
        @compileError("static assertion failed: object '" ++ @typeName(T) ++
            "' bit size " ++ found_bits_s ++ " does not match requirement " ++ required_bits_s);
    }
    fn initializeNothingError(comptime T: type, comptime U: type) noreturn {
        @compileError("cannot initialize " ++ @typeName(T) ++ " with value of type " ++ @typeName(U));
    }
    fn initializeComptimeFieldError(comptime T: type, comptime field: builtin.Type.StructField) noreturn {
        @compileError("cannot initialize comptime field '" ++ field.name ++ "' in " ++ @typeName(T));
    }
    fn unexpectedVariantError(comptime T: type, value: anytype, yes: anytype, no: anytype) noreturn {
        if (no.len != 0) {
            inline for (no) |n| if (value == n) @compileError("invalid variant of " ++ @typeName(T) ++ ": " ++ @tagName(value));
        }
        if (yes.len != 0) {
            inline for (yes) |y| if (value == y) return;
        }
        @compileError("unlisted variant of " ++ @typeName(T) ++ ": " ++ @tagName(value));
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
