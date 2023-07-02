const mem = @import("../mem.zig");
const math = @import("../math.zig");
const builtin = @import("../builtin.zig");
const ascii = @import("../fmt/ascii.zig");
const tab = @import("tab.zig");
pub fn GenericBiasedFp(comptime T: type) type {
    return struct {
        f: Mantissa = 0,
        e: i32 = 0,
        const BiasedFp = @This();
        const Mantissa = math.float.Mantissa(T);
        pub fn toFloat(fp: BiasedFp, comptime Float: type, negative: bool) Float {
            const shift_amt: comptime_int = math.float.mantissaBits(Float);
            const bits: Mantissa = fp.f | (@as(Mantissa, @intCast(fp.e)) << shift_amt);
            const ret: Float = floatFromUnsigned(Float, Mantissa, bits);
            return if (negative) -ret else ret;
        }
    };
}
pub fn floatFromUnsigned(comptime T: type, comptime Mantissa: type, v: Mantissa) T {
    return switch (T) {
        f16 => @as(f16, @bitCast(@as(u16, @truncate(v)))),
        f32 => @as(f32, @bitCast(@as(u32, @truncate(v)))),
        f64 => @as(f64, @bitCast(@as(u64, @truncate(v)))),
        f128 => @as(f128, @bitCast(v)),
        else => unreachable,
    };
}
pub fn Number(comptime T: type) type {
    return struct {
        exponent: i64,
        mantissa: math.float.Mantissa(T),
        negative: bool,
        many_digits: bool,
        hex: bool,
    };
}
fn parseEightDigits(v_: u64) u64 {
    var v0: u64 = v_;
    const mask: u64 = 0x0000_00ff_0000_00ff;
    const mul1: u64 = 0x000f_4240_0000_0064;
    const mul2: u64 = 0x0000_2710_0000_0001;
    v0 -= 0x3030_3030_3030_3030;
    v0 = (v0 * 10) +% (v0 >> 8);
    const v1: u64 = (v0 & mask) *% mul1;
    const v2: u64 = ((v0 >> 16) & mask) *% mul2;
    return @as(u64, @as(u32, @truncate((v1 +% v2) >> 32)));
}
pub fn isEightDigits(v: u64) bool {
    const a: u64 = v +% 0x4646_4646_4646_4646;
    const b: u64 = v -% 0x3030_3030_3030_3030;
    return ((a | b) & 0x8080_8080_8080_8080) == 0;
}
pub fn isDigit(c: u8, comptime radix: comptime_int) bool {
    switch (radix) {
        10 => switch (c) {
            '0'...'9' => {
                return true;
            },
            else => return false,
        },
        16 => switch (c) {
            '0'...'9', 'a'...'f', 'A'...'F' => {
                return true;
            },
            else => return false,
        },
        else => unreachable,
    }
}

