const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./detail_more.zig");
};
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
const alloc_fn = @import("./alloc_fn.zig");

const ExprTag = enum(u8) {
    constant,
    symbol,
    join,
    list,
    //exprs,
    call,
    call_member,
};
pub const Expr = struct {
    data1: u64,
    data2: u64,
    const unit: u64 = 1;
    const mask: u64 = (unit << 56) - 1;
    fn symbol(expr: Expr) [:0]const u8 {
        const len: u64 = expr.data2 & mask;
        return @intToPtr([*]const u8, expr.data1)[0..len :0];
    }
    fn more(expr: Expr) []Expr {
        const len: u64 = expr.data2 & mask;
        return @intToPtr([*]Expr, expr.data1)[0..len];
    }
    pub fn tag(expr: Expr) ExprTag {
        return @intToEnum(ExprTag, expr.data2 >> 56);
    }
    pub fn args(expr: Expr) []Expr {
        if (expr.tag() == .call_member) {
            return expr.more()[2..];
        } else {
            return expr.more()[1..];
        }
    }
    pub fn formatWrite(format: Expr, array: anytype) void {
        switch (format.tag()) {
            .symbol => array.writeMany(format.symbol()),
            .constant => array.writeFormat(fmt.ud64(format.data1)),
            .join => for (format.more()) |op| {
                op.formatWrite(array);
            },
            .list => for (format.more()) |op| {
                op.formatWrite(array);
                array.writeMany(tok.end_list_item);
            },
            //.exprs => for (format.more()) |op| {
            //    op.formatWrite(array);
            //    array.writeMany(tok.end_expression);
            //},
            .call => formatWriteCall(format, array),
            .call_member => formatWriteCallMember(format, array),
        }
    }
    pub fn formatLength(format: Expr) u64 {
        var len: u64 = 0;
        switch (format.tag()) {
            .symbol => len +%= format.data2 & mask,
            .constant => len +%= fmt.ud64(format.data1).formatLength(),
            .join => for (format.more()) |op| {
                len +%= op.formatLength();
            },
            .list => for (format.more()) |op| {
                len +%= op.formatLength() +% tok.end_list_item.len;
            },
            //.exprs => for (format.more()) |op| {
            //    len +%= op.formatLength() +% tok.end_expression.len;
            //},
            .call => len +%= formatLengthCall(format),
            .call_member => len +%= formatLengthCallMember(format),
        }
        return len;
    }
    pub fn formatWriteCall(format: Expr, array: anytype) void {
        const all_exprs: []const Expr = format.more();
        const fn_name: [:0]const u8 = all_exprs[0].symbol();
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
        const all_exprs: []const Expr = format.more();
        const fn_name: [:0]const u8 = all_exprs[0].symbol();
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
            len -%= tok.end_small_item.len;
        }
        len +%= 1;
        return len;
    }
    pub fn formatWriteCallMember(format: Expr, array: anytype) void {
        const all_exprs: []const Expr = format.more();
        const fn_name: [:0]const u8 = all_exprs[0].symbol();
        const fn_args: []const Expr = all_exprs[1..];
        fn_args[0].formatWrite(array);
        array.writeOne('.');
        array.writeMany(fn_name);
        array.writeOne('(');
        var idx: u64 = 1;
        while (idx != fn_args.len) : (idx +%= 1) {
            fn_args[idx].formatWrite(array);
            array.writeMany(tok.end_small_item);
        }
        if (idx != 1) {
            array.undefine(tok.end_small_item.len);
        }
        array.writeOne(')');
    }
    pub fn formatLengthCallMember(format: Expr) u64 {
        const all_exprs: []const Expr = format.more();
        const fn_name: [:0]const u8 = all_exprs[0].symbol();
        const fn_args: []const Expr = all_exprs[1..];
        var len: u64 = 0;
        len +%= fn_args[0].formatLength();
        len +%= 1;
        len +%= fn_name.len;
        len +%= 1;
        var idx: u64 = 1;
        while (idx != fn_args.len) : (idx +%= 1) {
            len +%= fn_args[idx].formatLength();
            len +%= tok.end_small_item.len;
        }
        if (idx != 1) {
            len -%= tok.end_small_item.len;
        }
        len +%= 1;
        return len;
    }
};
pub fn subst(buf: []Expr, what: struct { dst: Expr, src: Expr }) void {
    for (buf) |*ptr| {
        if (builtin.testEqual(Expr, what.dst, ptr.*)) {
            ptr.* = what.src;
            return;
        }
    }
}
const Init = struct {
    fn packMore(tag: ExprTag, exprs: []Expr) Expr {
        return .{
            .data1 = @ptrToInt(exprs.ptr),
            .data2 = mach.shlOr64(@enumToInt(tag), 56, exprs.len),
        };
    }
    pub fn constant(value: u64) Expr {
        return .{
            .data1 = value,
            .data2 = mach.shl64(@enumToInt(ExprTag.constant), 56),
        };
    }
    pub fn symbol(token: [:0]const u8) Expr {
        return .{
            .data1 = @ptrToInt(token.ptr),
            .data2 = mach.shlOr64(@enumToInt(ExprTag.symbol), 56, token.len),
        };
    }
    pub fn join(exprs: []Expr) Expr {
        return packMore(.join, exprs);
    }
    pub fn list(exprs: []Expr) Expr {
        return packMore(.list, exprs);
    }
    pub fn call(exprs: []Expr) Expr {
        return packMore(.call, exprs);
    }
    pub fn callMember(exprs: []Expr) Expr {
        return packMore(.call_member, exprs);
    }
    fn comptimeField(arg_list: gen.ArgList) bool {
        for (arg_list.readAll()) |arg| {
            if (arg.ptr == tok.impl_name.ptr) {
                return false;
            }
        }
        return true;
    }
    pub fn impl(allocator: anytype, detail: anytype, impl_fn_info: *const impl_fn.Fn) Expr {
        const ctn_scope: bool = @TypeOf(detail.*) == out.DetailLess;
        const impl_detail: *const out.DetailMore = if (ctn_scope) detail.more() else detail;
        const arg_list: gen.ArgList = impl_fn_info.argList(impl_detail, .Argument);
        const comptime_field: bool = ctn_scope and comptimeField(arg_list);
        const exprs: []Expr = allocator.allocateIrreversible(
            Expr,
            arg_list.len +% @boolToInt(comptime_field) +% 1,
        );
        var idx: u64 = 0;
        exprs[idx] = Init.symbol(impl_fn_info.fnName());
        idx +%= 1;
        if (comptime_field) {
            exprs[idx] = Init.symbol(tok.impl_name);
            idx +%= 1;
        }
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Init.symbol(arg);
            idx +%= 1;
        }
        if (ctn_scope) {
            return Init.callMember(exprs[0..idx]);
        } else {
            return Init.call(exprs[0..idx]);
        }
    }
    pub fn intr(allocator: anytype, ctn_detail: *const out.DetailLess, ctn_fn_info: *const ctn_fn.Fn) Expr {
        const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        const exprs: []Expr = allocator.allocateIrreversible(
            Expr,
            arg_list.len +% @boolToInt(arg_list.field) +% 1,
        );
        var idx: u64 = 0;
        exprs[idx] = Init.symbol(ctn_fn_info.fnName());
        idx +%= 1;
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Init.symbol(arg);
            idx +%= 1;
        }
        return Init.call(exprs[0..idx]);
    }
};
pub usingnamespace Init;

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
        return len;
    }
};
pub const FieldAccess = struct {
    expr1: Expr,
    expr2: Expr,
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

pub inline fn fnCall1(fn_name: [:0]const u8, expr1: Expr) [2]Expr {
    return .{ Init.symbol(fn_name), expr1 };
}
pub inline fn fnCall2(fn_name: [:0]const u8, expr1: Expr, expr2: Expr) [3]Expr {
    return .{ Init.symbol(fn_name), expr1, expr2 };
}
pub inline fn fnCall3(fn_name: [:0]const u8, expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return .{ Init.symbol(fn_name), expr1, expr2, expr3 };
}
pub inline fn fnCall4(fn_name: [:0]const u8, expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return .{ Init.symbol(fn_name), expr1, expr2, expr3, expr4 };
}
pub inline fn fnCall5(fn_name: [:0]const u8, expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr, expr5: Expr) [5]Expr {
    return .{ Init.symbol(fn_name), expr1, expr2, expr3, expr4, expr5 };
}
pub inline fn pointerOne(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.pointer_one_fn_name, expr1, expr2);
}
pub inline fn pointerOpaque(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.pointer_opaque_fn_name, expr1, expr2);
}
pub inline fn pointerMany(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.pointer_many_fn_name, expr1, expr2, expr3);
}
pub inline fn pointerManyWithSentinel(expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return fnCall4(tok.pointer_many_with_sentinel_fn_name, expr1, expr2, expr3, expr4);
}
pub inline fn pointerCount(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.pointer_count_fn_name, expr1, expr2, expr3);
}
pub inline fn pointerCountWithSentinel(expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return fnCall4(tok.pointer_count_with_sentinel_fn_name, expr1, expr2, expr3, expr4);
}

