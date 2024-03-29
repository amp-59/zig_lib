const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
pub const replacement_character: u32 = 0xFFFD;

pub fn codepointSequenceLength(c: u32) !u8 {
    if (c < 0x80) return 1;
    if (c < 0x800) return 2;
    if (c < 0x10000) return 3;
    if (c < 0x110000) return 4;
    return error.InvalidInput;
}
pub fn byteSequenceLength(first_byte: u8) !u8 {
    switch (first_byte) {
        0b0000_0000...0b0111_1111 => return 1,
        0b1100_0000...0b1101_1111 => return 2,
        0b1110_0000...0b1110_1111 => return 3,
        0b1111_0000...0b1111_0111 => return 4,
        else => return error.InvalidEncoding,
    }
}
pub fn decode(bytes: []const u8) !u32 {
    switch (bytes.len) {
        1 => return bytes[0],
        2 => return decode2(bytes),
        3 => return decode3(bytes),
        4 => return decode4(bytes),
        else => unreachable,
    }
}
pub fn decode2(bytes: []const u8) !u32 {
    var value: u32 = bytes[0] & 0b00011111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (value < 0x80) {
        return error.InvalidEncoding;
    }
    return value;
}
pub fn decode3(bytes: []const u8) !u32 {
    var value: u32 = bytes[0] & 0b00001111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (bytes[2] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[2] & 0b00111111;
    if (value < 0x800) {
        return error.InvalidEncoding;
    }
    if (0xd800 <= value and value <= 0xdfff) {
        return error.InvalidEncoding;
    }
    return value;
}
pub fn decode4(bytes: []const u8) !u32 {
    var value: u32 = bytes[0] & 0b00000111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (bytes[2] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[2] & 0b00111111;
    if (bytes[3] & 0b11000000 != 0b10000000) {
        return error.InvalidEncoding;
    }
    value <<= 6;
    value |= bytes[3] & 0b00111111;
    if (value < 0x10000 or value > 0x10FFFF) {
        return error.InvalidEncoding;
    }
    return value;
}
pub fn encode(value: u32, out: []u8) !u8 {
    const ret: u8 = try codepointSequenceLength(value);
    debug.assertAboveOrEqual(u64, out.len, ret);
    switch (ret) {
        1 => out[0] = @as(u8, @intCast(value)),
        2 => {
            out[0] = @as(u8, @intCast(0b11000000 | (value >> 6)));
            out[1] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
        },
        3 => {
            if (0xd800 <= value and value <= 0xdfff) {
                return error.InvalidInput;
            }
            out[0] = @as(u8, @intCast(0b11100000 | (value >> 12)));
            out[1] = @as(u8, @intCast(0b10000000 | ((value >> 6) & 0b111111)));
            out[2] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
        },
        4 => {
            out[0] = @as(u8, @intCast(0b11110000 | (value >> 18)));
            out[1] = @as(u8, @intCast(0b10000000 | ((value >> 12) & 0b111111)));
            out[2] = @as(u8, @intCast(0b10000000 | ((value >> 6) & 0b111111)));
            out[3] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
        },
        else => unreachable,
    }
    return ret;
}
pub const noexcept = struct {
    pub fn codepointSequenceLength(value: u32) u8 {
        if (value < 0x80) return 1;
        if (value < 0x800) return 2;
        if (value < 0x10000) return 3;
        if (value < 0x110000) return 4;
        unreachable;
    }
    fn byteSequenceLength(first_byte: u8) u8 {
        switch (first_byte) {
            0b0000_0000...0b0111_1111 => return 1,
            0b1100_0000...0b1101_1111 => return 2,
            0b1110_0000...0b1110_1111 => return 3,
            0b1111_0000...0b1111_0111 => return 4,
            else => unreachable,
        }
    }
    pub fn decode(bytes: []const u8) u32 {
        switch (bytes.len) {
            1 => return bytes[0],
            2 => return noexcept.decode2(bytes),
            3 => return noexcept.decode3(bytes),
            4 => return noexcept.decode4(bytes),
            else => unreachable,
        }
    }
    fn decode2(bytes: []const u8) u32 {
        var value: u32 = bytes[0] & 0b00011111;
        debug.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        debug.assertAboveOrEqual(u32, value, 0x80);
        return value;
    }
    fn decode3(bytes: []const u8) u32 {
        debug.assertEqual(u64, bytes.len, 3);
        debug.assertEqual(u64, bytes[0] & 0b11110000, 0b11100000);
        var value: u32 = bytes[0] & 0b00001111;
        debug.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        debug.assertEqual(u8, bytes[2] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[2] & 0b00111111;
        debug.assertAboveOrEqual(u32, value, 0x800);
        debug.assertBelow(u32, value, 0xd800);
        debug.assertAbove(u32, value, 0xdfff);
        return value;
    }
    fn decode4(bytes: []const u8) u32 {
        debug.assertEqual(u64, bytes.len, 4);
        debug.assertEqual(u64, bytes[0] & 0b11111000, 0b11110000);
        var value: u32 = bytes[0] & 0b00000111;
        debug.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        debug.assertEqual(u8, bytes[2] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[2] & 0b00111111;
        debug.assertEqual(u8, bytes[3] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[3] & 0b00111111;
        debug.assertAboveOrEqual(u32, value, 0x10000);
        debug.assertBelowOrEqual(u32, value, 0x10FFFF);
        return value;
    }
    pub fn encode(value: u32, out: []u8) u8 {
        const ret: u8 = noexcept.codepointSequenceLength(value);
        debug.assertAboveOrEqual(u64, out.len, ret);
        switch (ret) {
            1 => out[0] = @as(u8, @intCast(value)),
            2 => {
                out[0] = @as(u8, @intCast(0b11000000 | (value >> 6)));
                out[1] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
            },
            3 => {
                debug.assertBelow(u32, value, 0xd800);
                debug.assertAbove(u32, value, 0xdfff);
                out[0] = @as(u8, @intCast(0b11100000 | (value >> 12)));
                out[1] = @as(u8, @intCast(0b10000000 | ((value >> 6) & 0b111111)));
                out[2] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
            },
            4 => {
                out[0] = @as(u8, @intCast(0b11110000 | (value >> 18)));
                out[1] = @as(u8, @intCast(0b10000000 | ((value >> 12) & 0b111111)));
                out[2] = @as(u8, @intCast(0b10000000 | ((value >> 6) & 0b111111)));
                out[3] = @as(u8, @intCast(0b10000000 | (value & 0b111111)));
            },
            else => unreachable,
        }
        return ret;
    }
};
pub const Iterator = struct {
    bytes: []const u8,
    bytes_idx: u64 = 0,
    pub fn readNextCodepoint(itr: *Iterator) ?[]const u8 {
        if (itr.bytes_idx < itr.bytes.len) {
            const idx: u64 = itr.bytes_idx;
            itr.bytes_idx +%= noexcept.byteSequenceLength(itr.bytes[idx]);
            return itr.bytes[idx..itr.bytes_idx];
        }
        return null;
    }
    pub fn decodeNextCodepoint(itr: *Iterator) ?u32 {
        if (itr.readNextCodepoint()) |bytes| {
            return noexcept.decode(bytes);
        }
        return null;
    }
    pub fn peekNextCodepoints(itr: *Iterator, amt: u64) []const u8 {
        const idx: u64 = itr.bytes_idx;
        defer itr.bytes_idx = idx;
        var end: u64 = idx;
        for (0..amt) |_| {
            if (itr.readNextCodepoint()) |bytes| {
                end += bytes.len;
            } else {
                return itr.bytes[idx..];
            }
        }
        return itr.bytes[idx..end];
    }
};
pub fn countCodepoints(bytes: []const u8) !usize {
    var len: u64 = 0;
    var itr: Iterator = .{ .bytes = bytes };
    while (itr.readNextCodepoint() != null) {
        len +%= 1;
    }
    return len;
}
pub fn testValidCodepoint(value: u32) bool {
    switch (value) {
        0xd800...0xdfff => { // Surrogates range
            return false;
        },
        0x110000...0x1fffff => { // Above the maximum codepoint value
            return false;
        },
        else => return true,
    }
}
pub fn expectValidSlice(bytes: []const u8) !void {
    var itr: Iterator = .{ .bytes = bytes };
    while (itr.bytes_idx < itr.bytes.len) {
        const idx: u64 = itr.bytes_idx;
        itr.bytes_idx +%= try byteSequenceLength(itr.bytes[idx]);
        const cp: u32 = try decode(itr.bytes[idx..itr.bytes_idx]);
        if (!testValidCodepoint(cp)) {
            return error.InvalidEncoding;
        }
    }
}
pub fn testValidSlice(bytes: []const u8) bool {
    return expectValidSlice(bytes) != error.InvalidEncoding;
}
