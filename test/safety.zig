const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

const safety = @import("../top/safety.zig");
const just_compile: bool = true;

var rng: zl.file.DeviceRandomBytes(4096) = .{};

inline fn readOne(comptime T: type) T {
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    } else {
        return rng.readOne(T);
    }
}

fn intWillBeMisaligned(comptime T: type, alignment: T) T {
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    return (alignment *% 2) +% (alignment / 2);
}
fn intWillBelow(comptime T: type, val: *T) T {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    return @max(1, val.* / 2);
}
fn intSubWillOverflow(comptime T: type, val: *T) T {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    var ret: T = 0;
    var res = @subWithOverflow(val.*, ret);
    while (res[1] == 0) : (res = @subWithOverflow(val.*, ret)) {
        val.* = rng.readOne(T);
        ret = @bitCast(@abs((zl.math.extrema(T).min -% val.*) *| 2));
    }
    return ret;
}
fn intAddWillOverflow(comptime T: type, val: *T) T {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    const x = zl.math.extrema(T);
    return (x.max -% val.*) *| 2;
}
fn intMulWillOverflow(comptime T: type, val: *T) T {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    var ret: T = rng.readOne(T);
    while (@mulWithOverflow(val.*, ret)[1] == 0) {
        val.* = @max(rng.readOne(T), 1);
        ret = @divTrunc(zl.math.extrema(T).max, val.*) +% 1;
    }
    return ret;
}
fn divWillBeInexact(comptime T: type, val: *T) T {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    var ret: T = 1;
    while ((val / @max(ret, 1)) * ret == val.*) {
        ret += 1;
    }
    return ret;
}
fn shrWillShiftOutBits(comptime T: type, val: *T) zl.builtin.ShiftAmount(T) {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    const min_shift_amt = @ctz(val.*) +| 1;
    return @intCast(min_shift_amt +% (@bitSizeOf(T) -| min_shift_amt) / 2);
}
fn shlWillShiftOutBits(comptime T: type, val: *T) zl.builtin.ShiftAmount(T) {
    @setRuntimeSafety(false);
    if (just_compile) {
        return zl.mem.unstable(T, 0);
    }
    const min_shift_amt = @clz(val.*) +| 1;
    return @intCast(min_shift_amt +% (@bitSizeOf(T) -| min_shift_amt) / 2);
}
fn causeAccessInactiveField() void {
    safety.panic(.{ .access_inactive_field = .{ .expected = "a", .found = "b" } }, @errorReturnTrace(), @returnAddress());
}
fn causeOutOfBounds() void {
    safety.panic(.{ .access_out_of_bounds = .{ .index = 256, .length = 128 } }, @errorReturnTrace(), @returnAddress());
}
fn causeOutOfOrder() void {
    var start: usize = readOne(usize);
    const finish: usize = intWillBelow(usize, &start);
    safety.panic(.{ .access_out_of_order = .{ .start = start, .finish = finish } }, @errorReturnTrace(), @returnAddress());
}

