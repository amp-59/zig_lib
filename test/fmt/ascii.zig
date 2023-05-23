const zig_lib = @import("../../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const testing = zig_lib.testing;
const builtin = zig_lib.builtin;
fn testWhitespace() !void {
    for (fmt.ascii.whitespace) |char| {
        try builtin.expect(fmt.ascii.isWhitespace(char));
    }
    var i: u8 = 0;
    while (fmt.ascii.isASCII(i)) : (i += 1) {
        if (fmt.ascii.isWhitespace(i)) {
            try builtin.expect(mem.indexOfFirstEqualOne(u8, i, &fmt.ascii.whitespace) != null);
        }
    }
}

fn testASCIICharacterClasses() !void {
    try builtin.expect(!fmt.ascii.isControl('a'));
    try builtin.expect(!fmt.ascii.isControl('z'));
    try builtin.expect(!fmt.ascii.isControl(' '));
    try builtin.expect(fmt.ascii.isControl(0));
    try builtin.expect(fmt.ascii.isControl(fmt.ascii.control_code.form_feed));
    try builtin.expect(fmt.ascii.isControl(fmt.ascii.control_code.unit_separator));
    try builtin.expect(fmt.ascii.isControl(fmt.ascii.control_code.delete));
    try builtin.expect(!fmt.ascii.isControl(0x80));
    try builtin.expect(!fmt.ascii.isControl(0xff));

    try builtin.expect('C' == fmt.ascii.toUpper('c'));
    try builtin.expect(':' == fmt.ascii.toUpper(':'));
    try builtin.expect('\xab' == fmt.ascii.toUpper('\xab'));
    try builtin.expect(!fmt.ascii.isUpper('z'));
    try builtin.expect(!fmt.ascii.isUpper(0x80));
    try builtin.expect(!fmt.ascii.isUpper(0xff));

    try builtin.expect('c' == fmt.ascii.toLower('C'));
    try builtin.expect(':' == fmt.ascii.toLower(':'));
    try builtin.expect('\xab' == fmt.ascii.toLower('\xab'));
    try builtin.expect(!fmt.ascii.isLower('Z'));
    try builtin.expect(!fmt.ascii.isLower(0x80));
    try builtin.expect(!fmt.ascii.isLower(0xff));

    try builtin.expect(fmt.ascii.isAlphanumeric('Z'));
    try builtin.expect(fmt.ascii.isAlphanumeric('z'));
    try builtin.expect(fmt.ascii.isAlphanumeric('5'));
    try builtin.expect(fmt.ascii.isAlphanumeric('a'));
    try builtin.expect(!fmt.ascii.isAlphanumeric('!'));
    try builtin.expect(!fmt.ascii.isAlphanumeric(0x80));
    try builtin.expect(!fmt.ascii.isAlphanumeric(0xff));

    try builtin.expect(!fmt.ascii.isAlphabetic('5'));
    try builtin.expect(fmt.ascii.isAlphabetic('c'));
    try builtin.expect(!fmt.ascii.isAlphabetic('@'));
    try builtin.expect(fmt.ascii.isAlphabetic('Z'));
    try builtin.expect(!fmt.ascii.isAlphabetic(0x80));
    try builtin.expect(!fmt.ascii.isAlphabetic(0xff));

    try builtin.expect(fmt.ascii.isWhitespace(' '));
    try builtin.expect(fmt.ascii.isWhitespace('\t'));
    try builtin.expect(fmt.ascii.isWhitespace('\r'));
    try builtin.expect(fmt.ascii.isWhitespace('\n'));
    try builtin.expect(fmt.ascii.isWhitespace(fmt.ascii.control_code.form_feed));
    try builtin.expect(!fmt.ascii.isWhitespace('.'));
    try builtin.expect(!fmt.ascii.isWhitespace(fmt.ascii.control_code.unit_separator));
    try builtin.expect(!fmt.ascii.isWhitespace(0x80));
    try builtin.expect(!fmt.ascii.isWhitespace(0xff));

    try builtin.expect(!fmt.ascii.isHex('g'));
    try builtin.expect(fmt.ascii.isHex('b'));
    try builtin.expect(fmt.ascii.isHex('F'));
    try builtin.expect(fmt.ascii.isHex('9'));
    try builtin.expect(!fmt.ascii.isHex(0x80));
    try builtin.expect(!fmt.ascii.isHex(0xff));

    try builtin.expect(!fmt.ascii.isDigit('~'));
    try builtin.expect(fmt.ascii.isDigit('0'));
    try builtin.expect(fmt.ascii.isDigit('9'));
    try builtin.expect(!fmt.ascii.isDigit(0x80));
    try builtin.expect(!fmt.ascii.isDigit(0xff));

    try builtin.expect(fmt.ascii.isPrint(' '));
    try builtin.expect(fmt.ascii.isPrint('@'));
    try builtin.expect(fmt.ascii.isPrint('~'));
    try builtin.expect(!fmt.ascii.isPrint(fmt.ascii.control_code.escape));
    try builtin.expect(!fmt.ascii.isPrint(0x80));
    try builtin.expect(!fmt.ascii.isPrint(0xff));
}

fn testLowerString() !void {
    var buf: [1024]u8 = undefined;
    const result = fmt.ascii.lowerString(&buf, "aBcDeFgHiJkLmNOPqrst0234+💩!");
    try testing.expectEqualMany(u8, "abcdefghijklmnopqrst0234+💩!", result);
}
fn testUpperString() !void {
    var buf: [1024]u8 = undefined;
    const result = fmt.ascii.upperString(&buf, "aBcDeFgHiJkLmNOPqrst0234+💩!");
    try testing.expectEqualMany(u8, "ABCDEFGHIJKLMNOPQRST0234+💩!", result);
}
fn testEqlIgnoreCase() !void {
    try builtin.expect(fmt.ascii.testEqualStringIgnoreCase("HEl💩Lo!", "hel💩lo!"));
    try builtin.expect(!fmt.ascii.testEqualStringIgnoreCase("hElLo!", "hello! "));
    try builtin.expect(!fmt.ascii.testEqualStringIgnoreCase("hElLo!", "helro!"));
}
fn testStartsWithIgnoreCase() !void {
    try builtin.expect(fmt.ascii.testEqualFrontIgnoreCase("Bo", "boB"));
    try builtin.expect(!fmt.ascii.testEqualFrontIgnoreCase("haystack", "Needle in hAyStAcK"));
}
fn testEndsWithIgnoreCase() !void {
    try builtin.expect(fmt.ascii.testEqualBackIgnoreCase("haystack", "Needle in HaYsTaCk"));
    try builtin.expect(!fmt.ascii.testEqualBackIgnoreCase("BoB", "Bo"));
}
fn testIndexOfIgnoreCase() !void {
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("foUr", "one Two Three Four").? == 14);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("gOur", "one two three FouR") == null);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("Foo", "foO").? == 0);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("fool", "foo") == null);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("fOo", "FOO foo").? == 0);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("ThReE fOUr", "one two three four five six seven eight nine ten eleven").? == 8);
    try builtin.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("Two tWo", "one two three four five six seven eight nine ten eleven") == null);
}
pub fn asciiTestMain() !void {
    try testWhitespace();
    try testASCIICharacterClasses();
    try testLowerString();
    try testUpperString();
    try testEqlIgnoreCase();
    try testStartsWithIgnoreCase();
    try testEndsWithIgnoreCase();
    try testIndexOfIgnoreCase();
}
