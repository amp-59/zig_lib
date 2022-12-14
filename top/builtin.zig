pub const root = @import("root");
pub const zig = @import("builtin");

pub const native_endian = zig.cpu.arch.endian();
pub const is_little: bool = native_endian == .Little;
pub const is_big: bool = native_endian == .Big;

pub const is_debug: bool = config("is_debug", bool, zig.mode == .Debug);
pub const is_safe: bool = config("is_safe", bool, zig.mode == .ReleaseSafe);
pub const is_small: bool = config("is_small", bool, zig.mode == .ReleaseSmall);
pub const is_fast: bool = config("is_fast", bool, zig.mode == .ReleaseFast);

/// Perform runtime assertions
pub const is_correct: bool = config("is_correct", bool, is_debug or is_safe);
pub const is_perf: bool = config("is_perf", bool, is_small or is_fast);
/// Report succesful actions
pub const is_verbose: bool = config("is_verbose", bool, is_debug);
pub const is_tolerant: bool = config("is_tolerant", bool, is_debug);
pub const build_root: ?[:0]const u8 = config("build_root", ?[:0]const u8, null);

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
pub const Endian = @TypeOf(zig.cpu.arch.endian());
pub const SourceLocation = Src();
fn Src() type {
    return @TypeOf(@src());
}

pub const Exception = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    ExactDivisionWithRemainder,
    UnexpectedValue,
};

