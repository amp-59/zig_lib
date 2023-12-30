const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const tab = zl.tab;
const mem = zl.mem;
const meta = zl.meta;
const proc = zl.proc;
const algo = zl.algo;
const file = zl.file;
const time = zl.time;
const debug = zl.debug;
const parse = zl.parse;
const crypto = zl.crypto;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const logging_override: debug.Logging.Override = debug.spec.logging.override.silent;
pub const runtime_assertions: bool = false;
pub const AddressSpace = mem.spec.address_space.regular_128;
const show_best_cases: bool = false;
pub fn write(buf: []u8, off: u64, ss: []const []const u8) u64 {
    var len: u64 = 0;
    for (ss) |s| {
        for (s, 0..) |c, i| buf[off +% len +% i] = c;
        len +%= s.len;
    }
    return len;
}
pub fn print(buf: []u8, off: u64, ss: []const []const u8) void {
    file.write(.{ .errors = .{} }, 1, buf[0 .. off + write(buf, off, ss)]);
}
pub const Allocator = mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = mem.spec.address_space.regular_128,
    .arena_index = 1,
    .logging = mem.dynamic.spec.logging.silent,
    .errors = mem.dynamic.spec.errors.noexcept,
});
pub const S = struct {
    fn asc(x: anytype, y: anytype) bool {
        return x > y;
    }
    fn desc(x: anytype, y: anytype) bool {
        return x < y;
    }
};
pub fn compareSorts() !void {
    const size = 0x400000;
    const T = u64;
    try mem.map(.{}, .{}, .{}, size, size);
    try mem.map(.{}, .{}, .{}, size + size, size);
    const rnbuf: []u8 = @as([*]u8, @ptrFromInt(size))[0..size];
    try file.readRandom(rnbuf);
    const values_1 = @as([*]T, @ptrFromInt(size))[0..(size / @sizeOf(T))];
    const values_2 = @as([*]T, @ptrFromInt(size + size))[0..(size / @sizeOf(T))];
    if (false) {
        @memcpy(@as([*]u8, @ptrFromInt(size + size))[0..size], @as([*]const u8, @ptrFromInt(size)));
        const t_0 = try time.get(.{}, .realtime);
        algo.insertionSort(T, S.asc, values_2[0 .. values_2.len / 10]);
        const t_1 = try time.get(.{}, .realtime);
        testing.printN(4096, .{ "insert: [", fmt.ud64(values_2.len / 10), "]" ++ @typeName(T), "\t = ", fmt.any(time.diff(t_1, t_0)), '\n' });
    }
    {
        @memcpy(@as([*]u8, @ptrFromInt(size + size))[0..size], @as([*]const u8, @ptrFromInt(size)));
        const t_0 = try time.get(.{}, .realtime);
        algo.shellSort(T, S.asc, values_2);
        const t_1 = try time.get(.{}, .realtime);
        testing.printN(4096, .{ "shell: [", fmt.ud64(values_2.len), "]" ++ @typeName(T), "\t = ", fmt.any(time.diff(t_1, t_0)), '\n' });
    }
    {
        var address_space: AddressSpace = .{};
        var allocator: Allocator = try Allocator.init(&address_space);
        const t_0 = try time.get(.{}, .realtime);
        algo.radixSort(&allocator, T, values_1);
        const t_1 = try time.get(.{}, .realtime);
        testing.printN(4096, .{ "radix: [", fmt.ud64(values_1.len), "]" ++ @typeName(T), "\t = ", fmt.any(time.diff(t_1, t_0)), '\n' });
    }
}
pub fn approximationTest() void {
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    var n_aligned_bytes: u32 = 1;
    var total_requested: u64 = 0;
    var total_returned: u64 = 0;
    while (n_aligned_bytes < tab.max_bit_u16) : (n_aligned_bytes +%= 1) {
        const s_lb_counts: u16 = algo.partialPackSingleApprox(n_aligned_bytes);
        const o_aligned_bytes: u64 = algo.partialUnpackSingleApprox(s_lb_counts);
        const s_ub_counts: u16 = algo.partialPackDoubleApprox(n_aligned_bytes, o_aligned_bytes);
        const s_aligned_bytes: u64 = algo.partialUnpackDoubleApprox(o_aligned_bytes, s_ub_counts);
        total_requested +%= n_aligned_bytes;
        total_returned +%= s_aligned_bytes;
        if (n_aligned_bytes -% s_aligned_bytes == 0 and show_best_cases) {
            const ss: []const []const u8 = &[_][]const u8{
                fmt.old.ud32(@as(u32, @intCast(s_aligned_bytes))).readAll(), " ",
                fmt.old.ub32(@as(u32, @intCast(s_aligned_bytes))).readAll(), "\n",
            };
            if (len +% 128 > buf.len) {
                print(&buf, len, ss);
                len = 0;
            } else {
                len +%= write(&buf, len, ss);
            }
        }
    }
    debug.assertBelow(u64, total_returned - total_requested, (2 *% total_requested) / 100);
}
pub fn main() !void {
    if (builtin.is_fast) {
        try compareSorts();
        approximationTest();
    }
}
