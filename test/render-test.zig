const top = @import("../zig_lib.zig");
const mem = top.mem;
const fmt = top.fmt;
const proc = top.proc;
const meta = top.meta;
const file = top.file;
const render = fmt;
const spec = top.spec;
const builtin = top.builtin;
const testing = top.testing;
const tokenizer = top.tokenizer;
const virtual_test = @import("./virtual-test.zig");
pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
pub const AddressSpace = spec.address_space.regular_128;
pub const runtime_assertions: bool = true;
const FakeAllocator = struct {
    pub const arena_index = 127;
};
const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = AddressSpace,
    .logging = spec.allocator.logging.silent,
    .options = spec.allocator.options.small,
});
const Array = Allocator.StructuredHolder(u8);
const PrintArray = mem.StaticString(1024 * 1024);
const DynamicArray = mem.StructuredVector(u8, null, 1, FakeAllocator, .{ .unit_alignment = true });
const StaticArray = mem.StructuredStaticVector(u8, null, 16384, 1, FakeAllocator, .{ .unit_alignment = true });
const use_alloc: bool = false;
const use_min: bool = false;
const use_dyn: bool = false;
const cmp_test: bool = false;
const huge_test: bool = false;
const use_std: bool = !builtin.is_debug and false;
const std = @import("std");
const err: std.fs.File = std.io.getStdErr();
const render_spec: fmt.RenderSpec = .{
    .radix = 10,
    .omit_default_fields = false,
    .omit_type_names = false,
};
const runTest = if (use_alloc) allocateRunTest else minimalRunTest;
fn testLoopFormatAgainstStandard(comptime ThisAddressSpace: type) anyerror!void {
    const max_index: ThisAddressSpace.Index = comptime AddressSpace.addr_spec.count();
    comptime var arena_index: AddressSpace.Index = 0;
    var array: mem.StaticString(1024 * 1024) = .{};
    var buf = if (use_std) std.io.bufferedWriter(std.io.getStdOut().writer());
    const writer = if (use_std) buf.writer();
    inline while (arena_index != max_index) : (arena_index += 1) {
        if (use_std) {
            writer.print("s: {}:\t{}\n", .{ arena_index, AddressSpace.arena(arena_index) }) catch {};
        } else {
            array.writeAny(spec.reinterpret.fmt, .{
                "s: ", fmt.render(render_spec, arena_index),
                ":\t", fmt.render(render_spec, AddressSpace.arena(arena_index)),
                "'\n",
            });
        }
    }
    if (use_std) {
        try buf.flush();
    } else {
        builtin.debug.write(array.readAll());
    }
}
fn testWithComplexList(comptime what: fn (comptime type) anyerror!void) anyerror!void {
    const ThisAddressSpace: type = mem.GenericDiscreteAddressSpace(.{ .list = virtual_test.complex_list });
    return what(ThisAddressSpace);
}
fn testWithComplexListSubSpace(comptime what: fn (comptime type) anyerror!void) anyerror!void {
    const ThisAddressSpace = mem.GenericDiscreteAddressSpace(.{ .list = virtual_test.complex_list });
    const SubAddressSpace = mem.GenericDiscreteSubAddressSpace(.{ .list = virtual_test.rare_sub_list }, ThisAddressSpace);
    return what(SubAddressSpace);
}
fn testAgainstStandard() !void {
    try meta.wrap(testWithComplexList(testLoopFormatAgainstStandard));
}
const MinimalRenderArray = struct {
    start: u64,
    finish: u64,
    pub fn define(array: *MinimalRenderArray, count: usize) void {
        array.finish += count;
    }
    pub fn referOneUndefined(array: MinimalRenderArray) *u8 {
        return @as(*u8, @ptrFromInt(array.finish));
    }
    pub fn writeCount(array: *MinimalRenderArray, comptime count: usize, values: [count]u8) void {
        for (values, 0..) |value, index| {
            @as(*u8, @ptrFromInt(array.finish + index)).* = value;
        }
        array.finish += count;
    }
    pub fn writeMany(array: *MinimalRenderArray, values: []const u8) void {
        for (values, 0..) |value, index| {
            @as(*u8, @ptrFromInt(array.finish + index)).* = value;
        }
        array.finish += values.len;
    }
    pub fn writeOne(array: *MinimalRenderArray, value: u8) void {
        @as(*u8, @ptrFromInt(array.finish)).* = value;
        array.finish += 1;
    }
    pub fn overwriteCountBack(array: MinimalRenderArray, comptime count: usize, values: [count]u8) void {
        const next: u64 = array.finish - count;
        for (values, 0..) |value, index| @as(*u8, @ptrFromInt(next + index)).* = value;
    }
    pub fn readAll(array: MinimalRenderArray) []const u8 {
        return @as([*]const u8, @ptrFromInt(array.start))[0..array.len()];
    }
    pub fn undefineAll(array: *MinimalRenderArray) void {
        array.finish = array.start;
    }
    fn len(array: MinimalRenderArray) usize {
        return array.finish - array.start;
    }
    fn init(any: anytype) MinimalRenderArray {
        return .{
            .start = @intFromPtr(any),
            .finish = @intFromPtr(any),
        };
    }
};
fn hasDecls(comptime T: type) bool {
    const type_info: builtin.Type = @typeInfo(T);
    return type_info == .Struct or type_info == .Opaque or
        type_info == .Union or type_info == .Enum;
}
fn allocateRunTest(allocator: *Allocator, array: *Array, format: anytype, expected: ?[]const u8) !void {
    try meta.wrap(array.appendFormat(allocator, format));
    if (expected) |value| {
        try testing.expectEqualMany(u8, array.readAll(allocator.*), value);
    } else {
        builtin.debug.write(array.readAll(allocator.*));
    }
    array.undefineAll(allocator.*);
}
fn minimalRunTest(_: *Allocator, array: anytype, format: anytype, expected: ?[]const u8) !void {
    format.formatWrite(array);
    if (expected) |value| {
        try testing.expectEqualMany(u8, array.readAll(), value);
    } else {
        builtin.debug.write(array.readAll());
    }
    array.undefineAll();
}
fn testSpecificCases() !void {
    var address_space: builtin.AddressSpace() = .{};
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
                    .lb_addr = @intFromPtr(&dst),
                    .up_addr = @intFromPtr(&dst) + dst.len,
                }),
            };
        } else {
            break :blk StaticArray{
                .impl = StaticArray.Implementation.construct(.{
                    .lb_addr = @intFromPtr(&dst),
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
    try runTest(
        &allocator,
        &array,
        render.PointerSliceFormat(.{}, []const u64){ .value = &.{ 1, 2, 3, 4, 5, 6 } },
        "[]const u64{ 1, 2, 3, 4, 5, 6 }",
    );
    try runTest(
        &allocator,
        &array,
        render.PointerSliceFormat(.{ .omit_trailing_comma = false }, []const u64){ .value = &.{ 7, 8, 9, 10, 11, 12 } },
        "[]const u64{ 7, 8, 9, 10, 11, 12, }",
    );
    try runTest(&allocator, &array, render.PointerSliceFormat(.{}, []const u64){ .value = &.{} }, "[]const u64{}");
    try runTest(
        &allocator,
        &array,
        render.ArrayFormat(.{}, [6]u64){ .value = .{ 1, 2, 3, 4, 5, 6 } },
        "[6]u64{ 1, 2, 3, 4, 5, 6 }",
    );
    try runTest(&allocator, &array, render.ArrayFormat(.{}, [0]u64){ .value = .{} }, "[0]u64{}");
    try runTest(
        &allocator,
        &array,
        render.PointerManyFormat(.{}, [*:0]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr },
        "[:0]const u64{ 1, 2, 3, 4, 5, 6 }",
    );
    try runTest(
        &allocator,
        &array,
        render.PointerManyFormat(.{}, [*]const u64){ .value = @as([:0]const u64, &[_:0]u64{ 1, 2, 3, 4, 5, 6 }).ptr },
        "[*]const u64{ ... }",
    );
    try runTest(&allocator, &array, render.PointerSliceFormat(.{}, []const u8){ .value = array.readAll() }, "\"\"");
    try runTest(&allocator, &array, render.EnumLiteralFormat{ .value = .EnumLiteral }, ".EnumLiteral");
    try runTest(&allocator, &array, render.NullFormat{}, "null");
    try runTest(&allocator, &array, render.VoidFormat{}, "{}");
    try runTest(&allocator, &array, render.TypeFormat(.{ .omit_container_decls = false }){ .value = struct {
        pub const x: u64 = 25;
        pub const y: u64 = 50;
    } }, "struct { pub const x: u64 = 25; pub const y: u64 = 50; }");
    try runTest(&allocator, &array, render.StructFormat(.{
        .infer_type_names = true,
        .omit_trailing_comma = true,
    }, ExternTaggedUnion){ .value = .{ .x = .{ .a = 14 }, .x_tag = .a } }, ".{ .x = .{ .a = 14 }, .x_tag = .a }");
}
const ExternTaggedUnion = struct {
    x: packed union { a: u64, b: u32 },
    x_tag: enum { a, b },
};
pub fn testOneBigCase() !void {
    var array: mem.StaticString(0x10000) = .{};
    array.writeFormat(comptime render.GenericTypeDescrFormat(.{ .options = .{ .depth = 0 } }).init(mem.AbstractSpec));
    builtin.debug.write(array.readAll());
}
pub fn testHugeCase() !void {
    var address_space: builtin.AddressSpace() = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var unlimited_array: Allocator.StructuredVector(u8) = try Allocator.StructuredVector(u8).init(&allocator, 1024 * 1024);
    const sys = top.sys;
    try unlimited_array.appendAny(spec.reinterpret.fmt, &allocator, comptime render.TypeFormat(.{ .omit_container_decls = false, .radix = 2 }){ .value = sys });
    builtin.debug.write(unlimited_array.readAll());
    builtin.debug.write("\n");
    unlimited_array.undefineAll();
}
pub fn main() !void {
    if (huge_test) {
        return meta.wrap(testHugeCase());
    }
    if (cmp_test) {
        return meta.wrap(testAgainstStandard());
    } else {
        try meta.wrap(testSpecificCases());
        return meta.wrap(testOneBigCase());
    }
}
