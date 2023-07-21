const zl = @import("../../zig_lib.zig");
const math = zl.math;
const proc = zl.proc;
const debug = zl.debug;
const crypto = zl.crypto;
const testing = zl.testing;
const builtin = zl.builtin;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
fn testTimingSafeEql() !void {
    var a: [100]u8 = undefined;
    var b: [100]u8 = undefined;
    crypto.utils.bytes(a[0..]);
    crypto.utils.bytes(b[0..]);
    try debug.expect(!crypto.utils.timingSafeEql([100]u8, a, b));
    a = b;
    try debug.expect(crypto.utils.timingSafeEql([100]u8, a, b));
}
fn testTimingSafeEqlVectors() !void {
    var a: [100]u8 = undefined;
    var b: [100]u8 = undefined;
    crypto.utils.bytes(a[0..]);
    crypto.utils.bytes(b[0..]);
    const v1: @Vector(100, u8) = a;
    const v2: @Vector(100, u8) = b;
    try debug.expect(!crypto.utils.timingSafeEql(@Vector(100, u8), v1, v2));
    const v3: @Vector(100, u8) = a;
    try debug.expect(crypto.utils.timingSafeEql(@Vector(100, u8), v1, v3));
}
fn testTimingSafeCompare() !void {
    var a: [32]u8 = .{10} ** 32;
    var b: [32]u8 = .{10} ** 32;
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .eq);
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .eq);
    a[31] = 1;
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .lt);
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .lt);
    a[0] = 20;
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Big), .gt);
    try debug.expectEqual(math.Order, crypto.utils.timingSafeCompare(u8, &a, &b, .Little), .lt);
}
fn testTimingSafeAddSub() !void {
    var a: [32]u8 = undefined;
    var b: [32]u8 = undefined;
    var c: [32]u8 = undefined;
    const zero: [32]u8 = .{0} ** 32;
    var iterations: usize = 100;
    while (iterations != 0) : (iterations -%= 1) {
        crypto.utils.bytes(&a);
        crypto.utils.bytes(&b);
        const endian = if (iterations % 2 == 0) builtin.Endian.Big else builtin.Endian.Little;
        _ = crypto.utils.timingSafeSub(u8, &a, &b, &c, endian);
        _ = crypto.utils.timingSafeAdd(u8, &c, &b, &c, endian);
        try testing.expectEqualMany(u8, &c, &a);
        const borrow: bool = crypto.utils.timingSafeSub(u8, &c, &a, &c, endian);
        try testing.expectEqualMany(u8, &c, &zero);
        try debug.expectEqual(bool, borrow, false);
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
