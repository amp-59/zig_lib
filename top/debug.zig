const tab = @import("./tab.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const builtin = @import("./builtin.zig");
const debug = @This();
pub const Error = error{
    SubCausedOverflow,
    AddCausedOverflow,
    MulCausedOverflow,
    LeftShiftCausedOverflow,
    ExactDivisionWithRemainder,
    IncorrectAlignment,
};
pub const Unexpected = error{
    UnexpectedValue,
    UnexpectedLength,
};
pub const PanicFn = @TypeOf(panic);
pub const PanicExtraFn = @TypeOf(panicSignal);
pub const PanicOutOfBoundsFn = @TypeOf(panicOutOfBounds);
pub const PanicSentinelMismatchFn = @TypeOf(panicSentinelMismatch);
pub const PanicStartGreaterThanEndFn = @TypeOf(panicStartGreaterThanEnd);
pub const PanicInactiveUnionFieldFn = @TypeOf(panicInactiveUnionField);
pub const PanicUnwrapErrorFn = @TypeOf(panicUnwrapError);
pub const AlarmFn = @TypeOf(alarm);
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
    /// Address of lowest mapped byte of alternate stack.
    addr: u64 = 0x3f000000,
    /// Initial mapping length of alternate stack.
    len: u64 = 0x1000000,
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
                tags: []const builtin.parse.Token.Tag = meta.tagList(builtin.parse.Token.Tag),
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
    var bits: u6 = 0;
    while (true) : (bits +%= 1) {
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
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " < ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " < ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertBelowOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 > arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " <= ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " <= ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and !mem.testEqual(T, arg1, arg2)) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " == ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " == ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertNotEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and mem.testEqual(T, arg1, arg2)) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " != ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " != ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertAboveOrEqual(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 < arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " >= ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " >= ", arg1, arg2, @returnAddress());
        }
    }
}
pub fn assertAbove(comptime T: type, arg1: T, arg2: T) void {
    if (builtin.runtime_assertions and arg1 <= arg2) {
        if (@inComptime()) {
            debug.static.comparisonFailed(T, " > ", arg1, arg2);
        } else {
            debug.comparisonFailedFault(T, " > ", arg1, arg2, @returnAddress());
        }
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
pub fn intCastTruncatedBitsFault(comptime T: type, comptime U: type, arg: U, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeIntCastTruncatedBits(T, U, &buf, arg);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn subCausedOverflowError(comptime T: type, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeSubCausedOverflow(T, @typeName(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.SubCausedOverflow;
}
pub fn subCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeSubCausedOverflow(T, @typeName(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn addCausedOverflowError(comptime T: type, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeAddCausedOverflow(T, @typeName(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.AddCausedOverflow;
}
pub fn addCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeAddCausedOverflow(T, @typeName(T), &buf, arg1, arg2, @min(arg1, arg2) > 10_000);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn mulCausedOverflowError(comptime T: type, arg1: T, arg2: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeMulCausedOverflow(T, @typeName(T), &buf, arg1, arg2);
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.MulCausedOverflow;
}
pub fn mulCausedOverflowFault(comptime T: type, arg1: T, arg2: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeMulCausedOverflow(T, @typeName(T), &buf, arg1, arg2);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn exactDivisionWithRemainderError(comptime T: type, arg1: T, arg2: T, result: T, remainder: T, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeExactDivisionWithRemainder(T, @typeName(T), &buf, arg1, arg2, result, remainder);
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.ExactDivisionWithRemainder;
}
pub fn exactDivisionWithRemainderFault(comptime T: type, arg1: T, arg2: T, result: T, remainder: T, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeExactDivisionWithRemainder(T, @typeName(T), &buf, arg1, arg2, result, remainder);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn incorrectAlignmentError(comptime T: type, address: usize, alignment: usize, ret_addr: ?usize) Error {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeIncorrectAlignment(@typeName(T), &buf, address, alignment, remainder);
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.IncorrectAlignment;
}
pub fn incorrectAlignmentFault(comptime T: type, address: usize, alignment: usize, ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    const remainder: usize = address & (@typeInfo(T).Pointer.alignment -% 1);
    var buf: [4096]u8 = undefined;
    const len: u64 = about.writeIncorrectAlignment(@typeName(T), &buf, address, alignment, remainder);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn comparisonFailedFault(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1), ret_addr: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    const about_s: []const u8 = @typeName(T) ++ " failed assertion: ";
    var buf: [4096]u8 = undefined;
    const len: u64 = switch (@typeInfo(T)) {
        .Int => about.writeComparisonFailed(T, about_s, symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000),
        .Enum => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, @tagName(arg1), symbol, @tagName(arg2) }),
        .Type => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, @typeName(arg1), symbol, @typeName(arg2) }),
        else => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, "unexpected value" }),
    };
    builtin.panic(buf[0..len], null, ret_addr);
}
pub fn comparisonFailedError(comptime T: type, symbol: []const u8, arg1: anytype, arg2: @TypeOf(arg1), ret_addr: ?usize) Unexpected {
    @setCold(true);
    @setRuntimeSafety(builtin.is_safe);
    const about_s: []const u8 = @typeName(T) ++ " failed test: ";
    var buf: [4096]u8 = undefined;
    const len: u64 = switch (@typeInfo(T)) {
        .Int => about.writeComparisonFailed(T, about_s, symbol, &buf, arg1, arg2, @min(arg1, arg2) > 10_000),
        .Enum => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, @tagName(arg1), symbol, @tagName(arg2) }),
        .Type => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, @typeName(arg1), symbol, @typeName(arg2) }),
        else => mach.memcpyMulti(&buf, &[_][]const u8{ about_s, "unexpected value" }),
    };
    builtin.alarm(buf[0..len], @errorReturnTrace(), ret_addr orelse @returnAddress());
    return error.UnexpectedValue;
}
pub fn sampleAllReports() void {
    inline for (.{ u16, u32, u64, usize }) |T| {
        var arg1: T = 2048;
        var arg2: T = 4098;
        var result: T = 2;
        const remainder: T = 2;
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
        incorrectAlignmentError(*T, arg2, remainder, null) catch {};
        subCausedOverflowError(T, ~arg1, ~arg2, null) catch {};
        addCausedOverflowError(T, ~arg1, ~arg2, null) catch {};
        mulCausedOverflowError(T, ~arg1, ~arg2, null) catch {};
        exactDivisionWithRemainderError(T, ~arg1, ~arg2, result, remainder, null) catch {};
        incorrectAlignmentError(*T, ~arg2, remainder, null) catch {};
    }

    about.faultNotice("message");
    about.errorNotice(@errorName(error.Error));
    about.errorFaultNotice(@errorName(error.Error), "message");
    about.faultRcNotice("message", 2);
    about.errorRcNotice(@errorName(error.Error), 1);
    about.errorFaultRcNotice(@errorName(error.Error), "message", 2);
}
pub fn write(buf: []const u8) void {
    if (@inComptime()) {
        return @compileLog(buf);
    } else {
        asm volatile (
            \\syscall # write
            :
            : [_] "{rax}" (1), // linux sys_write
              [_] "{rdi}" (2), // stderr
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
    /// Namespace containing definition of `printStackTrace`.
    const trace = @import("./trace.zig");

    /// Used by panic functions if executable is static linked with special
    /// module object `trace.o`.
    extern fn printStackTrace(*const Trace, u64, u64) void;
};
pub const printStackTrace = blk: {
    if (builtin.want_stack_traces and
        !builtin.have_stack_traces and
        builtin.output_mode == .Exe)
    {
        break :blk special.trace.printStackTrace;
    } else {
        break :blk special.printStackTrace;
    }
};
pub noinline fn alarm(msg: []const u8, _: @TypeOf(@errorReturnTrace()), ret_addr: usize) void {
    @setCold(true);
    @setRuntimeSafety(false);
    if (builtin.want_stack_traces and builtin.trace.Error) {
        printStackTrace(&builtin.trace, ret_addr, 0);
    }
    @call(.always_inline, about.errorNotice, .{msg});
}
pub noinline fn panic(msg: []const u8, _: @TypeOf(@errorReturnTrace()), ret_addr: ?usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    if (builtin.want_stack_traces and builtin.trace.Fault) {
        printStackTrace(&builtin.trace, ret_addr orelse @returnAddress(), 0);
    }
    @call(.always_inline, proc.exitGroupFault, .{ msg, builtin.panic_return_value });
}
pub noinline fn panicSignal(msg: []const u8, ctx_ptr: *const anyopaque) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const regs: mach.RegisterState = @as(
        *mach.RegisterState,
        @ptrFromInt(@intFromPtr(ctx_ptr) +% mach.RegisterState.offset),
    ).*;
    if (builtin.want_stack_traces and builtin.trace.Signal) {
        printStackTrace(&builtin.trace, regs.rip, regs.rbp);
    }
    @call(.always_inline, proc.exitGroupFault, .{ msg, 2 });
}
inline fn panicOutOfBoundsEmpty(buf: [*]u8, idx: usize) usize {
    var len: u64 = 0;
    var ud64: fmt.Type.Ud64 = @bitCast(idx);
    @as(*[10]u8, @ptrCast(buf)).* = "indexing (".*;
    len +%= 10;
    len +%= ud64.formatWriteBuf(buf + len);
    @as(*[18]u8, @ptrCast(buf + len)).* = ") into empty array".*;
    return len +% 18;
}
pub noinline fn panicOutOfBounds(idx: usize, max_len: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const ret_addr: usize = @returnAddress();
    var buf: [1024]u8 = undefined;
    var len: u64 = 0;
    if (max_len == 0) {
        len +%= panicOutOfBoundsEmpty(&buf, idx);
    } else {
        var ud64: fmt.Type.Ud64 = @bitCast(idx);
        @as(*[6]u8, @ptrCast(buf[len..].ptr)).* = "index ".*;
        len +%= 6;
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
        @as(*[15]u8, @ptrCast(buf[len..].ptr)).* = " above maximum ".*;
        len +%= 15;
        ud64 = @bitCast(max_len -% 1);
        len +%= ud64.formatWriteBuf(buf[len..].ptr);
    }
    builtin.panic(buf[0..len], null, ret_addr);
}
pub noinline fn panicSentinelMismatch(expected: anytype, actual: @TypeOf(expected)) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const ret_addr: usize = @returnAddress();
    var buf: [1024]u8 = undefined;
    var len: usize = 0;
    var ud64: fmt.Type.Ud64 = @bitCast(@as(u64, expected));
    @as(*[28]u8, @ptrCast(&buf)).* = "sentinel mismatch: expected ".*;
    len +%= 28;
    len +%= ud64.formatWriteBuf(buf[len..].ptr);
    @as(*[8]u8, @ptrCast(buf[len..].ptr)).* = ", found ".*;
    len +%= 8;
    ud64 = @bitCast(@as(u64, actual));
    len +%= ud64.formatWriteBuf(buf[len..].ptr);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub noinline fn panicStartGreaterThanEnd(lower: usize, upper: usize) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const ret_addr: usize = @returnAddress();
    var buf: [1024]u8 = undefined;
    var len: usize = 0;
    var ud64: fmt.Type.Ud64 = @bitCast(lower);
    @as(*[12]u8, @ptrCast(&buf)).* = "start index ".*;
    len +%= 12;
    len +%= ud64.formatWriteBuf(buf[len..].ptr);
    @as(*[26]u8, @ptrCast(buf[len..].ptr)).* = " is larger than end index ".*;
    len +%= 26;
    ud64 = @bitCast(upper);
    len +%= ud64.formatWriteBuf(buf[len..].ptr);
    builtin.panic(buf[0..len], null, ret_addr);
}
pub noinline fn panicInactiveUnionField(active: anytype, wanted: @TypeOf(active)) noreturn {
    @setCold(true);
    @setRuntimeSafety(false);
    const ret_addr: usize = @returnAddress();
    var buf: [1024]u8 = undefined;
    var len: usize = 0;
    @as(*[23]u8, @ptrCast(&buf)).* = "access of union field '".*;
    len +%= 23;
    @memcpy(buf[len..].ptr, @tagName(wanted));
    len +%= @tagName(wanted).len;
    @as(*[15]u8, @ptrCast(buf[len..].ptr)).* = "' while field '".*;
    len +%= 15;
    @memcpy(buf[len..].ptr, @tagName(active));
    len +%= @tagName(active).len;
    @as(*[11]u8, @ptrCast(buf[len..].ptr)).* = "' is active".*;
    len +%= 11;
    builtin.panic(buf[0..len], null, ret_addr);
}
pub noinline fn panicUnwrapError(st: ?*builtin.StackTrace, err: anyerror) noreturn {
    if (!builtin.discard_errors) {
        @compileError("error is discarded");
    }
    const ret_addr: usize = @returnAddress();
    var buf: [1024]u8 = undefined;
    var len: usize = 20;
    @as(*[20]u8, @ptrCast(&buf)).* = "error is discarded: ".*;
    @memcpy(buf[len..].ptr, @errorName(err));
    len +%= @errorName(err).len;
    builtin.panic(buf[0..len], st, ret_addr);
}
fn checkNonScalarSentinel(expected: comptime_int, actual: anytype) void {
    if (expected != actual) {
        builtin.panicSentinelMismatch(expected, actual);
    }
}
fn addErrRetTraceAddr(st: *builtin.StackTrace, ret_addr: usize) void {
    if (st.addrs_len < st.addrs.len) {
        st.addrs[st.addrs_len] = ret_addr;
    }
    st.addrs_len +%= 1;
}
noinline fn returnError(st: *builtin.StackTrace) void {
    @setCold(true);
    @setRuntimeSafety(false);
    addErrRetTraceAddr(st, @returnAddress());
}
const static = struct {
    fn subCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
        comptime {
            var msg: [4096]u8 = undefined;
            @compileError(msg[0..about.writeSubCausedOverflow(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
    }
    fn addCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
        comptime {
            var msg: [4096]u8 = undefined;
            @compileError(msg[0..about.writeAddCausedOverflow(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
    }
    fn mulCausedOverflow(comptime T: type, comptime arg1: T, comptime arg2: T) noreturn {
        comptime {
            var msg: [4096]u8 = undefined;
            @compileError(msg[0..about.writeMulCausedOverflow(T, &msg, arg1, arg2, @min(arg1, arg2) > 10_000)]);
        }
    }
    fn exactDivisionWithRemainder(comptime T: type, comptime arg1: T, comptime arg2: T, comptime result: T, comptime remainder: T) noreturn {
        comptime {
            var buf: [4096]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                @typeName(T),      ": exact division had a remainder: ",
                fmt.ci(arg1),      "/",
                fmt.ci(arg2),      " == ",
                fmt.ci(result),    "r",
                fmt.ci(remainder), "\n",
            }) |s| {
                for (s, 0..) |c, idx| buf[len +% idx] = c;
                len +%= s.len;
            }
            @compileError(buf[0..len]);
        }
    }
    fn incorrectAlignment(comptime T: type, comptime type_name: []const u8, comptime address: T, comptime alignment: T, comptime result: T, comptime remainder: T) noreturn {
        comptime {
            var buf: [4096]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                @typeName(T),      ": incorrect alignment: ",
                type_name,         " align(",
                fmt.ci(alignment), "): ",
                fmt.ci(address),   " == ",
                fmt.ci(result),    "+",
                fmt.ci(remainder), "\n",
            }) |s| {
                for (s, 0..) |c, idx| buf[len +% idx] = c;
                len +%= s.len;
            }
            @compileError(buf[0..len]);
        }
    }
    inline fn comparisonFailed(comptime T: type, comptime symbol: []const u8, comptime arg1: T, comptime arg2: T) void {
        comptime {
            var buf: [4096]u8 = undefined;
            var len: u64 = 0;
            for ([_][]const u8{
                @typeName(T), " assertion failed ",
                fmt.ci(arg1), symbol,
                fmt.ci(arg2), if (@min(arg1, arg2) > 10_000) ", i.e. " else "\n",
            }) |s| {
                for (s, 0..) |c, idx| buf[len +% idx] = c;
                len +%= s.len;
            }
            if (@min(arg1, arg2) > 10_000) {
                if (arg1 > arg2) {
                    for ([_][]const u8{ fmt.ci(arg1 -% arg2), symbol, "0\n" }) |s| {
                        for (s, 0..) |c, idx| buf[len +% idx] = c;
                        len +%= s.len;
                    }
                } else {
                    for ([_][]const u8{ "0", symbol, fmt.ci(arg2 -% arg1), "\n" }) |s| {
                        for (s, 0..) |c, idx| buf[len +% idx] = c;
                        len +%= s.len;
                    }
                }
            }
            @compileError(buf[0..len]);
        }
    }
};
pub const about = struct {
    pub const ErrorSrc = @TypeOf(error_s);
    pub const ErrorDest = @TypeOf(@constCast(error_s));
    pub const ErrorPDest = @TypeOf(@constCast(error_p0_s));
    pub const FaultPDest = @TypeOf(@constCast(fault_p0_s));
    pub const error_s = "\x1b[91;1merror\x1b[0m=";
    pub const fault_p0_s = blk: {
        var lhs: [:0]const u8 = "fault";
        lhs = builtin.message_prefix ++ lhs;
        lhs = lhs ++ builtin.message_suffix;
        const len: usize = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ builtin.message_no_style;
        break :blk lhs ++ " " ** (builtin.message_indent - len);
    };
    pub const error_p0_s = blk: {
        var lhs: [:0]const u8 = "error";
        lhs = builtin.message_prefix ++ lhs;
        lhs = lhs ++ builtin.message_suffix;
        const len: usize = lhs.len;
        lhs = "\x1b[1m" ++ lhs ++ builtin.message_no_style;
        break :blk lhs ++ " " ** (builtin.message_indent - len);
    };
    pub const test_1_s = "test failed";
    pub const assertion_1_s = "assertion failed";
    pub fn aboutError(about_s: fmt.AboutSrc, error_name: [:0]const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var buf: [32768]u8 = undefined;
        var len: usize = about_s.len;
        @as(fmt.AboutDest, @ptrCast(&buf)).* = about_s.*;
        @as(debug.about.ErrorDest, @ptrCast(buf[len..].ptr)).* = debug.about.error_s.*;
        len +%= debug.about.error_s.len;
        @memcpy(buf[len..].ptr, error_name);
        len +%= error_name.len;
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn exitRcNotice(rc: u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = fmt.about_exit_s.len;
        @as(fmt.AboutDest, @ptrCast(&buf)).* = fmt.about_exit_s.*;
        @as(*[3]u8, @ptrCast(buf[len..].ptr)).* = "rc=".*;
        len +%= 3;
        len +%= fmt.ud64(rc).formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn errorRcNotice(error_name: []const u8, rc: u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.error_p0_s.len;
        @as(debug.about.ErrorPDest, @ptrCast(&buf)).* = about.error_p0_s.*;
        @as(debug.about.ErrorDest, @ptrCast(buf[len..].ptr)).* = debug.about.error_s.*;
        len +%= debug.about.error_s.len;
        @memcpy(buf[len..].ptr, error_name);
        len +%= error_name.len;
        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = ", rc=".*;
        len +%= 5;
        len +%= fmt.ud64(rc).formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn errorFaultRcNotice(error_name: []const u8, message: []const u8, rc: u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.fault_p0_s.len;
        @as(debug.about.FaultPDest, @ptrCast(&buf)).* = about.fault_p0_s.*;
        @as(debug.about.ErrorDest, @ptrCast(buf[len..].ptr)).* = debug.about.error_s.*;
        len +%= debug.about.error_s.len;
        @memcpy(buf[len..].ptr, error_name);
        len +%= error_name.len;
        @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
        len +%= 2;
        @memcpy(buf[len..].ptr, message);
        len +%= message.len;
        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = ", rc=".*;
        len +%= 5;
        len +%= fmt.ud64(rc).formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn errorNotice(error_name: []const u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.error_p0_s.len;
        @as(*[about.error_p0_s.len]u8, @ptrCast(&buf)).* = about.error_p0_s.*;
        @memcpy(buf[len..].ptr, error_name);
        len +%= error_name.len;
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn faultNotice(message: []const u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.fault_p0_s.len;
        @as(*[about.fault_p0_s.len]u8, @ptrCast(&buf)).* = about.fault_p0_s.*;
        len +%= about.fault_p0_s.len;
        @memcpy(buf[len..].ptr, message);
        len +%= message.len;
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn faultRcNotice(message: []const u8, rc: u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.fault_p0_s.len;
        @as(*[about.fault_p0_s.len]u8, @ptrCast(&buf)).* = about.fault_p0_s.*;
        len +%= about.fault_p0_s.len;
        @memcpy(buf[len..].ptr, message);
        len +%= message.len;
        @as(*[5]u8, @ptrCast(buf[len..].ptr)).* = ", rc=".*;
        len +%= 5;
        len +%= fmt.ud64(rc).formatWriteBuf(buf[len..].ptr);
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    pub fn errorFaultNotice(error_name: []const u8, message: []const u8) void {
        var buf: [4096]u8 = undefined;
        var len: usize = about.fault_p0_s.len;
        @as(*[about.fault_p0_s]u8, @ptrCast(&buf)).* = about.fault_p0_s.*;
        @as(debug.about.ErrorDest, @ptrCast(buf[len..].ptr)).* = debug.about.error_s.*;
        len +%= debug.about.error_s.len;
        @memcpy(buf[len..].ptr, error_name);
        len +%= error_name.len;
        @as(*[2]u8, @ptrCast(buf[len..].ptr)).* = ", ".*;
        len +%= 2;
        @memcpy(buf[len..].ptr, message);
        len +%= message.len;
        buf[len] = '\n';
        write(buf[0 .. len +% 1]);
    }
    fn writeComparisonFailed(comptime T: type, what: []const u8, symbol: []const u8, buf: [*]u8, arg1: T, arg2: T, help_read: bool) u64 {
        var len: usize = what.len;
        var ud: fmt.Type.Xd(T) = .{ .value = arg1 };
        @memcpy(buf, what);
        len +%= ud.formatWriteBuf(buf + len);
        @memcpy(buf + len, symbol);
        len +%= symbol.len;
        ud = .{ .value = arg2 };
        len +%= ud.formatWriteBuf(buf + len);
        if (help_read) {
            @as(*[7]u8, @ptrCast(buf + len)).* = ", i.e. ".*;
            len +%= 7;
            if (arg1 > arg2) {
                ud = .{ .value = arg1 -% arg2 };
                len +%= ud.formatWriteBuf(buf + len);
                @memcpy(buf + len, symbol);
                len +%= symbol.len;
                buf[len] = '0';
                len +%= 1;
            } else {
                buf[len] = '0';
                len +%= 1;
                @memcpy(buf + len, symbol);
                len +%= symbol.len;
                ud = .{ .value = arg2 -% arg1 };
                len +%= ud.formatWriteBuf(buf + len);
            }
        }
        return len;
    }
    fn writeIntCastTruncatedBits(comptime T: type, comptime U: type, buf: [*]u8, arg1: U) u64 {
        var len: usize = 29;
        @as(*[29]u8, @ptrCast(buf)).* = "integer cast truncated bits: ".*;
        len +%= fmt.Type.Xd(U).formatWriteBuf(.{ .value = arg1 }, buf);
        @as(*[26]u8, @ptrCast(buf + len)).* = (" greater than " ++ @typeName(T) ++ " maximum (").*;
        len +%= 26;
        len +%= fmt.ud(~@as(T, 0)).formatWriteBuf(buf);
        buf[len] = ')';
        return len +% 1;
    }
    fn writeSubCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T, help_read: bool) u64 {
        var len: u64 = what.len;
        var ud: fmt.Type.Xd(T) = .{ .value = arg1 };
        @memcpy(buf, what);
        @as(*[19]u8, @ptrCast(buf + len)).* = " integer overflow: ".*;
        len +%= 19;
        len +%= ud.formatWriteBuf(buf + len);
        @as(*[3]u8, @ptrCast(buf + len)).* = " - ".*;
        len +%= 3;
        ud = .{ .value = arg2 };
        len +%= ud.formatWriteBuf(buf + len);
        if (help_read) {
            @as(*[11]u8, @ptrCast(buf + len)).* = ", i.e. 0 - ".*;
            len +%= 11;
            ud = .{ .value = arg2 -% arg1 };
            len +%= ud.formatWriteBuf(buf + len);
        }
        return len;
    }
    fn writeAddCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T, help_read: bool) u64 {
        var len: u64 = what.len;
        var ud: fmt.Type.Xd(T) = .{ .value = arg1 };
        @memcpy(buf, what);
        @as(*[19]u8, @ptrCast(buf + len)).* = " integer overflow: ".*;
        len +%= 19;
        len +%= ud.formatWriteBuf(buf + len);
        @as(*[3]u8, @ptrCast(buf + len)).* = " + ".*;
        len +%= 3;
        ud = .{ .value = arg2 };
        len +%= ud.formatWriteBuf(buf + len);
        if (help_read) {
            @as(*[7]u8, @ptrCast(buf + len)).* = ", i.e. ".*;
            len +%= 7;
            const argl: T = ~@as(T, 0);
            const argr: T = (arg2 +% arg1) -% argl;
            ud = .{ .value = argl };
            len +%= ud.formatWriteBuf(buf + len);
            @as(*[3]u8, @ptrCast(buf + len)).* = " + ".*;
            len +%= 3;
            ud = .{ .value = argr };
            len +%= ud.formatWriteBuf(buf + len);
        }
        return len;
    }
    fn writeMulCausedOverflow(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T) u64 {
        var len: u64 = what.len;
        var ud: fmt.Type.Xd(T) = .{ .value = arg1 };
        @memcpy(buf, what);
        @as(*[19]u8, @ptrCast(buf + len)).* = " integer overflow: ".*;
        len +%= 19;
        len +%= ud.formatWriteBuf(buf + len);
        @as(*[3]u8, @ptrCast(buf + len)).* = " * ".*;
        len +%= 3;
        ud = .{ .value = arg2 };
        len +%= ud.formatWriteBuf(buf + len);
        return len;
    }
    fn writeExactDivisionWithRemainder(comptime T: type, what: []const u8, buf: [*]u8, arg1: T, arg2: T, result: T, remainder: T) u64 {
        var len: u64 = what.len;
        var ud: fmt.Type.Xd(T) = .{ .value = arg1 };
        @memcpy(buf, what);
        @as(*[34]u8, @ptrCast(buf + len)).* = ": exact division had a remainder: ".*;
        len +%= 34;
        len +%= ud.formatWriteBuf(buf + len);
        buf[len] = '/';
        len +%= 1;
        ud = .{ .value = arg2 };
        len +%= ud.formatWriteBuf(buf + len);
        @as(*[4]u8, @ptrCast(buf + len)).* = " == ".*;
        len +%= 4;
        ud = .{ .value = result };
        len +%= ud.formatWriteBuf(buf + len);
        buf[len] = 'r';
        len +%= 1;
        ud = .{ .value = remainder };
        len +%= ud.formatWriteBuf(buf + len);
        return len;
    }
    fn writeIncorrectAlignment(comptime Pointer: type, what: []const u8, buf: [*]u8, address: usize, alignment: usize, remainder: u64) u64 {
        var len: u64 = what.len;
        var udsize: fmt.Type.Xd(usize) = .{ .value = alignment };
        @memcpy(buf, what);
        @as(*[34]u8, @ptrCast(buf + len)).* = (": incorrect alignment: " ++ @typeName(Pointer) ++ " align(").*;
        len +%= 34;
        len +%= udsize.formatWriteBuf(buf + len);
        @as(*[3]u8, @ptrCast(buf + len)).* = "): ".*;
        len +%= 4;
        udsize = @bitCast(address);
        len +%= udsize.formatWriteBuf(buf + len);
        @as(*[4]u8, @ptrCast(buf + len)).* = " == ".*;
        len +%= 4;
        udsize = @bitCast(address -% remainder);
        len +%= udsize.formatWriteBuf(buf + len);
        buf[len] = '+';
        len +%= 1;
        udsize = @bitCast(remainder);
        len +%= udsize.formatWriteBuf(buf + len);
        return len;
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
