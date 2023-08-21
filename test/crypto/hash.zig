const zl = @import("../../zig_lib.zig");
const fmt = zl.fmt;
const mem = zl.mem;
const mach = zl.mach;
const meta = zl.meta;
const proc = zl.proc;
const debug = zl.debug;
const parse = zl.parse;
const crypto = zl.crypto;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;

pub const signal_handlers: debug.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
pub const htest = struct {
    pub fn assertEqualHash(allocator: *mem.SimpleAllocator, comptime Hasher: anytype, expected_hex: [:0]const u8, input: []const u8) !void {
        const hash_buf: []u8 = allocator.allocate(u8, Hasher.len *% 2);
        mach.memset(hash_buf.ptr, 0, hash_buf.len);
        if (meta.fnParams(Hasher.hash).len == 3) {
            Hasher.hash(input, hash_buf[0..Hasher.len], .{});
        } else {
            Hasher.hash(input, hash_buf[0..Hasher.len]);
        }
        try assertEqual(allocator, expected_hex, hash_buf[0..Hasher.len]);
    }
    pub fn assertEqual(allocator: *mem.SimpleAllocator, expected_hex: [:0]const u8, input: []const u8) !void {
        const bytes_buf: []u8 = allocator.allocate(u8, expected_hex.len);
        mach.memset(bytes_buf.ptr, 0, bytes_buf.len);
        for (bytes_buf[0 .. bytes_buf.len / 2], 0..) |*byte, idx| {
            byte.* = parse.ux(u8, expected_hex[2 * idx .. 2 * idx + 2]);
        }
        try testing.expectEqualMany(u8, bytes_buf[0 .. bytes_buf.len / 2], input);
    }
};
fn testSha3224Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_224, "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7", "");
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_224, "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_224, "543e6868e1666c1a643630df77367ae5a62a85070a51c14cbf665cbc", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha3224Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha3_224 = .{};
    var out: [28]u8 = undefined;
    h.final(out[0..]);
    try htest.assertEqual(allocator, "6b4e03423667dbb73b6e15454f0eb1abd4597f9a1b078e3f5b5a6bc7", out[0..]);
    h = .{};
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf", out[0..]);
    h = .{};
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "e642824c3f8cf24ad09234ee7d3c766fc9a3a5168d0c94ad73b46fdf", out[0..]);
}
fn testSha3256Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_256, "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", "");
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_256, "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_256, "916f6061fe879741ca6469b43971dfdb28b1a32dc36cb3254e812be27aad1d18", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha3256Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha3_256 = .{};
    var out: [32]u8 = undefined;
    h.final(out[0..]);
    try htest.assertEqual(allocator, "a7ffc6f8bf1ed76651c14756a061d662f580ff4de43b49fa82d80a4b80f8434a", out[0..]);
    h = .{};
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532", out[0..]);
    h = .{};
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "3a985da74fe225b2045c172d6bd390bd855f086e3e9d525b46bfe24511431532", out[0..]);
}
fn testSha3256AlignedFinal() !void {
    var block: [crypto.hash.Sha3_256.blk_len]u8 = undefined;
    var out: [crypto.hash.Sha3_256.len]u8 = undefined;
    var h: crypto.hash.Sha3_256 = .{};
    h.update(&block);
    h.final(out[0..]);
}
fn testSha3384Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_384, h1, "");
    const h2: [:0]const u8 = "ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_384, h2, "abc");
    const h3: [:0]const u8 = "79407d3b5916b59c3e30b09822974791c313fb9ecc849e406f23592d04f625dc8c709b98b43b3852b337216179aa7fc7";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_384, h3, "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha3384Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha3_384 = .{};
    var out: [48]u8 = undefined;
    const h1: [:0]const u8 = "0c63a75b845e4f7d01107d852e4c2485c51a50aaaa94fc61995e71bbee983a2ac3713831264adb47fb6bd1e058d5f004";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "ec01498288516fc926459f58e2c6ad8df9b473cb0fc08c2596da7cf0e49be4b298d88cea927ac7f539f1edf228376d25";
    h = .{};
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = .{};
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
}
fn testSha3512Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_512, h1, "");
    const h2: [:0]const u8 = "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_512, h2, "abc");
    const h3: [:0]const u8 = "afebb2ef542e6579c50cad06d2e578f9f8dd6881d7dc824d26360feebf18a4fa73e3261122948efcfd492e74e82e2189ed0fb440d187f382270cb455f21dd185";
    try htest.assertEqualHash(allocator, crypto.hash.Sha3_512, h3, "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha3512Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha3_512 = .{};
    var out: [64]u8 = undefined;
    const h1: [:0]const u8 = "a69f73cca23a9ac5c8b567dc185a756e97c982164fe25859e0d1dcc1475c80a615b2123af1f5f94c11e3e9402c3ac558f500199d95b6d3e301758586281dcd26";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "b751850b1a57168a5693cd924b6b096e08f621827444f70d884f5d0240d2712e10e116e9192af3c91a7ec57647e3934057340b4cf408d5a56592f8274eec53f0";
    h = .{};
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = .{};
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
}
fn testSha3512AlignedFinal() !void {
    var block = [_]u8{0} ** crypto.hash.Sha3_512.blk_len;
    var out: [crypto.hash.Sha3_512.len]u8 = undefined;
    var h: crypto.hash.Sha3_512 = .{};
    h.update(&block);
    h.final(out[0..]);
}
fn testKeccak256Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Keccak256, "c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470", "");
    try htest.assertEqualHash(allocator, crypto.hash.Keccak256, "4e03657aea45a94fc7d47ba826c8d667c0d1e6e33a64a036ec44f58fa12d6c45", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Keccak256, "f519747ed599024f3882238e5ab43960132572b7345fbeb9a90769dafd21ad67", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testKeccak512Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Keccak512, "0eab42de4c3ceb9235fc91acffe746b29c29a8c366b7c60e4e67c466f36a4304c00fa9caf9d87976ba469bcbe06713b435f091ef2769fb160cdab33d3670680e", "");
    try htest.assertEqualHash(allocator, crypto.hash.Keccak512, "18587dc2ea106b9a1563e32b3312421ca164c7f1f07bc922a9c83d77cea3a1e5d0c69910739025372dc14ac9642629379540c17e2a65b19d77aa511a9d00bb96", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Keccak512, "ac2fb35251825d3aa48468a9948c0a91b8256f6d97d8fa4160faff2dd9dfcc24f3f1db7a983dad13d53439ccac0b37e24037e7b95f80f59f37a2f683c4ba4682", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSHAKE128Single(allocator: *mem.SimpleAllocator) !void {
    var out: [10]u8 = undefined;
    crypto.hash.Shake128.hash("hello123", &out);
    try htest.assertEqual(allocator, "1b85861510bc4d8e467d", &out);
}
fn testSHAKE128Multisqueeze(allocator: *mem.SimpleAllocator) !void {
    var out: [10]u8 = undefined;
    var h: crypto.hash.Shake128 = .{};
    h.update("hello123");
    h.squeeze(out[0..4]);
    h.squeeze(out[4..]);
    try htest.assertEqual(allocator, "1b85861510bc4d8e467d", &out);
}
fn testSHAKE128MultisqueezeWithMultipleBlocks() !void {
    var out: [100]u8 = undefined;
    var out2: [100]u8 = undefined;
    var h: crypto.hash.Shake128 = .{};
    h.update("hello123");
    h.squeeze(out[0..50]);
    h.squeeze(out[50..]);
    var h2: crypto.hash.Shake128 = .{};
    h2.update("hello123");
    h2.squeeze(&out2);
    try debug.expectEqualMemory([]const u8, &out, &out2);
}
fn testSHAKE256Single(allocator: *mem.SimpleAllocator) !void {
    var out: [10]u8 = undefined;
    crypto.hash.Shake256.hash("hello123", &out);
    try htest.assertEqual(allocator, "ade612ba265f92de4a37", &out);
}
fn testTurboSHAKE128(allocator: *mem.SimpleAllocator) !void {
    var out: [32]u8 = undefined;
    crypto.hash.TurboShake(128, 0x06).hash("\xff", &out);
    try htest.assertEqual(allocator, "8ec9c66465ed0d4a6c35d13506718d687a25cb05c74cca1e42501abd83874a67", &out);
}
fn testSHA3WithStreaming(allocator: *mem.SimpleAllocator) !void {
    var msg: [613]u8 = [613]u8{
        0x97, 0xd1, 0x2d, 0x1a, 0x16, 0x2d, 0x36, 0x4d, 0x20, 0x62, 0x19, 0x0b, 0x14, 0x93, 0xbb, 0xf8,
        0x5b, 0xea, 0x04, 0xc2, 0x61, 0x8e, 0xd6, 0x08, 0x81, 0xa1, 0x1d, 0x73, 0x27, 0x48, 0xbf, 0xa4,
        0xba, 0xb1, 0x9a, 0x48, 0x9c, 0xf9, 0x9b, 0xff, 0x34, 0x48, 0xa9, 0x75, 0xea, 0xc8, 0xa3, 0x48,
        0x24, 0x9d, 0x75, 0x27, 0x48, 0xec, 0x03, 0xb0, 0xbb, 0xdf, 0x33, 0x90, 0xe3, 0x93, 0xed, 0x68,
        0x24, 0x39, 0x12, 0xdf, 0xea, 0xee, 0x8c, 0x9f, 0x96, 0xde, 0x42, 0x46, 0x8c, 0x2b, 0x17, 0x83,
        0x36, 0xfb, 0xf4, 0xf7, 0xff, 0x79, 0xb9, 0x45, 0x41, 0xc9, 0x56, 0x1a, 0x6b, 0x0c, 0xa4, 0x1a,
        0xdd, 0x6b, 0x95, 0xe8, 0x03, 0x0f, 0x09, 0x29, 0x40, 0x1b, 0xea, 0x87, 0xfa, 0xb9, 0x18, 0xa9,
        0x95, 0x07, 0x7c, 0x2f, 0x7c, 0x33, 0xfb, 0xc5, 0x11, 0x5e, 0x81, 0x0e, 0xbc, 0xae, 0xec, 0xb3,
        0xe1, 0x4a, 0x26, 0x56, 0xe8, 0x5b, 0x11, 0x9d, 0x37, 0x06, 0x9b, 0x34, 0x31, 0x6e, 0xa3, 0xba,
        0x41, 0xbc, 0x11, 0xd8, 0xc5, 0x15, 0xc9, 0x30, 0x2c, 0x9b, 0xb6, 0x71, 0xd8, 0x7c, 0xbc, 0x38,
        0x2f, 0xd5, 0xbd, 0x30, 0x96, 0xd4, 0xa3, 0x00, 0x77, 0x9d, 0x55, 0x4a, 0x33, 0x53, 0xb6, 0xb3,
        0x35, 0x1b, 0xae, 0xe5, 0xdc, 0x22, 0x23, 0x85, 0x95, 0x88, 0xf9, 0x3b, 0xbf, 0x74, 0x13, 0xaa,
        0xcb, 0x0a, 0x60, 0x79, 0x13, 0x79, 0xc0, 0x4a, 0x02, 0xdb, 0x1c, 0xc9, 0xff, 0x60, 0x57, 0x9a,
        0x70, 0x28, 0x58, 0x60, 0xbc, 0x57, 0x07, 0xc7, 0x47, 0x1a, 0x45, 0x71, 0x76, 0x94, 0xfb, 0x05,
        0xad, 0xec, 0x12, 0x29, 0x5a, 0x44, 0x6a, 0x81, 0xd9, 0xc6, 0xf0, 0xb6, 0x9b, 0x97, 0x83, 0x69,
        0xfb, 0xdc, 0x0d, 0x4a, 0x67, 0xbc, 0x72, 0xf5, 0x43, 0x5e, 0x9b, 0x13, 0xf2, 0xe4, 0x6d, 0x49,
        0xdb, 0x76, 0xcb, 0x42, 0x6a, 0x3c, 0x9f, 0xa1, 0xfe, 0x5e, 0xca, 0x0a, 0xfc, 0xfa, 0x39, 0x27,
        0xd1, 0x3c, 0xcb, 0x9a, 0xde, 0x4c, 0x6b, 0x09, 0x8b, 0x49, 0xfd, 0x1e, 0x3d, 0x5e, 0x67, 0x7c,
        0x57, 0xad, 0x90, 0xcc, 0x46, 0x5f, 0x5c, 0xae, 0x6a, 0x9c, 0xb2, 0xcd, 0x2c, 0x89, 0x78, 0xcf,
        0xf1, 0x49, 0x96, 0x55, 0x1e, 0x04, 0xef, 0x0e, 0x1c, 0xde, 0x6c, 0x96, 0x51, 0x00, 0xee, 0x9a,
        0x1f, 0x8d, 0x61, 0xbc, 0xeb, 0xb1, 0xa6, 0xa5, 0x21, 0x8b, 0xa7, 0xf8, 0x25, 0x41, 0x48, 0x62,
        0x5b, 0x01, 0x6c, 0x7c, 0x2a, 0xe8, 0xff, 0xf9, 0xf9, 0x1f, 0xe2, 0x79, 0x2e, 0xd1, 0xff, 0xa3,
        0x2e, 0x1c, 0x3a, 0x1a, 0x5d, 0x2b, 0x7b, 0x87, 0x25, 0x22, 0xa4, 0x90, 0xea, 0x26, 0x9d, 0xdd,
        0x13, 0x60, 0x4c, 0x10, 0x03, 0xf6, 0x99, 0xd3, 0x21, 0x0c, 0x69, 0xc6, 0xd8, 0xc8, 0x9e, 0x94,
        0x89, 0x51, 0x21, 0xe3, 0x9a, 0xcd, 0xda, 0x54, 0x72, 0x64, 0xae, 0x94, 0x79, 0x36, 0x81, 0x44,
        0x14, 0x6d, 0x3a, 0x0e, 0xa6, 0x30, 0xbf, 0x95, 0x99, 0xa6, 0xf5, 0x7f, 0x4f, 0xef, 0xc6, 0x71,
        0x2f, 0x36, 0x13, 0x14, 0xa2, 0x9d, 0xc2, 0x0c, 0x0d, 0x4e, 0xc0, 0x02, 0xd3, 0x6f, 0xee, 0x98,
        0x5e, 0x24, 0x31, 0x74, 0x11, 0x96, 0x6e, 0x43, 0x57, 0xe8, 0x8e, 0xa0, 0x8d, 0x3d, 0x79, 0x38,
        0x20, 0xc2, 0x0f, 0xb4, 0x75, 0x99, 0x3b, 0xb1, 0xf0, 0xe8, 0xe1, 0xda, 0xf9, 0xd4, 0xe6, 0xd6,
        0xf4, 0x8a, 0x32, 0x4a, 0x4a, 0x25, 0xa8, 0xd9, 0x60, 0xd6, 0x33, 0x31, 0x97, 0xb9, 0xb6, 0xed,
        0x5f, 0xfc, 0x15, 0xbd, 0x13, 0xc0, 0x3a, 0x3f, 0x1f, 0x2d, 0x09, 0x1d, 0xeb, 0x69, 0x6a, 0xfe,
        0xd7, 0x95, 0x3e, 0x8a, 0x4e, 0xe1, 0x6e, 0x61, 0xb2, 0x6c, 0xe3, 0x2b, 0x70, 0x60, 0x7e, 0x8c,
        0xe4, 0xdd, 0x27, 0x30, 0x7e, 0x0d, 0xc7, 0xb7, 0x9a, 0x1a, 0x3c, 0xcc, 0xa7, 0x22, 0x77, 0x14,
        0x05, 0x50, 0x57, 0x31, 0x1b, 0xc8, 0xbf, 0xce, 0x52, 0xaf, 0x9c, 0x8e, 0x10, 0x2e, 0xd2, 0x16,
        0xb6, 0x6e, 0x43, 0x10, 0xaf, 0x8b, 0xde, 0x1d, 0x60, 0xb2, 0x7d, 0xe6, 0x2f, 0x08, 0x10, 0x12,
        0x7e, 0xb4, 0x76, 0x45, 0xb6, 0xd8, 0x9b, 0x26, 0x40, 0xa1, 0x63, 0x5c, 0x7a, 0x2a, 0xb1, 0x8c,
        0xd6, 0xa4, 0x6f, 0x5a, 0xae, 0x33, 0x7e, 0x6d, 0x71, 0xf5, 0xc8, 0x6d, 0x80, 0x1c, 0x35, 0xfc,
        0x3f, 0xc1, 0xa6, 0xc6, 0x1a, 0x15, 0x04, 0x6d, 0x76, 0x38, 0x32, 0x95, 0xb2, 0x51, 0x1a, 0xe9,
        0x3e, 0x89, 0x9f, 0x0c, 0x79,
    };
    var out: [crypto.hash.Sha3_256.len]u8 = undefined;
    crypto.hash.Sha3_256.hash(&msg, &out);
    try htest.assertEqual(allocator, "5780048dfa381a1d01c747906e4a08711dd34fd712ecd7c6801dd2b38fd81a89", &out);
    var h: crypto.hash.Sha3_256 = .{};
    h.update(msg[0..64]);
    h.update(msg[64..613]);
    h.final(&out);
    try htest.assertEqual(allocator, "5780048dfa381a1d01c747906e4a08711dd34fd712ecd7c6801dd2b38fd81a89", &out);
}
fn testSha384Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b";
    try htest.assertEqualHash(allocator, crypto.hash.Sha384, h1, "");
    const h2: [:0]const u8 = "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7";
    try htest.assertEqualHash(allocator, crypto.hash.Sha384, h2, "abc");
    const h3: [:0]const u8 = "09330c33f71147e83d192fc782cd1b4753111b173b3b05d22fa08086e3b0f712fcc7c71a557e2db966c3e9fa91746039";
    try htest.assertEqualHash(allocator, crypto.hash.Sha384, h3, "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha384Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha384 = crypto.hash.Sha384.init();
    var out: [48]u8 = undefined;
    const h1: [:0]const u8 = "38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da274edebfe76f65fbd51ad2f14898b95b";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "cb00753f45a35e8bb5a03d699ac65007272c32ab0eded1631a8b605a43ff5bed8086072ba1e7cc2358baeca134c825a7";
    h = crypto.hash.Sha384.init();
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Sha384.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
}
fn testSha512Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e";
    try htest.assertEqualHash(allocator, crypto.hash.Sha512, h1, "");
    const h2: [:0]const u8 = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f";
    try htest.assertEqualHash(allocator, crypto.hash.Sha512, h2, "abc");
    const h3: [:0]const u8 = "8e959b75dae313da8cf4f72814fc143f8f7779c6eb9f7fa17299aeadb6889018501d289e4900f7e4331b99dec4b5433ac7d329eeb6dd26545e96e55b874be909";
    try htest.assertEqualHash(allocator, crypto.hash.Sha512, h3, "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha512Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha512 = crypto.hash.Sha512.init();
    var out: [64]u8 = undefined;
    const h1: [:0]const u8 = "cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "ddaf35a193617abacc417349ae20413112e6fa4e89a97ea20a9eeee64b55d39a2192992a274fc1a836ba3c23a3feebbd454d4423643ce80e2a9ac94fa54ca49f";
    h = crypto.hash.Sha512.init();
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Sha512.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
}
fn testSha512AlignedFinal() !void {
    var block = [_]u8{0} ** crypto.hash.Sha512.blk_len;
    var out: [crypto.hash.Sha512.len]u8 = undefined;
    var h: crypto.hash.Sha512 = crypto.hash.Sha512.init();
    h.update(&block);
    h.final(out[0..]);
}
fn testMd5Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "9e107d9d372bb6826bd81d3542a419d6", "The quick brown fox jumps over the lazy dog");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "e4d909c290d0fb1ca068ffaddf22cbd0", "The quick brown fox jumps over the lazy dog.");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "d41d8cd98f00b204e9800998ecf8427e", "");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "0cc175b9c0f1b6a831c399e269772661", "a");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "900150983cd24fb0d6963f7d28e17f72", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "f96b697d7cb7938d525a2f31aaf161d0", "message digest");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "c3fcd3d76192e4007dfb496cca67e13b", "abcdefghijklmnopqrstuvwxyz");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "d174ab98d277d9f5a5611c2c9f419d9f", "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789");
    try htest.assertEqualHash(allocator, crypto.hash.Md5, "57edf4a22be3c955ac49da2e2107b67a", "12345678901234567890123456789012345678901234567890123456789012345678901234567890");
}
fn testMd5AlignedFinal() !void {
    var block = [_]u8{0} ** crypto.hash.Md5.blk_len;
    var out: [crypto.hash.Md5.len]u8 = undefined;
    var h: crypto.hash.Md5 = crypto.hash.Md5.init();
    h.update(&block);
    h.final(out[0..]);
}
fn testMd5Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Md5 = crypto.hash.Md5.init();
    var out: [16]u8 = undefined;
    h.final(out[0..]);
    try htest.assertEqual(allocator, "d41d8cd98f00b204e9800998ecf8427e", out[0..]);
    h = crypto.hash.Md5.init();
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "900150983cd24fb0d6963f7d28e17f72", out[0..]);
    h = crypto.hash.Md5.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "900150983cd24fb0d6963f7d28e17f72", out[0..]);
}
fn testBlake2s160Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "354c9c33f735962418bdacb9479873429c34916f";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s160, h1, "");
    const h2: [:0]const u8 = "5ae3b99be29b01834c3b508521ede60438f8de17";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s160, h2, "abc");
    const h3: [:0]const u8 = "5a604fec9713c369e84b0ed68daed7d7504ef240";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s160, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "b60c4dc60e2681e58fbc24e77f07e02c69e72ed0";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s160, h4, "a" ** 32 ++ "b" ** 32);
}
fn testBlake2s160Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2s160 = crypto.hash.Blake2s160.init(.{});
    var out: [20]u8 = undefined;
    const h1: [:0]const u8 = "354c9c33f735962418bdacb9479873429c34916f";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "5ae3b99be29b01834c3b508521ede60438f8de17";
    h = crypto.hash.Blake2s160.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2s160.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "b60c4dc60e2681e58fbc24e77f07e02c69e72ed0";
    h = crypto.hash.Blake2s160.init(.{});
    h.update("a" ** 32);
    h.update("b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2s160.init(.{});
    h.update("a" ** 32 ++ "b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    const h4: [:0]const u8 = "4667fd60791a7fe41f939bca646b4529e296bd68";
    h = crypto.hash.Blake2s160.init(.{ .context = [_]u8{0x69} ** 8, .salt = [_]u8{0x42} ** 8 });
    h.update("a" ** 32);
    h.update("b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
    h = crypto.hash.Blake2s160.init(.{ .context = [_]u8{0x69} ** 8, .salt = [_]u8{0x42} ** 8 });
    h.update("a" ** 32 ++ "b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
}
fn testBlake2s224Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "1fa1291e65248b37b3433475b2a0dd63d54a11ecc4e3e034e7bc1ef4";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s224, h1, "");
    const h2: [:0]const u8 = "0b033fc226df7abde29f67a05d3dc62cf271ef3dfea4d387407fbd55";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s224, h2, "abc");
    const h3: [:0]const u8 = "e4e5cb6c7cae41982b397bf7b7d2d9d1949823ae78435326e8db4912";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s224, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "557381a78facd2b298640f4e32113e58967d61420af1aa939d0cfe01";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s224, h4, "a" ** 32 ++ "b" ** 32);
}
fn testBlake2s224Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2s224 = crypto.hash.Blake2s224.init(.{});
    var out: [28]u8 = undefined;
    const h1: [:0]const u8 = "1fa1291e65248b37b3433475b2a0dd63d54a11ecc4e3e034e7bc1ef4";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "0b033fc226df7abde29f67a05d3dc62cf271ef3dfea4d387407fbd55";
    h = crypto.hash.Blake2s224.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2s224.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "557381a78facd2b298640f4e32113e58967d61420af1aa939d0cfe01";
    h = crypto.hash.Blake2s224.init(.{});
    h.update("a" ** 32);
    h.update("b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2s224.init(.{});
    h.update("a" ** 32 ++ "b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    const h4: [:0]const u8 = "a4d6a9d253441b80e5dfd60a04db169ffab77aec56a2855c402828c3";
    h = crypto.hash.Blake2s224.init(.{ .context = [_]u8{0x69} ** 8, .salt = [_]u8{0x42} ** 8 });
    h.update("a" ** 32);
    h.update("b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
    h = crypto.hash.Blake2s224.init(.{ .context = [_]u8{0x69} ** 8, .salt = [_]u8{0x42} ** 8 });
    h.update("a" ** 32 ++ "b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
}
fn testBlake2s256Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s256, h1, "");
    const h2: [:0]const u8 = "508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s256, h2, "abc");
    const h3: [:0]const u8 = "606beeec743ccbeff6cbcdf5d5302aa855c256c29b88c8ed331ea1a6bf3c8812";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s256, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "8d8711dade07a6b92b9a3ea1f40bee9b2c53ff3edd2a273dec170b0163568977";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2s256, h4, "a" ** 32 ++ "b" ** 32);
}
fn testBlake2s256Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2s256 = crypto.hash.Blake2s256.init(.{});
    var out: [32]u8 = undefined;
    const h1: [:0]const u8 = "69217a3079908094e11121d042354a7c1f55b6482ca1a51e1b250dfd1ed0eef9";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "508c5e8c327c14e2e1a72ba34eeb452f37458b209ed63a294d999b4c86675982";
    h = crypto.hash.Blake2s256.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2s256.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "8d8711dade07a6b92b9a3ea1f40bee9b2c53ff3edd2a273dec170b0163568977";
    h = crypto.hash.Blake2s256.init(.{});
    h.update("a" ** 32);
    h.update("b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2s256.init(.{});
    h.update("a" ** 32 ++ "b" ** 32);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
}
fn testBlake2s256Keyed(allocator: *mem.SimpleAllocator) !void {
    var out: [32]u8 = undefined;
    const h1: [:0]const u8 = "10f918da4d74fab3302e48a5d67d03804b1ec95372a62a0f33b7c9fa28ba1ae6";
    const key: []const u8 = "secret_key";
    crypto.hash.Blake2s256.hash("a" ** 64 ++ "b" ** 64, &out, .{ .key = key });
    try htest.assertEqual(allocator, h1, out[0..]);
    var h = crypto.hash.Blake2s256.init(.{ .key = key });
    h.update("a" ** 64 ++ "b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    h = crypto.hash.Blake2s256.init(.{ .key = key });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
}
fn testBlake2b160Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "3345524abf6bbe1809449224b5972c41790b6cf2";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b160, h1, "");
    const h2: [:0]const u8 = "384264f676f39536840523f284921cdc68b6846b";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b160, h2, "abc");
    const h3: [:0]const u8 = "3c523ed102ab45a37d54f5610d5a983162fde84f";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b160, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "43758f5de1740f651f1ae39de92260fe8bd5a11f";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b160, h4, "a" ** 64 ++ "b" ** 64);
}
fn testBlake2b160Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2b160 = crypto.hash.Blake2b160.init(.{});
    var out: [20]u8 = undefined;
    const h1: [:0]const u8 = "3345524abf6bbe1809449224b5972c41790b6cf2";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "384264f676f39536840523f284921cdc68b6846b";
    h = crypto.hash.Blake2b160.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2b160.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "43758f5de1740f651f1ae39de92260fe8bd5a11f";
    h = crypto.hash.Blake2b160.init(.{});
    h.update("a" ** 64 ++ "b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2b160.init(.{});
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2b160.init(.{});
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    const h4: [:0]const u8 = "72328f8a8200663752fc302d372b5dd9b49dd8dc";
    h = crypto.hash.Blake2b160.init(.{ .context = [_]u8{0x69} ** 16, .salt = [_]u8{0x42} ** 16 });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
    h = crypto.hash.Blake2b160.init(.{ .context = [_]u8{0x69} ** 16, .salt = [_]u8{0x42} ** 16 });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
}
fn testBlake2b384Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "b32811423377f52d7862286ee1a72ee540524380fda1724a6f25d7978c6fd3244a6caf0498812673c5e05ef583825100";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b384, h1, "");
    const h2: [:0]const u8 = "6f56a82c8e7ef526dfe182eb5212f7db9df1317e57815dbda46083fc30f54ee6c66ba83be64b302d7cba6ce15bb556f4";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b384, h2, "abc");
    const h3: [:0]const u8 = "b7c81b228b6bd912930e8f0b5387989691c1cee1e65aade4da3b86a3c9f678fc8018f6ed9e2906720c8d2a3aeda9c03d";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b384, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "b7283f0172fecbbd7eca32ce10d8a6c06b453cb3cf675b33eb4246f0da2bb94a6c0bdd6eec0b5fd71ec4fd51be80bf4c";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b384, h4, "a" ** 64 ++ "b" ** 64);
}
fn testBlake2b384Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2b384 = crypto.hash.Blake2b384.init(.{});
    var out: [48]u8 = undefined;
    const h1: [:0]const u8 = "b32811423377f52d7862286ee1a72ee540524380fda1724a6f25d7978c6fd3244a6caf0498812673c5e05ef583825100";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "6f56a82c8e7ef526dfe182eb5212f7db9df1317e57815dbda46083fc30f54ee6c66ba83be64b302d7cba6ce15bb556f4";
    h = crypto.hash.Blake2b384.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2b384.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "b7283f0172fecbbd7eca32ce10d8a6c06b453cb3cf675b33eb4246f0da2bb94a6c0bdd6eec0b5fd71ec4fd51be80bf4c";
    h = crypto.hash.Blake2b384.init(.{});
    h.update("a" ** 64 ++ "b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2b384.init(.{});
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2b384.init(.{});
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    const h4: [:0]const u8 = "934c48fcb197031c71f583d92f98703510805e72142e0b46f5752d1e971bc86c355d556035613ff7a4154b4de09dac5c";
    h = crypto.hash.Blake2b384.init(.{ .context = [_]u8{0x69} ** 16, .salt = [_]u8{0x42} ** 16 });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
    h = crypto.hash.Blake2b384.init(.{ .context = [_]u8{0x69} ** 16, .salt = [_]u8{0x42} ** 16 });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h4, out[0..]);
}

