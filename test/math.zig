const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const proc = zl.proc;
const math = zl.math;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;

var rng: zl.file.DeviceRandomBytes(4096) = .{};

fn testExtrema() !void {
    try debug.expectEqual(i1, -1, math.extrema(i1).min);
    try debug.expectEqual(u1, 1, math.extrema(u1).max);
}
fn testCast() !void {
    try testing.expect(math.cast(u8, 300) == null);
    try testing.expect(math.cast(u8, @as(u32, 300)) == null);
    try testing.expect(math.cast(i8, -200) == null);
    try testing.expect(math.cast(i8, @as(i32, -200)) == null);
    try testing.expect(math.cast(u8, -1) == null);
    try testing.expect(math.cast(u8, @as(i8, -1)) == null);
    try testing.expect(math.cast(u64, -1) == null);
    try testing.expect(math.cast(u64, @as(i8, -1)) == null);
    try testing.expect(math.cast(u8, 255).? == @as(u8, 255));
    try testing.expect(math.cast(u8, @as(u32, 255)).? == @as(u8, 255));
    try testing.expect(@TypeOf(math.cast(u8, 255).?) == u8);
    try testing.expect(@TypeOf(math.cast(u8, @as(u32, 255)).?) == u8);
}
fn testShl() !void {
    try debug.expect(math.shl(u8, 0b11111111, @as(usize, 3)) == 0b11111000);
    try debug.expect(math.shl(u8, 0b11111111, @as(usize, 8)) == 0);
    try debug.expect(math.shl(u8, 0b11111111, @as(usize, 9)) == 0);
    try debug.expect(math.shl(u8, 0b11111111, @as(isize, -2)) == 0b00111111);
    try debug.expect(math.shl(u8, 0b11111111, 3) == 0b11111000);
    try debug.expect(math.shl(u8, 0b11111111, 8) == 0);
    try debug.expect(math.shl(u8, 0b11111111, 9) == 0);
    try debug.expect(math.shl(u8, 0b11111111, -2) == 0b00111111);
    if (builtin.zig_backend == .stage2_llvm) {
        try debug.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, @as(usize, 1))[0] == @as(u32, 42) << 1);
        try debug.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, @as(isize, -1))[0] == @as(u32, 42) >> 1);
        try debug.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, 33)[0] == 0);
    }
}
fn testShr() !void {
    try debug.expect(math.shr(u8, 0b11111111, @as(usize, 3)) == 0b00011111);
    try debug.expect(math.shr(u8, 0b11111111, @as(usize, 8)) == 0);
    try debug.expect(math.shr(u8, 0b11111111, @as(usize, 9)) == 0);
    try debug.expect(math.shr(u8, 0b11111111, @as(isize, -2)) == 0b11111100);
    try debug.expect(math.shr(u8, 0b11111111, 3) == 0b00011111);
    try debug.expect(math.shr(u8, 0b11111111, 8) == 0);
    try debug.expect(math.shr(u8, 0b11111111, 9) == 0);
    try debug.expect(math.shr(u8, 0b11111111, -2) == 0b11111100);
    if (builtin.zig_backend == .stage2_llvm) {
        try debug.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, @as(usize, 1))[0] == @as(u32, 42) >> 1);
        try debug.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, @as(isize, -1))[0] == @as(u32, 42) << 1);
        try debug.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, 33)[0] == 0);
    }
}
fn testRotr() !void {
    try debug.expect(math.rotr(u0, 0b0, @as(usize, 3)) == 0b0);
    try debug.expect(math.rotr(u5, 0b00001, @as(usize, 0)) == 0b00001);
    try debug.expect(math.rotr(u6, 0b000001, @as(usize, 7)) == 0b100000);
    try debug.expect(math.rotr(u8, 0b00000001, @as(usize, 0)) == 0b00000001);
    try debug.expect(math.rotr(u8, 0b00000001, @as(usize, 9)) == 0b10000000);
    try debug.expect(math.rotr(u8, 0b00000001, @as(usize, 8)) == 0b00000001);
    try debug.expect(math.rotr(u8, 0b00000001, @as(usize, 4)) == 0b00010000);
    try debug.expect(math.rotr(u8, 0b00000001, @as(isize, -1)) == 0b00000010);
    try debug.expect(math.rotr(@Vector(1, u32), @Vector(1, u32){1}, @as(usize, 1))[0] == @as(u32, 1) << 31);
    try debug.expect(math.rotr(@Vector(1, u32), @Vector(1, u32){1}, @as(isize, -1))[0] == @as(u32, 1) << 1);
}
fn testRotl() !void {
    try debug.expect(math.rotl(u0, 0b0, @as(usize, 3)) == 0b0);
    try debug.expect(math.rotl(u5, 0b00001, @as(usize, 0)) == 0b00001);
    try debug.expect(math.rotl(u6, 0b000001, @as(usize, 7)) == 0b000010);
    try debug.expect(math.rotl(u8, 0b00000001, @as(usize, 0)) == 0b00000001);
    try debug.expect(math.rotl(u8, 0b00000001, @as(usize, 9)) == 0b00000010);
    try debug.expect(math.rotl(u8, 0b00000001, @as(usize, 8)) == 0b00000001);
    try debug.expect(math.rotl(u8, 0b00000001, @as(usize, 4)) == 0b00010000);
    try debug.expect(math.rotl(u8, 0b00000001, @as(isize, -1)) == 0b10000000);
    try debug.expect(math.rotl(@Vector(1, u32), @Vector(1, u32){1 << 31}, @as(usize, 1))[0] == 1);
    try debug.expect(math.rotl(@Vector(1, u32), @Vector(1, u32){1 << 31}, @as(isize, -1))[0] == @as(u32, 1) << 30);
}
fn testIsNan() !void {
    try debug.expect(math.float.isNan(math.float.nan(f16)));
    try debug.expect(math.float.isNan(math.float.nan(f32)));
    try debug.expect(math.float.isNan(math.float.nan(f64)));
    // try debug.expect(math.float.isNan(math.nan(f128)));
    try debug.expect(!math.float.isNan(@as(f16, 1.0)));
    try debug.expect(!math.float.isNan(@as(f32, 1.0)));
    try debug.expect(!math.float.isNan(@as(f64, 1.0)));
    // try debug.expect(!math.float.isNan(@as(f128, 1.0)));
}
fn testIsInf() !void {
    inline for ([_]type{ f16, f32, f64 }) |T| {
        try debug.expect(!math.isInf(@as(T, 0.0)));
        try debug.expect(!math.isInf(@as(T, -0.0)));
        try debug.expect(math.isInf(math.float.inf(T)));
        try debug.expect(math.isInf(-math.float.inf(T)));
        try debug.expect(!math.isInf(math.float.nan(T)));
        try debug.expect(!math.isInf(-math.float.nan(T)));
    }
}
fn testIsPositiveInf() !void {
    inline for ([_]type{ f16, f32, f64 }) |T| {
        try debug.expect(!math.isPositiveInf(@as(T, 0.0)));
        try debug.expect(!math.isPositiveInf(@as(T, -0.0)));
        try debug.expect(math.isPositiveInf(math.float.inf(T)));
        try debug.expect(!math.isPositiveInf(-math.float.inf(T)));
        try debug.expect(!math.isInf(math.float.nan(T)));
        try debug.expect(!math.isInf(-math.float.nan(T)));
    }
}
fn testIsNegativeInf() !void {
    inline for ([_]type{ f16, f32, f64 }) |T| {
        try debug.expect(!math.isNegativeInf(@as(T, 0.0)));
        try debug.expect(!math.isNegativeInf(@as(T, -0.0)));
        try debug.expect(!math.isNegativeInf(math.float.inf(T)));
        try debug.expect(math.isNegativeInf(-math.float.inf(T)));
        try debug.expect(!math.isInf(math.float.nan(T)));
        try debug.expect(!math.isInf(-math.float.nan(T)));
    }
}
pub fn main() !void {
    try testRotl();
    try testRotr();
    try testShl();
    try testShr();
    try testIsNan();
    try testCast();
    try testExtrema();
}
