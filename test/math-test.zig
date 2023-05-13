const zig_lib = @import("../zig_lib.zig");

const proc = zig_lib.proc;
const math = zig_lib.math;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

fn testShl() !void {
    try builtin.expect(math.shl(u8, 0b11111111, @as(usize, 3)) == 0b11111000);
    try builtin.expect(math.shl(u8, 0b11111111, @as(usize, 8)) == 0);
    try builtin.expect(math.shl(u8, 0b11111111, @as(usize, 9)) == 0);
    try builtin.expect(math.shl(u8, 0b11111111, @as(isize, -2)) == 0b00111111);
    try builtin.expect(math.shl(u8, 0b11111111, 3) == 0b11111000);
    try builtin.expect(math.shl(u8, 0b11111111, 8) == 0);
    try builtin.expect(math.shl(u8, 0b11111111, 9) == 0);
    try builtin.expect(math.shl(u8, 0b11111111, -2) == 0b00111111);
    try builtin.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, @as(usize, 1))[0] == @as(u32, 42) << 1);
    try builtin.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, @as(isize, -1))[0] == @as(u32, 42) >> 1);
    try builtin.expect(math.shl(@Vector(1, u32), @Vector(1, u32){42}, 33)[0] == 0);
}

fn testShr() !void {
    try builtin.expect(math.shr(u8, 0b11111111, @as(usize, 3)) == 0b00011111);
    try builtin.expect(math.shr(u8, 0b11111111, @as(usize, 8)) == 0);
    try builtin.expect(math.shr(u8, 0b11111111, @as(usize, 9)) == 0);
    try builtin.expect(math.shr(u8, 0b11111111, @as(isize, -2)) == 0b11111100);
    try builtin.expect(math.shr(u8, 0b11111111, 3) == 0b00011111);
    try builtin.expect(math.shr(u8, 0b11111111, 8) == 0);
    try builtin.expect(math.shr(u8, 0b11111111, 9) == 0);
    try builtin.expect(math.shr(u8, 0b11111111, -2) == 0b11111100);
    try builtin.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, @as(usize, 1))[0] == @as(u32, 42) >> 1);
    try builtin.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, @as(isize, -1))[0] == @as(u32, 42) << 1);
    try builtin.expect(math.shr(@Vector(1, u32), @Vector(1, u32){42}, 33)[0] == 0);
}
fn testRotr() !void {
    try builtin.expect(math.rotr(u0, 0b0, @as(usize, 3)) == 0b0);
    try builtin.expect(math.rotr(u5, 0b00001, @as(usize, 0)) == 0b00001);
    try builtin.expect(math.rotr(u6, 0b000001, @as(usize, 7)) == 0b100000);
    try builtin.expect(math.rotr(u8, 0b00000001, @as(usize, 0)) == 0b00000001);
    try builtin.expect(math.rotr(u8, 0b00000001, @as(usize, 9)) == 0b10000000);
    try builtin.expect(math.rotr(u8, 0b00000001, @as(usize, 8)) == 0b00000001);
    try builtin.expect(math.rotr(u8, 0b00000001, @as(usize, 4)) == 0b00010000);
    try builtin.expect(math.rotr(u8, 0b00000001, @as(isize, -1)) == 0b00000010);
    try builtin.expect(math.rotr(@Vector(1, u32), @Vector(1, u32){1}, @as(usize, 1))[0] == @as(u32, 1) << 31);
    try builtin.expect(math.rotr(@Vector(1, u32), @Vector(1, u32){1}, @as(isize, -1))[0] == @as(u32, 1) << 1);
}
fn testRotl() !void {
    try builtin.expect(math.rotl(u0, 0b0, @as(usize, 3)) == 0b0);
    try builtin.expect(math.rotl(u5, 0b00001, @as(usize, 0)) == 0b00001);
    try builtin.expect(math.rotl(u6, 0b000001, @as(usize, 7)) == 0b000010);
    try builtin.expect(math.rotl(u8, 0b00000001, @as(usize, 0)) == 0b00000001);
    try builtin.expect(math.rotl(u8, 0b00000001, @as(usize, 9)) == 0b00000010);
    try builtin.expect(math.rotl(u8, 0b00000001, @as(usize, 8)) == 0b00000001);
    try builtin.expect(math.rotl(u8, 0b00000001, @as(usize, 4)) == 0b00010000);
    try builtin.expect(math.rotl(u8, 0b00000001, @as(isize, -1)) == 0b10000000);
    try builtin.expect(math.rotl(@Vector(1, u32), @Vector(1, u32){1 << 31}, @as(usize, 1))[0] == 1);
    try builtin.expect(math.rotl(@Vector(1, u32), @Vector(1, u32){1 << 31}, @as(isize, -1))[0] == @as(u32, 1) << 30);
}
pub fn main() !void {
    try testRotl();
    try testRotr();
    try testShl();
    try testShr();
}
