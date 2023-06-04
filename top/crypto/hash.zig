const mem = @import("../mem.zig");
const math = @import("../math.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const tab = @import("./tab.zig");
const core = @import("./core.zig");
pub const Blake2s128 = GenericBlake2s(128);
pub const Blake2s160 = GenericBlake2s(160);
pub const Blake2s224 = GenericBlake2s(224);
pub const Blake2s256 = GenericBlake2s(256);
pub const Blake2b128 = GenericBlake2b(128);
pub const Blake2b160 = GenericBlake2b(160);
pub const Blake2b256 = GenericBlake2b(256);
pub const Blake2b384 = GenericBlake2b(384);
pub const Blake2b512 = GenericBlake2b(512);
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
            mach.memset(blake_2s.buf[blake_2s.buf_len..].ptr, 0, blake_2s.buf.len -% blake_2s.buf_len);
            blake_2s.t +%= blake_2s.buf_len;
            blake_2s.round(blake_2s.buf[0..], true);
            for (&blake_2s.h) |*x| x.* = mem.nativeToLittle(u32, x.*);
            mach.memcpy(dest.ptr, @ptrCast([*]u8, &blake_2s.h), 32);
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
        pub fn final(blake_2b: *Blake2b, dest: []u8) void {
            const buf: []u8 = blake_2b.buf[blake_2b.buf_len..];
            mach.memset(buf.ptr, 0, buf.len);
            blake_2b.t +%= blake_2b.buf_len;
            blake_2b.round(blake_2b.buf[0..], true);
            for (&blake_2b.h) |*x| x.* = mem.nativeToLittle(u64, x.*);
            mach.memcpy(dest.ptr, @ptrCast([*]u8, &blake_2b.h), 64);
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
/// An incremental hasher that can accept any number of writes.
pub const Blake3 = struct {
    chunk_state: ChunkState,
    key: [8]u32,
    cv_stack: [54][8]u32 = undefined, // Space for 54 subtree chaining values:
    cv_stack_len: u8 = 0, // 2^54 * buf_len: u64 = 2^64
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
                .buf = buf_len,
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
    const compress = if (builtin.config.zig.cpu.arch == .x86_64)
        CompressVectorized.compress
    else
        CompressGeneric.compress;
    fn first8Words(words: [16]u32) [8]u32 {
        return @ptrCast(*const [8]u32, &words).*;
    }
    fn wordsFromLittleEndianBytes(comptime count: usize, bytes: [count * 4]u8) [count]u32 {
        var words: [count]u32 = undefined;
        for (&words, 0..) |*word, i| {
            word.* = mem.readIntSliceLittle(u32, bytes[4 * i ..]);
        }
        return words;
    }
    // Each chunk or parent node can produce either an 8-word chaining value or, by
    // setting the ROOT flag, any number of final output bytes. The Output struct
    // captures the state just prior to choosing between those two possibilities.
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
                var words = compress(output.input_chaining_value, output.block_words, output.block_len, output_block_counter, output.flags | root);
                var out_word_itr: ChunkIterator = .{ .buf = out_block, .buf_len = 4 };
                var word_counter: usize = 0;
                while (out_word_itr.next()) |out_word| {
                    var word_bytes: [4]u8 = undefined;
                    mem.writeIntLittle(u32, &word_bytes, words[word_counter]);
                    mach.memcpy(out_word.ptr, &word_bytes, out_word.len);
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
            return ChunkState{
                .chaining_value = key,
                .chunk_counter = chunk_counter,
                .flags = flags,
            };
        }
        fn len(st: *const ChunkState) usize {
            return blk_len * @as(usize, st.blocks_compressed) +% @as(usize, st.block_len);
        }
        fn fillBlockBuf(st: *ChunkState, input: []const u8) []const u8 {
            const want: u64 = blk_len -% st.block_len;
            const take: u64 = @min(want, input.len);
            mach.memcpy(st.block[st.block_len..].ptr, input.ptr, take);
            st.block_len +%= @truncate(u8, take);
            return input[take..];
        }
        fn startFlag(st: *const ChunkState) u8 {
            return if (st.blocks_compressed == 0) chunk_start else 0;
        }
        fn update(st: *ChunkState, src: []const u8) void {
            var bytes: []const u8 = src;
            while (bytes.len > 0) {
                // If the block buffer is full, compress it and clear it. More
                // input is coming, so this compression is not CHUNK_END.
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
                // Copy input bytes into the block buffer.
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
            .block_len = blk_len, // Always blk_len (64) for parent nodes.
            .counter = 0, // Always 0 for parent nodes.
            .flags = parent | flags,
        };
    }
    fn parentCv(left_child_cv: [8]u32, right_child_cv: [8]u32, key: [8]u32, flags: u8) [8]u32 {
        return parentOutput(left_child_cv, right_child_cv, key, flags).chainingValue();
    }
    fn init_internal(key: [8]u32, flags: u8) Blake3 {
        return Blake3{ .chunk_state = ChunkState.init(key, 0, flags), .key = key, .flags = flags };
    }
    /// Construct a new `Blake3` for the hash function, with an optional key
    pub fn init(options: Options) Blake3 {
        if (options.key) |key| {
            const key_words: [8]u32 = wordsFromLittleEndianBytes(8, key);
            return Blake3.init_internal(key_words, keyed_hash);
        } else {
            return Blake3.init_internal(tab.init_vec.blake_3, 0);
        }
    }
    /// Construct a new `Blake3` for the key derivation function. The context
    /// string should be hardcoded, globally unique, and application-specific.
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
    // Section 5.1.2 of the BLAKE3 spec explains this algorithm in more detail.
    fn addChunkChainingValue(blake_3: *Blake3, first_cv: [8]u32, total_chunks: u64) void {
        // This chunk might complete some subtrees. For each completed subtree,
        // its left child will be the current top entry in the CV stack, and
        // its right child will be the current value of `new_cv`. Pop each left
        // child off the stack, merge it with `new_cv`, and overwrite `new_cv`
        // with the result. After all these merges, push the final value of
        // `new_cv` onto the stack. The number of completed subtrees is given
        // by the number of trailing 0-bits in the new total number of chunks.
        var new_cv: [8]u32 = first_cv;
        var chunk_counter: u64 = total_chunks;
        while (chunk_counter & 1 == 0) {
            new_cv = parentCv(blake_3.popCv(), new_cv, blake_3.key, blake_3.flags);
            chunk_counter >>= 1;
        }
        blake_3.pushCv(new_cv);
    }
    /// Add input to the hash state. This can be called any number of times.
    pub fn update(blake_3: *Blake3, src: []const u8) void {
        var bytes: []const u8 = src;
        while (bytes.len > 0) {
            // If the current chunk is complete, finalize it and reset the
            // chunk state. More input is coming, so this chunk is not ROOT.
            if (blake_3.chunk_state.len() == chunk_len) {
                const chunk_cv: [8]u32 = blake_3.chunk_state.output().chainingValue();
                const total_chunks: u64 = blake_3.chunk_state.chunk_counter +% 1;
                blake_3.addChunkChainingValue(chunk_cv, total_chunks);
                blake_3.chunk_state = ChunkState.init(blake_3.key, total_chunks, blake_3.flags);
            }
            // Compress input bytes into the current chunk state.
            const want: u64 = chunk_len -% blake_3.chunk_state.len();
            const take: usize = @min(want, bytes.len);
            blake_3.chunk_state.update(bytes[0..take]);
            bytes = bytes[take..];
        }
    }
    /// Finalize the hash and write any number of output bytes.
    pub fn final(blake_3: *const Blake3, dest: []u8) void {
        // Starting with the Output from the current chunk, compute all the
        // parent chaining values along the right edge of the tree, until we
        // have the root Output.
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
pub const CompressVectorized = struct {
    const Lane = @Vector(4, u32);
    const Rows = [4]Lane;
    fn g(even: bool, rows: *Rows, m: Lane) void {
        rows[0] +%= rows[1] +% m;
        rows[3] ^= rows[0];
        rows[3] = math.rotr(Lane, rows[3], mach.cmov8(even, 8, 16));
        rows[2] +%= rows[3];
        rows[1] ^= rows[2];
        rows[1] = math.rotr(Lane, rows[1], mach.cmov8(even, 7, 12));
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
        const md: Lane = .{ @truncate(u32, counter), @truncate(u32, counter >> 32), block_len, @as(u32, flags) };
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
        return @bitCast([16]u32, rows);
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
        // Mix the columns.
        g(state, 0, 4, 8, 12, msg[schedule[0]], msg[schedule[1]]);
        g(state, 1, 5, 9, 13, msg[schedule[2]], msg[schedule[3]]);
        g(state, 2, 6, 10, 14, msg[schedule[4]], msg[schedule[5]]);
        g(state, 3, 7, 11, 15, msg[schedule[6]], msg[schedule[7]]);
        // Mix the diagonals.
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
            chaining_value[0],       chaining_value[1],
            chaining_value[2],       chaining_value[3],
            chaining_value[4],       chaining_value[5],
            chaining_value[6],       chaining_value[7],
            tab.init_vec.blake_3[0], tab.init_vec.blake_3[1],
            tab.init_vec.blake_3[2], tab.init_vec.blake_3[3],
            @truncate(u32, counter), @truncate(u32, counter >> 32),
            block_len,               flags,
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
        @setRuntimeSafety(builtin.is_safe);
        var off: usize = 0;
        if (md5.buf_len != 0 and md5.buf_len +% bytes.len >= 64) {
            off +%= 64 -% md5.buf_len;
            mach.memcpy(md5.buf[md5.buf_len..].ptr, bytes.ptr, off);
            md5.round(&md5.buf);
            md5.buf_len = 0;
        }
        while (off +% 64 <= bytes.len) : (off +%= 64) {
            md5.round(bytes[off..][0..64]);
        }
        const rem: []const u8 = bytes[off..];
        mach.memcpy(md5.buf[md5.buf_len..].ptr, rem.ptr, rem.len);
        md5.buf_len +%= @intCast(u8, rem.len);
        md5.total_len +%= bytes.len;
    }
    pub fn final(md5: *Md5, dest: []u8) void {
        @setRuntimeSafety(builtin.is_safe);
        mach.memset(md5.buf[md5.buf_len..].ptr, 0, md5.buf.len -% md5.buf_len);
        md5.buf[md5.buf_len] = 0x80;
        md5.buf_len +%= 1;
        if (64 -% md5.buf_len < 8) {
            md5.round(&md5.buf);
            mach.memset(&md5.buf, 0, 64);
        }
        var idx: usize = 1;
        var off: u64 = md5.total_len >> 5;
        md5.buf[56] = @intCast(u8, md5.total_len & 0x1f) << 3;
        while (idx < 8) : (idx +%= 1) {
            md5.buf[56 +% idx] = @intCast(u8, off & 0xff);
            off >>= 8;
        }
        md5.round(md5.buf[0..]);
        for (md5.s, 0..) |s, j| {
            mem.writeIntLittle(u32, dest[4 * j ..][0..4], s);
        }
    }
    fn round(md5: *Md5, bytes: *const [64]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var s: [16]u32 = undefined;
        var idx: usize = 0;
        while (idx < 16) : (idx +%= 1) {
            s[idx] = 0;
            s[idx] |= @as(u32, bytes[idx * 4 +% 0]);
            s[idx] |= @as(u32, bytes[idx * 4 +% 1]) << 8;
            s[idx] |= @as(u32, bytes[idx * 4 +% 2]) << 16;
            s[idx] |= @as(u32, bytes[idx * 4 +% 3]) << 24;
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
