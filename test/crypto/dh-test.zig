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
    const blind_key_pair: crypto.dh.Ed25519.key_blinding.BlindKeyPair =
        try crypto.dh.Ed25519.key_blinding.BlindKeyPair.init(kp, blind, "ctx");
    const msg = "test";
    const sig = try blind_key_pair.sign(msg, null);
    try sig.verify(msg, blind_key_pair.blind_public_key.key);
    const pk = try blind_key_pair.blind_public_key.unblind(blind, "ctx");
    try testing.expectEqualMany(u8, &pk.toBytes(), &kp.public_key.toBytes());
}
fn testEd25519TestVectors() !void {
    for (tab.entries) |entry| {
        var msg: [32]u8 = undefined;
        _ = try fmt.hexToBytes(&msg, entry.msg);
        var public_key_bytes: [32]u8 = undefined;
        _ = try fmt.hexToBytes(&public_key_bytes, entry.key);
        const public_key: crypto.dh.Ed25519.PublicKey = crypto.dh.Ed25519.PublicKey.fromBytes(public_key_bytes) catch |err| {
            try builtin.expectEqual(anyerror, entry.expected.?, err);
            continue;
        };
        var sig_bytes: [64]u8 = undefined;
        _ = try fmt.hexToBytes(&sig_bytes, entry.sig);
        const sig: crypto.dh.Ed25519.Signature = crypto.dh.Ed25519.Signature.fromBytes(sig_bytes);
        if (entry.expected) |error_type| {
            try builtin.expect(error_type == sig.verify(&msg, public_key));
        } else {
            try sig.verify(&msg, public_key);
        }
    }
}
fn testEdwards25519ToCurve25519Map(allocator: *mem.SimpleAllocator) !void {
    const ed_key_pair: crypto.dh.Ed25519.KeyPair =
        try crypto.dh.Ed25519.KeyPair.create([_]u8{0x42} ** 32);
    const mont_key_pair: crypto.dh.X25519.KeyPair =
        try crypto.dh.X25519.KeyPair.fromEd25519(ed_key_pair);
    try htest.assertEqual(
        allocator,
        "90e7595fc89e52fdfddce9c6a43d74dbf6047025ee0462d2d172e8b6a2841d6e",
        &mont_key_pair.secret_key,
    );
    try htest.assertEqual(
        allocator,
        "cc4f2cdb695dd766f34118eb67b98652fed1d8bc49c330b119bbfa8a64989378",
        &mont_key_pair.public_key,
    );
}
fn testEdwards25519PointAdditionSubtraction() !void {
    var s1: [32]u8 = undefined;
    var s2: [32]u8 = undefined;
    crypto.utils.bytes(&s1);
    crypto.utils.bytes(&s2);
    const p: crypto.dh.Edwards25519 = try crypto.dh.Edwards25519.base_point.clampedMul(s1);
    const q: crypto.dh.Edwards25519 = try crypto.dh.Edwards25519.base_point.clampedMul(s2);
    const r: crypto.dh.Edwards25519 = p.add(q).add(q).sub(q).sub(q);
    try r.rejectIdentity();
    try builtin.expect(error.IdentityElement == r.sub(p).rejectIdentity());
    try builtin.expect(error.IdentityElement == p.sub(p).rejectIdentity());
    try builtin.expect(error.IdentityElement == p.sub(q).add(q).sub(p).rejectIdentity());
}
fn testEdwards25519UniformToPoint(allocator: *mem.SimpleAllocator) !void {
    var r: [32]u8 = .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 };
    var p: crypto.dh.Edwards25519 = crypto.dh.Edwards25519.fromUniform(r);
    try htest.assertEqual(allocator, "0691eee3cf70a0056df6bfa03120635636581b5c4ea571dfc680f78c7e0b4137", p.toBytes()[0..]);
    r[31] = 0xff;
    p = crypto.dh.Edwards25519.fromUniform(r);
    try htest.assertEqual(allocator, "f70718e68ef42d90ca1d936bb2d7e159be6c01d8095d39bd70487c82fe5c973a", p.toBytes()[0..]);
}
fn testEdwards25519HashToCurveOperation(allocator: *mem.SimpleAllocator) !void {
    var p: crypto.dh.Edwards25519 = crypto.dh.Edwards25519.fromString(true, "QUUX-V01-CS02-with-edwards25519_XMD:SHA-512_ELL2_RO_", "abc");
    try htest.assertEqual(allocator, "31558a26887f23fb8218f143e69d5f0af2e7831130bd5b432ef23883b895839a", p.toBytes()[0..]);
    p = crypto.dh.Edwards25519.fromString(false, "QUUX-V01-CS02-with-edwards25519_XMD:SHA-512_ELL2_NU_", "abc");
    try htest.assertEqual(allocator, "42fa27c8f5a1ae0aa38bb59d5938e5145622ba5dedd11d11736fa2f9502d7367", p.toBytes()[0..]);
}
fn testEdwards25519ImplicitReductionOfInvalidScalars(allocator: *mem.SimpleAllocator) !void {
    const s: [32]u8 = [1]u8{0} ** 31 ++ [1]u8{255};
    const p1: crypto.dh.Edwards25519 = try crypto.dh.Edwards25519.base_point.mulPublic(s);
    const p2: crypto.dh.Edwards25519 = try crypto.dh.Edwards25519.base_point.mul(s);
    const p3: crypto.dh.Edwards25519 = try p1.mulPublic(s);
    const p4: crypto.dh.Edwards25519 = try p1.mul(s);
    try testing.expectEqualMany(u8, p1.toBytes()[0..], p2.toBytes()[0..]);
    try testing.expectEqualMany(u8, p3.toBytes()[0..], p4.toBytes()[0..]);
    try htest.assertEqual(allocator, "339f189ecc5fbebe9895345c72dc07bda6e615f8a40e768441b6f529cd6c671a", p1.toBytes()[0..]);
    try htest.assertEqual(allocator, "a501e4c595a3686d8bee7058c7e6af7fd237f945c47546910e37e0e79b1bafb0", p3.toBytes()[0..]);
}
fn testEdwards25519PackingUnpacking() !void {
    const s: [32]u8 = [1]u8{170} ++ [_]u8{0} ** 31;
    var b: crypto.dh.Edwards25519 = crypto.dh.Edwards25519.base_point;
    const pk: crypto.dh.Edwards25519 = try b.mul(s);
    var buf: [128]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &pk.toBytes()),
        "074bc7e0fcbd587fdbc0969444245fadc562809c8f6e97e949af62484b5b81a6",
    );
    const small_order_ss: [7][32]u8 = .{
        .{
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        },
        .{
            0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
            0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        },
        .{
            0x26, 0xe8, 0x95, 0x8f, 0xc2, 0xb2, 0x27, 0xb0,
            0x45, 0xc3, 0xf4, 0x89, 0xf2, 0xef, 0x98, 0xf0,
            0xd5, 0xdf, 0xac, 0x05, 0xd3, 0xc6, 0x33, 0x39,
            0xb1, 0x38, 0x02, 0x88, 0x6d, 0x53, 0xfc, 0x05,
        },
        .{
            0xc7, 0x17, 0x6a, 0x70, 0x3d, 0x4d, 0xd8, 0x4f,
            0xba, 0x3c, 0x0b, 0x76, 0x0d, 0x10, 0x67, 0x0f,
            0x2a, 0x20, 0x53, 0xfa, 0x2c, 0x39, 0xcc, 0xc6,
            0x4e, 0xc7, 0xfd, 0x77, 0x92, 0xac, 0x03, 0x7a,
        },
        .{
            0xec, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f,
        },
        .{
            0xed, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f,
        },
        .{
            0xee, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff,
            0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x7f,
        },
    };
    for (small_order_ss) |small_order_s| {
        const small_p: crypto.dh.Edwards25519 = try crypto.dh.Edwards25519.fromBytes(small_order_s);
        try builtin.expect(error.WeakPublicKey == small_p.mul(s));
    }
}
pub fn dhTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    // Ed25519
    try testEd25519KeyPairCreation();
    try testEd25519Signature();
    try testEd25519BatchVerification();
    try testEd25519SignaturesWithStreaming();
    try testEd25519KeyPairFromSecretKey();
    try testEd25519WithBlindKeys();
    try testEd25519TestVectors();
    // Edwards25519
    try testEdwards25519ToCurve25519Map(&allocator);
    try testEdwards25519PointAdditionSubtraction();
    try testEdwards25519UniformToPoint(&allocator);
    try testEdwards25519HashToCurveOperation(&allocator);
    try testEdwards25519ImplicitReductionOfInvalidScalars(&allocator);
    try testEdwards25519PackingUnpacking();
}
pub const main = dhTestMain;
