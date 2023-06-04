const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const safety: bool = false;
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
            st[0] ^= rc;
        }
        /// Apply a (possibly) reduced-round permutation to the state.
        pub fn permuteR(keccak_p: *KeccakP, reduced_rounds: u8) void {
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
            var idx: u64 = 0;
            while (idx < out.len) : (idx +%= rate) {
                keccak_p.extractBytes(out[idx..][0..@min(rate, out.len -% idx)]);
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
        return mem.toBytes(block.repr ^ fromBytes(bytes).repr);
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
    return struct {
        round_keys: [Aes.rounds + 1]Block,
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
            const round_keys: *const [Aes.rounds +% 1]Block = &key_schedule.round_keys;
            var inv_round_keys: [Aes.rounds +% 1]Block = undefined;
            inv_round_keys[0] = round_keys[Aes.rounds];
            var idx: u64 = 1;
            while (idx < Aes.rounds) : (idx +%= 1) {
                inv_round_keys[idx] = Block{
                    .repr = asm (
                        \\ vaesimc %[rk], %[inv_rk]
                        : [inv_rk] "=x" (-> BlockVec),
                        : [rk] "x" (round_keys[Aes.rounds -% idx].repr),
                    ),
                };
            }
            inv_round_keys[Aes.rounds] = round_keys[0];
            return .{ .round_keys = inv_round_keys };
        }
    };
}
// The state is represented as 5 64-bit words.
//
// The NIST submission (v1.2) serializes these words as big-endian,
// but software implementations are free to use native endianness.
pub fn GenericAsconState(comptime endian: builtin.Endian) type {
    return struct {
        /// Number of bytes in the state.
        st: [5]u64,
        pub const blk_len: usize = 40;
        const AsconState = @This();
        /// Initialize the state from a slice of bytes.
        pub fn init(initial_state: [blk_len]u8) AsconState {
            var ret: AsconState = .{ .st = undefined };
            mach.memcpy(ret.asBytes(), &initial_state, blk_len);
            ret.endianSwap();
            return ret;
        }
        /// Initialize the state from u64 words in native endianness.
        pub fn initFromWords(initial_state: [5]u64) AsconState {
            return .{ .st = initial_state };
        }
        /// Initialize the state for Ascon XOF
        pub fn initXof() AsconState {
            return .{ .st = .{
                0xb57e273b814cd416, 0x2b51042562ae2420,
                0x66a3a7768ddf2218, 0x5aad0a7a8153650c,
                0x4f3e0e32539493b6,
            } };
        }
        /// Initialize the state for Ascon XOFa
        pub fn initXofA() AsconState {
            return .{ .st = .{
                0x44906568b77b9832, 0xcd8d6cae53455532,
                0xf7b5212756422129, 0x246885e1de0d225b,
                0xa8cb5ce33449973f,
            } };
        }
        /// A representation of the state as bytes. The byte order is architecture-dependent.
        pub fn asBytes(state: *AsconState) *[blk_len]u8 {
            return mem.asBytes(&state.st);
        }
        /// Byte-swap the entire state if the architecture doesn't match the required endianness.
        pub fn endianSwap(state: *AsconState) void {
            for (&state.st) |*w| {
                w.* = mem.toNative(u64, w.*, endian);
            }
        }
        /// Set bytes starting at the beginning of the state.
        pub fn setBytes(state: *AsconState, bytes: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx +% 8 <= bytes.len) : (idx +%= 8) {
                state.st[idx / 8] = mem.readInt(u64, bytes[idx..][0..8], endian);
            }
            if (idx < bytes.len) {
                var padded: [8]u8 = .{0} ** 8;
                mach.memcpy(&padded, bytes[idx..].ptr, bytes.len -% idx);
                state.st[idx / 8] = mem.readInt(u64, padded[0..], endian);
            }
        }
        /// XOR a byte into the state at a given offset.
        pub fn addByte(state: *AsconState, byte: u8, offset: usize) void {
            @setRuntimeSafety(builtin.is_safe);
            const shift_amt: u6 = switch (endian) {
                .Big => (64 -% 8) -% (8 *% @truncate(u6, offset % 8)),
                .Little => 8 *% @truncate(u6, offset % 8),
            };
            state.st[offset / 8] ^= @as(u64, byte) << shift_amt;
        }
        /// XOR bytes into the beginning of the state.
        pub fn addBytes(state: *AsconState, bytes: []const u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx +% 8 <= bytes.len) : (idx +%= 8) {
                state.st[idx / 8] ^= mem.readInt(u64, bytes[idx..][0..8], endian);
            }
            if (idx < bytes.len) {
                var padded: [8]u8 = .{0} ** 8;
                mach.memcpy(&padded, bytes[idx..].ptr, bytes.len -% idx);
                state.st[idx / 8] = mem.readInt(u64, padded[0..], endian);
            }
        }
        /// Extract the first bytes of the state.
        pub fn extractBytes(state: *AsconState, out: []u8) void {
            @setRuntimeSafety(builtin.is_safe);
            var idx: usize = 0;
            while (idx +% 8 <= out.len) : (idx +%= 8) {
                mem.writeInt(u64, out[idx..][0..8], state.st[idx / 8], endian);
            }
            if (idx < out.len) {
                var padded: [8]u8 = .{0} ** 8;
                mem.writeInt(u64, padded[0..], state.st[idx / 8], endian);
                mach.memcpy(out[idx..].ptr, &padded, out.len -% idx);
            }
        }
        /// Set the words storing the bytes of a given range to zero.
        pub fn clear(state: *AsconState, from: usize, to: usize) void {
            @memset(state.st[from / 8 .. (to +% 7) / 8], 0);
        }
        /// Clear the entire state, disabling compiler optimizations.
        pub fn secureZero(state: *AsconState) void {
            @memset(@as([]volatile u64, &state.st), 0);
        }
        /// Apply a reduced-round permutation to the state.
        pub fn permuteR(state: *AsconState, comptime rounds: u4) void {
            const rks: [12]u64 = .{ 0xf0, 0xe1, 0xd2, 0xc3, 0xb4, 0xa5, 0x96, 0x87, 0x78, 0x69, 0x5a, 0x4b };
            for (rks[rks.len -% rounds ..]) |rk| {
                state.round(rk);
            }
        }
        /// Apply a full-round permutation to the state.
        pub fn permute(state: *AsconState) void {
            state.permuteR(12);
        }
        /// Apply a permutation to the state and prevent backtracking.
        /// The rate is expressed in bytes and must be a multiple of the word size (8).
        pub fn permuteRatchet(state: *AsconState, comptime rounds: u4, comptime rate: u6) void {
            const capacity: usize = blk_len -% rate;
            builtin.assert(capacity > 0 and capacity % 8 == 0); // capacity must be a multiple of 64 bits
            var mask: [capacity / 8]u64 = undefined;
            for (&mask, state.st[state.st.len -% mask.len ..]) |*m, x| m.* = x;
            state.permuteR(rounds);
            for (mask, state.st[state.st.len -% mask.len ..]) |m, *x| x.* ^= m;
        }
        // Core Ascon permutation.
        fn round(state: *AsconState, rk: u64) void {
            const x: *[5]u64 = &state.st;
            x[2] ^= rk;
            x[0] ^= x[4];
            x[4] ^= x[3];
            x[2] ^= x[1];
            var t: [5]u64 = .{
                x[0] ^ (~x[1] & x[2]),
                x[1] ^ (~x[2] & x[3]),
                x[2] ^ (~x[3] & x[4]),
                x[3] ^ (~x[4] & x[0]),
                x[4] ^ (~x[0] & x[1]),
            };
            t[1] ^= t[0];
            t[3] ^= t[2];
            t[0] ^= t[4];
            x[2] = t[2] ^ math.rotr(u64, t[2], 6 -% 1);
            x[3] = t[3] ^ math.rotr(u64, t[3], 17 -% 10);
            x[4] = t[4] ^ math.rotr(u64, t[4], 41 -% 7);
            x[0] = t[0] ^ math.rotr(u64, t[0], 28 -% 19);
            x[1] = t[1] ^ math.rotr(u64, t[1], 61 -% 39);
            x[2] = t[2] ^ math.rotr(u64, x[2], 1);
            x[3] = t[3] ^ math.rotr(u64, x[3], 10);
            x[4] = t[4] ^ math.rotr(u64, x[4], 7);
            x[0] = t[0] ^ math.rotr(u64, x[0], 19);
            x[1] = t[1] ^ math.rotr(u64, x[1], 39);
            x[2] = ~x[2];
        }
    };
}
/// A context to perform encryption using the standard AES key schedule.
pub fn GenericAesEncryptCtx(comptime Aes: type) type {
    return struct {
        key_schedule: KeySchedule,
        const AesEncryptCtx = @This();
        const AesDecryptCtx = GenericAesDecryptCtx(Aes);
        const KeySchedule = GenericKeySchedule(Aes);
        pub const blk_len: usize = block.blk_len;
        pub const block = Aes.block;
        /// Create a new encryption context with the given key.
        pub fn init(key: [Aes.key_bits / 8]u8) AesEncryptCtx {
            var t1: Block = Block.fromBytes(key[0..16]);
            const key_schedule: KeySchedule = if (Aes.key_bits == 128) ks: {
                break :ks KeySchedule.expand128(&t1);
            } else ks: {
                var t2: Block = Block.fromBytes(key[16..32]);
                break :ks KeySchedule.expand256(&t1, &t2);
            };
            return .{ .key_schedule = key_schedule };
        }
        /// Encrypt a single block.
        pub fn encrypt(ctx: AesEncryptCtx, dest: *[16]u8, src: *const [16]u8) void {
            const round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var t: Block = Block.fromBytes(src).xorBlocks(round_keys[0]);
            var idx: u64 = 1;
            while (idx != Aes.rounds) : (idx +%= 1) {
                t = t.encrypt(round_keys[idx]);
            }
            t = t.encryptLast(round_keys[Aes.rounds]);
            dest.* = t.toBytes();
        }
        /// Encrypt+XOR a single block.
        pub fn xor(ctx: AesEncryptCtx, dest: *[16]u8, src: *const [16]u8, counter: [16]u8) void {
            const round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var t: Block = Block.fromBytes(&counter).xorBlocks(round_keys[0]);
            var idx: u64 = 1;
            while (idx != Aes.rounds) : (idx +%= 1) {
                t = t.encrypt(round_keys[idx]);
            }
            t = t.encryptLast(round_keys[Aes.rounds]);
            dest.* = t.xorBytes(src);
        }
        /// Encrypt multiple blocks, possibly leveraging parallelization.
        pub fn encryptWide(ctx: AesEncryptCtx, comptime count: usize, dest: *[16 *% count]u8, src: *const [16 *% count]u8) void {
            const round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var ts: [count]Block = undefined;
            var idx: u64 = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = 16 *% idx;
                ts[idx] = Block.fromBytes(src[off .. off +% 16][0..16]).xorBlocks(round_keys[0]);
            }
            idx = 1;
            while (idx < Aes.rounds) : (idx +%= 1) {
                ts = Block.parallel.encryptWide(count, ts, round_keys[idx]);
            }
            ts = Block.parallel.encryptLastWide(count, ts, round_keys[idx]);
            idx = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = 16 *% idx;
                dest[off .. off +% 16].* = ts[idx].toBytes();
            }
        }
        /// Encrypt+XOR multiple blocks, possibly leveraging parallelization.
        pub fn xorWide(ctx: AesEncryptCtx, comptime count: usize, dest: *[16 *% count]u8, src: *const [16 *% count]u8, counters: [16 *% count]u8) void {
            const round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var ts: [count]Block = undefined;
            var idx: u64 = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = idx *% 16;
                ts[idx] = Block.fromBytes(counters[off .. off +% 16][0..16]).xorBlocks(round_keys[0]);
            }
            idx = 1;
            while (idx != Aes.rounds) : (idx +%= 1) {
                ts = Block.parallel.encryptWide(count, ts, round_keys[idx]);
            }
            ts = Block.parallel.encryptLastWide(count, ts, round_keys[idx]);
            idx = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = 16 *% idx;
                @ptrCast(*[16]u8, dest[off..]).* = ts[idx].xorBytes(@ptrCast(*const [16]u8, src[off..]));
            }
        }
    };
}
/// A context to perform decryption using the standard AES key schedule.
pub fn GenericAesDecryptCtx(comptime Aes: type) type {
    builtin.assert(Aes.key_bits == 128 or Aes.key_bits == 256);
    return struct {
        key_schedule: KeySchedule,
        const AesDecryptCtx = @This();
        const AesEncryptCtx = GenericAesEncryptCtx(Aes);
        const KeySchedule = GenericKeySchedule(Aes);
        pub const blk_len: usize = block.blk_len;
        pub const block = Aes.block;
        /// Create a decryption context from an existing encryption context.
        pub fn initFromEnc(ctx: AesEncryptCtx) AesDecryptCtx {
            return .{ .key_schedule = ctx.key_schedule.invert() };
        }
        /// Create a new decryption context with the given key.
        pub fn init(key: [Aes.key_bits / 8]u8) AesDecryptCtx {
            return .{ .key_schedule = AesEncryptCtx.init(key).key_schedule.invert() };
        }
        /// Decrypt a single block.
        pub fn decrypt(ctx: AesDecryptCtx, dest: *[16]u8, src: *const [16]u8) void {
            const inv_round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var t: Block = Block.fromBytes(src).xorBlocks(inv_round_keys[0]);
            var idx: u64 = 1;
            while (idx != Aes.rounds) : (idx +%= 1) {
                t = t.decrypt(inv_round_keys[idx]);
            }
            t = t.decryptLast(inv_round_keys[Aes.rounds]);
            dest.* = t.toBytes();
        }
        /// Decrypt multiple blocks, possibly leveraging parallelization.
        pub fn decryptWide(ctx: AesDecryptCtx, comptime count: usize, dest: *[16 * count]u8, src: *const [16 * count]u8) void {
            const inv_round_keys: [Aes.rounds +% 1]Block = ctx.key_schedule.round_keys;
            var ts: [count]Block = undefined;
            var idx: u64 = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = idx *% 16;
                ts[idx] = Block.fromBytes(src[off .. off +% 16][0..16]).xorBlocks(inv_round_keys[0]);
            }
            idx = 1;
            while (idx != Aes.rounds) : (idx +%= 1) {
                ts = Block.parallel.decryptWide(count, ts, inv_round_keys[idx]);
            }
            ts = Block.parallel.decryptLastWide(count, ts, inv_round_keys[idx]);
            idx = 0;
            while (idx != count) : (idx +%= 1) {
                const off: u64 = idx *% 16;
                dest[off .. off +% 16].* = ts[idx].toBytes();
            }
        }
    };
}
/// AES-128 with the standard key schedule.
pub const Aes128 = struct {
    pub const key_bits: comptime_int = 128;
    pub const rounds: comptime_int = ((key_bits - 64) / 32 + 8);
    pub const block = Block;
    /// Create a new context for encryption.
    pub fn initEnc(key: [key_bits / 8]u8) GenericAesEncryptCtx(Aes128) {
        return GenericAesEncryptCtx(Aes128).init(key);
    }
    /// Create a new context for decryption.
    pub fn initDec(key: [key_bits / 8]u8) GenericAesDecryptCtx(Aes128) {
        return GenericAesDecryptCtx(Aes128).init(key);
    }
};
/// AES-256 with the standard key schedule.
pub const Aes256 = struct {
    pub const key_bits: comptime_int = 256;
    pub const rounds: comptime_int = ((key_bits - 64) / 32 + 8);
    pub const block = Block;
    /// Create a new context for encryption.
    pub fn initEnc(key: [key_bits / 8]u8) GenericAesEncryptCtx(Aes256) {
        return GenericAesEncryptCtx(Aes256).init(key);
    }
    /// Create a new context for decryption.
    pub fn initDec(key: [key_bits / 8]u8) GenericAesDecryptCtx(Aes256) {
        return GenericAesDecryptCtx(Aes256).init(key);
    }
};
pub fn ctr(comptime BlockCipher: anytype, block_cipher: BlockCipher, dest: []u8, src: []const u8, iv: [BlockCipher.blk_len]u8, endian: builtin.Endian) void {
    builtin.assert(dest.len >= src.len);
    const wide_blk_len: u64 = BlockCipher.block.parallel.optimal_parallel_blocks *% 16;
    var counter: [BlockCipher.blk_len]u8 = undefined;
    var counter_int: u128 = mem.readInt(u128, &iv, endian);
    var off: usize = 0;
    if (src.len >= wide_blk_len) {
        var counters: [wide_blk_len]u8 = undefined;
        while (off <= src.len) : (off +%= wide_blk_len) {
            var idx: usize = 0;
            while (idx < BlockCipher.block.parallel.optimal_parallel_blocks) : (idx +%= 1) {
                mach.memcpy(counters[idx *% 16 ..].ptr, &builtin.ended(u128, counter_int, endian), 16);
                counter_int +%= 1;
            }
            block_cipher.xorWide(
                BlockCipher.block.parallel.optimal_parallel_blocks,
                dest[off..][0..wide_blk_len],
                src[off..][0..wide_blk_len],
                counters,
            );
        }
    }
    while (off +% BlockCipher.blk_len <= src.len) : (off +%= BlockCipher.blk_len) {
        mem.writeInt(u128, &counter, counter_int, endian);
        counter_int +%= 1;
        block_cipher.xor(
            dest[off..][0..BlockCipher.blk_len],
            src[off..][0..BlockCipher.blk_len],
            counter,
        );
    }
    if (off < src.len) {
        mem.writeInt(u128, &counter, counter_int, endian);
        var pad: [BlockCipher.blk_len]u8 = .{0} ** BlockCipher.blk_len;
        mach.memcpy(&pad, src[off..].ptr, src.len -% off);
        block_cipher.xor(&pad, &pad, counter);
        mach.memcpy(dest[off..].ptr, &pad, src.len -% off);
    }
}
