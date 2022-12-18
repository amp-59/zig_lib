const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const render = @import("./render.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

const std = @import("std");

pub usingnamespace proc.start;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = mem.alloc_preset.silent,
    .options = mem.alloc_preset.small,
});
const Array = Allocator.StructuredHolder(u8);
const PrintArray = mem.StaticString(1024 * 1024);

pub const is_correct: bool = true;

fn hasDecls(comptime T: type) bool {
    const type_info: builtin.Type = @typeInfo(T);
    return type_info == .Struct or type_info == .Opaque or
        type_info == .Union or type_info == .Enum;
}

fn allocateRunTest(allocator: *Allocator, array: *Array, format: anytype, expected: []const u8) !void {
    try array.appendFormat(allocator, format);
    try testing.expectEqualMany(u8, array.readAll(allocator.*), expected);
    array.undefineAll(allocator.*);
}
const runTest = allocateRunTest;

fn testSpecificCases() !void {
    var address_space: mem.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    var array: Array = Array.init(&allocator);
    try runTest(&allocator, &array, render.TypeFormat{ .value = packed struct(u128) { a: u64, b: u64 } }, "packed struct(u128) { a: u64, b: u64, }");
    try runTest(&allocator, &array, render.TypeFormat{ .value = packed union { a: u64, b: u64 } }, "packed union { a: u64, b: u64, }");
    try runTest(&allocator, &array, render.TypeFormat{ .value = enum { a, b } }, "enum(u1) { a, b, }");
    try runTest(&allocator, &array, render.TypeFormat{ .value = u64 }, "u64");
    try runTest(&allocator, &array, render.ComptimeIntFormat{ .value = 111111111 }, "111111111");
    try runTest(&allocator, &array, render.ComptimeIntFormat{ .value = -111111111 }, "-111111111");
    try runTest(&allocator, &array, render.PointerSliceFormat([]const u64){ .value = &.{ 1, 2, 3, 4, 5, 6 } }, "[]const u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.PointerSliceFormat([]const u64){ .value = &.{} }, "[]const u64{}");
    try runTest(&allocator, &array, render.ArrayFormat([6]u64){ .value = .{ 1, 2, 3, 4, 5, 6 } }, "[6]u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.ArrayFormat([0]u64){ .value = .{} }, "[0]u64{}");
    try runTest(&allocator, &array, render.PointerManyFormat([*:0]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr }, "[:0]const u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.PointerManyFormat([*]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr }, "[*]const u64{ ... }");
    try runTest(&allocator, &array, render.EnumLiteralFormat{ .value = .EnumLiteral }, ".EnumLiteral");
    try runTest(&allocator, &array, render.NullFormat{}, "null");
    try runTest(&allocator, &array, render.VoidFormat{}, "{}");
    try array.appendFormat(&allocator, render.StructFormat(@import("std").Target){ .value = @import("builtin").target });
    file.noexcept.write(2, array.readAll(allocator));
}

pub fn main() !void {
    try meta.wrap(testSpecificCases());
}
