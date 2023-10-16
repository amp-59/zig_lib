const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const mem = zl.mem;
const meta = zl.meta;
const math = zl.math;
const file = zl.file;
const proc = zl.proc;
const debug = zl.debug;
const parse = zl.parse;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;

fn testWriteLEB128UnsignedFixed() !void {
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 0);
        try testing.expect((try testReadLEB128(u64, &buf)[0]) == 0);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 1);
        try testing.expect((try testReadLEB128(u64, &buf)[0]) == 1);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 1000);
        try testing.expect((try testReadLEB128(u64, &buf)[0]) == 1000);
    }
    {
        var buf: [4]u8 = undefined;
        fmt.writeUnsignedFixed(4, &buf, 10000000);
        try testing.expect((try testReadLEB128(u64, &buf)[0]) == 10000000);
    }
}
fn testReadLEB128(comptime T: type, encoded: []const u8) !T {
    const v1 = try parse.readLEB128(T, encoded);
    return v1[0];
}
fn testReadLEB128Seq(comptime T: type, comptime N: usize, encoded: []const u8) !void {
    var reader = mem.array.view(encoded);
    var i: usize = 0;
    while (i < N) : (i += 1) {
        _ = try parse.readLEB128(T, reader.readAll());
    }
}
fn testEquivalentLEBFormatAndParse() !void {
    testing.announce(@src());
    var rng: file.DeviceRandomBytes(4096) = .{};
    const U8 = fmt.GenericLEB128Format(u8);
    const U16 = fmt.GenericLEB128Format(u16);
    const U32 = fmt.GenericLEB128Format(u32);
    const U64 = fmt.GenericLEB128Format(u64);
    const I8 = fmt.GenericLEB128Format(i8);
    const I16 = fmt.GenericLEB128Format(i16);
    const I32 = fmt.GenericLEB128Format(i32);
    const I64 = fmt.GenericLEB128Format(i64);
    var array: mem.array.StaticString(4096) = undefined;
    array.undefineAll();
    for (0..1000) |_| {
        const uint: u64 = rng.readOne(u64);
        const uint_32: u32 = @truncate(uint);
        const uint_16: u16 = @as(u16, @truncate(uint));
        const uint_8: u8 = @as(u8, @truncate(uint));
        const sint_64: i64 = @bitReverse(@as(i64, @bitCast(uint)));
        const sint_32: i32 = @as(i32, @truncate(sint_64));
        const sint_16: i16 = @as(i16, @truncate(sint_64));
        const sint_8: i8 = @as(i8, @truncate(sint_64));
        const uint_64_fmt: U64 = .{ .value = uint };
        const uint_32_fmt: U32 = .{ .value = uint_32 };
        const uint_16_fmt: U16 = .{ .value = uint_16 };
        const uint_8_fmt: U8 = .{ .value = uint_8 };
        const sint_64_fmt: I64 = .{ .value = sint_64 };
        const sint_32_fmt: I32 = .{ .value = sint_32 };
        const sint_16_fmt: I16 = .{ .value = sint_16 };
        const sint_8_fmt: I8 = .{ .value = sint_8 };
        {
            uint_64_fmt.formatWrite(&array);
            const res = try parse.readLEB128(u64, array.readAll());
            try debug.expectEqual(u64, uint, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            uint_32_fmt.formatWrite(&array);
            const res = try parse.readLEB128(u32, array.readAll());
            try debug.expectEqual(u32, uint_32, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            uint_16_fmt.formatWrite(&array);
            const res = try parse.readLEB128(u16, array.readAll());
            try debug.expectEqual(u16, uint_16, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            uint_8_fmt.formatWrite(&array);
            const res = try parse.readLEB128(u8, array.readAll());
            try debug.expectEqual(u8, uint_8, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            sint_64_fmt.formatWrite(&array);
            const res = try parse.readLEB128(i64, array.readAll());
            try debug.expectEqual(i64, sint_64, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            sint_32_fmt.formatWrite(&array);
            const res = try parse.readLEB128(i32, array.readAll());
            try debug.expectEqual(i32, sint_32, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            sint_16_fmt.formatWrite(&array);
            const res = try parse.readLEB128(i16, array.readAll());
            try debug.expectEqual(i16, sint_16, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
        {
            sint_8_fmt.formatWrite(&array);
            const res = try parse.readLEB128(i8, array.readAll());
            try debug.expectEqual(i8, sint_8, res[0]);
            try debug.expectEqual(usize, array.len(), res[1]);
            array.undefineAll();
        }
    }

    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i8, "\x80\x80\x40"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i16, "\x80\x80\x80\x40"));
    // try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i32, "\x80\x80\x80\x80\x40"));
    // try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x40"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i8, "\xff\x7e"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i32, "\x80\x80\x80\x80\x08"));
    // try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x01"));

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
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")) == @as(i64, @bitCast(@as(u64, @intCast(0x8000000000000000)))));
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x40")) == -0x4000000000000000);
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x7f")) == -0x8000000000000000);

    try testing.expect((try testReadLEB128(i64, "\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(i64, "\x80\x80\x00")) == 0);
    try testing.expect((try testReadLEB128(i64, "\xff\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(i64, "\xff\x80\x00")) == 0x7f);
    try testing.expect((try testReadLEB128(i64, "\x80\x81\x00")) == 0x80);
    try testing.expect((try testReadLEB128(i64, "\x80\x81\x80\x00")) == 0x80);

    try testReadLEB128Seq(i64, 4, "\x81\x01\x3f\x80\x7f\x80\x80\x80\x00");
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u8, "\x80\x02"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u8, "\x80\x80\x40"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u16, "\x80\x80\x84"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u16, "\x80\x80\x80\x40"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u32, "\x80\x80\x80\x80\x90"));
    try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u32, "\x80\x80\x80\x80\x40"));
    //try testing.expectError(error.IntCastTruncatedBits, testReadLEB128(u64, "\x80\x80\x80\x80\x80\x80\x80\x80\x80\x40"));

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

fn testParseUserInt() !void {
    try debug.expectEqual(usize, 16, try parse.unsigned("0x10"));
    try debug.expectEqual(usize, 2, try parse.unsigned("0b10"));
    try debug.expectEqual(usize, 10, try parse.unsigned("10"));
    try debug.expectEqual(isize, 2, try parse.signed("0b10"));
    try debug.expectEqual(isize, -2, try parse.signed("-0b10"));
    try debug.expectEqual(isize, -10, try parse.signed("-10"));
    try debug.expect(try parse.signed("-10") == -10);
    try debug.expect(try parse.signed("+10") == 10);
    try debug.expect(try parse.signed("+10") == 10);
    try debug.expect(try parse.unsigned("255") == 255);
    try debug.expect(try parse.signed("-0") == 0);
    try debug.expect(try parse.signed("+0") == 0);
    try debug.expect(try parse.signed("-1") == -1);
    try debug.expect(try parse.signed("-128") == -128);
    try debug.expect(try parse.signed("-4398046511104") == -4398046511104);
    try debug.expectEqual(usize, try parse.unsigned("111"), 111);
    try debug.expectEqual(isize, try parse.signed("+0b111"), 7);
    try debug.expectEqual(isize, try parse.signed("+0o111"), 73);
    try debug.expectEqual(isize, try parse.signed("+0x111"), 273);
    try debug.expectEqual(isize, try parse.signed("-0b111"), -7);
    try debug.expectEqual(isize, try parse.signed("-0o111"), -73);
    try debug.expectEqual(isize, try parse.signed("-0x111"), -273);
    try debug.expectEqual(usize, 16, parse.noexcept.unsigned("0x10"));
    try debug.expectEqual(usize, 2, parse.noexcept.unsigned("0b10"));
    try debug.expectEqual(usize, 10, parse.noexcept.unsigned("10"));
    try debug.expectEqual(isize, 2, parse.noexcept.signed("0b10"));
    try debug.expect(parse.noexcept.signed("-10") == -10);
    try debug.expect(parse.noexcept.signed("+10") == 10);
    try debug.expect(parse.noexcept.signed("+10") == 10);
    try debug.expect(parse.noexcept.unsigned("255") == 255);
    try debug.expect(parse.noexcept.signed("-0") == 0);
    try debug.expect(parse.noexcept.signed("+0") == 0);
    try debug.expect(parse.noexcept.signed("-1") == -1);
    try debug.expect(parse.noexcept.signed("-128") == -128);
    try debug.expect(parse.noexcept.signed("-4398046511104") == -4398046511104);
    try debug.expectEqual(usize, parse.noexcept.unsigned("111"), 111);
    try debug.expectEqual(isize, parse.noexcept.signed("+0b111"), 7);
    try debug.expectEqual(isize, parse.noexcept.signed("+0o111"), 73);
    try debug.expectEqual(isize, parse.noexcept.signed("+0x111"), 273);
    try debug.expectEqual(isize, parse.noexcept.signed("-0b111"), -7);
    try debug.expectEqual(isize, parse.noexcept.signed("-0o111"), -73);
    try debug.expectEqual(isize, parse.noexcept.signed("-0x111"), -273);
}
fn testParseReusableIntExhaustive() !void {
    var rng: file.DeviceRandomBytes(4096) = .{};
    var buf: [4096]u8 = undefined;
    inline for (2..17) |bits| {
        const radix = switch (bits) {
            1...3 => 2,
            4...8 => 8,
            9...15 => 10,
            else => 16,
        };
        const prefix = switch (radix) {
            2 => "0b",
            8 => "0o",
            16 => "0x",
            else => null,
        };
        const S = fmt.GenericPolynomialFormat(.{ .bits = bits, .signedness = .signed, .radix = radix, .width = .min, .prefix = prefix });
        const U = fmt.GenericPolynomialFormat(.{ .bits = bits, .signedness = .unsigned, .radix = radix, .width = .min, .prefix = prefix });
        var s: S = .{ .value = 0 };
        var u: U = .{ .value = 0 };
        const extrema: math.Extrema = math.extrema(S.Int);
        var idx: S.Int = extrema.min;
        while (idx != extrema.max) : (idx +%= mem.unstable(S.Int, 1)) {
            s.value = @bitCast(idx);
            u.value = @bitCast(idx);
            const ss: []const u8 = s.formatConvert().readAll();
            const us: []const u8 = u.formatConvert().readAll();
            try debug.expectEqual(S.Int, s.value, @as(S.Int, @truncate(try parse.signed(ss))));
            try debug.expectEqual(U.Int, u.value, @as(U.Int, @truncate(try parse.unsigned(us))));
        }
    }
    inline for (.{ i1, i2, i4, i8, i16, i32, i64 }) |T| {
        const extrema: math.Extrema = math.extrema(T);
        const random: T = rng.readOne(T);
        const hex_min_s: []const u8 = fmt.ix(extrema.min).formatConvert().readAll();
        const dec_min_s: []const u8 = fmt.id(extrema.min).formatConvert().readAll();
        const bin_min_s: []const u8 = fmt.ib(extrema.min).formatConvert().readAll();
        const hex_rng_s: []const u8 = fmt.ix(random).formatConvert().readAll();
        const dec_rng_s: []const u8 = fmt.id(random).formatConvert().readAll();
        const bin_rng_s: []const u8 = fmt.ib(random).formatConvert().readAll();
        const hex_max_s: []const u8 = fmt.ix(extrema.max).formatConvert().readAll();
        const dec_max_s: []const u8 = fmt.id(extrema.max).formatConvert().readAll();
        const bin_max_s: []const u8 = fmt.ib(extrema.max).formatConvert().readAll();
        try debug.expectEqual(isize, extrema.min, try parse.signed(hex_min_s));
        try debug.expectEqual(isize, extrema.min, try parse.signed(dec_min_s));
        try debug.expectEqual(isize, extrema.min, try parse.signed(bin_min_s));
        try debug.expectEqual(isize, random, try parse.signed(hex_rng_s));
        try debug.expectEqual(isize, random, try parse.signed(dec_rng_s));
        try debug.expectEqual(isize, random, try parse.signed(bin_rng_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(hex_max_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(dec_max_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(bin_max_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(hex_min_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(dec_min_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(bin_min_s));
        try debug.expectEqual(isize, random, parse.noexcept.signed(hex_rng_s));
        try debug.expectEqual(isize, random, parse.noexcept.signed(dec_rng_s));
        try debug.expectEqual(isize, random, parse.noexcept.signed(bin_rng_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(hex_max_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(dec_max_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(bin_max_s));
    }
    inline for (.{ u1, u2, u4, u8, u16, u32, u64 }) |T| {
        for (0..1000) |_| {
            const extrema: math.Extrema = math.extrema(T);
            const random: T = rng.readOne(T);
            const hex_min_s: []const u8 = fmt.ux(extrema.min).formatConvert().readAll();
            const dec_min_s: []const u8 = fmt.ud(extrema.min).formatConvert().readAll();
            const bin_min_s: []const u8 = fmt.ub(extrema.min).formatConvert().readAll();
            const hex_rng_s: []const u8 = fmt.ux(random).formatConvert().readAll();
            const dec_rng_s: []const u8 = fmt.ud(random).formatConvert().readAll();
            const bin_rng_s: []const u8 = fmt.ub(random).formatConvert().readAll();
            const hex_max_s: []const u8 = fmt.ux(extrema.max).formatConvert().readAll();
            const dec_max_s: []const u8 = fmt.ud(extrema.max).formatConvert().readAll();
            const bin_max_s: []const u8 = fmt.ub(extrema.max).formatConvert().readAll();
            try debug.expectEqual(usize, extrema.min, try parse.unsigned(hex_min_s));
            try debug.expectEqual(usize, extrema.min, try parse.unsigned(dec_min_s));
            try debug.expectEqual(usize, extrema.min, try parse.unsigned(bin_min_s));
            try debug.expectEqual(usize, random, try parse.unsigned(hex_rng_s));
            try debug.expectEqual(usize, random, try parse.unsigned(dec_rng_s));
            try debug.expectEqual(usize, random, try parse.unsigned(bin_rng_s));
            try debug.expectEqual(usize, extrema.max, try parse.unsigned(hex_max_s));
            try debug.expectEqual(usize, extrema.max, try parse.unsigned(dec_max_s));
            try debug.expectEqual(usize, extrema.max, try parse.unsigned(bin_max_s));
            try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(hex_min_s));
            try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(dec_min_s));
            try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(bin_min_s));
            try debug.expectEqual(usize, random, parse.noexcept.unsigned(hex_rng_s));
            try debug.expectEqual(usize, random, parse.noexcept.unsigned(dec_rng_s));
            try debug.expectEqual(usize, random, parse.noexcept.unsigned(bin_rng_s));
            try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(hex_max_s));
            try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(dec_max_s));
            try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(bin_max_s));
            if (@bitSizeOf(T) > 8) {
                var leb128_u64: fmt.Type.U64xLEB128 = .{ .value = random };
                var len: usize = leb128_u64.formatWriteBuf(&buf);
                try debug.expectEqual(T, @intCast(parse.noexcept.unsignedLEB128(buf[0..len].ptr)[0]), random);
            }
        }
    }
}
pub fn main() !void {
    try testEquivalentLEBFormatAndParse();
    try testParseUserInt();
    try testParseReusableIntExhaustive();
    try @import("./parse/float.zig").floatTestMain();
}
