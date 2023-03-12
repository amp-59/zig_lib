const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const preset = gen.preset;
const builtin = gen.builtin;
const out = struct {
    usingnamespace @import("./zig-out/src/config.zig");
    usingnamespace @import("./zig-out/src/canonical.zig");
    usingnamespace @import("./zig-out/src/canonicals.zig");
};

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

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
    array.writeMany("pub const containers:[]const[]const Index=&[_][]const Index{\n");
    var keys: Keys = Keys.init(out.Canonical, out.canonicals);
    for (keys.values[0..keys.len]) |key| {
        array.writeMany("&.{");
        for (out.canonicals, 0..) |canonical, index| {
            if (builtin.testEqual(Container, key, .{
                .layout = canonical.layout,
                .kind = canonical.kind,
                .mode = canonical.mode,
            })) {
                array.writeFormat(fmt.ud64(index));
                array.writeMany(",");
            }
        }
        array.overwriteManyBack("}");
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    array.writeMany("const Index=" ++ @typeName(out.Index) ++ ";");

    gen.writeAuxiliarySourceFile(&array, "containers.zig");
}
pub const main = mapToContainers;
