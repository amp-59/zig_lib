const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const render = @import("./render.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");
const tokenizer = @import("./tokenizer.zig");

pub usingnamespace proc.start;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .options = preset.allocator.options.small,
});
const FakeAllocator = struct {
    pub const arena_index = 127;
};
const Array = Allocator.StructuredHolder(u8);
const PrintArray = mem.StaticString(1024 * 1024);
const DynamicArray = mem.StructuredVector(u8, null, 1, FakeAllocator, .{ .unit_alignment = true });
const StaticArray = mem.StructuredStaticVector(u8, null, 16384, 1, FakeAllocator, .{ .unit_alignment = true });

pub const is_correct: bool = true;
pub const use_alloc: bool = false;
pub const use_min: bool = false;
pub const use_dyn: bool = false;

const MinimalRenderArray = struct {
    start: u64,
    finish: u64,
    pub fn define(array: *MinimalRenderArray, count: usize) void {
        array.finish += count;
    }
    pub fn referOneUndefined(array: MinimalRenderArray) *u8 {
        return @intToPtr(*u8, array.finish);
    }
    pub fn writeCount(array: *MinimalRenderArray, comptime count: usize, values: [count]u8) void {
        for (values) |value, index| {
            @intToPtr(*u8, array.finish + index).* = value;
        }
        array.finish += count;
    }
    pub fn writeMany(array: *MinimalRenderArray, values: []const u8) void {
        for (values) |value, index| {
            @intToPtr(*u8, array.finish + index).* = value;
        }
        array.finish += values.len;
    }
    pub fn writeOne(array: *MinimalRenderArray, value: u8) void {
        @intToPtr(*u8, array.finish).* = value;
        array.finish += 1;
    }
    pub fn overwriteCountBack(array: MinimalRenderArray, comptime count: usize, values: [count]u8) void {
        const next: u64 = array.finish - count;
        for (values) |value, index| @intToPtr(*u8, next + index).* = value;
    }
    pub fn readAll(array: MinimalRenderArray) []const u8 {
        return @intToPtr([*]const u8, array.start)[0..array.len()];
    }
    pub fn undefineAll(array: *MinimalRenderArray) void {
        array.finish = array.start;
    }
    fn len(array: MinimalRenderArray) usize {
        return array.finish - array.start;
    }
    fn init(any: anytype) MinimalRenderArray {
        return .{
            .start = @ptrToInt(any),
            .finish = @ptrToInt(any),
        };
    }
};
fn hasDecls(comptime T: type) bool {
    const type_info: builtin.Type = @typeInfo(T);
    return type_info == .Struct or type_info == .Opaque or
        type_info == .Union or type_info == .Enum;
}
fn allocateRunTest(allocator: *Allocator, array: *Array, format: anytype, expected: ?[]const u8) !void {
    try array.appendFormat(allocator, format);
    if (expected) |value| {
        try testing.expectEqualMany(u8, array.readAll(allocator.*), value);
    } else {
        file.noexcept.write(2, array.readAll(allocator.*));
    }
    array.undefineAll(allocator.*);
}
fn minimalRunTest(_: *Allocator, array: anytype, format: anytype, expected: ?[]const u8) !void {
    format.formatWrite(array);
    if (expected) |value| {
        try testing.expectEqualMany(u8, array.readAll(), value);
    } else {
        file.noexcept.write(2, array.readAll());
    }
    array.undefineAll();
}

const runTest = if (use_alloc) allocateRunTest else minimalRunTest;

fn testSpecificCases() !void {
    var address_space: builtin.AddressSpace = .{};
    var allocator: Allocator = if (use_alloc) try Allocator.init(&address_space) else undefined;
    defer if (use_alloc) allocator.deinit(&address_space);

    var dst: [16384]u8 = undefined;
    var array = blk: {
        if (use_min) {
            break :blk MinimalRenderArray.init(&dst);
        } else if (use_alloc) {
            break :blk Array.init(&allocator);
        } else if (use_dyn) {
            break :blk DynamicArray{
                .impl = DynamicArray.Implementation.construct(.{
                    .lb_addr = @ptrToInt(&dst),
                    .up_addr = @ptrToInt(&dst) + dst.len,
                }),
            };
        } else {
            break :blk StaticArray{
                .impl = StaticArray.Implementation.construct(.{
                    .lb_addr = @ptrToInt(&dst),
                }),
            };
        }
    };
    try runTest(&allocator, &array, render.TypeFormat(.{}){ .value = packed struct(u128) { a: u64, b: u64 } }, "packed struct(u128) { a: u64, b: u64, }");
    try runTest(&allocator, &array, render.TypeFormat(.{}){ .value = packed struct(u64) { a: void, b: u64 } }, "packed struct(u64) { a: void, b: u64, }");
    try runTest(&allocator, &array, render.TypeFormat(.{}){ .value = packed union { a: u64, b: u64 } }, "packed union { a: u64, b: u64, }");
    try runTest(&allocator, &array, render.TypeFormat(.{}){ .value = enum { a, b } }, "enum(u1) { a, b, }");
    try runTest(&allocator, &array, render.TypeFormat(.{}){ .value = u64 }, "u64");
    try runTest(&allocator, &array, render.ComptimeIntFormat{ .value = 111111111 }, "111111111");
    try runTest(&allocator, &array, render.ComptimeIntFormat{ .value = -111111111 }, "-111111111");
    try runTest(&allocator, &array, render.PointerSliceFormat([]const u64, .{}){ .value = &.{ 1, 2, 3, 4, 5, 6 } }, "[]const u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.PointerSliceFormat([]const u64, .{ .omit_trailing_comma = false }){ .value = &.{ 7, 8, 9, 10, 11, 12 } }, "[]const u64{ 7, 8, 9, 10, 11, 12, }");
    try runTest(&allocator, &array, render.PointerSliceFormat([]const u64, .{}){ .value = &.{} }, "[]const u64{}");
    try runTest(&allocator, &array, render.ArrayFormat([6]u64, .{}){ .value = .{ 1, 2, 3, 4, 5, 6 } }, "[6]u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.ArrayFormat([0]u64, .{}){ .value = .{} }, "[0]u64{}");
    try runTest(&allocator, &array, render.PointerManyFormat([*:0]const u64, .{}){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr }, "[:0]const u64{ 1, 2, 3, 4, 5, 6 }");
    try runTest(&allocator, &array, render.PointerManyFormat([*]const u64, .{}){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr }, "[*]const u64{ ... }");
    try runTest(&allocator, &array, render.EnumLiteralFormat{ .value = .EnumLiteral }, ".EnumLiteral");
    try runTest(&allocator, &array, render.NullFormat{}, "null");
    try runTest(&allocator, &array, render.VoidFormat{}, "{}");
    try runTest(&allocator, &array, comptime render.render(.{ .inline_field_types = true }, mem.AbstractSpec), null);
}

pub fn main() !void {
    try meta.wrap(testSpecificCases());
}
