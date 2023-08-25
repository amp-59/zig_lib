const zl = @import("../../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const crypto = zl.crypto;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
const htest = @import("./hash.zig").htest;
const tab = @import("./tab.zig");

const sunscreen: []const u8 = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";

fn testChacha20AEADAPI() !void {
    const aeads = [_]type{ crypto.aead.ChaCha20Poly1305, crypto.aead.XChaCha20Poly1305 };
    const bytes: []const u8 = "Additional data";
    inline for (aeads) |aead| {
        const key: [aead.key_len]u8 = [1]u8{69} ** aead.key_len;
        const nonce: [aead.nonce_len]u8 = [1]u8{42} ** aead.nonce_len;
        var cipher: [sunscreen.len]u8 = undefined;
        var tag: [aead.tag_len]u8 = undefined;
        var out: [sunscreen.len]u8 = undefined;
        aead.encrypt(&cipher, &tag, sunscreen, bytes, nonce, key);
        try aead.decrypt(&out, &cipher, tag, bytes, nonce, key);
        try testing.expectEqualMany(u8, &out, sunscreen);
        cipher[0] +%= 1;
        try testing.expectError(error.AuthenticationFailed, aead.decrypt(&out, &cipher, tag, bytes, nonce, key));
    }
}
fn testChacha20TestVectorSunscreen() !void {
    const expected_output: [114]u8 = .{
        0x6e, 0x2e, 0x35, 0x9a, 0x25, 0x68, 0xf9, 0x80,
        0x41, 0xba, 0x07, 0x28, 0xdd, 0x0d, 0x69, 0x81,
        0xe9, 0x7e, 0x7a, 0xec, 0x1d, 0x43, 0x60, 0xc2,
        0x0a, 0x27, 0xaf, 0xcc, 0xfd, 0x9f, 0xae, 0x0b,
        0xf9, 0x1b, 0x65, 0xc5, 0x52, 0x47, 0x33, 0xab,
        0x8f, 0x59, 0x3d, 0xab, 0xcd, 0x62, 0xb3, 0x57,
        0x16, 0x39, 0xd6, 0x24, 0xe6, 0x51, 0x52, 0xab,
        0x8f, 0x53, 0x0c, 0x35, 0x9f, 0x08, 0x61, 0xd8,
        0x07, 0xca, 0x0d, 0xbf, 0x50, 0x0d, 0x6a, 0x61,
        0x56, 0xa3, 0x8e, 0x08, 0x8a, 0x22, 0xb6, 0x5e,
        0x52, 0xbc, 0x51, 0x4d, 0x16, 0xcc, 0xf8, 0x06,
        0x81, 0x8c, 0xe9, 0x1a, 0xb7, 0x79, 0x37, 0x36,
        0x5a, 0xf9, 0x0b, 0xbf, 0x74, 0xa3, 0x5b, 0xe6,
        0xb4, 0x0b, 0x8e, 0xed, 0xf2, 0x78, 0x5e, 0x42,
        0x87, 0x4d,
    };
    var out1: [114]u8 = undefined;
    var out2: [114]u8 = undefined;
    const key: [32]u8 = .{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    };
    const nonce: [12]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0x4a, 0, 0, 0, 0 };
    crypto.aead.ChaCha20IETF.xor(&out1, sunscreen, 1, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &out1);
    crypto.aead.ChaCha20IETF.xor(&out2, &out1, 1, key, nonce);
    try testing.expect(mem.order(u8, sunscreen, &out2) == .eq);
}
fn testChacha20TestVector1() !void {
    const expected_output: [64]u8 = .{
        0x76, 0xb8, 0xe0, 0xad, 0xa0, 0xf1, 0x3d, 0x90,
        0x40, 0x5d, 0x6a, 0xe5, 0x53, 0x86, 0xbd, 0x28,
        0xbd, 0xd2, 0x19, 0xb8, 0xa0, 0x8d, 0xed, 0x1a,
        0xa8, 0x36, 0xef, 0xcc, 0x8b, 0x77, 0x0d, 0xc7,
        0xda, 0x41, 0x59, 0x7c, 0x51, 0x57, 0x48, 0x8d,
        0x77, 0x24, 0xe0, 0x3f, 0xb8, 0xd8, 0x4a, 0x37,
        0x6a, 0x43, 0xb8, 0xf4, 0x15, 0x18, 0xa1, 0x1c,
        0xc3, 0x87, 0xb6, 0x69, 0xb2, 0xee, 0x65, 0x86,
    };
    const msg: [64]u8 = [1]u8{0} ** 64;
    var out: [64]u8 = undefined;
    const key: [32]u8 = [1]u8{0} ** 32;
    const nonce: [8]u8 = [1]u8{0} ** 8;
    crypto.aead.ChaCha20With64BitNonce.xor(&out, &msg, 0, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &out);
}
fn testChacha20TestVector2() !void {
    const expected_output: [64]u8 = .{
        0x45, 0x40, 0xf0, 0x5a, 0x9f, 0x1f, 0xb2, 0x96,
        0xd7, 0x73, 0x6e, 0x7b, 0x20, 0x8e, 0x3c, 0x96,
        0xeb, 0x4f, 0xe1, 0x83, 0x46, 0x88, 0xd2, 0x60,
        0x4f, 0x45, 0x09, 0x52, 0xed, 0x43, 0x2d, 0x41,
        0xbb, 0xe2, 0xa0, 0xb6, 0xea, 0x75, 0x66, 0xd2,
        0xa5, 0xd1, 0xe7, 0xe2, 0x0d, 0x42, 0xaf, 0x2c,
        0x53, 0xd7, 0x92, 0xb1, 0xc4, 0x3f, 0xea, 0x81,
        0x7e, 0x9a, 0xd2, 0x75, 0xae, 0x54, 0x69, 0x63,
    };
    const msg: [64]u8 = [1]u8{0} ** 64;
    var result: [64]u8 = undefined;
    const key: [32]u8 = .{
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 1,
    };
    const nonce: [8]u8 = [1]u8{0} ** 8;
    crypto.aead.ChaCha20With64BitNonce.xor(&result, &msg, 0, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &result);
}
fn testChacha20TestVector3() !void {
    const expected_output: [60]u8 = .{
        0xde, 0x9c, 0xba, 0x7b, 0xf3, 0xd6, 0x9e, 0xf5,
        0xe7, 0x86, 0xdc, 0x63, 0x97, 0x3f, 0x65, 0x3a,
        0x0b, 0x49, 0xe0, 0x15, 0xad, 0xbf, 0xf7, 0x13,
        0x4f, 0xcb, 0x7d, 0xf1, 0x37, 0x82, 0x10, 0x31,
        0xe8, 0x5a, 0x05, 0x02, 0x78, 0xa7, 0x08, 0x45,
        0x27, 0x21, 0x4f, 0x73, 0xef, 0xc7, 0xfa, 0x5b,
        0x52, 0x77, 0x06, 0x2e, 0xb7, 0xa0, 0x43, 0x3e,
        0x44, 0x5f, 0x41, 0xe3,
    };
    const msg: [60]u8 = [1]u8{0} ** 60;
    var result: [60]u8 = undefined;
    const key: [32]u8 = [1]u8{0} ** 32;
    const nonce: [8]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 1 };
    crypto.aead.ChaCha20With64BitNonce.xor(&result, &msg, 0, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &result);
}
fn testChacha20TestVector4() !void {
    const expected_output: [64]u8 = .{
        0xef, 0x3f, 0xdf, 0xd6, 0xc6, 0x15, 0x78, 0xfb,
        0xf5, 0xcf, 0x35, 0xbd, 0x3d, 0xd3, 0x3b, 0x80,
        0x09, 0x63, 0x16, 0x34, 0xd2, 0x1e, 0x42, 0xac,
        0x33, 0x96, 0x0b, 0xd1, 0x38, 0xe5, 0x0d, 0x32,
        0x11, 0x1e, 0x4c, 0xaf, 0x23, 0x7e, 0xe5, 0x3c,
        0xa8, 0xad, 0x64, 0x26, 0x19, 0x4a, 0x88, 0x54,
        0x5d, 0xdc, 0x49, 0x7a, 0x0b, 0x46, 0x6e, 0x7d,
        0x6b, 0xbd, 0xb0, 0x04, 0x1b, 0x2f, 0x58, 0x6b,
    };
    const msg: [64]u8 = [1]u8{0} ** 64;
    var result: [64]u8 = undefined;
    const key: [32]u8 = .{
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0, 0, 0, 0, 0, 0, 0,
    };
    const nonce: [8]u8 = .{ 1, 0, 0, 0, 0, 0, 0, 0 };
    crypto.aead.ChaCha20With64BitNonce.xor(&result, &msg, 0, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &result);
}
fn testChacha20TestVector5() !void {
    const expected_output: [256]u8 = .{
        0xf7, 0x98, 0xa1, 0x89, 0xf1, 0x95, 0xe6, 0x69,
        0x82, 0x10, 0x5f, 0xfb, 0x64, 0x0b, 0xb7, 0x75,
        0x7f, 0x57, 0x9d, 0xa3, 0x16, 0x02, 0xfc, 0x93,
        0xec, 0x01, 0xac, 0x56, 0xf8, 0x5a, 0xc3, 0xc1,
        0x34, 0xa4, 0x54, 0x7b, 0x73, 0x3b, 0x46, 0x41,
        0x30, 0x42, 0xc9, 0x44, 0x00, 0x49, 0x17, 0x69,
        0x05, 0xd3, 0xbe, 0x59, 0xea, 0x1c, 0x53, 0xf1,
        0x59, 0x16, 0x15, 0x5c, 0x2b, 0xe8, 0x24, 0x1a,
        0x38, 0x00, 0x8b, 0x9a, 0x26, 0xbc, 0x35, 0x94,
        0x1e, 0x24, 0x44, 0x17, 0x7c, 0x8a, 0xde, 0x66,
        0x89, 0xde, 0x95, 0x26, 0x49, 0x86, 0xd9, 0x58,
        0x89, 0xfb, 0x60, 0xe8, 0x46, 0x29, 0xc9, 0xbd,
        0x9a, 0x5a, 0xcb, 0x1c, 0xc1, 0x18, 0xbe, 0x56,
        0x3e, 0xb9, 0xb3, 0xa4, 0xa4, 0x72, 0xf8, 0x2e,
        0x09, 0xa7, 0xe7, 0x78, 0x49, 0x2b, 0x56, 0x2e,
        0xf7, 0x13, 0x0e, 0x88, 0xdf, 0xe0, 0x31, 0xc7,
        0x9d, 0xb9, 0xd4, 0xf7, 0xc7, 0xa8, 0x99, 0x15,
        0x1b, 0x9a, 0x47, 0x50, 0x32, 0xb6, 0x3f, 0xc3,
        0x85, 0x24, 0x5f, 0xe0, 0x54, 0xe3, 0xdd, 0x5a,
        0x97, 0xa5, 0xf5, 0x76, 0xfe, 0x06, 0x40, 0x25,
        0xd3, 0xce, 0x04, 0x2c, 0x56, 0x6a, 0xb2, 0xc5,
        0x07, 0xb1, 0x38, 0xdb, 0x85, 0x3e, 0x3d, 0x69,
        0x59, 0x66, 0x09, 0x96, 0x54, 0x6c, 0xc9, 0xc4,
        0xa6, 0xea, 0xfd, 0xc7, 0x77, 0xc0, 0x40, 0xd7,
        0x0e, 0xaf, 0x46, 0xf7, 0x6d, 0xad, 0x39, 0x79,
        0xe5, 0xc5, 0x36, 0x0c, 0x33, 0x17, 0x16, 0x6a,
        0x1c, 0x89, 0x4c, 0x94, 0xa3, 0x71, 0x87, 0x6a,
        0x94, 0xdf, 0x76, 0x28, 0xfe, 0x4e, 0xaa, 0xf2,
        0xcc, 0xb2, 0x7d, 0x5a, 0xaa, 0xe0, 0xad, 0x7a,
        0xd0, 0xf9, 0xd4, 0xb6, 0xad, 0x3b, 0x54, 0x09,
        0x87, 0x46, 0xd4, 0x52, 0x4d, 0x38, 0x40, 0x7a,
        0x6d, 0xeb, 0x3a, 0xb7, 0x8f, 0xab, 0x78, 0xc9,
    };
    const msg: [256]u8 = [1]u8{0} ** 256;
    var result: [256]u8 = undefined;
    const key: [32]u8 = .{
        0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07,
        0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
        0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17,
        0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
    };
    const nonce: [8]u8 = .{ 0, 1, 2, 3, 4, 5, 6, 7 };
    crypto.aead.ChaCha20With64BitNonce.xor(&result, &msg, 0, key, nonce);
    try testing.expectEqualMany(u8, &expected_output, &result);
}
fn testXchacha201() !void {
    const key: [32]u8 = [1]u8{69} ** 32;
    const nonce: [24]u8 = [1]u8{42} ** 24;
    var cipher: [sunscreen.len]u8 = undefined;
    crypto.aead.XChaCha20IETF.xor(&cipher, sunscreen, 0, key, nonce);
    var buf: [2 *% cipher.len]u8 = undefined;
    try testing.expectEqualMany(u8, fmt.bytesToHex(&buf, &cipher), "e0a1bcf939654afdbdc1746ec49832647c19d891f0d1a81fc0c1703b4514bdea584b512f6908c2c5e9dd18d5cbc1805de5803fe3b9ca5f193fb8359e91fab0c3bb40309a292eb1cf49685c65c4a3adf4f11db0cd2b6b67fbc174bc2e860e8f769fd3565bbfad1c845e05a0fed9be167c240d");
}
fn testXchacha202() !void {
    const key: [32]u8 = [1]u8{69} ** 32;
    const nonce: [24]u8 = [1]u8{42} ** 24;
    const bytes: []const u8 = "Additional data";
    var cipher: [sunscreen.len]u8 = undefined;
    var tag: [crypto.aead.XChaCha20Poly1305.tag_len]u8 = undefined;
    crypto.aead.XChaCha20Poly1305.encrypt(&cipher, &tag, sunscreen, bytes, nonce, key);
    var out: [sunscreen.len]u8 = undefined;
    try crypto.aead.XChaCha20Poly1305.decrypt(&out, &cipher, tag, bytes, nonce, key);
    var buf: [2 *% (cipher.len +% tag.len)]u8 = undefined;
    try testing.expectEqualMany(u8, fmt.bytesToHex(&buf, &cipher), "994d2dd32333f48e53650c02c7a2abb8e018b0836d7175aec779f52e961780768f815c58f1aa52d211498db89b9216763f569c9433a6bbfcefb4d4a49387a4c5207fbb3b5a92b5941294df30588c6740d39dc16fa1f0e634f7246cf7cdcb978e44347d89381b7a74eb7084f754b90bde9aaf");
    try testing.expectEqualMany(u8, fmt.bytesToHex(&buf, &tag), "5a94b8f2a85efd0b50692ae2d425e234");
    try testing.expectEqualMany(u8, &out, sunscreen);
    cipher[0] +%= 1;
    try testing.expectError(error.AuthenticationFailed, crypto.aead.XChaCha20Poly1305.decrypt(&out, &cipher, tag, sunscreen, nonce, key));
}
fn testSeal1() !void {
    const msg: []const u8 = "";
    const bytes: []const u8 = "";
    const key: [32]u8 = .{
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    };
    const nonce: [12]u8 = .{ 0x7, 0x0, 0x0, 0x0, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47 };
    const expected_output: [16]u8 = .{ 0xa0, 0x78, 0x4d, 0x7a, 0x47, 0x16, 0xf3, 0xfe, 0xb4, 0xf6, 0x4e, 0x7f, 0x4b, 0x39, 0xbf, 0x4 };
    var out: [expected_output.len]u8 = undefined;
    crypto.aead.ChaCha20Poly1305.encrypt(out[0..msg.len], out[msg.len..], msg, bytes, nonce, key);
    try testing.expectEqualMany(u8, expected_output[0..], out[0..]);
}
fn testSeal2() !void {
    const msg: [114]u8 = .{
        0x4c, 0x61, 0x64, 0x69, 0x65, 0x73, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x47, 0x65, 0x6e, 0x74, 0x6c,
        0x65, 0x6d, 0x65, 0x6e, 0x20, 0x6f, 0x66, 0x20, 0x74, 0x68, 0x65, 0x20, 0x63, 0x6c, 0x61, 0x73,
        0x73, 0x20, 0x6f, 0x66, 0x20, 0x27, 0x39, 0x39, 0x3a, 0x20, 0x49, 0x66, 0x20, 0x49, 0x20, 0x63,
        0x6f, 0x75, 0x6c, 0x64, 0x20, 0x6f, 0x66, 0x66, 0x65, 0x72, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x6f,
        0x6e, 0x6c, 0x79, 0x20, 0x6f, 0x6e, 0x65, 0x20, 0x74, 0x69, 0x70, 0x20, 0x66, 0x6f, 0x72, 0x20,
        0x74, 0x68, 0x65, 0x20, 0x66, 0x75, 0x74, 0x75, 0x72, 0x65, 0x2c, 0x20, 0x73, 0x75, 0x6e, 0x73,
        0x63, 0x72, 0x65, 0x65, 0x6e, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62, 0x65, 0x20, 0x69,
        0x74, 0x2e,
    };
    const bytes: [12]u8 = .{ 0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7 };
    const key: [32]u8 = .{
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    };
    const nonce: [12]u8 = .{ 0x7, 0x0, 0x0, 0x0, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47 };
    const expected_output: [130]u8 = .{
        0xd3, 0x1a, 0x8d, 0x34, 0x64, 0x8e, 0x60, 0xdb, 0x7b, 0x86, 0xaf, 0xbc, 0x53, 0xef, 0x7e, 0xc2,
        0xa4, 0xad, 0xed, 0x51, 0x29, 0x6e, 0x8,  0xfe, 0xa9, 0xe2, 0xb5, 0xa7, 0x36, 0xee, 0x62, 0xd6,
        0x3d, 0xbe, 0xa4, 0x5e, 0x8c, 0xa9, 0x67, 0x12, 0x82, 0xfa, 0xfb, 0x69, 0xda, 0x92, 0x72, 0x8b,
        0x1a, 0x71, 0xde, 0xa,  0x9e, 0x6,  0xb,  0x29, 0x5,  0xd6, 0xa5, 0xb6, 0x7e, 0xcd, 0x3b, 0x36,
        0x92, 0xdd, 0xbd, 0x7f, 0x2d, 0x77, 0x8b, 0x8c, 0x98, 0x3,  0xae, 0xe3, 0x28, 0x9,  0x1b, 0x58,
        0xfa, 0xb3, 0x24, 0xe4, 0xfa, 0xd6, 0x75, 0x94, 0x55, 0x85, 0x80, 0x8b, 0x48, 0x31, 0xd7, 0xbc,
        0x3f, 0xf4, 0xde, 0xf0, 0x8e, 0x4b, 0x7a, 0x9d, 0xe5, 0x76, 0xd2, 0x65, 0x86, 0xce, 0xc6, 0x4b,
        0x61, 0x16, 0x1a, 0xe1, 0xb,  0x59, 0x4f, 0x9,  0xe2, 0x6a, 0x7e, 0x90, 0x2e, 0xcb, 0xd0, 0x60,
        0x6,  0x91,
    };
    var out: [expected_output.len]u8 = undefined;
    crypto.aead.ChaCha20Poly1305.encrypt(out[0..msg.len], out[msg.len..], &msg, &bytes, nonce, key);
    try testing.expectEqualMany(u8, &expected_output, &out);
}
fn testOpen1() !void {
    const c: [16]u8 = .{ 0xa0, 0x78, 0x4d, 0x7a, 0x47, 0x16, 0xf3, 0xfe, 0xb4, 0xf6, 0x4e, 0x7f, 0x4b, 0x39, 0xbf, 0x4 };
    const bytes: []const u8 = "";
    const key: [32]u8 = .{
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    };
    const nonce = [12]u8{ 0x7, 0x0, 0x0, 0x0, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47 };
    const expected_output: []const u8 = "";
    var out: [expected_output.len]u8 = undefined;
    try crypto.aead.ChaCha20Poly1305.decrypt(&out, c[0..expected_output.len], c[expected_output.len..].*, bytes, nonce, key);
    try testing.expectEqualMany(u8, expected_output, &out);
}
fn testOpen2() !void {
    const cipher: [130]u8 = .{
        0xd3, 0x1a, 0x8d, 0x34, 0x64, 0x8e, 0x60, 0xdb, 0x7b, 0x86, 0xaf, 0xbc, 0x53, 0xef, 0x7e, 0xc2,
        0xa4, 0xad, 0xed, 0x51, 0x29, 0x6e, 0x8,  0xfe, 0xa9, 0xe2, 0xb5, 0xa7, 0x36, 0xee, 0x62, 0xd6,
        0x3d, 0xbe, 0xa4, 0x5e, 0x8c, 0xa9, 0x67, 0x12, 0x82, 0xfa, 0xfb, 0x69, 0xda, 0x92, 0x72, 0x8b,
        0x1a, 0x71, 0xde, 0xa,  0x9e, 0x6,  0xb,  0x29, 0x5,  0xd6, 0xa5, 0xb6, 0x7e, 0xcd, 0x3b, 0x36,
        0x92, 0xdd, 0xbd, 0x7f, 0x2d, 0x77, 0x8b, 0x8c, 0x98, 0x3,  0xae, 0xe3, 0x28, 0x9,  0x1b, 0x58,
        0xfa, 0xb3, 0x24, 0xe4, 0xfa, 0xd6, 0x75, 0x94, 0x55, 0x85, 0x80, 0x8b, 0x48, 0x31, 0xd7, 0xbc,
        0x3f, 0xf4, 0xde, 0xf0, 0x8e, 0x4b, 0x7a, 0x9d, 0xe5, 0x76, 0xd2, 0x65, 0x86, 0xce, 0xc6, 0x4b,
        0x61, 0x16, 0x1a, 0xe1, 0xb,  0x59, 0x4f, 0x9,  0xe2, 0x6a, 0x7e, 0x90, 0x2e, 0xcb, 0xd0, 0x60,
        0x6,  0x91,
    };
    const bytes: [12]u8 = .{ 0x50, 0x51, 0x52, 0x53, 0xc0, 0xc1, 0xc2, 0xc3, 0xc4, 0xc5, 0xc6, 0xc7 };
    const key: [32]u8 = .{
        0x80, 0x81, 0x82, 0x83, 0x84, 0x85, 0x86, 0x87, 0x88, 0x89, 0x8a, 0x8b, 0x8c, 0x8d, 0x8e, 0x8f,
        0x90, 0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0x9b, 0x9c, 0x9d, 0x9e, 0x9f,
    };
    const nonce: [12]u8 = .{ 0x7, 0x0, 0x0, 0x0, 0x40, 0x41, 0x42, 0x43, 0x44, 0x45, 0x46, 0x47 };
    const expected_output: [114]u8 = .{
        0x4c, 0x61, 0x64, 0x69, 0x65, 0x73, 0x20, 0x61, 0x6e, 0x64, 0x20, 0x47, 0x65, 0x6e, 0x74, 0x6c,
        0x65, 0x6d, 0x65, 0x6e, 0x20, 0x6f, 0x66, 0x20, 0x74, 0x68, 0x65, 0x20, 0x63, 0x6c, 0x61, 0x73,
        0x73, 0x20, 0x6f, 0x66, 0x20, 0x27, 0x39, 0x39, 0x3a, 0x20, 0x49, 0x66, 0x20, 0x49, 0x20, 0x63,
        0x6f, 0x75, 0x6c, 0x64, 0x20, 0x6f, 0x66, 0x66, 0x65, 0x72, 0x20, 0x79, 0x6f, 0x75, 0x20, 0x6f,
        0x6e, 0x6c, 0x79, 0x20, 0x6f, 0x6e, 0x65, 0x20, 0x74, 0x69, 0x70, 0x20, 0x66, 0x6f, 0x72, 0x20,
        0x74, 0x68, 0x65, 0x20, 0x66, 0x75, 0x74, 0x75, 0x72, 0x65, 0x2c, 0x20, 0x73, 0x75, 0x6e, 0x73,
        0x63, 0x72, 0x65, 0x65, 0x6e, 0x20, 0x77, 0x6f, 0x75, 0x6c, 0x64, 0x20, 0x62, 0x65, 0x20, 0x69,
        0x74, 0x2e,
    };
    var out: [expected_output.len]u8 = undefined;
    try crypto.aead.ChaCha20Poly1305.decrypt(&out, cipher[0..expected_output.len], cipher[expected_output.len..].*, &bytes, nonce, key);
    try testing.expectEqualMany(u8, expected_output[0..], &out);
    var bad_cipher = cipher;
    bad_cipher[0] ^= 1;
    try testing.expectError(
        error.AuthenticationFailed,
        crypto.aead.ChaCha20Poly1305.decrypt(&out, bad_cipher[0..out.len], bad_cipher[out.len..].*, &bytes, nonce, key),
    );
    var bad_bytes = bytes;
    bad_bytes[0] ^= 1;
    try testing.expectError(
        error.AuthenticationFailed,
        crypto.aead.ChaCha20Poly1305.decrypt(&out, cipher[0..out.len], cipher[out.len..].*, &bad_bytes, nonce, key),
    );
    var bad_key = key;
    bad_key[0] ^= 1;
    try testing.expectError(
        error.AuthenticationFailed,
        crypto.aead.ChaCha20Poly1305.decrypt(&out, cipher[0..out.len], cipher[out.len..].*, &bytes, nonce, bad_key),
    );
    var bad_nonce = nonce;
    bad_nonce[0] ^= 1;
    try testing.expectError(
        error.AuthenticationFailed,
        crypto.aead.ChaCha20Poly1305.decrypt(&out, cipher[0..out.len], cipher[out.len..].*, &bytes, bad_nonce, key),
    );
}
fn testAes256GcmEmptyMessageAndNoAssociatedData(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.aead.Aes256Gcm.key_len]u8 = [_]u8{0x69} ** crypto.aead.Aes256Gcm.key_len;
    const nonce: [crypto.aead.Aes256Gcm.nonce_len]u8 = [_]u8{0x42} ** crypto.aead.Aes256Gcm.nonce_len;
    const bytes: []const u8 = "";
    const msg: []const u8 = "";
    var cipher: [msg.len]u8 = undefined;
    var tag: [crypto.aead.Aes256Gcm.tag_len]u8 = undefined;
    crypto.aead.Aes256Gcm.encrypt(&cipher, &tag, msg, bytes, nonce, key);
    try htest.assertEqual(allocator, "6b6ff610a16fa4cd59f1fb7903154e92", &tag);
}
fn testAes256GcmAssociatedDataOnly(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.aead.Aes256Gcm.key_len]u8 = [_]u8{0x69} ** crypto.aead.Aes256Gcm.key_len;
    const nonce: [crypto.aead.Aes256Gcm.nonce_len]u8 = [_]u8{0x42} ** crypto.aead.Aes256Gcm.nonce_len;
    const msg: []const u8 = "";
    const bytes: []const u8 = "Test with associated data";
    var cipher: [msg.len]u8 = undefined;
    var tag: [crypto.aead.Aes256Gcm.tag_len]u8 = undefined;
    crypto.aead.Aes256Gcm.encrypt(&cipher, &tag, msg, bytes, nonce, key);
    try htest.assertEqual(allocator, "262ed164c2dfb26e080a9d108dd9dd4c", &tag);
}
fn testAes256GcmMessageOnly(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.aead.Aes256Gcm.key_len]u8 = [_]u8{0x69} ** crypto.aead.Aes256Gcm.key_len;
    const nonce: [crypto.aead.Aes256Gcm.nonce_len]u8 = [_]u8{0x42} ** crypto.aead.Aes256Gcm.nonce_len;
    const msg: []const u8 = "Test with message only";
    const bytes: []const u8 = "";
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.aead.Aes256Gcm.tag_len]u8 = undefined;
    crypto.aead.Aes256Gcm.encrypt(&cipher, &tag, msg, bytes, nonce, key);
    try crypto.aead.Aes256Gcm.decrypt(&out, &cipher, tag, bytes, nonce, key);
    try testing.expectEqualMany(u8, msg, &out);
    try htest.assertEqual(allocator, "5ca1642d90009fea33d01f78cf6eefaf01d539472f7c", &cipher);
    try htest.assertEqual(allocator, "07cd7fc9103e2f9e9bf2dfaa319caff4", &tag);
}
fn testAes256GcmMessageAndAssociatedData(allocator: *mem.SimpleAllocator) !void {
    const key: [crypto.aead.Aes256Gcm.key_len]u8 = [_]u8{0x69} ** crypto.aead.Aes256Gcm.key_len;
    const nonce: [crypto.aead.Aes256Gcm.nonce_len]u8 = [_]u8{0x42} ** crypto.aead.Aes256Gcm.nonce_len;
    const msg: []const u8 = "Test with message";
    const bytes: []const u8 = "Test with associated data";
    var cipher: [msg.len]u8 = undefined;
    var out: [msg.len]u8 = undefined;
    var tag: [crypto.aead.Aes256Gcm.tag_len]u8 = undefined;
    crypto.aead.Aes256Gcm.encrypt(&cipher, &tag, msg, bytes, nonce, key);
    try crypto.aead.Aes256Gcm.decrypt(&out, &cipher, tag, bytes, nonce, key);
    try testing.expectEqualMany(u8, msg, &out);
    try htest.assertEqual(allocator, "5ca1642d90009fea33d01f78cf6eefaf01", &cipher);
    try htest.assertEqual(allocator, "64accec679d444e2373bd9f6796c0d2c", &tag);
}
fn testGhash(allocator: *mem.SimpleAllocator) !void {
    const key: [16]u8 = [1]u8{0x42} ** 16;
    const msg: [256]u8 = [1]u8{0x69} ** 256;
    var st: crypto.aead.Ghash = crypto.aead.Ghash.init(&key);
    st.update(&msg);
    var out: [16]u8 = undefined;
    st.final(&out);
    try htest.assertEqual(allocator, "889295fa746e8b174bf4ec80a65dea41", &out);
    st = crypto.aead.Ghash.init(&key);
    st.update(msg[0..100]);
    st.update(msg[100..]);
    st.final(&out);
    try htest.assertEqual(allocator, "889295fa746e8b174bf4ec80a65dea41", &out);
}
fn testGhashVectors(allocator: *mem.SimpleAllocator) !void {
    var key: [16]u8 = undefined;
    var idx: usize = 0;
    while (idx < key.len) : (idx +%= 1) {
        key[idx] = @as(u8, @intCast(idx *% 15 +% 1));
    }
    inline for (tab.ghash_vectors) |tv| {
        var msg: [tv.len]u8 = undefined;
        idx = 0;
        while (idx < msg.len) : (idx +%= 1) {
            msg[idx] = @as(u8, @truncate(idx % 254 +% 1));
        }
        var st: crypto.aead.Ghash = crypto.aead.Ghash.init(&key);
        st.update(&msg);
        var out: [16]u8 = undefined;
        st.final(&out);
        try htest.assertEqual(allocator, tv.hash, &out);
    }
}
fn testPolyval(allocator: *mem.SimpleAllocator) !void {
    const key: [16]u8 = [1]u8{0x42} ** 16;
    const msg: [256]u8 = [1]u8{0x69} ** 256;
    var st = crypto.aead.Polyval.init(&key);
    st.update(&msg);
    var out: [16]u8 = undefined;
    st.final(&out);
    try htest.assertEqual(allocator, "0713c82b170eef25c8955ddf72c85ccb", &out);
    st = crypto.aead.Polyval.init(&key);
    st.update(msg[0..100]);
    st.update(msg[100..]);
    st.final(&out);
    try htest.assertEqual(allocator, "0713c82b170eef25c8955ddf72c85ccb", &out);
}
pub fn aeadTestMain() !void {
    try testChacha20AEADAPI();
    try testChacha20TestVectorSunscreen();
    try testChacha20TestVector1();
    try testChacha20TestVector2();
    try testChacha20TestVector3();
    try testChacha20TestVector4();
    try testChacha20TestVector5();
    try testXchacha201();
    try testXchacha202();
    try testSeal1();
    try testSeal2();
    try testOpen1();
    try testOpen2();
    var allocator: mem.SimpleAllocator = .{};
    try testAes256GcmAssociatedDataOnly(&allocator);
    try testAes256GcmEmptyMessageAndNoAssociatedData(&allocator);
    try testAes256GcmMessageOnly(&allocator);
    try testAes256GcmMessageAndAssociatedData(&allocator);
    try testGhash(&allocator);
    try testGhashVectors(&allocator);
    try testPolyval(&allocator);
}
pub const main = aeadTestMain;