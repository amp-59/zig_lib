const mem = @import("../../mem.zig");
const fmt = @import("../../fmt.zig");
const gen = @import("../../gen.zig");
const proc = @import("../../proc.zig");
const file = @import("../../file.zig");
const meta = @import("../../meta.zig");
const spec = @import("../../spec.zig");
const debug = @import("../../debug.zig");
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
pub usingnamespace @import("../../start.zig");
pub const runtime_assertions: bool = false;
const Allocator = config.Allocator;
const AddressSpace = Allocator.AddressSpace;
const Array = Allocator.StructuredVector(u8);
const Details = Allocator.StructuredVector(types.Implementation);
const read_impl_spec: file.ReadSpec = .{
    .child = types.Implementation,
    .errors = .{},
    .return_type = void,
};
const ImplArgListPair = struct {
    impl_detail: types.Implementation,
    arg_list: gen.ArgList,
};
fn BinaryFilter(comptime T: type) type {
    return config.Allocator.allocate_payload(BinaryFilterPayload(T));
}
fn BinaryFilterPayload(comptime T: type) type {
    return struct { []const T, []const T };
}
fn haveField(allocator: *config.Allocator, impl_set: []const ImplArgListPair, f_field: [:0]const u8) BinaryFilter(ImplArgListPair) {
    @setRuntimeSafety(false);
    var t: []ImplArgListPair = try meta.wrap(
        allocator.allocate(ImplArgListPair, impl_set.len),
    );
    var t_len: u64 = 0;
    var f: []ImplArgListPair = try meta.wrap(
        allocator.allocate(ImplArgListPair, impl_set.len),
    );
    var f_len: u64 = 0;
    for (impl_set) |pair| {
        for (pair.arg_list.readAll()) |arg| {
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
    array: *Array,
    param_lists_map: *const ptr_fn.FnArgs.Map,
    alloc_fn_info: alloc_fn.Fn,
    impl_arg_list_pair: ImplArgListPair,
    decl_list: *gen.DeclList,
) config.Allocator.allocate_void {
    const ptr_fn_info: ptr_fn.Fn = alloc_fn_info.convert();
    if (param_lists_map.lookup(impl_arg_list_pair.impl_detail, ptr_fn_info)) |_| {
        const args: []const [:0]const u8 = impl_arg_list_pair.arg_list.readAll();
        for (args) |arg| {
            writeDeclExpr(array, alloc_fn_info, impl_arg_list_pair, arg, decl_list);
        }
        array.writeMany("const ret: s_impl_type = s_impl_type.");
        array.writeMany(alloc_fn_info.convert().fnName());
        array.writeMany("(.{");
        for (args) |arg| {
            if (!ptr_fn.isPtrSymbol(arg)) {
                array.writeMany(".");
                array.writeMany(arg);
                array.writeMany("=");
                array.writeMany(arg);
                array.writeMany(",");
            }
        }
        if (args.len != 0 and !ptr_fn.isPtrSymbol(args[0])) {
            array.undefine(1);
        }
        array.writeMany("});\n");
        array.writeMany("return ret;\n");
        return;
    }
}
fn writeDeclCond(array: *Array, symbol: [:0]const u8) void {
    array.writeMany("if(@hasField(P, \"");
    array.writeMany(symbol);
    array.writeMany("\")){\n");
}
fn writeDeclExpr(
    array: *Array,
    alloc_fn_info: alloc_fn.Fn,
    impl_arg_list_pair: ImplArgListPair,
    symbol: [:0]const u8,
    decl_list: *gen.DeclList,
) void {
    if (decl_list.have(symbol)) {
        return;
    }
    const impl_variant: types.Implementation = impl_arg_list_pair.impl_detail;
    defer decl_list.writeOne(symbol);
    if (symbol.ptr == tok.source_allocated_byte_address_name.ptr) {
        var allocated_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.source_allocated_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.symbol(tok.slave_specifier_call_unallocated_byte_address),
        );
        return array.writeFormat(expr.join(&allocated_byte_address));
    }
    if (symbol.ptr == tok.target_allocated_byte_address_name.ptr) {
        var allocated_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.target_allocated_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.symbol(tok.slave_specifier_call_unallocated_byte_address),
        );
        return array.writeFormat(expr.join(&allocated_byte_address));
    }
    if (symbol.ptr == tok.source_aligned_byte_address_name.ptr) {
        writeDeclExpr(array, alloc_fn_info, impl_arg_list_pair, tok.source_allocated_byte_address_name, decl_list);
        var low_alignment: [3]expr.Expr = expr.fieldAccess(
            expr.symbol(tok.source_impl_type_name),
            expr.symbol(tok.low_alignment_name),
        );
        var aligna_allocated_byte_address: [3]expr.Expr = expr.alignA(
            expr.symbol(tok.source_allocated_byte_address_name),
            expr.join(&low_alignment),
        );
        var aligned_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.source_aligned_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.call(&aligna_allocated_byte_address),
        );
        return array.writeFormat(expr.join(&aligned_byte_address));
    }
    if (symbol.ptr == tok.target_aligned_byte_address_name.ptr) {
        writeDeclExpr(array, alloc_fn_info, impl_arg_list_pair, tok.target_allocated_byte_address_name, decl_list);
        var low_alignment: [3]expr.Expr = expr.fieldAccess(
            expr.symbol(tok.source_impl_type_name),
            expr.symbol(tok.low_alignment_name),
        );
        var aligna_allocated_byte_address: [3]expr.Expr = expr.alignA(
            expr.symbol(tok.target_allocated_byte_address_name),
            expr.join(&low_alignment),
        );
        var aligned_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.target_aligned_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.call(&aligna_allocated_byte_address),
        );
        return array.writeFormat(expr.join(&aligned_byte_address));
    }
    if (symbol.ptr == tok.source_unallocated_byte_address_name.ptr) {
        writeDeclExpr(array, alloc_fn_info, impl_arg_list_pair, tok.source_aligned_bytes_name, decl_list);
        var add_aligned_byte_address_aligned_bytes: [3]expr.Expr = expr.add(
            expr.symbol(decl_list.haveElse(tok.source_aligned_byte_address_name, tok.source_allocated_byte_address_name)),
            expr.symbol(tok.source_aligned_bytes_name),
        );
        var unallocated_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.source_unallocated_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.call(&add_aligned_byte_address_aligned_bytes),
        );
        return array.writeFormat(expr.join(&unallocated_byte_address));
    }
    if (symbol.ptr == tok.target_unallocated_byte_address_name.ptr) {
        writeDeclExpr(array, alloc_fn_info, impl_arg_list_pair, tok.target_aligned_bytes_name, decl_list);
        var add_aligned_byte_address_aligned_bytes: [3]expr.Expr = expr.add(
            expr.symbol(decl_list.haveElse(tok.target_aligned_byte_address_name, tok.target_allocated_byte_address_name)),
            expr.symbol(tok.target_aligned_bytes_name),
        );
        var unallocated_byte_address: [7]expr.Expr = expr.constDecl(
            expr.symbol(tok.target_unallocated_byte_address_name),
            expr.symbol(tok.word_type_name),
            expr.call(&add_aligned_byte_address_aligned_bytes),
        );
        return array.writeFormat(expr.join(&unallocated_byte_address));
    }
    if (symbol.ptr == tok.source_aligned_bytes_name.ptr) {
        if (decl_list.have(tok.source_amount_name)) {
            var amount_reserved_bytes: [3]expr.Expr = expr.amountReservedToBytesNs(
                expr.symbol(tok.source_amount_name),
                expr.symbol(tok.source_impl_type_name),
            );
            var aligned_bytes: [7]expr.Expr = expr.constDecl(
                expr.symbol(tok.source_aligned_bytes_name),
                expr.symbol(tok.word_type_name),
                expr.call(&amount_reserved_bytes),
            );
            array.writeFormat(expr.join(&aligned_bytes));
        }
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
                if (impl_variant.kind == .static) {} else {}
            } else {
                if (impl_variant.kind == .static) {} else {}
            }
        }
    }
    if (symbol.ptr == tok.source_single_approximation_counts_name.ptr) {
        var amount_reserved_bytes: [3]expr.Expr = expr.amountReservedToBytes(
            expr.symbol(tok.input_amount_name),
            expr.symbol(tok.source_impl_type_name),
        );
        var aligna_amount_reserved_bytes: [3]expr.Expr = expr.alignA(expr.call(&amount_reserved_bytes), expr.constant(8));
        var partial_pack_single: [2]expr.Expr = expr.pck1x05(expr.call(&aligna_amount_reserved_bytes));
        array.writeFormat(expr.call(&partial_pack_single));
        return array.writeMany(tok.end_expr);
    }
    if (symbol.ptr == tok.source_double_approximation_counts_name.ptr) {
        var partial_unpack_single: [2]expr.Expr = expr.unpck1x05(
            expr.symbol(tok.source_single_approximation_counts_name),
        );
        var partial_pack_double = expr.pck2x05(
            expr.symbol(tok.input_aligned_bytes_name),
            expr.call(&partial_unpack_single),
        );
        array.writeFormat(expr.call(&partial_pack_double));
        return array.writeMany(tok.end_expr);
    }
    if (symbol.ptr == tok.impl_name.ptr) {
        return;
    }
    if (symbol.ptr == tok.target_single_approximation_counts_name.ptr) {
        return;
    }
    if (symbol.ptr == tok.target_double_approximation_counts_name.ptr) {
        return;
    }
}

