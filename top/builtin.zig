pub const config = @import("./config.zig");

pub usingnamespace config;
pub usingnamespace @import("./static/memcpy.zig");
pub usingnamespace @import("./static/memset.zig");
pub usingnamespace @import("./static/zig_probe_stack.zig");

/// Return an absolute path to a project file.
pub fn absolutePath(comptime relative: [:0]const u8) [:0]const u8 {
    return @This().build_root.? ++ "/" ++ relative;
}
pub const Exception = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    ExactDivisionWithRemainder,
    UnexpectedValue,
};
/// `E` must be an error type.
pub fn InternalError(comptime E: type) type {
    static.assert(@typeInfo(E) == .ErrorSet);
    return union(enum) {
        /// Return this error for any exception
        throw: E,
        /// Abort the program for any exception
        abort,
        ignore,
        pub const Error = E;
    };
}
/// `E` must be an Enum type.
pub fn ExternalError(comptime E: type) type {
    static.assert(@typeInfo(E) == .Enum);
    static.assert(@hasDecl(E, "errorName"));
    return (struct {
        /// Throw error if unwrapping yields any of these values
        throw: ?[]const E = null,
        /// Abort the program if unwrapping yields any of these values
        abort: ?[]const E = null,
        pub const Enum = E;
    });
}
pub fn ZigError(comptime Value: type, comptime return_codes: []const Value, comptime catch_all: ?[]const u8) type {
    var error_set: []const Type.Error = &.{};
    for (return_codes) |error_code| {
        error_set = error_set ++ [1]Type.Error{.{ .name = error_code.errorName() }};
    }
    if (catch_all) |error_name| {
        error_set = error_set ++ [1]Type.Error{.{ .name = error_name }};
    }
    return @Type(.{ .ErrorSet = error_set });
}
/// Attempt to match a return value against a set of error codes--returning the
/// corresponding zig error on success.
pub fn zigErrorThrow(
    comptime Value: type,
    comptime values: []const Value,
    ret: isize,
    comptime catch_all: ?[]const u8,
) ZigError(Value, values, catch_all) {
    const Error = ZigError(Value, values, catch_all);
    inline for (values) |value| {
        if (ret == @enumToInt(value)) {
            return @field(Error, value.errorName());
        }
    }
    if (catch_all) |error_name| {
        return @field(Error, error_name);
    }
}
/// Attempt to match a return value against a set of error codes--aborting the
/// program on success.
/// This function is exceptional in this namespace for its use of system calls.
pub fn zigErrorAbort(
    comptime Value: type,
    comptime values: []const Value,
    ret: isize,
) void {
    inline for (values) |value| {
        if (ret == @enumToInt(value)) {
            var buf: [4608]u8 = undefined;
            debug.logAbort(&buf, value.errorName());
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
fn ArithWithOverflowReturn(comptime T: type) type {
    return struct {
        value: T,
        overflowed: bool,
    };
}
fn normalAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalAddReturn(T, arg1.*, arg2);
}
fn normalAddReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        debug.addCausedOverflowFault(T, arg1, arg2);
    }
    return result[0];
}
fn normalSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalSubReturn(T, arg1.*, arg2);
}
fn normalSubReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        debug.subCausedOverflowFault(T, arg1, arg2);
    }
    return result[0];
}
fn normalMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalMulReturn(T, arg1.*, arg2);
}
fn normalMulReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
    if (config.runtime_assertions and result[1] != 0) {
        debug.mulCausedOverflowFault(T, arg1, arg2);
    }
    return result[0];
}
fn exactDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = exactDivisionReturn(T, arg1.*, arg2);
}
fn exactDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: T = arg1 / arg2;
    const remainder: T = normalSubReturn(T, arg1, (result * arg2));
    if (config.runtime_assertions and remainder != 0) {
        debug.exactDivisionWithRemainderFault(T, arg1, arg2, result, remainder);
    }
    return result;
}
fn saturatingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +|= arg2;
}
fn saturatingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +| arg2;
}
fn saturatingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -|= arg2;
}
fn saturatingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -| arg2;
}
fn saturatingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *|= arg2;
}
fn saturatingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *| arg2;
}
fn wrappingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +%= arg2;
}
fn wrappingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +% arg2;
}
fn wrappingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -%= arg2;
}
fn wrappingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -% arg2;
}
fn wrappingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *%= arg2;
}
fn wrappingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *% arg2;
}
fn normalDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* /= arg2;
}
fn normalDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 / arg2;
}
fn normalOrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 | arg2;
}
fn normalOrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* |= arg2;
}
fn normalAndReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 & arg2;
}
fn normalAndAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* &= arg2;
}
fn normalXorReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 ^ arg2;
}
fn normalXorAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* ^= arg2;
}
fn normalShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 >> intCast(ShiftAmount(T), arg2);
}
fn normalShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* >>= intCast(ShiftAmount(T), arg2);
}
fn normalShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 << intCast(ShiftAmount(T), arg2);
}
fn normalShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* <<= intCast(ShiftAmount(T), arg2);
}
fn truncatedDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divTrunc(arg1.*, arg2);
}
fn truncatedDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divTrunc(arg1, arg2);
}
fn flooredDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divFloor(arg1.*, arg2);
}
fn flooredDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divFloor(arg1, arg2);
}
fn exactShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shrExact(arg1, intCast(ShiftAmount(T), arg2));
}
fn exactShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shrExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
fn exactShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shlExact(arg1, intCast(ShiftAmount(T), arg2));
}
fn exactShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shlExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
fn overflowingAddAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @addWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
fn overflowingAddReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @addWithOverflow(arg1, arg2);
}
fn overflowingSubAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @subWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
fn overflowingSubReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @subWithOverflow(arg1, arg2);
}
fn overflowingMulAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @mulWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
fn overflowingMulReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @mulWithOverflow(arg1, arg2);
}
fn overflowingShlAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @shlWithOverflow(arg1.*, intCast(ShiftAmount(T), arg2));
    arg1.* = result[0];
    return result[1] != 0;
}
fn overflowingShlReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
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

