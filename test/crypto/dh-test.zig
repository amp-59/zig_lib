const zig_lib = @import("../../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const file = zig_lib.file;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
const htest = @import("./hash-test.zig").htest;

fn testEd25519KeyPairCreation() !void {
    var seed: [32]u8 = undefined;
    _ = try fmt.hexToBytes(seed[0..], "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166");
    const key_pair = try crypto.dh.Ed25519.KeyPair.create(seed);
    var buf: [256]u8 = undefined;
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &key_pair.secret_key.toBytes()),
        "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de1662d6f7455d97b4a3a10d7293909d1a4f2058cb9a370e43fa8154bb280db839083",
    );
    try testing.expectEqualMany(
        u8,
        fmt.bytesToHex(&buf, &key_pair.public_key.toBytes()),
        "2d6f7455d97b4a3a10d7293909d1a4f2058cb9a370e43fa8154bb280db839083",
    );
}

pub fn dhTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();

    try testEd25519KeyPairCreation();
}
pub const main = dhTestMain;
