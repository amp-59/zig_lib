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
fn writeFunctionBodyTranslate(allocator: *Allocator, array: *Array, impl_variant: *const out.DetailMore) void {
    _ = impl_variant;
    _ = array;
    _ = allocator;
}
inline fn constructInitializer(allocator: *Allocator, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) *[3]Expr {
    Expr.debug = true;
    defer Expr.debug = false;
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
    const sub_or_ab_lb_ab: *expr.FnCall = dupe(allocator, expr.subOr(
        allocator,
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
                    const shl_or_sub_or_16_lb_c: *expr.FnCall = dupe(allocator, expr.shlOr(
                        allocator,
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
                    const shl_or_lb_c_48_sub_or: *expr.FnCall = dupe(allocator, expr.shlOr(
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
                    const shl_or_ab_16_lb_c: *expr.FnCall = dupe(allocator, expr.shlOr(
                        allocator,
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
                    const shl_or_lb_c_48_ab: *expr.FnCall = dupe(allocator, expr.shlOr(
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
                const shl_or_ab_16_ub_c: expr.FnCall = expr.shlOr(
                    allocator,
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
                const shl_or_ub_c_48_ab: expr.FnCall = expr.shlOr(
                    allocator,
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
        .op1 = expr.symbol(tok.low_alignment_specifier_name),
        .op2 = expr.constant(1),
    });
    const shl_call_65535_48: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shl_fn_name,
        .op1 = expr.constant(65535),
        .op2 = expr.constant(48),
    });
    const shr_call_lb_16: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.shr_fn_name,
        .op1 = expr.symbol(tok.allocated_byte_address_word_access),
        .op2 = expr.constant(16),
    });
    const pointer_opaque_call_sentinel: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.pointer_opaque_fn_name,
        .op1 = expr.symbol(tok.child_specifier_name),
        .op2 = expr.symbol(tok.sentinel_specifier_name),
    });
    const pointer_one_call_undefined: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.pointer_one_fn_name,
        .op1 = expr.symbol(tok.child_specifier_name),
        .op2 = expr.call(&undefined_byte_address_call),
    });
    const pointer_opaque_call_sentinel_deref_stx: [2]Expr =
        expr.dereferenceS(expr.call(&pointer_opaque_call_sentinel));
    const pointer_one_call_undefined_deref_stx: [2]Expr =
        expr.dereferenceS(expr.call(&pointer_one_call_undefined));
    switch (impl_fn_info.*) {
        .allocated_byte_address => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.kinds.automatic) {
                const address_of_impl_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.add_fn_name,
                    .op1 = expr.symbol(tok.address_of_impl),
                    .op2 = expr.symbol(tok.offset_of_automatic_storage),
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
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&shl_call_65535_48),
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.disjunct_alignment) {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&aligned_byte_address_call),
                    expr.call(&alignment),
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
                            expr.call(&shr_call_lb_16),
                            expr.call(&sub_call_1),
                        ));
                        return array.writeMany(tok.end_expression);
                    }
                    const or_call_1_65535_48: expr.FnCall =
                        expr.FnCall.allocate(allocator, expr.FnCall2, .{
                        .symbol = tok.or_fn_name,
                        .op1 = expr.call(&sub_call_1),
                        .op2 = expr.call(&shl_call_65535_48),
                    });
                    array.writeFormat(expr.andn(
                        allocator,
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&or_call_1_65535_48),
                    ));
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(expr.andn(
                    allocator,
                    expr.symbol(tok.allocated_byte_address_word_access),
                    expr.call(&sub_call_1),
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.parametric) {
                if (impl_variant.techs.lazy_alignment) {
                    array.writeFormat(expr.alignA(
                        allocator,
                        expr.symbol(tok.slave_specifier_call_unallocated_byte_address),
                        expr.symbol(tok.low_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(allocated_byte_address_fn_info.*);
            }
            if (impl_variant.techs.lazy_alignment) {
                array.writeFormat(expr.alignA(
                    allocator,
                    expr.call(&allocated_byte_address_call),
                    expr.symbol(tok.low_alignment_specifier_name),
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
                        .op1 = expr.symbol(tok.undefined_byte_address_word_access),
                        .op2 = expr.constant(16),
                    });
                    array.writeFormat(shr_call_ub_16);
                    return array.writeMany(tok.end_expression);
                }
                array.writeFormat(expr.andn(
                    allocator,
                    expr.symbol(tok.undefined_byte_address_word_access),
                    expr.call(&shl_call_65535_48),
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.kinds.automatic) {
                array.writeFormat(expr.add(
                    allocator,
                    expr.call(&allocated_byte_address_call),
                    expr.symbol(tok.undefined_byte_address_word_access),
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
                    expr.call(&allocated_byte_address_call),
                    expr.call(&allocated_byte_count_call),
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
                        expr.call(&unallocated_byte_address_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                }
                return info.setAlias(unallocated_byte_address_fn_info.*);
            }
            if (impl_variant.fields.unallocated_byte_address) {
                if (impl_variant.specs.sentinel) {
                    array.writeFormat(expr.sub(
                        allocator,
                        expr.symbol(tok.unallocated_byte_address_word_access),
                        expr.symbol(tok.high_alignment_specifier_name),
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
                expr.call(&aligned_byte_address_call),
                expr.call(&writable_byte_count_call),
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
                        expr.call(&alignment),
                        expr.call(&aligned_byte_count_call),
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
                        expr.call(&alignment),
                        expr.call(&aligned_byte_count_call),
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_static_maximum_length) {
                return info.setAlias(writable_byte_count_fn_info.*);
            }
            array.writeFormat(expr.sub(
                allocator,
                expr.call(&unallocated_byte_address_call),
                expr.call(&allocated_byte_address_call),
            ));
            return array.writeMany(tok.end_expression);
        },
        .aligned_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.techs.single_packed_approximate_capacity) {
                const unpck1x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall1, .{
                    .symbol = tok.unpack_single_fn_name,
                    .op1 = expr.symbol(tok.allocated_byte_address_word_access),
                });
                array.writeFormat(unpck1x_call);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.double_packed_approximate_capacity) {
                const unpck2x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = expr.symbol(tok.allocated_byte_address_word_access),
                    .op2 = expr.symbol(tok.undefined_byte_address_word_access),
                });
                array.writeFormat(unpck2x_call);
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.specs.sentinel) {
                array.writeFormat(expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.add_fn_name,
                    .op1 = expr.call(&aligned_byte_count_call),
                    .op2 = expr.symbol(tok.high_alignment_specifier_name),
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
                    expr.call(&unwritable_byte_address_call),
                    expr.call(&aligned_byte_address_call),
                ));
                return array.writeMany(tok.end_expression);
            }
            if (has_static_maximum_length) {
                array.writeFormat(expr.mul(
                    allocator,
                    expr.symbol(tok.count_specifier_name),
                    expr.symbol(tok.call_sizeof_child_specifier),
                ));
                return array.writeMany(tok.end_expression);
            }
            if (impl_variant.techs.single_packed_approximate_capacity) {
                const unpck1x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall1, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = expr.symbol(tok.allocated_byte_address_word_access),
                });
                if (impl_variant.specs.sentinel) {
                    const alignb_call: expr.FnCall = expr.alignB(
                        allocator,
                        expr.call(&unpck1x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.sub(
                        allocator,
                        expr.call(&alignb_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.alignB(
                        allocator,
                        expr.call(&unpck1x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.techs.double_packed_approximate_capacity) {
                const unpck2x_call: expr.FnCall =
                    expr.FnCall.allocate(allocator, expr.FnCall2, .{
                    .symbol = tok.unpack_double_fn_name,
                    .op1 = expr.symbol(tok.allocated_byte_address_word_access),
                    .op2 = expr.symbol(tok.undefined_byte_address_word_access),
                });
                if (impl_variant.specs.sentinel) {
                    const alignb_call: expr.FnCall = expr.alignB(
                        allocator,
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    );
                    array.writeFormat(expr.sub(
                        allocator,
                        expr.call(&alignb_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.alignB(
                        allocator,
                        expr.call(&unpck2x_call),
                        expr.symbol(tok.high_alignment_specifier_name),
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else if (impl_variant.specs.sentinel) {
                const sub_call: expr.FnCall = expr.sub(
                    allocator,
                    expr.call(&allocated_byte_count_call),
                    expr.symbol(tok.high_alignment_specifier_name),
                );
                if (has_unit_alignment) {
                    array.writeFormat(sub_call);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.sub(
                        allocator,
                        expr.call(&sub_call),
                        expr.call(&alignment),
                    ));
                    return array.writeMany(tok.end_expression);
                }
            }
            if (has_unit_alignment) {
                return info.setAlias(allocated_byte_count_fn_info.*);
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&allocated_byte_count_call),
                    expr.call(&alignment),
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .defined_byte_count => {
            array.writeMany(tok.return_keyword);
            if (has_unit_alignment) {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&undefined_byte_address_call),
                    expr.call(&allocated_byte_address_call),
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&undefined_byte_address_call),
                    expr.call(&aligned_byte_address_call),
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .undefined_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.sub(
                allocator,
                expr.call(&unwritable_byte_address_call),
                expr.call(&undefined_byte_address_call),
            ));
            return array.writeMany(tok.end_expression);
        },
        .streamed_byte_count => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.sub(
                allocator,
                expr.call(&unstreamed_byte_address_call),
                expr.call(&aligned_byte_address_call),
            ));
            return array.writeMany(tok.end_expression);
        },
        .unstreamed_byte_count => {
            array.writeMany(tok.return_keyword);
            if (impl_variant.modes.resize) {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&undefined_byte_address_call),
                    expr.call(&unstreamed_byte_address_call),
                ));
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&unwritable_byte_address_call),
                    expr.call(&unstreamed_byte_address_call),
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
                        expr.call(&shr_call_lb_16),
                        expr.call(&sub_call_1),
                    ));
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.@"and"(
                        allocator,
                        expr.symbol(tok.allocated_byte_address_word_access),
                        expr.call(&sub_call_1),
                    ));
                    return array.writeMany(tok.end_expression);
                }
            } else {
                array.writeFormat(expr.sub(
                    allocator,
                    expr.call(&aligned_byte_address_call),
                    expr.call(&allocated_byte_address_call),
                ));
                return array.writeMany(tok.end_expression);
            }
        },
        .define => {
            array.writeFormat(expr.addEqu(
                allocator,
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                const assign_ops: [3]Expr = expr.assignS(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                expr.formatWrite(expr.join(&assign_ops), array);
            }
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            array.writeFormat(expr.subEqu(
                allocator,
                expr.symbol(tok.undefined_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            ));
            if (impl_variant.specs.sentinel) {
                array.writeMany(tok.end_expression);
                const assign_ops: [3]Expr = expr.assignS(
                    expr.join(&pointer_one_call_undefined_deref_stx),
                    expr.join(&pointer_opaque_call_sentinel_deref_stx),
                );
                expr.formatWrite(expr.join(&assign_ops), array);
            }
            return array.writeMany(tok.end_expression);
        },
        .seek => {
            array.writeFormat(expr.addEqu(
                allocator,
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            ));
            return array.writeMany(tok.end_expression);
        },
        .tell => {
            array.writeFormat(expr.subEqu(
                allocator,
                expr.symbol(tok.unstreamed_byte_address_word_ptr),
                expr.symbol(tok.offset_bytes_name),
            ));
            return array.writeMany(tok.end_expression);
        },
        .construct => {
            const construct_init: *[3]Expr = constructInitializer(allocator, impl_variant, impl_fn_info);
            array.writeMany(tok.return_keyword);
            expr.formatWrite(expr.join(construct_init), array);
            return array.writeMany(tok.end_expression);
        },
        .translate => {
            const construct_init: *[3]Expr = constructInitializer(allocator, impl_variant, impl_fn_info);
            const impl_symbol_expr: Expr = expr.symbol(tok.impl_name);
            const impl_deref_stx: *[2]Expr = expr.dereference(allocator, impl_symbol_expr);
            const assign_impl_construct_init: *[3]Expr = expr.assign(
                allocator,
                expr.join(impl_deref_stx),
                expr.join(construct_init),
            );
            array.writeFormat(expr.join(assign_impl_construct_init));
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
fn writeComptimeFieldInternal(array: *Array, fn_tag: Fn, args: *const gen.ArgList) void {
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
inline fn writeComptimeField(array: *Array, impl_variant: *const out.DetailMore, impl_fn_info: Fn) void {
    const args: gen.ArgList = impl_fn_info.argList(impl_variant, .Parameter);
    writeComptimeFieldInternal(array, impl_fn_info, &args);
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
