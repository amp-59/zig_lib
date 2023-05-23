const zig_lib = @import("../../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const testing = zig_lib.testing;
const builtin = zig_lib.builtin;

fn testUtf8Encode() !void {
    comptime try _testUtf8Encode();
    try _testUtf8Encode();
}
fn _testUtf8Encode() !void {
    var array: [4]u8 = undefined;
    try builtin.expect((try fmt.utf8.encode(try fmt.utf8.decode("€"), array[0..])) == 3);
    try builtin.expect(array[0] == 0b11100010);
    try builtin.expect(array[1] == 0b10000010);
    try builtin.expect(array[2] == 0b10101100);
    try builtin.expect((try fmt.utf8.encode(try fmt.utf8.decode("$"), array[0..])) == 1);
    try builtin.expect(array[0] == 0b00100100);
    try builtin.expect((try fmt.utf8.encode(try fmt.utf8.decode("¢"), array[0..])) == 2);
    try builtin.expect(array[0] == 0b11000010);
    try builtin.expect(array[1] == 0b10100010);
    try builtin.expect((try fmt.utf8.encode(try fmt.utf8.decode("𐍈"), array[0..])) == 4);
    try builtin.expect(array[0] == 0b11110000);
    try builtin.expect(array[1] == 0b10010000);
    try builtin.expect(array[2] == 0b10001101);
    try builtin.expect(array[3] == 0b10001000);
}
fn testUtf8EncodeError() !void {
    try _testUtf8EncodeError();
}
fn _testUtf8EncodeError() !void {
    var array: [4]u8 = undefined;
    try testErrorEncode(0xd800, array[0..], error.Utf8CannotEncodeSurrogateHalf);
    try testErrorEncode(0xdfff, array[0..], error.Utf8CannotEncodeSurrogateHalf);
    try testErrorEncode(0x110000, array[0..], error.CodepointTooLarge);
    try testErrorEncode(0x1fffff, array[0..], error.CodepointTooLarge);
}
fn testErrorEncode(codePoint: u21, array: []u8, expectedErr: anyerror) !void {
    try builtin.expect(expectedErr == fmt.utf8.encode(codePoint, array));
}
fn testUtf8IteratorOnAscii() !void {
    try _testUtf8IteratorOnAscii();
}
fn _testUtf8IteratorOnAscii() !void {
    var itr: fmt.utf8.Iterator = fmt.utf8.Iterator{ .bytes = "abc", .idx = 0 };
    try testing.expectEqualMany(u8, "a", itr.readNextCodepoint().?);
    try testing.expectEqualMany(u8, "b", itr.readNextCodepoint().?);
    try testing.expectEqualMany(u8, "c", itr.readNextCodepoint().?);
    try builtin.expect(itr.readNextCodepoint() == null);
    itr.idx = 0;
    try builtin.expect(itr.decodeNextCodepoint().? == 'a');
    try builtin.expect(itr.decodeNextCodepoint().? == 'b');
    try builtin.expect(itr.decodeNextCodepoint().? == 'c');
    try builtin.expect(itr.decodeNextCodepoint() == null);
    itr = .{ .bytes = "äåéëþüúíóö", .idx = 0 };
    for ([_][]const u8{ "ä", "å", "é", "ë", "þ", "ü", "ú", "í", "ó", "ö" }) |s| {
        try testing.expectEqualMany(u8, s, itr.readNextCodepoint().?);
    } else {
        try builtin.expect(itr.decodeNextCodepoint() == null);
    }
    itr = .{ .bytes = "こんにちは", .idx = 0 };
    for ([_][]const u8{ "こ", "ん", "に", "ち", "は" }) |s| {
        try testing.expectEqualMany(u8, s, itr.readNextCodepoint().?);
    } else {
        try builtin.expect(itr.decodeNextCodepoint() == null);
    }
    itr.idx = 0;
    try testing.expectEqualMany(u8, "こんに", itr.peekNextCodepoints(3));
}
pub fn utf8TestMain() !void {
    try testUtf8Encode();
    try testUtf8EncodeError();
    try testUtf8IteratorOnAscii();
}