pub inline fn initializeS(symbol: [:0]const u8, expr1: Expr) [4]Expr {
    return .{ Init.symbol("."), Init.symbol(symbol), Init.symbol(" = "), expr1 };
}
pub inline fn initializerS(expr1: Expr) [3]Expr {
    return .{ Init.symbol(".{ "), expr1, Init.symbol(" }") };
}
pub inline fn dereferenceS(expr1: Expr) [2]Expr {
    return .{ expr1, Init.symbol(tok.period_asterisk_operator) };
}
pub inline fn fieldAccessS(expr1: Expr, expr2: Expr) [3]Expr {
    return .{ expr1, Init.symbol(tok.period_operator), expr2 };
}
pub inline fn assignS(expr1: Expr, expr2: Expr) [3]Expr {
    return .{ expr1, Init.symbol(tok.equal_operator), expr2 };
}
pub inline fn initialize(allocator: anytype, symbol: [:0]const u8, expr1: Expr) *[4]Expr {
    return allocator.duplicateIrreversible([4]Expr, .{ Init.symbol("."), Init.symbol(symbol), Init.symbol(" = "), expr1 });
}
pub inline fn initializer(allocator: anytype, expr1: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ Init.symbol(".{ "), expr1, Init.symbol(" }") });
}
pub inline fn dereference(allocator: anytype, expr1: Expr) *[2]Expr {
    return allocator.duplicateIrreversible([2]Expr, .{ expr1, Init.symbol(tok.period_asterisk_operator) });
}
pub inline fn assign(allocator: anytype, expr1: Expr, expr2: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ expr1, Init.symbol(tok.equal_operator), expr2 });
}

