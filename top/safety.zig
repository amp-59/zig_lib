const mem = @import("mem.zig");
const fmt = @import("fmt.zig");
const math = @import("math.zig");
const meta = @import("meta.zig");
const builtin = @import("builtin.zig");
const fill = undefined;
pub fn writeAboveOrBelowLimit(
    buf: [*]u8,
    comptime To: type,
    to_type_name: []const u8,
    yn: bool,
    limit: To,
) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..7].* = if (yn) " below ".* else " above ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf + 7, to_type_name);
    ptr[0..10].* = if (yn) " minimum (".* else " maximum (".*;
    ptr = fmt.Xd(To).write(ptr + 10, limit);
    ptr[0] = ')';
    return ptr + 1;
}
pub fn panicMismatchedMemcpyArgumentLengths(
    dest_len: usize,
    src_len: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..65].* = "@memcpy destination and source with mismatched lengths: expected ".*;
    var ptr: [*]u8 = fmt.Udsize.write(buf[65..], dest_len);
    ptr[0..8].* = ", found ".*;
    ptr = fmt.Udsize.write(ptr + 8, src_len);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicUnwrappedError(
    error_name: []const u8,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..17].* = "unwrapped error: ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[17..], error_name);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicAccessOutOfBounds(
    index: usize,
    length: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    if (length == 0) {
        ptr[0..10].* = "indexing (".*;
        ptr = fmt.Udsize.write(ptr + 10, index);
        ptr = fmt.strcpyEqu(ptr, ") into empty array");
    } else {
        ptr[0..6].* = "index ".*;
        ptr = fmt.Udsize.write(ptr + 6, index);
        ptr[0..15].* = " above maximum ".*;
        ptr = fmt.Udsize.write(ptr + 15, length -% 1);
    }
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicAccessOutOfOrder(
    start: usize,
    finish: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..12].* = "start index ".*;
    var ptr: [*]u8 = fmt.Udsize.write(buf[12..], start);
    ptr[0..26].* = " is larger than end index ".*;
    ptr = fmt.Udsize.write(ptr + 26, finish);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicMemcpyArgumentsAlias(
    dest_start: usize,
    dest_len: usize,
    src_start: usize,
    src_len: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..32].* = "@memcpy arguments alias between ".*;
    var ptr: [*]u8 = fmt.Uxsize.write(buf[32..], @max(dest_start, src_start));
    ptr[0..5].* = " and ".*;
    ptr = fmt.Uxsize.write(ptr + 5, @min(dest_start +% dest_len, src_start +% src_len));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicMismatchedForLoopCaptureLengths(
    prev_len: usize,
    next_len: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..58].* = "multi-for loop captures with mismatched lengths: expected ".*;
    var ptr: [*]u8 = fmt.Udsize.write(buf[58..], prev_len);
    ptr[0..8].* = ", found ".*;
    ptr = fmt.Udsize.write(ptr + 8, next_len);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicAccessInactiveField(
    expected: []const u8,
    found: []const u8,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..23].* = "access of union field '".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[23..], found);
    ptr[0..15].* = "' while field '".*;
    ptr = fmt.strcpyEqu(ptr + 15, expected);
    ptr = fmt.strcpyEqu(ptr, "' is active");
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicCastToPointerFromInvalid(
    type_name: []const u8,
    address: usize,
    alignment: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    if (address == 0) {
        ptr[0..17].* = "integer cast to *".*;
        ptr = fmt.strcpyEqu(ptr + 17, type_name);
        ptr[0..30].* = " from null without 'allowzero'".*;
        ptr += 30;
    } else {
        ptr[0..7].* = "*align(".*;
        ptr = fmt.Udsize.write(ptr + 7, alignment);
        ptr[0..2].* = ") ".*;
        ptr = fmt.strcpyEqu(ptr + 2, type_name);
        ptr[0..23].* = ": incorrect alignment: ".*;
        ptr = fmt.Uxsize.write(ptr + 23, address);
        ptr[0..4].* = " == ".*;
        ptr = fmt.Uxsize.write(ptr + 4, address & ~(alignment -% 1));
        ptr[0] = '+';
        ptr = fmt.Uxsize.write(ptr + 1, address & (alignment -% 1));
    }
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicCastToTagFromInvalid(
    comptime Integer: type,
    type_name: []const u8,
    value: Integer,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..8].* = "cast to ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[8..], type_name);
    ptr[0..20].* = " from invalid value ".*;
    ptr = fmt.Udsize.write(ptr + 20, value);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicCastToIntFromInvalid(
    comptime Float: type,
    type_name: []const u8,
    _: Float,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..8].* = "cast to ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[8..], type_name);
    ptr[0..20].* = " from invalid value ".*;
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicCastTruncatedData(
    comptime To: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    extrema: math.BestExtrema(To),
    value: From,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = buf[0..];
    const yn: bool = value < 0;
    ptr[0..18].* = "integer cast from ".*;
    ptr = fmt.strcpyEqu(ptr + 18, from_type_name);
    ptr[0..4].* = " to ".*;
    ptr = fmt.strcpyEqu(ptr + 4, to_type_name);
    ptr[0..17].* = " truncated bits: ".*;
    ptr = fmt.Xd(From).write(ptr + 17, value);
    ptr = writeAboveOrBelowLimit(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicCastToUnsignedFromNegative(
    comptime _: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    value: From,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = buf[0..];
    ptr[0..18].* = "integer cast from ".*;
    ptr = fmt.strcpyEqu(ptr + 18, from_type_name);
    ptr[0..2].* = " (".*;
    ptr = fmt.Xd(From).write(ptr + 2, value);
    ptr[0..5].* = ") to ".*;
    ptr = fmt.strcpyEqu(ptr + 5, to_type_name);
    ptr[0..16].* = " lost signedness".*;
    builtin.alarm(buf[0 .. @intFromPtr(ptr + 16) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicSentinelMismatch(
    comptime Number: type,
    type_name: []const u8,
    expected: Number,
    found: Number,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
    ptr[0..29].* = " sentinel mismatch: expected ".*;
    ptr = fmt.Xd(Number).write(ptr + 29, expected);
    ptr[0..8].* = ", found ".*;
    ptr = fmt.Xd(Number).write(ptr + 8, found);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicNonScalarSentinelMismatch(
    comptime Child: type,
    expected: Child,
    found: Child,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    if (!mem.testEqual(Child, expected, found)) {
        const Format = fmt.AnyFormat(.{}, Child);
        const type_name = @typeName(Child);
        var buf: [type_name.len +% 256 +% (2 *% Format.max_len.?)]u8 = undefined;
        buf[0..type_name.len].* = type_name.*;
        var ptr: [*]u8 = buf[type_name.len..];
        ptr[0..29].* = " sentinel mismatch: expected ".*;
        ptr = Format.write(ptr + 29, expected);
        ptr[0..8].* = ", found ".*;
        ptr = Format.write(ptr + 8, found);
        builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
    }
}
pub fn panicExactDivisionWithRemainder(
    comptime Number: type,
    type_name: []const u8,
    numerator: Number,
    denominator: Number,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
    ptr[0..34].* = ": exact division had a remainder: ".*;
    ptr += fmt.Xd(Number).write(ptr + 34, numerator);
    ptr[0] = '/';
    ptr += fmt.Xd(Number).write(ptr + 1, denominator);
    ptr[0..4].* = " == ".*;
    ptr = fmt.Xd(Number).write(ptr + 4, @divTrunc(numerator, denominator));
    ptr[0] = 'r';
    ptr = fmt.Xd(Number).write(ptr + 1, @rem(numerator, denominator));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub fn panicArithOverflow(comptime Number: type) type {
    return struct {
        const Extrema = math.BestExtrema(Number);
        const Absolute = math.Absolute(Number);
        const ShiftAmount = builtin.ShiftAmount(Number);
        pub fn add(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            const yn: bool = rhs < 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @addWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).write(ptr + 19, lhs);
            ptr[0..3].* = " + ".*;
            ptr = fmt.Xd(Number).write(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).write(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        pub fn sub(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            const yn: bool = rhs > 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @subWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).write(ptr + 19, lhs);
            ptr[0..3].* = " - ".*;
            ptr = fmt.Xd(Number).write(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).write(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        pub fn mul(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            var yn: bool = @bitCast(
                (@intFromBool(rhs < 0) & @intFromBool(lhs > 0)) |
                    (@intFromBool(lhs < 0) & @intFromBool(rhs > 0)),
            );
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @mulWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).write(ptr + 19, lhs);
            ptr[0..3].* = " * ".*;
            ptr = fmt.Xd(Number).write(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).write(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        pub fn shl(
            type_name: []const u8,
            value: Number,
            shift_amt: ShiftAmount,
            mask: Absolute,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            const absolute: Absolute = @bitCast(value);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..29].* = " left shift overflowed bits: ".*;
            ptr = fmt.Xd(Number).write(ptr + 29, value);
            ptr[0..4].* = " << ".*;
            ptr = fmt.Xd(Number).write(ptr + 4, shift_amt);
            ptr[0..13].* = " shifted out ".*;
            ptr = fmt.Xd(Number).write(ptr + 13, @popCount(absolute & mask) -% @popCount((absolute << shift_amt) & mask));
            ptr[0..5].* = " bits".*;
            builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
        }
        pub fn shr(
            type_name: []const u8,
            value: Number,
            shift_amt: ShiftAmount,
            mask: Absolute,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            const absolute: Absolute = @bitCast(value);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..30].* = " right shift overflowed bits: ".*;
            ptr = fmt.Xd(Number).write(ptr + 30, value);
            ptr[0..4].* = " >> ".*;
            ptr = fmt.Xd(Number).write(ptr + 4, shift_amt);
            ptr[0..13].* = " shifted out ".*;
            ptr = fmt.Xd(Number).write(ptr + 13, @popCount(absolute & mask) -% @popCount((absolute << shift_amt) & mask));
            ptr[0..5].* = " bits".*;
            builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
        }
    };
}
