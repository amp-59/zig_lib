const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const gen = struct {
    usingnamespace @import("./gen-0.zig");
    usingnamespace @import("./gen-1.zig");
};
const Array = mem.StaticString(1024 * 1024);

// zig fmt: off
const fn_stds = .{
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

fn gatherContainerTypesInternal(comptime types: []const type, comptime T: type) []const type {
    var ret: []const type = types;
    if (!comptime meta.isContainer(T)) {
        return ret;
    }
    if (gen.typeIndex(ret, T) == null and @typeInfo(T) == .Struct) {
        ret = meta.concat(type, ret, T);
    }
    const type_info = meta.resolve(@typeInfo(T));
    inline for (type_info.fields) |field| {
        const Field = @TypeOf(field);
        if (@hasField(Field, "type")) {
            if (gen.typeIndex(types, field.type) == null) {
                ret = gatherContainerTypesInternal(ret, field.type);
            }
        }
    }
    return ret;
}
fn gatherContainerTypes(comptime T: type) []const type {
    return gatherContainerTypesInternal(meta.empty, T);
}
fn getMutuallyExclusiveOptions(comptime any: anytype) []const []const u8 {
    switch (@typeInfo(@TypeOf(any))) {
        .Struct => |struct_info| {
            var names: []const []const u8 = meta.empty;
            inline for (struct_info.fields) |field| {
                for (getMutuallyExclusiveOptions(@field(any, field.name))) |name| {
                    if (struct_info.is_tuple) {
                        names = meta.concat([]const u8, names, name);
                    } else {
                        names = meta.concat([]const u8, names, name ++ "_" ++ field.name);
                    }
                }
            }
            return names;
        },
        .EnumLiteral => {
            return meta.parcel([]const u8, @tagName(any));
        },
        else => @compileError(fmt.typeName(@TypeOf(any))),
    }
}
fn typeNames(comptime types: []const type) []const u8 {
    var ret: []const u8 = ".{ ";
    for (types) |T| {
        ret = ret ++ fmt.typeName(T) ++ ", ";
    }
    return ret ++ "}";
}
fn fieldNamesSuperSet(comptime types: []const type) []const []const u8 {
    var all_field_names: []const []const u8 = meta.empty;
    var all_field_types: []const type = meta.empty;
    for (types) |T| {
        lo: for (meta.resolve(@typeInfo(T)).fields) |field| {
            for (all_field_names) |field_name, type_index| {
                if (mem.testEqualMany(u8, field.name, field_name)) {
                    builtin.static.assertEqual(type, all_field_types[type_index], field.type);
                    continue :lo;
                }
            }
            all_field_names = meta.concat([]const u8, all_field_names, field.name);
            all_field_types = meta.concat(type, all_field_types, field.type);
        }
    }
    return all_field_names;
}
fn declNamesSuperSet(comptime types: []const type) []const []const u8 {
    var all_decl_names: []const []const u8 = meta.empty;
    var all_decl_types: []const type = meta.empty;
    for (types) |T| {
        lo: for (meta.resolve(@typeInfo(T)).decls) |decl| {
            for (all_decl_names) |decl_name, type_index| {
                if (mem.testEqualMany(u8, decl.name, decl_name)) {
                    builtin.static.assertEqual(type, all_decl_types[type_index], decl.type);
                    continue :lo;
                }
            }
            all_decl_names = meta.concat([]const u8, all_decl_names, decl.name);
            all_decl_types = meta.concat(type, all_decl_types, decl.type);
        }
    }
    return all_decl_names;
}
fn haveField(comptime types: []const type, comptime field_name: []const u8) gen.BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasField(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}
fn haveDecl(comptime types: []const type, comptime field_name: []const u8) gen.BinaryFilter(type) {
    comptime var t: []const type = meta.empty;
    comptime var f: []const type = meta.empty;
    inline for (types) |T| {
        if (@hasDecl(T, field_name)) {
            t = meta.concat(type, t, T);
        } else {
            f = meta.concat(type, f, T);
        }
    }
    return .{ f, t };
}
fn writeHasFieldDeductionInternal(array: *Array, comptime types: []const type, comptime field_names: []const []const u8) void {
    if (field_names.len == 0) {
        return array.writeMany("return " ++ comptime typeNames(types) ++ ";\n");
    }
    const filtered: gen.BinaryFilter(type) = comptime haveField(types, field_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (@hasField(T, \"" ++ field_names[0] ++ "\")) {\n");
        writeDeclaration(array, field_names[0], meta.Field(filtered[1][0], field_names[0]));
        if (filtered[1].len == 1) {
            array.writeMany("return " ++ comptime fmt.typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasFieldDeductionInternal(array, filtered[1], field_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ comptime fmt.typeName(filtered[0][0]) ++ ";\n");
        } else {
            writeHasFieldDeductionInternal(array, filtered[0], field_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeHasDeclDeductionInternal(array: *Array, comptime types: []const type, comptime decl_names: []const []const u8) void {
    if (decl_names.len == 0) {
        return array.writeMany("return " ++ comptime typeNames(types) ++ ";\n");
    }
    const filtered: gen.BinaryFilter(type) = comptime haveDecl(types, decl_names[0]);
    if (filtered[1].len != 0) {
        array.writeMany("if (@hasDecl(T, \"" ++ decl_names[0] ++ "\")) {\n");
        if (filtered[1].len == 1) {
            array.writeMany("return " ++ fmt.typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasDeclDeductionInternal(filtered[1], decl_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ fmt.typeName(filtered[0][0]) ++ ";\n");
        } else {
            writeHasDeclDeductionInternal(filtered[0], decl_names[1..]);
        }
    }
    if (filtered[1].len != 0) {
        array.writeMany("}\n");
    }
}
fn writeHasFieldDeduction(array: *Array, comptime types: []const type) void {
    array.writeMany("comptime {");
    writeHasFieldDeductionInternal(array, types, comptime fieldNamesSuperSet(types));
    array.writeMany("}");
}
fn writeHasDeclDeduction(array: *Array, comptime types: []const type) void {
    array.writeMany("comptime {");
    writeHasDeclDeductionInternal(array, types, comptime declNamesSuperSet(types));
    array.writeMany("}");
}
fn writeDeclaration(array: *Array, comptime decl_name: []const u8, comptime decl_type: type) void {
    array.writeMany("const " ++ decl_name ++ ": " ++ comptime fmt.typeName(decl_type) ++ " = undefined;\n");
}
/// All fields the same, all field types the same.
fn equivalentType(comptime dst_type: type, comptime src_type: type) bool {
    @setEvalBranchQuota(~@as(u32, 0));
    const src_type_info: builtin.Type = @typeInfo(src_type);
    const dst_type_info: builtin.Type = @typeInfo(dst_type);
    if (@as(builtin.TypeId, src_type_info) !=
        @as(builtin.TypeId, dst_type_info))
    {
        return false;
    }
    switch (src_type_info) {
        .Struct => |src_struct_info| {
            const dst_struct_info: builtin.Struct = dst_type_info.Struct;
            const src_fields: []const builtin.Type.StructField = src_struct_info.fields;
            const dst_fields: []const builtin.Type.StructField = dst_struct_info.fields;
            if (src_fields.len != dst_fields.len) {
                return false;
            }
            inline for (src_fields) |src_field, i| {
                const dst_field: builtin.Type.StructField = dst_fields[i];
                if (!mem.testEqualMany(u8, src_field.name, dst_field.name)) {
                    return false;
                }
                if (!equivalentType(dst_field.type, src_field.type)) {
                    return false;
                }
                if (src_field.default_value != null and dst_field.default_value != null) {
                    if (mem.pointerOpaque(src_field.type, src_field.default_value.?).* !=
                        mem.pointerOpaque(dst_field.type, dst_field.default_value.?).*)
                    {
                        return false;
                    }
                }
                if ((src_field.default_value == null) !=
                    (dst_field.default_value == null))
                {
                    return false;
                }
            }
        },
        .Enum => |src_enum_info| {
            const dst_enum_info: builtin.Enum = dst_type_info.Enum;
            const src_fields: []const builtin.EnumField = src_enum_info.fields;
            const dst_fields: []const builtin.EnumField = dst_enum_info.fields;
            if (src_fields.len != dst_fields.len) {
                return false;
            }
            inline for (src_fields) |src_field, i| {
                const dst_field: builtin.EnumField = dst_fields[i];
                if (src_field.value != dst_field.value) {
                    return false;
                }
                if (!mem.testEqualMany(u8, src_field.name, dst_field.name)) {
                    return false;
                }
            }
        },
        .Union => |src_union_info| {
            const dst_union_info: builtin.Union = dst_type_info.Union;
            const src_fields: []const builtin.UnionField = src_union_info.fields;
            const dst_fields: []const builtin.UnionField = dst_union_info.fields;
            if (src_fields.len != dst_fields.len) {
                return false;
            }
            inline for (src_fields) |src_field, i| {
                const dst_field: builtin.UnionField = dst_fields[i];
                if (!mem.testEqualMany(u8, src_field.name, dst_field.name)) {
                    return false;
                }
                if (!equivalentType(dst_field.type, src_field.type)) {
                    return false;
                }
            }
        },
        else => {
            return dst_type == src_type;
        },
    }
    return true;
}
pub fn generateContainerFunctions() void {}
