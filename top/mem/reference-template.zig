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
