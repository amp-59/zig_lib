//! This stage generates reference impls
const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const file = @import("../../file.zig");
const serial = @import("../../serial.zig");
const tok = @import("tok.zig");
const expr = @import("expr.zig");
const attr = @import("attr.zig");
const types = @import("types.zig");
const config = @import("config.zig");
const ptr_fn = @import("ptr_fn.zig");
pub usingnamespace @import("../../start.zig");
pub const runtime_assertions: bool = false;
pub const show_expressions: bool = false;
const Allocator = config.Allocator;
const AddressSpace = Allocator.AddressSpace;
const Array = Allocator.StructuredVector(u8);
const Details = Allocator.StructuredVector(types.Implementation);
const read_impl_spec: file.ReadSpec = .{ .child = types.Implementation, .errors = .{}, .return_type = void };
const Info = struct {
    start: usize,
    alias: ?ptr_fn.Fn = null,
    fn setAlias(info: *Info, ptr_fn_info: ptr_fn.Fn) void {
        info.alias = ptr_fn_info;
    }
};
fn resizeInitializer(allocator: *Allocator, impl_variant: types.Implementation) *[3]expr.Expr {
    var buf: []expr.Expr = allocator.allocate(expr.Expr, 8);
    var len: usize = 0;
    const andn_undefined_65535: *[3]expr.Expr = allocator.duplicate([3]expr.Expr, expr.andn(
        expr.symbol(tok.undefined_byte_address_word_access),
        expr.constant(65535),
    ));
    const andn_allocated_65535: *[3]expr.Expr = allocator.duplicate([3]expr.Expr, expr.andn(
        expr.symbol(tok.allocated_byte_address_word_access),
        expr.constant(65535),
    ));
    if (impl_variant.fields.allocated_byte_address and
        impl_variant.techs.single_packed_approximate_capacity)
    {
        const or_target_single: *[3]expr.Expr = allocator.duplicate([3]expr.Expr, expr.@"or"(
            expr.call(andn_allocated_65535),
            expr.symbol(tok.interface_target_single_approximation_counts_name),
        ));
        const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.allocated_byte_address_word_field_name,
            expr.call(or_target_single),
        ));
        buf[len] = expr.join(init_lb_word);
        len +%= 1;
    }
    if (impl_variant.fields.undefined_byte_address and
        impl_variant.techs.double_packed_approximate_capacity)
    {
        const or_target_single: *[3]expr.Expr = allocator.duplicate([3]expr.Expr, expr.@"or"(
            expr.call(andn_allocated_65535),
            expr.symbol(tok.interface_target_single_approximation_counts_name),
        ));
        const or_target_double: *[3]expr.Expr = allocator.duplicate([3]expr.Expr, expr.@"or"(
            expr.call(andn_undefined_65535),
            expr.symbol(tok.interface_target_double_approximation_counts_name),
        ));
        const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.allocated_byte_address_word_field_name,
            expr.call(or_target_single),
        ));
        const init_ub_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.undefined_byte_address_word_field_name,
            expr.call(or_target_double),
        ));
        buf[len] = expr.join(init_lb_word);
        len +%= 1;
        buf[len] = expr.join(init_ub_word);
        len +%= 1;
    }
    if (impl_variant.fields.unallocated_byte_address) {
        const init_up_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.unallocated_byte_address_word_field_name,
            expr.symbol(tok.interface_target_unallocated_byte_address_name),
        ));
        buf[len] = expr.join(init_up_word);
        len +%= 1;
    }
    return allocator.duplicate([3]expr.Expr, expr.initializer(expr.list(buf[0..len])));
}
fn constructInitializer(allocator: *Allocator, impl_variant: types.Implementation, ptr_fn_info: ptr_fn.Fn) *[3]expr.Expr {
    const source_aligned_byte_address_name: [:0]const u8 = blk: {
        if (ptr_fn_info == .allocate) {
            break :blk tok.interface_source_aligned_byte_address_name;
        }
        break :blk tok.interface_target_aligned_byte_address_name;
    };
    const source_allocated_byte_address_name: [:0]const u8 = blk: {
        if (ptr_fn_info == .allocate) {
            break :blk tok.interface_source_allocated_byte_address_name;
        }
        break :blk tok.interface_target_allocated_byte_address_name;
    };
    const source_single_approximation_counts_name: [:0]const u8 = blk: {
        if (ptr_fn_info == .allocate) {
            break :blk tok.interface_source_single_approximation_counts_name;
        }
        break :blk tok.interface_target_single_approximation_counts_name;
    };
    const source_double_approximation_counts_name: [:0]const u8 = blk: {
        if (ptr_fn_info == .allocate) {
            break :blk tok.interface_source_double_approximation_counts_name;
        }
        break :blk tok.interface_target_double_approximation_counts_name;
    };
    const source_unallocated_byte_address_name: [:0]const u8 = blk: {
        if (ptr_fn_info == .allocate) {
            break :blk tok.interface_source_unallocated_byte_address_name;
        }
        break :blk tok.interface_target_unallocated_byte_address_name;
    };
    const sub_or_ab_lb_ab: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.subOr(
        expr.symbol(source_aligned_byte_address_name),
        expr.symbol(source_allocated_byte_address_name),
        expr.symbol(source_aligned_byte_address_name),
    ));
    var buf: []expr.Expr = allocator.allocate(expr.Expr, 8);
    var len: usize = 0;
    if (impl_variant.fields.allocated_byte_address) {
        if (impl_variant.techs.single_packed_approximate_capacity or
            impl_variant.techs.double_packed_approximate_capacity)
        {
            if (impl_variant.techs.disjunct_alignment) {
                if (config.packed_capacity_low) {
                    const shl_or_sub_or_16_lb_c: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                        expr.call(sub_or_ab_lb_ab),
                        expr.constant(16),
                        expr.symbol(source_single_approximation_counts_name),
                    ));
                    const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_sub_or_16_lb_c),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                } else {
                    const shl_or_lb_c_48_sub_or: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                        expr.symbol(source_single_approximation_counts_name),
                        expr.constant(48),
                        expr.call(sub_or_ab_lb_ab),
                    ));
                    const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_lb_c_48_sub_or),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                }
            } else {
                if (config.packed_capacity_low) {
                    const shl_or_ab_16_lb_c: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                        expr.symbol(source_allocated_byte_address_name),
                        expr.constant(16),
                        expr.symbol(source_single_approximation_counts_name),
                    ));
                    const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_ab_16_lb_c),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                } else {
                    const shl_or_lb_c_48_ab: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                        expr.symbol(source_single_approximation_counts_name),
                        expr.constant(48),
                        expr.symbol(source_allocated_byte_address_name),
                    ));
                    const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_lb_c_48_ab),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                }
            }
        } else {
            if (impl_variant.techs.disjunct_alignment) {
                const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                    tok.allocated_byte_address_word_field_name,
                    expr.call(sub_or_ab_lb_ab),
                ));
                buf[len] = expr.join(init_lb_word);
                len +%= 1;
            } else {
                const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                    tok.allocated_byte_address_word_field_name,
                    expr.symbol(source_allocated_byte_address_name),
                ));
                buf[len] = expr.join(init_lb_word);
                len +%= 1;
            }
        }
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        const init_ss_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.unstreamed_byte_address_word_field_name,
            expr.symbol(source_aligned_byte_address_name),
        ));
        buf[len] = expr.join(init_ss_word);
        len +%= 1;
    }
    if (impl_variant.fields.undefined_byte_address) {
        if (impl_variant.techs.double_packed_approximate_capacity) {
            if (config.packed_capacity_low) {
                const shl_or_ab_16_ub_c: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                    expr.symbol(source_aligned_byte_address_name),
                    expr.constant(16),
                    expr.symbol(source_double_approximation_counts_name),
                ));
                const init_ub_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                    tok.undefined_byte_address_word_field_name,
                    expr.call(shl_or_ab_16_ub_c),
                ));
                buf[len] = expr.join(init_ub_word);
                len +%= 1;
            } else {
                const shl_or_ub_c_48_ab: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.shlOr(
                    expr.symbol(source_double_approximation_counts_name),
                    expr.constant(48),
                    expr.symbol(source_aligned_byte_address_name),
                ));
                const init_ub_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                    tok.undefined_byte_address_word_field_name,
                    expr.call(shl_or_ub_c_48_ab),
                ));
                buf[len] = expr.join(init_ub_word);
                len +%= 1;
            }
        } else {
            const init_ub_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
                tok.undefined_byte_address_word_field_name,
                expr.symbol(source_aligned_byte_address_name),
            ));
            buf[len] = expr.join(init_ub_word);
            len +%= 1;
        }
    }
    if (impl_variant.fields.unallocated_byte_address) {
        const init_up_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.unallocated_byte_address_word_field_name,
            expr.symbol(source_unallocated_byte_address_name),
        ));
        buf[len] = expr.join(init_up_word);
        len +%= 1;
    }
    if (len == 0) {
        const init_lb_word: *[4]expr.Expr = allocator.duplicate([4]expr.Expr, expr.initialize(
            tok.unallocated_byte_address_word_field_name,
            expr.constant(0),
        ));
        buf[len] = expr.join(init_lb_word);
        len +%= 1;
    }
    return allocator.duplicate([3]expr.Expr, expr.initializer(expr.list(buf[0..len])));
}
fn writeFunctionBodyGeneric(
    allocator: *Allocator,
    array: *Array,
    impl_variant: types.Implementation,
    ptr_fn_info: ptr_fn.Fn,
    info: *Info,
) void {
    const allocated_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .allocated_byte_address);
    const aligned_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .aligned_byte_address);
    const unstreamed_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .unstreamed_byte_address);
    const undefined_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .undefined_byte_address);
    const unwritable_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .unwritable_byte_address);
    const unallocated_byte_address_call: expr.Expr = expr.impl(allocator, impl_variant, .unallocated_byte_address);
    const allocated_byte_count_call: expr.Expr = expr.impl(allocator, impl_variant, .allocated_byte_count);
    const aligned_byte_count_call: expr.Expr = expr.impl(allocator, impl_variant, .aligned_byte_count);
    const alignment_call: expr.Expr = expr.impl(allocator, impl_variant, .alignment);
    const has_static_maximum_length: bool =
        impl_variant.kind == .automatic or
        impl_variant.kind == .static;
    const has_packed_approximate_capacity: bool =
        impl_variant.techs.single_packed_approximate_capacity or
        impl_variant.techs.double_packed_approximate_capacity;
    const has_unit_alignment: bool =
        impl_variant.kind == .automatic or
        impl_variant.techs.unit_alignment;
    var sub_1: [3]expr.Expr = expr.sub(
        expr.symbol(tok.low_alignment_impl_specifier_name),
        expr.constant(1),
    );
    var shl_65535_48: [3]expr.Expr = expr.shl(
        expr.constant(65535),
        expr.constant(48),
    );
    var shr_lb_16: [3]expr.Expr = expr.shl(
        expr.symbol(tok.allocated_byte_address_word_access),
        expr.constant(16),
    );
    var pointer_opaque_call_sentinel: [3]expr.Expr = expr.pointerOpaque(
        expr.symbol(tok.child_impl_specifier_name),
        expr.symbol(tok.sentinel_impl_specifier_name),
    );
    var pointer_one_call_undefined: [3]expr.Expr = expr.pointerOne(
        expr.symbol(tok.child_impl_specifier_name),
        undefined_byte_address_call,
    );
    var pointer_opaque_call_sentinel_deref_stx: [2]expr.Expr =
        expr.dereference(expr.call(&pointer_opaque_call_sentinel));
    var pointer_one_call_undefined_deref_stx: [2]expr.Expr =
        expr.dereference(expr.call(&pointer_one_call_undefined));
    array.writeMany(tok.open_brace_operator);
    defer array.writeMany(tok.close_brace_operator);
    switch (ptr_fn_info) {
        .allocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kind == .automatic) {
                var add_address_offset: [3]expr.Expr = expr.add(
                    expr.symbol(tok.address_of_impl),
                    expr.symbol(tok.offset_of_automatic_storage),
                );
                array.writeFormat(expr.call(&add_address_offset));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.kind == .parametric) {
                array.writeMany(tok.slave_specifier_call_unallocated_byte_address);
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.techs.double_packed_approximate_capacity or
                impl_variant.techs.single_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    array.writeFormat(expr.call(&shr_lb_16));
                    return array.writeMany(tok.end_expr);
                }
                var andn_allocated_shl: [3]expr.Expr = expr.andn(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&shl_65535_48),
                );
                array.writeFormat(expr.call(&andn_allocated_shl));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.techs.disjunct_alignment) {
                var sub_aligned_alignment: [3]expr.Expr = expr.sub(
                    aligned_byte_address_call,
                    alignment_call,
                );
                array.writeFormat(expr.call(&sub_aligned_alignment));
                return array.writeMany(tok.end_expr);
            }
            array.writeMany(tok.allocated_byte_address_word_access);
            return array.writeMany(tok.end_expr);
        },
        .aligned_byte_address => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                return info.setAlias(.allocated_byte_address);
            }
            if (impl_variant.techs.disjunct_alignment) {
                if (has_packed_approximate_capacity) {
                    if (config.packed_capacity_low) {
                        var sub_shr_sub: [3]expr.Expr = expr.andn(
                            expr.call(&shr_lb_16),
                            expr.call(&sub_1),
                        );
                        array.writeFormat(expr.call(&sub_shr_sub));
                        return array.writeMany(tok.end_expr);
                    }
                    var or_call_1_65535_48: [3]expr.Expr = expr.@"or"(
                        expr.call(&sub_1),
                        expr.call(&shl_65535_48),
                    );
                    var andn_allocated_or: [3]expr.Expr = expr.andn(
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&or_call_1_65535_48),
                    );
                    array.writeFormat(expr.call(&andn_allocated_or));
                    return array.writeMany(tok.end_expr);
                }
                var andn_allocated_sub: [3]expr.Expr = expr.andn(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&sub_1),
                );
                array.writeFormat(expr.call(&andn_allocated_sub));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.kind == .parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    var aligna_unallocated_low_alignment: [3]expr.Expr = expr.alignA(
                        expr.symbol(tok.slave_specifier_call_unallocated_byte_address),
                        expr.symbol(tok.low_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&aligna_unallocated_low_alignment));
                    return array.writeMany(tok.end_expr);
                }
                return info.setAlias(.allocated_byte_address);
            }
            if (impl_variant.techs.lazy_alignment) {
                var aligna_allocated_low_alignment: [3]expr.Expr = expr.alignA(
                    allocated_byte_address_call,
                    expr.symbol(tok.low_alignment_impl_specifier_name),
                );
                array.writeFormat(expr.call(&aligna_allocated_low_alignment));
                return array.writeMany(tok.end_expr);
            }
            return array.writeMany(tok.end_expr);
        },
        .unstreamed_byte_address => {
            array.writeMany(tok.return_keyword);
            array.writeMany(tok.unstreamed_byte_address_word_access);
            return array.writeMany(tok.end_expr);
        },
        .undefined_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (config.packed_capacity_low) {
                    var shr_undefined_16: [3]expr.Expr = expr.shr(
                        expr.symbol(tok.undefined_byte_address_word_access),
                        expr.constant(16),
                    );
                    array.writeFormat(expr.call(&shr_undefined_16));
                    return array.writeMany(tok.end_expr);
                }
                var andn_undefined_shl: [3]expr.Expr = expr.andn(
                    expr.symbol(tok.undefined_byte_address_word_access),
                    expr.call(&shl_65535_48),
                );
                array.writeFormat(expr.call(&andn_undefined_shl));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.kind == .automatic) {
                var add_allocated_undefined: [3]expr.Expr = expr.add(
                    allocated_byte_address_call,
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                array.writeFormat(expr.call(&add_allocated_undefined));
                return array.writeMany(tok.end_expr);
            }
            array.writeMany(tok.undefined_byte_address_word_access);
            return array.writeMany(tok.end_expr);
        },
        .unallocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.fields.unallocated_byte_address) {
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expr);
            }
            if (has_static_maximum_length or has_packed_approximate_capacity) {
                var add_allocated_count: [3]expr.Expr = expr.add(
                    allocated_byte_address_call,
                    allocated_byte_count_call,
                );
                array.writeFormat(expr.call(&add_allocated_count));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.kind == .parametric) {
                array.writeMany(tok.slave_specifier_call_unmapped_byte_address);
                return array.writeMany(tok.end_expr);
            }
            return array.writeMany(tok.end_expr);
        },
        .unwritable_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kind == .parametric) {
                if (impl_variant.specs.sentinel) {
                    var sub_unallocated_high_alignment: [3]expr.Expr = expr.sub(
                        unallocated_byte_address_call,
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_unallocated_high_alignment));
                    return array.writeMany(tok.end_expr);
                }
                return info.setAlias(.unallocated_byte_address);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    var sub_unallocated_high_alignment: [3]expr.Expr = expr.sub(
                        expr.symbol(tok.unallocated_byte_address_word_access),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_unallocated_high_alignment));
                    return array.writeMany(tok.end_expr);
                }
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expr);
            }
            var add_aligned_writable: [3]expr.Expr = expr.add(
                aligned_byte_address_call,
                expr.impl(allocator, impl_variant, .writable_byte_count),
            );
            array.writeFormat(expr.call(&add_aligned_writable));
            return array.writeMany(tok.end_expr);
        },
        .allocated_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(.aligned_byte_count);
                } else {
                    var add_alignment_count: [3]expr.Expr = expr.add(
                        alignment_call,
                        aligned_byte_count_call,
                    );
                    array.writeFormat(expr.call(&add_alignment_count));
                    return array.writeMany(tok.end_expr);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(.aligned_byte_count);
                } else {
                    var add_alignment_count: [3]expr.Expr = expr.add(
                        alignment_call,
                        aligned_byte_count_call,
                    );
                    array.writeFormat(expr.call(&add_alignment_count));
                    return array.writeMany(tok.end_expr);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(.writable_byte_count);
            }
            var sub_unallocated_allocated: [3]expr.Expr = expr.sub(
                unallocated_byte_address_call,
                allocated_byte_address_call,
            );
            array.writeFormat(expr.call(&sub_unallocated_allocated));
            return array.writeMany(tok.end_expr);
        },
        .aligned_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                var unpck1x: [2]expr.Expr = expr.unpck1x(expr.symbol(tok.allocated_byte_address_word_access));
                array.writeFormat(expr.call(&unpck1x));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                var unpck2x: [3]expr.Expr = expr.unpck2x(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                array.writeFormat(expr.call(&unpck2x));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.specs.sentinel) {
                var add_aligned_count_high_alignment: [3]expr.Expr = expr.add(
                    aligned_byte_count_call,
                    expr.symbol(tok.high_alignment_impl_specifier_name),
                );
                array.writeFormat(expr.call(&add_aligned_count_high_alignment));
                return array.writeMany(tok.end_expr);
            }
            return info.setAlias(.writable_byte_count);
        },
        .writable_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kind == .parametric) {
                var sub_unwritable_aligned: [3]expr.Expr = expr.sub(
                    unwritable_byte_address_call,
                    aligned_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_unwritable_aligned));
                return array.writeMany(tok.end_expr);
            }
            if (has_static_maximum_length) {
                var mul_count_sizeof: [3]expr.Expr = expr.mul(
                    expr.symbol(tok.count_impl_specifier_name),
                    expr.symbol(tok.call_sizeof_child_specifier),
                );
                array.writeFormat(expr.call(&mul_count_sizeof));
                return array.writeMany(tok.end_expr);
            }
            if (impl_variant.techs.single_packed_approximate_capacity) {
                var unpck1x = expr.unpck1x(expr.symbol(tok.allocated_byte_address_word_access));
                if (impl_variant.specs.sentinel) {
                    var alignb_unpck1x_high_alignment: [3]expr.Expr = expr.alignB(
                        expr.call(&unpck1x),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    var sub_alignb_high_alignment: [3]expr.Expr = expr.sub(
                        expr.call(&alignb_unpck1x_high_alignment),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_alignb_high_alignment));
                    return array.writeMany(tok.end_expr);
                } else {
                    var alignb_unpck1x_high_alignment: [3]expr.Expr = expr.alignB(
                        expr.call(&unpck1x),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&alignb_unpck1x_high_alignment));
                    return array.writeMany(tok.end_expr);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                var unpck2x_call: [3]expr.Expr = expr.unpck2x(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                if (impl_variant.specs.sentinel) {
                    var alignb_unpck2x_high_alignment: [3]expr.Expr = expr.alignB(
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    var sub_alignb_high_alignment: [3]expr.Expr = expr.sub(
                        expr.call(&alignb_unpck2x_high_alignment),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_alignb_high_alignment));
                    return array.writeMany(tok.end_expr);
                } else {
                    var alignb_unpck2x_high_alignment: [3]expr.Expr = expr.alignB(
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_impl_specifier_name),
                    );
                    array.writeFormat(expr.call(&alignb_unpck2x_high_alignment));
                    return array.writeMany(tok.end_expr);
                }
            } else if (impl_variant.specs.sentinel) {
                var sub_allocated_high_alignment: [3]expr.Expr = expr.sub(
                    allocated_byte_count_call,
                    expr.symbol(tok.high_alignment_impl_specifier_name),
                );
                if (has_unit_alignment) {
                    array.writeFormat(expr.call(&sub_allocated_high_alignment));
                    return array.writeMany(tok.end_expr);
                } else {
                    var sub_sub_allocated_alignment: [3]expr.Expr = expr.sub(
                        expr.call(&sub_allocated_high_alignment),
                        alignment_call,
                    );
                    array.writeFormat(expr.call(&sub_sub_allocated_alignment));
                    return array.writeMany(tok.end_expr);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(.allocated_byte_count);
            } else {
                var sub_allocated_count_alignment: [3]expr.Expr = expr.sub(
                    allocated_byte_count_call,
                    alignment_call,
                );
                array.writeFormat(expr.call(&sub_allocated_count_alignment));
                return array.writeMany(tok.end_expr);
            }
        },
        .defined_byte_count => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                var sub_undefined_allocated: [3]expr.Expr = expr.sub(
                    undefined_byte_address_call,
                    allocated_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_allocated));
                return array.writeMany(tok.end_expr);
            } else {
                var sub_undefined_aligned: [3]expr.Expr = expr.sub(
                    undefined_byte_address_call,
                    aligned_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_aligned));
                return array.writeMany(tok.end_expr);
            }
        },
        .undefined_byte_count => {
            var sub_unwritable_undefined: [3]expr.Expr = expr.sub(
                unwritable_byte_address_call,
                undefined_byte_address_call,
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_unwritable_undefined));
            return array.writeMany(tok.end_expr);
        },
        .streamed_byte_count => {
            var sub_unstreamed_aligned: [3]expr.Expr = expr.sub(
                unstreamed_byte_address_call,
                aligned_byte_address_call,
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_unstreamed_aligned));
            return array.writeMany(tok.end_expr);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                var sub_undefined_unstreamed: [3]expr.Expr = expr.sub(
                    undefined_byte_address_call,
                    unstreamed_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_unstreamed));
                return array.writeMany(tok.end_expr);
            } else {
                var sub_unwritable_unstreamed: [3]expr.Expr = expr.sub(
                    unwritable_byte_address_call,
                    unstreamed_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_unwritable_unstreamed));
                return array.writeMany(tok.end_expr);
            }
        },
        .alignment => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.disjunct_alignment and
                has_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    var and_shr_16_sub_1: [3]expr.Expr = expr.@"and"(
                        expr.call(&shr_lb_16),
                        expr.call(&sub_1),
                    );
                    array.writeFormat(expr.call(&and_shr_16_sub_1));
                    return array.writeMany(tok.end_expr);
                } else {
                    var and_allocated_sub_1: [3]expr.Expr = expr.@"and"(
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&sub_1),
                    );
                    array.writeFormat(expr.call(&and_allocated_sub_1));
                    return array.writeMany(tok.end_expr);
                }
            } else {
                var sub_aligned_allocated: [3]expr.Expr = expr.sub(
                    aligned_byte_address_call,
                    allocated_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_aligned_allocated));
                return array.writeMany(tok.end_expr);
            }
        },
        .define => {
            var add_equ_undefined_offset: [3]expr.Expr = expr.addEqu(
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&add_equ_undefined_offset));
            array.writeMany(tok.end_expr);
            if (impl_variant.specs.sentinel) {
                var assign_pointer_one_sentinel: [4]expr.Expr = expr.assign(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                array.writeFormat(expr.join(&assign_pointer_one_sentinel));
            }
        },
        .undefine => {
            var sub_equ_undefined_offset: [3]expr.Expr = expr.subEqu(
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&sub_equ_undefined_offset));
            array.writeMany(tok.end_expr);
            if (impl_variant.specs.sentinel) {
                var assign_pointer_one_sentinel: [4]expr.Expr = expr.assign(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                array.writeFormat(expr.join(&assign_pointer_one_sentinel));
            }
        },
        .seek => {
            var add_equ_unstreamed_offset: [3]expr.Expr = expr.addEqu(
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&add_equ_unstreamed_offset));
            return array.writeMany(tok.end_expr);
        },
        .tell => {
            var sub_equ_unstreamed_offset: [3]expr.Expr = expr.subEqu(
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&sub_equ_unstreamed_offset));
            return array.writeMany(tok.end_expr);
        },
        .allocate => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(constructInitializer(allocator, impl_variant, ptr_fn_info)));
            return array.writeMany(tok.end_expr);
        },
        .resize => {
            var impl_deref_stx: [2]expr.Expr = expr.dereference(expr.symbol(tok.impl_name));
            var assign_impl: [4]expr.Expr = expr.assign(
                expr.join(&impl_deref_stx),
                expr.join(resizeInitializer(allocator, impl_variant)),
            );
            return array.writeFormat(expr.join(&assign_impl));
        },
        .reallocate, .move => {
            expr.subst(aligned_byte_address_call.args(), .{
                .dst = expr.symbol(tok.impl_name),
                .src = expr.symbol(tok.source_impl_name),
            });
            expr.subst(aligned_byte_count_call.args(), .{
                .dst = expr.symbol(tok.impl_name),
                .src = expr.symbol(tok.source_impl_name),
            });
            const target_aligned_byte_address_call: expr.Expr =
                expr.impl(allocator, impl_variant, .aligned_byte_address);
            var impl_deref_stx: [2]expr.Expr = expr.dereference(expr.symbol(tok.impl_name));
            var s_impl_decl: [7]expr.Expr = expr.constDecl(
                expr.symbol(tok.source_impl_name),
                expr.symbol(tok.impl_type_name),
                expr.join(&impl_deref_stx),
            );
            var t_impl_decl: [7]expr.Expr = expr.constDecl(
                expr.symbol(tok.target_impl_name),
                expr.symbol(tok.impl_type_name),
                expr.join(constructInitializer(allocator, impl_variant, ptr_fn_info)),
            );
            var assign_impl_t_impl: [4]expr.Expr = expr.assign(
                expr.join(&impl_deref_stx),
                expr.symbol(tok.target_impl_name),
            );
            var copy: [5]expr.Expr = expr.fnCall4(
                tok.copy_fn_name,
                aligned_byte_address_call,
                aligned_byte_count_call,
                target_aligned_byte_address_call,
                expr.symbol(tok.high_alignment_impl_specifier_name),
            );
            array.writeFormat(expr.join(&s_impl_decl));
            array.writeFormat(expr.join(&t_impl_decl));
            array.writeFormat(expr.join(&assign_impl_t_impl));
            array.writeFormat(expr.call(&copy));
            return array.writeMany(tok.end_expr);
        },
        .deallocate => return,
    }
}
fn writeSignature(
    array: *Array,
    arg_lists_map: *const ptr_fn.FnArgs.Map,
    impl_variant: types.Implementation,
    ptr_fn_info: ptr_fn.Fn,
) void {
    const idxs: ptr_fn.FnArgs.Index = arg_lists_map.idxs[impl_variant.ptr];
    for (idxs.keys[0..idxs.keys_len]) |ki_pair| {
        if (ki_pair.ptr_fn_info == ptr_fn_info) {
            for (arg_lists_map.vals[0..idxs.keys_len]) |kv_pair| {
                if (kv_pair.ptr_fn_info == ptr_fn_info) {
                    const arg_list: gen.ArgList = kv_pair.arg_lists[ki_pair.arg_list_idx];
                    array.writeMany("pub inline fn ");
                    array.writeMany(ptr_fn_info.fnName());
                    array.writeMany("(");
                    switch (ptr_fn_info) {
                        .allocate => {
                            array.writeMany("s:");
                        },
                        .move, .resize, .reallocate => {
                            array.writeMany(arg_list.args[0]);
                            array.writeMany(",t:");
                        },
                        else => unreachable,
                    }
                    array.writeMany(@tagName(ptr_fn_info));
                    array.writeFormat(fmt.ud64(ki_pair.arg_list_idx));
                    array.writeMany(")");
                    array.writeMany(arg_list.ret);
                    return;
                }
            }
        }
    }
    ptr_fn_info.writeSignature(array, impl_variant);
}
fn writeFunctions(
    allocator: *Allocator,
    array: *Array,
    arg_lists_map: *const ptr_fn.FnArgs.Map,
    impl_variant: types.Implementation,
) void {
    for (ptr_fn.list) |ptr_fn_info| {
        if (ptr_fn_info != .deallocate and ptr_fn_info.hasCapability(impl_variant)) {
            var info: Info = .{ .start = array.len() };
            writeSignature(array, arg_lists_map, impl_variant, ptr_fn_info);
            writeFunctionBodyGeneric(allocator, array, impl_variant, ptr_fn_info, &info);
            writeSimpleRedecl(array, &ptr_fn_info, &info);
        }
    }
}
fn writeDeclarations(array: *Array, impl_variant: types.Implementation) void {
    const no_type_expr: expr.Expr = expr.scrub(1);
    var const_decl: [7]expr.Expr = expr.constDecl(
        expr.symbol(tok.impl_type_name),
        no_type_expr,
        expr.symbol(tok.call_this),
    );
    const const_decl_name: *expr.Expr = &const_decl[1];
    const const_decl_type_name: *expr.Expr = &const_decl[3];
    const const_decl_value: *expr.Expr = &const_decl[5];
    const_decl_type_name.* = no_type_expr;
    array.writeFormat(expr.join(&const_decl));
    if (impl_variant.kind == .parametric) {
        const_decl_name.* = expr.symbol(tok.slave_fn_type_name);
        const_decl_value.* = expr.symbol(tok.slave_fn_type_decl_spec);
        array.writeFormat(expr.join(&const_decl));
    }
    if (impl_variant.kind == .dynamic or impl_variant.kind == .parametric) {
        if (impl_variant.techs.unit_alignment) {
            const_decl_name.* = expr.symbol(tok.unit_alignment_name);
            const_decl_type_name.* = expr.symbol(tok.word_type_name);
            const_decl_value.* = expr.symbol(tok.low_alignment_impl_specifier_name);
            return array.writeFormat(expr.join(&const_decl));
        }
    } else {
        if (impl_variant.kind == .automatic or impl_variant.kind == .static) {
            const_decl_name.* = expr.symbol(tok.static_fn_type_name);
            const_decl_value.* = expr.symbol(tok.static_fn_type_decl_spec);
            array.writeFormat(expr.join(&const_decl));
        }
        if (impl_variant.techs.auto_alignment) {
            const_decl_name.* = expr.symbol(tok.auto_alignment_name);
            const_decl_type_name.* = expr.symbol(tok.word_type_name);
            const_decl_value.* = expr.symbol(tok.low_alignment_impl_specifier_name);
            array.writeFormat(expr.join(&const_decl));
        }
    }
}
fn writeSimpleRedecl(array: *Array, ptr_fn_info: *const ptr_fn.Fn, info: *Info) void {
    if (info.alias) |ptr_fn_alias_info| {
        array.undefine(array.len() - info.start);
        array.writeMany("pub const ");
        array.writeMany(ptr_fn_info.fnName());
        array.writeMany(tok.equal_operator);
        array.writeMany(ptr_fn_alias_info.fnName());
        array.writeMany(tok.end_expr);
        info.alias = null;
    }
}
fn writeComptimeField(array: *Array, impl_variant: types.Implementation, ptr_fn_info: ptr_fn.Fn) void {
    const args_list: gen.ArgList = ptr_fn_info.argList(impl_variant, .Parameter);
    if (expr.comptimeField(args_list)) {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(ptr_fn_info.fnName());
        if (impl_variant.kind == .parametric) {
            array.writeMany(tok.colon_operator ++ tok.slave_fn_type_name ++ tok.equal_operator);
        } else {
            array.writeMany(tok.colon_operator ++ tok.static_type_name ++ tok.equal_operator);
        }
        array.writeMany(ptr_fn_info.fnName());
        array.writeMany(tok.end_elem);
    }
}
fn writeFields(array: *Array, impl_variant: types.Implementation) void {
    writeComptimeField(array, impl_variant, .allocated_byte_address);
    writeComptimeField(array, impl_variant, .aligned_byte_address);
    writeComptimeField(array, impl_variant, .unallocated_byte_address);
    if (impl_variant.fields.automatic_storage) {
        if (impl_variant.specs.sentinel) {
            array.writeMany(tok.automatic_storage_with_sentinel_field);
        } else {
            array.writeMany(tok.automatic_storage_field);
        }
        array.writeMany(tok.end_elem);
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(tok.allocated_byte_address_word_field);
        array.writeMany(tok.end_elem);
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(tok.unstreamed_byte_address_word_field);
        array.writeMany(tok.end_elem);
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(tok.undefined_byte_address_word_field);
        array.writeMany(tok.end_elem);
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(tok.unallocated_byte_address_word_field);
        array.writeMany(tok.end_elem);
    }
    writeComptimeField(array, impl_variant, .unwritable_byte_address);
    writeComptimeField(array, impl_variant, .allocated_byte_count);
    writeComptimeField(array, impl_variant, .writable_byte_count);
    writeComptimeField(array, impl_variant, .aligned_byte_count);
}
fn writeTypeFunction(
    allocator: *Allocator,
    array: *Array,
    arg_lists_map: *const ptr_fn.FnArgs.Map,
    impl_variant: types.Implementation,
) void {
    array.writeMany("pub fn ");
    array.writeFormat(impl_variant);
    array.writeMany("(" ++ tok.comptime_keyword ++ tok.impl_spec_name ++ tok.colon_operator ++ tok.generic_spec_type_name);
    fmt.ud64(impl_variant.ctn).formatWrite(array);
    array.writeMany(")type{\nreturn(struct{\n");
    writeFields(array, impl_variant);
    writeDeclarations(array, impl_variant);
    writeFunctions(allocator, array, arg_lists_map, impl_variant);
    array.writeMany("});\n}\n");
}
fn writeInterfaceStruct(array: *Array, ptr_fn_info: ptr_fn.Fn, idx: usize, arg_list: gen.ArgList) void {
    array.writeMany("const ");
    array.writeMany(@tagName(ptr_fn_info));
    array.writeFormat(fmt.ud64(idx));
    array.writeMany("=struct{");
    for (arg_list.readAll()) |arg| {
        if (!ptr_fn.isPtrParam(arg)) {
            array.writeMany(arg);
            array.writeMany(",");
        }
    }
    array.writeMany("};\n");
}
const details = blk: {
    const bytes: []const u8 = @embedFile("./zig-out/src/impl_detail");
    const len: usize = @divExact(bytes.len, @sizeOf(types.Implementation));
    const ptr: [*]const types.Implementation = @ptrCast(@alignCast(bytes[0..bytes.len]));
    break :blk ptr[0..len];
};
pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    const arg_lists_map: ptr_fn.FnArgs.Map = ptr_fn.deduceUniqueInterfaceStructs(&allocator, details);
    for (arg_lists_map.vals) |kv| {
        for (kv.arg_lists, 0..) |arg_list, arg_list_idx| {
            writeInterfaceStruct(&array, kv.ptr_fn_info, arg_list_idx, arg_list);
        }
    }
    for (types.Kind.list) |kind| {
        for (details) |impl_detail| {
            if (impl_detail.kind == kind) {
                writeTypeFunction(&allocator, &array, &arg_lists_map, impl_detail);
            }
        }
        if (config.write_separate_source_files) {
            const pathname: [:0]const u8 = switch (kind) {
                .automatic => config.automatic_container_path,
                .static => config.static_container_path,
                .dynamic => config.dynamic_container_path,
                .parametric => config.parametric_container_path,
            };
            try gen.appendFile(.{ .return_type = void }, pathname, array.readAll());
            array.undefineAll();
        }
    }
    if (!config.write_separate_source_files) {
        try gen.appendFile(.{}, config.reference_file_path, array.readAll());
    }
}
