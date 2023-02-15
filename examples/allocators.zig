const srg = @import("zig_lib");
const mem = srg.mem;
const fmt = srg.fmt;
const proc = srg.proc;
const meta = srg.meta;
const preset = srg.preset;
const virtual = srg.virtual;
const testing = srg.testing;

pub const AddressSpace = virtual.GenericRegularAddressSpace(multi_arena);

pub usingnamespace proc.start;

const Allocator = mem.GenericRtArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .logging = preset.allocator.logging.verbose,
    .options = preset.allocator.options.small,
});
const Allocators = mem.StaticArray(Allocator, count);

// This is 1GiB. I allow this much for the binary mapping. Not sure if sound,
// but the binary mapping should start at ~64K, so it would need to be big to
// overlap. If it did the program would abort due to MAP_FIXED_NOREPLACE.
const start: u64 = 0x40000000;
// Also 1GiB. Would rather not do something weird like size = start.
// This is the size of each arena.
const size: u64 = 1024 * 1024 * 1024;
const count: u64 = 1024;
const finish: u64 = start + (size * count);

const multi_arena: virtual.RegularMultiArena = .{
    .label = "1024x1GiB",
    .lb_addr = start,
    .ab_addr = start,
    .up_addr = finish,
    .divisions = count,
};

fn init(address_space: *AddressSpace, allocators: *Allocators) !void {
    var arena_index: u16 = 0;
    while (arena_index != count) : (arena_index +%= 1) {
        allocators.referOneAt(arena_index).* = try Allocator.init(address_space, arena_index);
    }
}
fn deinit(address_space: *AddressSpace, allocators: *Allocators) void {
    var arena_index: u16 = 0;
    while (arena_index != count) : (arena_index +%= 1) {
        allocators.referOneAt(arena_index).deinit(address_space);
    }
}

pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocators: Allocators = undefined;
    allocators.undefineAll();

    try init(&address_space, &allocators);
    defer deinit(&address_space, &allocators);
}
