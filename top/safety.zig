const zl = @import("../zig_lib.zig");
/// Note:
///     Default settings may be changed.
///
///     Arbitrary groupings may be changed.
///
///     Names of functions, function parameters, fields, types, and
///     compile commands may be changed.
///
pub const RuntimeSafetyCheck = struct {
    reached_unreachable: ?bool = null,
    mismatched_arguments: ?bool = null,
    accessed_invalid_memory: ?bool = null,
    mismatched_sentinel: ?bool = null,
    arith_lost_precision: ?bool = null,
    arith_overflowed: ?bool = null,
    cast_from_invalid: ?bool = null,
    pub const Tag = zl.meta.TagFromList(zl.meta.fieldNames(RuntimeSafetyCheck));
    pub fn causes(comptime tag: Tag) []const PanicId {
        switch (tag) {
            .reached_unreachable => return &.{
                .message,
                .returned_noreturn,
                .reached_unreachable,
                .reached_unreachable_operand,
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
};

pub const PanicId = @typeInfo(PanicCause).Union.tag_type.?;

pub const PanicCause = union(enum) {
    /// Control: -f[no-]panic-reached-unreachable
    ///
    /// @panic
    message,
    /// fn f() noreturn { return; }
    returned_noreturn,
    /// unreachable
    reached_unreachable,
    /// (catch|=>) unreachable
    reached_unreachable_operand: type,

    /// -f[no-]panic-accessed-invalid-memory
    ///
    /// ([0]void{})[0];
    accessed_out_of_bounds,
    /// ([1]void{{}})[1..0];
    accessed_out_of_order,
    /// @as(union(enum) { a, b }, .a).b;
    accessed_inactive_field,
    /// @as(?void, null).?;
    accessed_null_value,
    /// 1 / 0
    divided_by_zero,

    /// Control: -f[no-]panic-mismatched-arguments
    ///
    /// @memcpy
    memcpy_argument_aliasing,
    /// @memcpy
    memcpy_argument_lengths_mismatched,
    /// for
    for_loop_capture_lengths_mismatched,

    /// -f[no-]panic-mismatched-sentinel
    mismatched_sentinel: type,

    /// Control: -f[no-]panic-arith-lost-precision
    ///
    /// @shlExact   Int type
    shl_overflowed: type,
    /// @shrExact   Int type
    shr_overflowed: type,
    /// <<          Int type
    shift_amt_overflowed: type,
    /// @divExact   Resolved Int type
    div_with_remainder: type,

    /// Control: -f[no-]panic-arith-overflowed
    ///
    /// *   Resolved Int type
    mul_overflowed: type,
    /// +   Resolved Int type
    add_overflowed: type,
    /// -   Resolved Int type
    sub_overflowed: type,

    /// Control: -f[no-]panic-cast-from-invalid
    ///
    /// @intCast        To Int type from Int type
    cast_truncated_data: Cast,
    /// @enumFromInt    Enum type
    cast_to_enum_from_invalid: type,
    /// @errorFromInt   Error type
    cast_to_error_from_invalid: Cast,
    /// @ptrFromInt     Pointer type
    cast_to_pointer_from_invalid: type,
    /// @intFromFloat   To Int type from Float type
    cast_to_int_from_invalid: Cast,
    /// @intCast        To Int type from Int type
    cast_to_unsigned_from_negative: Cast,
};
pub const Cast = struct {
    to: type,
    from: type,
};
pub fn PanicData(comptime cause: PanicCause) type {
    switch (cause) {
        .message => {
            return []const u8;
        },
        .returned_noreturn,
        .reached_unreachable,
        .accessed_null_value,
        .divided_by_zero,
        => {
            return void;
        },
        .reached_unreachable_operand => |op_type| {
            return op_type;
        },
        .accessed_out_of_bounds => {
            return struct { index: usize, length: usize };
        },
        .accessed_out_of_order => {
            return struct { start: usize, finish: usize };
        },
        .accessed_inactive_field => {
            return struct { expected: []const u8, found: []const u8 };
        },
        .memcpy_argument_aliasing => {
            return struct { dest_start: usize, dest_finish: usize, src_start: usize, src_finish: usize };
        },
        .memcpy_argument_lengths_mismatched => {
            return struct { dest_len: usize, src_len: usize };
        },
        .for_loop_capture_lengths_mismatched => {
            return struct { loop_len: usize, capture_len: usize };
        },
        .mismatched_sentinel => |child| {
            return struct { expected: child, found: child };
        },
        .mul_overflowed,
        .add_overflowed,
        .sub_overflowed,
        => |val_type| {
            return struct { lhs: val_type, rhs: val_type };
        },
        .div_with_remainder => |num_type| {
            return struct { numerator: num_type, denominator: num_type };
        },
        .shl_overflowed,
        .shr_overflowed,
        => |int_type| {
            return struct {
                value: int_type,
                shift_amt: zl.builtin.ShiftAmount(int_type),
            };
        },
        .shift_amt_overflowed => |int_type| {
            return zl.builtin.ShiftAmount(int_type);
        },
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
        .cast_to_enum_from_invalid => |enum_type| {
            return @typeInfo(enum_type).Enum.tag_type;
        },
        .cast_to_error_from_invalid => |error_type| {
            return error_type.from;
        },
    }
}

// Safety

pub inline fn panic(comptime cause: PanicCause, data: PanicData(cause), st: ?*zl.builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    switch (cause) {
        .message => panic_fn(data, st, ret_addr),
        .accessed_null_value => {
            panic_fn("attempt to use null value", st, ret_addr);
        },
        .divided_by_zero => {
            panic_fn("attempt to divide by zero", st, ret_addr);
        },
        .returned_noreturn => {
            panic_fn("function marked 'noreturn' returned", st, ret_addr);
        },
        .reached_unreachable => {
            panic_fn("reached unreachable code", st, ret_addr);
        },
        .reached_unreachable_operand => |op_type| if (op_type == anyerror) {
            @call(.never_inline, panicUnreachableError, .{ data, st, ret_addr });
        } else {
            @call(.never_inline, panicUnreachableValue, .{ op_type, data, st, ret_addr });
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
        .memcpy_argument_aliasing => @call(.never_inline, panicMemcpyArgumentsAlias, .{
            data.dest_start, data.dest_finish, data.src_start, data.src_finish, st, ret_addr,
        }),
        .memcpy_argument_lengths_mismatched => @call(.never_inline, panicMismatchedMemcpyArgumentLengths, .{
            data.dest_len, data.src_len, st, ret_addr,
        }),
        .for_loop_capture_lengths_mismatched => @call(.never_inline, panicMismatchedForLoopCaptureLengths, .{
            data.loop_len, data.capture_len, st, ret_addr,
        }),
        .cast_to_pointer_from_invalid => |child_type| @call(.never_inline, panicCastToPointerFromInvalid, .{
            @typeName(child_type), data, @alignOf(child_type), st, ret_addr,
        }),
        .mismatched_sentinel => |child_type| @call(.never_inline, panicSentinelMismatch, .{
            zl.meta.BestNum(child_type), @typeName(child_type), data.expected, data.found, st, ret_addr,
        }),
        .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, panicCastToTagFromInvalid, .{
            zl.meta.BestInt(enum_type), @typeName(enum_type), data, st, ret_addr,
        }),
        .cast_to_error_from_invalid => |error_type| @call(.never_inline, panicCastToErrorFromInvalid, .{
            error_type.from, @typeName(error_type.to), data, st, ret_addr,
        }),
        .mul_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).mul, .{
            @typeName(int_type), zl.math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .add_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).add, .{
            @typeName(int_type), zl.math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .sub_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).sub, .{
            @typeName(int_type), zl.math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .shl_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).shl, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .shr_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).shr, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .shift_amt_overflowed => |int_type| @call(.never_inline, panicArithOverflow(zl.meta.BestInt(int_type)).shiftRhs, .{
            @typeName(int_type), @bitSizeOf(int_type), data, st, ret_addr,
        }),
        .div_with_remainder => |num_type| @call(.never_inline, panicExactDivisionWithRemainder, .{
            zl.meta.BestNum(num_type), @typeName(num_type), data.numerator, data.denominator, st, ret_addr,
        }),
        .cast_to_unsigned_from_negative => |int_types| @call(.never_inline, panicCastToUnsignedFromNegative, .{
            zl.meta.BestNum(int_types.to),   @typeName(int_types.to),
            zl.meta.BestNum(int_types.from), @typeName(int_types.from),
            data,                            st,
            ret_addr,
        }),
        .cast_to_int_from_invalid => |num_types| @call(.never_inline, panicCastToIntFromInvalid, .{
            zl.meta.BestNum(num_types.to),     @typeName(num_types.to),
            zl.meta.BestNum(num_types.from),   @typeName(num_types.from),
            zl.math.bestExtrema(num_types.to), data,
            st,                                ret_addr,
        }),
        .cast_truncated_data => |num_types| @call(.never_inline, panicCastTruncatedData, .{
            zl.meta.BestNum(num_types.to),     @typeName(num_types.to),
            zl.meta.BestNum(num_types.from),   @typeName(num_types.from),
            zl.math.bestExtrema(num_types.to), data,
            st,                                ret_addr,
        }),
    }
}

// Potential local implementation:
const panic_fn = zl.builtin.alarm;
const return_type = zl.meta.Return(panic_fn);

fn panicMismatchedMemcpyArgumentLengths(
    dest_len: usize,
    src_len: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..65].* = "@memcpy destination and source with mismatched lengths: expected ".*;
    var ptr: [*]u8 = zl.fmt.Udsize.write(buf[65..], dest_len);
    ptr[0..8].* = ", found ".*;
    ptr = zl.fmt.Udsize.write(ptr + 8, src_len);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicUnreachableError(
    err: anyerror,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..17].* = "unwrapped error: ".*;
    const ptr: [*]u8 = zl.fmt.strcpyEqu(buf[17..], @errorName(err));
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicUnreachableValue(
    comptime Any: type,
    value: anytype,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    const type_name: []const u8 = @typeName(Any);
    const Format = zl.fmt.AnyFormat(.{}, Any);
    var buf: [type_name.len +% 256 +% (2 *% Format.max_len.?)]u8 = undefined;
    buf[0..27].* = "reached unreachable value: ".*;
    panic_fn(buf[0 .. @intFromPtr(Format.write(buf[27..], value)) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessOutOfBounds(
    index: usize,
    length: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    if (length == 0) {
        ptr[0..10].* = "indexing (".*;
        ptr = zl.fmt.Udsize.write(ptr + 10, index);
        ptr = zl.fmt.strcpyEqu(ptr, ") into empty array");
    } else {
        ptr[0..6].* = "index ".*;
        ptr = zl.fmt.Udsize.write(ptr + 6, index);
        ptr[0..15].* = " above maximum ".*;
        ptr = zl.fmt.Udsize.write(ptr + 15, length -% 1);
    }
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessOutOfOrder(
    start: usize,
    finish: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..12].* = "start index ".*;
    var ptr: [*]u8 = zl.fmt.Udsize.write(buf[12..], start);
    ptr[0..26].* = " is larger than end index ".*;
    ptr = zl.fmt.Udsize.write(ptr + 26, finish);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicMemcpyArgumentsAlias(
    dest_start: usize,
    dest_finish: usize,
    src_start: usize,
    src_finish: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..32].* = "@memcpy arguments alias between ".*;
    var ptr: [*]u8 = zl.fmt.Uxsize.write(buf[32..], @max(dest_start, src_start));
    ptr[0..5].* = " and ".*;
    ptr = zl.fmt.Uxsize.write(ptr + 5, @min(dest_finish, src_finish));
    ptr[0..2].* = " (".*;
    ptr = zl.fmt.Udsize.write(ptr + 2, dest_finish -% dest_start);
    ptr[0..7].* = " bytes)".*;
    panic_fn(buf[0 .. @intFromPtr(ptr + 7) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicMismatchedForLoopCaptureLengths(
    prev_len: usize,
    next_len: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..58].* = "multi-for loop captures with mismatched lengths: expected ".*;
    var ptr: [*]u8 = zl.fmt.Udsize.write(buf[58..], prev_len);
    ptr[0..8].* = ", found ".*;
    ptr = zl.fmt.Udsize.write(ptr + 8, next_len);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicAccessInactiveField(
    expected: []const u8,
    found: []const u8,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..23].* = "access of union field '".*;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[23..], found);
    ptr[0..15].* = "' while field '".*;
    ptr = zl.fmt.strcpyEqu(ptr + 15, expected);
    ptr = zl.fmt.strcpyEqu(ptr, "' is active");
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToPointerFromInvalid(
    type_name: []const u8,
    address: usize,
    alignment: usize,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = &buf;
    ptr[0..9].* = "cast to *".*;
    if (address == 0) {
        ptr = zl.fmt.strcpyEqu(ptr + 9, type_name);
        ptr[0..30].* = " from null without 'allowzero'".*;
        ptr += 30;
    } else {
        ptr[9..15].* = "align(".*;
        ptr = zl.fmt.Udsize.write(ptr + 15, alignment);
        ptr[0..2].* = ") ".*;
        ptr = zl.fmt.strcpyEqu(ptr + 2, type_name);
        ptr[0..27].* = " with incorrect alignment: ".*;
        ptr = zl.fmt.Udsize.write(ptr + 27, address);
        ptr[0..4].* = " == ".*;
        ptr = zl.fmt.Udsize.write(ptr + 4, address & ~(alignment -% 1));
        ptr[0] = '+';
        ptr = zl.fmt.Udsize.write(ptr + 1, address & (alignment -% 1));
    }
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToTagFromInvalid(
    comptime Integer: type,
    type_name: []const u8,
    value: Integer,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..8].* = "cast to ".*;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[8..], type_name);
    ptr[0..20].* = " from invalid value ".*;
    ptr = zl.fmt.Udsize.write(ptr + 20, value);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToErrorFromInvalid(
    comptime From: type,
    type_name: []const u8,
    value: From,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..9].* = "cast to '".*;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[9..], type_name);
    ptr[0..7].* = "' from ".*;
    if (@typeInfo(From) == .Int) {
        ptr[7..32].* = "non-existent error-code (".*;
        ptr = zl.fmt.Udsize.write(ptr + 32, value);
        ptr[0] = ')';
        ptr += 1;
    } else {
        ptr[7] = '\'';
        ptr = zl.fmt.strcpyEqu2(ptr + 8, @typeName(From));
        ptr[0..9].* = "', error.";
        ptr = zl.fmt.strcpyEqu(ptr + 9, @errorName(value));
    }
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToIntFromInvalid(
    comptime To: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    extrema: zl.math.BestExtrema(To),
    value: From,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    const yn: bool = value < 0;
    const x: zl.math.Extrema = zl.math.extrema(To);
    var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
    ptr[0..13].* = " overflowed: ".*;
    ptr += 13;
    if (value < x.max and value > x.min) {
        ptr[0] = '(';
        ptr = zl.fmt.Udsize.write(ptr + 1, @intFromFloat(@trunc(value)));
        ptr[0] = ')';
        ptr += 1;
    }
    ptr = writeAboveOrBelowLimit(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastTruncatedData(
    comptime To: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    extrema: zl.math.BestExtrema(To),
    value: From,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    const yn: bool = value < 0;
    var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
    ptr[0..17].* = " truncated bits (".*;
    ptr = zl.fmt.Xd(From).write(ptr + 17, value);
    ptr = writeAboveOrBelowLimit(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicCastToUnsignedFromNegative(
    comptime _: type,
    to_type_name: []const u8,
    comptime From: type,
    from_type_name: []const u8,
    value: From,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
    ptr[0..18].* = " lost signedness (".*;
    ptr = zl.fmt.Xd(From).write(ptr + 18, value);
    ptr[0] = ')';
    panic_fn(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicSentinelMismatch(
    comptime Number: type,
    type_name: []const u8,
    expected: Number,
    found: Number,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(&buf, type_name);
    ptr[0..29].* = " sentinel mismatch: expected ".*;
    ptr = zl.fmt.Xd(Number).write(ptr + 29, expected);
    ptr[0..8].* = ", found ".*;
    ptr = zl.fmt.Xd(Number).write(ptr + 8, found);
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn panicExactDivisionWithRemainder(
    comptime Number: type,
    _: []const u8,
    numerator: Number,
    denominator: Number,
    st: ?*zl.builtin.StackTrace,
    ret_addr: usize,
) return_type {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    buf[0..31].* = "exact division with remainder: ".*;
    var ptr: [*]u8 = zl.fmt.Xd(Number).write(buf[31..], numerator);
    ptr[0] = '/';
    ptr = zl.fmt.Xd(Number).write(ptr + 1, denominator);
    ptr[0..4].* = " == ".*;
    ptr = zl.fmt.Xd(Number).write(ptr + 4, @divTrunc(numerator, denominator));
    ptr[0] = 'r';
    ptr = zl.fmt.Xd(Number).write(ptr + 1, @rem(numerator, denominator));
    panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
fn writeCastToFrom(
    buf: [*]u8,
    to_type_name: []const u8,
    from_type_name: []const u8,
) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..8].* = "cast to ".*;
    const ptr: [*]u8 = zl.fmt.strcpyEqu(buf + 8, to_type_name);
    ptr[0..6].* = " from ".*;
    return zl.fmt.strcpyEqu(ptr + 6, from_type_name);
}
fn writeAboveOrBelowLimit(
    buf: [*]u8,
    comptime To: type,
    to_type_name: []const u8,
    yn: bool,
    limit: To,
) [*]u8 {
    @setRuntimeSafety(false);
    buf[0..7].* = if (yn) " below ".* else " above ".*;
    var ptr: [*]u8 = zl.fmt.strcpyEqu(buf + 7, to_type_name);
    ptr[0..10].* = if (yn) " minimum (".* else " maximum (".*;
    ptr = zl.fmt.Xd(To).write(ptr + 10, limit);
    ptr[0] = ')';
    return ptr + 1;
}
fn panicArithOverflow(comptime Number: type) type {
    return struct {
        const Extrema = zl.math.BestExtrema(Number);
        const Absolute = zl.math.Absolute(Number);
        const ShiftAmount = zl.builtin.ShiftAmount(Number);

        fn add(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            const yn: bool = rhs < 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = writeOverflowed(&buf, "add overflowed ", type_name, " + ", lhs, rhs);
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn sub(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            const yn: bool = rhs > 0;
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = writeOverflowed(&buf, "sub overflowed ", type_name, " - ", lhs, rhs);
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn mul(
            type_name: []const u8,
            extrema: Extrema,
            lhs: Number,
            rhs: Number,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = writeOverflowed(&buf, "mul overflowed ", type_name, " * ", lhs, rhs);
            const yn: bool = @bitCast(
                (@intFromBool(rhs < 0) & @intFromBool(lhs > 0)) |
                    (@intFromBool(lhs < 0) & @intFromBool(rhs > 0)),
            );
            ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }

        fn shl(
            type_name: []const u8,
            value: Number,
            shift_amt: ShiftAmount,
            mask: Absolute,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            const absolute: Absolute = @bitCast(value);
            const ov_bits: u16 = @popCount(absolute & mask) -% @popCount((absolute << shift_amt) & mask);
            var buf: [256]u8 = undefined;
            buf[0..23].* = "left shift overflowed: ".*;
            var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[23..], type_name);
            ptr[0..2].* = ": ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 2, value);
            ptr[0..4].* = " << ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 4, shift_amt);
            ptr = writeShiftedOutBits(ptr, ov_bits);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn shr(
            type_name: []const u8,
            value: Number,
            shift_amt: ShiftAmount,
            mask: Absolute,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            const absolute: Absolute = @bitCast(value);
            const ov_bits: u16 = @popCount(absolute & mask) -% @popCount((absolute << shift_amt) & mask);
            var buf: [256]u8 = undefined;
            buf[0..24].* = "right shift overflowed: ".*;
            var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[24..], type_name);
            ptr[0..2].* = ": ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 2, value);
            ptr[0..4].* = " >> ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 4, shift_amt);
            ptr = writeShiftedOutBits(ptr, ov_bits);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn shiftRhs(
            type_name: []const u8,
            bit_count: u16,
            shift_amt: ShiftAmount,
            st: ?*zl.builtin.StackTrace,
            ret_addr: usize,
        ) return_type {
            @setCold(true);
            @setRuntimeSafety(false);
            var buf: [256]u8 = undefined;
            var ptr: [*]u8 = zl.fmt.strcpyEqu(&buf, type_name);
            ptr[0..23].* = " RHS of shift too big: ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 23, shift_amt);
            ptr[0..3].* = " > ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 3, bit_count);
            panic_fn(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        fn writeOverflowed(
            buf: [*]u8,
            op_name: *const [15]u8,
            type_name: []const u8,
            op_sym: *const [3]u8,
            lhs: Number,
            rhs: Number,
        ) [*]u8 {
            @setCold(true);
            @setRuntimeSafety(false);
            const res = @addWithOverflow(lhs, rhs);
            buf[0..15].* = op_name.*;
            var ptr: [*]u8 = zl.fmt.strcpyEqu(buf[15..], type_name);
            ptr[0..2].* = ": ".*;
            ptr = zl.fmt.Xd(Number).write(ptr + 2, lhs);
            ptr[0..3].* = op_sym.*;
            ptr = zl.fmt.Xd(Number).write(ptr + 3, rhs);
            if (res[1] == 0) {
                ptr[0..2].* = " (".*;
                ptr = zl.fmt.Xd(Number).write(ptr + 2, res[0]);
                ptr[0] = ')';
                ptr += 1;
            }
            return ptr;
        }
        fn writeShiftedOutBits(
            buf: [*]u8,
            ov_bits: u16,
        ) [*]u8 {
            @setCold(true);
            @setRuntimeSafety(false);
            buf[0..13].* = " shifted out ".*;
            var ptr: [*]u8 = zl.fmt.Xd(Number).write(buf + 13, ov_bits);
            ptr[0..5].* = " bits".*;
            return ptr + 4 + @intFromBool(ov_bits != 1);
        }
    };
}
