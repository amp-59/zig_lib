//! Experimental
//!
//! The address space is currently divided 127 times to allow allocators and
//! threads to manage mapped segments without possibility of collision.
//!
const mem = @import("./mem.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub const Arena = struct {
    low: usize,
    high: usize,
    options: Options = .{},
    const Options = struct {
        thread_safe: bool = false,
    };
};

// Maybe make generic on Endian.
// Right now it is difficult to get Zig vectors to produce consistent results,
// so this is not an option.
pub fn DiscreteBitSet(comptime bits: u16) type {
    return struct {
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
    return struct {
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
    return struct {
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
    const Specification: type = @This();
    const List = []const Arena;
    const Options = struct {
        prefer_word_size: bool = true,
        /// Constructing the implementation at compile time can be expensive, so
        /// in polished programs consider rendering the required values. Try
        /// file.noexcept.write(2, fmt.any().formatConvert());
        preset: ?Preset = null,
    };
    const Preset = struct { directory: *const anyopaque, Fields: type };
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
        if (spec.options.preset) |preset| {
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
            const T: type = @Type(meta.tupleInfo(fields));
            return GenericMultiSet(spec, directory, T);
        }
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
pub fn ExactAddressSpace(comptime spec: ExactAddressSpaceSpec) type {
    return struct {
        impl: Implementation = .{},
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
        pub fn low(comptime index: Index) usize {
            return spec.list[index].low;
        }
        pub fn high(comptime index: Index) usize {
            return spec.list[index].high;
        }
        pub fn arena(comptime index: Index) Arena {
            return spec.list[index];
        }
    };
}
const FormulaicAddressSpaceSpec = struct {
    low: usize = 0,
    start: usize = safe_zone,
    finish: usize = (1 << shift_amt) - safe_zone,
    high: usize = 1 << shift_amt,
    divisions: usize = 8,
    alignment: usize = 4096,
    options: Options = .{},

    const shift_amt: comptime_int = @min(48, @bitSizeOf(usize)) - 1;
    const safe_zone: comptime_int = 0x40000000;

    const Options = struct {
        /// All arenas thread safe
        thread_safe: bool = true,
        /// Use bytes instead of bits when efficient
        prefer_word_size: bool = true,
    };
    fn Implementation(comptime spec: FormulaicAddressSpaceSpec) type {
        const BitSet: type = DiscreteBitSet(spec.divisions);
        if (spec.options.prefer_word_size) {
            const SafeSet: type = ThreadSafeSet(spec.divisions);
            if (@sizeOf(SafeSet) <= @sizeOf(usize) or spec.options.thread_safe) {
                return SafeSet;
            }
        }
        return BitSet;
    }
};
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
pub fn FormulaicAddressSpace(comptime spec: FormulaicAddressSpaceSpec) type {
    return struct {
        impl: Implementation = .{},
        const AddressSpace = @This();
        pub const Index: type = meta.AlignSizeAW(builtin.ShiftAmount(u64));
        pub const Implementation: type = spec.Implementation();
        pub const addr_spec: FormulaicAddressSpaceSpec = spec;
        const len: usize = blk: {
            const mask: usize = spec.alignment - 1;
            const value: usize = spec.high / spec.divisions;
            break :blk (value + mask) & ~mask;
        };
        comptime {
            builtin.static.assertAboveOrEqual(usize, spec.start, spec.low);
            builtin.static.assertBelowOrEqual(usize, spec.finish, spec.high);
            builtin.static.assertEqual(usize, spec.start, low(0));
            builtin.static.assertEqual(usize, spec.high, low(spec.divisions));
        }
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
        pub fn arena(index: Index) Arena {
            return .{
                .high = high(index),
                .low = low(index),
                .options = .{ .thread_safe = spec.options.thread_safe },
            };
        }
    };
}

/// If the list of indices is continuous and the safety of all the sub space
/// can be formulaic, otherwise an exact sub space must be constructed.
const SubArena = struct {
    index: comptime_int,
    options: Options = .{},

    const Options = struct {
        thread_safe: ?bool = null,
    };
};
const SubSpaceSpec = struct {
    AddressSpace: type,
    list: []const SubArena,

    fn isContinuous(comptime spec: SubSpaceSpec) bool {
        var index: ?usize = null;
        for (spec.list) |item| {
            if (index) |prev| {
                if (item.index == prev + 1) {
                    prev = item.index;
                } else {
                    return false;
                }
            } else {
                index = item.index;
            }
        }
        return true;
    }
    fn isUniformSafety(comptime spec: SubSpaceSpec) bool {
        var safety: ?usize = null;
        for (spec.list) |item| {
            if (safety) |prev| {
                if (item.options.thread_safe != prev) {
                    return false;
                }
            } else {
                safety = item.options.thread_safe;
            }
        }
        return true;
    }
    fn isParentFormulaic(comptime spec: SubSpaceSpec) bool {
        return @TypeOf(spec.AddressSpace.addr_spec) == FormulaicAddressSpaceSpec;
    }
    fn isFormulaic(comptime spec: SubSpaceSpec) bool {
        return isParentFormulaic(spec) and isContinuous(spec) and isUniformSafety(spec);
    }
};
