const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const proc = zl.proc;
const bits = zl.bits;
const meta = zl.meta;
const file = zl.file;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

const tab = @import("./tab.zig");

pub usingnamespace zl.start;

pub const runtime_assertions: bool = true;
pub const logging_default: debug.Logging.Default = debug.spec.logging.default.verbose;
pub const AddressSpace = mem.spec.address_space.regular_128;
const Impl = struct {
    im1: ImArrays = .{},
    im2: ImStruct = .{},
    const ImArrays = mem.GenericOptionalArrays(mem.SimpleAllocator, usize, union(enum) {
        args: [*:0]u8,
        impl: *Impl,
        deps: struct {},
    });
    const ImStruct = mem.GenericOptionals(mem.SimpleAllocator, union(enum) {
        image_base: usize,
        cpu: []const u8,
    });
};
fn arenaFromBits(b: u64) mem.Arena {
    return .{ .lb_addr = @ctz(b), .up_addr = @ctz(b) + @popCount(b) };
}
fn arenaToBits(arena: mem.Arena) u64 {
    return bits.shl64(bits.shl64(1, arena.up_addr - arena.lb_addr) - 1, arena.lb_addr);
}
fn testArenaIntersection() !void {
    var a: mem.Arena = arenaFromBits(0b000000000111111111110000000000000);
    var b: mem.Arena = arenaFromBits(0b000000000000000111111111110000000);
    var x: mem.Intersection(mem.Arena) = mem.intersection2(mem.Arena, a, b).?;
    try debug.expectEqual(u64, arenaToBits(x.l), 0b0000000000000000000000000000000000000000000000000001111110000000);
    try debug.expectEqual(u64, arenaToBits(x.x), 0b0000000000000000000000000000000000000000000000111110000000000000);
    try debug.expectEqual(u64, arenaToBits(x.h), 0b0000000000000000000000000000000000000000111111000000000000000000);
}
fn testRegularAddressSpace() !void {
    const LAddressSpace = mem.GenericRegularAddressSpace(.{ .divisions = 8, .lb_offset = 0x40000000 });
    var address_space: LAddressSpace = .{};
    const Allocator = mem.dynamic.GenericRtArenaAllocator(.{ .AddressSpace = LAddressSpace });
    Allocator.__refAllDecls();
    var allocator: Allocator = try Allocator.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    var i: u8 = 1;
    while (i != LAddressSpace.specification.divisions) : (i +%= 1) {
        try mem.acquire(LAddressSpace, &address_space, i);
    }
    try debug.expectEqual(u64, LAddressSpace.specification.divisions, address_space.count());
}
fn testDiscreteAddressSpace(comptime list: anytype) !void {
    const LAddressSpace = mem.GenericDiscreteAddressSpace(.{ .list = list });
    meta.refAllDecls(LAddressSpace, &.{});
    var address_space: LAddressSpace = .{};
    const Allocator = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = LAddressSpace });
    Allocator.__refAllDecls();
    var allocator: Allocator = try Allocator.init(&address_space);
    comptime var idx: u8 = 1;
    inline while (idx != LAddressSpace.specification.list.len) : (idx +%= 1) {
        try mem.acquireStatic(LAddressSpace, &address_space, idx);
    }
    try debug.expectEqual(u64, LAddressSpace.specification.list.len, address_space.count());
    idx = 1;
    inline while (idx != LAddressSpace.specification.list.len) : (idx +%= 1) {
        mem.releaseStatic(LAddressSpace, &address_space, idx);
    }
    allocator.deinit(&address_space);
    try debug.expectEqual(u64, address_space.count(), 0);
}
fn testDiscreteSubSpaceFromDiscrete(comptime sup_spec: mem.DiscreteAddressSpaceSpec, comptime sub_spec: mem.DiscreteAddressSpaceSpec) !void {
    const LAddressSpace = comptime blk: {
        var tmp = sup_spec;
        tmp.subspace = &[_]meta.Generic{mem.generic(sub_spec)};
        break :blk mem.GenericDiscreteAddressSpace(tmp);
    };
    const SubLAddressSpace = LAddressSpace.SubSpace(0);
    meta.refAllDecls(SubLAddressSpace, &.{});
    var sub_space: SubLAddressSpace = .{};
    const Allocator0 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubLAddressSpace });
    const Allocator1 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubLAddressSpace });
    const Allocator2 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubLAddressSpace });
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
}
fn testRegularAddressSubSpaceFromDiscrete(comptime sup_spec: mem.DiscreteAddressSpaceSpec) !void {
    const LAddressSpace = sup_spec.instantiate();
    const SubLAddressSpace = LAddressSpace.SubSpace(0);
    var sub_space: SubLAddressSpace = .{};
    const Allocator0 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 0, .AddressSpace = SubLAddressSpace });
    const Allocator1 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 1, .AddressSpace = SubLAddressSpace });
    const Allocator2 = mem.dynamic.GenericArenaAllocator(.{ .arena_index = 2, .AddressSpace = SubLAddressSpace });
    var allocator_0: Allocator0 = try Allocator0.init(&sub_space);
    defer allocator_0.deinit(&sub_space);
    var allocator_1: Allocator1 = try Allocator1.init(&sub_space);
    defer allocator_1.deinit(&sub_space);
    var allocator_2: Allocator2 = try Allocator2.init(&sub_space);
    defer allocator_2.deinit(&sub_space);
}
fn testTaggedSets() !void {
    const E = enum(u2) { a, b, c, d };
    const K = mem.GenericDiscreteAddressSpace(.{
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
fn testImplementations() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmapAll();
    var impl: Impl = .{};
    impl.im1.add(&allocator, .args).* = @constCast("one");
    impl.im1.add(&allocator, .args).* = @constCast("two");
    impl.im1.add(&allocator, .args).* = @constCast("three");
    for ([_][]const u8{ "one", "two", "three" }, 0..) |arg, idx| {
        try debug.expectEqual([]const u8, mem.terminate(impl.im1.get(.args)[idx], 0), arg);
    }
    impl.im2.add(&allocator, .image_base).* = 0x10000;
    impl.im2.add(&allocator, .cpu).* = "zen2";
    try debug.expectEqual(usize, impl.im2.get(.image_base).*, 0x10000);
    try debug.expectEqual([]const u8, impl.im2.get(.cpu).*, "zen2");
}
fn testProtect() !void {
    testing.announce(@src());
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end -% addr;
    try meta.wrap(mem.map(.{}, .{}, .{}, addr, len));
    try meta.wrap(mem.protect(.{}, .{ .read = true }, addr, 4096));
    try meta.wrap(mem.unmap(.{}, addr, len));
}
fn testLowSystemMemoryOperations() !void {
    testing.announce(@src());
    try meta.wrap(mem.unmap(.{}, 0x7000000, 0x3000000 * 2));
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end -% addr;
    try meta.wrap(mem.map(.{}, .{}, .{}, addr, len));
    try meta.wrap(mem.move(.{}, .{ .may_move = true, .fixed = true }, addr, len, addr +% len));
    try meta.wrap(mem.protect(.{}, .{ .read = false, .write = false }, addr +% len, len));
    addr +%= len;
    try meta.wrap(mem.resize(.{}, addr, len, len *% 2));
    len *= 2;
    try meta.wrap(mem.advise(.{}, .hugepage, addr, len));
    try meta.wrap(mem.unmap(.{}, addr, len));
}
fn testMapGenericOverhead() !void {
    testing.announce(@src());
    var addr: u64 = 0x7000000;
    var len: u64 = 0x3000000;
    var end: u64 = addr +% len;
    try meta.wrap(mem.map(.{}, .{}, .{ .populate = true }, addr, len));
    try meta.wrap(mem.unmap(.{}, addr, len));
    addr = end;
    try meta.wrap(mem.map(.{}, .{}, .{ .populate = false, .visibility = .shared }, end, len));
    try meta.wrap(mem.unmap(.{}, addr, len));
}
fn testRtAllocatedImplementation() !void {
    testing.announce(@src());
    const repeats: u64 = 0x100;
    const Allocator = mem.dynamic.GenericRtArenaAllocator(.{
        .options = .{ .trace_state = false },
        .logging = mem.dynamic.spec.logging.silent,
        .AddressSpace = mem.spec.address_space.regular_128,
    });
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    const ArrayA = Allocator.StructuredStreamHolder(u8);
    var array_a: ArrayA = ArrayA.init(&allocator);
    {
        var idx: usize = 0;
        while (idx != repeats) : (idx +%= 1) {
            try array_a.appendMany(&allocator, "Hello, world!");
            try array_a.appendCount(&allocator, 4, "1234".*);
            try array_a.appendFormat(&allocator, fmt.ux(0x1fee1dead));
            try testing.expectEqualMany(u8, "world!", &array_a.readCountAt(allocator, "world!".len, "Hello, ".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyAhead("Hello, ".len));
            array_a.stream("Hello, ".len);
            try testing.expectEqualMany(u8, "world!", array_a.readManyAhead("world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyBehind("Hello, ".len));
            array_a.unstream("Hello, ".len);
        }
    }
    const ArrayB = Allocator.StructuredStreamVector(u8);
    var array_ab: ArrayB = try array_a.dynamic(&allocator, ArrayB);
    defer array_ab.deinit(&allocator);
    var array_b: ArrayB = try ArrayB.init(&allocator, 256);
    defer array_b.deinit(&allocator);
    {
        var idx: usize = 0;
        while (idx != repeats) : (idx +%= 1) {
            try array_b.appendMany(&allocator, "Hello, world!");
            try array_b.appendCount(&allocator, 4, "1234".*);
            try array_b.appendFormat(&allocator, fmt.ux(0x1fee1dead));
            try testing.expectEqualMany(u8, "world!", &array_b.readCountAt("world!".len, "Hello, ".len));
            try testing.expectEqualMany(u8, "Hello, ", array_b.readManyAhead("Hello, ".len));
            array_b.stream("Hello, ".len);
            try testing.expectEqualMany(u8, "world!", array_b.readManyAhead("world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_b.readManyBehind("Hello, ".len));
            array_b.unstream("Hello, ".len);
        }
    }
    try debug.expectEqual(usize, 2, mem.editDistance("abc", "cb"));
    try testing.expect(0 == mem.editDistance("one", "one"));
    try testing.expect(1 == mem.editDistance("onE", "one"));
    try debug.expectEqual(usize, 2, mem.editDistance("cat", "cake"));
    try testing.expectEqualMany(u8, array_ab.readAll(), array_b.readAll());
}
fn testAllocatedImplementation() !void {
    testing.announce(@src());
    const repeats: u64 = 0x100;
    const Allocator = mem.dynamic.GenericArenaAllocator(.{
        // Allocations will begin offset 1GiB into the mem address space.
        // This would be 0B, but to avoid the program mapping. Obviously
        // unsound on systems where the program is mapped randomly in the
        // address space.
        .arena_index = 0,
        .options = .{ .trace_state = false },
        .logging = mem.dynamic.spec.logging.silent,
        .AddressSpace = AddressSpace,
    });
    var address_space: builtin.VirtualAddressSpace() = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    const ArrayA = Allocator.StructuredStreamHolder(u8);
    var array_a: ArrayA = ArrayA.init(&allocator);
    {
        var i: u64 = 0;
        while (i != repeats) : (i +%= 1) {
            try array_a.appendMany(&allocator, "Hello, world!");
            try array_a.appendCount(&allocator, 4, "1234".*);
            try array_a.appendFormat(&allocator, fmt.ux(0x1fee1dead));
            try testing.expectEqualMany(u8, "world!", &array_a.readCountAt(allocator, "world!".len, "Hello, ".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyAhead("Hello, ".len));
            array_a.stream("Hello, ".len);
            try testing.expectEqualMany(u8, "world!", array_a.readManyAhead("world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyBehind("Hello, ".len));
            array_a.unstream("Hello, ".len);
        }
    }
    const ArrayB = Allocator.StructuredStreamVector(u8);
    var array_ab: ArrayB = try array_a.dynamic(&allocator, ArrayB);
    defer array_ab.deinit(&allocator);
    var array_b: ArrayB = try ArrayB.init(&allocator, 256);
    defer array_b.deinit(&allocator);
    {
        var idx: u64 = 0;
        while (idx != repeats) : (idx +%= 1) {
            try array_b.appendMany(&allocator, "Hello, world!");
            try array_b.appendCount(&allocator, 4, "1234".*);
            try array_b.appendFormat(&allocator, fmt.ux(0x1fee1dead));
            try testing.expectEqualMany(u8, "world!", &array_b.readCountAt("world!".len, "Hello, ".len));
            try testing.expectEqualMany(u8, "Hello, ", array_b.readManyAhead("Hello, ".len));
            array_b.stream("Hello, ".len);
            try testing.expectEqualMany(u8, "world!", array_b.readManyAhead("world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_b.readManyBehind("Hello, ".len));
            array_b.unstream("Hello, ".len);
        }
    }
    try testing.expectEqualMany(u8, array_ab.readAll(), array_b.readAll());
}
fn testAutomaticImplementation() !void {
    testing.announce(@src());
    {
        const array = mem.array.view("Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, array.readAll(), "Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, "World!", &array.readCountAt("World!".len, "Hello, ".len));
        try debug.expectEqual(u64, array.readAll().len, array.impl.allocated_byte_count());
    }
    {
        const StaticString = mem.array.StructuredAutomaticStreamVector(u8, null, 256, 1, .{});
        var array: StaticString = .{};
        array.writeMany("Hello, world!");
        array.writeCount(4, "1234".*);
        array.writeFormat(fmt.ux(0x1fee1dead));
        try testing.expectEqualMany(u8, "world!", &array.readCountAt("world!".len, "Hello, ".len));
        try testing.expectEqualMany(u8, "Hello, ", array.readManyAhead("Hello, ".len));
        array.stream("Hello, ".len);
        try testing.expectEqualMany(u8, "world!", array.readManyAhead("world!".len));
        try testing.expectEqualMany(u8, "Hello, ", array.readManyBehind("Hello, ".len));
    }
    {
        const VectorBool = mem.array.StructuredAutomaticStreamVector(bool, null, 256, 1, .{});
        var bit_set: VectorBool = .{};
        bit_set.writeCount(4, .{ true, false, false, true });
        try testing.expectEqualMany(bool, bit_set.readAll(), &.{ true, false, false, true });
    }
}
fn testUtilityTestFunctions() !void {
    testing.announce(@src());
    const hello: [:0]const u8 = "Hello, world!";
    try testing.expect(mem.order(u8, "abcd", "bee") == .lt);
    try testing.expect(mem.order(u8, "abc", "abc") == .eq);
    try testing.expect(mem.order(u8, "abc", "abc0") == .lt);
    try testing.expect(mem.order(u8, "", "") == .eq);
    try testing.expect(mem.order(u8, "", "a") == .lt);
    try debug.expect(mem.testEqualManyFront(u8, "1", "10"));
    try debug.expect(mem.testEqualManyBack(u8, "0", "10"));
    try debug.expect(!mem.testEqualManyFront(u8, "0", "10"));
    try debug.expect(!mem.testEqualManyBack(u8, "1", "10"));
    try debug.expect(!mem.testEqualManyFront(u8, "012", "10"));
    try debug.expect(!mem.testEqualManyBack(u8, "124", "10"));
    try debug.expectEqual(u64, 5, mem.indexOfFirstEqualOne(u8, ',', hello).?);
    try debug.expectEqual(u64, 0, mem.indexOfFirstEqualOne(u8, 'H', hello).?);
    try debug.expectEqual(u64, 12, mem.indexOfFirstEqualOne(u8, '!', hello).?);
    try debug.expectEqual(u64, 0, mem.indexOfFirstEqualMany(u8, "Hello", hello).?);
    try debug.expectEqual(u64, 7, mem.indexOfFirstEqualMany(u8, "world", hello).?);
    try debug.expectEqual(u64, 7, mem.indexOfLastEqualMany(u8, "world", hello).?);
    try debug.expectEqual(u64, 5, mem.indexOfFirstEqualAny(u8, ", ", hello).?);
    try debug.expectEqual(u64, 6, mem.indexOfLastEqualAny(u8, ", ", hello).?);
    try debug.expectEqual(u64, 0, mem.indexOfFirstEqualAny(u8, "!H", hello).?);
    try debug.expectEqual(u64, 12, mem.indexOfLastEqualAny(u8, "!H", hello).?);
    try debug.expect(mem.indexOfFirstEqualOne(u8, 'f', hello) == null);
    try debug.expect(mem.indexOfFirstEqualMany(u8, "foo", hello) == null);
    try debug.expect(mem.indexOfFirstEqualMany(u8, hello, "foo") == null);
    try debug.expect(mem.indexOfFirstEqualMany(u8, "", hello) == null);
    try testing.expectEqualMany(u8, ".field", mem.readBeforeFirstEqualMany(u8, " = ", ".field = value,").?);
    try testing.expectEqualMany(u8, "value,", mem.readAfterFirstEqualMany(u8, " = ", ".field = value,").?);
    try testing.expectEqualMany(u8, "", mem.readAfterFirstEqualMany(u8, " = ", ".field = ").?);
    try testing.expectEqualMany(u8, "", mem.readBeforeFirstEqualMany(u8, " = ", " = value,").?);
    try debug.expectEqual(u64, 3, mem.indexOfNearestEqualMany(u8, "345", "0123456789", 3).?);
    try debug.expectEqual(u64, 8, mem.indexOfNearestEqualMany(u8, "8", "0123456789", 8).?);
    try debug.expectEqual(u64, 4, mem.indexOfNearestEqualMany(u8, "4", "0123456789", 4).?);
    try debug.expectEqual(u64, 0, mem.indexOfNearestEqualMany(u8, "0123456789", "0123456789", 0).?);
    try debug.expect(mem.testEqualManyIn(u8, "__anon", "top.mem.GenericOptionalArrays.U.set__anon_4804"));
    try debug.expectEqual(u64, @as(u64, @bitCast([8]u8{ 0, 0, 0, 0, 0, 5, 5, 5 })), mem.readIntVar(u64, &[3]u8{ 5, 5, 5 }, 3));
}
fn testLallocator() !void {
    testing.announce(@src());
    const AllocatorL = mem.dynamic.GenericLinkedAllocator(.{
        .AddressSpace = AddressSpace,
        .errors = mem.dynamic.spec.errors.noexcept,
        .logging = mem.dynamic.spec.logging.silent,
    });
    AllocatorL.__refAllDecls();
    var rng: file.DeviceRandomBytes(65536) = .{};
    var address_space: AddressSpace = .{};
    var allocator: AllocatorL = try AllocatorL.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    var count: u64 = rng.readOne(u16);
    while (count != 1024) : (count = rng.readOne(u16)) {
        const buf: []u8 = try meta.wrap(allocator.allocate(u8, count));
        AllocatorL.Graphics.graphPartitions(allocator);
        @memset(buf, 0);
        allocator.consolidate();
        allocator.deallocate(u8, buf);
    }
    allocator.deallocateAll();
    var allocations: [16]?[]u8 = .{null} ** 16;
    for (&allocations, 0..) |*buf, idx| {
        buf.* = try meta.wrap(allocator.allocate(u8, idx +% 1));
    }
    for (0..0x10000) |_| {
        for (&allocations) |*buf| {
            if (buf.*) |allocation| {
                const sz: u16 = rng.readOne(u8);
                switch (rng.readOne(enum { Deallocate, Reallocate })) {
                    .Deallocate => {
                        allocator.deallocate(u8, allocation);
                        buf.* = null;
                    },
                    .Reallocate => {
                        if (sz > allocation.len) {
                            if (meta.wrap(allocator.reallocate(u8, allocation, sz))) |ret| {
                                buf.* = ret;
                            } else |_| {
                                allocator.deallocate(u8, allocation);
                                buf.* = null;
                                buf.* = try allocator.allocate(u8, rng.readOne(u8));
                            }
                        }
                    },
                }
            } else {
                if (rng.readOne(u8) != 0) {
                    buf.* = try meta.wrap(allocator.allocate(u8, rng.readOne(u8)));
                }
            }
        }
        allocator.consolidate();
    }
    AllocatorL.Graphics.graphPartitions(allocator);
    allocator.deallocateAll();
}
fn testSimpleAllocator() void {
    testing.announce(@src());
    var allocator: mem.SimpleAllocator = .{};
    var buf: []u8 = allocator.allocate(u8, 256);
    allocator.deallocate(u8, buf);
    allocator.unmapAll();
}
fn testSampleAllReports() !void {
    testing.announce(@src());
    mem.about.sampleAllReports();
}
fn testSequentialMatches() !void {
    try debug.expectEqual(usize, 4, mem.sequentialMatches("onetwo", "oeto"));
    try debug.expectEqual(usize, 439, mem.sequentialMatches(
        @embedFile("../top/build/forwardToExecuteCloneThreaded.s"),
        @embedFile("../top/build/forwardToExecuteCloneThreaded4.s"),
    ));
}
pub fn main() !void {
    meta.refAllDecls(mem, &.{});
    try testLallocator();
    try meta.wrap(testRegularAddressSpace());
    try meta.wrap(testDiscreteAddressSpace(tab.trivial_list));
    testSimpleAllocator();
    try meta.wrap(testSequentialMatches());
    try meta.wrap(testArenaIntersection());
    try meta.wrap(testTaggedSets());
    try meta.wrap(testDiscreteAddressSpace(tab.complex_list));
    try meta.wrap(testDiscreteAddressSpace(tab.simple_list));
    try meta.wrap(testRegularAddressSubSpaceFromDiscrete(.{
        .list = tab.complex_list,
        .subspace = &[_]meta.Generic{mem.generic(.{
            .lb_addr = tab.complex_list[34].lb_addr,
            .up_addr = tab.complex_list[42].up_addr,
            .divisions = 16,
            .options = .{ .thread_safe = true },
        })},
    }));
    try meta.wrap(testDiscreteSubSpaceFromDiscrete(
        .{ .list = tab.simple_list },
        .{ .list = tab.rare_sub_list },
    ));
    try testImplementations();
    try testMapGenericOverhead();
    try testProtect();
    try testLowSystemMemoryOperations();
    try testAutomaticImplementation();
    try testAllocatedImplementation();
    try testRtAllocatedImplementation();
    try testUtilityTestFunctions();
    try testSampleAllReports();
}
