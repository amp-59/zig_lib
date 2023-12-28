const meta = @import("meta.zig");
const math = @import("math.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
const _float = @import("parse/float.zig");

pub usingnamespace _float;

const UnsignedOverflow = struct { usize, u1 };
const SignedOverflow = struct { isize, u1 };

pub fn ub(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 2);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'b');
    while (idx != str.len) : (idx +%= 1) {
        value +%= fromSymbol(str[idx], 2) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return value;
}
pub fn uo(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 8);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'o');
    while (idx != str.len) : (idx +%= 1) {
        value +%= fromSymbol(str[idx], 8) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return value;
}
pub fn ud(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 10);
    var idx: u64 = 0;
    var value: T = 0;
    while (idx != str.len) : (idx +%= 1) {
        value +%= fromSymbol(str[idx], 10) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return value;
}
pub fn ux(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 16);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'x');
    while (idx != str.len) : (idx +%= 1) {
        value +%= fromSymbol(str[idx], 16) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return value;
}
pub fn ib(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 2);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '-');
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'b');
    while (idx != str.len) : (idx +%= 1) {
        value +%= @as(i8, @intCast(fromSymbol(str[idx], 2))) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return if (str[0] == '-') -value else value;
}
pub fn io(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 8);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '-');
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'o');
    while (idx != str.len) : (idx +%= 1) {
        value +%= @as(i8, @intCast(fromSymbol(str[idx], 8))) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return if (str[0] == '-') -value else value;
}
pub fn id(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 10);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '-');
    while (idx != str.len) : (idx +%= 1) {
        value +%= @as(i8, @intCast(fromSymbol(str[idx], 10))) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return if (str[0] == '-') -value else value;
}
pub fn ix(comptime T: type, str: []const u8) T {
    @setRuntimeSafety(builtin.is_safe);
    const sig_fig_list: []const T = comptime sigFigList(T, 16);
    var idx: u64 = 0;
    var value: T = 0;
    idx +%= @intFromBool(str[idx] == '-');
    idx +%= @intFromBool(str[idx] == '0');
    idx +%= @intFromBool(str[idx] == 'x');
    while (idx != str.len) : (idx +%= 1) {
        value +%= @as(i8, @intCast(fromSymbol(str[idx], 16))) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return if (str[0] == '-') -value else value;
}
pub fn fromSymbol(c: u8, comptime radix: u7) u8 {
    if (radix <= 10) {
        return c -% '0';
    } else {
        switch (c) {
            '0'...'9' => return c -% '0',
            'a'...'z' => return c -% 'a' +% 0xa,
            'A'...'Z' => return c -% 'A' +% 0xa,
            else => return radix +% 1,
        }
    }
}
pub fn fromSymbolChecked(comptime Int: type, c: u8, comptime radix: u7) !Int {
    const value: u8 = fromSymbol(c, radix);
    if (value >= radix) {
        return error.InvalidEncoding;
    }
    if (math.cast(Int, value)) |ret| {
        return ret;
    }
    return error.Overflow;
}
fn nextSigFig(comptime T: type, prev: T, comptime radix: u7) ?T {
    if (radix > ~@as(T, 0)) {
        return null;
    }
    const mul_result = @mulWithOverflow(prev, radix);
    if (mul_result[1] != 0) {
        return null;
    }
    const add_result = @addWithOverflow(mul_result[0], radix -% 1);
    if (add_result[1] != 0) {
        return null;
    }
    return math.cast(T, add_result[0]);
}
pub inline fn sigFigList(comptime T: type, comptime radix: u7) []const T {
    if (math.sigFigList(T, radix)) |list| {
        return list;
    }
    var value: T = 0;
    var ret: []const T = &.{};
    while (nextSigFig(T, value, radix)) |next| {
        ret = ret ++ [1]T{value};
        value = next;
    } else {
        ret = ret ++ [1]T{value};
    }
    return ret;
}
pub fn any(comptime Int: type, str: []const u8) !Int {
    const x = math.extrema(Int);
    if (@typeInfo(Int).Int.signedness == .unsigned) {
        const res: usize = try unsigned(str);
        if (res > x.max) {
            return error.IntCastTruncatedBits;
        }
        return @intCast(res);
    } else {
        const res: isize = try signed(str);
        if (res < x.min or res > x.max) {
            return error.IntCastTruncatedBits;
        }
        return @intCast(res);
    }
}
fn parseValidate(comptime T: type, str: []const u8, comptime radix: u7) !T {
    const sig_fig_list: []const T = comptime sigFigList(T, radix);
    var idx: u64 = 0;
    var value: struct { T, u1 } = .{ 0, 0 };
    while (idx != str.len) : (idx +%= 1) {
        value = @addWithOverflow(value[0], try fromSymbolChecked(T, str[idx], radix) *% (sig_fig_list[str.len -% idx -% 1] +% 1));
        if (value[1] != 0) {
            return error.Overflow;
        }
    }
    return value[0];
}
pub fn unsigned(str: []const u8) !usize {
    @setRuntimeSafety(builtin.is_safe);
    if (str.len == 0) {
        return error.InvalidCharacter;
    }
    var idx: usize = 0;
    idx +%= @intFromBool(str[idx] == '0');
    if (idx == str.len) {
        return 0;
    }
    var radix: u8 = 10;
    switch (str[idx]) {
        else => idx -%= 1,
        'b' => radix = 2,
        'o' => radix = 8,
        'x' => radix = 16,
    }
    idx +%= 1;
    const end: usize = idx;
    idx = str.len;
    var res: UnsignedOverflow = .{ 0, 0 };
    var ret: UnsignedOverflow = .{ 0, 0 };
    while (idx != end) {
        idx -%= 1;
        ret = @addWithOverflow(ret[0], (res[0] +% 1) *% switch (str[idx]) {
            '0'...'9' => |byte| (byte -% '0'),
            'a'...'z' => |byte| (byte -% 'a' +% 0xa),
            'A'...'Z' => |byte| (byte -% 'A' +% 0xa),
            else => return error.InvalidCharacter,
        });
        if (ret[1] != 0) {
            return 0;
        }
        res = @mulWithOverflow(res[0], radix);
        if (res[1] != 0) {
            break;
        }
        res = @addWithOverflow(res[0], radix -% 1);
        if (res[1] != 0) {
            break;
        }
    }
    return ret[0];
}
pub fn signed(str: []const u8) !isize {
    @setRuntimeSafety(builtin.is_safe);
    if (str.len == 0) {
        return error.InvalidCharacter;
    }
    const neg: bool = str[0] == '-';
    const pos: bool = str[0] == '+';
    var idx: usize = @intFromBool(neg) +% @intFromBool(pos);
    idx +%= @intFromBool(str[idx] == '0');
    if (idx == str.len) {
        return 0;
    }
    var radix: u8 = 10;
    switch (str[idx]) {
        'x' => radix = 16,
        'o' => radix = 8,
        'b' => radix = 2,
        else => idx -%= 1,
    }
    const end: usize = idx +% 1;
    idx = str.len;
    var res: UnsignedOverflow = .{ 0, 0 };
    var ret: UnsignedOverflow = .{ 0, 0 };
    while (idx != end) {
        idx -%= 1;
        ret = @addWithOverflow(ret[0], (res[0] +% 1) *% switch (str[idx]) {
            '0'...'9' => |byte| (byte -% '0'),
            'a'...'z' => |byte| (byte -% 'a' +% 0xa),
            'A'...'Z' => |byte| (byte -% 'A' +% 0xa),
            else => return error.InvalidCharacter,
        });
        if (ret[1] != 0) {
            return 0;
        }
        res = @mulWithOverflow(res[0], radix);
        if (res[1] != 0) {
            break;
        }
        res = @addWithOverflow(res[0], radix -% 1);
        if (res[1] != 0) {
            break;
        }
    }
    return @bitCast(if (neg) -%ret[0] else ret[0]);
}
pub fn readLEB128(comptime T: type, bytes: []const u8) !struct { T, u8 } {
    if (@typeInfo(T).Int.signedness == .signed) {
        if (T == isize) {
            return noexcept.signedLEB128(bytes.ptr);
        }
        const res = noexcept.signedLEB128(bytes.ptr);
        const val: T = try debug.expectCast(T, res[0]);
        return .{ val, res[1] };
    } else {
        if (T == usize) {
            return noexcept.unsignedLEB128(bytes.ptr);
        }
        const res = noexcept.unsignedLEB128(bytes.ptr);
        const val: T = try debug.expectCast(T, res[0]);
        return .{ val, res[1] };
    }
}
pub const noexcept = struct {
    pub fn readLEB128(comptime T: type, bytes: []const u8) struct { T, u8 } {
        @setRuntimeSafety(false);
        if (@typeInfo(T) == .Int) {
            if (@typeInfo(T).Int.signedness == .signed) {
                if (T == isize) {
                    return @call(.always_inline, noexcept.signedLEB128, .{bytes.ptr});
                }
                const res = @call(.always_inline, noexcept.signedLEB128, .{bytes.ptr});
                return .{ @intCast(res[0]), res[1] };
            } else {
                if (T == usize) {
                    return @call(.always_inline, noexcept.unsignedLEB128, .{bytes.ptr});
                }
                const res = @call(.always_inline, noexcept.unsignedLEB128, .{bytes.ptr});
                return .{ @intCast(res[0]), res[1] };
            }
        } else {
            const res = @call(.always_inline, noexcept.readLEB128, .{ @typeInfo(T).Enum.tag_type, bytes });
            return .{ @enumFromInt(res[0]), res[1] };
        }
    }
    pub fn signedLEB128(bytes: [*]const u8) struct { isize, u8 } {
        @setRuntimeSafety(false);
        const max_idx: comptime_int = (@bitSizeOf(isize) +% 6) / 7;
        var value: usize = 0;
        var idx: u8 = 0;
        while (idx != max_idx) : (idx +%= 1) {
            value |= @as(usize, bytes[idx] & 0x7f) << @truncate(idx *% 7);
            if (bytes[idx] & 0x80 != 0) {
                continue;
            }
            if (bytes[idx] & 0x40 != 0 and idx +% 1 != max_idx) {
                value |= ~@as(usize, 0) << @truncate((idx +% 1) *% 7);
            }
            return .{ @bitCast(value), idx +% 1 };
        }
        unreachable;
    }
    pub fn unsignedLEB128(bytes: [*]const u8) struct { usize, u8 } {
        @setRuntimeSafety(false);
        const max_idx: comptime_int = (@bitSizeOf(usize) +% 6) / 7;
        var value: usize = 0;
        var idx: u8 = 0;
        while (idx != max_idx) : (idx +%= 1) {
            value |= @as(usize, bytes[idx] & 0x7f) << @truncate(idx *% 7);
            if (bytes[idx] & 0x80 == 0) {
                return .{ value, idx +% 1 };
            }
        }
        unreachable;
    }
    pub fn unsignedRadix(str: []const u8, radix: u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var res: usize = 0;
        var ret: usize = 0;
        var idx: usize = str.len;
        while (idx != 0) {
            idx -%= 1;
            ret +%= (res +% 1) *% switch (str[idx]) {
                '0'...'9' => |byte| (byte -% '0'),
                'a'...'z' => |byte| (byte -% 'a' +% 0xa),
                'A'...'Z' => |byte| (byte -% 'A' +% 0xa),
                else => radix +% 1,
            };
            res *%= radix;
            res +%= radix -% 1;
        }
        return ret;
    }
    pub fn unsigned(str: []const u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var idx: usize = 0;
        idx +%= @intFromBool(str[idx] == '0');
        if (idx == str.len) {
            return 0;
        }
        var radix: u8 = 10;
        switch (str[idx]) {
            'x' => radix = 16,
            'o' => radix = 8,
            'b' => radix = 2,
            else => idx -%= 1,
        }
        idx +%= 1;
        return unsignedRadix(str[idx..], radix);
    }
    pub fn signedRadix(str: []const u8, radix: u8) isize {
        @setRuntimeSafety(builtin.is_safe);
        var res: isize = 0;
        var ret: isize = 0;
        var idx: usize = str.len;
        while (idx != 0) {
            idx -%= 1;
            ret +%= (res +% 1) *% switch (str[idx]) {
                '0'...'9' => |byte| (byte -% '0'),
                'a'...'z' => |byte| (byte -% 'a' +% 0xa),
                'A'...'Z' => |byte| (byte -% 'A' +% 0xa),
                else => radix +% 1,
            };
            res *%= radix;
            res +%= radix -% 1;
        }
        return ret;
    }
    pub fn signed(str: []const u8) isize {
        @setRuntimeSafety(builtin.is_safe);
        const neg: bool = str[0] == '-';
        const pos: bool = str[0] == '+';
        var idx: usize = @intFromBool(neg) | @intFromBool(pos);
        idx +%= @intFromBool(str[idx] == '0');
        if (idx == str.len) {
            return 0;
        }
        var radix: u8 = 10;
        switch (str[idx]) {
            else => idx -%= 1,
            'b' => radix = 2,
            'o' => radix = 8,
            'x' => radix = 16,
        }
        idx +%= 1;
        const ret: isize = signedRadix(str[idx..], radix);
        return if (neg) -ret else ret;
    }
};
