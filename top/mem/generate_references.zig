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

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

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
pub fn assignmentOp(op1: anytype, op2: anytype) AssignmentOp {
    return .{
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
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
pub inline fn dereferenceOp(op1: anytype) expr.Parentheses {
    return .{
        .op = expr.Operand.init(op1),
        .rhs = ".*",
    };
}
pub inline fn addEqualOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.add_equ_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn subtractEqualOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.subtract_equ_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn addOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.add_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn alignAboveOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.subtract_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn alignBelowOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.align_below_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn andOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.and_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn andNotOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.and_not_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn conditionalMoveOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.conditional_move_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn multiplyOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.multiply_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn orOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.or_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn shiftLeftOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.shift_left_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn shiftRightOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.shift_right_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn subtractOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.subtract_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub inline fn unpackDoubleApproxOp(op1: anytype, op2: anytype) expr.FnCall2 {
    return .{
        .symbol = tok.unpack_double_fn_name,
        .op1 = expr.Operand.init(op1),
        .op2 = expr.Operand.init(op2),
    };
}
pub fn writeComma(array: *gen.String) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, tok.end_small_item, array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(tok.end_small_item);
    }
}
pub fn writeArgument(array: *gen.String, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
fn writeFunctionBodyGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, info: *Info) void {
    const allocated_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.allocated_byte_address),
    };
    const aligned_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.aligned_byte_address),
    };
    const unstreamed_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.unstreamed_byte_address),
    };
    const undefined_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.undefined_byte_address),
    };
    const unwritable_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.unwritable_byte_address),
    };
    const unallocated_byte_address: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.unallocated_byte_address),
    };
    const allocated_byte_count: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.allocated_byte_count),
    };
    const aligned_byte_count: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.aligned_byte_count),
    };
    const writable_byte_count: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.writable_byte_count),
    };
    const alignment: expr.FnCallImpl = .{
        .impl_variant = impl_variant,
        .impl_fn_info = implementation.get(.alignment),
    };
    const subtract_op_1: expr.FnCall2 = .{
        .symbol = tok.subtract_fn_name,
        .op1 = .{ .symbol = tok.low_alignment_specifier_name },
        .op2 = .{ .constant = 1 },
    };
    const shift_left_op_65535_48: expr.FnCall2 = .{
        .symbol = tok.shift_left_fn_name,
        .op1 = .{ .constant = 65535 },
        .op2 = .{ .constant = 48 },
    };
    const shift_right_op_lb_16: expr.FnCall2 = .{
        .symbol = tok.shift_right_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const shift_right_op_ub_16: expr.FnCall2 = .{
        .symbol = tok.shift_right_fn_name,
        .op1 = .{ .symbol = tok.undefined_byte_address_word_access },
        .op2 = .{ .constant = 16 },
    };
    const or_op_1_65535_48: expr.FnCall2 = .{
        .symbol = tok.or_fn_name,
        .op1 = .{ .call2 = &subtract_op_1 },
        .op2 = .{ .call2 = &shift_left_op_65535_48 },
    };
    const unpck1x_op: expr.FnCall1 = .{
        .symbol = tok.unpack_single_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
    };
    const unpck2x_op: expr.FnCall2 = .{
        .symbol = tok.unpack_double_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
        .op2 = .{ .symbol = tok.undefined_byte_address_word_access },
    };
    const sentinel_pointer_op: expr.FnCall2 = .{
        .symbol = tok.pointer_opaque_fn_name,
        .op1 = .{ .symbol = tok.child_specifier_name },
        .op2 = .{ .symbol = tok.sentinel_specifier_name },
    };
    const undefined_child_pointer_op: expr.FnCall2 = .{
        .symbol = tok.pointer_one_fn_name,
        .op1 = .{ .symbol = tok.child_specifier_name },
        .op2 = .{ .call_impl = &undefined_byte_address },
    };
    const sentinel_pointer_deref_op: expr.Parentheses = .{
        .op = .{ .call2 = &sentinel_pointer_op },
        .rhs = ".*",
    };
    const undefined_child_pointer_deref_op: expr.Parentheses = .{
        .op = .{ .call2 = &undefined_child_pointer_op },
        .rhs = ".*",
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
        .define => {
            array.writeFormat(addEqualOp(tok.undefined_byte_address_word_ptr, tok.offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                array.writeFormat(assignmentOp(&undefined_child_pointer_deref_op, &sentinel_pointer_deref_op));
            }
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            array.writeFormat(subtractEqualOp(tok.undefined_byte_address_word_ptr, tok.offset_bytes_name));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                array.writeFormat(assignmentOp(&undefined_child_pointer_deref_op, &sentinel_pointer_deref_op));
            }
            return array.writeMany(tok.end_expression);
        },
        .seek => {
            array.writeFormat(addEqualOp(tok.unstreamed_byte_address_word_ptr, tok.offset_bytes_name));
            return array.writeMany(tok.end_expression);
        },
        .tell => {
            array.writeFormat(subtractEqualOp(tok.unstreamed_byte_address_word_ptr, tok.offset_bytes_name));
            return array.writeMany(tok.end_expression);
        },
        .allocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(tok.address_of_impl, tok.offset_of_automatic_storage));
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
                    array.writeFormat(shift_right_op_lb_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(tok.allocated_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(subtractOp(&aligned_byte_address, &alignment));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.allocated_byte_address_word_access);
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_address => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_address.impl_fn_info);
            }
            if (impl_variant.techs.disjunct_alignment) {
                if (has_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        array.writeFormat(andNotOp(&shift_right_op_lb_16, &subtract_op_1));
                        return array.writeMany(tok.end_expression);
                    }
                    array.writeFormat(andNotOp(tok.allocated_byte_address_word_access, &or_op_1_65535_48));
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(tok.allocated_byte_address_word_access, &subtract_op_1));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(alignAboveOp(tok.slave_specifier_call_unallocated_byte_address, tok.low_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(allocated_byte_address.impl_fn_info);
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(alignAboveOp(&allocated_byte_address, tok.low_alignment_specifier_name));
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
                    array.writeFormat(shift_right_op_ub_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(andNotOp(tok.undefined_byte_address_word_access, &shift_left_op_65535_48));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(addOp(&allocated_byte_address, tok.undefined_byte_address_word_access));
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
            if (has_static_maximum_length or
                has_packed_approximate_capacity)
            {
                array.writeFormat(addOp(&allocated_byte_address, &allocated_byte_count));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.slave_specifier_call_unmapped_byte_address);
            return array.writeMany(tok.end_expression);
        },
        .unwritable_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(&unallocated_byte_address, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(unallocated_byte_address.impl_fn_info);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(subtractOp(tok.unallocated_byte_address_word_access, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                }
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expression);
            }
            array.writeFormat(addOp(&aligned_byte_address, &writable_byte_count));
            return array.writeMany(tok.end_expression);
        },
        .allocated_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count.impl_fn_info);
                } else {
                    array.writeFormat(addOp(&alignment, &aligned_byte_count));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count.impl_fn_info);
                } else {
                    array.writeFormat(addOp(&alignment, &aligned_byte_count));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(writable_byte_count.impl_fn_info);
            }
            array.writeFormat(subtractOp(&unallocated_byte_address, &allocated_byte_address));
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
                array.writeFormat(addOp(&writable_byte_count, tok.high_alignment_specifier_name));
                return array.writeMany(tok.end_expression);
            }
            return info.setAlias(writable_byte_count.impl_fn_info);
        },
        .writable_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                array.writeFormat(subtractOp(&unwritable_byte_address, &aligned_byte_address));
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length) {
                array.writeFormat(multiplyOp(tok.count_specifier_name, tok.call_sizeof_child));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: expr.FnCall2 = alignBelowOp(&unpck2x_op, tok.high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck2x_op, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                if (impl_variant.specs.sentinel) {
                    const align_below_op: expr.FnCall2 = alignBelowOp(&unpck1x_op, tok.high_alignment_specifier_name);
                    array.writeFormat(subtractOp(&align_below_op, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(alignBelowOp(&unpck1x_op, tok.high_alignment_specifier_name));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const subtract_op: expr.FnCall2 = subtractOp(&allocated_byte_count, tok.high_alignment_specifier_name);
                if (has_unit_alignment) {
                    array.writeFormat(subtract_op);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(subtractOp(&subtract_op, &alignment));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_count.impl_fn_info);
            } else {
                array.writeFormat(subtractOp(&allocated_byte_count, &alignment));
                return array.writeMany(tok.end_expression);
            }
        },
        .defined_byte_count => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                array.writeFormat(subtractOp(&undefined_byte_address, &allocated_byte_address));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(subtractOp(&undefined_byte_address, &aligned_byte_address));
                return array.writeMany(tok.end_expression);
            }
        },
        .undefined_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(subtractOp(&unwritable_byte_address, &undefined_byte_address));
            return array.writeMany(tok.end_expression);
        },
        .streamed_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(subtractOp(&unstreamed_byte_address, &aligned_byte_address));
            return array.writeMany(tok.end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                array.writeFormat(subtractOp(&undefined_byte_address, &unstreamed_byte_address));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(subtractOp(&unwritable_byte_address, &unstreamed_byte_address));
                return array.writeMany(tok.end_expression);
            }
        },
        .alignment => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.disjunct_alignment and
                has_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(andOp(&shift_right_op_lb_16, &subtract_op_1));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(andOp(tok.allocated_byte_address_word_access, &subtract_op_1));
                    return array.writeMany(tok.end_expression);
                }
            } else {
                array.writeFormat(subtractOp(&aligned_byte_address, &allocated_byte_address));
                return array.writeMany(tok.end_expression);
            }
        },
    }
}
fn writeFunctions(array: *gen.String, impl_variant: *const out.DetailMore) void {
    for (implementation.key) |*impl_fn_info| {
        if (!impl_fn_info.hasCapability(impl_variant)) {
            continue;
        }
        var info: Info = .{ .start = array.len() };
        impl_fn_info.writeSignature(array, impl_variant);
        array.writeMany("{\n");
        writeFunctionBodyGeneric(array, impl_variant, impl_fn_info, &info);
        array.writeMany("}\n");
        writeSimpleRedecl(array, impl_fn_info, &info);
    }
}
fn writeDeclarations(array: *gen.String, impl_variant: *const out.DetailMore) void {
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
inline fn writeComptimeField(array: *gen.String, impl_variant: *const out.DetailMore, comptime fn_tag: Fn) void {
    const args: gen.ArgList = implementation.get(fn_tag).argList(impl_variant, .Parameter);
    writeComptimeFieldInternal(array, fn_tag, &args);
}
inline fn writeFields(array: *gen.String, impl_variant: *const out.DetailMore) void {
    writeComptimeField(array, impl_variant, .allocated_byte_address);
    writeComptimeField(array, impl_variant, .aligned_byte_address);
    writeComptimeField(array, impl_variant, .unallocated_byte_address);
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
    writeComptimeField(array, impl_variant, .unwritable_byte_address);
    writeComptimeField(array, impl_variant, .allocated_byte_count);
    writeComptimeField(array, impl_variant, .writable_byte_count);
    writeComptimeField(array, impl_variant, .aligned_byte_count);
}

fn writeReturnType(array: *gen.String, impl_fn_info: *const Fn) void {
    if (impl_fn_info.mut == .Mutable) {
        array.writeMany(" void ");
    } else {
        array.writeMany(" " ++ tok.word_type_name ++ " ");
    }
}
inline fn writeTypeFunction(array: *gen.String, accm_spec_index: u16, impl_variant: *const out.DetailMore) void {
    array.writeMany("fn ");
    impl_variant.writeImplementationName(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ": " ++ tok.generic_spec_type_name);
    gen.writeIndex(array, accm_spec_index);
    array.writeMany(") type {\nreturn (struct {\n");
    {
        writeFields(array, impl_variant);
        writeDeclarations(array, impl_variant);
        writeFunctions(array, impl_variant);
    }
    array.writeMany("});\n}\n");
}
pub fn generateReferences() void {
    var array: gen.String = undefined;
    array.undefineAll();
    var accm_spec_index: u16 = 0;
    var ctn_index: u16 = 0;
    while (ctn_index != out.specifications.len) : (ctn_index +%= 1) {
        const ctn_group: []const []const u16 = out.specifications[ctn_index];
        var spec_index: u16 = 0;
        while (spec_index != ctn_group.len) : (spec_index +%= 1) {
            defer accm_spec_index +%= 1;
            const spec_group: []const u16 = ctn_group[spec_index];
            var impl_index: u16 = 0;
            while (impl_index != spec_group.len) : (impl_index +%= 1) {
                if (spec_group.len != 0) {
                    writeTypeFunction(&array, accm_spec_index, &out.impl_variants[spec_group[impl_index]]);
                }
            }
        }
    }
    gen.appendSourceFile(&array, "reference.zig");
}
pub const main = generateReferences;
