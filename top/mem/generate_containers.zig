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
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = false;
pub const is_silent: bool = true;
pub const runtime_assertions: bool = true;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .up_addr = 0x80000000,
    .lb_offset = 0x40000000,
    .divisions = 128,
    .errors = .{},
    .logging = preset.address_space.logging.silent,
});
const Array = Allocator.StructuredStaticVector(u8, 1024 * 4096);
const Fn = ctn_fn.Fn;
const Expr = expr.Expr;

fn writeFunctionBodyPrimary(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    var aligned_byte_address_call: [3]Expr = expr.fieldAccessS(
        expr.symbol(tok.array_name),
        expr.FnCall.impl(allocator, ctn_detail.more(), impl_fn.get(.aligned_byte_address)),
    );
    var undefined_byte_address_call: [3]Expr = expr.fieldAccessS(
        expr.symbol(tok.array_name),
        expr.FnCall.impl(allocator, ctn_detail.more(), impl_fn.get(.undefined_byte_address)),
    );
    var unstreamed_byte_address_call: [3]Expr = expr.fieldAccessS(
        expr.symbol(tok.array_name),
        expr.FnCall.impl(allocator, ctn_detail.more(), impl_fn.get(.unstreamed_byte_address)),
    );
    aligned_byte_address_call[2].tag = .call_member;
    undefined_byte_address_call[2].tag = .call_member;
    unstreamed_byte_address_call[2].tag = .call_member;
    const offset_name_symbol: Expr = expr.symbol(tok.offset_name);
    var increment_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.increment));
    var len_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.len));
    _ = len_fn_call;
    var avail_fn_cal: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.avail));
    _ = avail_fn_cal;
    var __len_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__len));
    _ = __len_fn_call;
    var __rem_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__rem));
    _ = __rem_fn_call;
    var __at_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__at));
    _ = __at_fn_call;
    var __ad_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__ad));
    _ = __ad_fn_call;
    var __back_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__back));
    _ = __back_fn_call;
    var __behind_fn_call: Expr =
        expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.__behind));
    _ = __behind_fn_call;

    const location_op = expr.symbol(tok.loop_index_name);
    const length_op = expr.symbol(tok.offset_name);

    var pointer_one_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.intr_pointer_one_fn_name,
        .arg1 = expr.symbol(tok.child_type_name),
        .arg2 = location_op,
    });
    var pointer_many_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.intr_pointer_many_fn_name,
        .arg1 = expr.symbol(tok.child_type_name),
        .arg2 = location_op,
        .arg3 = length_op,
    });
    _ = pointer_many_call;
    var pointer_count_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
        .symbol = tok.intr_pointer_count_fn_name,
        .arg1 = expr.symbol(tok.child_type_name),
        .arg2 = location_op,
        .arg3 = length_op,
    });
    var pointer_count_with_sentinel_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall4, .{
        .symbol = tok.intr_pointer_count_with_sentinel_fn_name,
        .arg1 = expr.symbol(tok.child_type_name),
        .arg2 = location_op,
        .arg3 = length_op,
        .arg4 = expr.symbol(tok.sentinel_name),
    });
    _ = pointer_count_with_sentinel_call;

    switch (ctn_fn_info.tag) {
        .referOneAt => {},
        .referOneUndefined => {},
        .referOneBack => {},
        .referManyAt => {},
        .referManyUndefined => {},
        .referManyBack => {},
        .referManyWithSentinelAt => {},
        .referManyWithSentinelBehind => {},
        .referManyWithSentinelBack => {},
        .referCountAt => {},
        .referCountUndefined => {},
        .referCountBack => {},
        .referCountWithSentinelAt => {},
        .referCountWithSentinelBehind => {},
        .referCountWithSentinelBack => {},
        .readOneAt => {},
        .readOneBack => {},
        .readManyAt => {},
        .readManyBack => {},
        .readManyWithSentinelAt => {},
        .readManyWithSentinelBehind => {},
        .readManyWithSentinelAhead => {},
        .readManyWithSentinelBack => {},
        .readCountAt => {},
        .readCountBack => {},
        .readCountWithSentinelAt => {},
        .readCountWithSentinelBehind => {},
        .readCountWithSentinelBack => {},
        .appendOne => {
            const write_one_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeOne));
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_one_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendCount => {
            const write_count_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeCount));
            increment_fn_call.subst(offset_name_symbol, expr.symbol(tok.count_name));
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_count_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendMany => {
            const write_many_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeMany));
            increment_fn_call.subst(offset_name_symbol, expr.symbol(tok.many_values_len));
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_many_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFormat => {
            const write_format_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeFormat));
            const length_format_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall2, .{
                .symbol = tok.length_format_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.format_name),
            });
            increment_fn_call.subst(offset_name_symbol, length_format_call);
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendArgs => {
            const write_args_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeArgs));
            const length_args_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
                .symbol = tok.length_args_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.args_name),
            });
            increment_fn_call.subst(offset_name_symbol, length_args_call);
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFields => {
            const write_fields_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeFields));
            const length_fields_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
                .symbol = tok.length_fields_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.fields_name),
            });
            increment_fn_call.subst(offset_name_symbol, length_fields_call);
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendAny => {
            const write_any_intr_call: Expr = expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.writeAny));
            const length_any_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
                .symbol = tok.length_any_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.any_name),
            });
            increment_fn_call.subst(offset_name_symbol, length_any_call);
            array.writeFormat(increment_fn_call);
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
                    .arg1 = expr.symbol(tok.child_type_name),
                    .arg2 = location_op,
                    .arg3 = expr.symbol(tok.value_name),
                }));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeCount => {
            if (config.implement_write_inline) {
                if (config.implement_count_as_one) {
                    pointer_count_call.subst(
                        expr.symbol(tok.child_type_name),
                        expr.symbol(tok.child_array_ptr_type_name),
                    );
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
                        .expr1 = expr.symbol(tok.count_values_name),
                        .symbol1 = tok.value_name,
                        .symbol2 = tok.loop_index_name,
                    });
                    const add_call_next_loop_index: Expr = expr.FnCall.allocate(allocator, expr.FnCall2, .{
                        .symbol = tok.add_fn_name,
                        .arg1 = expr.call(&undefined_byte_address_call),
                        .arg2 = expr.symbol(tok.loop_index_name),
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
                    .arg1 = expr.symbol(tok.child_type_name),
                    .arg2 = expr.symbol(tok.count_name),
                    .arg3 = location_op,
                    .arg4 = expr.symbol(tok.count_values_name),
                }));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeMany => {
            array.writeFormat(expr.ForLoop{
                .expr1 = expr.symbol(tok.many_values_name),
                .symbol1 = tok.value_name,
                .symbol2 = tok.loop_index_name,
            });
            const add_undefined_byte_address_call_loop_index: Expr = expr.FnCall.allocate(allocator, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .arg1 = expr.join(&undefined_byte_address_call),
                .arg2 = expr.symbol(tok.loop_index_name),
            });
            pointer_one_call.subst(location_op, add_undefined_byte_address_call_loop_index);
            const deref_ops: [2]Expr = expr.dereferenceS(pointer_one_call);
            const assign_ops: [3]Expr = expr.assignS(
                expr.join(&deref_ops),
                expr.symbol(tok.value_name),
            );
            expr.formatWrite(expr.join(&assign_ops), array);
            return array.writeMany(tok.end_expression);
        },
        .writeFormat => {
            const write_format_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall3, .{
                .symbol = tok.write_format_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.array_name),
                .arg3 = expr.symbol(tok.format_name),
            });
            array.writeFormat(write_format_call);
            return array.writeMany(tok.end_expression);
        },
        .writeArgs => {
            const write_args_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall4, .{
                .symbol = if (ctn_detail.layouts.structured)
                    tok.write_args_structured_fn_name
                else
                    tok.write_args_unstructured_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.array_name),
                .arg4 = expr.symbol(tok.args_name),
            });
            array.writeFormat(write_args_call);
            return array.writeMany(tok.end_expression);
        },
        .writeFields => {
            const write_fields_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall4, .{
                .symbol = if (ctn_detail.layouts.structured)
                    tok.write_fields_structured_fn_name
                else
                    tok.write_fields_unstructured_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.array_name),
                .arg4 = expr.symbol(tok.fields_name),
            });
            array.writeFormat(write_fields_call);
            return array.writeMany(tok.end_expression);
        },
        .writeAny => {
            const write_any_call: Expr = expr.FnCall.allocate(allocator, expr.FnCall4, .{
                .symbol = if (ctn_detail.layouts.structured)
                    tok.write_any_structured_fn_name
                else
                    tok.write_any_unstructured_fn_name,
                .arg1 = expr.symbol(tok.child_type_name),
                .arg2 = expr.symbol(tok.reinterpret_spec_name),
                .arg3 = expr.symbol(tok.array_name),
                .arg4 = expr.symbol(tok.any_name),
            });
            array.writeFormat(write_any_call);
            return array.writeMany(tok.end_expression);
        },
        else => {}, //functionBodyUndefinedNotice(ctn_detail, ctn_fn_info),
    }
}
fn makeImplFnMemberCall(allocator: *Allocator, ctn_detail: *const out.DetailLess, impl_fn_info: *const impl_fn.Fn) [3]Expr {
    var ret: [3]Expr = expr.fieldAccessS(
        expr.symbol(tok.array_name),
        expr.FnCall.impl(allocator, ctn_detail.more(), impl_fn_info),
    );
    ret[2].tag = .call_member;
    return ret;
}
fn writeFunctionBodySpecial(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    const child_size_symbol: [:0]const u8 =
        if (ctn_detail.layouts.structured) tok.child_size_name else tok.call_sizeof_child;
    var writable_byte_count: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.writable_byte_count));
    var defined_byte_count: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.defined_byte_count));
    var undefined_byte_count: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefined_byte_count));
    var streamed_byte_count: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.streamed_byte_count));
    var unstreamed_byte_count: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.unstreamed_byte_count));
    var aligned_byte_address_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.aligned_byte_address));
    var undefined_byte_address_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefined_byte_address));
    var unstreamed_byte_address_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.unstreamed_byte_address));
    var define_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.define));
    var undefine_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefine));
    var seek_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.seek));
    var tell_call: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.tell));

    const amount_of_type_to_bytes_call: Expr =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.amount_of_type_to_bytes_fn_name,
        .arg1 = expr.symbol(tok.amount_name),
        .arg2 = expr.symbol(tok.child_type_name),
    });
    const mul_op_offset_child_size: Expr =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.mul_fn_name,
        .arg1 = expr.symbol(tok.offset_name),
        .arg2 = expr.symbol(child_size_symbol),
    });
    const mul_op_count_child_size: Expr =
        expr.FnCall.allocate(allocator, expr.FnCall2, .{
        .symbol = tok.mul_fn_name,
        .arg1 = expr.symbol(tok.count_name),
        .arg2 = expr.symbol(child_size_symbol),
    });
    var data: [8]Expr = undefined;
    const amount_call: Expr = if (ctn_detail.layouts.structured)
        mul_op_count_child_size
    else
        amount_of_type_to_bytes_call;
    switch (ctn_fn_info.tag) {
        .len => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .arg1 = if (ctn_detail.modes.resize)
                    expr.join(&defined_byte_count)
                else
                    expr.join(&writable_byte_count),
                .arg2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .index => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .arg1 = expr.join(&streamed_byte_count),
                .arg2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .avail => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.div_trunc_fn_name,
                .arg1 = expr.join(&undefined_byte_count),
                .arg2 = expr.symbol(child_size_symbol),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__at => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .arg1 = expr.join(&aligned_byte_address_call),
                .arg2 = mul_op_offset_child_size,
            }));
            return array.writeMany(tok.end_expression);
        },
        .__ad => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.add_fn_name,
                .arg1 = expr.join(&undefined_byte_address_call),
                .arg2 = mul_op_offset_child_size,
            }));
            return array.writeMany(tok.end_expression);
        },
        .__len => {
            var len_fn_call: Expr =
                expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.len));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .arg1 = len_fn_call,
                .arg2 = expr.symbol(tok.offset_name),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__rem => {
            var avail_fn_call: Expr =
                expr.FnCall.intr(allocator, ctn_detail, ctn_fn.get(.avail));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .arg1 = avail_fn_call,
                .arg2 = expr.symbol(tok.offset_name),
            }));
            return array.writeMany(tok.end_expression);
        },
        .__back => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .arg1 = expr.join(&undefined_byte_address_call),
                .arg2 = mul_op_offset_child_size,
            }));
            return array.writeMany(tok.end_expression);
        },
        .__behind => {
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.FnCall.data(&data, expr.FnCall2, .{
                .symbol = tok.sub_fn_name,
                .arg1 = expr.join(&unstreamed_byte_address_call),
                .arg2 = mul_op_offset_child_size,
            }));
            return array.writeMany(tok.end_expression);
        },
        .define => {
            define_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                amount_call,
            );
            array.writeFormat(expr.join(&define_call));
            return array.writeMany(tok.end_expression);
        },
        .defineAll => {
            define_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                expr.join(&undefined_byte_count),
            );
            array.writeFormat(expr.join(&define_call));
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            undefine_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                amount_call,
            );
            array.writeFormat(expr.join(&undefine_call));
            return array.writeMany(tok.end_expression);
        },
        .undefineAll => {
            undefine_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                expr.join(&defined_byte_count),
            );
            array.writeFormat(expr.join(&undefine_call));
            return array.writeMany(tok.end_expression);
        },
        .stream => {
            seek_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                amount_call,
            );
            array.writeFormat(expr.join(&seek_call));
            return array.writeMany(tok.end_expression);
        },
        .streamAll => {
            seek_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                expr.join(&unstreamed_byte_count),
            );
            array.writeFormat(expr.join(&seek_call));
            return array.writeMany(tok.end_expression);
        },
        .unstream => {
            tell_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                amount_call,
            );
            array.writeFormat(expr.join(&tell_call));
            return array.writeMany(tok.end_expression);
        },
        .unstreamAll => {
            tell_call[2].subst(
                expr.symbol(tok.offset_bytes_name),
                expr.join(&streamed_byte_count),
            );
            array.writeFormat(expr.join(&tell_call));
            return array.writeMany(tok.end_expression);
        },

        .init => {},
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
    for (ctn_fn.key) |*ctn_fn_info| {
        if (!ctn_fn_info.hasCapability(ctn_detail)) {
            continue;
        }
        ctn_fn_info.writeSignature(array, ctn_detail);
        array.writeMany(ctn_fn_info.getReturnType());
        array.writeMany("{\n");
        writeFunctionBodyGeneric(allocator, array, ctn_detail, ctn_fn_info);
        array.writeMany("}\n");
    }
}

