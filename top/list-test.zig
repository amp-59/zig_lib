const lit = @import("./lit.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

const Random = file.DeviceRandomBytes(4096);
const String = Allocator0.StructuredVector(u8);

pub const is_verbose: bool = false;
pub const is_correct: bool = true;

const ptr_wr_spec: mem.ReinterpretSpec = .{
    .reference = .{ .dereference = &.{} },
};
const T = struct {
    i: u64,
    j: u64 = 0xdeadbeef,
};
const Allocator0 = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .options = .{
        .check_parametric_binding = false,
        .unit_alignment = 1,
        .count_allocations = false,
        .count_useful_bytes = false,
        .count_branches = false,
        .require_filo_free = false,
        .require_all_free_deinit = true,
        .trace_state = false,
    },
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .arena_index = 2,
    .options = .{
        .check_parametric_binding = false,
        .unit_alignment = 1,
        .count_allocations = false,
        .count_useful_bytes = false,
        .count_branches = false,
        .require_filo_free = false,
        .require_all_free_deinit = true,
        .trace_state = false,
    },
});
const Allocator = Allocator0;
const LinkedList = mem.XorLinkedListAdv(.{
    .child = T,
    .low_alignment = 8,
    .Allocator = Allocator0,
});
const Link0 = LinkedList.Link;
const Node0 = LinkedList.Node;
fn c(x: anytype) bool {
    return x != 0;
}
var list_count: u64 = 0;
fn d(x: anytype) bool {
    return x < list_count and c(x);
}
fn contrivedInternal(allocator: *Allocator0, list: *LinkedList) !void {
    const values: [5]T = .{
        .{ .i = 11 },
        .{ .i = 22 },
        .{ .i = 33 },
        .{ .i = 44 },
        .{ .i = 55 },
    };
    for (values) |value| {
        try list.append(allocator, value);
    }
    try list.delete(null);
    try list.delete(null);
    try list.delete(null);
    try list.delete(null);
    try list.delete(null);
}
fn contrived() !void {
    var address_space: mem.AddressSpace = .{};
    var allocator: Allocator0 = try Allocator0.init(&address_space);
    defer allocator.deinit(&address_space);
    var list: LinkedList = try LinkedList.init(&allocator);
    try contrivedInternal(&allocator, &list);
    list.goToHead();
    try contrivedInternal(&allocator, &list);
    list.goToHead();
    try contrivedInternal(&allocator, &list);
}
fn string(allocator: *Allocator0, any: anytype) !String {
    var array = try String.init(allocator, any.len);
    array.writeAny(ptr_wr_spec, any);
    return array;
}
fn testAllMovement(list: LinkedList) void {
    var tmp: LinkedList = list;
    while (tmp.next()) |next| {
        tmp = next;
    }
    var n_bwd: u64 = 0;
    while (tmp.prev()) |prev| {
        n_bwd += 1;
        tmp = prev;
    }
    const n_tot: u64 = n_bwd + @boolToInt(list.count != 0);
    builtin.assertEqual(u64, n_tot, list.count);
}
pub fn main() !void {
    const big_num: comptime_int = 10;
    const Count: type = meta.LeastBitSize(big_num);
    const Big: type = meta.LeastBitSize(big_num / 3);
    const undefined_s: [256]u8 = ("a" ** 256).*;
    var address_space: mem.AddressSpace = .{};
    var random: Random = .{};
    var allocator_0: Allocator0 = try Allocator0.init(&address_space);
    defer {
        allocator_0.discard();
        allocator_0.deinit(&address_space);
    }
    var allocator_1: Allocator1 = try Allocator1.init(&address_space);
    defer {
        allocator_1.discard();
        allocator_1.deinit(&address_space);
    }
    const appends_per_round: u64 = random.readOneConditionally(Big, c);
    const prepends_per_round: u64 = random.readOneConditionally(Big, c);
    const inserts_per_round: u64 = big_num - (appends_per_round + prepends_per_round);
    const Disruptor = Allocator1.StructuredHolder(String);
    var disruption: Disruptor = Disruptor.init(&allocator_1);
    defer disruption.deinit(&allocator_1);
    var round_count: u64 = 0;
    while (round_count != 100000) : (round_count += 1) {
        builtin.assertEqual(u64, 0, allocator_0.metadata.count);
        var list: LinkedList = try LinkedList.init(&allocator_0);
        var operation_count: u64 = 0;
        while (operation_count != appends_per_round) : (operation_count += 1) {
            try disruption.appendOne(&allocator_1, try string(&allocator_0, undefined_s[0..builtin.max(u64, 1, random.readOne(u8))]));
            try list.append(&allocator_0, .{ .i = 1 });
        }
        operation_count = 0;
        while (operation_count != prepends_per_round) : (operation_count += 1) {
            try disruption.appendOne(&allocator_1, try string(&allocator_0, undefined_s[0..builtin.max(u64, 1, random.readOne(u8))]));
            try list.prepend(&allocator_0, .{ .i = 10 });
        }
        operation_count = 0;
        while (operation_count != inserts_per_round) : (operation_count += 1) {
            const mid: u64 = builtin.min(u64, list.count, random.readOne(Count));
            try disruption.appendOne(&allocator_1, try string(&allocator_0, undefined_s[0..builtin.max(u64, 1, random.readOne(u8))]));
            try list.insert(&allocator_0, mid, .{ .i = 100 });
        }
        operation_count = 0;
        while (operation_count != big_num / 4) : (operation_count += 1) {
            list_count = list.count;
            const count = list.count;
            const s_begin = try list.at(0);
            const t_begin = try list.extract(0);
            const s_end = try list.at(list.count - 1);
            const t_end = try list.extract(list.count - 1);
            const mid: u64 = builtin.min(u64, list.count - 1, random.readOne(Count));
            const s_mid = try list.at(mid);
            const t_mid = try list.extract(mid);
            try builtin.expectEqual(u64, s_end.i, t_end.read().i);
            try builtin.expectEqual(u64, s_mid.i, t_mid.read().i);
            try builtin.expectEqual(u64, s_begin.*.i, t_begin.read().i);
            try builtin.expectEqual(u64, list.count, count - 3);
            list.retire(t_end);
            list.retire(t_mid);
            list.retire(t_begin);
        }
        try LinkedList.Graphics.show(list, &address_space);
        list.deinit(&allocator_0);
        for (disruption.referAll(allocator_1)) |*z| {
            z.deinit(&allocator_0);
        }
        disruption.undefineAll(allocator_1);
        try builtin.expectEqual(u64, 0, disruption.count(allocator_1));
        try builtin.expectEqual(u64, 0, allocator_0.metadata.count);
    }
}