pub inline fn addEqu(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.add_equ_fn_name, expr1, expr2);
}
pub inline fn subEqu(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.sub_equ_fn_name, expr1, expr2);
}
pub inline fn add(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.add_fn_name, expr1, expr2);
}
pub inline fn alignA(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.aligna_fn_name, expr1, expr2);
}
pub inline fn alignB(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.alignb_fn_name, expr1, expr2);
}
pub inline fn @"and"(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.and_fn_name, expr1, expr2);
}
pub inline fn andn(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.and_not_fn_name, expr1, expr2);
}
pub inline fn cmov(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.cmov_fn_name, expr1, expr2);
}
pub inline fn mul(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.mul_fn_name, expr1, expr2);
}
pub inline fn @"or"(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.or_fn_name, expr1, expr2);
}
pub inline fn shl(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.shl_fn_name, expr1, expr2);
}
pub inline fn shr(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.shr_fn_name, expr1, expr2);
}
pub inline fn sub(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.sub_fn_name, expr1, expr2);
}
pub inline fn divT(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.div_trunc_fn_name, expr1, expr2);
}
pub inline fn divX(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.div_exact_fn_name, expr1, expr2);
}
pub inline fn unpck2x(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.unpack_double_fn_name, expr1, expr2);
}
pub inline fn unpck1x(expr1: Expr) [2]Expr {
    return fnCall1(tok.unpack_single_fn_name, expr1);
}
pub inline fn subOr(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.sub_or_fn_name, expr1, expr2, expr3);
}
pub inline fn shlOr(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.shl_or_fn_name, expr1, expr2, expr3);
}
