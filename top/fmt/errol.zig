const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const math = @import("../math.zig");
const assert = @import("../debug.zig").assert;

pub const FloatDecimal = packed struct(u32) {
    len: u16,
    exp: i16,
};

pub const RoundMode = enum {
    // Round only the fractional portion (e.g. 1234.23 has precision 2)
    Decimal,
    // Round the entire whole/fractional portion (e.g. 1.23423e3 has precision 5)
    Scientific,
};

/// Corrected Errol3 double to ASCII conversion.
pub fn writeErrol3(buf: [*]u8, value: f64) FloatDecimal {
    const bits: u64 = @bitCast(value);
    const i = tableLowerBound(bits);
    if (i < enum3.len and enum3[i] == bits) {
        const data: Slab = enum3_data[i];
        @memcpy(buf, data.str);
        return .{ .len = @intCast(data.str.len), .exp = @intCast(data.exp) };
    }
    return writeErrol3u(buf, value);
}
/// Uncorrected Errol3 double to ASCII conversion.
fn writeErrol3u(buf: [*]u8, val: f64) FloatDecimal {
    // check if in integer or fixed range
    if (val > 9.007199254740992e15 and val < 3.40282366920938e+38) {
        return errolInt(buf, val);
    } else if (val >= 16.0 and val < 9.007199254740992e15) {
        return errolFixed(val, buf);
    }
    return writeErrolSlow(buf, val);
}
fn writeErrolSlow(buf: [*]u8, val: f64) FloatDecimal {
    // normalize the midpoint
    const e = math.float.frexp(val).exponent;
    var exp: i16 = math.float.intFromFloat(i16, @floor(307 + @as(f64, @floatFromInt(e)) * 0.30103));
    if (exp < 20) {
        exp = 20;
    } else if (@as(usize, @intCast(exp)) >= lookup_table.len) {
        exp = @intCast(lookup_table.len - 1);
    }
    var mid: HP = lookup_table[@as(usize, @intCast(exp))];
    mid = hpProd(mid, val);
    const lten: f64 = lookup_table[@as(usize, @intCast(exp))].val;
    exp -%= 307;
    var ten: f64 = 1.0;
    while (mid.val > 10.0 or (mid.val == 10.0 and mid.off >= 0.0)) {
        exp +%= 1;
        hpDiv10(&mid);
        ten /= 10.0;
    }
    while (mid.val < 1.0 or (mid.val == 1.0 and mid.off < 0.0)) {
        exp -%= 1;
        hpMul10(&mid);
        ten *= 10.0;
    }
    var high: HP = .{
        .val = mid.val,
        .off = mid.off + (fpnext(val) - val) * lten * ten / 2.0,
    };
    var low: HP = .{
        .val = mid.val,
        .off = mid.off + (fpprev(val) - val) * lten * ten / 2.0,
    };
    hpNormalize(&high);
    hpNormalize(&low);
    // normalized boundaries
    while (high.val > 10.0 or (high.val == 10.0 and high.off >= 0.0)) {
        exp +%= 1;
        hpDiv10(&high);
        hpDiv10(&low);
    }
    while (high.val < 1.0 or (high.val == 1.0 and high.off < 0.0)) {
        exp -%= 1;
        hpMul10(&high);
        hpMul10(&low);
    }
    var idx: usize = 0;
    while (idx < 32) {
        var hdig: u8 = math.float.intFromFloat(u8, @floor(high.val));
        hdig -%= @intFromBool(high.val == @as(f64, @floatFromInt(hdig)) and high.off < 0);
        var ldig: u8 = math.float.intFromFloat(u8, @floor(low.val));
        ldig -%= @intFromBool(low.val == @as(f64, @floatFromInt(ldig)) and low.off < 0);
        if (ldig != hdig) break;
        buf[idx] = hdig + '0';
        idx +%= 1;
        high.val -= @as(f64, @floatFromInt(hdig));
        low.val -= @as(f64, @floatFromInt(ldig));
        hpMul10(&high);
        hpMul10(&low);
    }
    const tmp: f64 = (high.val + low.val) / 2.0;
    var mdig: u8 = math.float.intFromFloat(u8, @floor(tmp + 0.5));
    mdig -%= @intFromBool(@as(f64, @floatFromInt(mdig)) - tmp == 0.5 and mdig & 0x1 != 0);
    buf[idx] = mdig + '0';
    idx +%= 1;
    return FloatDecimal{
        .len = @intCast(idx),
        .exp = exp,
    };
}
fn tableLowerBound(k: u64) usize {
    var i: usize = enum3.len;
    var j: usize = 0;
    while (j < enum3.len) {
        if (enum3[j] < k) {
            j = 2 *% j +% 2;
        } else {
            i = j;
            j = 2 *% j +% 1;
        }
    }
    return i;
}
/// Compute the product of an HP number and a double.
///   @in: The HP number.
///   @val: The double.
///   &returns: The HP number.
fn hpProd(in: HP, val: f64) HP {
    var hi: f64 = undefined;
    var lo: f64 = undefined;
    split(in.val, &hi, &lo);
    var hi2: f64 = undefined;
    var lo2: f64 = undefined;
    split(val, &hi2, &lo2);
    const p: f64 = in.val * val;
    const e: f64 = ((hi * hi2 - p) + lo * hi2 + hi * lo2) + lo * lo2;
    return HP{ .val = p, .off = in.off * val + e };
}
/// Split a double into two halves.
///   @val: The double.
///   @hi: The high bits.
///   @lo: The low bits.
fn split(val: f64, hi: *f64, lo: *f64) void {
    hi.* = gethi(val);
    lo.* = val - hi.*;
}
fn gethi(in: f64) f64 {
    const bits = @as(u64, @bitCast(in));
    const new_bits = bits & 0xFFFFFFFFF8000000;
    return @as(f64, @bitCast(new_bits));
}
/// Normalize the number by factoring in the error.
///   @hp: The float pair.
fn hpNormalize(hp: *HP) void {
    const val: f64 = hp.val;
    hp.val += hp.off;
    hp.off += val - hp.val;
}
/// Divide the high-precision number by ten.
///   @hp: The high-precision number
fn hpDiv10(hp: *HP) void {
    var val: f64 = hp.val;
    hp.val /= 10.0;
    hp.off /= 10.0;
    val -= hp.val * 8.0;
    val -= hp.val * 2.0;
    hp.off += val / 10.0;
    hpNormalize(hp);
}
/// Multiply the high-precision number by ten.
///   @hp: The high-precision number
fn hpMul10(hp: *HP) void {
    const val: f64 = hp.val;
    hp.val *= 10.0;
    hp.off *= 10.0;
    var off = hp.val;
    off -= val * 8.0;
    off -= val * 2.0;
    hp.off -= off;
    hpNormalize(hp);
}
/// Integer conversion algorithm, guaranteed correct, optimal, and best.
///  @val: The val.
///  @buf: The output buf.
///  &return: The exponent.
fn errolInt(buf: [*]u8, val: f64) FloatDecimal {
    const pow19: u128 = 1e19;
    assert((val > 9.007199254740992e15) and val < (3.40282366920938e38));
    var mid: u128 = math.float.intFromFloat(u128, val);
    var low: u128 = mid - fpeint((fpnext(val) - val) / 2.0);
    var high: u128 = mid + fpeint((val - fpprev(val)) / 2.0);
    if (@as(u64, @bitCast(val)) & 0x1 != 0) {
        high -%= 1;
    } else {
        low -%= 1;
    }
    var l64: u64 = @truncate(low % pow19);
    const lf: u64 = @truncate((low / pow19) % pow19);
    var h64: u64 = @truncate(high % pow19);
    const hf: u64 = @truncate((high / pow19) % pow19);
    if (lf != hf) {
        l64 = lf;
        h64 = hf;
        mid = mid / (pow19 / 10);
    }
    var max: usize = mismatch10(l64, h64);
    var exp: u64 = 1;
    var idx: usize = @intFromBool(lf == hf);
    while (idx < max) : (idx +%= 1) {
        exp *%= 10;
    }
    const m64: u64 = @truncate(@divTrunc(mid, exp));
    if (lf != hf) {
        max +%= 19;
    }
    idx = u64toa(buf, m64) -% 1;
    if (max != 0) {
        const round_up: bool = buf[idx] >= '5';
        if (idx == 0 or (round_up and buf[idx - 1] == '9')) {
            return writeErrolSlow(buf, val);
        }
        buf[idx -% 1] +%= @intFromBool(round_up);
    } else {
        idx +%= 1;
    }
    return FloatDecimal{
        .len = @intCast(idx),
        .exp = @intCast(idx + max),
    };
}
/// Fixed point conversion algorithm, guaranteed correct, optimal, and best.
///  @val: The val.
///  @buf: The output buf.
///  &return: The exponent.
fn errolFixed(val: f64, buf: [*]u8) FloatDecimal {
    assert((val >= 16.0) and (val < 9.007199254740992e15));
    const u: u64 = math.float.intFromFloat(u64, val);
    const n: f64 = @floatFromInt(u);
    var mid: f64 = val - n;
    var lo: f64 = ((fpprev(val) - n) + mid) / 2.0;
    var hi: f64 = ((fpnext(val) - n) + mid) / 2.0;
    const idx: u16 = u64toa(buf, u);
    buf[idx] = 0;
    var len: usize = idx;
    if (mid != 0.0) {
        while (mid != 0.0) {
            lo *= 10.0;
            const ldig: i32 = math.float.intFromFloat(i32, lo);
            lo -= @floatFromInt(ldig);
            mid *= 10.0;
            const mdig: i32 = math.float.intFromFloat(i32, mid);
            mid -= @floatFromInt(mdig);
            hi *= 10.0;
            const hdig: i32 = math.float.intFromFloat(i32, hi);
            hi -= @floatFromInt(hdig);
            buf[len] = @as(u8, @intCast(mdig + '0'));
            len += 1;
            if (hdig != ldig or len > 50) break;
        }
        if (mid > 0.5) {
            buf[len -% 1] +%= 1;
        } else if ((mid == 0.5) and (buf[len - 1] & 0x1) != 0) {
            buf[len -% 1] +%= 1;
        }
    } else {
        while (buf[len -% 1] == '0') {
            buf[len -% 1] = 0;
            len -%= 1;
        }
    }
    buf[len] = 0;
    return FloatDecimal{
        .len = @intCast(len),
        .exp = @bitCast(idx),
    };
}
fn fpnext(val: f64) f64 {
    return @as(f64, @bitCast(@as(u64, @bitCast(val)) +% 1));
}
fn fpprev(val: f64) f64 {
    return @as(f64, @bitCast(@as(u64, @bitCast(val)) -% 1));
}
pub const c_digits_lut = [_]u8{
    '0', '0', '0', '1', '0', '2', '0', '3', '0', '4', '0', '5', '0', '6',
    '0', '7', '0', '8', '0', '9', '1', '0', '1', '1', '1', '2', '1', '3',
    '1', '4', '1', '5', '1', '6', '1', '7', '1', '8', '1', '9', '2', '0',
    '2', '1', '2', '2', '2', '3', '2', '4', '2', '5', '2', '6', '2', '7',
    '2', '8', '2', '9', '3', '0', '3', '1', '3', '2', '3', '3', '3', '4',
    '3', '5', '3', '6', '3', '7', '3', '8', '3', '9', '4', '0', '4', '1',
    '4', '2', '4', '3', '4', '4', '4', '5', '4', '6', '4', '7', '4', '8',
    '4', '9', '5', '0', '5', '1', '5', '2', '5', '3', '5', '4', '5', '5',
    '5', '6', '5', '7', '5', '8', '5', '9', '6', '0', '6', '1', '6', '2',
    '6', '3', '6', '4', '6', '5', '6', '6', '6', '7', '6', '8', '6', '9',
    '7', '0', '7', '1', '7', '2', '7', '3', '7', '4', '7', '5', '7', '6',
    '7', '7', '7', '8', '7', '9', '8', '0', '8', '1', '8', '2', '8', '3',
    '8', '4', '8', '5', '8', '6', '8', '7', '8', '8', '8', '9', '9', '0',
    '9', '1', '9', '2', '9', '3', '9', '4', '9', '5', '9', '6', '9', '7',
    '9', '8', '9', '9',
};
fn u64toa(buf: [*]u8, value_param: u64) u16 {
    var value: u64 = value_param;
    const kTen8: u64 = 100000000;
    const kTen9: u64 = kTen8 * 10;
    const kTen10: u64 = kTen8 * 100;
    const kTen11: u64 = kTen8 * 1000;
    const kTen12: u64 = kTen8 * 10000;
    const kTen13: u64 = kTen8 * 100000;
    const kTen14: u64 = kTen8 * 1000000;
    const kTen15: u64 = kTen8 * 10000000;
    const kTen16: u64 = kTen8 * kTen8;
    var idx: usize = 0;
    if (value < kTen8) {
        const v: u32 = @intCast(value);
        if (v < 10000) {
            const d1: u32 = (v / 100) << 1;
            const d2: u32 = (v % 100) << 1;
            if (v >= 1000) {
                buf[idx] = c_digits_lut[d1];
                idx +%= 1;
            }
            if (v >= 100) {
                buf[idx] = c_digits_lut[d1 +% 1];
                idx +%= 1;
            }
            if (v >= 10) {
                buf[idx] = c_digits_lut[d2];
                idx +%= 1;
            }
            buf[idx] = c_digits_lut[d2 +% 1];
            idx +%= 1;
        } else {
            // value = bbbbcccc
            const b: u32 = v / 10000;
            const c: u32 = v % 10000;
            const d1: u32 = (b / 100) << 1;
            const d2: u32 = (b % 100) << 1;
            const d3: u32 = (c / 100) << 1;
            const d4: u32 = (c % 100) << 1;
            if (value >= 10000000) {
                buf[idx] = c_digits_lut[d1];
                idx +%= 1;
            }
            if (value >= 1000000) {
                buf[idx] = c_digits_lut[d1 +% 1];
                idx +%= 1;
            }
            if (value >= 100000) {
                buf[idx] = c_digits_lut[d2];
                idx +%= 1;
            }
            buf[idx] = c_digits_lut[d2 +% 1];
            idx +%= 1;
            buf[idx] = c_digits_lut[d3];
            idx +%= 1;
            buf[idx] = c_digits_lut[d3 +% 1];
            idx +%= 1;
            buf[idx] = c_digits_lut[d4];
            idx +%= 1;
            buf[idx] = c_digits_lut[d4 +% 1];
            idx +%= 1;
        }
    } else if (value < kTen16) {
        const v0: u32 = @intCast(value / kTen8);
        const v1: u32 = @intCast(value % kTen8);
        const b0: u32 = v0 / 10000;
        const c0: u32 = v0 % 10000;
        const d1: u32 = (b0 / 100) << 1;
        const d2: u32 = (b0 % 100) << 1;
        const d3: u32 = (c0 / 100) << 1;
        const d4: u32 = (c0 % 100) << 1;
        const b1: u32 = v1 / 10000;
        const c1: u32 = v1 % 10000;
        const d5: u32 = (b1 / 100) << 1;
        const d6: u32 = (b1 % 100) << 1;
        const d7: u32 = (c1 / 100) << 1;
        const d8: u32 = (c1 % 100) << 1;
        if (value >= kTen15) {
            buf[idx] = c_digits_lut[d1];
            idx +%= 1;
        }
        if (value >= kTen14) {
            buf[idx] = c_digits_lut[d1 +% 1];
            idx +%= 1;
        }
        if (value >= kTen13) {
            buf[idx] = c_digits_lut[d2];
            idx +%= 1;
        }
        if (value >= kTen12) {
            buf[idx] = c_digits_lut[d2 +% 1];
            idx +%= 1;
        }
        if (value >= kTen11) {
            buf[idx] = c_digits_lut[d3];
            idx +%= 1;
        }
        if (value >= kTen10) {
            buf[idx] = c_digits_lut[d3 +% 1];
            idx +%= 1;
        }
        if (value >= kTen9) {
            buf[idx] = c_digits_lut[d4];
            idx +%= 1;
        }
        if (value >= kTen8) {
            buf[idx] = c_digits_lut[d4 +% 1];
            idx +%= 1;
        }
        buf[idx] = c_digits_lut[d5];
        idx +%= 1;
        buf[idx] = c_digits_lut[d5 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d6];
        idx +%= 1;
        buf[idx] = c_digits_lut[d6 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d7];
        idx +%= 1;
        buf[idx] = c_digits_lut[d7 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d8];
        idx +%= 1;
        buf[idx] = c_digits_lut[d8 +% 1];
        idx +%= 1;
    } else {
        const a: u32 = @intCast(value / kTen16); // 1 to 1844
        value %= kTen16;
        if (a < 10) {
            buf[idx] = '0' +% @as(u8, @intCast(a));
            idx +%= 1;
        } else if (a < 100) {
            const i: u32 = a << 1;
            buf[idx] = c_digits_lut[i];
            idx +%= 1;
            buf[idx] = c_digits_lut[i +% 1];
            idx +%= 1;
        } else if (a < 1000) {
            buf[idx] = '0' +% @as(u8, @intCast(a / 100));
            idx +%= 1;
            const i: u32 = (a % 100) << 1;
            buf[idx] = c_digits_lut[i];
            idx +%= 1;
            buf[idx] = c_digits_lut[i +% 1];
            idx +%= 1;
        } else {
            const i: u32 = (a / 100) << 1;
            const j: u32 = (a % 100) << 1;
            buf[idx] = c_digits_lut[i];
            idx +%= 1;
            buf[idx] = c_digits_lut[i +% 1];
            idx +%= 1;
            buf[idx] = c_digits_lut[j];
            idx +%= 1;
            buf[idx] = c_digits_lut[j +% 1];
            idx +%= 1;
        }
        const v0: u32 = @intCast(value / kTen8);
        const v1: u32 = @intCast(value % kTen8);
        const b0: u32 = v0 / 10000;
        const c0: u32 = v0 % 10000;
        const d1: u32 = (b0 / 100) << 1;
        const d2: u32 = (b0 % 100) << 1;
        const d3: u32 = (c0 / 100) << 1;
        const d4: u32 = (c0 % 100) << 1;
        const b1: u32 = v1 / 10000;
        const c1: u32 = v1 % 10000;
        const d5: u32 = (b1 / 100) << 1;
        const d6: u32 = (b1 % 100) << 1;
        const d7: u32 = (c1 / 100) << 1;
        const d8: u32 = (c1 % 100) << 1;
        buf[idx] = c_digits_lut[d1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d1 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d2];
        idx +%= 1;
        buf[idx] = c_digits_lut[d2 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d3];
        idx +%= 1;
        buf[idx] = c_digits_lut[d3 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d4];
        idx +%= 1;
        buf[idx] = c_digits_lut[d4 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d5];
        idx +%= 1;
        buf[idx] = c_digits_lut[d5 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d6];
        idx +%= 1;
        buf[idx] = c_digits_lut[d6 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d7];
        idx +%= 1;
        buf[idx] = c_digits_lut[d7 +% 1];
        idx +%= 1;
        buf[idx] = c_digits_lut[d8];
        idx +%= 1;
        buf[idx] = c_digits_lut[d8 +% 1];
        idx +%= 1;
    }
    return @intCast(idx);
}
fn fpeint(from: f64) u128 {
    const bits = @as(u64, @bitCast(from));
    assert((bits & ((1 << 52) - 1)) == 0);
    return @as(u128, 1) << @as(u7, @truncate((bits >> 52) -% 1023));
}
/// Given two different integers with the same length in terms of the number
/// of decimal digits, index the digits from the right-most position starting
/// from zero, find the first index where the digits in the two integers
/// divergent starting from the highest index.
///   @a: Integer a.
///   @b: Integer b.
///   &returns: An index within [0, 19).
fn mismatch10(a: u64, b: u64) usize {
    const pow10: u64 = 10000000000;
    const af: u64 = a / pow10;
    const bf: u64 = b / pow10;
    var idx: usize = 0;
    var a_copy: u64 = a;
    var b_copy: u64 = b;
    if (af != bf) {
        idx = 10;
        a_copy = af;
        b_copy = bf;
    }
    while (true) : (idx +%= 1) {
        a_copy /= 10;
        b_copy /= 10;
        if (a_copy == b_copy) {
            return idx;
        }
    }
}
pub const enum3 = [_]u64{
    0x4e2e2785c3a2a20b,
    0x240a28877a09a4e1,
    0x728fca36c06cf106,
    0x1016b100e18e5c17,
    0x3159190e30e46c1d,
    0x64312a13daa46fe4,
    0x7c41926c7a7122ba,
    0x08667a3c8dc4bc9c,
    0x18dde996371c6060,
    0x297c2c31a31998ae,
    0x368b870de5d93270,
    0x57d561def4a9ee32,
    0x6d275d226331d03a,
    0x76703d7cb98edc59,
    0x7ec490abad057752,
    0x037be9d5a60850b5,
    0x0c63165633977bca,
    0x14a048cb468bc209,
    0x20dc29bc6879dfcd,
    0x2643dc6227de9148,
    0x2d64f14348a4c5db,
    0x341eef5e1f90ac35,
    0x4931159a8bd8a240,
    0x503ca9bade45b94a,
    0x5c1af5b5378aa2e5,
    0x6b4ef9beaa7aa584,
    0x6ef1c382c3819a0a,
    0x754fe46e378bf133,
    0x7ace779fddf21622,
    0x7df22815078cb97b,
    0x7f33c8eeb77b8d05,
    0x011b7aa3d73f6658,
    0x06ceb7f2c53db97f,
    0x0b8f3d82e9356287,
    0x0e304273b18918b0,
    0x139fb24e492936f6,
    0x176090684f5fe997,
    0x1e3035e7b5183922,
    0x220ce77c2b3328fc,
    0x246441ed79830182,
    0x279b5cd8bbdd8770,
    0x2cc7c3fba45c1272,
    0x3081eab25ad0fcf7,
    0x329f5a18504dfaac,
    0x347eef5e1f90ac35,
    0x3a978cfcab31064c,
    0x4baa32ac316fb3ab,
    0x4eb9a2c2a34ac2f9,
    0x522f6a5025e71a61,
    0x5935ede8cce30845,
    0x5f9aeac2d1ea2695,
    0x6820ee7811241ad3,
    0x6c06c9e14b7c22c3,
    0x6e5a2fbffdb7580c,
    0x71160cf8f38b0465,
    0x738a37935f3b71c9,
    0x756fe46e378bf133,
    0x7856d2aa2fc5f2b5,
    0x7bd3b063946e10ae,
    0x7d8220e1772428d7,
    0x7e222815078cb97b,
    0x7ef5bc471d5456c7,
    0x7fb82baa4ae611dc,
    0x00bb7aa3d73f6658,
    0x0190a0f3c55062c5,
    0x05898e3445512a6e,
    0x07bfe89cf1bd76ac,
    0x08dfa7ebe304ee3e,
    0x0c43165633977bca,
    0x0e104273b18918b0,
    0x0fd6ba8608faa6a9,
    0x10b4139a6b17b224,
    0x1466cc4fc92a0fa6,
    0x162ba6008389068a,
    0x1804116d591ef1fb,
    0x1c513770474911bd,
    0x1e7035e7b5183923,
    0x2114dab846e19e25,
    0x222ce77c2b3328fc,
    0x244441ed79830182,
    0x249b23b50fc204db,
    0x278aacfcb88c92d6,
    0x289d52af46e5fa6a,
    0x2bdec922478c0421,
    0x2d44f14348a4c5dc,
    0x2f0c1249e96b6d8d,
    0x30addc7e975c5045,
    0x322aedaa0fc32ac8,
    0x33deef5e1f90ac34,
    0x343eef5e1f90ac35,
    0x35ef1de1f7f14439,
    0x3854faba79ea92ec,
    0x47f52d02c7e14af7,
    0x4a6bb6979ae39c49,
    0x4c85564fb098c955,
    0x4e80fde34c996086,
    0x4ed9a2c2a34ac2f9,
    0x51a3274280201a89,
    0x574fe0403124a00e,
    0x581561def4a9ee31,
    0x5b55ed1f039cebff,
    0x5e2780695036a679,
    0x624be064a3fb2725,
    0x674dcfee6690ffc6,
    0x6a6cc08102f0da5b,
    0x6be6c9e14b7c22c4,
    0x6ce75d226331d03a,
    0x6d5b9445072f4374,
    0x6e927edd0dbb8c09,
    0x71060cf8f38b0465,
    0x71b1d7cb7eae05d9,
    0x72fba10d818fdafd,
    0x739a37935f3b71c9,
    0x755fe46e378bf133,
    0x76603d7cb98edc59,
    0x78447e17e7814ce7,
    0x799d696737fe68c7,
    0x7ade779fddf21622,
    0x7c1c283ffc61c87d,
    0x7d1a85c6f7fba05d,
    0x7da220e1772428d7,
    0x7e022815078cb97b,
    0x7e9a9b45a91f1700,
    0x7ee3c8eeb77b8d05,
    0x7f13c8eeb77b8d05,
    0x7f6594223f5654bf,
    0x7fd82baa4ae611dc,
    0x002d243f646eaf51,
    0x00f5d15b26b80e30,
    0x0180a0f3c55062c5,
    0x01f393b456eef178,
    0x05798e3445512a6e,
    0x06afdadafcacdf85,
    0x06e8b03fd6894b66,
    0x07cfe89cf1bd76ac,
    0x08ac25584881552a,
    0x097822507db6a8fd,
    0x0c27b35936d56e28,
    0x0c53165633977bca,
    0x0c8e9eddbbb259b4,
    0x0e204273b18918b0,
    0x0f1d16d6d4b89689,
    0x0fe6ba8608faa6a9,
    0x105f48347c60a1be,
    0x13627383c5456c5e,
    0x13f93bb1e72a2033,
    0x148048cb468bc208,
    0x1514c0b3a63c1444,
    0x175090684f5fe997,
    0x17e4116d591ef1fb,
    0x18cde996371c6060,
    0x19aa2cf604c30d3f,
    0x1d2b1ad9101b1bfd,
    0x1e5035e7b5183923,
    0x1fe5a79c4e71d028,
    0x20ec29bc6879dfcd,
    0x218ce77c2b3328fb,
    0x221ce77c2b3328fc,
    0x233f346f9ed36b89,
    0x243441ed79830182,
    0x245441ed79830182,
    0x247441ed79830182,
    0x2541e4ee41180c0a,
    0x277aacfcb88c92d6,
    0x279aacfcb88c92d6,
    0x27cbb4c6bd8601bd,
    0x28c04a616046e074,
    0x2a4eeff57768f88c,
    0x2c2379f099a86227,
    0x2d04f14348a4c5db,
    0x2d54f14348a4c5dc,
    0x2d6a8c931c19b77a,
    0x2fa387cf9cb4ad4e,
    0x308ddc7e975c5046,
    0x3149190e30e46c1d,
    0x318d2ec75df6ba2a,
    0x32548050091c3c24,
    0x33beef5e1f90ac34,
    0x33feef5e1f90ac35,
    0x342eef5e1f90ac35,
    0x345eef5e1f90ac35,
    0x35108621c4199208,
    0x366b870de5d93270,
    0x375b20c2f4f8d4a0,
    0x3864faba79ea92ec,
    0x3aa78cfcab31064c,
    0x4919d9577de925d5,
    0x49ccadd6dd730c96,
    0x4b9a32ac316fb3ab,
    0x4bba32ac316fb3ab,
    0x4cff20b1a0d7f626,
    0x4e3e2785c3a2a20b,
    0x4ea9a2c2a34ac2f9,
    0x4ec9a2c2a34ac2f9,
    0x4f28750ea732fdae,
    0x513843e10734fa57,
    0x51e71760b3c0bc13,
    0x55693ba3249a8511,
    0x57763ae2caed4528,
    0x57f561def4a9ee32,
    0x584561def4a9ee31,
    0x5b45ed1f039cebfe,
    0x5bfaf5b5378aa2e5,
    0x5c6cf45d333da323,
    0x5e64ec8fd70420c7,
    0x6009813653f62db7,
    0x64112a13daa46fe4,
    0x672dcfee6690ffc6,
    0x677a77581053543b,
    0x699873e3758bc6b3,
    0x6b3ef9beaa7aa584,
    0x6b7b86d8c3df7cd1,
    0x6bf6c9e14b7c22c3,
    0x6c16c9e14b7c22c3,
    0x6d075d226331d03a,
    0x6d5a3bdac4f00f33,
    0x6e4a2fbffdb7580c,
    0x6e927edd0dbb8c08,
    0x6ee1c382c3819a0a,
    0x70f60cf8f38b0465,
    0x7114390c68b888ce,
    0x714fb4840532a9e5,
    0x727fca36c06cf106,
    0x72eba10d818fdafd,
    0x737a37935f3b71c9,
    0x73972852443155ae,
    0x754fe46e378bf132,
    0x755fe46e378bf132,
    0x756fe46e378bf132,
    0x76603d7cb98edc58,
    0x76703d7cb98edc58,
    0x782f7c6a9ad432a1,
    0x78547e17e7814ce7,
    0x7964066d88c7cab8,
    0x7ace779fddf21621,
    0x7ade779fddf21621,
    0x7bc3b063946e10ae,
    0x7c0c283ffc61c87d,
    0x7c31926c7a7122ba,
    0x7d0a85c6f7fba05d,
    0x7d52a5daf9226f04,
    0x7d9220e1772428d7,
    0x7db220e1772428d7,
    0x7dfe5aceedf1c1f1,
    0x7e122815078cb97b,
    0x7e8a9b45a91f1700,
    0x7eb6202598194bee,
    0x7ec6202598194bee,
    0x7ef3c8eeb77b8d05,
    0x7f03c8eeb77b8d05,
    0x7f23c8eeb77b8d05,
    0x7f5594223f5654bf,
    0x7f9914e03c9260ee,
    0x7fc82baa4ae611dc,
    0x7fefffffffffffff,
    0x001d243f646eaf51,
    0x00ab7aa3d73f6658,
    0x00cb7aa3d73f6658,
    0x010b7aa3d73f6658,
    0x012b7aa3d73f6658,
    0x0180a0f3c55062c6,
    0x0190a0f3c55062c6,
    0x03719f08ccdccfe5,
    0x03dc25ba6a45de02,
    0x05798e3445512a6f,
    0x05898e3445512a6f,
    0x06bfdadafcacdf85,
    0x06cfdadafcacdf85,
    0x06f8b03fd6894b66,
    0x07c1707c02068785,
    0x08567a3c8dc4bc9c,
    0x089c25584881552a,
    0x08dfa7ebe304ee3d,
    0x096822507db6a8fd,
    0x09e41934d77659be,
    0x0c27b35936d56e27,
    0x0c43165633977bc9,
    0x0c53165633977bc9,
    0x0c63165633977bc9,
    0x0c7e9eddbbb259b4,
    0x0c9e9eddbbb259b4,
    0x0e104273b18918b1,
    0x0e204273b18918b1,
    0x0e304273b18918b1,
    0x0fd6ba8608faa6a8,
    0x0fe6ba8608faa6a8,
    0x1006b100e18e5c17,
    0x104f48347c60a1be,
    0x10a4139a6b17b224,
    0x12cb91d317c8ebe9,
    0x138fb24e492936f6,
    0x13afb24e492936f6,
    0x14093bb1e72a2033,
    0x1476cc4fc92a0fa6,
    0x149048cb468bc209,
    0x1504c0b3a63c1444,
    0x161ba6008389068a,
    0x168cfab1a09b49c4,
    0x175090684f5fe998,
    0x176090684f5fe998,
    0x17f4116d591ef1fb,
    0x18a710b7a2ef18b7,
    0x18d99fccca44882a,
    0x199a2cf604c30d3f,
    0x1b5ebddc6593c857,
    0x1d1b1ad9101b1bfd,
    0x1d3b1ad9101b1bfd,
    0x1e4035e7b5183923,
    0x1e6035e7b5183923,
    0x1fd5a79c4e71d028,
    0x20cc29bc6879dfcd,
    0x20e8823a57adbef8,
    0x2104dab846e19e25,
    0x2124dab846e19e25,
    0x220ce77c2b3328fb,
    0x221ce77c2b3328fb,
    0x222ce77c2b3328fb,
    0x229197b290631476,
    0x240a28877a09a4e0,
    0x243441ed79830181,
    0x244441ed79830181,
    0x245441ed79830181,
    0x246441ed79830181,
    0x247441ed79830181,
    0x248b23b50fc204db,
    0x24ab23b50fc204db,
    0x2633dc6227de9148,
    0x2653dc6227de9148,
    0x277aacfcb88c92d7,
    0x278aacfcb88c92d7,
    0x279aacfcb88c92d7,
    0x27bbb4c6bd8601bd,
    0x289d52af46e5fa69,
    0x28b04a616046e074,
    0x28d04a616046e074,
    0x2a3eeff57768f88c,
    0x2b8e3a0aeed7be19,
    0x2beec922478c0421,
    0x2cc7c3fba45c1271,
    0x2cf4f14348a4c5db,
    0x2d44f14348a4c5db,
    0x2d54f14348a4c5db,
    0x2d5a8c931c19b77a,
    0x2d64f14348a4c5dc,
    0x2efc1249e96b6d8d,
    0x2f0f6b23cfe98807,
    0x2fe91b9de4d5cf31,
    0x308ddc7e975c5045,
    0x309ddc7e975c5045,
    0x30bddc7e975c5045,
    0x3150ed9bd6bfd003,
    0x317d2ec75df6ba2a,
    0x321aedaa0fc32ac8,
    0x32448050091c3c24,
    0x328f5a18504dfaac,
    0x3336dca59d035820,
    0x33ceef5e1f90ac34,
    0x33eeef5e1f90ac35,
    0x340eef5e1f90ac35,
    0x34228f9edfbd3420,
    0x34328f9edfbd3420,
    0x344eef5e1f90ac35,
    0x346eef5e1f90ac35,
    0x35008621c4199208,
    0x35e0ac2e7f90b8a3,
    0x361dde4a4ab13e09,
    0x367b870de5d93270,
    0x375b20c2f4f8d49f,
    0x37f25d342b1e33e5,
    0x3854faba79ea92ed,
    0x3864faba79ea92ed,
    0x3a978cfcab31064d,
    0x3aa78cfcab31064d,
    0x490cd230a7ff47c3,
    0x4929d9577de925d5,
    0x4939d9577de925d5,
    0x49dcadd6dd730c96,
    0x4a7bb6979ae39c49,
    0x4b9a32ac316fb3ac,
    0x4baa32ac316fb3ac,
    0x4bba32ac316fb3ac,
    0x4cef20b1a0d7f626,
    0x4e2e2785c3a2a20a,
    0x4e3e2785c3a2a20a,
    0x4e6454b1aef62c8d,
    0x4e90fde34c996086,
    0x4ea9a2c2a34ac2fa,
    0x4eb9a2c2a34ac2fa,
    0x4ec9a2c2a34ac2fa,
    0x4ed9a2c2a34ac2fa,
    0x4f38750ea732fdae,
    0x504ca9bade45b94a,
    0x514843e10734fa57,
    0x51b3274280201a89,
    0x521f6a5025e71a61,
    0x52c6a47d4e7ec633,
    0x55793ba3249a8511,
    0x575fe0403124a00e,
    0x57863ae2caed4528,
    0x57e561def4a9ee32,
    0x580561def4a9ee31,
    0x582561def4a9ee31,
    0x585561def4a9ee31,
    0x59d0dd8f2788d699,
    0x5b55ed1f039cebfe,
    0x5beaf5b5378aa2e5,
    0x5c0af5b5378aa2e5,
    0x5c4ef3052ef0a361,
    0x5e1780695036a679,
    0x5e54ec8fd70420c7,
    0x5e6b5e2f86026f05,
    0x5faaeac2d1ea2695,
    0x611260322d04d50b,
    0x625be064a3fb2725,
    0x64212a13daa46fe4,
    0x671dcfee6690ffc6,
    0x673dcfee6690ffc6,
    0x675dcfee6690ffc6,
    0x678a77581053543b,
    0x682d3683fa3d1ee0,
    0x699cb490951e8515,
    0x6b3ef9beaa7aa583,
    0x6b4ef9beaa7aa583,
    0x6b7896beb0c66eb9,
    0x6bdf20938e7414bb,
    0x6bef20938e7414bb,
    0x6bf6c9e14b7c22c4,
    0x6c06c9e14b7c22c4,
    0x6c16c9e14b7c22c4,
    0x6cf75d226331d03a,
    0x6d175d226331d03a,
    0x6d4b9445072f4374,
};
const Slab = struct {
    str: []const u8,
    exp: i32,
};
pub const enum3_data: []const Slab = &[_]Slab{
    .{ .str = "40648030339495312", .exp = 69 },
    .{ .str = "4498645355592131", .exp = -134 },
    .{ .str = "678321594594593", .exp = 244 },
    .{ .str = "36539702510912277", .exp = -230 },
    .{ .str = "56819570380646536", .exp = -70 },
    .{ .str = "42452693975546964", .exp = 175 },
    .{ .str = "34248868699178663", .exp = 291 },
    .{ .str = "34037810581283983", .exp = -267 },
    .{ .str = "67135881167178176", .exp = -188 },
    .{ .str = "74973710847373845", .exp = -108 },
    .{ .str = "60272377639347644", .exp = -45 },
    .{ .str = "1316415380484425", .exp = 116 },
    .{ .str = "64433314612521525", .exp = 218 },
    .{ .str = "31961502891542243", .exp = 263 },
    .{ .str = "4407140524515149", .exp = 303 },
    .{ .str = "69928982131052126", .exp = -291 },
    .{ .str = "5331838923808276", .exp = -248 },
    .{ .str = "24766435002945523", .exp = -208 },
    .{ .str = "21509066976048781", .exp = -149 },
    .{ .str = "2347200170470694", .exp = -123 },
    .{ .str = "51404180294474556", .exp = -89 },
    .{ .str = "12320586499023201", .exp = -56 },
    .{ .str = "38099461575161174", .exp = 45 },
    .{ .str = "3318949537676913", .exp = 79 },
    .{ .str = "48988560059074597", .exp = 136 },
    .{ .str = "7955843973866726", .exp = 209 },
    .{ .str = "2630089515909384", .exp = 227 },
    .{ .str = "11971601492124911", .exp = 258 },
    .{ .str = "35394816534699092", .exp = 284 },
    .{ .str = "47497368114750945", .exp = 299 },
    .{ .str = "54271187548763685", .exp = 305 },
    .{ .str = "2504414972009504", .exp = -302 },
    .{ .str = "69316187906522606", .exp = -275 },
    .{ .str = "53263359599109627", .exp = -252 },
    .{ .str = "24384437085962037", .exp = -239 },
    .{ .str = "3677854139813342", .exp = -213 },
    .{ .str = "44318030915155535", .exp = -195 },
    .{ .str = "28150140033551147", .exp = -162 },
    .{ .str = "1157373742186464", .exp = -143 },
    .{ .str = "2229658838863212", .exp = -132 },
    .{ .str = "67817280930489786", .exp = -117 },
    .{ .str = "56966478488538934", .exp = -92 },
    .{ .str = "49514357246452655", .exp = -74 },
    .{ .str = "74426102121433776", .exp = -64 },
    .{ .str = "78851753593748485", .exp = -55 },
    .{ .str = "19024128529074359", .exp = -25 },
    .{ .str = "32118580932839778", .exp = 57 },
    .{ .str = "17693166778887419", .exp = 72 },
    .{ .str = "78117757194253536", .exp = 88 },
    .{ .str = "56627018760181905", .exp = 122 },
    .{ .str = "35243988108650928", .exp = 153 },
    .{ .str = "38624526316654214", .exp = 194 },
    .{ .str = "2397422026462446", .exp = 213 },
    .{ .str = "37862966954556723", .exp = 224 },
    .{ .str = "56089100059334965", .exp = 237 },
    .{ .str = "3666156212014994", .exp = 249 },
    .{ .str = "47886405968499643", .exp = 258 },
    .{ .str = "48228872759189434", .exp = 272 },
    .{ .str = "29980574575739863", .exp = 289 },
    .{ .str = "37049827284413546", .exp = 297 },
    .{ .str = "37997894491800756", .exp = 300 },
    .{ .str = "37263572163337027", .exp = 304 },
    .{ .str = "16973149506391291", .exp = 308 },
    .{ .str = "391314839376485", .exp = -304 },
    .{ .str = "38797447671091856", .exp = -300 },
    .{ .str = "54994366114768736", .exp = -281 },
    .{ .str = "23593494977819109", .exp = -270 },
    .{ .str = "61359116592542813", .exp = -265 },
    .{ .str = "1332959730952069", .exp = -248 },
    .{ .str = "6096109271490509", .exp = -240 },
    .{ .str = "22874741188249992", .exp = -231 },
    .{ .str = "33104948806015703", .exp = -227 },
    .{ .str = "21670630627577332", .exp = -209 },
    .{ .str = "70547825868713855", .exp = -201 },
    .{ .str = "54981742371928845", .exp = -192 },
    .{ .str = "27843818440071113", .exp = -171 },
    .{ .str = "4504022405368184", .exp = -161 },
    .{ .str = "2548351460621656", .exp = -148 },
    .{ .str = "4629494968745856", .exp = -143 },
    .{ .str = "557414709715803", .exp = -133 },
    .{ .str = "23897004381644022", .exp = -131 },
    .{ .str = "33057350728075958", .exp = -117 },
    .{ .str = "47628822744182433", .exp = -112 },
    .{ .str = "22520091703825729", .exp = -96 },
    .{ .str = "1285104507361864", .exp = -89 },
    .{ .str = "46239793787746783", .exp = -81 },
    .{ .str = "330095714976351", .exp = -73 },
    .{ .str = "4994144928421182", .exp = -66 },
    .{ .str = "77003665618895", .exp = -58 },
    .{ .str = "49282345996092803", .exp = -56 },
    .{ .str = "66534156679273626", .exp = -48 },
    .{ .str = "24661175471861008", .exp = -36 },
    .{ .str = "45035996273704964", .exp = 39 },
    .{ .str = "32402369146794532", .exp = 51 },
    .{ .str = "42859354584576066", .exp = 61 },
    .{ .str = "1465909318208761", .exp = 71 },
    .{ .str = "70772667115549675", .exp = 72 },
    .{ .str = "18604316837693468", .exp = 86 },
    .{ .str = "38329392744333992", .exp = 113 },
    .{ .str = "21062646087750798", .exp = 117 },
    .{ .str = "972708181182949", .exp = 132 },
    .{ .str = "36683053719290777", .exp = 146 },
    .{ .str = "32106017483029628", .exp = 166 },
    .{ .str = "41508952543121158", .exp = 190 },
    .{ .str = "45072812455233127", .exp = 205 },
    .{ .str = "59935550661561155", .exp = 212 },
    .{ .str = "40270821632825953", .exp = 217 },
    .{ .str = "60846862848160256", .exp = 219 },
    .{ .str = "42788225889846894", .exp = 225 },
    .{ .str = "28044550029667482", .exp = 237 },
    .{ .str = "46475406389115295", .exp = 240 },
    .{ .str = "7546114860200514", .exp = 246 },
    .{ .str = "7332312424029988", .exp = 249 },
    .{ .str = "23943202984249821", .exp = 258 },
    .{ .str = "15980751445771122", .exp = 263 },
    .{ .str = "21652206566352648", .exp = 272 },
    .{ .str = "65171333649148234", .exp = 278 },
    .{ .str = "70789633069398184", .exp = 284 },
    .{ .str = "68600253110025576", .exp = 290 },
    .{ .str = "4234784709771466", .exp = 295 },
    .{ .str = "14819930913765419", .exp = 298 },
    .{ .str = "9499473622950189", .exp = 299 },
    .{ .str = "71272819274635585", .exp = 302 },
    .{ .str = "16959746108988652", .exp = 304 },
    .{ .str = "13567796887190921", .exp = 305 },
    .{ .str = "4735325513114182", .exp = 306 },
    .{ .str = "67892598025565165", .exp = 308 },
    .{ .str = "81052743999542975", .exp = -307 },
    .{ .str = "4971131903427841", .exp = -303 },
    .{ .str = "19398723835545928", .exp = -300 },
    .{ .str = "29232758945460627", .exp = -298 },
    .{ .str = "27497183057384368", .exp = -281 },
    .{ .str = "17970091719480621", .exp = -275 },
    .{ .str = "22283747288943228", .exp = -274 },
    .{ .str = "47186989955638217", .exp = -270 },
    .{ .str = "6819439187504402", .exp = -266 },
    .{ .str = "47902021250710456", .exp = -262 },
    .{ .str = "41378294570975613", .exp = -249 },
    .{ .str = "2665919461904138", .exp = -248 },
    .{ .str = "3421423777071132", .exp = -247 },
    .{ .str = "12192218542981019", .exp = -239 },
    .{ .str = "7147520638007367", .exp = -235 },
    .{ .str = "45749482376499984", .exp = -231 },
    .{ .str = "80596937390013985", .exp = -229 },
    .{ .str = "26761990828289327", .exp = -214 },
    .{ .str = "18738512510673039", .exp = -211 },
    .{ .str = "619160875073638", .exp = -209 },
    .{ .str = "403997300048931", .exp = -206 },
    .{ .str = "22159015457577768", .exp = -195 },
    .{ .str = "13745435592982211", .exp = -192 },
    .{ .str = "33567940583589088", .exp = -188 },
    .{ .str = "4812711195250522", .exp = -184 },
    .{ .str = "3591036630219558", .exp = -167 },
    .{ .str = "1126005601342046", .exp = -161 },
    .{ .str = "5047135806497922", .exp = -154 },
    .{ .str = "43018133952097563", .exp = -149 },
    .{ .str = "45209911804158747", .exp = -146 },
    .{ .str = "2314747484372928", .exp = -143 },
    .{ .str = "65509428048152994", .exp = -138 },
    .{ .str = "2787073548579015", .exp = -133 },
    .{ .str = "1114829419431606", .exp = -132 },
    .{ .str = "4459317677726424", .exp = -132 },
    .{ .str = "32269008655522087", .exp = -128 },
    .{ .str = "16528675364037979", .exp = -117 },
    .{ .str = "66114701456151916", .exp = -117 },
    .{ .str = "54934856534126976", .exp = -116 },
    .{ .str = "21168365664081082", .exp = -111 },
    .{ .str = "67445733463759384", .exp = -104 },
    .{ .str = "45590931008842566", .exp = -95 },
    .{ .str = "8031903171011649", .exp = -91 },
    .{ .str = "2570209014723728", .exp = -89 },
    .{ .str = "6516605505584466", .exp = -89 },
    .{ .str = "32943123175907307", .exp = -78 },
    .{ .str = "82523928744087755", .exp = -74 },
    .{ .str = "28409785190323268", .exp = -70 },
    .{ .str = "52853886779813977", .exp = -69 },
    .{ .str = "30417302377115577", .exp = -65 },
    .{ .str = "1925091640472375", .exp = -58 },
    .{ .str = "30801466247558002", .exp = -57 },
    .{ .str = "24641172998046401", .exp = -56 },
    .{ .str = "19712938398437121", .exp = -55 },
    .{ .str = "43129529027318865", .exp = -52 },
    .{ .str = "15068094409836911", .exp = -45 },
    .{ .str = "48658418478920193", .exp = -41 },
    .{ .str = "49322350943722016", .exp = -36 },
    .{ .str = "38048257058148717", .exp = -25 },
    .{ .str = "14411294198511291", .exp = 45 },
    .{ .str = "32745697577386472", .exp = 48 },
    .{ .str = "16059290466419889", .exp = 57 },
    .{ .str = "64237161865679556", .exp = 57 },
    .{ .str = "8003248329710242", .exp = 63 },
    .{ .str = "81296060678990625", .exp = 69 },
    .{ .str = "8846583389443709", .exp = 71 },
    .{ .str = "35386333557774838", .exp = 72 },
    .{ .str = "21606114462319112", .exp = 74 },
    .{ .str = "18413733104063271", .exp = 84 },
    .{ .str = "35887030159858487", .exp = 87 },
    .{ .str = "2825769263311679", .exp = 104 },
    .{ .str = "2138446062528161", .exp = 114 },
    .{ .str = "52656615219377", .exp = 116 },
    .{ .str = "16850116870200639", .exp = 118 },
    .{ .str = "48635409059147446", .exp = 132 },
    .{ .str = "12247140014768649", .exp = 136 },
    .{ .str = "16836228873919609", .exp = 138 },
    .{ .str = "5225574770881846", .exp = 147 },
    .{ .str = "42745323906998127", .exp = 155 },
    .{ .str = "10613173493886741", .exp = 175 },
    .{ .str = "10377238135780289", .exp = 190 },
    .{ .str = "29480080280199528", .exp = 191 },
    .{ .str = "4679330956996797", .exp = 201 },
    .{ .str = "3977921986933363", .exp = 209 },
    .{ .str = "56560320317673966", .exp = 210 },
    .{ .str = "1198711013231223", .exp = 213 },
    .{ .str = "4794844052924892", .exp = 213 },
    .{ .str = "16108328653130381", .exp = 218 },
    .{ .str = "57878622568856074", .exp = 219 },
    .{ .str = "18931483477278361", .exp = 224 },
    .{ .str = "4278822588984689", .exp = 225 },
    .{ .str = "1315044757954692", .exp = 227 },
    .{ .str = "14022275014833741", .exp = 237 },
    .{ .str = "5143975308105889", .exp = 237 },
    .{ .str = "64517311884236306", .exp = 238 },
    .{ .str = "3391607972972965", .exp = 244 },
    .{ .str = "3773057430100257", .exp = 246 },
    .{ .str = "1833078106007497", .exp = 249 },
    .{ .str = "64766168833734675", .exp = 249 },
    .{ .str = "1197160149212491", .exp = 258 },
    .{ .str = "2394320298424982", .exp = 258 },
    .{ .str = "4788640596849964", .exp = 258 },
    .{ .str = "1598075144577112", .exp = 263 },
    .{ .str = "3196150289154224", .exp = 263 },
    .{ .str = "83169412421960475", .exp = 271 },
    .{ .str = "43304413132705296", .exp = 272 },
    .{ .str = "5546524276967009", .exp = 277 },
    .{ .str = "3539481653469909", .exp = 284 },
    .{ .str = "7078963306939818", .exp = 284 },
    .{ .str = "14990287287869931", .exp = 289 },
    .{ .str = "34300126555012788", .exp = 290 },
    .{ .str = "17124434349589332", .exp = 291 },
    .{ .str = "2117392354885733", .exp = 295 },
    .{ .str = "47639264836707725", .exp = 296 },
    .{ .str = "7409965456882709", .exp = 297 },
    .{ .str = "29639861827530837", .exp = 298 },
    .{ .str = "79407577493590275", .exp = 299 },
    .{ .str = "18998947245900378", .exp = 300 },
    .{ .str = "35636409637317792", .exp = 302 },
    .{ .str = "23707742595255608", .exp = 303 },
    .{ .str = "47415485190511216", .exp = 303 },
    .{ .str = "33919492217977303", .exp = 304 },
    .{ .str = "6783898443595461", .exp = 304 },
    .{ .str = "27135593774381842", .exp = 305 },
    .{ .str = "2367662756557091", .exp = 306 },
    .{ .str = "44032152438472327", .exp = 307 },
    .{ .str = "33946299012782582", .exp = 308 },
    .{ .str = "17976931348623157", .exp = 309 },
    .{ .str = "40526371999771488", .exp = -307 },
    .{ .str = "1956574196882425", .exp = -304 },
    .{ .str = "78262967875297", .exp = -304 },
    .{ .str = "1252207486004752", .exp = -302 },
    .{ .str = "5008829944019008", .exp = -302 },
    .{ .str = "1939872383554593", .exp = -300 },
    .{ .str = "3879744767109186", .exp = -300 },
    .{ .str = "44144884605471774", .exp = -291 },
    .{ .str = "45129663866844427", .exp = -289 },
    .{ .str = "2749718305738437", .exp = -281 },
    .{ .str = "5499436611476874", .exp = -281 },
    .{ .str = "35940183438961242", .exp = -275 },
    .{ .str = "71880366877922484", .exp = -275 },
    .{ .str = "44567494577886457", .exp = -274 },
    .{ .str = "25789638850173173", .exp = -270 },
    .{ .str = "17018905290641991", .exp = -267 },
    .{ .str = "3409719593752201", .exp = -266 },
    .{ .str = "6135911659254281", .exp = -265 },
    .{ .str = "23951010625355228", .exp = -262 },
    .{ .str = "51061856989121905", .exp = -260 },
    .{ .str = "4137829457097561", .exp = -249 },
    .{ .str = "13329597309520689", .exp = -248 },
    .{ .str = "26659194619041378", .exp = -248 },
    .{ .str = "53318389238082755", .exp = -248 },
    .{ .str = "1710711888535566", .exp = -247 },
    .{ .str = "6842847554142264", .exp = -247 },
    .{ .str = "609610927149051", .exp = -240 },
    .{ .str = "1219221854298102", .exp = -239 },
    .{ .str = "2438443708596204", .exp = -239 },
    .{ .str = "2287474118824999", .exp = -231 },
    .{ .str = "4574948237649998", .exp = -231 },
    .{ .str = "18269851255456139", .exp = -230 },
    .{ .str = "40298468695006992", .exp = -229 },
    .{ .str = "16552474403007851", .exp = -227 },
    .{ .str = "39050270537318193", .exp = -217 },
    .{ .str = "1838927069906671", .exp = -213 },
    .{ .str = "7355708279626684", .exp = -213 },
    .{ .str = "37477025021346077", .exp = -211 },
    .{ .str = "43341261255154663", .exp = -209 },
    .{ .str = "12383217501472761", .exp = -208 },
    .{ .str = "2019986500244655", .exp = -206 },
    .{ .str = "35273912934356928", .exp = -201 },
    .{ .str = "47323883490786093", .exp = -199 },
    .{ .str = "2215901545757777", .exp = -195 },
    .{ .str = "4431803091515554", .exp = -195 },
    .{ .str = "27490871185964422", .exp = -192 },
    .{ .str = "64710073234908765", .exp = -189 },
    .{ .str = "57511323531737074", .exp = -188 },
    .{ .str = "2406355597625261", .exp = -184 },
    .{ .str = "75862936714499446", .exp = -176 },
    .{ .str = "1795518315109779", .exp = -167 },
    .{ .str = "7182073260439116", .exp = -167 },
    .{ .str = "563002800671023", .exp = -162 },
    .{ .str = "2252011202684092", .exp = -161 },
    .{ .str = "2523567903248961", .exp = -154 },
    .{ .str = "10754533488024391", .exp = -149 },
    .{ .str = "37436263604934127", .exp = -149 },
    .{ .str = "1274175730310828", .exp = -148 },
    .{ .str = "5096702921243312", .exp = -148 },
    .{ .str = "11573737421864639", .exp = -143 },
    .{ .str = "23147474843729279", .exp = -143 },
    .{ .str = "46294949687458557", .exp = -143 },
    .{ .str = "36067106647774144", .exp = -141 },
    .{ .str = "44986453555921307", .exp = -134 },
    .{ .str = "27870735485790148", .exp = -133 },
    .{ .str = "55741470971580295", .exp = -133 },
    .{ .str = "11148294194316059", .exp = -132 },
    .{ .str = "22296588388632118", .exp = -132 },
    .{ .str = "44593176777264236", .exp = -132 },
    .{ .str = "11948502190822011", .exp = -131 },
    .{ .str = "47794008763288043", .exp = -131 },
    .{ .str = "1173600085235347", .exp = -123 },
    .{ .str = "4694400340941388", .exp = -123 },
    .{ .str = "1652867536403798", .exp = -117 },
    .{ .str = "3305735072807596", .exp = -117 },
    .{ .str = "6611470145615192", .exp = -117 },
    .{ .str = "27467428267063488", .exp = -116 },
    .{ .str = "4762882274418243", .exp = -112 },
    .{ .str = "10584182832040541", .exp = -111 },
    .{ .str = "42336731328162165", .exp = -111 },
    .{ .str = "33722866731879692", .exp = -104 },
    .{ .str = "69097540994131414", .exp = -98 },
    .{ .str = "45040183407651457", .exp = -96 },
    .{ .str = "5696647848853893", .exp = -92 },
    .{ .str = "40159515855058247", .exp = -91 },
    .{ .str = "12851045073618639", .exp = -89 },
    .{ .str = "25702090147237278", .exp = -89 },
    .{ .str = "3258302752792233", .exp = -89 },
    .{ .str = "5140418029447456", .exp = -89 },
    .{ .str = "23119896893873391", .exp = -81 },
    .{ .str = "51753157237874753", .exp = -81 },
    .{ .str = "67761208324172855", .exp = -77 },
    .{ .str = "8252392874408775", .exp = -74 },
    .{ .str = "1650478574881755", .exp = -73 },
    .{ .str = "660191429952702", .exp = -73 },
    .{ .str = "3832399419240467", .exp = -70 },
    .{ .str = "26426943389906988", .exp = -69 },
    .{ .str = "2497072464210591", .exp = -66 },
    .{ .str = "15208651188557789", .exp = -65 },
    .{ .str = "37213051060716888", .exp = -64 },
    .{ .str = "55574205388093594", .exp = -61 },
    .{ .str = "385018328094475", .exp = -58 },
    .{ .str = "15400733123779001", .exp = -57 },
    .{ .str = "61602932495116004", .exp = -57 },
    .{ .str = "14784703798827841", .exp = -56 },
    .{ .str = "29569407597655683", .exp = -56 },
    .{ .str = "9856469199218561", .exp = -56 },
    .{ .str = "39425876796874242", .exp = -55 },
    .{ .str = "21564764513659432", .exp = -52 },
    .{ .str = "35649516398744314", .exp = -48 },
    .{ .str = "51091836539008967", .exp = -47 },
    .{ .str = "30136188819673822", .exp = -45 },
    .{ .str = "4865841847892019", .exp = -41 },
    .{ .str = "33729482964455627", .exp = -38 },
    .{ .str = "2466117547186101", .exp = -36 },
    .{ .str = "4932235094372202", .exp = -36 },
    .{ .str = "1902412852907436", .exp = -25 },
    .{ .str = "3804825705814872", .exp = -25 },
    .{ .str = "80341375308088225", .exp = 44 },
    .{ .str = "28822588397022582", .exp = 45 },
    .{ .str = "57645176794045164", .exp = 45 },
    .{ .str = "65491395154772944", .exp = 48 },
    .{ .str = "64804738293589064", .exp = 51 },
    .{ .str = "1605929046641989", .exp = 57 },
    .{ .str = "3211858093283978", .exp = 57 },
    .{ .str = "6423716186567956", .exp = 57 },
    .{ .str = "4001624164855121", .exp = 63 },
    .{ .str = "4064803033949531", .exp = 69 },
    .{ .str = "8129606067899062", .exp = 69 },
    .{ .str = "4384946084578497", .exp = 70 },
    .{ .str = "2931818636417522", .exp = 71 },
    .{ .str = "884658338944371", .exp = 71 },
    .{ .str = "1769316677888742", .exp = 72 },
    .{ .str = "3538633355777484", .exp = 72 },
    .{ .str = "7077266711554968", .exp = 72 },
    .{ .str = "43212228924638223", .exp = 74 },
    .{ .str = "6637899075353826", .exp = 79 },
    .{ .str = "36827466208126543", .exp = 84 },
    .{ .str = "37208633675386937", .exp = 86 },
    .{ .str = "39058878597126768", .exp = 88 },
    .{ .str = "57654578150150385", .exp = 91 },
    .{ .str = "5651538526623358", .exp = 104 },
    .{ .str = "76658785488667984", .exp = 113 },
    .{ .str = "4276892125056322", .exp = 114 },
    .{ .str = "263283076096885", .exp = 116 },
    .{ .str = "10531323043875399", .exp = 117 },
    .{ .str = "42125292175501597", .exp = 117 },
    .{ .str = "33700233740401277", .exp = 118 },
    .{ .str = "44596066840334405", .exp = 125 },
    .{ .str = "9727081811829489", .exp = 132 },
    .{ .str = "61235700073843246", .exp = 135 },
    .{ .str = "24494280029537298", .exp = 136 },
    .{ .str = "4499029632233837", .exp = 137 },
    .{ .str = "18341526859645389", .exp = 146 },
    .{ .str = "2612787385440923", .exp = 147 },
    .{ .str = "6834859331393543", .exp = 147 },
    .{ .str = "70487976217301855", .exp = 153 },
    .{ .str = "40366692112133834", .exp = 160 },
    .{ .str = "64212034966059256", .exp = 166 },
    .{ .str = "21226346987773482", .exp = 175 },
    .{ .str = "51886190678901447", .exp = 189 },
    .{ .str = "20754476271560579", .exp = 190 },
    .{ .str = "83017905086242315", .exp = 190 },
    .{ .str = "58960160560399056", .exp = 191 },
    .{ .str = "66641177824100826", .exp = 194 },
    .{ .str = "5493127645170153", .exp = 201 },
    .{ .str = "39779219869333628", .exp = 209 },
    .{ .str = "79558439738667255", .exp = 209 },
    .{ .str = "50523702331566894", .exp = 210 },
    .{ .str = "40933393326155808", .exp = 212 },
    .{ .str = "81866786652311615", .exp = 212 },
    .{ .str = "11987110132312231", .exp = 213 },
    .{ .str = "23974220264624462", .exp = 213 },
    .{ .str = "47948440529248924", .exp = 213 },
    .{ .str = "8054164326565191", .exp = 217 },
    .{ .str = "32216657306260762", .exp = 218 },
    .{ .str = "30423431424080128", .exp = 219 },
};
pub const HP = struct {
    val: f64,
    off: f64,
};
pub const lookup_table: []const HP = &[_]HP{
    HP{ .val = 1.000000e+308, .off = -1.097906362944045488e+291 },
    HP{ .val = 1.000000e+307, .off = 1.396894023974354241e+290 },
    HP{ .val = 1.000000e+306, .off = -1.721606459673645508e+289 },
    HP{ .val = 1.000000e+305, .off = 6.074644749446353973e+288 },
    HP{ .val = 1.000000e+304, .off = 6.074644749446353567e+287 },
    HP{ .val = 1.000000e+303, .off = -1.617650767864564452e+284 },
    HP{ .val = 1.000000e+302, .off = -7.629703079084895055e+285 },
    HP{ .val = 1.000000e+301, .off = -5.250476025520442286e+284 },
    HP{ .val = 1.000000e+300, .off = -5.250476025520441956e+283 },
    HP{ .val = 1.000000e+299, .off = -5.250476025520441750e+282 },
    HP{ .val = 1.000000e+298, .off = 4.043379652465702264e+281 },
    HP{ .val = 1.000000e+297, .off = -1.765280146275637946e+280 },
    HP{ .val = 1.000000e+296, .off = 1.865132227937699609e+279 },
    HP{ .val = 1.000000e+295, .off = 1.865132227937699609e+278 },
    HP{ .val = 1.000000e+294, .off = -6.643646774124810287e+277 },
    HP{ .val = 1.000000e+293, .off = 7.537651562646039934e+276 },
    HP{ .val = 1.000000e+292, .off = -1.325659897835741608e+275 },
    HP{ .val = 1.000000e+291, .off = 4.213909764965371606e+274 },
    HP{ .val = 1.000000e+290, .off = -6.172783352786715670e+273 },
    HP{ .val = 1.000000e+289, .off = -6.172783352786715670e+272 },
    HP{ .val = 1.000000e+288, .off = -7.630473539575035471e+270 },
    HP{ .val = 1.000000e+287, .off = -7.525217352494018700e+270 },
    HP{ .val = 1.000000e+286, .off = -3.298861103408696612e+269 },
    HP{ .val = 1.000000e+285, .off = 1.984084207947955778e+268 },
    HP{ .val = 1.000000e+284, .off = -7.921438250845767591e+267 },
    HP{ .val = 1.000000e+283, .off = 4.460464822646386735e+266 },
    HP{ .val = 1.000000e+282, .off = -3.278224598286209647e+265 },
    HP{ .val = 1.000000e+281, .off = -3.278224598286209737e+264 },
    HP{ .val = 1.000000e+280, .off = -3.278224598286209961e+263 },
    HP{ .val = 1.000000e+279, .off = -5.797329227496039232e+262 },
    HP{ .val = 1.000000e+278, .off = 3.649313132040821498e+261 },
    HP{ .val = 1.000000e+277, .off = -2.867878510995372374e+259 },
    HP{ .val = 1.000000e+276, .off = -5.206914080024985409e+259 },
    HP{ .val = 1.000000e+275, .off = 4.018322599210230404e+258 },
    HP{ .val = 1.000000e+274, .off = 7.862171215558236495e+257 },
    HP{ .val = 1.000000e+273, .off = 5.459765830340732821e+256 },
    HP{ .val = 1.000000e+272, .off = -6.552261095746788047e+255 },
    HP{ .val = 1.000000e+271, .off = 4.709014147460262298e+254 },
    HP{ .val = 1.000000e+270, .off = -4.675381888545612729e+253 },
    HP{ .val = 1.000000e+269, .off = -4.675381888545612892e+252 },
    HP{ .val = 1.000000e+268, .off = 2.656177514583977380e+251 },
    HP{ .val = 1.000000e+267, .off = 2.656177514583977190e+250 },
    HP{ .val = 1.000000e+266, .off = -3.071603269111014892e+249 },
    HP{ .val = 1.000000e+265, .off = -6.651466258920385440e+248 },
    HP{ .val = 1.000000e+264, .off = -4.414051890289528972e+247 },
    HP{ .val = 1.000000e+263, .off = -1.617283929500958387e+246 },
    HP{ .val = 1.000000e+262, .off = -1.617283929500958241e+245 },
    HP{ .val = 1.000000e+261, .off = 7.122615947963323868e+244 },
    HP{ .val = 1.000000e+260, .off = -6.533477610574617382e+243 },
    HP{ .val = 1.000000e+259, .off = 7.122615947963323982e+242 },
    HP{ .val = 1.000000e+258, .off = -5.679971763165996225e+241 },
    HP{ .val = 1.000000e+257, .off = -3.012765990014054219e+240 },
    HP{ .val = 1.000000e+256, .off = -3.012765990014054219e+239 },
    HP{ .val = 1.000000e+255, .off = 1.154743030535854616e+238 },
    HP{ .val = 1.000000e+254, .off = 6.364129306223240767e+237 },
    HP{ .val = 1.000000e+253, .off = 6.364129306223241129e+236 },
    HP{ .val = 1.000000e+252, .off = -9.915202805299840595e+235 },
    HP{ .val = 1.000000e+251, .off = -4.827911520448877980e+234 },
    HP{ .val = 1.000000e+250, .off = 7.890316691678530146e+233 },
    HP{ .val = 1.000000e+249, .off = 7.890316691678529484e+232 },
    HP{ .val = 1.000000e+248, .off = -4.529828046727141859e+231 },
    HP{ .val = 1.000000e+247, .off = 4.785280507077111924e+230 },
    HP{ .val = 1.000000e+246, .off = -6.858605185178205305e+229 },
    HP{ .val = 1.000000e+245, .off = -4.432795665958347728e+228 },
    HP{ .val = 1.000000e+244, .off = -7.465057564983169531e+227 },
    HP{ .val = 1.000000e+243, .off = -7.465057564983169741e+226 },
    HP{ .val = 1.000000e+242, .off = -5.096102956370027445e+225 },
    HP{ .val = 1.000000e+241, .off = -5.096102956370026952e+224 },
    HP{ .val = 1.000000e+240, .off = -1.394611380411992474e+223 },
    HP{ .val = 1.000000e+239, .off = 9.188208545617793960e+221 },
    HP{ .val = 1.000000e+238, .off = -4.864759732872650359e+221 },
    HP{ .val = 1.000000e+237, .off = 5.979453868566904629e+220 },
    HP{ .val = 1.000000e+236, .off = -5.316601966265964857e+219 },
    HP{ .val = 1.000000e+235, .off = -5.316601966265964701e+218 },
    HP{ .val = 1.000000e+234, .off = -1.786584517880693123e+217 },
    HP{ .val = 1.000000e+233, .off = 2.625937292600896716e+216 },
    HP{ .val = 1.000000e+232, .off = -5.647541102052084079e+215 },
    HP{ .val = 1.000000e+231, .off = -5.647541102052083888e+214 },
    HP{ .val = 1.000000e+230, .off = -9.956644432600511943e+213 },
    HP{ .val = 1.000000e+229, .off = 8.161138937705571862e+211 },
    HP{ .val = 1.000000e+228, .off = 7.549087847752475275e+211 },
    HP{ .val = 1.000000e+227, .off = -9.283347037202319948e+210 },
    HP{ .val = 1.000000e+226, .off = 3.866992716668613820e+209 },
    HP{ .val = 1.000000e+225, .off = 7.154577655136347262e+208 },
    HP{ .val = 1.000000e+224, .off = 3.045096482051680688e+207 },
    HP{ .val = 1.000000e+223, .off = -4.660180717482069567e+206 },
    HP{ .val = 1.000000e+222, .off = -4.660180717482070101e+205 },
    HP{ .val = 1.000000e+221, .off = -4.660180717482069544e+204 },
    HP{ .val = 1.000000e+220, .off = 3.562757926310489022e+202 },
    HP{ .val = 1.000000e+219, .off = 3.491561111451748149e+202 },
    HP{ .val = 1.000000e+218, .off = -8.265758834125874135e+201 },
    HP{ .val = 1.000000e+217, .off = 3.981449442517482365e+200 },
    HP{ .val = 1.000000e+216, .off = -2.142154695804195936e+199 },
    HP{ .val = 1.000000e+215, .off = 9.339603063548950188e+198 },
    HP{ .val = 1.000000e+214, .off = 4.555537330485139746e+197 },
    HP{ .val = 1.000000e+213, .off = 1.565496247320257804e+196 },
    HP{ .val = 1.000000e+212, .off = 9.040598955232462036e+195 },
    HP{ .val = 1.000000e+211, .off = 4.368659762787334780e+194 },
    HP{ .val = 1.000000e+210, .off = 7.288621758065539072e+193 },
    HP{ .val = 1.000000e+209, .off = -7.311188218325485628e+192 },
    HP{ .val = 1.000000e+208, .off = 1.813693016918905189e+191 },
    HP{ .val = 1.000000e+207, .off = -3.889357755108838992e+190 },
    HP{ .val = 1.000000e+206, .off = -3.889357755108838992e+189 },
    HP{ .val = 1.000000e+205, .off = -1.661603547285501360e+188 },
    HP{ .val = 1.000000e+204, .off = 1.123089212493670643e+187 },
    HP{ .val = 1.000000e+203, .off = 1.123089212493670643e+186 },
    HP{ .val = 1.000000e+202, .off = 9.825254086803583029e+185 },
    HP{ .val = 1.000000e+201, .off = -3.771878529305654999e+184 },
    HP{ .val = 1.000000e+200, .off = 3.026687778748963675e+183 },
    HP{ .val = 1.000000e+199, .off = -9.720624048853446693e+182 },
    HP{ .val = 1.000000e+198, .off = -1.753554156601940139e+181 },
    HP{ .val = 1.000000e+197, .off = 4.885670753607648963e+180 },
    HP{ .val = 1.000000e+196, .off = 4.885670753607648963e+179 },
    HP{ .val = 1.000000e+195, .off = 2.292223523057028076e+178 },
    HP{ .val = 1.000000e+194, .off = 5.534032561245303825e+177 },
    HP{ .val = 1.000000e+193, .off = -6.622751331960730683e+176 },
    HP{ .val = 1.000000e+192, .off = -4.090088020876139692e+175 },
    HP{ .val = 1.000000e+191, .off = -7.255917159731877552e+174 },
    HP{ .val = 1.000000e+190, .off = -7.255917159731877992e+173 },
    HP{ .val = 1.000000e+189, .off = -2.309309130269787104e+172 },
    HP{ .val = 1.000000e+188, .off = -2.309309130269787019e+171 },
    HP{ .val = 1.000000e+187, .off = 9.284303438781988230e+170 },
    HP{ .val = 1.000000e+186, .off = 2.038295583124628364e+169 },
    HP{ .val = 1.000000e+185, .off = 2.038295583124628532e+168 },
    HP{ .val = 1.000000e+184, .off = -1.735666841696912925e+167 },
    HP{ .val = 1.000000e+183, .off = 5.340512704843477241e+166 },
    HP{ .val = 1.000000e+182, .off = -6.453119872723839321e+165 },
    HP{ .val = 1.000000e+181, .off = 8.288920849235306587e+164 },
    HP{ .val = 1.000000e+180, .off = -9.248546019891598293e+162 },
    HP{ .val = 1.000000e+179, .off = 1.954450226518486016e+162 },
    HP{ .val = 1.000000e+178, .off = -5.243811844750628197e+161 },
    HP{ .val = 1.000000e+177, .off = -7.448980502074320639e+159 },
    HP{ .val = 1.000000e+176, .off = -7.448980502074319858e+158 },
    HP{ .val = 1.000000e+175, .off = 6.284654753766312753e+158 },
    HP{ .val = 1.000000e+174, .off = -6.895756753684458388e+157 },
    HP{ .val = 1.000000e+173, .off = -1.403918625579970616e+156 },
    HP{ .val = 1.000000e+172, .off = -8.268716285710580522e+155 },
    HP{ .val = 1.000000e+171, .off = 4.602779327034313170e+154 },
    HP{ .val = 1.000000e+170, .off = -3.441905430931244940e+153 },
    HP{ .val = 1.000000e+169, .off = 6.613950516525702884e+152 },
    HP{ .val = 1.000000e+168, .off = 6.613950516525702652e+151 },
    HP{ .val = 1.000000e+167, .off = -3.860899428741951187e+150 },
    HP{ .val = 1.000000e+166, .off = 5.959272394946474605e+149 },
    HP{ .val = 1.000000e+165, .off = 1.005101065481665103e+149 },
    HP{ .val = 1.000000e+164, .off = -1.783349948587918355e+146 },
    HP{ .val = 1.000000e+163, .off = 6.215006036188360099e+146 },
    HP{ .val = 1.000000e+162, .off = 6.215006036188360099e+145 },
    HP{ .val = 1.000000e+161, .off = -3.774589324822814903e+144 },
    HP{ .val = 1.000000e+160, .off = -6.528407745068226929e+142 },
    HP{ .val = 1.000000e+159, .off = 7.151530601283157561e+142 },
    HP{ .val = 1.000000e+158, .off = 4.712664546348788765e+141 },
    HP{ .val = 1.000000e+157, .off = 1.664081977680827856e+140 },
    HP{ .val = 1.000000e+156, .off = 1.664081977680827750e+139 },
    HP{ .val = 1.000000e+155, .off = -7.176231540910168265e+137 },
    HP{ .val = 1.000000e+154, .off = -3.694754568805822650e+137 },
    HP{ .val = 1.000000e+153, .off = 2.665969958768462622e+134 },
    HP{ .val = 1.000000e+152, .off = -4.625108135904199522e+135 },
    HP{ .val = 1.000000e+151, .off = -1.717753238721771919e+134 },
    HP{ .val = 1.000000e+150, .off = 1.916440382756262433e+133 },
    HP{ .val = 1.000000e+149, .off = -4.897672657515052040e+132 },
    HP{ .val = 1.000000e+148, .off = -4.897672657515052198e+131 },
    HP{ .val = 1.000000e+147, .off = 2.200361759434233991e+130 },
    HP{ .val = 1.000000e+146, .off = 6.636633270027537273e+129 },
    HP{ .val = 1.000000e+145, .off = 1.091293881785907977e+128 },
    HP{ .val = 1.000000e+144, .off = -2.374543235865110597e+127 },
    HP{ .val = 1.000000e+143, .off = -2.374543235865110537e+126 },
    HP{ .val = 1.000000e+142, .off = -5.082228484029969099e+125 },
    HP{ .val = 1.000000e+141, .off = -1.697621923823895943e+124 },
    HP{ .val = 1.000000e+140, .off = -5.928380124081487212e+123 },
    HP{ .val = 1.000000e+139, .off = -3.284156248920492522e+122 },
    HP{ .val = 1.000000e+138, .off = -3.284156248920492706e+121 },
    HP{ .val = 1.000000e+137, .off = -3.284156248920492476e+120 },
    HP{ .val = 1.000000e+136, .off = -5.866406127007401066e+119 },
    HP{ .val = 1.000000e+135, .off = 3.817030915818506056e+118 },
    HP{ .val = 1.000000e+134, .off = 7.851796350329300951e+117 },
    HP{ .val = 1.000000e+133, .off = -2.235117235947686077e+116 },
    HP{ .val = 1.000000e+132, .off = 9.170432597638723691e+114 },
    HP{ .val = 1.000000e+131, .off = 8.797444499042767883e+114 },
    HP{ .val = 1.000000e+130, .off = -5.978307824605161274e+113 },
    HP{ .val = 1.000000e+129, .off = 1.782556435814758516e+111 },
    HP{ .val = 1.000000e+128, .off = -7.517448691651820362e+111 },
    HP{ .val = 1.000000e+127, .off = 4.507089332150205498e+110 },
    HP{ .val = 1.000000e+126, .off = 7.513223838100711695e+109 },
    HP{ .val = 1.000000e+125, .off = 7.513223838100712113e+108 },
    HP{ .val = 1.000000e+124, .off = 5.164681255326878494e+107 },
    HP{ .val = 1.000000e+123, .off = 2.229003026859587122e+106 },
    HP{ .val = 1.000000e+122, .off = -1.440594758724527399e+105 },
    HP{ .val = 1.000000e+121, .off = -3.734093374714598783e+104 },
    HP{ .val = 1.000000e+120, .off = 1.999653165260579757e+103 },
    HP{ .val = 1.000000e+119, .off = 5.583244752745066693e+102 },
    HP{ .val = 1.000000e+118, .off = 3.343500010567262234e+101 },
    HP{ .val = 1.000000e+117, .off = -5.055542772599503556e+100 },
    HP{ .val = 1.000000e+116, .off = -1.555941612946684331e+99 },
    HP{ .val = 1.000000e+115, .off = -1.555941612946684331e+98 },
    HP{ .val = 1.000000e+114, .off = -1.555941612946684293e+97 },
    HP{ .val = 1.000000e+113, .off = -1.555941612946684246e+96 },
    HP{ .val = 1.000000e+112, .off = 6.988006530736955847e+95 },
    HP{ .val = 1.000000e+111, .off = 4.318022735835818244e+94 },
    HP{ .val = 1.000000e+110, .off = -2.356936751417025578e+93 },
    HP{ .val = 1.000000e+109, .off = 1.814912928116001926e+92 },
    HP{ .val = 1.000000e+108, .off = -3.399899171300282744e+91 },
    HP{ .val = 1.000000e+107, .off = 3.118615952970072913e+90 },
    HP{ .val = 1.000000e+106, .off = -9.103599905036843605e+89 },
    HP{ .val = 1.000000e+105, .off = 6.174169917471802325e+88 },
    HP{ .val = 1.000000e+104, .off = -1.915675085734668657e+86 },
    HP{ .val = 1.000000e+103, .off = -1.915675085734668864e+85 },
    HP{ .val = 1.000000e+102, .off = 2.295048673475466221e+85 },
    HP{ .val = 1.000000e+101, .off = 2.295048673475466135e+84 },
    HP{ .val = 1.000000e+100, .off = -1.590289110975991792e+83 },
    HP{ .val = 1.000000e+99, .off = 3.266383119588331155e+82 },
    HP{ .val = 1.000000e+98, .off = 2.309629754856292029e+80 },
    HP{ .val = 1.000000e+97, .off = -7.357587384771124533e+80 },
    HP{ .val = 1.000000e+96, .off = -4.986165397190889509e+79 },
    HP{ .val = 1.000000e+95, .off = -2.021887912715594741e+78 },
    HP{ .val = 1.000000e+94, .off = -2.021887912715594638e+77 },
    HP{ .val = 1.000000e+93, .off = -4.337729697461918675e+76 },
    HP{ .val = 1.000000e+92, .off = -4.337729697461918997e+75 },
    HP{ .val = 1.000000e+91, .off = -7.956232486128049702e+74 },
    HP{ .val = 1.000000e+90, .off = 3.351588728453609882e+73 },
    HP{ .val = 1.000000e+89, .off = 5.246334248081951113e+71 },
    HP{ .val = 1.000000e+88, .off = 4.058327554364963672e+71 },
    HP{ .val = 1.000000e+87, .off = 4.058327554364963918e+70 },
    HP{ .val = 1.000000e+86, .off = -1.463069523067487266e+69 },
    HP{ .val = 1.000000e+85, .off = -1.463069523067487314e+68 },
    HP{ .val = 1.000000e+84, .off = -5.776660989811589441e+67 },
    HP{ .val = 1.000000e+83, .off = -3.080666323096525761e+66 },
    HP{ .val = 1.000000e+82, .off = 3.659320343691134468e+65 },
    HP{ .val = 1.000000e+81, .off = 7.871812010433421235e+64 },
    HP{ .val = 1.000000e+80, .off = -2.660986470836727449e+61 },
    HP{ .val = 1.000000e+79, .off = 3.264399249934044627e+62 },
    HP{ .val = 1.000000e+78, .off = -8.493621433689703070e+60 },
    HP{ .val = 1.000000e+77, .off = 1.721738727445414063e+60 },
    HP{ .val = 1.000000e+76, .off = -4.706013449590547218e+59 },
    HP{ .val = 1.000000e+75, .off = 7.346021882351880518e+58 },
    HP{ .val = 1.000000e+74, .off = 4.835181188197207515e+57 },
    HP{ .val = 1.000000e+73, .off = 1.696630320503867482e+56 },
    HP{ .val = 1.000000e+72, .off = 5.619818905120542959e+55 },
    HP{ .val = 1.000000e+71, .off = -4.188152556421145598e+54 },
    HP{ .val = 1.000000e+70, .off = -7.253143638152923145e+53 },
    HP{ .val = 1.000000e+69, .off = -7.253143638152923145e+52 },
    HP{ .val = 1.000000e+68, .off = 4.719477774861832896e+51 },
    HP{ .val = 1.000000e+67, .off = 1.726322421608144052e+50 },
    HP{ .val = 1.000000e+66, .off = 5.467766613175255107e+49 },
    HP{ .val = 1.000000e+65, .off = 7.909613737163661911e+47 },
    HP{ .val = 1.000000e+64, .off = -2.132041900945439564e+47 },
    HP{ .val = 1.000000e+63, .off = -5.785795994272697265e+46 },
    HP{ .val = 1.000000e+62, .off = -3.502199685943161329e+45 },
    HP{ .val = 1.000000e+61, .off = 5.061286470292598274e+44 },
    HP{ .val = 1.000000e+60, .off = 5.061286470292598472e+43 },
    HP{ .val = 1.000000e+59, .off = 2.831211950439536034e+42 },
    HP{ .val = 1.000000e+58, .off = 5.618805100255863927e+41 },
    HP{ .val = 1.000000e+57, .off = -4.834669211555366251e+40 },
    HP{ .val = 1.000000e+56, .off = -9.190283508143378583e+39 },
    HP{ .val = 1.000000e+55, .off = -1.023506702040855158e+38 },
    HP{ .val = 1.000000e+54, .off = -7.829154040459624616e+37 },
    HP{ .val = 1.000000e+53, .off = 6.779051325638372659e+35 },
    HP{ .val = 1.000000e+52, .off = 6.779051325638372290e+34 },
    HP{ .val = 1.000000e+51, .off = 6.779051325638371598e+33 },
    HP{ .val = 1.000000e+50, .off = -7.629769841091887392e+33 },
    HP{ .val = 1.000000e+49, .off = 5.350972305245182400e+32 },
    HP{ .val = 1.000000e+48, .off = -4.384584304507619764e+31 },
    HP{ .val = 1.000000e+47, .off = -4.384584304507619876e+30 },
    HP{ .val = 1.000000e+46, .off = 6.860180964052978705e+28 },
    HP{ .val = 1.000000e+45, .off = 7.024271097546444878e+28 },
    HP{ .val = 1.000000e+44, .off = -8.821361405306422641e+27 },
    HP{ .val = 1.000000e+43, .off = -1.393721169594140991e+26 },
    HP{ .val = 1.000000e+42, .off = -4.488571267807591679e+25 },
    HP{ .val = 1.000000e+41, .off = -6.200086450407783195e+23 },
    HP{ .val = 1.000000e+40, .off = -3.037860284270036669e+23 },
    HP{ .val = 1.000000e+39, .off = 6.029083362839682141e+22 },
    HP{ .val = 1.000000e+38, .off = 2.251190176543965970e+21 },
    HP{ .val = 1.000000e+37, .off = 4.612373417978788577e+20 },
    HP{ .val = 1.000000e+36, .off = -4.242063737401796198e+19 },
    HP{ .val = 1.000000e+35, .off = 3.136633892082024448e+18 },
    HP{ .val = 1.000000e+34, .off = 5.442476901295718400e+17 },
    HP{ .val = 1.000000e+33, .off = 5.442476901295718400e+16 },
    HP{ .val = 1.000000e+32, .off = -5.366162204393472000e+15 },
    HP{ .val = 1.000000e+31, .off = 3.641037050347520000e+14 },
    HP{ .val = 1.000000e+30, .off = -1.988462483865600000e+13 },
    HP{ .val = 1.000000e+29, .off = 8.566849142784000000e+12 },
    HP{ .val = 1.000000e+28, .off = 4.168802631680000000e+11 },
    HP{ .val = 1.000000e+27, .off = -1.328755507200000000e+10 },
    HP{ .val = 1.000000e+26, .off = -4.764729344000000000e+09 },
    HP{ .val = 1.000000e+25, .off = -9.059696640000000000e+08 },
    HP{ .val = 1.000000e+24, .off = 1.677721600000000000e+07 },
    HP{ .val = 1.000000e+23, .off = 8.388608000000000000e+06 },
    HP{ .val = 1.000000e+22, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+21, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+20, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+19, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+18, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+17, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+16, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+15, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+14, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+13, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+12, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+11, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+10, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+09, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+08, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+07, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+06, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+05, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+04, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+03, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+02, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+01, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e+00, .off = 0.000000000000000000e+00 },
    HP{ .val = 1.000000e-01, .off = -5.551115123125783010e-18 },
    HP{ .val = 1.000000e-02, .off = -2.081668171172168436e-19 },
    HP{ .val = 1.000000e-03, .off = -2.081668171172168557e-20 },
    HP{ .val = 1.000000e-04, .off = -4.792173602385929943e-21 },
    HP{ .val = 1.000000e-05, .off = -8.180305391403130547e-22 },
    HP{ .val = 1.000000e-06, .off = 4.525188817411374069e-23 },
    HP{ .val = 1.000000e-07, .off = 4.525188817411373922e-24 },
    HP{ .val = 1.000000e-08, .off = -2.092256083012847109e-25 },
    HP{ .val = 1.000000e-09, .off = -6.228159145777985254e-26 },
    HP{ .val = 1.000000e-10, .off = -3.643219731549774344e-27 },
    HP{ .val = 1.000000e-11, .off = 6.050303071806019080e-28 },
    HP{ .val = 1.000000e-12, .off = 2.011335237074438524e-29 },
    HP{ .val = 1.000000e-13, .off = -3.037374556340037101e-30 },
    HP{ .val = 1.000000e-14, .off = 1.180690645440101289e-32 },
    HP{ .val = 1.000000e-15, .off = -7.770539987666107583e-32 },
    HP{ .val = 1.000000e-16, .off = 2.090221327596539779e-33 },
    HP{ .val = 1.000000e-17, .off = -7.154242405462192144e-34 },
    HP{ .val = 1.000000e-18, .off = -7.154242405462192572e-35 },
    HP{ .val = 1.000000e-19, .off = 2.475407316473986894e-36 },
    HP{ .val = 1.000000e-20, .off = 5.484672854579042914e-37 },
    HP{ .val = 1.000000e-21, .off = 9.246254777210362522e-38 },
    HP{ .val = 1.000000e-22, .off = -4.859677432657087182e-39 },
    HP{ .val = 1.000000e-23, .off = 3.956530198510069291e-40 },
    HP{ .val = 1.000000e-24, .off = 7.629950044829717753e-41 },
    HP{ .val = 1.000000e-25, .off = -3.849486974919183692e-42 },
    HP{ .val = 1.000000e-26, .off = -3.849486974919184170e-43 },
    HP{ .val = 1.000000e-27, .off = -3.849486974919184070e-44 },
    HP{ .val = 1.000000e-28, .off = 2.876745653839937870e-45 },
    HP{ .val = 1.000000e-29, .off = 5.679342582489572168e-46 },
    HP{ .val = 1.000000e-30, .off = -8.333642060758598930e-47 },
    HP{ .val = 1.000000e-31, .off = -8.333642060758597958e-48 },
    HP{ .val = 1.000000e-32, .off = -5.596730997624190224e-49 },
    HP{ .val = 1.000000e-33, .off = -5.596730997624190604e-50 },
    HP{ .val = 1.000000e-34, .off = 7.232539610818348498e-51 },
    HP{ .val = 1.000000e-35, .off = -7.857545194582380514e-53 },
    HP{ .val = 1.000000e-36, .off = 5.896157255772251528e-53 },
    HP{ .val = 1.000000e-37, .off = -6.632427322784915796e-54 },
    HP{ .val = 1.000000e-38, .off = 3.808059826012723592e-55 },
    HP{ .val = 1.000000e-39, .off = 7.070712060011985131e-56 },
    HP{ .val = 1.000000e-40, .off = 7.070712060011985584e-57 },
    HP{ .val = 1.000000e-41, .off = -5.761291134237854167e-59 },
    HP{ .val = 1.000000e-42, .off = -3.762312935688689794e-59 },
    HP{ .val = 1.000000e-43, .off = -7.745042713519821150e-60 },
    HP{ .val = 1.000000e-44, .off = 4.700987842202462817e-61 },
    HP{ .val = 1.000000e-45, .off = 1.589480203271891964e-62 },
    HP{ .val = 1.000000e-46, .off = -2.299904345391321765e-63 },
    HP{ .val = 1.000000e-47, .off = 2.561826340437695261e-64 },
    HP{ .val = 1.000000e-48, .off = 2.561826340437695345e-65 },
    HP{ .val = 1.000000e-49, .off = 6.360053438741614633e-66 },
    HP{ .val = 1.000000e-50, .off = -7.616223705782342295e-68 },
    HP{ .val = 1.000000e-51, .off = -7.616223705782343324e-69 },
    HP{ .val = 1.000000e-52, .off = -7.616223705782342295e-70 },
    HP{ .val = 1.000000e-53, .off = -3.079876214757872338e-70 },
    HP{ .val = 1.000000e-54, .off = -3.079876214757872821e-71 },
    HP{ .val = 1.000000e-55, .off = 5.423954167728123147e-73 },
    HP{ .val = 1.000000e-56, .off = -3.985444122640543680e-73 },
    HP{ .val = 1.000000e-57, .off = 4.504255013759498850e-74 },
    HP{ .val = 1.000000e-58, .off = -2.570494266573869991e-75 },
    HP{ .val = 1.000000e-59, .off = -2.570494266573869930e-76 },
    HP{ .val = 1.000000e-60, .off = 2.956653608686574324e-77 },
    HP{ .val = 1.000000e-61, .off = -3.952281235388981376e-78 },
    HP{ .val = 1.000000e-62, .off = -3.952281235388981376e-79 },
    HP{ .val = 1.000000e-63, .off = -6.651083908855995172e-80 },
    HP{ .val = 1.000000e-64, .off = 3.469426116645307030e-81 },
    HP{ .val = 1.000000e-65, .off = 7.686305293937516319e-82 },
    HP{ .val = 1.000000e-66, .off = 2.415206322322254927e-83 },
    HP{ .val = 1.000000e-67, .off = 5.709643179581793251e-84 },
    HP{ .val = 1.000000e-68, .off = -6.644495035141475923e-85 },
    HP{ .val = 1.000000e-69, .off = 3.650620143794581913e-86 },
    HP{ .val = 1.000000e-70, .off = 4.333966503770636492e-88 },
    HP{ .val = 1.000000e-71, .off = 8.476455383920859113e-88 },
    HP{ .val = 1.000000e-72, .off = 3.449543675455986564e-89 },
    HP{ .val = 1.000000e-73, .off = 3.077238576654418974e-91 },
    HP{ .val = 1.000000e-74, .off = 4.234998629903623140e-91 },
    HP{ .val = 1.000000e-75, .off = 4.234998629903623412e-92 },
    HP{ .val = 1.000000e-76, .off = 7.303182045714702338e-93 },
    HP{ .val = 1.000000e-77, .off = 7.303182045714701699e-94 },
    HP{ .val = 1.000000e-78, .off = 1.121271649074855759e-96 },
    HP{ .val = 1.000000e-79, .off = 1.121271649074855863e-97 },
    HP{ .val = 1.000000e-80, .off = 3.857468248661243988e-97 },
    HP{ .val = 1.000000e-81, .off = 3.857468248661244248e-98 },
    HP{ .val = 1.000000e-82, .off = 3.857468248661244410e-99 },
    HP{ .val = 1.000000e-83, .off = -3.457651055545315679e-100 },
    HP{ .val = 1.000000e-84, .off = -3.457651055545315933e-101 },
    HP{ .val = 1.000000e-85, .off = 2.257285900866059216e-102 },
    HP{ .val = 1.000000e-86, .off = -8.458220892405268345e-103 },
    HP{ .val = 1.000000e-87, .off = -1.761029146610688867e-104 },
    HP{ .val = 1.000000e-88, .off = 6.610460535632536565e-105 },
    HP{ .val = 1.000000e-89, .off = -3.853901567171494935e-106 },
    HP{ .val = 1.000000e-90, .off = 5.062493089968513723e-108 },
    HP{ .val = 1.000000e-91, .off = -2.218844988608365240e-108 },
    HP{ .val = 1.000000e-92, .off = 1.187522883398155383e-109 },
    HP{ .val = 1.000000e-93, .off = 9.703442563414457296e-110 },
    HP{ .val = 1.000000e-94, .off = 4.380992763404268896e-111 },
    HP{ .val = 1.000000e-95, .off = 1.054461638397900823e-112 },
    HP{ .val = 1.000000e-96, .off = 9.370789450913819736e-113 },
    HP{ .val = 1.000000e-97, .off = -3.623472756142303998e-114 },
    HP{ .val = 1.000000e-98, .off = 6.122223899149788839e-115 },
    HP{ .val = 1.000000e-99, .off = -1.999189980260288281e-116 },
    HP{ .val = 1.000000e-100, .off = -1.999189980260288281e-117 },
    HP{ .val = 1.000000e-101, .off = -5.171617276904849634e-118 },
    HP{ .val = 1.000000e-102, .off = 6.724985085512256320e-119 },
    HP{ .val = 1.000000e-103, .off = 4.246526260008692213e-120 },
    HP{ .val = 1.000000e-104, .off = 7.344599791888147003e-121 },
    HP{ .val = 1.000000e-105, .off = 3.472007877038828407e-122 },
    HP{ .val = 1.000000e-106, .off = 5.892377823819652194e-123 },
    HP{ .val = 1.000000e-107, .off = -1.585470431324073925e-125 },
    HP{ .val = 1.000000e-108, .off = -3.940375084977444795e-125 },
    HP{ .val = 1.000000e-109, .off = 7.869099673288519908e-127 },
    HP{ .val = 1.000000e-110, .off = -5.122196348054018581e-127 },
    HP{ .val = 1.000000e-111, .off = -8.815387795168313713e-128 },
    HP{ .val = 1.000000e-112, .off = 5.034080131510290214e-129 },
    HP{ .val = 1.000000e-113, .off = 2.148774313452247863e-130 },
    HP{ .val = 1.000000e-114, .off = -5.064490231692858416e-131 },
    HP{ .val = 1.000000e-115, .off = -5.064490231692858166e-132 },
    HP{ .val = 1.000000e-116, .off = 5.708726942017560559e-134 },
    HP{ .val = 1.000000e-117, .off = -2.951229134482377772e-134 },
    HP{ .val = 1.000000e-118, .off = 1.451398151372789513e-135 },
    HP{ .val = 1.000000e-119, .off = -1.300243902286690040e-136 },
    HP{ .val = 1.000000e-120, .off = 2.139308664787659449e-137 },
    HP{ .val = 1.000000e-121, .off = 2.139308664787659329e-138 },
    HP{ .val = 1.000000e-122, .off = -5.922142664292847471e-139 },
    HP{ .val = 1.000000e-123, .off = -5.922142664292846912e-140 },
    HP{ .val = 1.000000e-124, .off = 6.673875037395443799e-141 },
    HP{ .val = 1.000000e-125, .off = -1.198636026159737932e-142 },
    HP{ .val = 1.000000e-126, .off = 5.361789860136246995e-143 },
    HP{ .val = 1.000000e-127, .off = -2.838742497733733936e-144 },
    HP{ .val = 1.000000e-128, .off = -5.401408859568103261e-145 },
    HP{ .val = 1.000000e-129, .off = 7.411922949603743011e-146 },
    HP{ .val = 1.000000e-130, .off = -8.604741811861064385e-147 },
    HP{ .val = 1.000000e-131, .off = 1.405673664054439890e-148 },
    HP{ .val = 1.000000e-132, .off = 1.405673664054439933e-149 },
    HP{ .val = 1.000000e-133, .off = -6.414963426504548053e-150 },
    HP{ .val = 1.000000e-134, .off = -3.971014335704864578e-151 },
    HP{ .val = 1.000000e-135, .off = -3.971014335704864748e-152 },
    HP{ .val = 1.000000e-136, .off = -1.523438813303585576e-154 },
    HP{ .val = 1.000000e-137, .off = 2.234325152653707766e-154 },
    HP{ .val = 1.000000e-138, .off = -6.715683724786540160e-155 },
    HP{ .val = 1.000000e-139, .off = -2.986513359186437306e-156 },
    HP{ .val = 1.000000e-140, .off = 1.674949597813692102e-157 },
    HP{ .val = 1.000000e-141, .off = -4.151879098436469092e-158 },
    HP{ .val = 1.000000e-142, .off = -4.151879098436469295e-159 },
    HP{ .val = 1.000000e-143, .off = 4.952540739454407825e-160 },
    HP{ .val = 1.000000e-144, .off = 4.952540739454407667e-161 },
    HP{ .val = 1.000000e-145, .off = 8.508954738630531443e-162 },
    HP{ .val = 1.000000e-146, .off = -2.604839008794855481e-163 },
    HP{ .val = 1.000000e-147, .off = 2.952057864917838382e-164 },
    HP{ .val = 1.000000e-148, .off = 6.425118410988271757e-165 },
    HP{ .val = 1.000000e-149, .off = 2.083792728400229858e-166 },
    HP{ .val = 1.000000e-150, .off = -6.295358232172964237e-168 },
    HP{ .val = 1.000000e-151, .off = 6.153785555826519421e-168 },
    HP{ .val = 1.000000e-152, .off = -6.564942029880634994e-169 },
    HP{ .val = 1.000000e-153, .off = -3.915207116191644540e-170 },
    HP{ .val = 1.000000e-154, .off = 2.709130168030831503e-171 },
    HP{ .val = 1.000000e-155, .off = -1.431080634608215966e-172 },
    HP{ .val = 1.000000e-156, .off = -4.018712386257620994e-173 },
    HP{ .val = 1.000000e-157, .off = 5.684906682427646782e-174 },
    HP{ .val = 1.000000e-158, .off = -6.444617153428937489e-175 },
    HP{ .val = 1.000000e-159, .off = 1.136335243981427681e-176 },
    HP{ .val = 1.000000e-160, .off = 1.136335243981427725e-177 },
    HP{ .val = 1.000000e-161, .off = -2.812077463003137395e-178 },
    HP{ .val = 1.000000e-162, .off = 4.591196362592922204e-179 },
    HP{ .val = 1.000000e-163, .off = 7.675893789924613703e-180 },
    HP{ .val = 1.000000e-164, .off = 3.820022005759999543e-181 },
    HP{ .val = 1.000000e-165, .off = -9.998177244457686588e-183 },
    HP{ .val = 1.000000e-166, .off = -4.012217555824373639e-183 },
    HP{ .val = 1.000000e-167, .off = -2.467177666011174334e-185 },
    HP{ .val = 1.000000e-168, .off = -4.953592503130188139e-185 },
    HP{ .val = 1.000000e-169, .off = -2.011795792799518887e-186 },
    HP{ .val = 1.000000e-170, .off = 1.665450095113817423e-187 },
    HP{ .val = 1.000000e-171, .off = 1.665450095113817487e-188 },
    HP{ .val = 1.000000e-172, .off = -4.080246604750770577e-189 },
    HP{ .val = 1.000000e-173, .off = -4.080246604750770677e-190 },
    HP{ .val = 1.000000e-174, .off = 4.085789420184387951e-192 },
    HP{ .val = 1.000000e-175, .off = 4.085789420184388146e-193 },
    HP{ .val = 1.000000e-176, .off = 4.085789420184388146e-194 },
    HP{ .val = 1.000000e-177, .off = 4.792197640035244894e-194 },
    HP{ .val = 1.000000e-178, .off = 4.792197640035244742e-195 },
    HP{ .val = 1.000000e-179, .off = -2.057206575616014662e-196 },
    HP{ .val = 1.000000e-180, .off = -2.057206575616014662e-197 },
    HP{ .val = 1.000000e-181, .off = -4.732755097354788053e-198 },
    HP{ .val = 1.000000e-182, .off = -4.732755097354787867e-199 },
    HP{ .val = 1.000000e-183, .off = -5.522105321379546765e-201 },
    HP{ .val = 1.000000e-184, .off = -5.777891238658996019e-201 },
    HP{ .val = 1.000000e-185, .off = 7.542096444923057046e-203 },
    HP{ .val = 1.000000e-186, .off = 8.919335748431433483e-203 },
    HP{ .val = 1.000000e-187, .off = -1.287071881492476028e-204 },
    HP{ .val = 1.000000e-188, .off = 5.091932887209967018e-205 },
    HP{ .val = 1.000000e-189, .off = -6.868701054107114024e-206 },
    HP{ .val = 1.000000e-190, .off = -1.885103578558330118e-207 },
    HP{ .val = 1.000000e-191, .off = -1.885103578558330205e-208 },
    HP{ .val = 1.000000e-192, .off = -9.671974634103305058e-209 },
    HP{ .val = 1.000000e-193, .off = -4.805180224387695640e-210 },
    HP{ .val = 1.000000e-194, .off = -1.763433718315439838e-211 },
    HP{ .val = 1.000000e-195, .off = -9.367799983496079132e-212 },
    HP{ .val = 1.000000e-196, .off = -4.615071067758179837e-213 },
    HP{ .val = 1.000000e-197, .off = 1.325840076914194777e-214 },
    HP{ .val = 1.000000e-198, .off = 8.751979007754662425e-215 },
    HP{ .val = 1.000000e-199, .off = 1.789973760091724198e-216 },
    HP{ .val = 1.000000e-200, .off = 1.789973760091724077e-217 },
    HP{ .val = 1.000000e-201, .off = 5.416018159916171171e-218 },
    HP{ .val = 1.000000e-202, .off = -3.649092839644947067e-219 },
    HP{ .val = 1.000000e-203, .off = -3.649092839644947067e-220 },
    HP{ .val = 1.000000e-204, .off = -1.080338554413850956e-222 },
    HP{ .val = 1.000000e-205, .off = -1.080338554413850841e-223 },
    HP{ .val = 1.000000e-206, .off = -2.874486186850417807e-223 },
    HP{ .val = 1.000000e-207, .off = 7.499710055933455072e-224 },
    HP{ .val = 1.000000e-208, .off = -9.790617015372999087e-225 },
    HP{ .val = 1.000000e-209, .off = -4.387389805589732612e-226 },
    HP{ .val = 1.000000e-210, .off = -4.387389805589732612e-227 },
    HP{ .val = 1.000000e-211, .off = -8.608661063232909897e-228 },
    HP{ .val = 1.000000e-212, .off = 4.582811616902018972e-229 },
    HP{ .val = 1.000000e-213, .off = 4.582811616902019155e-230 },
    HP{ .val = 1.000000e-214, .off = 8.705146829444184930e-231 },
    HP{ .val = 1.000000e-215, .off = -4.177150709750081830e-232 },
    HP{ .val = 1.000000e-216, .off = -4.177150709750082366e-233 },
    HP{ .val = 1.000000e-217, .off = -8.202868690748290237e-234 },
    HP{ .val = 1.000000e-218, .off = -3.170721214500530119e-235 },
    HP{ .val = 1.000000e-219, .off = -3.170721214500529857e-236 },
    HP{ .val = 1.000000e-220, .off = 7.606440013180328441e-238 },
    HP{ .val = 1.000000e-221, .off = -1.696459258568569049e-238 },
    HP{ .val = 1.000000e-222, .off = -4.767838333426821244e-239 },
    HP{ .val = 1.000000e-223, .off = 2.910609353718809138e-240 },
    HP{ .val = 1.000000e-224, .off = -1.888420450747209784e-241 },
    HP{ .val = 1.000000e-225, .off = 4.110366804835314035e-242 },
    HP{ .val = 1.000000e-226, .off = 7.859608839574391006e-243 },
    HP{ .val = 1.000000e-227, .off = 5.516332567862468419e-244 },
    HP{ .val = 1.000000e-228, .off = -3.270953451057244613e-245 },
    HP{ .val = 1.000000e-229, .off = -6.932322625607124670e-246 },
    HP{ .val = 1.000000e-230, .off = -4.643966891513449762e-247 },
    HP{ .val = 1.000000e-231, .off = 1.076922443720738305e-248 },
    HP{ .val = 1.000000e-232, .off = -2.498633390800628939e-249 },
    HP{ .val = 1.000000e-233, .off = 4.205533798926934891e-250 },
    HP{ .val = 1.000000e-234, .off = 4.205533798926934891e-251 },
    HP{ .val = 1.000000e-235, .off = 4.205533798926934697e-252 },
    HP{ .val = 1.000000e-236, .off = -4.523850562697497656e-253 },
    HP{ .val = 1.000000e-237, .off = 9.320146633177728298e-255 },
    HP{ .val = 1.000000e-238, .off = 9.320146633177728062e-256 },
    HP{ .val = 1.000000e-239, .off = -7.592774752331086440e-256 },
    HP{ .val = 1.000000e-240, .off = 3.063212017229987840e-257 },
    HP{ .val = 1.000000e-241, .off = 3.063212017229987562e-258 },
    HP{ .val = 1.000000e-242, .off = 3.063212017229987562e-259 },
    HP{ .val = 1.000000e-243, .off = 4.616527473176159842e-261 },
    HP{ .val = 1.000000e-244, .off = 6.965550922098544975e-261 },
    HP{ .val = 1.000000e-245, .off = 6.965550922098544749e-262 },
    HP{ .val = 1.000000e-246, .off = 4.424965697574744679e-263 },
    HP{ .val = 1.000000e-247, .off = -1.926497363734756420e-264 },
    HP{ .val = 1.000000e-248, .off = 2.043167049583681740e-265 },
    HP{ .val = 1.000000e-249, .off = -5.399953725388390154e-266 },
    HP{ .val = 1.000000e-250, .off = -5.399953725388389982e-267 },
    HP{ .val = 1.000000e-251, .off = -1.523328321757102663e-268 },
    HP{ .val = 1.000000e-252, .off = 5.745344310051561161e-269 },
    HP{ .val = 1.000000e-253, .off = -6.369110076296211879e-270 },
    HP{ .val = 1.000000e-254, .off = 8.773957906638504842e-271 },
    HP{ .val = 1.000000e-255, .off = -6.904595826956931908e-273 },
    HP{ .val = 1.000000e-256, .off = 2.267170882721243669e-273 },
    HP{ .val = 1.000000e-257, .off = 2.267170882721243669e-274 },
    HP{ .val = 1.000000e-258, .off = 4.577819683828225398e-275 },
    HP{ .val = 1.000000e-259, .off = -6.975424321706684210e-276 },
    HP{ .val = 1.000000e-260, .off = 3.855741933482293648e-277 },
    HP{ .val = 1.000000e-261, .off = 1.599248963651256552e-278 },
    HP{ .val = 1.000000e-262, .off = -1.221367248637539543e-279 },
    HP{ .val = 1.000000e-263, .off = -1.221367248637539494e-280 },
    HP{ .val = 1.000000e-264, .off = -1.221367248637539647e-281 },
    HP{ .val = 1.000000e-265, .off = 1.533140771175737943e-282 },
    HP{ .val = 1.000000e-266, .off = 1.533140771175737895e-283 },
    HP{ .val = 1.000000e-267, .off = 1.533140771175738074e-284 },
    HP{ .val = 1.000000e-268, .off = 4.223090009274641634e-285 },
    HP{ .val = 1.000000e-269, .off = 4.223090009274641634e-286 },
    HP{ .val = 1.000000e-270, .off = -4.183001359784432924e-287 },
    HP{ .val = 1.000000e-271, .off = 3.697709298708449474e-288 },
    HP{ .val = 1.000000e-272, .off = 6.981338739747150474e-289 },
    HP{ .val = 1.000000e-273, .off = -9.436808465446354751e-290 },
    HP{ .val = 1.000000e-274, .off = 3.389869038611071740e-291 },
    HP{ .val = 1.000000e-275, .off = 6.596538414625427829e-292 },
    HP{ .val = 1.000000e-276, .off = -9.436808465446354618e-293 },
    HP{ .val = 1.000000e-277, .off = 3.089243784609725523e-294 },
    HP{ .val = 1.000000e-278, .off = 6.220756847123745836e-295 },
    HP{ .val = 1.000000e-279, .off = -5.522417137303829470e-296 },
    HP{ .val = 1.000000e-280, .off = 4.263561183052483059e-297 },
    HP{ .val = 1.000000e-281, .off = -1.852675267170212272e-298 },
    HP{ .val = 1.000000e-282, .off = -1.852675267170212378e-299 },
    HP{ .val = 1.000000e-283, .off = 5.314789322934508480e-300 },
    HP{ .val = 1.000000e-284, .off = -3.644541414696392675e-301 },
    HP{ .val = 1.000000e-285, .off = -7.377595888709267777e-302 },
    HP{ .val = 1.000000e-286, .off = -5.044436842451220838e-303 },
    HP{ .val = 1.000000e-287, .off = -2.127988034628661760e-304 },
    HP{ .val = 1.000000e-288, .off = -5.773549044406860911e-305 },
    HP{ .val = 1.000000e-289, .off = -1.216597782184112068e-306 },
    HP{ .val = 1.000000e-290, .off = -6.912786859962547924e-307 },
    HP{ .val = 1.000000e-291, .off = 3.767567660872018813e-308 },
};
