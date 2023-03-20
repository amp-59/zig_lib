const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;

pub const itos = builtin.fmt.ux;

pub const AddressSpace = preset.address_space.exact_8;

const invalid_holder_state: u64 = (0b110000110000 << 48);

const move_spec = .{
    .options = .{},
    .logging = preset.logging.success_error_fault.verbose,
    .errors = .{ .abort = sys.mremap_errors },
};
const map_spec = .{
    .options = .{},
    .logging = preset.logging.acquire_error_fault.verbose,
    .errors = .{ .abort = sys.mmap_errors },
};
const resize_spec = .{
    .logging = preset.logging.success_error_fault.verbose,
    .errors = .{ .abort = sys.mremap_errors },
};
const unmap_spec = .{
    .logging = preset.logging.release_error_fault.verbose,
    .errors = .{ .abort = sys.munmap_errors },
};
const advise_spec = .{
    .options = .{ .property = .{ .dump = true } },
    .logging = preset.logging.success_error_fault.verbose,
    .errors = .{ .abort = sys.madvise_errors },
};
const protect_spec = .{
    .options = .{ .none = true },
    .logging = preset.logging.success_error_fault.verbose,
    .errors = .{ .abort = sys.madvise_errors },
};
const wr_spec: mem.ReinterpretSpec = .{
    .composite = .{ .format = true },
    .reference = .{ .dereference = &.{} },
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
        .options = .{ .trace_state = true },
        .logging = preset.allocator.logging.verbose,
        .AddressSpace = preset.address_space.regular_128,
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
        .options = .{ .trace_state = true },
        .logging = preset.allocator.logging.verbose,
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

const AllocatorX = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .options = preset.allocator.options.small,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
    .AddressSpace = AddressSpace,
});

export fn resizeMany(allocator: *AllocatorX, array: *AllocatorX.StructuredHolder(u8), x: u64) void {
    try meta.wrap(array.increment(allocator, x));
}

noinline fn getViewOfRaw(x: []const u8, begin: u64, end: u64) []const u8 {
    return x[begin..end];
}
noinline fn getViewOfView(x: anytype, begin: u64, end: u64) []const u8 {
    return x.readAll()[begin..end];
}

fn testUtilityTestFunctions() !void {
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
            try builtin.expectEqual(u64, 5, mem.indexOfFirstEqualOne(u8, ',', "Hello, world!").?);
            try builtin.expectEqual(u64, 0, mem.indexOfFirstEqualOne(u8, 'H', "Hello, world!").?);
            try builtin.expectEqual(u64, 12, mem.indexOfFirstEqualOne(u8, '!', "Hello, world!").?);
            try builtin.expectEqual(u64, 0, mem.indexOfFirstEqualMany(u8, "Hello", "Hello, world!").?);
            try builtin.expectEqual(u64, 7, mem.indexOfFirstEqualMany(u8, "world", "Hello, world!").?);
            try builtin.expectEqual(u64, 7, mem.indexOfLastEqualMany(u8, "world", "Hello, world!").?);
        }
        { // null
            try builtin.expect(mem.indexOfFirstEqualOne(u8, 'f', "Hello, world!") == null);
            try builtin.expect(mem.indexOfFirstEqualMany(u8, "foo", "Hello, world!") == null);
        }
        { // impossible (null)
            try builtin.expect(mem.indexOfFirstEqualMany(u8, "Hello, world!", "foo") == null);
            try builtin.expect(mem.indexOfFirstEqualMany(u8, "", "Hello, world!") == null);
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
pub fn testNoImpact() !void {
    var rng: file.DeviceRandomBytes(16384) = .{};
    const S = struct {
        const src = @embedFile("./mem-test.zig");
        fn between(x: *u64) bool {
            if (!(x.* < src.len and x.* > 0)) {
                x.* /= 2;
                return false;
            }
            return true;
        }
    };
    const x: u64 = rng.readOneConditionally(u64, S.between);
    const y: u64 = rng.readOneConditionally(u64, S.between);
    const low: u64 = @min(x, y);
    const high: u64 = @max(x, y);
    try testing.expectEqualMany(u8, getViewOfRaw(S.src, low, high), getViewOfView(&mem.view(S.src), low, high));
}
pub fn main() !void {
    try meta.wrap(testMapGenericOverhead());
    try meta.wrap(testProtect());
    try meta.wrap(testLowSystemMemoryOperations());
    try meta.wrap(testAutomaticImplementation());
    try meta.wrap(testAllocatedImplementation());
    try meta.wrap(testRtAllocatedImplementation());
    try meta.wrap(testUtilityTestFunctions());
}
