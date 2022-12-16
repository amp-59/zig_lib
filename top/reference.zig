const mach = @import("./mach.zig");
const algo = @import("./algo.zig");
const builtin = @import("./builtin.zig");
fn automatic_storage_address(impl: anytype) u64 {
    return @ptrToInt(impl) + @offsetOf(@TypeOf(impl.*), "auto");
}
pub fn pointerOne(comptime child: type, s_lb_addr: u64) *child {
    return builtin.intToPtr(*child, s_lb_addr);
}
pub fn pointerMany(comptime child: type, s_lb_addr: u64, count: u64) []child {
    return builtin.intToPtr([*]child, s_lb_addr)[0..count];
}
pub fn pointerManyWithSentinel(comptime child: type, s_lb_addr: u64, count: u64, comptime sentinel: child) [:sentinel]child {
    return builtin.intToPtr([*]child, s_lb_addr)[0..count :sentinel];
}
pub fn pointerCount(comptime child: type, s_lb_addr: u64, comptime count: u64) *[count]child {
    return builtin.intToPtr(*[count]child, s_lb_addr)[0..count];
}
pub fn pointerCountWithSentinel(comptime child: type, s_lb_addr: u64, comptime count: u64, comptime sentinel: child) *[count:sentinel]child {
    return builtin.intToPtr(*[count]child, s_lb_addr)[0..count :sentinel];
}
pub fn pointerOneWithSentinel(comptime child: type, s_lb_addr: u64, comptime sentinel: child) [*:sentinel]child {
    return builtin.intToPtr([*:sentinel]child, s_lb_addr);
}
pub fn pointerOpaque(comptime child: type, any: *const anyopaque) *const child {
    return @ptrCast(*const child, @alignCast(@alignOf(child), any));
}
pub fn copy(dst: u64, src: u64, bytes: u64, comptime high_alignment: u64) void {
    const unit_type: type = @Type(.{ .Int = .{
        .bits = 8 * high_alignment,
        .signedness = .unsigned,
    } });
    var index: u64 = 0;
    while (index != bytes / high_alignment) : (index += 1) {
        @intToPtr([*]unit_type, dst)[index] = @intToPtr([*]const unit_type, src)[index];
    }
}
pub const Specification0 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignment(spec);
            },
            .read_write_push_pop_auto => {
                return ReadWritePushPopAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_push_pop_auto => {
                return ReadWriteStreamPushPopAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream => |invalid| {
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
        ReadWriteStaticStructuredUnitAlignment,
        ReadWriteStaticStructuredLazyAlignment,
        ReadWriteStaticStructuredDisjunctAlignment,
        ReadWriteStreamPushPopStaticStructuredUnitAlignment,
        ReadWriteStreamPushPopStaticStructuredLazyAlignment,
        ReadWriteStreamPushPopStaticStructuredDisjunctAlignment,
        ReadWritePushPopStaticStructuredUnitAlignment,
        ReadWritePushPopStaticStructuredLazyAlignment,
        ReadWritePushPopStaticStructuredDisjunctAlignment,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const capacity: Static = writable_byte_count;
    };
}
pub fn ReadWriteStreamAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
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
            return mach.mul64(spec.count, high_alignment);
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
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr };
        }
    };
}
pub fn ReadWriteStreamPushPopAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
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
            return mach.mul64(spec.count, high_alignment);
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
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = 0 };
        }
    };
}
pub fn ReadWritePushPopAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
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
            return mach.mul64(spec.count, high_alignment);
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
    };
}
pub fn ReadWriteStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
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
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_push_pop_auto => {
                return ReadWritePushPopAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_push_pop_auto => {
                return ReadWriteStreamPushPopAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream => |invalid| {
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
        ReadWriteStaticStructuredUnitAlignmentSentinel,
        ReadWriteStaticStructuredLazyAlignmentSentinel,
        ReadWriteStaticStructuredDisjunctAlignmentSentinel,
        ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinel,
        ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinel,
        ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinel,
        ReadWritePushPopStaticStructuredUnitAlignmentSentinel,
        ReadWritePushPopStaticStructuredLazyAlignmentSentinel,
        ReadWritePushPopStaticStructuredDisjunctAlignmentSentinel,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [spec.count + 1]spec.child align(low_alignment) = undefined,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const capacity: Static = writable_byte_count;
    };
}
pub fn ReadWriteStreamAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [spec.count + 1]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
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
            return mach.mul64(spec.count, high_alignment);
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
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr };
        }
    };
}
pub fn ReadWriteStreamPushPopAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [spec.count + 1]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
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
            return mach.mul64(spec.count, high_alignment);
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
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = 0 };
        }
    };
}
pub fn ReadWritePushPopAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        auto: [spec.count + 1]spec.child align(low_alignment) = undefined,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
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
            return mach.mul64(spec.count, high_alignment);
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
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
    };
}
pub fn ReadWriteStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub const Specification2 = struct {
    child: type,
    count: u64,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStaticStructuredUnitAlignmentArenaIndex,
        ReadWriteStaticStructuredLazyAlignmentArenaIndex,
        ReadWriteStaticStructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentArenaIndex,
        ReadWritePushPopStaticStructuredUnitAlignmentArenaIndex,
        ReadWritePushPopStaticStructuredLazyAlignmentArenaIndex,
        ReadWritePushPopStaticStructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
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
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub const Specification3 = struct {
    child: type,
    sentinel: *const anyopaque,
    count: u64,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStaticStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStaticStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStaticStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWritePushPopStaticStructuredUnitAlignmentSentinelArenaIndex,
        ReadWritePushPopStaticStructuredLazyAlignmentSentinelArenaIndex,
        ReadWritePushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex,
    };
};
pub fn ReadWriteStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime bytes: *const Static = &allocated_byte_count,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
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
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        comptime capacity: *const Static = &writable_byte_count,
        comptime utility: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Static = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub const Specification4 = struct {
    bytes: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStaticUnstructuredUnitAlignment,
        ReadWriteStaticUnstructuredLazyAlignment,
        ReadWriteStaticUnstructuredDisjunctAlignment,
        ReadWriteStreamPushPopStaticUnstructuredUnitAlignment,
        ReadWriteStreamPushPopStaticUnstructuredLazyAlignment,
        ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignment,
        ReadWritePushPopStaticUnstructuredUnitAlignment,
        ReadWritePushPopStaticUnstructuredLazyAlignment,
        ReadWritePushPopStaticUnstructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
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
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub const Specification5 = struct {
    bytes: u64,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStaticUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStaticUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStaticUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStaticUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStaticUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStaticUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStaticUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStaticUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStaticUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStaticUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStaticUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignmentArenaIndex,
        ReadWritePushPopStaticUnstructuredUnitAlignmentArenaIndex,
        ReadWritePushPopStaticUnstructuredLazyAlignmentArenaIndex,
        ReadWritePushPopStaticUnstructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Static = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    };
}
pub fn ReadWriteStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
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
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate5) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWriteStreamPushPopStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct7) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate7) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        const allocated_byte_count: Static = aligned_byte_count;
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        const Implementation = @This();
        const Static: type = fn () callconv(.Inline) u64;
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count(impl));
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        const aligned_byte_count: Static = writable_byte_count;
        inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Static = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    };
}
pub const Specification6 = struct {
    child: type,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopStructuredUnitAlignment,
        ReadWriteStreamPushPopStructuredLazyAlignment,
        ReadWriteStreamPushPopStructuredDisjunctAlignment,
        ReadWriteStreamStructuredUnitAlignment,
        ReadWriteStreamStructuredLazyAlignment,
        ReadWriteStreamStructuredDisjunctAlignment,
        ReadWritePushPopStructuredUnitAlignment,
        ReadWritePushPopStructuredLazyAlignment,
        ReadWritePushPopStructuredDisjunctAlignment,
        ReadWriteStructuredUnitAlignment,
        ReadWriteStructuredLazyAlignment,
        ReadWriteStructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStreamPushPopStructuredUnitAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredLazyAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredUnitAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredLazyAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredUnitAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredLazyAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredUnitAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredLazyAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification7 = struct {
    child: type,
    sentinel: *const anyopaque,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopStructuredUnitAlignmentSentinel,
        ReadWriteStreamPushPopStructuredLazyAlignmentSentinel,
        ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinel,
        ReadWriteStreamStructuredUnitAlignmentSentinel,
        ReadWriteStreamStructuredLazyAlignmentSentinel,
        ReadWriteStreamStructuredDisjunctAlignmentSentinel,
        ReadWritePushPopStructuredUnitAlignmentSentinel,
        ReadWritePushPopStructuredLazyAlignmentSentinel,
        ReadWritePushPopStructuredDisjunctAlignmentSentinel,
        ReadWriteStructuredUnitAlignmentSentinel,
        ReadWriteStructuredLazyAlignmentSentinel,
        ReadWriteStructuredDisjunctAlignmentSentinel,
    };
};
pub fn ReadWriteStreamPushPopStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification8 = struct {
    child: type,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamPushPopStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamPushPopStructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamStructuredDisjunctAlignmentArenaIndex,
        ReadWritePushPopStructuredUnitAlignmentArenaIndex,
        ReadWritePushPopStructuredLazyAlignmentArenaIndex,
        ReadWritePushPopStructuredDisjunctAlignmentArenaIndex,
        ReadWriteStructuredUnitAlignmentArenaIndex,
        ReadWriteStructuredLazyAlignmentArenaIndex,
        ReadWriteStructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStreamPushPopStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification9 = struct {
    child: type,
    sentinel: *const anyopaque,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamPushPopStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWritePushPopStructuredUnitAlignmentSentinelArenaIndex,
        ReadWritePushPopStructuredLazyAlignmentSentinelArenaIndex,
        ReadWritePushPopStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStructuredDisjunctAlignmentSentinelArenaIndex,
    };
};
pub fn ReadWriteStreamPushPopStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification10 = struct {
    high_alignment: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopUnstructuredUnitAlignment,
        ReadWriteStreamPushPopUnstructuredLazyAlignment,
        ReadWriteStreamPushPopUnstructuredDisjunctAlignment,
        ReadWriteStreamUnstructuredUnitAlignment,
        ReadWriteStreamUnstructuredLazyAlignment,
        ReadWriteStreamUnstructuredDisjunctAlignment,
        ReadWritePushPopUnstructuredUnitAlignment,
        ReadWritePushPopUnstructuredLazyAlignment,
        ReadWritePushPopUnstructuredDisjunctAlignment,
        ReadWriteUnstructuredUnitAlignment,
        ReadWriteUnstructuredLazyAlignment,
        ReadWriteUnstructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStreamPushPopUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification11 = struct {
    high_alignment: u64,
    low_alignment: u64,
    arena_index: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write");
                    } else { // @2b5-out
                        return ReadWriteUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWritePushPopUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_push_pop");
                    } else { // @2b5-out
                        return ReadWritePushPopUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream");
                    } else { // @2b5-out
                        return ReadWriteStreamUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamPushPopUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    } else { // @2b5-out
                        return ReadWriteStreamPushPopUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamPushPopUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamPushPopUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamUnstructuredDisjunctAlignmentArenaIndex,
        ReadWritePushPopUnstructuredUnitAlignmentArenaIndex,
        ReadWritePushPopUnstructuredLazyAlignmentArenaIndex,
        ReadWritePushPopUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteUnstructuredUnitAlignmentArenaIndex,
        ReadWriteUnstructuredLazyAlignmentArenaIndex,
        ReadWriteUnstructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStreamPushPopUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert29) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamPushPopUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
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
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert31) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate13) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert21) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteStreamUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate15) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ss_word = t.ss_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert23) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct9) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.lb_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert25) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWritePushPopUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub const length: Value = defined_byte_count;
        pub const available: Value = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ab_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .ub_word = t.ab_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert27) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        const aligned_byte_address: Value = allocated_byte_address;
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct9) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate9) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.lb_addr,
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub fn ReadWriteUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub const low: Value = allocated_byte_address;
        pub const start: Value = aligned_byte_address;
        pub const finish: Value = unwritable_byte_address;
        pub const high: Value = unallocated_byte_address;
        pub const bytes: Value = allocated_byte_count;
        pub const utility: Value = aligned_byte_count;
        pub const capacity: Value = writable_byte_count;
        pub inline fn construct(s: Construct11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn translate(impl: *Implementation, t: Translate11) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{
                .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr),
                .up_word = t.up_addr,
            };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert19) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .up_word = s.up_addr,
            };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    };
}
pub const Specification12 = struct {
    Allocator: type,
    child: type,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopParametricStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWritePushPopParametricStructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_push_pop");
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopParametricStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamPushPopParametricStructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopParametricStructuredUnitAlignment,
        ReadWriteStreamPushPopParametricStructuredLazyAlignment,
        ReadWritePushPopParametricStructuredUnitAlignment,
        ReadWritePushPopParametricStructuredLazyAlignment,
    };
};
pub fn ReadWriteStreamPushPopParametricStructuredUnitAlignment(comptime spec: Specification12) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWriteStreamPushPopParametricStructuredLazyAlignment(comptime spec: Specification12) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
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
        pub inline fn construct(s: Construct6) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricStructuredUnitAlignment(comptime spec: Specification12) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricStructuredLazyAlignment(comptime spec: Specification12) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct2) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub const Specification13 = struct {
    Allocator: type,
    child: type,
    sentinel: *const anyopaque,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopParametricStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWritePushPopParametricStructuredLazyAlignmentSentinel(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_push_pop");
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopParametricStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamPushPopParametricStructuredLazyAlignmentSentinel(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopParametricStructuredUnitAlignmentSentinel,
        ReadWriteStreamPushPopParametricStructuredLazyAlignmentSentinel,
        ReadWritePushPopParametricStructuredUnitAlignmentSentinel,
        ReadWritePushPopParametricStructuredLazyAlignmentSentinel,
    };
};
pub fn ReadWriteStreamPushPopParametricStructuredUnitAlignmentSentinel(comptime spec: Specification13) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.finish(), high_alignment);
        }
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct5) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWriteStreamPushPopParametricStructuredLazyAlignmentSentinel(comptime spec: Specification13) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.finish(), high_alignment);
        }
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct6) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricStructuredUnitAlignmentSentinel(comptime spec: Specification13) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.finish(), high_alignment);
        }
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricStructuredLazyAlignmentSentinel(comptime spec: Specification13) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const sentinel: *const spec.child = pointerOpaque(spec.child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.finish(), high_alignment);
        }
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub inline fn construct(s: Construct2) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub const Specification14 = struct {
    Allocator: type,
    high_alignment: u64,
    low_alignment: u64,
    const Specification = @This();
    pub fn deduce(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) type {
        if (spec.matchImplementation(mode, techs)) |match| {
            return match;
        } else {
            @compileError("no matching specification");
        }
    }
    pub fn matchImplementation(comptime spec: Specification, comptime mode: Mode, comptime techs: anytype) ?type {
        switch (mode) {
            .read_write_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWritePushPopParametricUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWritePushPopParametricUnstructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_push_pop");
                    }
                }
            },
            .read_write_stream_push_pop => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamPushPopParametricUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamPushPopParametricUnstructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_push_pop");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_push_pop_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_push_pop_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamPushPopParametricUnstructuredUnitAlignment,
        ReadWriteStreamPushPopParametricUnstructuredLazyAlignment,
        ReadWritePushPopParametricUnstructuredUnitAlignment,
        ReadWritePushPopParametricUnstructuredLazyAlignment,
    };
};
pub fn ReadWriteStreamPushPopParametricUnstructuredUnitAlignment(comptime spec: Specification14) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
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
        pub inline fn construct(s: Construct5) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWriteStreamPushPopParametricUnstructuredLazyAlignment(comptime spec: Specification14) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const position: Value = unstreamed_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const behind: Value = streamed_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const ahead: Value = unstreamed_byte_count;
        pub const available: Vector = undefined_byte_count;
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
        pub inline fn construct(s: Construct6) Implementation {
            return .{ .ss_word = s.ss_addr, .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricUnstructuredUnitAlignment(comptime spec: Specification14) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        const aligned_byte_address = allocated_byte_address;
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .ub_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub fn ReadWritePushPopParametricUnstructuredLazyAlignment(comptime spec: Specification14) type {
    return struct {
        comptime low: *const Slave = &allocated_byte_address,
        comptime start: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime high: *const Slave = &unallocated_byte_address,
        comptime finish: *const Slave = &unwritable_byte_address,
        comptime bytes: *const Slave = &allocated_byte_count,
        comptime capacity: *const Slave = &writable_byte_count,
        comptime utility: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value: type = fn (*const Implementation) callconv(.Inline) u64;
        const Vector: type = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave: type = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.next();
        }
        inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.next(), low_alignment);
        }
        inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        const unwritable_byte_address: Slave = unallocated_byte_address;
        inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.finish();
        }
        inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub const low: Slave = allocated_byte_address;
        pub const start: Slave = aligned_byte_address;
        pub const next: Value = undefined_byte_address;
        pub const finish: Slave = unwritable_byte_address;
        pub const high: Slave = unallocated_byte_address;
        pub const bytes: Slave = allocated_byte_count;
        pub const utility: Slave = aligned_byte_count;
        pub const capacity: Slave = writable_byte_count;
        pub const length: Vector = defined_byte_count;
        pub const available: Vector = undefined_byte_count;
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
        pub inline fn construct(s: Construct2) Implementation {
            return .{ .ub_word = s.ab_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate2) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .ub_word = t.ab_addr };
            impl.* = t_impl;
            copy(t_impl.start(), s_impl.start(), s_impl.utility(), high_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    };
}
pub const specifications: [15]type = .{
    Specification0,
    Specification1,
    Specification2,
    Specification3,
    Specification4,
    Specification5,
    Specification6,
    Specification7,
    Specification8,
    Specification9,
    Specification10,
    Specification11,
    Specification12,
    Specification13,
    Specification14,
};
const Mode = enum {
    read_write,
    read_write_push_pop,
    read_write_auto,
    read_write_push_pop_auto,
    read_write_stream,
    read_write_stream_push_pop,
    read_write_stream_auto,
    read_write_stream_push_pop_auto,
};
const Construct1 = struct { lb_addr: u64 };
const Construct2 = struct { ab_addr: u64 };
const Construct3 = struct { lb_addr: u64, ab_addr: u64 };
const Construct5 = struct { lb_addr: u64, ss_addr: u64 };
const Construct6 = struct { ab_addr: u64, ss_addr: u64 };
const Construct7 = struct { lb_addr: u64, ab_addr: u64, ss_addr: u64 };
const Construct9 = struct { lb_addr: u64, up_addr: u64 };
const Construct11 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64 };
const Construct13 = struct { lb_addr: u64, up_addr: u64, ss_addr: u64 };
const Construct15 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64, ss_addr: u64 };
const Translate1 = Construct1;
const Translate2 = Construct2;
const Translate3 = Construct3;
const Translate5 = Construct5;
const Translate7 = Construct7;
const Translate9 = Construct9;
const Translate11 = Construct11;
const Translate13 = Construct13;
const Translate15 = Construct15;
const Resize1 = struct { up_addr: u64 };
const Reconstruct1 = struct { lb_addr: u64 };
const Reconstruct2 = struct { ab_addr: u64 };
const Reconstruct3 = struct { lb_addr: u64, ab_addr: u64 };
const Reconstruct9 = struct { up_addr: u64, lb_addr: u64 };
const Reconstruct11 = struct { up_addr: u64, lb_addr: u64, ab_addr: u64 };
const Convert1 = struct { lb_addr: u64 };
const Convert3 = struct { lb_addr: u64, ab_addr: u64 };
const Convert4 = struct { ss_addr: u64 };
const Convert8 = struct { ub_addr: u64 };
const Convert9 = struct { lb_addr: u64, ub_addr: u64 };
const Convert11 = struct { lb_addr: u64, ab_addr: u64, ub_addr: u64 };
const Convert13 = struct { lb_addr: u64, ss_addr: u64, ub_addr: u64 };
const Convert15 = struct { lb_addr: u64, ab_addr: u64, ss_addr: u64, ub_addr: u64 };
const Convert17 = struct { lb_addr: u64, up_addr: u64 };
const Convert19 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64 };
const Convert21 = struct { lb_addr: u64, up_addr: u64, ss_addr: u64 };
const Convert23 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64, ss_addr: u64 };
const Convert25 = struct { lb_addr: u64, up_addr: u64, ub_addr: u64 };
const Convert27 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64, ub_addr: u64 };
const Convert29 = struct { lb_addr: u64, up_addr: u64, ss_addr: u64, ub_addr: u64 };
const Convert31 = struct { lb_addr: u64, up_addr: u64, ab_addr: u64, ss_addr: u64, ub_addr: u64 };
