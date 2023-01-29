//! This stage generates reference implementations
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");
const config = @import("./config.zig");
const gen = struct {
    usingnamespace @import("./gen-0.zig");
    usingnamespace @import("./gen-1.zig");
    const type_spec = @import("./type_spec.zig").type_spec;
    const impl_details = @import("./impl_details.zig").impl_details;
};
const Array = mem.StaticString(1024 * 1024);

// zig fmt: off
const key: [18]Fn = .{
    .{ .tag = .define,                      .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .seek,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .undefine,                    .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .tell,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .allocated_byte_address,      .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_address,        .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_address,     .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .undefined_byte_address,      .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .unwritable_byte_address,     .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unallocated_byte_address,    .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .allocated_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .streamed_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_count,       .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .writable_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .undefined_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .defined_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .alignment,                   .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
};
// zig fmt: on

const impl_name: [:0]const u8 = "impl";
const impl_type_name: [:0]const u8 = "Implementation";
const impl_ptr_type_name: [:0]const u8 = "*" ++ impl_type_name;
const impl_const_ptr_type_name: [:0]const u8 = "*const " ++ impl_type_name;
const impl_param: [:0]const u8 = impl_name ++ ": " ++ impl_ptr_type_name;
const impl_const_param: [:0]const u8 = impl_name ++ ": " ++ impl_const_ptr_type_name;
const slave_name: [:0]const u8 = "allocator";
const slave_type_name: [:0]const u8 = "Allocator";
const slave_param: [:0]const u8 = slave_name ++ ": " ++ slave_type_name;
const offset_bytes_name: [:0]const u8 = "x_bytes";
const offset_bytes_param: [:0]const u8 = offset_bytes_name ++ ": 64";
const allocated_byte_address_word_field_name: [:0]const u8 = "lb_word";
const unstreamed_byte_address_word_field_name: [:0]const u8 = "ss_word";
const undefined_byte_address_word_field_name: [:0]const u8 = "ub_word";
const unallocated_byte_address_word_field_name: [:0]const u8 = "up_word";
const allocated_byte_address_word_access: [:0]const u8 = impl_name ++ "." ++ allocated_byte_address_word_field_name;
const unstreamed_byte_address_word_access: [:0]const u8 = impl_name ++ "." ++ unstreamed_byte_address_word_field_name;
const undefined_byte_address_word_access: [:0]const u8 = impl_name ++ "." ++ undefined_byte_address_word_field_name;
const unallocated_byte_address_word_access: [:0]const u8 = impl_name ++ "." ++ unallocated_byte_address_word_field_name;
const allocated_byte_address_word_ptr: [:0]const u8 = "&" ++ allocated_byte_address_word_access;
const undefined_byte_address_word_ptr: [:0]const u8 = "&" ++ undefined_byte_address_word_access;
const unstreamed_byte_address_word_ptr: [:0]const u8 = "&" ++ unstreamed_byte_address_word_access;
const unallocated_byte_address_word_ptr: [:0]const u8 = "&" ++ unallocated_byte_address_word_access;

const Fn = struct {
    tag: Tag,
    val: Value,
    loc: Location,
    mut: Mutability,
    const Tag = enum {
        define,
        seek,
        undefine,
        tell,
        allocated_byte_address,
        aligned_byte_address,
        unstreamed_byte_address,
        undefined_byte_address,
        unwritable_byte_address,
        unallocated_byte_address,
        allocated_byte_count,
        aligned_byte_count,
        streamed_byte_count,
        unstreamed_byte_count,
        writable_byte_count,
        undefined_byte_count,
        defined_byte_count,
        alignment,
    };
    const Value = enum {
        Address,
        Offset,
    };
    const Location = enum {
        Relative,
        Absolute,
    };
    const Mutability = enum {
        Mutable,
        Immutable,
    };
    fn fnName(impl_fn_info: *const Fn) []const u8 {
        return @tagName(impl_fn_info.tag);
    }
};
fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
        unreachable;
    }
}
const Operand = union(enum) {
    symbol: [:0]const u8,
    add_op: *const AddOp,
    align_above_op: *const AlignAboveOp,
    align_below_op: *const AlignBelowOp,
    and_op: *const AndOp,
    and_not_op: *const AndNotOp,
    conditional_move_op: *const ConditionalMoveOp,
    multiply_op: *const MultiplyOp,
    or_op: *const OrOp,
    shift_left_op: *const ShiftLeftOp,
    shift_right_op: *const ShiftRightOp,
    subtract_op: *const SubtractOp,
    call: *const FnCall,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        switch (format) {
            .symbol => |symbol| array.writeMany(symbol),
            .add_op => |add_op| add_op.formatWrite(array),
            .align_above_op => |align_above_op| align_above_op.formatWrite(array),
            .align_below_op => |align_below_op| align_below_op.formatWrite(array),
            .and_op => |and_op| and_op.formatWrite(array),
            .and_not_op => |and_not_op| and_not_op.formatWrite(array),
            .conditional_move_op => |conditional_move_op| conditional_move_op.formatWrite(array),
            .multiply_op => |multiply_op| multiply_op.formatWrite(array),
            .or_op => |or_op| or_op.formatWrite(array),
            .shift_left_op => |shift_left_op| shift_left_op.formatWrite(array),
            .shift_right_op => |shift_right_op| shift_right_op.formatWrite(array),
            .subtract_op => |subtract_op| subtract_op.formatWrite(array),
            .call => |call| call.formatWrite(array),
        }
    }
    pub fn formatLength(format: Format) u64 {
        return switch (format) {
            .symbol => |symbol| symbol.len,
            .add_op => |add_op| add_op.formatLength(),
            .align_above_op => |align_above_op| align_above_op.formatLength(),
            .align_below_op => |align_below_op| align_below_op.formatLength(),
            .and_op => |and_op| and_op.formatLength(),
            .and_not_op => |and_not_op| and_not_op.formatLength(),
            .conditional_move_op => |conditional_move_op| conditional_move_op.formatLength(),
            .multiply_op => |multiply_op| multiply_op.formatLength(),
            .or_op => |or_op| or_op.formatLength(),
            .shift_left_op => |shift_left_op| shift_left_op.formatLength(),
            .shift_right_op => |shift_right_op| shift_right_op.formatLength(),
            .subtract_op => |subtract_op| subtract_op.formatLength(),
            .call => |call| call.formatLength(),
        };
    }
};
pub fn formatWriteToken(op1: Operand, op2: Operand, array: anytype, fn_token: [:0]const u8) void {
    array.writeMany(fn_token);
    array.writeMany("(");
    array.writeFormat(op1);
    array.writeMany(", ");
    array.writeFormat(op2);
    array.writeMany(")");
}
const AddEquOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token = "mach.addEqu64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const SubEquOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token = "mach.subEqu64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const AddOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token = "mach.add64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const AlignAboveOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.alignA64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const AlignBelowOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.alignB64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const AndOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.and64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const AndNotOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.andn64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const ConditionalMoveOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.cmov64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const MultiplyOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.mul64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const OrOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.or64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const ShiftLeftOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.shl64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const ShiftRightOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.shr64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const SubtractOp = struct {
    op1: Operand,
    op2: Operand,
    const Format = @This();
    const fn_token: [:0]const u8 = "mach.sub64";
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return formatWriteToken(format.op1, format.op2, array, fn_token);
    }
};
const FnCall = struct {
    impl_detail: *const gen.Detail,
    impl_fn_info: *const Fn,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        writeFnSignatureOrCall(array, format.impl_detail, format.impl_fn_info, false);
    }
};
fn writeComma(array: *Array) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, ", ", array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(", ");
    }
}
fn writeArgument(array: *Array, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
fn hasCapability(impl_detail: *const gen.Detail, fn_info: *const Fn) bool {
    return switch (fn_info.tag) {
        .define,
        .undefine,
        .undefined_byte_address,
        .defined_byte_count,
        => impl_detail.modes.resize,
        .seek,
        .tell,
        .unstreamed_byte_address,
        .streamed_byte_count,
        => impl_detail.modes.stream,
        .alignment => !impl_detail.kind.automatic,
        else => true,
    };
}
fn writeFnSignatureOrCall(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const Fn, comptime sign: bool) void {
    if (sign) array.writeMany("inline fn ");
    array.writeMany(impl_fn_info.fnName());
    array.writeMany("(");
    if (impl_fn_info.mut == .Mutable) {
        writeArgument(array, if (sign) impl_param else impl_name);
    } else if (impl_detail.kind.parametric) {
        if (impl_fn_info.loc == .Absolute) {
            if (impl_fn_info.val == .Address) {
                writeArgument(array, if (sign) slave_param else slave_name);
            }
            if (impl_fn_info.val == .Offset) {
                writeArgument(array, if (sign) impl_const_param else impl_name);
                writeArgument(array, if (sign) slave_param else slave_name);
            }
        } else {
            writeArgument(array, if (sign) impl_const_param else impl_name);
        }
    } else {
        writeArgument(array, if (sign) impl_const_param else impl_name);
    }
    array.writeMany(")");
    if (impl_fn_info.mut == .Mutable) {
        if (sign) writeArgument(array, offset_bytes_param);
        if (sign) array.writeMany(" void ");
    } else {
        if (sign) array.writeMany(" u64 ");
    }
}
inline fn writeFnCallGeneric(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_detail, impl_fn_info, false);
}
inline fn writeFnSignatureGeneric(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const Fn) void {
    writeFnSignatureOrCall(array, impl_detail, impl_fn_info, true);
}
fn writeFnBodyGeneric(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const Fn) void {
    array.writeMany("{\n");
    switch (impl_fn_info.tag) {
        .define => {
            array.writeFormat(AddEquOp{
                .op1 = .{ .symbol = undefined_byte_address_word_ptr },
                .op2 = .{ .symbol = offset_bytes_name },
            });
            array.writeMany(";\n");
        },
        .undefine => {
            array.writeFormat(SubEquOp{
                .op1 = .{ .symbol = undefined_byte_address_word_ptr },
                .op2 = .{ .symbol = offset_bytes_name },
            });
            array.writeMany(";\n");
        },
        .seek => {
            array.writeFormat(AddEquOp{
                .op1 = .{ .symbol = unstreamed_byte_address_word_ptr },
                .op2 = .{ .symbol = offset_bytes_name },
            });
            array.writeMany(";\n");
        },
        .tell => {
            array.writeFormat(SubEquOp{
                .op1 = .{ .symbol = unstreamed_byte_address_word_ptr },
                .op2 = .{ .symbol = offset_bytes_name },
            });
            array.writeMany(";\n");
        },
        .defined_byte_count => {
            const undefined_byte_address: FnCall = .{
                .impl_detail = impl_detail,
                .impl_fn_info = get(.undefined_byte_address),
            };
            const aligned_byte_address: FnCall = .{
                .impl_detail = impl_detail,
                .impl_fn_info = get(.aligned_byte_address),
            };
            array.writeMany("return ");
            array.writeFormat(SubtractOp{
                .op1 = .{ .call = &undefined_byte_address },
                .op2 = .{ .call = &aligned_byte_address },
            });
            array.writeMany(";\n");
        },
        .streamed_byte_count => {
            const unstreamed_byte_address: FnCall = .{
                .impl_detail = impl_detail,
                .impl_fn_info = get(.unstreamed_byte_address),
            };
            const aligned_byte_address: FnCall = .{
                .impl_detail = impl_detail,
                .impl_fn_info = get(.aligned_byte_address),
            };
            array.writeMany("return ");
            array.writeFormat(SubtractOp{
                .op1 = .{ .call = &unstreamed_byte_address },
                .op2 = .{ .call = &aligned_byte_address },
            });
            array.writeMany(";\n");
        },
        else => {},
    }
    array.writeMany("}\n");
}
fn writeFn(array: *Array, impl_detail: *const gen.Detail, impl_fn_info: *const Fn) void {
    if (!hasCapability(impl_detail, impl_fn_info)) {
        return;
    }
    writeFnSignatureGeneric(array, impl_detail, impl_fn_info);
    writeFnBodyGeneric(array, impl_detail, impl_fn_info);
    array.writeOne('\n');
}
pub fn generateFnDefinitions() void {
    var array: Array = .{};
    for (gen.impl_details) |impl_detail| {
        for (key) |impl_fn_info| {
            writeFn(&array, &impl_detail, &impl_fn_info);
        }
        array.writeOne('\n');
    }
    file.noexcept.write(2, array.readAll());
}
