const math = @import("./math.zig");
const meta = @import("./meta.zig");
const safety = @import("./safety.zig");
const builtin = @import("./builtin.zig");
const PanicCause = union(enum) {
    message,
    unwrapped_error,
    /// These are efficient for formatted panics.
    access_out_of_bounds,
    access_out_of_order,
    access_inactive_field,
    memcpy_arguments_alias,
    mismatched_memcpy_lengths,
    mismatched_for_loop_lengths,
    /// These might be extended to be more useful.
    corrupt_switch,
    shift_amt_overflowed,
    /// These only require the equivalent of `panic_messages`.
    unwrapped_null,
    returned_noreturn,
    reached_unreachable,
    /// These are more expensive.
    mul_overflowed: type,
    add_overflowed: type,
    sub_overflowed: type,
    shl_overflowed: type,
    shr_overflowed: type,
    div_with_remainder: type,
    /// May be signed or unsigned and any size.
    mismatched_sentinel: type,
    /// *Test code compiled from source. Any composite.
    mismatched_non_scalar_sentinel: type,
    /// Always from `@typeInfo(type).Enum.tag_type`
    cast_to_enum_from_invalid: type,
    /// Always from `u16`
    cast_to_error_from_invalid: type,
    /// Always from `usize`
    cast_to_pointer_from_invalid: type,
    cast_to_int_from_invalid: struct {
        /// Int
        to: type,
        /// Float
        from: type,
    },
    cast_truncated_data: struct {
        /// Int
        to: type,
        /// Int
        from: type,
    },
    cast_to_unsigned_from_negative: struct {
        /// Int{ .signedness = .unsigned }
        to: type,
        /// Int{ .signedness = .signed }
        from: type,
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
    }
}
pub inline fn panic(comptime cause: PanicCause, data: PanicData(cause), st: ?*builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    switch (cause) {
        .returned_noreturn => {
            builtin.alarm("function declared 'noreturn' returned", st, ret_addr);
        },
        .reached_unreachable => {
            builtin.alarm("reached unreachable code", st, ret_addr);
        },
        .shift_amt_overflowed => {
            builtin.alarm("shift amount overflowed", st, ret_addr);
        },
        .corrupt_switch => {
            builtin.alarm("switch on corrupt value", st, ret_addr);
        },
        .unwrapped_null => {
            builtin.alarm("attempt to use null value", st, ret_addr);
        },
        .message => |message| builtin.alarm(message, st, ret_addr),
        .unwrapped_error => @call(.never_inline, safety.panicUnwrappedError, .{
            data, st, ret_addr,
        }),
        .access_out_of_order => @call(.never_inline, safety.panicAccessOutOfOrder, .{
            data.start, data.finish, st, ret_addr,
        }),
        .access_out_of_bounds => @call(.never_inline, safety.panicAccessOutOfBounds, .{
            data.index, data.length, st, ret_addr,
        }),
        .access_inactive_field => @call(.never_inline, safety.panicAccessInactiveField, .{
            data.expected, data.found, st, ret_addr,
        }),
        .memcpy_arguments_alias => @call(.never_inline, safety.panicMemcpyArgumentsAlias, .{
            data.dest_start, data.dest_finish, data.src_start, data.src_finish, st, ret_addr,
        }),
        .mismatched_for_loop_lengths => @call(.never_inline, safety.panicMismatchedForLoopLengths, .{
            data.prev_capture_length, data.next_capture_length, st, ret_addr,
        }),
        .mismatched_memcpy_lengths => @call(.never_inline, safety.panicMismatchedMemcpyArgumentsLength, .{
            data.dest_length, data.src_length, st, ret_addr,
        }),
        .cast_to_pointer_from_invalid => |child_type| @call(.never_inline, safety.panicCastToPointerFromInvalid, .{
            @typeName(child_type), data, @alignOf(child_type), st, ret_addr,
        }),
        .mismatched_sentinel => |child_type| @call(.never_inline, safety.panicSentinelMismatch, .{
            meta.BestNum(child_type), @typeName(child_type), data.expected, data.found, st, ret_addr,
        }),
        .cast_to_int_from_invalid => |num_types| @call(.never_inline, safety.panicCastToIntFromInvalid, .{
            meta.BestFloat(num_types.from), @typeName(num_types.from), data, st, ret_addr,
        }),
        .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, safety.panicCastToTagFromInvalid, .{
            meta.BestInt(enum_type), @typeName(enum_type), data, st, ret_addr,
        }),
        .cast_to_error_from_invalid => |error_type| @call(.never_inline, safety.panicCastToTagFromInvalid, .{
            meta.BestInt(error_type), @typeName(error_type), data, st, ret_addr,
        }),
        .mismatched_non_scalar_sentinel => |child_type| @call(.never_inline, safety.panicNonScalarSentinelMismatch, .{
            child_type, data.expected, data.found, st, ret_addr,
        }),
        .mul_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).mul, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .add_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).add, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .sub_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).sub, .{
            @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, st, ret_addr,
        }),
        .shl_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).shl, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .shr_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).shr, .{
            @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), st, ret_addr,
        }),
        .div_with_remainder => |num_type| @call(.never_inline, safety.panicExactDivisionWithRemainder, .{
            meta.BestNum(num_type), @typeName(num_type), data.numerator, data.denominator, st, ret_addr,
        }),
        .cast_to_unsigned_from_negative => |int_types| @call(.never_inline, safety.panicCastToUnsignedFromNegative, .{
            meta.BestNum(int_types.to),   @typeName(int_types.to),
            meta.BestNum(int_types.from), @typeName(int_types.from),
            data,                         st,
            ret_addr,
        }),
        .cast_truncated_data => |num_types| @call(.never_inline, safety.panicCastTruncatedData, .{
            meta.BestNum(num_types.to),     @typeName(num_types.to),
            meta.BestNum(num_types.from),   @typeName(num_types.from),
            math.bestExtrema(num_types.to), data,
            st,                             ret_addr,
        }),
    }
}
