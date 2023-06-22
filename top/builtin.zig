pub const mach = @import("./mach.zig");
pub const math = @import("./math.zig");
pub const config = @import("./config.zig");
pub usingnamespace config;
pub const Error = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    ExactDivisionWithRemainder,
};
pub const Unexpected = error{
    UnexpectedValue,
    UnexpectedLength,
};
/// `E` must be an error type.
pub fn InternalError(comptime E: type) type {
    const U = union(enum) {
        /// Return this error for any exception
        throw: E,
        /// Abort the program for any exception
        abort,
        ignore,
        /// Input Zig error type (unused)
        Error: type,
    };
    return U;
}
/// `E` must be an Enum type.
pub fn ExternalError(comptime E: type) type {
    const T = struct {
        /// Throw error if unwrapping yields any of these values
        throw: []const E = &.{},
        /// Abort the program if unwrapping yields any of these values
        abort: []const E = &.{},
        /// Input error value type
        Enum: type = E,
    };
    return T;
}
pub fn ZigError(comptime Value: type, comptime return_codes: []const Value) type {
    var error_set: type = error{};
    for (return_codes) |error_code| {
        error_set = error_set || @Type(.{
            .ErrorSet = &[1]Type.Error{.{ .name = error_code.errorName() }},
        });
    }
    return error_set;
}
/// Attempt to match a return value against a set of error codes--returning the
/// corresponding zig error on success.
pub fn zigErrorThrow(comptime Value: type, comptime values: []const Value, ret: isize) ZigError(Value, values)!void {
    const E = ZigError(Value, values);
    inline for (values) |value| {
        if (ret == @enumToInt(value)) {
            return @field(E, value.errorName());
        }
    }
}
/// Attempt to match a return value against a set of error codes--aborting the
/// program on success.
pub fn zigErrorAbort(comptime Value: type, comptime values: []const Value, ret: isize) void {
    inline for (values) |value| {
        if (ret == @enumToInt(value)) {
            debug.panic(debug.about_fault_p0_s ++ value.errorName(), null, @returnAddress());
        }
    }
}
/// `S` must be a container type.
pub inline fn setErrorPolicy(
    comptime S: type,
    comptime new: InternalError(S.Error),
) void {
    static.assert(@hasDecl(S, "error_policy"));
    S.error_policy.* = new;
}
/// `S` must be a container type. This function should be called within `S`, to
/// declare a pointer with the name `error_policy`.
pub inline fn createErrorPolicy(
    comptime S: type,
    comptime new: InternalError(S.Error),
) *InternalError(S.Error) {
    static.assert(@hasDecl(S, "Error"));
    var value: *InternalError(S.Error) = ptr(InternalError(S.Error));
    value.* = new;
    return value;
}
pub fn BitCount(comptime T: type) type {
    if (@sizeOf(T) == 0) {
        return comptime_int;
    }
    const bits: T = @bitSizeOf(T);
    return @Type(.{ .Int = .{
        .bits = bits -% @clz(bits),
        .signedness = .unsigned,
    } });
}
pub fn ShiftAmount(comptime V: type) type {
    if (@sizeOf(V) == 0) {
        return comptime_int;
    }
    const bits: V = @bitSizeOf(V);
    return @Type(.{ .Int = .{
        .bits = bits -% @clz(bits -% 1),
        .signedness = .unsigned,
    } });
}
pub fn ShiftValue(comptime A: type) type {
    if (@sizeOf(A) == 0) {
        return comptime_int;
    }
    const bits: A = ~@as(A, 0);
    return @Type(.{ .Int = .{
        .bits = bits +% 1,
        .signedness = .unsigned,
    } });
}
pub fn tzcnt(comptime T: type, value: T) BitCount(T) {
    return @ctz(value);
}
pub fn lzcnt(comptime T: type, value: T) BitCount(T) {
    return @clz(value);
}
pub fn popcnt(comptime T: type, value: T) BitCount(T) {
    return @popCount(value);
}
pub fn mod(comptime T: type, numerator: anytype, denominator: anytype) T {
    return intCast(T, @mod(numerator, denominator));
}
pub fn rem(comptime T: type, numerator: anytype, denominator: anytype) T {
    return intCast(T, @rem(numerator, denominator));
}
pub fn int(comptime T: type, value: bool) T {
    return @boolToInt(value);
}
pub fn int2a(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @boolToInt(value1) & @boolToInt(value2);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn int2v(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @boolToInt(value1) | @boolToInt(value2);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn int3a(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @boolToInt(value1) & @boolToInt(value2) & @boolToInt(value3);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn int3v(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @boolToInt(value1) | @boolToInt(value2) | @boolToInt(value3);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn ended(comptime T: type, value: T, endian: Endian) T {
    if (endian == config.native_endian) {
        return value;
    } else {
        return @byteSwap(value);
    }
}
fn ArithWithOverflowReturn(comptime T: type) type {
    const S = struct {
        value: T,
        overflowed: bool,
    };
    return S;
}
inline fn normalAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalAddReturn(T, arg1.*, arg2);
}
inline fn normalAddReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        } else {
            debug.addCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn normalSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalSubReturn(T, arg1.*, arg2);
}
inline fn normalSubReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        } else {
            debug.subCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn normalMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalMulReturn(T, arg1.*, arg2);
}
inline fn normalMulReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        } else {
            debug.mulCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn exactDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = exactDivisionReturn(T, arg1.*, arg2);
}
inline fn exactDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: T = arg1 / arg2;
    const remainder: T = normalSubReturn(T, arg1, (result * arg2));
    if (config.runtime_assertions and remainder != 0) {
        if (@inComptime()) {
            debug.static.exactDivisionWithRemainder(T, arg1, arg2, result, remainder);
        } else {
            debug.exactDivisionWithRemainderFault(T, arg1, arg2, result, remainder, @returnAddress());
        }
    }
    return result;
}
inline fn saturatingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +|= arg2;
}
inline fn saturatingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +| arg2;
}
inline fn saturatingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -|= arg2;
}
inline fn saturatingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -| arg2;
}
inline fn saturatingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *|= arg2;
}
inline fn saturatingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *| arg2;
}
inline fn wrappingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +%= arg2;
}
inline fn wrappingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +% arg2;
}
inline fn wrappingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -%= arg2;
}
inline fn wrappingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -% arg2;
}
inline fn wrappingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *%= arg2;
}
inline fn wrappingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *% arg2;
}
inline fn normalDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* /= arg2;
}
inline fn normalDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 / arg2;
}
inline fn normalOrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 | arg2;
}
inline fn normalOrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* |= arg2;
}
inline fn normalAndReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 & arg2;
}
inline fn normalAndAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* &= arg2;
}
inline fn normalXorReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 ^ arg2;
}
inline fn normalXorAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* ^= arg2;
}
inline fn normalShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 >> intCast(ShiftAmount(T), arg2);
}
inline fn normalShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* >>= intCast(ShiftAmount(T), arg2);
}
inline fn normalShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 << intCast(ShiftAmount(T), arg2);
}
inline fn normalShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* <<= intCast(ShiftAmount(T), arg2);
}
inline fn truncatedDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divTrunc(arg1.*, arg2);
}
inline fn truncatedDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divTrunc(arg1, arg2);
}
inline fn flooredDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divFloor(arg1.*, arg2);
}
inline fn flooredDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divFloor(arg1, arg2);
}
inline fn exactShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shrExact(arg1, intCast(ShiftAmount(T), arg2));
}
inline fn exactShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shrExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
inline fn exactShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shlExact(arg1, intCast(ShiftAmount(T), arg2));
}
inline fn exactShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shlExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
inline fn overflowingAddAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @addWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingAddReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @addWithOverflow(arg1, arg2);
}
inline fn overflowingSubAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @subWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingSubReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @subWithOverflow(arg1, arg2);
}
inline fn overflowingMulAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @mulWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingMulReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @mulWithOverflow(arg1, arg2);
}
inline fn overflowingShlAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @shlWithOverflow(arg1.*, intCast(ShiftAmount(T), arg2));
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingShlReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @shlWithOverflow(arg1, intCast(ShiftAmount(T), arg2));
}
pub fn add(comptime T: type, arg1: T, arg2: T) T {
    return normalAddReturn(T, arg1, arg2);
}
pub fn addSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingAddReturn(T, arg1, arg2);
}
pub fn addWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingAddReturn(T, arg1, arg2);
}
pub fn addEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalAddAssign(T, arg1, arg2);
}
pub fn addEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingAddAssign(T, arg1, arg2);
}
pub fn addEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingAddAssign(T, arg1, arg2);
}
pub fn addWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingAddReturn(T, arg1, arg2);
}
pub fn addEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingAddAssign(T, arg1, arg2);
}
pub fn sub(comptime T: type, arg1: T, arg2: T) T {
    return normalSubReturn(T, arg1, arg2);
}
pub fn subSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingSubReturn(T, arg1, arg2);
}
pub fn subWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingSubReturn(T, arg1, arg2);
}
pub fn subEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalSubAssign(T, arg1, arg2);
}
pub fn subEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingSubAssign(T, arg1, arg2);
}
pub fn subEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingSubAssign(T, arg1, arg2);
}
pub fn subWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingSubReturn(T, arg1, arg2);
}
pub fn subEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingSubAssign(T, arg1, arg2);
}
pub fn mul(comptime T: type, arg1: T, arg2: T) T {
    return normalMulReturn(T, arg1, arg2);
}
pub fn mulSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingMulReturn(T, arg1, arg2);
}
pub fn mulWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingMulReturn(T, arg1, arg2);
}
pub fn mulEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalMulAssign(T, arg1, arg2);
}
pub fn mulEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingMulAssign(T, arg1, arg2);
}
pub fn mulEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingMulAssign(T, arg1, arg2);
}
pub fn mulWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingMulReturn(T, arg1, arg2);
}
pub fn mulEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingMulAssign(T, arg1, arg2);
}
pub fn div(comptime T: type, arg1: T, arg2: T) T {
    return normalDivisionReturn(T, arg1, arg2);
}
pub fn divEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalDivisionAssign(T, arg1, arg2);
}
pub fn divExact(comptime T: type, arg1: T, arg2: T) T {
    return exactDivisionReturn(T, arg1, arg2);
}
pub fn divEquExact(comptime T: type, arg1: *T, arg2: T) void {
    return exactDivisionAssign(T, arg1, arg2);
}
pub fn divEquTrunc(comptime T: type, arg1: *T, arg2: T) void {
    truncatedDivisionAssign(T, arg1, arg2);
}
pub fn divTrunc(comptime T: type, arg1: T, arg2: T) T {
    return truncatedDivisionReturn(T, arg1, arg2);
}
pub fn divEquFloor(comptime T: type, arg1: *T, arg2: T) void {
    flooredDivisionAssign(T, arg1, arg2);
}
pub fn divFloor(comptime T: type, arg1: T, arg2: T) T {
    return flooredDivisionReturn(T, arg1, arg2);
}
pub fn @"and"(comptime T: type, arg1: T, arg2: T) T {
    return normalAndReturn(T, arg1, arg2);
}
pub fn andEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalAndAssign(T, arg1, arg2);
}
pub fn @"or"(comptime T: type, arg1: T, arg2: T) T {
    return normalOrReturn(T, arg1, arg2);
}
pub fn orEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalOrAssign(T, arg1, arg2);
}
pub fn xor(comptime T: type, arg1: T, arg2: T) T {
    return normalXorReturn(T, arg1, arg2);
}
pub fn xorEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalXorAssign(T, arg1, arg2);
}
pub fn shr(comptime T: type, arg1: T, arg2: T) T {
    return normalShrReturn(T, arg1, arg2);
}
pub fn shrEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalShrAssign(T, arg1, arg2);
}
pub fn shrExact(comptime T: type, arg1: T, arg2: T) T {
    return exactShrReturn(T, arg1, arg2);
}
pub fn shrEquExact(comptime T: type, arg1: *T, arg2: T) void {
    exactShrAssign(T, arg1, arg2);
}
pub fn shl(comptime T: type, arg1: T, arg2: T) T {
    return normalShlReturn(T, arg1, arg2);
}
pub fn shlEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalShlAssign(T, arg1, arg2);
}
pub fn shlExact(comptime T: type, arg1: T, arg2: T) T {
    return exactShlReturn(T, arg1, arg2);
}
pub fn shlEquExact(comptime T: type, arg1: *T, arg2: T) void {
    exactShlAssign(T, arg1, arg2);
}
pub fn shlWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingShlReturn(T, arg1, arg2);
}
pub fn shlEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingShlAssign(T, arg1, arg2);
}
pub fn min(comptime T: type, arg1: T, arg2: T) T {
    if (@typeInfo(T) == .Int or @typeInfo(T) == .ComptimeInt or
        @typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat or
        @typeInfo(T) == .Vector)
    {
        return @min(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        if (@ptrCast(*const U, &arg1).* <
            @ptrCast(*const U, &arg2).*)
        {
            return arg1;
        } else {
            return arg2;
        }
    }
}
pub fn max(comptime T: type, arg1: T, arg2: T) T {
    if (@typeInfo(T) == .Int or @typeInfo(T) == .ComptimeInt or
        @typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat or
        @typeInfo(T) == .Vector)
    {
        return @max(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        if (@ptrCast(*const U, &arg1).* >
            @ptrCast(*const U, &arg2).*)
        {
            return arg1;
        } else {
            return arg2;
        }
    }
}
pub fn ptr(comptime T: type) *T {
    var ret: T = zero(T);
    return &ret;
}
pub fn diff(comptime T: type, arg1: T, arg2: T) T {
    return subWrap(T, max(T, arg1, arg2), min(T, arg1, arg2));
}
pub fn cmov(comptime T: type, b: bool, argt: T, argf: T) T {
    return if (b) argt else argf;
}
pub fn isComptime() bool {
    var b: bool = false;
    return @TypeOf(if (b) @as(u32, 0) else @as(u8, 0)) == u8;
}
pub inline fn ptrCast(comptime T: type, any: anytype) T {
    @setRuntimeSafety(false);
    if (@typeInfo(@TypeOf(any)).Pointer.size == .Slice) {
        return @ptrCast(T, @alignCast(@typeInfo(T).Pointer.alignment, @constCast(any.ptr)));
    } else {
        return @ptrCast(T, @alignCast(@typeInfo(T).Pointer.alignment, @constCast(any)));
    }
}
pub inline fn zero(comptime T: type) T {
    const data: [@sizeOf(T)]u8 align(@max(1, @alignOf(T))) = .{@as(u8, 0)} ** @sizeOf(T);
    comptime return @ptrCast(*const T, &data).*;
}
pub inline fn all(comptime T: type) T {
    const data: [@sizeOf(T)]u8 align(@max(1, @alignOf(T))) = .{~@as(u8, 0)} ** @sizeOf(T);
    return @ptrCast(*const T, &data).*;
}
pub inline fn addr(any: anytype) usize {
    if (@typeInfo(@TypeOf(any)).Pointer.size == .Slice) {
        return @ptrToInt(any.ptr);
    } else {
        return @ptrToInt(any);
    }
}
pub fn anyOpaque(comptime value: anytype) *const anyopaque {
    const S: type = @TypeOf(value);
    const T = [0:value]S;
    return @typeInfo(T).Array.sentinel.?;
}
pub inline fn identity(any: anytype) @TypeOf(any) {
    return any;
}
pub inline fn equ(comptime T: type, dst: *T, src: T) void {
    dst.* = src;
}
pub inline fn arrcpy(buf: [*]u8, comptime any: anytype) u64 {
    @ptrCast(*@TypeOf(any), buf).* = any;
    return any.len;
}
pub inline fn memcpy(buf: [*]u8, slice: []const u8) void {
    mach.memcpy(buf, slice.ptr, slice.len);
}
fn @"test"(b: bool) bool {
    return b;
}
// Currently, only the following non-trivial comparisons are supported:
fn testEqualArray(comptime T: type, comptime array_info: Type.Array, arg1: T, arg2: T) bool {
    var i: usize = 0;
    while (i != array_info.len) : (i += 1) {
        if (!testEqual(array_info.child, arg1[i], arg2[i])) {
            return false;
        }
    }
    return true;
}
fn testEqualSlice(comptime T: type, comptime pointer_info: Type.Pointer, arg1: T, arg2: T) bool {
    if (arg1.len != arg2.len) {
        return false;
    }
    if (arg1.ptr == arg2.ptr) {
        return true;
    }
    var i: usize = 0;
    while (i != arg1.len) : (i += 1) {
        if (!testEqual(pointer_info.child, arg1[i], arg2[i])) {
            return false;
        }
    }
    return true;
}
fn testEqualPointer(comptime T: type, comptime pointer_info: Type.Pointer, arg1: T, arg2: T) bool {
    if (@typeInfo(pointer_info.child) != .Fn) {
        return arg1 == arg2;
    }
    return false;
}
fn testIdenticalStruct(comptime T: type, comptime struct_info: Type.Struct, arg1: T, arg2: T) bool {
    if (struct_info.layout == .Packed) {
        return @bitCast(struct_info.backing_integer.?, arg1) ==
            @bitCast(struct_info.backing_integer.?, arg2);
    }
    return testEqualStruct(T, struct_info, arg1, arg2);
}
fn testEqualStruct(comptime T: type, comptime struct_info: Type.Struct, arg1: T, arg2: T) bool {
    inline for (struct_info.fields) |field| {
        if (!testEqual(
            field.type,
            @field(arg1, field.name),
            @field(arg2, field.name),
        )) {
            return false;
        }
    }
    return true;
}
fn testIdenticalUnion(comptime T: type, comptime union_info: Type.Union, arg1: T, arg2: T) bool {
    return testEqual(union_info.tag_type.?, arg1, arg2) and
        mach.testEqualMany8(
        @ptrCast(*const [@sizeOf(T)]u8, &arg1),
        @ptrCast(*const [@sizeOf(T)]u8, &arg2),
    );
}
fn testEqualUnion(comptime T: type, comptime union_info: Type.Union, arg1: T, arg2: T) bool {
    if (union_info.tag_type) |tag_type| {
        if (@enumToInt(arg1) != @enumToInt(arg2)) {
            return false;
        }
        inline for (union_info.fields) |field| {
            if (@enumToInt(arg1) == @enumToInt(@field(tag_type, field.name))) {
                if (!testEqual(
                    field.type,
                    @field(arg1, field.name),
                    @field(arg2, field.name),
                )) {
                    return false;
                }
            }
        }
    }
    return testIdenticalUnion(T, union_info, arg1, arg2);
}
fn testEqualOptional(comptime T: type, comptime optional_info: Type.Optional, arg1: T, arg2: T) bool {
    if (@typeInfo(optional_info.child) == .Pointer and
        @typeInfo(optional_info.child).Pointer.size != .Slice and
        @typeInfo(optional_info.child).Pointer.size != .C)
    {
        return arg1 == arg2;
    }
    return false;
}
pub fn testEqual(comptime T: type, arg1: T, arg2: T) bool {
    const type_info: Type = @typeInfo(T);
    switch (type_info) {
        .Array => |array_info| {
            return testEqualArray(T, array_info, arg1, arg2);
        },
        .Pointer => |pointer_info| if (pointer_info.size == .Slice) {
            return testEqualSlice(T, pointer_info, arg1, arg2);
        } else {
            return testEqualPointer(T, pointer_info, arg1, arg2);
        },
        .Optional => |optional_info| {
            return testEqualOptional(T, optional_info, arg1, arg2);
        },
        .Struct => |struct_info| {
            return testEqualStruct(T, struct_info, arg1, arg2);
        },
        .Union => |union_info| {
            return testEqualUnion(T, union_info, arg1, arg2);
        },
        .Type,
        .Void,
        .Bool,
        .Int,
        .Float,
        .ComptimeFloat,
        .ComptimeInt,
        .Null,
        .ErrorSet,
        .Enum,
        .Opaque,
        .AnyFrame,
        .EnumLiteral,
        => {
            return arg1 == arg2;
        },
        .Fn,
        .NoReturn,
        .ErrorUnion,
        .Frame,
        .Vector,
        .Undefined,
        => {
            return false;
        },
    }
    return false;
}
pub fn assert(b: bool) void {
    if (!b) {
        if (@inComptime()) {
            @compileError("assertion failed\n");
        } else {
            debug.logFault("assertion failed\n");
        }
    }
}
pub fn assertBelow(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 >= arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " < ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " < ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertBelowOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 > arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " <= ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " <= ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and !testEqual(T, arg1, arg2)) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " == ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " == ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and testEqual(T, arg1, arg2)) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " != ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " != ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertAboveOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 < arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " >= ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " >= ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertAbove(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 <= arg2) {
        if (@inComptime()) {
            debug.comparisonFailedFault(T, " > ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " > ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn testEqualMemory(comptime T: type, arg1: T, arg2: T) bool {
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Int, .Enum, .Bool, .Void => {
            return arg1 == arg2;
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                if (!testEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name))) {
                    return false;
                }
            }
            return true;
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                if (@as(tag_type, arg1) != @as(tag_type, arg2)) {
                    return false;
                }
                switch (arg1) {
                    inline else => |value, tag| {
                        return testEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                return testEqualMemory(optional_info.child, arg1.?, arg2.?);
            }
            return arg1 == null and arg2 == null;
        },
        .Array => |array_info| {
            return testEqualMemory([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = indexOfSentinel(arg1);
                    const len2: usize = indexOfSentinel(arg2);
                    if (len1 != len2) {
                        return false;
                    }
                    if (arg1 == arg2) {
                        return true;
                    }
                    for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                        if (!testEqualMemory(pointer_info.child, value1, value2)) {
                            return false;
                        }
                    }
                    return true;
                },
                .Slice => {
                    if (arg1.len != arg2.len) {
                        return false;
                    }
                    if (arg1.ptr == arg2.ptr) {
                        return true;
                    }
                    for (arg1, arg2) |value1, value2| {
                        if (!testEqualMemory(pointer_info.child, value1, value2)) {
                            return false;
                        }
                    }
                    return true;
                },
                else => return testEqualMemory(pointer_info.child, arg1.*, arg2.*),
            }
        },
    }
}
pub fn assertEqualMemory(comptime T: type, arg1: T, arg2: T) void {
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Int, .Enum => {
            assertEqual(T, arg1, arg2);
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                assertEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name));
            }
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                assertEqual(tag_type, arg1, arg2);
                switch (arg1) {
                    inline else => |value, tag| {
                        assertEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                assertEqualMemory(optional_info.child, arg1.?, arg2.?);
            } else {
                assert(arg1 == null and arg2 == null);
            }
        },
        .Array => |array_info| {
            assertEqual([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = indexOfSentinel(arg1);
                    const len2: usize = indexOfSentinel(arg2);
                    assertEqual(usize, len1, len2);
                    if (arg1 != arg2) {
                        for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                            assertEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                .Slice => {
                    assertEqual(usize, arg1.len, arg2.len);
                    if (arg1.ptr != arg2.ptr) {
                        for (arg1, arg2) |value1, value2| {
                            assertEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                else => assertEqualMemory(pointer_info.child, arg1.*, arg2.*),
            }
        },
    }
}
pub fn expectEqualMemory(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Void => {},
        .Int, .Enum, .Bool => {
            try expectEqual(T, arg1, arg2);
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                try expectEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name));
            }
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                try expectEqual(tag_type, arg1, arg2);
                switch (arg1) {
                    inline else => |value, tag| {
                        try expectEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                try expectEqualMemory(optional_info.child, arg1.?, arg2.?);
            } else {
                try expect(arg1 == null and arg2 == null);
            }
        },
        .Array => |array_info| {
            try expectEqual([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = indexOfSentinel(arg1);
                    const len2: usize = indexOfSentinel(arg2);
                    try expectEqual(usize, len1, len2);
                    if (arg1 != arg2) {
                        for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                            try expectEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                .Slice => {
                    try expectEqual(usize, arg1.len, arg2.len);
                    if (arg1.ptr != arg2.ptr) {
                        for (arg1, arg2) |value1, value2| {
                            try expectEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                else => if (arg1 != arg2) {
                    try expectEqualMemory(pointer_info.child, arg1.*, arg2.*);
                },
            }
        },
    }
}
pub fn expect(b: bool) Unexpected!void {
    if (!b) {
        return error.UnexpectedValue;
    }
}
pub fn expectBelow(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (arg1 >= arg2) {
        return debug.comparisonFailedError(T, " < ", arg1, arg2);
    }
}
pub fn expectBelowOrEqual(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (arg1 > arg2) {
        return debug.comparisonFailedError(T, " <= ", arg1, arg2);
    }
}
pub fn expectEqual(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (!testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedError(T, " == ", arg1, arg2);
    }
}
pub fn expectNotEqual(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedError(T, " != ", arg1, arg2);
    }
}
pub fn expectAboveOrEqual(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (arg1 < arg2) {
        return debug.comparisonFailedError(T, " >= ", arg1, arg2);
    }
}
pub fn expectAbove(comptime T: type, arg1: T, arg2: T) Unexpected!void {
    if (arg1 <= arg2) {
        return debug.comparisonFailedError(T, " > ", arg1, arg2);
    }
}
pub fn intToPtr(comptime P: type, address: u64) P {
    return @intToPtr(P, address);
}
pub inline fn intCast(comptime T: type, value: anytype) T {
    @setRuntimeSafety(false);
    const U: type = @TypeOf(value);
    if (@bitSizeOf(T) > @bitSizeOf(U)) {
        return value;
    }
    if (config.runtime_assertions and value > ~@as(T, 0)) {
        debug.intCastTruncatedBitsFault(T, U, value, @returnAddress());
    }
    return @truncate(T, value);
}
pub const static = struct {
    pub fn assert(comptime b: bool) void {
        if (!b) {
            @compileError("assertion failed");
        }
    }
    pub fn expect(b: bool) !void {
        if (!b) {
            return error.Unexpected;
        }
    }
    fn normalAddAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingAddReturn(T, arg1.*, arg2);
        if (config.comptime_assertions and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalAddReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
        if (config.comptime_assertions and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalSubAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingSubReturn(T, arg1.*, arg2);
        if (config.comptime_assertions and arg1.* < arg2) {
            debug.static.subCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalSubReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
        if (config.comptime_assertions and result[1] != 0) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalMulAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingMulReturn(T, arg1.*, arg2);
        if (config.comptime_assertions and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalMulReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
        if (config.comptime_assertions and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn exactDivisionAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: T = arg1.* / arg2;
        const remainder: T = static.normalSubReturn(T, arg1.*, (result * arg2));
        if (config.comptime_assertions and remainder != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1.*, arg2, result, remainder);
        }
        arg1.* = result;
    }
    fn exactDivisionReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: T = arg1 / arg2;
        const remainder: T = static.normalSubReturn(T, arg1, (result * arg2));
        if (config.comptime_assertions and remainder != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1, arg2, result, remainder);
        }
        return result;
    }
    pub fn add(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        return static.normalAddReturn(T, arg1, arg2);
    }
    pub fn addEqu(comptime T: type, arg1: *T, comptime arg2: T) void {
        static.normalAddAssign(T, arg1, arg2);
    }
    pub fn sub(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        return static.normalSubReturn(T, arg1, arg2);
    }
    pub fn subEqu(comptime T: type, arg1: *T, comptime arg2: T) void {
        static.normalSubAssign(T, arg1, arg2);
    }
    pub fn mul(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        return static.normalMulReturn(T, arg1, arg2);
    }
    pub fn mulEqu(comptime T: type, arg1: *T, comptime arg2: T) void {
        static.normalMulAssign(T, arg1, arg2);
    }
    pub fn divExact(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        return static.exactDivisionReturn(T, arg1, arg2);
    }
    pub fn divEquExact(comptime T: type, arg1: *T, comptime arg2: T) void {
        static.exactDivisionAssign(T, arg1, arg2);
    }
    pub fn assertBelow(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 >= arg2) {
            debug.static.comparisonFailed(T, " < ", arg1, arg2);
        }
    }
    pub fn assertBelowOrEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 > arg2) {
            debug.static.comparisonFailed(T, " <= ", arg1, arg2);
        }
    }
    pub fn assertEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 != arg2) {
            debug.static.comparisonFailed(T, " == ", arg1, arg2);
        }
    }
    pub fn assertNotEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 == arg2) {
            debug.static.comparisonFailed(T, " != ", arg1, arg2);
        }
    }
    pub fn assertAboveOrEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 < arg2) {
            debug.static.comparisonFailed(T, " >= ", arg1, arg2);
        }
    }
    pub fn assertAbove(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        if (config.comptime_assertions and arg1 <= arg2) {
            debug.static.comparisonFailed(T, " > ", arg1, arg2);
        }
    }
};
// These look stupid but the compiler will optimise various methods with
// different success for different word size. Doing manual shifts with u8 is
// much better, whereas bit-casting from a struct with u16 is much better.
pub fn pack16(h: u16, l: u8) u16 {
    return h << 8 | l;
}
// Defined here to prevent stage2 segmentation fault
const U32 = packed struct { h: u16, l: u16 };
pub fn pack32(h: u16, l: u16) u32 {
    return @bitCast(u32, U32{ .h = h, .l = l });
}
// Defined here to prevent stage2 segmentation fault
const U64 = packed struct { h: u32, l: u32 };
pub fn pack64(h: u32, l: u32) u64 {
    return @bitCast(u64, U64{ .h = h, .l = l });
}
pub const proc = struct {
    pub fn exitNotice(return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Success) {
            debug.exitRc(return_code);
        }
        exit(return_code);
    }
    pub fn exitGroupNotice(return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Success) {
            debug.exitNotice(return_code);
        }
        exitGroup(return_code);
    }
    pub fn exitError(exit_error: anytype, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault) {
            debug.exitErrorRc(@errorName(exit_error), return_code);
        }
        exit(return_code);
    }
    pub fn exitGroupError(exit_error: anytype, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault) {
            debug.exitErrorRc(@errorName(exit_error), return_code);
        }
        exitGroup(return_code);
    }
    pub fn exitFault(message: []const u8, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault) {
            debug.exitFault(message, return_code);
        }
        exit(return_code);
    }
    pub fn exitGroupFault(message: []const u8, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault) {
            debug.exitFault(message, return_code);
        }
        exitGroup(return_code);
    }
    pub fn exitErrorFault(exit_error: anytype, message: []const u8, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault and
            config.logging_general.Error)
        {
            debug.exitErrorFaultRc(@errorName(exit_error), message, return_code);
        } else if (config.logging_general.Fault) {
            debug.exitFault(message, return_code);
        } else if (config.logging_general.Error) {
            debug.exitErrorRc(@errorName(exit_error), return_code);
        }
        exitGroup(return_code);
    }
    pub fn exitGroupErrorFault(exit_error: anytype, message: []const u8, return_code: u8) noreturn {
        @setCold(true);
        if (config.logging_general.Fault and
            config.logging_general.Error)
        {
            debug.exitErrorFault(@errorName(exit_error), message, return_code);
        } else if (config.logging_general.Fault) {
            debug.exitFault(message, return_code);
        } else if (config.logging_general.Error) {
            debug.exitErrorRc(@errorName(exit_error), return_code);
        }
        exitGroup(return_code);
    }
    pub fn exit(rc: u8) noreturn {
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (60), // linux sys_exit
              [arg1] "{rdi}" (rc), // exit code
        );
        unreachable;
    }
    pub fn exitGroup(rc: u8) noreturn {
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (231), // linux sys_exit_group
              [arg1] "{rdi}" (rc), // exit code
        );
        unreachable;
    }
};
pub const debug = struct {
    pub fn itos(comptime T: type, value: T) fmt.Generic(T).Array10 {
        return fmt.Generic(T).dec(value);
    }
    const size: usize = 4096;
    const about_exit_0_s: [:0]const u8 = fmt.about("exit");
    pub extern fn printStackTrace(u64, u64) void;
    pub const about_fault_p0_s = blk: {
        var lhs: [:0]const u8 = "fault";
        lhs = config.message_prefix ++ lhs;
        lhs = lhs ++ config.message_suffix;
        const len: u64 = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ config.message_no_style;
        break :blk lhs ++ " " ** (config.message_indent - len);
    };
    const about_error_p0_s = blk: {
        var lhs: [:0]const u8 = "error";
        lhs = config.message_prefix ++ lhs;
        lhs = lhs ++ config.message_suffix;
        const len: u64 = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ config.message_no_style;
        break :blk lhs ++ " " ** (config.message_indent - len);
    };
    pub inline fn typeFault(comptime T: type) []const u8 {
        return about_fault_p0_s ++ @typeName(T);
    }
    pub inline fn typeError(comptime T: type) []const u8 {
        return about_error_p0_s ++ @typeName(T);
    }
    fn exitRc(rc: u8) void {
        var buf: [4096]u8 = undefined;
        logAlwaysAIO(&buf, &.{ about_exit_0_s, "rc=", fmt.ud8(rc).readAll(), "\n" });
    }
    fn exitErrorRc(error_name: []const u8, rc: u8) void {
        var buf: [4096]u8 = undefined;
        logAlwaysAIO(&buf, &.{ about_error_p0_s, "(", error_name, "), rc=", fmt.ud8(rc).readAll(), "\n" });
    }
    fn exitErrorFaultRc(error_name: []const u8, message: []const u8, rc: u8) void {
        exitError(error_name);
        exitFault(message, rc);
    }
    fn exitError(error_name: []const u8) void {
        var buf: [4096]u8 = undefined;
        logAlwaysAIO(&buf, &.{ about_error_p0_s, "(", error_name, ")\n" });
    }
    fn exitFault(message: []const u8, rc: u8) void {
        var buf: [4096]u8 = undefined;
        logAlwaysAIO(&buf, &.{ message, ", rc=", fmt.ud8(rc).readAll(), "\n" });
    }
    fn exitErrorFault(error_name: []const u8, message: []const u8) void {
        exitError(error_name);
        exitFault(message);
    }
    fn comparisonFailedString(comptime T: type, what: []const u8, symbol: []const u8, buf: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const notation: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = mach.memcpyMulti(buf.ptr, &[_][]const u8{
            what,     itos(T, arg1).readAll(),
            symbol,   itos(T, arg2).readAll(),
            notation,
        });
        if (help_read) {
            if (arg1 > arg2) {
                len += mach.memcpyMulti(buf[len..].ptr, &[_][]const u8{ itos(T, arg1 -% arg2).readAll(), symbol, "0\n" });
            } else {
                len += mach.memcpyMulti(buf[len..].ptr, &[_][]const u8{ "0", symbol, itos(T, arg2 -% arg1).readAll(), "\n" });
            }
        }
        return len;
    }
    fn intCastTruncatedBitsString(comptime T: type, comptime U: type, buf: []u8, arg1: U) u64 {
        const minimum: T = 0;
        return mach.memcpyMulti(buf.ptr, &[_][]const u8{
            about_fault_p0_s,            "integer cast truncated bits: ",
            itos(U, arg1).readAll(),     " greater than " ++ @typeName(T) ++ " maximum (",
            itos(T, ~minimum).readAll(), ")\n",
        });
    }
    fn subCausedOverflowString(comptime T: type, what: []const u8, msg: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += mach.memcpyMulti(msg.ptr, &[_][]const u8{
            what,                    " integer overflow: ",
            itos(T, arg1).readAll(), " - ",
            itos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            len += mach.memcpyMulti(msg[len..].ptr, &[_][]const u8{ "0 - ", itos(T, arg2 -% arg1).readAll(), "\n" });
        }
        return len;
    }
    fn addCausedOverflowString(comptime T: type, what: []const u8, msg: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += mach.memcpyMulti(msg.ptr, &[_][]const u8{
            what,                    " integer overflow: ",
            itos(T, arg1).readAll(), " + ",
            itos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            const argl: T = ~@as(T, 0);
            const argr: T = (arg2 +% arg1) -% argl;
            len += mach.memcpyMulti(msg[len..].ptr, &[_][]const u8{ itos(T, argl).readAll(), " + ", itos(T, argr).readAll(), "\n" });
        }
        return len;
    }
    fn mulCausedOverflowString(comptime T: type, what: []const u8, buf: []u8, arg1: T, arg2: T) u64 {
        return mach.memcpyMulti(buf.ptr, &[_][]const u8{
            what,                    ": integer overflow: ",
            itos(T, arg1).readAll(), " * ",
            itos(T, arg2).readAll(), "\n",
        });
    }
    fn exactDivisionWithRemainderString(comptime T: type, what: []const u8, buf: []u8, arg1: T, arg2: T, result: T, remainder: T) u64 {
        return mach.memcpyMulti(buf.ptr, &[_][]const u8{
            what,                         ": exact division had a remainder: ",
            itos(T, arg1).readAll(),      "/",
            itos(T, arg2).readAll(),      " == ",
            itos(T, result).readAll(),    "r",
            itos(T, remainder).readAll(), "\n",
        });
    }
    fn incorrectAlignmentString(comptime Pointer: type, what: []const u8, buf: []u8, address: usize, alignment: usize, remainder: u64) u64 {
        return mach.memcpyMulti(buf.ptr, &[_][]const u8{
            what,                                      ": incorrect alignment: ",
            @typeName(Pointer),                        " align(",
            itos(u64, alignment).readAll(),            "): ",
            itos(u64, address).readAll(),              " == ",
            itos(u64, address -% remainder).readAll(), "+",
            itos(u64, remainder).readAll(),            "\n",
        });
    }
    fn intCastTruncatedBitsFault(comptime T: type, comptime U: type, arg: U, ret_addr: usize) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.intCastTruncatedBitsString(T, U, &buf, arg);
        panic(buf[0..len], null, ret_addr);
    }
    fn subCausedOverflowError(comptime T: type, arg1: T, arg2: T) Error {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logError(buf[0..len]);
        return error.SubCausedOverflow;
    }
    fn subCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, typeFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len], null, ret_addr);
    }
    fn addCausedOverflowError(comptime T: type, arg1: T, arg2: T) Error {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, typeError(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logError(buf[0..len]);
        return error.AddCausedOverflow;
    }
    fn addCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, typeFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len], null, ret_addr);
    }
    fn mulCausedOverflowError(comptime T: type, arg1: T, arg2: T) Error {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, typeError(T), &buf, arg1, arg2);
        logError(buf[0..len]);
        return error.MulCausedOverflow;
    }
    fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, typeFault(T), &buf, arg1, arg2);
        panic(buf[0..len], null, ret_addr);
    }
    fn exactDivisionWithRemainderError(comptime T: type, arg1: T, arg2: T, result: T, remainder: T) Error {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, typeError(T), &buf, arg1, arg2, result, remainder);
        logError(buf[0..len]);
        return error.DivisionWithRemainder;
    }
    fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, remainder: T, ret_addr: usize) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, typeFault(T), &buf, arg1, arg2, result, remainder);
        panic(buf[0..len], null, ret_addr);
    }
    fn incorrectAlignmentError(comptime T: type, address: usize, alignment: usize) Error {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, typeError(T), &buf, address, alignment, remainder);
        logError(buf[0..len]);
        return error.IncorrectAlignment;
    }
    fn incorrectAlignmentFault(comptime T: type, buf: *[size]u8, address: usize, alignment: usize, ret_addr: usize) noreturn {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        const len: u64 = incorrectAlignmentString(T, typeFault(T), &buf, address, alignment, remainder);
        panic(buf[0..len], null, ret_addr);
    }
    fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1), ret_addr: usize) noreturn {
        @setCold(true);
        const about_fault_s: []const u8 = typeFault(T) ++ " failed assertion: ";
        var buf: [size]u8 = undefined;
        const len: u64 = switch (@typeInfo(T)) {
            .Int => comparisonFailedString(T, about_fault_s, symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000),
            .Enum => mach.memcpyMulti(&buf, &[_][]const u8{ about_fault_s, @tagName(arg1), symbol, @tagName(arg2) }),
            .Type => mach.memcpyMulti(&buf, &[_][]const u8{ about_fault_s, @typeName(arg1), symbol, @typeName(arg2) }),
            else => mach.memcpyMulti(&buf, &[_][]const u8{ about_fault_s, "unexpected value\n" }),
        };
        panic(buf[0..len], null, ret_addr);
    }
    fn comparisonFailedError(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1)) Unexpected {
        @setCold(true);
        const about_error_s: []const u8 = typeError(T) ++ " failed test: ";
        var buf: [size]u8 = undefined;
        const len: u64 = switch (@typeInfo(T)) {
            .Int => comparisonFailedString(T, about_error_s, symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000),
            .Enum => mach.memcpyMulti(&buf, &[_][]const u8{ about_error_s, @tagName(arg1), symbol, @tagName(arg2) }),
            .Type => mach.memcpyMulti(&buf, &[_][]const u8{ about_error_s, @typeName(arg1), symbol, @typeName(arg2) }),
            else => mach.memcpyMulti(&buf, &[_][]const u8{ about_error_s, "unexpected value\n" }),
        };
        logError(buf[0..len]);
        return error.UnexpectedValue;
    }
    pub fn write(buf: []const u8) void {
        asm volatile (
            \\syscall # write
            :
            : [_] "{rax}" (1), // linux sys_write
              [_] "{rdi}" (2), // stderr
              [_] "{rsi}" (buf.ptr),
              [_] "{rdx}" (buf.len),
            : "rcx", "r11", "memory", "rax"
        );
    }
    pub fn read(comptime n: u64) struct { buf: [n]u8, len: u64 } {
        var buf: [n]u8 = undefined;
        return .{
            .buf = buf,
            .len = asm volatile (
                \\syscall # read
                : [_] "={rax}" (-> usize),
                : [_] "{rax}" (0), // linux sys_read
                  [_] "{rdi}" (0), // stdin
                  [_] "{rsi}" (&buf),
                  [_] "{rdx}" (n),
                : "rcx", "r11", "memory"
            ),
        };
    }
    pub inline fn name(buf: []u8) u64 {
        const rc: i64 = asm volatile (
            \\syscall
            : [_] "={rax}" (-> isize),
            : [_] "{rax}" (89), // linux readlink
              [_] "{rdi}" ("/proc/self/exe"), // symlink to executable
              [_] "{rsi}" (buf.ptr), // message buf ptr
              [_] "{rdx}" (buf.len), // message buf len
            : "rcx", "r11", "memory"
        );
        return if (rc < 0) ~@as(u64, 0) else @intCast(u64, rc);
    }
    pub inline fn logSuccess(buf: []const u8) void {
        if (config.logging_general.Success) write(buf);
    }
    pub inline fn logAcquire(buf: []const u8) void {
        if (config.logging_general.Acquire) write(buf);
    }
    pub inline fn logRelease(buf: []const u8) void {
        if (config.logging_general.Release) write(buf);
    }
    pub inline fn logError(buf: []const u8) void {
        if (config.logging_general.Error) write(buf);
    }
    pub inline fn logFault(buf: []const u8) void {
        if (config.logging_general.Fault) write(buf);
    }
    pub fn logAlwaysAIO(buf: []u8, slices: []const []const u8) void {
        @setRuntimeSafety(false);
        write(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub fn logSuccessAIO(buf: []u8, slices: []const []const u8) void {
        @setRuntimeSafety(false);
        logSuccess(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub fn logAcquireAIO(buf: []u8, slices: []const []const u8) void {
        @setRuntimeSafety(false);
        logAcquire(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub fn logReleaseAIO(buf: []u8, slices: []const []const u8) void {
        @setRuntimeSafety(false);
        logRelease(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub fn logErrorAIO(buf: []u8, slices: []const []const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        logError(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub fn logFaultAIO(buf: []u8, slices: []const []const u8) void {
        @setCold(true);
        @setRuntimeSafety(false);
        logFault(buf[0..mach.memcpyMulti(buf.ptr, slices)]);
    }
    pub noinline fn panic(msg: []const u8, _: @TypeOf(@errorReturnTrace()), ret_addr: ?usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        if (config.tracing_override orelse
            config.tracing_default)
        {
            printStackTrace(ret_addr.?, 0);
        }
        @call(.always_inline, proc.exitGroupFault, .{ msg, 2 });
    }
    pub noinline fn panicExtra(msg: []const u8, ctx_ptr: *const anyopaque) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const st: mach.RegisterState = @intToPtr(*mach.RegisterState, @ptrToInt(ctx_ptr) +% 40).*;
        if (config.tracing_override orelse
            config.tracing_default)
        {
            printStackTrace(st.rip, st.rbp);
        }
        @call(.always_inline, proc.exitGroupFault, .{ msg, 2 });
    }
    // This function is an example for how the other panic handlers should look.
    // Obviously this is tedious to code so not all at once.
    pub noinline fn panicOutOfBounds(idx: u64, max_len: u64) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: u64 = @returnAddress();
        var buf: [1024]u8 = undefined;
        var len: u64 = 0;
        const idx_s: []const u8 = fmt.ud64(idx).readAll();
        @ptrCast(*[debug.about_fault_p0_s.len]u8, &buf).* = debug.about_fault_p0_s.*;
        len +%= debug.about_fault_p0_s.len;
        if (max_len == 0) {
            @ptrCast(*[10]u8, buf[len..].ptr).* = "indexing (".*;
            len +%= 10;
            mach.memcpy(buf[len..].ptr, idx_s.ptr, idx_s.len);
            len +%= idx_s.len;
        } else {
            @ptrCast(*[6]u8, buf[len..].ptr).* = "index ".*;
            len +%= 6;
            mach.memcpy(buf[len..].ptr, idx_s.ptr, idx_s.len);
            len +%= idx_s.len;
        }
        mach.memcpy(buf[len..].ptr, idx_s.ptr, idx_s.len);
        if (max_len == 0) {
            @ptrCast(*[18]u8, buf[len..].ptr).* = ") into empty array".*;
            len +%= 18;
        } else {
            const max_len_s: []const u8 = fmt.ud64(max_len -% 1).readAll();
            @ptrCast(*[15]u8, buf[len..].ptr).* = " above maximum ".*;
            len +%= 15;
            mach.memcpy(buf[len..].ptr, max_len_s.ptr, max_len_s.len);
            len +%= max_len_s.len;
        }
        panic(buf[0..len], null, ret_addr);
    }
    pub noinline fn panicSentinelMismatch(expected: anytype, actual: @TypeOf(expected)) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        const expected_s: []const u8 = fmt.udsize(expected).readAll();
        const actual_s: []const u8 = fmt.udsize(actual).readAll();
        const len: u64 = mach.memcpyMulti(&buf, &[_][]const u8{
            debug.about_fault_p0_s, "sentinel mismatch: expected ",
            expected_s,             ", found ",
            actual_s,               "\n",
        });
        panic(buf[0..len], null, ret_addr);
    }
    pub noinline fn panicStartGreaterThanEnd(lower: usize, upper: usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        const lower_s: []const u8 = fmt.ud64(lower).readAll();
        const upper_s: []const u8 = fmt.ud64(upper).readAll();
        const len: u64 = mach.memcpyMulti(&buf, &[_][]const u8{
            debug.about_fault_p0_s, "start index ",
            lower_s,                " is larger than end index ",
            upper_s,                "\n",
        });
        panic(buf[0..len], null, ret_addr);
    }
    pub noinline fn panicInactiveUnionField(active: anytype, wanted: @TypeOf(active)) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        const len: u64 = mach.memcpyMulti(&buf, &[_][]const u8{
            debug.about_fault_p0_s, "access of union field '",
            @tagName(wanted),       "' while field '",
            @tagName(active),       "' is active\n",
        });
        panic(buf[0..len], null, ret_addr);
    }
    pub noinline fn panicUnwrapError(st: ?*StackTrace, err: anyerror) noreturn {
        if (!config.discard_errors) {
            @compileError("error is discarded");
        }
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        const len: u64 = mach.memcpyMulti(&buf, &[_][]const u8{ debug.about_fault_p0_s, "error is discarded: ", @errorName(err), "\n" });
        panic(buf[0..len], st, ret_addr);
    }
    fn checkNonScalarSentinel(expected: anytype, actual: @TypeOf(expected)) void {
        if (!testEqual(@TypeOf(expected), expected, actual)) {
            panicSentinelMismatch(expected, actual);
        }
    }
    inline fn addErrRetTraceAddr(st: *StackTrace, ret_addr: usize) void {
        if (st.addrs_len < st.addrs.len) {
            st.addrs[st.addrs_len] = ret_addr;
        }
        st.addrs_len +%= 1;
    }
    noinline fn returnError(st: *StackTrace) void {
        @setCold(true);
        @setRuntimeSafety(false);
        addErrRetTraceAddr(st, @returnAddress());
    }
    const static = struct {
        fn subCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            comptime {
                var msg: [size]u8 = undefined;
                @compileError(msg[0..debug.overflowedSubString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
            }
        }
        fn addCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            comptime {
                var msg: [size]u8 = undefined;
                @compileError(msg[0..debug.overflowedAddString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
            }
        }
        fn mulCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            comptime {
                var msg: [size]u8 = undefined;
                @compileError(msg[0..debug.mulCausedOverflowString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
            }
        }
        fn exactDivisionWithRemainder(
            comptime T: type,
            comptime arg1: T,
            comptime arg2: T,
            comptime result: T,
            comptime remainder: T,
        ) noreturn {
            comptime {
                var buf: [size]u8 = undefined;
                var len: u64 = 0;
                for ([_][]const u8{
                    @typeName(T),                 ": exact division had a remainder: ",
                    itos(T, arg1).readAll(),      "/",
                    itos(T, arg2).readAll(),      " == ",
                    itos(T, result).readAll(),    "r",
                    itos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s, 0..) |c, idx| buf[len +% idx] = c;
                    len +%= s.len;
                }
                @compileError(buf[0..len]);
            }
        }
        fn incorrectAlignment(
            comptime T: type,
            comptime type_name: []const u8,
            comptime address: T,
            comptime alignment: T,
            comptime result: T,
            comptime remainder: T,
        ) noreturn {
            comptime {
                var buf: [size]u8 = undefined;
                var len: u64 = 0;
                for ([_][]const u8{
                    @typeName(T),                 ": incorrect alignment: ",
                    type_name,                    " align(",
                    itos(T, alignment).readAll(), "): ",
                    itos(T, address).readAll(),   " == ",
                    itos(T, result).readAll(),    "+",
                    itos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s, 0..) |c, idx| buf[len +% idx] = c;
                    len +%= s.len;
                }
                @compileError(buf[0..len]);
            }
        }
        fn comparisonFailed(
            comptime T: type,
            comptime how: []const u8,
            comptime symbol: []const u8,
            comptime arg1: T,
            comptime arg2: T,
        ) void {
            comptime {
                var buf: [size]u8 = undefined;
                var len: u64 = 0;
                for ([_][]const u8{
                    typeFault(T) ++ how,
                    itos(T, arg1).readAll(),
                    symbol,
                    itos(T, arg2).readAll(),
                    if (@min(arg1, arg2) > 10_000) ", i.e. " else "\n",
                }) |s| {
                    for (s, 0..) |c, idx| buf[len +% idx] = c;
                    len +%= s.len;
                }
                if (@min(arg1, arg2) > 10_000) {
                    if (arg1 > arg2) {
                        for ([_][]const u8{ itos(T, arg1 -% arg2).readAll(), symbol, "0\n" }) |s| {
                            for (s, 0..) |c, idx| buf[len +% idx] = c;
                            len +%= s.len;
                        }
                    } else {
                        for ([_][]const u8{ "0", symbol, itos(T, arg2 -% arg1).readAll(), "\n" }) |s| {
                            for (s, 0..) |c, idx| buf[len +% idx] = c;
                            len +%= s.len;
                        }
                    }
                }
                @compileError(buf[0..len]);
            }
        }
    };
};
pub const parse = struct {
    pub const E = error{BadParse};
    pub fn ub(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 2);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'b');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 2) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn uo(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 8);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'o');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 8) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ud(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ux(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 16);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'x');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 16) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ib(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 2);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'b');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @intCast(i8, fromSymbol(str[idx], 2)) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn io(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 8);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'o');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @intCast(i8, fromSymbol(str[idx], 8)) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn id(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @intCast(i8, fromSymbol(str[idx], 10)) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn ix(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 16);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'x');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @intCast(i8, fromSymbol(str[idx], 16)) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn fromSymbol(c: u8, comptime radix: u7) u8 {
        if (radix <= 10) {
            return c -% '0';
        } else {
            switch (c) {
                '0'...'9' => return c -% '0',
                'a'...'z' => return c -% 'a' +% 0xa,
                'A'...'Z' => return c -% 'A' +% 0xa,
                else => return radix +% 1,
            }
        }
    }
    pub inline fn fromSymbolChecked(c: u8, comptime radix: u7) !u8 {
        const value: u8 = fromSymbol(c, radix);
        if (value >= radix) {
            return error.InvalidEncoding;
        }
        return value;
    }
    fn nextSigFig(comptime T: type, prev: T, comptime radix: T) ?T {
        const mul_result: Overflow(T) = @mulWithOverflow(prev, radix);
        if (mul_result[1] != 0) {
            return null;
        }
        const add_result: Overflow(T) = @addWithOverflow(mul_result[0], radix -% 1);
        if (add_result[1] != 0) {
            return null;
        }
        return add_result[0];
    }
    pub inline fn sigFigList(comptime T: type, comptime radix: u7) []const T {
        comptime var value: T = 0;
        comptime var ret: []const T = &.{};
        inline while (comptime nextSigFig(T, value, radix)) |next| {
            ret = ret ++ [1]T{value};
            value = next;
        } else {
            ret = ret ++ [1]T{value};
        }
        comptime return ret;
    }
    pub fn any(comptime T: type, str: []const u8) !T {
        const signed: bool = str[0] == '-';
        if (@typeInfo(T).Int.signedness == .unsigned and signed) {
            return E.BadParse;
        }
        var idx: u64 = int(u64, signed);
        const is_zero: bool = str[idx] == '0';
        idx += int(u64, is_zero);
        if (idx == str.len) {
            return 0;
        }
        switch (str[idx]) {
            'b' => return parseValidate(T, str[idx +% 1 ..], 2),
            'o' => return parseValidate(T, str[idx +% 1 ..], 8),
            'x' => return parseValidate(T, str[idx +% 1 ..], 16),
            else => return parseValidate(T, str[idx..], 10),
        }
    }
    fn parseValidate(comptime T: type, str: []const u8, comptime radix: u7) !T {
        const sig_fig_list: []const T = sigFigList(T, radix);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= try fromSymbolChecked(str[idx], radix) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
};
pub const fmt = struct {
    const about_blank_s = blk: {
        const indent = (" " ** config.message_indent);
        if (config.message_style) |style| {
            break :blk style ++ indent ++ config.message_no_style;
        }
        break :blk indent;
    };
    const AboutSrc = @TypeOf(about_blank_s);
    const AboutDest = @TypeOf(@constCast(about_blank_s));
    pub fn about(comptime s: [:0]const u8) AboutSrc {
        var lhs: [:0]const u8 = s;
        lhs = config.message_prefix ++ lhs;
        lhs = lhs ++ config.message_suffix;
        const len: u64 = lhs.len;
        if (config.message_style) |style| {
            lhs = style ++ lhs ++ config.message_no_style;
        }
        if (len >= config.message_indent) {
            @compileError(s ++ " is too long");
        }
        return lhs ++ " " ** (config.message_indent - len);
    }
    pub fn ci(comptime value: comptime_int) []const u8 {
        if (value < 0) {
            const s: []const u8 = @typeName([-value]void);
            return "-" ++ s[1 .. s.len -% 5];
        } else {
            const s: []const u8 = @typeName([value]void);
            return s[1 .. s.len -% 5];
        }
    }
    pub fn cx(comptime value: anytype) []const u8 {
        const S: type = @TypeOf(value);
        const T = [:value]S;
        const s_type_name: []const u8 = @typeName(S);
        const t_type_name: []const u8 = @typeName(T);
        return t_type_name[2 .. t_type_name.len -% (s_type_name.len +% 1)];
    }
    pub inline fn bin(comptime Int: type, value: Int) Generic(Int).Array2 {
        return Generic(Int).bin(value);
    }
    pub inline fn oct(comptime Int: type, value: Int) Generic(Int).Array8 {
        return Generic(Int).oct(value);
    }
    pub inline fn dec(comptime Int: type, value: Int) Generic(Int).Array10 {
        return Generic(Int).dec(value);
    }
    pub inline fn hex(comptime Int: type, value: Int) Generic(Int).Array16 {
        return Generic(Int).hex(value);
    }
    pub const ub8 = Generic(u8).bin;
    pub const ub16 = Generic(u16).bin;
    pub const ub32 = Generic(u32).bin;
    pub const ub64 = Generic(u64).bin;
    pub const ubsize = Generic(usize).bin;
    pub const uo8 = Generic(u8).oct;
    pub const uo16 = Generic(u16).oct;
    pub const uo32 = Generic(u32).oct;
    pub const uo64 = Generic(u64).oct;
    pub const uosize = Generic(usize).oct;
    pub const ud8 = Generic(u8).dec;
    pub const ud16 = Generic(u16).dec;
    pub const ud32 = Generic(u32).dec;
    pub const ud64 = Generic(u64).dec;
    pub const udsize = Generic(usize).dec;
    pub const ux8 = Generic(u8).hex;
    pub const ux16 = Generic(u16).hex;
    pub const ux32 = Generic(u32).hex;
    pub const ux64 = Generic(u64).hex;
    pub const uxsize = Generic(usize).hex;
    pub const ib8 = Generic(i8).bin;
    pub const ib16 = Generic(i16).bin;
    pub const ib32 = Generic(i32).bin;
    pub const ib64 = Generic(i64).bin;
    pub const ibsize = Generic(isize).bin;
    pub const io8 = Generic(i8).oct;
    pub const io16 = Generic(i16).oct;
    pub const io32 = Generic(i32).oct;
    pub const io64 = Generic(i64).oct;
    pub const iosize = Generic(isize).oct;
    pub const id8 = Generic(i8).dec;
    pub const id16 = Generic(i16).dec;
    pub const id32 = Generic(i32).dec;
    pub const id64 = Generic(i64).dec;
    pub const idsize = Generic(isize).dec;
    pub const ix8 = Generic(i8).hex;
    pub const ix16 = Generic(i16).hex;
    pub const ix32 = Generic(i32).hex;
    pub const ix64 = Generic(i64).hex;
    pub const ixsize = Generic(isize).hex;
    pub const nsec = Generic(u64).nsec;
    fn maxSigFig(comptime T: type, comptime radix: u7) comptime_int {
        const U = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        var value: U = 0;
        var len: u16 = 0;
        if (radix != 10) {
            len += 2;
        }
        value -%= 1;
        while (value != 0) : (value /= radix) {
            len += 1;
        }
        return len;
    }
    pub fn length(comptime U: type, abs_value: U, comptime radix: u7) usize {
        @setRuntimeSafety(false);
        if (@bitSizeOf(U) == 1) {
            return 1;
        }
        var value: U = abs_value;
        var count: u64 = 0;
        while (value != 0) : (value /= radix) {
            count +%= 1;
        }
        return @max(1, count);
    }
    pub fn toSymbol(comptime T: type, value: T, comptime radix: u7) u8 {
        @setRuntimeSafety(false);
        if (@bitSizeOf(T) < 8) {
            return toSymbol(u8, value, radix);
        }
        const result: u8 = @intCast(u8, @rem(value, radix));
        const dx = .{
            .d = @as(u8, '9' -% 9),
            .x = @as(u8, 'f' -% 15),
        };
        if (radix > 10) {
            return result +% if (result < 10) dx.d else dx.x;
        } else {
            return result +% dx.d;
        }
    }
    pub fn Generic(comptime Int: type) type {
        const T = struct {
            const Abs = math.Absolute(Int);
            const len2: comptime_int = maxSigFig(Int, 2) +% 1;
            const len8: comptime_int = maxSigFig(Int, 8) +% 1;
            const len10: comptime_int = maxSigFig(Int, 10) +% 1;
            const len16: comptime_int = maxSigFig(Int, 16) +% 1;
            const Array2 = Array(len2);
            const Array8 = Array(len8);
            const Array10 = Array(len10);
            const Array16 = Array(len16);
            fn bin(value: Int) Array2 {
                @setRuntimeSafety(false);
                var ret: Array2 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    while (ret.len != 3) {
                        ret.len -%= 1;
                        ret.buf[ret.len] = '0';
                    }
                    ret.len -%= 2;
                    @ptrCast(*[2]u8, &ret.buf[ret.len]).* = "0b".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @intCast(Abs, -value)
                else
                    @intCast(Abs, value);
                while (abs_value != 0) : (abs_value /= 2) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @intCast(u8, @rem(abs_value, 2));
                }
                while (ret.len != 3) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                }
                ret.len -%= 2;
                @ptrCast(*[2]u8, ret.buf[ret.len..].ptr).* = "0b".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            fn oct(value: Int) Array8 {
                @setRuntimeSafety(false);
                var ret: Array8 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 3;
                    @ptrCast(*[3]u8, ret.buf[ret.len..].ptr).* = "0o0".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @intCast(Abs, -value)
                else
                    @intCast(Abs, value);
                while (abs_value != 0) : (abs_value /= 8) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @intCast(u8, @rem(abs_value, 8));
                }
                ret.len -%= 2;
                @ptrCast(*[2]u8, ret.buf[ret.len..].ptr).* = "0o".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            fn dec(value: Int) Array10 {
                @setRuntimeSafety(false);
                var ret: Array10 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @intCast(Abs, -value)
                else
                    @intCast(Abs, value);
                while (abs_value != 0) : (abs_value /= 10) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @intCast(u8, @rem(abs_value, 10));
                }
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            fn hex(value: Int) Array16 {
                @setRuntimeSafety(false);
                var ret: Array16 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 3;
                    @ptrCast(*[3]u8, ret.buf[ret.len..].ptr).* = "0x0".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @bitCast(Abs, -value)
                else
                    @intCast(Abs, value);
                while (abs_value != 0) : (abs_value /= 16) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = toSymbol(Abs, abs_value, 16);
                }
                ret.len -%= 2;
                @ptrCast(*[2]u8, ret.buf[ret.len..].ptr).* = "0x".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            fn nsec(value: Int) Array10 {
                @setRuntimeSafety(false);
                var ret: Array10 = @This().dec(value);
                while (ret.buf.len -% ret.len < 9) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                }
                return ret;
            }
            fn Array(comptime len: comptime_int) type {
                return struct {
                    len: u64,
                    buf: [len]u8 align(8),
                    pub fn readAll(array: *const @This()) []const u8 {
                        return array.buf[array.len..];
                    }
                };
            }
        };
        return T;
    }
    pub fn typeTypeName(comptime id: TypeId) []const u8 {
        return switch (id) {
            .Type => "type",
            .Void => "void",
            .Bool => "bool",
            .NoReturn => "noreturn",
            .Int => "integer",
            .Float => "float",
            .Pointer => "pointer",
            .Array => "array",
            .Struct => "struct",
            .ComptimeFloat => "comptime_float",
            .ComptimeInt => "comptime_int",
            .Undefined => "undefined",
            .Null => "null",
            .Optional => "optional",
            .ErrorUnion => "error union",
            .ErrorSet => "error set",
            .Enum => "enum",
            .Union => "union",
            .Fn => "function",
            .Opaque => "opaque",
            .Frame => "frame",
            .AnyFrame => "anyframe",
            .Vector => "vector",
            .EnumLiteral => "enum literal",
        };
    }
    pub fn typeDeclSpecifier(comptime type_info: Type) []const u8 {
        return switch (type_info) {
            .Array, .Pointer, .Optional => {
                const type_name: []const u8 = @typeName(@Type(type_info));
                const child_type_name: []const u8 = @typeName(@field(type_info, @tagName(type_info)).child);
                return type_name[0 .. type_name.len -% child_type_name.len];
            },
            .Enum => |enum_info| {
                return "enum(" ++ @typeName(enum_info.tag_type) ++ ")";
            },
            .Struct => |struct_info| {
                switch (struct_info.layout) {
                    .Packed => {
                        if (struct_info.backing_integer) |backing_integer| {
                            return "packed struct(" ++ @typeName(backing_integer) ++ ")";
                        } else {
                            return "packed struct";
                        }
                    },
                    .Extern => {
                        return "extern struct";
                    },
                    .Auto => {
                        return "struct";
                    },
                }
            },
            .Union => |union_info| {
                switch (union_info.layout) {
                    .Packed => {
                        if (union_info.tag_type != null) {
                            return "packed union(enum)";
                        } else {
                            return "packed union";
                        }
                    },
                    .Extern => {
                        return "extern union";
                    },
                    .Auto => {
                        if (union_info.tag_type != null) {
                            return "union(enum)";
                        } else {
                            return "union";
                        }
                    },
                }
            },
            .Opaque => "opaque",
            .ErrorSet => "error",
            else => @compileError(@typeName(@Type(type_info))),
        };
    }
};
pub const Version = struct {
    major: u32,
    minor: u32,
    patch: u32 = 0,
    pub const Range = struct {
        min: Version,
        max: Version,
        pub fn includesVersion(range: Range, version: Version) bool {
            if (range.min.order(version) == .gt) return false;
            if (range.max.order(version) == .lt) return false;
            return true;
        }
        pub fn isAtLeast(range: Range, version: Version) ?bool {
            if (range.min.order(version) != .lt) return true;
            if (range.max.order(version) == .lt) return false;
            return null;
        }
    };
    const Order = enum { lt, gt, eq };
    pub fn order(lhs: Version, rhs: Version) Order {
        if (lhs.major < rhs.major) return .lt;
        if (lhs.major > rhs.major) return .gt;
        if (lhs.minor < rhs.minor) return .lt;
        if (lhs.minor > rhs.minor) return .gt;
        if (lhs.patch < rhs.patch) return .lt;
        if (lhs.patch > rhs.patch) return .gt;
        return .eq;
    }
    pub fn parseVersion(text: []const u8) !Version {
        var i: usize = 0;
        var j: usize = 0;
        while (i < text.len) : (i += 1) {
            switch (text[i]) {
                '.' => if (j == 2) break else {
                    j += 1;
                },
                '0'...'9' => {},
                else => break,
            }
        }
        const digits: []const u8 = text[0..i];
        if (i == 0) return error.InvalidVersion;
        i = 0;
        const major: usize = blk: {
            while (i < digits.len and digits[i] != '.') i += 1;
            break :blk i;
        };
        i += 1;
        const minor: usize = blk: {
            while (i < digits.len and digits[i] != '.') i += 1;
            break :blk i;
        };
        const patch: u64 = digits.len;
        const major_digits: []const u8 = digits[0..major];
        const minor_digits: []const u8 =
            if (major +% 1 < minor) digits[major +% 1 .. minor] else "";
        const patch_digits: []const u8 =
            if (minor +% 1 < patch) digits[minor +% 1 .. patch] else "";
        const major_val: u64 = parse.ud(u64, major_digits);
        const minor_val: u64 = if (minor_digits.len != 0) parse.ud(u64, minor_digits) else 0;
        const patch_val: u64 = if (minor_digits.len != 0) parse.ud(u64, patch_digits) else 0;
        if (major_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (minor_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (patch_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (major_digits.len == 0) {
            return error.InvalidVersion;
        }
        return Version{
            .major = @intCast(u32, major_val),
            .minor = @intCast(u32, minor_val),
            .patch = @intCast(u32, patch_val),
        };
    }
};
pub const SourceLocation = Src();
pub const Mode = @TypeOf(config.zig.mode);
pub const Type = @TypeOf(@typeInfo(void));
pub const TypeId = @typeInfo(Type).Union.tag_type.?;
pub const Endian = @TypeOf(config.zig.cpu.arch.endian());
pub const Signedness = @TypeOf(@as(Type.Int, undefined).signedness);
pub const StackTrace = @typeInfo(@typeInfo(@TypeOf(@errorReturnTrace())).Optional.child).Pointer.child;
pub const CallingConvention = @TypeOf(@typeInfo(fn () noreturn).Fn.calling_convention);
fn Src() type {
    return @TypeOf(@src());
}
fn Overflow(comptime T: type) type {
    const S = struct { T, u1 };
    return S;
}
fn indexOfSentinel(any: anytype) usize {
    const T = @TypeOf(any);
    const type_info: Type = @typeInfo(T);
    if (type_info.Pointer.sentinel == null) {
        @compileError(@typeName(T));
    }
    const sentinel: type_info.Pointer.child =
        @ptrCast(*const type_info.Pointer.child, type_info.Pointer.sentinel.?).*;
    var idx: usize = 0;
    while (any[idx] != sentinel) idx +%= 1;
    return idx;
}