fn writeDeclarations(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);

    const const_decl: *expr.ConstDecl = allocator.duplicateIrreversible(expr.ConstDecl, .{
        .val_name = tok.array_type_name,
        .type_name = tok.type_type_name,
        .expr1 = expr.symbol("@This()"),
    });
    array.writeFormat(const_decl.*);
    if (ctn_detail.layouts.structured) {
        const_decl.* = expr.ConstDecl{
            .val_name = tok.child_type_name,
            .type_name = tok.type_type_name,
            .expr1 = expr.symbol(tok.child_specifier_name),
        };
        array.writeFormat(const_decl.*);
        const_decl.* = expr.ConstDecl{
            .val_name = tok.child_size_name,
            .type_name = tok.word_type_name,
            .expr1 = expr.symbol(tok.call_sizeof_child),
        };
        array.writeFormat(const_decl.*);
    }
    if (ctn_detail.kinds.dynamic or
        ctn_detail.kinds.parametric or
        ctn_detail.kinds.static)
    {
        const_decl.* = expr.ConstDecl{
            .val_name = tok.allocator_type_name,
            .type_name = tok.type_type_name,
            .expr1 = expr.symbol(tok.slave_specifier_type_name),
        };
        array.writeFormat(const_decl.*);
    }
    const deduce_impl_type_call: Expr =
        expr.FnCall.allocate(allocator, expr.FnCall1, .{
        .symbol = "spec.deduce",
        .arg1 = expr.symbol("params.options"),
    });
    const_decl.* = expr.ConstDecl{
        .val_name = tok.impl_type_name,
        .type_name = tok.type_type_name,
        .expr1 = deduce_impl_type_call,
    };
    array.writeFormat(const_decl.*);
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
    var ctn_index: u64 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);
        const ctn_group: []const out.Index = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
        writeTypeFunction(&allocator, &array, out.impl_variants[ctn_group[0]].less());
    }
    gen.appendSourceFile(&array, "container.zig");
}

pub const main = generateContainers;
