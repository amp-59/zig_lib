const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const math = @import("./math.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
const PanicCause = union(enum) {
    message,
    access_out_of_bounds,
    access_out_of_order,
    access_inactive_field,
    memcpy_arguments_alias,
    mismatched_memcpy_lengths,
    mismatched_for_loop_lengths,
    corrupt_switch,
    unwrapped_null,
    unwrapped_error,
    returned_noreturn,
    reached_unreachable,
    shift_amt_overflowed,
    mul_overflowed: type,
    add_overflowed: type,
    sub_overflowed: type,
    shl_overflowed: type,
    shr_overflowed: type,
    div_with_remainder: type,
    mismatched_sentinel: type,
    mismatched_non_scalar_sentinel: type,
    cast_to_enum_from_invalid: type,
    cast_to_error_from_invalid: type,
    cast_to_float_from_invalid: type,
    cast_to_pointer_from_invalid: type,
    cast_truncated_data: struct {
        from: type,
        to: type,
    },
    cast_to_unsigned_from_negative: struct {
        from: type,
        to: type,
    },
};
fn PanicData(comptime panic_extra_cause: PanicCause) type {
    switch (panic_extra_cause) {
        else => void,
        .access_out_of_bounds => return struct {
            index: usize,
            length: usize,
        },
        .access_out_of_order => return struct {
            start: usize,
            finish: usize,
        },
        .access_inactive_field => return struct {
            expected: []const u8,
            found: []const u8,
        },
        .memcpy_arguments_alias => return struct {
            dest_start: usize,
            dest_finish: usize,
            src_start: usize,
            src_finish: usize,
        },
        .mismatched_memcpy_lengths => return struct {
            dest_length: usize,
            src_length: usize,
        },
        .mismatched_for_loop_lengths => return struct {
            prev_index: usize,
            prev_capture_length: usize,
            next_capture_length: usize,
        },
        .mismatched_non_scalar_sentinel,
        .mismatched_sentinel,
        => |child| return struct {
            expected: child,
            found: child,
        },
        .div_with_remainder => |num_type| return struct {
            numerator: num_type,
            denominator: num_type,
        },
        .shl_overflowed,
        .shr_overflowed,
        => |int_type| return struct {
            value: int_type,
            shift_amt: builtin.ShiftAmount(int_type),
        },
        .mul_overflowed,
        .add_overflowed,
        .sub_overflowed,
        => |val_type| return struct {
            lhs: val_type,
            rhs: val_type,
        },
        .message, .unwrapped_error => {
            return []const u8;
        },
        .cast_to_enum_from_invalid,
        .cast_to_error_from_invalid,
        => |tag_type| {
            return meta.Child(tag_type);
        },
        .cast_truncated_data => |num_type| {
            return num_type.from;
        },
        .cast_to_unsigned_from_negative => |num_type| {
            return num_type.from;
        },
        .cast_to_float_from_invalid => |dest_type| {
            return dest_type;
        },
        .cast_to_pointer_from_invalid => {
            return usize;
        },
    }
}
pub inline fn panic(comptime cause: PanicCause, data: PanicData(cause), st: ?*builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    switch (cause) {
        .message => |message| builtin.alarm(message, st, ret_addr),
        .returned_noreturn => builtin.alarm("function declared 'noreturn' returned", st, ret_addr),
        .reached_unreachable => builtin.alarm("reached unreachable code", st, ret_addr),
        .shift_amt_overflowed => builtin.alarm("shift amount overflowed", st, ret_addr),
        .corrupt_switch => builtin.alarm("switch on corrupt value", st, ret_addr),
        .unwrapped_null => builtin.alarm("attempt to use null value", st, ret_addr),
        .unwrapped_error => @call(.never_inline, panicUnwrappedError, .{ data, st, ret_addr }),
        .access_out_of_order => @call(.never_inline, panicAccessOutOfOrder, .{ data.start, data.finish, st, ret_addr }),
        .access_out_of_bounds => @call(.never_inline, panicAccessOutOfBounds, .{ data.index, data.length, st, ret_addr }),
        .access_inactive_field => @call(.never_inline, panicAccessInactiveField, .{ data.expected, data.found, st, ret_addr }),
        .memcpy_arguments_alias => @call(.never_inline, panicMemcpyArgumentsAlias, .{
            data.dest_start, data.dest_finish, data.src_start, data.src_finish, st, ret_addr,
        }),
        .mismatched_for_loop_lengths => @call(.never_inline, panicMismatchedForLoopLengths, .{
            data.prev_capture_length, data.next_capture_length, st, ret_addr,
        }),
        .mismatched_memcpy_lengths => @call(.never_inline, panicMismatchedMemcpyArgumentsLength, .{
            data.dest_length, data.src_length, st, ret_addr,
        }),
        .cast_to_pointer_from_invalid => |child_type| @call(.never_inline, panicCastToPointerFromInvalid, .{
            @typeName(child_type), data, @alignOf(child_type), st, ret_addr,
        }),
        .mismatched_sentinel => |child_type| @call(.never_inline, panicSentinelMismatch, .{
            meta.BestNum(child_type), @typeName(child_type), data.expected, data.found, st, ret_addr,
        }),
        .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, panicCastToTagFromInvalid, .{
            meta.BestInt(enum_type), @typeName(enum_type), data, st, ret_addr,
        }),
        .cast_to_error_from_invalid => |error_type| @call(.never_inline, panicCastToTagFromInvalid, .{
            meta.BestInt(error_type), @typeName(error_type), data, st, ret_addr,
        }),
        .cast_to_float_from_invalid => |float_type| @call(.never_inline, panicCastToIntFromInvalidFloat, .{
            meta.BestFloat(float_type), @typeName(float_type), data, data.rhs, st, ret_addr,
        }),
        .mismatched_non_scalar_sentinel => |child_type| @call(.never_inline, panicNonScalarSentinelMismatch, .{
            child_type, data.expected, data.found, st, ret_addr,
        }),
        .mul_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).mul, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .add_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).add, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .sub_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).sub, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .shl_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).shl, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .shr_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).shr, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .div_with_remainder => |num_type| @call(.never_inline, panicExactDivisionWithRemainder, .{
            meta.BestNum(num_type), @typeName(num_type), data.numerator, data.denominator, st, ret_addr,
        }),
        .cast_to_unsigned_from_negative => |int_types| @call(.never_inline, panicCastToUnsignedFromNegative, .{
            meta.BestNum(int_types.to),   @typeName(int_types.to),
            meta.BestNum(int_types.from), @typeName(int_types.from),
            data,                         st,
            ret_addr,
        }),
        .cast_truncated_data => |num_types| @call(.never_inline, panicCastTruncatedData, .{
            meta.BestNum(num_types.to),     @typeName(num_types.to),
            meta.BestNum(num_types.from),   @typeName(num_types.from),
            math.bestExtrema(num_types.to), data,
            st,                             ret_addr,
        }),
    }
}
fn panicMismatchedMemcpyArgumentsLength(
    dest_length: usize,
    src_length: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..56].* = "@memcpy destination and source with mismatched lengths: ".*;
    var ptr: [*]u8 = fmt.writeUdsize(buf[56..], dest_length);
    ptr[0..4].* = " != ".*;
    ptr = fmt.writeUdsize(ptr + 4, src_length);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicUnwrappedError(
    error_name: []const u8,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..17].* = "unwrapped error: ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[17..], error_name);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessOutOfBounds(
    index: usize,
    length: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    if (length == 0) {
        ptr[0..10].* = "indexing (".*;
        ptr = fmt.writeUdsize(ptr + 10, index);
        ptr = fmt.strcpyEqu(ptr, ") into empty array");
    } else {
        ptr[0..6].* = "index ".*;
        ptr = fmt.writeUdsize(ptr + 6, index);
        ptr[0..15].* = " above maximum ".*;
        ptr = fmt.writeUdsize(ptr + 15, length -% 1);
    }
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessOutOfOrder(
    start: usize,
    finish: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..12].* = "start index ".*;
    var ptr: [*]u8 = fmt.writeUdsize(buf[12..], start);
    ptr[0..26].* = " is larger than end index ".*;
    ptr = fmt.writeUdsize(ptr + 26, finish);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicMemcpyArgumentsAlias(
    dest_start: usize,
    dest_finish: usize,
    src_start: usize,
    src_finish: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..32].* = "@memcpy arguments alias between ".*;
    const range: mem.Bounds = mem.intersection(
        mem.Bounds,
        .{ .lb_addr = dest_start, .up_addr = dest_finish },
        .{ .lb_addr = src_start, .up_addr = src_finish },
    ).?;
    var ptr: [*]u8 = fmt.writeUxsize(buf[32..], range.lb_addr);
    ptr[0..5].* = " and ".*;
    ptr = fmt.writeUxsize(ptr + 5, range.up_addr);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicMismatchedForLoopLengths(
    prev_capture_length: usize,
    next_capture_length: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..49].* = "multi-for loop captures with mismatched lengths: ".*;
    var ptr: [*]u8 = fmt.writeUdsize(buf[49..], prev_capture_length);
    ptr[0..4].* = " != ".*;
    ptr = fmt.writeUdsize(ptr + 4, next_capture_length);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessInactiveField(
    expected: []const u8,
    found: []const u8,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    buf[0..23].* = "access of union field '".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[23..], found);
    ptr[0..15].* = "' while field '".*;
    ptr = fmt.strcpyEqu(ptr + 15, expected);
    ptr = fmt.strcpyEqu(ptr, "' is active");
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn writeAboveOrBelowTypeExtrema(buf: [*]u8, comptime To: type, to_type_name: []const u8, yn: bool, limit: To) [*]u8 {
    @setRuntimeSafety(builtin.is_safe);
    buf[0..7].* = if (yn)
        " below ".*
    else
        " above ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf + 7, to_type_name);
    ptr[0..10].* = if (yn)
        " minimum (".*
    else
        " maximum (".*;
    ptr = fmt.Xd(To).writeInt(ptr + 10, limit);
    ptr[0] = ')';
    return ptr + 1;
}
fn panicCastToPointerFromInvalid(
    type_name: []const u8,
    address: usize,
    alignment: usize,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setRuntimeSafety(builtin.is_safe);
    const backward: usize = address & ~(alignment -% 1);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    if (address == 0) {
        ptr[0..9].* = "cast to *".*;
        ptr = fmt.strcpyEqu(ptr + 9, type_name);
        ptr[0..29].* = "from null without 'allowzero'".*;
        ptr += 29;
    } else {
        ptr[0..7].* = "*align(".*;
        ptr = fmt.writeUdsize(ptr + 7, alignment);
        ptr[0..2].* = ") ".*;
        ptr = fmt.strcpyEqu(ptr + 2, type_name);
        ptr[0..23].* = ": incorrect alignment: ".*;
        ptr = fmt.writeUxsize(ptr + 23, address);
        ptr[0..4].* = " == ".*;
        ptr = fmt.writeUxsize(ptr + 4, backward);
        ptr[0] = '+';
        ptr = fmt.writeUxsize(ptr + 1, address -% backward);
    }
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToTagFromInvalid(
    comptime Integer: type,
    type_name: []const u8,
    value: Integer,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [256]u8 = undefined;
    buf[0..8].* = "cast to ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[8..], type_name);
    ptr[0..20].* = " from invalid value ".*;
    ptr = fmt.writeUdsize(ptr + 20, value);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToIntFromInvalidFloat(
    type_name: []const u8,
    value: anytype,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [256]u8 = undefined;
    buf[0..8].* = "cast to ".*;
    var ptr: [*]u8 = fmt.strcpyEqu(buf[8..], type_name);
    ptr[0..20].* = " from invalid value ".*;
    ptr = fmt.writeUdsize(ptr + 20, value);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastTruncatedData(
    comptime To: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    extrema: math.BestExtrema(To),
    value: From,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = buf[0..];
    const yn: bool = value < 0;
    ptr[0..18].* = "integer cast from ".*;
    ptr = fmt.strcpyEqu(ptr + 18, from_type_name);
    ptr[0..4].* = " to ".*;
    ptr = fmt.strcpyEqu(ptr + 4, to_type_name);
    ptr[0..17].* = " truncated bits: ".*;
    ptr = fmt.Xd(From).writeInt(ptr + 17, value);
    ptr = writeAboveOrBelowTypeExtrema(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToUnsignedFromNegative(
    comptime _: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    value: From,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = buf[0..];
    ptr[0..18].* = "integer cast from ".*;
    ptr = fmt.strcpyEqu(ptr + 27, from_type_name);
    ptr[0..2].* = " (".*;
    ptr = fmt.Xd(From).writeInt(ptr + 2, value);
    ptr[0..5].* = ") to ".*;
    ptr = fmt.strcpyEqu(ptr + 5, to_type_name);
    ptr[0..16].* = " lost signedness".*;
    builtin.alarm(buf[0 .. @intFromPtr(ptr + 16) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicSentinelMismatch(
    comptime Number: type,
    type_name: []const u8,
    expected: Number,
    found: Number,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
    ptr[0..29].* = " sentinel mismatch: expected ".*;
    ptr = fmt.Xd(Number).writeInt(ptr + 29, expected);
    ptr[0..8].* = ", found ".*;
    ptr = fmt.Xd(Number).writeInt(ptr + 8, found);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicNonScalarSentinelMismatch(
    comptime Child: type,
    expected: Child,
    found: Child,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    const type_name = @typeName(Child);
    var buf: [1024]u8 = undefined;
    buf[0 .. type_name.len +% 29].* = (type_name ++ " sentinel mismatch: expected ").*;
    var ptr: [*]u8 = buf[type_name.len +% 29 ..];
    ptr += fmt.render(.{ .infer_type_names = true }, expected).formatWriteBuf(ptr);
    ptr[0..8].* = ", found ".*;
    ptr += 8;
    ptr += fmt.render(.{ .infer_type_names = true }, found).formatWriteBuf(ptr);
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicExactDivisionWithRemainder(
    comptime Number: type,
    type_name: []const u8,
    numerator: Number,
    denominator: Number,
    st: ?*builtin.StackTrace,
    ret_addr: usize,
) void {
    @setRuntimeSafety(builtin.is_safe);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
    ptr[0..34].* = ": exact division had a remainder: ".*;
    ptr += 34;
    ptr += fmt.Xd(Number).writeInt(ptr + 34, numerator);
    ptr[0] = '/';
    ptr += fmt.Xd(Number).writeInt(ptr + 1, denominator);
    ptr[0..4].* = " == ".*;
    ptr = fmt.Xd(Number).writeInt(ptr + 4, @divTrunc(numerator, denominator));
    ptr[0] = 'r';
    ptr = fmt.Xd(Number).writeInt(ptr + 1, @rem(numerator, denominator));
    builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicArithOverflow(comptime Number: type) type {
    return struct {
        const Extrema = math.BestExtrema(Number);
        const Absolute = math.Absolute(Number);
        const ShiftAmount = builtin.ShiftAmount(Number);
        fn add(type_name: []const u8, extrema: Extrema, lhs: Number, rhs: Number, st: ?*builtin.StackTrace, ret_addr: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const yn: bool = rhs < 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @addWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).writeInt(ptr + 19, lhs);
            ptr[0..3].* = " + ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).writeInt(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowTypeExtrema(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn sub(type_name: []const u8, extrema: Extrema, lhs: Number, rhs: Number, st: ?*builtin.StackTrace, ret_addr: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const yn: bool = rhs > 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @subWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).writeInt(ptr + 19, lhs);
            ptr[0..3].* = " - ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).writeInt(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowTypeExtrema(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn mul(type_name: []const u8, extrema: Extrema, lhs: Number, rhs: Number, st: ?*builtin.StackTrace, ret_addr: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const yn: bool = (rhs < 0 and lhs > 0) or (lhs < 0 and rhs > 0);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..19].* = " integer overflow: ".*;
            const res = @mulWithOverflow(lhs, rhs);
            ptr = fmt.Xd(Number).writeInt(ptr + 19, lhs);
            ptr[0..3].* = " * ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = fmt.Xd(Number).writeInt(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            ptr = writeAboveOrBelowTypeExtrema(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn shl(type_name: []const u8, value: Number, shift_amt: ShiftAmount, mask: Absolute, st: ?*builtin.StackTrace, ret_addr: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const absolute: Absolute = @bitCast(value);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..29].* = " left shift overflowed bits: ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 29, value);
            ptr[0..4].* = " << ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 4, shift_amt);
            ptr[0..13].* = " shifted out ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 13, @popCount(absolute) -% @popCount((absolute << shift_amt) & mask));
            ptr[0..5].* = " bits".*;
            builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn shr(type_name: []const u8, value: Number, shift_amt: ShiftAmount, mask: Absolute, st: ?*builtin.StackTrace, ret_addr: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const Abs = @TypeOf(@abs(value));
            const absolute: Abs = @bitCast(value);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..30].* = " right shift overflowed bits: ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 30, value);
            ptr[0..4].* = " >> ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 4, shift_amt);
            ptr[0..13].* = " shifted out ".*;
            ptr = fmt.Xd(Number).writeInt(ptr + 13, @popCount(absolute) -% @popCount((absolute >> shift_amt) & mask));
            ptr[0..5].* = " bits".*;
            builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
        }
    };
}
