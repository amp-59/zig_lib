const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
const version: enum { single, std } = .single;

const safety = switch (version) {
    .single => @import("../top/safety.zig"),
    .std => @import("std").builtin.default,
};
const just_compile: bool = true;

pub const want_stack_traces: bool = false;
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
    const E = enum { a, b };
    switch (version) {
        .single => safety.panic(.accessed_inactive_field, .{ .expected = "a", .found = "b" }, @errorReturnTrace(), @returnAddress()),
        .std => safety.panicInactiveUnionField(E.a, E.b),
    }
}
fn causeAccessOutOfBounds() void {
    var index: usize = readOne(usize);
    const length: usize = readOne(usize);
    switch (version) {
        .single => safety.panic(.accessed_out_of_bounds, .{ .index = index, .length = length }, @errorReturnTrace(), @returnAddress()),
        .std => safety.panicOutOfBounds(index, length),
    }
    switch (version) {
        .single => safety.panic(.accessed_out_of_bounds, .{ .index = 16, .length = 8 }, @errorReturnTrace(), @returnAddress()),
        .std => safety.panicOutOfBounds(16, 8),
    }
}
fn causeAccessOutOfOrder() void {
    var start: usize = readOne(usize);
    const finish: usize = intWillBelow(usize, &start);
    switch (version) {
        .single => safety.panic(.accessed_out_of_order, .{ .start = start, .finish = finish }, @errorReturnTrace(), @returnAddress()),
        .std => safety.panicStartGreaterThanEnd(start, finish),
    }
}
fn causeMempcyLengthMismatch() void {
    switch (version) {
        .single => safety.panic(.memcpy_argument_lengths_mismatched, .{ .src_len = 16384, .dest_len = 32768 }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeForLoopLengthMismatch() void {
    switch (version) {
        .single => safety.panic(.for_loop_capture_lengths_mismatched, .{ .prev_index = 2, .prev_len = 32768, .next_len = 16384 }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastToMisalignedPointer(comptime T: type) void {
    const alignment: usize = @as(usize, 1) << @max(2, readOne(u4));
    const address: usize = intWillBeMisaligned(usize, alignment);
    switch (version) {
        .single => safety.panic(.{ .cast_to_pointer_from_invalid = T }, address, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastTruncatedBits(comptime From: type, comptime To: type) void {
    const x = zl.math.extrema(From);
    switch (version) {
        .single => safety.panic(.{ .cast_truncated_data = .{ .from = From, .to = To } }, x.max, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastToUnsignedFromNegative(comptime From: type, comptime To: type) void {
    const x = zl.math.extrema(From);
    switch (version) {
        .single => safety.panic(.{ .cast_to_unsigned_from_negative = .{ .from = From, .to = To } }, x.min, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeAddWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intAddWillOverflow(T, &a);
    switch (version) {
        .single => safety.panic(.{ .add_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeSubWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intSubWillOverflow(T, &a);
    switch (version) {
        .single => safety.panic(.{ .sub_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeMulWithOverflow(comptime T: type) void {
    var a: T = readOne(T);
    const b: T = intMulWillOverflow(T, &a);
    switch (version) {
        .single => safety.panic(.{ .mul_overflowed = T }, .{ .lhs = a, .rhs = b }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeShlWithOverflow(comptime T: type) void {
    var x = readOne(T);
    const y = shlWillShiftOutBits(T, &x);
    switch (version) {
        .single => safety.panic(.{ .shl_overflowed = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeShrWithOverflow(comptime T: type) void {
    var x = readOne(T);
    const y = shrWillShiftOutBits(T, &x);
    switch (version) {
        .single => safety.panic(.{ .shr_overflowed = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeDivWithRemainder(comptime T: type) void {
    var x = zl.math.extrema(T);
    const y = divWillBeInexact(T, &x);
    switch (version) {
        .single => safety.panic(.{ .div_with_remainder = T }, .{ .value = x, .shift_amt = y }, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeSentinelMismatch(comptime T: type) void {
    const expected: T = readOne(T);
    switch (version) {
        .single => safety.panic(.{ .mismatched_sentinel = T }, .{ .expected = expected, .found = readOne(T) }, @errorReturnTrace(), @returnAddress()),
        .std => safety.panicSentinelMismatch(expected, readOne(T)),
    }
}
fn causeNonScalarSentinelMismatch(comptime T: type, expected: T, found: T) void {
    switch (version) {
        .single => safety.panic(.{ .mismatched_non_scalar_sentinel = T }, .{ .expected = expected, .found = found }, @errorReturnTrace(), @returnAddress()),
        .std => safety.checkNonScalarSentinel(expected, found),
    }
}
fn causeMemcpyArgumentsAlias() void {
    const data = .{ .dest_start = 0x40000000, .dest_len = 0x1000000, .src_start = 0x40500000, .src_len = 0x500000 };
    switch (version) {
        .single => safety.panic(.memcpy_argument_aliasing, data, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastToEnumFromInvalid(comptime Enum: type) void {
    switch (version) {
        .single => safety.panic(.{ .cast_to_enum_from_invalid = Enum }, 16384, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastToErrorFromInvalid(comptime Error: type) void {
    switch (version) {
        .single => safety.panic(.{ .cast_to_error_from_invalid = Error }, 32768, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
fn causeCastToIntFromInvalid(comptime Float: type, comptime Int: type) void {
    switch (version) {
        .single => safety.panic(.{ .cast_to_int_from_invalid = .{ .from = Float, .to = Int } }, 10.0, @errorReturnTrace(), @returnAddress()),
        .std => @compileError("unavailable"),
    }
}
pub fn main() void {
    causeAccessInactiveField();
    causeAccessOutOfBounds();
    causeAccessOutOfOrder();
    causeSentinelMismatch(u32);
    causeSentinelMismatch(i32);

    causeNonScalarSentinelMismatch(
        struct { a: u64, b: u32 },
        .{ .a = 1, .b = 2 },
        .{ .a = 3, .b = 4 },
    );
    causeNonScalarSentinelMismatch(
        union(enum) { a: u64, b: u32 },
        .{ .a = 1 },
        .{ .b = 4 },
    );

    if (version == .std) {
        return;
    }

    causeMemcpyArgumentsAlias();
    causeMempcyLengthMismatch();
    causeForLoopLengthMismatch();

    causeCastTruncatedBits(u8, u3);
    causeCastToUnsignedFromNegative(i32, u32);
    causeCastToIntFromInvalid(f16, u16);

    causeCastToErrorFromInvalid(error{ A, B, C, D, E });
    causeCastToEnumFromInvalid(enum(u16) { A, B, C, D, E = 32768 });

    causeCastToMisalignedPointer(u32);
    causeAddWithOverflow(u32);
    causeSubWithOverflow(u32);
    causeMulWithOverflow(u32);
    causeShlWithOverflow(u32);
    causeShrWithOverflow(u32);

    causeCastToMisalignedPointer(i32);
    causeAddWithOverflow(i32);
    causeSubWithOverflow(i32);
    causeMulWithOverflow(i32);
    causeShlWithOverflow(i32);
    causeShrWithOverflow(i32);
}
