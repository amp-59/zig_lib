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
const implementation = @import("./impl_fn.zig");

pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 128,
    .errors = preset.address_space.errors.noexcept,
    .logging = preset.address_space.logging.silent,
});
const Array = Allocator.StructuredStaticVector(u8, 1024 * 4096);
const Fn = implementation.Fn;
const Expr = expr.Expr;

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

fn dupe(allocator: *Allocator, value: anytype) Allocator.allocate_payload(*@TypeOf(value)) {
    return allocator.duplicateIrreversible(@TypeOf(value), value);
}
const Info = struct {
    start: u64,
    alias: ?Fn = null,
    fn setAlias(info: *Info, impl_fn_info: Fn) void {
        info.alias = impl_fn_info;
    }
};
inline fn constructInitializer(allocator: *Allocator, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) *[3]Expr {
    const source_aligned_byte_address_name: [:0]const u8 = blk: {
        if (impl_fn_info.* == .construct) {
            break :blk tok.source_aligned_byte_address_name;
        }
        if (impl_fn_info.* == .translate) {
            break :blk tok.target_aligned_byte_address_name;
        }
        unreachable;
    };
    const source_allocated_byte_address_name: [:0]const u8 = blk: {
        if (impl_fn_info.* == .construct) {
            break :blk tok.source_allocated_byte_address_name;
        }
        if (impl_fn_info.* == .translate) {
            break :blk tok.target_allocated_byte_address_name;
        }
        unreachable;
    };
    const source_single_approximation_counts_name: [:0]const u8 = blk: {
        if (impl_fn_info.* == .construct) {
            break :blk tok.source_single_approximation_counts_name;
        }
        if (impl_fn_info.* == .translate) {
            break :blk tok.target_single_approximation_counts_name;
        }
        unreachable;
    };
    const source_double_approximation_counts_name: [:0]const u8 = blk: {
        if (impl_fn_info.* == .construct) {
            break :blk tok.source_double_approximation_counts_name;
        }
        if (impl_fn_info.* == .translate) {
            break :blk tok.target_double_approximation_counts_name;
        }
        unreachable;
    };
    const source_unallocated_byte_address_name: [:0]const u8 = blk: {
        if (impl_fn_info.* == .construct) {
            break :blk tok.source_unallocated_byte_address_name;
        }
        if (impl_fn_info.* == .translate) {
            break :blk tok.target_unallocated_byte_address_name;
        }
        unreachable;
    };
    var buf: []Expr = allocator.allocateIrreversible(Expr, 8);
    var len: u64 = 0;
    const sub_or_ab_lb_ab: *[4]Expr = dupe(allocator, expr.subOr(
        expr.symbol(source_aligned_byte_address_name),
        expr.symbol(source_allocated_byte_address_name),
        expr.symbol(source_aligned_byte_address_name),
    ));
    if (impl_variant.fields.allocated_byte_address) {
        if (impl_variant.techs.single_packed_approximate_capacity or
            impl_variant.techs.double_packed_approximate_capacity)
        {
            if (impl_variant.techs.disjunct_alignment) {
                if (config.packed_capacity_low) {
                    const shl_or_sub_or_16_lb_c: *[4]Expr = dupe(allocator, expr.shlOr(
                        expr.call(sub_or_ab_lb_ab),
                        expr.constant(16),
                        expr.symbol(source_single_approximation_counts_name),
                    ));
                    const init_lb_word: *[4]Expr = expr.initialize(
                        allocator,
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_sub_or_16_lb_c),
                    );
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                } else {
                    const shl_or_lb_c_48_sub_or: *[3]Expr = dupe(allocator, expr.shlOr(
                        allocator,
                        expr.symbol(source_single_approximation_counts_name),
                        expr.constant(48),
                        expr.call(sub_or_ab_lb_ab),
                    ));
                    const init_lb_word: *[4]Expr = dupe(allocator, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_lb_c_48_sub_or),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                }
            } else {
                if (config.packed_capacity_low) {
                    const shl_or_ab_16_lb_c: *[4]Expr = dupe(allocator, expr.shlOr(
                        expr.symbol(source_allocated_byte_address_name),
                        expr.constant(16),
                        expr.symbol(source_single_approximation_counts_name),
                    ));
                    const init_lb_word: *[4]Expr = expr.initialize(
                        allocator,
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_ab_16_lb_c),
                    );
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                } else {
                    const shl_or_lb_c_48_ab: *[3]Expr = dupe(allocator, expr.shlOr(
                        allocator,
                        expr.symbol(source_single_approximation_counts_name),
                        expr.constant(48),
                        expr.symbol(source_allocated_byte_address_name),
                    ));
                    const init_lb_word: *[4]Expr = dupe(allocator, expr.initialize(
                        tok.allocated_byte_address_word_field_name,
                        expr.call(shl_or_lb_c_48_ab),
                    ));
                    buf[len] = expr.join(init_lb_word);
                    len +%= 1;
                }
            }
        } else {
            if (impl_variant.techs.disjunct_alignment) {
                const init_lb_word: *[4]Expr = expr.initialize(
                    allocator,
                    tok.allocated_byte_address_word_field_name,
                    expr.call(sub_or_ab_lb_ab),
                );
                buf[len] = expr.join(init_lb_word);
                len +%= 1;
            } else {
                const init_lb_word: *[4]Expr = expr.initialize(
                    allocator,
                    tok.allocated_byte_address_word_field_name,
                    expr.symbol(source_allocated_byte_address_name),
                );
                buf[len] = expr.join(init_lb_word);
                len +%= 1;
            }
        }
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        const init_ss_word: *[4]Expr = expr.initialize(
            allocator,
            tok.unstreamed_byte_address_word_field_name,
            expr.symbol(source_aligned_byte_address_name),
        );
        buf[len] = expr.join(init_ss_word);
        len +%= 1;
    }
    if (impl_variant.fields.undefined_byte_address) {
        if (impl_variant.techs.double_packed_approximate_capacity) {
            if (config.packed_capacity_low) {
                var shl_or_ab_16_ub_c: [4]Expr = expr.shlOr(
                    expr.symbol(source_aligned_byte_address_name),
                    expr.constant(16),
                    expr.symbol(source_double_approximation_counts_name),
                );
                const init_ub_word: *[4]Expr = expr.initialize(
                    allocator,
                    tok.undefined_byte_address_word_field_name,
                    expr.call(&shl_or_ab_16_ub_c),
                );
                buf[len] = expr.join(init_ub_word);
                len +%= 1;
            } else {
                const shl_or_ub_c_48_ab: [4]Expr = expr.shlOr(
                    expr.symbol(source_double_approximation_counts_name),
                    expr.constant(48),
                    expr.symbol(source_aligned_byte_address_name),
                );
                const init_ub_word: *[4]Expr = expr.initialize(
                    tok.undefined_byte_address_word_field_name,
                    expr.call(&shl_or_ub_c_48_ab),
                );
                buf[len] = expr.join(init_ub_word);
                len +%= 1;
            }
        } else {
            const init_ub_word: *[4]Expr = expr.initialize(
                allocator,
                tok.undefined_byte_address_word_field_name,
                expr.symbol(source_aligned_byte_address_name),
            );
            buf[len] = expr.join(init_ub_word);
            len +%= 1;
        }
    }
    if (impl_variant.fields.unallocated_byte_address) {
        const init_up_word: *[4]Expr = expr.initialize(
            allocator,
            tok.unallocated_byte_address_word_field_name,
            expr.symbol(source_unallocated_byte_address_name),
        );
        buf[len] = expr.join(init_up_word);
        len +%= 1;
    }
    if (len == 0) {
        const init_lb_word: *[4]Expr = expr.initialize(
            allocator,
            tok.unallocated_byte_address_word_field_name,
            expr.constant(0),
        );
        buf[len] = expr.join(init_lb_word);
        len +%= 1;
    }
    //testing.printN(4096, .{ fmt.render(render_spec, buf[0..len]), '\n' });
    return expr.initializer(allocator, expr.list(buf[0..len]));
}

