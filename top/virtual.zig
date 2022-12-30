//! Experimental
//!
//! The address space is currently divided 127 times to allow allocators and
//! threads to manage mapped segments without possibility of collision.

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

/// Maybe make generic on Endian.
/// Right now it is difficult to get Zig vectors to produce consistent results,
/// so this is not an option.
pub fn DiscreteBitSet(comptime bits: u16) type {
    return struct {
        bits: Data = if (data_info == .Array) [1]usize{0} ** data_info.Array.len else 0,
        const BitSet: type = @This();
        const Data: type = switch (bits) {
            0...word_size => @Type(.{ .Int = .{ .bits = real_bit_size, .signedness = .unsigned } }),
            else => [(bits / word_size) + builtin.int(u16, builtin.rem(u16, bits, word_size) != 0)]usize,
        };
        const Word: type = switch (data_info) {
            .Array => |array_info| array_info.child,
            else => Data,
        };
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
        bits: [divisions]u8 = .{0} ** divisions,

        const SafeSet: type = @This();

        pub fn set(safe_set: *SafeSet, index: usize) void {
            safe_set.bits[index] = 255;
        }
        pub fn unset(safe_set: *SafeSet, index: usize) void {
            safe_set.bits[index] = 0;
        }
        pub fn atomicSet(safe_set: *SafeSet, index: usize) bool {
            return asm volatile (
                \\mov           $0,     %al
                \\mov           $255,   %dl
                \\lock cmpxchg  %dl,    %[ptr]
                \\sete          %[ret]
                : [ret] "=r" (-> bool),
                : [ptr] "p" (&safe_set.bits[index]),
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
                : [ptr] "p" (&safe_set.bits[index]),
                : "rax", "rdx", "memory"
            );
        }
        pub fn check(safe_set: SafeSet, pos: usize) bool {
            return safe_set.bits[pos] == 255;
        }
    };
}

const FormulaicAddressSpaceSpec = struct {
    low: usize = 0x40000000,
    high: usize = ~@as(usize, 0),
    divisions: usize = 8,
    alignment: usize = 4096,
    options: Options = .{},
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
///  Pro: * Good locality associated with computing the begin and end addresses
///         using the arena index alone.
///       * Thread safety is all-or-nothing, therefore requesting atomic
///         operations from a thread-unsafe address space yields a compile error.
///
///  Con: * Poor flexibility.
///       * Formula results must be tightly constrained or checked.
///       * Arenas can not be independently configured.
///       * Thread safety is all-or-nothing, which increases the metadata size
///         required by each arena from 1 to 8 bits.
///
pub fn FormulaicAddressSpace(comptime spec: FormulaicAddressSpaceSpec) type {
    return struct {
        impl: Implementation = .{},
        const AddressSpace = @This();
        const Index: type = meta.AlignSizeAW(builtin.ShiftAmount(u64));
        const Implementation: type = spec.Implementation();
        const addr_spec: FormulaicAddressSpaceSpec = spec;
        const max_bit: usize = 1 << 47;
        const len: usize = blk: {
            const mask: usize = spec.alignment - 1;
            const value: usize = max_bit / spec.divisions;
            break :blk (value + mask) & ~mask;
        };
        comptime {
            builtin.static.assertBelowOrEqual(usize, spec.low, high(0));
            builtin.static.assertAboveOrEqual(usize, spec.high, low(spec.divisions));
        }

        fn unset(address_space: *AddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (ret) address_space.bits.unset(index);
            return ret;
        }
        fn set(address_space: *AddressSpace, index: Index) bool {
            const ret: bool = address_space.impl.check(index);
            if (!ret) address_space.impl.set(index);
            return ret;
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
        fn atomicUnset(address_space: *AddressSpace, index: Index) bool {
            if (!spec.options.thread_safe) {
                @compileError("address space is not thread safe");
            }
            const ret: bool = address_space.impl.check(index);
            if (ret) address_space.bits.unset(index);
            return ret;
        }
        fn atomicSet(address_space: *AddressSpace, index: Index) bool {
            if (!spec.options.thread_safe) {
                @compileError("address space is not thread safe");
            }
            const ret: bool = address_space.impl.check(index);
            if (!ret) address_space.impl.atomicSet(index);
            return ret;
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
        pub fn low(index: Index) usize {
            return len * index;
        }
        pub fn high(index: Index) usize {
            return len * (index + 1);
        }
        pub fn invert(addr: usize) Index {
            return @intCast(u7, addr / len);
        }
        pub const Arena = struct {
            index: Index,
            fn low(arena: AddressSpace.Arena) usize {
                return @max(spec.low, AddressSpace.low(arena.index));
            }
            fn high(arena: AddressSpace.Arena) usize {
                return @min(spec.high, AddressSpace.high(arena.index));
            }
        };
    };
}
