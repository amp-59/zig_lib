const zig_lib = @import("../zig_lib.zig");
const mem = zig_lib.mem;
const rng = zig_lib.rng;
const proc = zig_lib.proc;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
fn testXoroshiroSequence() !void {
    var r: rng.Xoroshiro128 = rng.Xoroshiro128.init(0);
    r.s[0] = 0xaeecf86f7878dd75;
    r.s[1] = 0x01cd153642e72622;
    const seq1 = [_]u64{
        0xb0ba0da5bb600397, 0x18a08afde614dccc,
        0xa2635b956a31b929, 0xabe633c971efa045,
        0x9ac19f9706ca3cac, 0xf62b426578c1e3fb,
    };
    for (seq1) |s| {
        try builtin.expect(s == r.next());
    }
    r.jump();
    const seq2: [6]u64 = [_]u64{
        0x95344a13556d3e22, 0xb4fb32dafa4d00df,
        0xb2011d9ccdcfe2dd, 0x05679a9b2119b908,
        0xa860a1da7c9cd8a0, 0x658a96efe3f86550,
    };
    for (seq2) |s| {
        try builtin.expect(s == r.next());
    }
}
fn testXoroshiroFill() !void {
    var r: rng.Xoroshiro128 = rng.Xoroshiro128.init(0);
    r.s[0] = 0xaeecf86f7878dd75;
    r.s[1] = 0x01cd153642e72622;
    const seq: [6]u64 = [_]u64{
        0xb0ba0da5bb600397, 0x18a08afde614dccc,
        0xa2635b956a31b929, 0xabe633c971efa045,
        0x9ac19f9706ca3cac, 0xf62b426578c1e3fb,
    };
    for (seq) |s| {
        var buf0: [8]u8 = undefined;
        var buf1: [7]u8 = undefined;
        mem.writeIntLittle(u64, &buf0, s);
        r.fill(&buf1);
        try testing.expectEqualMany(u8, buf0[0..7], buf1[0..]);
    }
}
pub fn main() !void {
    try testXoroshiroSequence();
    try testXoroshiroFill();
}
