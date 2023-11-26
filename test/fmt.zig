const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub const logging_override: zl.debug.Logging.Override = zl.debug.spec.logging.override.verbose;
const AddressSpace = zl.mem.GenericRegularAddressSpace(.{
    .lb_addr = 0x40000000,
    .divisions = 128,
});
const Allocator = zl.mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .logging = zl.mem.dynamic.spec.logging.silent,
});
const PrintArray = zl.mem.array.StaticString(4096);
const Array = Allocator.StructuredHolder(u8);
const TypeDescr = zl.fmt.GenericTypeDescrFormat(.{});
const BigTypeDescr = zl.fmt.GenericTypeDescrFormat(.{ .decls = true, .default_field_values = .{ .exact_safe = .{} } });
const test_size: bool = false;
var rng: zl.file.DeviceRandomBytes(4096) = .{};
fn testIntToString() !void {
    const T: type = u64;
    var arg1: T = 0;
    var iint: i64 = -0xfee1dead;
    var uint: u64 = 0xdeadbeef;
    try zl.testing.expectEqualMany(u8, zl.builtin.fmt.ix64(iint).readAll(), "-0xfee1dead");
    iint = 0x0;
    try zl.testing.expectEqualMany(u8, zl.builtin.fmt.ix64(iint).readAll(), "0x0");
    try zl.testing.expectEqualMany(u8, zl.builtin.fmt.ux64(uint).readAll(), "0xdeadbeef");
    const bs: [2]bool = .{ true, false };
    for (bs) |b_0| {
        zl.builtin.assertEqual(u64, @intFromBool(b_0), zl.builtin.int(u64, b_0));
        for (bs) |b_1| {
            zl.builtin.assertEqual(u64, @intFromBool(b_0 or b_1), zl.builtin.int2v(u64, b_0, b_1));
            zl.builtin.assertEqual(u64, @intFromBool(b_0 and b_1), zl.builtin.int2a(u64, b_0, b_1));
            for (bs) |b_2| {
                zl.builtin.assertEqual(u64, @intFromBool(b_0 or b_1 or b_2), zl.builtin.int3v(u64, b_0, b_1, b_2));
                zl.builtin.assertEqual(u64, @intFromBool(b_0 and b_1 and b_2), zl.builtin.int3a(u64, b_0, b_1, b_2));
            }
        }
    }
    try zl.testing.expectEqualMany(u8, zl.builtin.fmt.ub8(0).readAll(), "0b00000000");
    try zl.testing.expectEqualMany(u8, zl.builtin.fmt.ub8(1).readAll(), "0b00000001");
    const start = @intFromPtr(&arg1);
    var inc: u64 = 1;
    uint = start;
    while (uint - start < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
        zl.builtin.assertEqual(u64, uint, zl.builtin.parse.ub(u64, zl.builtin.fmt.ub64(uint).readAll()));
        zl.builtin.assertEqual(u64, uint, zl.builtin.parse.uo(u64, zl.builtin.fmt.uo64(uint).readAll()));
        zl.builtin.assertEqual(u64, uint, zl.builtin.parse.ud(u64, zl.builtin.fmt.ud64(uint).readAll()));
        zl.builtin.assertEqual(u64, uint, zl.builtin.parse.ux(u64, zl.builtin.fmt.ux64(uint).readAll()));
        zl.builtin.assertEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ub(u32, zl.builtin.fmt.ub32(@as(u32, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.uo(u32, zl.builtin.fmt.uo32(@as(u32, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ud(u32, zl.builtin.fmt.ud32(@as(u32, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ux(u32, zl.builtin.fmt.ux32(@as(u32, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ub(u16, zl.builtin.fmt.ub16(@as(u16, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.uo(u16, zl.builtin.fmt.uo16(@as(u16, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ud(u16, zl.builtin.fmt.ud16(@as(u16, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ux(u16, zl.builtin.fmt.ux16(@as(u16, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ub(u8, zl.builtin.fmt.ub8(@as(u8, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.uo(u8, zl.builtin.fmt.uo8(@as(u8, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ud(u8, zl.builtin.fmt.ud8(@as(u8, @truncate(uint))).readAll()));
        zl.builtin.assertEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ux(u8, zl.builtin.fmt.ux8(@as(u8, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u64, uint, zl.builtin.parse.ub(u64, zl.builtin.fmt.ub64(uint).readAll()));
        try zl.builtin.expectEqual(u64, uint, zl.builtin.parse.uo(u64, zl.builtin.fmt.uo64(uint).readAll()));
        try zl.builtin.expectEqual(u64, uint, zl.builtin.parse.ud(u64, zl.builtin.fmt.ud64(uint).readAll()));
        try zl.builtin.expectEqual(u64, uint, zl.builtin.parse.ux(u64, zl.builtin.fmt.ux64(uint).readAll()));
        try zl.builtin.expectEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ub(u32, zl.builtin.fmt.ub32(@as(u32, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.uo(u32, zl.builtin.fmt.uo32(@as(u32, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ud(u32, zl.builtin.fmt.ud32(@as(u32, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u32, @as(u32, @truncate(uint)), zl.builtin.parse.ux(u32, zl.builtin.fmt.ux32(@as(u32, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ub(u16, zl.builtin.fmt.ub16(@as(u16, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.uo(u16, zl.builtin.fmt.uo16(@as(u16, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ud(u16, zl.builtin.fmt.ud16(@as(u16, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u16, @as(u16, @truncate(uint)), zl.builtin.parse.ux(u16, zl.builtin.fmt.ux16(@as(u16, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ub(u8, zl.builtin.fmt.ub8(@as(u8, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.uo(u8, zl.builtin.fmt.uo8(@as(u8, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ud(u8, zl.builtin.fmt.ud8(@as(u8, @truncate(uint))).readAll()));
        try zl.builtin.expectEqual(u8, @as(u8, @truncate(uint)), zl.builtin.parse.ux(u8, zl.builtin.fmt.ux8(@as(u8, @truncate(uint))).readAll()));
    }
    iint = @as(isize, @bitCast(start));
    inc = 1;
    while (iint < 0x100000) : ({
        uint +%= inc;
        inc +%= 1;
    }) {
        zl.builtin.assertEqual(i64, iint, zl.builtin.parse.ib(i64, zl.builtin.fmt.ib64(iint).readAll()));
        zl.builtin.assertEqual(i64, iint, zl.builtin.parse.io(i64, zl.builtin.fmt.io64(iint).readAll()));
        zl.builtin.assertEqual(i64, iint, zl.builtin.parse.id(i64, zl.builtin.fmt.id64(iint).readAll()));
        zl.builtin.assertEqual(i64, iint, zl.builtin.parse.ix(i64, zl.builtin.fmt.ix64(iint).readAll()));
        zl.builtin.assertEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.ib(i32, zl.builtin.fmt.ib32(@as(i32, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.io(i32, zl.builtin.fmt.io32(@as(i32, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.id(i32, zl.builtin.fmt.id32(@as(i32, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.ix(i32, zl.builtin.fmt.ix32(@as(i32, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.ib(i16, zl.builtin.fmt.ib16(@as(i16, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.io(i16, zl.builtin.fmt.io16(@as(i16, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.id(i16, zl.builtin.fmt.id16(@as(i16, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.ix(i16, zl.builtin.fmt.ix16(@as(i16, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.ib(i8, zl.builtin.fmt.ib8(@as(i8, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.io(i8, zl.builtin.fmt.io8(@as(i8, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.id(i8, zl.builtin.fmt.id8(@as(i8, @truncate(iint))).readAll()));
        zl.builtin.assertEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.ix(i8, zl.builtin.fmt.ix8(@as(i8, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i64, iint, zl.builtin.parse.ib(i64, zl.builtin.fmt.ib64(iint).readAll()));
        try zl.builtin.expectEqual(i64, iint, zl.builtin.parse.io(i64, zl.builtin.fmt.io64(iint).readAll()));
        try zl.builtin.expectEqual(i64, iint, zl.builtin.parse.id(i64, zl.builtin.fmt.id64(iint).readAll()));
        try zl.builtin.expectEqual(i64, iint, zl.builtin.parse.ix(i64, zl.builtin.fmt.ix64(iint).readAll()));
        try zl.builtin.expectEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.ib(i32, zl.builtin.fmt.ib32(@as(i32, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.io(i32, zl.builtin.fmt.io32(@as(i32, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.id(i32, zl.builtin.fmt.id32(@as(i32, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i32, @as(i32, @truncate(iint)), zl.builtin.parse.ix(i32, zl.builtin.fmt.ix32(@as(i32, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.ib(i16, zl.builtin.fmt.ib16(@as(i16, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.io(i16, zl.builtin.fmt.io16(@as(i16, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.id(i16, zl.builtin.fmt.id16(@as(i16, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i16, @as(i16, @truncate(iint)), zl.builtin.parse.ix(i16, zl.builtin.fmt.ix16(@as(i16, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.ib(i8, zl.builtin.fmt.ib8(@as(i8, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.io(i8, zl.builtin.fmt.io8(@as(i8, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.id(i8, zl.builtin.fmt.id8(@as(i8, @truncate(iint))).readAll()));
        try zl.builtin.expectEqual(i8, @as(i8, @truncate(iint)), zl.builtin.parse.ix(i8, zl.builtin.fmt.ix8(@as(i8, @truncate(iint))).readAll()));
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
        const ptr: [*]u8 = zl.fmt.Bytes.write(&buf, pair[1]);
        try zl.testing.expectEqualMany(u8, pair[0], zl.fmt.slice(ptr, &buf));
    }
}
// There is currently only one implementation of intToString, the `fmt` one.
fn testEquivalentIntToStringFormat() !void {
    const ubin = zl.fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
    const sbin = zl.fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
    var uint: u64 = 0;
    const seed: u64 = @intFromPtr(&uint);
    uint = seed;
    try zl.testing.expectEqualMany(u8, "0b0", (sbin{ .value = 0 }).formatConvert().readAll());
    try zl.testing.expectEqualMany(u8, "-0b1", (sbin{ .value = -1 }).formatConvert().readAll());
    try zl.testing.expectEqualMany(u8, "0b0", (ubin{ .value = 0 }).formatConvert().readAll());
    try zl.testing.expectEqualMany(u8, "0b1", (ubin{ .value = 1 }).formatConvert().readAll());
    try zl.testing.expectEqualMany(u8, zl.fmt.ub64(uint).readAll(), zl.fmt.ub64(uint).formatConvert().readAll());
    var buf: [4096]u8 = undefined;
    while (uint < seed +% 0x1000) : (uint +%= 1) {
        const uint_32: u32 = @as(u32, @truncate(uint));
        const uint_16: u16 = @as(u16, @truncate(uint));
        const uint_8: u8 = @as(u8, @truncate(uint));
        const sint_64: i64 = @bitReverse(@as(i64, @bitCast(uint)));
        const sint_32: i32 = @bitReverse(@as(i32, @bitCast(@as(u32, @truncate(uint)))));
        const sint_16: i16 = @bitReverse(@as(i16, @bitCast(@as(u16, @truncate(uint)))));
        const sint_8: i8 = @bitReverse(@as(i8, @bitCast(@as(u8, @truncate(uint)))));
        try zl.testing.expectEqualMany(u8, zl.fmt.ub64(uint).readAll(), buf[0..zl.fmt.ub64(uint).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ub32(uint_32).readAll(), buf[0..zl.fmt.ub32(uint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ub16(uint_16).readAll(), buf[0..zl.fmt.ub16(uint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ub8(uint_8).readAll(), buf[0..zl.fmt.ub8(uint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.uo64(uint).readAll(), buf[0..zl.fmt.uo64(uint).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.uo32(uint_32).readAll(), buf[0..zl.fmt.uo32(uint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.uo16(uint_16).readAll(), buf[0..zl.fmt.uo16(uint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.uo8(uint_8).readAll(), buf[0..zl.fmt.uo8(uint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ud64(uint).readAll(), buf[0..zl.fmt.ud64(uint).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ud32(uint_32).readAll(), buf[0..zl.fmt.ud32(uint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ud16(uint_16).readAll(), buf[0..zl.fmt.ud16(uint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ud8(uint_8).readAll(), buf[0..zl.fmt.ud8(uint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ux64(uint).readAll(), buf[0..zl.fmt.ux64(uint).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ux32(uint_32).readAll(), buf[0..zl.fmt.ux32(uint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ux16(uint_16).readAll(), buf[0..zl.fmt.ux16(uint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ux8(uint_8).readAll(), buf[0..zl.fmt.ux8(uint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ib64(sint_64).readAll(), buf[0..zl.fmt.ib64(sint_64).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ib32(sint_32).readAll(), buf[0..zl.fmt.ib32(sint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ib16(sint_16).readAll(), buf[0..zl.fmt.ib16(sint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ib8(sint_8).readAll(), buf[0..zl.fmt.ib8(sint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.io64(sint_64).readAll(), buf[0..zl.fmt.io64(sint_64).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.io32(sint_32).readAll(), buf[0..zl.fmt.io32(sint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.io16(sint_16).readAll(), buf[0..zl.fmt.io16(sint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.io8(sint_8).readAll(), buf[0..zl.fmt.io8(sint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.id64(sint_64).readAll(), buf[0..zl.fmt.id64(sint_64).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.id32(sint_32).readAll(), buf[0..zl.fmt.id32(sint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.id16(sint_16).readAll(), buf[0..zl.fmt.id16(sint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.id8(sint_8).readAll(), buf[0..zl.fmt.id8(sint_8).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ix64(sint_64).readAll(), buf[0..zl.fmt.ix64(sint_64).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ix32(sint_32).readAll(), buf[0..zl.fmt.ix32(sint_32).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ix16(sint_16).readAll(), buf[0..zl.fmt.ix16(sint_16).formatWriteBuf(&buf)]);
        try zl.testing.expectEqualMany(u8, zl.fmt.ix8(sint_8).readAll(), buf[0..zl.fmt.ix8(sint_8).formatWriteBuf(&buf)]);
    }
}
fn testBytesToHex() !void {
    zl.testing.announce(@src());
    const input: []const u8 = "0123456789abcdef";
    var buf0: [2 *% input.len]u8 = undefined;
    var buf1: [2 *% input.len]u8 = undefined;
    @memset(&buf0, 0);
    @memset(&buf1, 0);
    const encoded: []const u8 = zl.fmt.bytesToHex(&buf0, input);
    const decoded: []const u8 = zl.fmt.hexToBytes2(&buf0, encoded);
    try zl.testing.expectEqualMany(u8, input, decoded);
}
fn testHexToBytes() !void {
    zl.testing.announce(@src());
    var buf: [32]u8 = .{0} ** 32;
    var bytes: [64]u8 = .{0} ** 64;
    try zl.testing.expectEqualMany(u8, "90" ** 32, zl.fmt.bytesToHex(&bytes, try zl.fmt.hexToBytes(&buf, "90" ** 32)));
    try zl.testing.expectEqualMany(u8, "abcd", zl.fmt.bytesToHex(&bytes, try zl.fmt.hexToBytes(&buf, "abcd")));
    try zl.testing.expectEqualMany(u8, "", zl.fmt.bytesToHex(&bytes, try zl.fmt.hexToBytes(&buf, "")));
    _ = zl.fmt.hexToBytes(&buf, "012z") catch |err| {
        if (err != error.InvalidEncoding) {
            return err;
        }
    };
    _ = zl.fmt.hexToBytes(&buf, "aaa") catch |err| {
        if (err != error.InvalidLength) {
            return err;
        }
    };
    _ = zl.fmt.hexToBytes(buf[0..1], "abcd") catch |err| {
        if (err != error.NoSpaceLeft) {
            return err;
        }
    };
}
fn TestFormatAlloc(comptime spec: zl.fmt.RenderSpec, comptime Value: type) type {
    return struct {
        fn run(allocator: *Allocator, array: *Array, expected: []const u8, comptime value: Value) !void {
            zl.debug.write("run(" ++ comptime zl.fmt.eval(.{ .omit_trailing_comma = true }, spec) ++ ", " ++ @typeName(Value) ++ ")\n");
            try array.appendFormat(allocator, comptime zl.fmt.render(spec, value));
            try zl.testing.expectEqualString(expected, array.readAll(allocator.*));
            try array.appendMany(allocator, "\n\n");
            zl.debug.write(array.readAll(allocator.*));
            array.undefineAll(allocator.*);
        }
    };
}
fn testTypeDescr(allocator: *Allocator, array: *Array, format: anytype) !void {
    try array.appendFormat(allocator, format);
    zl.debug.write(array.readAll(allocator.*));
    array.undefineAll(allocator.*);
}
fn testFormats(allocator: *Allocator, array: *Array, format1: anytype, format2: anytype) !void {
    zl.testing.announce(@src());
    try array.appendFormat(allocator, format1);
    try array.appendOne(allocator, 0xa);
    const slice1: []const u8 = array.readAll(allocator.*);
    allocator.ub_addr +%= slice1.len;
    try array.appendFormat(allocator, format2);
    try array.appendOne(allocator, 0xa);
    const slice2: []const u8 = array.readAll(allocator.*);
    allocator.ub_addr -%= slice1.len;
    zl.debug.write(slice1);
    zl.debug.write(slice2);
    try zl.testing.expectEqualString(slice1, slice2);
    array.undefineAll(allocator.*);
}
fn testRenderArray(allocator: *Allocator, array: *Array) !void {
    zl.testing.announce(@src());
    comptime var render: zl.fmt.RenderSpec = .{};
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
    zl.testing.announce(@src());
    comptime var render: zl.fmt.RenderSpec = .{};
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
    zl.testing.announce(@src());
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
fn testRenderStruct(allocator: *Allocator, array: *Array) !void {
    zl.testing.announce(@src());
    const tmp = "c7176a703d4dd84fba3c0b760d10670f2a2053fa2c39ccc64ec7fd7792ac03fa8c";
    const tmp_max_len: usize = tmp.len;

    comptime var render: zl.fmt.RenderSpec = .{};

    try TestFormatAlloc(render, packed struct(u120) {
        x: u64 = 5,
        y: packed struct(u48) { a: u32 = 1, b: u16 = 2 } = .{},
        z: u8 = 255,
    }).run(
        allocator,
        array,
        ".{ .x = 25, .y = .{ .a = 3, .b = 4 }, .z = 127 }",
        .{
            .x = 25,
            .y = .{ .a = 3, .b = 4 },
            .z = 127,
        },
    );
    render.views.extern_tagged_union = true;
    try TestFormatAlloc(render, struct {
        value_tag: enum { a, b },
        value: extern union { a: usize, b: usize },
    }).run(
        allocator,
        array,
        ".{ .a = 2342342 }",
        .{
            .value_tag = .a,
            .value = .{ .a = 2342342 },
        },
    );
    render.views.extern_slice = true;
    try TestFormatAlloc(render, struct { buf: [*]u8, buf_len: usize }).run(
        allocator,
        array,
        ".{ .buf = \"c7176a703d4dd84f\", .buf_len = 16 }",
        .{ .buf = @constCast(tmp), .buf_len = 16 },
    );

    if (false) {
        try TestFormatAlloc().run(allocator, array, zl.fmt.render(.{
            .views = .{ .zig_resizeable = true },
        }, struct { buf: []u8, buf_len: usize }{
            .buf = tmp[16..tmp_max_len],
            .buf_len = tmp_max_len - 16,
        }));
        try TestFormatAlloc().run(allocator, array, zl.fmt.render(.{
            .views = .{ .static_resizeable = true },
        }, struct {
            auto: [256]u8 = [1]u8{0xa} ** 256,
            auto_len: usize = 16,
        }{}));
        try TestFormatAlloc().run(allocator, array, zl.fmt.render(.{
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
}
fn testRenderUnion(allocator: *Allocator, array: *Array) !void {
    zl.testing.announce(@src());
    try TestFormatAlloc().run(allocator, array, comptime zl.fmt.any(extern union { x: u64 }{ .x = 0 }));
}
fn testRenderEnum(allocator: *Allocator, array: *Array) !void {
    zl.testing.announce(@src());
    try TestFormatAlloc().run(allocator, array, comptime zl.fmt.any(enum(u3) { x, y, z }.z));
}
fn testRenderTypeDescription(allocator: *Allocator, array: *Array) !void {
    zl.testing.announce(@src());
    try testTypeDescr(allocator, array, comptime TypeDescr.init( //
        packed struct(u120) { x: u64 = 5, y: packed struct(u48) { @"0": u32 = 1, @"1": u16 = 2 } = .{}, z: u8 = 255 }));
    try testTypeDescr(allocator, array, comptime TypeDescr.init(struct { buf: [*]u8, buf_len: usize }));
    try testTypeDescr(allocator, array, comptime TypeDescr.init(struct { buf: []u8, buf_len: usize }));
    try testTypeDescr(allocator, array, comptime TypeDescr.init(struct { auto: [256]u8 = [1]u8{0xa} ** 256, auto_len: usize = 16 }));
    try testTypeDescr(allocator, array, comptime TypeDescr.init(?union(enum) { yes: ?zl.file.CompoundPath, no }));
    try testTypeDescr(allocator, array, comptime TypeDescr.init(?union(enum) { yes: ?zl.file.CompoundPath, no }));
    try testTypeDescr(allocator, array, comptime BigTypeDescr.init(zl.builtin.Type));
}
pub fn testRenderFunctions() !void {
    try zl.mem.map(.{}, .{}, .{}, 0x40000000, 0x40000000);
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: Array = Array.init(&allocator);
    try testRenderArray(&allocator, &array);
    try testRenderType(&allocator, &array);
    try testRenderSlice(&allocator, &array);
    try testRenderStruct(&allocator, &array);
    try testRenderTypeDescription(&allocator, &array);
}
fn testGenericRangeFormat() !void {
    zl.testing.announce(@src());
    var array: PrintArray = undefined;
    array.undefineAll();
    const Range = zl.fmt.GenericRangeFormat(.{ .bits = 64, .signedness = .unsigned, .radix = 16, .width = .min });
    var range_fmt: Range = .{ .lower = 0x7f2, .upper = 0x7f3 };
    var new_range_fmt: Range = .{ .lower = 0x7f2, .upper = 0x7f3 };
    array.writeFormat(range_fmt);
    try zl.testing.expectEqualString("7f{2..3}", array.readAll());
    array.undefineAll();

    range_fmt.lower = @as(u32, @truncate(rng.readOne(u64)));
    range_fmt.upper = range_fmt.lower +% (range_fmt.lower >> @intCast(@popCount(range_fmt.lower)));

    array.writeFormat(&range_fmt);
    zl.debug.write(array.readAll());
    array.undefineAll();

    range_fmt.lower = @as(u32, @truncate(rng.readOne(u64)));
    range_fmt.upper = range_fmt.lower +% (range_fmt.lower >> @intCast(@popCount(range_fmt.lower)));

    new_range_fmt.lower = @as(u32, @truncate(rng.readOne(u64)));
    new_range_fmt.upper = range_fmt.lower +% (range_fmt.lower >> @intCast(@popCount(range_fmt.lower)));
}
fn testIntToStringWithSeparators() !void {
    var buf: [4096]u8 = undefined;
    const len: usize = zl.fmt.udh(10_000_000).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("10,000,000", buf[0..len]);
}
fn testSystemFlagsFormatters() !void {
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    len = (zl.sys.flags.MemMap{}).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("flags=private,anonymous,fixed_noreplace", buf[0..len]);
    len = (zl.sys.flags.FileMap{}).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("flags=private,fixed", buf[0..len]);
    len = (zl.sys.flags.MemProt{ .exec = true }).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("flags=read,write,exec", buf[0..len]);
    len = (zl.sys.flags.MemFd{ .allow_sealing = true, .close_on_exec = true }).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("flags=close_on_exec,allow_sealing", buf[0..len]);
    len = (zl.sys.flags.Clone{ .clear_child_thread_id = true, .detached = false, .fs = true, .files = true }).formatWriteBuf(&buf);
    try zl.testing.expectEqualString("flags=vm,fs,files,signal_handlers,thread,sysvsem,set_parent_thread_id,clear_child_thread_id,set_child_thread_id", buf[0..len]);
}
fn testStringLitChar() void {
    var lens: [5][256]u8 = .{.{255}} ** 5;
    var lens_lens: [5]usize = .{0} ** 5;
    for (0..256) |byte| {
        const seqn = zl.fmt.stringLiteralChar(@intCast(byte));
        const idx: usize = lens_lens[seqn.len];
        lens_lens[seqn.len] +%= 1;
        lens[seqn.len][idx] = @intCast(byte);
    }
    zl.debug.write("switch(byte){\n");
    var prev: u8 = 0;
    var last: u8 = 0;
    for (lens, 0..) |len, idx| {
        for (len[0..lens_lens[idx]]) |byte| {
            if (byte == prev + 1) {
                //
            } else if (last != prev) {
                zl.debug.write("...");
                zl.debug.write(zl.fmt.ud64(prev).formatConvert().readAll());
                zl.debug.write(", ");
                zl.debug.write(zl.fmt.ud64(byte).formatConvert().readAll());
                last = byte;
            } else {
                zl.debug.write(", ");
                zl.debug.write(zl.fmt.ud64(byte).formatConvert().readAll());
                last = byte;
            }
            prev = byte;
        }
        if (last != prev) {
            zl.debug.write("...");
            zl.debug.write(zl.fmt.ud64(prev).formatConvert().readAll());
        }
        if (lens_lens[idx] != 0) {
            zl.debug.write(" => ");
            zl.debug.write(zl.fmt.ud64(idx).formatConvert().readAll());
            zl.debug.write(",\n");
            last = prev;
        }
    }
    zl.debug.write("}\n");
}
fn testCaseFormat() !void {
    var buf: [4096]u8 = undefined;
    var end: [*]u8 = zl.fmt.UpperCaseFormat.write(&buf, "idhiIHFGshdFshaFISahIFfhIAUFsUAIHF");
    try zl.testing.expectEqualString("IDHIIHFGSHDFSHAFISAHIFFHIAUFSUAIHF", zl.fmt.slice(end, &buf));
    end = zl.fmt.LowerCaseFormat.write(&buf, "idhiIHFGshdFshaFISahIFfhIAUFsUAIHF");
    try zl.testing.expectEqualString("idhiihfgshdfshafisahiffhiaufsuaihf", zl.fmt.slice(end, &buf));
}
fn testRenderHighlight() !void {
    const src: [:0]const u8 = @embedFile(@src().file["test/".len..]);
    var buf: [src.len * 16]u8 = undefined;
    const end: [*]u8 = zl.fmt.SourceCodeFormat.write(&buf, @constCast(src));
    zl.debug.write(zl.fmt.slice(end, &buf));
}
pub fn testLEB() !void {
    @setRuntimeSafety(false);
    inline for (.{ u8, u16, u32, u64, i8, i16, i32, i64 }) |T| {
        const LEB128 = zl.fmt.GenericLEB128Format(T);
        const val: T = rng.readOne(T);
        var buf: [4096]u8 = undefined;
        const max: usize = 10000;
        var idx: usize = 0;
        while (idx != max) : (idx +%= 1) {
            const l: T = @intCast(@as(usize, @intCast(val)) -% idx);
            const u: T = @intCast(@as(usize, @intCast(val)) +% idx);
            const u_len: usize = zl.fmt.strlen(LEB128.write(&buf, u), &buf);
            const u_res = try zl.parse.readLEB128(T, buf[0..u_len]);
            try zl.debug.expectEqual(T, u, u_res[0]);
            const l_len: usize = zl.fmt.strlen(LEB128.write(&buf, l), &buf);
            const l_res = try zl.parse.readLEB128(T, buf[0..l_len]);
            try zl.debug.expectEqual(T, l, l_res[0]);
        }
    }
}
fn test1() !void {
    const X = struct {
        x: [25]u8 = .{'a'} ** 25,
        x_len: usize = 0,
    };
    const x: X = .{};
    var buf: [4096]u8 = undefined;
    const end: [*]u8 = zl.fmt.AnyFormat(.{}, X).write(&buf, x);
    zl.debug.write(zl.fmt.slice(end, &buf));
}
fn testChangedBytesFormat() !void {
    var buf: [4096]u8 = undefined;
    comptime var Format = zl.fmt.GenericChangedBytesFormat(.{
        .dec_style = "",
        .inc_style = "",
        .no_style = "",
    });
    var end: [*]u8 = Format.write(&buf, 2, 3);
    try zl.testing.expectEqualString("2B(1B) => 3B", zl.fmt.slice(end, &buf));
    Format = zl.fmt.GenericChangedBytesFormat(.{
        .dec_style = "-\x1b[92m",
        .inc_style = "+\x1b[91m",
        .no_style = "\x1b[0m",
    });
    end = Format.write(&buf, 25, 16);
    try zl.testing.expectEqualString("25B(-\x1b[92m9B\x1b[0m) => 16B", zl.fmt.slice(end, &buf));
}
pub fn main() !void {
    zl.meta.refAllDecls(zl.fmt, &.{});
    try testLEB();
    try testRenderHighlight();
    try testBytesFormat();
    try testBytesToHex();
    try testHexToBytes();
    try testCaseFormat();
    try testGenericRangeFormat();
    try testRenderFunctions();
    try testSystemFlagsFormatters();
    try testChangedBytesFormat();
    try testIntToStringWithSeparators();
    //try testEquivalentIntToStringFormat();
    try @import("fmt/utf8.zig").testUtf8();
    try @import("fmt/ascii.zig").testAscii();
}
