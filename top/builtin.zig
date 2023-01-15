pub const zig = @import("builtin");
pub const root = @import("root");

pub usingnamespace builtin;
// zig fmt: off
pub const native_endian                   = zig.cpu.arch.endian();
pub const is_little: bool                 = native_endian == .Little;
pub const is_big: bool                    = native_endian == .Big;
pub const is_safe: bool                   = config("is_safe",       bool,           zig.mode == .ReleaseSafe);
pub const is_small: bool                  = config("is_small",      bool,           zig.mode == .ReleaseSmall);
pub const is_fast: bool                   = config("is_fast",       bool,           zig.mode == .ReleaseFast);
pub const is_debug: bool                  = config("is_debug",      bool,           zig.mode == .Debug);
pub const is_correct: bool                = config("is_correct",    bool,           is_debug or is_safe);
pub const is_perf: bool                   = config("is_perf",       bool,           is_small or is_fast);
pub const is_verbose: bool                = config("is_verbose",    bool,           is_debug);
pub const AddressSpace: type              = config("AddressSpace",  type,           info.address_space.generic);
pub const logging: Logging                = config("logging",       Logging, .{});
pub const build_root: ?[:0]const u8       = config("build_root",    ?[:0]const u8,  null);
pub const root_src_file: ?[:0]const u8    = config("root_src_file", ?[:0]const u8,  null);
const builtin = opaque {
pub const SourceLocation                  = Src();
pub const Type                            = @TypeOf(@typeInfo(void));
pub const Struct                          = @TypeOf(@typeInfo(struct {}).Struct);
pub const Array                           = @TypeOf(@typeInfo([0]void).Array);
pub const Union                           = @TypeOf(@typeInfo(union {}).Union);
pub const Enum                            = @TypeOf(@typeInfo(enum {}).Enum);
pub const Pointer                         = @TypeOf(@typeInfo(*void).Pointer);
pub const Size                            = @TypeOf(@typeInfo(*void).Pointer.size);
pub const Signedness                      = @TypeOf(@typeInfo(u0).Int.signedness);
pub const TypeId                                  = @typeInfo(Type).Union.tag_type.?;
pub const StructField           = @typeInfo(@TypeOf(@typeInfo(struct {}).Struct.fields)).Pointer.child;
pub const ContainerLayout                 = @TypeOf(@typeInfo(struct {}).Struct.layout);
pub const Declaration           = @typeInfo(@TypeOf(@typeInfo(struct {}).Struct.decls)).Pointer.child;
pub const EnumField             = @typeInfo(@TypeOf(@typeInfo(enum { e }).Enum.fields)).Pointer.child;
pub const UnionField            = @typeInfo(@TypeOf(@typeInfo(union {}).Union.fields)).Pointer.child;
pub const CallingConvention               = @TypeOf(@typeInfo(fn () noreturn).Fn.calling_convention);
pub const FnParam               = @typeInfo(@TypeOf(@typeInfo(fn () noreturn).Fn.params)).Pointer.child;
pub const DeclLiteral                             = @Type(.EnumLiteral);
pub const Endian                                  = @TypeOf(zig.cpu.arch.endian());
};
// zig fmt: on
fn Src() type {
    return @TypeOf(@src());
}
fn Overflow(comptime T: type) type {
    return struct { T, u1 };
}
// Some compiler_rt
pub fn memcpy(dest: [*]u8, source: [*]const u8, count: usize) callconv(.C) void {
    @setRuntimeSafety(false);
    var index: usize = 0;
    while (index != count) : (index += 1) {
        dest[index] = source[index];
    }
}
pub fn memset(dest: [*]u8, value: u8, count: usize) callconv(.C) void {
    if (is_small) {
        asm volatile ("rep stosb"
            :
            : [_] "{rdi}" (dest),
              [_] "{al}" (value),
              [_] "{rcx}" (count),
            : "rax", "rdi", "rcx", "memory"
        );
    } else {
        @setRuntimeSafety(false);
        var index: usize = 0;
        while (index != count) : (index += 1) {
            dest[index] = value;
        }
    }
}
pub fn __zig_probe_stack() callconv(.C) void {}
comptime {
    @export(memcpy, .{ .name = "memcpy" });
    @export(memset, .{ .name = "memset" });
    if (is_debug or is_safe) @export(__zig_probe_stack, .{ .name = "__zig_probe_stack" });
}
/// Return an absolute path to a project file.
pub fn absolutePath(comptime relative: [:0]const u8) [:0]const u8 {
    return build_root.? ++ "/" ++ relative;
}
pub const Exception = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    ExactDivisionWithRemainder,
    UnexpectedValue,
};
pub const Logging = packed struct {
    Success: bool = is_verbose,
    Acquire: bool = is_verbose,
    Release: bool = is_verbose,
    Error: bool = true,
    Fault: bool = true,
    pub const verbose: Logging = .{
        .Success = true,
        .Acquire = true,
        .Release = true,
        .Error = true,
        .Fault = true,
    };
    pub const silent: Logging = .{
        .Success = false,
        .Acquire = false,
        .Release = false,
        .Error = false,
        .Fault = false,
    };
};
pub fn config(
    comptime symbol: []const u8,
    comptime T: type,
    comptime default: anytype,
) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    } else if (@hasDecl(@cImport({}), symbol)) {
        const command = @field(@cImport({}), symbol);
        if (T == bool) {
            return @bitCast(T, @as(u1, command));
        }
        return command;
    } else if (@typeInfo(@TypeOf(default)) == .Fn) {
        return @call(.auto, default, .{});
    }
    return default;
}
pub fn configExtra(
    comptime symbol: []const u8,
    comptime T: type,
    comptime default: anytype,
    comptime args: anytype,
) T {
    if (@hasDecl(root, symbol)) {
        return @field(root, symbol);
    } else if (@hasDecl(@cImport({}), symbol)) {
        const command = @field(@cImport({}), symbol);
        if (T == bool) {
            return @bitCast(T, @as(u1, command));
        }
        return command;
    } else if (@typeInfo(@TypeOf(default)) == .Fn) {
        return @call(.auto, default, args);
    }
    return default;
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
    if (is_debug and result[1] != 0) {
        debug.addCausedOverflowFault(T, arg1, arg2);
    }
    return result[0];
}
fn normalSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalSubReturn(T, arg1.*, arg2);
}
fn normalSubReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
    if (is_debug and result[1] != 0) {
        debug.subCausedOverflowFault(T, arg1, arg2);
    }
    return result[0];
}
fn normalMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalMulReturn(T, arg1.*, arg2);
}
fn normalMulReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
    if (is_debug and result[1] != 0) {
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
    if (is_debug and remainder != 0) {
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
    if (@typeInfo(T) == .Int) {
        return @min(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = @bitSizeOf(T), .signedness = .unsigned });
        return @min(@bitCast(U, arg1), @bitCast(U, arg2));
    }
}
pub fn max(comptime T: type, arg1: T, arg2: T) T {
    if (@typeInfo(T) == .Int) {
        return @max(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = @bitSizeOf(T), .signedness = .unsigned });
        return @max(@bitCast(U, arg1), @bitCast(U, arg2));
    }
}
pub fn isComptime() bool {
    var b: bool = false;
    return @TypeOf(if (b) @as(u32, 0) else @as(u8, 0)) == u8;
}

