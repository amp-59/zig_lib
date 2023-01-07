const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const preset = @import("./preset.zig");
const virtual = @import("./virtual.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
pub usingnamespace proc.start;
pub const is_verbose: bool = false;
pub const render_type_names: bool = false;
pub const render_radix: u16 = 2;
pub const trivial_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x40000000, .up_addr = 0x10000000000 }, .{ .lb_addr = 0x10000000000, .up_addr = 0x110000000000 },
});
pub const simple_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x40000000, .up_addr = 0x10000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
});
pub const rare_sub_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x40000000, .up_addr = 0x10000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
});
pub const complex_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x40000000, .up_addr = 0x10000000000 },
    .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
    .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
    .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
    .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
    .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
    .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
    .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
    .{ .lb_addr = 0x80000000000, .up_addr = 0x90000000000 },
    .{ .lb_addr = 0x90000000000, .up_addr = 0xa0000000000 },
    .{ .lb_addr = 0xa0000000000, .up_addr = 0xb0000000000 },
    .{ .lb_addr = 0xb0000000000, .up_addr = 0xc0000000000 },
    .{ .lb_addr = 0xc0000000000, .up_addr = 0xd0000000000 },
    .{ .lb_addr = 0xd0000000000, .up_addr = 0xe0000000000 },
    .{ .lb_addr = 0xe0000000000, .up_addr = 0xf0000000000 },
    .{ .lb_addr = 0xf0000000000, .up_addr = 0x100000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x130000000000, .up_addr = 0x140000000000 },
    .{ .lb_addr = 0x140000000000, .up_addr = 0x150000000000 },
    .{ .lb_addr = 0x150000000000, .up_addr = 0x160000000000 },
    .{ .lb_addr = 0x160000000000, .up_addr = 0x170000000000 },
    .{ .lb_addr = 0x170000000000, .up_addr = 0x180000000000 },
    .{ .lb_addr = 0x180000000000, .up_addr = 0x190000000000 },
    .{ .lb_addr = 0x190000000000, .up_addr = 0x1a0000000000 },
    .{ .lb_addr = 0x1a0000000000, .up_addr = 0x1b0000000000 },
    .{ .lb_addr = 0x1b0000000000, .up_addr = 0x1c0000000000 },
    .{ .lb_addr = 0x1c0000000000, .up_addr = 0x1d0000000000 },
    .{ .lb_addr = 0x1d0000000000, .up_addr = 0x1e0000000000 },
    .{ .lb_addr = 0x1e0000000000, .up_addr = 0x1f0000000000 },
    .{ .lb_addr = 0x1f0000000000, .up_addr = 0x200000000000 },
    .{ .lb_addr = 0x200000000000, .up_addr = 0x210000000000 },
    .{ .lb_addr = 0x210000000000, .up_addr = 0x220000000000 },
    .{ .lb_addr = 0x220000000000, .up_addr = 0x230000000000 },
    .{ .lb_addr = 0x230000000000, .up_addr = 0x240000000000 },
    .{ .lb_addr = 0x240000000000, .up_addr = 0x250000000000 },
    .{ .lb_addr = 0x250000000000, .up_addr = 0x260000000000 },
    .{ .lb_addr = 0x260000000000, .up_addr = 0x270000000000 },
    .{ .lb_addr = 0x270000000000, .up_addr = 0x280000000000 },
    .{ .lb_addr = 0x280000000000, .up_addr = 0x290000000000 },
    .{ .lb_addr = 0x290000000000, .up_addr = 0x2a0000000000 },
    .{ .lb_addr = 0x2a0000000000, .up_addr = 0x2b0000000000 },
    .{ .lb_addr = 0x2b0000000000, .up_addr = 0x2c0000000000 },
    .{ .lb_addr = 0x2c0000000000, .up_addr = 0x2d0000000000 },
    .{ .lb_addr = 0x2d0000000000, .up_addr = 0x2e0000000000 },
    .{ .lb_addr = 0x2e0000000000, .up_addr = 0x2f0000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x2f0000000000, .up_addr = 0x300000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x300000000000, .up_addr = 0x310000000000 },
    .{ .lb_addr = 0x310000000000, .up_addr = 0x320000000000 },
    .{ .lb_addr = 0x320000000000, .up_addr = 0x330000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x330000000000, .up_addr = 0x340000000000 },
    .{ .lb_addr = 0x340000000000, .up_addr = 0x350000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x350000000000, .up_addr = 0x360000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x360000000000, .up_addr = 0x370000000000 },
    .{ .lb_addr = 0x370000000000, .up_addr = 0x380000000000 },
    .{ .lb_addr = 0x380000000000, .up_addr = 0x390000000000 },
    .{ .lb_addr = 0x390000000000, .up_addr = 0x3a0000000000 },
    .{ .lb_addr = 0x3a0000000000, .up_addr = 0x3b0000000000 },
    .{ .lb_addr = 0x3b0000000000, .up_addr = 0x3c0000000000 },
    .{ .lb_addr = 0x3c0000000000, .up_addr = 0x3d0000000000 },
    .{ .lb_addr = 0x3d0000000000, .up_addr = 0x3e0000000000 },
    .{ .lb_addr = 0x3e0000000000, .up_addr = 0x3f0000000000 },
    .{ .lb_addr = 0x3f0000000000, .up_addr = 0x400000000000 },
    .{ .lb_addr = 0x400000000000, .up_addr = 0x410000000000 },
    .{ .lb_addr = 0x410000000000, .up_addr = 0x420000000000 },
    .{ .lb_addr = 0x420000000000, .up_addr = 0x430000000000 },
    .{ .lb_addr = 0x430000000000, .up_addr = 0x440000000000 },
    .{ .lb_addr = 0x440000000000, .up_addr = 0x450000000000 },
    .{ .lb_addr = 0x450000000000, .up_addr = 0x460000000000 },
    .{ .lb_addr = 0x460000000000, .up_addr = 0x470000000000 },
    .{ .lb_addr = 0x470000000000, .up_addr = 0x480000000000 },
    .{ .lb_addr = 0x480000000000, .up_addr = 0x490000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x490000000000, .up_addr = 0x4a0000000000 },
    .{ .lb_addr = 0x4a0000000000, .up_addr = 0x4b0000000000 },
    .{ .lb_addr = 0x4b0000000000, .up_addr = 0x4c0000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x4c0000000000, .up_addr = 0x4d0000000000 },
    .{ .lb_addr = 0x4d0000000000, .up_addr = 0x4e0000000000 },
    .{ .lb_addr = 0x4e0000000000, .up_addr = 0x4f0000000000 },
    .{ .lb_addr = 0x4f0000000000, .up_addr = 0x500000000000 },
    .{ .lb_addr = 0x500000000000, .up_addr = 0x510000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x510000000000, .up_addr = 0x520000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x520000000000, .up_addr = 0x530000000000 },
    .{ .lb_addr = 0x530000000000, .up_addr = 0x540000000000 },
    .{ .lb_addr = 0x540000000000, .up_addr = 0x550000000000 },
    .{ .lb_addr = 0x550000000000, .up_addr = 0x560000000000 },
    .{ .lb_addr = 0x560000000000, .up_addr = 0x570000000000 },
    .{ .lb_addr = 0x570000000000, .up_addr = 0x580000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x580000000000, .up_addr = 0x590000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x590000000000, .up_addr = 0x5a0000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x5a0000000000, .up_addr = 0x5b0000000000 },
    .{ .lb_addr = 0x5b0000000000, .up_addr = 0x5c0000000000 },
    .{ .lb_addr = 0x5c0000000000, .up_addr = 0x5d0000000000 },
    .{ .lb_addr = 0x5d0000000000, .up_addr = 0x5e0000000000 },
    .{ .lb_addr = 0x5e0000000000, .up_addr = 0x5f0000000000 },
    .{ .lb_addr = 0x5f0000000000, .up_addr = 0x600000000000 },
    .{ .lb_addr = 0x600000000000, .up_addr = 0x610000000000 },
    .{ .lb_addr = 0x610000000000, .up_addr = 0x620000000000 },
    .{ .lb_addr = 0x620000000000, .up_addr = 0x630000000000 },
    .{ .lb_addr = 0x630000000000, .up_addr = 0x640000000000 },
    .{ .lb_addr = 0x640000000000, .up_addr = 0x650000000000 },
    .{ .lb_addr = 0x650000000000, .up_addr = 0x660000000000 },
    .{ .lb_addr = 0x660000000000, .up_addr = 0x670000000000 },
    .{ .lb_addr = 0x670000000000, .up_addr = 0x680000000000 },
    .{ .lb_addr = 0x680000000000, .up_addr = 0x690000000000 },
    .{ .lb_addr = 0x690000000000, .up_addr = 0x6a0000000000 },
    .{ .lb_addr = 0x6a0000000000, .up_addr = 0x6b0000000000 },
    .{ .lb_addr = 0x6b0000000000, .up_addr = 0x6c0000000000 },
    .{ .lb_addr = 0x6c0000000000, .up_addr = 0x6d0000000000 },
    .{ .lb_addr = 0x6d0000000000, .up_addr = 0x6e0000000000 },
    .{ .lb_addr = 0x6e0000000000, .up_addr = 0x6f0000000000 },
    .{ .lb_addr = 0x6f0000000000, .up_addr = 0x700000000000 },
    .{ .lb_addr = 0x700000000000, .up_addr = 0x710000000000 },
    .{ .lb_addr = 0x710000000000, .up_addr = 0x720000000000 },
    .{ .lb_addr = 0x720000000000, .up_addr = 0x730000000000 },
    .{ .lb_addr = 0x730000000000, .up_addr = 0x740000000000 },
    .{ .lb_addr = 0x740000000000, .up_addr = 0x750000000000 },
    .{ .lb_addr = 0x750000000000, .up_addr = 0x760000000000 },
    .{ .lb_addr = 0x760000000000, .up_addr = 0x770000000000 },
    .{ .lb_addr = 0x770000000000, .up_addr = 0x780000000000 },
    .{ .lb_addr = 0x780000000000, .up_addr = 0x790000000000 },
    .{ .lb_addr = 0x790000000000, .up_addr = 0x7a0000000000 },
    .{ .lb_addr = 0x7a0000000000, .up_addr = 0x7b0000000000 },
    .{ .lb_addr = 0x7b0000000000, .up_addr = 0x7c0000000000 },
    .{ .lb_addr = 0x7c0000000000, .up_addr = 0x7d0000000000 },
    .{ .lb_addr = 0x7d0000000000, .up_addr = 0x7e0000000000 },
    .{ .lb_addr = 0x7e0000000000, .up_addr = 0x7f0000000000 },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
});

