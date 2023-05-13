const mach = @import("./mach.zig");
const builtin = @import("./builtin.zig");

pub fn Absolute(comptime T: type) type {
    const bit_size_of: u16 = @bitSizeOf(T);
    if (bit_size_of == 0) {
        return comptime_int;
    }
    return @Type(.{ .Int = .{
        .bits = bit_size_of,
        .signedness = .unsigned,
    } });
}
pub inline fn absoluteDiff(x: anytype, y: anytype) Absolute(@TypeOf(x + y)) {
    return @max(x, y) - @min(x, y);
}
pub inline fn absoluteVal(i: anytype) Absolute(@TypeOf(i)) {
    const Int: type = @TypeOf(i);
    const Abs: type = Absolute(Int);
    if (Int == comptime_int and i < 0) {
        return -i;
    }
    if (Int != Abs) {
        if (i < 0) return @bitCast(Abs, -i);
    }
    return @intCast(Abs, i);
}
pub fn rotr(comptime T: type, value: T, rot_amt: anytype) T {
    if (@typeInfo(T) == .Vector) {
        const C = @typeInfo(T).Vector.child;
        if (C == u0) {
            return 0;
        }
        builtin.assert(@typeInfo(C).Int.signedness != .signed);
        const shift_amt = @intCast(builtin.ShiftAmount(C), @mod(rot_amt, @typeInfo(C).Int.bits));
        return (value >> @splat(@typeInfo(T).Vector.len, shift_amt)) |
            (value << @splat(@typeInfo(T).Vector.len, 1 +% ~shift_amt));
    } else {
        builtin.assert(@typeInfo(T).Int.signedness != .signed);
        if (T == u0) {
            return 0;
        }
        if (@popCount(@typeInfo(T).Int.bits) == 1) {
            const shift_amt = @intCast(builtin.ShiftAmount(T), @mod(rot_amt, @typeInfo(T).Int.bits));
            return value >> shift_amt | value << (1 +% ~shift_amt);
        } else {
            const shift_amt = @mod(rot_amt, @typeInfo(T).Int.bits);
            return shr(T, value, shift_amt) | shl(T, value, @typeInfo(T).Int.bits -% shift_amt);
        }
    }
}
pub fn rotl(comptime T: type, value: T, rot_amt: anytype) T {
    if (@typeInfo(T) == .Vector) {
        const C = @typeInfo(T).Vector.child;
        if (C == u0) {
            return 0;
        }
        builtin.assert(@typeInfo(C).Int.signedness != .signed);
        const shift_amt = @intCast(builtin.ShiftAmount(C), @mod(rot_amt, @typeInfo(C).Int.bits));
        return (value << @splat(@typeInfo(T).Vector.len, shift_amt)) |
            (value >> @splat(@typeInfo(T).Vector.len, 1 +% ~shift_amt));
    } else {
        builtin.assert(@typeInfo(T).Int.signedness != .signed);
        if (T == u0) {
            return 0;
        }
        if (@popCount(@typeInfo(T).Int.bits) == 1) {
            const shift_amt = @intCast(builtin.ShiftAmount(T), @mod(rot_amt, @typeInfo(T).Int.bits));
            return value << shift_amt | value >> 1 +% ~shift_amt;
        } else {
            const shift_amt = @mod(rot_amt, @typeInfo(T).Int.bits);
            return shl(T, value, shift_amt) | shr(T, value, @typeInfo(T).Int.bits -% shift_amt);
        }
    }
}
pub fn shl(comptime T: type, value: T, shift_amt: anytype) T {
    const ShiftAmount = @TypeOf(shift_amt);
    const abs_shift_amt: Absolute(ShiftAmount) = absoluteVal(shift_amt);
    const casted_shift_amt = blk: {
        if (@typeInfo(T) == .Vector) {
            const C = @typeInfo(T).Vector.child;
            const len: usize = @typeInfo(T).Vector.len;
            if (abs_shift_amt >= @typeInfo(C).Int.bits) {
                return @splat(len, @as(C, 0));
            }
            break :blk @splat(len, @intCast(builtin.ShiftAmount(C), abs_shift_amt));
        } else {
            if (abs_shift_amt >= @typeInfo(T).Int.bits) {
                return 0;
            }
            break :blk @intCast(builtin.ShiftAmount(T), abs_shift_amt);
        }
    };
    if (ShiftAmount == comptime_int or
        @typeInfo(ShiftAmount).Int.signedness == .signed)
    {
        if (shift_amt < 0) {
            return value >> casted_shift_amt;
        }
    }
    return value << casted_shift_amt;
}
pub fn shr(comptime T: type, a: T, shift_amt: anytype) T {
    const ShiftAmount = @TypeOf(shift_amt);
    const abs_shift_amt: Absolute(ShiftAmount) = absoluteVal(shift_amt);
    const casted_shift_amt = blk: {
        if (@typeInfo(T) == .Vector) {
            const C = @typeInfo(T).Vector.child;
            const len = @typeInfo(T).Vector.len;
            if (abs_shift_amt >= @typeInfo(C).Int.bits) {
                return @splat(len, @as(C, 0));
            }
            break :blk @splat(len, @intCast(builtin.ShiftAmount(C), abs_shift_amt));
        } else {
            if (abs_shift_amt >= @typeInfo(T).Int.bits) {
                return 0;
            }
            break :blk @intCast(builtin.ShiftAmount(T), abs_shift_amt);
        }
    };
    if (ShiftAmount == comptime_int or
        @typeInfo(ShiftAmount).Int.signedness == .signed)
    {
        if (shift_amt < 0) {
            return a << casted_shift_amt;
        }
    }
    return a >> casted_shift_amt;
}
