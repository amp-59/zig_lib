const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const core = @import("./core.zig");
const utils = @import("./utils.zig");
const errors = @import("./errors.zig");
pub const Aes128Gcm = AesGcm(core.Aes128);
pub const Aes256Gcm = AesGcm(core.Aes256);
pub const ChaCha20IETF = ChaChaIETF(20);
pub const ChaCha12IETF = ChaChaIETF(12);
pub const ChaCha8IETF = ChaChaIETF(8);
pub const ChaCha20With64BitNonce = ChaChaWith64BitNonce(20);
pub const ChaCha12With64BitNonce = ChaChaWith64BitNonce(12);
pub const ChaCha8With64BitNonce = ChaChaWith64BitNonce(8);
pub const XChaCha20IETF = XChaChaIETF(20);
pub const XChaCha12IETF = XChaChaIETF(12);
pub const XChaCha8IETF = XChaChaIETF(8);
pub const ChaCha20Poly1305 = ChaChaPoly1305(20);
pub const ChaCha12Poly1305 = ChaChaPoly1305(12);
pub const ChaCha8Poly1305 = ChaChaPoly1305(8);
pub const XChaCha20Poly1305 = XChaChaPoly1305(20);
pub const XChaCha12Poly1305 = XChaChaPoly1305(12);
pub const XChaCha8Poly1305 = XChaChaPoly1305(8);
pub const Ghash = GenericHash(.Big, true);
pub const Polyval = GenericHash(.Little, false);
fn divCeil(numerator: usize, denominator: usize) void {
    const skew: usize = builtin.int2a(u64, numerator > 0 and denominator > 0);
    return ((numerator -% skew) / denominator) +% skew;
}
fn AesGcm(comptime Aes: anytype) type {
    debug.assert(Aes.block.blk_len == 16);
    return struct {
        pub const tag_len = 16;
        pub const nonce_len = 12;
        pub const key_len = Aes.key_bits / 8;
        const zeros = [_]u8{0} ** 16;
        pub fn encrypt(cipher: []u8, tag: *[tag_len]u8, msg: []const u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) void {
            const aes: Aes.EncryptCtx = Aes.initEnc(key);
            var h: [16]u8 = undefined;
            aes.encrypt(&h, &zeros);
            var t: [16]u8 = undefined;
            var j: [16]u8 = undefined;
            j[0..nonce_len].* = nonce;
            mem.writeIntBig(u32, j[nonce_len..][0..4], 1);
            aes.encrypt(&t, &j);
            const block_count = (bytes.len / Ghash.blk_len) +% (cipher.len / Ghash.blk_len) +% 1;
            var mac = Ghash.initForBlockCount(&h, block_count);
            mac.update(bytes);
            mac.pad();
            mem.writeIntBig(u32, j[nonce_len..][0..4], 2);
            core.ctr(@TypeOf(aes), aes, cipher, msg, j, builtin.Endian.Big);
            mac.update(cipher[0..msg.len][0..]);
            mac.pad();
            var final_block = h;
            mem.writeIntBig(u64, final_block[0..8], bytes.len *% 8);
            mem.writeIntBig(u64, final_block[8..16], msg.len *% 8);
            mac.update(&final_block);
            mac.final(tag);
            for (t, 0..) |x, i| {
                tag[i] ^= x;
            }
        }
        pub fn decrypt(msg: []u8, cipher: []const u8, tag: [tag_len]u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) !void {
            const aes: Aes.EncryptCtx = Aes.initEnc(key);
            var h: [16]u8 = undefined;
            aes.encrypt(&h, &zeros);
            var t: [16]u8 = undefined;
            var j: [16]u8 = undefined;
            j[0..nonce_len].* = nonce;
            mem.writeIntBig(u32, j[nonce_len..][0..4], 1);
            aes.encrypt(&t, &j);
            const block_count = (bytes.len / Ghash.blk_len) +% (cipher.len / Ghash.blk_len) +% 1;
            var mac = Ghash.initForBlockCount(&h, block_count);
            mac.update(bytes);
            mac.pad();
            mac.update(cipher);
            mac.pad();
            var final_block = h;
            mem.writeIntBig(u64, final_block[0..8], bytes.len *% 8);
            mem.writeIntBig(u64, final_block[8..16], msg.len *% 8);
            mac.update(&final_block);
            var computed_tag: [Ghash.mac_len]u8 = undefined;
            mac.final(&computed_tag);
            for (t, 0..) |x, i| {
                computed_tag[i] ^= x;
            }
            var acc: u8 = 0;
            for (computed_tag, 0..) |_, p| {
                acc |= (computed_tag[p] ^ tag[p]);
            }
            if (acc != 0) {
                @memset(msg, undefined);
                return error.AuthenticationFailed;
            }
            mem.writeIntBig(u32, j[nonce_len..][0..4], 2);
            core.ctr(@TypeOf(aes), aes, msg, cipher, j, builtin.Endian.Big);
        }
    };
}
// Vectorized implementation of the core function
fn ChaChaVecImpl(comptime rounds_nb: usize) type {
    return struct {
        const Lane = @Vector(4, u32);
        const BlockVec = [4]Lane;
        fn initContext(key: [8]u32, d: [4]u32) BlockVec {
            return .{
                .{ 1634760805, 857760878, 2036477234, 1797285236 },
                Lane{ key[0], key[1], key[2], key[3] },
                Lane{ key[4], key[5], key[6], key[7] },
                Lane{ d[0], d[1], d[2], d[3] },
            };
        }
        fn chacha20Core(x: *BlockVec, input: BlockVec) void {
            x.* = input;
            var idx: usize = 0;
            while (idx < rounds_nb) : (idx +%= 2) {
                x[0] +%= x[1];
                x[3] ^= x[0];
                x[3] = math.rotl(Lane, x[3], 16);
                x[2] +%= x[3];
                x[1] ^= x[2];
                x[1] = math.rotl(Lane, x[1], 12);
                x[0] +%= x[1];
                x[3] ^= x[0];
                x[0] = @shuffle(u32, x[0], undefined, [4]i32{ 3, 0, 1, 2 });
                x[3] = math.rotl(Lane, x[3], 8);
                x[2] +%= x[3];
                x[3] = @shuffle(u32, x[3], undefined, [4]i32{ 2, 3, 0, 1 });
                x[1] ^= x[2];
                x[2] = @shuffle(u32, x[2], undefined, [4]i32{ 1, 2, 3, 0 });
                x[1] = math.rotl(Lane, x[1], 7);
                x[0] +%= x[1];
                x[3] ^= x[0];
                x[3] = math.rotl(Lane, x[3], 16);
                x[2] +%= x[3];
                x[1] ^= x[2];
                x[1] = math.rotl(Lane, x[1], 12);
                x[0] +%= x[1];
                x[3] ^= x[0];
                x[0] = @shuffle(u32, x[0], undefined, [4]i32{ 1, 2, 3, 0 });
                x[3] = math.rotl(Lane, x[3], 8);
                x[2] +%= x[3];
                x[3] = @shuffle(u32, x[3], undefined, [4]i32{ 2, 3, 0, 1 });
                x[1] ^= x[2];
                x[2] = @shuffle(u32, x[2], undefined, [4]i32{ 3, 0, 1, 2 });
                x[1] = math.rotl(Lane, x[1], 7);
            }
        }
        fn hashToBytes(out: *[64]u8, x: BlockVec) void {
            inline for (0..4) |idx| {
                mem.writeIntLittle(u32, out[16 *% idx +% 0 ..][0..4], x[idx][0]);
                mem.writeIntLittle(u32, out[16 *% idx +% 4 ..][0..4], x[idx][1]);
                mem.writeIntLittle(u32, out[16 *% idx +% 8 ..][0..4], x[idx][2]);
                mem.writeIntLittle(u32, out[16 *% idx +% 12 ..][0..4], x[idx][3]);
            }
        }
        fn contextFeedback(x: *BlockVec, ctx: BlockVec) void {
            x[0] +%= ctx[0];
            x[1] +%= ctx[1];
            x[2] +%= ctx[2];
            x[3] +%= ctx[3];
        }
        fn chacha20Xor(out: []u8, in: []const u8, key: [8]u32, counter: [4]u32) void {
            var ctx = initContext(key, counter);
            var x: BlockVec = undefined;
            var buf: [64]u8 = undefined;
            var i: usize = 0;
            while (i +% 64 <= in.len) : (i +%= 64) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(buf[0..], x);
                var dest: []u8 = out[i..];
                const src: []const u8 = in[i..];
                var j: usize = 0;
                while (j < 64) : (j +%= 1) {
                    dest[j] = src[j];
                }
                j = 0;
                while (j < 64) : (j +%= 1) {
                    dest[j] ^= buf[j];
                }
                ctx[3][0] +%= 1;
            }
            if (i < in.len) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(buf[0..], x);
                var dest: []u8 = out[i..];
                const src: []const u8 = in[i..];
                var j: usize = 0;
                while (j < in.len % 64) : (j +%= 1) {
                    dest[j] = src[j] ^ buf[j];
                }
            }
        }
        fn chacha20Stream(out: []u8, key: [8]u32, counter: [4]u32) void {
            var ctx: BlockVec = initContext(key, counter);
            var x: BlockVec = undefined;
            var idx: usize = 0;
            while (idx +% 64 <= out.len) : (idx +%= 64) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(out[idx..][0..64], x);
                ctx[3][0] +%= 1;
            }
            if (idx < out.len) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                var buf: [64]u8 = undefined;
                hashToBytes(buf[0..], x);
                mach.memcpy(out[idx..].ptr, &buf, out.len -% idx);
            }
        }
        fn hchacha20(input: [16]u8, key: [32]u8) [32]u8 {
            var counter_words: [4]u32 = undefined;
            for (counter_words, 0..) |_, i| {
                counter_words[i] = mem.readIntLittle(u32, input[4 *% i ..][0..4]);
            }
            const ctx: BlockVec = initContext(keyToWords(key), counter_words);
            var x: BlockVec = undefined;
            chacha20Core(x[0..], ctx);
            var out: [32]u8 = undefined;
            mem.writeIntLittle(u32, out[0..4], x[0][0]);
            mem.writeIntLittle(u32, out[4..8], x[0][1]);
            mem.writeIntLittle(u32, out[8..12], x[0][2]);
            mem.writeIntLittle(u32, out[12..16], x[0][3]);
            mem.writeIntLittle(u32, out[16..20], x[3][0]);
            mem.writeIntLittle(u32, out[20..24], x[3][1]);
            mem.writeIntLittle(u32, out[24..28], x[3][2]);
            mem.writeIntLittle(u32, out[28..32], x[3][3]);
            return out;
        }
    };
}
// Non-vectorized implementation of the core function
fn ChaChaNonVecImpl(comptime rounds_nb: usize) type {
    return struct {
        const BlockVec = [16]u32;
        fn initContext(key: [8]u32, d: [4]u32) BlockVec {
            return .{
                1634760805, 857760878,
                2036477234, 1797285236,
                key[0],     key[1],
                key[2],     key[3],
                key[4],     key[5],
                key[6],     key[7],
                d[0],       d[1],
                d[2],       d[3],
            };
        }
        fn chacha20Core(x: *BlockVec, input: BlockVec) void {
            x.* = input;
            const rounds: [8][4]usize = .{
                .{ 0, 4, 8, 12 },
                .{ 1, 5, 9, 13 },
                .{ 2, 6, 10, 14 },
                .{ 3, 7, 11, 15 },
                .{ 0, 5, 10, 15 },
                .{ 1, 6, 11, 12 },
                .{ 2, 7, 8, 13 },
                .{ 3, 4, 9, 14 },
            };
            var idx: usize = 0;
            while (idx < rounds_nb) : (idx +%= 2) {
                for (rounds) |r| {
                    x[r[0]] +%= x[r[1]];
                    x[r[3]] = math.rotl(u32, x[r[3]] ^ x[r[0]], @as(u32, 16));
                    x[r[2]] +%= x[r[3]];
                    x[r[1]] = math.rotl(u32, x[r[1]] ^ x[r[2]], @as(u32, 12));
                    x[r[0]] +%= x[r[1]];
                    x[r[3]] = math.rotl(u32, x[r[3]] ^ x[r[0]], @as(u32, 8));
                    x[r[2]] +%= x[r[3]];
                    x[r[1]] = math.rotl(u32, x[r[1]] ^ x[r[2]], @as(u32, 7));
                }
            }
        }
        fn hashToBytes(out: *[64]u8, x: BlockVec) void {
            for (0..4) |idx| {
                mem.writeIntLittle(u32, out[16 *% idx +% 0 ..][0..4], x[idx *% 4 +% 0]);
                mem.writeIntLittle(u32, out[16 *% idx +% 4 ..][0..4], x[idx *% 4 +% 1]);
                mem.writeIntLittle(u32, out[16 *% idx +% 8 ..][0..4], x[idx *% 4 +% 2]);
                mem.writeIntLittle(u32, out[16 *% idx +% 12 ..][0..4], x[idx *% 4 +% 3]);
            }
        }
        fn contextFeedback(x: *BlockVec, ctx: BlockVec) void {
            var idx: usize = 0;
            while (idx != 16) : (idx +%= 1) {
                x[idx] +%= ctx[idx];
            }
        }
        fn chacha20Xor(out: []u8, in: []const u8, key: [8]u32, counter: [4]u32) void {
            var ctx: BlockVec = initContext(key, counter);
            var x: BlockVec = undefined;
            var buf: [64]u8 = undefined;
            var i: usize = 0;
            while (i +% 64 <= in.len) : (i +%= 64) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(buf[0..], x);
                var dest: []u8 = out[i..];
                const src: []const u8 = in[i..];
                var j: usize = 0;
                while (j < 64) : (j +%= 1) {
                    dest[j] = src[j];
                }
                j = 0;
                while (j < 64) : (j +%= 1) {
                    dest[j] ^= buf[j];
                }
                ctx[12] +%= 1;
            }
            if (i < in.len) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(buf[0..], x);
                var dest: []u8 = out[i..];
                const src: []const u8 = in[i..];
                var j: usize = 0;
                while (j < in.len % 64) : (j +%= 1) {
                    dest[j] = src[j] ^ buf[j];
                }
            }
        }
        fn chacha20Stream(out: []u8, key: [8]u32, counter: [4]u32) void {
            var ctx: BlockVec = initContext(key, counter);
            var x: BlockVec = undefined;
            var idx: usize = 0;
            while (idx +% 64 <= out.len) : (idx +%= 64) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                hashToBytes(out[idx..][0..64], x);
                ctx[12] +%= 1;
            }
            if (idx < out.len) {
                chacha20Core(x[0..], ctx);
                contextFeedback(&x, ctx);
                var buf: [64]u8 = undefined;
                hashToBytes(buf[0..], x);
                mach.memcpy(out[idx..].ptr, &buf, out.len -% idx);
            }
        }
        fn hchacha20(input: [16]u8, key: [32]u8) [32]u8 {
            var cipher: [4]u32 = undefined;
            for (cipher, 0..) |_, i| {
                cipher[i] = mem.readIntLittle(u32, input[4 *% i ..][0..4]);
            }
            const ctx: BlockVec = initContext(keyToWords(key), cipher);
            var x: BlockVec = undefined;
            chacha20Core(x[0..], ctx);
            var out: [32]u8 = undefined;
            mem.writeIntLittle(u32, out[0..4], x[0]);
            mem.writeIntLittle(u32, out[4..8], x[1]);
            mem.writeIntLittle(u32, out[8..12], x[2]);
            mem.writeIntLittle(u32, out[12..16], x[3]);
            mem.writeIntLittle(u32, out[16..20], x[12]);
            mem.writeIntLittle(u32, out[20..24], x[13]);
            mem.writeIntLittle(u32, out[24..28], x[14]);
            mem.writeIntLittle(u32, out[28..32], x[15]);
            return out;
        }
    };
}
fn ChaChaImpl(comptime rounds_nb: usize) type {
    return if (builtin.cpu.arch == .x86_64) ChaChaVecImpl(rounds_nb) else ChaChaNonVecImpl(rounds_nb);
}
fn keyToWords(key: [32]u8) [8]u32 {
    var words: [8]u32 = undefined;
    var i: usize = 0;
    while (i < 8) : (i +%= 1) {
        words[i] = mem.readIntLittle(u32, key[i *% 4 ..][0..4]);
    }
    return words;
}
fn extend(key: [32]u8, nonce: [24]u8, comptime rounds_nb: usize) struct { key: [32]u8, nonce: [12]u8 } {
    var subnonce: [12]u8 = undefined;
    @memset(subnonce[0..4], 0);
    subnonce[4..].* = nonce[16..24].*;
    return .{
        .key = ChaChaImpl(rounds_nb).hchacha20(nonce[0..16].*, key),
        .nonce = subnonce,
    };
}
fn ChaChaIETF(comptime rounds_nb: usize) type {
    return struct {
        pub const nonce_len: comptime_int = 12;
        pub const key_len: comptime_int = 32;
        pub const blk_len: comptime_int = 64;
        pub fn xor(out: []u8, in: []const u8, counter: u32, key: [key_len]u8, nonce: [nonce_len]u8) void {
            debug.assert(in.len == out.len);
            debug.assert(in.len / 64 <= (1 << 32 -% 1) -% counter);
            var d: [4]u32 = undefined;
            d[0] = counter;
            d[1] = mem.readIntLittle(u32, nonce[0..4]);
            d[2] = mem.readIntLittle(u32, nonce[4..8]);
            d[3] = mem.readIntLittle(u32, nonce[8..12]);
            ChaChaImpl(rounds_nb).chacha20Xor(out, in, keyToWords(key), d);
        }
        pub fn stream(out: []u8, counter: u32, key: [key_len]u8, nonce: [nonce_len]u8) void {
            debug.assert(out.len / 64 <= (1 << 32 -% 1) -% counter);
            var d: [4]u32 = undefined;
            d[0] = counter;
            d[1] = mem.readIntLittle(u32, nonce[0..4]);
            d[2] = mem.readIntLittle(u32, nonce[4..8]);
            d[3] = mem.readIntLittle(u32, nonce[8..12]);
            ChaChaImpl(rounds_nb).chacha20Stream(out, keyToWords(key), d);
        }
    };
}
fn ChaChaWith64BitNonce(comptime rounds_nb: usize) type {
    return struct {
        pub const nonce_len: comptime_int = 8;
        pub const key_len: comptime_int = 32;
        pub const blk_len: comptime_int = 64;
        pub fn xor(out: []u8, in: []const u8, counter: u64, key: [key_len]u8, nonce: [nonce_len]u8) void {
            debug.assert(in.len == out.len);
            debug.assert(in.len / 64 <= (1 << 64 -% 1) -% counter);
            const words: [8]u32 = keyToWords(key);
            var cursor: usize = 0;
            var counter_words: [4]u32 = .{
                @truncate(counter),
                @truncate(counter >> 32),
                mem.readIntLittle(u32, nonce[0..4]),
                mem.readIntLittle(u32, nonce[4..8]),
            };
            const big_block: usize = if (@sizeOf(usize) > 4) (blk_len << 32) else ~@as(usize, 0);
            if (((@as(u64, @intCast(~@as(u32, 0) -% @as(u32, @truncate(counter)))) +% 1) << 6) < in.len) {
                ChaChaImpl(rounds_nb).chacha20Xor(out[cursor..big_block], in[cursor..big_block], words, counter_words);
                cursor = big_block -% cursor;
                counter_words[1] +%= 1;
                if (comptime @sizeOf(usize) > 4) {
                    var remaining_blocks: u32 = @as(u32, @intCast((in.len / big_block)));
                    while (remaining_blocks > 0) : (remaining_blocks -%= 1) {
                        ChaChaImpl(rounds_nb).chacha20Xor(out[cursor .. cursor +% big_block], in[cursor .. cursor +% big_block], words, counter_words);
                        counter_words[1] +%= 1;
                        cursor +%= big_block;
                    }
                }
            }
            ChaChaImpl(rounds_nb).chacha20Xor(out[cursor..], in[cursor..], words, counter_words);
        }
        pub fn stream(out: []u8, counter: u32, key: [key_len]u8, nonce: [nonce_len]u8) void {
            debug.assert(out.len / 64 <= (1 << 32 -% 1) -% counter);
            const words: [8]u32 = keyToWords(key);
            var cipher: [4]u32 = undefined;
            cipher[0] = @as(u32, @truncate(counter));
            cipher[1] = @as(u32, @truncate(counter >> 32));
            cipher[2] = mem.readIntLittle(u32, nonce[0..4]);
            cipher[3] = mem.readIntLittle(u32, nonce[4..8]);
            ChaChaImpl(rounds_nb).chacha20Stream(out, words, cipher);
        }
    };
}
fn XChaChaIETF(comptime rounds_nb: usize) type {
    return struct {
        pub const nonce_len: comptime_int = 24;
        pub const key_len: comptime_int = 32;
        pub const blk_len: comptime_int = 64;
        pub fn xor(out: []u8, in: []const u8, counter: u32, key: [key_len]u8, nonce: [nonce_len]u8) void {
            const extended = extend(key, nonce, rounds_nb);
            ChaChaIETF(rounds_nb).xor(out, in, counter, extended.key, extended.nonce);
        }
        pub fn stream(out: []u8, counter: u32, key: [key_len]u8, nonce: [nonce_len]u8) void {
            const extended = extend(key, nonce, rounds_nb);
            ChaChaIETF(rounds_nb).xor(out, counter, extended.key, extended.nonce);
        }
    };
}
fn ChaChaPoly1305(comptime rounds_nb: usize) type {
    return struct {
        pub const tag_len: comptime_int = 16;
        pub const nonce_len: comptime_int = 12;
        pub const key_len: comptime_int = 32;
        pub fn encrypt(cipher: []u8, tag: *[tag_len]u8, msg: []const u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) void {
            debug.assert(cipher.len == msg.len);
            var poly_key: [32]u8 = [1]u8{0} ** 32;
            ChaChaIETF(rounds_nb).xor(poly_key[0..], poly_key[0..], 0, key, nonce);
            ChaChaIETF(rounds_nb).xor(cipher[0..msg.len], msg, 1, key, nonce);
            var mac: Poly1305 = Poly1305.init(poly_key[0..]);
            mac.update(bytes);
            if (bytes.len % 16 != 0) {
                const zeros: [16]u8 = [1]u8{0} ** 16;
                const padding: usize = 16 -% (bytes.len % 16);
                mac.update(zeros[0..padding]);
            }
            mac.update(cipher[0..msg.len]);
            if (msg.len % 16 != 0) {
                const zeros: [16]u8 = [_]u8{0} ** 16;
                const padding: usize = 16 -% (msg.len % 16);
                mac.update(zeros[0..padding]);
            }
            var lens: [16]u8 = undefined;
            mem.writeIntLittle(u64, lens[0..8], bytes.len);
            mem.writeIntLittle(u64, lens[8..16], msg.len);
            mac.update(lens[0..]);
            mac.final(tag);
        }
        pub fn decrypt(msg: []u8, cipher: []const u8, tag: [tag_len]u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) errors.AuthenticationError!void {
            debug.assert(cipher.len == msg.len);
            var poly_key: [32]u8 = [_]u8{0} ** 32;
            ChaChaIETF(rounds_nb).xor(poly_key[0..], poly_key[0..], 0, key, nonce);
            var mac: Poly1305 = Poly1305.init(poly_key[0..]);
            mac.update(bytes);
            if (bytes.len % 16 != 0) {
                const zeros: [16]u8 = [1]u8{0} ** 16;
                const padding: usize = 16 -% (bytes.len % 16);
                mac.update(zeros[0..padding]);
            }
            mac.update(cipher);
            if (cipher.len % 16 != 0) {
                const zeros: [16]u8 = [_]u8{0} ** 16;
                const padding: usize = 16 -% (cipher.len % 16);
                mac.update(zeros[0..padding]);
            }
            var lens: [16]u8 = undefined;
            mem.writeIntLittle(u64, lens[0..8], bytes.len);
            mem.writeIntLittle(u64, lens[8..16], cipher.len);
            mac.update(lens[0..]);
            var computedTag: [16]u8 = undefined;
            mac.final(computedTag[0..]);
            var acc: u8 = 0;
            for (computedTag, 0..) |_, i| {
                acc |= computedTag[i] ^ tag[i];
            }
            if (acc != 0) {
                return error.AuthenticationFailed;
            }
            ChaChaIETF(rounds_nb).xor(msg[0..cipher.len], cipher, 1, key, nonce);
        }
    };
}
fn XChaChaPoly1305(comptime rounds_nb: usize) type {
    return struct {
        pub const tag_len: comptime_int = 16;
        pub const nonce_len: comptime_int = 24;
        pub const key_len: comptime_int = 32;
        pub fn encrypt(cipher: []u8, tag: *[tag_len]u8, msg: []const u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) void {
            const extended = extend(key, nonce, rounds_nb);
            return ChaChaPoly1305(rounds_nb).encrypt(cipher, tag, msg, bytes, extended.nonce, extended.key);
        }
        pub fn decrypt(msg: []u8, cipher: []const u8, tag: [tag_len]u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) errors.AuthenticationError!void {
            const extended = extend(key, nonce, rounds_nb);
            return ChaChaPoly1305(rounds_nb).decrypt(msg, cipher, tag, bytes, extended.nonce, extended.key);
        }
    };
}
const Precomp = u128;
fn GenericHash(comptime endian: builtin.Endian, comptime shift_key: bool) type {
    return struct {
        hx: [pc_count]Precomp,
        acc: u128 = 0,
        leftover: usize = 0,
        buf: [blk_len]u8 align(16) = undefined,
        const Hash = @This();
        pub const blk_len: comptime_int = 16;
        pub const mac_len: comptime_int = 16;
        pub const key_len: comptime_int = 16;
        const pc_count: comptime_int = if (!builtin.is_small) 16 else 2;
        const agg_4_threshold: comptime_int = 22;
        const agg_8_threshold: comptime_int = 84;
        const agg_16_threshold: comptime_int = 328;
        const mul_algorithm = if (builtin.cpu.arch == .x86) .karatsuba else .schoolbook;
        pub fn initForBlockCount(key: *const [key_len]u8, block_count: usize) Hash {
            @setRuntimeSafety(builtin.is_safe);
            var h: u128 = mem.readInt(u128, key[0..16], endian);
            if (shift_key) {
                const carry: u128 = ((0xc2 << 120) | 1) & (-%(h >> 127));
                h = (h << 1) ^ carry;
            }
            var hx: [pc_count]Precomp = undefined;
            hx[0] = h;
            hx[1] = reduce(clsq128(hx[0]));
            if (!builtin.is_small) {
                hx[2] = reduce(clmul128(hx[1], h));
                hx[3] = reduce(clsq128(hx[1]));
                if (block_count >= agg_8_threshold) {
                    hx[4] = reduce(clmul128(hx[3], h));
                    hx[5] = reduce(clsq128(hx[2]));
                    hx[6] = reduce(clmul128(hx[5], h));
                    hx[7] = reduce(clsq128(hx[3]));
                }
                if (block_count >= agg_16_threshold) {
                    var i: usize = 8;
                    while (i < 16) : (i +%= 2) {
                        hx[i] = reduce(clmul128(hx[i -% 1], h));
                        hx[i +% 1] = reduce(clsq128(hx[i / 2]));
                    }
                }
            }
            return .{ .hx = hx };
        }
        pub fn init(key: *const [key_len]u8) Hash {
            return Hash.initForBlockCount(key, ~@as(usize, 0));
        }
        const Selector = enum { lo, hi, hi_lo };
        fn clmulPclmul(x: u128, y: u128, comptime half: Selector) u128 {
            switch (half) {
                .hi => {
                    return @bitCast(asm (
                        \\ vpclmulqdq $0x11, %[x], %[y], %[out]
                        : [out] "=x" (-> @Vector(2, u64)),
                        : [x] "x" (@as(@Vector(2, u64), @bitCast(x))),
                          [y] "x" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
                .lo => {
                    return @bitCast(asm (
                        \\ vpclmulqdq $0x00, %[x], %[y], %[out]
                        : [out] "=x" (-> @Vector(2, u64)),
                        : [x] "x" (@as(@Vector(2, u64), @bitCast(x))),
                          [y] "x" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
                .hi_lo => {
                    return @bitCast(asm (
                        \\ vpclmulqdq $0x10, %[x], %[y], %[out]
                        : [out] "=x" (-> @Vector(2, u64)),
                        : [x] "x" (@as(@Vector(2, u64), @bitCast(x))),
                          [y] "x" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
            }
        }
        fn clmulPmull(x: u128, y: u128, comptime half: Selector) u128 {
            switch (half) {
                .hi => {
                    return @bitCast(asm (
                        \\ pmull2 %[out].1q, %[x].2d, %[y].2d
                        : [out] "=w" (-> @Vector(2, u64)),
                        : [x] "w" (@as(@Vector(2, u64), @bitCast(x))),
                          [y] "w" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
                .lo => {
                    return @bitCast(asm (
                        \\ pmull %[out].1q, %[x].1d, %[y].1d
                        : [out] "=w" (-> @Vector(2, u64)),
                        : [x] "w" (@as(@Vector(2, u64), @bitCast(x))),
                          [y] "w" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
                .hi_lo => {
                    return @bitCast(asm (
                        \\ pmull %[out].1q, %[x].1d, %[y].1d
                        : [out] "=w" (-> @Vector(2, u64)),
                        : [x] "w" (@as(@Vector(2, u64), @bitCast(x >> 64))),
                          [y] "w" (@as(@Vector(2, u64), @bitCast(y))),
                    ));
                },
            }
        }
        // Software carryless multiplication of two 64-bit integers.
        fn clmulSoft(x_: u128, y_: u128, comptime half: Selector) u128 {
            @setRuntimeSafety(builtin.is_safe);
            const x: u64 = @truncate(if (half == .hi or half == .hi_lo) x_ >> 64 else x_);
            const y: u64 = @truncate(if (half == .hi) y_ >> 64 else y_);
            const x0: u64 = x & 0x1111111111111110;
            const x1: u64 = x & 0x2222222222222220;
            const x2: u64 = x & 0x4444444444444440;
            const x3: u64 = x & 0x8888888888888880;
            const y0: u64 = y & 0x1111111111111111;
            const y1: u64 = y & 0x2222222222222222;
            const y2: u64 = y & 0x4444444444444444;
            const y3: u64 = y & 0x8888888888888888;
            const z0: u128 = (x0 *% @as(u128, y0)) ^ (x1 *% @as(u128, y3)) ^ (x2 *% @as(u128, y2)) ^ (x3 *% @as(u128, y1));
            const z1: u128 = (x0 *% @as(u128, y1)) ^ (x1 *% @as(u128, y0)) ^ (x2 *% @as(u128, y3)) ^ (x3 *% @as(u128, y2));
            const z2: u128 = (x0 *% @as(u128, y2)) ^ (x1 *% @as(u128, y1)) ^ (x2 *% @as(u128, y0)) ^ (x3 *% @as(u128, y3));
            const z3: u128 = (x0 *% @as(u128, y3)) ^ (x1 *% @as(u128, y2)) ^ (x2 *% @as(u128, y1)) ^ (x3 *% @as(u128, y0));
            const x0_mask: u64 = -%(x & 1);
            const x1_mask: u64 = -%((x >> 1) & 1);
            const x2_mask: u64 = -%((x >> 2) & 1);
            const x3_mask: u64 = -%((x >> 3) & 1);
            const extra: u128 = (x0_mask & y) ^ (@as(u128, x1_mask & y) << 1) ^
                (@as(u128, x2_mask & y) << 2) ^ (@as(u128, x3_mask & y) << 3);
            return (z0 & 0x11111111111111111111111111111111) ^
                (z1 & 0x22222222222222222222222222222222) ^
                (z2 & 0x44444444444444444444444444444444) ^
                (z3 & 0x88888888888888888888888888888888) ^ extra;
        }
        const I256 = struct {
            hi: u128,
            lo: u128,
            mid: u128,
        };
        fn xor256(x: *I256, y: I256) void {
            x.* = .{ .hi = x.hi ^ y.hi, .lo = x.lo ^ y.lo, .mid = x.mid ^ y.mid };
        }
        // Square a 128-bit integer in GF(2^128).
        fn clsq128(x: u128) I256 {
            return .{ .hi = clmul(x, x, .hi), .lo = clmul(x, x, .lo), .mid = 0 };
        }
        // Multiply two 128-bit integers in GF(2^128).
        fn clmul128(x: u128, y: u128) I256 {
            if (mul_algorithm == .karatsuba) {
                const x_hi: u64 = @as(u64, @truncate(x >> 64));
                const y_hi: u64 = @as(u64, @truncate(y >> 64));
                const r_lo: u128 = clmul(x, y, .lo);
                const r_hi: u128 = clmul(x, y, .hi);
                const r_mid: u128 = clmul(x ^ x_hi, y ^ y_hi, .lo) ^ r_lo ^ r_hi;
                return .{
                    .hi = r_hi,
                    .lo = r_lo,
                    .mid = r_mid,
                };
            } else {
                return .{
                    .hi = clmul(x, y, .hi),
                    .lo = clmul(x, y, .lo),
                    .mid = clmul(x, y, .hi_lo) ^ clmul(y, x, .hi_lo),
                };
            }
        }
        // Reduce a 256-bit representative of a polynomial modulo the irreducible polynomial x^128 +% x^127 +% x^126 +% x^121 +% 1.
        // This is done using Shay Gueron's black magic demysticated here:
        // https://blog.quarkslab.com/reversing-a-finite-field-multiplication-optimization.html
        fn reduce(x: I256) u128 {
            const p64: comptime_int = (((1 << 121) | (1 << 126) | (1 << 127)) >> 64);
            const hi: u128 = x.hi ^ (x.mid >> 64);
            const lo: u128 = x.lo ^ (x.mid << 64);
            const a: u128 = clmul(lo, p64, .lo);
            const b: u128 = ((lo << 64) | (lo >> 64)) ^ a;
            const cipher: u128 = clmul(b, p64, .lo);
            const d: u128 = ((b << 64) | (b >> 64)) ^ cipher;
            return d ^ hi;
        }
        const has_pclmul = true; //std.Target.x86.featureSetHas(builtin.config.zig.features, .pclmul);
        const has_avx = true; // std.Target.x86.featureSetHas(builtin.config.zig.features, .avx);
        const has_armaes = true; // std.Target.aarch64.featureSetHas(builtin.config.zig.features, .aes);
        // C backend doesn't currently support passing vectors to inline asm.
        const clmul = if (builtin.cpu.arch == .x86_64 and builtin.zig_backend != .stage2_c and has_pclmul and has_avx) impl: {
            break :impl clmulPclmul;
        } else if (builtin.cpu.arch == .aarch64 and builtin.zig_backend != .stage2_c and has_armaes) impl: {
            break :impl clmulPmull;
        } else impl: {
            break :impl clmulSoft;
        };
        // Process 16 byte blocks.
        fn blocks(st: *Hash, msg: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            debug.assert(msg.len % 16 == 0); // GHASH blocks() expects full blocks
            var acc = st.acc;
            var i: usize = 0;
            if (!builtin.is_small and msg.len >= agg_16_threshold *% blk_len) {
                while (i +% 256 <= msg.len) : (i +%= 256) {
                    var u: I256 = clmul128(acc ^ mem.readInt(u128, msg[i..][0..16], endian), st.hx[15 -% 0]);
                    var j: usize = 1;
                    while (j < 16) : (j +%= 1) {
                        xor256(&u, clmul128(mem.readInt(u128, msg[i..][j *% 16 ..][0..16], endian), st.hx[15 -% j]));
                    }
                    acc = reduce(u);
                }
            } else if (!builtin.is_small and msg.len >= agg_8_threshold *% blk_len) {
                while (i +% 128 <= msg.len) : (i +%= 128) {
                    var u: I256 = clmul128(acc ^ mem.readInt(u128, msg[i..][0..16], endian), st.hx[7 -% 0]);
                    var j: usize = 1;
                    while (j < 8) : (j +%= 1) {
                        xor256(&u, clmul128(mem.readInt(u128, msg[i..][j *% 16 ..][0..16], endian), st.hx[7 -% j]));
                    }
                    acc = reduce(u);
                }
            } else if (!builtin.is_small and msg.len >= agg_4_threshold *% blk_len) {
                while (i +% 64 <= msg.len) : (i +%= 64) {
                    var u: I256 = clmul128(acc ^ mem.readInt(u128, msg[i..][0..16], endian), st.hx[3 -% 0]);
                    var j: usize = 1;
                    while (j < 4) : (j +%= 1) {
                        xor256(&u, clmul128(mem.readInt(u128, msg[i..][j *% 16 ..][0..16], endian), st.hx[3 -% j]));
                    }
                    acc = reduce(u);
                }
            }
            while (i +% 32 <= msg.len) : (i +%= 32) {
                var u: I256 = clmul128(acc ^ mem.readInt(u128, msg[i..][0..16], endian), st.hx[1 -% 0]);
                var j: usize = 1;
                while (j < 2) : (j +%= 1) {
                    xor256(&u, clmul128(mem.readInt(u128, msg[i..][j *% 16 ..][0..16], endian), st.hx[1 -% j]));
                }
                acc = reduce(u);
            }
            if (i < msg.len) {
                const u: I256 = clmul128(acc ^ mem.readInt(u128, msg[i..][0..16], endian), st.hx[0]);
                acc = reduce(u);
                i +%= 16;
            }
            debug.assert(i == msg.len);
            st.acc = acc;
        }
        pub fn update(st: *Hash, msg: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var mb = msg;
            if (st.leftover > 0) {
                const want = @min(blk_len -% st.leftover, mb.len);
                const mc = mb[0..want];
                for (mc, 0..) |x, i| {
                    st.buf[st.leftover +% i] = x;
                }
                mb = mb[want..];
                st.leftover +%= want;
                if (st.leftover < blk_len) {
                    return;
                }
                st.blocks(&st.buf);
                st.leftover = 0;
            }
            if (mb.len >= blk_len) {
                const want = mb.len & ~(@as(usize, blk_len) -% 1);
                st.blocks(mb[0..want]);
                mb = mb[want..];
            }
            if (mb.len > 0) {
                for (mb, 0..) |x, i| {
                    st.buf[st.leftover +% i] = x;
                }
                st.leftover +%= mb.len;
            }
        }
        pub fn pad(st: *Hash) void {
            @setRuntimeSafety(builtin.is_safe);
            if (st.leftover == 0) {
                return;
            }
            var i = st.leftover;
            while (i < blk_len) : (i +%= 1) {
                st.buf[i] = 0;
            }
            st.blocks(&st.buf);
            st.leftover = 0;
        }
        pub fn final(st: *Hash, out: *[mac_len]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            st.pad();
            mem.writeInt(u128, out[0..16], st.acc, endian);
            mach.memset(@as([*]u8, @ptrCast(st)), 0, @sizeOf(Hash));
        }
        pub fn create(out: *[mac_len]u8, msg: []const u8, key: *const [key_len]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var st: Hash = Hash.init(key);
            st.update(msg);
            st.final(out);
        }
    };
}
pub const Poly1305 = struct {
    r: [3]u64,
    h: [3]u64 = [_]u64{ 0, 0, 0 },
    pad: [2]u64,
    leftover: usize = 0,
    buf: [block_len]u8 align(16) = undefined,
    pub const block_len: comptime_int = 16;
    pub const mac_len: comptime_int = 16;
    pub const key_len: comptime_int = 32;
    pub fn init(key: *const [key_len]u8) Poly1305 {
        @setRuntimeSafety(builtin.is_safe);
        const t0: u64 = mem.readIntLittle(u64, key[0..8]);
        const t1: u64 = mem.readIntLittle(u64, key[8..16]);
        return .{ .r = .{
            t0 & 0xffc0fffffff,
            ((t0 >> 44) | (t1 << 20)) & 0xfffffc0ffff,
            ((t1 >> 24)) & 0x00ffffffc0f,
        }, .pad = .{
            mem.readIntLittle(u64, key[16..24]),
            mem.readIntLittle(u64, key[24..32]),
        } };
    }
    fn blocks(st: *Poly1305, msg: []const u8, comptime last: bool) void {
        @setRuntimeSafety(builtin.is_safe);
        const hibit: u64 = if (last) 0 else 1 << 40;
        const r0: u64 = st.r[0];
        const r1: u64 = st.r[1];
        const r2: u64 = st.r[2];
        var h0: u64 = st.h[0];
        var h1: u64 = st.h[1];
        var h2: u64 = st.h[2];
        const s1: u64 = r1 *% (5 << 2);
        const s2: u64 = r2 *% (5 << 2);
        var idx: usize = 0;
        while (idx +% block_len <= msg.len) : (idx +%= block_len) {
            // h +%= msg[i]
            const t0: u64 = mem.readIntLittle(u64, msg[idx..][0..8]);
            const t1: u64 = mem.readIntLittle(u64, msg[idx +% 8 ..][0..8]);
            h0 +%= @as(u44, @truncate(t0));
            h1 +%= @as(u44, @truncate((t0 >> 44) | (t1 << 20)));
            h2 +%= @as(u42, @truncate(t1 >> 24)) | hibit;
            const d0: u128 = @as(u128, h0) *% r0 +% @as(u128, h1) *% s2 +% @as(u128, h2) *% s1;
            var d1: u128 = @as(u128, h0) *% r1 +% @as(u128, h1) *% r0 +% @as(u128, h2) *% s2;
            var d2: u128 = @as(u128, h0) *% r2 +% @as(u128, h1) *% r1 +% @as(u128, h2) *% r0;
            var carry: u64 = @intCast(d0 >> 44);
            h0 = @as(u44, @truncate(d0));
            d1 +%= carry;
            carry = @intCast(d1 >> 44);
            h1 = @as(u44, @truncate(d1));
            d2 +%= carry;
            carry = @as(u64, @intCast(d2 >> 42));
            h2 = @as(u42, @truncate(d2));
            h0 +%= @as(u64, @truncate(carry)) *% 5;
            carry = h0 >> 44;
            h0 = @as(u44, @truncate(h0));
            h1 +%= carry;
        }
        st.h = .{ h0, h1, h2 };
    }
    pub fn update(st: *Poly1305, msg: []const u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var mb = msg;
        if (st.leftover > 0) {
            const want = @min(block_len -% st.leftover, mb.len);
            const mc = mb[0..want];
            for (mc, 0..) |x, i| {
                st.buf[st.leftover +% i] = x;
            }
            mb = mb[want..];
            st.leftover +%= want;
            if (st.leftover < block_len) {
                return;
            }
            st.blocks(&st.buf, false);
            st.leftover = 0;
        }
        if (mb.len >= block_len) {
            const want = mb.len & ~(@as(usize, block_len) -% 1);
            st.blocks(mb[0..want], false);
            mb = mb[want..];
        }
        if (mb.len > 0) {
            for (mb, 0..) |x, i| {
                st.buf[st.leftover +% i] = x;
            }
            st.leftover +%= mb.len;
        }
    }
    pub fn pad(st: *Poly1305) void {
        @setRuntimeSafety(builtin.is_safe);
        if (st.leftover == 0) {
            return;
        }
        var i = st.leftover;
        while (i < block_len) : (i +%= 1) {
            st.buf[i] = 0;
        }
        st.blocks(&st.buf);
        st.leftover = 0;
    }
    pub fn final(st: *Poly1305, out: *[mac_len]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        if (st.leftover > 0) {
            var idx: usize = st.leftover;
            st.buf[idx] = 1;
            idx +%= 1;
            while (idx < block_len) : (idx +%= 1) {
                st.buf[idx] = 0;
            }
            st.blocks(&st.buf, true);
        }
        var carry: u64 = st.h[1] >> 44;
        st.h[1] = @as(u44, @truncate(st.h[1]));
        st.h[2] +%= carry;
        carry = st.h[2] >> 42;
        st.h[2] = @as(u42, @truncate(st.h[2]));
        st.h[0] +%= carry *% 5;
        carry = st.h[0] >> 44;
        st.h[0] = @as(u44, @truncate(st.h[0]));
        st.h[1] +%= carry;
        carry = st.h[1] >> 44;
        st.h[1] = @as(u44, @truncate(st.h[1]));
        st.h[2] +%= carry;
        carry = st.h[2] >> 42;
        st.h[2] = @as(u42, @truncate(st.h[2]));
        st.h[0] +%= carry *% 5;
        carry = st.h[0] >> 44;
        st.h[0] = @as(u44, @truncate(st.h[0]));
        st.h[1] +%= carry;
        var g0: u64 = st.h[0] +% 5;
        carry = g0 >> 44;
        g0 = @as(u44, @truncate(g0));
        var g1: u64 = st.h[1] +% carry;
        carry = g1 >> 44;
        g1 = @as(u44, @truncate(g1));
        var g2: u64 = st.h[2] +% carry -% (1 << 42);
        const mask = (g2 >> 63) -% 1;
        g0 &= mask;
        g1 &= mask;
        g2 &= mask;
        const nmask = ~mask;
        st.h[0] = (st.h[0] & nmask) | g0;
        st.h[1] = (st.h[1] & nmask) | g1;
        st.h[2] = (st.h[2] & nmask) | g2;
        const t0 = st.pad[0];
        const t1 = st.pad[1];
        st.h[0] +%= @as(u44, @truncate(t0));
        carry = st.h[0] >> 44;
        st.h[0] = @as(u44, @truncate(st.h[0]));
        st.h[1] +%= @as(u44, @truncate((t0 >> 44) | (t1 << 20))) +% carry;
        carry = st.h[1] >> 44;
        st.h[1] = @as(u44, @truncate(st.h[1]));
        st.h[2] +%= @as(u42, @truncate(t1 >> 24)) +% carry;
        st.h[2] = @as(u42, @truncate(st.h[2]));
        st.h[0] |= st.h[1] << 44;
        st.h[1] = (st.h[1] >> 20) | (st.h[2] << 24);
        mem.writeIntLittle(u64, out[0..8], st.h[0]);
        mem.writeIntLittle(u64, out[8..16], st.h[1]);
        mach.memset(@as([*]u8, @ptrCast(st)), 0, @sizeOf(Poly1305));
    }
    pub fn create(out: *[mac_len]u8, msg: []const u8, key: *const [key_len]u8) void {
        var st = Poly1305.init(key);
        st.update(msg);
        st.final(out);
    }
};
