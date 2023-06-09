const top = @import("../../zig_lib.zig");
const math = top.math;
const parse = top.parse;
const builtin = top.builtin;
const testing = top.testing;

fn testParseFloatNaNAndInf() !void {
    inline for ([_]type{ f16, f32, f64, f128 }) |T| {
        if (T == f128) return;
        const Z = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = @typeInfo(T).Float.bits } });
        try builtin.expectEqual(Z, @bitCast(Z, try parse.parseFloat(T, "nAn")), @bitCast(Z, math.float.nan(T)));
        try builtin.expectEqual(T, try parse.parseFloat(T, "inF"), math.float.inf(T));
        try builtin.expectEqual(T, try parse.parseFloat(T, "-INF"), -math.float.inf(T));
    }
}
fn testParseFloat11169() !void {
    if (return) {}
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "9007199254740993.0"), 9007199254740993.0);
}
fn testParseFloatHexSpecial() !void {
    try builtin.expect(math.float.isNan(try parse.parseFloat(f32, "nAn")));
    try builtin.expect(math.float.isPositiveInf(try parse.parseFloat(f32, "iNf")));
    try builtin.expect(math.float.isPositiveInf(try parse.parseFloat(f32, "+Inf")));
    try builtin.expect(math.float.isNegativeInf(try parse.parseFloat(f32, "-iNf")));
}
fn testParseFloatHexZero() !void {
    try builtin.expectEqual(f32, @as(f32, 0.0), try parse.parseFloat(f32, "0x0"));
    try builtin.expectEqual(f32, @as(f32, 0.0), try parse.parseFloat(f32, "-0x0"));
    try builtin.expectEqual(f32, @as(f32, 0.0), try parse.parseFloat(f32, "0x0p42"));
    try builtin.expectEqual(f32, @as(f32, 0.0), try parse.parseFloat(f32, "-0x0.00000p42"));
    try builtin.expectEqual(f32, @as(f32, 0.0), try parse.parseFloat(f32, "0x0.00000p666"));
}
fn testParseFloatHexF16() !void {
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x1p0"), 1.0);
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "-0x1p-1"), -0.5);
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x10p+10"), 16384.0);
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x10p-10"), 0.015625);
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x1.ffcp+15"), math.float.max(f16));
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "-0x1.ffcp+15"), -math.float.max(f16));
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x1p-14"), math.float.min(f16));
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "-0x1p-14"), -math.float.min(f16));
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "0x1p-24"), math.float.trueMin(f16));
    try builtin.expectEqual(f16, try parse.parseFloat(f16, "-0x1p-24"), -math.float.trueMin(f16));
}
fn testParseFloatHexF32() !void {
    try builtin.expect(error.InvalidCharacter == parse.parseFloat(f32, "0x"));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x1p0"), 1.0);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "-0x1p-1"), -0.5);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x10p+10"), 16384.0);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x10p-10"), 0.015625);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x0.ffffffp128"), 0x0.ffffffp128);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x0.1234570p-125"), 0x0.1234570p-125);
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x1.fffffeP+127"), math.float.max(f32));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "-0x1.fffffeP+127"), -math.float.max(f32));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x1p-126"), math.float.min(f32));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "-0x1p-126"), -math.float.min(f32));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "0x1P-149"), math.float.trueMin(f32));
    try builtin.expectEqual(f32, try parse.parseFloat(f32, "-0x1P-149"), -math.float.trueMin(f32));
}
fn testParseFloatHexF64() !void {
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x1p0"), 1.0);
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "-0x1p-1"), -0.5);
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x10p+10"), 16384.0);
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x10p-10"), 0.015625);
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x1.fffffffffffffp+1023"), math.float.max(f64));
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "-0x1.fffffffffffffp1023"), -math.float.max(f64));
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x1p-1022"), math.float.min(f64));
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "-0x1p-1022"), -math.float.min(f64));
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "0x1p-1074"), math.float.trueMin(f64));
    try builtin.expectEqual(f64, try parse.parseFloat(f64, "-0x1p-1074"), -math.float.trueMin(f64));
}
fn testParseFloatHexF128() !void {
    if (return) {}
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x1p0"), 1.0);
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "-0x1p-1"), -0.5);
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x10p+10"), 16384.0);
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x10p-10"), 0.015625);
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0xf.fffffffffffffffffffffffffff8p+16380"), math.float.max(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "-0xf.fffffffffffffffffffffffffff8p+16380"), -math.float.max(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x1p-16382"), math.float.min(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "-0x1p-16382"), -math.float.min(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x1p-16494"), math.float.trueMin(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "-0x1p-16494"), -math.float.trueMin(f128));
    try builtin.expectEqual(f128, try parse.parseFloat(f128, "0x1.edcb34a235253948765432134674fp-1"), 0x1.edcb34a235253948765432134674fp-1);
}
fn testParseFloat() !void {
    inline for ([_]type{ f16, f32, f64, f128 }) |T| {
        if (T == f128) return;
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, ""));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "   1"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "1abc"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "+"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "-"));
        try builtin.expectEqual(T, try parse.parseFloat(T, "0"), 0.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "0"), 0.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "+0"), 0.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "-0"), 0.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "0e0"), 0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "2e3"), 2000.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1e0"), 1.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "-2e3"), -2000.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "-1e0"), -1.0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1.234e3"), 1234);
        try builtin.expectEqual(T, try parse.parseFloat(T, "3.141"), 3.141);
        try builtin.expectEqual(T, try parse.parseFloat(T, "-3.141"), -3.141);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1e-5000"), 0);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1e+5000"), math.float.inf(T));
        try builtin.expectEqual(T, try parse.parseFloat(T, "0.4e0066999999999999999999999999999999999999999999999999999"), math.float.inf(T));
        try builtin.expectEqual(T, try parse.parseFloat(T, "0_1_2_3_4_5_6.7_8_9_0_0_0e0_0_1_0"), @as(T, 123456.789000e10));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "0123456.789000e_0010"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "_0123456.789000e0010"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "0__123456.789000e_0010"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "0123456_.789000e0010"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "0123456.789000e0010_"));
        try builtin.expectEqual(T, try parse.parseFloat(T, "1e-2"), 0.01);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1234e-2"), 12.34);
        try builtin.expectEqual(T, try parse.parseFloat(T, "1."), 1);
        try builtin.expectEqual(T, try parse.parseFloat(T, "0."), 0);
        try builtin.expectEqual(T, try parse.parseFloat(T, ".1"), 0.1);
        try builtin.expectEqual(T, try parse.parseFloat(T, ".0"), 0);
        try builtin.expectEqual(T, try parse.parseFloat(T, ".1e-1"), 0.01);
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "."));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, ".e1"));
        try builtin.expect(error.InvalidCharacter == parse.parseFloat(T, "0.e"));
        try builtin.expectEqual(T, try parse.parseFloat(T, "123142.1"), 123142.1);
        try builtin.expectEqual(T, try parse.parseFloat(T, "-123142.1124"), @as(T, -123142.1124));
        try builtin.expectEqual(T, try parse.parseFloat(T, "0.7062146892655368"), @as(T, 0.7062146892655368));
        try builtin.expectEqual(T, try parse.parseFloat(T, "2.71828182845904523536"), @as(T, 2.718281828459045));
    }
}
pub fn floatTestMain() !void {
    if (@hasDecl(top.parse, "parseFloat")) {
        try testParseFloatNaNAndInf();
        try testParseFloat11169();
        try testParseFloatHexSpecial();
        try testParseFloatHexZero();
        try testParseFloatHexF16();
        try testParseFloatHexF32();
        try testParseFloatHexF64();
        try testParseFloatHexF128();
        try testParseFloat();
    }
}
