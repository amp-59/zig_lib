const top = @import("../zig_lib.zig");
const sys = top.sys;
const fmt = top.fmt;
const mem = top.mem;
const proc = top.proc;
const mach = top.mach;
const meta = top.meta;
const file = top.file;
const spec = top.spec;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const AddressSpace = spec.address_space.regular_128;

const move_spec = .{
    .options = .{},
    .logging = spec.logging.success_error.verbose,
    .errors = .{ .abort = sys.mremap_errors },
};
const map_spec = .{
    .options = .{},
    .logging = spec.logging.acquire_error.verbose,
    .errors = .{ .abort = sys.mmap_errors },
};
const resize_spec = .{
    .logging = spec.logging.success_error.verbose,
    .errors = .{ .abort = sys.mremap_errors },
};
const unmap_spec = .{
    .logging = spec.logging.release_error.verbose,
    .errors = .{ .abort = sys.munmap_errors },
};
const advise_spec = .{
    .options = .{ .property = .{ .dump = true } },
    .logging = spec.logging.success_error.verbose,
    .errors = .{ .abort = sys.madvise_errors },
};
const protect_spec = .{
    .options = .{ .none = true },
    .logging = spec.logging.success_error.verbose,
    .errors = .{ .abort = sys.madvise_errors },
};
const wr_spec: mem.ReinterpretSpec = .{
    .composite = .{ .format = true },
    .reference = .{ .dereference = &.{} },
};
const mem_fd_spec: mem.FdSpec = .{
    .logging = spec.logging.acquire_error.verbose,
    .errors = .{ .throw = sys.memfd_create_errors },
};
fn testProtect() void {
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end - addr;
    try meta.wrap(mem.map(map_spec, addr, len));
    try meta.wrap(mem.protect(protect_spec, addr, 4096));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
}
fn testLowSystemMemoryOperations() !void {
    try meta.wrap(mem.unmap(unmap_spec, 0x7000000, 0x3000000 * 2));
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end - addr;
    try meta.wrap(mem.map(map_spec, addr, len));
    try meta.wrap(mem.move(move_spec, addr, len, addr + len));
    try meta.wrap(mem.protect(protect_spec, addr + len, len));
    addr += len;
    try meta.wrap(mem.resize(resize_spec, addr, len, len * 2));
    len *= 2;
    try meta.wrap(mem.advise(advise_spec, addr, len));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
}
fn testMapGenericOverhead() !void {
    var addr: u64 = 0x7000000;
    var len: u64 = 0x3000000;
    var end: u64 = addr + len;
    try meta.wrap(mem.map(.{ .options = .{ .populate = true } }, addr, len));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
    addr = end;
    try meta.wrap(mem.map(.{ .options = .{ .populate = false, .visibility = .shared } }, end, len));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
}
fn testRtAllocatedImplementation() !void {
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
        var i: u64 = 0;
        while (i != repeats) : (i += 1) {
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
        var i: u64 = 0;
        while (i != repeats) : (i += 1) {
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
fn testAllocatedImplementation() !void {
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
    var address_space: builtin.AddressSpace() = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    const ArrayA = Allocator.StructuredStreamHolder(u8);
    var array_a: ArrayA = ArrayA.init(&allocator);
    {
        var i: u64 = 0;
        while (i != repeats) : (i += 1) {
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
        var i: u64 = 0;
        while (i != repeats) : (i += 1) {
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
    {
        const array = mem.view("Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, array.readAll(), "Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, "World!", &array.readCountAt("World!".len, "Hello, ".len));
        try builtin.expectEqual(u64, array.readAll().len + 1, array.impl.allocated_byte_count());
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
    const hello: [:0]const u8 = "Hello, world!";
    { // strings
        { // true
            try builtin.expect(mem.testEqualManyFront(u8, "1", "10"));
            try builtin.expect(mem.testEqualManyBack(u8, "0", "10"));
        } // false
        {
            try builtin.expect(!mem.testEqualManyFront(u8, "0", "10"));
            try builtin.expect(!mem.testEqualManyBack(u8, "1", "10"));
        }
        { // impossible (false)
            try builtin.expect(!mem.testEqualManyFront(u8, "012", "10"));
            try builtin.expect(!mem.testEqualManyBack(u8, "124", "10"));
        }

        { // result
            try builtin.expectEqual(u64, 5, mem.indexOfFirstEqualOne(u8, ',', hello).?);
            try builtin.expectEqual(u64, 0, mem.indexOfFirstEqualOne(u8, 'H', hello).?);
            try builtin.expectEqual(u64, 12, mem.indexOfFirstEqualOne(u8, '!', hello).?);
            try builtin.expectEqual(u64, 0, mem.indexOfFirstEqualMany(u8, "Hello", hello).?);
            try builtin.expectEqual(u64, 7, mem.indexOfFirstEqualMany(u8, "world", hello).?);
            try builtin.expectEqual(u64, 7, mem.indexOfLastEqualMany(u8, "world", hello).?);
            try builtin.expectEqual(u64, 5, mem.indexOfFirstEqualAny(u8, ", ", hello).?);
            try builtin.expectEqual(u64, 6, mem.indexOfLastEqualAny(u8, ", ", hello).?);
            try builtin.expectEqual(u64, 0, mem.indexOfFirstEqualAny(u8, "!H", hello).?);
            try builtin.expectEqual(u64, 12, mem.indexOfLastEqualAny(u8, "!H", hello).?);
        }
        { // null
            try builtin.expect(mem.indexOfFirstEqualOne(u8, 'f', hello) == null);
            try builtin.expect(mem.indexOfFirstEqualMany(u8, "foo", hello) == null);
        }
        { // impossible (null)
            try builtin.expect(mem.indexOfFirstEqualMany(u8, hello, "foo") == null);
            try builtin.expect(mem.indexOfFirstEqualMany(u8, "", hello) == null);
        }
        {
            try testing.expectEqualMany(u8, ".field", mem.readBeforeFirstEqualMany(u8, " = ", ".field = value,").?);
            try testing.expectEqualMany(u8, "value,", mem.readAfterFirstEqualMany(u8, " = ", ".field = value,").?);
            try testing.expectEqualMany(u8, "", mem.readAfterFirstEqualMany(u8, " = ", ".field = ").?);
            try testing.expectEqualMany(u8, "", mem.readBeforeFirstEqualMany(u8, " = ", " = value,").?);
        }
        {
            try builtin.expectEqual(u64, 3, mem.propagateSearch(u8, "345", "0123456789", 3).?);
            try builtin.expectEqual(u64, 8, mem.propagateSearch(u8, "8", "0123456789", 8).?);
            try builtin.expectEqual(u64, 4, mem.propagateSearch(u8, "4", "0123456789", 4).?);
            try builtin.expectEqual(u64, 0, mem.propagateSearch(u8, "0123456789", "0123456789", 0).?);
        }
    }
}
const AllocatorL = struct {}.GenericLinkedAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
});
fn testLallocator() !void {
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
    var allocator: mem.SimpleAllocator = .{};
    var buf: []u8 = allocator.allocate(u8, 256);
    allocator.deallocate(u8, buf);
    allocator.unmap();
}
pub fn main() !void {
    testSimpleAllocator();
    //try meta.wrap(testLallocator());
    try meta.wrap(testMapGenericOverhead());
    try meta.wrap(testProtect());
    try meta.wrap(testLowSystemMemoryOperations());
    try meta.wrap(testAutomaticImplementation());
    try meta.wrap(testAllocatedImplementation());
    try meta.wrap(testRtAllocatedImplementation());
    try meta.wrap(testUtilityTestFunctions());
}
