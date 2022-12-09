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

