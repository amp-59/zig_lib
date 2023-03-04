const gen = @import("./gen.zig");
const fmt = gen.fmt;
const meta = gen.meta;
const algo = gen.algo;
const builtin = gen.builtin;
const testing = gen.testing;

const tok = @import("./tok.zig");
const detail = @import("./detail.zig");
const config = @import("./config.zig");
// zig fmt: off

const kind = @import("./zig-out/src/container_kinds.zig");

pub const key = blk: {
    var res: [@typeInfo(Fn).Enum.fields.len]Fn = undefined;
    for (@typeInfo(Fn).Enum.fields, 0..) |field, index| {
        res[index] =@intToEnum(Fn, field.value);
    }
    break :blk res;
};
// zig fmt: on
pub fn get(comptime tag: Fn) *const Fn {
    comptime {
        for (key) |val| {
            if (val == tag) return &val;
        }
    }
}
pub const Fn = enum(u8) {
    defineAll,
    undefineAll,
    streamAll,
    unstreamAll,

    len,
    __len,
    index,
    __at,
    avail,
    __avail,

    __undefined,
    __defined,
    __unstreamed,
    __streamed,

    readAll,
    referAllDefined,
    readAllWithSentinel,
    referAllDefinedWithSentinel,

    unstream,
    readOneStreamed,
    readCountStreamed,
    readCountWithSentinelStreamed,
    referCountWithSentinelStreamed,
    readManyStreamed,
    readManyWithSentinelStreamed,
    referManyWithSentinelStreamed,
    readOneOffsetStreamed,
    readCountOffsetStreamed,
    readCountWithSentinelOffsetStreamed,
    referCountWithSentinelOffsetStreamed,
    readManyOffsetStreamed,
    readManyWithSentinelOffsetStreamed,
    referManyWithSentinelOffsetStreamed,

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

    ahead,
    stream,
    readOneUnstreamed,
    readCountUnstreamed,
    readCountWithSentinelUnstreamed,
    readManyUnstreamed,
    readManyWithSentinelUnstreamed,
    readOneOffsetUnstreamed,
    readCountOffsetUnstreamed,
    readCountWithSentinelOffsetUnstreamed,
    readManyOffsetUnstreamed,
    readManyWithSentinelOffsetUnstreamed,

    undefine,
    readOneDefined,
    referOneDefined,
    overwriteOneDefined,
    readCountDefined,
    referCountDefined,
    overwriteCountDefined,
    readCountWithSentinelDefined,
    referCountWithSentinelDefined,
    readManyDefined,
    referManyDefined,
    overwriteManyDefined,
    readManyWithSentinelDefined,
    referManyWithSentinelDefined,
    readOneOffsetDefined,
    referOneOffsetDefined,
    overwriteOneOffsetDefined,
    readCountOffsetDefined,
    referCountOffsetDefined,
    overwriteCountOffsetDefined,
    readCountWithSentinelOffsetDefined,
    referCountWithSentinelOffsetDefined,
    readManyOffsetDefined,
    referManyOffsetDefined,
    overwriteManyOffsetDefined,
    readManyWithSentinelOffsetDefined,
    referManyWithSentinelOffsetDefined,

    referAllUndefined,
    referAllUndefinedWithSentinel,
    define,
    referOneUndefined,
    referOneOffsetUndefined,
    writeOne,
    referCountUndefined,
    referCountOffsetUndefined,
    writeCount,
    referManyUndefined,
    referManyOffsetUndefined,
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
    pub fn fnName(ctn_fn_info: Fn) [:0]const u8 {
        return @tagName(ctn_fn_info);
    }
    pub fn hasCapability(ctn_fn_info: Fn, ctn_detail: *const detail.Less) bool {
        switch (ctn_fn_info) {
            .__at,
            .__len,
            .readAll,
            .readAllWithSentinel,
            .referAllDefined,
            .referAllDefinedWithSentinel,
            .readOneAt,
            .referOneAt,
            .overwriteOneAt,
            .readCountAt,
            .referCountAt,
            .overwriteCountAt,
            .readCountWithSentinelAt,
            .referCountWithSentinelAt,
            .readManyAt,
            .referManyAt,
            .overwriteManyAt,
            .readManyWithSentinelAt,
            .referManyWithSentinelAt,
            .len,
            => return true,

            .stream,
            .unstream,
            .streamAll,
            .unstreamAll,
            .index,
            .__streamed,
            .__unstreamed,

            .readOneStreamed,
            .readCountStreamed,
            .readCountWithSentinelStreamed,
            .referCountWithSentinelStreamed,
            .readManyStreamed,
            .readManyWithSentinelStreamed,
            .referManyWithSentinelStreamed,

            .readOneOffsetStreamed,
            .readCountOffsetStreamed,
            .readCountWithSentinelOffsetStreamed,
            .referCountWithSentinelOffsetStreamed,
            .readManyOffsetStreamed,
            .readManyWithSentinelOffsetStreamed,
            .referManyWithSentinelOffsetStreamed,

            .ahead,
            .readOneUnstreamed,
            .readCountUnstreamed,
            .readCountWithSentinelUnstreamed,
            .readManyUnstreamed,
            .readManyWithSentinelUnstreamed,
            .readOneOffsetUnstreamed,
            .readCountOffsetUnstreamed,
            .readCountWithSentinelOffsetUnstreamed,
            .readManyOffsetUnstreamed,
            .readManyWithSentinelOffsetUnstreamed,
            => return ctn_detail.modes.stream,

            .__undefined,
            .__defined,
            .__avail,
            .defineAll,
            .undefineAll,
            .avail,
            .undefine,
            .readOneDefined,
            .referOneDefined,
            .overwriteOneDefined,
            .readCountDefined,
            .referCountDefined,
            .overwriteCountDefined,
            .readCountWithSentinelDefined,
            .referCountWithSentinelDefined,
            .readManyDefined,
            .referManyDefined,
            .overwriteManyDefined,
            .readManyWithSentinelDefined,
            .referManyWithSentinelDefined,
            .readOneOffsetDefined,
            .referOneOffsetDefined,
            .overwriteOneOffsetDefined,
            .readCountOffsetDefined,
            .referCountOffsetDefined,
            .overwriteCountOffsetDefined,
            .readCountWithSentinelOffsetDefined,
            .referCountWithSentinelOffsetDefined,
            .readManyOffsetDefined,
            .referManyOffsetDefined,
            .overwriteManyOffsetDefined,
            .readManyWithSentinelOffsetDefined,
            .referManyWithSentinelOffsetDefined,
            .referAllUndefined,
            .referAllUndefinedWithSentinel,
            .define,
            .referOneUndefined,
            .referOneOffsetUndefined,
            .writeOne,
            .referCountUndefined,
            .referCountOffsetUndefined,
            .writeCount,
            .referManyUndefined,
            .referManyOffsetUndefined,
            => return ctn_detail.modes.resize,

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
    pub fn argList(ctn_fn_info: Fn, ctn_detail: *const detail.Less, list_kind: gen.ListKind) gen.ArgList { // 8KiB
        var arg_list: gen.ArgList = .{
            .args = undefined,
            .len = 0,
            .kind = list_kind,
            .ret = ctn_fn_info.returnType(),
        };
        const arg_list_ptr_symbol: [:0]const u8 = switch (list_kind) {
            .Parameter => tok.array_ptr_param,
            .Argument => tok.array_name,
        };
        const arg_list_const_ptr_symbol: [:0]const u8 = switch (list_kind) {
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
                    .Parameter => tok.offset_word_param,
                    .Argument => tok.offset_name,
                };
            }
        };
        switch (ctn_fn_info) {
            .defineAll,
            .undefineAll,
            .unstreamAll,
            => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .streamAll => {
                arg_list.writeOne(arg_list_ptr_symbol);
            },
            .len,
            .index,
            .avail,
            => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .ahead => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .__at => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .__len,
            .__avail,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .__undefined,
            .__defined,
            .__streamed,
            .__unstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readAll,
            .referAllDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .readAllWithSentinel,
            .referAllDefinedWithSentinel,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .unstream => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .stream => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .undefine => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .define => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .readOneStreamed,
            .readOneOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .readOneOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readCountStreamed,
            .readCountOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .readCountOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .readCountWithSentinelStreamed,
            .readCountWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .readCountWithSentinelOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyStreamed,
            .readManyOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                if (ctn_fn_info == .readManyOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyWithSentinelStreamed,
            .readManyWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                if (ctn_fn_info == .readManyWithSentinelOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },

            .readOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .readCountWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .readManyAt, .referManyAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readManyWithSentinelAt, .referManyWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .readOneUnstreamed,
            .readOneOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .readOneOffsetUnstreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readCountUnstreamed,
            .readCountOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                if (ctn_fn_info == .readCountOffsetUnstreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readCountWithSentinelUnstreamed,
            .readCountWithSentinelOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .readCountWithSentinelOffsetUnstreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyUnstreamed,
            .readManyOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                if (ctn_fn_info == .readManyOffsetUnstreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyWithSentinelUnstreamed,
            .readManyWithSentinelOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .readManyWithSentinelOffsetUnstreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readOneDefined,
            .readOneOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .readOneOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readCountDefined,
            .readCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                if (ctn_fn_info == .readCountOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readCountWithSentinelDefined,
            .readCountWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .readCountWithSentinelOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyDefined,
            .readManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                if (ctn_fn_info == .readManyOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .readManyWithSentinelDefined,
            .readManyWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .readManyWithSentinelOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .overwriteOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }

                arg_list.writeOne(value_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteManyAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(many_values_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteOneDefined,
            .overwriteOneOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .overwriteOneOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
                arg_list.writeOne(value_symbol);
            },
            .overwriteCountDefined,
            .overwriteCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                if (ctn_fn_info == .overwriteCountOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
                arg_list.writeOne(count_values_symbol);
            },
            .overwriteManyDefined,
            .overwriteManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .overwriteManyOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
                arg_list.writeOne(many_values_symbol);
            },
            .referCountWithSentinelStreamed,
            .referCountWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .referCountWithSentinelOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referManyWithSentinelStreamed,
            .referManyWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .referManyWithSentinelOffsetStreamed) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .referCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .referCountWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .referOneDefined,
            .referOneOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .referOneOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referCountDefined,
            .referCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                if (ctn_fn_info == .referCountOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referManyDefined,
            .referManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                if (ctn_fn_info == .referManyOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referCountWithSentinelDefined,
            .referCountWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .referCountWithSentinelOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referManyWithSentinelDefined,
            .referManyWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
                if (ctn_fn_info == .referManyWithSentinelOffsetDefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referAllUndefined => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .referAllUndefinedWithSentinel => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kinds.parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .referOneUndefined,
            .referOneOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_fn_info == .referOneOffsetUndefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referCountUndefined,
            .referCountOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                if (ctn_fn_info == .referCountOffsetUndefined) {
                    arg_list.writeOne(offset_symbol);
                }
            },
            .referManyUndefined,
            .referManyOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (!config.user_defined_length and
                    ctn_detail.kinds.parametric)
                {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                if (ctn_fn_info == .referManyOffsetUndefined) {
                    arg_list.writeOne(offset_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
            },
            .static => {},
            .dynamic => {},
            .holder => {},
            .init => {
                arg_list.writeOne(allocator_ptr_symbol);
                if (ctn_detail.kinds.dynamic) {
                    arg_list.writeOne(count_symbol);
                }
            },
            .grow, .shrink => {
                arg_list.writeOne(arg_list_ptr_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(count_symbol);
            },
            .deinit => {
                arg_list.writeOne(arg_list_ptr_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
            },
            .increment,
            .decrement,
            => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(offset_symbol);
            },

            .writeOne => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(value_symbol);
            },
            .appendOne => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(value_symbol);
            },
            .writeCount => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
            },
            .appendCount => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
            },
            .writeMany => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(many_values_symbol);
            },
            .appendMany => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(many_values_symbol);
            },
            .writeFormat => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(format_symbol);
            },
            .appendFormat => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(format_symbol);
            },
            .writeFields => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(fields_symbol);
            },
            .appendFields => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(fields_symbol);
            },
            .writeArgs => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(args_symbol);
            },
            .appendArgs => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(args_symbol);
            },
            .writeAny => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(any_symbol);
            },
            .appendAny => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layouts.unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(any_symbol);
            },
        }
        return arg_list;
    }
    pub fn writeCall(ctn_fn_info: Fn, array: anytype, ctn_detail: *const detail.Less) void {
        const list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Argument);
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(")");
    }
    pub fn writeSignature(ctn_fn_info: Fn, array: anytype, ctn_detail: *const detail.Less) void {
        const list: gen.ArgList = ctn_fn_info.argList(ctn_detail, .Parameter);
        array.writeMany("pub fn ");
        array.writeMany(ctn_fn_info.fnName());
        array.writeMany("(");
        for (list.readAll()) |arg| gen.writeArgument(array, arg);
        array.writeMany(") ");
        array.writeMany(list.ret);
    }
    pub fn returnType(ctn_fn_info: Fn) [:0]const u8 {
        if (kind.write(ctn_fn_info)) {
            return tok.void_type_name;
        }
        if (kind.sentinel(ctn_fn_info)) {
            if (kind.refer_many(ctn_fn_info)) {
                return tok.child_slice_with_sentinel_type_name;
            }
            if (kind.refer_count(ctn_fn_info)) {
                return tok.child_array_ptr_with_sentinel_type_name;
            }
            if (kind.read_many(ctn_fn_info)) {
                return tok.child_const_slice_with_sentinel_type_name;
            }
            if (kind.read_count(ctn_fn_info)) {
                return tok.child_array_with_sentinel_type_name;
            }
            if (kind.read_one(ctn_fn_info)) {
                return tok.child_type_name;
            }
        }
        if (kind.refer_many(ctn_fn_info)) {
            return tok.child_slice_type_name;
        }
        if (kind.refer_count(ctn_fn_info)) {
            return tok.child_array_ptr_type_name;
        }
        if (kind.read_many(ctn_fn_info)) {
            return tok.child_const_slice_type_name;
        }
        if (kind.read_count(ctn_fn_info)) {
            return tok.child_array_type_name;
        }
        if (kind.refer_one(ctn_fn_info)) {
            return tok.child_ptr_type_name;
        }
        if (kind.append(ctn_fn_info) or
            ctn_fn_info == .init or
            ctn_fn_info == .increment or
            ctn_fn_info == .grow)
        {
            return tok.allocator_void_type_name;
        }
        if (ctn_fn_info == .deinit or
            ctn_fn_info == .decrement or
            ctn_fn_info == .shrink)
        {
            return tok.void_type_name;
        }
        return tok.word_type_name;
    }
};
