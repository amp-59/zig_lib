const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const meta = @import("../../meta.zig");
const spec = @import("../../spec.zig");
const serial = @import("../../serial.zig");
const testing = @import("../../testing.zig");
const builtin = @import("../../builtin.zig");
const tok = @import("./tok.zig");
const expr = @import("./expr.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");
const ptr_fn = @import("./ptr_fn.zig");
const alloc_fn = @import("./alloc_fn.zig");
pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const show_expressions: bool = false;

const Allocator = config.Allocator;
const AddressSpace = Allocator.AddressSpace;
const Array = Allocator.StructuredVector(u8);
const Details = Allocator.StructuredVector(types.Implementation);
const read_impl_spec: file.ReadSpec = .{ .child = types.Implementation, .errors = .{}, .return_type = void };

fn writeFunctionBody(allocator: *Allocator, array: *Array, impl_variant: *const types.Implementation, alloc_fn_info: alloc_fn.Fn) void {
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
fn BinaryFilter(comptime T: type) type {
    return config.Allocator.allocate_payload(BinaryFilterPayload(T));
}
fn BinaryFilterPayload(comptime T: type) type {
    return struct { []const T, []const T };
}
fn haveField(allocator: *config.Allocator, impl_set: []const ArgListMap, f_field: [:0]const u8) BinaryFilter(ArgListMap) {
    @setRuntimeSafety(false);
    var t: []ArgListMap = try meta.wrap(
        allocator.allocate(ArgListMap, impl_set.len),
    );
    var t_len: u64 = 0;
    var f: []ArgListMap = try meta.wrap(
        allocator.allocate(ArgListMap, impl_set.len),
    );
    var f_len: u64 = 0;
    for (impl_set) |pair| {
        for (pair[1].readAll()) |arg| {
            if (f_field.ptr == arg.ptr) {
                t[t_len] = pair;
                t_len +%= 1;
                break;
            }
        } else {
            f[f_len] = pair;
            f_len +%= 1;
        }
    }
    return .{ f[0..f_len], t[0..t_len] };
}

fn writeImplementationDeduction(
    allocator: *config.Allocator,
    array: *Array,
    pair: ArgListMap,
) config.Allocator.allocate_void {
    _ = allocator;
    array.writeMany("// ");
    array.writeFormat(pair[0]);
    array.writeMany("\n");
}

fn writeDeclExpr(array: *Array, symbol: [:0]const u8) void {
    array.writeMany("if(@hasField(s_impl_type, \"");
    array.writeMany(symbol);
    array.writeMany("\")){\n");
}
fn writeFieldDeductionInternal(
    allocator: *config.Allocator,
    array: *Array,
    arg_list: []const [:0]const u8,
    impl_set: []const ArgListMap,
) config.Allocator.allocate_void {
    @setRuntimeSafety(false);
    const filtered: BinaryFilterPayload(ArgListMap) = try meta.wrap(
        haveField(allocator, impl_set, arg_list[0]),
    );
    if (filtered[1].len != 0) {
        writeDeclExpr(array, arg_list[0]);
        if (filtered[1].len == 1) {
            try meta.wrap(
                writeImplementationDeduction(allocator, array, filtered[1][0]),
            );
        } else if (arg_list.len != 1) {
            try meta.wrap(
                writeFieldDeductionInternal(allocator, array, arg_list[1..], filtered[1]),
            );
        } else {
            for (filtered[1]) |pair| {
                try meta.wrap(
                    writeImplementationDeduction(allocator, array, pair),
                );
            }
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("}else{\n");
        }
        if (filtered[0].len == 1) {
            try meta.wrap(
                writeImplementationDeduction(allocator, array, filtered[0][0]),
            );
        } else if (arg_list.len != 1) {
            try meta.wrap(
                writeFieldDeductionInternal(allocator, array, arg_list[1..], filtered[0]),
            );
        } else {
            for (filtered[0]) |pair| {
                try meta.wrap(
                    writeImplementationDeduction(allocator, array, pair),
                );
            }
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}

// Create limited set of fields for the kind

const ArgListMap = struct { types.Implementation, gen.ArgList };

pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    array.writeMany("comptime{\n");
    array.writeMany("const s_impl_type: type = u64;\n");
    var fd: u64 = file.open(spec.generic.noexcept, config.impl_detail_path);
    const st: file.Status = file.status(spec.generic.noexcept, fd);
    const details: []types.Implementation = allocator.allocate(
        types.Implementation,
        st.count(types.Implementation),
    );
    file.read(read_impl_spec, fd, details);
    file.close(spec.generic.noexcept, fd);
    var len: [types.Kind.list.len]u64 = .{0} ** types.Kind.list.len;
    for (types.Kind.list, 0..) |kind, kind_idx| {
        for (details) |impl_detail| {
            if (impl_detail.kind == kind) {
                len[kind_idx] +%= 1;
            }
        }
    }
    for (ptr_fn.list) |ptr_fn_info| {
        for (types.Kind.list, 0..) |kind, kind_idx| {
            const save: Allocator.Save = allocator.save();
            defer allocator.restore(save);
            var list_map: []ArgListMap = allocator.allocate(ArgListMap, len[kind_idx]);
            var idx: u64 = 0;
            for (details) |impl_detail| {
                if (impl_detail.kind == kind) {
                    list_map[idx] = .{ impl_detail, ptr_fn_info.argList(impl_detail, .Parameter) };
                    idx +%= 1;
                }
            }
            var arg_list: gen.ArgList = list_map[0][1];
            for (list_map[1..]) |pair| {
                lo: for (pair[1].readAll()) |arg| {
                    for (arg_list.readAll()) |unique_arg| {
                        if (arg.ptr == unique_arg.ptr) {
                            continue :lo;
                        }
                    }
                    arg_list.writeOne(arg);
                }
            }
            if (arg_list.len != 0) {
                writeFieldDeductionInternal(&allocator, &array, arg_list.readAll(), list_map);
            }
        }
    }
    array.writeMany("}");
    if (!config.write_separate_source_files) {
        try gen.truncateFile(.{ .return_type = void }, config.allocator_file_path, array.readAll());
    }
}
