const fmt = @import("fmt.zig");
const mem = @import("mem.zig");
const meta = @import("meta.zig");
const bits = @import("bits.zig");
const math = @import("math.zig");
const proc = @import("proc.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
const pointer = @import("pointer.zig");

pub fn StaticStream(comptime child: type, comptime count: u64) type {
    return StructuredAutomaticStreamVector(child, null, count, @alignOf(child), .{});
}
pub fn StaticArray(comptime child: type, comptime count: u64) type {
    return StructuredAutomaticVector(child, null, count, @alignOf(child), .{});
}
pub fn StaticView(comptime child: type, comptime count: u64) type {
    return StructuredAutomaticView(child, null, count, @alignOf(child), .{});
}
pub fn StaticString(comptime count: u64) type {
    return StaticArray(u8, count);
}
pub fn literalView(comptime s: [:0]const u8) StructuredAutomaticView(u8, &@as(u8, 0), s.len, null, .{}) {
    return .{ .impl = .{ .auto = @as(*const [s.len:0]u8, @ptrCast(s.ptr)).* } };
}
pub fn view(s: []const u8) StructuredStreamView(u8, null, 1, struct {}, .{}) {
    return .{ .impl = .{
        .lb_word = @intFromPtr(s.ptr),
        .up_word = @intFromPtr(s.ptr + s.len),
        .ss_word = @intFromPtr(s.ptr),
    } };
}
pub fn GenericSimpleArray(comptime T: type) type {
    return struct {
        values: []T,
        values_len: usize,
        const Array = @This();
        const Allocator = builtin.define("Allocator", type, mem.SimpleAllocator);
        pub fn appendOne(array: *Array, allocator: *Allocator, value: T) void {
            if (array.values_len == array.values.len) {
                array.values = allocator.reallocate(T, array.values, array.values_len *% 2);
            }
            array.values[array.values_len] = value;
            array.values_len +%= 1;
        }
        pub fn appendSlice(array: *Array, allocator: *Allocator, values: []const T) void {
            if (array.values_len +% values.len > array.values.len) {
                array.values = allocator.reallocate(T, array.values, (array.values_len +% values.len) *% 2);
            }
            for (values) |value| {
                array.values[array.values_len] = value;
                array.values_len +%= 1;
            }
        }
        pub fn readAll(array: *const Array) []const T {
            return array.values[0..array.values_len];
        }
        pub fn referAll(array: *Array) []T {
            return array.values[0..array.values_len];
        }
        pub fn popOne(array: *Array) T {
            array.values_len -%= 1;
            return array.values[array.values_len];
        }
        pub fn init(allocator: *Allocator, count: u64) Array {
            return .{
                .values = allocator.allocate(T, count),
                .values_len = 0,
            };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            allocator.deallocate(T, array.values);
        }
    };
}
pub fn GenericSimpleMap(comptime Key: type, comptime Value: type) type {
    return struct {
        pairs: []*Pair,
        pairs_len: usize,
        const Array = @This();
        const Allocator = builtin.define("Allocator", type, mem.SimpleAllocator);
        const Pair = struct {
            key: Key,
            val: Value,
        };
        pub fn put(array: *Array, allocator: *Allocator, key: Key, val: Value) void {
            array.appendOne(allocator, .{ .key = key, .val = val });
        }
        pub fn get(array: *const Array, key: Key) ?Value {
            for (array.pairs[0..array.pairs_len]) |pair| {
                if (mem.testEqualMemory(Key, pair.key, key)) {
                    return pair.val;
                }
            }
            return null;
        }
        pub fn refer(array: *const Array, key: Key) ?*Value {
            for (array.pairs[0..array.pairs_len]) |pair| {
                if (mem.testEqualMemory(Key, pair.key, key)) {
                    return &pair.val;
                }
            }
            return null;
        }
        pub fn remove(array: *Array, key: Key) void {
            const end: *Pair = array.pairs[array.pairs_len -% 1];
            for (array.pairs[0..array.pairs_len]) |*pair| {
                if (mem.testEqualMemory(Key, pair.*.key, key)) {
                    pair.* = end;
                    array.pairs_len -%= 1;
                }
            }
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, pair: Pair) void {
            if (array.pairs_len == array.pairs.len) {
                array.pairs = allocator.reallocate(*Pair, array.pairs, array.pairs_len *% 2);
            }
            array.pairs[array.pairs_len] = allocator.create(Pair);
            array.pairs[array.pairs_len].* = pair;
            array.pairs_len +%= 1;
        }
        pub fn readAll(array: *const Array) []const *Pair {
            return array.pairs[0..array.pairs_len];
        }
        pub fn init(allocator: *Allocator, count: u64) Array {
            return .{
                .pairs = allocator.allocate(*Pair, count),
                .pairs_len = 0,
            };
        }
    };
}

pub const Amount = union(enum) { // bytes: u64, count: u64 };
    bytes: u64,
    count: u64,
    const zero: Amount = .{ .bytes = 0 };
    const one: Amount = .{ .bytes = 1 };
    const none: Amount = .{ .count = 0 };
    const unit: Amount = .{ .count = 1 };
};
pub inline fn amountToCountOfType(amt: Amount, comptime child: type) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes / @sizeOf(child),
        .count => |count| count,
    };
}
pub inline fn amountOfTypeToBytes(amt: Amount, comptime child: type) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes,
        .count => |count| count * @sizeOf(child),
    };
}
pub inline fn amountToCountOfLength(amt: Amount, length: u64) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes / length,
        .count => |count| count,
    };
}
pub inline fn amountOfLengthToBytes(amt: Amount, length: u64) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes,
        .count => |count| count * length,
    };
}
inline fn hasSentinel(comptime impl_type: type) bool {
    return @hasDecl(impl_type, "sentinel") or
        @hasDecl(impl_type, "Specification") and
        @hasField(impl_type.Specification, "sentinel");
}
pub inline fn amountReservedToCount(amt: Amount, comptime impl_type: type) u64 {
    return amountToCountOfLength(amt, impl_type.high_alignment) +
        builtin.int(hasSentinel(impl_type));
}
pub inline fn amountReservedToBytes(amt: Amount, comptime impl_type: type) u64 {
    return amountOfLengthToBytes(amt, impl_type.high_alignment) +
        bits.cmov64z(hasSentinel(impl_type), impl_type.high_alignment);
}
fn writeOneInternal(comptime child: type, next: u64, value: child) void {
    pointer.pointerOne(child, next).* = value;
}
fn writeCountInternal(comptime child: type, next: u64, comptime write_count: u64, values: [write_count]child) void {
    for (values, 0..) |value, i| pointer.pointerOne(child, next + i).* = value;
}
fn writeManyInternal(comptime child: type, next: u64, values: []const child) void {
    for (values, 0..) |value, i| pointer.pointerOne(child, next + i).* = value;
}
pub const ReinterpretSpec = struct {
    integral: Integral = .{},
    aggregate: Aggregate = .{},
    composite: Composite = .{},
    reference: Reference = .{},
    symbol: Symbol = .{},
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
        /// Map input types to formatter types
        map: ?[]const struct { in: type, out: type } = null,
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
};
pub const reinterpret = opaque {
    fn isEquivalent(comptime child: type, comptime write_spec: ReinterpretSpec, comptime dst_type: type, comptime src_type: type) bool {
        const dst_type_info: builtin.Type = @typeInfo(dst_type);
        const src_type_info: builtin.Type = @typeInfo(src_type);
        if (comptime dst_type_info == .Optional and
            src_type_info == .Optional)
        blk: {
            const dst_child_type_id: builtin.TypeId = @typeInfo(dst_type_info.Optional.child);
            const src_child_type_id: builtin.TypeId = @typeInfo(src_type_info.Optional.child);
            if (comptime dst_child_type_id != src_child_type_id) {
                break :blk;
            }
            return isEquivalent(child, write_spec, dst_type_info.Optional.child, src_type_info.Optional.child);
        }
        if (comptime dst_type_info == .Array and
            src_type_info == .Array)
        blk: {
            const dst_child_type_id: builtin.TypeId = @typeInfo(dst_type_info.Array.child);
            const src_child_type_id: builtin.TypeId = @typeInfo(src_type_info.Array.child);
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
            const dst_child_type_id: builtin.TypeId = @typeInfo(dst_type_info.Pointer.child);
            const src_child_type_id: builtin.TypeId = @typeInfo(src_type_info.Pointer.child);
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
        const dst_type_info: builtin.Type = @typeInfo(dst_type);
        const src_type_info: builtin.Type = @typeInfo(src_type);
        if (comptime write_spec.integral.over_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(@as(dst_type, @intCast(any)));
            }
            if (dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(@as(dst_type, @floatCast(any)));
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
                return memory.writeOne(@as(dst_type, @intFromFloat(any)));
            }
        }
        if (comptime write_spec.integral.int) {
            if (dst_type_info == .Float and
                src_type_info == .Int)
            {
                return memory.writeOne(@as(dst_type, @floatFromInt(any)));
            }
        }
        if (comptime dst_type == src_type or
            isEquivalent(child, write_spec, dst_type, src_type))
        {
            return memory.writeOne(any);
        }
        if (comptime write_spec.composite.map) |map| {
            inline for (map) |kv| {
                if (comptime src_type == kv.in) {
                    return memory.writeAny(write_spec, kv.out{ .value = any });
                }
            }
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
                return reinterpret.writeFormat(u8, memory, any);
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
        return any.formatWrite(memory);
    }
    pub fn writeAnyUnstructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, any: anytype) void {
        const dst_type: type = child;
        const src_type: type = @TypeOf(any);
        const dst_type_info: builtin.Type = @typeInfo(dst_type);
        const src_type_info: builtin.Type = @typeInfo(src_type);
        if (comptime write_spec.integral.over_size) {
            if (dst_type_info == .Int and
                src_type_info == .Int and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(child, @as(dst_type, @intCast(any)));
            }
            if (dst_type_info == .Float and
                src_type_info == .Float and src_type_info.Int.bits > dst_type_info.Int.bits)
            {
                return memory.writeOne(child, @as(dst_type, @floatCast(any)));
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
                return memory.writeOne(child, @as(dst_type, @intFromFloat(any)));
            }
        }
        if (comptime write_spec.integral.int) {
            if (dst_type_info == .Float and
                src_type_info == .Int)
            {
                return memory.writeOne(child, @as(dst_type, @floatFromInt(any)));
            }
        }
        if (comptime dst_type == src_type or
            isEquivalent(child, write_spec, dst_type, src_type))
        {
            return memory.writeOne(child, any);
        }
        if (comptime write_spec.composite.map) |map| {
            inline for (map) |kv| {
                if (comptime src_type == kv.in) {
                    return memory.writeAny(write_spec, kv.out{ .value = any });
                }
            }
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
                return reinterpret.writeFormat(child, memory, any);
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
        return any.formatWrite(memory);
    }
    pub inline fn writeArgsStructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, args: anytype) void {
        inline for (args) |arg| {
            reinterpret.writeAnyStructured(child, write_spec, memory, arg);
        }
    }
    pub inline fn writeFieldsStructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, fields: anytype) void {
        inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field| {
            reinterpret.writeAnyStructured(child, write_spec, memory, @field(fields, field.name));
        }
    }
    pub inline fn writeArgsUnstructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, args: anytype) void {
        inline for (args) |arg| {
            reinterpret.writeAnyUnstructured(child, write_spec, memory, arg);
        }
    }
    pub inline fn writeFieldsUnstructured(comptime child: type, comptime write_spec: ReinterpretSpec, memory: anytype, fields: anytype) void {
        inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field| {
            reinterpret.writeAnyUnstructured(child, write_spec, memory, @field(fields, field.name));
        }
    }
    pub fn writeFormat(comptime child: type, memory: anytype, format: anytype) void {
        const Format: type = @TypeOf(format);
        if (child != u8) {
            @compileError("invalid destination type for format write: " ++ @typeName(child));
        }
        if (@hasDecl(Format, "readAll") and
            @hasDecl(Format, "len"))
        {
            return memory.writeMany(format.readAll());
        }
        if (!@hasDecl(Format, "formatWrite")) {
            @compileError("formatter type '" ++ @typeName(Format) ++ "' requires declaration 'formatWrite'");
        }
        if (builtin.runtime_assertions) {
            const what: []const u8 = @typeName(Format) ++ ".length(), ";
            if (builtin.is_fast or builtin.is_small) {
                const s_len: usize = format.formatLength();
                const addr_0: usize = memory.impl.undefined_byte_address();
                format.formatWrite(memory);
                const addr_1: usize = memory.impl.undefined_byte_address();
                const t_len: usize = addr_1 -% addr_0;
                if (s_len < t_len) {
                    formatLengthFault(what, " > ", s_len, t_len);
                }
            } else {
                const s_len: usize = format.formatLength();
                const addr_0: usize = memory.impl.undefined_byte_address();
                format.formatWrite(memory);
                const addr_1: usize = memory.impl.undefined_byte_address();
                const t_len: usize = addr_1 -% addr_0;
                if (s_len != t_len) {
                    formatLengthFault(what, " == ", s_len, t_len);
                }
            }
        } else {
            format.formatWrite(memory);
        }
    }
    fn formatLengthFault(format_type_name: []const u8, operator_symbol: anytype, s_len: u64, t_len: u64) noreturn {
        var buf: [32768]u8 = undefined;
        var ptr: [*]u8 = &buf;
        var ud64: fmt.Ud64 = .{ .value = t_len };
        ptr = fmt.strcpyEqu(ptr, format_type_name);
        ptr += ud64.formatWriteBuf(ptr);
        ptr[0..operator_symbol.len].* = operator_symbol.*;
        ptr += operator_symbol.len;
        ud64.value = s_len;
        ptr += ud64.formatWriteBuf(ptr);
        if (t_len > 99_999) {
            ptr[0..7].* = ", i.e. ".*;
            ptr += 7;
            ptr[0] = '0';
            ptr += 1;
            ptr[0..operator_symbol.len].* = operator_symbol.*;
            ptr += operator_symbol.len;
            ud64.value = t_len -% s_len;
            ptr += ud64.formatWriteBuf(ptr);
        }
        @panic(buf[0 .. @intFromPtr(ptr) - @intFromPtr(&buf)]);
    }
    pub fn lengthAny(comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) u64 {
        const dst_type: type = child;
        const src_type: type = @TypeOf(any);
        const dst_type_info: builtin.Type = @typeInfo(dst_type);
        const src_type_info: builtin.Type = @typeInfo(src_type);
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
        if (comptime write_spec.composite.map) |map| {
            inline for (map) |kv| {
                if (comptime src_type == kv.in) {
                    return lengthAny(child, write_spec, kv.out{ .value = any });
                }
            }
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
                return lengthFields(child, write_spec, any);
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
        return any.formatLength();
    }
    pub fn lengthFormat(comptime child: type, format: anytype) usize {
        const Format: type = @TypeOf(format);
        if (child != u8) {
            @compileError("invalid destination type for format write: " ++ @typeName(child));
        }
        if (@hasDecl(Format, "max_len") and (builtin.is_fast or builtin.is_small)) {
            if (Format.max_len) |max_len| {
                return max_len;
            }
        }
        if (@hasDecl(Format, "readAll") and
            @hasDecl(Format, "len"))
        {
            return format.len();
        }
        if (!@hasDecl(Format, "formatLength")) {
            @compileError("formatter type '" ++ @typeName(Format) ++ "' requires declaration 'formatLength'");
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
        inline for (args) |arg| {
            len += lengthAny(child, write_spec, arg);
        }
        return len;
    }
};
fn highAlignment(comptime Specification: type, comptime specification: Specification) u64 {
    _ = specification;
    if (@hasField(Specification, "high_alignment")) {
        return spec.high_alignment;
    }
    if (@hasField(Specification, "child")) {
        return @sizeOf(spec.child);
    }
    if (spec.low_alignment) |low_alignment| {
        return low_alignment;
    }
    @compileError(@typeName(Specification) ++
        ": no high address alignment, child size, or low " ++
        "addess alignment defined in container parameters");
}
fn lowAlignment(comptime Specification: type, comptime specification: Specification) u64 {
    _ = specification;
    if (spec.low_alignment) |low_alignment| {
        return low_alignment;
    }
    if (@hasField(Specification, "child")) {
        return @alignOf(spec.child);
    }
    if (@hasField(Specification, "high_alignment")) {
        return spec.high_alignment;
    }
    @compileError(@typeName(Specification) ++
        ": no low address alignment, child size, or high " ++
        "addess alignment defined in container parameters");
}
fn unitAlignment(comptime Specification: type, comptime specification: Specification) u64 {
    _ = specification;
    if (@hasDecl(spec.Allocator, "allocator_spec")) {
        const AllocatorSpec: type = @TypeOf(spec.Allocator.specification);
        if (@hasField(AllocatorSpec, "unit_alignment")) {
            return spec.Allocator.specification.unit_alignment;
        }
        const AllocatorSpecOptions: type = @TypeOf(spec.Allocator.specification.options);
        if (@hasField(AllocatorSpecOptions, "unit_alignment")) {
            return spec.Allocator.specification.options.unit_alignment;
        }
    }
    if (@hasDecl(spec.Allocator, "unit_alignment")) {
        return spec.Allocator.unit_alignment;
    }
    @compileError(@typeName(Specification) ++
        ": no unit aligment defined in Allocator declarations, " ++
        "specification, or specification options");
}
fn arenaIndex(comptime Specification: type, comptime specification: Specification) ?u64 {
    _ = specification;
    const Parameters = @TypeOf(spec);
    if (@hasField(Parameters, "Allocator")) {
        if (@hasDecl(spec.Allocator, "arena_index")) {
            return spec.Allocator.arena_index;
        }
        if (@hasDecl(spec.Allocator, "allocator_spec")) {
            const AllocatorOptions: type = @TypeOf(spec.Allocator.specification.options);
            if (@hasField(AllocatorOptions, "arena_index")) {
                return spec.Allocator.specification.options.arena_index;
            }
        }
    } else {
        @compileError(@typeName(Specification) ++
            ": no Allocator field in specification");
    }
    return null;
}
fn GenericParameters(comptime Parameters: type) type {
    return struct {
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
                const AllocatorSpec: type = @TypeOf(params.Allocator.specification);
                if (@hasField(AllocatorSpec, "unit_alignment")) {
                    return params.Allocator.specification.unit_alignment;
                }
                const AllocatorSpecOptions: type = @TypeOf(params.Allocator.specification.options);
                if (@hasField(AllocatorSpecOptions, "unit_alignment")) {
                    return params.Allocator.specification.options.unit_alignment;
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
            if (params.Allocator == void) {
                return null;
            }
            if (@hasDecl(params.Allocator, "arena_index")) {
                return params.Allocator.arena_index;
            }
            if (@hasDecl(params.Allocator, "allocator_spec")) {
                const AllocatorOptions: type = @TypeOf(params.Allocator.specification.options);
                if (@hasField(AllocatorOptions, "arena_index")) {
                    return params.Allocator.specification.options.arena_index;
                }
            }
            return null;
        }
    };
}
pub const Parameters0 = struct {
    child: type,
    sentinel: ?*const anyopaque = null,
    count: u64,
    low_alignment: ?u64 = null,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.sentinel != null) {
            return pointer.Specification1;
        } else {
            return pointer.Specification0;
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
pub fn StructuredAutomaticView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return (struct {
        impl: Implementation = .{},
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_auto, params.options);
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn len(array: *const Array) u64 {
            return array.impl.writable_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
    });
}
pub fn StructuredAutomaticStreamView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return (struct {
        impl: Implementation = .{ .ss_word = 0 },
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_auto, params.options);
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array) u64 {
            return array.impl.streamed_byte_count() / child_size;
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.writable_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
    });
}
pub fn StructuredAutomaticStreamVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return (struct {
        impl: Implementation = .{ .ub_word = 0, .ss_word = 0 },
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize_auto, params.options);
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array) u64 {
            return array.impl.streamed_byte_count() / child_size;
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
    });
}
pub fn StructuredAutomaticVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return (struct {
        impl: Implementation = .{ .ub_word = 0 },
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize_auto, params.options);
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
    });
}
pub const Parameters1 = struct {
    child: type,
    sentinel: ?*const anyopaque = null,
    count: u64,
    low_alignment: ?u64 = null,
    Allocator: type,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.sentinel != null) {
            return pointer.Specification3;
        } else {
            return pointer.Specification2;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.sentinel) |sentinel| {
            if (params.arenaIndex()) |arena_index| {
                return .{
                    .child = params.child,
                    .sentinel = sentinel,
                    .count = params.count,
                    .low_alignment = params.lowAlignment(),
                    .arena_index = arena_index,
                };
            }
        } else {
            if (params.arenaIndex()) |arena_index| {
                return .{
                    .child = params.child,
                    .count = params.count,
                    .low_alignment = params.lowAlignment(),
                    .arena_index = arena_index,
                };
            }
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn StructuredStaticView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) type {
    const params: Parameters1 = params1(child, sentinel, count, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write, params.options);
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn len(array: *const Array) u64 {
            return array.impl.writable_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub fn StructuredStaticStreamVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) type {
    const params: Parameters1 = params1(child, sentinel, count, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array) u64 {
            return array.impl.streamed_byte_count() / child_size;
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub fn StructuredStaticVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) type {
    const params: Parameters1 = params1(child, sentinel, count, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub const Parameters2 = struct {
    bytes: u64,
    low_alignment: ?u64 = null,
    Allocator: type,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.arenaIndex() != null) {
            return pointer.Specification5;
        } else {
            return pointer.Specification4;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.arenaIndex()) |arena_index| {
            return .{
                .bytes = params.bytes,
                .low_alignment = params.lowAlignment(),
                .arena_index = arena_index,
            };
        } else {
            return .{
                .bytes = params.bytes,
                .low_alignment = params.lowAlignment(),
            };
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn UnstructuredStaticView(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) type {
    const params: Parameters2 = params2(bytes, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write, params.options);
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.writable_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub fn UnstructuredStaticStreamVector(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) type {
    const params: Parameters2 = params2(bytes, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.streamed_byte_count() / @sizeOf(child);
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.defined_byte_count() / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.undefined_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountOfTypeToBytes(unstream_amount, child));
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __behind(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountOfTypeToBytes(stream_amount, child));
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub fn UnstructuredStaticVector(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) type {
    const params: Parameters2 = params2(bytes, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.defined_byte_count() / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.undefined_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertStaticMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
    });
}
pub const Parameters3 = struct {
    child: type,
    sentinel: ?*const anyopaque = null,
    low_alignment: ?u64 = null,
    Allocator: type,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.sentinel != null) {
            if (params.arenaIndex() != null) {
                return pointer.Specification9;
            } else {
                return pointer.Specification7;
            }
        }
        if (params.arenaIndex() != null) {
            return pointer.Specification8;
        } else {
            return pointer.Specification6;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.sentinel) |sentinel| {
            if (params.arenaIndex()) |arena_index| {
                return .{
                    .child = params.child,
                    .sentinel = sentinel,
                    .low_alignment = params.lowAlignment(),
                    .arena_index = arena_index,
                };
            } else {
                return .{
                    .child = params.child,
                    .sentinel = sentinel,
                    .low_alignment = params.lowAlignment(),
                };
            }
        } else {
            if (params.arenaIndex()) |arena_index| {
                return .{
                    .child = params.child,
                    .low_alignment = params.lowAlignment(),
                    .arena_index = arena_index,
                };
            } else {
                return .{
                    .child = params.child,
                    .low_alignment = params.lowAlignment(),
                };
            }
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn StructuredStreamVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array) u64 {
            return array.impl.streamed_byte_count() / child_size;
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, 1));
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, write_count));
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, values.len));
            array.writeMany(values);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFields(child, write_spec, fields)));
            array.writeFields(write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthArgs(child, write_spec, args)));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFormat(child, format)));
            array.writeFormat(format);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthAny(child, write_spec, any)));
            array.writeAny(write_spec, any);
        }
    });
}
pub fn StructuredStreamView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream, params.options);
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array) u64 {
            return array.impl.streamed_byte_count() / child_size;
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.writable_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
    });
}
pub fn StructuredVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return array.impl.defined_byte_count() / child_size;
        }
        pub fn avail(array: *const Array) u64 {
            return array.impl.undefined_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __rem(array: *const Array, offset: u64) u64 {
            return math.sub64(avail(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, 1));
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, write_count));
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, values.len));
            array.writeMany(values);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFields(child, write_spec, fields)));
            array.writeFields(write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthArgs(child, write_spec, args)));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFormat(child, format)));
            array.writeFormat(format);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthAny(child, write_spec, any)));
            array.writeAny(write_spec, any);
        }
    });
}
pub fn StructuredView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write, params.options);
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn len(array: *const Array) u64 {
            return array.impl.writable_byte_count() / child_size;
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        pub fn readAll(array: *const Array) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn referAllDefined(array: *const Array) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return pointer.pointerOne(child, __at(array, offset)).*;
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, offset));
        }
        pub fn overwriteOneAt(array: *Array, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn referManyAt(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, offset), __len(array, offset));
        }
        pub fn overwriteManyAt(array: *Array, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, offset), __len(array, offset), sentinel_value);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
    });
}
pub const Parameters4 = struct {
    high_alignment: u64,
    low_alignment: ?u64 = null,
    Allocator: type,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
        disjunct_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.arenaIndex() != null) {
            return pointer.Specification11;
        } else {
            return pointer.Specification10;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.arenaIndex()) |arena_index| {
            return .{
                .high_alignment = params.high_alignment,
                .low_alignment = params.lowAlignment(),
                .arena_index = arena_index,
            };
        } else {
            return .{
                .high_alignment = params.high_alignment,
                .low_alignment = params.lowAlignment(),
            };
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn UnstructuredStreamVector(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.streamed_byte_count() / @sizeOf(child);
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.defined_byte_count() / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.undefined_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountOfTypeToBytes(unstream_amount, child));
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __behind(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountOfTypeToBytes(stream_amount, child));
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, add_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(add_amount, child) }));
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(sub_amount, child) }));
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = 1 }));
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = write_count }));
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = values.len }));
            array.writeMany(child, values);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFields(child, write_spec, fields) }));
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthArgs(child, write_spec, args) }));
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFormat(child, format) }));
            array.writeFormat(child, format);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthAny(child, write_spec, any) }));
            array.writeAny(child, write_spec, any);
        }
    });
}
pub fn UnstructuredStreamView(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream, params.options);
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.streamed_byte_count() / @sizeOf(child);
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.writable_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountOfTypeToBytes(unstream_amount, child));
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __behind(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountOfTypeToBytes(stream_amount, child));
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
    });
}
pub fn UnstructuredVector(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.defined_byte_count() / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.undefined_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn grow(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, add_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(add_amount, child) }));
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(sub_amount, child) }));
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = 1 }));
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = write_count }));
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = values.len }));
            array.writeMany(child, values);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFields(child, write_spec, fields) }));
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthArgs(child, write_spec, args) }));
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFormat(child, format) }));
            array.writeFormat(child, format);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthAny(child, write_spec, any) }));
            array.writeAny(child, write_spec, any);
        }
    });
}
pub fn UnstructuredView(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write, params.options);
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.writable_byte_count() / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, offset), __len(array, child, offset), sentinel_value);
        }
        pub fn init(allocator: *Allocator, init_count: u64) Allocator.allocate_payload(Array) {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
    });
}
pub const Parameters5 = struct {
    Allocator: type,
    child: type,
    sentinel: ?*const anyopaque = null,
    low_alignment: ?u64 = null,
    options: Options = .{},
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
    };
    fn Specification(comptime params: Parameters) type {
        if (params.sentinel != null) {
            return pointer.Specification13;
        } else {
            return pointer.Specification12;
        }
    }
    fn specification(comptime params: Parameters) params.Specification() {
        if (params.sentinel) |sentinel| {
            return .{
                .Allocator = params.Allocator,
                .child = params.child,
                .sentinel = sentinel,
                .low_alignment = params.lowAlignment(),
            };
        } else {
            return .{
                .Allocator = params.Allocator,
                .child = params.child,
                .low_alignment = params.lowAlignment(),
            };
        }
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn StructuredStreamHolder(comptime Allocator: type, comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime options: Parameters5.Options) type {
    const params: Parameters5 = params5(Allocator, child, sentinel, low_alignment, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters5;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn streamAll(array: *Array, allocator: Allocator) void {
            array.impl.seek(array.impl.unstreamed_byte_count(allocator));
        }
        pub fn unstreamAll(array: *Array, allocator: Allocator) void {
            array.impl.tell(array.impl.streamed_byte_count(allocator));
        }
        pub fn index(array: *const Array, allocator: Allocator) u64 {
            return array.impl.streamed_byte_count(allocator) / child_size;
        }
        pub fn len(array: *const Array, allocator: Allocator) u64 {
            return array.impl.defined_byte_count(allocator) / child_size;
        }
        pub fn avail(array: *const Array, allocator: Allocator) u64 {
            return array.impl.undefined_byte_count(allocator) / child_size;
        }
        fn __at(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), offset);
        }
        fn __rem(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.sub64(avail(array, allocator), offset);
        }
        pub fn readAll(array: *const Array, allocator: Allocator) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn referAllDefined(array: *const Array, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        fn __behind(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), offset * child_size);
        }
        pub fn unstream(array: *Array, unstream_count: u64) void {
            array.impl.tell(child_size * unstream_count);
        }
        pub fn readOneBehind(array: *const Array) child {
            return pointer.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __behind(array, offset), offset);
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, offset), offset, sentinel_value);
        }
        pub fn readOneAt(array: *const Array, allocator: Allocator, offset: u64) child {
            return pointer.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn referOneAt(array: *const Array, allocator: Allocator, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn overwriteOneAt(array: *Array, allocator: Allocator, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, allocator, offset), value);
        }
        pub fn readCountAt(array: *const Array, allocator: Allocator, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, allocator, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, allocator: Allocator, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, allocator, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, allocator: Allocator, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, allocator, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, allocator: Allocator, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn referManyAt(array: *const Array, allocator: Allocator, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn overwriteManyAt(array: *Array, allocator: Allocator, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, allocator, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: Allocator, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: Allocator, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), sentinel_value);
        }
        pub fn stream(array: *Array, stream_count: u64) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn readOneAhead(array: *const Array) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), offset);
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), offset, sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, allocator));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, allocator), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertHolderMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, 1));
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, write_count));
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, values.len));
            array.writeMany(values);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFields(child, write_spec, fields)));
            array.writeFields(write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthArgs(child, write_spec, args)));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFormat(child, format)));
            array.writeFormat(format);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthAny(child, write_spec, any)));
            array.writeAny(write_spec, any);
        }
    });
}
pub fn StructuredHolder(comptime Allocator: type, comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime options: Parameters5.Options) type {
    const params: Parameters5 = params5(Allocator, child, sentinel, low_alignment, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters5;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn len(array: *const Array, allocator: Allocator) u64 {
            return array.impl.defined_byte_count(allocator) / child_size;
        }
        pub fn avail(array: *const Array, allocator: Allocator) u64 {
            return array.impl.undefined_byte_count(allocator) / child_size;
        }
        fn __at(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), offset * child_size);
        }
        fn __ad(array: *const Array, offset: u64) u64 {
            return math.add64(array.impl.undefined_byte_address(), offset * child_size);
        }
        fn __len(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), offset);
        }
        fn __rem(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return math.sub64(avail(array, allocator), offset);
        }
        pub fn readAll(array: *const Array, allocator: Allocator) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn referAllDefined(array: *const Array, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, allocator: Allocator, offset: u64) child {
            return pointer.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn referOneAt(array: *const Array, allocator: Allocator, offset: u64) *child {
            return pointer.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn overwriteOneAt(array: *Array, allocator: Allocator, offset: u64, value: child) void {
            writeOneInternal(child, __at(array, allocator, offset), value);
        }
        pub fn readCountAt(array: *const Array, allocator: Allocator, comptime read_count: u64, offset: u64) [read_count]child {
            return pointer.pointerCount(child, __at(array, allocator, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, allocator: Allocator, comptime read_count: u64, offset: u64) *[read_count]child {
            return pointer.pointerCount(child, __at(array, allocator, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, allocator: Allocator, comptime write_count: u64, offset: u64, values: [write_count]child) void {
            writeCountInternal(child, __at(array, allocator, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: u64) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: u64) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, allocator: Allocator, offset: u64) []const child {
            return pointer.pointerSlice(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn referManyAt(array: *const Array, allocator: Allocator, offset: u64) []child {
            return pointer.pointerSlice(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn overwriteManyAt(array: *Array, allocator: Allocator, offset: u64, values: []const child) void {
            writeManyInternal(child, __at(array, allocator, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: Allocator, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: Allocator, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), sentinel_value);
        }
        fn __back(array: *const Array, offset: u64) u64 {
            return math.sub64(array.impl.undefined_byte_address(), offset * child_size);
        }
        pub fn undefine(array: *Array, undefine_count: u64) void {
            array.impl.undefine(child_size * undefine_count);
        }
        pub fn readOneBack(array: *const Array) child {
            return pointer.pointerOne(child, __back(array, 1)).*;
        }
        pub fn referOneBack(array: *const Array) *child {
            return pointer.pointerOne(child, __back(array, 1));
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            writeOneInternal(child, __back(array, 1), value);
        }
        pub fn readCountBack(array: *const Array, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, read_count), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, write_count), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, read_count), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, offset: u64) []const child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn referManyBack(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, __back(array, offset), offset);
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            writeManyInternal(child, __back(array, values.len), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, offset), offset, sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, allocator));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, allocator), sentinel_value);
        }
        pub fn define(array: *Array, define_count: u64) void {
            array.impl.define(define_count * child_size);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(child_size);
        }
        pub fn referCountUndefined(array: *const Array, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * write_count);
        }
        pub fn referManyUndefined(array: *const Array, offset: u64) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), offset);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(child_size * values.len);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertHolderMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, 1));
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, write_count));
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, values.len));
            array.writeMany(values);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFields(child, write_spec, fields)));
            array.writeFields(write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthArgs(child, write_spec, args)));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthFormat(child, format)));
            array.writeFormat(format);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(allocator, reinterpret.lengthAny(child, write_spec, any)));
            array.writeAny(write_spec, any);
        }
    });
}
pub const Parameters6 = struct {
    Allocator: type,
    high_alignment: u64,
    low_alignment: ?u64 = null,
    options: Options = .{},
    comptime Specification: fn () type = Specification,
    const Parameters = @This();
    pub const Options = struct {
        lazy_alignment: bool = true,
        unit_alignment: bool = false,
    };
    fn Specification() type {
        return pointer.Specification14;
    }
    fn specification(comptime params: Parameters) params.Specification() {
        return .{
            .Allocator = params.Allocator,
            .high_alignment = params.high_alignment,
            .low_alignment = params.lowAlignment(),
        };
    }
    usingnamespace GenericParameters(Parameters);
};
pub fn UnstructuredStreamHolder(comptime Allocator: type, comptime high_alignment: u64, comptime low_alignment: ?u64, comptime options: Parameters6.Options) type {
    const params: Parameters6 = params6(Allocator, high_alignment, low_alignment, options);
    return (struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_stream_resize, params.options);
        pub const Parameters: type = Parameters6;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn streamAll(array: *Array, allocator: Allocator) void {
            array.impl.seek(array.impl.unstreamed_byte_count(allocator));
        }
        pub fn unstreamAll(array: *Array, allocator: Allocator) void {
            array.impl.tell(array.impl.streamed_byte_count(allocator));
        }
        pub fn index(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.streamed_byte_count(allocator) / @sizeOf(child);
        }
        pub fn len(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.defined_byte_count(allocator) / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.undefined_byte_count(allocator) / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.sub64(avail(array, child, allocator), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type, allocator: Allocator) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountOfTypeToBytes(unstream_amount, child));
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __behind(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __behind(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, allocator, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, allocator, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, allocator, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, allocator: Allocator, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, allocator, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, allocator, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), sentinel_value);
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountOfTypeToBytes(stream_amount, child));
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, array.impl.unstreamed_byte_address()).*;
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, array.impl.unstreamed_byte_address(), read_count).*;
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), read_count, sentinel_value).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.unstreamed_byte_address(), amountToCountOfType(offset, child), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child, allocator));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child, allocator), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertHolderMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn grow(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, add_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(add_amount, child) }));
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(sub_amount, child) }));
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = 1 }));
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = write_count }));
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = values.len }));
            array.writeMany(child, values);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFields(child, write_spec, fields) }));
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthArgs(child, write_spec, args) }));
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFormat(child, format) }));
            array.writeFormat(child, format);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthAny(child, write_spec, any) }));
            array.writeAny(child, write_spec, any);
        }
    });
}
pub fn UnstructuredHolder(comptime Allocator: type, comptime high_alignment: u64, comptime low_alignment: ?u64, comptime options: Parameters6.Options) type {
    const params: Parameters6 = params6(Allocator, high_alignment, low_alignment, options);
    const T = struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = specification.deduce(.read_write_resize, params.options);
        pub const Parameters: type = Parameters6;
        pub const Specification: type = params.Specification();
        pub const specification: Specification = params.specification();
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn len(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.defined_byte_count(allocator) / @sizeOf(child);
        }
        pub fn avail(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.undefined_byte_count(allocator) / @sizeOf(child);
        }
        fn __at(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), amountOfTypeToBytes(offset, child));
        }
        fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __len(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        fn __rem(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return math.sub64(avail(array, child, allocator), amountToCountOfType(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type, allocator: Allocator) []const child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn referAllDefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) child {
            return pointer.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) *child {
            return pointer.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, value: child) void {
            writeOneInternal(child, __at(array, child, allocator, offset), value);
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, offset: Amount) [read_count]child {
            return pointer.pointerCount(child, __at(array, child, allocator, offset), read_count).*;
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, offset: Amount) *[read_count]child {
            return pointer.pointerCount(child, __at(array, child, allocator, offset), read_count);
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, allocator: Allocator, comptime write_count: u64, offset: Amount, values: [write_count]child) void {
            writeCountInternal(child, __at(array, child, allocator, offset), write_count, values);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime read_count: u64, comptime sentinel_value: child, offset: Amount) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, sentinel_value);
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []const child {
            return pointer.pointerSlice(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []child {
            return pointer.pointerSlice(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, values: []const child) void {
            writeManyInternal(child, __at(array, child, allocator, offset), values);
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), sentinel_value);
        }
        fn __back(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(undefine_amount, child));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 })).*;
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, __back(array, child, .{ .count = 1 }));
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            writeOneInternal(child, __back(array, child, .{ .count = 1 }), value);
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: u64) [read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, __back(array, child, .{ .count = read_count }), read_count);
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            writeCountInternal(child, __back(array, child, .{ .count = write_count }), write_count, values);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) [read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value).*;
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: u64, comptime sentinel_value: child) *[read_count:sentinel_value]child {
            return pointer.pointerCountWithSentinel(child, __back(array, child, .{ .count = read_count }), read_count, sentinel_value);
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, __back(array, child, offset), amountToCountOfType(offset, child));
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            writeManyInternal(child, __back(array, child, .{ .count = values.len }), values);
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, __back(array, child, offset), amountToCountOfType(offset, child), sentinel_value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), avail(array, child, allocator));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime sentinel_value: child) [:sentinel_value]child {
            return pointer.pointerSliceWithSentinel(child, array.impl.undefined_byte_address(), avail(array, child, allocator), sentinel_value);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(define_amount, child));
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return pointer.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            pointer.pointerOne(child, array.impl.undefined_byte_address()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime read_count: u64) *[read_count]child {
            return pointer.pointerCount(child, array.impl.undefined_byte_address(), read_count);
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: u64, values: [write_count]child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * write_count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, offset: Amount) []child {
            return pointer.pointerSlice(child, array.impl.undefined_byte_address(), amountToCountOfType(offset, child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| pointer.pointerOne(child, array.impl.undefined_byte_address() +% i).* = value;
            array.impl.define(@sizeOf(child) * values.len);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn dynamic(array: *const Array, allocator: *Allocator, comptime Dynamic: type) Allocator.allocate_payload(Dynamic) {
            return .{ .impl = try meta.wrap(allocator.convertHolderMany(Implementation, Dynamic.Implementation, array.impl)) };
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn grow(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn shrink(array: *Array, comptime child: type, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(new_amount, child) }));
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, add_amount: Amount) Allocator.allocate_void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(add_amount, child) }));
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .bytes = amountOfTypeToBytes(sub_amount, child) }));
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = 1 }));
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: u64, values: [write_count]child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = write_count }));
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = values.len }));
            array.writeMany(child, values);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFields(child, write_spec, fields) }));
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthArgs(child, write_spec, args) }));
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthFormat(child, format) }));
            array.writeFormat(child, format);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            try meta.wrap(array.increment(child, allocator, .{ .count = reinterpret.lengthAny(child, write_spec, any) }));
            array.writeAny(child, write_spec, any);
        }
    };
    return T;
}
fn params0(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) Parameters0 {
    return .{
        .child = child,
        .sentinel = sentinel,
        .count = count,
        .low_alignment = low_alignment,
        .options = options,
    };
}
fn params1(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) Parameters1 {
    return .{
        .child = child,
        .sentinel = sentinel,
        .count = count,
        .low_alignment = low_alignment,
        .Allocator = Allocator,
        .options = options,
    };
}
fn params2(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) Parameters2 {
    return .{
        .bytes = bytes,
        .low_alignment = low_alignment,
        .Allocator = Allocator,
        .options = options,
    };
}
fn params3(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) Parameters3 {
    return .{
        .child = child,
        .sentinel = sentinel,
        .low_alignment = low_alignment,
        .Allocator = Allocator,
        .options = options,
    };
}
fn params4(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) Parameters4 {
    return .{
        .high_alignment = high_alignment,
        .low_alignment = low_alignment,
        .Allocator = Allocator,
        .options = options,
    };
}
fn params5(comptime Allocator: type, comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime options: Parameters5.Options) Parameters5 {
    return .{
        .Allocator = Allocator,
        .child = child,
        .sentinel = sentinel,
        .low_alignment = low_alignment,
        .options = options,
    };
}
fn params6(comptime Allocator: type, comptime high_alignment: u64, comptime low_alignment: ?u64, comptime options: Parameters6.Options) Parameters6 {
    return .{
        .Allocator = Allocator,
        .high_alignment = high_alignment,
        .low_alignment = low_alignment,
        .options = options,
    };
}
pub const spec = struct {
    pub const reinterpret = struct {
        pub const flat: ReinterpretSpec = .{};
        pub const ptr: ReinterpretSpec = .{
            .reference = .{ .dereference = &.{} },
        };
        pub const fmt: ReinterpretSpec = reinterpretRecursively(.{
            .reference = ptr.reference,
            .aggregate = .{ .iterate = true },
            .composite = .{ .format = true },
            .symbol = .{ .tag_name = true },
        });
        pub const print: ReinterpretSpec = reinterpretRecursively(.{
            .reference = ptr.reference,
            .aggregate = .{ .iterate = true },
            .composite = .{ .format = true },
            .symbol = .{ .tag_name = true },
        });
        pub const follow: ReinterpretSpec = blk: {
            var rs_0: ReinterpretSpec = .{};
            var rs_1: ReinterpretSpec = .{ .reference = .{
                .dereference = &rs_0,
            } };
            rs_1.reference.dereference = &rs_0;
            rs_0 = .{ .reference = .{
                .dereference = &rs_1,
            } };
            break :blk rs_1;
        };
        fn reinterpretRecursively(comptime reinterpret_spec: ReinterpretSpec) ReinterpretSpec {
            var rs_0: ReinterpretSpec = reinterpret_spec;
            var rs_1: ReinterpretSpec = reinterpret_spec;
            rs_0.reference.dereference = &rs_1;
            rs_1.reference.dereference = &rs_0;
            return rs_1;
        }
    };
};
