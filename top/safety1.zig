const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const math = @import("./math.zig");
const meta = @import("./meta.zig");
const safety = @import("./safety.zig");
const builtin = @import("./builtin.zig");
const Panic = union(enum(usize)) {
    message: []const u8,
    unwrapped_error: []const u8,
    access_out_of_bounds: struct {
        index: usize,
        length: usize,
    },
    access_out_of_order: struct {
        start: usize,
        finish: usize,
    },
    mismatched_memcpy_lengths: struct {
        dest_length: usize,
        src_length: usize,
    },
    mismatched_for_loop_lengths: struct {
        prev_index: usize,
        prev_capture_length: usize,
        next_capture_length: usize,
    },
    access_inactive_field: struct {
        expected: []const u8,
        found: []const u8,
    },
    memcpy_arguments_alias: struct {
        dest_start: usize,
        dest_finish: usize,
        src_start: usize,
        src_finish: usize,
    },
    unwrapped_null,
    returned_noreturn,
    reached_unreachable,
    shift_amt_overflowed,
    corrupt_switch,
};
const PanicExtraCause = union(enum) {
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
    cast_to_pointer_from_invalid: type,
    cast_to_int_from_invalid: struct {
        from: type,
        to: type,
    },
    cast_truncated_data: struct {
        from: type,
        to: type,
    },
    cast_to_unsigned_from_negative: struct {
        from: type,
        to: type,
    },
};
fn PanicExtraData(comptime panic_extra_cause: PanicExtraCause) type {
    switch (panic_extra_cause) {
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
        .cast_to_int_from_invalid => |num_type| {
            return num_type.from;
        },
        .cast_to_pointer_from_invalid => {
            return usize;
        },
    }
}
pub fn panic(payload: Panic, st: ?*builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [256]u8 = undefined;
    var ptr: [*]u8 = buf[0..];
    switch (payload) {
        .message => |message| return builtin.alarm(message, st, ret_addr),
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
        .unwrapped_error => |error_name| {
            ptr[0..17].* = "unwrapped error: ".*;
            ptr = fmt.strcpyEqu(buf[17..], error_name);
        },
        .access_out_of_order => |params| {
            ptr[0..12].* = "start index ".*;
            ptr = fmt.writeUdsize(ptr + 12, params.start);
            ptr[0..26].* = " is larger than end index ".*;
            ptr = fmt.writeUdsize(ptr + 26, params.finish);
        },
        .access_out_of_bounds => |params| {
            if (params.length == 0) {
                ptr[0..10].* = "indexing (".*;
                ptr = fmt.writeUdsize(ptr + 10, params.index);
                ptr = fmt.strcpyEqu(ptr, ") into empty array");
            } else {
                ptr[0..6].* = "index ".*;
                ptr = fmt.writeUdsize(ptr + 6, params.index);
                ptr[0..15].* = " above maximum ".*;
                ptr = fmt.writeUdsize(ptr + 15, params.length -% 1);
            }
        },
        .access_inactive_field => |params| {
            ptr[0..23].* = "access of union field '".*;
            ptr = fmt.strcpyEqu(ptr + 23, params.found);
            ptr[0..15].* = "' while field '".*;
            ptr = fmt.strcpyEqu(ptr + 15, params.expected);
            ptr = fmt.strcpyEqu(ptr, "' is active");
        },
        .mismatched_for_loop_lengths => |params| {
            ptr[0..49].* = "multi-for loop captures with mismatched lengths: ".*;
            ptr = fmt.writeUdsize(ptr + 49, params.prev_capture_length);
            ptr[0..4].* = " != ".*;
            ptr = fmt.writeUdsize(ptr + 4, params.next_capture_length);
        },
        .mismatched_memcpy_lengths => |params| {
            ptr[0..65].* = "@memcpy destination and source with mismatched lengths: expected ".*;
            ptr = fmt.writeUdsize(ptr + 65, params.dest_length);
            ptr[0..8].* = ", found ".*;
            ptr = fmt.writeUdsize(ptr + 8, params.src_length);
        },
        .memcpy_arguments_alias => |params| {
            ptr[0..32].* = "@memcpy arguments alias between ".*;
            ptr[0..32].* = "@memcpy arguments alias between ".*;
            ptr = fmt.writeUxsize(buf[32..], @max(params.dest_start, params.src_start));
            ptr[0..5].* = " and ".*;
            ptr = fmt.writeUxsize(ptr + 5, @min(params.dest_finish, params.src_finish));
        },
    }
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
}
pub inline fn panicExtra(comptime cause: PanicExtraCause, data: PanicExtraData(cause), st: ?*builtin.StackTrace, ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    switch (cause) {
        .cast_to_pointer_from_invalid => |child_type| @call(.never_inline, safety.panicCastToPointerFromInvalid, .{
            @typeName(child_type), data, @alignOf(child_type), st, ret_addr,
        }),
        .mismatched_sentinel => |child_type| @call(.never_inline, safety.panicSentinelMismatch, .{
            meta.BestNum(child_type), @typeName(child_type), data.expected, data.found, st, ret_addr,
        }),
        .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, safety.panicCastToTagFromInvalid, .{
            meta.BestInt(enum_type), @typeName(enum_type), data, st, ret_addr,
        }),
        .cast_to_error_from_invalid => |error_type| @call(.never_inline, safety.panicCastToTagFromInvalid, .{
            meta.BestInt(error_type), @typeName(error_type), data, st, ret_addr,
        }),
        .cast_to_int_from_invalid => |num_types| @call(.never_inline, safety.panicCastToIntFromInvalid, .{
            meta.BestFloat(num_types.from), @typeName(num_types.from), data, st, ret_addr,
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
