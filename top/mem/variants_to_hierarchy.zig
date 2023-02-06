const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/memgen_type_spec.zig");
    usingnamespace @import("./zig-out/src/memgen_variants.zig");
    usingnamespace @import("./zig-out/src/memgen_canonical.zig");
};

fn detailToHierarchy(array: *gen.String) void {
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "../../detail_full.zig" }});
    array.writeMany("pub const hierarchy: out.DetailFull = [_]out.DetailFull{\n");
    for (out.variants) |variant| {
        array.writeMany("    .{ .");
        array.writeMany(@tagName(out.Kind.convert(variant.kinds)));
        array.writeMany(", .");
        array.writeMany(@tagName(out.Mode.convert(variant.modes)));
        array.writeMany(", .");
        array.writeMany(@tagName(out.Field.convert(variant.fields)));
        array.writeMany(", .");
        array.writeMany(@tagName(out.Technique.convert(variant.techs)));
        array.writeMany(", .");
        array.writeMany(@tagName(out.Specifier.convert(variant.specs)));
        array.writeMany(" },\n");
    }
    array.writeMany("};\n");
    gen.writeFile(array, "memgen_hierarchy.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    detailToHierarchy(&array);
    gen.exit(0);
}
