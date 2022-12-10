//! Miscellaneous low level functions: Primarily related to packing, bit-masks
//! and bit-shifts. For operator wrappers which unambiguously mimic Zig's
//! default behaviour see builtin.zig.
const lit = @import("./lit.zig");
const builtin = @import("./builtin.zig");

// For operations with no comptime operands and register-sized integers prefer
// the following four functions. These reference the assembly directly below,
// so no truncation is needed to circumvent Zig's requirements for shift_amt.
// (UB?)
pub inline fn shlx64(value: u64, shift_amt: u64) u64 {
    return shlx(u64, value, shift_amt);
}
pub inline fn shlx32(value: u32, shift_amt: u32) u32 {
    return shlx(u32, value, shift_amt);
}
pub inline fn shrx64(value: u64, shift_amt: u64) u64 {
    return shrx(u64, value, shift_amt);
}
pub inline fn shrx32(value: u32, shift_amt: u32) u32 {
    return shrx(u32, value, shift_amt);
}
inline fn shlx(comptime T: type, value: T, shift_amt: T) T {
    return asm ("shlx" ++ switch (T) {
            u32 => "l",
            u64 => "q",
            else => @compileError("invalid operand type for this instruction"),
        } ++ " %[shift_amt], %[value], %[ret]"
        : [ret] "=r" (-> T),
        : [value] "r" (value),
          [shift_amt] "r" (shift_amt),
    );
}
inline fn shrx(comptime T: type, value: T, shift_amt: T) T {
    return asm ("shrx" ++ switch (T) {
            u32 => "l",
            u64 => "q",
            else => @compileError("invalid operand type for this instruction"),
        } ++ " %[shift_amt], %[value], %[ret]"
        : [ret] "=r" (-> T),
        : [value] "r" (value),
          [shift_amt] "r" (shift_amt),
    );
}
// The following operations are distinct from similarly named in builtin by
// truncating instead of casting. This matches the machine behaviour more
// closely. There is no need to forward these to a generic function to ask meta
// what the shift_amt types are; we know them already and want to save the
// compiler the extra work.
pub inline fn shl64(value: u64, shift_amt: u64) u64 {
    return value << @truncate(u6, shift_amt);
}
pub inline fn shl32(value: u32, shift_amt: u32) u32 {
    return value << @truncate(u5, shift_amt);
}
pub inline fn shl16(value: u16, shift_amt: u16) u16 {
    return value << @truncate(u4, shift_amt);
}
pub inline fn shl8(value: u8, shift_amt: u8) u8 {
    return value << @truncate(u3, shift_amt);
}
pub inline fn shr64(value: u64, shift_amt: u64) u64 {
    return value >> @truncate(u6, shift_amt);
}
pub inline fn shr32(value: u32, shift_amt: u32) u32 {
    return value >> @truncate(u5, shift_amt);
}
pub inline fn shr16(value: u16, shift_amt: u16) u16 {
    return value >> @truncate(u4, shift_amt);
}
pub inline fn shr8(value: u8, shift_amt: u8) u8 {
    return value >> @truncate(u3, shift_amt);
}
pub inline fn shl64T(comptime T: type, value: u64, shift_amt: u64) T {
    return @intCast(T, value << @truncate(u6, shift_amt));
}
pub inline fn shl32T(comptime T: type, value: u32, shift_amt: u32) T {
    return @intCast(T, value << @truncate(u5, shift_amt));
}
pub inline fn shl16T(comptime T: type, value: u16, shift_amt: u16) T {
    return @intCast(T, value << @truncate(u4, shift_amt));
}
pub inline fn shl8T(comptime T: type, value: u8, shift_amt: u8) T {
    return @intCast(T, value << @truncate(u3, shift_amt));
}
pub inline fn shr64T(comptime T: type, value: u64, shift_amt: u64) T {
    return @intCast(T, value >> @truncate(u6, shift_amt));
}
pub inline fn shr32T(comptime T: type, value: u32, shift_amt: u16) T {
    return @intCast(T, value >> @truncate(u5, shift_amt));
}
pub inline fn shr16T(comptime T: type, value: u16, shift_amt: u16) T {
    return @intCast(T, value >> @truncate(u4, shift_amt));
}
pub inline fn shr8T(comptime T: type, value: u8, shift_amt: u8) T {
    return @intCast(T, value >> @truncate(u3, shift_amt));
}

