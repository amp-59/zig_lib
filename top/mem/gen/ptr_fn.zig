const gen = @import("../../gen.zig");
const meta = @import("../../meta.zig");
const builtin = @import("../../builtin.zig");
const testing = @import("../../testing.zig");

const tok = @import("./tok.zig");
const attr = @import("./attr.zig");
const types = @import("./types.zig");
const config = @import("./config.zig");

pub const list = meta.tagList(Fn);

pub const Fn = enum(u5) {
    allocated_byte_address = 0,
    aligned_byte_address = 1,
    unstreamed_byte_address = 2,
    undefined_byte_address = 3,
    unwritable_byte_address = 4,
    unallocated_byte_address = 5,
    allocated_byte_count = 6,
    aligned_byte_count = 7,
    streamed_byte_count = 8,
    unstreamed_byte_count = 9,
    writable_byte_count = 10,
    undefined_byte_count = 11,
    defined_byte_count = 12,
    alignment = 13,
    define = 14,
    undefine = 15,
    seek = 16,
    tell = 17,
    allocate = 18,
    resize = 19,
    move = 20,
    reallocate = 21,
    deallocate = 22,
    pub inline fn fnName(ptr_fn_info: Fn) [:0]const u8 {
        return @tagName(ptr_fn_info);
    }
    pub fn hasCapability(fn_info: Fn, impl_variant: types.Implementation) bool {
        const is_always_aligned: bool =
            impl_variant.techs.auto_alignment or
            impl_variant.techs.unit_alignment;
        switch (fn_info) {
            .define,
            .undefine,
            .undefined_byte_address,
            .defined_byte_count,
            .undefined_byte_count,
            => {
                return impl_variant.modes.resize;
            },
            .seek,
            .tell,
            .unstreamed_byte_address,
            .streamed_byte_count,
            .unstreamed_byte_count,
            => return {
                return impl_variant.modes.stream;
            },
            .alignment => {
                return !is_always_aligned;
            },
            .resize => {
                return !(impl_variant.kind == .static) and
                    !(impl_variant.kind == .parametric) and
                    !(impl_variant.kind == .automatic);
            },
            .move, .reallocate => {
                return !(impl_variant.kind == .automatic) and
                    !(impl_variant.kind == .parametric);
            },
            .allocate => {
                return !(impl_variant.kind == .automatic);
            },
            else => {
                return true;
            },
        }
    }
    pub fn argList(ptr_fn_info: Fn, impl_variant: types.Implementation, list_kind: gen.ListKind) gen.ArgList {
        const Variant = @TypeOf(impl_variant);
        var arg_list: gen.ArgList = .{
            .args = undefined,
            .len = 0,
            .kind = list_kind,
            .ret = ptr_fn_info.returnType(),
        };
        const has_static_maximum_length: bool =
            impl_variant.kind == .automatic or
            impl_variant.kind == .static;
        const has_dynamic_maximum_length: bool =
            !has_static_maximum_length;
        const impl_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.impl_param,
            .Argument => tok.impl_name,
        };
        const offset_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.offset_bytes_param,
            .Argument => tok.offset_bytes_name,
        };
        const impl_const_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.impl_const_param,
            .Argument => tok.impl_name,
        };
        const slave_const_symbol: [:0]const u8 = switch (list_kind) {
            else => tok.slave_specifier_const_ptr_param,
            .Argument => tok.slave_specifier_name,
        };
        const allocated_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            else => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_allocated_byte_address_param;
                } else {
                    break :blk tok.target_allocated_byte_address_param;
                }
            },
            .Argument => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_allocated_byte_address_name;
                } else {
                    break :blk tok.target_allocated_byte_address_name;
                }
            },
        };
        const aligned_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            else => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_aligned_byte_address_param;
                } else {
                    break :blk tok.target_aligned_byte_address_param;
                }
            },
            .Argument => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_aligned_byte_address_name;
                } else {
                    break :blk tok.target_aligned_byte_address_name;
                }
            },
        };
        const unallocated_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            else => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_unallocated_byte_address_param;
                } else {
                    break :blk tok.target_unallocated_byte_address_param;
                }
            },
            .Argument => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_unallocated_byte_address_name;
                } else {
                    break :blk tok.target_unallocated_byte_address_name;
                }
            },
        };
        const single_approximation_counts_symbol: [:0]const u8 = switch (list_kind) {
            else => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_single_approximation_counts_param;
                } else {
                    break :blk tok.target_single_approximation_counts_param;
                }
            },
            .Argument => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_single_approximation_counts_name;
                } else {
                    break :blk tok.target_single_approximation_counts_name;
                }
            },
        };
        const double_approximation_counts_symbol: [:0]const u8 = switch (list_kind) {
            else => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_double_approximation_counts_param;
                } else {
                    break :blk tok.target_double_approximation_counts_param;
                }
            },
            .Argument => blk: {
                if (ptr_fn_info == .allocate) {
                    break :blk tok.source_double_approximation_counts_name;
                } else {
                    break :blk tok.target_double_approximation_counts_name;
                }
            },
        };
        switch (ptr_fn_info) {
            .define, .undefine, .seek, .tell => {
                arg_list.writeOne(impl_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .unstreamed_byte_count => {
                arg_list.writeOne(impl_const_symbol);
            },
            .undefined_byte_address,
            .unstreamed_byte_address,
            => {
                arg_list.writeOne(impl_const_symbol);
            },
            .undefined_byte_count,
            .defined_byte_count,
            .streamed_byte_count,
            => {
                arg_list.writeOne(impl_const_symbol);
                if (impl_variant.kind == .parametric) {
                    arg_list.writeOne(slave_const_symbol);
                }
            },
            .writable_byte_count,
            .aligned_byte_count,
            => {
                if (impl_variant.kind == .parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else if (has_dynamic_maximum_length) {
                    arg_list.writeOne(impl_const_symbol);
                }
            },
            .allocated_byte_count => {
                if (impl_variant.kind == .parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else {
                    arg_list.writeOne(impl_const_symbol);
                }
            },
            .allocated_byte_address,
            .aligned_byte_address,
            .unwritable_byte_address,
            .unallocated_byte_address,
            .alignment,
            => {
                if (impl_variant.kind == .parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else {
                    arg_list.writeOne(impl_const_symbol);
                }
            },
            .resize => {
                if (Variant == types.Implementation) {
                    arg_list.writeOne(impl_symbol);
                    if (impl_variant.fields.unallocated_byte_address) {
                        arg_list.writeOne(unallocated_byte_address_symbol);
                    }
                    if (impl_variant.techs.single_packed_approximate_capacity) {
                        arg_list.writeOne(single_approximation_counts_symbol);
                    }
                    if (impl_variant.techs.double_packed_approximate_capacity) {
                        arg_list.writeOne(single_approximation_counts_symbol);
                        arg_list.writeOne(double_approximation_counts_symbol);
                    }
                }
            },
            .allocate, .move, .reallocate => {
                if (Variant == types.Implementation) {
                    if (ptr_fn_info != .allocate) {
                        arg_list.writeOne(impl_symbol);
                    }
                    if (impl_variant.fields.allocated_byte_address) {
                        arg_list.writeOne(allocated_byte_address_symbol);
                    }
                    if (impl_variant.fields.undefined_byte_address or
                        impl_variant.fields.unstreamed_byte_address or
                        impl_variant.techs.disjunct_alignment)
                    {
                        arg_list.writeOne(aligned_byte_address_symbol);
                    }
                    if (impl_variant.techs.single_packed_approximate_capacity) {
                        arg_list.writeOne(single_approximation_counts_symbol);
                    }
                    if (impl_variant.techs.double_packed_approximate_capacity) {
                        arg_list.writeOne(single_approximation_counts_symbol);
                        arg_list.writeOne(double_approximation_counts_symbol);
                    }
                    if (impl_variant.fields.unallocated_byte_address) {
                        arg_list.writeOne(unallocated_byte_address_symbol);
                    }
                }
            },
            .deallocate => {
                arg_list.writeOne(impl_symbol);
            },
        }
        return arg_list;
    }
    pub fn returnType(ptr_fn_info: Fn) [:0]const u8 {
        switch (ptr_fn_info) {
            .allocated_byte_address,
            .aligned_byte_address,
            .unstreamed_byte_address,
            .undefined_byte_address,
            .unwritable_byte_address,
            .unallocated_byte_address,
            .allocated_byte_count,
            .aligned_byte_count,
            .streamed_byte_count,
            .unstreamed_byte_count,
            .writable_byte_count,
            .undefined_byte_count,
            .defined_byte_count,
            .alignment,
            => {
                return tok.word_type_name;
            },
            .allocate => {
                return tok.impl_type_name;
            },
            .define,
            .undefine,
            .seek,
            .tell,
            .move,
            .reallocate,
            .resize,
            .deallocate,
            => {
                return tok.void_type_name;
            },
        }
    }
    pub fn writeSignature(ptr_fn_info: Fn, array: anytype, impl_detail: types.Implementation) void {
        const arg_list: gen.ArgList = ptr_fn_info.argList(impl_detail, .Parameter);
        array.writeMany("pub inline fn ");
        array.writeMany(ptr_fn_info.fnName());
        array.writeMany("(");
        const args: []const [:0]const u8 = arg_list.readAll();
        for (args) |arg| {
            array.writeMany(arg);
            array.writeMany(",");
        }
        if (args.len != 0) {
            array.undefine(1);
        }
        array.writeMany(")");
        array.writeMany(arg_list.ret);
    }
    pub fn interface(tag: Fn) bool {
        switch (tag) {
            .allocate,
            .deallocate,
            .reallocate,
            .move,
            .resize,
            => return true,
            else => return false,
        }
    }
};
pub const FnArgLists = struct {
    keys: []Key,
    keys_len: usize = 0,
    pub const Key = struct { Fn, usize };
    pub const Value = struct { Fn, []gen.ArgList };
};
pub const FnArgListMap = struct {
    []const FnArgLists.Value,
    []const FnArgLists,
};
pub fn deduceUniqueInterfaceStructs(allocator: *config.Allocator, impl_details: []types.Implementation) FnArgListMap {
    var key_len: usize = 0;
    for (list) |ptr_fn_info| {
        if (!ptr_fn_info.interface()) {
            continue;
        }
        key_len +%= 1;
    }
    const arg_list_vals: []FnArgLists.Value = allocator.allocate(FnArgLists.Value, key_len);
    const arg_list_maps: []FnArgLists = allocator.allocate(FnArgLists, impl_details.len);
    for (arg_list_maps) |*arg_list_map| {
        arg_list_map.keys = allocator.allocate(FnArgLists.Key, key_len);
        arg_list_map.keys_len = 0;
    }
    var key_idx: usize = 0;
    for (list) |ptr_fn_info| {
        if (!ptr_fn_info.interface()) {
            continue;
        }
        const arg_lists: []gen.ArgList = allocator.allocate(gen.ArgList, impl_details.len);
        var arg_lists_len: usize = 0;
        lo: for (impl_details, 0..) |impl_detail, impl_detail_idx| {
            if (!ptr_fn_info.hasCapability(impl_detail)) {
                continue :lo;
            }
            const arg_list_map: *FnArgLists = &arg_list_maps[impl_detail_idx];
            const arg_list: gen.ArgList = ptr_fn_info.argList(impl_detail, .Parameter);
            if (arg_list.len == 0) {
                continue :lo;
            }
            un: for (arg_lists[0..arg_lists_len], 0..) |unique_arg_list, unique_arg_list_idx| {
                if (unique_arg_list.len != arg_list.len) {
                    continue :un;
                }
                for (unique_arg_list.readAll(), arg_list.readAll()) |u, v| {
                    if (u.ptr != v.ptr) {
                        continue :un;
                    }
                }
                arg_list_map.keys[arg_list_map.keys_len] = .{
                    ptr_fn_info,
                    unique_arg_list_idx,
                };
                arg_list_map.keys_len +%= 1;
                continue :lo;
            }
            arg_list_map.keys[arg_list_map.keys_len] = .{ ptr_fn_info, arg_lists_len };
            arg_list_map.keys_len +%= 1;
            arg_lists[arg_lists_len] = arg_list;
            arg_lists_len +%= 1;
        }
        arg_list_vals[key_idx] = .{
            ptr_fn_info,
            arg_lists[0..arg_lists_len],
        };
        key_idx +%= 1;
    }
    return .{ arg_list_vals, arg_list_maps };
}