fn causeMempcyLengthMismatch() void {
    safety.panic(.{ .mismatched_memcpy_lengths = .{ .src_length = 16384, .dest_length = 32768 } }, @errorReturnTrace(), @returnAddress());
}
fn causeForLoopLengthMismatch() void {
    safety.panic(.{ .mismatched_for_loop_lengths = .{ .prev_index = 2, .prev_capture_length = 32768, .next_capture_length = 16384 } }, @errorReturnTrace(), @returnAddress());
}
fn causeCastToMisalignedPointer(comptime T: type) void {
    const alignment: usize = @as(usize, 1) << @max(2, readOne(u4));
    const address: usize = intWillBeMisaligned(usize, alignment);
    safety.panicExtra(.{ .cast_to_pointer_from_invalid = T }, address, @errorReturnTrace(), @returnAddress());
}
fn causeCastTruncatedBits(comptime From: type, comptime To: type) void {
    const x = zl.math.extrema(From);
    safety.panicExtra(.{ .cast_truncated_data = .{ .from = From, .to = To } }, x.max, @errorReturnTrace(), @returnAddress());
}
fn causeCastToUnsignedFromNegative(comptime From: type, comptime To: type) void {
    const x = zl.math.extrema(From);
    safety.panicExtra(.{ .cast_to_unsigned_from_negative = .{ .from = From, .to = To } }, x.min, @errorReturnTrace(), @returnAddress());
}
fn causeAddWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intAddWillOverflow(T, &a);
    safety.panicExtra(.{ .add_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress());
}
fn causeSubWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intSubWillOverflow(T, &a);
    safety.panicExtra(.{ .sub_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress());
}
fn causeMulWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intMulWillOverflow(T, &a);
    safety.panicExtra(.{ .mul_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress());
}
fn causeShlWithOverflow(comptime T: type) void {
    var x = readOne(T);
    const y = shlWillShiftOutBits(T, &x);
    safety.panicExtra(.{ .shl_overflowed = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress());
}
fn causeShrWithOverflow(comptime T: type) void {
    var x = readOne(T);
    const y = shrWillShiftOutBits(T, &x);
    safety.panicExtra(.{ .shr_overflowed = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress());
}
fn causeDivWithRemainder(comptime T: type) void {
    var x = zl.math.extrema(T);
    const y = divWillBeInexact(T, &x);
    safety.panicExtra(.{ .div_with_remainder = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress());
}
fn causeSentinelMismatch(comptime T: type) void {
    const expected: T = readOne(T);
    safety.panicExtra(
        .{ .mismatched_sentinel = T },
        .{ .expected = expected, .found = readOne(T) },
        @errorReturnTrace(),
        @returnAddress(),
    );
}
fn causeNonScalarSentinelMismatch(comptime T: type, expected: T, found: T) void {
    safety.panicExtra(
        .{ .mismatched_non_scalar_sentinel = T },
        .{ .expected = expected, .found = found },
        @errorReturnTrace(),
        @returnAddress(),
    );
}
fn causeMemcpyArgumentsAlias() void {
    safety.panic(.{ .memcpy_arguments_alias = .{
        .dest_start = 0x40000000,
        .dest_finish = 0x41000000,
        .src_start = 0x40500000,
        .src_finish = 0x41000000,
    } }, @errorReturnTrace(), @returnAddress());
}
fn causeCastToEnumFromInvalidInteger(comptime Enum: type) void {
    safety.panicExtra(.{ .cast_to_enum_from_invalid = Enum }, 16384, @errorReturnTrace(), @returnAddress());
}
fn causeCastToErrorFromInvalidInteger(comptime Error: type) void {
    safety.panicExtra(.{ .cast_to_error_from_invalid = Error }, 32768, @errorReturnTrace(), @returnAddress());
}
pub fn main() void {
    causeAccessInactiveField();
    causeOutOfBounds();
    causeOutOfOrder();
    causeMemcpyArgumentsAlias();
    causeMempcyLengthMismatch();
    causeForLoopLengthMismatch();
    inline for (.{ usize, isize }) |T| {
        causeCastToMisalignedPointer(T);
        causeAddWithOverflow(T);
        causeSubWithOverflow(T);
        causeMulWithOverflow(T);
        causeShlWithOverflow(T);
        causeShrWithOverflow(T);
        causeSentinelMismatch(T);
    }
    causeCastTruncatedBits(u8, u3);
    causeCastToUnsignedFromNegative(i32, u32);
    causeNonScalarSentinelMismatch(struct { a: u64, b: u32 }, .{ .a = 1, .b = 2 }, .{ .a = 3, .b = 4 });
    causeCastToErrorFromInvalidInteger(error{ A, B, C, D, E });
    causeCastToEnumFromInvalidInteger(enum(u16) { A, B, C, D, E = 32768 });
}
//