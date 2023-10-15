const tab = @import("./tab.zig");
const math = @import("./math.zig");
const bits = @import("./bits.zig");
const builtin = @import("./builtin.zig");
/// Derives and packs approximation counts.
fn packSingleApproxB(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(n_bytes, n_bytes_clz));
    return builtin.shl(u16, n_bytes_clz, 8) | l_bytes_cls;
}
pub fn unpackSingleApproxB(s_counts_l: u64) u64 {
    const n_bytes_clz: u64 = bits.shrx64(s_counts_l, 8);
    return bits.shrx64(~bits.shrx64(tab.max_bit_u64, s_counts_l), n_bytes_clz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
fn packSingleApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packSingleApproxB(n_bytes);
    return bits.shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
fn unpackSingleApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = builtin.shrY(u64, u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
/// Creates a 12-bit approximation of a 64-bit integer. Accuracy is better near
/// binary powers.
pub fn approx(n_bytes: u64) u64 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(n_bytes, n_bytes_clz));
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
    const n_bytes_ctz: u8 = bits.shr16T(u8, s_counts_l, 8);
    return bits.shlx64(bits.shlx64(1, n_bytes_pop) -% 1, n_bytes_ctz);
}
/// Derives, packs, and shifts the approximation counts, as required by the
/// container technique.
fn packAlignedApproxA(n_bytes: u64) u64 {
    const s_counts_l: u16 = packAlignedApproxB(n_bytes);
    return bits.shlx64(s_counts_l, 48);
}
/// Shifts and unpacks the approximation counts, and computes the approximation.
pub fn unpackAlignedApproxA(s_counts_h: u64) u64 {
    const s_counts_l: u16 = bits.shr64T(u16, s_counts_h, 48);
    return unpackSingleApproxB(s_counts_l);
}
pub fn alignedApprox(n_bytes: u64) u64 {
    const n_bytes_pop: u8 = builtin.popcnt(u64, n_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    return bits.shlx64(bits.shlx64(1, n_bytes_pop) -% 1, 64 -% (n_bytes_pop + n_bytes_clz));
}
fn reverseApproximateAbove(n_bytes_clz: u8, l_bytes_cls: u8) u64 {
    return bits.shrx64(~builtin.shr(u64, tab.max_bit_u64, l_bytes_cls), n_bytes_clz);
}
fn reverseApproximateBelow(m_bytes_clz: u8, o_bytes_cls: u8) u64 {
    return bits.shrx64(~builtin.shr(u64, tab.max_bit_u64, o_bytes_cls -% 1), m_bytes_clz) +% 1;
}
// The compiler will optimise various success depending on the word size. Doing
// manual shifts with u8 is much better, whereas bit-casting from a struct with
// u16 is much better.
pub fn pack16(h: u16, l: u8) u16 {
    return h << 8 | l;
}
// Defined here to prevent stage2 segmentation fault
const U32 = packed struct { h: u16, l: u16 };
pub fn pack32(h: u16, l: u16) u32 {
    return @as(u32, @bitCast(U32{ .h = h, .l = l }));
}
// Defined here to prevent stage2 segmentation fault
const U64 = packed struct { h: u32, l: u32 };
pub fn pack64(h: u32, l: u32) u64 {
    return @as(u64, @bitCast(U64{ .h = h, .l = l }));
}
// The following functions require 32 bits total.
fn packDouble(l_bytes_clz: u8, l_bytes_cls: u8, m_bytes_clz: u8, m_bytes_cls: u8) u32 {
    const s_lb_counts: u16 = pack16(l_bytes_clz, l_bytes_cls);
    const s_ub_counts: u16 = pack16(m_bytes_clz, m_bytes_cls -% 1);
    return pack32(s_lb_counts, s_ub_counts);
}
fn unpackDouble(l_bytes_clz: u8, l_bytes_ctz: u64, m_bytes_clz: u8, o_bytes_ctz: u64) u64 {
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, l_bytes_clz);
    const p_bytes: u64 = bits.shrx64(o_bytes_ctz, m_bytes_clz);
    return math.sub64(o_bytes, p_bytes);
}
pub fn partialPackSingleApprox(n_bytes: u64) u16 {
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(n_bytes, n_bytes_clz));
    const s_lb_counts: u16 = pack16(n_bytes_clz, l_bytes_cls);
    return s_lb_counts;
}
pub fn partialUnpackSingleApprox(s_lb_counts: u16) u64 {
    const n_bytes_clz: u8 = bits.mask8H(s_lb_counts);
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, n_bytes_clz);
    return o_bytes;
}
pub fn partialPackDoubleApprox(n_bytes: u64, o_bytes: u64) u16 {
    const m_bytes: u64 = math.sub64(o_bytes, n_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(m_bytes, m_bytes_clz));
    const s_ub_counts: u16 = pack16(m_bytes_clz, m_bytes_cls -% 1);
    return s_ub_counts;
}
pub fn partialUnpackDoubleApprox(o_bytes: u64, s_ub_counts: u16) u64 {
    const o_bytes_cls: u8 = bits.mask8H(s_ub_counts);
    const o_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = bits.shrx64(o_bytes_ctz, o_bytes_cls);
    const s_bytes: u64 = math.sub64(o_bytes, p_bytes +% 1);
    return s_bytes;
}
pub fn packDoubleApproxB(k_bytes: u64) u32 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~bits.shr64(tab.max_bit_u64, l_bytes_cls);
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, l_bytes_clz);
    const m_bytes: u64 = math.sub64(o_bytes, k_bytes);
    const m_bytes_clz: u8 = builtin.lzcnt(u64, m_bytes);
    const m_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(m_bytes, m_bytes_clz));
    return packDouble(l_bytes_clz, l_bytes_cls, m_bytes_clz, m_bytes_cls);
}
/// Unpacks approximation counts and computes the approximation.
pub fn unpackDoubleApproxB(s_lu_counts: u32) u64 {
    const s_lb_counts: u32 = bits.shr32(s_lu_counts, 16);
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_lb_counts);
    const m_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_lu_counts);
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, bits.shr64(s_lb_counts, 8));
    const p_bytes: u64 = bits.shrx64(m_bytes_ctz, bits.shr64(s_lu_counts, 8));
    return builtin.subWrap(u64, p_bytes, o_bytes +% 1);
}
pub fn unpackDoubleApproxHA(s_lb_counts: u64) u64 {
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, bits.shr64(s_lb_counts, 8));
    return o_bytes -% 1;
}
pub fn unpackDoubleApproxHB(s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = bits.shrx64(m_bytes_ctz, bits.shr64(s_ub_counts, 8));
    return p_bytes;
}
pub fn unpackDoubleApproxC(s_lb_counts: u64, s_ub_counts: u64) u64 {
    return math.sub64(unpackDoubleApproxHA(s_lb_counts), unpackDoubleApproxHB(s_ub_counts));
}
pub fn unpackDoubleApproxH(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, bits.shrx64(s_ub_counts, 48));
    const p_bytes: u64 = bits.shrx64(m_bytes_ctz, bits.shr64(s_ub_counts, 56));
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, bits.shrx64(s_lb_counts, 48));
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, bits.shr64(s_lb_counts, 56));
    return math.sub64(o_bytes -% 1, p_bytes);
}
pub fn unpackDoubleApproxS(s_lb_counts: u64, s_ub_counts: u64) u64 {
    const m_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_ub_counts);
    const p_bytes: u64 = bits.shrx64(m_bytes_ctz, bits.shr64(s_ub_counts, 8));
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, s_lb_counts);
    const o_bytes: u64 = bits.shrx64(l_bytes_ctz, bits.shr64(s_lb_counts, 8));
    return math.sub64(o_bytes -% 1, p_bytes);
}
pub fn approxDouble(k_bytes: u64) u64 {
    const l_bytes_clz: u8 = builtin.lzcnt(u64, k_bytes);
    const l_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(k_bytes, l_bytes_clz));
    const l_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, l_bytes_cls);
    const m_bytes: u64 = bits.shrx64(l_bytes_ctz, l_bytes_clz);
    const n_bytes: u64 = math.sub64(m_bytes, k_bytes);
    const n_bytes_clz: u8 = builtin.lzcnt(u64, n_bytes);
    const n_bytes_cls: u8 = builtin.lzcnt(u64, ~bits.shlx64(n_bytes, n_bytes_clz)) -% 1;
    const n_bytes_ctz: u64 = ~bits.shrx64(tab.max_bit_u64, n_bytes_cls);
    return math.sub64(m_bytes, bits.shrx64(n_bytes_ctz, n_bytes_clz) +% 1);
}
/// Returns true if x is greater than y.
pub fn asc(x: anytype, y: anytype) bool {
    return x > y;
}
/// Return true if x is less than y.
pub fn desc(x: anytype, y: anytype) bool {
    return x < y;
}
/// insert: [524288]u64 = top.time.TimeSpec{ .sec = 27, .nsec = 365636807, }
pub fn insertionSort(comptime T: type, comptime comparison: anytype, values: []T) void {
    @setRuntimeSafety(false);
    var idx: usize = 1;
    while (idx != values.len) : (idx +%= 1) {
        const value: T = values[idx];
        var end: usize = idx -% 1;
        while (end >= 0 and comparison(values[end], value)) : (end -%= 1) {
            values[end +% 1] = values[end];
        }
        values[end +% 1] = value;
    }
}
/// shell: [524288]u64 = top.time.TimeSpec{ .nsec = 568540594, }
pub fn shellSort(comptime T: type, comptime comparison: anytype, values: []T) void {
    @setRuntimeSafety(false);
    var gap: usize = values.len >> 1;
    while (gap != 0) : (gap >>= 1) {
        var idx: usize = gap;
        while (idx != values.len) : (idx +%= 1) {
            var end: usize = idx -% gap;
            while (end < values.len and comparison(values[end], values[end +% gap])) : (end -%= gap) {
                const pos: usize = end +% gap;
                const value: T = values[end];
                values[end] = values[pos];
                values[pos] = value;
            }
        }
    }
}
/// radix: [524288]u64 = top.time.TimeSpec{ .nsec = 86801419, }
pub fn radixSort(allocator: anytype, comptime T: type, values0: []T) void {
    @setRuntimeSafety(false);
    const save: usize = allocator.save();
    defer allocator.restore(save);
    var values1: []T = allocator.allocate(T, values0.len);
    var bit: T = 1;
    while (bit != 0) : (bit <<= 1) {
        var len0: usize = 0;
        var len1: usize = 0;
        for (values0) |value_0| {
            const j: bool = value_0 & bit == bit;
            const t: *T = if (j) &values1[len1] else &values0[len0];
            len0 +%= ~@intFromBool(j);
            len1 +%= @intFromBool(j);
            t.* = value_0;
        }
        for (values1[0..len1]) |value_1| {
            values0[len0] = value_1;
            len0 +%= 1;
        }
    }
}
pub fn isSorted(comptime T: type, comptime comparison: anytype, values: []T) bool {
    @setRuntimeSafety(false);
    if (values.len == 0) {
        return true;
    }
    var idx: usize = 0;
    var prev: T = values[0];
    while (idx != values.len) : (idx +%= 1) {
        const next: T = values[idx];
        if (comparison(prev, next)) {
            return false;
        }
        prev = next;
    }
    return true;
}
