const mem = @import("mem.zig");
const fmt = @import("fmt.zig");
const math = @import("math.zig");
const meta = @import("meta.zig");
const builtin = @import("builtin.zig");
/// Note:
///     Default settings may be changed.
///
///     Arbitrary groupings may be changed.
///
///     Names of functions, function parameters, fields, types, and
///     compile commands may be changed.
///
pub const RuntimeSafetyCheck = struct {
    mismatched_arguments: ?bool = null,
    reached_unreachable: ?bool = null,
    accessed_invalid_memory: ?bool = null,
    mismatched_sentinel: ?bool = null,
    arith_lost_precision: ?bool = null,
    arith_overflowed: ?bool = null,
    cast_from_invalid: ?bool = null,
    pub fn causes(comptime tag: Tag) []const PanicCause.Tag {
        switch (tag) {
            .reached_unreachable => return &.{
                .message,
                .discarded_error,
                .corrupt_switch,
                .returned_noreturn,
                .reached_unreachable,
                .accessed_null_value,
            },
            .mismatched_arguments => return &.{
                .memcpy_argument_aliasing,
                .memcpy_argument_lengths_mismatched,
                .for_loop_capture_lengths_mismatched,
            },
            .accessed_invalid_memory => return &.{
                .accessed_out_of_bounds,
                .accessed_out_of_order,
                .accessed_inactive_field,
            },
            .mismatched_sentinel => return &.{
                .mismatched_sentinel,
                .mismatched_non_scalar_sentinel,
            },
            .arith_lost_precision => return &.{
                .div_with_remainder,
                .shl_overflowed,
                .shr_overflowed,
                .shift_amt_overflowed,
            },
            .arith_overflowed => return &.{
                .mul_overflowed,
                .add_overflowed,
                .sub_overflowed,
            },
            .cast_from_invalid => return &.{
                .cast_to_int_from_invalid,
                .cast_truncated_data,
                .cast_to_unsigned_from_negative,
                .cast_to_pointer_from_invalid,
                .cast_to_enum_from_invalid,
                .cast_to_error_from_invalid,
            },
        }
    }
    pub const Tag = meta.TagFromList(meta.fieldNames(RuntimeSafetyCheck));
};
pub const PanicCause = union(enum) {
    /// -f[no-]panic-reached-unreachable
    message,
    corrupt_switch,
    discarded_error,
    returned_noreturn,
    reached_unreachable,
    /// -f[no-]panic-accessed-invalid-memory
    accessed_out_of_bounds,
    accessed_out_of_order,
    accessed_inactive_field,
    accessed_null_value,
    /// -f[no-]panic-mismatched-arguments
    memcpy_argument_aliasing,
    memcpy_argument_lengths_mismatched,
    for_loop_capture_lengths_mismatched,
    /// -f[no-]panic-mismatched-sentinel
    mismatched_sentinel: type,
    mismatched_non_scalar_sentinel: type,
    /// -f[no-]panic-arith-lost-precision
    shl_overflowed: type,
    shr_overflowed: type,
    shift_amt_overflowed: type,
    div_with_remainder: type,
    /// -f[no-]panic-arith-overflowed
    mul_overflowed: type,
    add_overflowed: type,
    sub_overflowed: type,
    /// -f[no-]panic-cast-from-invalid
    cast_truncated_data: struct {
        to: type,
        from: type,
    },
    cast_to_enum_from_invalid: type,
    cast_to_error_from_invalid: type,
    cast_to_pointer_from_invalid: type,
    cast_to_int_from_invalid: struct {
        to: type,
        from: type,
    },
    cast_to_unsigned_from_negative: struct {
        to: type,
        from: type,
    },
    pub const Tag = @typeInfo(@This()).Union.tag_type.?;
};
pub fn PanicData(comptime panic_extra_cause: PanicCause) type {
    switch (panic_extra_cause) {
        // reached_unreachable
        .message,
        .discarded_error,
        => {
            return []const u8;
        },
        .corrupt_switch,
        .returned_noreturn,
        .reached_unreachable,
        .accessed_null_value,
        => {
            return void;
        },
        // accessed_invalid_memory
        .accessed_out_of_bounds => {
            return struct { index: usize, length: usize };
        },
        .accessed_out_of_order => {
            return struct { start: usize, finish: usize };
        },
        .accessed_inactive_field => {
            return struct { expected: []const u8, found: []const u8 };
        },
        // mismatched_arguments
        .memcpy_argument_aliasing => {
            return struct { dest_start: usize, dest_len: usize, src_start: usize, src_len: usize };
        },
        .memcpy_argument_lengths_mismatched => {
            return struct { dest_len: usize, src_len: usize };
        },
        .for_loop_capture_lengths_mismatched => {
            return struct { prev_index: usize, prev_len: usize, next_len: usize };
        },
        // mismatched_sentinel
        .mismatched_sentinel,
        .mismatched_non_scalar_sentinel,
        => |child| {
            return struct { expected: child, found: child };
        },
        // arith_overflowed
        .mul_overflowed,
        .add_overflowed,
        .sub_overflowed,
        => |val_type| {
            return struct { lhs: val_type, rhs: val_type };
        },
        // arith_lost_precision
        .div_with_remainder => |num_type| {
            return struct { numerator: num_type, denominator: num_type };
        },
        .shl_overflowed,
        .shr_overflowed,
        => |int_type| {
            return struct {
                value: int_type,
                shift_amt: builtin.ShiftAmount(int_type),
            };
        },
        .shift_amt_overflowed => |int_type| {
            return struct {
                bit_count: u16,
                shift_amt: builtin.ShiftAmount(int_type),
            };
        },
        // cast_from_invalid
        .cast_to_int_from_invalid => |num_type| {
            return num_type.from;
        },
        .cast_truncated_data => |num_type| {
            return num_type.from;
        },
        .cast_to_unsigned_from_negative => |num_type| {
            return num_type.from;
        },
        .cast_to_pointer_from_invalid => {
            return usize;
        },
        .cast_to_enum_from_invalid => |tag_type| {
            return meta.Child(tag_type);
        },
        .cast_to_error_from_invalid => {
            return u16;
        },
    }
}
pub inline fn panic(comptime cause: PanicCause, data: PanicData(cause), st: ?*builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    switch (cause) {
        .message => |message| builtin.alarm(message, st, ret_addr),
        .returned_noreturn => {
            builtin.alarm("function declared 'noreturn' returned", st, ret_addr);
        },
        .reached_unreachable => {
            builtin.alarm("reached unreachable code", st, ret_addr);
        },
        .corrupt_switch => {
            builtin.alarm("switch on corrupt value", st, ret_addr);
        },
        .accessed_null_value => {
            builtin.alarm("attempt to use null value", st, ret_addr);
        },
        .accessed_out_of_order => @call(.never_inline, panicAccessOutOfOrder, .{
            data.start, data.finish, st, ret_addr,
        }),
        .accessed_out_of_bounds => @call(.never_inline, panicAccessOutOfBounds, .{
            data.index, data.length, st, ret_addr,
        }),
        .accessed_inactive_field => @call(.never_inline, panicAccessInactiveField, .{
            data.expected, data.found, st, ret_addr,
        }),
        .discarded_error => @call(.never_inline, panicUnwrappedError, .{
            data, st, ret_addr,
        }),
        .memcpy_argument_aliasing => @call(.never_inline, panicMemcpyArgumentsAlias, .{
            data.dest_start, data.dest_len, data.src_start, data.src_len, st, ret_addr,
        }),
        .memcpy_argument_lengths_mismatched => @call(.never_inline, panicMismatchedMemcpyArgumentLengths, .{
            data.dest_len, data.src_len, st, ret_addr,
        }),
        .for_loop_capture_lengths_mismatched => @call(.never_inline, panicMismatchedForLoopCaptureLengths, .{
            data.prev_len, data.next_len, st, ret_addr,
        }),
        .cast_to_pointer_from_invalid => |child_type| @call(.never_inline, panicCastToPointerFromInvalid, .{
            @typeName(child_type), data, @alignOf(child_type), st, ret_addr,
        }),
        .mismatched_sentinel => |child_type| @call(.never_inline, panicSentinelMismatch, .{
            meta.BestNum(child_type), @typeName(child_type), data.expected, data.found, st, ret_addr,
        }),
        .cast_to_int_from_invalid => |num_types| @call(.never_inline, panicCastToIntFromInvalid, .{
            meta.BestFloat(num_types.from), @typeName(num_types.from), data, st, ret_addr,
        }),
        .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, panicCastToTagFromInvalid, .{
            meta.BestInt(enum_type), @typeName(enum_type), data, st, ret_addr,
        }),
        .cast_to_error_from_invalid => |error_type| @call(.never_inline, panicCastToTagFromInvalid, .{
            meta.BestInt(error_type), @typeName(error_type), data, st, ret_addr,
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
        .shift_amt_overflowed => |int_type| @call(.never_inline, panicArithOverflow(meta.BestInt(int_type)).rhs, .{
            @typeName(int_type), data.bit_count, data.shift_amt, st, ret_addr,
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
        pub fn shiftRhs(
            type_name: []const u8,
            bit_count: u16,
            shift_amt: ShiftAmount,
            st: ?*builtin.StackTrace,
            ret_addr: usize,
        ) void {
            @setCold(true);
            @setRuntimeSafety(false);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
            ptr[0..30].* = " RHS of shift too big: ".*;
            ptr = fmt.Xd(Number).write(ptr + 30, shift_amt);
            ptr[0..4].* = " > ".*;
            ptr = fmt.Xd(Number).write(ptr + 4, bit_count);
            builtin.alarm(buf[0 .. @intFromPtr(ptr + 5) -% @intFromPtr(&buf)], st, ret_addr);
        }
    };
}