pub const lib_build_root: [:0]const u8 = blk: {
    const symbol: [:0]const u8 = "build_root";
    if (@hasDecl(root, symbol)) {
        break :blk @field(root, symbol);
    }
    if (@hasDecl(@cImport({}), symbol)) {
        break :blk @field(@cImport({}), symbol);
    }
    @compileError("program requires build direction: build_root");
};
pub fn config(comptime symbol: []const u8, comptime T: type, default: anytype) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    }
    if (@hasDecl(@cImport({}), symbol)) {
        const command = @field(@cImport({}), symbol);
        if (T == bool) {
            return @bitCast(T, @as(u1, command));
        }
        return command;
    }
    return default;
}
pub fn BitCount(comptime T: type) type {
    if (@sizeOf(T) == 0) {
        return comptime_int;
    }
    const bits: T = @bitSizeOf(T);
    return @Type(.{ .Int = .{
        .bits = bits - @clz(bits),
        .signedness = .unsigned,
    } });
}
pub fn ShiftAmount(comptime V: type) type {
    if (@sizeOf(V) == 0) {
        return comptime_int;
    }
    const bits: V = @bitSizeOf(V);
    return @Type(.{ .Int = .{
        .bits = bits - @clz(bits - 1),
        .signedness = .unsigned,
    } });
}
pub fn ShiftValue(comptime A: type) type {
    if (@sizeOf(A) == 0) {
        return comptime_int;
    }
    const bits: A = ~@as(A, 0);
    return @Type(.{ .Int = .{
        .bits = bits + 1,
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
pub fn int(comptime T: type, value: bool) T {
    return @boolToInt(value);
}
pub fn int2a(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @boolToInt(value1) & @boolToInt(value2);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return @intCast(T, ret);
    }
}
pub fn int2v(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @boolToInt(value1) | @boolToInt(value2);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return @intCast(T, ret);
    }
}
pub fn int3a(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @boolToInt(value1) & @boolToInt(value2) & @boolToInt(value3);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return @intCast(T, ret);
    }
}
pub fn int3v(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @boolToInt(value1) | @boolToInt(value2) | @boolToInt(value3);
    if (T == bool) {
        return @bitCast(bool, ret);
    } else {
        return @intCast(T, ret);
    }
}
fn ArithWithOverflowReturn(comptime T: type) type {
    return struct {
        value: T,
        overflowed: bool,
    };
}
inline fn normalAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalAddReturn(T, arg1.*, arg2);
}
inline fn normalAddReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: ArithWithOverflowReturn(T) = overflowingAddReturn(T, arg1, arg2);
    if (is_debug and result.overflowed) {
        debug.addCausedOverflowFault(T, arg1, arg2);
    }
    return result.value;
}
inline fn normalSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalSubReturn(T, arg1.*, arg2);
}
inline fn normalSubReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: ArithWithOverflowReturn(T) = overflowingSubReturn(T, arg1, arg2);
    if (is_debug and result.overflowed) {
        debug.subCausedOverflowFault(T, arg1, arg2);
    }
    return result.value;
}
inline fn normalMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalMulReturn(T, arg1.*, arg2);
}
inline fn normalMulReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: ArithWithOverflowReturn(T) = overflowingMulReturn(T, arg1, arg2);
    if (is_debug and result.overflowed) {
        debug.mulCausedOverflowFault(T, arg1, arg2);
    }
    return result.value;
}
inline fn exactDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = exactDivisionReturn(T, arg1.*, arg2);
}
inline fn exactDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: T = arg1 / arg2;
    const rem: T = normalSubReturn(T, arg1, (result * arg2));
    if (is_debug and rem != 0) {
        debug.exactDivisionWithRemainderFault(T, arg1, arg2, result, rem);
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
    return arg1 >> @intCast(ShiftAmount(T), arg2);
}
inline fn normalShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* >>= @intCast(ShiftAmount(T), arg2);
}
inline fn normalShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 << @intCast(ShiftAmount(T), arg2);
}
inline fn normalShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* <<= @intCast(ShiftAmount(T), arg2);
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
    return @shrExact(arg1, @intCast(ShiftAmount(T), arg2));
}
inline fn exactShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shrExact(arg1.*, @intCast(ShiftAmount(T), arg2));
}
inline fn exactShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shlExact(arg1, @intCast(ShiftAmount(T), arg2));
}
inline fn exactShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shlExact(arg1.*, @intCast(ShiftAmount(T), arg2));
}
inline fn overflowingAddAssign(comptime T: type, arg1: *T, arg2: T) bool {
    return @addWithOverflow(T, arg1.*, arg2, arg1);
}
inline fn overflowingAddReturn(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
    var result: T = undefined;
    const overflowed: bool = @addWithOverflow(T, arg1, arg2, &result);
    return .{
        .overflowed = overflowed,
        .value = result,
    };
}
inline fn overflowingSubAssign(comptime T: type, arg1: *T, arg2: T) bool {
    return @subWithOverflow(T, arg1.*, arg2, arg1);
}
inline fn overflowingSubReturn(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
    var result: T = undefined;
    const overflowed: bool = @subWithOverflow(T, arg1, arg2, &result);
    return .{
        .overflowed = overflowed,
        .value = result,
    };
}
inline fn overflowingMulAssign(comptime T: type, arg1: *T, arg2: T) bool {
    return @mulWithOverflow(T, arg1.*, arg2, arg1);
}
inline fn overflowingMulReturn(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
    var result: T = undefined;
    const overflowed: bool = @mulWithOverflow(T, arg1, arg2, &result);
    return .{
        .overflowed = overflowed,
        .value = result,
    };
}
inline fn overflowingShlReturn(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
    var result: T = undefined;
    const overflowed: bool = @shlWithOverflow(T, arg1, @intCast(ShiftAmount(T), arg2), &result);
    return .{
        .overflowed = overflowed,
        .value = result,
    };
}
inline fn overflowingShlAssign(comptime T: type, arg1: *T, arg2: T) bool {
    return @shlWithOverflow(T, arg1.*, @intCast(ShiftAmount(T), arg2), arg1);
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
pub fn addWithOverflow(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
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
pub fn subWithOverflow(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
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
pub fn mulWithOverflow(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
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
pub fn shlWithOverflow(comptime T: type, arg1: T, arg2: T) ArithWithOverflowReturn(T) {
    return overflowingShlReturn(T, arg1, arg2);
}
pub fn shlEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingShlAssign(T, arg1, arg2);
}
pub fn min(comptime T: type, arg1: T, arg2: T) T {
    return @min(arg1, arg2);
}
pub fn max(comptime T: type, arg1: T, arg2: T) T {
    return @max(arg1, arg2);
}
pub inline fn isComptime() bool {
    var b: bool = false;
    return @TypeOf(if (b) @as(u32, 0) else @as(u8, 0)) == u8;
}
pub fn assert(b: bool) void {
    if (!b) {
        @panic("assertion failed");
    }
}
pub fn assertBelow(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 < arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " < ", arg1, arg2);
    }
}
pub fn assertBelowOrEqual(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 <= arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " <= ", arg1, arg2);
    }
}
pub fn assertEqual(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 == arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " == ", arg1, arg2);
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 != arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " != ", arg1, arg2);
    }
}
pub fn assertAboveOrEqual(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 >= arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " >= ", arg1, arg2);
    }
}
pub fn assertAbove(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = arg1 > arg2;
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " > ", arg1, arg2);
    }
}

