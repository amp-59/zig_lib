const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = @import("./detail_more.zig");

// zig fmt: off
pub const key: [18]Fn = .{
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
    .define,
    .undefine,
    .seek,
    .tell,
};
// zig fmt: on
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
    pub inline fn fnName(impl_fn_info: *const Fn) [:0]const u8 {
        return @tagName(impl_fn_info.*);
    }
    pub fn hasCapability(fn_info: *const Fn, impl_variant: *const out.DetailMore) bool {
        switch (fn_info.*) {
            .alignment => return !(impl_variant.kinds.automatic or impl_variant.techs.unit_alignment),
            .define,
            .undefine,
            .undefined_byte_address,
            .defined_byte_count,
            .undefined_byte_count,
            => return impl_variant.modes.resize,
            .seek,
            .tell,
            .unstreamed_byte_address,
            .streamed_byte_count,
            .unstreamed_byte_count,
            => return impl_variant.modes.stream,
            else => return true,
        }
    }
    pub fn argList(impl_fn_info: *const Fn, impl_variant: *const out.DetailMore, list_kind: gen.ListKind) gen.ArgList {
        var array: gen.ArgList = undefined;
        array.undefineAll();
        const has_static_maximum_length: bool =
            impl_variant.kinds.automatic or
            impl_variant.kinds.static;
        const has_dynamic_maximum_length: bool =
            !has_static_maximum_length;
        const has_active_alignment: bool =
            impl_variant.techs.disjunct_alignment or
            impl_variant.techs.lazy_alignment;
        switch (impl_fn_info.*) {
            .define, .undefine, .seek, .tell => {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_param,
                    .Argument => tok.impl_name,
                });
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.offset_bytes_param,
                    .Argument => tok.offset_bytes_name,
                });
            },
            .unstreamed_byte_count => {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_const_param,
                    .Argument => tok.impl_name,
                });
            },
            .undefined_byte_address,
            .unstreamed_byte_address,
            => {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_const_param,
                    .Argument => tok.impl_name,
                });
            },
            .undefined_byte_count,
            .defined_byte_count,
            .streamed_byte_count,
            => {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_const_param,
                    .Argument => tok.impl_name,
                });
                if (impl_variant.kinds.parametric) {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.slave_specifier_const_ptr_param,
                        .Argument => tok.slave_specifier_name,
                    });
                }
            },
            .writable_byte_count,
            .aligned_byte_count,
            => {
                if (impl_variant.kinds.parametric) {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.slave_specifier_const_ptr_param,
                        .Argument => tok.slave_specifier_name,
                    });
                } else if (has_dynamic_maximum_length) {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.impl_const_param,
                        .Argument => tok.impl_name,
                    });
                }
            },
            .allocated_byte_count => {
                if (impl_variant.kinds.parametric) {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.slave_specifier_const_ptr_param,
                        .Argument => tok.slave_specifier_name,
                    });
                } else if (has_static_maximum_length) {
                    if (has_active_alignment) {
                        array.writeOne(switch (list_kind) {
                            .Parameter => tok.impl_const_param,
                            .Argument => tok.impl_name,
                        });
                    }
                } else {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.impl_const_param,
                        .Argument => tok.impl_name,
                    });
                }
            },
            else => {
                if (impl_variant.kinds.parametric) {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.slave_specifier_const_ptr_param,
                        .Argument => tok.slave_specifier_name,
                    });
                } else {
                    array.writeOne(switch (list_kind) {
                        .Parameter => tok.impl_const_param,
                        .Argument => tok.impl_name,
                    });
                }
            },
        }
        return array;
    }
    pub fn writeCall(impl_fn_info: *const Fn, array: *gen.String, impl_detail: *const out.DetailMore) void {
        const list: gen.ArgList = impl_fn_info.argList(impl_detail, .Argument);
        array.writeMany(impl_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(")");
    }
    pub fn writeSignature(impl_fn_info: *const Fn, array: *gen.String, impl_detail: *const out.DetailMore) void {
        const list: gen.ArgList = impl_fn_info.argList(impl_detail, .Parameter);
        array.writeMany("pub inline fn ");
        array.writeMany(impl_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") u64 ");
    }
};
