const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const file = gen.file;
const mach = gen.mach;
const algo = gen.algo;
const proc = gen.proc;
const meta = gen.meta;
const preset = gen.preset;
const serial = gen.serial;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
//const alloc_fn = @import("./alloc_fn.zig");
pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const show_expressions: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
    .AddressSpace = AddressSpace,
});
const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .logging = preset.address_space.logging.silent,
    .errors = preset.address_space.errors.noexcept,
    .options = .{},
});
const Array = Allocator.StructuredVector(u8);
const Fn = ctn_fn.Fn;
const Expr = expr.Expr;

fn writeFunctionBody(allocator: *Allocator, array: *Array, ctn_detail: *const attr.Container, ctn_fn_info: Fn) void {
    if (Expr.debug.show_expressions) {
        Expr.debug.showFunction(ctn_fn_info);
    }
    const child_size: [:0]const u8 = if (ctn_detail.layout == .structured) tok.child_size_name else tok.call_sizeof_child;
    const unit: Expr = if (ctn_detail.layout == .structured) expr.constant(1) else expr.symbol(tok.amount_unit);
    var define: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.define));
    var undefine: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefine));
    var seek: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.seek));
    var tell: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.tell));
    var writable_byte_count: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.writable_byte_count));
    var defined_byte_count: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.defined_byte_count));
    var undefined_byte_count: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefined_byte_count));
    var streamed_byte_count: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.streamed_byte_count));
    var unstreamed_byte_count: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.unstreamed_byte_count));
    var aligned_byte_address: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.aligned_byte_address));
    var undefined_byte_address: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.undefined_byte_address));
    var unstreamed_byte_address: [3]Expr = makeImplFnMemberCall(allocator, ctn_detail, impl_fn.get(.unstreamed_byte_address));
    var readable_byte_count: [3]Expr = if (ctn_detail.modes.resize) defined_byte_count else writable_byte_count;
    var amount_of_type_to_bytes: [3]Expr = expr.amountOfTypeToBytes(expr.symbol(tok.offset_name), expr.symbol(tok.child_type_name));
    var amount_to_count_of_type: [3]Expr = expr.amountToCountOfType(expr.symbol(tok.offset_name), expr.symbol(tok.child_type_name));
    var mul_sub_address_offset: [4]Expr = expr.mulSub(expr.symbol(tok.offset_name), expr.symbol(child_size), undefined);
    var mul_add_address_offset: [4]Expr = expr.mulAdd(expr.symbol(tok.offset_name), expr.symbol(child_size), undefined);
    var mul_sub_address_count: [4]Expr = expr.mulSub(expr.symbol(tok.count_name), expr.symbol(child_size), undefined);
    var mul_sub_address_one: [3]Expr = expr.sub(undefined, expr.symbol(child_size));
    var sub_address_amount_of_type_to_bytes: [3]Expr = expr.sub(undefined, expr.call(&amount_of_type_to_bytes));
    var add_address_amount_of_type_to_bytes: [3]Expr = expr.add(undefined, expr.call(&amount_of_type_to_bytes));
    var mul_offset_child_size: [3]Expr = expr.mul(expr.symbol(tok.offset_name), expr.symbol(child_size));
    var mul_count_child_size: [3]Expr = expr.mul(expr.symbol(tok.count_name), expr.symbol(child_size));
    const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
    const __undefined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__undefined));
    const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
    const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
    const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
    const __len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__len));
    const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
    const write_one_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeOne));
    const write_count_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeCount));
    const write_many_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeMany));
    const write_format_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFormat));
    const write_args_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeArgs));
    const write_fields_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFields));
    const write_any_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeAny));
    const mul_sub_address_offset_exprs: []Expr = &if (ctn_detail.layout == .structured) mul_sub_address_offset else sub_address_amount_of_type_to_bytes;
    const mul_add_address_offset_exprs: []Expr = &if (ctn_detail.layout == .structured) mul_add_address_offset else add_address_amount_of_type_to_bytes;
    const mul_sub_address_offset_address: *Expr = &if (ctn_detail.layout == .structured) mul_sub_address_offset[3] else sub_address_amount_of_type_to_bytes[1];
    const mul_add_address_offset_address: *Expr = &if (ctn_detail.layout == .structured) mul_add_address_offset[3] else add_address_amount_of_type_to_bytes[1];
    const mul_sub_address_count_address: *Expr = &mul_sub_address_count[3];
    const sub_address_one_address: *Expr = &mul_sub_address_one[1];
    const is_offset: bool = ctn_fn.kind.offset(ctn_fn_info);
    const is_defined: bool = ctn_fn.kind.defined(ctn_fn_info);
    switch (ctn_fn_info) {
        .readAll => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            var pointer_many: [4]Expr = expr.interfacePointerMany(expr.symbol(tok.child_type_name), expr.join(&aligned_byte_address), len_call);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expr);
        },
        .readAllWithSentinel => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                expr.join(&aligned_byte_address),
                len_call,
                expr.symbol(tok.sentinel_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .readOneDefined,
        .readOneOffsetDefined,
        .readOneStreamed,
        .readOneOffsetStreamed,
        => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_one),
            );
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            sub_address_one_address.* = if (is_defined)
                expr.join(&undefined_byte_address)
            else
                expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_one_deref));
            return array.writeMany(tok.end_expr);
        },
        .referOneDefined,
        .referOneOffsetDefined,
        .referOneStreamed,
        .referOneOffsetStreamed,
        => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_one),
            );
            sub_address_one_address.* = if (is_defined)
                expr.join(&undefined_byte_address)
            else
                expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expr);
        },
        .readCountDefined,
        .readCountOffsetDefined,
        .readCountStreamed,
        .readCountOffsetStreamed,
        => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
            );
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));

            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            mul_sub_address_count_address.* = expr.join(&undefined_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_deref));
            return array.writeMany(tok.end_expr);
        },
        //.referCountStreamed,
        //.referCountOffsetStreamed,
        .referCountDefined,
        .referCountOffsetDefined,
        => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
            );
            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expr);
        },
        .readCountWithSentinelStreamed,
        .readCountWithSentinelOffsetStreamed,
        .readCountWithSentinelDefined,
        .readCountWithSentinelOffsetDefined,
        => {
            var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            var deref_pointer_count_with_sentinel: [2]Expr = expr.dereference(expr.call(&pointer_count_with_sentinel));
            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&deref_pointer_count_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .referCountWithSentinelStreamed,
        .referCountWithSentinelOffsetStreamed,
        .referCountWithSentinelDefined,
        .referCountWithSentinelOffsetDefined,
        => {
            var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .readManyStreamed,
        .referManyStreamed,
        .readManyOffsetStreamed,
        .referManyOffsetStreamed,
        .readManyDefined,
        .referManyDefined,
        .readManyOffsetDefined,
        .referManyOffsetDefined,
        => {
            var pointer_many: [4]Expr = expr.interfacePointerMany(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
            );
            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expr);
        },
        .readManyWithSentinelDefined,
        .referManyWithSentinelDefined,
        .readManyWithSentinelOffsetDefined,
        .referManyWithSentinelOffsetDefined,
        .readManyWithSentinelStreamed,
        .referManyWithSentinelStreamed,
        .readManyWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        => {
            var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                if (is_offset) (if (is_defined) __defined_call else __streamed_call) else expr.call(&mul_sub_address_count),
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            mul_sub_address_count_address.* = if (is_defined) expr.join(&undefined_byte_address) else expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .readOneAt => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(expr.symbol(tok.child_type_name), __at_call);
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_one_deref));
            return array.writeMany(tok.end_expr);
        },
        .referOneAt => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(expr.symbol(tok.child_type_name), __at_call);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expr);
        },
        .readCountAt => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(expr.symbol(tok.child_type_name), __at_call, expr.symbol(tok.count_name));
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_deref));
            return array.writeMany(tok.end_expr);
        },
        .referCountAt => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(expr.symbol(tok.child_type_name), __at_call, expr.symbol(tok.count_name));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expr);
        },
        .readCountWithSentinelAt => {
            var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                __at_call,
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            var pointer_count_with_sentinel_deref: [2]Expr = expr.dereference(expr.call(&pointer_count_with_sentinel));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_with_sentinel_deref));
            return array.writeMany(tok.end_expr);
        },
        .referCountWithSentinelAt => {
            var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                __at_call,
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .readManyAt, .referManyAt => {
            var pointer_many: [4]Expr = expr.interfacePointerMany(
                expr.symbol(tok.child_type_name),
                __at_call,
                if (config.user_defined_length) expr.symbol(tok.count_name) else __len_call,
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expr);
        },
        .readManyWithSentinelAt,
        .referManyWithSentinelAt,
        => {
            var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                __at_call,
                if (config.user_defined_length) expr.symbol(tok.count_name) else __len_call,
                expr.symbol(tok.sentinel_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .readOneUnstreamed,
        .readOneOffsetUnstreamed,
        => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(
                expr.symbol(tok.child_type_name),
                if (is_offset) __unstreamed_call else expr.join(&unstreamed_byte_address),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expr);
        },
        .readCountUnstreamed,
        .readCountOffsetUnstreamed,
        => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(
                expr.symbol(tok.child_type_name),
                if (is_offset) __unstreamed_call else expr.join(&unstreamed_byte_address),
                expr.symbol(tok.count_name),
            );
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_deref));
            return array.writeMany(tok.end_expr);
        },
        .readCountWithSentinelUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        => {
            var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                if (is_offset) __unstreamed_call else expr.join(&unstreamed_byte_address),
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            var pointer_count_with_sentinel_deref: [2]Expr = expr.dereference(expr.call(&pointer_count_with_sentinel));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_with_sentinel_deref));
            return array.writeMany(tok.end_expr);
        },
        .readManyUnstreamed,
        .readManyOffsetUnstreamed,
        .referManyUnstreamed,
        .referManyOffsetUnstreamed,
        => {
            var pointer_many: [4]Expr = expr.interfacePointerMany(
                expr.symbol(tok.child_type_name),
                if (is_offset) __unstreamed_call else expr.join(&unstreamed_byte_address),
                expr.symbol(tok.count_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expr);
        },
        .readManyWithSentinelUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        .referManyWithSentinelUnstreamed,
        .referManyWithSentinelOffsetUnstreamed,
        => {
            var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
                expr.symbol(tok.child_type_name),
                if (is_offset) __unstreamed_call else expr.join(&unstreamed_byte_address),
                expr.symbol(tok.count_name),
                expr.symbol(tok.sentinel_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expr);
        },
        .overwriteOneAt => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(expr.symbol(tok.child_type_name), __at_call);
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            var pointer_one_deref_assign_value: [4]Expr = expr.assign(expr.join(&pointer_one_deref), expr.symbol(tok.value_name));
            return array.writeFormat(expr.join(&pointer_one_deref_assign_value));
        },
        .overwriteCountAt => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(expr.symbol(tok.child_type_name), __at_call, expr.symbol(tok.count_name));
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            var pointer_count_deref_assign_values: [4]Expr = expr.assign(expr.join(&pointer_count_deref), expr.symbol(tok.count_values_name));
            return array.writeFormat(expr.join(&pointer_count_deref_assign_values));
        },
        .overwriteManyAt => {
            var write_many: [4]Expr = expr.fnCall3(
                tok.write_many_impl_fn_name,
                expr.symbol(tok.child_type_name),
                __at_call,
                expr.symbol(tok.many_values_name),
            );
            array.writeFormat(expr.call(&write_many));
            return array.writeMany(tok.end_expr);
        },
        .overwriteOneDefined,
        .overwriteOneOffsetDefined,
        => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(
                expr.symbol(tok.child_type_name),
                if (is_offset) __defined_call else expr.join(&undefined_byte_address),
            );
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            var pointer_one_deref_assign_value: [4]Expr = expr.assign(expr.join(&pointer_one_deref), expr.symbol(tok.value_name));
            return array.writeFormat(expr.join(&pointer_one_deref_assign_value));
        },
        .overwriteCountDefined,
        .overwriteCountOffsetDefined,
        => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(
                expr.symbol(tok.child_type_name),
                if (is_offset) __defined_call else expr.join(&undefined_byte_address),
                expr.symbol(tok.count_name),
            );
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            var pointer_count_deref_assign_values: [4]Expr = expr.assign(
                expr.join(&pointer_count_deref),
                expr.symbol(tok.count_values_name),
            );
            return array.writeFormat(expr.join(&pointer_count_deref_assign_values));
        },
        .overwriteManyDefined,
        .overwriteManyOffsetDefined,
        => {
            var add_values_len_offset: [3]Expr = expr.add(expr.symbol(tok.many_values_len), expr.symbol(tok.offset_name));
            var write_many: [4]Expr = expr.fnCall3(
                tok.write_many_impl_fn_name,
                expr.symbol(tok.child_type_name),
                __defined_call,
                expr.symbol(tok.many_values_name),
            );
            expr.subst(__defined_call.args(), .{
                .dst = expr.symbol(tok.offset_name),
                .src = if (is_offset) expr.call(&add_values_len_offset) else expr.symbol(tok.many_values_len),
            });
            array.writeFormat(expr.call(&write_many));
            return array.writeMany(tok.end_expr);
        },
        .referOneUndefined,
        .referOneOffsetUndefined,
        => {
            var pointer_one: [3]Expr = expr.interfacePointerOne(
                expr.symbol(tok.child_type_name),
                if (is_offset) __undefined_call else expr.join(&undefined_byte_address),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expr);
        },
        .referCountUndefined,
        .referCountOffsetUndefined,
        => {
            var pointer_count: [4]Expr = expr.interfacePointerCount(
                expr.symbol(tok.child_type_name),
                if (is_offset) __undefined_call else expr.join(&undefined_byte_address),
                expr.symbol(tok.count_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expr);
        },
        .referManyUndefined,
        .referManyOffsetUndefined,
        => {
            var pointer_many: [4]Expr = expr.interfacePointerMany(
                expr.symbol(tok.child_type_name),
                if (is_offset) __undefined_call else expr.join(&undefined_byte_address),
                expr.symbol(tok.count_name),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expr);
        },
        .appendOne => {
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = unit });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_one_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendCount => {
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.symbol(tok.count_name) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_count_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendMany => {
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.symbol(tok.many_values_len) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_many_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendFormat => {
            var length_format: [3]Expr = expr.fnCall2(
                tok.length_format_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.format_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_format) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendArgs => {
            var length_args: [4]Expr = expr.fnCall3(
                tok.length_args_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.args_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_args) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendFields => {
            var length_fields: [4]Expr = expr.fnCall3(
                tok.length_fields_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.fields_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_fields) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .appendAny => {
            var length_any: [4]Expr = expr.fnCall3(
                tok.length_any_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.any_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_any) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expr);
            array.writeFormat(write_any_intr_call);
            return array.writeMany(tok.end_expr);
        },
        .writeOne => {
            if (config.implement_write_inline) {
                var pointer_one: [3]Expr = expr.interfacePointerOne(
                    expr.symbol(tok.child_type_name),
                    expr.join(&undefined_byte_address),
                );
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                var pointer_one_deref_assign_value: [4]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                return array.writeFormat(expr.join(&pointer_one_deref_assign_value));
            } else {
                var write_one: [4]Expr = expr.fnCall3(
                    tok.write_one_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.call(&write_one));
                return array.writeMany(tok.end_expr);
            }
        },
        .writeCount => {
            if (config.implement_write_inline) {
                var add_undefined_byte_address_loop_index: [3]Expr = expr.add(
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.loop_index_name),
                );
                var pointer_one: [3]Expr = expr.interfacePointerOne(
                    expr.symbol(tok.child_type_name),
                    expr.call(&add_undefined_byte_address_loop_index),
                );
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                var pointer_one_deref_assign_value: [4]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.ForLoop{
                    .expr1 = expr.symbol(tok.count_values_name),
                    .symbol1 = tok.value_name,
                    .symbol2 = tok.loop_index_name,
                });
                return array.writeFormat(expr.join(&pointer_one_deref_assign_value));
            } else {
                var write_count: [5]Expr = expr.fnCall4(
                    tok.write_count_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.symbol(tok.count_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.count_values_name),
                );
                array.writeFormat(expr.call(&write_count));
                return array.writeMany(tok.end_expr);
            }
        },
        .writeMany => {
            if (config.implement_write_inline) {
                var add_undefined_byte_address_loop_index: [3]Expr = expr.add(
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.loop_index_name),
                );
                var pointer_one: [3]Expr = expr.interfacePointerOne(
                    expr.symbol(tok.child_type_name),
                    expr.call(&add_undefined_byte_address_loop_index),
                );
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                var pointer_one_deref_assign_value: [4]Expr = expr.assign(
                    expr.join(&pointer_one_deref),
                    expr.symbol(tok.value_name),
                );
                array.writeFormat(expr.ForLoop{
                    .expr1 = expr.symbol(tok.many_values_name),
                    .symbol1 = tok.value_name,
                    .symbol2 = tok.loop_index_name,
                });
                return array.writeFormat(expr.join(&pointer_one_deref_assign_value));
            } else {
                var write_many: [4]Expr = expr.fnCall3(
                    tok.write_many_impl_fn_name,
                    expr.symbol(tok.child_type_name),
                    expr.join(&undefined_byte_address),
                    expr.symbol(tok.many_values_name),
                );
                array.writeFormat(expr.call(&write_many));
                return array.writeMany(tok.end_expr);
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
            return array.writeMany(tok.end_expr);
        },
        .writeArgs => {
            var write_args: [5]Expr = expr.fnCall4(
                if (ctn_detail.layout == .structured)
                    tok.write_args_structured_fn_name
                else
                    tok.write_args_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.args_name),
            );
            array.writeFormat(expr.call(&write_args));
            return array.writeMany(tok.end_expr);
        },
        .writeFields => {
            var write_fields: [5]Expr = expr.fnCall4(
                if (ctn_detail.layout == .structured)
                    tok.write_fields_structured_fn_name
                else
                    tok.write_fields_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.fields_name),
            );
            array.writeFormat(expr.call(&write_fields));
            return array.writeMany(tok.end_expr);
        },
        .writeAny => {
            var write_any: [5]Expr = expr.fnCall4(
                if (ctn_detail.layout == .structured)
                    tok.write_any_structured_fn_name
                else
                    tok.write_any_unstructured_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.array_name),
                expr.symbol(tok.any_name),
            );
            array.writeFormat(expr.call(&write_any));
            return array.writeMany(tok.end_expr);
        },
        // return count of defined of type
        .len => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&readable_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expr);
        },
        // return count of streamed of type
        .index => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&streamed_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expr);
        },
        // return count of undefined of type
        .avail => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&undefined_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expr);
        },
        // return count of unstreamed of type
        .ahead => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&unstreamed_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expr);
        },

        // return count of defined of type subtract amount of type
        .__len => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            var sub_len_offset: [3]Expr = expr.sub(len_call, if (ctn_detail.layout == .structured)
                expr.call(&mul_offset_child_size)
            else
                expr.call(&amount_to_count_of_type));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_len_offset));
            return array.writeMany(tok.end_expr);
        },

        // return aligned address offset above amount of type
        .__at => {
            mul_add_address_offset_address.* = expr.join(&aligned_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(mul_add_address_offset_exprs));
            return array.writeMany(tok.end_expr);
        },
        .__unstreamed => {
            mul_add_address_offset_address.* = expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(mul_add_address_offset_exprs));
            return array.writeMany(tok.end_expr);
        },
        // return undefined address offset above amount of type
        .__undefined => {
            mul_add_address_offset_address.* = expr.join(&undefined_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(mul_add_address_offset_exprs));
            return array.writeMany(tok.end_expr);
        },
        // return count of undefined of type  subtract amount of type
        .__avail => {
            const avail_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            array.writeMany(tok.return_keyword);
            var sub_avail_offset: [3]Expr = expr.sub(avail_call, expr.symbol(tok.offset_name));
            array.writeFormat(expr.call(&sub_avail_offset));
            return array.writeMany(tok.end_expr);
        },
        // return undefined address offset below amount of type
        .__defined => {
            mul_sub_address_offset_address.* = expr.join(&undefined_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(mul_sub_address_offset_exprs));
            return array.writeMany(tok.end_expr);
        },
        // return unstreamed address subtract amount of type
        .__streamed => {
            mul_sub_address_offset_address.* = expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(mul_sub_address_offset_exprs));
            return array.writeMany(tok.end_expr);
        },
        .define => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(define[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layout == .structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&define));
            return array.writeMany(tok.end_expr);
        },
        .defineAll => {
            expr.subst(define[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&undefined_byte_count),
            });
            array.writeFormat(expr.join(&define));
            return array.writeMany(tok.end_expr);
        },
        .undefine => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(undefine[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layout == .structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&undefine));
            return array.writeMany(tok.end_expr);
        },
        .undefineAll => {
            expr.subst(undefine[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&defined_byte_count),
            });
            array.writeFormat(expr.join(&undefine));
            return array.writeMany(tok.end_expr);
        },
        .stream => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(seek[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layout == .structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&seek));
            return array.writeMany(tok.end_expr);
        },
        .streamAll => {
            expr.subst(seek[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&unstreamed_byte_count),
            });
            array.writeFormat(expr.join(&seek));
            return array.writeMany(tok.end_expr);
        },
        .unstream => {
            amount_of_type_to_bytes[1] = expr.symbol(tok.amount_name);
            expr.subst(tell[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.call(&if (ctn_detail.layout == .structured)
                    mul_count_child_size
                else
                    amount_of_type_to_bytes),
            });
            array.writeFormat(expr.join(&tell));
            return array.writeMany(tok.end_expr);
        },
        .unstreamAll => {
            expr.subst(tell[2].args(), .{
                .dst = expr.symbol(tok.offset_bytes_name),
                .src = expr.join(&streamed_byte_count),
            });
            array.writeFormat(expr.join(&tell));
            return array.writeMany(tok.end_expr);
        },
        .init,
        .deinit,
        .grow,
        .shrink,
        .increment,
        .decrement,
        .holder,
        .static,
        .dynamic,
        => {
            const arg_list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
            for (arg_list.readAll()) |param_name| {
                var discard_paramm: [3]Expr = expr.discard(expr.symbol(param_name));
                array.writeFormat(expr.join(&discard_paramm));
            }
            if (arg_list.len == 0) {
                var discard_this: [3]Expr = expr.discard(expr.symbol(tok.call_this));
                array.writeFormat(expr.join(&discard_this));
            }
        },
    }
}
fn makeImplFnMemberCall(allocator: *Allocator, ctn_detail: *const attr.Container, impl_fn_info: *const impl_fn.Fn) [3]Expr {
    // Using array_impl in expr.impl would be better.
    return expr.fieldAccess(
        expr.symbol(tok.array_name),
        expr.impl(allocator, ctn_detail, impl_fn_info),
    );
}

