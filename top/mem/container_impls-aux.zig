const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const algo = @import("../algo.zig");
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
const alloc_fn = @import("./alloc_fn.zig");

pub usingnamespace proc.start;

pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = false,
    .Fault = false,
};
pub const runtime_assertions: bool = false;

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
    .logging = preset.address_space.logging.silent,
});
const Array = Allocator.StructuredVector(u8);
const Fn = ctn_fn.Fn;
const Expr = expr.Expr;

fn writeFunctionBody(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn) void {
    if (Expr.debug.show_expressions) {
        Expr.debug.showFunction(ctn_fn_info.tag);
    }
    var define: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.define));
    var undefine: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefine));
    var seek: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.seek));
    var tell: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.tell));
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
    var aligned_byte_address: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.aligned_byte_address));
    var undefined_byte_address: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefined_byte_address));
    var unstreamed_byte_address: [3]Expr =
        makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.unstreamed_byte_address));
    const child_size_symbol: [:0]const u8 = if (ctn_detail.layouts.structured)
        tok.child_size_name
    else
        tok.call_sizeof_child;
    const defined_byte_count_call: Expr = expr.join(&defined_byte_count);
    const writable_byte_count_call: Expr = expr.join(&writable_byte_count);
    const readable_byte_count_call: Expr = if (ctn_detail.modes.resize)
        defined_byte_count_call
    else
        writable_byte_count_call;
    var increment_fn_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
    var len_fn_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
    var avail_fn_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.avail));
    var __len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__len));
    var __avail_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__avail));
    _ = __avail_call;
    var __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
    var __ad_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__ad));
    _ = __ad_call;
    var __back_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__back));
    _ = __back_call;
    var __behind_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__behind));
    var pointer_one: [3]Expr = expr.interfacePointerOne(
        expr.symbol(tok.child_type_name),
        undefined,
    );
    var pointer_many: [4]Expr = expr.interfacePointerMany(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
    );
    var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
        expr.symbol(tok.sentinel_name),
    );
    var pointer_count: [4]Expr = expr.interfacePointerCount(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
    );
    var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
        expr.symbol(tok.sentinel_name),
    );
    var amount_of_type_to_bytes: [3]Expr = expr.amountOfTypeToBytes(
        expr.symbol(tok.offset_name),
        expr.symbol(tok.child_type_name),
    );
    var mul_offset_child_size: [3]Expr = if (ctn_detail.layouts.structured)
        expr.mul(expr.symbol(tok.offset_name), expr.symbol(child_size_symbol))
    else
        amount_of_type_to_bytes;
    var mul_count_child_size: [3]Expr = expr.mul(
        expr.symbol(tok.count_name),
        expr.symbol(child_size_symbol),
    );
    const pointer_one_loc: *Expr = &pointer_one[2];
    const pointer_many_loc: *Expr = &pointer_many[2];
    const pointer_many_len: *Expr = &pointer_many[3];
    const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
    const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
    const pointer_count_loc: *Expr = &pointer_count[2];
    const pointer_count_len: *Expr = &pointer_count[3];
    const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
    const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];

    if (ctn_fn_info.kind == .append) return;

    switch (ctn_fn_info.tag) {
        .readAll, .referAllDefined => {
            pointer_many_loc.* = expr.join(&aligned_byte_address);
            pointer_many_len.* = len_fn_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .readAllWithSentinel, .referAllDefinedWithSentinel => {
            pointer_many_with_sentinel_loc.* = expr.join(&aligned_byte_address);
            pointer_many_with_sentinel_len.* = len_fn_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneBehind => {
            pointer_one_loc.* = __behind_call;
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = if (ctn_detail.layouts.structured)
                    expr.symbol(child_size_symbol)
                else
                    expr.symbol(tok.const_amount_1),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        // return an array of type with a given length ending at unstreamed
        .readCountBehind => {
            pointer_count_loc.* = __behind_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .readCountWithSentinelBehind => {
            pointer_count_with_sentinel_loc.* = __behind_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelBehind => {
            pointer_count_with_sentinel_loc.* = __behind_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        // returns
        .readManyBehind => {
            pointer_many_loc.* = __behind_call;
            pointer_many_len.* = expr.symbol(tok.count_name);
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .readManyWithSentinelBehind, .referManyWithSentinelBehind => {
            pointer_many_with_sentinel_loc.* = __behind_call;
            pointer_many_with_sentinel_len.* = expr.symbol(tok.count_name);
            expr.subst(__behind_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneAt => {
            pointer_one_loc.* = __at_call;
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_one_deref));
            return array.writeMany(tok.end_expression);
        },
        .referOneAt => {
            pointer_one_loc.* = __at_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .overwriteOneAt => {
            pointer_one_loc.* = __at_call;
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            var pointer_one_deref_assign_value: [3]Expr = expr.assign(
                expr.join(&pointer_one_deref),
                expr.symbol(tok.value_name),
            );
            array.writeFormat(expr.join(&pointer_one_deref_assign_value));
            return array.writeMany(tok.end_expression);
        },
        .readCountAt => {
            pointer_count_loc.* = __at_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_deref));
            return array.writeMany(tok.end_expression);
        },
        .referCountAt => {
            pointer_count_loc.* = __at_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .overwriteCountAt => {
            pointer_count_loc.* = __at_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            var pointer_count_deref_assign_values: [3]Expr = expr.assign(
                expr.join(&pointer_count_deref),
                expr.symbol(tok.count_values_name),
            );
            array.writeFormat(expr.join(&pointer_count_deref_assign_values));
            return array.writeMany(tok.end_expression);
        },
        .readCountWithSentinelAt => {
            pointer_count_with_sentinel_loc.* = __at_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            var pointer_count_with_sentinel_deref: [2]Expr = expr.dereference(expr.call(&pointer_count_with_sentinel));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_with_sentinel_deref));
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelAt => {
            pointer_count_with_sentinel_loc.* = __at_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readManyAt => {
            pointer_many_loc.* = __at_call;
            if (config.user_defined_length) {
                pointer_many_len.* = expr.symbol(tok.count_name);
            } else {
                pointer_many_len.* = __len_call;
            }
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .referManyAt => {},
        .overwriteManyAt => {},
        .readManyWithSentinelAt => {},
        .referManyWithSentinelAt => {},
        .readOneAhead => {},
        .readCountAhead => {},
        .readCountWithSentinelAhead => {},
        .readManyAhead => {},
        .readManyWithSentinelAhead => {},
        .readOneBack => {},
        .referOneBack => {},
        .overwriteOneBack => {},
        .readCountBack => {},
        .referCountBack => {},
        .overwriteCountBack => {},
        .readCountWithSentinelBack => {},
        .referCountWithSentinelBack => {},
        .readManyBack => {},
        .referManyBack => {},
        .overwriteManyBack => {},
        .readManyWithSentinelBack => {},
        .referManyWithSentinelBack => {},
        .referAllUndefined => {},
        .referAllUndefinedWithSentinel => {},
        .referOneUndefined => {},
        .referCountUndefined => {},
        .referManyUndefined => {},
        .appendOne => {
            const write_one_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeOne));
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_one_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendCount => {
            const write_count_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeCount));
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.count_name),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_count_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendMany => {
            const write_many_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeMany));
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.symbol(tok.many_values_len),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_many_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFormat => {
            const write_format_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFormat));
            var length_format: [3]Expr = expr.fnCall2(
                tok.length_format_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.format_name),
            );
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.call(&length_format),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendArgs => {
            const write_args_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeArgs));
            var length_args: [4]Expr = expr.fnCall3(
                tok.length_args_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.args_name),
            );
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.call(&length_args),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFields => {
            const write_fields_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFields));
            var length_fields: [4]Expr = expr.fnCall3(
                tok.length_fields_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.fields_name),
            );
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.call(&length_fields),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendAny => {
            const write_any_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeAny));
            var length_any: [4]Expr = expr.fnCall3(
                tok.length_any_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.any_name),
            );
            expr.subst(increment_fn_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = expr.call(&length_any),
            });
            array.writeFormat(increment_fn_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_any_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeOne => {
            if (config.implement_write_inline) {
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                pointer_one_loc.* = expr.join(&undefined_byte_address);
                var pointer_one_deref_assign_value: [3]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.join(&pointer_one_deref_assign_value));
                return array.writeMany(tok.end_expression);
            } else {
                var write_one: [4]Expr = expr.fnCall3(
                    tok.write_one_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.call(&write_one));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeCount => {
            if (config.implement_write_inline) {
                var add_undefined_byte_address_loop_index: [3]Expr = expr.add(
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.loop_index_name),
                );
                pointer_one_loc.* = expr.call(&add_undefined_byte_address_loop_index);
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                var pointer_one_deref_assign_value: [3]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.ForLoop{
                    .expr1 = expr.symbol(tok.count_values_name),
                    .symbol1 = tok.value_name,
                    .symbol2 = tok.loop_index_name,
                });
                array.writeFormat(expr.join(&pointer_one_deref_assign_value));
                return array.writeMany(tok.end_expression);
            } else {
                var write_count: [5]Expr = expr.fnCall4(
                    tok.write_count_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.symbol(tok.count_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.count_values_name),
                );
                array.writeFormat(expr.call(&write_count));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeMany => {
            if (config.implement_write_inline) {
                var add_undefined_byte_address_loop_index: [3]Expr = expr.add(
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.loop_index_name),
                );
                pointer_one_loc.* = expr.call(&add_undefined_byte_address_loop_index);
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                var pointer_one_deref_assign_value: [3]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.ForLoop{
                    .expr1 = expr.symbol(tok.many_values_name),
                    .symbol1 = tok.value_name,
                    .symbol2 = tok.loop_index_name,
                });
                array.writeFormat(expr.join(&pointer_one_deref_assign_value));
                return array.writeMany(tok.end_expression);
            } else {
                var write_many: [4]Expr = expr.fnCall3(
                    tok.write_many_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.many_values_name),
                );
                array.writeFormat(expr.call(&write_many));
                return array.writeMany(tok.end_expression);
            }
        },
        .writeFormat => {
            var write_format: [4]Expr = expr.fnCall3(
                tok.write_format_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.format_name),
            );
            array.writeFormat(expr.call(&write_format));
            return array.writeMany(tok.end_expression);
        },
        .writeArgs => {
            var write_args: [5]Expr = expr.fnCall4(
                if (ctn_detail.layouts.structured)
                    tok.write_args_structured_fn_name
                else
                    tok.write_args_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.args_name),
            );
            array.writeFormat(expr.call(&write_args));
            return array.writeMany(tok.end_expression);
        },
        .writeFields => {
            var write_fields: [5]Expr = expr.fnCall4(
                if (ctn_detail.layouts.structured)
                    tok.write_fields_structured_fn_name
                else
                    tok.write_fields_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.fields_name),
            );
            array.writeFormat(expr.call(&write_fields));
            return array.writeMany(tok.end_expression);
        },
        .writeAny => {
            var write_any: [5]Expr = expr.fnCall4(
                if (ctn_detail.layouts.structured)
                    tok.write_any_structured_fn_name
                else
                    tok.write_any_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.any_name),
            );
            array.writeFormat(expr.call(&write_any));
            return array.writeMany(tok.end_expression);
        },
        // return count of defined of type
        .len => {
            var div_count_size: [3]Expr = expr.divT(
                readable_byte_count_call,
                expr.symbol(child_size_symbol),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return count of streamed of type
        .index => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&streamed_byte_count),
                expr.symbol(child_size_symbol),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return count of undefined of type
        .avail => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&undefined_byte_count),
                expr.symbol(child_size_symbol),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return count of unstreamed of type
        .ahead => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&unstreamed_byte_count),
                expr.symbol(child_size_symbol),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return aligned address offset above amount of type
        .__at => {
            array.writeMany(tok.return_keyword);
            var add_aligned_offset: [3]Expr = expr.add(
                expr.join(&aligned_byte_address),
                expr.call(&mul_offset_child_size),
            );
            array.writeFormat(expr.call(&add_aligned_offset));
            return array.writeMany(tok.end_expression);
        },
        // return undefined address offset above amount of type
        .__ad => {
            array.writeMany(tok.return_keyword);
            var add_undefined_offset: [3]Expr = expr.add(
                expr.join(&undefined_byte_address),
                expr.call(&mul_offset_child_size),
            );
            array.writeFormat(expr.call(&add_undefined_offset));
            return array.writeMany(tok.end_expression);
        },
        // return count of defined of type subtract amount of type
        .__len => {
            var sub_len_offset: [3]Expr = expr.sub(len_fn_call, expr.call(&mul_offset_child_size));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_len_offset));
            return array.writeMany(tok.end_expression);
        },
        // return count of undefined of type  subtract amount of type
        .__avail => {
            array.writeMany(tok.return_keyword);
            var sub_avail_offset: [3]Expr = expr.sub(avail_fn_call, expr.symbol(tok.offset_name));
            array.writeFormat(expr.call(&sub_avail_offset));
            return array.writeMany(tok.end_expression);
        },
        // return undefined address offset below amount of type
        .__back => {
            array.writeMany(tok.return_keyword);
            var sub_undefined_offset: [3]Expr = expr.sub(
                expr.join(&undefined_byte_address),
                expr.call(&mul_offset_child_size),
            );
            array.writeFormat(expr.call(&sub_undefined_offset));
            return array.writeMany(tok.end_expression);
        },
        // return unstreamed address subtract amount of type
        .__behind => {
            var sub_unstreamed_offset: [3]Expr = expr.sub(
                expr.join(&unstreamed_byte_address),
                expr.call(&mul_offset_child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_unstreamed_offset));
            return array.writeMany(tok.end_expression);
        },
        .define => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(define[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layouts.structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&define));
            return array.writeMany(tok.end_expression);
        },
        .defineAll => {
            expr.subst(define[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&undefined_byte_count),
            });
            array.writeFormat(expr.join(&define));
            return array.writeMany(tok.end_expression);
        },
        .undefine => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(undefine[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layouts.structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&undefine));
            return array.writeMany(tok.end_expression);
        },
        .undefineAll => {
            expr.subst(undefine[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&defined_byte_count),
            });
            array.writeFormat(expr.join(&undefine));
            return array.writeMany(tok.end_expression);
        },
        .stream => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(seek[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layouts.structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&seek));
            return array.writeMany(tok.end_expression);
        },
        .streamAll => {
            expr.subst(seek[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&unstreamed_byte_count),
            });
            array.writeFormat(expr.join(&seek));
            return array.writeMany(tok.end_expression);
        },
        .unstream => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(tell[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layouts.structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&tell));
            return array.writeMany(tok.end_expression);
        },
        .unstreamAll => {
            expr.subst(tell[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&streamed_byte_count),
            });
            array.writeFormat(expr.join(&tell));
            return array.writeMany(tok.end_expression);
        },
        .init => {
            // alloc_fn.get(.allocate);
        },
        .deinit => {
            // alloc_fn.get(.deallocate);
        },
        // set writable count of type above defined
        //.realloc => {
        //    alloc_fn.get(.reallocate);
        //},
        // set writable count of type above current
        .grow => {
            // alloc_fn.get(.resizeAbove);
        },
        // set writable count of type below current
        .shrink => {
            // alloc_fn.get(.resizeBelow);
        },
        // require at least this many count of type undefined
        // (grow if less than this undefined)
        .increment => {
            // alloc_fn.get(.resizeDeficit);
        },
        // require at most this many count of type undefined
        // (shrink if more than this undefined)
        .decrement => {
            // alloc_fn.get(.resizeSurplus);
        },

        .holder => {},
        .static => {},
        .dynamic => {},
    }
}
fn makeImplFnMemberCall(allocator: *Allocator, ctn_detail: *const out.DetailLess, impl_fn_info: *const impl_fn.Fn) [3]Expr {
    // Using array_impl in expr.impl would be better.
    return expr.fieldAccess(
        expr.symbol(tok.array_name),
        expr.impl(allocator, ctn_detail, impl_fn_info),
    );
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
fn writeFunctions(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    for (&ctn_fn.key) |*ctn_fn_info| {
        if (!ctn_fn_info.hasCapability(ctn_detail)) {
            continue;
        }
        const len_0: u64 = array.len();
        ctn_fn_info.writeSignature(array, ctn_detail);
        array.writeMany("{\n");
        const len_1: u64 = array.len();
        writeFunctionBody(allocator, array, ctn_detail, ctn_fn_info);
        const len_2: u64 = array.len();
        if (len_1 == len_2) {
            array.undefine(len_1 - len_0);
        } else {
            array.writeMany("}\n");
        }
    }
}

fn writeDeclarations(allocator: *Allocator, array: *Array, ctn_detail: *const out.DetailLess) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);

    const const_decl: *expr.ConstDecl = allocator.duplicateIrreversible(expr.ConstDecl, .{
        .val_name = tok.array_type_name,
        .type_name = tok.type_type_name,
        .expr1 = expr.symbol(tok.call_this),
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
    const_decl.* = expr.ConstDecl{
        .val_name = tok.impl_type_name,
        .type_name = tok.type_type_name,
        .expr1 = expr.symbol("spec.Implementation()"),
    };
    array.writeFormat(const_decl.*);
}
inline fn writeFields(array: *Array) void {
    array.writeMany(tok.impl_field);
    array.writeMany(tok.end_list_item);
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

    var array: Array = Array.init(&allocator, 1024 * 4096);
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
    gen.appendSourceFile(&array, "containers.zig");
}

pub const main = generateContainers;
