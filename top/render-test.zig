const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const render = @import("./render.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

const PrintArray = mem.StaticString(4096);

pub usingnamespace proc.start;

pub fn main() !void {
    var array: PrintArray = .{};
    array.writeFormat(render.TypeFormat{ .value = packed struct(u128) { a: u64, b: u64 } });
    try testing.expectEqualMany(u8, array.readAll(), "packed struct(u128) { a: u64, b: u64, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = packed union { a: u64, b: u64 } });
    try testing.expectEqualMany(u8, array.readAll(), "packed union { a: u64, b: u64, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = enum { a, b } });
    try testing.expectEqualMany(u8, array.readAll(), "enum(u1) { a, b, }");
    array.undefineAll();
    array.writeFormat(render.TypeFormat{ .value = u64 });
    try testing.expectEqualMany(u8, array.readAll(), "u64");
    array.undefineAll();
}