fn testBlake2b512Single(allocator: *mem.SimpleAllocator) !void {
    const h1: [:0]const u8 = "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b512, h1, "");
    const h2: [:0]const u8 = "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b512, h2, "abc");
    const h3: [:0]const u8 = "a8add4bdddfd93e4877d2746e62817b116364a1fa7bc148d95090bc7333b3673f82401cf7aa2e4cb1ecd90296e3f14cb5413f8ed77be73045b13914cdcd6a918";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b512, h3, "The quick brown fox jumps over the lazy dog");
    const h4: [:0]const u8 = "049980af04d6a2cf16b4b49793c3ed7e40732073788806f2c989ebe9547bda0541d63abe298ec8955d08af48ae731f2e8a0bd6d201655a5473b4aa79d211b920";
    try htest.assertEqualHash(allocator, crypto.hash.Blake2b512, h4, "a" ** 64 ++ "b" ** 64);
}
fn testBlake2b512Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Blake2b512 = crypto.hash.Blake2b512.init(.{});
    var out: [64]u8 = undefined;
    const h1: [:0]const u8 = "786a02f742015903c6c6fd852552d272912f4740e15847618a86e217f71f5419d25e1031afee585313896444934eb04b903a685b1448b755d56f701afe9be2ce";
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    const h2: [:0]const u8 = "ba80a53f981c4d0d6a2797b69f12f6e94c212f14685ac4b74b12bb6fdbffa2d17d87c5392aab792dc252d5de4533cc9518d38aa8dbf1925ab92386edd4009923";
    h = crypto.hash.Blake2b512.init(.{});
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    h = crypto.hash.Blake2b512.init(.{});
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, h2, out[0..]);
    const h3: [:0]const u8 = "049980af04d6a2cf16b4b49793c3ed7e40732073788806f2c989ebe9547bda0541d63abe298ec8955d08af48ae731f2e8a0bd6d201655a5473b4aa79d211b920";
    h = crypto.hash.Blake2b512.init(.{});
    h.update("a" ** 64 ++ "b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
    h = crypto.hash.Blake2b512.init(.{});
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h3, out[0..]);
}
fn testBlake2b512Keyed(allocator: *mem.SimpleAllocator) !void {
    var out: [64]u8 = undefined;
    const h1: [:0]const u8 = "8a978060ccaf582f388f37454363071ac9a67e3a704585fd879fb8a419a447e389c7c6de790faa20a7a7dccf197de736bc5b40b98a930b36df5bee7555750c4d";
    const key = "secret_key";
    crypto.hash.Blake2b512.hash("a" ** 64 ++ "b" ** 64, &out, .{ .key = key });
    try htest.assertEqual(allocator, h1, out[0..]);
    var h = crypto.hash.Blake2b512.init(.{ .key = key });
    h.update("a" ** 64 ++ "b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
    h = crypto.hash.Blake2b512.init(.{ .key = key });
    h.update("a" ** 64);
    h.update("b" ** 64);
    h.final(out[0..]);
    try htest.assertEqual(allocator, h1, out[0..]);
}
const OUT_LEN: usize = 32;
const KEY_LEN: usize = 32;
const BLOCK_LEN: usize = 64;
const CHUNK_LEN: usize = 1024;
// Use named type declarations to workaround crash with anonymous structs (issue #4373).
const ReferenceTest = struct {
    key: *const [KEY_LEN]u8,
    context_string: []const u8,
    cases: []const ReferenceTestCase,
};
const ReferenceTestCase = struct {
    input_len: usize,
    hash: *const [262]u8,
    keyed_hash: *const [262]u8,
    derive_key: *const [262]u8,
};
// Each test is an input length and three outputs, one for each of the `hash`, `keyed_hash`, and
// `derive_key` modes. The input in each case is filled with a 251-byte-long repeating pattern:
// 0, 1, 2, ..., 249, 250, 0, 1, ... The key used with `keyed_hash` is the 32-byte ASCII string
// given in the `key` field below. For `derive_key`, the test input is used as the input key, and
// the context string is 'BLAKE3 2019-12-27 16:29:52 test vectors context'. (As good practice for
// following the security requirements of `derive_key`, test runners should make that context
// string a hardcoded constant, and we do not provided it in machine-readable form.) Outputs are
// encoded as hexadecimal. Each case is an extended output, and implementations should also check
// that the first 32 bytes match their default-length output.
//
// Source: https://github.com/BLAKE3-team/BLAKE3/blob/92d421dea1a89e2f079f4dbd93b0dab41234b279/test_vectors/test_vectors.json
const reference_test = ReferenceTest{
    .key = "whats the Elvish word for friend",
    .context_string = "BLAKE3 2019-12-27 16:29:52 test vectors context",
    .cases = &[_]ReferenceTestCase{
        .{
            .input_len = 0,
            .hash = "af1349b9f5f9a1a6a0404dea36dcc9499bcb25c9adc112b7cc9a93cae41f3262e00f03e7b69af26b7faaf09fcd333050338ddfe085b8cc869ca98b206c08243a26f5487789e8f660afe6c99ef9e0c52b92e7393024a80459cf91f476f9ffdbda7001c22e159b402631f277ca96f2defdf1078282314e763699a31c5363165421cce14d",
            .keyed_hash = "92b2b75604ed3c761f9d6f62392c8a9227ad0ea3f09573e783f1498a4ed60d26b18171a2f22a4b94822c701f107153dba24918c4bae4d2945c20ece13387627d3b73cbf97b797d5e59948c7ef788f54372df45e45e4293c7dc18c1d41144a9758be58960856be1eabbe22c2653190de560ca3b2ac4aa692a9210694254c371e851bc8f",
            .derive_key = "2cc39783c223154fea8dfb7c1b1660f2ac2dcbd1c1de8277b0b0dd39b7e50d7d905630c8be290dfcf3e6842f13bddd573c098c3f17361f1f206b8cad9d088aa4a3f746752c6b0ce6a83b0da81d59649257cdf8eb3e9f7d4998e41021fac119deefb896224ac99f860011f73609e6e0e4540f93b273e56547dfd3aa1a035ba6689d89a0",
        },
        .{
            .input_len = 1,
            .hash = "2d3adedff11b61f14c886e35afa036736dcd87a74d27b5c1510225d0f592e213c3a6cb8bf623e20cdb535f8d1a5ffb86342d9c0b64aca3bce1d31f60adfa137b358ad4d79f97b47c3d5e79f179df87a3b9776ef8325f8329886ba42f07fb138bb502f4081cbcec3195c5871e6c23e2cc97d3c69a613eba131e5f1351f3f1da786545e5",
            .keyed_hash = "6d7878dfff2f485635d39013278ae14f1454b8c0a3a2d34bc1ab38228a80c95b6568c0490609413006fbd428eb3fd14e7756d90f73a4725fad147f7bf70fd61c4e0cf7074885e92b0e3f125978b4154986d4fb202a3f331a3fb6cf349a3a70e49990f98fe4289761c8602c4e6ab1138d31d3b62218078b2f3ba9a88e1d08d0dd4cea11",
            .derive_key = "b3e2e340a117a499c6cf2398a19ee0d29cca2bb7404c73063382693bf66cb06c5827b91bf889b6b97c5477f535361caefca0b5d8c4746441c57617111933158950670f9aa8a05d791daae10ac683cbef8faf897c84e6114a59d2173c3f417023a35d6983f2c7dfa57e7fc559ad751dbfb9ffab39c2ef8c4aafebc9ae973a64f0c76551",
        },
        .{
            .input_len = 1023,
            .hash = "10108970eeda3eb932baac1428c7a2163b0e924c9a9e25b35bba72b28f70bd11a182d27a591b05592b15607500e1e8dd56bc6c7fc063715b7a1d737df5bad3339c56778957d870eb9717b57ea3d9fb68d1b55127bba6a906a4a24bbd5acb2d123a37b28f9e9a81bbaae360d58f85e5fc9d75f7c370a0cc09b6522d9c8d822f2f28f485",
            .keyed_hash = "c951ecdf03288d0fcc96ee3413563d8a6d3589547f2c2fb36d9786470f1b9d6e890316d2e6d8b8c25b0a5b2180f94fb1a158ef508c3cde45e2966bd796a696d3e13efd86259d756387d9becf5c8bf1ce2192b87025152907b6d8cc33d17826d8b7b9bc97e38c3c85108ef09f013e01c229c20a83d9e8efac5b37470da28575fd755a10",
            .derive_key = "74a16c1c3d44368a86e1ca6df64be6a2f64cce8f09220787450722d85725dea59c413264404661e9e4d955409dfe4ad3aa487871bcd454ed12abfe2c2b1eb7757588cf6cb18d2eccad49e018c0d0fec323bec82bf1644c6325717d13ea712e6840d3e6e730d35553f59eff5377a9c350bcc1556694b924b858f329c44ee64b884ef00d",
        },
        .{
            .input_len = 1024,
            .hash = "42214739f095a406f3fc83deb889744ac00df831c10daa55189b5d121c855af71cf8107265ecdaf8505b95d8fcec83a98a6a96ea5109d2c179c47a387ffbb404756f6eeae7883b446b70ebb144527c2075ab8ab204c0086bb22b7c93d465efc57f8d917f0b385c6df265e77003b85102967486ed57db5c5ca170ba441427ed9afa684e",
            .keyed_hash = "75c46f6f3d9eb4f55ecaaee480db732e6c2105546f1e675003687c31719c7ba4a78bc838c72852d4f49c864acb7adafe2478e824afe51c8919d06168414c265f298a8094b1ad813a9b8614acabac321f24ce61c5a5346eb519520d38ecc43e89b5000236df0597243e4d2493fd626730e2ba17ac4d8824d09d1a4a8f57b8227778e2de",
            .derive_key = "7356cd7720d5b66b6d0697eb3177d9f8d73a4a5c5e968896eb6a6896843027066c23b601d3ddfb391e90d5c8eccdef4ae2a264bce9e612ba15e2bc9d654af1481b2e75dbabe615974f1070bba84d56853265a34330b4766f8e75edd1f4a1650476c10802f22b64bd3919d246ba20a17558bc51c199efdec67e80a227251808d8ce5bad",
        },
        .{
            .input_len = 1025,
            .hash = "d00278ae47eb27b34faecf67b4fe263f82d5412916c1ffd97c8cb7fb814b8444f4c4a22b4b399155358a994e52bf255de60035742ec71bd08ac275a1b51cc6bfe332b0ef84b409108cda080e6269ed4b3e2c3f7d722aa4cdc98d16deb554e5627be8f955c98e1d5f9565a9194cad0c4285f93700062d9595adb992ae68ff12800ab67a",
            .keyed_hash = "357dc55de0c7e382c900fd6e320acc04146be01db6a8ce7210b7189bd664ea69362396b77fdc0d2634a552970843722066c3c15902ae5097e00ff53f1e116f1cd5352720113a837ab2452cafbde4d54085d9cf5d21ca613071551b25d52e69d6c81123872b6f19cd3bc1333edf0c52b94de23ba772cf82636cff4542540a7738d5b930",
            .derive_key = "effaa245f065fbf82ac186839a249707c3bddf6d3fdda22d1b95a3c970379bcb5d31013a167509e9066273ab6e2123bc835b408b067d88f96addb550d96b6852dad38e320b9d940f86db74d398c770f462118b35d2724efa13da97194491d96dd37c3c09cbef665953f2ee85ec83d88b88d11547a6f911c8217cca46defa2751e7f3ad",
        },
        .{
            .input_len = 2048,
            .hash = "e776b6028c7cd22a4d0ba182a8bf62205d2ef576467e838ed6f2529b85fba24a9a60bf80001410ec9eea6698cd537939fad4749edd484cb541aced55cd9bf54764d063f23f6f1e32e12958ba5cfeb1bf618ad094266d4fc3c968c2088f677454c288c67ba0dba337b9d91c7e1ba586dc9a5bc2d5e90c14f53a8863ac75655461cea8f9",
            .keyed_hash = "879cf1fa2ea0e79126cb1063617a05b6ad9d0b696d0d757cf053439f60a99dd10173b961cd574288194b23ece278c330fbb8585485e74967f31352a8183aa782b2b22f26cdcadb61eed1a5bc144b8198fbb0c13abbf8e3192c145d0a5c21633b0ef86054f42809df823389ee40811a5910dcbd1018af31c3b43aa55201ed4edaac74fe",
            .derive_key = "7b2945cb4fef70885cc5d78a87bf6f6207dd901ff239201351ffac04e1088a23e2c11a1ebffcea4d80447867b61badb1383d842d4e79645d48dd82ccba290769caa7af8eaa1bd78a2a5e6e94fbdab78d9c7b74e894879f6a515257ccf6f95056f4e25390f24f6b35ffbb74b766202569b1d797f2d4bd9d17524c720107f985f4ddc583",
        },
        .{
            .input_len = 2049,
            .hash = "5f4d72f40d7a5f82b15ca2b2e44b1de3c2ef86c426c95c1af0b687952256303096de31d71d74103403822a2e0bc1eb193e7aecc9643a76b7bbc0c9f9c52e8783aae98764ca468962b5c2ec92f0c74eb5448d519713e09413719431c802f948dd5d90425a4ecdadece9eb178d80f26efccae630734dff63340285adec2aed3b51073ad3",
            .keyed_hash = "9f29700902f7c86e514ddc4df1e3049f258b2472b6dd5267f61bf13983b78dd5f9a88abfefdfa1e00b418971f2b39c64ca621e8eb37fceac57fd0c8fc8e117d43b81447be22d5d8186f8f5919ba6bcc6846bd7d50726c06d245672c2ad4f61702c646499ee1173daa061ffe15bf45a631e2946d616a4c345822f1151284712f76b2b0e",
            .derive_key = "2ea477c5515cc3dd606512ee72bb3e0e758cfae7232826f35fb98ca1bcbdf27316d8e9e79081a80b046b60f6a263616f33ca464bd78d79fa18200d06c7fc9bffd808cc4755277a7d5e09da0f29ed150f6537ea9bed946227ff184cc66a72a5f8c1e4bd8b04e81cf40fe6dc4427ad5678311a61f4ffc39d195589bdbc670f63ae70f4b6",
        },
        .{
            .input_len = 3072,
            .hash = "b98cb0ff3623be03326b373de6b9095218513e64f1ee2edd2525c7ad1e5cffd29a3f6b0b978d6608335c09dc94ccf682f9951cdfc501bfe47b9c9189a6fc7b404d120258506341a6d802857322fbd20d3e5dae05b95c88793fa83db1cb08e7d8008d1599b6209d78336e24839724c191b2a52a80448306e0daa84a3fdb566661a37e11",
            .keyed_hash = "044a0e7b172a312dc02a4c9a818c036ffa2776368d7f528268d2e6b5df19177022f302d0529e4174cc507c463671217975e81dab02b8fdeb0d7ccc7568dd22574c783a76be215441b32e91b9a904be8ea81f7a0afd14bad8ee7c8efc305ace5d3dd61b996febe8da4f56ca0919359a7533216e2999fc87ff7d8f176fbecb3d6f34278b",
            .derive_key = "050df97f8c2ead654d9bb3ab8c9178edcd902a32f8495949feadcc1e0480c46b3604131bbd6e3ba573b6dd682fa0a63e5b165d39fc43a625d00207607a2bfeb65ff1d29292152e26b298868e3b87be95d6458f6f2ce6118437b632415abe6ad522874bcd79e4030a5e7bad2efa90a7a7c67e93f0a18fb28369d0a9329ab5c24134ccb0",
        },
        .{
            .input_len = 3073,
            .hash = "7124b49501012f81cc7f11ca069ec9226cecb8a2c850cfe644e327d22d3e1cd39a27ae3b79d68d89da9bf25bc27139ae65a324918a5f9b7828181e52cf373c84f35b639b7fccbb985b6f2fa56aea0c18f531203497b8bbd3a07ceb5926f1cab74d14bd66486d9a91eba99059a98bd1cd25876b2af5a76c3e9eed554ed72ea952b603bf",
            .keyed_hash = "68dede9bef00ba89e43f31a6825f4cf433389fedae75c04ee9f0cf16a427c95a96d6da3fe985054d3478865be9a092250839a697bbda74e279e8a9e69f0025e4cfddd6cfb434b1cd9543aaf97c635d1b451a4386041e4bb100f5e45407cbbc24fa53ea2de3536ccb329e4eb9466ec37093a42cf62b82903c696a93a50b702c80f3c3c5",
            .derive_key = "72613c9ec9ff7e40f8f5c173784c532ad852e827dba2bf85b2ab4b76f7079081576288e552647a9d86481c2cae75c2dd4e7c5195fb9ada1ef50e9c5098c249d743929191441301c69e1f48505a4305ec1778450ee48b8e69dc23a25960fe33070ea549119599760a8a2d28aeca06b8c5e9ba58bc19e11fe57b6ee98aa44b2a8e6b14a5",
        },
        .{
            .input_len = 4096,
            .hash = "015094013f57a5277b59d8475c0501042c0b642e531b0a1c8f58d2163229e9690289e9409ddb1b99768eafe1623da896faf7e1114bebeadc1be30829b6f8af707d85c298f4f0ff4d9438aef948335612ae921e76d411c3a9111df62d27eaf871959ae0062b5492a0feb98ef3ed4af277f5395172dbe5c311918ea0074ce0036454f620",
            .keyed_hash = "befc660aea2f1718884cd8deb9902811d332f4fc4a38cf7c7300d597a081bfc0bbb64a36edb564e01e4b4aaf3b060092a6b838bea44afebd2deb8298fa562b7b597c757b9df4c911c3ca462e2ac89e9a787357aaf74c3b56d5c07bc93ce899568a3eb17d9250c20f6c5f6c1e792ec9a2dcb715398d5a6ec6d5c54f586a00403a1af1de",
            .derive_key = "1e0d7f3db8c414c97c6307cbda6cd27ac3b030949da8e23be1a1a924ad2f25b9d78038f7b198596c6cc4a9ccf93223c08722d684f240ff6569075ed81591fd93f9fff1110b3a75bc67e426012e5588959cc5a4c192173a03c00731cf84544f65a2fb9378989f72e9694a6a394a8a30997c2e67f95a504e631cd2c5f55246024761b245",
        },
        .{
            .input_len = 4097,
            .hash = "9b4052b38f1c5fc8b1f9ff7ac7b27cd242487b3d890d15c96a1c25b8aa0fb99505f91b0b5600a11251652eacfa9497b31cd3c409ce2e45cfe6c0a016967316c426bd26f619eab5d70af9a418b845c608840390f361630bd497b1ab44019316357c61dbe091ce72fc16dc340ac3d6e009e050b3adac4b5b2c92e722cffdc46501531956",
            .keyed_hash = "00df940cd36bb9fa7cbbc3556744e0dbc8191401afe70520ba292ee3ca80abbc606db4976cfdd266ae0abf667d9481831ff12e0caa268e7d3e57260c0824115a54ce595ccc897786d9dcbf495599cfd90157186a46ec800a6763f1c59e36197e9939e900809f7077c102f888caaf864b253bc41eea812656d46742e4ea42769f89b83f",
            .derive_key = "aca51029626b55fda7117b42a7c211f8c6e9ba4fe5b7a8ca922f34299500ead8a897f66a400fed9198fd61dd2d58d382458e64e100128075fc54b860934e8de2e84170734b06e1d212a117100820dbc48292d148afa50567b8b84b1ec336ae10d40c8c975a624996e12de31abbe135d9d159375739c333798a80c64ae895e51e22f3ad",
        },
        .{
            .input_len = 5120,
            .hash = "9cadc15fed8b5d854562b26a9536d9707cadeda9b143978f319ab34230535833acc61c8fdc114a2010ce8038c853e121e1544985133fccdd0a2d507e8e615e611e9a0ba4f47915f49e53d721816a9198e8b30f12d20ec3689989175f1bf7a300eee0d9321fad8da232ece6efb8e9fd81b42ad161f6b9550a069e66b11b40487a5f5059",
            .keyed_hash = "2c493e48e9b9bf31e0553a22b23503c0a3388f035cece68eb438d22fa1943e209b4dc9209cd80ce7c1f7c9a744658e7e288465717ae6e56d5463d4f80cdb2ef56495f6a4f5487f69749af0c34c2cdfa857f3056bf8d807336a14d7b89bf62bef2fb54f9af6a546f818dc1e98b9e07f8a5834da50fa28fb5874af91bf06020d1bf0120e",
            .derive_key = "7a7acac8a02adcf3038d74cdd1d34527de8a0fcc0ee3399d1262397ce5817f6055d0cefd84d9d57fe792d65a278fd20384ac6c30fdb340092f1a74a92ace99c482b28f0fc0ef3b923e56ade20c6dba47e49227166251337d80a037e987ad3a7f728b5ab6dfafd6e2ab1bd583a95d9c895ba9c2422c24ea0f62961f0dca45cad47bfa0d",
        },
        .{
            .input_len = 5121,
            .hash = "628bd2cb2004694adaab7bbd778a25df25c47b9d4155a55f8fbd79f2fe154cff96adaab0613a6146cdaabe498c3a94e529d3fc1da2bd08edf54ed64d40dcd6777647eac51d8277d70219a9694334a68bc8f0f23e20b0ff70ada6f844542dfa32cd4204ca1846ef76d811cdb296f65e260227f477aa7aa008bac878f72257484f2b6c95",
            .keyed_hash = "6ccf1c34753e7a044db80798ecd0782a8f76f33563accaddbfbb2e0ea4b2d0240d07e63f13667a8d1490e5e04f13eb617aea16a8c8a5aaed1ef6fbde1b0515e3c81050b361af6ead126032998290b563e3caddeaebfab592e155f2e161fb7cba939092133f23f9e65245e58ec23457b78a2e8a125588aad6e07d7f11a85b88d375b72d",
            .derive_key = "b07f01e518e702f7ccb44a267e9e112d403a7b3f4883a47ffbed4b48339b3c341a0add0ac032ab5aaea1e4e5b004707ec5681ae0fcbe3796974c0b1cf31a194740c14519273eedaabec832e8a784b6e7cfc2c5952677e6c3f2c3914454082d7eb1ce1766ac7d75a4d3001fc89544dd46b5147382240d689bbbaefc359fb6ae30263165",
        },
        .{
            .input_len = 6144,
            .hash = "3e2e5b74e048f3add6d21faab3f83aa44d3b2278afb83b80b3c35164ebeca2054d742022da6fdda444ebc384b04a54c3ac5839b49da7d39f6d8a9db03deab32aade156c1c0311e9b3435cde0ddba0dce7b26a376cad121294b689193508dd63151603c6ddb866ad16c2ee41585d1633a2cea093bea714f4c5d6b903522045b20395c83",
            .keyed_hash = "3d6b6d21281d0ade5b2b016ae4034c5dec10ca7e475f90f76eac7138e9bc8f1dc35754060091dc5caf3efabe0603c60f45e415bb3407db67e6beb3d11cf8e4f7907561f05dace0c15807f4b5f389c841eb114d81a82c02a00b57206b1d11fa6e803486b048a5ce87105a686dee041207e095323dfe172df73deb8c9532066d88f9da7e",
            .derive_key = "2a95beae63ddce523762355cf4b9c1d8f131465780a391286a5d01abb5683a1597099e3c6488aab6c48f3c15dbe1942d21dbcdc12115d19a8b8465fb54e9053323a9178e4275647f1a9927f6439e52b7031a0b465c861a3fc531527f7758b2b888cf2f20582e9e2c593709c0a44f9c6e0f8b963994882ea4168827823eef1f64169fef",
        },
        .{
            .input_len = 6145,
            .hash = "f1323a8631446cc50536a9f705ee5cb619424d46887f3c376c695b70e0f0507f18a2cfdd73c6e39dd75ce7c1c6e3ef238fd54465f053b25d21044ccb2093beb015015532b108313b5829c3621ce324b8e14229091b7c93f32db2e4e63126a377d2a63a3597997d4f1cba59309cb4af240ba70cebff9a23d5e3ff0cdae2cfd54e070022",
            .keyed_hash = "9ac301e9e39e45e3250a7e3b3df701aa0fb6889fbd80eeecf28dbc6300fbc539f3c184ca2f59780e27a576c1d1fb9772e99fd17881d02ac7dfd39675aca918453283ed8c3169085ef4a466b91c1649cc341dfdee60e32231fc34c9c4e0b9a2ba87ca8f372589c744c15fd6f985eec15e98136f25beeb4b13c4e43dc84abcc79cd4646c",
            .derive_key = "379bcc61d0051dd489f686c13de00d5b14c505245103dc040d9e4dd1facab8e5114493d029bdbd295aaa744a59e31f35c7f52dba9c3642f773dd0b4262a9980a2aef811697e1305d37ba9d8b6d850ef07fe41108993180cf779aeece363704c76483458603bbeeb693cffbbe5588d1f3535dcad888893e53d977424bb707201569a8d2",
        },
        .{
            .input_len = 7168,
            .hash = "61da957ec2499a95d6b8023e2b0e604ec7f6b50e80a9678b89d2628e99ada77a5707c321c83361793b9af62a40f43b523df1c8633cecb4cd14d00bdc79c78fca5165b863893f6d38b02ff7236c5a9a8ad2dba87d24c547cab046c29fc5bc1ed142e1de4763613bb162a5a538e6ef05ed05199d751f9eb58d332791b8d73fb74e4fce95",
            .keyed_hash = "b42835e40e9d4a7f42ad8cc04f85a963a76e18198377ed84adddeaecacc6f3fca2f01d5277d69bb681c70fa8d36094f73ec06e452c80d2ff2257ed82e7ba348400989a65ee8daa7094ae0933e3d2210ac6395c4af24f91c2b590ef87d7788d7066ea3eaebca4c08a4f14b9a27644f99084c3543711b64a070b94f2c9d1d8a90d035d52",
            .derive_key = "11c37a112765370c94a51415d0d651190c288566e295d505defdad895dae223730d5a5175a38841693020669c7638f40b9bc1f9f39cf98bda7a5b54ae24218a800a2116b34665aa95d846d97ea988bfcb53dd9c055d588fa21ba78996776ea6c40bc428b53c62b5f3ccf200f647a5aae8067f0ea1976391fcc72af1945100e2a6dcb88",
        },
        .{
            .input_len = 7169,
            .hash = "a003fc7a51754a9b3c7fae0367ab3d782dccf28855a03d435f8cfe74605e781798a8b20534be1ca9eb2ae2df3fae2ea60e48c6fb0b850b1385b5de0fe460dbe9d9f9b0d8db4435da75c601156df9d047f4ede008732eb17adc05d96180f8a73548522840779e6062d643b79478a6e8dbce68927f36ebf676ffa7d72d5f68f050b119c8",
            .keyed_hash = "ed9b1a922c046fdb3d423ae34e143b05ca1bf28b710432857bf738bcedbfa5113c9e28d72fcbfc020814ce3f5d4fc867f01c8f5b6caf305b3ea8a8ba2da3ab69fabcb438f19ff11f5378ad4484d75c478de425fb8e6ee809b54eec9bdb184315dc856617c09f5340451bf42fd3270a7b0b6566169f242e533777604c118a6358250f54",
            .derive_key = "554b0a5efea9ef183f2f9b931b7497995d9eb26f5c5c6dad2b97d62fc5ac31d99b20652c016d88ba2a611bbd761668d5eda3e568e940faae24b0d9991c3bd25a65f770b89fdcadabcb3d1a9c1cb63e69721cacf1ae69fefdcef1e3ef41bc5312ccc17222199e47a26552c6adc460cf47a72319cb5039369d0060eaea59d6c65130f1dd",
        },
        .{
            .input_len = 8192,
            .hash = "aae792484c8efe4f19e2ca7d371d8c467ffb10748d8a5a1ae579948f718a2a635fe51a27db045a567c1ad51be5aa34c01c6651c4d9b5b5ac5d0fd58cf18dd61a47778566b797a8c67df7b1d60b97b19288d2d877bb2df417ace009dcb0241ca1257d62712b6a4043b4ff33f690d849da91ea3bf711ed583cb7b7a7da2839ba71309bbf",
            .keyed_hash = "dc9637c8845a770b4cbf76b8daec0eebf7dc2eac11498517f08d44c8fc00d58a4834464159dcbc12a0ba0c6d6eb41bac0ed6585cabfe0aca36a375e6c5480c22afdc40785c170f5a6b8a1107dbee282318d00d915ac9ed1143ad40765ec120042ee121cd2baa36250c618adaf9e27260fda2f94dea8fb6f08c04f8f10c78292aa46102",
            .derive_key = "ad01d7ae4ad059b0d33baa3c01319dcf8088094d0359e5fd45d6aeaa8b2d0c3d4c9e58958553513b67f84f8eac653aeeb02ae1d5672dcecf91cd9985a0e67f4501910ecba25555395427ccc7241d70dc21c190e2aadee875e5aae6bf1912837e53411dabf7a56cbf8e4fb780432b0d7fe6cec45024a0788cf5874616407757e9e6bef7",
        },
        .{
            .input_len = 8193,
            .hash = "bab6c09cb8ce8cf459261398d2e7aef35700bf488116ceb94a36d0f5f1b7bc3bb2282aa69be089359ea1154b9a9286c4a56af4de975a9aa4a5c497654914d279bea60bb6d2cf7225a2fa0ff5ef56bbe4b149f3ed15860f78b4e2ad04e158e375c1e0c0b551cd7dfc82f1b155c11b6b3ed51ec9edb30d133653bb5709d1dbd55f4e1ff6",
            .keyed_hash = "954a2a75420c8d6547e3ba5b98d963e6fa6491addc8c023189cc519821b4a1f5f03228648fd983aef045c2fa8290934b0866b615f585149587dda2299039965328835a2b18f1d63b7e300fc76ff260b571839fe44876a4eae66cbac8c67694411ed7e09df51068a22c6e67d6d3dd2cca8ff12e3275384006c80f4db68023f24eebba57",
            .derive_key = "af1e0346e389b17c23200270a64aa4e1ead98c61695d917de7d5b00491c9b0f12f20a01d6d622edf3de026a4db4e4526225debb93c1237934d71c7340bb5916158cbdafe9ac3225476b6ab57a12357db3abbad7a26c6e66290e44034fb08a20a8d0ec264f309994d2810c49cfba6989d7abb095897459f5425adb48aba07c5fb3c83c0",
        },
        .{
            .input_len = 16384,
            .hash = "f875d6646de28985646f34ee13be9a576fd515f76b5b0a26bb324735041ddde49d764c270176e53e97bdffa58d549073f2c660be0e81293767ed4e4929f9ad34bbb39a529334c57c4a381ffd2a6d4bfdbf1482651b172aa883cc13408fa67758a3e47503f93f87720a3177325f7823251b85275f64636a8f1d599c2e49722f42e93893",
            .keyed_hash = "9e9fc4eb7cf081ea7c47d1807790ed211bfec56aa25bb7037784c13c4b707b0df9e601b101e4cf63a404dfe50f2e1865bb12edc8fca166579ce0c70dba5a5c0fc960ad6f3772183416a00bd29d4c6e651ea7620bb100c9449858bf14e1ddc9ecd35725581ca5b9160de04060045993d972571c3e8f71e9d0496bfa744656861b169d65",
            .derive_key = "160e18b5878cd0df1c3af85eb25a0db5344d43a6fbd7a8ef4ed98d0714c3f7e160dc0b1f09caa35f2f417b9ef309dfe5ebd67f4c9507995a531374d099cf8ae317542e885ec6f589378864d3ea98716b3bbb65ef4ab5e0ab5bb298a501f19a41ec19af84a5e6b428ecd813b1a47ed91c9657c3fba11c406bc316768b58f6802c9e9b57",
        },
        .{
            .input_len = 31744,
            .hash = "62b6960e1a44bcc1eb1a611a8d6235b6b4b78f32e7abc4fb4c6cdcce94895c47860cc51f2b0c28a7b77304bd55fe73af663c02d3f52ea053ba43431ca5bab7bfea2f5e9d7121770d88f70ae9649ea713087d1914f7f312147e247f87eb2d4ffef0ac978bf7b6579d57d533355aa20b8b77b13fd09748728a5cc327a8ec470f4013226f",
            .keyed_hash = "efa53b389ab67c593dba624d898d0f7353ab99e4ac9d42302ee64cbf9939a4193a7258db2d9cd32a7a3ecfce46144114b15c2fcb68a618a976bd74515d47be08b628be420b5e830fade7c080e351a076fbc38641ad80c736c8a18fe3c66ce12f95c61c2462a9770d60d0f77115bbcd3782b593016a4e728d4c06cee4505cb0c08a42ec",
            .derive_key = "39772aef80e0ebe60596361e45b061e8f417429d529171b6764468c22928e28e9759adeb797a3fbf771b1bcea30150a020e317982bf0d6e7d14dd9f064bc11025c25f31e81bd78a921db0174f03dd481d30e93fd8e90f8b2fee209f849f2d2a52f31719a490fb0ba7aea1e09814ee912eba111a9fde9d5c274185f7bae8ba85d300a2b",
        },
        .{
            .input_len = 102400,
            .hash = "bc3e3d41a1146b069abffad3c0d44860cf664390afce4d9661f7902e7943e085e01c59dab908c04c3342b816941a26d69c2605ebee5ec5291cc55e15b76146e6745f0601156c3596cb75065a9c57f35585a52e1ac70f69131c23d611ce11ee4ab1ec2c009012d236648e77be9295dd0426f29b764d65de58eb7d01dd42248204f45f8e",
            .keyed_hash = "1c35d1a5811083fd7119f5d5d1ba027b4d01c0c6c49fb6ff2cf75393ea5db4a7f9dbdd3e1d81dcbca3ba241bb18760f207710b751846faaeb9dff8262710999a59b2aa1aca298a032d94eacfadf1aa192418eb54808db23b56e34213266aa08499a16b354f018fc4967d05f8b9d2ad87a7278337be9693fc638a3bfdbe314574ee6fc4",
            .derive_key = "4652cff7a3f385a6103b5c260fc1593e13c778dbe608efb092fe7ee69df6e9c6d83a3e041bc3a48df2879f4a0a3ed40e7c961c73eff740f3117a0504c2dff4786d44fb17f1549eb0ba585e40ec29bf7732f0b7e286ff8acddc4cb1e23b87ff5d824a986458dcc6a04ac83969b80637562953df51ed1a7e90a7926924d2763778be8560",
        },
    },
};
fn testBlake3(hasher: *crypto.hash.Blake3, input_len: usize, expected_hex: [262]u8) !void {
    // Save initial state
    const initial_state: crypto.hash.Blake3 = hasher.*;
    // Setup input pattern
    var input_pattern: [251]u8 = undefined;
    for (&input_pattern, 0..) |*e, i| e.* = @as(u8, @truncate(i));
    // Write repeating input pattern to hasher
    var input_counter: u64 = input_len;
    while (input_counter > 0) {
        const update_len = @min(input_counter, input_pattern.len);
        hasher.update(input_pattern[0..update_len]);
        input_counter -= update_len;
    }
    // Read final hash value
    var actual_bytes: [expected_hex.len / 2]u8 = undefined;
    hasher.final(actual_bytes[0..]);
    // Compare to expected value
    var expected_bytes: [expected_hex.len / 2]u8 = undefined;
    _ = try meta.wrap(fmt.hexToBytes(expected_bytes[0..], expected_hex[0..]));
    try debug.expectEqualMemory(@TypeOf(actual_bytes), actual_bytes, expected_bytes);
    // Restore initial state
    hasher.* = initial_state;
}
fn testBLAKE3ReferenceTestCases() !void {
    var hash_state: crypto.hash.Blake3 = crypto.hash.Blake3.init(.{});
    const hash: *crypto.hash.Blake3 = &hash_state;
    var keyed_hash_state: crypto.hash.Blake3 = crypto.hash.Blake3.init(.{ .key = reference_test.key.* });
    const keyed_hash: *crypto.hash.Blake3 = &keyed_hash_state;
    var derive_key_state: crypto.hash.Blake3 = crypto.hash.Blake3.initKdf(reference_test.context_string);
    const derive_key: *crypto.hash.Blake3 = &derive_key_state;
    for (reference_test.cases) |t| {
        try testBlake3(hash, t.input_len, t.hash.*);
        try testBlake3(keyed_hash, t.input_len, t.keyed_hash.*);
        try testBlake3(derive_key, t.input_len, t.derive_key.*);
    }
}
fn testSha1Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Sha1, "da39a3ee5e6b4b0d3255bfef95601890afd80709", "");
    try htest.assertEqualHash(allocator, crypto.hash.Sha1, "a9993e364706816aba3e25717850c26c9cd0d89d", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Sha1, "a49b2446a02c645bf419f995b67091253a04a259", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha1Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha1 = crypto.hash.Sha1.init();
    var out: [20]u8 = undefined;
    h.final(&out);
    try htest.assertEqual(allocator, "da39a3ee5e6b4b0d3255bfef95601890afd80709", out[0..]);
    h = crypto.hash.Sha1.init();
    h.update("abc");
    h.final(&out);
    try htest.assertEqual(allocator, "a9993e364706816aba3e25717850c26c9cd0d89d", out[0..]);
    h = crypto.hash.Sha1.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(&out);
    try htest.assertEqual(allocator, "a9993e364706816aba3e25717850c26c9cd0d89d", out[0..]);
}
fn testSha1AlignedFinal() !void {
    var block: [crypto.hash.Sha1.blk_len]u8 = [1]u8{0} ** crypto.hash.Sha1.blk_len;
    var out: [crypto.hash.Sha1.len]u8 = undefined;
    var h: crypto.hash.Sha1 = crypto.hash.Sha1.init();
    h.update(&block);
    h.final(out[0..]);
}
fn testSha224Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Sha224, "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", "");
    try htest.assertEqualHash(allocator, crypto.hash.Sha224, "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Sha224, "c97ca9a559850ce97a04a96def6d99a9e0e0e2ab14e6b8df265fc0b3", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha224Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha224 = crypto.hash.Sha224.init();
    var out: [28]u8 = undefined;
    h.final(out[0..]);
    try htest.assertEqual(allocator, "d14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f", out[0..]);
    h = crypto.hash.Sha224.init();
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", out[0..]);
    h = crypto.hash.Sha224.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "23097d223405d8228642a477bda255b32aadbce4bda0b3f7e36c9da7", out[0..]);
}
fn testSha256Single(allocator: *mem.SimpleAllocator) !void {
    try htest.assertEqualHash(allocator, crypto.hash.Sha256, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", "");
    try htest.assertEqualHash(allocator, crypto.hash.Sha256, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", "abc");
    try htest.assertEqualHash(allocator, crypto.hash.Sha256, "cf5b16a778af8380036ce59e7b0492370b249b11e8f07a51afac45037afee9d1", "abcdefghbcdefghicdefghijdefghijkefghijklfghijklmghijklmnhijklmnoijklmnopjklmnopqklmnopqrlmnopqrsmnopqrstnopqrstu");
}
fn testSha256Streaming(allocator: *mem.SimpleAllocator) !void {
    var h: crypto.hash.Sha256 = crypto.hash.Sha256.init();
    var out: [32]u8 = undefined;
    h.final(out[0..]);
    try htest.assertEqual(allocator, "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855", out[0..]);
    h = crypto.hash.Sha256.init();
    h.update("abc");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", out[0..]);
    h = crypto.hash.Sha256.init();
    h.update("a");
    h.update("b");
    h.update("c");
    h.final(out[0..]);
    try htest.assertEqual(allocator, "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad", out[0..]);
}
fn testSha256AlignedFinal() !void {
    var block: [crypto.hash.Sha256.blk_len]u8 = [1]u8{0} ** 64;
    var out: [crypto.hash.Sha256.len]u8 = undefined;
    var h: crypto.hash.Sha256 = crypto.hash.Sha256.init();
    h.update(&block);
    h.final(out[0..]);
}
pub fn hashTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    try testSha3224Single(&allocator);
    try testSha3224Streaming(&allocator);
    try testSha3256Single(&allocator);
    try testSha3256Streaming(&allocator);
    try testSha3256AlignedFinal();
    try testSha3384Single(&allocator);
    try testSha3384Streaming(&allocator);
    try testSha3512Single(&allocator);
    try testSha3512Streaming(&allocator);
    try testSha3512AlignedFinal();
    try testKeccak256Single(&allocator);
    try testKeccak512Single(&allocator);
    try testSHAKE128Single(&allocator);
    try testSHAKE128Multisqueeze(&allocator);
    try testSHAKE128MultisqueezeWithMultipleBlocks();
    try testSHAKE256Single(&allocator);
    try testTurboSHAKE128(&allocator);
    try testSHA3WithStreaming(&allocator);
    try testSha384Single(&allocator);
    try testSha384Streaming(&allocator);
    try testSha512Single(&allocator);
    try testSha512Streaming(&allocator);
    try testSha512AlignedFinal();
    try testMd5Single(&allocator);
    try testMd5AlignedFinal();
    try testMd5Streaming(&allocator);
    try testBlake2s160Single(&allocator);
    try testBlake2s160Streaming(&allocator);
    try testBlake2s224Single(&allocator);
    try testBlake2s224Streaming(&allocator);
    try testBlake2s256Single(&allocator);
    try testBlake2s256Streaming(&allocator);
    try testBlake2s256Keyed(&allocator);
    try testBlake2b160Single(&allocator);
    try testBlake2b160Streaming(&allocator);
    try testBlake2b384Single(&allocator);
    try testBlake2b384Streaming(&allocator);
    try testBlake2b512Single(&allocator);
    try testBlake2b512Streaming(&allocator);
    try testBlake2b512Keyed(&allocator);
    try testBLAKE3ReferenceTestCases();
    if (@hasDecl(crypto.hash, "Sha224")) {
        try testSha224Single(&allocator);
        try testSha224Streaming(&allocator);
    }
    if (@hasDecl(crypto.hash, "Sha256")) {
        try testSha256Single(&allocator);
        try testSha256Streaming(&allocator);
        try testSha256AlignedFinal();
    }
    allocator.unmap();
}
pub const main = hashTestMain;
