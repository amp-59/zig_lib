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

const allocated_byte_address_fn_info: *const Fn = implementation.get(.allocated_byte_address);
const aligned_byte_address_fn_info: *const Fn = implementation.get(.aligned_byte_address);
const unstreamed_byte_address_fn_info: *const Fn = implementation.get(.unstreamed_byte_address);
const undefined_byte_address_fn_info: *const Fn = implementation.get(.undefined_byte_address);
const unwritable_byte_address_fn_info: *const Fn = implementation.get(.unwritable_byte_address);
const unallocated_byte_address_fn_info: *const Fn = implementation.get(.unallocated_byte_address);
const allocated_byte_count_fn_info: *const Fn = implementation.get(.allocated_byte_count);
const aligned_byte_count_fn_info: *const Fn = implementation.get(.aligned_byte_count);
const writable_byte_count_fn_info: *const Fn = implementation.get(.writable_byte_count);
const alignment_fn_info: *const Fn = implementation.get(.alignment);

const Info = struct {
    start: u64,
    alias: ?Fn = null,
    fn setAlias(info: *Info, impl_fn_info: Fn) void {
        info.alias = impl_fn_info;
    }
};
fn writeFunctionBodyGeneric(allocator: *gen.Allocator, array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, info: *Info) void {
    const allocated_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, allocated_byte_address_fn_info);
    const aligned_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, aligned_byte_address_fn_info);
    const unstreamed_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, unstreamed_byte_address_fn_info);
    const undefined_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, undefined_byte_address_fn_info);
    const unwritable_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, unwritable_byte_address_fn_info);
    const unallocated_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, unallocated_byte_address_fn_info);
    const allocated_byte_count_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, allocated_byte_count_fn_info);
    const aligned_byte_count_call: expr.FnCall =
        expr.FnCall.impl(allocator, impl_variant, aligned_byte_count_fn_info);
    const alignment: expr.FnCall = expr.FnCall.impl(allocator, impl_variant, alignment_fn_info);
    const has_static_maximum_length: bool =
        impl_variant.kinds.automatic or
        impl_variant.kinds.static;
    const has_packed_approximate_capacity: bool =
        impl_variant.techs.single_packed_approximate_capacity or
        impl_variant.techs.double_packed_approximate_capacity;
    const has_unit_alignment: bool =
        impl_variant.techs.auto_alignment or
        impl_variant.techs.unit_alignment;
    const sub_call_1: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.sub_fn_name,
        .op1 = .{ .symbol = tok.low_alignment_specifier_name },
        .op2 = .{ .constant = 1 },
    });
    const shl_call_65535_48: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shl_fn_name,
        .op1 = .{ .constant = 65535 },
        .op2 = .{ .constant = 48 },
    });
    const shr_call_lb_16: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shr_fn_name,
        .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
        .op2 = .{ .constant = 16 },
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
    const pointer_opaque_call_sentinel_deref_stx: [2]expr.Operand =
        expr.dereference(.{ .call = &pointer_opaque_call_sentinel });
    const pointer_one_call_undefined_deref_stx: [2]expr.Operand =
        expr.dereference(.{ .call = &pointer_one_call_undefined });
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
                    array.writeFormat(shr_call_lb_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(expr.andn(
                    allocator,
                    .{ .symbol = tok.allocated_byte_address_word_access },
                    .{ .call = &shl_call_65535_48 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(expr.sub(
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
                return info.setAlias(allocated_byte_address_fn_info.*);
            }
            if (impl_variant.techs.disjunct_alignment) {
                if (has_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        array.writeFormat(expr.andn(
                            allocator,
                            .{ .call = &shr_call_lb_16 },
                            .{ .call = &sub_call_1 },
                        ));
                        return array.writeMany(tok.end_expression);
                    }
                    const or_call_1_65535_48: expr.FnCall =
                        expr.FnCall.allocate(allocator, expr.FnCall2, .{
                        .symbol = tok.or_fn_name,
                        .op1 = .{ .call = &sub_call_1 },
                        .op2 = .{ .call = &shl_call_65535_48 },
                    });
                    array.writeFormat(expr.andn(
                        allocator,
                        .{ .symbol = tok.allocated_byte_address_word_access },
                        .{ .call = &or_call_1_65535_48 },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(expr.andn(
                    allocator,
                    .{ .symbol = tok.allocated_byte_address_word_access },
                    .{ .call = &sub_call_1 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(expr.alignA(
                        allocator,
                        .{ .symbol = tok.slave_specifier_call_unallocated_byte_address },
                        .{ .symbol = tok.low_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(allocated_byte_address_fn_info.*);
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(expr.alignA(
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
                    const shr_call_ub_16: expr.FnCall =
                        expr.FnCall.allocate(allocator, expr.FnCall2, .{
                        .symbol = tok.shr_fn_name,
                        .op1 = .{ .symbol = tok.undefined_byte_address_word_access },
                        .op2 = .{ .constant = 16 },
                    });
                    array.writeFormat(shr_call_ub_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(expr.andn(
                    allocator,
                    .{ .symbol = tok.undefined_byte_address_word_access },
                    .{ .call = &shl_call_65535_48 },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(expr.add(
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
                array.writeFormat(expr.add(
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
                    array.writeFormat(expr.sub(
                        allocator,
                        .{ .call = &unallocated_byte_address_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(unallocated_byte_address_fn_info.*);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(expr.sub(
                        allocator,
                        .{ .symbol = tok.unallocated_byte_address_word_access },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expression);
            }
            const writable_byte_count_call: expr.FnCall =
                expr.FnCall.impl(allocator, impl_variant, writable_byte_count_fn_info);
            array.writeFormat(expr.add(
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
                    return info.setAlias(aligned_byte_count_fn_info.*);
                } else {
                    array.writeFormat(expr.add(
                        allocator,
                        .{ .call = &alignment },
                        .{ .call = &aligned_byte_count_call },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count_fn_info.*);
                } else {
                    array.writeFormat(expr.add(
                        allocator,
                        .{ .call = &alignment },
                        .{ .call = &aligned_byte_count_call },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(writable_byte_count_fn_info.*);
            }
            array.writeFormat(expr.sub(
                allocator,
                .{ .call = &unallocated_byte_address_call },
                .{ .call = &allocated_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                const unpck1x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall1, .{
                    .symbol = tok.unpack_single_fn_name,
                    .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
                });
                array.writeFormat(unpck1x_call);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                const unpck2x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
                    .op2 = .{ .symbol = tok.undefined_byte_address_word_access },
                });
                array.writeFormat(unpck2x_call);
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
            return info.setAlias(writable_byte_count_fn_info.*);
        },
        .writable_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                array.writeFormat(expr.sub(
                    allocator,
                    .{ .call = &unwritable_byte_address_call },
                    .{ .call = &aligned_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length) {
                array.writeFormat(expr.mul(
                    allocator,
                    .{ .symbol = tok.count_specifier_name },
                    .{ .symbol = tok.call_sizeof_child_specifier },
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.single_packed_approximate_capacity) {
                const unpck1x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall1, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
                });
                if (impl_variant.specs.sentinel) {
                    const alignb_call: expr.FnCall = expr.alignB(
                        allocator,
                        .{ .call = &unpck1x_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    );
                    array.writeFormat(expr.sub(
                        allocator,
                        .{ .call = &alignb_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.alignB(
                        allocator,
                        .{ .call = &unpck1x_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                const unpck2x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = .{ .symbol = tok.allocated_byte_address_word_access },
                    .op2 = .{ .symbol = tok.undefined_byte_address_word_access },
                });
                if (impl_variant.specs.sentinel) {
                    const alignb_call: expr.FnCall = expr.alignB(
                        allocator,
                        .{ .call = &unpck2x_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    );
                    array.writeFormat(expr.sub(
                        allocator,
                        .{ .call = &alignb_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.alignB(
                        allocator,
                        .{ .call = &unpck2x_call },
                        .{ .symbol = tok.high_alignment_specifier_name },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const sub_call: expr.FnCall = expr.sub(
                    allocator,
                    .{ .call = &allocated_byte_count_call },
                    .{ .symbol = tok.high_alignment_specifier_name },
                );
                if (has_unit_alignment) {
                    array.writeFormat(sub_call);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.sub(
                        allocator,
                        .{ .call = &sub_call },
                        .{ .call = &alignment },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_count_fn_info.*);
            } else {
                array.writeFormat(expr.sub(
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
                array.writeFormat(expr.sub(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &allocated_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &aligned_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .undefined_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.sub(
                allocator,
                .{ .call = &unwritable_byte_address_call },
                .{ .call = &undefined_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .streamed_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.sub(
                allocator,
                .{ .call = &unstreamed_byte_address_call },
                .{ .call = &aligned_byte_address_call },
            ));
            return array.writeMany(tok.end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                array.writeFormat(expr.sub(
                    allocator,
                    .{ .call = &undefined_byte_address_call },
                    .{ .call = &unstreamed_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(expr.sub(
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
                    array.writeFormat(expr.@"and"(
                        allocator,
                        .{ .call = &shr_call_lb_16 },
                        .{ .call = &sub_call_1 },
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.@"and"(
                        allocator,
                        .{ .symbol = tok.allocated_byte_address_word_access },
                        .{ .call = &sub_call_1 },
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    .{ .call = &aligned_byte_address_call },
                    .{ .call = &allocated_byte_address_call },
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .define => {
            array.writeFormat(expr.addEqu(
                allocator,
                .{ .symbol = tok.undefined_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                const assign_ops: [3]expr.Operand = expr.assign(
                    .{ .any = &pointer_one_call_undefined_deref_stx },
                    .{ .any = &pointer_opaque_call_sentinel_deref_stx },
                );
                expr.Operand.formatWrite(.{ .any = &assign_ops }, array);
            }
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            array.writeFormat(expr.subEqu(
                allocator,
                .{ .symbol = tok.undefined_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                const assign_ops: [3]expr.Operand = expr.assign(
                    .{ .any = &pointer_one_call_undefined_deref_stx },
                    .{ .any = &pointer_opaque_call_sentinel_deref_stx },
                );
                expr.Operand.formatWrite(.{ .any = &assign_ops }, array);
            }
            return array.writeMany(tok.end_expression);
        },
        .seek => {
            array.writeFormat(expr.addEqu(
                allocator,
                .{ .symbol = tok.unstreamed_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            return array.writeMany(tok.end_expression);
        },
        .tell => {
            array.writeFormat(expr.subEqu(
                allocator,
                .{ .symbol = tok.unstreamed_byte_address_word_ptr },
                .{ .symbol = tok.offset_bytes_name },
            ));
            return array.writeMany(tok.end_expression);
        },
        .construct => {
            array.writeMany(tok.return_keyword);
            array.writeMany(".{ ");
            const sub_or_ab_lb_ab: expr.FnCall = expr.subOr(
                allocator,
                .{ .symbol = tok.source_aligned_byte_address_name },
                .{ .symbol = tok.source_allocated_byte_address_name },
                .{ .symbol = tok.source_aligned_byte_address_name },
            );
            if (impl_variant.fields.allocated_byte_address) {
                if (has_packed_approximate_capacity) {
                    if (impl_variant.techs.disjunct_alignment) {
                        if (config.packed_capacity_low) {
                            const shl_or_sub_or_16_lb_c: expr.FnCall = expr.shlOr(
                                allocator,
                                .{ .call = &sub_or_ab_lb_ab },
                                .{ .constant = 16 },
                                .{ .symbol = tok.source_single_approximation_counts_name },
                            );
                            const init_lb_word: [4]expr.Operand = expr.initialize(
                                tok.allocated_byte_address_word_field_name,
                                .{ .call = &shl_or_sub_or_16_lb_c },
                            );
                            expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                            array.writeMany(tok.end_small_item);
                        } else {
                            const shl_or_lb_c_48_sub_or: expr.FnCall = expr.shlOr(
                                allocator,
                                .{ .symbol = tok.source_single_approximation_counts_name },
                                .{ .constant = 48 },
                                .{ .call = &sub_or_ab_lb_ab },
                            );
                            const init_lb_word: [4]expr.Operand = expr.initialize(
                                tok.allocated_byte_address_word_field_name,
                                .{ .call = &shl_or_lb_c_48_sub_or },
                            );
                            expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                            array.writeMany(tok.end_small_item);
                        }
                    } else {
                        // No disjunct alignment
                        if (config.packed_capacity_low) {
                            const shl_or_ab_16_lb_c: expr.FnCall = expr.shlOr(
                                allocator,
                                .{ .symbol = tok.source_allocated_byte_address_name },
                                .{ .constant = 16 },
                                .{ .symbol = tok.source_single_approximation_counts_name },
                            );
                            const init_lb_word: [4]expr.Operand = expr.initialize(
                                tok.allocated_byte_address_word_field_name,
                                .{ .call = &shl_or_ab_16_lb_c },
                            );
                            expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                            array.writeMany(tok.end_small_item);
                        } else {
                            const shl_or_lb_c_48_ab: expr.FnCall = expr.shlOr(
                                allocator,
                                .{ .symbol = tok.source_single_approximation_counts_name },
                                .{ .constant = 48 },
                                .{ .symbol = tok.source_allocated_byte_address_name },
                            );
                            const init_lb_word: [4]expr.Operand = expr.initialize(
                                tok.allocated_byte_address_word_field_name,
                                .{ .call = &shl_or_lb_c_48_ab },
                            );
                            expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                            array.writeMany(tok.end_small_item);
                        }
                    }
                } else {
                    if (impl_variant.techs.disjunct_alignment) {
                        const init_lb_word: [4]expr.Operand = expr.initialize(
                            tok.allocated_byte_address_word_field_name,
                            .{ .call = &sub_or_ab_lb_ab },
                        );
                        expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                        array.writeMany(tok.end_small_item);
                    } else {
                        const init_lb_word: [4]expr.Operand = expr.initialize(
                            tok.allocated_byte_address_word_field_name,
                            .{ .symbol = tok.source_allocated_byte_address_name },
                        );
                        expr.Operand.formatWrite(.{ .any = &init_lb_word }, array);
                        array.writeMany(tok.end_small_item);
                    }
                }
            }
            if (impl_variant.fields.unstreamed_byte_address) {
                const init_ss_word: [4]expr.Operand = expr.initialize(
                    tok.unstreamed_byte_address_word_field_name,
                    .{ .symbol = tok.source_aligned_byte_address_name },
                );
                expr.Operand.formatWrite(.{ .any = &init_ss_word }, array);
                array.writeMany(tok.end_small_item);
            }
            if (impl_variant.fields.undefined_byte_address) {
                if (impl_variant.techs.double_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        const shl_or_ab_16_ub_c: expr.FnCall = expr.shlOr(
                            allocator,
                            .{ .symbol = tok.source_aligned_byte_address_name },
                            .{ .constant = 16 },
                            .{ .symbol = tok.source_double_approximation_counts_name },
                        );
                        const init_ub_word: [4]expr.Operand = expr.initialize(
                            tok.undefined_byte_address_word_field_name,
                            .{ .call = &shl_or_ab_16_ub_c },
                        );
                        expr.Operand.formatWrite(.{ .any = &init_ub_word }, array);
                        array.writeMany(tok.end_small_item);
                    } else {
                        const shl_or_ub_c_48_ab: expr.FnCall = expr.shlOr(
                            allocator,
                            .{ .symbol = tok.source_double_approximation_counts_name },
                            .{ .constant = 48 },
                            .{ .symbol = tok.source_aligned_byte_address_name },
                        );
                        const init_ub_word: [4]expr.Operand = expr.initialize(
                            tok.undefined_byte_address_word_field_name,
                            .{ .call = &shl_or_ub_c_48_ab },
                        );
                        expr.Operand.formatWrite(.{ .any = &init_ub_word }, array);
                        array.writeMany(tok.end_small_item);
                    }
                } else {
                    const init_ub_word: [4]expr.Operand = expr.initialize(
                        tok.undefined_byte_address_word_field_name,
                        .{ .symbol = tok.source_aligned_byte_address_name },
                    );
                    expr.Operand.formatWrite(.{ .any = &init_ub_word }, array);
                    array.writeMany(tok.end_small_item);
                }
            }
            if (impl_variant.fields.unallocated_byte_address) {
                const init_ss_word: [4]expr.Operand = expr.initialize(
                    tok.unallocated_byte_address_word_field_name,
                    .{ .symbol = tok.source_unallocated_byte_address_name },
                );
                expr.Operand.formatWrite(.{ .any = &init_ss_word }, array);
                array.writeMany(tok.end_small_item);
            }
            array.writeMany("}");
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
pub fn generateReferences() !void {
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