fn @"test"(b: bool) bool {
    return b;
}

// Currently, only the following non-trivial comparisons are supported:
fn testEqualArray(comptime T: type, comptime array_info: builtin.Array, arg1: T, arg2: T) bool {
    var i: usize = 0;
    while (i != array_info.len) : (i += 1) {
        if (!testEqual(array_info.child, arg1[i], arg2[i])) {
            return false;
        }
    }
    return true;
}
fn testEqualSlice(comptime T: type, comptime pointer_info: builtin.Pointer, arg1: T, arg2: T) bool {
    if (arg1.len != arg2.len) {
        return false;
    }
    var i: usize = 0;
    while (i != arg1.len) : (i += 1) {
        if (!testEqual(pointer_info.child, arg1[i], arg2[i])) {
            return false;
        }
    }
    return true;
}
fn testEqualPointer(comptime T: type, comptime pointer_info: builtin.Pointer, arg1: T, arg2: T) bool {
    if (@typeInfo(pointer_info.child) != .Fn) {
        return arg1 == arg2;
    }
    return false;
}
fn testEqualStruct(comptime T: type, comptime struct_info: builtin.Struct, arg1: T, arg2: T) bool {
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
fn testEqualUnion(comptime T: type, comptime union_info: builtin.Union, arg1: T, arg2: T) bool {
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
}
fn testEqualOptional(comptime T: type, comptime optional_info: builtin.Optional, arg1: T, arg2: T) bool {
    if (@typeInfo(optional_info.child) == .Pointer and
        @typeInfo(optional_info.child).Pointer.size != .Slice and
        @typeInfo(optional_info.child).Pointer.size != .C)
    {
        return arg1 == arg2;
    }
    return false;
}
pub fn testEqual(comptime T: type, arg1: T, arg2: T) bool {
    const type_info: builtin.Type = @typeInfo(T);
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
    const result: bool = testEqual(T, arg1, arg2);
    if (is_correct and !result) {
        debug.comparisonFailedFault(T, " == ", arg1, arg2);
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    const result: bool = !testEqual(T, arg1, arg2);
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
pub fn intToPtr(comptime P: type, address: u64) P {
    return @intToPtr(P, address);
}
pub fn intCast(comptime T: type, value: anytype) T {
    @setRuntimeSafety(false);
    const U: type = @TypeOf(value);
    if (@bitSizeOf(T) > @bitSizeOf(U)) {
        return value;
    }
    if (value > ~@as(T, 0)) {
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
        if (is_debug and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalAddReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
        if (is_debug and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalSubAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingSubReturn(T, arg1.*, arg2);
        if (is_debug and arg1.* < arg2) {
            debug.static.subCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalSubReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
        if (is_debug and result[1] != 0) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalMulAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingMulReturn(T, arg1.*, arg2);
        if (is_debug and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalMulReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
        if (is_debug and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn exactDivisionAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: T = arg1.* / arg2;
        const remainder: T = static.normalSubReturn(T, arg1.*, (result * arg2));
        if (is_debug and remainder != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1.*, arg2, result, remainder);
        }
        arg1.* = result;
    }
    fn exactDivisionReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: T = arg1 / arg2;
        const remainder: T = static.normalSubReturn(T, arg1, (result * arg2));
        if (is_debug and remainder != 0) {
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
                len += write(buf[len..], &[_][]const u8{ tos(T, arg1 -% arg2).readAll(), symbol, "0\n" });
            } else {
                len += write(buf[len..], &[_][]const u8{ "0", symbol, tos(T, arg2 -% arg1).readAll(), "\n" });
            }
        }
        return len;
    }
    fn intCastTruncatedBitsString(comptime T: type, comptime U: type, buf: *[size]u8, arg1: U) u64 {
        const minimum: T = 0;
        return write(buf, &[_][]const u8{
            about_fault_p0_s,           "integer cast truncated bits: ",
            tos(U, arg1).readAll(),     " greater than " ++ @typeName(T) ++ " maximum (",
            tos(T, ~minimum).readAll(), ")\n",
        });
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
            len += write(msg[len..], &[_][]const u8{ "0 - ", tos(T, arg2 -% arg1).readAll(), "\n" });
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
    fn exactDivisionWithRemainderString(comptime T: type, about: []const u8, buf: *[size]u8, arg1: T, arg2: T, result: T, remainder: T) u64 {
        return write(buf, &[_][]const u8{
            about,                       ": exact division had a remainder: ",
            tos(T, arg1).readAll(),      "/",
            tos(T, arg2).readAll(),      " == ",
            tos(T, result).readAll(),    "r",
            tos(T, remainder).readAll(), "\n",
        });
    }
    fn incorrectAlignmentString(comptime Pointer: type, about: []const u8, buf: *[size]u8, address: usize, alignment: usize, remainder: u64) u64 {
        return write(buf, &[_][]const u8{
            about,                                    ": incorrect alignment: ",
            @typeName(Pointer),                       " align(",
            tos(u64, alignment).readAll(),            "): ",
            tos(u64, address).readAll(),              " == ",
            tos(u64, address -% remainder).readAll(), "+",
            tos(u64, remainder).readAll(),            "\n",
        });
    }
    fn intCastTruncatedBitsFault(comptime T: type, comptime U: type, arg: U) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.intCastTruncatedBitsString(T, U, &buf, arg);
        panic(buf[0..len]);
    }
    fn subCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.SubCausedOverflow;
    }
    fn subCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.subCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
    }
    fn addCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutError(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.AddCausedOverflow;
    }
    fn addCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = debug.addCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
    }
    fn mulCausedOverflowException(comptime T: type, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutError(T), &buf, arg1, arg2);
        print(buf[0..len]);
        return error.MulCausedOverflow;
    }
    fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = mulCausedOverflowString(T, aboutFault(T), &buf, arg1, arg2);
        panic(buf[0..len]);
    }
    fn exactDivisionWithRemainderException(comptime T: type, arg1: T, arg2: T, result: T, remainder: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutError(T), &buf, arg1, arg2, result, remainder);
        print(buf[0..len]);
        return error.DivisionWithRemainder;
    }
    fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, remainder: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = exactDivisionWithRemainderString(T, aboutFault(T), &buf, arg1, arg2, result, remainder);
        panic(buf[0..len]);
    }
    fn incorrectAlignmentException(comptime T: type, address: usize, alignment: usize) Exception {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutError(T), &buf, address, alignment, remainder);
        print(buf[0..len]);
        return error.IncorrectAlignment;
    }
    fn incorrectAlignmentFault(comptime T: type, address: usize, alignment: usize) noreturn {
        @setCold(true);
        const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
        var buf: [size]u8 = undefined;
        const len: u64 = incorrectAlignmentString(T, aboutFault(T), &buf, address, alignment, remainder);
        panic(buf[0..len]);
    }
    fn comparisonFailedException(comptime T: type, symbol: []const u8, arg1: T, arg2: T) Exception {
        @setCold(true);
        var buf: [size]u8 = undefined;
        const len: u64 = comparisonFailedString(T, aboutError(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        print(buf[0..len]);
        return error.UnexpectedValue;
    }
    fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: T, arg2: T) noreturn {
        @setCold(true);
        var buf: [size]u8 = undefined;
        var len: u64 = comparisonFailedString(T, aboutFault(T), symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
        panic(buf[0..len]);
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
                    @typeName(T),                ": exact division had a remainder: ",
                    tos(T, arg1).readAll(),      "/",
                    tos(T, arg2).readAll(),      " == ",
                    tos(T, result).readAll(),    "r",
                    tos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s) |c, i| msg[len +% i] = c;
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
                    @typeName(T),                ": incorrect alignment: ",
                    type_name,                   " align(",
                    tos(T, alignment).readAll(), "): ",
                    tos(T, address).readAll(),   " == ",
                    tos(T, result).readAll(),    "+",
                    tos(T, remainder).readAll(), "\n",
                }) |s| {
                    for (s) |c, i| msg[len +% i] = c;
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
                var len: u64 = write(&buf, &[_][]const u8{
                    @typeName(T),           " assertion failed: ",
                    tos(T, arg1).readAll(), symbol,
                    tos(T, arg2).readAll(), if (@min(arg1, arg2) > 10_000) ", i.e. " else "\n",
                });
                if (@min(arg1, arg2) > 10_000) {
                    if (arg1 > arg2) {
                        len += write(buf[len..], &[_][]const u8{ tos(T, arg1 -% arg2).readAll(), symbol, "0\n" });
                    } else {
                        len += write(buf[len..], &[_][]const u8{ "0", symbol, tos(T, arg2 -% arg1).readAll(), "\n" });
                    }
                }
                @compileError(buf[0..len]);
            }
        }
    };
    fn panic(buf: []const u8) noreturn {
        print(buf);
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (60), // linux sys_exit
              [arg1] "{rdi}" (2), // exit code
        );
        unreachable;
    }
    fn print(buf: []const u8) void {
        asm volatile (
            \\syscall
            :
            : [sysno] "{rax}" (1), // linux sys_write
              [arg1] "{rdi}" (2), // stderr
              [arg2] "{rsi}" (@ptrToInt(buf.ptr)),
              [arg3] "{rdx}" (buf.len),
        );
    }
};
pub const parse = opaque {
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
            value +%= fromSymbol(str[idx], 2) * (sig_fig_list[str.len -% idx -% 1] +% 1);
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
            value +%= fromSymbol(str[idx], 8) * (sig_fig_list[str.len -% idx -% 1] +% 1);
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
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
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
            value +%= fromSymbol(str[idx], 16) * (sig_fig_list[str.len -% idx -% 1] +% 1);
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
    pub fn any(comptime T: type, str: []const u8) !T {
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
        return d(@TypeOf(value), value);
    }
    fn b(comptime Int: type, value: Int) StaticString(Int, 2) {
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
    fn o(comptime Int: type, value: Int) StaticString(Int, 8) {
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
    fn d(comptime Int: type, value: Int) StaticString(Int, 10) {
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
    fn x(comptime Int: type, value: Int) StaticString(Int, 16) {
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
    pub const ub = b;
    pub const uo = o;
    pub const ud = d;
    pub const ux = x;
    pub const ib = b;
    pub const io = o;
    pub const id = d;
    pub const ix = x;
    pub fn ub8(value: u8) StaticString(u8, 2) {
        return ub(u8, value);
    }
    pub fn ub16(value: u16) StaticString(u16, 2) {
        return ub(u16, value);
    }
    pub fn ub32(value: u32) StaticString(u32, 2) {
        return ub(u32, value);
    }
    pub fn ub64(value: u64) StaticString(u64, 2) {
        return ub(u64, value);
    }
    pub fn uo8(value: u8) StaticString(u8, 8) {
        return uo(u8, value);
    }
    pub fn uo16(value: u16) StaticString(u16, 8) {
        return uo(u16, value);
    }
    pub fn uo32(value: u32) StaticString(u32, 8) {
        return uo(u32, value);
    }
    pub fn uo64(value: u64) StaticString(u64, 8) {
        return uo(u64, value);
    }
    pub fn ud8(value: u8) StaticString(u8, 10) {
        return ud(u8, value);
    }
    pub fn ud16(value: u16) StaticString(u16, 10) {
        return ud(u16, value);
    }
    pub fn ud32(value: u32) StaticString(u32, 10) {
        return ud(u32, value);
    }
    pub fn ud64(value: u64) StaticString(u64, 10) {
        return ud(u64, value);
    }
    pub fn ux8(value: u8) StaticString(u8, 16) {
        return ux(u8, value);
    }
    pub fn ux16(value: u16) StaticString(u16, 16) {
        return ux(u16, value);
    }
    pub fn ux32(value: u32) StaticString(u32, 16) {
        return ux(u32, value);
    }
    pub fn ux64(value: u64) StaticString(u64, 16) {
        return ux(u64, value);
    }
    pub fn ib8(value: i8) StaticString(i8, 2) {
        return ib(i8, value);
    }
    pub fn ib16(value: i16) StaticString(i16, 2) {
        return ib(i16, value);
    }
    pub fn ib32(value: i32) StaticString(i32, 2) {
        return ib(i32, value);
    }
    pub fn ib64(value: i64) StaticString(i64, 2) {
        return ib(i64, value);
    }
    pub fn io8(value: i8) StaticString(i8, 8) {
        return io(i8, value);
    }
    pub fn io16(value: i16) StaticString(i16, 8) {
        return io(i16, value);
    }
    pub fn io32(value: i32) StaticString(i32, 8) {
        return io(i32, value);
    }
    pub fn io64(value: i64) StaticString(i64, 8) {
        return io(i64, value);
    }
    pub fn id8(value: i8) StaticString(i8, 10) {
        return id(i8, value);
    }
    pub fn id16(value: i16) StaticString(i16, 10) {
        return id(i16, value);
    }
    pub fn id32(value: i32) StaticString(i32, 10) {
        return id(i32, value);
    }
    pub fn id64(value: i64) StaticString(i64, 10) {
        return id(i64, value);
    }
    pub fn ix8(value: i8) StaticString(i8, 16) {
        return ix(i8, value);
    }
    pub fn ix16(value: i16) StaticString(i16, 16) {
        return ix(i16, value);
    }
    pub fn ix32(value: i32) StaticString(i32, 16) {
        return ix(i32, value);
    }
    pub fn ix64(value: i64) StaticString(i64, 16) {
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
        const result: u8 = @intCast(u8, @rem(value, @intCast(T, radix)));
        const dec: u8 = '9' -% 9;
        const hex: u8 = 'f' -% 15;
        if (radix > 10) {
            return result +% if (result < 10) dec else hex;
        } else {
            return result +% dec;
        }
    }
    pub fn typeTypeName(comptime type_id: builtin.TypeId) []const u8 {
        return switch (type_id) {
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
    pub fn typeDeclSpecifier(comptime type_info: builtin.Type) []const u8 {
        return switch (type_info) {
            .Array => |array_info| {
                const type_name: []const u8 = @typeName(@Type(type_info));
                const child_type_name: []const u8 = @typeName(array_info.child);
                return type_name[0 .. type_name.len -% child_type_name.len];
            },
            .Pointer => |pointer_info| {
                const type_name: []const u8 = @typeName(@Type(type_info));
                const child_type_name: []const u8 = @typeName(pointer_info.child);
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
    pub fn parseVersion(comptime text: []const u8) !Version {
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
pub const info = struct {
    const title_s: []const u8 = "\r\t\x1b[96;1mnote\x1b[0;1m: ";
    const point_s: []const u8 = "\r\t    : ";
    const space_s: []const u8 = "\r\t       ";
    pub const path = opaque {
        pub inline fn buildRoot() noreturn {
            @compileError(
                "program requires build root:\n" ++
                    title_s ++ "add '-Dbuild_root=<project_build_root>' to compile flags\n",
            );
        }
    };
    pub const address_space = opaque {
        pub inline fn generic() noreturn {
            @compileError(
                "toplevel address space required:\n" ++
                    title_s ++ "declare 'pub const AddressSpace = <zig_lib>.preset.address_space.formulaic_128;' in program root\n" ++
                    title_s ++ "address spaces are required by high level features with managed memory",
            );
        }
        pub inline fn defaultValue(comptime Struct: type) noreturn {
            @compileError(
                if (!@hasField(Struct, "AddressSpace"))
                    "expected field 'AddressSpace' in '" ++ @typeName(Struct) ++ "'"
                else
                    "toplevel address space required by default field value:\n" ++
                        title_s ++ "declare 'pub const AddressSpace = <zig_lib>.preset.address_space.formulaic_128;' in program root\n" ++
                        point_s ++ "initialize field 'AddressSpace' in '" ++ @typeName(Struct) ++ "' explicitly\n" ++
                        title_s ++ "address spaces are required by high level features with managed memory",
            );
        }
        pub noinline fn testPrint() noreturn {}
    };
};
