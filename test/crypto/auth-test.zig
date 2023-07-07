const zig_lib = @import("../../zig_lib.zig");
const fmt = zig_lib.fmt;
const mem = zig_lib.mem;
const mach = zig_lib.mach;
const meta = zig_lib.meta;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
const tab = @import("./tab.zig");
const htest = @import("./hash-test.zig").htest;

fn testHmacMd5(allocator: *mem.SimpleAllocator) !void {
    var out: [crypto.auth.HmacMd5.mac_len]u8 = undefined;
    crypto.auth.HmacMd5.create(out[0..], "", "");
    try htest.assertEqual(allocator, "74e6f7298a9c2d168935f58c001bad88", out[0..]);
    crypto.auth.HmacMd5.create(out[0..], "The quick brown fox jumps over the lazy dog", "key");
    try htest.assertEqual(allocator, "80070713463e7749b90c2dc24911e275", out[0..]);
}
fn testHmacSha256(allocator: *mem.SimpleAllocator) !void {
    var out: [crypto.auth.HmacSha256.mac_len]u8 = undefined;
    crypto.auth.HmacSha256.create(out[0..], "", "");
    try htest.assertEqual(allocator, "b613679a0814d9ec772f95d778c35fc5ff1697c493715653c6c712144292c5ad", out[0..]);
    crypto.auth.HmacSha256.create(out[0..], "The quick brown fox jumps over the lazy dog", "key");
    try htest.assertEqual(allocator, "f7bc83f430538424b13298e6aa6fb143ef4d59a14946175997479dbc2d1a3cd8", out[0..]);
}
fn testSiphash6424Sanity() !void {
    const SipHash64 = crypto.auth.GenericSipHash64(2, 4);
    var buffer: [64]u8 = undefined;
    for (tab.sip_6424_vectors, 0..) |vector, i| {
        buffer[i] = @as(u8, @intCast(i));
        var out: [SipHash64.mac_len]u8 = undefined;
        SipHash64.create(&out, buffer[0..i], tab.sip_test_key);
        try builtin.expectEqual(@TypeOf(out), out, vector);
    }
}
fn testSiphash12824Sanity() !void {
    const SipHash128 = crypto.auth.GenericSipHash128(2, 4);
    var buffer: [64]u8 = undefined;
    for (tab.sip_12824_vectors, 0..) |vector, i| {
        buffer[i] = @as(u8, @intCast(i));
        var out: [SipHash128.mac_len]u8 = undefined;
        SipHash128.create(&out, buffer[0..i], tab.sip_test_key);
        try builtin.expectEqual(@TypeOf(out), out, vector);
    }
}
fn testCmacAes128Example1Len0() !void {
    const key: [16]u8 = .{
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
    };
    var msg: [0]u8 = undefined;
    const exp: [16]u8 = .{
        0xbb, 0x1d, 0x69, 0x29, 0xe9, 0x59, 0x37, 0x28, 0x7f, 0xa3, 0x7d, 0x12, 0x9b, 0x75, 0x67, 0x46,
    };
    var out: [crypto.auth.CmacAes128.mac_len]u8 = undefined;
    crypto.auth.CmacAes128.create(&out, &msg, &key);
    try testing.expectEqualMany(u8, &out, &exp);
}
fn testCmacAes128Example2Len16() !void {
    const key: [16]u8 = .{
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
    };
    const msg: [16]u8 = .{
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
    };
    const exp: [16]u8 = .{
        0x07, 0x0a, 0x16, 0xb4, 0x6b, 0x4d, 0x41, 0x44, 0xf7, 0x9b, 0xdd, 0x9d, 0xd0, 0x4a, 0x28, 0x7c,
    };
    var out: [crypto.auth.CmacAes128.mac_len]u8 = undefined;
    crypto.auth.CmacAes128.create(&out, &msg, &key);
    try testing.expectEqualMany(u8, &out, &exp);
}
fn testCmacAes128Example3Len40() !void {
    const key: [16]u8 = .{
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
    };
    const msg: [40]u8 = .{
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
        0xae, 0x2d, 0x8a, 0x57, 0x1e, 0x03, 0xac, 0x9c, 0x9e, 0xb7, 0x6f, 0xac, 0x45, 0xaf, 0x8e, 0x51,
        0x30, 0xc8, 0x1c, 0x46, 0xa3, 0x5c, 0xe4, 0x11,
    };
    const exp: [16]u8 = .{
        0xdf, 0xa6, 0x67, 0x47, 0xde, 0x9a, 0xe6, 0x30, 0x30, 0xca, 0x32, 0x61, 0x14, 0x97, 0xc8, 0x27,
    };
    var out: [crypto.auth.CmacAes128.mac_len]u8 = undefined;
    crypto.auth.CmacAes128.create(&out, &msg, &key);
    try testing.expectEqualMany(u8, &out, &exp);
}
fn testCmacAes128Example4Len64() !void {
    const key: [16]u8 = [16]u8{
        0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c,
    };
    const msg: [64]u8 = .{
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
        0xae, 0x2d, 0x8a, 0x57, 0x1e, 0x03, 0xac, 0x9c, 0x9e, 0xb7, 0x6f, 0xac, 0x45, 0xaf, 0x8e, 0x51,
        0x30, 0xc8, 0x1c, 0x46, 0xa3, 0x5c, 0xe4, 0x11, 0xe5, 0xfb, 0xc1, 0x19, 0x1a, 0x0a, 0x52, 0xef,
        0xf6, 0x9f, 0x24, 0x45, 0xdf, 0x4f, 0x9b, 0x17, 0xad, 0x2b, 0x41, 0x7b, 0xe6, 0x6c, 0x37, 0x10,
    };
    const exp: [16]u8 = .{
        0x51, 0xf0, 0xbe, 0xbf, 0x7e, 0x3b, 0x9d, 0x92, 0xfc, 0x49, 0x74, 0x17, 0x79, 0x36, 0x3c, 0xfe,
    };
    var out: [crypto.auth.CmacAes128.mac_len]u8 = undefined;
    crypto.auth.CmacAes128.create(&out, &msg, &key);
    try testing.expectEqualMany(u8, &out, &exp);
}

fn authTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    try testHmacMd5(&allocator);
    try testHmacSha256(&allocator);
    try testSiphash6424Sanity();
    try testSiphash12824Sanity();
    try testCmacAes128Example1Len0();
    try testCmacAes128Example2Len16();
    try testCmacAes128Example3Len40();
    try testCmacAes128Example4Len64();
}
pub const main = authTestMain;
