const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

pub const RegularAddressSpaceSpec = RegularMultiArena;
pub const DiscreteAddressSpaceSpec = DiscreteMultiArena;

pub const ArenaOptions = extern struct {
    thread_safe: bool = false,
};
pub const Arena = struct {
    lb_addr: u64,
    up_addr: u64,
    options: ArenaOptions = .{},
    pub fn low(arena: Arena) u64 {
        return arena.lb_addr;
    }
    pub fn high(arena: Arena) u64 {
        return arena.up_addr;
    }
    pub fn capacity(arena: Arena) u64 {
        return arena.up_addr - arena.lb_addr;
    }
    fn construct(lb_addr: u64, up_addr: u64) Arena {
        return .{
            .lb_addr = lb_addr,
            .up_addr = up_addr,
        };
    }
    pub const Intersection = struct {
        l: Arena,
        x: Arena,
        h: Arena,
    };
    pub fn intersection2(s_arena: Arena, t_arena: Arena) ?Intersection {
        if (intersection(s_arena, t_arena)) |x_arena| {
            return .{
                .l = .{
                    .lb_addr = @min(t_arena.lb_addr, s_arena.lb_addr),
                    .up_addr = x_arena.lb_addr,
                    .options = if (s_arena.lb_addr < t_arena.lb_addr)
                        s_arena.options
                    else
                        t_arena.options,
                },
                .x = x_arena,
                .h = .{
                    .lb_addr = x_arena.up_addr,
                    .up_addr = @max(s_arena.up_addr, t_arena.up_addr),
                    .options = if (t_arena.up_addr > s_arena.up_addr)
                        t_arena.options
                    else
                        s_arena.options,
                },
            };
        }
        return null;
    }
    pub fn intersection(s_arena: Arena, t_arena: Arena) ?Arena {
        if (builtin.int2v(
            bool,
            t_arena.up_addr - 1 < s_arena.lb_addr,
            s_arena.up_addr - 1 < t_arena.lb_addr,
        )) {
            return null;
        }
        return .{
            .lb_addr = @max(s_arena.lb_addr, t_arena.lb_addr),
            .up_addr = @min(s_arena.up_addr, t_arena.up_addr),
            .options = .{
                .thread_safe = builtin.int2v(
                    bool,
                    s_arena.options.thread_safe,
                    t_arena.options.thread_safe,
                ),
            },
        };
    }
};
pub const ArenaReference = struct {
    index: comptime_int,
    options: ?ArenaOptions = null,
    fn arena(comptime arena_ref: ArenaReference, comptime AddressSpace: type) Arena {
        return AddressSpace.arena(arena_ref.index);
    }
};
const SuperSpace = struct {
    AddressSpace: type,
    list: []const ArenaReference,
};
// Maybe make generic on Endian.
// Right now it is difficult to get Zig vectors to produce consistent results,
// so this is not an option.
pub fn DiscreteBitSet(comptime bits: u16) type {
    const real_bits: u16 = meta.alignAW(bits);
    if (bits != real_bits) {
        return DiscreteBitSet(real_bits);
    }
    return extern struct {
        bits: Data = if (data_info == .Array) [1]usize{0} ** data_info.Array.len else 0,
        const BitSet: type = @This();
        const Data: type = meta.UniformData(bits);
        const Word: type = if (data_info == .Array) data_info.Array.child else Data;
        const Index: type = meta.LeastRealBitSize(bits);
        const word_size: u8 = @bitSizeOf(usize);
        const data_info: builtin.Type = @typeInfo(Data);
        pub fn positionToShiftAmount(pos: Index) u8 {
            if (data_info == .Array) {
                return builtin.sub(u8, word_size - 1, builtin.rem(u8, pos, word_size));
            } else {
                return builtin.sub(u8, data_info.Int.bits - 1, pos);
            }
        }
        pub fn set(bit_set: *BitSet, pos: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, positionToShiftAmount(pos));
            if (data_info == .Array) {
                bit_set.bits[pos / word_size] |= bit_mask;
            } else {
                bit_set.bits |= bit_mask;
            }
        }
        pub fn unset(bit_set: *BitSet, pos: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, positionToShiftAmount(pos));
            if (data_info == .Array) {
                bit_set.bits[pos / word_size] &= ~bit_mask;
            } else {
                bit_set.bits &= ~bit_mask;
            }
        }
        pub fn check(bit_set: BitSet, pos: Index) bool {
            const bit_mask: Word = builtin.shl(Word, 1, positionToShiftAmount(pos));
            if (data_info == .Array) {
                return bit_set.bits[pos / word_size] & bit_mask != 0;
            } else {
                return bit_set.bits & bit_mask != 0;
            }
        }
    };
}
pub fn ThreadSafeSet(comptime divisions: u16) type {
    return extern struct {
        bytes: Data = .{0} ** divisions,
        const SafeSet: type = @This();
        const Data: type = [divisions]u8;
        const Index: type = meta.LeastRealBitSize(divisions);
        pub fn set(safe_set: *SafeSet, index: Index) void {
            safe_set.bytes[index] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: Index) void {
            safe_set.bytes[index] = 0;
        }
        pub fn atomicSet(safe_set: *SafeSet, index: Index) bool {
            return asm volatile (
                \\mov           $0,     %al
                \\mov           $255,   %dl
                \\lock cmpxchg  %dl,    %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&safe_set.bytes[index]),
                : "rax", "rdx", "memory"
            );
        }
        pub fn atomicUnset(safe_set: *SafeSet, index: Index) bool {
            return asm volatile (
                \\mov           $255,   %al
                \\mov           $0,     %dl
                \\lock cmpxchg  %dl,    %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&safe_set.bytes[index]),
                : "rax", "rdx", "memory"
            );
        }
        pub fn check(safe_set: SafeSet, index: Index) bool {
            return safe_set.bytes[index] == 255;
        }
    };
}
fn GenericMultiSet(
    comptime spec: DiscreteAddressSpaceSpec,
    comptime directory: DiscreteAddressSpaceSpec.Directory(spec),
    comptime Fields: type,
) type {
    return extern struct {
        fields: Fields = .{},
        const MultiSet: type = @This();
        const Index: type = DiscreteAddressSpaceSpec.Index(spec);
        pub const params: struct { @TypeOf(directory), type } = .{ directory, Fields };
        pub fn set(multi_set: *MultiSet, comptime index: Index) void {
            return multi_set.fields[directory[index].field_index].set(directory[index].arena_index);
        }
        pub fn unset(multi_set: *MultiSet, comptime index: Index) void {
            return multi_set.fields[directory[index].field_index].unset(directory[index].arena_index);
        }
        pub fn atomicSet(multi_set: *MultiSet, comptime index: Index) bool {
            return multi_set.fields[directory[index].field_index].atomicSet(directory[index].arena_index);
        }
        pub fn atomicUnset(multi_set: *MultiSet, comptime index: Index) bool {
            return multi_set.fields[directory[index].field_index].atomicUnset(directory[index].arena_index);
        }
        fn check(multi_set: MultiSet, comptime index: Index) bool {
            return multi_set.fields[directory[index].field_index].check(directory[index].arena_index);
        }
    };
}
pub const DiscreteMultiArena = struct {
    list: []const Arena,
    super_space: ?SuperSpace = null,
    sub_space: ?[]type = null,
    label: ?[]const u8 = null,
    const Specification: type = @This();
    fn Index(comptime spec: Specification) type {
        return meta.LeastRealBitSize(spec.list.len);
    }
    fn Directory(comptime spec: Specification) type {
        return [spec.list.len]struct { field_index: Index(spec), arena_index: Index(spec) };
    }
    fn Implementation(comptime spec: Specification) type {
        var directory: Directory(spec) = undefined;
        var fields: []const builtin.StructField = meta.empty;
        var thread_safe_state: bool = spec.list[0].options.thread_safe;
        var arena_index: Index(spec) = 0;
        for (spec.list) |arena, index| {
            if (thread_safe_state and !arena.options.thread_safe) {
                const T: type = ThreadSafeSet(arena_index + 1);
                fields = meta.concat(builtin.StructField, fields, meta.structField(T, builtin.fmt.ci(fields.len), .{}));
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else if (!thread_safe_state and arena.options.thread_safe) {
                const T: type = DiscreteBitSet(arena_index + 1);
                fields = meta.concat(builtin.StructField, fields, meta.structField(T, builtin.fmt.ci(fields.len), .{}));
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else {
                directory[index] = .{ .arena_index = arena_index, .field_index = fields.len };
                arena_index += 1;
            }
            thread_safe_state = arena.options.thread_safe;
        }
        if (thread_safe_state) {
            const T: type = ThreadSafeSet(arena_index + 1);
            fields = meta.concat(builtin.StructField, fields, meta.structField(T, builtin.fmt.ci(fields.len), .{}));
        } else {
            const T: type = DiscreteBitSet(arena_index + 1);
            fields = meta.concat(builtin.StructField, fields, meta.structField(T, builtin.fmt.ci(fields.len), .{}));
        }
        if (fields.len == 1) {
            return fields[0].type;
        }
        var type_info: builtin.Type = meta.tupleInfo(fields);
        type_info.Struct.layout = .Extern;
        const T: type = @Type(type_info);
        return GenericMultiSet(spec, directory, T);
    }
    pub fn count(comptime spec: Specification) Index(spec) {
        return spec.list.len;
    }
    fn mapSuperList(comptime spec: Specification, comptime AddressSpace: type) []const ArenaReference {
        var super_list: []const ArenaReference = meta.empty;
        var t_index: AddressSpace.Index = 0;
        if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
            lo: while (t_index != spec.list.len) : (t_index += 1) {
                var capacity: usize = 0;
                var s_index: AddressSpace.Index = 0;
                while (s_index != AddressSpace.addr_spec.list.len) : (s_index += 1) {
                    const s_arena: Arena = AddressSpace.addr_spec.list[s_index];
                    const t_arena: Arena = spec.list[t_index];
                    if (s_arena.intersection(t_arena)) |x_arena| {
                        capacity += x_arena.capacity();
                        super_list = meta.concat(ArenaReference, super_list, .{
                            .index = s_index,
                            .options = AddressSpace.arena(s_index).options,
                        });
                    }
                    if (capacity == spec.list[t_index].capacity()) {
                        continue :lo;
                    }
                }
            }
        } else {
            var max_index: AddressSpace.Index = 0;
            var min_index: AddressSpace.Index = ~max_index;
            while (t_index != spec.list.len) : (t_index += 1) {
                min_index = builtin.min(AddressSpace.Index, min_index, AddressSpace.invert(spec.list[t_index].low()));
                max_index = builtin.max(AddressSpace.Index, max_index, AddressSpace.invert(spec.list[t_index].high() - 1));
            }
            var s_index: AddressSpace.Index = min_index;
            while (s_index <= max_index) : (s_index += 1) {
                super_list = meta.concat(ArenaReference, super_list, .{
                    .index = s_index,
                    .options = AddressSpace.arena(s_index).options,
                });
            }
        }
        return super_list;
    }
};
pub const RegularMultiArena = struct {
    lb_addr: u64 = 0,
    ab_addr: u64 = safe_zone,
    xb_addr: u64 = (1 << shift_amt),
    up_addr: u64 = (1 << shift_amt) - safe_zone,
    divisions: u64 = 8,
    alignment: u64 = page_size,
    options: ArenaOptions = .{},
    super_space: ?SuperSpace = null,
    sub_space: ?[]type = null,
    label: ?[]const u8 = null,
    const Specification = @This();
    const page_size: u16 = 4096;
    const shift_amt: u16 = @min(48, @bitSizeOf(usize)) - 1;
    const safe_zone: u64 = 0x40000000;
    fn Index(comptime spec: Specification) type {
        return meta.LeastRealBitSize(spec.divisions);
    }
    fn Implementation(comptime spec: Specification) type {
        if (spec.options.thread_safe) {
            return ThreadSafeSet(spec.divisions);
        } else {
            return DiscreteBitSet(spec.divisions);
        }
    }
    pub fn count(comptime spec: Specification) Index(spec) {
        return spec.divisions;
    }
    pub fn capacity(comptime spec: Specification) u64 {
        return builtin.sub(u64, spec.up_addr, spec.lb_addr);
    }
    fn arena(comptime spec: Specification) Arena {
        return .{
            .lb_addr = spec.lb_addr,
            .up_addr = spec.up_addr,
            .options = spec.options,
        };
    }
    fn mapSuperList(comptime spec: RegularAddressSpaceSpec, comptime AddressSpace: type) []const ArenaReference {
        const t_arena: Arena = spec.arena();
        var super_list: []const ArenaReference = meta.empty;
        if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
            var s_index: AddressSpace.Index = 0;
            while (s_index != AddressSpace.addr_spec.list.len) : (s_index += 1) {
                const s_arena: Arena = AddressSpace.addr_spec.list[s_index];
                if (s_arena.intersection(t_arena) != null) {
                    super_list = meta.concat(ArenaReference, super_list, .{
                        .index = s_index,
                        .options = spec.options,
                    });
                }
            }
        } else {
            var max_index: AddressSpace.Index = AddressSpace.invert(t_arena.high());
            var min_index: AddressSpace.Index = AddressSpace.invert(t_arena.low());
            var s_index: AddressSpace.Index = min_index;
            while (s_index <= max_index) : (s_index += 1) {
                super_list = meta.concat(super_list, .{
                    .index = s_index,
                    .options = spec.options,
                });
            }
        }
        if (isRegular(AddressSpace, super_list)) {
            return super_list;
        } else {
            @compileError("invalid sub address space spec");
        }
    }
};
pub fn isRegular(comptime AddressSpace: type, comptime list: []const ArenaReference) bool {
    var safety: ?bool = null;
    var addr: ?usize = null;
    for (list) |item| {
        if (safety) |prev| {
            if (item.options) |options| {
                if (options.thread_safe != prev) {
                    return false;
                }
            }
        } else {
            if (item.options) |options| {
                safety = options.thread_safe;
            }
        }
        if (addr) |prev| {
            if (AddressSpace.low(item.index) == prev) {
                addr = AddressSpace.high(item.index);
            } else {
                return false;
            }
        } else {
            addr = AddressSpace.high(item.index);
        }
    }
    return true;
}
/// Discrete:
/// Good:
///     * Arbitrary ranges.
///     * Maps directly to an arena.
/// Bad:
///     * Arena index must be known at compile time.
///     * Inversion is expensive.
///     * Constructing the bit set fields can be expensive at compile time.
pub fn GenericDiscreteAddressSpace(comptime spec: DiscreteAddressSpaceSpec) type {
    return extern struct {
        impl: Implementation align(8) = .{},
        const AddressSpace = @This();
        pub const Implementation: type = spec.Implementation();
        pub const Index: type = DiscreteAddressSpaceSpec.Index(spec);
        pub const addr_spec: DiscreteAddressSpaceSpec = spec;
        pub fn unset(address_space: *AddressSpace, comptime index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub fn set(address_space: *AddressSpace, comptime index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (!ret) address_space.impl.set(index);
            return !ret;
        }
        pub fn atomicUnset(address_space: *AddressSpace, comptime index: Index) bool {
            builtin.static.assert(spec.list[index].options.thread_safe);
            return address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *AddressSpace, comptime index: Index) bool {
            builtin.static.assert(spec.list[index].options.thread_safe);
            return address_space.impl.atomicSet(index);
        }
        pub fn invert(addr: usize) Index {
            var index: Index = 0;
            while (index != spec.list.len) : (index += 1) {
                if (addr >= low(index) and addr < high(index)) {
                    return index;
                }
            }
        }
        pub fn low(comptime index: Index) usize {
            return spec.list[index].low();
        }
        pub fn high(comptime index: Index) usize {
            return spec.list[index].high();
        }
        pub fn arena(comptime index: Index) Arena {
            return spec.list[index];
        }
        pub usingnamespace GenericAddressSpace(AddressSpace);
    };
}
pub fn GenericDiscreteSubAddressSpace(comptime spec: DiscreteAddressSpaceSpec, comptime AddressSpace: type) type {
    var sub_spec: DiscreteAddressSpaceSpec = spec;
    sub_spec.super_space = .{
        .AddressSpace = AddressSpace,
        .list = spec.mapSuperList(AddressSpace),
    };
    return GenericDiscreteAddressSpace(sub_spec);
}
/// Regular:
/// Good:
///     * Good locality associated with computing the begin and end addresses
///       using the arena index alone.
///     * Thread safety is all-or-nothing, therefore requesting atomic
///       operations from a thread-unsafe address space yields a compile error.
/// Bad:
///     * Poor flexibility.
///     * params results must be tightly constrained or checked.
///     * Arenas can not be independently configured.
///     * Thread safety is all-or-nothing, which increases the metadata size
///       required by each arena from 1 to 8 bits.
pub fn GenericRegularAddressSpace(comptime spec: RegularAddressSpaceSpec) type {
    return extern struct {
        impl: Implementation align(8) = .{},
        const AddressSpace = @This();
        pub const Index: type = meta.AlignSizeAW(builtin.ShiftAmount(u64));
        pub const Implementation: type = spec.Implementation();
        pub const addr_spec: RegularAddressSpaceSpec = spec;
        const capacity: usize = blk: {
            const mask: usize = spec.alignment - 1;
            const value: usize = spec.capacity() / spec.divisions;
            break :blk (value + mask) & ~mask;
        };
        pub fn unset(address_space: *AddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub fn set(address_space: *AddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (!ret) address_space.impl.set(index);
            return !ret;
        }
        pub fn atomicUnset(address_space: *AddressSpace, index: Index) bool {
            builtin.static.assert(spec.options.thread_safe);
            return address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *AddressSpace, index: Index) bool {
            builtin.static.assert(spec.options.thread_safe);
            return address_space.impl.atomicSet(index);
        }
        pub fn low(index: Index) usize {
            return @max(spec.ab_addr, spec.lb_addr + capacity * index);
        }
        pub fn high(index: Index) usize {
            return @min(spec.xb_addr, spec.lb_addr + capacity * (index + 1));
        }
        pub fn invert(addr: usize) Index {
            return @truncate(Index, addr / capacity);
        }
        pub fn arena(index: Index) Arena {
            return .{
                .lb_addr = low(index),
                .up_addr = high(index),
                .options = addr_spec.options,
            };
        }
        pub usingnamespace GenericAddressSpace(AddressSpace);
    };
}
pub fn GenericRegularSubAddressSpace(comptime spec: RegularAddressSpaceSpec, comptime AddressSpace: type) type {
    var sub_spec: RegularAddressSpaceSpec = spec;
    sub_spec.super_space = .{
        .AddressSpace = AddressSpace,
        .list = spec.mapSuperList(AddressSpace),
    };
    return GenericRegularAddressSpace(sub_spec);
}
pub const StaticAddressSpace = extern struct {
    bits: [2]u64 = .{ 0, 0 },
    const AddressSpace = @This();
    const divisions: u8 = 128;
    const alignment: u64 = 4096;
    const max_bit: u64 = 1 << 47;
    const len: u64 = blk: {
        const mask: u64 = alignment - 1;
        const value: u64 = max_bit / divisions;
        break :blk (value + mask) & ~mask;
    };
    pub const Index: type = u8;
    pub fn bitMask(index: Index) u64 {
        return mach.shl64(1, mach.cmov8(index > 63, index, index -% 64));
    }
    pub fn pointer(address_space: *AddressSpace, index: Index) *u64 {
        return mach.cmovx(index > 63, &address_space.bits[1], &address_space.bits[0]);
    }
    pub fn unset(address_space: *AddressSpace, index: Index) bool {
        const mask: u64 = bitMask(index);
        const ptr: *u64 = address_space.pointer(index);
        const ret: bool = ptr.* & mask != 0;
        if (ret) ptr.* &= ~mask;
        return ret;
    }
    pub fn set(address_space: *AddressSpace, index: Index) bool {
        const mask: u64 = bitMask(index);
        const ptr: *u64 = address_space.pointer(index);
        const ret: bool = ptr.* & mask == 0;
        if (ret) ptr.* |= mask;
        return ret;
    }
    pub fn atomicSet(address_space: *AddressSpace, index: Index) bool {
        return address_space.threads().atomicSet(index >> 3);
    }
    pub fn atomicUnset(address_space: *AddressSpace, index: Index) bool {
        return address_space.threads().atomicUnset(index >> 3);
    }
    pub fn acquire(address_space: *AddressSpace, index: Index) !void {
        if (!address_space.set(index)) {
            return error.UnderSupply;
        }
    }
    pub fn release(address_space: *AddressSpace, index: Index) !void {
        if (!address_space.unset(index)) {
            return error.OverSupply;
        }
    }
    pub fn atomicAcquire(address_space: *AddressSpace, index: Index) !void {
        if (!address_space.atomicSet(index)) {
            return error.UnderSupply;
        }
    }
    pub fn atomicRelease(address_space: *AddressSpace, index: Index) !void {
        if (!address_space.atomicUnset(index)) {
            return error.OverSupply;
        }
    }
    pub fn low(index: Index) u64 {
        return @max(0x40000000, len * index);
    }
    pub fn high(index: Index) u64 {
        return len * (index + 1);
    }
    pub fn arena(comptime index: Index) Arena {
        return .{
            .lb_addr = low(index),
            .up_addr = high(index),
            .options = .{ .thread_safe = false },
        };
    }
    pub fn invert(addr: u64) Index {
        return @intCast(Index, addr / len);
    }
    pub fn wait(address_space: *const AddressSpace) void {
        var r: u64 = 0;
        while (r != 1) {
            r = address_space.count();
        }
    }
};
fn GenericAddressSpace(comptime AddressSpace: type) type {
    return struct {
        const check_true: []const u8 = "[1]: ";
        const check_false: []const u8 = "[0]: ";
        pub fn formatWrite(address_space: AddressSpace, array: anytype) void {
            if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
                return formatWriteDiscrete(address_space, array);
            } else {
                return formatWriteRegular(address_space, array);
            }
        }
        pub fn formatLength(address_space: AddressSpace) u64 {
            if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
                return formatLengthDiscrete(address_space);
            } else {
                return formatLengthRegular(address_space);
            }
        }
        fn formatWriteRegular(address_space: AddressSpace, array: anytype) void {
            var arena_index: AddressSpace.Index = 0;
            array.writeMany(check_false);
            while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (!address_space.impl.check(arena_index)) {
                    array.writeMany(builtin.fmt.ud(AddressSpace.Index, arena_index).readAll());
                    array.writeCount(2, ", ".*);
                }
            }
            arena_index = 0;
            array.writeMany(check_true);
            while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (address_space.impl.check(arena_index)) {
                    array.writeMany(builtin.fmt.ud(AddressSpace.Index, arena_index).readAll());
                    array.writeCount(2, ", ".*);
                }
            }
        }
        fn formatLengthRegular(address_space: AddressSpace) u64 {
            var len: u64 = 0;
            var arena_index: AddressSpace.Index = 0;
            len += check_false.len;
            while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (!address_space.impl.check(arena_index)) {
                    len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                    len += 2;
                }
            }
            arena_index = 0;
            len += check_true.len;
            while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (address_space.impl.check(arena_index)) {
                    len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                    len += 2;
                }
            }
            return len;
        }
        fn formatWriteDiscrete(address_space: AddressSpace, array: anytype) void {
            comptime var arena_index: AddressSpace.Index = 0;
            array.writeMany(check_false);
            inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (!address_space.impl.check(arena_index)) {
                    array.writeMany(builtin.fmt.ud(AddressSpace.Index, arena_index).readAll());
                    array.writeCount(2, ", ".*);
                }
            }
            arena_index = 0;
            array.writeMany(check_true);
            inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (address_space.impl.check(arena_index)) {
                    array.writeMany(builtin.fmt.ud(AddressSpace.Index, arena_index).readAll());
                    array.writeCount(2, ", ".*);
                }
            }
        }
        fn formatLengthDiscrete(address_space: AddressSpace) u64 {
            var len: u64 = 0;
            comptime var arena_index: AddressSpace.Index = 0;
            len += check_true.len;
            inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (address_space.impl.check(arena_index)) {
                    len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                    len += 2;
                }
            }
            len += check_false.len;
            arena_index = 0;
            inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                if (!address_space.impl.check(arena_index)) {
                    len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                    len += 2;
                }
            }
            return len;
        }
        pub fn reserve(comptime address_space: *AddressSpace, comptime SubAddressSpace: type) SubAddressSpace {
            if (SubAddressSpace.addr_spec.super_space) |super_space| {
                comptime {
                    for (super_space.list) |ref| if (!address_space.set(ref.index)) break;
                }
            }
            return .{};
        }
    };
}
