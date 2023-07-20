const zl = @import("../../zig_lib.zig");
const fmt = zl.fmt;
const meta = zl.meta;
const proc = zl.proc;
const crypto = zl.crypto;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
fn testP256ECDHKeyExchange() !void {
    const dha = crypto.pcurves.P256.scalar.randomX(.Little);
    const dhb = crypto.pcurves.P256.scalar.randomX(.Little);
    const dhA = try crypto.pcurves.P256.base_point.mul(dha, .Little);
    const dhB = try crypto.pcurves.P256.base_point.mul(dhb, .Little);
    const shareda = try dhA.mul(dhb, .Little);
    const sharedb = try dhB.mul(dha, .Little);
    try debug.expect(shareda.equivalent(sharedb));
}
fn testP256PointFromAffineCoordinates() !void {
    const xh: [:0]const u8 = "6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296";
    const yh: [:0]const u8 = "4FE342E2FE1A7F9B8EE7EB4A7C0F9E162BCE33576B315ECECBB6406837BF51F5";
    var xs: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
    var ys: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&ys, yh));
    var p = try crypto.pcurves.P256.fromSerializedAffineCoordinates(xs, ys, .Big);
    try debug.expect(p.equivalent(crypto.pcurves.P256.base_point));
}
fn testP256TestVectors() !void {
    const expected: []const [:0]const u8 = &[10][:0]const u8{
        "0000000000000000000000000000000000000000000000000000000000000000",
        "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
        "7cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978",
        "5ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c",
        "e2534a3532d08fbba02dde659ee62bd0031fe2db785596ef509302446b030852",
        "51590b7a515140d2d784c85608668fdfef8c82fd1f5be52421554a0dc3d033ed",
        "b01a172a76a4602c92d3242cb897dde3024c740debb215b4c6b0aae93c2291a9",
        "8e533b6fa0bf7b4625bb30667c01fb607ef9f8b8a80fef5b300628703187b2a3",
        "62d9779dbee9b0534042742d3ab54cadc1d238980fce97dbb4dd9dc1db6fb393",
        "ea68d7b6fedf0b71878938d51d71f8729e0acb8c2c6df8b3d79e8a4b90949ee0",
    };
    var p = crypto.pcurves.P256.identity_element;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.add(crypto.pcurves.P256.base_point);
        var xs: [32]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testP256TestVectorsDoubling() !void {
    const expected: []const [:0]const u8 = &[4][:0]const u8{
        "6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296",
        "7cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978",
        "e2534a3532d08fbba02dde659ee62bd0031fe2db785596ef509302446b030852",
        "62d9779dbee9b0534042742d3ab54cadc1d238980fce97dbb4dd9dc1db6fb393",
    };
    var p = crypto.pcurves.P256.base_point;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.dbl();
        var xs: [32]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testP256CompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.P256.random();
    const s = p.toCompressedSec1();
    const q = try crypto.pcurves.P256.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testP256UncompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.P256.random();
    const s = p.toUncompressedSec1();
    const q = try crypto.pcurves.P256.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testP256PublicKeyIsTheNeutralElement() !void {
    const n = crypto.pcurves.P256.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.P256.random();
    try debug.expect(error.IdentityElement == p.mul(n, .Little));
}
fn testP256PublicKeyIsTheNeutralElementPublicVerification() !void {
    const n = crypto.pcurves.P256.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.P256.random();
    try debug.expect(error.IdentityElement == p.mulPublic(n, .Little));
}
fn testP256FieldElementNonCanonicalEncoding() !void {
    const s = [_]u8{0xff} ** 32;
    try debug.expect(error.NonCanonical == crypto.pcurves.P256.Fe.fromBytes(s, .Little));
}
fn testP256NeutralElementDecoding() !void {
    try debug.expect(error.InvalidEncoding == crypto.pcurves.P256.fromAffineCoordinates(.{ .x = crypto.pcurves.P256.Fe.zero, .y = crypto.pcurves.P256.Fe.zero }));
    const p = try crypto.pcurves.P256.fromAffineCoordinates(.{ .x = crypto.pcurves.P256.Fe.zero, .y = crypto.pcurves.P256.Fe.one });
    try debug.expect(error.IdentityElement == p.rejectIdentity());
}
fn testP256DoubleBaseMultiplication() !void {
    const p1 = crypto.pcurves.P256.base_point;
    const p2 = crypto.pcurves.P256.base_point.dbl();
    const s1 = [_]u8{0x01} ** 32;
    const s2 = [_]u8{0x02} ** 32;
    const pr1 = try crypto.pcurves.P256.mulDoubleBasePublic(p1, s1, p2, s2, .Little);
    const pr2 = (try p1.mul(s1, .Little)).add(try p2.mul(s2, .Little));
    try debug.expect(pr1.equivalent(pr2));
}
fn testP256DoubleBaseMultiplicationWithLargeScalars() !void {
    const p1 = crypto.pcurves.P256.base_point;
    const p2 = crypto.pcurves.P256.base_point.dbl();
    const s1 = [_]u8{0xee} ** 32;
    const s2 = [_]u8{0xdd} ** 32;
    const pr1 = try crypto.pcurves.P256.mulDoubleBasePublic(p1, s1, p2, s2, .Little);
    const pr2 = (try p1.mul(s1, .Little)).add(try p2.mul(s2, .Little));
    try debug.expect(pr1.equivalent(pr2));
}
fn testP256ScalarInverse() !void {
    const expected = "3b549196a13c898a6f6e84dfb3a22c40a8b9b17fb88e408ea674e451cd01d0a6";
    var out: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&out, expected));
    const scalar = try crypto.pcurves.P256.scalar.Scalar.fromBytes(.{
        0x94, 0xa1, 0xbb, 0xb1, 0x4b, 0x90, 0x6a, 0x61, 0xa2, 0x80, 0xf2, 0x45, 0xf9, 0xe9, 0x3c, 0x7f,
        0x3b, 0x4a, 0x62, 0x47, 0x82, 0x4f, 0x5d, 0x33, 0xb9, 0x67, 0x07, 0x87, 0x64, 0x2a, 0x68, 0xde,
    }, .Big);
    const inverse = scalar.invert();
    try testing.expectEqualMany(u8, &out, &inverse.toBytes(.Big));
}
fn testP384ECDHKeyExchange() !void {
    const dha = crypto.pcurves.P384.scalar.randomX(.Little);
    const dhb = crypto.pcurves.P384.scalar.randomX(.Little);
    const dhA = try crypto.pcurves.P384.base_point.mul(dha, .Little);
    const dhB = try crypto.pcurves.P384.base_point.mul(dhb, .Little);
    const shareda = try dhA.mul(dhb, .Little);
    const sharedb = try dhB.mul(dha, .Little);
    try debug.expect(shareda.equivalent(sharedb));
}
fn testP384PointFromAffineCoordinates() !void {
    const xh: [:0]const u8 = "aa87ca22be8b05378eb1c71ef320ad746e1d3b628ba79b9859f741e082542a385502f25dbf55296c3a545e3872760ab7";
    const yh: [:0]const u8 = "3617de4a96262c6f5d9e98bf9292dc29f8f41dbd289a147ce9da3113b5f0b8c00a60b1ce1d7e819d7a431d7c90ea0e5f";
    var xs: [48]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
    var ys: [48]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&ys, yh));
    var p = try crypto.pcurves.P384.fromSerializedAffineCoordinates(xs, ys, .Big);
    try debug.expect(p.equivalent(crypto.pcurves.P384.base_point));
}
fn testP384TestVectors() !void {
    const expected: [11][:0]const u8 = [_][:0]const u8{
        "000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
        "AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7",
        "08D999057BA3D2D969260045C55B97F089025959A6F434D651D207D19FB96E9E4FE0E86EBE0E64F85B96A9C75295DF61",
        "077A41D4606FFA1464793C7E5FDC7D98CB9D3910202DCD06BEA4F240D3566DA6B408BBAE5026580D02D7E5C70500C831",
        "138251CD52AC9298C1C8AAD977321DEB97E709BD0B4CA0ACA55DC8AD51DCFC9D1589A1597E3A5120E1EFD631C63E1835",
        "11DE24A2C251C777573CAC5EA025E467F208E51DBFF98FC54F6661CBE56583B037882F4A1CA297E60ABCDBC3836D84BC",
        "627BE1ACD064D2B2226FE0D26F2D15D3C33EBCBB7F0F5DA51CBD41F26257383021317D7202FF30E50937F0854E35C5DF",
        "283C1D7365CE4788F29F8EBF234EDFFEAD6FE997FBEA5FFA2D58CC9DFA7B1C508B05526F55B9EBB2040F05B48FB6D0E1",
        "1692778EA596E0BE75114297A6FA383445BF227FBE58190A900C3C73256F11FB5A3258D6F403D5ECE6E9B269D822C87D",
        "8F0A39A4049BCB3EF1BF29B8B025B78F2216F7291E6FD3BAC6CB1EE285FB6E21C388528BFEE2B9535C55E4461079118B",
        "A669C5563BD67EEC678D29D6EF4FDE864F372D90B79B9E88931D5C29291238CCED8E85AB507BF91AA9CB2D13186658FB",
    };
    var p = crypto.pcurves.P384.identity_element;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.add(crypto.pcurves.P384.base_point);
        var xs: [48]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testP384TestVectorsDoubling() !void {
    const expected = [_][]const u8{
        "AA87CA22BE8B05378EB1C71EF320AD746E1D3B628BA79B9859F741E082542A385502F25DBF55296C3A545E3872760AB7",
        "08D999057BA3D2D969260045C55B97F089025959A6F434D651D207D19FB96E9E4FE0E86EBE0E64F85B96A9C75295DF61",
        "138251CD52AC9298C1C8AAD977321DEB97E709BD0B4CA0ACA55DC8AD51DCFC9D1589A1597E3A5120E1EFD631C63E1835",
        "1692778EA596E0BE75114297A6FA383445BF227FBE58190A900C3C73256F11FB5A3258D6F403D5ECE6E9B269D822C87D",
    };
    var p = crypto.pcurves.P384.base_point;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.dbl();
        var xs: [48]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testP384CompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.P384.random();
    const s0 = p.toUncompressedSec1();
    const s = p.toCompressedSec1();
    try testing.expectEqualMany(u8, s0[1..49], s[1..49]);
    const q = try crypto.pcurves.P384.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testP384UncompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.P384.random();
    const s = p.toUncompressedSec1();
    const q = try crypto.pcurves.P384.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testP384PublicKeyIsTheNeutralElement() !void {
    const n = crypto.pcurves.P384.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.P384.random();
    try debug.expect(error.IdentityElement == p.mul(n, .Little));
}
fn testP384PublicKeyIsTheNeutralElementPublicVerification() !void {
    const n = crypto.pcurves.P384.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.P384.random();
    try debug.expect(error.IdentityElement == p.mulPublic(n, .Little));
}
fn testP384FieldElementNonCanonicalEncoding() !void {
    const s = [_]u8{0xff} ** 48;
    try debug.expect(error.NonCanonical == crypto.pcurves.P384.Fe.fromBytes(s, .Little));
}
fn testP384NeutralElementDecoding() !void {
    try debug.expect(error.InvalidEncoding == crypto.pcurves.P384.fromAffineCoordinates(.{ .x = crypto.pcurves.P384.Fe.zero, .y = crypto.pcurves.P384.Fe.zero }));
    const p = try crypto.pcurves.P384.fromAffineCoordinates(.{ .x = crypto.pcurves.P384.Fe.zero, .y = crypto.pcurves.P384.Fe.one });
    try debug.expect(error.IdentityElement == p.rejectIdentity());
}
fn testP384DoubleBaseMultiplication() !void {
    const p1 = crypto.pcurves.P384.base_point;
    const p2 = crypto.pcurves.P384.base_point.dbl();
    const s1 = [_]u8{0x01} ** 48;
    const s2 = [_]u8{0x02} ** 48;
    const pr1 = try crypto.pcurves.P384.mulDoubleBasePublic(p1, s1, p2, s2, .Little);
    const pr2 = (try p1.mul(s1, .Little)).add(try p2.mul(s2, .Little));
    try debug.expect(pr1.equivalent(pr2));
}
fn testP384DoubleBaseMultiplicationWithLargeScalars() !void {
    const p1 = crypto.pcurves.P384.base_point;
    const p2 = crypto.pcurves.P384.base_point.dbl();
    const s1 = [_]u8{0xee} ** 48;
    const s2 = [_]u8{0xdd} ** 48;
    const pr1 = try crypto.pcurves.P384.mulDoubleBasePublic(p1, s1, p2, s2, .Little);
    const pr2 = (try p1.mul(s1, .Little)).add(try p2.mul(s2, .Little));
    try debug.expect(pr1.equivalent(pr2));
}
fn testP384ScalarInverse() !void {
    const expected = "a3cc705f33b5679a66e76ce66e68055c927c5dba531b2837b18fe86119511091b54d733f26b2e7a0f6fa2e7ea21ca806";
    var out: [48]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&out, expected));
    const scalar = try crypto.pcurves.P384.scalar.Scalar.fromBytes(.{
        0x94, 0xa1, 0xbb, 0xb1, 0x4b, 0x90, 0x6a, 0x61, 0xa2, 0x80, 0xf2, 0x45, 0xf9, 0xe9, 0x3c, 0x7f,
        0x3b, 0x4a, 0x62, 0x47, 0x82, 0x4f, 0x5d, 0x33, 0xb9, 0x67, 0x07, 0x87, 0x64, 0x2a, 0x68, 0xde,
        0x38, 0x36, 0xe8, 0x0f, 0xa2, 0x84, 0x6b, 0x4e, 0xf3, 0x9a, 0x02, 0x31, 0x24, 0x41, 0x22, 0xca,
    }, .Big);
    const inverse = scalar.invert();
    const inverse2 = inverse.invert();
    try testing.expectEqualMany(u8, &out, &inverse.toBytes(.Big));
    try debug.expect(inverse2.equivalent(scalar));
    const sq = scalar.sq();
    const sqr = try sq.sqrt();
    try debug.expect(sqr.equivalent(scalar));
}
fn testSecp256k1ECDHKeyExchange() !void {
    const dha = crypto.pcurves.Secp256k1.scalar.randomX(.Little);
    const dhb = crypto.pcurves.Secp256k1.scalar.randomX(.Little);
    const dhA = try crypto.pcurves.Secp256k1.base_point.mul(dha, .Little);
    const dhB = try crypto.pcurves.Secp256k1.base_point.mul(dhb, .Little);
    const shareda = try dhA.mul(dhb, .Little);
    const sharedb = try dhB.mul(dha, .Little);
    try debug.expect(shareda.equivalent(sharedb));
}
fn testSecp256k1ECDHKeyExchangeIncludingPublicMultiplication() !void {
    const dha = crypto.pcurves.Secp256k1.scalar.randomX(.Little);
    const dhb = crypto.pcurves.Secp256k1.scalar.randomX(.Little);
    const dhA = try crypto.pcurves.Secp256k1.base_point.mul(dha, .Little);
    const dhB = try crypto.pcurves.Secp256k1.base_point.mulPublic(dhb, .Little);
    const shareda = try dhA.mul(dhb, .Little);
    const sharedb = try dhB.mulPublic(dha, .Little);
    try debug.expect(shareda.equivalent(sharedb));
}
fn testSecp256k1PointFromAffineCoordinates() !void {
    const xh = "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798";
    const yh = "483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8";
    var xs: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
    var ys: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&ys, yh));
    var p = try crypto.pcurves.Secp256k1.fromSerializedAffineCoordinates(xs, ys, .Big);
    try debug.expect(p.equivalent(crypto.pcurves.Secp256k1.base_point));
}
fn testSecp256k1TestVectors() !void {
    const expected: [10][]const u8 = .{
        "0000000000000000000000000000000000000000000000000000000000000000",
        "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        "c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5",
        "f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9",
        "e493dbf1c10d80f3581e4904930b1404cc6c13900ee0758474fa94abe8c4cd13",
        "2f8bde4d1a07209355b4a7250a5c5128e88b84bddc619ab7cba8d569b240efe4",
        "fff97bd5755eeea420453a14355235d382f6472f8568a18b2f057a1460297556",
        "5cbdf0646e5db4eaa398f365f2ea7a0e3d419b7e0330e39ce92bddedcac4f9bc",
        "2f01e5e15cca351daff3843fb70f3c2f0a1bdd05e5af888a67784ef3e10a2a01",
        "acd484e2f0c7f65309ad178a9f559abde09796974c57e714c35f110dfc27ccbe",
    };
    var p = crypto.pcurves.Secp256k1.identity_element;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.add(crypto.pcurves.Secp256k1.base_point);
        var xs: [32]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testSecp256k1TestVectorsDoubling() !void {
    const expected: [5][]const u8 = .{
        "79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798",
        "c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5",
        "e493dbf1c10d80f3581e4904930b1404cc6c13900ee0758474fa94abe8c4cd13",
        "2f01e5e15cca351daff3843fb70f3c2f0a1bdd05e5af888a67784ef3e10a2a01",
        "e60fce93b59e9ec53011aabc21c23e97b2a31369b87a5ae9c44ee89e2a6dec0a",
    };
    var p = crypto.pcurves.Secp256k1.base_point;
    for (expected) |xh| {
        const x = p.affineCoordinates().x;
        p = p.dbl();
        var xs: [32]u8 = undefined;
        _ = try meta.wrap(fmt.hexToBytes(&xs, xh));
        try testing.expectEqualMany(u8, &x.toBytes(.Big), &xs);
    }
}
fn testSecp256k1CompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.Secp256k1.random();
    const s = p.toCompressedSec1();
    const q = try crypto.pcurves.Secp256k1.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testSecp256k1UncompressedSec1EncodingDecoding() !void {
    const p = crypto.pcurves.Secp256k1.random();
    const s = p.toUncompressedSec1();
    const q = try crypto.pcurves.Secp256k1.fromSec1(&s);
    try debug.expect(p.equivalent(q));
}
fn testSecp256k1PublicKeyIsTheNeutralElement() !void {
    const n = crypto.pcurves.Secp256k1.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.Secp256k1.random();
    try debug.expect(error.IdentityElement == p.mul(n, .Little));
}
fn testSecp256k1PublicKeyIsTheNeutralElementPublicVerification() !void {
    const n = crypto.pcurves.Secp256k1.scalar.Scalar.zero.toBytes(.Little);
    const p = crypto.pcurves.Secp256k1.random();
    try debug.expect(error.IdentityElement == p.mulPublic(n, .Little));
}
fn testSecp256k1FieldElementNonCanonicalEncoding() !void {
    const s = [_]u8{0xff} ** 32;
    try debug.expect(error.NonCanonical == crypto.pcurves.Secp256k1.Fe.fromBytes(s, .Little));
}
fn testSecp256k1NeutralElementDecoding() !void {
    try debug.expect(error.InvalidEncoding == crypto.pcurves.Secp256k1.fromAffineCoordinates(.{ .x = crypto.pcurves.Secp256k1.Fe.zero, .y = crypto.pcurves.Secp256k1.Fe.zero }));
    const p = try crypto.pcurves.Secp256k1.fromAffineCoordinates(.{ .x = crypto.pcurves.Secp256k1.Fe.zero, .y = crypto.pcurves.Secp256k1.Fe.one });
    try debug.expect(error.IdentityElement == p.rejectIdentity());
}
fn testSecp256k1DoubleBaseMultiplication() !void {
    const p1 = crypto.pcurves.Secp256k1.base_point;
    const p2 = crypto.pcurves.Secp256k1.base_point.dbl();
    const s1 = [_]u8{0x01} ** 32;
    const s2 = [_]u8{0x02} ** 32;
    const pr1 = try crypto.pcurves.Secp256k1.mulDoubleBasePublic(p1, s1, p2, s2, .Little);
    const pr2 = (try p1.mul(s1, .Little)).add(try p2.mul(s2, .Little));
    try debug.expect(pr1.equivalent(pr2));
}
fn testSecp256k1ScalarInverse() !void {
    const expected = "08d0684a0fe8ea978b68a29e4b4ffdbd19eeb59db25301cf23ecbe568e1f9822";
    var out: [32]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(&out, expected));
    const scalar = try crypto.pcurves.Secp256k1.scalar.Scalar.fromBytes(.{
        0x94, 0xa1, 0xbb, 0xb1, 0x4b, 0x90, 0x6a, 0x61, 0xa2, 0x80, 0xf2, 0x45, 0xf9, 0xe9, 0x3c, 0x7f,
        0x3b, 0x4a, 0x62, 0x47, 0x82, 0x4f, 0x5d, 0x33, 0xb9, 0x67, 0x07, 0x87, 0x64, 0x2a, 0x68, 0xde,
    }, .Big);
    const inverse = scalar.invert();
    try testing.expectEqualMany(u8, &out, &inverse.toBytes(.Big));
}
pub fn pcurveTestMain() !void {
    comptime var do_test = .{
        .p256_ecdh_key_exchange = true, // 267512
        // This test WAS failing, so perhaps worthy of concern that it is now passing without any deliberate attempt to fix.
        .p256_point_from_affine_coordinates = true,
        .p256_test_vectors = true,
        .p256_test_vectors_doubling = true,
        .p256_compressed_sec1_encoding_decoding = true,
        .p256_uncompressed_sec1_encoding_decoding = true,
        .p256_public_key_is_the_neutral_element = true,
        .p256_public_key_is_the_neutral_element_public_verification = true,
        .p256_field_element_non_canonical_encoding = true,
        .p256_neutral_element_decoding = true,
        .p256_double_base_multiplication = true,
        .p256_double_base_multiplication_with_large_scalars = true,
        .p256_scalar_inverse = true,
        .p384_ecdh_key_exchange = true, // 492320
        .p384_point_from_affine_coordinates = true,
        .p384_test_vectors = true,
        .p384_test_vectors_doubling = true,
        .p384_compressed_sec1_encoding_decoding = true,
        .p384_uncompressed_sec1_encoding_decoding = true,
        .p384_public_key_is_the_neutral_element = true,
        .p384_public_key_is_the_neutral_element_public_verification = true,
        .p384_field_element_non_canonical_encoding = true,
        .p384_neutral_element_decoding = true,
        .p384_double_base_multiplication = true,
        .p384_double_base_multiplication_with_large_scalars = true,
        .p384_scalar_inverse = true,
        .secp256k1_ecdh_key_exchange = true, // 277080
        .secp256k1_ecdh_key_exchange_including_public_multiplication = true,
        .secp256k1_point_from_affine_coordinates = true,
        .secp256k1_test_vectors = true,
        .secp256k1_test_vectors_doubling = true,
        .secp256k1_compressed_sec1_encoding_decoding = true,
        .secp256k1_uncompressed_sec1_encoding_decoding = true,
        .secp256k1_public_key_is_the_neutral_element = true,
        .secp256k1_public_key_is_the_neutral_element_public_verification = true,
        .secp256k1_field_element_non_canonical_encoding = true,
        .secp256k1_neutral_element_decoding = true,
        .secp256k1_double_base_multiplication = true,
        .secp256k1_scalar_inverse = true,
    };
    if (do_test.p256_ecdh_key_exchange)
        try testP256ECDHKeyExchange();
    if (do_test.p256_point_from_affine_coordinates)
        try testP256PointFromAffineCoordinates();
    if (do_test.p256_test_vectors)
        try testP256TestVectors();
    if (do_test.p256_test_vectors_doubling)
        try testP256TestVectorsDoubling();
    if (do_test.p256_compressed_sec1_encoding_decoding)
        try testP256CompressedSec1EncodingDecoding();
    if (do_test.p256_uncompressed_sec1_encoding_decoding)
        try testP256UncompressedSec1EncodingDecoding();
    if (do_test.p256_public_key_is_the_neutral_element)
        try testP256PublicKeyIsTheNeutralElement();
    if (do_test.p256_public_key_is_the_neutral_element_public_verification)
        try testP256PublicKeyIsTheNeutralElementPublicVerification();
    if (do_test.p256_field_element_non_canonical_encoding)
        try testP256FieldElementNonCanonicalEncoding();
    if (do_test.p256_neutral_element_decoding)
        try testP256NeutralElementDecoding();
    if (do_test.p256_double_base_multiplication)
        try testP256DoubleBaseMultiplication();
    if (do_test.p256_double_base_multiplication_with_large_scalars)
        try testP256DoubleBaseMultiplicationWithLargeScalars();
    if (do_test.p256_scalar_inverse)
        try testP256ScalarInverse();
    if (do_test.p384_ecdh_key_exchange)
        try testP384ECDHKeyExchange();
    if (do_test.p384_point_from_affine_coordinates)
        try testP384PointFromAffineCoordinates();
    if (do_test.p384_test_vectors)
        try testP384TestVectors();
    if (do_test.p384_test_vectors_doubling)
        try testP384TestVectorsDoubling();
    if (do_test.p384_compressed_sec1_encoding_decoding)
        try testP384CompressedSec1EncodingDecoding();
    if (do_test.p384_uncompressed_sec1_encoding_decoding)
        try testP384UncompressedSec1EncodingDecoding();
    if (do_test.p384_public_key_is_the_neutral_element)
        try testP384PublicKeyIsTheNeutralElement();
    if (do_test.p384_public_key_is_the_neutral_element_public_verification)
        try testP384PublicKeyIsTheNeutralElementPublicVerification();
    if (do_test.p384_field_element_non_canonical_encoding)
        try testP384FieldElementNonCanonicalEncoding();
    if (do_test.p384_neutral_element_decoding)
        try testP384NeutralElementDecoding();
    if (do_test.p384_double_base_multiplication)
        try testP384DoubleBaseMultiplication();
    if (do_test.p384_double_base_multiplication_with_large_scalars)
        try testP384DoubleBaseMultiplicationWithLargeScalars();
    if (do_test.p384_scalar_inverse)
        try testP384ScalarInverse();
    if (do_test.secp256k1_ecdh_key_exchange)
        try testSecp256k1ECDHKeyExchange();
    if (do_test.secp256k1_ecdh_key_exchange_including_public_multiplication)
        try testSecp256k1ECDHKeyExchangeIncludingPublicMultiplication();
    if (do_test.secp256k1_point_from_affine_coordinates)
        try testSecp256k1PointFromAffineCoordinates();
    if (do_test.secp256k1_test_vectors)
        try testSecp256k1TestVectors();
    if (do_test.secp256k1_test_vectors_doubling)
        try testSecp256k1TestVectorsDoubling();
    if (do_test.secp256k1_compressed_sec1_encoding_decoding)
        try testSecp256k1CompressedSec1EncodingDecoding();
    if (do_test.secp256k1_uncompressed_sec1_encoding_decoding)
        try testSecp256k1UncompressedSec1EncodingDecoding();
    if (do_test.secp256k1_public_key_is_the_neutral_element)
        try testSecp256k1PublicKeyIsTheNeutralElement();
    if (do_test.secp256k1_public_key_is_the_neutral_element_public_verification)
        try testSecp256k1PublicKeyIsTheNeutralElementPublicVerification();
    if (do_test.secp256k1_field_element_non_canonical_encoding)
        try testSecp256k1FieldElementNonCanonicalEncoding();
    if (do_test.secp256k1_neutral_element_decoding)
        try testSecp256k1NeutralElementDecoding();
    if (do_test.secp256k1_double_base_multiplication)
        try testSecp256k1DoubleBaseMultiplication();
    if (do_test.secp256k1_scalar_inverse)
        try testSecp256k1ScalarInverse();
}
pub const main = pcurveTestMain;
