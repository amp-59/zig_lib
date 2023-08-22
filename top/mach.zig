pub const RegisterState = extern struct {
    pub const offset: comptime_int = 40;
    r8: usize,
    r9: usize,
    r10: usize,
    r11: usize,
    r12: usize,
    r13: usize,
    r14: usize,
    r15: usize,
    rdi: usize,
    rsi: usize,
    rbp: usize,
    rbx: usize,
    rdx: usize,
    rax: usize,
    rcx: usize,
    rsp: usize,
    rip: usize,
    eflags: usize,
    cs: u16,
    gs: u16,
    fs: u16,
    pad0: u16 = undefined,
    err: usize,
    trapno: usize,
    oldmask: usize,
    cr2: usize,
};
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
// The following operations are distinct from similarly named in builtin by
// truncating instead of casting. This matches the machine behaviour more
// closely. There is no need to forward these to a generic function to ask meta
// what the shift_amt types are; we know them already and want to save the
// compiler the extra work.
pub inline fn shl64(value: u64, shift_amt: u64) u64 {
    return value << @truncate(shift_amt);
}
pub inline fn shl32(value: u32, shift_amt: u32) u32 {
    return value << @truncate(shift_amt);
}
pub inline fn shl16(value: u16, shift_amt: u16) u16 {
    return value << @truncate(shift_amt);
}
pub inline fn shl8(value: u8, shift_amt: u8) u8 {
    return value << @truncate(shift_amt);
}
pub inline fn shr64(value: u64, shift_amt: u64) u64 {
    return value >> @truncate(shift_amt);
}
pub inline fn shr32(value: u32, shift_amt: u32) u32 {
    return value >> @truncate(shift_amt);
}
pub inline fn shr16(value: u16, shift_amt: u16) u16 {
    return value >> @truncate(shift_amt);
}
pub inline fn shr8(value: u8, shift_amt: u8) u8 {
    return value >> @truncate(shift_amt);
}
pub inline fn shl64T(comptime T: type, value: u64, shift_amt: u64) T {
    return @as(T, @truncate(value << @truncate(shift_amt)));
}
pub inline fn shl32T(comptime T: type, value: u32, shift_amt: u32) T {
    return @as(T, @truncate(value << @truncate(shift_amt)));
}
pub inline fn shl16T(comptime T: type, value: u16, shift_amt: u16) T {
    return @as(T, @truncate(value << @truncate(shift_amt)));
}
pub inline fn shl8T(comptime T: type, value: u8, shift_amt: u8) T {
    return @as(T, @truncate(value << @truncate(shift_amt)));
}
pub inline fn shr64T(comptime T: type, value: u64, shift_amt: u64) T {
    return @as(T, @truncate(value >> @truncate(shift_amt)));
}
pub inline fn shr32T(comptime T: type, value: u32, shift_amt: u16) T {
    return @as(T, @truncate(value >> @truncate(shift_amt)));
}
pub inline fn shr16T(comptime T: type, value: u16, shift_amt: u16) T {
    return @as(T, @truncate(value >> @truncate(shift_amt)));
}
pub inline fn shr8T(comptime T: type, value: u8, shift_amt: u8) T {
    return @as(T, @truncate(value >> @truncate(shift_amt)));
}
pub inline fn shr64TM(comptime T: type, value: u64, shift_amt: u64, comptime pop_count: comptime_int) T {
    return @as(T, @truncate(value >> @truncate(shift_amt))) & ((1 << pop_count) -% 1);
}
pub inline fn shr32TM(comptime T: type, value: u32, shift_amt: u32, comptime pop_count: comptime_int) T {
    return @as(T, @truncate(value >> @truncate(shift_amt))) & ((1 << pop_count) -% 1);
}
pub inline fn shr16TM(comptime T: type, value: u16, shift_amt: u16, comptime pop_count: comptime_int) T {
    return @as(T, @truncate(value >> @truncate(shift_amt))) & ((1 << pop_count) -% 1);
}
pub inline fn shr8TM(comptime T: type, value: u8, shift_amt: u8, comptime pop_count: comptime_int) T {
    return @as(T, @truncate(value >> @truncate(shift_amt))) & ((1 << pop_count) -% 1);
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
// Unused, but potentially useful for testing.
pub const generic = struct {
    pub inline fn sub(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 -% arg2) {
        return arg1 -% arg2;
    }
    pub inline fn add(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 +% arg2) {
        return arg1 +% arg2;
    }
    pub inline fn mul(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 *% arg2) {
        return arg1 *% arg2;
    }
    pub inline fn div(arg1: anytype, arg2: @TypeOf(arg1)) @TypeOf(arg1 / arg2) {
        return arg1 / arg2;
    }
};
pub inline fn sub64(arg1: u64, arg2: u64) u64 {
    return arg1 -% arg2;
}
pub inline fn mul64(arg1: u64, arg2: u64) u64 {
    return arg1 *% arg2;
}
pub inline fn add64(arg1: u64, arg2: u64) u64 {
    return arg1 +% arg2;
}
pub inline fn divT64(arg1: u64, arg2: u64) u64 {
    return arg1 / arg2;
}
pub inline fn sub32(arg1: u32, arg2: u32) u32 {
    return arg1 -% arg2;
}
pub inline fn mul32(arg1: u32, arg2: u32) u32 {
    return arg1 *% arg2;
}
pub inline fn add32(arg1: u32, arg2: u32) u32 {
    return arg1 +% arg2;
}
pub inline fn divT32(arg1: u32, arg2: u32) u32 {
    return arg1 / arg2;
}
pub inline fn sub16(arg1: u16, arg2: u16) u16 {
    return arg1 -% arg2;
}
pub inline fn mul16(arg1: u16, arg2: u16) u16 {
    return arg1 *% arg2;
}
pub inline fn add16(arg1: u16, arg2: u16) u16 {
    return arg1 +% arg2;
}
pub inline fn divT16(arg1: u16, arg2: u16) u16 {
    return arg1 / arg2;
}
pub inline fn sub8(arg1: u8, arg2: u8) u8 {
    return arg1 -% arg2;
}
pub inline fn mul8(arg1: u8, arg2: u8) u8 {
    return arg1 *% arg2;
}
pub inline fn add8(arg1: u8, arg2: u8) u8 {
    return arg1 +% arg2;
}
pub inline fn divT8(arg1: u8, arg2: u8) u8 {
    return arg1 / arg2;
}
/// arg3 +% (arg1 *% arg2)
pub inline fn mulAdd64(arg1: u64, arg2: u64, arg3: u64) u64 {
    return add64(mul64(arg1, arg2), arg3);
}
/// arg3 +% (arg1 *% arg2)
pub inline fn mulAdd32(arg1: u32, arg2: u32, arg3: u32) u32 {
    return add32(mul32(arg1, arg2), arg3);
}
/// arg3 +% (arg1 *% arg2)
pub inline fn mulAdd16(arg1: u16, arg2: u16, arg3: u16) u16 {
    return add16(mul16(arg1, arg2), arg3);
}
/// arg3 +% (arg1 *% arg2)
pub inline fn mulAdd8(arg1: u8, arg2: u8, arg3: u8) u8 {
    return add8(mul8(arg1, arg2), arg3);
}
/// arg3 -% (arg1 *% arg2)
pub inline fn mulSub64(arg1: u64, arg2: u64, arg3: u64) u64 {
    return sub64(arg3, mul64(arg1, arg2));
}
/// arg3 -% (arg1 *% arg2)
pub inline fn mulSub32(arg1: u32, arg2: u32, arg3: u32) u32 {
    return sub32(arg3, mul32(arg1, arg2));
}
/// arg3 -% (arg1 *% arg2)
pub inline fn mulSub16(arg1: u16, arg2: u16, arg3: u16) u16 {
    return sub16(arg3, mul16(arg1, arg2));
}
/// arg3 -% (arg1 *% arg2)
pub inline fn mulSub8(arg1: u8, arg2: u8, arg3: u8) u8 {
    return sub8(arg3, mul8(arg1, arg2));
}
pub inline fn shlOr64(arg1: u64, arg2: u64, arg3: u64) u64 {
    return or64(shl64(arg1, arg2), arg3);
}
pub inline fn shlOr32(arg1: u32, arg2: u32, arg3: u32) u32 {
    return or32(shl32(arg1, arg2), arg3);
}
pub inline fn shlOr16(arg1: u16, arg2: u16, arg3: u16) u16 {
    return or16(shl16(arg1, arg2), arg3);
}
pub inline fn shlOr8(arg1: u8, arg2: u8, arg3: u8) u8 {
    return or8(shl8(arg1, arg2), arg3);
}
pub inline fn subOr64(arg1: u64, arg2: u64, arg3: u64) u64 {
    return or64(sub64(arg1, arg2), arg3);
}
pub inline fn subOr32(arg1: u32, arg2: u32, arg3: u32) u32 {
    return or32(sub32(arg1, arg2), arg3);
}
pub inline fn subOr16(arg1: u16, arg2: u16, arg3: u16) u16 {
    return or16(sub16(arg1, arg2), arg3);
}
pub inline fn subOr8(arg1: u8, arg2: u8, arg3: u8) u8 {
    return or8(sub8(arg1, arg2), arg3);
}
pub inline fn subEqu64(arg1: *u64, arg2: u64) void {
    arg1.* = sub64(arg1.*, arg2);
}
pub inline fn mulEqu64(arg1: *u64, arg2: u64) void {
    arg1.* = mul64(arg1.*, arg2);
}
pub inline fn addEqu64(arg1: *u64, arg2: u64) void {
    arg1.* = add64(arg1.*, arg2);
}
pub inline fn divTEqu64(arg1: *u64, arg2: u64) void {
    arg1.* = divT64(arg1.*, arg2);
}
pub inline fn subEqu32(arg1: *u32, arg2: u32) void {
    arg1.* = sub32(arg1.*, arg2);
}
pub inline fn mulEqu32(arg1: *u32, arg2: u32) void {
    arg1.* = mul32(arg1.*, arg2);
}
pub inline fn addEqu32(arg1: *u32, arg2: u32) void {
    arg1.* = add32(arg1.*, arg2);
}
pub inline fn divTEqu32(arg1: *u32, arg2: u32) void {
    arg1.* = divT32(arg1.*, arg2);
}
pub inline fn subEqu16(arg1: *u16, arg2: u16) void {
    arg1.* = sub16(arg1.*, arg2);
}
pub inline fn mulEqu16(arg1: *u16, arg2: u16) void {
    arg1.* = mul16(arg1.*, arg2);
}
pub inline fn addEqu16(arg1: *u16, arg2: u16) void {
    arg1.* = add16(arg1.*, arg2);
}
pub inline fn divTEqu16(arg1: *u16, arg2: u16) void {
    arg1.* = divT16(arg1.*, arg2);
}
pub inline fn subEqu8(arg1: *u8, arg2: u8) void {
    arg1.* = sub8(arg1.*, arg2);
}
pub inline fn mulEqu8(arg1: *u8, arg2: u8) void {
    arg1.* = mul8(arg1.*, arg2);
}
pub inline fn addEqu8(arg1: *u8, arg2: u8) void {
    arg1.* = add8(arg1.*, arg2);
}
pub inline fn divTEqu8(arg1: *u8, arg2: u8) void {
    arg1.* = divT8(arg1.*, arg2);
}
pub inline fn mulAddEqu64(arg1: *u64, arg2: u64, arg3: u64) void {
    arg1.* = add64(mul64(arg1.*, arg2), arg3);
}
pub inline fn mulAddEqu32(arg1: *u32, arg2: u32, arg3: u32) void {
    arg1.* = add32(mul32(arg1.*, arg2), arg3);
}
pub inline fn mulAddEqu16(arg1: *u16, arg2: u16, arg3: u16) void {
    arg1.* = add16(mul16(arg1.*, arg2), arg3);
}
pub inline fn mulAddEqu8(arg1: *u8, arg2: u8, arg3: u8) void {
    arg1.* = add8(mul8(arg1.*, arg2), arg3);
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
pub inline fn and16(arg1: u16, arg2: u16) u16 {
    return @"and"(u16, arg1, arg2);
}
pub inline fn andn16(arg1: u16, arg2: u16) u16 {
    return @"and"(u16, arg1, ~arg2);
}
pub inline fn or16(arg1: u16, arg2: u16) u16 {
    return @"or"(u16, arg1, arg2);
}
pub inline fn orn16(arg1: u16, arg2: u16) u16 {
    return @"or"(u16, arg1, ~arg2);
}
pub inline fn xor16(arg1: u16, arg2: u16) u16 {
    return xor(u16, arg1, arg2);
}
pub inline fn and8(arg1: u8, arg2: u8) u8 {
    return @"and"(u8, arg1, arg2);
}
pub inline fn andn8(arg1: u8, arg2: u8) u8 {
    return @"and"(u8, arg1, ~arg2);
}
pub inline fn or8(arg1: u8, arg2: u8) u8 {
    return @"or"(u8, arg1, arg2);
}
pub inline fn orn8(arg1: u8, arg2: u8) u8 {
    return @"or"(u8, arg1, ~arg2);
}
pub inline fn xor8(arg1: u8, arg2: u8) u8 {
    return xor(u8, arg1, arg2);
}
pub fn alignA4096(value: usize) usize {
    return (value +% @as(usize, 4095)) & ~@as(usize, 4095);
}
pub fn alignB4096(value: usize) usize {
    return value & ~@as(usize, 4095);
}
pub inline fn alignA(value: anytype, alignment: @TypeOf(value)) @TypeOf(value) {
    const mask: @TypeOf(value) = alignment -% 1;
    return (value +% mask) & ~mask;
}
pub inline fn alignB(value: anytype, alignment: @TypeOf(value)) @TypeOf(value) {
    const mask: @TypeOf(value) = alignment -% 1;
    return value & ~mask;
}
pub inline fn alignA64(value: u64, alignment: u64) u64 {
    const mask: u64 = alignment -% 1;
    return (value +% mask) & ~mask;
}
pub inline fn alignB64(value: u64, alignment: u64) u64 {
    const mask: u64 = alignment -% 1;
    return value & ~mask;
}
pub fn halfMask64(pop_count: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @as(u6, @truncate(pop_count));
    const int_max_mask: u64 = ~@as(u64, 0);
    const int_sub_mask: u64 = @as(u64, @bitCast(~(iunit << popcnt_shl)));
    return cmov64(pop_count == 64, int_max_mask, int_sub_mask);
}
pub fn bitMask64(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @as(u6, @truncate(pop_count));
    const tzcnt_shl: u6 = @as(u6, @truncate(shift_amt));
    const int_max_mask: u64 = ~@as(u64, 0);
    const int_sub_mask: u64 = @as(u64, @bitCast(~(iunit << popcnt_shl) << tzcnt_shl));
    return cmov64(pop_count == 64, int_max_mask, int_sub_mask);
}
pub fn bitMask64NonZero(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = @as(i64, -1 << 1);
    const popcnt_shl: u6 = @as(u6, @truncate(pop_count - 1));
    const tzcnt_shl: u6 = @as(u6, @truncate(shift_amt));
    return @as(u64, @bitCast(~(iunit << popcnt_shl) << tzcnt_shl));
}
pub fn halfMask64NonMax(pop_count: u8) u64 {
    const iunit: i64 = -1;
    const popcnt_shl: u6 = @as(u6, @truncate(pop_count));
    return @as(u64, @bitCast(~(iunit << popcnt_shl)));
}
pub fn bitMask64NonMax(pop_count: u8, shift_amt: u8) u64 {
    const iunit: i64 = @as(i64, -1);
    const popcnt_shl: u6 = @as(u6, @truncate(pop_count));
    const tzcnt_shl: u6 = @as(u6, @truncate(shift_amt));
    return @as(u64, @bitCast(~(iunit << popcnt_shl) << tzcnt_shl));
}
pub inline fn shiftRightTruncate(
    comptime T: type,
    comptime U: type,
    value: T,
    comptime shift_amt: comptime_int,
) U {
    return @as(U, @truncate(value >> shift_amt));
}
pub inline fn shiftRightMaskTruncate(
    comptime T: type,
    comptime U: type,
    value: T,
    comptime shift_amt: comptime_int,
    comptime pop_count: comptime_int,
) U {
    return @as(U, @truncate(value >> shift_amt)) & ((@as(U, 1) << pop_count) -% 1);
}
pub inline fn mask32(value: u64) u32 {
    return @as(u32, @truncate(value));
}
pub inline fn mask16(value: u64) u16 {
    return @as(u16, @truncate(value));
}
pub inline fn mask8L(value: u64) u8 {
    return @as(u8, @truncate(value));
}
pub inline fn mask8H(value: u64) u8 {
    return @as(u8, @truncate(value >> 8));
}
inline fn shlx(comptime T: type, value: T, shift_amt: T) T {
    if (@inComptime()) {
        return value << shift_amt;
    }
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
    if (@inComptime()) {
        return value >> shift_amt;
    }
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
const is_small = @import("builtin").mode == .ReleaseSmall;
const is_fast = @import("builtin").mode == .ReleaseFast;
const is_debug = @import("builtin").mode == .Debug;
const is_test = @import("builtin").is_test;

pub extern fn memset(dest: [*]u8, value: u8, count: usize) void;
pub extern fn memcpy(noalias dest: [*]u8, noalias src: [*]const u8, len: u64) void;
pub const addrcpy = @as(*const fn (dest: usize, src: usize, len: usize) void, @ptrCast(&memcpy));

const __0 = struct {
    inline fn memcpy1(noalias dest: [*]u8, noalias src: [*]const u8, len: u64) void {
        @memcpy(dest[0..len], src[0..len]);
    }
    inline fn memset1(dest: [*]u8, value: u8, count: usize) void {
        @memset(dest[0..count], value);
    }
};
comptime {
    asm (
        \\.intel_syntax noprefix
        \\memset:
        \\  mov     eax, esi
        \\  mov     rcx, rdx
        \\  rep     stosb byte ptr es:[rdi], al
        \\  ret
    );
}
comptime {
    asm (
        \\.intel_syntax noprefix
        \\memcpy:
        \\  mov     rcx, rdx
        \\  rep     movsb byte ptr es:[rdi], byte ptr [rsi]
        \\  ret
    );
}
pub extern fn memmove(noalias dest: [*]u8, noalias src: [*]const u8, len: u64) callconv(.C) void;
comptime {
    asm (
        \\.intel_syntax noprefix
        \\memmove:
        \\  mov     rcx, rdx
        \\  rep     movsb byte ptr es:[rdi], byte ptr [rsi]
        \\  ret
    );
}
pub inline fn testEqualMany8(l_values: []const u8, r_values: []const u8) bool {
    if (@inComptime()) {
        if (l_values.len != r_values.len) {
            return false;
        }
        if (l_values.ptr == r_values.ptr) {
            return true;
        }
        for (l_values, r_values) |l, r| {
            if (l != r) {
                return false;
            }
        }
        return true;
    } else {
        return _0.asmTestEqualMany8(l_values.ptr, l_values.len, r_values.ptr, r_values.len);
    }
}
pub inline fn memcpyMulti(noalias dest: [*]u8, src: []const []const u8) u64 {
    if (@inComptime()) {
        var len: u64 = 0;
        for (src) |bytes| {
            for (bytes) |byte| {
                dest[len] = byte;
                len +%= 1;
            }
        }
        return len;
    } else {
        return _1.asmMemcpyMulti(dest, src.ptr, src.len);
    }
}
pub fn manyToSlice80(str: [*]u8) [:0]u8 {
    @setRuntimeSafety(false);
    return str[0.._3.strlen(str) :0];
}
pub fn assert(cond: bool, msg: []const u8) void {
    _2.asmAssert(cond, msg.ptr, msg.len);
}
const _0 = struct {
    extern fn asmTestEqualMany8(arg1: [*]const u8, arg1_len: u64, arg2: [*]const u8, arg2_len: u64) callconv(.C) bool;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmTestEqualMany8:
            \\  cmp     rsi, rcx
            \\  jne     2f
            \\  mov     al, 1f
            \\  cmp     rdi, rdx
            \\  je      1f
            \\  test    rsi, rsi
            \\  je      1f
            \\  dec     rsi
            \\  xor     ecx, ecx
            \\0:
            \\  movzx   eax, byte ptr [rdi + rcx]
            \\  cmp     al,  byte ptr [rdx + rcx]
            \\  sete    al
            \\  jne     1f
            \\  lea     r8,  [rcx + 1]
            \\  cmp     rsi, rcx
            \\  mov     rcx, r8
            \\  jne     0b
            \\1:
            \\  ret
            \\2:
            \\  xor    eax,  eax
            \\  ret
        );
    }
};
const _1 = struct {
    extern fn asmMemcpyMulti(noalias dest: [*]u8, src: [*]const []const u8, len: u64) callconv(.C) u64;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmMemcpyMulti:
            \\  xor     r8d, r8d
            \\  xor     ecx, ecx
            \\  cmp     r8, rdx
            \\  jne     9f
            \\  mov     rax, rcx
            \\  ret
            \\9:
            \\  push    rbx
            \\5:
            \\  mov     r10, qword ptr [rsi]
            \\  mov     r9, qword ptr [rsi + 8]
            \\  xor     eax, eax
            \\  lea     r11, [rdi + rcx]
            \\3:
            \\  cmp     rax, r9
            \\  je      11f
            \\  mov     bl, byte ptr [r10 + rax]
            \\  mov     byte ptr [r11 + rax], bl
            \\  inc     rax
            \\  jmp     3b
            \\11:
            \\  inc     r8
            \\  add     rcx, rax
            \\  add     rsi, 16
            \\  cmp     r8, rdx
            \\  jne     5b
            \\  mov     rax, rcx
            \\  pop     rbx
            \\  ret
        );
    }
};
const _2 = struct {
    extern fn asmAssert(b: bool, buf_ptr: [*]const u8, buf_len: u64) callconv(.C) void;
    comptime {
        asm (
            \\.intel_syntax noprefix
            \\asmAssert:
            \\  test    edi, edi
            \\  jne     0f
            \\  mov     eax, 1
            \\  mov     edi, 2
            \\  syscall # write
            \\  mov     eax, 60
            \\  mov     edi, 2
            \\  syscall # exit
            \\0:
            \\  ret
        );
    }
};
const _3 = struct {
    extern fn strlen(str: [*]u8) callconv(.C) u64;
    comptime {
        asm (
            \\  .intel_syntax noprefix
            \\strlen:
            \\  mov     rax, -1
            \\0:
            \\  cmp     byte ptr [rdi + rax + 1], 0
            \\  lea     rax, [rax + 1]
            \\  jne     0b
            \\  ret
            \\
        );
    }
};
extern fn __zig_probe_stack() callconv(.C) void;
comptime {
    asm (
        \\__zig_probe_stack:
        \\ret
    );
}
