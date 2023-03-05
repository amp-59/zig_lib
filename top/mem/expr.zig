const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const mach = gen.mach;
const builtin = gen.builtin;

const tok = @import("./tok.zig");
const detail = @import("./detail.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
//const alloc_fn = @import("./alloc_fn.zig");

const ExprTag = enum(u8) {
    scrub,
    constant,
    symbol,
    join,
    list,
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
    fn constant(expr: Expr) u64 {
        return expr.data1;
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
    pub fn scrub(expr: Expr) u64 {
        return expr.data1;
    }
    fn formatLengthCallMember(format: Expr) u64 {
        const fn_args: []const Expr = format.more()[1..];
        var len: u64 = 0;
        len +%= fn_args[0].formatLength();
        len +%= 1;
        len +%= format.more()[0].formatLength();
        len +%= 1;
        var idx: u64 = 1;
        while (idx != fn_args.len) : (idx +%= 1) {
            len +%= fn_args[idx].formatLength();
            len +%= tok.end_elem.len;
        }
        if (idx != 1) {
            len -%= tok.end_elem.len;
        }
        len +%= 1;
        return len;
    }
    fn formatLengthCall(format: Expr) u64 {
        const fn_args: []const Expr = format.more()[1..];
        var len: u64 = 0;
        len +%= format.more()[0].formatLength();
        len +%= 1;
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            len +%= fn_args[idx].formatLength();
            len +%= tok.end_elem.len;
        }
        if (idx != 0) {
            len -%= tok.end_elem.len;
        }
        len +%= 1;
        return len;
    }
    fn formatLengthList(format: Expr, array: anytype) void {
        if (format.more().len == 0) {
            return 0;
        }
        var len: u64 = 0;
        const pos: u64 = array.len();
        for (format.more()) |op| {
            len +%= op.formatLength();
            len +%= tok.end_elem.len;
        }
        if (format.more().len == 1 or
            array.len() -% pos < 40)
        {
            len -%= 1;
        }
    }
    fn formatLengthJoin(format: Expr) u64 {
        var len: u64 = 0;
        for (format.more()) |op| {
            len +%= op.formatLength();
        }
        return len;
    }
    pub fn formatLength(format: Expr) u64 {
        var len: u64 = 0;
        switch (format.tag()) {
            .scrub => {},
            .symbol => len +%= format.data2 & mask,
            .constant => len +%= fmt.ud64(format.data1).formatLength(),
            .call => len +%= formatLengthCall(format),
            .call_member => len +%= formatLengthCallMember(format),
            .join => formatLengthJoin(format),
            .list => formatLengthList(format),
        }
        return len;
    }
    fn formatWriteList(format: Expr, array: anytype) void {
        if (format.more().len == 0) {
            return;
        }
        const pos: u64 = array.len();
        for (format.more()) |op| {
            op.formatWrite(array);
            array.writeMany(tok.end_elem);
        }
        if (format.more().len == 1 or
            array.len() -% pos < 40)
        {
            array.undefine(1);
        }
    }
    fn formatWriteJoin(format: Expr, array: anytype) void {
        for (format.more()) |op| {
            op.formatWrite(array);
        }
    }
    fn formatWriteCall(format: Expr, array: anytype) void {
        const fn_args: []const Expr = format.more()[1..];
        array.writeFormat(format.more()[0]);
        array.writeOne('(');
        var idx: u64 = 0;
        while (idx != fn_args.len) : (idx +%= 1) {
            array.writeFormat(fn_args[idx]);
            array.writeMany(tok.end_elem);
        }
        if (idx != 0) {
            array.undefine(tok.end_elem.len);
        }
        array.writeOne(')');
    }
    fn formatWriteCallMember(format: Expr, array: anytype) void {
        const fn_args: []const Expr = format.more()[1..];
        fn_args[0].formatWrite(array);
        array.writeOne('.');
        array.writeFormat(format.more()[0]);
        array.writeOne('(');
        var idx: u64 = 1;
        while (idx != fn_args.len) : (idx +%= 1) {
            fn_args[idx].formatWrite(array);
            array.writeMany(tok.end_elem);
        }
        if (idx != 1) {
            array.undefine(tok.end_elem.len);
        }
        array.writeOne(')');
    }
    pub fn formatWrite(format: Expr, array: anytype) void {
        if (debug.show_expressions) {
            debug.showOpen(format);
        }
        switch (format.tag()) {
            .scrub => array.undefine(format.scrub()),
            .symbol => array.writeMany(format.symbol()),
            .constant => array.writeFormat(fmt.ud64(format.data1)),
            .call => formatWriteCall(format, array),
            .call_member => formatWriteCallMember(format, array),
            .join => formatWriteJoin(format, array),
            .list => formatWriteList(format, array),
        }
        if (debug.show_expressions) {
            debug.showClose();
        }
    }
    pub const debug = struct {
        pub const show_expressions: bool = builtin.define("show_expressions", bool, false);
        var depth: u64 = 0;
        var array: mem.StaticString(4096) = undefined;
        fn showOpen(expr: Expr) void {
            array.writeMany("expr.");
            array.writeMany(@tagName(expr.tag()));
            array.writeMany("(");
            switch (expr.tag()) {
                .symbol => {
                    if (tok.symbolName(expr.symbol())) |named| {
                        array.writeMany("tok.");
                        array.writeMany(named);
                    } else {
                        array.writeMany("\x1b[91m");
                        array.writeMany(expr.symbol());
                        array.writeMany("\x1b[0m");
                    }
                },
                .constant => {
                    array.writeFormat(fmt.ud64(expr.constant()));
                },
                else => {},
            }
            depth +%= 1;
        }
        fn showClose() void {
            depth -%= 1;
            array.writeMany("),");
            if (depth == 0) {
                array.overwriteOneBack(';');
                array.writeOne('\n');
                builtin.debug.write(array.readAll());
            }
        }
        pub fn showFunction(any: anytype) void {
            array.undefineAll();
            array.writeMany(@tagName(any));
            array.writeMany("\n");
        }
    };
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
        //if (tok.symbolName(token) == null) {
        //    builtin.debug.logAlways(token);
        //    builtin.debug.logAlways("\n");
        //}
        return .{
            .data1 = @ptrToInt(token.ptr),
            .data2 = mach.shlOr64(@enumToInt(ExprTag.symbol), 56, token.len),
        };
    }
    pub fn scrub(count: u64) Expr {
        return .{ .data1 = count, .data2 = mach.shl64(@enumToInt(ExprTag.scrub), 56) };
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

    pub fn impl0(allocator: anytype, impl_fn_info: *const impl_fn.Fn, arg_list: *const gen.ArgList) Expr {
        const exprs: []Expr = allocator.allocateIrreversible(Expr, arg_list.len +% 3);
        var idx: u64 = 0;
        exprs[idx] = Init.symbol(impl_fn_info.fnName());
        idx +%= 1;
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Init.symbol(arg);
            idx +%= 1;
        }
        return packMore(.call, exprs[0..idx]);
    }
    const Tokens = struct {
        impl_name: [:0]const u8 = tok.impl_name,
        impl_type_name: [:0]const u8 = tok.impl_type_name,
        impl_const_param: [:0]const u8 = tok.impl_const_param,
        fn determine(impl_fn_info: *const impl_fn.Fn) Tokens {
            switch (impl_fn_info.*) {
                .allocate => {
                    return .{
                        .impl_name = tok.source_impl_name,
                        .impl_type_name = tok.source_impl_type_name,
                    };
                },
                .reallocate,
                .move,
                => {
                    return .{
                        .impl_name = tok.target_impl_name,
                        .impl_type_name = tok.target_impl_type_name,
                    };
                },
                else => {
                    return .{
                        .impl_name = tok.impl_name,
                        .impl_type_name = tok.impl_type_name,
                    };
                },
            }
        }
    };

    pub fn impl1(allocator: anytype, impl_fn_info: *const impl_fn.Fn, arg_list: *const gen.ArgList, tokens: Tokens) Expr {
        const exprs: []Expr = allocator.allocateIrreversible(Expr, arg_list.len +% 3);
        var idx: u64 = 0;
        exprs[idx] = Init.symbol(impl_fn_info.fnName());
        idx +%= 1;
        if (arg_list.comptimeField()) {
            exprs[idx] = Init.symbol(switch (arg_list.kind) {
                .Parameter => tokens.impl_const_param,
                .Argument => tokens.impl_name,
            });
            idx +%= 1;
        } else if (arg_list.args[0].ptr != tok.impl_name.ptr) {
            exprs[idx] = Init.symbol(tokens.impl_type_name);
            idx +%= 1;
        }
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Init.symbol(arg);
            idx +%= 1;
        }
        return packMore(.call_member, exprs[0..idx]);
    }
    pub fn impl(allocator: anytype, any_detail: anytype, impl_fn_info: *const impl_fn.Fn) Expr {
        if (@TypeOf(any_detail.*) == detail.More) {
            return impl0(allocator, impl_fn_info, &impl_fn_info.argList(any_detail, .Argument));
        } else {
            return impl1(allocator, impl_fn_info, &impl_fn_info.argList(any_detail.more(), .Argument), Tokens.determine(impl_fn_info));
        }
    }
    pub fn intr(allocator: anytype, ctn_detail: *const detail.Less, ctn_fn_info: *const ctn_fn.Fn) Expr {
        const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        const exprs: []Expr = allocator.allocateIrreversible(Expr, arg_list.len +% 1);
        var idx: u64 = 0;
        exprs[idx] = Init.symbol(ctn_fn_info.fnName());
        idx +%= 1;
        for (arg_list.readAll()) |arg| {
            exprs[idx] = Init.symbol(arg);
            idx +%= 1;
        }
        return packMore(.call, exprs[0..idx]);
    }
};
pub usingnamespace Init;