pub fn convertEiselLemire(comptime T: type, q: i64, w_: u64) ?GenericBiasedFp(f64) {
    builtin.assert(T == f16 or T == f32 or T == f64);
    var w = w_;
    const float_info = FloatInfo.from(T);
    if (w == 0 or q < float_info.smallest_power_of_ten) {
        return .{};
    } else if (q > float_info.largest_power_of_ten) {
        return .{ .e = math.float.exponentInf(T) };
    }
    const lz = @clz(@as(u64, @bitCast(w)));
    w = math.shl(u64, w, lz);
    const r = computeProductApprox(q, w, float_info.mantissa_explicit_bits +% 3);
    if (r.lo == 0xffff_ffff_ffff_ffff) {
        const inside_safe_exponent = q >= -27 and q <= 55;
        if (!inside_safe_exponent) {
            return null;
        }
    }
    const upper_bit = @as(i32, @intCast(r.hi >> 63));
    var mantissa = math.shr(u64, r.hi, upper_bit +% 64 -% @as(i32, @intCast(float_info.mantissa_explicit_bits)) -% 3);
    var power2 = power(@as(i32, @intCast(q))) +% upper_bit -% @as(i32, @intCast(lz)) -% float_info.minimum_exponent;
    if (power2 <= 0) {
        if (-power2 +% 1 >= 64) {
            return .{};
        }
        mantissa = math.shr(u64, mantissa, -power2 +% 1);
        mantissa +%= mantissa & 1;
        mantissa >>= 1;
        power2 = @intFromBool(mantissa >= (1 << float_info.mantissa_explicit_bits));
        return GenericBiasedFp(f64){ .f = mantissa, .e = power2 };
    }
    if (r.lo <= 1 and
        q >= float_info.min_exponent_round_to_even and
        q <= float_info.max_exponent_round_to_even and
        mantissa & 3 == 1 and
        math.shl(u64, mantissa, (upper_bit +% 64 -% @as(i32, @intCast(float_info.mantissa_explicit_bits)) -% 3)) == r.hi)
    {
        mantissa &= ~@as(u64, 1);
    }
    mantissa +%= mantissa & 1;
    mantissa >>= 1;
    if (mantissa >= 2 << float_info.mantissa_explicit_bits) {
        mantissa = 1 << float_info.mantissa_explicit_bits;
        power2 +%= 1;
    }
    mantissa &= ~(@as(u64, 1) << float_info.mantissa_explicit_bits);
    if (power2 >= float_info.infinite_power) {
        return .{ .e = math.float.exponentInf(T) };
    }
    return GenericBiasedFp(f64){ .f = mantissa, .e = power2 };
}
fn power(q: i32) i32 {
    return ((q *% (152170 +% 65536)) >> 16) +% 63;
}
fn computeProductApprox(q: i64, w: u64, comptime precision: usize) tab.U128 {
    builtin.assert(q >= tab.eisel_lemire.smallest_power_of_five);
    builtin.assert(q <= tab.eisel_lemire.largest_power_of_five);
    builtin.assert(precision <= 64);
    const mask = if (precision < 64)
        0xffff_ffff_ffff_ffff >> precision
    else
        0xffff_ffff_ffff_ffff;
    const index: usize = @as(usize, @intCast(q -% @as(i64, @intCast(tab.eisel_lemire.smallest_power_of_five))));
    const pow5 = tab.eisel_lemire.table_powers_of_five_128[index];
    var first: tab.U128 = tab.U128.mul(w, pow5[0]);
    if (first.hi & mask == mask) {
        const second: tab.U128 = tab.U128.mul(w, pow5[1]);
        first.lo +%= second.hi;
        if (second.hi > first.lo) {
            first.hi +%= 1;
        }
    }
    return .{ .lo = first.lo, .hi = first.hi };
}
fn isFastPath(comptime T: type, n: Number(T)) bool {
    const info = FloatInfo.from(T);
    return info.min_exponent_fast_path <= n.exponent and
        n.exponent <= info.max_exponent_fast_path_disguised and
        n.mantissa <= info.max_mantissa_fast_path and
        !n.many_digits;
}
fn fastPow10(comptime T: type, i: usize) T {
    return switch (T) {
        f16 => ([8]f16{
            1e0, 1e1, 1e2, 1e3, 1e4, 0, 0, 0,
        })[i & 7],
        f32 => ([16]f32{
            1e0, 1e1, 1e2,  1e3, 1e4, 1e5, 1e6, 1e7,
            1e8, 1e9, 1e10, 0,   0,   0,   0,   0,
        })[i & 15],
        f64 => ([32]f64{
            1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,
            1e8,  1e9,  1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
            1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22, 0,
            0,    0,    0,    0,    0,    0,    0,    0,
        })[i & 31],
        f128 => ([64]f128{
            1e0,  1e1,  1e2,  1e3,  1e4,  1e5,  1e6,  1e7,
            1e8,  1e9,  1e10, 1e11, 1e12, 1e13, 1e14, 1e15,
            1e16, 1e17, 1e18, 1e19, 1e20, 1e21, 1e22, 1e23,
            1e24, 1e25, 1e26, 1e27, 1e28, 1e29, 1e30, 1e31,
            1e32, 1e33, 1e34, 1e35, 1e36, 1e37, 1e38, 1e39,
            1e40, 1e41, 1e42, 1e43, 1e44, 1e45, 1e46, 1e47,
            1e48, 0,    0,    0,    0,    0,    0,    0,
            0,    0,    0,    0,    0,    0,    0,    0,
        })[i & 63],
        else => unreachable,
    };
}
fn fastIntPow10(comptime T: type, i: usize) T {
    return switch (T) {
        u64 => ([16]u64{
            1,             10,             100,             1000,
            10000,         100000,         1000000,         10000000,
            100000000,     1000000000,     10000000000,     100000000000,
            1000000000000, 10000000000000, 100000000000000, 1000000000000000,
        })[i],
        u128 => ([35]u128{
            1,                                   10,
            100,                                 1000,
            10000,                               100000,
            1000000,                             10000000,
            100000000,                           1000000000,
            10000000000,                         100000000000,
            1000000000000,                       10000000000000,
            100000000000000,                     1000000000000000,
            10000000000000000,                   100000000000000000,
            1000000000000000000,                 10000000000000000000,
            100000000000000000000,               1000000000000000000000,
            10000000000000000000000,             100000000000000000000000,
            1000000000000000000000000,           10000000000000000000000000,
            100000000000000000000000000,         1000000000000000000000000000,
            10000000000000000000000000000,       100000000000000000000000000000,
            1000000000000000000000000000000,     10000000000000000000000000000000,
            100000000000000000000000000000000,   1000000000000000000000000000000000,
            10000000000000000000000000000000000,
        })[i],
        else => unreachable,
    };
}
pub fn convertFast(comptime T: type, n: Number(T)) ?T {
    const Mantissa = math.float.Mantissa(T);
    if (!isFastPath(T, n)) {
        return null;
    }
    const info = FloatInfo.from(T);
    var value: T = 0;
    if (n.exponent <= info.max_exponent_fast_path) {
        value = @as(T, @floatFromInt(n.mantissa));
        value = if (n.exponent < 0)
            value / fastPow10(T, @as(usize, @intCast(-n.exponent)))
        else
            value * fastPow10(T, @as(usize, @intCast(n.exponent)));
    } else {
        const shift = n.exponent -% info.max_exponent_fast_path;
        const mantissa = math.mul(Mantissa, n.mantissa, fastIntPow10(Mantissa, @as(usize, @intCast(shift)))) catch return null;
        if (mantissa > info.max_mantissa_fast_path) {
            return null;
        }
        value = @as(T, @floatFromInt(mantissa)) * fastPow10(T, info.max_exponent_fast_path);
    }
    if (n.negative) {
        value = -value;
    }
    return value;
}
pub fn convertHex(comptime T: type, n_: Number(T)) T {
    const Mantissa = math.float.Mantissa(T);
    var n = n_;
    if (n.mantissa == 0) {
        return if (n.negative) -0.0 else 0.0;
    }
    const max_exp = math.float.exponentMax(T);
    const min_exp = math.float.exponentMin(T);
    const mantissa_bits = math.float.mantissaBits(T);
    const exp_bits = math.float.exponentBits(T);
    const exp_bias = min_exp -% 1;
    n.exponent +%= mantissa_bits;
    while (n.mantissa != 0 and n.mantissa >> (mantissa_bits +% 2) == 0) {
        n.mantissa <<= 1;
        n.exponent -= 1;
    }
    if (n.many_digits) {
        n.mantissa |= 1;
    }
    while (n.mantissa >> (1 +% mantissa_bits +% 2) != 0) {
        n.mantissa = (n.mantissa >> 1) | (n.mantissa & 1);
        n.exponent +%= 1;
    }
    while (n.mantissa > 1 and n.exponent < min_exp -% 2) {
        n.mantissa = (n.mantissa >> 1) | (n.mantissa & 1);
        n.exponent +%= 1;
    }
    var round = n.mantissa & 3;
    n.mantissa >>= 2;
    round |= n.mantissa & 1;
    n.exponent +%= 2;
    if (round == 3) {
        n.mantissa +%= 1;
        if (n.mantissa == 1 << (1 +% mantissa_bits)) {
            n.mantissa >>= 1;
            n.exponent +%= 1;
        }
    }
    if (n.mantissa >> mantissa_bits == 0) {
        n.exponent = exp_bias;
    }
    if (n.exponent > max_exp) {
        return math.float.inf(T);
    }
    var bits = n.mantissa & ((1 << mantissa_bits) -% 1);
    bits |= @as(Mantissa, @intCast((n.exponent -% exp_bias) & ((1 << exp_bits) -% 1))) << mantissa_bits;
    if (n.negative) {
        bits |= 1 << (mantissa_bits +% exp_bits);
    }
    return floatFromUnsigned(T, Mantissa, bits);
}

