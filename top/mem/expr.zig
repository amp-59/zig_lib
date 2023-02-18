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
const interface = @import("./interface.zig");
const implementation = @import("./implementation.zig");

const ExprTag = enum(u8) {
    call,
    constant,
    symbol,
    join,
    list,
};
const Value = extern union {
    call: *const FnCall,
    symbol: [*:0]const u8,
    any: [*]const Expr,
    constant: u64,

    pub const Tagged = union(ExprTag) {
        call: *const FnCall,
        symbol: [:0]const u8,
        join: []const Expr,
        list: []const Expr,
        constant: u64,
    };
    pub inline fn tagged(value: *const Value) Tagged {
        const expr: *const Expr = @fieldParentPtr(Expr, "value", value);
        switch (expr.tag) {
            .call => return .{ .call = value.call },
            .constant => return .{ .constant = value.constant },
            .symbol => return .{ .symbol = value.symbol[0..expr.extra :0] },
            .join => return .{ .join = value.any[0..expr.extra] },
            .list => return .{ .list = value.any[0..expr.extra] },
        }
    }
};
// Unsound
const UntaggedExpr = struct {
    pub fn formatWrite(format: Expr, array: anytype) void {
        switch (format.tag) {
            .call => array.writeFormat(format.value.call.*),
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
            .call => len +%= format.value.call.formatLength(),
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
    pub fn constant(value: u64) Expr {
        const ret: Expr = .{
            .tag = .constant,
            .value = .{ .constant = value },
            .extra = 0,
        };
        return ret;
    }
    pub fn call(value: *const FnCall) Expr {
        const ret: Expr = .{
            .tag = .call,
            .value = .{ .call = value },
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
    pub fn join(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .join,
            .value = .{ .any = value.ptr },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
    pub fn list(value: []const Expr) Expr {
        const ret: Expr = .{
            .tag = .list,
            .value = .{ .any = value.ptr },
            .extra = @intCast(u32, value.len),
        };
        return ret;
    }
};

pub const Expr = union(ExprTag) {
    call: *const FnCall,
    symbol: [:0]const u8,
    join: []const Expr,
    list: []const Expr,
    constant: u64,
    pub fn formatWrite(format: Expr, array: anytype) void {
        switch (format) {
            .call => array.writeFormat(format.call.*),
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
    op1: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall2 = struct {
    symbol: [:0]const u8,
    op1: Expr,
    op2: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall3 = struct {
    symbol: [:0]const u8,
    op1: Expr,
    op2: Expr,
    op3: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall4 = struct {
    symbol: [:0]const u8,
    op1: Expr,
    op2: Expr,
    op3: Expr,
    op4: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall5 = struct {
    symbol: [:0]const u8,
    op1: Expr,
    op2: Expr,
    op3: Expr,
    op4: Expr,
    op5: Expr,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCallImpl = struct {
    impl_variant: *const out.DetailMore,
    impl_fn_info: *const implementation.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        format.impl_fn_info.writeCall(array, format.impl_variant);
    }
};
pub const FnCallIntr = struct {
    ctn_detail: *const out.DetailLess,
    ctn_fn_info: *const interface.Fn,
    member: bool = member_call,
    const Format = @This();
    pub inline fn formatWrite(format: Format, array: anytype) void {
        format.ctn_fn_info.writeCall(array, format.ctn_detail);
    }
};
pub const FnCall = struct {
    symbol: [:0]const u8,
    ops: []Expr,
    member: bool = member_call,
    const Format = @This();

    pub fn op(call: *const FnCall) Expr {
        return Expr.call(call);
    }
    pub fn subst(call: *FnCall, dst: Expr, src: Expr) void {
        for (call.ops) |*ptr| {
            if (builtin.testEqual(Expr, dst, ptr.*)) {
                ptr.* = src;
                break;
            }
        }
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.member) {
            array.writeFormat(format.ops[0]);
            array.writeOne('.');
            array.writeMany(format.symbol);
            array.writeOne('(');
            var len: u64 = 1;
            while (len != format.ops.len) : (len +%= 1) {
                array.writeFormat(format.ops[len]);
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
            while (len != format.ops.len) : (len +%= 1) {
                array.writeFormat(format.ops[len]);
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
            len +%= format.ops[0].formatLength();
            len +%= 1;
            len +%= format.symbol.len;
            len +%= 1;
            var idx: u64 = 1;
            while (len != format.ops.len) : (idx +%= 1) {
                len +%= format.ops[idx].formatLength();
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
            while (idx != format.ops.len) : (idx +%= 1) {
                len +%= format.ops[idx].formatLength();
                len +%= tok.end_small_item.len;
            }
            if (idx != 0) {
                len -%= tok.end_small_item.len;
            }
            len +%= 1;
        }
        return len;
    }

    pub fn impl(allocator: anytype, impl_detail: *const out.DetailMore, impl_fn_info: *const implementation.Fn) FnCall {
        const arg_list: gen.ArgList = impl_fn_info.argList(impl_detail, .Argument);
        const ops: []Expr = allocator.allocateIrreversible(Expr, @max(arg_list.len(), 1));
        for (arg_list.readAll()) |symbol, i| {
            ops[i] = Expr.symbol(symbol);
        }
        return .{ .symbol = impl_fn_info.fnName(), .ops = ops[0..arg_list.len()] };
    }
    pub fn intr(allocator: anytype, ctn_detail: *const out.DetailLess, ctn_fn_info: *const interface.Fn) FnCall {
        const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        const ops: []Expr = allocator.allocateIrreversible(Expr, @max(arg_list.len(), 1));
        for (arg_list.readAll()) |symbol, i| {
            ops[i] = Expr.symbol(symbol);
        }
        return .{ .symbol = ctn_fn_info.fnName(), .ops = ops };
    }
    pub fn allocate(allocator: anytype, comptime Call: type, call: Call) FnCall {
        return data(allocator.allocateIrreversible(Expr, @max((@typeInfo(Call).Struct.fields.len - 1), 1)), Call, call);
    }
    pub fn data(buf: []Expr, comptime Call: type, call: Call) FnCall {
        const fields: []const builtin.Type.StructField = @typeInfo(Call).Struct.fields;
        var ret: FnCall = .{ .symbol = call.symbol, .member = call.member, .ops = buf };
        var len: u64 = 0;
        inline for (fields) |field| {
            if (field.type == Expr) {
                ret.ops[len] = @field(call, field.name);
                len +%= 1;
            }
        }
        ret.ops = ret.ops[0..len];
        return ret;
    }
};
pub const ForLoop = struct {
    op1: Expr,
    symbol1: [:0]const u8,
    symbol2: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("for (");
        array.writeFormat(format.op1);
        array.writeMany(") |");
        array.writeMany(format.symbol1);
        array.writeMany(", ");
        array.writeMany(format.symbol2);
        array.writeMany("| ");
    }
};
pub const FieldAccess = struct {
    op1: Expr,
    symbol: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(tok.period_asterisk_operator);
        array.writeMany(format.symbol);
    }
};
pub const ConstDecl = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.const_keyword);
        array.writeMany(format.var_name);
        array.writeMany(tok.colon_operator);
        array.writeMany(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op1);
        array.writeMany(tok.end_expression);
    }
};
pub const VarDecl = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.var_keyword);
        array.writeFormat(format.var_name);
        array.writeMany(tok.colon_operator);
        array.writeFormat(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op1);
        array.writeMany(tok.end_expression);
    }
};
pub const Initializer = struct {
    type_name: [:0]const u8,
    op1: Expr,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(tok.var_keyword);
        array.writeFormat(format.var_name);
        array.writeMany(tok.colon_operator);
        array.writeFormat(format.type_name);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op1);
        array.writeMany(tok.end_expression);
    }
};

pub inline fn initializeS(symbol: [:0]const u8, op1: Expr) [4]Expr {
    return .{ Expr.symbol("."), Expr.symbol(symbol), Expr.symbol(" = "), op1 };
}
pub inline fn initializerS(op1: Expr) [3]Expr {
    return .{ Expr.symbol(".{ "), op1, Expr.symbol(" }") };
}
pub inline fn dereferenceS(op1: Expr) [2]Expr {
    return .{ op1, Expr.symbol(tok.period_asterisk_operator) };
}
pub inline fn assignS(op1: Expr, op2: Expr) [3]Expr {
    return .{ op1, Expr.symbol(tok.equal_operator), op2 };
}
pub inline fn initialize(allocator: anytype, symbol: [:0]const u8, op1: Expr) *[4]Expr {
    return allocator.duplicateIrreversible([4]Expr, .{ Expr.symbol("."), Expr.symbol(symbol), Expr.symbol(" = "), op1 });
}
pub inline fn initializer(allocator: anytype, op1: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ Expr.symbol(".{ "), op1, Expr.symbol(" }") });
}
pub inline fn dereference(allocator: anytype, op1: Expr) *[2]Expr {
    return allocator.duplicateIrreversible([2]Expr, .{ op1, Expr.symbol(tok.period_asterisk_operator) });
}
pub inline fn assign(allocator: anytype, op1: Expr, op2: Expr) *[3]Expr {
    return allocator.duplicateIrreversible([3]Expr, .{ op1, Expr.symbol(tok.equal_operator), op2 });
}
pub inline fn addEqu(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn subEqu(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn add(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignA(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignB(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.alignb_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn @"and"(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn andn(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_not_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn cmov(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.cmov_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn mul(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.mul_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn @"or"(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.or_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shl(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shl_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shr(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shr_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn sub(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn unpck2x(allocator: anytype, op1: Expr, op2: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.unpack_double_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn unpck1x(allocator: anytype, op1: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall1, .{ .symbol = tok.unpack_single_fn_name, .op1 = op1 });
}
pub inline fn subOr(allocator: anytype, op1: Expr, op2: Expr, op3: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.sub_or_fn_name, .op1 = op1, .op2 = op2, .op3 = op3 });
}
pub inline fn shlOr(allocator: anytype, op1: Expr, op2: Expr, op3: Expr) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.shl_or_fn_name, .op1 = op1, .op2 = op2, .op3 = op3 });
}
