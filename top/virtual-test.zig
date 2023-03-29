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

pub const logging_override: builtin.Logging.Override = preset.logging.override.silent;

const PrintArray = mem.StaticString(16384);
var print_array: PrintArray = undefined;

pub const runtime_assertions: bool = true;
pub const render_radix: u16 = 10;

pub const trivial_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000004000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x010000000000, .up_addr = 0x110000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
};
pub const simple_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x100000000000, .up_addr = 0x110000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x120000000000, .up_addr = 0x130000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
};
pub const rare_sub_list: []const virtual.Arena = &.{
    .{ .lb_addr = 0x000040000000, .up_addr = 0x010000000000 },
    .{ .lb_addr = 0x110000000000, .up_addr = 0x120000000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x7f0000000000, .up_addr = 0x800000000000 },
};
// zig fmt: off
pub const complex_list: []const virtual.Arena = &.{
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
};
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
    var a: virtual.Arena = arenaFromBits(0b000000000111111111110000000000000);
    var b: virtual.Arena = arenaFromBits(0b000000000000000111111111110000000);
    var x: virtual.Arena.Intersection = a.intersection2(b).?;
    try builtin.expectEqual(u64, arenaToBits(x.l), 0b0000000000000000000000000000000000000000000000000001111110000000);
    try builtin.expectEqual(u64, arenaToBits(x.x), 0b0000000000000000000000000000000000000000000000111110000000000000);
    try builtin.expectEqual(u64, arenaToBits(x.h), 0b0000000000000000000000000000000000000000111111000000000000000000);
}
fn testRegularAddressSpace() !void {
    const AddressSpace = virtual.GenericRegularAddressSpace(.{ .divisions = 8, .lb_offset = 0x40000000 });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var i: u8 = 1;
    while (i != AddressSpace.addr_spec.divisions) : (i += 1) {
        try mem.acquire(AddressSpace, &address_space, i);
    }
}

fn acquireStaticSet(comptime AddressSpace: type, address_space: *AddressSpace, comptime index: AddressSpace.Index) bool {
    if (comptime AddressSpace.arena(index).options.thread_safe) {
        return address_space.atomicSet(index);
    } else {
        return address_space.set(index);
    }
}
fn testDiscreteAddressSpace(comptime list: anytype) !void {
    const AddressSpace = virtual.GenericDiscreteAddressSpace(.{ .list = list });

    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    comptime var i: u8 = 1;
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        try mem.acquireStatic(AddressSpace, &address_space, i);
    }
    i = 1;
    inline while (i != AddressSpace.addr_spec.list.len) : (i += 1) {
        mem.releaseStatic(AddressSpace, &address_space, i);
    }
}
fn testDiscreteSubSpaceFromDiscrete(comptime sup_spec: virtual.DiscreteAddressSpaceSpec, comptime sub_spec: virtual.DiscreteAddressSpaceSpec) !void {
    const AddressSpace = comptime blk: {
        var tmp = sup_spec;
        tmp.subspace = meta.slice(meta.Generic, .{virtual.generic(sub_spec)});
        break :blk virtual.GenericDiscreteAddressSpace(tmp);
    };
    const SubAddressSpace = AddressSpace.SubSpace(0);
    var sub_space: SubAddressSpace = .{};
    const Allocator0 = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubAddressSpace });
    const Allocator1 = mem.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubAddressSpace });
    const Allocator2 = mem.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubAddressSpace });
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
}
fn testRegularAddressSubSpaceFromDiscrete(comptime sup_spec: virtual.DiscreteAddressSpaceSpec) !void {
    const AddressSpace = sup_spec.instantiate();
    const SubAddressSpace = AddressSpace.SubSpace(0);
    var sub_space: SubAddressSpace = .{};
    const Allocator0 = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubAddressSpace });
    const Allocator1 = mem.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubAddressSpace });
    const Allocator2 = mem.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubAddressSpace });
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
}

fn testTaggedSets() !void {
    const E = enum { a, b, c, d };
    const K = virtual.GenericDiscreteAddressSpace(.{
        .label = "tagged",
        .idx_type = E,
        .list = &.{
            .{ .lb_addr = 0x40000000, .up_addr = 0x80000000 },
            .{ .lb_addr = 0x80000000, .up_addr = 0x100000000 },
            .{ .lb_addr = 0x100000000, .up_addr = 0x200000000, .options = .{ .thread_safe = true } },
            .{ .lb_addr = 0x200000000, .up_addr = 0x400000000 },
        },
    });
    var k: K = .{};
    try builtin.expect(k.set(.a));
    try builtin.expect(k.set(.b));
    try builtin.expect(k.set(.c));
    try builtin.expect(k.set(.d));

    testing.print(fmt.any(k));
}
pub fn main() !void {
    try meta.wrap(testArenaIntersection());
    try meta.wrap(testRegularAddressSpace());
    try meta.wrap(testTaggedSets());
    try meta.wrap(testDiscreteAddressSpace(trivial_list));
    try meta.wrap(testDiscreteAddressSpace(complex_list));
    try meta.wrap(testDiscreteAddressSpace(simple_list));
    try meta.wrap(testRegularAddressSubSpaceFromDiscrete(.{
        .list = complex_list,
        .subspace = meta.slice(meta.Generic, .{virtual.generic(.{
            .lb_addr = complex_list[34].lb_addr,
            .up_addr = complex_list[42].up_addr,
            .divisions = 16,
            .options = .{ .thread_safe = true },
        })}),
    }));
    try meta.wrap(testDiscreteSubSpaceFromDiscrete(.{ .list = simple_list }, .{ .list = rare_sub_list }));
}
