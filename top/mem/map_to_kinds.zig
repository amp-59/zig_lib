const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const builtin = @import("../builtin.zig");
const gen = @import("./gen.zig");
const out = struct {
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
};

pub usingnamespace proc.start;

const Array = mem.StaticArray(u8, 1024 * 1024);
const Keys = gen.GenericKeys(Key, 256);
const Key = struct { kind: out.Kind };

pub fn mapToKinds() void {
    const keys: Keys = Keys.init(out.Canonical, out.canonicals);
    var array: Array = undefined;
    array.undefineAll();
    gen.writeImport(&array, "out", "./impl_variants.zig");
    array.writeMany("pub const kinds: []const []const out.Index = &[_][]const out.Index{\n");
    for (keys.values[0..keys.len]) |key| {
        array.writeMany("&.{");
        for (out.canonicals, 0..) |canonical, index| {
            if (key.kind == canonical.kind) {
                array.writeFormat(fmt.ud64(index));
                array.writeMany(",");
            }
        }
        array.overwriteManyBack("}");
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "kinds.zig");
}
pub const main = mapToKinds;
