const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const AddressSpace = mem.spec.address_space.exact_8;

pub fn main() !void {
    const Allocator = mem.dynamic.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    try file.write(.{}, 1, fmt.typeDescr(.{
        .decls = true,
    }, zl.file));
}