const render_spec = .{
    .infer_type_names = true,
    .ignore_formatter_decls = true,
    .address_view = true,
};

fn writeFunctionBodyGeneric(allocator: *Allocator, array: *Array, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, info: *Info) void {
    const allocated_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, allocated_byte_address_fn_info);
    const aligned_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, aligned_byte_address_fn_info);
    const unstreamed_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, unstreamed_byte_address_fn_info);
    const undefined_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, undefined_byte_address_fn_info);
    const unwritable_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, unwritable_byte_address_fn_info);
    const unallocated_byte_address_call: Expr =
        expr.impl(allocator, impl_variant, unallocated_byte_address_fn_info);
    const allocated_byte_count_call: Expr =
        expr.impl(allocator, impl_variant, allocated_byte_count_fn_info);
    const aligned_byte_count_call: Expr =
        expr.impl(allocator, impl_variant, aligned_byte_count_fn_info);
    const alignment_call: Expr = expr.impl(allocator, impl_variant, alignment_fn_info);
    const has_static_maximum_length: bool =
        impl_variant.kinds.automatic or
        impl_variant.kinds.static;
    const has_packed_approximate_capacity: bool =
        impl_variant.techs.single_packed_approximate_capacity or
        impl_variant.techs.double_packed_approximate_capacity;
    const has_unit_alignment: bool =
        impl_variant.techs.auto_alignment or
        impl_variant.techs.unit_alignment;
    var sub_1: [3]Expr = expr.sub(
        expr.symbol(tok.low_alignment_specifier_name),
        expr.constant(1),
    );
    var shl_65535_48: [3]Expr = expr.shl(
        expr.constant(65535),
        expr.constant(48),
    );
    var shr_lb_16: [3]Expr = expr.shl(
        expr.symbol(tok.allocated_byte_address_word_access),
        expr.constant(16),
    );
    var pointer_opaque_call_sentinel: [3]Expr = expr.pointerOpaque(
        expr.symbol(tok.child_specifier_name),
        expr.symbol(tok.sentinel_specifier_name),
    );
    var pointer_one_call_undefined: [3]Expr = expr.pointerOne(
        expr.symbol(tok.child_specifier_name),
        undefined_byte_address_call,
    );
    var pointer_opaque_call_sentinel_deref_stx: [2]Expr =
        expr.dereferenceS(expr.call(&pointer_opaque_call_sentinel));
    var pointer_one_call_undefined_deref_stx: [2]Expr =
        expr.dereferenceS(expr.call(&pointer_one_call_undefined));

    switch (impl_fn_info.*) {
        .allocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.automatic) {
                var add_address_offset: [3]Expr = expr.add(
                    expr.symbol(tok.address_of_impl),
                    expr.symbol(tok.offset_of_automatic_storage),
                );
                array.writeFormat(expr.call(&add_address_offset));
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
                    array.writeFormat(expr.call(&shr_lb_16));
                    return array.writeMany(tok.end_expression);
                }
                var andn_allocated_shl: [3]Expr = expr.andn(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&shl_65535_48),
                );
                array.writeFormat(expr.call(&andn_allocated_shl));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                var sub_aligned_alignment: [3]Expr = expr.sub(
                    aligned_byte_address_call,
                    alignment_call,
                );
                array.writeFormat(expr.call(&sub_aligned_alignment));
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
                        var sub_shr_sub: [3]Expr = expr.andn(
                            expr.call(&shr_lb_16),
                            expr.call(&sub_1),
                        );
                        array.writeFormat(expr.call(&sub_shr_sub));
                        return array.writeMany(tok.end_expression);
                    }
                    const or_call_1_65535_48: [3]Expr = expr.@"or"(
                        expr.call(&sub_1),
                        expr.call(&shl_65535_48),
                    );
                    array.writeFormat(expr.call(&expr.andn(
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&or_call_1_65535_48),
                    )));
                    return array.writeMany(tok.end_expression);
                }
                var andn_allocated_sub: [3]Expr = expr.andn(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&sub_1),
                );
                array.writeFormat(expr.call(&andn_allocated_sub));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    var aligna_unallocated_low_alignment: [3]Expr = expr.alignA(
                        expr.symbol(tok.slave_specifier_call_unallocated_byte_address),
                        expr.symbol(tok.low_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&aligna_unallocated_low_alignment));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(allocated_byte_address_fn_info.*);
            }
            if (impl_variant.techs.lazy_alignment) {
                var aligna_allocated_low_alignment: [3]Expr = expr.alignA(
                    allocated_byte_address_call,
                    expr.symbol(tok.low_alignment_specifier_name),
                );
                array.writeFormat(expr.call(&aligna_allocated_low_alignment));
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
                    var shr_undefined_16: [3]Expr = expr.shr(
                        expr.symbol(tok.undefined_byte_address_word_access),
                        expr.constant(16),
                    );
                    array.writeFormat(expr.call(&shr_undefined_16));
                    return array.writeMany(tok.end_expression);
                }
                var andn_undefined_shl: [3]Expr = expr.andn(
                    expr.symbol(tok.undefined_byte_address_word_access),
                    shl_65535_48,
                );
                array.writeFormat(expr.call(&andn_undefined_shl));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.automatic) {
                var add_allocated_undefined: [3]Expr = expr.add(
                    allocated_byte_address_call,
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                array.writeFormat(expr.call(&add_allocated_undefined));
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
                var add_allocated_count: [3]Expr = expr.add(
                    allocated_byte_address_call,
                    allocated_byte_count_call,
                );
                array.writeFormat(expr.call(&add_allocated_count));
                return array.writeMany(tok.end_expression);
            }
            array.writeMany(tok.slave_specifier_call_unmapped_byte_address);
            return array.writeMany(tok.end_expression);
        },
        .unwritable_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                if (impl_variant.specs.sentinel) {
                    var sub_unallocated_high_alignment: [3]Expr = expr.sub(
                        unallocated_byte_address_call,
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_unallocated_high_alignment));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(unallocated_byte_address_fn_info.*);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    var sub_unallocated_high_alignment: [3]Expr = expr.sub(
                        expr.symbol(tok.unallocated_byte_address_word_access),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_unallocated_high_alignment));
                    return array.writeMany(tok.end_expression);
                }
                array.writeMany(tok.unallocated_byte_address_word_access);
                return array.writeMany(tok.end_expression);
            }
            var add_aligned_writable: [3]Expr = expr.add(
                aligned_byte_address_call,
                expr.impl(allocator, impl_variant, writable_byte_count_fn_info),
            );
            array.writeFormat(expr.call(&add_aligned_writable));
            return array.writeMany(tok.end_expression);
        },
        .allocated_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count_fn_info.*);
                } else {
                    var add_alignment_count: [3]Expr = expr.add(
                        alignment_call,
                        aligned_byte_count_call,
                    );
                    array.writeFormat(expr.call(&add_alignment_count));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                if (has_unit_alignment) {
                    return info.setAlias(aligned_byte_count_fn_info.*);
                } else {
                    var add_alignment_count: [3]Expr = expr.add(
                        alignment_call,
                        aligned_byte_count_call,
                    );
                    array.writeFormat(expr.call(&add_alignment_count));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(writable_byte_count_fn_info.*);
            }
            var sub_unallocated_allocated: [3]Expr = expr.sub(
                unallocated_byte_address_call,
                allocated_byte_address_call,
            );
            array.writeFormat(expr.call(&sub_unallocated_allocated));
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                var unpck1x: [2]Expr = expr.unpck1x(expr.symbol(tok.allocated_byte_address_word_access));
                array.writeFormat(expr.call(&unpck1x));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                var unpck2x: [3]Expr = expr.unpck2x(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                array.writeFormat(expr.call(&unpck2x));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.specs.sentinel) {
                var add_aligned_count_high_alignment: [3]Expr = expr.add(
                    aligned_byte_count_call,
                    expr.symbol(tok.high_alignment_specifier_name),
                );
                array.writeFormat(expr.call(&add_aligned_count_high_alignment));
                return array.writeMany(tok.end_expression);
            }
            return info.setAlias(writable_byte_count_fn_info.*);
        },
        .writable_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.parametric) {
                var sub_unwritable_aligned: [3]Expr = expr.sub(
                    unwritable_byte_address_call,
                    aligned_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_unwritable_aligned));
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length) {
                var mul_count_sizeof: [3]Expr = expr.mul(
                    expr.symbol(tok.count_specifier_name),
                    expr.symbol(tok.call_sizeof_child_specifier),
                );
                array.writeFormat(expr.call(&mul_count_sizeof));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.single_packed_approximate_capacity) {
                var unpck1x = expr.unpck1x(expr.symbol(tok.allocated_byte_address_word_access));
                if (impl_variant.specs.sentinel) {
                    var alignb_unpck1x_high_alignment: [3]Expr = expr.alignB(
                        expr.call(&unpck1x),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    var sub_alignb_high_alignment: [3]Expr = expr.sub(
                        expr.call(&alignb_unpck1x_high_alignment),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_alignb_high_alignment));
                    return array.writeMany(tok.end_expression);
                } else {
                    var alignb_unpck1x_high_alignment: [3]Expr = expr.alignB(
                        expr.call(&unpck1x),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&alignb_unpck1x_high_alignment));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                var unpck2x_call: [3]Expr = expr.unpck2x(
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.symbol(tok.undefined_byte_address_word_access),
                );
                if (impl_variant.specs.sentinel) {
                    var alignb_unpck2x_high_alignment: [3]Expr = expr.alignB(
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    var sub_alignb_high_alignment: [3]Expr = expr.sub(
                        expr.call(&alignb_unpck2x_high_alignment),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&sub_alignb_high_alignment));
                    return array.writeMany(tok.end_expression);
                } else {
                    var alignb_unpck2x_high_alignment: [3]Expr = expr.alignB(
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.call(&alignb_unpck2x_high_alignment));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                var sub_allocated_high_alignment: [3]Expr = expr.sub(
                    allocated_byte_count_call,
                    expr.symbol(tok.high_alignment_specifier_name),
                );
                if (has_unit_alignment) {
                    array.writeFormat(expr.call(&sub_allocated_high_alignment));
                    return array.writeMany(tok.end_expression);
                } else {
                    var sub_sub_allocated_alignment: [3]Expr = expr.sub(
                        expr.call(&sub_allocated_high_alignment),
                        alignment_call,
                    );
                    array.writeFormat(expr.call(&sub_sub_allocated_alignment));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_count_fn_info.*);
            } else {
                var sub_allocated_count_alignment: [3]Expr = expr.sub(
                    allocated_byte_count_call,
                    alignment_call,
                );
                array.writeFormat(expr.call(&sub_allocated_count_alignment));
                return array.writeMany(tok.end_expression);
            }
        },
        .defined_byte_count => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                var sub_undefined_allocated: [3]Expr = expr.sub(
                    undefined_byte_address_call,
                    allocated_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_allocated));
                return array.writeMany(tok.end_expression);
            } else {
                var sub_undefined_aligned: [3]Expr = expr.sub(
                    undefined_byte_address_call,
                    aligned_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_aligned));
                return array.writeMany(tok.end_expression);
            }
        },
        .undefined_byte_count => {
            var sub_unwritable_undefined: [3]Expr = expr.sub(
                unwritable_byte_address_call,
                undefined_byte_address_call,
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_unwritable_undefined));
            return array.writeMany(tok.end_expression);
        },
        .streamed_byte_count => {
            var sub_unstreamed_aligned: [3]Expr = expr.sub(
                unstreamed_byte_address_call,
                aligned_byte_address_call,
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_unstreamed_aligned));
            return array.writeMany(tok.end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                var sub_undefined_unstreamed: [3]Expr = expr.sub(
                    undefined_byte_address_call,
                    unstreamed_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_undefined_unstreamed));
                return array.writeMany(tok.end_expression);
            } else {
                var sub_unwritable_unstreamed: [3]Expr = expr.sub(
                    unwritable_byte_address_call,
                    unstreamed_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_unwritable_unstreamed));
                return array.writeMany(tok.end_expression);
            }
        },
        .alignment => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.disjunct_alignment and
                has_packed_approximate_capacity)
            {
                if (config.packed_capacity_low) {
                    var and_shr_16_sub_1: [3]Expr = expr.@"and"(
                        expr.call(&shr_lb_16),
                        expr.call(&sub_1),
                    );
                    array.writeFormat(expr.call(&and_shr_16_sub_1));
                    return array.writeMany(tok.end_expression);
                } else {
                    var and_allocated_sub_1: [3]Expr = expr.@"and"(
                        allocator,
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&sub_1),
                    );
                    array.writeFormat(expr.call(&and_allocated_sub_1));
                    return array.writeMany(tok.end_expression);
                }
            } else {
                var sub_aligned_allocated: [3]Expr = expr.sub(
                    aligned_byte_address_call,
                    allocated_byte_address_call,
                );
                array.writeFormat(expr.call(&sub_aligned_allocated));
                return array.writeMany(tok.end_expression);
            }
        },
        .define => {
            var add_equ_undefined_offset: [3]Expr = expr.addEqu(
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&add_equ_undefined_offset));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                var assign_pointer_one_sentinel: [3]Expr = expr.assignS(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                array.writeFormat(expr.join(&assign_pointer_one_sentinel));
            }
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            var sub_equ_undefined_offset: [3]Expr = expr.subEqu(
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&sub_equ_undefined_offset));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                var assign_pointer_one_sentinel: [3]Expr = expr.assignS(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                array.writeFormat(expr.join(&assign_pointer_one_sentinel));
            }
            return array.writeMany(tok.end_expression);
        },
        .seek => {
            var add_equ_unstreamed_offset: [3]Expr = expr.addEqu(
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&add_equ_unstreamed_offset));
            return array.writeMany(tok.end_expression);
        },
        .tell => {
            var sub_equ_unstreamed_offset: [3]Expr = expr.subEqu(
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            );
            array.writeFormat(expr.call(&sub_equ_unstreamed_offset));
            return array.writeMany(tok.end_expression);
        },
        .construct => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(constructInitializer(allocator, impl_variant, impl_fn_info)));
            return array.writeMany(tok.end_expression);
        },
        .translate => {
            const construct_init: *[3]Expr = constructInitializer(allocator, impl_variant, impl_fn_info);
            const impl_symbol_expr: Expr = expr.symbol(tok.impl_name);
            const impl_deref_stx: *[2]Expr = expr.dereference(allocator, impl_symbol_expr);
            var assign_impl_deref_construct_init: [3]Expr = expr.assignS(
                expr.join(impl_deref_stx),
                expr.join(construct_init),
            );
            array.writeFormat(expr.join(&assign_impl_deref_construct_init));
            return array.writeMany(tok.end_expression);
        },
    }
}

