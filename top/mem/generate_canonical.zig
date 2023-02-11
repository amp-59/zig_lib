const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/impl_details.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};

const CanonicalSpec = struct {
    type_name: []const u8 = "Canonical",
    fields: []const CanonicalFieldSpec,
};
const CanonicalFieldSpec = struct {
    src_name: []const u8,
    src_type: type,
    dst_name: []const u8,
    dst_type_name: []const u8,
    detail: type,
};
const mode_spec: CanonicalFieldSpec = .{
    .src_name = "modes",
    .src_type = gen.Modes,
    .dst_name = "mode",
    .dst_type_name = "Mode",
    .detail = out.Detail,
};
const kind_spec: CanonicalFieldSpec = .{
    .src_name = "kinds",
    .src_type = gen.Kinds,
    .dst_name = "kind",
    .dst_type_name = "Kind",
    .detail = out.Detail,
};
const layout_spec: CanonicalFieldSpec = .{
    .src_name = "layouts",
    .src_type = gen.Layouts,
    .dst_name = "layout",
    .dst_type_name = "Layout",
    .detail = out.Detail,
};
const field_spec: CanonicalFieldSpec = .{
    .src_type = gen.Fields,
    .src_name = "fields",
    .dst_name = "field",
    .dst_type_name = "Field",
    .detail = out.Detail,
};
const tech_spec: CanonicalFieldSpec = .{
    .src_name = "techs",
    .src_type = gen.Techniques,
    .dst_name = "tech",
    .dst_type_name = "Technique",
    .detail = out.Detail,
};
const specs_spec: CanonicalFieldSpec = .{
    .src_name = "specs",
    .src_type = out.Specifiers,
    .dst_name = "spec",
    .dst_type_name = "Specifier",
    .detail = out.DetailMore,
};
fn writeFieldType(comptime field: CanonicalFieldSpec, array: *gen.String) void {
    const sample: []const field.detail = if (field.detail == out.Detail) out.impl_details else out.impl_variants;
    const backing_int: type = meta.Child(field.src_type);
    const Uniques = mem.StaticArray(backing_int, 256);
    var uniques: Uniques = undefined;
    uniques.undefineAll();
    lo: for (sample) |detail| {
        const value: field.src_type = @field(detail, field.src_name);
        for (uniques.readAll()) |unique_value| {
            if (@bitCast(backing_int, value) == unique_value) continue :lo;
        }
        uniques.writeOne(@bitCast(backing_int, value));
    }
    array.writeMany("pub const " ++ field.dst_type_name ++ " = enum(u");
    gen.writeIndex(array, @intCast(u8, @bitSizeOf(usize) - @clz(uniques.len() - 1)));
    array.writeMany(") {\n");
    for (uniques.readAll()) |unique, index| {
        const value: field.src_type = @bitCast(field.src_type, unique);
        array.writeMany("    ");
        const save: u64 = array.len();
        inline for (@typeInfo(field.src_type).Struct.fields) |field_field| {
            if (@field(value, field_field.name)) {
                array.writeMany(field_field.name ++ "_");
            }
        }
        if (save == array.len()) {
            array.writeMany("none");
        } else {
            array.undefine(1);
        }
        array.writeMany(" = ");
        gen.writeIndex(array, @intCast(u8, index));
        array.writeMany(",\n");
    }
    array.writeMany("    pub fn convert(" ++ field.src_name ++ ": anytype) @This() {\n");
    array.writeMany("        switch (@bitCast(" ++ @typeName(backing_int) ++ ", " ++ field.src_name ++ ")) {\n");
    for (uniques.readAll()) |unique| {
        const value: field.src_type = @bitCast(field.src_type, unique);
        array.writeMany("            ");
        gen.writeIndex(array, unique);
        array.writeMany(" => return .");
        const save: u64 = array.len();
        inline for (@typeInfo(field.src_type).Struct.fields) |field_field| {
            if (@field(value, field_field.name)) {
                array.writeMany(field_field.name ++ "_");
            }
        }
        if (save == array.len()) {
            array.writeMany("none");
        } else {
            array.undefine(1);
        }
        array.writeMany(",\n");
    }
    if (uniques.len() != @as(usize, ~@as(backing_int, 0)) + 1) {
        array.writeMany("            else => unreachable,\n");
    }
    array.writeMany("        }\n" ++ "    }\n" ++ "};\n");
}
fn writeCanonicalStruct(array: *gen.String, comptime spec: CanonicalSpec) void {
    inline for (spec.fields) |field| writeFieldType(field, array);
    array.writeMany("pub const " ++ spec.type_name ++ " = packed struct {\n");
    array.writeMany("    index: u8,\n");
    inline for (spec.fields) |field| {
        array.writeMany("    " ++ field.dst_name ++ ": " ++ field.dst_type_name ++ ",\n");
    }
    array.writeMany("    pub fn convert(detail: anytype) " ++ spec.type_name ++ " {\n");
    array.writeMany("        return .{\n");
    array.writeMany("            .index = detail.index,\n");
    inline for (spec.fields) |field| {
        array.writeMany("            ." ++ field.dst_name ++ " = " ++ field.dst_type_name ++ ".convert(detail." ++ field.src_name ++ "),\n");
    }
    array.writeMany("        };\n");
    array.writeMany("    }\n");
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(array, "canonical.zig");
}

pub export fn _start() noreturn {
    @setAlignStack(16);
    var array: gen.String = undefined;
    array.undefineAll();

    writeCanonicalStruct(&array, .{ .fields = &.{ layout_spec, kind_spec, mode_spec, field_spec, tech_spec, specs_spec } });
    sys.exit(0);
}
