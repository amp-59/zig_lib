const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const file = gen.file;
const mach = gen.mach;
const algo = gen.algo;
const proc = gen.proc;
const meta = gen.meta;
const preset = gen.preset;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const detail = @import("./detail.zig");
const config = @import("./config.zig");
const ctn_fn = @import("./ctn_fn.zig");
const impl_fn = @import("./impl_fn.zig");
//const alloc_fn = @import("./alloc_fn.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
const kind = @import("./zig-out/src/container_kinds.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const runtime_assertions: bool = false;

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

fn writeFunctionBody(allocator: *Allocator, array: *Array, ctn_detail: *const detail.Less, ctn_fn_info: Fn) void {
    if (Expr.debug.show_expressions) {
        Expr.debug.showFunction(ctn_fn_info);
    }
    const child_size: [:0]const u8 = if (ctn_detail.layouts.structured) tok.child_size_name else tok.call_sizeof_child;

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

    var pointer_one: [3]Expr = expr.interfacePointerOne(expr.symbol(tok.child_type_name), undefined);
    var pointer_many: [4]Expr = expr.interfacePointerMany(expr.symbol(tok.child_type_name), undefined, undefined);
    var pointer_many_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
        expr.symbol(tok.sentinel_name),
    );
    var pointer_count: [4]Expr = expr.interfacePointerCount(expr.symbol(tok.child_type_name), undefined, undefined);
    var pointer_count_with_sentinel: [5]Expr = expr.interfacePointerCountWithSentinel(
        expr.symbol(tok.child_type_name),
        undefined,
        undefined,
        expr.symbol(tok.sentinel_name),
    );

    var amount_of_type_to_bytes: [3]Expr = expr.amountOfTypeToBytes(expr.symbol(tok.offset_name), expr.symbol(tok.child_type_name));

    var mul_sub_address_offset: [4]Expr = expr.mulSub(expr.symbol(tok.offset_name), expr.symbol(child_size), undefined);
    var sub_address_amount_of_type_to_bytes: [3]Expr = expr.sub(undefined, expr.call(&amount_of_type_to_bytes));
    const address_sub_offset: []Expr = if (ctn_detail.layouts.structured) &mul_sub_address_offset else &sub_address_amount_of_type_to_bytes;
    const address_sub_offset_address: *Expr = if (ctn_detail.layouts.structured) &mul_sub_address_offset[3] else &sub_address_amount_of_type_to_bytes[1];

    var mul_add_address_offset: [4]Expr = expr.mulAdd(expr.symbol(tok.offset_name), expr.symbol(child_size), undefined);
    var add_address_amount_of_type_to_bytes: [3]Expr = expr.add(undefined, expr.call(&amount_of_type_to_bytes));
    const address_add_offset: []Expr = if (ctn_detail.layouts.structured) &mul_add_address_offset else &add_address_amount_of_type_to_bytes;
    const address_add_offset_address: *Expr = if (ctn_detail.layouts.structured) &mul_add_address_offset[3] else &add_address_amount_of_type_to_bytes[1];

    var mul_offset_child_size: [3]Expr = expr.mul(expr.symbol(tok.offset_name), expr.symbol(child_size));
    var mul_count_child_size: [3]Expr = expr.mul(expr.symbol(tok.count_name), expr.symbol(child_size));

    switch (ctn_fn_info) {
        .readAll,
        .referAllDefined,
        => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
            pointer_many_loc.* = expr.join(&aligned_byte_address);
            pointer_many_len.* = len_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .readAllWithSentinel,
        .referAllDefinedWithSentinel,
        => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = expr.join(&aligned_byte_address);
            pointer_many_with_sentinel_len.* = len_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneStreamed,
        .readOneOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = if (ctn_fn_info == .readOneStreamed) expr.join(&unstreamed_byte_address) else __streamed_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        // return an array of type with a given length ending at unstreamed
        .readCountStreamed,
        .readCountOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = if (ctn_fn_info == .readCountStreamed)
                expr.join(&unstreamed_byte_address)
            else
                __streamed_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .readCountWithSentinelStreamed,
        .readCountWithSentinelOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = if (ctn_fn_info == .readCountWithSentinelStreamed) expr.join(&unstreamed_byte_address) else __streamed_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelStreamed,
        .referCountWithSentinelOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = if (ctn_fn_info == .referCountWithSentinelStreamed) expr.join(&unstreamed_byte_address) else __streamed_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readManyStreamed,
        .readManyOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
            pointer_many_loc.* = if (ctn_fn_info == .readManyStreamed)
                expr.join(&unstreamed_byte_address)
            else
                __streamed_call;
            pointer_many_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .readManyWithSentinelStreamed,
        .referManyWithSentinelStreamed,
        .readManyWithSentinelOffsetStreamed,
        .referManyWithSentinelOffsetStreamed,
        => {
            const __streamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__streamed));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = if (ctn_fn_info == .readManyWithSentinelStreamed) expr.join(&unstreamed_byte_address) else __streamed_call;
            pointer_many_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = __at_call;
            var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_one_deref));
            return array.writeMany(tok.end_expression);
        },
        .referOneAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = __at_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .overwriteOneAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_one_loc: *Expr = &pointer_one[2];
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
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = __at_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            var pointer_count_deref: [2]Expr = expr.dereference(expr.call(&pointer_count));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_deref));
            return array.writeMany(tok.end_expression);
        },
        .referCountAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = __at_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .overwriteCountAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
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
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = __at_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            var pointer_count_with_sentinel_deref: [2]Expr = expr.dereference(expr.call(&pointer_count_with_sentinel));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.join(&pointer_count_with_sentinel_deref));
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = __at_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readManyAt, .referManyAt => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const __len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__len));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
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
        .overwriteManyAt => {},
        .readManyWithSentinelAt,
        .referManyWithSentinelAt,
        => {
            const __at_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__at));
            const __len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__len));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = __at_call;
            if (config.user_defined_length) {
                pointer_many_with_sentinel_len.* = expr.symbol(tok.count_name);
            } else {
                pointer_many_with_sentinel_len.* = __len_call;
            }
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneUnstreamed,
        .readOneOffsetUnstreamed,
        => {
            const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = if (ctn_fn_info == .readOneUnstreamed) expr.join(&unstreamed_byte_address) else __unstreamed_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .readCountUnstreamed,
        .readCountOffsetUnstreamed,
        => {
            const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = if (ctn_fn_info == .readCountUnstreamed) expr.join(&unstreamed_byte_address) else __unstreamed_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .readCountWithSentinelUnstreamed,
        .readCountWithSentinelOffsetUnstreamed,
        => {
            const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = if (ctn_fn_info == .readCountWithSentinelUnstreamed) expr.join(&unstreamed_byte_address) else __unstreamed_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readManyUnstreamed,
        .readManyOffsetUnstreamed,
        => {
            const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];

            pointer_many_loc.* = if (ctn_fn_info == .readManyUnstreamed) expr.join(&unstreamed_byte_address) else __unstreamed_call;
            pointer_many_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .readManyWithSentinelUnstreamed,
        .readManyWithSentinelOffsetUnstreamed,
        => {
            const __unstreamed_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__unstreamed));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = if (ctn_fn_info == .readManyWithSentinelUnstreamed) expr.join(&unstreamed_byte_address) else __unstreamed_call;
            pointer_many_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readOneDefined,
        .readOneOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = if (ctn_fn_info == .readOneDefined) expr.join(&undefined_byte_address) else __defined_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .referOneDefined,
        .referOneOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = if (ctn_fn_info == .referOneDefined) expr.join(&undefined_byte_address) else __defined_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .overwriteOneDefined,
        .overwriteOneOffsetDefined,
        => {},
        .readCountDefined,
        .readCountOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = if (ctn_fn_info == .readCountDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .referCountDefined,
        .referCountOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = if (ctn_fn_info == .referCountDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .overwriteCountDefined,
        .overwriteCountOffsetDefined,
        => {},
        .readCountWithSentinelDefined,
        .readCountWithSentinelOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = if (ctn_fn_info == .readCountWithSentinelDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .referCountWithSentinelDefined,
        .referCountWithSentinelOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_count_with_sentinel_loc: *Expr = &pointer_count_with_sentinel[2];
            const pointer_count_with_sentinel_len: *Expr = &pointer_count_with_sentinel[3];
            pointer_count_with_sentinel_loc.* = if (ctn_fn_info == .referCountWithSentinelDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_count_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .readManyDefined,
        .readManyOffsetDefined,
        .referManyDefined,
        .referManyOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
            pointer_many_loc.* = if (ctn_fn_info == .readManyDefined or
                ctn_fn_info == .referManyDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_many_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .overwriteManyDefined,
        .overwriteManyOffsetDefined,
        => {},
        .readManyWithSentinelDefined,
        .readManyWithSentinelOffsetDefined,
        .referManyWithSentinelDefined,
        .referManyWithSentinelOffsetDefined,
        => {
            const __defined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__defined));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = if (ctn_fn_info == .readManyWithSentinelDefined or
                ctn_fn_info == .referManyWithSentinelDefined) expr.join(&undefined_byte_address) else __defined_call;
            pointer_many_with_sentinel_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },
        .referAllUndefined => {
            const avail_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.avail));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
            pointer_many_loc.* = expr.join(&aligned_byte_address);
            pointer_many_len.* = avail_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .referAllUndefinedWithSentinel => {
            const avail_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.avail));
            const pointer_many_with_sentinel_loc: *Expr = &pointer_many_with_sentinel[2];
            const pointer_many_with_sentinel_len: *Expr = &pointer_many_with_sentinel[3];
            pointer_many_with_sentinel_loc.* = expr.join(&aligned_byte_address);
            pointer_many_with_sentinel_len.* = avail_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many_with_sentinel));
            return array.writeMany(tok.end_expression);
        },

        .referOneUndefined,
        .referOneOffsetUndefined,
        => {
            const __undefined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__undefined));
            const pointer_one_loc: *Expr = &pointer_one[2];
            pointer_one_loc.* = if (ctn_fn_info == .referOneUndefined) expr.join(&undefined_byte_address) else __undefined_call;
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_one));
            return array.writeMany(tok.end_expression);
        },
        .referCountUndefined,
        .referCountOffsetUndefined,
        => {
            const __undefined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__undefined));
            const pointer_count_loc: *Expr = &pointer_count[2];
            const pointer_count_len: *Expr = &pointer_count[3];
            pointer_count_loc.* = if (ctn_fn_info == .referCountUndefined) expr.join(&undefined_byte_address) else __undefined_call;
            pointer_count_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_count));
            return array.writeMany(tok.end_expression);
        },
        .referManyUndefined,
        .referManyOffsetUndefined,
        => {
            const __undefined_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.__undefined));
            const pointer_many_loc: *Expr = &pointer_many[2];
            const pointer_many_len: *Expr = &pointer_many[3];
            pointer_many_loc.* = if (ctn_fn_info == .referManyUndefined) expr.join(&undefined_byte_address) else __undefined_call;
            pointer_many_len.* = expr.symbol(tok.count_name);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&pointer_many));
            return array.writeMany(tok.end_expression);
        },
        .appendOne => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_one_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeOne));
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_one_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendCount => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_count_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeCount));
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.symbol(tok.count_name) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_count_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendMany => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_many_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeMany));
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.symbol(tok.many_values_len) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_many_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFormat => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_format_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFormat));
            var length_format: [3]Expr = expr.fnCall2(
                tok.length_format_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.format_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_format) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_format_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendArgs => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_args_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeArgs));
            var length_args: [4]Expr = expr.fnCall3(
                tok.length_args_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.args_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_args) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_args_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendFields => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_fields_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeFields));
            var length_fields: [4]Expr = expr.fnCall3(
                tok.length_fields_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.fields_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_fields) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_fields_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .appendAny => {
            const increment_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.increment));
            const write_any_intr_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.writeAny));
            var length_any: [4]Expr = expr.fnCall3(
                tok.length_any_fn_name,
                expr.symbol(tok.child_type_name),
                expr.symbol(tok.reinterpret_spec_name),
                expr.symbol(tok.any_name),
            );
            expr.subst(increment_call.args(), .{ .dst = expr.symbol(tok.offset_name), .src = expr.call(&length_any) });
            array.writeFormat(increment_call);
            array.writeMany(tok.end_expression);
            array.writeFormat(write_any_intr_call);
            return array.writeMany(tok.end_expression);
        },
        .writeOne => {
            if (config.implement_write_inline) {
                var pointer_one_deref: [2]Expr = expr.dereference(expr.call(&pointer_one));
                const pointer_one_loc: *Expr = &pointer_one[2];
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
                const pointer_one_loc: *Expr = &pointer_one[2];
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
                const pointer_one_loc: *Expr = &pointer_one[2];
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
                expr.join(&readable_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return count of streamed of type
        .index => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&streamed_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return count of undefined of type
        .avail => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&undefined_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },
        // return unstreamed address offset above amount of type

        // return count of unstreamed of type
        .ahead => {
            var div_count_size: [3]Expr = expr.divT(
                expr.join(&unstreamed_byte_count),
                expr.symbol(child_size),
            );
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&div_count_size));
            return array.writeMany(tok.end_expression);
        },

        // return count of defined of type subtract amount of type
        .__len => {
            const len_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            var sub_len_offset: [3]Expr = expr.sub(len_call, expr.call(&mul_offset_child_size));
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(&sub_len_offset));
            return array.writeMany(tok.end_expression);
        },

        // return aligned address offset above amount of type
        .__at => {
            address_add_offset_address.* = expr.join(&aligned_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(address_add_offset));
            return array.writeMany(tok.end_expression);
        },
        .__unstreamed => {
            address_add_offset_address.* = expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(address_add_offset));
            return array.writeMany(tok.end_expression);
        },
        // return undefined address offset above amount of type
        .__undefined => {
            address_add_offset_address.* = expr.join(&undefined_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(address_add_offset));
            return array.writeMany(tok.end_expression);
        },
        // return count of undefined of type  subtract amount of type
        .__avail => {
            const avail_call: Expr = expr.intr(allocator, ctn_detail, ctn_fn.get(.len));
            array.writeMany(tok.return_keyword);
            var sub_avail_offset: [3]Expr = expr.sub(avail_call, expr.symbol(tok.offset_name));
            array.writeFormat(expr.call(&sub_avail_offset));
            return array.writeMany(tok.end_expression);
        },
        // return undefined address offset below amount of type
        .__defined => {
            address_sub_offset_address.* = expr.join(&undefined_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(address_sub_offset));
            return array.writeMany(tok.end_expression);
        },
        // return unstreamed address subtract amount of type
        .__streamed => {
            address_sub_offset_address.* = expr.join(&unstreamed_byte_address);
            array.writeMany(tok.return_keyword);
            array.writeFormat(expr.call(address_sub_offset));
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
fn makeImplFnMemberCall(allocator: *Allocator, ctn_detail: *const detail.Less, impl_fn_info: *const impl_fn.Fn) [3]Expr {
    // Using array_impl in expr.impl would be better.
    return expr.fieldAccess(
        expr.symbol(tok.array_name),
        expr.impl(allocator, ctn_detail, impl_fn_info),
    );
}

fn functionBodyUndefinedNotice(ctn_detail: *const detail.Less, ctn_fn_info: *const Fn) void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    array.writeMany("function body undefined: ");
    array.writeMany(ctn_fn_info.fnName());
    array.writeOne(' ');
    ctn_detail.writeContainerName(&array);
    array.writeOne('\n');
    builtin.debug.write(array.readAll());
}
fn writeFunctions(allocator: *Allocator, array: *Array, ctn_detail: *const detail.Less) void {
    for (ctn_fn.key) |ctn_fn_info| {
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

fn writeDeclarations(allocator: *Allocator, array: *Array, ctn_detail: *const detail.Less) void {
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
inline fn writeTypeFunction(allocator: *Allocator, array: *Array, ctn_detail: *const detail.Less) void {
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
pub fn generateContainers() void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);

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
