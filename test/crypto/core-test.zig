const zig_lib = @import("../../zig_lib.zig");
const fmt = zig_lib.fmt;
const mach = zig_lib.mach;
const meta = zig_lib.meta;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
fn testCtr() !void {
    // NIST SP 800-38A pp 55-58
    const key: [16]u8 = .{ 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c };
    const iv: [16]u8 = .{ 0xf0, 0xf1, 0xf2, 0xf3, 0xf4, 0xf5, 0xf6, 0xf7, 0xf8, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfe, 0xff };
    const in: [64]u8 = .{
        0x6b, 0xc1, 0xbe, 0xe2, 0x2e, 0x40, 0x9f, 0x96, 0xe9, 0x3d, 0x7e, 0x11, 0x73, 0x93, 0x17, 0x2a,
        0xae, 0x2d, 0x8a, 0x57, 0x1e, 0x03, 0xac, 0x9c, 0x9e, 0xb7, 0x6f, 0xac, 0x45, 0xaf, 0x8e, 0x51,
        0x30, 0xc8, 0x1c, 0x46, 0xa3, 0x5c, 0xe4, 0x11, 0xe5, 0xfb, 0xc1, 0x19, 0x1a, 0x0a, 0x52, 0xef,
        0xf6, 0x9f, 0x24, 0x45, 0xdf, 0x4f, 0x9b, 0x17, 0xad, 0x2b, 0x41, 0x7b, 0xe6, 0x6c, 0x37, 0x10,
    };
    const exp_out: [64]u8 = .{
        0x87, 0x4d, 0x61, 0x91, 0xb6, 0x20, 0xe3, 0x26, 0x1b, 0xef, 0x68, 0x64, 0x99, 0x0d, 0xb6, 0xce,
        0x98, 0x06, 0xf6, 0x6b, 0x79, 0x70, 0xfd, 0xff, 0x86, 0x17, 0x18, 0x7b, 0xb9, 0xff, 0xfd, 0xff,
        0x5a, 0xe4, 0xdf, 0x3e, 0xdb, 0xd5, 0xd3, 0x5e, 0x5b, 0x4f, 0x09, 0x02, 0x0d, 0xb0, 0x3e, 0xab,
        0x1e, 0x03, 0x1d, 0xda, 0x2f, 0xbe, 0x03, 0xd1, 0x79, 0x21, 0x70, 0xa0, 0xf3, 0x00, 0x9c, 0xee,
    };
    var out: [exp_out.len]u8 = undefined;
    crypto.core.ctr(crypto.core.GenericAesEncryptCtx(crypto.core.Aes128), crypto.core.Aes128.initEnc(key), out[0..], in[0..], iv, builtin.Endian.Big);
    try testing.expectEqualMany(u8, exp_out[0..], out[0..]);
}
fn testEncrypt() !void {
    {
        const key: [16]u8 = .{ 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c };
        const in: [16]u8 = .{ 0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d, 0x31, 0x31, 0x98, 0xa2, 0xe0, 0x37, 0x07, 0x34 };
        const exp_out: [16]u8 = .{ 0x39, 0x25, 0x84, 0x1d, 0x02, 0xdc, 0x09, 0xfb, 0xdc, 0x11, 0x85, 0x97, 0x19, 0x6a, 0x0b, 0x32 };
        var out: [exp_out.len]u8 = undefined;
        crypto.core.Aes128.initEnc(key).encrypt(out[0..], in[0..]);
        try testing.expectEqualMany(u8, exp_out[0..], out[0..]);
    }
    {
        const key: [32]u8 = .{
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
        };
        const in: [16]u8 = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff };
        const exp_out: [16]u8 = .{ 0x8e, 0xa2, 0xb7, 0xca, 0x51, 0x67, 0x45, 0xbf, 0xea, 0xfc, 0x49, 0x90, 0x4b, 0x49, 0x60, 0x89 };
        var out: [exp_out.len]u8 = undefined;
        crypto.core.Aes256.initEnc(key).encrypt(out[0..], in[0..]);
        try testing.expectEqualMany(u8, exp_out[0..], out[0..]);
    }
}
fn testDecrypt() !void {
    {
        const key: [16]u8 = .{ 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c };
        const in: [16]u8 = .{ 0x39, 0x25, 0x84, 0x1d, 0x02, 0xdc, 0x09, 0xfb, 0xdc, 0x11, 0x85, 0x97, 0x19, 0x6a, 0x0b, 0x32 };
        const exp_out: [16]u8 = .{ 0x32, 0x43, 0xf6, 0xa8, 0x88, 0x5a, 0x30, 0x8d, 0x31, 0x31, 0x98, 0xa2, 0xe0, 0x37, 0x07, 0x34 };
        var out: [exp_out.len]u8 = undefined;
        crypto.core.Aes128.initDec(key).decrypt(out[0..], in[0..]);
        try testing.expectEqualMany(u8, exp_out[0..], out[0..]);
    }
    {
        const key: [32]u8 = .{
            0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09, 0x0a, 0x0b, 0x0c, 0x0d, 0x0e, 0x0f,
            0x10, 0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19, 0x1a, 0x1b, 0x1c, 0x1d, 0x1e, 0x1f,
        };
        const in: [16]u8 = .{ 0x8e, 0xa2, 0xb7, 0xca, 0x51, 0x67, 0x45, 0xbf, 0xea, 0xfc, 0x49, 0x90, 0x4b, 0x49, 0x60, 0x89 };
        const exp_out: [16]u8 = .{ 0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff };
        var out: [exp_out.len]u8 = undefined;
        crypto.core.Aes256.initDec(key).decrypt(out[0..], in[0..]);
        try testing.expectEqualMany(u8, exp_out[0..], out[0..]);
    }
}
fn testExpand128BitKey() !void {
    const key: [16]u8 = .{ 0x2b, 0x7e, 0x15, 0x16, 0x28, 0xae, 0xd2, 0xa6, 0xab, 0xf7, 0x15, 0x88, 0x09, 0xcf, 0x4f, 0x3c };
    const exp_enc = [_]*const [32:0]u8{
        "2b7e151628aed2a6abf7158809cf4f3c", "a0fafe1788542cb123a339392a6c7605", "f2c295f27a96b9435935807a7359f67f", "3d80477d4716fe3e1e237e446d7a883b", "ef44a541a8525b7fb671253bdb0bad00", "d4d1c6f87c839d87caf2b8bc11f915bc", "6d88a37a110b3efddbf98641ca0093fd", "4e54f70e5f5fc9f384a64fb24ea6dc4f", "ead27321b58dbad2312bf5607f8d292f", "ac7766f319fadc2128d12941575c006e", "d014f9a8c9ee2589e13f0cc8b6630ca6",
    };
    const exp_dec = [_]*const [32:0]u8{
        "d014f9a8c9ee2589e13f0cc8b6630ca6", "0c7b5a631319eafeb0398890664cfbb4", "df7d925a1f62b09da320626ed6757324", "12c07647c01f22c7bc42d2f37555114a", "6efcd876d2df54807c5df034c917c3b9", "6ea30afcbc238cf6ae82a4b4b54a338d", "90884413d280860a12a128421bc89739", "7c1f13f74208c219c021ae480969bf7b", "cc7505eb3e17d1ee82296c51c9481133", "2b3708a7f262d405bc3ebdbf4b617d62", "2b7e151628aed2a6abf7158809cf4f3c",
    };
    var exp: [16]u8 = undefined;
    for (crypto.core.Aes128.initEnc(key).key_schedule.round_keys, 0..) |round_key, i| {
        _ = try meta.wrap(fmt.hexToBytes(&exp, exp_enc[i]));
        try testing.expectEqualMany(u8, &exp, &round_key.toBytes());
    }
    for (crypto.core.Aes128.initDec(key).key_schedule.round_keys, 0..) |round_key, i| {
        _ = try meta.wrap(fmt.hexToBytes(&exp, exp_dec[i]));
        try testing.expectEqualMany(u8, &exp, &round_key.toBytes());
    }
}
fn testExpand256BitKey() !void {
    const key: [32]u8 = .{
        0x60, 0x3d, 0xeb, 0x10,
        0x15, 0xca, 0x71, 0xbe,
        0x2b, 0x73, 0xae, 0xf0,
        0x85, 0x7d, 0x77, 0x81,
        0x1f, 0x35, 0x2c, 0x07,
        0x3b, 0x61, 0x08, 0xd7,
        0x2d, 0x98, 0x10, 0xa3,
        0x09, 0x14, 0xdf, 0xf4,
    };
    const exp_enc = [_]*const [32:0]u8{
        "603deb1015ca71be2b73aef0857d7781", "1f352c073b6108d72d9810a30914dff4", "9ba354118e6925afa51a8b5f2067fcde",
        "a8b09c1a93d194cdbe49846eb75d5b9a", "d59aecb85bf3c917fee94248de8ebe96", "b5a9328a2678a647983122292f6c79b3",
        "812c81addadf48ba24360af2fab8b464", "98c5bfc9bebd198e268c3ba709e04214", "68007bacb2df331696e939e46c518d80",
        "c814e20476a9fb8a5025c02d59c58239", "de1369676ccc5a71fa2563959674ee15", "5886ca5d2e2f31d77e0af1fa27cf73c3",
        "749c47ab18501ddae2757e4f7401905a", "cafaaae3e4d59b349adf6acebd10190d", "fe4890d1e6188d0b046df344706c631e",
    };
    const exp_dec = [_]*const [32:0]u8{
        "fe4890d1e6188d0b046df344706c631e", "ada23f4963e23b2455427c8a5c709104", "57c96cf6074f07c0706abb07137f9241",
        "b668b621ce40046d36a047ae0932ed8e", "34ad1e4450866b367725bcc763152946", "32526c367828b24cf8e043c33f92aa20",
        "c440b289642b757227a3d7f114309581", "d669a7334a7ade7a80c8f18fc772e9e3", "25ba3c22a06bc7fb4388a28333934270",
        "54fb808b9c137949cab22ff547ba186c", "6c3d632985d1fbd9e3e36578701be0f3", "4a7459f9c8e8f9c256a156bc8d083799",
        "42107758e9ec98f066329ea193f8858b", "8ec6bff6829ca03b9e49af7edba96125", "603deb1015ca71be2b73aef0857d7781",
    };
    var exp: [16]u8 = undefined;
    for (crypto.core.Aes256.initEnc(key).key_schedule.round_keys, 0..) |round_key, i| {
        _ = try meta.wrap(fmt.hexToBytes(&exp, exp_enc[i]));
        try testing.expectEqualMany(u8, &exp, &round_key.toBytes());
    }
    for (crypto.core.Aes256.initDec(key).key_schedule.round_keys, 0..) |round_key, i| {
        _ = try meta.wrap(fmt.hexToBytes(&exp, exp_dec[i]));
        try testing.expectEqualMany(u8, &exp, &round_key.toBytes());
    }
}
fn testAscon() !void {
    const Ascon = crypto.core.GenericAsconState(.Big);
    const bytes: [40]u8 = .{0x01} ** Ascon.blk_len;
    var st: Ascon = Ascon.init(bytes);
    var out: [Ascon.blk_len]u8 = undefined;
    st.permute();
    st.extractBytes(&out);
    const expected1: [Ascon.blk_len]u8 = .{ 148, 147, 49, 226, 218, 221, 208, 113, 186, 94, 96, 10, 183, 219, 119, 150, 169, 206, 65, 18, 215, 97, 78, 106, 118, 81, 211, 150, 52, 17, 117, 64, 216, 45, 148, 240, 65, 181, 90, 180 };
    try testing.expectEqualMany(u8, &expected1, &out);
    st.clear(0, 10);
    st.extractBytes(&out);
    const expected2: [Ascon.blk_len]u8 = .{ 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 169, 206, 65, 18, 215, 97, 78, 106, 118, 81, 211, 150, 52, 17, 117, 64, 216, 45, 148, 240, 65, 181, 90, 180 };
    try testing.expectEqualMany(u8, &expected2, &out);
    st.addByte(1, 5);
    st.addByte(2, 5);
    st.extractBytes(&out);
    const expected3: [Ascon.blk_len]u8 = .{ 0, 0, 0, 0, 0, 3, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 169, 206, 65, 18, 215, 97, 78, 106, 118, 81, 211, 150, 52, 17, 117, 64, 216, 45, 148, 240, 65, 181, 90, 180 };
    try testing.expectEqualMany(u8, &expected3, &out);
    st.addBytes(&bytes);
    st.extractBytes(&out);
    const expected4: [Ascon.blk_len]u8 = .{ 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 168, 207, 64, 19, 214, 96, 79, 107, 119, 80, 210, 151, 53, 16, 116, 65, 217, 44, 149, 241, 64, 180, 91, 181 };
    try testing.expectEqualMany(u8, &expected4, &out);
}
pub fn coreTestMain() !void {
    try testCtr();
    try testEncrypt();
    try testDecrypt();
    try testExpand128BitKey();
    try testExpand256BitKey();
    try testAscon();
}
pub const main = coreTestMain;
