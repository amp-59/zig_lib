const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const builtin = gen.builtin;
const out = struct {
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
};
pub usingnamespace proc.start;
const Array = mem.StaticArray(u8, 1024 * 1024);
const Keys = gen.GenericKeys(Key, 256);
const Key = struct { kind: out.Kind };
pub fn kinds() void {
    const keys: Keys = Keys.init(out.Canonical, out.canonicals);
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("const Index=" ++ @typeName(out.Index) ++ ";\n");
    array.writeMany("pub const kinds:[]const[]const Index = &[_][]const Index{\n");
    for (keys.values[0..keys.len]) |key| {
        var len: u64 = 0;
        array.writeMany("&.{");
        for (out.canonicals, 0..) |canonical, index| {
            if (key.kind == canonical.kind) {
                len +%= 1;
                if (len % 8 == 0) array.writeMany("\n   ");
                array.writeFormat(fmt.ud64(index));
                array.writeMany(",");
            }
        }
        array.writeMany("},\n");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "kinds.zig");
}
pub const main = kinds;
