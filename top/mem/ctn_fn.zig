const gen = @import("./gen.zig");
const fmt = gen.fmt;
const meta = gen.meta;
const algo = gen.algo;
const builtin = gen.builtin;
const testing = gen.testing;
const tok = @import("./tok.zig");
const attr = @import("./attr.zig");
const config = @import("./config.zig");

pub const kind = @import("./zig-out/src/container_kinds.zig");

pub const key = meta.tagList(Fn);
pub fn get(comptime tag: Fn) *const Fn {
    comptime {
        for (key) |val| {
            if (val == tag) return &val;
        }
    }
}

pub const Fn = enum(u8) {
    __undefined,
    __defined,
    __unstreamed,
    __streamed,
    __avail,
    __len,
    __at,
    readAll,
    readAllWithSentinel,
    readOneAt,
    readCountAt,
    readManyAt,
    readCountWithSentinelAt,
    readManyWithSentinelAt,
    readOneDefined,
    readCountDefined,
    readManyDefined,
    readCountWithSentinelDefined,
    readManyWithSentinelDefined,
    readOneOffsetDefined,
    readCountOffsetDefined,
    readManyOffsetDefined,
    readCountWithSentinelOffsetDefined,
    readManyWithSentinelOffsetDefined,
    readOneStreamed,
    readCountStreamed,
    readManyStreamed,
    readCountWithSentinelStreamed,
    readManyWithSentinelStreamed,
    readOneOffsetStreamed,
    readCountOffsetStreamed,
    readManyOffsetStreamed,
    readCountWithSentinelOffsetStreamed,
    readManyWithSentinelOffsetStreamed,
    readOneUnstreamed,
    readCountUnstreamed,
    readManyUnstreamed,
    readCountWithSentinelUnstreamed,
    readManyWithSentinelUnstreamed,
    readOneOffsetUnstreamed,
    readCountOffsetUnstreamed,
    readManyOffsetUnstreamed,
    readCountWithSentinelOffsetUnstreamed,
    readManyWithSentinelOffsetUnstreamed,
    referOneAt,
    referCountAt,
    referManyAt,
    referCountWithSentinelAt,
    referManyWithSentinelAt,
    referOneDefined,
    referCountDefined,
    referManyDefined,
    referCountWithSentinelDefined,
    referManyWithSentinelDefined,
    referOneOffsetDefined,
    referCountOffsetDefined,
    referManyOffsetDefined,
    referCountWithSentinelOffsetDefined,
    referManyWithSentinelOffsetDefined,
    referOneUndefined,
    referCountUndefined,
    referManyUndefined,
    referOneOffsetUndefined,
    referCountOffsetUndefined,
    referManyOffsetUndefined,
    referOneStreamed,
    referManyStreamed,
    referCountWithSentinelStreamed,
    referManyWithSentinelStreamed,
    referOneOffsetStreamed,
    referManyOffsetStreamed,
    referCountWithSentinelOffsetStreamed,
    referManyWithSentinelOffsetStreamed,
    referManyUnstreamed,
    referManyWithSentinelUnstreamed,
    referManyOffsetUnstreamed,
    referManyWithSentinelOffsetUnstreamed,
    overwriteOneAt,
    overwriteCountAt,
    overwriteManyAt,
    overwriteOneDefined,
    overwriteCountDefined,
    overwriteManyDefined,
    overwriteOneOffsetDefined,
    overwriteCountOffsetDefined,
    overwriteManyOffsetDefined,
    writeAny,
    writeOne,
    writeCount,
    writeMany,
    writeFormat,
    writeFields,
    writeArgs,
    appendFields,
    appendAny,
    appendArgs,
    appendFormat,
    appendOne,
    appendCount,
    appendMany,
    defineAll,
    undefineAll,
    streamAll,
    unstreamAll,
    len,
    index,
    avail,
    ahead,
    define,
    undefine,
    stream,
    unstream,
    init,
    grow,
    increment,
    shrink,
    decrement,
    static,
    dynamic,
    holder,
    deinit,
    pub fn fnName(ctn_fn_info: Fn) [:0]const u8 {
        return @tagName(ctn_fn_info);
    }
    pub fn hasCapability(ctn_fn_info: Fn, ctn_detail: *const attr.Container) bool {
        if (kind.stream(ctn_fn_info) or
            kind.unstream(ctn_fn_info) or
            kind.streamed(ctn_fn_info) or
            kind.unstreamed(ctn_fn_info) or
            ctn_fn_info == .ahead)
        {
            return ctn_detail.modes.stream;
        }
        if (kind.define(ctn_fn_info) or
            kind.undefine(ctn_fn_info) or
            kind.defined(ctn_fn_info) or
            kind.undefined(ctn_fn_info) or
            kind.write(ctn_fn_info) or
            ctn_fn_info == .avail)
        {
            return ctn_detail.modes.resize;
        }

        if (ctn_fn_info == .init or
            ctn_fn_info == .deinit)
        {
            return ctn_detail.managers.allocatable;
        }
        if (ctn_fn_info == .grow or
            ctn_fn_info == .shrink or
            ctn_fn_info == .increment or
            ctn_fn_info == .decrement)
        {
            return ctn_detail.managers.resizable;
        }
        if (kind.append(ctn_fn_info)) {
            return ctn_detail.managers.resizable and ctn_detail.modes.resize;
        }
        return true;
    }
    pub fn argList(ctn_fn_info: Fn, ctn_detail: *const attr.Container, list_kind: gen.ListKind) gen.ArgList {
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
            if (ctn_detail.layout == .unstructured) {
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
            if (ctn_detail.layout == .unstructured) {
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
                if (ctn_detail.kind == .parametric) {
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
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .ahead => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .__at => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .__len,
            .__avail,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
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
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readAll => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
            },
            .readAllWithSentinel => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .unstream => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .stream => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .undefine => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .define => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(amount_symbol);
            },
            .readOneStreamed,
            .readOneOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .readCountStreamed,
            .readCountOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .readCountWithSentinelStreamed,
            .readCountWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .readManyStreamed,
            .readManyOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
            },
            .readManyWithSentinelStreamed,
            .readManyWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .readOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .readCountWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .readManyAt, .referManyAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .readManyWithSentinelAt, .referManyWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
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
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .readCountUnstreamed,
            .readCountOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .readCountWithSentinelUnstreamed,
            .readCountWithSentinelOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .readManyUnstreamed,
            .readManyOffsetUnstreamed,
            .referManyUnstreamed,
            .referManyOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
            },
            .readManyWithSentinelUnstreamed,
            .readManyWithSentinelOffsetUnstreamed,
            .referManyWithSentinelUnstreamed,
            .referManyWithSentinelOffsetUnstreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .readOneDefined,
            .readOneOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .readCountDefined,
            .readCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .readCountWithSentinelDefined,
            .readCountWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .readManyDefined,
            .readManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
            },
            .readManyWithSentinelDefined,
            .readManyWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .overwriteOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(value_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteManyAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(many_values_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .overwriteOneDefined,
            .overwriteOneOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(value_symbol);
            },
            .overwriteCountDefined,
            .overwriteCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
            },
            .overwriteManyDefined,
            .overwriteManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(many_values_symbol);
            },
            .referCountWithSentinelStreamed,
            .referCountWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .referManyWithSentinelStreamed,
            .referManyWithSentinelOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .referOneAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(offset_symbol);
            },
            .referCountAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .referCountWithSentinelAt => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (ctn_detail.kind == .parametric) {
                    arg_list.writeOne(allocator_const_ptr_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .referOneDefined,
            .referOneOffsetDefined,
            .referOneStreamed,
            .referOneOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .referCountDefined,
            .referCountOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .referManyDefined,
            .referManyOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
            },
            .referCountWithSentinelDefined,
            .referCountWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(sentinel_symbol);
            },
            .referManyWithSentinelDefined,
            .referManyWithSentinelOffsetDefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (config.user_defined_length) {
                    arg_list.writeOne(count_symbol);
                }
                arg_list.writeOne(sentinel_symbol);
            },
            .referManyStreamed,
            .referManyOffsetStreamed,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(count_symbol);
            },
            .referOneUndefined,
            .referOneOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
            },
            .referCountUndefined,
            .referCountOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
            },
            .referManyUndefined,
            .referManyOffsetUndefined,
            => {
                arg_list.writeOne(arg_list_const_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                if (!config.user_defined_length and
                    ctn_detail.kind == .parametric)
                {
                    arg_list.writeOne(allocator_const_ptr_symbol);
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
                if (ctn_detail.kind == .dynamic) {
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
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(offset_symbol);
            },
            .writeOne => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(value_symbol);
            },
            .appendOne => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(value_symbol);
            },
            .writeCount => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
            },
            .appendCount => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(static_count_symbol);
                arg_list.writeOne(count_values_symbol);
            },
            .writeMany => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(many_values_symbol);
            },
            .appendMany => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(many_values_symbol);
            },
            .writeFormat => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(format_symbol);
            },
            .appendFormat => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(format_symbol);
            },
            .writeFields => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(fields_symbol);
            },
            .appendFields => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(fields_symbol);
            },
            .writeArgs => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(args_symbol);
            },
            .appendArgs => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(args_symbol);
            },
            .writeAny => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(any_symbol);
            },
            .appendAny => {
                arg_list.writeOne(arg_list_ptr_symbol);
                if (ctn_detail.layout == .unstructured) {
                    arg_list.writeOne(child_type_symbol);
                }
                arg_list.writeOne(reinterpret_spec_symbol);
                arg_list.writeOne(allocator_ptr_symbol);
                arg_list.writeOne(any_symbol);
            },
        }
        if (kind.offset(ctn_fn_info)) {
            arg_list.writeOne(offset_symbol);
        }
        return arg_list;
    }
    pub fn returnType(ctn_fn_info: Fn) [:0]const u8 {
        switch (ctn_fn_info) {
            .defineAll,
            .undefineAll,
            .streamAll,
            .unstreamAll,
            .deinit,
            .decrement,
            .shrink,
            => return tok.void_type_name,
            else => {
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
                if (kind.read_one(ctn_fn_info)) {
                    return tok.child_type_name;
                }
                if (kind.append(ctn_fn_info) or
                    ctn_fn_info == .init or
                    ctn_fn_info == .increment or
                    ctn_fn_info == .grow)
                {
                    return tok.allocator_void_type_name;
                }
                return tok.word_type_name;
            },
        }
    }
};
pub const utility = struct {
    const PseudoAttributes = packed struct {
        helper: bool,
        rwvalue: packed struct {
            one: bool,
            count: bool,
            many: bool,
            format: bool,
            fields: bool,
            args: bool,
            any: bool,
        },
        sentinel: bool,
        offset: bool,
        loc: packed struct {
            at: bool,
            defined: bool,
            undefined: bool,
            streamed: bool,
            unstreamed: bool,
        },
        rrwa: packed struct {
            read: bool,
            refer: bool,
            overwrite: bool,
            write: bool,
            append: bool,
        },
        special: bool,
    };
    const Sort = struct {
        fn comparison(x: anytype, y: anytype) bool {
            return x > y;
        }
        fn transform(x: anytype) u64 {
            return meta.leastBitCast(PseudoAttributes{
                .helper = kind.helper(x),
                .rwvalue = .{
                    .one = kind.one(x),
                    .count = kind.count(x),
                    .many = kind.many(x),
                    .format = kind.format(x),
                    .args = kind.args(x),
                    .fields = kind.fields(x),
                    .any = kind.sentinel(x),
                },
                .sentinel = kind.sentinel(x),
                .offset = kind.offset(x),
                .loc = .{
                    .at = kind.at(x),
                    .defined = kind.defined(x),
                    .undefined = kind.undefined(x),
                    .streamed = kind.streamed(x),
                    .unstreamed = kind.unstreamed(x),
                },
                .rrwa = .{
                    .read = kind.read(x),
                    .refer = kind.refer(x),
                    .overwrite = kind.overwrite(x),
                    .write = kind.write(x),
                    .append = kind.append(x),
                },
                .special = kind.special(x),
            });
        }
    };
    pub fn showPseudoSorted() void {
        var unsorted: [key.len]Fn = key;
        algo.shellSort(Fn, Sort.comparison, Sort.transform, &unsorted);
        builtin.debug.write("pub const Fn = enum(" ++ @typeName(@typeInfo(Fn).Enum.tag_type.?) ++ ") {\n");
        for (unsorted) |sorted| {
            builtin.debug.write("    ");
            builtin.debug.write(@tagName(sorted));
            builtin.debug.write(",\n");
        }
        builtin.debug.write("};\n");
    }
};
