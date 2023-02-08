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

const Container = struct { out.Layout, out.Kind, out.Mode };
const Uniques = mem.StaticArray(Container, 256);

fn writeOneUnique(uniques: *Uniques, value: Container) void {
    for (uniques.readAll()) |unique| {
        if (builtin.testEqual(Container, value, unique)) return;
    }
    uniques.writeOne(value);
}
fn variantsToCanonical(array: *gen.String) void {
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "./memgen_canonical.zig" }});
    array.writeMany("pub const canonicals: []const out.Canonical = &[_]out.Canonical{\n");
    for (out.variants) |variant| {
        array.writeMany("    ");
        gen.writeStructOfEnum(array, out.Canonical, out.Canonical.convert(variant));
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeFile(array, "memgen_canonicals.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    variantsToCanonical(&array);
    gen.exit(0);
}
