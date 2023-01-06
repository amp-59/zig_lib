const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const virtual = @import("./virtual.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const render_type_names: bool = false;
pub const render_radix: u16 = 16;
pub const trivial_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .low = 0x40000000, .high = 0x10000000000 }, .{ .low = 0x10000000000, .high = 0x110000000000 },
});
pub const simple_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .low = 0x40000000, .high = 0x10000000000 },
    .{ .low = 0x100000000000, .high = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x110000000000, .high = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x120000000000, .high = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x7f0000000000, .high = 0x800000000000 },
});
pub const complex_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .low = 0x40000000, .high = 0x10000000000 },
    .{ .low = 0x10000000000, .high = 0x20000000000 },
    .{ .low = 0x20000000000, .high = 0x30000000000 },
    .{ .low = 0x30000000000, .high = 0x40000000000 },
    .{ .low = 0x40000000000, .high = 0x50000000000 },
    .{ .low = 0x50000000000, .high = 0x60000000000 },
    .{ .low = 0x60000000000, .high = 0x70000000000 },
    .{ .low = 0x70000000000, .high = 0x80000000000 },
    .{ .low = 0x80000000000, .high = 0x90000000000 },
    .{ .low = 0x90000000000, .high = 0xa0000000000 },
    .{ .low = 0xa0000000000, .high = 0xb0000000000 },
    .{ .low = 0xb0000000000, .high = 0xc0000000000 },
    .{ .low = 0xc0000000000, .high = 0xd0000000000 },
    .{ .low = 0xd0000000000, .high = 0xe0000000000 },
    .{ .low = 0xe0000000000, .high = 0xf0000000000 },
    .{ .low = 0xf0000000000, .high = 0x100000000000 },
    .{ .low = 0x100000000000, .high = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x110000000000, .high = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x120000000000, .high = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x130000000000, .high = 0x140000000000 },
    .{ .low = 0x140000000000, .high = 0x150000000000 },
    .{ .low = 0x150000000000, .high = 0x160000000000 },
    .{ .low = 0x160000000000, .high = 0x170000000000 },
    .{ .low = 0x170000000000, .high = 0x180000000000 },
    .{ .low = 0x180000000000, .high = 0x190000000000 },
    .{ .low = 0x190000000000, .high = 0x1a0000000000 },
    .{ .low = 0x1a0000000000, .high = 0x1b0000000000 },
    .{ .low = 0x1b0000000000, .high = 0x1c0000000000 },
    .{ .low = 0x1c0000000000, .high = 0x1d0000000000 },
    .{ .low = 0x1d0000000000, .high = 0x1e0000000000 },
    .{ .low = 0x1e0000000000, .high = 0x1f0000000000 },
    .{ .low = 0x1f0000000000, .high = 0x200000000000 },
    .{ .low = 0x200000000000, .high = 0x210000000000 },
    .{ .low = 0x210000000000, .high = 0x220000000000 },
    .{ .low = 0x220000000000, .high = 0x230000000000 },
    .{ .low = 0x230000000000, .high = 0x240000000000 },
    .{ .low = 0x240000000000, .high = 0x250000000000 },
    .{ .low = 0x250000000000, .high = 0x260000000000 },
    .{ .low = 0x260000000000, .high = 0x270000000000 },
    .{ .low = 0x270000000000, .high = 0x280000000000 },
    .{ .low = 0x280000000000, .high = 0x290000000000 },
    .{ .low = 0x290000000000, .high = 0x2a0000000000 },
    .{ .low = 0x2a0000000000, .high = 0x2b0000000000 },
    .{ .low = 0x2b0000000000, .high = 0x2c0000000000 },
    .{ .low = 0x2c0000000000, .high = 0x2d0000000000 },
    .{ .low = 0x2d0000000000, .high = 0x2e0000000000 },
    .{ .low = 0x2e0000000000, .high = 0x2f0000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x2f0000000000, .high = 0x300000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x300000000000, .high = 0x310000000000 },
    .{ .low = 0x310000000000, .high = 0x320000000000 },
    .{ .low = 0x320000000000, .high = 0x330000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x330000000000, .high = 0x340000000000 },
    .{ .low = 0x340000000000, .high = 0x350000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x350000000000, .high = 0x360000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x360000000000, .high = 0x370000000000 },
    .{ .low = 0x370000000000, .high = 0x380000000000 },
    .{ .low = 0x380000000000, .high = 0x390000000000 },
    .{ .low = 0x390000000000, .high = 0x3a0000000000 },
    .{ .low = 0x3a0000000000, .high = 0x3b0000000000 },
    .{ .low = 0x3b0000000000, .high = 0x3c0000000000 },
    .{ .low = 0x3c0000000000, .high = 0x3d0000000000 },
    .{ .low = 0x3d0000000000, .high = 0x3e0000000000 },
    .{ .low = 0x3e0000000000, .high = 0x3f0000000000 },
    .{ .low = 0x3f0000000000, .high = 0x400000000000 },
    .{ .low = 0x400000000000, .high = 0x410000000000 },
    .{ .low = 0x410000000000, .high = 0x420000000000 },
    .{ .low = 0x420000000000, .high = 0x430000000000 },
    .{ .low = 0x430000000000, .high = 0x440000000000 },
    .{ .low = 0x440000000000, .high = 0x450000000000 },
    .{ .low = 0x450000000000, .high = 0x460000000000 },
    .{ .low = 0x460000000000, .high = 0x470000000000 },
    .{ .low = 0x470000000000, .high = 0x480000000000 },
    .{ .low = 0x480000000000, .high = 0x490000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x490000000000, .high = 0x4a0000000000 },
    .{ .low = 0x4a0000000000, .high = 0x4b0000000000 },
    .{ .low = 0x4b0000000000, .high = 0x4c0000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x4c0000000000, .high = 0x4d0000000000 },
    .{ .low = 0x4d0000000000, .high = 0x4e0000000000 },
    .{ .low = 0x4e0000000000, .high = 0x4f0000000000 },
    .{ .low = 0x4f0000000000, .high = 0x500000000000 },
    .{ .low = 0x500000000000, .high = 0x510000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x510000000000, .high = 0x520000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x520000000000, .high = 0x530000000000 },
    .{ .low = 0x530000000000, .high = 0x540000000000 },
    .{ .low = 0x540000000000, .high = 0x550000000000 },
    .{ .low = 0x550000000000, .high = 0x560000000000 },
    .{ .low = 0x560000000000, .high = 0x570000000000 },
    .{ .low = 0x570000000000, .high = 0x580000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x580000000000, .high = 0x590000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x590000000000, .high = 0x5a0000000000, .options = .{ .thread_safe = true } },
    .{ .low = 0x5a0000000000, .high = 0x5b0000000000 },
    .{ .low = 0x5b0000000000, .high = 0x5c0000000000 },
    .{ .low = 0x5c0000000000, .high = 0x5d0000000000 },
    .{ .low = 0x5d0000000000, .high = 0x5e0000000000 },
    .{ .low = 0x5e0000000000, .high = 0x5f0000000000 },
    .{ .low = 0x5f0000000000, .high = 0x600000000000 },
    .{ .low = 0x600000000000, .high = 0x610000000000 },
    .{ .low = 0x610000000000, .high = 0x620000000000 },
    .{ .low = 0x620000000000, .high = 0x630000000000 },
    .{ .low = 0x630000000000, .high = 0x640000000000 },
    .{ .low = 0x640000000000, .high = 0x650000000000 },
    .{ .low = 0x650000000000, .high = 0x660000000000 },
    .{ .low = 0x660000000000, .high = 0x670000000000 },
    .{ .low = 0x670000000000, .high = 0x680000000000 },
    .{ .low = 0x680000000000, .high = 0x690000000000 },
    .{ .low = 0x690000000000, .high = 0x6a0000000000 },
    .{ .low = 0x6a0000000000, .high = 0x6b0000000000 },
    .{ .low = 0x6b0000000000, .high = 0x6c0000000000 },
    .{ .low = 0x6c0000000000, .high = 0x6d0000000000 },
    .{ .low = 0x6d0000000000, .high = 0x6e0000000000 },
    .{ .low = 0x6e0000000000, .high = 0x6f0000000000 },
    .{ .low = 0x6f0000000000, .high = 0x700000000000 },
    .{ .low = 0x700000000000, .high = 0x710000000000 },
    .{ .low = 0x710000000000, .high = 0x720000000000 },
    .{ .low = 0x720000000000, .high = 0x730000000000 },
    .{ .low = 0x730000000000, .high = 0x740000000000 },
    .{ .low = 0x740000000000, .high = 0x750000000000 },
    .{ .low = 0x750000000000, .high = 0x760000000000 },
    .{ .low = 0x760000000000, .high = 0x770000000000 },
    .{ .low = 0x770000000000, .high = 0x780000000000 },
    .{ .low = 0x780000000000, .high = 0x790000000000 },
    .{ .low = 0x790000000000, .high = 0x7a0000000000 },
    .{ .low = 0x7a0000000000, .high = 0x7b0000000000 },
    .{ .low = 0x7b0000000000, .high = 0x7c0000000000 },
    .{ .low = 0x7c0000000000, .high = 0x7d0000000000 },
    .{ .low = 0x7d0000000000, .high = 0x7e0000000000 },
    .{ .low = 0x7e0000000000, .high = 0x7f0000000000 },
    .{ .low = 0x7f0000000000, .high = 0x800000000000 },
});

