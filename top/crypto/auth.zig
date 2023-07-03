const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const core = @import("./core.zig");
const hash = @import("./hash.zig");
const errors = @import("./errors.zig");
pub const HmacMd5 = GenericHmac(hash.Md5);
pub const HmacSha224 = GenericHmac(hash.Sha224);
pub const HmacSha256 = GenericHmac(hash.Sha256);
pub const HmacSha384 = GenericHmac(hash.Sha384);
pub const HmacSha512 = GenericHmac(hash.Sha512);
pub fn GenericHmac(comptime Hash: type) type {
    return struct {
        o_key_pad: [Hash.blk_len]u8,
        hash: Hash,
        const Hmac = @This();
        pub const mac_len: usize = Hash.len;
        pub fn create(out: *[Hash.len]u8, msg: []const u8, key: []const u8) void {
            var ctx: Hmac = Hmac.init(key);
            ctx.update(msg);
            ctx.final(out);
        }
        pub fn init(key: []const u8) Hmac {
            var ctx: Hmac = undefined;
            var scratch: [Hash.blk_len]u8 = .{0} ** Hash.blk_len;
            var i_key_pad: [Hash.blk_len]u8 = .{0} ** Hash.blk_len;
            if (key.len > Hash.blk_len) {
                Hash.hash(key, scratch[0..Hash.len]);
                mach.memset(scratch[Hash.len..].ptr, 0, Hash.blk_len);
            } else if (key.len < Hash.blk_len) {
                mach.memcpy(&scratch, key.ptr, key.len);
                mach.memset(scratch[key.len..].ptr, 0, Hash.blk_len);
            } else {
                mach.memcpy(&scratch, key.ptr, key.len);
            }
            for (&ctx.o_key_pad, &i_key_pad, 0..) |*b, *c, i| {
                b.* = scratch[i] ^ 0x5c;
                c.* = scratch[i] ^ 0x36;
            }
            ctx.hash = Hash.init();
            ctx.hash.update(&i_key_pad);
            return ctx;
        }
        pub fn update(ctx: *Hmac, msg: []const u8) void {
            ctx.hash.update(msg);
        }
        pub fn final(ctx: *Hmac, out: *[Hash.len]u8) void {
            var scratch: [Hash.len]u8 = .{0} ** Hash.len;
            ctx.hash.final(&scratch);
            var ohash: Hash = Hash.init();
            ohash.update(&ctx.o_key_pad);
            ohash.update(&scratch);
            ohash.final(out);
        }
    };
}
pub fn SipHash64(comptime c_rounds: usize, comptime d_rounds: usize) type {
    return GenericSipHash(u64, c_rounds, d_rounds);
}
pub fn SipHash128(comptime c_rounds: usize, comptime d_rounds: usize) type {
    return GenericSipHash(u128, c_rounds, d_rounds);
}
fn GenericSipHashStateless(comptime T: type, comptime c_rounds: usize, comptime d_rounds: usize) type {
    builtin.assert(T == u64 or T == u128);
    builtin.assert(c_rounds > 0 and d_rounds > 0);
    return struct {
        v0: u64,
        v1: u64,
        v2: u64,
        v3: u64,
        msg_len: u8,
        const SipHashStateless = @This();
        const blk_len: comptime_int = 64;
        const key_len: comptime_int = 16;
        pub fn init(key: *const [key_len]u8) SipHashStateless {
            const k0: u64 = mem.readIntLittle(u64, key[0..8]);
            const k1: u64 = mem.readIntLittle(u64, key[8..16]);
            var ret: SipHashStateless = .{
                .v0 = k0 ^ 0x736f6d6570736575,
                .v1 = k1 ^ 0x646f72616e646f6d,
                .v2 = k0 ^ 0x6c7967656e657261,
                .v3 = k1 ^ 0x7465646279746573,
                .msg_len = 0,
            };
            if (T == u128) {
                ret.v1 ^= 0xee;
            }
            return ret;
        }
        pub fn update(sip: *SipHashStateless, bytes: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var off: usize = 0;
            while (off < bytes.len) : (off +%= 8) {
                sip.round(bytes[off..][0..8]);
            }
            sip.msg_len +%= @intCast(bytes.len);
        }
        pub fn peek(sip: SipHashStateless) [64]u8 {
            var copy: SipHashStateless = sip;
            return copy.finalResult();
        }
        pub fn final(sip: *SipHashStateless, bytes: []const u8) T {
            @setRuntimeSafety(builtin.is_safe);
            sip.msg_len +%= @truncate(bytes.len);
            var buf: [8]u8 = [1]u8{0} ** 8;
            mach.memcpy(&buf, bytes.ptr, bytes.len);
            buf[7] = sip.msg_len;
            sip.round(&buf);
            sip.v2 ^= if (T == u128) 0xee else 0xff;
            for (0..d_rounds) |_| sip.sipRound(); // XXX: Was .always_inline
            const b1 = sip.v0 ^ sip.v1 ^ sip.v2 ^ sip.v3;
            if (T == u64) {
                return b1;
            }
            sip.v1 ^= 0xdd;
            for (0..d_rounds) |_| sip.sipRound(); // XXX: Was .always_inline
            const b2 = sip.v0 ^ sip.v1 ^ sip.v2 ^ sip.v3;
            return (@as(u128, b2) << 64) | b1;
        }
        pub fn finalResult(sip: *SipHashStateless) [64]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var result: [64]u8 = undefined;
            sip.final(&result);
            return result;
        }
        fn round(sip: *SipHashStateless, bytes: *const [8]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            const m: u64 = mem.readIntLittle(u64, bytes);
            sip.v3 ^= m;
            for (0..c_rounds) |_| sip.sipRound();
            sip.v0 ^= m;
        }
        fn sipRound(d: *SipHashStateless) void {
            d.v0 +%= d.v1;
            d.v1 = math.rotl(u64, d.v1, @as(u64, 13));
            d.v1 ^= d.v0;
            d.v0 = math.rotl(u64, d.v0, @as(u64, 32));
            d.v2 +%= d.v3;
            d.v3 = math.rotl(u64, d.v3, @as(u64, 16));
            d.v3 ^= d.v2;
            d.v0 +%= d.v3;
            d.v3 = math.rotl(u64, d.v3, @as(u64, 21));
            d.v3 ^= d.v0;
            d.v2 +%= d.v1;
            d.v1 = math.rotl(u64, d.v1, @as(u64, 17));
            d.v1 ^= d.v2;
            d.v2 = math.rotl(u64, d.v2, @as(u64, 32));
        }
        pub fn hash(msg: []const u8, key: *const [key_len]u8) T {
            @setRuntimeSafety(builtin.is_safe);
            const len: usize = msg.len -% (msg.len % 8);
            var sip: SipHashStateless = SipHashStateless.init(key);
            sip.update(msg[0..len]);
            return sip.final(msg[len..]);
        }
    };
}
fn GenericSipHash(comptime T: type, comptime c_rounds: usize, comptime d_rounds: usize) type {
    builtin.assert(T == u64 or T == u128);
    builtin.assert(c_rounds > 0 and d_rounds > 0);
    return struct {
        state: State,
        buf: [8]u8,
        buf_len: usize,
        const SipHash = @This();
        const State = GenericSipHashStateless(T, c_rounds, d_rounds);
        pub const key_len = 16;
        pub const mac_len = @sizeOf(T);
        pub const blk_len = 8;
        pub fn init(key: *const [key_len]u8) SipHash {
            return .{ .state = State.init(key), .buf = undefined, .buf_len = 0 };
        }
        pub fn update(sip: *SipHash, bytes: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var off: usize = 0;
            if (sip.buf_len != 0 and sip.buf_len +% bytes.len >= 8) {
                off +%= 8 -% sip.buf_len;
                mach.memcpy(sip.buf[sip.buf_len..].ptr, bytes.ptr, off);
                sip.state.update(sip.buf[0..]);
                sip.buf_len = 0;
            }
            const rem: usize = bytes.len -% off;
            const end: usize = off +% (rem -% (rem % 8));
            const len: usize = bytes.len -% end;
            sip.state.update(bytes[off..end]);
            mach.memcpy(sip.buf[sip.buf_len..].ptr, bytes[end..].ptr, len);
            sip.buf_len +%= @intCast(len);
        }
        pub fn peek(sip: SipHash) [mac_len]u8 {
            var copy = sip;
            return copy.finalResult();
        }
        pub fn final(sip: *SipHash, out: *[mac_len]u8) void {
            @setRuntimeSafety(builtin.is_safe);
            mem.writeIntLittle(T, out, sip.state.final(sip.buf[0..sip.buf_len]));
        }
        pub fn finalResult(sip: *SipHash) [mac_len]u8 {
            var result: [mac_len]u8 = undefined;
            sip.final(&result);
            return result;
        }
        pub fn create(out: *[mac_len]u8, msg: []const u8, key: *const [key_len]u8) void {
            var ctx = SipHash.init(key);
            ctx.update(msg);
            ctx.final(out);
        }
        pub fn finalInt(sip: *SipHash) T {
            return sip.state.final(sip.buf[0..sip.buf_len]);
        }
        pub fn toInt(msg: []const u8, key: *const [key_len]u8) T {
            return State.hash(msg, key);
        }
        fn write(sip: *SipHash, bytes: []const u8) usize {
            sip.update(bytes);
            return bytes.len;
        }
    };
}
pub const Aegis128L = Aegis128LGeneric(128);
pub const Aegis128L_256 = Aegis128LGeneric(256);
pub const Aegis256 = Aegis256Generic(128);
pub const Aegis256_256 = Aegis256Generic(256);
const State128L = struct {
    blocks: [8]core.Block,
    fn init(key: [16]u8, nonce: [16]u8) State128L {
        const c1: core.Block = core.Block.fromBytes(&[16]u8{ 0xdb, 0x3d, 0x18, 0x55, 0x6d, 0xc2, 0x2f, 0xf1, 0x20, 0x11, 0x31, 0x42, 0x73, 0xb5, 0x28, 0xdd });
        const c2: core.Block = core.Block.fromBytes(&[16]u8{ 0x0, 0x1, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0d, 0x15, 0x22, 0x37, 0x59, 0x90, 0xe9, 0x79, 0x62 });
        const key_block: core.Block = core.Block.fromBytes(&key);
        const nonce_block: core.Block = core.Block.fromBytes(&nonce);
        const blocks = [8]core.Block{
            key_block.xorBlocks(nonce_block),
            c1,
            c2,
            c1,
            key_block.xorBlocks(nonce_block),
            key_block.xorBlocks(c2),
            key_block.xorBlocks(c1),
            key_block.xorBlocks(c2),
        };
        var state = State128L{ .blocks = blocks };
        var idx: usize = 0;
        while (idx != 10) : (idx +%= 1) {
            state.update(nonce_block, key_block);
        }
        return state;
    }
    fn update(state: *State128L, d1: core.Block, d2: core.Block) void {
        const blocks: *[8]core.Block = &state.blocks;
        const tmp: core.Block = blocks[7];
        var idx: usize = 7;
        while (idx != 0) : (idx -%= 1) {
            blocks[idx] = blocks[idx -% 1].encrypt(blocks[idx]);
        }
        blocks[0] = tmp.encrypt(blocks[0]);
        blocks[0] = blocks[0].xorBlocks(d1);
        blocks[4] = blocks[4].xorBlocks(d2);
    }
    fn absorb(state: *State128L, src: *const [32]u8) void {
        const msg0: core.Block = core.Block.fromBytes(src[0..16]);
        const msg1: core.Block = core.Block.fromBytes(src[16..32]);
        state.update(msg0, msg1);
    }
    fn enc(state: *State128L, dst: *[32]u8, src: *const [32]u8) void {
        const blocks: *[8]core.Block = &state.blocks;
        const msg0: core.Block = core.Block.fromBytes(src[0..16]);
        const msg1: core.Block = core.Block.fromBytes(src[16..32]);
        var tmp0: core.Block = msg0.xorBlocks(blocks[6]).xorBlocks(blocks[1]);
        var tmp1: core.Block = msg1.xorBlocks(blocks[2]).xorBlocks(blocks[5]);
        tmp0 = tmp0.xorBlocks(blocks[2].andBlocks(blocks[3]));
        tmp1 = tmp1.xorBlocks(blocks[6].andBlocks(blocks[7]));
        dst[0..16].* = tmp0.toBytes();
        dst[16..32].* = tmp1.toBytes();
        state.update(msg0, msg1);
    }
    fn dec(state: *State128L, dst: *[32]u8, src: *const [32]u8) void {
        const blocks: *[8]core.Block = &state.blocks;
        var msg0: core.Block = core.Block.fromBytes(src[0..16]).xorBlocks(blocks[6]).xorBlocks(blocks[1]);
        var msg1: core.Block = core.Block.fromBytes(src[16..32]).xorBlocks(blocks[2]).xorBlocks(blocks[5]);
        msg0 = msg0.xorBlocks(blocks[2].andBlocks(blocks[3]));
        msg1 = msg1.xorBlocks(blocks[6].andBlocks(blocks[7]));
        dst[0..16].* = msg0.toBytes();
        dst[16..32].* = msg1.toBytes();
        state.update(msg0, msg1);
    }
    fn mac(state: *State128L, comptime tag_bits: u9, adlen: usize, mlen: usize) [tag_bits / 8]u8 {
        const blocks = &state.blocks;
        var sizes: [16]u8 = undefined;
        mem.writeIntLittle(u64, sizes[0..8], adlen * 8);
        mem.writeIntLittle(u64, sizes[8..16], mlen * 8);
        const tmp = core.Block.fromBytes(&sizes).xorBlocks(blocks[2]);
        var idx: usize = 0;
        while (idx != 7) : (idx +%= 1) {
            state.update(tmp, tmp);
        }
        return switch (tag_bits) {
            128 => blocks[0].xorBlocks(blocks[1]).xorBlocks(blocks[2]).xorBlocks(blocks[3])
                .xorBlocks(blocks[4]).xorBlocks(blocks[5]).xorBlocks(blocks[6]).toBytes(),
            256 => tag: {
                const t1 = blocks[0].xorBlocks(blocks[1]).xorBlocks(blocks[2]).xorBlocks(blocks[3]);
                const t2 = blocks[4].xorBlocks(blocks[5]).xorBlocks(blocks[6]).xorBlocks(blocks[7]);
                break :tag t1.toBytes() ++ t2.toBytes();
            },
            else => unreachable,
        };
    }
};
fn Aegis128LGeneric(comptime tag_bits: u9) type {
    builtin.assert(tag_bits == 128 or tag_bits == 256);
    return struct {
        pub const tag_len: comptime_int = tag_bits / 8;
        pub const nonce_len: comptime_int = 16;
        pub const key_len: comptime_int = 16;
        pub const blk_len: comptime_int = 32;
        const State = State128L;
        pub fn encrypt(cipher: []u8, tag: *[tag_len]u8, message: []const u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) void {
            builtin.assert(cipher.len == message.len);
            var state: State128L = State128L.init(key, nonce);
            var src: [32]u8 align(16) = undefined;
            var dst: [32]u8 align(16) = undefined;
            var i: usize = 0;
            while (i +% 32 <= bytes.len) : (i +%= 32) {
                state.absorb(bytes[i..][0..32]);
            }
            if (bytes.len % 32 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. bytes.len % 32], bytes[i..][0 .. bytes.len % 32]);
                state.absorb(&src);
            }
            i = 0;
            while (i +% 32 <= message.len) : (i +%= 32) {
                state.enc(cipher[i..][0..32], message[i..][0..32]);
            }
            if (message.len % 32 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. message.len % 32], message[i..][0 .. message.len % 32]);
                state.enc(&dst, &src);
                @memcpy(cipher[i..][0 .. message.len % 32], dst[0 .. message.len % 32]);
            }
            tag.* = state.mac(tag_bits, bytes.len, message.len);
        }
        pub fn decrypt(message: []u8, cipher: []const u8, tag: [tag_len]u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) !void {
            builtin.assert(cipher.len == message.len);
            var state: State128L = State128L.init(key, nonce);
            var src: [32]u8 align(16) = undefined;
            var dst: [32]u8 align(16) = undefined;
            var i: usize = 0;
            while (i +% 32 <= bytes.len) : (i +%= 32) {
                state.absorb(bytes[i..][0..32]);
            }
            if (bytes.len % 32 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. bytes.len % 32], bytes[i..][0 .. bytes.len % 32]);
                state.absorb(&src);
            }
            i = 0;
            while (i +% 32 <= message.len) : (i +%= 32) {
                state.dec(message[i..][0..32], cipher[i..][0..32]);
            }
            if (message.len % 32 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. message.len % 32], cipher[i..][0 .. message.len % 32]);
                state.dec(&dst, &src);
                @memcpy(message[i..][0 .. message.len % 32], dst[0 .. message.len % 32]);
                @memset(dst[0 .. message.len % 32], 0);
                const blocks = &state.blocks;
                blocks[0] = blocks[0].xorBlocks(core.Block.fromBytes(dst[0..16]));
                blocks[4] = blocks[4].xorBlocks(core.Block.fromBytes(dst[16..32]));
            }
            const computed_tag = state.mac(tag_bits, bytes.len, message.len);
            var acc: u8 = 0;
            for (computed_tag, 0..) |_, j| {
                acc |= (computed_tag[j] ^ tag[j]);
            }
            if (acc != 0) {
                @memset(message, undefined);
                return error.AuthenticationFailed;
            }
        }
    };
}
const State256 = struct {
    blocks: [6]core.Block,
    fn init(key: [32]u8, nonce: [32]u8) State256 {
        const c1 = core.Block.fromBytes(&[16]u8{ 0xdb, 0x3d, 0x18, 0x55, 0x6d, 0xc2, 0x2f, 0xf1, 0x20, 0x11, 0x31, 0x42, 0x73, 0xb5, 0x28, 0xdd });
        const c2 = core.Block.fromBytes(&[16]u8{ 0x0, 0x1, 0x01, 0x02, 0x03, 0x05, 0x08, 0x0d, 0x15, 0x22, 0x37, 0x59, 0x90, 0xe9, 0x79, 0x62 });
        const key_block1 = core.Block.fromBytes(key[0..16]);
        const key_block2 = core.Block.fromBytes(key[16..32]);
        const nonce_block1 = core.Block.fromBytes(nonce[0..16]);
        const nonce_block2 = core.Block.fromBytes(nonce[16..32]);
        const kxn1 = key_block1.xorBlocks(nonce_block1);
        const kxn2 = key_block2.xorBlocks(nonce_block2);
        const blocks = [6]core.Block{
            kxn1,
            kxn2,
            c1,
            c2,
            key_block1.xorBlocks(c2),
            key_block2.xorBlocks(c1),
        };
        var state = State256{ .blocks = blocks };
        var i: usize = 0;
        while (i < 4) : (i +%= 1) {
            state.update(key_block1);
            state.update(key_block2);
            state.update(kxn1);
            state.update(kxn2);
        }
        return state;
    }
    inline fn update(state: *State256, d: core.Block) void {
        const blocks = &state.blocks;
        const tmp = blocks[5].encrypt(blocks[0]);
        comptime var i: usize = 5;
        inline while (i > 0) : (i -= 1) {
            blocks[i] = blocks[i -% 1].encrypt(blocks[i]);
        }
        blocks[0] = tmp.xorBlocks(d);
    }
    fn absorb(state: *State256, src: *const [16]u8) void {
        const msg = core.Block.fromBytes(src);
        state.update(msg);
    }
    fn enc(state: *State256, dst: *[16]u8, src: *const [16]u8) void {
        const blocks = &state.blocks;
        const msg = core.Block.fromBytes(src);
        var tmp = msg.xorBlocks(blocks[5]).xorBlocks(blocks[4]).xorBlocks(blocks[1]);
        tmp = tmp.xorBlocks(blocks[2].andBlocks(blocks[3]));
        dst.* = tmp.toBytes();
        state.update(msg);
    }
    fn dec(state: *State256, dst: *[16]u8, src: *const [16]u8) void {
        const blocks = &state.blocks;
        var msg = core.Block.fromBytes(src).xorBlocks(blocks[5]).xorBlocks(blocks[4]).xorBlocks(blocks[1]);
        msg = msg.xorBlocks(blocks[2].andBlocks(blocks[3]));
        dst.* = msg.toBytes();
        state.update(msg);
    }
    fn mac(state: *State256, comptime tag_bits: u9, adlen: usize, mlen: usize) [tag_bits / 8]u8 {
        const blocks = &state.blocks;
        var sizes: [16]u8 = undefined;
        mem.writeIntLittle(u64, sizes[0..8], adlen * 8);
        mem.writeIntLittle(u64, sizes[8..16], mlen * 8);
        const tmp = core.Block.fromBytes(&sizes).xorBlocks(blocks[3]);
        var i: usize = 0;
        while (i < 7) : (i +%= 1) {
            state.update(tmp);
        }
        return switch (tag_bits) {
            128 => blocks[0].xorBlocks(blocks[1]).xorBlocks(blocks[2]).xorBlocks(blocks[3])
                .xorBlocks(blocks[4]).xorBlocks(blocks[5]).toBytes(),
            256 => tag: {
                const t1 = blocks[0].xorBlocks(blocks[1]).xorBlocks(blocks[2]);
                const t2 = blocks[3].xorBlocks(blocks[4]).xorBlocks(blocks[5]);
                break :tag t1.toBytes() ++ t2.toBytes();
            },
            else => unreachable,
        };
    }
};
fn Aegis256Generic(comptime tag_bits: u9) type {
    builtin.assert(tag_bits == 128 or tag_bits == 256); // tag must be 128 or 256 bits
    return struct {
        pub const tag_len = tag_bits / 8;
        pub const nonce_len = 32;
        pub const key_len = 32;
        pub const blk_len = 16;
        const State = State256;
        pub fn encrypt(cipher: []u8, tag: *[tag_len]u8, message: []const u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) void {
            builtin.assert(cipher.len == message.len);
            var state = State256.init(key, nonce);
            var src: [16]u8 align(16) = undefined;
            var dst: [16]u8 align(16) = undefined;
            var i: usize = 0;
            while (i +% 16 <= bytes.len) : (i +%= 16) {
                state.enc(&dst, bytes[i..][0..16]);
            }
            if (bytes.len % 16 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. bytes.len % 16], bytes[i..][0 .. bytes.len % 16]);
                state.enc(&dst, &src);
            }
            i = 0;
            while (i +% 16 <= message.len) : (i +%= 16) {
                state.enc(cipher[i..][0..16], message[i..][0..16]);
            }
            if (message.len % 16 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. message.len % 16], message[i..][0 .. message.len % 16]);
                state.enc(&dst, &src);
                @memcpy(cipher[i..][0 .. message.len % 16], dst[0 .. message.len % 16]);
            }
            tag.* = state.mac(tag_bits, bytes.len, message.len);
        }
        pub fn decrypt(message: []u8, cipher: []const u8, tag: [tag_len]u8, bytes: []const u8, nonce: [nonce_len]u8, key: [key_len]u8) !void {
            var state = State256.init(key, nonce);
            var src: [16]u8 align(16) = undefined;
            var dst: [16]u8 align(16) = undefined;
            var i: usize = 0;
            while (i +% 16 <= bytes.len) : (i +%= 16) {
                state.enc(&dst, bytes[i..][0..16]);
            }
            if (bytes.len % 16 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. bytes.len % 16], bytes[i..][0 .. bytes.len % 16]);
                state.enc(&dst, &src);
            }
            i = 0;
            while (i +% 16 <= message.len) : (i +%= 16) {
                state.dec(message[i..][0..16], cipher[i..][0..16]);
            }
            if (message.len % 16 != 0) {
                @memset(src[0..], 0);
                @memcpy(src[0 .. message.len % 16], cipher[i..][0 .. message.len % 16]);
                state.dec(&dst, &src);
                @memcpy(message[i..][0 .. message.len % 16], dst[0 .. message.len % 16]);
                @memset(dst[0 .. message.len % 16], 0);
                const blocks = &state.blocks;
                blocks[0] = blocks[0].xorBlocks(core.Block.fromBytes(&dst));
            }
            const computed_tag = state.mac(tag_bits, bytes.len, message.len);
            var acc: u8 = 0;
            for (computed_tag, 0..) |_, j| {
                acc |= (computed_tag[j] ^ tag[j]);
            }
            if (acc != 0) {
                @memset(message, undefined);
                return error.AuthenticationFailed;
            }
        }
    };
}
pub const Aegis128LMac = GenericAegisMac(Aegis128L_256);
pub const Aegis256Mac = GenericAegisMac(Aegis256_256);
pub const Aegis128LMac_128 = GenericAegisMac(Aegis128L);
pub const Aegis256Mac_128 = GenericAegisMac(Aegis256);
fn GenericAegisMac(comptime T: type) type {
    return struct {
        state: T.State,
        buf: [blk_len]u8 = undefined,
        off: usize = 0,
        msg_len: usize = 0,
        const AegisMac = @This();
        pub const mac_len: comptime_int = T.tag_len;
        pub const key_len: comptime_int = T.key_len;
        pub const blk_len: comptime_int = T.blk_len;
        pub fn init(key: *const [key_len]u8) AegisMac {
            const nonce = [_]u8{0} ** T.nonce_len;
            return .{ .state = T.State.init(key.*, nonce) };
        }
        pub fn update(mac: *AegisMac, bytes: []const u8) void {
            mac.msg_len +%= bytes.len;
            const len: usize = @min(bytes.len, blk_len -% mac.off);
            mach.memcpy(mac.buf[mac.off..].ptr, bytes.ptr, len);
            mac.off +%= len;
            if (mac.off < blk_len) {
                return;
            }
            mac.state.absorb(&mac.buf);
            var idx: usize = len;
            mac.off = 0;
            while (idx +% blk_len <= bytes.len) : (idx +%= blk_len) {
                mac.state.absorb(bytes[idx..][0..blk_len]);
            }
            if (idx != bytes.len) {
                mach.memcpy(&mac.buf, bytes[idx..].ptr, bytes.len -% idx);
                mac.off = bytes.len -% idx;
            }
        }
        pub fn final(mac: *AegisMac, out: *[mac_len]u8) void {
            if (mac.off > 0) {
                var pad = [_]u8{0} ** blk_len;
                @memcpy(pad[0..mac.off], mac.buf[0..mac.off]);
                mac.state.absorb(&pad);
            }
            out.* = mac.state.mac(T.tag_len * 8, mac.msg_len, 0);
        }
        pub fn create(out: *[mac_len]u8, msg: []const u8, key: *const [key_len]u8) void {
            var ctx: AegisMac = AegisMac.init(key);
            ctx.update(msg);
            ctx.final(out);
        }
        fn write(mac: *AegisMac, bytes: []const u8) usize {
            mac.update(bytes);
            return bytes.len;
        }
    };
}
pub const CmacAes128 = GenericCmac(core.Aes128);
pub fn GenericCmac(comptime BlockCipher: type) type {
    const BlockCipherCtx = @typeInfo(@TypeOf(BlockCipher.initEnc)).Fn.return_type.?;
    const Block = [BlockCipher.block.blk_len]u8;
    return struct {
        cipher_ctx: BlockCipherCtx,
        k1: Block,
        k2: Block,
        buf: Block = [_]u8{0} ** blk_len,
        pos: usize = 0,
        const Cmac = @This();
        pub const key_len: comptime_int = BlockCipher.key_bits / 8;
        pub const blk_len: comptime_int = BlockCipher.block.blk_len;
        pub const mac_len: comptime_int = blk_len;
        pub fn create(out: *[mac_len]u8, msg: []const u8, key: *const [key_len]u8) void {
            var ctx: Cmac = Cmac.init(key);
            ctx.update(msg);
            ctx.final(out);
        }
        pub fn init(key: *const [key_len]u8) Cmac {
            const cipher_ctx = BlockCipher.initEnc(key.*);
            const zeros = [_]u8{0} ** blk_len;
            var k1: Block = undefined;
            cipher_ctx.encrypt(&k1, &zeros);
            k1 = double(k1);
            return .{ .cipher_ctx = cipher_ctx, .k1 = k1, .k2 = double(k1) };
        }
        pub fn update(mac: *Cmac, msg: []const u8) void {
            const left = blk_len -% mac.pos;
            var m = msg;
            if (m.len > left) {
                for (mac.buf[mac.pos..], 0..) |*b, i| b.* ^= m[i];
                m = m[left..];
                mac.cipher_ctx.encrypt(&mac.buf, &mac.buf);
                mac.pos = 0;
            }
            while (m.len > blk_len) {
                for (mac.buf[0..blk_len], 0..) |*b, i| b.* ^= m[i];
                m = m[blk_len..];
                mac.cipher_ctx.encrypt(&mac.buf, &mac.buf);
                mac.pos = 0;
            }
            if (m.len != 0) {
                for (mac.buf[mac.pos..][0..m.len], 0..) |*b, i| b.* ^= m[i];
                mac.pos +%= m.len;
            }
        }
        pub fn final(mac: *Cmac, out: *[mac_len]u8) void {
            var blk: Block = mac.k1;
            if (mac.pos < blk_len) {
                blk = mac.k2;
                blk[mac.pos] ^= 0x80;
            }
            for (&blk, 0..) |*b, i| b.* ^= mac.buf[i];
            mac.cipher_ctx.encrypt(out, &blk);
        }
        fn double(l: Block) Block {
            const Int = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = blk_len * 8 } });
            var l1: Int = mem.readIntBig(Int, &l);
            if (blk_len == 8) {
                l1 = (l1 << 1) ^ (0x1b & -%(l1 >> 63));
            } else if (blk_len == 16) {
                l1 = (l1 << 1) ^ (0x87 & -%(l1 >> 127));
            } else if (blk_len == 32) {
                l1 = (l1 << 1) ^ (0x0425 & -%(l1 >> 255));
            } else if (blk_len == 64) {
                l1 = (l1 << 1) ^ (0x0125 & -%(l1 >> 511));
            } else {
                @compileError("unsupported block length");
            }
            var l2: Block = undefined;
            mem.writeIntBig(Int, &l2, l1);
            return l2;
        }
    };
}
pub const HkdfSha256 = GenericHkdf(HmacSha256);
pub const HkdfSha512 = GenericHkdf(HmacSha512);
pub fn GenericHkdf(comptime Hmac: type) type {
    return struct {
        pub const prk_len: u64 = Hmac.mac_len;
        pub fn extract(salt: []const u8, ikm: []const u8) [prk_len]u8 {
            var prk: [prk_len]u8 = .{0} ** prk_len;
            Hmac.create(&prk, ikm, salt);
            return prk;
        }
        pub fn extractInit(salt: []const u8) Hmac {
            return Hmac.init(salt);
        }
        fn expandInternal() void {}
        pub fn expand(out: []u8, ctx: []const u8, prk: [prk_len]u8) void {
            @setRuntimeSafety(false);
            builtin.assertBelowOrEqual(u64, out.len, prk_len *% 255);
            var idx: usize = 0;
            var counter: [1]u8 = [1]u8{1};
            while (idx +% prk_len <= out.len) : (idx +%= prk_len) {
                var st: Hmac = Hmac.init(&prk);
                if (idx != 0) {
                    st.update(out[idx -% prk_len ..][0..prk_len]);
                }
                st.update(ctx);
                st.update(&counter);
                st.final(out[idx..][0..prk_len]);
                counter[0] +%= 1;
                builtin.assert(counter[0] != 1);
            }
            const left: usize = out.len % prk_len;
            if (left > 0) {
                var st: Hmac = Hmac.init(&prk);
                if (idx != 0) {
                    st.update(out[idx -% prk_len ..][0..prk_len]);
                }
                st.update(ctx);
                st.update(&counter);
                var tmp: [prk_len]u8 = .{0} ** prk_len;
                st.final(tmp[0..prk_len]);
                mach.memcpy(out[idx..].ptr, &tmp, left);
            }
        }
    };
}
