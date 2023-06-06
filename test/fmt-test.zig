const top = @import("../zig_lib.zig");
const fmt = top.fmt;
const mem = top.mem;
const meta = top.meta;
const file = top.file;
const proc = top.proc;
const parse = top.parse;
const builtin = top.builtin;
const testing = top.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
const PrintArray = mem.StaticString(4096);
const test_size: bool = false;
fn testNonChildIntegers() !void {
    var array: PrintArray = .{};
    array.writeAny(.{ .integral = .{ .format = .hex } }, @as(u64, 0xdeadbeef));
    try testing.expectEqualMany(u8, "0xdeadbeef", array.readAll());
}
fn testBytesFormat() !void {
    for ([_]struct { []const u8, u64 }{
        .{ "0B", 0 },
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
        try testing.expectEqualMany(u8, pair[0], fmt.bytes(pair[1]).formatConvert().readAll());
    }
}
fn testEquivalentIntToStringFormat() !void {
    const ubin = fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
    const sbin = fmt.GenericPolynomialFormat(.{ .bits = 1, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
    var uint: u64 = 0;
    const seed: u64 = @ptrToInt(&uint);
    uint = seed;
    try testing.expectEqualMany(u8, "0b0", (sbin{ .value = 0 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "-0b1", (sbin{ .value = -1 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "0b0", (ubin{ .value = 0 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, "0b1", (ubin{ .value = 1 }).formatConvert().readAll());
    try testing.expectEqualMany(u8, builtin.fmt.ub64(uint).readAll(), fmt.ub64(uint).formatConvert().readAll());
    while (uint < seed +% 0x1000) : (uint +%= 1) {
        const uint_32: u32 = @truncate(u32, uint);
        const uint_16: u16 = @truncate(u16, uint);
        const uint_8: u8 = @truncate(u8, uint);
        const sint_64: i64 = @bitReverse(@bitCast(i64, uint));
        const sint_32: i32 = @bitReverse(@bitCast(i32, @truncate(u32, uint)));
        const sint_16: i16 = @bitReverse(@bitCast(i16, @truncate(u16, uint)));
        const sint_8: i8 = @bitReverse(@bitCast(i8, @truncate(u8, uint)));

        try testing.expectEqualMany(u8, builtin.fmt.ub64(uint).readAll(), fmt.ub64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub32(uint_32).readAll(), fmt.ub32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub16(uint_16).readAll(), fmt.ub16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ub8(uint_8).readAll(), fmt.ub8(uint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.uo64(uint).readAll(), fmt.uo64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo32(uint_32).readAll(), fmt.uo32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo16(uint_16).readAll(), fmt.uo16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.uo8(uint_8).readAll(), fmt.uo8(uint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.ud64(uint).readAll(), fmt.ud64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud32(uint_32).readAll(), fmt.ud32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud16(uint_16).readAll(), fmt.ud16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ud8(uint_8).readAll(), fmt.ud8(uint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.ux64(uint).readAll(), fmt.ux64(uint).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux32(uint_32).readAll(), fmt.ux32(uint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux16(uint_16).readAll(), fmt.ux16(uint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ux8(uint_8).readAll(), fmt.ux8(uint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.ib64(sint_64).readAll(), fmt.ib64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib32(sint_32).readAll(), fmt.ib32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib16(sint_16).readAll(), fmt.ib16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ib8(sint_8).readAll(), fmt.ib8(sint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.io64(sint_64).readAll(), fmt.io64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io32(sint_32).readAll(), fmt.io32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io16(sint_16).readAll(), fmt.io16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.io8(sint_8).readAll(), fmt.io8(sint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.id64(sint_64).readAll(), fmt.id64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id32(sint_32).readAll(), fmt.id32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id16(sint_16).readAll(), fmt.id16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.id8(sint_8).readAll(), fmt.id8(sint_8).formatConvert().readAll());

        try testing.expectEqualMany(u8, builtin.fmt.ix64(sint_64).readAll(), fmt.ix64(sint_64).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix32(sint_32).readAll(), fmt.ix32(sint_32).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix16(sint_16).readAll(), fmt.ix16(sint_16).formatConvert().readAll());
        try testing.expectEqualMany(u8, builtin.fmt.ix8(sint_8).readAll(), fmt.ix8(sint_8).formatConvert().readAll());
    }
}
fn testWriteLEB128UnsignedFixed() !void {
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 0);
        try testing.expect((try testReadLEB128(u64, &buf)) == 0);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 1);
        try testing.expect((try testReadLEB128(u64, &buf)) == 1);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 1000);
        try testing.expect((try testReadLEB128(u64, &buf)) == 1000);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 10000000);
        try testing.expect((try testReadLEB128(u64, &buf)) == 10000000);
    }
}
fn testReadLEB128Stream(comptime T: type, encoded: []const u8) !T {
    var reader = mem.view(encoded);
    return try parse.readLEB128(T, reader.readAll());
}
fn testReadLEB128(comptime T: type, encoded: []const u8) !T {
    var reader = mem.view(encoded);
    const v1 = try parse.readLEB128(T, reader.readAll());
    return v1;
}
fn testReadLEB128Seq(comptime T: type, comptime N: usize, encoded: []const u8) !void {
    var reader = mem.view(encoded);
    var i: usize = 0;
    while (i < N) : (i += 1) {
        _ = try parse.readLEB128(T, reader.readAll());
    }
}
fn testEquivalentLEBFormatAndParse() !void {
    const test_stream: bool = false;
    const U8 = fmt.GenericLEB128Format(u8);
    const U16 = fmt.GenericLEB128Format(u16);
    const U32 = fmt.GenericLEB128Format(u32);
    const U64 = fmt.GenericLEB128Format(u64);
    const I8 = fmt.GenericLEB128Format(i8);
    const I16 = fmt.GenericLEB128Format(i16);
    const I32 = fmt.GenericLEB128Format(i32);
    const I64 = fmt.GenericLEB128Format(i64);
    var array: mem.StaticString(4096) = undefined;
    var uint: u64 = 0;
    const seed: u64 = @ptrToInt(&uint);
    uint = seed;
    try testing.expectEqualMany(u8, builtin.fmt.ub64(uint).readAll(), fmt.ub64(uint).formatConvert().readAll());
    while (uint < seed +% 0x1000) : (uint +%= 1) {
        const uint_32: u32 = @truncate(u32, uint);
        const uint_16: u16 = @truncate(u16, uint);
        const uint_8: u8 = @truncate(u8, uint);
        const sint_64: i64 = @bitReverse(@bitCast(i64, uint));
        const sint_32: i32 = @truncate(i32, sint_64);
        const sint_16: i16 = @truncate(i16, sint_64);
        const sint_8: i8 = @truncate(i8, sint_64);
        const uint_64_fmt: U64 = .{ .value = uint };
        const uint_32_fmt: U32 = .{ .value = uint_32 };
        const uint_16_fmt: U16 = .{ .value = uint_16 };
        const uint_8_fmt: U8 = .{ .value = uint_8 };
        const sint_64_fmt: I64 = .{ .value = sint_64 };
        const sint_32_fmt: I32 = .{ .value = sint_32 };
        const sint_16_fmt: I16 = .{ .value = sint_16 };
        const sint_8_fmt: I8 = .{ .value = sint_8 };
        array.undefineAll();
        uint_64_fmt.formatWrite(&array);
        try builtin.expectEqual(u64, uint, try parse.readLEB128(u64, array.readAll()));
        array.undefineAll();
        uint_32_fmt.formatWrite(&array);
        try builtin.expectEqual(u32, uint_32, try parse.readLEB128(u32, array.readAll()));
        array.undefineAll();
        uint_16_fmt.formatWrite(&array);
        try builtin.expectEqual(u16, uint_16, try parse.readLEB128(u16, array.readAll()));
        array.undefineAll();
        uint_8_fmt.formatWrite(&array);
        try builtin.expectEqual(u8, uint_8, try parse.readLEB128(u8, array.readAll()));
        array.undefineAll();
        sint_64_fmt.formatWrite(&array);
        try builtin.expectEqual(i64, sint_64, try parse.readLEB128(i64, array.readAll()));
        array.undefineAll();
        sint_32_fmt.formatWrite(&array);
        try builtin.expectEqual(i32, sint_32, try parse.readLEB128(i32, array.readAll()));
        array.undefineAll();
        sint_16_fmt.formatWrite(&array);
        try builtin.expectEqual(i16, sint_16, try parse.readLEB128(i16, array.readAll()));
        array.undefineAll();
        sint_8_fmt.formatWrite(&array);
        try builtin.expectEqual(i8, sint_8, try parse.readLEB128(i8, array.readAll()));
    }
    if (test_stream) {
        try testing.expectError(error.EndOfStream, testReadLEB128Stream(i64, "\x80"));
    }
    try testing.expectError(error.Overflow, testReadLEB128(i8, "\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(i16, "\x80\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(i32, "\x80\x80\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(i8, "\xff\x7e"));
    try testing.expectError(error.Overflow, testReadLEB128(i32, "\x80\x80\x80\x80\x08"));
    try testing.expectError(error.Overflow, testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x01"));

    try testing.expect((try testReadLEB128(i64, "\x00")) == 0);
    try testing.expect((try testReadLEB128(i64, "\x01")) == 1);
    try testing.expect((try testReadLEB128(i64, "\x3f")) == 63);
    try testing.expect((try testReadLEB128(i64, "\x40")) == -64);
    try testing.expect((try testReadLEB128(i64, "\x41")) == -63);
    try testing.expect((try testReadLEB128(i64, "\x7f")) == -1);
    try testing.expect((try testReadLEB128(i64, "\x80\x01")) == 128);
    try testing.expect((try testReadLEB128(i64, "\x81\x01")) == 129);
    try testing.expect((try testReadLEB128(i64, "\xff\x7e")) == -129);
    try testing.expect((try testReadLEB128(i64, "\x80\x7f")) == -128);
    try testing.expect((try testReadLEB128(i64, "\x81\x7f")) == -127);
    try testing.expect((try testReadLEB128(i64, "\xc0\x00")) == 64);
    try testing.expect((try testReadLEB128(i64, "\xc7\x9f\x7f")) == -12345);
    try testing.expect((try testReadLEB128(i8, "\xff\x7f")) == -1);
    try testing.expect((try testReadLEB128(i16, "\xff\xff\x7f")) == -1);
    try testing.expect((try testReadLEB128(i32, "\xff\xff\xff\xff\x7f")) == -1);
    try testing.expect((try testReadLEB128(i32, "\x80\x80\x80\x80\x78")) == -0x80000000);
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")) == @bitCast(i64, @intCast(u64, 0x8000000000000000)));
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x40")) == -0x4000000000000000);
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")) == -0x8000000000000000);

    try testing.expect((try testReadLEB128(i64, "\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(i64, "\xff\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(i64, "\xff\x80\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(i64, "\x80\x81\x00")) == 0x80);
    try testing.expect((try testReadLEB128(i64, "\x80\x81\x80\x00")) == 0x80);

    try testReadLEB128Seq(i64, 4, "\x81\x01\x3f\x80\x7f\x80\x80\x80\x00");
    if (test_stream) {
        try testing.expectError(error.EndOfStream, testReadLEB128Stream(u64, "\x80"));
    }
    try testing.expectError(error.Overflow, testReadLEB128(u8, "\x80\x02"));
    try testing.expectError(error.Overflow, testReadLEB128(u8, "\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(u16, "\x80\x80\x84"));
    try testing.expectError(error.Overflow, testReadLEB128(u16, "\x80\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(u32, "\x80\x80\x80\x80\x90"));
    try testing.expectError(error.Overflow, testReadLEB128(u32, "\x80\x80\x80\x80\x40"));
    try testing.expectError(error.Overflow, testReadLEB128(u64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x40"));

    try testing.expect((try testReadLEB128(u64, "\x00")) == 0);
    try testing.expect((try testReadLEB128(u64, "\x01")) == 1);
    try testing.expect((try testReadLEB128(u64, "\x3f")) == 63);
    try testing.expect((try testReadLEB128(u64, "\x40")) == 64);
    try testing.expect((try testReadLEB128(u64, "\x7f")) == 0x7f);
    try testing.expect((try testReadLEB128(u64, "\x80\x01")) == 0x80);
    try testing.expect((try testReadLEB128(u64, "\x81\x01")) == 0x81);
    try testing.expect((try testReadLEB128(u64, "\x90\x01")) == 0x90);
    try testing.expect((try testReadLEB128(u64, "\xff\x01")) == 0xff);
    try testing.expect((try testReadLEB128(u64, "\x80\x02")) == 0x100);
    try testing.expect((try testReadLEB128(u64, "\x81\x02")) == 0x101);
    try testing.expect((try testReadLEB128(u64, "\x80\xc1\x80\x80\x10")) == 4294975616);
    try testing.expect((try testReadLEB128(u64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x01")) == 0x8000000000000000);

    try testing.expect((try testReadLEB128(u64, "\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(u64, "\x80\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(u64, "\xff\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(u64, "\xff\x80\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(u64, "\x80\x81\x00")) == 0x80);
    try testing.expect((try testReadLEB128(u64, "\x80\x81\x80\x00")) == 0x80);

    try testReadLEB128Seq(u64, 4, "\x81\x01\x3f\x80\x7f\x80\x80\x80\x00");
}

pub const render_radix: u16 = 16;

fn testBytesToHex() !void {
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
fn testBinarySize() void {
    var array: PrintArray = .{};
    array.writeFormat(fmt.ux64(@ptrToInt(&array)));
    builtin.debug.write(array.readAll());
}
pub fn main() !void {
    try testBytesToHex();
    try testHexToBytes();
    try @import("./fmt/utf8.zig").utf8TestMain();
    try @import("./fmt/ascii.zig").asciiTestMain();
    if (test_size) {
        try meta.wrap(testBinarySize());
    } else {
        try meta.wrap(testEquivalentIntToStringFormat());
        try meta.wrap(testEquivalentLEBFormatAndParse());
        try meta.wrap(testBytesFormat());
        try meta.wrap(testNonChildIntegers());
    }
}
