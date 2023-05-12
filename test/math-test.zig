const zig_lib = @import("../zig_lib.zig");

const proc = zig_lib.proc;
const math = zig_lib.math;
const builtin = zig_lib.builtin;

pub usingnamespace proc.start;

fn testRotR() !void {
    // try builtin.expect(math.rotr(u5, 0b00001, @as(usize, 0)) == 0b00001);
    // try builtin.expect(math.rotr(u6, 0b000001, @as(usize, 7)) == 0b100000);
    try builtin.expect(math.rotr(u8, 0b00000001, 0) == 0b00000001);
    try builtin.expect(math.rotr(u8, 0b00000001, 9) == 0b10000000);
    try builtin.expect(math.rotr(u8, 0b00000001, 8) == 0b00000001);
    try builtin.expect(math.rotr(u8, 0b00000001, 4) == 0b00010000);
}
fn testRotL() !void {
    // try builtin.expect(math.rotl(u5, 0b00001, @as(usize, 0)) == 0b00001);
    // try builtin.expect(math.rotl(u6, 0b000001, @as(usize, 7)) == 0b000010);
    try builtin.expect(math.rotl(u8, 0b00000001, 0) == 0b00000001);
    try builtin.expect(math.rotl(u8, 0b00000001, 9) == 0b00000010);
    try builtin.expect(math.rotl(u8, 0b00000001, 8) == 0b00000001);
    try builtin.expect(math.rotl(u8, 0b00000001, 4) == 0b00010000);
}
pub fn main() !void {
    try testRotL();
    try testRotR();
}
