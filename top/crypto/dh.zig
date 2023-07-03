const mem = @import("../mem.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
const tab = @import("./tab.zig");
const hash = @import("./hash.zig");
const utils = @import("./utils.zig");
const errors = @import("./errors.zig");
const scalar = @import("./scalar.zig");
const pcurves = @import("./pcurves.zig");
pub const Curve25519 = struct {
    x: Fe,
    pub fn fromBytes(s: [32]u8) Curve25519 {
        return .{ .x = Fe.fromBytes(s) };
    }
    pub fn toBytes(p: Curve25519) [32]u8 {
        return p.x.toBytes();
    }
    pub const base_point: Curve25519 = .{ .x = Fe.curve25519_base_point };
    pub fn rejectNonCanonical(s: [32]u8) !void {
        return Fe.rejectNonCanonical(s, false);
    }
    pub fn rejectIdentity(p: Curve25519) !void {
        if (p.x.isZero()) {
            return error.IdentityElement;
        }
    }
    pub fn clearCofactor(p: Curve25519) !Curve25519 {
        const cofactor: [32]u8 = [_]u8{8} ++ [_]u8{0} ** 31;
        return ladder(p, cofactor, 4) catch return error.WeakPublicKey;
    }
    fn ladder(p: Curve25519, s: [32]u8, comptime bits: usize) !Curve25519 {
        var x1: Fe = p.x;
        var x2: Fe = Fe.one;
        var z2: Fe = Fe.zero;
        var x3: Fe = x1;
        var z3: Fe = Fe.one;
        var swap: u8 = 0;
        var pos: usize = bits -% 1;
        while (true) : (pos -%= 1) {
            const bit: u8 = (s[pos >> 3] >> @as(u3, @truncate(pos))) & 1;
            swap ^= bit;
            Fe.cSwap2(&x2, &x3, &z2, &z3, swap);
            swap = bit;
            const a: Fe = x2.add(z2);
            const b: Fe = x2.sub(z2);
            const aa: Fe = a.sq();
            const bb: Fe = b.sq();
            x2 = aa.mul(bb);
            const e: Fe = aa.sub(bb);
            const da: Fe = x3.sub(z3).mul(a);
            const cb: Fe = x3.add(z3).mul(b);
            x3 = da.add(cb).sq();
            z3 = x1.mul(da.sub(cb).sq());
            z2 = e.mul(bb.add(e.mul32(121666)));
            if (pos == 0) break;
        }
        Fe.cSwap2(&x2, &x3, &z2, &z3, swap);
        z2 = z2.invert();
        x2 = x2.mul(z2);
        if (x2.isZero()) {
            return error.IdentityElement;
        }
        return Curve25519{ .x = x2 };
    }
    pub fn clampedMul(p: Curve25519, s: [32]u8) !Curve25519 {
        var t: [32]u8 = s;
        scalar.clamp(&t);
        return try ladder(p, t, 255);
    }
    pub fn mul(p: Curve25519, s: [32]u8) !Curve25519 {
        _ = try p.clearCofactor();
        return try ladder(p, s, 256);
    }
    pub fn fromEdwards25519(p: Edwards25519) !Curve25519 {
        try p.clearCofactor().rejectIdentity();
        const one: Fe = Fe.one;
        const x: Fe = one.add(p.y).mul(one.sub(p.y).invert()); // xMont=(1+yEd)/(1-yEd)
        return Curve25519{ .x = x };
    }
};
pub const Ed25519 = struct {
    pub const noise_len: comptime_int = 32;
    pub const SecretKey = struct {
        pub const encoded_len: comptime_int = 64;
        bytes: [encoded_len]u8,
        pub fn seed(secret: SecretKey) [KeyPair.seed_len]u8 {
            return secret.bytes[0..KeyPair.seed_len].*;
        }
        pub fn publicKeyBytes(secret: SecretKey) [PublicKey.encoded_len]u8 {
            return secret.bytes[KeyPair.seed_len..].*;
        }
        pub fn fromBytes(bytes: [encoded_len]u8) !SecretKey {
            return SecretKey{ .bytes = bytes };
        }
        pub fn toBytes(sk: SecretKey) [encoded_len]u8 {
            return sk.bytes;
        }
        fn scalarAndPrefix(secret: SecretKey) struct { compressed: scalar.CompressedScalar, prefix: [32]u8 } {
            var az: [hash.Sha512.len]u8 = undefined;
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&secret.seed());
            h.final(&az);
            var s: [32]u8 = az[0..32].*;
            scalar.clamp(&s);
            return .{ .compressed = s, .prefix = az[32..].* };
        }
    };
    pub const Signer = struct {
        h: hash.Sha512,
        compressed: scalar.CompressedScalar,
        nonce: scalar.CompressedScalar,
        r_bytes: [Edwards25519.encoded_len]u8,
        fn init(compressed: scalar.CompressedScalar, nonce: scalar.CompressedScalar, public_key: PublicKey) !Signer {
            const r: Edwards25519 = try Edwards25519.base_point.mul(nonce);
            const r_bytes: [Edwards25519.encoded_len]u8 = r.toBytes();
            var t: [64]u8 = undefined;
            t[0..32].* = r_bytes;
            t[32..].* = public_key.bytes;
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&t);
            return .{ .h = h, .compressed = compressed, .nonce = nonce, .r_bytes = r_bytes };
        }
        pub fn update(signer: *Signer, data: []const u8) void {
            signer.h.update(data);
        }
        pub fn finalize(signer: *Signer) Signature {
            var hram64: [hash.Sha512.len]u8 = undefined;
            signer.h.final(&hram64);
            const hram: scalar.CompressedScalar = scalar.reduce64(hram64);
            const s: scalar.CompressedScalar = scalar.mulAdd(hram, signer.compressed, signer.nonce);
            return Signature{ .r = signer.r_bytes, .s = s };
        }
    };
    pub const PublicKey = struct {
        pub const encoded_len: comptime_int = 32;
        bytes: [encoded_len]u8,
        pub fn fromBytes(bytes: [encoded_len]u8) !PublicKey {
            try Edwards25519.rejectNonCanonical(bytes);
            return PublicKey{ .bytes = bytes };
        }
        pub fn toBytes(pk: PublicKey) [encoded_len]u8 {
            return pk.bytes;
        }
        fn signWithNonce(public_key: PublicKey, msg: []const u8, compressed: scalar.CompressedScalar, nonce: scalar.CompressedScalar) (errors.IdentityElementError ||
            errors.NonCanonicalError || errors.KeyMismatchError || errors.WeakPublicKeyError)!Signature {
            var st: Signer = try Signer.init(compressed, nonce, public_key);
            st.update(msg);
            return st.finalize();
        }
        fn computeNonceAndSign(public_key: PublicKey, msg: []const u8, noise: ?[noise_len]u8, compressed: scalar.CompressedScalar, prefix: []const u8) !Signature {
            var h: hash.Sha512 = hash.Sha512.init();
            if (noise) |*z| {
                h.update(z);
            }
            h.update(prefix);
            h.update(msg);
            var nonce64: [64]u8 = undefined;
            h.final(&nonce64);
            const nonce: scalar.CompressedScalar = scalar.reduce64(nonce64);
            return public_key.signWithNonce(msg, compressed, nonce);
        }
    };
    pub const Verifier = struct {
        h: hash.Sha512,
        s: scalar.CompressedScalar,
        a: Edwards25519,
        expected_r: Edwards25519,
        fn init(sig: Signature, public_key: PublicKey) !Verifier {
            const r: [Edwards25519.encoded_len]u8 = sig.r;
            const s: scalar.CompressedScalar = sig.s;
            try scalar.rejectNonCanonical(s);
            const a: Edwards25519 = try Edwards25519.fromBytes(public_key.bytes);
            try a.rejectIdentity();
            try Edwards25519.rejectNonCanonical(r);
            const expected_r: Edwards25519 = try Edwards25519.fromBytes(r);
            try expected_r.rejectIdentity();
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&r);
            h.update(&public_key.bytes);
            return Verifier{ .h = h, .s = s, .a = a, .expected_r = expected_r };
        }
        pub fn update(verifier: *Verifier, msg: []const u8) void {
            verifier.h.update(msg);
        }
        pub fn verify(verifier: *Verifier) !void {
            var hram64: [hash.Sha512.len]u8 = undefined;
            verifier.h.final(&hram64);
            const hram: scalar.CompressedScalar = scalar.reduce64(hram64);
            const sb_ah: Edwards25519 = try Edwards25519.base_point.mulDoubleBasePublic(verifier.s, verifier.a.neg(), hram);
            if (verifier.expected_r.sub(sb_ah).rejectLowOrder()) {
                return error.SignatureVerificationFailed;
            } else |_| {}
        }
    };
    pub const Signature = struct {
        pub const encoded_len: comptime_int = Edwards25519.encoded_len +% @sizeOf(scalar.CompressedScalar);
        r: [Edwards25519.encoded_len]u8,
        s: scalar.CompressedScalar,
        pub fn toBytes(signature: Signature) [encoded_len]u8 {
            var bytes: [encoded_len]u8 = undefined;
            bytes[0 .. encoded_len / 2].* = signature.r;
            bytes[encoded_len / 2 ..].* = signature.s;
            return bytes;
        }
        pub fn fromBytes(bytes: [encoded_len]u8) Signature {
            return Signature{
                .r = bytes[0 .. encoded_len / 2].*,
                .s = bytes[encoded_len / 2 ..].*,
            };
        }
        pub fn verifier(signature: Signature, public_key: PublicKey) !Verifier {
            return Verifier.init(signature, public_key);
        }
        pub fn verify(signature: Signature, msg: []const u8, public_key: PublicKey) !void {
            var st: Verifier = try Verifier.init(signature, public_key);
            st.update(msg);
            return st.verify();
        }
    };
    pub const KeyPair = struct {
        pub const seed_len: comptime_int = noise_len;
        public_key: PublicKey,
        secret_key: SecretKey,
        pub fn create(seed: ?[seed_len]u8) !KeyPair {
            const ss: [seed_len]u8 = seed orelse ss: {
                var random_seed: [seed_len]u8 = undefined;
                utils.bytes(&random_seed);
                break :ss random_seed;
            };
            var az: [hash.Sha512.len]u8 = undefined;
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&ss);
            h.final(&az);
            const pk_p: Edwards25519 = Edwards25519.base_point.clampedMul(az[0..32].*) catch return error.IdentityElement;
            const pk_bytes: [Edwards25519.encoded_len]u8 = pk_p.toBytes();
            var sk_bytes: [SecretKey.encoded_len]u8 = undefined;
            sk_bytes[0..ss.len].* = ss;
            sk_bytes[seed_len..].* = pk_bytes;
            return KeyPair{
                .public_key = PublicKey.fromBytes(pk_bytes) catch undefined,
                .secret_key = try SecretKey.fromBytes(sk_bytes),
            };
        }
        pub fn fromSecretKey(secret_key: SecretKey) !KeyPair {
            return KeyPair{
                .public_key = try PublicKey.fromBytes(secret_key.publicKeyBytes()),
                .secret_key = secret_key,
            };
        }
        pub fn sign(key_pair: KeyPair, msg: []const u8, noise: ?[noise_len]u8) !Signature {
            if (!mem.testEqualMany(u8, &key_pair.secret_key.publicKeyBytes(), &key_pair.public_key.toBytes())) {
                return error.KeyMismatch;
            }
            const scalar_and_prefix = key_pair.secret_key.scalarAndPrefix();
            return key_pair.public_key.computeNonceAndSign(
                msg,
                noise,
                scalar_and_prefix.compressed,
                &scalar_and_prefix.prefix,
            );
        }
        pub fn signer(key_pair: KeyPair, noise: ?[noise_len]u8) !Signer {
            if (!mem.testEqualMany(u8, &key_pair.secret_key.publicKeyBytes(), &key_pair.public_key.toBytes())) {
                return error.KeyMismatch;
            }
            const scalar_and_prefix = key_pair.secret_key.scalarAndPrefix();
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&scalar_and_prefix.prefix);
            var noise2: [noise_len]u8 = undefined;
            utils.bytes(&noise2);
            h.update(&noise2);
            if (noise) |*z| {
                h.update(z);
            }
            var nonce64: [64]u8 = undefined;
            h.final(&nonce64);
            const nonce: scalar.CompressedScalar = scalar.reduce64(nonce64);
            return Signer.init(scalar_and_prefix.compressed, nonce, key_pair.public_key);
        }
    };
    pub const BatchElement = struct {
        sig: Signature,
        msg: []const u8,
        public_key: PublicKey,
    };
    pub fn verifyBatch(comptime count: usize, signature_batch: [count]BatchElement) !void {
        var r_batch: [count]scalar.CompressedScalar = undefined;
        var s_batch: [count]scalar.CompressedScalar = undefined;
        var a_batch: [count]Edwards25519 = undefined;
        var expected_r_batch: [count]Edwards25519 = undefined;
        for (signature_batch, 0..) |signature, i| {
            const r: [Edwards25519.encoded_len]u8 = signature.sig.r;
            const s: scalar.CompressedScalar = signature.sig.s;
            try scalar.rejectNonCanonical(s);
            const a: Edwards25519 = try Edwards25519.fromBytes(signature.public_key.bytes);
            try a.rejectIdentity();
            try Edwards25519.rejectNonCanonical(r);
            const expected_r: Edwards25519 = try Edwards25519.fromBytes(r);
            try expected_r.rejectIdentity();
            expected_r_batch[i] = expected_r;
            r_batch[i] = r;
            s_batch[i] = s;
            a_batch[i] = a;
        }
        var hram_batch: [count]scalar.CompressedScalar = undefined;
        for (signature_batch, 0..) |signature, i| {
            var h: hash.Sha512 = hash.Sha512.init();
            h.update(&r_batch[i]);
            h.update(&signature.public_key.bytes);
            h.update(signature.msg);
            var hram64: [hash.Sha512.len]u8 = undefined;
            h.final(&hram64);
            hram_batch[i] = scalar.reduce64(hram64);
        }
        var z_batch: [count]scalar.CompressedScalar = undefined;
        for (&z_batch) |*z| {
            utils.bytes(z[0..16]);
            @memset(z[16..], 0);
        }
        var zs_sum: [32]u8 = scalar.zero;
        for (z_batch, 0..) |z, i| {
            const zs: scalar.CompressedScalar = scalar.mul(z, s_batch[i]);
            zs_sum = scalar.add(zs_sum, zs);
        }
        zs_sum = scalar.mul8(zs_sum);
        var zhs: [count]scalar.CompressedScalar = undefined;
        for (z_batch, 0..) |z, i| {
            zhs[i] = scalar.mul(z, hram_batch[i]);
        }
        const zr: Edwards25519 = (try Edwards25519.mulMulti(count, expected_r_batch, z_batch)).clearCofactor();
        const zah: Edwards25519 = (try Edwards25519.mulMulti(count, a_batch, zhs)).clearCofactor();
        const zsb: Edwards25519 = try Edwards25519.base_point.mulPublic(zs_sum);
        if (zr.add(zah).sub(zsb).rejectIdentity()) |_| {
            return error.SignatureVerificationFailed;
        } else |_| {}
    }
    pub const key_blinding = struct {
        pub const blind_seed_len: comptime_int = 32;
        pub const BlindSecretKey = struct {
            prefix: [64]u8,
            blind_scalar: scalar.CompressedScalar,
            blind_public_key: BlindPublicKey,
        };
        pub const BlindPublicKey = struct {
            key: PublicKey,
            pub fn unblind(blind_public_key: BlindPublicKey, blind_seed: [blind_seed_len]u8, ctx: []const u8) !PublicKey {
                const blind_h: [hash.Sha512.len]u8 = blindCtx(blind_seed, ctx);
                const inv_blind_factor: scalar.CompressedScalar = scalar.Scalar.fromBytes(blind_h[0..32].*).invert().toBytes();
                const pk_p: Edwards25519 = try (try Edwards25519.fromBytes(blind_public_key.key.bytes)).mul(inv_blind_factor);
                return PublicKey.fromBytes(pk_p.toBytes());
            }
        };
        pub const BlindKeyPair = struct {
            blind_public_key: BlindPublicKey,
            blind_secret_key: BlindSecretKey,
            pub fn init(key_pair: Ed25519.KeyPair, blind_seed: [blind_seed_len]u8, ctx: []const u8) !BlindKeyPair {
                var h: [hash.Sha512.len]u8 = undefined;
                hash.Sha512.hash(&key_pair.secret_key.seed(), &h);
                scalar.clamp(h[0..32]);
                const compressed: scalar.CompressedScalar = scalar.reduce(h[0..32].*);
                const blind_h: [hash.Sha512.len]u8 = blindCtx(blind_seed, ctx);
                const blind_factor: scalar.CompressedScalar = scalar.reduce(blind_h[0..32].*);
                const blind_scalar: scalar.CompressedScalar = scalar.mul(compressed, blind_factor);
                const blind_public_key: BlindPublicKey = .{
                    .key = try PublicKey.fromBytes((Edwards25519.base_point.mul(blind_scalar) catch return error.IdentityElement).toBytes()),
                };
                var prefix: [64]u8 = undefined;
                prefix[0..32].* = h[32..64].*;
                prefix[32..64].* = blind_h[32..64].*;
                const blind_secret_key: BlindSecretKey = .{
                    .prefix = prefix,
                    .blind_scalar = blind_scalar,
                    .blind_public_key = blind_public_key,
                };
                return .{
                    .blind_public_key = blind_public_key,
                    .blind_secret_key = blind_secret_key,
                };
            }
            pub fn sign(key_pair: BlindKeyPair, msg: []const u8, noise: ?[noise_len]u8) !Signature {
                return (try PublicKey.fromBytes(key_pair.blind_public_key.key.bytes))
                    .computeNonceAndSign(msg, noise, key_pair.blind_secret_key.blind_scalar, &key_pair.blind_secret_key.prefix);
            }
        };
        fn blindCtx(blind_seed: [blind_seed_len]u8, ctx: []const u8) [hash.Sha512.len]u8 {
            var blind_h: [hash.Sha512.len]u8 = undefined;
            var hx: hash.Sha512 = hash.Sha512.init();
            hx.update(&blind_seed);
            hx.update(&[1]u8{0});
            hx.update(ctx);
            hx.final(&blind_h);
            return blind_h;
        }
    };
};
pub const Edwards25519 = struct {
    x: Fe,
    y: Fe,
    z: Fe,
    t: Fe,
    is_base: bool = false,
    pub const encoded_len: comptime_int = 32;
    pub fn fromBytes(s: [encoded_len]u8) !Edwards25519 {
        const z: Fe = Fe.one;
        const y: Fe = Fe.fromBytes(s);
        var u: Fe = y.sq();
        var v: Fe = u.mul(Fe.edwards25519d);
        u = u.sub(z);
        v = v.add(z);
        var x: Fe = u.mul(v).pow2523().mul(u);
        const vxx: Fe = x.sq().mul(v);
        const has_m_root: bool = vxx.sub(u).isZero();
        const has_p_root: bool = vxx.add(u).isZero();
        if ((@intFromBool(has_m_root) | @intFromBool(has_p_root)) == 0) { // best-effort to avoid two conditional branches
            return error.InvalidEncoding;
        }
        x.cMov(x.mul(Fe.sqrtm1), 1 -% @intFromBool(has_m_root));
        x.cMov(x.neg(), @intFromBool(x.isNegative()) ^ (s[31] >> 7));
        const t: Fe = x.mul(y);
        return Edwards25519{ .x = x, .y = y, .z = z, .t = t };
    }
    pub fn toBytes(p: Edwards25519) [encoded_len]u8 {
        const zi: Fe = p.z.invert();
        var s: [32]u8 = p.y.mul(zi).toBytes();
        s[31] ^= @as(u8, @intFromBool(p.x.mul(zi).isNegative())) << 7;
        return s;
    }
    pub fn rejectNonCanonical(s: [32]u8) !void {
        return Fe.rejectNonCanonical(s, true);
    }
    pub const base_point: Edwards25519 = .{
        .x = Fe{ .limbs = .{ 1738742601995546, 1146398526822698, 2070867633025821, 562264141797630, 587772402128613 } },
        .y = Fe{ .limbs = .{ 1801439850948184, 1351079888211148, 450359962737049, 900719925474099, 1801439850948198 } },
        .z = Fe.one,
        .t = Fe{ .limbs = .{ 1841354044333475, 16398895984059, 755974180946558, 900171276175154, 1821297809914039 } },
        .is_base = true,
    };
    pub const identity_element: Edwards25519 = .{
        .x = Fe.zero,
        .y = Fe.one,
        .z = Fe.one,
        .t = Fe.zero,
    };
    pub fn rejectIdentity(p: Edwards25519) !void {
        if (p.x.isZero()) {
            return error.IdentityElement;
        }
    }
    pub fn clearCofactor(p: Edwards25519) Edwards25519 {
        return p.dbl().dbl().dbl();
    }
    pub fn rejectLowOrder(p: Edwards25519) !void {
        const zi: Fe = p.z.invert();
        const x: Fe = p.x.mul(zi);
        const y: Fe = p.y.mul(zi);
        const x_neg: Fe = x.neg();
        const iy: Fe = Fe.sqrtm1.mul(y);
        if (x.isZero() or y.isZero() or iy.equivalent(x) or iy.equivalent(x_neg)) {
            return error.WeakPublicKey;
        }
    }
    pub fn neg(p: Edwards25519) Edwards25519 {
        return .{ .x = p.x.neg(), .y = p.y, .z = p.z, .t = p.t.neg() };
    }
    pub fn dbl(p: Edwards25519) Edwards25519 {
        const t0: Fe = p.x.add(p.y).sq();
        var x: Fe = p.x.sq();
        var z: Fe = p.y.sq();
        const y: Fe = z.add(x);
        z = z.sub(x);
        x = t0.sub(y);
        const t: Fe = p.z.sq2().sub(z);
        return .{
            .x = x.mul(t),
            .y = y.mul(z),
            .z = z.mul(t),
            .t = x.mul(y),
        };
    }
    pub fn add(p: Edwards25519, q: Edwards25519) Edwards25519 {
        const a: Fe = p.y.sub(p.x).mul(q.y.sub(q.x));
        const b: Fe = p.x.add(p.y).mul(q.x.add(q.y));
        const c: Fe = p.t.mul(q.t).mul(Fe.edwards25519d2);
        var d: Fe = p.z.mul(q.z);
        d = d.add(d);
        const x: Fe = b.sub(a);
        const y: Fe = b.add(a);
        const z: Fe = d.add(c);
        const t: Fe = d.sub(c);
        return .{
            .x = x.mul(t),
            .y = y.mul(z),
            .z = z.mul(t),
            .t = x.mul(y),
        };
    }
    pub fn sub(p: Edwards25519, q: Edwards25519) Edwards25519 {
        return p.add(q.neg());
    }
    fn cMov(p: *Edwards25519, a: Edwards25519, c: u64) void {
        p.x.cMov(a.x, c);
        p.y.cMov(a.y, c);
        p.z.cMov(a.z, c);
        p.t.cMov(a.t, c);
    }
    fn pcSelect(comptime n: usize, pc: *const [n]Edwards25519, b: u8) Edwards25519 {
        var t: Edwards25519 = Edwards25519.identity_element;
        comptime var idx: u8 = 1;
        inline while (idx < pc.len) : (idx +%= 1) {
            t.cMov(pc[idx], ((@as(usize, b ^ idx) -% 1) >> 8) & 1);
        }
        return t;
    }
    fn slide(s: [32]u8) [2 *% 32]i8 {
        const reduced: scalar.CompressedScalar = if ((s[s.len -% 1] & 0x80) == 0) s else scalar.reduce(s);
        var e: [2 *% 32]i8 = undefined;
        for (reduced, 0..) |x, i| {
            e[i *% 2 +% 0] = @as(i8, @as(u4, @truncate(x)));
            e[i *% 2 +% 1] = @as(i8, @as(u4, @truncate(x >> 4)));
        }
        // Now, e[0..63] is between 0 and 15, e[63] is between 0 and 7
        var carry: i8 = 0;
        for (e[0..63]) |*x| {
            x.* +%= carry;
            carry = (x.* +% 8) >> 4;
            x.* -%= carry *% 16;
        }
        e[63] +%= carry;
        // Now, e[*] is between -8 and 8, including e[63]
        return e;
    }
    // Scalar multiplication with a 4-bit window and the first 8 multiples.
    // This requires the scalar to be converted to non-adjacent form.
    // Based on real-world benchmarks, we only use this for multi-scalar multiplication.
    // NAF could be useful to half the size of precomputation tables, but we intentionally
    // avoid these to keep the standard library lightweight.
    fn pcMul(pc: *const [9]Edwards25519, s: [32]u8, comptime vartime: bool) !Edwards25519 {
        builtin.assert(vartime);
        const e: [64]i8 = slide(s);
        var q: Edwards25519 = Edwards25519.identity_element;
        var pos: usize = 2 *% 32 -% 1;
        while (true) : (pos -%= 1) {
            const slot: i8 = e[pos];
            if (slot > 0) {
                q = q.add(pc[@as(usize, @intCast(slot))]);
            } else if (slot < 0) {
                q = q.sub(pc[@as(usize, @intCast(-slot))]);
            }
            if (pos == 0) break;
            q = q.dbl().dbl().dbl().dbl();
        }
        try q.rejectIdentity();
        return q;
    }
    // Scalar multiplication with a 4-bit window and the first 15 multiples.
    fn pcMul16(pc: *const [16]Edwards25519, s: [32]u8, comptime vartime: bool) !Edwards25519 {
        var q: Edwards25519 = Edwards25519.identity_element;
        var pos: usize = 252;
        while (true) : (pos -%= 4) {
            const slot: u4 = @as(u4, @truncate((s[pos >> 3] >> @as(u3, @truncate(pos)))));
            if (vartime) {
                if (slot != 0) {
                    q = q.add(pc[slot]);
                }
            } else {
                q = q.add(pcSelect(16, pc, slot));
            }
            if (pos == 0) break;
            q = q.dbl().dbl().dbl().dbl();
        }
        try q.rejectIdentity();
        return q;
    }
    fn precompute(p: Edwards25519, comptime count: usize) [1 +% count]Edwards25519 {
        var pc: [1 +% count]Edwards25519 = undefined;
        pc[0] = Edwards25519.identity_element;
        pc[1] = p;
        var i: usize = 2;
        while (i <= count) : (i +%= 1) {
            pc[i] = if (i % 2 == 0) pc[i / 2].dbl() else pc[i -% 1].add(p);
        }
        return pc;
    }
    const base_point_pc: [16]Edwards25519 = tab.base_point_pc_edwards25519;
    pub fn mul(p: Edwards25519, s: [32]u8) !Edwards25519 {
        const pc: [16]Edwards25519 = if (p.is_base) base_point_pc else pc: {
            const xpc: [16]Edwards25519 = precompute(p, 15);
            xpc[4].rejectIdentity() catch return error.WeakPublicKey;
            break :pc xpc;
        };
        return pcMul16(&pc, s, false);
    }
    pub fn mulPublic(p: Edwards25519, s: [32]u8) !Edwards25519 {
        if (p.is_base) {
            return pcMul16(&base_point_pc, s, true);
        } else {
            const pc: [9]Edwards25519 = precompute(p, 8);
            pc[4].rejectIdentity() catch return error.WeakPublicKey;
            return pcMul(&pc, s, true);
        }
    }
    pub fn mulDoubleBasePublic(p1: Edwards25519, s1: [32]u8, p2: Edwards25519, s2: [32]u8) !Edwards25519 {
        var pc1_array: [9]Edwards25519 = undefined;
        const pc1: *const [9]Edwards25519 = if (p1.is_base) base_point_pc[0..9] else pc: {
            pc1_array = precompute(p1, 8);
            pc1_array[4].rejectIdentity() catch return error.WeakPublicKey;
            break :pc &pc1_array;
        };
        var pc2_array: [9]Edwards25519 = undefined;
        const pc2: *const [9]Edwards25519 = if (p2.is_base) base_point_pc[0..9] else pc: {
            pc2_array = precompute(p2, 8);
            pc2_array[4].rejectIdentity() catch return error.WeakPublicKey;
            break :pc &pc2_array;
        };
        const e1: [64]i8 = slide(s1);
        const e2: [64]i8 = slide(s2);
        var q: Edwards25519 = Edwards25519.identity_element;
        var pos: usize = (2 *% 32) -% 1;
        while (true) : (pos -%= 1) {
            const slot1: i8 = e1[pos];
            if (slot1 > 0) {
                q = q.add(pc1[@as(usize, @intCast(slot1))]);
            } else if (slot1 < 0) {
                q = q.sub(pc1[@as(usize, @intCast(-slot1))]);
            }
            const slot2: i8 = e2[pos];
            if (slot2 > 0) {
                q = q.add(pc2[@as(usize, @intCast(slot2))]);
            } else if (slot2 < 0) {
                q = q.sub(pc2[@as(usize, @intCast(-slot2))]);
            }
            if (pos == 0) break;
            q = q.dbl().dbl().dbl().dbl();
        }
        try q.rejectIdentity();
        return q;
    }
    pub fn mulMulti(comptime count: usize, ps: [count]Edwards25519, ss: [count][32]u8) !Edwards25519 {
        var pcs: [count][9]Edwards25519 = undefined;
        var bpc: [9]Edwards25519 = undefined;
        @memcpy(&bpc, base_point_pc[0..bpc.len]);
        for (ps, 0..) |p, i| {
            if (p.is_base) {
                pcs[i] = bpc;
            } else {
                pcs[i] = precompute(p, 8);
                pcs[i][4].rejectIdentity() catch return error.WeakPublicKey;
            }
        }
        var es: [count][2 *% 32]i8 = undefined;
        for (ss, 0..) |s, i| {
            es[i] = slide(s);
        }
        var q: Edwards25519 = Edwards25519.identity_element;
        var pos: usize = 2 *% 32 -% 1;
        while (true) : (pos -%= 1) {
            for (es, 0..) |e, i| {
                const slot: i8 = e[pos];
                if (slot > 0) {
                    q = q.add(pcs[i][@as(usize, @intCast(slot))]);
                } else if (slot < 0) {
                    q = q.sub(pcs[i][@as(usize, @intCast(-slot))]);
                }
            }
            if (pos == 0) break;
            q = q.dbl().dbl().dbl().dbl();
        }
        try q.rejectIdentity();
        return q;
    }
    pub fn clampedMul(p: Edwards25519, s: [32]u8) !Edwards25519 {
        var t: [32]u8 = s;
        scalar.clamp(&t);
        return mul(p, t);
    }
    // montgomery -- recover y = sqrt(x^3 +% A*x^2 +% x)
    fn xmontToYmont(x: Fe) !Fe {
        var x2: Fe = x.sq();
        const x3: Fe = x.mul(x2);
        x2 = x2.mul32(Fe.edwards25519a_32);
        return x.add(x2).add(x3).sqrt();
    }
    // montgomery affine coordinates to edwards extended coordinates
    fn montToEd(x: Fe, y: Fe) Edwards25519 {
        const x_plus_one: Fe = x.add(Fe.one);
        const x_minus_one: Fe = x.sub(Fe.one);
        const x_plus_one_y_inv: Fe = x_plus_one.mul(y).invert(); // 1/((x+1)*y)
        // xed = sqrt(-A-2)*x/y
        const xed: Fe = x.mul(Fe.edwards25519sqrtam2).mul(x_plus_one_y_inv).mul(x_plus_one);
        // yed = (x-1)/(x+1) or 1 if the denominator is 0
        var yed: Fe = x_plus_one_y_inv.mul(y).mul(x_minus_one);
        yed.cMov(Fe.one, @intFromBool(x_plus_one_y_inv.isZero()));
        return Edwards25519{
            .x = xed,
            .y = yed,
            .z = Fe.one,
            .t = xed.mul(yed),
        };
    }
    pub fn elligator2(r: Fe) struct { x: Fe, y: Fe, not_square: bool } {
        const rr2: Fe = r.sq2().add(Fe.one).invert();
        var x: Fe = rr2.mul32(Fe.edwards25519a_32).neg(); // x=x1
        var x2: Fe = x.sq();
        const x3: Fe = x2.mul(x);
        x2 = x2.mul32(Fe.edwards25519a_32); // x2 = A*x1^2
        const gx1: Fe = x3.add(x).add(x2); // gx1 = x1^3 +% A*x1^2 +% x1
        const not_square: bool = !gx1.isSquare();
        // gx1 not a square => x = -x1-A
        x.cMov(x.neg(), @intFromBool(not_square));
        x2 = Fe.zero;
        x2.cMov(Fe.edwards25519a, @intFromBool(not_square));
        x = x.sub(x2);
        // We have y = sqrt(gx1) or sqrt(gx2) with gx2 = gx1*(A+x1)/(-x1)
        // but it is about as fast to just recompute y from the curve equation.
        const y: Fe = xmontToYmont(x) catch undefined;
        return .{ .x = x, .y = y, .not_square = not_square };
    }
    pub fn fromHash(h: [64]u8) Edwards25519 {
        const fe_f: Fe = Fe.fromBytes64(h);
        var elr = elligator2(fe_f);
        const y_sign: bool = !elr.not_square;
        const y_neg: Fe = elr.y.neg();
        elr.y.cMov(y_neg, @intFromBool(elr.y.isNegative()) ^ @intFromBool(y_sign));
        return montToEd(elr.x, elr.y).clearCofactor();
    }
    fn stringToPoints(comptime n: usize, ctx: []const u8, s: []const u8) [n]Edwards25519 {
        builtin.assert(n <= 2);
        const h_l: usize = 48;
        var xctx: []const u8 = ctx;
        var hctx: [hash.Sha512.len]u8 = undefined;
        if (ctx.len > 0xff) {
            var st: hash.Sha512 = hash.Sha512.init();
            st.update("H2C-OVERSIZE-DST-");
            st.update(ctx);
            st.final(&hctx);
            xctx = hctx[0..];
        }
        const empty_block: [hash.Sha512.blk_len]u8 = [1]u8{0} ** hash.Sha512.blk_len;
        var t: [3]u8 = .{ 0, n *% h_l, 0 };
        var xctx_len_u8: [1]u8 = .{@as(u8, @intCast(xctx.len))};
        var st: hash.Sha512 = hash.Sha512.init();
        st.update(empty_block[0..]);
        st.update(s);
        st.update(t[0..]);
        st.update(xctx);
        st.update(xctx_len_u8[0..]);
        var u_0: [hash.Sha512.len]u8 = undefined;
        st.final(&u_0);
        var u: [n *% hash.Sha512.len]u8 = undefined;
        var i: usize = 0;
        while (i < n *% hash.Sha512.len) : (i +%= hash.Sha512.len) {
            u[i..][0..hash.Sha512.len].* = u_0;
            var j: usize = 0;
            while (i > 0 and j < hash.Sha512.len) : (j +%= 1) {
                u[i +% j] ^= u[i +% j -% hash.Sha512.len];
            }
            t[2] +%= 1;
            st = hash.Sha512.init();
            st.update(u[i..][0..hash.Sha512.len]);
            st.update(t[2..3]);
            st.update(xctx);
            st.update(xctx_len_u8[0..]);
            st.final(u[i..][0..hash.Sha512.len]);
        }
        var px: [n]Edwards25519 = undefined;
        i = 0;
        while (i < n) : (i +%= 1) {
            @memset(u_0[0 .. hash.Sha512.len -% h_l], 0);
            u_0[hash.Sha512.len -% h_l ..][0..h_l].* = u[i *% h_l ..][0..h_l].*;
            px[i] = fromHash(u_0);
        }
        return px;
    }
    pub fn fromString(comptime random_oracle: bool, ctx: []const u8, s: []const u8) Edwards25519 {
        if (random_oracle) {
            const px: [2]Edwards25519 = stringToPoints(2, ctx, s);
            return px[0].add(px[1]);
        } else {
            return stringToPoints(1, ctx, s)[0];
        }
    }
    pub fn fromUniform(r: [32]u8) Edwards25519 {
        var s: [32]u8 = r;
        const x_sign: u8 = s[31] >> 7;
        s[31] &= 0x7f;
        const elr = elligator2(Fe.fromBytes(s));
        var p: Edwards25519 = montToEd(elr.x, elr.y);
        const p_neg: Edwards25519 = p.neg();
        p.cMov(p_neg, @intFromBool(p.x.isNegative()) ^ x_sign);
        return p.clearCofactor();
    }
};
// Inline conditionally, when it can result in large code generation.
const bloaty_inline = switch (builtin.mode) {
    .ReleaseSafe, .ReleaseFast => .Inline,
    .Debug, .ReleaseSmall => .Unspecified,
};
pub const Fe = struct {
    limbs: [5]u64,
    const MASK51: u64 = 0x7ffffffffffff;
    pub const zero: Fe = .{ .limbs = .{ 0, 0, 0, 0, 0 } };
    pub const one: Fe = .{ .limbs = .{ 1, 0, 0, 0, 0 } };
    pub const sqrtm1: Fe = .{ .limbs = .{ 1718705420411056, 234908883556509, 2233514472574048, 2117202627021982, 765476049583133 } };
    pub const curve25519_base_point: Fe = .{ .limbs = .{ 9, 0, 0, 0, 0 } };
    pub const edwards25519d: Fe = .{ .limbs = .{ 929955233495203, 466365720129213, 1662059464998953, 2033849074728123, 1442794654840575 } };
    pub const edwards25519d2: Fe = .{ .limbs = .{ 1859910466990425, 932731440258426, 1072319116312658, 1815898335770999, 633789495995903 } };
    pub const edwards25519sqrtamd: Fe = .{ .limbs = .{ 278908739862762, 821645201101625, 8113234426968, 1777959178193151, 2118520810568447 } };
    pub const edwards25519eonemsqd: Fe = .{ .limbs = .{ 1136626929484150, 1998550399581263, 496427632559748, 118527312129759, 45110755273534 } };
    pub const edwards25519sqdmone: Fe = .{ .limbs = .{ 1507062230895904, 1572317787530805, 683053064812840, 317374165784489, 1572899562415810 } };
    pub const edwards25519sqrtadm1: Fe = .{ .limbs = .{ 2241493124984347, 425987919032274, 2207028919301688, 1220490630685848, 974799131293748 } };
    pub const edwards25519a_32: u32 = 486662;
    pub const edwards25519a: Fe = .{ .limbs = .{ @as(u64, edwards25519a_32), 0, 0, 0, 0 } };
    pub const edwards25519sqrtam2: Fe = .{ .limbs = .{ 1693982333959686, 608509411481997, 2235573344831311, 947681270984193, 266558006233600 } };
    pub fn isZero(fe: Fe) bool {
        var reduced: Fe = fe;
        reduced.reduce();
        const limbs: [5]u64 = reduced.limbs;
        return (limbs[0] | limbs[1] | limbs[2] | limbs[3] | limbs[4]) == 0;
    }
    pub fn equivalent(a: Fe, b: Fe) bool {
        return a.sub(b).isZero();
    }
    pub fn fromBytes(s: [32]u8) Fe {
        var fe: Fe = undefined;
        fe.limbs[0] = mem.readIntLittle(u64, s[0..8]) & MASK51;
        fe.limbs[1] = (mem.readIntLittle(u64, s[6..14]) >> 3) & MASK51;
        fe.limbs[2] = (mem.readIntLittle(u64, s[12..20]) >> 6) & MASK51;
        fe.limbs[3] = (mem.readIntLittle(u64, s[19..27]) >> 1) & MASK51;
        fe.limbs[4] = (mem.readIntLittle(u64, s[24..32]) >> 12) & MASK51;
        return fe;
    }
    pub fn toBytes(fe: Fe) [32]u8 {
        var reduced: Fe = fe;
        reduced.reduce();
        var s: [32]u8 = undefined;
        mem.writeIntLittle(u64, s[0..8], reduced.limbs[0] | (reduced.limbs[1] << 51));
        mem.writeIntLittle(u64, s[8..16], (reduced.limbs[1] >> 13) | (reduced.limbs[2] << 38));
        mem.writeIntLittle(u64, s[16..24], (reduced.limbs[2] >> 26) | (reduced.limbs[3] << 25));
        mem.writeIntLittle(u64, s[24..32], (reduced.limbs[3] >> 39) | (reduced.limbs[4] << 12));
        return s;
    }
    pub fn fromBytes64(s: [64]u8) Fe {
        var fl: [32]u8 = undefined;
        var gl: [32]u8 = undefined;
        var idx: usize = 0;
        while (idx < 32) : (idx +%= 1) {
            fl[idx] = s[63 -% idx];
            gl[idx] = s[31 -% idx];
        }
        fl[31] &= 0x7f;
        gl[31] &= 0x7f;
        var fe_f: Fe = fromBytes(fl);
        const fe_g: Fe = fromBytes(gl);
        fe_f.limbs[0] +%= (s[32] >> 7) *% 19 +% @as(u10, s[0] >> 7) *% 722;
        idx = 0;
        while (idx < 5) : (idx +%= 1) {
            fe_f.limbs[idx] +%= 38 *% fe_g.limbs[idx];
        }
        fe_f.reduce();
        return fe_f;
    }
    pub fn rejectNonCanonical(s: [32]u8, comptime ignore_extra_bit: bool) !void {
        var c: u16 = (s[31] & 0x7f) ^ 0x7f;
        comptime var idx: usize = 30;
        inline while (idx > 0) : (idx -%= 1) {
            c |= s[idx] ^ 0xff;
        }
        c = (c -% 1) >> 8;
        const d: u16 = (@as(u16, 0xed -% 1) -% @as(u16, s[0])) >> 8;
        const x: u8 = if (ignore_extra_bit) 0 else s[31] >> 7;
        if ((((c & d) | x) & 1) != 0) {
            return error.NonCanonical;
        }
    }
    fn reduce(fe: *Fe) void {
        const limbs: *[5]u64 = &fe.limbs;
        inline for (0..2) |_| {
            inline for (0..4) |idx| {
                limbs[idx +% 1] +%= limbs[idx] >> 51;
                limbs[idx] &= MASK51;
            }
            limbs[0] +%= 19 *% (limbs[4] >> 51);
            limbs[4] &= MASK51;
        }
        limbs[0] +%= 19;
        inline for (0..4) |idx| {
            limbs[idx +% 1] +%= limbs[idx] >> 51;
            limbs[idx] &= MASK51;
        }
        limbs[0] +%= 19 *% (limbs[4] >> 51);
        limbs[4] &= MASK51;
        limbs[0] +%= 0x8000000000000 -% 19;
        limbs[1] +%= 0x8000000000000 -% 1;
        limbs[2] +%= 0x8000000000000 -% 1;
        limbs[3] +%= 0x8000000000000 -% 1;
        limbs[4] +%= 0x8000000000000 -% 1;
        inline for (0..4) |idx| {
            limbs[idx +% 1] +%= limbs[idx] >> 51;
            limbs[idx] &= MASK51;
        }
        limbs[4] &= MASK51;
    }
    pub fn add(a: Fe, b: Fe) Fe {
        var fe: Fe = undefined;
        inline for (0..5) |idx| {
            fe.limbs[idx] = a.limbs[idx] +% b.limbs[idx];
        }
        return fe;
    }
    pub fn sub(a: Fe, b: Fe) Fe {
        var fe: Fe = b;
        inline for (0..4) |i| {
            fe.limbs[i +% 1] +%= fe.limbs[i] >> 51;
            fe.limbs[i] &= MASK51;
        }
        fe.limbs[0] +%= 19 *% (fe.limbs[4] >> 51);
        fe.limbs[4] &= MASK51;
        fe.limbs[0] = (a.limbs[0] +% 0xfffffffffffda) -% fe.limbs[0];
        fe.limbs[1] = (a.limbs[1] +% 0xffffffffffffe) -% fe.limbs[1];
        fe.limbs[2] = (a.limbs[2] +% 0xffffffffffffe) -% fe.limbs[2];
        fe.limbs[3] = (a.limbs[3] +% 0xffffffffffffe) -% fe.limbs[3];
        fe.limbs[4] = (a.limbs[4] +% 0xffffffffffffe) -% fe.limbs[4];
        return fe;
    }
    pub fn neg(a: Fe) Fe {
        return zero.sub(a);
    }
    pub fn isNegative(a: Fe) bool {
        return (a.toBytes()[0] & 1) != 0;
    }
    pub fn cMov(fe: *Fe, a: Fe, c: u64) void {
        const mask: u64 = 0 -% c;
        var x: Fe = fe.*;
        inline for (0..5) |i| {
            x.limbs[i] ^= a.limbs[i];
        }
        inline for (0..5) |i| {
            x.limbs[i] &= mask;
        }
        inline for (0..5) |i| {
            fe.limbs[i] ^= x.limbs[i];
        }
    }
    pub fn cSwap2(a0: *Fe, b0: *Fe, a1: *Fe, b1: *Fe, c: u64) void {
        const mask: u64 = 0 -% c;
        var x0: Fe = a0.*;
        var x1: Fe = a1.*;
        inline for (0..5) |i| {
            x0.limbs[i] ^= b0.limbs[i];
            x1.limbs[i] ^= b1.limbs[i];
        }
        inline for (0..5) |i| {
            x0.limbs[i] &= mask;
            x1.limbs[i] &= mask;
        }
        inline for (0..5) |i| {
            a0.limbs[i] ^= x0.limbs[i];
            b0.limbs[i] ^= x0.limbs[i];
            a1.limbs[i] ^= x1.limbs[i];
            b1.limbs[i] ^= x1.limbs[i];
        }
    }
    fn _carry128(r: *[5]u128) Fe {
        var rs: [5]u64 = undefined;
        inline for (0..4) |i| {
            rs[i] = @as(u64, @truncate(r[i])) & MASK51;
            r[i +% 1] +%= @as(u64, @intCast(r[i] >> 51));
        }
        rs[4] = @as(u64, @truncate(r[4])) & MASK51;
        var carry: u64 = @as(u64, @intCast(r[4] >> 51));
        rs[0] +%= 19 *% carry;
        carry = rs[0] >> 51;
        rs[0] &= MASK51;
        rs[1] +%= carry;
        carry = rs[1] >> 51;
        rs[1] &= MASK51;
        rs[2] +%= carry;
        return .{ .limbs = rs };
    }
    pub fn mul(a: Fe, b: Fe) callconv(bloaty_inline) Fe {
        var ax: [5]u128 = undefined;
        var bx: [5]u128 = undefined;
        var a19: [5]u128 = undefined;
        var r: [5]u128 = undefined;
        for (0..5) |i| {
            ax[i] = @as(u128, @intCast(a.limbs[i]));
            bx[i] = @as(u128, @intCast(b.limbs[i]));
        }
        for (1..5) |i| {
            a19[i] = 19 *% ax[i];
        }
        r[0] = ax[0] *% bx[0] +% a19[1] *% bx[4] +% a19[2] *%
            bx[3] +% a19[3] *% bx[2] +% a19[4] *% bx[1];
        r[1] = ax[0] *% bx[1] +% ax[1] *% bx[0] +% a19[2] *%
            bx[4] +% a19[3] *% bx[3] +% a19[4] *% bx[2];
        r[2] = ax[0] *% bx[2] +% ax[1] *% bx[1] +% ax[2] *%
            bx[0] +% a19[3] *% bx[4] +% a19[4] *% bx[3];
        r[3] = ax[0] *% bx[3] +% ax[1] *% bx[2] +% ax[2] *%
            bx[1] +% ax[3] *% bx[0] +% a19[4] *% bx[4];
        r[4] = ax[0] *% bx[4] +% ax[1] *% bx[3] +% ax[2] *%
            bx[2] +% ax[3] *% bx[1] +% ax[4] *% bx[0];
        return _carry128(&r);
    }
    fn _sq(a: Fe, comptime double: bool) Fe {
        var ax: [5]u128 = undefined;
        var r: [5]u128 = undefined;
        inline for (0..5) |i| {
            ax[i] = @as(u128, @intCast(a.limbs[i]));
        }
        const a0_2: u128 = 2 *% ax[0];
        const a1_2: u128 = 2 *% ax[1];
        const a1_38: u128 = 38 *% ax[1];
        const a2_38: u128 = 38 *% ax[2];
        const a3_38: u128 = 38 *% ax[3];
        const a3_19: u128 = 19 *% ax[3];
        const a4_19: u128 = 19 *% ax[4];
        r[0] = ax[0] *% ax[0] +% a1_38 *% ax[4] +% a2_38 *% ax[3];
        r[1] = a0_2 *% ax[1] +% a2_38 *% ax[4] +% a3_19 *% ax[3];
        r[2] = a0_2 *% ax[2] +% ax[1] *% ax[1] +% a3_38 *% ax[4];
        r[3] = a0_2 *% ax[3] +% a1_2 *% ax[2] +% a4_19 *% ax[4];
        r[4] = a0_2 *% ax[4] +% a1_2 *% ax[3] +% ax[2] *% ax[2];
        if (double) {
            inline for (0..5) |i| {
                r[i] *%= 2;
            }
        }
        return _carry128(&r);
    }
    pub fn sq(a: Fe) Fe {
        return _sq(a, false);
    }
    pub fn sq2(a: Fe) Fe {
        return _sq(a, true);
    }
    pub fn mul32(a: Fe, comptime n: u32) Fe {
        const sn: u128 = @as(u128, @intCast(n));
        var fe: Fe = undefined;
        var x: u128 = 0;
        inline for (0..5) |idx| {
            x = a.limbs[idx] *% sn +% (x >> 51);
            fe.limbs[idx] = @as(u64, @truncate(x)) & MASK51;
        }
        fe.limbs[0] +%= @as(u64, @intCast(x >> 51)) *% 19;
        return fe;
    }
    fn sqn(a: Fe, n: usize) Fe {
        var idx: usize = 0;
        var fe: Fe = a;
        while (idx != n) : (idx +%= 1) {
            fe = fe.sq();
        }
        return fe;
    }
    pub fn invert(a: Fe) Fe {
        var t0: Fe = a.sq();
        var t1: Fe = t0.sqn(2).mul(a);
        t0 = t0.mul(t1);
        t1 = t1.mul(t0.sq());
        t1 = t1.mul(t1.sqn(5));
        var t2: Fe = t1.sqn(10).mul(t1);
        t2 = t2.mul(t2.sqn(20)).sqn(10);
        t1 = t1.mul(t2);
        t2 = t1.sqn(50).mul(t1);
        return t1.mul(t2.mul(t2.sqn(100)).sqn(50)).sqn(5).mul(t0);
    }
    pub fn pow2523(a: Fe) Fe {
        var t0: Fe = a.mul(a.sq());
        var t1: Fe = t0.mul(t0.sqn(2)).sq().mul(a);
        t0 = t1.sqn(5).mul(t1);
        var t2: Fe = t0.sqn(5).mul(t1);
        t1 = t2.sqn(15).mul(t2);
        t2 = t1.sqn(30).mul(t1);
        t1 = t2.sqn(60).mul(t2);
        return t1.sqn(120).mul(t1).sqn(10).mul(t0).sqn(2).mul(a);
    }
    pub fn abs(a: Fe) Fe {
        var r: Fe = a;
        r.cMov(a.neg(), @intFromBool(a.isNegative()));
        return r;
    }
    pub fn isSquare(a: Fe) bool {
        const _11: Fe = a.mul(a.sq());
        const _1111: Fe = _11.mul(_11.sq().sq());
        const _11111111: Fe = _1111.mul(_1111.sq().sq().sq().sq());
        const u: Fe = _11111111.sqn(2).mul(_11);
        const t: Fe = u.sqn(10).mul(u).sqn(10).mul(u);
        const t2: Fe = t.sqn(30).mul(t);
        const t3: Fe = t2.sqn(60).mul(t2);
        const t4: Fe = t3.sqn(120).mul(t3).sqn(10).mul(u).sqn(3).mul(_11).sq();
        return @as(bool, @bitCast(@as(u1, @truncate(~(t4.toBytes()[1] & 1)))));
    }
    fn uncheckedSqrt(x2: Fe) Fe {
        var e: Fe = x2.pow2523();
        const p_root: Fe = e.mul(x2); // positive root
        const m_root: Fe = p_root.mul(Fe.sqrtm1); // negative root
        const m_root2: Fe = m_root.sq();
        e = x2.sub(m_root2);
        var x: Fe = p_root;
        x.cMov(m_root, @intFromBool(e.isZero()));
        return x;
    }
    pub fn sqrt(x2: Fe) !Fe {
        var x2_copy: Fe = x2;
        const x: Fe = x2.uncheckedSqrt();
        const check: Fe = x.sq().sub(x2_copy);
        if (check.isZero()) {
            return x;
        }
        return error.NotSquare;
    }
};
pub const Ristretto255 = struct {
    p: Edwards25519,
    pub const encoded_len: comptime_int = 32;
    fn sqrtRatioM1(u: Fe, v: Fe) struct { ratio_is_square: u32, root: Fe } {
        const v3: Fe = v.sq().mul(v); // v^3
        var x: Fe = v3.sq().mul(u).mul(v).pow2523().mul(v3).mul(u); // uv^3(uv^7)^((q-5)/8)
        const vxx: Fe = x.sq().mul(v); // vx^2
        const m_root_check: Fe = vxx.sub(u); // vx^2-u
        const p_root_check: Fe = vxx.add(u); // vx^2+u
        const f_root_check: Fe = u.mul(Fe.sqrtm1).add(vxx); // vx^2+u*sqrt(-1)
        const has_m_root: bool = m_root_check.isZero();
        const has_p_root: bool = p_root_check.isZero();
        const has_f_root: bool = f_root_check.isZero();
        const x_sqrtm1 = x.mul(Fe.sqrtm1); // x*sqrt(-1)
        x.cMov(x_sqrtm1, @intFromBool(has_p_root) | @intFromBool(has_f_root));
        return .{ .ratio_is_square = @intFromBool(has_m_root) | @intFromBool(has_p_root), .root = x.abs() };
    }
    fn rejectNonCanonical(s: [encoded_len]u8) !void {
        if ((s[0] & 1) != 0) {
            return error.NonCanonical;
        }
        try Fe.rejectNonCanonical(s, false);
    }
    pub fn rejectIdentity(p: Ristretto255) !void {
        return p.p.rejectIdentity();
    }
    pub const base_point: Ristretto255 = .{ .p = Edwards25519.base_point };
    pub fn fromBytes(s: [encoded_len]u8) !Ristretto255 {
        try rejectNonCanonical(s);
        const s_: Fe = Fe.fromBytes(s);
        const ss: Fe = s_.sq(); // s^2
        const u1_: Fe = Fe.one.sub(ss); // (1-s^2)
        const u1u1: Fe = u1_.sq(); // (1-s^2)^2
        const u2_: Fe = Fe.one.add(ss); // (1+s^2)
        const u2u2: Fe = u2_.sq(); // (1+s^2)^2
        const v: Fe = Fe.edwards25519d.mul(u1u1).neg().sub(u2u2); // -(d*u1^2)-u2^2
        const v_u2u2: Fe = v.mul(u2u2); // v*u2^2
        const inv_sqrt = sqrtRatioM1(Fe.one, v_u2u2);
        var x: Fe = inv_sqrt.root.mul(u2_);
        const y: Fe = inv_sqrt.root.mul(x).mul(v).mul(u1_);
        x = x.mul(s_);
        x = x.add(x).abs();
        const t: Fe = x.mul(y);
        if ((1 -% inv_sqrt.ratio_is_square) | @intFromBool(t.isNegative()) | @intFromBool(y.isZero()) != 0) {
            return error.InvalidEncoding;
        }
        const p: Edwards25519 = .{
            .x = x,
            .y = y,
            .z = Fe.one,
            .t = t,
        };
        return .{ .p = p };
    }
    pub fn toBytes(e: Ristretto255) [encoded_len]u8 {
        const p: *const Edwards25519 = &e.p;
        var u1_: Fe = p.z.add(p.y); // Z+Y
        const zmy: Fe = p.z.sub(p.y); // Z-Y
        u1_ = u1_.mul(zmy); // (Z+Y)*(Z-Y)
        const u2_: Fe = p.x.mul(p.y); // X*Y
        const u1_u2u2: Fe = u2_.sq().mul(u1_); // u1*u2^2
        const inv_sqrt = sqrtRatioM1(Fe.one, u1_u2u2);
        const den1: Fe = inv_sqrt.root.mul(u1_);
        const den2: Fe = inv_sqrt.root.mul(u2_);
        const z_inv: Fe = den1.mul(den2).mul(p.t); // den1*den2*T
        const ix: Fe = p.x.mul(Fe.sqrtm1); // X*sqrt(-1)
        const iy: Fe = p.y.mul(Fe.sqrtm1); // Y*sqrt(-1)
        const eden: Fe = den1.mul(Fe.edwards25519sqrtamd); // den1/sqrt(a-d)
        const t_z_inv: Fe = p.t.mul(z_inv); // T*z_inv
        const rotate: u1 = @intFromBool(t_z_inv.isNegative());
        var x: Fe = p.x;
        var y: Fe = p.y;
        var den_inv: Fe = den2;
        x.cMov(iy, rotate);
        y.cMov(ix, rotate);
        den_inv.cMov(eden, rotate);
        const x_z_inv: Fe = x.mul(z_inv);
        const yneg: Fe = y.neg();
        y.cMov(yneg, @intFromBool(x_z_inv.isNegative()));
        return p.z.sub(y).mul(den_inv).abs().toBytes();
    }
    fn elligator(t: Fe) Edwards25519 {
        const r: Fe = t.sq().mul(Fe.sqrtm1); // sqrt(-1)*t^2
        const u: Fe = r.add(Fe.one).mul(Fe.edwards25519eonemsqd); // (r+1)*(1-d^2)
        var c: Fe = comptime Fe.one.neg(); // -1
        const v: Fe = c.sub(r.mul(Fe.edwards25519d)).mul(r.add(Fe.edwards25519d)); // (c-r*d)*(r+d)
        const ratio_sqrt = sqrtRatioM1(u, v);
        const wasnt_square: u32 = 1 -% ratio_sqrt.ratio_is_square;
        var s: Fe = ratio_sqrt.root;
        const s_prime: Fe = s.mul(t).abs().neg(); // -|s*t|
        s.cMov(s_prime, wasnt_square);
        c.cMov(r, wasnt_square);
        const n: Fe = r.sub(Fe.one).mul(c).mul(Fe.edwards25519sqdmone).sub(v); // c*(r-1)*(d-1)^2-v
        const w0: Fe = s.add(s).mul(v); // 2s*v
        const w1: Fe = n.mul(Fe.edwards25519sqrtadm1); // n*sqrt(ad-1)
        const ss: Fe = s.sq(); // s^2
        const w2: Fe = Fe.one.sub(ss); // 1-s^2
        const w3: Fe = Fe.one.add(ss); // 1+s^2
        return .{ .x = w0.mul(w3), .y = w2.mul(w1), .z = w1.mul(w3), .t = w0.mul(w2) };
    }
    pub fn fromUniform(h: [64]u8) Ristretto255 {
        const p0: Edwards25519 = elligator(Fe.fromBytes(h[0..32].*));
        const p1: Edwards25519 = elligator(Fe.fromBytes(h[32..64].*));
        return .{ .p = p0.add(p1) };
    }
    pub fn dbl(p: Ristretto255) Ristretto255 {
        return .{ .p = p.p.dbl() };
    }
    pub fn add(p: Ristretto255, q: Ristretto255) Ristretto255 {
        return .{ .p = p.p.add(q.p) };
    }
    pub fn mul(p: Ristretto255, s: [encoded_len]u8) !Ristretto255 {
        return .{ .p = try p.p.mul(s) };
    }
    pub fn equivalent(arg1: Ristretto255, arg2: Ristretto255) bool {
        const ptr1: *const Ristretto255 = &arg1;
        const ptr2: *const Ristretto255 = &arg2;
        const a = ptr1.p.x.mul(ptr2.p.y).equivalent(ptr1.p.y.mul(ptr2.p.x));
        const b = ptr1.p.y.mul(ptr2.p.y).equivalent(ptr1.p.x.mul(ptr2.p.x));
        return (@intFromBool(a) | @intFromBool(b)) != 0;
    }
};
pub const X25519 = struct {
    pub const secret_len: comptime_int = 32;
    pub const public_len: comptime_int = 32;
    pub const shared_len: comptime_int = 32;
    pub const seed_len: comptime_int = 32;
    pub const KeyPair = struct {
        public_key: [public_len]u8,
        secret_key: [secret_len]u8,
        pub fn create(seed: [seed_len]u8) !KeyPair {
            var kp: KeyPair = undefined;
            kp.secret_key = seed;
            kp.public_key = try X25519.recoverPublicKey(seed);
            return kp;
        }
        pub fn fromEd25519(ed25519_key_pair: Ed25519.KeyPair) !KeyPair {
            const seed: [Ed25519.KeyPair.seed_len]u8 = ed25519_key_pair.secret_key.seed();
            var az: [hash.Sha512.len]u8 = undefined;
            hash.Sha512.hash(&seed, &az);
            var sk: [32]u8 = az[0..32].*;
            scalar.clamp(&sk);
            const pk: [public_len]u8 = try publicKeyFromEd25519(ed25519_key_pair.public_key);
            return KeyPair{
                .public_key = pk,
                .secret_key = sk,
            };
        }
    };
    pub fn recoverPublicKey(secret_key: [secret_len]u8) ![public_len]u8 {
        const q: Curve25519 = try Curve25519.base_point.clampedMul(secret_key);
        return q.toBytes();
    }
    pub fn publicKeyFromEd25519(ed25519_public_key: Ed25519.PublicKey) ![public_len]u8 {
        const pk_ed: Edwards25519 = try Edwards25519.fromBytes(ed25519_public_key.bytes);
        const pk: Curve25519 = try Curve25519.fromEdwards25519(pk_ed);
        return pk.toBytes();
    }
    pub fn scalarmult(secret_key: [secret_len]u8, public_key: [public_len]u8) ![shared_len]u8 {
        const q: Curve25519 = try Curve25519.fromBytes(public_key).clampedMul(secret_key);
        return q.toBytes();
    }
};
