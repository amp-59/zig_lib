const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const meta = @import("../meta.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/kinds.zig");
};

const Array = mem.StaticArray(u8, 1024 * 1024);

fn variantsToInterface(array: *Array, comptime field_name: []const u8, kind_group: []const out.Index) void {
    array.writeMany("&.{ ");
    for (kind_group) |impl_index| {
        if (@field(out.impl_variants[impl_index].management, field_name)) {
            array.writeFormat(fmt.ud64(impl_index));
            array.writeMany(", ");
        }
    }
    array.overwriteOneBack('}');
    array.writeOne(',');
}
fn variantsToInterfaces() void {
    var array: Array = undefined;
    array.undefineAll();
    gen.writeGenerator(&array, @src());

    gen.writeImport(&array, "out", "./impl_variants.zig");
    array.writeMany("pub const interfaces: []const []const []const out.Index = &[_][]const []const out.Index{\n");
    inline for (@typeInfo(gen.Management).Struct.fields) |field| {
        array.writeMany("&.{\n");
        for (out.kinds) |kind_group| {
            variantsToInterface(&array, field.name, kind_group);
        }
        array.writeMany("},\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "interfaces.zig");
}
pub const main = variantsToInterfaces;
