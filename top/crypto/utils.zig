const sys = @import("../sys.zig");
const math = @import("../math.zig");
const builtin = @import("../builtin.zig");
const random = @import("./random.zig");
/// Compares two arrays in constant time (for a given length) and returns whether they are equal.
/// This function was designed to compare short cryptographic secrets (MACs, signatures).
/// For all other applications, use mem.eql() instead.
pub fn timingSafeEql(comptime T: type, a: T, b: T) bool {
    switch (@typeInfo(T)) {
        .Array => |info| {
            const C = info.child;
            if (@typeInfo(C) != .Int) {
                @compileError("Elements to be compared must be integers");
            }
            var acc = @as(C, 0);
            for (a, 0..) |x, idx| {
                acc |= x ^ b[idx];
            }
            const s = @typeInfo(C).Int.bits;
            const Cu = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = s } });
            const Cext = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = s +% 1 } });
            return @bitCast(bool, @truncate(u1, (@as(Cext, @bitCast(Cu, acc)) -% 1) >> s));
        },
        .Vector => |info| {
            const C = info.child;
            if (@typeInfo(C) != .Int) {
                @compileError("Elements to be compared must be integers");
            }
            const acc = @reduce(.Or, a ^ b);
            const s = @typeInfo(C).Int.bits;
            const Cu = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = s } });
            const Cext = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = s +% 1 } });
            return @bitCast(bool, @truncate(u1, (@as(Cext, @bitCast(Cu, acc)) -% 1) >> s));
        },
        else => {
            @compileError("Only arrays and vectors can be compared");
        },
    }
}
/// Compare two integers serialized as arrays of the same size, in constant time.
/// Returns .lt if a<b, .gt if a>b and .eq if a=b
pub fn timingSafeCompare(comptime T: type, a: []const T, b: []const T, endian: builtin.Endian) math.Order {
    builtin.assert(a.len == b.len);
    const bits = switch (@typeInfo(T)) {
        .Int => |cinfo| if (cinfo.signedness != .unsigned) @compileError("Elements to be compared must be unsigned") else cinfo.bits,
        else => @compileError("Elements to be compared must be integers"),
    };
    const Cext = @Type(.{ .Int = .{ .signedness = .unsigned, .bits = bits +% 1 } });
    var gt: T = 0;
    var eq: T = 1;
    if (endian == .Little) {
        var idx = a.len;
        while (idx != 0) {
            idx -%= 1;
            const x1 = a[idx];
            const x2 = b[idx];
            gt |= @truncate(T, (@as(Cext, x2) -% @as(Cext, x1)) >> bits) & eq;
            eq &= @truncate(T, (@as(Cext, (x2 ^ x1)) -% 1) >> bits);
        }
    } else {
        for (a, 0..) |x1, idx| {
            const x2 = b[idx];
            gt |= @truncate(T, (@as(Cext, x2) -% @as(Cext, x1)) >> bits) & eq;
            eq &= @truncate(T, (@as(Cext, (x2 ^ x1)) -% 1) >> bits);
        }
    }
    if (gt != 0) {
        return math.Order.gt;
    } else if (eq != 0) {
        return math.Order.eq;
    }
    return math.Order.lt;
}
/// Add two integers serialized as arrays of the same size, in constant time.
/// The result is stored into `result`, and `true` is returned if an overflow occurred.
pub fn timingSafeAdd(comptime T: type, a: []const T, b: []const T, result: []T, endian: builtin.Endian) bool {
    const Overflow = struct { T, u1 };
    const len: usize = a.len;
    builtin.assert(len == b.len and len == result.len);
    var carry: u1 = 0;
    if (endian == .Little) {
        var idx: usize = 0;
        while (idx < len) : (idx +%= 1) {
            const ov1: Overflow = @addWithOverflow(a[idx], b[idx]);
            const ov2: Overflow = @addWithOverflow(ov1[0], carry);
            result[idx] = ov2[0];
            carry = ov1[1] | ov2[1];
        }
    } else {
        var idx: usize = len;
        while (idx != 0) {
            idx -%= 1;
            const ov1: Overflow = @addWithOverflow(a[idx], b[idx]);
            const ov2: Overflow = @addWithOverflow(ov1[0], carry);
            result[idx] = ov2[0];
            carry = ov1[1] | ov2[1];
        }
    }
    return @bitCast(bool, carry);
}
/// Subtract two integers serialized as arrays of the same size, in constant time.
/// The result is stored into `result`, and `true` is returned if an underflow occurred.
pub fn timingSafeSub(comptime T: type, a: []const T, b: []const T, result: []T, endian: builtin.Endian) bool {
    const len = a.len;
    builtin.assert(len == b.len and len == result.len);
    const Overflow = struct { T, u1 };
    var borrow: u1 = 0;
    if (endian == .Little) {
        var idx: usize = 0;
        while (idx < len) : (idx +%= 1) {
            const ov1: Overflow = @subWithOverflow(a[idx], b[idx]);
            const ov2: Overflow = @subWithOverflow(ov1[0], borrow);
            result[idx] = ov2[0];
            borrow = ov1[1] | ov2[1];
        }
    } else {
        var idx: usize = len;
        while (idx != 0) {
            idx -%= 1;
            const ov1: Overflow = @subWithOverflow(a[idx], b[idx]);
            const ov2: Overflow = @subWithOverflow(ov1[0], borrow);
            result[idx] = ov2[0];
            borrow = ov1[1] | ov2[1];
        }
    }
    return @bitCast(bool, borrow);
}
/// Sets a slice to zeroes.
/// Prevents the store from being optimized out.
pub fn secureZero(comptime T: type, _: []T) void {
    if (@sizeOf(T) == 1) {
        @compileError("mach.memset(buf, 0, buf.len);");
    } else {
        @compileError("mach.memset(@ptrCast([*]u8, buf.ptr), 0, " ++ builtin.fmt.cx(@sizeOf(T)) ++ " *% buf.len);");
    }
}
pub fn bytes(buf: []u8) void {
    sys.call(.getrandom, .{ .throw = sys.getrandom_errors }, void, .{
        @intFromPtr(buf.ptr),
        buf.len,
        sys.GRND.RANDOM,
    }) catch |getrandom_error| {
        builtin.proc.exitError(getrandom_error, 2);
    };
}