const FormulaicThreadSpaceSpec = struct {
    AddressSpace: type,
    stack_size: usize,
    count: usize,
};
pub fn FormulaicThreadSpace(comptime spec: FormulaicThreadSpaceSpec) type {
    return struct {
        comptime {
            const AddressSpace = spec.AddressSpace;
            builtin.assertBelowOrEqual(AddressSpace.Index, spec.arena_index, AddressSpace.max_idx);
        }
    };
}

fn testFormulaicAddressSpace() !void {
    const AddressSpace = virtual.GenericFormulaicAddressSpace(.{ .divisions = 8 });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    const Array = Allocator.StructuredVector(u8);
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = try Array.init(&allocator, 8192);
    defer array.deinit(&allocator);
    comptime var i: u8 = 1;
    try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
    inline while (i != AddressSpace.addr_spec.divisions) : (i += 1) {
        try mem.acquire(.{ .options = .{ .thread_safe = AddressSpace.addr_spec.options.thread_safe } }, &address_space, i);
        try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
}
fn testExactAddressSpace() !void {
    const AddressSpace = virtual.GenericExactAddressSpace(.{ .list = trivial_list });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    const Array = Allocator.StructuredVector(u8);
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = try Array.init(&allocator, 8192);
    defer array.deinit(&allocator);
    comptime var i: u8 = 1;
    try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        try mem.static.acquire(.{ .options = .{ .thread_safe = AddressSpace.addr_spec.list[i].options.thread_safe } }, &address_space, i);
        try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
    i = 1;
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        try mem.static.release(.{ .options = .{ .thread_safe = AddressSpace.addr_spec.list[i].options.thread_safe } }, &address_space, i);
        try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
}
pub fn main() !void {
    try meta.wrap(testExactAddressSpace());
    try meta.wrap(testFormulaicAddressSpace());
}
