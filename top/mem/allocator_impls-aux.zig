const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const attr = @import("./attr.zig");
const detail = @import("./detail.zig");
const impl_fn = @import("./impl_fn.zig");
const alloc_fn = @import("./alloc_fn.zig");

const out = @import("./zig-out/src/impl_variants.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const show_expressions: bool = false;

const Fn = alloc_fn.Fn;
const Expr = expr.Expr;

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

fn undefinedDeclarationNotice(arg: [:0]const u8) void {
    var buf: [1024]u8 = undefined;
    builtin.debug.logAlwaysAIO(&buf, &.{ "undefined declaration: ", arg, "\n" });
}

fn writeFunctionBody(allocator: *Allocator, array: *Array, impl_variant: *const detail.More, alloc_fn_info: Fn) void {
    _ = allocator;
    const impl_fn_info: impl_fn.Fn = blk: {
        if (alloc_fn_info == .allocate) {
            break :blk impl_fn.Fn.allocate;
        }
        if (alloc_fn_info == .reallocate) {
            break :blk impl_fn.Fn.reallocate;
        }
        break :blk impl_fn.Fn.resize;
    };
    const arg_list: gen.ArgList = impl_fn_info.argList(impl_variant, .Argument);
    var decl_list: gen.DeclList = undefined;
    decl_list.len = 0;

    for (arg_list.readAll()) |arg| {
        if (arg.ptr == tok.source_allocated_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.source_aligned_bytes_name.ptr) {
            if (decl_list.have(tok.option_amount_name)) {
                //try writeDeclaration(construct, allocator, array, .n_count, interface);
            }
            if (decl_list.have(tok.source_single_approximation_counts_name)) {
                if (decl_list.have(tok.source_double_approximation_counts_name)) {
                    var partial_unpack_double: [3]Expr = expr.unpck2x05(
                        expr.symbol(tok.option_aligned_bytes_name),
                        expr.symbol(tok.source_double_approximation_counts_name),
                    );
                    if (decl_list.have(tok.input_count_name)) {
                        var mul_count_partial_unpack_double: [3]Expr = expr.mul(
                            expr.symbol(tok.input_count_name),
                            expr.call(&partial_unpack_double),
                        );
                        array.writeFormat(expr.call(&mul_count_partial_unpack_double));
                        array.writeMany(tok.end_expr);
                    } else {
                        array.writeFormat(expr.call(&partial_unpack_double));
                        array.writeMany(tok.end_expr);
                    }
                } else {
                    var partial_unpack_single: [2]Expr = expr.unpck1x05(
                        expr.symbol(tok.source_single_approximation_counts_name),
                    );
                    if (decl_list.have(tok.input_count_name)) {
                        var mul_count_partial_unpack_single: [3]Expr = expr.mul(
                            expr.symbol(tok.input_count_name),
                            expr.call(&partial_unpack_single),
                        );
                        array.writeFormat(expr.call(&mul_count_partial_unpack_single));
                        array.writeMany(tok.end_expr);
                    } else {
                        array.writeFormat(expr.call(&partial_unpack_single));
                        array.writeMany(tok.end_expr);
                    }
                }
            } else {
                if (decl_list.have(tok.input_count_name)) {
                    if (impl_variant.kinds.static) {} else {}
                } else {
                    if (impl_variant.kinds.static) {} else {}
                }
            }
            decl_list.writeOne(tok.source_aligned_bytes_name);
            continue;
        }
        if (arg.ptr == tok.source_aligned_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.source_single_approximation_counts_name.ptr) {
            var amount_reserved_bytes: [3]Expr = expr.amountReservedToBytes(
                expr.symbol(tok.input_amount_name),
                expr.symbol(tok.source_impl_type_name),
            );
            var aligna_amount_reserved_bytes: [3]Expr = expr.alignA(expr.call(&amount_reserved_bytes), expr.constant(8));
            var partial_pack_single: [2]Expr = expr.pck1x05(expr.call(&aligna_amount_reserved_bytes));
            array.writeFormat(expr.call(&partial_pack_single));
            array.writeMany(tok.end_expr);
            continue;
        }
        if (arg.ptr == tok.source_double_approximation_counts_name.ptr) {
            var partial_unpack_single: [2]Expr = expr.unpck1x05(
                expr.symbol(tok.source_single_approximation_counts_name),
            );
            var partial_pack_double = expr.pck2x05(
                expr.symbol(tok.input_aligned_bytes_name),
                expr.call(&partial_unpack_single),
            );
            array.writeFormat(expr.call(&partial_pack_double));
            array.writeMany(tok.end_expr);
            continue;
        }
        if (arg.ptr == tok.source_unallocated_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.impl_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.target_single_approximation_counts_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.target_double_approximation_counts_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.target_unallocated_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.target_allocated_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.target_aligned_byte_address_name.ptr) {
            continue;
        }
        undefinedDeclarationNotice(arg);
    }
}
pub fn main() void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    for (attr.Kinds.tag_list) |kind| {
        const save_0: Allocator.Save = allocator.save();
        defer allocator.restore(save_0);
        const buf_0: []*const detail.More = allocator.allocateIrreversible(*const detail.More, out.impl_variants.len);
        var len_0: u64 = 0;
        for (out.impl_variants) |*impl_variant| {
            if (kind == impl_variant.kind()) {
                buf_0[len_0] = impl_variant;
                len_0 +%= 1;
            }
        }
        for (alloc_fn.key) |alloc_fn_info| {
            const save_1: Allocator.Save = allocator.save();
            defer allocator.restore(save_1);
            const buf_1: []*const detail.More = allocator.allocateIrreversible(*const detail.More, len_0);
            var len_1: u64 = 0;
            for (buf_0[0..len_0]) |impl_variant| {
                if (alloc_fn_info.hasCapability(impl_variant)) {
                    buf_1[len_1] = impl_variant;
                    len_1 +%= 1;
                }
            }
            for (buf_1[0..len_1]) |impl_variant| {
                writeFunctionBody(&allocator, &array, impl_variant, alloc_fn_info);
            }
        }
    }
    builtin.debug.write(array.readAll());
}