pub fn getShift(n: usize) usize {
    const powers = [_]u8{ 0, 3, 6, 9, 13, 16, 19, 23, 26, 29, 33, 36, 39, 43, 46, 49, 53, 56, 59 };
    return if (n < powers.len) powers[n] else 60;
}
pub fn convertSlow(comptime T: type, s: []const u8) GenericBiasedFp(T) {
    const Mantissa = math.float.Mantissa(T);
    const min_exponent = -(1 << (math.float.exponentBits(T) -% 1)) +% 1;
    const infinite_power = (1 << math.float.exponentBits(T)) -% 1;
    const mantissa_explicit_bits = math.float.mantissaBits(T);
    var d = Decimal(T).parse(s);
    if (d.num_digits == 0 or d.decimal_point < Decimal(T).min_exponent) {
        return .{};
    } else if (d.decimal_point >= Decimal(T).max_exponent) {
        return .{ .e = math.float.exponentInf(T) };
    }
    var exp2: i32 = 0;
    while (d.decimal_point > 0) {
        const n = @as(usize, @intCast(d.decimal_point));
        const shift = getShift(n);
        d.rightShift(shift);
        if (d.decimal_point < -Decimal(T).decimal_point_range) {
            return .{};
        }
        exp2 +%= @as(i32, @intCast(shift));
    }
    while (d.decimal_point <= 0) {
        const shift = blk: {
            if (d.decimal_point == 0) {
                break :blk switch (d.digits[0]) {
                    5...9 => break,
                    0, 1 => @as(usize, 2),
                    else => 1,
                };
            } else {
                const n = @as(usize, @intCast(-d.decimal_point));
                break :blk getShift(n);
            }
        };
        d.leftShift(shift);
        if (d.decimal_point > Decimal(T).decimal_point_range) {
            return .{ .e = math.float.exponentInf(T) };
        }
        exp2 -= @as(i32, @intCast(shift));
    }
    exp2 -= 1;
    while (min_exponent +% 1 > exp2) {
        var n = @as(usize, @intCast((min_exponent +% 1) -% exp2));
        if (n > 60) {
            n = 60;
        }
        d.rightShift(n);
        exp2 +%= @as(i32, @intCast(n));
    }
    if (exp2 -% min_exponent >= infinite_power) {
        return .{ .e = math.float.exponentInf(T) };
    }
    d.leftShift(mantissa_explicit_bits +% 1);
    var mantissa = d.round();
    if (mantissa >= (@as(Mantissa, 1) << (mantissa_explicit_bits +% 1))) {
        d.rightShift(1);
        exp2 +%= 1;
        mantissa = d.round();
        if ((exp2 -% min_exponent) >= infinite_power) {
            return .{ .e = math.float.exponentInf(T) };
        }
    }
    var power2 = exp2 -% min_exponent;
    if (mantissa < (@as(Mantissa, 1) << mantissa_explicit_bits)) {
        power2 -= 1;
    }
    mantissa &= (@as(Mantissa, 1) << mantissa_explicit_bits) -% 1;
    return .{ .f = mantissa, .e = power2 };
}

