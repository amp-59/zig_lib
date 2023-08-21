const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const proc = zl.proc;
const mach = zl.mach;
const meta = zl.meta;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub const logging_default: debug.Logging.Default = spec.logging.default.verbose;
pub const AddressSpace = spec.address_space.regular_128;
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
    try meta.wrap(mem.move(.{}, addr, len, addr +% len));
    try meta.wrap(mem.protect(.{}, .{ .read = true }, addr +% len, len));
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
    const Allocator = mem.GenericRtArenaAllocator(.{
        .options = .{ .trace_state = false },
        .logging = spec.allocator.logging.silent,
        .AddressSpace = spec.address_space.regular_128,
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
    const Allocator = mem.GenericArenaAllocator(.{
        // Allocations will begin offset 1GiB into the virtual address space.
        // This would be 0B, but to avoid the program mapping. Obviously
        // unsound on systems where the program is mapped randomly in the
        // address space.
        .arena_index = 0,
        .options = .{ .trace_state = false },
        .logging = spec.allocator.logging.silent,
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
        const array = mem.view("Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, array.readAll(), "Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, "World!", &array.readCountAt("World!".len, "Hello, ".len));
        try debug.expectEqual(u64, array.readAll().len, array.impl.allocated_byte_count());
    }
    {
        const StaticString = mem.StructuredAutomaticStreamVector(u8, null, 256, 1, .{});
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
        const VectorBool = mem.StructuredAutomaticStreamVector(bool, null, 256, 1, .{});
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

    try debug.expectEqual(u64, @as(u64, @bitCast([8]u8{ 0, 0, 0, 0, 0, 5, 5, 5 })), mem.readIntVar(u64, &[3]u8{ 5, 5, 5 }, 3));
}

fn testLallocator() !void {
    testing.announce(@src());
    const AllocatorL = struct {}.GenericLinkedAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    var rng: file.DeviceRandomBytes(65536) = .{};
    var address_space: AddressSpace = .{};
    var allocator: AllocatorL = try AllocatorL.init(&address_space);
    defer allocator.deinit(&address_space);
    var count: u64 = rng.readOne(u16);
    while (count != 1024) : (count = rng.readOne(u16)) {
        const buf: []u8 = try allocator.allocate(u8, count);
        AllocatorL.Graphics.graphPartitions(allocator);
        mach.memset(buf.ptr, 0, buf.len);
        allocator.consolidate();
        allocator.deallocate(buf);
    }
    allocator.deallocateAll();
    var allocations: [16]?[]u8 = .{null} ** 16;
    for (&allocations, 0..) |*buf, idx| {
        buf.* = try allocator.allocate(u8, idx +% 1);
    }
    for (0..0x10000) |_| {
        for (&allocations) |*buf| {
            if (buf.*) |allocation| {
                const sz: u16 = rng.readOne(u8);
                switch (rng.readOne(enum { Deallocate, Reallocate })) {
                    .Deallocate => {
                        allocator.deallocate(allocation);
                        buf.* = null;
                    },
                    .Reallocate => {
                        if (sz > allocation.len) {
                            if (allocator.reallocate(u8, allocation, sz)) |ret| {
                                buf.* = ret;
                            } else |_| {
                                allocator.deallocate(allocation);
                                buf.* = null;
                                buf.* = try allocator.allocate(u8, rng.readOne(u8));
                            }
                        }
                    },
                }
            } else {
                if (rng.readOne(u8) != 0) {
                    buf.* = try allocator.allocate(u8, rng.readOne(u8));
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
    allocator.unmap();
}
fn testSampleAllReports() !void {
    testing.announce(@src());
    mem.about.sampleAllReports();
}
pub fn main() !void {
    testSimpleAllocator();
    try testMapGenericOverhead();
    try testProtect();
    try testLowSystemMemoryOperations();
    try testAutomaticImplementation();
    try testAllocatedImplementation();
    try testRtAllocatedImplementation();
    try testUtilityTestFunctions();
    try testSampleAllReports();
}
