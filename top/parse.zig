const meta = @import("./meta.zig");
const _float = @import("./parse/float.zig");

pub usingnamespace _float;

pub fn readLEB128(comptime T: type, bytes: []const u8) !extern struct { T, u8 } {
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
                return .{ if (T == Int) value else @intToEnum(T, value), idx };
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
            const ored: i8 = @bitCast(i8, byte | 0x80);
            const shift_amt: Shift = idx *% 7;
            idx +%= 1;
            const ov: struct { Abs, u1 } = @shlWithOverflow(@as(Abs, byte & 0x7f), shift_amt);
            if (ov[1] != 0) {
                if (byte & 0x80 != 0 or
                    @bitCast(Int, ov[0]) >= 0 or
                    ored >> @intCast(u3, bit_size_of -% @as(u16, shift_amt)) != -1)
                {
                    return error.Overflow;
                }
            } else {
                if (byte & 0x80 == 0 and
                    @bitCast(Int, ov[0]) < 0 and
                    ored >> @intCast(u3, bit_size_of -% @as(u16, shift_amt)) != -1)
                {
                    return error.Overflow;
                }
            }
            value |= ov[0];
            if (byte & 0x80 == 0) {
                if (byte & 0x40 != 0 and idx != max_idx) {
                    value |= @bitCast(Abs, @as(Int, -1)) << (shift_amt +% 7);
                }
                return .{ if (T == Int) @bitCast(Int, value) else @intToEnum(T, @bitCast(Int, value)), idx };
            }
        }
        return error.Overflow;
    }
}
pub const noexcept = struct {
    pub fn readLEB128(comptime T: type, bytes: []const u8) extern struct { T, u8 } {
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
                    return .{ if (T == Int) value else @intToEnum(T, value), idx };
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
                        value |= @bitCast(Abs, @as(Int, -1)) << (shift_amt +% 7);
                    }
                    return .{ if (T == Int) @bitCast(Int, value) else @intToEnum(T, @bitCast(Int, value)), idx };
                }
            }
            unreachable;
        }
    }
};
