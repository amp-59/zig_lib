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

fn testChacha20AEADAPI() !void {
    const aeads = [_]type{ crypto.aead.ChaCha20Poly1305, crypto.aead.XChaCha20Poly1305 };
    const msg: *const [114]u8 = "Ladies and Gentlemen of the class of '99: If I could offer you only one tip for the future, sunscreen would be it.";
    const bytes: []const u8 = "Additional data";
    inline for (aeads) |aead| {
        const key: [aead.key_len]u8 = [1]u8{69} ** aead.key_len;
        const nonce: [aead.nonce_len]u8 = [1]u8{42} ** aead.nonce_len;
        var cipher: [msg.len]u8 = undefined;
        var tag: [aead.tag_len]u8 = undefined;
        var out: [msg.len]u8 = undefined;
        aead.encrypt(&cipher, &tag, msg, bytes, nonce, key);
        try aead.decrypt(&out, &cipher, tag, bytes, nonce, key);
        try testing.expectEqualMany(u8, &out, msg);
        cipher[0] +%= 1;
        try testing.expectError(error.AuthenticationFailed, aead.decrypt(&out, &cipher, tag, bytes, nonce, key));
    }
}
pub fn aeadTestMain() !void {
    try testChacha20AEADAPI();
}
pub const main = aeadTestMain;
