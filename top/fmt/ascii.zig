const mem = @import("../mem.zig");
const math = @import("../math.zig");
const debug = @import("../debug.zig");
const builtin = @import("../builtin.zig");
pub const control_code = struct {
    pub const start_of_heading: u8 = 0x01;
    pub const start_of_text: u8 = 0x02;
    pub const end_of_text: u8 = 0x03;
    pub const end_of_transmission: u8 = 0x04;
    pub const enquiry: u8 = 0x05;
    pub const acknowledge: u8 = 0x06;
    pub const bell: u8 = 0x07;
    pub const backspace: u8 = 0x08;
    pub const horizontal_tab: u8 = 0x09;
    pub const line_feed: u8 = 0x0A;
    pub const vertical_tab: u8 = 0x0B;
    pub const form_feed: u8 = 0x0C;
    pub const carriage_return: u8 = 0x0D;
    pub const shift_out: u8 = 0x0E;
    pub const shift_in: u8 = 0x0F;
    pub const data_link_escape: u8 = 0x10;
    pub const device_control_1: u8 = 0x11;
    pub const device_control_2: u8 = 0x12;
    pub const device_control_3: u8 = 0x13;
    pub const device_control_4: u8 = 0x14;
    pub const negative_acknowledge: u8 = 0x15;
    pub const synchronous_idle: u8 = 0x16;
    pub const end_of_transmission_block: u8 = 0x17;
    pub const cancel: u8 = 0x18;
    pub const end_of_medium: u8 = 0x19;
    pub const substitute: u8 = 0x1A;
    pub const escape: u8 = 0x1B;
    pub const file_separator: u8 = 0x1C;
    pub const group_separator: u8 = 0x1D;
    pub const record_separator: u8 = 0x1E;
    pub const unit_separator: u8 = 0x1F;
    pub const delete: u8 = 0x7F;
};
pub fn isAlphanumeric(c: u8) bool {
    switch (c) {
        '0'...'9', 'A'...'Z', 'a'...'z' => {
            return true;
        },
        else => return false,
    }
}
pub fn isAlphabetic(c: u8) bool {
    switch (c) {
        'A'...'Z', 'a'...'z' => {
            return true;
        },
        else => return false,
    }
}
pub fn isControl(c: u8) bool {
    return c <= control_code.unit_separator or c == control_code.delete;
}
pub fn isDigit(c: u8) bool {
    switch (c) {
        '0'...'9' => {
            return true;
        },
        else => return false,
    }
}
pub fn isLower(c: u8) bool {
    return switch (c) {
        'a'...'z' => true,
        else => false,
    };
}
pub fn isPrint(c: u8) bool {
    return isASCII(c) and !isControl(c);
}
pub export fn isWhitespace(c: u8) bool {
    inline for (whitespace) |other| {
        if (c == other) {
            return true;
        }
    }
    return false;
}
pub const whitespace: [6]u8 = .{
    ' ',
    control_code.horizontal_tab,
    control_code.line_feed,
    control_code.carriage_return,
    control_code.vertical_tab,
    control_code.form_feed,
};
pub fn isUpper(c: u8) bool {
    switch (c) {
        'A'...'Z' => {
            return true;
        },
        else => return false,
    }
}
pub fn isHex(c: u8) bool {
    switch (c) {
        '0'...'9', 'A'...'F', 'a'...'f' => {
            return true;
        },
        else => return false,
    }
}
pub fn isASCII(c: u8) bool {
    return c < 128;
}
pub fn toUpper(c: u8) u8 {
    if (isLower(c)) {
        return c & 0b11011111;
    } else {
        return c;
    }
}
pub fn toLower(c: u8) u8 {
    if (isUpper(c)) {
        return c | 0b00100000;
    } else {
        return c;
    }
}
fn transformChars(dest: []u8, src: []const u8, transform: *const fn (u8) u8) []u8 {
    debug.assertAboveOrEqual(u64, dest.len, src.len);
    for (src, 0..) |value, idx| {
        dest[idx] = transform(value);
    }
    return dest[0..src.len];
}
pub fn testEqualStringFront(prefix_values: []const u8, values: []const u8, transform: *const fn (u8) u8) bool {
    if (prefix_values.len == 0 or prefix_values.len > values.len) {
        return false;
    }
    return testEqualString(prefix_values, values[0..prefix_values.len], transform);
}
pub fn testEqualStringBack(suffix_values: []const u8, values: []const u8, transform: *const fn (u8) u8) bool {
    if (suffix_values.len == 0 or suffix_values.len > values.len) {
        return false;
    }
    return testEqualString(suffix_values, values[values.len -% suffix_values.len ..], transform);
}
pub fn testEqualString(l_values: []const u8, r_values: []const u8, transform: *const fn (u8) u8) bool {
    if (l_values.len != r_values.len) {
        return false;
    }
    if (l_values.ptr == r_values.ptr) {
        return true;
    }
    var idx: u64 = 0;
    while (idx != l_values.len) {
        if (transform(l_values[idx]) != transform(r_values[idx])) {
            return false;
        }
        idx +%= 1;
    }
    return true;
}
pub fn indexOfFirstEqualChar(value: u8, values: []const u8, transform: *const fn (u8) u8) ?u64 {
    var idx: u64 = 0;
    while (idx != values.len) {
        if (transform(values[idx]) != transform(value)) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn indexOfFirstEqualString(sub_values: []const u8, values: []const u8, transform: *const fn (u8) u8) ?u64 {
    if (sub_values.len > values.len) {
        return null;
    }
    const max_idx: u64 = (values.len -% sub_values.len) +% 1;
    var idx: u64 = 0;
    while (idx != max_idx) {
        if (testEqualStringFront(sub_values, values[idx..], transform)) {
            return idx;
        }
        idx +%= 1;
    }
    return null;
}
pub fn lowerString(dest: []u8, src: []const u8) []u8 {
    return transformChars(dest, src, toLower);
}
pub fn upperString(dest: []u8, src: []const u8) []u8 {
    return transformChars(dest, src, toUpper);
}
pub fn testEqualStringIgnoreCase(l_values: []const u8, r_values: []const u8) bool {
    return testEqualString(l_values, r_values, toLower);
}
pub fn indexOfFirstEqualCharIgnoreCase(value: u8, values: []const u8) ?u64 {
    return indexOfFirstEqualChar(value, values, toLower);
}
pub fn indexOfFirstEqualStringIgnoreCase(sub_values: []const u8, values: []const u8) ?u64 {
    return indexOfFirstEqualString(sub_values, values, toLower);
}
pub fn testEqualFrontIgnoreCase(prefix_values: []const u8, values: []const u8) bool {
    if (prefix_values.len == 0 or prefix_values.len > values.len) {
        return false;
    }
    return testEqualString(prefix_values, values[0..prefix_values.len], toLower);
}
pub fn testEqualBackIgnoreCase(suffix_values: []const u8, values: []const u8) bool {
    if (suffix_values.len == 0 or suffix_values.len > values.len) {
        return false;
    }
    return testEqualString(suffix_values, values[values.len -% suffix_values.len ..], toLower);
}
pub fn orderIgnoreCase(lhs: []const u8, rhs: []const u8) math.Order {
    const max_len: u64 = @min(lhs.len, rhs.len);
    var idx: usize = 0;
    while (idx < max_len) : (idx += 1) {
        switch (math.order(toLower(lhs[idx]), toLower(rhs[idx]))) {
            .eq => continue,
            .lt => return .lt,
            .gt => return .gt,
        }
    }
    return math.order(lhs.len, rhs.len);
}
pub fn lessThanIgnoreCase(lhs: []const u8, rhs: []const u8) bool {
    return orderIgnoreCase(lhs, rhs) == .lt;
}
