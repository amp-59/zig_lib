const zig_lib = @import("../../zig_lib.zig");
const math = zig_lib.math;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const testing = zig_lib.testing;
const builtin = zig_lib.builtin;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
fn testTimingSafeEql() !void {
    var a: [100]u8 = undefined;
    var b: [100]u8 = undefined;
    crypto.random.bytes(a[0..]);
    crypto.random.bytes(b[0..]);
    try builtin.expect(!crypto.utils.timingSafeEql([100]u8, a, b));
    a = b;
    try builtin.expect(crypto.utils.timingSafeEql([100]u8, a, b));
}
fn testTimingSafeEqlVectors() !void {
    var a: [100]u8 = undefined;
    var b: [100]u8 = undefined;
    crypto.random.bytes(a[0..]);
    crypto.random.bytes(b[0..]);
    const v1: @Vector(100, u8) = a;
    const v2: @Vector(100, u8) = b;
    try builtin.expect(!crypto.utils.timingSafeEql(@Vector(100, u8), v1, v2));
    const v3: @Vector(100, u8) = a;
    try builtin.expect(crypto.utils.timingSafeEql(@Vector(100, u8), v1, v3));
}
fn testTimingSafeCompare() !void {
    var a: [32]u8 = .{10} ** 32;
    var b: [32]u8 = .{10} ** 32;
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .eq);
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .eq);
    a[31] = 1;
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .lt);
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .lt);
    a[0] = 20;
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .gt);
    try builtin.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .lt);
}
fn testTimingSafeAddSub() !void {
    var a: [32]u8 = undefined;
    var b: [32]u8 = undefined;
    var c: [32]u8 = undefined;
    const zero: [32]u8 = .{0} ** 32;
    var iterations: usize = 100;
    while (iterations != 0) : (iterations -%= 1) {
        crypto.random.bytes(&a);
        crypto.random.bytes(&b);
        const endian = if (iterations % 2 == 0) builtin.Endian.Big else builtin.Endian.Little;
        _ = crypto.utils.timingSafeSub(u8, &a, &b, &c, endian);
        _ = crypto.utils.timingSafeAdd(u8, &c, &b, &c, endian);
        try testing.expectEqualMany(u8, &c, &a);
        const borrow: bool = crypto.utils.timingSafeSub(u8, &c, &a, &c, endian);
        try testing.expectEqualMany(u8, &c, &zero);
        try builtin.expectEqual(bool, borrow, false);
    }
}
fn testSecureZero() !void {
    var a: [8]u8 = [1]u8{0xfe} ** 8;
    var b: [8]u8 = [1]u8{0xfe} ** 8;
    @memset(a[0..], 0);
    crypto.utils.secureZero(u8, b[0..]);
    try testing.expectEqualMany(u8, a[0..], b[0..]);
}
pub fn utilsTestMain() !void {
    try testTimingSafeEql();
    try testTimingSafeEqlVectors();
    try testTimingSafeCompare();
    try testTimingSafeAddSub();
}
pub const main = utilsTestMain;
