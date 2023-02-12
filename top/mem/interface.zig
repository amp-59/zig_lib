const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = @import("./detail_less.zig");

// zig fmt: off
pub const key: [87]Fn = .{
    .{ .tag = .defineAll,                       .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .undefineAll,                     .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .streamAll,                       .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .unstreamAll,                     .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .index,                           .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .count,                           .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .avail,                           .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .__at,                            .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .__ad,                            .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .__len,                           .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .__rem,                           .kind = .special,                                   .loc = .AllDefined },
    .{ .tag = .readAll,                         .kind = .read,      .val = .Many,                   .loc = .AllDefined },
    .{ .tag = .referAllDefined,                 .kind = .refer,     .val = .Many,                   .loc = .AllDefined },
    .{ .tag = .readAllWithSentinel,             .kind = .read,      .val = .ManyWithSentinel,       .loc = .AllDefined },
    .{ .tag = .referAllDefinedWithSentinel,     .kind = .refer,     .val = .ManyWithSentinel,       .loc = .AllDefined },
    .{ .tag = .__behind,                        .kind = .special,                                   .loc = .Behind },
    .{ .tag = .unstream,                        .kind = .special,                                   .loc = .Behind },
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
    .{ .tag = .stream,                          .kind = .special,                                   .loc = .Ahead },
    .{ .tag = .readOneAhead,                    .kind = .read,      .val = .One,                    .loc = .Ahead },
    .{ .tag = .readCountAhead,                  .kind = .read,      .val = .Count,                  .loc = .Ahead },
    .{ .tag = .readCountWithSentinelAhead,      .kind = .read,      .val = .CountWithSentinel,      .loc = .Ahead },
    .{ .tag = .readManyAhead,                   .kind = .read,      .val = .Many,                   .loc = .Ahead },
    .{ .tag = .readManyWithSentinelAhead,       .kind = .read,      .val = .ManyWithSentinel,       .loc = .Ahead },
    .{ .tag = .__back,                          .kind = .special,                                   .loc = .Back },
    .{ .tag = .undefine,                        .kind = .special,                                   .loc = .Back },
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
    .{ .tag = .define,                          .kind = .special,                                   .loc = .Next },
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
    .{ .tag = .static,                          .kind = .special,                                   .err = .Wrap },
    .{ .tag = .dynamic,                         .kind = .special,                                   .err = .Wrap },
    .{ .tag = .holder,                          .kind = .special,                                   .err = .Wrap },
    .{ .tag = .init,                            .kind = .allocate,                                  .err = .Wrap },
    .{ .tag = .grow,                            .kind = .reallocate,                                .err = .Wrap },
    .{ .tag = .deinit,                          .kind = .deallocate,                                .err = .Wrap },
    .{ .tag = .shrink,                          .kind = .reallocate,                                .err = .Wrap },
    .{ .tag = .increment,                       .kind = .reallocate,                                .err = .Wrap },
    .{ .tag = .decrement,                       .kind = .reallocate,                                .err = .Wrap },
    .{ .tag = .appendOne,                       .kind = .append, .val = .One,       .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendCount,                     .kind = .append, .val = .Count,     .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendMany,                      .kind = .append, .val = .Many,      .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendFields,                    .kind = .append, .val = .Fields,    .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendArgs,                      .kind = .append, .val = .Args,      .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendFormat,                    .kind = .append, .val = .Format,    .loc = .Next,   .err = .Wrap },
    .{ .tag = .appendAny,                       .kind = .append, .val = .Any,       .loc = .Next,   .err = .Wrap },
};
pub inline fn get(comptime tag: Fn.Tag) *const Fn {
    comptime {
        for (key) |val| {
            if (val.tag == tag) return &val;
        }
        unreachable;
    }
}
// zig fmt: on

