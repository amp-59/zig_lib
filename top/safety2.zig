const math = @import("math.zig");
const meta = @import("meta.zig");
const safety = @import("safety.zig");
const builtin = @import("builtin.zig");

/// First:
///     Default settings may be changed.
///
///     Arbitrary groupings may be changed.
///
///     Names of functions, function parameters, fields, types, and
///     compile commands may be changed.
///
const PanicCause = union(enum) {
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
};
const RuntimeSafetyCheck = struct {
    mismatched_arguments: ?bool = null,
    reached_unreachable: ?bool = null,
    accessed_invalid_memory: ?bool = null,
    mismatched_sentinel: ?bool = null,
    arith_lost_precision: ?bool = null,
    arith_overflowed: ?bool = null,
    cast_from_invalid: ?bool = null,
};
fn PanicData(comptime panic_extra_cause: PanicCause) type {
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
        .accessed_out_of_order => @call(.never_inline, safety.panicAccessOutOfOrder, .{
            data.start, data.finish, st, ret_addr,
        }),
        .accessed_out_of_bounds => @call(.never_inline, safety.panicAccessOutOfBounds, .{
            data.index, data.length, st, ret_addr,
        }),
        .accessed_inactive_field => @call(.never_inline, safety.panicAccessInactiveField, .{
            data.expected, data.found, st, ret_addr,
        }),
        .discarded_error => @call(.never_inline, safety.panicUnwrappedError, .{
            data, st, ret_addr,
        }),
        .memcpy_argument_aliasing => @call(.never_inline, safety.panicMemcpyArgumentsAlias, .{
            data.dest_start, data.dest_len, data.src_start, data.src_len, st, ret_addr,
        }),
        .memcpy_argument_lengths_mismatched => @call(.never_inline, safety.panicMismatchedMemcpyArgumentLengths, .{
            data.dest_len, data.src_len, st, ret_addr,
        }),
        .for_loop_capture_lengths_mismatched => @call(.never_inline, safety.panicMismatchedForLoopCaptureLengths, .{
            data.prev_len, data.next_len, st, ret_addr,
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
        .shift_amt_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).rhs, .{
            @typeName(int_type), data.bit_count, data.shift_amt, st, ret_addr,
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