// Conditional moves--for integers prefer dedicated functions. Prevents lazy-
// evaluating the conditional values by ordering their evaluation before the
// function is called.
pub inline fn cmov8(b: bool, t_value: u8, f_value: u8) u8 {
    return if (b) t_value else f_value;
}
pub inline fn cmov16(b: bool, t_value: u16, f_value: u16) u16 {
    return if (b) t_value else f_value;
}
pub inline fn cmov32(b: bool, t_value: u32, f_value: u32) u32 {
    return if (b) t_value else f_value;
}
pub inline fn cmov64(b: bool, t_value: u64, f_value: u64) u64 {
    return if (b) t_value else f_value;
}
pub inline fn cmov8z(b: bool, t_value: u8) u8 {
    return if (b) t_value else 0;
}
pub inline fn cmov16z(b: bool, t_value: u16) u16 {
    return if (b) t_value else 0;
}
pub inline fn cmov32z(b: bool, t_value: u32) u32 {
    return if (b) t_value else 0;
}
pub inline fn cmov64z(b: bool, t_value: u64) u64 {
    return if (b) t_value else 0;
}
pub inline fn cmovu(comptime Unsigned: type, b: bool, t_value: Unsigned, f_value: Unsigned) u64 {
    return if (b) t_value else f_value;
}
pub inline fn cmovi(comptime Signed: type, b: bool, t_value: Signed, f_value: Signed) u64 {
    return if (b) t_value else f_value;
}
pub inline fn cmovuz(comptime Unsigned: type, b: bool, t_value: Unsigned) u64 {
    return if (b) t_value else 0;
}
pub inline fn cmoviz(comptime Signed: type, b: bool, t_value: Signed) u64 {
    return if (b) t_value else 0;
}
pub inline fn cmovV(comptime b: bool, any: anytype) @TypeOf(if (b) any) {
    return if (b) any;
}
pub inline fn cmovx(b: bool, t_value: anytype, f_value: @TypeOf(t_value)) @TypeOf(t_value) {
    return if (b) t_value else f_value;
}
pub inline fn cmovxZ(b: bool, t_value: anytype) ?@TypeOf(t_value) {
    return if (b) t_value else null;
}
// Basic arithmetic operations--safety off by default:
inline fn add(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +% arg2;
}
inline fn sub(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -% arg2;
}
inline fn mul(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *% arg2;
}
inline fn div(comptime T: type, arg1: T, arg2: T) T {
    return arg1 / arg2;
}
pub inline fn sub64(arg1: u64, arg2: u64) u64 {
    return sub(u64, arg1, arg2);
}
pub inline fn mul64(arg1: u64, arg2: u64) u64 {
    return mul(u64, arg1, arg2);
}
pub inline fn add64(arg1: u64, arg2: u64) u64 {
    return add(u64, arg1, arg2);
}
pub inline fn div64(arg1: u64, arg2: u64) u64 {
    return div(u64, arg1, arg2);
}
pub inline fn sub32(arg1: u32, arg2: u32) u32 {
    return sub(u32, arg1, arg2);
}
pub inline fn mul32(arg1: u32, arg2: u32) u32 {
    return mul(u32, arg1, arg2);
}
pub inline fn add32(arg1: u32, arg2: u32) u32 {
    return add(u32, arg1, arg2);
}
pub inline fn div32(arg1: u32, arg2: u32) u32 {
    return div(u32, arg1, arg2);
}
pub inline fn sub16(arg1: u16, arg2: u16) u16 {
    return sub(u16, arg1, arg2);
}
pub inline fn mul16(arg1: u16, arg2: u16) u16 {
    return mul(u16, arg1, arg2);
}
pub inline fn add16(arg1: u16, arg2: u16) u16 {
    return add(u16, arg1, arg2);
}
pub inline fn div16(arg1: u16, arg2: u16) u16 {
    return div(u16, arg1, arg2);
}
pub inline fn sub8(arg1: u8, arg2: u8) u8 {
    return sub(u8, arg1, arg2);
}
pub inline fn mul8(arg1: u8, arg2: u8) u8 {
    return mul(u8, arg1, arg2);
}
pub inline fn add8(arg1: u8, arg2: u8) u8 {
    return add(u8, arg1, arg2);
}
pub inline fn div8(arg1: u8, arg2: u8) u8 {
    return div(u8, arg1, arg2);
}
// Basic bit-wise operations--same behaviour as builtin.
inline fn @"and"(comptime T: type, arg1: T, arg2: T) T {
    return arg1 & arg2;
}
inline fn @"or"(comptime T: type, arg1: T, arg2: T) T {
    return arg1 | arg2;
}
inline fn xor(comptime T: type, arg1: T, arg2: T) T {
    return arg1 ^ arg2;
}
pub inline fn and64(arg1: u64, arg2: u64) u64 {
    return @"and"(u64, arg1, arg2);
}
pub inline fn andn64(arg1: u64, arg2: u64) u64 {
    return @"and"(u64, arg1, ~arg2);
}
pub inline fn or64(arg1: u64, arg2: u64) u64 {
    return @"or"(u64, arg1, arg2);
}
pub inline fn orn64(arg1: u64, arg2: u64) u64 { // Not a real instruction
    return @"or"(u64, arg1, ~arg2);
}
pub inline fn xor64(arg1: u64, arg2: u64) u64 {
    return xor(u64, arg1, arg2);
}
pub inline fn and32(arg1: u32, arg2: u32) u32 {
    return @"and"(u32, arg1, arg2);
}
pub inline fn andn32(arg1: u32, arg2: u32) u32 {
    return @"and"(u32, arg1, ~arg2);
}
pub inline fn or32(arg1: u32, arg2: u32) u32 {
    return @"or"(u32, arg1, arg2);
}
pub inline fn orn32(arg1: u32, arg2: u32) u32 {
    return @"or"(u32, arg1, ~arg2);
}
pub inline fn xor32(arg1: u32, arg2: u32) u32 {
    return xor(u32, arg1, arg2);
}

