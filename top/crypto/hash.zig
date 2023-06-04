const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const tab = @import("./tab.zig");
const core = @import("./core.zig");
pub fn GenericBlake2s(comptime out_bits: usize) type {
    return struct {
        h: [8]u32,
        t: u64,
        buf: [64]u8,
        buf_len: u8,
        const Blake2s = @This();
        pub const Options = struct {
            key: []const u8 = &.{},
            salt: ?[8]u8 = null,
            context: ?[8]u8 = null,
            expected_out_bits: usize = out_bits,
        };
        pub const len: comptime_int = out_bits / 8;
        pub const blk_len: comptime_int = 64;
        pub const key_len: comptime_int = 32;
        pub fn init(options: Options) Blake2s {
            var ret: Blake2s = undefined;
            ret.h = tab.init_vec.blake_2s;
            // default parameters
            ret.h[0] ^= 0x01010000 ^
                @truncate(u32, options.key.len << 8) ^
                @intCast(u32, options.expected_out_bits >> 3);
            ret.t = 0;
            ret.buf_len = 0;
            if (options.salt) |salt| {
                ret.h[4] ^= mem.readIntLittle(u32, salt[0..4]);
                ret.h[5] ^= mem.readIntLittle(u32, salt[4..8]);
            }
            if (options.context) |context| {
                ret.h[6] ^= mem.readIntLittle(u32, context[0..4]);
                ret.h[7] ^= mem.readIntLittle(u32, context[4..8]);
            }
            if (options.key.len != 0) {
                mach.memset(ret.buf[options.key.len..].ptr, 0, ret.buf.len -% options.key.len);
                ret.update(options.key);
                ret.buf_len = 64;
            }
            return ret;
        }
        pub fn hash(bytes: []const u8, dest: []u8, options: Options) void {
            var blake_2s: Blake2s = Blake2s.init(options);
            blake_2s.update(bytes);
            blake_2s.final(dest);
        }
        pub fn update(blake_2s: *Blake2s, bytes: []const u8) void {
            var off: usize = 0;
            // Partial buffer exists from previous update. Copy into buffer then hash.
            if (blake_2s.buf_len != 0 and blake_2s.buf_len +% bytes.len > 64) {
                off +%= 64 -% blake_2s.buf_len;
                mach.memcpy(blake_2s.buf[blake_2s.buf_len..].ptr, bytes.ptr, off);
                blake_2s.t +%= 64;
                blake_2s.round(blake_2s.buf[0..], false);
                blake_2s.buf_len = 0;
            }
            // Full middle blocks.
            while (off +% 64 < bytes.len) : (off +%= 64) {
                blake_2s.t +%= 64;
                blake_2s.round(bytes[off..][0..64], false);
            }
            // Copy any remainder for next pass.
            const rem: []const u8 = bytes[off..];
            mach.memcpy(blake_2s.buf[blake_2s.buf_len..].ptr, rem.ptr, rem.len);
            blake_2s.buf_len +%= @intCast(u8, rem.len);
        }
        pub fn final(blake_2s: *Blake2s, dest: []u8) void {
            @memset(blake_2s.buf[blake_2s.buf_len..], 0);
            blake_2s.t +%= blake_2s.buf_len;
            blake_2s.round(blake_2s.buf[0..], true);
            for (&blake_2s.h) |*x| x.* = mem.nativeToLittle(u32, x.*);
            mach.memcpy(dest.ptr, &blake_2s.h, 32);
        }
        fn round(blake_2s: *Blake2s, b: *const [64]u8, last: bool) void {
            var m: [16]u32 = undefined;
            var v: [16]u32 = undefined;
            for (&m, 0..) |*r, i| {
                r.* = mem.readIntLittle(u32, b[4 * i ..][0..4]);
            }
            var k: usize = 0;
            while (k < 8) : (k +%= 1) {
                v[k] = blake_2s.h[k];
                v[k +% 8] = tab.init_vec.blake_2s[k];
            }
            v[12] ^= @truncate(u32, blake_2s.t);
            v[13] ^= @intCast(u32, blake_2s.t >> 32);
            if (last) v[14] = ~v[14];
            var j: usize = 0;
            while (j < 10) : (j +%= 1) {
                for (tab.rounds.blake_2s) |r| {
                    v[r.a] = v[r.a] +% v[r.b] +% m[tab.sigma.blake_2s[j][r.x]];
                    v[r.d] = math.rotr(u32, v[r.d] ^ v[r.a], @as(usize, 16));
                    v[r.c] = v[r.c] +% v[r.d];
                    v[r.b] = math.rotr(u32, v[r.b] ^ v[r.c], @as(usize, 12));
                    v[r.a] = v[r.a] +% v[r.b] +% m[tab.sigma.blake_2s[j][r.y]];
                    v[r.d] = math.rotr(u32, v[r.d] ^ v[r.a], @as(usize, 8));
                    v[r.c] = v[r.c] +% v[r.d];
                    v[r.b] = math.rotr(u32, v[r.b] ^ v[r.c], @as(usize, 7));
                }
            }
            for (&blake_2s.h, 0..) |*r, i| {
                r.* ^= v[i] ^ v[i +% 8];
            }
        }
        fn write(blake_2s: *Blake2s, bytes: []const u8) usize {
            blake_2s.update(bytes);
            return bytes.len;
        }
    };
}
pub fn GenericBlake2b(comptime out_bits: usize) type {
    return struct {
        h: [8]u64,
        t: u128,
        buf: [128]u8,
        buf_len: u8,
        const Blake2b = @This();
        pub const Options = struct {
            key: []const u8 = &.{},
            salt: ?[16]u8 = null,
            context: ?[16]u8 = null,
            expected_out_bits: usize = out_bits,
        };
        pub const len: comptime_int = out_bits / 8;
        pub const blk_len: comptime_int = 128;
        pub const key_len: comptime_int = 32; // recommended key length
        pub fn init(options: Options) Blake2b {
            builtin.assert(8 <= out_bits and out_bits <= 512);
            var ret: Blake2b = undefined;
            ret.h = tab.init_vec.blake_2b;
            ret.h[0] ^= 0x01010000 ^ (options.key.len << 8) ^ (options.expected_out_bits >> 3);
            ret.t = 0;
            ret.buf_len = 0;
            if (options.salt) |salt| {
                ret.h[4] ^= mem.readIntLittle(u64, salt[0..8]);
                ret.h[5] ^= mem.readIntLittle(u64, salt[8..16]);
            }
            if (options.context) |context| {
                ret.h[6] ^= mem.readIntLittle(u64, context[0..8]);
                ret.h[7] ^= mem.readIntLittle(u64, context[8..16]);
            }
            if (options.key.len != 0) {
                mach.memset(ret.buf[options.key.len..].ptr, 0, ret.buf.len -% options.key.len);
                ret.update(options.key);
                ret.buf_len = 128;
            }
            return ret;
        }
        pub fn hash(bytes: []const u8, dest: []u8, options: Options) void {
            var blake_2b: Blake2b = Blake2b.init(options);
            blake_2b.update(bytes);
            blake_2b.final(dest);
        }
        pub fn update(blake_2b: *Blake2b, bytes: []const u8) void {
            var off: usize = 0;
            // Partial buffer exists from previous update. Copy into buffer then hash.
            if (blake_2b.buf_len != 0 and blake_2b.buf_len +% bytes.len > 128) {
                off +%= 128 -% blake_2b.buf_len;
                mach.memcpy(blake_2b.buf[blake_2b.buf_len..].ptr, bytes.ptr, off);
                blake_2b.t +%= 128;
                blake_2b.round(blake_2b.buf[0..], false);
                blake_2b.buf_len = 0;
            }
            // Full middle blocks.
            while (off +% 128 < bytes.len) : (off +%= 128) {
                blake_2b.t +%= 128;
                blake_2b.round(bytes[off..][0..128], false);
            }
            // Copy any remainder for next pass.
            const rem: []const u8 = bytes[off..];
            mach.memcpy(blake_2b.buf[blake_2b.buf_len..].ptr, rem.ptr, rem.len);
            blake_2b.buf_len +%= @intCast(u8, rem.len);
        }
        pub fn final(d: *Blake2b, dest: []u8) void {
            const buf: []u8 = d.buf[d.buf_len..];
            mach.memset(buf.ptr, 0, buf.len);
            d.t +%= d.buf_len;
            d.round(d.buf[0..], true);
            for (&d.h) |*x| x.* = mem.nativeToLittle(u64, x.*);
            mach.memcpy(dest.ptr, &d.h, 64);
        }
        fn round(blake_2b: *Blake2b, b: *const [128]u8, last: bool) void {
            var m: [16]u64 = undefined;
            var v: [16]u64 = undefined;
            for (&m, 0..) |*r, i| {
                r.* = mem.readIntLittle(u64, b[8 * i ..][0..8]);
            }
            var k: usize = 0;
            while (k < 8) : (k +%= 1) {
                v[k] = blake_2b.h[k];
                v[k +% 8] = tab.init_vec.blake_2b[k];
            }
            v[12] ^= @truncate(u64, blake_2b.t);
            v[13] ^= @intCast(u64, blake_2b.t >> 64);
            if (last) v[14] = ~v[14];
            var j: usize = 0;
            while (j < 12) : (j +%= 1) {
                for (tab.rounds.blake_2b) |r| {
                    v[r.a] = v[r.a] +% v[r.b] +% m[tab.sigma.blake_2b[j][r.x]];
                    v[r.d] = math.rotr(u64, v[r.d] ^ v[r.a], @as(usize, 32));
                    v[r.c] = v[r.c] +% v[r.d];
                    v[r.b] = math.rotr(u64, v[r.b] ^ v[r.c], @as(usize, 24));
                    v[r.a] = v[r.a] +% v[r.b] +% m[tab.sigma.blake_2b[j][r.y]];
                    v[r.d] = math.rotr(u64, v[r.d] ^ v[r.a], @as(usize, 16));
                    v[r.c] = v[r.c] +% v[r.d];
                    v[r.b] = math.rotr(u64, v[r.b] ^ v[r.c], @as(usize, 63));
                }
            }
            for (&blake_2b.h, 0..) |*r, i| {
                r.* ^= v[i] ^ v[i +% 8];
            }
        }
    };
}