fn ptr(comptime T: type) *T {
    var ret: T = 0;
    return &ret;
}
const type_id: *comptime_int = ptr(comptime_int);
comptime {
    type_id.* = 0;
}
pub inline fn typeId(comptime _: type) comptime_int {
    const ret: comptime_int = type_id.*;
    type_id.* +%= 1;
    return ret;
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
pub fn nullPointer(comptime T: type) *allowzero T {
    return @intToPtr(*allowzero T, 0);
}
pub inline fn identity(any: anytype) @TypeOf(any) {
    return any;
}
pub inline fn equ(comptime T: type, dst: *T, src: T) void {
    dst.* = src;
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
fn testEqualUnion(comptime T: type, comptime union_info: Type.Union, arg1: T, arg2: T) bool {
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            const tag: tag_type = @field(tag_type, field.name);
            if (arg1 == tag) {
                if (arg2 != tag) {
                    return false;
                }
                if (!testEqual(
                    field.type,
                    @field(arg1, field.name),
                    @field(arg2, field.name),
                )) {
                    return false;
                }
            }
        }
        return true;
    }
    return testEqual(
        []const u8,
        @ptrCast(*const [@sizeOf(T)]u8, &arg1),
        @ptrCast(*const [@sizeOf(T)]u8, &arg2),
    );
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
        debug.logFault("assertion failed");
    }
}
pub fn assertBelow(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 >= arg2) {
        debug.comparisonFailedFault(T, " < ", arg1, arg2);
    }
}
pub fn assertBelowOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 > arg2) {
        debug.comparisonFailedFault(T, " <= ", arg1, arg2);
    }
}
pub fn assertEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and !testEqual(T, arg1, arg2)) {
        debug.comparisonFailedFault(T, " == ", arg1, arg2);
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and testEqual(T, arg1, arg2)) {
        debug.comparisonFailedFault(T, " != ", arg1, arg2);
    }
}
pub fn assertAboveOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 < arg2) {
        debug.comparisonFailedFault(T, " >= ", arg1, arg2);
    }
}
pub fn assertAbove(comptime T: type, arg1: T, arg2: T) void {
    if (config.runtime_assertions and arg1 <= arg2) {
        debug.comparisonFailedFault(T, " > ", arg1, arg2);
    }
}
const FaultExtra = struct {
    src: SourceLocation,
    about: ?[]const u8 = null,
};
pub fn expect(b: bool) Exception!void {
    if (!b) {
        return error.UnexpectedValue;
    }
}
pub fn expectBelow(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and arg1 >= arg2) {
        return debug.comparisonFailedException(T, " < ", arg1, arg2);
    }
}
pub fn expectBelowOrEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and arg1 > arg2) {
        return debug.comparisonFailedException(T, " <= ", arg1, arg2);
    }
}
pub fn expectEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and !testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedException(T, " == ", arg1, arg2);
    }
}
pub fn expectNotEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedException(T, " != ", arg1, arg2);
    }
}
pub fn expectAboveOrEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and arg1 < arg2) {
        return debug.comparisonFailedException(T, " >= ", arg1, arg2);
    }
}
pub fn expectAbove(comptime T: type, arg1: T, arg2: T) Exception!void {
    if (config.runtime_assertions and arg1 <= arg2) {
        return debug.comparisonFailedException(T, " > ", arg1, arg2);
    }
}
pub fn intToPtr(comptime P: type, address: u64) P {
    return @intToPtr(P, address);
}
pub fn intCast(comptime T: type, value: anytype) T {
    @setRuntimeSafety(false);
    const U: type = @TypeOf(value);
    if (@bitSizeOf(T) > @bitSizeOf(U)) {
        return value;
    }
    if (config.runtime_assertions and value > ~@as(T, 0)) {
        debug.intCastTruncatedBitsFault(T, U, value);
    }
    return @truncate(T, value);
}
pub const static = opaque {
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
pub fn shrA(comptime T: type, comptime U: type, value: T, comptime shift_amt: comptime_int) U {
    return @truncate(U, value >> shift_amt);
}
pub fn shrB(comptime T: type, comptime U: type, value: T, comptime shift_amt: comptime_int, comptime pop_count: comptime_int) U {
    return @truncate(U, value >> shift_amt) & ((@as(U, 1) << pop_count) -% 1);
}
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
pub const debug = opaque {
    pub const itos = fmt.dec;
    const size: usize = 4096;
    const about_fault_p0_s: []const u8 = "fault:          ";
    const about_error_p0_s: []const u8 = "error:          ";
    const about_fault_p1_s: []const u8 = " assertion failed: ";
    const about_error_p1_s: []const u8 = " unexpected result: ";

    fn aboutFault(comptime T: type) []const u8 {
        return about_fault_p0_s ++ @typeName(T);
    }
    fn aboutError(comptime T: type) []const u8 {
        return about_error_p0_s ++ @typeName(T);
    }
    fn comparisonFailedString(comptime T: type, about: []const u8, symbol: []const u8, buf: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const notation: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = writeMulti(buf, &[_][]const u8{
            about,                   " failed test: ",
            itos(T, arg1).readAll(), symbol,
            itos(T, arg2).readAll(), notation,
        });
        if (help_read) {
            if (arg1 > arg2) {
                len += writeMulti(buf[len..], &[_][]const u8{ itos(T, arg1 -% arg2).readAll(), symbol, "0\n" });
            } else {
                len += writeMulti(buf[len..], &[_][]const u8{ "0", symbol, itos(T, arg2 -% arg1).readAll(), "\n" });
            }
        }
        return len;
    }
    fn intCastTruncatedBitsString(comptime T: type, comptime U: type, buf: []u8, arg1: U) u64 {
        const minimum: T = 0;
        return writeMulti(buf, &[_][]const u8{
            about_fault_p0_s,            "integer cast truncated bits: ",
            itos(U, arg1).readAll(),     " greater than " ++ @typeName(T) ++ " maximum (",
            itos(T, ~minimum).readAll(), ")\n",
        });
    }
    fn subCausedOverflowString(comptime T: type, about: []const u8, msg: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += writeMulti(msg, &[_][]const u8{
            about,                   " integer overflow: ",
            itos(T, arg1).readAll(), " - ",
            itos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            len += writeMulti(msg[len..], &[_][]const u8{ "0 - ", itos(T, arg2 -% arg1).readAll(), "\n" });
        }
        return len;
    }
    fn addCausedOverflowString(comptime T: type, about: []const u8, msg: []u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += writeMulti(msg, &[_][]const u8{
            about,                   " integer overflow: ",
            itos(T, arg1).readAll(), " + ",
            itos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            const argl: T = ~@as(T, 0);
            const argr: T = (arg2 +% arg1) -% argl;
            len += writeMulti(msg[len..], &[_][]const u8{ itos(T, argl).readAll(), " + ", itos(T, argr).readAll(), "\n" });
        }
        return len;
    }
    fn mulCausedOverflowString(comptime T: type, about: []const u8, buf: []u8, arg1: T, arg2: T) u64 {
        return writeMulti(buf, &[_][]const u8{
            about,                   ": integer overflow: ",
            itos(T, arg1).readAll(), " * ",
            itos(T, arg2).readAll(), "\n",
        });
    }
    fn exactDivisionWithRemainderString(comptime T: type, about: []const u8, buf: []u8, arg1: T, arg2: T, result: T, remainder: T) u64 {
        return writeMulti(buf, &[_][]const u8{
            about,                        ": exact division had a remainder: ",
            itos(T, arg1).readAll(),      "/",
            itos(T, arg2).readAll(),      " == ",
            itos(T, result).readAll(),    "r",
            itos(T, remainder).readAll(), "\n",
        });
    }
    fn incorrectAlignmentString(comptime Pointer: type, about: []const u8, buf: []u8, address: usize, alignment: usize, remainder: u64) u64 {
        return writeMulti(buf, &[_][]const u8{
            about,                                     ": incorrect alignment: ",
            @typeName(Pointer),                        " align(",
            itos(u64, alignment).readAll(),            "): ",
            itos(u64, address).readAll(),              " == ",
            itos(u64, address -% remainder).readAll(), "+",
            itos(u64, remainder).readAll(),            "\n",
        });
    }
    fn intCastTruncatedBitsFault(comptime T: type, comptime U: type, arg: U) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.intCastTruncatedBitsString(T, U, &buf, arg);
        logFault(buf[0..len]);
    }
    fn subCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logError(buf[0..len]);
        return error.SubCausedOverflow;
    }
    fn subCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logFault(buf[0..len]);
    }
    fn addCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutError(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logError(buf[0..len]);
        return error.AddCausedOverflow;
    }
    fn addCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        logFault(buf[0..len]);
    }
    fn mulCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutError(T), &buf, arg1, arg2);
        logError(buf[0..len]);
        return error.MulCausedOverflow;
    }
    fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2);
        logFault(buf[0..len]);
    }
    fn exactDivisionWithRemainderException(comptime T: type, arg1: T, arg2: T, result: T, remainder: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutError(T), &buf, arg1, arg2, result, remainder);
        logError(buf[0..len]);
        return error.DivisionWithRemainder;
    }
    fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, remainder: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutFault(T), &buf, arg1, arg2, result, remainder);
        logFault(buf[0..len]);
    }
    fn incorrectAlignmentException(comptime T: type, address: usize, alignment: usize) Exception {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutError(T), &buf, address, alignment, remainder);
        logError(buf[0..len]);
        return error.IncorrectAlignment;
    }
    fn incorrectAlignmentFault(comptime T: type, address: usize, alignment: usize) noreturn {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutFault(T), &buf, address, alignment, remainder);
        logFault(buf[0..len]);
    }
    fn comparisonFailedException(comptime T: type, symbol: []const u8, arg1: T, arg2: T) Exception {
        @setCold(true);
        if (@typeInfo(T) == .Int) {
            var buf: [size]u8 = undefined;
            const len: u64 = comparisonFailedString(T, aboutError(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
            logError(buf[0..len]);
        }
        return error.UnexpectedValue;
    }
    fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: T, arg2: T) noreturn {
        @setCold(true);
        if (@typeInfo(T) == .Int) {
            var buf: [size]u8 = undefined;
            var len: u64 = comparisonFailedString(T, aboutFault(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
            logFault(buf[0..len]);
        } else {
            logFault("assertion failed");
        }
    }
    pub fn write(buf: []const u8) void {
        asm volatile (
            \\syscall
            :
            : [_] "{rax}" (1), // linux sys_write
              [_] "{rdi}" (2), // stderr
              [_] "{rsi}" (buf.ptr),
              [_] "{rdx}" (buf.len),
            : "rcx", "r11", "memory", "rax"
        );
    }
    fn name(buf: []u8) u64 {
        const rc: i64 = asm volatile (
            \\syscall
            : [rc] "={rax}" (-> isize),
            : [sysno] "{rax}" (89), // linux readlink
              [_] "{rdi}" ("/proc/self/exe"), // symlink to executable
              [_] "{rsi}" (buf.ptr), // message buf ptr
              [_] "{rdx}" (buf.len), // message buf len
            : "rcx", "r11", "memory"
        );
        return if (rc < 0) ~@as(u64, 0) else @intCast(u64, rc);
    }
    fn abort() noreturn {
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (60), // linux sys_exit
              [arg1] "{rdi}" (2), // exit code
        );
        unreachable;
    }
    // At the time of writing, this function benefits from inlining but
    // writeMulti does not.
    pub inline fn writeMany(buf: []u8, s: []const u8) u64 {
        for (s, 0..) |c, i| buf[i] = c;
        return s.len;
    }
    pub fn writeMulti(buf: []u8, ss: []const []const u8) u64 {
        var len: u64 = 0;
        for (ss) |s| {
            for (s, 0..) |c, i| buf[len +% i] = c;
            len +%= s.len;
        }
        return len;
    }
    pub inline fn logAlways(buf: []const u8) void {
        write(buf);
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
    pub inline fn logFault(buf: []const u8) noreturn {
        if (config.logging_general.Fault) write(buf);
        abort();
    }
    pub fn logAbort(buf: []u8, symbol: []const u8) noreturn {
        var len: u64 = 0;
        len +%= writeMany(buf[len..], about_error_p0_s);
        len +%= about_error_p0_s.len;
        len +%= name(buf[len..]);
        len +%= writeMulti(buf[len..], &[_][]const u8{ " (", symbol, ")\n" });
        logFault(buf[0..len]);
    }
    pub inline fn logAlwaysAIO(buf: []u8, slices: []const []const u8) void {
        write(buf[0..writeMulti(buf, slices)]);
    }
    pub inline fn logSuccessAIO(buf: []u8, slices: []const []const u8) void {
        if (config.logging_general.Success) write(buf[0..writeMulti(buf, slices)]);
    }
    pub inline fn logAcquireAIO(buf: []u8, slices: []const []const u8) void {
        if (config.logging_general.Acquire) write(buf[0..writeMulti(buf, slices)]);
    }
    pub inline fn logReleaseAIO(buf: []u8, slices: []const []const u8) void {
        if (config.logging_general.Release) write(buf[0..writeMulti(buf, slices)]);
    }
    pub inline fn logErrorAIO(buf: []u8, slices: []const []const u8) void {
        if (config.logging_general.Error) write(buf[0..writeMulti(buf, slices)]);
    }
    pub inline fn logFaultAIO(buf: []u8, slices: []const []const u8) noreturn {
        if (config.logging_general.Fault) write(buf[0..writeMulti(buf, slices)]);
        abort();
    }

    const static = opaque {
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
                var msg: [size]u8 = undefined;
                var len: u64 = 0;
                for ([_][]const u8{
                    @typeName(T),                 ": exact division had a remainder: ",
                    itos(T, arg1).readAll(),      "/",
                    itos(T, arg2).readAll(),      " == ",
                    itos(T, result).readAll(),    "r",
                    itos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s, 0..) |c, i| msg[len +% i] = c;
                    len +%= s.len;
                }
                @compileError(msg[0..len]);
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
                var msg: [size]u8 = undefined;
                var len: u64 = 0;
                for ([_][]const u8{
                    @typeName(T),                 ": incorrect alignment: ",
                    type_name,                    " align(",
                    itos(T, alignment).readAll(), "): ",
                    itos(T, address).readAll(),   " == ",
                    itos(T, result).readAll(),    "+",
                    itos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s, 0..) |c, i| msg[len +% i] = c;
                    len +%= s.len;
                }
                @compileError(msg[0..len]);
            }
        }
        fn comparisonFailed(
            comptime T: type,
            comptime symbol: []const u8,
            comptime arg1: T,
            comptime arg2: T,
        ) void {
            comptime {
                var buf: [size]u8 = undefined;
                var len: u64 = writeMulti(&buf, &[_][]const u8{
                    @typeName(T),            " assertion failed: ",
                    itos(T, arg1).readAll(), symbol,
                    itos(T, arg2).readAll(), if (@min(arg1, arg2) > 10_000) ", i.e. " else "\n",
                });
                if (@min(arg1, arg2) > 10_000) {
                    if (arg1 > arg2) {
                        len += writeMulti(buf[len..], &[_][]const u8{ itos(T, arg1 -% arg2).readAll(), symbol, "0\n" });
                    } else {
                        len += writeMulti(buf[len..], &[_][]const u8{ "0", symbol, itos(T, arg2 -% arg1).readAll(), "\n" });
                    }
                }
                @compileError(buf[0..len]);
            }
        }
    };
};
pub const parse = opaque {
    pub const Error = error{BadParse};
    pub const error_policy: *InternalError(Error) = createErrorPolicy(parse, .{ .throw = Error.BadParse });

    pub fn ub(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = comptime sigFigList(T, 2);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 8);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ux(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = comptime sigFigList(T, 16);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 2);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 8);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 10);
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
        const sig_fig_list: []const T = comptime sigFigList(T, 16);
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
    pub fn fromSymbol(c: u8, radix: u16) u8 {
        if (radix > 10) {
            return switch (c) {
                '0'...'9' => c -% ('9' -% 0x9),
                'a'...'f' => c -% ('f' -% 0xf),
                else => 0,
            };
        } else {
            return c -% ('9' -% 9);
        }
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
    fn sigFigList(comptime T: type, comptime radix: u16) []const T {
        var value: T = 0;
        var ret: []const T = &.{};
        while (nextSigFig(T, value, radix)) |next| {
            ret = ret ++ [1]T{value};
            value = next;
        } else {
            ret = ret ++ [1]T{value};
        }
        return ret;
    }
    pub fn any(comptime T: type, any_str: anytype) !T {
        const str: []const u8 = blk: {
            if (@TypeOf(any_str) == [*:0]u8) {
                var len: u64 = 0;
                while (any_str[len] != 0) len +%= 1;
                break :blk any_str[0..len :0];
            } else {
                break :blk any_str;
            }
        };
        const signed: bool = str[0] == '-';
        if (signed and @typeInfo(T).Int.signedness == .unsigned) {
            return Error.BadParse;
        }
        var idx: u64 = int(u64, signed);
        const zero: bool = str[idx] == '0';
        idx += int(u64, zero);
        if (idx == str.len) {
            return 0;
        }
        switch (str[idx]) {
            'b' => {
                return parseValidate(T, str[idx +% 1 ..], 2);
            },
            'o' => {
                return parseValidate(T, str[idx +% 1 ..], 8);
            },
            'x' => {
                return parseValidate(T, str[idx +% 1 ..], 16);
            },
            else => {
                return parseValidate(T, str[idx..], 10);
            },
        }
    }
    fn parseValidate(comptime T: type, str: []const u8, comptime radix: u16) !T {
        const sig_fig_list: []const T = comptime sigFigList(T, radix);
        var idx: u64 = 0;
        var value: T = 0;
        switch (radix) {
            2 => while (idx != str.len) : (idx +%= 1) {
                switch (str[idx]) {
                    '0'...'1' => {
                        value +%= fromSymbol(str[idx], 2) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return Error.BadParse;
                    },
                }
            },
            8 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'7' => {
                        value +%= fromSymbol(str[idx], 8) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return Error.BadParse;
                    },
                }
            },
            10 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'9' => {
                        value +%= fromSymbol(str[idx], 10) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return Error.BadParse;
                    },
                }
            },
            16 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'9', 'a'...'f' => {
                        value +%= fromSymbol(str[idx], 16) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return Error.BadParse;
                    },
                }
            },
            else => unreachable,
        }
        return value;
    }
};
pub const fmt = opaque {
    fn StaticStringMemo(comptime max_len: u64) type {
        return struct {
            auto: [max_len]u8 align(8),
            len: u64 = max_len,
            const Array = @This();
            fn init() Array {
                var ret: Array = undefined;
                ret.len = max_len;
                return ret;
            }
            fn writeOneBackwards(array: *Array, v: u8) void {
                array.len -%= 1;
                array.auto[array.len] = v;
            }
            pub fn readAll(array: *const Array) []const u8 {
                return array.auto[array.len..];
            }
        };
    }
    fn StaticString(comptime T: type, comptime radix: u16) type {
        return StaticStringMemo(maxSigFig(T, radix) +% 1);
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
    pub fn int(value: anytype) StaticString(@TypeOf(value), 10) {
        if (@sizeOf(@TypeOf(value)) == 0) {
            return ci(value);
        }
        return dec(@TypeOf(value), value);
    }
    pub fn bin(comptime Int: type, value: Int) StaticString(Int, 2) {
        const Array = StaticString(Int, 2);
        const Abs = Absolute(Int);
        var array: Array = Array.init();
        if (value == 0) {
            while (array.len != 3) {
                array.writeOneBackwards('0');
            }
            array.writeOneBackwards('b');
            array.writeOneBackwards('0');
            return array;
        }
        var abs_value: Abs = absoluteValue(Int, Abs, value);
        while (abs_value != 0) : (abs_value /= 2) {
            array.writeOneBackwards(toSymbol(Abs, abs_value, 2));
        }
        while (array.len != 3) {
            array.writeOneBackwards('0');
        }
        array.writeOneBackwards('b');
        array.writeOneBackwards('0');
        if (value < 0) {
            array.writeOneBackwards('-');
        }
        return array;
    }
    pub fn oct(comptime Int: type, value: Int) StaticString(Int, 8) {
        const Array = StaticString(Int, 8);
        const Abs = Absolute(Int);
        var array: Array = Array.init();
        if (value == 0) {
            array.writeOneBackwards('0');
            array.writeOneBackwards('o');
            array.writeOneBackwards('0');
            return array;
        }
        var abs_value: Abs = absoluteValue(Int, Abs, value);
        while (abs_value != 0) : (abs_value /= 8) {
            array.writeOneBackwards(toSymbol(Abs, abs_value, 8));
        }
        array.writeOneBackwards('o');
        array.writeOneBackwards('0');
        if (value < 0) {
            array.writeOneBackwards('-');
        }
        return array;
    }
    pub fn dec(comptime Int: type, value: Int) StaticString(Int, 10) {
        const Array = StaticString(Int, 10);
        const Abs = Absolute(Int);
        var array: Array = Array.init();
        if (value == 0) {
            array.writeOneBackwards('0');
            return array;
        }
        var abs_value: Abs = absoluteValue(Int, Abs, value);
        while (abs_value != 0) : (abs_value /= 10) {
            array.writeOneBackwards(toSymbol(Abs, abs_value, 10));
        }
        if (value < 0) {
            array.writeOneBackwards('-');
        }
        return array;
    }
    pub fn hex(comptime Int: type, value: Int) StaticString(Int, 16) {
        const Array = StaticString(Int, 16);
        const Abs = Absolute(Int);
        var array: Array = Array.init();
        if (value == 0) {
            array.writeOneBackwards('0');
            array.writeOneBackwards('x');
            array.writeOneBackwards('0');
            return array;
        }
        var abs_value: Abs = absoluteValue(Int, Abs, value);
        while (abs_value != 0) : (abs_value /= 16) {
            array.writeOneBackwards(toSymbol(Abs, abs_value, 16));
        }
        array.writeOneBackwards('x');
        array.writeOneBackwards('0');
        if (value < 0) {
            array.writeOneBackwards('-');
        }
        return array;
    }
    pub fn ub8(value: u8) StaticString(u8, 2) {
        return bin(u8, value);
    }
    pub fn ub16(value: u16) StaticString(u16, 2) {
        return bin(u16, value);
    }
    pub fn ub32(value: u32) StaticString(u32, 2) {
        return bin(u32, value);
    }
    pub fn ub64(value: u64) StaticString(u64, 2) {
        return bin(u64, value);
    }
    pub fn ubsize(value: usize) StaticString(usize, 2) {
        return bin(usize, value);
    }
    pub fn uo8(value: u8) StaticString(u8, 8) {
        return oct(u8, value);
    }
    pub fn uo16(value: u16) StaticString(u16, 8) {
        return oct(u16, value);
    }
    pub fn uo32(value: u32) StaticString(u32, 8) {
        return oct(u32, value);
    }
    pub fn uo64(value: u64) StaticString(u64, 8) {
        return oct(u64, value);
    }
    pub fn uosize(value: usize) StaticString(usize, 8) {
        return oct(usize, value);
    }
    pub fn ud8(value: u8) StaticString(u8, 10) {
        return dec(u8, value);
    }
    pub fn ud16(value: u16) StaticString(u16, 10) {
        return dec(u16, value);
    }
    pub fn ud32(value: u32) StaticString(u32, 10) {
        return dec(u32, value);
    }
    pub fn ud64(value: u64) StaticString(u64, 10) {
        return dec(u64, value);
    }
    pub fn udsize(value: usize) StaticString(usize, 10) {
        return dec(usize, value);
    }
    pub fn ux8(value: u8) StaticString(u8, 16) {
        return hex(u8, value);
    }
    pub fn ux16(value: u16) StaticString(u16, 16) {
        return hex(u16, value);
    }
    pub fn ux32(value: u32) StaticString(u32, 16) {
        return hex(u32, value);
    }
    pub fn ux64(value: u64) StaticString(u64, 16) {
        return hex(u64, value);
    }
    pub fn uxsize(value: usize) StaticString(usize, 16) {
        return hex(usize, value);
    }
    pub fn ib8(value: i8) StaticString(i8, 2) {
        return bin(i8, value);
    }
    pub fn ib16(value: i16) StaticString(i16, 2) {
        return bin(i16, value);
    }
    pub fn ib32(value: i32) StaticString(i32, 2) {
        return bin(i32, value);
    }
    pub fn ib64(value: i64) StaticString(i64, 2) {
        return bin(i64, value);
    }
    pub fn ibsize(value: isize) StaticString(isize, 2) {
        return bin(isize, value);
    }
    pub fn io8(value: i8) StaticString(i8, 8) {
        return oct(i8, value);
    }
    pub fn io16(value: i16) StaticString(i16, 8) {
        return oct(i16, value);
    }
    pub fn io32(value: i32) StaticString(i32, 8) {
        return oct(i32, value);
    }
    pub fn io64(value: i64) StaticString(i64, 8) {
        return oct(i64, value);
    }
    pub fn iosize(value: isize) StaticString(isize, 8) {
        return oct(isize, value);
    }
    pub fn id8(value: i8) StaticString(i8, 10) {
        return dec(i8, value);
    }
    pub fn id16(value: i16) StaticString(i16, 10) {
        return dec(i16, value);
    }
    pub fn id32(value: i32) StaticString(i32, 10) {
        return dec(i32, value);
    }
    pub fn id64(value: i64) StaticString(i64, 10) {
        return dec(i64, value);
    }
    pub fn idsize(value: isize) StaticString(isize, 10) {
        return dec(isize, value);
    }
    pub fn ix8(value: i8) StaticString(i8, 16) {
        return hex(i8, value);
    }
    pub fn ix16(value: i16) StaticString(i16, 16) {
        return hex(i16, value);
    }
    pub fn ix32(value: i32) StaticString(i32, 16) {
        return hex(i32, value);
    }
    pub fn ix64(value: i64) StaticString(i64, 16) {
        return hex(i64, value);
    }
    pub fn ixsize(value: isize) StaticString(isize, 16) {
        return hex(isize, value);
    }

    fn Absolute(comptime Int: type) type {
        return @Type(.{ .Int = .{
            .bits = @max(@bitSizeOf(Int), 8),
            .signedness = .unsigned,
        } });
    }
    fn Real(comptime Int: type) type {
        return @Type(.{ .Int = .{
            .bits = @max(@bitSizeOf(Int), 8),
            .signedness = @typeInfo(Int).Int.signedness,
        } });
    }
    fn absoluteValue(comptime Int: type, comptime Abs: type, i: Real(Int)) Abs {
        return if (i < 0) 1 +% ~@bitCast(Abs, i) else @bitCast(Abs, i);
    }
    fn maxSigFig(comptime T: type, radix: u16) u16 {
        const U = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        var value: U = 0;
        var len: u16 = 0;
        if (radix != 10) {
            len += 2;
        }
        value -%= 1;
        while (value != 0) : (len += 1) value /= radix;
        return len;
    }
    pub fn length(comptime U: type, abs_value: U, radix: anytype) usize {
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
    pub fn toSymbol(comptime T: type, value: T, radix: u16) u8 {
        if (@bitSizeOf(T) < 8) {
            return toSymbol(u8, value, radix);
        }
        const result: u8 = @intCast(u8, @rem(value, @intCast(T, radix)));
        const d: u8 = '9' -% 9;
        const x: u8 = 'f' -% 15;
        if (radix > 10) {
            return result +% if (result < 10) d else x;
        } else {
            return result +% d;
        }
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
pub const Endian = @TypeOf(@This().cpu.arch.endian());
pub const Signedness = @TypeOf(@as(Type.Int, undefined).signedness);
pub const CallingConvention = @TypeOf(@typeInfo(fn () noreturn).Fn.calling_convention);
fn Src() type {
    return @TypeOf(@src());
}
fn Overflow(comptime T: type) type {
    return struct { T, u1 };
}
