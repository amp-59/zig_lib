const builtin = @import("../builtin.zig");
pub const replacement_character: u32 = 0xFFFD;

pub fn codepointSequenceLength(c: u32) !u8 {
    if (c < 0x80) return 1;
    if (c < 0x800) return 2;
    if (c < 0x10000) return 3;
    if (c < 0x110000) return 4;
    return error.CodepointTooLarge;
}
fn byteSequenceLength(first_byte: u8) !u8 {
    switch (first_byte) {
        0b0000_0000...0b0111_1111 => return 1,
        0b1100_0000...0b1101_1111 => return 2,
        0b1110_0000...0b1110_1111 => return 3,
        0b1111_0000...0b1111_0111 => return 4,
        else => return error.Utf8InvalidStartByte,
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
fn decode2(bytes: []const u8) !u32 {
    var value: u32 = bytes[0] & 0b00011111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (value < 0x80) {
        return error.Utf8OverlongEncoding;
    }
    return value;
}
fn decode3(bytes: []const u8) !u32 {
    builtin.assertEqual(u64, bytes.len, 3);
    builtin.assertEqual(u64, bytes[0] & 0b11110000, 0b11100000);
    var value: u32 = bytes[0] & 0b00001111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (bytes[2] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[2] & 0b00111111;
    if (value < 0x800) return error.Utf8OverlongEncoding;
    if (0xd800 <= value and value <= 0xdfff) {
        return error.Utf8EncodesSurrogateHalf;
    }
    return value;
}
fn decode4(bytes: []const u8) !u32 {
    builtin.assertEqual(u64, bytes.len, 4);
    builtin.assertEqual(u64, bytes[0] & 0b11111000, 0b11110000);
    var value: u32 = bytes[0] & 0b00000111;
    if (bytes[1] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[1] & 0b00111111;
    if (bytes[2] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[2] & 0b00111111;
    if (bytes[3] & 0b11000000 != 0b10000000) {
        return error.Utf8ExpectedContinuation;
    }
    value <<= 6;
    value |= bytes[3] & 0b00111111;
    if (value < 0x10000) {
        return error.Utf8OverlongEncoding;
    }
    if (value > 0x10FFFF) {
        return error.Utf8CodepointTooLarge;
    }
    return value;
}
pub fn encode(c: u32, out: []u8) !u8 {
    const length: u8 = try codepointSequenceLength(c);
    builtin.assert(out.len >= length);
    switch (length) {
        1 => out[0] = @intCast(u8, c),
        2 => {
            out[0] = @intCast(u8, 0b11000000 | (c >> 6));
            out[1] = @intCast(u8, 0b10000000 | (c & 0b111111));
        },
        3 => {
            if (0xd800 <= c and c <= 0xdfff) {
                return error.Utf8CannotEncodeSurrogateHalf;
            }
            out[0] = @intCast(u8, 0b11100000 | (c >> 12));
            out[1] = @intCast(u8, 0b10000000 | ((c >> 6) & 0b111111));
            out[2] = @intCast(u8, 0b10000000 | (c & 0b111111));
        },
        4 => {
            out[0] = @intCast(u8, 0b11110000 | (c >> 18));
            out[1] = @intCast(u8, 0b10000000 | ((c >> 12) & 0b111111));
            out[2] = @intCast(u8, 0b10000000 | ((c >> 6) & 0b111111));
            out[3] = @intCast(u8, 0b10000000 | (c & 0b111111));
        },
        else => unreachable,
    }
    return length;
}
pub const noexcept = struct {
    pub fn codepointSequenceLength(c: u32) u8 {
        if (c < 0x80) return 1;
        if (c < 0x800) return 2;
        if (c < 0x10000) return 3;
        if (c < 0x110000) return 4;
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
        builtin.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        builtin.assertAboveOrEqual(u32, value, 0x80);
        return value;
    }
    fn decode3(bytes: []const u8) u32 {
        builtin.assertEqual(u64, bytes.len, 3);
        builtin.assertEqual(u64, bytes[0] & 0b11110000, 0b11100000);
        var value: u32 = bytes[0] & 0b00001111;
        builtin.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        builtin.assertEqual(u8, bytes[2] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[2] & 0b00111111;
        builtin.assertAboveOrEqual(u32, value, 0x800);
        builtin.assertBelow(u32, value, 0xd800);
        builtin.assertAbove(u32, value, 0xdfff);
        return value;
    }
    fn decode4(bytes: []const u8) u32 {
        builtin.assertEqual(u64, bytes.len, 4);
        builtin.assertEqual(u64, bytes[0] & 0b11111000, 0b11110000);
        var value: u32 = bytes[0] & 0b00000111;
        builtin.assertEqual(u8, bytes[1] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[1] & 0b00111111;
        builtin.assertEqual(u8, bytes[2] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[2] & 0b00111111;
        builtin.assertEqual(u8, bytes[3] & 0b11000000, 0b10000000);
        value <<= 6;
        value |= bytes[3] & 0b00111111;
        builtin.assertAboveOrEqual(u32, value, 0x10000);
        builtin.assertBelowOrEqual(u32, value, 0x10FFFF);
        return value;
    }
    pub fn encode(c: u32, out: []u8) u8 {
        const ret: u8 = noexcept.codepointSequenceLength(c);
        builtin.assertAboveOrEqual(u64, out.len >= ret);
        switch (ret) {
            1 => out[0] = @intCast(u8, c),
            2 => {
                out[0] = @intCast(u8, 0b11000000 | (c >> 6));
                out[1] = @intCast(u8, 0b10000000 | (c & 0b111111));
            },
            3 => {
                builtin.assertBelow(u8, c, 0xd800);
                builtin.assertAbove(u8, c, 0xdfff);
                out[0] = @intCast(u8, 0b11100000 | (c >> 12));
                out[1] = @intCast(u8, 0b10000000 | ((c >> 6) & 0b111111));
                out[2] = @intCast(u8, 0b10000000 | (c & 0b111111));
            },
            4 => {
                out[0] = @intCast(u8, 0b11110000 | (c >> 18));
                out[1] = @intCast(u8, 0b10000000 | ((c >> 12) & 0b111111));
                out[2] = @intCast(u8, 0b10000000 | ((c >> 6) & 0b111111));
                out[3] = @intCast(u8, 0b10000000 | (c & 0b111111));
            },
            else => unreachable,
        }
        return ret;
    }
};
pub const Iterator = struct {
    bytes: []const u8,
    idx: u64,
    pub fn readNextCodepoint(itr: *Iterator) ?[]const u8 {
        if (itr.idx < itr.bytes.len) {
            const idx: u64 = itr.idx;
            itr.idx +%= noexcept.byteSequenceLength(itr.bytes[idx]);
            return itr.bytes[idx..itr.idx];
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
        const idx: u64 = itr.idx;
        defer itr.idx = idx;
        var end: u64 = idx;
        var num: u64 = 0;
        while (num != amt) : (num +%= 1) {
            if (itr.readNextCodepoint()) |bytes| {
                end += bytes.len;
            } else {
                return itr.bytes[idx..];
            }
        }
        return itr.bytes[idx..end];
    }
};
