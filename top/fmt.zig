const lit = @import("./lit.zig");
const mem = @import("./mem.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

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
    signedness: meta.Signedness,
    radix: comptime_int,
    width: Width,
    range: Range = .{},
    prefix: bool = true,
    separator: ?Separator = null,
};
fn length(comptime U: type, abs_value: U, radix: U) u64 {
    var value: U = abs_value;
    var count: u64 = 0;
    while (value != 0) : (value /= radix) {
        count +%= 1;
    }
    return @max(1, count);
}
pub fn PolynomialFormat(comptime spec: PolynomialFormatSpec) type {
    return struct {
        value: Int,
        const Format = @This();
        const Int: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = fmt_spec.signedness } });
        const Abs: type = @Type(.{ .Int = .{ .bits = fmt_spec.bits, .signedness = .unsigned } });
        const fmt_spec: PolynomialFormatSpec = spec;
        const min_abs_value: Abs = fmt_spec.range.min orelse 0;
        const max_abs_value: Abs = fmt_spec.range.max orelse ~@as(Abs, 0);
        const min_digits_count: u16 = length(Abs, min_abs_value, fmt_spec.radix);
        const max_digits_count: u16 = length(Abs, max_abs_value, fmt_spec.radix);
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
                .min => length(Abs, format.absolute(), fmt_spec.radix),
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
