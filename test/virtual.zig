const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const meta = zl.meta;
const proc = zl.proc;
const mach = zl.mach;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const virtual = zl.virtual;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

const tab = @import("./tab.zig");

const PrintArray = mem.StaticString(16384);
var print_array: PrintArray = undefined;

pub const runtime_assertions: bool = true;
pub const render_radix: u16 = 10;

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
    var x: virtual.Intersection(virtual.Arena) = virtual.intersection2(virtual.Arena, a, b).?;
    try debug.expectEqual(u64, arenaToBits(x.l), 0b0000000000000000000000000000000000000000000000000001111110000000);
    try debug.expectEqual(u64, arenaToBits(x.x), 0b0000000000000000000000000000000000000000000000111110000000000000);
    try debug.expectEqual(u64, arenaToBits(x.h), 0b0000000000000000000000000000000000000000111111000000000000000000);
}
fn testRegularAddressSpace() !void {
    const AddressSpace = virtual.GenericRegularAddressSpace(.{ .divisions = 8, .lb_offset = 0x40000000 });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var i: u8 = 1;
    while (i != AddressSpace.addr_spec.divisions) : (i +%= 1) {
        try mem.acquire(AddressSpace, &address_space, i);
    }
    try debug.expectEqual(u64, AddressSpace.addr_spec.divisions, address_space.count());
}
fn testDiscreteAddressSpace(comptime list: anytype) !void {
    const AddressSpace = virtual.GenericDiscreteAddressSpace(.{ .list = list });
    var address_space: AddressSpace = .{};
    const Allocator = mem.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = AddressSpace });
    var allocator: Allocator = try Allocator.init(&address_space);
    comptime var idx: u8 = 1;
    inline while (idx != AddressSpace.addr_spec.list.len) : (idx +%= 1) {
        try mem.acquireStatic(AddressSpace, &address_space, idx);
    }
    try debug.expectEqual(u64, AddressSpace.addr_spec.list.len, address_space.count());
    idx = 1;
    inline while (idx != AddressSpace.addr_spec.list.len) : (idx +%= 1) {
        mem.releaseStatic(AddressSpace, &address_space, idx);
    }
    allocator.deinit(&address_space);
    try debug.expectEqual(u64, address_space.count(), 0);
}
fn testDiscreteSubSpaceFromDiscrete(comptime sup_spec: virtual.DiscreteAddressSpaceSpec, comptime sub_spec: virtual.DiscreteAddressSpaceSpec) !void {
    const AddressSpace = comptime blk: {
        var tmp = sup_spec;
        tmp.subspace = &[_]meta.Generic{virtual.generic(sub_spec)};
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
    const E = enum(u2) { a, b, c, d };
    const K = virtual.GenericDiscreteAddressSpace(.{
        .index_type = E,
        .label = "tagged",
        .list = &.{
            .{ .lb_addr = 0x40000000, .up_addr = 0x80000000 },
            .{ .lb_addr = 0x80000000, .up_addr = 0x100000000 },
            .{ .lb_addr = 0x100000000, .up_addr = 0x200000000, .options = .{ .thread_safe = true } },
            .{ .lb_addr = 0x200000000, .up_addr = 0x400000000 },
        },
    });
    var k: K = .{};
    try debug.expect(k.set(.a));
    try debug.expect(k.set(.b));
    try debug.expect(k.set(.c));
    try debug.expect(k.set(.d));
    testing.print(fmt.any(k));
}
fn Clone(comptime function: anytype) type {
    return struct {
        const Fn = @TypeOf(function);
        const Args = meta.Args(Fn);
        const Value = meta.ReturnPayload(Fn);
        const Error = meta.ReturnErrorSet(Fn);
        const Return = Error!Value;
    };
}
pub fn main() !void {
    try meta.wrap(testArenaIntersection());
    try meta.wrap(testRegularAddressSpace());
    try meta.wrap(testTaggedSets());
    try meta.wrap(testDiscreteAddressSpace(tab.trivial_list));
    try meta.wrap(testDiscreteAddressSpace(tab.complex_list));
    try meta.wrap(testDiscreteAddressSpace(tab.simple_list));
    try meta.wrap(testRegularAddressSubSpaceFromDiscrete(.{
        .list = tab.complex_list,
        .subspace = &[_]meta.Generic{virtual.generic(.{
            .lb_addr = tab.complex_list[34].lb_addr,
            .up_addr = tab.complex_list[42].up_addr,
            .divisions = 16,
            .options = .{ .thread_safe = true },
        })},
    }));
    try meta.wrap(testDiscreteSubSpaceFromDiscrete(.{ .list = tab.simple_list }, .{ .list = tab.rare_sub_list }));
}