fn writeFunctions(allocator: *Allocator, array: *Array, impl_variant: *const out.DetailMore) void {
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
fn writeDeclarations(allocator: *Allocator, array: *Array, impl_variant: *const out.DetailMore) void {
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
        return array.writeMany("pub const unit_alignment: u64 = spec.unit_alignment;\n");
    }
    if (impl_variant.techs.auto_alignment) {
        return array.writeMany("pub const auto_alignment: u64 = spec.low_alignment;\n");
    }
}
fn writeSimpleRedecl(array: *Array, impl_fn_info: *const Fn, info: *Info) void {
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
inline fn writeComptimeField(array: *Array, impl_variant: *const out.DetailMore, impl_fn_info: Fn) void {
    const args_list: gen.ArgList = impl_fn_info.argList(impl_variant, .Parameter);
    if (args_list.comptimeField()) {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(impl_fn_info.fnName());
        if (impl_variant.kinds.parametric) {
            array.writeMany(": Slave = ");
        } else {
            array.writeMany(": Static = ");
        }
        array.writeMany(impl_fn_info.fnName());
        array.writeMany(tok.end_list_item);
    }
}
inline fn writeFields(allocator: *Allocator, array: *Array, impl_variant: *const out.DetailMore) void {
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
        array.writeMany(tok.end_small_list_item);
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(tok.allocated_byte_address_word_field);
        array.writeMany(tok.end_small_list_item);
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(tok.unstreamed_byte_address_word_field);
        array.writeMany(tok.end_small_list_item);
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(tok.undefined_byte_address_word_field);
        array.writeMany(tok.end_small_list_item);
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(tok.unallocated_byte_address_word_field);
        array.writeMany(tok.end_small_list_item);
    }
    writeComptimeField(array, impl_variant, Fn.unwritable_byte_address);
    writeComptimeField(array, impl_variant, Fn.allocated_byte_count);
    writeComptimeField(array, impl_variant, Fn.writable_byte_count);
    writeComptimeField(array, impl_variant, Fn.aligned_byte_count);
}
inline fn writeTypeFunction(allocator: *Allocator, array: *Array, accm_spec_index: u64, impl_variant: *const out.DetailMore) void {
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
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1);
    array.undefineAll();
    var accm_spec_index: u64 = 0;
    var ctn_index: u64 = 0;
    while (ctn_index != out.specifications.len) : (ctn_index +%= 1) {
        const s = allocator.save();
        defer allocator.restore(s);
        const ctn_group: []const []const out.Index = out.specifications[ctn_index];
        var spec_index: u64 = 0;
        while (spec_index != ctn_group.len) : (spec_index +%= 1) {
            defer accm_spec_index +%= 1;
            const spec_group: []const out.Index = ctn_group[spec_index];
            var impl_index: u64 = 0;
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
