const fmt = @import("../fmt.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./detail_more.zig");
};
const config = @import("./config.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
const alloc_fn = @import("./alloc_fn.zig");

/// `TaggedExpr` and `UntaggedExpr` (should) have the same behaviour, but
/// `TaggedExpr` is slightly larger at runtime but better in every other way that
/// matters.
pub const Expr = UntaggedExpr;

const ExprTag = enum(u8) {
    call,
    call_member,
    constant,
    symbol,
    join,
    list,
};
pub const TaggedExpr = union(ExprTag) {
    call: *const FnCall,
    call_member: *const FnCall,
    join: []const Expr,
    list: []const Expr,
    symbol: [:0]const u8,
    constant: u64,
    pub fn formatWrite(format: Expr, array: anytype) void {
        switch (format) {
            .call => array.writeFormat(makeCall(format.call)),
            .call_member => array.writeFormat(makeMemberCall(format.member_call)),
            .symbol => array.writeMany(format.symbol),
            .constant => array.writeFormat(fmt.ud64(format.constant)),
            .join => for (format.join) |op| {
                op.formatWrite(array);
            },
            .list => for (format.list) |op| {
                op.formatWrite(array);
                array.writeMany(tok.end_item);
            },
        }
    }
    pub fn formatLength(format: Expr) u64 {
        var len: u64 = 0;
        switch (format) {
            .call => len +%= format.call.formatLength(),
            .call_member => len +%= format.call_member.formatLength(),
            .symbol => len +%= format.symbol.len,
            .constant => len +%= fmt.ud64(format.constant).formatLength(),
            .join => for (format.join) |op| {
                len +%= op.formatLength();
            },
            .list => for (format.list) |op| {
                len +%= op.formatLength();
                len +%= tok.end_item.len;
            },
        }
        return len;
    }
    pub fn call(value: *const FnCall) Expr {
        return .{ .call = value };
    }
    pub fn symbol(value: [:0]const u8) Expr {
        return .{ .symbol = value };
    }
    pub fn constant(value: u64) Expr {
        return .{ .constant = value };
    }
    pub fn join(value: []const Expr) Expr {
        return .{ .join = value };
    }
    pub fn list(value: []const Expr) Expr {
        return .{ .list = value };
    }
    pub var debug: bool = false;
};
const UntaggedExpr = struct {
    tag: ExprTag,
    value: Value,
    extra: u32,

    const Value = extern union {
        symbol: [*:0]const u8,
        any: [*]Expr,
        constant: u64,
    };
    pub fn formatWrite(format: Expr, array: anytype) void {
        switch (format.tag) {
            .call => formatWriteCall(format, array),
            .call_member => formatWriteCallMember(format, array),
            .symbol => array.writeMany(format.value.symbol[0..format.extra]),
            .constant => array.writeFormat(fmt.ud64(format.extra)),
            .join => for (format.value.any[0..format.extra]) |op| {
                op.formatWrite(array);
            },
            .list => for (format.value.any[0..format.extra]) |op| {
                op.formatWrite(array);
                array.writeMany(tok.end_item);
            },
        }
    }
    pub fn formatLength(format: Expr) u64 {
        var len: u64 = 0;
        switch (format.tag) {
            .call => formatLengthCall(format),
            .call_member => formatLengthCallMember(format),
            .symbol => len +%= format.extra,
            .constant => len +%= fmt.ud64(format.value.constant).formatLength(),
            .join => for (format.value.any[0..format.extra]) |op| {
                len +%= op.formatLength();
            },
            .list => for (format.value.any[0..format.extra]) |op| {
                len +%= op.formatLength();
                len +%= tok.end_item.len;
            },
        }
        return len;
    }
    fn assertSymbol(expr: Expr) [:0]const u8 {
        return expr.value.symbol[0..expr.extra :0];
    }
    fn assertMore(expr: Expr) []Expr {
        return expr.value.any[0..expr.extra];
    }
    pub fn formatWriteCall(format: Expr, array: anytype) void {
        const all_exprs: []const Expr = format.assertMore();
        const fn_name: [:0]const u8 = all_exprs[0].assertSymbol();
        const fn_args: []const Expr = all_exprs[1..];
        array.writeMany(fn_name);
        array.writeOne('(');
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            array.writeFormat(fn_args[idx]);
            array.writeMany(tok.end_small_item);
        }
        if (idx != 0) {
            array.undefine(tok.end_small_item.len);
        }
        array.writeOne(')');
    }
    pub fn formatLengthCall(format: Expr) u64 {
        const all_exprs: []const Expr = format.assertMore();
        const fn_name: [:0]const u8 = all_exprs[0].assertSymbol();
        const fn_args: []const Expr = all_exprs[1..];
        var len: u64 = 0;
        len +%= fn_name.len;
        len +%= 1;
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            len +%= fn_args[idx].formatLength();
            len +%= tok.end_small_item.len;
        }
        if (idx != 0) {
            len +%= tok.end_small_item.len;
        }
        len +%= 1;
        return len;
    }
    pub fn formatWriteCallMember(format: Expr, array: anytype) void {
        const all_exprs: []const Expr = format.assertMore();
        const fn_name: [:0]const u8 = all_exprs[0].assertSymbol();
        const fn_args: []const Expr = all_exprs[2..];
        array.writeFormat(all_exprs[1]);
        array.writeOne('.');
        array.writeMany(fn_name);
        array.writeOne('(');
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            array.writeFormat(fn_args[idx]);
            array.writeMany(tok.end_small_item);
        }
        if (idx != 0) {
            array.undefine(tok.end_small_item.len);
        }
        array.writeOne(')');
    }
    pub fn formatLengthCallMember(format: Expr) u64 {
        const all_exprs: []const Expr = format.assertMore();
        const fn_name: [:0]const u8 = all_exprs[0].assertSymbol();
        const fn_args: []const Expr = all_exprs[2..];
        var len: u64 = 0;
        len +%= all_exprs[1].formatLength();
        len +%= 1;
        len +%= fn_name.len;
        len +%= 1;
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            len +%= .writeFormat(fn_args[idx]);
            len +%= .writeMany(tok.end_small_item);
        }
        if (idx != 1) {
            len -%= tok.end_small_item.len;
        }
        len +%= 1;
        return len;
    }
    pub fn constant(value: u64) Expr {
        const ret: Expr = .{
            .tag = .constant,
            .value = .{ .constant = value },
            .extra = 0,
        };
        return ret;
    }
    pub inline fn symbol(value: [:0]const u8) Expr {
        const ret: Expr = .{
            .tag = .symbol,
            .value = .{ .symbol = value.ptr },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub inline fn join(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .join,
            .value = .{ .any = @constCast(value.ptr) },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub inline fn list(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .list,
            .value = .{ .any = @constCast(value.ptr) },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub inline fn call(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .call,
            .value = .{ .any = @constCast(value.ptr) },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub inline fn call1(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .call_member,
            .value = .{ .any = @constCast(value.ptr) },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub fn subst(expr: *Expr, dst: Expr, src: Expr) void {
        for (expr.assertMore()) |*ptr| {
            if (builtin.testEqual(Expr, dst, ptr.*)) {
                ptr.* = src;
                return;
            }
        }
        if (config.debug_argument_substitution_match_fail) {
            testing.printN(4096, .{ call.symbol, ":\n" });
            for (call.exprs) |*ptr| {
                testing.printN(65536, .{
                    fmt.render(.{ .infer_type_names = true }, src),   " != ",
                    fmt.render(.{ .infer_type_names = true }, ptr.*), '\n',
                });
            }
        }
    }
};

pub usingnamespace Expr;

/// This system allows an implementation or interface function to be called with
/// arguments substituted by other operands.
const member_call: bool = false;

pub const FnCall0 = struct {
    symbol: [:0]const u8,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall1 = struct {
    symbol: [:0]const u8,
    arg1: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall2 = struct {
    symbol: [:0]const u8,
    arg1: Expr,
    arg2: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall3 = struct {
    symbol: [:0]const u8,
    arg1: Expr,
    arg2: Expr,
    arg3: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall4 = struct {
    symbol: [:0]const u8,
    arg1: Expr,
    arg2: Expr,
    arg3: Expr,
    arg4: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall5 = struct {
    symbol: [:0]const u8,
    arg1: Expr,
    arg2: Expr,
    arg3: Expr,
    arg4: Expr,
    arg5: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCallImpl = struct {
    impl_variant: *const out.DetailMore,
    impl_fn_info: *const impl_fn.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        format.impl_fn_info.writeCall(array, format.impl_variant);
    }
};
pub const FnCallIntr = struct {
    ctn_detail: *const out.DetailLess,
    ctn_fn_info: *const ctn_fn.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        format.ctn_fn_info.writeCall(array, format.ctn_detail);
    }
};
fn makeMemberCall(exprs: []Expr) FnCall {
    const fn_name: [:0]const u8 = exprs[0].value.symbol[0..exprs[0].extra :0];
    return .{
        .symbol = fn_name,
        .exprs = exprs[1..],
        .member = true,
    };
}
fn makeCall(exprs: []Expr) FnCall {
    const fn_name: [:0]const u8 = exprs[0].value.symbol[0..exprs[0].extra :0];
    return .{
        .symbol = fn_name,
        .exprs = exprs[1..],
        .member = false,
    };
}
pub const FnCall = struct {
    symbol: [:0]const u8,
    exprs: []Expr,
    member: bool = member_call,
    const Format = @This();

    pub fn op(call: *const FnCall) Expr {
        return Expr.call(call);
    }
    pub fn subst(call: *FnCall, dst: Expr, src: Expr) void {
        for (call.exprs) |*ptr| {
            if (builtin.testEqual(Expr, dst, ptr.*)) {
                ptr.* = src;
                return;
            }
        }
        if (config.debug_argument_substitution_match_fail) {
            testing.printN(4096, .{ call.symbol, ":\n" });
            for (call.exprs) |*ptr| {
                testing.printN(65536, .{
                    fmt.render(.{ .infer_type_names = true }, src),   " != ",
                    fmt.render(.{ .infer_type_names = true }, ptr.*), '\n',
                });
            }
        }
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.exprs[0]);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
            var len: u64 = 1;
            while (len != format.exprs.len) : (len +%= 1) {
                array.writeFormat(format.exprs[len]);
                array.writeMany(tok.end_small_item);
            }
            if (len != 1) {
                array.undefine(tok.end_small_item.len);
            }
            array.writeOne(')');
        } else {
            array.writeMany(format.symbol);
            array.writeOne('(');
            var len: u64 = 0;
            while (len != format.exprs.len) : (len +%= 1) {
                array.writeFormat(format.exprs[len]);
                array.writeMany(tok.end_small_item);
            }
            if (len != 0) {
                array.undefine(tok.end_small_item.len);
            }
            array.writeOne(')');
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.member) {
            len +%= format.exprs[0].formatLength();
            len +%= 1;
            len +%= format.symbol.len;
            len +%= 1;
            var idx: u64 = 1;
            while (len != format.exprs.len) : (idx +%= 1) {
                len +%= format.exprs[idx].formatLength();
                len +%= tok.end_small_item.len;
            }
            if (len != 1) {
                len -%= tok.end_small_item.len;
            }
            len +%= 1;
        } else {
            len +%= format.symbol.len;
            len +%= 1;
            var idx: u64 = 0;
            while (idx != format.exprs.len) : (idx +%= 1) {
                len +%= format.exprs[idx].formatLength();
                len +%= tok.end_small_item.len;
            }
            if (idx != 0) {
                len -%= tok.end_small_item.len;
            }
            len +%= 1;
        }
        return len;
    }
    pub fn impl(allocator: anytype, impl_detail: *const out.DetailMore, impl_fn_info: *const impl_fn.Fn) Expr {
        const arg_list: gen.ArgList = impl_fn_info.argList(impl_detail, .Argument);
        const max: u64 = arg_list.len +% @boolToInt(arg_list.field);
        const exprs: []Expr = allocator.allocateIrreversible(Expr, max);
        var idx: u64 = 0;
        if (arg_list.field) {
            exprs[idx] = Expr.symbol(impl_fn_info.fnName());
        }
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Expr.symbol(arg);
        }
        return Expr.call(exprs);
    }
    pub fn intr(allocator: anytype, ctn_detail: *const out.DetailLess, ctn_fn_info: *const ctn_fn.Fn) Expr {
        const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        const max: u64 = arg_list.len +% @boolToInt(arg_list.field);
        const exprs: []Expr = allocator.allocateIrreversible(Expr, max);
        var idx: u64 = 0;
        if (arg_list.field) {
            exprs[idx] = Expr.symbol(ctn_fn_info.fnName());
        }
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Expr.symbol(arg);
            idx +%= 1;
        }
        return Expr.call(exprs);
    }
    pub fn allocate(allocator: anytype, comptime Call: type, call: Call) Expr {
        return data(allocator.allocateIrreversible(Expr, @max((@typeInfo(Call).Struct.fields.len - 1), 1)), Call, call);
    }
    pub fn allocate1(allocator: anytype, comptime Call: type, call: Call) Expr {
        return data(allocator.allocateIrreversible(Expr, @max((@typeInfo(Call).Struct.fields.len - 1), 1)), Call, call);
    }

    pub fn data(buf: []Expr, comptime Call: type, call: Call) FnCall {
        var ret: FnCall = .{ .symbol = call.symbol, .member = call.member, .exprs = buf };
        var len: u64 = 0;
        inline for (@typeInfo(Call).Struct.fields) |field| {
            if (field.type == Expr) {
                ret.exprs[len] = @field(call, field.name);
                len +%= 1;
            }
        }
        ret.exprs = ret.exprs[0..len];
        return ret;
    }
};
pub const ForLoop = struct {
    expr1: Expr,
    symbol1: [:0]const u8,
    symbol2: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("for (");
        array.writeFormat(format.expr1);
        array.writeMany(") |");
        array.writeMany(format.symbol1);
        array.writeMany(", ");
        array.writeMany(format.symbol2);
        array.writeMany("| ");
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 5;
        len +%= format.expr1.formatLength();
        len +%= 3;
        len +%= format.symbol1.len;
        len +%= 2;
        len +%= format.symbol2.len;
        len +%= 2;
    }
};
pub const FieldAccess = struct {
    expr1: Expr,
    symbol: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.expr1);
        array.writeMany(tok.period_asterisk_operator);
        array.writeMany(format.symbol);
    }
};
pub const ConstDecl = struct {
    val_name: [:0]const u8,
    type_name: [:0]const u8,
    expr1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.const_keyword);
        array.writeMany(format.val_name);
        if (format.type_name.ptr != tok.type_type_name.ptr) {
            array.writeMany(tok.colon_operator);
            array.writeMany(format.type_name);
        }
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.expr1);
        array.writeMany(tok.end_expression);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= tok.const_keyword.len;
        len +%= format.val_name.len;
        if (format.type_name.ptr != tok.type_type_name.ptr) {
            len +%= tok.colon_operator.len;
            len +%= format.type_name.len;
        }
        len +%= tok.equal_operator.len;
        len +%= format.expr1.formatLength();
        len +%= tok.end_expression.len;
        return len;
    }
};
pub const VarDecl = struct {
    val_name: [:0]const u8,
    type_name: [:0]const u8,
    expr1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.var_keyword);
        array.writeFormat(format.val_name);
        array.writeMany(tok.colon_operator);
        array.writeFormat(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.expr1);
        array.writeMany(tok.end_expression);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= tok.var_keyword.len;
        len +%= format.val_name.len;
        len +%= tok.colon_operator.len;
        len +%= format.type_name.len;
        len +%= tok.equal_operator.len;
        len +%= format.expr1.formatLength();
        len +%= tok.end_expression.len;
        return len;
    }
};
pub const Initializer = struct {
    type_name: [:0]const u8,
    expr1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.var_keyword);
        array.writeFormat(format.val_name);
        array.writeMany(tok.colon_operator);
        array.writeFormat(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.expr1);
        array.writeMany(tok.end_expression);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= tok.var_keyword.len;
        len +%= format.val_name.len;
        len +%= tok.colon_operator.len;
        len +%= format.type_name.len;
        len +%= tok.equal_operator.len;
        len +%= format.expr1.len;
        len +%= tok.end_expression.len;
        return len;
    }
};

