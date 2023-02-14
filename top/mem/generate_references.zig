//! This stage generates reference impls
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const meta = @import("../meta.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const testing = @import("../testing.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const config = @import("./config.zig");
const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
    usingnamespace @import("./zig-out/src/specifications.zig");
};
const implementation = @import("./implementation.zig");

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = true;
pub const is_silent: bool = false;

const Fn = implementation.Fn;

const Info = struct {
    start: u64,
    alias: ?*const Fn = null,
    fn setAlias(info: *Info, impl_fn_info: *const Fn) void {
        info.alias = impl_fn_info;
    }
};
pub const AssignmentOp = struct {
    op1: expr.Operand,
    op2: expr.Operand,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(tok.equal_operator);
        array.writeFormat(format.op2);
    }
};
pub fn assignmentOp(op1: expr.Operand, op2: expr.Operand) AssignmentOp {
    return .{ .op1 = op1, .op2 = op2 };
}
pub const FieldAccessOp = struct {
    op1: expr.Operand,
    symbol: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeFormat(format.op1);
        array.writeMany(tok.period_asterisk_operator);
        array.writeMany(format.symbol);
    }
};
pub const ConstDeclOp = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: expr.Operand,
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
pub const VarDeclOp = struct {
    var_name: [:0]const u8,
    type_name: [:0]const u8,
    op1: expr.Operand,
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
pub inline fn dereferenceOp(op1: expr.Operand) expr.Parentheses {
    return .{ .op = op1, .rhs = tok.period_asterisk_operator };
}
pub inline fn addEqualOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.add_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn subtractEqualOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.subtract_equ_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn addOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.add_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignAboveOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.subtract_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn alignBelowOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.align_below_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn andOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.and_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn andNotOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.and_not_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn conditionalMoveOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.conditional_move_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn multiplyOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.multiply_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn orOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.or_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shiftLeftOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.shift_left_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn shiftRightOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.shift_right_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn subtractOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.subtract_fn_name, .op1 = op1, .op2 = op2 });
}
pub inline fn unpackDoubleApproxOp(allocator: *gen.Allocator, op1: expr.Operand, op2: expr.Operand) expr.FnCall {
    return expr.FnCall.allocate(allocator, expr.FnCall2, .{ .symbol = tok.unpack_double_fn_name, .op1 = op1, .op2 = op2 });
}
fn showGenerate(impl_fn_info: implementation.Fn) void {
    var buf: [4096]u8 = undefined;
    builtin.debug.logSuccessAIO(&buf, &.{ impl_fn_info.fnName(), "\n" });
}
fn writeFunctionBodyGeneric(allocator: *gen.Allocator, array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, info: *Info) void {
    const allocated_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.allocated_byte_address));
    const aligned_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.aligned_byte_address));
    const unstreamed_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.unstreamed_byte_address));
    const undefined_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.undefined_byte_address));
    const unwritable_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.unwritable_byte_address));
    const unallocated_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.unallocated_byte_address));
    const allocated_byte_count_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.allocated_byte_count));
    const aligned_byte_count_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.aligned_byte_count));
    const writable_byte_count_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.writable_byte_count));
    const alignment: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, implementation.get(.alignment));
    const subtract_call_1: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.subtract_fn_name,
        .op1 = .{ .symbol = tok.low_alignment_specifier_name },
        .op2 = .{ .constant = 1 },
    });
    const shift_left_call_65535_48: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shift_left_fn_name,
        .op1 = .{ .constant = 65535 },
        .op2 = .{ .constant = 48 },
    });
    const shift_right_call_lb_16: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shift_right_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    });
    const shift_right_call_ub_16: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shift_right_fn_name,
        .op1 = .{ .symbol = tok.undefined_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    });
    const or_call_1_65535_48: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.or_fn_name,
        .op1 = .{ .call = &subtract_call_1 },
        .op2 = .{ .call = &shift_left_call_65535_48 },
    });
    const unpck1x_op: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall1, .{
        .symbol = tok.unpack_single_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
    });
    const unpck2x_op: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.unpack_double_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
        .op2 = .{ .symbol = tok.undefined_byte_address_word_access },
    });
    const pointer_opaque_call_sentinel: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.pointer_opaque_fn_name,
        .op1 = .{ .symbol = tok.child_specifier_name },
        .op2 = .{ .symbol = tok.sentinel_specifier_name },
    });
    const pointer_one_call_undefined: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.pointer_one_fn_name,
        .op1 = .{ .symbol = tok.child_specifier_name },
        .op2 = .{ .call = &undefined_byte_address_call },
    });
    const pointer_opaque_call_sentinel_deref_stx: expr.Parentheses = .{
        .op = .{ .call = &pointer_opaque_call_sentinel },
        .rhs = tok.period_asterisk_operator,
    };
    const pointer_one_call_undefined_deref_stx: expr.Parentheses = .{
        .op = .{ .call = &pointer_one_call_undefined },
        .rhs = tok.period_asterisk_operator,
    };
    const has_static_maximum_length: bool =
        impl_variant.kinds.automatic or
        impl_variant.kinds.static;
    const has_packed_approximate_capacity: bool =
        impl_variant.techs.single_packed_approximate_capacity or
        impl_variant.techs.double_packed_approximate_capacity;
    const has_unit_alignment: bool =
        impl_variant.techs.auto_alignment or
        impl_variant.techs.unit_alignment;
    switch (impl_fn_info.*) {
        .allocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.automatic) {
                const address_of_impl_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.add_fn_name,
                    .op1 = .{ .symbol = tok.address_of_impl },
                    .op2 = .{ .symbol = tok.offset_of_automatic_storage },
                });
                array.writeFormat(address_of_impl_call);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                array.writeMany(tok.slave_specifier_call_unallocated_byte_address);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity or
                impl_variant.techs.single_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_call_lb_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(
                    allocator,
                    .{ .symbol = tok.allocated_byte_address_word_access },
                    .{ .call = &shift_left_call_65535_48 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &aligned_byte_address_call },
                    .{ .call = &alignment },
                ));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.allocated_byte_address_word_access);
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_address => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                return info.setAlias(implementation.get(.allocated_byte_address));
            }
            if (impl_variant.techs.disjunct_alignment) {
                if (has_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        array.writeFormat(andNotOp(
                            allocator,
                            .{ .call = &shift_right_call_lb_16 },
                            .{ .call = &subtract_call_1 },
                        ));
                        return array.writeMany(tok.end_expression);
                    }
                    array.writeFormat(andNotOp(
                        allocator,
                        .{ .symbol = tok.allocated_byte_address_word_access },
                        .{ .call = &or_call_1_65535_48 },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(
                    allocator,
                    .{ .symbol = tok.allocated_byte_address_word_access },
                    .{ .call = &subtract_call_1 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(alignAboveOp(
                        allocator,
                        .{ .symbol = tok.slave_specifier_call_unallocated_byte_address },
                        .{ .symbol = tok.low_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(implementation.get(.allocated_byte_address));
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(alignAboveOp(
                    allocator,
                    .{ .call = &allocated_byte_address_call },
                    .{ .symbol = tok.low_alignment_specifier_name },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .unstreamed_byte_address => {
            array.writeMany(tok.return_keyword);
            array.writeMany(tok.unstreamed_byte_address_word_access);
            return array.writeMany(tok.end_expression);
        },
        .undefined_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (config.packed_capacity_low) {
                    array.writeFormat(shift_right_call_ub_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(
                    allocator,
                    .{ .symbol = tok.undefined_byte_address_word_access },
                    .{ .call = &shift_left_call_65535_48 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(
                    allocator,
                    .{ .call = &allocated_byte_address_call },
                    .{ .symbol = tok.undefined_byte_address_word_access },
                ));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.undefined_byte_address_word_access);
            return array.writeMany(tok.end_expression);
        },
        .unallocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.fields.unallocated_byte_address) {
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length or has_packed_approximate_capacity) {
                array.writeFormat(addOp(
                    allocator,
                    .{ .call = &allocated_byte_address_call },
                    .{ .call = &allocated_byte_count_call },
                ));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.slave_specifier_call_unmapped_byte_address);
            return array.writeMany(tok.end_expression);
        },
        .unwritable_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(
                        allocator,
                        .{ .call = &unallocated_byte_address_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(implementation.get(.unallocated_byte_address));
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(
                        allocator,
                        .{ .symbol = tok.unallocated_byte_address_word_access },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expression);
            }
            array.writeFormat(addOp(
                allocator,
                .{ .call = &aligned_byte_address_call },
                .{ .call = &writable_byte_count_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .allocated_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(implementation.get(.aligned_byte_count));
                } else {
                    array.writeFormat(addOp(
                        allocator,
                        .{ .call = &alignment },
                        .{ .call = &aligned_byte_count_call },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(implementation.get(.aligned_byte_count));
                } else {
                    array.writeFormat(addOp(
                        allocator,
                        .{ .call = &alignment },
                        .{ .call = &aligned_byte_count_call },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(implementation.get(.writable_byte_count));
            }
            array.writeFormat(subtractOp(
                allocator,
                .{ .call = &unallocated_byte_address_call },
                .{ .call = &allocated_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                array.writeFormat(unpck1x_op);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                array.writeFormat(unpck2x_op);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.specs.sentinel) {
                array.writeFormat(expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.add_fn_name,
                    .op1 = .{ .call = &aligned_byte_count_call },
                    .op2 = .{ .symbol = tok.high_alignment_specifier_name },
                }));
                return array.writeMany(tok.end_expression);
            }
            return info.setAlias(implementation.get(.writable_byte_count));
        },
        .writable_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &unwritable_byte_address_call },
                    .{ .call = &aligned_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length) {
                array.writeFormat(multiplyOp(
                    allocator,
                    .{ .symbol = tok.count_specifier_name },
                    .{ .symbol = tok.call_sizeof_child_specifier },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: expr.FnCall = alignBelowOp(
                        allocator,
                        .{ .call = &unpck2x_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    );
                    array.writeFormat(subtractOp(
                        allocator,
                        .{ .call = &align_below_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(alignBelowOp(
                        allocator,
                        .{ .call = &unpck2x_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: expr.FnCall = alignBelowOp(
                        allocator,
                        .{ .call = &unpck2x_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    );
                    array.writeFormat(subtractOp(
                        allocator,
                        .{ .call = &align_below_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(alignBelowOp(
                        allocator,
                        .{ .call = &unpck2x_op },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const subtract_op: expr.FnCall = subtractOp(
                    allocator,
                    .{ .call = &allocated_byte_count_call },
                    .{ .symbol = tok.high_alignment_specifier_name },
                );
                if (has_unit_alignment) {
                    array.writeFormat(subtract_op);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(subtractOp(
                        allocator,
                        .{ .call = &subtract_op },
                        .{ .call = &alignment },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(implementation.get(.allocated_byte_count));
            } else {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &allocated_byte_count_call },
                    .{ .call = &alignment },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .defined_byte_count => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &allocated_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &aligned_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .undefined_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(subtractOp(
                allocator,
                .{ .call = &unwritable_byte_address_call },
                .{ .call = &undefined_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .streamed_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(subtractOp(
                allocator,
                .{ .call = &unstreamed_byte_address_call },
                .{ .call = &aligned_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &unstreamed_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &unwritable_byte_address_call },
                    .{ .call = &unstreamed_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .alignment => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.disjunct_alignment and
                has_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(andOp(
                        allocator,
                        .{ .call = &shift_right_call_lb_16 },
                        .{ .call = &subtract_call_1 },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(andOp(
                        allocator,
                        .{ .symbol = tok.allocated_byte_address_word_access },
                        .{ .call = &subtract_call_1 },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else {
                array.writeFormat(subtractOp(
                    allocator,
                    .{ .call = &aligned_byte_address_call },
                    .{ .call = &allocated_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .define => {
            array.writeFormat(addEqualOp(
                allocator,
                .{ .symbol = tok.undefined_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                array.writeFormat(assignmentOp(
                    .{ .parens = &pointer_one_call_undefined_deref_stx },
                    .{ .parens = &pointer_opaque_call_sentinel_deref_stx },
                ));
            }
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            array.writeFormat(subtractEqualOp(
                allocator,
                .{ .symbol = tok.undefined_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                array.writeFormat(assignmentOp(
                    .{ .parens = &pointer_one_call_undefined_deref_stx },
                    .{ .parens = &pointer_opaque_call_sentinel_deref_stx },
                ));
            }
            return array.writeMany(tok.end_expression);
        },
        .seek => {
            array.writeFormat(addEqualOp(
                allocator,
                .{ .symbol = tok.unstreamed_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            return array.writeMany(tok.end_expression);
        },
        .tell => {
            array.writeFormat(subtractEqualOp(
                allocator,
                .{ .symbol = tok.unstreamed_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            return array.writeMany(tok.end_expression);
        },
    }
}
fn writeFunctions(allocator: *gen.Allocator, array: *gen.String, impl_variant: *const out.DetailMore) void {
    for (implementation.key) |*impl_fn_info| {
        if (!impl_fn_info.hasCapability(impl_variant)) {
            continue;
        }
        var info: Info = .{ .start = array.len() };
        impl_fn_info.writeSignature(array, impl_variant);
        array.writeMany("{\n");
        writeFunctionBodyGeneric(allocator, array, impl_variant, impl_fn_info, &info);
        array.writeMany("}\n");
        writeSimpleRedecl(array, impl_fn_info, &info);
    }
}
fn writeDeclarations(allocator: *gen.Allocator, array: *gen.String, impl_variant: *const out.DetailMore) void {
    _ = allocator;
    array.writeMany("const " ++ tok.impl_type_name ++ " = @This();\n");
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        return array.writeMany("const Static = fn () callconv(.Inline) " ++
            tok.word_type_name ++ tok.end_expression);
    }
    if (impl_variant.kinds.parametric) {
        return array.writeMany("const Slave = fn (" ++ tok.slave_specifier_const_ptr_type_name ++ ") callconv(.Inline) " ++
            tok.word_type_name ++ tok.end_expression);
    }
    if (impl_variant.techs.unit_alignment) {
        return array.writeMany("pub const unit_alignment: usize = spec.unit_alignment;\n");
    }
    if (impl_variant.techs.auto_alignment) {
        return array.writeMany("pub const auto_alignment: usize = spec.low_alignment;\n");
    }
}
fn writeSimpleRedecl(array: *gen.String, impl_fn_info: *const Fn, info: *Info) void {
    if (info.alias) |impl_fn_alias_info| {
        array.undefine(array.len() - info.start);
        array.writeMany("pub const ");
        array.writeMany(impl_fn_info.fnName());
        array.writeMany(" = ");
        array.writeMany(impl_fn_alias_info.fnName());
        array.writeMany(";\n");
        info.alias = null;
    }
}
fn writeComptimeFieldInternal(array: *gen.String, fn_tag: Fn, args: *const gen.ArgList) void {
    if (args.len() == 0) {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Static = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
    if (args.len() == 1 and
        args.readOneAt(0).ptr == tok.slave_specifier_name.ptr)
    {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Slave = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
}
inline fn writeComptimeField(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: Fn) void {
    const args: gen.ArgList = impl_fn_info.argList(impl_variant, .Parameter);
    writeComptimeFieldInternal(array, impl_fn_info, &args);
}
inline fn writeFields(allocator: *gen.Allocator, array: *gen.String, impl_variant: *const out.DetailMore) void {
    _ = allocator;
    writeComptimeField(array, impl_variant, Fn.allocated_byte_address);
    writeComptimeField(array, impl_variant, Fn.aligned_byte_address);
    writeComptimeField(array, impl_variant, Fn.unallocated_byte_address);
    if (impl_variant.fields.automatic_storage) {
        if (impl_variant.specs.sentinel) {
            array.writeMany(tok.automatic_storage_with_sentinel_field);
        } else {
            array.writeMany(tok.automatic_storage_field);
        }
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(tok.allocated_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(tok.unstreamed_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(tok.undefined_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(tok.unallocated_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    writeComptimeField(array, impl_variant, Fn.unwritable_byte_address);
    writeComptimeField(array, impl_variant, Fn.allocated_byte_count);
    writeComptimeField(array, impl_variant, Fn.writable_byte_count);
    writeComptimeField(array, impl_variant, Fn.aligned_byte_count);
}

fn writeReturnType(array: *gen.String, impl_fn_info: *const Fn) void {
    if (impl_fn_info.mut == .Mutable) {
        array.writeMany(" void ");
    } else {
        array.writeMany(" " ++ tok.word_type_name ++ " ");
    }
}
inline fn writeTypeFunction(allocator: *gen.Allocator, array: *gen.String, accm_spec_index: u16, impl_variant: *const out.DetailMore) void {
    array.writeMany("fn ");
    impl_variant.writeImplementationName(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ": " ++ tok.generic_spec_type_name);
    gen.writeIndex(array, accm_spec_index);
    array.writeMany(") type {\nreturn (struct {\n");
    {
        writeFields(allocator, array, impl_variant);
        writeDeclarations(allocator, array, impl_variant);
        writeFunctions(allocator, array, impl_variant);
    }
    array.writeMany("});\n}\n");
}
pub fn generateReferences() void {
    var address_space: AddressSpace = .{};
    var allocator: gen.Allocator = try gen.Allocator.init(&address_space);
    var array: gen.String = undefined;
    array.undefineAll();
    var accm_spec_index: u16 = 0;
    var ctn_index: u16 = 0;
    while (ctn_index != out.specifications.len) : (ctn_index +%= 1) {
        const s = allocator.save();
        allocator.restore(s);
        const ctn_group: []const []const u16 = out.specifications[ctn_index];
        var spec_index: u16 = 0;
        while (spec_index != ctn_group.len) : (spec_index +%= 1) {
            defer accm_spec_index +%= 1;
            const spec_group: []const u16 = ctn_group[spec_index];
            var impl_index: u16 = 0;
            while (impl_index != spec_group.len) : (impl_index +%= 1) {
                if (spec_group.len != 0) {
                    writeTypeFunction(&allocator, &array, accm_spec_index, &out.impl_variants[spec_group[impl_index]]);
                }
            }
        }
    }
    gen.appendSourceFile(&array, "reference.zig");
}
pub const main = generateReferences;
