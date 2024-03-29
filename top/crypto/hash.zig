const mem = @import("../mem.zig");
const math = @import("../math.zig");
const bits = @import("../bits.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const tab = @import("tab.zig");
const core = @import("core.zig");
pub const Sha3_224 = GenericKeccak(1600, 224, 0x06, 24);
pub const Sha3_256 = GenericKeccak(1600, 256, 0x06, 24);
pub const Sha3_384 = GenericKeccak(1600, 384, 0x06, 24);
pub const Sha3_512 = GenericKeccak(1600, 512, 0x06, 24);
pub const Keccak256 = GenericKeccak(1600, 256, 0x01, 24);
pub const Keccak512 = GenericKeccak(1600, 512, 0x01, 24);
const safety: bool = false;
pub fn GenericKeccak(comptime number: comptime_int, comptime output_bits: comptime_int, comptime delim: u8, comptime rounds: comptime_int) type {
    return struct {
        st: State = .{},
        const Keccak = @This();
        const State = core.GenericKeccakPState(number, output_bits *% 2, delim, rounds);
        pub const len: comptime_int = output_bits / 8;
        pub const blk_len: comptime_int = State.rate;
        pub fn hash(bytes: []const u8, dest: []u8) void {
            var st: Keccak = .{};
            st.update(bytes);
            st.final(dest);
        }
        pub fn update(keccak: *Keccak, bytes: []const u8) void {
            keccak.st.absorb(bytes);
        }
        pub fn final(keccak: *Keccak, dest: []u8) void {
            keccak.st.pad();
            keccak.st.squeeze(dest[0..]);
        }
        fn write(keccak: *Keccak, bytes: []const u8) usize {
            keccak.update(bytes);
            return bytes.len;
        }
    };
}
pub fn GenericComposition(comptime H1: type, comptime H2: type) type {
    return struct {
        H1: H1,
        H2: H2,
        const Composition = @This();
        pub const len: comptime_int = H1.len;
        pub const blk_len: comptime_int = H1.blk_len;
        pub fn init() Composition {
            return .{ .H1 = H1.init(), .H2 = H2.init() };
        }
        pub fn hash(bytes: []const u8, dest: []u8) void {
            var comp: Composition = Composition.init();
            comp.update(bytes);
            comp.final(dest);
        }
        pub fn update(comp: *Composition, bytes: []const u8) void {
            comp.H2.update(bytes);
        }
        pub fn final(comp: *Composition, dest: []u8) void {
            var H2_digest: [H2.len]u8 = undefined;
            comp.H2.final(&H2_digest);
            comp.H1.update(&H2_digest);
            comp.H1.final(dest);
        }
    };
}
pub const Blake2s128 = GenericBlake2s(128);
pub const Blake2s160 = GenericBlake2s(160);
pub const Blake2s224 = GenericBlake2s(224);
pub const Blake2s256 = GenericBlake2s(256);
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
            ret.h[0] ^= 0x01010000 ^
                @as(u32, @truncate(options.key.len << 8)) ^
                @as(u32, @intCast(options.expected_out_bits >> 3));
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
                builtin.memset(ret.buf[options.key.len..].ptr, 0, ret.buf.len -% options.key.len);
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
            if (blake_2s.buf_len != 0 and blake_2s.buf_len +% bytes.len > 64) {
                off +%= 64 -% blake_2s.buf_len;
                builtin.memcpy(blake_2s.buf[blake_2s.buf_len..].ptr, bytes.ptr, off);
                blake_2s.t +%= 64;
                blake_2s.round(blake_2s.buf[0..], false);
                blake_2s.buf_len = 0;
            }
            while (off +% 64 < bytes.len) : (off +%= 64) {
                blake_2s.t +%= 64;
                blake_2s.round(bytes[off..][0..64], false);
            }
            const rem: []const u8 = bytes[off..];
            builtin.memcpy(blake_2s.buf[blake_2s.buf_len..].ptr, rem.ptr, rem.len);
            blake_2s.buf_len +%= @intCast(rem.len);
        }
        pub fn final(blake_2s: *Blake2s, dest: []u8) void {
            builtin.memset(blake_2s.buf[blake_2s.buf_len..].ptr, 0, blake_2s.buf.len -% blake_2s.buf_len);
            blake_2s.t +%= blake_2s.buf_len;
            blake_2s.round(blake_2s.buf[0..], true);
            for (&blake_2s.h) |*x| x.* = mem.nativeToLittle(u32, x.*);
            builtin.memcpy(dest.ptr, @as([*]u8, @ptrCast(&blake_2s.h)), 32);
        }
        fn round(blake_2s: *Blake2s, b: *const [64]u8, last: bool) void {
            var m: [16]u32 = undefined;
            var v: [16]u32 = undefined;
            var idx: usize = 0;
            while (idx != 16) : (idx +%= 1) {
                m[idx] = mem.readIntLittle(u32, b[4 *% idx ..][0..4]);
            }
            idx = 0;
            while (idx != 8) : (idx +%= 1) {
                v[idx] = blake_2s.h[idx];
                v[idx +% 8] = tab.init_vec.blake_2s[idx];
            }
            v[12] ^= @as(u32, @truncate(blake_2s.t));
            v[13] ^= @as(u32, @intCast(blake_2s.t >> 32));
            if (last) v[14] = ~v[14];
            idx = 0;
            while (idx != 10) : (idx +%= 1) {
                for (tab.rounds.blake_2s) |rc| {
                    v[rc.a] = v[rc.a] +% v[rc.b] +% m[tab.sigma.blake_2s[idx][rc.x]];
                    v[rc.d] = math.rotr(u32, v[rc.d] ^ v[rc.a], @as(usize, 16));
                    v[rc.c] = v[rc.c] +% v[rc.d];
                    v[rc.b] = math.rotr(u32, v[rc.b] ^ v[rc.c], @as(usize, 12));
                    v[rc.a] = v[rc.a] +% v[rc.b] +% m[tab.sigma.blake_2s[idx][rc.y]];
                    v[rc.d] = math.rotr(u32, v[rc.d] ^ v[rc.a], @as(usize, 8));
                    v[rc.c] = v[rc.c] +% v[rc.d];
                    v[rc.b] = math.rotr(u32, v[rc.b] ^ v[rc.c], @as(usize, 7));
                }
            }
            idx = 0;
            while (idx != blake_2s.h.len) : (idx +%= 1) {
                blake_2s.h[idx] ^= v[idx] ^ v[idx +% 8];
            }
        }
        fn write(blake_2s: *Blake2s, bytes: []const u8) usize {
            blake_2s.update(bytes);
            return bytes.len;
        }
    };
}
pub const Blake2b128 = GenericBlake2b(128);
pub const Blake2b160 = GenericBlake2b(160);
pub const Blake2b256 = GenericBlake2b(256);
pub const Blake2b384 = GenericBlake2b(384);
pub const Blake2b512 = GenericBlake2b(512);
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
        pub const key_len: comptime_int = 32;
        pub fn init(options: Options) Blake2b {
            debug.assert(8 <= out_bits and out_bits <= 512);
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
                builtin.memset(ret.buf[options.key.len..].ptr, 0, ret.buf.len -% options.key.len);
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
            if (blake_2b.buf_len != 0 and blake_2b.buf_len +% bytes.len > 128) {
                off +%= 128 -% blake_2b.buf_len;
                builtin.memcpy(blake_2b.buf[blake_2b.buf_len..].ptr, bytes.ptr, off);
                blake_2b.t +%= 128;
                blake_2b.round(blake_2b.buf[0..], false);
                blake_2b.buf_len = 0;
            }
            while (off +% 128 < bytes.len) : (off +%= 128) {
                blake_2b.t +%= 128;
                blake_2b.round(bytes[off..][0..128], false);
            }
            const rem: []const u8 = bytes[off..];
            builtin.memcpy(blake_2b.buf[blake_2b.buf_len..].ptr, rem.ptr, rem.len);
            blake_2b.buf_len +%= @as(u8, @intCast(rem.len));
        }
        pub fn final(blake_2b: *Blake2b, dest: []u8) void {
            const buf: []u8 = blake_2b.buf[blake_2b.buf_len..];
            builtin.memset(buf.ptr, 0, buf.len);
            blake_2b.t +%= blake_2b.buf_len;
            blake_2b.round(blake_2b.buf[0..], true);
            for (&blake_2b.h) |*x| x.* = mem.nativeToLittle(u64, x.*);
            builtin.memcpy(dest.ptr, @as([*]u8, @ptrCast(&blake_2b.h)), 64);
        }
        fn round(blake_2b: *Blake2b, bytes: *const [128]u8, last: bool) void {
            var m: [16]u64 = undefined;
            var v: [16]u64 = undefined;
            for (&m, 0..) |*r, i| {
                r.* = mem.readIntLittle(u64, bytes[8 *% i ..][0..8]);
            }
            var k: usize = 0;
            while (k < 8) : (k +%= 1) {
                v[k] = blake_2b.h[k];
                v[k +% 8] = tab.init_vec.blake_2b[k];
            }
            v[12] ^= @as(u64, @truncate(blake_2b.t));
            v[13] ^= @as(u64, @intCast(blake_2b.t >> 64));
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
pub const CompressVectorized = struct {
    const Lane = @Vector(4, u32);
    const Rows = [4]Lane;
    fn g(even: bool, rows: *Rows, m: Lane) void {
        rows[0] +%= rows[1] +% m;
        rows[3] ^= rows[0];
        rows[3] = math.rotr(Lane, rows[3], bits.cmov8(even, 8, 16));
        rows[2] +%= rows[3];
        rows[1] ^= rows[2];
        rows[1] = math.rotr(Lane, rows[1], bits.cmov8(even, 7, 12));
    }
    fn diagonalize(rows: *Rows) void {
        rows[0] = @shuffle(u32, rows[0], undefined, [_]i32{ 3, 0, 1, 2 });
        rows[3] = @shuffle(u32, rows[3], undefined, [_]i32{ 2, 3, 0, 1 });
        rows[2] = @shuffle(u32, rows[2], undefined, [_]i32{ 1, 2, 3, 0 });
    }
    fn undiagonalize(rows: *Rows) void {
        rows[0] = @shuffle(u32, rows[0], undefined, [_]i32{ 1, 2, 3, 0 });
        rows[3] = @shuffle(u32, rows[3], undefined, [_]i32{ 2, 3, 0, 1 });
        rows[2] = @shuffle(u32, rows[2], undefined, [_]i32{ 3, 0, 1, 2 });
    }
    pub fn compress(
        chaining_value: [8]u32,
        block_words: [16]u32,
        block_len: u32,
        counter: u64,
        flags: u8,
    ) [16]u32 {
        const md: Lane = .{ @as(u32, @truncate(counter)), @as(u32, @truncate(counter >> 32)), block_len, @as(u32, flags) };
        var rows: Rows = .{ chaining_value[0..4].*, chaining_value[4..8].*, tab.init_vec.blake_3[0..4].*, md };
        var m: Rows = .{ block_words[0..4].*, block_words[4..8].*, block_words[8..12].*, block_words[12..16].* };
        var t0: @Vector(4, u32) = @shuffle(u32, m[0], m[1], [_]i32{ 0, 2, (-1 -% 0), (-1 -% 2) });
        g(false, &rows, t0);
        var t1: @Vector(4, u32) = @shuffle(u32, m[0], m[1], [_]i32{ 1, 3, (-1 -% 1), (-1 -% 3) });
        g(true, &rows, t1);
        diagonalize(&rows);
        var t2: @Vector(4, u32) = @shuffle(u32, m[2], m[3], [_]i32{ 0, 2, (-1 -% 0), (-1 -% 2) });
        t2 = @shuffle(u32, t2, undefined, [_]i32{ 3, 0, 1, 2 });
        g(false, &rows, t2);
        var t3: @Vector(4, u32) = @shuffle(u32, m[2], m[3], [_]i32{ 1, 3, (-1 -% 1), (-1 -% 3) });
        t3 = @shuffle(u32, t3, undefined, [_]i32{ 3, 0, 1, 2 });
        g(true, &rows, t3);
        undiagonalize(&rows);
        m = Rows{ t0, t1, t2, t3 };
        var i: usize = 0;
        while (i < 6) : (i +%= 1) {
            t0 = @shuffle(u32, m[0], m[1], [_]i32{ 2, 1, (-1 -% 1), (-1 -% 3) });
            t0 = @shuffle(u32, t0, undefined, [_]i32{ 1, 2, 3, 0 });
            g(false, &rows, t0);
            t1 = @shuffle(u32, m[2], m[3], [_]i32{ 2, 2, (-1 -% 3), (-1 -% 3) });
            var tt: @Vector(4, u32) = @shuffle(u32, m[0], undefined, [_]i32{ 3, 3, 0, 0 });
            t1 = @shuffle(u32, tt, t1, [_]i32{ 0, (-1 -% 1), 2, (-1 -% 3) });
            g(true, &rows, t1);
            diagonalize(&rows);
            t2 = @shuffle(u32, m[3], m[1], [_]i32{ 0, 1, (-1 -% 0), (-1 -% 1) });
            tt = @shuffle(u32, t2, m[2], [_]i32{ 0, 1, 2, (-1 -% 3) });
            t2 = @shuffle(u32, tt, undefined, [_]i32{ 0, 2, 3, 1 });
            g(false, &rows, t2);
            t3 = @shuffle(u32, m[1], m[3], [_]i32{ 2, (-1 -% 2), 3, (-1 -% 3) });
            tt = @shuffle(u32, m[2], t3, [_]i32{ 0, (-1 -% 0), 1, (-1 -% 1) });
            t3 = @shuffle(u32, tt, undefined, [_]i32{ 2, 3, 1, 0 });
            g(true, &rows, t3);
            undiagonalize(&rows);
            m = Rows{ t0, t1, t2, t3 };
        }
        rows[0] ^= rows[2];
        rows[1] ^= rows[3];
        rows[2] ^= @Vector(4, u32){ chaining_value[0], chaining_value[1], chaining_value[2], chaining_value[3] };
        rows[3] ^= @Vector(4, u32){ chaining_value[4], chaining_value[5], chaining_value[6], chaining_value[7] };
        return @as([16]u32, @bitCast(rows));
    }
};
pub const CompressGeneric = struct {
    fn g(state: *[16]u32, comptime a: usize, comptime b: usize, comptime c: usize, comptime d: usize, mx: u32, my: u32) void {
        state[a] +%= state[b] +% mx;
        state[d] = math.rotr(u32, state[d] ^ state[a], 16);
        state[c] +%= state[d];
        state[b] = math.rotr(u32, state[b] ^ state[c], 12);
        state[a] +%= state[b] +% my;
        state[d] = math.rotr(u32, state[d] ^ state[a], 8);
        state[c] +%= state[d];
        state[b] = math.rotr(u32, state[b] ^ state[c], 7);
    }
    fn round(state: *[16]u32, msg: [16]u32, schedule: [16]u8) void {
        g(state, 0, 4, 8, 12, msg[schedule[0]], msg[schedule[1]]);
        g(state, 1, 5, 9, 13, msg[schedule[2]], msg[schedule[3]]);
        g(state, 2, 6, 10, 14, msg[schedule[4]], msg[schedule[5]]);
        g(state, 3, 7, 11, 15, msg[schedule[6]], msg[schedule[7]]);
        g(state, 0, 5, 10, 15, msg[schedule[8]], msg[schedule[9]]);
        g(state, 1, 6, 11, 12, msg[schedule[10]], msg[schedule[11]]);
        g(state, 2, 7, 8, 13, msg[schedule[12]], msg[schedule[13]]);
        g(state, 3, 4, 9, 14, msg[schedule[14]], msg[schedule[15]]);
    }
    pub fn compress(
        chaining_value: [8]u32,
        block_words: [16]u32,
        block_len: u32,
        counter: u64,
        flags: u8,
    ) [16]u32 {
        var state: [16]u32 = .{
            chaining_value[0],            chaining_value[1],
            chaining_value[2],            chaining_value[3],
            chaining_value[4],            chaining_value[5],
            chaining_value[6],            chaining_value[7],
            tab.init_vec.blake_3[0],      tab.init_vec.blake_3[1],
            tab.init_vec.blake_3[2],      tab.init_vec.blake_3[3],
            @as(u32, @truncate(counter)), @as(u32, @truncate(counter >> 32)),
            block_len,                    flags,
        };
        const msg_schedule: [7][16]u8 = .{
            .{ 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
            .{ 2, 6, 3, 10, 7, 0, 4, 13, 1, 11, 12, 5, 9, 14, 15, 8 },
            .{ 3, 4, 10, 12, 13, 2, 7, 14, 6, 5, 9, 0, 11, 15, 8, 1 },
            .{ 10, 7, 12, 9, 14, 3, 13, 15, 4, 0, 11, 2, 5, 8, 1, 6 },
            .{ 12, 13, 9, 11, 15, 10, 14, 8, 7, 2, 5, 3, 0, 1, 6, 4 },
            .{ 9, 14, 11, 5, 8, 12, 15, 1, 13, 3, 0, 10, 2, 6, 4, 7 },
            .{ 11, 15, 5, 0, 1, 9, 8, 6, 14, 10, 2, 12, 3, 4, 7, 13 },
        };
        for (msg_schedule) |schedule| {
            round(&state, block_words, schedule);
        }
        for (chaining_value, 0..) |_, i| {
            state[i] ^= state[i +% 8];
            state[i +% 8] ^= chaining_value[i];
        }
        return state;
    }
};
const u32x4 = @Vector(4, u32);
const u64x8 = @Vector(8, u64);
pub const Md5 = struct {
    s: [4]u32 = tab.init_vec.md5,
    buf: [64]u8 = undefined,
    buf_len: u8 = 0,
    total_len: u64 = 0,
    pub const len: comptime_int = 16;
    pub const blk_len: comptime_int = 64;
    pub fn init() Md5 {
        return .{};
    }
    pub fn hash(bytes: []const u8, dest: []u8) void {
        var md5: Md5 = Md5.init();
        md5.update(bytes);
        md5.final(dest);
    }
    pub fn update(md5: *Md5, bytes: []const u8) void {
        @setRuntimeSafety(safety);
        var off: usize = 0;
        if (md5.buf_len != 0 and md5.buf_len +% bytes.len >= 64) {
            off +%= 64 -% md5.buf_len;
            builtin.memcpy(md5.buf[md5.buf_len..].ptr, bytes.ptr, off);
            md5.round(&md5.buf);
            md5.buf_len = 0;
        }
        while (off +% 64 <= bytes.len) : (off +%= 64) {
            md5.round(bytes[off..][0..64]);
        }
        const rem: []const u8 = bytes[off..];
        builtin.memcpy(md5.buf[md5.buf_len..].ptr, rem.ptr, rem.len);
        md5.buf_len +%= @intCast(rem.len);
        md5.total_len +%= bytes.len;
    }
    pub fn final(md5: *Md5, dest: []u8) void {
        @setRuntimeSafety(safety);
        builtin.memset(md5.buf[md5.buf_len..].ptr, 0, md5.buf.len -% md5.buf_len);
        md5.buf[md5.buf_len] = 0x80;
        md5.buf_len +%= 1;
        if (64 -% md5.buf_len < 8) {
            md5.round(&md5.buf);
            builtin.memset(&md5.buf, 0, 64);
        }
        var idx: usize = 1;
        var off: u64 = md5.total_len >> 5;
        md5.buf[56] = @as(u8, @intCast(md5.total_len & 0x1f)) << 3;
        while (idx < 8) : (idx +%= 1) {
            md5.buf[56 +% idx] = @intCast(off & 0xff);
            off >>= 8;
        }
        md5.round(md5.buf[0..]);
        for (md5.s, 0..) |s, j| {
            mem.writeIntLittle(u32, dest[4 *% j ..][0..4], s);
        }
    }
    fn round(md5: *Md5, bytes: *const [64]u8) void {
        @setRuntimeSafety(safety);
        var s: [16]u32 = undefined;
        var idx: usize = 0;
        while (idx < 16) : (idx +%= 1) {
            s[idx] = 0;
            s[idx] |= @as(u32, bytes[idx *% 4 +% 0]);
            s[idx] |= @as(u32, bytes[idx *% 4 +% 1]) << 8;
            s[idx] |= @as(u32, bytes[idx *% 4 +% 2]) << 16;
            s[idx] |= @as(u32, bytes[idx *% 4 +% 3]) << 24;
        }
        var v: [4]u32 = md5.s;
        for (tab.rounds.md5_0) |r| {
            v[r.a] = v[r.a] +% (v[r.d] ^ (v[r.b] & (v[r.c] ^ v[r.d]))) +% r.t +% s[r.k];
            v[r.a] = v[r.b] +% math.rotl(u32, v[r.a], r.s);
        }
        for (tab.rounds.md5_1) |r| {
            v[r.a] = v[r.a] +% (v[r.c] ^ (v[r.d] & (v[r.b] ^ v[r.c]))) +% r.t +% s[r.k];
            v[r.a] = v[r.b] +% math.rotl(u32, v[r.a], r.s);
        }
        for (tab.rounds.md5_2) |r| {
            v[r.a] = v[r.a] +% (v[r.b] ^ v[r.c] ^ v[r.d]) +% r.t +% s[r.k];
            v[r.a] = v[r.b] +% math.rotl(u32, v[r.a], r.s);
        }
        for (tab.rounds.md5_3) |r| {
            v[r.a] = v[r.a] +% (v[r.c] ^ (v[r.b] | ~v[r.d])) +% r.t +% s[r.k];
            v[r.a] = v[r.b] +% math.rotl(u32, v[r.a], r.s);
        }
        md5.s +%= @as(u32x4, v);
    }
};
pub const Sha2Params64 = struct {
    init_vec: [8]u64,
    digest_bits: usize,
};
pub const Sha2Params32 = struct {
    init_vec: [8]u32,
    digest_bits: usize,
};
pub const Sha512 = GenericSha2x64(.{ .init_vec = tab.init_vec.sha512, .digest_bits = 512 });
fn GenericSha2x64(comptime params: Sha2Params64) type {
    return struct {
        s: [8]u64,
        buf: [128]u8 = undefined,
        buf_len: u8 = 0,
        total_len: u128 = 0,
        const Sha2x64 = @This();
        pub const len: comptime_int = params.digest_bits / 8;
        pub const blk_len: comptime_int = 128;
        pub fn init() Sha2x64 {
            return Sha2x64{ .s = params.init_vec };
        }
        pub fn hash(bytes: []const u8, dest: []u8) void {
            var sha: Sha2x64 = Sha2x64.init();
            sha.update(bytes);
            sha.final(dest);
        }
        pub fn update(sha: *Sha2x64, bytes: []const u8) void {
            var off: usize = 0;
            if (sha.buf_len != 0 and sha.buf_len +% bytes.len >= 128) {
                off +%= 128 -% sha.buf_len;
                builtin.memcpy(sha.buf[sha.buf_len..].ptr, bytes.ptr, off);
                sha.round(&sha.buf);
                sha.buf_len = 0;
            }
            while (off +% 128 <= bytes.len) : (off +%= 128) {
                sha.round(bytes[off..][0..128]);
            }
            const rem: []const u8 = bytes[off..];
            builtin.memcpy(sha.buf[sha.buf_len..].ptr, rem.ptr, rem.len);
            sha.buf_len +%= @as(u8, @intCast(bytes[off..].len));
            sha.total_len +%= bytes.len;
        }
        pub fn peek(sha: Sha2x64) [len]u8 {
            var copy: Sha2x64 = sha;
            return copy.finalResult();
        }
        pub fn final(sha: *Sha2x64, dest: []u8) void {
            @memset(sha.buf[sha.buf_len..], 0);
            sha.buf[sha.buf_len] = 0x80;
            sha.buf_len +%= 1;
            if (128 -% sha.buf_len < 16) {
                sha.round(sha.buf[0..]);
                @memset(sha.buf[0..], 0);
            }
            var i: u64 = 1;
            var off: u128 = sha.total_len >> 5;
            sha.buf[127] = @as(u8, @intCast(sha.total_len & 0x1f)) << 3;
            while (i < 16) : (i +%= 1) {
                sha.buf[127 -% i] = @as(u8, @intCast(off & 0xff));
                off >>= 8;
            }
            sha.round(sha.buf[0..]);
            const rr = sha.s[0 .. params.digest_bits / 64];
            for (rr, 0..) |s, j| {
                mem.writeIntBig(u64, dest[8 *% j ..][0..8], s);
            }
        }
        pub fn finalResult(sha: *Sha2x64) [len]u8 {
            var result: [len]u8 = undefined;
            sha.final(&result);
            return result;
        }
        fn round(sha: *Sha2x64, b: *const [128]u8) void {
            var s: [80]u64 = undefined;
            var idx: usize = 0;
            while (idx < 16) : (idx +%= 1) {
                s[idx] = 0;
                s[idx] |= @as(u64, b[idx *% 8 +% 0]) << 56;
                s[idx] |= @as(u64, b[idx *% 8 +% 1]) << 48;
                s[idx] |= @as(u64, b[idx *% 8 +% 2]) << 40;
                s[idx] |= @as(u64, b[idx *% 8 +% 3]) << 32;
                s[idx] |= @as(u64, b[idx *% 8 +% 4]) << 24;
                s[idx] |= @as(u64, b[idx *% 8 +% 5]) << 16;
                s[idx] |= @as(u64, b[idx *% 8 +% 6]) << 8;
                s[idx] |= @as(u64, b[idx *% 8 +% 7]) << 0;
            }
            while (idx < 80) : (idx +%= 1) {
                s[idx] = s[idx -% 16] +% s[idx -% 7] +%
                    (math.rotr(u64, s[idx -% 15], @as(u64, 1)) ^
                    math.rotr(u64, s[idx -% 15], @as(u64, 8)) ^ (s[idx -% 15] >> 7)) +%
                    (math.rotr(u64, s[idx -% 2], @as(u64, 19)) ^
                    math.rotr(u64, s[idx -% 2], @as(u64, 61)) ^ (s[idx -% 2] >> 6));
            }
            var v: [8]u64 = .{
                sha.s[0], sha.s[1], sha.s[2], sha.s[3],
                sha.s[4], sha.s[5], sha.s[6], sha.s[7],
            };
            for (tab.rounds.sha2x64_0) |r| {
                v[r.h] = v[r.h] +% (math.rotr(u64, v[r.e], @as(u64, 14)) ^
                    math.rotr(u64, v[r.e], @as(u64, 18)) ^
                    math.rotr(u64, v[r.e], @as(u64, 41))) +%
                    (v[r.g] ^ (v[r.e] & (v[r.f] ^ v[r.g]))) +% r.k +% s[r.i];
                v[r.d] = v[r.d] +% v[r.h];
                v[r.h] = v[r.h] +% (math.rotr(u64, v[r.a], @as(u64, 28)) ^
                    math.rotr(u64, v[r.a], @as(u64, 34)) ^
                    math.rotr(u64, v[r.a], @as(u64, 39))) +%
                    ((v[r.a] & (v[r.b] | v[r.c])) | (v[r.b] & v[r.c]));
            }
            sha.s +%= @as(u64x8, v);
        }
    };
}
pub const Sha384oSha384 = GenericComposition(Sha384, Sha384);
pub const Sha512oSha512 = GenericComposition(Sha512, Sha512);
pub const Sha384 = GenericSha2x64(.{ .init_vec = tab.init_vec.sha384, .digest_bits = 384 });
pub const Sha512256 = GenericSha2x64(.{ .init_vec = tab.init_vec.sha512_256, .digest_bits = 256 });
pub const Sha512T256 = GenericSha2x64(.{ .init_vec = tab.init_vec.sha512_t_256, .digest_bits = 256 });
pub const Shake128 = Shake(128);
pub const Shake256 = Shake(256);
pub fn TurboShake128(comptime delim: ?u8) type {
    return TurboShake(128, delim);
}
pub fn TurboShake256(comptime delim: ?u8) type {
    return TurboShake(256, delim);
}
pub fn Shake(comptime security_level: u11) type {
    return GenericShakeLike(security_level, 0x1f, 24);
}
pub fn TurboShake(comptime security_level: u11, comptime delim: ?u8) type {
    return GenericShakeLike(security_level, delim orelse 0x1f, 12);
}
fn GenericShakeLike(comptime security_level: u11, comptime delim: u8, comptime rounds: u5) type {
    return struct {
        st: State = .{},
        buf: [State.rate]u8 = undefined,
        offset: usize = 0,
        padded: bool = false,
        const ShakeLike = @This();
        const State = core.GenericKeccakPState(1600, security_level *% 2, delim, rounds);
        pub const len: comptime_int = security_level / 2;
        pub const blk_len: comptime_int = State.rate;
        pub fn hash(bytes: []const u8, dest: []u8) void {
            var st: ShakeLike = .{};
            st.update(bytes);
            st.squeeze(dest);
        }
        pub fn update(shake: *ShakeLike, bytes: []const u8) void {
            shake.st.absorb(bytes);
        }
        pub fn squeeze(shake: *ShakeLike, dest: []u8) void {
            if (!shake.padded) {
                shake.st.pad();
                shake.padded = true;
            }
            var bytes: []u8 = dest;
            if (shake.offset > 0) {
                var off: usize = shake.buf.len -% shake.offset;
                if (off > 0) {
                    off = @min(off, bytes.len);
                    builtin.memcpy(bytes.ptr, shake.buf[shake.offset..].ptr, off);
                    bytes = bytes[off..];
                    shake.offset +%= off;
                    if (bytes.len == 0) {
                        return;
                    }
                }
            }
            const full_blocks: []u8 = bytes[0 .. bytes.len -% bytes.len % State.rate];
            if (full_blocks.len > 0) {
                shake.st.squeeze(full_blocks);
                bytes = bytes[full_blocks.len..];
            }
            if (bytes.len > 0) {
                shake.st.squeeze(shake.buf[0..]);
                @memcpy(bytes[0..], shake.buf[0..bytes.len]);
                shake.offset = bytes.len;
            }
        }
        pub fn final(shake: *ShakeLike, dest: []u8) void {
            shake.squeeze(dest);
            shake.st.clear(0, State.rate);
        }
        fn write(shake: *ShakeLike, bytes: []const u8) usize {
            shake.update(bytes);
            return bytes.len;
        }
    };
}

//
// Everything below is mysterious.
//

pub const Blake3 = struct {
    chunk_state: ChunkState,
    key: [8]u32,
    cv_stack: [54][8]u32 = undefined,
    cv_stack_len: u8 = 0,
    flags: u8,
    pub const Options = struct {
        key: ?[len]u8 = null,
    };
    pub const len: comptime_int = 32;
    pub const blk_len: comptime_int = 64;
    pub const key_len: comptime_int = 32;
    const ChunkIterator = struct {
        buf: []u8,
        buf_len: usize,
        fn init(buf: []u8, buf_len: usize) ChunkIterator {
            return ChunkIterator{
                .buf = buf,
                .buf_len = buf_len,
            };
        }
        fn next(itr: *ChunkIterator) ?[]u8 {
            const next_chunk = itr.buf[0..@min(itr.buf_len, itr.buf.len)];
            itr.buf = itr.buf[next_chunk.len..];
            return if (next_chunk.len > 0) next_chunk else null;
        }
    };
    const chunk_len: comptime_int = 1024;
    const chunk_start: comptime_int = 1;
    const chunk_end: comptime_int = 2;
    const parent: comptime_int = 4;
    const root: comptime_int = 8;
    const keyed_hash: comptime_int = 16;
    const derive_key_context: comptime_int = 32;
    const derive_key_material: comptime_int = 64;
    const compress = if (builtin.cpu.arch == .x86_64)
        CompressVectorized.compress
    else
        CompressGeneric.compress;
    fn first8Words(words: [16]u32) [8]u32 {
        return @as(*const [8]u32, @ptrCast(&words)).*;
    }
    fn wordsFromLittleEndianBytes(comptime count: usize, bytes: [count *% 4]u8) [count]u32 {
        var words: [count]u32 = undefined;
        for (&words, 0..) |*word, i| {
            word.* = mem.readIntSliceLittle(u32, bytes[4 *% i ..]);
        }
        return words;
    }
    const Output = struct {
        input_chaining_value: [8]u32 align(16),
        block_words: [16]u32 align(16),
        block_len: u32,
        counter: u64,
        flags: u8,
        fn chainingValue(dest: *const Output) [8]u32 {
            return first8Words(compress(dest.input_chaining_value, dest.block_words, dest.block_len, dest.counter, dest.flags));
        }
        fn rootOutputBytes(output: *const Output, buf: []u8) void {
            var out_block_itr: ChunkIterator = .{ .buf = buf, .buf_len = 2 *% len };
            var output_block_counter: usize = 0;
            while (out_block_itr.next()) |out_block| {
                const words = compress(output.input_chaining_value, output.block_words, output.block_len, output_block_counter, output.flags | root);
                var out_word_itr: ChunkIterator = .{ .buf = out_block, .buf_len = 4 };
                var word_counter: usize = 0;
                while (out_word_itr.next()) |out_word| {
                    var word_bytes: [4]u8 = undefined;
                    mem.writeIntLittle(u32, &word_bytes, words[word_counter]);
                    builtin.memcpy(out_word.ptr, &word_bytes, out_word.len);
                    word_counter +%= 1;
                }
                output_block_counter +%= 1;
            }
        }
    };
    const ChunkState = struct {
        chaining_value: [8]u32 align(16),
        chunk_counter: u64,
        block: [blk_len]u8 align(16) = [1]u8{0} ** blk_len,
        block_len: u8 = 0,
        blocks_compressed: u8 = 0,
        flags: u8,
        fn init(key: [8]u32, chunk_counter: u64, flags: u8) ChunkState {
            return ChunkState{ .chaining_value = key, .chunk_counter = chunk_counter, .flags = flags };
        }
        fn len(st: *const ChunkState) usize {
            return blk_len *% @as(usize, st.blocks_compressed) +% @as(usize, st.block_len);
        }
        fn fillBlockBuf(st: *ChunkState, input: []const u8) []const u8 {
            const want: u64 = blk_len -% st.block_len;
            const take: u64 = @min(want, input.len);
            builtin.memcpy(st.block[st.block_len..].ptr, input.ptr, take);
            st.block_len +%= @as(u8, @truncate(take));
            return input[take..];
        }
        fn startFlag(st: *const ChunkState) u8 {
            return if (st.blocks_compressed == 0) chunk_start else 0;
        }
        fn update(st: *ChunkState, src: []const u8) void {
            var bytes: []const u8 = src;
            while (bytes.len > 0) {
                if (st.block_len == blk_len) {
                    const block_words: [16]u32 = wordsFromLittleEndianBytes(16, st.block);
                    st.chaining_value = first8Words(compress(
                        st.chaining_value,
                        block_words,
                        blk_len,
                        st.chunk_counter,
                        st.flags | st.startFlag(),
                    ));
                    st.blocks_compressed +%= 1;
                    st.block = [_]u8{0} ** blk_len;
                    st.block_len = 0;
                }
                bytes = st.fillBlockBuf(bytes);
            }
        }
        fn output(st: *const ChunkState) Output {
            const block_words: [16]u32 = wordsFromLittleEndianBytes(16, st.block);
            return Output{
                .input_chaining_value = st.chaining_value,
                .block_words = block_words,
                .block_len = st.block_len,
                .counter = st.chunk_counter,
                .flags = st.flags | st.startFlag() | chunk_end,
            };
        }
    };
    fn parentOutput(left_child_cv: [8]u32, right_child_cv: [8]u32, key: [8]u32, flags: u8) Output {
        var block_words: [16]u32 align(16) = undefined;
        block_words[0..8].* = left_child_cv;
        block_words[8..].* = right_child_cv;
        return Output{
            .input_chaining_value = key,
            .block_words = block_words,
            .block_len = blk_len,
            .counter = 0,
            .flags = parent | flags,
        };
    }
    fn parentCv(left_child_cv: [8]u32, right_child_cv: [8]u32, key: [8]u32, flags: u8) [8]u32 {
        return parentOutput(left_child_cv, right_child_cv, key, flags).chainingValue();
    }
    fn init_internal(key: [8]u32, flags: u8) Blake3 {
        return Blake3{ .chunk_state = ChunkState.init(key, 0, flags), .key = key, .flags = flags };
    }
    pub fn init(options: Options) Blake3 {
        if (options.key) |key| {
            const key_words: [8]u32 = wordsFromLittleEndianBytes(8, key);
            return Blake3.init_internal(key_words, keyed_hash);
        } else {
            return Blake3.init_internal(tab.init_vec.blake_3, 0);
        }
    }
    pub fn initKdf(context: []const u8) Blake3 {
        var context_hasher: Blake3 = Blake3.init_internal(tab.init_vec.blake_3, derive_key_context);
        context_hasher.update(context);
        var context_key: [key_len]u8 = undefined;
        context_hasher.final(context_key[0..]);
        const context_key_words: [8]u32 = wordsFromLittleEndianBytes(8, context_key);
        return Blake3.init_internal(context_key_words, derive_key_material);
    }
    pub fn hash(bytes: []const u8, dest: []u8, options: Options) void {
        var blake_3: Blake3 = Blake3.init(options);
        blake_3.update(bytes);
        blake_3.final(dest);
    }
    fn pushCv(blake_3: *Blake3, cv: [8]u32) void {
        blake_3.cv_stack[blake_3.cv_stack_len] = cv;
        blake_3.cv_stack_len +%= 1;
    }
    fn popCv(blake_3: *Blake3) [8]u32 {
        blake_3.cv_stack_len -%= 1;
        return blake_3.cv_stack[blake_3.cv_stack_len];
    }
    fn addChunkChainingValue(blake_3: *Blake3, first_cv: [8]u32, total_chunks: u64) void {
        var new_cv: [8]u32 = first_cv;
        var chunk_counter: u64 = total_chunks;
        while (chunk_counter & 1 == 0) {
            new_cv = parentCv(blake_3.popCv(), new_cv, blake_3.key, blake_3.flags);
            chunk_counter >>= 1;
        }
        blake_3.pushCv(new_cv);
    }
    pub fn update(blake_3: *Blake3, src: []const u8) void {
        var bytes: []const u8 = src;
        while (bytes.len > 0) {
            if (blake_3.chunk_state.len() == chunk_len) {
                const chunk_cv: [8]u32 = blake_3.chunk_state.output().chainingValue();
                const total_chunks: u64 = blake_3.chunk_state.chunk_counter +% 1;
                blake_3.addChunkChainingValue(chunk_cv, total_chunks);
                blake_3.chunk_state = ChunkState.init(blake_3.key, total_chunks, blake_3.flags);
            }
            const want: u64 = chunk_len -% blake_3.chunk_state.len();
            const take: usize = @min(want, bytes.len);
            blake_3.chunk_state.update(bytes[0..take]);
            bytes = bytes[take..];
        }
    }
    pub fn final(blake_3: *const Blake3, dest: []u8) void {
        var output: Output = blake_3.chunk_state.output();
        var parent_nodes_remaining: usize = blake_3.cv_stack_len;
        while (parent_nodes_remaining > 0) {
            parent_nodes_remaining -%= 1;
            output = parentOutput(
                blake_3.cv_stack[parent_nodes_remaining],
                output.chainingValue(),
                blake_3.key,
                blake_3.flags,
            );
        }
        output.rootOutputBytes(dest);
    }
    fn write(blake_3: *Blake3, bytes: []const u8) usize {
        blake_3.update(bytes);
        return bytes.len;
    }
};
fn GenericSha2x32(comptime params: Sha2Params32) type {
    return struct {
        s: [8]u32 align(16),
        buf: [64]u8 = undefined,
        buf_len: u8 = 0,
        total_len: u64 = 0,
        const Sha2x32 = @This();
        pub const len: comptime_int = params.digest_bits / 8;
        pub const blk_len: comptime_int = 64;
        pub fn init() Sha2x32 {
            return .{ .s = params.init_vec };
        }
        pub fn hash(bytes: []const u8, dest: []u8) void {
            var sha: Sha2x32 = Sha2x32.init();
            sha.update(bytes);
            sha.final(dest);
        }
        pub fn update(sha: *Sha2x32, bytes: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var off: usize = 0;
            if (sha.buf_len != 0 and sha.buf_len +% bytes.len >= 64) {
                off +%= 64 -% sha.buf_len;
                builtin.memcpy(sha.buf[sha.buf_len..].ptr, bytes.ptr, off);
                sha.round(&sha.buf);
                sha.buf_len = 0;
            }
            while (off +% 64 <= bytes.len) : (off +%= 64) {
                sha.round(bytes[off..][0..64]);
            }
            const rem: []const u8 = bytes[off..];
            @memcpy(sha.buf[sha.buf_len..], rem);
            sha.buf_len +%= @intCast(rem.len);
            sha.total_len +%= bytes.len;
        }
        pub fn peek(sha: Sha2x32) [len]u8 {
            var copy: Sha2x32 = sha;
            return copy.finalResult();
        }
        pub fn final(sha: *Sha2x32, dest: []u8) void {
            @setRuntimeSafety(builtin.is_safe);
            @memset(sha.buf[sha.buf_len..], 0);
            sha.buf[sha.buf_len] = 0x80;
            sha.buf_len +%= 1;
            if (64 -% sha.buf_len < 8) {
                sha.round(&sha.buf);
                @memset(sha.buf[0..], 0);
            }
            var i: u64 = 1;
            var off: u64 = sha.total_len >> 5;
            sha.buf[63] = @as(u8, @intCast(sha.total_len & 0x1f)) << 3;
            while (i < 8) : (i +%= 1) {
                sha.buf[63 -% i] = @intCast(off & 0xff);
                off >>= 8;
            }
            sha.round(&sha.buf);
            const rr = sha.s[0 .. params.digest_bits / 32];
            for (rr, 0..) |s, j| {
                mem.writeIntBig(u32, dest[4 * j ..][0..4], s);
            }
        }
        pub fn finalResult(sha2: *Sha2x32) [len]u8 {
            var result: [len]u8 = undefined;
            sha2.final(&result);
            return result;
        }
        fn round(sha2: *Sha2x32, buf: *const [64]u8) void {
            var s: [64]u32 align(16) = undefined;
            const elems: *align(1) const [16][4]u8 = @ptrCast(buf);
            for (elems, 0..) |*elem, i| {
                s[i] = mem.readIntBig(u32, elem);
            }
            var idx: usize = 16;
            while (idx != 64) : (idx +%= 1) {
                s[idx] = s[idx -% 16] +% s[idx -% 7] +%
                    (math.rotr(u32, s[idx -% 15], @as(u32, 7)) ^
                    math.rotr(u32, s[idx -% 15], @as(u32, 18)) ^ (s[idx -% 15] >> 3)) +%
                    (math.rotr(u32, s[idx -% 2], @as(u32, 17)) ^
                    math.rotr(u32, s[idx -% 2], @as(u32, 19)) ^ (s[idx -% 2] >> 10));
            }
            var v: [8]u32 = [_]u32{ sha2.s[0], sha2.s[1], sha2.s[2], sha2.s[3], sha2.s[4], sha2.s[5], sha2.s[6], sha2.s[7] };
            for (tab.rounds.sha2x32_0) |r| {
                v[r.h] = v[r.h] +% (math.rotr(u32, v[r.e], @as(u32, 6)) ^
                    math.rotr(u32, v[r.e], @as(u32, 11)) ^
                    math.rotr(u32, v[r.e], @as(u32, 25))) +% (v[r.g] ^ (v[r.e] & (v[r.f] ^ v[r.g]))) +% tab.init_vec_sha2_w[r.i] +% s[r.i];
                v[r.d] = v[r.d] +% v[r.h];
                v[r.h] = v[r.h] +% (math.rotr(u32, v[r.a], @as(u32, 2)) ^
                    math.rotr(u32, v[r.a], @as(u32, 13)) ^
                    math.rotr(u32, v[r.a], @as(u32, 22))) +% ((v[r.a] & (v[r.b] | v[r.c])) | (v[r.b] & v[r.c]));
            }
            sha2.s[0] +%= v[0];
            sha2.s[1] +%= v[1];
            sha2.s[2] +%= v[2];
            sha2.s[3] +%= v[3];
            sha2.s[4] +%= v[4];
            sha2.s[5] +%= v[5];
            sha2.s[6] +%= v[6];
            sha2.s[7] +%= v[7];
        }
        fn write(sha2: *Sha2x32, bytes: []const u8) usize {
            sha2.update(bytes);
            return bytes.len;
        }
    };
}
pub const Sha256oSha256 = GenericComposition(Sha256, Sha256);
pub const Sha224 = GenericSha2x32(.{ .init_vec = tab.init_vec.sha224, .digest_bits = 224 });
pub const Sha256 = GenericSha2x32(.{ .init_vec = tab.init_vec.sha256, .digest_bits = 256 });
