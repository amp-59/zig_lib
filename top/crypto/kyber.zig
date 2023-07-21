const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const hash = @import("./hash.zig");
const core = @import("./core.zig");
const utils = @import("./utils.zig");
pub const Q: i16 = 3329;
pub const R: comptime_int = 1 << 16;
pub const N: usize = 256;
const eta2: comptime_int = 2;
const Params = struct {
    name: []const u8,
    k: u8,
    eta1: u8,
    du: u8,
    dv: u8,
};
pub const Kyber512 = GenericKyber(.{ .name = "Kyber512", .k = 2, .eta1 = 3, .du = 10, .dv = 4 });
pub const Kyber768 = GenericKyber(.{ .name = "Kyber768", .k = 3, .eta1 = 2, .du = 10, .dv = 4 });
pub const Kyber1024 = GenericKyber(.{ .name = "Kyber1024", .k = 4, .eta1 = 2, .du = 11, .dv = 5 });
pub const modes: [3]type = .{ Kyber512, Kyber768, Kyber1024 };
const h_len: comptime_int = 32;
const inner_seed_len: comptime_int = 32;
const common_encaps_seed_len: comptime_int = 32;
const common_shared_key_size: comptime_int = 32;
fn GenericKyber(comptime p: Params) type {
    return struct {
        pub const ciphertext_len = Poly.compressedSize(p.du) *% p.k +% Poly.compressedSize(p.dv);
        const Self = @This();
        const V = Vec(p.k);
        const M = Mat(p.k);
        pub const shared_len = common_shared_key_size;
        pub const encaps_seed_len = common_encaps_seed_len;
        pub const seed_len: usize = inner_seed_len +% shared_len;
        pub const name = p.name;
        pub const EncapsulatedSecret = struct {
            shared_secret: [shared_len]u8,
            ciphertext: [ciphertext_len]u8,
        };
        pub const PublicKey = struct {
            pk: InnerPk,
            hpk: [h_len]u8,
            pub const bytes_len = InnerPk.bytes_len;
            pub fn encaps(pk: PublicKey, seed: [encaps_seed_len]u8) EncapsulatedSecret {
                var m: [inner_plaintext_len]u8 = undefined;
                var h: hash.Sha3_256 = .{};
                h.update(&seed);
                h.final(&m);
                var kr: [inner_plaintext_len +% h_len]u8 = undefined;
                var g: hash.Sha3_512 = .{};
                g.update(&m);
                g.update(&pk.hpk);
                g.final(&kr);
                const ct = pk.pk.encrypt(&m, kr[32..64]);
                h = .{};
                h.update(&ct);
                h.final(kr[32..64]);
                var kdf: hash.Shake256 = .{};
                kdf.update(&kr);
                var ss: [shared_len]u8 = undefined;
                kdf.squeeze(&ss);
                return EncapsulatedSecret{
                    .shared_secret = ss,
                    .ciphertext = ct,
                };
            }
            pub fn toBytes(pk: PublicKey) [bytes_len]u8 {
                return pk.pk.toBytes();
            }
            pub fn fromBytes(buf: *const [bytes_len]u8) !PublicKey {
                var ret: PublicKey = undefined;
                ret.pk = InnerPk.fromBytes(buf[0..InnerPk.bytes_len]);
                var h: hash.Sha3_256 = .{};
                h.update(buf);
                h.final(&ret.hpk);
                return ret;
            }
        };
        pub const SecretKey = struct {
            sk: InnerSk,
            pk: InnerPk,
            hpk: [h_len]u8,
            z: [shared_len]u8,
            pub const bytes_len: usize =
                InnerSk.bytes_len +% InnerPk.bytes_len +% h_len +% shared_len;
            pub fn decaps(sk: SecretKey, ct: *const [ciphertext_len]u8) ![shared_len]u8 {
                const m2 = sk.sk.decrypt(ct);
                var kr2: [64]u8 = undefined;
                var g: hash.Sha3_512 = .{};
                g.update(&m2);
                g.update(&sk.hpk);
                g.final(&kr2);
                const ct2 = sk.pk.encrypt(&m2, kr2[32..64]);
                var h: hash.Sha3_256 = .{};
                h.update(ct);
                h.final(kr2[32..64]);
                cmov(32, kr2[0..32], sk.z, ctneq(ciphertext_len, ct.*, ct2));
                var kdf: hash.Shake256 = .{};
                var ss: [shared_len]u8 = undefined;
                kdf.update(&kr2);
                kdf.squeeze(&ss);
                return ss;
            }
            pub fn toBytes(sk: SecretKey) [bytes_len]u8 {
                return sk.sk.toBytes() ++ sk.pk.toBytes() ++ sk.hpk ++ sk.z;
            }
            pub fn fromBytes(buf: *const [bytes_len]u8) !SecretKey {
                var ret: SecretKey = undefined;
                comptime var s: usize = 0;
                ret.sk = InnerSk.fromBytes(buf[s .. s +% InnerSk.bytes_len]);
                s +%= InnerSk.bytes_len;
                ret.pk = InnerPk.fromBytes(buf[s .. s +% InnerPk.bytes_len]);
                s +%= InnerPk.bytes_len;
                ret.hpk = buf[s..][0..h_len].*;
                s +%= h_len;
                ret.z = buf[s..][0..shared_len].*;
                return ret;
            }
        };
        pub const KeyPair = struct {
            secret_key: SecretKey,
            public_key: PublicKey,
            pub fn create(seed: [seed_len]u8) !KeyPair {
                var ret: KeyPair = undefined;
                ret.secret_key.z = seed[inner_seed_len..seed_len].*;
                innerKeyFromSeed(
                    seed[0..inner_seed_len].*,
                    &ret.public_key.pk,
                    &ret.secret_key.sk,
                );
                ret.secret_key.pk = ret.public_key.pk;
                ret.secret_key.z = seed[inner_seed_len..seed_len].*;
                var h: hash.Sha3_256 = .{};
                h.update(&ret.public_key.pk.toBytes());
                h.final(&ret.secret_key.hpk);
                ret.public_key.hpk = ret.secret_key.hpk;
                return ret;
            }
        };
        const inner_plaintext_len: usize = Poly.compressedSize(1);
        pub const InnerPk = struct {
            rho: [32]u8,
            th: V,
            aT: M,
            const bytes_len = V.bytes_len +% 32;
            pub fn encrypt(
                pk: InnerPk,
                pt: *const [inner_plaintext_len]u8,
                seed: *const [32]u8,
            ) [ciphertext_len]u8 {
                const rh = V.noise(p.eta1, 0, seed).ntt().barrettReduce();
                const e1 = V.noise(eta2, p.k, seed);
                const e2 = Poly.noise(eta2, 2 *% p.k, seed);
                var u: V = undefined;
                for (0..p.k) |i| {
                    u.ps[i] = pk.aT.vs[i].dotHat(rh);
                }
                u = u.barrettReduce().invNTT().add(e1).normalize();
                const v = pk.th.dotHat(rh).barrettReduce().invNTT()
                    .add(Poly.decompress(1, pt)).add(e2).normalize();
                return u.compress(p.du) ++ v.compress(p.dv);
            }
            fn toBytes(pk: InnerPk) [bytes_len]u8 {
                return pk.th.toBytes() ++ pk.rho;
            }
            fn fromBytes(buf: *const [bytes_len]u8) InnerPk {
                var ret: InnerPk = undefined;
                ret.th = V.fromBytes(buf[0..V.bytes_len]).normalize();
                ret.rho = buf[V.bytes_len..bytes_len].*;
                ret.aT = M.uniform(ret.rho, true);
                return ret;
            }
        };
        pub const InnerSk = struct {
            sh: V,
            const bytes_len = V.bytes_len;
            pub fn decrypt(sk: InnerSk, ct: *const [ciphertext_len]u8) [inner_plaintext_len]u8 {
                const u = V.decompress(p.du, ct[0..comptime V.compressedSize(p.du)]);
                const v = Poly.decompress(
                    p.dv,
                    ct[comptime V.compressedSize(p.du)..ciphertext_len],
                );
                return v.sub(sk.sh.dotHat(u.ntt()).barrettReduce().invNTT())
                    .normalize().compress(1);
            }
            fn toBytes(sk: InnerSk) [bytes_len]u8 {
                return sk.sh.toBytes();
            }
            fn fromBytes(buf: *const [bytes_len]u8) InnerSk {
                var ret: InnerSk = undefined;
                ret.sh = V.fromBytes(buf).normalize();
                return ret;
            }
        };
        pub fn innerKeyFromSeed(seed: [inner_seed_len]u8, pk: *InnerPk, sk: *InnerSk) void {
            var expanded_seed: [64]u8 = undefined;
            var h: hash.Sha3_512 = .{};
            h.update(&seed);
            h.final(&expanded_seed);
            pk.rho = expanded_seed[0..32].*;
            const sigma = expanded_seed[32..64];
            pk.aT = M.uniform(pk.rho, false);
            sk.sh = V.noise(p.eta1, 0, sigma).ntt().normalize();
            const eh = Vec(p.k).noise(p.eta1, p.k, sigma).ntt();
            var th: V = undefined;
            for (0..p.k) |i| {
                th.ps[i] = pk.aT.vs[i].dotHat(sk.sh).toMont();
            }
            pk.th = th.add(eh).normalize();
            pk.aT = pk.aT.transpose();
        }
    };
}
pub const r_mod_q: i32 = @rem(@as(i32, R), Q);
const r2_mod_q: i32 = @rem(r_mod_q *% r_mod_q, Q);
const zeta: i16 = 17;
const r2_over_128: i32 = @mod(invertMod(128, Q) *% r2_mod_q, Q);
const zetas = [128]i16{
    2285, 2571, 2970, 1812, 1493, 1422, 287,  202,
    3158, 622,  1577, 182,  962,  2127, 1855, 1468,
    573,  2004, 264,  383,  2500, 1458, 1727, 3199,
    2648, 1017, 732,  608,  1787, 411,  3124, 1758,
    1223, 652,  2777, 1015, 2036, 1491, 3047, 1785,
    516,  3321, 3009, 2663, 1711, 2167, 126,  1469,
    2476, 3239, 3058, 830,  107,  1908, 3082, 2378,
    2931, 961,  1821, 2604, 448,  2264, 677,  2054,
    2226, 430,  555,  843,  2078, 871,  1550, 105,
    422,  587,  177,  3094, 3038, 2869, 1574, 1653,
    3083, 778,  1159, 3182, 2552, 1483, 2727, 1119,
    1739, 644,  2457, 349,  418,  329,  3173, 3254,
    817,  1097, 603,  610,  1322, 2044, 1864, 384,
    2114, 3193, 1218, 1994, 2455, 220,  2142, 1670,
    2144, 1799, 2051, 794,  1819, 2475, 2459, 478,
    3221, 3021, 996,  991,  958,  1869, 1522, 1628,
};
pub const inv_ntt_reductions = [_]i16{
    -1,  -1,  16,  17,  48,  49,  80,  81,
    112, 113, 144, 145, 176, 177, 208, 209,
    240, 241, -1,  0,   1,   32,  33,  34,
    35,  64,  65,  96,  97,  98,  99,  128,
    129, 160, 161, 162, 163, 192, 193, 224,
    225, 226, 227, -1,  2,   3,   66,  67,
    68,  69,  70,  71,  130, 131, 194, 195,
    196, 197, 198, 199, -1,  4,   5,   6,
    7,   132, 133, 134, 135, 136, 137, 138,
    139, 140, 141, 142, 143, -1,  -1,
};
fn eea(a: anytype, b: @TypeOf(a)) EeaResult(@TypeOf(a)) {
    if (a == 0) {
        return .{ .gcd = b, .x = 0, .y = 1 };
    }
    const r = eea(@rem(b, a), a);
    return .{ .gcd = r.gcd, .x = r.y -% @divTrunc(b, a) *% r.x, .y = r.x };
}
fn EeaResult(comptime T: type) type {
    return struct { gcd: T, x: T, y: T };
}
fn lcm(a: anytype, b: @TypeOf(a)) @TypeOf(a) {
    const r = eea(a, b);
    return a *% b / r.gcd;
}
fn invertMod(a: anytype, p: @TypeOf(a)) @TypeOf(a) {
    const r = eea(a, p);
    debug.assert(r.gcd == 1);
    return r.x;
}
pub fn modQ32(x: i32) i16 {
    var y = @as(i16, @intCast(@rem(x, @as(i32, Q))));
    if (y < 0) {
        y +%= Q;
    }
    return y;
}
pub fn montReduce(x: i32) i16 {
    const qInv = comptime invertMod(@as(i32, Q), R);
    const m = @as(i16, @truncate(@as(i32, @truncate(x *% qInv))));
    const yR = x -% @as(i32, m) *% @as(i32, Q);
    return @as(i16, @bitCast(@as(u16, @truncate(@as(u32, @bitCast(yR)) >> 16))));
}
pub fn feToMont(x: i16) i16 {
    return montReduce(@as(i32, x) *% r2_mod_q);
}
pub fn feBarrettReduce(x: i16) i16 {
    return x -% @as(i16, @intCast((@as(i32, x) *% 20159) >> 26)) *% Q;
}
pub fn csubq(x: i16) i16 {
    var r = x;
    r -%= Q;
    r +%= (r >> 15) & Q;
    return r;
}
pub fn mpow(a: anytype, s: @TypeOf(a), p: @TypeOf(a)) @TypeOf(a) {
    var ret: @TypeOf(a) = 1;
    var s2 = s;
    var a2 = a;
    while (true) {
        if (s2 & 1 == 1) {
            ret = @mod(ret *% a2, p);
        }
        s2 >>= 1;
        if (s2 == 0) {
            break;
        }
        a2 = @mod(a2 *% a2, p);
    }
    return ret;
}
fn computeZetas() [128]i16 {
    @setEvalBranchQuota(10000);
    var ret: [128]i16 = undefined;
    for (&ret, 0..) |*r, i| {
        const t = @as(i16, @intCast(mpow(@as(i32, zeta), @bitReverse(@as(u7, @intCast(i))), Q)));
        r.* = csubq(feBarrettReduce(feToMont(t)));
    }
    return ret;
}
pub const Poly = struct {
    cs: [N]i16,
    const bytes_len = N / 2 *% 3;
    const zero: Poly = .{ .cs = .{0} ** N };
    pub fn add(a: Poly, b: Poly) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = a.cs[i] +% b.cs[i];
        }
        return ret;
    }
    pub fn sub(a: Poly, b: Poly) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = a.cs[i] -% b.cs[i];
        }
        return ret;
    }
    pub fn randAbsLeqQ(rnd: anytype) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = rnd.random().intRangeAtMost(i16, -Q, Q);
        }
        return ret;
    }
    pub fn randNormalized(rnd: anytype) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = rnd.random().intRangeLessThan(i16, 0, Q);
        }
        return ret;
    }
    pub fn ntt(a: Poly) Poly {
        var p = a;
        var k: usize = 0;
        var l = N >> 1;
        while (l > 1) : (l >>= 1) {
            var offset: usize = 0;
            while (offset < N -% l) : (offset +%= 2 *% l) {
                k +%= 1;
                const z = @as(i32, zetas[k]);
                for (offset..offset +% l) |j| {
                    const t = montReduce(z *% @as(i32, p.cs[j +% l]));
                    p.cs[j +% l] = p.cs[j] -% t;
                    p.cs[j] +%= t;
                }
            }
        }
        return p;
    }
    pub fn invNTT(a: Poly) Poly {
        var k: usize = 127;
        var r: usize = 0;
        var p = a;
        var l: usize = 2;
        while (l < N) : (l <<= 1) {
            var offset: usize = 0;
            while (offset < N -% l) : (offset +%= 2 *% l) {
                const minZeta = @as(i32, zetas[k]);
                k -%= 1;
                for (offset..offset +% l) |j| {
                    const t = p.cs[j +% l] -% p.cs[j];
                    p.cs[j] +%= p.cs[j +% l];
                    p.cs[j +% l] = montReduce(minZeta *% @as(i32, t));
                }
            }
            while (true) {
                const i = inv_ntt_reductions[r];
                r +%= 1;
                if (i < 0) {
                    break;
                }
                p.cs[@as(usize, @intCast(i))] = feBarrettReduce(p.cs[@as(usize, @intCast(i))]);
            }
        }
        for (0..N) |j| {
            p.cs[j] = montReduce(r2_over_128 *% @as(i32, p.cs[j]));
        }
        return p;
    }
    pub fn normalize(a: Poly) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = csubq(feBarrettReduce(a.cs[i]));
        }
        return ret;
    }
    pub fn toMont(a: Poly) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = feToMont(a.cs[i]);
        }
        return ret;
    }
    pub fn barrettReduce(a: Poly) Poly {
        var ret: Poly = undefined;
        for (0..N) |i| {
            ret.cs[i] = feBarrettReduce(a.cs[i]);
        }
        return ret;
    }
    fn compressedSize(comptime d: u8) usize {
        return @divTrunc(N *% d, 8);
    }
    pub fn compress(p: Poly, comptime d: u8) [compressedSize(d)]u8 {
        @setRuntimeSafety(builtin.is_safe);
        @setEvalBranchQuota(10000);
        const q_over_2: comptime_int = @divTrunc(Q, 2);
        const two_d_min_1: comptime_int = (1 << d) -% 1;
        var in_off: usize = 0;
        var out_off: usize = 0;
        const batch_size: usize = comptime lcm(@as(i16, d), 8);
        const in_batch_size: usize = comptime batch_size / d;
        const out_batch_size: usize = comptime batch_size / 8;
        const out_len: usize = comptime @divTrunc(N *% d, 8);
        debug.assert(out_len *% 8 == d *% N);
        var out = [_]u8{0} ** out_len;
        while (in_off < N) {
            var in: [in_batch_size]u16 = undefined;
            inline for (0..in_batch_size) |i| {
                const t = @as(u32, @intCast(p.cs[in_off +% i])) << d;
                in[i] = @as(u16, @intCast(@divFloor(t +% q_over_2, Q) & two_d_min_1));
            }
            comptime var in_shift: usize = 0;
            comptime var j: usize = 0;
            comptime var i: usize = 0;
            inline while (i < in_batch_size) : (j +%= 1) {
                comptime var todo: usize = 8;
                inline while (todo > 0) {
                    const out_shift = comptime 8 -% todo;
                    out[out_off +% j] |= @as(u8, @truncate((in[i] >> in_shift) << out_shift));
                    const done = comptime @min(@min(d, todo), d -% in_shift);
                    todo -%= done;
                    in_shift +%= done;
                    if (in_shift == d) {
                        in_shift = 0;
                        i +%= 1;
                    }
                }
            }
            in_off +%= in_batch_size;
            out_off +%= out_batch_size;
        }
        return out;
    }
    pub fn decompress(comptime d: u8, in: *const [compressedSize(d)]u8) Poly {
        @setRuntimeSafety(builtin.is_safe);
        @setEvalBranchQuota(10000);
        const in_len: comptime_int = @divTrunc(N *% d, 8);
        debug.assertEqual(comptime_int, in_len *% 8, d *% N);
        var ret: Poly = undefined;
        var in_off: usize = 0;
        var out_off: usize = 0;
        const batch_size: usize = comptime lcm(@as(i16, d), 8);
        const in_batch_size: usize = comptime batch_size / 8;
        const out_batch_size: usize = comptime batch_size / d;
        while (out_off < N) {
            comptime var in_shift: usize = 0;
            comptime var j: usize = 0;
            comptime var i: usize = 0;
            inline while (i < out_batch_size) : (i +%= 1) {
                comptime var todo = d;
                var out: u16 = 0;
                inline while (todo > 0) {
                    const out_shift = comptime d -% todo;
                    const m = comptime (1 << d) -% 1;
                    out |= (@as(u16, in[in_off +% j] >> in_shift) << out_shift) & m;
                    const done = comptime @min(@min(8, todo), 8 -% in_shift);
                    todo -%= done;
                    in_shift +%= done;
                    if (in_shift == 8) {
                        in_shift = 0;
                        j +%= 1;
                    }
                }
                const qx = @as(u32, out) *% @as(u32, Q);
                ret.cs[out_off +% i] = @as(i16, @intCast((qx +% (1 << (d -% 1))) >> d));
            }
            in_off +%= in_batch_size;
            out_off +%= out_batch_size;
        }
        return ret;
    }
    pub fn mulHat(a: Poly, b: Poly) Poly {
        var p: Poly = undefined;
        var k: usize = 64;
        var i: usize = 0;
        while (i < N) : (i +%= 4) {
            const z = @as(i32, zetas[k]);
            k +%= 1;
            const a1b1 = montReduce(@as(i32, a.cs[i +% 1]) *% @as(i32, b.cs[i +% 1]));
            const a0b0 = montReduce(@as(i32, a.cs[i]) *% @as(i32, b.cs[i]));
            const a1b0 = montReduce(@as(i32, a.cs[i +% 1]) *% @as(i32, b.cs[i]));
            const a0b1 = montReduce(@as(i32, a.cs[i]) *% @as(i32, b.cs[i +% 1]));
            p.cs[i] = montReduce(a1b1 *% z) +% a0b0;
            p.cs[i +% 1] = a0b1 +% a1b0;
            const a3b3 = montReduce(@as(i32, a.cs[i +% 3]) *% @as(i32, b.cs[i +% 3]));
            const a2b2 = montReduce(@as(i32, a.cs[i +% 2]) *% @as(i32, b.cs[i +% 2]));
            const a3b2 = montReduce(@as(i32, a.cs[i +% 3]) *% @as(i32, b.cs[i +% 2]));
            const a2b3 = montReduce(@as(i32, a.cs[i +% 2]) *% @as(i32, b.cs[i +% 3]));
            p.cs[i +% 2] = a2b2 -% montReduce(a3b3 *% z);
            p.cs[i +% 3] = a2b3 +% a3b2;
        }
        return p;
    }
    pub fn noise(comptime eta: u8, nonce: u8, seed: *const [32]u8) Poly {
        var h: hash.Shake256 = .{};
        const suffix: [1]u8 = .{nonce};
        h.update(seed);
        h.update(&suffix);
        const buf_len = comptime 2 *% eta *% N / 8;
        var buf: [buf_len]u8 = undefined;
        h.squeeze(&buf);
        const T = switch (builtin.target.cpu.arch) {
            .x86_64, .x86 => u32,
            else => u64,
        };
        comptime var batch_count: usize = undefined;
        comptime var batch_bytes: usize = undefined;
        comptime var mask: T = 0;
        comptime {
            batch_count = @bitSizeOf(T) / @as(usize, 2 *% eta);
            while (@rem(N, batch_count) != 0 and batch_count > 0) : (batch_count -%= 1) {}
            debug.assert(batch_count > 0);
            debug.assert(@rem(2 *% eta *% batch_count, 8) == 0);
            batch_bytes = 2 *% eta *% batch_count / 8;
            for (0..2 *% eta *% batch_count) |_| {
                mask <<= eta;
                mask |= 1;
            }
        }
        var ret: Poly = undefined;
        for (0..comptime N / batch_count) |i| {
            var t: T = 0;
            inline for (0..batch_bytes) |j| {
                t |= @as(T, buf[batch_bytes *% i +% j]) << (8 *% j);
            }
            var d: T = 0;
            inline for (0..eta) |j| {
                d +%= (t >> j) & mask;
            }
            inline for (0..batch_count) |j| {
                const mask2 = comptime (1 << eta) -% 1;
                const a = @as(i16, @intCast((d >> (comptime (2 *% j *% eta))) & mask2));
                const b = @as(i16, @intCast((d >> (comptime ((2 *% j +% 1) *% eta))) & mask2));
                ret.cs[batch_count *% i +% j] = a -% b;
            }
        }
        return ret;
    }
    pub fn uniform(seed: [32]u8, x: u8, y: u8) Poly {
        var h: hash.Shake128 = .{};
        const suffix: [2]u8 = .{ x, y };
        h.update(&seed);
        h.update(&suffix);
        const buf_len = hash.Shake128.blk_len;
        var buf: [buf_len]u8 = undefined;
        var ret: Poly = undefined;
        var i: usize = 0;
        outer: while (true) {
            h.squeeze(&buf);
            var j: usize = 0;
            while (j < buf_len) : (j +%= 3) {
                const b0 = @as(u16, buf[j]);
                const b1 = @as(u16, buf[j +% 1]);
                const b2 = @as(u16, buf[j +% 2]);
                const ts: [2]u16 = .{
                    b0 | ((b1 & 0xf) << 8),
                    (b1 >> 4) | (b2 << 4),
                };
                inline for (ts) |t| {
                    if (t < Q) {
                        ret.cs[i] = @as(i16, @intCast(t));
                        i +%= 1;
                        if (i == N) {
                            break :outer;
                        }
                    }
                }
            }
        }
        return ret;
    }
    pub fn toBytes(p: Poly) [bytes_len]u8 {
        var ret: [bytes_len]u8 = undefined;
        for (0..comptime N / 2) |i| {
            const t0 = @as(u16, @intCast(p.cs[2 *% i]));
            const t1 = @as(u16, @intCast(p.cs[2 *% i +% 1]));
            ret[3 *% i] = @as(u8, @truncate(t0));
            ret[3 *% i +% 1] = @as(u8, @truncate((t0 >> 8) | (t1 << 4)));
            ret[3 *% i +% 2] = @as(u8, @truncate(t1 >> 4));
        }
        return ret;
    }
    pub fn fromBytes(buf: *const [bytes_len]u8) Poly {
        var ret: Poly = undefined;
        for (0..comptime N / 2) |i| {
            const b0 = @as(i16, buf[3 *% i]);
            const b1 = @as(i16, buf[3 *% i +% 1]);
            const b2 = @as(i16, buf[3 *% i +% 2]);
            ret.cs[2 *% i] = b0 | ((b1 & 0xf) << 8);
            ret.cs[2 *% i +% 1] = (b1 >> 4) | b2 << 4;
        }
        return ret;
    }
};
fn Vec(comptime K: u8) type {
    return struct {
        ps: [K]Poly,
        const Self = @This();
        const bytes_len = K *% Poly.bytes_len;
        fn compressedSize(comptime d: u8) usize {
            return Poly.compressedSize(d) *% K;
        }
        fn ntt(a: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].ntt();
            }
            return ret;
        }
        fn invNTT(a: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].invNTT();
            }
            return ret;
        }
        fn normalize(a: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].normalize();
            }
            return ret;
        }
        pub fn barrettReduce(a: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].barrettReduce();
            }
            return ret;
        }
        fn add(a: Self, b: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].add(b.ps[i]);
            }
            return ret;
        }
        fn sub(a: Self, b: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = a.ps[i].sub(b.ps[i]);
            }
            return ret;
        }
        fn noise(comptime eta: u8, nonce: u8, seed: *const [32]u8) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                ret.ps[i] = Poly.noise(eta, nonce +% @as(u8, @intCast(i)), seed);
            }
            return ret;
        }
        fn dotHat(a: Self, b: Self) Poly {
            var ret: Poly = Poly.zero;
            inline for (0..K) |i| {
                ret = ret.add(a.ps[i].mulHat(b.ps[i]));
            }
            return ret;
        }
        fn compress(v: Self, comptime d: u8) [compressedSize(d)]u8 {
            const cs = comptime Poly.compressedSize(d);
            var ret: [compressedSize(d)]u8 = undefined;
            inline for (0..K) |i| {
                ret[i *% cs .. (i +% 1) *% cs].* = v.ps[i].compress(d);
            }
            return ret;
        }
        fn decompress(comptime d: u8, buf: *const [compressedSize(d)]u8) Self {
            const cs = comptime Poly.compressedSize(d);
            var ret: Self = undefined;
            inline for (0..K) |i| {
                ret.ps[i] = Poly.decompress(d, buf[i *% cs .. (i +% 1) *% cs]);
            }
            return ret;
        }
        fn toBytes(v: Self) [bytes_len]u8 {
            var ret: [bytes_len]u8 = undefined;
            inline for (0..K) |i| {
                ret[i *% Poly.bytes_len .. (i +% 1) *% Poly.bytes_len].* = v.ps[i].toBytes();
            }
            return ret;
        }
        fn fromBytes(buf: *const [bytes_len]u8) Self {
            var ret: Self = undefined;
            inline for (0..K) |i| {
                ret.ps[i] = Poly.fromBytes(
                    buf[i *% Poly.bytes_len .. (i +% 1) *% Poly.bytes_len],
                );
            }
            return ret;
        }
    };
}
fn Mat(comptime K: u8) type {
    return struct {
        const Self = @This();
        vs: [K]Vec(K),
        fn uniform(seed: [32]u8, comptime transposed: bool) Self {
            var ret: Self = undefined;
            var i: u8 = 0;
            while (i < K) : (i +%= 1) {
                var j: u8 = 0;
                while (j < K) : (j +%= 1) {
                    ret.vs[i].ps[j] = Poly.uniform(
                        seed,
                        if (transposed) i else j,
                        if (transposed) j else i,
                    );
                }
            }
            return ret;
        }
        fn transpose(m: Self) Self {
            var ret: Self = undefined;
            for (0..K) |i| {
                for (0..K) |j| {
                    ret.vs[i].ps[j] = m.vs[j].ps[i];
                }
            }
            return ret;
        }
    };
}
fn ctneq(comptime len: usize, a: [len]u8, b: [len]u8) u1 {
    return 1 -% @intFromBool(utils.timingSafeEql([len]u8, a, b));
}
fn cmov(comptime len: usize, dst: *[len]u8, src: [len]u8, b: u1) void {
    const mask = @as(u8, 0) -% b;
    for (0..len) |i| {
        dst[i] ^= mask & (dst[i] ^ src[i]);
    }
}
const NistDRBG = struct {
    key: [32]u8,
    v: [16]u8,
    fn incV(g: *NistDRBG) void {
        var j: usize = 15;
        while (j >= 0) : (j -%= 1) {
            if (g.v[j] == 255) {
                g.v[j] = 0;
            } else {
                g.v[j] +%= 1;
                break;
            }
        }
    }
    fn update(g: *NistDRBG, pd: ?[48]u8) void {
        var buf: [48]u8 = undefined;
        const ctx = core.Aes256.initEnc(g.key);
        var i: usize = 0;
        while (i < 3) : (i +%= 1) {
            g.incV();
            var block: [16]u8 = undefined;
            ctx.encrypt(&block, &g.v);
            buf[i *% 16 ..][0..16].* = block;
        }
        if (pd) |p| {
            for (&buf, p) |*b, x| {
                b.* ^= x;
            }
        }
        g.key = buf[0..32].*;
        g.v = buf[32..48].*;
    }
    fn fill(g: *NistDRBG, out: []u8) void {
        var block: [16]u8 = undefined;
        var dst = out;
        const ctx = core.Aes256.initEnc(g.key);
        while (dst.len > 0) {
            g.incV();
            ctx.encrypt(&block, &g.v);
            if (dst.len < 16) {
                @memcpy(dst, block[0..dst.len]);
                break;
            }
            dst[0..block.len].* = block;
            dst = dst[16..dst.len];
        }
        g.update(null);
    }
    fn init(seed: [48]u8) NistDRBG {
        var ret: NistDRBG = .{ .key = .{0} ** 32, .v = .{0} ** 16 };
        ret.update(seed);
        return ret;
    }
};
