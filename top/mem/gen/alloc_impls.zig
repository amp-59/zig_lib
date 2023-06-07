const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const spec = gen.spec;
const builtin = gen.builtin;

const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const types = @import("./types.zig");
const ptr_fn = @import("./ptr_fn.zig");
const alloc_fn = @import("./alloc_fn.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const show_expressions: bool = false;

fn writeFunctionBody(allocator: *types.Allocator, array: *types.Array, impl_variant: *const types.Container, alloc_fn_info: alloc_fn.Fn) void {
    _ = allocator;
    const ptr_fn_info: ptr_fn.Fn = blk: {
        if (alloc_fn_info == .allocate) {
            break :blk ptr_fn.Fn.allocate;
        }
        if (alloc_fn_info == .reallocate) {
            break :blk ptr_fn.Fn.reallocate;
        }
        break :blk ptr_fn.Fn.resize;
    };
    const arg_list: gen.ArgList = ptr_fn_info.argList(impl_variant, .Argument);
    var decl_list: gen.DeclList = undefined;
    decl_list.len = 0;

    for (arg_list.readAll()) |arg| {
        if (arg.ptr == tok.source_allocated_byte_address_name.ptr) {
            continue;
        }
        if (arg.ptr == tok.source_aligned_bytes_name.ptr) {
            if (decl_list.have(tok.option_amount_name)) {}
            if (decl_list.have(tok.source_single_approximation_counts_name)) {
                if (decl_list.have(tok.source_double_approximation_counts_name)) {
                    var partial_unpack_double: [3]expr.Expr = expr.unpck2x05(
                        expr.symbol(tok.option_aligned_bytes_name),
                        expr.symbol(tok.source_double_approximation_counts_name),
                    );
                    if (decl_list.have(tok.input_count_name)) {
                        var mul_count_partial_unpack_double: [3]expr.Expr = expr.mul(
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
                    var partial_unpack_single: [2]expr.Expr = expr.unpck1x05(
                        expr.symbol(tok.source_single_approximation_counts_name),
                    );
                    if (decl_list.have(tok.input_count_name)) {
                        var mul_count_partial_unpack_single: [3]expr.Expr = expr.mul(
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
            var amount_reserved_bytes: [3]expr.Expr = expr.amountReservedToBytes(
                expr.symbol(tok.input_amount_name),
                expr.symbol(tok.source_impl_type_name),
            );
            var aligna_amount_reserved_bytes: [3]expr.Expr = expr.alignA(expr.call(&amount_reserved_bytes), expr.constant(8));
            var partial_pack_single: [2]expr.Expr = expr.pck1x05(expr.call(&aligna_amount_reserved_bytes));
            array.writeFormat(expr.call(&partial_pack_single));
            array.writeMany(tok.end_expr);
            continue;
        }
        if (arg.ptr == tok.source_double_approximation_counts_name.ptr) {
            var partial_unpack_single: [2]expr.Expr = expr.unpck1x05(
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
    }
}
pub fn main() void {}
