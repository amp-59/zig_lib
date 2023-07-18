const zl = @import("../../zig_lib.zig");
const fmt = zig_lib.fmt;
const mem = zig_lib.mem;
const mach = zig_lib.mach;
const meta = zig_lib.meta;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
const htest = @import("./hash-test.zig").htest;
const tab = @import("./tab.zig");
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
fn testHkdfSha256(allocator: *mem.SimpleAllocator) !void {
    const ikm: [22]u8 = .{0x0b} ** 22;
    const salt: [13]u8 = .{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c };
    const context: [10]u8 = .{ 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9 };
    const prk: [crypto.auth.HkdfSha256.prk_len]u8 = crypto.auth.HkdfSha256.extract(&salt, &ikm);
    try htest.assertEqual(allocator, "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5", &prk);
    var out: [42]u8 = undefined;
    crypto.auth.HkdfSha256.expand(&out, &context, prk);
    try htest.assertEqual(allocator, "3cb25f25faacd57a90434f64d0362f2a2d2d0a90cf1a5a4c5db02d56ecc4c5bf34007208d5b887185865", &out);
    var hkdf: crypto.auth.HmacSha256 = crypto.auth.HkdfSha256.extractInit(&salt);
    hkdf.update(&ikm);
    var prk2: [crypto.auth.HkdfSha256.prk_len]u8 = undefined;
    hkdf.final(&prk2);
    try htest.assertEqual(allocator, "077709362c2e32df0ddc3f0dc47bba6390b6c73bb50f9c3122ec844ad7c2b3e5", &prk2);
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
fn testSipHashIterativeNonDivisibleUpdate() !void {
    var buf: [1024]u8 = undefined;
    for (&buf, 0..) |*e, i| {
        e.* = @as(u8, @truncate(i));
    }
    const key: []const u8 = "0x128dad08f12307";
    const Siphash64 = crypto.auth.GenericSipHash64(2, 4);
    var end: usize = 9;
    while (end < buf.len) : (end +%= 9) {
        const non_iterative_hash: u64 = Siphash64.toInt(buf[0..end], key[0..]);
        var siphash: Siphash64 = Siphash64.init(key);
        var idx: usize = 0;
        while (idx != end) : (idx +%= 7) {
            siphash.update(buf[idx..@min(idx +% 7, end)]);
        }
        const iterative_hash: u64 = siphash.finalInt();
        try builtin.expectEqual(u64, iterative_hash, non_iterative_hash);
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
fn testAegis128LTestVector1(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis128L.key_len]u8 = [_]u8{ 0x10, 0x01 } ++ [_]u8{0x00} ** 14;
    const nonce: [crypto.auth.Aegis128L.nonce_len]u8 = [_]u8{ 0x10, 0x00, 0x02 } ++ [_]u8{0x00} ** 13;
    const bytes: [8]u8 = .{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07 };
    const msg: [32]u8 = .{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f };
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis128L.tag_len]u8 = undefined;
    crypto.auth.Aegis128L.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis128L.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "79d94593d8c2119d7e8fd9b8fc77845c5c077a05b2528b6ac54b563aed8efe84", &cipher);
    try htest.assertEqual(allocator, "cc6f3372f6aa1bb82388d695c3962d9a", &tag);
    cipher[0] +%= 1;
    try builtin.expect(error.AuthenticationFailed == crypto.auth.Aegis128L.decrypt(&out, &cipher, tag, &bytes, nonce, key));
    cipher[0] -%= 1;
    tag[0] +%= 1;
    try builtin.expect(error.AuthenticationFailed == crypto.auth.Aegis128L.decrypt(&out, &cipher, tag, &bytes, nonce, key));
}
fn testAegis128LTestVector2(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis128L.key_len]u8 = [_]u8{0x00} ** 16;
    const nonce: [crypto.auth.Aegis128L.nonce_len]u8 = [_]u8{0x00} ** 16;
    const bytes: [0]u8 = [0]u8{};
    const msg: [16]u8 = [1]u8{0} ** 16;
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis128L.tag_len]u8 = undefined;
    crypto.auth.Aegis128L.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis128L.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "41de9000a7b5e40e2d68bb64d99ebb19", &cipher);
    try htest.assertEqual(allocator, "f4d997cc9b94227ada4fe4165422b1c8", &tag);
}
fn testAegis128LTestVector3(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis128L.key_len]u8 = [_]u8{0x00} ** 16;
    const nonce: [crypto.auth.Aegis128L.nonce_len]u8 = [_]u8{0x00} ** 16;
    const bytes: [0]u8 = [0]u8{};
    const msg: [0]u8 = [0]u8{};
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis128L.tag_len]u8 = undefined;
    crypto.auth.Aegis128L.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis128L.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "83cc600dc4e3e7e62d4055826174f149", &tag);
}
fn testAegis128LMac(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis128LMac.key_len]u8 = [1]u8{0} ** crypto.auth.Aegis128LMac.key_len;
    var msg: [64]u8 = undefined;
    for (&msg, 0..) |*byte, i| {
        byte.* = @as(u8, @truncate(i));
    }
    const st_init: crypto.auth.Aegis128LMac = crypto.auth.Aegis128LMac.init(&key);
    var st = st_init;
    var tag: [crypto.auth.Aegis128LMac.mac_len]u8 = undefined;
    st.update(msg[0..32]);
    st.update(msg[32..]);
    st.final(&tag);
    try htest.assertEqual(allocator, "f8840849602738d81037cbaa0f584ea95759e2ac60263ce77346bcdc79fe4319", &tag);
    st = st_init;
    st.update(msg[0..31]);
    st.update(msg[31..]);
    st.final(&tag);
    try htest.assertEqual(allocator, "f8840849602738d81037cbaa0f584ea95759e2ac60263ce77346bcdc79fe4319", &tag);
    st = st_init;
    st.update(msg[0..14]);
    st.update(msg[14..30]);
    st.update(msg[30..]);
    st.final(&tag);
    try htest.assertEqual(allocator, "f8840849602738d81037cbaa0f584ea95759e2ac60263ce77346bcdc79fe4319", &tag);
    var empty: [0]u8 = undefined;
    const nonce = [_]u8{0x00} ** crypto.auth.Aegis128L_256.nonce_len;
    crypto.auth.Aegis128L_256.encrypt(&empty, &tag, &empty, &msg, nonce, key);
    try htest.assertEqual(allocator, "f8840849602738d81037cbaa0f584ea95759e2ac60263ce77346bcdc79fe4319", &tag);
}
fn testAegis256TestVector1(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis256.key_len]u8 = [2]u8{ 16, 1 } ++ [1]u8{0} ** 30;
    const nonce: [crypto.auth.Aegis256.nonce_len]u8 = [3]u8{ 16, 0, 2 } ++ [1]u8{0} ** 29;
    const bytes: [8]u8 = .{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07 };
    const msg: [32]u8 = .{ 0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f, 0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f };
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis256.tag_len]u8 = undefined;
    crypto.auth.Aegis256.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis256.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "f373079ed84b2709faee373584585d60accd191db310ef5d8b11833df9dec711", &cipher);
    try htest.assertEqual(allocator, "8d86f91ee606e9ff26a01b64ccbdd91d", &tag);
    cipher[0] +%= 1;
    try builtin.expect(error.AuthenticationFailed == crypto.auth.Aegis256.decrypt(&out, &cipher, tag, &bytes, nonce, key));
    cipher[0] -%= 1;
    tag[0] +%= 1;
    try builtin.expect(error.AuthenticationFailed == crypto.auth.Aegis256.decrypt(&out, &cipher, tag, &bytes, nonce, key));
}
fn testAegis256TestVector2(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis256.key_len]u8 = [1]u8{0} ** 32;
    const nonce: [crypto.auth.Aegis256.nonce_len]u8 = [1]u8{0} ** 32;
    const bytes: [0]u8 = [0]u8{};
    const msg: [16]u8 = [1]u8{0} ** 16;
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis256.tag_len]u8 = undefined;
    crypto.auth.Aegis256.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis256.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "b98f03a947807713d75a4fff9fc277a6", &cipher);
    try htest.assertEqual(allocator, "478f3b50dc478ef7d5cf2d0f7cc13180", &tag);
}
fn testAegis256TestVector3(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.auth.Aegis256.key_len]u8 = [1]u8{0} ** 32;
    const nonce: [crypto.auth.Aegis256.nonce_len]u8 = [1]u8{0} ** 32;
    const bytes: [0]u8 = [0]u8{};
    const msg: [0]u8 = [0]u8{};
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.auth.Aegis256.tag_len]u8 = undefined;
    crypto.auth.Aegis256.encrypt(&cipher, &tag, &msg, &bytes, nonce, key);
    try crypto.auth.Aegis256.decrypt(&out, &cipher, tag, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &msg, &out);
    try htest.assertEqual(allocator, "f7a0878f68bd083e8065354071fc27c3", &tag);
}
fn authTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    try testHmacMd5(&allocator);
    try testHmacSha256(&allocator);
    try testHkdfSha256(&allocator);
    try testSiphash6424Sanity();
    try testSiphash12824Sanity();
    try testCmacAes128Example1Len0();
    try testCmacAes128Example2Len16();
    try testCmacAes128Example3Len40();
    try testCmacAes128Example4Len64();
    try testAegis128LTestVector1(&allocator);
    try testAegis128LTestVector2(&allocator);
    try testAegis128LTestVector3(&allocator);
    try testAegis128LMac(&allocator);
    try testAegis256TestVector1(&allocator);
    try testAegis256TestVector2(&allocator);
    try testAegis256TestVector3(&allocator);
}
pub const main = authTestMain;
