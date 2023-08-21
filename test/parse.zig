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

fn testParseInt() !void {
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
fn testParseIntExhaustive() !void {
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
        const hex_min_s: []const u8 = fmt.ix(extrema.min).formatConvert().readAll();
        const dec_min_s: []const u8 = fmt.id(extrema.min).formatConvert().readAll();
        const bin_min_s: []const u8 = fmt.ib(extrema.min).formatConvert().readAll();
        const hex_max_s: []const u8 = fmt.ix(extrema.max).formatConvert().readAll();
        const dec_max_s: []const u8 = fmt.id(extrema.max).formatConvert().readAll();
        const bin_max_s: []const u8 = fmt.ib(extrema.max).formatConvert().readAll();
        try debug.expectEqual(isize, extrema.min, try parse.signed(hex_min_s));
        try debug.expectEqual(isize, extrema.min, try parse.signed(dec_min_s));
        try debug.expectEqual(isize, extrema.min, try parse.signed(bin_min_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(hex_max_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(dec_max_s));
        try debug.expectEqual(isize, extrema.max, try parse.signed(bin_max_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(hex_min_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(dec_min_s));
        try debug.expectEqual(isize, extrema.min, parse.noexcept.signed(bin_min_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(hex_max_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(dec_max_s));
        try debug.expectEqual(isize, extrema.max, parse.noexcept.signed(bin_max_s));
    }
    inline for (.{ u1, u2, u4, u8, u16, u32, u64 }) |T| {
        const extrema: math.Extrema = math.extrema(T);
        const hex_min_s: []const u8 = fmt.ux(extrema.min).formatConvert().readAll();
        const dec_min_s: []const u8 = fmt.ud(extrema.min).formatConvert().readAll();
        const bin_min_s: []const u8 = fmt.ub(extrema.min).formatConvert().readAll();
        const hex_max_s: []const u8 = fmt.ux(extrema.max).formatConvert().readAll();
        const dec_max_s: []const u8 = fmt.ud(extrema.max).formatConvert().readAll();
        const bin_max_s: []const u8 = fmt.ub(extrema.max).formatConvert().readAll();
        try debug.expectEqual(usize, extrema.min, try parse.unsigned(hex_min_s));
        try debug.expectEqual(usize, extrema.min, try parse.unsigned(dec_min_s));
        try debug.expectEqual(usize, extrema.min, try parse.unsigned(bin_min_s));
        try debug.expectEqual(usize, extrema.max, try parse.unsigned(hex_max_s));
        try debug.expectEqual(usize, extrema.max, try parse.unsigned(dec_max_s));
        try debug.expectEqual(usize, extrema.max, try parse.unsigned(bin_max_s));
        try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(hex_min_s));
        try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(dec_min_s));
        try debug.expectEqual(usize, extrema.min, parse.noexcept.unsigned(bin_min_s));
        try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(hex_max_s));
        try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(dec_max_s));
        try debug.expectEqual(usize, extrema.max, parse.noexcept.unsigned(bin_max_s));
    }
}
pub fn main() !void {
    try testParseInt();
    try testParseIntExhaustive();
    try @import("./parse/float.zig").floatTestMain();
}