pub inline fn alignA(value: anytype, alignment: @TypeOf(value)) @TypeOf(value) {
    const mask: @TypeOf(value) = alignment - 1;
    return (value +% mask) & ~mask;
}
pub inline fn alignB(value: anytype, alignment: @TypeOf(value)) @TypeOf(value) {
    const mask: @TypeOf(value) = alignment - 1;
    return value & ~mask;
}
pub inline fn alignA64(value: u64, alignment: u64) u64 {
    const mask: u64 = alignment - 1;
    return (value +% mask) & ~mask;
}
pub inline fn alignB64(value: u64, alignment: u64) u64 {
    const mask: u64 = alignment - 1;
    return value & ~mask;
}
pub inline fn halfMask64(pop_count: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @truncate(u6, pop_count);
    const int_max_mask: u64 = ~@as(u64, 0);
    const int_sub_mask: u64 = @bitCast(u64, ~(iunit << popcnt_shl));
    return cmov64(pop_count == 64, int_max_mask, int_sub_mask);
}
pub inline fn bitMask64(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @truncate(u6, pop_count);
    const tzcnt_shl: u6 = @truncate(u6, shift_amt);
    const int_max_mask: u64 = ~@as(u64, 0);
    const int_sub_mask: u64 = @bitCast(u64, ~(iunit << popcnt_shl) << tzcnt_shl);
    return cmov64(pop_count == 64, int_max_mask, int_sub_mask);
}
pub inline fn bitMask64NonZero(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = @as(i64, -1 << 1);
    const popcnt_shl: u6 = @truncate(u6, pop_count - 1);
    const tzcnt_shl: u6 = @truncate(u6, shift_amt);
    return @bitCast(u64, ~(iunit << popcnt_shl) << tzcnt_shl);
}
pub inline fn halfMask64NonMax(pop_count: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @truncate(u6, pop_count);
    return @bitCast(u64, ~(iunit << popcnt_shl));
}
pub inline fn bitMask64NonMax(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = @as(i64, -1);
    const popcnt_shl: u6 = @truncate(u6, pop_count);
    const tzcnt_shl: u6 = @truncate(u6, shift_amt);
    return @bitCast(u64, ~(iunit << popcnt_shl) << tzcnt_shl);
}
pub inline fn shiftRightTruncate(
    comptime T: type,
    comptime U: type,
    value: T,
    comptime shift_amt: comptime_int,
) U {
    return @truncate(U, value >> shift_amt);
}
pub inline fn shiftRightMaskTruncate(
    comptime T: type,
    comptime U: type,
    value: T,
    comptime shift_amt: comptime_int,
    comptime pop_count: comptime_int,
) U {
    return @truncate(U, value >> shift_amt) & ((@as(U, 1) << pop_count) -% 1);
}

