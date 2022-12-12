const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");
const reference = @import("./reference.zig");
const Amount = mem.Amount;
pub const Parameters0 = struct {
    child: type,
    sentinel: ?*const anyopaque = null,
    count: u64,
    low_alignment: ?u64 = null,
    options: Options = .{},
    const Parameters = @This();
    const Options = struct {};
    fn Specification(comptime params: Parameters) type {
        if (params.sentinel != null) {
            return reference.Specification1;
        } else {
            return reference.Specification0;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.sentinel) |sentinel| {
            return .{
                .child = params.child,
                .sentinel = sentinel,
                .count = params.count,
                .low_alignment = params.lowAlignment(),
            };
        } else {
            return .{
                .child = params.child,
                .count = params.count,
                .low_alignment = params.lowAlignment(),
            };
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn StructuredAutomaticView(comptime params: Parameters0) type {
    return struct {
        impl: Implementation = .{},
        const Memory = @This();
        const Functions = StructuredAutomaticViewFunctions(Memory);
        pub const Implementation: type = spec.deduce(.read_write_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child: type = params.child;
        pub const child_size: u64 = @sizeOf(child);
        pub usingnamespace Functions;
    };
}
fn StructuredAutomaticViewFunctions(comptime Memory: type) type {
    return struct {
        pub fn readAll(memory: *const Memory) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.capacity());
        }
        pub fn readAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.capacity(), sentinel);
        }
        pub fn referAll(memory: *const Memory) []Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.capacity());
        }
        pub fn referAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.capacity(), sentinel);
        }
        pub fn readOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn readCountAt(memory: *const Memory, offset: usize, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn readManyAt(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn readCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn readManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn referOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn referCountAt(memory: *const Memory, offset: usize, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn referManyAt(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn referCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn referManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn overwriteOneAt(memory: *Memory, offset: usize, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __at(memory, offset)), value);
        }
        pub fn overwriteCountAt(memory: *Memory, offset: usize, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __at(memory, offset), count), values);
        }
        pub fn overwriteManyAt(memory: *Memory, offset: usize, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            ), values);
        }
        inline fn __count(memory: *const Memory) u64 {
            return memory.impl.capacity() / Memory.child_size;
        }
        inline fn __at(memory: *const Memory, offset: u64) u64 {
            return mach.add64(memory.impl.start(), offset * Memory.child_size);
        }
        inline fn __len(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(__count(memory), offset);
        }
    };
}
pub fn StructuredAutomaticStreamView(comptime params: Parameters0) type {
    return struct {
        impl: Implementation = .{ .ss_word = 0 },
        const Memory = @This();
        const Functions = StructuredAutomaticStreamViewFunctions(Memory);
        pub const Implementation: type = spec.deduce(.read_write_stream_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child: type = params.child;
        pub const child_size: u64 = @sizeOf(child);
        pub usingnamespace Functions;
    };
}
fn StructuredAutomaticStreamViewFunctions(comptime Memory: type) type {
    return struct {
        pub fn readAll(memory: *const Memory) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.capacity());
        }
        pub fn readAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.capacity(), sentinel);
        }
        pub fn referAll(memory: *const Memory) []Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.capacity());
        }
        pub fn referAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.capacity(), sentinel);
        }
        pub fn readOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn readCountAt(memory: *const Memory, offset: usize, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn readManyAt(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn readCountBehind(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __behind(memory, count), count).*;
        }
        pub fn readManyBehind(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, __behind(memory, offset), offset);
        }
        pub fn readCountAhead(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, memory.impl.position(), count).*;
        }
        pub fn readManyAhead(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn readManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn readCountWithSentinelBehind(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __behind(memory, count), count, sentinel).*;
        }
        pub fn readManyWithSentinelBehind(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, __behind(memory, offset), offset, sentinel);
        }
        pub fn readCountWithSentinelAhead(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, memory.impl.position(), count, sentinel).*;
        }
        pub fn readManyWithSentinelAhead(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.position(), offset, sentinel);
        }
        pub fn referOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn referCountAt(memory: *const Memory, offset: usize, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn referManyAt(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn referCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn referManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn referCountWithSentinelBehind(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __behind(memory, count), count, sentinel).*;
        }
        pub fn referManyWithSentinelBehind(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, __behind(memory, offset), offset, sentinel);
        }
        pub fn overwriteOneAt(memory: *Memory, offset: usize, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __at(memory, offset)), value);
        }
        pub fn overwriteCountAt(memory: *Memory, offset: usize, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __at(memory, offset), count), values);
        }
        pub fn overwriteManyAt(memory: *Memory, offset: usize, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            ), values);
        }
        inline fn __count(memory: *const Memory) u64 {
            return memory.impl.capacity() / Memory.child_size;
        }
        inline fn __at(memory: *const Memory, offset: u64) u64 {
            return mach.add64(memory.impl.start(), offset * Memory.child_size);
        }
        inline fn __len(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(__count(memory), offset);
        }
        inline fn __behind(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(memory.impl.position(), offset * Memory.child_size);
        }
        pub fn stream(memory: *Memory, count: u64) void {
            memory.impl.seek(count);
        }
        pub fn streamAll(memory: *Memory) void {
            memory.impl.seek(memory.impl.available());
        }
        pub fn unstream(memory: *Memory, count: u64) void {
            memory.impl.tell(count);
        }
        pub fn unstreamAll(memory: *Memory) void {
            memory.impl.tell(memory.impl.length());
        }
    };
}
pub fn StructuredAutomaticStreamVector(comptime params: Parameters0) type {
    return struct {
        impl: Implementation = .{ .ub_word = 0, .ss_word = 0 },
        const Memory = @This();
        const Functions = StructuredAutomaticStreamVectorFunctions(Memory);
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child: type = params.child;
        pub const child_size: u64 = @sizeOf(child);
        pub usingnamespace Functions;
    };
}
fn StructuredAutomaticStreamVectorFunctions(comptime Memory: type) type {
    return struct {
        pub fn readAll(memory: *const Memory) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.length());
        }
        pub fn readAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.length(), sentinel);
        }
        pub fn referAll(memory: *const Memory) []Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.length());
        }
        pub fn referAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.length(), sentinel);
        }
        pub fn readOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn readCountAt(memory: *const Memory, offset: usize, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn readManyAt(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn readOneBack(memory: *const Memory) Memory.child {
            return mem.pointerOne(Memory.child, __prev(memory, 1)).*;
        }
        pub fn readCountBack(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __prev(memory, count), count).*;
        }
        pub fn readManyBack(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, __prev(memory, offset), offset);
        }
        pub fn readCountBehind(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __behind(memory, count), count).*;
        }
        pub fn readManyBehind(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, __behind(memory, offset), offset);
        }
        pub fn readCountAhead(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, memory.impl.position(), count).*;
        }
        pub fn readManyAhead(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn readManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn readCountWithSentinelBack(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __prev(memory, count), count, sentinel).*;
        }
        pub fn readManyWithSentinelBack(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, __prev(memory, offset), offset, sentinel);
        }
        pub fn readCountWithSentinelBehind(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __behind(memory, count), count, sentinel).*;
        }
        pub fn readManyWithSentinelBehind(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, __behind(memory, offset), offset, sentinel);
        }
        pub fn readCountWithSentinelAhead(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, memory.impl.position(), count, sentinel).*;
        }
        pub fn readManyWithSentinelAhead(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.position(), offset, sentinel);
        }
        pub fn referOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn referCountAt(memory: *const Memory, offset: usize, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn referManyAt(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn referOneBack(memory: *const Memory) Memory.child {
            return mem.pointerOne(Memory.child, __prev(memory, 1)).*;
        }
        pub fn referCountBack(memory: *const Memory, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __prev(memory, count), count).*;
        }
        pub fn referManyBack(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(Memory.child, __prev(memory, offset), offset);
        }
        pub fn referCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn referManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn referCountWithSentinelBack(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __prev(memory, count), count, sentinel).*;
        }
        pub fn referManyWithSentinelBack(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, __prev(memory, offset), offset, sentinel);
        }
        pub fn referCountWithSentinelBehind(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __behind(memory, count), count, sentinel).*;
        }
        pub fn referManyWithSentinelBehind(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, __behind(memory, offset), offset, sentinel);
        }
        pub fn overwriteOneAt(memory: *Memory, offset: usize, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __at(memory, offset)), value);
        }
        pub fn overwriteCountAt(memory: *Memory, offset: usize, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __at(memory, offset), count), values);
        }
        pub fn overwriteManyAt(memory: *Memory, offset: usize, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            ), values);
        }
        pub fn overwriteOneBack(memory: *Memory, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __prev(memory, 1)), value);
        }
        pub fn overwriteManyBack(memory: *Memory, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(Memory.child, __prev(memory, values.len), values.len), values);
        }
        pub fn overwriteCountBack(memory: *Memory, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __prev(memory, values.len), values.len), values);
        }
        pub fn writeOne(memory: *Memory, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, memory.impl.next()), value);
            memory.impl.define(Memory.child_size);
        }
        pub fn writeCount(memory: *Memory, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, memory.impl.next(), values.len), values);
            memory.impl.define(count * Memory.child_size);
        }
        pub fn writeMany(memory: *Memory, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(Memory.child, memory.impl.next(), values.len), values);
            memory.impl.define(values.len * Memory.child_size);
        }
        pub fn writeFormat(memory: *Memory, format: anytype) void {
            Reinterpret.writeFormat(Memory.child, memory, format);
        }
        pub fn writeArgs(memory: *Memory, comptime spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(Memory.child, spec, memory, arg);
        }
        pub fn writeAny(memory: *Memory, comptime spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(Memory.child, spec, memory, any);
        }
        inline fn __count(memory: *const Memory) u64 {
            return memory.impl.length() / Memory.child_size;
        }
        inline fn __at(memory: *const Memory, offset: u64) u64 {
            return mach.add64(memory.impl.start(), offset * Memory.child_size);
        }
        inline fn __len(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(__count(memory), offset);
        }
        inline fn __prev(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(memory.impl.next(), offset * Memory.child_size);
        }
        inline fn __behind(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(memory.impl.position(), offset * Memory.child_size);
        }
        pub fn define(memory: *Memory, count: u64) void {
            memory.impl.define(count);
        }
        pub fn defineAll(memory: *Memory) void {
            memory.impl.define(memory.impl.available());
        }
        pub fn undefine(memory: *Memory, count: u64) void {
            memory.impl.undefine(count);
        }
        pub fn undefineAll(memory: *Memory) void {
            memory.impl.undefine(memory.impl.length());
        }
        pub fn stream(memory: *Memory, count: u64) void {
            memory.impl.seek(count);
        }
        pub fn streamAll(memory: *Memory) void {
            memory.impl.seek(memory.impl.available());
        }
        pub fn unstream(memory: *Memory, count: u64) void {
            memory.impl.tell(count);
        }
        pub fn unstreamAll(memory: *Memory) void {
            memory.impl.tell(memory.impl.length());
        }
    };
}
pub fn StructuredAutomaticVector(comptime params: Parameters0) type {
    return struct {
        impl: Implementation = .{ .ub_word = 0 },
        const Memory = @This();
        const Functions = StructuredAutomaticVectorFunctions(Memory);
        pub const Implementation: type = spec.deduce(.read_write_push_pop_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child: type = params.child;
        pub const child_size: u64 = @sizeOf(child);
        pub usingnamespace Functions;
    };
}
fn StructuredAutomaticVectorFunctions(comptime Memory: type) type {
    return struct {
        pub fn readAll(memory: *const Memory) []const Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.length());
        }
        pub fn readAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.length(), sentinel);
        }
        pub fn referAll(memory: *const Memory) []Memory.child {
            return mem.pointerMany(Memory.child, memory.impl.start(), memory.impl.length());
        }
        pub fn referAllWithSentinel(memory: *const Memory, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, memory.impl.start(), memory.impl.length(), sentinel);
        }
        pub fn readOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn readCountAt(memory: *const Memory, offset: usize, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn readManyAt(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn readOneBack(memory: *const Memory) Memory.child {
            return mem.pointerOne(Memory.child, __prev(memory, 1)).*;
        }
        pub fn readCountBack(memory: *const Memory, comptime count: usize) [count]Memory.child {
            return mem.pointerCount(Memory.child, __prev(memory, count), count).*;
        }
        pub fn readManyBack(memory: *const Memory, offset: usize) []const Memory.child {
            return mem.pointerMany(Memory.child, __prev(memory, offset), offset);
        }
        pub fn readCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn readManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn readCountWithSentinelBack(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) [count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __prev(memory, count), count, sentinel).*;
        }
        pub fn readManyWithSentinelBack(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]const Memory.child {
            return mem.pointerManySentinel(Memory.child, __prev(memory, offset), offset, sentinel);
        }
        pub fn referOneAt(memory: *const Memory, offset: usize) Memory.child {
            return mem.pointerOne(Memory.child, __at(memory, offset)).*;
        }
        pub fn referCountAt(memory: *const Memory, offset: usize, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __at(memory, offset), count).*;
        }
        pub fn referManyAt(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            );
        }
        pub fn referOneBack(memory: *const Memory) Memory.child {
            return mem.pointerOne(Memory.child, __prev(memory, 1)).*;
        }
        pub fn referCountBack(memory: *const Memory, comptime count: usize) *[count]Memory.child {
            return mem.pointerCount(Memory.child, __prev(memory, count), count).*;
        }
        pub fn referManyBack(memory: *const Memory, offset: usize) []Memory.child {
            return mem.pointerMany(Memory.child, __prev(memory, offset), offset);
        }
        pub fn referCountWithSentinelAt(memory: *const Memory, offset: usize, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __at(memory, offset), count, sentinel).*;
        }
        pub fn referManyWithSentinelAt(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
                sentinel,
            );
        }
        pub fn referCountWithSentinelBack(memory: *const Memory, comptime count: usize, comptime sentinel: Memory.child) *[count:sentinel]Memory.child {
            return mem.pointerCountSentinel(Memory.child, __prev(memory, count), count, sentinel).*;
        }
        pub fn referManyWithSentinelBack(memory: *const Memory, offset: usize, comptime sentinel: Memory.child) [:sentinel]Memory.child {
            return mem.pointerManySentinel(Memory.child, __prev(memory, offset), offset, sentinel);
        }
        pub fn overwriteOneAt(memory: *Memory, offset: usize, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __at(memory, offset)), value);
        }
        pub fn overwriteCountAt(memory: *Memory, offset: usize, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __at(memory, offset), count), values);
        }
        pub fn overwriteManyAt(memory: *Memory, offset: usize, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(
                Memory.child,
                __at(memory, offset),
                __len(memory, offset),
            ), values);
        }
        pub fn overwriteOneBack(memory: *Memory, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, __prev(memory, 1)), value);
        }
        pub fn overwriteManyBack(memory: *Memory, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(Memory.child, __prev(memory, values.len), values.len), values);
        }
        pub fn overwriteCountBack(memory: *Memory, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, __prev(memory, values.len), values.len), values);
        }
        pub fn writeOne(memory: *Memory, value: Memory.child) void {
            writeOneImpl(Memory.child, mem.pointerOne(Memory.child, memory.impl.next()), value);
            memory.impl.define(Memory.child_size);
        }
        pub fn writeCount(memory: *Memory, comptime count: usize, values: [count]Memory.child) void {
            writeCountImpl(Memory.child, count, mem.pointerCount(Memory.child, memory.impl.next(), values.len), values);
            memory.impl.define(count * Memory.child_size);
        }
        pub fn writeMany(memory: *Memory, values: []const Memory.child) void {
            writeManyImpl(Memory.child, mem.pointerMany(Memory.child, memory.impl.next(), values.len), values);
            memory.impl.define(values.len * Memory.child_size);
        }
        pub fn writeFormat(memory: *Memory, format: anytype) void {
            Reinterpret.writeFormat(Memory.child, memory, format);
        }
        pub fn writeArgs(memory: *Memory, comptime spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(Memory.child, spec, memory, arg);
        }
        pub fn writeAny(memory: *Memory, comptime spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(Memory.child, spec, memory, any);
        }
        inline fn __count(memory: *const Memory) u64 {
            return memory.impl.length() / Memory.child_size;
        }
        inline fn __at(memory: *const Memory, offset: u64) u64 {
            return mach.add64(memory.impl.start(), offset * Memory.child_size);
        }
        inline fn __len(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(__count(memory), offset);
        }
        inline fn __prev(memory: *const Memory, offset: u64) u64 {
            return mach.sub64(memory.impl.next(), offset * Memory.child_size);
        }
        pub fn define(memory: *Memory, count: u64) void {
            memory.impl.define(count);
        }
        pub fn defineAll(memory: *Memory) void {
            memory.impl.define(memory.impl.available());
        }
        pub fn undefine(memory: *Memory, count: u64) void {
            memory.impl.undefine(count);
        }
        pub fn undefineAll(memory: *Memory) void {
            memory.impl.undefine(memory.impl.length());
        }
    };
}