pub const Fn = packed struct {
    tag: Tag,
    kind: Kind,
    val: Value = .None,
    loc: Location = .AllDefined,
    err: ErrorHandler = .None,
    decl: builtin.CallingConvention = .Unspecified,
    pub const Kind = enum(u3) {
        read,
        refer,
        write,
        append,
        special,

        allocate,
        reallocate,
        deallocate,
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
        count,
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
    inline fn fnName(impl_fn_info: *const Fn) []const u8 {
        return @tagName(impl_fn_info.tag);
    }
    pub fn hasCapability(ctn_fn_info: *const Fn, ctn_detail: *const out.DetailLess) bool {
        switch (ctn_fn_info.kind) {
            .read => {
                return true;
            },
            .refer => {
                return true;
            },
            .write => {
                return true;
            },
            .append => {
                return ctn_detail.modes.resize;
            },
            .special => {},
            .allocate => {},
            .reallocate => {},
            .deallocate => {},
        }
        return true;
    }
    pub fn writeCall(ctn_fn_info: *const Fn, array: *gen.String, ctn_detail: *const out.DetailLess) void {
        const list: gen.ArgList = getArgList(ctn_detail, ctn_fn_info, .Argument);
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(")");
    }
    pub fn writeSignature(ctn_fn_info: *const Fn, array: *gen.String, ctn_detail: *const out.DetailLess) void {
        const list: gen.ArgList = getArgList(ctn_detail, ctn_fn_info, .Parameter);
        array.writeMany("pub fn ");
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") u64 ");
    }
};
pub fn getArgList(ctn_detail: *const out.DetailLess, ctn_fn_info: *const Fn, list_kind: gen.ListKind) gen.ArgList {
    var array: gen.ArgList = undefined;
    array.undefineAll();
    const is_count: bool =
        ctn_fn_info.val == .Count or
        ctn_fn_info.val == .CountWithSentinel;
    const is_special: bool = ctn_fn_info.kind == .special;
    const is_write: bool =
        ctn_fn_info.kind == .write or
        ctn_fn_info.kind == .append;
    if (is_special or is_write) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.array_ptr_param,
            .Argument => tok.array_name,
        });
    } else {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.array_const_ptr_param,
            .Argument => tok.array_name,
        });
    }
    if (ctn_detail.layouts.unstructured) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.child_param,
            .Argument => tok.child_name,
        });
    }
    const is_reinterpreted: bool =
        is_write and
        ctn_fn_info.val == .Any or
        ctn_fn_info.val == .Args or
        ctn_fn_info.val == .Fields;
    if (is_reinterpreted) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.reinterpret_spec_param,
            .Argument => tok.reinterpret_spec_name,
        });
    }
    const is_absolute: bool =
        ctn_fn_info.loc == .AllDefined or
        ctn_fn_info.loc == .AllUndefined or
        ctn_fn_info.loc == .AnyDefined or
        ctn_fn_info.loc == .AnyUndefined;
    if (ctn_fn_info.kind == .append) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.allocator_ptr_param,
            .Argument => tok.allocator_name,
        });
    } else //
    if (ctn_detail.kinds.parametric and is_absolute) {
        array.writeOne(switch (list_kind) {
            .Parameter => tok.allocator_param,
            .Argument => tok.allocator_name,
        });
    }
    const is_read: bool =
        ctn_fn_info.kind == .read or
        ctn_fn_info.kind == .refer;
    if (is_count) {
        if (is_read) {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.read_count_param,
                .Argument => tok.read_count_name,
            });
        }
        if (is_write) {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.write_count_param,
                .Argument => tok.write_count_name,
            });
        }
    }
    const has_sentinel: bool =
        ctn_fn_info.val == .ManyWithSentinel or
        ctn_fn_info.val == .CountWithSentinel;
    if (has_sentinel) {
        if (ctn_detail.layouts.structured) {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.s_sentinel_param,
                .Argument => tok.sentinel_name,
            });
        } else {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.u_sentinel_param,
                .Argument => tok.sentinel_name,
            });
        }
    }
    const is_many: bool =
        ctn_fn_info.val == .Many or
        ctn_fn_info.val == .ManyWithSentinel;
    const is_relative: bool =
        ctn_fn_info.loc == .Behind or
        ctn_fn_info.loc == .Ahead or
        ctn_fn_info.loc == .Back or
        ctn_fn_info.loc == .Next;
    const is_any: bool =
        ctn_fn_info.loc == .AnyDefined or
        ctn_fn_info.loc == .AnyUndefined;
    if (is_any or (is_relative and is_read and is_many)) {
        if (ctn_detail.layouts.structured) {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.offset_int_param,
                .Argument => tok.offset_name,
            });
        } else {
            array.writeOne(switch (list_kind) {
                .Parameter => tok.offset_amt_param,
                .Argument => tok.offset_name,
            });
        }
    }
    if (is_write) {
        switch (ctn_fn_info.val) {
            .Count => array.writeOne(switch (list_kind) {
                .Parameter => tok.count_values_param,
                .Argument => tok.count_values_name,
            }),
            .Many => array.writeOne(switch (list_kind) {
                .Parameter => tok.many_values_param,
                .Argument => tok.many_values_name,
            }),
            .One => array.writeOne(switch (list_kind) {
                .Parameter => tok.value_param,
                .Argument => tok.value_name,
            }),
            .Format => array.writeOne(switch (list_kind) {
                .Parameter => tok.format_param,
                .Argument => tok.format_name,
            }),
            .Fields => array.writeOne(switch (list_kind) {
                .Parameter => tok.fields_param,
                .Argument => tok.fields_name,
            }),
            .Args => array.writeOne(switch (list_kind) {
                .Parameter => tok.args_param,
                .Argument => tok.args_name,
            }),
            .Any => array.writeOne(switch (list_kind) {
                .Parameter => tok.any_param,
                .Argument => tok.any_name,
            }),
            else => return array,
        }
    }
    return array;
}
