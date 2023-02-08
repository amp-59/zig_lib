const mem = @import("./../mem.zig");
const builtin = @import("./../builtin.zig");

const gen = @import("./gen.zig");

const out = struct {
    usingnamespace @import("./zig-out/src/memgen_canonical.zig");
    usingnamespace @import("./zig-out/src/memgen_canonicals.zig");
    usingnamespace @import("./zig-out/src/memgen_containers.zig");
};

const Keys = mem.StaticArray(out.Specifier, 256);

fn writeOneUnique(keys: *Keys, value: out.Specifier) void {
    for (keys.readAll()) |unique| {
        if (value == unique) return;
    }
    keys.writeOne(value);
}
fn getKeys() Keys {
    var keys: Keys = undefined;
    keys.undefineAll();
    for (out.canonicals) |canonical| {
        writeOneUnique(&keys, canonical.spec);
    }
    return keys;
}
fn mapToContainers(array: *gen.String) void {
    const keys: Keys = getKeys();
    array.writeMany("pub const container_specifications: []const []const []const u16 = &[_][]const []const u16{\n");
    for (out.containers) |indices| {
        array.writeMany("&.{");
        for (keys.readAll()) |key| {
            array.writeMany("&.{");
            const len: u64 = array.len();
            for (indices) |index| {
                if (out.canonicals[index].spec == key) {
                    gen.writeIndex(array, @intCast(u16, index));
                    array.writeMany(", ");
                }
            }
            if (len == array.len()) {
                array.writeMany("},");
            } else {
                array.overwriteManyBack(" }");
                array.writeMany(",");
            }
        }
        array.writeMany("},");
    }
    array.writeMany("};\n");
    gen.writeFile(array, "memgen_container_specifications.zig");
}

pub export fn _start() noreturn {
    @setAlignStack(16);
    var buf: [1024 * 1024]u8 = undefined;
    var array: gen.String = gen.String.init(&buf);
    mapToContainers(&array);
    gen.exit(0);
}
