const builtin = @import("builtin");
const tab = @import("./tab.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const math = @import("./math.zig");
const debug = @import("./debug.zig");

pub const root = @import("root");

/// Determines whether this library must supply compiler function types and
/// target information.
pub const is_zig_lib: bool = @hasDecl(@import("std"), "zig_lib");

/// Determines whether the library should provide `_start`
pub const has_start_in_root: bool = @hasDecl(root, "_start");
pub const is_executable: bool = builtin.output_mode == .Exe;

/// * Determines defaults for various allocator checks.
pub const is_safe: bool = define("is_safe", bool, builtin.mode == .ReleaseSafe);
pub const is_small: bool = define("is_small", bool, builtin.mode == .ReleaseSmall);
pub const is_fast: bool = define("is_fast", bool, builtin.mode == .ReleaseFast);
/// * Determines whether `Acquire` and `Release` actions are logged by default.
/// * Determine whether signals for floating point errors should be handled
///   verbosely.
pub const is_debug: bool = define("is_debug", bool, builtin.mode == .Debug);

/// The primary reason that these constants exist is to distinguish between
/// reports from the build runner and reports from a run command.
///
/// The length of this string does not count to the length of the column.
/// Defining this string inserts `\x1b[0m` after the subject name.
pub const message_style: ?[:0]const u8 = define("message_style", ?[:0]const u8, null);
/// This text to the left of every subject name, to the right of the style.
pub const message_prefix: [:0]const u8 = define("message_prefix", [:0]const u8, "");
/// This text to the right of every string.
pub const message_suffix: [:0]const u8 = define("message_suffix", [:0]const u8, ":");
/// The total length of the subject column, to the left of the information column.
pub const message_indent: u8 = define("message_indent", u8, 16);
/// Sequence used to undo `message_style` if defined.
pub const message_no_style: [:0]const u8 = "\x1b[0m";
pub const have_stack_traces: bool = define("have_stack_traces", bool, false);
pub const want_stack_traces: bool = define("want_stack_traces", bool, builtin.mode == .Debug and !builtin.strip_debug_info);
/// Determines whether calling `panicUnwrapError` is legal.
pub const discard_errors: bool = define("discard_errors", bool, true);
/// Determines whether `assert*` functions will be called at runtime.
pub const runtime_assertions: bool = define("runtime_assertions", bool, builtin.mode == .Debug or builtin.mode == .ReleaseSafe);
/// Determines whether `static.assert*` functions will be called at comptime
/// time.
pub const comptime_assertions: bool = define("comptime_assertions", bool, builtin.mode == .Debug);
/// Determines text output in case of panic without formatting
pub const panic_messages = define("panic_messages", type, struct {
    pub const unreach: [:0]const u8 = "reached unreachable code";
    pub const unwrap_null: [:0]const u8 = "attempt to use null value";
    pub const cast_to_null: [:0]const u8 = "cast causes pointer to be null";
    pub const incorrect_alignment: [:0]const u8 = "incorrect alignment";
    pub const invalid_error_code: [:0]const u8 = "invalid error code";
    pub const cast_truncated_data: [:0]const u8 = "integer cast truncated bits";
    pub const negative_to_unsigned: [:0]const u8 = "attempt to cast negative value to unsigned integer";
    pub const integer_overflow: [:0]const u8 = "integer overflow";
    pub const shl_overflow: [:0]const u8 = "left shift overflowed bits";
    pub const shr_overflow: [:0]const u8 = "right shift overflowed bits";
    pub const divide_by_zero: [:0]const u8 = "division by zero";
    pub const exact_division_remainder: [:0]const u8 = "exact division produced remainder";
    pub const inactive_union_field: [:0]const u8 = "access of inactive union field";
    pub const integer_part_out_of_bounds: [:0]const u8 = "integer part of floating point value out of bounds";
    pub const corrupt_switch: [:0]const u8 = "switch on corrupt value";
    pub const shift_rhs_too_big: [:0]const u8 = "shift amount is greater than the type size";
    pub const invalid_enum_value: [:0]const u8 = "invalid enum value";
    pub const sentinel_mismatch: [:0]const u8 = "sentinel mismatch";
    pub const unwrap_error: [:0]const u8 = "attempt to unwrap error";
    pub const index_out_of_bounds: [:0]const u8 = "index out of bounds";
    pub const start_index_greater_than_end: [:0]const u8 = "start index is larger than end index";
    pub const for_len_mismatch: [:0]const u8 = "for loop over objects with non-equal lengths";
    pub const memcpy_len_mismatch: [:0]const u8 = "@memcpy arguments have non-equal lengths";
    pub const memcpy_alias: [:0]const u8 = "@memcpy arguments alias";
    pub const noreturn_returned: [:0]const u8 = "'noreturn' function returned";
});
pub const panic = define("panic", debug.PanicFn, debug.panic);
pub const panicSentinelMismatch = define("panicSentinelMismatch", debug.PanicSentinelMismatchFn, debug.panicSentinelMismatch);
pub const panicUnwrapError = define("panicUnwrapError", debug.PanicUnwrapErrorFn, debug.panicUnwrapError);
pub const panicOutOfBounds = define("panicOutOfBounds", debug.PanicOutOfBoundsFn, debug.panicOutOfBounds);
pub const panicStartGreaterThanEnd = define("startGreaterThanEnd", debug.PanicStartGreaterThanEndFn, debug.panicStartGreaterThanEnd);
pub const panicInactiveUnionField = define("panicInactiveUnionField", debug.PanicInactiveUnionFieldFn, debug.panicInactiveUnionField);
pub const alarm = define("alarm", debug.AlarmFn, debug.alarm);

pub const logging_default: debug.Logging.Default = define(
    "logging_default",
    debug.Logging.Default,
    .{
        // Never report attempted actions
        .Attempt = false,
        // Never report successful actions
        .Success = false,
        // Report actions where a resource is acquired when build mode is debug
        .Acquire = builtin.mode == .Debug,
        // Report actions where a resource is released when build mode is debug
        .Release = builtin.mode == .Debug,
        // Always report errors
        .Error = true,
        // Always report faults
        .Fault = true,
    },
);
/// These values (optionally) define all override field values for all logging
/// sub-types and all default field values for the general logging type.
pub const logging_override: debug.Logging.Override = define(
    "logging_override",
    debug.Logging.Override,
    .{
        .Attempt = null,
        .Success = null,
        .Acquire = null,
        .Release = null,
        .Error = null,
        .Fault = null,
    },
);

/// All enabled in build mode `Debug`.
pub const signal_handlers: debug.SignalHandlers = define(
    "signal_handlers",
    debug.SignalHandlers,
    .{
        .SegmentationFault = debug.logging_general.Fault,
        .IllegalInstruction = debug.logging_general.Fault,
        .BusError = debug.logging_general.Fault,
        .FloatingPointError = debug.logging_general.Fault,
        .Trap = logging_default.Fault,
    },
);
/// Enabled if `SegmentationFault` enabled. This is because the alternate stack
/// is only likely to be useful in the event of stack overflow, which is only
/// reported by SIGSEGV.
pub const signal_stack: ?debug.SignalAlternateStack = define(
    "signal_stack",
    ?debug.SignalAlternateStack,
    if (signal_handlers.SegmentationFault) .{} else null,
);
pub const trace: debug.Trace = define("trace", debug.Trace, .{});
pub const my_trace: debug.Trace = .{
    .Error = !builtin.strip_debug_info,
    .Fault = !builtin.strip_debug_info,
    .Signal = !builtin.strip_debug_info,
    .options = .{
        .show_line_no = true,
        .show_pc_addr = false,
        .write_sidebar = true,
        .write_caret = true,
        .break_line_count = 1,
        .context_line_count = 1,
        .tokens = .{
            .line_no = "\x1b[2m",
            .pc_addr = "\x1b[38;5;247m",
            .sidebar = "|",
            .sidebar_fill = ": ",
            .comment = "\x1b[2m",
            .syntax = &.{ .{
                .style = "",
                .tags = parse.Token.Tag.other,
            }, .{
                .style = tab.fx.color.fg.orange24,
                .tags = &.{.number_literal},
            }, .{
                .style = tab.fx.color.fg.yellow24,
                .tags = &.{.char_literal},
            }, .{
                .style = tab.fx.color.fg.light_green,
                .tags = parse.Token.Tag.strings,
            }, .{
                .style = tab.fx.color.fg.bracket,
                .tags = parse.Token.Tag.bracket,
            }, .{
                .style = tab.fx.color.fg.magenta24,
                .tags = parse.Token.Tag.operator,
            }, .{
                .style = tab.fx.color.fg.red24,
                .tags = parse.Token.Tag.builtin_fn,
            }, .{
                .style = tab.fx.color.fg.cyan24,
                .tags = parse.Token.Tag.macro_keyword,
            }, .{
                .style = tab.fx.color.fg.light_purple,
                .tags = parse.Token.Tag.call_keyword,
            }, .{
                .style = tab.fx.color.fg.redwine,
                .tags = parse.Token.Tag.container_keyword,
            }, .{
                .style = tab.fx.color.fg.white24,
                .tags = parse.Token.Tag.cond_keyword,
            }, .{
                .style = tab.fx.color.fg.yellow24,
                .tags = parse.Token.Tag.goto_keyword ++ parse.Token.Tag.value_keyword,
            } },
        },
    },
};

/// `E` must be an error type.
pub fn InternalError(comptime E: type) type {
    const U = union(enum) {
        /// Return this error for any exception
        throw: E,
        /// Abort the program for any exception
        abort,
        ignore,
        /// Input Zig error type (unused)
        Error: type,
    };
    return U;
}
/// `E` must be an Enum type.
pub fn ExternalError(comptime E: type) type {
    const T = struct {
        /// Throw error if unwrapping yields any of these values
        throw: []const E = &.{},
        /// Abort the program if unwrapping yields any of these values
        abort: []const E = &.{},
        /// Input error value type
        Enum: type = E,
    };
    return T;
}
pub fn ZigError(comptime Value: type, comptime return_codes: []const Value) type {
    var error_set: type = error{};
    for (return_codes) |error_code| {
        error_set = error_set || @Type(.{
            .ErrorSet = &[1]zig.Type.Error{.{ .name = error_code.errorName() }},
        });
    }
    return error_set;
}
/// Attempt to match a return value against a set of error codes--returning the
/// corresponding zig error on success.
pub fn zigErrorThrow(comptime Value: type, comptime values: []const Value, ret: isize) ZigError(Value, values)!void {
    const E = ZigError(Value, values);
    inline for (values) |value| {
        if (ret == @intFromEnum(value)) {
            return @field(E, value.errorName());
        }
    }
}
/// Attempt to match a return value against a set of error codes--aborting the
/// program on success.
pub fn zigErrorAbort(comptime Value: type, comptime values: []const Value, ret: isize) void {
    inline for (values) |value| {
        if (ret == @intFromEnum(value)) {
            debug.panic(value.errorName(), null, @returnAddress());
        }
    }
}
/// `S` must be a container type.
pub inline fn setErrorPolicy(
    comptime S: type,
    comptime new: InternalError(S.Error),
) void {
    static.assert(@hasDecl(S, "error_policy"));
    S.error_policy.* = new;
}
/// `S` must be a container type. This function should be called within `S`, to
/// declare a pointer with the name `error_policy`.
pub inline fn createErrorPolicy(
    comptime S: type,
    comptime new: InternalError(S.Error),
) *InternalError(S.Error) {
    static.assert(@hasDecl(S, "Error"));
    var value: *InternalError(S.Error) = ptr(InternalError(S.Error));
    value.* = new;
    return value;
}
pub fn BitCount(comptime T: type) type {
    if (@sizeOf(T) == 0) {
        return comptime_int;
    }
    const bits: T = @bitSizeOf(T);
    return @Type(.{ .Int = .{
        .bits = bits -% @clz(bits),
        .signedness = .unsigned,
    } });
}
pub fn ShiftAmount(comptime V: type) type {
    if (@sizeOf(V) == 0) {
        return comptime_int;
    }
    const bits: V = @bitSizeOf(V);
    return @Type(.{ .Int = .{
        .bits = bits -% @clz(bits -% 1),
        .signedness = .unsigned,
    } });
}
pub fn ShiftValue(comptime A: type) type {
    if (@sizeOf(A) == 0) {
        return comptime_int;
    }
    const bits: A = ~@as(A, 0);
    return @Type(.{ .Int = .{
        .bits = bits +% 1,
        .signedness = .unsigned,
    } });
}
pub fn tzcnt(comptime T: type, value: T) BitCount(T) {
    return @ctz(value);
}
pub fn lzcnt(comptime T: type, value: T) BitCount(T) {
    return @clz(value);
}
pub fn popcnt(comptime T: type, value: T) BitCount(T) {
    return @popCount(value);
}
pub fn mod(comptime T: type, numerator: anytype, denominator: anytype) T {
    return intCast(@mod(numerator, denominator));
}
pub fn rem(comptime T: type, numerator: anytype, denominator: anytype) T {
    return intCast(T, @rem(numerator, denominator));
}
pub fn int(comptime T: type, value: bool) T {
    return @intFromBool(value);
}
pub fn int2a(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @intFromBool(value1) & @intFromBool(value2);
    if (T == bool) {
        return @bitCast(ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn int2v(comptime T: type, value1: bool, value2: bool) T {
    const ret: u1 = @intFromBool(value1) | @intFromBool(value2);
    if (T == bool) {
        return @bitCast(ret);
    } else {
        return intCast(T, ret);
    }
}
pub fn int3a(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @intFromBool(value1) & @intFromBool(value2) & @intFromBool(value3);
    if (T == bool) {
        return @as(bool, @bitCast(ret));
    } else {
        return intCast(T, ret);
    }
}
pub fn int3v(comptime T: type, value1: bool, value2: bool, value3: bool) T {
    const ret: u1 = @intFromBool(value1) | @intFromBool(value2) | @intFromBool(value3);
    if (T == bool) {
        return @as(bool, @bitCast(ret));
    } else {
        return intCast(T, ret);
    }
}
pub fn ended(comptime T: type, value: T, endian: zig.Endian) T {
    if (endian == native_endian) {
        return value;
    } else {
        return @byteSwap(value);
    }
}
fn ArithWithOverflowReturn(comptime T: type) type {
    const S = struct {
        value: T,
        overflowed: bool,
    };
    return S;
}
inline fn normalAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalAddReturn(T, arg1.*, arg2);
}
inline fn normalAddReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
    if (runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        } else {
            debug.addCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn normalSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalSubReturn(T, arg1.*, arg2);
}
inline fn normalSubReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
    if (runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        } else {
            debug.subCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn normalMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = normalMulReturn(T, arg1.*, arg2);
}
inline fn normalMulReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
    if (runtime_assertions and result[1] != 0) {
        if (@inComptime()) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        } else {
            debug.mulCausedOverflowFault(T, arg1, arg2, @returnAddress());
        }
    }
    return result[0];
}
inline fn exactDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = exactDivisionReturn(T, arg1.*, arg2);
}
inline fn exactDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    const result: T = arg1 / arg2;
    const remainder: T = normalSubReturn(T, arg1, (result * arg2));
    if (runtime_assertions and remainder != 0) {
        if (@inComptime()) {
            debug.static.exactDivisionWithRemainder(T, arg1, arg2, result, remainder);
        } else {
            debug.exactDivisionWithRemainderFault(T, arg1, arg2, result, remainder, @returnAddress());
        }
    }
    return result;
}
inline fn saturatingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +|= arg2;
}
inline fn saturatingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +| arg2;
}
inline fn saturatingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -|= arg2;
}
inline fn saturatingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -| arg2;
}
inline fn saturatingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *|= arg2;
}
inline fn saturatingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *| arg2;
}
inline fn wrappingAddAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* +%= arg2;
}
inline fn wrappingAddReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 +% arg2;
}
inline fn wrappingSubAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* -%= arg2;
}
inline fn wrappingSubReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 -% arg2;
}
inline fn wrappingMulAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* *%= arg2;
}
inline fn wrappingMulReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 *% arg2;
}
inline fn normalDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* /= arg2;
}
inline fn normalDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 / arg2;
}
inline fn normalOrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 | arg2;
}
inline fn normalOrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* |= arg2;
}
inline fn normalAndReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 & arg2;
}
inline fn normalAndAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* &= arg2;
}
inline fn normalXorReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 ^ arg2;
}
inline fn normalXorAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* ^= arg2;
}
inline fn normalShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 >> intCast(ShiftAmount(T), arg2);
}
inline fn normalShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* >>= intCast(ShiftAmount(T), arg2);
}
inline fn normalShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return arg1 << intCast(ShiftAmount(T), arg2);
}
inline fn normalShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* <<= intCast(ShiftAmount(T), arg2);
}
inline fn truncatedDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divTrunc(arg1.*, arg2);
}
inline fn truncatedDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divTrunc(arg1, arg2);
}
inline fn flooredDivisionAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @divFloor(arg1.*, arg2);
}
inline fn flooredDivisionReturn(comptime T: type, arg1: T, arg2: T) T {
    return @divFloor(arg1, arg2);
}
inline fn exactShrReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shrExact(arg1, intCast(ShiftAmount(T), arg2));
}
inline fn exactShrAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shrExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
inline fn exactShlReturn(comptime T: type, arg1: T, arg2: T) T {
    return @shlExact(arg1, intCast(ShiftAmount(T), arg2));
}
inline fn exactShlAssign(comptime T: type, arg1: *T, arg2: T) void {
    arg1.* = @shlExact(arg1.*, intCast(ShiftAmount(T), arg2));
}
inline fn overflowingAddAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @addWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingAddReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @addWithOverflow(arg1, arg2);
}
inline fn overflowingSubAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @subWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingSubReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @subWithOverflow(arg1, arg2);
}
inline fn overflowingMulAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @mulWithOverflow(arg1.*, arg2);
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingMulReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @mulWithOverflow(arg1, arg2);
}
inline fn overflowingShlAssign(comptime T: type, arg1: *T, arg2: T) bool {
    const result: Overflow(T) = @shlWithOverflow(arg1.*, intCast(ShiftAmount(T), arg2));
    arg1.* = result[0];
    return result[1] != 0;
}
inline fn overflowingShlReturn(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return @shlWithOverflow(arg1, intCast(ShiftAmount(T), arg2));
}
pub fn add(comptime T: type, arg1: T, arg2: T) T {
    return normalAddReturn(T, arg1, arg2);
}
pub fn addSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingAddReturn(T, arg1, arg2);
}
pub fn addWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingAddReturn(T, arg1, arg2);
}
pub fn addEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalAddAssign(T, arg1, arg2);
}
pub fn addEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingAddAssign(T, arg1, arg2);
}
pub fn addEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingAddAssign(T, arg1, arg2);
}
pub fn addWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingAddReturn(T, arg1, arg2);
}
pub fn addEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingAddAssign(T, arg1, arg2);
}
pub fn sub(comptime T: type, arg1: T, arg2: T) T {
    return normalSubReturn(T, arg1, arg2);
}
pub fn subSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingSubReturn(T, arg1, arg2);
}
pub fn subWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingSubReturn(T, arg1, arg2);
}
pub fn subEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalSubAssign(T, arg1, arg2);
}
pub fn subEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingSubAssign(T, arg1, arg2);
}
pub fn subEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingSubAssign(T, arg1, arg2);
}
pub fn subWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingSubReturn(T, arg1, arg2);
}
pub fn subEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingSubAssign(T, arg1, arg2);
}
pub fn mul(comptime T: type, arg1: T, arg2: T) T {
    return normalMulReturn(T, arg1, arg2);
}
pub fn mulSat(comptime T: type, arg1: T, arg2: T) T {
    return saturatingMulReturn(T, arg1, arg2);
}
pub fn mulWrap(comptime T: type, arg1: T, arg2: T) T {
    return wrappingMulReturn(T, arg1, arg2);
}
pub fn mulEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalMulAssign(T, arg1, arg2);
}
pub fn mulEquSat(comptime T: type, arg1: *T, arg2: T) void {
    saturatingMulAssign(T, arg1, arg2);
}
pub fn mulEquWrap(comptime T: type, arg1: *T, arg2: T) void {
    wrappingMulAssign(T, arg1, arg2);
}
pub fn mulWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingMulReturn(T, arg1, arg2);
}
pub fn mulEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingMulAssign(T, arg1, arg2);
}
pub fn div(comptime T: type, arg1: T, arg2: T) T {
    return normalDivisionReturn(T, arg1, arg2);
}
pub fn divEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalDivisionAssign(T, arg1, arg2);
}
pub fn divExact(comptime T: type, arg1: T, arg2: T) T {
    return exactDivisionReturn(T, arg1, arg2);
}
pub fn divEquExact(comptime T: type, arg1: *T, arg2: T) void {
    return exactDivisionAssign(T, arg1, arg2);
}
pub fn divEquTrunc(comptime T: type, arg1: *T, arg2: T) void {
    truncatedDivisionAssign(T, arg1, arg2);
}
pub fn divTrunc(comptime T: type, arg1: T, arg2: T) T {
    return truncatedDivisionReturn(T, arg1, arg2);
}
pub fn divEquFloor(comptime T: type, arg1: *T, arg2: T) void {
    flooredDivisionAssign(T, arg1, arg2);
}
pub fn divFloor(comptime T: type, arg1: T, arg2: T) T {
    return flooredDivisionReturn(T, arg1, arg2);
}
pub fn @"and"(comptime T: type, arg1: T, arg2: T) T {
    return normalAndReturn(T, arg1, arg2);
}
pub fn andEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalAndAssign(T, arg1, arg2);
}
pub fn @"or"(comptime T: type, arg1: T, arg2: T) T {
    return normalOrReturn(T, arg1, arg2);
}
pub fn orEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalOrAssign(T, arg1, arg2);
}
pub fn xor(comptime T: type, arg1: T, arg2: T) T {
    return normalXorReturn(T, arg1, arg2);
}
pub fn xorEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalXorAssign(T, arg1, arg2);
}
pub fn shr(comptime T: type, arg1: T, arg2: T) T {
    return normalShrReturn(T, arg1, arg2);
}
pub fn shrEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalShrAssign(T, arg1, arg2);
}
pub fn shrExact(comptime T: type, arg1: T, arg2: T) T {
    return exactShrReturn(T, arg1, arg2);
}
pub fn shrEquExact(comptime T: type, arg1: *T, arg2: T) void {
    exactShrAssign(T, arg1, arg2);
}
pub fn shl(comptime T: type, arg1: T, arg2: T) T {
    return normalShlReturn(T, arg1, arg2);
}
pub fn shlEqu(comptime T: type, arg1: *T, arg2: T) void {
    normalShlAssign(T, arg1, arg2);
}
pub fn shlExact(comptime T: type, arg1: T, arg2: T) T {
    return exactShlReturn(T, arg1, arg2);
}
pub fn shlEquExact(comptime T: type, arg1: *T, arg2: T) void {
    exactShlAssign(T, arg1, arg2);
}
pub fn shlWithOverflow(comptime T: type, arg1: T, arg2: T) Overflow(T) {
    return overflowingShlReturn(T, arg1, arg2);
}
pub fn shlEquWithOverflow(comptime T: type, arg1: *T, arg2: T) bool {
    return overflowingShlAssign(T, arg1, arg2);
}
pub fn min(comptime T: type, arg1: T, arg2: T) T {
    if (@typeInfo(T) == .Int or @typeInfo(T) == .ComptimeInt or
        @typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat or
        @typeInfo(T) == .Vector)
    {
        return @min(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        if (@as(*const U, @ptrCast(&arg1)).* <
            @as(*const U, @ptrCast(&arg2)).*)
        {
            return arg1;
        } else {
            return arg2;
        }
    }
}
pub fn max(comptime T: type, arg1: T, arg2: T) T {
    if (@typeInfo(T) == .Int or @typeInfo(T) == .ComptimeInt or
        @typeInfo(T) == .Float or @typeInfo(T) == .ComptimeFloat or
        @typeInfo(T) == .Vector)
    {
        return @max(arg1, arg2);
    } else {
        const U: type = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
        if (@as(*const U, @ptrCast(&arg1)).* >
            @as(*const U, @ptrCast(&arg2)).*)
        {
            return arg1;
        } else {
            return arg2;
        }
    }
}
pub fn ptr(comptime T: type) *T {
    var ret: T = zero(T);
    return &ret;
}
pub fn diff(comptime T: type, arg1: T, arg2: T) T {
    return subWrap(T, max(T, arg1, arg2), min(T, arg1, arg2));
}
pub fn cmov(comptime T: type, b: bool, argt: T, argf: T) T {
    return if (b) argt else argf;
}
pub fn isComptime() bool {
    var b: bool = false;
    return @TypeOf(if (b) @as(u32, 0) else @as(u8, 0)) == u8;
}
pub inline fn ptrCast(comptime T: type, any: anytype) T {
    @setRuntimeSafety(false);
    if (@typeInfo(@TypeOf(any)).Pointer.size == .Slice) {
        return @as(T, @ptrCast(@constCast(any.ptr)));
    } else {
        return @as(T, @ptrCast(@constCast(any)));
    }
}
pub inline fn zero(comptime T: type) T {
    const data: [@sizeOf(T)]u8 align(@max(1, @alignOf(T))) = .{@as(u8, 0)} ** @sizeOf(T);
    comptime return @as(*const T, @ptrCast(&data)).*;
}
pub inline fn all(comptime T: type) T {
    const data: [@sizeOf(T)]u8 align(@max(1, @alignOf(T))) = .{~@as(u8, 0)} ** @sizeOf(T);
    comptime return @as(*const T, @ptrCast(&data)).*;
}
pub inline fn addr(any: anytype) usize {
    if (@typeInfo(@TypeOf(any)).Pointer.size == .Slice) {
        return @intFromPtr(any.ptr);
    } else {
        return @intFromPtr(any);
    }
}
pub fn anyOpaque(comptime value: anytype) *const anyopaque {
    const S: type = @TypeOf(value);
    const T = [0:value]S;
    return @typeInfo(T).Array.sentinel.?;
}
pub inline fn identity(any: anytype) @TypeOf(any) {
    return any;
}
pub inline fn equ(comptime T: type, dst: *T, src: T) void {
    dst.* = src;
}
pub inline fn arrcpy(buf: [*]u8, comptime any: anytype) u64 {
    @as(*@TypeOf(any), @ptrCast(buf)).* = any;
    return any.len;
}
pub inline fn memcpy(buf: [*]u8, slice: []const u8) void {
    mach.memcpy(buf, slice.ptr, slice.len);
}
fn @"test"(b: bool) bool {
    return b;
}
pub fn intToPtr(comptime P: type, address: u64) P {
    return @as(P, @ptrFromInt(address));
}
pub inline fn intCast(comptime T: type, value: anytype) T {
    @setRuntimeSafety(false);
    const U: type = @TypeOf(value);
    if (@bitSizeOf(T) > @bitSizeOf(U)) {
        return value;
    }
    if (runtime_assertions and value > ~@as(T, 0)) {
        debug.intCastTruncatedBitsFault(T, U, value, @returnAddress());
    }
    return @as(T, @truncate(value));
}
pub const static = struct {
    pub fn assert(comptime b: bool) void {
        if (!b) {
            @compileError(debug.about_assertion_1_s);
        }
    }
    pub fn expect(b: bool) !void {
        if (!b) {
            return error.Unexpected;
        }
    }
    fn normalAddAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingAddReturn(T, arg1.*, arg2);
        if (runtime_assertions and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalAddReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingAddReturn(T, arg1, arg2);
        if (runtime_assertions and result[1] != 0) {
            debug.static.addCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalSubAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingSubReturn(T, arg1.*, arg2);
        if (runtime_assertions and arg1.* < arg2) {
            debug.static.subCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalSubReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingSubReturn(T, arg1, arg2);
        if (runtime_assertions and result[1] != 0) {
            debug.static.subCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn normalMulAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: Overflow(T) = overflowingMulReturn(T, arg1.*, arg2);
        if (runtime_assertions and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1.*, arg2);
        }
        arg1.* = result[0];
    }
    fn normalMulReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: Overflow(T) = overflowingMulReturn(T, arg1, arg2);
        if (runtime_assertions and result[1] != 0) {
            debug.static.mulCausedOverflow(T, arg1, arg2);
        }
        return result[0];
    }
    fn exactDivisionAssign(comptime T: type, comptime arg1: *T, comptime arg2: T) void {
        const result: T = arg1.* / arg2;
        const remainder: T = static.normalSubReturn(T, arg1.*, (result * arg2));
        if (runtime_assertions and remainder != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1.*, arg2, result, remainder);
        }
        arg1.* = result;
    }
    fn exactDivisionReturn(comptime T: type, comptime arg1: T, comptime arg2: T) T {
        const result: T = arg1 / arg2;
        const remainder: T = static.normalSubReturn(T, arg1, (result * arg2));
        if (runtime_assertions and remainder != 0) {
            debug.static.exactDivisionWithRemainder(T, arg1, arg2, result, remainder);
        }
        return result;
    }
};
pub const parse = struct {
    pub const E = error{BadParse};
    pub fn ub(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 2);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'b');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 2) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn uo(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 8);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'o');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 8) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ud(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 10) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ux(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .unsigned);
        const sig_fig_list: []const T = sigFigList(T, 16);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'x');
        while (idx != str.len) : (idx +%= 1) {
            value +%= fromSymbol(str[idx], 16) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    pub fn ib(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 2);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '-');
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'b');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @as(i8, @intCast(fromSymbol(str[idx], 2))) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn io(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 8);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '-');
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'o');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @as(i8, @intCast(fromSymbol(str[idx], 8))) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn id(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 10);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '-');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @as(i8, @intCast(fromSymbol(str[idx], 10))) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn ix(comptime T: type, str: []const u8) T {
        static.assert(@typeInfo(T).Int.signedness == .signed);
        const sig_fig_list: []const T = sigFigList(T, 16);
        var idx: u64 = 0;
        var value: T = 0;
        idx +%= @intFromBool(str[idx] == '-');
        idx +%= @intFromBool(str[idx] == '0');
        idx +%= @intFromBool(str[idx] == 'x');
        while (idx != str.len) : (idx +%= 1) {
            value +%= @as(i8, @intCast(fromSymbol(str[idx], 16))) * (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return if (str[0] == '-') -value else value;
    }
    pub fn fromSymbol(c: u8, comptime radix: u7) u8 {
        if (radix <= 10) {
            return c -% '0';
        } else {
            switch (c) {
                '0'...'9' => return c -% '0',
                'a'...'z' => return c -% 'a' +% 0xa,
                'A'...'Z' => return c -% 'A' +% 0xa,
                else => return radix +% 1,
            }
        }
    }
    pub inline fn fromSymbolChecked(c: u8, comptime radix: u7) !u8 {
        const value: u8 = fromSymbol(c, radix);
        if (value >= radix) {
            return error.InvalidEncoding;
        }
        return value;
    }
    fn nextSigFig(comptime T: type, prev: T, comptime radix: T) ?T {
        const mul_result: Overflow(T) = @mulWithOverflow(prev, radix);
        if (mul_result[1] != 0) {
            return null;
        }
        const add_result: Overflow(T) = @addWithOverflow(mul_result[0], radix -% 1);
        if (add_result[1] != 0) {
            return null;
        }
        return add_result[0];
    }
    pub inline fn sigFigList(comptime T: type, comptime radix: u7) []const T {
        if (comptime math.sigFigList(T, radix)) |list| {
            return list;
        }
        comptime var value: T = 0;
        comptime var ret: []const T = &.{};
        inline while (comptime nextSigFig(T, value, radix)) |next| {
            ret = ret ++ [1]T{value};
            value = next;
        } else {
            ret = ret ++ [1]T{value};
        }
        comptime return ret;
    }
    pub fn any(comptime T: type, str: []const u8) !T {
        const signed: bool = str[0] == '-';
        if (@typeInfo(T).Int.signedness == .unsigned and signed) {
            return E.BadParse;
        }
        var idx: u64 = int(u64, signed);
        const is_zero: bool = str[idx] == '0';
        idx += int(u64, is_zero);
        if (idx == str.len) {
            return 0;
        }
        switch (str[idx]) {
            'b' => return parseValidate(T, str[idx +% 1 ..], 2),
            'o' => return parseValidate(T, str[idx +% 1 ..], 8),
            'x' => return parseValidate(T, str[idx +% 1 ..], 16),
            else => return parseValidate(T, str[idx..], 10),
        }
    }
    fn parseValidate(comptime T: type, str: []const u8, comptime radix: u7) !T {
        const sig_fig_list: []const T = sigFigList(T, radix);
        var idx: u64 = 0;
        var value: T = 0;
        while (idx != str.len) : (idx +%= 1) {
            value +%= try fromSymbolChecked(str[idx], radix) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
        }
        return value;
    }
    const KV = struct { []const u8, Token.Tag };
    const keywords: [49]KV = tab.kw;
    pub const Token = struct {
        tag: Tag,
        loc: Loc,
        pub const Loc = struct {
            start: usize = 0,
            finish: usize = 0,
        };
        pub const Tag = enum {
            invalid,
            invalid_periodasterisks,
            identifier,
            string_literal,
            multiline_string_literal_line,
            char_literal,
            eof,
            builtin,
            bang,
            pipe,
            pipe_pipe,
            pipe_equal,
            equal,
            equal_equal,
            equal_angle_bracket_right,
            bang_equal,
            l_paren,
            r_paren,
            semicolon,
            percent,
            percent_equal,
            l_brace,
            r_brace,
            l_bracket,
            r_bracket,
            period,
            period_asterisk,
            ellipsis2,
            ellipsis3,
            caret,
            caret_equal,
            plus,
            plus_plus,
            plus_equal,
            plus_percent,
            plus_percent_equal,
            plus_pipe,
            plus_pipe_equal,
            minus,
            minus_equal,
            minus_percent,
            minus_percent_equal,
            minus_pipe,
            minus_pipe_equal,
            asterisk,
            asterisk_equal,
            asterisk_asterisk,
            asterisk_percent,
            asterisk_percent_equal,
            asterisk_pipe,
            asterisk_pipe_equal,
            arrow,
            colon,
            slash,
            slash_equal,
            comma,
            ampersand,
            ampersand_equal,
            question_mark,
            angle_bracket_left,
            angle_bracket_left_equal,
            angle_bracket_angle_bracket_left,
            angle_bracket_angle_bracket_left_equal,
            angle_bracket_angle_bracket_left_pipe,
            angle_bracket_angle_bracket_left_pipe_equal,
            angle_bracket_right,
            angle_bracket_right_equal,
            angle_bracket_angle_bracket_right,
            angle_bracket_angle_bracket_right_equal,
            tilde,
            number_literal,
            doc_comment,
            container_doc_comment,
            keyword_addrspace,
            keyword_align,
            keyword_allowzero,
            keyword_and,
            keyword_anyframe,
            keyword_anytype,
            keyword_asm,
            keyword_async,
            keyword_await,
            keyword_break,
            keyword_callconv,
            keyword_catch,
            keyword_comptime,
            keyword_const,
            keyword_continue,
            keyword_defer,
            keyword_else,
            keyword_enum,
            keyword_errdefer,
            keyword_error,
            keyword_export,
            keyword_extern,
            keyword_fn,
            keyword_for,
            keyword_if,
            keyword_inline,
            keyword_noalias,
            keyword_noinline,
            keyword_nosuspend,
            keyword_opaque,
            keyword_or,
            keyword_orelse,
            keyword_packed,
            keyword_pub,
            keyword_resume,
            keyword_return,
            keyword_linksection,
            keyword_struct,
            keyword_suspend,
            keyword_switch,
            keyword_test,
            keyword_threadlocal,
            keyword_try,
            keyword_union,
            keyword_unreachable,
            keyword_usingnamespace,
            keyword_var,
            keyword_volatile,
            keyword_while,
            pub const strings: []const Token.Tag = &.{
                .string_literal,
                .multiline_string_literal_line,
            };
            pub const bracket: []const Token.Tag = &.{
                .l_brace,
                .r_brace,
                .l_bracket,
                .r_bracket,
                .l_paren,
                .r_paren,
            };
            pub const operator: []const Token.Tag = &.{
                .arrow,                  .bang,
                .pipe,                   .pipe_pipe,
                .pipe_equal,             .equal,
                .equal_equal,            .bang_equal,
                .percent,                .percent_equal,
                .period_asterisk,        .caret,
                .caret_equal,            .plus,
                .plus_plus,              .plus_equal,
                .plus_percent,           .plus_percent_equal,
                .plus_pipe,              .plus_pipe_equal,
                .minus,                  .minus_equal,
                .minus_percent,          .minus_percent_equal,
                .minus_pipe,             .minus_pipe_equal,
                .asterisk,               .asterisk_equal,
                .asterisk_asterisk,      .asterisk_percent,
                .asterisk_percent_equal, .asterisk_pipe,
                .asterisk_pipe_equal,    .slash,
                .slash_equal,            .ampersand,
                .ampersand_equal,        .question_mark,
                .tilde,                  .angle_bracket_left,
                .ellipsis2,              .ellipsis3,
                .equal_angle_bracket_right, //
                .angle_bracket_left_equal,
                .angle_bracket_angle_bracket_left,
                .angle_bracket_angle_bracket_left_equal,
                .angle_bracket_angle_bracket_left_pipe,
                .angle_bracket_angle_bracket_left_pipe_equal,
                .angle_bracket_right,
                .angle_bracket_right_equal,
                .angle_bracket_angle_bracket_right,
                .angle_bracket_angle_bracket_right_equal,
            };
            pub const builtin_fn: []const Token.Tag = &.{
                .builtin,
                .keyword_align,
                .keyword_addrspace,
                .keyword_linksection,
                .keyword_callconv,
            };
            pub const macro_keyword: []const Token.Tag = &.{
                .keyword_defer,
                .keyword_async,
                .keyword_await,
                .keyword_export,
                .keyword_extern,
                .keyword_resume,
                .keyword_suspend,
                .keyword_errdefer,
                .keyword_nosuspend,
                .keyword_unreachable,
            };
            pub const container_keyword: []const Token.Tag = &.{
                .keyword_enum,
                .keyword_packed,
                .keyword_opaque,
                .keyword_struct,
                .keyword_union,
                .keyword_error,
            };
            pub const qual_keyword: []const Token.Tag = &.{
                .keyword_volatile,
                .keyword_allowzero,
            };
            pub const call_keyword: []const Token.Tag = &.{
                .keyword_asm,
                .keyword_catch,
                .keyword_inline,
                .keyword_noalias,
                .keyword_noinline,
            };
            pub const cond_keyword: []const Token.Tag = &.{
                .keyword_fn,
                .keyword_if,
                .keyword_or,
                .keyword_for,
                .keyword_and,
                .keyword_try,
                .keyword_else,
                .keyword_test,
                .keyword_while,
                .keyword_switch,
                .keyword_orelse,
                .keyword_anytype,
                .keyword_anyframe,
            };
            pub const goto_keyword: []const Token.Tag = &.{
                .keyword_break,
                .keyword_return,
                .keyword_continue,
            };
            pub const value_keyword: []const Token.Tag = &.{
                .keyword_pub,
                .keyword_var,
                .keyword_const,
                .keyword_comptime,
                .keyword_threadlocal,
                .keyword_usingnamespace,
            };
            pub const other: []const Token.Tag = &.{
                .invalid,
                .identifier,
                .container_doc_comment,
                .doc_comment,
                .invalid_periodasterisks,
                .period,
                .comma,
                .colon,
                .semicolon,
                .eof,
            };
        };
    };
    pub const TokenIterator = struct {
        buf: [:0]const u8,
        buf_pos: usize,
        inval: ?Token,
        const State = enum {
            start,
            identifier,
            builtin,
            string_literal,
            string_literal_backslash,
            multiline_string_literal_line,
            char_literal,
            char_literal_backslash,
            char_literal_hex_escape,
            char_literal_unicode_escape_saw_u,
            char_literal_unicode_escape,
            char_literal_unicode_invalid,
            char_literal_unicode,
            char_literal_end,
            backslash,
            equal,
            bang,
            pipe,
            minus,
            minus_percent,
            minus_pipe,
            asterisk,
            asterisk_percent,
            asterisk_pipe,
            slash,
            line_comment_start,
            line_comment,
            doc_comment_start,
            doc_comment,
            int,
            int_exponent,
            int_period,
            float,
            float_exponent,
            ampersand,
            caret,
            percent,
            plus,
            plus_percent,
            plus_pipe,
            angle_bracket_left,
            angle_bracket_angle_bracket_left,
            angle_bracket_angle_bracket_left_pipe,
            angle_bracket_right,
            angle_bracket_angle_bracket_right,
            period,
            period_2,
            period_asterisk,
            saw_at_sign,
        };
        pub fn next(itr: *TokenIterator) Token {
            @setRuntimeSafety(false);
            if (itr.inval) |token| {
                itr.inval = null;
                return token;
            }
            var state: State = .start;
            var ret = Token{
                .tag = .eof,
                .loc = .{ .start = itr.buf_pos },
            };
            var esc_no: usize = undefined;
            var rem_cp: usize = undefined;
            while (true) : (itr.buf_pos +%= 1) {
                const c: u8 = itr.buf[itr.buf_pos];
                switch (state) {
                    .start => switch (c) {
                        0 => {
                            if (itr.buf_pos != itr.buf.len) {
                                ret.tag = .invalid;
                                ret.loc.start = itr.buf_pos;
                                itr.buf_pos +%= 1;
                                ret.loc.finish = itr.buf_pos;
                                return ret;
                            }
                            break;
                        },
                        ' ', '\n', '\t', '\r' => ret.loc.start = itr.buf_pos +% 1,
                        '"' => {
                            state = .string_literal;
                            ret.tag = .string_literal;
                        },
                        '\'' => state = .char_literal,
                        'a'...'z', 'A'...'Z', '_' => {
                            state = .identifier;
                            ret.tag = .identifier;
                        },
                        '@' => state = .saw_at_sign,
                        '=' => state = .equal,
                        '!' => state = .bang,
                        '|' => state = .pipe,
                        '(' => {
                            ret.tag = .l_paren;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        ')' => {
                            ret.tag = .r_paren;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '[' => {
                            ret.tag = .l_bracket;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        ']' => {
                            ret.tag = .r_bracket;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        ';' => {
                            ret.tag = .semicolon;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        ',' => {
                            ret.tag = .comma;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '?' => {
                            ret.tag = .question_mark;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        ':' => {
                            ret.tag = .colon;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '%' => state = .percent,
                        '*' => state = .asterisk,
                        '+' => state = .plus,
                        '<' => state = .angle_bracket_left,
                        '>' => state = .angle_bracket_right,
                        '^' => state = .caret,
                        '\\' => {
                            state = .backslash;
                            ret.tag = .multiline_string_literal_line;
                        },
                        '{' => {
                            ret.tag = .l_brace;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '}' => {
                            ret.tag = .r_brace;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '~' => {
                            ret.tag = .tilde;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '.' => state = .period,
                        '-' => state = .minus,
                        '/' => state = .slash,
                        '&' => state = .ampersand,
                        '0'...'9' => {
                            state = .int;
                            ret.tag = .number_literal;
                        },
                        else => {
                            ret.tag = .invalid;
                            ret.loc.finish = itr.buf_pos;
                            itr.buf_pos +%= 1;
                            return ret;
                        },
                    },
                    .saw_at_sign => switch (c) {
                        '"' => {
                            ret.tag = .identifier;
                            state = .string_literal;
                        },
                        'a'...'z', 'A'...'Z', '_' => {
                            state = .builtin;
                            ret.tag = .builtin;
                        },
                        else => {
                            ret.tag = .invalid;
                            break;
                        },
                    },
                    .ampersand => switch (c) {
                        '=' => {
                            ret.tag = .ampersand_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .ampersand;
                            break;
                        },
                    },
                    .asterisk => switch (c) {
                        '=' => {
                            ret.tag = .asterisk_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '*' => {
                            ret.tag = .asterisk_asterisk;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '%' => state = .asterisk_percent,
                        '|' => state = .asterisk_pipe,
                        else => {
                            ret.tag = .asterisk;
                            break;
                        },
                    },
                    .asterisk_percent => switch (c) {
                        '=' => {
                            ret.tag = .asterisk_percent_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .asterisk_percent;
                            break;
                        },
                    },
                    .asterisk_pipe => switch (c) {
                        '=' => {
                            ret.tag = .asterisk_pipe_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .asterisk_pipe;
                            break;
                        },
                    },
                    .percent => switch (c) {
                        '=' => {
                            ret.tag = .percent_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .percent;
                            break;
                        },
                    },
                    .plus => switch (c) {
                        '=' => {
                            ret.tag = .plus_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '+' => {
                            ret.tag = .plus_plus;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '%' => state = .plus_percent,
                        '|' => state = .plus_pipe,
                        else => {
                            ret.tag = .plus;
                            break;
                        },
                    },
                    .plus_percent => switch (c) {
                        '=' => {
                            ret.tag = .plus_percent_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .plus_percent;
                            break;
                        },
                    },
                    .plus_pipe => switch (c) {
                        '=' => {
                            ret.tag = .plus_pipe_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .plus_pipe;
                            break;
                        },
                    },
                    .caret => switch (c) {
                        '=' => {
                            ret.tag = .caret_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .caret;
                            break;
                        },
                    },
                    .identifier => switch (c) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                        else => {
                            if (keyword(itr.buf[ret.loc.start..itr.buf_pos])) |tag| {
                                ret.tag = tag;
                            }
                            break;
                        },
                    },
                    .builtin => switch (c) {
                        'a'...'z', 'A'...'Z', '_', '0'...'9' => {},
                        else => break,
                    },
                    .backslash => switch (c) {
                        '\\' => state = .multiline_string_literal_line,
                        else => {
                            ret.tag = .invalid;
                            break;
                        },
                    },
                    .string_literal => switch (c) {
                        '\\' => state = .string_literal_backslash,
                        '"' => {
                            itr.buf_pos +%= 1;
                            break;
                        },
                        0 => {
                            if (itr.buf_pos == itr.buf.len) {
                                ret.tag = .invalid;
                                break;
                            } else {
                                itr.checkChar();
                            }
                        },
                        '\n' => {
                            ret.tag = .invalid;
                            break;
                        },
                        else => itr.checkChar(),
                    },
                    .string_literal_backslash => switch (c) {
                        0, '\n' => {
                            ret.tag = .invalid;
                            break;
                        },
                        else => state = .string_literal,
                    },
                    .char_literal => switch (c) {
                        0 => {
                            ret.tag = .invalid;
                            break;
                        },
                        '\\' => state = .char_literal_backslash,
                        '\'', 0x80...0xbf, 0xf8...0xff => {
                            ret.tag = .invalid;
                            break;
                        },
                        0xc0...0xdf => {
                            rem_cp = 1;
                            state = .char_literal_unicode;
                        },
                        0xe0...0xef => {
                            rem_cp = 2;
                            state = .char_literal_unicode;
                        },
                        0xf0...0xf7 => {
                            rem_cp = 3;
                            state = .char_literal_unicode;
                        },
                        '\n' => {
                            ret.tag = .invalid;
                            break;
                        },
                        else => state = .char_literal_end,
                    },
                    .char_literal_backslash => switch (c) {
                        0, '\n' => {
                            ret.tag = .invalid;
                            break;
                        },
                        'x' => {
                            state = .char_literal_hex_escape;
                            esc_no = 0;
                        },
                        'u' => state = .char_literal_unicode_escape_saw_u,
                        else => state = .char_literal_end,
                    },
                    .char_literal_hex_escape => switch (c) {
                        '0'...'9', 'a'...'f', 'A'...'F' => {
                            esc_no +%= 1;
                            if (esc_no == 2) {
                                state = .char_literal_end;
                            }
                        },
                        else => {
                            ret.tag = .invalid;
                            break;
                        },
                    },
                    .char_literal_unicode_escape_saw_u => switch (c) {
                        0 => {
                            ret.tag = .invalid;
                            break;
                        },
                        '{' => state = .char_literal_unicode_escape,
                        else => {
                            ret.tag = .invalid;
                            state = .char_literal_unicode_invalid;
                        },
                    },
                    .char_literal_unicode_escape => switch (c) {
                        0 => {
                            ret.tag = .invalid;
                            break;
                        },
                        '0'...'9', 'a'...'f', 'A'...'F' => {},
                        '}' => state = .char_literal_end,
                        else => {
                            ret.tag = .invalid;
                            state = .char_literal_unicode_invalid;
                        },
                    },
                    .char_literal_unicode_invalid => switch (c) {
                        '0'...'9', 'a'...'z', 'A'...'Z', '}' => {},
                        else => break,
                    },
                    .char_literal_end => switch (c) {
                        '\'' => {
                            ret.tag = .char_literal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .invalid;
                            break;
                        },
                    },
                    .char_literal_unicode => switch (c) {
                        0x80...0xbf => {
                            rem_cp -%= 1;
                            if (rem_cp == 0) {
                                state = .char_literal_end;
                            }
                        },
                        else => {
                            ret.tag = .invalid;
                            break;
                        },
                    },
                    .multiline_string_literal_line => switch (c) {
                        0 => break,
                        '\n' => {
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '\t' => {},
                        else => itr.checkChar(),
                    },
                    .bang => switch (c) {
                        '=' => {
                            ret.tag = .bang_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .bang;
                            break;
                        },
                    },
                    .pipe => switch (c) {
                        '=' => {
                            ret.tag = .pipe_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '|' => {
                            ret.tag = .pipe_pipe;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .pipe;
                            break;
                        },
                    },
                    .equal => switch (c) {
                        '=' => {
                            ret.tag = .equal_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '>' => {
                            ret.tag = .equal_angle_bracket_right;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .equal;
                            break;
                        },
                    },
                    .minus => switch (c) {
                        '>' => {
                            ret.tag = .arrow;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '=' => {
                            ret.tag = .minus_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '%' => state = .minus_percent,
                        '|' => state = .minus_pipe,
                        else => {
                            ret.tag = .minus;
                            break;
                        },
                    },
                    .minus_percent => switch (c) {
                        '=' => {
                            ret.tag = .minus_percent_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .minus_percent;
                            break;
                        },
                    },
                    .minus_pipe => switch (c) {
                        '=' => {
                            ret.tag = .minus_pipe_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .minus_pipe;
                            break;
                        },
                    },
                    .angle_bracket_left => switch (c) {
                        '<' => state = .angle_bracket_angle_bracket_left,
                        '=' => {
                            ret.tag = .angle_bracket_left_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .angle_bracket_left;
                            break;
                        },
                    },
                    .angle_bracket_angle_bracket_left => switch (c) {
                        '=' => {
                            ret.tag = .angle_bracket_angle_bracket_left_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        '|' => state = .angle_bracket_angle_bracket_left_pipe,
                        else => {
                            ret.tag = .angle_bracket_angle_bracket_left;
                            break;
                        },
                    },
                    .angle_bracket_angle_bracket_left_pipe => switch (c) {
                        '=' => {
                            ret.tag = .angle_bracket_angle_bracket_left_pipe_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .angle_bracket_angle_bracket_left_pipe;
                            break;
                        },
                    },
                    .angle_bracket_right => switch (c) {
                        '>' => state = .angle_bracket_angle_bracket_right,
                        '=' => {
                            ret.tag = .angle_bracket_right_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .angle_bracket_right;
                            break;
                        },
                    },
                    .angle_bracket_angle_bracket_right => switch (c) {
                        '=' => {
                            ret.tag = .angle_bracket_angle_bracket_right_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .angle_bracket_angle_bracket_right;
                            break;
                        },
                    },
                    .period => switch (c) {
                        '.' => state = .period_2,
                        '*' => state = .period_asterisk,
                        else => {
                            ret.tag = .period;
                            break;
                        },
                    },
                    .period_2 => switch (c) {
                        '.' => {
                            ret.tag = .ellipsis3;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .ellipsis2;
                            break;
                        },
                    },
                    .period_asterisk => switch (c) {
                        '*' => {
                            ret.tag = .invalid_periodasterisks;
                            break;
                        },
                        else => {
                            ret.tag = .period_asterisk;
                            break;
                        },
                    },
                    .slash => switch (c) {
                        '/' => state = .line_comment_start,
                        '=' => {
                            ret.tag = .slash_equal;
                            itr.buf_pos +%= 1;
                            break;
                        },
                        else => {
                            ret.tag = .slash;
                            break;
                        },
                    },
                    .line_comment_start => switch (c) {
                        0 => {
                            if (itr.buf_pos != itr.buf.len) {
                                ret.tag = .invalid;
                                itr.buf_pos +%= 1;
                            }
                            break;
                        },
                        '/' => state = .doc_comment_start,
                        '!' => {
                            ret.tag = .container_doc_comment;
                            state = .doc_comment;
                        },
                        '\n' => {
                            state = .start;
                            ret.loc.start = itr.buf_pos +% 1;
                        },
                        '\t' => state = .line_comment,
                        else => {
                            state = .line_comment;
                            itr.checkChar();
                        },
                    },
                    .doc_comment_start => switch (c) {
                        '/' => state = .line_comment,
                        0, '\n' => {
                            ret.tag = .doc_comment;
                            break;
                        },
                        '\t' => {
                            state = .doc_comment;
                            ret.tag = .doc_comment;
                        },
                        else => {
                            state = .doc_comment;
                            ret.tag = .doc_comment;
                            itr.checkChar();
                        },
                    },
                    .line_comment => switch (c) {
                        0 => {
                            if (itr.buf_pos != itr.buf.len) {
                                ret.tag = .invalid;
                                itr.buf_pos +%= 1;
                            }
                            break;
                        },
                        '\n' => {
                            state = .start;
                            ret.loc.start = itr.buf_pos +% 1;
                        },
                        '\t' => {},
                        else => itr.checkChar(),
                    },
                    .doc_comment => switch (c) {
                        0, '\n' => break,
                        '\t' => {},
                        else => itr.checkChar(),
                    },
                    .int => switch (c) {
                        '.' => state = .int_period,
                        '_',
                        'a'...'d',
                        'f'...'o',
                        'q'...'z',
                        'A'...'D',
                        'F'...'O',
                        'Q'...'Z',
                        '0'...'9',
                        => {},
                        'e', 'E', 'p', 'P' => state = .int_exponent,
                        else => break,
                    },
                    .int_exponent => switch (c) {
                        '-', '+' => state = .float,
                        else => {
                            itr.buf_pos -%= 1;
                            state = .int;
                        },
                    },
                    .int_period => switch (c) {
                        '_',
                        'a'...'d',
                        'f'...'o',
                        'q'...'z',
                        'A'...'D',
                        'F'...'O',
                        'Q'...'Z',
                        '0'...'9',
                        => state = .float,
                        'e', 'E', 'p', 'P' => state = .float_exponent,
                        else => {
                            itr.buf_pos -%= 1;
                            break;
                        },
                    },
                    .float => switch (c) {
                        '_',
                        'a'...'d',
                        'f'...'o',
                        'q'...'z',
                        'A'...'D',
                        'F'...'O',
                        'Q'...'Z',
                        '0'...'9',
                        => {},
                        'e', 'E', 'p', 'P' => state = .float_exponent,
                        else => break,
                    },
                    .float_exponent => switch (c) {
                        '-', '+' => state = .float,
                        else => {
                            itr.buf_pos -%= 1;
                            state = .float;
                        },
                    },
                }
            }
            if (ret.tag == .eof) {
                if (itr.inval) |token| {
                    itr.inval = null;
                    return token;
                }
                ret.loc.start = itr.buf_pos;
            }
            ret.loc.finish = itr.buf_pos;
            return ret;
        }
        fn checkChar(itr: *TokenIterator) void {
            if (itr.inval != null) {
                return;
            }
            const inval_len: u64 = itr.invalLen();
            if (inval_len == 0) {
                return;
            }
            itr.inval = .{
                .tag = .invalid,
                .loc = .{
                    .start = itr.buf_pos,
                    .finish = itr.buf_pos +% inval_len,
                },
            };
        }
        fn invalLen(itr: *TokenIterator) u8 {
            const byte: u8 = itr.buf[itr.buf_pos];
            if (byte < 0x80) {
                // Removed carriage return tolerance.
                return @intFromBool(byte <= 0x1F) | @intFromBool(byte == 0x7F);
            } else {
                const len: u8 = switch (byte) {
                    0b0000_0000...0b0111_1111 => 1,
                    0b1100_0000...0b1101_1111 => 2,
                    0b1110_0000...0b1110_1111 => 3,
                    0b1111_0000...0b1111_0111 => 4,
                    else => return 1,
                };
                if (itr.buf_pos +% len > itr.buf.len) {
                    return @as(u8, @intCast(itr.buf.len -% itr.buf_pos));
                }
                const bytes: []const u8 = itr.buf[itr.buf_pos .. itr.buf_pos +% len];
                if (len == 2) {
                    var value: u32 = bytes[0] & 0b00011111;
                    if (bytes[1] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[1] & 0b00111111;
                    if (value < 0x80 or value == 0x85) {
                        return len;
                    }
                } else //
                if (len == 3) {
                    var value: u32 = bytes[0] & 0b00001111;
                    if (bytes[1] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[1] & 0b00111111;
                    if (bytes[2] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[2] & 0b00111111;
                    if (value < 0x800) {
                        return len;
                    }
                    if (0xd800 <= value and value <= 0xdfff) {
                        return len;
                    }
                    if (value == 0x2028 or value == 0x2029) {
                        return len;
                    }
                } else //
                if (len == 4) {
                    var value: u32 = bytes[0] & 0b00000111;
                    if (bytes[1] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[1] & 0b00111111;
                    if (bytes[2] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[2] & 0b00111111;
                    if (bytes[3] & 0b11000000 != 0b10000000) {
                        return len;
                    }
                    value <<= 6;
                    value |= bytes[3] & 0b00111111;
                    if (value < 0x10000 or value > 0x10FFFF) {
                        return len;
                    }
                }
                itr.buf_pos +%= len -% 1;
            }
            return 0;
        }
    };
    pub fn lexeme(tag: Token.Tag) ?[]const u8 {
        switch (tag) {
            .invalid_periodasterisks => return ".**",
            .bang => return "!",
            .pipe => return "|",
            .pipe_pipe => return "||",
            .pipe_equal => return "|=",
            .equal => return "=",
            .equal_equal => return "==",
            .equal_angle_bracket_right => return "=>",
            .bang_equal => return "!=",
            .l_paren => return "(",
            .r_paren => return ")",
            .semicolon => return ";",
            .percent => return "%",
            .percent_equal => return "%=",
            .l_brace => return "{",
            .r_brace => return "}",
            .l_bracket => return "[",
            .r_bracket => return "]",
            .period => return ".",
            .period_asterisk => return ".*",
            .ellipsis2 => return "..",
            .ellipsis3 => return "...",
            .caret => return "^",
            .caret_equal => return "^=",
            .plus => return "+",
            .plus_plus => return "++",
            .plus_equal => return "+=",
            .plus_percent => return "+%",
            .plus_percent_equal => return "+%=",
            .plus_pipe => return "+|",
            .plus_pipe_equal => return "+|=",
            .minus => return "-",
            .minus_equal => return "-=",
            .minus_percent => return "-%",
            .minus_percent_equal => return "-%=",
            .minus_pipe => return "-|",
            .minus_pipe_equal => return "-|=",
            .asterisk => return "*",
            .asterisk_equal => return "*=",
            .asterisk_asterisk => return "**",
            .asterisk_percent => return "*%",
            .asterisk_percent_equal => return "*%=",
            .asterisk_pipe => return "*|",
            .asterisk_pipe_equal => return "*|=",
            .arrow => return "->",
            .colon => return ":",
            .slash => return "/",
            .slash_equal => return "/=",
            .comma => return ",",
            .ampersand => return "&",
            .ampersand_equal => return "&=",
            .question_mark => return "?",
            .angle_bracket_left => return "<",
            .angle_bracket_left_equal => return "<=",
            .angle_bracket_angle_bracket_left => return "<<",
            .angle_bracket_angle_bracket_left_equal => return "<<=",
            .angle_bracket_angle_bracket_left_pipe => return "<<|",
            .angle_bracket_angle_bracket_left_pipe_equal => return "<<|=",
            .angle_bracket_right => return ">",
            .angle_bracket_right_equal => return ">=",
            .angle_bracket_angle_bracket_right => return ">>",
            .angle_bracket_angle_bracket_right_equal => return ">>=",
            .tilde => return "~",
            .keyword_addrspace => return "addrspace",
            .keyword_align => return "align",
            .keyword_allowzero => return "allowzero",
            .keyword_and => return "and",
            .keyword_anyframe => return "anyframe",
            .keyword_anytype => return "anytype",
            .keyword_asm => return "asm",
            .keyword_async => return "async",
            .keyword_await => return "await",
            .keyword_break => return "break",
            .keyword_callconv => return "callconv",
            .keyword_catch => return "catch",
            .keyword_comptime => return "comptime",
            .keyword_const => return "const",
            .keyword_continue => return "continue",
            .keyword_defer => return "defer",
            .keyword_else => return "else",
            .keyword_enum => return "enum",
            .keyword_errdefer => return "errdefer",
            .keyword_error => return "error",
            .keyword_export => return "export",
            .keyword_extern => return "extern",
            .keyword_fn => return "fn",
            .keyword_for => return "for",
            .keyword_if => return "if",
            .keyword_inline => return "inline",
            .keyword_noalias => return "noalias",
            .keyword_noinline => return "noinline",
            .keyword_nosuspend => return "nosuspend",
            .keyword_opaque => return "opaque",
            .keyword_or => return "or",
            .keyword_orelse => return "orelse",
            .keyword_packed => return "packed",
            .keyword_pub => return "pub",
            .keyword_resume => return "resume",
            .keyword_return => return "return",
            .keyword_linksection => return "linksection",
            .keyword_struct => return "struct",
            .keyword_suspend => return "suspend",
            .keyword_switch => return "switch",
            .keyword_test => return "test",
            .keyword_threadlocal => return "threadlocal",
            .keyword_try => return "try",
            .keyword_union => return "union",
            .keyword_unreachable => return "unreachable",
            .keyword_usingnamespace => return "usingnamespace",
            .keyword_var => return "var",
            .keyword_volatile => return "volatile",
            .keyword_while => return "while",
            else => return null,
        }
    }
    pub fn symbol(tag: Token.Tag) []const u8 {
        switch (tag) {
            .invalid => return "invalid bytes",
            .identifier => return "an identifier",
            .char_literal => return "a character literal",
            .eof => return "EOF",
            .builtin => return "a builtin function",
            .number_literal => return "a number literal",
            .string_literal,
            .multiline_string_literal_line,
            => return "a string literal",
            .doc_comment,
            .container_doc_comment,
            => return "a document comment",
            else => return tag.lexeme(),
        }
    }
    pub fn keyword(str: []const u8) ?Token.Tag {
        lo: for (keywords) |kv| {
            if (kv[0].len != str.len) {
                continue;
            }
            for (str, kv[0]) |x, y| {
                if (x != y) {
                    continue :lo;
                }
            }
            return kv[1];
        }
        return null;
    }
};
/// Return an absolute path to a project file.
pub fn absolutePath(comptime relative: [:0]const u8) [:0]const u8 {
    return root.build_root ++ "/" ++ relative;
}
pub fn VirtualAddressSpace() type {
    if (!@hasDecl(root, "AddressSpace")) {
        @compileError(
            "toplevel address space required:\n" ++
                "declare 'pub const AddressSpace = <zig_lib>.spec.address_space.regular_128;' in program root\n" ++
                "address spaces are required by high level features with managed memory",
        );
    }
    return root.AddressSpace;
}
pub const Version = struct {
    major: u32,
    minor: u32,
    patch: u32 = 0,
    pub const Range = struct {
        min: Version,
        max: Version,
        pub fn includesVersion(range: Range, version: Version) bool {
            if (range.min.order(version) == .gt) {
                return false;
            }
            if (range.max.order(version) == .lt) {
                return false;
            }
            return true;
        }
        pub fn isAtLeast(range: Range, version: Version) ?bool {
            if (range.min.order(version) != .lt) {
                return true;
            }
            if (range.max.order(version) == .lt) {
                return false;
            }
            return null;
        }
    };
    const Order = enum { lt, gt, eq };
    pub fn order(lhs: Version, rhs: Version) Order {
        if (lhs.major < rhs.major) {
            return .lt;
        }
        if (lhs.major > rhs.major) {
            return .gt;
        }
        if (lhs.minor < rhs.minor) {
            return .lt;
        }
        if (lhs.minor > rhs.minor) {
            return .gt;
        }
        if (lhs.patch < rhs.patch) {
            return .lt;
        }
        if (lhs.patch > rhs.patch) {
            return .gt;
        }
        return .eq;
    }
    pub fn parseVersion(text: []const u8) !Version {
        var idx: usize = 0;
        var pos: usize = 0;
        while (idx < text.len) : (idx +%= 1) {
            switch (text[idx]) {
                '.' => if (pos == 2) break else {
                    pos +%= 1;
                },
                '0'...'9' => {},
                else => break,
            }
        }
        const digits: []const u8 = text[0..idx];
        if (idx == 0) return error.InvalidVersion;
        idx = 0;
        const major: usize = blk: {
            while (idx < digits.len and digits[idx] != '.') idx +%= 1;
            break :blk idx;
        };
        idx +%= 1;
        const minor: usize = blk: {
            while (idx < digits.len and digits[idx] != '.') idx +%= 1;
            break :blk idx;
        };
        const patch: u64 = digits.len;
        const major_digits: []const u8 = digits[0..major];
        const minor_digits: []const u8 =
            if (major +% 1 < minor) digits[major +% 1 .. minor] else "";
        const patch_digits: []const u8 =
            if (minor +% 1 < patch) digits[minor +% 1 .. patch] else "";
        const major_val: u64 = parse.ud(u64, major_digits);
        const minor_val: u64 = if (minor_digits.len != 0) parse.ud(u64, minor_digits) else 0;
        const patch_val: u64 = if (minor_digits.len != 0) parse.ud(u64, patch_digits) else 0;
        if (major_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (minor_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (patch_val > ~@as(u32, 0)) {
            return error.Overflow;
        }
        if (major_digits.len == 0) {
            return error.InvalidVersion;
        }
        return Version{
            .major = @as(u32, @intCast(major_val)),
            .minor = @as(u32, @intCast(minor_val)),
            .patch = @as(u32, @intCast(patch_val)),
        };
    }
};
fn Overflow(comptime T: type) type {
    return struct { T, u1 };
}
pub const native_endian: zig.Endian = switch (builtin.cpu.arch) {
    .avr,
    .arm,
    .aarch64_32,
    .aarch64,
    .amdgcn,
    .amdil,
    .amdil64,
    .bpfel,
    .csky,
    .xtensa,
    .hexagon,
    .hsail,
    .hsail64,
    .kalimba,
    .le32,
    .le64,
    .mipsel,
    .mips64el,
    .msp430,
    .nvptx,
    .nvptx64,
    .sparcel,
    .tcele,
    .powerpcle,
    .powerpc64le,
    .r600,
    .riscv32,
    .riscv64,
    .x86,
    .x86_64,
    .wasm32,
    .wasm64,
    .xcore,
    .thumb,
    .spir,
    .spir64,
    .renderscript32,
    .renderscript64,
    .shave,
    .ve,
    .spu_2,
    .spirv32,
    .spirv64,
    .dxil,
    .loongarch32,
    .loongarch64,
    => .Little,
    .arc,
    .armeb,
    .aarch64_be,
    .bpfeb,
    .m68k,
    .mips,
    .mips64,
    .powerpc,
    .powerpc64,
    .thumbeb,
    .sparc,
    .sparc64,
    .tce,
    .lanai,
    .s390x,
    => |tag| @compileError("Unsupported architecture: " ++ @tagName(tag)),
};
/// The following definitions must match the compiler definitions, or else bad things will happen.
const zig = if (is_zig_lib) zig_lib else std_lib;
const zig_lib = struct {
    pub const StackTrace = struct { index: usize, instruction_addresses: []usize };
    pub const GlobalLinkage = enum { Internal, Strong, Weak, LinkOnce };
    pub const SymbolVisibility = enum { default, hidden, protected };
    pub const AtomicOrder = enum { Unordered, Monotonic, Acquire, Release, AcqRel, SeqCst };
    pub const ReduceOp = enum { And, Or, Xor, Min, Max, Add, Mul };
    pub const AtomicRmwOp = enum { Xchg, Add, Sub, And, Nand, Or, Xor, Max, Min };
    pub const CodeModel = enum { default, tiny, small, kernel, medium, large };
    pub const OptimizeMode = enum { Debug, ReleaseSafe, ReleaseFast, ReleaseSmall };
    pub const CallingConvention = enum(u8) {
        /// This is the default Zig calling convention used when not using `export` on `fn`
        /// and no other calling convention is specified.
        Unspecified,
        /// Matches the C ABI for the target.
        /// This is the default calling convention when using `export` on `fn`
        /// and no other calling convention is specified.
        C,
        /// This makes a function not have any function prologue or epilogue,
        /// making the function itself uncallable in regular Zig code.
        /// This can be useful when integrating with assembly.
        Naked,
        /// Functions with this calling convention are called asynchronously,
        /// as if called as `async function()`.
        Async,
        /// Functions with this calling convention are inlined at all call sites.
        Inline,
        /// x86-only.
        Interrupt,
        Signal,
        /// x86-only.
        Stdcall,
        /// x86-only.
        Fastcall,
        /// x86-only.
        Vectorcall,
        /// x86-only.
        Thiscall,
        /// ARM Procedure Call Standard (obsolete)
        /// ARM-only.
        APCS,
        /// ARM Architecture Procedure Call Standard (current standard)
        /// ARM-only.
        AAPCS,
        /// ARM Architecture Procedure Call Standard Vector Floating-Point
        /// ARM-only.
        AAPCSVFP,
        /// x86-64-only.
        SysV,
        /// x86-64-only.
        Win64,
        /// AMD GPU, NVPTX, or SPIR-V kernel
        Kernel,
    };
    pub const AddressSpace = enum(u5) {
        // CPU address spaces.
        generic,
        gs,
        fs,
        ss,
        // GPU address spaces.
        global,
        constant,
        param,
        shared,
        local,
        // AVR address spaces.
        flash,
        flash1,
        flash2,
        flash3,
        flash4,
        flash5,
    };
    pub const SourceLocation = struct {
        file: [:0]const u8,
        fn_name: [:0]const u8,
        line: u32,
        column: u32,
    };
    pub const TypeId = @typeInfo(Type).Union.tag_type.?;
    pub const Type = union(enum) {
        Type: void,
        Void: void,
        Bool: void,
        NoReturn: void,
        Int: Int,
        Float: Float,
        Pointer: Pointer,
        Array: Array,
        Struct: Struct,
        ComptimeFloat: void,
        ComptimeInt: void,
        Undefined: void,
        Null: void,
        Optional: Optional,
        ErrorUnion: ErrorUnion,
        ErrorSet: ErrorSet,
        Enum: Enum,
        Union: Union,
        Fn: Fn,
        Opaque: Opaque,
        Frame: Frame,
        AnyFrame: AnyFrame,
        Vector: Vector,
        EnumLiteral: void,
        pub const Int = struct { signedness: Signedness, bits: u16 };
        pub const Float = struct { bits: u16 };
        pub const Pointer = struct {
            size: Size,
            is_const: bool,
            is_volatile: bool,
            alignment: comptime_int,
            address_space: AddressSpace,
            child: type,
            is_allowzero: bool,
            sentinel: ?*const anyopaque,
            pub const Size = enum(u2) { One, Many, Slice, C };
        };
        pub const Array = struct {
            len: comptime_int,
            child: type,
            sentinel: ?*const anyopaque,
        };
        pub const ContainerLayout = enum(u2) { Auto, Extern, Packed };
        pub const StructField = struct {
            name: []const u8,
            type: type,
            default_value: ?*const anyopaque,
            is_comptime: bool,
            alignment: comptime_int,
        };
        pub const Struct = struct {
            layout: ContainerLayout,
            backing_integer: ?type = null,
            fields: []const StructField,
            decls: []const Declaration,
            is_tuple: bool,
        };
        pub const Optional = struct { child: type };
        pub const ErrorUnion = struct { error_set: type, payload: type };
        pub const Error = struct { name: []const u8 };
        pub const ErrorSet = ?[]const Error;
        pub const EnumField = struct {
            name: []const u8,
            value: comptime_int,
        };
        pub const Enum = struct {
            tag_type: type,
            fields: []const EnumField,
            decls: []const Declaration,
            is_exhaustive: bool,
        };
        pub const UnionField = struct {
            name: []const u8,
            type: type,
            alignment: comptime_int,
        };
        pub const Union = struct {
            layout: ContainerLayout,
            tag_type: ?type,
            fields: []const UnionField,
            decls: []const Declaration,
        };
        pub const Fn = struct {
            calling_convention: CallingConvention,
            alignment: comptime_int,
            is_generic: bool,
            is_var_args: bool,
            return_type: ?type,
            params: []const Param,
            pub const Param = struct {
                is_generic: bool,
                is_noalias: bool,
                type: ?type,
            };
        };
        pub const Opaque = struct { decls: []const Declaration };
        pub const Frame = struct { function: *const anyopaque };
        pub const AnyFrame = struct { child: ?type };
        pub const Vector = struct { len: comptime_int, child: type };
        pub const Declaration = struct { name: []const u8, is_pub: bool };
    };
    pub const FloatMode = enum { Strict, Optimized };
    pub const Endian = enum { Big, Little };
    pub const Signedness = enum { signed, unsigned };
    pub const OutputMode = enum { Exe, Lib, Obj };
    pub const LinkMode = enum { Static, Dynamic };
    pub const WasiExecModel = enum { command, reactor };
    pub const CallModifier = enum {
        /// Equivalent to function call syntax.
        auto,
        /// Equivalent to async keyword used with function call syntax.
        async_kw,
        /// Prevents tail call optimization. This guarantees that the return
        /// address will point to the callsite, as opposed to the callsite's
        /// callsite. If the call is otherwise required to be tail-called
        /// or inlined, a compile error is emitted instead.
        never_tail,
        /// Guarantees that the call will not be inlined. If the call is
        /// otherwise required to be inlined, a compile error is emitted instead.
        never_inline,
        /// Asserts that the function call will not suspend. This allows a
        /// non-async function to call an async function.
        no_async,
        /// Guarantees that the call will be generated with tail call optimization.
        /// If this is not possible, a compile error is emitted instead.
        always_tail,
        /// Guarantees that the call will be inlined at the callsite.
        /// If this is not possible, a compile error is emitted instead.
        always_inline,
        /// Evaluates the call at compile-time. If the call cannot be completed at
        /// compile-time, a compile error is emitted instead.
        compile_time,
    };
    pub const VaListAarch64 = @compileError("VaList not supported");
    pub const VaListHexagon = @compileError("VaList not supported");
    pub const VaListPowerPc = @compileError("VaList not supported");
    pub const VaListS390x = @compileError("VaList not supported");
    pub const VaListX86_64 = @compileError("VaList not supported");
    pub const VaList = @compileError("VaList not supported");
    pub const PrefetchOptions = struct {
        /// Whether the prefetch should prepare for a read or a write.
        rw: Rw = .read,
        /// The data's locality in an inclusive range from 0 to 3.
        ///
        /// 0 means no temporal locality. That is, the data can be immediately
        /// dropped from the cache after it is accessed.
        ///
        /// 3 means high temporal locality. That is, the data should be kept in
        /// the cache as it is likely to be accessed again soon.
        locality: u2 = 3,
        /// The cache that the prefetch should be performed on.
        cache: Cache = .data,
        pub const Rw = enum(u1) { read, write };
        pub const Cache = enum(u1) { instruction, data };
    };
    pub const ExportOptions = struct {
        name: []const u8,
        linkage: GlobalLinkage = .Strong,
        section: ?[]const u8 = null,
        visibility: SymbolVisibility = .default,
    };
    pub const ExternOptions = struct {
        name: []const u8,
        library_name: ?[]const u8 = null,
        linkage: GlobalLinkage = .Strong,
        is_thread_local: bool = false,
    };
    pub const CompilerBackend = enum(u64) {
        /// It is allowed for a compiler implementation to not reveal its identity,
        /// in which case this value is appropriate. Be cool and make sure your
        /// code supports `other` Zig compilers!
        other = 0,
        /// The original Zig compiler created in 2015 by Andrew Kelley. Implemented
        /// in C++. Used LLVM. Deleted from the ZSF ziglang/zig codebase on
        /// December 6th, 2022.
        stage1 = 1,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// LLVM backend.
        stage2_llvm = 2,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// backend that generates C source code.
        /// Note that one can observe whether the compilation will output C code
        /// directly with `object_format` value rather than the `compiler_backend` value.
        stage2_c = 3,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// WebAssembly backend.
        stage2_wasm = 4,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// arm backend.
        stage2_arm = 5,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// x86_64 backend.
        stage2_x86_64 = 6,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// aarch64 backend.
        stage2_aarch64 = 7,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// x86 backend.
        stage2_x86 = 8,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// riscv64 backend.
        stage2_riscv64 = 9,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// sparc64 backend.
        stage2_sparc64 = 10,
        /// The reference implementation self-hosted compiler of Zig, using the
        /// spirv backend.
        stage2_spirv64 = 11,
        _,
    };
    pub const TestFn = struct {
        name: []const u8,
        func: *const fn () anyerror!void,
        async_frame_size: ?usize,
    };
    pub const Mode = OptimizeMode;
};
const std_lib = struct {
    const std = @import("std");
    pub const StackTrace = std.builtin.StackTrace;
    pub const GlobalLinkage = std.builtin.GlobalLinkage;
    pub const SymbolVisibility = std.builtin.SymbolVisibility;
    pub const AtomicOrder = std.builtin.AtomicOrder;
    pub const ReduceOp = std.builtin.ReduceOp;
    pub const AtomicRmwOp = std.builtin.AtomicRmwOp;
    pub const CodeModel = std.builtin.CodeModel;
    pub const OptimizeMode = std.builtin.OptimizeMode;
    pub const CallingConvention = std.builtin.CallingConvention;
    pub const AddressSpace = std.builtin.AddressSpace;
    pub const SourceLocation = std.builtin.SourceLocation;
    pub const TypeId = std.builtin.TypeId;
    pub const Type = std.builtin.Type;
    pub const FloatMode = std.builtin.FloatMode;
    pub const Endian = std.builtin.Endian;
    pub const Signedness = std.builtin.Signedness;
    pub const OutputMode = std.builtin.OutputMode;
    pub const LinkMode = std.builtin.LinkMode;
    pub const WasiExecModel = std.builtin.WasiExecModel;
    pub const CallModifier = std.builtin.CallModifier;
    pub const PrefetchOptions = std.builtin.PrefetchOptions;
    pub const ExportOptions = std.builtin.ExportOptions;
    pub const ExternOptions = std.builtin.ExternOptions;
    pub const CompilerBackend = std.builtin.CompilerBackend;
    pub const TestFn = std.builtin.TestFn;
    pub const Mode = std.builtin.Mode;
};
pub usingnamespace zig;
pub usingnamespace builtin;

pub fn define(comptime symbol: []const u8, comptime T: type, comptime default: T) T {
    return if (@hasDecl(root, symbol)) @field(root, symbol) else default;
}
