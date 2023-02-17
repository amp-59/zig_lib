const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const meta = @import("../meta.zig");
const builtin = @import("../builtin.zig");

const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./detail.zig");
    usingnamespace @import("./detail_more.zig");

    usingnamespace @import("./zig-out/src/type_specs.zig");
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
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
    gen.writeImports(array, @src(), &.{.{ .name = "out", .path = "./canonical.zig" }});
    array.writeMany("pub const canonicals: []const out.Canonical = &[_]out.Canonical{\n");
    for (out.impl_variants) |variant| {
        array.writeMany("    ");
        gen.writeStructOfEnum(array, out.Canonical, out.Canonical.convert(variant));
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(array, "canonicals.zig");
}
pub export fn _start() noreturn {
    @setAlignStack(16);
    var array: gen.String = undefined;
    array.undefineAll();
    variantsToCanonical(&array);
    sys.call(.exit, .{}, noreturn, .{0});
}
