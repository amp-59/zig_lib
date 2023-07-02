const mach = @import("../mach.zig");
const algo = @import("../algo.zig");
fn automatic_storage_address(impl: anytype) u64 {
    return @intFromPtr(impl) + @offsetOf(@TypeOf(impl.*), "auto");
}
pub fn pointerOne(comptime child: type, s_lb_addr: u64) *child {
    @setRuntimeSafety(false);
    return @as(*child, @ptrFromInt(s_lb_addr));
}
pub fn pointerMany(comptime child: type, s_lb_addr: u64) [*]child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(s_lb_addr));
}
pub fn pointerManyWithSentinel(
    comptime child: type,
    addr: u64,
    comptime sentinel: child,
) [*:sentinel]child {
    @setRuntimeSafety(false);
    return @as([*:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerSlice(comptime child: type, addr: u64, count: u64) []child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(addr))[0..count];
}
pub fn pointerSliceWithSentinel(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime sentinel: child,
) [:sentinel]child {
    @setRuntimeSafety(false);
    return @as([*]child, @ptrFromInt(addr))[0..count :sentinel];
}
pub fn pointerCount(
    comptime child: type,
    addr: u64,
    comptime count: u64,
) *[count]child {
    @setRuntimeSafety(false);
    return @ptrFromInt(addr);
}
pub fn pointerCountWithSentinel(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
) *[count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*[count:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerOpaque(comptime child: type, any: *const anyopaque) *const child {
    @setRuntimeSafety(false);
    return @as(*align(@max(1, @alignOf(child))) const child, @ptrCast(@alignCast(any)));
}
pub fn pointerOneAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) *align(alignment) child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerManyAligned(
    comptime child: type,
    addr: u64,
    comptime alignment: u64,
) [*]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerManyWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [*:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*:sentinel]align(alignment) child, @ptrFromInt(addr));
}
pub fn pointerSliceAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime alignment: u64,
) []align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count];
}
pub fn pointerSliceWithSentinelAligned(
    comptime child: type,
    addr: u64,
    count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) [:sentinel]align(alignment) child {
    @setRuntimeSafety(false);
    return @as([*]align(alignment) child, @ptrFromInt(addr))[0..count :sentinel];
}
pub fn pointerCountAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime alignment: u64,
) *align(alignment) [count]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count]child, @ptrFromInt(addr));
}
pub fn pointerCountWithSentinelAligned(
    comptime child: type,
    addr: u64,
    comptime count: u64,
    comptime sentinel: child,
    comptime alignment: u64,
) *align(alignment) [count:sentinel]child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) [count:sentinel]child, @ptrFromInt(addr));
}
pub fn pointerOpaqueAligned(
    comptime child: type,
    any: *const anyopaque,
    comptime alignment: u64,
) *const child {
    @setRuntimeSafety(false);
    return @as(*align(alignment) const child, @ptrCast(any));
}
pub fn copy(dst: u64, src: u64, bytes: u64, comptime high_alignment: u64) void {
    const unit_type: type = @Type(.{ .Int = .{
        .bits = 8 *% high_alignment,
        .signedness = .unsigned,
    } });
    var index: u64 = 0;
    @setRuntimeSafety(false);
    while (index != bytes / high_alignment) : (index +%= 1) {
        @as([*]unit_type, @ptrFromInt(dst))[index] = @as([*]const unit_type, @ptrFromInt(src))[index];
    }
}
