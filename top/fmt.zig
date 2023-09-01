const tab = @import("./tab.zig");
const mem = @import("./mem.zig");
const math = @import("./math.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const spec = @import("./spec.zig");
const debug = @import("./debug.zig");
const parse = @import("./parse.zig");
const builtin = @import("./builtin.zig");
const _render = @import("./render.zig");
pub const utf8 = @import("./fmt/utf8.zig");
pub const ascii = @import("./fmt/ascii.zig");
pub usingnamespace _render;

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
    var lhs: [:0]const u8 = s;
    lhs = builtin.message_prefix ++ lhs;
    lhs = lhs ++ builtin.message_suffix;
    const len: u64 = lhs.len;
    if (builtin.message_style) |style| {
        lhs = style ++ lhs ++ builtin.message_no_style;
    }
    if (len >= builtin.message_indent) {
        @compileError(s ++ " is too long");
    }
    return lhs ++ " " ** (builtin.message_indent - len);
}
pub const about_blank_s: AboutSrc = about("");
pub const AboutDest = @TypeOf(@constCast(about_blank_s));
pub const about_exit_s: AboutSrc = about("exit");
pub const about_err_len: comptime_int = about_blank_s.len + debug.about.error_s.len;
pub fn ci(comptime value: comptime_int) []const u8 {
    if (value < 0) {
        const s: []const u8 = @typeName([-value]void);
        return "-" ++ s[1 .. s.len -% 5];
    } else {
        const s: []const u8 = @typeName([value]void);
        return s[1 .. s.len -% 5];
    }
}
pub fn cx(comptime value: anytype) []const u8 {
    const S: type = @TypeOf(value);
    const T = [:value]S;
    const s_type_name: []const u8 = @typeName(S);
    const t_type_name: []const u8 = @typeName(T);
    return t_type_name[2 .. t_type_name.len -% (s_type_name.len +% 1)];
}

