const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const detail = @import("./detail.zig");

pub const key = blk: {
    var res: []const Fn = &.{};
    for (@typeInfo(Fn).Enum.fields) |field| {
        res = res ++ [1]Fn{@intToEnum(Fn, field.value)};
    }
    break :blk res;
};
pub inline fn get(comptime tag: Fn) *const Fn {
    return &key[@enumToInt(tag)];
}
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
    pub inline fn fnName(impl_fn_info: *const Fn) [:0]const u8 {
        return @tagName(impl_fn_info.*);
    }
    pub fn hasCapability(fn_info: *const Fn, impl_variant: *const detail.More) bool {
        const is_always_aligned: bool =
            impl_variant.techs.auto_alignment or
            impl_variant.techs.unit_alignment;
        switch (fn_info.*) {
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
                return !impl_variant.kinds.static and
                    !impl_variant.kinds.parametric and
                    !impl_variant.kinds.automatic;
            },
            .move, .reallocate => {
                return !impl_variant.kinds.automatic and
                    !impl_variant.kinds.parametric;
            },
            .allocate => {
                return !impl_variant.kinds.automatic;
            },
            else => {
                return true;
            },
        }
    }
    pub fn argList(impl_fn_info: *const Fn, impl_variant: *const detail.More, list_kind: gen.ListKind) gen.ArgList {
        var arg_list: gen.ArgList = .{
            .args = undefined,
            .len = 0,
            .kind = list_kind,
            .ret = impl_fn_info.returnType(),
        };
        const has_static_maximum_length: bool =
            impl_variant.kinds.automatic or
            impl_variant.kinds.static;
        const has_dynamic_maximum_length: bool =
            !has_static_maximum_length;
        const has_active_alignment: bool =
            impl_variant.techs.disjunct_alignment or
            impl_variant.techs.lazy_alignment;
        const impl_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.impl_param,
            .Argument => tok.impl_name,
        };
        const offset_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.offset_bytes_param,
            .Argument => tok.offset_bytes_name,
        };
        const impl_const_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.impl_const_param,
            .Argument => tok.impl_name,
        };
        const slave_const_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.slave_specifier_const_ptr_param,
            .Argument => tok.slave_specifier_name,
        };
        const allocated_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_allocated_byte_address_param;
                } else {
                    break :blk tok.target_allocated_byte_address_param;
                }
            },
            .Argument => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_allocated_byte_address_name;
                } else {
                    break :blk tok.target_allocated_byte_address_name;
                }
            },
        };
        const aligned_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_aligned_byte_address_param;
                } else {
                    break :blk tok.target_aligned_byte_address_param;
                }
            },
            .Argument => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_aligned_byte_address_name;
                } else {
                    break :blk tok.target_aligned_byte_address_name;
                }
            },
        };
        const unallocated_byte_address_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_unallocated_byte_address_param;
                } else {
                    break :blk tok.target_unallocated_byte_address_param;
                }
            },
            .Argument => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_unallocated_byte_address_name;
                } else {
                    break :blk tok.target_unallocated_byte_address_name;
                }
            },
        };
        const single_approximation_counts_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_single_approximation_counts_param;
                } else {
                    break :blk tok.target_single_approximation_counts_param;
                }
            },
            .Argument => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_single_approximation_counts_name;
                } else {
                    break :blk tok.target_single_approximation_counts_name;
                }
            },
        };
        const double_approximation_counts_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_double_approximation_counts_param;
                } else {
                    break :blk tok.target_double_approximation_counts_param;
                }
            },
            .Argument => blk: {
                if (impl_fn_info.* == .allocate) {
                    break :blk tok.source_double_approximation_counts_name;
                } else {
                    break :blk tok.target_double_approximation_counts_name;
                }
            },
        };
        switch (impl_fn_info.*) {
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
                if (impl_variant.kinds.parametric) {
                    arg_list.writeOne(slave_const_symbol);
                }
            },
            .writable_byte_count,
            .aligned_byte_count,
            => {
                if (impl_variant.kinds.parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else if (has_dynamic_maximum_length) {
                    arg_list.writeOne(impl_const_symbol);
                }
            },
            .allocated_byte_count => {
                if (impl_variant.kinds.parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else if (has_static_maximum_length) {
                    if (has_active_alignment) {
                        arg_list.writeOne(impl_const_symbol);
                    }
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
                if (impl_variant.kinds.parametric) {
                    arg_list.writeOne(slave_const_symbol);
                } else {
                    arg_list.writeOne(impl_const_symbol);
                }
            },
            .resize => {
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
            },
            .allocate, .move, .reallocate => {
                if (impl_fn_info.* != .allocate) {
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
            },
            .deallocate => {
                arg_list.writeOne(impl_symbol);
            },
        }
        return arg_list;
    }
    pub fn returnType(impl_fn_info: *const Fn) [:0]const u8 {
        switch (impl_fn_info.*) {
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
    pub fn writeSignature(impl_fn_info: *const Fn, array: anytype, impl_detail: *const detail.More) void {
        const list: gen.ArgList = impl_fn_info.argList(impl_detail, .Parameter);
        array.writeMany("pub inline fn ");
        array.writeMany(impl_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") ");
        array.writeMany(list.ret);
    }
};