pub inline fn initializeS(symbol: [:0]const u8, expr1: Expr) [4]Expr {
    return .{ Expr.symbol("."), Expr.symbol(symbol), Expr.symbol(" = "), expr1 };
}
pub inline fn initializerS(expr1: Expr) [3]Expr {
    return .{ Expr.symbol(".{ "), expr1, Expr.symbol(" }") };
}
pub inline fn dereferenceS(expr1: Expr) [2]Expr {
    return .{ expr1, Expr.symbol(tok.period_asterisk_operator) };
}
pub inline fn assignS(expr1: Expr, expr2: Expr) [3]Expr {
    return .{ expr1, Expr.symbol(tok.equal_operator), expr2 };
}
pub inline fn initialize(allocator: anytype, symbol: [:0]const u8, expr1: Expr) *[4]Expr {
    return allocator.duplicateIrreversible([4]Expr, .{ Expr.symbol("."), Expr.symbol(symbol), Expr.symbol(" = "), expr1 });
}
pub inline fn initializer(allocator: anytype, expr1: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ Expr.symbol(".{ "), expr1, Expr.symbol(" }") });
}
pub inline fn dereference(allocator: anytype, expr1: Expr) *[2]Expr {
    return allocator.duplicateIrreversible([2]Expr, .{ expr1, Expr.symbol(tok.period_asterisk_operator) });
}
pub inline fn assign(allocator: anytype, expr1: Expr, expr2: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ expr1, Expr.symbol(tok.equal_operator), expr2 });
}
pub inline fn addEqu(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_equ_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn subEqu(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_equ_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn add(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn alignA(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn alignB(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.alignb_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn @"and"(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn andn(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_not_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn cmov(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.cmov_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn mul(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.mul_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn @"or"(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.or_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn shl(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shl_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn shr(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shr_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn sub(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn unpck2x(allocator: anytype, expr1: Expr, expr2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.unpack_double_fn_name, .expr1 = expr1, .expr2 = expr2 });
}
pub inline fn unpck1x(allocator: anytype, expr1: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall1, .{ .symbol = tok.unpack_single_fn_name, .expr1 = expr1 });
}
pub inline fn subOr(allocator: anytype, expr1: Expr, expr2: Expr, expr3: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.sub_or_fn_name, .expr1 = expr1, .expr2 = expr2, .expr3 = expr3 });
}
pub inline fn shlOr(allocator: anytype, expr1: Expr, expr2: Expr, expr3: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.shl_or_fn_name, .expr1 = expr1, .expr2 = expr2, .expr3 = expr3 });
}
