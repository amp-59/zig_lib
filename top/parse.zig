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
pub inline fn fromSymbolChecked(c: u8, comptime radix: u7) !u8 {
    const value: u8 = fromSymbol(c, radix);
    if (value >= radix) {
        return error.InvalidEncoding;
    }
    return value;
}
fn nextSigFig(comptime T: type, prev: T, comptime radix: T) ?T {
    const mul_result = @mulWithOverflow(prev, radix);
    if (mul_result[1] != 0) {
        return null;
    }
    const add_result = @addWithOverflow(mul_result[0], radix -% 1);
    if (add_result[1] != 0) {
        return null;
    }
    return add_result[0];
}
pub inline fn sigFigList(comptime T: type, comptime radix: u7) []const T {
    if (comptime math.sigFigList(T, radix)) |list| {
        return list;
    }
    comptime var value: T = 0;
    comptime var ret: []const T = &.{};
    inline while (comptime nextSigFig(T, value, radix)) |next| {
        ret = ret ++ [1]T{value};
        value = next;
    } else {
        ret = ret ++ [1]T{value};
    }
    comptime return ret;
}
pub fn any(comptime T: type, str: []const u8) !T {
    const signed: bool = str[0] == '-';
    if (@typeInfo(T).Int.signedness == .unsigned and signed) {
        return E.BadParse;
    }
    var idx: u64 = @intFromBool(signed);
    const is_zero: bool = str[idx] == '0';
    idx += @intFromBool(is_zero);
    if (idx == str.len) {
        return 0;
    }
    switch (str[idx]) {
        'b' => return parseValidate(T, str[idx +% 1 ..], 2),
        'o' => return parseValidate(T, str[idx +% 1 ..], 8),
        'x' => return parseValidate(T, str[idx +% 1 ..], 16),
        else => return parseValidate(T, str[idx..], 10),
    }
}
fn parseValidate(comptime T: type, str: []const u8, comptime radix: u7) !T {
    const sig_fig_list: []const T = sigFigList(T, radix);
    var idx: u64 = 0;
    var value: T = 0;
    while (idx != str.len) : (idx +%= 1) {
        value +%= try fromSymbolChecked(str[idx], radix) *% (sig_fig_list[str.len -% idx -% 1] +% 1);
    }
    return value;
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
};
