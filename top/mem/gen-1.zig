//! This stage derives specification variants
const mem = @import("./../mem.zig");
const fmt = @import("./../fmt.zig");
const meta = @import("./../meta.zig");
const file = @import("./../file.zig");
const preset = @import("./../preset.zig");
const testing = @import("./../testing.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen-0.zig");

const abstract_params = @import("./abstract_params.zig").abstract_params;

pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .errors = preset.allocator.errors.noexcept,
});
pub const Array = mem.StaticString(65536);

const close_spec: file.CloseSpec = .{
    .errors = null,
};
const create_spec: file.CreateSpec = .{
    .errors = null,
    .options = .{ .exclusive = false },
};

const TypeSpecMap = struct {
    params: type,
    specs: []const type,
};
const boilerplate: []const u8 =
    \\//! This file is generated by `memgen` stage 1
    \\const gen = @import("./gen-1.zig");
    \\pub const type_spec = [_]gen.TypeSpecMap{
;
fn addVariant(
    comptime struct_field_slices: []const []const builtin.StructField,
    comptime struct_field: builtin.StructField,
) []const []const builtin.StructField {
    return struct_field_slices ++ addField(struct_field_slices, struct_field);
}
fn addField(
    comptime struct_field_slices: []const []const builtin.StructField,
    comptime struct_field: builtin.StructField,
) []const []const builtin.StructField {
    if (struct_field_slices.len == 0) {
        return &[1][]const builtin.StructField{&[1]builtin.StructField{struct_field}};
    } else {
        var ret: []const []const builtin.StructField = meta.empty;
        for (struct_field_slices) |struct_fields| {
            ret = meta.concat([]const builtin.StructField, ret, struct_fields ++ [1]builtin.StructField{struct_field});
        }
        return ret;
    }
}
fn writeSpecifications(array: *Array, comptime T: type) void {
    comptime var p_struct_fields: []const builtin.StructField = meta.empty;
    comptime var s_struct_field_slices: []const []const builtin.StructField = meta.empty;
    inline for (@typeInfo(T).Struct.fields) |field| {
        const field_type_info: builtin.Type = @typeInfo(field.type);
        if (field_type_info != .Union) {
            p_struct_fields = meta.concat(builtin.StructField, p_struct_fields, field);
            s_struct_field_slices = addField(
                s_struct_field_slices,
                meta.structField(field.type, field.name, null),
            );
        } else {
            const field_union_field_name: []const u8 = field_type_info.Union.fields[0].name;
            if (@hasField(gen.Variant, field_union_field_name)) {
                switch (@field(gen.Variant, field_union_field_name)) {
                    .__stripped => {
                        p_struct_fields = meta.concat(builtin.StructField, p_struct_fields, field);
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
                        p_struct_fields = meta.concat(
                            builtin.StructField,
                            p_struct_fields,
                            meta.structField(p_field_type, field.name, if (field.default_value) |default_value_ptr|
                                @field(mem.pointerOpaque(field.type, default_value_ptr), field_union_field_name)
                            else
                                null),
                        );
                        s_struct_field_slices = addField(
                            s_struct_field_slices,
                            meta.structField(s_field_type, field.name, null),
                        );
                    },
                    .__optional_variant => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const s_field_type: type = meta.Child(p_field_type);
                        p_struct_fields = meta.concat(
                            builtin.StructField,
                            p_struct_fields,
                            meta.structField(p_field_type, field.name, if (field.default_value) |default_value_ptr|
                                @field(mem.pointerOpaque(field.type, default_value_ptr), field_union_field_name)
                            else
                                null),
                        );
                        s_struct_field_slices = addVariant(
                            s_struct_field_slices,
                            meta.structField(s_field_type, field.name, null),
                        );
                    },
                    .__decl_optional_derived => {
                        const p_field_type: type = meta.Field(field.type, field_union_field_name);
                        const fields: []const builtin.StructField = meta.structFields(p_field_type);
                        p_struct_fields = meta.concat(
                            builtin.StructField,
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
                        const fields: []const builtin.StructField = meta.structFields(p_field_type);
                        p_struct_fields = meta.concat(
                            builtin.StructField,
                            p_struct_fields,
                            meta.structField(fields[0].type, fields[0].name, null),
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
    array.writeMany(".{ .params = ");
    array.writeFormat(comptime fmt.any(@Type(meta.structInfo(p_struct_fields))));
    array.writeMany(", .specs = &[_]type{");
    inline for (s_struct_field_slices) |fields| {
        array.writeFormat(comptime fmt.any(@Type(meta.structInfo(fields))));
        array.writeMany(", ");
    }
    array.writeMany("}, },\n");
}
fn writeFile(array: *Array) void {
    const fd: u64 = file.create(create_spec, builtin.build_root.? ++ "/top/mem/type_spec.zig");
    defer file.close(close_spec, fd);
    file.noexcept.write(fd, boilerplate);
    file.noexcept.write(fd, array.readAll());
}
pub fn generateSpecificationTypes() void {
    var array: Array = .{};
    inline for (abstract_params) |param|
        writeSpecifications(&array, param)
    else
        array.writeMany("};\n");
    writeFile(&array);
}
