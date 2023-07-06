const zig_lib = @import("../../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
const htest = @import("./hash-test.zig").htest;

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
    const expected_result: [114]u8 = .{
        0x6e, 0x2e, 0x35, 0x9a, 0x25, 0x68, 0xf9, 0x80, 0x41, 0xba, 0x07, 0x28, 0xdd, 0x0d, 0x69, 0x81,
        0xe9, 0x7e, 0x7a, 0xec, 0x1d, 0x43, 0x60, 0xc2, 0x0a, 0x27, 0xaf, 0xcc, 0xfd, 0x9f, 0xae, 0x0b,
        0xf9, 0x1b, 0x65, 0xc5, 0x52, 0x47, 0x33, 0xab, 0x8f, 0x59, 0x3d, 0xab, 0xcd, 0x62, 0xb3, 0x57,
        0x16, 0x39, 0xd6, 0x24, 0xe6, 0x51, 0x52, 0xab, 0x8f, 0x53, 0x0c, 0x35, 0x9f, 0x08, 0x61, 0xd8,
        0x07, 0xca, 0x0d, 0xbf, 0x50, 0x0d, 0x6a, 0x61, 0x56, 0xa3, 0x8e, 0x08, 0x8a, 0x22, 0xb6, 0x5e,
        0x52, 0xbc, 0x51, 0x4d, 0x16, 0xcc, 0xf8, 0x06, 0x81, 0x8c, 0xe9, 0x1a, 0xb7, 0x79, 0x37, 0x36,
        0x5a, 0xf9, 0x0b, 0xbf, 0x74, 0xa3, 0x5b, 0xe6, 0xb4, 0x0b, 0x8e, 0xed, 0xf2, 0x78, 0x5e, 0x42,
        0x87, 0x4d,
    };
    var result1: [114]u8 = undefined;
    var result2: [114]u8 = undefined;
    const key: [32]u8 = .{
        0,  1,  2,  3,  4,  5,  6,  7,  8,  9,  10, 11, 12, 13, 14, 15,
        16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31,
    };
    const nonce: [12]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0x4a, 0, 0, 0, 0 };
    crypto.aead.ChaCha20IETF.xor(&result1, sunscreen, 1, key, nonce);
    try testing.expectEqualMany(u8, &expected_result, &result1);
    crypto.aead.ChaCha20IETF.xor(&result2, &result1, 1, key, nonce);
    try testing.expect(mem.order(u8, sunscreen, &result2) == .eq);
}
pub fn aeadTestMain() !void {
    try testChacha20AEADAPI();
    try testChacha20TestVectorSunscreen();
}
pub const main = aeadTestMain;
