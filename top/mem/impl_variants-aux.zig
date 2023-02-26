const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");
    usingnamespace @import("./zig-out/src/impl_details.zig");
    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/specifiers.zig");
};
pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;

const Array = mem.StaticArray(u8, 1024 * 1024);

fn writeVariantStructInternal(array: *Array, impl_detail: out.Detail, specs: out.Specifiers) void {
    array.writeFormat(impl_detail.more(out.DetailMore, specs));
    array.writeMany(",\n");
}
fn writeVariantStruct(array: *Array, comptime impl_detail: out.Detail) u16 {
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
    gen.writeImport(&array, "out", "../../detail_more.zig");
    array.writeMany("pub const impl_variants: []const out.DetailMore = &[_]out.DetailMore{\n");
    var vars: u64 = 0;
    inline for (out.impl_details) |impl_detail| {
        vars +%= writeVariantStruct(&array, impl_detail);
    }
    array.writeMany("};\n");
    array.writeMany("pub const Index = ");
    switch (vars) {
        0...255 => array.writeMany("u8;"),
        256...65535 => array.writeMany("u16;"),
        else => array.writeMany("u32;"),
    }
    gen.writeAuxiliarySourceFile(&array, "impl_variants.zig");
}
pub const main = detailToVariants;
