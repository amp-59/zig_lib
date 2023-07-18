const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const spec = zl.spec;
const virtual = zl.virtual;
const testing = zl.testing;

pub usingnamespace zl.start;
pub const AddressSpace = virtual.GenericRegularAddressSpace(multi_arena);

// This is 1GiB. I allow this much for the binary mapping. Not sure if sound,
// but the binary mapping should start at ~64K, so it would need to be big to
// overlap. If it did the program would abort due to MAP_FIXED_NOREPLACE.
const start: u64 = 0x40000000;
const size: u64 = 1024 * 1024;
const count: u64 = 1024;
const finish: u64 = start + (size * count);

const Allocator = mem.GenericRtArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .logging = spec.allocator.logging.verbose,
    .options = .{
        .require_map = false,
        .require_unmap = false,
    },
});
const multi_arena: virtual.RegularMultiArena = .{
    .label = "1024x1MiB",
    .lb_addr = start,
    .up_addr = finish,
    .divisions = count,
    .logging = spec.address_space.logging.verbose,
    .options = .{
        .require_map = true,
        .require_unmap = true,
    },
};

const Allocators = mem.StaticArray(Allocator, count);

fn init(address_space: *AddressSpace, allocators: *Allocators) !void {
    var arena_index: AddressSpace.Index = 0;
    while (arena_index != count) : (arena_index +%= 1) {
        allocators.referOneAt(arena_index).* = try Allocator.init(address_space, arena_index);
    }
}
fn deinit(address_space: *AddressSpace, allocators: *Allocators) void {
    var arena_index: AddressSpace.Index = 0;
    while (arena_index != count) : (arena_index +%= 1) {
        allocators.referOneAt(arena_index).deinit(address_space, arena_index);
    }
}
pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocators: Allocators = undefined;
    allocators.undefineAll();

    try init(&address_space, &allocators);
    defer deinit(&address_space, &allocators);
}
