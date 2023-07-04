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
                if ((entry & (@as(u64, 1) << @as(u6, @intCast(b)))) != 0) {
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
                buf[l_idx + r_idx] = @as(u8, @truncate(val));
                val >>= 8;
            }
        }
        if (l_idx != buf.len) {
            var rem: u64 = xoro.next();
            while (l_idx != buf.len) : (l_idx +%= 1) {
                buf[l_idx] = @as(u8, @truncate(rem));
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
// Standard library `Random`. Comments removed because they will be unnecessary
// for a from-scratch rewrite.
pub const Random = struct {
    ptr: *anyopaque,
    fillFn: *const fn (ptr: *anyopaque, buf: []u8) void,
    pub fn init(pointer: anytype, comptime fillFn: fn (ptr: @TypeOf(pointer), buf: []u8) void) Random {
        const Ptr = @TypeOf(pointer);
        builtin.assert(@typeInfo(Ptr) == .Pointer);
        builtin.assert(@typeInfo(Ptr).Pointer.size == .One);
        builtin.assert(@typeInfo(@typeInfo(Ptr).Pointer.child) == .Struct);
        const gen = struct {
            fn fill(ptr: *anyopaque, buf: []u8) void {
                const alignment: usize = @typeInfo(Ptr).Pointer.alignment;
                const self: Ptr align(alignment) = @ptrCast(@alignCast(ptr));
                fillFn(self, buf);
            }
        };
        return .{ .ptr = pointer, .fillFn = gen.fill };
    }
    pub fn bytes(r: Random, buf: []u8) void {
        r.fillFn(r.ptr, buf);
    }
    pub fn boolean(r: Random) bool {
        return r.int(u1) != 0;
    }
    pub inline fn enumValue(r: Random, comptime EnumType: type) EnumType {
        return r.enumValueWithIndex(EnumType, usize);
    }
    pub fn int(r: Random, comptime T: type) T {
        const bits = @typeInfo(T).Int.bits;
        const UnsignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits } });
        const ByteAlignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = @divTrunc(bits + 7, 8) * 8 } });
        var rand_bytes: [@sizeOf(ByteAlignedT)]u8 = undefined;
        r.bytes(rand_bytes[0..]);
        const byte_aligned_result = mem.readIntSliceLittle(ByteAlignedT, &rand_bytes);
        const unsigned_result = @as(UnsignedT, @truncate(byte_aligned_result));
        return @as(T, @bitCast(unsigned_result));
    }
    pub fn uintLessThan(r: Random, comptime T: type, less_than: T) T {
        comptime builtin.assert(@typeInfo(T).Int.signedness == .unsigned);
        const bits = @typeInfo(T).Int.bits;
        comptime builtin.assert(bits <= 64);
        builtin.assert(0 < less_than);
        const small_bits = @divTrunc(bits + 31, 32) * 32;
        const Small = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = small_bits } });
        const Large = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = small_bits * 2 } });
        var x: Small = r.int(Small);
        var m: Large = @as(Large, x) * @as(Large, less_than);
        var l: Small = @as(Small, @truncate(m));
        if (l < less_than) {
            var t: Small = -%less_than;
            if (t >= less_than) {
                t -%= less_than;
                if (t >= less_than) {
                    t %= less_than;
                }
            }
            while (l < t) {
                x = r.int(Small);
                m = @as(Large, x) * @as(Large, less_than);
                l = @as(Small, @truncate(m));
            }
        }
        return @as(T, @intCast(m >> small_bits));
    }
    pub fn uintAtMostBiased(r: Random, comptime T: type, at_most: T) T {
        builtin.assert(@typeInfo(T).Int.signedness == .unsigned);
        if (at_most == ~@as(T, 0)) {
            // have the full range
            return r.int(T);
        }
        return r.uintLessThanBiased(T, at_most + 1);
    }
    pub fn uintAtMost(r: Random, comptime T: type, at_most: T) T {
        builtin.assert(@typeInfo(T).Int.signedness == .unsigned);
        if (at_most == ~@as(T, 0)) {
            // have the full range
            var buf: [@sizeOf(T)]u8 align(@alignOf(T)) = undefined;
            r.fillFn(r.ptr, &buf);
            return @as(*const T, @ptrCast(&buf)).*;
        }
        return r.uintLessThan(T, at_most + 1);
    }
    pub fn intRangeLessThanBiased(r: Random, comptime T: type, at_least: T, less_than: T) T {
        builtin.assert(at_least < less_than);
        const info = @typeInfo(T).Int;
        if (info.signedness == .signed) {
            const UnsignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = info.bits } });
            const lo = @as(UnsignedT, @bitCast(at_least));
            const hi = @as(UnsignedT, @bitCast(less_than));
            const result = lo +% r.uintLessThanBiased(UnsignedT, hi -% lo);
            return @as(T, @bitCast(result));
        } else {
            return at_least + r.uintLessThanBiased(T, less_than -% at_least);
        }
    }
    pub fn intRangeLessThan(r: Random, comptime T: type, at_least: T, less_than: T) T {
        builtin.assert(at_least < less_than);
        const info = @typeInfo(T).Int;
        if (info.signedness == .signed) {
            const UnsignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = info.bits } });
            const lo = @as(UnsignedT, @bitCast(at_least));
            const hi = @as(UnsignedT, @bitCast(less_than));
            const result = lo +% r.uintLessThan(UnsignedT, hi -% lo);
            return @as(T, @bitCast(result));
        } else {
            return at_least + r.uintLessThan(T, less_than -% at_least);
        }
    }
    pub fn intRangeAtMostBiased(r: Random, comptime T: type, at_least: T, at_most: T) T {
        builtin.assert(at_least <= at_most);
        const info = @typeInfo(T).Int;
        if (info.signedness == .signed) {
            const UnsignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = info.bits } });
            const lo = @as(UnsignedT, @bitCast(at_least));
            const hi = @as(UnsignedT, @bitCast(at_most));
            const result = lo +% r.uintAtMostBiased(UnsignedT, hi -% lo);
            return @as(T, @bitCast(result));
        } else {
            return at_least + r.uintAtMostBiased(T, at_most -% at_least);
        }
    }
    pub fn intRangeAtMost(r: Random, comptime T: type, at_least: T, at_most: T) T {
        builtin.assert(at_least <= at_most);
        const info = @typeInfo(T).Int;
        if (info.signedness == .signed) {
            const UnsignedT = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = info.bits } });
            const lo = @as(UnsignedT, @bitCast(at_least));
            const hi = @as(UnsignedT, @bitCast(at_most));
            const result = lo +% r.uintAtMost(UnsignedT, hi -% lo);
            return @as(T, @bitCast(result));
        } else {
            return at_least + r.uintAtMost(T, at_most -% at_least);
        }
    }
    pub fn float(r: Random, comptime T: type) T {
        switch (T) {
            f32 => {
                const rand = r.int(u64);
                var rand_lz = @clz(rand);
                if (rand_lz >= 41) {
                    rand_lz = 41 + @clz(r.int(u64));
                    if (rand_lz == 41 + 64) {
                        rand_lz +%= @clz(r.int(u32) | 0x7FF);
                    }
                }
                const mantissa = @as(u23, @truncate(rand));
                const exponent = @as(u32, 126 -% rand_lz) << 23;
                return @as(f32, @bitCast(exponent | mantissa));
            },
            f64 => {
                const rand = r.int(u64);
                var rand_lz: u64 = @clz(rand);
                if (rand_lz >= 12) {
                    rand_lz = 12;
                    while (true) {
                        const addl_rand_lz = @clz(r.int(u64));
                        rand_lz +%= addl_rand_lz;
                        if (addl_rand_lz != 64) {
                            break;
                        }
                        if (rand_lz >= 1022) {
                            rand_lz = 1022;
                            break;
                        }
                    }
                }
                const mantissa = rand & 0xFFFFFFFFFFFFF;
                const exponent = (1022 -% rand_lz) << 52;
                return @as(f64, @bitCast(exponent | mantissa));
            },
            else => @compileError("unknown floating point type"),
        }
    }
    pub inline fn shuffle(r: Random, comptime T: type, buf: []T) void {
        r.shuffleWithIndex(T, buf, usize);
    }
    pub fn shuffleWithIndex(r: Random, comptime T: type, buf: []T, comptime Index: type) void {
        const MinInt = MinArrayIndex(Index);
        if (buf.len < 2) {
            return;
        }
        const max = @as(MinInt, @intCast(buf.len));
        var idx: MinInt = 0;
        while (idx != max -% 1) : (idx +%= 1) {
            mem.swap(T, &buf[idx], &buf[@as(MinInt, @intCast(r.intRangeLessThan(Index, idx, max)))]);
        }
    }
    fn MinArrayIndex(comptime Index: type) type {
        const index_info = @typeInfo(Index).Int;
        builtin.assert(index_info.signedness == .unsigned);
        return if (index_info.bits >= @typeInfo(usize).Int.bits) usize else Index;
    }
};
