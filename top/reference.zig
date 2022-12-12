const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const algo = @import("./algo.zig");
const builtin = @import("./builtin.zig");
pub const Specification0 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: mem.AbstractSpec.Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: mem.AbstractSpec.Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignment(spec);
            },
            .read_write_push_pop_auto => {
                return ReadWritePushPopAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_push_pop_auto => {
                return ReadWriteStreamPushPopAutoStructuredAutoAlignment(spec);
            },
            .read_write,
            .read_write_push_pop,
            .read_write_stream,
            .read_write_stream_push_pop,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteAutoStructuredAutoAlignment,
        ReadWriteStreamAutoStructuredAutoAlignment,
        ReadWriteStreamPushPopAutoStructuredAutoAlignment,
        ReadWritePushPopAutoStructuredAutoAlignment,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [count]child align(low_alignment) = undefined,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWriteStreamAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [count]child align(low_alignment) = undefined,
        ss_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const behind: Value = streamed_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{
                .ss_word = s.ss_addr,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [count]child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{
                .ss_word = s.ss_addr,
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWritePushPopAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [count]child align(low_alignment) = undefined,
        ub_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub const Specification1 = struct {
    child: type,
    sentinel: *const anyopaque,
    count: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: mem.AbstractSpec.Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: mem.AbstractSpec.Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_push_pop_auto => {
                return ReadWritePushPopAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_push_pop_auto => {
                return ReadWriteStreamPushPopAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write,
            .read_write_push_pop,
            .read_write_stream,
            .read_write_stream_push_pop,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteAutoStructuredAutoAlignmentSentinel,
        ReadWriteStreamAutoStructuredAutoAlignmentSentinel,
        ReadWriteStreamPushPopAutoStructuredAutoAlignmentSentinel,
        ReadWritePushPopAutoStructuredAutoAlignmentSentinel,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [count + 1]child align(low_alignment) = undefined,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const sentinel: *const child = @ptrCast(*const child, @alignCast(@alignOf(child), spec.sentinel));
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWriteStreamAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [count + 1]child align(low_alignment) = undefined,
        ss_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const sentinel: *const child = @ptrCast(*const child, @alignCast(@alignOf(child), spec.sentinel));
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const behind: Value = streamed_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct() Implementation {
            return .{
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{
                .ss_word = s.ss_addr,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [count + 1]child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const sentinel: *const child = @ptrCast(*const child, @alignCast(@alignOf(child), spec.sentinel));
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            mem.pointerOne(child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            mem.pointerOne(child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{
                .ss_word = s.ss_addr,
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub fn ReadWritePushPopAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [count + 1]child align(low_alignment) = undefined,
        ub_word: u64,
        comptime bytes: Static = allocated_byte_count,
        comptime capacity: Static = writable_byte_count,
        comptime utility: Static = aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const count: u64 = spec.count;
        pub const child: type = spec.child;
        pub const sentinel: *const child = @ptrCast(*const child, @alignCast(@alignOf(child), spec.sentinel));
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return @ptrToInt(impl) + @offsetOf(Implementation, "auto");
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return allocated_byte_address(impl) + impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        const allocated_byte_count: Static = aligned_byte_count;
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            mem.pointerOne(child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            mem.pointerOne(child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
        pub inline fn convert() Implementation {
            return .{
                .ub_word = 0,
                .utility = aligned_byte_count,
                .capacity = writable_byte_count,
                .bytes = allocated_byte_count,
            };
        }
    };
}
pub const specifications: [2]type = .{
    Specification0,
    Specification1,
};
pub const Convert4 = struct {
    ss_addr: u64,
};
