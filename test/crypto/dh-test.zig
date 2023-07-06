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
    var blind: [32]u8 = undefined;
    const key_pair: crypto.dh.Ed25519.KeyPair = try crypto.dh.Ed25519.KeyPair.create(null);
    crypto.utils.bytes(&blind);
    const blind_key_pair: crypto.dh.Ed25519.key_blinding.BlindKeyPair =
        try crypto.dh.Ed25519.key_blinding.BlindKeyPair.init(key_pair, blind, "ctx");
    const msg = "test";
    const sig = try blind_key_pair.sign(msg, null);
    try sig.verify(msg, blind_key_pair.blind_public_key.key);
    const public_key: crypto.dh.Ed25519.PublicKey = try blind_key_pair.blind_public_key.unblind(blind, "ctx");
    try testing.expectEqualMany(u8, &public_key.toBytes(), &key_pair.public_key.toBytes());
}
fn testEd25519TestVectors() !void {
    for (tab.ed25519_vectors) |entry| {
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
const field_order_s = s: {
    var s: [32]u8 = undefined;
    mem.writeIntLittle(u256, &s, crypto.scalar.field_order);
    break :s s;
};
fn testScalar25519() !void {
    const bytes: [32]u8 = .{
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 255,
    };
    var x: crypto.scalar.Scalar = crypto.scalar.Scalar.fromBytes(bytes);
    var y: crypto.scalar.CompressedScalar = x.toBytes();
    try crypto.scalar.rejectNonCanonical(y);
    var buf: [128]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &y),
        "1e979b917937f3de71d18077f961f6ceff01030405060708010203040506070f",
    );
    const reduced: crypto.scalar.CompressedScalar = crypto.scalar.reduce(field_order_s);
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &reduced),
        "0000000000000000000000000000000000000000000000000000000000000000",
    );
}
fn testMulAddOverflowCheck() !void {
    const a: [32]u8 = [_]u8{0xff} ** 32;
    const b: [32]u8 = [_]u8{0xff} ** 32;
    const c: [32]u8 = [_]u8{0xff} ** 32;
    const x: crypto.scalar.CompressedScalar = crypto.scalar.mulAdd(a, b, c);
    var buf: [128]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &x),
        "d14df91389432c25ad60ff9791b9fd1d67bef517d273ecce3d9a307c1b419903",
    );
}
fn testScalarFieldInversion() !void {
    const bytes: [32]u8 = .{
        1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8,
    };
    const x: crypto.scalar.Scalar = crypto.scalar.Scalar.fromBytes(bytes);
    const inv: crypto.scalar.Scalar = x.invert();
    const recovered_x: crypto.scalar.Scalar = inv.invert();
    try testing.expectEqualMany(u8, &bytes, &recovered_x.toBytes());
}
fn testRandomScalar() !void {
    const s1: crypto.scalar.CompressedScalar = crypto.scalar.randomX();
    const s2: crypto.scalar.CompressedScalar = crypto.scalar.randomX();
    try builtin.expect(!mem.testEqualMany(u8, &s1, &s2));
}
fn test64BitReduction() !void {
    const bytes: [64]u8 = field_order_s ++ [1]u8{0} ** 32;
    const x: crypto.scalar.Scalar = crypto.scalar.Scalar.fromBytes64(bytes);
    try builtin.expect(x.isZero());
}
fn testNonCanonicalScalar25519() !void {
    try builtin.expect(error.NonCanonical == crypto.scalar.rejectNonCanonical(.{
        0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
        0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10,
    }));
}

