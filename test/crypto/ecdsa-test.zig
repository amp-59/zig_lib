const zl = @import("../../zig_lib.zig");
const fmt = zig_lib.fmt;
const mach = zig_lib.mach;
const file = zig_lib.file;
const proc = zig_lib.proc;
const meta = zig_lib.meta;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
const tab = @import("./tab.zig");
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
fn testECDSABasicOperationsOverEcdsaP384Sha384() !void {
    const Scheme = crypto.ecdsa.EcdsaP384Sha384;
    var noise: [Scheme.noise_len]u8 = undefined;
    crypto.utils.bytes(&noise);
    const key_pair: Scheme.KeyPair = try Scheme.KeyPair.create(noise);
    const msg: []const u8 = "test";
    crypto.utils.bytes(&noise);
    const sig: Scheme.Signature = try key_pair.sign(msg, noise);
    try sig.verify(msg, key_pair.public_key);
    const sig2: Scheme.Signature = try key_pair.sign(msg, null);
    try sig2.verify(msg, key_pair.public_key);
}
fn testECDSABasicOperationsOverSecp256k1() !void {
    const Scheme = crypto.ecdsa.EcdsaSecp256k1Sha256oSha256;
    const key_pair: Scheme.KeyPair = try crypto.ecdsa.EcdsaSecp256k1Sha256oSha256.KeyPair.create(null);
    const msg: []const u8 = "test";
    var noise: [Scheme.noise_len]u8 = undefined;
    crypto.utils.bytes(&noise);
    const sig: Scheme.Signature = try key_pair.sign(msg, noise);
    try sig.verify(msg, key_pair.public_key);
    const sig2: Scheme.Signature = try key_pair.sign(msg, null);
    try sig2.verify(msg, key_pair.public_key);
}
fn testECDSABasicOperationsOverEcdsaP384Sha256() !void {
    const Scheme = crypto.ecdsa.GenericEcdsa(crypto.pcurves.P384, crypto.hash.Sha256);
    const key_pair: Scheme.KeyPair = try Scheme.KeyPair.create(null);
    const msg: []const u8 = "test";
    var noise: [Scheme.noise_len]u8 = undefined;
    crypto.utils.bytes(&noise);
    const sig: Scheme.Signature = try key_pair.sign(msg, noise);
    try sig.verify(msg, key_pair.public_key);
    const sig2: Scheme.Signature = try key_pair.sign(msg, null);
    try sig2.verify(msg, key_pair.public_key);
}
fn testECDSAVerifyingAExistingSignatureWithEcdsaP384Sha256() !void {
    const Scheme = crypto.ecdsa.GenericEcdsa(crypto.pcurves.P384, crypto.hash.Sha256);
    const seed: [48]u8 = .{
        0x6a, 0x53, 0x9c, 0x83, 0x0f, 0x06, 0x86, 0xd9,
        0xef, 0xf1, 0xe7, 0x5c, 0xae, 0x93, 0xd9, 0x5b,
        0x16, 0x1e, 0x96, 0x7c, 0xb0, 0x86, 0x35, 0xc9,
        0xea, 0x20, 0xdc, 0x2b, 0x02, 0x37, 0x6d, 0xd2,
        0x89, 0x72, 0x0a, 0x37, 0xf6, 0x5d, 0x4f, 0x4d,
        0xf7, 0x97, 0xcb, 0x8b, 0x03, 0x63, 0xc3, 0x2d,
    };
    const msg: [17]u8 = .{
        0x64, 0x61, 0x74, 0x61,
        0x20, 0x66, 0x6f, 0x72,
        0x20, 0x73, 0x69, 0x67,
        0x6e, 0x69, 0x6e, 0x67,
        0x0a,
    };
    const sig_ans_bytes: [102]u8 = .{
        0x30, 0x64, 0x02, 0x30, 0x7a, 0x31, 0xd8, 0xe0,
        0xf8, 0x40, 0x7d, 0x6a, 0xf3, 0x1a, 0x5d, 0x02,
        0xe5, 0xcb, 0x24, 0x29, 0x1a, 0xac, 0x15, 0x94,
        0xd1, 0x5b, 0xcd, 0x75, 0x2f, 0x45, 0x79, 0x98,
        0xf7, 0x60, 0x9a, 0xd5, 0xca, 0x80, 0x15, 0x87,
        0x9b, 0x0c, 0x27, 0xe3, 0x01, 0x8b, 0x73, 0x4e,
        0x57, 0xa3, 0xd2, 0x9a, 0x02, 0x30, 0x33, 0xe0,
        0x04, 0x5e, 0x76, 0x1f, 0xc8, 0xcf, 0xda, 0xbe,
        0x64, 0x95, 0x0a, 0xd4, 0x85, 0x34, 0x33, 0x08,
        0x7a, 0x81, 0xf2, 0xf6, 0xb6, 0x94, 0x68, 0xc3,
        0x8c, 0x5f, 0x88, 0x92, 0x27, 0x5e, 0x4e, 0x84,
        0x96, 0x48, 0x42, 0x84, 0x28, 0xac, 0x37, 0x93,
        0x07, 0xd3, 0x50, 0x32, 0x71, 0xb0,
    };
    const secret_key: Scheme.SecretKey = try Scheme.SecretKey.fromBytes(seed);
    const key_pair: Scheme.KeyPair = try Scheme.KeyPair.fromSecretKey(secret_key);
    const sig_ans: Scheme.Signature = try Scheme.Signature.fromDer(&sig_ans_bytes);
    try sig_ans.verify(&msg, key_pair.public_key);
    const sig: Scheme.Signature = try key_pair.sign(&msg, null);
    try sig.verify(&msg, key_pair.public_key);
}
fn testECDSASec1EncodingDecoding() !void {
    const Scheme = crypto.ecdsa.EcdsaP384Sha384;
    const key_pair: Scheme.KeyPair = try Scheme.KeyPair.create(null);
    const public_key: Scheme.PublicKey = key_pair.public_key;
    const public_key_compressed_sec1: Scheme.PublicKey.CompressedSec1 = public_key.toCompressedSec1();
    const public_key_recovered1: Scheme.PublicKey = try Scheme.PublicKey.fromSec1(&public_key_compressed_sec1);
    try testing.expectEqualMany(u8, &public_key_recovered1.toCompressedSec1(), &public_key_compressed_sec1);
    const public_key_uncompressed_sec1: Scheme.PublicKey.UncompressedSec1 = public_key.toUncompressedSec1();
    const public_key_recovered2: Scheme.PublicKey = try Scheme.PublicKey.fromSec1(&public_key_uncompressed_sec1);
    try testing.expectEqualMany(u8, &public_key_recovered2.toUncompressedSec1(), &public_key_uncompressed_sec1);
}
fn tvTry(vector: tab.TestVector) !void {
    const Scheme = crypto.ecdsa.EcdsaP256Sha256;
    var key_sec1_buf: [Scheme.PublicKey.encoded_len]u8 = undefined;
    const key_sec1: []const u8 = try meta.wrap(fmt.hexToBytes(&key_sec1_buf, vector.key));
    const public_key: Scheme.PublicKey = try Scheme.PublicKey.fromSec1(key_sec1);
    var msg_buf: [20]u8 = undefined;
    const msg: []const u8 = try meta.wrap(fmt.hexToBytes(&msg_buf, vector.msg));
    var sig_der_buf: [152]u8 = undefined;
    const sig_der: []const u8 = try meta.wrap(fmt.hexToBytes(&sig_der_buf, vector.sig));
    const sig: Scheme.Signature = try Scheme.Signature.fromDer(sig_der);
    try sig.verify(msg, public_key);
}
fn testECDSATestVectorsFromProjectWycheproof() !void {
    var false_positive: u64 = 0;
    var false_negative: u64 = 0;
    for (&tab.ecdsa_vectors) |vector| {
        const which: bool = vector.result == .valid or vector.result == .acceptable;
        if (tvTry(vector)) {
            false_positive +%= @intFromBool(!which);
        } else |_| {
            false_negative +%= @intFromBool(which);
        }
    }
    builtin.assertEqual(u64, false_negative, 0);
    builtin.assertEqual(u64, false_positive, 0);
}
pub fn ecdsaTestMain() !void {
    try testECDSABasicOperationsOverEcdsaP384Sha384();
    try testECDSABasicOperationsOverSecp256k1();
    try testECDSABasicOperationsOverEcdsaP384Sha256();
    try testECDSAVerifyingAExistingSignatureWithEcdsaP384Sha256();
    try testECDSASec1EncodingDecoding();
    try testECDSATestVectorsFromProjectWycheproof();
}
pub const main = ecdsaTestMain;
