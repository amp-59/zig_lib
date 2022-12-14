pub inline fn absoluteDifference(x: anytype, y: anytype) @TypeOf(x + y) {
    return @max(x, y) - @min(x, y);
}
fn Absolute(comptime T: type) type {
    return @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
}
pub inline fn absoluteValue(i: anytype) Absolute(@TypeOf(i)) {
    const Int: type = @TypeOf(i);
    const Abs: type = Absolute(Int);
    if (Int != Abs and i < 0) {
        return @bitCast(Abs, -i);
    } else {
        return @bitCast(Abs, i);
    }
}
