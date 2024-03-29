const tab = @import("tab.zig");
const mem = @import("mem.zig");
const fmt = @import("fmt.zig");
const bits = @import("bits.zig");
const math = @import("math.zig");
const meta = @import("meta.zig");
const proc = @import("proc.zig");
const builtin = @import("builtin.zig");
const debug = @This();
pub const Error = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    IntCastTruncatedBits,
    ExactDivisionWithRemainder,
    IncorrectAlignment,
};
pub const Unexpected = error{
    UnexpectedValue,
    UnexpectedLength,
};
pub const AlarmFn = @TypeOf(alarm);
pub const PanicFn = @TypeOf(panic);
pub const PanicExtraFn = @TypeOf(panic_extra.panicSignal);
pub const PanicOutOfBoundsFn = @TypeOf(panic_extra.panicOutOfBounds);
pub const PanicSentinelMismatchFn = @TypeOf(panic_extra.panicSentinelMismatch);
pub const PanicStartGreaterThanEndFn = @TypeOf(panic_extra.panicStartGreaterThanEnd);
pub const PanicInactiveUnionFieldFn = @TypeOf(panic_extra.panicInactiveUnionField);
pub const PanicUnwrapErrorFn = @TypeOf(panic_extra.panicUnwrapError);
pub const SignalHandlers = packed struct {
    /// Report receipt of signal 11 SIGSEGV.
    SegmentationFault: bool,
    /// Report receipt of signal 4 SIGILL.
    IllegalInstruction: bool,
    /// Report receipt of signal 7 SIGBUS.
    BusError: bool,
    /// Report receipt of signal 8 SIGFPE.
    FloatingPointError: bool,
    /// Report receipt of signal 5 SIGTRAP.
    Trap: bool,
};
pub const SignalAlternateStack = struct {
    /// Address of lowest mapped byte.
    addr: usize,
    /// Initial mapping length.
    len: usize,
};
pub const Trace = struct {
    /// Show trace on alarm.
    Error: bool = true,
    /// Show trace on panic.
    Fault: bool = true,
    /// Show trace on signal.
    Signal: bool = true,
    /// Control output formatting.
    options: Options = .{},
    pub const Options = struct {
        /// Unwind this many frames. max_depth = 0 is unlimited.
        max_depth: u8 = 0,
        /// Write this many lines of source code context.
        context_line_count: u8 = 0,
        /// Allow this many blank lines between source code contexts.
        break_line_count: u8 = 0,
        /// Show the source line number on source lines.
        show_line_no: bool = true,
        /// Show the program counter on the caret line.
        show_pc_addr: bool = false,
        /// Control sidebar inclusion and appearance.
        write_sidebar: bool = true,
        /// Write extra line to indicate column.
        write_caret: bool = true,
        /// Write full source location context for reference trace entries
        /// (Compile errors only)
        write_full_ref_trace: bool = false,
        /// Define composition of stack trace text.
        tokens: Tokens = .{},
        pub const Tokens = struct {
            /// Apply this style to the line number text.
            line_no: ?[]const u8 = null,
            /// Apply this style to the program counter address text.
            pc_addr: ?[]const u8 = null,
            /// Separate context information from sidebar with this text.
            sidebar: []const u8 = "|",
            /// Substitute absent `line_no` or `pc_addr` address with this text.
            sidebar_fill: []const u8 = " ",
            /// Indicate column number with this text.
            caret: []const u8 = tab.fx.color.fg.light_green ++ "^" ++ tab.fx.none,
            /// Fill text between `sidebar` and `caret` with this character.
            caret_fill: []const u8 = " ",
            /// Apply style for non-token text (comments)
            comment: ?[]const u8 = null,
            /// Apply `style` to every Zig token tag in `tags`.
            syntax: ?[]const Mapping = null,
            pub const Mapping = struct {
                style: []const u8 = "",
                tags: []const builtin.parse.Token.Tag = &meta.tagList(builtin.parse.Token.Tag),
            };
        };
    };
};
pub const logging_general: Logging.Default = .{
    .Attempt = builtin
        .logging_override.Attempt orelse builtin
        .logging_default.Attempt,
    .Success = builtin
        .logging_override.Success orelse builtin
        .logging_default.Success,
    .Acquire = builtin
        .logging_override.Acquire orelse builtin
        .logging_default.Acquire,
    .Release = builtin
        .logging_override.Release orelse builtin
        .logging_default.Release,
    .Error = builtin
        .logging_override.Error orelse builtin
        .logging_default.Error,
    .Fault = builtin
        .logging_override.Fault orelse builtin
        .logging_default.Fault,
};
pub const Logging = packed struct {
    pub const Default = packed struct {
        /// Report attempted actions
        Attempt: bool,
        /// Report major successful actions
        Success: bool,
        /// Report actions which acquire a finite resource
        Acquire: bool,
        /// Report actions which release a finite resource
        Release: bool,
        /// Report actions which throw an error
        Error: bool,
        /// Report actions which terminate the program
        Fault: bool,
    };
    pub const Override = struct {
        /// Report attempted actions
        Attempt: ?bool = null,
        /// Report major successful actions
        Success: ?bool = null,
        /// Report actions which acquire a finite resource
        Acquire: ?bool = null,
        /// Report actions which release a finite resource
        Release: ?bool = null,
        /// Report actions which throw an error
        Error: ?bool = null,
        /// Report actions which terminate the program
        Fault: ?bool = null,
    };
    pub fn Field(comptime Spec: type) type {
        return @TypeOf(@field(@as(Spec, undefined), "logging"));
    }
    pub usingnamespace LoggingExtra;
};
pub fn loggingTypeTypes() []const type {
    var ret: []const type = &.{};
    var bit_size_of: u16 = 0;
    while (true) : (bit_size_of +%= 1) {
        var fields: @TypeOf(@typeInfo(Logging.Default).Struct.fields) = &.{};
        const logging: Logging.Default = @as(Logging.Default, @bitCast(bits));
        inline for (@typeInfo(Logging.Default).Struct.fields) |field| {
            if (@field(logging, field.name)) {
                fields = fields ++ .{field};
            }
        }
        if (@popCount(bits) <= 1) {
            continue;
        }
        if (!logging.Error and !logging.Fault) {
            continue;
        }
        ret = ret ++ .{@Type(.{ .Struct = .{
            .layout = .Packed,
            .fields = fields,
            .decls = &.{},
            .is_tuple = false,
        } })};
        if (logging.Acquire and logging.Release and
            logging.Attempt and logging.Error and logging.Fault)
        {
            break;
        }
    }
    return ret;
}
pub fn assert(b: bool) void {
    if (!b) {
        if (@inComptime()) {
            @compileError("assertion failed\n");
        } else {
            @panic("assertion failed\n");
        }
    }
}
pub fn assertBelow(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 >= arg2) {
        debug.comparisonFailedFault(T, " < ", arg1, arg2, @returnAddress());
    }
}
pub fn assertBelowOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 > arg2) {
        debug.comparisonFailedFault(T, " <= ", arg1, arg2, @returnAddress());
    }
}
pub fn assertEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and !mem.testEqual(T, arg1, arg2)) {
        debug.comparisonFailedFault(T, " == ", arg1, arg2, @returnAddress());
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and mem.testEqual(T, arg1, arg2)) {
        debug.comparisonFailedFault(T, " != ", arg1, arg2, @returnAddress());
    }
}
pub fn assertAboveOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 < arg2) {
        debug.comparisonFailedFault(T, " >= ", arg1, arg2, @returnAddress());
    }
}
pub fn assertAbove(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 <= arg2) {
        debug.comparisonFailedFault(T, " > ", arg1, arg2, @returnAddress());
    }
}
pub fn assertEqualWord(arg1: *align(1) const u32, arg2: *align(1) const u32) void {
    assert(arg1.* == arg2.*);
}
pub fn assertEqualMemory(comptime T: type, arg1: T, arg2: T) void {
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Int, .Enum => assertEqual(T, arg1, arg2),
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                assertEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name));
            }
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                assertEqual(tag_type, arg1, arg2);
                switch (arg1) {
                    inline else => |value, tag| {
                        assertEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                assertEqualMemory(optional_info.child, arg1.?, arg2.?);
            } else {
                assert(arg1 == null and arg2 == null);
            }
        },
        .Array => |array_info| {
            assertEqual([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = mem.indexOfSentinel(arg1);
                    const len2: usize = mem.indexOfSentinel(arg2);
                    assertEqual(usize, len1, len2);
                    if (arg1 != arg2) {
                        for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                            assertEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                .Slice => {
                    assertEqual(usize, arg1.len, arg2.len);
                    if (arg1.ptr != arg2.ptr) {
                        for (arg1, arg2) |value1, value2| {
                            assertEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                else => assertEqualMemory(pointer_info.child, arg1.*, arg2.*),
            }
        },
    }
}
pub fn expect(b: bool) debug.Unexpected!void {
    if (!b) {
        builtin.alarm(@errorName(error.UnexpectedValue), null, @returnAddress());
        return error.UnexpectedValue;
    }
}
pub fn expectBelow(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (arg1 >= arg2) {
        return debug.comparisonFailedError(T, " < ", arg1, arg2, @returnAddress());
    }
}
pub fn expectBelowOrEqual(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (arg1 > arg2) {
        return debug.comparisonFailedError(T, " <= ", arg1, arg2, @returnAddress());
    }
}
pub fn expectEqual(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (!mem.testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedError(T, " == ", arg1, arg2, @returnAddress());
    }
}
pub fn expectNotEqual(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (mem.testEqual(T, arg1, arg2)) {
        return debug.comparisonFailedError(T, " != ", arg1, arg2, @returnAddress());
    }
}
pub fn expectAboveOrEqual(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (arg1 < arg2) {
        return debug.comparisonFailedError(T, " >= ", arg1, arg2, @returnAddress());
    }
}
pub fn expectAbove(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    if (arg1 <= arg2) {
        return debug.comparisonFailedError(T, " > ", arg1, arg2, @returnAddress());
    }
}
pub fn expectError(comptime T: type, arg1: @typeInfo(T).ErrorUnion.error_set, arg2: T) debug.Unexpected!void {
    if (arg2) |payload| {
        return comparisonFailedErrorValue(@TypeOf(payload), @errorName(arg1), payload);
    } else |err| {
        if (arg1 != err) {
            return comparisonFailedErrorError(@typeName(@TypeOf(arg1)), @errorName(arg1), @errorName(err));
        }
    }
}
pub fn expectCast(comptime T: type, value: anytype) Error!T {
    @setRuntimeSafety(false);
    const extrema: math.Extrema = math.extrema(T);
    if (value > extrema.max) {
        return intCastTruncatedBitsError(T, @TypeOf(value), extrema.max, value, @returnAddress());
    }
    if (value < extrema.min) {
        return intCastTruncatedBitsError(T, @TypeOf(value), extrema.min, value, @returnAddress());
    }
    return @intCast(value);
}
pub fn expectEqualMemory(comptime T: type, arg1: T, arg2: T) debug.Unexpected!void {
    switch (@typeInfo(T)) {
        else => @compileError(@typeName(T)),
        .Void => {},
        .Int, .Enum, .Bool => try expectEqual(T, arg1, arg2),
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                comptime var field_type_info: builtin.Type = @typeInfo(field.type);
                if (field_type_info == .Pointer and
                    field_type_info.Pointer.size == .Many and
                    @hasField(T, field.name ++ "_len"))
                {
                    const len1: usize = @field(arg1, field.name ++ "_len");
                    const len2: usize = @field(arg2, field.name ++ "_len");
                    field_type_info.Pointer.size = .Slice;
                    try expectEqualMemory(@Type(field_type_info), @field(arg1, field.name)[0..len1], @field(arg2, field.name)[0..len2]);
                } else {
                    try expectEqualMemory(field.type, @field(arg1, field.name), @field(arg2, field.name));
                }
            }
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                try expectEqual(tag_type, arg1, arg2);
                switch (arg1) {
                    inline else => |value, tag| {
                        try expectEqualMemory(@TypeOf(value), value, @field(arg2, @tagName(tag)));
                    },
                }
            } else {
                @compileError(@typeName(T));
            }
        },
        .Optional => |optional_info| {
            if (arg1 != null and arg2 != null) {
                try expectEqualMemory(optional_info.child, arg1.?, arg2.?);
            } else {
                try expect(arg1 == null and arg2 == null);
            }
        },
        .Array => |array_info| {
            try expectEqual([]const array_info.child, &arg1, &arg2);
        },
        .Pointer => |pointer_info| {
            switch (pointer_info.size) {
                .Many => {
                    const len1: usize = mem.indexOfSentinel(arg1);
                    const len2: usize = mem.indexOfSentinel(arg2);
                    try expectEqual(usize, len1, len2);
                    if (arg1 != arg2) {
                        for (arg1[0..len1], arg2[0..len2]) |value1, value2| {
                            try expectEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                .Slice => {
                    try expectEqual(usize, arg1.len, arg2.len);
                    if (arg1.ptr != arg2.ptr) {
                        for (arg1, arg2) |value1, value2| {
                            try expectEqualMemory(pointer_info.child, value1, value2);
                        }
                    }
                },
                else => if (arg1 != arg2) {
                    try expectEqualMemory(pointer_info.child, arg1.*, arg2.*);
                },
            }
        },
    }
}
pub fn intCastTruncatedBitsError(comptime T: type, comptime U: type, lim: T, arg: U, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeIntCastTruncatedBits(T, U, &buf, lim, arg);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.IntCastTruncatedBits;
}
pub fn intCastTruncatedBitsFault(comptime T: type, comptime U: type, lim: T, arg: U, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeIntCastTruncatedBits(T, U, &buf, lim, arg);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn invalidEnumValueError(comptime T: type, type_name: []const u8, values: []const T, value: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeInvalidEnumValue(T, type_name, values, value);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.IntCastTruncatedBits;
}
pub fn invalidEnumValueFault(comptime T: type, type_name: []const u8, values: []const T, value: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeInvalidEnumValue(T, type_name, values, value);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn subCausedOverflowError(comptime T: type, lim: T, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeSubCausedOverflow(meta.BestInt(T), @typeName(T), &buf, lim, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.SubCausedOverflow;
}
pub fn subCausedOverflowFault(comptime T: type, lim: T, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeSubCausedOverflow(meta.BestInt(T), @typeName(T), &buf, lim, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn addCausedOverflowError(comptime T: type, lim: T, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeAddCausedOverflow(meta.BestInt(T), @typeName(T), &buf, lim, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.AddCausedOverflow;
}
pub fn addCausedOverflowFault(comptime T: type, lim: T, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeAddCausedOverflow(meta.BestInt(T), @typeName(T), &buf, lim, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn mulCausedOverflowError(comptime T: type, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeMulCausedOverflow(meta.BestInt(T), @typeName(T), &buf, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.MulCausedOverflow;
}
pub fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeMulCausedOverflow(meta.BestInt(T), @typeName(T), &buf, arg1, arg2);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn exactDivisionWithRemainderError(comptime T: type, arg1: T, arg2: T, result: T, remainder: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeExactDivisionWithRemainder(meta.BestInt(T), @typeName(T), &buf, arg1, arg2, result, remainder);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.ExactDivisionWithRemainder;
}
pub fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, remainder: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeExactDivisionWithRemainder(meta.BestInt(T), @typeName(T), &buf, arg1, arg2, result, remainder);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn incorrectAlignmentError(child_type_name: []const u8, address: usize, alignment: usize, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(false);
    const remainder: usize = address & (alignment -% 1);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeIncorrectAlignment(child_type_name, &buf, address, alignment, remainder);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.IncorrectAlignment;
}
pub fn incorrectAlignmentFault(child_type_name: []const u8, address: usize, alignment: usize, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const remainder: usize = address & (alignment -% 1);
    var buf: [4096]u8 = undefined;
    const ptr: [*]u8 = about.writeIncorrectAlignment(child_type_name, &buf, address, alignment, remainder);
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1), ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    buf[0..@typeName(T).len].* = @typeName(T).*;
    var ptr: [*]u8 = buf[@typeName(T).len..];
    ptr[0..19].* = " failed assertion: ".*;
    ptr = switch (@typeInfo(T)) {
        .Int => about.writeComparisonFailed(T, symbol, ptr + 19, arg1, arg2),
        .Enum => fmt.strcpyEqu(fmt.strcpyEqu(fmt.strcpyEqu(ptr + 19, @tagName(arg1)), symbol), @tagName(arg2)),
        .Type => fmt.strcpyEqu(fmt.strcpyEqu(fmt.strcpyEqu(ptr + 19, @typeName(arg1)), symbol), @typeName(arg2)),
        else => fmt.strcpyEqu(ptr, " unexpected value"),
    };
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
}
pub fn comparisonFailedErrorValue(comptime T: type, _: []const u8, _: T) Unexpected {
    return error.UnexpectedValue;
}
pub fn comparisonFailedErrorError(_: []const u8, _: []const u8, _: []const u8) Unexpected {
    return error.UnexpectedValue;
}
pub fn comparisonFailedError(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1), ret_addr: ?usize) Unexpected {
    @setCold(true);
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    buf[0..@typeName(T).len].* = @typeName(T).*;
    var ptr: [*]u8 = buf[@typeName(T).len..];
    ptr[0..14].* = " failed test: ".*;
    ptr = switch (@typeInfo(T)) {
        .Int => about.writeComparisonFailed(T, symbol, ptr + 14, arg1, arg2),
        .Enum => fmt.strcpyEqu(fmt.strcpyEqu(fmt.strcpyEqu(ptr + 14, @tagName(arg1)), symbol), @tagName(arg2)),
        .Type => fmt.strcpyEqu(fmt.strcpyEqu(fmt.strcpyEqu(ptr + 14, @typeName(arg1)), symbol), @typeName(arg2)),
        else => fmt.strcpyEqu(ptr, " unexpected value"),
    };
    if (@inComptime()) @compileError(fmt.slice(ptr, &buf));
    builtin.alarm(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr orelse @returnAddress());
    return error.UnexpectedValue;
}
pub fn sampleAllReports() void {
    if (false) {
        inline for (.{ u16, u32, u64, usize, i16, i32, i64, isize }) |T| {
            const arg1: comptime_int = ~@as(T, 0);
            const arg2: comptime_int = ~@as(T, 0);
            const result: T = 2;
            const remainder: T = 2;
            if (arg2 < arg1)
                expectEqual(T, arg1, arg2) catch {};
            expectNotEqual(T, arg1, arg2) catch {};
            expectAbove(T, arg1, arg2) catch {};
            expectBelow(T, arg1, arg2) catch {};
            expectAboveOrEqual(T, arg1, arg2) catch {};
            expectBelowOrEqual(T, arg1, arg2) catch {};
            subCausedOverflowError(T, arg1, arg2, null) catch {};
            addCausedOverflowError(T, arg1, arg2, null) catch {};
            mulCausedOverflowError(T, arg1, arg2, null) catch {};
            exactDivisionWithRemainderError(T, arg1, arg2, result, remainder, null) catch {};
            if (@typeInfo(T).Int.signedness == .unsigned) {
                incorrectAlignmentError(@typeName(T), arg2, remainder, null) catch {};
            }
        }
    }
    const _u8: u8 = 128;
    const _u16: u16 = 32768;
    const _u32: u32 = 2147483648;
    const _u64: u64 = ~@as(i64, 0) +% 1;
    const _i8: i8 = -128;
    const _i16: i16 = -32768;
    const _i32: i32 = -2147483648;
    const _i64: i64 = ~@as(i64, 0);
    _ = expectCast(i3, _u8) catch {};
    _ = expectCast(u3, _i8) catch {};
    _ = expectCast(i8, _u16) catch {};
    _ = expectCast(u8, _i16) catch {};
    _ = expectCast(i16, _u32) catch {};
    _ = expectCast(u16, _i32) catch {};
    _ = expectCast(i32, _u64) catch {};
    _ = expectCast(u32, _i64) catch {};
    _ = expectCast(u3, _u8) catch {};
    _ = expectCast(u8, _u16) catch {};
    _ = expectCast(u16, _u32) catch {};
    _ = expectCast(u32, _u64) catch {};
    _ = expectCast(i3, _i8) catch {};
    _ = expectCast(i8, _i16) catch {};
    _ = expectCast(i16, _i32) catch {};
    _ = expectCast(i32, _i64) catch {};
    about.faultNotice("message");
    about.errorNotice(@errorName(error.Error));
    about.errorFaultNotice(@errorName(error.Error), "message");
    about.faultRcNotice("message", 2);
    about.errorRcNotice(@errorName(error.Error), 1);
    about.errorFaultRcNotice(@errorName(error.Error), "message", 2);
}
pub fn write(buf: []const u8) void {
    if (@inComptime()) {
        @compileError(buf);
    } else {
        asm volatile (
            \\syscall # write
            :
            : [_] "{rax}" (1), // linux sys_write
              [_] "{rdi}" (builtin.debug_write_fd orelse @compileError("debug.write disabled")), // stderr
              [_] "{rsi}" (buf.ptr),
              [_] "{rdx}" (buf.len),
            : "rcx", "r11", "memory", "rax"
        );
    }
}
pub fn read(comptime n: u64) struct { buf: [n]u8, len: u64 } {
    var buf: [n]u8 = undefined;
    return .{
        .buf = buf,
        .len = asm volatile (
            \\syscall # read
            : [_] "={rax}" (-> usize),
            : [_] "{rax}" (0), // linux sys_read
              [_] "{rdi}" (0), // stdin
              [_] "{rsi}" (&buf),
              [_] "{rdx}" (n),
            : "rcx", "r11", "memory"
        ),
    };
}
const special = struct {
    /// Used by panic functions if executable is static linked with special
    /// module object `trace.o`.
    extern fn printStackTrace(*const Trace, usize, usize) void;
    extern fn printSourceCodeAtAddress(*const Trace, usize) void;
    extern fn printSourceCodeAtAddresses(*const Trace, usize, [*]usize, usize) void;
    pub const trace = @import("trace.zig");
};
pub const printStackTrace = blk: {
    if (builtin.strip_debug_info)
        @compileError("missing debug information")
    else {
        if (builtin.want_stack_traces and
            !builtin.have_stack_traces and
            builtin.output_mode == .Exe)
        {
            break :blk special.trace.printStackTrace;
        } else {
            break :blk special.printStackTrace;
        }
    }
};
pub const printSourceCodeAtAddress = blk: {
    if (builtin.strip_debug_info)
        @compileError("missing debug information")
    else {
        if (builtin.want_stack_traces and
            !builtin.have_stack_traces and
            builtin.output_mode == .Exe)
        {
            break :blk special.trace.printSourceCodeAtAddress;
        } else {
            break :blk special.printSourceCodeAtAddress;
        }
    }
};
pub const printSourceCodeAtAddresses = blk: {
    if (builtin.strip_debug_info)
        @compileError("missing debug information")
    else {
        if (builtin.want_stack_traces and
            !builtin.have_stack_traces and
            builtin.output_mode == .Exe)
        {
            break :blk special.trace.printSourceCodeAtAddresses;
        } else {
            break :blk special.printSourceCodeAtAddresses;
        }
    }
};
pub noinline fn alarm(error_name: []const u8, st: @TypeOf(@errorReturnTrace()), ret_addr: ?usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    if (builtin.want_stack_traces and logging_general.Error) {
        if (ret_addr) |addr| {
            printStackTrace(&builtin.trace, addr, 0);
        } else {
            if (st) |trace| {
                printSourceCodeAtAddresses(&builtin.trace, 0, trace.instruction_addresses.ptr, trace.index);
            }
        }
    }
    @call(.always_inline, about.errorNotice, .{error_name});
}
pub noinline fn panic(message: []const u8, _: @TypeOf(@errorReturnTrace()), ret_addr: ?usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    if (builtin.want_stack_traces) {
        printStackTrace(&builtin.trace, ret_addr orelse @returnAddress(), 0);
    }
    @call(.always_inline, proc.exitGroupFault, .{ message, builtin.panic_return_value });
}
pub const panic_extra = struct {
    pub noinline fn checkNonScalarSentinel(expected: anytype, actual: @TypeOf(expected)) void {
        @setRuntimeSafety(false);
        if (!builtin.permit_non_scalar_sentinel) {
            @compileError("non-scalar sentinel type forbidden");
        }
        if (!mem.testEqual(@TypeOf(expected), expected, actual)) {
            @call(.always_inline, builtin.panicSentinelMismatch, .{ expected, actual });
        }
    }
    pub inline fn addErrRetTraceAddr(st: *builtin.StackTrace, ret_addr: usize) void {
        @setRuntimeSafety(false);
        if (st.index < st.instruction_addresses.len) {
            st.instruction_addresses[st.index] = ret_addr;
        }
        st.index +%= 1;
    }
    pub noinline fn returnError(st: *builtin.StackTrace) void {
        @setCold(true);
        @setRuntimeSafety(false);
        addErrRetTraceAddr(st, @returnAddress());
    }
    pub noinline fn panicSignal(message: []const u8, ctx_ptr: *const anyopaque) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const regs: bits.RegisterState = @as(*bits.RegisterState, @ptrFromInt(@intFromPtr(ctx_ptr) +% bits.RegisterState.offset)).*;
        if (!builtin.strip_debug_info and
            builtin.want_stack_traces and builtin.trace.Signal)
        {
            printStackTrace(&builtin.trace, regs.rip, regs.rbp);
        }
        @call(.always_inline, proc.exitGroupFault, .{ message, builtin.panic_return_value });
    }
    pub noinline fn panicOutOfBounds(idx: usize, max_len: usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..6].* = "index ".*;
        var ptr: [*]u8 = buf[5..];
        if (max_len == 0) {
            ptr[0..5].* = "ing (".*;
            ptr = fmt.Ud64.write(ptr + 5, idx);
            ptr[0..18].* = ") into empty array".*;
            ptr += 18;
        } else {
            ptr = fmt.Ud64.write(ptr + 1, idx);
            ptr[0..15].* = " above maximum ".*;
            ptr = fmt.Ud64.write(ptr + 15, max_len -% 1);
        }
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub noinline fn panicAddressAboveUpperBound(addr: usize, finish: usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..8].* = "address ".*;
        var ptr: [*]u8 = buf[8..];
        var ux64: fmt.Ux64 = .{ .value = addr };
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..19].* = " above upper bound ".*;
        ptr += 19;
        ux64.value = finish;
        ptr += ux64.formatWriteBuf(ptr);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub noinline fn panicAddressBelowLowerBound(addr: usize, start: usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..8].* = "address ".*;
        var ptr: [*]u8 = buf[8..];
        var ux64: fmt.Ux64 = .{ .value = addr };
        ptr += ux64.formatWriteBuf(ptr);
        ptr[0..19].* = " below lower bound ".*;
        ptr += 19;
        ux64.value = start;
        ptr += ux64.formatWriteBuf(ptr);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub fn panicSentinelMismatch(expected: anytype, actual: @TypeOf(expected)) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..28].* = "sentinel mismatch: expected ".*;
        var ptr: [*]u8 = buf[28..];
        ptr += fmt.any(expected).formatWriteBuf(ptr);
        ptr[0..8].* = ", found ".*;
        ptr += 8;
        ptr += fmt.any(actual).formatWriteBuf(ptr);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub noinline fn panicStartGreaterThanEnd(lower: usize, upper: usize) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..12].* = "start index ".*;
        var ptr: [*]u8 = buf[12..];
        ptr = fmt.Ud64.write(ptr, lower);
        ptr[0..26].* = " is larger than end index ".*;
        ptr += 26;
        ptr = fmt.Ud64.write(ptr, upper);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub noinline fn panicInactiveUnionField(active: anytype, wanted: @TypeOf(active)) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        const ret_addr: usize = @returnAddress();
        var buf: [1024]u8 = undefined;
        buf[0..23].* = "access of union field '".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[23..], @tagName(wanted));
        ptr[0..15].* = "' while field '".*;
        ptr += 15;
        ptr = fmt.strcpyEqu(ptr, @tagName(active));
        ptr[0..11].* = "' is active".*;
        ptr += 11;
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    pub noinline fn panicUnwrapError(st: ?*builtin.StackTrace, err: anyerror) noreturn {
        if (builtin.permit_discard_errors) {
            const ret_addr: usize = @returnAddress();
            var buf: [1024]u8 = undefined;
            buf[0..20].* = "error is discarded: ".*;
            const ptr: [*]u8 = fmt.strcpyEqu(buf[20..], @errorName(err));
            builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], st, ret_addr);
        }
        @compileError("error is discarded");
    }
};
pub noinline fn aboutWhere(about_s: []const u8, message: []const u8, ret_addr: ?usize, mb_src: ?builtin.SourceLocation) void {
    var buf: [4096]u8 = undefined;
    const pid: u32 = proc.getProcessId();
    const tid: u32 = proc.getThreadId();
    var ptr: [*]u8 = fmt.strcpyEqu(&buf, about_s);
    ptr = fmt.strcpyEqu(ptr, message);
    ptr[0..6].* = ", pid=".*;
    ptr += 6;
    ptr = fmt.Ud64.write(ptr, pid);
    if (pid != tid) {
        ptr[0..6].* = ", tid=".*;
        ptr += 6;
        ptr = fmt.Ud64.write(ptr, tid);
    }
    if (mb_src) |src| {
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr += fmt.SourceLocationFormat.init(src, ret_addr orelse @returnAddress()).formatWriteBuf(ptr);
    }
    ptr[0] = '\n';
    ptr += 1;
    write(buf[0 .. @intFromPtr(ptr) - @intFromPtr(&buf)]);
}
pub const about = struct {
    pub const ErrorSrc = @TypeOf(error_s);
    pub const ErrorDest = @TypeOf(@constCast(error_s));
    pub const ErrorPDest = @TypeOf(@constCast(error_p0_s));
    pub const FaultPDest = @TypeOf(@constCast(fault_p0_s));
    pub const error_s = "\x1b[91;1merror\x1b[0m=";
    pub const fault_p0_s = blk: {
        var lhs: [:0]const u8 = builtin.message_prefix ++ "fault" ++ builtin.message_suffix;
        const len: usize = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ builtin.message_no_style;
        break :blk lhs ++ " " ** (builtin.message_indent - len);
    };
    pub const error_p0_s = blk: {
        var lhs: [:0]const u8 = builtin.message_prefix ++ "error" ++ builtin.message_suffix;
        const len: usize = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ builtin.message_no_style;
        break :blk lhs ++ " " ** (builtin.message_indent - len);
    };
    pub const note_p0_s = blk: {
        var lhs: [:0]const u8 = builtin.message_prefix ++ "note" ++ builtin.message_suffix;
        const len: usize = lhs.len;
        lhs = "\x1b[96;1m" ++ lhs ++ builtin.message_no_style;
        break :blk lhs ++ " " ** (builtin.message_indent - len);
    };
    pub const test_1_s = "test failed";
    pub const assertion_1_s = "assertion failed";
    pub fn writeAboutError(buf: [*]u8, about_s: [:0]const u8, error_name: []const u8) [*]u8 {
        var ptr: [*]u8 = fmt.strcpyEqu(buf, about_s);
        ptr[0..error_s.len].* = error_s.*;
        return fmt.strcpyEqu(ptr + error_s.len, error_name);
    }
    pub fn aboutError(about_s: fmt.AboutSrc, error_name: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = writeAboutError(&buf, about_s, error_name);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn exitRcNotice(rc: u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = buf[fmt.about_exit_s.len..];
        buf[0..fmt.about_exit_s.len].* = fmt.about_exit_s.*;
        ptr[0..3].* = "rc=".*;
        ptr += 3;
        ptr = fmt.Ud64.write(ptr, rc);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn errorRcNotice(error_name: []const u8, rc: u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = writeAboutError(&buf, error_p0_s, error_name);
        ptr[0..5].* = ", rc=".*;
        ptr += 5;
        ptr = fmt.Ud64.write(ptr, rc);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn errorFaultRcNotice(error_name: []const u8, message: []const u8, rc: u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = writeAboutError(&buf, fault_p0_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, message);
        ptr[0..5].* = ", rc=".*;
        ptr += 5;
        ptr = fmt.Ud64.write(ptr, rc);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn errorNotice(error_name: []const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = buf[about.error_p0_s.len..];
        buf[0..about.error_p0_s.len].* = about.error_p0_s.*;
        ptr = fmt.strcpyEqu(ptr, error_name);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn faultNotice(message: []const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = buf[about.fault_p0_s.len..];
        buf[0..about.fault_p0_s.len].* = about.fault_p0_s.*;
        ptr = fmt.strcpyEqu(ptr, message);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn faultRcNotice(message: []const u8, rc: u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = buf[about.fault_p0_s.len..];
        buf[0..about.fault_p0_s.len].* = about.fault_p0_s.*;
        ptr = fmt.strcpyEqu(ptr, message);
        ptr[0..5].* = ", rc=".*;
        ptr += 5;
        ptr = fmt.Ud64.write(ptr, rc);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    pub fn errorFaultNotice(error_name: []const u8, message: []const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = writeAboutError(&buf, fault_p0_s, error_name);
        ptr[0..2].* = ", ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, message);
        ptr[0] = '\n';
        ptr += 1;
        write(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)]);
    }
    fn writeComparisonFailed(comptime T: type, symbol: []const u8, buf: [*]u8, arg1: T, arg2: T) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        const writeDec = fmt.writeDec(T);
        var ptr: [*]u8 = writeDec(buf, arg1);
        ptr = fmt.strcpyEqu(ptr, symbol);
        ptr = fmt.writeDec(T)(ptr, arg2);
        if (@abs(@min(arg1, arg2)) > 10_000) {
            ptr[0..7].* = ", i.e. ".*;
            ptr += 7;
            if (arg1 > arg2) {
                ptr = writeDec(ptr, arg1 -% arg2);
                ptr = fmt.strcpyEqu(ptr, symbol);
                ptr[0] = '0';
                ptr += 1;
            } else {
                ptr[0] = '0';
                ptr += 1;
                ptr = fmt.strcpyEqu(ptr, symbol);
                ptr = writeDec(ptr, arg2 -% arg1);
            }
        }
        return ptr;
    }
    inline fn writeIntCastTruncatedBits(comptime T: type, comptime U: type, buf: [*]u8, lim: T, arg: U) [*]u8 {
        if (@typeInfo(T).Int.signedness == @typeInfo(U).Int.signedness) {
            if (@typeInfo(T).Int.signedness == .signed) {
                return writeIntCastTruncatedBitsSignedFromSigned(T, U, buf, lim, arg);
            } else {
                return writeIntCastTruncatedBitsUnsignedFromUnsigned(T, U, buf, lim, arg);
            }
        } else {
            if (@typeInfo(T).Int.signedness == .signed) {
                return writeIntCastTruncatedBitsSignedFromUnsigned(T, U, buf, lim, arg);
            } else {
                return writeIntCastTruncatedBitsUnsignedFromSigned(T, U, buf, lim, arg);
            }
        }
    }
    fn writeIntegerCastFromTo(buf: [*]u8, from_type_name: []const u8, to_type_name: []const u8) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..18].* = "integer cast from ".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 18, from_type_name);
        ptr[0..4].* = " to ".*;
        ptr += 4;
        ptr = fmt.strcpyEqu(ptr, to_type_name);
        ptr[0..17].* = " truncated bits: ".*;
        ptr += 17;
        return ptr;
    }
    fn writeAboveOrBelowTypeExtrema(buf: [*]u8, type_name: []const u8, yn: bool) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        if (yn) {
            buf[0..7].* = " below ".*;
        } else {
            buf[0..7].* = " above ".*;
        }
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 7, type_name);
        if (yn) {
            ptr[0..9].* = " minimum ".*;
            ptr += 9;
        } else {
            ptr[0..9].* = " maximum ".*;
            ptr += 9;
        }
        return ptr;
    }
    fn writeIntCastTruncatedBitsUnsignedFromUnsigned(comptime T: type, comptime U: type, buf: [*]u8, lim: U, arg: U) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var ud: fmt.Ud(U) = .{ .value = arg };
        var ptr: [*]u8 = writeIntegerCastFromTo(buf, @typeName(U), @typeName(T));
        ptr += ud.formatWriteBuf(ptr);
        ptr = writeAboveOrBelowTypeExtrema(ptr, @typeName(T), false);
        ptr[0] = '(';
        ptr += 1;
        ud.value = lim;
        ptr += ud.formatWriteBuf(ptr);
        ptr[0] = ')';
        ptr += 1;
        return ptr;
    }
    fn writeIntCastTruncatedBitsSignedFromUnsigned(comptime T: type, comptime U: type, buf: [*]u8, lim: T, arg: U) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = writeIntegerCastFromTo(buf, @typeName(U), @typeName(T));
        ptr = fmt.Ud(U).write(ptr, arg);
        ptr = writeAboveOrBelowTypeExtrema(ptr, @typeName(T), false);
        ptr[0] = '(';
        ptr += 1;
        ptr = fmt.Id(T).write(ptr, lim);
        ptr[0] = ')';
        ptr += 1;
        return ptr;
    }
    fn writeIntCastTruncatedBitsUnsignedFromSigned(comptime T: type, comptime U: type, buf: [*]u8, lim: T, arg: U) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var ptr: [*]u8 = writeIntegerCastFromTo(buf, @typeName(U), @typeName(T));
        ptr = fmt.Id(U).write(ptr, arg);
        ptr = writeAboveOrBelowTypeExtrema(ptr, @typeName(T), arg < 0);
        ptr[0] = '(';
        ptr = fmt.Ud(T).write(ptr + 1, lim);
        ptr[0] = ')';
        ptr += 1;
        return ptr;
    }
    fn writeIntCastTruncatedBitsSignedFromSigned(comptime T: type, comptime U: type, buf: [*]u8, lim: U, arg: U) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var id: fmt.Id(U) = .{ .value = arg };
        var ptr: [*]u8 = writeIntegerCastFromTo(buf, @typeName(U), @typeName(T));
        ptr += id.formatWriteBuf(ptr);
        ptr = writeAboveOrBelowTypeExtrema(ptr, @typeName(T), arg < 0);
        ptr[0] = '(';
        ptr += 1;
        id.value = lim;
        ptr += id.formatWriteBuf(ptr);
        ptr[0] = ')';
        ptr += 1;
        return ptr;
    }
    fn writeSubCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, lim: T, arg1: T, arg2: T) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var xd: fmt.Xd(T) = .{ .value = arg1 };
        var ptr: [*]u8 = fmt.strcpyEqu(buf, what);
        ptr[0..19].* = " integer overflow: ".*;
        ptr += 19;
        ptr += xd.formatWriteBuf(ptr);
        ptr[0..3].* = " - ".*;
        ptr += 3;
        xd.value = arg2;
        ptr += xd.formatWriteBuf(ptr);
        if (@abs(@min(arg1, arg2)) > 10_000) {
            ptr[0..7].* = ", i.e. ".*;
            ptr += 7;
            xd.value = lim;
            ptr += xd.formatWriteBuf(ptr);
            ptr[0..3].* = " - ".*;
            ptr += 3;
            xd.value = (arg1 -% arg2) -% lim;
            ptr += xd.formatWriteBuf(ptr);
        }
        return ptr;
    }
    fn writeAddCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, lim: T, arg1: T, arg2: T) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var xd: fmt.Xd(T) = .{ .value = arg1 };
        var ptr: [*]u8 = fmt.strcpyEqu(buf, what);
        ptr[0..19].* = " integer overflow: ".*;
        ptr += 19;
        ptr += xd.formatWriteBuf(ptr);
        ptr[0..3].* = " + ".*;
        ptr += 3;
        xd.value = arg2;
        ptr += xd.formatWriteBuf(ptr);
        if (@abs(@min(arg1, arg2)) > 10_000) {
            ptr[0..7].* = ", i.e. ".*;
            ptr += 7;
            xd.value = lim;
            ptr += xd.formatWriteBuf(ptr);
            ptr[0..3].* = " + ".*;
            ptr += 3;
            xd.value = (arg1 +% arg2) -% lim;
            ptr += xd.formatWriteBuf(ptr);
        }
        return ptr;
    }
    fn writeMulCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var xd: fmt.Xd(T) = .{ .value = arg1 };
        var ptr: [*]u8 = fmt.strcpyEqu(buf, what);
        ptr[0..19].* = " integer overflow: ".*;
        ptr += 19;
        ptr += xd.formatWriteBuf(ptr);
        ptr[0..3].* = " * ".*;
        ptr += 3;
        xd.value = arg2;
        ptr += xd.formatWriteBuf(ptr);
        return ptr;
    }
    fn writeExactDivisionWithRemainder(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T, result: T, remainder: T) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        var xd: fmt.Xd(T) = .{ .value = arg1 };
        var ptr: [*]u8 = fmt.strcpyEqu(buf, what);
        ptr[0..34].* = ": exact division had a remainder: ".*;
        ptr += 34;
        ptr += xd.formatWriteBuf(ptr);
        ptr[0] = '/';
        ptr += 1;
        xd = .{ .value = arg2 };
        ptr += xd.formatWriteBuf(ptr);
        ptr[0..4].* = " == ".*;
        ptr += 4;
        xd = .{ .value = result };
        ptr += xd.formatWriteBuf(ptr);
        ptr[0] = 'r';
        ptr += 1;
        xd.value = remainder;
        ptr += xd.formatWriteBuf(ptr);
        return ptr;
    }
    fn writeIncorrectAlignment(type_name: []const u8, buf: [*]u8, address: usize, alignment: usize, remainder: usize) [*]u8 {
        @setRuntimeSafety(builtin.is_safe);
        buf[0..7].* = "*align(".*;
        var ptr: [*]u8 = fmt.Ud64.write(buf + 7, alignment);
        ptr[0..2].* = ") ".*;
        ptr += 2;
        ptr = fmt.strcpyEqu(ptr, type_name);
        ptr[0..23].* = ": incorrect alignment: ".*;
        ptr += 23;
        ptr = fmt.Ux64.write(ptr, address);
        ptr[0..4].* = " == ".*;
        ptr += 4;
        ptr = fmt.Ux64.write(ptr, address -% remainder);
        ptr[0] = '+';
        ptr += 1;
        ptr = fmt.Ux64.write(ptr, remainder);
        return ptr;
    }
};
const LoggingExtra = struct {
    pub const AttemptError = packed struct(u2) {
        Attempt: bool = builtin.logging_default.Attempt,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptError) AttemptError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessError = packed struct(u2) {
        Success: bool = builtin.logging_default.Success,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: SuccessError) SuccessError {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessError = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessError) AttemptSuccessError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireError = packed struct(u2) {
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AcquireError) AcquireError {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptAcquireError = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptAcquireError) AttemptAcquireError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessAcquireError = packed struct(u3) {
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: SuccessAcquireError) SuccessAcquireError {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessAcquireError = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessAcquireError) AttemptSuccessAcquireError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const ReleaseError = packed struct(u2) {
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: ReleaseError) ReleaseError {
            comptime return .{
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptReleaseError = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptReleaseError) AttemptReleaseError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessReleaseError = packed struct(u3) {
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: SuccessReleaseError) SuccessReleaseError {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessReleaseError = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessReleaseError) AttemptSuccessReleaseError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AcquireReleaseError = packed struct(u3) {
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AcquireReleaseError) AcquireReleaseError {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptAcquireReleaseError = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptAcquireReleaseError) AttemptAcquireReleaseError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const SuccessAcquireReleaseError = packed struct(u4) {
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: SuccessAcquireReleaseError) SuccessAcquireReleaseError {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptSuccessAcquireReleaseError = packed struct(u5) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        pub fn override(comptime logging: AttemptSuccessAcquireReleaseError) AttemptSuccessAcquireReleaseError {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
            };
        }
    };
    pub const AttemptFault = packed struct(u2) {
        Attempt: bool = builtin.logging_default.Attempt,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptFault) AttemptFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessFault = packed struct(u2) {
        Success: bool = builtin.logging_default.Success,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessFault) SuccessFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessFault = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessFault) AttemptSuccessFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireFault = packed struct(u2) {
        Acquire: bool = builtin.logging_default.Acquire,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AcquireFault) AcquireFault {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireFault = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireFault) AttemptAcquireFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireFault = packed struct(u3) {
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireFault) SuccessAcquireFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireFault) AttemptSuccessAcquireFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseFault = packed struct(u2) {
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: ReleaseFault) ReleaseFault {
            comptime return .{
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptReleaseFault = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptReleaseFault) AttemptReleaseFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessReleaseFault = packed struct(u3) {
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessReleaseFault) SuccessReleaseFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessReleaseFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessReleaseFault) AttemptSuccessReleaseFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireReleaseFault = packed struct(u3) {
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AcquireReleaseFault) AcquireReleaseFault {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireReleaseFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireReleaseFault) AttemptAcquireReleaseFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireReleaseFault = packed struct(u4) {
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireReleaseFault) SuccessAcquireReleaseFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireReleaseFault = packed struct(u5) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireReleaseFault) AttemptSuccessAcquireReleaseFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ErrorFault = packed struct(u2) {
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: ErrorFault) ErrorFault {
            comptime return .{
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptErrorFault = packed struct(u3) {
        Attempt: bool = builtin.logging_default.Attempt,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptErrorFault) AttemptErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessErrorFault = packed struct(u3) {
        Success: bool = builtin.logging_default.Success,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessErrorFault) SuccessErrorFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessErrorFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessErrorFault) AttemptSuccessErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireErrorFault = packed struct(u3) {
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AcquireErrorFault) AcquireErrorFault {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireErrorFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireErrorFault) AttemptAcquireErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessAcquireErrorFault = packed struct(u4) {
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessAcquireErrorFault) SuccessAcquireErrorFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessAcquireErrorFault = packed struct(u5) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Acquire: bool = builtin.logging_default.Acquire,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessAcquireErrorFault) AttemptSuccessAcquireErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const ReleaseErrorFault = packed struct(u3) {
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: ReleaseErrorFault) ReleaseErrorFault {
            comptime return .{
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptReleaseErrorFault = packed struct(u4) {
        Attempt: bool = builtin.logging_default.Attempt,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptReleaseErrorFault) AttemptReleaseErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const SuccessReleaseErrorFault = packed struct(u4) {
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: SuccessReleaseErrorFault) SuccessReleaseErrorFault {
            comptime return .{
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptSuccessReleaseErrorFault = packed struct(u5) {
        Attempt: bool = builtin.logging_default.Attempt,
        Success: bool = builtin.logging_default.Success,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptSuccessReleaseErrorFault) AttemptSuccessReleaseErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Success = builtin.logging_override.Success orelse logging.Success,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AcquireReleaseErrorFault = packed struct(u4) {
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AcquireReleaseErrorFault) AcquireReleaseErrorFault {
            comptime return .{
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
    pub const AttemptAcquireReleaseErrorFault = packed struct(u5) {
        Attempt: bool = builtin.logging_default.Attempt,
        Acquire: bool = builtin.logging_default.Acquire,
        Release: bool = builtin.logging_default.Release,
        Error: bool = builtin.logging_default.Error,
        Fault: bool = builtin.logging_default.Fault,
        pub fn override(comptime logging: AttemptAcquireReleaseErrorFault) AttemptAcquireReleaseErrorFault {
            comptime return .{
                .Attempt = builtin.logging_override.Attempt orelse logging.Attempt,
                .Acquire = builtin.logging_override.Acquire orelse logging.Acquire,
                .Release = builtin.logging_override.Release orelse logging.Release,
                .Error = builtin.logging_override.Error orelse logging.Error,
                .Fault = builtin.logging_override.Fault orelse logging.Fault,
            };
        }
    };
};
pub const spec = struct {
    pub const logging = struct {
        pub const default = struct {
            pub const verbose: Logging.Default = .{
                .Attempt = true,
                .Success = true,
                .Acquire = true,
                .Release = true,
                .Error = true,
                .Fault = true,
            };
            pub const silent: Logging.Default = .{
                .Attempt = false,
                .Success = false,
                .Acquire = false,
                .Release = false,
                .Error = false,
                .Fault = false,
            };
        };
        pub const override = struct {
            pub const verbose: Logging.Override = .{
                .Attempt = true,
                .Success = true,
                .Acquire = true,
                .Release = true,
                .Error = true,
                .Fault = true,
            };
            pub const silent: Logging.Override = .{
                .Attempt = false,
                .Success = false,
                .Acquire = false,
                .Release = false,
                .Error = false,
                .Fault = false,
            };
        };
        pub const attempt_error = struct {
            pub const verbose: debug.Logging.AttemptError =
                builtin.all(Logging.AttemptError);
            pub const silent: Logging.AttemptError =
                builtin.zero(Logging.AttemptError);
        };
        pub const attempt_fault = struct {
            pub const verbose: Logging.AttemptFault =
                builtin.all(Logging.AttemptFault);
            pub const silent: Logging.AttemptFault =
                builtin.zero(Logging.AttemptFault);
        };
        pub const attempt_success_error = struct {
            pub const verbose: Logging.AttemptSuccessError =
                builtin.all(Logging.AttemptSuccessError);
            pub const silent: Logging.AttemptSuccessError =
                builtin.zero(Logging.AttemptSuccessError);
        };
        pub const attempt_error_fault = struct {
            pub const verbose: Logging.AttemptErrorFault =
                builtin.all(Logging.AttemptErrorFault);
            pub const silent: Logging.AttemptErrorFault =
                builtin.zero(Logging.AttemptErrorFault);
        };
        pub const success_error = struct {
            pub const verbose: Logging.SuccessError =
                builtin.all(Logging.SuccessError);
            pub const silent: Logging.SuccessError =
                builtin.zero(Logging.SuccessError);
        };
        pub const success_fault = struct {
            pub const verbose: Logging.SuccessFault =
                builtin.all(Logging.SuccessFault);
            pub const silent: Logging.SuccessFault =
                builtin.zero(Logging.SuccessFault);
        };
        pub const success_error_fault = struct {
            pub const verbose: Logging.SuccessErrorFault =
                builtin.all(Logging.SuccessErrorFault);
            pub const silent: Logging.SuccessErrorFault =
                builtin.zero(Logging.SuccessErrorFault);
        };
        pub const acquire_error = struct {
            pub const verbose: Logging.AcquireError =
                builtin.all(Logging.AcquireError);
            pub const silent: Logging.AcquireError =
                builtin.zero(Logging.AcquireError);
        };
        pub const acquire_fault = struct {
            pub const verbose: Logging.AcquireFault =
                builtin.all(Logging.AcquireFault);
            pub const silent: Logging.AcquireFault =
                builtin.zero(Logging.AcquireFault);
        };
        pub const acquire_error_fault = struct {
            pub const verbose: Logging.AcquireErrorFault =
                builtin.all(Logging.AcquireErrorFault);
            pub const silent: Logging.AcquireErrorFault =
                builtin.zero(Logging.AcquireErrorFault);
        };
        pub const release_error = struct {
            pub const verbose: Logging.ReleaseError =
                builtin.all(Logging.ReleaseError);
            pub const silent: Logging.ReleaseError =
                builtin.zero(Logging.ReleaseError);
        };
        pub const release_fault = struct {
            pub const verbose: Logging.ReleaseFault =
                builtin.all(Logging.ReleaseFault);
            pub const silent: Logging.ReleaseFault =
                builtin.zero(Logging.ReleaseFault);
        };
        pub const release_error_fault = struct {
            pub const verbose: Logging.ReleaseErrorFault =
                builtin.all(Logging.ReleaseErrorFault);
            pub const silent: Logging.ReleaseErrorFault =
                builtin.zero(Logging.ReleaseErrorFault);
        };
    };
};

pub const safety = struct {
    const str = struct {
        const eql = " == ".*;
        const lost_sign = " lost signedness (".*;
        const max = " maximum (".*;
        const min = " minimum (".*;
        const above = " above ".*;
        const below = " below ".*;
        const colon = ": ".*;
        const trunc_bits = " truncated bits: ".*;
        const shr = " >> ".*;
        const shr_ov = "right shift overflowed ".*;
        const shl = " << ".*;
        const shl_ov = "left shift overflowed ".*;
        const add_ov = "add overflowed ".*;
        const add = " + ".*;
        const mul_ov = "mul overflowed ".*;
        const mul = " * ".*;
        const sub = " - ".*;
        const sub_ov = "sub overflowed ".*;
        const div_exact = "exact division with remainder: ".*;
        const bad_sent = " sentinel mismatch: expected ".*;
        const found = ", found ".*;
        const cast_to_ty = "cast to '".*;
        const from = "' from ".*;
        const from_ty = "' from '".*;
    };

    fn panicCastToPointerFromInvalid(
        address: usize,
        alignment: usize,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        var ptr: [*]u8 = &buf;
        if (address != 0) {
            ptr[0..42].* = "cast to pointer with incorrect alignment (".*;
            ptr = fmt.Udsize.write(ptr + 42, alignment);
            ptr[0..3].* = "): ".*;
            ptr = fmt.Udsize.write(ptr + 3, address);
            ptr[0..4].* = " == ".*;
            ptr = fmt.Udsize.write(ptr + 4, address & ~(alignment -% 1));
            ptr[0] = '+';
            ptr = fmt.Udsize.write(ptr + 1, address & (alignment -% 1));
        } else {
            ptr[0..40].* = "cast to null pointer without 'allowzero'".*;
            ptr += 40;
        }
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicCastToTagFromInvalid(
        comptime Integer: type,
        type_name: []const u8,
        value: Integer,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        buf[0..9].* = "cast to '".*;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[9..], type_name);
        ptr[0..21].* = "' from invalid value ".*;
        ptr = fmt.Udsize.write(ptr + 21, value);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicCastToErrorFromInvalid(
        comptime From: type,
        type_name: []const u8,
        value: From,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        buf[0..9].* = str.cast_to_ty;
        var ptr: [*]u8 = fmt.strcpyEqu(buf[9..], type_name);
        ptr[0..7].* = str.from;
        if (@typeInfo(From) == .Int) {
            ptr[7..32].* = "non-existent error-code (".*;
            ptr = fmt.Udsize.write(ptr + 32, value);
            ptr[0] = ')';
            ptr += 1;
        } else {
            ptr[7] = '\'';
            ptr = fmt.strcpyEqu2(ptr + 8, @typeName(From));
            ptr[0..2].* = "' ".*;
            ptr = fmt.AnyFormat(.{}, From).write(ptr + 2, value);
        }
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicCastToIntFromInvalid(
        comptime To: type,
        to_type_name: []const u8,
        comptime From: type,
        from_type_name: []const u8,
        extrema: math.BestExtrema(To),
        value: From,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        const yn: bool = value < 0;
        const x: math.Extrema = math.extrema(To);
        var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
        ptr[0..13].* = " overflowed: ".*;
        ptr += 13;
        if (value < x.max and value > x.min) {
            ptr[0] = '(';
            ptr = fmt.Udsize.write(ptr + 1, @intFromFloat(@trunc(value)));
            ptr[0] = ')';
            ptr += 1;
        }
        ptr = writeAboveOrBelowLimit(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicCastTruncatedData(
        comptime To: type,
        to_type_name: []const u8,
        comptime From: type,
        from_type_name: []const u8,
        extrema: math.BestExtrema(To),
        value: From,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        const yn: bool = value < 0;
        var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
        ptr[0..17].* = " truncated bits: ".*;
        ptr = fmt.Xd(From).write(ptr + 17, value);
        ptr = writeAboveOrBelowLimit(ptr, To, to_type_name, yn, if (yn) extrema.min else extrema.max);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicCastToUnsignedFromNegative(
        comptime _: type,
        to_type_name: []const u8,
        comptime From: type,
        from_type_name: []const u8,
        value: From,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        var ptr: [*]u8 = writeCastToFrom(&buf, to_type_name, from_type_name);
        ptr[0..18].* = " lost signedness (".*;
        ptr = fmt.AnyFormat(.{}, From).write(ptr + 18, value);
        ptr[0] = ')';
        builtin.panic(buf[0 .. @intFromPtr(ptr + 1) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicMismatchedSentinel(
        comptime Number: type,
        type_name: []const u8,
        expected: Number,
        found: Number,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
        ptr[0..29].* = " sentinel mismatch: expected ".*;
        ptr = fmt.AnyFormat(.{}, Number).write(ptr + 29, expected);
        ptr[0..8].* = ", found ".*;
        ptr = fmt.AnyFormat(.{}, Number).write(ptr + 8, found);
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn panicExactDivisionWithRemainder(
        comptime Number: type,
        lhs: Number,
        rhs: Number,
        ret_addr: usize,
    ) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        var buf: [256]u8 = undefined;
        buf[0..31].* = "exact division with remainder: ".*;
        var ptr: [*]u8 = fmt.AnyFormat(.{}, Number).write(buf[31..], lhs);
        ptr[0] = '/';
        ptr = fmt.AnyFormat(.{}, Number).write(ptr + 1, rhs);
        ptr[0..4].* = " == ".*;
        ptr = fmt.AnyFormat(.{}, Number).write(ptr + 4, @divTrunc(lhs, rhs));
        ptr[0] = 'r';
        ptr = fmt.AnyFormat(.{}, Number).write(ptr + 1, @rem(lhs, rhs));
        builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
    }
    fn writeCastToFrom(
        buf: [*]u8,
        to_type_name: []const u8,
        from_type_name: []const u8,
    ) [*]u8 {
        @setRuntimeSafety(false);
        buf[0..9].* = "cast to '".*;
        const ptr: [*]u8 = fmt.strcpyEqu(buf + 9, to_type_name);
        ptr[0..8].* = "' from '".*;
        fmt.strcpyEqu(ptr + 8, from_type_name)[0] = '\'';
        return ptr + 9 + from_type_name.len;
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
        var ptr: [*]u8 = fmt.strcpyEqu(buf + 7, to_type_name);
        ptr[0..10].* = if (yn) " minimum (".* else " maximum (".*;
        ptr = fmt.Xd(To).write(ptr + 10, limit);
        ptr[0] = ')';
        return ptr + 1;
    }
    fn panicArithOverflow(comptime Number: type) type {
        return struct {
            const Extrema = math.BestExtrema(Number);
            const Absolute = math.Absolute(Number);
            fn add(
                type_name: []const u8,
                extrema: Extrema,
                lhs: Number,
                rhs: Number,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                const yn: bool = rhs < 0;
                var buf: [256]u8 = undefined;
                var ptr: [*]u8 = writeOverflowed(&buf, "add overflowed ", type_name, " + ", lhs, rhs, &@addWithOverflow(lhs, rhs));
                ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn sub(
                type_name: []const u8,
                extrema: Extrema,
                lhs: Number,
                rhs: Number,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                const yn: bool = rhs > 0;
                var buf: [256]u8 = undefined;
                var ptr: [*]u8 = writeOverflowed(&buf, "sub overflowed ", type_name, " - ", lhs, rhs, &@subWithOverflow(lhs, rhs));
                ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn mul(
                type_name: []const u8,
                extrema: Extrema,
                lhs: Number,
                rhs: Number,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                var buf: [256]u8 = undefined;
                var ptr: [*]u8 = writeOverflowed(&buf, "mul overflowed ", type_name, " * ", lhs, rhs, &@mulWithOverflow(lhs, rhs));
                const yn: bool = @bitCast(
                    (@intFromBool(rhs < 0) & @intFromBool(lhs > 0)) |
                        (@intFromBool(lhs < 0) & @intFromBool(rhs > 0)),
                );
                ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn combined(
                pc: builtin.PanicId,
                type_name: []const u8,
                extrema: Extrema,
                lhs: Number,
                rhs: Number,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                const yn: bool = switch (pc) {
                    .add_overflowed => rhs < 0,
                    .sub_overflowed => rhs > 0,
                    else => @bitCast(
                        (@intFromBool(rhs < 0) & @intFromBool(lhs > 0)) |
                            (@intFromBool(lhs < 0) & @intFromBool(rhs > 0)),
                    ),
                };
                var buf: [256]u8 = undefined;
                var ptr: [*]u8 = writeOverflowed(&buf, switch (pc) {
                    .add_overflowed => "add overflowed ",
                    .sub_overflowed => "sub overflowed ",
                    else => "mul overflowed ",
                }, type_name, switch (pc) {
                    .add_overflowed => " + ",
                    .sub_overflowed => " - ",
                    else => " * ",
                }, lhs, rhs, switch (pc) {
                    .add_overflowed => @addWithOverflow(lhs, rhs),
                    .sub_overflowed => @subWithOverflow(lhs, rhs),
                    else => @mulWithOverflow(lhs, rhs),
                });
                ptr = writeAboveOrBelowLimit(ptr, Number, type_name, yn, if (yn) extrema.min else extrema.max);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn shl(
                type_name: []const u8,
                value: Number,
                shift_amt: u16,
                mask: Absolute,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                const absolute: Absolute = @bitCast(value);
                const ov_bits: u16 = @popCount(absolute & mask) -% @popCount((absolute << @intCast(shift_amt)) & mask);
                var buf: [256]u8 = undefined;
                buf[0..22].* = "left shift overflowed ".*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[22..], type_name);
                ptr[0..2].* = ": ".*;
                ptr = fmt.Xd(Number).write(ptr + 2, value);
                ptr[0..4].* = " << ".*;
                ptr = fmt.Xd(Number).write(ptr + 4, shift_amt);
                ptr = writeShiftedOutBits(ptr, ov_bits);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn shr(
                type_name: []const u8,
                value: Number,
                shift_amt: u16,
                mask: Absolute,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                const absolute: Absolute = @bitCast(value);
                const ov_bits: u16 = @popCount(absolute & mask) -% @popCount((absolute << @intCast(shift_amt)) & mask);
                var buf: [256]u8 = undefined;
                buf[0..23].* = "right shift overflowed ".*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[23..], type_name);
                ptr[0..2].* = ": ".*;
                ptr = fmt.Xd(Number).write(ptr + 2, value);
                ptr[0..4].* = " >> ".*;
                ptr = fmt.Xd(Number).write(ptr + 4, shift_amt);
                ptr = writeShiftedOutBits(ptr, ov_bits);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn shiftRhs(
                type_name: []const u8,
                bit_count: u16,
                shift_amt: u16,
                ret_addr: usize,
            ) noreturn {
                @setCold(true);
                @setRuntimeSafety(false);
                var buf: [256]u8 = undefined;
                var ptr: [*]u8 = fmt.strcpyEqu(&buf, type_name);
                ptr[0..23].* = " RHS of shift too big: ".*;
                ptr = fmt.Xd(Number).write(ptr + 23, shift_amt);
                ptr[0..3].* = " > ".*;
                ptr = fmt.Xd(Number).write(ptr + 3, bit_count);
                builtin.panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, ret_addr);
            }
            fn writeOverflowed(
                buf: [*]u8,
                op_name: *const [15]u8,
                type_name: []const u8,
                op_sym: *const [3]u8,
                lhs: Number,
                rhs: Number,
                res: *const struct { Number, u1 },
            ) [*]u8 {
                @setCold(true);
                @setRuntimeSafety(false);
                buf[0..15].* = op_name.*;
                var ptr: [*]u8 = fmt.strcpyEqu(buf[15..], type_name);
                ptr[0..2].* = ": ".*;
                ptr = fmt.Xd(Number).write(ptr + 2, lhs);
                ptr[0..3].* = op_sym.*;
                ptr = fmt.Xd(Number).write(ptr + 3, rhs);
                if (res[1] == 0) {
                    ptr[0..2].* = " (".*;
                    ptr = fmt.Xd(Number).write(ptr + 2, res[0]);
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
                var ptr: [*]u8 = fmt.Xd(Number).write(buf + 13, ov_bits);
                ptr[0..5].* = " bits".*;
                return ptr + 4 + @intFromBool(ov_bits != 1);
            }
        };
    }
    const want_panic_data: bool = if (@hasDecl(builtin, "want_panic_data")) builtin.want_panic_data else true;

    pub fn panicNew(comptime cause: builtin.PanicCause, data: builtin.PanicData(cause)) noreturn {
        @setCold(true);
        @setRuntimeSafety(false);
        if (want_panic_data) {
            switch (cause) {
                .message => {
                    panic(data, null, @returnAddress());
                },
                .accessed_null_value => {
                    panic("attempted to use null value", null, @returnAddress());
                },
                .divided_by_zero => {
                    panic("attempted to divide by zero", null, @returnAddress());
                },
                .returned_noreturn => {
                    panic("returned from function marked 'noreturn'", null, @returnAddress());
                },
                .reached_unreachable => {
                    panic("reached unreachable code", null, @returnAddress());
                },
                .unwrapped_error => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..28].* = "attempted to discard error: ".*;
                    const ptr: [*]u8 = fmt.strcpyEqu(buf[28..], @errorName(data.err));
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], data.st, @returnAddress());
                },
                .accessed_out_of_order => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..12].* = "start index ".*;
                    var ptr: [*]u8 = fmt.Udsize.write(buf[12..], data.start);
                    ptr[0..26].* = " is larger than end index ".*;
                    ptr = fmt.Udsize.write(ptr + 26, data.finish);
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .accessed_out_of_bounds => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    var ptr: [*]u8 = &buf;
                    ptr[0..6].* = "index ".*;
                    ptr = fmt.Udsize.write(ptr + 6, data.index);
                    ptr[0..15].* = " above maximum ".*;
                    ptr = fmt.Udsize.write(ptr + 15, data.length -% 1);
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .accessed_inactive_field => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..23].* = "access of union field '".*;
                    var ptr: [*]u8 = fmt.strcpyEqu(buf[23..], @tagName(data.found));
                    ptr[0..15].* = "' while field '".*;
                    ptr = fmt.strcpyEqu(ptr + 15, @tagName(data.expected));
                    ptr = fmt.strcpyEqu(ptr, "' is active");
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .memcpy_argument_aliasing => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..32].* = "@memcpy arguments alias between ".*;
                    var ptr: [*]u8 = fmt.Uxsize.write(buf[32..], @max(data.dest_start, data.src_start));
                    ptr[0..5].* = " and ".*;
                    ptr = fmt.Uxsize.write(ptr + 5, @min(data.dest_finish, data.src_finish));
                    ptr[0..2].* = " (".*;
                    ptr = fmt.Udsize.write(ptr + 2, data.dest_finish -% data.dest_start);
                    ptr[0..7].* = " bytes)".*;
                    panic(buf[0 .. @intFromPtr(ptr + 7) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .mismatched_memcpy_argument_lengths => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..65].* = "@memcpy destination and source with mismatched lengths: expected ".*;
                    var ptr: [*]u8 = fmt.Udsize.write(buf[65..], data.dest_len);
                    ptr[0..8].* = ", found ".*;
                    ptr = fmt.Udsize.write(ptr + 8, data.src_len);
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .mismatched_for_loop_capture_lengths => {
                    @setRuntimeSafety(false);
                    var buf: [256]u8 = undefined;
                    buf[0..58].* = "multi-for loop captures with mismatched lengths: expected ".*;
                    var ptr: [*]u8 = fmt.Udsize.write(buf[58..], data.loop_len);
                    ptr[0..8].* = ", found ".*;
                    ptr = fmt.Udsize.write(ptr + 8, data.capture_len);
                    panic(buf[0 .. @intFromPtr(ptr) -% @intFromPtr(&buf)], null, @returnAddress());
                },
                .cast_to_enum_from_invalid => |enum_type| @call(.never_inline, safety.panicCastToTagFromInvalid, .{
                    meta.BestInt(enum_type), @typeName(enum_type), data, @returnAddress(),
                }),
                .cast_to_error_from_invalid => |error_type| @call(.never_inline, safety.panicCastToErrorFromInvalid, .{
                    error_type.from, @typeName(error_type.to), data, @returnAddress(),
                }),
                .mul_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).mul, .{
                    @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, @returnAddress(),
                }),
                .add_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).add, .{
                    @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, @returnAddress(),
                }),
                .sub_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).sub, .{
                    @typeName(int_type), math.bestExtrema(int_type), data.lhs, data.rhs, @returnAddress(),
                }),
                .shl_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).shl, .{
                    @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), @returnAddress(),
                }),
                .shr_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).shr, .{
                    @typeName(int_type), data.value, data.shift_amt, ~@abs(@as(int_type, 0)), @returnAddress(),
                }),
                .shift_amt_overflowed => |int_type| @call(.never_inline, safety.panicArithOverflow(meta.BestInt(int_type)).shiftRhs, .{
                    @typeName(int_type), @bitSizeOf(int_type), data, @returnAddress(),
                }),
                .div_with_remainder => |num_type| @call(.never_inline, safety.panicExactDivisionWithRemainder, .{
                    meta.BestNum(num_type), data.lhs, data.rhs, @returnAddress(),
                }),
                .mismatched_sentinel => |elem_type| @call(.never_inline, safety.panicMismatchedSentinel, .{
                    meta.BestNum(elem_type),     @typeName(elem_type),
                    meta.bestNum(data.expected), meta.bestNum(data.actual),
                    @returnAddress(),
                }),
                .cast_to_ptr_from_invalid => |alignment| @call(.never_inline, safety.panicCastToPointerFromInvalid, .{
                    data, alignment, @returnAddress(),
                }),
                .cast_to_unsigned_from_negative => |int_types| @call(.never_inline, safety.panicCastToUnsignedFromNegative, .{
                    meta.BestNum(int_types.to),   @typeName(int_types.to),
                    meta.BestNum(int_types.from), @typeName(int_types.from),
                    data,                         @returnAddress(),
                }),
                .cast_to_int_from_invalid => |num_types| @call(.never_inline, safety.panicCastToIntFromInvalid, .{
                    meta.BestNum(num_types.to),     @typeName(num_types.to),
                    meta.BestNum(num_types.from),   @typeName(num_types.from),
                    math.bestExtrema(num_types.to), data,
                    @returnAddress(),
                }),
                .cast_truncated_data => |num_types| @call(.never_inline, safety.panicCastTruncatedData, .{
                    meta.BestNum(num_types.to),     @typeName(num_types.to),
                    meta.BestNum(num_types.from),   @typeName(num_types.from),
                    math.bestExtrema(num_types.to), data,
                    @returnAddress(),
                }),
            }
        }
        panic(@tagName(cause), null, @returnAddress());
    }
};
