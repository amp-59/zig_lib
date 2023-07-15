const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
pub inline fn sigFigList(comptime T: type, comptime radix: u7) ?[]const T {
    switch (T) {
        u8 => switch (radix) {
            2 => return &.{ 0, 1, 3, 7, 15, 31, 63, 127, 255 },
            8 => return &.{ 0, 7, 63 },
            10 => return &.{ 0, 9, 99 },
            16 => return &.{ 0, 15, 255 },
            else => return null,
        },
        u16 => switch (radix) {
            2 => return &.{ 0, 1, 3, 7, 15, 31, 63, 127, 255, 511, 1023, 2047, 4095, 8191, 16383, 32767, 65535 },
            8 => return &.{ 0, 7, 63, 511, 4095, 32767 },
            10 => return &.{ 0, 9, 99, 999, 9999 },
            16 => return &.{ 0, 15, 255, 4095, 65535 },
            else => return null,
        },
        u32 => switch (radix) {
            2 => return &.{
                0,          1,         3,          7,
                15,         31,        63,         127,
                255,        511,       1023,       2047,
                4095,       8191,      16383,      32767,
                65535,      131071,    262143,     524287,
                1048575,    2097151,   4194303,    8388607,
                16777215,   33554431,  67108863,   134217727,
                268435455,  536870911, 1073741823, 2147483647,
                4294967295,
            },
            8 => return &.{ 0, 7, 63, 511, 4095, 32767, 262143, 2097151, 16777215, 134217727, 1073741823 },
            10 => return &.{ 0, 9, 99, 999, 9999, 99999, 999999, 9999999, 99999999, 999999999 },
            16 => return &.{ 0, 15, 255, 4095, 65535, 1048575, 16777215, 268435455, 4294967295 },
            else => return null,
        },
        u64 => switch (radix) {
            2 => return &.{
                0,                    1,                   3,                   7,
                15,                   31,                  63,                  127,
                255,                  511,                 1023,                2047,
                4095,                 8191,                16383,               32767,
                65535,                131071,              262143,              524287,
                1048575,              2097151,             4194303,             8388607,
                16777215,             33554431,            67108863,            134217727,
                268435455,            536870911,           1073741823,          2147483647,
                4294967295,           8589934591,          17179869183,         34359738367,
                68719476735,          137438953471,        274877906943,        549755813887,
                1099511627775,        2199023255551,       4398046511103,       8796093022207,
                17592186044415,       35184372088831,      70368744177663,      140737488355327,
                281474976710655,      562949953421311,     1125899906842623,    2251799813685247,
                4503599627370495,     9007199254740991,    18014398509481983,   36028797018963967,
                72057594037927935,    144115188075855871,  288230376151711743,  576460752303423487,
                1152921504606846975,  2305843009213693951, 4611686018427387903, 9223372036854775807,
                18446744073709551615,
            },
            8 => return &.{
                0,                   7,                   63,                511,
                4095,                32767,               262143,            2097151,
                16777215,            134217727,           1073741823,        8589934591,
                68719476735,         549755813887,        4398046511103,     35184372088831,
                281474976710655,     2251799813685247,    18014398509481983, 144115188075855871,
                1152921504606846975, 9223372036854775807,
            },
            10 => return &.{
                0,                9,                 99,                 999,
                9999,             99999,             999999,             9999999,
                99999999,         999999999,         9999999999,         99999999999,
                999999999999,     9999999999999,     99999999999999,     999999999999999,
                9999999999999999, 99999999999999999, 999999999999999999, 9999999999999999999,
            },
            16 => return &.{
                0,                    15,               255,               4095,
                65535,                1048575,          16777215,          268435455,
                4294967295,           68719476735,      1099511627775,     17592186044415,
                281474976710655,      4503599627370495, 72057594037927935, 1152921504606846975,
                18446744073709551615,
            },
            else => return null,
        },
        else => return null,
    }
}
pub const nan_u16: u16 = @as(u16, 0x7C01);
pub const nan_f16: f16 = @as(f16, @bitCast(nan_u16));
pub const qnan_u16: u16 = @as(u16, 0x7E00);
pub const qnan_f16: f16 = @as(f16, @bitCast(qnan_u16));
pub const nan_u32: u32 = @as(u32, 0x7F800001);
pub const nan_f32: f32 = @as(f32, @bitCast(nan_u32));
pub const qnan_u32: u32 = @as(u32, 0x7FC00000);
pub const qnan_f32: f32 = @as(f32, @bitCast(qnan_u32));
pub const nan_u64: u64 = @as(u64, 0x7FF << 52) | 1;
pub const nan_f64: f64 = @as(f64, @bitCast(nan_u64));
pub const qnan_u64: u64 = @as(u64, 0x7ff8000000000000);
pub const qnan_f64: f64 = @as(f64, @bitCast(qnan_u64));
pub const nan_u128: u128 = @as(u128, 0x7fff0000000000000000000000000001);
pub const nan_f128: f128 = @as(f128, @bitCast(nan_u128));
pub const qnan_u128: u128 = @as(u128, 0x7fff8000000000000000000000000000);
pub const qnan_f128: f128 = @as(f128, @bitCast(qnan_u128));
pub const Order = enum {
    lt,
    eq,
    gt,
};
pub fn order(a: anytype, b: anytype) Order {
    if (a == b) {
        return .eq;
    } else if (a < b) {
        return .lt;
    } else if (a > b) {
        return .gt;
    } else {
        unreachable;
    }
}
pub fn Absolute(comptime T: type) type {
    const bit_size_of: u16 = @bitSizeOf(T);
    if (bit_size_of == 0) {
        return comptime_int;
    }
    return @Type(.{ .Int = .{
        .bits = @max(8, bit_size_of),
        .signedness = .unsigned,
    } });
}
pub inline fn absoluteDiff(x: anytype, y: anytype) Absolute(@TypeOf(x + y)) {
    return @max(x, y) -% @min(x, y);
}
pub inline fn absoluteVal(value: anytype) Absolute(@TypeOf(value)) {
    @setRuntimeSafety(false);
    const Int: type = @TypeOf(value);
    const Abs: type = Absolute(Int);
    if (Int == comptime_int and value < 0) {
        return -value;
    }
    if (Int != Abs and value < 0) {
        return @as(Abs, @bitCast(-value));
    }
    return @as(Abs, @intCast(value));
}
/// Returns the sum of arg1 and b. Returns an error on overflow.
pub fn mul(comptime T: type, arg1: T, arg2: T) (error{Overflow}!T) {
    if (@inComptime()) {
        return arg1 * arg2;
    }
    const res: struct { T, u1 } = @mulWithOverflow(arg1, arg2);
    if (res[1] != 0) {
        return error.Overflow;
    }
    return res[0];
}
/// Returns the sum of arg1 and b. Returns an error on overflow.
pub fn add(comptime T: type, arg1: T, arg2: T) (error{Overflow}!T) {
    if (@inComptime()) {
        return arg1 + arg2;
    }
    const res: struct { T, u1 } = @addWithOverflow(arg1, arg2);
    if (res[1] != 0) {
        return error.Overflow;
    }
    return res[0];
}
/// Returns arg1 - b, or an error on overflow.
pub fn sub(comptime T: type, arg1: T, arg2: T) (error{Overflow}!T) {
    if (@inComptime()) {
        return arg1 - arg2;
    }
    const res: struct { T, u1 } = @subWithOverflow(arg1, arg2);
    if (res[1] != 0) {
        return error.Overflow;
    }
    return res[0];
}
pub fn rotr(comptime T: type, value: T, rot_amt: anytype) T {
    const RotateAmount = @TypeOf(rot_amt);
    if (@typeInfo(T) == .Vector) {
        const C = @typeInfo(T).Vector.child;
        if (C == u0) {
            return 0;
        }
        builtin.assert(@typeInfo(C).Int.signedness != .signed);
        const shift_amt = @as(builtin.ShiftAmount(C), @intCast(@mod(rot_amt, @typeInfo(C).Int.bits)));
        return (value >> @splat(shift_amt)) | (value << @splat(1 +% ~shift_amt));
    } else {
        builtin.assert(@typeInfo(T).Int.signedness != .signed);
        const ShiftAmount = builtin.ShiftAmount(T);
        const bit_size_of: u16 = @typeInfo(T).Int.bits;
        if (T == u0) {
            return 0;
        }
        if (@popCount(bit_size_of) == 1) {
            const shift_amt: ShiftAmount = @as(ShiftAmount, @intCast(@mod(rot_amt, bit_size_of)));
            return value >> shift_amt | value << (1 +% ~shift_amt);
        } else {
            const shift_amt: RotateAmount = @mod(rot_amt, bit_size_of);
            return shr(T, value, shift_amt) | shl(T, value, bit_size_of -% shift_amt);
        }
    }
}
pub fn rotl(comptime T: type, value: T, rot_amt: anytype) T {
    const RotateAmount = @TypeOf(rot_amt);
    if (@typeInfo(T) == .Vector) {
        const C = @typeInfo(T).Vector.child;
        if (C == u0) {
            return 0;
        }
        builtin.assert(@typeInfo(C).Int.signedness != .signed);
        const shift_amt = @as(builtin.ShiftAmount(C), @intCast(@mod(rot_amt, @typeInfo(C).Int.bits)));
        return (value << @splat(shift_amt)) | (value >> @splat(1 +% ~shift_amt));
    } else {
        builtin.assert(@typeInfo(T).Int.signedness != .signed);
        const ShiftAmount = builtin.ShiftAmount(T);
        const bit_size_of: u16 = @typeInfo(T).Int.bits;
        if (T == u0) {
            return 0;
        }
        if (@popCount(bit_size_of) == 1) {
            const shift_amt: ShiftAmount = @as(ShiftAmount, @intCast(@mod(rot_amt, bit_size_of)));
            return value << shift_amt | value >> 1 +% ~shift_amt;
        } else {
            const shift_amt: RotateAmount = @mod(rot_amt, bit_size_of);
            return shl(T, value, shift_amt) | shr(T, value, bit_size_of -% shift_amt);
        }
    }
}
pub fn shl(comptime T: type, value: T, shift_amt: anytype) T {
    const ShiftAmount = @TypeOf(shift_amt);
    const abs_shift_amt: Absolute(ShiftAmount) = absoluteVal(shift_amt);
    const casted_shift_amt = blk: {
        if (@typeInfo(T) == .Vector) {
            const C = @typeInfo(T).Vector.child;
            const len: usize = @typeInfo(T).Vector.len;
            if (abs_shift_amt >= @typeInfo(C).Int.bits) {
                return @as(@Vector(len, C), @splat(@as(C, 0)));
            }
            break :blk @as(@Vector(len, C), @splat(@as(builtin.ShiftAmount(C), @intCast(abs_shift_amt))));
        } else {
            if (abs_shift_amt >= @typeInfo(T).Int.bits) {
                return 0;
            }
            break :blk @as(builtin.ShiftAmount(T), @intCast(abs_shift_amt));
        }
    };
    if (ShiftAmount == comptime_int or
        @typeInfo(ShiftAmount).Int.signedness == .signed)
    {
        if (shift_amt < 0) {
            return value >> @intCast(casted_shift_amt);
        }
    }
    return value << @intCast(casted_shift_amt);
}
pub fn shr(comptime T: type, a: T, shift_amt: anytype) T {
    const ShiftAmount = @TypeOf(shift_amt);
    const abs_shift_amt: Absolute(ShiftAmount) = absoluteVal(shift_amt);
    const casted_shift_amt = blk: {
        if (@typeInfo(T) == .Vector) {
            const C = @typeInfo(T).Vector.child;
            const len = @typeInfo(T).Vector.len;
            if (abs_shift_amt >= @typeInfo(C).Int.bits) {
                return @as(@Vector(len, C), @splat(@as(C, 0)));
            }
            break :blk @as(@Vector(len, C), @splat(@as(builtin.ShiftAmount(C), @intCast(abs_shift_amt))));
        } else {
            if (abs_shift_amt >= @typeInfo(T).Int.bits) {
                return 0;
            }
            break :blk @as(builtin.ShiftAmount(T), @intCast(abs_shift_amt));
        }
    };
    if (ShiftAmount == comptime_int or
        @typeInfo(ShiftAmount).Int.signedness == .signed)
    {
        if (shift_amt < 0) {
            return a << @intCast(casted_shift_amt);
        }
    }
    return a >> @intCast(casted_shift_amt);
}
pub fn log2(comptime T: type, x: T) builtin.ShiftAmount(T) {
    return @as(builtin.ShiftAmount(T), @intCast(@typeInfo(T).Int.bits - 1 - @clz(x)));
}
pub const float = struct {
    pub fn Mantissa(comptime T: type) type {
        return switch (T) {
            f16, f32, f64 => u64,
            f128 => u128,
            else => unreachable,
        };
    }
    /// Creates a raw "1.0" mantissa for floating point type T. Used to dedupe f80 logic.
    fn mantissaOne(comptime T: type) comptime_int {
        return if (@typeInfo(T).Float.bits == 80) 1 << fractionalBits(T) else 0;
    }
    /// Creates floating point type T from an unbiased exponent and raw mantissa.
    fn reconstructFloat(comptime T: type, comptime exponent: comptime_int, comptime mantissa: comptime_int) comptime_float {
        const TBits = @Type(.{ .Int = .{
            .signedness = .unsigned,
            .bits = @bitSizeOf(T),
        } });
        return @as(T, @bitCast((@as(TBits, exponent + exponentMax(T)) << mantissaBits(T)) | @as(TBits, mantissa)));
    }
    /// Returns the number of bits in the exponent of floating point type T.
    pub fn exponentBits(comptime T: type) comptime_int {
        switch (@typeInfo(T).Float.bits) {
            16 => return 5,
            32 => return 8,
            64 => return 11,
            80 => return 15,
            128 => return 15,
            else => return undefined,
        }
    }
    /// Returns the number of bits in the mantissa of floating point type T.
    pub fn mantissaBits(comptime T: type) comptime_int {
        switch (@typeInfo(T).Float.bits) {
            16 => return 10,
            32 => return 23,
            64 => return 52,
            80 => return 64,
            128 => return 112,
            else => return undefined,
        }
    }
    /// Returns the number of fractional bits in the mantissa of floating point type T.
    pub fn fractionalBits(comptime T: type) comptime_int {
        switch (@typeInfo(T).Float.bits) {
            16 => return 10,
            32 => return 23,
            64 => return 52,
            80 => return 63,
            128 => return 112,
            else => return undefined,
        }
    }
    pub inline fn exponentMin(comptime T: type) comptime_int {
        comptime return -exponentMax(T) + 1;
    }
    pub inline fn exponentInf(comptime T: type) comptime_int {
        comptime return (1 << exponentBits(T)) - 1;
    }
    pub inline fn exponentMax(comptime T: type) comptime_int {
        comptime return (1 << (exponentBits(T) - 1)) - 1;
    }
    pub inline fn trueMin(comptime T: type) T {
        comptime return reconstructFloat(T, exponentMin(T) - 1, 1);
    }
    pub inline fn min(comptime T: type) T {
        comptime return reconstructFloat(T, exponentMin(T), mantissaOne(T));
    }
    pub inline fn max(comptime T: type) T {
        comptime return reconstructFloat(T, exponentMax(T), (1 << mantissaBits(T)) - 1);
    }
    pub inline fn eps(comptime T: type) T {
        comptime return reconstructFloat(T, -fractionalBits(T), mantissaOne(T));
    }
    pub inline fn inf(comptime T: type) T {
        comptime return reconstructFloat(T, exponentMax(T) + 1, mantissaOne(T));
    }
    pub inline fn nan(comptime T: type) T {
        switch (@typeInfo(T).Float.bits) {
            16 => return nan_f16,
            32 => return nan_f32,
            64 => return nan_f64,
            128 => return undefined, // nan_f128,
            else => return undefined,
        }
    }
    pub fn snan(comptime T: type) T {
        return nan(T);
    }
    pub inline fn isNan(x: anytype) bool {
        return x != x;
    }
    pub fn isSignalNan(x: anytype) bool {
        return isNan(x);
    }
    pub fn isInf(x: anytype) bool {
        const T = @TypeOf(x);
        const TBits = @Type(.{ .Int = .{
            .signedness = .unsigned,
            .bits = @typeInfo(T).Float.bits,
        } });
        const remove_sign = ~@as(TBits, 0) >> 1;
        return @as(TBits, @bitCast(x)) & remove_sign == @as(TBits, @bitCast(inf(T)));
    }
    pub inline fn isPositiveInf(x: anytype) bool {
        return x == inf(@TypeOf(x));
    }
    pub inline fn isNegativeInf(x: anytype) bool {
        return x == -inf(@TypeOf(x));
    }
};
