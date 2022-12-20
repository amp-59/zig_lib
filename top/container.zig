const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");
const reference = @import("./reference.zig");
pub const Amount = union(enum) { bytes: u64, count: u64 };

pub fn amountToCountOfType(amt: Amount, comptime child: type) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes / @sizeOf(child),
        .count => |count| count,
    };
}
pub fn amountToBytesOfType(amt: Amount, comptime child: type) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes,
        .count => |count| count * @sizeOf(child),
    };
}
pub fn amountToCountOfLength(amt: Amount, length: u64) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes / length,
        .count => |count| count,
    };
}
pub fn amountToBytesOfLength(amt: Amount, length: u64) u64 {
    return switch (amt) {
        .bytes => |bytes| bytes,
        .count => |count| count * length,
    };
}
fn hasSentinel(comptime impl_type: type) bool {
    return @hasDecl(impl_type, "sentinel") or
        @hasDecl(impl_type, "Specification") and
        @hasField(impl_type.Specification, "sentinel");
}
pub fn amountToCountReserved(amt: Amount, comptime impl_type: type) u64 {
    return amountToCountOfLength(amt, impl_type.high_alignment) +
        builtin.int(hasSentinel(impl_type));
}
pub fn amountToBytesReserved(amt: Amount, comptime impl_type: type) u64 {
    return amountToBytesOfLength(amt, impl_type.high_alignment) +
        mach.cmov64z(hasSentinel(impl_type), impl_type.high_alignment);
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
pub fn StructuredAutomaticView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return struct {
        impl: Implementation = .{},
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.capacity() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
    };
}
pub fn StructuredAutomaticStreamView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return struct {
        impl: Implementation = .{ .ss_word = 0 },
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub inline fn index(array: *const Array) u64 {
            return array.impl.behind() / child_size;
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.capacity() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredAutomaticStreamVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return struct {
        impl: Implementation = .{ .ub_word = 0, .ss_word = 0 },
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub inline fn index(array: *const Array) u64 {
            return array.impl.behind() / child_size;
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredAutomaticVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime options: Parameters0.Options) type {
    const params: Parameters0 = params0(child, sentinel, count, low_alignment, options);
    return struct {
        impl: Implementation = .{ .ub_word = 0 },
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop_auto, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters0;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
    };
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
            if (params.arenaIndex() != null) {
                return reference.Specification3;
            }
        } else {
            if (params.arenaIndex() != null) {
                return reference.Specification2;
            }
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.capacity() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
    };
}
pub fn StructuredStaticStreamVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) type {
    const params: Parameters1 = params1(child, sentinel, count, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn index(array: *const Array) u64 {
            return array.impl.behind() / child_size;
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredStaticVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime count: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters1.Options) type {
    const params: Parameters1 = params1(child, sentinel, count, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters1;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
    };
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
            return reference.Specification5;
        } else {
            return reference.Specification4;
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.capacity() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
    };
}
pub fn UnstructuredStaticStreamVector(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) type {
    const params: Parameters2 = params2(bytes, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __behind(array, child, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountToBytesOfType(stream_amount, child));
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountToBytesOfType(unstream_amount, child));
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.behind() / @sizeOf(child);
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.length() / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.available() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.position(), amountToBytesOfType(offset, child));
        }
    };
}
pub fn UnstructuredStaticVector(comptime bytes: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters2.Options) type {
    const params: Parameters2 = params2(bytes, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters2;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateStatic(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateStatic(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.length() / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.available() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
    };
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
                return reference.Specification9;
            } else {
                return reference.Specification7;
            }
        } else {
            if (params.arenaIndex() != null) {
                return reference.Specification8;
            } else {
                return reference.Specification6;
            }
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) !void {
            try array.increment(allocator, 1);
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(allocator, write_count);
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) !void {
            try array.increment(allocator, values.len);
            array.writeMany(values);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFormat(child, format));
            array.writeFormat(format);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthArgs(child, write_spec, args));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFields(child, write_spec, fields));
            array.writeFields(write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthAny(child, write_spec, any));
            array.writeAny(write_spec, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) !void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub inline fn index(array: *const Array) u64 {
            return array.impl.behind() / child_size;
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredStreamView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub inline fn index(array: *const Array) u64 {
            return array.impl.behind() / child_size;
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.capacity() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredVector(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) !void {
            try array.increment(allocator, 1);
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(allocator, write_count);
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) !void {
            try array.increment(allocator, values.len);
            array.writeMany(values);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFormat(child, format));
            array.writeFormat(format);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthArgs(child, write_spec, args));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFields(child, write_spec, fields));
            array.writeFields(write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthAny(child, write_spec, any));
            array.writeAny(write_spec, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) !void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.length() / child_size;
        }
        pub inline fn avail(array: *const Array) u64 {
            return array.impl.available() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
        inline fn __rem(array: *const Array, offset: u64) u64 {
            return mach.sub64(avail(array), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
    };
}
pub fn StructuredView(comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters3.Options) type {
    const params: Parameters3 = params3(child, sentinel, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters3;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, offset: usize) child {
            return reference.pointerOne(child, __at(array, offset)).*;
        }
        pub fn readCountAt(array: *const Array, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn readCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn referOneAt(array: *const Array, offset: usize) *child {
            return reference.pointerOne(child, __at(array, offset));
        }
        pub fn referCountAt(array: *const Array, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __at(array, offset), __len(array, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, offset), __len(array, offset), value);
        }
        pub fn overwriteOneAt(array: *Array, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, offset), __len(array, offset))) |*value, i| value.* = values[i];
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array) u64 {
            return array.impl.capacity() / child_size;
        }
        inline fn __at(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.start(), offset * child_size);
        }
        inline fn __len(array: *const Array, offset: u64) u64 {
            return mach.sub64(len(array), offset);
        }
    };
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
            return reference.Specification11;
        } else {
            return reference.Specification10;
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __behind(array, child, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) !void {
            try array.increment(child, allocator, .{ .count = 1 });
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(child, allocator, .{ .count = write_count });
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) !void {
            try array.increment(child, allocator, .{ .count = values.len });
            array.writeMany(child, values);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFormat(child, format) });
            array.writeFormat(child, format);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthArgs(child, write_spec, args) });
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFields(child, write_spec, fields) });
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthAny(child, write_spec, any) });
            array.writeAny(child, write_spec, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountToBytesOfType(stream_amount, child));
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountToBytesOfType(unstream_amount, child));
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_amount: Amount) !void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, add_amount));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, sub_amount));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_amount: Amount) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, new_amount));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, new_amount));
        }
        pub inline fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.behind() / @sizeOf(child);
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.length() / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.available() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.position(), amountToBytesOfType(offset, child));
        }
    };
}
pub fn UnstructuredStreamView(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __behind(array, child, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountToBytesOfType(stream_amount, child));
        }
        pub fn streamAll(array: *Array) void {
            array.impl.seek(array.impl.ahead());
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountToBytesOfType(unstream_amount, child));
        }
        pub fn unstreamAll(array: *Array) void {
            array.impl.tell(array.impl.behind());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_amount: Amount) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, new_amount));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, new_amount));
        }
        pub inline fn index(array: *const Array, comptime child: type) u64 {
            return array.impl.behind() / @sizeOf(child);
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.capacity() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        inline fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.position(), amountToBytesOfType(offset, child));
        }
    };
}
pub fn UnstructuredVector(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __ad(array, 0), __rem(array, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, 0), __rem(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) !void {
            try array.increment(child, allocator, .{ .count = 1 });
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(child, allocator, .{ .count = write_count });
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) !void {
            try array.increment(child, allocator, .{ .count = values.len });
            array.writeMany(child, values);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFormat(child, format) });
            array.writeFormat(child, format);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthArgs(child, write_spec, args) });
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFields(child, write_spec, fields) });
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthAny(child, write_spec, any) });
            array.writeAny(child, write_spec, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array) void {
            array.impl.define(array.impl.available());
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array) void {
            array.impl.undefine(array.impl.length());
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_amount: Amount) !void {
            try meta.wrap(allocator.resizeManyIncrement(Implementation, &array.impl, add_amount));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeManyDecrement(Implementation, &array.impl, sub_amount));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_amount: Amount) !void {
            try meta.wrap(allocator.resizeManyAbove(Implementation, &array.impl, new_amount));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeManyBelow(Implementation, &array.impl, new_amount));
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.length() / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type) u64 {
            return array.impl.available() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(avail(array, child), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
    };
}
pub fn UnstructuredView(comptime high_alignment: u64, comptime low_alignment: ?u64, comptime Allocator: type, comptime options: Parameters4.Options) type {
    const params: Parameters4 = params4(high_alignment, low_alignment, Allocator, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters4;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type) []const child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type) []child {
            return reference.pointerMany(child, __at(array, 0), __len(array, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, 0), __len(array, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset));
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, offset), __len(array, child, offset), value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, offset), __len(array, child, offset))) |*value, i| value.* = values[i];
        }
        pub fn init(allocator: *Allocator, init_count: u64) !Array {
            return .{ .impl = try meta.wrap(allocator.allocateMany(Implementation, .{ .count = init_count })) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateMany(Implementation, array.impl));
        }
        pub inline fn len(array: *const Array, comptime child: type) u64 {
            return array.impl.capacity() / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.start(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(len(array, child), amountToCountOfType(offset, child));
        }
    };
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
            return reference.Specification13;
        } else {
            return reference.Specification12;
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters5;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array, allocator: Allocator) []const child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllDefined(array: *const Array, allocator: Allocator) []child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, allocator: Allocator) []child {
            return reference.pointerMany(child, __ad(array, allocator, 0), __rem(array, allocator, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, allocator, 0), __rem(array, allocator, 0), value);
        }
        pub fn readOneAt(array: *const Array, allocator: Allocator, offset: usize) child {
            return reference.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, allocator: Allocator, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readOneBehind(array: *const Array) child {
            return reference.pointerOne(child, __behind(array, 1)).*;
        }
        pub fn readOneAhead(array: *const Array) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, read_count), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __behind(array, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, allocator: Allocator, offset: usize) *child {
            return reference.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, allocator: Allocator, offset: usize) []child {
            return reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, allocator: Allocator, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, allocator: Allocator, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, allocator, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, allocator: Allocator, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) !void {
            try array.increment(allocator, 1);
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(allocator, write_count);
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) !void {
            try array.increment(allocator, values.len);
            array.writeMany(values);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFormat(child, format));
            array.writeFormat(format);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthArgs(child, write_spec, args));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFields(child, write_spec, fields));
            array.writeFields(write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthAny(child, write_spec, any));
            array.writeAny(write_spec, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.available(allocator));
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.length(allocator));
        }
        pub fn stream(array: *Array, stream_count: usize) void {
            array.impl.seek(stream_count * child_size);
        }
        pub fn streamAll(array: *Array, allocator: Allocator) void {
            array.impl.seek(array.impl.ahead(allocator));
        }
        pub fn unstream(array: *Array, unstream_count: usize) void {
            array.impl.tell(unstream_count * child_size);
        }
        pub fn unstreamAll(array: *Array, allocator: Allocator) void {
            array.impl.tell(array.impl.behind(allocator));
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) !void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) !void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub inline fn index(array: *const Array, allocator: Allocator) u64 {
            return array.impl.behind(allocator) / child_size;
        }
        pub inline fn len(array: *const Array, allocator: Allocator) u64 {
            return array.impl.length(allocator) / child_size;
        }
        pub inline fn avail(array: *const Array, allocator: Allocator) u64 {
            return array.impl.available(allocator) / child_size;
        }
        inline fn __at(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.add64(array.impl.start(allocator), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.sub64(len(array, allocator), offset);
        }
        inline fn __rem(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.sub64(avail(array, allocator), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
        inline fn __behind(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.position(), offset * child_size);
        }
    };
}
pub fn StructuredHolder(comptime Allocator: type, comptime child: type, comptime sentinel: ?*const anyopaque, comptime low_alignment: ?u64, comptime options: Parameters5.Options) type {
    const params: Parameters5 = params5(Allocator, child, sentinel, low_alignment, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters5;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub const child_size: u64 = @sizeOf(child);
        pub fn readAll(array: *const Array, allocator: Allocator) []const child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllDefined(array: *const Array, allocator: Allocator) []child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, allocator: Allocator) []child {
            return reference.pointerMany(child, __ad(array, allocator, 0), __rem(array, allocator, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, allocator, 0), __rem(array, allocator, 0), value);
        }
        pub fn readOneAt(array: *const Array, allocator: Allocator, offset: usize) child {
            return reference.pointerOne(child, __at(array, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, allocator: Allocator, offset: usize) []const child {
            return reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn readOneBack(array: *const Array) child {
            return reference.pointerOne(child, __prev(array, 1)).*;
        }
        pub fn readCountBack(array: *const Array, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count).*;
        }
        pub fn readManyBack(array: *const Array, offset: usize) []const child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, allocator: Allocator, offset: usize) *child {
            return reference.pointerOne(child, __at(array, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, allocator, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, allocator: Allocator, offset: usize) []child {
            return reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset));
        }
        pub fn referOneBack(array: *const Array) *child {
            return reference.pointerOne(child, __prev(array, 1));
        }
        pub fn referCountBack(array: *const Array, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, read_count), read_count);
        }
        pub fn referManyBack(array: *const Array, offset: usize) []child {
            return reference.pointerMany(child, __prev(array, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, allocator, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, allocator: Allocator, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, offset), __len(array, allocator, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, read_count), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, offset: usize, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, allocator: Allocator, offset: usize, value: child) void {
            reference.pointerOne(child, __at(array, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, allocator: Allocator, offset: usize, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, allocator, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, allocator: Allocator, offset: usize, values: []const child) void {
            for (reference.pointerMany(child, __at(array, allocator, offset), __len(array, allocator, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, value: child) void {
            reference.pointerOne(child, __prev(array, 1)).* = value;
        }
        pub fn overwriteManyBack(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, values.len), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(child_size);
        }
        pub fn writeCount(array: *Array, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * child_size);
        }
        pub fn writeMany(array: *Array, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * child_size);
        }
        pub fn writeFormat(array: *Array, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyStructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyStructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyStructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, allocator: *Allocator, value: child) !void {
            try array.increment(allocator, 1);
            array.writeOne(value);
        }
        pub fn appendCount(array: *Array, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(allocator, write_count);
            array.writeCount(write_count, values);
        }
        pub fn appendMany(array: *Array, allocator: *Allocator, values: []const child) !void {
            try array.increment(allocator, values.len);
            array.writeMany(values);
        }
        pub fn appendFormat(array: *Array, allocator: *Allocator, format: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFormat(child, format));
            array.writeFormat(format);
        }
        pub fn appendArgs(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthArgs(child, write_spec, args));
            array.writeArgs(write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthFields(child, write_spec, fields));
            array.writeFields(write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(allocator, Reinterpret.lengthAny(child, write_spec, any));
            array.writeAny(write_spec, any);
        }
        pub fn define(array: *Array, define_count: usize) void {
            array.impl.define(define_count * child_size);
        }
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.available(allocator));
        }
        pub fn undefine(array: *Array, undefine_count: usize) void {
            array.impl.undefine(undefine_count * child_size);
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.length(allocator));
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_count: u64) !void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, .{ .count = add_count }));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_count: u64) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, .{ .count = sub_count }));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_count: u64) !void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_count: u64) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, .{ .count = new_count }));
        }
        pub inline fn len(array: *const Array, allocator: Allocator) u64 {
            return array.impl.length(allocator) / child_size;
        }
        pub inline fn avail(array: *const Array, allocator: Allocator) u64 {
            return array.impl.available(allocator) / child_size;
        }
        inline fn __at(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.add64(array.impl.start(allocator), offset * child_size);
        }
        inline fn __ad(array: *const Array, offset: u64) u64 {
            return mach.add64(array.impl.next(), offset * child_size);
        }
        inline fn __len(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.sub64(len(array, allocator), offset);
        }
        inline fn __rem(array: *const Array, allocator: Allocator, offset: u64) u64 {
            return mach.sub64(avail(array, allocator), offset);
        }
        inline fn __prev(array: *const Array, offset: u64) u64 {
            return mach.sub64(array.impl.next(), offset * child_size);
        }
    };
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
        return reference.Specification14;
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
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_stream_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters6;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type, allocator: Allocator) []const child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return reference.pointerMany(child, __ad(array, allocator, 0), __rem(array, allocator, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, allocator, 0), __rem(array, allocator, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readOneBehind(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __behind(array, child, .{ .count = 1 })).*;
        }
        pub fn readOneAhead(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, array.impl.position()).*;
        }
        pub fn readCountBehind(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __behind(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBehind(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __behind(array, child, offset), offset);
        }
        pub fn readCountAhead(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, array.impl.position(), read_count).*;
        }
        pub fn readManyAhead(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, array.impl.position(), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn readCountWithSentinelAhead(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, array.impl.position(), read_count, value).*;
        }
        pub fn readManyWithSentinelAhead(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, array.impl.position(), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referCountWithSentinelBehind(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __behind(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBehind(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __behind(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, allocator, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) !void {
            try array.increment(child, allocator, .{ .count = 1 });
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(child, allocator, .{ .count = write_count });
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) !void {
            try array.increment(child, allocator, .{ .count = values.len });
            array.writeMany(child, values);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFormat(child, format) });
            array.writeFormat(child, format);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthArgs(child, write_spec, args) });
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFields(child, write_spec, fields) });
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthAny(child, write_spec, any) });
            array.writeAny(child, write_spec, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.available(allocator));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.length(allocator));
        }
        pub fn stream(array: *Array, comptime child: type, stream_amount: Amount) void {
            array.impl.seek(amountToBytesOfType(stream_amount, child));
        }
        pub fn streamAll(array: *Array, allocator: Allocator) void {
            array.impl.seek(array.impl.ahead(allocator));
        }
        pub fn unstream(array: *Array, comptime child: type, unstream_amount: Amount) void {
            array.impl.tell(amountToBytesOfType(unstream_amount, child));
        }
        pub fn unstreamAll(array: *Array, allocator: Allocator) void {
            array.impl.tell(array.impl.behind(allocator));
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_amount: Amount) !void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, add_amount));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, sub_amount));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_amount: Amount) !void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, new_amount));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, new_amount));
        }
        pub inline fn index(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.behind(allocator) / @sizeOf(child);
        }
        pub inline fn len(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.length(allocator) / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.available(allocator) / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.add64(array.impl.start(allocator), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.sub64(avail(array, child, allocator), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __behind(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.position(), amountToBytesOfType(offset, child));
        }
    };
}
pub fn UnstructuredHolder(comptime Allocator: type, comptime high_alignment: u64, comptime low_alignment: ?u64, comptime options: Parameters6.Options) type {
    const params: Parameters6 = params6(Allocator, high_alignment, low_alignment, options);
    return struct {
        impl: Implementation,
        const Array = @This();
        pub const Implementation: type = spec.deduce(.read_write_push_pop, params.options);
        pub const Reference: type = Implementation;
        pub const Parameters: type = Parameters6;
        pub const Specification: type = params.Specification();
        pub const spec: Specification = params.specification();
        pub fn readAll(array: *const Array, comptime child: type, allocator: Allocator) []const child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn readAllWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllDefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return reference.pointerMany(child, __at(array, allocator, 0), __len(array, allocator, 0));
        }
        pub fn referAllDefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, allocator, 0), __len(array, allocator, 0), value);
        }
        pub fn referAllUndefined(array: *const Array, comptime child: type, allocator: Allocator) []child {
            return reference.pointerMany(child, __ad(array, allocator, 0), __rem(array, allocator, 0));
        }
        pub fn referAllUndefinedWithSentinel(array: *const Array, comptime child: type, allocator: Allocator, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __ad(array, allocator, 0), __rem(array, allocator, 0), value);
        }
        pub fn readOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) child {
            return reference.pointerOne(child, __at(array, child, allocator, offset)).*;
        }
        pub fn readCountAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), read_count).*;
        }
        pub fn readManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []const child {
            return reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn readOneBack(array: *const Array, comptime child: type) child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).*;
        }
        pub fn readCountBack(array: *const Array, comptime child: type, comptime read_count: usize) [read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count).*;
        }
        pub fn readManyBack(array: *const Array, comptime child: type, offset: Amount) []const child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn readCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, value).*;
        }
        pub fn readManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), value);
        }
        pub fn readCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) [read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value).*;
        }
        pub fn readManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]const child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn referOneAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) *child {
            return reference.pointerOne(child, __at(array, child, allocator, offset));
        }
        pub fn referCountAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __at(array, child, allocator, offset), read_count);
        }
        pub fn referManyAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) []child {
            return reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset));
        }
        pub fn referOneBack(array: *const Array, comptime child: type) *child {
            return reference.pointerOne(child, __prev(array, child, .{ .count = 1 }));
        }
        pub fn referCountBack(array: *const Array, comptime child: type, comptime read_count: usize) *[read_count]child {
            return reference.pointerCount(child, __prev(array, child, .{ .count = read_count }), read_count);
        }
        pub fn referManyBack(array: *const Array, comptime child: type, offset: Amount) []child {
            return reference.pointerMany(child, __prev(array, child, offset), offset);
        }
        pub fn referCountWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __at(array, child, allocator, offset), read_count, value);
        }
        pub fn referManyWithSentinelAt(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset), value);
        }
        pub fn referCountWithSentinelBack(array: *const Array, comptime child: type, comptime read_count: usize, comptime value: child) *[read_count:value]child {
            return reference.pointerCountWithSentinel(child, __prev(array, child, .{ .count = read_count }), read_count, value);
        }
        pub fn referManyWithSentinelBack(array: *const Array, comptime child: type, offset: Amount, comptime value: child) [:value]child {
            return reference.pointerManyWithSentinel(child, __prev(array, child, offset), offset, value);
        }
        pub fn overwriteOneAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, value: child) void {
            reference.pointerOne(child, __at(array, child, allocator, offset)).* = value;
        }
        pub fn overwriteCountAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __at(array, child, allocator, offset), write_count)) |*value, i| value.* = values[i];
        }
        pub fn overwriteManyAt(array: *Array, comptime child: type, allocator: Allocator, offset: Amount, values: []const child) void {
            for (reference.pointerMany(child, __at(array, child, allocator, offset), __len(array, child, allocator, offset))) |*value, i| value.* = values[i];
        }
        pub fn overwriteOneBack(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, __prev(array, child, .{ .count = 1 })).* = value;
        }
        pub fn overwriteManyBack(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn overwriteCountBack(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, __prev(array, child, .{ .count = values.len }), values.len)) |*value, i| value.* = values[i];
        }
        pub fn writeOne(array: *Array, comptime child: type, value: child) void {
            reference.pointerOne(child, array.impl.next()).* = value;
            array.impl.define(@sizeOf(child));
        }
        pub fn writeCount(array: *Array, comptime child: type, comptime write_count: usize, values: [write_count]child) void {
            for (reference.pointerCount(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(write_count * @sizeOf(child));
        }
        pub fn writeMany(array: *Array, comptime child: type, values: []const child) void {
            for (reference.pointerMany(child, array.impl.next(), values.len)) |*value, i| value.* = values[i];
            array.impl.define(values.len * @sizeOf(child));
        }
        pub fn writeFormat(array: *Array, comptime child: type, format: anytype) void {
            Reinterpret.writeFormat(child, array, format);
        }
        pub fn writeArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, args: anytype) void {
            inline for (args) |arg| Reinterpret.writeAnyUnstructured(child, write_spec, array, arg);
        }
        pub fn writeFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, fields: anytype) void {
            inline for (@typeInfo(@TypeOf(fields)).Struct.fields) |field|
                Reinterpret.writeAnyUnstructured(child, write_spec, array, @field(fields, field.name));
        }
        pub fn writeAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, any: anytype) void {
            Reinterpret.writeAnyUnstructured(child, write_spec, array, any);
        }
        pub fn appendOne(array: *Array, comptime child: type, allocator: *Allocator, value: child) !void {
            try array.increment(child, allocator, .{ .count = 1 });
            array.writeOne(child, value);
        }
        pub fn appendCount(array: *Array, comptime child: type, allocator: *Allocator, comptime write_count: usize, values: [write_count]child) !void {
            try array.increment(child, allocator, .{ .count = write_count });
            array.writeCount(child, write_count, values);
        }
        pub fn appendMany(array: *Array, comptime child: type, allocator: *Allocator, values: []const child) !void {
            try array.increment(child, allocator, .{ .count = values.len });
            array.writeMany(child, values);
        }
        pub fn appendFormat(array: *Array, comptime child: type, allocator: *Allocator, format: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFormat(child, format) });
            array.writeFormat(child, format);
        }
        pub fn appendArgs(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, args: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthArgs(child, write_spec, args) });
            array.writeArgs(child, write_spec, args);
        }
        pub fn appendFields(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, fields: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthFields(child, write_spec, fields) });
            array.writeFields(child, write_spec, fields);
        }
        pub fn appendAny(array: *Array, comptime child: type, comptime write_spec: ReinterpretSpec, allocator: *Allocator, any: anytype) !void {
            try array.increment(child, allocator, .{ .count = Reinterpret.lengthAny(child, write_spec, any) });
            array.writeAny(child, write_spec, any);
        }
        pub fn define(array: *Array, comptime child: type, define_amount: Amount) void {
            array.impl.define(amountToBytesOfType(define_amount, child));
        }
        pub fn defineAll(array: *Array, allocator: Allocator) void {
            array.impl.define(array.impl.available(allocator));
        }
        pub fn undefine(array: *Array, comptime child: type, undefine_amount: Amount) void {
            array.impl.undefine(amountToBytesOfType(undefine_amount, child));
        }
        pub fn undefineAll(array: *Array, allocator: Allocator) void {
            array.impl.undefine(array.impl.length(allocator));
        }
        pub fn init(allocator: *Allocator) Array {
            return .{ .impl = try meta.wrap(allocator.allocateHolder(Implementation)) };
        }
        pub fn deinit(array: *Array, allocator: *Allocator) void {
            try meta.wrap(allocator.deallocateHolder(Implementation, array.impl));
        }
        pub fn increment(array: *Array, allocator: *Allocator, add_amount: Amount) !void {
            try meta.wrap(allocator.resizeHolderIncrement(Implementation, &array.impl, add_amount));
        }
        pub fn decrement(array: *Array, allocator: *Allocator, sub_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderDecrement(Implementation, &array.impl, sub_amount));
        }
        pub fn grow(array: *Array, allocator: *Allocator, new_amount: Amount) !void {
            try meta.wrap(allocator.resizeHolderAbove(Implementation, &array.impl, new_amount));
        }
        pub fn shrink(array: *Array, allocator: *Allocator, new_amount: Amount) void {
            try meta.wrap(allocator.resizeHolderBelow(Implementation, &array.impl, new_amount));
        }
        pub inline fn len(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.length(allocator) / @sizeOf(child);
        }
        pub inline fn avail(array: *const Array, comptime child: type, allocator: Allocator) u64 {
            return array.impl.available(allocator) / @sizeOf(child);
        }
        inline fn __at(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.add64(array.impl.start(allocator), amountToBytesOfType(offset, child));
        }
        inline fn __ad(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.add64(array.impl.next(), amountToBytesOfType(offset, child));
        }
        inline fn __len(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.sub64(len(array, child, allocator), amountToCountOfType(offset, child));
        }
        inline fn __rem(array: *const Array, comptime child: type, allocator: Allocator, offset: Amount) u64 {
            return mach.sub64(avail(array, child, allocator), amountToCountOfType(offset, child));
        }
        inline fn __prev(array: *const Array, comptime child: type, offset: Amount) u64 {
            return mach.sub64(array.impl.next(), amountToBytesOfType(offset, child));
        }
    };
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
        /// Attempt to render integer
        format: ?enum { bin, oct, dec, hex } = null,
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
};
const Reinterpret = struct {
    const validate_format_length: bool = false;
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
        if (comptime write_spec.integral.format) |kind| {
            if (src_type_info == .Int and dst_type == u8) {
                return memory.writeMany(switch (kind) {
                    .bin => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ub,
                    .oct => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.io
                    else
                        builtin.fmt.uo,
                    .dec => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.id
                    else
                        builtin.fmt.ud,
                    .hex => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ux,
                }(src_type, any).readAll());
            }
        }
        return memory.writeAny(write_spec, @as(dst_type, any));
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
        if (comptime write_spec.integral.format) |kind| {
            if (src_type_info == .Int and dst_type == u8) {
                return memory.writeMany(child, switch (kind) {
                    .bin => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ub,
                    .oct => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.io
                    else
                        builtin.fmt.uo,
                    .dec => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.id
                    else
                        builtin.fmt.ud,
                    .hex => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ux,
                }(src_type, any).readAll());
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
        if (builtin.is_correct and builtin.is_perf) {
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
        if (comptime write_spec.integral.format) |kind| {
            if (src_type_info == .Int and dst_type == u8) {
                return switch (kind) {
                    .bin => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ub,
                    .oct => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.io
                    else
                        builtin.fmt.uo,
                    .dec => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.id
                    else
                        builtin.fmt.ud,
                    .hex => if (src_type_info.Int.signedness == .signed)
                        builtin.fmt.ix
                    else
                        builtin.fmt.ux,
                }(src_type, any).len;
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
