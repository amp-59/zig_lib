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
                const left: usize = @min(rate -% keccak_p.offset, bytes.len);
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

const BlockVec = @Vector(2, u64);
/// A single AES block.
pub const Block = struct {
    /// Internal representation of a block.
    repr: BlockVec,
    const Pointer = @Type(.{ .Pointer = .{
        .size = .One,
        .is_const = true,
        .is_volatile = false,
        .is_allowzero = false,
        .alignment = 1,
        .address_space = .generic,
        .child = BlockVec,
        .sentinel = null,
    } });
    pub const blk_len: usize = @sizeOf(BlockVec);
    /// Convert a byte sequence into an internal representation.
    pub fn fromBytes(bytes: *const [16]u8) Block {
        return Block{ .repr = @ptrCast(Pointer, bytes).* };
    }
    /// Convert the internal representation of a block into a byte sequence.
    pub fn toBytes(block: Block) [16]u8 {
        return mem.toBytes(block.repr);
    }
    /// XOR the block with a byte sequence.
    pub fn xorBytes(block: Block, bytes: *const [16]u8) [16]u8 {
        const x = block.repr ^ fromBytes(bytes).repr;
        return mem.toBytes(x);
    }
    /// Encrypt a block with a round key.
    pub fn encrypt(block: Block, round_key: Block) Block {
        return Block{
            .repr = asm (
                \\ vaesenc %[rk], %[in], %[out]
                : [out] "=x" (-> BlockVec),
                : [in] "x" (block.repr),
                  [rk] "x" (round_key.repr),
            ),
        };
    }
    /// Encrypt a block with the last round key.
    pub fn encryptLast(block: Block, round_key: Block) Block {
        return Block{
            .repr = asm (
                \\ vaesenclast %[rk], %[in], %[out]
                : [out] "=x" (-> BlockVec),
                : [in] "x" (block.repr),
                  [rk] "x" (round_key.repr),
            ),
        };
    }
    /// Decrypt a block with a round key.
    pub fn decrypt(block: Block, inv_round_key: Block) Block {
        return Block{
            .repr = asm (
                \\ vaesdec %[rk], %[in], %[out]
                : [out] "=x" (-> BlockVec),
                : [in] "x" (block.repr),
                  [rk] "x" (inv_round_key.repr),
            ),
        };
    }
    /// Decrypt a block with the last round key.
    pub fn decryptLast(block: Block, inv_round_key: Block) Block {
        return Block{
            .repr = asm (
                \\ vaesdeclast %[rk], %[in], %[out]
                : [out] "=x" (-> BlockVec),
                : [in] "x" (block.repr),
                  [rk] "x" (inv_round_key.repr),
            ),
        };
    }
    // TODO: Remove usage of these functions, actually inline them.
    pub inline fn xorBlocks(block1: Block, block2: Block) Block {
        return Block{ .repr = block1.repr ^ block2.repr };
    }
    pub inline fn andBlocks(block1: Block, block2: Block) Block {
        return Block{ .repr = block1.repr & block2.repr };
    }
    pub inline fn orBlocks(block1: Block, block2: Block) Block {
        return Block{ .repr = block1.repr | block2.repr };
    }
    // XXX: Remember that almost all of these functions were `inline` in the
    // standard.
    /// Perform operations on multiple blocks in parallel.
    pub const parallel = struct {
        const cpu = @import("std").Target.x86.cpu;
        /// The recommended number of AES encryption/decryption to perform in parallel for the chosen implementation.
        pub const optimal_parallel_blocks = switch (builtin.config.zig.cpu.model) {
            &cpu.westmere => 6,
            &cpu.sandybridge, &cpu.ivybridge => 8,
            &cpu.haswell, &cpu.broadwell => 7,
            &cpu.cannonlake, &cpu.skylake, &cpu.skylake_avx512 => 4,
            &cpu.icelake_client, &cpu.icelake_server, &cpu.tigerlake, &cpu.rocketlake, &cpu.alderlake => 6,
            &cpu.znver1, &cpu.znver2, &cpu.znver3 => 8,
            else => 8,
        };
        pub fn encryptParallel(comptime count: usize, blocks: [count]Block, round_keys: [count]Block) [count]Block {
            var idx: usize = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].encrypt(round_keys[idx]);
            }
            return out;
        }
        pub fn decryptParallel(comptime count: usize, blocks: [count]Block, round_keys: [count]Block) [count]Block {
            var idx: usize = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].decrypt(round_keys[idx]);
            }
            return out;
        }
        pub fn encryptWide(comptime count: usize, blocks: [count]Block, round_key: Block) [count]Block {
            var idx: usize = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].encrypt(round_key);
            }
            return out;
        }
        pub fn decryptWide(comptime count: usize, blocks: [count]Block, round_key: Block) [count]Block {
            var idx: usize = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].decrypt(round_key);
            }
            return out;
        }
        pub fn encryptLastWide(comptime count: usize, blocks: [count]Block, round_key: Block) [count]Block {
            var idx: usize = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].encryptLast(round_key);
            }
            return out;
        }
        pub fn decryptLastWide(comptime count: usize, blocks: [count]Block, round_key: Block) [count]Block {
            var idx: u64 = 0;
            var out: [count]Block = undefined;
            while (idx != count) : (idx +%= 1) {
                out[idx] = blocks[idx].decryptLast(round_key);
            }
            return out;
        }
    };
};
fn GenericKeySchedule(comptime Aes: type) type {
    builtin.assert(Aes.rounds == 10 or Aes.rounds == 14);
    const rounds = Aes.rounds;
    return struct {
        round_keys: [rounds + 1]Block,
        const KeySchedule = @This();
        fn drc(comptime second: bool, comptime rc: u8, t: BlockVec, tx: BlockVec) BlockVec {
            var s: BlockVec = undefined;
            var ts: BlockVec = undefined;
            return asm (
                \\ vaeskeygenassist %[rc], %[t], %[s]
                \\ vpslldq $4, %[tx], %[ts]
                \\ vpxor   %[ts], %[tx], %[r]
                \\ vpslldq $8, %[r], %[ts]
                \\ vpxor   %[ts], %[r], %[r]
                \\ vpshufd %[mask], %[s], %[ts]
                \\ vpxor   %[ts], %[r], %[r]
                : [r] "=&x" (-> BlockVec),
                  [s] "=&x" (s),
                  [ts] "=&x" (ts),
                : [rc] "n" (rc),
                  [t] "x" (t),
                  [tx] "x" (tx),
                  [mask] "n" (@as(u8, if (second) 0xaa else 0xff)),
            );
        }
        fn expand128(t1: *Block) KeySchedule {
            var round_keys: [11]Block = undefined;
            const rcs: [10]u8 = .{ 1, 2, 4, 8, 16, 32, 64, 128, 27, 54 };
            inline for (rcs, 0..) |rc, round| {
                round_keys[round] = t1.*;
                t1.repr = drc(false, rc, t1.repr, t1.repr);
            }
            round_keys[rcs.len] = t1.*;
            return .{ .round_keys = round_keys };
        }
        fn expand256(t1: *Block, t2: *Block) KeySchedule {
            var round_keys: [15]Block = undefined;
            const rcs: [6]u8 = .{ 1, 2, 4, 8, 16, 32 };
            round_keys[0] = t1.*;
            inline for (rcs, 0..) |rc, round| {
                round_keys[round * 2 + 1] = t2.*;
                t1.repr = drc(false, rc, t2.repr, t1.repr);
                round_keys[round * 2 + 2] = t1.*;
                t2.repr = drc(true, rc, t1.repr, t2.repr);
            }
            round_keys[rcs.len * 2 + 1] = t2.*;
            t1.repr = drc(false, 64, t2.repr, t1.repr);
            round_keys[rcs.len * 2 + 2] = t1.*;
            return .{ .round_keys = round_keys };
        }
        /// Invert the key schedule.
        pub fn invert(key_schedule: KeySchedule) KeySchedule {
            const round_keys: *const [rounds +% 1]Block = &key_schedule.round_keys;
            var inv_round_keys: [rounds +% 1]Block = undefined;
            inv_round_keys[0] = round_keys[rounds];
            var idx: u64 = 1;
            while (idx < rounds) : (idx +%= 1) {
                inv_round_keys[idx] = Block{
                    .repr = asm (
                        \\ vaesimc %[rk], %[inv_rk]
                        : [inv_rk] "=x" (-> BlockVec),
                        : [rk] "x" (round_keys[rounds -% idx].repr),
                    ),
                };
            }
            inv_round_keys[rounds] = round_keys[0];
            return .{ .round_keys = inv_round_keys };
        }
    };
}