fn testFormulaicAddressSpace() !void {
    const AddressSpace = virtual.GenericFormulaicAddressSpace(.{ .params = .{ .divisions = 8 } });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    const Array = Allocator.StructuredVector(u8);
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = try Array.init(&allocator, 8192);
    defer array.deinit(&allocator);
    var i: u8 = 1;
    try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
    while (i != AddressSpace.addr_spec.params.divisions) : (i += 1) {
        try mem.acquire(.{ .options = .{ .thread_safe = AddressSpace.addr_spec.options.thread_safe } }, &address_space, i);
        try array.appendAny(mem.fmt_wr_spec, &allocator, .{ fmt.any(address_space), '\n' });
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
}
fn testExactAddressSpace(comptime list: anytype) !void {
    const AddressSpace = virtual.GenericExactAddressSpace(.{ .list = list });
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
fn testExactSubSpaceFromExact(comptime sup_spec: virtual.ExactAddressSpaceSpec, comptime sub_spec: virtual.ExactAddressSpaceSpec) !void {
    const AddressSpace = virtual.GenericExactAddressSpace(sup_spec);
    const SubAddressSpace = virtual.GenericExactSubAddressSpace(sub_spec, AddressSpace);
    comptime var address_space_init: AddressSpace = .{};
    var sub_space: SubAddressSpace = address_space_init.reserve(SubAddressSpace);
    const Allocator0 = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubAddressSpace, .errors = preset.allocator.errors.noexcept });
    const Allocator1 = mem.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubAddressSpace, .errors = preset.allocator.errors.noexcept });
    const Allocator2 = mem.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubAddressSpace, .errors = preset.allocator.errors.noexcept });
    const Array0 = Allocator0.StructuredVector(u8);
    const Array1 = Allocator1.StructuredVector(u8);
    const Array2 = Allocator2.StructuredVector(u8);
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var array_0: Array0 = try Array0.init(&allocator_0, 16);
    defer array_0.deinit(&allocator_0);
    array_0.appendAny(mem.fmt_wr_spec, &allocator_0, .{ fmt.any(meta.uniformData(sub_space)), '\n' });
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var array_1: Array1 = try Array1.init(&allocator_1, 16);
    defer array_1.deinit(&allocator_1);
    array_1.appendAny(mem.fmt_wr_spec, &allocator_1, .{ fmt.any(meta.uniformData(sub_space)), '\n' });
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
    var array_2: Array2 = try Array2.init(&allocator_2, 16);
    defer array_2.deinit(&allocator_2);
    array_2.appendAny(mem.fmt_wr_spec, &allocator_2, .{ fmt.any(meta.uniformData(sub_space)), '\n' });
    file.noexcept.write(2, array_0.readAll());
    array_0.undefineAll();
    file.noexcept.write(2, array_1.readAll());
    array_1.undefineAll();
    file.noexcept.write(2, array_2.readAll());
    array_2.undefineAll();
}
pub fn main() !void {
    try meta.wrap(testExactAddressSpace(trivial_list));
    try meta.wrap(testExactAddressSpace(complex_list));
    try meta.wrap(testExactAddressSpace(simple_list));
    try meta.wrap(testFormulaicAddressSpace());
    try meta.wrap(testExactSubSpaceFromExact(.{ .list = simple_list }, .{ .list = rare_sub_list }));
}
