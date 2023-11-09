const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const bits = @import("../bits.zig");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const reference = @import("ptr.zig");
// start-document container-template.zig
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
    reference.pointerOne(child, next).* = value;
}
fn writeCountInternal(comptime child: type, next: u64, comptime write_count: u64, values: [write_count]child) void {
    for (values, 0..) |value, i| reference.pointerOne(child, next + i).* = value;
}
fn writeManyInternal(comptime child: type, next: u64, values: []const child) void {
    for (values, 0..) |value, i| reference.pointerOne(child, next + i).* = value;
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
pub const reinterpret = struct {
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
        debug.assert(src_type == dst_type);
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
        debug.assert(src_type == dst_type);
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
    pub inline fn writeFormat(comptime child: type, memory: anytype, format: anytype) void {
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
                const len_0: usize = memory.impl.undefined_byte_address();
                format.formatWrite(memory);
                const len_1: usize = memory.impl.undefined_byte_address();
                const t_len: usize = builtin.sub(usize, len_1, len_0);
                if (s_len < t_len) {
                    formatLengthFault(what, " >= ", s_len, t_len);
                }
            } else {
                const s_len: usize = format.formatLength();
                const len_0: usize = memory.impl.undefined_byte_address();
                format.formatWrite(memory);
                const len_1: usize = memory.impl.undefined_byte_address();
                const t_len: usize = builtin.sub(usize, len_1, len_0);
                if (t_len != s_len) {
                    formatLengthFault(what, " == ", s_len, t_len);
                }
            }
        } else {
            format.formatWrite(memory);
        }
    }
    fn formatLengthFault(format_type_name: []const u8, operator_symbol: anytype, s_len: u64, t_len: u64) noreturn {
        const help_read: bool = t_len > 99_999;
        const notation: []const u8 = if (help_read) ", i.e. " else "\n";
        var buf: [32768]u8 = undefined;
        const ptr: [*]u8 = &buf;
        var len: usize = 0;
        var ud64: fmt.Ud64 = @bitCast(t_len);
        @memcpy(ptr, format_type_name);
        len +%= format_type_name.len;
        len +%= ud64.formatWriteBuf(ptr + len);
        @as(*[operator_symbol.len]u8, @ptrCast(ptr + len)).* = operator_symbol.*;
        len +%= operator_symbol.len;
        ud64 = @bitCast(s_len);
        len +%= ud64.formatWriteBuf(ptr + len);
        @memcpy(ptr + len, notation);
        if (help_read) {
            buf[len] = '0';
            len +%= 1;
            @as(*[operator_symbol.len]u8, @ptrCast(ptr + len)).* = operator_symbol.*;
            len +%= operator_symbol.len;
            ud64 = @bitCast(t_len -% s_len);
            len +%= ud64.formatWriteBuf(ptr + len);
        }
        @panic(ptr[0..len]);
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
        debug.assert(src_type == dst_type);
    }
    pub fn lengthFormat(comptime child: type, format: anytype) u64 {
        const Format: type = @TypeOf(format);
        if (child != u8) {
            @compileError("invalid destination type for format write: " ++ @typeName(child));
        }
        if (@hasDecl(Format, "max_len")) {
            if (builtin.is_fast or builtin.is_small) return Format.max_len;
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
fn highAlignment(comptime spec: anytype) u64 {
    const Parameters = @TypeOf(spec);
    if (@hasField(Parameters, "high_alignment")) {
        return spec.high_alignment;
    }
    if (@hasField(Parameters, "child")) {
        return @sizeOf(spec.child);
    }
    if (spec.low_alignment) |low_alignment| {
        return low_alignment;
    }
    @compileError(@typeName(Parameters) ++
        ": no high address alignment, child size, or low " ++
        "addess alignment defined in container parameters");
}
fn lowAlignment(comptime spec: anytype) u64 {
    const Parameters = @TypeOf(spec);
    if (spec.low_alignment) |low_alignment| {
        return low_alignment;
    }
    if (@hasField(Parameters, "child")) {
        return @alignOf(spec.child);
    }
    if (@hasField(Parameters, "high_alignment")) {
        return spec.high_alignment;
    }
    @compileError(@typeName(Parameters) ++
        ": no low address alignment, child size, or high " ++
        "addess alignment defined in container parameters");
}
fn unitAlignment(comptime spec: anytype) u64 {
    const Parameters = @TypeOf(spec);
    if (@hasDecl(spec.Allocator, "allocator_spec")) {
        const AllocatorSpec: type = @TypeOf(spec.Allocator.allocator_spec);
        if (@hasField(AllocatorSpec, "unit_alignment")) {
            return spec.Allocator.allocator_spec.unit_alignment;
        }
        const AllocatorSpecOptions: type = @TypeOf(spec.Allocator.allocator_spec.options);
        if (@hasField(AllocatorSpecOptions, "unit_alignment")) {
            return spec.Allocator.allocator_spec.options.unit_alignment;
        }
    }
    if (@hasDecl(spec.Allocator, "unit_alignment")) {
        return spec.Allocator.unit_alignment;
    }
    @compileError(@typeName(Parameters) ++
        ": no unit aligment defined in Allocator declarations, " ++
        "specification, or specification options");
}
fn arenaIndex(comptime spec: anytype) ?u64 {
    const Parameters = @TypeOf(spec);
    if (@hasField(Parameters, "Allocator")) {
        if (@hasDecl(spec.Allocator, "arena_index")) {
            return spec.Allocator.arena_index;
        }
        if (@hasDecl(spec.Allocator, "allocator_spec")) {
            const AllocatorOptions: type = @TypeOf(spec.Allocator.allocator_spec.options);
            if (@hasField(AllocatorOptions, "arena_index")) {
                return spec.Allocator.allocator_spec.options.arena_index;
            }
        }
    } else {
        @compileError(@typeName(Parameters) ++
            ": no Allocator field in specification");
    }
    return null;
}
// finish-document container-template.zig
const Parameters0 = struct {
    child: type,
    count: u64,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            return reference.AutomaticStructuredReadWriteSentinel(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                .sentinel = sentinel,
            });
        } else {
            return reference.AutomaticStructuredReadWrite(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
            });
        }
    }
};
const Parameters1 = struct {
    child: type,
    count: u64,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            return reference.AutomaticStructuredReadWriteStreamSentinel(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                .sentinel = sentinel,
            });
        } else {
            return reference.AutomaticStructuredReadWriteStream(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
            });
        }
    }
};
const Parameters2 = struct {
    child: type,
    count: u64,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            return reference.AutomaticStructuredReadWriteResizeSentinel(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                .sentinel = sentinel,
            });
        } else {
            return reference.AutomaticStructuredReadWriteResize(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
            });
        }
    }
};
const Parameters3 = struct {
    child: type,
    count: u64,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            return reference.AutomaticStructuredReadWriteStreamResizeSentinel(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                .sentinel = sentinel,
            });
        } else {
            return reference.AutomaticStructuredReadWriteStreamResize(.{
                .child = spec.child,
                .count = spec.count,
                .low_alignment = spec.low_alignment orelse lowAlignment(spec),
            });
        }
    }
};
const Parameters4 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters5 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters6 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteResizeSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteResizeSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteResizeSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteResizeArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteResizeLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteResizeUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteResizeDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters7 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicStructuredReadWriteStreamResizeDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters8 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters9 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters10 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteResizeDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters11 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.DynamicUnstructuredReadWriteStreamResizeDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters12 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters13 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters14 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteResizeSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteResizeSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteResizeSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteResizeArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteResizeLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteResizeUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteResizeDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters15 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeSentinelDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeArenaDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeLazyAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeUnitAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticStructuredReadWriteStreamResizeDisjunctAlignment(.{
                            .child = spec.child,
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters16 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters17 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters18 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteResizeDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters19 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeSentinelDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .sentinel = sentinel,
                        });
                    },
                }
            }
        } else {
            if (@hasDecl(spec.Allocator, "arena")) {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeArenaDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                            .arena = spec.Allocator.arena,
                        });
                    },
                }
            } else {
                switch (spec.alignment) {
                    .lazy_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeLazyAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .unit_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeUnitAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                    .disjunct_alignment => {
                        return reference.StaticUnstructuredReadWriteStreamResizeDisjunctAlignment(.{
                            .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        });
                    },
                }
            }
        }
    }
};
const Parameters20 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricStructuredReadWriteResizeSentinelLazyAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricStructuredReadWriteResizeSentinelUnitAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
            }
        } else {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricStructuredReadWriteResizeLazyAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricStructuredReadWriteResizeUnitAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
            }
        }
    }
};
const Parameters21 = struct {
    child: type,
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricStructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricStructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
            }
        } else {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricStructuredReadWriteStreamResizeLazyAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricStructuredReadWriteStreamResizeUnitAlignment(.{
                        .child = spec.child,
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
            }
        }
    }
};
const Parameters22 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricUnstructuredReadWriteResizeSentinelLazyAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricUnstructuredReadWriteResizeSentinelUnitAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
            }
        } else {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricUnstructuredReadWriteResizeLazyAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricUnstructuredReadWriteResizeUnitAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
            }
        }
    }
};
const Parameters23 = struct {
    low_alignment: ?u64,
    sentinel: ?*const anyopaque,
    Allocator: type,
    const Parameters = @This();
    fn Implementation(comptime spec: Parameters) type {
        if (spec.sentinel) |sentinel| {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricUnstructuredReadWriteStreamResizeSentinelLazyAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricUnstructuredReadWriteStreamResizeSentinelUnitAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                        .sentinel = sentinel,
                    });
                },
            }
        } else {
            switch (spec.alignment) {
                .lazy_alignment => {
                    return reference.ParametricUnstructuredReadWriteStreamResizeLazyAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
                .unit_alignment => {
                    return reference.ParametricUnstructuredReadWriteStreamResizeUnitAlignment(.{
                        .low_alignment = spec.low_alignment orelse lowAlignment(spec),
                        .Allocator = spec.Allocator,
                    });
                },
            }
        }
    }
};
pub fn AutomaticStructuredReadWrite(comptime ctn_spec: Parameters0) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
    });
}
pub fn AutomaticStructuredReadWriteStream(comptime ctn_spec: Parameters1) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
    });
}
pub fn AutomaticStructuredReadWriteResize(comptime ctn_spec: Parameters2) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
    });
}
pub fn AutomaticStructuredReadWriteStreamResize(comptime ctn_spec: Parameters3) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
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
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
    });
}
pub fn DynamicStructuredReadWrite(comptime ctn_spec: Parameters4) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicStructuredReadWriteStream(comptime ctn_spec: Parameters5) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicStructuredReadWriteResize(comptime ctn_spec: Parameters6) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, format);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, allocator, 1);
            writeOne(array, value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, allocator, count);
            writeCount(array, count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, allocator, values.len);
            writeMany(array, values);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicStructuredReadWriteStreamResize(comptime ctn_spec: Parameters7) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, format);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, allocator, 1);
            writeOne(array, value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, allocator, count);
            writeCount(array, count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, allocator, values.len);
            writeMany(array, values);
        }
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
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicUnstructuredReadWrite(comptime ctn_spec: Parameters8) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.writable_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicUnstructuredReadWriteStream(comptime ctn_spec: Parameters9) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __streamed(array, child, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __streamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __unstreamed(array, child, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __unstreamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneStreamed(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child)));
        }
        pub fn referManyStreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __streamed(array, child, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.writable_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn ahead(array: *Array, comptime child: type) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), @sizeOf(child));
        }
        pub fn stream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.seek(amountOfTypeToBytes(amount, child));
        }
        pub fn unstream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.tell(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicUnstructuredReadWriteResize(comptime ctn_spec: Parameters10) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, child, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, child, format);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, child, allocator, Amount.unit);
            writeOne(array, child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, child, allocator, count);
            writeCount(array, child, count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, child, allocator, values.len);
            writeMany(array, child, values);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.defined_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.undefined_byte_count(), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn DynamicUnstructuredReadWriteStreamResize(comptime ctn_spec: Parameters11) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __streamed(array, child, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __streamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __unstreamed(array, child, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __unstreamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn referOneStreamed(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child)));
        }
        pub fn referManyStreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __streamed(array, child, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, child, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, child, format);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, child, allocator, Amount.unit);
            writeOne(array, child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, child, allocator, count);
            writeCount(array, child, count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, child, allocator, values.len);
            writeMany(array, child, values);
        }
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
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.defined_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.undefined_byte_count(), @sizeOf(child));
        }
        pub fn ahead(array: *Array, comptime child: type) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn stream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.seek(amountOfTypeToBytes(amount, child));
        }
        pub fn unstream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.tell(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = allocator;
            _ = count;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticStructuredReadWrite(comptime ctn_spec: Parameters12) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticStructuredReadWriteStream(comptime ctn_spec: Parameters13) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.writable_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticStructuredReadWriteResize(comptime ctn_spec: Parameters14) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticStructuredReadWriteStreamResize(comptime ctn_spec: Parameters15) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), offset);
        }
        fn __len(array: *const Array, offset: u64) u64 {
            return math.sub64(len(array), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address());
        }
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, offset), count);
        }
        pub fn referManyAt(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
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
        pub fn len(array: *const Array) u64 {
            return math.divT64(array.impl.defined_byte_count(), child_size);
        }
        pub fn index(array: *const Array) u64 {
            return math.divT64(array.impl.streamed_byte_count(), child_size);
        }
        pub fn avail(array: *const Array) u64 {
            return math.divT64(array.impl.undefined_byte_count(), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticUnstructuredReadWrite(comptime ctn_spec: Parameters16) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.writable_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticUnstructuredReadWriteStream(comptime ctn_spec: Parameters17) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __streamed(array, child, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __streamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __unstreamed(array, child, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __unstreamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneStreamed(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child)));
        }
        pub fn referManyStreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __streamed(array, child, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.streamed_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.writable_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn ahead(array: *Array, comptime child: type) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), @sizeOf(child));
        }
        pub fn stream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.seek(amountOfTypeToBytes(amount, child));
        }
        pub fn unstream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.tell(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticUnstructuredReadWriteResize(comptime ctn_spec: Parameters18) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.undefined_byte_count());
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.defined_byte_count());
        }
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.defined_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.undefined_byte_count(), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn StaticUnstructuredReadWriteStreamResize(comptime ctn_spec: Parameters19) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), offset);
        }
        fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(), len(array, child));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(), len(array, child), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __streamed(array, child, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __streamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __unstreamed(array, child, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __unstreamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn referOneStreamed(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child)));
        }
        pub fn referManyStreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __streamed(array, child, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
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
        pub fn len(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.defined_byte_count(), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.streamed_byte_count(), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type) u64 {
            return math.divT64(array.impl.undefined_byte_count(), @sizeOf(child));
        }
        pub fn ahead(array: *Array, comptime child: type) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn stream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.seek(amountOfTypeToBytes(amount, child));
        }
        pub fn unstream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.tell(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn ParametricStructuredReadWriteResize(comptime ctn_spec: Parameters20) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), offset);
        }
        fn __len(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address(allocator));
        }
        pub fn readAll(array: *const Array, allocator: *const Allocator) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: *const Allocator, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, allocator: *const Allocator, offset: u64) child {
            return reference.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, allocator: *const Allocator, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, allocator, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, allocator: *const Allocator, offset: u64) *child {
            return reference.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), count);
        }
        pub fn referManyAt(array: *const Array, allocator: *const Allocator, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, allocator, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, allocator: *const Allocator, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, allocator, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, allocator: *const Allocator, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, allocator, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, format);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, allocator, 1);
            writeOne(array, value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, allocator, count);
            writeCount(array, count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, allocator, values.len);
            writeMany(array, values);
        }
        pub fn defineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn len(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.defined_byte_count(allocator), child_size);
        }
        pub fn index(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.streamed_byte_count(allocator), child_size);
        }
        pub fn avail(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.undefined_byte_count(allocator), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn ParametricStructuredReadWriteStreamResize(comptime ctn_spec: Parameters21) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const child = ctn_spec.child;
        const child_size: u64 = @sizeOf(child);
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __defined(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.undefined_byte_address());
        }
        fn __unstreamed(array: *const Array, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __streamed(array: *const Array, offset: u64) u64 {
            return math.mulSub64(offset, child_size, array.impl.unstreamed_byte_address());
        }
        fn __avail(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), offset);
        }
        fn __len(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.sub64(len(array, allocator), math.mul64(offset, child_size));
        }
        fn __at(array: *const Array, allocator: *const Allocator, offset: u64) u64 {
            return math.mulAdd64(offset, child_size, array.impl.aligned_byte_address(allocator));
        }
        pub fn readAll(array: *const Array, allocator: *const Allocator) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: *const Allocator, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, allocator: *const Allocator, offset: u64) child {
            return reference.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, allocator: *const Allocator, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __at(array, allocator, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size)).*;
        }
        pub fn readCountDefined(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __defined(array, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __defined(array, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size)).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __streamed(array, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __streamed(array, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, offset: u64) child {
            return reference.pointerOne(child, __unstreamed(array, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime count: u64, offset: u64) [count]child {
            return reference.pointerCount(child, __unstreamed(array, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []const child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, allocator: *const Allocator, offset: u64) *child {
            return reference.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), count);
        }
        pub fn referManyAt(array: *const Array, allocator: *const Allocator, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __at(array, allocator, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), child_size));
        }
        pub fn referCountDefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __defined(array, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __defined(array, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __defined(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __undefined(array, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime count: u64, offset: u64) *[count]child {
            return reference.pointerCount(child, __undefined(array, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __undefined(array, offset), count);
        }
        pub fn referOneStreamed(array: *const Array) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), child_size));
        }
        pub fn referManyStreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, child_size, array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, offset: u64) *child {
            return reference.pointerOne(child, __streamed(array, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __streamed(array, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime count: u64, comptime sentinel_value: child, offset: u64) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, count: u64, offset: u64) []child {
            return reference.pointerSlice(child, __unstreamed(array, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, count: u64, comptime sentinel_value: child, offset: u64) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, allocator: *const Allocator, value: child, offset: u64) u64 {
            reference.pointerOne(child, __at(array, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, allocator: *const Allocator, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __at(array, allocator, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, allocator: *const Allocator, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __at(array, allocator, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, values: []const child) u64 {
            writeManyInternal(child, __defined(array, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, value: child, offset: u64) u64 {
            reference.pointerOne(child, __defined(array, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime count: u64, values: [count]child, offset: u64) u64 {
            reference.pointerCount(child, __defined(array, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, values: []const child, offset: u64) u64 {
            writeManyInternal(child, __defined(array, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsStructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsStructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, write_spec, args);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, format);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, allocator, 1);
            writeOne(array, value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, allocator, count);
            writeCount(array, count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, allocator, values.len);
            writeMany(array, values);
        }
        pub fn defineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array, allocator: *const Allocator) void {
            array.impl.tell(array.impl.streamed_byte_count(allocator));
        }
        pub fn len(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.defined_byte_count(allocator), child_size);
        }
        pub fn index(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.streamed_byte_count(allocator), child_size);
        }
        pub fn avail(array: *const Array, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.undefined_byte_count(allocator), child_size);
        }
        pub fn ahead(array: *Array) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), child_size);
        }
        pub fn define(array: *Array, count: u64) void {
            array.impl.define(math.mul64(count, child_size));
        }
        pub fn undefine(array: *Array, count: u64) void {
            array.impl.undefine(math.mul64(count, child_size));
        }
        pub fn stream(array: *Array, count: u64) u64 {
            array.impl.seek(math.mul64(count, child_size));
        }
        pub fn unstream(array: *Array, count: u64) u64 {
            array.impl.tell(math.mul64(count, child_size));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, allocator: *Allocator, offset: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, allocator: *Allocator, offset: u64) void {
            _ = array;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn ParametricUnstructuredReadWriteResize(comptime ctn_spec: Parameters22) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), offset);
        }
        fn __len(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type, allocator: *const Allocator) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: *const Allocator, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, allocator, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, allocator, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, allocator, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, allocator, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, child, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, child, format);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, child, allocator, Amount.unit);
            writeOne(array, child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, child, allocator, count);
            writeCount(array, child, count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, child, allocator, values.len);
            writeMany(array, child, values);
        }
        pub fn defineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn len(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.defined_byte_count(allocator), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.streamed_byte_count(allocator), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.undefined_byte_count(allocator), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
pub fn ParametricUnstructuredReadWriteStreamResize(comptime ctn_spec: Parameters23) type {
    return (struct {
        impl: Implementation,
        const Array = @This();
        const Allocator = ctn_spec.allocator;
        const Implementation = ctn_spec.Implementation();
        fn __undefined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __defined(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.undefined_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __unstreamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.add64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __streamed(array: *const Array, comptime child: type, offset: Amount) u64 {
            return math.sub64(array.impl.unstreamed_byte_address(), amountOfTypeToBytes(offset, child));
        }
        fn __avail(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), offset);
        }
        fn __len(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        fn __at(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) u64 {
            return math.add64(array.impl.aligned_byte_address(allocator), amountOfTypeToBytes(offset, child));
        }
        pub fn readAll(array: *const Array, comptime child: type, allocator: *const Allocator) []const child {
            return reference.pointerSlice(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: *const Allocator, comptime sentinel_value: child) []const child {
            return reference.pointerCountWithSentinel(child, array.impl.aligned_byte_address(allocator), len(array, child, allocator), sentinel_value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __at(array, child, allocator, offset), count);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn readOneDefined(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountDefined(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyDefined(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn readCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __defined(array, child, offset)).*;
        }
        pub fn readCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count).*;
        }
        pub fn readManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn readOneStreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child))).*;
        }
        pub fn readCountStreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count).*;
        }
        pub fn readManyStreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn readCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn readOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __streamed(array, child, offset)).*;
        }
        pub fn readCountOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __streamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn readOneUnstreamed(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.unstreamed_byte_address());
        }
        pub fn readCountUnstreamed(array: *const Array, comptime child: type, comptime count: u64) [count]child {
            return reference.pointerCount(child, array.impl.unstreamed_byte_address(), count).*;
        }
        pub fn readManyUnstreamed(array: *const Array, comptime child: type, count: u64) []const child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn readCountWithSentinelUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn readOneOffsetUnstreamed(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __unstreamed(array, child, offset));
        }
        pub fn readCountOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) [count]child {
            return reference.pointerCount(child, __unstreamed(array, child, offset), count).*;
        }
        pub fn readManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []const child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn readCountWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) [count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value).*;
        }
        pub fn readManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]const child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __at(array, child, allocator, offset), count);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: *const Allocator, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), count, sentinel_value);
        }
        pub fn referOneDefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.undefined_byte_address(), @sizeOf(child)));
        }
        pub fn referCountDefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referManyDefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count);
        }
        pub fn referCountWithSentinelDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.undefined_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetDefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __defined(array, child, offset));
        }
        pub fn referCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __defined(array, child, offset), count);
        }
        pub fn referManyOffsetDefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __defined(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetDefined(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __defined(array, child, offset), count, sentinel_value);
        }
        pub fn referOneUndefined(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, array.impl.undefined_byte_address());
        }
        pub fn referCountUndefined(array: *const Array, comptime child: type, comptime count: u64) *[count]child {
            return reference.pointerCount(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referManyUndefined(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.undefined_byte_address(), count);
        }
        pub fn referOneOffsetUndefined(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __undefined(array, child, offset));
        }
        pub fn referCountOffsetUndefined(array: *const Array, comptime child: type, comptime count: u64, offset: Amount) *[count]child {
            return reference.pointerCount(child, __undefined(array, child, offset), count);
        }
        pub fn referManyOffsetUndefined(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __undefined(array, child, offset), count);
        }
        pub fn referOneStreamed(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, math.sub64(array.impl.unstreamed_byte_address(), @sizeOf(child)));
        }
        pub fn referManyStreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count);
        }
        pub fn referCountWithSentinelStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referManyWithSentinelStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, math.mulSub64(count, @sizeOf(child), array.impl.unstreamed_byte_address()), count, sentinel_value);
        }
        pub fn referOneOffsetStreamed(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __streamed(array, child, offset));
        }
        pub fn referManyOffsetStreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __streamed(array, child, offset), count);
        }
        pub fn referCountWithSentinelOffsetStreamed(array: *const Array, comptime child: type, comptime count: u64, comptime sentinel_value: child, offset: Amount) *[count:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyWithSentinelOffsetStreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __streamed(array, child, offset), count, sentinel_value);
        }
        pub fn referManyUnstreamed(array: *const Array, comptime child: type, count: u64) []child {
            return reference.pointerSlice(child, array.impl.unstreamed_byte_address(), count);
        }
        pub fn referManyWithSentinelUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, array.impl.unstreamed_byte_address(), count, sentinel_value);
        }
        pub fn referManyOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, offset: Amount) []child {
            return reference.pointerSlice(child, __unstreamed(array, child, offset), count);
        }
        pub fn referManyWithSentinelOffsetUnstreamed(array: *const Array, comptime child: type, count: u64, comptime sentinel_value: child, offset: Amount) [:sentinel_value]child {
            return reference.pointerCountWithSentinel(child, __unstreamed(array, child, offset), count, sentinel_value);
        }
        pub fn overwriteOneAt(array: *const Array, comptime child: type, allocator: *const Allocator, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __at(array, child, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *const Array, comptime child: type, allocator: *const Allocator, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __at(array, child, allocator, offset), count).* = values;
        }
        pub fn overwriteManyAt(array: *const Array, comptime child: type, allocator: *const Allocator, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __at(array, child, allocator, offset), values);
        }
        pub fn overwriteOneDefined(array: *const Array, comptime child: type, value: child) u64 {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn overwriteCountDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child) u64 {
            reference.pointerCount(child, array.impl.undefined_byte_address(), count).* = values;
        }
        pub fn overwriteManyDefined(array: *const Array, comptime child: type, values: []const child) u64 {
            writeManyInternal(child, __defined(array, child, values.len), values);
        }
        pub fn overwriteOneOffsetDefined(array: *const Array, comptime child: type, value: child, offset: Amount) u64 {
            reference.pointerOne(child, __defined(array, child, offset)).* = value;
        }
        pub fn overwriteCountOffsetDefined(array: *const Array, comptime child: type, comptime count: u64, values: [count]child, offset: Amount) u64 {
            reference.pointerCount(child, __defined(array, child, offset), count).* = values;
        }
        pub fn overwriteManyOffsetDefined(array: *const Array, comptime child: type, values: []const child, offset: Amount) u64 {
            writeManyInternal(child, __defined(array, child, math.add64(values.len, offset)), values);
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.undefined_byte_address()).* = value;
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime count: u64, values: [count]child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (values, 0..) |value, i| reference.pointerOne(child, math.add64(array.impl.undefined_byte_address(), i)).* = value;
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            reinterpret.writeFormat(child, array, format);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            reinterpret.writeFieldsUnstructured(child, write_spec, array, fields);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            reinterpret.writeArgsUnstructured(child, write_spec, array, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFields(child, write_spec, fields));
            writeFields(array, child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthAny(child, write_spec, any));
            writeAny(array, child, write_spec, any);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthArgs(child, write_spec, args));
            writeArgs(array, child, write_spec, args);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) Allocator.allocate_void {
            increment(array, child, allocator, reinterpret.lengthFormat(child, format));
            writeFormat(array, child, format);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) Allocator.allocate_void {
            increment(array, child, allocator, Amount.unit);
            writeOne(array, child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime count: u64, values: [count]child) Allocator.allocate_void {
            increment(array, child, allocator, count);
            writeCount(array, child, count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) Allocator.allocate_void {
            increment(array, child, allocator, values.len);
            writeMany(array, child, values);
        }
        pub fn defineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.define(array.impl.undefined_byte_count(allocator));
        }
        pub fn undefineAll(array: *Array, allocator: *const Allocator) void {
            array.impl.undefine(array.impl.defined_byte_count(allocator));
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.unstreamed_byte_count());
        }
        pub fn unstreamAll(array: *Array, allocator: *const Allocator) void {
            array.impl.tell(array.impl.streamed_byte_count(allocator));
        }
        pub fn len(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.defined_byte_count(allocator), @sizeOf(child));
        }
        pub fn index(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.streamed_byte_count(allocator), @sizeOf(child));
        }
        pub fn avail(array: *const Array, comptime child: type, allocator: *const Allocator) u64 {
            return math.divT64(array.impl.undefined_byte_count(allocator), @sizeOf(child));
        }
        pub fn ahead(array: *Array, comptime child: type) u64 {
            return math.divT64(array.impl.unstreamed_byte_count(), @sizeOf(child));
        }
        pub fn define(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.define(amountOfTypeToBytes(amount, child));
        }
        pub fn undefine(array: *Array, comptime child: type, amount: Amount) void {
            array.impl.undefine(amountOfTypeToBytes(amount, child));
        }
        pub fn stream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.seek(amountOfTypeToBytes(amount, child));
        }
        pub fn unstream(array: *Array, comptime child: type, amount: Amount) u64 {
            array.impl.tell(amountOfTypeToBytes(amount, child));
        }
        pub fn init(allocator: *Allocator) Allocator.allocate_void {
            _ = allocator;
        }
        pub fn grow(array: *Array, allocator: *Allocator, count: u64) Allocator.allocate_void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn increment(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) Allocator.allocate_void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn shrink(array: *Array, allocator: *Allocator, count: u64) void {
            _ = array;
            _ = allocator;
            _ = count;
        }
        pub fn decrement(array: *Array, comptime child: type, allocator: *Allocator, offset: Amount) void {
            _ = array;
            _ = child;
            _ = allocator;
            _ = offset;
        }
        pub fn static() u64 {
            _ = @This();
        }
        pub fn dynamic() u64 {
            _ = @This();
        }
        pub fn holder() u64 {
            _ = @This();
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            _ = array;
            _ = allocator;
        }
    });
}
