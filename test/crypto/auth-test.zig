const zig_lib = @import("../../zig_lib.zig");
const fmt = zig_lib.fmt;
const mem = zig_lib.mem;
const mach = zig_lib.mach;
const meta = zig_lib.meta;
const proc = zig_lib.proc;
const crypto = zig_lib.crypto;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
const tab = @import("./tab.zig");
const htest = @import("./hash-test.zig").htest;

fn testSiphash6424Sanity() !void {
    const SipHash64 = crypto.auth.GenericSipHash64(2, 4);
    var buffer: [64]u8 = undefined;
    for (tab.sip_6424_vectors, 0..) |vector, i| {
        buffer[i] = @as(u8, @intCast(i));
        var out: [SipHash64.mac_len]u8 = undefined;
        SipHash64.create(&out, buffer[0..i], tab.sip_test_key);
        try builtin.expectEqual(@TypeOf(out), out, vector);
    }
}
fn testSiphash12824Sanity() !void {
    const SipHash128 = crypto.auth.GenericSipHash128(2, 4);
    var buffer: [64]u8 = undefined;
    for (tab.sip_12824_vectors, 0..) |vector, i| {
        buffer[i] = @as(u8, @intCast(i));
        var out: [SipHash128.mac_len]u8 = undefined;
        SipHash128.create(&out, buffer[0..i], tab.sip_test_key);
        try builtin.expectEqual(@TypeOf(out), out, vector);
    }
}
fn authTestMain() !void {
    var allocator: mem.SimpleAllocator = .{};
    defer allocator.unmap();
    try testSiphash6424Sanity();
}
pub const main = authTestMain;
