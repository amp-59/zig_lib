const mem = @import("./../mem.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen.zig");

const out = struct {
    usingnamespace @import("./zig-out/src/memgen_canonical.zig");
    usingnamespace @import("./zig-out/src/memgen_canonicals.zig");
};

/// Containers are grouped by layout, kind, and mode.
const Container = struct {
    out.Layout,
    out.Kind,
    out.Mode,
};
const Keys = mem.StaticArray(Container, 256);

fn writeOneUnique(keys: *Keys, value: Container) void {
    for (keys.readAll()) |unique| {
        if (builtin.testEqual(Container, value, unique)) return;
    }
    keys.writeOne(value);
}

fn getKeys() Keys {
    var keys: Keys = undefined;
    keys.undefineAll();
    for (out.canonicals) |canonical| {
        writeOneUnique(&keys, .{ canonical.layout, canonical.kind, canonical.mode });
    }
    return keys;
}
fn mapToContainers(array: *gen.String) void {
    const keys: Keys = getKeys();
    array.writeMany("pub const containers: []const []const u16 = &[_][]const u16{\n");
    for (keys.readAll()) |key| {
        array.writeMany("    &.{ ");
        for (out.canonicals) |canonical, index| {
            const container: Container = .{
                canonical.layout,
                canonical.kind,
                canonical.mode,
            };
            if (builtin.testEqual(Container, key, container)) {
                gen.writeIndex(array, @intCast(u16, index));
                array.writeMany(", ");
            }
        }
        array.overwriteManyBack(" }");
        array.writeMany(",\n");
    }
    array.writeMany("};\n");
    gen.writeFile(array, "memgen_containers.zig");
}

pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    mapToContainers(&array);
    gen.exit(0);
}