/// Derives and packs approximation counts.
pub fn packSingleApproxB(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(n_bytes, n_bytes_clz));
    return builtin.shl(u16, n_bytes_clz, 8) | l_bytes_cls;
}
pub fn unpackSingleApproxB(s_counts_l: u64) u64 {
    const n_bytes_clz: u64 = shrx64(s_counts_l, 8);
    return shrx64(~shrx64(lit.max_bit_u64, s_counts_l), n_bytes_clz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
pub fn packSingleApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packSingleApproxB(n_bytes);
    return shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
pub fn unpackSingleApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = builtin.shrY(u64, u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
pub fn approx(n_bytes: u64) u64 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(n_bytes, n_bytes_clz));
    return reverseApproximateAbove(n_bytes_clz, l_bytes_cls);
}
/// Derives and packs approximation counts.
pub fn packAlignedApproxB(n_bytes: u64) u16 {
    const n_bytes_pop: u8 = builtin.popcnt(u64, n_bytes);
    const n_bytes_clz: u8 = builtin.tzcnt(u64, n_bytes);
    return builtin.shl(u16, n_bytes_pop, 8) | builtin.sub(u16, 64, (n_bytes_pop + n_bytes_clz));
}
/// Unpacks approximation counts and computes the approximation.
pub fn unpackAlignedApproxB(s_counts_l: u16) u64 {
    const n_bytes_pop: u8 = builtin.maskZ(u16, u8, s_counts_l);
    const n_bytes_ctz: u8 = shr16T(u8, s_counts_l, 8);
    return shlx64(shlx64(1, n_bytes_pop) -% 1, n_bytes_ctz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
pub fn packAlignedApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packAlignedApproxB(n_bytes);
    return shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
pub fn unpackAlignedApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = builtin.shrY(u64, u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
pub fn alignedApprox(n_bytes: u64) u64 {
    const n_bytes_pop: u8 = builtin.popcnt(u64, n_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    return shlx64(shlx64(1, n_bytes_pop) -% 1, 64 -% (n_bytes_pop + n_bytes_clz));
}
inline fn reverseApproximateAbove(n_bytes_clz: u8, l_bytes_cls: u8) u64 {
    return shrx64(~builtin.shr(u64, lit.max_bit_u64, l_bytes_cls), n_bytes_clz);
}
inline fn reverseApproximateBelow(m_bytes_clz: u8, o_bytes_cls: u8) u64 {
    return shrx64(~builtin.shr(u64, lit.max_bit_u64, o_bytes_cls -% 1), m_bytes_clz) +% 1;
}
// The following functions require 32 bits total.
inline fn packDouble(l_bytes_clz: u8, l_bytes_cls: u8, m_bytes_clz: u8, m_bytes_cls: u8) u32 {
    const s_lb_counts: u16 = builtin.pack16(l_bytes_clz, l_bytes_cls);
    const s_ub_counts: u16 = builtin.pack16(m_bytes_clz, m_bytes_cls -% 1);
    return builtin.pack32(s_lb_counts, s_ub_counts);
}
inline fn unpackDouble(l_bytes_clz: u8, l_bytes_ctz: u64, m_bytes_clz: u8, o_bytes_ctz: u64) u64 {
    const o_bytes: u64 = shrx64(l_bytes_ctz, l_bytes_clz);
    const p_bytes: u64 = shrx64(o_bytes_ctz, m_bytes_clz);
    return sub64(o_bytes, p_bytes);
}
pub inline fn partialPackSingleApprox(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(n_bytes, n_bytes_clz));
    const s_lb_counts: u16 = builtin.pack16(n_bytes_clz, l_bytes_cls);
    return s_lb_counts;
}
pub inline fn partialUnpackSingleApprox(s_lb_counts: u16) u64 {
    const n_bytes_clz: u8 = mask8H(s_lb_counts);
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = shrx64(l_bytes_ctz, n_bytes_clz);
    return o_bytes;
}
pub inline fn partialPackDoubleApprox(n_bytes: u64, o_bytes: u64) u16 {
    const m_bytes: u64 = sub64(o_bytes, n_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(m_bytes, m_bytes_clz));
    const s_ub_counts: u16 = builtin.pack16(m_bytes_clz, m_bytes_cls -% 1);
    return s_ub_counts;
}
pub inline fn partialUnpackDoubleApprox(o_bytes: u64, s_ub_counts: u16) u64 {
    const o_bytes_cls: u8 = mask8H(s_ub_counts);
    const o_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = shrx64(o_bytes_ctz, o_bytes_cls);
    const s_bytes: u64 = sub64(o_bytes, p_bytes +% 1);
    return s_bytes;
}
/// Derives and packs approximation counts.
pub fn packDoubleApproxBOld(n_bytes: u64) u32 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const n_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(n_bytes, n_bytes_clz));
    const n_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, n_bytes_cls);
    const o_bytes: u64 = shrx64(n_bytes_ctz, n_bytes_clz);
    const m_bytes: u64 = sub64(o_bytes, n_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(m_bytes, m_bytes_clz));
    return packDouble(n_bytes_clz, n_bytes_cls, m_bytes_clz, m_bytes_cls);
}
pub inline fn packDoubleApproxB(k_bytes: u64) u32 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~shr64(lit.max_bit_u64, l_bytes_cls);
    const o_bytes: u64 = shrx64(l_bytes_ctz, l_bytes_clz);
    const m_bytes: u64 = sub64(o_bytes, k_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(m_bytes, m_bytes_clz));
    return packDouble(l_bytes_clz, l_bytes_cls, m_bytes_clz, m_bytes_cls);
}
/// Unpacks approximation counts and computes the approximation.
pub fn unpackDoubleApproxB(s_lu_counts: u32) u64 {
    const s_lb_counts: u32 = shr32(s_lu_counts, 16);
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_lb_counts);
    const m_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_lu_counts);
    const o_bytes: u64 = shrx64(l_bytes_ctz, shr64(s_lb_counts, 8));
    const p_bytes: u64 = shrx64(m_bytes_ctz, shr64(s_lu_counts, 8));
    return builtin.subWrap(u64, p_bytes, o_bytes +% 1);
}
pub fn unpackDoubleApproxHA(s_lb_counts: u64) u64 {
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = shrx64(l_bytes_ctz, shr64(s_lb_counts, 8));
    return o_bytes -% 1;
}
pub fn unpackDoubleApproxHB(s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = shrx64(m_bytes_ctz, shr64(s_ub_counts, 8));
    return p_bytes;
}
pub fn unpackDoubleApproxC(s_lb_counts: u64, s_ub_counts: u64) u64 {
    return sub64(unpackDoubleApproxHA(s_lb_counts), unpackDoubleApproxHB(s_ub_counts));
}
pub fn unpackDoubleApproxH(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, shrx64(s_ub_counts, 48));
    const p_bytes: u64 = shrx64(m_bytes_ctz, shr64(s_ub_counts, 56));
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, shrx64(s_lb_counts, 48));
    const o_bytes: u64 = shrx64(l_bytes_ctz, shr64(s_lb_counts, 56));
    return sub64(o_bytes -% 1, p_bytes);
}
pub fn unpackDoubleApproxS(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = shrx64(m_bytes_ctz, shr64(s_ub_counts, 8));
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = shrx64(l_bytes_ctz, shr64(s_lb_counts, 8));
    return sub64(o_bytes -% 1, p_bytes);
}
pub fn approxDouble(k_bytes: u64) u64 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, l_bytes_cls);
    const m_bytes: u64 = shrx64(l_bytes_ctz, l_bytes_clz);
    const n_bytes: u64 = sub64(m_bytes, k_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const n_bytes_cls: u8 = builtin.lzcnt(u64, ~shlx64(n_bytes, n_bytes_clz)) -% 1;
    const n_bytes_ctz: u64 = ~shrx64(lit.max_bit_u64, n_bytes_cls);
    return sub64(m_bytes, shrx64(n_bytes_ctz, n_bytes_clz) +% 1);
}