fn functionBodyUndefinedNotice(ctn_detail: *const attr.Container, ctn_fn_info: Fn) void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    array.writeMany("function body undefined: ");
    array.writeMany(ctn_fn_info.fnName());
    array.writeOne(' ');
    ctn_detail.formatWrite(&array);
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}

fn writeFunctions(allocator: *Allocator, array: *Array, ctn_detail: *const attr.Container) void {
    for (ctn_fn.key) |ctn_fn_info| {
        if (!ctn_fn_info.hasCapability(ctn_detail)) {
            continue;
        }
        const len_0: u64 = array.len();
        writeSignature(array, ctn_fn_info, ctn_detail);
        array.writeMany("{\n");
        const len_1: u64 = array.len();
        writeFunctionBody(allocator, array, ctn_detail, ctn_fn_info);
        const len_2: u64 = array.len();
        if (len_1 == len_2) {
            functionBodyUndefinedNotice(ctn_detail, ctn_fn_info);
            array.undefine(len_1 - len_0);
        } else {
            array.writeMany("}\n");
        }
    }
}
fn writeSignature(array: anytype, ctn_fn_info: Fn, ctn_detail: *const attr.Container) void {
    const list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Parameter);
    if (ctn_fn.kind.helper(ctn_fn_info)) {
        array.writeMany("fn ");
    } else {
        array.writeMany("pub fn ");
    }
    array.writeMany(ctn_fn_info.fnName());
    array.writeMany("(");
    for (list.readAll()) |arg| gen.writeArgument(array, arg);
    array.writeMany(") ");
    array.writeMany(list.ret);
}

