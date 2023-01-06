//! Experimental
//!
//! The address space is currently divided 127 times to allow allocators and
//! threads to manage mapped segments without possibility of collision.
//!
const mem = @import("./mem.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

const Options = struct {
    thread_safe: bool = false,
};

pub const Arena = struct {
    lb_addr: usize,
    up_addr: usize,
    options: Options = .{},

    pub fn low(arena: Arena) usize {
        return arena.lb_addr;
    }
    pub fn high(arena: Arena) usize {
        return arena.up_addr;
    }
    pub fn capacity(arena: Arena) usize {
        return arena.up_addr - arena.lb_addr;
    }
    pub fn intersection(s_arena: Arena, t_arena: Arena) ?Arena {
        const s_lb_addr: usize = s_arena.low();
        const s_up_addr: usize = s_arena.high() - 1;
        const t_lb_addr: usize = t_arena.low();
        const t_up_addr: usize = t_arena.high() - 1;
        if (builtin.int2v(bool, t_up_addr < s_lb_addr, s_up_addr < t_lb_addr)) {
            return null;
        }
        if (s_lb_addr == t_up_addr) {
            return construct(t_up_addr, s_lb_addr);
        }
        if (s_up_addr == t_lb_addr) {
            return construct(s_up_addr, t_lb_addr);
        }
        if (s_up_addr == t_up_addr) {
            return if (s_lb_addr < t_lb_addr) t_arena else s_arena;
        }
        if (s_lb_addr == t_lb_addr) {
            return if (s_up_addr < t_up_addr) s_arena else t_arena;
        }
        if (s_lb_addr < t_lb_addr) {
            return if (s_up_addr < t_up_addr) construct(t_lb_addr, s_up_addr) else t_arena;
        } else {
            return if (s_up_addr < t_up_addr) s_arena else construct(s_lb_addr, t_up_addr);
        }
        unreachable;
    }
    fn construct(lb_addr: usize, up_addr: usize) Arena {
        return .{ .lb_addr = lb_addr, .up_addr = up_addr };
    }
};
pub const ArenaReference = struct {
    index: comptime_int,
    options: Options = .{},
    fn arena(comptime arena_ref: ArenaReference, comptime AddressSpace: type) Arena {
        return AddressSpace.arena(arena_ref.index);
    }
};

// Maybe make generic on Endian.
// Right now it is difficult to get Zig vectors to produce consistent results,
// so this is not an option.
pub fn DiscreteBitSet(comptime bits: u16) type {
    return extern struct {
        bits: Data = if (data_info == .Array) [1]usize{0} ** data_info.Array.len else 0,
        const BitSet: type = @This();
        const Data: type = meta.UniformData(bits);
        const Word: type = if (data_info == .Array) data_info.Array.child else Data;
        const Index: type = meta.LeastRealBitSize(bits);
        const word_size: u8 = @bitSizeOf(usize);
        const real_bit_size: u16 = meta.alignAW(bits);
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
        pub fn set(safe_set: *SafeSet, index: usize) void {
            safe_set.bytes[index] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: usize) void {
            safe_set.bytes[index] = 0;
        }
        pub fn atomicSet(safe_set: *SafeSet, index: usize) bool {
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
        pub fn atomicUnset(safe_set: *SafeSet, index: usize) bool {
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
        pub fn check(safe_set: SafeSet, pos: usize) bool {
            return safe_set.bytes[pos] == 255;
        }
    };
}
fn GenericMultiSet(
    comptime spec: ExactAddressSpaceSpec,
    comptime directory: ExactAddressSpaceSpec.Directory(spec),
    comptime Fields: type,
) type {
    return extern struct {
        fields: Fields = .{},
        const MultiSet: type = @This();
        const Index: type = ExactAddressSpaceSpec.Index(spec);
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
        fn check(multi_set: *MultiSet, comptime index: Index) bool {
            return multi_set.fields[directory[index].field_index].check(directory[index].arena_index);
        }
    };
}
pub const ExactAddressSpaceSpec = struct {
    list: List,
    options: Options = .{},
    /// Constructing the implementation at compile time can be expensive, so
    /// in polished programs consider rendering the required values. Try
    /// file.noexcept.write(2, fmt.any().formatConvert());
    preset: ?Preset = null,

    const Preset = struct { directory: *const anyopaque, Fields: type };

    const Specification: type = @This();
    const List = []const Arena;
    fn Index(comptime spec: ExactAddressSpaceSpec) type {
        return meta.LeastRealBitSize(spec.list.len);
    }
    fn Metadata(comptime spec: ExactAddressSpaceSpec) type {
        return struct { field_index: Index(spec), arena_index: Index(spec) };
    }
    fn Directory(comptime spec: ExactAddressSpaceSpec) type {
        return [spec.list.len]Metadata(spec);
    }
    fn Implementation(comptime spec: ExactAddressSpaceSpec) type {
        if (spec.preset) |preset| {
            const directory: Directory(spec) = mem.pointerOpaque(Directory(spec), preset.directory).*;
            return GenericMultiSet(spec, directory, preset.Fields);
        } else {
            var directory: Directory(spec) = undefined;
            var fields: []const builtin.StructField = meta.empty;
            var thread_safe_state: bool = spec.list[0].options.thread_safe;
            var arena_index: Index(spec) = 0;
            for (spec.list) |arena, index| {
                if (thread_safe_state and !arena.options.thread_safe) {
                    const T: type = ThreadSafeSet(arena_index + 1);
                    fields = fields ++ meta.parcel(meta.structField(T, builtin.fmt.ci(fields.len), .{}));
                    directory[index] = .{ .arena_index = 0, .field_index = fields.len };
                    arena_index = 1;
                } else if (!thread_safe_state and arena.options.thread_safe) {
                    const T: type = DiscreteBitSet(arena_index + 1);
                    fields = fields ++ meta.parcel(meta.structField(T, builtin.fmt.ci(fields.len), .{}));
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
                fields = fields ++ meta.parcel(meta.structField(T, builtin.fmt.ci(fields.len), .{}));
            } else {
                const T: type = DiscreteBitSet(arena_index + 1);
                fields = fields ++ meta.parcel(meta.structField(T, builtin.fmt.ci(fields.len), .{}));
            }
            if (fields.len == 1) {
                return fields[0].type;
            }
            var type_info: builtin.Type = meta.tupleInfo(fields);
            type_info.Struct.layout = .Extern;
            const T: type = @Type(type_info);
            return GenericMultiSet(spec, directory, T);
        }
    }
};
const Formula = struct {
    lb_addr: usize = lb_addr,
    ab_addr: usize = ab_addr,
    xb_addr: usize = xb_addr,
    up_addr: usize = up_addr,
    divisions: usize = 8,
    alignment: usize = page_size,

    const lb_addr: usize = 0;
    const ab_addr: usize = safe_zone;
    const up_addr: usize = 1 << shift_amt;
    const xb_addr: usize = up_addr - safe_zone;
    const divisions: u16 = 8;
    const page_size: u16 = 4096;
    const shift_amt: u16 = @min(48, @bitSizeOf(usize)) - 1;
    const safe_zone: u64 = 0x40000000;
};
const FormulaicAddressSpaceSpec = struct {
    formula: Formula = .{},
    options: Options = .{},
    fn Implementation(comptime spec: FormulaicAddressSpaceSpec) type {
        if (spec.options.thread_safe) {
            return ThreadSafeSet(spec.formula.divisions);
        } else {
            return DiscreteBitSet(spec.formula.divisions);
        }
    }
};

pub const SubInitializer = struct {
    super_list: []const ArenaReference,
    addr_spec: union(enum) {
        formulaic: FormulaicAddressSpaceSpec,
        exact: ExactAddressSpaceSpec,
    },
    pub fn AddressSpace(comptime sub_init: SubInitializer) type {
        switch (sub_init.addr_spec) {
            .formulaic => |spec| {
                return GenericFormulaicAddressSpace(spec);
            },
            .exact => |spec| {
                return GenericExactAddressSpace(spec);
            },
        }
    }
};

pub const SubSpaceSpec = struct {
    AddressSpace: type,

    list: ?[]const ArenaReference,
    redefine: ?Redefine,

    const Redefine = union(enum) {
        list: []const Arena,
        formula: Formula,
    };

    fn isFormulaic(comptime AddressSpace: type, list: []const ArenaReference) bool {
        var safety: ?bool = null;
        var addr: ?usize = null;
        for (list) |item| {
            if (safety) |prev| {
                if (item.options.thread_safe != prev) {
                    return false;
                }
            } else {
                safety = item.options.thread_safe;
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

    // Make formulaic with hints or bust
    fn userHelperListRedefineFormula(
        comptime AddressSpace: type,
        comptime super_list: []const ArenaReference,
        comptime spec: FormulaicAddressSpaceSpec,
    ) void {
        return struct {
            const SubAddressSpace = GenericExactAddressSpace(spec);
            comptime {
                if (builtin.is_correct) {}
            }
            pub fn reserve(comptime address_space: *AddressSpace) SubAddressSpace {
                var s_index: AddressSpace.Index = 0;
                while (s_index != super_list.len) : (s_index += 1) {
                    if (super_list[s_index].options.thread_safe) {
                        if (!address_space.set(s_index)) break;
                    }
                }
                return .{};
            }
        };
    }
    // Make exact or error
    pub fn userHelperRedefineExact(comptime AddressSpace: type, comptime spec: ExactAddressSpaceSpec) SubInitializer {
        var super_list: []const ArenaReference = meta.empty;
        var t_index: AddressSpace.Index = 0;
        if (@TypeOf(AddressSpace.addr_spec) == ExactAddressSpaceSpec) {
            lo: while (t_index != spec.list.len) : (t_index += 1) {
                var capacity: usize = 0;
                var s_index: AddressSpace.Index = 0;
                while (s_index != AddressSpace.addr_spec.list.len) : (s_index += 1) {
                    if (spec.list[t_index].intersection(AddressSpace.addr_spec.list[s_index])) |intrs| {
                        capacity += intrs.capacity();
                        super_list = meta.concat(super_list, .{ .index = s_index, .options = AddressSpace.arena(s_index).options });
                    }
                    if (capacity == spec.list[t_index].capacity()) {
                        continue :lo;
                    }
                }
                builtin.assertEqual(usize, capacity, spec.list[t_index].capacity());
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
                super_list = meta.concat(super_list, .{ .index = s_index, .options = AddressSpace.arena(s_index).options });
            }
        }
        return .{ .super_list = super_list, .addr_spec = .{ .exact = spec } };
    }
    // Make formulaic or error
    fn userHelperRedefineFormulaic(comptime AddressSpace: type, comptime spec: FormulaicAddressSpaceSpec) void {
        if (@TypeOf(AddressSpace.addr_spec) == ExactAddressSpaceSpec) {} else {}
        AddressSpace.invert(spec.formula.low);
        AddressSpace.invert(spec.formula.high);
    }
    // Make it work with hint
    fn userHelperList(comptime AddressSpace: type, comptime super_list: []const ArenaReference) void {
        if (isFormulaic(AddressSpace, super_list)) {}
    }
};

/// Exact:
/// Good:
///     * Arbitrary ranges.
///     * Maps directly to an arena.
/// Bad:
///     * Arena index must be known at compile time.
///     * Inversion is expensive.
///     * Constructing the bit set fields can be expensive at compile time.
pub fn GenericExactAddressSpace(comptime spec: ExactAddressSpaceSpec) type {
    return extern struct {
        impl: Implementation align(8) = .{},
        const AddressSpace = @This();
        pub const Implementation: type = spec.Implementation();
        pub const Index: type = Implementation.Index;
        pub const addr_spec: ExactAddressSpaceSpec = spec;
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
            if (!spec.list[index].options.thread_safe) {
                @compileError("arena is not thread safe");
            }
            return address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *AddressSpace, comptime index: Index) bool {
            if (!spec.list[index].options.thread_safe) {
                @compileError("arena is not thread safe");
            }
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
        pub fn reserve(
            comptime address_space: *AddressSpace,
            comptime sub_init: SubInitializer,
        ) SubInitializer.AddressSpace(sub_init) {
            comptime var s_index: AddressSpace.Index = 0;
            inline while (s_index != sub_init.super_list.len) : (s_index += 1) {
                if (sub_init.super_list[s_index].options.thread_safe) {
                    if (!address_space.set(s_index)) break;
                }
            }
            return .{};
        }
    };
}
/// Formulaic:
/// Good:
///     * Good locality associated with computing the begin and end addresses
///       using the arena index alone.
///     * Thread safety is all-or-nothing, therefore requesting atomic
///       operations from a thread-unsafe address space yields a compile error.
/// Bad:
///     * Poor flexibility.
///     * Formula results must be tightly constrained or checked.
///     * Arenas can not be independently configured.
///     * Thread safety is all-or-nothing, which increases the metadata size
///       required by each arena from 1 to 8 bits.
pub fn GenericFormulaicAddressSpace(comptime spec: FormulaicAddressSpaceSpec) type {
    return extern struct {
        impl: Implementation align(8) = .{},
        const AddressSpace = @This();
        pub const Index: type = meta.AlignSizeAW(builtin.ShiftAmount(u64));
        pub const Implementation: type = spec.Implementation();
        pub const addr_spec: FormulaicAddressSpaceSpec = spec;
        const len: usize = blk: {
            const mask: usize = spec.alignment - 1;
            const value: usize = spec.high / spec.divisions;
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
            if (!spec.options.thread_safe) {
                @compileError("address space is not thread safe");
            }
            return address_space.impl.atomicUnset(index);
        }
        pub fn atomicSet(address_space: *AddressSpace, index: Index) bool {
            if (!spec.options.thread_safe) {
                @compileError("address space is not thread safe");
            }
            return address_space.impl.atomicSet(index);
        }
        pub fn low(index: Index) usize {
            return @max(spec.start, len * index);
        }
        pub fn high(index: Index) usize {
            return @min(spec.finish, len * (index + 1));
        }
        pub fn invert(addr: usize) Index {
            return @intCast(u7, addr / len);
        }
        pub fn arena(comptime index: Index) Arena {
            return .{
                .lb_addr = low(index),
                .up_addr = high(index),
                .options = addr_spec.options.thread_safe,
            };
        }
    };
}
