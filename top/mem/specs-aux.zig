const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const builtin = gen.builtin;

const out = struct {
    usingnamespace @import("./zig-out/src/impl_variants.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
    usingnamespace @import("./zig-out/src/containers.zig");
};
pub usingnamespace proc.start;

const Array = mem.StaticArray(u8, 1024 * 1024);
const Keys = gen.GenericKeys(struct { spec: out.Specifier }, 256);

fn mapToContainers() void {
    const keys: Keys = Keys.init(out.Canonical, out.canonicals);
    var array: Array = undefined;
    array.undefineAll();
    array.writeMany("const Index=" ++ @typeName(out.Index) ++ ";\n");
    array.writeMany("pub const specifications:[]const[]const[]const Index=&[_][]const[]const Index{\n");
    for (out.containers) |indices| {
        array.writeMany("&.{");
        for (keys.values[0..keys.len]) |key| {
            if (indices.len == 0) {
                array.writeMany("&.{},");
            } else {
                array.writeMany("&.{");
                for (indices) |index| {
                    if (out.canonicals[index].spec == key.spec) {
                        array.writeFormat(fmt.ud64(index));
                        array.writeMany(",");
                    }
                }
                array.undefine(builtin.int(u1, array.readOneBack() != '{'));
                array.writeMany("},");
            }
        }
        array.writeMany("},");
    }
    array.writeMany("};\n");
    gen.writeAuxiliarySourceFile(&array, "specifications.zig");
}
pub const main = mapToContainers;
