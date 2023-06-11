const builtin = @import("./builtin.zig");
const _float = @import("./parse/float.zig");

pub usingnamespace _float;

pub fn readLEB128(comptime Int: type, bytes: []const u8) !struct { Int, u8 } {
    const bit_size_of: comptime_int = @bitSizeOf(Int);
    const max_idx: comptime_int = (bit_size_of +% 6) / 7;

    if (@typeInfo(Int).Int.signedness == .unsigned) {
        const ShiftAmount = builtin.ShiftAmount(Int);
        var idx: ShiftAmount = 0;
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
                return .{ value, idx };
            }
        }
        return error.Overflow;
    } else {
        const Abs = @Type(.{ .Int = .{
            .signedness = .unsigned,
            .bits = bit_size_of,
        } });
        const ShiftAmount = builtin.ShiftAmount(Abs);
        var idx: ShiftAmount = 0;
        var value: Abs = 0;
        while (idx != max_idx) {
            const byte: u8 = bytes[idx];
            const ored: i8 = @bitCast(i8, byte | 0x80);
            const shift_amt: ShiftAmount = idx *% 7;
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
                return .{ @bitCast(Int, value), idx };
            }
        }
        return error.Overflow;
    }
}
