const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const mach = @import("./mach.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.formulaic_128;
pub const is_correct: bool = true;
pub const is_verbose: bool = true;
pub const is_perf: bool = false;

const Allocator0 = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .options = .{
        .require_filo_free = false,
        .trace_state = false,
        .count_allocations = true,
        .count_branches = false,
        .count_useful_bytes = false,
    },
    .logging = preset.allocator.logging.verbose,
});

const PrintArray = mem.StructuredAutomaticVector(u8, null, 4096, 1, .{});
const ModeSet = enum { ReadWritePushPop, ReadWrite, Both };
const StructureSet = enum { Structured, Unstructured, Both };
const Dummy = mem.ReadWriteStructuredUnitAlignment(.{ .child = u8, .low_alignment = 1 });
const Random = file.DeviceRandomBytes(4096);

const test_types: []const type = &[_]type{ u16, u32, u64, u128 };
const static_impl_types: []const type = manifestStatic(test_types);
const dynamic_impl_types: []const type = manifestDynamic(test_types);
const parametric_impl_types: []const type = manifestParametric(test_types);

var random: Random = .{};

fn about(comptime name: []const u8) []const u8 {
    return (name ++ ":") ++ (" " ** (16 - (name.len + 1)));
}

fn writeAddresses2Always(comptime S: type, comptime field_name: []const u8, s: S, t: S, array: *PrintArray) void {
    array.writeMany(about(field_name));
    array.writeFormat(fmt.uxd(@field(s, field_name), @field(t, field_name)));
    array.writeMany("\n");
}
fn writeAddresses4Always(comptime S: type, comptime field_name: []const u8, s: S, t: S, u: S, v: S, array: *PrintArray) void {
    array.writeMany(about(field_name));
    array.writeFormat(fmt.uxd(@field(s, field_name), @field(t, field_name)));
    array.writeMany(", ");
    array.writeFormat(fmt.uxd(@field(t, field_name), @field(u, field_name)));
    array.writeMany(", ");
    array.writeFormat(fmt.uxd(@field(u, field_name), @field(v, field_name)));
    array.writeMany("\n");
}
fn writeOffsets2Always(comptime S: type, comptime field_name: []const u8, s: S, t: S, array: *PrintArray) void {
    array.writeMany(about(field_name));
    array.writeFormat(fmt.udd(@field(s, field_name), @field(t, field_name)));
    array.writeMany("\n");
}
fn writeOffsets4Always(comptime S: type, comptime field_name: []const u8, s: S, t: S, u: S, v: S, array: *PrintArray) void {
    array.writeMany(about(field_name));
    array.writeFormat(fmt.udd(@field(s, field_name), @field(t, field_name)));
    array.writeMany(", ");
    array.writeFormat(fmt.udd(@field(t, field_name), @field(u, field_name)));
    array.writeMany(", ");
    array.writeFormat(fmt.udd(@field(u, field_name), @field(v, field_name)));
    array.writeMany("\n");
}
fn announceAnalysis(comptime impl_type: type) void {
    @setEvalBranchQuota(10_000);
    var array: PrintArray = .{};
    if (@hasDecl(impl_type, "child")) {
        const low_alignment: u64 = comptime if (@hasDecl(impl_type, "unit_alignment")) impl_type.unit_alignment else impl_type.low_alignment;
        const layout_align_s: []const u8 = comptime ": " ++ @typeName(impl_type.child) ++ " align(" ++ builtin.fmt.ci(low_alignment) ++ ")";
        array.writeMany(lit.fx.color.fg.hi_blue ++ lit.fx.style.bold);
        array.writeMany(comptime fmt.typeName(impl_type));
        array.writeMany(layout_align_s ++ lit.fx.none ++ "\n");
    } else {
        const low_alignment: u64 = comptime if (@hasDecl(impl_type, "unit_alignment")) impl_type.unit_alignment else impl_type.low_alignment;
        const aligns_s: []const u8 = comptime ": align(" ++ lit.ud8[low_alignment] ++ ") align(" ++ builtin.fmt.ci(low_alignment) ++ ")";
        array.writeMany(lit.fx.color.fg.hi_blue ++ lit.fx.style.bold);
        array.writeMany(comptime fmt.typeName(impl_type));
        array.writeMany(aligns_s ++ lit.fx.none ++ "\n");
    }
    file.noexcept.write(2, array.readAll());
}
fn getBetween(comptime T: type, lower: ?u64, upper: ?u64) u64 {
    const zero: T = 0;
    const min: T = @intCast(T, lower orelse zero);
    const max: T = @intCast(T, upper orelse ~zero);
    builtin.assertAbove(T, max, 0);
    builtin.assertAbove(T, max, min + 1);
    while (true) {
        const first_attempt: T = @max(random.readOne(T), 1);
        var ret: T = first_attempt;
        var i: u64 = 0;
        while (i != 10) : (i += 1) {
            const inc: T = ret >> 1;
            if (inc == 0) {
                ret = @max(random.readOne(T), 1);
            } else if (ret >= max) {
                ret -|= inc;
            } else if (ret <= min) {
                ret +|= inc;
            } else {
                return ret;
            }
        }
    }
    unreachable;
}
fn getAboveAmount(n_amt: mem.Amount, comptime factor: u64) mem.Amount {
    builtin.assertAboveOrEqual(u64, mem.amountToCountOfLength(n_amt, factor), 16);
    var ret: mem.Amount = .{ .count = random.readOne(u8) };
    while (builtin.eval2b(mem.amountToCountOfLength(ret, factor) <= n_amt.countV(factor), ret.countV(factor) < 16)) ret.count = random.readOne(u8);
    return ret;
}
fn getBelowAmount(n_amt: mem.Amount, comptime factor: u64) mem.Amount {
    builtin.assertAboveOrEqual(u64, mem.amountToCountOfLength(n_amt, factor), 16);
    var ret: mem.Amount = .{ .count = random.readOne(u8) };
    while (builtin.eval2b(mem.amountToCountOfLength(ret, factor) >= n_amt.countV(factor), ret.countV(factor) < 16)) ret.count = random.readOne(u8);
    return ret;
}
fn getAbove(bytes: u64) u64 {
    builtin.assertAboveOrEqual(u64, bytes, 16);
    var val: u64 = random.readOne(u8);
    while (builtin.eval2b(val <= bytes, val < 0)) val = random.readOne(u8);
    return val;
}
fn getBelow(bytes: u64) u64 {
    builtin.assertAboveOrEqual(u64, bytes, 16);
    var val: u64 = random.readOne(u8);
    while (builtin.eval2b(val >= bytes, val < 8)) val = random.readOne(u8);
    return val;
}
const RWAddresses = extern struct {
    low: u64,
    start: u64,
    finish: u64,
    high: u64,
    const Addresses = @This();
    const Offsets = RWOffsets;
    fn init(any_rw_impl: anytype) Addresses {
        return .{
            .low = any_rw_impl.low(),
            .start = any_rw_impl.start(),
            .finish = any_rw_impl.finish(),
            .high = any_rw_impl.high(),
        };
    }
    fn alignedBytes(addresses: Addresses) u64 {
        return addresses.high - addresses.start;
    }
    fn offsets(addresses: Addresses) Offsets {
        return .{
            .bytes = mach.sub64(addresses.high, addresses.low),
            .capacity = mach.sub64(addresses.finish, addresses.start),
        };
    }
    fn assertEqual(s_addresses: Addresses, t_addresses: Addresses) void {
        builtin.assertEqual(u64, s_addresses.low, t_addresses.low);
        builtin.assertEqual(u64, s_addresses.start, t_addresses.start);
        builtin.assertEqual(u64, s_addresses.finish, t_addresses.finish);
        builtin.assertEqual(u64, s_addresses.high, t_addresses.high);
    }
    const showWithReferenceWrite = showTwo;
    fn showTwo(s_addresses: Addresses, t_addresses: Addresses, array: *PrintArray) void {
        writeAddresses2Always(Addresses, "low", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "start", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "finish", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "high", s_addresses, t_addresses, array);
    }
    fn showFour(s_addresses: Addresses, t_addresses: Addresses, u_addresses: Addresses, v_addresses: Addresses, array: *PrintArray) void {
        writeAddresses4Always(Addresses, "low", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "start", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "finish", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "high", s_addresses, t_addresses, u_addresses, v_addresses, array);
    }
};
const RWPPAddresses = extern struct {
    low: u64,
    start: u64,
    finish: u64,
    high: u64,
    next: u64,
    const Addresses = @This();
    const Offsets = RWPPOffsets;
    fn alignedBytes(addresses: Addresses) u64 {
        return addresses.high - addresses.start;
    }
    fn offsets(addresses: Addresses) Offsets {
        return .{
            .bytes = mach.sub64(addresses.high, addresses.low),
            .capacity = mach.sub64(addresses.finish, addresses.start),
            .length = mach.sub64(addresses.next, addresses.start),
            .available = mach.sub64(addresses.finish, addresses.next),
        };
    }
    fn assertEqual(s_addresses: Addresses, t_addresses: Addresses) void {
        builtin.assertEqual(u64, s_addresses.low, t_addresses.low);
        builtin.assertEqual(u64, s_addresses.start, t_addresses.start);
        builtin.assertEqual(u64, s_addresses.next, t_addresses.next);
        builtin.assertEqual(u64, s_addresses.finish, t_addresses.finish);
        builtin.assertEqual(u64, s_addresses.high, t_addresses.high);
    }
    const showWithReferenceWrite = showTwo;
    fn showTwo(s_addresses: Addresses, t_addresses: Addresses, array: *PrintArray) void {
        writeAddresses2Always(Addresses, "low", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "start", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "next", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "finish", s_addresses, t_addresses, array);
        writeAddresses2Always(Addresses, "high", s_addresses, t_addresses, array);
    }
    fn showFour(s_addresses: Addresses, t_addresses: Addresses, u_addresses: Addresses, v_addresses: Addresses, array: *PrintArray) void {
        writeAddresses4Always(Addresses, "low", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "start", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "next", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "finish", s_addresses, t_addresses, u_addresses, v_addresses, array);
        writeAddresses4Always(Addresses, "high", s_addresses, t_addresses, u_addresses, v_addresses, array);
    }
};
const RWOffsets = extern struct {
    bytes: u64,
    capacity: u64,
    const Offsets = @This();
    fn maxCount(offsets: Offsets, factor: u64) u64 {
        return offsets.capacity / factor;
    }
    fn init(any_rw_values: anytype) Offsets {
        return .{ .capacity = any_rw_values.capacity, .bytes = any_rw_values.bytes };
    }
    fn assertEqual(s_offsets: Offsets, t_offsets: Offsets) void {
        builtin.assertEqual(u64, s_offsets.capacity, t_offsets.capacity);
        builtin.assertEqual(u64, s_offsets.bytes, t_offsets.bytes);
    }
    const showWithReferenceWrite = showTwo;
    fn showTwo(s_offsets: Offsets, t_offsets: Offsets, array: *PrintArray) void {
        writeOffsets2Always(Offsets, "bytes", s_offsets, t_offsets, array);
        writeOffsets2Always(Offsets, "capacity", s_offsets, t_offsets, array);
    }
    fn showFour(s_offsets: Offsets, t_offsets: Offsets, u_offsets: Offsets, v_offsets: Offsets, array: *PrintArray) void {
        writeOffsets4Always(Offsets, "bytes", s_offsets, t_offsets, u_offsets, v_offsets, array);
        writeOffsets4Always(Offsets, "capacity", s_offsets, t_offsets, u_offsets, v_offsets, array);
    }
};
const RWPPOffsets = extern struct {
    bytes: u64,
    capacity: u64,
    length: u64,
    available: u64,
    const Offsets = @This();
    fn count(offsets: Offsets, factor: u64) u64 {
        return @divExact(offsets.length, factor);
    }
    fn maxCount(offsets: Offsets, factor: u64) u64 {
        return offsets.capacity / factor;
    }
    fn assertEqual(s_offsets: Offsets, t_offsets: Offsets) void {
        builtin.assertEqual(u64, s_offsets.capacity, t_offsets.capacity);
        builtin.assertEqual(u64, s_offsets.bytes, t_offsets.bytes);
        builtin.assertEqual(u64, s_offsets.length, t_offsets.length);
        builtin.assertEqual(u64, s_offsets.available, t_offsets.available);
    }
    const showWithReferenceWrite = showTwo;
    fn showTwo(s_offsets: Offsets, t_offsets: Offsets, array: *PrintArray) void {
        writeOffsets2Always(Offsets, "bytes", s_offsets, t_offsets, array);
        writeOffsets2Always(Offsets, "capacity", s_offsets, t_offsets, array);
        writeOffsets2Always(Offsets, "length", s_offsets, t_offsets, array);
        writeOffsets2Always(Offsets, "available", s_offsets, t_offsets, array);
    }
    fn showFour(s_offsets: Offsets, t_offsets: Offsets, u_offsets: Offsets, v_offsets: Offsets, array: *PrintArray) void {
        writeOffsets4Always(Offsets, "bytes", s_offsets, t_offsets, u_offsets, v_offsets, array);
        writeOffsets4Always(Offsets, "capacity", s_offsets, t_offsets, u_offsets, v_offsets, array);
        writeOffsets4Always(Offsets, "length", s_offsets, t_offsets, u_offsets, v_offsets, array);
        writeOffsets4Always(Offsets, "available", s_offsets, t_offsets, u_offsets, v_offsets, array);
    }
};
const RWDValues = extern struct {
    addresses: RWAddresses,
    offsets: RWOffsets,
    count: u64,
    const Values = @This();
    const Addresses = RWAddresses;
    const Offsets = RWOffsets;
    fn amount(values: Values) mem.Amount {
        return .{ .count = values.count };
    }
    fn assertConsistent(values: Values) void {
        values.offsets.assertEqual(values.addresses.offsets());
    }
    fn assertEqualMemory(s_values: Values, t_values: Values) void {
        const capacity: u64 = @min(s_values.offsets.capacity, t_values.offsets.capacity);
        const s_memory: []u8 = @intToPtr([*]u8, s_values.addresses.start)[0..capacity];
        const t_memory: []u8 = @intToPtr([*]u8, t_values.addresses.start)[0..capacity];
        var byte_offset: u64 = 0;
        while (byte_offset != capacity) : (byte_offset += 1) {
            if (s_memory[byte_offset] != t_memory[byte_offset]) {
                var array: PrintArray = .{};
                array.writeMany("unequal bytes offset ");
                array.writeFormat(fmt.ud(byte_offset));
                array.writeMany("\n");
                file.noexcept.write(2, array.readAll());
                builtin.assertEqual(u8, s_memory[byte_offset], t_memory[byte_offset]);
            }
        }
    }
    const Graphics = struct {
        fn show(values: Values, src: builtin.SourceLocation) void {
            var array: PrintArray = .{};
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            array.writeFormat(src_fmt);
            _ = values;
            if (array.impl.length() != src_fmt.formatLength()) {
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showWithReference(s_values: Values, t_values: Values, src: builtin.SourceLocation) void {
            var array: PrintArray = .{};
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            array.writeFormat(src_fmt);
            s_values.addresses.showWithReferenceWrite(t_values.addresses, &array);
            s_values.offsets.showWithReferenceWrite(t_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showTwo(s_values: Values, t_values: Values, src: builtin.SourceLocation) void {
            var array: PrintArray = .{};
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            array.writeFormat(src_fmt);
            s_values.addresses.showTwo(t_values.addresses, &array);
            s_values.offsets.showTwo(t_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showFour(s_values: Values, t_values: Values, u_values: Values, v_values: Values, src: builtin.SourceLocation) void {
            var array: PrintArray = .{};
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            array.writeFormat(src_fmt);
            s_values.addresses.showFour(t_values.addresses, u_values.addresses, v_values.addresses, &array);
            s_values.offsets.showFour(t_values.offsets, u_values.offsets, v_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
    };
};
const RWPPDValues = extern struct {
    addresses: Addresses,
    offsets: Offsets,
    count: u64,
    const Values = @This();
    const Offsets = RWPPOffsets;
    const Addresses = RWPPAddresses;
    fn amount(values: Values) mem.Amount {
        return .{ .count = values.count };
    }
    fn assertEqual(s_values: Values, t_values: Values) void {
        s_values.addresses.assertEqual(t_values.addresses);
        s_values.offsets.assertEqual(t_values.offsets);
    }
    fn assertFull(values: Values) void {
        builtin.assertEqual(u64, values.offsets.length + values.offsets.available, values.offsets.capacity);
        builtin.assertEqual(u64, values.offsets.length, values.offsets.capacity);
        builtin.assertEqual(u64, values.offsets.available, 0);
        builtin.assertEqual(u64, values.addresses.next, values.addresses.finish);
    }
    fn assertEmpty(values: Values) void {
        builtin.assertEqual(u64, values.offsets.length + values.offsets.available, values.offsets.capacity);
        builtin.assertEqual(u64, values.offsets.length, 0);
        builtin.assertEqual(u64, values.offsets.available, values.offsets.capacity);
        builtin.assertEqual(u64, values.offsets.next, values.offsets.start);
    }
    fn assertConsistent(values: Values) void {
        builtin.assertNotEqual(u64, 0, values.addresses.low);
        builtin.assertAboveOrEqual(u64, values.addresses.start, values.addresses.low);
        builtin.assertAboveOrEqual(u64, values.addresses.next, values.addresses.start);
        builtin.assertAboveOrEqual(u64, values.addresses.finish, values.addresses.next);
        builtin.assertAboveOrEqual(u64, values.addresses.high, values.addresses.finish);
        values.offsets.assertEqual(values.addresses.offsets());
    }
    fn assertEqualMemory(s_values: Values, t_values: Values) void {
        const min_length: u64 = @min(s_values.offsets.length, t_values.offsets.length);
        const max_length: u64 = @min(s_values.offsets.length, t_values.offsets.length);
        builtin.assertEqual(u64, min_length, max_length);
        const s_memory: []u8 = @intToPtr([*]u8, s_values.addresses.start)[0..max_length];
        const t_memory: []u8 = @intToPtr([*]u8, t_values.addresses.start)[0..max_length];
        var byte_offset: u64 = 0;
        while (byte_offset != max_length) : (byte_offset += 1) {
            builtin.assertEqual(u8, s_memory[byte_offset], t_memory[byte_offset]);
        }
    }
    fn requestCount(values: Values) u64 {
        return values.mem.amountToCountOfLength(amount, values.factor);
    }
    fn requestBytes(values: Values) u64 {
        return values.mem.amountToBytesOfLength(amount, values.factor);
    }
    fn requiredCount(values: Values) u64 {
        const s_amt: mem.Amount = .{ .bytes = values.capacity };
        return mem.amountToCountOfLength(s_amt, values.factor);
    }
    fn requiredBytes(values: Values) u64 {
        const s_amt: mem.Amount = .{ .bytes = values.capacity };
        return mem.amountToBytesOfLength(s_amt, values.factor);
    }
    const Graphics = struct {
        fn show(values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            _ = values;
            if (array.impl.length() != src_fmt.formatLength()) {
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showWithReference(s_values: Values, t_values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            s_values.addresses.showWithReferenceWrite(t_values.addresses, &array);
            s_values.offsets.showWithReferenceWrite(t_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showTwo(s_values: Values, t_values: Values, src: builtin.SourceLocation) void {
            var array: PrintArray = .{};
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            array.writeFormat(src_fmt);
            s_values.addresses.showTwo(t_values.addresses, &array);
            s_values.offsets.showTwo(t_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showFour(s_values: Values, t_values: Values, u_values: Values, v_values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            s_values.addresses.showFour(t_values.addresses, u_values.addresses, v_values.addresses, &array);
            s_values.offsets.showFour(t_values.offsets, u_values.offsets, v_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
    };
};
pub const RWPPXValues = extern struct {
    addresses: Addresses,
    offsets: Offsets,
    const Values = @This();
    const Addresses = RWPPAddresses;
    const Offsets = RWPPOffsets;
    fn assertEqualMemory(s_values: Values, t_values: Values) void {
        builtin.assertEqual(u64, s_values.capacity, t_values.capacity);
        const s_memory: []u8 = @intToPtr([*]u8, s_values.start)[0..s_values.capacity];
        const t_memory: []u8 = @intToPtr([*]u8, t_values.start)[0..t_values.capacity];
        for (s_memory) |value, index| {
            builtin.assertEqual(u8, value, t_memory[index]);
        }
    }
    fn assertConsistent(values: Values) void {
        const offsets_0: Offsets = values.offsets;
        const offsets_1: Offsets = values.addresses.offsets();
        offsets_0.assertEqual(offsets_1);
    }
    const Graphics = struct {
        fn show(values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            values.addresses.show();
            values.offsets.show();
            if (array.impl.length() != src_fmt.formatLength()) {
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showWithReference(s_values: Values, t_values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            s_values.addresses.showWithReferenceWrite(t_values.addresses, &array);
            s_values.offsets.showWithReferenceWrite(t_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
        fn showFour(s_values: Values, t_values: Values, u_values: Values, v_values: Values, src: builtin.SourceLocation) void {
            const src_fmt: fmt.SourceLocationFormat = fmt.src(src, @returnAddress());
            var array: PrintArray = .{};
            array.writeFormat(src_fmt);
            s_values.addresses.showFour(t_values.addresses, u_values.addresses, v_values.addresses, &array);
            s_values.offsets.showFour(t_values.offsets, u_values.offsets, v_values.offsets, &array);
            if (array.impl.length() != src_fmt.formatLength()) {
                array.writeOne('\n');
                file.noexcept.write(2, array.readAll());
            }
        }
    };
};
pub fn RWSTestPair(comptime impl_type: type) type {
    return struct {
        impl: impl_type,
        values: Values,
        const Pair = @This();
        const Values = RWDValues;
        const factor = impl_type.high_alignment;
        fn memoise(impl: impl_type, n_amt: mem.Amount) Values {
            const ret: Values = .{
                .offsets = .{
                    .bytes = impl.bytes(),
                    .capacity = impl.capacity(),
                },
                .addresses = .{
                    .low = impl.low(),
                    .start = impl.start(),
                    .finish = impl.finish(),
                    .high = impl.high(),
                },
                .count = mem.amountToCountOfLength(n_amt, impl_type.high_alignment),
            };
            ret.assertConsistent();
            return ret;
        }
        fn construct(impl: impl_type, values: Values) Pair {
            return Pair{ .impl = impl, .values = values };
        }
        fn modify(pair: *Pair, n_amt: ?mem.Amount, src: builtin.SourceLocation) Values {
            const s_values: Values = pair.values;
            const t_values: Values = memoise(pair.impl, n_amt orelse mem.Amount{ .count = s_values.count });
            s_values.assertEqualMemory(t_values);
            pair.values = t_values;
            if (is_verbose) {
                Values.Graphics.showWithReference(s_values, t_values, src);
            }
            return s_values;
        }
        fn testAllocateOperation(allocator: *Allocator0) !Pair {
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = random.readOne(u8) }));
            defer allocator.deallocateMany(Dummy, dummy);
            if (is_verbose) announceAnalysis(impl_type);
            const impl: impl_type = try meta.wrap(allocator.allocateStatic(impl_type, .{ .count = 1 }));
            sys.noexcept.getrandom(impl.start(), impl.capacity(), sys.GRND.RANDOM);
            const values: Values = memoise(impl, .{ .count = 1 });
            return construct(impl, values);
        }
        fn testMoveOperation(pair: *Pair, allocator: *Allocator0) !Values {
            try meta.wrap(allocator.moveStatic(impl_type, &pair.impl));
            return pair.modify(null, @src());
        }
        fn testDeallocateOperation(pair: *Pair, allocator: *Allocator0) void {
            allocator.deallocateStatic(impl_type, pair.impl, .{ .count = 1 });
        }
        pub fn analyse(pair: *Pair, allocator: *Allocator0) !void {
            defer pair.testDeallocateOperation(allocator);
            pair.values.assertConsistent();
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = 256 }));
            const values_1: Values = try pair.testMoveOperation(allocator);
            allocator.deallocateMany(Dummy, dummy);
            const values_2: Values = try pair.testMoveOperation(allocator);
            if (is_verbose) {
                Values.Graphics.showTwo(values_1, values_2, @src());
            }
        }
        pub const init = testAllocateOperation;
    };
}
pub fn RWPPSTestPair(comptime impl_type: type) type {
    return struct {
        impl: impl_type,
        values: Values,
        const Pair = @This();
        const Values = RWPPDValues;
        const factor: u64 = impl_type.high_alignment;
        fn memoise(impl: impl_type, n_amt: mem.Amount) Values {
            const ret: Values = .{
                .addresses = .{
                    .low = impl.low(),
                    .start = impl.start(),
                    .next = impl.next(),
                    .finish = impl.finish(),
                    .high = impl.high(),
                },
                .offsets = .{
                    .bytes = impl.bytes(),
                    .capacity = impl.capacity(),
                    .length = impl.length(),
                    .available = impl.available(),
                },
                .count = mem.amountToCountOfLength(n_amt, impl_type.high_alignment),
            };
            ret.assertConsistent();
            return ret;
        }
        fn construct(impl: impl_type, values: Values) Pair {
            return Pair{ .impl = impl, .values = values };
        }
        fn modify(pair: *Pair, n_amt: ?mem.Amount, src: builtin.SourceLocation) Values {
            const s_values: Values = pair.values;
            const t_values: Values = memoise(pair.impl, n_amt orelse mem.Amount{ .count = s_values.count });
            s_values.assertEqualMemory(t_values);
            pair.values = t_values;
            if (is_verbose) {
                Values.Graphics.showWithReference(s_values, t_values, src);
            }
            return s_values;
        }
        fn testAllocateOperation(allocator: *Allocator0) !Pair {
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = random.readOne(u8) }));
            defer allocator.deallocateMany(Dummy, dummy);
            if (is_verbose) announceAnalysis(impl_type);
            const n_amt: mem.Amount = .{ .count = 1 };
            const impl: impl_type = try meta.wrap(allocator.allocateStatic(impl_type, n_amt));
            const values: Values = memoise(impl, n_amt);
            return construct(impl, values);
        }
        fn testMoveOperation(pair: *Pair, allocator: *Allocator0) !Values {
            try meta.wrap(allocator.moveStatic(impl_type, &pair.impl));
            return pair.modify(pair.values.amount(), @src());
        }
        fn testDeallocateOperation(pair: *Pair, allocator: *Allocator0) void {
            allocator.deallocateStatic(impl_type, pair.impl, .{ .count = 1 });
        }
        pub fn analyse(pair: *Pair, allocator: *Allocator0) !void {
            defer pair.testDeallocateOperation(allocator);
            pair.values.assertConsistent();
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = 256 }));
            const values_1: Values = try pair.testMoveOperation(allocator);
            allocator.deallocateMany(Dummy, dummy);
            const values_2: Values = try pair.testMoveOperation(allocator);
            if (is_verbose) {
                Values.Graphics.showTwo(values_1, values_2, @src());
            }
        }
        pub const init = testAllocateOperation;
    };
}
pub fn RWDTestPair(comptime impl_type: type) type {
    return struct {
        impl: impl_type,
        values: Values,
        const Pair = @This();
        const Values = RWDValues;
        const factor = impl_type.high_alignment;
        fn testAllocateOperation(allocator: *Allocator0) !Pair {
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = random.readOne(u8) }));
            defer allocator.deallocateMany(Dummy, dummy);
            if (is_verbose) announceAnalysis(impl_type);
            const n_amt: mem.Amount = .{ .count = getBetween(u16, 8, 2048) };
            const impl: impl_type = try meta.wrap(allocator.allocateMany(impl_type, n_amt));
            const values: Values = memoise(impl, n_amt);
            return construct(impl, values);
        }
        fn memoise(impl: impl_type, n_amt: mem.Amount) Values {
            const ret: Values = .{
                .offsets = .{
                    .bytes = impl.bytes(),
                    .capacity = impl.capacity(),
                },
                .addresses = .{
                    .low = impl.low(),
                    .start = impl.start(),
                    .finish = impl.finish(),
                    .high = impl.high(),
                },
                .count = mem.amountToCountOfLength(n_amt, impl_type.high_alignment),
            };
            ret.assertConsistent();
            return ret;
        }
        fn construct(impl: impl_type, values: Values) Pair {
            return Pair{ .impl = impl, .values = values };
        }
        fn modify(pair: *Pair, n_amt: ?mem.Amount, src: builtin.SourceLocation) Values {
            const s_values: Values = pair.values;
            const t_values: Values = memoise(pair.impl, n_amt orelse mem.Amount{ .count = s_values.count });
            s_values.assertEqualMemory(t_values);
            pair.values = t_values;
            if (is_verbose) {
                Values.Graphics.showWithReference(s_values, t_values, src);
            }
            return s_values;
        }
        fn testResizeAboveOperation(pair: *Pair, allocator: *Allocator0, n_amt: mem.Amount) !Values {
            try meta.wrap(allocator.resizeManyAbove(impl_type, &pair.impl, n_amt));
            return pair.modify(n_amt, @src());
        }
        fn testResizeBelowOperation(pair: *Pair, allocator: *Allocator0, n_amt: mem.Amount) !Values {
            allocator.resizeManyBelow(impl_type, &pair.impl, n_amt);
            return pair.modify(n_amt, @src());
        }
        fn testMoveOperation(pair: *Pair, allocator: *Allocator0) !Values {
            try meta.wrap(allocator.moveMany(impl_type, &pair.impl));
            return pair.modify(null, @src());
        }
        fn testDeallocateOperation(pair: *Pair, allocator: *Allocator0) void {
            allocator.deallocateMany(impl_type, pair.impl);
        }
        pub fn analyse(pair: *Pair, allocator: *Allocator0) !void {
            defer pair.testDeallocateOperation(allocator);
            pair.values.assertConsistent();
            const amt_1: mem.Amount = .{ .count = getBetween(u16, pair.values.count, pair.values.count * 2) };
            const values_0: Values = try pair.testResizeAboveOperation(allocator, amt_1);
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = 256 }));
            const values_1: Values = try pair.testMoveOperation(allocator);
            allocator.deallocateMany(Dummy, dummy);
            const values_2: Values = try pair.testMoveOperation(allocator);
            const values_3: Values = try pair.testResizeBelowOperation(allocator, values_0.amount());
            if (is_verbose) {
                Values.Graphics.showFour(values_0, values_1, values_2, values_3, @src());
            }
        }
        pub const init = testAllocateOperation;
    };
}
pub fn RWPPDTestPair(comptime impl_type: type) type {
    return struct {
        impl: impl_type,
        values: Values,
        const Pair = @This();
        const Values = RWPPDValues;
        const factor: u64 = impl_type.high_alignment;
        fn memoise(impl: impl_type, n_amt: mem.Amount) Values {
            const ret: Values = .{
                .addresses = .{
                    .low = impl.low(),
                    .start = impl.start(),
                    .next = impl.next(),
                    .finish = impl.finish(),
                    .high = impl.high(),
                },
                .offsets = .{
                    .bytes = impl.bytes(),
                    .capacity = impl.capacity(),
                    .length = impl.length(),
                    .available = impl.available(),
                },
                .count = mem.amountToCountOfLength(n_amt, impl_type.high_alignment),
            };
            ret.assertConsistent();
            return ret;
        }
        fn construct(impl: impl_type, values: Values) Pair {
            return Pair{ .impl = impl, .values = values };
        }
        fn modify(pair: *Pair, n_amt: ?mem.Amount, src: builtin.SourceLocation) Values {
            const s_values: Values = pair.values;
            const t_values: Values = memoise(pair.impl, n_amt orelse mem.Amount{ .count = s_values.count });
            pair.values = t_values;
            if (is_verbose) {
                Values.Graphics.showWithReference(s_values, t_values, src);
            }
            return s_values;
        }
        fn testAllocateOperation(allocator: *Allocator0) !Pair {
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = random.readOne(u8) }));
            defer allocator.deallocateMany(Dummy, dummy);
            if (is_verbose) announceAnalysis(impl_type);
            const n_amt: mem.Amount = .{ .count = getBetween(u7, 8, null) };
            const impl: impl_type = try meta.wrap(allocator.allocateMany(impl_type, n_amt));
            const values: Values = memoise(impl, n_amt);
            return construct(impl, values);
        }
        fn testResizeAboveOperation(pair: *Pair, allocator: *Allocator0, n_amt: mem.Amount) !Values {
            try meta.wrap(allocator.resizeManyAbove(impl_type, &pair.impl, n_amt));
            return pair.modify(n_amt, @src());
        }
        fn testResizeBelowOperation(pair: *Pair, allocator: *Allocator0, n_amt: mem.Amount) !Values {
            allocator.resizeManyBelow(impl_type, &pair.impl, n_amt);
            return pair.modify(n_amt, @src());
        }
        fn testMoveOperation(pair: *Pair, allocator: *Allocator0) !Values {
            try meta.wrap(allocator.moveMany(impl_type, &pair.impl));
            return pair.modify(pair.values.amount(), @src());
        }
        fn testDeallocateOperation(pair: *Pair, allocator: *Allocator0) void {
            allocator.deallocateMany(impl_type, pair.impl);
        }
        pub fn analyse(pair: *Pair, allocator: *Allocator0) !void {
            defer pair.testDeallocateOperation(allocator);
            pair.values.assertConsistent();
            const amt_1: mem.Amount = .{ .count = getBetween(u16, pair.values.count, pair.values.count * 2) };
            const values_0: Values = try pair.testResizeAboveOperation(allocator, amt_1);
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = 256 }));
            const values_1: Values = try pair.testMoveOperation(allocator);
            allocator.deallocateMany(Dummy, dummy);
            const values_2: Values = try pair.testMoveOperation(allocator);
            const values_3: Values = try pair.testResizeBelowOperation(allocator, values_0.amount());
            if (is_verbose) {
                Values.Graphics.showFour(values_0, values_1, values_2, values_3, @src());
            }
        }
        pub const init = testAllocateOperation;
    };
}
pub fn RWPPXTestPair(comptime impl_type: type) type {
    return struct {
        impl: impl_type,
        values: RWPPXValues,
        const Pair = @This();
        const Values = RWPPXValues;
        const factor: u64 = impl_type.high_alignment;
        fn memoise(impl: impl_type, allocator: Allocator0) Values {
            return .{
                .addresses = .{
                    .low = impl.low(allocator),
                    .start = impl.start(allocator),
                    .next = impl.next(),
                    .finish = impl.finish(allocator),
                    .high = impl.high(allocator),
                },
                .offsets = .{
                    .bytes = impl.bytes(allocator),
                    .capacity = impl.capacity(allocator),
                    .length = impl.length(allocator),
                    .available = impl.available(allocator),
                },
            };
        }
        fn construct(impl: impl_type, values: Values) Pair {
            return Pair{ .impl = impl, .values = values };
        }
        fn modify(pair: *Pair, allocator: Allocator0, src: builtin.SourceLocation) Values {
            const s_values: Values = pair.values;
            const t_values: Values = memoise(pair.impl, allocator);
            pair.values = t_values;
            if (is_verbose) {
                Values.Graphics.showWithReference(s_values, t_values, src);
            }
            return s_values;
        }
        pub fn analyse(pair: *Pair, allocator: *Allocator0) !void {
            defer pair.testDeallocateOperation(allocator);
            const next_unallocated_byte_address: u64 = allocator.next();
            defer allocator.ub_addr = next_unallocated_byte_address;
            const values_0: Values = pair.testDefineOperation(allocator.*);
            pair.values.assertConsistent();
            const values_1: Values = try pair.testResizeOperation(allocator, .{ .count = @max(random.readOne(u8), 1) });
            pair.values.assertConsistent();
            _ = values_0;
            _ = values_1;
        }
        fn testAllocateOperation(allocator: *Allocator0) !Pair {
            var dummy: Dummy = try meta.wrap(allocator.allocateMany(Dummy, .{ .count = random.readOne(u8) }));
            defer allocator.deallocateMany(Dummy, dummy);
            if (is_verbose) announceAnalysis(impl_type);
            const impl: impl_type = allocator.allocateHolder(impl_type);
            const values: Values = memoise(impl, allocator.*);
            return construct(impl, values);
        }
        fn testResizeOperation(pair: *Pair, allocator: *Allocator0, n_amt: mem.Amount) !Values {
            try meta.wrap(allocator.resizeHolderAbove(impl_type, &pair.impl, n_amt));
            return modify(pair, allocator.*, @src());
        }
        fn testDeallocateOperation(pair: *Pair, allocator: *Allocator0) void {
            allocator.deallocateHolder(impl_type, pair.impl);
        }
        fn testDefineOperation(pair: *Pair, allocator: Allocator0) Values {
            const amt: mem.Amount = .{ .count = @max(random.readOne(u8), 1) };
            pair.impl.define(mem.amountToBytesOfLength(amt, factor));
            pair.values.assertConsistent();
            return modify(pair, allocator, @src());
        }
        pub const init = testAllocateOperation;
    };
}
const Specifications = struct {
    static: []const type = meta.empty,
    dynamic: []const type = meta.empty,
    parametric: []const type = meta.empty,
};
const specifications: Specifications = blk: {
    var tmp: Specifications = .{};
    for (mem.specifications) |Specification| {
        if (@hasField(Specification, "bytes") or @hasField(Specification, "count")) {
            tmp.static = meta.concat(type, tmp.static, Specification);
        } else if (@hasField(Specification, "Allocator")) {
            tmp.parametric = meta.concat(type, tmp.parametric, Specification);
        } else {
            tmp.dynamic = meta.concat(type, tmp.dynamic, Specification);
        }
    }
    break :blk tmp;
};
fn manifestStatic(comptime types: []const type) []const type {
    @setEvalBranchQuota(5_000);
    var impl_types: []const type = meta.empty;
    inline for (types) |child| {
        const low_alignment: u64 = @alignOf(child);
        inline for (specifications.static) |impl_typeSpec| {
            const l_spec: impl_typeSpec = comptime blk: {
                const count: u64 = 512 / @sizeOf(child);
                if (@hasField(impl_typeSpec, "child") and @hasField(impl_typeSpec, "sentinel")) {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .sentinel = &@as(child, 0),
                            .count = count,
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .sentinel = &@as(child, 0),
                            .count = count,
                        };
                    }
                } else if (@hasField(impl_typeSpec, "child")) {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .count = count,
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .count = count,
                        };
                    }
                } else {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .low_alignment = low_alignment,
                            .bytes = @sizeOf(child) * count,
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .low_alignment = low_alignment,
                            .bytes = @sizeOf(child) * count,
                        };
                    }
                }
            };
            inline for (impl_typeSpec.implementations) |l_fn_struct| {
                const impl_type: type = l_fn_struct(l_spec);
                if (@hasField(impl_type, "up_word")) {
                    continue;
                }
                if (!@hasField(impl_type, "utility")) {
                    continue;
                }
                if (@hasField(impl_type, "auto")) {
                    continue;
                }
                const unit_aligned_is: bool = @hasDecl(impl_type, "unit_alignment");
                const unit_aligned_ought: bool = (if (unit_aligned_is)
                    impl_type.unit_alignment
                else
                    impl_type.low_alignment) == Allocator0.allocator_spec.options.unit_alignment;
                if ((unit_aligned_is and unit_aligned_ought) or
                    (!unit_aligned_is and !unit_aligned_ought))
                {
                    impl_types = meta.concat(type, impl_types, impl_type);
                }
            }
        }
    }
    return impl_types;
}
fn manifestParametric(comptime types: []const type) []const type {
    var impl_types: []const type = meta.empty;
    inline for (types) |child| {
        const low_alignment: u64 = @alignOf(child);
        inline for (specifications.parametric) |LSpec| {
            const l_spec: LSpec = comptime blk: {
                if (@hasField(LSpec, "child") and @hasField(LSpec, "sentinel")) {
                    break :blk .{ .Allocator = Allocator0, .child = child, .low_alignment = low_alignment, .sentinel = &@as(child, 0) };
                } else if (@hasField(LSpec, "child")) {
                    break :blk .{ .Allocator = Allocator0, .child = child, .low_alignment = low_alignment };
                } else {
                    break :blk .{ .Allocator = Allocator0, .low_alignment = low_alignment, .high_alignment = @sizeOf(child) };
                }
            };
            inline for (LSpec.implementations) |l_fn_struct| {
                const impl_type: type = l_fn_struct(l_spec);
                const unit_aligned_is: bool = @hasDecl(impl_type, "unit_alignment");
                const unit_aligned_ought: bool = (if (unit_aligned_is)
                    impl_type.unit_alignment
                else
                    impl_type.low_alignment) == Allocator0.allocator_spec.options.unit_alignment;
                if ((unit_aligned_is and unit_aligned_ought) or
                    (!unit_aligned_is and !unit_aligned_ought))
                {
                    impl_types = meta.concat(type, impl_types, impl_type);
                }
            }
        }
    }
    return impl_types;
}
fn manifestDynamic(comptime types: []const type) []const type {
    @setEvalBranchQuota(~@as(u32, 0));
    var impl_types: []const type = meta.empty;
    inline for (types) |child| {
        const low_alignment: u64 = @alignOf(child);
        inline for (specifications.dynamic) |impl_typeSpec| {
            const l_spec: impl_typeSpec = comptime blk: {
                if (@hasField(impl_typeSpec, "child") and @hasField(impl_typeSpec, "sentinel")) {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .sentinel = &@as(child, 0),
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .sentinel = &@as(child, 0),
                        };
                    }
                } else if (@hasField(impl_typeSpec, "child")) {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .child = child,
                            .low_alignment = low_alignment,
                        };
                    }
                } else {
                    if (@hasField(impl_typeSpec, "arena_index")) {
                        break :blk .{
                            .low_alignment = low_alignment,
                            .high_alignment = @sizeOf(child),
                            .arena_index = Allocator0.arena_index,
                        };
                    } else {
                        break :blk .{
                            .low_alignment = low_alignment,
                            .high_alignment = @sizeOf(child),
                        };
                    }
                }
            };
            inline for (impl_typeSpec.implementations) |l_fn_struct| {
                const impl_type: type = l_fn_struct(l_spec);
                const unit_aligned_is: bool = @hasDecl(impl_type, "unit_alignment");
                const unit_aligned_ought: bool = (if (unit_aligned_is)
                    impl_type.unit_alignment
                else
                    impl_type.low_alignment) == Allocator0.allocator_spec.options.unit_alignment;
                if ((unit_aligned_is and unit_aligned_ought) or
                    (!unit_aligned_is and !unit_aligned_ought))
                {
                    impl_types = meta.concat(type, impl_types, impl_type);
                }
            }
        }
    }
    return impl_types;
}
fn analyseRWPPStaticReference(allocator: *Allocator0, comptime impl_type: type) anyerror!void {
    const Pair = RWPPSTestPair(impl_type);
    var pair: Pair = try Pair.init(allocator);
    try pair.analyse(allocator);
}
fn analyseRWStaticReference(allocator: *Allocator0, comptime impl_type: type) anyerror!void {
    const Pair = RWSTestPair(impl_type);
    var pair: Pair = try Pair.init(allocator);
    try pair.analyse(allocator);
}
fn analyseStaticReferences(allocator: *Allocator0, mode: ModeSet, structure: StructureSet) !void {
    @setEvalBranchQuota(5_000);
    inline for (static_impl_types) |impl_type| {
        const b0: bool = @hasDecl(impl_type, "next");
        const b1: bool = @hasDecl(impl_type, "child");
        const function = if (b0) analyseRWPPStaticReference else analyseRWStaticReference;
        if ((if (b0) (mode == .ReadWritePushPop or mode == .Both) else (mode == .ReadWrite or mode == .Both)) and
            (if (b1) (structure == .Structured or structure == .Both) else (structure == .Unstructured or structure == .Both)))
        {
            try @call(.auto, function, .{ allocator, impl_type });
        }
    }
}
fn analyseRWDynamicReference(allocator: *Allocator0, comptime impl_type: type) anyerror!void {
    const Pair = RWDTestPair(impl_type);
    var pair: Pair = try Pair.init(allocator);
    try pair.analyse(allocator);
}
fn analyseRWPPDynamicReference(allocator: *Allocator0, comptime impl_type: type) anyerror!void {
    const Pair = RWPPDTestPair(impl_type);
    var pair: Pair = try Pair.init(allocator);
    try pair.analyse(allocator);
}
fn analyseDynamicReferences(allocator: *Allocator0, mode: ModeSet, structure: StructureSet) !void {
    const next: u64 = allocator.next();
    defer allocator.ub_addr = next;
    @setEvalBranchQuota(5_000);
    inline for (dynamic_impl_types) |impl_type| {
        const b0: bool = @hasDecl(impl_type, "next");
        const b1: bool = @hasDecl(impl_type, "child");
        const function = if (b0) analyseRWPPDynamicReference else analyseRWDynamicReference;
        if ((if (b0) (mode == .ReadWritePushPop or mode == .Both) else (mode == .ReadWrite or mode == .Both)) and
            (if (b1) (structure == .Structured or structure == .Both) else (structure == .Unstructured or structure == .Both)))
        {
            try @call(.auto, function, .{ allocator, impl_type });
        }
    }
}
fn analyseRWPPParametricReference(allocator: *Allocator0, comptime impl_type: type) anyerror!void {
    const Pair = RWPPXTestPair(impl_type);
    var pair: Pair = try Pair.init(allocator);
    try pair.analyse(allocator);
}
fn analyseParametricReferences(allocator: *Allocator0, structure: StructureSet) !void {
    @setEvalBranchQuota(5_000);
    inline for (parametric_impl_types) |impl_type| {
        if (@hasDecl(impl_type, "child")) {
            if (structure == .Structured or structure == .Both) {
                try analyseRWPPParametricReference(allocator, impl_type);
            }
        } else {
            if (structure == .Unstructured or structure == .Both) {
                try analyseRWPPParametricReference(allocator, impl_type);
            }
        }
    }
}
pub fn main() !void {
    var address_space: builtin.AddressSpace = .{};
    var repeat: u64 = 0;
    var allocator: Allocator0 = try Allocator0.init(&address_space);
    try allocator.map(65536);

    defer allocator.deinit(&address_space);
    while (repeat != 1) : (repeat += 1) {
        try analyseStaticReferences(&allocator, .Both, .Both);
        try analyseParametricReferences(&allocator, .Both);
        try analyseDynamicReferences(&allocator, .Both, .Both);
    }
}
