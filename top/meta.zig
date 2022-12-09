const builtin = @import("./builtin.zig");

pub const Empty = struct {};
pub const empty = &.{};
pub const default = .{};

pub const Type = @TypeOf(@typeInfo(void));
pub const TypeId = @typeInfo(Type).Union.tag_type.?;
pub const TypeKind = enum { type, type_type };
pub const StructField = @typeInfo(@TypeOf(@typeInfo(struct {}).Struct.fields)).Pointer.child;
pub const EnumField = @typeInfo(@TypeOf(@typeInfo(enum { e }).Enum.fields)).Pointer.child;
pub const UnionField = @typeInfo(@TypeOf(@typeInfo(union {}).Union.fields)).Pointer.child;
pub const AddressSpace = @TypeOf(@typeInfo(*void).Pointer.address_space);
pub const Size = @TypeOf(@typeInfo(*void).Pointer.size);
pub const Signedness = @TypeOf(@typeInfo(u0).Int.signedness);
pub const ContainerLayout = @TypeOf(@typeInfo(struct {}).Struct.layout);
pub const CallingConvention = @TypeOf(@typeInfo(fn () noreturn).Fn.calling_convention);
pub const Declaration = @typeInfo(@TypeOf(@typeInfo(struct {}).Struct.decls)).Pointer.child;
pub const FnParam = @typeInfo(@TypeOf(@typeInfo(fn () noreturn).Fn.args)).Pointer.child;
pub const SourceLocation = Src();
pub const Endian = @TypeOf(builtin.zig.cpu.arch.endian());
pub const number_types: []const TypeId = integer_types ++ float_types;
pub const integer_types: []const TypeId = &[_]TypeId{ .Int, .ComptimeInt };
pub const float_types: []const TypeId = &[_]TypeId{ .Float, .ComptimeFloat };
pub const enum_types: []const TypeId = &[_]TypeId{ .Int, .ComptimeInt, .Enum, .EnumLiteral };
pub const tag_types: []const TypeId = &[_]TypeId{ .Type, .ErrorUnion, .Enum, .EnumLiteral };
pub const fn_types: []const TypeId = &[_]TypeId{ .Fn, .BoundFn };
pub const data_types: []const TypeId = &[_]TypeId{ .Struct, .Union };
pub const container_types: []const TypeId = &[_]TypeId{ .Struct, .Enum, .Union };
fn Src() type {
    return @TypeOf(@src());
}
fn isTypeType(comptime T: type, comptime type_types: []const TypeId) bool {
    for (type_types) |type_type| {
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
/// Align `count` below to bitSizeOf smallest real word bit count
pub fn alignBW(comptime count: comptime_int) u16 {
    return switch (count) {
        0...7 => 0,
        8...15 => 8,
        16...31 => 16,
        32...63 => 32,
        64...127 => 64,
        128...255 => 128,
        256...511 => 256,
        else => 512,
    };
}
/// Align `count` above to bitSizeOf smallest real word bit count
pub fn alignAW(comptime count: comptime_int) u16 {
    return switch (count) {
        0 => 0,
        1...8 => 8,
        9...16 => 16,
        17...32 => 32,
        33...64 => 64,
        65...128 => 128,
        129...256 => 256,
        else => 512,
    };
}

pub fn extrema(comptime I: type) struct { min: comptime_int, max: comptime_int } {
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
/// Convert comptime value to bitSizeOf smallest real word bit count
pub fn alignCX(comptime value: comptime_int) u16 {
    if (value > 0) {
        return switch (value) {
            0...~@as(u8, 0) => 8,
            @as(u9, 1) << 8...~@as(u16, 0) => 16,
            @as(u17, 1) << 16...~@as(u32, 0) => 32,
            @as(u33, 1) << 32...~@as(u64, 0) => 64,
            @as(u65, 1) << 64...~@as(u128, 0) => 128,
            @as(u129, 1) << 128...~@as(u256, 0) => 256,
            @as(u257, 1) << 256...~@as(u512, 0) => 512,
            else => @compileLog(value),
        };
    } else {
        const xi8 = extrema(i8);
        const xi16 = extrema(i16);
        const xi32 = extrema(i32);
        const xi64 = extrema(i64);
        const xi128 = extrema(i128);
        const xi256 = extrema(i256);
        const xi512 = extrema(i512);
        return switch (value) {
            xi8.min...xi8.max => 8,
            xi16.min...xi8.min - 1, xi8.max + 1...xi16.max => 16,
            xi32.min...xi16.min - 1, xi16.max + 1...xi32.max => 32,
            xi64.min...xi32.min - 1, xi32.max + 1...xi64.max => 64,
            xi128.min...xi64.min - 1, xi64.max + 1...xi128.max => 128,
            xi256.min...xi128.min - 1, xi128.max + 1...xi256.max => 128,
            xi512.min...xi256.min - 1, xi256.max + 1...xi512.max => 128,
            else => @compileLog(value),
        };
    }
}