pub const ForLoop = struct {
    expr1: Expr,
    symbol1: [:0]const u8,
    symbol2: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("for(");
        array.writeFormat(format.expr1);
        array.writeMany(",0..)|");
        array.writeMany(format.symbol1);
        array.writeMany(",");
        array.writeMany(format.symbol2);
        array.writeMany("|");
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
        array.writeMany(tok.end_expr);
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
        len +%= tok.end_expr.len;
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
        array.writeMany(tok.end_expr);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= tok.var_keyword.len;
        len +%= format.val_name.len;
        len +%= tok.colon_operator.len;
        len +%= format.type_name.len;
        len +%= tok.equal_operator.len;
        len +%= format.expr1.formatLength();
        len +%= tok.end_expr.len;
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
    return fnCall3(tok.reference_namespace, tok.pointer_count_fn_name, expr1, expr2, expr3);
}
pub inline fn pointerCountWithSentinel(expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return fnCall4(tok.pointer_count_with_sentinel_fn_name, expr1, expr2, expr3, expr4);
}
pub inline fn interfacePointerOne(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.intr_pointer_one_fn_name, expr1, expr2);
}
pub inline fn interfacePointerOpaque(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.intr_pointer_opaque_fn_name, expr1, expr2);
}
pub inline fn interfacePointerMany(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.intr_pointer_many_fn_name, expr1, expr2, expr3);
}
pub inline fn interfacePointerManyWithSentinel(expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return fnCall4(tok.intr_pointer_many_with_sentinel_fn_name, expr1, expr2, expr3, expr4);
}
pub inline fn interfacePointerCount(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.intr_pointer_count_fn_name, expr1, expr2, expr3);
}
pub inline fn interfacePointerCountWithSentinel(expr1: Expr, expr2: Expr, expr3: Expr, expr4: Expr) [5]Expr {
    return fnCall4(tok.intr_pointer_count_with_sentinel_fn_name, expr1, expr2, expr3, expr4);
}
pub inline fn amountOfTypeToBytes(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_of_type_to_bytes_fn_name, expr1, expr2);
}
pub inline fn amountOfLengthToBytes(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_of_length_to_bytes_fn_name, expr1, expr2);
}
pub inline fn amountToCountOfType(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_to_count_of_type_name, expr1, expr2);
}
pub inline fn amountToCountOfLength(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_to_count_of_length_fn_name, expr1, expr2);
}
pub inline fn amountReservedToCount(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_reserved_to_count_fn_name, expr1, expr2);
}
pub inline fn amountReservedToBytes(expr1: Expr, expr2: Expr) [3]Expr {
    return fnCall2(tok.amount_reserved_to_bytes_fn_name, expr1, expr2);
}
pub inline fn initialize(symbol: [:0]const u8, expr1: Expr) [4]Expr {
    return .{ Init.symbol(tok.period_operator), Init.symbol(symbol), Init.symbol(tok.equal_operator), expr1 };
}
pub inline fn initializer(expr1: Expr) [3]Expr {
    return .{ Init.symbol(tok.period_open_brace_operator), expr1, Init.symbol(tok.close_brace_operator) };
}
pub inline fn dereference(expr1: Expr) [2]Expr {
    return .{ expr1, Init.symbol(tok.period_asterisk_operator) };
}
pub inline fn fieldAccess(expr1: Expr, expr2: Expr) [3]Expr {
    return .{ expr1, Init.symbol(tok.period_operator), expr2 };
}
pub inline fn assign(expr1: Expr, expr2: Expr) [4]Expr {
    return .{ expr1, Init.symbol(tok.equal_operator), expr2, Init.symbol(tok.end_expr) };
}
pub inline fn discard(name: [:0]const u8) [3]Expr {
    return .{ Init.symbol(tok.discard), Init.symbol(name), Init.symbol(tok.end_expr) };
}
pub inline fn constDecl(name: [:0]const u8, type_name: [:0]const u8, value: Expr) [7]Expr {
    return .{
        Init.symbol(tok.const_keyword),  Init.symbol(name),
        Init.symbol(tok.colon_operator), Init.symbol(type_name),
        Init.symbol(tok.equal_operator), value,
        Init.symbol(tok.end_expr),
    };
}
pub inline fn varDecl(name: [:0]const u8, type_name: [:0]const u8, value: Expr) [7]Expr {
    return .{
        Init.symbol(tok.var_keyword),    Init.symbol(name),
        Init.symbol(tok.colon_operator), Init.symbol(type_name),
        Init.symbol(tok.equal_operator), value,
        Init.symbol(tok.end_expr),
    };
}
pub inline fn public(decl_expr: []Expr) [2]Expr {
    return .{ Init.symbol(tok.pub_keyword), Init.join(decl_expr) };
}
pub inline fn comptimeField(name: [:0]const u8, type_name: [:0]const u8, value: Expr) [7]Expr {
    return .{
        Init.symbol(tok.comptime_keyword), Init.symbol(name),
        Init.symbol(tok.colon_operator),   Init.symbol(type_name),
        Init.symbol(tok.equal_operator),   value,
        Init.symbol(tok.end_elem),
    };
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
pub inline fn mulAdd(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.mul_add_fn_name, expr1, expr2, expr3);
}
pub inline fn mulSub(expr1: Expr, expr2: Expr, expr3: Expr) [4]Expr {
    return fnCall3(tok.mul_sub_fn_name, expr1, expr2, expr3);
}
