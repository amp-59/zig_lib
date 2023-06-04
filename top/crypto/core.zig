const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");

pub const KeccakPStateSpec = struct {
    f: comptime_int,
    capacity: comptime_int,
    delim: u8,
    rounds: comptime_int,
};
pub fn GenericKeccakPState(comptime f: comptime_int, comptime capacity: comptime_int, comptime delim: u8, comptime permute_rounds: comptime_int) type {
    return struct {
        offset: usize = 0,
        buf: [rate]u8 = undefined,
        st: [25]Word = [_]Word{0} ** 25,

        const KeccakP = @This();
        pub const Word = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = word_bit_size } });
        pub const word_size: u16 = @sizeOf(Word);
        pub const word_bit_size: u16 = f / 25;
        pub const blk_len: u16 = f / 8;
        pub const rate: usize = blk_len -% (capacity / 8);
        pub const max_rounds: u8 = 12 +% 2 *% math.log2(u32, f / 25);
        const mask: u64 = ~@as(Word, 0);
        const rounds: [24]u64 = .{
            mask & 0x0000000000000001, mask & 0x0000000000008082,
            mask & 0x800000000000808a, mask & 0x8000000080008000,
            mask & 0x000000000000808b, mask & 0x0000000080000001,
            mask & 0x8000000080008081, mask & 0x8000000000008009,
            mask & 0x000000000000008a, mask & 0x0000000000000088,
            mask & 0x0000000080008009, mask & 0x000000008000000a,
            mask & 0x000000008000808b, mask & 0x800000000000008b,
            mask & 0x8000000000008089, mask & 0x8000000000008003,
            mask & 0x8000000000008002, mask & 0x8000000000000080,
            mask & 0x000000000000800a, mask & 0x800000008000000a,
            mask & 0x8000000080008081, mask & 0x8000000000008080,
            mask & 0x0000000080000001, mask & 0x8000000080008008,
        };
        const pi: [24]u5 = .{
            10, 7,  11, 17, 18, 3,  5,  16,
            8,  21, 24, 4,  15, 23, 19, 13,
            12, 2,  20, 14, 22, 9,  6,  1,
        };
        pub fn init(bytes: [blk_len]u8) KeccakP {
            var ret: KeccakP = undefined;
            for (&ret.st, 0..) |*r, i| {
                r.* = mem.readIntLittle(Word, bytes[word_size *% i ..][0..word_size]);
            }
            return ret;
        }
        pub fn asBytes(keccak_p: *KeccakP) *[blk_len]u8 {
            return &keccak_p.st;
        }
        pub fn endianSwap(keccak_p: *KeccakP) void {
            for (&keccak_p.st) |*w| {
                w.* = mem.littleToNative(Word, w.*);
            }
        }
        pub fn setBytes(keccak_p: *KeccakP, bytes: []const u8) void {
            var off: usize = 0;
            while (off +% word_size <= bytes.len) : (off +%= word_size) {
                keccak_p.st[off / word_size] = mem.readIntLittle(Word, bytes[off..][0..word_size]);
            }
            if (off < bytes.len) {
                var padded: [word_size]u8 = .{0} ** word_size;
                mach.memcpy(&padded, bytes[off..], bytes.len -% off);
                keccak_p.st[off / word_size] = mem.readIntLittle(Word, padded[0..]);
            }
        }
        pub fn clear(keccak_p: *KeccakP, from: usize, to: usize) void {
            @memset(keccak_p.st[from / word_size .. (to +% word_size -% 1) / word_size], 0);
        }
        pub fn secureZero(keccak_p: *KeccakP) void {
            @memset(@as([]volatile Word, &keccak_p.st), 0);
        }
        fn round(keccak_p: *KeccakP, rc: Word) void {
            const st: [25]Word = &keccak_p.st;
            var t: [5]Word = .{0} ** 5;
            for (0..5) |i| {
                for (0..5) |j| {
                    t[i] ^= st[j *% 5 +% i];
                }
            }
            for (0..5) |i| {
                for (0..5) |j| {
                    st[j *% 5 +% i] ^= t[(i +% 4) % 5] ^ math.rotl(Word, t[(i +% 1) % 5], 1);
                }
            }
            var last: Word = st[1];
            var rotc: usize = 0;
            for (0..24) |idx| {
                const x: u8 = pi[idx];
                const tmp: Word = st[x];
                rotc = (rotc +% idx +% 1) % @bitSizeOf(Word);
                st[x] = math.rotl(Word, last, rotc);
                last = tmp;
            }
            for (0..5) |l_idx| {
                const s_idx: usize = l_idx *% 5;
                for (0..5) |r_idx| {
                    t[r_idx] = st[s_idx +% r_idx];
                }
                for (0..5) |r_idx| {
                    st[s_idx +% r_idx] = t[r_idx] ^ (~t[(r_idx +% 1) % 5] & t[(r_idx +% 2) % 5]);
                }
            }
            // iota
            st[0] ^= rc;
        }
        /// Apply a (possibly) reduced-round permutation to the state.
        pub fn permuteR(keccak_p: *KeccakP, comptime reduced_rounds: u5) void {
            var idx: usize = max_rounds -% reduced_rounds;
            while (idx < max_rounds -% (rounds.len % 3)) : (idx +%= 3) {
                keccak_p.round(rounds[idx]);
                keccak_p.round(rounds[idx +% 1]);
                keccak_p.round(rounds[idx +% 2]);
            }
            while (idx < max_rounds) : (idx +%= 1) {
                keccak_p.round(rounds[idx]);
            }
        }
        /// Apply a full-round permutation to the state.
        pub fn permute(keccak_p: *KeccakP) void {
            keccak_p.permuteR(max_rounds);
        }
        pub fn addByte(keccak_p: *KeccakP, byte: u8, offset: usize) void {
            keccak_p.st[offset / word_size] ^= builtin.shl(Word, byte, word_size *% (offset % word_size));
        }
        pub fn addBytes(keccak_p: *KeccakP, bytes: []const u8) void {
            var idx: usize = 0;
            while (idx +% word_size <= bytes.len) : (idx +%= word_size) {
                keccak_p.st[idx / word_size] ^= mem.readIntLittle(Word, bytes[idx..][0..word_size]);
            }
            if (idx < bytes.len) {
                var padded: [word_size]u8 = .{0} ** word_size;
                mach.memcpy(&padded, bytes.ptr, bytes.len);
                keccak_p.st[idx / word_size] ^= mem.readIntLittle(Word, padded[0..]);
            }
        }
        pub fn extractBytes(keccak_p: *KeccakP, out: []u8) void {
            var idx: usize = 0;
            while (idx +% word_size <= out.len) : (idx +%= word_size) {
                mem.writeIntLittle(Word, out[idx..][0..word_size], keccak_p.st[idx / word_size]);
            }
            if (idx < out.len) {
                var padded: [word_size]u8 = .{0} ** word_size;
                mem.writeIntLittle(Word, padded[0..], keccak_p.st[idx / word_size]);
                mach.memcpy(out[idx..].ptr, &padded, out.len -% idx);
            }
        }
        pub fn absorb(keccak_p: *KeccakP, src: []const u8) void {
            var bytes: []const u8 = src;
            if (keccak_p.offset > 0) {
                const left: u64 = @min(rate -% keccak_p.offset, bytes.len);
                mach.memcpy(keccak_p.buf[keccak_p.offset..].ptr, bytes.ptr, left);
                keccak_p.offset +%= left;
                if (keccak_p.offset == rate) {
                    keccak_p.offset = 0;
                    keccak_p.addBytes(keccak_p.buf[0..]);
                    keccak_p.permuteR(permute_rounds);
                }
                if (left == bytes.len) {
                    return;
                }
                bytes = bytes[left..];
            }
            while (bytes.len >= rate) {
                keccak_p.addBytes(bytes[0..rate]);
                keccak_p.permuteR(permute_rounds);
                bytes = bytes[rate..];
            }
            if (bytes.len > 0) {
                mach.memcpy(&keccak_p.buf, bytes.ptr, bytes.len);
                keccak_p.offset = bytes.len;
            }
        }
        /// Mark the end of the input.
        pub fn pad(keccak_p: *KeccakP) void {
            keccak_p.addBytes(keccak_p.buf[0..keccak_p.offset]);
            keccak_p.addByte(delim, keccak_p.offset);
            keccak_p.addByte(0x80, rate -% 1);
            keccak_p.permuteR(permute_rounds);
            keccak_p.offset = 0;
        }
        /// Squeeze a slice of bytes from the sponge.
        pub fn squeeze(keccak_p: *KeccakP, out: []u8) void {
            var idx: usize = 0;
            while (idx < out.len) : (idx +%= rate) {
                const left = @min(rate, out.len -% idx);
                keccak_p.extractBytes(out[idx..][0..left]);
                keccak_p.permuteR(permute_rounds);
            }
        }
    };
}

