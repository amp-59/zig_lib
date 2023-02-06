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
pub usingnamespace root;

const root = opaque {
    pub const AddressSpace = preset.address_space.regular_128;
};

const PrintArray = mem.StaticString(16384);

pub const is_verbose: bool = false;
pub const runtime_assertions: bool = true;
pub const render_type_names: bool = false;
pub const render_radix: u16 = 10;
pub const trivial_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x000004000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x010000000000, .up_addr = 0x110000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
});
pub const simple_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
});
pub const rare_sub_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
});
// zig fmt: off
pub const complex_list: []const virtual.Arena = meta.slice(virtual.Arena, .{
    .{ .lb_addr = 0x0f0000000000, .up_addr = 0x100000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x130000000000, .up_addr = 0x140000000000 }, // [X]
    .{ .lb_addr = 0x140000000000, .up_addr = 0x150000000000 }, // [X]
    .{ .lb_addr = 0x150000000000, .up_addr = 0x160000000000 },
    .{ .lb_addr = 0x2a0000000000, .up_addr = 0x2b0000000000 },
    .{ .lb_addr = 0x2d0000000000, .up_addr = 0x2e0000000000 }, // [X]
    .{ .lb_addr = 0x2e0000000000, .up_addr = 0x2f0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x2f0000000000, .up_addr = 0x300000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x300000000000, .up_addr = 0x310000000000 },
    .{ .lb_addr = 0x310000000000, .up_addr = 0x320000000000 }, // [X]
    .{ .lb_addr = 0x320000000000, .up_addr = 0x330000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x330000000000, .up_addr = 0x340000000000 },
    .{ .lb_addr = 0x340000000000, .up_addr = 0x350000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x350000000000, .up_addr = 0x360000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x360000000000, .up_addr = 0x370000000000 }, // [X]
    .{ .lb_addr = 0x370000000000, .up_addr = 0x380000000000 }, // [X]
    .{ .lb_addr = 0x380000000000, .up_addr = 0x390000000000 }, // [X]
    .{ .lb_addr = 0x390000000000, .up_addr = 0x3a0000000000 }, // [X]
    .{ .lb_addr = 0x430000000000, .up_addr = 0x440000000000 },
    .{ .lb_addr = 0x440000000000, .up_addr = 0x450000000000 },
    .{ .lb_addr = 0x450000000000, .up_addr = 0x460000000000 },
    .{ .lb_addr = 0x460000000000, .up_addr = 0x470000000000 },
    .{ .lb_addr = 0x470000000000, .up_addr = 0x480000000000 },
    .{ .lb_addr = 0x480000000000, .up_addr = 0x490000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x490000000000, .up_addr = 0x4a0000000000 }, // [X]
    .{ .lb_addr = 0x4a0000000000, .up_addr = 0x4b0000000000 },
    .{ .lb_addr = 0x4b0000000000, .up_addr = 0x4c0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x4c0000000000, .up_addr = 0x4d0000000000 }, // [X]
    .{ .lb_addr = 0x4d0000000000, .up_addr = 0x4e0000000000 },
    .{ .lb_addr = 0x4e0000000000, .up_addr = 0x4f0000000000 },
    .{ .lb_addr = 0x4f0000000000, .up_addr = 0x500000000000 }, // [X]
    .{ .lb_addr = 0x500000000000, .up_addr = 0x510000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x510000000000, .up_addr = 0x520000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x520000000000, .up_addr = 0x530000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x530000000000, .up_addr = 0x540000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x540000000000, .up_addr = 0x550000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x550000000000, .up_addr = 0x560000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x560000000000, .up_addr = 0x570000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x570000000000, .up_addr = 0x580000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x580000000000, .up_addr = 0x590000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x590000000000, .up_addr = 0x5a0000000000, .options = .{ .thread_safe = true } }, // [X]
    .{ .lb_addr = 0x5a0000000000, .up_addr = 0x5b0000000000 }, // [X]
    .{ .lb_addr = 0x5b0000000000, .up_addr = 0x5c0000000000 },
    .{ .lb_addr = 0x5c0000000000, .up_addr = 0x5d0000000000 },
});
// zig fmt: on

