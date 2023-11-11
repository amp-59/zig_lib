const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const sys = zl.sys;
const mem = zl.mem;
const meta = zl.meta;
const file = zl.file;
const proc = zl.proc;
const debug = zl.debug;
const parse = zl.parse;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub const logging_override: debug.Logging.Override = debug.spec.logging.override.verbose;
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0x40000000,
    .divisions = 128,
});
const Allocator = mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .logging = mem.dynamic.spec.logging.silent,
});
const PrintArray = mem.array.StaticString(4096);
const Array = Allocator.StructuredHolder(u8);
const TypeDescr = fmt.GenericTypeDescrFormat(.{});
const BigTypeDescr = fmt.GenericTypeDescrFormat(.{ .decls = true, .default_field_values = .{ .exact_safe = .{} } });
const test_size: bool = false;
fn testIntToString() !void {
    const T: type = u64;
    var arg1: T = 0;
    var iint: i64 = -0xfee1dead;
    var uint: u64 = 0xdeadbeef;
    try testing.expectEqualMany(u8, builtin.fmt.ix64(iint).readAll(), "-0xfee1dead");
    iint = 0x0;
    try testing.expectEqualMany(u8, builtin.fmt.ix64(iint).readAll(), "0x0");
    try testing.expectEqualMany(u8, builtin.fmt.ux64(uint).readAll(), "0xdeadbeef");
    const bs: [2]bool = .{ true, false };
    for (bs) |b_0| {
        builtin.assertEqual(u64, @intFromBool(b_0), builtin.int(u64, b_0));
        for (bs) |b_1| {
            builtin.assertEqual(u64, @intFromBool(b_0 or b_1), builtin.int2v(u64, b_0, b_1));
            builtin.assertEqual(u64, @intFromBool(b_0 and b_1), builtin.int2a(u64, b_0, b_1));
            for (bs) |b_2| {
                builtin.assertEqual(u64, @intFromBool(b_0 or b_1 or b_2), builtin.int3v(u64, b_0, b_1, b_2));
                builtin.assertEqual(u64, @intFromBool(b_0 and b_1 and b_2), builtin.int3a(u64, b_0, b_1, b_2));
            }
        }
    }
    try testing.expectEqualMany(u8, builtin.fmt.ub8(0).readAll(), "0b00000000");
    try testing.expectEqualMany(u8, builtin.fmt.ub8(1).readAll(), "0b00000001");
    const start = @intFromPtr(&arg1);
    var inc: u64 = 1;
    uint = start;
    while (uint - start < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
        builtin.assertEqual(u64, uint, builtin.parse.ub(u64, builtin.fmt.ub64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.uo(u64, builtin.fmt.uo64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.ud(u64, builtin.fmt.ud64(uint).readAll()));
        builtin.assertEqual(u64, uint, builtin.parse.ux(u64, builtin.fmt.ux64(uint).readAll()));
        builtin.assertEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ub(u32, builtin.fmt.ub32(@as(u32, @truncate(uint))).readAll()));
        builtin.assertEqual(u32, @as(u32, @truncate(uint)), builtin.parse.uo(u32, builtin.fmt.uo32(@as(u32, @truncate(uint))).readAll()));
        builtin.assertEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ud(u32, builtin.fmt.ud32(@as(u32, @truncate(uint))).readAll()));
        builtin.assertEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ux(u32, builtin.fmt.ux32(@as(u32, @truncate(uint))).readAll()));
        builtin.assertEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ub(u16, builtin.fmt.ub16(@as(u16, @truncate(uint))).readAll()));
        builtin.assertEqual(u16, @as(u16, @truncate(uint)), builtin.parse.uo(u16, builtin.fmt.uo16(@as(u16, @truncate(uint))).readAll()));
        builtin.assertEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ud(u16, builtin.fmt.ud16(@as(u16, @truncate(uint))).readAll()));
        builtin.assertEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ux(u16, builtin.fmt.ux16(@as(u16, @truncate(uint))).readAll()));
        builtin.assertEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ub(u8, builtin.fmt.ub8(@as(u8, @truncate(uint))).readAll()));
        builtin.assertEqual(u8, @as(u8, @truncate(uint)), builtin.parse.uo(u8, builtin.fmt.uo8(@as(u8, @truncate(uint))).readAll()));
        builtin.assertEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ud(u8, builtin.fmt.ud8(@as(u8, @truncate(uint))).readAll()));
        builtin.assertEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ux(u8, builtin.fmt.ux8(@as(u8, @truncate(uint))).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ub(u64, builtin.fmt.ub64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.uo(u64, builtin.fmt.uo64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ud(u64, builtin.fmt.ud64(uint).readAll()));
        try builtin.expectEqual(u64, uint, builtin.parse.ux(u64, builtin.fmt.ux64(uint).readAll()));
        try builtin.expectEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ub(u32, builtin.fmt.ub32(@as(u32, @truncate(uint))).readAll()));
        try builtin.expectEqual(u32, @as(u32, @truncate(uint)), builtin.parse.uo(u32, builtin.fmt.uo32(@as(u32, @truncate(uint))).readAll()));
        try builtin.expectEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ud(u32, builtin.fmt.ud32(@as(u32, @truncate(uint))).readAll()));
        try builtin.expectEqual(u32, @as(u32, @truncate(uint)), builtin.parse.ux(u32, builtin.fmt.ux32(@as(u32, @truncate(uint))).readAll()));
        try builtin.expectEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ub(u16, builtin.fmt.ub16(@as(u16, @truncate(uint))).readAll()));
        try builtin.expectEqual(u16, @as(u16, @truncate(uint)), builtin.parse.uo(u16, builtin.fmt.uo16(@as(u16, @truncate(uint))).readAll()));
        try builtin.expectEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ud(u16, builtin.fmt.ud16(@as(u16, @truncate(uint))).readAll()));
        try builtin.expectEqual(u16, @as(u16, @truncate(uint)), builtin.parse.ux(u16, builtin.fmt.ux16(@as(u16, @truncate(uint))).readAll()));
        try builtin.expectEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ub(u8, builtin.fmt.ub8(@as(u8, @truncate(uint))).readAll()));
        try builtin.expectEqual(u8, @as(u8, @truncate(uint)), builtin.parse.uo(u8, builtin.fmt.uo8(@as(u8, @truncate(uint))).readAll()));
        try builtin.expectEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ud(u8, builtin.fmt.ud8(@as(u8, @truncate(uint))).readAll()));
        try builtin.expectEqual(u8, @as(u8, @truncate(uint)), builtin.parse.ux(u8, builtin.fmt.ux8(@as(u8, @truncate(uint))).readAll()));
    }
    iint = @as(isize, @bitCast(start));
    inc = 1;
    while (iint < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
        builtin.assertEqual(i64, iint, builtin.parse.ib(i64, builtin.fmt.ib64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.io(i64, builtin.fmt.io64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.id(i64, builtin.fmt.id64(iint).readAll()));
        builtin.assertEqual(i64, iint, builtin.parse.ix(i64, builtin.fmt.ix64(iint).readAll()));
        builtin.assertEqual(i32, @as(i32, @truncate(iint)), builtin.parse.ib(i32, builtin.fmt.ib32(@as(i32, @truncate(iint))).readAll()));
        builtin.assertEqual(i32, @as(i32, @truncate(iint)), builtin.parse.io(i32, builtin.fmt.io32(@as(i32, @truncate(iint))).readAll()));
        builtin.assertEqual(i32, @as(i32, @truncate(iint)), builtin.parse.id(i32, builtin.fmt.id32(@as(i32, @truncate(iint))).readAll()));
        builtin.assertEqual(i32, @as(i32, @truncate(iint)), builtin.parse.ix(i32, builtin.fmt.ix32(@as(i32, @truncate(iint))).readAll()));
        builtin.assertEqual(i16, @as(i16, @truncate(iint)), builtin.parse.ib(i16, builtin.fmt.ib16(@as(i16, @truncate(iint))).readAll()));
        builtin.assertEqual(i16, @as(i16, @truncate(iint)), builtin.parse.io(i16, builtin.fmt.io16(@as(i16, @truncate(iint))).readAll()));
        builtin.assertEqual(i16, @as(i16, @truncate(iint)), builtin.parse.id(i16, builtin.fmt.id16(@as(i16, @truncate(iint))).readAll()));
        builtin.assertEqual(i16, @as(i16, @truncate(iint)), builtin.parse.ix(i16, builtin.fmt.ix16(@as(i16, @truncate(iint))).readAll()));
        builtin.assertEqual(i8, @as(i8, @truncate(iint)), builtin.parse.ib(i8, builtin.fmt.ib8(@as(i8, @truncate(iint))).readAll()));
        builtin.assertEqual(i8, @as(i8, @truncate(iint)), builtin.parse.io(i8, builtin.fmt.io8(@as(i8, @truncate(iint))).readAll()));
        builtin.assertEqual(i8, @as(i8, @truncate(iint)), builtin.parse.id(i8, builtin.fmt.id8(@as(i8, @truncate(iint))).readAll()));
        builtin.assertEqual(i8, @as(i8, @truncate(iint)), builtin.parse.ix(i8, builtin.fmt.ix8(@as(i8, @truncate(iint))).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.ib(i64, builtin.fmt.ib64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.io(i64, builtin.fmt.io64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.id(i64, builtin.fmt.id64(iint).readAll()));
        try builtin.expectEqual(i64, iint, builtin.parse.ix(i64, builtin.fmt.ix64(iint).readAll()));
        try builtin.expectEqual(i32, @as(i32, @truncate(iint)), builtin.parse.ib(i32, builtin.fmt.ib32(@as(i32, @truncate(iint))).readAll()));
        try builtin.expectEqual(i32, @as(i32, @truncate(iint)), builtin.parse.io(i32, builtin.fmt.io32(@as(i32, @truncate(iint))).readAll()));
        try builtin.expectEqual(i32, @as(i32, @truncate(iint)), builtin.parse.id(i32, builtin.fmt.id32(@as(i32, @truncate(iint))).readAll()));
        try builtin.expectEqual(i32, @as(i32, @truncate(iint)), builtin.parse.ix(i32, builtin.fmt.ix32(@as(i32, @truncate(iint))).readAll()));
        try builtin.expectEqual(i16, @as(i16, @truncate(iint)), builtin.parse.ib(i16, builtin.fmt.ib16(@as(i16, @truncate(iint))).readAll()));
        try builtin.expectEqual(i16, @as(i16, @truncate(iint)), builtin.parse.io(i16, builtin.fmt.io16(@as(i16, @truncate(iint))).readAll()));
        try builtin.expectEqual(i16, @as(i16, @truncate(iint)), builtin.parse.id(i16, builtin.fmt.id16(@as(i16, @truncate(iint))).readAll()));
        try builtin.expectEqual(i16, @as(i16, @truncate(iint)), builtin.parse.ix(i16, builtin.fmt.ix16(@as(i16, @truncate(iint))).readAll()));
        try builtin.expectEqual(i8, @as(i8, @truncate(iint)), builtin.parse.ib(i8, builtin.fmt.ib8(@as(i8, @truncate(iint))).readAll()));
        try builtin.expectEqual(i8, @as(i8, @truncate(iint)), builtin.parse.io(i8, builtin.fmt.io8(@as(i8, @truncate(iint))).readAll()));
        try builtin.expectEqual(i8, @as(i8, @truncate(iint)), builtin.parse.id(i8, builtin.fmt.id8(@as(i8, @truncate(iint))).readAll()));
        try builtin.expectEqual(i8, @as(i8, @truncate(iint)), builtin.parse.ix(i8, builtin.fmt.ix8(@as(i8, @truncate(iint))).readAll()));
    }
}
fn testBytesFormat() !void {
    for ([_]struct { []const u8, u64 }{
        .{ "0B", 0 },
        .{ "1KiB", 1024 },
        .{ "12.224EiB", 14094246983574119504 },
        .{ "3.055GiB", 3281572597 },
        .{ "48.898KiB", 50072 },
        .{ "965.599PiB", 1087169224958701762 },
        .{ "241.399MiB", 253126310 },
        .{ "3.771KiB", 3862 },
        .{ "13.398EiB", 15448432752139178971 },
        .{ "3.349GiB", 3596868541 },
        .{ "53.596KiB", 54883 },
        .{ "15.515EiB", 17888947792637945813 },
        .{ "3.878GiB", 4165095228 },
        .{ "62.064KiB", 63554 },
        .{ "8.527EiB", 9831702696906455266 },
        .{ "2.131GiB", 2289121667 },
        .{ "34.110KiB", 34929 },
        .{ "483.670PiB", 544565144281564221 },
        .{ "120.916MiB", 126791453 },
        .{ "8MiB", 8 * 1024 * 1024 },
        .{ "1.888KiB", 1934 },
        .{ "15.571EiB", 17953561487338746285 },
        .{ "3.892GiB", 4180139276 },
        .{ "62.288KiB", 63783 },
        .{ "120.314PiB", 135462692621452395 },
        .{ "30.078MiB", 31539865 },
        .{ "481B", 481 },
        .{ "9.218EiB", 10629341187628544125 },
        .{ "2.304GiB", 2474836350 },
        .{ "36.877KiB", 37763 },
        .{ "3.470EiB", 4002398647170186451 },
        .{ "888.710MiB", 931881053 },
        .{ "13.885KiB", 14219 },
        .{ "10.413EiB", 12006395527087239748 },
        .{ "2.602GiB", 2795456798 },
        .{ "41.655KiB", 42655 },
        .{ "15.978EiB", 18422768632654111595 },
        .{ "3.994GiB", 4289385078 },
        .{ "63.916KiB", 65450 },
        .{ "13.546EiB", 15619441245434454517 },
        .{ "3.386GiB", 3636684558 },
        .{ "54.190KiB", 55491 },
        .{ "13.297EiB", 15332095086078333874 },
        .{ "3.324GiB", 3569781567 },
        .{ "53.193KiB", 54470 },
        .{ "358.001PiB", 403074625244083568 },
        .{ "89.500MiB", 93848124 },
        .{ "1.398KiB", 1432 },
        .{ "5.851EiB", 6747100094387843530 },
        .{ "1.462GiB", 1570931657 },
        .{ "23.408KiB", 23970 },
        .{ "15.999EiB", ~@as(u64, 0) },
    }) |pair| {
        var buf: [4096]u8 = undefined;
        var ptr: [*]u8 = fmt.Bytes.write(&buf, pair[1]);
        try testing.expectEqualMany(u8, pair[0], fmt.slice(ptr, &buf));
    }
}
// There is currently only one implementation of intToString, the `fmt` one.
fn testEquivalentIntToStringFormat() !void {
    const ubin = fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
    const sbin = fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
    var uint: u64 = 0;
    const seed: u64 = @intFromPtr(&uint);
    uint = seed;
    try testing.expectEqualMany(u8, "0b0", (sbin{ .value = 0 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "-0b1", (sbin{ .value = -1 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "0b0", (ubin{ .value = 0 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "0b1", (ubin{ .value = 1 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, fmt.ub64(uint).readAll(), fmt.ub64(uint).formatConvert().readAll());
    var buf: [4096]u8 = undefined;
    while (uint < seed +% 0x1000) : (uint +%= 1) {
        const uint_32: u32 = @as(u32, @truncate(uint));
        const uint_16: u16 = @as(u16, @truncate(uint));
        const uint_8: u8 = @as(u8, @truncate(uint));
        const sint_64: i64 = @bitReverse(@as(i64, @bitCast(uint)));
        const sint_32: i32 = @bitReverse(@as(i32, @bitCast(@as(u32, @truncate(uint)))));
        const sint_16: i16 = @bitReverse(@as(i16, @bitCast(@as(u16, @truncate(uint)))));
        const sint_8: i8 = @bitReverse(@as(i8, @bitCast(@as(u8, @truncate(uint)))));
        try testing.expectEqualMany(u8, fmt.ub64(uint).readAll(), buf[0..fmt.ub64(uint).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ub32(uint_32).readAll(), buf[0..fmt.ub32(uint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ub16(uint_16).readAll(), buf[0..fmt.ub16(uint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ub8(uint_8).readAll(), buf[0..fmt.ub8(uint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.uo64(uint).readAll(), buf[0..fmt.uo64(uint).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.uo32(uint_32).readAll(), buf[0..fmt.uo32(uint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.uo16(uint_16).readAll(), buf[0..fmt.uo16(uint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.uo8(uint_8).readAll(), buf[0..fmt.uo8(uint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ud64(uint).readAll(), buf[0..fmt.ud64(uint).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ud32(uint_32).readAll(), buf[0..fmt.ud32(uint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ud16(uint_16).readAll(), buf[0..fmt.ud16(uint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ud8(uint_8).readAll(), buf[0..fmt.ud8(uint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ux64(uint).readAll(), buf[0..fmt.ux64(uint).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ux32(uint_32).readAll(), buf[0..fmt.ux32(uint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ux16(uint_16).readAll(), buf[0..fmt.ux16(uint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ux8(uint_8).readAll(), buf[0..fmt.ux8(uint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ib64(sint_64).readAll(), buf[0..fmt.ib64(sint_64).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ib32(sint_32).readAll(), buf[0..fmt.ib32(sint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ib16(sint_16).readAll(), buf[0..fmt.ib16(sint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ib8(sint_8).readAll(), buf[0..fmt.ib8(sint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.io64(sint_64).readAll(), buf[0..fmt.io64(sint_64).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.io32(sint_32).readAll(), buf[0..fmt.io32(sint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.io16(sint_16).readAll(), buf[0..fmt.io16(sint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.io8(sint_8).readAll(), buf[0..fmt.io8(sint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.id64(sint_64).readAll(), buf[0..fmt.id64(sint_64).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.id32(sint_32).readAll(), buf[0..fmt.id32(sint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.id16(sint_16).readAll(), buf[0..fmt.id16(sint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.id8(sint_8).readAll(), buf[0..fmt.id8(sint_8).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ix64(sint_64).readAll(), buf[0..fmt.ix64(sint_64).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ix32(sint_32).readAll(), buf[0..fmt.ix32(sint_32).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ix16(sint_16).readAll(), buf[0..fmt.ix16(sint_16).formatWriteBuf(&buf)]);
        try testing.expectEqualMany(u8, fmt.ix8(sint_8).readAll(), buf[0..fmt.ix8(sint_8).formatWriteBuf(&buf)]);
    }
}
fn testBytesToHex() !void {
    testing.announce(@src());
    const input: []const u8 = "0123456789abcdef";
    var buf0: [2 *% input.len]u8 = undefined;
    var buf1: [2 *% input.len]u8 = undefined;
    @memset(&buf0, 0);
    @memset(&buf1, 0);
    const encoded: []const u8 = fmt.bytesToHex(&buf0, input);
    const decoded: []const u8 = fmt.hexToBytes2(&buf0, encoded);
    try testing.expectEqualMany(u8, input, decoded);
}
fn testHexToBytes() !void {
    testing.announce(@src());
    var buf: [32]u8 = .{0} ** 32;
    var bytes: [64]u8 = .{0} ** 64;
    try testing.expectEqualMany(u8, "90" ** 32, fmt.bytesToHex(&bytes, try fmt.hexToBytes(&buf, "90" ** 32)));
    try testing.expectEqualMany(u8, "abcd", fmt.bytesToHex(&bytes, try fmt.hexToBytes(&buf, "abcd")));
    try testing.expectEqualMany(u8, "", fmt.bytesToHex(&bytes, try fmt.hexToBytes(&buf, "")));
    _ = fmt.hexToBytes(&buf, "012z") catch |err| {
        if (err != error.InvalidEncoding) {
            return err;
        }
    };
    _ = fmt.hexToBytes(&buf, "aaa") catch |err| {
        if (err != error.InvalidLength) {
            return err;
        }
    };
    _ = fmt.hexToBytes(buf[0..1], "abcd") catch |err| {
        if (err != error.NoSpaceLeft) {
            return err;
        }
    };
}
fn TestFormatAlloc(comptime spec: fmt.RenderSpec, comptime Value: type) type {
    const rc = builtin.requireComptime(Value);
    return struct {
        const run = if (rc) runCx else runRt;
        fn runCx(allocator: *Allocator, array: *Array, expected: []const u8, comptime value: Value) !void {
            debug.write("run(" ++ comptime fmt.eval(.{ .omit_trailing_comma = true }, spec) ++ ", " ++ @typeName(Value) ++ ")\n");
            try array.appendFormat(allocator, comptime fmt.render(spec, value));
            try testing.expectEqualString(expected, array.readAll(allocator.*));
            try array.appendMany(allocator, "\n\n");
            debug.write(array.readAll(allocator.*));
            array.undefineAll(allocator.*);
        }
        fn runRt(allocator: *Allocator, array: *Array, expected: []const u8, value: Value) !void {
            debug.write("run(" ++ comptime fmt.eval(.{ .omit_trailing_comma = true }, spec) ++ ", " ++ @typeName(Value) ++ ")\n");
            try array.appendFormat(allocator, fmt.render(spec, value));
            try testing.expectEqualString(expected, array.readAll(allocator.*));
            try array.appendMany(allocator, "\n\n");
            debug.write(array.readAll(allocator.*));
            array.undefineAll(allocator.*);
        }
    };
}
fn testFormats(allocator: *Allocator, array: *Array, format1: anytype, format2: anytype) !void {
    testing.announce(@src());
    try array.appendFormat(allocator, format1);
    try array.appendOne(allocator, 0xa);
    const slice1: []const u8 = array.readAll(allocator.*);
    allocator.ub_addr +%= slice1.len;
    try array.appendFormat(allocator, format2);
    try array.appendOne(allocator, 0xa);
    const slice2: []const u8 = array.readAll(allocator.*);
    allocator.ub_addr -%= slice1.len;
    debug.write(slice1);
    debug.write(slice2);
    try testing.expectEqualString(slice1, slice2);
    array.undefineAll(allocator.*);
}
fn testRenderArray(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    comptime var render: fmt.RenderSpec = .{};
    try TestFormatAlloc(render, [8]u8).run(allocator, array, ".{ 1, 2, 3, 4, 5, 6, 7, 8 }", .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    render.infer_type_names = false;
    try TestFormatAlloc(render, [8]u8).run(allocator, array, "[8]u8{ 1, 2, 3, 4, 5, 6, 7, 8 }", .{ 1, 2, 3, 4, 5, 6, 7, 8 });
    try TestFormatAlloc(render, [8][8]u8).run(
        allocator,
        array,
        "[8][8]u8{ [8]u8{ 0, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 1, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 2, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 3, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 4, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 5, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 6, 0, 0, 0, 0, 0, 0, 0 }, [8]u8{ 7, 0, 0, 0, 0, 0, 0, 0 } }",
        .{
            .{ 0, 0, 0, 0, 0, 0, 0, 0 },
            .{ 1, 0, 0, 0, 0, 0, 0, 0 },
            .{ 2, 0, 0, 0, 0, 0, 0, 0 },
            .{ 3, 0, 0, 0, 0, 0, 0, 0 },
            .{ 4, 0, 0, 0, 0, 0, 0, 0 },
            .{ 5, 0, 0, 0, 0, 0, 0, 0 },
            .{ 6, 0, 0, 0, 0, 0, 0, 0 },
            .{ 7, 0, 0, 0, 0, 0, 0, 0 },
        },
    );
}
fn testRenderType(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    comptime var render: fmt.RenderSpec = .{};
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "packed struct(u120) { x: u64 = 5, y: packed struct(u48) { @\"0\": u32, @\"1\": u16, }, z: u8, }",
        packed struct(u120) { x: u64 = 5, y: packed struct { @"0": u32, @"1": u16 }, z: u8 },
    );
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "extern union { x: u64, }",
        extern union { x: u64 },
    );
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "enum(u3) { x, y, z, }",
        enum(u3) { x, y, z },
    );
    render.omit_trailing_comma = true;
    render.omit_container_decls = false;
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "struct { x: u64 = 5, y: struct { @\"0\": u32, @\"1\": u16 }, z: u8 }",
        struct { x: u64 = 5, y: struct { @"0": u32, @"1": u16 }, z: u8 },
    );
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "extern union { x: u64 }",
        extern union { x: u64 },
    );
    try TestFormatAlloc(render, type).run(
        allocator,
        array,
        "enum(u3) { x, y, z }",
        enum(u3) { x, y, z },
    );
}
fn testRenderSlice(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    try TestFormatAlloc(.{}, []const u8).run(
        allocator,
        array,
        "\"c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c\"",
        "c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c",
    );
    try TestFormatAlloc(.{}, []const u8).run(
        allocator,
        array,
        "\"one\\ntwo\\nthree\\n\"",
        "one\ntwo\nthree\n",
    );
    try TestFormatAlloc(.{}, []const u16).run(
        allocator,
        array,
        "&.{ 111, 110, 101, 10, 116, 119, 111, 10, 116, 104, 114, 101, 101, 10 }",
        &.{ 'o', 'n', 'e', '\n', 't', 'w', 'o', '\n', 't', 'h', 'r', 'e', 'e', '\n' },
    );
}
fn testRenderStruct(allocator: *Allocator, array: *Array, buf: [*]u8) !void {
    _ = buf;
    testing.announce(@src());
    const tmp_max_len: usize = "c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c".len;
    const tmp: [*]u8 = @constCast("c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c");
    try TestFormatAlloc().run(allocator, array, fmt.render(.{}, packed struct(u120) {
        x: u64 = 5,
        y: packed struct(u48) { a: u32 = 1, b: u16 = 2 } = .{},
        z: u8 = 255,
    }{
        .x = 25,
        .y = .{ .a = 3, .b = 4 },
        .z = 127,
    }));
    try TestFormatAlloc().run(allocator, array, fmt.render(.{
        .views = .{ .extern_tagged_union = true },
    }, struct {
        value_tag: enum { a, b },
        value: extern union { a: usize, b: usize },
    }{
        .value_tag = .a,
        .value = .{ .a = 2342342 },
    }));
    try TestFormatAlloc().run(allocator, array, fmt.render(.{
        .views = .{ .extern_resizeable = true },
    }, struct { buf: [*]u8, buf_len: usize }{
        .buf = tmp,
        .buf_len = 16,
    }));
    try TestFormatAlloc().run(allocator, array, fmt.render(.{
        .views = .{ .zig_resizeable = true },
    }, struct { buf: []u8, buf_len: usize }{
        .buf = tmp[16..tmp_max_len],
        .buf_len = tmp_max_len - 16,
    }));
    try TestFormatAlloc().run(allocator, array, fmt.render(.{
        .views = .{ .static_resizeable = true },
    }, struct {
        auto: [256]u8 = [1]u8{0xa} ** 256,
        auto_len: usize = 16,
    }{}));
    if (return) {}
    try TestFormatAlloc().run(allocator, array, fmt.render(.{
        .views = .{
            .extern_resizeable = true,
            .extern_slice = true,
            .extern_tagged_union = true,
            .static_resizeable = true,
        },
    }, struct {
        auto: [2]type = .{ u8, u16 },
        auto_len: usize = 1,
    }{}));
}
fn testRenderUnion(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    try TestFormatAlloc().run(allocator, array, comptime fmt.any(extern union { x: u64 }{ .x = 0 }));
}
fn testRenderEnum(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    try TestFormatAlloc().run(allocator, array, comptime fmt.any(enum(u3) { x, y, z }.z));
}
fn testRenderTypeDescription(allocator: *Allocator, array: *Array) !void {
    testing.announce(@src());
    try TestFormatAlloc().run(allocator, array, //
        comptime TypeDescr.init(packed struct(u120) { x: u64 = 5, y: packed struct(u48) { @"0": u32 = 1, @"1": u16 = 2 } = .{}, z: u8 = 255 }));
    try TestFormatAlloc().run(allocator, array, comptime TypeDescr.init(struct { buf: [*]u8, buf_len: usize }));
    try TestFormatAlloc().run(allocator, array, comptime TypeDescr.init(struct { buf: []u8, buf_len: usize }));
    try TestFormatAlloc().run(allocator, array, comptime TypeDescr.init(struct { auto: [256]u8 = [1]u8{0xa} ** 256, auto_len: usize = 16 }));
    try TestFormatAlloc().run(allocator, array, comptime BigTypeDescr.init(@import("std").builtin));
    try TestFormatAlloc().run(allocator, array, comptime BigTypeDescr.declare("Os", @import("std").Target.Os));
    const td1: TypeDescr = comptime TypeDescr.init(?union(enum) { yes: ?zl.file.CompoundPath, no });
    const td2: TypeDescr = comptime TypeDescr.init(?union(enum) { yes: ?zl.file.CompoundPath, no });
    try testFormats(allocator, array, td1, td2);
    try debug.expectEqualMemory(TypeDescr, td1, td2);
}
pub fn testRenderFunctions() !void {
    try mem.map(.{}, .{}, .{}, 0x40000000, 0x40000000);
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = Array.init(&allocator);
    try testRenderArray(&allocator, &array);
    try testRenderType(&allocator, &array);
    try testRenderSlice(&allocator, &array);
    //try testRenderStruct(&allocator, &array);
}
fn testGenericRangeFormat() !void {
    testing.announce(@src());
    var array: PrintArray = undefined;
    array.undefineAll();
    const Range = fmt.GenericRangeFormat(.{ .bits = 64, .signedness = .unsigned, .radix = 16, .width = .min });
    const range_fmt: Range = .{ .lower = 0x7f2, .upper = 0x7f3 };
    array.writeFormat(range_fmt);
    try testing.expectEqualString("7f{2..3}", array.readAll());
}
fn testIntToStringWithSeparators() !void {
    var buf: [4096]u8 = undefined;
    var len: usize = fmt.udh(10_000_000).formatWriteBuf(&buf);
    try testing.expectEqualString("10,000,000", buf[0..len]);
}
fn testSystemFlagsFormatters() !void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    len = (sys.flags.MemMap{}).formatWriteBuf(&buf);
    try testing.expectEqualString("flags=private,anonymous,fixed_noreplace", buf[0..len]);
    len = (sys.flags.FileMap{}).formatWriteBuf(&buf);
    try testing.expectEqualString("flags=private,fixed", buf[0..len]);
    len = (sys.flags.MemProt{ .exec = true }).formatWriteBuf(&buf);
    try testing.expectEqualString("flags=read,write,exec", buf[0..len]);
    len = (sys.flags.MemFd{ .allow_sealing = true, .close_on_exec = true }).formatWriteBuf(&buf);
    try testing.expectEqualString("flags=close_on_exec,allow_sealing", buf[0..len]);
    len = (sys.flags.Clone{ .clear_child_thread_id = true, .detached = false, .fs = true, .files = true }).formatWriteBuf(&buf);
    try testing.expectEqualString("flags=vm,fs,files,signal_handlers,thread,sysvsem,set_parent_thread_id,clear_child_thread_id,set_child_thread_id", buf[0..len]);
}
fn testStringLitChar() void {
    var lens: [5][256]u8 = .{.{255}} ** 5;
    var lens_lens: [5]usize = .{0} ** 5;
    for (0..256) |byte| {
        const seqn = fmt.stringLiteralChar(@intCast(byte));
        const idx: usize = lens_lens[seqn.len];
        lens_lens[seqn.len] +%= 1;
        lens[seqn.len][idx] = @intCast(byte);
    }
    debug.write("switch(byte){\n");
    var prev: u8 = 0;
    var last: u8 = 0;
    for (lens, 0..) |len, idx| {
        for (len[0..lens_lens[idx]]) |byte| {
            if (byte == prev + 1) {
                //
            } else if (last != prev) {
                debug.write("...");
                debug.write(fmt.ud64(prev).formatConvert().readAll());
                debug.write(", ");
                debug.write(fmt.ud64(byte).formatConvert().readAll());
                last = byte;
            } else {
                debug.write(", ");
                debug.write(fmt.ud64(byte).formatConvert().readAll());
                last = byte;
            }
            prev = byte;
        }
        if (last != prev) {
            debug.write("...");
            debug.write(fmt.ud64(prev).formatConvert().readAll());
        }
        if (lens_lens[idx] != 0) {
            debug.write(" => ");
            debug.write(fmt.ud64(idx).formatConvert().readAll());
            debug.write(",\n");
            last = prev;
        }
    }
    debug.write("}\n");
}
fn testCaseFormat() !void {
    var buf: [4096]u8 = undefined;
    var end: [*]u8 = fmt.UpperCaseFormat.write(&buf, "idhiIHFGshdFshaFISahIFfhIAUFsUAIHF");
    try testing.expectEqualString("IDHIIHFGSHDFSHAFISAHIFFHIAUFSUAIHF", fmt.slice(end, &buf));
    end = fmt.LowerCaseFormat.write(&buf, "idhiIHFGshdFshaFISahIFfhIAUFsUAIHF");
    try testing.expectEqualString("idhiihfgshdfshafisahiffhiaufsuaihf", fmt.slice(end, &buf));
}
fn testRenderHighlight() !void {
    const src: [:0]const u8 = @embedFile(@src().file["test/".len..]);
    var buf: [src.len * 16]u8 = undefined;
    var end: [*]u8 = fmt.SourceCodeFormat.write(&buf, @constCast(src));
    debug.write(fmt.slice(end, &buf));
}
pub fn testLEB() !void {
    @setRuntimeSafety(false);
    var rng: file.DeviceRandomBytes(4096) = .{};
    inline for (.{ u8, u16, u32, u64, i8, i16, i32, i64 }) |T| {
        const LEB128 = fmt.GenericLEB128Format(T);
        var val: T = rng.readOne(T);
        var buf: [4096]u8 = undefined;
        comptime var max: usize = 10000;
        var idx: usize = 0;
        while (idx != max) : (idx +%= 1) {
            const l: T = @intCast(@as(usize, @intCast(val)) -% idx);
            const u: T = @intCast(@as(usize, @intCast(val)) +% idx);
            const u_len: usize = fmt.strlen(LEB128.write(&buf, u), &buf);
            const u_res = try parse.readLEB128(T, buf[0..u_len]);
            try debug.expectEqual(T, u, u_res[0]);
            const l_len: usize = fmt.strlen(LEB128.write(&buf, l), &buf);
            const l_res = try parse.readLEB128(T, buf[0..l_len]);
            try debug.expectEqual(T, l, l_res[0]);
        }
    }
}
pub fn test1() !void {
    const X = struct {
        x: [25]u8 = .{'a'} ** 25,
        x_len: usize = 0,
    };
    var x: X = .{};
    var buf: [4096]u8 = undefined;
    const end: [*]u8 = fmt.AnyFormat(.{}, X).write(&buf, x);
    debug.write(fmt.slice(end, &buf));
}
pub fn main() !void {
    meta.refAllDecls(fmt, &.{});
    try testLEB();
    //try testRenderHighlight();
    //try testBytesFormat();
    //try testBytesToHex();
    //try testHexToBytes();
    //try testCaseFormat();
    //try testGenericRangeFormat();
    try testRenderFunctions();
    //try testSystemFlagsFormatters();
    //try testIntToStringWithSeparators();
    //try testEquivalentIntToStringFormat();
    try @import("fmt/utf8.zig").testUtf8();
    try @import("fmt/ascii.zig").testAscii();
}
