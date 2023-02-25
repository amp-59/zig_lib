const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
};
const Array = mem.StaticArray(u8, 1024 * 1024);
const Keys = gen.GenericKeys(Container, 256);
const Container = struct {
    layout: out.Layout,
    kind: out.Kind,
    mode: out.Mode,
};
fn mapToContainers() void {
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("pub const containers: []const []const u8 = &[_][]const u8{\n");
    var keys: Keys = Keys.init(out.Canonical, out.canonicals);
    for (keys.auto[0..keys.len]) |key| {
        array.writeMany("    &.{ ");
        for (out.canonicals, 0..) |canonical, index| {
            if (builtin.testEqual(Container, key, .{
                .layout = canonical.layout,
                .kind = canonical.kind,
                .mode = canonical.mode,
            })) {
                array.writeFormat(fmt.ud64(index));
                array.writeMany(", ");
            }
        }
        array.overwriteManyBack(" }");
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "containers.zig");
}
pub const main = mapToContainers;
