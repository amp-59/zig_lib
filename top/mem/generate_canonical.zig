const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/memgen_detail.zig");
    usingnamespace @import("./zig-out/src/memgen_type_spec.zig");
    usingnamespace @import("./zig-out/src/memgen_variants.zig");
};

const CanonicalSpec = struct {
    field_type: type,
    detail: type,

    type_name: []const u8,
    field_name: []const u8,
};
const mode_spec: CanonicalSpec = .{
    .type_name = "Mode",
    .field_type = gen.Modes,
    .detail = out.Detail,
    .field_name = "modes",
};
const kind_spec: CanonicalSpec = .{
    .type_name = "Kind",
    .field_type = gen.Kinds,
    .detail = out.Detail,
    .field_name = "kinds",
};
const layout_spec: CanonicalSpec = .{
    .type_name = "Layout",
    .field_type = gen.Layouts,
    .detail = out.Detail,
    .field_name = "layouts",
};
const field_spec: CanonicalSpec = .{
    .type_name = "Field",
    .field_type = gen.Fields,
    .detail = out.Detail,
    .field_name = "fields",
};
const tech_spec: CanonicalSpec = .{
    .type_name = "Technique",
    .field_type = gen.Techniques,
    .detail = out.Detail,
    .field_name = "techs",
};
const specs_spec: CanonicalSpec = .{
    .type_name = "Specifier",
    .field_type = out.Specifiers,
    .detail = out.DetailMore,
    .field_name = "specs",
};

fn writeCanonical(comptime spec: CanonicalSpec, comptime sample: []const spec.detail, array: *gen.String) void {
    const backing_int: type = meta.Child(spec.field_type);
    const Uniques = mem.StaticArray(backing_int, 256);
    var uniques: Uniques = undefined;
    uniques.undefineAll();
    lo: for (sample) |detail| {
        const value: spec.field_type = @field(detail, spec.field_name);
        for (uniques.readAll()) |unique_value| {
            if (@bitCast(backing_int, value) == unique_value) continue :lo;
        }
        uniques.writeOne(@bitCast(backing_int, value));
    }
    array.writeMany("pub const " ++ spec.type_name ++ " = enum(u");
    gen.writeIndex(array, @intCast(u8, @bitSizeOf(usize) - @clz(uniques.len() - 1)));
    array.writeMany(") {\n");
    for (uniques.readAll()) |unique, index| {
        const value: spec.field_type = @bitCast(spec.field_type, unique);
        array.writeMany("    ");
        const save: u64 = array.finish;
        inline for (@typeInfo(spec.field_type).Struct.fields) |field| {
            if (@field(value, field.name)) {
                array.writeMany(field.name ++ "_");
            }
        }
        if (save == array.finish) {
            array.writeMany("none");
        } else {
            array.undefine(1);
        }
        array.writeMany(" = ");
        gen.writeIndex(array, @intCast(u8, index));
        array.writeMany(",\n");
    }
    array.writeMany("    pub fn convert(" ++ spec.field_name ++ ": anytype) @This() {\n");
    array.writeMany("        switch (@bitCast(" ++ @typeName(backing_int) ++ ", " ++ spec.field_name ++ ")) {\n");
    for (uniques.readAll()) |unique| {
        const value: spec.field_type = @bitCast(spec.field_type, unique);
        array.writeMany("            ");
        gen.writeIndex(array, unique);
        array.writeMany(" => return .");
        const save: u64 = array.finish;
        inline for (@typeInfo(spec.field_type).Struct.fields) |field| {
            if (@field(value, field.name)) {
                array.writeMany(field.name ++ "_");
            }
        }
        if (array.finish == save) {
            array.writeMany("none");
        } else {
            array.undefine(1);
        }
        array.writeMany(",\n");
    }
    if (uniques.len() != @as(usize, ~@as(backing_int, 0)) + 1) {
        array.writeMany("            else => unreachable,\n");
    }
    array.writeMany("        }\n");
    array.writeMany("    }\n");
    array.writeMany("};\n");
}

fn writeCanonicalFieldTypes(array: *gen.String) void {
    writeCanonical(mode_spec, out.details, array);
    writeCanonical(kind_spec, out.details, array);
    writeCanonical(layout_spec, out.details, array);
    writeCanonical(field_spec, out.details, array);
    writeCanonical(tech_spec, out.details, array);
    writeCanonical(specs_spec, out.variants, array);
    gen.writeFile(array, "memgen_canonical.zig");
}

pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    writeCanonicalFieldTypes(&array);
    gen.exit(0);
}