fn writeDeclarations(allocator: *Allocator, array: *Array, ctn_detail: *const attr.Container) void {
    const save: Allocator.Save = allocator.save();
    defer allocator.restore(save);
    const const_decl: *expr.ConstDecl = allocator.duplicateIrreversible(expr.ConstDecl, .{
        .val_name = tok.array_type_name,
        .type_name = tok.type_type_name,
        .expr1 = expr.symbol(tok.call_this),
    });
    array.writeFormat(const_decl.*);
    if (ctn_detail.layout == .structured) {
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
    if (ctn_detail.kind == .dynamic or
        ctn_detail.kind == .parametric or
        ctn_detail.kind == .static)
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
fn writeTypeFunction(allocator: *Allocator, array: *Array, ctn_detail: *const attr.Container) void {
    array.writeMany("pub fn ");
    ctn_detail.formatWrite(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ":");
    ctn_detail.formatWrite(array);
    array.writeMany("Spec)type{\nreturn(struct{\n");
    array.writeMany(tok.impl_field);
    array.writeMany(tok.end_elem);
    writeDeclarations(allocator, array, ctn_detail);
    writeFunctions(allocator, array, ctn_detail);
    array.writeMany("});\n}\n");
}
pub fn generateContainers() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    const details: []attr.Container = try serial.deserialize([]attr.Container, &allocator, gen.auxiliaryFile("ctn_detail"));

    var ctn_index: u64 = 0;
    while (ctn_index != details.len) : (ctn_index +%= 1) {
        const save: Allocator.Save = allocator.save();
        defer allocator.restore(save);

        writeTypeFunction(&allocator, &array, &details[ctn_index]);
    }
    gen.appendSourceFile(gen.primaryFile("containers.zig"), array.readAll());
}
pub const main = generateContainers;