fn testCurve25519() !void {
    var s: [32]u8 = .{
        1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8,
        1, 2, 3, 4, 5, 6, 7, 8, 1, 2, 3, 4, 5, 6, 7, 8,
    };
    const p: crypto.dh.Curve25519 = try crypto.dh.Curve25519.base_point.clampedMul(s);
    try p.rejectIdentity();
    var buf: [128]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &p.toBytes()),
        "e6f2a4d1c28ee5c7ad0329268255a468ad407d2672824c0c0eb30ea6ef450145",
    );
    const q: crypto.dh.Curve25519 = try p.clampedMul(s);
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &q.toBytes()),
        "3614e119ffe55ec55b87d6b19971a9f4cbc78efe80bec55b96392babcc712537",
    );
    try crypto.dh.Curve25519.rejectNonCanonical(s);
    s[31] |= 0x80;
    try builtin.expect(error.NonCanonical == crypto.dh.Curve25519.rejectNonCanonical(s));
}
fn testCurve25519SmallOrderCheck() !void {
    var s: [32]u8 = [_]u8{1} ++ [_]u8{0} ** 31;
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
            0xe0, 0xeb, 0x7a, 0x7c, 0x3b, 0x41, 0xb8, 0xae,
            0x16, 0x56, 0xe3, 0xfa, 0xf1, 0x9f, 0xc4, 0x6a,
            0xda, 0x09, 0x8d, 0xeb, 0x9c, 0x32, 0xb1, 0xfd,
            0x86, 0x62, 0x05, 0x16, 0x5f, 0x49, 0xb8, 0x00,
        },
        .{
            0x5f, 0x9c, 0x95, 0xbc, 0xa3, 0x50, 0x8c, 0x24,
            0xb1, 0xd0, 0xb1, 0x55, 0x9c, 0x83, 0xef, 0x5b,
            0x04, 0x44, 0x5c, 0xc4, 0x58, 0x1c, 0x8e, 0x86,
            0xd8, 0x22, 0x4e, 0xdd, 0xd0, 0x9f, 0x11, 0x57,
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
        try builtin.expect(error.WeakPublicKey == crypto.dh.Curve25519.fromBytes(small_order_s).clearCofactor());
        try builtin.expect(error.WeakPublicKey == crypto.dh.Curve25519.fromBytes(small_order_s).mul(s));
        var extra: [32]u8 = small_order_s;
        extra[31] ^= 0x80;
        try builtin.expect(error.WeakPublicKey == crypto.dh.Curve25519.fromBytes(extra).mul(s));
        var valid: [32]u8 = small_order_s;
        valid[31] = 0x40;
        s[0] = 0;
        try builtin.expect(error.IdentityElement == crypto.dh.Curve25519.fromBytes(valid).mul(s));
    }
}
fn testX25519PublicKeyCalculationFromSecretKey() !void {
    var secret_key: [32]u8 = undefined;
    var public_key_expected: [32]u8 = undefined;
    _ = try fmt.hexToBytes(
        secret_key[0..],
        "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166",
    );
    _ = try fmt.hexToBytes(
        public_key_expected[0..],
        "f1814f0e8ff1043d8a44d25babff3cedcae6c22c3edaa48f857ae70de2baae50",
    );
    const public_key_calculated: [32]u8 = try crypto.dh.X25519.recoverPublicKey(secret_key);
    try builtin.expectEqual([32]u8, public_key_calculated, public_key_expected);
}
fn testX25519Rfc7748Vector1() !void {
    const secret_key: [32]u8 = .{
        0xa5, 0x46, 0xe3, 0x6b, 0xf0, 0x52, 0x7c, 0x9d,
        0x3b, 0x16, 0x15, 0x4b, 0x82, 0x46, 0x5e, 0xdd,
        0x62, 0x14, 0x4c, 0x0a, 0xc1, 0xfc, 0x5a, 0x18,
        0x50, 0x6a, 0x22, 0x44, 0xba, 0x44, 0x9a, 0xc4,
    };
    const public_key: [32]u8 = .{
        0xe6, 0xdb, 0x68, 0x67, 0x58, 0x30, 0x30, 0xdb,
        0x35, 0x94, 0xc1, 0xa4, 0x24, 0xb1, 0x5f, 0x7c,
        0x72, 0x66, 0x24, 0xec, 0x26, 0xb3, 0x35, 0x3b,
        0x10, 0xa9, 0x03, 0xa6, 0xd0, 0xab, 0x1c, 0x4c,
    };
    const expected_output: [32]u8 = .{
        0xc3, 0xda, 0x55, 0x37, 0x9d, 0xe9, 0xc6, 0x90,
        0x8e, 0x94, 0xea, 0x4d, 0xf2, 0x8d, 0x08, 0x4f,
        0x32, 0xec, 0xcf, 0x03, 0x49, 0x1c, 0x71, 0xf7,
        0x54, 0xb4, 0x07, 0x55, 0x77, 0xa2, 0x85, 0x52,
    };
    const output = try crypto.dh.X25519.scalarmult(secret_key, public_key);
    try builtin.expectEqual([32]u8, output, expected_output);
}
fn testX25519Rfc7748Vector2() !void {
    const secret_key: [32]u8 = .{
        0x4b, 0x66, 0xe9, 0xd4, 0xd1, 0xb4, 0x67, 0x3c,
        0x5a, 0xd2, 0x26, 0x91, 0x95, 0x7d, 0x6a, 0xf5,
        0xc1, 0x1b, 0x64, 0x21, 0xe0, 0xea, 0x01, 0xd4,
        0x2c, 0xa4, 0x16, 0x9e, 0x79, 0x18, 0xba, 0x0d,
    };
    const public_key: [32]u8 = .{
        0xe5, 0x21, 0x0f, 0x12, 0x78, 0x68, 0x11, 0xd3,
        0xf4, 0xb7, 0x95, 0x9d, 0x05, 0x38, 0xae, 0x2c,
        0x31, 0xdb, 0xe7, 0x10, 0x6f, 0xc0, 0x3c, 0x3e,
        0xfc, 0x4c, 0xd5, 0x49, 0xc7, 0x15, 0xa4, 0x93,
    };
    const expected_output: [32]u8 = .{
        0x95, 0xcb, 0xde, 0x94, 0x76, 0xe8, 0x90, 0x7d,
        0x7a, 0xad, 0xe4, 0x5c, 0xb4, 0xb8, 0x73, 0xf8,
        0x8b, 0x59, 0x5a, 0x68, 0x79, 0x9f, 0xa1, 0x52,
        0xe6, 0xf8, 0xf7, 0x64, 0x7a, 0xac, 0x79, 0x57,
    };
    const output = try crypto.dh.X25519.scalarmult(secret_key, public_key);
    try builtin.expectEqual([32]u8, output, expected_output);
}
fn testX25519Rfc7748OneIteration() !void {
    if (return) {} // Verified 28-06-2023
    const initial_value: [32]u8 = .{
        0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const expected_output: [32]u8 = .{
        0x42, 0x2c, 0x8e, 0x7a, 0x62, 0x27, 0xd7, 0xbc,
        0xa1, 0x35, 0x0b, 0x3e, 0x2b, 0xb7, 0x27, 0x9f,
        0x78, 0x97, 0xb8, 0x7b, 0xb6, 0x85, 0x4b, 0x78,
        0x3c, 0x60, 0xe8, 0x03, 0x11, 0xae, 0x30, 0x79,
    };
    var k: [32]u8 = initial_value;
    var u: [32]u8 = initial_value;
    var idx: usize = 0;
    while (idx != 1) : (idx +%= 1) {
        const output: [crypto.dh.X25519.shared_len]u8 = try crypto.dh.X25519.scalarmult(k, u);
        u = k;
        k = output;
    }
    try builtin.expectEqual([32]u8, k, expected_output);
}
fn testX5519Rfc77481000Iterations() !void {
    if (return) {} // Verified 28-06-2023
    const initial_value: [32]u8 = .{
        0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const expected_output: [32]u8 = .{
        0x68, 0x4c, 0xf5, 0x9b, 0xa8, 0x33, 0x09, 0x55,
        0x28, 0x00, 0xef, 0x56, 0x6f, 0x2f, 0x4d, 0x3c,
        0x1c, 0x38, 0x87, 0xc4, 0x93, 0x60, 0xe3, 0x87,
        0x5f, 0x2e, 0xb9, 0x4d, 0x99, 0x53, 0x2c, 0x51,
    };
    var k: [32]u8 = initial_value.*;
    var u: [32]u8 = initial_value.*;
    var idx: usize = 0;
    while (idx != 1000) : (idx +%= 1) {
        const output: [crypto.dh.X25519.shared_len]u8 = try crypto.dh.X25519.scalarmult(&k, &u);
        u = k;
        k = output;
    }
    try builtin.expectEqual([32]u8, k, expected_output);
}
fn testX25519Rfc77481000000Iterations() !void {
    if (return) {} // Verified 28-06-2023
    const initial_value: [32]u8 = .{
        0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
    };
    const expected_output: [32]u8 = .{
        0x7c, 0x39, 0x11, 0xe0, 0xab, 0x25, 0x86, 0xfd,
        0x86, 0x44, 0x97, 0x29, 0x7e, 0x57, 0x5e, 0x6f,
        0x3b, 0xc6, 0x01, 0xc0, 0x88, 0x3c, 0x30, 0xdf,
        0x5f, 0x4d, 0xd2, 0xd2, 0x4f, 0x66, 0x54, 0x24,
    };
    var k: [32]u8 = initial_value;
    var u: [32]u8 = initial_value;
    var idx: usize = 0;
    while (idx != 1000000) : (idx +%= 1) {
        const output: [crypto.dh.X25519.shared_len]u8 = try crypto.dh.X25519.scalarmult(k, u);
        u = k;
        k = output;
    }
    try builtin.expectEqual([32]u8, k, expected_output);
}
fn testRistretto255() !void {
    var buf: [256]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &crypto.dh.Ristretto255.base_point.toBytes()),
        "e2f2ae0a6abc4e71a884a961c500515f58e30b6aa582dd8db6a65945e08d2d76",
    );
    var r: [crypto.dh.Ristretto255.encoded_len]u8 = undefined;
    _ = try fmt.hexToBytes(r[0..], "6a493210f7499cd17fecb510ae0cea23a110e8d5b901f8acadd3095c73a3b919");
    var q: crypto.dh.Ristretto255 = try crypto.dh.Ristretto255.fromBytes(r);
    q = q.dbl().add(crypto.dh.Ristretto255.base_point);
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &q.toBytes()),
        "e882b131016b52c1d3337080187cf768423efccbb517bb495ab812c4160ff44e",
    );
    const s: [32]u8 = [_]u8{15} ++ [_]u8{0} ** 31;
    const w: crypto.dh.Ristretto255 = try crypto.dh.Ristretto255.base_point.mul(s);
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &w.toBytes()),
        "e0c418f7c8d9c4cdd7395b93ea124f3ad99021bb681dfc3302a9d99a2e53e64e",
    );
    try builtin.expect(crypto.dh.Ristretto255.base_point.dbl().dbl().dbl().dbl()
        .equivalent(w.add(crypto.dh.Ristretto255.base_point)));
    const h: [64]u8 = [_]u8{69} ** 32 ++ [_]u8{42} ** 32;
    const ph: crypto.dh.Ristretto255 = crypto.dh.Ristretto255.fromUniform(h);
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &ph.toBytes()),
        "dcca54e037a4311efbeef413acd21d35276518970b7a61dc88f8587b493d5e19",
    );
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
    // Scalar
    try testScalar25519();
    try testMulAddOverflowCheck();
    try testScalarFieldInversion();
    try testRandomScalar();
    try test64BitReduction();
    try testNonCanonicalScalar25519();
    // Curve25519
    try testCurve25519();
    try testCurve25519SmallOrderCheck();
    // X22519
    try testX25519PublicKeyCalculationFromSecretKey();
    try testX25519Rfc7748Vector1();
    try testX25519Rfc7748Vector2();
    try testX25519Rfc7748OneIteration();
    try testX5519Rfc77481000Iterations();
    try testX25519Rfc77481000000Iterations();
    // Ristretto255
    try testRistretto255();
}
pub const main = dhTestMain;