fn writeFieldDeductionInternal(
    allocator: *config.Allocator,
    array: *Array,
    param_lists_map: *const ptr_fn.FnArgs.Map,
    alloc_fn_info: alloc_fn.Fn,
    impl_arg_list_pairs: []const ImplArgListPair,
    arg_list: []const [:0]const u8,
    decl_list: *gen.DeclList,
) config.Allocator.allocate_void {
    @setRuntimeSafety(false);
    const filtered: BinaryFilterPayload(ImplArgListPair) = try meta.wrap(
        haveField(allocator, impl_arg_list_pairs, arg_list[0]),
    );
    if (filtered[1].len != 0) {
        var decls_len: u8 = decl_list.decls_len;
        defer decl_list.decls_len = decls_len;
        if (filtered[0].len != 0 and
            arg_list[0].ptr != tok.impl_name.ptr)
        {
            writeDeclCond(array, arg_list[0]);
            writeDeclExpr(array, alloc_fn_info, filtered[1][0], arg_list[0], decl_list);
        }
        if (filtered[1].len == 1) {
            try meta.wrap(
                writeImplementationDeduction(array, param_lists_map, alloc_fn_info, filtered[1][0], decl_list),
            );
        } else if (arg_list.len != 1) {
            try meta.wrap(
                writeFieldDeductionInternal(allocator, array, param_lists_map, alloc_fn_info, filtered[1], arg_list[1..], decl_list),
            );
        } else {
            writeImplementationDeduction(array, param_lists_map, alloc_fn_info, filtered[1][0], decl_list);
        }
    }
    if (filtered[0].len != 0) {
        if (arg_list[0].ptr != tok.impl_name.ptr and
            filtered[1].len != 0)
        {
            array.writeMany("}else{\n");
        }
        if (filtered[0].len == 1) {
            try meta.wrap(
                writeImplementationDeduction(array, param_lists_map, alloc_fn_info, filtered[0][0], decl_list),
            );
        } else if (arg_list.len != 1) {
            try meta.wrap(
                writeFieldDeductionInternal(allocator, array, param_lists_map, alloc_fn_info, filtered[0], arg_list[1..], decl_list),
            );
        } else {
            writeImplementationDeduction(array, param_lists_map, alloc_fn_info, filtered[0][0], decl_list);
        }
    }
    if (arg_list[0].ptr != tok.impl_name.ptr and
        filtered[0].len != 0 and
        filtered[1].len != 0)
    {
        array.writeMany("}\n");
    }
}
pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator, 1024 * 4096);
    array.writeMany("const mem = @import(\"../mem.zig\");\n");
    array.writeMany("const meta = @import(\"../meta.zig\");\n");
    array.writeMany("const mach = @import(\"../mach.zig\");\n");
    array.writeMany("const " ++ tok.allocator_type_name ++ " = struct {};\n");
    array.writeMany("const " ++ tok.amount_type_name ++ " = struct {};\n");
    var fd: u64 = file.open(spec.generic.noexcept, config.impl_detail_path);
    const st: file.Status = file.status(spec.generic.noexcept, fd);
    const details: []types.Implementation = allocator.allocate(
        types.Implementation,
        st.count(types.Implementation),
    );
    file.read(read_impl_spec, fd, details);
    file.close(spec.generic.noexcept, fd);
    var len: [types.Kind.list.len]u64 = .{0} ** types.Kind.list.len;
    const param_lists_map: ptr_fn.FnArgs.Map = ptr_fn.deduceUniqueInterfaceStructs(&allocator, details);
    for (types.Kind.list, 0..) |kind, kind_idx| {
        for (details) |impl_detail| {
            if (impl_detail.kind == kind) {
                len[kind_idx] +%= 1;
            }
        }
    }
    for (alloc_fn.list) |alloc_fn_info| {
        const ptr_fn_info: ptr_fn.Fn = alloc_fn_info.convert();
        for (types.Kind.list, 0..) |kind, kind_idx| {
            const save: Allocator.Save = allocator.save();
            defer allocator.restore(save);
            var impl_arg_list_pairs: []ImplArgListPair = allocator.allocate(ImplArgListPair, len[kind_idx]);
            var idx: u64 = 0;
            for (details) |impl_detail| {
                if (impl_detail.kind == kind) {
                    impl_arg_list_pairs[idx] = .{
                        .impl_detail = impl_detail,
                        .arg_list = ptr_fn_info.argList(impl_detail, .Argument),
                    };
                    idx +%= 1;
                }
            }
            var unique_arg_list: gen.ArgList = impl_arg_list_pairs[0].arg_list;
            for (impl_arg_list_pairs[1..]) |impl_arg_list_pair| {
                lo: for (impl_arg_list_pair.arg_list.readAll()) |arg| {
                    for (unique_arg_list.readAll()) |unique_arg| {
                        if (arg.ptr == unique_arg.ptr) {
                            continue :lo;
                        }
                    }
                    unique_arg_list.writeOne(arg);
                }
            }
            alloc_fn_info.writeSignature(&array, kind);
            var decl_list: gen.DeclList = alloc_fn_info.declList(kind);
            array.writeMany("{\n");
            array.writeMany("const P = meta.FnParam0(s_impl_type.");
            array.writeMany(@tagName(alloc_fn_info));
            array.writeMany(");\n");
            if (unique_arg_list.args_len != 0) {
                writeFieldDeductionInternal(&allocator, &array, &param_lists_map, alloc_fn_info, impl_arg_list_pairs, unique_arg_list.readAll(), &decl_list);
            }
            array.writeMany("}\n");
        }
    }
    if (!config.write_separate_source_files) {
        try gen.truncateFile(.{ .return_type = void }, config.allocator_file_path, array.readAll());
    }
}
