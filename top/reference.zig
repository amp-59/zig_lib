const mach = @import("./mach.zig");
const algo = @import("./algo.zig");
const builtin = @import("./builtin.zig");
fn automatic_storage_address(impl: anytype) u64 {
    return @ptrToInt(impl) + @offsetOf(@TypeOf(impl.*), "auto");
}
pub fn pointerOne(comptime child: type, s_lb_addr: u64) *child {
    @setRuntimeSafety(false);
    return @intToPtr(*child, s_lb_addr);
}
pub fn pointerMany(comptime child: type, s_lb_addr: u64) [*]child {
    @setRuntimeSafety(false);
    return @intToPtr([*]child, s_lb_addr);
}
pub fn pointerManyWithSentinel(
    comptime child: type,
    s_lb_addr: u64,
    comptime sentinel: child,
) [*:sentinel]child {
    @setRuntimeSafety(false);
    return @intToPtr([*:sentinel]child, s_lb_addr);
}
pub fn pointerSlice(comptime child: type, s_lb_addr: u64, count: u64) []child {
    @setRuntimeSafety(false);
    return @intToPtr([*]child, s_lb_addr)[0..count];
}
pub fn pointerSliceWithSentinel(
    comptime child: type,
    s_lb_addr: u64,
    count: u64,
    comptime sentinel: child,
) [:sentinel]child {
    @setRuntimeSafety(false);
    return @intToPtr([*]child, s_lb_addr)[0..count :sentinel];
}
pub fn pointerCount(
    comptime child: type,
    s_lb_addr: u64,
    comptime count: u64,
) *[count]child {
    @setRuntimeSafety(false);
    return @intToPtr(*[count]child, s_lb_addr);
}
pub fn pointerCountWithSentinel(
    comptime child: type,
    s_lb_addr: u64,
    comptime count: u64,
    comptime sentinel: child,
) *[count:sentinel]child {
    @setRuntimeSafety(false);
    return @intToPtr(*[count:sentinel]child, s_lb_addr);
}
pub fn pointerOpaque(comptime child: type, any: *const anyopaque) *const child {
    @setRuntimeSafety(false);
    return @ptrCast(*const child, @alignCast(@max(1, @alignOf(child)), any));
}
pub fn copy(dst: u64, src: u64, bytes: u64, comptime high_alignment: u64) void {
    const unit_type: type = @Type(.{ .Int = .{
        .bits = 8 *% high_alignment,
        .signedness = .unsigned,
    } });
    var index: u64 = 0;
    @setRuntimeSafety(false);
    while (index != bytes / high_alignment) : (index +%= 1) {
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignment(spec);
            },
            .read_write_resize_auto => {
                return ReadWriteResizeAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignment(spec);
            },
            .read_write_stream_resize_auto => {
                return ReadWriteStreamResizeAutoStructuredAutoAlignment(spec);
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
        ReadWriteStreamResizeAutoStructuredAutoAlignment,
        ReadWriteResizeAutoStructuredAutoAlignment,
        ReadWriteStaticStructuredUnitAlignment,
        ReadWriteStaticStructuredLazyAlignment,
        ReadWriteStaticStructuredDisjunctAlignment,
        ReadWriteStreamResizeStaticStructuredUnitAlignment,
        ReadWriteStreamResizeStaticStructuredLazyAlignment,
        ReadWriteStreamResizeStaticStructuredDisjunctAlignment,
        ReadWriteResizeStaticStructuredUnitAlignment,
        ReadWriteResizeStaticStructuredLazyAlignment,
        ReadWriteResizeStaticStructuredDisjunctAlignment,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return (struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
    });
}
pub fn ReadWriteStreamAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return (struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr };
        }
    });
}
pub fn ReadWriteStreamResizeAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return (struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
    });
}
pub fn ReadWriteResizeAutoStructuredAutoAlignment(comptime spec: Specification0) type {
    return (struct {
        auto: [spec.count]spec.child align(low_alignment) = undefined,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
        }
    });
}
pub fn ReadWriteStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredUnitAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredLazyAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredDisjunctAlignment(comptime spec: Specification0) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_auto => {
                return ReadWriteAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_resize_auto => {
                return ReadWriteResizeAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_stream_auto => {
                return ReadWriteStreamAutoStructuredAutoAlignmentSentinel(spec);
            },
            .read_write_stream_resize_auto => {
                return ReadWriteStreamResizeAutoStructuredAutoAlignmentSentinel(spec);
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
        ReadWriteStreamResizeAutoStructuredAutoAlignmentSentinel,
        ReadWriteResizeAutoStructuredAutoAlignmentSentinel,
        ReadWriteStaticStructuredUnitAlignmentSentinel,
        ReadWriteStaticStructuredLazyAlignmentSentinel,
        ReadWriteStaticStructuredDisjunctAlignmentSentinel,
        ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinel,
        ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinel,
        ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinel,
        ReadWriteResizeStaticStructuredUnitAlignmentSentinel,
        ReadWriteResizeStaticStructuredLazyAlignmentSentinel,
        ReadWriteResizeStaticStructuredDisjunctAlignmentSentinel,
    };
};
pub fn ReadWriteAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        auto: [spec.count:sentinel.*]spec.child align(low_alignment) = undefined,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
    });
}
pub fn ReadWriteStreamAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        auto: [spec.count:sentinel.*]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub fn seek(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word +%= x_bytes;
        }
        pub fn tell(impl: *Implementation, x_bytes: u64) void {
            impl.ss_word -%= x_bytes;
        }
        pub inline fn convert(s: Convert4) Implementation {
            return .{ .ss_word = s.ss_addr };
        }
    });
}
pub fn ReadWriteStreamResizeAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        auto: [spec.count:sentinel.*]spec.child align(low_alignment) = undefined,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ss_word);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
    });
}
pub fn ReadWriteResizeAutoStructuredAutoAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        auto: [spec.count:sentinel.*]spec.child align(low_alignment) = undefined,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return automatic_storage_address(impl);
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), impl.ub_word);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub fn define(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word +%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
        pub fn undefine(impl: *Implementation, x_bytes: u64) void {
            impl.ub_word -%= x_bytes;
            pointerOne(spec.child, undefined_byte_address(impl)).* = sentinel.*;
        }
    });
}
pub fn ReadWriteStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredUnitAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredLazyAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredDisjunctAlignmentSentinel(comptime spec: Specification1) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
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
        ReadWriteStreamResizeStaticStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamResizeStaticStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamResizeStaticStructuredDisjunctAlignmentArenaIndex,
        ReadWriteResizeStaticStructuredUnitAlignmentArenaIndex,
        ReadWriteResizeStaticStructuredLazyAlignmentArenaIndex,
        ReadWriteResizeStaticStructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredUnitAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredLazyAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification2) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
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
        ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteResizeStaticStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteResizeStaticStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex,
    };
};
pub fn ReadWriteStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime allocated_byte_count: *const Static = &allocated_byte_count,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count());
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification3) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub inline fn aligned_byte_count() u64 {
            return mach.add64(writable_byte_count(), high_alignment);
        }
        pub inline fn writable_byte_count() u64 {
            return mach.mul64(spec.count, high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
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
        ReadWriteStreamResizeStaticUnstructuredUnitAlignment,
        ReadWriteStreamResizeStaticUnstructuredLazyAlignment,
        ReadWriteStreamResizeStaticUnstructuredDisjunctAlignment,
        ReadWriteResizeStaticUnstructuredUnitAlignment,
        ReadWriteResizeStaticUnstructuredLazyAlignment,
        ReadWriteResizeStaticUnstructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredUnitAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredLazyAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredDisjunctAlignment(comptime spec: Specification4) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStaticUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStaticUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStaticUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStaticUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStaticUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStaticUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
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
        ReadWriteStreamResizeStaticUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamResizeStaticUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamResizeStaticUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteResizeStaticUnstructuredUnitAlignmentArenaIndex,
        ReadWriteResizeStaticUnstructuredLazyAlignmentArenaIndex,
        ReadWriteResizeStaticUnstructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn construct(s: Construct1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
        pub inline fn translate(impl: *Implementation, t: Translate1) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.lb_addr };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert1) Implementation {
            return .{ .lb_word = s.lb_addr };
        }
    });
}
pub fn ReadWriteStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn construct(s: Construct3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
        pub inline fn translate(impl: *Implementation, t: Translate3) void {
            const s_impl: Implementation = impl.*;
            const t_impl: Implementation = .{ .lb_word = t.ab_addr | mach.sub64(t.ab_addr, t.lb_addr) };
            impl.* = t_impl;
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert3) Implementation {
            return .{ .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr) };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert13) Implementation {
            return .{
                .lb_word = s.lb_addr,
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteStreamResizeStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert15) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ss_word = s.ss_addr,
                .ub_word = s.ub_addr,
            };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub const allocated_byte_count: Static = aligned_byte_count;
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert9) Implementation {
            return .{ .lb_word = s.lb_addr, .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeStaticUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification5) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        comptime writable_byte_count: *const Static = &writable_byte_count,
        comptime aligned_byte_count: *const Static = &aligned_byte_count,
        const Implementation = @This();
        const Static = fn () callconv(.Inline) u64;
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.bytes;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.add64(aligned_byte_address(impl), writable_byte_count());
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return mach.add64(allocated_byte_address(impl), allocated_byte_count(impl));
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.add64(alignment(impl), aligned_byte_count());
        }
        pub const aligned_byte_count: Static = writable_byte_count;
        pub inline fn writable_byte_count() u64 {
            return high_alignment;
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert11) Implementation {
            return .{
                .lb_word = s.ab_addr | mach.sub64(s.ab_addr, s.lb_addr),
                .ub_word = s.ub_addr,
            };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStructuredDisjunctAlignment(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeStructuredUnitAlignment,
        ReadWriteStreamResizeStructuredLazyAlignment,
        ReadWriteStreamResizeStructuredDisjunctAlignment,
        ReadWriteStreamStructuredUnitAlignment,
        ReadWriteStreamStructuredLazyAlignment,
        ReadWriteStreamStructuredDisjunctAlignment,
        ReadWriteResizeStructuredUnitAlignment,
        ReadWriteResizeStructuredLazyAlignment,
        ReadWriteResizeStructuredDisjunctAlignment,
        ReadWriteStructuredUnitAlignment,
        ReadWriteStructuredLazyAlignment,
        ReadWriteStructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStreamResizeStructuredUnitAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredLazyAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredUnitAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredLazyAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredUnitAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredLazyAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStructuredUnitAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredLazyAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredDisjunctAlignment(comptime spec: Specification6) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStructuredDisjunctAlignmentSentinel(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStructuredLazyAlignmentSentinel(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStructuredDisjunctAlignmentSentinel(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeStructuredUnitAlignmentSentinel,
        ReadWriteStreamResizeStructuredLazyAlignmentSentinel,
        ReadWriteStreamResizeStructuredDisjunctAlignmentSentinel,
        ReadWriteStreamStructuredUnitAlignmentSentinel,
        ReadWriteStreamStructuredLazyAlignmentSentinel,
        ReadWriteStreamStructuredDisjunctAlignmentSentinel,
        ReadWriteResizeStructuredUnitAlignmentSentinel,
        ReadWriteResizeStructuredLazyAlignmentSentinel,
        ReadWriteResizeStructuredDisjunctAlignmentSentinel,
        ReadWriteStructuredUnitAlignmentSentinel,
        ReadWriteStructuredLazyAlignmentSentinel,
        ReadWriteStructuredDisjunctAlignmentSentinel,
    };
};
pub fn ReadWriteStreamResizeStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStructuredUnitAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredLazyAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredDisjunctAlignmentSentinel(comptime spec: Specification7) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStructuredDisjunctAlignmentArenaIndex(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamResizeStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamResizeStructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamStructuredUnitAlignmentArenaIndex,
        ReadWriteStreamStructuredLazyAlignmentArenaIndex,
        ReadWriteStreamStructuredDisjunctAlignmentArenaIndex,
        ReadWriteResizeStructuredUnitAlignmentArenaIndex,
        ReadWriteResizeStructuredLazyAlignmentArenaIndex,
        ReadWriteResizeStructuredDisjunctAlignmentArenaIndex,
        ReadWriteStructuredUnitAlignmentArenaIndex,
        ReadWriteStructuredLazyAlignmentArenaIndex,
        ReadWriteStructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStreamResizeStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStructuredUnitAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredLazyAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredDisjunctAlignmentArenaIndex(comptime spec: Specification8) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeStructuredDisjunctAlignmentSentinelArenaIndex(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeStructuredUnitAlignmentSentinelArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeStructuredLazyAlignmentSentinelArenaIndex(spec);
                    } else if (comptime spec.low_alignment > @sizeOf(spec.child)) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeStructuredDisjunctAlignmentSentinelArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamResizeStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamResizeStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStreamStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteResizeStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteResizeStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteResizeStructuredDisjunctAlignmentSentinelArenaIndex,
        ReadWriteStructuredUnitAlignmentSentinelArenaIndex,
        ReadWriteStructuredLazyAlignmentSentinelArenaIndex,
        ReadWriteStructuredDisjunctAlignmentSentinelArenaIndex,
    };
};
pub fn ReadWriteStreamResizeStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStructuredUnitAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), high_alignment);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredLazyAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteStructuredDisjunctAlignmentSentinelArenaIndex(comptime spec: Specification9) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(impl.up_word, high_alignment);
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl) + high_alignment);
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeUnstructuredDisjunctAlignment(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeUnstructuredLazyAlignment(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeUnstructuredDisjunctAlignment(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeUnstructuredUnitAlignment,
        ReadWriteStreamResizeUnstructuredLazyAlignment,
        ReadWriteStreamResizeUnstructuredDisjunctAlignment,
        ReadWriteStreamUnstructuredUnitAlignment,
        ReadWriteStreamUnstructuredLazyAlignment,
        ReadWriteStreamUnstructuredDisjunctAlignment,
        ReadWriteResizeUnstructuredUnitAlignment,
        ReadWriteResizeUnstructuredLazyAlignment,
        ReadWriteResizeUnstructuredDisjunctAlignment,
        ReadWriteUnstructuredUnitAlignment,
        ReadWriteUnstructuredLazyAlignment,
        ReadWriteUnstructuredDisjunctAlignment,
    };
};
pub fn ReadWriteStreamResizeUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteUnstructuredUnitAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteUnstructuredLazyAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteUnstructuredDisjunctAlignment(comptime spec: Specification10) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteResizeUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_resize");
                    } else { // @2b5-out
                        return ReadWriteResizeUnstructuredDisjunctAlignmentArenaIndex(spec);
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
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeUnstructuredUnitAlignmentArenaIndex(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b5-out
                        return ReadWriteStreamResizeUnstructuredLazyAlignmentArenaIndex(spec);
                    } else if (comptime spec.low_alignment > spec.high_alignment) { // @2b5-out
                        @compileError("no specification matching technique 'super_alignment'" ++
                            " and mode == read_write_stream_resize");
                    } else { // @2b5-out
                        return ReadWriteStreamResizeUnstructuredDisjunctAlignmentArenaIndex(spec);
                    }
                }
            },
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamResizeUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamResizeUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteStreamUnstructuredUnitAlignmentArenaIndex,
        ReadWriteStreamUnstructuredLazyAlignmentArenaIndex,
        ReadWriteStreamUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteResizeUnstructuredUnitAlignmentArenaIndex,
        ReadWriteResizeUnstructuredLazyAlignmentArenaIndex,
        ReadWriteResizeUnstructuredDisjunctAlignmentArenaIndex,
        ReadWriteUnstructuredUnitAlignmentArenaIndex,
        ReadWriteUnstructuredLazyAlignmentArenaIndex,
        ReadWriteUnstructuredDisjunctAlignmentArenaIndex,
    };
};
pub fn ReadWriteStreamResizeUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamResizeUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteStreamUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ss_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteResizeUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        ub_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unwritable_byte_address(impl), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
}
pub fn ReadWriteUnstructuredUnitAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub const aligned_byte_address: Value = allocated_byte_address;
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return allocated_byte_count(impl);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteUnstructuredLazyAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return impl.lb_word;
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.alignA64(allocated_byte_address(impl), low_alignment);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), allocated_byte_address(impl));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert17) Implementation {
            return .{ .lb_word = s.lb_addr, .up_word = s.up_addr };
        }
        pub inline fn resize(impl: *Implementation, t: Resize1) void {
            impl.up_word = t.up_addr;
        }
    });
}
pub fn ReadWriteUnstructuredDisjunctAlignmentArenaIndex(comptime spec: Specification11) type {
    return (struct {
        lb_word: u64,
        up_word: u64,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(impl: *const Implementation) u64 {
            return mach.sub64(aligned_byte_address(impl), alignment(impl));
        }
        pub inline fn aligned_byte_address(impl: *const Implementation) u64 {
            return mach.andn64(impl.lb_word, low_alignment - 1);
        }
        pub inline fn unwritable_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn unallocated_byte_address(impl: *const Implementation) u64 {
            return impl.up_word;
        }
        pub inline fn allocated_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), allocated_byte_address(impl));
        }
        pub inline fn aligned_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(unallocated_byte_address(impl), aligned_byte_address(impl));
        }
        pub inline fn writable_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(allocated_byte_count(impl), alignment(impl));
        }
        pub inline fn alignment(impl: *const Implementation) u64 {
            return mach.and64(impl.lb_word, low_alignment - 1);
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
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
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeParametricStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteResizeParametricStructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_resize");
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeParametricStructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamResizeParametricStructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_resize");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeParametricStructuredUnitAlignment,
        ReadWriteStreamResizeParametricStructuredLazyAlignment,
        ReadWriteResizeParametricStructuredUnitAlignment,
        ReadWriteResizeParametricStructuredLazyAlignment,
    };
};
pub fn ReadWriteStreamResizeParametricStructuredUnitAlignment(comptime spec: Specification12) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteStreamResizeParametricStructuredLazyAlignment(comptime spec: Specification12) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricStructuredUnitAlignment(comptime spec: Specification12) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricStructuredLazyAlignment(comptime spec: Specification12) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeParametricStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteResizeParametricStructuredLazyAlignmentSentinel(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_resize");
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeParametricStructuredUnitAlignmentSentinel(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamResizeParametricStructuredLazyAlignmentSentinel(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_resize");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeParametricStructuredUnitAlignmentSentinel,
        ReadWriteStreamResizeParametricStructuredLazyAlignmentSentinel,
        ReadWriteResizeParametricStructuredUnitAlignmentSentinel,
        ReadWriteResizeParametricStructuredLazyAlignmentSentinel,
    };
};
pub fn ReadWriteStreamResizeParametricStructuredUnitAlignmentSentinel(comptime spec: Specification13) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.unmapped_byte_address(), high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteStreamResizeParametricStructuredLazyAlignmentSentinel(comptime spec: Specification13) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.unmapped_byte_address(), high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricStructuredUnitAlignmentSentinel(comptime spec: Specification13) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.unmapped_byte_address(), high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricStructuredLazyAlignmentSentinel(comptime spec: Specification13) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const child: type = spec.child;
        pub const sentinel: *const spec.child = pointerOpaque(child, spec.sentinel);
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = @sizeOf(spec.child);
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub inline fn unwritable_byte_address(allocator: Allocator) u64 {
            return mach.sub64(allocator.unmapped_byte_address(), high_alignment);
        }
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
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
            .read_write_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteResizeParametricUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteResizeParametricUnstructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_resize");
                    }
                }
            },
            .read_write_stream_resize => {
                if (comptime techs.unit_alignment) { // @1b1
                    return ReadWriteStreamResizeParametricUnstructuredUnitAlignment(spec);
                } else { // @1b1
                    if (comptime techs.lazy_alignment) { // @2b2-out
                        return ReadWriteStreamResizeParametricUnstructuredLazyAlignment(spec);
                    } else { // @2b2-out
                        @compileError("no specification without technique 'lazy_alignment'" ++
                            " and mode == read_write_stream_resize");
                    }
                }
            },
            .read_write,
            .read_write_auto,
            .read_write_resize_auto,
            .read_write_stream,
            .read_write_stream_auto,
            .read_write_stream_resize_auto,
            => |invalid| {
                @compileError("no specification matching mode '" ++ @tagName(invalid) ++ "'");
            },
        }
        builtin.static.assert(@typeInfo(@TypeOf(techs)) == .Struct);
        return null;
    }
    pub const implementations = .{
        ReadWriteStreamResizeParametricUnstructuredUnitAlignment,
        ReadWriteStreamResizeParametricUnstructuredLazyAlignment,
        ReadWriteResizeParametricUnstructuredUnitAlignment,
        ReadWriteResizeParametricUnstructuredLazyAlignment,
    };
};
pub fn ReadWriteStreamResizeParametricUnstructuredUnitAlignment(comptime spec: Specification14) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteStreamResizeParametricUnstructuredLazyAlignment(comptime spec: Specification14) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ss_word: u64,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn unstreamed_byte_address(impl: *const Implementation) u64 {
            return impl.ss_word;
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn streamed_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unstreamed_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn unstreamed_byte_count(impl: *const Implementation) u64 {
            return mach.sub64(undefined_byte_address(impl), unstreamed_byte_address(impl));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricUnstructuredUnitAlignment(comptime spec: Specification14) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const unit_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub const aligned_byte_address = allocated_byte_address;
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
}
pub fn ReadWriteResizeParametricUnstructuredLazyAlignment(comptime spec: Specification14) type {
    return (struct {
        comptime allocated_byte_address: *const Slave = &allocated_byte_address,
        comptime aligned_byte_address: *const Slave = &aligned_byte_address,
        ub_word: u64,
        comptime unallocated_byte_address: *const Slave = &unallocated_byte_address,
        comptime unwritable_byte_address: *const Slave = &unwritable_byte_address,
        comptime allocated_byte_count: *const Slave = &allocated_byte_count,
        comptime writable_byte_count: *const Slave = &writable_byte_count,
        comptime aligned_byte_count: *const Slave = &aligned_byte_count,
        const Implementation = @This();
        const Value = fn (*const Implementation) callconv(.Inline) u64;
        const Vector = fn (*const Implementation, Allocator) callconv(.Inline) u64;
        const Slave = fn (Allocator) callconv(.Inline) u64;
        const Allocator = spec.Allocator;
        pub const low_alignment: u64 = spec.low_alignment;
        pub const high_alignment: u64 = spec.high_alignment;
        pub inline fn allocated_byte_address(allocator: Allocator) u64 {
            return allocator.unallocated_byte_address();
        }
        pub inline fn aligned_byte_address(allocator: Allocator) u64 {
            return mach.alignA64(allocator.unallocated_byte_address(), low_alignment);
        }
        pub inline fn undefined_byte_address(impl: *const Implementation) u64 {
            return impl.ub_word;
        }
        pub const unwritable_byte_address: Slave = unallocated_byte_address;
        pub inline fn unallocated_byte_address(allocator: Allocator) u64 {
            return allocator.unmapped_byte_address();
        }
        pub inline fn allocated_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), allocated_byte_address(allocator));
        }
        pub inline fn aligned_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unallocated_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn writable_byte_count(allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), aligned_byte_address(allocator));
        }
        pub inline fn undefined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(unwritable_byte_address(allocator), undefined_byte_address(impl));
        }
        pub inline fn defined_byte_count(impl: *const Implementation, allocator: Allocator) u64 {
            return mach.sub64(undefined_byte_address(impl), aligned_byte_address(allocator));
        }
        pub inline fn alignment(allocator: Allocator) u64 {
            return mach.sub64(aligned_byte_address(allocator), allocated_byte_address(allocator));
        }
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
            copy(t_impl.aligned_byte_address(), s_impl.aligned_byte_address(), s_impl.aligned_byte_count(), spec.low_alignment);
        }
        pub inline fn convert(s: Convert8) Implementation {
            return .{ .ub_word = s.ub_addr };
        }
    });
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
const Mode = enum(u3) {
    read_write,
    read_write_resize,
    read_write_auto,
    read_write_resize_auto,
    read_write_stream,
    read_write_stream_resize,
    read_write_stream_auto,
    read_write_stream_resize_auto,
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
pub const Construct: [10]type = .{
    Construct1,
    Construct2,
    Construct3,
    Construct5,
    Construct6,
    Construct7,
    Construct9,
    Construct11,
    Construct13,
    Construct15,
};
const Translate1 = Construct1;
const Translate2 = Construct2;
const Translate3 = Construct3;
const Translate5 = Construct5;
const Translate7 = Construct7;
const Translate9 = Construct9;
const Translate11 = Construct11;
const Translate13 = Construct13;
const Translate15 = Construct15;
pub const Translate: [9]type = .{
    Translate1,
    Translate2,
    Translate3,
    Translate5,
    Translate7,
    Translate9,
    Translate11,
    Translate13,
    Translate15,
};
const Resize1 = struct { up_addr: u64 };
pub const Resize: [1]type = .{
    Resize1,
};
const Reconstruct1 = struct { lb_addr: u64 };
const Reconstruct2 = struct { ab_addr: u64 };
const Reconstruct3 = struct { lb_addr: u64, ab_addr: u64 };
const Reconstruct9 = struct { up_addr: u64, lb_addr: u64 };
const Reconstruct11 = struct { up_addr: u64, lb_addr: u64, ab_addr: u64 };
pub const Reconstruct: [5]type = .{
    Reconstruct1,
    Reconstruct2,
    Reconstruct3,
    Reconstruct9,
    Reconstruct11,
};
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
pub const Convert: [16]type = .{
    Convert1,
    Convert3,
    Convert4,
    Convert8,
    Convert9,
    Convert11,
    Convert13,
    Convert15,
    Convert17,
    Convert19,
    Convert21,
    Convert23,
    Convert25,
    Convert27,
    Convert29,
    Convert31,
};
