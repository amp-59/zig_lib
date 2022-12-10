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

// Sub-registers
pub inline fn mask32(value: u64) u32 {
    return @truncate(u32, value);
}
pub inline fn mask16(value: u64) u16 {
    return @truncate(u16, value);
}
pub inline fn mask8L(value: u64) u8 {
    return @truncate(u8, value);
}
pub inline fn mask8H(value: u64) u8 {
    return @truncate(u8, value >> 8);
}