/// Initial concern by increased binary size switching to new (formulaic)
/// address space. However code scores much better on MCA.
const OldAddressSpace = mem.StaticAddressSpace;
fn arenaFromBits(b: u64) virtual.Arena {
    return .{ .lb_addr = @ctz(b), .up_addr = @ctz(b) + @popCount(b) };
}
fn arenaToBits(arena: virtual.Arena) u64 {
    return mach.shl64(mach.shl64(1, arena.up_addr - arena.lb_addr) - 1, arena.lb_addr);
}
fn testArenaIntersection() !void {
    const a: virtual.Arena = arenaFromBits(0b000000000111111111110000000000000);
    const b: virtual.Arena = arenaFromBits(0b000000000000000111111111110000000);
    const x: virtual.Arena.Intersection = a.intersection2(b).?;
    var array: PrintArray = .{};
    array.writeMany("a:\t");
    array.writeFormat(fmt.any(a));
    array.writeMany("\t -> ");
    array.writeFormat(fmt.ub64(arenaToBits(a)));
    array.writeMany("\nb:\t");
    array.writeFormat(fmt.any(b));
    array.writeMany("\t -> ");
    array.writeFormat(fmt.ub64(arenaToBits(b)));
    array.writeMany("\nx.l:\t");
    array.writeFormat(fmt.any(x.l));
    array.writeMany("\t -> ");
    array.writeFormat(fmt.ub64(arenaToBits(x.l)));
    array.writeMany("\nx.x:\t");
    array.writeFormat(fmt.any(x.x));
    array.writeMany("\t -> ");
    array.writeFormat(fmt.ub64(arenaToBits(x.x)));
    array.writeMany("\nx.h:\t");
    array.writeFormat(fmt.any(x.h));
    array.writeMany("\t -> ");
    array.writeFormat(fmt.ub64(arenaToBits(x.h)));
    file.noexcept.write(2, array.readAll());
}
fn testRegularAddressSpace() !void {
    const AddressSpace = virtual.GenericRegularAddressSpace(.{ .divisions = 8 });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    const Array = Allocator.StructuredVector(u8);
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = try Array.init(&allocator, 8192);
    defer array.deinit(&allocator);
    var i: u8 = 1;
    try array.appendAny(preset.reinterpret.fmt, &allocator, .{ fmt.any(address_space), '\n' });
    while (i != AddressSpace.addr_spec.divisions) : (i += 1) {
        try mem.acquire(.{}, AddressSpace, &address_space, i);
        try array.appendAny(preset.reinterpret.fmt, &allocator, .{ fmt.any(address_space), '\n' });
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
}
fn testDiscreteAddressSpace(comptime list: anytype) !void {
    const AddressSpace = virtual.GenericDiscreteAddressSpace(.{ .list = list });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    const Array = Allocator.StructuredVector(u8);
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = try Array.init(&allocator, 8192);
    defer array.deinit(&allocator);
    comptime var i: u8 = 1;
    try array.appendAny(preset.reinterpret.fmt, &allocator, .{ fmt.any(address_space), '\n' });
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        try mem.static.acquire(.{}, AddressSpace, &address_space, i);
        try array.appendFormat(&allocator, fmt.any(address_space));
        try array.appendMany(&allocator, "\n");
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
    file.noexcept.write(2, array.readAll());
    i = 1;
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        try mem.static.release(.{}, AddressSpace, &address_space, i);
        try array.appendFormat(&allocator, fmt.any(address_space));
        try array.appendMany(&allocator, "\n");
        file.noexcept.write(2, array.readAll());
        array.undefineAll();
    }
}
fn testDiscreteSubSpaceFromDiscrete(comptime sup_spec: virtual.DiscreteAddressSpaceSpec, comptime sub_spec: virtual.DiscreteAddressSpaceSpec) !void {
    const render_spec: fmt.RenderSpec = .{ .radix = 2, .ignore_container_decls = true, .ignore_formatter_decls = true };
    const AddressSpace = comptime blk: {
        var tmp = sup_spec;
        tmp.subspace = meta.slice(meta.Generic, .{virtual.generic(sub_spec)});
        break :blk virtual.GenericDiscreteAddressSpace(tmp);
    };
    const SubAddressSpace = AddressSpace.SubSpace(0);
    var address_space: AddressSpace = .{};
    var sub_space: SubAddressSpace = .{};

    const Allocator0 = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubAddressSpace });
    const Allocator1 = mem.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubAddressSpace });
    const Allocator2 = mem.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubAddressSpace });
    const Array0 = Allocator0.StructuredVector(u8);
    const Array1 = Allocator1.StructuredVector(u8);
    const Array2 = Allocator2.StructuredVector(u8);
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var array_0: Array0 = try Array0.init(&allocator_0, 2048);
    defer array_0.deinit(&allocator_0);
    try array_0.appendAny(preset.reinterpret.fmt, &allocator_0, .{
        fmt.render(render_spec, address_space), '\n',
        fmt.render(render_spec, sub_space),     '\n',
    });
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var array_1: Array1 = try Array1.init(&allocator_1, 2048);
    defer array_1.deinit(&allocator_1);
    try array_1.appendFormat(&allocator_1, fmt.render(render_spec, sub_space));
    try array_1.appendMany(&allocator_1, "\n");
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
    var array_2: Array2 = try Array2.init(&allocator_2, 2048);
    defer array_2.deinit(&allocator_2);
    try array_2.appendFormat(&allocator_2, fmt.render(render_spec, sub_space));
    try array_2.appendMany(&allocator_2, "\n");
    file.noexcept.write(2, array_0.readAll());
    array_0.undefineAll();
    file.noexcept.write(2, array_1.readAll());
    array_1.undefineAll();
    file.noexcept.write(2, array_2.readAll());
    array_2.undefineAll();
}
fn testRegularAddressSubSpaceFromDiscrete(comptime sup_spec: virtual.DiscreteAddressSpaceSpec) !void {
    const render_spec: fmt.RenderSpec = .{ .radix = 2, .ignore_container_decls = true, .ignore_formatter_decls = true };
    const AddressSpace = sup_spec.instantiate();
    const SubAddressSpace = AddressSpace.SubSpace(0);
    var address_space: AddressSpace = .{};
    var sub_space: SubAddressSpace = .{};
    const Allocator0 = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubAddressSpace });
    const Allocator1 = mem.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubAddressSpace });
    const Allocator2 = mem.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubAddressSpace });
    const Array0 = Allocator0.StructuredHolder(u8);
    const Array1 = Allocator1.StructuredHolder(u8);
    const Array2 = Allocator2.StructuredHolder(u8);
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var array_0: Array0 = Array0.init(&allocator_0);
    defer array_0.deinit(&allocator_0);
    try array_0.appendAny(preset.reinterpret.fmt, &allocator_0, .{
        fmt.render(render_spec, address_space), '\n',
        fmt.render(render_spec, sub_space),     '\n',
    });
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var array_1: Array1 = Array1.init(&allocator_1);
    defer array_1.deinit(&allocator_1);
    try array_1.appendFormat(&allocator_1, fmt.render(render_spec, sub_space));
    try array_1.appendMany(&allocator_1, "\n");
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
    var array_2: Array2 = Array2.init(&allocator_2);
    defer array_2.deinit(&allocator_2);
    try array_2.appendFormat(&allocator_2, fmt.render(render_spec, sub_space));
    try array_2.appendMany(&allocator_2, "\n");
    file.noexcept.write(2, array_0.readAll(allocator_0));
    array_0.undefineAll(allocator_0);
    file.noexcept.write(2, array_1.readAll(allocator_1));
    array_1.undefineAll(allocator_1);
    file.noexcept.write(2, array_2.readAll(allocator_2));
    array_2.undefineAll(allocator_2);
}
pub fn main() !void {
    try meta.wrap(testArenaIntersection());
    try meta.wrap(testDiscreteAddressSpace(trivial_list));
    try meta.wrap(testDiscreteAddressSpace(complex_list));
    try meta.wrap(testDiscreteAddressSpace(simple_list));
    try meta.wrap(testRegularAddressSpace());
    try meta.wrap(testRegularAddressSubSpaceFromDiscrete(.{
        .list = complex_list,
        .subspace = meta.slice(meta.Generic, .{virtual.generic(.{
            .lb_addr = complex_list[34].lb_addr,
            .ab_addr = complex_list[34].lb_addr,
            .xb_addr = complex_list[42].up_addr,
            .up_addr = complex_list[42].up_addr,
            .divisions = 16,
            .options = .{ .thread_safe = true },
        })}),
    }));
    try meta.wrap(testDiscreteSubSpaceFromDiscrete(.{ .list = simple_list }, .{ .list = rare_sub_list }));
}
