const meta = @import("./meta.zig");
const math = @import("./math.zig");
const debug = @import("./debug.zig");
const builtin = @import("./builtin.zig");
const _float = @import("./parse/float.zig");

pub usingnamespace _float;

pub const E = error{BadParse};
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
    if (@typeInfo(Int).Int.signedness == .unsigned) {
        if (math.cast(Int, try unsigned(str))) |ret| {
            return ret;
        }
    } else {
        if (math.cast(Int, try signed(str))) |ret| {
            return ret;
        }
    }
    return error.Overflow;
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
    var idx: usize = @intFromBool(neg) + @intFromBool(pos);
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
    const Int = meta.Child(T);
    const bit_size_of: comptime_int = @bitSizeOf(Int);
    const max_idx: comptime_int = (bit_size_of +% 6) / 7;
    const Shift = @Type(.{ .Int = .{
        .bits = bit_size_of -% @clz(@as(Int, bit_size_of) -% 1),
        .signedness = .unsigned,
    } });
    if (@typeInfo(Int).Int.signedness == .unsigned) {
        var idx: Shift = 0;
        var value: Int = 0;
        while (idx != max_idx) {
            const byte: Int = bytes[idx];
            const ov: struct { Int, u1 } = @shlWithOverflow(byte & 0x7f, idx *% 7);
            idx +%= 1;
            if (ov[1] != 0) {
                return error.Overflow;
            }
            value |= ov[0];
            if (byte & 0x80 == 0) {
                return .{ if (T == Int) value else @as(T, @enumFromInt(value)), idx };
            }
        }
        return error.Overflow;
    } else {
        const Abs = @Type(.{ .Int = .{
            .signedness = .unsigned,
            .bits = bit_size_of,
        } });
        var idx: Shift = 0;
        var value: Abs = 0;
        while (idx != max_idx) {
            const byte: u8 = bytes[idx];
            const ored: i8 = @as(i8, @bitCast(byte | 0x80));
            const shift_amt: Shift = idx *% 7;
            idx +%= 1;
            const ov: struct { Abs, u1 } = @shlWithOverflow(@as(Abs, byte & 0x7f), shift_amt);
            if (ov[1] != 0) {
                if (byte & 0x80 != 0 or
                    @as(Int, @bitCast(ov[0])) >= 0 or
                    ored >> @as(u3, @intCast(bit_size_of -% @as(u16, shift_amt))) != -1)
                {
                    return error.Overflow;
                }
            } else {
                if (byte & 0x80 == 0 and
                    @as(Int, @bitCast(ov[0])) < 0 and
                    ored >> @as(u3, @intCast(bit_size_of -% @as(u16, shift_amt))) != -1)
                {
                    return error.Overflow;
                }
            }
            value |= ov[0];
            if (byte & 0x80 == 0) {
                if (byte & 0x40 != 0 and idx != max_idx) {
                    value |= @as(Abs, @bitCast(@as(Int, -1))) << (shift_amt +% 7);
                }
                return .{ if (T == Int) @as(Int, @bitCast(value)) else @as(T, @enumFromInt(@as(Int, @bitCast(value)))), idx };
            }
        }
        return error.Overflow;
    }
}
pub const noexcept = struct {
    pub fn readLEB128(comptime T: type, bytes: []const u8) struct { T, u8 } {
        const Int = meta.Child(T);
        const bit_size_of: comptime_int = @bitSizeOf(Int);
        const max_idx: comptime_int = (bit_size_of +% 6) / 7;
        const Shift = @Type(.{ .Int = .{
            .bits = bit_size_of -% @clz(@as(Int, bit_size_of) -% 1),
            .signedness = .unsigned,
        } });
        if (@typeInfo(Int).Int.signedness == .unsigned) {
            var idx: Shift = 0;
            var value: Int = 0;
            while (idx != max_idx) {
                const byte: Int = bytes[idx];
                const ov: struct { Int, u1 } = @shlWithOverflow(byte & 0x7f, idx *% 7);
                idx +%= 1;
                value |= ov[0];
                if (byte & 0x80 == 0) {
                    return .{ if (T == Int) value else @as(T, @enumFromInt(value)), idx };
                }
            }
            unreachable;
        } else {
            const Abs = @Type(.{ .Int = .{
                .signedness = .unsigned,
                .bits = bit_size_of,
            } });
            var idx: Shift = 0;
            var value: Abs = 0;
            while (idx != max_idx) {
                const byte: u8 = bytes[idx];
                const shift_amt: Shift = idx *% 7;
                idx +%= 1;
                const ov: struct { Abs, u1 } = @shlWithOverflow(@as(Abs, byte & 0x7f), shift_amt);
                value |= ov[0];
                if (byte & 0x80 == 0) {
                    if (byte & 0x40 != 0 and idx != max_idx) {
                        value |= @as(Abs, @bitCast(@as(Int, -1))) << (shift_amt +% 7);
                    }
                    return .{ if (T == Int) @as(Int, @bitCast(value)) else @as(T, @enumFromInt(@as(Int, @bitCast(value)))), idx };
                }
            }
            unreachable;
        }
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