pub fn expect(b: bool) Exception!void {
    if (!b) {
        return error.UnexpectedValue;
    }
}
pub fn expectBelow(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 < arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " < ", arg1, arg2);
    }
}
pub fn expectBelowOrEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 <= arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " <= ", arg1, arg2);
    }
}
pub fn expectEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 == arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " == ", arg1, arg2);
    }
}
pub fn expectNotEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 != arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " != ", arg1, arg2);
    }
}
pub fn expectAboveOrEqual(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 >= arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " >= ", arg1, arg2);
    }
}
pub fn expectAbove(comptime T: type, arg1: T, arg2: T) Exception!void {
    const result: bool = arg1 > arg2;
    if (is_correct and !result) {
        return debug.comparisonFailedException(T, " > ", arg1, arg2);
    }
}
pub fn intToPtr(comptime Pointer: type, address: u64) Pointer {
    if (is_correct) {
        const alignment: u64 = @typeInfo(Pointer).Pointer.alignment;
        if (address & (alignment -% 1) != 0) {
            debug.incorrectAlignmentFault(Pointer, address, alignment);
        }
    }
    return @intToPtr(Pointer, address);
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
    inline fn normalAddAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: ArithWithOverflowReturn(T) = overflowingAddReturn(T, arg1.*, arg2);
        if (is_debug and result.overflowed) {
            debug.static.addCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result.value;
    }
    inline fn normalAddReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: ArithWithOverflowReturn(T) = overflowingAddReturn(T, arg1, arg2);
        if (is_debug and result.overflowed) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        }
        return result.value;
    }
    inline fn normalSubAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: ArithWithOverflowReturn(T) = overflowingSubReturn(T, arg1.*, arg2);
        if (is_debug and arg1.* < arg2) {
            debug.static.subCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result.value;
    }
    inline fn normalSubReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: ArithWithOverflowReturn(T) = overflowingSubReturn(T, arg1, arg2);
        if (is_debug and result.overflowed) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        }
        return result.value;
    }
    inline fn normalMulAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: ArithWithOverflowReturn(T) = overflowingMulReturn(T, arg1.*, arg2);
        if (is_debug and result.overflowed) {
            debug.static.mulCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result.value;
    }
    inline fn normalMulReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: ArithWithOverflowReturn(T) = overflowingMulReturn(T, arg1, arg2);
        if (is_debug and result.overflowed) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        }
        return result.value;
    }
    inline fn exactDivisionAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: T = arg1.* / arg2;
        const rem: T = static.normalSubReturn(T, arg1.*, (result * arg2));
        if (is_debug and rem != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1.*, arg2, result, rem);
        }
        arg1.* = result;
    }
    inline fn exactDivisionReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: T = arg1 / arg2;
        const rem: T = static.normalSubReturn(T, arg1, (result * arg2));
        if (is_debug and rem != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1, arg2, result, rem);
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
        const result: bool = arg1 < arg2;
        if (!result and is_correct) {
            debug.static.comparisonFailed(T, " < ", arg1, arg2);
        }
    }
    pub fn assertBelowOrEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        const result: bool = arg1 <= arg2;
        if (!result and is_correct) {
            debug.static.comparisonFailed(T, " <= ", arg1, arg2);
        }
    }
    pub fn assertEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        const result: bool = arg1 == arg2;
        if (!result and is_correct) {
            debug.static.comparisonFailed(T, " == ", arg1, arg2);
        }
    }
    pub fn assertNotEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        const result: bool = arg1 != arg2;
        if (is_correct and !result) {
            debug.static.comparisonFailed(T, " != ", arg1, arg2);
        }
    }
    pub fn assertAboveOrEqual(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        const result: bool = arg1 >= arg2;
        if (!result and is_correct) {
            debug.static.comparisonFailed(T, " >= ", arg1, arg2);
        }
    }
    pub fn assertAbove(comptime T: type, comptime arg1: T, comptime arg2: T) void {
        const result: bool = arg1 > arg2;
        if (!result and is_correct) {
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
const debug = opaque {
    const tos = fmt.ud;
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
    fn write(msg: []u8, ss: []const []const u8) u64 {
        var len: u64 = 0;
        for (ss) |s| {
            for (s) |c, i| msg[len +% i] = c;
            len +%= s.len;
        }
        return len;
    }
    fn comparisonFailedString(comptime T: type, about: []const u8, symbol: []const u8, buf: *[size]u8, arg1: T, arg2: T, help_read: bool) u64 {
        const notation: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = write(buf, &[_][]const u8{
            about,                  " failed test: ",
            tos(T, arg1).readAll(), symbol,
            tos(T, arg2).readAll(), notation,
        });
        if (help_read) {
            if (arg1 > arg2) {
                len += write(buf[len..], &[_][]const u8{ tos(T, arg1 - arg2).readAll(), symbol, "0\n" });
            } else {
                len += write(buf[len..], &[_][]const u8{ "0", symbol, tos(T, arg2 - arg1).readAll(), "\n" });
            }
        }
        return len;
    }
    fn subCausedOverflowString(comptime T: type, about: []const u8, msg: *[size]u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += write(msg, &[_][]const u8{
            about,                  " integer overflow: ",
            tos(T, arg1).readAll(), " - ",
            tos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            len += write(msg[len..], &[_][]const u8{ "0 - ", tos(T, arg2 - arg1).readAll(), "\n" });
        }
        return len;
    }
    fn addCausedOverflowString(comptime T: type, about: []const u8, msg: *[size]u8, arg1: T, arg2: T, help_read: bool) u64 {
        const endl: []const u8 = if (help_read) ", i.e. " else "\n";
        var len: u64 = 0;
        len += write(msg, &[_][]const u8{
            about,                  " integer overflow: ",
            tos(T, arg1).readAll(), " + ",
            tos(T, arg2).readAll(), endl,
        });
        if (help_read) {
            const argl: T = ~@as(T, 0);
            const argr: T = (arg2 +% arg1) -% argl;
            len += write(msg[len..], &[_][]const u8{ tos(T, argl).readAll(), " + ", tos(T, argr).readAll(), "\n" });
        }
        return len;
    }
    fn mulCausedOverflowString(comptime T: type, about: []const u8, buf: *[size]u8, arg1: T, arg2: T) u64 {
        return write(buf, &[_][]const u8{
            about,                  ": integer overflow: ",
            tos(T, arg1).readAll(), " * ",
            tos(T, arg2).readAll(), "\n",
        });
    }
    fn exactDivisionWithRemainderString(comptime T: type, about: []const u8, buf: *[size]u8, arg1: T, arg2: T, result: T, rem: T) u64 {
        return write(buf, &[_][]const u8{
            about,                    ": exact division had a remainder: ",
            tos(T, arg1).readAll(),   "/",
            tos(T, arg2).readAll(),   " == ",
            tos(T, result).readAll(), "r",
            tos(T, rem).readAll(),    "\n",
        });
    }
    fn incorrectAlignmentString(comptime Pointer: type, about: []const u8, buf: *[size]u8, address: usize, alignment: usize, rem: u64) u64 {
        return write(buf, &[_][]const u8{
            about,                             ": incorrect alignment: ",
            @typeName(Pointer),                " align(",
            tos(u64, alignment).readAll(),     "): ",
            tos(u64, address).readAll(),       " == ",
            tos(u64, address - rem).readAll(), "+",
            tos(u64, rem).readAll(),           "\n",
        });
    }
    noinline fn subCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.SubCausedOverflow;
    }
    noinline fn subCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
    }
    noinline fn addCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutError(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.AddCausedOverflow;
    }
    noinline fn addCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
    }
    noinline fn mulCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutError(T), &buf, arg1, arg2);
        print(buf[0..len]);
        return error.MulCausedOverflow;
    }
    noinline fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2);
        panic(buf[0..len]);
    }
    noinline fn exactDivisionWithRemainderException(comptime T: type, arg1: T, arg2: T, result: T, rem: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutError(T), &buf, arg1, arg2, result, rem);
        print(buf[0..len]);
        return error.DivisionWithRemainder;
    }
    noinline fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, rem: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutFault(T), &buf, arg1, arg2, result, rem);
        panic(buf[0..len]);
    }
    noinline fn incorrectAlignmentException(comptime T: type, address: usize, alignment: usize) Exception {
        @setCold(true);
        const rem: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutError(T), &buf, address, alignment, rem);
        print(buf[0..len]);
        return error.IncorrectAlignment;
    }
    noinline fn incorrectAlignmentFault(comptime T: type, address: usize, alignment: usize) noreturn {
        @setCold(true);
        const rem: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutFault(T), &buf, address, alignment, rem);
        panic(buf[0..len]);
    }
    noinline fn comparisonFailedException(comptime T: type, symbol: []const u8, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = comparisonFailedString(T, aboutError(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.UnexpectedValue;
    }
    noinline fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        var len: u64 = comparisonFailedString(T, aboutFault(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
    }
    const static = opaque {
        fn subCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            var msg: [size]u8 = undefined;
            @compileError(msg[0..debug.overflowedSubString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
        fn addCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            var msg: [size]u8 = undefined;
            @compileError(msg[0..debug.overflowedAddString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
        fn mulCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
            var msg: [size]u8 = undefined;
            @compileError(msg[0..debug.mulCausedOverflowString(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
        fn exactDivisionWithRemainder(
            comptime T: type,
            comptime arg1: T,
            comptime arg2: T,
            comptime result: T,
            comptime rem: T,
        ) noreturn {
            var msg: [size]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                @typeName(T),             ": exact division had a remainder: ",
                tos(T, arg1).readAll(),   "/",
                tos(T, arg2).readAll(),   " == ",
                tos(T, result).readAll(), "r",
                tos(T, rem).readAll(),    "\n",
            }) |s| {
                for (s) |c, i| msg[len +% i] = c;
                len +%= s.len;
            }
            @compileError(msg[0..len]);
        }
        fn incorrectAlignment(
            comptime T: type,
            comptime type_name: []const u8,
            comptime address: T,
            comptime alignment: T,
            comptime result: T,
            comptime rem: T,
        ) noreturn {
            var msg: [size]u8 = undefined;
            var len: u64 = 0;

            for ([_][]const u8{
                @typeName(T),                ": incorrect alignment: ",
                type_name,                   " align(",
                tos(T, alignment).readAll(), "): ",
                tos(T, address).readAll(),   " == ",
                tos(T, result).readAll(),    "+",
                tos(T, rem).readAll(),       "\n",
            }) |s| {
                for (s) |c, i| msg[len +% i] = c;
                len +%= s.len;
            }
            @compileError(msg[0..len]);
        }
        fn comparisonFailed(
            comptime T: type,
            comptime symbol: []const u8,
            comptime arg1: T,
            comptime arg2: T,
        ) void {
            var buf: [size]u8 = undefined;
            var len: u64 = write(&buf, &[_][]const u8{
                @typeName(T),           " assertion failed: ",
                tos(T, arg1).readAll(), symbol,
                tos(T, arg2).readAll(), if (@min(arg1, arg2) > 10_000) ", i.e. " else "\n",
            });
            if (@min(arg1, arg2) > 10_000) {
                if (arg1 > arg2) {
                    len += write(buf[len..], &[_][]const u8{ tos(T, arg1 - arg2).readAll(), symbol, "0\n" });
                } else {
                    len += write(buf[len..], &[_][]const u8{ "0", symbol, tos(T, arg2 - arg1).readAll(), "\n" });
                }
            }
            @compileError(buf[0..len]);
        }
    };
    fn panic(buf: []const u8) noreturn {
        print(buf);
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (60),
              [arg1] "{rdi}" (2),
        );
        unreachable;
    }
    fn print(buf: []const u8) void {
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (1),
              [arg1] "{rdi}" (2),
              [arg2] "{rsi}" (@ptrToInt(buf.ptr)),
              [arg3] "{rdx}" (buf.len),
        );
    }
};
pub const parse = opaque {
    pub noinline fn ub(comptime T: type, str: []const u8) T {
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
    pub noinline fn uo(comptime T: type, str: []const u8) T {
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
    pub noinline fn ud(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = comptime sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub noinline fn ux(comptime T: type, str: []const u8) T {
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
    pub noinline fn ib(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = comptime sigFigList(T, 2);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'b');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 2) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub noinline fn io(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = comptime sigFigList(T, 8);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'o');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 8) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub noinline fn id(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = comptime sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub noinline fn ix(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = comptime sigFigList(T, 16);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @boolToInt(str[idx] == '-');
        idx +%= @boolToInt(str[idx] == '0');
        idx +%= @boolToInt(str[idx] == 'x');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 16) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn fromSymbol(c: u8, radix: u16) u8 {
        if (radix > 10) {
            return switch (c) {
                '0'...'9' => c -% ('9' - 0x9),
                'a'...'f' => c -% ('f' - 0xf),
                else => 0,
            };
        } else {
            return c -% ('9' - 9);
        }
    }
    fn nextSigFig(comptime T: type, prev: T, comptime radix: u16) ?T {
        var ret: T = undefined;
        if (@mulWithOverflow(T, prev, radix, &ret)) {
            return null;
        }
        if (@addWithOverflow(T, ret, radix -% 1, &ret)) {
            return null;
        }
        return ret;
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
    pub noinline fn any(comptime T: type, str: []const u8) !T {
        const signed: bool = str[0] == '-';
        if (signed and @typeInfo(T).Int.signedness == .unsigned) {
            return error.InvalidInputParity;
        }
        var idx: u64 = int(u64, signed);
        const zero: bool = str[idx] == '0';
        idx += int(u64, zero);
        if (idx == str.len) {
            return 0;
        }
        switch (str[idx]) {
            'b' => {
                return parseValidate(T, str[idx + 1 ..], 2);
            },
            'o' => {
                return parseValidate(T, str[idx + 1 ..], 8);
            },
            'x' => {
                return parseValidate(T, str[idx + 1 ..], 16);
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
            2 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'1' => {
                        value +%= fromSymbol(str[idx], 2) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return error.InvalidInputBinary;
                    },
                }
            },
            8 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'7' => {
                        value +%= fromSymbol(str[idx], 8) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return error.InvalidInputOctal;
                    },
                }
            },
            10 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'9' => {
                        value +%= fromSymbol(str[idx], 10) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return error.InvalidInputDecimal;
                    },
                }
            },
            16 => while (idx != str.len) : (idx += 1) {
                switch (str[idx]) {
                    '0'...'9', 'a'...'f' => {
                        value +%= fromSymbol(str[idx], 16) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
                    },
                    else => {
                        return error.InvalidInputHexadecimal;
                    },
                }
            },
            else => unreachable,
        }
        return value;
    }
};
pub const fmt = opaque {
    fn StaticString(comptime T: type, comptime radix: u16) type {
        return struct {
            auto: [max_len]u8 align(8) = undefined,
            len: u64 = max_len,
            const Array = @This();
            const max_len: u64 = maxSigFig(T, radix) + 1;
            fn writeOneBackwards(array: *Array, v: u8) void {
                array.len -%= 1;
                array.auto[array.len] = v;
            }
            pub fn readAll(array: *const Array) []const u8 {
                return array.auto[array.len..];
            }
        };
    }
    pub fn ci(value: comptime_int) []const u8 {
        if (value == 0) {
            return "0";
        }
        var s: []const u8 = "";
        var y = if (value < 0) -value else value;
        while (y != 0) : (y /= 10) {
            s = [_]u8{@truncate(u8, ((y % 10) + 48))} ++ s;
        }
        if (value < 0) {
            s = [_]u8{'-'} ++ s;
        }
        return s;
    }
    pub fn int(any: anytype) StaticString(@TypeOf(any), 10) {
        return d(@TypeOf(any), any);
    }
    inline fn b(comptime Int: type, value: Int) StaticString(Int, 2) {
        const Array = StaticString(Int, 2);
        const Abs = Absolute(Int);
        var array: Array = .{};
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
    inline fn o(comptime Int: type, value: Int) StaticString(Int, 8) {
        const Array = StaticString(Int, 8);
        const Abs = Absolute(Int);
        var array: Array = .{};
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
    inline fn d(comptime Int: type, value: Int) StaticString(Int, 10) {
        const Array = StaticString(Int, 10);
        const Abs = Absolute(Int);
        var array: Array = .{};
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
    inline fn x(comptime Int: type, value: Int) StaticString(Int, 16) {
        const Array = StaticString(Int, 16);
        const Abs = Absolute(Int);
        var array: Array = .{};
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
    pub noinline fn ub(comptime T: type, value: T) StaticString(T, 2) {
        return b(T, value);
    }
    pub noinline fn uo(comptime T: type, value: T) StaticString(T, 8) {
        return o(T, value);
    }
    pub noinline fn ud(comptime T: type, value: T) StaticString(T, 10) {
        return d(T, value);
    }
    pub noinline fn ux(comptime T: type, value: T) StaticString(T, 16) {
        return x(T, value);
    }
    pub noinline fn ib(comptime T: type, value: T) StaticString(T, 2) {
        return b(T, value);
    }
    pub noinline fn io(comptime T: type, value: T) StaticString(T, 8) {
        return o(T, value);
    }
    pub noinline fn id(comptime T: type, value: T) StaticString(T, 10) {
        return d(T, value);
    }
    pub noinline fn ix(comptime T: type, value: T) StaticString(T, 16) {
        return x(T, value);
    }
    pub noinline fn ub8(value: u8) StaticString(u8, 2) {
        return ub(u8, value);
    }
    pub noinline fn ub16(value: u16) StaticString(u16, 2) {
        return ub(u16, value);
    }
    pub noinline fn ub32(value: u32) StaticString(u32, 2) {
        return ub(u32, value);
    }
    pub noinline fn ub64(value: u64) StaticString(u64, 2) {
        return ub(u64, value);
    }
    pub noinline fn uo8(value: u8) StaticString(u8, 8) {
        return uo(u8, value);
    }
    pub noinline fn uo16(value: u16) StaticString(u16, 8) {
        return uo(u16, value);
    }
    pub noinline fn uo32(value: u32) StaticString(u32, 8) {
        return uo(u32, value);
    }
    pub noinline fn uo64(value: u64) StaticString(u64, 8) {
        return uo(u64, value);
    }
    pub noinline fn ud8(value: u8) StaticString(u8, 10) {
        return ud(u8, value);
    }
    pub noinline fn ud16(value: u16) StaticString(u16, 10) {
        return ud(u16, value);
    }
    pub noinline fn ud32(value: u32) StaticString(u32, 10) {
        return ud(u32, value);
    }
    pub noinline fn ud64(value: u64) StaticString(u64, 10) {
        return ud(u64, value);
    }
    pub noinline fn ux8(value: u8) StaticString(u8, 16) {
        return ux(u8, value);
    }
    pub noinline fn ux16(value: u16) StaticString(u16, 16) {
        return ux(u16, value);
    }
    pub noinline fn ux32(value: u32) StaticString(u32, 16) {
        return ux(u32, value);
    }
    pub noinline fn ux64(value: u64) StaticString(u64, 16) {
        return ux(u64, value);
    }
    pub noinline fn ib8(value: i8) StaticString(i8, 2) {
        return ib(i8, value);
    }
    pub noinline fn ib16(value: i16) StaticString(i16, 2) {
        return ib(i16, value);
    }
    pub noinline fn ib32(value: i32) StaticString(i32, 2) {
        return ib(i32, value);
    }
    pub noinline fn ib64(value: i64) StaticString(i64, 2) {
        return ib(i64, value);
    }
    pub noinline fn io8(value: i8) StaticString(i8, 8) {
        return io(i8, value);
    }
    pub noinline fn io16(value: i16) StaticString(i16, 8) {
        return io(i16, value);
    }
    pub noinline fn io32(value: i32) StaticString(i32, 8) {
        return io(i32, value);
    }
    pub noinline fn io64(value: i64) StaticString(i64, 8) {
        return io(i64, value);
    }
    pub noinline fn id8(value: i8) StaticString(i8, 10) {
        return id(i8, value);
    }
    pub noinline fn id16(value: i16) StaticString(i16, 10) {
        return id(i16, value);
    }
    pub noinline fn id32(value: i32) StaticString(i32, 10) {
        return id(i32, value);
    }
    pub noinline fn id64(value: i64) StaticString(i64, 10) {
        return id(i64, value);
    }
    pub noinline fn ix8(value: i8) StaticString(i8, 16) {
        return ix(i8, value);
    }
    pub noinline fn ix16(value: i16) StaticString(i16, 16) {
        return ix(i16, value);
    }
    pub noinline fn ix32(value: i32) StaticString(i32, 16) {
        return ix(i32, value);
    }
    pub noinline fn ix64(value: i64) StaticString(i64, 16) {
        return ix(i64, value);
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
    pub fn length(comptime U: type, abs_value: U, radix: U) u64 {
        var value: U = abs_value;
        var count: u64 = 0;
        while (value != 0) : (value /= radix) {
            count +%= 1;
        }
        return @max(1, count);
    }
    pub fn toSymbol(comptime T: type, value: T, radix: u16) u8 {
        const result: u8 = @intCast(u8, @rem(value, @intCast(T, radix)));
        const dec: u8 = '9' -% 9;
        const hex: u8 = 'f' -% 15;
        if (radix > 10) {
            return result +% if (result < 10) dec else hex;
        } else {
            return result +% dec;
        }
    }
    pub fn typeTypeName(comptime any: TypeId) []const u8 {
        return switch (any) {
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
            .BoundFn => "method", // Soon deprecated
            .Opaque => "opaque",
            .Frame => "frame",
            .AnyFrame => "anyframe",
            .Vector => "vector",
            .EnumLiteral => "(enum literal)",
        };
    }
    pub fn typeDeclSpecifier(comptime any: Type) []const u8 {
        return switch (any) {
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
                        return "packed union";
                    },
                    .Extern => {
                        return "extern union";
                    },
                    .Auto => {
                        return "union";
                    },
                }
            },
            .Opaque => "opaque",
            .ErrorSet => "error",

            .BoundFn,
            .Fn,
            .Vector,
            .Type,
            .Void,
            .Bool,
            .NoReturn,
            .Int,
            .Float,
            .Pointer,
            .Array,
            .ComptimeFloat,
            .ComptimeInt,
            .Undefined,
            .Null,
            .Optional,
            .ErrorUnion,
            .EnumLiteral,

            .Frame,
            .AnyFrame,
            => @compileError(@typeName(@Type(any))),
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
    pub fn parseVersion(comptime text: []const u8) !Version {
        var i: usize = 0;
        while (i < text.len) : (i += 1) {
            switch (text[i]) {
                '0'...'9', '.' => {},
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
            if (major + 1 < minor) digits[major + 1 .. minor] else "0";
        const patch_digits: []const u8 =
            if (minor + 1 < patch) digits[minor + 1 .. patch] else "0";
        const major_val: u64 = parse.ud(u64, major_digits);
        const minor_val: u64 = parse.ud(u64, minor_digits);
        const patch_val: u64 = parse.ud(u64, patch_digits);
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
    pub fn format(
        _: Version,
        comptime _: []const u8,
        _: anytype,
        _: anytype,
    ) !void {
        @compileError("TODO: Print version number");
    }
};
test {
    @setEvalBranchQuota(3000);
    comptime try testVersionParse();
}
fn testVersionParse() !void {
    const f = struct {
        fn eql(
            comptime text: []const u8,
            comptime v1: u32,
            comptime v2: u32,
            comptime v3: u32,
        ) !void {
            const v = try comptime Version.parseVersion(text);
            comptime static.assertEqual(u32, v.major, v1);
            comptime static.assertEqual(u32, v.minor, v2);
            comptime static.assertEqual(u32, v.patch, v3);
        }
        fn err(comptime text: []const u8, comptime expected_err: anyerror) !void {
            _ = comptime Version.parseVersion(text) catch |actual_err| {
                if (actual_err == expected_err) return;
                return actual_err;
            };
            return error.Unreachable;
        }
    };
    try f.eql("2.6.32.11-svn21605", 2, 6, 32); // Debian PPC
    try f.eql("2.11.2(0.329/5/3)", 2, 11, 2); // MinGW
    try f.eql("5.4.0-1018-raspi", 5, 4, 0); // Ubuntu
    try f.eql("5.7.12_3", 5, 7, 12); // Void
    try f.eql("2.13-DEVELOPMENT", 2, 13, 0); // DragonFly
    try f.eql("2.3-35", 2, 3, 0);
    try f.eql("1a.4", 1, 0, 0);
    try f.eql("3.b1.0", 3, 0, 0);
    try f.eql("1.4beta", 1, 4, 0);
    try f.eql("2.7.pre", 2, 7, 0);
    try f.eql("0..3", 0, 0, 0);
    try f.eql("8.008.", 8, 8, 0);
    try f.eql("01...", 1, 0, 0);
    try f.eql("55", 55, 0, 0);
    try f.eql("4294967295.0.1", 4294967295, 0, 1);
    try f.eql("429496729_6", 429496729, 0, 0);
    try f.err("foobar", error.InvalidVersion);
    try f.err("", error.InvalidVersion);
    try f.err("-1", error.InvalidVersion);
    try f.err("+4", error.InvalidVersion);
    try f.err(".", error.InvalidVersion);
    try f.err("....3", error.InvalidVersion);
    try f.err("4294967296", error.Overflow);
    try f.err("5000877755", error.Overflow);
}
