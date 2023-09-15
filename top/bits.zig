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
