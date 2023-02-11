const mem = @import("../mem.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const tok = @import("./tok.zig");
const out = struct {
    usingnamespace @import("./detail_less.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};

pub usingnamespace proc.start;

const Args = mem.StaticArray([:0]const u8, 8);

// zig fmt: off
const key: [187]Fn = .{
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
    .{ .tag = .static,                          .kind = .special,                                   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .dynamic,                         .kind = .special,                                   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .holder,                          .kind = .special,                                   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .init,                            .kind = .{ .client = .allocate },                   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .grow,                            .kind = .{ .client = .{ .resize = .Above } },       .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .deinit,                          .kind = .{ .client = .deallocate },                 .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .shrink,                          .kind = .{ .client = .{ .resize = .Below } },       .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .increment,                       .kind = .{ .client = .{ .resize = .Increment } },   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .decrement,                       .kind = .{ .client = .{ .resize = .Decrement } },   .loc = .AllDefined, .err = .Wrap },
    .{ .tag = .appendOne,                       .kind = .append, .val = .One,                       .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendCount,                     .kind = .append, .val = .Count,                     .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendMany,                      .kind = .append, .val = .Many,                      .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendFields,                    .kind = .append, .val = .Fields,                    .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendArgs,                      .kind = .append, .val = .Args,                      .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendFormat,                    .kind = .append, .val = .Format,                    .loc = .Next,       .err = .Wrap },
    .{ .tag = .appendAny,                       .kind = .append, .val = .Any,                       .loc = .Next,       .err = .Wrap },
};
// zig fmt: on

pub const Fn = packed struct {
    tag: Tag,
    kind: Kind,
    val: Value = .None,
    loc: Location = .{ .Absolute = .AllDefined },
    err: ErrorHandler = .None,
    decl: builtin.CallingConvention = .Unspecified,
    const Kind = union(enum) {
        read,
        refer,
        write,
        append,
        helper,
        special,
        client,
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
    const Location = union(enum) {
        Absolute: AbsoluteLocation,
        Relative: RelativeLocation,
    };
    const AbsoluteLocation = enum(u2) {
        /// All positions with defined values
        AllDefined = 0,
        /// Any position with a defined value
        AnyDefined = 1,
        // Any position with an undefined value
        AnyUndefined = 2,
        // All positions with undefined value
        AllUndefined = 3,
    };
    const RelativeLocation = enum(u2) {
        /// below unstreamed_byte_address: (overwrite|read)*Behind
        Behind = 0,
        /// unstreamed_byte_address and above: (overwrite|read)*Ahead
        Ahead = 1,
        /// below undefined_byte_address: re(write|read)*Back
        Back = 2,
        /// undefined_byte_address and above (write|append)*
        Next = 3,
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
};

fn writeFunctionBodyGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    _ = impl_fn_info;
    _ = impl_variant;
    _ = array;
}

pub fn writeComma(array: *gen.String) void {
    const j0: bool = mem.testEqualOneBack(u8, '(', array.readAll());
    const j1: bool = mem.testEqualManyBack(u8, tok.end_small_item, array.readAll());
    if (builtin.int2a(bool, !j0, !j1)) {
        array.writeMany(tok.end_small_item);
    }
}
pub fn writeArgument(array: *gen.String, argument_name: [:0]const u8) void {
    writeComma(array);
    array.writeMany(argument_name);
}
pub fn writeImplFunctionCallGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFunctionSignatureOrCall(array, impl_variant, impl_fn_info, false);
}
pub fn writeImplFunctionSignatureGeneric(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn) void {
    writeFunctionSignatureOrCall(array, impl_variant, impl_fn_info, true);
}

fn writeFunctions(array: *gen.String, impl_variant: *const out.DetailMore) void {
    for (key) |*impl_fn_info| {
        if (!impl_fn_info.hasCapability(impl_variant)) {
            continue;
        }
        writeImplFunctionSignatureGeneric(array, impl_variant, impl_fn_info);
        array.writeMany("{\n");
        writeFunctionBodyGeneric(array, impl_variant, impl_fn_info);
        array.writeMany("}\n");
    }
}
fn writeDeclarations(array: *gen.String, impl_variant: *const out.DetailMore) void {
    array.writeMany("const " ++ tok.impl_type_name ++ " = @This();\n");
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        return array.writeMany("const Static = fn () callconv(.Inline) " ++
            tok.word_type_name ++ tok.end_expression);
    }
    if (impl_variant.kinds.parametric) {
        return array.writeMany("const Slave = fn (" ++ tok.slave_specifier_const_ptr_type_name ++ ") callconv(.Inline) " ++
            tok.word_type_name ++ tok.end_expression);
    }
    if (impl_variant.techs.unit_alignment) {
        return array.writeMany("pub const unit_alignment: usize = spec.unit_alignment;\n");
    }
    if (impl_variant.techs.auto_alignment) {
        return array.writeMany("pub const auto_alignment: usize = spec.low_alignment;\n");
    }
}
fn writeComptimeFieldInternal(array: *gen.String, fn_tag: Fn.Tag, args: *const Args) void {
    if (args.len() == 0) {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Static = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
    if (args.len() == 1 and
        args.readOneAt(0).ptr == tok.slave_specifier_name.ptr)
    {
        array.writeMany(tok.comptime_keyword);
        array.writeMany(@tagName(fn_tag));
        array.writeMany(": Slave = ");
        array.writeMany(@tagName(fn_tag));
        return array.writeMany(tok.end_item);
    }
}
inline fn writeComptimeField(array: *gen.String, impl_variant: *const out.DetailMore, comptime fn_tag: Fn.Tag) void {
    const args: Args = getArgList(impl_variant, Fn.get(fn_tag), false);
    writeComptimeFieldInternal(array, fn_tag, &args);
}
inline fn writeFields(array: *gen.String, impl_variant: *const out.DetailMore) void {
    writeComptimeField(array, impl_variant, .allocated_byte_address);
    writeComptimeField(array, impl_variant, .aligned_byte_address);
    writeComptimeField(array, impl_variant, .unallocated_byte_address);
    if (impl_variant.fields.automatic_storage) {
        if (impl_variant.specs.sentinel) {
            array.writeMany(tok.automatic_storage_with_sentinel_field);
        } else {
            array.writeMany(tok.automatic_storage_field);
        }
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.allocated_byte_address) {
        array.writeMany(tok.allocated_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.unstreamed_byte_address) {
        array.writeMany(tok.unstreamed_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.undefined_byte_address) {
        array.writeMany(tok.undefined_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    if (impl_variant.fields.unallocated_byte_address) {
        array.writeMany(tok.unallocated_byte_address_word_field);
        array.writeMany(tok.end_small_item);
    }
    writeComptimeField(array, impl_variant, .unwritable_byte_address);
    writeComptimeField(array, impl_variant, .allocated_byte_count);
    writeComptimeField(array, impl_variant, .writable_byte_count);
    writeComptimeField(array, impl_variant, .aligned_byte_count);
}
fn getArgList(impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, sign: bool) Args {
    var array: Args = undefined;
    array.undefineAll();
    if (impl_fn_info.mut == .Mutable) {
        array.writeOne(mach.cmovx(
            sign,
            tok.impl_param,
            tok.impl_name,
        ));
        array.writeOne(mach.cmovx(
            sign,
            tok.offset_bytes_param,
            tok.offset_bytes_name,
        ));
    } else //
    if (impl_variant.kinds.parametric) {
        if (impl_fn_info.val == .Address) {
            if (impl_fn_info.loc == .Absolute) {
                array.writeOne(mach.cmovx(
                    sign,
                    tok.slave_specifier_const_ptr_param,
                    tok.slave_specifier_name,
                ));
            } else {
                array.writeOne(mach.cmovx(
                    sign,
                    tok.impl_const_param,
                    tok.impl_name,
                ));
            }
        } else if (impl_fn_info.val == .Offset) {
            if (impl_fn_info.tag == .unstreamed_byte_count and
                impl_variant.fields.undefined_byte_address)
            {
                array.writeOne(mach.cmovx(
                    sign,
                    tok.impl_const_param,
                    tok.impl_name,
                ));
            } else if (impl_fn_info.loc == .Relative) {
                array.writeOne(mach.cmovx(
                    sign,
                    tok.impl_const_param,
                    tok.impl_name,
                ));
                array.writeOne(mach.cmovx(
                    sign,
                    tok.slave_specifier_const_ptr_param,
                    tok.slave_specifier_name,
                ));
            } else {
                array.writeOne(mach.cmovx(
                    sign,
                    tok.slave_specifier_const_ptr_param,
                    tok.slave_specifier_name,
                ));
            }
        }
    } else //
    if (impl_variant.kinds.automatic or
        impl_variant.kinds.static)
    {
        const has_unit_alignment: bool =
            impl_variant.techs.auto_alignment or
            impl_variant.techs.unit_alignment;
        const criteria_full: bool =
            impl_fn_info.tag == .writable_byte_count or
            impl_fn_info.tag == .aligned_byte_count or
            impl_fn_info.tag == .allocated_byte_count and has_unit_alignment;
        if (!criteria_full) {
            array.writeOne(mach.cmovx(
                sign,
                tok.impl_const_param,
                tok.impl_name,
            ));
        }
    } else {
        array.writeOne(mach.cmovx(
            sign,
            tok.impl_const_param,
            tok.impl_name,
        ));
    }
    return array;
}
fn writeReturnType(array: *gen.String, impl_fn_info: *const Fn) void {
    if (impl_fn_info.mut == .Mutable) {
        array.writeMany(" void ");
    } else {
        array.writeMany(" " ++ tok.word_type_name ++ " ");
    }
}
fn writeFunctionSignatureOrCall(array: *gen.String, impl_variant: *const out.DetailMore, impl_fn_info: *const Fn, sign: bool) void {
    const list: Args = getArgList(impl_variant, impl_fn_info, sign);
    if (sign) {
        array.writeMany("pub inline fn ");
    }
    array.writeMany(impl_fn_info.fnName());
    array.writeMany("(");
    for (list.readAll()) |arg| {
        writeArgument(array, arg);
    }
    array.writeMany(")");
    if (sign) {
        writeReturnType(array, impl_fn_info);
    }
}
inline fn writeTypeFunction(array: *gen.String, impl_variant: *const out.DetailLess) void {
    array.writeMany("fn ");
    impl_variant.writeImplementationName(array);
    array.writeMany("(comptime " ++ tok.spec_name ++ ": " ++ tok.generic_spec_type_name);
    array.writeMany(") type {\nreturn (struct {\n");
    {
        writeFields(array, impl_variant);
        writeDeclarations(array, impl_variant);
        writeFunctions(array, impl_variant);
    }
    array.writeMany("});\n}\n");
}

pub fn generateContainers() void {
    var array: gen.String = undefined;
    array.undefineAll();
    var accm_spec_index: u16 = 0;
    _ = accm_spec_index;
    var ctn_index: u16 = 0;
    while (ctn_index != out.containers.len) : (ctn_index +%= 1) {
        const ctn_group: []const u16 = out.containers[ctn_index];
        if (ctn_group.len == 0) {
            continue;
        }
    }
    gen.appendSourceFile(&array, "container.zig");
}

pub const main = generateContainers;
