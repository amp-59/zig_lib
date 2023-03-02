const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const meta = @import("../meta.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const attr = @import("./attr.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    //usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/kinds.zig");
};

const Array = mem.StaticArray(u8, 1024 * 1024);

fn variantsToInterface(array: *Array, comptime field_name: []const u8, kind_group: []const out.Index) void {
    array.writeMany("&.{");
    var len: u64 = 0;
    for (kind_group) |impl_index| {
        if (@field(out.impl_variants[impl_index].managers, field_name)) {
            len +%= 1;
            if (len % 8 == 0) array.writeMany("\n   ");
            array.writeFormat(fmt.ud64(impl_index));
            array.writeOne(',');
        }
    }
    array.writeMany("},\n");
}
fn variantsToInterfaces() void {
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("const Index=" ++ @typeName(out.Index) ++ ";\n");
    inline for (@typeInfo(attr.Managers).Struct.fields) |field| {
        array.writeMany("pub const " ++ field.name ++ ":[]const[]const Index=&[_][]const Index{\n");
        for (out.kinds) |kind_group| {
            variantsToInterface(&array, field.name, kind_group);
        }
        array.writeMany("};\n");
    }
    array.writeMany("pub const interfaces:[]const[]const[]const Index=&[_][]const[]const Index{\n");
    inline for (@typeInfo(attr.Managers).Struct.fields) |field| {
        array.writeMany(field.name ++ ",");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "interfaces.zig");
}
pub const main = variantsToInterfaces;
