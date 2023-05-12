const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

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
pub fn rotr(comptime T: type, value: T, rot_amt: u16) T {
    builtin.static.assert(@popCount(@typeInfo(T).Int.bits) == 1);
    builtin.static.assert(@typeInfo(T).Int.signedness == .unsigned);
    const S = builtin.ShiftAmount(T);
    if (T == u0) {
        return 0;
    }
    const shift_amt: S = @truncate(S, rot_amt % @typeInfo(T).Int.bits);
    return (value >> shift_amt) | (value << (1 +% ~shift_amt));
}
pub fn rotl(comptime T: type, value: T, rot_amt: u16) T {
    builtin.static.assert(@popCount(@typeInfo(T).Int.bits) == 1);
    builtin.static.assert(@typeInfo(T).Int.signedness == .unsigned);
    const S = builtin.ShiftAmount(T);
    if (T == u0) {
        return 0;
    }
    const shift_amt: S = @intCast(S, @mod(rot_amt, @typeInfo(T).Int.bits));
    return (value << shift_amt) | (value >> (1 +% ~shift_amt));
}
