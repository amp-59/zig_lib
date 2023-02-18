const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
const expr = @import("./expr.zig");
const config = @import("./config.zig");
const interface = @import("./interface.zig");
const implementation = @import("./implementation.zig");

pub usingnamespace proc.start;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small_composed,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .up_addr = 0x80000000,
    .lb_offset = 0x40000000,
    .divisions = 128,
    .errors = .{},
    .logging = preset.address_space.logging.silent,
    .options = .{ .require_map = true, .require_unmap = true },
});
const Array = Allocator.StructuredStaticVector(u8, 1024 * 4096);

pub const is_verbose: bool = false;
pub const is_silent: bool = true;
pub const runtime_assertions: bool = false;

const Fn = interface.Fn;
const Expr = expr.Expr;

fn setImplToMember(callable: *expr.FnCall) void {
    if (callable.ops.len == 0) {
        callable.ops = callable.ops.ptr[0..1];
    }
    callable.ops[0] = expr.symbol(tok.array_impl);
    callable.member = true;
}

fn writeFunctionBodyPrimary(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const is_one: bool = ctn_fn_info.val == .One;
    const is_count: bool =
        ctn_fn_info.val == .Count or
        ctn_fn_info.val == .CountWithSentinel;
    const is_many: bool =
        ctn_fn_info.val == .Many or
        ctn_fn_info.val == .ManyWithSentinel;
    const is_write: bool =
        ctn_fn_info.kind == .write or
        ctn_fn_info.kind == .append;
    const is_read: bool =
        ctn_fn_info.kind == .read or
        ctn_fn_info.kind == .refer;
    const is_relative: bool =
        ctn_fn_info.loc == .Next or
        ctn_fn_info.loc == .Back or
        ctn_fn_info.loc == .Behind or
        ctn_fn_info.loc == .Ahead;
    var len_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.len));
    var avail_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.avail));
    _ = avail_fn_call;
    var __len_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__len));
    _ = __len_fn_call;
    var __rem_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__rem));
    _ = __rem_fn_call;
    var __at_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__at));
    var __ad_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__ad));
    var __back_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__back));
    var __behind_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.__behind));
    var aligned_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.aligned_byte_address));
    setImplToMember(&aligned_byte_address_call);
    var undefined_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.undefined_byte_address));
    setImplToMember(&undefined_byte_address_call);
    var unstreamed_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.unstreamed_byte_address));
    setImplToMember(&unstreamed_byte_address_call);
    const location_call: *expr.FnCall = switch (ctn_fn_info.loc) {
        .AnyDefined => &__at_fn_call,
        .AnyUndefined => &__ad_fn_call,
        .Back => &__back_fn_call,
        .Behind => &__behind_fn_call,
        .AllDefined => &aligned_byte_address_call,
        .AllUndefined => &undefined_byte_address_call,
        .Next => &undefined_byte_address_call,
        .Ahead => &unstreamed_byte_address_call,
    };
    const length_call: *expr.FnCall = &len_fn_call;
    const offset_name_symbol: Expr = expr.symbol(tok.offset_name);
    const location_call_op: Expr = expr.call(location_call);
    const length_call_op: Expr = expr.call(length_call);
    const location_op: Expr = blk: {
        if (is_read and is_relative) {
            if (is_one) {
                location_call.subst(offset_name_symbol, expr.constant(1));
            }
            if (is_count or is_many) {
                location_call.subst(offset_name_symbol, expr.symbol(tok.count_name));
            }
        }
        break :blk location_call_op;
    };
    const length_op: Expr = blk: {
        if (is_write) {
            if (is_count) {
                break :blk expr.symbol(tok.count_name);
            }
            if (is_many) {
                break :blk expr.symbol(tok.many_values_len);
            }
        }
        break :blk length_call_op;
    };
    var pointer_one_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.intr_pointer_one_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = location_op,
    });
    const pointer_many_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.intr_pointer_many_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = location_op,
        .op3 = length_op,
    });
    const pointer_count_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.intr_pointer_count_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = location_op,
        .op3 = length_op,
    });
    const pointer_many_with_sentinel_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = tok.intr_pointer_many_with_sentinel_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = location_op,
        .op3 = length_op,
        .op4 = expr.symbol(tok.sentinel_name),
    });
    const pointer_count_with_sentinel_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = tok.intr_pointer_count_with_sentinel_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = location_op,
        .op3 = length_op,
        .op4 = expr.symbol(tok.sentinel_name),
    });
    const write_format_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.write_format_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.array_name),
        .op3 = expr.symbol(tok.format_name),
    });
    const write_fields_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_fields_structured_fn_name
        else
            tok.write_fields_unstructured_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.array_name),
        .op4 = expr.symbol(tok.fields_name),
    });
    const write_args_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_args_structured_fn_name
        else
            tok.write_args_unstructured_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.array_name),
        .op4 = expr.symbol(tok.args_name),
    });
    const write_any_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = if (ctn_detail.layouts.structured)
            tok.write_any_structured_fn_name
        else
            tok.write_any_unstructured_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.array_name),
        .op4 = expr.symbol(tok.any_name),
    });
    const length_format_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.length_format_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.format_name),
    });
    const length_fields_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.length_fields_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.fields_name),
    });
    const length_args_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.length_args_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.args_name),
    });
    const length_any_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.length_any_fn_name,
        .op1 = expr.symbol(tok.child_type_name),
        .op2 = expr.symbol(tok.reinterpret_spec_name),
        .op3 = expr.symbol(tok.any_name),
    });
    const write_one_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeOne),
    };
    const write_count_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeCount),
    };
    const write_many_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeMany),
    };
    const write_format_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeFormat),
    };
    const write_args_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeArgs),
    };
    const write_fields_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeFields),
    };
    const write_any_intr_call: expr.FnCallIntr = .{
        .ctn_detail = ctn_detail,
        .ctn_fn_info = interface.get(.writeAny),
    };
    var increment_fn_call: expr.FnCall =
        expr.FnCall.intr(allocator, ctn_detail, interface.get(.increment));

    switch (ctn_fn_info.tag) {
        .referOneAt,
        .referOneUndefined,
        .referOneBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_one_call);
            return array.writeMany(tok.end_expression);
        },
        .referManyAt,
        .referManyUndefined,
        .referManyBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_many_call);
            return array.writeMany(tok.end_expression);
        },
        .referManyWithSentinelAt,
        .referManyWithSentinelBehind,
        .referManyWithSentinelBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_many_with_sentinel_call);
            return array.writeMany(tok.end_expression);
        },
        .referCountAt,
        .referCountUndefined,
        .referCountBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_count_call);
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelAt,
        .referCountWithSentinelBehind,
        .referCountWithSentinelBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_count_with_sentinel_call);
            return array.writeMany(tok.end_expression);
        },
        .readOneAt,
        .readOneBack,
        => {
            const deref_ops: [2]Expr = expr.dereferenceS(expr.call(&pointer_one_call));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&deref_ops));
            return array.writeMany(tok.end_expression);
        },
        .readManyAt,
        .readManyBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_many_call);
            return array.writeMany(tok.end_expression);
        },
        .readManyWithSentinelAt,
        .readManyWithSentinelBehind,
        .readManyWithSentinelAhead,
        .readManyWithSentinelBack,
        => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(pointer_many_with_sentinel_call);
            return array.writeMany(tok.end_expression);
        },
        .readCountAt,
        .readCountBack,
        => {
            const deref_ops: [2]Expr = expr.dereferenceS(expr.call(&pointer_count_call));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&deref_ops));
            return array.writeMany(tok.end_expression);
        },
        .readCountWithSentinelAt,
        .readCountWithSentinelBehind,
        .readCountWithSentinelBack,
        => {
            const deref_ops: [2]Expr = expr.dereferenceS(expr.call(&pointer_count_with_sentinel_call));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&deref_ops));
            return array.writeMany(tok.end_expression);
        },
        .appendOne => {
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_one_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendCount => {
            increment_fn_call.subst(offset_name_symbol, expr.symbol(tok.count_name));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_count_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendMany => {
            increment_fn_call.subst(offset_name_symbol, expr.symbol(tok.many_values_len));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_many_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFormat => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_format_call));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendArgs => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_args_call));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFields => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_fields_call));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendAny => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_any_call));
            array.writeFormat(expr.call(&increment_fn_call));
            array.writeMany(tok.end_expression);
            array.writeFormat(write_any_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeOne => {
            if (config.implement_write_inline) {
                const deref_ops: [2]Expr = expr.dereferenceS(
                    expr.call(&pointer_one_call),
                );
                const assign_ops: [3]Expr = expr.assignS(
                    expr.join(&deref_ops),
                    expr.symbol(tok.value_name),
                );
                expr.formatWrite(expr.join(&assign_ops), array);
                return array.writeMany(tok.end_expression);
            } else {
                array.writeFormat(expr.FnCall.allocate(allocator, expr.FnCall3, .{
                    .symbol = tok.write_one_impl_fn_name,
                    .op1 = expr.symbol(tok.child_type_name),
                    .op2 = location_op,
                    .op3 = expr.symbol(tok.value_name),
                }));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeCount => {
            if (config.implement_write_inline) {
                if (config.implement_count_as_one) {
                    const deref_ops: [2]Expr = expr.dereferenceS(
                        expr.call(&pointer_one_call),
                    );
                    const assign_ops: [3]Expr = expr.assignS(
                        expr.join(&deref_ops),
                        expr.symbol(tok.value_name),
                    );
                    expr.formatWrite(expr.join(&assign_ops), array);
                    return array.writeMany(tok.end_expression);
                } else {
                    array.writeFormat(expr.ForLoop{
                        .op1 = expr.symbol(tok.count_values_name),
                        .symbol1 = tok.value_name,
                        .symbol2 = tok.loop_index_name,
                    });
                    const add_call_next_loop_index: expr.FnCall =
                        expr.FnCall.allocate(allocator, expr.FnCall2, .{
                        .symbol = tok.add_fn_name,
                        .op1 = expr.call(&undefined_byte_address_call),
                        .op2 = expr.symbol(tok.loop_index_name),
                    });
                    const deref_ops: [2]Expr = expr.dereferenceS(
                        expr.call(&add_call_next_loop_index),
                    );
                    const assign_ops: [3]Expr = expr.assignS(
                        expr.join(&deref_ops),
                        expr.symbol(tok.value_name),
                    );
                    expr.formatWrite(expr.join(&assign_ops), array);
                    return array.writeMany(tok.end_expression);
                }
            } else {
                array.writeFormat(expr.FnCall.allocate(allocator, expr.FnCall4, .{
                    .symbol = tok.write_count_impl_fn_name,
                    .op1 = expr.symbol(tok.child_type_name),
                    .op2 = expr.symbol(tok.count_name),
                    .op3 = location_op,
                    .op4 = expr.symbol(tok.count_values_name),
                }));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeMany => {
            array.writeFormat(expr.ForLoop{
                .op1 = expr.symbol(tok.many_values_name),
                .symbol1 = tok.value_name,
                .symbol2 = tok.loop_index_name,
            });
            const add_call_next_loop_index: expr.FnCall =
                expr.FnCall.allocate(allocator, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .op1 = expr.call(&undefined_byte_address_call),
                .op2 = expr.symbol(tok.loop_index_name),
            });
            pointer_one_call.subst(location_op, expr.call(&add_call_next_loop_index));
            const deref_ops: [2]Expr = expr.dereferenceS(
                expr.call(&pointer_one_call),
            );
            const assign_ops: [3]Expr = expr.assignS(
                expr.join(&deref_ops),
                expr.symbol(tok.value_name),
            );
            expr.formatWrite(expr.join(&assign_ops), array);
            return array.writeMany(tok.end_expression);
        },
        .writeFormat => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_format_call));
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeArgs => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_args_call));
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeFields => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_fields_call));
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeAny => {
            increment_fn_call.subst(offset_name_symbol, expr.call(&length_any_call));
            array.writeFormat(write_any_intr_call);
            return array.writeMany(tok.end_expression);
        },

        else => {}, //functionBodyUndefinedNotice(ctn_detail, ctn_fn_info),
    }
    switch (ctn_fn_info.kind) {
        .write => {
            if (ctn_fn_info.val == .One) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {} else {}
            }
            if (ctn_fn_info.val == .Many) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {} else {
                    array.writeMany(tok.write_many_impl_fn_name ++ "(");
                    gen.writeArgument(array, tok.child_type_name);
                    gen.writeComma(array);
                    array.writeFormat(location_op);
                    gen.writeArgument(array, tok.many_values_name);
                    array.writeMany(")");
                    return array.writeMany(tok.end_expression);
                }
            }
            if (ctn_fn_info.val == .Count) {
                if (ctn_fn_info.loc == .Next or config.implement_write_inline) {} else {
                    if (config.implement_count_as_one) {
                        array.writeMany(tok.write_one_impl_name ++ "([" ++ tok.count_name ++ "]");
                        array.writeMany(tok.child_type_name);
                        gen.writeComma(array);
                        array.writeFormat(location_op);
                    } else {
                        array.writeMany(tok.write_count_impl_fn_name ++ "(");
                        gen.writeArgument(array, tok.child_type_name);
                        gen.writeComma(array);
                        array.writeFormat(location_op);
                        gen.writeArgument(array, tok.count_name);
                    }
                    gen.writeArgument(array, tok.count_values_name);
                    array.writeMany(")");
                    return array.writeMany(tok.end_expression);
                }
            }
            if (ctn_fn_info.val == .Format) {
                array.writeFormat(write_format_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Fields) {
                array.writeFormat(write_fields_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Args) {
                array.writeFormat(write_args_call);
                return array.writeMany(tok.end_expression);
            }
            if (ctn_fn_info.val == .Any) {
                array.writeFormat(write_any_call);
                return array.writeMany(tok.end_expression);
            }
        },
        else => unreachable,
    }
}
fn writeFunctionBodySpecial(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const child_size_symbol: [:0]const u8 =
        if (ctn_detail.layouts.structured) tok.child_size_name else tok.call_sizeof_child;
    var writable_byte_count: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.writable_byte_count));
    setImplToMember(&writable_byte_count);
    var defined_byte_count: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.defined_byte_count));
    setImplToMember(&defined_byte_count);
    var undefined_byte_count: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.undefined_byte_count));
    setImplToMember(&undefined_byte_count);
    var streamed_byte_count: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.streamed_byte_count));
    setImplToMember(&streamed_byte_count);
    var unstreamed_byte_count: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.unstreamed_byte_count));
    setImplToMember(&unstreamed_byte_count);
    var aligned_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.aligned_byte_address));
    setImplToMember(&aligned_byte_address_call);
    var undefined_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.undefined_byte_address));
    setImplToMember(&undefined_byte_address_call);
    var unstreamed_byte_address_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.unstreamed_byte_address));
    setImplToMember(&unstreamed_byte_address_call);
    var define_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.define));
    setImplToMember(&define_call);
    var undefine_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.undefine));
    setImplToMember(&undefine_call);
    var seek_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.seek));
    setImplToMember(&seek_call);
    var tell_call: expr.FnCall =
        expr.FnCall.impl(allocator, ctn_detail.more(), implementation.get(.tell));
    setImplToMember(&tell_call);
    const amount_of_type_to_bytes_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.amount_of_type_to_bytes_fn_name,
        .op1 = expr.symbol(tok.amount_name),
        .op2 = expr.symbol(tok.child_type_name),
    });
    const mul_op_offset_child_size: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.mul_fn_name,
        .op1 = expr.symbol(tok.offset_name),
        .op2 = expr.symbol(child_size_symbol),
    });
    const mul_op_count_child_size: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.mul_fn_name,
        .op1 = expr.symbol(tok.count_name),
        .op2 = expr.symbol(child_size_symbol),
    });
    var data: [8]Expr = undefined;
    const amount_call: expr.FnCall = if (ctn_detail.layouts.structured)
        mul_op_count_child_size
    else
        amount_of_type_to_bytes_call;
    switch (ctn_fn_info.tag) {
        .len => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .op1 = if (ctn_detail.modes.resize)
                    expr.call(&defined_byte_count)
                else
                    expr.call(&writable_byte_count),
                .op2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .index => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .op1 = expr.call(&streamed_byte_count),
                .op2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .avail => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .op1 = expr.call(&undefined_byte_count),
                .op2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__at => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .op1 = expr.call(&aligned_byte_address_call),
                .op2 = expr.call(&mul_op_offset_child_size),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__ad => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .op1 = expr.call(&undefined_byte_address_call),
                .op2 = expr.call(&mul_op_offset_child_size),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__len => {
            var len_fn_call: expr.FnCall =
                expr.FnCall.intr(allocator, ctn_detail, interface.get(.len));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .op1 = expr.call(&len_fn_call),
                .op2 = expr.symbol(tok.offset_name),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__rem => {
            var avail_fn_call: expr.FnCall =
                expr.FnCall.intr(allocator, ctn_detail, interface.get(.avail));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .op1 = expr.call(&avail_fn_call),
                .op2 = expr.symbol(tok.offset_name),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__back => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .op1 = expr.call(&undefined_byte_address_call),
                .op2 = expr.call(&mul_op_offset_child_size),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__behind => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .op1 = expr.call(&unstreamed_byte_address_call),
                .op2 = expr.call(&mul_op_offset_child_size),
            }));
            return array.writeMany(tok.end_expression);
        },
        .define => {
            define_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&amount_call),
            );
            array.writeFormat(expr.call(&define_call));
            return array.writeMany(tok.end_expression);
        },
        .defineAll => {
            define_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&undefined_byte_count),
            );
            array.writeFormat(expr.call(&define_call));
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            undefine_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&amount_call),
            );
            array.writeFormat(expr.call(&undefine_call));
            return array.writeMany(tok.end_expression);
        },
        .undefineAll => {
            undefine_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&defined_byte_count),
            );
            array.writeFormat(expr.call(&undefine_call));
            return array.writeMany(tok.end_expression);
        },
        .stream => {
            seek_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&amount_call),
            );
            array.writeFormat(expr.call(&seek_call));
            return array.writeMany(tok.end_expression);
        },
        .streamAll => {
            seek_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&unstreamed_byte_count),
            );
            array.writeFormat(expr.call(&seek_call));
            return array.writeMany(tok.end_expression);
        },
        .unstream => {
            tell_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&amount_call),
            );
            array.writeFormat(expr.call(&tell_call));
            return array.writeMany(tok.end_expression);
        },
        .unstreamAll => {
            tell_call.subst(
                expr.symbol(tok.offset_bytes_name),
                expr.call(&streamed_byte_count),
            );
            array.writeFormat(expr.call(&tell_call));
            return array.writeMany(tok.end_expression);
        },
        .init => {

            //const wrap_in_error_call: expr.FnCall =
            //    expr.FnCall.allocate(allocator, expr.FnCall1, .{
            //    .symbol = tok.wrap_fn_name,
            //    .op1 = .{ .symbol = "allocator.allocate(" ++ tok.impl_type_name ++ ")" },
            //});
            //const wrap_in_try_stx: expr.Parentheses = .{
            //    .lhs = "try ",
            //    .op = expr.call(&wrap_in_error_call),
            //};
            //const impl_field_init_stx: expr.Parentheses = .{
            //    .lhs = ".{ ." ++ tok.impl_name ++ " = ",
            //    .op = .{ .parens = &wrap_in_try_stx },
            //    .rhs = "}",
            //};
            //array.writeMany(tok.return_keyword);
            //array.writeFormat(impl_field_init_stx);
            //return array.writeMany(tok.end_expression);
        },
        .deinit => {},
        .grow => {},
        .shrink => {},
        .increment => {},
        .decrement => {},

        .holder => {},
        .static => {},
        .dynamic => {},

        else => {}, // functionBodyUndefinedNotice(ctn_detail, ctn_fn_info),
    }
}
fn functionBodyUndefinedNotice(ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    array.writeMany("function body undefined: ");
    array.writeMany(ctn_fn_info.fnName());
    array.writeOne(' ');
    ctn_detail.writeContainerName(&array);
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn writeFunctionBodyGeneric(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const is_read: bool =
        ctn_fn_info.kind == .read or
        ctn_fn_info.kind == .refer;
    const is_write: bool =
        ctn_fn_info.kind == .write or
        ctn_fn_info.kind == .append;
    const is_primary: bool = is_read or is_write;

    if (is_primary) {
        return writeFunctionBodyPrimary(allocator, array, ctn_detail, ctn_fn_info);
    }
    writeFunctionBodySpecial(allocator, array, ctn_detail, ctn_fn_info);
}
fn writeFunctions(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    for (interface.key) |*ctn_fn_info| {
        if (!ctn_fn_info.hasCapability(ctn_detail)) {
            continue;
        }
        ctn_fn_info.writeSignature(array, ctn_detail);
        array.writeMany(interface.getReturnType(ctn_detail, ctn_fn_info));
        array.writeMany("{\n");
        writeFunctionBodyGeneric(allocator, array, ctn_detail, ctn_fn_info);
        array.writeMany("}\n");
    }
}
fn writeDeclarations(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    array.writeMany("const " ++ tok.array_type_name ++ " = @This();\n");
    if (ctn_detail.layouts.structured) {
        array.writeMany("const " ++ tok.child_type_name ++ " = spec." ++ tok.child_type_name ++ ";\n");
        array.writeMany("const " ++ tok.child_size_name ++ " = " ++ tok.call_sizeof_child ++ ";\n");
    }
    if (ctn_detail.kinds.dynamic or
        ctn_detail.kinds.parametric or
        ctn_detail.kinds.static)
    {
        array.writeMany("const " ++ tok.allocator_type_name ++ " = spec." ++ tok.allocator_type_name ++ ";\n");
    }
    const deduce_impl_type_call: expr.FnCall =
        expr.FnCall.allocate(allocator, expr.FnCall1, .{
        .symbol = "spec.deduce",
        .op1 = expr.symbol("params.options"),
    });
    const impl_type_decl: expr.ConstDecl = .{
        .var_name = tok.impl_type_name,
        .type_name = tok.type_type_name,
        .op1 = expr.call(&deduce_impl_type_call),
    };
    array.writeFormat(impl_type_decl);
}
inline fn writeFields(array: *Array) void {
    array.writeMany(tok.impl_field);
    array.writeMany(tok.end_item);
}
inline fn writeTypeFunction(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    array.writeMany("pub fn ");
    ctn_detail.writeContainerName(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ": anytype) type {\nreturn (struct {\n");
    {
        writeFields(array);
        writeDeclarations(allocator, array, ctn_detail);
        writeFunctions(allocator, array, ctn_detail);
    }
    array.writeMany("});\n}\n");
}

pub fn generateContainers() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1);
    array.undefineAll();
    var ctn_index: u16 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const s = allocator.save();
        defer allocator.restore(s);
        const ctn_group: []const u16 = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
        writeTypeFunction(&allocator, &array, out.impl_variants[ctn_group[0]].less());
    }
    gen.appendSourceFile(&array, "container.zig");
}

pub const main = generateContainers;
