//! This stage derives specification variants
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const mach = @import("./../mach.zig");
const preset = @import("./../preset.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen.zig");

const out = @import("./zig-out/src/memgen_abstract.zig");

const fmt_spec: fmt.RenderSpec = .{ .omit_trailing_comma = true };

fn slicePtr(comptime T: type) *[]const T {
    var ptrs: []const T = &.{};
    return &ptrs;
}
fn addUniqueFieldName(field_names: *mem.StaticArray([]const u8, 16), field_name: []const u8) void {
    for (field_names.readAll()) |unique_field_name| {
        if (builtin.testEqual([]const u8, field_name, unique_field_name)) {
            return;
        }
    }
    field_names.writeOne(field_name);
}

// Questionable
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
fn writeSpecifications(array: *gen.String, comptime T: type, field_names: *mem.StaticArray([]const u8, 16)) void {
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
            if (@hasField(gen.Variant, field_union_field_name)) {
                switch (@field(gen.Variant, field_union_field_name)) {
                    .__stripped => {
                        p_struct_fields = meta.concat(builtin.Type.StructField, p_struct_fields, field);
                    },
                    .__derived => {
                        s_struct_field_slices = addField(
                            s_struct_field_slices,
                            meta.structField(field.type, field.name, null),
                        );
                    },
                    .__optional_derived => {
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
                    .__optional_variant => {
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
                    .__decl_optional_derived => {
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
                    .__decl_optional_variant => {
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
                continue;
            }
        }
    }
    array.writeMany("\n    .{ .params = ");
    writeStructFromFields(array, p_struct_fields);
    array.undefine(2);
    array.writeMany(", options: options.Options0");
    array.writeMany(" }, .specs = &[_]type{\n");
    inline for (s_struct_field_slices) |s_struct_fields| {
        array.writeMany("        ");
        writeStructFromFields(array, s_struct_fields);
        array.writeMany(",\n");
    }
    array.writeMany("    }, .vars = packed ");
    inline for (v_struct_fields) |field| {
        addUniqueFieldName(field_names, field.name);
    }
    writeStructFromFields(array, v_struct_fields);
    array.writeMany(" },");
}

fn writeStructFromFields(array: *gen.String, comptime struct_fields: []const builtin.Type.StructField) void {
    array.writeMany("struct { ");
    inline for (struct_fields) |field| {
        array.writeMany(field.name ++ ": " ++
            comptime gen.simpleTypeName(field.type));
        if (comptime meta.defaultValue(field)) |default_value| {
            if (field.type == bool) {
                array.writeMany(if (default_value) " = true, " else " = false, ");
            } else {
                array.writeMany(" = null, ");
            }
        } else {
            array.writeMany(", ");
        }
    }
    if (struct_fields.len != 0) {
        array.overwriteManyBack(" }");
    } else {
        array.writeOne('}');
    }
}
fn writeSpecifiersStruct(array: *gen.String, field_names: mem.StaticArray([]const u8, 16)) void {
    array.writeMany("pub const Specifiers = packed struct { ");
    for (field_names.readAll()) |field_name| {
        array.writeMany(field_name);
        array.writeMany(": bool = false, ");
    }
    array.undefine(2);
    array.writeMany(" };\n");
}
pub fn abstractToTypeSpec(array: *gen.String) void {
    gen.writeImports(array, @src(), &.{
        .{ .name = "gen", .path = "./../../gen.zig" },
        .{ .name = "options", .path = "./memgen_options.zig" },
    });
    var field_names: mem.StaticArray([]const u8, 16) = undefined;
    field_names.undefineAll();
    array.writeMany("pub const type_specs = [_]gen.TypeSpecMap{");
    inline for (out.abstract_params) |param| {
        writeSpecifications(array, param, &field_names);
    }
    array.writeMany("\n};\n");
    writeSpecifiersStruct(array, field_names);
    gen.writeFile(array, "memgen_type_spec.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var array: gen.String = gen.String.init(builtin.debug.impendingBytes(1024 * 1024));
    array.undefineAll();
    abstractToTypeSpec(&array);
    gen.exit(0);
}
