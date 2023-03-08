//! This stage derives specification variants
const gen = @import("./gen.zig");
const mem = gen.mem;
const proc = gen.proc;
const meta = gen.meta;
const preset = gen.preset;
const builtin = gen.builtin;
const out = struct {
    usingnamespace @import("./abstract_spec.zig");
    usingnamespace @import("./zig-out/src/abstract_params.zig");
};

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

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
fn writeSpecifications(array: *Array, comptime T: type, field_names: *mem.StaticArray([]const u8, 16)) void {
    comptime var p_struct_fields: []const builtin.Type.StructField = &.{};
    comptime var v_struct_fields: []const builtin.Type.StructField = &.{};
    comptime var s_struct_field_slices: []const []const builtin.Type.StructField = meta.empty;
    inline for (@typeInfo(T).Struct.fields) |field| {
        const field_type_info: builtin.Type = @typeInfo(field.type);
        if (field_type_info != .Union) {
            p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, field);
            s_struct_field_slices = addField(
                s_struct_field_slices,
                meta.structField(field.type, field.name, null),
            );
        } else {
            const field_union_field_name: []const u8 = field_type_info.Union.fields[0].name;
            if (@hasField(out.Variant, field_union_field_name)) {
                switch (@field(out.Variant, field_union_field_name)) {
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
                }
            }
        }
    }
    array.writeMany(".{.params=");
    writeStructFromFields(array, p_struct_fields);
    array.writeMany(",.specs=&[_]type{\n");
    inline for (s_struct_field_slices) |s_struct_fields| {
        writeStructFromFields(array, s_struct_fields);
        array.writeMany(",\n");
    }
    array.writeMany("},.vars=packed ");
    inline for (v_struct_fields) |field| {
        addUniqueFieldName(field_names, field.name);
    }
    writeStructFromFields(array, v_struct_fields);
    array.writeMany("},");
}

fn writeStructFromFields(array: *Array, comptime struct_fields: []const builtin.Type.StructField) void {
    array.writeMany("struct {");
    inline for (struct_fields) |field| {
        array.writeMany(field.name ++ ":" ++
            comptime gen.simpleTypeName(field.type));
        if (comptime meta.defaultValue(field)) |default_value| {
            if (field.type == bool) {
                array.writeMany(if (default_value) "=true," else "=false,");
            } else {
                array.writeMany("=null,");
            }
        } else {
            array.writeMany(",");
        }
    }
    array.undefine(builtin.int(u1, array.readOneBack() == ','));
    array.writeOne('}');
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
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "gen", "../../gen.zig");
    var field_names: mem.StaticArray([]const u8, 16) = undefined;
    field_names.undefineAll();
    array.writeMany("pub const type_specs = [_]gen.TypeSpecMap{");
    inline for (out.abstract_params) |param| {
        writeSpecifications(&array, param, &field_names);
    }
    array.writeMany("\n};\n");
    gen.writeAuxiliarySourceFile(&array, "type_specs.zig");
    writeSpecifiersStruct(&array, field_names);
}
pub inline fn main() void {
    abstractToTypeSpec();
}
