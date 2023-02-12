const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = @import("./detail_more.zig");

// zig fmt: off
pub const key: [18]Fn = .{
    .{ .tag = .allocated_byte_address,      .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_address,        .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_address,     .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .undefined_byte_address,      .val = .Address,    .loc = .Relative, .mut = .Immutable },
    .{ .tag = .unwritable_byte_address,     .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .unallocated_byte_address,    .val = .Address,    .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .allocated_byte_count,        .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .aligned_byte_count,          .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .streamed_byte_count,         .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .unstreamed_byte_count,       .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .writable_byte_count,         .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .undefined_byte_count,        .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .defined_byte_count,          .val = .Offset,     .loc = .Relative, .mut = .Immutable },
    .{ .tag = .alignment,                   .val = .Offset,     .loc = .Absolute, .mut = .Immutable },
    .{ .tag = .define,                      .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .undefine,                    .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .seek,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
    .{ .tag = .tell,                        .val = .Offset,     .loc = .Relative, .mut = .Mutable },
};
// zig fmt: on
pub inline fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
        unreachable;
    }
}
pub const Fn = packed struct {
    tag: Tag,
    val: Value,
    loc: Location,
    mut: Mutability,
    pub const Tag = enum(u5) {
        allocated_byte_address,
        aligned_byte_address,
        unstreamed_byte_address,
        undefined_byte_address,
        unwritable_byte_address,
        unallocated_byte_address,
        allocated_byte_count,
        aligned_byte_count,
        streamed_byte_count,
        unstreamed_byte_count,
        writable_byte_count,
        undefined_byte_count,
        defined_byte_count,
        alignment,
        define,
        undefine,
        seek,
        tell,
    };
    pub const Value = enum(u1) { Address, Offset };
    pub const Location = enum(u1) { Relative, Absolute };
    pub const Mutability = enum(u1) { Mutable, Immutable };
    pub inline fn fnName(impl_fn_info: *const Fn) []const u8 {
        return @tagName(impl_fn_info.tag);
    }
    pub fn hasCapability(fn_info: *const Fn, impl_variant: *const out.DetailMore) bool {
        switch (fn_info.tag) {
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
    pub fn writeCall(ctn_fn_info: *const Fn, array: *gen.String, ctn_detail: *const out.DetailMore) void {
        const list: gen.ArgList = getArgList(ctn_detail, ctn_fn_info, .Argument);
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(")");
    }
    pub fn writeSignature(ctn_fn_info: *const Fn, array: *gen.String, ctn_detail: *const out.DetailMore) void {
        const list: gen.ArgList = getArgList(ctn_detail, ctn_fn_info, .Parameter);
        array.writeMany("pub inline fn ");
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") u64 ");
    }
};
pub fn getArgList(impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, list_kind: gen.ListKind) gen.ArgList {
    var array: gen.ArgList = undefined;
    array.undefineAll();
    const has_unit_alignment: bool =
        impl_variant.techs.auto_alignment or
        impl_variant.techs.unit_alignment;
    const criteria_full: bool =
        impl_fn_info.tag == .writable_byte_count or
        impl_fn_info.tag == .aligned_byte_count or
        impl_fn_info.tag == .allocated_byte_count and has_unit_alignment;
    if (impl_fn_info.mut == .Mutable) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.impl_param,
            .Argument => tok.impl_name,
        });
        array.writeOne(switch (list_kind) {
            .Parameter => tok.offset_bytes_param,
            .Argument => tok.offset_bytes_name,
        });
    } else //
    if (impl_variant.kinds.parametric) {
        if (impl_fn_info.val == .Address) {
            if (impl_fn_info.loc == .Absolute) {
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
        } else if (impl_fn_info.val == .Offset) {
            if (impl_fn_info.tag == .unstreamed_byte_count and
                impl_variant.fields.undefined_byte_address)
            {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_const_param,
                    .Argument => tok.impl_name,
                });
            } else if (impl_fn_info.loc == .Relative) {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.impl_const_param,
                    .Argument => tok.impl_name,
                });
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.slave_specifier_const_ptr_param,
                    .Argument => tok.slave_specifier_name,
                });
            } else {
                array.writeOne(switch (list_kind) {
                    .Parameter => tok.slave_specifier_const_ptr_param,
                    .Argument => tok.slave_specifier_name,
                });
            }
        }
    } else //
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        if (!criteria_full) {
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
    return array;
}
