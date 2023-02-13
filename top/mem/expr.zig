const fmt = @import("../fmt.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./detail_more.zig");
};
const interface = @import("./interface.zig");
const implementation = @import("./implementation.zig");

pub const Callable = union(enum) {
    call0: FnCall0,
    call1: FnCall1,
    call2: FnCall2,
    call3: FnCall3,
    call4: FnCall4,
    call5: FnCall5,

    pub fn op(callable: *const Callable) Operand {
        switch (callable.*) {
            .call0 => return .{ .call0 = &callable.call0 },
            .call1 => return .{ .call1 = &callable.call1 },
            .call2 => return .{ .call2 = &callable.call2 },
            .call3 => return .{ .call3 = &callable.call3 },
            .call4 => return .{ .call4 = &callable.call4 },
            .call5 => return .{ .call5 = &callable.call5 },
        }
    }
    pub fn init(detail: anytype, fn_info: anytype) Callable {
        const array: gen.ArgList = fn_info.argList(detail, .Argument);
        const symbols: []const [:0]const u8 = array.readAll();
        switch (symbols.len) {
            0 => return .{ .call0 = .{
                .symbol = fn_info.fnName(),
            } },
            1 => return .{ .call1 = .{
                .symbol = fn_info.fnName(),
                .op1 = .{ .symbol = symbols[0] },
            } },
            2 => return .{ .call2 = .{
                .symbol = fn_info.fnName(),
                .op1 = .{ .symbol = symbols[0] },
                .op2 = .{ .symbol = symbols[1] },
            } },
            3 => return .{ .call3 = .{
                .symbol = fn_info.fnName(),
                .op1 = .{ .symbol = symbols[0] },
                .op2 = .{ .symbol = symbols[1] },
                .op3 = .{ .symbol = symbols[2] },
            } },
            4 => return .{ .call4 = .{
                .symbol = fn_info.fnName(),
                .op1 = .{ .symbol = symbols[0] },
                .op2 = .{ .symbol = symbols[1] },
                .op3 = .{ .symbol = symbols[2] },
                .op4 = .{ .symbol = symbols[3] },
            } },
            5 => return .{ .call5 = .{
                .symbol = fn_info.fnName(),
                .op1 = .{ .symbol = symbols[0] },
                .op2 = .{ .symbol = symbols[1] },
                .op3 = .{ .symbol = symbols[2] },
                .op4 = .{ .symbol = symbols[3] },
                .op5 = .{ .symbol = symbols[4] },
            } },
            else => unreachable,
        }
    }
    pub fn subst(callable: *Callable, dst: Operand, src: Operand) void {
        switch (callable.*) {
            inline .call0,
            .call1,
            .call2,
            .call3,
            .call4,
            .call5,
            => |call, tag| {
                var tmp = call;
                inline for (@typeInfo(@TypeOf(call)).Struct.fields) |field| {
                    if (field.type == Operand) {
                        if (builtin.testEqual(Operand, dst, @field(call, field.name))) {
                            @field(tmp, field.name) = src;
                        }
                    }
                }
                callable.* = @unionInit(Callable, @tagName(tag), tmp);
            },
        }
    }
    pub fn set(callable: *Callable, comptime field_name: [:0]const u8, value: anytype) void {
        switch (callable.*) {
            inline .call0,
            .call1,
            .call2,
            .call3,
            .call4,
            .call5,
            => |_, tag| {
                @field(@field(callable, @tagName(tag)), field_name) = value;
            },
        }
    }
};
pub const Operand = union(OperandTag) {
    call0: *const FnCall0,
    call1: *const FnCall1,
    call2: *const FnCall2,
    call3: *const FnCall3,
    call4: *const FnCall4,
    call5: *const FnCall5,
    call_impl: *const FnCallImpl,
    call_intr: *const FnCallIntr,
    constant: usize,

    symbol: [:0]const u8,
    parens: *const Parentheses,

    const OperandTag = enum(u4) {
        call0,
        call1,
        call2,
        call3,
        call4,
        call5,
        call_impl,
        call_intr,
        constant,
        symbol,
        parens,
    };

    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format) {
            .symbol => |symbol| array.writeMany(symbol),
            .constant => |constant| array.writeFormat(fmt.ud64(constant)),
            inline else => |op| op.formatWrite(array),
        }
    }
    pub fn init(any: anytype) Operand {
        inline for (@typeInfo(Operand).Union.fields) |field| {
            if (field.type == @TypeOf(any)) {
                return @unionInit(Operand, field.name, any);
            }
        }
        @compileError(@typeName(@TypeOf(any)));
    }
};

/// This system allows an implementation or interface function to be called with
/// arguments substituted by other operands.
const member_call: bool = false;

pub const FnCall0 = struct {
    symbol: [:0]const u8,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.symbol);
        array.writeMany("()");
    }
};
pub const FnCall1 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.op1);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            array.writeFormat(format.op1);
        }
        array.writeOne(')');
    }
};
pub const FnCall2 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    member: bool = member_call,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.op1);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            array.writeFormat(format.op1);
            array.writeMany(tok.end_small_item);
        }
        array.writeFormat(format.op2);
        array.writeOne(')');
    }
};
pub const FnCall3 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    member: bool = member_call,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.op1);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            array.writeFormat(format.op1);
            array.writeMany(tok.end_small_item);
        }
        array.writeFormat(format.op2);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op3);
        array.writeOne(')');
    }
};
pub const FnCall4 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    op4: Operand,
    member: bool = member_call,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.op1);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            array.writeFormat(format.op1);
            array.writeMany(tok.end_small_item);
        }
        array.writeFormat(format.op2);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op3);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op4);
        array.writeOne(')');
    }
};
pub const FnCall5 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    op4: Operand,
    op5: Operand,
    member: bool = member_call,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.op1);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            array.writeFormat(format.op1);
            array.writeMany(tok.end_small_item);
        }
        array.writeFormat(format.op2);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op3);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op4);
        array.writeMany(tok.end_small_item);
        array.writeFormat(format.op5);
        array.writeOne(')');
    }
};
pub const FnCallImpl = struct {
    impl_variant: *const out.DetailMore,
    impl_fn_info: *const implementation.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: *gen.String) void {
        format.impl_fn_info.writeCall(array, format.impl_variant);
    }
};
pub const FnCallIntr = struct {
    ctn_detail: *const out.DetailLess,
    ctn_fn_info: *const interface.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: *gen.String) void {
        format.ctn_fn_info.writeCall(array, format.ctn_detail);
    }
};
pub const Parentheses = struct {
    lhs: [:0]const u8 = "",
    op: Operand,
    rhs: [:0]const u8 = "",
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.lhs);
        array.writeFormat(format.op);
        array.writeMany(format.rhs);
    }
};
