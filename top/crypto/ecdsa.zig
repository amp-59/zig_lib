const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const mach = @import("../mach.zig");
const file = @import("../file.zig");
const builtin = @import("../builtin.zig");
const testing = @import("../testing.zig");
const hash = @import("./hash.zig");
const auth = @import("./auth.zig");
const pcurves = @import("./pcurves.zig");
pub const EcdsaP256Sha256 = GenericEcdsa(pcurves.P256, hash.Sha256);
pub const EcdsaP256Sha3_256 = GenericEcdsa(pcurves.P256, hash.Sha3_256);
pub const EcdsaP384Sha384 = GenericEcdsa(pcurves.P384, hash.Sha384);
pub const EcdsaP256Sha3_384 = GenericEcdsa(pcurves.P384, hash.Sha3_384);
pub const EcdsaSecp256k1Sha256 = GenericEcdsa(pcurves.Secp256k1, hash.Sha256);
pub const EcdsaSecp256k1Sha256oSha256 = GenericEcdsa(pcurves.Secp256k1, hash.Sha256oSha256);
pub fn GenericEcdsa(comptime Curve: type, comptime Hash: type) type {
    const T = struct {
        const Hmac = auth.GenericHmac(Hash);
        pub const SecretKey = struct {
            pub const encoded_len: comptime_int = Curve.scalar.encoded_len;
            bytes: Curve.scalar.CompressedScalar,
            pub fn fromBytes(bytes: [encoded_len]u8) !SecretKey {
                return .{ .bytes = bytes };
            }
            pub fn toBytes(secr_key: SecretKey) [encoded_len]u8 {
                return secr_key.bytes;
            }
        };
        pub const PublicKey = struct {
            p: Curve,
            pub const UncompressedSec1 = [encoded_len]u8;
            pub const CompressedSec1 = [compressed_len]u8;
            pub const encoded_len: comptime_int = 1 +% 2 *% Curve.Fe.encoded_len;
            pub const compressed_len: comptime_int = 1 +% Curve.Fe.encoded_len;
            pub fn fromSec1(sec1: []const u8) !PublicKey {
                return .{ .p = try Curve.fromSec1(sec1) };
            }
            pub fn toCompressedSec1(pub_key: PublicKey) CompressedSec1 {
                return pub_key.p.toCompressedSec1();
            }
            pub fn toUncompressedSec1(pub_key: PublicKey) [encoded_len]u8 {
                return pub_key.p.toUncompressedSec1();
            }
        };
        pub const Signature = extern struct {
            r: Curve.scalar.CompressedScalar,
            s: Curve.scalar.CompressedScalar,
            pub const encoded_len: comptime_int = Curve.scalar.encoded_len *% 2;
            pub const der_encoded_max_len: comptime_int = encoded_len +% 2 +% 2 *% 3;
            pub fn verifier(sig: Signature, public_key: PublicKey) !Verifier {
                return Verifier.init(sig, public_key);
            }
            pub fn verify(sig: Signature, msg: []const u8, public_key: PublicKey) !void {
                var st: Verifier = try Verifier.init(sig, public_key);
                st.update(msg);
                return st.verify();
            }
            pub fn toBytes(sig: Signature) [encoded_len]u8 {
                @setRuntimeSafety(builtin.is_safe);
                var bytes: [encoded_len]u8 = undefined;
                @memcpy(bytes[0 .. encoded_len / 2], &sig.r);
                @memcpy(bytes[encoded_len / 2 ..], &sig.s);
                return bytes;
            }
            pub fn fromBytes(bytes: [encoded_len]u8) Signature {
                return .{
                    .r = bytes[0 .. encoded_len / 2].*,
                    .s = bytes[encoded_len / 2 ..].*,
                };
            }
            fn readDerInt(dest: []u8, der: []const u8) !u64 {
                @setRuntimeSafety(builtin.is_safe);
                if (der.len < 2) {
                    return error.InvalidEncoding;
                }
                if (der[0] != 0x02) {
                    return error.InvalidEncoding;
                }
                const x_len: u64 = der[1];
                if (x_len == 0 or
                    x_len > 1 +% dest.len)
                {
                    return error.InvalidEncoding;
                }
                if (x_len == 1 +% dest.len) {
                    if (der[2] != 0) {
                        return error.InvalidEncoding;
                    }
                    const out: []u8 = dest[dest.len -% (x_len -% 1) ..];
                    mach.memcpy(out.ptr, der.ptr + 3, out.len);
                    if (dest[0] >> 7 == 0) {
                        return error.InvalidEncoding;
                    }
                    return 3 +% out.len;
                } else {
                    const out: []u8 = dest[dest.len -% x_len ..];
                    mach.memcpy(out.ptr, der.ptr + 2, out.len);
                    return 2 +% out.len;
                }
            }
            pub fn fromDer(der: []const u8) !Signature {
                var ret: Signature = comptime builtin.zero(Signature);
                if (der.len < 2) {
                    return error.InvalidEncoding;
                }
                if (der[0] != 0x30) {
                    return error.InvalidEncoding;
                }
                if (der[1] +% 2 != der.len) {
                    return error.InvalidEncoding;
                }
                var idx: u64 = 2;
                idx +%= try readDerInt(&ret.r, der[idx..]);
                idx +%= try readDerInt(&ret.s, der[idx..]);
                if (idx != der.len) {
                    return error.InvalidEncoding;
                }
                return ret;
            }
        };
        pub const Signer = struct {
            h: Hash,
            secret_key: SecretKey,
            noise: ?[noise_len]u8,
            fn init(secret_key: SecretKey, noise: ?[noise_len]u8) !Signer {
                return .{ .h = Hash.init(), .secret_key = secret_key, .noise = noise };
            }
            pub fn update(signer: *Signer, data: []const u8) void {
                signer.h.update(data);
            }
            pub fn finalize(signer: *Signer) !Signature {
                @setRuntimeSafety(builtin.is_safe);
                const scalar_encoded_len: comptime_int = Curve.scalar.encoded_len;
                const h_len: comptime_int = @max(Hash.len, scalar_encoded_len);
                var h: [h_len]u8 = [1]u8{0} ** h_len;
                var h_slice: *[Hash.len]u8 = h[h_len -% Hash.len .. h_len];
                signer.h.final(h_slice);
                const z: Curve.scalar.Scalar = reduceToScalar(scalar_encoded_len, h[0..scalar_encoded_len].*);
                const k: Curve.scalar.Scalar = deterministicScalar(h_slice.*, signer.secret_key.bytes, signer.noise);
                const p: Curve = try Curve.base_point.mul(k.toBytes(.Big), .Big);
                const xs: Curve.scalar.CompressedScalar = p.affineCoordinates().x.toBytes(.Big);
                const r: Curve.scalar.Scalar = reduceToScalar(Curve.Fe.encoded_len, xs);
                if (r.isZero()) return error.IdentityElement;
                const k_inv: Curve.scalar.Scalar = k.invert();
                const zrs: Curve.scalar.Scalar = z.add(r.mul(try Curve.scalar.Scalar.fromBytes(signer.secret_key.bytes, .Big)));
                const s: Curve.scalar.Scalar = k_inv.mul(zrs);
                if (s.isZero()) return error.IdentityElement;
                return Signature{ .r = r.toBytes(.Big), .s = s.toBytes(.Big) };
            }
        };
        pub const Verifier = struct {
            h: Hash,
            r: Curve.scalar.Scalar,
            s: Curve.scalar.Scalar,
            public_key: PublicKey,
            const h_len: comptime_int = @max(Hash.len, Curve.scalar.encoded_len);
            fn init(sig: Signature, public_key: PublicKey) !Verifier {
                const r: Curve.scalar.Scalar = try Curve.scalar.Scalar.fromBytes(sig.r, .Big);
                const s: Curve.scalar.Scalar = try Curve.scalar.Scalar.fromBytes(sig.s, .Big);
                if (r.isZero() or s.isZero()) return error.IdentityElement;
                return .{ .h = Hash.init(), .r = r, .s = s, .public_key = public_key };
            }
            pub fn update(verifier: *Verifier, data: []const u8) void {
                verifier.h.update(data);
            }
            pub fn verify(verifier: *Verifier) !void {
                var h: [h_len]u8 = [_]u8{0} ** h_len;
                verifier.h.final(h[h_len -% Hash.len .. h_len]);
                const z: Curve.scalar.Scalar = reduceToScalar(Curve.scalar.encoded_len, h[0..Curve.scalar.encoded_len].*);
                if (z.isZero()) {
                    return error.SignatureVerificationFailed;
                }
                const s_inv: Curve.scalar.Scalar = verifier.s.invert();
                const v1: Curve.scalar.CompressedScalar = z.mul(s_inv).toBytes(.Little);
                const v2: Curve.scalar.CompressedScalar = verifier.r.mul(s_inv).toBytes(.Little);
                const v1g: Curve = try Curve.base_point.mulPublic(v1, .Little);
                const v2pk: Curve = try verifier.public_key.p.mulPublic(v2, .Little);
                const vxs: Curve.scalar.CompressedScalar = v1g.add(v2pk).affineCoordinates().x.toBytes(.Big);
                const vr: Curve.scalar.Scalar = reduceToScalar(Curve.Fe.encoded_len, vxs);
                if (!verifier.r.equivalent(vr)) {
                    return error.SignatureVerificationFailed;
                }
            }
        };
        pub const KeyPair = struct {
            public_key: PublicKey,
            secret_key: SecretKey,
            pub const seed_len: comptime_int = noise_len;
            pub fn create(seed: ?[seed_len]u8) !KeyPair {
                const h: [Hash.len]u8 = [1]u8{0} ** Hash.len;
                const k0: [SecretKey.encoded_len]u8 = [1]u8{1} ** SecretKey.encoded_len;
                const secret_key: Curve.scalar.CompressedScalar = deterministicScalar(h, k0, seed).toBytes(.Big);
                return fromSecretKey(.{ .bytes = secret_key });
            }
            pub fn fromSecretKey(secret_key: SecretKey) !KeyPair {
                return .{
                    .secret_key = secret_key,
                    .public_key = .{ .p = try Curve.base_point.mul(secret_key.bytes, .Big) },
                };
            }
            pub fn sign(key_pair: KeyPair, msg: []const u8, noise: ?[noise_len]u8) !Signature {
                var st: Signer = try key_pair.signer(noise);
                st.update(msg);
                return st.finalize();
            }
            pub fn signer(key_pair: KeyPair, noise: ?[noise_len]u8) !Signer {
                return Signer.init(key_pair.secret_key, noise);
            }
        };
        pub const noise_len: comptime_int = Curve.scalar.encoded_len;
        pub const message_len: comptime_int = (Hash.len *% 2) +% noise_len +% 1 +% SecretKey.encoded_len;
        fn reduceToScalar(comptime unreduced_len: usize, s: [unreduced_len]u8) Curve.scalar.Scalar {
            if (unreduced_len >= 48) {
                var xs: [64]u8 = undefined;
                mach.memcpy(xs[xs.len -% s.len ..].ptr, &s, unreduced_len);
                mach.memset(&xs, 0, xs.len -% s.len);
                return Curve.scalar.Scalar.fromBytes64(xs, .Big);
            }
            var xs: [48]u8 = undefined;
            mach.memcpy(xs[xs.len -% s.len ..].ptr, &s, unreduced_len);
            mach.memset(&xs, 0, xs.len -% s.len);
            return Curve.scalar.Scalar.fromBytes48(xs, .Big);
        }
        fn deterministicScalar(h: [Hash.len]u8, secret_key: Curve.scalar.CompressedScalar, noise: ?[noise_len]u8) Curve.scalar.Scalar {
            @setRuntimeSafety(false);
            var k: [Hash.len]u8 = [1]u8{0} ** Hash.len;
            var t: [Curve.scalar.encoded_len]u8 = [1]u8{0} ** Curve.scalar.encoded_len;
            var m: [message_len]u8 = [1]u8{0} ** message_len;
            //var _v: [Hash.len]u8 = .{0} ** Hash.len;
            //var _i: u8 = 0;
            //var _z: [noise_len]u8 = .{0} ** noise_len;
            //var _x: [secret_key.len]u8 = .{0} ** secret_key.len;
            //var _h: [Hash.len]u8 = .{0} ** Hash.len;
            const m_v: *[Hash.len]u8 = m[0..h.len];
            const m_i: *u8 = &m[m_v.len];
            const m_z: *[noise_len]u8 = m[m_v.len +% 1 ..][0..noise_len];
            const m_x: *[secret_key.len]u8 = m[m_v.len +% 1 +% noise_len ..][0..secret_key.len];
            const m_h: *[Hash.len]u8 = m[m.len -% h.len ..];
            @memset(m_v, 0x01);
            m_i.* = 0x00;
            if (noise) |n| {
                @memcpy(m_z, &n);
            }
            @memcpy(m_x, &secret_key);
            @memcpy(m_h, &h);
            Hmac.create(&k, &m, &k);
            Hmac.create(m_v, m_v, &k);
            m_i.* = 0x01;
            Hmac.create(&k, &m, &k);
            Hmac.create(m_v, m_v, &k);
            while (true) {
                var off: usize = 0;
                while (off < t.len) : (off +%= m_v.len) {
                    const end: usize = @min(off +% m_v.len, t.len);
                    Hmac.create(m_v, m_v, &k);
                    @memcpy(t[off..end], m_v[0 .. end -% off]);
                }
                if (Curve.scalar.Scalar.fromBytes(t, .Big)) |s| return s else |_| {}
                m_i.* = 0x00;
                Hmac.create(&k, m[0 .. m_v.len +% 1], &k);
                Hmac.create(m_v, m_v, &k);
            }
        }
    };
    return T;
}
