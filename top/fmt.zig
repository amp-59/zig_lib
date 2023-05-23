const lit = @import("./lit.zig");
const zig = @import("./zig.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const time = @import("./time.zig");
const spec = @import("./spec.zig");
const builtin = @import("./builtin.zig");
const _render = @import("./render.zig");
pub const utf8 = @import("./fmt/utf8.zig");
//pub const json = @import("./fmt/json.zig");
pub usingnamespace _render;
fn GenericFormat(comptime Format: type) type {
    const T = struct {
        const StaticString = mem.StaticString(Format.max_len);
        pub fn formatConvert(format: Format) StaticString {
            var array: StaticString = .{};
            array.writeFormat(format);
            return array;
        }
        fn checkLen(len: u64) u64 {
            if (@hasDecl(Format, "max_len") and len != Format.max_len) {
                builtin.debug.logFault("formatter max length exceeded");
            }
            return len;
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
pub fn PolynomialFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    const T = struct {
        value: Int,
        const Format: type = @This();
        const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        const min_abs_value: Abs = fmt_spec.range.min orelse 0;
        const max_abs_value: Abs = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: u16 = builtin.fmt.length(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: u16 = builtin.fmt.length(Abs, max_abs_value, fmt_spec.radix);
        pub const spec: PolynomialFormatSpec = fmt_spec;
        const max_len: u64 = blk: {
            var len: u64 = 0;
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
                return 1 +% ~@bitCast(Abs, format.value);
            } else {
                return @bitCast(Abs, format.value);
            }
        }
        inline fn digits(format: Format) u64 {
            if (fmt_spec.radix > max_abs_value) {
                return 1;
            }
            const digits_len: u64 = switch (fmt_spec.width) {
                .min => builtin.fmt.length(Abs, format.absolute(), fmt_spec.radix),
                .max => max_digits_count,
                .fixed => |fixed| fixed,
            };
            if (fmt_spec.separator) |s| {
                return digits_len +% (digits_len -% 1) / s.digits;
            } else {
                return digits_len;
            }
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            array.define(@call(.always_inline, formatWriteBuf, .{
                format,
                @ptrCast([*]u8, array.referOneUndefined()),
            }));
        }
        pub fn formatWriteBuf(format: Format, buf: [*]u8) u64 {
            var len: u64 = 0;
            if (Abs != Int) {
                buf[0] = '-';
            }
            len +%= builtin.int(u64, format.value < 0);
            if (fmt_spec.prefix) |prefix| {
                len +%= builtin.arrcpy(buf + len, prefix.*);
            }
            if (fmt_spec.radix > max_abs_value) {
                buf[len] = '0' +% builtin.int(u8, format.value != 0);
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
                    sep +%= builtin.int2a(u64, b0, b1);
                    buf[len - (sep +% pos)] =
                        builtin.fmt.toSymbol(Abs, value, fmt_spec.radix);
                }
            } else {
                const count: u64 = format.digits();
                var value: Abs = format.absolute();
                len +%= count;
                var pos: u64 = 0;
                while (pos != count) : (value /= fmt_spec.radix) {
                    pos +%= 1;
                    buf[len -% pos] =
                        builtin.fmt.toSymbol(Abs, value, fmt_spec.radix);
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
        pub usingnamespace GenericFormat(Format);
    };
    return T;
}
pub fn uo(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assert(value > 0);
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
    const LineColFormat = PolynomialFormat(.{
        .bits = 32,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const AddrFormat = PolynomialFormat(.{
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
        @ptrCast(*[4]u8, buf).* = "\x1b[1m".*;
        mach.memcpy(buf + len, file_name.ptr, file_name.len);
        len +%= len;
        buf[len] = ':';
        len +%= 1;
        len +%= line_fmt.formatWriteBuf(buf + len);
        buf[len] = ':';
        len +%= 1;
        len +%= column_fmt.formatWriteBuf(buf + len);
        @ptrCast(*[7]u8, buf + len).* = ":\x1b[0;2m".*;
        len +%= 7;
        len +%= ret_addr_fmt.formatWriteBuf(buf + len);
        @ptrCast(*[4]u8, buf + len).* = " in ".*;
        len +%= 4;
        mach.memcpy(buf + len, fn_name.ptr, fn_name.len);
        len +%= fn_name.len;
        @ptrCast(*[5]u8, buf + len).* = "\x1b[0m\n".*;
        return len +% 4;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        array.writeMany(lit.fx.style.bold);
        array.writeMany(file_name);
        array.writeOne(':');
        array.writeFormat(line_fmt);
        array.writeOne(':');
        array.writeFormat(column_fmt);
        array.writeMany(": " ++ lit.fx.none ++ lit.fx.style.faint);
        array.writeFormat(ret_addr_fmt);
        array.writeMany(" in ");
        array.writeMany(fn_name);
        array.writeMany(lit.fx.none ++ "\n");
    }
    fn functionName(format: SourceLocationFormat) []const u8 {
        var start: u64 = 0;
        var idx: u64 = 0;
        while (idx != format.value.fn_name.len) : (idx +%= 1) {
            if (format.value.fn_name[idx] == '.') start = idx;
        }
        return format.value.fn_name[start +% @boolToInt(start != 0) .. :0];
    }
    pub fn formatLength(format: SourceLocationFormat) u64 {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: u64 = 0;
        len +%= lit.fx.style.bold.len;
        len +%= file_name.len;
        len +%= 1;
        len +%= line_fmt.formatLength();
        len +%= 1;
        len +%= column_fmt.formatLength();
        len +%= 2;
        len +%= lit.fx.none.len +% lit.fx.style.faint.len;
        len +%= ret_addr_fmt.formatLength();
        len +%= 4;
        len +%= fn_name.len;
        len +%= lit.fx.none.len;
        len +%= 1;
        return len;
    }
    pub fn init(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
        return .{ .value = value, .return_address = @intCast(u32, ret_addr orelse @returnAddress()) };
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
    const MajorIntFormat = PolynomialFormat(.{
        .bits = 16,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const MinorIntFormat = PolynomialFormat(.{
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
        return .{ .value = @intCast(u10, (format.value.remainder.count * 1000) / 1024) };
    }
    fn formatInteger(format: Format) MajorIntFormat {
        return .{ .value = @intCast(u10, format.value.integer.count) };
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
        mach.memcpy(buf + len, @tagName(format.value.integer.unit).ptr, @tagName(format.value.integer.unit).len);
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
    dec_style: []const u8 = lit.fx.color.fg.red ++ "-",
    inc_style: []const u8 = lit.fx.color.fg.green ++ "+",
    no_style: []const u8 = lit.fx.none,
    arrow_style: []const u8 = " => ",
};
pub fn ChangedIntFormat(comptime fmt_spec: ChangedIntFormatSpec) type {
    return (struct {
        old_value: Old,
        new_value: New,
        const Format: type = @This();
        const Old: type = @Type(.{ .Int = .{ .bits = fmt_spec.old_fmt_spec.bits, .signedness = fmt_spec.old_fmt_spec.signedness } });
        const New: type = @Type(.{ .Int = .{ .bits = fmt_spec.new_fmt_spec.bits, .signedness = fmt_spec.new_fmt_spec.signedness } });
        const OldIntFormat = PolynomialFormat(fmt_spec.old_fmt_spec);
        const NewIntFormat = PolynomialFormat(fmt_spec.new_fmt_spec);
        const DeltaIntFormat = PolynomialFormat(fmt_spec.del_fmt_spec);
        pub const max_len: u64 = @max(fmt_spec.dec_style.len, fmt_spec.inc_style.len) +%
            OldIntFormat.max_len +% 1 +% DeltaIntFormat.max_len +% 5 +% fmt_spec.no_style.len +% NewIntFormat.max_len;
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
                @ptrCast(*[4]u8, buf).* = "(+0)".*;
                len +%= 4;
            } else if (format.new_value > format.old_value) {
                const del_fmt: DeltaIntFormat = .{ .value = format.new_value -% format.old_value };
                buf[len] = '(';
                len +%= 1;
                mach.memcpy(buf + len, fmt_spec.inc_style.ptr, fmt_spec.inc_style.len);
                len +%= fmt_spec.inc_style.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                mach.memcpy(buf + len, fmt_spec.no_style.ptr, fmt_spec.no_style.len);
                len +%= fmt_spec.no_style.len;
                buf[len] = ')';
                len +%= 1;
            } else {
                const del_fmt: DeltaIntFormat = .{ .value = format.old_value -% format.new_value };
                buf[len] = '(';
                len +%= 1;
                mach.memcpy(buf + len, fmt_spec.dec_style.ptr, fmt_spec.dec_style.len);
                len +%= fmt_spec.dec_style.len;
                len +%= del_fmt.formatWriteBuf(buf + len);
                mach.memcpy(buf + len, fmt_spec.no_style.ptr, fmt_spec.no_style.len);
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
            mach.memcpy(buf + len, fmt_spec.arrow_style.ptr, fmt_spec.arrow_style.len);
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
    });
}
pub const ChangedBytesFormatSpec = struct {
    dec_style: []const u8 = lit.fx.color.fg.red ++ "-",
    inc_style: []const u8 = lit.fx.color.fg.green ++ "+",
    no_style: []const u8 = lit.fx.none,
};
pub fn ChangedBytesFormat(comptime fmt_spec: ChangedBytesFormatSpec) type {
    return (struct {
        old_value: u64,
        new_value: u64,
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
            const old_fmt: Bytes = bytes(format.old_value);
            const new_fmt: Bytes = bytes(format.new_value);
            var len: u64 = old_fmt.formatWriteBuf(buf);
            if (format.old_value != format.new_value) {
                if (format.old_value > format.new_value) {
                    const del_fmt: Bytes = bytes(format.old_value -% format.new_value);
                    buf[len] = '(';
                    len +%= 1;
                    mach.memcpy(buf + len, fmt_spec.dec_style.ptr, fmt_spec.dec_style.len);
                    len +%= fmt_spec.dec_style.len;
                    len +%= del_fmt.formatWriteBuf(buf + len);
                    mach.memcpy(buf + len, fmt_spec.no_style.ptr, fmt_spec.no_style.len);
                    len +%= fmt_spec.no_style.len;
                    buf[len] = ')';
                    len +%= 1;
                } else {
                    const del_fmt: Bytes = bytes(format.new_value -% format.old_value);
                    buf[len] = '(';
                    len +%= 1;
                    mach.memcpy(buf + len, fmt_spec.inc_style.ptr, fmt_spec.inc_style.len);
                    len +%= fmt_spec.inc_style.len;
                    len +%= del_fmt.formatWriteBuf(buf + len);
                    mach.memcpy(buf + len, fmt_spec.no_style.ptr, fmt_spec.no_style.len);
                    len +%= fmt_spec.no_style.len;
                    buf[len] = ')';
                    len +%= 1;
                }
                @ptrCast(*[4]u8, buf + len).* = " => ".*;
                len +%= 4;
                len +%= new_fmt.formatWriteBuf(buf + len);
            }
            return len;
        }
        pub fn formatLength(format: Format) u64 {
            const old_fmt: Bytes = bytes(format.old_value);
            const new_fmt: Bytes = bytes(format.new_value);
            var len: u64 = 0;
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
    });
}
pub fn RangeFormat(comptime fmt_spec: PolynomialFormatSpec) type {
    return (struct {
        lower: SubFormat.Int,
        upper: SubFormat.Int,
        const Format: type = @This();
        pub const spec: PolynomialFormatSpec = fmt_spec;
        pub const SubFormat = PolynomialFormat(blk: {
            var tmp: PolynomialFormatSpec = fmt_spec;
            tmp.prefix = null;
            break :blk tmp;
        });
        pub const max_len: u64 = (SubFormat.max_len) * 2 +% 4;
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
            var i: u64 = 0;
            const lower_s_count: u64 = lower_s.len();
            const upper_s_count: u64 = upper_s.len();
            while (i != lower_s_count) : (i +%= 1) {
                if (upper_s.readOneAt(i) != lower_s.readOneAt(i)) {
                    break;
                }
            }
            array.writeMany(upper_s.readAll()[0..i]);
            array.writeOne('{');
            var z: u64 = upper_s_count -% lower_s_count;
            while (z != 0) : (z -%= 1) array.writeOne('0');
            array.writeMany(lower_s.readAll()[i..lower_s_count]);
            array.writeMany("..");
            array.writeMany(upper_s.readAll()[i..upper_s_count]);
            array.writeOne('}');
        }
        pub fn init(lower: SubFormat.Int, upper: SubFormat.Int) Format {
            return .{ .lower = lower, .upper = upper };
        }
        pub usingnamespace GenericFormat(Format);
    });
}
pub const AddressRangeFormat = RangeFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 16,
    .width = .min,
});
pub fn ArenaRangeFormat(comptime arena_index: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .index = arena_index };
    return RangeFormat(.{
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
pub const ChangedAddressRangeFormat = ChangedRangeFormat(.{
    .new_fmt_spec = AddressRangeFormat.spec,
    .old_fmt_spec = AddressRangeFormat.spec,
    .del_fmt_spec = .{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .min,
    },
});
pub fn ChangedArenaRangeFormat(comptime arena_index: comptime_int) type {
    const arena: mem.Arena = mem.Arena{ .index = arena_index };
    const int_fmt_spec: PolynomialFormatSpec = .{
        .bits = 64,
        .signedness = .unsigned,
        .radix = 16,
        .width = .max,
        .range = .{ .min = arena.begin(), .max = arena.end() },
    };
    return ChangedRangeFormat(.{
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
    lower_inc_style: []const u8 = lit.fx.color.fg.green ++ lit.fx.style.bold ++ "+",
    lower_dec_style: []const u8 = lit.fx.color.fg.red ++ lit.fx.style.bold ++ "-",
    upper_inc_style: []const u8 = lit.fx.color.fg.green ++ lit.fx.style.bold ++ "+",
    upper_dec_style: []const u8 = lit.fx.color.fg.red ++ lit.fx.style.bold ++ "-",
    arrow_style: []const u8 = " => ",
};
pub fn ChangedRangeFormat(comptime fmt_spec: ChangedRangeFormatSpec) type {
    return (struct {
        old_lower: OldPolynomialFormat.Int,
        old_upper: OldPolynomialFormat.Int,
        new_lower: NewPolynomialFormat.Int,
        new_upper: NewPolynomialFormat.Int,
        const Format: type = @This();
        const OldPolynomialFormat = PolynomialFormat(fmt_spec.old_fmt_spec);
        const NewPolynomialFormat = PolynomialFormat(fmt_spec.new_fmt_spec);
        const DelPolynomialFormat = PolynomialFormat(fmt_spec.del_fmt_spec);
        const LowerChangedIntFormat = ChangedIntFormat(.{
            .old_fmt_spec = fmt_spec.old_fmt_spec,
            .new_fmt_spec = fmt_spec.new_fmt_spec,
            .del_fmt_spec = fmt_spec.del_fmt_spec,
            .dec_style = fmt_spec.lower_dec_style,
            .inc_style = fmt_spec.lower_inc_style,
            .arrow_style = fmt_spec.arrow_style,
        });
        const UpperChangedIntFormat = ChangedIntFormat(.{
            .old_fmt_spec = fmt_spec.old_fmt_spec,
            .new_fmt_spec = fmt_spec.new_fmt_spec,
            .del_fmt_spec = fmt_spec.del_fmt_spec,
            .dec_style = fmt_spec.upper_dec_style,
            .inc_style = fmt_spec.upper_inc_style,
            .arrow_style = fmt_spec.arrow_style,
        });
        pub fn formatWrite(format: Format, array: anytype) void {
            const old_lower_fmt: OldPolynomialFormat = OldPolynomialFormat{ .value = format.old_lower };
            const old_upper_fmt: OldPolynomialFormat = OldPolynomialFormat{ .value = format.old_upper };
            const old_lower_s: OldPolynomialFormat.StaticString = old_lower_fmt.formatConvert();
            const old_upper_s: OldPolynomialFormat.StaticString = old_upper_fmt.formatConvert();
            const new_lower_fmt: NewPolynomialFormat = NewPolynomialFormat{ .value = format.new_lower };
            const new_upper_fmt: NewPolynomialFormat = NewPolynomialFormat{ .value = format.new_upper };
            const new_lower_s: NewPolynomialFormat.StaticString = new_lower_fmt.formatConvert();
            const new_upper_s: NewPolynomialFormat.StaticString = new_upper_fmt.formatConvert();
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
            const old_lower_fmt: OldPolynomialFormat = OldPolynomialFormat{ .value = format.old_lower };
            const old_upper_fmt: OldPolynomialFormat = OldPolynomialFormat{ .value = format.old_upper };
            const old_lower_s: OldPolynomialFormat.StaticString = old_lower_fmt.formatConvert();
            const old_upper_s: OldPolynomialFormat.StaticString = old_upper_fmt.formatConvert();
            const new_lower_fmt: NewPolynomialFormat = NewPolynomialFormat{ .value = format.new_lower };
            const new_upper_fmt: NewPolynomialFormat = NewPolynomialFormat{ .value = format.new_upper };
            const new_lower_s: NewPolynomialFormat.StaticString = new_lower_fmt.formatConvert();
            const new_upper_s: NewPolynomialFormat.StaticString = new_upper_fmt.formatConvert();
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
            old_lower: OldPolynomialFormat.Int,
            old_upper: OldPolynomialFormat.Int,
            new_lower: NewPolynomialFormat.Int,
            new_upper: NewPolynomialFormat.Int,
        ) Format {
            return .{
                .old_lower = old_lower,
                .old_upper = old_upper,
                .new_lower = new_lower,
                .new_upper = new_upper,
            };
        }
    });
}
pub const ListFormatSpec = struct {
    item: type,
    transform: ?meta.Generic = null,
    separator: []const u8 = ", ",
    omit_trailing_separator: bool = true,
    reinterpret: mem.ReinterpretSpec = spec.reinterpret.fmt,
};
pub fn ListFormat(comptime fmt_spec: ListFormatSpec) type {
    return (struct {
        values: []const fmt_spec.item,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
            if (fmt_spec.omit_trailing_separator) {
                if (format.values.len != 0) {
                    if (fmt_spec.transform) |transform| {
                        array.writeFormat(meta.typeCast(transform)(format.values[0]));
                    } else {
                        array.writeMany(format.values[0]);
                    }
                }
                if (format.values.len != 1) {
                    for (format.values[1..]) |value| {
                        array.writeAny(fmt_spec.reinterpret, fmt_spec.separator);
                        if (fmt_spec.transform) |transform| {
                            array.writeFormat(meta.typeCast(transform)(value));
                        } else {
                            array.writeMany(value);
                        }
                    }
                }
            } else {
                for (format.values) |value| {
                    if (fmt_spec.transform) |transform| {
                        array.writeFormat(meta.typeCast(transform)(value));
                    } else {
                        array.writeMany(value);
                    }
                    array.writeMany(fmt_spec.separator);
                }
            }
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (fmt_spec.omit_trailing_separator) {
                if (format.values.len != 0) {
                    len +%= mem.ReinterpretSpec.lengthAny(fmt_spec.reinterpret, fmt_spec.separator);
                    if (fmt_spec.transform) |transform| {
                        len +%= mem.ReinterpretSpec.lengthFormat(meta.typeCast(transform)(format.values[0]));
                    } else {
                        len +%= format.values.len;
                    }
                }
                if (format.values.len != 1) {
                    for (format.values[1..]) |value| {
                        len +%= mem.ReinterpretSpec.lengthAny(fmt_spec.reinterpret, fmt_spec.separator);
                        if (fmt_spec.transform) |transform| {
                            len +%= mem.ReinterpretSpec.lengthFormat(meta.typeCast(transform)(value));
                        } else {
                            len +%= format.value.len;
                        }
                    }
                }
            } else {
                for (format.values) |value| {
                    if (fmt_spec.transform) |transform| {
                        len +%= mem.ReinterpretSpec.lengthFormat(meta.typeCast(transform)(value));
                    } else {
                        len +%= format.value.len;
                    }
                    len +%= mem.ReinterpretSpec.lengthAny(fmt_spec.reinterpret, fmt_spec.separator);
                }
            }
            return len;
        }
    });
}
pub fn list(values: []const []const u8) ListFormat(.{ .item = []const u8 }) {
    return .{ .values = values };
}
pub fn DateTimeFormat(comptime DateTime: type) type {
    return (struct {
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
    });
}
pub const IdentifierFormat = struct {
    value: []const u8,
    const Format: type = @This();
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
/// This function attempts to shorten type names, to improve readability, and
/// makes no attempt to accomodate for extreme names, such as enabled by @"".
pub fn typeName(comptime T: type) []const u8 {
    const type_info: builtin.Type = @typeInfo(T);
    const type_name: [:0]const u8 = @typeName(T);
    comptime switch (type_info) {
        .Pointer => |pointer_info| {
            return builtin.fmt.typeDeclSpecifier(type_info) ++
                typeName(pointer_info.child);
        },
        .Array => |array_info| {
            return builtin.fmt.typeDeclSpecifier(type_info) ++
                typeName(array_info.child);
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
pub fn isValidId(values: []const u8) bool {
    if (values.len == 0) return false;
    if (mem.testEqualMany(u8, "_", values)) {
        return false;
    }
    for (values, 0..) |c, i| {
        switch (c) {
            '_', 'a'...'z', 'A'...'Z' => {
                continue;
            },
            '0'...'9' => if (i == 0) {
                return false;
            },
            else => {
                return false;
            },
        }
    }
    return zig.Token.getKeyword(values) == null;
}
const EscapedStringFormatSpec = struct {
    single_quote: []const u8 = "\'",
    double_quote: []const u8 = "\\\"",
};
pub fn EscapedStringFormat(comptime fmt_spec: EscapedStringFormatSpec) type {
    const T = struct {
        value: []const u8,
        const Format = @This();
        pub fn formatWrite(format: Format, array: anytype) void {
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
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
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
            return len;
        }
    };
    return T;
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
pub fn toTitlecases(noalias buf: []u8, comptime names: []const []const u8) []u8 {
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
    mach.memcpy(buf.ptr, name.ptr, name.len);
    if (buf[0] >= 'a') {
        buf[0] +%= ('a' -% 'A');
    }
    return buf[0..name.len];
}
/// .{ 0xff, 0xff, 0xff, 0xff } => "ffffffff";
pub fn bytesToHex(dest: []u8, src: []const u8) []const u8 {
    var idx: u64 = 0;
    while (idx < src.len) : (idx +%= 1) {
        dest[idx * 2 +% 0] = builtin.fmt.toSymbol(u8, src[idx] / 16, 16);
        dest[idx * 2 +% 1] = builtin.fmt.toSymbol(u8, src[idx] & 15, 16);
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
            try builtin.parse.fromSymbolChecked(src[idx], 16) << 4 |
            try builtin.parse.fromSymbolChecked(src[idx +% 1], 16);
    }
    return dest[0 .. idx / 2];
}
/// "ffffffff" => .{ 0xff, 0xff, 0xff, 0xff };
pub fn hexToBytes2(dest: []u8, src: []const u8) []const u8 {
    var idx: u64 = 0;
    while (idx < src.len) : (idx +%= 2) {
        dest[idx / 2] =
            builtin.parse.fromSymbol(src[idx], 16) << 4 |
            builtin.parse.fromSymbol(src[idx +% 1], 16);
    }
    return dest[0 .. idx / 2];
}
pub const static = struct {
    fn concatUpper(comptime s: []const u8, comptime c: u8) []const u8 {
        return switch (c) {
            'a'...'z' => s ++ [1]u8{c -% ('a' -% 'A')},
            else => s ++ [1]u8{c},
        };
    }
    pub fn toInitialism(comptime names: []const []const u8) []const u8 {
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
    pub fn toCamelCases(comptime names: []const []const u8) []const u8 {
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
    pub fn toCamelCase(comptime name: []const u8) []const u8 {
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
    pub fn toTitlecases(comptime names: []const []const u8) []const u8 {
        const rename: []const u8 = static.toCamelCases(names);
        if (rename[0] >= 'a') {
            return [1]u8{rename[0] -% ('a' -% 'A')} ++ rename[1..rename.len];
        } else {
            return rename;
        }
    }
    pub fn toTitlecase(comptime name: []const u8) []const u8 {
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
pub inline fn ud(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn udh(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
    .separator = .{},
}) {
    return .{ .value = value };
}
pub inline fn ub(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ux(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn id(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn idh(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 10,
    .signedness = .signed,
    .width = .min,
    .separator = .{},
}) {
    return .{ .value = value };
}
pub inline fn ib(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ix(value: anytype) PolynomialFormat(.{
    .bits = blk: {
        const T: type = @TypeOf(value);
        if (T == comptime_int) {
            builtin.static.assertAboveOrEqual(comptime_int, value, 0);
            break :blk meta.alignCX(value);
        } else {
            break :blk meta.alignSizeAW(T);
        }
    },
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ib8(value: i8) PolynomialFormat(.{
    .bits = 8,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib16(value: i16) PolynomialFormat(.{
    .bits = 16,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib32(value: i32) PolynomialFormat(.{
    .bits = 32,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib64(value: i64) PolynomialFormat(.{
    .bits = 64,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ib128(value: i128) PolynomialFormat(.{
    .bits = 128,
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn io8(value: i8) PolynomialFormat(.{
    .bits = 8,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io16(value: i16) PolynomialFormat(.{
    .bits = 16,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io32(value: i32) PolynomialFormat(.{
    .bits = 32,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io64(value: i64) PolynomialFormat(.{
    .bits = 64,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn io128(value: i128) PolynomialFormat(.{
    .bits = 128,
    .radix = 8,
    .signedness = .signed,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn id8(value: i8) PolynomialFormat(.{
    .bits = 8,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id16(value: i16) PolynomialFormat(.{
    .bits = 16,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id32(value: i32) PolynomialFormat(.{
    .bits = 32,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id64(value: i64) PolynomialFormat(.{
    .bits = 64,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn id128(value: i128) PolynomialFormat(.{
    .bits = 128,
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ix8(value: i8) PolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix16(value: i16) PolynomialFormat(.{
    .bits = 16,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix32(value: i32) PolynomialFormat(.{
    .bits = 32,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix64(value: i64) PolynomialFormat(.{
    .bits = 64,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ix128(value: i128) PolynomialFormat(.{
    .bits = 128,
    .radix = 16,
    .signedness = .signed,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn iz8(value: i8) PolynomialFormat(.{
    .bits = 8,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz16(value: i16) PolynomialFormat(.{
    .bits = 16,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz32(value: i32) PolynomialFormat(.{
    .bits = 32,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz64(value: i64) PolynomialFormat(.{
    .bits = 64,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn iz128(value: i128) PolynomialFormat(.{
    .bits = 128,
    .radix = 36,
    .signedness = .signed,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn ub8(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub16(value: u16) PolynomialFormat(.{
    .bits = 16,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub32(value: u32) PolynomialFormat(.{
    .bits = 32,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn ub64(value: u64) PolynomialFormat(.{
    .bits = 64,
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub inline fn uo8(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo16(value: u16) PolynomialFormat(.{
    .bits = 16,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo32(value: u32) PolynomialFormat(.{
    .bits = 32,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo64(value: u64) PolynomialFormat(.{
    .bits = 64,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn uo128(value: u128) PolynomialFormat(.{
    .bits = 128,
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub inline fn ud8(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud16(value: u16) PolynomialFormat(.{
    .bits = 16,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud32(value: u32) PolynomialFormat(.{
    .bits = 32,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud64(value: u64) PolynomialFormat(.{
    .bits = 64,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ud128(value: u128) PolynomialFormat(.{
    .bits = 128,
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub inline fn ux8(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn esc(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "\\x",
}) {
    return .{ .value = value };
}
pub inline fn ux16(value: u16) PolynomialFormat(.{
    .bits = 16,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux32(value: u32) PolynomialFormat(.{
    .bits = 32,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux64(value: u64) PolynomialFormat(.{
    .bits = 64,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn ux128(value: u128) PolynomialFormat(.{
    .bits = 128,
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub inline fn uz8(value: u8) PolynomialFormat(.{
    .bits = 8,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz16(value: u16) PolynomialFormat(.{
    .bits = 16,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz32(value: u32) PolynomialFormat(.{
    .bits = 32,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz64(value: u64) PolynomialFormat(.{
    .bits = 64,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub inline fn uz128(value: u128) PolynomialFormat(.{
    .bits = 128,
    .radix = 36,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0z",
}) {
    return .{ .value = value };
}
pub fn ubsize(value: usize) PolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 2,
    .signedness = .unsigned,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub fn uosize(value: usize) PolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 8,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0o",
}) {
    return .{ .value = value };
}
pub fn udsize(value: usize) PolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 10,
    .signedness = .unsigned,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn uxsize(value: usize) PolynomialFormat(.{
    .bits = @bitSizeOf(usize),
    .radix = 16,
    .signedness = .unsigned,
    .width = .min,
    .prefix = "0x",
}) {
    return .{ .value = value };
}
pub fn ibsize(value: isize) PolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 2,
    .signedness = .signed,
    .width = .max,
    .prefix = "0b",
}) {
    return .{ .value = value };
}
pub fn iosize(value: isize) PolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 8,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn idsize(value: isize) PolynomialFormat(.{
    .bits = @bitSizeOf(isize),
    .radix = 10,
    .signedness = .signed,
    .width = .min,
}) {
    return .{ .value = value };
}
pub fn ixsize(value: isize) PolynomialFormat(.{
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
pub fn sourceLocation(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
    return SourceLocationFormat.init(value, ret_addr);
}
pub fn yr(year: u64) PolynomialFormat(.{
    .bits = 64,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 0, .max = 9999 },
}) {
    return .{ .value = year };
}
pub fn mon(month: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 12 },
}) {
    return .{ .value = month };
}
pub fn mday(month_day: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 1, .max = 31 },
}) {
    return .{ .value = month_day };
}
pub fn yday(year_day: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 4 },
    .range = .{ .min = 1, .max = 366 },
}) {
    return .{ .value = year_day };
}
pub fn hr(hour: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 23 },
}) {
    return .{ .value = hour };
}
pub fn min(minute: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
}) {
    return .{ .value = minute };
}
pub fn sec(second: u8) PolynomialFormat(.{
    .bits = 8,
    .signedness = .unsigned,
    .radix = 10,
    .width = .{ .fixed = 2 },
    .range = .{ .min = 0, .max = 59 },
}) {
    return .{ .value = second };
}
/// Constructs DateTime formatter
pub fn dt(value: time.DateTime) DateTimeFormat(time.DateTime) {
    return .{ .value = value };
}
/// Constructs packed DateTime formatter
pub fn pdt(value: time.PackedDateTime) DateTimeFormat(time.PackedDateTime) {
    return .{ .value = value };
}
pub fn nsec(value: u64) PolynomialFormat(.{
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
pub fn ubd(old: anytype, new: anytype) blk: {
    const T: type = if (@TypeOf(old) == comptime_int) u128 else @TypeOf(old);
    const U: type = if (@TypeOf(new) == comptime_int) u128 else @TypeOf(new);
    break :blk ChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 2));
} {
    return .{ .old_value = old, .new_value = new };
}
pub fn uod(old: anytype, new: anytype) blk: {
    const T: type = if (@TypeOf(old) == comptime_int) u128 else @TypeOf(old);
    const U: type = if (@TypeOf(new) == comptime_int) u128 else @TypeOf(new);
    break :blk ChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 8));
} {
    return .{ .old_value = old, .new_value = new };
}
pub fn udd(old: anytype, new: anytype) blk: {
    const T: type = if (@TypeOf(old) == comptime_int) u128 else @TypeOf(old);
    const U: type = if (@TypeOf(new) == comptime_int) u128 else @TypeOf(new);
    break :blk ChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 10));
} {
    return .{ .old_value = old, .new_value = new };
}
pub fn uxd(old: anytype, new: anytype) blk: {
    const T: type = if (@TypeOf(old) == comptime_int) u128 else @TypeOf(old);
    const U: type = if (@TypeOf(new) == comptime_int) u128 else @TypeOf(new);
    break :blk ChangedIntFormat(uniformChangedIntFormatSpec(@max(@bitSizeOf(T), @bitSizeOf(U)), .unsigned, 16));
} {
    return .{ .old_value = old, .new_value = new };
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
    pub const UDel = ChangedIntFormat(.{
        .old_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
        .new_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
        .del_fmt_spec = .{ .bits = 64, .signedness = .unsigned, .radix = 10, .width = .min },
    });
    pub const BytesDel = ChangedBytesFormat(.{});
};