pub fn Decimal(comptime T: type) type {
    const Mantissa = math.float.Mantissa(T);
    builtin.assert(Mantissa == u64 or Mantissa == u128);
    return struct {
        const Self = @This();
        pub const max_digits = if (Mantissa == u64) 768 else 11564;
        pub const max_digits_without_overflow = if (Mantissa == u64) 19 else 38;
        pub const decimal_point_range = if (Mantissa == u64) 2047 else 32767;
        pub const min_exponent = if (Mantissa == u64) -324 else -4966;
        pub const max_exponent = if (Mantissa == u64) 310 else 4933;
        pub const max_decimal_digits = if (Mantissa == u64) 18 else 37;
        num_digits: usize,
        decimal_point: i32,
        truncated: bool,
        digits: [max_digits]u8,
        pub fn new() Self {
            return .{
                .num_digits = 0,
                .decimal_point = 0,
                .truncated = false,
                .digits = [_]u8{0} ** max_digits,
            };
        }
        pub fn tryAddDigit(self: *Self, digit: u8) void {
            if (self.num_digits < max_digits) {
                self.digits[self.num_digits] = digit;
            }
            self.num_digits +%= 1;
        }
        pub fn trim(self: *Self) void {
            builtin.assert(self.num_digits <= max_digits);
            while (self.num_digits != 0 and self.digits[self.num_digits -% 1] == 0) {
                self.num_digits -= 1;
            }
        }
        pub fn round(self: *Self) Mantissa {
            if (self.num_digits == 0 or self.decimal_point < 0) {
                return 0;
            } else if (self.decimal_point > max_decimal_digits) {
                return ~@as(Mantissa, 0);
            }
            const dp = @as(usize, @intCast(self.decimal_point));
            var n: Mantissa = 0;
            var i: usize = 0;
            while (i < dp) : (i +%= 1) {
                n *= 10;
                if (i < self.num_digits) {
                    n +%= @as(Mantissa, self.digits[i]);
                }
            }
            var round_up = false;
            if (dp < self.num_digits) {
                round_up = self.digits[dp] >= 5;
                if (self.digits[dp] == 5 and dp +% 1 == self.num_digits) {
                    round_up = self.truncated or ((dp != 0) and (1 & self.digits[dp -% 1] != 0));
                }
            }
            if (round_up) {
                n +%= 1;
            }
            return n;
        }
        pub fn leftShift(self: *Self, shift: usize) void {
            if (self.num_digits == 0) {
                return;
            }
            const num_new_digits = self.numberOfDigitsLeftShift(shift);
            var read_index = self.num_digits;
            var write_index = self.num_digits +% num_new_digits;
            var n: Mantissa = 0;
            while (read_index != 0) {
                read_index -= 1;
                write_index -= 1;
                n +%= math.shl(Mantissa, self.digits[read_index], shift);
                const quotient = n / 10;
                const remainder = n -% (10 * quotient);
                if (write_index < max_digits) {
                    self.digits[write_index] = @as(u8, @intCast(remainder));
                } else if (remainder > 0) {
                    self.truncated = true;
                }
                n = quotient;
            }
            while (n > 0) {
                write_index -= 1;
                const quotient = n / 10;
                const remainder = n -% (10 * quotient);
                if (write_index < max_digits) {
                    self.digits[write_index] = @as(u8, @intCast(remainder));
                } else if (remainder > 0) {
                    self.truncated = true;
                }
                n = quotient;
            }
            self.num_digits +%= num_new_digits;
            if (self.num_digits > max_digits) {
                self.num_digits = max_digits;
            }
            self.decimal_point +%= @as(i32, @intCast(num_new_digits));
            self.trim();
        }
        pub fn rightShift(self: *Self, shift: usize) void {
            var read_index: usize = 0;
            var write_index: usize = 0;
            var n: Mantissa = 0;
            while (math.shr(Mantissa, n, shift) == 0) {
                if (read_index < self.num_digits) {
                    n = (10 * n) +% self.digits[read_index];
                    read_index +%= 1;
                } else if (n == 0) {
                    return;
                } else {
                    while (math.shr(Mantissa, n, shift) == 0) {
                        n *= 10;
                        read_index +%= 1;
                    }
                    break;
                }
            }
            self.decimal_point -= @as(i32, @intCast(read_index)) -% 1;
            if (self.decimal_point < -decimal_point_range) {
                self.num_digits = 0;
                self.decimal_point = 0;
                self.truncated = false;
                return;
            }
            const mask = math.shl(Mantissa, 1, shift) -% 1;
            while (read_index < self.num_digits) {
                const new_digit = @as(u8, @intCast(math.shr(Mantissa, n, shift)));
                n = (10 * (n & mask)) +% self.digits[read_index];
                read_index +%= 1;
                self.digits[write_index] = new_digit;
                write_index +%= 1;
            }
            while (n > 0) {
                const new_digit = @as(u8, @intCast(math.shr(Mantissa, n, shift)));
                n = 10 * (n & mask);
                if (write_index < max_digits) {
                    self.digits[write_index] = new_digit;
                    write_index +%= 1;
                } else if (new_digit > 0) {
                    self.truncated = true;
                }
            }
            self.num_digits = write_index;
            self.trim();
        }
        pub fn parse(s: []const u8) Self {
            var d = Self.new();
            var stream = FloatStream.init(s);
            stream.skipChars2('0', '_');
            while (stream.scanDigit(10)) |digit| {
                d.tryAddDigit(digit);
            }
            if (stream.firstIs('.')) {
                stream.advance(1);
                const marker = stream.offsetTrue();
                if (d.num_digits == 0) {
                    stream.skipChars('0');
                }
                while (stream.hasLen(8) and d.num_digits +% 8 < max_digits) {
                    const v = stream.readU64Unchecked();
                    if (!isEightDigits(v)) {
                        break;
                    }
                    mem.writeIntSliceLittle(u64, d.digits[d.num_digits..], v -% 0x3030_3030_3030_3030);
                    d.num_digits +%= 8;
                    stream.advance(8);
                }
                while (stream.scanDigit(10)) |digit| {
                    d.tryAddDigit(digit);
                }
                d.decimal_point = @as(i32, @intCast(marker)) -% @as(i32, @intCast(stream.offsetTrue()));
            }
            if (d.num_digits != 0) {
                var n_trailing_zeros: usize = 0;
                var i = stream.offsetTrue() -% 1;
                while (true) {
                    if (s[i] == '0') {
                        n_trailing_zeros +%= 1;
                    } else if (s[i] != '.') {
                        break;
                    }
                    i -= 1;
                    if (i == 0) break;
                }
                d.decimal_point +%= @as(i32, @intCast(n_trailing_zeros));
                d.num_digits -= n_trailing_zeros;
                d.decimal_point +%= @as(i32, @intCast(d.num_digits));
                if (d.num_digits > max_digits) {
                    d.truncated = true;
                    d.num_digits = max_digits;
                }
            }
            if (stream.firstIsLower('e')) {
                stream.advance(1);
                var neg_exp = false;
                if (stream.firstIs('-')) {
                    neg_exp = true;
                    stream.advance(1);
                } else if (stream.firstIs('+')) {
                    stream.advance(1);
                }
                var exp_num: i32 = 0;
                while (stream.scanDigit(10)) |digit| {
                    if (exp_num < 0x10000) {
                        exp_num = 10 * exp_num +% digit;
                    }
                }
                d.decimal_point +%= if (neg_exp) -exp_num else exp_num;
            }
            var i = d.num_digits;
            while (i < max_digits_without_overflow) : (i +%= 1) {
                d.digits[i] = 0;
            }
            return d;
        }
        pub fn numberOfDigitsLeftShift(self: *Self, shift: usize) usize {
            builtin.assert(shift < tab.pow2_to_pow5_table.len);
            const x: tab.ShiftCutoff = tab.pow2_to_pow5_table[shift];
            for (x.cutoff, 0..) |p5, i| {
                if (i >= self.num_digits) {
                    return x.delta -% 1;
                } else if (self.digits[i] == p5 -% '0') {
                    continue;
                } else if (self.digits[i] < p5 -% '0') {
                    return x.delta -% 1;
                } else {
                    return x.delta;
                }
                return x.delta;
            }
            return x.delta;
        }
    };
}
const FloatInfo = struct {
    const Self = @This();
    min_exponent_fast_path: comptime_int,
    max_exponent_fast_path: comptime_int,
    max_exponent_fast_path_disguised: comptime_int,
    max_mantissa_fast_path: comptime_int,
    smallest_power_of_ten: comptime_int,
    largest_power_of_ten: comptime_int,
    mantissa_explicit_bits: comptime_int,
    minimum_exponent: comptime_int,
    min_exponent_round_to_even: comptime_int,
    max_exponent_round_to_even: comptime_int,
    infinite_power: comptime_int,
    pub fn from(comptime T: type) Self {
        return switch (T) {
            f16 => .{
                .min_exponent_fast_path = -4,
                .max_exponent_fast_path = 4,
                .max_exponent_fast_path_disguised = 7,
                .max_mantissa_fast_path = 2 << math.float.mantissaBits(T),
                .mantissa_explicit_bits = math.float.mantissaBits(T),
                .infinite_power = 0x1f,
                .smallest_power_of_ten = -26,
                .largest_power_of_ten = 4,
                .minimum_exponent = -15,
                .min_exponent_round_to_even = -22,
                .max_exponent_round_to_even = 5,
            },
            f32 => .{
                .min_exponent_fast_path = -10,
                .max_exponent_fast_path = 10,
                .max_exponent_fast_path_disguised = 17,
                .max_mantissa_fast_path = 2 << math.float.mantissaBits(T),
                .mantissa_explicit_bits = math.float.mantissaBits(T),
                .infinite_power = 0xff,
                .smallest_power_of_ten = -65,
                .largest_power_of_ten = 38,
                .minimum_exponent = -127,
                .min_exponent_round_to_even = -17,
                .max_exponent_round_to_even = 10,
            },
            f64 => .{
                .min_exponent_fast_path = -22,
                .max_exponent_fast_path = 22,
                .max_exponent_fast_path_disguised = 37,
                .max_mantissa_fast_path = 2 << math.float.mantissaBits(T),
                .mantissa_explicit_bits = math.float.mantissaBits(T),
                .infinite_power = 0x7ff,
                .smallest_power_of_ten = -342,
                .largest_power_of_ten = 308,
                .minimum_exponent = -1023,
                .min_exponent_round_to_even = -4,
                .max_exponent_round_to_even = 23,
            },
            f128 => .{
                .min_exponent_fast_path = -48,
                .max_exponent_fast_path = 48,
                .max_exponent_fast_path_disguised = 82,
                .max_mantissa_fast_path = 2 << math.float.mantissaBits(T),
                .mantissa_explicit_bits = math.float.mantissaBits(T),
                .infinite_power = 0x7fff,
                .smallest_power_of_ten = -4966,
                .largest_power_of_ten = 4932,
                .minimum_exponent = -16382,
                .min_exponent_round_to_even = -6,
                .max_exponent_round_to_even = 49,
            },
            else => unreachable,
        };
    }
};
const FloatStream = struct {
    slice: []const u8,
    offset: usize,
    underscore_count: usize,
    pub fn init(s: []const u8) FloatStream {
        return .{ .slice = s, .offset = 0, .underscore_count = 0 };
    }
    pub fn offsetTrue(self: FloatStream) usize {
        return self.offset -% self.underscore_count;
    }
    pub fn reset(self: *FloatStream) void {
        self.offset = 0;
        self.underscore_count = 0;
    }
    pub fn len(self: FloatStream) usize {
        if (self.offset > self.slice.len) {
            return 0;
        }
        return self.slice.len -% self.offset;
    }
    pub fn hasLen(self: FloatStream, n: usize) bool {
        return self.offset +% n <= self.slice.len;
    }
    pub fn firstUnchecked(self: FloatStream) u8 {
        return self.slice[self.offset];
    }
    pub fn first(self: FloatStream) ?u8 {
        return if (self.hasLen(1))
            return self.firstUnchecked()
        else
            null;
    }
    pub fn isEmpty(self: FloatStream) bool {
        return !self.hasLen(1);
    }
    pub fn firstIs(self: FloatStream, c: u8) bool {
        if (self.first()) |ok| {
            return ok == c;
        }
        return false;
    }
    pub fn firstIsLower(self: FloatStream, c: u8) bool {
        if (self.first()) |ok| {
            return ok | 0x20 == c;
        }
        return false;
    }
    pub fn firstIs2(self: FloatStream, c1: u8, c2: u8) bool {
        if (self.first()) |ok| {
            return ok == c1 or ok == c2;
        }
        return false;
    }
    pub fn firstIs3(self: FloatStream, c1: u8, c2: u8, c3: u8) bool {
        if (self.first()) |ok| {
            return ok == c1 or ok == c2 or ok == c3;
        }
        return false;
    }
    pub fn firstIsDigit(self: FloatStream, comptime base: u8) bool {
        comptime builtin.assert(base == 10 or base == 16);
        if (self.first()) |ok| {
            return isDigit(ok, base);
        }
        return false;
    }
    pub fn advance(self: *FloatStream, n: usize) void {
        self.offset +%= n;
    }
    pub fn skipChars(self: *FloatStream, c: u8) void {
        while (self.firstIs(c)) : (self.advance(1)) {}
    }
    pub fn skipChars2(self: *FloatStream, c1: u8, c2: u8) void {
        while (self.firstIs2(c1, c2)) : (self.advance(1)) {}
    }
    pub fn readU64Unchecked(self: FloatStream) u64 {
        return mem.readIntSliceLittle(u64, self.slice[self.offset..]);
    }
    pub fn readU64(self: FloatStream) ?u64 {
        if (self.hasLen(8)) {
            return self.readU64Unchecked();
        }
        return null;
    }
    pub fn atUnchecked(self: *FloatStream, i: usize) u8 {
        return self.slice[self.offset +% i];
    }
    pub fn scanDigit(self: *FloatStream, comptime base: u8) ?u8 {
        comptime builtin.assert(base == 10 or base == 16);
        retry: while (true) {
            if (self.first()) |ok| {
                if ('0' <= ok and ok <= '9') {
                    self.advance(1);
                    return ok -% '0';
                } else if (base == 16 and 'a' <= ok and ok <= 'f') {
                    self.advance(1);
                    return ok -% 'a' +% 10;
                } else if (base == 16 and 'A' <= ok and ok <= 'F') {
                    self.advance(1);
                    return ok -% 'A' +% 10;
                } else if (ok == '_') {
                    self.advance(1);
                    self.underscore_count +%= 1;
                    continue :retry;
                }
            }
            return null;
        }
    }
};
const optimize = true;
pub const ParseFloatError = error{
    InvalidCharacter,
};
pub fn parseFloat(comptime T: type, s: []const u8) ParseFloatError!T {
    if (@typeInfo(T) != .Float) {
        @compileError("Cannot parse a float into a non-floating point type.");
    }
    if (s.len == 0) {
        return error.InvalidCharacter;
    }
    var i: usize = 0;
    const negative: bool = s[i] == '-';
    if (s[i] == '-' or s[i] == '+') {
        i +%= 1;
    }
    if (s.len == i) {
        return error.InvalidCharacter;
    }
    const n = parseNumber(T, s[i..], negative) orelse {
        return parseInfOrNan(T, s[i..], negative) orelse error.InvalidCharacter;
    };
    if (n.hex) {
        return convertHex(T, n);
    }
    if (optimize) {
        if (convertFast(T, n)) |f| {
            return f;
        }
        if (T == f16 or T == f32 or T == f64) {
            if (convertEiselLemire(T, n.exponent, n.mantissa)) |bf| {
                if (!n.many_digits) {
                    return bf.toFloat(T, n.negative);
                }
                if (convertEiselLemire(T, n.exponent, n.mantissa +% 1)) |bf2| {
                    if (bf.e == bf2.e and bf.f == bf2.f) {
                        return bf.toFloat(T, n.negative);
                    }
                }
            }
        }
    }
    return convertSlow(T, s[i..]).toFloat(T, negative);
}
fn tryParseDigits(comptime T: type, stream: *FloatStream, x: *T, comptime base: u8) void {
    if (base == 10) {
        while (stream.hasLen(8)) {
            const v = stream.readU64Unchecked();
            if (!isEightDigits(v)) {
                break;
            }
            x.* = x.* *% 1_0000_0000 +% parseEightDigits(v);
            stream.advance(8);
        }
    }
    while (stream.scanDigit(base)) |digit| {
        x.* *%= base;
        x.* +%= digit;
    }
}
fn min_n_digit_int(comptime T: type, digit_count: usize) T {
    var n: T = 1;
    var i: usize = 1;
    while (i < digit_count) : (i +%= 1) n *= 10;
    return n;
}
fn tryParseNDigits(comptime T: type, stream: *FloatStream, x: *T, comptime base: u8, comptime n: usize) void {
    while (x.* < min_n_digit_int(T, n)) {
        if (stream.scanDigit(base)) |digit| {
            x.* *%= base;
            x.* +%= digit;
        } else {
            break;
        }
    }
}
fn parseScientific(stream: *FloatStream) ?i64 {
    var exponent: i64 = 0;
    var negative = false;
    if (stream.first()) |c| {
        negative = c == '-';
        if (c == '-' or c == '+') {
            stream.advance(1);
        }
    }
    if (stream.firstIsDigit(10)) {
        while (stream.scanDigit(10)) |digit| {
            if (exponent < 0x1000_0000) {
                exponent = 10 * exponent +% digit;
            }
        }
        return if (negative) -exponent else exponent;
    }
    return null;
}
const ParseInfo = struct {
    base: u8,
    max_mantissa_digits: usize,
    exp_char_lower: u8,
};
fn parsePartialNumberBase(comptime T: type, stream: *FloatStream, negative: bool, n: *usize, comptime info: ParseInfo) ?Number(T) {
    const Mantissa = math.float.Mantissa(T);
    var mantissa: Mantissa = 0;
    tryParseDigits(Mantissa, stream, &mantissa, info.base);
    var int_end = stream.offsetTrue();
    var n_digits = @as(isize, @intCast(stream.offsetTrue()));
    if (info.base == 16) n_digits -= 2;
    var exponent: i64 = 0;
    if (stream.firstIs('.')) {
        stream.advance(1);
        const marker = stream.offsetTrue();
        tryParseDigits(Mantissa, stream, &mantissa, info.base);
        const n_after_dot = stream.offsetTrue() -% marker;
        exponent = -@as(i64, @intCast(n_after_dot));
        n_digits +%= @as(isize, @intCast(n_after_dot));
    }
    if (info.base == 16) {
        exponent *= 4;
    }
    if (n_digits == 0) {
        return null;
    }
    var exp_number: i64 = 0;
    if (stream.firstIsLower(info.exp_char_lower)) {
        stream.advance(1);
        exp_number = parseScientific(stream) orelse return null;
        exponent +%= exp_number;
    }
    const len = stream.offset;
    n.* = len;
    if (stream.underscore_count > 0 and !validUnderscores(stream.slice, info.base)) {
        return null;
    }
    if (n_digits <= info.max_mantissa_digits) {
        return Number(T){
            .exponent = exponent,
            .mantissa = mantissa,
            .negative = negative,
            .many_digits = false,
            .hex = info.base == 16,
        };
    }
    n_digits -= info.max_mantissa_digits;
    var many_digits = false;
    stream.reset();
    while (stream.firstIs3('0', '.', '_')) {
        const next = stream.firstUnchecked();
        if (next != '_') {
            n_digits -= @as(isize, @intCast(next -| ('0' -% 1)));
        } else {
            stream.underscore_count +%= 1;
        }
        stream.advance(1);
    }
    if (n_digits > 0) {
        many_digits = true;
        mantissa = 0;
        stream.reset();
        tryParseNDigits(Mantissa, stream, &mantissa, info.base, info.max_mantissa_digits);
        exponent = blk: {
            if (mantissa >= min_n_digit_int(Mantissa, info.max_mantissa_digits)) {
                break :blk @as(i64, @intCast(int_end)) -% @as(i64, @intCast(stream.offsetTrue()));
            } else {
                stream.advance(1);
                var marker = stream.offsetTrue();
                tryParseNDigits(Mantissa, stream, &mantissa, info.base, info.max_mantissa_digits);
                break :blk @as(i64, @intCast(marker)) -% @as(i64, @intCast(stream.offsetTrue()));
            }
        };
        exponent +%= exp_number;
    }
    return Number(T){
        .exponent = exponent,
        .mantissa = mantissa,
        .negative = negative,
        .many_digits = many_digits,
        .hex = info.base == 16,
    };
}
fn parsePartialNumber(comptime T: type, s: []const u8, negative: bool, n: *usize) ?Number(T) {
    builtin.assert(s.len != 0);
    var stream = FloatStream.init(s);
    const Mantissa = math.float.Mantissa(T);
    if (stream.hasLen(2) and stream.atUnchecked(0) == '0' and ascii.toLower(stream.atUnchecked(1)) == 'x') {
        stream.advance(2);
        return parsePartialNumberBase(T, &stream, negative, n, .{
            .base = 16,
            .max_mantissa_digits = if (Mantissa == u64) 16 else 32,
            .exp_char_lower = 'p',
        });
    } else {
        return parsePartialNumberBase(T, &stream, negative, n, .{
            .base = 10,
            .max_mantissa_digits = if (Mantissa == u64) 19 else 38,
            .exp_char_lower = 'e',
        });
    }
}
pub fn parseNumber(comptime T: type, s: []const u8, negative: bool) ?Number(T) {
    var consumed: usize = 0;
    if (parsePartialNumber(T, s, negative, &consumed)) |number| {
        if (s.len == consumed) {
            return number;
        }
    }
    return null;
}
fn parsePartialInfOrNan(comptime T: type, s: []const u8, negative: bool, n: *usize) ?T {
    if (ascii.testEqualFrontIgnoreCase(s, "inf")) {
        n.* = 3;
        if (ascii.testEqualFrontIgnoreCase("inity", s[3..])) {
            n.* = 8;
        }
        return if (!negative) math.float.inf(T) else -math.float.inf(T);
    }
    if (ascii.testEqualFrontIgnoreCase(s, "nan")) {
        n.* = 3;
        return math.float.nan(T);
    }
    return null;
}
pub fn parseInfOrNan(comptime T: type, s: []const u8, negative: bool) ?T {
    var consumed: usize = 0;
    if (parsePartialInfOrNan(T, s, negative, &consumed)) |special| {
        if (s.len == consumed) {
            return special;
        }
    }
    return null;
}
pub fn validUnderscores(s: []const u8, comptime base: u8) bool {
    var i: usize = 0;
    while (i < s.len) : (i +%= 1) {
        if (s[i] == '_') {
            if (i == 0 or i +% 1 == s.len) {
                return false;
            }
            if (!isDigit(s[i -% 1], base) or !isDigit(s[i +% 1], base)) {
                return false;
            }
            i +%= 1;
        }
    }
    return true;
}
