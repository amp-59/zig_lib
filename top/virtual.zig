const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

const word_bit_size: u8 = @bitSizeOf(u64);

pub const ResourceError = error{ UnderSupply, OverSupply };
pub const ResourceErrorPolicy = builtin.InternalError(ResourceError);
pub const RegularAddressSpaceSpec = RegularMultiArena;
pub const DiscreteAddressSpaceSpec = DiscreteMultiArena;

// Maybe make generic on Endian.
// Right now it is difficult to get Zig vectors to produce consistent results,
// so this is not an option.
pub fn DiscreteBitSet(comptime elements: u16, comptime val_type: type) type {
    const val_bit_size: u16 = @bitSizeOf(val_type);
    if (val_bit_size != 1) {
        @compileError("not yet implemented");
    }
    const bits: u16 = elements * val_bit_size;
    const Data: type = meta.UniformData(bits);
    const data_info: builtin.Type = @typeInfo(Data);
    const Array = extern struct {
        bits: Data = [1]u64{0} ** data_info.Array.len,
        pub const BitSet: type = @This();
        const Word: type = data_info.Array.child;
        const Index: type = meta.LeastRealBitSize(bits);
        pub fn get(bit_set: BitSet, index: Index) bool {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            return bit_set.bits[index / word_bit_size] & bit_mask != 0;
        }
        pub fn indexToShiftAmount(index: Index) u8 {
            return builtin.sub(u8, word_bit_size -% 1, builtin.rem(u8, index, word_bit_size));
        }
        pub fn set(bit_set: *BitSet, index: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            bit_set.bits[index / word_bit_size] |= bit_mask;
        }
        pub fn unset(bit_set: *BitSet, index: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            bit_set.bits[index / word_bit_size] &= ~bit_mask;
        }
    };
    const Int = extern struct {
        bits: Data = 0,
        pub const BitSet: type = @This();
        const Word: type = Data;
        const Index: type = meta.LeastRealBitSize(bits);
        pub fn get(bit_set: BitSet, index: Index) bool {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            return bit_set.bits & bit_mask != 0;
        }
        pub fn indexToShiftAmount(index: Index) u8 {
            return builtin.sub(u8, data_info.Int.bits -% 1, index);
        }
        pub fn set(bit_set: *BitSet, index: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            bit_set.bits |= bit_mask;
        }
        pub fn unset(bit_set: *BitSet, index: Index) void {
            const bit_mask: Word = builtin.shl(Word, 1, indexToShiftAmount(index));
            bit_set.bits &= ~bit_mask;
        }
    };
    return if (data_info == .Array) Array else Int;
}
pub fn ThreadSafeSet(comptime elements: u16, comptime val_type: type) type {
    const Binary = extern struct {
        bytes: Data = .{0} ** elements,
        pub const SafeSet: type = @This();
        const Data: type = [elements]u8;
        const Index: type = meta.LeastRealBitSize(elements);
        pub fn get(safe_set: SafeSet, index: Index) bool {
            return safe_set.bytes[index] == 255;
        }
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
    };
    const Compound = extern struct {
        bytes: Data = .{@intToEnum(val_type, 0)} ** elements,
        pub const SafeSet: type = @This();
        const Data: type = [elements]val_type;
        const Index: type = meta.LeastRealBitSize(elements);
        pub fn get(safe_set: SafeSet, index: Index) val_type {
            return safe_set.bytes[index];
        }
        pub fn atomicTransform(
            safe_set: *SafeSet,
            index: Index,
            comptime if_state: val_type,
            comptime to_state: val_type,
        ) bool {
            return asm volatile (
                \\mov           %[if_state],    %al
                \\mov           %[to_state],    %dl
                \\lock cmpxchg  %dl,            %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&safe_set.bytes[index]),
                  [if_state] "i" (if_state),
                  [to_state] "i" (to_state),
                : "rax", "rdx", "memory"
            );
        }
    };
    return if (val_type == bool) Binary else Compound;
}
fn GenericMultiSet(
    comptime spec: DiscreteAddressSpaceSpec,
    comptime directory: anytype,
    comptime Fields: type,
) type {
    return (extern struct {
        fields: Fields = .{},
        pub const MultiSet: type = @This();
        const Index: type = DiscreteAddressSpaceSpec.Index(spec);
        pub fn get(multi_set: MultiSet, comptime index: Index) bool {
            const arena_index: Index = directory[index].arena_index;
            const field_index: Index = directory[index].field_index;
            return multi_set.fields[field_index].get(arena_index);
        }
        pub fn set(multi_set: *MultiSet, comptime index: Index) void {
            const arena_index: Index = directory[index].arena_index;
            const field_index: Index = directory[index].field_index;
            return multi_set.fields[field_index].set(arena_index);
        }
        pub fn unset(multi_set: *MultiSet, comptime index: Index) void {
            const arena_index: Index = directory[index].arena_index;
            const field_index: Index = directory[index].field_index;
            return multi_set.fields[field_index].unset(arena_index);
        }
        pub fn atomicSet(multi_set: *MultiSet, comptime index: Index) bool {
            const arena_index: Index = directory[index].arena_index;
            const field_index: Index = directory[index].field_index;
            return multi_set.fields[field_index].atomicSet(arena_index);
        }
        pub fn atomicUnset(multi_set: *MultiSet, comptime index: Index) bool {
            const arena_index: Index = directory[index].arena_index;
            const field_index: Index = directory[index].field_index;
            return multi_set.fields[field_index].atomicUnset(arena_index);
        }
    });
}
pub const ArenaOptions = extern struct {
    thread_safe: bool = false,
    require_map: bool = false,
    require_unmap: bool = false,
};
pub const Arena = struct {
    lb_addr: u64,
    up_addr: u64,
    options: ArenaOptions = .{},
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
            t_arena.up_addr -% 1 < s_arena.lb_addr,
            s_arena.up_addr -% 1 < t_arena.lb_addr,
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
    pub fn low(arena: Arena) u64 {
        return arena.lb_addr;
    }
    pub fn high(arena: Arena) u64 {
        return arena.up_addr;
    }
    pub fn capacity(arena: Arena) u64 {
        return arena.up_addr -% arena.lb_addr;
    }
};
pub const AddressSpaceLogging = struct {
    acquire: builtin.Logging.AcquireErrorFault = .{},
    release: builtin.Logging.ReleaseErrorFault = .{},
    map: builtin.Logging.AcquireErrorFault = .{},
    unmap: builtin.Logging.ReleaseErrorFault = .{},
};
pub const AddressSpaceErrors = struct {
    acquire: ResourceErrorPolicy = .{ .throw = error.UnderSupply },
    release: ResourceErrorPolicy = .abort,
    map: sys.ErrorPolicy = .{ .throw = sys.mmap_errors },
    unmap: sys.ErrorPolicy = .{ .abort = sys.munmap_errors },
};
pub const ArenaReference = struct {
    index: comptime_int,
    options: ?ArenaOptions = null,
    fn arena(comptime arena_ref: ArenaReference, comptime AddressSpace: type) Arena {
        return AddressSpace.arena(arena_ref.index);
    }
};
pub const DiscreteMultiArena = struct {
    label: ?[]const u8 = null,
    list: []const Arena,
    subspace: ?[]const meta.Generic = null,
    val_type: type = bool,

    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},

    pub const MultiArena: type = @This();

    fn Index(comptime multi_arena: MultiArena) type {
        return meta.LeastRealBitSize(multi_arena.list.len);
    }
    fn Directory(comptime multi_arena: MultiArena) type {
        return [multi_arena.list.len]struct {
            field_index: Index(multi_arena),
            arena_index: Index(multi_arena),
        };
    }
    pub fn Metadata(comptime multi_arena: MultiArena) type {
        var mapping_directory: [multi_arena.list.len]Index(multi_arena) = undefined;
        var bit_index: u16 = 0;
        for (multi_arena.list, 0..) |super_arena, index| {
            if (super_arena.options.require_map) {
                mapping_directory[index] = bit_index;
                bit_index +%= 1;
            }
        }
        return mapping_directory;
    }
    pub fn Implementation(comptime multi_arena: MultiArena) type {
        builtin.static.assertNotEqual(u64, multi_arena.list.len, 0);
        var directory: Directory(multi_arena) = undefined;
        var fields: []const builtin.Type.StructField = meta.empty;
        var thread_safe_state: bool = multi_arena.list[0].options.thread_safe;
        var arena_index: Index(multi_arena) = 0;
        for (multi_arena.list, 0..) |super_arena, index| {
            if (thread_safe_state and !super_arena.options.thread_safe) {
                const T: type = ThreadSafeSet(arena_index +% 1, multi_arena.val_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else if (!thread_safe_state and super_arena.options.thread_safe) {
                const T: type = DiscreteBitSet(arena_index +% 1, multi_arena.val_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else {
                directory[index] = .{ .arena_index = arena_index, .field_index = fields.len };
                arena_index +%= 1;
            }
            thread_safe_state = super_arena.options.thread_safe;
        }
        if (thread_safe_state) {
            const T: type = ThreadSafeSet(arena_index +% 1, multi_arena.val_type);
            fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
        } else {
            const T: type = DiscreteBitSet(arena_index +% 1, multi_arena.val_type);
            fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
        }
        if (fields.len == 1) {
            return fields[0].type;
        }
        var type_info: builtin.Type = meta.tupleInfo(fields);
        type_info.Struct.layout = .Extern;
        return GenericMultiSet(multi_arena, directory, @Type(type_info));
    }
    fn referSubRegular(comptime multi_arena: MultiArena, comptime sub_arena: Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var s_index: Index(multi_arena) = 0;
        while (s_index <= multi_arena.list.len) : (s_index += 1) {
            const super_arena: Arena = multi_arena.list[s_index];
            if (super_arena.low() > sub_arena.high()) {
                break;
            }
            if (super_arena.intersection(sub_arena) != null) {
                map_list = map_list ++ [1]ArenaReference{.{
                    .index = s_index,
                    .options = multi_arena.list[s_index].options,
                }};
            }
        }
        return map_list;
    }
    fn referSubDiscrete(comptime multi_arena: MultiArena, comptime sub_list: []const Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var t_index: Index(multi_arena) = 0;
        while (t_index != sub_list.len) : (t_index += 1) {
            var s_index: Index(multi_arena) = 0;
            while (s_index != multi_arena.list.len) : (s_index += 1) {
                const s_arena: Arena = multi_arena.list[s_index];
                const t_arena: Arena = sub_list[t_index];
                if (s_arena.intersection(t_arena) != null) {
                    map_list = map_list ++ [1]ArenaReference{.{
                        .index = s_index,
                        .options = multi_arena.list[s_index].options,
                    }};
                }
            }
        }
        return map_list;
    }
    pub fn capacityAll(comptime multi_arena: MultiArena) u64 {
        return builtin.sub(u64, multi_arena.up_addr, multi_arena.lb_addr);
    }
    pub fn capacityAny(comptime multi_arena: MultiArena, comptime index: Index(multi_arena)) u64 {
        return multi_arena.list[index].capacity();
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: u64) Index(multi_arena) {
        var index: Index(multi_arena) = 0;
        while (index != multi_arena.list.len) : (index += 1) {
            if (addr >= multi_arena.list[index].low() and
                addr < multi_arena.list[index].high())
            {
                return index;
            }
        }
        unreachable;
    }
    pub fn arena(comptime multi_arena: MultiArena, index: Index(multi_arena)) Arena {
        return multi_arena.list[index];
    }
    pub fn count(comptime multi_arena: MultiArena) Index(multi_arena) {
        return multi_arena.list.len;
    }
    pub fn low(comptime multi_arena: MultiArena, comptime index: Index(multi_arena)) u64 {
        return multi_arena.list[index].low();
    }
    pub fn high(comptime multi_arena: MultiArena, comptime index: Index(multi_arena)) u64 {
        return multi_arena.list[index].high();
    }
    pub fn instantiate(comptime multi_arena: MultiArena) type {
        return GenericDiscreteAddressSpace(multi_arena);
    }
    pub fn options(comptime multi_arena: MultiArena, comptime index: Index(multi_arena)) ArenaOptions {
        return multi_arena.list[index].options;
    }
};
pub const RegularMultiArena = struct {
    /// This will show up in logging.
    label: ?[]const u8 = null,
    /// Lower bound of address space. This is used when computing division
    /// length.
    lb_addr: u64 = 0,
    /// Upper bound of address space. This is used when computing division
    /// length.
    up_addr: u64 = 1 << 47,
    /// The first arena starts at this offset in the first division.
    /// This is an option to allow the largest alignment possible per division
    /// while avoiding the binary mapping in the first division.
    lb_offset: u64 = 0,
    /// The last arena ends at this offset below the end of the last division.
    up_offset: u64 = 0,

    divisions: u64 = 64,
    alignment: u64 = 4096,
    subspace: ?[]const meta.Generic = null,
    val_type: type = bool,

    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},
    options: ArenaOptions = .{},

    pub const MultiArena = @This();
    fn Index(comptime multi_arena: MultiArena) type {
        return meta.LeastRealBitSize(multi_arena.divisions);
    }
    fn Implementation(comptime multi_arena: MultiArena) type {
        if (multi_arena.options.thread_safe or
            @bitSizeOf(multi_arena.val_type) == 8)
        {
            return ThreadSafeSet(
                multi_arena.divisions + @boolToInt(multi_arena.options.require_map),
                multi_arena.val_type,
            );
        } else {
            return DiscreteBitSet(
                multi_arena.divisions + @boolToInt(multi_arena.options.require_map),
                multi_arena.val_type,
            );
        }
    }
    pub inline fn addressable_byte_address(comptime multi_arena: MultiArena) u64 {
        return mach.add64(multi_arena.lb_addr, multi_arena.lb_offset);
    }
    pub inline fn allocated_byte_address(comptime multi_arena: MultiArena) u64 {
        return multi_arena.lb_addr;
    }
    pub inline fn unallocated_byte_address(comptime multi_arena: MultiArena) u64 {
        return mach.sub64(multi_arena.up_addr, multi_arena.up_offset);
    }
    pub inline fn unaddressable_byte_address(comptime multi_arena: MultiArena) u64 {
        return multi_arena.up_addr;
    }
    pub inline fn allocated_byte_count(comptime multi_arena: MultiArena) u64 {
        return mach.sub64(unallocated_byte_address(multi_arena), allocated_byte_address(multi_arena));
    }
    pub inline fn addressable_byte_count(comptime multi_arena: MultiArena) u64 {
        return mach.sub64(unaddressable_byte_address(multi_arena), addressable_byte_address(multi_arena));
    }

    fn referSubRegular(comptime multi_arena: MultiArena, comptime sub_arena: Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var max_index: Index(multi_arena) = multi_arena.invert(sub_arena.high());
        var min_index: Index(multi_arena) = multi_arena.invert(sub_arena.low());
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index += 1) {
            map_list = meta.concat(ArenaReference, map_list, .{
                .index = s_index,
                .options = multi_arena.options,
            });
        }
        if (isRegular(multi_arena, map_list)) {
            return map_list;
        } else {
            @compileError("invalid sub address space spec");
        }
    }
    fn referSubDiscrete(comptime multi_arena: MultiArena, comptime sub_list: []const Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var max_index: Index(multi_arena) = multi_arena.invert(sub_list[sub_list.len -% 1].high());
        var min_index: Index(multi_arena) = multi_arena.invert(sub_list[0].low());
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index += 1) {
            map_list = meta.concat(ArenaReference, map_list, .{
                .index = s_index,
                .options = multi_arena.options,
            });
        }
        if (isRegular(multi_arena, map_list)) {
            return map_list;
        } else {
            @compileError("invalid sub address space spec");
        }
    }
    pub fn count(comptime multi_arena: MultiArena) Index(multi_arena) {
        return multi_arena.divisions;
    }
    pub fn capacityAll(comptime multi_arena: MultiArena) u64 {
        return mach.alignA64(multi_arena.up_addr - multi_arena.lb_addr, multi_arena.alignment);
    }
    pub fn capacityEach(comptime multi_arena: MultiArena) u64 {
        return @divExact(capacityAll(multi_arena), multi_arena.divisions);
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: u64) Index(multi_arena) {
        return @intCast(Index(multi_arena), (addr - multi_arena.lb_addr) / capacityEach(multi_arena));
    }
    pub fn low(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        const offset: u64 = capacityEach(multi_arena) * index;
        return @max(multi_arena.lb_addr + multi_arena.lb_offset, multi_arena.lb_addr + offset);
    }
    pub fn high(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        const offset: u64 = capacityEach(multi_arena) * (index + 1);
        return @min(multi_arena.up_addr - multi_arena.up_offset, multi_arena.lb_addr + offset);
    }
    pub fn instantiate(comptime multi_arena: MultiArena) type {
        return GenericRegularAddressSpace(multi_arena);
    }
    pub fn super(comptime multi_arena: MultiArena) Arena {
        return .{
            .lb_addr = multi_arena.lb_addr,
            .up_addr = multi_arena.up_addr,
            .options = multi_arena.options,
        };
    }
    pub fn arena(comptime multi_arena: MultiArena, index: Index(multi_arena)) Arena {
        return .{
            .lb_addr = multi_arena.low(index),
            .up_addr = multi_arena.high(index),
            .options = multi_arena.options,
        };
    }
};
pub fn isRegular(comptime multi_arena: anytype, comptime map_list: []const ArenaReference) bool {
    var safety: ?bool = null;
    var addr: ?u64 = null;
    for (map_list) |item| {
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
            if (multi_arena.low(item.index) == prev) {
                addr = multi_arena.high(item.index);
            } else {
                return false;
            }
        } else {
            addr = multi_arena.high(item.index);
        }
    }
    return true;
}
fn RegularTypes(comptime AddressSpace: type) type {
    return struct {
        pub const acquire_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_map and
                AddressSpace.addr_spec.errors.map.throw != null)
            {
                const MMapError = sys.Error(AddressSpace.addr_spec.errors.map.throw.?);
                if (AddressSpace.addr_spec.errors.acquire == .throw) {
                    break :blk (MMapError || ResourceError)!void;
                }
                break :blk MMapError!void;
            }
            if (AddressSpace.addr_spec.errors.acquire == .throw) {
                break :blk ResourceError!void;
            }
            break :blk void;
        };
        pub const release_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw != null)
            {
                const MUnmapError = sys.Error(AddressSpace.addr_spec.errors.unmap.throw.?);
                if (AddressSpace.addr_spec.errors.release == .throw) {
                    break :blk (MUnmapError || ResourceError)!void;
                }
                break :blk MUnmapError!void;
            }
            if (AddressSpace.addr_spec.errors.release == .throw) {
                break :blk ResourceError!void;
            }
            break :blk void;
        };
        pub const map_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_map and
                AddressSpace.addr_spec.errors.map.throw != null)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.map.throw.?)!void;
            }
            break :blk void;
        };
        pub const unmap_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw != null)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.unmap.throw.?)!void;
            }
            break :blk void;
        };
    };
}
fn DiscreteTypes(comptime AddressSpace: type) type {
    return struct {
        pub fn acquire_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_map and
                AddressSpace.addr_spec.errors.map.throw != null)
            {
                const MMapError = sys.Error(AddressSpace.addr_spec.errors.map.throw.?);
                if (AddressSpace.addr_spec.errors.acquire == .throw) {
                    return (MMapError || ResourceError)!void;
                }
                return MMapError!void;
            }
            if (AddressSpace.addr_spec.errors.acquire == .throw) {
                return ResourceError!void;
            }
            return void;
        }
        pub fn release_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw != null)
            {
                const MUnmapError = sys.Error(AddressSpace.addr_spec.errors.unmap.throw.?);
                if (AddressSpace.addr_spec.errors.release == .throw) {
                    return (MUnmapError || ResourceError)!void;
                }
                return MUnmapError!void;
            }
            if (AddressSpace.addr_spec.errors.release == .throw) {
                return ResourceError!void;
            }
            return void;
        }
        pub fn map_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_map and
                AddressSpace.addr_spec.errors.map.throw != null)
            {
                return sys.Error(AddressSpace.addr_spec.errors.map.throw.?)!void;
            }
            return void;
        }
        pub fn unmap_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw != null)
            {
                return sys.Error(AddressSpace.addr_spec.errors.unmap.throw.?)!void;
            }
            return void;
        }
    };
}
fn Specs(comptime AddressSpace: type) type {
    return struct {
        pub const map_spec = .{
            .options = .{},
            .errors = AddressSpace.addr_spec.errors.map,
            .logging = AddressSpace.addr_spec.logging.map,
        };
        pub const remap_spec = .{
            .errors = AddressSpace.addr_spec.errors.remap,
            .logging = AddressSpace.addr_spec.logging.remap,
        };
        pub const unmap_spec = .{
            .errors = AddressSpace.addr_spec.errors.unmap,
            .logging = AddressSpace.addr_spec.logging.unmap,
        };
    };
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
        impl: RegularAddressSpaceSpec.Implementation(spec) align(8) = defaultValue(spec),
        pub const RegularAddressSpace = @This();
        pub const Index: type = RegularAddressSpaceSpec.Index(spec);
        pub const addr_spec: RegularAddressSpaceSpec = spec;
        pub fn get(address_space: *RegularAddressSpace, index: Index) bool {
            return address_space.impl.get(index);
        }
        pub fn unset(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub fn set(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (!ret) address_space.impl.set(index);
            return !ret;
        }
        pub fn atomicUnset(address_space: *RegularAddressSpace, index: Index) bool {
            return spec.options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *RegularAddressSpace, index: Index) bool {
            return spec.options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub fn atomicTransform(
            address_space: *RegularAddressSpace,
            index: Index,
            comptime if_state: spec.val_type,
            comptime to_state: spec.val_type,
        ) bool {
            return spec.options.thread_safe and
                address_space.impl.atomicTransform(index, if_state, to_state);
        }
        pub fn low(index: Index) u64 {
            return spec.low(index);
        }
        pub fn high(index: Index) u64 {
            return spec.high(index);
        }
        pub fn arena(index: Index) Arena {
            return spec.arena(index);
        }
        pub fn count(address_space: *const RegularAddressSpace) u64 {
            var index: Index = 0;
            var ret: u64 = 0;
            while (index != addr_spec.divisions) : (index +%= 1) {
                ret +%= builtin.int(u64, address_space.impl.get(index));
            }
            return ret;
        }
        pub usingnamespace Specs(RegularAddressSpace);
        pub usingnamespace RegularTypes(RegularAddressSpace);
        pub usingnamespace GenericAddressSpace(RegularAddressSpace);
    };
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
    return (extern struct {
        impl: DiscreteAddressSpaceSpec.Implementation(spec) = defaultValue(spec),
        pub const DiscreteAddressSpace = @This();
        pub const Index: type = DiscreteAddressSpaceSpec.Index(spec);
        pub const addr_spec: DiscreteAddressSpaceSpec = spec;
        pub fn unset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub fn set(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: bool = !address_space.impl.get(index);
            if (ret) address_space.impl.set(index);
            return ret;
        }
        pub fn atomicUnset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return spec.list[index].options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return spec.list[index].options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub fn atomicTransform(
            address_space: *DiscreteAddressSpace,
            comptime index: Index,
            comptime if_state: spec.val_type,
            comptime to_state: spec.val_type,
        ) bool {
            return spec.list[index].options.thread_safe and
                address_space.impl.atomicTransform(index, if_state, to_state);
        }
        pub fn low(comptime index: Index) u64 {
            return spec.low(index);
        }
        pub fn high(comptime index: Index) u64 {
            return spec.high(index);
        }
        pub fn arena(comptime index: Index) Arena {
            return spec.arena(index);
        }
        pub fn count(address_space: *const DiscreteAddressSpace) u64 {
            var index: Index = 0;
            var ret: u64 = 0;
            while (index != spec.list.len) : (index +%= 1) {
                ret +%= builtin.int(u64, address_space.impl.get(index));
            }
            return ret;
        }
        pub usingnamespace Specs(DiscreteAddressSpace);
        pub usingnamespace DiscreteTypes(DiscreteAddressSpace);
        pub usingnamespace GenericAddressSpace(DiscreteAddressSpace);
    });
}
pub const ElementaryAddressSpaceSpec = struct {
    label: ?[]const u8 = null,

    lb_addr: u64 = 0x40000000,
    up_addr: u64 = 0x800000000000,
    errors: AddressSpaceErrors,
    logging: AddressSpaceLogging,
    options: ArenaOptions,
};
/// Elementary:
pub fn GenericElementaryAddressSpace(comptime spec: ElementaryAddressSpaceSpec) type {
    return struct {
        impl: bool = false,
        comptime high: fn () u64 = high,
        comptime low: fn () u64 = low,
        pub const ElementaryAddressSpace = @This();
        pub const addr_spec: ElementaryAddressSpaceSpec = spec;
        pub fn get(address_space: *ElementaryAddressSpace) bool {
            return address_space.impl;
        }
        pub fn unset(address_space: *ElementaryAddressSpace) bool {
            const ret: bool = address_space.impl;
            if (ret) {
                address_space.impl = false;
            }
            return ret;
        }
        pub fn set(address_space: *ElementaryAddressSpace) bool {
            const ret: bool = address_space.impl;
            if (!ret) {
                address_space.impl = true;
            }
            return !ret;
        }
        pub fn atomicSet(address_space: *ElementaryAddressSpace) bool {
            return spec.options.thread_safe and asm volatile (
                \\mov           $0,     %al
                \\mov           $255,   %dl
                \\lock cmpxchg  %dl,    %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&address_space.impl),
                : "rax", "rdx", "memory"
            );
        }
        pub fn atomicUnset(address_space: *ElementaryAddressSpace) bool {
            return spec.options.thread_safe and asm volatile (
                \\mov           $255,   %al
                \\mov           $0,     %dl
                \\lock cmpxchg  %dl,    %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&address_space.impl),
                : "rax", "rdx", "memory"
            );
        }
        fn low() u64 {
            return spec.lb_addr;
        }
        fn high() u64 {
            return spec.up_addr;
        }
        pub fn arena() Arena {
            return .{
                .lb_addr = spec.lb_addr,
                .up_addr = spec.up_addr,
                .options = spec.options,
            };
        }
        pub fn count(address_space: *const ElementaryAddressSpace) u8 {
            return builtin.int(u8, address_space.impl);
        }
        pub usingnamespace Specs(ElementaryAddressSpace);
        pub usingnamespace RegularTypes(ElementaryAddressSpace);
        pub usingnamespace GenericAddressSpace(ElementaryAddressSpace);
    };
}
fn GenericAddressSpace(comptime AddressSpace: type) type {
    return struct {
        pub fn formatWrite(address_space: AddressSpace, array: anytype) void {
            if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
                return debug.formatWriteDiscrete(address_space, array);
            } else {
                return debug.formatWriteRegular(address_space, array);
            }
        }
        pub fn formatLength(address_space: AddressSpace) u64 {
            if (@TypeOf(AddressSpace.addr_spec) == DiscreteAddressSpaceSpec) {
                return debug.formatLengthDiscrete(address_space);
            } else {
                return debug.formatLengthRegular(address_space);
            }
        }
        pub fn invert(addr: u64) AddressSpace.Index {
            return @intCast(AddressSpace.Index, AddressSpace.addr_spec.invert(addr));
        }
        pub fn SubSpace(comptime label_or_index: anytype) type {
            return GenericSubSpace(AddressSpace.addr_spec.subspace.?, label_or_index);
        }
        const debug = struct {
            const about_set_0_s: []const u8 = "set:            ";
            const about_set_1_s: []const u8 = "unset:          ";
            fn formatWriteRegular(address_space: AddressSpace, array: anytype) void {
                var arena_index: AddressSpace.Index = 0;
                array.writeMany(about_set_0_s);
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (!address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
                arena_index = 0;
                array.writeMany(about_set_1_s);
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
            }
            fn formatLengthRegular(address_space: AddressSpace) u64 {
                var len: u64 = 0;
                var arena_index: AddressSpace.Index = 0;
                len += about_set_0_s.len;
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (!address_space.impl.get(arena_index)) {
                        len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len += 2;
                    }
                }
                arena_index = 0;
                len += about_set_1_s.len;
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (address_space.impl.get(arena_index)) {
                        len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len += 2;
                    }
                }
                return len;
            }
            fn formatWriteDiscrete(address_space: AddressSpace, array: anytype) void {
                comptime var arena_index: AddressSpace.Index = 0;
                array.writeMany(about_set_0_s);
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (!address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
                arena_index = 0;
                array.writeMany(about_set_1_s);
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
            }
            fn formatLengthDiscrete(address_space: AddressSpace) u64 {
                var len: u64 = 0;
                comptime var arena_index: AddressSpace.Index = 0;
                len += about_set_0_s.len;
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (address_space.impl.get(arena_index)) {
                        len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len += 2;
                    }
                }
                arena_index = 0;
                len += about_set_1_s.len;
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index += 1) {
                    if (!address_space.impl.get(arena_index)) {
                        len += builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len += 2;
                    }
                }
                return len;
            }
        };
    };
}
pub fn generic(comptime any: anytype) meta.Generic {
    const T: type = if (@hasField(@TypeOf(any), "list"))
        DiscreteMultiArena
    else
        RegularMultiArena;
    return .{ .type = T, .value = &@as(T, any) };
}
pub fn genericSlice(comptime any: anytype) []const meta.Generic {
    return meta.genericSlice(generic, any);
}
fn GenericSubSpace(comptime ss: []const meta.Generic, comptime any: anytype) type {
    switch (@typeInfo(@TypeOf(any))) {
        .Int, .ComptimeInt => {
            return meta.typeCast(ss[any]).instantiate();
        },
        else => for (ss) |s| {
            if (meta.typeCast(s).label) |label| {
                if (label.len != any.len) {
                    continue;
                }
                for (label, 0..) |c, i| {
                    if (c != any[i]) continue;
                }
                return meta.typeCast(s).instantiate();
            }
        },
    }
}
fn defaultValue(comptime multi_arena: anytype) multi_arena.Implementation() {
    var tmp: multi_arena.Implementation() = .{};
    for (multi_arena.subspace orelse
        return tmp) |subspace|
    {
        for (blk: {
            if (subspace.type == RegularMultiArena) {
                break :blk multi_arena.referSubRegular(meta.typeCast(subspace).super());
            }
            if (subspace.type == DiscreteMultiArena) {
                break :blk multi_arena.referSubDiscrete(meta.typeCast(subspace).list);
            }
        }) |ref| {
            tmp.set(ref.index);
        }
    }
    return tmp;
}
