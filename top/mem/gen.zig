pub const attr = @import("gen/attr.zig");
pub const types = @import("gen/types.zig");
pub const config = @import("gen/config.zig");

const Value = enum {
    source_impl_type,
    target_impl_type,
    source_impl,
    target_impl,
    source_impl_ptr,
    target_impl_ptr,
    input_amount,
    source_amount,
    option_amount,
    extra_amount,
    target_amount,
    input_bytes,
    source_bytes,
    option_bytes,
    offset_bytes,
    target_bytes,
    input_count,
    source_count,
    option_count,
    offset_count,
    target_count,
    input_aligned_bytes,
    source_aligned_bytes,
    option_aligned_bytes,
    offset_aligned_bytes,
    target_aligned_bytes,
    source_allocated_byte_address,
    target_allocated_byte_address,
    source_unstreamed_byte_address,
    target_unstreamed_byte_address,
    source_aligned_byte_address,
    target_aligned_byte_address,
    source_undefined_byte_address,
    target_undefined_byte_address,
    source_unallocated_byte_address,
    target_unallocated_byte_address,
    source_single_approximation_counts,
    source_double_approximation_counts,
    target_single_approximation_counts,
    target_double_approximation_counts,
    interface_source_allocated_byte_address,
    interface_target_allocated_byte_address,
    interface_source_unstreamed_byte_address,
    interface_target_unstreamed_byte_address,
    interface_source_aligned_byte_address,
    interface_target_aligned_byte_address,
    interface_source_undefined_byte_address,
    interface_target_undefined_byte_address,
    interface_source_unallocated_byte_address,
    interface_target_unallocated_byte_address,
    interface_source_single_approximation_counts,
    interface_source_double_approximation_counts,
    interface_target_single_approximation_counts,
    interface_target_double_approximation_counts,
};

pub const ListKind = enum {
    Parameter,
    Argument,
};

pub const ArgList = struct {
    args: [16][:0]const u8,
    args_len: u8,
    kind: ListKind,
    ret: [:0]const u8,

    pub fn writeOne(arg_list: *ArgList, symbol: [:0]const u8) void {
        arg_list.args[arg_list.args_len] = symbol;
        arg_list.args_len +%= 1;
    }
    pub fn readAll(arg_list: *const ArgList) []const [:0]const u8 {
        return arg_list.args[0..arg_list.args_len];
    }
};
pub const DeclList = struct {
    decls: [24][:0]const u8,
    decls_len: u8,
    pub fn writeOne(decl_list: *DeclList, symbol: [:0]const u8) void {
        decl_list.decls[decl_list.decls_len] = symbol;
        decl_list.decls_len +%= 1;
    }
    pub fn readAll(decl_list: *const DeclList) []const [:0]const u8 {
        return decl_list.decls[0..decl_list.decls_len];
    }
    pub fn haveElse(
        decl_list: *const DeclList,
        symbol1: [:0]const u8,
        symbol2: [:0]const u8,
    ) [:0]const u8 {
        if (decl_list.have(symbol1)) {
            return symbol1;
        } else {
            return symbol2;
        }
    }
    pub fn have(decl_list: *const DeclList, symbol: [:0]const u8) bool {
        for (decl_list.readAll()) |decl| {
            if (decl.ptr == symbol.ptr) {
                return true;
            }
        }
        return false;
    }
};
