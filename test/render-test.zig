const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;
const tokenizer = zl.tokenizer;
const virtual_test = @import("./virtual-test.zig");
pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;
pub const runtime_assertions: bool = true;
pub const trace: debug.Trace = .{
    .options = .{ .tokens = builtin.my_trace.options.tokens },
};

const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0x40000000,
    .divisions = 128,
});
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .logging = spec.allocator.logging.silent,
});
const Array = Allocator.StructuredHolder(u8);

fn testFormat(allocator: *Allocator, array: *Array, buf: [*]u8, format: anytype) !void {
    try array.appendFormat(allocator, format);
    var len: usize = format.formatWriteBuf(buf);
    testing.print(.{ array.readAll(allocator.*), '\n', buf[0..len], '\n' });
    try testing.expectEqualString(array.readAll(allocator.*), buf[0..len]);
    array.undefineAll(allocator.*);
}
fn testRenderArray(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    var value1 = [8]u8{ 0, 1, 2, 3, 4, 5, 6, 7 } ** 40;
    var value2 = [8][8]u8{
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
        @bitCast(@as(u64, 1)),
    };
    try testFormat(allocator, array, buf, fmt.any(value1));
    try testFormat(allocator, array, buf, fmt.any(value2));
    try testFormat(allocator, array, buf, fmt.render(.{ .omit_trailing_comma = true }, value1));
    try testFormat(allocator, array, buf, fmt.render(.{ .omit_trailing_comma = true }, value2));
}
fn testRenderType(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    try testFormat(allocator, array, buf, comptime fmt.any(packed struct(u120) { x: u64 = 5, y: packed struct { u32, u16 }, z: u8 }));
    try testFormat(allocator, array, buf, comptime fmt.any(extern union { x: u64 }));
    try testFormat(allocator, array, buf, comptime fmt.any(enum(u3) { x, y, z }));
}
fn testRenderSlice(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    try testFormat(allocator, array, buf, fmt.any(@as([]const u8, "c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c")));
    try testFormat(allocator, array, buf, fmt.any(@as([]const u8, "one\ntwo\nthree\n")));
    try testFormat(allocator, array, buf, fmt.any(@as([]const u16, &.{ 'o', 'n', 'e', '\n', 't', 'w', 'o', '\n', 't', 'h', 'r', 'e', 'e', '\n' })));
}
fn testRenderStruct(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    var tmp: [*]u8 = @ptrFromInt(0x40000000);
    try testFormat(allocator, array, buf, comptime fmt.any(packed struct(u120) { x: u64 = 5, y: packed struct { u32 = 1, u16 = 2 } = .{}, z: u8 = 255 }{}));
    try testFormat(allocator, array, buf, comptime fmt.any(struct { buf: [*]u8, buf_len: usize }{ .buf = tmp, .buf_len = 16 }));
    try testFormat(allocator, array, buf, comptime fmt.any(struct { buf: []u8, buf_len: usize }{ .buf = tmp[16..256], .buf_len = 32 }));
    try testFormat(allocator, array, buf, comptime fmt.any(struct { auto: [256]u8 = [1]u8{0xa} ** 256, auto_len: usize = 16 }{}));
}
fn testRenderUnion(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    try testFormat(allocator, array, buf, comptime fmt.any(extern union { x: u64 }{ .x = 0 }));
}
fn testRenderEnum(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    try testFormat(allocator, array, buf, comptime fmt.any(enum(u3) { x, y, z }.z));
}
pub fn main() !void {
    try mem.map(.{}, .{}, .{}, 0x40000000, 0x40000000);
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var buf: []u8 = try allocator.allocate(u8, 65536);
    var array: Array = Array.init(&allocator);
    try testRenderArray(&allocator, &array, buf.ptr);
    try testRenderType(&allocator, &array, buf.ptr);
    try testRenderSlice(&allocator, &array, buf.ptr);
    //try testRenderStruct(&allocator, &array, buf.ptr);
    //try testRenderEnum(&allocator, &array, buf.ptr);
}
