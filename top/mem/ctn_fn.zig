const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = @import("./detail_less.zig");
const config = @import("./config.zig");
// zig fmt: off
pub const key: [87]Fn = .{
    .{ .tag = .defineAll,                       .kind = .set,                                       .loc = .AllDefined },
    .{ .tag = .undefineAll,                     .kind = .set,                                       .loc = .AllDefined },
    .{ .tag = .streamAll,                       .kind = .set,                                       .loc = .AllDefined },
    .{ .tag = .unstreamAll,                     .kind = .set,                                       .loc = .AllDefined },
    .{ .tag = .index,                           .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .len,                             .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .avail,                           .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .__at,                            .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .__ad,                            .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .__len,                           .kind = .get,                                       .loc = .AllDefined },
    .{ .tag = .__rem,                           .kind = .get,                                       .loc = .AllUndefined },
    .{ .tag = .readAll,                         .kind = .read,      .val = .Many,                   .loc = .AllDefined },
    .{ .tag = .referAllDefined,                 .kind = .refer,     .val = .Many,                   .loc = .AllDefined },
    .{ .tag = .readAllWithSentinel,             .kind = .read,      .val = .ManyWithSentinel,       .loc = .AllDefined },
    .{ .tag = .referAllDefinedWithSentinel,     .kind = .refer,     .val = .ManyWithSentinel,       .loc = .AllDefined },
    .{ .tag = .__behind,                        .kind = .get,                                       .loc = .Behind },
    .{ .tag = .unstream,                        .kind = .set,                                       .loc = .Behind },
    .{ .tag = .readOneBehind,                   .kind = .read,      .val = .One,                    .loc = .Behind },
    .{ .tag = .readCountBehind,                 .kind = .read,      .val = .Count,                  .loc = .Behind },
    .{ .tag = .readCountWithSentinelBehind,     .kind = .read,      .val = .CountWithSentinel,      .loc = .Behind },
    .{ .tag = .referCountWithSentinelBehind,    .kind = .refer,     .val = .CountWithSentinel,      .loc = .Behind },
    .{ .tag = .readManyBehind,                  .kind = .read,      .val = .Many,                   .loc = .Behind },
    .{ .tag = .readManyWithSentinelBehind,      .kind = .read,      .val = .ManyWithSentinel,       .loc = .Behind },
    .{ .tag = .referManyWithSentinelBehind,     .kind = .refer,     .val = .ManyWithSentinel,       .loc = .Behind },
    .{ .tag = .readOneAt,                       .kind = .read,      .val = .One,                    .loc = .AnyDefined },
    .{ .tag = .referOneAt,                      .kind = .refer,     .val = .One,                    .loc = .AnyDefined },
    .{ .tag = .overwriteOneAt,                  .kind = .write,     .val = .One,                    .loc = .AnyDefined },
    .{ .tag = .readCountAt,                     .kind = .read,      .val = .Count,                  .loc = .AnyDefined },
    .{ .tag = .referCountAt,                    .kind = .refer,     .val = .Count,                  .loc = .AnyDefined },
    .{ .tag = .overwriteCountAt,                .kind = .write,     .val = .Count,                  .loc = .AnyDefined },
    .{ .tag = .readCountWithSentinelAt,         .kind = .read,      .val = .CountWithSentinel,      .loc = .AnyDefined },
    .{ .tag = .referCountWithSentinelAt,        .kind = .refer,     .val = .CountWithSentinel,      .loc = .AnyDefined },
    .{ .tag = .readManyAt,                      .kind = .read,      .val = .Many,                   .loc = .AnyDefined },
    .{ .tag = .referManyAt,                     .kind = .refer,     .val = .Many,                   .loc = .AnyDefined },
    .{ .tag = .overwriteManyAt,                 .kind = .write,     .val = .Many,                   .loc = .AnyDefined },
    .{ .tag = .readManyWithSentinelAt,          .kind = .read,      .val = .ManyWithSentinel,       .loc = .AnyDefined },
    .{ .tag = .referManyWithSentinelAt,         .kind = .refer,     .val = .ManyWithSentinel,       .loc = .AnyDefined },
    .{ .tag = .stream,                          .kind = .set,                                       .loc = .Ahead },
    .{ .tag = .readOneAhead,                    .kind = .read,      .val = .One,                    .loc = .Ahead },
    .{ .tag = .readCountAhead,                  .kind = .read,      .val = .Count,                  .loc = .Ahead },
    .{ .tag = .readCountWithSentinelAhead,      .kind = .read,      .val = .CountWithSentinel,      .loc = .Ahead },
    .{ .tag = .readManyAhead,                   .kind = .read,      .val = .Many,                   .loc = .Ahead },
    .{ .tag = .readManyWithSentinelAhead,       .kind = .read,      .val = .ManyWithSentinel,       .loc = .Ahead },
    .{ .tag = .__back,                          .kind = .get,                                       .loc = .Back },
    .{ .tag = .undefine,                        .kind = .set,                                       .loc = .Back },
    .{ .tag = .readOneBack,                     .kind = .read,      .val = .One,                    .loc = .Back },
    .{ .tag = .referOneBack,                    .kind = .refer,     .val = .One,                    .loc = .Back },
    .{ .tag = .overwriteOneBack,                .kind = .write,     .val = .One,                    .loc = .Back },
    .{ .tag = .readCountBack,                   .kind = .read,      .val = .Count,                  .loc = .Back },
    .{ .tag = .referCountBack,                  .kind = .refer,     .val = .Count,                  .loc = .Back },
    .{ .tag = .overwriteCountBack,              .kind = .write,     .val = .Count,                  .loc = .Back },
    .{ .tag = .readCountWithSentinelBack,       .kind = .read,      .val = .CountWithSentinel,      .loc = .Back },
    .{ .tag = .referCountWithSentinelBack,      .kind = .refer,     .val = .CountWithSentinel,      .loc = .Back },
    .{ .tag = .readManyBack,                    .kind = .read,      .val = .Many,                   .loc = .Back },
    .{ .tag = .referManyBack,                   .kind = .refer,     .val = .Many,                   .loc = .Back },
    .{ .tag = .overwriteManyBack,               .kind = .write,     .val = .Many,                   .loc = .Back },
    .{ .tag = .readManyWithSentinelBack,        .kind = .read,      .val = .ManyWithSentinel,       .loc = .Back },
    .{ .tag = .referManyWithSentinelBack,       .kind = .refer,     .val = .ManyWithSentinel,       .loc = .Back },
    .{ .tag = .referAllUndefined,               .kind = .refer,     .val = .Many,                   .loc = .AllUndefined },
    .{ .tag = .referAllUndefinedWithSentinel,   .kind = .refer,     .val = .ManyWithSentinel,       .loc = .AllUndefined },
    .{ .tag = .define,                          .kind = .set,                                       .loc = .Next },
    .{ .tag = .referOneUndefined,               .kind = .refer,     .val = .One,                    .loc = .Next },
    .{ .tag = .writeOne,                        .kind = .write,     .val = .One,                    .loc = .Next },
    .{ .tag = .referCountUndefined,             .kind = .refer,     .val = .Count,                  .loc = .Next },
    .{ .tag = .writeCount,                      .kind = .write,     .val = .Count,                  .loc = .Next },
    .{ .tag = .referManyUndefined,              .kind = .refer,     .val = .Many,                   .loc = .Next },
    .{ .tag = .writeMany,                       .kind = .write,     .val = .Many,                   .loc = .Next },
    .{ .tag = .writeFields,                     .kind = .write,     .val = .Fields,                 .loc = .Next },
    .{ .tag = .writeArgs,                       .kind = .write,     .val = .Args,                   .loc = .Next },
    .{ .tag = .writeFormat,                     .kind = .write,     .val = .Format,                 .loc = .Next },
    .{ .tag = .writeAny,                        .kind = .write,     .val = .Any,                    .loc = .Next },
    .{ .tag = .static,                          .kind = .transform,                                 .err = .Wrap },
    .{ .tag = .dynamic,                         .kind = .transform,                                 .err = .Wrap },
    .{ .tag = .holder,                          .kind = .transform,                                 .err = .Wrap },
    .{ .tag = .init,                            .kind = .allocate,                                  .err = .Wrap },
    .{ .tag = .grow,                            .kind = .reallocate,                                .err = .Wrap },
    .{ .tag = .deinit,                          .kind = .deallocate,                                .err = .Wrap },
    .{ .tag = .shrink,                          .kind = .reallocate,                .loc = .AllUndefined,   .err = .Wrap },
    .{ .tag = .increment,                       .kind = .reallocate,                .loc = .Next,           .err = .Wrap },
    .{ .tag = .decrement,                       .kind = .reallocate,                .loc = .Back,           .err = .Wrap },
    .{ .tag = .appendOne,                       .kind = .append, .val = .One,       .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendCount,                     .kind = .append, .val = .Count,     .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendMany,                      .kind = .append, .val = .Many,      .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendFields,                    .kind = .append, .val = .Fields,    .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendArgs,                      .kind = .append, .val = .Args,      .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendFormat,                    .kind = .append, .val = .Format,    .loc = .Next,           .err = .Wrap },
    .{ .tag = .appendAny,                       .kind = .append, .val = .Any,       .loc = .Next,           .err = .Wrap },
};
// zig fmt: on
pub inline fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
    }
}
pub const Fn = packed struct {
    tag: Tag,
    kind: Kind,
    val: Value = .None,
    loc: Location = .AllDefined,
    err: ErrorHandler = .None,
    decl: builtin.CallingConvention = .Unspecified,
    pub const Kind = enum(u4) {
        // State actions
        get = 0,
        set = 1,
        // Value actions
        read = 2,
        refer = 3,
        write = 4,
        append = 5,
        // Interface state actions
        allocate = 6,
        reallocate = 7,
        deallocate = 8,
        transform = 9,
    };
    const Value = enum(u4) {
        None = 0,
        One = 1,
        Count = 2,
        CountWithSentinel = 3,
        Many = 4,
        ManyWithSentinel = 5,
        Fields = 6,
        Args = 7,
        Format = 8,
        Any = 9,
        Location = 10,
        Offset = 11,
    };
    const ErrorHandler = enum(u2) {
        None = 0,
        Try = 1,
        Wrap = 2,
    };
    const Location = enum(u3) {
        /// below unstreamed_byte_address: (overwrite|read)*Behind
        Behind = 0,
        /// unstreamed_byte_address and above: (overwrite|read)*Ahead
        Ahead = 1,
        /// below undefined_byte_address: re(write|read)*Back
        Back = 2,
        /// undefined_byte_address and above (write|append)*
        Next = 3,
        /// All positions with defined values
        AllDefined = 4,
        /// Any position with a defined value
        AnyDefined = 5,
        // Any position with an undefined value
        AnyUndefined = 6,
        // All positions with undefined value
        AllUndefined = 7,
    };
    pub const Tag = enum {
        defineAll,
        undefineAll,
        streamAll,
        unstreamAll,
        index,
        len,
        avail,
        __at,
        __ad,
        __len,
        __rem,
        readAll,
        referAllDefined,
        readAllWithSentinel,
        referAllDefinedWithSentinel,
        __behind,
        unstream,
        readOneBehind,
        readCountBehind,
        readCountWithSentinelBehind,
        referCountWithSentinelBehind,
        readManyBehind,
        readManyWithSentinelBehind,
        referManyWithSentinelBehind,
        readOneAt,
        referOneAt,
        overwriteOneAt,
        readCountAt,
        referCountAt,
        overwriteCountAt,
        readCountWithSentinelAt,
        referCountWithSentinelAt,
        readManyAt,
        referManyAt,
        overwriteManyAt,
        readManyWithSentinelAt,
        referManyWithSentinelAt,
        stream,
        readOneAhead,
        readCountAhead,
        readCountWithSentinelAhead,
        readManyAhead,
        readManyWithSentinelAhead,
        __back,
        undefine,
        readOneBack,
        referOneBack,
        overwriteOneBack,
        readCountBack,
        referCountBack,
        overwriteCountBack,
        readCountWithSentinelBack,
        referCountWithSentinelBack,
        readManyBack,
        referManyBack,
        overwriteManyBack,
        readManyWithSentinelBack,
        referManyWithSentinelBack,
        referAllUndefined,
        referAllUndefinedWithSentinel,
        define,
        referOneUndefined,
        writeOne,
        referCountUndefined,
        writeCount,
        referManyUndefined,
        writeMany,
        writeFields,
        writeArgs,
        writeFormat,
        writeAny,
        static,
        dynamic,
        holder,
        init,
        grow,
        deinit,
        shrink,
        increment,
        decrement,
        appendOne,
        appendCount,
        appendMany,
        appendFields,
        appendArgs,
        appendFormat,
        appendAny,
    };
    pub inline fn fnName(ctn_fn_info: *const Fn) [:0]const u8 {
        return @tagName(ctn_fn_info.tag);
    }
    pub fn hasCapability(ctn_fn_info: *const Fn, ctn_detail: *const out.DetailLess) bool {
        switch (ctn_fn_info.tag) {
            .defineAll => {},
            .undefineAll => {},
            .streamAll => {},
            .unstreamAll => {},
            .index => {},
            .len => {},
            .avail => {},
            .__at => {},
            .__ad => {},
            .__len => {},
            .__rem => {},
            .readAll => {},
            .referAllDefined => {},
            .readAllWithSentinel => {},
            .referAllDefinedWithSentinel => {},
            .__behind => {},
            .unstream => {},
            .readOneBehind => {},
            .readCountBehind => {},
            .readCountWithSentinelBehind => {},
            .referCountWithSentinelBehind => {},
            .readManyBehind => {},
            .readManyWithSentinelBehind => {},
            .referManyWithSentinelBehind => {},
            .readOneAt => {},
            .referOneAt => {},
            .overwriteOneAt => {},
            .readCountAt => {},
            .referCountAt => {},
            .overwriteCountAt => {},
            .readCountWithSentinelAt => {},
            .referCountWithSentinelAt => {},
            .readManyAt => {},
            .referManyAt => {},
            .overwriteManyAt => {},
            .readManyWithSentinelAt => {},
            .referManyWithSentinelAt => {},
            .stream => {},
            .readOneAhead => {},
            .readCountAhead => {},
            .readCountWithSentinelAhead => {},
            .readManyAhead => {},
            .readManyWithSentinelAhead => {},
            .__back => {},
            .undefine => {},
            .readOneBack => {},
            .referOneBack => {},
            .overwriteOneBack => {},
            .readCountBack => {},
            .referCountBack => {},
            .overwriteCountBack => {},
            .readCountWithSentinelBack => {},
            .referCountWithSentinelBack => {},
            .readManyBack => {},
            .referManyBack => {},
            .overwriteManyBack => {},
            .readManyWithSentinelBack => {},
            .referManyWithSentinelBack => {},
            .referAllUndefined => {},
            .referAllUndefinedWithSentinel => {},
            .define => {},
            .referOneUndefined => {},
            .writeOne => {},
            .referCountUndefined => {},
            .writeCount => {},
            .referManyUndefined => {},
            .writeMany => {},
            .writeFields => {},
            .writeArgs => {},
            .writeFormat => {},
            .writeAny => {},
            .static => return !ctn_detail.kinds.static and !ctn_detail.kinds.automatic,
            .dynamic => return !ctn_detail.kinds.dynamic and !ctn_detail.kinds.automatic,
            .holder => return !ctn_detail.kinds.parametric and !ctn_detail.kinds.automatic,
            .init,
            .deinit,
            => return !ctn_detail.kinds.automatic,
            .grow,
            .shrink,
            .appendOne,
            .appendCount,
            .appendMany,
            .appendFields,
            .appendArgs,
            .appendFormat,
            .appendAny,
            .increment,
            .decrement,
            => return !ctn_detail.kinds.automatic or ctn_detail.kinds.static,
        }
        return true;
    }
    pub fn argList(ctn_fn_info: *const Fn, ctn_detail: *const out.DetailLess, list_kind: gen.ListKind) gen.ArgList { // 8KiB
        var array: gen.ArgList = undefined;
        array.undefineAll();
        const array_ptr_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.array_ptr_param,
            .Argument => tok.array_name,
        };
        const array_const_ptr_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.array_const_ptr_param,
            .Argument => tok.array_name,
        };
        const allocator_ptr_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.allocator_ptr_param,
            .Argument => tok.allocator_name,
        };
        const allocator_const_ptr_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.allocator_const_ptr_param,
            .Argument => tok.allocator_name,
        };
        const child_type_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.child_param,
            .Argument => tok.child_type_name,
        };
        const sentinel_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.s_sentinel_param,
            .Argument => tok.sentinel_name,
        };
        const value_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.value_param,
            .Argument => tok.value_name,
        };
        const count_values_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.count_values_param,
            .Argument => tok.count_values_name,
        };
        const count_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.count_param,
            .Argument => tok.count_name,
        };
        const static_count_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.static_count_param,
            .Argument => tok.count_name,
        };
        const many_values_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.many_values_param,
            .Argument => tok.many_values_name,
        };
        const format_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.format_param,
            .Argument => tok.format_name,
        };
        const reinterpret_spec_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.reinterpret_spec_param,
            .Argument => tok.reinterpret_spec_name,
        };
        const args_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.args_param,
            .Argument => tok.args_name,
        };
        const any_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.any_param,
            .Argument => tok.any_name,
        };
        const fields_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.fields_param,
            .Argument => tok.fields_name,
        };
        const amount_symbol: [:0]const u8 = blk: {
            if (ctn_detail.layouts.unstructured) {
                break :blk switch (list_kind) {
                    .Parameter => tok.amount_param,
                    .Argument => tok.amount_name,
                };
            } else {
                break :blk switch (list_kind) {
                    .Parameter => tok.count_param,
                    .Argument => tok.count_name,
                };
            }
        };
        const offset_symbol: [:0]const u8 = blk: {
            if (ctn_detail.layouts.unstructured) {
                break :blk switch (list_kind) {
                    .Parameter => tok.offset_amount_param,
                    .Argument => tok.offset_name,
                };
            } else {
                break :blk switch (list_kind) {
                    .Parameter => tok.offset_param,
                    .Argument => tok.offset_name,
                };
            }
        };
        switch (ctn_fn_info.tag) {
            .defineAll,
            .undefineAll,
            .streamAll,
            .unstreamAll,
            => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .len,
            .index,
            .avail,
            => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .__at => {
                if (!ctn_detail.kinds.parametric) {
                    array.writeOne(array_const_ptr_symbol);
                }
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .__len,
            .__rem,
            => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .__ad,
            .__back,
            .__behind,
            => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .readAll,
            .referAllDefined,
            => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .readAllWithSentinel,
            .referAllDefinedWithSentinel,
            => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .unstream => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(amount_symbol);
            },
            .stream => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(amount_symbol);
            },
            .undefine => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(amount_symbol);
            },
            .define => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(amount_symbol);
            },
            .readOneBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
            },
            .readCountBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
            },
            .readCountWithSentinelBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
            },
            .readManyBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
            },
            .readManyWithSentinelBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .readOneAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .readCountAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(offset_symbol);
            },
            .readCountWithSentinelAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
                array.writeOne(offset_symbol);
            },
            .readManyAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .readManyWithSentinelAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(sentinel_symbol);
                array.writeOne(offset_symbol);
            },
            .readOneAhead => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
            },
            .readCountAhead => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
            },
            .readCountWithSentinelAhead => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
            },
            .readManyAhead => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
            },
            .readManyWithSentinelAhead => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .readOneBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
            },
            .readCountBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
            },
            .readCountWithSentinelBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
            },
            .readManyBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
            },
            .readManyWithSentinelBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .overwriteOneAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }

                array.writeOne(value_symbol);
                array.writeOne(offset_symbol);
            },
            .overwriteCountAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(count_values_symbol);
                array.writeOne(offset_symbol);
            },
            .overwriteManyAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(many_values_symbol);
                array.writeOne(offset_symbol);
            },
            .overwriteOneBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(value_symbol);
            },
            .overwriteCountBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(count_values_symbol);
            },
            .overwriteManyBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(many_values_symbol);
            },
            .referCountWithSentinelBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
            },
            .referManyWithSentinelBehind => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(sentinel_symbol);
                array.writeOne(offset_symbol);
            },
            .referOneAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .referCountAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(offset_symbol);
            },
            .referCountWithSentinelAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
                array.writeOne(offset_symbol);
            },
            .referManyAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(offset_symbol);
            },
            .referManyWithSentinelAt => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(sentinel_symbol);
                array.writeOne(offset_symbol);
            },
            .referOneBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
            },
            .referCountBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
            },
            .referManyBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
            },
            .referCountWithSentinelBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
                array.writeOne(sentinel_symbol);
            },
            .referManyWithSentinelBack => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    array.writeOne(count_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .referAllUndefined => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .referAllUndefinedWithSentinel => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
                array.writeOne(sentinel_symbol);
            },
            .referOneUndefined => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .referCountUndefined => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(static_count_symbol);
            },
            .referManyUndefined => {
                array.writeOne(array_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    array.writeOne(allocator_const_ptr_symbol);
                }
            },
            .static => {},
            .dynamic => {},
            .holder => {},
            .init => {
                array.writeOne(allocator_ptr_symbol);
                if (ctn_detail.kinds.dynamic) {
                    array.writeOne(count_symbol);
                }
            },
            .grow, .shrink => {
                array.writeOne(array_ptr_symbol);
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(count_symbol);
            },
            .deinit => {
                array.writeOne(array_ptr_symbol);
                array.writeOne(allocator_ptr_symbol);
            },
            .increment,
            .decrement,
            => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(offset_symbol);
            },

            .writeOne => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(value_symbol);
            },
            .appendOne => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(value_symbol);
            },
            .writeCount => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(static_count_symbol);
                array.writeOne(count_values_symbol);
            },
            .appendCount => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(static_count_symbol);
                array.writeOne(count_values_symbol);
            },
            .writeMany => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(many_values_symbol);
            },
            .appendMany => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(many_values_symbol);
            },
            .writeFormat => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(format_symbol);
            },
            .appendFormat => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(format_symbol);
            },
            .writeFields => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(fields_symbol);
            },
            .appendFields => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(fields_symbol);
            },
            .writeArgs => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(args_symbol);
            },
            .appendArgs => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(args_symbol);
            },
            .writeAny => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(any_symbol);
            },
            .appendAny => {
                array.writeOne(array_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    array.writeOne(child_type_symbol);
                }
                array.writeOne(reinterpret_spec_symbol);
                array.writeOne(allocator_ptr_symbol);
                array.writeOne(any_symbol);
            },
        }
        return array;
    }
    pub fn writeCall(ctn_fn_info: *const Fn, array: anytype, ctn_detail: *const out.DetailLess) void {
        const list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(")");
    }
    pub fn writeSignature(ctn_fn_info: *const Fn, array: anytype, ctn_detail: *const out.DetailLess) void {
        const list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Parameter);
        array.writeMany("pub fn ");
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") ");
    }
    pub fn getReturnType(ctn_fn_info: *const Fn) [:0]const u8 {
        switch (ctn_fn_info.kind) {
            .write => return tok.void_type_name,
            .refer => switch (ctn_fn_info.val) {
                .One => return tok.child_ptr_type_name,
                .Count => return tok.child_array_ptr_type_name,
                .CountWithSentinel => return tok.child_array_ptr_with_sentinel_type_name,
                .Many => return tok.child_slice_type_name,
                .ManyWithSentinel => return tok.child_slice_with_sentinel_type_name,
                else => return tok.void_type_name,
            },
            .read => switch (ctn_fn_info.val) {
                .One => return tok.child_type_name,
                .Count => return tok.child_array_type_name,
                .CountWithSentinel => return tok.child_array_with_sentinel_type_name,
                .Many => return tok.child_const_slice_type_name,
                .ManyWithSentinel => return tok.child_const_slice_with_sentinel_type_name,
                else => return tok.void_type_name,
            },
            .append => return tok.allocator_void_type_name,
            else => return tok.void_type_name,
        }
    }
};
