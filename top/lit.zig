//! Constants. More useful as a reference than as an import.
// If the programmer can remember to use these, the LHS name may be more helpful
// to the reader than the RHS expression.
pub const max_val_u8: u8 = 0xff;
pub const max_val_u16: u16 = 0xffff;
pub const max_val_u32: u32 = 0xffffffff;
pub const max_val_u64: u64 = 0xffffffffffffffff;
pub const max_bit_u8: u8 = 0x80;
pub const max_bit_u16: u16 = 0x8000;
pub const max_bit_u32: u32 = 0x80000000;
pub const max_bit_u64: u64 = 0x8000000000000000;
pub const max_val_i8: i8 = 0x7f;
pub const max_val_i16: i16 = 0x7fff;
pub const max_val_i32: i32 = 0x7fffffff;
pub const max_val_i64: i64 = 0x7fffffffffffffff;
pub const max_bit_i8: i8 = 0x40;
pub const max_bit_i16: i16 = 0x4000;
pub const max_bit_i32: i32 = 0x40000000;
pub const max_bit_i64: i64 = 0x4000000000000000;
// So that basic formatters do not need to compute a safe buffer length.
pub const u8d_max_len: u64 = 3;
pub const u8x_max_len: u64 = 5;
pub const u64d_max_len: u64 = 19;
pub const u64x_max_len: u64 = 18;
pub const i8d_max_len: u64 = 4;
pub const i8x_max_len: u64 = 6;
pub const i64d_max_len: u64 = 20;
pub const i64x_max_len: u64 = 19;
/// Unconfirmed theory that using these is faster to compile when naming tuple
/// fields.
pub const ud8 = [256][]const u8{
    "0",   "1",   "2",   "3",   "4",   "5",   "6",   "7",   "8",   "9",
    "10",  "11",  "12",  "13",  "14",  "15",  "16",  "17",  "18",  "19",
    "20",  "21",  "22",  "23",  "24",  "25",  "26",  "27",  "28",  "29",
    "30",  "31",  "32",  "33",  "34",  "35",  "36",  "37",  "38",  "39",
    "40",  "41",  "42",  "43",  "44",  "45",  "46",  "47",  "48",  "49",
    "50",  "51",  "52",  "53",  "54",  "55",  "56",  "57",  "58",  "59",
    "60",  "61",  "62",  "63",  "64",  "65",  "66",  "67",  "68",  "69",
    "70",  "71",  "72",  "73",  "74",  "75",  "76",  "77",  "78",  "79",
    "80",  "81",  "82",  "83",  "84",  "85",  "86",  "87",  "88",  "89",
    "90",  "91",  "92",  "93",  "94",  "95",  "96",  "97",  "98",  "99",
    "100", "101", "102", "103", "104", "105", "106", "107", "108", "109",
    "110", "111", "112", "113", "114", "115", "116", "117", "118", "119",
    "120", "121", "122", "123", "124", "125", "126", "127", "128", "129",
    "130", "131", "132", "133", "134", "135", "136", "137", "138", "139",
    "140", "141", "142", "143", "144", "145", "146", "147", "148", "149",
    "150", "151", "152", "153", "154", "155", "156", "157", "158", "159",
    "160", "161", "162", "163", "164", "165", "166", "167", "168", "169",
    "170", "171", "172", "173", "174", "175", "176", "177", "178", "179",
    "180", "181", "182", "183", "184", "185", "186", "187", "188", "189",
    "190", "191", "192", "193", "194", "195", "196", "197", "198", "199",
    "200", "201", "202", "203", "204", "205", "206", "207", "208", "209",
    "210", "211", "212", "213", "214", "215", "216", "217", "218", "219",
    "220", "221", "222", "223", "224", "225", "226", "227", "228", "229",
    "230", "231", "232", "233", "234", "235", "236", "237", "238", "239",
    "240", "241", "242", "243", "244", "245", "246", "247", "248", "249",
    "250", "251", "252", "253", "254", "255",
};
pub const esc_hex_sequences = [256][]const u8{
    "\\x00", "\\x01", "\\x02", "\\x03", "\\x04", "\\x05", "\\x06", "\\x07", "\\x08",
    "\\x09", "\\x0a", "\\x0b", "\\x0c", "\\x0d", "\\x0e", "\\x0f", "\\x10", "\\x11",
    "\\x12", "\\x13", "\\x14", "\\x15", "\\x16", "\\x17", "\\x18", "\\x19", "\\x1a",
    "\\x1b", "\\x1c", "\\x1d", "\\x1e", "\\x1f", "\\x20", "\\x21", "\\x22", "\\x23",
    "\\x24", "\\x25", "\\x26", "\\x27", "\\x28", "\\x29", "\\x2a", "\\x2b", "\\x2c",
    "\\x2d", "\\x2e", "\\x2f", "\\x30", "\\x31", "\\x32", "\\x33", "\\x34", "\\x35",
    "\\x36", "\\x37", "\\x38", "\\x39", "\\x3a", "\\x3b", "\\x3c", "\\x3d", "\\x3e",
    "\\x3f", "\\x40", "\\x41", "\\x42", "\\x43", "\\x44", "\\x45", "\\x46", "\\x47",
    "\\x48", "\\x49", "\\x4a", "\\x4b", "\\x4c", "\\x4d", "\\x4e", "\\x4f", "\\x50",
    "\\x51", "\\x52", "\\x53", "\\x54", "\\x55", "\\x56", "\\x57", "\\x58", "\\x59",
    "\\x5a", "\\x5b", "\\x5c", "\\x5d", "\\x5e", "\\x5f", "\\x60", "\\x61", "\\x62",
    "\\x63", "\\x64", "\\x65", "\\x66", "\\x67", "\\x68", "\\x69", "\\x6a", "\\x6b",
    "\\x6c", "\\x6d", "\\x6e", "\\x6f", "\\x70", "\\x71", "\\x72", "\\x73", "\\x74",
    "\\x75", "\\x76", "\\x77", "\\x78", "\\x79", "\\x7a", "\\x7b", "\\x7c", "\\x7d",
    "\\x7e", "\\x7f", "\\x80", "\\x81", "\\x82", "\\x83", "\\x84", "\\x85", "\\x86",
    "\\x87", "\\x88", "\\x89", "\\x8a", "\\x8b", "\\x8c", "\\x8d", "\\x8e", "\\x8f",
    "\\x90", "\\x91", "\\x92", "\\x93", "\\x94", "\\x95", "\\x96", "\\x97", "\\x98",
    "\\x99", "\\x9a", "\\x9b", "\\x9c", "\\x9d", "\\x9e", "\\x9f", "\\xa0", "\\xa1",
    "\\xa2", "\\xa3", "\\xa4", "\\xa5", "\\xa6", "\\xa7", "\\xa8", "\\xa9", "\\xaa",
    "\\xab", "\\xac", "\\xad", "\\xae", "\\xaf", "\\xb0", "\\xb1", "\\xb2", "\\xb3",
    "\\xb4", "\\xb5", "\\xb6", "\\xb7", "\\xb8", "\\xb9", "\\xba", "\\xbb", "\\xbc",
    "\\xbd", "\\xbe", "\\xbf", "\\xc0", "\\xc1", "\\xc2", "\\xc3", "\\xc4", "\\xc5",
    "\\xc6", "\\xc7", "\\xc8", "\\xc9", "\\xca", "\\xcb", "\\xcc", "\\xcd", "\\xce",
    "\\xcf", "\\xd0", "\\xd1", "\\xd2", "\\xd3", "\\xd4", "\\xd5", "\\xd6", "\\xd7",
    "\\xd8", "\\xd9", "\\xda", "\\xdb", "\\xdc", "\\xdd", "\\xde", "\\xdf", "\\xe0",
    "\\xe1", "\\xe2", "\\xe3", "\\xe4", "\\xe5", "\\xe6", "\\xe7", "\\xe8", "\\xe9",
    "\\xea", "\\xeb", "\\xec", "\\xed", "\\xee", "\\xef", "\\xf0", "\\xf1", "\\xf2",
    "\\xf3", "\\xf4", "\\xf5", "\\xf6", "\\xf7", "\\xf8", "\\xf9", "\\xfa", "\\xfb",
    "\\xfc", "\\xfd", "\\xfe", "\\xff",
};
pub const lit_hex_sequences: [256][]const u8 = .{
    "\\x00", "\\x01", "\\x02", "\\x03", "\\x04", "\\x05", "\\x06", "\\x07", "\\x08",
    "\\x09", "\\x0a", "\\x0b", "\\x0c", "\\x0d", "\\x0e", "\\x0f", "\\x10", "\\x11",
    "\\x12", "\\x13", "\\x14", "\\x15", "\\x16", "\\x17", "\\x18", "\\x19", "\\x1a",
    "\\x1b", "\\x1c", "\\x1d", "\\x1e", "\\x1f", " ",     "!",     "\"",    "#",
    "$",     "%",     "&",     "'",     "(",     ")",     "*",     "+",     ",",
    "-",     ".",     "/",     "0",     "1",     "2",     "3",     "4",     "5",
    "6",     "7",     "8",     "9",     ":",     ";",     "<",     "=",     ">",
    "?",     "@",     "A",     "B",     "C",     "D",     "E",     "F",     "G",
    "H",     "I",     "J",     "K",     "L",     "M",     "N",     "O",     "P",
    "Q",     "R",     "S",     "T",     "U",     "V",     "W",     "X",     "Y",
    "Z",     "[",     "\\",    "]",     "^",     "_",     "`",     "a",     "b",
    "c",     "d",     "e",     "f",     "g",     "h",     "i",     "j",     "k",
    "l",     "m",     "n",     "o",     "p",     "q",     "r",     "s",     "t",
    "u",     "v",     "w",     "x",     "y",     "z",     "{",     "|",     "}",
    "~",     "\\x7f", "\\x80", "\\x81", "\\x82", "\\x83", "\\x84", "\\x85", "\\x86",
    "\\x87", "\\x88", "\\x89", "\\x8a", "\\x8b", "\\x8c", "\\x8d", "\\x8e", "\\x8f",
    "\\x90", "\\x91", "\\x92", "\\x93", "\\x94", "\\x95", "\\x96", "\\x97", "\\x98",
    "\\x99", "\\x9a", "\\x9b", "\\x9c", "\\x9d", "\\x9e", "\\x9f", "\\xa0", "\\xa1",
    "\\xa2", "\\xa3", "\\xa4", "\\xa5", "\\xa6", "\\xa7", "\\xa8", "\\xa9", "\\xaa",
    "\\xab", "\\xac", "\\xad", "\\xae", "\\xaf", "\\xb0", "\\xb1", "\\xb2", "\\xb3",
    "\\xb4", "\\xb5", "\\xb6", "\\xb7", "\\xb8", "\\xb9", "\\xba", "\\xbb", "\\xbc",
    "\\xbd", "\\xbe", "\\xbf", "\\xc0", "\\xc1", "\\xc2", "\\xc3", "\\xc4", "\\xc5",
    "\\xc6", "\\xc7", "\\xc8", "\\xc9", "\\xca", "\\xcb", "\\xcc", "\\xcd", "\\xce",
    "\\xcf", "\\xd0", "\\xd1", "\\xd2", "\\xd3", "\\xd4", "\\xd5", "\\xd6", "\\xd7",
    "\\xd8", "\\xd9", "\\xda", "\\xdb", "\\xdc", "\\xdd", "\\xde", "\\xdf", "\\xe0",
    "\\xe1", "\\xe2", "\\xe3", "\\xe4", "\\xe5", "\\xe6", "\\xe7", "\\xe8", "\\xe9",
    "\\xea", "\\xeb", "\\xec", "\\xed", "\\xee", "\\xef", "\\xf0", "\\xf1", "\\xf2",
    "\\xf3", "\\xf4", "\\xf5", "\\xf6", "\\xf7", "\\xf8", "\\xf9", "\\xfa", "\\xfb",
    "\\xfc", "\\xfd", "\\xfe", "\\xff",
};
const Range = extern struct { lower: u8, upper: u8 };
pub const character_ranges = opaque {
    pub const print: Range = .{ .lower = 0x20, .upper = 0x7e };
    pub const lower: Range = .{ .lower = 0x61, .upper = 0x7a };
    pub const upper: Range = .{ .lower = 0x41, .upper = 0x5a };
    pub const digit: Range = .{ .lower = 0x30, .upper = 0x39 };
};
pub const character_classes = opaque {
    pub const alpha: [2]Range = .{ character_ranges.upper, character_ranges.lower };
    pub const alnum: [3]Range = .{ character_ranges.upper, character_ranges.lower, character_ranges.digit };
    pub const punct: [4]Range = .{
        .{ .lower = 33, .upper = 47 },
        .{ .lower = 58, .upper = 64 },
        .{ .lower = 91, .upper = 96 },
        .{ .lower = 123, .upper = 126 },
    };
};
pub const int_prefixes: [51][]const u8 = [_][]const u8{
    "", "", "0b", "", "", "", "", "", "0o", "", "", "", "0d", "", "", "", "0x",
    "", "", "",   "", "", "", "", "", "",   "", "", "", "",   "", "", "", "",
    "", "", "0z", "", "", "", "", "", "",   "", "", "", "",   "", "", "", "",
};
pub const fx = opaque {
    pub const none: []const u8 = "\x1b\x5b\x30\x6d";
    pub const color = opaque {
        pub const fg = opaque {
            pub const black: []const u8 = "\x1b\x5b\x33\x30\x6d";
            pub const red: []const u8 = "\x1b\x5b\x33\x31\x6d";
            pub const green: []const u8 = "\x1b\x5b\x33\x32\x6d";
            pub const yellow: []const u8 = "\x1b\x5b\x33\x33\x6d";
            pub const blue: []const u8 = "\x1b\x5b\x33\x34\x6d";
            pub const magenta: []const u8 = "\x1b\x5b\x33\x35\x6d";
            pub const cyan: []const u8 = "\x1b\x5b\x33\x36\x6d";
            pub const white: []const u8 = "\x1b\x5b\x33\x37\x6d";
            pub const hi_red: []const u8 = "\x1b\x5b\x39\x31\x6d";
            pub const hi_green: []const u8 = "\x1b\x5b\x39\x32\x6d";
            pub const hi_yellow: []const u8 = "\x1b\x5b\x39\x33\x6d";
            pub const hi_blue: []const u8 = "\x1b\x5b\x39\x34\x6d";
            pub const hi_magenta: []const u8 = "\x1b\x5b\x39\x35\x6d";
            pub const hi_cyan: []const u8 = "\x1b\x5b\x39\x36\x6d";
            pub const max_red: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x31\x39\x36\x6d";
            pub const max_blue: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x32\x37\x6d";
            pub const dark_green: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x32\x32\x6d";
            pub const max_green_alt: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x37\x36\x6d";
            pub const orange: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x32\x30\x32\x6d";
            pub const purple: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x39\x39\x6d";
            pub const aqua: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x31\x35\x33\x6d";
            pub const max_white: []const u8 = "\x1b\x5b\x33\x38\x3b\x35\x3b\x32\x33\x31\x6d";
            pub fn shade(comptime index: u8) []const u8 {
                return mcode(.{ 38, 5, 255 - @min(23, index) });
            }
        };
        pub const bg = opaque {
            pub const black: []const u8 = "\x1b\x5b\x34\x30\x6d";
            pub const red: []const u8 = "\x1b\x5b\x34\x31\x6d";
            pub const green: []const u8 = "\x1b\x5b\x34\x32\x6d";
            pub const yellow: []const u8 = "\x1b\x5b\x34\x33\x6d";
            pub const blue: []const u8 = "\x1b\x5b\x34\x34\x6d";
            pub const magenta: []const u8 = "\x1b\x5b\x34\x35\x6d";
            pub const cyan: []const u8 = "\x1b\x5b\x34\x36\x6d";
            pub const white: []const u8 = "\x1b\x5b\x34\x37\x6d";
            pub const hi_red: []const u8 = "\x1b\x5b\x31\x30\x31\x6d";
            pub const hi_green: []const u8 = "\x1b\x5b\x31\x30\x32\x6d";
            pub const hi_yellow: []const u8 = "\x1b\x5b\x31\x30\x33\x6d";
            pub const hi_blue: []const u8 = "\x1b\x5b\x31\x30\x34\x6d";
            pub const hi_magenta: []const u8 = "\x1b\x5b\x31\x30\x35\x6d";
            pub const hi_cyan: []const u8 = "\x1b\x5b\x31\x30\x36\x6d";
            pub const hi_white: []const u8 = "\x1b\x5b\x31\x30\x37\x6d";
        };
    };
    pub const style = opaque {
        pub const bold: []const u8 = "\x1b\x5b\x31\x6d";
        pub const faint: []const u8 = "\x1b\x5b\x32\x6d";
        pub const italic: []const u8 = "\x1b\x5b\x33\x6d";
        pub const underline: []const u8 = "\x1b\x5b\x34\x6d";
        pub const inverted: []const u8 = "\x1b\x5b\x37\x6d";
        pub const invisible: []const u8 = "\x1b\x5b\x38\x6d";
        pub const strikeout: []const u8 = "\x1b\x5b\x39\x6d";
    };
    fn mcode(comptime args: anytype) []const u8 {
        comptime var code: []const u8 = "\x1b[";
        inline for (args) |arg| {
            code = code ++ ud8[arg] ++ ";";
        }
        return code[0 .. code.len - 1] ++ "m";
    }
};
pub const whitespace = [_]u8{ ' ', '\t', '\n', '\r', 0x0b, 0x0a };
pub const ctrl = opaque {
    pub const start_of_heading: u8 = 0x1;
    pub const start_of_text: u8 = 0x2;
    pub const end_of_text: u8 = 0x03;
    pub const end_of_transmission: u8 = 0x04;
    pub const end_of_query: u8 = 0x05;
    pub const acknowledge: u8 = 0x06;
    pub const bell: u8 = 0x07;
    pub const backspace: u8 = 0x8;
    pub const horizontal_tab: u8 = 0x09;
    pub const line_feed: u8 = 0x0a;
    pub const vertical_tab: u8 = 0x0b;
    pub const form_feed: u8 = 0x0c;
    pub const carriage_return: u8 = 0x0d;
    pub const shift_out: u8 = 0x0e;
    pub const shift_in: u8 = 0x0f;
    pub const data_link_escape: u8 = 0x10;
    pub const device_ctrl_1: u8 = 0x11;
    pub const device_ctrl_2: u8 = 0x12;
    pub const device_ctrl_3: u8 = 0x13;
    pub const device_ctrl_4: u8 = 0x14;
    pub const negative_acknowledgement: u8 = 0x15;
    pub const synchronize: u8 = 0x16;
    pub const end_of_transmission_block: u8 = 0x17;
    pub const cancel: u8 = 0x18;
    pub const end_of_medium: u8 = 0x19;
    pub const substitute: u8 = 0x1c;
    pub const escape: u8 = 0x1b;
    pub const file_separator: u8 = 0x1c;
    pub const group_separator: u8 = 0x1d;
    pub const record_separator: u8 = 0x1e;
    pub const unit_separator: u8 = 0x1f;
    pub const white_space: u8 = 0x20;
};
pub const position = opaque {
    pub const ask: [4]u8 = .{ 0x1b, 0x5b, 0x36, 0x6e };
    pub const save: [3]u8 = .{ 0x1b, 0x5b, 0x73 };
    pub const restore: [3]u8 = .{ 0x1b, 0x5b, 0x75 };
    pub const up: [3]u8 = .{ 0x1b, 0x5b, 0x41 };
    pub const down: [3]u8 = .{ 0x1b, 0x5b, 0x42 };
    pub const right: [3]u8 = .{ 0x1b, 0x5b, 0x43 };
    pub const left: [3]u8 = .{ 0x1b, 0x5b, 0x44 };
};
pub const kill = opaque {
    pub const screen_bare: [3]u8 = .{ 0x1b, 0x5b, 0x4a };
    pub const screen_down: [4]u8 = .{ 0x1b, 0x5b, 0x30, 0x4a };
    pub const screen_up: [4]u8 = .{ 0x1b, 0x5b, 0x31, 0x4a };
    pub const screen: [4]u8 = .{ 0x1b, 0x5b, 0x32, 0x4a };
    pub const line_bare: [3]u8 = .{ 0x1b, 0x5b, 0x4b };
    pub const line_right: [4]u8 = .{ 0x1b, 0x5b, 0x30, 0x4b };
    pub const line_left: [4]u8 = .{ 0x1b, 0x5b, 0x31, 0x4b };
    pub const line: [4]u8 = .{ 0x1b, 0x5b, 0x32, 0x4b };
    pub const back: [1]u8 = .{0x8};
};
const key = opaque {
    pub const home: [3]u8 = .{ 0x1b, 0x5b, 0x48 };
    pub const end: [3]u8 = .{ 0x1b, 0x5b, 0x46 };
    pub const insert: [4]u8 = .{ 0x1b, 0x5b, 0x32, 0x7e };
    pub const delete: [4]u8 = .{ 0x1b, 0x5b, 0x33, 0x7e };
    pub const page_up: [4]u8 = .{ 0x1b, 0x5b, 0x35, 0x7e };
    pub const page_down: [4]u8 = .{ 0x1b, 0x5b, 0x36, 0x7e };
    pub const f1: [3]u8 = .{ 0x1b, 0x4f, 0x50 };
    pub const f2: [3]u8 = .{ 0x1b, 0x4f, 0x51 };
    pub const f3: [3]u8 = .{ 0x1b, 0x4f, 0x52 };
    pub const f4: [3]u8 = .{ 0x1b, 0x4f, 0x53 };
    pub const f5: [5]u8 = .{ 0x1b, 0x5b, 0x31, 0x35, 0x7e };
    pub const f6: [5]u8 = .{ 0x1b, 0x5b, 0x31, 0x37, 0x7e };
    pub const f7: [5]u8 = .{ 0x1b, 0x5b, 0x31, 0x38, 0x7e };
    pub const f8: [5]u8 = .{ 0x1b, 0x5b, 0x31, 0x39, 0x7e };
    pub const f9: [5]u8 = .{ 0x1b, 0x5b, 0x32, 0x30, 0x7e };
    pub const f10: [5]u8 = .{ 0x1b, 0x5b, 0x32, 0x31, 0x7e };
    pub const f11: [5]u8 = .{ 0x1b, 0x5b, 0x32, 0x33, 0x7e };
    pub const f12: [5]u8 = .{ 0x1b, 0x5b, 0x32, 0x34, 0x7e };
};