pub fn strcpy(dest: [*]u8, src: []const u8) usize {
    @setRuntimeSafety(false);
    for (src, 0..) |byte, idx| dest[idx] = byte;
    return src.len;
}
pub fn strset(dest: [*]u8, byte: u8, len: usize) usize {
    @setRuntimeSafety(false);
    for (dest[0..len]) |*ptr| ptr.* = byte;
    return len;
}
pub fn strcpyEqu(dest: [*]u8, src: []const u8) [*]u8 {
    @setRuntimeSafety(false);
    for (src, 0..) |byte, idx| dest[idx] = byte;
    return dest + src.len;
}
pub fn strsetEqu(dest: [*]u8, byte: u8, len: usize) [*]u8 {
    @setRuntimeSafety(false);
    for (dest[0..len]) |*ptr| ptr.* = byte;
    return dest + len;
}
pub fn strlen(dest: [*]u8, src: [*]u8) usize {
    return @intFromPtr(dest) -% @intFromPtr(src);
}
pub fn stringLiteralChar(byte: u8) []const u8 {
    switch (byte) {
        inline else => |value| {
            const res = @typeName([:&[1]u8{value}][]const u8);
            return res[3 .. res.len -% 12];
        },
    }
}
fn maxSigFig(comptime T: type, comptime radix: u7) comptime_int {
    @setRuntimeSafety(false);
    const U = @Type(.{ .Int = .{ .bits = @bitSizeOf(T), .signedness = .unsigned } });
    var value: if (@bitSizeOf(U) < 8) u8 else U = 0;
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
pub fn length(
    comptime U: type,
    abs_value: if (@bitSizeOf(U) < 8) u8 else U,
    comptime radix: u7,
) usize {
    @setRuntimeSafety(false);
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
    const result: u8 = @as(u8, @intCast(@rem(value, radix)));
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

fn GenericFormat(comptime Format: type) type {
    const T = struct {
        const StaticString = mem.StaticString(Format.max_len);
        pub fn formatConvert(format: Format) StaticString {
            var array: StaticString = .{};
            array.writeFormat(format);
            return array;
        }
    };
    return T;
}
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
pub const PolynomialFormatSpec = struct {
    bits: u16,
    signedness: builtin.Signedness,
    radix: comptime_int,
    width: Width,
    range: Range = .{},
    prefix: ?*const [2]u8 = null,
    separator: ?Separator = null,
};
pub fn GenericPolynomialFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    const T = packed struct {
        value: Int,
        const Format: type = @This();
        pub const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        pub const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        const min_abs_value: Abs = fmt_spec.range.min orelse 0;
        const max_abs_value: Abs = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: u16 = length(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: u16 = length(Abs, max_abs_value, fmt_spec.radix);
        pub const spec: PolynomialFormatSpec = fmt_spec;
        pub const StaticString = mem.StaticString(max_len);
        const max_len: comptime_int = blk: {
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
            break :blk len;
        };
        inline fn absolute(format: Format) Abs {
            if (format.value < 0) {
                return 1 +% ~@as(Abs, @bitCast(format.value));
            } else {
                return @as(Abs, @bitCast(format.value));
            }
        }
        inline fn digits(format: Format) u64 {
            if (fmt_spec.radix > max_abs_value) {
                return 1;
            }
            const digits_len: u64 = switch (fmt_spec.width) {
                .min => length(Abs, format.absolute(), fmt_spec.radix),
                .max => max_digits_count,
                .fixed => |fixed| fixed,
            };
            if (fmt_spec.separator) |s| {
                return digits_len +% (digits_len -% 1) / s.digits;
            } else {
                return digits_len;
            }
        }
        pub fn formatConvert(format: Format) StaticString {
            var array: StaticString = undefined;
            array.undefineAll();
            array.writeFormat(format);
            return array;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            array.define(@call(.always_inline, formatWriteBuf, .{
                format,
                @as([*]u8, @ptrCast(array.referOneUndefined())),
            }));
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            @setRuntimeSafety(false);
            var len: u64 = 0;
            if (Abs != Int) {
                buf[0] = '-';
            }
            len +%= @intFromBool(format.value < 0);
            if (fmt_spec.prefix) |prefix| {
                @as(*[prefix.len]u8, @ptrCast(buf + len)).* = prefix.*;
                len +%= prefix.len;
            }
            if (fmt_spec.radix > max_abs_value) {
                buf[len] = '0' +% @as(u8, @intFromBool(format.value != 0));
                len +%= 1;
            } else if (fmt_spec.separator) |separator| {
                const count: u64 = format.digits();
                var value: Abs = format.absolute();
                len +%= count;
                var pos: u64 = 0;
                var sep: u64 = 0;
                while (sep +% pos != count) : (value /= fmt_spec.radix) {
                    pos +%= 1;
                    buf[len - (sep +% pos)] = separator.character;
                    const b0: bool = pos / separator.digits != 0;
                    const b1: bool = pos % separator.digits == 1;
                    sep +%= @intFromBool(b0) & @intFromBool(b1);
                    buf[len -% (sep +% pos)] =
                        toSymbol(Abs, value, fmt_spec.radix);
                }
            } else {
                const count: u64 = format.digits();
                var value: Abs = format.absolute();
                len +%= count;
                var pos: u64 = 0;
                while (pos != count) : (value /= fmt_spec.radix) {
                    pos +%= 1;
                    buf[len -% pos] =
                        toSymbol(Abs, value, fmt_spec.radix);
                }
            }
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (fmt_spec.prefix) |prefix| {
                len +%= prefix.len;
            }
            if (format.value < 0) {
                len +%= 1;
            }
            return len +% format.digits();
        }
    };
    return T;
}
pub fn uo(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            debug.assert(value > 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub const SourceLocationFormat = struct {
    value: builtin.SourceLocation,
    return_address: u32,
    const Format: type = @This();
    const LineColFormat = GenericPolynomialFormat(.{
        .bits = 32,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const AddrFormat = GenericPolynomialFormat(.{
        .bits = 32,
        .signedness = .unsigned,
        .radix = 16,
        .width = .min,
        .prefix = "0x",
    });
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: u64 = 4;
        @as(*[4]u8, @ptrCast(buf)).* = "\x1b[1m".*;
        @memcpy(buf + len, file_name);
        len +%= len;
        buf[len] = ':';
        len +%= 1;
        len +%= line_fmt.formatWriteBuf(buf + len);
        buf[len] = ':';
        len +%= 1;
        len +%= column_fmt.formatWriteBuf(buf + len);
        @as(*[7]u8, @ptrCast(buf + len)).* = ":\x1b[0;2m".*;
        len +%= 7;
        len +%= ret_addr_fmt.formatWriteBuf(buf + len);
        @as(*[4]u8, @ptrCast(buf + len)).* = " in ".*;
        len +%= 4;
        @memcpy(buf + len, fn_name);
        len +%= fn_name.len;
        @as(*[5]u8, @ptrCast(buf + len)).* = "\x1b[0m\n".*;
        return len +% 4;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        array.writeMany(tab.fx.style.bold);
        array.writeMany(file_name);
        array.writeOne(':');
        array.writeFormat(line_fmt);
        array.writeOne(':');
        array.writeFormat(column_fmt);
        array.writeMany(": " ++ tab.fx.none ++ tab.fx.style.faint);
        array.writeFormat(ret_addr_fmt);
        array.writeMany(" in ");
        array.writeMany(fn_name);
        array.writeMany(tab.fx.none ++ "\n");
    }
    fn functionName(format: SourceLocationFormat) []const u8 {
        var start: u64 = 0;
        var idx: u64 = 0;
        while (idx != format.value.fn_name.len) : (idx +%= 1) {
            if (format.value.fn_name[idx] == '.') start = idx;
        }
        return format.value.fn_name[start +% @intFromBool(start != 0) .. :0];
    }
    pub fn formatLength(format: SourceLocationFormat) u64 {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: u64 = 0;
        len +%= tab.fx.style.bold.len;
        len +%= file_name.len;
        len +%= 1;
        len +%= line_fmt.formatLength();
        len +%= 1;
        len +%= column_fmt.formatLength();
        len +%= 2;
        len +%= tab.fx.none.len +% tab.fx.style.faint.len;
        len +%= ret_addr_fmt.formatLength();
        len +%= 4;
        len +%= fn_name.len;
        len +%= tab.fx.none.len;
        len +%= 1;
        return len;
    }
    pub fn init(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
        return .{ .value = value, .return_address = @as(u32, @intCast(ret_addr orelse @returnAddress())) };
    }
};
pub const Bytes = struct {
    value: Value,
    const Format: type = @This();
    const Value = struct {
        integer: mem.Bytes,
        remainder: mem.Bytes,
    };
    const Unit = mem.Bytes.Unit;
    const MajorIntFormat = GenericPolynomialFormat(.{
        .bits = 16,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const MinorIntFormat = GenericPolynomialFormat(.{
        .bits = 16,
        .signedness = .unsigned,
        .radix = 10,
        .width = .{ .fixed = 3 },
    });
    const fields: []const builtin.Type.EnumField = @typeInfo(Unit).Enum.fields;
    pub const max_len: u64 =
        MajorIntFormat.max_len +%
        MinorIntFormat.max_len +% 3; // Unit
    const default: mem.Bytes = .{
        .count = 0,
        .unit = .B,
    };
    fn formatRemainder(format: Format) MinorIntFormat {
        return .{ .value = @as(u10, @intCast((format.value.remainder.count * 1000) / 1024)) };
    }
    fn formatInteger(format: Format) MajorIntFormat {
        return .{ .value = @as(u10, @intCast(format.value.integer.count)) };
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.value.remainder.count != 0) {
            array.writeFormat(format.formatInteger());
            array.writeOne('.');
            array.writeFormat(format.formatRemainder());
            array.writeMany(@tagName(format.value.integer.unit));
        } else {
            array.writeFormat(format.formatInteger());
            array.writeMany(@tagName(format.value.integer.unit));
        }
    }
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        var len: u64 = format.formatInteger().formatWriteBuf(buf);
        if (format.value.remainder.count != 0) {
            buf[len] = '.';
            len +%= 1;
            len +%= format.formatRemainder().formatWriteBuf(buf + len);
        }
        @memcpy(buf + len, @tagName(format.value.integer.unit));
        return len +% @tagName(format.value.integer.unit).len;
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.value.remainder.count != 0) {
            len +%= format.formatInteger().formatLength();
            len +%= 1;
            len +%= format.formatRemainder().formatLength();
            len +%= @tagName(format.value.integer.unit).len;
        } else {
            len +%= format.formatInteger().formatLength();
            len +%= @tagName(format.value.integer.unit).len;
        }
        return len;
    }
    pub fn init(value: u64) Bytes {
        inline for (fields, 0..) |field, i| {
            const integer: mem.Bytes = mem.Bytes.Unit.to(value, @field(mem.Bytes.Unit, field.name));
            if (integer.count != 0) {
                const remainder: mem.Bytes = Unit.to(
                    value -| mem.Bytes.bytes(integer),
                    @field(Unit, fields[if (i != fields.len -% 1) i +% 1 else i].name),
                );
                return .{ .value = .{
                    .integer = integer,
                    .remainder = remainder,
                } };
            }
        }
        return .{ .value = .{
            .integer = default,
            .remainder = default,
        } };
    }
    pub usingnamespace GenericFormat(Format);
};
pub const ChangedIntFormatSpec = struct {
    old_fmt_spec: PolynomialFormatSpec,
    new_fmt_spec: PolynomialFormatSpec,
    del_fmt_spec: PolynomialFormatSpec,
    dec_style: []const u8 = tab.fx.color.fg.red ++ "-",
    inc_style: []const u8 = tab.fx.color.fg.green ++ "+",
    no_style: []const u8 = tab.fx.none,
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
        pub const max_len: comptime_int = OldIntFormat.max_len +% 1 +%
            DeltaIntFormat.max_len +% 5 +%
            fmt_spec.no_style.len +%
            NewIntFormat.max_len +%
            @max(fmt_spec.dec_style.len, fmt_spec.inc_style.len);
        fn formatWriteDelta(format: Format, array: anytype) void {
            if (format.old_value == format.new_value) {
                array.writeMany("(+0)");
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                array.writeOne('(');
                array.writeMany(fmt_spec.inc_style);
                array.writeFormat(del_fmt);
                array.writeMany(fmt_spec.no_style);
                array.writeOne(')');
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                array.writeOne('(');
                array.writeMany(fmt_spec.dec_style);
                array.writeFormat(del_fmt);
                array.writeMany(fmt_spec.no_style);
                array.writeOne(')');
            }
        }
        fn formatWriteDeltaBuf(format: Format, buf: [*]u8) u64 {
            var len: u64 = 0;
            if (format.old_value == format.new_value) {
                @as(*[4]u8, @ptrCast(buf)).* = "(+0)".*;
                len +%= 4;
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                buf[len] = '(';
                len +%= 1;
                @memcpy(buf + len, fmt_spec.inc_style);
                len +%= fmt_spec.inc_style.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                @memcpy(buf + len, fmt_spec.no_style);
                len +%= fmt_spec.no_style.len;
                buf[len] = ')';
                len +%= 1;
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                buf[len] = '(';
                len +%= 1;
                @memcpy(buf + len, fmt_spec.dec_style);
                len +%= fmt_spec.dec_style.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                @memcpy(buf + len, fmt_spec.no_style);
                len +%= fmt_spec.no_style.len;
                buf[len] = ')';
                len +%= 1;
            }
            return len;
        }
        fn formatLengthDelta(format: Format) u64 {
            var len: u64 = 0;
            if (format.old_value == format.new_value) {
                len +%= 4;
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                len +%= 1;
                len +%= fmt_spec.inc_style.len;
                len +%= del_fmt.formatLength();
                len +%= fmt_spec.no_style.len;
                len +%= 1;
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                len +%= 1;
                len +%= fmt_spec.dec_style.len;
                len +%= del_fmt.formatLength();
                len +%= fmt_spec.no_style.len;
                len +%= 1;
            }
            return len;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            const old_fmt: OldIntFormat = .{ .value = format.old_value };
            const new_fmt: NewIntFormat = .{ .value = format.new_value };
            array.writeFormat(old_fmt);
            format.formatWriteDelta(array);
            array.writeMany(fmt_spec.arrow_style);
            array.writeFormat(new_fmt);
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            const old_fmt: OldIntFormat = .{ .value = format.old_value };
            const new_fmt: NewIntFormat = .{ .value = format.new_value };
            var len: u64 = old_fmt.formatWriteBuf(buf);
            len +%= format.formatWriteDeltaBuf(buf + len);
            @memcpy(buf + len, fmt_spec.arrow_style);
            len +%= fmt_spec.arrow_style.len;
            len +%= new_fmt.formatWriteBuf(buf);
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            const old_fmt: OldIntFormat = .{ .value = format.old_value };
            const new_fmt: NewIntFormat = .{ .value = format.new_value };
            var len: u64 = 0;
            len +%= old_fmt.formatLength();
            len +%= formatLengthDelta(format);
            len +%= 4;
            len +%= new_fmt.formatLength();
            return len;
        }
        pub usingnamespace GenericFormat(Format);
    };
    return T;
}
pub const ChangedBytesFormatSpec = struct {
    dec_style: []const u8 = tab.fx.color.fg.red ++ "-",
    inc_style: []const u8 = tab.fx.color.fg.green ++ "+",
    no_style: []const u8 = tab.fx.none,
};
pub fn GenericChangedBytesFormat(comptime fmt_spec: ChangedBytesFormatSpec) type {
    const T = struct {
        old_value: usize,
        new_value: usize,
        const Format: type = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            const old_fmt: Bytes = bytes(format.old_value);
            const new_fmt: Bytes = bytes(format.new_value);
            old_fmt.formatWrite(array);
            if (format.old_value != format.new_value) {
                if (format.old_value > format.new_value) {
                    const del_fmt: Bytes = bytes(format.old_value -% format.new_value);
                    array.writeOne('(');
                    array.writeMany(fmt_spec.dec_style);
                    array.writeFormat(del_fmt);
                    array.writeMany(fmt_spec.no_style);
                    array.writeOne(')');
                } else {
                    const del_fmt: Bytes = bytes(format.new_value -% format.old_value);
                    array.writeOne('(');
                    array.writeMany(fmt_spec.inc_style);
                    array.writeFormat(del_fmt);
                    array.writeMany(fmt_spec.no_style);
                    array.writeOne(')');
                }
                array.writeMany(" => ");
                new_fmt.formatWrite(array);
            }
        }
        // TODO: Merge this with the body for ChangedIntFormat.
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            @setRuntimeSafety(builtin.is_safe);
            const old_fmt: Bytes = bytes(format.old_value);
            const new_fmt: Bytes = bytes(format.new_value);
            var len: u64 = old_fmt.formatWriteBuf(buf);
            if (format.old_value != format.new_value) {
                if (format.old_value > format.new_value) {
                    const del_fmt: Bytes = bytes(format.old_value -% format.new_value);
                    buf[len] = '(';
                    len +%= 1;
                    @memcpy(buf + len, fmt_spec.dec_style);
                    len +%= fmt_spec.dec_style.len;
                    len +%= del_fmt.formatWriteBuf(buf + len);
                    @memcpy(buf + len, fmt_spec.no_style);
                    len +%= fmt_spec.no_style.len;
                    buf[len] = ')';
                    len +%= 1;
                } else {
                    const del_fmt: Bytes = bytes(format.new_value -% format.old_value);
                    buf[len] = '(';
                    len +%= 1;
                    @memcpy(buf + len, fmt_spec.inc_style);
                    len +%= fmt_spec.inc_style.len;
                    len +%= del_fmt.formatWriteBuf(buf + len);
                    @memcpy(buf + len, fmt_spec.no_style);
                    len +%= fmt_spec.no_style.len;
                    buf[len] = ')';
                    len +%= 1;
                }
                @as(*[4]u8, @ptrCast(buf + len)).* = " => ".*;
                len +%= 4;
                len +%= new_fmt.formatWriteBuf(buf + len);
            }
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            const old_fmt: Bytes = bytes(format.old_value);
            const new_fmt: Bytes = bytes(format.new_value);
            var len: usize = 0;
            len +%= old_fmt.formatLength();
            if (format.old_value != format.new_value) {
                if (format.old_value > format.new_value) {
                    const del_fmt: Bytes = bytes(format.old_value -% format.new_value);
                    len +%= 1;
                    len +%= fmt_spec.dec_style.len;
                    len +%= del_fmt.formatLength();
                    len +%= fmt_spec.no_style.len;
                    len +%= 1;
                } else {
                    const del_fmt: Bytes = bytes(format.new_value -% format.old_value);
                    len +%= 1;
                    len +%= fmt_spec.inc_style.len;
                    len +%= del_fmt.formatLength();
                    len +%= fmt_spec.no_style.len;
                    len +%= 1;
                }
                len +%= 4;
                len +%= new_fmt.formatLength();
            }
            return len;
        }
        pub fn init(old_value: u64, new_value: u64) Format {
            return .{ .old_value = old_value, .new_value = new_value };
        }
    };
    return T;
}
pub fn GenericRangeFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    return (struct {
        lower: SubFormat.Int,
        upper: SubFormat.Int,
        const Format: type = @This();
        pub const spec: PolynomialFormatSpec = fmt_spec;
        pub const SubFormat = GenericPolynomialFormat(blk: {
            var tmp: PolynomialFormatSpec = fmt_spec;
            tmp.prefix = null;
            break :blk tmp;
        });
        pub const max_len: u64 = (SubFormat.max_len) *% 2 +% 4;
        pub fn formatLength(format: Format) u64 {
            const lower_fmt: SubFormat = SubFormat{ .value = format.lower };
            const upper_fmt: SubFormat = SubFormat{ .value = format.upper };
            const lower_s: SubFormat.StaticString = lower_fmt.formatConvert();
            const upper_s: SubFormat.StaticString = upper_fmt.formatConvert();
            const lower_s_count: u64 = lower_s.len();
            const upper_s_count: u64 = upper_s.len();
            for (lower_s.readAll(), 0..) |v, i| {
                if (v != upper_s.readOneAt(i)) {
                    return (upper_s_count -% lower_s_count) +% i +% 1 +% (lower_s_count -% i) +% 2 +% (upper_s_count -% i) +% 1;
                }
            }
            return (upper_s_count -% lower_s_count) +% lower_s.len() +% 4;
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            const lower_fmt: SubFormat = SubFormat{ .value = format.lower };
            const upper_fmt: SubFormat = SubFormat{ .value = format.upper };
            const lower_s: SubFormat.StaticString = lower_fmt.formatConvert();
            const upper_s: SubFormat.StaticString = upper_fmt.formatConvert();
            var idx: u64 = 0;
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
        pub usingnamespace GenericFormat(Format);
    });
}
pub const AddressRangeFormat = GenericRangeFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 16,
    .width = .min,
});
pub fn GenericArenaRangeFormat(comptime arena_index: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .index = arena_index };
    return GenericRangeFormat(.{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .max,
        .range = .{
            .min = arena.begin(),
            .max = arena.end(),
        },
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
    },
});
pub fn GenericChangedArenaRangeFormat(comptime arena_index: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .index = arena_index };
    const int_fmt_spec: PolynomialFormatSpec = .{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .max,
        .range = .{ .min = arena.begin(), .max = arena.end() },
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
    });
}
pub const ChangedRangeFormatSpec = struct {
    old_fmt_spec: PolynomialFormatSpec,
    new_fmt_spec: PolynomialFormatSpec,
    del_fmt_spec: PolynomialFormatSpec,
    lower_inc_style: []const u8 = tab.fx.color.fg.green ++ tab.fx.style.bold ++ "+",
    lower_dec_style: []const u8 = tab.fx.color.fg.red ++ tab.fx.style.bold ++ "-",
    upper_inc_style: []const u8 = tab.fx.color.fg.green ++ tab.fx.style.bold ++ "+",
    upper_dec_style: []const u8 = tab.fx.color.fg.red ++ tab.fx.style.bold ++ "-",
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
            var i: u64 = 0;
            const old_lower_s_count: u64 = old_lower_s.len();
            const old_upper_s_count: u64 = old_upper_s.len();
            while (i != old_lower_s_count) : (i +%= 1) {
                if (old_upper_s.readOneAt(i) != old_lower_s.readOneAt(i)) {
                    break;
                }
            }
            array.writeMany(old_upper_s.readAll()[0..i]);
            array.writeOne('{');
            var x: u64 = old_upper_s_count -% old_lower_s_count;
            while (x != 0) : (x -%= 1) array.writeOne('0');
            array.writeMany(old_lower_s.readAll()[i..old_lower_s_count]);
            if (format.old_lower != format.new_lower) {
                lower_del_fmt.formatWriteDelta(array);
            }
            array.writeMany("..");
            array.writeMany(old_upper_s.readAll()[i..old_upper_s_count]);
            if (format.old_upper != format.new_upper) {
                upper_del_fmt.formatWriteDelta(array);
            }
            array.writeOne('}');
            array.writeMany(" => ");
            i = 0;
            const new_lower_s_count: u64 = new_lower_s.len();
            const new_upper_s_count: u64 = new_upper_s.len();
            while (i != new_lower_s_count) : (i +%= 1) {
                if (new_upper_s.readOneAt(i) != new_lower_s.readOneAt(i)) {
                    break;
                }
            }
            array.writeMany(new_upper_s.readAll()[0..i]);
            array.writeOne('{');
            var y: u64 = new_upper_s_count -% new_lower_s_count;
            while (y != 0) : (y -%= 1) array.writeOne('0');
            array.writeMany(new_lower_s.readAll()[i..new_lower_s_count]);
            array.writeMany("..");
            array.writeMany(new_upper_s.readAll()[i..new_upper_s_count]);
            array.writeOne('}');
        }
        pub fn formatLength(format: Format) u64 {
            const old_lower_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_lower };
            const old_upper_fmt: OldGenericPolynomialFormat = OldGenericPolynomialFormat{ .value = format.old_upper };
            const old_lower_s: OldGenericPolynomialFormat.StaticString = old_lower_fmt.formatConvert();
            const old_upper_s: OldGenericPolynomialFormat.StaticString = old_upper_fmt.formatConvert();
            const new_lower_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_lower };
            const new_upper_fmt: NewGenericPolynomialFormat = NewGenericPolynomialFormat{ .value = format.new_upper };
            const new_lower_s: NewGenericPolynomialFormat.StaticString = new_lower_fmt.formatConvert();
            const new_upper_s: NewGenericPolynomialFormat.StaticString = new_upper_fmt.formatConvert();
            var len: u64 = 0;
            const lower_del_fmt: LowerChangedIntFormat = .{ .old_value = format.old_lower, .new_value = format.new_lower };
            const upper_del_fmt: UpperChangedIntFormat = .{ .old_value = format.old_upper, .new_value = format.new_upper };
            var i: u64 = 0;
            const old_lower_s_count: u64 = old_lower_s.len();
            const old_upper_s_count: u64 = old_upper_s.len();
            len +%= old_upper_s_count -% old_lower_s_count;
            if (format.old_lower != format.new_lower) {
                len +%= lower_del_fmt.formatLengthDelta();
            }
            if (format.old_upper != format.new_upper) {
                len +%= upper_del_fmt.formatLengthDelta();
            }
            while (i != old_lower_s_count) : (i +%= 1) {
                if (old_upper_s.readOneAt(i) != old_lower_s.readOneAt(i)) {
                    len +%= i +% 1 +%
                        (old_lower_s_count -% i) +% 2 +%
                        (old_upper_s_count -% i) +% 1 +% 4;
                    break;
                }
            }
            i = 0;
            const new_lower_s_count: u64 = new_lower_s.len();
            const new_upper_s_count: u64 = new_upper_s.len();
            len +%= new_upper_s_count -% new_lower_s_count;
            while (i != new_lower_s_count) : (i +%= 1) {
                if (new_upper_s.readOneAt(i) != new_lower_s.readOneAt(i)) {
                    len +%= i +% 1 +%
                        (new_lower_s_count -% i) +% 2 +%
                        (new_upper_s_count -% i) +% 1;
                    break;
                }
            }
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
pub fn GenericDateTimeFormat(comptime DateTime: type) type {
    const T = struct {
        value: DateTime,
        const Format: type = @This();
        pub const max_len: u64 = 19;
        pub fn formatConvert(format: Format) mem.StaticString(max_len) {
            var array: mem.StaticString(max_len) = undefined;
            array.undefineAll();
            format.formatWrite(&array);
            return array;
        }
        pub fn formatLength(format: Format) u64 {
            if (builtin.is_small) {
                if (@hasDecl(DateTime, "getNanoseconds")) {
                    return "0000-00-00 00:00:00.000000000".len;
                } else {
                    return "0000-00-00 00:00:00".len;
                }
            } else {
                var len: u64 = 0;
                len +%= yr(format.value.getYear()).formatLength();
                len +%= 1;
                len +%= mon(format.value.getMonth()).formatLength();
                len +%= 1;
                len +%= mday(format.value.getMonthDay()).formatLength();
                len +%= 1;
                len +%= hr(format.value.getHour()).formatLength();
                len +%= 1;
                len +%= min(format.value.getMinute()).formatLength();
                len +%= 1;
                len +%= sec(format.value.getSecond()).formatLength();
                if (@hasDecl(DateTime, "getNanoseconds")) {
                    len +%= 1;
                    len +%= sec(format.value.getNanoseconds()).formatLength();
                    @compileError("TODO: sig.fig. Formatter");
                }
                return len;
            }
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeFormat(yr(format.value.getYear()));
            array.writeOne('-');
            array.writeFormat(mon(format.value.getMonth()));
            array.writeOne('-');
            array.writeFormat(mday(format.value.getMonthDay()));
            array.writeOne(' ');
            array.writeFormat(hr(format.value.getHour()));
            array.writeOne(':');
            array.writeFormat(min(format.value.getMinute()));
            array.writeOne(':');
            array.writeFormat(sec(format.value.getSecond()));
            if (@hasDecl(DateTime, "getNanoseconds")) {
                array.writeOne('.');
                array.writeFormat(sec(format.value.getNanoSecond()));
                @compileError("TODO: sig.fig. Formatter");
            }
        }
    };
    return T;
}
pub const IdentifierFormat = struct {
    value: []const u8,
    const Format: type = @This();
    pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: u64 = 0;
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
pub fn isValidId(values: []const u8) bool {
    @setRuntimeSafety(builtin.is_safe);

    if (values.len == 0) {
        return false;
    }
    var byte: u8 = values[0];
    if (values.len == 1 and byte == '_') {
        return false;
    }
    if (byte >= '0' and byte <= '9') {
        return false;
    }
    var idx: usize = 0;
    if (byte == 'i' or byte == 'u') {
        idx +%= 1;
        while (idx != values.len) : (idx +%= 1) {
            switch (values[idx]) {
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
    while (idx != values.len) : (idx +%= 1) {
        switch (values[idx]) {
            '0'...'9', '_', 'a'...'z', 'A'...'Z' => {
                continue;
            },
            else => return false,
        }
    }
    return builtin.parse.keyword(values) == null;
}
pub fn typeName(comptime T: type) []const u8 {
    const type_info: builtin.Type = @typeInfo(T);
    const type_name: [:0]const u8 = @typeName(T);
    comptime switch (type_info) {
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
    };
}
fn typeNameDemangle(comptime type_name: []const u8, comptime decl_name: []const u8) []const u8 {
    var ret: []const u8 = type_name;
    var index: u64 = type_name.len;
    while (index != 0) {
        index -%= 1;
        if (type_name[index] == '_') {
            break;
        }
        if (type_name[index] < '0' or
            type_name[index] > '9')
        {
            return type_name;
        }
    }
    const serial = index;
    ret = type_name[0..index];
    if (ret.len < decl_name.len) {
        return type_name;
    }
    for (ret[ret.len -% decl_name.len ..], 0..) |c, i| {
        if (c != decl_name[i]) {
            return type_name;
        }
    }
    index -%= decl_name.len;
    return ret[0..index] ++ type_name[serial..];
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
pub fn typeDeclSpecifier(comptime type_info: builtin.Type) []const u8 {
    return switch (type_info) {
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
        .Opaque => "opaque",
        .ErrorSet => "error",
        else => @compileError(@typeName(@Type(type_info))),
    };
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
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            var len: u64 = 0;
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
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
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
    return struct {
        value: Int,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            if (@typeInfo(Int).Int.signedness == .signed) {
                const Abs = @Type(.{ .Int = .{
                    .signedness = .unsigned,
                    .bits = bit_size_of,
                } });
                var value: Int = format.value;

                while (true) {
                    const uvalue: Abs = @as(Abs, @bitCast(value));
                    const byte: u8 = @as(u8, @truncate(uvalue));
                    value >>= 6;
                    if (value == -1 or value == 0) {
                        array.writeOne(byte & 0x7f);
                        break;
                    } else {
                        value >>= 1;
                        array.writeOne(byte | 0x80);
                    }
                }
            } else {
                var value: Int = format.value;
                while (true) {
                    const byte: u8 = @as(u8, @truncate(value & 0x7f));
                    value >>= 7;
                    if (value == 0) {
                        array.writeOne(byte);
                        break;
                    } else {
                        array.writeOne(byte | 0x80);
                    }
                }
            }
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            var len: u64 = 0;
            if (@typeInfo(Int).Int.signedness == .signed) {
                const Abs = @Type(.{ .Int = .{
                    .signedness = .unsigned,
                    .bits = bit_size_of,
                } });
                var value: Int = format.value;
                while (true) {
                    const uvalue: Abs = @as(Abs, @bitCast(value));
                    const byte: u8 = @as(u8, @truncate(uvalue));
                    value >>= 6;
                    if (value == -1 or value == 0) {
                        buf[len] = byte & 0x7f;
                        len +%= 1;
                        break;
                    } else {
                        value >>= 1;
                        buf[len] = byte | 0x80;
                        len +%= 1;
                    }
                }
            } else {
                var value: Int = format.value;
                while (true) {
                    const byte: u8 = @as(u8, @truncate(value & 0x7f));
                    value >>= 7;
                    if (value == 0) {
                        buf[len] = byte;
                        len +%= 1;
                        break;
                    } else {
                        buf[len] = byte | 0x80;
                        len +%= 1;
                    }
                }
            }
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (@typeInfo(Int).Int.signedness == .signed) {
                var value: Int = format.value;
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
                var value: Int = format.value;
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
    };
}
pub fn writeUnsignedFixedLEB128(comptime width: usize, ptr: *[width]u8, int: @Type(.{ .Int = .{
    .signedness = .unsigned,
    .bits = width *% 7,
} })) void {
    const T = @TypeOf(int);
    const U = if (@typeInfo(T).Int.bits < 8) u8 else T;
    var value = @as(U, @intCast(int));
    var idx: usize = 0;
    while (idx != width -% 1) : (idx +%= 1) {
        const byte: u8 = @as(u8, @truncate(value)) | 0x80;
        value >>= 7;
        ptr[idx] = byte;
    }
    ptr[idx] = @as(u8, @truncate(value));
}
pub fn toCamelCases(noalias buf: []u8, names: []const []const u8) []u8 {
    var len: u64 = 0;
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
    var len: u64 = 0;
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
/// .{ 0xff, 0xff, 0xff, 0xff } => "ffffffff";
pub fn bytesToHex(dest: []u8, src: []const u8) []const u8 {
    var idx: u64 = 0;
    const max_idx: u64 = @min(dest.len / 2, src.len);
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
    var idx: u64 = 0;
    while (idx < src.len) : (idx +%= 2) {
        dest[idx / 2] =
            try parse.fromSymbolChecked(u8, src[idx], 16) << 4 |
            try parse.fromSymbolChecked(u8, src[idx +% 1], 16);
    }
    return dest[0 .. idx / 2];
}
/// "ffffffff" => .{ 0xff, 0xff, 0xff, 0xff };
pub fn hexToBytes2(dest: []u8, src: []const u8) []const u8 {
    var idx: u64 = 0;
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
pub fn requireComptime(comptime T: type) bool {
    switch (@typeInfo(T)) {
        .ComptimeFloat, .ComptimeInt, .Type => {
            return true;
        },
        .Pointer => |pointer_info| {
            return requireComptime(pointer_info.child);
        },
        .Array => |array_info| {
            return requireComptime(array_info.child);
        },
        .Struct => {
            inline for (@typeInfo(T).Struct.fields) |field| {
                if (requireComptime(field.type)) {
                    return true;
                }
            }
            return false;
        },
        .Union => {
            inline for (@typeInfo(T).Union.fields) |field| {
                if (requireComptime(field.type)) {
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
pub inline fn ud(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            debug.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn udh(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            debug.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
    .separator = .{},
}) {
    return .{ .value = value };
}
pub inline fn ub(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            debug.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ux(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            debug.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn id(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn idh(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 10,
    .signedness = .signed,
    .width = .min,
    .separator = .{},
}) {
    return .{ .value = value };
}
pub inline fn ib(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ix(value: anytype) GenericPolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            break :blk meta.realBitSizeOf(value);
        } else {
            break :blk meta.alignBitSizeOfAbove(T);
        }
    },
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ib8(value: i8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib16(value: i16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib32(value: i32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib64(value: i64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib128(value: i128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn io8(value: i8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io16(value: i16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io32(value: i32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io64(value: i64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io128(value: i128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn id8(value: i8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id16(value: i16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id32(value: i32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id64(value: i64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id128(value: i128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ix8(value: i8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix16(value: i16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix32(value: i32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix64(value: i64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix128(value: i128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn iz8(value: i8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz16(value: i16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz32(value: i32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz64(value: i64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz128(value: i128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn ub8(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub16(value: u16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub32(value: u32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub64(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn uo8(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo16(value: u16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo32(value: u32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo64(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo128(value: u128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn ud8(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud16(value: u16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud32(value: u32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud64(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud128(value: u128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ux8(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn esc(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "\\x",
}) {
    return .{ .value = value };
}
pub inline fn ux16(value: u16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux32(value: u32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux64(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux128(value: u128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn uz8(value: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz16(value: u16) GenericPolynomialFormat(.{
    .bits = 16,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz32(value: u32) GenericPolynomialFormat(.{
    .bits = 32,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz64(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz128(value: u128) GenericPolynomialFormat(.{
    .bits = 128,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub fn ubsize(value: usize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub fn uosize(value: usize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub fn udsize(value: usize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn uxsize(value: usize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub fn ibsize(value: isize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub fn iosize(value: isize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 8,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn idsize(value: isize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn ixsize(value: isize) GenericPolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 16,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn bytes(count: usize) Bytes {
    return Bytes.init(count);
}
pub fn identifier(name: []const u8) IdentifierFormat {
    return .{ .value = name };
}
pub fn sourceLocation(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
    return SourceLocationFormat.init(value, ret_addr);
}
pub fn yr(year: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 0, .max = 9999 },
}) {
    return .{ .value = year };
}
pub fn mon(month: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 12 },
}) {
    return .{ .value = month };
}
pub fn mday(month_day: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 31 },
}) {
    return .{ .value = month_day };
}
pub fn yday(year_day: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 1, .max = 366 },
}) {
    return .{ .value = year_day };
}
pub fn hr(hour: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 23 },
}) {
    return .{ .value = hour };
}
pub fn min(minute: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
}) {
    return .{ .value = minute };
}
pub fn sec(second: u8) GenericPolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
}) {
    return .{ .value = second };
}
/// Constructs DateTime formatter
pub fn dt(value: time.DateTime) GenericDateTimeFormat(time.DateTime) {
    return .{ .value = value };
}
/// Constructs packed DateTime formatter
pub fn pdt(value: time.PackedDateTime) GenericDateTimeFormat(time.PackedDateTime) {
    return .{ .value = value };
}
pub fn nsec(value: u64) GenericPolynomialFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 9 },
    .range = .{ .min = 0, .max = 999999999 },
}) {
    return .{ .value = value };
}
fn uniformChangedIntFormatSpec(comptime bits: u16, comptime signedness: builtin.Signedness, comptime radix: u16) ChangedIntFormatSpec {
    const old_fmt_spec: PolynomialFormatSpec = .{
        .bits = bits,
        .signedness = signedness,
        .width = if (radix == 2) .max else .min,
        .radix = radix,
    };
    const new_fmt_spec: PolynomialFormatSpec = .{
        .bits = bits,
        .signedness = .unsigned,
        .width = if (radix == 2) .max else .min,
        .radix = radix,
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
pub const Type = struct {
    pub const Ib8 = @TypeOf(ib8(undefined));
    pub const Ib16 = @TypeOf(ib16(undefined));
    pub const Ib32 = @TypeOf(ib32(undefined));
    pub const Ib64 = @TypeOf(ib64(undefined));
    pub const Ib128 = @TypeOf(ib128(undefined));
    pub const Io8 = @TypeOf(io8(undefined));
    pub const Io16 = @TypeOf(io16(undefined));
    pub const Io32 = @TypeOf(io32(undefined));
    pub const Io64 = @TypeOf(io64(undefined));
    pub const Io128 = @TypeOf(io128(undefined));
    pub const Id8 = @TypeOf(id8(undefined));
    pub const Id16 = @TypeOf(id16(undefined));
    pub const Id32 = @TypeOf(id32(undefined));
    pub const Id64 = @TypeOf(id64(undefined));
    pub const Id128 = @TypeOf(id128(undefined));
    pub const Ix8 = @TypeOf(ix8(undefined));
    pub const Ix16 = @TypeOf(ix16(undefined));
    pub const Ix32 = @TypeOf(ix32(undefined));
    pub const Ix64 = @TypeOf(ix64(undefined));
    pub const Ix128 = @TypeOf(ix128(undefined));
    pub const Iz8 = @TypeOf(iz8(undefined));
    pub const Iz16 = @TypeOf(iz16(undefined));
    pub const Iz32 = @TypeOf(iz32(undefined));
    pub const Iz64 = @TypeOf(iz64(undefined));
    pub const Iz128 = @TypeOf(iz128(undefined));
    pub const Ub8 = @TypeOf(ub8(undefined));
    pub const Ub16 = @TypeOf(ub16(undefined));
    pub const Ub32 = @TypeOf(ub32(undefined));
    pub const Ub64 = @TypeOf(ub64(undefined));
    pub const Uo8 = @TypeOf(uo8(undefined));
    pub const Uo16 = @TypeOf(uo16(undefined));
    pub const Uo32 = @TypeOf(uo32(undefined));
    pub const Uo64 = @TypeOf(uo64(undefined));
    pub const Uo128 = @TypeOf(uo128(undefined));
    pub const Ud8 = @TypeOf(ud8(undefined));
    pub const Ud16 = @TypeOf(ud16(undefined));
    pub const Ud32 = @TypeOf(ud32(undefined));
    pub const Ud64 = @TypeOf(ud64(undefined));
    pub const Ud128 = @TypeOf(ud128(undefined));
    pub const Ux8 = @TypeOf(ux8(undefined));
    pub const Ux16 = @TypeOf(ux16(undefined));
    pub const Ux32 = @TypeOf(ux32(undefined));
    pub const Ux64 = @TypeOf(ux64(undefined));
    pub const Ux128 = @TypeOf(ux128(undefined));
    pub const Uz8 = @TypeOf(uz8(undefined));
    pub const Uz16 = @TypeOf(uz16(undefined));
    pub const Uz32 = @TypeOf(uz32(undefined));
    pub const Uz64 = @TypeOf(uz64(undefined));
    pub const Uz128 = @TypeOf(uz128(undefined));
    pub const Ubsize = @TypeOf(ubsize(undefined));
    pub const Uosize = @TypeOf(uosize(undefined));
    pub const Udsize = @TypeOf(udsize(undefined));
    pub const Uxsize = @TypeOf(uxsize(undefined));
    pub const Ibsize = @TypeOf(ibsize(undefined));
    pub const Iosize = @TypeOf(iosize(undefined));
    pub const Idsize = @TypeOf(idsize(undefined));
    pub const Ixsize = @TypeOf(ixsize(undefined));
    pub const Esc = @TypeOf(esc(undefined));
    pub const NSec = @TypeOf(nsec(undefined));
    pub fn Ib(comptime Int: type) type {
        return @TypeOf(ib(@as(Int, undefined)));
    }
    pub fn Id(comptime Int: type) type {
        return @TypeOf(id(@as(Int, undefined)));
    }
    pub fn Ix(comptime Int: type) type {
        return @TypeOf(ix(@as(Int, undefined)));
    }
    pub fn Ub(comptime Int: type) type {
        return @TypeOf(ub(@as(Int, undefined)));
    }
    pub fn Uo(comptime Int: type) type {
        return @TypeOf(uo(@as(Int, undefined)));
    }
    pub fn Ud(comptime Int: type) type {
        return @TypeOf(ud(@as(Int, undefined)));
    }
    pub fn Ux(comptime Int: type) type {
        return @TypeOf(ux(@as(Int, undefined)));
    }
    pub fn Xb(comptime Int: type) type {
        if (@typeInfo(Int).Int.signedness == .signed) {
            return @TypeOf(ib(@as(Int, undefined)));
        } else {
            return @TypeOf(ub(@as(Int, undefined)));
        }
    }
    pub fn Xd(comptime Int: type) type {
        if (@typeInfo(Int).Int.signedness == .signed) {
            return @TypeOf(id(@as(Int, undefined)));
        } else {
            return @TypeOf(ud(@as(Int, undefined)));
        }
    }
    pub fn Xx(comptime Int: type) type {
        if (@typeInfo(Int).Int.signedness == .signed) {
            return @TypeOf(ix(@as(Int, undefined)));
        } else {
            return @TypeOf(ux(@as(Int, undefined)));
        }
    }
    pub fn Xo(comptime Int: type) type {
        if (@typeInfo(Int).Int.signedness == .signed) {
            unreachable;
        } else {
            return @TypeOf(uo(@as(Int, undefined)));
        }
    }
    pub const UDel = GenericChangedIntFormat(.{
        .old_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
        .new_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
        .del_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
    });
    pub const BytesDel = GenericChangedBytesFormat(.{});
    pub const Char = struct {
        value: u8,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            array.writeOne(format.value);
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) usize {
            buf[0] = format.value;
            return 1;
        }
        pub fn formatLength(_: Format) usize {
            return 1;
        }
    };
};
pub const old = struct {
    pub inline fn bin(comptime Int: type, value: Int) Generic(Int).Array2 {
        return Generic(Int).bin(value);
    }
    pub inline fn oct(comptime Int: type, value: Int) Generic(Int).Array8 {
        return Generic(Int).oct(value);
    }
    pub inline fn dec(comptime Int: type, value: Int) Generic(Int).Array10 {
        return Generic(Int).dec(value);
    }
    pub inline fn hex(comptime Int: type, value: Int) Generic(Int).Array16 {
        return Generic(Int).hex(value);
    }
    pub const ub8 = Generic(u8).bin;
    pub const ub16 = Generic(u16).bin;
    pub const ub32 = Generic(u32).bin;
    pub const ub64 = Generic(u64).bin;
    pub const ubsize = Generic(usize).bin;
    pub const uo8 = Generic(u8).oct;
    pub const uo16 = Generic(u16).oct;
    pub const uo32 = Generic(u32).oct;
    pub const uo64 = Generic(u64).oct;
    pub const uosize = Generic(usize).oct;
    pub const ud8 = Generic(u8).dec;
    pub const ud16 = Generic(u16).dec;
    pub const ud32 = Generic(u32).dec;
    pub const ud64 = Generic(u64).dec;
    pub const udsize = Generic(usize).dec;
    pub const ux8 = Generic(u8).hex;
    pub const ux16 = Generic(u16).hex;
    pub const ux32 = Generic(u32).hex;
    pub const ux64 = Generic(u64).hex;
    pub const uxsize = Generic(usize).hex;
    pub const ib8 = Generic(i8).bin;
    pub const ib16 = Generic(i16).bin;
    pub const ib32 = Generic(i32).bin;
    pub const ib64 = Generic(i64).bin;
    pub const ibsize = Generic(isize).bin;
    pub const io8 = Generic(i8).oct;
    pub const io16 = Generic(i16).oct;
    pub const io32 = Generic(i32).oct;
    pub const io64 = Generic(i64).oct;
    pub const iosize = Generic(isize).oct;
    pub const id8 = Generic(i8).dec;
    pub const id16 = Generic(i16).dec;
    pub const id32 = Generic(i32).dec;
    pub const id64 = Generic(i64).dec;
    pub const idsize = Generic(isize).dec;
    pub const ix8 = Generic(i8).hex;
    pub const ix16 = Generic(i16).hex;
    pub const ix32 = Generic(i32).hex;
    pub const ix64 = Generic(i64).hex;
    pub const ixsize = Generic(isize).hex;
    pub const nsec = Generic(u64).nsec;
    pub fn Generic(comptime Int: type) type {
        const T = struct {
            const Abs = math.Absolute(Int);
            const len2: comptime_int = maxSigFig(Int, 2) +% 1;
            const len8: comptime_int = maxSigFig(Int, 8) +% 1;
            const len10: comptime_int = maxSigFig(Int, 10) +% 1;
            const len16: comptime_int = maxSigFig(Int, 16) +% 1;
            pub const Array2 = Array(len2);
            pub const Array8 = Array(len8);
            pub const Array10 = Array(len10);
            pub const Array16 = Array(len16);
            pub fn bin(value: Int) Array2 {
                @setRuntimeSafety(false);
                var ret: Array2 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    while (ret.len != 3) {
                        ret.len -%= 1;
                        ret.buf[ret.len] = '0';
                    }
                    ret.len -%= 2;
                    @as(*[2]u8, @ptrCast(&ret.buf[ret.len])).* = "0b".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @intCast(-value)
                else
                    @intCast(value);
                while (abs_value != 0) : (abs_value /= 2) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @as(u8, @intCast(@rem(abs_value, 2)));
                }
                while (ret.len != 3) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                }
                ret.len -%= 2;
                @as(*[2]u8, @ptrCast(ret.buf[ret.len..].ptr)).* = "0b".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            pub fn oct(value: Int) Array8 {
                @setRuntimeSafety(false);
                var ret: Array8 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 3;
                    @as(*[3]u8, @ptrCast(ret.buf[ret.len..].ptr)).* = "0o0".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @as(Abs, @intCast(-value))
                else
                    @as(Abs, @intCast(value));
                while (abs_value != 0) : (abs_value /= 8) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @as(u8, @intCast(@rem(abs_value, 8)));
                }
                ret.len -%= 2;
                @as(*[2]u8, @ptrCast(ret.buf[ret.len..].ptr)).* = "0o".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            pub fn dec(value: Int) Array10 {
                @setRuntimeSafety(false);
                var ret: Array10 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @as(Abs, @intCast(-value))
                else
                    @as(Abs, @intCast(value));
                while (abs_value != 0) : (abs_value /= 10) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0' +% @as(u8, @intCast(@rem(abs_value, 10)));
                }
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            pub fn hex(value: Int) Array16 {
                @setRuntimeSafety(false);
                var ret: Array16 = undefined;
                ret.len = ret.buf.len;
                if (value == 0) {
                    ret.len -%= 3;
                    @as(*[3]u8, @ptrCast(ret.buf[ret.len..].ptr)).* = "0x0".*;
                    return ret;
                }
                var abs_value: Abs = if (Int != Abs and value < 0)
                    @as(Abs, @bitCast(-value))
                else
                    @as(Abs, @intCast(value));
                while (abs_value != 0) : (abs_value /= 16) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = toSymbol(Abs, abs_value, 16);
                }
                ret.len -%= 2;
                @as(*[2]u8, @ptrCast(ret.buf[ret.len..].ptr)).* = "0x".*;
                if (value < 0) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '-';
                }
                return ret;
            }
            pub fn nsec(value: Int) Array10 {
                @setRuntimeSafety(false);
                var ret: Array10 = @This().dec(value);
                while (ret.buf.len -% ret.len < 9) {
                    ret.len -%= 1;
                    ret.buf[ret.len] = '0';
                }
                return ret;
            }
            fn Array(comptime len: comptime_int) type {
                return struct {
                    len: u64,
                    buf: [len]u8 align(8),
                    pub fn readAll(array: *const @This()) []const u8 {
                        return array.buf[array.len..];
                    }
                };
            }
        };
        return T;
    }
};
