const zig_lib = @import("../../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const file = zig_lib.file;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
const tab = @import("./tab.zig");
const htest = @import("./hash-test.zig").htest;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
fn testEd25519KeyPairCreation() !void {
    var seed: [32]u8 = undefined;
    _ = try fmt.hexToBytes(seed[0..], "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166");
    const key_pair = try crypto.dh.Ed25519.KeyPair.create(seed);
    var buf: [256]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &key_pair.secret_key.toBytes()),
        "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de1662d6f7455d97b4a3a10d7293909d1a4f2058cb9a370e43fa8154bb280db839083",
    );
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &key_pair.public_key.toBytes()),
        "2d6f7455d97b4a3a10d7293909d1a4f2058cb9a370e43fa8154bb280db839083",
    );
}
fn testEd25519Signature() !void {
    var seed: [32]u8 = undefined;
    _ = try fmt.hexToBytes(seed[0..], "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166");
    const key_pair = try crypto.dh.Ed25519.KeyPair.create(seed);
    const sig: crypto.dh.Ed25519.Signature = try key_pair.sign("test", null);
    var buf: [128]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &sig.toBytes()),
        "10a442b4a80cc4225b154f43bef28d2472ca80221951262eb8e0df9091575e2687cc486e77263c3418c757522d54f84b0359236abbbd4acd20dc297fdca66808",
    );
    try sig.verify("test", key_pair.public_key);
    try builtin.expect(error.SignatureVerificationFailed == sig.verify("TEST", key_pair.public_key));
}
fn testEd25519BatchVerification() !void {
    var idx: usize = 0;
    while (idx != 100) : (idx +%= 1) {
        const key_pair = try crypto.dh.Ed25519.KeyPair.create(null);
        var msg1: [32]u8 = undefined;
        var msg2: [32]u8 = undefined;
        crypto.utils.bytes(&msg1);
        crypto.utils.bytes(&msg2);
        const sig1: crypto.dh.Ed25519.Signature = try key_pair.sign(&msg1, null);
        const sig2: crypto.dh.Ed25519.Signature = try key_pair.sign(&msg2, null);
        var signature_batch: [2]crypto.dh.Ed25519.BatchElement = .{
            crypto.dh.Ed25519.BatchElement{
                .sig = sig1,
                .msg = &msg1,
                .public_key = key_pair.public_key,
            },
            crypto.dh.Ed25519.BatchElement{
                .sig = sig2,
                .msg = &msg2,
                .public_key = key_pair.public_key,
            },
        };
        try crypto.dh.Ed25519.verifyBatch(2, signature_batch);
        signature_batch[1].sig = sig1;
        try builtin.expect(error.SignatureVerificationFailed == crypto.dh.Ed25519.verifyBatch(signature_batch.len, signature_batch));
    }
}
fn testEd25519SignaturesWithStreaming() !void {
    const key_pair: crypto.dh.Ed25519.KeyPair = try crypto.dh.Ed25519.KeyPair.create(null);
    var signer: crypto.dh.Ed25519.Signer = try key_pair.signer(null);
    signer.update("mes");
    signer.update("sage");
    const sig: crypto.dh.Ed25519.Signature = signer.finalize();
    try sig.verify("message", key_pair.public_key);
    var verifier: crypto.dh.Ed25519.Verifier = try sig.verifier(key_pair.public_key);
    verifier.update("mess");
    verifier.update("age");
    try verifier.verify();
}
fn testEd25519KeyPairFromSecretKey() !void {
    const key_pair1: crypto.dh.Ed25519.KeyPair = try crypto.dh.Ed25519.KeyPair.create(null);
    const key_pair2: crypto.dh.Ed25519.KeyPair = try crypto.dh.Ed25519.KeyPair.fromSecretKey(key_pair1.secret_key);
    try testing.expectEqualMany(u8, &key_pair1.secret_key.toBytes(), &key_pair2.secret_key.toBytes());
    try testing.expectEqualMany(u8, &key_pair1.public_key.toBytes(), &key_pair2.public_key.toBytes());
}
fn testEd25519WithBlindKeys() !void {
    const kp = try crypto.dh.Ed25519.KeyPair.create(null);
    var blind: [32]u8 = undefined;
    crypto.utils.bytes(&blind);
    const blind_kp: crypto.dh.Ed25519.key_blinding.BlindKeyPair =
        try crypto.dh.Ed25519.key_blinding.BlindKeyPair.init(kp, blind, "ctx");
    const msg = "test";
    const sig = try blind_kp.sign(msg, null);
    try sig.verify(msg, blind_kp.blind_public_key.key);
    const pk = try blind_kp.blind_public_key.unblind(blind, "ctx");
    try testing.expectEqualMany(u8, &pk.toBytes(), &kp.public_key.toBytes());
}
fn testEd25519TestVectors() !void {
    for (tab.entries) |entry| {
        var msg: [32]u8 = undefined;
        _ = try fmt.hexToBytes(&msg, entry.msg);
        var public_key_bytes: [32]u8 = undefined;
        _ = try fmt.hexToBytes(&public_key_bytes, entry.key);
        const public_key = crypto.dh.Ed25519.PublicKey.fromBytes(public_key_bytes) catch |err| {
            try builtin.expectEqual(anyerror, entry.expected.?, err);
            continue;
        };
        var sig_bytes: [64]u8 = undefined;
        _ = try fmt.hexToBytes(&sig_bytes, entry.sig);
        const sig = crypto.dh.Ed25519.Signature.fromBytes(sig_bytes);
        if (entry.expected) |error_type| {
            try builtin.expect(error_type == sig.verify(&msg, public_key));
        } else {
            try sig.verify(&msg, public_key);
        }
    }
}
pub fn dhTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();

    try testEd25519KeyPairCreation();
    try testEd25519Signature();
    try testEd25519BatchVerification();
    try testEd25519SignaturesWithStreaming();
    try testEd25519KeyPairFromSecretKey();
    try testEd25519WithBlindKeys();
    try testEd25519TestVectors();
}
pub const main = dhTestMain;
