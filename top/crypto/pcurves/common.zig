const mem = @import("../../mem.zig");
const debug = @import("../../debug.zig");
const builtin = @import("../../builtin.zig");
const utils = @import("../utils.zig");
const errors = @import("../errors.zig");
/// Parameters to create a finite field type.
pub const FieldParams = struct {
    fiat: type,
    field_order: comptime_int,
    field_bits: comptime_int,
    saturated_bits: comptime_int,
    encoded_len: comptime_int,
};
/// A field element, internally stored in Montgomery domain.
pub fn Field(comptime params: FieldParams) type {
    const Fe = extern struct {
        const Fe = @This();
        limbs: params.fiat.MontgomeryDomainFieldElement,
        /// Field size.
        pub const field_order = params.field_order;
        /// Number of bits to represent the set of all elements.
        pub const field_bits = params.field_bits;
        /// Number of bits that can be saturated without overflowing.
        pub const saturated_bits = params.saturated_bits;
        /// Number of bytes required to encode an element.
        pub const encoded_len = params.encoded_len;
        /// Zero.
        pub const zero: Fe = Fe{ .limbs = builtin.zero(params.fiat.MontgomeryDomainFieldElement) };
        /// One.
        pub const one = one: {
            var fe: Fe = undefined;
            params.fiat.setOne(&fe.limbs);
            break :one fe;
        };
        /// Reject non-canonical encodings of an element.
        pub fn rejectNonCanonical(s_: [encoded_len]u8, endian: builtin.Endian) !void {
            var s = if (endian == .Little) s_ else orderSwap(s_);
            const field_order_s = comptime fos: {
                var fos: [encoded_len]u8 = undefined;
                mem.writeIntLittle(@Type(.{ .Int = .{ .signedness = .unsigned, .bits = encoded_len * 8 } }), &fos, field_order);
                break :fos fos;
            };
            if (utils.timingSafeCompare(u8, &s, &field_order_s, .Little) != .lt) {
                return error.NonCanonical;
            }
        }
        /// Swap the endianness of an encoded element.
        pub fn orderSwap(s: [encoded_len]u8) [encoded_len]u8 {
            var t = s;
            for (s, 0..) |x, i| t[t.len - 1 - i] = x;
            return t;
        }
        /// Unpack a field element.
        pub fn fromBytes(s_: [encoded_len]u8, endian: builtin.Endian) !Fe {
            var s = if (endian == .Little) s_ else orderSwap(s_);
            try rejectNonCanonical(s, .Little);
            var limbs_z: params.fiat.NonMontgomeryDomainFieldElement = undefined;
            params.fiat.fromBytes(&limbs_z, s);
            var limbs: params.fiat.MontgomeryDomainFieldElement = undefined;
            params.fiat.toMontgomery(&limbs, limbs_z);
            return Fe{ .limbs = limbs };
        }
        /// Pack a field element.
        pub fn toBytes(fe: Fe, endian: builtin.Endian) [encoded_len]u8 {
            var limbs_z: params.fiat.NonMontgomeryDomainFieldElement = undefined;
            params.fiat.fromMontgomery(&limbs_z, fe.limbs);
            var s: [encoded_len]u8 = undefined;
            params.fiat.toBytes(&s, limbs_z);
            return if (endian == .Little) s else orderSwap(s);
        }
        /// Element as an integer.
        pub const IntRepr = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = params.field_bits } });
        /// Create a field element from an integer.
        pub fn fromInt(comptime x: IntRepr) !Fe {
            var s: [encoded_len]u8 = undefined;
            mem.writeIntLittle(IntRepr, &s, x);
            return fromBytes(s, .Little);
        }
        /// Return the field element as an integer.
        pub fn toInt(fe: Fe) IntRepr {
            const s = fe.toBytes(.Little);
            return mem.readIntLittle(IntRepr, &s);
        }
        /// Return true if the field element is zero.
        pub fn isZero(fe: Fe) bool {
            var z: @TypeOf(fe.limbs[0]) = undefined;
            params.fiat.nonzero(&z, fe.limbs);
            return z == 0;
        }
        /// Return true if both field elements are equivalent.
        pub fn equivalent(a: Fe, b: Fe) bool {
            return a.sub(b).isZero();
        }
        /// Return true if the element is odd.
        pub fn isOdd(fe: Fe) bool {
            const s = fe.toBytes(.Little);
            return @as(u1, @truncate(s[0])) != 0;
        }
        /// Conditonally replace a field element with `a` if `c` is positive.
        pub fn cMov(fe: *Fe, a: Fe, c: u1) void {
            params.fiat.selectznz(&fe.limbs, c, fe.limbs, a.limbs);
        }
        /// Add field elements.
        pub fn add(a: Fe, b: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.add(&fe.limbs, a.limbs, b.limbs);
            return fe;
        }
        /// Subtract field elements.
        pub fn sub(a: Fe, b: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.sub(&fe.limbs, a.limbs, b.limbs);
            return fe;
        }
        /// Double a field element.
        pub fn dbl(a: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.add(&fe.limbs, a.limbs, a.limbs);
            return fe;
        }
        /// Multiply field elements.
        pub fn mul(a: Fe, b: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.mul(&fe.limbs, a.limbs, b.limbs);
            return fe;
        }
        /// Square a field element.
        pub fn sq(a: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.mul(&fe.limbs, a.limbs, a.limbs);
            return fe;
        }
        /// Square a field element n times.
        fn sqn(a: Fe, n: usize) Fe {
            var fe = a;
            for (0..n) |_| {
                fe = fe.sq();
            }
            return fe;
        }
        /// Compute a^n.
        pub fn pow(a: Fe, comptime T: type, comptime n: T) Fe {
            var fe = one;
            var x: T = n;
            var t = a;
            while (true) {
                if (@as(u1, @truncate(x)) != 0) fe = fe.mul(t);
                x >>= 1;
                if (x == 0) break;
                t = t.sq();
            }
            return fe;
        }
        /// Negate a field element.
        pub fn neg(a: Fe) Fe {
            var fe: Fe = undefined;
            params.fiat.opp(&fe.limbs, a.limbs);
            return fe;
        }
        /// Return the inverse of a field element, or 0 if a=0.
        // Field inversion from https://eprint.iacr.org/2021/549.pdf
        pub fn invert(a: Fe) Fe {
            const iterations = (49 * field_bits + 57) / 17;
            const Limbs = @TypeOf(a.limbs);
            const Word = @TypeOf(a.limbs[0]);
            const XLimbs = [a.limbs.len + 1]Word;
            var d: Word = 1;
            var f = comptime blk: {
                var f: XLimbs = undefined;
                params.fiat.msat(&f);
                break :blk f;
            };
            var g: XLimbs = undefined;
            params.fiat.fromMontgomery(g[0..a.limbs.len], a.limbs);
            g[g.len - 1] = 0;
            var r = Fe.one.limbs;
            var v = Fe.zero.limbs;
            var out1: Word = undefined;
            var out2: XLimbs = undefined;
            var out3: XLimbs = undefined;
            var out4: Limbs = undefined;
            var out5: Limbs = undefined;
            var i: usize = 0;
            while (i < iterations - iterations % 2) : (i += 2) {
                params.fiat.divstep(&out1, &out2, &out3, &out4, &out5, d, f, g, v, r);
                params.fiat.divstep(&d, &f, &g, &v, &r, out1, out2, out3, out4, out5);
            }
            if (iterations % 2 != 0) {
                params.fiat.divstep(&out1, &out2, &out3, &out4, &out5, d, f, g, v, r);
                v = out4;
                f = out2;
            }
            var v_opp: Limbs = undefined;
            params.fiat.opp(&v_opp, v);
            params.fiat.selectznz(&v, @as(u1, @truncate(f[f.len - 1] >> (@bitSizeOf(Word) - 1))), v, v_opp);
            const precomp = blk: {
                var precomp: Limbs = undefined;
                params.fiat.divstepPrecomp(&precomp);
                break :blk precomp;
            };
            var fe: Fe = undefined;
            params.fiat.mul(&fe.limbs, v, precomp);
            return fe;
        }
        /// Return true if the field element is a square.
        pub fn isSquare(x2: Fe) bool {
            if (field_order == 115792089210356248762697446949407573530086143415290314195533631308867097853951) {
                const t110 = x2.mul(x2.sq()).sq();
                const t111 = x2.mul(t110);
                const t111111 = t111.mul(x2.mul(t110).sqn(3));
                const x15 = t111111.sqn(6).mul(t111111).sqn(3).mul(t111);
                const x16 = x15.sq().mul(x2);
                const x53 = x16.sqn(16).mul(x16).sqn(15);
                const x47 = x15.mul(x53);
                const ls = x47.mul(((x53.sqn(17).mul(x2)).sqn(143).mul(x47)).sqn(47)).sq().mul(x2);
                return ls.equivalent(Fe.one);
            } else if (field_order == 39402006196394479212279040100143613805079739270465446667948293404245721771496870329047266088258938001861606973112319) {
                const t111 = x2.mul(x2.mul(x2.sq()).sq());
                const t111111 = t111.mul(t111.sqn(3));
                const t1111110 = t111111.sq();
                const t1111111 = x2.mul(t1111110);
                const x12 = t1111110.sqn(5).mul(t111111);
                const x31 = x12.sqn(12).mul(x12).sqn(7).mul(t1111111);
                const x32 = x31.sq().mul(x2);
                const x63 = x32.sqn(31).mul(x31);
                const x126 = x63.sqn(63).mul(x63);
                const ls = x126.sqn(126).mul(x126).sqn(3).mul(t111).sqn(33).mul(x32).sqn(95).mul(x31);
                return ls.equivalent(Fe.one);
            } else {
                const ls = x2.pow(@Type(.{ .Int = .{ .signedness = .unsigned, .bits = field_bits } }), (field_order - 1) / 2); // Legendre symbol
                return ls.equivalent(Fe.one);
            }
        }
        // x=x2^((field_order+1)/4) w/ field order=3 (mod 4).
        fn uncheckedSqrt(x2: Fe) Fe {
            debug.assert(field_order % 4 == 3);
            if (field_order == 115792089210356248762697446949407573530086143415290314195533631308867097853951) {
                const t11 = x2.mul(x2.sq());
                const t1111 = t11.mul(t11.sqn(2));
                const t11111111 = t1111.mul(t1111.sqn(4));
                const x16 = t11111111.sqn(8).mul(t11111111);
                return x16.sqn(16).mul(x16).sqn(32).mul(x2).sqn(96).mul(x2).sqn(94);
            } else if (field_order == 39402006196394479212279040100143613805079739270465446667948293404245721771496870329047266088258938001861606973112319) {
                const t111 = x2.mul(x2.mul(x2.sq()).sq());
                const t111111 = t111.mul(t111.sqn(3));
                const t1111110 = t111111.sq();
                const t1111111 = x2.mul(t1111110);
                const x12 = t1111110.sqn(5).mul(t111111);
                const x31 = x12.sqn(12).mul(x12).sqn(7).mul(t1111111);
                const x32 = x31.sq().mul(x2);
                const x63 = x32.sqn(31).mul(x31);
                const x126 = x63.sqn(63).mul(x63);
                return x126.sqn(126).mul(x126).sqn(3).mul(t111).sqn(33).mul(x32).sqn(64).mul(x2).sqn(30);
            } else if (field_order == 115792089237316195423570985008687907853269984665640564039457584007908834671663) {
                const t11 = x2.mul(x2.sq());
                const t1111 = t11.mul(t11.sqn(2));
                const t11111 = x2.mul(t1111.sq());
                const t1111111 = t11.mul(t11111.sqn(2));
                const x11 = t1111111.sqn(4).mul(t1111);
                const x22 = x11.sqn(11).mul(x11);
                const x27 = x22.sqn(5).mul(t11111);
                const x54 = x27.sqn(27).mul(x27);
                const x108 = x54.sqn(54).mul(x54);
                return x108.sqn(108).mul(x108).sqn(7).mul(t1111111).sqn(23).mul(x22).sqn(6).mul(t11).sqn(2);
            } else {
                return x2.pow(@Type(.{ .Int = .{ .signedness = .unsigned, .bits = field_bits } }), (field_order + 1) / 4);
            }
        }
        /// Compute the square root of `x2`, returning `error.NotSquare` if `x2` was not a square.
        pub fn sqrt(x2: Fe) !Fe {
            const x = x2.uncheckedSqrt();
            if (x.sq().equivalent(x2)) {
                return x;
            }
            return error.NotSquare;
        }
    };
    return Fe;
}
pub const arith = struct {
    pub const safety: bool = false;
    pub fn addcarryxU64(out1: *u64, out2: *u8, arg1: u8, arg2: u64, arg3: u64) void {
        @setRuntimeSafety(safety);
        const ov1 = @addWithOverflow(arg2, arg3);
        const ov2 = @addWithOverflow(ov1[0], arg1);
        out1.* = ov2[0];
        out2.* = ov1[1] | ov2[1];
    }
    pub fn subborrowxU64(out1: *u64, out2: *u8, arg1: u8, arg2: u64, arg3: u64) void {
        @setRuntimeSafety(safety);
        const ov1 = @subWithOverflow(arg2, arg3);
        const ov2 = @subWithOverflow(ov1[0], arg1);
        out1.* = ov2[0];
        out2.* = ov1[1] | ov2[1];
    }
    pub fn mulxU64(out1: *u64, out2: *u64, arg1: u64, arg2: u64) void {
        @setRuntimeSafety(safety);
        const x: u128 = @as(u128, arg1) *% @as(u128, arg2);
        out1.* = @as(u64, @truncate(x));
        out2.* = @as(u64, @truncate(x >> 64));
    }
    pub fn cmovznzU64(out1: *u64, arg1: u8, arg2: u64, arg3: u64) void {
        @setRuntimeSafety(safety);
        const mask: u64 = 0 -% @as(u64, arg1);
        out1.* = (mask & arg3) | ((~mask) & arg2);
    }
};
