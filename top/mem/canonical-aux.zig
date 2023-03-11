const gen = @import("./gen.zig");
const mem = gen.mem;
const sys = gen.sys;
const proc = gen.proc;
const meta = gen.meta;
const preset = gen.preset;
const builtin = gen.builtin;
const detail = @import("./detail.zig");
const canonical = @import("./canonical.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/specifiers.zig");
    usingnamespace @import("./zig-out/src/impl_details.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn writeFieldType(comptime field: canonical.CanonicalFieldSpec, array: *Array) void {
    const sample: []const field.detail = if (field.detail == detail.Base) out.impl_details else out.impl_variants;
    const backing_int: type = meta.Child(field.src_type);
    const Uniques = mem.StaticArray(backing_int, 256);
    var uniques: Uniques = undefined;
    uniques.undefineAll();
    lo: for (sample) |impl_detail| {
        const value: field.src_type = @field(impl_detail, field.src_name);
        for (uniques.readAll()) |unique_value| {
            if (@bitCast(backing_int, value) == unique_value) continue :lo;
        }
        uniques.writeOne(@bitCast(backing_int, value));
    }
    array.writeMany("pub const " ++ field.dst_type_name ++ "=enum(u");
    gen.fmt.ud64(@max(@intCast(u8, @bitSizeOf(u64) - @clz(uniques.len() - 1)), 1)).formatWrite(array);
    array.writeMany("){\n");
    for (uniques.readAll(), 0..) |unique, index| {
        const value: field.src_type = @bitCast(field.src_type, unique);
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
        array.writeMany("=");
        gen.fmt.ud64(@intCast(u8, index)).formatWrite(array);
        array.writeMany(",");
    }
    var field_len: u64 = 0;
    array.writeMany("pub fn convert(" ++ field.src_name ++ ":anytype)@This(){\n");
    array.writeMany("switch (@bitCast(" ++ @typeName(backing_int) ++ "," ++ field.src_name ++ ")){\n");
    for (uniques.readAll()) |unique| {
        const value: field.src_type = @bitCast(field.src_type, unique);
        gen.fmt.ud64(unique).formatWrite(array);
        array.writeMany("=>return .");
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
            field_len +%= 1;
        }
        array.writeMany(",\n");
    }
    if (uniques.len() != @as(usize, ~@as(backing_int, 0)) + 1) {
        array.writeMany("else=>unreachable,\n");
    }
    array.writeMany("}\n}\n");
    array.writeMany("pub fn revert(" ++ field.dst_name ++ ":@This(),comptime T:type)T{\n");
    array.writeMany("switch(" ++ field.dst_name ++ "){\n");
    for (uniques.readAll()) |unique| {
        const value: field.src_type = @bitCast(field.src_type, unique);
        array.writeMany(".");
        const save: u64 = array.len();
        inline for (@typeInfo(field.src_type).Struct.fields) |field_field| {
            if (@field(value, field_field.name)) {
                array.writeMany(field_field.name ++ "_");
            }
        }
        if (array.len() == save) {
            array.writeMany("none");
        } else {
            array.undefine(1);
        }
        array.writeMany("=>return@bitCast(T,@as(" ++ @typeName(backing_int) ++ ",");
        gen.fmt.ud64(unique).formatWrite(array);
        array.writeMany(")),\n");
    }
    array.writeMany("}\n}\n};\n");
}
fn writeCanonicalStruct(array: *Array, comptime spec: canonical.CanonicalSpec) void {
    inline for (spec.fields) |field| writeFieldType(field, array);
    array.writeMany("pub const " ++ spec.type_name ++ "=packed struct{\n");
    array.writeMany("index:u8,\n");
    inline for (spec.fields) |field| {
        array.writeMany(field.dst_name ++ ":" ++ field.dst_type_name ++ ",\n");
    }
    array.writeMany("pub fn convert(detail:anytype)" ++ spec.type_name ++ "{\n");
    array.writeMany("return .{\n");
    array.writeMany(".index=detail.index,\n");
    inline for (spec.fields) |field| {
        array.writeMany("." ++ field.dst_name ++ "=" ++ field.dst_type_name ++ ".convert(detail." ++ field.src_name ++ "),\n");
    }
    array.writeMany("};\n}\n};\n");
    gen.writeAuxiliarySourceFile(array, "canonical.zig");
}
pub fn main() void {
    var array: Array = undefined;
    array.undefineAll();
    writeCanonicalStruct(&array, .{ .fields = &.{
        canonical.layouts,
        canonical.kinds,
        canonical.modes,
        canonical.managers,
        canonical.fields,
        canonical.techs,
        canonical.specs,
    } });
}
