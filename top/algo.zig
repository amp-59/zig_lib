const lit = @import("./lit.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

/// Derives and packs approximation counts.
fn packSingleApproxB(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(n_bytes, n_bytes_clz));
    return builtin.shl(u16, n_bytes_clz, 8) | l_bytes_cls;
}
pub fn unpackSingleApproxB(s_counts_l: u64) u64 {
    const n_bytes_clz: u64 = mach.shrx64(s_counts_l, 8);
    return mach.shrx64(~mach.shrx64(lit.max_bit_u64, s_counts_l), n_bytes_clz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
fn packSingleApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packSingleApproxB(n_bytes);
    return mach.shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
fn unpackSingleApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = builtin.shrY(u64, u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
fn approx(n_bytes: u64) u64 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(n_bytes, n_bytes_clz));
    return reverseApproximateAbove(n_bytes_clz, l_bytes_cls);
}
/// Derives and packs approximation counts.
fn packAlignedApproxB(n_bytes: u64) u16 {
    const n_bytes_pop: u8 = builtin.popcnt(u64, n_bytes);
    const n_bytes_clz: u8 = builtin.tzcnt(u64, n_bytes);
    return builtin.shl(u16, n_bytes_pop, 8) | builtin.sub(u16, 64, (n_bytes_pop + n_bytes_clz));
}
/// Unpacks approximation counts and computes the approximation.
fn unpackAlignedApproxB(s_counts_l: u16) u64 {
    const n_bytes_pop: u8 = builtin.maskZ(u16, u8, s_counts_l);
    const n_bytes_ctz: u8 = mach.shr16T(u8, s_counts_l, 8);
    return mach.shlx64(mach.shlx64(1, n_bytes_pop) -% 1, n_bytes_ctz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
fn packAlignedApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packAlignedApproxB(n_bytes);
    return mach.shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
pub fn unpackAlignedApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = builtin.shrY(u64, u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
pub fn alignedApprox(n_bytes: u64) u64 {
    const n_bytes_pop: u8 = builtin.popcnt(u64, n_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    return mach.shlx64(mach.shlx64(1, n_bytes_pop) -% 1, 64 -% (n_bytes_pop + n_bytes_clz));
}
fn reverseApproximateAbove(n_bytes_clz: u8, l_bytes_cls: u8) u64 {
    return mach.shrx64(~builtin.shr(u64, lit.max_bit_u64, l_bytes_cls), n_bytes_clz);
}
fn reverseApproximateBelow(m_bytes_clz: u8, o_bytes_cls: u8) u64 {
    return mach.shrx64(~builtin.shr(u64, lit.max_bit_u64, o_bytes_cls -% 1), m_bytes_clz) +% 1;
}
// The following functions require 32 bits total.
fn packDouble(l_bytes_clz: u8, l_bytes_cls: u8, m_bytes_clz: u8, m_bytes_cls: u8) u32 {
    const s_lb_counts: u16 = builtin.pack16(l_bytes_clz, l_bytes_cls);
    const s_ub_counts: u16 = builtin.pack16(m_bytes_clz, m_bytes_cls -% 1);
    return builtin.pack32(s_lb_counts, s_ub_counts);
}
fn unpackDouble(l_bytes_clz: u8, l_bytes_ctz: u64, m_bytes_clz: u8, o_bytes_ctz: u64) u64 {
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, l_bytes_clz);
    const p_bytes: u64 = mach.shrx64(o_bytes_ctz, m_bytes_clz);
    return mach.sub64(o_bytes, p_bytes);
}
pub fn partialPackSingleApprox(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(n_bytes, n_bytes_clz));
    const s_lb_counts: u16 = builtin.pack16(n_bytes_clz, l_bytes_cls);
    return s_lb_counts;
}
pub fn partialUnpackSingleApprox(s_lb_counts: u16) u64 {
    const n_bytes_clz: u8 = mach.mask8H(s_lb_counts);
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, n_bytes_clz);
    return o_bytes;
}
pub fn partialPackDoubleApprox(n_bytes: u64, o_bytes: u64) u16 {
    const m_bytes: u64 = mach.sub64(o_bytes, n_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(m_bytes, m_bytes_clz));
    const s_ub_counts: u16 = builtin.pack16(m_bytes_clz, m_bytes_cls -% 1);
    return s_ub_counts;
}
pub fn partialUnpackDoubleApprox(o_bytes: u64, s_ub_counts: u16) u64 {
    const o_bytes_cls: u8 = mach.mask8H(s_ub_counts);
    const o_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = mach.shrx64(o_bytes_ctz, o_bytes_cls);
    const s_bytes: u64 = mach.sub64(o_bytes, p_bytes +% 1);
    return s_bytes;
}
pub fn packDoubleApproxB(k_bytes: u64) u32 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~mach.shr64(lit.max_bit_u64, l_bytes_cls);
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, l_bytes_clz);
    const m_bytes: u64 = mach.sub64(o_bytes, k_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(m_bytes, m_bytes_clz));
    return packDouble(l_bytes_clz, l_bytes_cls, m_bytes_clz, m_bytes_cls);
}
/// Unpacks approximation counts and computes the approximation.
pub fn unpackDoubleApproxB(s_lu_counts: u32) u64 {
    const s_lb_counts: u32 = mach.shr32(s_lu_counts, 16);
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_lb_counts);
    const m_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_lu_counts);
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, mach.shr64(s_lb_counts, 8));
    const p_bytes: u64 = mach.shrx64(m_bytes_ctz, mach.shr64(s_lu_counts, 8));
    return builtin.subWrap(u64, p_bytes, o_bytes +% 1);
}
pub fn unpackDoubleApproxHA(s_lb_counts: u64) u64 {
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, mach.shr64(s_lb_counts, 8));
    return o_bytes -% 1;
}
pub fn unpackDoubleApproxHB(s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = mach.shrx64(m_bytes_ctz, mach.shr64(s_ub_counts, 8));
    return p_bytes;
}
pub fn unpackDoubleApproxC(s_lb_counts: u64, s_ub_counts: u64) u64 {
    return mach.sub64(unpackDoubleApproxHA(s_lb_counts), unpackDoubleApproxHB(s_ub_counts));
}
pub fn unpackDoubleApproxH(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, mach.shrx64(s_ub_counts, 48));
    const p_bytes: u64 = mach.shrx64(m_bytes_ctz, mach.shr64(s_ub_counts, 56));
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, mach.shrx64(s_lb_counts, 48));
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, mach.shr64(s_lb_counts, 56));
    return mach.sub64(o_bytes -% 1, p_bytes);
}
pub fn unpackDoubleApproxS(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = mach.shrx64(m_bytes_ctz, mach.shr64(s_ub_counts, 8));
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = mach.shrx64(l_bytes_ctz, mach.shr64(s_lb_counts, 8));
    return mach.sub64(o_bytes -% 1, p_bytes);
}
pub fn approxDouble(k_bytes: u64) u64 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, l_bytes_cls);
    const m_bytes: u64 = mach.shrx64(l_bytes_ctz, l_bytes_clz);
    const n_bytes: u64 = mach.sub64(m_bytes, k_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const n_bytes_cls: u8 = builtin.lzcnt(u64, ~mach.shlx64(n_bytes, n_bytes_clz)) -% 1;
    const n_bytes_ctz: u64 = ~mach.shrx64(lit.max_bit_u64, n_bytes_cls);
    return mach.sub64(m_bytes, mach.shrx64(n_bytes_ctz, n_bytes_clz) +% 1);
}
