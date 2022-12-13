const lit = @import("./lit.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub fn ud(value: anytype) PolynomialFormat(.{
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
pub fn udh(value: anytype) PolynomialFormat(.{
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
pub fn ub(value: anytype) PolynomialFormat(.{
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
}) {
    return .{ .value = value };
}
pub fn ux(value: anytype) PolynomialFormat(.{
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
}) {
    return .{ .value = value };
}
pub fn ib8(value: i8) PolynomialFormat(.{ .bits = 8, .radix = 2, .signedness = .signed, .width = .max }) {
    return .{ .value = value };
}
pub fn ib16(value: i16) PolynomialFormat(.{ .bits = 16, .radix = 2, .signedness = .signed, .width = .max }) {
    return .{ .value = value };
}
pub fn ib32(value: i32) PolynomialFormat(.{ .bits = 32, .radix = 2, .signedness = .signed, .width = .max }) {
    return .{ .value = value };
}
pub fn ib64(value: i64) PolynomialFormat(.{ .bits = 64, .radix = 2, .signedness = .signed, .width = .max }) {
    return .{ .value = value };
}
pub fn ib128(value: i128) PolynomialFormat(.{ .bits = 128, .radix = 2, .signedness = .signed, .width = .max }) {
    return .{ .value = value };
}
pub fn io8(value: i8) PolynomialFormat(.{ .bits = 8, .radix = 8, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn io16(value: i16) PolynomialFormat(.{ .bits = 16, .radix = 8, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn io32(value: i32) PolynomialFormat(.{ .bits = 32, .radix = 8, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn io64(value: i64) PolynomialFormat(.{ .bits = 64, .radix = 8, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn io128(value: i128) PolynomialFormat(.{ .bits = 128, .radix = 8, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn id8(value: i8) PolynomialFormat(.{ .bits = 8, .radix = 10, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn id16(value: i16) PolynomialFormat(.{ .bits = 16, .radix = 10, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn id32(value: i32) PolynomialFormat(.{ .bits = 32, .radix = 10, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn id64(value: i64) PolynomialFormat(.{ .bits = 64, .radix = 10, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn id128(value: i128) PolynomialFormat(.{ .bits = 128, .radix = 10, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ix8(value: i8) PolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ix16(value: i16) PolynomialFormat(.{ .bits = 16, .radix = 16, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ix32(value: i32) PolynomialFormat(.{ .bits = 32, .radix = 16, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ix64(value: i64) PolynomialFormat(.{ .bits = 64, .radix = 16, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ix128(value: i128) PolynomialFormat(.{ .bits = 128, .radix = 16, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn iz8(value: i8) PolynomialFormat(.{ .bits = 8, .radix = 36, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn iz16(value: i16) PolynomialFormat(.{ .bits = 16, .radix = 36, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn iz32(value: i32) PolynomialFormat(.{ .bits = 32, .radix = 36, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn iz64(value: i64) PolynomialFormat(.{ .bits = 64, .radix = 36, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn iz128(value: i128) PolynomialFormat(.{ .bits = 128, .radix = 36, .signedness = .signed, .width = .min }) {
    return .{ .value = value };
}
pub fn ub8(value: u8) PolynomialFormat(.{ .bits = 8, .radix = 2, .signedness = .unsigned, .width = .max }) {
    return .{ .value = value };
}
pub fn ub16(value: u16) PolynomialFormat(.{ .bits = 16, .radix = 2, .signedness = .unsigned, .width = .max }) {
    return .{ .value = value };
}
pub fn ub32(value: u32) PolynomialFormat(.{ .bits = 32, .radix = 2, .signedness = .unsigned, .width = .max }) {
    return .{ .value = value };
}
pub fn ub64(value: u64) PolynomialFormat(.{ .bits = 64, .radix = 2, .signedness = .unsigned, .width = .max }) {
    return .{ .value = value };
}
pub fn uo8(value: u8) PolynomialFormat(.{ .bits = 8, .radix = 8, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uo16(value: u16) PolynomialFormat(.{ .bits = 16, .radix = 8, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uo32(value: u32) PolynomialFormat(.{ .bits = 32, .radix = 8, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uo64(value: u64) PolynomialFormat(.{ .bits = 64, .radix = 8, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uo128(value: u128) PolynomialFormat(.{ .bits = 128, .radix = 8, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ud8(value: u8) PolynomialFormat(.{ .bits = 8, .radix = 10, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ud16(value: u16) PolynomialFormat(.{ .bits = 16, .radix = 10, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ud32(value: u32) PolynomialFormat(.{ .bits = 32, .radix = 10, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ud64(value: u64) PolynomialFormat(.{ .bits = 64, .radix = 10, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ud128(value: u128) PolynomialFormat(.{ .bits = 8, .radix = 10, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ux8(value: u8) PolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ux16(value: u16) PolynomialFormat(.{ .bits = 16, .radix = 16, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ux32(value: u32) PolynomialFormat(.{ .bits = 32, .radix = 16, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ux64(value: u64) PolynomialFormat(.{ .bits = 64, .radix = 16, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn ux128(value: u128) PolynomialFormat(.{ .bits = 8, .radix = 16, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uz8(value: u8) PolynomialFormat(.{ .bits = 8, .radix = 36, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uz16(value: u16) PolynomialFormat(.{ .bits = 16, .radix = 36, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uz32(value: u32) PolynomialFormat(.{ .bits = 32, .radix = 36, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uz64(value: u64) PolynomialFormat(.{ .bits = 64, .radix = 36, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn uz128(value: u128) PolynomialFormat(.{ .bits = 128, .radix = 36, .signedness = .unsigned, .width = .min }) {
    return .{ .value = value };
}
pub fn bytes(count: usize) Bytes {
    return Bytes.init(count);
}
pub fn src(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
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

fn GenericFormat(comptime Format: type) type {
    return struct {
        const StaticString = mem.StaticString(Format.max_len);
        pub fn formatConvert(format: Format) StaticString {
            var array: StaticString = .{};
            array.writeFormat(format);
            return array;
        }
        fn checkLen(len: u64) u64 {
            if (@hasDecl(Format, "max_len") and len != Format.max_len) {
                @panic("formatter max length exceeded");
            }
            return len;
        }
    };
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
    prefix: bool = true,
    separator: ?Separator = null,
};
pub fn PolynomialFormat(comptime spec: PolynomialFormatSpec) type {
    return struct {
        value: Int,
        const Format = @This();
        const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        const fmt_spec: PolynomialFormatSpec = spec;
        const min_abs_value: Abs = fmt_spec.range.min orelse 0;
        const max_abs_value: Abs = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: u16 = builtin.fmt.length(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: u16 = builtin.fmt.length(Abs, max_abs_value, fmt_spec.radix);
        const prefix: [2]u8 = lit.int_prefixes[fmt_spec.radix].*;
        const max_len: u64 = blk: {
            var len: u64 = max_digits_count;
            if (fmt_spec.radix != 10) {
                len += prefix.len;
            }
            if (fmt_spec.signedness == .signed) {
                len += 1;
            }
            if (fmt_spec.separator) |s| {
                len += (len - 1) / s.digits;
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
            const digits_len: u64 = switch (fmt_spec.width) {
                .min => builtin.fmt.length(Abs, format.absolute(), fmt_spec.radix),
                .max => max_digits_count,
                .fixed => |fixed| fixed,
            };
            if (fmt_spec.separator) |s| {
                return digits_len + (digits_len - 1) / s.digits;
            } else {
                return digits_len;
            }
        }
        pub fn formatWrite(format: Format, array: anytype) void {
            const start: u64 = array.impl.next();
            var next: u64 = start;
            if (Abs != Int) {
                @intToPtr(*u8, next).* = '-';
            }
            next += @boolToInt(format.value < 0);
            if (fmt_spec.radix != 10) {
                @intToPtr(*[prefix.len]u8, next).* = prefix;
                next += prefix.len;
            }
            if (format.value == 0) {
                @intToPtr(*u8, next).* = '0';
            }
            if (fmt_spec.separator) |separator| {
                const count: u64 = format.digits();
                var value: Abs = format.absolute();
                next += count;
                var len: u64 = 0;
                var sep: u64 = 0;
                while (sep + len != count) : (value /= fmt_spec.radix) {
                    len +%= 1;
                    @intToPtr(*u8, next - (sep + len)).* = separator.character;
                    const b0: bool = len / separator.digits != 0;
                    const b1: bool = len % separator.digits == 1;
                    sep += builtin.int2a(u64, b0, b1);
                    @intToPtr(*u8, next - (sep + len)).* =
                        builtin.fmt.toSymbol(Abs, value, fmt_spec.radix);
                }
            } else {
                const count: u64 = format.digits();
                var value: Abs = format.absolute();
                next += count;
                var len: u64 = 0;
                while (len != count) : (value /= fmt_spec.radix) {
                    len +%= 1;
                    @intToPtr(*u8, next - len).* =
                        builtin.fmt.toSymbol(Abs, value, fmt_spec.radix);
                }
            }
            array.impl.define(next - start);
        }
        pub fn formatLength(format: Format) u64 {
            var len: u64 = 0;
            if (fmt_spec.radix != 10) {
                len += prefix.len;
            }
            if (format.value < 0) {
                len += 1;
            }
            return len + format.digits();
        }
        pub usingnamespace GenericFormat(Format);
    };
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
    const Format = @This();
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
    });
    var cwd_pathname: ?mem.StaticString(4096) = null;

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
        array.writeCount(2, ": ".*);
        array.writeMany(lit.fx.none ++ lit.fx.style.faint);
        array.writeFormat(ret_addr_fmt);
        array.writeCount(4, " in ".*);
        array.writeMany(fn_name);
        array.writeMany(lit.fx.none);
        array.writeOne('\n');
    }
    fn functionName(format: SourceLocationFormat) []const u8 {
        const begin: u64 = blk: {
            var i: u64 = 0;
            var j: u64 = 0;
            while (i != format.value.fn_name.len) : (i += 1) {
                if (format.value.fn_name[i] == '.') j = i;
            }
            break :blk if (j != 0) j + 1 else 0;
        };
        return format.value.fn_name[begin.. :0];
    }
    pub fn formatLength(format: SourceLocationFormat) u64 {
        const fn_name: []const u8 = format.functionName();
        const file_name: []const u8 = format.value.file;
        const line_fmt: LineColFormat = .{ .value = format.value.line };
        const column_fmt: LineColFormat = .{ .value = format.value.column };
        const ret_addr_fmt: AddrFormat = .{ .value = format.return_address };
        var len: u64 = 0;
        len += lit.fx.style.bold.len;
        len += file_name.len;
        len += 1;
        len += line_fmt.formatLength();
        len += 1;
        len += column_fmt.formatLength();
        len += 2;
        len += lit.fx.none.len + lit.fx.style.faint.len;
        len += ret_addr_fmt.formatLength();
        len += 4;
        len += fn_name.len;
        len += lit.fx.none.len;
        len += 1;
        return len;
    }
    pub fn init(value: builtin.SourceLocation, ret_addr: ?u64) SourceLocationFormat {
        return .{ .value = value, .return_address = @intCast(u32, ret_addr orelse @returnAddress()) };
    }
};
pub const Bytes = struct {
    value: Value,
    const Format = @This();
    const Value = struct {
        integer: mem.Bytes,
        remainder: mem.Bytes,
    };
    const Unit = mem.Bytes.Unit;
    const MajorIntFormat = PolynomialFormat(.{
        .bits = 10,
        .signedness = .unsigned,
        .radix = 10,
        .width = .min,
    });
    const MinorIntFormat = PolynomialFormat(.{
        .bits = 10,
        .signedness = .unsigned,
        .radix = 10,
        .width = .{ .fixed = 3 },
    });
    const fields: []const builtin.EnumField = @typeInfo(Unit).Enum.fields;
    pub const max_len: u64 =
        MajorIntFormat.max_len +
        MinorIntFormat.max_len + 3; // Unit
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
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.value.remainder.count != 0) {
            len += format.formatInteger().formatLength();
            len += 1;
            len += format.formatRemainder().formatLength();
            len += @tagName(format.value.integer.unit).len;
        } else {
            len += format.formatInteger().formatLength();
            len += @tagName(format.value.integer.unit).len;
        }
        return len;
    }
    pub fn init(value: u64) Bytes {
        inline for (fields) |field, i| {
            const integer: mem.Bytes = mem.Bytes.Unit.to(value, @field(mem.Bytes.Unit, field.name));
            if (integer.count != 0) {
                const remainder: mem.Bytes = blk: {
                    const j: u64 = if (i != fields.len - 1) i + 1 else i;
                    break :blk Unit.to(value -| mem.Bytes.bytes(integer), @field(Unit, fields[j].name));
                };
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

fn indexOfFirst(comptime T: type, comptime value: T, values: []const T) ?u64 {
    var idx: u64 = 0;
    while (idx != values.len) : (idx += 1) {
        if (values[idx] == value) return idx;
    }
    return null;
}
fn indexOfLast(comptime T: type, comptime value: T, values: []const T) ?u64 {
    var idx: u64 = values.len;
    while (idx != 0) {
        idx -= 1;
        if (values[idx] == value) return idx;
    }
    return null;
}

pub fn shortTypeName(comptime T: type) [:0]const u8 {
    comptime {
        const type_name: [:0]const u8 = @typeName(T);
        if (indexOfFirst(u8, '.', type_name)) |first_dot| {
            if (indexOfFirst(u8, '(', type_name)) |first_parens| {
                if (indexOfLast(u8, '.', type_name[0..first_parens])) |last_dot| {
                    if (last_dot != first_dot) {
                        return type_name[0..first_dot] ++ "." ++ type_name[last_dot..first_parens] ++ "(..)";
                    }
                }
            }
        } else if (indexOfFirst(u8, '(', type_name)) |first_parens| {
            return type_name[0..first_parens] ++ "(..)";
        }
        return type_name;
    }
}