fn GenericParameters(comptime Parameters: type) type {
    return struct {
        pub fn convert(comptime params: Parameters, comptime T: type) T {
            return mem.genericConvert(Parameters, T, params);
        }
        pub fn highAlignment(comptime params: Parameters) u64 {
            if (@hasField(Parameters, "high_alignment")) {
                return params.high_alignment;
            }
            if (@hasField(Parameters, "child")) {
                return @sizeOf(params.child);
            }
            if (params.low_alignment) |low_alignment| {
                return low_alignment;
            }
            @compileError(@typeName(Parameters) ++
                ": no high address alignment, child size, or low " ++
                "addess alignment defined in container parameters");
        }
        pub fn lowAlignment(comptime params: Parameters) u64 {
            if (params.low_alignment) |low_alignment| {
                return low_alignment;
            }
            if (@hasField(Parameters, "child")) {
                return @alignOf(params.child);
            }
            if (@hasField(Parameters, "high_alignment")) {
                return params.high_alignment;
            }
            @compileError(@typeName(Parameters) ++
                ": no low address alignment, child size, or high " ++
                "addess alignment defined in container parameters");
        }
        pub fn unitAlignment(comptime params: Parameters) u64 {
            if (@hasDecl(params.Allocator, "allocator_spec")) {
                const AllocatorSpec: type = @TypeOf(params.Allocator.allocator_spec);
                if (@hasField(AllocatorSpec, "unit_alignment")) {
                    return params.Allocator.allocator_spec.unit_alignment;
                }
                const AllocatorSpecOptions: type = @TypeOf(params.Allocator.allocator_spec.options);
                if (@hasField(AllocatorSpecOptions, "unit_alignment")) {
                    return params.Allocator.allocator_spec.options.unit_alignment;
                }
            }
            if (@hasDecl(params.Allocator, "unit_alignment")) {
                return params.Allocator.unit_alignment;
            }
            @compileError(@typeName(Parameters) ++
                ": no unit aligment defined in Allocator declarations, " ++
                "specification, or specification options");
        }
        pub fn arenaIndex(comptime params: Parameters) ?u64 {
            if (@hasDecl(params.Allocator, "arena_index")) {
                return params.Allocator.arena_index;
            }
            if (@hasDecl(params.Allocator, "allocator_spec")) {
                const AllocatorOptions: type = @TypeOf(params.Allocator.allocator_spec.options);
                if (@hasField(AllocatorOptions, "arena_index")) {
                    return params.Allocator.allocator_spec.options.arena_index;
                }
            }
            return null;
        }
    };
}
fn writeOneImpl(comptime T: type, dst: *T, src: T) void {
    dst.* = src;
}
fn writeManyImpl(comptime T: type, dst: []T, src: []const T) void {
    for (dst) |*value, i| value.* = src[i];
}
fn writeCountImpl(comptime T: type, comptime count: u64, dst: *[count]T, src: [count]T) void {
    if (builtin.is_small) {
        @call(
            .{ .modifier = .always_inline },
            writeManyImpl,
            .{ T, dst, &src },
        );
    } else {
        @call(
            .{ .modifier = .always_inline },
            writeOneImpl,
            .{ [count]T, dst, src },
        );
    }
}
pub const ReinterpretSpec = struct {
    integral: Integral = .{},
    aggregate: Aggregate = .{},
    composite: Composite = .{},
    reference: Reference = .{},
    symbol: Symbol = .{},
    options: Options = .{},
    const Integral = struct {
        /// Attempt to write over_size integer types
        over_size: bool = false,
        /// Write under_size integer types
        under_size: bool = false,
        /// Write floating point type to integer type
        float: bool = false,
        /// Write integer type to floating pointer type
        int: bool = false,
        /// Attempt to write comptime known integers
        comptime_int: bool = true,
        /// Attempt to write comptime known floats
        comptime_float: bool = true,
    };
    const Aggregate = struct {
        /// Copy @size(..child) bytes from *..child to end of range
        copy: bool = true,
        /// Resubmit each element of input separately for writing
        iterate: bool = false,
    };
    const Composite = struct {
        /// Applies to structs Call struct formatter
        format: bool = false,
        /// Iterate over tuple argments
        iterate: bool = true,
    };
    const Reference = struct {
        /// Resubmit dereferenced value with new anytype
        dereference: ?*const ReinterpretSpec = null,
        /// increment pointer properties
        coerce: struct {
            /// Allow copying pointers to arrays to slices
            array: bool = true,
            /// Allow copying terminated pointers-to-many to slices
            many: bool = true,
            /// Allow copying aligned (above) pointers to aligned (below) pointers
            alignment: bool = false,
            /// Allow copying terminated pointers to non-terminated pointers
            sentinel: bool = true,
            /// Allow copying non-const pointers to const pointers
            mutability: bool = false,
            /// Allow copying nullable pointers to non-nullable pointers
            nullability: bool = false,
        } = .{},
    };
    /// The following apply to byte arrays (strings) only.
    const Symbol = struct {
        /// Convert enum and enum_literal to string. For enum use the length of
        /// the longest tag_name in the type.
        tag_name: bool = false,
        /// Convert error to string. Use the longest error_name in the set.
        error_name: bool = false,
        /// Convert type to string. Length is always compile-time-known.
        type_name: bool = false,
    };
    const Options = struct {
        /// If variable check and panic
        bounds: struct {
            Array: enum(u1) {
                /// Assert capacity of the destination is above or equal
                /// to the size of the source, aborting with error message if
                /// this test fails. (Debug)
                check_capacity_assert,
                /// Write to end without checks (ReleaseFast)
                assert_capacity,
            } = if (builtin.is_correct) .check_capacity_assert else .assert_capacity,
            Pointer: enum(u2) {
                /// Assert capacity of the destination is above or equal
                /// to the size of the source, aborting with error message if
                /// this test fails.
                check_capacity_assert,
                /// Test capacity of the destination is above or equal
                /// to the size of the source,
                check_capacity_increment,
                /// Write to end without checks
                assert_capacity,
            } = .check_capacity_increment,
        } = .{},
    };
};

