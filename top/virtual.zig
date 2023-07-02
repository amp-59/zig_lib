const sys = @import("./sys.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");
const word_bit_size: u8 = @bitSizeOf(u64);
pub const ResourceError = error{ UnderSupply, OverSupply };
pub const ResourceErrorPolicy = builtin.InternalError(ResourceError);
pub const RegularAddressSpaceSpec = RegularMultiArena;
pub const DiscreteAddressSpaceSpec = DiscreteMultiArena;

pub fn DiscreteBitSet(comptime elements: u16, comptime val_type: type, comptime idx_type: type) type {
    const val_bit_size: u16 = @bitSizeOf(val_type);
    if (val_bit_size != 1) {
        @compileError("not yet implemented");
    }
    const bits: u16 = elements * val_bit_size;
    const data_type: type = meta.UniformData(bits);
    const data_info: builtin.Type = @typeInfo(data_type);
    const idx_info: builtin.Type = @typeInfo(idx_type);
    if (data_info == .Array and idx_info != .Enum) {
        return extern struct {
            bits: data_type = [1]u64{0} ** data_info.Array.len,
            pub const BitSet: type = @This();
            const Word: type = data_info.Array.child;
            const Shift: type = builtin.ShiftAmount(Word);
            pub fn indexToShiftAmount(index: idx_type) Shift {
                return @as(Shift, @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size)));
            }
            pub fn get(bit_set: *BitSet, index: idx_type) val_type {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                return bit_set.bits[index / word_bit_size] & bit_mask != 0;
            }
            pub fn set(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits[index / word_bit_size] |= bit_mask;
            }
            pub fn unset(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits[index / word_bit_size] &= ~bit_mask;
            }
        };
    } else if (data_info == .Int and idx_info != .Enum) {
        return extern struct {
            bits: data_type = 0,
            pub const BitSet: type = @This();
            const Word: type = data_type;
            const Shift: type = builtin.ShiftAmount(Word);
            pub inline fn indexToShiftAmount(index: idx_type) Shift {
                return @as(Shift, @intCast((data_info.Int.bits -% 1) -% index));
            }
            pub fn get(bit_set: *BitSet, index: idx_type) val_type {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                return bit_set.bits & bit_mask != 0;
            }
            pub fn set(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits |= bit_mask;
            }
            pub fn unset(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits &= ~bit_mask;
            }
        };
    } else if (data_info == .Array and idx_info == .Enum) {
        return (extern struct {
            bits: data_type = [1]u64{0} ** data_info.Array.len,
            pub const BitSet: type = @This();
            const Word: type = data_info.Array.child;
            const Shift: type = builtin.ShiftAmount(Word);
            pub inline fn indexToShiftAmount(index: idx_type) Shift {
                return @as(Shift, @intCast((word_bit_size -% 1) -% @rem(index, word_bit_size)));
            }
            pub fn get(bit_set: *BitSet, index: idx_type) val_type {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                return bit_set.bits[index / word_bit_size] & bit_mask != 0;
            }
            pub fn set(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits[index / word_bit_size] |= bit_mask;
            }
            pub fn unset(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits[index / word_bit_size] &= ~bit_mask;
            }
        });
    } else if (data_info == .Int and idx_info == .Enum) {
        return extern struct {
            bits: data_type = 0,
            pub const BitSet: type = @This();
            const Word: type = data_type;
            const Shift: type = builtin.ShiftAmount(Word);
            pub inline fn indexToShiftAmount(index: idx_type) Shift {
                return @as(Shift, @intCast((data_info.Int.bits -% 1) -% @intFromEnum(index)));
            }
            pub fn get(bit_set: *BitSet, index: idx_type) val_type {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                return bit_set.bits & bit_mask != 0;
            }
            pub fn set(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits |= bit_mask;
            }
            pub fn unset(bit_set: *BitSet, index: idx_type) void {
                const bit_mask: Word = @as(Word, 1) << indexToShiftAmount(index);
                bit_set.bits &= ~bit_mask;
            }
        };
    }
}
fn ThreadSafeSetBoolInt(comptime elements: u16, comptime idx_type: type) type {
    return extern struct {
        bytes: [elements]u8 align(4) = builtin.zero([elements]u8),
        pub const SafeSet: type = @This();
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *SafeSet, index: idx_type) bool {
            return safe_set.bytes[index] != 0;
        }
        pub fn set(safe_set: *SafeSet, index: idx_type) void {
            safe_set.bytes[index] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: idx_type) void {
            safe_set.bytes[index] = 0;
        }
        pub inline fn atomicSet(safe_set: *SafeSet, index: idx_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 0, 255, .SeqCst, .SeqCst) == null;
        }
        pub inline fn atomicUnset(safe_set: *SafeSet, index: idx_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 255, 0, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: idx_type) *u32 {
            return @as(*u32, @ptrFromInt(mach.alignB64(@intFromPtr(&safe_set.bytes[index]), 4)));
        }
    };
}
fn ThreadSafeSetBoolEnum(comptime elements: u16, comptime idx_type: type) type {
    return extern struct {
        bytes: [elements]u8 align(4) = builtin.zero([elements]u8),
        pub const SafeSet: type = @This();
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *SafeSet, index: idx_type) bool {
            return safe_set.bytes[@intFromEnum(index)] != 0;
        }
        pub fn set(safe_set: *SafeSet, index: idx_type) void {
            safe_set.bytes[@intFromEnum(index)] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: idx_type) void {
            safe_set.bytes[@intFromEnum(index)] = 0;
        }
        pub fn atomicSet(safe_set: *SafeSet, index: idx_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 0, 255, .SeqCst, .SeqCst) == null;
        }
        pub fn atomicUnset(safe_set: *SafeSet, index: idx_type) bool {
            return @cmpxchgStrong(u8, &safe_set.bytes[index], 255, 0, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: idx_type) *u32 {
            return @as(*u32, @ptrFromInt(mach.alignB64(@intFromPtr(&safe_set.bytes[@intFromEnum(index)]), 4)));
        }
    };
}
fn ThreadSafeSetEnumInt(comptime elements: u16, comptime val_type: type, comptime idx_type: type) type {
    return extern struct {
        bytes: [elements]val_type align(4) = builtin.zero([elements]val_type),
        pub const SafeSet: type = @This();
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *SafeSet, index: idx_type) val_type {
            return safe_set.bytes[index];
        }
        pub fn set(safe_set: *SafeSet, index: idx_type, to: val_type) void {
            safe_set.bytes[index] = to;
        }
        pub fn atomicExchange(safe_set: *SafeSet, index: idx_type, if_state: val_type, to_state: val_type) bool {
            return @cmpxchgStrong(val_type, &safe_set.bytes[index], if_state, to_state, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: idx_type) *u32 {
            return @as(*u32, @ptrFromInt(mach.alignB64(@intFromPtr(&safe_set.bytes[index]), 4)));
        }
    };
}
fn ThreadSafeSetEnumEnum(comptime elements: u16, comptime val_type: type, comptime idx_type: type) type {
    return extern struct {
        bytes: [elements]val_type align(4) = builtin.zero([elements]val_type),
        pub const SafeSet: type = @This();
        const mutexes: comptime_int = @divExact(@sizeOf(@This()), 4);
        pub fn get(safe_set: *SafeSet, index: idx_type) val_type {
            return safe_set.bytes[@intFromEnum(index)];
        }
        pub fn set(safe_set: *SafeSet, index: idx_type, to: val_type) void {
            safe_set.bytes[@intFromEnum(index)] = to;
        }
        pub fn exchange(safe_set: *SafeSet, index: idx_type, if_state: val_type, to_state: val_type) bool {
            const ret: bool = safe_set.get(index) == if_state;
            if (ret) safe_set.bytes[@intFromEnum(index)] = to_state;
            return ret;
        }
        pub fn atomicExchange(safe_set: *SafeSet, index: idx_type, if_state: val_type, to_state: val_type) callconv(.C) bool {
            return @cmpxchgStrong(val_type, &safe_set.bytes[@intFromEnum(index)], if_state, to_state, .SeqCst, .SeqCst) == null;
        }
        pub fn mutex(safe_set: *SafeSet, index: idx_type) *u32 {
            return @as(*u32, @ptrFromInt(mach.alignB64(@intFromPtr(&safe_set.bytes[@intFromEnum(index)]), 4)));
        }
    };
}
pub fn ThreadSafeSet(comptime elements: u16, comptime val_type: type, comptime idx_type: type) type {
    const idx_info: builtin.Type = @typeInfo(idx_type);
    if (val_type == bool and idx_info != .Enum) {
        return ThreadSafeSetBoolInt(elements, idx_type);
    } else if (val_type == bool and idx_info == .Enum) {
        return ThreadSafeSetBoolEnum(elements, idx_type);
    } else if (val_type != bool and idx_info != .Enum) {
        return ThreadSafeSetEnumInt(elements, val_type, idx_type);
    } else if (val_type != bool and idx_info == .Enum) {
        return ThreadSafeSetEnumEnum(elements, val_type, idx_type);
    }
}
fn GenericMultiSet(
    comptime spec: DiscreteAddressSpaceSpec,
    comptime directory: anytype,
    comptime Fields: type,
) type {
    const T = extern struct {
        fields: Fields = .{},
        pub const MultiSet: type = @This();
        inline fn arenaIndex(comptime index: spec.idx_type) spec.idx_type {
            if (@typeInfo(spec.idx_type) == .Enum) {
                comptime return @as(spec.idx_type, @enumFromInt(directory[@intFromEnum(index)].arena_index));
            } else {
                comptime return directory[index].arena_index;
            }
        }
        inline fn fieldIndex(comptime index: spec.idx_type) usize {
            if (@typeInfo(spec.idx_type) == .Enum) {
                comptime return directory[@intFromEnum(index)].field_index;
            } else {
                comptime return directory[index].field_index;
            }
        }
        pub fn get(multi_set: *MultiSet, comptime index: spec.idx_type) spec.val_type {
            return multi_set.fields[fieldIndex(index)].get(arenaIndex(index));
        }
        pub fn set(multi_set: *MultiSet, comptime index: spec.idx_type) void {
            multi_set.fields[fieldIndex(index)].set(arenaIndex(index));
        }
        pub fn exchange(
            multi_set: *MultiSet,
            comptime index: spec.idx_type,
            if_state: spec.val_type,
            to_state: spec.val_type,
        ) bool {
            return multi_set.fields[fieldIndex(index)].exchange(arenaIndex(index), if_state, to_state);
        }
        pub fn unset(multi_set: *MultiSet, comptime index: spec.idx_type) void {
            multi_set.fields[fieldIndex(index)].unset(arenaIndex(index));
        }
        pub fn atomicSet(multi_set: *MultiSet, comptime index: spec.idx_type) bool {
            return multi_set.fields[fieldIndex(index)].atomicSet(arenaIndex(index));
        }
        pub fn atomicUnset(multi_set: *MultiSet, comptime index: spec.idx_type) bool {
            return multi_set.fields[fieldIndex(index)].atomicUnset(arenaIndex(index));
        }
        pub fn atomicExchange(
            multi_set: *MultiSet,
            comptime index: spec.idx_type,
            if_state: spec.val_type,
            to_state: spec.val_type,
        ) bool {
            return multi_set.fields[fieldIndex(index)].atomicExchange(arenaIndex(index), if_state, to_state);
        }
    };
    return T;
}
pub const ArenaOptions = extern struct {
    thread_safe: bool = false,
    require_map: bool = false,
    require_unmap: bool = false,
};
pub fn Intersection(comptime A: type) type {
    return extern struct { l: A, x: A, h: A };
}
pub const Bounds = extern struct {
    lb_addr: u64,
    up_addr: u64,
};
pub fn bounds(any: anytype) Bounds {
    return .{
        .lb_addr = @intFromPtr(any.ptr),
        .up_addr = @intFromPtr(any.ptr) +% any.len,
    };
}
pub fn intersection2(comptime A: type, s_arena: A, t_arena: A) ?Intersection(A) {
    if (intersection(A, s_arena, t_arena)) |x_arena| {
        return .{
            .l = if (@hasField(A, "options")) .{
                .lb_addr = @min(t_arena.lb_addr, s_arena.lb_addr),
                .up_addr = x_arena.lb_addr,
                .options = if (s_arena.lb_addr < t_arena.lb_addr)
                    s_arena.options
                else
                    t_arena.options,
            } else .{
                .lb_addr = @min(t_arena.lb_addr, s_arena.lb_addr),
                .up_addr = x_arena.lb_addr,
            },
            .x = x_arena,
            .h = if (@hasField(A, "options")) .{
                .lb_addr = x_arena.up_addr,
                .up_addr = @max(s_arena.up_addr, t_arena.up_addr),
                .options = if (t_arena.up_addr > s_arena.up_addr)
                    t_arena.options
                else
                    s_arena.options,
            } else .{
                .lb_addr = x_arena.up_addr,
                .up_addr = @max(s_arena.up_addr, t_arena.up_addr),
            },
        };
    }
    return null;
}
pub fn intersection(comptime A: type, s_arena: Arena, t_arena: Arena) ?A {
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
pub const Arena = extern struct {
    lb_addr: u64,
    up_addr: u64,
    options: ArenaOptions = .{},
};
pub const AddressSpaceLogging = packed struct {
    acquire: builtin.Logging.AcquireErrorFault = .{},
    release: builtin.Logging.ReleaseErrorFault = .{},
    map: builtin.Logging.AcquireError = .{},
    unmap: builtin.Logging.ReleaseError = .{},
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
    idx_type: type = u16,
    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},
    pub const MultiArena: type = @This();
    fn Directory(comptime multi_arena: MultiArena) type {
        return [multi_arena.list.len]struct {
            field_index: comptime_int,
            arena_index: comptime_int,
        };
    }
    pub fn Implementation(comptime multi_arena: MultiArena) type {
        builtin.assertNotEqual(u64, multi_arena.list.len, 0);
        var directory: Directory(multi_arena) = undefined;
        var fields: []const builtin.Type.StructField = meta.empty;
        var thread_safe_state: bool = multi_arena.list[0].options.thread_safe;
        var arena_index: comptime_int = 0;
        for (multi_arena.list, 0..) |super_arena, index| {
            if (thread_safe_state and !super_arena.options.thread_safe) {
                const T: type = ThreadSafeSet(arena_index +% 1, multi_arena.val_type, multi_arena.idx_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else if (!thread_safe_state and super_arena.options.thread_safe) {
                const T: type = DiscreteBitSet(arena_index +% 1, multi_arena.val_type, multi_arena.idx_type);
                fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
                directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                arena_index = 1;
            } else {
                directory[index] = .{ .arena_index = arena_index, .field_index = fields.len };
                arena_index +%= 1;
            }
            thread_safe_state = super_arena.options.thread_safe;
        }
        const GenericSet = if (thread_safe_state) ThreadSafeSet else DiscreteBitSet;
        const T: type = GenericSet(arena_index +% 1, multi_arena.val_type, multi_arena.idx_type);
        fields = fields ++ [1]builtin.Type.StructField{meta.structField(T, builtin.fmt.ci(fields.len), .{})};
        if (fields.len == 1) {
            return fields[0].type;
        }
        var type_info: builtin.Type = meta.tupleInfo(fields);
        type_info.Struct.layout = .Extern;
        return GenericMultiSet(multi_arena, directory, @Type(type_info));
    }
    fn referSubRegular(comptime multi_arena: MultiArena, comptime sub_arena: Arena) []const ArenaReference {
        var map_list: []const ArenaReference = meta.empty;
        var s_index: multi_arena.idx_type = 0;
        while (s_index <= multi_arena.list.len) : (s_index +%= 1) {
            const super_arena: Arena = multi_arena.list[s_index];
            if (super_arena.lb_addr > sub_arena.up_addr) {
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
        var t_index: multi_arena.idx_type = 0;
        while (t_index != sub_list.len) : (t_index +%= 1) {
            var s_index: multi_arena.idx_type = 0;
            while (s_index != multi_arena.list.len) : (s_index +%= 1) {
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
    pub fn capacityAny(comptime multi_arena: MultiArena, comptime index: multi_arena.idx_type) u64 {
        return multi_arena.list[index].up_addr -% multi_arena.list[index].up_addr;
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: u64) multi_arena.idx_type {
        var index: multi_arena.idx_type = 0;
        while (index != multi_arena.list.len) : (index +%= 1) {
            if (addr >= multi_arena.list[index].lb_addr and
                addr < multi_arena.list[index].up_addr)
            {
                return index;
            }
        }
        unreachable;
    }
    pub fn arena(comptime multi_arena: MultiArena, index: multi_arena.idx_type) Arena {
        return multi_arena.list[index];
    }
    pub fn count(comptime multi_arena: MultiArena) comptime_int {
        return multi_arena.list.len;
    }
    pub fn low(comptime multi_arena: MultiArena, comptime index: multi_arena.idx_type) u64 {
        return multi_arena.list[index].lb_addr;
    }
    pub fn high(comptime multi_arena: MultiArena, comptime index: multi_arena.idx_type) u64 {
        return multi_arena.list[index].up_addr;
    }
    pub fn instantiate(comptime multi_arena: MultiArena) type {
        return GenericDiscreteAddressSpace(multi_arena);
    }
    pub fn options(comptime multi_arena: MultiArena, comptime index: multi_arena.idx_type) ArenaOptions {
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
    idx_type: type = u16,
    errors: AddressSpaceErrors = .{},
    logging: AddressSpaceLogging = .{},
    options: ArenaOptions = .{},
    pub const MultiArena = @This();
    fn Index(comptime multi_arena: MultiArena) type {
        return multi_arena.idx_type;
    }
    fn Implementation(comptime multi_arena: MultiArena) type {
        if (multi_arena.options.thread_safe or
            @bitSizeOf(multi_arena.val_type) == 8)
        {
            return ThreadSafeSet(
                multi_arena.divisions +% @intFromBool(multi_arena.options.require_map),
                multi_arena.val_type,
                multi_arena.idx_type,
            );
        } else {
            return DiscreteBitSet(
                multi_arena.divisions +% @intFromBool(multi_arena.options.require_map),
                multi_arena.val_type,
                multi_arena.idx_type,
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
        var max_index: Index(multi_arena) = multi_arena.invert(sub_arena.up_addr);
        var min_index: Index(multi_arena) = multi_arena.invert(sub_arena.lb_addr);
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index +%= 1) {
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
        var max_index: Index(multi_arena) = multi_arena.invert(sub_list[sub_list.len -% 1].up_addr);
        var min_index: Index(multi_arena) = multi_arena.invert(sub_list[0].lb_addr);
        var s_index: Index(multi_arena) = min_index;
        while (s_index <= max_index) : (s_index +%= 1) {
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
    pub inline fn count(comptime multi_arena: MultiArena) Index(multi_arena) {
        comptime return multi_arena.divisions;
    }
    pub fn capacityAll(comptime multi_arena: MultiArena) u64 {
        comptime return mach.alignA64(multi_arena.up_addr -% multi_arena.lb_addr, multi_arena.alignment);
    }
    pub fn capacityEach(comptime multi_arena: MultiArena) u64 {
        comptime return @divExact(capacityAll(multi_arena), multi_arena.divisions);
    }
    pub fn invert(comptime multi_arena: MultiArena, addr: u64) Index(multi_arena) {
        return @as(Index(multi_arena), @intCast((addr -% multi_arena.lb_addr) / capacityEach(multi_arena)));
    }
    pub fn low(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        const offset: u64 = index *% comptime capacityEach(multi_arena);
        return @max(multi_arena.lb_addr +% multi_arena.lb_offset, multi_arena.lb_addr +% offset);
    }
    pub fn high(comptime multi_arena: MultiArena, index: Index(multi_arena)) u64 {
        const offset: u64 = (index +% 1) *% comptime capacityEach(multi_arena);
        return @min(multi_arena.up_addr -% multi_arena.up_offset, multi_arena.lb_addr +% offset);
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
                AddressSpace.addr_spec.errors.map.throw.len != 0)
            {
                const MMapError = sys.Error(AddressSpace.addr_spec.errors.map.throw);
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
        pub const acquire_bool: type = blk: {
            if (AddressSpace.addr_spec.options.require_map and
                AddressSpace.addr_spec.errors.map.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.map.throw)!bool;
            }
            break :blk bool;
        };
        pub const release_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw.len != 0)
            {
                const MUnmapError = sys.Error(AddressSpace.addr_spec.errors.unmap.throw);
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
        pub const release_bool: type = blk: {
            if (AddressSpace.addr_spec.options.require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.unmap.throw)!bool;
            }
            break :blk bool;
        };
        pub const map_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_map and
                AddressSpace.addr_spec.errors.map.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.map.throw)!void;
            }
            break :blk void;
        };
        pub const unmap_void: type = blk: {
            if (AddressSpace.addr_spec.options.require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw.len != 0)
            {
                break :blk sys.Error(AddressSpace.addr_spec.errors.unmap.throw)!void;
            }
            break :blk void;
        };
    };
}
fn DiscreteTypes(comptime AddressSpace: type) type {
    return struct {
        pub fn acquire_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_map and
                AddressSpace.addr_spec.errors.map.throw.len != 0)
            {
                const MMapError = sys.Error(AddressSpace.addr_spec.errors.map.throw);
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
                AddressSpace.addr_spec.errors.unmap.throw.len != 0)
            {
                const MUnmapError = sys.Error(AddressSpace.addr_spec.errors.unmap.throw);
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
                AddressSpace.addr_spec.errors.map.throw.len != 0)
            {
                return sys.Error(AddressSpace.addr_spec.errors.map.throw)!void;
            }
            return void;
        }
        pub fn unmap_void(comptime index: AddressSpace.Index) type {
            if (AddressSpace.addr_spec.options(index).require_unmap and
                AddressSpace.addr_spec.errors.unmap.throw.len != 0)
            {
                return sys.Error(AddressSpace.addr_spec.errors.unmap.throw)!void;
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
///     * Results must be tightly constrained or checked.
///     * Arenas can not be independently configured.
///     * Thread safety is all-or-nothing, which increases the metadata size
///       required by each arena from 1 to 8 bits.
pub fn GenericRegularAddressSpace(comptime spec: RegularAddressSpaceSpec) type {
    const T = extern struct {
        impl: RegularAddressSpaceSpec.Implementation(spec) align(8) = defaultValue(spec),
        pub const RegularAddressSpace = @This();
        pub const Index: type = spec.idx_type;
        pub const Value: type = spec.val_type;
        pub const addr_spec: RegularAddressSpaceSpec = spec;
        pub inline fn get(address_space: *const RegularAddressSpace, index: Index) Value {
            return address_space.impl.get(index);
        }
        pub inline fn unset(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub inline fn set(address_space: *RegularAddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.get(index);
            if (!ret) address_space.impl.set(index);
            return !ret;
        }
        pub inline fn exchange(
            address_space: *RegularAddressSpace,
            index: Index,
            if_state: Value,
            to_state: Value,
        ) bool {
            const ret: Value = address_space.impl.get(index);
            if (ret == if_state) address_space.impl.set(index, to_state);
            return !ret;
        }
        pub inline fn atomicUnset(address_space: *RegularAddressSpace, index: Index) bool {
            return spec.options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub inline fn atomicSet(address_space: *RegularAddressSpace, index: Index) bool {
            return spec.options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub inline fn atomicExchange(
            address_space: *RegularAddressSpace,
            index: Index,
            comptime if_state: spec.val_type,
            comptime to_state: spec.val_type,
        ) bool {
            return spec.options.thread_safe and
                address_space.impl.atomicExchange(index, if_state, to_state);
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
        pub fn count(address_space: *RegularAddressSpace) u64 {
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
    return T;
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
    const T = extern struct {
        impl: DiscreteAddressSpaceSpec.Implementation(spec) = defaultValue(spec),
        pub const DiscreteAddressSpace = @This();
        pub const Index: type = spec.idx_type;
        pub const Value: type = spec.val_type;
        pub const addr_spec: DiscreteAddressSpaceSpec = spec;
        pub fn get(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return address_space.impl.get(index);
        }
        pub fn unset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: spec.val_type = address_space.get(index);
            if (ret) address_space.impl.unset(index);
            return ret;
        }
        pub fn set(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            const ret: spec.val_type = !address_space.get(index);
            if (ret) address_space.impl.set(index);
            return ret;
        }
        pub fn transform(address_space: *DiscreteAddressSpace, comptime index: Index, if_state: Value, to_state: Value) bool {
            const ret: Value = address_space.get(index);
            if (ret == if_state) address_space.impl.transform(index, if_state, to_state);
            return !ret;
        }
        pub fn atomicUnset(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return spec.list[index].options.thread_safe and address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *DiscreteAddressSpace, comptime index: Index) bool {
            return spec.list[index].options.thread_safe and address_space.impl.atomicSet(index);
        }
        pub fn atomicExchange(
            address_space: *DiscreteAddressSpace,
            comptime index: Index,
            comptime if_state: spec.val_type,
            comptime to_state: spec.val_type,
        ) bool {
            return spec.list[index].options.thread_safe and
                address_space.impl.atomicExchange(index, if_state, to_state);
        }
        pub inline fn low(comptime index: Index) u64 {
            return spec.low(index);
        }
        pub inline fn high(comptime index: Index) u64 {
            return spec.high(index);
        }
        pub inline fn arena(comptime index: Index) Arena {
            return spec.arena(index);
        }
        pub fn count(address_space: *DiscreteAddressSpace) u64 {
            comptime var index: Index = 0;
            var ret: u64 = 0;
            inline while (index != spec.list.len) : (index +%= 1) {
                ret +%= builtin.int(u64, address_space.impl.get(index));
            }
            return ret;
        }
        pub usingnamespace Specs(DiscreteAddressSpace);
        pub usingnamespace DiscreteTypes(DiscreteAddressSpace);
        pub usingnamespace GenericAddressSpace(DiscreteAddressSpace);
    };
    return T;
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
    const T = struct {
        impl: bool = false,
        comptime high: fn () u64 = high,
        comptime low: fn () u64 = low,
        pub const ElementaryAddressSpace = @This();
        pub const addr_spec: ElementaryAddressSpaceSpec = spec;
        pub fn get(address_space: *const ElementaryAddressSpace) bool {
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
            return @cmpxchgStrong(u8, &address_space.impl, 0, 255, .SeqCst, .SeqCst);
        }
        pub fn atomicUnset(address_space: *ElementaryAddressSpace) bool {
            return @cmpxchgStrong(u8, &address_space.impl, 255, 0, .SeqCst, .SeqCst);
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
    return T;
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
            return @as(AddressSpace.Index, @intCast(AddressSpace.addr_spec.invert(addr)));
        }
        pub fn SubSpace(comptime label_or_index: anytype) type {
            return GenericSubSpace(AddressSpace.addr_spec.subspace.?, label_or_index);
        }
        const debug = struct {
            const about_set_0_s: []const u8 = builtin.fmt.about("set");
            const about_set_1_s: []const u8 = builtin.fmt.about("unset");
            fn formatWriteRegular(address_space: AddressSpace, array: anytype) void {
                var arena_index: AddressSpace.Index = 0;
                array.writeMany(about_set_0_s);
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (!address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
                arena_index = 0;
                array.writeMany(about_set_1_s);
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
            }
            fn formatLengthRegular(address_space: AddressSpace) u64 {
                var len: u64 = 0;
                var arena_index: AddressSpace.Index = 0;
                len +%= about_set_0_s.len;
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (!address_space.impl.get(arena_index)) {
                        len +%= builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len +%= 2;
                    }
                }
                arena_index = 0;
                len +%= about_set_1_s.len;
                while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (address_space.impl.get(arena_index)) {
                        len +%= builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len +%= 2;
                    }
                }
                return len;
            }
            fn formatWriteDiscrete(address_space: AddressSpace, array: anytype) void {
                comptime var arena_index: AddressSpace.Index = 0;
                array.writeMany(about_set_0_s);
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (!address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
                arena_index = 0;
                array.writeMany(about_set_1_s);
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (address_space.impl.get(arena_index)) {
                        array.writeMany(builtin.fmt.dec(AddressSpace.Index, arena_index).readAll());
                        array.writeCount(2, ", ".*);
                    }
                }
            }
            fn formatLengthDiscrete(address_space: AddressSpace) u64 {
                var len: u64 = 0;
                comptime var arena_index: AddressSpace.Index = 0;
                len +%= about_set_0_s.len;
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (address_space.impl.get(AddressSpace.Index, arena_index)) {
                        len +%= builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len +%= 2;
                    }
                }
                arena_index = 0;
                len +%= about_set_1_s.len;
                inline while (arena_index != comptime AddressSpace.addr_spec.count()) : (arena_index +%= 1) {
                    if (!address_space.impl.get(AddressSpace.Index, arena_index)) {
                        len +%= builtin.fmt.length(AddressSpace.Index, arena_index, 10);
                        len +%= 2;
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
    return meta.genericCast(T, any);
}
pub fn genericSlice(comptime any: anytype) []const meta.Generic {
    return meta.genericSlice(generic, any);
}
fn GenericSubSpace(comptime ss: []const meta.Generic, comptime any: anytype) type {
    switch (@typeInfo(@TypeOf(any))) {
        .Int, .ComptimeInt => {
            return ss[any].cast().instantiate();
        },
        else => for (ss) |s| {
            if (s.cast().label) |label| {
                if (label.len != any.len) {
                    continue;
                }
                for (label, 0..) |c, i| {
                    if (c != any[i]) continue;
                }
                return s.cast().instantiate();
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
                break :blk multi_arena.referSubRegular(subspace.cast().super());
            }
            if (subspace.type == DiscreteMultiArena) {
                break :blk multi_arena.referSubDiscrete(subspace.cast().list);
            }
        }) |ref| {
            tmp.set(ref.index);
        }
    }
    return tmp;
}
