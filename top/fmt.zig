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
const fmt_is_safe: bool = false;
pub fn Interface(comptime Format: type) type {
    return struct {
        pub inline fn formatWrite(format: anytype, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub inline fn formatWriteBuf(format: anytype, buf: [*]u8) usize {
            return strlen(Format.write(buf, format.value), buf);
        }
        pub inline fn formatLength(format: anytype) usize {
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
    @setRuntimeSafety(fmt_is_safe);
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
    comptime {
        if (value < 0) {
            const s: []const u8 = @typeName([-value]void);
            return "-" ++ s[1 .. s.len -% 5];
        } else {
            const s: []const u8 = @typeName([value]void);
            return s[1 .. s.len -% 5];
        }
    }
}
pub inline fn cx(comptime value: anytype) *const [@typeName(@TypeOf(.{ ._ = value })).len -% @typeName(@TypeOf(value)).len -% 23]u8 {
    comptime {
        const Value = @TypeOf(value);
        if (@typeInfo(Value) == .Fn) {
            return cx(&value);
        }
        const type_name: []const u8 = @typeName(@TypeOf(.{ ._ = value }));
        return type_name[22 +% @typeName(Value).len .. type_name.len -% 1];
    }
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
pub fn strcpyEqu2(dest: [*]u8, comptime src: []const u8) [*]u8 {
    @setRuntimeSafety(false);
    dest[0..src.len].* = src[0..src.len].*;
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
const lit_char_dwords: []const u32 = &.{
    808482908,  825260124,  842037340,  858814556,
    875591772,  892368988,  909146204,  925923420,
    942700636,  29788,      28252,      1647343708,
    1664120924, 29276,      1697675356, 1714452572,
    808548444,  825325660,  842102876,  858880092,
    875657308,  892434524,  909211740,  925988956,
    942766172,  959543388,  1630632028, 1647409244,
    1664186460, 1680963676, 1697740892, 1714518108,
    32,         33,         8796,       35,
    36,         37,         38,         39,
    40,         41,         42,         43,
    44,         45,         46,         47,
    48,         49,         50,         51,
    52,         53,         54,         55,
    56,         57,         58,         59,
    60,         61,         62,         63,
    64,         65,         66,         67,
    68,         69,         70,         71,
    72,         73,         74,         75,
    76,         77,         78,         79,
    80,         81,         82,         83,
    84,         85,         86,         87,
    88,         89,         90,         91,
    23644,      93,         94,         95,
    96,         97,         98,         99,
    100,        101,        102,        103,
    104,        105,        106,        107,
    108,        109,        110,        111,
    112,        113,        114,        115,
    116,        117,        118,        119,
    120,        121,        122,        123,
    124,        125,        126,        1714911324,
    809007196,  825784412,  842561628,  859338844,
    876116060,  892893276,  909670492,  926447708,
    943224924,  960002140,  1631090780, 1647867996,
    1664645212, 1681422428, 1698199644, 1714976860,
    809072732,  825849948,  842627164,  859404380,
    876181596,  892958812,  909736028,  926513244,
    943290460,  960067676,  1631156316, 1647933532,
    1664710748, 1681487964, 1698265180, 1715042396,
    811694172,  828471388,  845248604,  862025820,
    878803036,  895580252,  912357468,  929134684,
    945911900,  962689116,  1633777756, 1650554972,
    1667332188, 1684109404, 1700886620, 1717663836,
    811759708,  828536924,  845314140,  862091356,
    878868572,  895645788,  912423004,  929200220,
    945977436,  962754652,  1633843292, 1650620508,
    1667397724, 1684174940, 1700952156, 1717729372,
    811825244,  828602460,  845379676,  862156892,
    878934108,  895711324,  912488540,  929265756,
    946042972,  962820188,  1633908828, 1650686044,
    1667463260, 1684240476, 1701017692, 1717794908,
    811890780,  828667996,  845445212,  862222428,
    878999644,  895776860,  912554076,  929331292,
    946108508,  962885724,  1633974364, 1650751580,
    1667528796, 1684306012, 1701083228, 1717860444,
    811956316,  828733532,  845510748,  862287964,
    879065180,  895842396,  912619612,  929396828,
    946174044,  962951260,  1634039900, 1650817116,
    1667594332, 1684371548, 1701148764, 1717925980,
    812021852,  828799068,  845576284,  862353500,
    879130716,  895907932,  912685148,  929462364,
    946239580,  963016796,  1634105436, 1650882652,
    1667659868, 1684437084, 1701214300, 1717991516,
};
pub fn stringLiteralChar(byte: u8) []const u8 {
    const ptr: *const [4]u8 = @ptrCast(&lit_char_dwords[byte]);
    return ptr[0..(4 -% (@clz(lit_char_dwords[byte]) >> 3))];
}
pub const StringLiteralFormat = struct {
    value: []const u8,
    const Format = @This();
    const use_dwords: bool = true;
    pub fn write(buf: [*]u8, string: []const u8) [*]u8 {
        @setRuntimeSafety(false);
        buf[0] = '"';
        var ptr: [*]u8 = buf + 1;
        for (string) |byte| {
            if (use_dwords) {
                ptr[0..4].* = @bitCast(lit_char_dwords[byte]);
                ptr += (4 -% (@clz(lit_char_dwords[byte]) >> 3));
            } else {
                ptr = writeChar(ptr, byte);
            }
        }
        ptr[0] = '"';
        return ptr + 1;
    }
    pub fn length(string: []const u8) usize {
        @setRuntimeSafety(false);
        var len: usize = 2;
        for (string) |byte| {
            if (use_dwords) {
                len +%= 4 -% (@clz(lit_char_dwords[byte]) >> 3);
            } else {
                len +%= lengthChar(byte);
            }
        }
        return len;
    }
    pub fn writeChar(ptr: [*]u8, byte: u8) [*]u8 {
        @setRuntimeSafety(false);
        if (use_dwords) {
            @as(*u32, @alignCast(@ptrCast(ptr))).* = lit_char_dwords[byte];
            return ptr + (4 -% (@clz(lit_char_dwords[byte]) >> 3));
        }
        switch (byte) {
            32...33, 35...91, 93...126 => {
                ptr[0..1].* = lit_char[byte][0..1].*;
                return ptr + 1;
            },
            9...10, 13, 34, 92 => {
                ptr[0..2].* = lit_char[byte][0..2].*;
                return ptr + 2;
            },
            0...8, 11...12, 14...31, 127...255 => {
                ptr[0..4].* = lit_char[byte][0..4].*;
                return ptr + 4;
            },
        }
    }
    pub fn lengthChar(byte: u8) usize {
        @setRuntimeSafety(false);
        if (use_dwords) {
            return 4 -% (@clz(lit_char_dwords[byte]) >> 3);
        }
        switch (byte) {
            32...33, 35...91, 93...126 => {
                return 1;
            },
            9...10, 13, 34, 92 => {
                return 2;
            },
            0...8, 11...12, 14...31, 127...255 => {
                return 4;
            },
        }
    }
    pub usingnamespace Interface(Format);
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
        var ptr: [*]u8 = strcpyEqu(strsetEqu(buf, ' ', width -| heading.len), heading);
        ptr[0] = ':';
        return strsetEqu(ptr + 1, ' ', builtin.message_indent -% (width +% 1));
    }
};
fn sigFigMaxLen(comptime T: type, comptime radix: u7) comptime_int {
    @setRuntimeSafety(false);
    var value: if (@bitSizeOf(T) < 8) u8 else @TypeOf(@abs(@as(T, 0))) = 0;
    var len: u16 = 0;
    if (radix != 10) {
        len +%= 2;
    }
    value -%= 1;
    while (value != 0) : (value /= radix) {
        len +%= 1;
    }
    return len;
}
pub fn sigFigLen(comptime U: type, abs_value: meta.BestInt(U), comptime radix: u7) usize {
    @setRuntimeSafety(false);
    if (@inComptime() and builtin.isUndefined(abs_value)) {
        return 9;
    }
    if (@bitSizeOf(U) == 1) {
        return 1;
    }
    var value: @TypeOf(abs_value) = abs_value;
    var count: usize = 0;
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
    if (radix > 10) {
        return result +% if (result < 10) @as(u8, '9' -% 9) else @as(u8, 'f' -% 15);
    } else {
        return result +% @as(u8, '9' -% 9);
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
    fn percentFormatSpec(
        comptime fmt_spec: PolynomialFormatSpec,
        comptime decimal_places: comptime_int,
    ) PercentFormatSpec {
        return .{
            .bits = fmt_spec.bits,
            .width = fmt_spec.width,
            .signedness = fmt_spec.signedness,
            .decimal_places = decimal_places,
        };
    }
};
pub fn GenericPolynomialFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    const T = packed struct {
        value: Int,
        const Format: type = @This();
        pub const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        pub const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        const min_abs_value: comptime_int = fmt_spec.range.min orelse 0;
        const max_abs_value: comptime_int = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: comptime_int = sigFigLen(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: comptime_int = sigFigLen(Abs, max_abs_value, fmt_spec.radix);
        const specification: PolynomialFormatSpec = fmt_spec;
        pub const max_len: ?comptime_int = blk: {
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
                const ret: [*]u8 = ptr + count;
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
            @setRuntimeSafety(false);
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
        pub fn formatConvert(format: Format) mem.array.StaticString(max_len.?) {
            var array: mem.array.StaticString(max_len.?) = undefined;
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
            buf[0] = '"';
            var ptr: [*]u8 = buf + 1;
            if (path.names_len != 0) {
                for (path.names[0]) |byte| {
                    ptr = StringLiteralFormat.writeChar(ptr, byte);
                }
                for (path.names[1..path.names_len]) |name| {
                    ptr[0] = '/';
                    ptr += 1;
                    for (name) |byte| {
                        ptr = StringLiteralFormat.writeChar(ptr, byte);
                    }
                }
            }
            ptr[0] = '"';
            return ptr + 1;
        }
        pub fn lengthLiteral(path: Path) usize {
            @setRuntimeSafety(fmt_is_safe);
            var len: usize = 2;
            if (path.names_len != 0) {
                for (path.names[0]) |byte| {
                    len +%= StringLiteralFormat.lengthChar(byte);
                }
                for (path.names[1..path.names_len]) |name| {
                    len +%= 1;
                    for (name) |byte| {
                        len +%= StringLiteralFormat.lengthChar(byte);
                    }
                }
            }
            return len;
        }
        pub fn formatWriteBufDisplayLiteral(format: Format, buf: [*]u8) usize {
            @setRuntimeSafety(fmt_is_safe);
            var tmp: [4096]u8 = undefined;
            var len: usize = format.formatWriteBufDisplay(&tmp);
            len -%= 1;
            return stringLiteral(tmp[0..len]).formatWriteBuf(buf);
        }
        pub fn write(buf: [*]u8, path: Path) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
        var len: usize = Bytes.MajorIntFormat.length(res.int.count);
        if (res.rem != 0) {
            len +%= 1;
            len +%= Bytes.MinorIntFormat.length((res.rem *% 1000) / 1024);
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
        pub const max_len: ?comptime_int = OldIntFormat.max_len.? +% 1 +%
            DeltaIntFormat.max_len.? +% 5 +%
            fmt_spec.no_style.len +%
            NewIntFormat.max_len.? +%
            @max(fmt_spec.dec_style.len, fmt_spec.inc_style.len);
        fn writeStyledChange(buf: [*]u8, count: usize, style_s: []const u8) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            buf[0] = '(';
            var ptr: [*]u8 = strcpyEqu(buf + 1, style_s);
            ptr = DeltaIntFormat.write(ptr, count);
            ptr = strcpyEqu(ptr, fmt_spec.no_style);
            ptr[0] = ')';
            return ptr + 1;
        }
        fn lengthStyledChange(count: usize, style_s: []const u8) usize {
            @setRuntimeSafety(fmt_is_safe);
            return 1 +% style_s.len +% DeltaIntFormat.length(count) +% fmt_spec.no_style.len +% 1;
        }
        fn writeDelta(buf: [*]u8, old_value: Old, new_value: New) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            var ptr: [*]u8 = buf;
            if (old_value == new_value) {
                ptr[0..4].* = "(+0)".*;
                ptr += 4;
            } else if (new_value > old_value) {
                ptr = writeStyledChange(buf, new_value -% old_value, fmt_spec.inc_style);
            } else {
                ptr = writeStyledChange(buf, old_value -% new_value, fmt_spec.dec_style);
            }
            ptr[0..fmt_spec.arrow_style.len].* = fmt_spec.arrow_style[0..fmt_spec.arrow_style.len].*;
            ptr += fmt_spec.arrow_style.len;
            return ptr;
        }
        fn lengthDelta(old_value: Old, new_value: New) usize {
            @setRuntimeSafety(fmt_is_safe);
            var len: usize = 0;
            if (old_value == new_value) {
                len +%= 4;
            } else if (new_value > old_value) {
                len +%= lengthStyledChange(new_value -% old_value, fmt_spec.inc_style);
            } else {
                len +%= lengthStyledChange(old_value -% new_value, fmt_spec.dec_style);
            }
            return len +% fmt_spec.arrow_style.len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub fn write(buf: [*]u8, old_value: Old, new_value: New) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            var ptr: [*]u8 = OldIntFormat.write(buf, old_value);
            ptr = writeDelta(ptr, old_value, new_value);
            return NewIntFormat.write(ptr, new_value);
        }
        pub fn length(old_value: Old, new_value: New) usize {
            return OldIntFormat.length(old_value) +%
                lengthDelta(old_value, new_value) +%
                NewIntFormat.length(new_value);
        }
    };
    return T;
}
pub const ChangedPercentFormatSpec = struct {
    old_fmt_spec: PercentFormatSpec,
    new_fmt_spec: PercentFormatSpec,
    del_fmt_spec: PercentFormatSpec,
    dec_style: []const u8 = "\x1b[91m-",
    inc_style: []const u8 = "\x1b[92m+",
    no_style: []const u8 = "\x1b[0m",
    arrow_style: []const u8 = " => ",
};
pub fn GenericChangedPercentFormat(comptime fmt_spec: ChangedPercentFormatSpec) type {
    const T = struct {
        old_numeraotr: Old,
        old_denominator: Old,
        new_numerator: New,
        new_denominator: New,
        const Format: type = @This();
        const Old = OldPercentFormat.Int;
        const New = NewPercentFormat.Int;
        const Int = if (@bitSizeOf(Old) > @bitSizeOf(New)) Old else New;
        const OldPercentFormat = GenericPercentFormat(fmt_spec.old_fmt_spec);
        const NewPercentFormat = GenericPercentFormat(fmt_spec.new_fmt_spec);
        const DeltaPercentFormat = GenericPercentFormat(fmt_spec.del_fmt_spec);
        const ChangedIntFormat = GenericChangedIntFormat(.{
            .old_fmt_spec = fmt_spec.old_fmt_spec.polynomialFormatSpec(),
            .new_fmt_spec = fmt_spec.new_fmt_spec.polynomialFormatSpec(),
            .del_fmt_spec = fmt_spec.del_fmt_spec.polynomialFormatSpec(),
            .dec_style = fmt_spec.dec_style,
            .inc_style = fmt_spec.dec_style,
            .no_style = fmt_spec.no_style,
            .arrow_style = fmt_spec.arrow_style,
        });
        pub const max_len: ?comptime_int = OldPercentFormat.max_len.? +% 1 +%
            DeltaPercentFormat.max_len.? +% 5 +%
            fmt_spec.no_style.len +%
            NewPercentFormat.max_len.? +%
            @max(fmt_spec.dec_style.len, fmt_spec.inc_style.len);
        fn writeStyledChange(buf: [*]u8, int: Int, dec: Int, style_s: []const u8) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            buf[0] = '(';
            var ptr: [*]u8 = strcpyEqu(buf + 1, style_s);
            ptr = DeltaPercentFormat.write2(ptr, int, dec);
            ptr = strcpyEqu(ptr, fmt_spec.no_style);
            ptr[0] = ')';
            return strcpyEqu(ptr + 1, fmt_spec.arrow_style);
        }
        fn lengthStyledChange(int: Int, dec: Int, style_s: []const u8) usize {
            @setRuntimeSafety(fmt_is_safe);
            return 1 +% style_s.len +% DeltaPercentFormat.length2(int, dec) +% fmt_spec.no_style.len +% 1 +% fmt_spec.arrow_style.len;
        }
        const old_factor = OldPercentFormat.factor;
        const new_factor = NewPercentFormat.factor;
        fn lengthNewIntGt(old_int: Old, old_dec: Old, new_int: New, new_dec: New) usize {
            @setRuntimeSafety(false);
            const new_dec_lt: bool = new_dec < old_dec;
            const new_dec_ne: bool = new_dec != old_dec;
            const int: Int = new_int -% (old_int +% @intFromBool(new_dec_lt));
            const dec: Int = if (new_dec_ne) ((new_dec -% old_dec) +% if (new_dec_lt) NewPercentFormat.factor else 0) else 0;
            var len: usize = OldPercentFormat.length2(old_int, old_dec);
            len +%= lengthStyledChange(int, dec, fmt_spec.inc_style);
            len +%= NewPercentFormat.length2(new_int, new_dec);
            return len;
        }
        fn lengthOldIntGt(old_int: Old, old_dec: Old, new_int: New, new_dec: New) usize {
            @setRuntimeSafety(false);
            const old_dec_lt: bool = old_dec < new_dec;
            const old_dec_ne: bool = old_dec != new_dec;
            const int: Int = old_int -% (new_int +% @intFromBool(old_dec_lt));
            const dec: Int = if (old_dec_ne) ((old_dec -% new_dec) +% if (old_dec_lt) OldPercentFormat.factor else 0) else 0;
            var len: usize = OldPercentFormat.length2(old_int, old_dec);
            len +%= lengthStyledChange(int, dec, fmt_spec.dec_style);
            len +%= NewPercentFormat.length2(new_int, new_dec);
            return len;
        }
        fn lengthIntEql(old_numerator: Old, old_int: Old, old_dec: Old, new_numerator: New, new_int: New, new_dec: New) usize {
            @setRuntimeSafety(false);
            const old_dec_gt: bool = old_dec > new_dec;
            const old_dec_lt: bool = old_dec < new_dec;
            const int: Int = 0;
            const dec: Int = if (old_dec_gt) (old_dec -% new_dec) else 0 | if (old_dec_lt) (new_dec -% old_dec) else 0;
            const style: []const u8 = if (old_dec_gt) fmt_spec.dec_style else (if (old_dec_lt) fmt_spec.inc_style else fmt_spec.no_style);
            if (dec == 0) {
                if (new_numerator != old_numerator) {
                    return ChangedIntFormat.length(old_numerator, new_numerator);
                }
            }
            var len: usize = OldPercentFormat.length2(old_int, old_dec);
            len +%= lengthStyledChange(int, dec, style);
            len +%= NewPercentFormat.length2(new_int, new_dec);
            return len;
        }
        fn writeNewIntGt(buf: [*]u8, old_int: Old, old_dec: Old, new_int: New, new_dec: New) [*]u8 {
            @setRuntimeSafety(false);
            const new_dec_lt: bool = new_dec < old_dec;
            const new_dec_ne: bool = new_dec != old_dec;
            const int: Int = new_int -% (old_int +% @intFromBool(new_dec_lt));
            const dec: Int = if (new_dec_ne) ((new_dec -% old_dec) +% if (new_dec_lt) NewPercentFormat.factor else 0) else 0;
            var ptr: [*]u8 = OldPercentFormat.write2(buf, old_int, old_dec);
            ptr = writeStyledChange(ptr, int, dec, fmt_spec.inc_style);
            ptr = NewPercentFormat.write2(ptr, new_int, new_dec);
            return ptr;
        }
        fn writeOldIntGt(buf: [*]u8, old_int: Old, old_dec: Old, new_int: New, new_dec: New) [*]u8 {
            @setRuntimeSafety(false);
            const old_dec_lt: bool = old_dec < new_dec;
            const old_dec_ne: bool = old_dec != new_dec;
            const int: Int = old_int -% (new_int +% @intFromBool(old_dec_lt));
            const dec: Int = if (old_dec_ne) ((old_dec -% new_dec) +% if (old_dec_lt) OldPercentFormat.factor else 0) else 0;
            var ptr: [*]u8 = OldPercentFormat.write2(buf, old_int, old_dec);
            ptr = writeStyledChange(ptr, int, dec, fmt_spec.dec_style);
            ptr = NewPercentFormat.write2(ptr, new_int, new_dec);
            return ptr;
        }
        fn writeIntEql(buf: [*]u8, old_numerator: Old, old_int: Old, old_dec: Old, new_numerator: New, new_int: New, new_dec: New) [*]u8 {
            @setRuntimeSafety(false);
            const old_dec_gt: bool = old_dec > new_dec;
            const old_dec_lt: bool = old_dec < new_dec;
            const int: Int = 0;
            const dec: Int = if (old_dec_gt) (old_dec -% new_dec) else 0 | if (old_dec_lt) (new_dec -% old_dec) else 0;
            const style: []const u8 = if (old_dec_gt) fmt_spec.dec_style else (if (old_dec_lt) fmt_spec.inc_style else fmt_spec.no_style);
            if (dec == 0) {
                if (new_numerator != old_numerator) {
                    return ChangedIntFormat.write(buf, old_numerator, new_numerator);
                }
            }
            var ptr: [*]u8 = OldPercentFormat.write2(buf, old_int, old_dec);
            ptr = writeStyledChange(ptr, int, dec, style);
            ptr = NewPercentFormat.write2(ptr, new_int, new_dec);
            return ptr;
        }
        pub fn write(
            buf: [*]u8,
            old_numerator: Old,
            old_denominator: Old,
            new_numerator: New,
            new_denominator: New,
        ) [*]u8 {
            @setRuntimeSafety(false);
            if (old_denominator *% new_denominator == 0) {
                return buf;
            }
            const old_res: Old = (100 *% old_factor *% old_numerator) / old_denominator;
            const old_int: Old = old_res / old_factor;
            const old_dec: Old = old_res -% (old_int *% old_factor);
            const new_res: New = (100 *% new_factor *% new_numerator) / new_denominator;
            const new_int: New = new_res / new_factor;
            const new_dec: New = new_res -% (new_int *% new_factor);
            if (new_int > old_int) {
                return writeNewIntGt(buf, old_int, old_dec, new_int, new_dec);
            } else if (old_int > new_int) {
                return writeOldIntGt(buf, old_int, old_dec, new_int, new_dec);
            } else {
                return writeIntEql(buf, old_numerator, old_int, old_dec, new_numerator, new_int, new_dec);
            }
        }
        pub fn length(
            old_numerator: Old,
            old_denominator: Old,
            new_numerator: New,
            new_denominator: New,
        ) usize {
            @setRuntimeSafety(false);
            if (old_denominator *% new_denominator == 0) {
                return 0;
            }
            const old_res: Old = (100 *% old_factor *% old_numerator) / old_denominator;
            const old_int: Old = old_res / old_factor;
            const old_dec: Old = old_res -% (old_int *% old_factor);
            const new_res: New = (100 *% new_factor *% new_numerator) / new_denominator;
            const new_int: New = new_res / new_factor;
            const new_dec: New = new_res -% (new_int *% new_factor);
            if (new_int > old_int) {
                return lengthNewIntGt(old_int, old_dec, new_int, new_dec);
            } else if (old_int > new_int) {
                return lengthOldIntGt(old_int, old_dec, new_int, new_dec);
            } else {
                return lengthIntEql(old_numerator, old_int, old_dec, new_numerator, new_int, new_dec);
            }
        }
    };
    return T;
}
pub const ChangedBytesFormatSpec = struct {
    dec_style: []const u8 = "\x1b[91m-",
    inc_style: []const u8 = "\x1b[92m+",
    no_style: []const u8 = "\x1b[0m",
    to_from_zero: bool = false,
    percent: ?comptime_int = null,
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
        pub fn length(lower: SubFormat.Int, upper: SubFormat.Int) usize {
            var l_buf: [SubFormat.max_len.?]u8 = undefined;
            var u_buf: [SubFormat.max_len.?]u8 = undefined;
            const l_end: [*]u8 = SubFormat.write(&l_buf, lower);
            const u_end: [*]u8 = SubFormat.write(&u_buf, upper);
            const l_len: usize = strlen(l_end, &l_buf);
            const u_len: usize = strlen(u_end, &u_buf);
            var len: usize = 0;
            if (fmt_spec.prefix) |prefix| {
                len +%= prefix.len;
            }
            var idx: usize = 0;
            while (idx != l_len) : (idx +%= 1) {
                if (u_buf[idx] != l_buf[idx]) {
                    break;
                }
            }
            len +%= idx +% 1 +% (u_len -% l_len) +% 2;
            len +%= l_len -% idx;
            len +%= u_len -% idx;
            return len +% 1;
        }
        pub fn write(buf: [*]u8, lower: SubFormat.Int, upper: SubFormat.Int) [*]u8 {
            var l_buf: [SubFormat.max_len.?]u8 = undefined;
            var u_buf: [SubFormat.max_len.?]u8 = undefined;
            const l_end: [*]u8 = SubFormat.write(&l_buf, lower);
            const u_end: [*]u8 = SubFormat.write(&u_buf, upper);
            const l_len: usize = strlen(l_end, &l_buf);
            const u_len: usize = strlen(u_end, &u_buf);
            var ptr: [*]u8 = buf;
            if (fmt_spec.prefix) |prefix| {
                ptr[0..prefix.len].* = prefix[0..prefix.len].*;
                ptr += prefix.len;
            }
            var idx: usize = 0;
            while (idx != l_len) : (idx +%= 1) {
                if (u_buf[idx] != l_buf[idx]) {
                    break;
                }
            }
            ptr = strcpyEqu(ptr, u_buf[0..idx]);
            ptr[0] = '{';
            ptr += 1;
            @memset(ptr[0 .. u_len -% l_len], '0');
            ptr += u_len -% l_len;
            ptr = strcpyEqu(ptr, l_buf[idx..l_len]);
            ptr[0..2].* = "..".*;
            ptr += 2;
            ptr = strcpyEqu(ptr, u_buf[idx..u_len]);
            ptr[0] = '}';
            return ptr + 1;
        }
        pub fn init(lower: SubFormat.Int, upper: SubFormat.Int) Format {
            return .{ .lower = lower, .upper = upper };
        }
        pub inline fn formatLength(format: anytype) usize {
            return Format.length(format.lower, format.upper);
        }
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(Format.write(buf, format.lower, format.upper), buf);
        }
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
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
        old_lower: OldIntFormat.Int,
        old_upper: OldIntFormat.Int,
        new_lower: NewIntFormat.Int,
        new_upper: NewIntFormat.Int,
        const Format: type = @This();
        const OldIntFormat = GenericPolynomialFormat(fmt_spec.old_fmt_spec);
        const NewIntFormat = GenericPolynomialFormat(fmt_spec.new_fmt_spec);
        const DelIntFormat = GenericPolynomialFormat(fmt_spec.del_fmt_spec);
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
        pub fn write(
            buf: [*]u8,
            old_lower: OldIntFormat.Int,
            old_upper: OldIntFormat.Int,
            new_lower: NewIntFormat.Int,
            new_upper: NewIntFormat.Int,
        ) [*]u8 {
            var ol_buf: [OldIntFormat.max_len.?]u8 = undefined;
            var ou_buf: [OldIntFormat.max_len.?]u8 = undefined;
            var nl_buf: [NewIntFormat.max_len.?]u8 = undefined;
            var nu_buf: [NewIntFormat.max_len.?]u8 = undefined;
            const ol_end: [*]u8 = OldIntFormat.write(&ol_buf, old_lower);
            const ou_end: [*]u8 = OldIntFormat.write(&ou_buf, old_upper);
            const nl_end: [*]u8 = NewIntFormat.write(&nl_buf, new_lower);
            const nu_end: [*]u8 = NewIntFormat.write(&nu_buf, new_upper);
            const ol_len: usize = strlen(ol_end, &ol_buf);
            const ou_len: usize = strlen(ou_end, &ou_buf);
            const nl_len: usize = strlen(nl_end, &nl_buf);
            const nu_len: usize = strlen(nu_end, &nu_buf);
            var idx: usize = 0;
            while (idx != ol_len) : (idx +%= 1) {
                if (ou_buf[idx] != ol_buf[idx]) {
                    break;
                }
            }
            var ptr: [*]u8 = strcpyEqu(buf, ou_buf[0..idx]);
            ptr[0] = '{';
            ptr += 1;
            @memset(ptr[0 .. ou_len -% ol_len], '0');
            ptr += ou_len -% ol_len;
            ptr = strcpyEqu(ptr, ol_buf[idx..ol_len]);
            if (old_lower != new_lower) {
                ptr = LowerChangedIntFormat.writeDelta(ptr, old_lower, new_lower);
            }
            ptr[0..2].* = "..".*;
            ptr += 2;
            ptr = strcpyEqu(ptr, ou_buf[idx..ou_len]);
            if (old_upper != new_upper) {
                ptr = UpperChangedIntFormat.writeDelta(ptr, old_upper, new_upper);
            }
            ptr[0] = '}';
            ptr[1..5].* = " => ".*;
            ptr += 5;
            idx = 0;
            while (idx != nl_len) : (idx +%= 1) {
                if (nu_buf[idx] != nl_buf[idx]) {
                    break;
                }
            }
            ptr = strcpyEqu(ptr, nu_buf[0..idx]);
            ptr[0] = '{';
            ptr += 1;
            @memset(ptr[0 .. nu_len -% nl_len], '0');
            ptr = strcpyEqu(ptr + (nu_len -% nl_len), nl_buf[idx..nl_len]);
            ptr[0..2].* = "..".*;
            ptr = strcpyEqu(ptr + 2, nu_buf[idx..nu_len]);
            ptr[0] = '}';
            return ptr + 1;
        }
        pub fn length(
            old_lower: OldIntFormat.Int,
            old_upper: OldIntFormat.Int,
            new_lower: NewIntFormat.Int,
            new_upper: NewIntFormat.Int,
        ) usize {
            var ol_buf: [OldIntFormat.max_len.?]u8 = undefined;
            var ou_buf: [OldIntFormat.max_len.?]u8 = undefined;
            var nl_buf: [NewIntFormat.max_len.?]u8 = undefined;
            var nu_buf: [NewIntFormat.max_len.?]u8 = undefined;
            const ol_end: [*]u8 = OldIntFormat.write(&ol_buf, old_lower);
            const ou_end: [*]u8 = OldIntFormat.write(&ou_buf, old_upper);
            const nl_end: [*]u8 = NewIntFormat.write(&nl_buf, new_lower);
            const nu_end: [*]u8 = NewIntFormat.write(&nu_buf, new_upper);
            const ol_len: usize = strlen(ol_end, &ol_buf);
            const ou_len: usize = strlen(ou_end, &ou_buf);
            const nl_len: usize = strlen(nl_end, &nl_buf);
            const nu_len: usize = strlen(nu_end, &nu_buf);
            var idx: usize = 0;
            while (idx != ol_len) : (idx +%= 1) {
                if (ou_buf[idx] != ol_buf[idx]) {
                    break;
                }
            }
            var len: usize = 12;
            len +%= idx +% (ou_len -% ol_len) +% ol_buf[idx..ol_len].len;
            if (old_lower != new_lower) {
                len +%= LowerChangedIntFormat.lengthDelta(old_lower, new_lower);
            }
            len +%= ou_buf[idx..ou_len].len;
            if (old_upper != new_upper) {
                len +%= UpperChangedIntFormat.lengthDelta(old_upper, new_upper);
            }
            idx = 0;
            while (idx != nl_len) : (idx +%= 1) {
                if (nu_buf[idx] != nl_buf[idx]) {
                    break;
                }
            }
            return len +% (2 *% nu_len) -% idx;
        }
        pub fn init(
            old_lower: OldIntFormat.Int,
            old_upper: OldIntFormat.Int,
            new_lower: NewIntFormat.Int,
            new_upper: NewIntFormat.Int,
        ) Format {
            return .{
                .old_lower = old_lower,
                .old_upper = old_upper,
                .new_lower = new_lower,
                .new_upper = new_upper,
            };
        }
        pub inline fn formatLength(format: anytype) usize {
            return Format.length(format.old_lower, format.old_upper, format.new_lower, format.new_upper);
        }
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(Format.write(buf, format.old_lower, format.old_upper, format.new_lower, format.new_upper), buf);
        }
        pub inline fn formatWrite(format: Format, array: anytype) void {
            return array.define(format.formatWriteBuf(@ptrCast(array.referOneUndefined())));
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
            return 5 +% dt_spec.year.length(date.year) +%
                dt_spec.month.length(@intFromEnum(date.mon)) +%
                dt_spec.month_day.length(date.mday) +%
                dt_spec.hour.length(date.hour) +%
                dt_spec.minute.length(date.min) +%
                dt_spec.second.length(date.sec);
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn writeNS(buf: [*]u8, ts: time.TimeSpec) [*]u8 {
    var ptr: [*]u8 = DateTime.write(buf, time.DateTime.init(ts.sec));
    ptr[0] = '.';
    return NSec.write(ptr + 1, ts.nsec);
}
pub fn lengthNS(date: time.DateTime, ns: u64) [*]u8 {
    return DateTime.length(date) +% 1 +% NSec.length(ns);
}
pub const LazyIdentifierFormat = struct {
    value: []const u8,
    const Format = @This();
    pub fn write(buf: [*]u8, name: []const u8) [*]u8 {
        buf[0] = '@';
        return StringLiteralFormat.write(buf + 1, name);
    }
    pub fn length(name: []const u8) usize {
        return 1 +% StringLiteralFormat.length(name);
    }
    pub usingnamespace Interface(Format);
};
pub inline fn fieldIdentifier(comptime field_name: []const u8) []const u8 {
    comptime {
        const field_init: []const u8 = fieldInitializer(field_name);
        return field_init[1 .. field_init.len -% 3];
    }
}
pub inline fn fieldTagName(comptime field_name: []const u8) []const u8 {
    comptime {
        const field_init: []const u8 = fieldInitializer(field_name);
        return field_init[0 .. field_init.len -% 3];
    }
}
pub inline fn fieldInitializer(comptime field_name: []const u8) []const u8 {
    comptime {
        var type_info = @typeInfo(union {});
        type_info.Union.fields = &.{.{ .type = void, .name = field_name, .alignment = 1 }};
        const Union = @Type(type_info);
        const type_name: []const u8 = @typeName(@TypeOf(.{ ._ = @unionInit(Union, field_name, {}) }));
        return type_name[25 +% @typeName(Union).len .. type_name.len -% 5];
    }
}
pub const FieldIdentifierFormat = struct {
    value: []const u8,
    const Format: type = @This();
    pub fn write(buf: [*]u8, comptime name: []const u8) [*]u8 {
        const field_name: []const u8 = comptime fieldIdentifier(name);
        buf[0..field_name.len].* = field_name[0..field_name.len].*;
        return buf + field_name.len;
    }
    pub fn length(comptime name: []const u8) usize {
        return comptime fieldIdentifier(name).len;
    }
    pub usingnamespace Interface(Format);
};
pub const IdentifierFormat = struct {
    value: []const u8,
    const Format: type = @This();
    pub fn write(buf: [*]u8, name: []const u8) [*]u8 {
        if (isValidId(name)) {
            return strcpyEqu(buf, name);
        }
        return LazyIdentifierFormat.write(buf, name);
    }
    pub fn length(name: []const u8) usize {
        if (isValidId(name)) {
            return name.len;
        }
        return LazyIdentifierFormat.length(name);
    }
    pub usingnamespace Interface(Format);
};
pub fn isValidId(name: []const u8) bool {
    @setRuntimeSafety(fmt_is_safe);
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
    const Format = @This();
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
    pub usingnamespace Interface(Format);
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
            return @typeName(@Type(type_info))[0 .. @typeName(@Type(type_info)).len -% @typeName(@field(type_info, @tagName(type_info)).child).len];
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
    return packed struct {
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
            ret = ret ++ lit_char[byte];
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
    render_float_places: u8 = 3,
    string_literal: ?bool = true,
    multi_line_string_literal: ?bool = false,
    omit_default_fields: bool = true,
    omit_container_decls: bool = true,
    omit_trailing_comma: ?bool = null,
    omit_type_names: bool = false,
    enum_to_int: bool = false,
    enum_out_of_range_to_int: bool = true,
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
        .Float => return FloatFormat(spec, T),
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
// These are required by the absence of comptime pointer subtract.
const neg1: usize = @as(usize, 0) -% 1;
const neg2: usize = @as(usize, 0) -% 2;
const neg4: usize = @as(usize, 0) -% 4;
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
    const array_info: builtin.Type = @typeInfo(Array);
    const child: type = array_info.Array.child;
    const child_spec: RenderSpec = blk: {
        var tmp: RenderSpec = spec;
        tmp.infer_type_names = @typeInfo(child) == .Struct;
        break :blk tmp;
    };
    const ChildFormat: type = AnyFormat(child_spec, child);
    const type_name = if (spec.infer_type_names) "." else @typeName(Array);
    const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
    const T = struct {
        value: Array,
        const Format = @This();
        const max_len: ?comptime_int = blk: {
            if (ChildFormat.max_len) |child_max_len| {
                break :blk (type_name.len +% 2) +% array_info.Array.len *% (child_max_len +% 2);
            } else {
                break :blk null;
            }
        };
        pub fn write(buf: [*]u8, value: anytype) [*]u8 {
            var ptr: [*]u8 = buf;
            ptr[0..type_name.len].* = type_name.*;
            ptr += type_name.len;
            if (value.len == 0) {
                ptr[0..2].* = "{}".*;
                ptr += 2;
            } else {
                ptr[0..2].* = "{ ".*;
                ptr += 2;
                if (builtin.requireComptime(child)) {
                    inline for (value) |element| {
                        ptr = ChildFormat.write(ptr, element);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                    }
                } else {
                    for (value) |element| {
                        ptr = ChildFormat.write(ptr, element);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                    }
                }
                if (omit_trailing_comma) {
                    (ptr + neg2)[0..2].* = " }".*;
                } else {
                    ptr[0] = '}';
                    ptr += 1;
                }
            }
            return ptr;
        }
        pub fn length(value: Array) usize {
            var len: usize = type_name.len +% 2;
            if (value.len != 0) {
                if (builtin.requireComptime(child)) {
                    inline for (value) |element| {
                        len +%= ChildFormat.length(element) +% 2;
                    }
                } else {
                    for (value) |element| {
                        len +%= ChildFormat.length(element) +% 2;
                    }
                }
                if (!omit_trailing_comma) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub const BoolFormat = packed struct {
    value: bool,
    const Format = @This();
    pub fn write(buf: [*]u8, value: bool) [*]u8 {
        if (value) buf[0..4].* = "true".* else buf[0..5].* = "false".*;
        return buf + (@as(usize, 5) -% @intFromBool(value));
    }
    pub fn length(value: bool) usize {
        return (@as(usize, 5) -% @intFromBool(value));
    }
    pub usingnamespace Interface(Format);
};
pub fn TypeFormat(comptime spec: RenderSpec) type {
    const omit_trailing_comma: bool = spec.omit_trailing_comma orelse false;
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
    const T = struct {
        value: type,
        const Format = @This();
        const max_len: ?comptime_int = null;
        inline fn evalDefaultValue(comptime field_type: type, comptime default_value: ?*const anyopaque) ?[]const u8 {
            if (default_value == null) {
                return null;
            }
            if (builtin.isUndefined(default_value)) {
                return "undefined";
            }
            return comptime eval(default_value_spec, @as(*const field_type, @ptrCast(@alignCast(default_value))).*);
        }
        pub fn write(buf: [*]u8, comptime value: type) [*]u8 {
            @setRuntimeSafety(false);
            const type_info: builtin.Type = @typeInfo(value);
            var ptr: [*]u8 = buf;
            switch (type_info) {
                .Struct => |struct_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (struct_info.fields.len == 0 and struct_info.decls.len == 0) {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " {}".*;
                        ptr += 3;
                    } else {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " { ".*;
                        ptr += 3;
                        inline for (struct_info.fields) |field| {
                            ptr += writeStructFieldBuf(ptr, field.name, field.type, evalDefaultValue(field.type, field.default_value));
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                if (@hasDecl(value, decl.name)) {
                                    ptr += writeDeclBuf(ptr, decl.name, @field(value, decl.name));
                                }
                            }
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, struct_info.fields.len +% struct_info.decls.len);
                        } else {
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, struct_info.fields.len);
                        }
                    }
                },
                .Union => |union_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (union_info.fields.len == 0 and union_info.decls.len == 0) {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " {}".*;
                        ptr += 3;
                    } else {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " { ".*;
                        ptr += 3;
                        inline for (union_info.fields) |field| {
                            ptr += writeUnionFieldBuf(ptr, field.name, field.type);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (union_info.decls) |decl| {
                                if (@hasDecl(value, decl.name)) {
                                    ptr += writeDeclBuf(ptr, decl.name, @field(value, decl.name));
                                }
                            }
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, union_info.fields.len +% union_info.decls.len);
                        } else {
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, union_info.fields.len);
                        }
                    }
                },
                .Enum => |enum_info| {
                    const decl_spec_s = meta.sliceToArrayPointer(typeDeclSpecifier(type_info)).*;
                    if (enum_info.fields.len == 0 and enum_info.decls.len == 0) {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " {}".*;
                        ptr += 3;
                    } else {
                        ptr[0..decl_spec_s.len].* = decl_spec_s;
                        ptr += decl_spec_s.len;
                        ptr[0..3].* = " { ".*;
                        ptr += 3;
                        inline for (enum_info.fields) |field| {
                            ptr += writeEnumFieldBuf(ptr, field.name);
                        }
                        if (!spec.omit_container_decls) {
                            inline for (enum_info.decls) |decl| {
                                if (@hasDecl(value, decl.name)) {
                                    ptr += writeDeclBuf(ptr, decl.name, @field(value, decl.name));
                                }
                            }
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, enum_info.fields.len +% enum_info.decls.len);
                        } else {
                            ptr += writeTrailingCommaBuf(ptr + neg2, omit_trailing_comma, enum_info.fields.len);
                        }
                    }
                },
                else => {
                    const type_name_s = @typeName(value);
                    ptr[0..type_name_s.len].* = type_name_s.*;
                    ptr += type_name_s.len;
                },
            }
            return ptr;
        }
        fn writeDeclBuf(buf: [*]u8, decl_name: []const u8, decl_value: anytype) usize {
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
            @setRuntimeSafety(fmt_is_safe);
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
        pub fn length(comptime value: type) comptime_int {
            const type_info: builtin.Type = @typeInfo(value);
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
                                len +%= IdentifierFormat.length(field.name) +% 2 +% type_format.formatLength();
                            } else {
                                len +%= IdentifierFormat.length(field.name) +% 2 +% @typeName(field.type).len;
                            }
                            if (evalDefaultValue(field.type, field.default_value)) |default_value| {
                                len +%= default_value.len +% 3;
                            }
                            len +%= 2;
                        }
                        if (!spec.omit_container_decls) {
                            inline for (struct_info.decls) |decl| {
                                if (@hasDecl(value, decl.name)) {
                                    len +%= lengthDecl(decl.name, @field(value, decl.name));
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
                            len +%= IdentifierFormat.length(field.name) +% 2;
                        } else {
                            if (spec.inline_field_types) {
                                const type_format: TypeFormat(field_type_spec) = .{ .value = field.type };
                                len +%= IdentifierFormat.length(field.name) +% 4 +% type_format.formatLength();
                            } else {
                                len +%= IdentifierFormat.length(field.name) +% 4 +% @typeName(field.type).len;
                            }
                        }
                    }
                    if (!spec.omit_container_decls) {
                        inline for (union_info.decls) |decl| {
                            if (@hasDecl(value, decl.name)) {
                                len +%= lengthDecl(decl.name, @field(value, decl.name));
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
                        len +%= comptime IdentifierFormat.length(field.name) +% 2;
                    }
                    if (!spec.omit_container_decls) {
                        inline for (enum_info.decls) |decl| {
                            if (@hasDecl(value, decl.name)) {
                                len +%= lengthDecl(decl.name, @field(value, decl.name));
                            }
                        }
                    }
                    len +%= @intFromBool(enum_info.fields.len != 0 and !omit_trailing_comma);
                },
                else => {
                    len +%= @typeName(value).len;
                },
            }
            return len;
        }
        pub usingnamespace Interface(Format);
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
fn writeTrailingCommaPtr(buf: [*]u8, omit_trailing_comma: bool, fields_len: usize) [*]u8 {
    if (fields_len == 0) {
        buf[1] = '}';
    } else {
        if (omit_trailing_comma) {
            buf[0..2].* = " }".*;
        } else {
            buf[2] = '}';
            return buf + 3;
        }
    }
    return buf + 2;
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
    @setRuntimeSafety(fmt_is_safe);
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
    const type_name = if (spec.infer_type_names) "." else @typeName(Struct);
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
                for (fields) |field| {
                    const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                    const FieldFormat = AnyFormat(field_spec, field.type);
                    len +%= fieldInitializer(field.name).len;
                    if (FieldFormat.max_len) |field_max_len| {
                        len +%= field_max_len;
                    } else {
                        break :blk null;
                    }
                }
            }
            break :blk len;
        };
        pub fn write(buf: [*]u8, value: anytype) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            buf[0..type_name.len].* = type_name.*;
            var ptr: [*]u8 = buf + type_name.len;
            if (fields.len == 0) {
                ptr[0..2].* = "{}".*;
                return ptr + 2;
            }
            var fields_len: usize = 0;
            ptr[0..2].* = "{ ".*;
            ptr += 2;
            comptime var field_idx: usize = 0;
            inline while (field_idx != fields.len) : (field_idx +%= 1) {
                const field: builtin.Type.StructField = fields[field_idx];
                if (comptime spec.ignore_padding_fields and
                    field.name.len > 1 and
                    field.name[0] == 'z' and
                    field.name[1] == 'b')
                {
                    continue;
                }
                const field_value: field.type = @field(value, field.name);
                const field_type_info: builtin.Type = @typeInfo(field.type);
                const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                if (field_type_info == .Union) {
                    if (field_type_info.Union.layout != .Auto) {
                        const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                        if (spec.views.extern_tagged_union and @hasField(Struct, tag_field_name)) {
                            const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(value, tag_field_name));
                            return AnyFormat(field_spec, @TypeOf(view)).write(buf, view);
                        }
                    }
                } else if (field_type_info == .Pointer) {
                    if (field_type_info.Pointer.size == .Many) {
                        if (spec.views.extern_slice) {
                            const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                                ptr = AnyFormat(field_spec, @TypeOf(view)).write(ptr, view);
                                ptr[0..2].* = ", ".*;
                                ptr += 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (spec.views.extern_resizeable) {
                            const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                                ptr = AnyFormat(field_spec, @TypeOf(view)).write(ptr, view);
                                ptr[0..2].* = ", ".*;
                                ptr += 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    }
                    if (field_type_info.Pointer.size == .Slice) {
                        if (spec.views.zig_resizeable) {
                            const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                                ptr = AnyFormat(field_spec, @TypeOf(view)).write(ptr, view);
                                ptr[0..2].* = ", ".*;
                                ptr += 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    }
                } else if (field_type_info == .Array) {
                    if (spec.views.static_resizeable) {
                        const len_field_name: []const u8 = field.name ++ spec.names.len_field_suffix;
                        if (@hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(value, len_field_name)];
                            ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                            ptr = AnyFormat(field_spec, @TypeOf(view)).write(ptr, view);
                            ptr[0..2].* = ", ".*;
                            ptr += 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                }
                if (spec.omit_default_fields and field.default_value != null and !field.is_comptime) {
                    if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                        ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                        ptr = AnyFormat(field_spec, field.type).write(ptr, field_value);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                        fields_len +%= 1;
                    }
                } else {
                    ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                    ptr = AnyFormat(field_spec, field.type).write(ptr, field_value);
                    ptr[0..2].* = ", ".*;
                    ptr += 2;
                    fields_len +%= 1;
                }
            }
            return writeTrailingCommaPtr(ptr + neg2, omit_trailing_comma, fields_len);
        }
        pub fn length(value: anytype) usize {
            @setRuntimeSafety(fmt_is_safe);
            var len: usize = type_name.len +% 2;
            var fields_len: usize = 0;
            comptime var field_idx: usize = 0;
            inline while (field_idx != fields.len) : (field_idx +%= 1) {
                const field: builtin.Type.StructField = fields[field_idx];
                if (comptime spec.ignore_padding_fields and
                    field.name.len > 1 and
                    field.name[0] == 'z' and
                    field.name[1] == 'b')
                {
                    continue;
                }
                const field_spec: RenderSpec = if (meta.DistalChild(field.type) == type) field_spec_if_type else field_spec_if_not_type;
                const field_value: field.type = @field(value, field.name);
                const field_type_info: builtin.Type = @typeInfo(field.type);
                if (field_type_info == .Union) {
                    if (field_type_info.Union.layout != .Auto) {
                        const tag_field_name: []const u8 = field.name ++ spec.names.tag_field_suffix;
                        if (spec.views.extern_tagged_union) {
                            if (@hasField(Struct, tag_field_name)) {
                                const view = meta.tagUnion(field.type, meta.Field(Struct, tag_field_name), field_value, @field(value, tag_field_name));
                                return AnyFormat(field_spec, @TypeOf(view)).length(view);
                            }
                        }
                    }
                } else if (field_type_info == .Pointer) {
                    if (field_type_info.Pointer.size == .Many) {
                        if (spec.views.extern_slice) {
                            const len_field_name = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                len +%= fieldInitializer(field.name).len +% render(field_spec, view).formatLength() +% 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                        if (spec.views.extern_resizeable) {
                            const len_field_name = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                len +%= fieldInitializer(field.name).len +% render(field_spec, view).formatLength() +% 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    }
                    if (field_type_info.Pointer.size == .Slice) {
                        if (spec.views.zig_resizeable) {
                            const len_field_name = field.name ++ spec.names.len_field_suffix;
                            if (@hasField(Struct, len_field_name)) {
                                const view = field_value[0..@field(value, len_field_name)];
                                len +%= fieldInitializer(field.name).len +% render(field_spec, view).formatLength() +% 2;
                                fields_len +%= 1;
                                continue;
                            }
                        }
                    }
                } else if (field_type_info == .Array) {
                    if (spec.views.static_resizeable) {
                        const len_field_name = field.name ++ spec.names.len_field_suffix;
                        if (@hasField(Struct, len_field_name)) {
                            const view = field_value[0..@field(value, len_field_name)];
                            len +%= fieldInitializer(field.name).len +% render(field_spec, view).formatLength() +% 2;
                            fields_len +%= 1;
                            continue;
                        }
                    }
                }
                if (spec.omit_default_fields and field.default_value != null and !field.is_comptime) {
                    if (builtin.requireComptime(field.type)) {
                        if (comptime !mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= fieldInitializer(field.name).len +%
                                AnyFormat(field_spec, field.type).length(field_value) +% 2;
                            fields_len +%= 1;
                        }
                    } else {
                        if (!mem.testEqual(field.type, field_value, mem.pointerOpaque(field.type, field.default_value.?).*)) {
                            len +%= fieldInitializer(field.name).len +%
                                AnyFormat(field_spec, field.type).length(field_value) +% 2;
                            fields_len +%= 1;
                        }
                    }
                } else {
                    len +%= fieldInitializer(field.name).len +%
                        AnyFormat(field_spec, field.type).length(field_value) +% 2;
                    fields_len +%= 1;
                }
            }
            return len +% @intFromBool(!omit_trailing_comma and fields_len != 0);
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn UnionFormat(comptime spec: RenderSpec, comptime Union: type) type {
    if (spec.decls.forward_formatter) {
        if (@hasDecl(Union, "formatWrite") and @hasDecl(Union, "formatLength")) {
            return FormatFormat(Union);
        }
    }
    if (@typeInfo(Union) != .Union) {
        return AnyFormat(spec, Union);
    }
    const type_name = if (spec.infer_type_names) "." else @typeInfo(Union);
    const T = struct {
        value: Union,
        const Format = @This();
        const fields: []const builtin.Type.UnionField = @typeInfo(Union).Union.fields;
        const tag_type: ?type = @typeInfo(Union).Union.tag_type;
        pub const max_len: ?comptime_int = blk: {
            var max_field_len: usize = 0;
            for (fields) |field| {
                max_field_len = @max(max_field_len, AnyFormat(spec, field.type).max_len.?);
            }
            break :blk (@typeName(Union).len +% 2) +% 1 +% meta.maxNameLength(Union) +% 3 +% max_field_len +% 2;
        };
        fn writeUntagged(buf: [*]u8, value: Union) [*]u8 {
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                return TaggedFormat.write(buf, value.tagged());
            }
            if (@sizeOf(Union) > @sizeOf(usize)) {
                buf[0..2].* = "{}".*;
                return buf + 2;
            }
            if (spec.infer_type_names) {
                buf[0..9].* = "@bitCast(".*;
                var ptr: [*]u8 = buf + 9;
                ptr = Ub(meta.LeastRealBitSize(Union)).write(ptr, meta.leastRealBitCast(value));
                ptr[0] = ')';
                return ptr + 1;
            } else {
                buf[0 .. 11 +% type_name.len].* = ("@bitCast(" ++ type_name ++ ", ").*;
                var ptr: [*]u8 = buf + 11 + type_name.len;
                ptr = Ub(meta.LeastRealBitSize(Union)).write(ptr, meta.leastRealBitCast(value));
                ptr[0] = ')';
                return ptr + 1;
            }
        }
        fn lengthUntagged(value: Union) usize {
            if (@hasDecl(Union, "tagged") and
                @hasDecl(Union, "Tagged") and
                spec.view.extern_tagged_union)
            {
                const TaggedFormat = AnyFormat(spec, Union.Tagged);
                return TaggedFormat.length(value.tagged());
            }
            if (@sizeOf(Union) > @sizeOf(usize)) {
                return type_name.len +% 2;
            }
            if (spec.infer_type_names) {
                return 10 +% Ub(meta.LeastRealBitSize(Union)).length(meta.leastRealBitCast(value));
            } else {
                return 12 +% type_name.len +% Ub(meta.LeastRealBitSize(Union)).length(meta.leastRealBitCast(value));
            }
        }
        pub fn write(buf: [*]u8, value: anytype) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            if (tag_type == null) {
                return writeUntagged(buf, value);
            }
            buf[0..type_name.len].* = type_name.*;
            var ptr: [*]u8 = buf + type_name.len;
            if (fields.len == 0) {
                ptr[0..2].* = "{}".*;
                return ptr + 2;
            }
            ptr[0..2].* = "{ ".*;
            ptr += 2;
            inline for (fields) |field| {
                if (value == @field(tag_type.?, field.name)) {
                    if (field.type == void) {
                        ptr += neg2;
                        ptr = strcpyEqu(ptr, fieldIdentifier(field.name));
                    } else {
                        ptr = strcpyEqu2(ptr, fieldInitializer(field.name));
                        ptr = AnyFormat(spec, field.type).write(ptr, @field(value, field.name));
                    }
                }
            }
            ptr[0..2].* = " }".*;
            return ptr + 2;
        }
        pub fn length(value: anytype) usize {
            if (tag_type == null) {
                return lengthUntagged(value);
            }
            var len: usize = type_name.len +% 2;
            if (fields.len == 0) {
                return len;
            }
            inline for (fields) |field| {
                if (value == @field(tag_type.?, field.name)) {
                    const field_name_format: IdentifierFormat = .{ .value = field.name };
                    if (field.type == void) {
                        len -%= 2;
                        return len +% field_name_format.formatLength();
                    } else {
                        len +%= fieldInitializer(field.name).len +%
                            AnyFormat(spec, field.type).length(@field(value, field.name)) +% 2;
                    }
                }
            }
            return len;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn EnumFormat(comptime spec: RenderSpec, comptime Enum: type) type {
    const T = struct {
        value: Enum,
        const Format = @This();
        const type_info: builtin.Type = @typeInfo(Enum);
        const ExhaustiveEnum = meta.ExhaustEnum(Enum);
        const TagTypeIntFormat = IntFormat(spec, type_info.Enum.tag_type);
        pub const max_len: ?comptime_int = blk: {
            var len: usize = 0;
            for (type_info.Enum.fields) |field| {
                len = @max(len, fieldTagName(field.name).len);
            }
            if (type_info.Enum.is_exhaustive) {
                break :blk len;
            } else if (spec.enum_out_of_range_to_int) {
                break :blk @max(len, IntFormat(spec, Enum).max_len orelse 0);
            }
        };
        pub fn write(buf: [*]u8, value: anytype) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            if (type_info.Enum.is_exhaustive) {
                return strcpyEqu(buf, switch (value) {
                    inline else => |tag| comptime fieldTagName(@tagName(tag)),
                });
            }
            for (meta.enumValues(ExhaustiveEnum)) |int_value| {
                if (@intFromEnum(value) == int_value) {
                    return EnumFormat(spec, ExhaustiveEnum).write(buf, @as(ExhaustiveEnum, @enumFromInt(@intFromEnum(value))));
                }
            }
            if (spec.enum_out_of_range_to_int) {
                return IntFormat(spec, @typeInfo(ExhaustiveEnum).Enum.tag_type).write(buf, @intFromEnum(value));
            }
            buf[0] = '_';
            return buf + 1;
        }
        pub fn length(value: anytype) usize {
            @setRuntimeSafety(fmt_is_safe);
            if (type_info.Enum.is_exhaustive) {
                return switch (value) {
                    inline else => |tag| comptime fieldTagName(@tagName(tag)).len,
                };
            }
            for (meta.enumValues(ExhaustiveEnum)) |int_value| {
                if (@intFromEnum(value) == int_value) {
                    return EnumFormat(spec, ExhaustiveEnum).length(@as(ExhaustiveEnum, @enumFromInt(@intFromEnum(value))));
                }
            }
            if (spec.enum_out_of_range_to_int) {
                return IntFormat(spec, @typeInfo(ExhaustiveEnum).Enum.tag_type).length(@intFromEnum(value));
            }
            return 1;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub const EnumLiteralFormat = struct {
    value: @Type(.EnumLiteral),
    const Format = @This();
    const max_len: ?comptime_int = null;
    pub fn write(buf: [*]u8, comptime value: Format) [*]u8 {
        return strcpyEqu(buf, fieldTagName(@tagName(value)));
    }
    pub fn length(comptime value: Format) usize {
        return fieldTagName(@tagName(value)).len;
    }
    pub usingnamespace Interface(Format);
};
pub const ComptimeIntFormat = struct {
    value: comptime_int,
    const Format = @This();
    pub fn write(buf: [*]u8, comptime value: comptime_int) [*]u8 {
        return strcpyEqu2(buf, ci(value));
    }
    pub fn length(comptime value: comptime_int) comptime_int {
        return ci(value).len;
    }
    pub usingnamespace Interface(Format);
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
pub fn FloatFormat(comptime spec: RenderSpec, comptime Float: type) type {
    comptime var dec_fmt_spec = Udsize.specification;
    dec_fmt_spec.width = .{ .fixed = spec.render_float_places };
    const T = struct {
        value: Float,
        const Format = @This();
        const Decimal = GenericPolynomialFormat(dec_fmt_spec);
        const fixed_mul: comptime_int = math.sigFigList(usize, 10).?[spec.render_float_places] +% 1;
        pub fn write(buf: [*]u8, value: Float) [*]u8 {
            const abs: Float = @abs(value);
            var ptr: [*]u8 = buf;
            ptr[0] = '-';
            const int: Float = @trunc(abs);
            ptr = Udsize.write(ptr + @intFromBool(value < 0), @intFromFloat(int));
            ptr[0] = '.';
            return Decimal.write(ptr + 1, @intFromFloat((abs * fixed_mul - int * fixed_mul)));
        }
        pub fn length(value: Float) usize {
            const abs: Float = @abs(value);
            var len: usize = @intFromBool(value < 0);
            const int: Float = @trunc(abs);
            len +%= Udsize.length(@intFromFloat(int));
            len +%= 1;
            len +%= Decimal.length(@intFromFloat(abs * fixed_mul - int * fixed_mul));
            return len;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
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
        @setRuntimeSafety(fmt_is_safe);
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
        const child: type = @typeInfo(Pointer).Pointer.child;
        const ChildFormat = AnyFormat(spec, child);
        const max_len: ?comptime_int = blk: {
            if (ChildFormat.max_len) |child_max_len| {
                break :blk (4 +% @typeName(Pointer).len +% 3) +% child_max_len +% 1;
            } else {
                break :blk null;
            }
        };
        pub fn write(buf: [*]u8, value: Pointer) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            if (@typeInfo(child) == .Array and
                @typeInfo(child).Array.child == u8)
            {
                return StringLiteralFormat.write(buf, value);
            }
            const type_name: []const u8 = @typeName(Pointer);
            const address: usize = if (@inComptime()) 8 else @intFromPtr(value);
            var ptr: [*]u8 = buf;
            if (child == anyopaque) {
                ptr[0 .. 14 +% type_name.len].* = ("@intFromPtr(" ++ type_name ++ ", ").*;
                ptr += 14 +% type_name.len;
                ptr = Uxsize.write(ptr, address);
                ptr[0] = ')';
                ptr += 1;
            } else {
                if (!spec.infer_type_names) {
                    ptr[0 .. 6 +% type_name.len].* = ("@as(" ++ type_name ++ ", ").*;
                    ptr += 6 +% type_name.len;
                }
                if (@typeInfo(child) == .Fn) {
                    ptr[0] = '@';
                    ptr = Uxsize.write(ptr + 1, address);
                } else {
                    ptr[0] = '&';
                    ptr = AnyFormat(spec, child).write(ptr + 1, value.*);
                }
                if (!spec.infer_type_names) {
                    ptr[0] = ')';
                    ptr += 1;
                }
            }
            return ptr;
        }
        pub fn length(value: Pointer) usize {
            var len: usize = 0;
            const address: usize = if (@inComptime()) 8 else @intFromPtr(value);
            const type_name: []const u8 = @typeName(Pointer);
            if (child == anyopaque) {
                len +%= 12 +% type_name.len;
                len +%= Uxsize.length(address);
                len +%= 1;
            } else {
                if (!spec.infer_type_names) {
                    len +%= 6 +% type_name.len;
                }
                if (@typeInfo(child) == .Fn) {
                    len +%= 1;
                    len +%= Uxsize.length(address);
                } else {
                    len +%= 1;
                    len +%= AnyFormat(spec, child).length(value.*);
                }
                if (!spec.infer_type_names) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn PointerSliceFormat(comptime spec: RenderSpec, comptime Pointer: type) type {
    const child: type = @typeInfo(Pointer).Pointer.child;
    const ChildFormat: type = AnyFormat(spec, child);
    const omit_trailing_comma: bool = spec.omit_trailing_comma orelse true;
    const type_name = if (spec.infer_type_names) "." else @typeName(Pointer);
    const T = struct {
        value: Pointer,
        const Format = @This();
        const max_len: ?comptime_int = null;
        pub fn writeAny(buf: [*]u8, value: anytype) [*]u8 {
            var ptr: [*]u8 = buf;
            if (value.len == 0) {
                if (spec.infer_type_names) {
                    ptr[0] = '&';
                    ptr += 1;
                }
                ptr[0..2].* = "{}".*;
                ptr += 2;
            } else {
                if (spec.infer_type_names) {
                    ptr[0] = '&';
                    ptr += 1;
                }
                ptr[0..type_name.len].* = type_name.*;
                ptr += type_name.len;
                ptr[0..2].* = "{ ".*;
                ptr += 2;
                if (builtin.requireComptime(child)) {
                    inline for (value) |element| {
                        ptr = ChildFormat.write(ptr, element);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                    }
                } else {
                    for (value) |element| {
                        ptr = ChildFormat.write(ptr, element);
                        ptr[0..2].* = ", ".*;
                        ptr += 2;
                    }
                }
                if (omit_trailing_comma) {
                    (ptr + neg2)[0..2].* = " }".*;
                } else {
                    ptr[0] = '}';
                    ptr += 1;
                }
            }
            return ptr;
        }
        pub fn lengthAny(value: anytype) usize {
            var len: usize = 0;
            if (value.len == 0) {
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
                    inline for (value) |element| {
                        len +%= ChildFormat.length(element) +% 2;
                    }
                } else {
                    for (value) |element| {
                        len +%= ChildFormat.length(element) +% 2;
                    }
                }
                if (!omit_trailing_comma) {
                    len +%= 1;
                }
            }
            return len;
        }
        pub fn lengthMultiLineStringLiteral(format: anytype) usize {
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
        pub fn writeMultiLineStringLiteral(buf: [*]u8, value: anytype) [*]u8 {
            buf[0..3].* = "\n\\\\".*;
            var ptr: [*]u8 = buf + 3;
            for (value) |byte| {
                switch (byte) {
                    '\n' => {
                        ptr[0..3].* = "\n\\\\".*;
                        ptr += 3;
                    },
                    '\t' => {
                        ptr[0..2].* = "\\t".*;
                        ptr += 2;
                    },
                    else => {
                        ptr[0] = byte;
                        ptr += 1;
                    },
                }
            }
            ptr[0] = '\n';
            return ptr + 1;
        }
        fn isMultiLine(values: []const u8) bool {
            for (values) |value| {
                if (value == '\n') return true;
            }
            return false;
        }
        pub inline fn write(buf: [*]u8, value: anytype) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(value)) {
                            return writeMultiLineStringLiteral(buf, value);
                        } else {
                            return StringLiteralFormat.write(buf, value);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return StringLiteralFormat.write(buf, value);
                    }
                }
            }
            return writeAny(buf, value);
        }
        pub inline fn length(value: anytype) usize {
            if (child == u8) {
                if (spec.multi_line_string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        if (isMultiLine(value)) {
                            return lengthMultiLineStringLiteral(value);
                        } else {
                            return StringLiteralFormat.length(value);
                        }
                    }
                }
                if (spec.string_literal) |render_string_literal| {
                    if (render_string_literal) {
                        return StringLiteralFormat.length(value);
                    }
                }
            }
            return lengthAny(value);
        }
        pub usingnamespace Interface(Format);
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
        pub fn write(buf: [*]u8, value: Pointer) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            var ptr: [*]u8 = buf;
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                var idx: usize = 0;
                while (!mem.testEqual(child, value[idx], sentinel)) idx +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                return PointerSliceFormat(spec, Slice).write(ptr, value[0..idx :sentinel]);
            } else {
                ptr[0..7].* = "{ ... }".*;
                return ptr + 7;
            }
        }
        pub fn length(value: Pointer) usize {
            @setRuntimeSafety(fmt_is_safe);
            if (type_info.Pointer.sentinel) |sentinel_ptr| {
                const sentinel: child = comptime mem.pointerOpaque(child, sentinel_ptr).*;
                var idx: usize = 0;
                while (!mem.testEqual(child, value[idx], sentinel)) idx +%= 1;
                const Slice: type = meta.ManyToSlice(Pointer);
                return PointerSliceFormat(spec, Slice).length(value[0..idx :sentinel]);
            } else {
                return 7;
            }
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn OptionalFormat(comptime spec: RenderSpec, comptime Optional: type) type {
    const T = struct {
        value: Optional,
        const Format = @This();
        const ChildFormat: type = AnyFormat(spec, child);
        const child: type = @typeInfo(Optional).Optional.child;
        const type_name = @typeName(Optional);
        const max_len: ?comptime_int = (4 +% type_name.len +% 2) +% @max(1 +% ChildFormat.max_len, 5);
        const render_readable: bool = true;
        pub fn write(buf: [*]u8, value: Optional) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            var ptr: [*]u8 = buf;
            if (!render_readable) {
                ptr[0..4].* = "@as(".*;
                ptr += 4;
                ptr[0..type_name.len].* = type_name.*;
                ptr += type_name.len;
                ptr[0..2].* = ", ".*;
                ptr += 2;
            }
            if (value) |optional| {
                ptr = ChildFormat.write(ptr, optional);
            } else {
                ptr[0..4].* = "null".*;
                ptr += 4;
            }
            if (!render_readable) {
                ptr[0] = ')';
                ptr += 1;
            }
            return ptr;
        }
        pub fn length(value: Optional) usize {
            var len: usize = 0;
            if (!render_readable) {
                len +%= 4 +% type_name.len +% 2;
            }
            if (value) |optional| {
                len +%= ChildFormat.length(optional);
            } else {
                len +%= 4;
            }
            if (!render_readable) {
                len +%= 1;
            }
            return len;
        }
        pub usingnamespace Interface(Format);
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
        const ErrorFormat = AnyFormat(spec, type_info.ErrorUnion.error_set);
        const PayloadFormat = AnyFormat(spec, type_info.ErrorUnion.payload);
        pub const max_len: ?comptime_int = 4096;

        pub fn write(buf: [*]u8, value: ErrorUnion) [*]u8 {
            if (value) |payload| {
                return PayloadFormat.write(buf, payload);
            } else |err| {
                return ErrorFormat.write(buf, err);
            }
        }
        pub fn length(value: ErrorUnion) usize {
            if (value) |payload| {
                return PayloadFormat.length(payload);
            } else |err| {
                return ErrorFormat.write(err);
            }
        }
        pub usingnamespace Interface(Format);
    };
    return T;
}
pub fn ErrorSetFormat(comptime ErrorSet: type) type {
    const T = struct {
        value: ErrorSet,
        const Format = @This();
        pub const max_len: ?comptime_int = blk: {
            var len: usize = 0;
            if (@typeInfo(ErrorSet).ErrorSet) |error_set| {
                for (error_set) |err| {
                    len = @max(len, fieldTagName(err.name).len);
                }
            }
            break :blk 5 + len;
        };
        pub fn write(buf: [*]u8, value: anytype) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            return strcpyEqu(buf, switch (value) {
                inline else => |tag| "error" ++ comptime fieldTagName(@errorName(tag)),
            });
        }
        pub fn length(value: anytype) usize {
            @setRuntimeSafety(fmt_is_safe);
            return switch (value) {
                inline else => |tag| 5 + comptime fieldTagName(@tagName(tag)).len,
            };
        }
        pub usingnamespace Interface(Format);
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
        pub fn write(buf: [*]u8, value: Struct) [*]u8 {
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                return ValuesFormat.write(buf, value.readAll());
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                return ValuesFormat.write(buf, value.readAll());
            }
        }
        pub fn length(value: Struct) usize {
            if (meta.GenericReturn(Struct.readAll)) |Values| {
                const ValuesFormat = PointerSliceFormat(values_spec, Values);
                return ValuesFormat.length(value.readAll());
            } else {
                const ValuesFormat = PointerSliceFormat(values_spec, []const u8);
                return ValuesFormat.length(value.readAll());
            }
        }
    };
    return T;
}
pub fn FormatFormat(comptime Struct: type) type {
    const T = struct {
        value: Struct,
        const Format = @This();
        pub inline fn write(buf: [*]u8, value: Struct) [*]u8 {
            return buf + value.formatWriteBuf(buf);
        }
        pub inline fn formatLength(value: Struct) usize {
            return value.formatLength();
        }
        pub usingnamespace Interface(Format);
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
    const decl_s = spec.tokens.decl[0..spec.tokens.decl.len].*;
    const lbrace_s = spec.tokens.lbrace[0..spec.tokens.lbrace.len].*;
    const equal_s = spec.tokens.equal[0..spec.tokens.equal.len].*;
    const rbrace_s = spec.tokens.rbrace[0..spec.tokens.rbrace.len].*;
    const next_s = spec.tokens.next[0..spec.tokens.next.len].*;
    const end_s = spec.tokens.end[0..spec.tokens.end.len].*;
    const colon_s = spec.tokens.colon[0..spec.tokens.colon.len].*;
    const indent_s = spec.tokens.indent[0..spec.tokens.indent.len].*;
    const U = union(enum) {
        type_decl: Declaration,
        type_ref: Reference,
        const Format = @This();
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
            fn write(buf: [*]u8, format: Container, depth: usize) [*]u8 {
                @setRuntimeSafety(fmt_is_safe);
                if (spec.option_5) {
                    if (matchDeclaration(format)) |decl| {
                        return Format.writeInternal(buf, decl, depth);
                    }
                }
                var ptr: [*]u8 = strcpyEqu(buf, format.spec);
                ptr[0..lbrace_s.len].* = lbrace_s;
                ptr = writeIndent(ptr + lbrace_s.len, depth +% 1);
                for (format.fields) |field| {
                    ptr = Field.write(ptr, field, depth +% 1);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        if (field.name != null and
                            field.defn != null)
                        {
                            ptr = Declaration.write(ptr, field, depth +% 1);
                        }
                    }
                }
                ptr -= indent_s.len;
                ptr[0..rbrace_s.len].* = rbrace_s;
                return ptr + rbrace_s.len;
            }
            fn length(format: Container, depth: usize) usize {
                if (spec.option_5) {
                    if (matchDeclaration(format)) |decl| {
                        return Declaration.length(decl, depth);
                    }
                }
                var len: usize = lbrace_s.len +% format.spec.len +% (depth +% 1) *% indent_s.len;
                for (format.fields) |field| {
                    len +%= Field.length(field, depth +% 1);
                }
                if (spec.decls) {
                    for (format.decls) |field| {
                        if (field.name != null and
                            field.defn != null)
                        {
                            len +%= Declaration.length(field, depth +% 1);
                        }
                    }
                }
                return len +% (rbrace_s.len -% indent_s.len);
            }
        };
        pub const Declaration = struct {
            name: ?spec.token = null,
            defn: ?Container = null,
            fn write(buf: [*]u8, type_decl: Declaration, depth: usize) [*]u8 {
                @setRuntimeSafety(fmt_is_safe);
                var ptr: [*]u8 = buf;
                if (spec.depth != 0 and spec.depth != depth) {
                    ptr = writeIndent(ptr, depth);
                }
                if (type_decl.name) |type_name| {
                    if (type_decl.defn) |type_defn| {
                        ptr[0..decl_s.len].* = decl_s;
                        if (spec.identifier_name) {
                            ptr = IdentifierFormat.write(ptr + decl_s.len, type_name);
                        } else {
                            ptr = strcpyEqu(ptr + decl_s.len, type_name);
                        }
                        ptr[0..equal_s.len].* = equal_s;
                        ptr = Container.write(ptr + equal_s.len, type_defn, depth);
                        ptr[0..end_s.len].* = end_s;
                        ptr = writeIndent(ptr + end_s.len, depth);
                    } else {
                        ptr = strcpyEqu(ptr, type_name);
                    }
                } else {
                    if (type_decl.defn) |type_defn| {
                        ptr = Container.write(ptr, type_defn, depth);
                    }
                }
                return ptr;
            }
            fn length(type_decl: Declaration, depth: usize) usize {
                var len: usize = 0;
                if (spec.depth != 0 and spec.depth != depth) {
                    len +%= depth *% indent_s.len;
                }
                if (type_decl.name) |type_name| {
                    if (type_decl.defn) |type_defn| {
                        len +%= decl_s.len;
                        if (spec.identifier_name) {
                            len +%= IdentifierFormat.length(type_name);
                        } else {
                            len +%= type_name.len;
                        }
                        len +%= equal_s.len +% end_s.len +% Container.length(type_defn, depth) +% (depth *% indent_s.len);
                    } else {
                        len +%= type_name.len;
                    }
                } else {
                    if (type_decl.defn) |type_defn| {
                        len +%= Container.length(type_defn, depth);
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
            fn write(buf: [*]u8, format: Field, depth: usize) [*]u8 {
                @setRuntimeSafety(fmt_is_safe);
                var ptr: [*]u8 = buf;
                if (spec.identifier_name) {
                    ptr = IdentifierFormat.write(ptr, format.name);
                } else {
                    ptr = strcpyEqu(ptr, format.name);
                }
                if (format.type) |field_type| {
                    ptr[0..colon_s.len].* = colon_s;
                    ptr = Format.writeInternal(ptr + colon_s.len, field_type, depth);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            ptr[0..equal_s.len].* = equal_s;
                            ptr = strcpyEqu(ptr + equal_s.len, default_value);
                        }
                    },
                    .enumeration => {
                        ptr[0..equal_s.len].* = equal_s;
                        ptr = Idsize.write(ptr + equal_s.len, format.value.enumeration);
                    },
                }
                ptr[0..next_s.len].* = next_s;
                return writeIndent(ptr + next_s.len, depth);
            }
            fn length(format: Field, depth: usize) usize {
                var len: usize = 0;
                if (spec.identifier_name) {
                    len +%= IdentifierFormat.length(format.name);
                } else {
                    len +%= format.name.len;
                }
                if (format.type) |field_type| {
                    len +%= colon_s.len +% Format.lengthInternal(field_type, depth);
                }
                switch (format.value) {
                    .default => |mb_default_value| {
                        if (mb_default_value) |default_value| {
                            len +%= equal_s.len +% default_value.len;
                        }
                    },
                    .enumeration => {
                        len +%= equal_s.len +% Idsize.length(format.value.enumeration);
                    },
                }
                return len +% (depth *% indent_s.len) +% next_s.len;
            }
        };
        fn writeInternal(buf: [*]u8, type_descr: Format, depth: usize) [*]u8 {
            @setRuntimeSafety(fmt_is_safe);
            switch (type_descr) {
                .type_ref => |type_ref| {
                    return writeInternal(strcpyEqu(buf, type_ref.spec), type_ref.type.*, depth);
                },
                .type_decl => |type_decl| {
                    return Declaration.write(buf, type_decl, depth);
                },
            }
        }
        fn lengthInternal(type_descr: Format, depth: usize) usize {
            switch (type_descr) {
                .type_ref => |type_ref| {
                    return type_ref.spec.len +% lengthInternal(type_ref.type.*, depth);
                },
                .type_decl => |type_decl| {
                    return Declaration.length(type_decl, depth);
                },
            }
        }
        pub fn write(buf: [*]u8, type_descr: Format) [*]u8 {
            return writeInternal(buf, type_descr, spec.depth);
        }
        pub const formatLength = length;
        pub fn length(type_descr: Format) usize {
            return lengthInternal(type_descr, spec.depth);
        }
        pub inline fn formatWrite(type_descr: Format, array: anytype) void {
            return array.define(type_descr.formatWriteBuf(@ptrCast(array.referOneUndefined())));
        }
        pub inline fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            return strlen(Format.write(buf, format), buf);
        }
        fn writeIndent(buf: [*]u8, depth: usize) [*]u8 {
            @memset(@as([*][indent_s.len]u8, @ptrCast(buf))[0..depth], indent_s);
            return buf + (indent_s.len *% depth);
        }
        pub fn cast(type_descr: anytype, comptime cast_spec: TypeDescrFormatSpec) GenericFormat(cast_spec) {
            debug.assert(
                cast_spec.default_field_values ==
                    spec.default_field_values,
            );
            return @as(*const GenericFormat(cast_spec), @ptrCast(type_descr)).*;
        }
        inline fn fieldDefaultValue(comptime field_type: type, comptime default_value_opt: ?*const anyopaque) ?spec.token {
            if (default_value_opt) |default_value_ptr| {
                switch (spec.default_field_values) {
                    .omit => return null,
                    .fast => return cx(default_value_ptr),
                    .exact => |render_spec| {
                        comptime return eval(render_spec, mem.pointerOpaque(field_type, default_value_ptr).*);
                    },
                    .exact_safe => |render_spec| {
                        const fast: []const u8 = cx(default_value_ptr);
                        if (fast[0] != '.') {
                            return fast;
                        }
                        comptime return eval(render_spec, mem.pointerOpaque(field_type, default_value_ptr).*);
                    },
                }
            } else {
                return null;
            }
        }
        inline fn defaultDeclareCriteria(comptime T: type, comptime decl: builtin.Type.Declaration) ?type {
            if (@hasDecl(T, decl.name)) {
                const u = @field(T, decl.name);
                const U = @TypeOf(u);
                if (U == type and meta.isContainer(u) and u != T) {
                    return u;
                }
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
                                    .value = .{ .default = fieldDefaultValue(field.type, field.default_value) },
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
                                    .value = .{ .default = fieldDefaultValue(field.type, field.default_value) },
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
                                    .value = .{ .default = fieldDefaultValue(field.type, field.default_value) },
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
                                    .value = .{ .default = fieldDefaultValue(field.type, field.default_value) },
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
pub const DateTime = GenericDateTimeFormat(.{});
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
