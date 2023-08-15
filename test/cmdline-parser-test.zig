const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const elf = zl.elf;
const file = zl.file;
const proc = zl.proc;
const mach = zl.mach;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

var s: struct { x: ?usize = null, y: usize = 50 } = .{};

const DynamicLoader = elf.GenericDynamicLoader(.{});

fn writeField(array: *mem.StaticArray(u8, 4096), field_name: []const u8, field_value: anytype) void {
    array.writeOne('.');
    array.writeMany(field_name);
    array.writeMany(" = ");
    array.writeFormat(fmt.render(.{}, field_value));
    array.writeMany(", ");
}
pub fn main(args: anytype) !void {
    var allocator: mem.SimpleAllocator = .{};
    var ptrs: build.Fns = .{};
    var loader: DynamicLoader = .{};
    const info: *DynamicLoader.Info = try loader.load("zig-out/lib/libzero-cmd_parsers.so");
    info.loadPointers(build.Fns, &ptrs);

    var cmd: build.BuildCommand = .{ .kind = .exe };
    ptrs.formatParseArgsBuildCommand(&cmd, &allocator, args.ptr, args.len);
    var array: mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeMany("node.addBuild(allocator, .{ ");
    inline for (@typeInfo(build.BuildCommand).Struct.fields) |field| {
        if (@typeInfo(field.type) == .Optional) {
            if (@field(cmd, field.name)) |field_value| {
                writeField(&array, field.name, field_value);
            }
        } else {
            if (field.default_value) |ptr| {
                if (@field(cmd, field.name) != mem.pointerOpaque(field.type, ptr).*) {
                    writeField(&array, field.name, @field(cmd, field.name));
                }
            } else {
                writeField(&array, field.name, @field(cmd, field.name));
            }
        }
    }
    array.writeMany("}, \"");
    if (cmd.name) |name| {
        array.writeMany(name);
    } else {
        array.writeMany("anonymous");
    }
    array.writeMany("\", \"<path>\");\n");
    debug.write(array.readAll());
}