const Reinterpret = struct {
    const validate_format_length: bool = false;

    fn isEquivalent(comptime child: type, comptime write_spec: ReinterpretSpec, comptime dst_type: type, comptime src_type: type) bool {
        const dst_type_info: meta.Type = @typeInfo(dst_type);
        const src_type_info: meta.Type = @typeInfo(src_type);
        if (comptime dst_type_info == .Optional and
            src_type_info == .Optional)
        blk: {
            const dst_child_type_id: meta.TypeId = @typeInfo(dst_type_info.Optional.child);
            const src_child_type_id: meta.TypeId = @typeInfo(src_type_info.Optional.child);
            if (comptime dst_child_type_id != src_child_type_id) {
                break :blk;
            }
            return isEquivalent(child, write_spec, dst_type_info.Optional.child, src_type_info.Optional.child);
        }
        if (comptime dst_type_info == .Array and
            src_type_info == .Array)
        blk: {
            const dst_child_type_id: meta.TypeId = @typeInfo(dst_type_info.Array.child);
            const src_child_type_id: meta.TypeId = @typeInfo(src_type_info.Array.child);
            if (comptime dst_child_type_id != src_child_type_id) {
                break :blk;
            }
            if (comptime dst_type_info.Array.sentinel != null) {
                if (comptime dst_type_info.Array.sentinel != src_type_info.Array.sentinel) {
                    break :blk;
                }
            } else if (comptime src_type_info.Array.sentinel != null) {
                if (comptime !write_spec.reference.coerce.sentinel) {
                    break :blk;
                }
            }
            return isEquivalent(child, write_spec, dst_type_info.Array.child, src_type_info.Array.child);
        }
        if (comptime dst_type_info == .Pointer and
            src_type_info == .Pointer)
        {
            const dst_child_type_id: meta.TypeId = @typeInfo(dst_type_info.Pointer.child);
            const src_child_type_id: meta.TypeId = @typeInfo(src_type_info.Pointer.child);
            if (comptime dst_type_info.Pointer.size == src_type_info.Pointer.size) blk: {
                if (comptime dst_child_type_id != src_child_type_id) {
                    break :blk;
                }
                if (comptime write_spec.reference.coerce.mutability) {
                    if (comptime dst_type_info.Pointer.is_const and !src_type_info.Pointer.is_const) {
                        break :blk;
                    }
                } else {
                    if (comptime dst_type_info.Pointer.is_const and !src_type_info.Pointer.is_const or
                        src_type_info.Pointer.is_const and !dst_type_info.Pointer.is_const)
                    {
                        break :blk;
                    }
                }
                if (comptime dst_type_info.Pointer.is_volatile and !src_type_info.Pointer.is_volatile or
                    src_type_info.Pointer.is_volatile and !dst_type_info.Pointer.is_volatile)
                {
                    break :blk;
                }
                if (comptime write_spec.reference.coerce.alignment) {
                    if (comptime dst_type_info.Pointer.alignment > src_type_info.Pointer.alignment) {
                        break :blk;
                    }
                } else {
                    if (comptime dst_type_info.Pointer.alignment != src_type_info.Pointer.alignment) {
                        break :blk;
                    }
                }
                if (comptime dst_type_info.Pointer.sentinel != null) {
                    if (comptime dst_type_info.Pointer.sentinel != src_type_info.Pointer.sentinel) {
                        break :blk;
                    }
                } else if (comptime src_type_info.Pointer.sentinel != null) {
                    if (comptime !write_spec.reference.coerce.sentinel) {
                        break :blk;
                    }
                }
                return isEquivalent(child, write_spec, dst_type_info.Pointer.child, src_type_info.Pointer.child);
            }
            if (comptime dst_type_info.Pointer.size == .Slice and
                src_type_info.Pointer.size == .One)
            blk: {
                if (comptime dst_type == child and write_spec.reference.coerce.array) {
                    if (comptime src_child_type_id != .Array) {
                        break :blk;
                    }
                    return isEquivalent(child, write_spec, dst_type, meta.ArrayPointerToSlice(src_type));
                }
            }
        }
        return dst_type == src_type;
    }
    pub fn writeAnyStructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, any: anytype) void {
        const dst_type: type = child;
        const src_type: type = @TypeOf(any);
        const dst_type_info: meta.Type = @typeInfo(dst_type);
        const src_type_info: meta.Type = @typeInfo(src_type);
        if (comptime write_spec.integral.over_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(@intCast(dst_type, any));
            }
            if (dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(@floatCast(dst_type, any));
            }
        }
        if (comptime write_spec.integral.under_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits < dst_type_info.Int.bits or
                dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Float.bits < dst_type_info.Float.bits)
            {
                return memory.writeOne(any);
            }
        }
        if (comptime write_spec.integral.comptime_int) {
            if (dst_type_info == .Int and
                src_type_info == .ComptimeInt)
            {
                return memory.writeOne(any);
            }
        }
        if (comptime write_spec.integral.comptime_float) {
            if (dst_type_info == .Float and
                src_type_info == .ComptimeFloat)
            {
                return memory.writeOne(any);
            }
        }
        if (comptime write_spec.integral.float) {
            if (dst_type_info == .Int and
                src_type_info == .Float)
            {
                return memory.writeOne(@floatToInt(dst_type, any));
            }
        }
        if (comptime write_spec.integral.int) {
            if (dst_type_info == .Float and
                src_type_info == .Int)
            {
                return memory.writeOne(@intToFloat(dst_type, any));
            }
        }
        if (comptime dst_type == src_type or
            isEquivalent(child, write_spec, dst_type, src_type))
        {
            return memory.writeOne(any);
        }
        if (comptime write_spec.reference.coerce.many) {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Many)
            {
                return memory.writeAny(write_spec, meta.manyToSlice(any));
            }
        }
        if (comptime write_spec.reference.dereference) |write_spec_ptr| {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Slice)
            {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Pointer.child)) {
                    return memory.writeMany(any);
                }
                for (any) |value| {
                    memory.writeAny(write_spec_ptr.*, value);
                }
                return;
            }
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .One)
            {
                return memory.writeAny(write_spec_ptr.*, any.*);
            }
        }
        if (comptime write_spec.aggregate.copy) {
            if (src_type_info == .Array) {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Array.child)) {
                    return memory.writeCount(src_type_info.Array.len, any);
                }
                for (any) |value| {
                    memory.writeAny(write_spec, value);
                }
                return;
            }
        }
        if (comptime write_spec.composite.iterate) {
            if (src_type_info == .Struct and src_type_info.Struct.is_tuple) {
                return memory.writeArgs(write_spec, any);
            }
            if (src_type_info == .Struct and src_type_info.Struct.decls.len == 0) {
                return memory.writeFields(write_spec, any);
            }
        }
        if (comptime write_spec.composite.format) {
            if (src_type_info == .Struct and !src_type_info.Struct.is_tuple) {
                return Reinterpret.writeFormat(u8, memory, any);
            }
        }
        if (comptime write_spec.symbol.type_name) {
            if (src_type_info == .Type and dst_type == u8) {
                return memory.writeMany(@typeName(any));
            }
        }
        if (comptime write_spec.symbol.tag_name) {
            if (src_type_info == .EnumLiteral and dst_type == u8) {
                return memory.writeMany(@tagName(any));
            }
            if (src_type_info == .Enum and dst_type == u8) {
                return memory.writeMany(@tagName(any));
            }
        }
        if (comptime write_spec.symbol.error_name) {
            if (src_type_info == .ErrorSet and dst_type == u8) {
                return memory.writeMany(@errorName(any));
            }
        }
        return memory.writeAny(write_spec, @as(dst_type, any));
    }
    pub fn writeAnyUnstructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, any: anytype) void {
        const dst_type: type = child;
        const src_type: type = @TypeOf(any);
        const dst_type_info: meta.Type = @typeInfo(dst_type);
        const src_type_info: meta.Type = @typeInfo(src_type);
        if (comptime write_spec.integral.over_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(child, @intCast(dst_type, any));
            }
            if (dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(child, @floatCast(dst_type, any));
            }
        }
        if (comptime write_spec.integral.under_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits < dst_type_info.Int.bits or
                dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Float.bits < dst_type_info.Float.bits)
            {
                return memory.writeOne(child, any);
            }
        }
        if (comptime write_spec.integral.comptime_int) {
            if (dst_type_info == .Int and
                src_type_info == .ComptimeInt)
            {
                return memory.writeOne(child, any);
            }
        }
        if (comptime write_spec.integral.comptime_float) {
            if (dst_type_info == .Float and
                src_type_info == .ComptimeFloat)
            {
                return memory.writeOne(child, any);
            }
        }
        if (comptime write_spec.integral.float) {
            if (dst_type_info == .Int and
                src_type_info == .Float)
            {
                return memory.writeOne(child, @floatToInt(dst_type, any));
            }
        }
        if (comptime write_spec.integral.int) {
            if (dst_type_info == .Float and
                src_type_info == .Int)
            {
                return memory.writeOne(child, @intToFloat(dst_type, any));
            }
        }
        if (comptime dst_type == src_type or
            isEquivalent(child, write_spec, dst_type, src_type))
        {
            return memory.writeOne(child, any);
        }
        if (comptime write_spec.reference.coerce.many) {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Many)
            {
                return memory.writeAny(child, write_spec, meta.manyToSlice(any));
            }
        }
        if (comptime write_spec.reference.dereference) |write_spec_ptr| {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Slice)
            {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Pointer.child)) {
                    return memory.writeMany(child, any);
                }
                for (any) |value| {
                    memory.writeAny(child, write_spec_ptr.*, value);
                }
                return;
            }
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .One)
            {
                return memory.writeAny(child, write_spec_ptr.*, any.*);
            }
        }
        if (comptime write_spec.aggregate.copy) {
            if (src_type_info == .Array) {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Array.child)) {
                    return memory.writeCount(child, src_type_info.Array.len, any);
                }
                for (any) |value| {
                    memory.writeAny(child, write_spec, value);
                }
                return;
            }
        }
        if (comptime write_spec.composite.iterate) {
            if (src_type_info == .Struct and src_type_info.Struct.is_tuple) {
                return memory.writeArgs(child, write_spec, any);
            }
            if (src_type_info == .Struct and src_type_info.Struct.decls.len == 0) {
                return memory.writeFields(child, write_spec, any);
            }
        }
        if (comptime write_spec.composite.format) {
            if (src_type_info == .Struct and !src_type_info.Struct.is_tuple) {
                return Reinterpret.writeFormat(child, memory, any);
            }
        }
        if (comptime write_spec.symbol.type_name) {
            if (src_type_info == .Type and dst_type == u8) {
                return memory.writeMany(child, @typeName(any));
            }
        }
        if (comptime write_spec.symbol.tag_name) {
            if (src_type_info == .EnumLiteral and dst_type == u8) {
                return memory.writeMany(child, @tagName(any));
            }
            if (src_type_info == .Enum and dst_type == u8) {
                return memory.writeMany(child, @tagName(any));
            }
        }
        if (comptime write_spec.symbol.error_name) {
            if (src_type_info == .ErrorSet and dst_type == u8) {
                return memory.writeMany(child, @errorName(any));
            }
        }
        return memory.writeAny(child, write_spec, @as(dst_type, any));
    }
    pub fn writeFormat(comptime child: type, memory: anytype, format: anytype) void {
        const Format: type = @TypeOf(format);
        if (child != u8) {
            @compileError("invalid destination type for format write: " ++ @typeName(child));
        }
        if (!@hasDecl(Format, "formatWrite")) {
            @compileError("invalid interface for formatter type: " ++ @typeName(Format));
        }
        if (builtin.is_correct) {
            const s_len: u64 = format.formatLength();
            const len_0: u64 = memory.impl.next();
            format.formatWrite(memory);
            const len_1: u64 = memory.impl.next();
            const t_len: u64 = builtin.sub(u64, len_1, len_0);
            builtin.assertBelowOrEqual(u64, t_len, s_len);
        } else if (builtin.is_correct) {
            const s_len: u64 = format.formatLength();
            const len_0: u64 = memory.impl.next();
            format.formatWrite(memory);
            const len_1: u64 = memory.impl.next();
            const t_len: u64 = builtin.sub(u64, len_1, len_0);
            builtin.assertEqual(u64, s_len, t_len);
        } else {
            format.formatWrite(memory);
        }
    }
    pub fn lengthAny(comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) u64 {
        const dst_type: type = child;
        const src_type: type = @TypeOf(any);
        const dst_type_info: meta.Type = @typeInfo(dst_type);
        const src_type_info: meta.Type = @typeInfo(src_type);
        if (comptime write_spec.integral.over_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return 1;
            }
            if (dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return 1;
            }
        }
        if (comptime write_spec.integral.under_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits < dst_type_info.Int.bits or
                dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Float.bits < dst_type_info.Float.bits)
            {
                return 1;
            }
        }
        if (comptime write_spec.integral.comptime_int) {
            if (dst_type_info == .Int and
                src_type_info == .ComptimeInt)
            {
                return 1;
            }
        }
        if (comptime write_spec.integral.comptime_float) {
            if (dst_type_info == .Float and
                src_type_info == .ComptimeFloat)
            {
                return 1;
            }
        }
        if (comptime write_spec.integral.float) {
            if (dst_type_info == .Int and
                src_type_info == .Float)
            {
                return 1;
            }
        }
        if (comptime write_spec.integral.int) {
            if (dst_type_info == .Float and
                src_type_info == .Int)
            {
                return 1;
            }
        }
        if (comptime dst_type == src_type or
            isEquivalent(child, write_spec, dst_type, src_type))
        {
            return 1;
        }
        if (comptime write_spec.reference.coerce.many) {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Many)
            {
                return lengthAny(child, write_spec, meta.manyToSlice(any));
            }
        }
        if (comptime write_spec.reference.dereference) |write_spec_ptr| {
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .Slice)
            {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Pointer.child)) {
                    return any.len;
                }
                var len: u64 = 0;
                for (any) |value| {
                    len += lengthAny(child, write_spec_ptr.*, value);
                }
                return len;
            }
            if (src_type_info == .Pointer and
                src_type_info.Pointer.size == .One)
            {
                return lengthAny(child, write_spec_ptr.*, any.*);
            }
        }
        if (comptime write_spec.aggregate.copy) {
            if (src_type_info == .Array) {
                if (comptime isEquivalent(child, write_spec, dst_type, src_type_info.Array.child)) {
                    return any.len;
                }
                var len: u64 = 0;
                for (any) |value| {
                    len += lengthAny(child, write_spec, value);
                }
                return len;
            }
        }
        if (comptime write_spec.composite.iterate) {
            if (src_type_info == .Struct and src_type_info.Struct.is_tuple) {
                return lengthArgs(child, write_spec, any);
            }
            if (src_type_info == .Struct and src_type_info.Struct.decls.len == 0) {
                return lengthFields(child, write_spec, src_type_info.Struct, any, 0);
            }
        }
        if (comptime write_spec.composite.format) {
            if (src_type_info == .Struct and !src_type_info.Struct.is_tuple) {
                return lengthFormat(child, any);
            }
        }
        if (comptime write_spec.symbol.type_name) {
            if (src_type_info == .Type and dst_type == u8) {
                return @typeName(any).len;
            }
        }
        if (comptime write_spec.symbol.tag_name) {
            if (src_type_info == .EnumLiteral and dst_type == u8) {
                return @tagName(any).len;
            }
            if (src_type_info == .Enum and dst_type == u8) {
                var len: u64 = 0;
                inline for (src_type_info.Enum.fields) |field| {
                    len = @max(len, field.name.len);
                }
                return len;
            }
        }
        if (comptime write_spec.symbol.error_name) {
            if (src_type_info == .ErrorSet and dst_type == u8) {
                var len: u64 = 0;
                inline for (src_type_info.ErrorSet.?) |e| {
                    len = @max(len, e.name.len);
                }
                return len;
            }
        }
        return lengthAny(child, write_spec, @as(dst_type, any));
    }
    pub fn lengthFormat(comptime child: type, format: anytype) u64 {
        const Format: type = @TypeOf(format);
        if (child != u8) {
            @compileError("invalid destination type for format write: " ++ @typeName(child));
        }
        if (@hasDecl(Format, "max_len")) {
            if (builtin.is_perf) return Format.max_len;
        }
        return format.formatLength();
    }
    pub fn lengthFields(comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) u64 {
        var len: u64 = 0;
        inline for (@typeInfo(@TypeOf(args)).Struct.fields) |field| {
            len += lengthAny(child, write_spec, @field(args, field.name));
        }
        return len;
    }
    pub fn lengthArgs(comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) u64 {
        var len: u64 = 0;
        comptime var index: u64 = 0;
        inline while (index != args.len) : (index += 1) {
            len += lengthAny(child, write_spec, args[index]);
        }
        return len;
    }
};
