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

const logging = true;
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
fn testImplementation() !void {
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
        const BitSet = mem.StructuredAutomaticStreamVector(.{ .child = bool, .count = 256 });
        var bit_set: BitSet = .{};
        bit_set.writeCount(4, .{ true, false, false, true });
        try testing.expectEqualMany(bool, bit_set.readAll(), &.{ true, false, false, true });
    }
}

pub fn main() !void {
    try meta.wrap(testImplementation());
    try meta.wrap(testLowSystemMemoryOperations());
}
