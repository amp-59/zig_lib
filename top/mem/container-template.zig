const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const meta = @import("../meta.zig");
const bits = @import("../bits.zig");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
const reference = @import("./ptr.zig");
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
        var ud64: fmt.Type.Ud64 = @bitCast(t_len);
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
