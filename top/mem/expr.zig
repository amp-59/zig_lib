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

pub const Operand = union(OperandTag) {
    call: *const FnCall,
    constant: usize,
    symbol: [:0]const u8,
    any: []const Operand,

    const OperandTag = enum(u4) {
        call,
        constant,
        symbol,
        any,
    };
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format) {
            .symbol => |symbol| array.writeMany(symbol),
            .constant => |constant| array.writeFormat(fmt.ud64(constant)),
            .call => |call| call.formatWrite(array),
            .any => |any| for (any) |op| op.formatWrite(array),
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
};
pub const FnCall1 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall2 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall3 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    member: bool = member_call,
    const Format = @This();
};
pub const FnCall4 = struct {
    symbol: [:0]const u8,
    op1: Operand,
    op2: Operand,
    op3: Operand,
    op4: Operand,
    member: bool = member_call,
    const Format = @This();
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
    pub inline fn formatWrite(format: Format, array: *gen.String) void {
        format.ctn_fn_info.writeCall(array, format.ctn_detail);
    }
};
pub const FnCall = struct {
    symbol: [:0]const u8,
    ops: []Operand,
    member: bool = member_call,
    const Format = @This();

    pub fn op(call: *const FnCall) Operand {
        return .{ .call = call };
    }
    pub fn subst(call: *FnCall, dst: Operand, src: Operand) void {
        for (call.ops) |*ptr| {
            if (builtin.testEqual(Operand, dst, ptr.*)) ptr.* = src;
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
    pub fn impl(allocator: *gen.Allocator, impl_detail: *const out.DetailMore, impl_fn_info: *const implementation.Fn) FnCall {
        const arg_list: gen.ArgList = impl_fn_info.argList(impl_detail, .Argument);
        const ops: []Operand = allocator.allocateIrreversible(Operand, @max(arg_list.len(), 1));
        for (arg_list.readAll()) |symbol, i| {
            ops[i] = .{ .symbol = symbol };
        }
        return .{ .symbol = impl_fn_info.fnName(), .ops = ops[0..arg_list.len()] };
    }
    pub fn intr(allocator: *gen.Allocator, ctn_detail: *const out.DetailLess, ctn_fn_info: *const interface.Fn) FnCall {
        const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        const ops: []Operand = allocator.allocateIrreversible(Operand, @max(arg_list.len(), 1));
        for (arg_list.readAll()) |symbol, i| {
            ops[i] = .{ .symbol = symbol };
        }
        return .{ .symbol = ctn_fn_info.fnName(), .ops = ops };
    }
    pub fn allocate(allocator: *gen.Allocator, comptime Call: type, call: Call) FnCall {
        return data(allocator.allocateIrreversible(Operand, @max((@typeInfo(Call).Struct.fields.len - 1), 1)), Call, call);
    }
    pub fn data(buf: []Operand, comptime Call: type, call: Call) FnCall {
        const fields: []const builtin.Type.StructField = @typeInfo(Call).Struct.fields;
        var ret: FnCall = .{ .symbol = call.symbol, .member = call.member, .ops = buf };
        var len: u64 = 0;
        inline for (fields) |field| {
            if (field.type == Operand) {
                ret.ops[len] = @field(call, field.name);
                len +%= 1;
            }
        }
        ret.ops = ret.ops[0..len];
        return ret;
    }
};
pub const ForLoop = struct {
    op1: Operand,
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
    op1: Operand,
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
    op1: Operand,
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
    op1: Operand,
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

pub inline fn initialize(symbol: [:0]const u8, op1: Operand) [4]Operand {
    return .{ .{ .symbol = "." }, .{ .symbol = symbol }, .{ .symbol = " = " }, op1 };
}
pub inline fn initializer(op1: Operand) [3]Operand {
    return .{ .{ .symbol = ".{ " }, op1, .{ .symbol = " }" } };
}
pub inline fn dereference(op1: Operand) [2]Operand {
    return .{ op1, .{ .symbol = tok.period_asterisk_operator } };
}
pub inline fn assign(op1: Operand, op2: Operand) [3]Operand {
    return .{ op1, .{ .symbol = tok.equal_operator }, op2 };
}
pub inline fn addEqu(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn subEqu(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn add(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.add_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignA(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignB(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.alignb_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn @"and"(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn andn(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.and_not_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn cmov(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.cmov_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn mul(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.mul_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn @"or"(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.or_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shl(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shl_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shr(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.shr_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn sub(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.sub_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn unpck2x(allocator: *gen.Allocator, op1: Operand, op2: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall2, .{ .symbol = tok.unpack_double_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn unpck1x(allocator: *gen.Allocator, op1: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall1, .{ .symbol = tok.unpack_single_fn_name, .op1 = op1 });
}
pub inline fn subOr(allocator: *gen.Allocator, op1: Operand, op2: Operand, op3: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.sub_or_fn_name, .op1 = op1, .op2 = op2, .op3 = op3 });
}
pub inline fn shlOr(allocator: *gen.Allocator, op1: Operand, op2: Operand, op3: Operand) FnCall {
    return FnCall.allocate(allocator, FnCall3, .{ .symbol = tok.shl_or_fn_name, .op1 = op1, .op2 = op2, .op3 = op3 });
}
