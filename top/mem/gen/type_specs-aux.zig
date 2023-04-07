//! This stage derives specification variants
const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const meta = gen.meta;
const spec = gen.spec;
const builtin = gen.builtin;
const abstract_spec = @import("./abstract_spec.zig");

const out = @import("./zig-out/src/abstract_params.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);
const TypeDescrFormat = fmt.GenericTypeDescrFormat(.{ .tokens = .{
    .next = ",",
    .lbrace = "{",
    .rbrace = "}",
    .indent = "",
    .colon = ":",
} });

fn addUniqueFieldName(field_names: *mem.StaticArray([]const u8, 16), field_name: []const u8) void {
    for (field_names.readAll()) |unique_field_name| {
        if (builtin.testEqual([]const u8, field_name, unique_field_name)) {
            return;
        }
    }
    field_names.writeOne(field_name);
}
fn getFieldDefault(
    comptime field: builtin.Type.StructField,
    comptime field_name: []const u8,
) ?meta.Field(field.type, field_name) {
    return @field(mem.pointerOpaque(field.type, field.default_value orelse return null), field_name);
}
fn addVariant(
    comptime struct_field_slices: []const []const builtin.Type.StructField,
    comptime struct_field: builtin.Type.StructField,
) []const []const builtin.Type.StructField {
    return struct_field_slices ++ addField(struct_field_slices, struct_field);
}
fn addField(
    comptime struct_field_slices: []const []const builtin.Type.StructField,
    comptime struct_field: builtin.Type.StructField,
) []const []const builtin.Type.StructField {
    if (struct_field_slices.len == 0) {
        return &[1][]const builtin.Type.StructField{&[1]builtin.Type.StructField{struct_field}};
    } else {
        var ret: []const []const builtin.Type.StructField = &.{};
        for (struct_field_slices) |struct_fields| {
            ret = ret ++ [1][]const builtin.Type.StructField{struct_fields ++ [1]builtin.Type.StructField{struct_field}};
        }
        return ret;
    }
}
fn writeSpecifications(types: *Array, variants: *Array, comptime T: type, field_names: *mem.StaticArray([]const u8, 16)) void {
    comptime var p_struct_fields: []const builtin.Type.StructField = &.{};
    comptime var v_struct_fields: []const builtin.Type.StructField = &.{};
    comptime var s_struct_field_slices: []const []const builtin.Type.StructField = meta.empty;
    variants.writeMany("&.{\n");
    inline for (@typeInfo(T).Struct.fields) |field| {
        const field_type_info: builtin.Type = @typeInfo(field.type);
        if (field_type_info != .Union) {
            variants.writeMany(".mandatory,");
            p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, field);
            s_struct_field_slices = addField(
                s_struct_field_slices,
                meta.structField(field.type, field.name, null),
            );
        } else {
            const field_union_field_name: []const u8 = field_type_info.Union.fields[0].name;
            variants.writeMany("." ++ field_union_field_name);
            if (@hasField(gen.Variant, field_union_field_name)) {
                switch (@field(gen.Variant, field_union_field_name)) {
                    .stripped => {
                        p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, field);
                    },
                    .derived => {
                        s_struct_field_slices = addField(
                            s_struct_field_slices,
                            meta.structField(field.type, field.name, null),
                        );
                    },
                    .optional_derived => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const s_field_type: type = meta.Child(p_field_type);
                        p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, meta.structField(
                            p_field_type,
                            field.name,
                            getFieldDefault(field, field_union_field_name),
                        ));
                        s_struct_field_slices = addField(
                            s_struct_field_slices,
                            meta.structField(s_field_type, field.name, null),
                        );
                    },
                    .optional_variant => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const s_field_type: type = meta.Child(p_field_type);
                        p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, meta.structField(
                            p_field_type,
                            field.name,
                            getFieldDefault(field, field_union_field_name),
                        ));
                        v_struct_fields = meta.concat(
                            builtin.Type.StructField,
                            v_struct_fields,
                            meta.structField(bool, field.name, false),
                        );
                        s_struct_field_slices = addVariant(
                            s_struct_field_slices,
                            meta.structField(s_field_type, field.name, null),
                        );
                    },
                    .decl_optional_derived => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const fields: []const builtin.Type.StructField = meta.structFields(p_field_type);
                        p_struct_fields = meta.concat(
                            builtin.Type.StructField,
                            p_struct_fields,
                            meta.structField(fields[0].type, fields[0].name, null),
                        );
                        s_struct_field_slices = addField(
                            s_struct_field_slices,
                            meta.structField(fields[1].type, fields[1].name, null),
                        );
                        variants.writeMany("=" ++ fields[1].name);
                    },
                    .decl_optional_variant => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const fields: []const builtin.Type.StructField = meta.structFields(p_field_type);
                        p_struct_fields = meta.concat(
                            builtin.Type.StructField,
                            p_struct_fields,
                            meta.structField(fields[0].type, fields[0].name, null),
                        );
                        v_struct_fields = meta.concat(
                            builtin.Type.StructField,
                            v_struct_fields,
                            meta.structField(bool, fields[1].name, false),
                        );
                        s_struct_field_slices = addVariant(
                            s_struct_field_slices,
                            meta.structField(fields[1].type, fields[1].name, null),
                        );
                    },
                    .mandatory => @compileError("???"),
                }
                variants.writeMany(",");
            } else {
                @compileError("bad field");
            }
        }
    }
    variants.writeMany("},");
    types.writeMany(".{.params=");
    writeStructFromFields(types, p_struct_fields);
    types.writeMany(",.specs=&[_]type{\n");
    inline for (s_struct_field_slices) |s_struct_fields| {
        writeStructFromFields(types, s_struct_fields);
        types.writeMany(",\n");
    }
    types.writeMany("},.vars=packed ");
    inline for (v_struct_fields) |field| {
        addUniqueFieldName(field_names, field.name);
    }
    writeStructFromFields(types, v_struct_fields);
    types.writeMany("},");
}
fn writeStructFromFields(types: *Array, comptime struct_fields: []const builtin.Type.StructField) void {
    types.writeFormat(TypeDescrFormat.init(@Type(meta.structInfo(.Auto, struct_fields))));
}
fn writeSpecifiersStruct(array: *Array, field_names: mem.StaticArray([]const u8, 16)) void {
    array.writeMany("pub const Specifiers=packed struct{");
    for (field_names.readAll()) |field_name| {
        array.writeMany(field_name);
        array.writeMany(":bool=false,");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(array, "specifiers.zig");
}
pub fn abstractToTypeSpec() void {
    var field_names: mem.StaticArray([]const u8, 16) = undefined;
    var types: Array = undefined;
    types.undefineAll();
    types.writeMany("pub const type_specs:[]const gen.TypeSpecMap=&[_]gen.TypeSpecMap{");
    var variants: Array = undefined;
    variants.undefineAll();
    variants.writeMany("pub const type_vars:[]const[]const gen.Variant=&[_][]const gen.Variant{");
    field_names.undefineAll();
    inline for (out.abstract_params) |param| {
        writeSpecifications(&types, &variants, param, &field_names);
    }
    types.writeMany("\n};\n");
    variants.writeMany("};\n");
    types.writeMany(variants.readAll());
    gen.writeImport(&types, "gen", "../../gen.zig");
    gen.writeAuxiliarySourceFile(&types, "type_specs.zig");
    writeSpecifiersStruct(&types, field_names);
}
pub inline fn main() void {
    abstractToTypeSpec();
}
