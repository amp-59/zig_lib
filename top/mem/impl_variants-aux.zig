const gen = @import("./gen.zig");
const mem = gen.mem;
const meta = gen.meta;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;

const detail = @import("./detail.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./zig-out/src/impl_details.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn writeVariantStructInternal(array: *Array, impl_detail: detail.Base, specs: out.Specifiers) void {
    array.writeFormat(impl_detail.more(specs));
    array.writeMany(",\n");
}
fn writeVariantStruct(array: *Array, comptime impl_detail: detail.Base) u16 {
    const type_spec: gen.TypeSpecMap = out.type_specs[impl_detail.index];
    var vars: u16 = 0;
    while (vars <= @truncate(meta.Child(type_spec.vars), ~@as(u64, 0))) : (vars +%= 1) {
        var specs: out.Specifiers = .{};
        inline for (@typeInfo(type_spec.vars).Struct.fields) |field| {
            if (@hasField(out.Specifiers, field.name)) {
                @field(specs, field.name) = @field(
                    @bitCast(type_spec.vars, @truncate(meta.Child(type_spec.vars), vars)),
                    field.name,
                );
            }
        }
        writeVariantStructInternal(array, impl_detail, specs);
    }
    return vars;
}
fn detailToVariants() void {
    var array: Array = undefined;
    array.undefineAll();

    // Wipe/touch files
    gen.writeAuxiliarySourceFile(&array, "container_kinds.zig");
    gen.writeAuxiliarySourceFile(&array, "reference_kinds.zig");

    gen.writeImport(&array, "detail", "../../detail.zig");
    array.writeMany("pub const impl_variants: []const detail.More = &[_]detail.More{\n");
    var vars: u64 = 0;
    inline for (out.impl_details) |impl_detail| {
        vars +%= writeVariantStruct(&array, impl_detail);
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "impl_variants.zig");
    array.writeMany("pub const Index=");
    switch (vars) {
        0...255 => array.writeMany("u8;"),
        256...65535 => array.writeMany("u16;"),
        else => array.writeMany("u32;"),
    }
    gen.writeAuxiliarySourceFile(&array, "config.zig");
}
pub const main = detailToVariants;
