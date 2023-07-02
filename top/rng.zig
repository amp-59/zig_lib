const mem = @import("./mem.zig");
const math = @import("./math.zig");
const builtin = @import("./builtin.zig");

pub const Xoroshiro128 = struct {
    s: [2]u64,
    const tab = [2]u64{
        0xbeac0467eba5facb, 0xd86b048b86aa9922,
    };
    pub fn init(s: u64) Xoroshiro128 {
        var x: Xoroshiro128 = .{ .s = undefined };
        x.seed(s);
        return x;
    }
    pub fn random(xoro: *Xoroshiro128) Random {
        return Random.init(xoro, fill);
    }
    pub fn next(xoro: *Xoroshiro128) u64 {
        const s0: u64 = xoro.s[0];
        var s1: u64 = xoro.s[1];
        const r: u64 = s0 +% s1;
        s1 ^= s0;
        xoro.s[0] = math.rotl(u64, s0, @as(u8, 55)) ^ s1 ^ (s1 << 14);
        xoro.s[1] = math.rotl(u64, s1, @as(u8, 36));
        return r;
    }
    pub fn jump(xoro: *Xoroshiro128) void {
        var s0: u64 = 0;
        var s1: u64 = 0;
        for (tab) |entry| {
            var b: usize = 0;
            while (b != 64) : (b +%= 1) {
                const x0: u64 = xoro.s[0];
                var x1: u64 = xoro.s[1];
                if ((entry & (@as(u64, 1) << @intCast(u6, b))) != 0) {
                    s0 ^= x0;
                    s1 ^= x1;
                }
                x1 ^= x0;
                xoro.s[0] = math.rotl(u64, x0, 55) ^ x1 ^ (x1 << 14);
                xoro.s[1] = math.rotl(u64, x1, 36);
            }
        }
        xoro.s[0] = s0;
        xoro.s[1] = s1;
    }
    pub fn seed(xoro: *Xoroshiro128, init_s: u64) void {
        var gen: u64 = init_s;
        xoro.s[0] = splitMix64(&gen);
        xoro.s[1] = splitMix64(&gen);
    }
    pub fn fill(xoro: *Xoroshiro128, buf: []u8) void {
        var l_idx: usize = 0;
        const aligned_len: usize = buf.len -% (buf.len & 7);
        while (l_idx != aligned_len) : (l_idx +%= 8) {
            var val: u64 = xoro.next();
            var r_idx: usize = 0;
            while (r_idx < 8) : (r_idx +%= 1) {
                buf[l_idx + r_idx] = @truncate(u8, val);
                val >>= 8;
            }
        }
        if (l_idx != buf.len) {
            var rem: u64 = xoro.next();
            while (l_idx != buf.len) : (l_idx +%= 1) {
                buf[l_idx] = @truncate(u8, rem);
                rem >>= 8;
            }
        }
    }
    pub fn splitMix64(s: *u64) u64 {
        s.* +%= 0x9e3779b97f4a7c15;
        var z: u64 = s.*;
        z = (z ^ (z >> 30)) *% 0xbf58476d1ce4e5b9;
        z = (z ^ (z >> 27)) *% 0x94d049bb133111eb;
        return z ^ (z >> 31);
    }
};
