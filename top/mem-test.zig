const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;
pub const is_correct: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");
const invalid_holder_state: u64 = (0b110000110000 << 48);
const move_spec = if (default_errors) .{
    .options = .{},
    .logging = logging,
} else .{
    .options = .{},
    .logging = logging,
    .errors = builtin.root.errors,
};
const map_spec = if (default_errors)
.{
    .options = .{},
    .logging = logging,
} else .{
    .options = .{},
    .logging = logging,
    .errors = builtin.root.errors,
};
const resize_spec = if (default_errors)
.{
    .logging = logging,
} else .{
    .logging = logging,
    .errors = builtin.root.errors,
};
const unmap_spec = if (default_errors)
.{
    .logging = logging,
} else .{
    .logging = logging,
    .errors = builtin.root.errors,
};
const advice_opts = .{ .property = .{ .dump = true } };
const advise_spec = if (default_errors)
.{
    .options = advice_opts,
    .logging = logging,
} else .{
    .options = advice_opts,
    .logging = logging,
    .errors = builtin.root.errors,
};
const wr_spec: mem.ReinterpretSpec = .{
    .composite = .{ .format = true },
    .reference = .{ .dereference = &.{} },
};

const logging = .{ .Acquire = true, .Release = true };
const errors = null;

fn testLowSystemMemoryOperations() !void {
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end - addr;
    try meta.wrap(mem.map(map_spec, addr, len));
    try meta.wrap(mem.move(move_spec, addr, len, addr + len));
    addr += len;
    try meta.wrap(mem.resize(resize_spec, addr, len, len * 2));
    len *= 2;
    try meta.wrap(mem.advise(advise_spec, addr, len));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
}
fn view(comptime s: []const u8) mem.StructuredAutomaticView(.{ .child = u8, .count = s.len }) {
    return .{ .impl = .{ .auto = @ptrCast(*const [s.len]u8, s.ptr).* } };
}

fn testAllocatedImplementation() !void {
    const repeats: u64 = 0x100;
    const Allocator = mem.GenericArenaAllocator(.{
        // Allocations will begin offset 1GiB into the virtual address space.
        // This would be 0B, but to avoid the program mapping. Obviously
        // unsound on systems where the program is mapped randomly in the
        // address space.
        .arena_index = 0,
        .options = .{
            .trace_state = true,
        },
        .logging = .{
            .map = logging,
            .unmap = logging,
            .remap = logging,
            .reallocate = true,
        },
    });
    // TODO: Create warnings in case holder is freed after conversion.
    var address_space: mem.AddressSpace = .{};
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
            try testing.expectEqualMany(u8, "world!", &array_a.readCountAt(allocator, "Hello, ".len, "world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyAhead("Hello, ".len));
            array_a.stream("Hello, ".len);
            try testing.expectEqualMany(u8, "world!", array_a.readManyAhead("world!".len));
            try testing.expectEqualMany(u8, "Hello, ", array_a.readManyBehind("Hello, ".len));
            array_a.unstream("Hello, ".len);
        }
    }

    const ArrayB = Allocator.StructuredStreamVector(u8);

    var array_ab: ArrayB = .{ .impl = try allocator.convertHolderMany(ArrayA.Implementation, ArrayB.Implementation, array_a.impl) };
    defer array_ab.deinit(&allocator);

    var array_b: ArrayB = try ArrayB.init(&allocator, 256);
    defer array_b.deinit(&allocator);
    {
        var i: u64 = 0;
        while (i != repeats) : (i += 1) {
            try array_b.appendMany(&allocator, "Hello, world!");
            try array_b.appendCount(&allocator, 4, "1234".*);
            try array_b.appendFormat(&allocator, fmt.ux(0x1fee1dead));
            try testing.expectEqualMany(u8, "world!", &array_b.readCountAt("Hello, ".len, "world!".len));
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
        const array = view("Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, array.readAll(), "Hello, World!12340x1fee1dead");
        try testing.expectEqualMany(u8, "World!", &array.readCountAt("Hello, ".len, "World!".len));
        try builtin.expectEqual(u64, array.readAll().len, array.impl.bytes());
    }
    {
        const StaticString = mem.StructuredAutomaticStreamVector(.{ .child = u8, .count = 256 });
        var array: StaticString = .{};
        array.writeMany("Hello, world!");
        array.writeCount(4, "1234".*);
        array.writeFormat(fmt.ux(0x1fee1dead));
        try testing.expectEqualMany(u8, "world!", &array.readCountAt("Hello, ".len, "world!".len));
        try testing.expectEqualMany(u8, "Hello, ", array.readManyAhead("Hello, ".len));
        array.stream("Hello, ".len);
        try testing.expectEqualMany(u8, "world!", array.readManyAhead("world!".len));
        try testing.expectEqualMany(u8, "Hello, ", array.readManyBehind("Hello, ".len));
    }
    {
        const VectorBool = mem.StructuredAutomaticStreamVector(.{ .child = bool, .count = 256 });
        var bit_set: VectorBool = .{};
        bit_set.writeCount(4, .{ true, false, false, true });
        try testing.expectEqualMany(bool, bit_set.readAll(), &.{ true, false, false, true });
    }
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
    }
}

pub fn main() !void {
    try meta.wrap(testLowSystemMemoryOperations());
    try meta.wrap(testAutomaticImplementation());
    try meta.wrap(testAllocatedImplementation());
    try meta.wrap(testUtilityTestFunctions());
}
