const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const proc = @import("./../proc.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");

pub const is_verbose: bool = false;
pub const is_silent: bool = true;

pub usingnamespace proc.start;

const testing = @import("./../testing.zig");

const gen = @import("./gen-0.zig");

const sum = @import("./mem-template.zig");

pub const AddressSpace = preset.address_space.formulaic_128;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
});
pub const Array = Allocator.StructuredHolder(u8);
// pub const Array = mem.StaticString(65536);

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
        else => @compileError(@typeName(@TypeOf(any))),
    }
}
fn typeNames(comptime types: []const type) []const u8 {
    var ret: []const u8 = ".{ ";
    for (types) |T| {
        ret = ret ++ @typeName(T) ++ ", ";
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
            array.writeMany("return " ++ @typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasFieldDeductionInternal(array, filtered[1], field_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[0][0]) ++ ";\n");
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
            array.writeMany("return " ++ @typeName(filtered[1][0]) ++ ";\n");
        } else {
            writeHasDeclDeductionInternal(filtered[1], decl_names[1..]);
        }
    }
    if (filtered[0].len != 0) {
        if (filtered[1].len != 0) {
            array.writeMany("} else {\n");
        }
        if (filtered[0].len == 1) {
            array.writeMany("return " ++ @typeName(filtered[0][0]) ++ ";\n");
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
    array.writeMany("const " ++ decl_name ++ ": " ++ @typeName(decl_type) ++ " = undefined;\n");
}
pub fn main() void {}
