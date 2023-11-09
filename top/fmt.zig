const mem = @import("mem.zig");
const tab = @import("tab.zig");
const math = @import("math.zig");
const meta = @import("meta.zig");
const time = @import("time.zig");
const debug = @import("debug.zig");
const parse = @import("parse.zig");
const builtin = @import("builtin.zig");
pub const utf8 = @import("fmt/utf8.zig");
pub const ascii = @import("fmt/ascii.zig");
pub fn Interface(comptime Format: type) type {
    return struct {
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(Format.write(buf, format.value), buf);
        }
        pub inline fn formatLength(format: Format) usize {
            return Format.length(format.value);
        }
        const undef: Format = undefined;
    };
}
pub const AboutSrc = blk: {
    var len: usize = 0;
    if (builtin.message_style) |style| {
        len +%= style.len;
        len +%= builtin.message_no_style.len;
    }
    len +%= builtin.message_indent;
    break :blk *const [len:0]u8;
};
pub fn about(comptime s: [:0]const u8) AboutSrc {
    comptime {
        var lhs: [:0]const u8 = s;
        lhs = builtin.message_prefix ++ lhs;
        lhs = lhs ++ builtin.message_suffix;
        const len: usize = lhs.len;
        if (builtin.message_style) |style| {
            lhs = style ++ lhs ++ builtin.message_no_style;
        }
        if (len >= builtin.message_indent) {
            @compileError(s ++ " is too long");
        }
        return lhs ++ " " ** (builtin.message_indent - len);
    }
}
/// Returns the apparent length of the first colon in the about string.
pub fn aboutCentre(about_s: AboutSrc) usize {
    @setRuntimeSafety(builtin.is_safe);
    var og: []const u8 = about_s;
    if (builtin.message_style) |style_s| {
        og = og[style_s.len..];
    }
    for (og, 0..) |byte, idx| {
        if (byte == ':') {
            return idx;
        }
    }
    return 0;
}
pub inline fn aboutInit(comptime about_s: AboutSrc, comptime len: usize) [len]u8 {
    const ret: [len -% about_s.len]u8 = undefined;
    return (about_s ++ ret).*;
}
pub const about_blank_s: AboutSrc = about("");
pub const AboutDest = @TypeOf(@constCast(about_blank_s));
pub const about_exit_s: AboutSrc = about("exit");
pub const about_err_len: comptime_int = about_blank_s.len + debug.about.error_s.len;
pub inline fn ci(comptime value: comptime_int) []const u8 {
    if (value < 0) {
        const s: []const u8 = @typeName([-value]void);
        return "-" ++ s[1 .. s.len -% 5];
    } else {
        const s: []const u8 = @typeName([value]void);
        return s[1 .. s.len -% 5];
    }
}
pub inline fn cx(comptime value: anytype) []const u8 {
    const S: type = @TypeOf(value);
    if (@typeInfo(S) == .Fn) {
        return cx(&value);
    }
    const T = [:value]S;
    const s_type_name: []const u8 = @typeName(S);
    const t_type_name: []const u8 = @typeName(T);
    return t_type_name[2 .. t_type_name.len -% (s_type_name.len +% 1)];
}
pub fn aboutEqu(dest: [*]u8, src: AboutSrc) [*]u8 {
    @setRuntimeSafety(false);
    dest[0..src.len].* = src.*;
    return dest + src.len;
}
pub fn strcpy(dest: [*]u8, src: []const u8) usize {
    @memcpy(dest, src);
    return src.len;
}
pub fn strset(dest: [*]u8, byte: u8, len: usize) usize {
    @setRuntimeSafety(false);
    @memset(dest[0..len], byte);
    return len;
}
pub fn strcpyEqu(dest: [*]u8, src: []const u8) [*]u8 {
    @setRuntimeSafety(false);
    @memcpy(dest, src);
    return dest + src.len;
}
pub fn strsetEqu(dest: [*]u8, byte: u8, len: usize) [*]u8 {
    @setRuntimeSafety(false);
    @memset(dest[0..len], byte);
    return dest + len;
}
pub fn strcpyMulti(dest: [*]u8, src: []const []const u8) usize {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = dest;
    for (src) |str| ptr += strcpy(ptr, str);
    return @intFromPtr(ptr) -% @intFromPtr(dest);
}
pub fn strcpyMultiEqu(dest: [*]u8, src: []const []const u8) [*]u8 {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = dest;
    for (src) |str| ptr = strcpyEqu(ptr, str);
    return ptr;
}
pub fn strlen(end: [*]u8, buf: [*]u8) usize {
    @setRuntimeSafety(false);
    if (@inComptime()) {
        var len: usize = 0;
        while (buf + len != end) len +%= 1;
        return len;
    }
    return @intFromPtr(end) -% @intFromPtr(buf);
}
pub fn slice(end: [*]u8, buf: [*]u8) []u8 {
    @setRuntimeSafety(false);
    return buf[0 .. @intFromPtr(end) -% @intFromPtr(buf)];
}
pub fn print(end: [*]u8, buf: [*]u8) void {
    @setRuntimeSafety(false);
    debug.write(buf[0 .. @intFromPtr(end) -% @intFromPtr(buf)]);
}
pub inline fn ib8(value: i8) Ib8 {
    return .{ .value = value };
}
pub inline fn ib16(value: i16) Ib16 {
    return .{ .value = value };
}
pub inline fn ib32(value: i32) Ib32 {
    return .{ .value = value };
}
pub inline fn ib64(value: i64) Ib64 {
    return .{ .value = value };
}
pub inline fn ib128(value: i128) Ib128 {
    return .{ .value = value };
}
pub inline fn io8(value: i8) Io8 {
    return .{ .value = value };
}
pub inline fn io16(value: i16) Io16 {
    return .{ .value = value };
}
pub inline fn io32(value: i32) Io32 {
    return .{ .value = value };
}
pub inline fn io64(value: i64) Io64 {
    return .{ .value = value };
}
pub inline fn io128(value: i128) Io128 {
    return .{ .value = value };
}
pub inline fn id8(value: i8) Id8 {
    return .{ .value = value };
}
pub inline fn id16(value: i16) Id16 {
    return .{ .value = value };
}
pub inline fn id32(value: i32) Id32 {
    return .{ .value = value };
}
pub inline fn id64(value: i64) Id64 {
    return .{ .value = value };
}
pub inline fn id128(value: i128) Id128 {
    return .{ .value = value };
}
pub inline fn ix8(value: i8) Ix8 {
    return .{ .value = value };
}
pub inline fn ix16(value: i16) Ix16 {
    return .{ .value = value };
}
pub inline fn ix32(value: i32) Ix32 {
    return .{ .value = value };
}
pub inline fn ix64(value: i64) Ix64 {
    return .{ .value = value };
}
pub inline fn ix128(value: i128) Ix128 {
    return .{ .value = value };
}
pub inline fn iz8(value: i8) Iz8 {
    return .{ .value = value };
}
pub inline fn iz16(value: i16) Iz16 {
    return .{ .value = value };
}
pub inline fn iz32(value: i32) Iz32 {
    return .{ .value = value };
}
pub inline fn iz64(value: i64) Iz64 {
    return .{ .value = value };
}
pub inline fn iz128(value: i128) Iz128 {
    return .{ .value = value };
}
pub inline fn ub8(value: u8) Ub8 {
    return .{ .value = value };
}
pub inline fn ub16(value: u16) Ub16 {
    return .{ .value = value };
}
pub inline fn ub32(value: u32) Ub32 {
    return .{ .value = value };
}
pub inline fn ub64(value: u64) Ub64 {
    return .{ .value = value };
}
pub inline fn uo8(value: u8) Uo8 {
    return .{ .value = value };
}
pub inline fn uo16(value: u16) Uo16 {
    return .{ .value = value };
}
pub inline fn uo32(value: u32) Uo32 {
    return .{ .value = value };
}
pub inline fn uo64(value: u64) Uo64 {
    return .{ .value = value };
}
pub inline fn uo128(value: u128) Uo128 {
    return .{ .value = value };
}
pub inline fn ud8(value: u8) Ud8 {
    return .{ .value = value };
}
pub inline fn ud16(value: u16) Ud16 {
    return .{ .value = value };
}
pub inline fn ud32(value: u32) Ud32 {
    return .{ .value = value };
}
pub fn ud64(value: u64) Ud64 {
    return .{ .value = value };
}
pub inline fn ud128(value: u128) Ud128 {
    return .{ .value = value };
}
pub inline fn ux8(value: u8) Ux8 {
    return .{ .value = value };
}
pub inline fn esc(value: u8) Esc {
    return .{ .value = value };
}
pub inline fn ux16(value: u16) Ux16 {
    return .{ .value = value };
}
pub inline fn ux32(value: u32) Ux32 {
    return .{ .value = value };
}
pub inline fn ux64(value: u64) Ux64 {
    return .{ .value = value };
}
pub inline fn ux128(value: u128) Ux128 {
    return .{ .value = value };
}
pub inline fn uz8(value: u8) Uz8 {
    return .{ .value = value };
}
pub inline fn uz16(value: u16) Uz16 {
    return .{ .value = value };
}
pub inline fn uz32(value: u32) Uz32 {
    return .{ .value = value };
}
pub inline fn uz64(value: u64) Uz64 {
    return .{ .value = value };
}
pub inline fn uz128(value: u128) Uz128 {
    return .{ .value = value };
}
pub inline fn ubsize(value: usize) Ubsize {
    return .{ .value = value };
}
pub inline fn uosize(value: usize) Uosize {
    return .{ .value = value };
}
pub inline fn udsize(value: usize) Udsize {
    return .{ .value = value };
}
pub inline fn uxsize(value: usize) Uxsize {
    return .{ .value = value };
}
pub inline fn ibsize(value: isize) Ibsize {
    return .{ .value = value };
}
pub inline fn iosize(value: isize) Iosize {
    return .{ .value = value };
}
pub inline fn idsize(value: isize) Idsize {
    return .{ .value = value };
}
pub inline fn ixsize(value: isize) Ixsize {
    return .{ .value = value };
}
pub inline fn writeBin(comptime T: type) fn ([*]u8, T) [*]u8 {
    switch (T) {
        usize => return Ubsize.write,
        isize => return Ibsize.write,
        u64 => return Ub64.write,
        i64 => return Ib64.write,
        u8 => return Ub8.write,
        u16 => return Ub16.write,
        u32 => return Ub32.write,
        i8 => return Ib8.write,
        i16 => return Ib16.write,
        i32 => return Ib32.write,
        else => return Xb(T).write,
    }
}
pub inline fn writeOct(comptime T: type) fn ([*]u8, T) [*]u8 {
    switch (T) {
        usize => return Uosize.write,
        isize => return Iosize.write,
        u64 => return Uo64.write,
        i64 => return Io64.write,
        u8 => return Uo8.write,
        u16 => return Uo16.write,
        u32 => return Uo32.write,
        i8 => return Io8.write,
        i16 => return Io16.write,
        i32 => return Io32.write,
        else => return Xo(T).write,
    }
}
pub inline fn writeDec(comptime T: type) fn ([*]u8, T) [*]u8 {
    switch (T) {
        usize => return Udsize.write,
        isize => return Idsize.write,
        u64 => return Ud64.write,
        i64 => return Id64.write,
        u8 => return Ud8.write,
        u16 => return Ud16.write,
        u32 => return Ud32.write,
        i8 => return Id8.write,
        i16 => return Id16.write,
        i32 => return Id32.write,
        else => return Xd(T).write,
    }
}
pub inline fn writeHex(comptime T: type) fn ([*]u8, T) [*]u8 {
    switch (T) {
        usize => return Uxsize.write,
        isize => return Ixsize.write,
        u64 => return Ux64.write,
        i64 => return Ix64.write,
        u8 => return Ux8.write,
        u16 => return Ux16.write,
        u32 => return Ux32.write,
        i8 => return Ix8.write,
        i16 => return Ix16.write,
        i32 => return Ix32.write,
        else => return Xx(T).write,
    }
}
const lit_char: [256][*:0]const u8 = .{
    "\\x00", "\\x01", "\\x02", "\\x03", "\\x04", "\\x05", "\\x06", "\\x07",
    "\\x08", "\\t",   "\\n",   "\\x0b", "\\x0c", "\\r",   "\\x0e", "\\x0f",
    "\\x10", "\\x11", "\\x12", "\\x13", "\\x14", "\\x15", "\\x16", "\\x17",
    "\\x18", "\\x19", "\\x1a", "\\x1b", "\\x1c", "\\x1d", "\\x1e", "\\x1f",
    " ",     "!",     "\\\"",  "#",     "$",     "%",     "&",     "'",
    "(",     ")",     "*",     "+",     ",",     "-",     ".",     "/",
    "0",     "1",     "2",     "3",     "4",     "5",     "6",     "7",
    "8",     "9",     ":",     ";",     "<",     "=",     ">",     "?",
    "@",     "A",     "B",     "C",     "D",     "E",     "F",     "G",
    "H",     "I",     "J",     "K",     "L",     "M",     "N",     "O",
    "P",     "Q",     "R",     "S",     "T",     "U",     "V",     "W",
    "X",     "Y",     "Z",     "[",     "\\\\",  "]",     "^",     "_",
    "`",     "a",     "b",     "c",     "d",     "e",     "f",     "g",
    "h",     "i",     "j",     "k",     "l",     "m",     "n",     "o",
    "p",     "q",     "r",     "s",     "t",     "u",     "v",     "w",
    "x",     "y",     "z",     "{",     "|",     "}",     "~",     "\\x7f",
    "\\x80", "\\x81", "\\x82", "\\x83", "\\x84", "\\x85", "\\x86", "\\x87",
    "\\x88", "\\x89", "\\x8a", "\\x8b", "\\x8c", "\\x8d", "\\x8e", "\\x8f",
    "\\x90", "\\x91", "\\x92", "\\x93", "\\x94", "\\x95", "\\x96", "\\x97",
    "\\x98", "\\x99", "\\x9a", "\\x9b", "\\x9c", "\\x9d", "\\x9e", "\\x9f",
    "\\xa0", "\\xa1", "\\xa2", "\\xa3", "\\xa4", "\\xa5", "\\xa6", "\\xa7",
    "\\xa8", "\\xa9", "\\xaa", "\\xab", "\\xac", "\\xad", "\\xae", "\\xaf",
    "\\xb0", "\\xb1", "\\xb2", "\\xb3", "\\xb4", "\\xb5", "\\xb6", "\\xb7",
    "\\xb8", "\\xb9", "\\xba", "\\xbb", "\\xbc", "\\xbd", "\\xbe", "\\xbf",
    "\\xc0", "\\xc1", "\\xc2", "\\xc3", "\\xc4", "\\xc5", "\\xc6", "\\xc7",
    "\\xc8", "\\xc9", "\\xca", "\\xcb", "\\xcc", "\\xcd", "\\xce", "\\xcf",
    "\\xd0", "\\xd1", "\\xd2", "\\xd3", "\\xd4", "\\xd5", "\\xd6", "\\xd7",
    "\\xd8", "\\xd9", "\\xda", "\\xdb", "\\xdc", "\\xdd", "\\xde", "\\xdf",
    "\\xe0", "\\xe1", "\\xe2", "\\xe3", "\\xe4", "\\xe5", "\\xe6", "\\xe7",
    "\\xe8", "\\xe9", "\\xea", "\\xeb", "\\xec", "\\xed", "\\xee", "\\xef",
    "\\xf0", "\\xf1", "\\xf2", "\\xf3", "\\xf4", "\\xf5", "\\xf6", "\\xf7",
    "\\xf8", "\\xf9", "\\xfa", "\\xfb", "\\xfc", "\\xfd", "\\xfe", "\\xff",
};
pub fn stringLiteralChar(byte: u8) []const u8 {
    return lit_char[byte][0..switch (byte) {
        32...33, 35...91, 93...126 => 1,
        9...10, 13, 34, 92 => 2,
        0...8, 11...12, 14...31, 127...255 => 4,
    }];
}
pub const StringLiteralFormat = struct {
    value: []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeOne('"');
        for (format.value) |byte| {
            array.writeMany(stringLiteralChar(byte));
        }
        array.writeOne('"');
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        return strlen(write(buf, format.value), buf);
    }
    pub fn formatLength(format: Format) usize {
        return length(format.value);
    }
    pub fn write(buf: [*]u8, string: []const u8) [*]u8 {
        @setRuntimeSafety(false);
        buf[0] = '"';
        var ptr: [*]u8 = buf + 1;
        for (string) |byte| {
            ptr = strcpyEqu(ptr, stringLiteralChar(byte));
        }
        ptr[0] = '"';
        return ptr + 1;
    }
    pub fn length(string: []const u8) usize {
        @setRuntimeSafety(false);
        var len: usize = 2;
        for (string) |byte| {
            len +%= stringLiteralChar(byte).len;
        }
        return len;
    }
};
pub const SideBarIndexFormat = struct {
    value: struct {
        width: usize,
        index: usize,
    },
    pub fn length(width: usize, index: usize) usize {
        var len: usize = width -| sigFigLen(usize, index, 10);
        len +%= Udsize.length(index) +% 1;
        return len +% (builtin.message_indent -| (width +% 1));
    }
    pub fn write(buf: [*]u8, width: usize, index: usize) [*]u8 {
        @setRuntimeSafety(false);
        const len: usize = sigFigLen(usize, index, 10);
        const rem: usize = builtin.message_indent -| (width +% 1);
        var ptr: [*]u8 = strsetEqu(buf, ' ', width -| len);
        ptr = Udsize.write(ptr, index);
        ptr[0] = ':';
        return strsetEqu(ptr + 1, ' ', rem);
    }
};
pub const SideBarSubHeadingFormat = struct {
    value: struct {
        width: usize,
        heading: []const u8,
    },
    pub fn length(width: usize, heading: []const u8) usize {
        var len: usize = width -| heading.len;
        len +%= heading.len +% 1;
        return len +% (builtin.message_indent -| (width +% 1));
    }
    pub fn write(buf: [*]u8, width: usize, heading: []const u8) [*]u8 {
        @setRuntimeSafety(false);
        const rem: usize = builtin.message_indent -% (width +% 1);
        var ptr: [*]u8 = strsetEqu(buf, ' ', width -| heading.len);
        ptr = strcpyEqu(ptr, heading);
        ptr[0] = ':';
        return strsetEqu(ptr + 1, ' ', rem);
    }
};
fn sigFigMaxLen(comptime T: type, comptime radix: u7) comptime_int {
    @setRuntimeSafety(false);
    var value: if (@bitSizeOf(T) < 8) u8 else @TypeOf(@abs(@as(T, 0))) = 0;
    var len: u16 = 0;
    if (radix != 10) {
        len += 2;
    }
    value -%= 1;
    while (value != 0) : (value /= radix) {
        len += 1;
    }
    return len;
}
pub fn sigFigLen(
    comptime U: type,
    abs_value: if (@bitSizeOf(U) < 8) u8 else U,
    comptime radix: u7,
) usize {
    @setRuntimeSafety(false);
    if (@inComptime() and builtin.isUndefined(abs_value)) {
        return 9;
    }
    if (@bitSizeOf(U) == 1) {
        return 1;
    }
    var value: @TypeOf(abs_value) = abs_value;
    var count: u64 = 0;
    while (value != 0) : (value /= radix) {
        count +%= 1;
    }
    return @max(1, count);
}
pub fn toSymbol(comptime T: type, value: T, comptime radix: u7) u8 {
    @setRuntimeSafety(false);
    if (@bitSizeOf(T) < 8) {
        return toSymbol(u8, value, radix);
    }
    const result: u8 = @truncate(@rem(value, radix));
    const dx = .{
        .d = @as(u8, '9' -% 9),
        .x = @as(u8, 'f' -% 15),
    };
    if (radix > 10) {
        return result +% if (result < 10) dx.d else dx.x;
    } else {
        return result +% dx.d;
    }
}
pub const FormatBuf = struct {
    formatWriteBuf: *const fn (*const anyopaque, [*]u8) usize,
    format: *const anyopaque,
};
pub const PolynomialFormatSpec = struct {
    bits: comptime_int,
    signedness: builtin.Signedness,
    radix: comptime_int,
    width: Width,
    range: Range = .{},
    prefix: ?[]const u8 = null,
    suffix: ?[]const u8 = null,
    separator: ?Separator = null,
    const Separator = struct {
        character: u8 = ',',
        digits: comptime_int = 3,
    };
    const Range = struct {
        min: ?comptime_int = null,
        max: ?comptime_int = null,
    };
    const Prefix = union(enum) {
        default,
        string: [:0]const u8,
    };
    const Width = union(enum) {
        min,
        max,
        fixed: u16,
    };
};
pub fn GenericPolynomialFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    const T = packed struct {
        value: Int,
        const Format: type = @This();
        pub const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        pub const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        pub const specification: PolynomialFormatSpec = fmt_spec;
        pub const StaticString = mem.array.StaticString(max_len.?);
        const min_abs_value: comptime_int = fmt_spec.range.min orelse 0;
        const max_abs_value: comptime_int = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: comptime_int = sigFigLen(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: comptime_int = sigFigLen(Abs, max_abs_value, fmt_spec.radix);
        const max_len: ?comptime_int = blk: {
            var len: comptime_int = 0;
            if (fmt_spec.radix > max_abs_value) {
                break :blk len +% 1;
            }
            len +%= max_digits_count;
            if (fmt_spec.prefix) |prefix| {
                len +%= prefix.len;
            }
            if (fmt_spec.signedness == .signed) {
                len +%= 1;
            }
            if (fmt_spec.separator) |s| {
                len +%= (len -% 1) / s.digits;
            }
            if (fmt_spec.suffix) |suffix| {
                len +%= suffix.len;
            }
            break :blk len;
        };
        pub fn write(buf: [*]u8, value: Int) [*]u8 {
            @setRuntimeSafety(false);
            if (@inComptime() and builtin.isUndefined(value)) {
                return strcpyEqu(buf, "undefined");
            }
            if (Abs != Int) {
                buf[0] = '-';
            }
            var ptr: [*]u8 = buf + @intFromBool(value < 0);
            if (fmt_spec.prefix) |prefix| {
                ptr[0..prefix.len].* = prefix[0..prefix.len].*;
                ptr += prefix.len;
            }
            if (fmt_spec.radix > max_abs_value) {
                ptr[0] = if (value == 0) '0' else '1';
                return ptr + 1;
            } else if (fmt_spec.separator) |separator| {
                var abs: Abs = @abs(value);
                var count: usize = switch (fmt_spec.width) {
                    .min => sigFigLen(Abs, abs, fmt_spec.radix),
                    .max => max_digits_count,
                    .fixed => |fixed| fixed,
                };
                count +%= (count -% 1) / separator.digits;
                var ret: [*]u8 = ptr + count;
                var pos: usize = 0;
                while (count != pos) : (abs /= fmt_spec.radix) {
                    pos +%= 1;
                    ptr[count -% pos] = separator.character;
                    count -%=
                        @intFromBool(pos > separator.digits) &
                        @intFromBool(pos % separator.digits == 1);
                    ptr[count -% pos] = toSymbol(Abs, abs, fmt_spec.radix);
                }
                if (fmt_spec.suffix) |suffix| {
                    ptr[0..suffix.len].* = suffix[0..suffix.len].*;
                    ptr += suffix.len;
                }
                return ret;
            } else {
                var abs: Abs = @abs(value);
                var count: usize = switch (fmt_spec.width) {
                    .min => sigFigLen(Abs, abs, fmt_spec.radix),
                    .max => max_digits_count,
                    .fixed => |fixed| fixed,
                };
                var ret: [*]u8 = ptr + count;
                while (count != 0) : (abs /= fmt_spec.radix) {
                    count -%= 1;
                    ptr[count] = toSymbol(Abs, abs, fmt_spec.radix);
                }
                if (fmt_spec.suffix) |suffix| {
                    ret[0..suffix.len].* = suffix[0..suffix.len].*;
                    ret += suffix.len;
                }
                return ret;
            }
        }
        pub fn length(value: Int) usize {
            const abs: Abs = @abs(value);
            var len: usize = 0;
            if (fmt_spec.prefix) |prefix| {
                len +%= prefix.len;
            }
            if (value < 0) {
                len +%= 1;
            }
            if (fmt_spec.radix > max_abs_value) {
                return len +% 1;
            }
            var count: usize = switch (fmt_spec.width) {
                .min => sigFigLen(Abs, abs, fmt_spec.radix),
                .max => max_digits_count,
                .fixed => |fixed| fixed,
            };
            if (fmt_spec.separator) |s| {
                count +%= (count -% 1) / s.digits;
            }
            if (fmt_spec.suffix) |suffix| {
                len +%= suffix.len;
            }
            return len +% count;
        }
        pub fn formatConvert(format: Format) StaticString {
            var array: StaticString = undefined;
            array.undefineAll();
            array.writeFormat(format);
            return array;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn PathFormat(comptime Path: type) type {
    const T = struct {
        const Format = Path;
        pub fn formatWrite(format: Format, array: anytype) void {
            @setRuntimeSafety(builtin.is_safe);
            if (format.names_len != 0) {
                array.writeMany(format.names[0]);
                for (format.names[1..format.names_len]) |name| {
                    array.writeOne('/');
                    array.writeMany(name);
                }
                array.writeOne(0);
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(write(buf, format), buf);
        }
        pub fn formatLength(format: Format) usize {
            return length(format);
        }
        pub fn formatWriteBufLiteral(format: Format, buf: [*]u8) usize {
            return strlen(writeLiteral(buf, format), buf);
        }
        pub fn formatWriteBufDisplay(format: Format, buf: [*]u8) usize {
            return strlen(writeDisplay(buf, format), buf);
        }
        fn writeDisplay(buf: [*]u8, path: Path) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            const end: [*]u8 = Format.write(buf, path) - 1;
            const len: usize = @intFromPtr(end) -% @intFromPtr(buf);
            if (builtin.AbsoluteState != void) {
                if (@hasField(builtin.AbsoluteState, "cwd")) {
                    if (builtin.absolute_state.ptr.cwd.len != 0) {
                        if (builtin.absolute_state.ptr.cwd.len <= len and mem.testEqualString(
                            builtin.absolute_state.ptr.cwd,
                            buf[0..builtin.absolute_state.ptr.cwd.len],
                        )) {
                            buf[0] = '.';
                            return strcpyEqu(buf + 1, buf[builtin.absolute_state.ptr.cwd.len..len]);
                        }
                    }
                }
                if (@hasField(builtin.AbsoluteState, "home")) {
                    if (builtin.absolute_state.ptr.home.len != 0) {
                        if (builtin.absolute_state.ptr.home.len <= len and mem.testEqualString(
                            builtin.absolute_state.ptr.home,
                            buf[0..builtin.absolute_state.ptr.home.len],
                        )) {
                            buf[0] = '~';
                            return strcpyEqu(buf + 1, buf[builtin.absolute_state.ptr.home.len..len]);
                        }
                    }
                }
            }
            return end;
        }
        pub fn lengthDisplay(path: Path) usize {
            @setRuntimeSafety(false);
            var tmp: [4096]u8 = undefined; // TODO Get rid of this by iterating names
            return strlen(writeDisplay(&tmp, path), &tmp);
        }
        pub fn writeDisplayPath(buf: [*]u8, pathname: [:0]const u8) [*]u8 {
            @setRuntimeSafety(false);
            return writeDisplay(buf, Format{ .names = @constCast(@ptrCast(&pathname)), .names_len = 1, .names_max_len = 1 });
        }
        pub fn lengthDisplayPath(pathname: [:0]const u8) usize {
            @setRuntimeSafety(false);
            return lengthDisplay(Format{ .names = @constCast(@ptrCast(&pathname)), .names_len = 1, .names_max_len = 1 });
        }
        pub fn writeLiteral(buf: [*]u8, path: Path) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            buf[0] = '"';
            var ptr: [*]u8 = buf + 1;
            if (path.names_len != 0) {
                for (path.names[0]) |byte| {
                    ptr = strcpyEqu(ptr, stringLiteralChar(byte));
                }
                for (path.names[1..path.names_len]) |name| {
                    ptr[0] = '/';
                    ptr += 1;
                    for (name) |byte| {
                        ptr = strcpyEqu(ptr, stringLiteralChar(byte));
                    }
                }
            }
            ptr[0] = '"';
            return ptr + 1;
        }
        pub fn lengthLiteral(path: Path) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 2;
            if (path.names_len != 0) {
                for (path.names[0]) |byte| {
                    len +%= stringLiteralChar(byte).len;
                }
                for (path.names[1..path.names_len]) |name| {
                    len +%= 1;
                    for (name) |byte| {
                        len +%= stringLiteralChar(byte).len;
                    }
                }
            }
            return len;
        }
        pub fn formatWriteBufDisplayLiteral(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var tmp: [4096]u8 = undefined;
            var len: usize = format.formatWriteBufDisplay(&tmp);
            len -%= 1;
            return stringLiteral(tmp[0..len]).formatWriteBuf(buf);
        }
        pub fn write(buf: [*]u8, path: Path) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var ptr: [*]u8 = buf;
            if (path.names_len != 0) {
                ptr = strcpyEqu(ptr, path.names[0]);
                for (path.names[1..path.names_len]) |name| {
                    ptr[0] = '/';
                    ptr = strcpyEqu(ptr + 1, name);
                }
                ptr[0] = 0;
                ptr += 1;
            }
            return ptr;
        }
        pub fn length(path: Path) usize {
            var len: usize = 0;
            if (path.names_len != 0) {
                len +%= path.names[0].len;
                for (path.names[1..path.names_len]) |name| {
                    len +%= 1 +% name.len;
                }
                len +%= 1;
            }
            return len;
        }
        pub fn formatParseArgs(allocator: anytype, _: [][*:0]u8, _: *usize, arg: [:0]u8) Format {
            @setRuntimeSafety(builtin.is_safe);
            const names: [*][:0]u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
            names[0] = arg;
            return .{ .names = names, .names_len = 1, .names_max_len = 1 };
        }
    };
    return T;
}
pub const SourceLocationFormat = struct {
    value: builtin.SourceLocation,
    return_address: usize,
    const Format: type = @This();
    const LineColFormat = GenericPolynomialFormat(.{
        .bits = @bitSizeOf(usize),
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const AddrFormat = GenericPolynomialFormat(.{
        .bits = @bitSizeOf(usize),
        .signedness = .unsigned,
        .radix = 16,
        .width = .min,
        .prefix = "0x",
    });
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: usize = 4;
        @as(*[4]u8, @ptrCast(buf)).* = "\x1b[1m".*;
        len +%= strcpy(buf + len, file_name);
        buf[len] = ':';
        len +%= 1;
        len +%= line_fmt.formatWriteBuf(buf + len);
        buf[len] = ':';
        len +%= 1;
        len +%= column_fmt.formatWriteBuf(buf + len);
        @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
        len +%= 2;
        len +%= ret_addr_fmt.formatWriteBuf(buf + len);
        @as(*[4]u8, @ptrCast(buf + len)).* = " in ".*;
        len +%= 4;
        len +%= strcpy(buf + len, fn_name);
        @as(*[5]u8, @ptrCast(buf + len)).* = "\x1b[0m\n".*;
        return len +% 4;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        array.writeMany("\x1b[1m");
        array.writeMany(file_name);
        array.writeOne(':');
        array.writeFormat(line_fmt);
        array.writeOne(':');
        array.writeFormat(column_fmt);
        array.writeOne(':');
        array.writeFormat(ret_addr_fmt);
        array.writeMany(" in ");
        array.writeMany(fn_name);
        array.writeMany("\x1b[0m\n");
    }
    fn functionName(format: SourceLocationFormat) []const u8 {
        var start: u64 = 0;
        var idx: usize = 0;
        while (idx != format.value.fn_name.len) : (idx +%= 1) {
            if (format.value.fn_name[idx] == '.') start = idx;
        }
        return format.value.fn_name[start +% @intFromBool(start != 0) .. :0];
    }
    pub fn formatLength(format: SourceLocationFormat) usize {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: usize = 16;
        len +%= file_name.len;
        len +%= line_fmt.formatLength();
        len +%= column_fmt.formatLength();
        len +%= ret_addr_fmt.formatLength();
        len +%= fn_name.len;
        return len;
    }
    pub fn init(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
        return .{ .value = value, .return_address = ret_addr orelse @returnAddress() };
    }
};
pub const Bytes = packed struct {
    value: usize,
    const Format: type = @This();
    const MajorIntFormat = GenericPolynomialFormat(.{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const MinorIntFormat = GenericPolynomialFormat(.{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 10,
        .width = .{ .fixed = 3 },
    });
    const Pair = struct {
        int: mem.Bytes,
        rem: usize,
    };
    const units = meta.tagList(mem.Bytes.Unit);
    pub const max_len: ?comptime_int =
        MajorIntFormat.max_len.? +%
        MinorIntFormat.max_len.? +% 3; // Unit
    pub inline fn formatWrite(format: Format, array: anytype) void {
        return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
    }
    pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        return strlen(Format.write(buf, format.value), buf);
    }
    pub inline fn formatLength(format: Format) usize {
        return Format.length(format.value);
    }
    pub fn write(buf: [*]u8, count: usize) [*]u8 {
        @setRuntimeSafety(false);
        const res: Bytes.Pair = bytes(count);
        var ptr: [*]u8 = Bytes.MajorIntFormat.write(buf, res.int.count);
        if (res.rem != 0) {
            ptr[0] = '.';
            ptr = Bytes.MinorIntFormat.write(ptr + 1, (res.rem *% 1000) / 1024);
        }
        return strcpyEqu(ptr, @tagName(res.int.unit));
    }
    pub fn length(count: usize) usize {
        @setRuntimeSafety(false);
        const res: Bytes.Pair = bytes(count);
        var len: usize = Bytes.MajorIntFormat.formatLength(.{ .value = res.int.count });
        if (res.rem != 0) {
            len +%= 1;
            len +%= Bytes.MinorIntFormat.formatLength(.{ .value = (res.rem *% 1000) / 1024 });
        }
        return len +% @tagName(res.int.unit).len;
    }
};
pub fn bytes(count: usize) Bytes.Pair {
    @setRuntimeSafety(false);
    const max_idx: comptime_int = Bytes.units.len -% 1;
    var int: mem.Bytes = .{ .count = 0, .unit = .B };
    var rem: usize = 0;
    for (0..Bytes.units.len) |idx| {
        int.unit = Bytes.units[idx];
        var val: usize = count & (mem.Bytes.mask << @intFromEnum(int.unit));
        int.count = val >> @intFromEnum(int.unit);
        if (int.count != 0) {
            val = (count -% val) & (mem.Bytes.mask << @intFromEnum(Bytes.units[@min(idx +% 1, max_idx)]));
            val >>= @intFromEnum(Bytes.units[@min(idx +% 1, max_idx)]);
            rem = @intCast(val);
            break;
        }
    }
    return .{ .int = int, .rem = rem };
}
pub const ChangedIntFormatSpec = struct {
    old_fmt_spec: PolynomialFormatSpec,
    new_fmt_spec: PolynomialFormatSpec,
    del_fmt_spec: PolynomialFormatSpec,
    dec_style: []const u8 = "\x1b[91m-",
    inc_style: []const u8 = "\x1b[92m+",
    no_style: []const u8 = "\x1b[0m",
    arrow_style: []const u8 = " => ",
};
pub fn GenericChangedIntFormat(comptime fmt_spec: ChangedIntFormatSpec) type {
    const T = struct {
        old_value: Old,
        new_value: New,
        const Format: type = @This();
        const Old: type = @Type(.{ .Int = .{ .bits = fmt_spec.old_fmt_spec.bits, .signedness = fmt_spec.old_fmt_spec.signedness } });
        const New: type = @Type(.{ .Int = .{ .bits = fmt_spec.new_fmt_spec.bits, .signedness = fmt_spec.new_fmt_spec.signedness } });
        const OldIntFormat = GenericPolynomialFormat(fmt_spec.old_fmt_spec);
        const NewIntFormat = GenericPolynomialFormat(fmt_spec.new_fmt_spec);
        const DeltaIntFormat = GenericPolynomialFormat(fmt_spec.del_fmt_spec);
        const inc_s = fmt_spec.inc_style[0..fmt_spec.inc_style.len];
        const dec_s = fmt_spec.dec_style[0..fmt_spec.dec_style.len];
        const no_s = fmt_spec.no_style[0..fmt_spec.no_style.len];
        pub const max_len: ?comptime_int = OldIntFormat.max_len.? +% 1 +%
            DeltaIntFormat.max_len.? +% 5 +%
            fmt_spec.no_style.len +%
            NewIntFormat.max_len.? +%
            @max(fmt_spec.dec_style.len, fmt_spec.inc_style.len);
        pub fn formatWriteDelta(format: Format, array: anytype) void {
            return array.define(format.formatWriteDeltaBuf(@ptrCast(array.referOneUndefined())));
        }
        fn formatWriteDeltaBuf(format: Format, buf: [*]u8) usize {
            var len: usize = 0;
            if (format.old_value == format.new_value) {
                @as(*[4]u8, @ptrCast(buf)).* = "(+0)".*;
                len +%= 4;
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                buf[len] = '(';
                len +%= 1;
                @as(*[inc_s.len]u8, @ptrCast(buf + len)).* = inc_s.*;
                len +%= inc_s.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                @as(*[no_s.len]u8, @ptrCast(buf + len)).* = no_s.*;
                len +%= no_s.len;
                buf[len] = ')';
                len +%= 1;
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                buf[len] = '(';
                len +%= 1;
                @as(*[dec_s.len]u8, @ptrCast(buf + len)).* = dec_s.*;
                len +%= dec_s.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                @as(*[no_s.len]u8, @ptrCast(buf + len)).* = no_s.*;
                len +%= no_s.len;
                buf[len] = ')';
                len +%= 1;
            }
            return len;
        }
        fn formatLengthDelta(format: Format) usize {
            var len: usize = 0;
            if (format.old_value == format.new_value) {
                len +%= 4;
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                len +%= 1;
                len +%= inc_s.len;
                len +%= del_fmt.formatLength();
                len +%= no_s.len;
                len +%= 1;
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                len +%= 1;
                len +%= dec_s.len;
                len +%= del_fmt.formatLength();
                len +%= no_s.len;
                len +%= 1;
            }
            return len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            const old_fmt: OldIntFormat = .{ .value = format.old_value };
            const new_fmt: NewIntFormat = .{ .value = format.new_value };
            var len: usize = old_fmt.formatWriteBuf(buf);
            len +%= format.formatWriteDeltaBuf(buf + len);
            @memcpy(buf + len, fmt_spec.arrow_style);
            len +%= fmt_spec.arrow_style.len;
            len +%= new_fmt.formatWriteBuf(buf + len);
            return len;
        }
        pub fn formatLength(format: Format) usize {
            const old_fmt: OldIntFormat = .{ .value = format.old_value };
            const new_fmt: NewIntFormat = .{ .value = format.new_value };
            var len: usize = 0;
            len +%= old_fmt.formatLength();
            len +%= formatLengthDelta(format);
            len +%= 4;
            len +%= new_fmt.formatLength();
            return len;
        }
    };
    return T;
}
pub const ChangedBytesFormatSpec = struct {
    dec_style: []const u8 = "\x1b[91m-",
    inc_style: []const u8 = "\x1b[92m+",
    no_style: []const u8 = "\x1b[0m",
    to_from_zero: bool = false,
};
pub fn GenericChangedBytesFormat(comptime fmt_spec: ChangedBytesFormatSpec) type {
    const T = struct {
        old_value: usize,
        new_value: usize,
        const Format: type = @This();
        const inc_s = fmt_spec.inc_style[0..fmt_spec.inc_style.len];
        const dec_s = fmt_spec.dec_style[0..fmt_spec.dec_style.len];
        const no_s = fmt_spec.no_style[0..fmt_spec.no_style.len];
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(Format.write(buf, format.old_value, format.new_value), buf);
        }
        pub inline fn formatLength(format: Format) usize {
            return length(format.old_value, format.new_value);
        }
        fn writeFull(buf: [*]u8, old_count: usize, new_count: usize) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            var ptr: [*]u8 = Bytes.write(buf, old_count);
            if (old_count != new_count) {
                if (new_count > old_count) {
                    ptr = writeStyledChange(ptr, new_count -% old_count, inc_s);
                } else {
                    ptr = writeStyledChange(ptr, old_count -% new_count, dec_s);
                }
                ptr[0..4].* = " => ".*;
                ptr = Bytes.write(ptr + 4, new_count);
            }
            return ptr;
        }
        fn lengthFull(old_count: usize, new_count: usize) usize {
            var len: usize = Bytes.length(old_count);
            if (old_count != new_count) {
                if (new_count > old_count) {
                    len +%= lengthStyledChange(new_count -% old_count, inc_s);
                } else {
                    len +%= lengthStyledChange(old_count -% new_count, dec_s);
                }
                len +%= 4 +% Bytes.length(new_count);
            }
            return len;
        }
        fn writeStyledChange(buf: [*]u8, count: usize, style_s: []const u8) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            buf[0] = '(';
            var ptr: [*]u8 = strcpyEqu(buf + 1, style_s);
            ptr = Bytes.write(ptr, count);
            ptr = strcpyEqu(ptr, no_s);
            ptr[0] = ')';
            return ptr + 1;
        }
        fn lengthStyledChange(count: usize, style_s: []const u8) usize {
            return 1 +% style_s.len +% Bytes.length(count) +% no_s.len +% 1;
        }
        pub fn write(buf: [*]u8, old_count: usize, new_count: usize) [*]u8 {
            @setRuntimeSafety(builtin.is_safe);
            if (fmt_spec.to_from_zero) {
                return writeFull(buf, old_count, new_count);
            } else {
                if (old_count == 0) {
                    return writeStyledChange(buf, new_count, fmt_spec.inc_style);
                } else if (new_count == 0) {
                    return writeStyledChange(buf, old_count, fmt_spec.dec_style);
                } else {
                    return writeFull(buf, old_count, new_count);
                }
            }
        }
        pub fn length(old_count: usize, new_count: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (fmt_spec.to_from_zero) {
                return lengthFull(old_count, new_count);
            } else {
                if (old_count == 0) {
                    return lengthStyledChange(new_count, fmt_spec.inc_style);
                } else if (new_count == 0) {
                    return lengthStyledChange(old_count, fmt_spec.dec_style);
                } else {
                    return lengthFull(old_count, new_count);
                }
            }
        }
        pub fn init(old_value: u64, new_value: u64) Format {
            return .{ .old_value = old_value, .new_value = new_value };
        }
    };
    return T;
}
pub fn GenericRangeFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    const T = struct {
        lower: SubFormat.Int,
        upper: SubFormat.Int,
        const Format: type = @This();
        pub const spec: PolynomialFormatSpec = fmt_spec;
        pub const SubFormat = GenericPolynomialFormat(blk: {
            var tmp: PolynomialFormatSpec = fmt_spec;
            tmp.prefix = null;
            break :blk tmp;
        });
        pub const max_len: ?comptime_int = (SubFormat.max_len.? *% 2) +% 4;
        pub fn formatLength(format: Format) usize {
            const lower_fmt: SubFormat = SubFormat{ .value = format.lower };
            const upper_fmt: SubFormat = SubFormat{ .value = format.upper };
            const lower_s: SubFormat.StaticString = lower_fmt.formatConvert();
            const upper_s: SubFormat.StaticString = upper_fmt.formatConvert();
            const lower_s_count: u64 = lower_s.len();
            const upper_s_count: u64 = upper_s.len();
            const len: usize = if (fmt_spec.prefix) |prefix| prefix.len else 0;
            for (lower_s.readAll(), 0..) |v, idx| {
                if (v != upper_s.readOneAt(idx)) {
                    return len +% (upper_s_count -% lower_s_count) +% idx +% 1 +% (lower_s_count -% idx) +% 2 +% (upper_s_count -% idx) +% 1;
                }
            }
            return len +% (upper_s_count -% lower_s_count) +% lower_s.len() +% 4;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            const lower_fmt: SubFormat = SubFormat{ .value = format.lower };
            const upper_fmt: SubFormat = SubFormat{ .value = format.upper };
            const lower_s: SubFormat.StaticString = lower_fmt.formatConvert();
            const upper_s: SubFormat.StaticString = upper_fmt.formatConvert();
            var idx: usize = 0;
            if (fmt_spec.prefix) |prefix| {
                array.writeMany(prefix);
            }
            const lower_s_count: u64 = lower_s.len();
            const upper_s_count: u64 = upper_s.len();
            while (idx != lower_s_count) : (idx +%= 1) {
                if (upper_s.readOneAt(idx) != lower_s.readOneAt(idx)) {
                    break;
                }
            }
            array.writeMany(upper_s.readAll()[0..idx]);
            array.writeOne('{');
            var del: u64 = upper_s_count -% lower_s_count;
            while (del != 0) : (del -%= 1) {
                array.writeOne('0');
            }
            array.writeMany(lower_s.readAll()[idx..lower_s_count]);
            array.writeMany("..");
            array.writeMany(upper_s.readAll()[idx..upper_s_count]);
            array.writeOne('}');
        }
        pub fn init(lower: SubFormat.Int, upper: SubFormat.Int) Format {
            return .{ .lower = lower, .upper = upper };
        }
    };
    return T;
}
pub const AddressRangeFormat = GenericRangeFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 16,
    .width = .min,
    .prefix = "0x",
});
pub fn GenericArenaRangeFormat(comptime arena_idx: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .idx = arena_idx };
    return GenericRangeFormat(.{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .max,
        .range = .{
            .min = arena.begin(),
            .max = arena.end(),
        },
        .prefix = "0x",
    });
}
pub const ChangedAddressRangeFormat = GenericChangedRangeFormat(.{
    .new_fmt_spec = AddressRangeFormat.spec,
    .old_fmt_spec = AddressRangeFormat.spec,
    .del_fmt_spec = .{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .min,
        .prefix = "0x",
    },
});
pub fn GenericChangedArenaRangeFormat(comptime arena_idx: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .idx = arena_idx };
    const int_fmt_spec: PolynomialFormatSpec = .{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .max,
        .range = .{ .min = arena.begin(), .max = arena.end() },
        .prefix = "0x",
    };
    return GenericChangedRangeFormat(.{
        .new_fmt_spec = int_fmt_spec,
        .old_fmt_spec = int_fmt_spec,
        .del_fmt_spec = .{
            .bits = 64,
            .signedness = .unsigned,
            .radix = 16,
            .width = .min,
            .range = .{ .max = arena.end() },
        },
        .prefix = "0x",
    });
}
pub const ChangedRangeFormatSpec = struct {
    old_fmt_spec: PolynomialFormatSpec,
    new_fmt_spec: PolynomialFormatSpec,
    del_fmt_spec: PolynomialFormatSpec,
    lower_inc_style: []const u8 = "\x1b[92m+",
    lower_dec_style: []const u8 = "\x1b[91m-",
    upper_inc_style: []const u8 = "\x1b[92m+",
    upper_dec_style: []const u8 = "\x1b[91m-",
    arrow_style: []const u8 = " => ",
};
pub fn GenericChangedRangeFormat(comptime fmt_spec: ChangedRangeFormatSpec) type {
    const T = struct {
        old_lower: OldGenericPolynomialFormat.Int,
        old_upper: OldGenericPolynomialFormat.Int,
        new_lower: NewGenericPolynomialFormat.Int,
        new_upper: NewGenericPolynomialFormat.Int,
        const Format: type = @This();
        const OldGenericPolynomialFormat = GenericPolynomialFormat(fmt_spec.old_fmt_spec);
        const NewGenericPolynomialFormat = GenericPolynomialFormat(fmt_spec.new_fmt_spec);
        const DelGenericPolynomialFormat = GenericPolynomialFormat(fmt_spec.del_fmt_spec);
        const LowerChangedIntFormat = GenericChangedIntFormat(.{
            .old_fmt_spec = fmt_spec.old_fmt_spec,
            .new_fmt_spec = fmt_spec.new_fmt_spec,
            .del_fmt_spec = fmt_spec.del_fmt_spec,
            .dec_style = fmt_spec.lower_dec_style,
            .inc_style = fmt_spec.lower_inc_style,
            .arrow_style = fmt_spec.arrow_style,
        });
        const UpperChangedIntFormat = GenericChangedIntFormat(.{
            .old_fmt_spec = fmt_spec.old_fmt_spec,
            .new_fmt_spec = fmt_spec.new_fmt_spec,
            .del_fmt_spec = fmt_spec.del_fmt_spec,
            .dec_style = fmt_spec.upper_dec_style,
            .inc_style = fmt_spec.upper_inc_style,
            .arrow_style = fmt_spec.arrow_style,
        });
        pub fn formatWrite(format: Format, array: anytype) void {
            const old_lower_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_lower };
            const old_upper_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_upper };
            const old_lower_s: OldGenericPolynomialFormat.StaticString = old_lower_fmt.formatConvert();
            const old_upper_s: OldGenericPolynomialFormat.StaticString = old_upper_fmt.formatConvert();
            const new_lower_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_lower };
            const new_upper_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_upper };
            const new_lower_s: NewGenericPolynomialFormat.StaticString = new_lower_fmt.formatConvert();
            const new_upper_s: NewGenericPolynomialFormat.StaticString = new_upper_fmt.formatConvert();
            const lower_del_fmt: LowerChangedIntFormat = .{ .old_value = format.old_lower, .new_value = format.new_lower };
            const upper_del_fmt: UpperChangedIntFormat = .{ .old_value = format.old_upper, .new_value = format.new_upper };
            var idx: usize = 0;
            const old_lower_s_count: usize = old_lower_s.len();
            const old_upper_s_count: usize = old_upper_s.len();
            while (idx != old_lower_s_count) : (idx +%= 1) {
                if (old_upper_s.readOneAt(idx) != old_lower_s.readOneAt(idx)) {
                    break;
                }
            }
            array.writeMany(old_upper_s.readAll()[0..idx]);
            array.writeOne('{');
            var x: u64 = old_upper_s_count -% old_lower_s_count;
            while (x != 0) : (x -%= 1) array.writeOne('0');
            array.writeMany(old_lower_s.readAll()[idx..old_lower_s_count]);
            if (format.old_lower != format.new_lower) {
                lower_del_fmt.formatWriteDelta(array);
            }
            array.writeMany("..");
            array.writeMany(old_upper_s.readAll()[idx..old_upper_s_count]);
            if (format.old_upper != format.new_upper) {
                upper_del_fmt.formatWriteDelta(array);
            }
            array.writeOne('}');
            array.writeMany(" => ");
            idx = 0;
            const new_lower_s_count: u64 = new_lower_s.len();
            const new_upper_s_count: u64 = new_upper_s.len();
            while (idx != new_lower_s_count) : (idx +%= 1) {
                if (new_upper_s.readOneAt(idx) != new_lower_s.readOneAt(idx)) {
                    break;
                }
            }
            array.writeMany(new_upper_s.readAll()[0..idx]);
            array.writeOne('{');
            var y: u64 = new_upper_s_count -% new_lower_s_count;
            while (y != 0) : (y -%= 1) array.writeOne('0');
            array.writeMany(new_lower_s.readAll()[idx..new_lower_s_count]);
            array.writeMany("..");
            array.writeMany(new_upper_s.readAll()[idx..new_upper_s_count]);
            array.writeOne('}');
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            const old_lower_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_lower };
            const old_upper_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_upper };
            const old_lower_s: OldGenericPolynomialFormat.StaticString = old_lower_fmt.formatConvert();
            const old_upper_s: OldGenericPolynomialFormat.StaticString = old_upper_fmt.formatConvert();
            const new_lower_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_lower };
            const new_upper_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_upper };
            const new_lower_s: NewGenericPolynomialFormat.StaticString = new_lower_fmt.formatConvert();
            const new_upper_s: NewGenericPolynomialFormat.StaticString = new_upper_fmt.formatConvert();
            const lower_del_fmt: LowerChangedIntFormat = .{ .old_value = format.old_lower, .new_value = format.new_lower };
            const upper_del_fmt: UpperChangedIntFormat = .{ .old_value = format.old_upper, .new_value = format.new_upper };
            var idx: usize = 0;
            const old_lower_s_count: usize = old_lower_s.len();
            const old_upper_s_count: usize = old_upper_s.len();
            while (idx != old_lower_s_count) : (idx +%= 1) {
                if (old_upper_s.readOneAt(idx) != old_lower_s.readOneAt(idx)) {
                    break;
                }
            }
            len +%= idx +% 1;
            len +%= old_upper_s_count -% old_lower_s_count;
            len +%= old_lower_s_count -% idx;
            if (format.old_lower != format.new_lower) {
                len +%= lower_del_fmt.formatLengthDelta();
            }
            len +%= 2;
            len +%= old_upper_s_count -% idx;
            if (format.old_upper != format.new_upper) {
                len +%= upper_del_fmt.formatLengthDelta();
            }
            len +%= 5;
            idx = 0;
            const new_lower_s_count: u64 = new_lower_s.len();
            const new_upper_s_count: u64 = new_upper_s.len();
            while (idx != new_lower_s_count) : (idx +%= 1) {
                if (new_upper_s.readOneAt(idx) != new_lower_s.readOneAt(idx)) {
                    break;
                }
            }
            len +%= idx +% 1;
            len +%= new_upper_s_count -% new_lower_s_count;
            len +%= new_lower_s_count -% idx;
            len +%= 2;
            len +%= new_upper_s_count -% idx;
            len +%= 1;
            return len;
        }
        pub fn init(
            old_lower: OldGenericPolynomialFormat.Int,
            old_upper: OldGenericPolynomialFormat.Int,
            new_lower: NewGenericPolynomialFormat.Int,
            new_upper: NewGenericPolynomialFormat.Int,
        ) Format {
            return .{
                .old_lower = old_lower,
                .old_upper = old_upper,
                .new_lower = new_lower,
                .new_upper = new_upper,
            };
        }
    };
    return T;
}
pub const DateTimeFormatSpec = struct {
    month: type = Month,
    month_day: type = MonthDay,
    year: type = Year,
    hour: type = Hour,
    minute: type = Minute,
    second: type = Second,
};
pub fn GenericDateTimeFormat(comptime dt_spec: DateTimeFormatSpec) type {
    const T = struct {
        value: time.DateTime,
        const Format: type = @This();
        pub const max_len: ?comptime_int = 19;
        pub fn write(buf: [*]u8, date: time.DateTime) [*]u8 {
            var ptr: [*]u8 = dt_spec.year.write(buf, date.year);
            ptr[0] = '-';
            ptr = dt_spec.month.write(ptr + 1, @intFromEnum(date.mon));
            ptr[0] = '-';
            ptr = dt_spec.month_day.write(ptr + 1, date.mday);
            ptr[0] = ' ';
            ptr = dt_spec.hour.write(ptr + 1, date.hour);
            ptr[0] = ':';
            ptr = dt_spec.minute.write(ptr + 1, date.min);
            ptr[0] = ':';
            return dt_spec.second.write(ptr + 1, date.sec);
        }
        pub fn length(date: time.DateTime) usize {
            var len: usize = 5 +% dt_spec.year.length(date.year);
            len +%= dt_spec.mont.length(date.month);
            len +%= dt_spec.month_day.length(date.month_day);
            len +%= dt_spec.hour.length(date.hour);
            len +%= dt_spec.minute.length(date.min);
            return dt_spec.second.length(date.sec);
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub const LazyIdentifierFormat = struct {
    value: []const u8,
    const Format = @This();
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        const str: StringLiteralFormat = .{ .value = format.value };
        buf[0] = '@';
        const len: usize = str.formatWriteBuf(buf + 1);
        return 1 +% len;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeOne('@');
        array.writeFormat(StringLiteralFormat{ .value = format.value });
    }
    pub fn formatLength(format: Format) usize {
        const str: StringLiteralFormat = .{ .value = format.value };
        return str.formatLength() +% 1;
    }
};
pub const IdentifierFormat = struct {
    value: []const u8,
    const Format: type = @This();
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        if (isValidId(format.value)) {
            @memcpy(buf, format.value);
            len +%= format.value.len;
        } else {
            @as(*[2]u8, @ptrCast(buf + len)).* = "@\"".*;
            len +%= 2;
            @memcpy(buf + len, format.value);
            len +%= format.value.len;
            buf[len] = '"';
            len +%= 1;
        }
        return len;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        if (isValidId(format.value)) {
            array.writeMany(format.value);
        } else {
            array.writeMany("@\"");
            array.writeMany(format.value);
            array.writeMany("\"");
        }
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 0;
        if (isValidId(format.value)) {
            len +%= format.value.len;
        } else {
            len +%= 2;
            len +%= format.value.len;
            len +%= 1;
        }
        return len;
    }
};
pub fn GenericPrettyFormatAddressSpaceHierarchy(comptime ToplevelAddressSpace: type) type {
    return (struct {
        value: ToplevelAddressSpace,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            _ = array;
            _ = format;
        }
        pub fn formatLength(format: Format) void {
            _ = format;
        }
    });
}
pub fn isValidId(name: []const u8) bool {
    @setRuntimeSafety(builtin.is_safe);
    if (name.len == 0) {
        return false;
    }
    const byte: u8 = name[0];
    if (name.len == 1 and byte == '_') {
        return false;
    }
    if (byte >= '0' and byte <= '9') {
        return false;
    }
    var idx: usize = 0;
    if (byte == 'i' or byte == 'u') {
        idx +%= 1;
        while (idx != name.len) : (idx +%= 1) {
            switch (name[idx]) {
                '0'...'9' => {
                    continue;
                },
                '_', 'a'...'z', 'A'...'Z' => {
                    break;
                },
                else => {
                    return false;
                },
            }
        } else return false;
    }
    while (idx != name.len) : (idx +%= 1) {
        switch (name[idx]) {
            '0'...'9', '_', 'a'...'z', 'A'...'Z' => {
                continue;
            },
            else => return false,
        }
    }
    return builtin.parse.keyword(name) == null;
}
pub fn highlight(tok: *const builtin.parse.Token, syntax: []const debug.Trace.Options.Tokens.Mapping) ?[]const u8 {
    @setRuntimeSafety(false);
    for (syntax) |pair| {
        for (pair.tags) |tag| {
            if (tok.tag == tag) {
                return pair.style;
            }
        }
    }
    return null;
}
pub const SourceCodeFormat = struct {
    src: [:0]const u8,
    pub fn write(buf: [*]u8, src: [:0]const u8) [*]u8 {
        if (builtin.trace.options.tokens.syntax) |syntax| {
            var itr: builtin.parse.TokenIterator = .{ .buf = @constCast(src), .buf_pos = 0 };
            var tok: builtin.parse.Token = itr.nextToken();
            var ptr: [*]u8 = buf;
            var prev: usize = 0;
            while (tok.tag != .eof) : (itr.nextExtra(&tok)) {
                const str: []const u8 = itr.buf[tok.loc.start..tok.loc.finish];
                ptr = strcpyEqu(ptr, itr.buf[prev..tok.loc.start]);
                if (highlight(&tok, syntax)) |style| {
                    ptr = strcpyEqu(ptr, style);
                }
                ptr = strcpyEqu(ptr, str);
                ptr = strcpyEqu(ptr, &tab.fx.none);
                prev = tok.loc.finish;
            }
            return ptr;
        } else {
            return strcpyEqu(buf, src);
        }
    }
    pub fn length(src: [:0]const u8) usize {
        if (builtin.trace.options.tokens.syntax) |syntax| {
            var itr: builtin.parse.TokenIterator = .{ .buf = @constCast(src), .buf_pos = 0 };
            var tok: builtin.parse.Token = itr.nextToken();
            var len: usize = 0;
            var prev: usize = 0;
            while (tok.tag != .eof) : (itr.nextExtra(&tok)) {
                if (highlight(&tok, syntax)) |style| {
                    len +%= style.len;
                }
                len +%= itr.buf[prev..tok.loc.start].len +%
                    (tok.loc.finish -% tok.loc.start) +% tab.fx.none.len;
                prev = tok.loc.finish;
            }
            return len;
        } else {
            return src.len;
        }
    }
};
pub inline fn typeName(comptime T: type) []const u8 {
    const type_info: builtin.Type = @typeInfo(T);
    const type_name: [:0]const u8 = @typeName(T);
    switch (type_info) {
        .Pointer => |pointer_info| {
            return typeDeclSpecifier(type_info) ++ typeName(pointer_info.child);
        },
        .Array => |array_info| {
            return typeDeclSpecifier(type_info) ++ typeName(array_info.child);
        },
        .Struct => {
            return typeNameDemangle(type_name, "__struct");
        },
        .Enum => {
            return typeNameDemangle(type_name, "__enum");
        },
        .Union => {
            return typeNameDemangle(type_name, "__union");
        },
        .Opaque => {
            return typeNameDemangle(type_name, "__opaque");
        },
        else => return type_name,
    }
}
inline fn typeNameDemangle(comptime type_name: []const u8, comptime decl_name: []const u8) []const u8 {
    comptime {
        var ret: []const u8 = type_name;
        var idx: u64 = type_name.len;
        while (idx != 0) {
            idx -%= 1;
            if (type_name[idx] == '_') {
                break;
            }
            if (type_name[idx] < '0' or
                type_name[idx] > '9')
            {
                return type_name;
            }
        }
        const serial = idx;
        ret = type_name[0..idx];
        if (ret.len < decl_name.len) {
            return type_name;
        }
        idx = ret.len -% decl_name.len;
        while (idx != ret.len) : (idx +%= 1) {
            if (ret[idx] != decl_name[idx]) {
                return type_name;
            }
        }
        idx -%= decl_name.len;
        return ret[0..idx] ++ type_name[serial..];
    }
}
pub fn typeTypeName(comptime type_id: builtin.TypeId) []const u8 {
    return switch (type_id) {
        .zig.Type => "type",
        .Void => "void",
        .Bool => "bool",
        .NoReturn => "noreturn",
        .Int => "integer",
        .Float => "float",
        .Pointer => "pointer",
        .Array => "array",
        .Struct => "struct",
        .ComptimeFloat => "comptime_float",
        .ComptimeInt => "comptime_int",
        .Undefined => "undefined",
        .Null => "null",
        .Optional => "optional",
        .ErrorUnion => "error union",
        .ErrorSet => "error set",
        .Enum => "enum",
        .Union => "union",
        .Fn => "function",
        .Opaque => "opaque",
        .Frame => "frame",
        .AnyFrame => "anyframe",
        .Vector => "vector",
        .EnumLiteral => "enum literal",
    };
}
pub inline fn typeDeclSpecifier(comptime type_info: builtin.Type) []const u8 {
    switch (type_info) {
        .Array, .Pointer, .Optional => {
            const type_name: []const u8 = @typeName(@Type(type_info));
            const child_type_name: []const u8 = @typeName(@field(type_info, @tagName(type_info)).child);
            return type_name[0 .. type_name.len -% child_type_name.len];
        },
        .Enum => |enum_info| {
            return "enum(" ++ @typeName(enum_info.tag_type) ++ ")";
        },
        .Struct => |struct_info| {
            switch (struct_info.layout) {
                .Packed => {
                    if (struct_info.backing_integer) |backing_integer| {
                        return "packed struct(" ++ @typeName(backing_integer) ++ ")";
                    } else {
                        return "packed struct";
                    }
                },
                .Extern => return "extern struct",
                .Auto => return "struct",
            }
        },
        .Union => |union_info| {
            switch (union_info.layout) {
                .Packed => {
                    if (union_info.tag_type != null) {
                        return "packed union(enum)";
                    } else {
                        return "packed union";
                    }
                },
                .Extern => return "extern union",
                .Auto => {
                    if (union_info.tag_type != null) {
                        return "union(enum)";
                    } else {
                        return "union";
                    }
                },
            }
        },
        .Opaque => return "opaque",
        .ErrorSet => return "error",
        else => @compileError(@typeName(@Type(type_info))),
    }
}
const EscapedStringFormatSpec = struct {
    single_quote: []const u8 = "\'",
    double_quote: []const u8 = "\\\"",
    open_quote: ?[]const u8 = "\"",
    close_quote: ?[]const u8 = "\"",
};
pub fn GenericEscapedStringFormat(comptime fmt_spec: EscapedStringFormatSpec) type {
    const T = struct {
        value: []const u8,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            if (fmt_spec.open_quote) |open_quote| {
                array.writeMany(open_quote);
            }
            for (format.value) |byte| {
                switch (byte) {
                    else => array.writeFormat(esc(byte)),
                    '\n' => array.writeMany("\\n"),
                    '\r' => array.writeMany("\\r"),
                    '\t' => array.writeMany("\\t"),
                    '\\' => array.writeMany("\\\\"),
                    '"' => array.writeMany(fmt_spec.double_quote),
                    '\'' => array.writeMany(fmt_spec.single_quote),
                    ' ', '!', '#'...'&', '('...'[', ']'...'~' => {
                        array.writeOne(byte);
                    },
                }
            }
            if (fmt_spec.close_quote) |close_quote| {
                array.writeMany(close_quote);
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            var len: usize = 0;
            if (fmt_spec.open_quote) |open_quote| {
                const OQ = [open_quote.len]u8;
                const dest: *OQ = @ptrCast(buf + len);
                const src: *const OQ = @ptrCast(open_quote.ptr);
                dest.* = src.*;
                len +%= open_quote.len;
            }
            const DQ = [fmt_spec.double_quote.len]u8;
            const SQ = [fmt_spec.single_quote.len]u8;
            for (format.value) |byte| {
                switch (byte) {
                    else => len +%= esc(byte).formatWriteBuf(buf),
                    '\n' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\n".*;
                        len +%= 2;
                    },
                    '\r' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\r".*;
                        len +%= 2;
                    },
                    '\t' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\t".*;
                        len +%= 2;
                    },
                    '\\' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\\\".*;
                        len +%= 2;
                    },
                    '"' => {
                        const dest: *DQ = @ptrCast(buf + len);
                        const src: *const DQ = @ptrCast(fmt_spec.double_quote.ptr);
                        dest.* = src.*;
                        len +%= fmt_spec.double_quote.len;
                    },
                    '\'' => {
                        const dest: *SQ = @ptrCast(buf + len);
                        const src: *const SQ = @ptrCast(fmt_spec.single_quote.ptr);
                        dest.* = src.*;
                        len +%= fmt_spec.single_quote.len;
                    },
                    ' ', '!', '#'...'&', '('...'[', ']'...'~' => {
                        buf[len] = byte;
                        len +%= 1;
                    },
                }
            }
            if (fmt_spec.close_quote) |close_quote| {
                const CQ = [close_quote.len]u8;
                const dest: *CQ = @ptrCast(buf + len);
                const src: *const CQ = @ptrCast(close_quote.ptr);
                dest.* = src.*;
                len +%= close_quote.len;
            }
            return len;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (fmt_spec.open_quote) |open_quote| {
                len +%= open_quote.len;
            }
            for (format.value) |byte| {
                switch (byte) {
                    else => len +%= esc(byte).formatLength(),
                    '\n' => len +%= "\\n".len,
                    '\r' => len +%= "\\r".len,
                    '\t' => len +%= "\\t".len,
                    '\\' => len +%= "\\\\".len,
                    '"' => len +%= fmt_spec.double_quote.len,
                    '\'' => len +%= fmt_spec.single_quote.len,
                    ' ', '!', '#'...'&', '('...'[', ']'...'~' => {
                        len +%= 1;
                    },
                }
            }
            if (fmt_spec.close_quote) |close_quote| {
                len +%= close_quote.len;
            }
            return len;
        }
    };
    return T;
}
pub fn GenericLEB128Format(comptime Int: type) type {
    const bit_size_of: comptime_int = @bitSizeOf(Int);
    return extern struct {
        value: Int,
        const Format = @This();
        pub fn write(buf: [*]u8, int: Int) [*]u8 {
            var ptr: [*]u8 = buf;
            if (@typeInfo(Int).Int.signedness == .signed) {
                const Abs = @Type(.{ .Int = .{
                    .signedness = .unsigned,
                    .bits = bit_size_of,
                } });
                var value: Int = int;
                while (true) {
                    const uvalue: Abs = @bitCast(value);
                    const byte: u8 = @truncate(uvalue);
                    value >>= 6;
                    if (value == -1 or value == 0) {
                        ptr[0] = byte & 0x7f;
                        ptr += 1;
                        break;
                    } else {
                        value >>= 1;
                        ptr[0] = byte | 0x80;
                        ptr += 1;
                    }
                }
            } else {
                var value: Int = int;
                while (true) {
                    const byte: u8 = @truncate(value & 0x7f);
                    value >>= 7;
                    if (value == 0) {
                        ptr[0] = byte;
                        ptr += 1;
                        break;
                    } else {
                        ptr[0] = byte | 0x80;
                        ptr += 1;
                    }
                }
            }
            return ptr;
        }
        pub fn length(int: Int) usize {
            var len: usize = 0;
            if (@typeInfo(Int).Int.signedness == .signed) {
                var value: Int = int;
                while (true) {
                    value >>= 6;
                    if (value == -1 or value == 0) {
                        len +%= 1;
                        break;
                    } else {
                        value >>= 1;
                        len +%= 1;
                    }
                }
            } else {
                var value: Int = int;
                while (true) {
                    value >>= 7;
                    if (value == 0) {
                        len +%= 1;
                        break;
                    } else {
                        len +%= 1;
                    }
                }
            }
            return len;
        }
        pub usingnamespace Interface(Format);
    };
}
pub fn writeUnsignedFixedLEB128(comptime width: usize, ptr: *[width]u8, int: @Type(.{ .Int = .{
    .signedness = .unsigned,
    .bits = width *% 7,
} })) void {
    const T = @TypeOf(int);
    const U = if (@typeInfo(T).Int.bits < 8) u8 else T;
    var value: U = @intCast(int);
    var idx: usize = 0;
    while (idx != width -% 1) : (idx +%= 1) {
        const byte: u8 = @as(u8, @truncate(value)) | 0x80;
        value >>= 7;
        ptr[idx] = byte;
    }
    ptr[idx] = @as(u8, @truncate(value));
}
pub inline fn toStringLiteral(comptime str: []const u8) []const u8 {
    comptime {
        var ret: []const u8 = &.{};
        for (str) |byte| {
            ret = ret ++ stringLiteralChar(byte);
        }
        return ret;
    }
}
pub fn toCamelCases(noalias buf: []u8, names: []const []const u8) []u8 {
    var len: usize = 0;
    var state: bool = false;
    for (names) |name| {
        for (name) |c| {
            if (c == '_' or c == '.') {
                state = true;
            } else {
                if (state) {
                    buf[len] = c -% ('a' -% 'A');
                    state = false;
                } else {
                    buf[len] = c;
                }
                len +%= 1;
            }
        }
        state = true;
    }
    return buf[0..len];
}
pub fn toCamelCase(noalias buf: []u8, name: []const u8) []u8 {
    var state: bool = false;
    var len: usize = 0;
    for (name) |c| {
        if (c == '_' or c == '.') {
            state = true;
        } else {
            if (state) {
                buf[len] = c -% ('a' -% 'A');
                state = false;
            } else {
                buf[len] = c;
            }
            len +%= 1;
        }
    }
    return buf[0..len];
}
pub fn toTitlecases(noalias buf: []u8, names: []const []const u8) []u8 {
    const rename: []u8 = toCamelCases(buf, names);
    if (rename[0] >= 'a') {
        rename[0] -%= ('a' -% 'A');
    }
    return rename;
}
pub fn toTitlecase(noalias buf: []u8, name: []const u8) []u8 {
    const rename: []u8 = toCamelCase(buf, name);
    if (rename[0] >= 'a') {
        rename[0] -%= ('a' -% 'A');
    }
    return rename;
}
pub fn untitle(noalias buf: []u8, noalias name: []const u8) []u8 {
    @memcpy(buf.ptr, name);
    if (buf[0] >= 'a') {
        buf[0] +%= ('a' -% 'A');
    }
    return buf[0..name.len];
}
pub fn lowerCase(name: []const u8) LowerCaseFormat {
    return .{ .value = name };
}
pub const UpperCaseFormat = struct {
    value: []const u8,
    const Format = @This();
    pub fn write(buf: [*]u8, string: []const u8) [*]u8 {
        for (string, 0..) |byte, idx| {
            buf[idx] = switch (byte) {
                'a'...'z' => byte -% ('a' -% 'A'),
                else => byte,
            };
        }
        return buf + string.len;
    }
    pub fn length(string: []const u8) usize {
        return string.len;
    }
    pub usingnamespace Interface(Format);
};
pub const LowerCaseFormat = struct {
    value: []const u8,
    const Format = @This();
    pub fn write(buf: [*]u8, string: []const u8) [*]u8 {
        for (string, 0..) |byte, idx| {
            buf[idx] = switch (byte) {
                'A'...'Z' => byte +% ('a' -% 'A'),
                else => byte,
            };
        }
        return buf + string.len;
    }
    pub fn length(string: []const u8) usize {
        return string.len;
    }
    pub usingnamespace Interface(Format);
};
/// .{ 0xff, 0xff, 0xff, 0xff } => "ffffffff";
pub fn bytesToHex(dest: []u8, src: []const u8) []const u8 {
    var idx: usize = 0;
    const max_idx: usize = @min(dest.len / 2, src.len);
    while (idx != max_idx) : (idx +%= 1) {
        dest[idx *% 2 +% 0] = toSymbol(u8, src[idx] / 16, 16);
        dest[idx *% 2 +% 1] = toSymbol(u8, src[idx] & 15, 16);
    }
    return dest[0 .. src.len *% 2];
}
pub fn hexToBytes(dest: []u8, src: []const u8) ![]const u8 {
    if (src.len & 1 != 0) {
        return error.InvalidLength;
    }
    if (dest.len * 2 < src.len) {
        return error.NoSpaceLeft;
    }
    var idx: usize = 0;
    while (idx < src.len) : (idx +%= 2) {
        dest[idx / 2] =
            try parse.fromSymbolChecked(u8, src[idx], 16) << 4 |
            try parse.fromSymbolChecked(u8, src[idx +% 1], 16);
    }
    return dest[0 .. idx / 2];
}
/// "ffffffff" => .{ 0xff, 0xff, 0xff, 0xff };
pub fn hexToBytes2(dest: []u8, src: []const u8) []const u8 {
    var idx: usize = 0;
    while (idx < src.len) : (idx +%= 2) {
        dest[idx / 2] =
            parse.fromSymbol(src[idx], 16) << 4 |
            parse.fromSymbol(src[idx +% 1], 16);
    }
    return dest[0 .. idx / 2];
}
pub const static = struct {
    inline fn concatUpper(comptime s: []const u8, comptime c: u8) []const u8 {
        comptime {
            switch (c) {
                'a'...'z' => return s ++ [1]u8{c -% ('a' -% 'A')},
                else => return s ++ [1]u8{c},
            }
        }
    }
    pub inline fn toInitialism(comptime names: []const []const u8) []const u8 {
        comptime {
            var ret: []const u8 = meta.empty;
            var state: bool = false;
            for (names) |name| {
                for (name) |c| {
                    if (c == '_' or c == '.') {
                        state = true;
                    } else if (state) {
                        ret = concatUpper(ret, c);
                        state = false;
                    }
                }
                state = true;
            }
            return static.toTitlecase(ret);
        }
    }
    pub inline fn toCamelCases(comptime names: []const []const u8) []const u8 {
        comptime {
            var ret: []const u8 = meta.empty;
            var state: bool = false;
            for (names) |name| {
                for (name) |c| {
                    if (c == '_' or c == '.') {
                        state = true;
                    } else if (state) {
                        ret = concatUpper(ret, c);
                        state = false;
                    } else {
                        ret = ret ++ [1]u8{c};
                    }
                }
                state = true;
            }
            return ret;
        }
    }
    pub inline fn toCamelCase(comptime name: []const u8) []const u8 {
        comptime {
            var ret: []const u8 = meta.empty;
            var state: bool = false;
            for (name) |c| {
                if (c == '_' or c == '.') {
                    state = true;
                } else if (state) {
                    ret = concatUpper(ret, c);
                    state = false;
                } else {
                    ret = ret ++ [1]u8{c};
                }
            }
            return ret;
        }
    }
    pub inline fn toTitlecases(comptime names: []const []const u8) []const u8 {
        const rename: []const u8 = static.toCamelCases(names);
        if (rename[0] >= 'a') {
            return [1]u8{rename[0] -% ('a' -% 'A')} ++ rename[1..rename.len];
        } else {
            return rename;
        }
    }
    pub inline fn toTitlecase(comptime name: []const u8) []const u8 {
        const rename: []const u8 = static.toCamelCase(name);
        if (rename[0] >= 'a') {
            return [1]u8{rename[0] -% ('a' -% 'A')} ++ rename[1..rename.len];
        } else {
            return rename;
        }
    }
    pub fn untitle(comptime name: []const u8) []const u8 {
        switch (name[0]) {
            'A'...'Z' => |c| {
                return [1]u8{c +% ('a' -% 'A')} ++ name[1..];
            },
            else => {
                return name;
            },
        }
    }
};
pub fn requireComptimeOld(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .ComptimeFloat, .ComptimeInt, .Type => {
            return true;
        },
        .Pointer => |pointer_info| {
            return requireComptimeOld(pointer_info.child);
        },
        .Array => |array_info| {
            return requireComptimeOld(array_info.child);
        },
        .Struct => {
            inline for (@typeInfo(T).Struct.fields) |field| {
                if (requireComptimeOld(field.type)) {
                    return true;
                }
            }
            return false;
        },
        .Union => {
            inline for (@typeInfo(T).Union.fields) |field| {
                if (requireComptimeOld(field.type)) {
                    return true;
                }
            }
            return false;
        },
        else => {
            return false;
        },
    }
}
pub inline fn ud(value: anytype) Ud(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn udh(value: anytype) Udh(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn ub(value: anytype) Ub(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn ux(value: anytype) Ux(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn id(value: anytype) Id(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn idh(value: anytype) Idh(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn ib(value: anytype) Ib(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn ix(value: anytype) Ix(if (@TypeOf(value) ==
    comptime_int) meta.LeastRealBitSize(value) else @TypeOf(value)) {
    return .{ .value = value };
}
pub fn bloatDiff(old_size: usize, new_size: usize) BloatDiff {
    return .{ .old_value = old_size, .new_value = new_size };
}
pub fn bytesDiff(old_size: usize, new_size: usize) BytesDiff {
    return .{ .old_value = old_size, .new_value = new_size };
}
pub fn addrDiff(old_size: usize, new_size: usize) AddrDiff {
    return .{ .old_value = old_size, .new_value = new_size };
}
pub fn identifier(name: []const u8) IdentifierFormat {
    return .{ .value = name };
}
pub const lazyIdentifier = @as(*const fn ([]const u8) LazyIdentifierFormat, @ptrCast(&identifier));
pub const stringLiteral = @as(*const fn ([]const u8) StringLiteralFormat, @ptrCast(&identifier));
pub fn sourceLocation(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
    return SourceLocationFormat.init(value, ret_addr);
}
pub fn year(value: usize) Year {
    return .{ .value = value };
}
pub fn mon(value: time.Month) Month {
    return .{ .value = @intFromEnum(value) };
}
pub fn mday(value: u8) MonthDay {
    return .{ .value = value };
}
pub fn yday(value: u8) YearDay {
    return .{ .value = value };
}
pub fn hour(value: u8) Hour {
    return .{ .value = value };
}
pub fn min(value: u8) Minute {
    return .{ .value = value };
}
pub fn sec(value: u8) Second {
    return .{ .value = value };
}
/// Constructs DateTime formatter
pub fn dt(value: time.DateTime) GenericDateTimeFormat(.{}) {
    return .{ .value = value };
}
pub fn nsec(value: u64) NSec {
    return .{ .value = value };
}
fn uniformChangedIntFormatSpec(comptime bits: u16, comptime signedness: builtin.Signedness, comptime radix: u16) ChangedIntFormatSpec {
    const pf = switch (radix) {
        2 => "0b",
        8 => "0o",
        16 => "0x",
        else => "",
    };
    const old_fmt_spec: PolynomialFormatSpec = .{
        .bits = bits,
        .signedness = signedness,
        .width = if (radix == 2) .max else .min,
        .radix = radix,
        .prefix = if (pf.len == 2) pf[0..2] else null,
    };
    const new_fmt_spec: PolynomialFormatSpec = .{
        .bits = bits,
        .signedness = .unsigned,
        .width = if (radix == 2) .max else .min,
        .radix = radix,
        .prefix = if (pf.len == 2) pf[0..2] else null,
    };
    return .{
        .old_fmt_spec = old_fmt_spec,
        .new_fmt_spec = new_fmt_spec,
        .del_fmt_spec = old_fmt_spec,
    };
}
pub fn ubd(old_int: anytype, new_int: anytype) blk: {
    const T: type = if (@TypeOf(old_int) == comptime_int) u128 else @TypeOf(old_int);
    const U: type = if (@TypeOf(new_int) == comptime_int) u128 else @TypeOf(new_int);
    break :blk GenericChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 2));
} {
    return .{ .old_value = old_int, .new_value = new_int };
}
pub fn uod(old_int: anytype, new_int: anytype) blk: {
    const T: type = if (@TypeOf(old_int) == comptime_int) u128 else @TypeOf(old_int);
    const U: type = if (@TypeOf(new_int) == comptime_int) u128 else @TypeOf(new_int);
    break :blk GenericChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 8));
} {
    return .{ .old_value = old_int, .new_value = new_int };
}
pub fn udd(old_int: anytype, new_int: anytype) blk: {
    const T: type = if (@TypeOf(old_int) == comptime_int) u128 else @TypeOf(old_int);
    const U: type = if (@TypeOf(new_int) == comptime_int) u128 else @TypeOf(new_int);
    break :blk GenericChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 10));
} {
    return .{ .old_value = old_int, .new_value = new_int };
}
pub fn uxd(old_int: anytype, new_int: anytype) blk: {
    const T: type = if (@TypeOf(old_int) == comptime_int) u128 else @TypeOf(old_int);
    const U: type = if (@TypeOf(new_int) == comptime_int) u128 else @TypeOf(new_int);
    break :blk GenericChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 16));
} {
    return .{ .old_value = old_int, .new_value = new_int };
}
pub const RenderSpec = struct {
    radix: u7 = 10,
    render_smallest_int: bool = false,
    string_literal: ?bool = true,
    multi_line_string_literal: ?bool = false,
    omit_default_fields: bool = true,
    omit_container_decls: bool = true,
    omit_trailing_comma: ?bool = null,
    omit_type_names: bool = false,
    enum_to_int: bool = false,
    ignore_padding_fields: bool = true,
    infer_type_names: bool = true,
    infer_type_names_recursively: bool = false,
    char_literal_formatter: type = Esc,
    inline_field_types: bool = true,
    forward: bool = false,
    names: Names = .{},
    views: Views = .{},
    decls: Decls = .{},
    const Names = struct {
        len_field_suffix: []const u8 = "_len",
        max_len_field_suffix: []const u8 = "_max_len",
        tag_field_suffix: []const u8 = "_tag",
    };
    const Decls = packed struct(u2) {
        /// Prefer existing formatter declarations if present (unions and structs)
        forward_formatter: bool = false,
        /// Prefer `ContainerFormat` over `StructFormat` for apparent library
        /// container types.
        forward_container: bool = false,
    };
    const Views = packed struct(u6) {
        /// Represents a normal slice where all values are to be shown, maybe used in extern structs.
        /// field_name: [*]T,
        /// field_name_len: usize,
        extern_slice: bool = false,
        /// Represents a slice where only `field_name_len` values are to be shown.
        /// field_name: []T
        /// field_name_len: usize,
        zig_resizeable: bool = false,
        /// Represents a statically sized buffer  where only `field_name_len` values are to be shown.
        /// field_name: [n]T
        /// field_name_len: usize,
        static_resizeable: bool = false,
        /// Represents a buffer with length and capacity, maybe used in extern structs.
        /// field_name: [*]T,
        /// field_name_max_len: usize,
        /// field_name_len: usize,
        extern_resizeable: bool = false,
        /// Represents a union with length and capacity, maybe used in extern structs.
        /// field_name: U,
        /// field_name_tag: E,
        extern_tagged_union: bool = true,
        /// Represents `anytype`
        generic_type_cast: bool = true,
    };
};
pub inline fn any(value: anytype) AnyFormat(.{}, @TypeOf(value)) {
    return .{ .value = value };
}
pub inline fn render(comptime spec: RenderSpec, value: anytype) AnyFormat(spec, @TypeOf(value)) {
    return .{ .value = value };
}
fn TypeName(comptime T: type, comptime spec: RenderSpec) type {
    if (spec.infer_type_names or
        spec.infer_type_names_recursively)
    {
        return *const [1]u8;
    } else if (spec.omit_type_names) {
        return *const [0]u8;
    } else {
        return @TypeOf(@typeName(T));
    }
}
inline fn writeFormat(array: anytype, format: anytype) void {
    if (builtin.runtime_assertions) {
        array.writeFormat(format);
    } else {
        format.formatWrite(array);
    }
}
pub fn AnyFormat(comptime spec: RenderSpec, comptime T: type) type {
    @setEvalBranchQuota(~@as(u32, 0));
    if (T == meta.Generic) {
        return GenericFormat(spec);
    }
    switch (@typeInfo(T)) {
        .Array => return ArrayFormat(spec, T),
        .Bool => return BoolFormat,
        .Type => return TypeFormat(spec),
        .Struct => return StructFormat(spec, T),
        .Union => return UnionFormat(spec, T),
        .Enum => return EnumFormat(spec, T),
        .EnumLiteral => return EnumLiteralFormat,
        .ComptimeInt => return ComptimeIntFormat,
        .Int => return IntFormat(spec, T),
        .Pointer => |pointer_info| switch (pointer_info.size) {
            .One => return PointerOneFormat(spec, T),
            .Many => return PointerManyFormat(spec, T),
            .Slice => return PointerSliceFormat(spec, T),
            else => @compileError(@typeName(T)),
        },
        .Optional => return OptionalFormat(spec, T),
        .Null => return NullFormat,
        .Void => return VoidFormat,
        .NoReturn => return NoReturnFormat,
        .Vector => return VectorFormat(spec, T),
        .ErrorUnion => return ErrorUnionFormat(spec, T),
        .ErrorSet => return ErrorSetFormat(T),
        else => @compileError(@typeName(T)),
    }
}
pub fn GenericFormat(comptime spec: RenderSpec) type {
    const T = struct {
        value: meta.Generic,
        const Format = @This();
        pub fn formatWrite(comptime format: Format, array: anytype) void {
            const type_format: AnyFormat(spec, format.value.type) = .{ .value = meta.typeCast(format.value) };
            writeFormat(array, type_format);
        }
        pub fn formatLength(comptime format: Format) usize {
            const type_format: AnyFormat(spec, format.value.type) = .{ .value = meta.typeCast(format.value) };
            return type_format.formatLength();
        }
    };
    return T;
}
pub fn eval(comptime spec: RenderSpec, comptime any_value: anytype) []const u8 {
    if (!@inComptime()) {
        @compileError("Must be called at compile time");
    }
    const any_format = render(spec, any_value);
    const len: usize = any_format.formatLength() +% 1;
    var buf: [len]u8 = undefined;
    return buf[0..any_format.formatWriteBuf(&buf)];
}
pub fn typeDescr(comptime spec: TypeDescrFormatSpec, comptime T: type) []const u8 {
    if (@inComptime()) {
        @compileError("Must not be called at compile time");
    }
    const any_format = comptime GenericTypeDescrFormat(spec).init(T);
    const len: usize = comptime any_format.formatLength() +% 1;
    const S = struct {
        var buf: [len]u8 = undefined;
    };
    return S.buf[0..any_format.formatWriteBuf(&S.buf)];
}
pub fn ArrayFormat(comptime spec: RenderSpec, comptime Array: type) type {
    const T = struct {
        value: Array,
        const Format = @This();
        const ChildFormat: type = AnyFormat(child_spec, child);
        const array_info: builtin.Type = @typeInfo(Array);
        const child: type = array_info.Array.child;
        const type_name: []const u8 = @typeName(Array);
        const max_len: ?comptime_int = blk: {
            if (ChildFormat.max_len) |child_max_len| {
                break :blk (type_name.len +% 2) +% array_info.Array.len *% (child_max_len +% 2);
            } else {
                break :blk null;
            }
        };
        const omit_trailing_comma: comptime_int = @intFromBool(spec.omit_trailing_comma orelse true);
        const child_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = @typeInfo(child) == .Struct;
            break :blk tmp;
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (format.value.len == 0) {
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (builtin.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                }
                if (omit_trailing_comma != 0) {
                    array.overwriteCountBack(2, " }".*);
                } else {
                    array.writeOne('}');
                }
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = type_name.len;
            @memcpy(buf, type_name);
            if (format.value.len == 0) {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                if (builtin.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const element_format: ChildFormat = .{ .value = element };
                        len +%= element_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                } else {
                    for (format.value) |element| {
                        const element_format: ChildFormat = .{ .value = element };
                        len +%= element_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                }
                if (omit_trailing_comma != 0) {
                    @as(*[2]u8, @ptrCast(buf + (len -% 2))).* = " }".*;
                } else {
                    buf[len] = '}';
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = type_name.len +% 2;
            if (builtin.requireComptime(child)) {
                inline for (format.value) |value| {
                    const element_format: ChildFormat = .{ .value = value };
                    len +%= element_format.formatLength() +% 2;
                }
            } else {
                for (format.value) |value| {
                    const element_format: ChildFormat = .{ .value = value };
                    len +%= element_format.formatLength() +% 2;
                }
            }
            if (omit_trailing_comma == 0 and
                format.value.len != 0)
            {
                len +%= 1;
            }
            return len;
        }
    };
    return T;
}
pub const BoolFormat = packed struct {
    value: bool,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.value) {
            array.writeCount(4, "true".*);
        } else {
            array.writeCount(5, "false".*);
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        if (format.value) {
            buf[0..4].* = "true".*;
            return 4;
        } else {
            buf[0..5].* = "false".*;
            return 5;
        }
    }
    pub inline fn formatLength(format: Format) usize {
        return if (format.value) 4 else 5;
    }
};
pub fn TypeFormat(comptime spec: RenderSpec) type {
    const T = struct {
        value: type,
        const Format = @This();
        const omit_trailing_comma: bool = spec.omit_trailing_comma orelse false;
        const max_len: ?comptime_int = null;
        const default_value_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = true;
            break :blk tmp;
        };
        const field_type_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.infer_type_names = false;
            break :blk tmp;
        };
        inline fn evalDefaultValue(comptime field_type: type, comptime default_value: ?*const anyopaque) ?[]const u8 {
            if (default_value == null) {
                return null;
            }
            if (builtin.isUndefined(default_value)) {
                return "undefined";
            }
            return comptime eval(default_value_spec, @as(*const field_type, @ptrCast(@alignCast(default_value))).*);
        }
        pub inline fn formatWrite(comptime format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub fn formatWriteBuf(comptime format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const type_info: builtin.Type = @typeInfo(format.value);
            var len: usize = 0;
            switch (type_info) {
                .Struct => |struct_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (struct_info.fields) |field| {
                            len +%= writeStructFieldBuf(buf + len, field.name, field.type, evalDefaultValue(field.type, field.default_value));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                if (@hasDecl(format.value, decl.name)) {
                                    len +%= writeDeclBuf(buf + len, decl.name, @field(format.value, decl.name));
                                }
                            }
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, struct_info.fields.len +% struct_info.decls.len);
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, struct_info.fields.len);
                        }
                    }
                },
                .Union => |union_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (union_info.fields) |field| {
                            len +%= writeUnionFieldBuf(buf + len, field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                if (@hasDecl(format.value, decl.name)) {
                                    len +%= writeDeclBuf(buf + len, decl.name, @field(format.value, decl.name));
                                }
                            }
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, union_info.fields.len +% union_info.decls.len);
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, union_info.fields.len);
                        }
                    }
                },
                .Enum => |enum_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " {}".*;
                        len +%= 3;
                    } else {
                        @as(*@TypeOf(decl_spec_s), @ptrCast(buf + len)).* = decl_spec_s;
                        len +%= decl_spec_s.len;
                        @as(*[3]u8, @ptrCast(buf + len)).* = " { ".*;
                        len +%= 3;
                        inline for (enum_info.fields) |field| {
                            len +%= writeEnumFieldBuf(buf + len, field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                if (@hasDecl(format.value, decl.name)) {
                                    len +%= writeDeclBuf(buf + len, decl.name, @field(format.value, decl.name));
                                }
                            }
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, enum_info.fields.len +% enum_info.decls.len);
                        } else {
                            len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, enum_info.fields.len);
                        }
                    }
                },
                else => {
                    const type_name_s: []const u8 = @typeName(format.value);
                    @memcpy(buf + len, type_name_s);
                    len +%= type_name_s.len;
                },
            }
            return len;
        }
        fn writeDeclBuf(buf: [*]u8, decl_name: []const u8, decl_value: anytype) usize {
            @setRuntimeSafety(builtin.is_safe);
            const decl_type: type = @TypeOf(decl_value);
            var len: usize = 0;
            if (@typeInfo(decl_type) != .Fn) {
                const decl_name_format: IdentifierFormat = .{ .value = decl_name };
                const decl_format: AnyFormat(default_value_spec, decl_type) = .{ .value = decl_value };
                const type_name_s: []const u8 = @typeName(decl_type);
                @as(*[10]u8, @ptrCast(buf + len)).* = "pub const ".*;
                len +%= 10;
                len +%= decl_name_format.formatWriteBuf(buf + len);
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                @memcpy(buf + len, type_name_s);
                len +%= type_name_s.len;
                @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
                len +%= 3;
                len +%= decl_format.formatWriteBuf(buf + len);
                @as(*[2]u8, @ptrCast(buf + len)).* = "; ".*;
                len +%= 2;
            }
            return len;
        }
        fn writeStructFieldBuf(buf: [*]u8, field_name: []const u8, comptime field_type: type, default_field: ?[]const u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (spec.inline_field_types) {
                const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                len +%= field_name_format.formatWriteBuf(buf);
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                len +%= type_format.formatWriteBuf(buf + len);
            } else {
                len +%= field_name_format.formatWriteBuf(buf);
                @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                len +%= 2;
                @as(meta.TypeName(field_type), @ptrCast(buf + len)).* = @typeName(field_type).*;
                len +%= @typeName(field_type).len;
            }
            if (default_field) |value| {
                @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
                len +%= 3;
                len +%= strcpy(buf + len, value);
            }
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        fn writeUnionFieldBuf(buf: [*]u8, field_name: []const u8, comptime field_type: type) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            if (field_type == void) {
                len +%= field_name_format.formatWriteBuf(buf + len);
                @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                len +%= 2;
            } else {
                if (spec.inline_field_types) {
                    const type_format: TypeFormat(field_type_spec) = .{ .value = field_type };
                    len +%= field_name_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                    len +%= 2;
                    len +%= type_format.formatWriteBuf(buf + len);
                } else {
                    len +%= field_name_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = ": ".*;
                    len +%= 2;
                    @as(meta.TypeName(field_type), @ptrCast(buf + len)).* = @typeName(field_type).*;
                    len +%= @typeName(field_type).len;
                }
                @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                len +%= 2;
            }
            return len;
        }
        fn writeEnumFieldBuf(buf: [*]u8, field_name: []const u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const field_name_format: IdentifierFormat = .{ .value = field_name };
            var len: usize = 0;
            len +%= field_name_format.formatWriteBuf(buf);
            @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
            len +%= 2;
            return len;
        }
        fn lengthDecl(buf: [*]u8, decl_name: []const u8, decl_value: anytype) comptime_int {
            const decl_type: type = @TypeOf(decl_value);
            var len: usize = 0;
            if (@typeInfo(decl_type) != .Fn) {
                len +%= 17 +% identifier(decl_name).formatWriteBuf(buf + len) +%
                    @typeName(decl_type).len +% any(decl_value).formatLength();
            }
            return len;
        }
        pub fn formatLength(comptime format: anytype) comptime_int {
            const type_info: builtin.Type = @typeInfo(format.value);
            var len: usize = 0;
            switch (type_info) {
                .Struct => |struct_info| {
                    len +%= typeDeclSpecifier(type_info).len +% 3;
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        return len;
                    } else {
                        inline for (struct_info.fields) |field| {
                            if (spec.inline_field_types) {
                                const type_format: TypeFormat(field_type_spec) = .{ .value = field.type };
                                len +%= identifier(field.name).formatLength() +% 2 +% type_format.formatLength();
                            } else {
                                len +%= identifier(field.name).formatLength() +% 2 +% @typeName(field.type).len;
                            }
                            if (evalDefaultValue(field.type, field.default_value)) |value| {
                                len +%= value.len +% 3;
                            }
                            len +%= 2;
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                if (@hasDecl(format.value, decl.name)) {
                                    len +%= lengthDecl(decl.name, @field(format.value, decl.name));
                                }
                            }
                        }
                        len +%= @intFromBool(struct_info.fields.len != 0 and !omit_trailing_comma);
                    }
                },
                .Union => |union_info| {
                    len +%= typeDeclSpecifier(type_info).len +% 3;
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        return len;
                    }
                    inline for (union_info.fields) |field| {
                        if (field.type == void) {
                            len +%= identifier(field.name).formatLength() +% 2;
                        } else {
                            if (spec.inline_field_types) {
                                const type_format: TypeFormat(field_type_spec) = .{ .value = field.type };
                                len +%= identifier(field.name).formatLength() +% 4 +% type_format.formatLength();
                            } else {
                                len +%= identifier(field.name).formatLength() +% 4 +% @typeName(field.type).len;
                            }
                        }
                    }
                    if (!spec.omit_container_decls) {
                        inline for (union_info.decls) |decl| {
                            if (@hasDecl(format.value, decl.name)) {
                                len +%= lengthDecl(decl.name, @field(format.value, decl.name));
                            }
                        }
                    }
                    len +%= @intFromBool(union_info.fields.len != 0 and !omit_trailing_comma);
                },
                .Enum => |enum_info| {
                    len +%= typeDeclSpecifier(type_info).len +% 3;
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        return len;
                    }
                    inline for (enum_info.fields) |field| {
                        len +%= comptime identifier(field.name).formatLength() +% 2;
                    }
                    if (!spec.omit_container_decls) {
                        inline for (enum_info.decls) |decl| {
                            if (@hasDecl(format.value, decl.name)) {
                                len +%= lengthDecl(decl.name, @field(format.value, decl.name));
                            }
                        }
                    }
                    len +%= @intFromBool(enum_info.fields.len != 0 and !omit_trailing_comma);
                },
                else => {
                    len +%= @typeName(format.value).len;
                },
            }
            return len;
        }
    };
    return T;
}
inline fn writeTrailingComma(array: anytype, comptime omit_trailing_comma: bool, fields_len: usize) void {
    if (fields_len == 0) {
        array.overwriteOneBack('}');
    } else {
        if (omit_trailing_comma) {
            array.overwriteManyBack(" }");
        } else {
            array.writeOne('}');
        }
    }
}
fn writeTrailingCommaBuf(buf: [*]u8, omit_trailing_comma: bool, fields_len: usize) usize {
    // The length starting at -1 is a workaround for compiler TODO implement sema comptime pointer subtract.
    var len: usize = 0;
    if (fields_len == 0) {
        buf[1] = '}';
    } else {
        if (omit_trailing_comma) {
            buf[0..2].* = " }".*;
        } else {
            buf[2] = '}';
            len +%= 1;
        }
    }
    return len;
}
fn writeFieldInitializerBuf(buf: [*]u8, field_name_format: IdentifierFormat, field_format: anytype) usize {
    @setRuntimeSafety(builtin.is_safe);
    var len: usize = 0;
    buf[0] = '.';
    len +%= 1;
    len +%= field_name_format.formatWriteBuf(buf + len);
    @as(*[3]u8, @ptrCast(buf + len)).* = " = ".*;
    len +%= 3;
    len +%= field_format.formatWriteBuf(buf + len);
    @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
    len +%= 2;
    return len;
}
pub fn StructFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    if (spec.decls.forward_formatter) {
        if (@hasDecl(Struct, "formatWrite") and @hasDecl(Struct, "formatLength")) {
            return FormatFormat(Struct);
        }
    }
    if (spec.decls.forward_container) {
        if (@hasDecl(Struct, "readAll") and @hasDecl(Struct, "len")) {
            return ContainerFormat(spec, Struct);
        }
    }
    const type_name = @typeName(Struct);
    const field_spec_if_not_type: RenderSpec = blk: {
        var tmp: RenderSpec = spec;
        tmp.infer_type_names = true;
        break :blk tmp;
    };
    const field_spec_if_type: RenderSpec = blk: {
        var tmp: RenderSpec = spec;
        tmp.infer_type_names = false;
        break :blk tmp;
    };
    const fields: []const builtin.Type.StructField = @typeInfo(Struct).Struct.fields;
    const omit_trailing_comma: bool = spec.omit_trailing_comma orelse (fields.len < 4);
    const T = struct {
        value: Struct,
        const Format = @This();
        pub const max_len: ?comptime_int = blk: {
            var len: usize = 0;
            len +%= @typeName(Struct).len +% 2;
            if (fields.len == 0) {
                len +%= 1;
            } else {
                inline for (fields) |field| {
                    const field_name_format: IdentifierFormat = .{ .value = field.name };
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    const FieldFormat = AnyFormat(field_spec, field.type);
                    len +%= 1 +% field_name_format.formatLength() +% 3;
                    if (FieldFormat.max_len) |field_max_len| {
                        len +%= field_max_len;
                    } else {
                        break :blk null;
                    }
                }
            }
            break :blk len;
        };
        fn writeFieldInitializer(array: anytype, field_name_format: IdentifierFormat, field_format: anytype) void {
            array.writeOne('.');
            writeFormat(array, field_name_format);
            array.writeCount(3, " = ".*);
            writeFormat(array, field_format);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.infer_type_names) {
                array.writeOne('.');
            } else {
                array.writeMany(type_name);
            }
            if (fields.len == 0) {
                array.writeMany("{}");
            } else {
                comptime var field_idx: usize = 0;
                var fields_len: usize = 0;
                array.writeMany("{ ");
                inline while (field_idx != fields.len) : (field_idx +%= 1) {
                    const field: builtin.Type.StructField = fields[field_idx];
                    if (spec.ignore_padding_fields) {
                        if (comptime field.name.len > 1 and field.name[0] == 'z' and field.name[1] == 'b') {
                            continue;
                        }
                    }
                    const field_name_format: IdentifierFormat = .{ .value = field.name };
                    const field_value: field.type = @field(format.value, field.name);
                    const field_type_info: builtin.Type = @typeInfo(field.type);
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    if (field_type_info == .Union) {
                        if (field_type_info.Union.layout != .Auto) {
                            comptime var tag_field_name = field.name ++ spec.names.tag_field_suffix;
                            if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                                const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(format.value, tag_field_name));
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Pointer) {
                        comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                        if (field_type_info.Pointer.size == .Many) {
                            if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                            if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (field_type_info.Pointer.size == .Slice) {
                            if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                writeFieldInitializer(array, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Array) {
                        comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                        if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            writeFieldInitializer(array, field_name_format, render(field_spec, view));
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                    if (spec.omit_default_fields and field.default_value != null and !field.is_comptime) {
                        if (builtin.requireComptime(field.type)) {
                            if (comptime !mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                                writeFieldInitializer(array, field_name_format, field_format);
                                fields_len +%= 1;
                            }
                        } else {
                            if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                                writeFieldInitializer(array, field_name_format, field_format);
                                fields_len +%= 1;
                            }
                        }
                    } else {
                        writeFieldInitializer(array, field_name_format, field_format);
                        fields_len +%= 1;
                    }
                }
                writeTrailingComma(array, omit_trailing_comma, fields_len);
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (spec.infer_type_names) {
                buf[len] = '.';
                len +%= 1;
            } else {
                buf[0..type_name.len].* = type_name.*;
                len +%= type_name.len;
            }
            if (fields.len == 0) {
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                comptime var field_idx: usize = 0;
                var fields_len: usize = 0;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                inline while (field_idx != fields.len) : (field_idx +%= 1) {
                    const field: builtin.Type.StructField = fields[field_idx];
                    if (spec.ignore_padding_fields) {
                        if (comptime field.name.len > 1 and field.name[0] == 'z' and field.name[1] == 'b') {
                            continue;
                        }
                    }
                    const field_name_format: IdentifierFormat = .{ .value = field.name };
                    const field_value: field.type = @field(format.value, field.name);
                    const field_type_info: builtin.Type = @typeInfo(field.type);
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    if (field_type_info == .Union) {
                        if (field_type_info.Union.layout != .Auto) {
                            comptime var tag_field_name = field.name ++ spec.names.tag_field_suffix;
                            if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                                const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(format.value, tag_field_name));
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Pointer) {
                        comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                        if (field_type_info.Pointer.size == .Many) {
                            if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                            if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (field_type_info.Pointer.size == .Slice) {
                            if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(format.value, len_field_name)];
                                len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    } else if (field_type_info == .Array) {
                        comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                        if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= writeFieldInitializerBuf(buf + len, field_name_format, render(field_spec, view));
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                    if (spec.omit_default_fields and field.default_value != null and !field.is_comptime) {
                        if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= writeFieldInitializerBuf(buf + len, field_name_format, field_format);
                            fields_len +%= 1;
                        }
                    } else {
                        len +%= writeFieldInitializerBuf(buf + len, field_name_format, field_format);
                        fields_len +%= 1;
                    }
                }
                len +%= writeTrailingCommaBuf(buf + (len -% 2), omit_trailing_comma, fields_len);
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (spec.infer_type_names) {
                len +%= 3;
            } else {
                len +%= @typeName(Struct).len +% 2;
            }
            comptime var field_idx: usize = 0;
            var fields_len: usize = 0;
            inline while (field_idx != fields.len) : (field_idx +%= 1) {
                const field: builtin.Type.StructField = fields[field_idx];
                const field_name_format: IdentifierFormat = .{ .value = field.name };
                const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                const field_value: field.type = @field(format.value, field.name);
                const field_type_info: builtin.Type = @typeInfo(field.type);
                if (field_type_info == .Union) {
                    if (field_type_info.Union.layout != .Auto) {
                        const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                        if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                            const view = meta.tagUnion(field.type, meta.Field(tag_field_name), field_value, @field(format.value, tag_field_name));
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                } else if (field_type_info == .Pointer) {
                    comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                    if (field_type_info.Pointer.size == .Many) {
                        if (spec.views.extern_slice and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                        if (spec.views.extern_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                    if (field_type_info.Pointer.size == .Slice) {
                        if (spec.views.zig_resizeable and @hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(format.value, len_field_name)];
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                } else if (field_type_info == .Array) {
                    comptime var len_field_name = field.name ++ spec.names.len_field_suffix;
                    if (spec.views.static_resizeable and @hasField(Struct, len_field_name)) {
                        const view = field_value[0..@field(format.value, len_field_name)];
                        len +%= 1 +% field_name_format.formatLength() +% 3 +% render(field_spec, view).formatLength() +% 2;
                        fields_len +%= 1;
                        continue;
                    }
                }
                const field_format: AnyFormat(field_spec, field.type) = .{ .value = field_value };
                if (spec.omit_default_fields and field.default_value != null and !field.is_comptime) {
                    if (builtin.requireComptime(field.type)) {
                        if (comptime !mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                            fields_len +%= 1;
                        }
                    } else {
                        if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                            fields_len +%= 1;
                        }
                    }
                } else {
                    len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                    fields_len +%= 1;
                }
            }
            len +%= @intFromBool(!omit_trailing_comma and fields_len != 0);
            return len;
        }
    };
    return T;
}
pub fn UnionFormat(comptime spec: RenderSpec, comptime Union: type) type {
    if (spec.decls.forward_formatter) {
        if (@hasDecl(Union, "formatWrite") and @hasDecl(Union, "formatLength")) {
            return FormatFormat(Union);
        }
    }
    const T = struct {
        value: Union,
        const Format = @This();
        const fields: []const builtin.Type.UnionField = @typeInfo(Union).Union.fields;
        // This is the actual tag type
        const tag_type: ?type = @typeInfo(Union).Union.tag_type;
        // This is the bit-field tag type name
        const tag_type_name: []const u8 = typeName(@typeInfo(fields[0].type).Enum.tag_type, spec);
        const show_enum_field: bool = fields.len == 2 and (@typeInfo(fields[0].type) == .Enum and
            fields[1].type == @typeInfo(fields[0].type).Enum.tag_type);
        const Int: type = meta.LeastRealBitSize(Union);
        const max_len: ?comptime_int = blk: {
            if (show_enum_field) {
                var len: usize = 0;
                const enum_info: builtin.Type = @typeInfo(fields[0].type);
                inline for (enum_info.Enum.fields) |field| {
                    const field_name_format: IdentifierFormat = .{ .value = field.name };
                    len +%= field_name_format.formatLength();
                }
                len +%= fields.len *% 3;
                len +%= 10;
                len +%= tag_type_name.len;
                len +%= 3;
                len +%= 1;
                len +%= fields.len -% 1;
                len +%= 2 +% 1 +% IntFormat(enum_info.Enum.tag_type).max_len +% 1;
                break :blk len;
            } else {
                var max_field_len: usize = 0;
                inline for (fields) |field| {
                    max_field_len = @max(max_field_len, AnyFormat(spec, field.type).max_len);
                }
                break :blk (@typeName(Union).len +% 2) +% 1 +% meta.maxNameLength(Union) +% 3 +% max_field_len +% 2;
            }
        };
        fn formatWriteEnumField(format: Format, array: anytype) void {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            array.writeMany("bit_field(" ++ @typeName(enum_info.Enum.tag_type) ++ "){ ");
            var x: enum_info.Enum.tag_type = w;
            comptime var idx: usize = enum_info.Enum.fields.len;
            inline while (idx != 0) {
                idx -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[idx];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        array.writeOne('.');
                        const tag_name_format: IdentifierFormat = .{ .value = field.name };
                        writeFormat(array, tag_name_format);
                        array.writeMany(" | ");
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    writeFormat(array, int_format);
                    array.writeCount(2, " }".*);
                } else {
                    array.undefine(1);
                    array.overwriteCountBack(2, " }".*);
                }
            } else {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    writeFormat(array, int_format);
                    array.writeCount(2, " }".*);
                } else {
                    array.overwriteOneBack('}');
                }
            }
        }
        fn formatWriteBufEnumField(format: Format, buf: [*]u8) usize {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            @as(*[10]u8, @ptrCast(buf)).* = "bit_field(".*;
            var len: usize = 10;
            @as(meta.TypeName(enum_info.Enum.tag_type), @ptrCast(buf + len)).* = @typeName(enum_info.Enum.tag_type).*;
            len +%= @typeName(enum_info.Enum.tag_type).len;
            @as(*[3]u8, @ptrCast(buf + len)).* = "){ ".*;
            len +%= 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var idx: usize = enum_info.Enum.fields.len;
            inline while (idx != 0) {
                idx -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[idx];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        buf[len] = '.';
                        len +%= 1;
                        const tag_name_format: IdentifierFormat = .{ .value = field.name };
                        len +%= tag_name_format.formatWriteBuf(buf + len);
                        @as(*[3]u8, @ptrCast(buf + len)).* = " | ".*;
                        len +%= 3;
                        x &= ~y;
                    }
                }
            }
            if (x != w) {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    len +%= int_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = " }".*;
                    len +%= 2;
                } else {
                    len -%= 1;
                    @as(*[2]u8, @ptrCast(buf + (len -% 2))).* = " }".*;
                }
            } else {
                if (x != 0) {
                    const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                    len +%= int_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = " }".*;
                    len +%= 2;
                } else {
                    len -%= 1;
                    (buf + (len -% 1))[0] = '}';
                }
            }
            return len;
        }
        fn formatLengthEnumField(format: Format) usize {
            const enum_info: builtin.Type = @typeInfo(fields[0].type);
            const w: enum_info.Enum.tag_type = @field(format.value, fields[1].name);
            var len: usize = 10;
            len +%= @typeName(enum_info.Enum.tag_type).len;
            len +%= 3;
            var x: enum_info.Enum.tag_type = w;
            comptime var idx: usize = enum_info.Enum.fields.len;
            inline while (idx != 0) {
                idx -%= 1;
                const field: builtin.Type.EnumField = enum_info.Enum.fields[idx];
                if (field.value != 0 or w == 0) {
                    const y: enum_info.Enum.tag_type = @field(format.value, fields[1].name) & field.value;
                    if (y == field.value) {
                        len +%= 1;
                        const tag_name_format: IdentifierFormat = .{ .value = field.name };
                        len +%= tag_name_format.formatLength();
                        x &= ~y;
                        len +%= 3;
                    }
                }
            }
            if (x != 0) {
                const int_format: IntFormat(spec, enum_info.Enum.tag_type) = .{ .value = x };
                len +%= int_format.formatLength();
                len +%= 2;
            } else {
                len -%= 1;
            }
            return len;
        }
        fn formatWriteUntagged(format: Format, array: anytype) void {
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                const tagged_format: TaggedFormat = .{ .value = format.value.tagged() };
                writeFormat(array, tagged_format);
            } else {
                if (spec.infer_type_names) {
                    array.writeOne('.');
                } else {
                    array.writeMany(@typeName(Union));
                }
                if (@sizeOf(Union) > @sizeOf(usize)) {
                    array.writeMany("{}");
                } else {
                    const int_format: Ub(Int) = .{ .value = meta.leastRealBitCast(format.value) };
                    array.writeMany("@bitCast(" ++ @typeName(Union) ++ ", ");
                    writeFormat(array, int_format);
                    array.writeMany(")");
                }
            }
        }
        fn formatWriteBufUntagged(format: Format, buf: [*]u8) usize {
            var len: usize = 0;
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                const tagged_format: TaggedFormat = .{ .value = format.value.tagged() };
                len +%= tagged_format.formatWriteBuf(buf);
            } else {
                if (@sizeOf(Union) > @sizeOf(usize)) {
                    buf[0..2].* = "{}".*;
                    len +%= 2;
                } else {
                    const int_format: Ub(Int) = .{ .value = meta.leastRealBitCast(format.value) };
                    buf[0 .. 11 +% @typeName(Union).len].* = ("@bitCast(" ++ @typeName(Union) ++ ", ").*;
                    len +%= 11 +% @typeName(Union).len;
                    len +%= int_format.formatWriteBuf(buf + len);
                    buf[len] = ')';
                    len +%= 1;
                }
            }
            return len;
        }
        fn formatLengthUntagged(format: Format) usize {
            var len: usize = 0;
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                len +%= TaggedFormat.formatLength(.{ .value = format.value.tagged() });
            } else {
                const type_name = if (spec.infer_type_names) "." else @typeName(Union);
                if (@sizeOf(Union) > @sizeOf(usize)) {
                    len +%= type_name.len +% 2;
                } else {
                    const int_format: Ub(Int) = .{ .value = meta.leastRealBitCast(format.value) };
                    len +%= ("@bitCast(" ++ @typeName(Union) ++ ", ").len;
                    len +%= int_format.formatLength();
                    len +%= 1;
                }
            }
            return len;
        }
        fn formatWriteField(array: anytype, field_name_format: IdentifierFormat, field_format: anytype) void {
            array.writeOne('.');
            writeFormat(array, field_name_format);
            array.writeCount(3, " = ".*);
            writeFormat(array, field_format);
            array.writeCount(2, ", ".*);
        }
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (show_enum_field) {
                return format.formatWriteEnumField(array);
            }
            if (tag_type == null) {
                return format.formatWriteUntagged(array);
            }
            const type_name = if (spec.infer_type_names) "." else @typeName(Union);
            if (fields.len == 0) {
                array.writeMany(type_name ++ "{}");
            } else {
                array.writeMany(type_name ++ "{ ");
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            array.undefine(2);
                            return writeFormat(array, field_name_format);
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            formatWriteField(array, field_name_format, field_format);
                        }
                    }
                }
                array.overwriteCountBack(2, " }".*);
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (show_enum_field) {
                return format.formatWriteBufEnumField(buf);
            }
            if (tag_type == null) {
                return format.formatWriteBufUntagged(buf);
            }
            const type_name = if (spec.infer_type_names) "." else @typeName(Union);
            @as(*[type_name.len]u8, @ptrCast(buf)).* = type_name.*;
            if (fields.len == 0) {
                @as(*[2]u8, @ptrCast(buf + type_name.len)).* = "{}".*;
                return type_name.len +% 2;
            } else {
                var len: usize = type_name.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            len -%= 2;
                            len +%= field_name_format.formatWriteBuf(buf + len);
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            len +%= writeFieldInitializerBuf(buf + len, field_name_format, field_format);
                        }
                    }
                }
                @as(*[2]u8, @ptrCast(buf + (len -% 2))).* = " }".*;
                return len;
            }
        }
        pub fn formatLength(format: anytype) usize {
            if (show_enum_field) {
                return format.formatLengthEnumField();
            }
            if (tag_type == null) {
                return format.formatLengthUntagged();
            }
            const type_name = if (spec.infer_type_names) "." else @typeName(Union);
            if (fields.len == 0) {
                return type_name.len +% 2;
            } else {
                var len: usize = type_name.len +% 2;
                inline for (fields) |field| {
                    if (format.value == @field(tag_type.?, field.name)) {
                        const field_name_format: IdentifierFormat = .{ .value = field.name };
                        if (field.type == void) {
                            len -%= 2;
                            return len +% field_name_format.formatLength();
                        } else {
                            const FieldFormat: type = AnyFormat(spec, field.type);
                            const field_format: FieldFormat = .{ .value = @field(format.value, field.name) };
                            len +%= 1 +% field_name_format.formatLength() +% 3 +% field_format.formatLength() +% 2;
                        }
                    }
                }
                return len;
            }
        }
    };
    return T;
}
pub fn EnumFormat(comptime spec: RenderSpec, comptime Enum: type) type {
    const T = struct {
        value: Enum,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(Enum);
        const max_len: ?comptime_int = 1 +% meta.maxNameLength(Enum);
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatWrite(.{ .value = @intFromEnum(format.value) }, array);
            }
            const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
            array.writeOne('.');
            writeFormat(array, tag_name_format);
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatWriteBuf(.{ .value = @intFromEnum(format.value) }, buf);
            }
            const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
            buf[0] = '.';
            return 1 +% tag_name_format.formatWriteBuf(buf + 1);
        }
        pub fn formatLength(format: anytype) usize {
            if (spec.enum_to_int) {
                return IntFormat(spec, type_info.Enum.tag_type).formatLength(.{ .value = @intFromEnum(format.value) });
            }
            const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
            return 1 +% tag_name_format.formatLength();
        }
    };
    return T;
}
pub const EnumLiteralFormat = struct {
    value: @Type(.EnumLiteral),
    const Format = @This();
    const max_len: ?comptime_int = undefined;
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
        array.writeOne('.');
        writeFormat(array, tag_name_format);
    }
    pub fn formatWriteBuf(comptime format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
        buf[0] = '.';
        return 1 +% tag_name_format.formatWriteBuf(buf + 1);
    }
    pub fn formatLength(comptime format: Format) usize {
        const tag_name_format: IdentifierFormat = .{ .value = @tagName(format.value) };
        return 1 +% tag_name_format.formatLength();
    }
};
pub const ComptimeIntFormat = struct {
    value: comptime_int,
    const Format = @This();
    pub fn formatWrite(comptime format: Format, array: anytype) void {
        array.writeMany(ci(format.value));
    }
    pub fn formatWriteBuf(comptime format: Format, buf: [*]u8) usize {
        return strcpy(buf, ci(format.value));
    }
    pub fn formatLength(comptime format: Format) usize {
        return ci(format.value).len;
    }
};
pub fn IntFormat(comptime spec: RenderSpec, comptime Int: type) type {
    if (spec.render_smallest_int) {
        switch (spec.radix) {
            2 => return Xb(Int),
            8 => return Xo(Int),
            10 => return Xd(Int),
            16 => return Xx(Int),
            else => @compileError("invalid render radix"),
        }
    } else {
        switch (spec.radix) {
            2 => return Xb(meta.BestInt(Int)),
            8 => return Xo(meta.BestInt(Int)),
            10 => return Xd(meta.BestInt(Int)),
            16 => return Xx(meta.BestInt(Int)),
            else => @compileError("invalid render radix"),
        }
    }
}
const AddressFormat = struct {
    value: usize,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        const addr_format = uxsize(format.value);
        array.writeMany("@(");
        writeFormat(addr_format, array);
        array.writeMany(")");
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        const addr_format = uxsize(format.value);
        @as(*[2]u8, @ptrCast(buf)).* = "@(".*;
        len +%= 2;
        len +%= addr_format.formatWriteBuf(buf + len);
        buf[len] = ')';
        len +%= 1;
        return len;
    }
    pub fn formatLength(format: Format) usize {
        var len: usize = 0;
        const addr_format = uxsize(format.value);
        len +%= 2;
        len +%= addr_format.formatLength();
        len +%= 1;
        return len;
    }
};
pub fn PointerOneFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const T = struct {
        value: Pointer,
        const Format = @This();
        const SubFormat = meta.Return(ux64);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const ChildFormat = AnyFormat(spec, child);
        const max_len: ?comptime_int = blk: {
            if (ChildFormat.max_len) |child_max_len| {
                break :blk (4 +% @typeName(Pointer).len +% 3) +% child_max_len +% 1;
            } else {
                break :blk null;
            }
        };
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.forward)
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            const address: usize = @intFromPtr(format.value);
            const type_name: []const u8 = @typeName(Pointer);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                array.writeCount(14 +% type_name.len, ("@intFromPtr(" ++ type_name ++ ", ").*);
                writeFormat(array, sub_format);
                array.writeOne(')');
            } else {
                if (!spec.infer_type_names) {
                    array.writeCount(6 +% type_name.len, ("@as(" ++ type_name ++ ", ").*);
                }
                if (@typeInfo(child) == .Fn) {
                    const sub_format: SubFormat = .{ .value = address };
                    array.writeMany("@");
                    writeFormat(array, sub_format);
                } else {
                    array.writeOne('&');
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    writeFormat(array, sub_format);
                }
                if (!spec.infer_type_names) {
                    array.writeOne(')');
                }
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            const address: usize = if (@inComptime()) 8 else @intFromPtr(format.value);
            const type_name: []const u8 = @typeName(Pointer);
            var len: usize = 0;
            if (@typeInfo(child) == .Array and
                @typeInfo(child).Array.child == u8)
            {
                return stringLiteral(format.value).formatWriteBuf(buf);
            }
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                @as(*[14 +% type_name.len]u8, @ptrCast(buf + len)).* = ("@intFromPtr(" ++ type_name ++ ", ").*;
                len +%= 14 +% type_name.len;
                len +%= sub_format.formatWriteBuf(buf + len);
                buf[len] = ')';
                len +%= 1;
            } else {
                if (!spec.infer_type_names) {
                    @as(*[6 +% type_name.len]u8, @ptrCast(buf + len)).* = ("@as(" ++ type_name ++ ", ").*;
                    len +%= 6 +% type_name.len;
                }
                if (@typeInfo(child) == .Fn) {
                    const sub_format: SubFormat = .{ .value = address };
                    buf[len] = '@';
                    len +%= 1;
                    len +%= sub_format.formatWriteBuf(buf + len);
                } else {
                    buf[len] = '&';
                    len +%= 1;
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    len +%= sub_format.formatWriteBuf(buf + len);
                }
                if (!spec.infer_type_names) {
                    buf[len] = ')';
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            const address: usize = if (@inComptime()) 8 else @intFromPtr(format.value);
            const type_name: []const u8 = @typeName(Pointer);
            if (child == anyopaque) {
                const sub_format: SubFormat = .{ .value = address };
                len +%= 12 +% type_name.len;
                len +%= sub_format.formatLength();
                len +%= 1;
            } else {
                if (!spec.infer_type_names) {
                    len +%= 6 +% type_name.len;
                }
                if (@typeInfo(child) == .Fn) {
                    const sub_format: SubFormat = .{ .value = address };
                    len +%= 1;
                    len +%= sub_format.formatLength();
                } else {
                    len +%= 1;
                    const sub_format: AnyFormat(spec, child) = .{ .value = format.value.* };
                    len +%= sub_format.formatLength();
                }
                if (!spec.infer_type_names) {
                    len +%= 1;
                }
            }
            return len;
        }
    };
    return T;
}
pub fn PointerSliceFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
    const type_name: []const u8 = if (spec.infer_type_names) "." else @typeName(Pointer);
    const T = struct {
        value: Pointer,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Pointer).Pointer.child;
        const max_len: ?comptime_int = null;
        pub fn formatWriteAny(format: anytype, array: anytype) void {
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    array.writeOne('&');
                }
                array.writeMany(type_name);
                array.writeCount(2, "{}".*);
            } else {
                if (spec.infer_type_names) {
                    array.writeOne('&');
                }
                array.writeMany(type_name);
                array.writeCount(2, "{ ".*);
                if (builtin.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        writeFormat(array, sub_format);
                        array.writeCount(2, ", ".*);
                    }
                }
                if (omit_trailing_comma) {
                    array.overwriteCountBack(2, " }".*);
                } else {
                    array.writeOne('}');
                }
            }
        }
        pub fn formatWriteBufAny(format: anytype, buf: [*]u8) usize {
            var len: usize = 0;
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    buf[0] = '&';
                    len +%= 1;
                }
                @as(*[2]u8, @ptrCast(buf + len)).* = "{}".*;
                len +%= 2;
            } else {
                if (spec.infer_type_names) {
                    buf[0] = '&';
                    len +%= 1;
                }
                @memcpy(buf + len, type_name);
                len +%= type_name.len;
                @as(*[2]u8, @ptrCast(buf + len)).* = "{ ".*;
                len +%= 2;
                if (builtin.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatWriteBuf(buf + len);
                        @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                        len +%= 2;
                    }
                }
                if (omit_trailing_comma) {
                    @as(*[2]u8, @ptrCast(buf + (len -% 2))).* = " }".*;
                } else {
                    buf[len] = '}';
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLengthAny(format: anytype) usize {
            var len: usize = 0;
            if (format.value.len == 0) {
                if (spec.infer_type_names) {
                    len +%= 1;
                }
                len +%= type_name.len +% 2;
            } else {
                if (spec.infer_type_names) {
                    len +%= 1;
                }
                len +%= type_name.len +% 2;
                if (builtin.requireComptime(child)) {
                    inline for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatLength() +% 2;
                    }
                } else {
                    for (format.value) |element| {
                        const sub_format: ChildFormat = .{ .value = element };
                        len +%= sub_format.formatLength() +% 2;
                    }
                }
                if (!omit_trailing_comma) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn formatLengthStringLiteral(format: anytype) usize {
            var len: usize = 1;
            for (format.value) |c| {
                len +%= esc(c).formatLength();
            }
            return len +% 1;
        }
        pub fn formatLengthMultiLineStringLiteral(format: anytype) usize {
            var len: usize = 3;
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => len +%= 3,
                    '\t' => len +%= 2,
                    else => len +%= 1,
                }
            }
            return len +% 1;
        }
        pub fn formatWriteStringLiteral(format: anytype, array: anytype) void {
            array.writeOne('"');
            for (format.value) |byte| {
                array.writeFormat(esc(byte));
            }
            array.writeOne('"');
        }
        pub fn formatWriteMultiLineStringLiteral(format: anytype, array: anytype) void {
            array.writeMany("\n\\\\");
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => array.writeMany("\n\\\\"),
                    '\t' => array.writeMany("\\t"),
                    else => array.writeOne(byte),
                }
            }
            array.writeOne('\n');
        }
        pub fn formatWriteBufStringLiteral(format: anytype, buf: [*]u8) usize {
            var len: usize = 1;
            buf[0] = '"';
            for (format.value) |byte| {
                len +%= esc(byte).formatWriteBuf(buf + len);
            }
            buf[len] = '"';
            return len +% 1;
        }
        pub fn formatWriteBufMultiLineStringLiteral(format: anytype, buf: [*]u8) usize {
            var len: usize = 3;
            @as(*[3]u8, @ptrCast(buf)).* = "\n\\\\".*;
            for (format.value) |byte| {
                switch (byte) {
                    '\n' => {
                        @as(*[3]u8, @ptrCast(buf + len)).* = "\n\\\\".*;
                        len +%= 3;
                    },
                    '\t' => {
                        @as(*[2]u8, @ptrCast(buf + len)).* = "\\t".*;
                        len +%= 2;
                    },
                    else => {
                        buf[len] = byte;
                        len +%= 1;
                    },
                }
            }
            buf[len] = '\n';
            return len +% 1;
        }
        fn isMultiLine(values: []const u8) bool {
            for (values) |value| {
                if (value == '\n') return true;
            }
            return false;
        }
        const StringLiteral = GenericEscapedStringFormat(.{});
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.forward)
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return formatWriteMultiLineStringLiteral(format, array);
                        } else {
                            return formatWriteStringLiteral(format, array);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return stringLiteral(format.value).formatWrite(array);
                    }
                }
            }
            return formatWriteAny(format, array);
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return len +% formatWriteBufMultiLineStringLiteral(format, buf);
                        } else {
                            return len +% formatWriteBufStringLiteral(format, buf);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return stringLiteral(format.value).formatWriteBuf(buf);
                    }
                }
            }
            return len +% formatWriteBufAny(format, buf);
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(format.value)) {
                            return len +% formatLengthMultiLineStringLiteral(format);
                        } else {
                            return len +% formatLengthStringLiteral(format);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return stringLiteral(format.value).formatLength();
                    }
                }
            }
            return len +% formatLengthAny(format);
        }
    };
    return T;
}
pub fn PointerManyFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const T = struct {
        value: Pointer,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const type_info: builtin.Type = @typeInfo(Pointer);
        const child: type = type_info.Pointer.child;
        const max_len: ?comptime_int = null;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (spec.forward) {
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            }
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                var len: usize = 0;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                writeFormat(array, slice_fmt);
            } else {
                array.writeMany(@typeName(Pointer) ++ "{ ... }");
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                len = slice_fmt.formatWriteBuf(buf);
            } else {
                @as(*[7]u8, @ptrCast(buf)).* = "{ ... }".*;
                len +%= 7;
            }
            return len;
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                while (!mem.testEqual(child, format.value[len], sentinel)) len +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                const slice_fmt_type: type = PointerSliceFormat(spec, Slice);
                const slice_fmt: slice_fmt_type = .{ .value = format.value[0..len :sentinel] };
                len +%= slice_fmt.formatLength();
            } else {
                len +%= 7;
            }
            return len;
        }
    };
    return T;
}
pub fn OptionalFormat(comptime spec: RenderSpec, comptime Optional: type) type {
    const T = struct {
        value: Optional,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Optional).Optional.child;
        const type_name: []const u8 = typeName(Optional);
        const max_len: ?comptime_int = (4 +% type_name.len +% 2) +% @max(1 +% ChildFormat.max_len, 5);
        const render_readable: bool = true;
        pub fn formatWrite(format: anytype, array: anytype) void {
            if (spec.forward) {
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            }
            if (!render_readable) {
                array.writeCount(4, "@as(".*);
                array.writeMany(type_name);
                array.writeCount(2, ", ".*);
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                writeFormat(array, sub_format);
            } else {
                array.writeCount(4, "null".*);
            }
            if (!render_readable) {
                array.writeOne(')');
            }
        }
        pub fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            if (!render_readable) {
                @as(*[4]u8, @ptrCast(buf)).* = "@as(".*;
                len +%= 4;
                @as(meta.TypeName(Optional), buf + len).* = @typeName(Optional).*;
                len +%= @typeName(Optional).len;
                @as(*[2]u8, @ptrCast(buf)).* = ", ".*;
                len +%= 2;
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                len +%= sub_format.formatWriteBuf(buf);
            } else {
                @as(*[4]u8, @ptrCast(buf)).* = "null".*;
                len +%= 4;
            }
            if (!render_readable) {
                buf[len] = ')';
                len +%= 1;
            }
            return len;
        }
        pub fn formatLength(format: anytype) usize {
            var len: usize = 0;
            if (!render_readable) {
                len +%= 4 +% type_name.len +% 2;
            }
            if (format.value) |optional| {
                const sub_format: ChildFormat = .{ .value = optional };
                len +%= sub_format.formatLength();
            } else {
                len +%= 4;
            }
            if (!render_readable) {
                len +%= 1;
            }
            return len;
        }
    };
    return T;
}
pub const NullFormat = struct {
    comptime value: @TypeOf(null) = null,
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () usize = formatLength,
    const Format = @This();
    const max_len: ?comptime_int = 4;
    pub fn formatWrite(array: anytype) void {
        array.writeMany("null");
    }
    pub fn formatLength() usize {
        return 4;
    }
};
pub const VoidFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () usize = formatLength,
    const Format = @This();
    const max_len: ?comptime_int = 2;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "{}".*);
    }
    pub fn formatLength() usize {
        return 2;
    }
};
pub const NoReturnFormat = struct {
    comptime value: void = {},
    comptime formatWrite: fn (anytype) void = formatWrite,
    comptime formatLength: fn () usize = formatLength,
    const Format = @This();
    const max_len: ?comptime_int = 8;
    pub fn formatWrite(array: anytype) void {
        array.writeCount(2, "noreturn".*);
    }
    pub fn formatLength() usize {
        return 8;
    }
};
pub fn VectorFormat(comptime spec: RenderSpec, comptime Vector: type) type {
    const T = struct {
        value: Vector,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const vector_info: builtin.Type = @typeInfo(Vector);
        const child: type = vector_info.Vector.child;
        const type_name: TypeName(Vector, spec) = typeName(Vector, spec);
        const max_len: ?comptime_int = if (ChildFormat.max_len) |len| (type_name.len +% 2) + vector_info.Vector.len *% (len +% 2) else null;
        pub fn formatWrite(format: Format, array: anytype) void {
            if (spec.forward)
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            if (vector_info.Vector.len == 0) {
                array.writeMany(type_name);
                array.writeMany("{}");
            } else {
                array.writeMany(type_name);
                array.writeMany("{ ");
                comptime var idx: usize = 0;
                inline while (idx != vector_info.Vector.len) : (idx +%= 1) {
                    const element_format: ChildFormat = .{ .value = format.value[idx] };
                    writeFormat(array, element_format);
                    array.writeCount(2, ", ".*);
                }
                array.overwriteManyBack(" }");
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            var len: usize = 0;
            if (vector_info.Vector.len == 0) {
                @as(*[type_name.len +% 2]u8, @ptrCast(buf + len)).* = (type_name ++ "{}").*;
                len +%= type_name.len +% 2;
            } else {
                @as(*[type_name.len +% 2]u8, @ptrCast(buf + len)).* = (type_name ++ "{ ").*;
                len +%= type_name.len +% 2;
                comptime var idx: usize = 0;
                inline while (idx != vector_info.Vector.len) : (idx +%= 1) {
                    const element_format: ChildFormat = .{ .value = format.value[idx] };
                    len +%= element_format.formatWriteBuf(buf + len);
                    @as(*[2]u8, @ptrCast(buf + len)).* = ", ".*;
                    len +%= 2;
                }
                @as(*[2]u8, @ptrCast(buf + (len -% 2))).* = ", ".*;
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = type_name.len +% 2;
            comptime var idx: u64 = 0;
            inline while (idx != vector_info.Vector.len) : (idx +%= 1) {
                const element_format: ChildFormat = .{ .value = format.value[idx] };
                len +%= element_format.formatLength() +% 2;
            }
            return len;
        }
    };
    return T;
}
pub fn ErrorUnionFormat(comptime spec: RenderSpec, comptime ErrorUnion: type) type {
    const T = struct {
        value: ErrorUnion,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(ErrorUnion);
        const PayloadFormat: type = AnyFormat(spec, type_info.ErrorUnion.payload);
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            var len: usize = 0;
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                return payload_format.formatWriteBuf(buf);
            } else |any_error| {
                @as(*[6]u8, buf).* = "error.".*;
                len +%= 6;
                @memcpy(buf + len, @errorName(any_error));
                len +%= @errorName(any_error).len;
            }
            return len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            if (spec.forward)
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                writeFormat(array, payload_format);
            } else |any_error| {
                array.writeMany("error.");
                array.writeMany(@errorName(any_error));
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (format.value) |value| {
                const payload_format: PayloadFormat = .{ .value = value };
                len +%= payload_format.formatLength();
            } else |any_error| {
                len +%= 6;
                len +%= @errorName(any_error).len;
            }
            return len;
        }
    };
    return T;
}
pub fn ErrorSetFormat(comptime ErrorSet: type) type {
    const T = struct {
        value: ErrorSet,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeMany("error.");
            array.writeMany(@errorName(format.value));
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            buf[0..6].* = "error.".*;
            @memcpy(buf + 6, @errorName(format.value));
            return 6 +% @errorName(format.value).len;
        }
        pub fn formatLength(format: Format) usize {
            return 6 +% @errorName(format.value).len;
        }
    };
    return T;
}
pub fn ContainerFormat(comptime spec: RenderSpec, comptime Struct: type) type {
    const T = struct {
        value: Struct,
        const Format = @This();
        const values_spec: RenderSpec = blk: {
            var tmp: RenderSpec = spec;
            tmp.omit_type_names = true;
            break :blk spec;
        };
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                const values_format: ValuesFormat = .{ .value = format.value.readAll() };
                return values_format.formatWriteBuf(buf);
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                return values_format.formatWriteBuf(buf);
            }
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                const values_format: ValuesFormat = .{ .value = format.value.readAll() };
                writeFormat(array, values_format);
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                writeFormat(array, values_format);
            }
        }
        pub fn formatLength(format: Format) usize {
            var len: usize = 0;
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                const values_format: ValuesFormat = .{ .value = format.value.readAll() };
                len +%= values_format.formatLength();
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                const values_format: ValuesFormat = .{ .value = format.value.readAll(u8) };
                len +%= values_format.formatLength();
            }
            return len;
        }
    };
    return T;
}
pub fn FormatFormat(comptime Struct: type) type {
    const T = struct {
        value: Struct,
        const Format = @This();
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return format.value.formatWriteBuf(buf);
        }
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return writeFormat(array, format.value);
        }
        pub inline fn formatLength(format: Format) usize {
            return format.value.formatLength();
        }
    };
    return T;
}
pub const TypeDescrFormatSpec = struct {
    token: type = []const u8,
    depth: u64 = 0,
    decls: bool = false,
    identifier_name: bool = true,
    forward: bool = false,
    option_5: bool = false,
    tokens: Tokens = .{},
    default_field_values: DefaultFieldValues = .{ .exact = .{} },
    const DefaultFieldValues = union(enum) {
        omit,
        fast,
        exact: RenderSpec,
        exact_safe: RenderSpec,
    };
    const Tokens = struct {
        decl: [:0]const u8 = "pub const ",
        lbrace: [:0]const u8 = " {\n",
        equal: [:0]const u8 = " = ",
        rbrace: [:0]const u8 = "}",
        next: [:0]const u8 = ",\n",
        end: [:0]const u8 = ";\n",
        colon: [:0]const u8 = ": ",
        indent: [:0]const u8 = "    ",
    };
};
pub fn GenericTypeDescrFormat(comptime spec: TypeDescrFormatSpec) type {
    const U = union(enum) {
        type_decl: Declaration,
        type_ref: Reference,
        const Format = @This();
        const tab = .{
            .decl = spec.tokens.decl[0..spec.tokens.decl.len].*,
            .lbrace = spec.tokens.lbrace[0..spec.tokens.lbrace.len].*,
            .equal = spec.tokens.equal[0..spec.tokens.equal.len].*,
            .rbrace = spec.tokens.rbrace[0..spec.tokens.rbrace.len].*,
            .next = spec.tokens.next[0..spec.tokens.next.len].*,
            .end = spec.tokens.end[0..spec.tokens.end.len].*,
            .colon = spec.tokens.colon[0..spec.tokens.colon.len].*,
            .indent = spec.tokens.indent[0..spec.tokens.indent.len].*,
        };
        pub var scope: []const Declaration = &.{};
        pub const Reference = struct { spec: spec.token, type: *const Format };
        pub const Container = struct {
            spec: spec.token,
            fields: []const Field = &.{},
            decls: []const Declaration = &.{},
            fn matchDeclaration(format: Container) ?Format {
                for (scope) |decl| {
                    if (mem.testEqualMemory(Container, format, decl.defn.?)) {
                        return .{ .type_decl = .{ .name = decl.name } };
                    }
                }
                return null;
            }
            fn formatWriteInternal(format: Container, array: anytype, depth: usize) void {
                if (spec.option_5) {
                    if (matchDeclaration(format)) |decl| {
                        return decl.formatWriteInternal(array, depth +% 1);
                    }
                }
                array.writeMany(format.spec);
                array.writeMany(spec.tokens.lbrace);
                for (0..depth +% 1) |_| array.writeMany(spec.tokens.indent);
                for (format.fields) |field| {
                    field.formatWriteInternal(array, depth +% 1);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        if (field.name != null and
                            field.defn != null)
                        {
                            field.formatWriteInternal(array, depth +% 1);
                        }
                    }
                }
                array.undefine(spec.tokens.indent.len);
                array.writeMany(spec.tokens.rbrace);
            }
            fn formatWriteBufInternal(format: Container, buf: [*]u8, depth: usize) usize {
                if (spec.option_5) {
                    if (matchDeclaration(format)) |decl| {
                        return decl.formatWriteBufInternal(buf, depth);
                    }
                }
                var len: usize = 0;
                @memcpy(buf + len, format.spec);
                len +%= format.spec.len;
                @as(*@TypeOf(Format.tab.lbrace), @ptrCast(buf + len)).* = Format.tab.lbrace;
                len +%= Format.tab.lbrace.len;
                for (0..depth +% 1) |_| {
                    @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                    len +%= Format.tab.indent.len;
                }
                for (format.fields) |field| {
                    len +%= field.formatWriteBufInternal(buf + len, depth +% 1);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        if (field.name != null and
                            field.defn != null)
                        {
                            len +%= field.formatWriteBufInternal(buf + len, depth +% 1);
                        }
                    }
                }
                len -%= spec.tokens.indent.len;
                @as(*@TypeOf(Format.tab.rbrace), @ptrCast(buf + len)).* = Format.tab.rbrace;
                len +%= Format.tab.rbrace.len;
                return len;
            }
            fn formatLengthInternal(format: Container, depth: usize) usize {
                if (spec.option_5) {
                    if (matchDeclaration(format)) |decl| {
                        return decl.formatLengthInternal(depth);
                    }
                }
                var len: usize = 0;
                len +%= format.spec.len;
                len +%= Format.tab.lbrace.len;
                len +%= (depth +% 1) *% Format.tab.indent.len;
                for (format.fields) |field| {
                    len +%= field.formatLengthInternal(depth +% 1);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        if (field.name != null and
                            field.defn != null)
                        {
                            len +%= field.formatLengthInternal(depth +% 1);
                        }
                    }
                }
                len -%= spec.tokens.indent.len;
                len +%= Format.tab.rbrace.len;
                return len;
            }
        };
        pub const Declaration = struct {
            name: ?spec.token = null,
            defn: ?Container = null,
            pub fn formatWriteInternal(type_decl: Declaration, array: anytype, depth: usize) void {
                if (spec.depth != 0 and
                    spec.depth != depth)
                {
                    for (0..depth) |_| array.writeMany(spec.tokens.indent);
                }
                if (type_decl.name) |type_name| {
                    if (type_decl.defn) |type_defn| {
                        array.writeMany(spec.tokens.decl);
                        if (spec.identifier_name) {
                            array.writeFormat(identifier(type_name));
                        } else {
                            array.writeMany(type_name);
                        }
                        array.writeMany(spec.tokens.equal);
                        type_defn.formatWriteInternal(array, depth);
                        array.writeMany(spec.tokens.end);
                        for (0..depth) |_| array.writeMany(spec.tokens.indent);
                    } else {
                        array.writeMany(type_name);
                    }
                } else {
                    if (type_decl.defn) |type_defn| {
                        type_defn.formatWriteInternal(array, depth);
                    }
                }
            }
            fn formatWriteBufInternal(type_decl: Declaration, buf: [*]u8, depth: usize) usize {
                var len: usize = 0;
                if (spec.depth != 0 and
                    spec.depth != depth)
                {
                    for (0..depth) |_| {
                        @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                        len +%= Format.tab.indent.len;
                    }
                }
                if (type_decl.name) |type_name| {
                    if (type_decl.defn) |type_defn| {
                        @as(*@TypeOf(Format.tab.decl), @ptrCast(buf + len)).* = Format.tab.decl;
                        len +%= Format.tab.decl.len;
                        if (spec.identifier_name) {
                            len +%= identifier(type_name).formatWriteBuf(buf + len);
                        } else {
                            @memcpy(buf, type_name);
                            len +%= type_name.len;
                        }
                        @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                        len +%= Format.tab.equal.len;
                        len +%= type_defn.formatWriteBufInternal(buf + len, depth);
                        @as(*@TypeOf(Format.tab.end), @ptrCast(buf + len)).* = Format.tab.end;
                        len +%= Format.tab.end.len;
                        for (0..depth) |_| {
                            @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                            len +%= Format.tab.indent.len;
                        }
                    } else {
                        @memcpy(buf, type_name);
                        len +%= type_name.len;
                    }
                } else {
                    if (type_decl.defn) |type_defn| {
                        len +%= type_defn.formatWriteBufInternal(buf, depth);
                    }
                }
                return len;
            }
            pub fn formatLengthInternal(type_decl: Declaration, depth: usize) usize {
                var len: usize = 0;
                if (spec.depth != 0 and
                    spec.depth != depth)
                {
                    len +%= depth *% Format.tab.indent.len;
                }
                if (type_decl.name) |type_name| {
                    if (type_decl.defn) |type_defn| {
                        len +%= Format.tab.decl.len;
                        if (spec.identifier_name) {
                            len +%= identifier(type_name).formatLength();
                        } else {
                            len +%= type_name.len;
                        }
                        len +%= Format.tab.equal.len;
                        len +%= type_defn.formatLengthInternal(depth);
                        len +%= Format.tab.end.len;
                        len +%= depth *% Format.tab.indent.len;
                    } else {
                        len +%= type_name.len;
                    }
                } else {
                    if (type_decl.defn) |type_defn| {
                        len +%= type_defn.formatLengthInternal(depth);
                    }
                }
                return len;
            }
        };
        pub const Field = struct {
            name: spec.token,
            type: ?Format = null,
            value: Value = .{ .default = null },
            const Value = union(enum) {
                default: ?spec.token,
                enumeration: isize,
            };
            fn formatWriteInternal(format: Field, array: anytype, depth: usize) void {
                if (spec.identifier_name) {
                    identifier(format.name).formatWrite(array);
                } else {
                    array.writeMany(format.name);
                }
                if (format.type) |field_type| {
                    array.writeMany(spec.tokens.colon);
                    field_type.formatWriteInternal(array, depth);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            array.writeMany(spec.tokens.equal);
                            array.writeMany(default_value);
                        }
                    },
                    .enumeration => {
                        array.writeMany(spec.tokens.equal);
                        array.writeFormat(idsize(format.value.enumeration));
                    },
                }
                array.writeMany(spec.tokens.next);
                for (0..depth) |_| array.writeMany(spec.tokens.indent);
            }
            fn formatWriteBufInternal(format: Field, buf: [*]u8, depth: usize) usize {
                @setRuntimeSafety(builtin.is_safe);
                var len: usize = 0;
                if (spec.identifier_name) {
                    len +%= identifier(format.name).formatWriteBuf(buf);
                } else {
                    @memcpy(buf, format.name);
                    len +%= format.name;
                }
                if (format.type) |field_type| {
                    @as(*@TypeOf(Format.tab.colon), @ptrCast(buf + len)).* = Format.tab.colon;
                    len +%= Format.tab.colon.len;
                    len +%= field_type.formatWriteBufInternal(buf + len, depth);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                            len +%= Format.tab.equal.len;
                            @memcpy(buf + len, default_value);
                            len +%= default_value.len;
                        }
                    },
                    .enumeration => {
                        @as(*@TypeOf(Format.tab.equal), @ptrCast(buf + len)).* = Format.tab.equal;
                        len +%= Format.tab.equal.len;
                        len +%= idsize(format.value.enumeration).formatWriteBuf(buf + len);
                    },
                }
                @as(*@TypeOf(Format.tab.next), @ptrCast(buf + len)).* = Format.tab.next;
                len +%= Format.tab.next.len;
                for (0..depth) |_| {
                    @as(*@TypeOf(Format.tab.indent), @ptrCast(buf + len)).* = Format.tab.indent;
                    len +%= Format.tab.indent.len;
                }
                return len;
            }
            fn formatLengthInternal(format: Field, depth: usize) usize {
                var len: usize = 0;
                if (spec.identifier_name) {
                    len +%= identifier(format.name).formatLength();
                } else {
                    len +%= format.name.len;
                }
                if (format.type) |field_type| {
                    len +%= spec.tokens.colon.len;
                    len +%= field_type.formatLengthInternal(depth);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            len +%= Format.tab.equal.len;
                            len +%= default_value.len;
                        }
                    },
                    .enumeration => {
                        len +%= Format.tab.equal.len;
                        len +%= idsize(format.value.enumeration).formatLength();
                    },
                }
                len +%= spec.tokens.next.len;
                len +%= depth *% spec.tokens.indent.len;
                return len;
            }
        };
        pub fn formatWrite(format: Format, array: anytype) void {
            if (spec.forward)
                return array.define(@call(.always_inline, formatWriteBuf, .{
                    format, array.referAllUndefined().ptr,
                }));
            return format.formatWriteInternal(array, spec.depth);
        }
        fn formatWriteInternal(type_descr: Format, array: anytype, depth: usize) void {
            switch (type_descr) {
                .type_ref => |type_ref| {
                    array.writeMany(type_ref.spec);
                    type_ref.type.formatWriteInternal(array, depth);
                },
                .type_decl => |type_decl| {
                    type_decl.formatWriteInternal(array, depth);
                },
            }
        }
        pub fn formatWriteBuf(type_descr: Format, buf: [*]u8) usize {
            return type_descr.formatWriteBufInternal(buf, spec.depth);
        }
        fn formatWriteBufInternal(type_descr: Format, buf: [*]u8, depth: usize) usize {
            @setRuntimeSafety(builtin.is_safe);
            var len: usize = 0;
            switch (type_descr) {
                .type_ref => |type_ref| {
                    @memcpy(buf + len, type_ref.spec);
                    len +%= type_ref.spec.len;
                    len +%= type_ref.type.formatWriteBufInternal(buf + len, depth);
                },
                .type_decl => |type_decl| {
                    len +%= type_decl.formatWriteBufInternal(buf, depth);
                },
            }
            return len;
        }
        pub fn formatLength(type_descr: Format) usize {
            return type_descr.formatLengthInternal(spec.depth);
        }
        fn formatLengthInternal(type_descr: Format, depth: usize) usize {
            var len: usize = 0;
            switch (type_descr) {
                .type_ref => |type_ref| {
                    len +%= type_ref.spec.len;
                    len +%= type_ref.type.formatLengthInternal(depth);
                },
                .type_decl => |type_decl| {
                    len +%= type_decl.formatLengthInternal(depth);
                },
            }
            return len;
        }
        pub fn cast(type_descr: anytype, comptime cast_spec: TypeDescrFormatSpec) GenericFormat(cast_spec) {
            debug.assert(
                cast_spec.default_field_values ==
                    spec.default_field_values,
            );
            return @as(*const GenericFormat(cast_spec), @ptrCast(type_descr)).*;
        }
        inline fn defaultFieldValue(comptime field_type: type, comptime default_value_opt: ?*const anyopaque) ?spec.token {
            if (default_value_opt) |default_value_ptr| {
                switch (spec.default_field_values) {
                    .omit => return null,
                    .fast => return cx(default_value_ptr),
                    .exact => |render_spec| {
                        return comptime eval(render_spec, mem.pointerOpaque(field_type, default_value_ptr).*);
                    },
                    .exact_safe => |render_spec| {
                        const fast: []const u8 = cx(default_value_ptr);
                        if (fast[0] != '.') {
                            return fast;
                        }
                        return comptime eval(render_spec, mem.pointerOpaque(field_type, default_value_ptr).*);
                    },
                }
            } else {
                return null;
            }
        }
        inline fn defaultDeclareCriteria(comptime T: type, comptime decl: builtin.Type.Declaration) ?type {
            const u = @field(T, decl.name);
            const U = @TypeOf(u);
            if (U == type and meta.isContainer(u) and u != T) {
                return u;
            }
            return null;
        }
        const TypeDecl = struct { []const u8, type };
        const types: *[]const TypeDecl = blk: {
            var res: []const TypeDecl = &.{};
            break :blk &res;
        };
        pub inline fn declare(comptime name: []const u8, comptime T: type) Format {
            comptime {
                @setEvalBranchQuota(~@as(u32, 0));
                for (types.*) |type_decl| {
                    if (type_decl[1] == T) {
                        return .{ .type_decl = .{ .name = type_decl[0] } };
                    }
                } else {
                    types.* = types.* ++ [1]TypeDecl{.{ name, T }};
                }
                const type_info: builtin.Type = @typeInfo(T);
                switch (type_info) {
                    else => return .{ .type_decl = .{ .name = @typeName(T) } },
                    .Struct => |struct_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (struct_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Union => |union_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (union_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Enum => |enum_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (enum_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = @intCast(field.value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = @intCast(field.value) },
                                }};
                            }
                            return .{ .type_decl = .{ .name = name, .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Optional => |optional_info| {
                        return .{ .type_ref = .{
                            .spec = typeDeclSpecifier(type_info),
                            .type = &init(optional_info.child),
                        } };
                    },
                    .Pointer => |pointer_info| {
                        return .{ .type_ref = .{ .name = name, .defn = .{
                            .spec = typeDeclSpecifier(type_info),
                            .type = &init(pointer_info.child),
                        } } };
                    },
                }
            }
        }
        pub fn init(comptime T: type) Format {
            comptime {
                @setEvalBranchQuota(~@as(u32, 0));
                for (types.*) |type_decl| {
                    if (type_decl[1] == T) {
                        return .{ .type_decl = .{ .name = type_decl[0] } };
                    }
                }
                const type_info: builtin.Type = @typeInfo(T);
                switch (type_info) {
                    else => return .{ .type_decl = .{ .name = @typeName(T) } },
                    .Struct => |struct_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (struct_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (struct_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                    .value = .{ .default = defaultFieldValue(field.type, field.default_value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Union => |union_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (union_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (union_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .type = init(field.type),
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Enum => |enum_info| {
                        if (spec.decls) {
                            var type_decls: []const Declaration = &.{};
                            for (enum_info.decls) |decl| {
                                if (defaultDeclareCriteria(T, decl)) |U| {
                                    type_decls = type_decls ++ [1]Declaration{declare(decl.name, U).type_decl};
                                }
                            }
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = @intCast(field.value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                                .decls = type_decls,
                            } } };
                        } else {
                            var type_fields: []const Field = &.{};
                            for (enum_info.fields) |field| {
                                type_fields = type_fields ++ [1]Field{.{
                                    .name = field.name,
                                    .value = .{ .enumeration = @intCast(field.value) },
                                }};
                            }
                            return .{ .type_decl = .{ .defn = .{
                                .spec = typeDeclSpecifier(type_info),
                                .fields = type_fields,
                            } } };
                        }
                    },
                    .Optional => |optional_info| {
                        return .{ .type_ref = .{
                            .spec = typeDeclSpecifier(type_info),
                            .type = &init(optional_info.child),
                        } };
                    },
                    .Pointer => |pointer_info| {
                        return .{ .type_ref = .{
                            .spec = typeDeclSpecifier(type_info),
                            .type = &init(pointer_info.child),
                        } };
                    },
                }
            }
        }
    };
    return U;
}
pub const U8xLEB128 = GenericLEB128Format(u8);
pub const U16xLEB128 = GenericLEB128Format(u16);
pub const U32xLEB128 = GenericLEB128Format(u32);
pub const U64xLEB128 = GenericLEB128Format(u64);
pub const I8xLEB128 = GenericLEB128Format(i8);
pub const I16xLEB128 = GenericLEB128Format(i16);
pub const I32xLEB128 = GenericLEB128Format(i32);
pub const I64xLEB128 = GenericLEB128Format(i64);
pub const Ib8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Ib16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Ib32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Ib64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Ib128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Io8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 8, .signedness = .signed, .width = .min, .prefix = "0o" });
pub const Io16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 8, .signedness = .signed, .width = .min, .prefix = "0o" });
pub const Io32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 8, .signedness = .signed, .width = .min, .prefix = "0o" });
pub const Io64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 8, .signedness = .signed, .width = .min, .prefix = "0o" });
pub const Io128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 8, .signedness = .signed, .width = .min, .prefix = "0o" });
pub const Id8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 10, .signedness = .signed, .width = .min });
pub const Id16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 10, .signedness = .signed, .width = .min });
pub const Id32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 10, .signedness = .signed, .width = .min });
pub const Id64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 10, .signedness = .signed, .width = .min });
pub const Id128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 10, .signedness = .signed, .width = .min });
pub const Ix8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .signed, .width = .min, .prefix = "0x" });
pub const Ix16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 16, .signedness = .signed, .width = .min, .prefix = "0x" });
pub const Ix32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 16, .signedness = .signed, .width = .min, .prefix = "0x" });
pub const Ix64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 16, .signedness = .signed, .width = .min, .prefix = "0x" });
pub const Ix128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 16, .signedness = .signed, .width = .min, .prefix = "0x" });
pub const Iz8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 36, .signedness = .signed, .width = .min, .prefix = "0z" });
pub const Iz16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 36, .signedness = .signed, .width = .min, .prefix = "0z" });
pub const Iz32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 36, .signedness = .signed, .width = .min, .prefix = "0z" });
pub const Iz64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 36, .signedness = .signed, .width = .min, .prefix = "0z" });
pub const Iz128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 36, .signedness = .signed, .width = .min, .prefix = "0z" });
pub const Ub8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
pub const Ub16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
pub const Ub32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
pub const Ub64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
pub const Uo8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Uo16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Uo32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Uo64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Uo128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Ud8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Ud16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Ud32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Ud64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Ud128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Ux8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Ux16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Ux32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Ux64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Ux128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Uz8 = GenericPolynomialFormat(.{ .bits = 8, .radix = 36, .signedness = .unsigned, .width = .min, .prefix = "0z" });
pub const Uz16 = GenericPolynomialFormat(.{ .bits = 16, .radix = 36, .signedness = .unsigned, .width = .min, .prefix = "0z" });
pub const Uz32 = GenericPolynomialFormat(.{ .bits = 32, .radix = 36, .signedness = .unsigned, .width = .min, .prefix = "0z" });
pub const Uz64 = GenericPolynomialFormat(.{ .bits = 64, .radix = 36, .signedness = .unsigned, .width = .min, .prefix = "0z" });
pub const Uz128 = GenericPolynomialFormat(.{ .bits = 128, .radix = 36, .signedness = .unsigned, .width = .min, .prefix = "0z" });
pub const Ubsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 2, .signedness = .unsigned, .width = .max, .prefix = "0b" });
pub const Uosize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 8, .signedness = .unsigned, .width = .min, .prefix = "0o" });
pub const Udsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 10, .signedness = .unsigned, .width = .min });
pub const Uxsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 16, .signedness = .unsigned, .width = .min, .prefix = "0x" });
pub const Ibsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 2, .signedness = .signed, .width = .max, .prefix = "0b" });
pub const Iosize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 8, .signedness = .signed, .width = .min });
pub const Idsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 10, .signedness = .signed, .width = .min });
pub const Ixsize = GenericPolynomialFormat(.{ .bits = mem.word_bit_size, .radix = 16, .signedness = .signed, .width = .min });
pub const Esc = GenericPolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .unsigned, .width = .max, .prefix = "\\x" });
pub const NSec = GenericPolynomialFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 9 },
    .range = .{ .min = 0, .max = 999999999 },
});
pub const Year = GenericPolynomialFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 0, .max = 9999 },
});
pub const Month = GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 12 },
});
pub const MonthDay = GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 31 },
});
pub const YearDay = GenericPolynomialFormat(.{
    .bits = 16,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 1, .max = 366 },
});
pub const Hour = GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 23 },
});
pub const Minute = GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
});
pub const Second = GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
});
pub fn Ud(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 10,
        .signedness = .unsigned,
        .width = .min,
    });
}
pub fn Udh(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 10,
        .signedness = .unsigned,
        .width = .min,
        .separator = .{},
    });
}
pub fn Ub(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 2,
        .signedness = .unsigned,
        .width = .max,
        .prefix = "0b",
    });
}
pub fn Ux(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 16,
        .signedness = .unsigned,
        .width = .min,
        .prefix = "0x",
    });
}
pub fn Id(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 10,
        .signedness = .signed,
        .width = .min,
    });
}
pub fn Idh(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 10,
        .signedness = .signed,
        .width = .min,
        .separator = .{},
    });
}
pub fn Ib(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 2,
        .signedness = .signed,
        .width = .max,
        .prefix = "0b",
    });
}
pub fn Ix(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = meta.alignBitSizeOfAbove(Int),
        .radix = 16,
        .signedness = .signed,
        .width = .min,
        .prefix = "0x",
    });
}
pub fn Xb(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = @bitSizeOf(Int),
        .prefix = "0b",
        .radix = 2,
        .signedness = @typeInfo(Int).Int.signedness,
        .width = .max,
    });
}
pub fn Xo(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = @bitSizeOf(Int),
        .prefix = "0o",
        .radix = 8,
        .signedness = @typeInfo(Int).Int.signedness,
        .width = .min,
    });
}
pub fn Xd(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = @bitSizeOf(Int),
        .prefix = null,
        .radix = 10,
        .signedness = @typeInfo(Int).Int.signedness,
        .width = .min,
    });
}
pub fn Xx(comptime Int: type) type {
    return GenericPolynomialFormat(.{
        .bits = @bitSizeOf(Int),
        .prefix = "0x",
        .radix = 16,
        .signedness = @typeInfo(Int).Int.signedness,
        .width = .min,
    });
}
pub const UDel = GenericChangedIntFormat(.{
    .old_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
    .new_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
    .del_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
});
pub const BytesDiff = GenericChangedBytesFormat(.{});
pub const BloatDiff = GenericChangedBytesFormat(.{
    .dec_style = "\x1b[92m-",
    .inc_style = "\x1b[91m+",
    .no_style = "\x1b[0m",
    .to_from_zero = false,
});
pub const AddrDiff = GenericChangedIntFormat(.{
    .del_fmt_spec = Ux64.specification,
    .new_fmt_spec = Ux64.specification,
    .old_fmt_spec = Ux64.specification,
});
