const zl = @import("../../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const debug = zl.debug;
const testing = zl.testing;
const builtin = zl.builtin;
fn testWhitespace() !void {
    for (fmt.ascii.whitespace) |char| {
        try debug.expect(fmt.ascii.isWhitespace(char));
    }
    var i: u8 = 0;
    while (fmt.ascii.isASCII(i)) : (i += 1) {
        if (fmt.ascii.isWhitespace(i)) {
            try debug.expect(mem.indexOfFirstEqualOne(u8, i, &fmt.ascii.whitespace) != null);
        }
    }
}

fn testASCIICharacterClasses() !void {
    try debug.expect(!fmt.ascii.isControl('a'));
    try debug.expect(!fmt.ascii.isControl('z'));
    try debug.expect(!fmt.ascii.isControl(' '));
    try debug.expect(fmt.ascii.isControl(0));
    try debug.expect(fmt.ascii.isControl(fmt.ascii.control_code.form_feed));
    try debug.expect(fmt.ascii.isControl(fmt.ascii.control_code.unit_separator));
    try debug.expect(fmt.ascii.isControl(fmt.ascii.control_code.delete));
    try debug.expect(!fmt.ascii.isControl(0x80));
    try debug.expect(!fmt.ascii.isControl(0xff));

    try debug.expect('C' == fmt.ascii.toUpper('c'));
    try debug.expect(':' == fmt.ascii.toUpper(':'));
    try debug.expect('\xab' == fmt.ascii.toUpper('\xab'));
    try debug.expect(!fmt.ascii.isUpper('z'));
    try debug.expect(!fmt.ascii.isUpper(0x80));
    try debug.expect(!fmt.ascii.isUpper(0xff));

    try debug.expect('c' == fmt.ascii.toLower('C'));
    try debug.expect(':' == fmt.ascii.toLower(':'));
    try debug.expect('\xab' == fmt.ascii.toLower('\xab'));
    try debug.expect(!fmt.ascii.isLower('Z'));
    try debug.expect(!fmt.ascii.isLower(0x80));
    try debug.expect(!fmt.ascii.isLower(0xff));

    try debug.expect(fmt.ascii.isAlphanumeric('Z'));
    try debug.expect(fmt.ascii.isAlphanumeric('z'));
    try debug.expect(fmt.ascii.isAlphanumeric('5'));
    try debug.expect(fmt.ascii.isAlphanumeric('a'));
    try debug.expect(!fmt.ascii.isAlphanumeric('!'));
    try debug.expect(!fmt.ascii.isAlphanumeric(0x80));
    try debug.expect(!fmt.ascii.isAlphanumeric(0xff));

    try debug.expect(!fmt.ascii.isAlphabetic('5'));
    try debug.expect(fmt.ascii.isAlphabetic('c'));
    try debug.expect(!fmt.ascii.isAlphabetic('@'));
    try debug.expect(fmt.ascii.isAlphabetic('Z'));
    try debug.expect(!fmt.ascii.isAlphabetic(0x80));
    try debug.expect(!fmt.ascii.isAlphabetic(0xff));

    try debug.expect(fmt.ascii.isWhitespace(' '));
    try debug.expect(fmt.ascii.isWhitespace('\t'));
    try debug.expect(fmt.ascii.isWhitespace('\r'));
    try debug.expect(fmt.ascii.isWhitespace('\n'));
    try debug.expect(fmt.ascii.isWhitespace(fmt.ascii.control_code.form_feed));
    try debug.expect(!fmt.ascii.isWhitespace('.'));
    try debug.expect(!fmt.ascii.isWhitespace(fmt.ascii.control_code.unit_separator));
    try debug.expect(!fmt.ascii.isWhitespace(0x80));
    try debug.expect(!fmt.ascii.isWhitespace(0xff));

    try debug.expect(!fmt.ascii.isHex('g'));
    try debug.expect(fmt.ascii.isHex('b'));
    try debug.expect(fmt.ascii.isHex('F'));
    try debug.expect(fmt.ascii.isHex('9'));
    try debug.expect(!fmt.ascii.isHex(0x80));
    try debug.expect(!fmt.ascii.isHex(0xff));

    try debug.expect(!fmt.ascii.isDigit('~'));
    try debug.expect(fmt.ascii.isDigit('0'));
    try debug.expect(fmt.ascii.isDigit('9'));
    try debug.expect(!fmt.ascii.isDigit(0x80));
    try debug.expect(!fmt.ascii.isDigit(0xff));

    try debug.expect(fmt.ascii.isPrint(' '));
    try debug.expect(fmt.ascii.isPrint('@'));
    try debug.expect(fmt.ascii.isPrint('~'));
    try debug.expect(!fmt.ascii.isPrint(fmt.ascii.control_code.escape));
    try debug.expect(!fmt.ascii.isPrint(0x80));
    try debug.expect(!fmt.ascii.isPrint(0xff));
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
    try debug.expect(fmt.ascii.testEqualStringIgnoreCase("HEl💩Lo!", "hel💩lo!"));
    try debug.expect(!fmt.ascii.testEqualStringIgnoreCase("hElLo!", "hello! "));
    try debug.expect(!fmt.ascii.testEqualStringIgnoreCase("hElLo!", "helro!"));
}
fn testStartsWithIgnoreCase() !void {
    try debug.expect(fmt.ascii.testEqualFrontIgnoreCase("Bo", "boB"));
    try debug.expect(!fmt.ascii.testEqualFrontIgnoreCase("haystack", "Needle in hAyStAcK"));
}
fn testEndsWithIgnoreCase() !void {
    try debug.expect(fmt.ascii.testEqualBackIgnoreCase("haystack", "Needle in HaYsTaCk"));
    try debug.expect(!fmt.ascii.testEqualBackIgnoreCase("BoB", "Bo"));
}
fn testIndexOfIgnoreCase() !void {
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("foUr", "one Two Three Four").? == 14);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("gOur", "one two three FouR") == null);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("Foo", "foO").? == 0);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("fool", "foo") == null);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("fOo", "FOO foo").? == 0);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("ThReE fOUr", "one two three four five six seven eight nine ten eleven").? == 8);
    try debug.expect(fmt.ascii.indexOfFirstEqualStringIgnoreCase("Two tWo", "one two three four five six seven eight nine ten eleven") == null);
}
pub fn testAscii() !void {
    try testWhitespace();
    try testASCIICharacterClasses();
    try testLowerString();
    try testUpperString();
    try testEqlIgnoreCase();
    try testStartsWithIgnoreCase();
    try testEndsWithIgnoreCase();
    try testIndexOfIgnoreCase();
}
