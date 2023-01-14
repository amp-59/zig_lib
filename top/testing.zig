//! Before the value renderer can be used this import is a place for all
//! miscellaneous testing functions which will not be used in the long term.
//! Still more infrastructure is needed.

const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

fn arrayOfCharsLength(s: []const u8) u64 {
    var len: u64 = 0;
    len += 2;
    for (s) |i| {
        len += 3;
        if (i != s.len - 1) {
            len += 2;
        }
    }
    return len + 3;
}
fn arrayOfCharsWrite(buf: []u8, s: []const u8) u64 {
    var len: u64 = 0;
    for ("{ ") |c, i| buf[len + i] = c;
    len += 2;
    for (s) |c, i| {
        if (c == 0) {
            for ("0x0") |b, j| buf[len + j] = b;
            len += 3;
        } else {
            for ([_]u8{ '\'', c, '\'' }) |b, j| buf[len + j] = b;
            len += 3;
        }
        if (i != s.len - 1) {
            for (", ") |b, j| buf[len + j] = b;
            len += 2;
        }
    }
    for (" }\n") |c, i| buf[len + i] = c;
    return len + 3;
}
pub fn showSpecialCase(comptime T: type, arg1: []const T, arg2: []const T) void {
    const arg1_xray_len: u64 = arrayOfCharsLength(arg1);
    const arg2_xray_len: u64 = arrayOfCharsLength(arg2);
    if (arg1_xray_len + arg2_xray_len > 4096) {
        return;
    }
    var buf: [4096]u8 = undefined;
    var len: u64 = 0;
    len += arrayOfCharsWrite(buf[len..], arg1);
    len += arrayOfCharsWrite(buf[len..], arg2);
    file.noexcept.write(2, buf[0..len]);
    file.noexcept.write(2, arg1);
    file.noexcept.write(2, "\n");
    file.noexcept.write(2, arg2);
    file.noexcept.write(2, "\n");
}

// Q: Why not put this in builtin, according to specification?
// A: Because without a low level value renderer it can only serve special
// cases. fault-error-test requires the former two variants render the error
// value. That is not yet possible.
pub fn expectEqualMany(comptime T: type, arg1: []const T, arg2: []const T) builtin.Exception!void {
    if (arg1.len != arg2.len) {
        if (T == u8) {
            showSpecialCase(T, arg1, arg2);
        }
        return error.UnexpectedValue;
    }
    var i: u64 = 0;
    while (i != arg1.len) : (i += 1) {
        if (arg1[i] != arg2[i]) {
            if (T == u8) {
                showSpecialCase(T, arg1, arg2);
            }
            return error.UnexpectedValue;
        }
    }
}

fn writeDepth(array: *mem.StaticString(1048576), depth: u64) void {
    var i: u64 = 0;
    while (i != depth) : (i += 1) {
        array.writeMany(tab_s);
    }
}
fn depthLength(depth: u64) u64 {
    return depth * tab_s.len;
}
const tab_s: []const u8 = "    ";
fn sizeBreakDownLengthInternal(comptime T: type, depth: u64) u64 {
    var len: u64 = 0;
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Struct or type_info == .Union) {
        if (@sizeOf(T) != 0) {
            if (type_info == .Struct) {
                len += ("struct {\t// sub total: ").len;
            } else {
                len += ("union {\t// sub total: ").len;
            }
            len += fmt.ud64(@sizeOf(T)).formatLength();
            len += ("\n").len;
            inline for (@field(type_info, @tagName(type_info)).fields) |field| {
                len += depthLength(depth);
                if (type_info == .Struct and field.is_comptime) {
                    len += ("comptime " ++ field.name ++ ": ").len;
                    len += (@typeName(field.type) ++ ",\t// 0 bytes\n").len;
                } else {
                    len += (field.name ++ ": ").len;
                    len += sizeBreakDownLengthInternal(field.type, depth + 1);
                }
            }
            len += depthLength(depth - 1);
            len += ("},\n").len;
        } else {
            len += ("struct {},\t// 0 bytes\n").len;
        }
    } else {
        len += (@typeName(T) ++ ",\t// ").len;
        len += fmt.ud64(@sizeOf(T)).formatLength();
        len += (" bytes\n").len;
    }
    return len;
}
fn sizeBreakDownLength(comptime T: type, type_rename: ?[:0]const u8) u64 {
    const depth: u64 = 1;
    var len: u64 = 0;
    const type_info: builtin.Type = @typeInfo(T);
    len += ("const ").len;
    len += (type_rename orelse fmt.typeName(T)).len;
    if (type_info == .Struct or type_info == .Union) {
        if (@sizeOf(T) != 0) {
            if (type_info == .Struct) {
                len += ("struct {\t// total: ").len;
            } else {
                len += ("union {\t// total: ").len;
            }
            len += fmt.ud64(@sizeOf(T)).formatLength();
            len += ("\n").len;
            inline for (@field(type_info, @tagName(type_info)).fields) |field| {
                len += depthLength(depth);
                if (type_info == .Struct and field.is_comptime) {
                    len += ("comptime " ++ field.name ++ ": ").len;
                    len += (@typeName(field.type) ++ ",\t// 0 bytes\n").len;
                } else {
                    len += (field.name ++ ": ").len;
                    len += sizeBreakDownLengthInternal(field.type, depth + 1);
                }
            }
            len += ("};").len;
        } else {
            len += ("\t0,\n").len;
        }
    } else {
        len += 1;
        len += fmt.ud64(@sizeOf(T)).formatLength();
        len += 1;
    }
    len += 1;
    return len;
}
fn sizeBreakDownInternal(comptime T: type, array: *mem.StaticString(1048576), depth: u64) void {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Struct or type_info == .Union) {
        if (@sizeOf(T) != 0) {
            if (type_info == .Struct) {
                array.writeMany("struct {\t// sub total: ");
            } else {
                array.writeMany("union {\t// sub total: ");
            }
            array.writeFormat(fmt.ud64(@sizeOf(T)));
            array.writeMany("\n");
            inline for (@field(type_info, @tagName(type_info)).fields) |field| {
                writeDepth(array, depth);
                if (type_info == .Struct and field.is_comptime) {
                    array.writeMany("comptime " ++ field.name ++ ": ");
                    array.writeMany(@typeName(field.type) ++ ",\t// 0 bytes\n");
                } else {
                    array.writeMany(field.name ++ ": ");
                    sizeBreakDownInternal(field.type, array, depth + 1);
                }
            }
            writeDepth(array, depth - 1);
            array.writeMany("},\n");
        } else {
            array.writeMany("struct {},\t// 0 bytes\n");
        }
    } else {
        array.writeMany(@typeName(T) ++ ",\t// ");
        array.writeFormat(fmt.ud64(@sizeOf(T)));
        array.writeMany(" bytes\n");
    }
}
pub fn printSizeBreakDown(comptime T: type, type_rename: ?[:0]const u8) u64 {
    const depth: u64 = 1;
    const type_info: builtin.Type = @typeInfo(T);
    var array: mem.StaticString(1048576) = .{};
    array.writeMany("const ");
    array.writeMany(type_rename orelse fmt.typeName(T));
    if (type_info == .Struct or type_info == .Union) {
        if (@sizeOf(T) != 0) {
            if (type_info == .Struct) {
                array.writeMany("struct {\t// total: ");
            } else {
                array.writeMany("union {\t// total: ");
            }
            array.writeFormat(fmt.ud64(@sizeOf(T)));
            array.writeMany("\n");
            inline for (@field(type_info, @tagName(type_info)).fields) |field| {
                writeDepth(&array, depth);
                if (type_info == .Struct and field.is_comptime) {
                    array.writeMany("comptime " ++ field.name ++ ": ");
                    array.writeMany(@typeName(field.type) ++ ",\t// 0 bytes\n");
                } else {
                    array.writeMany(field.name ++ ": ");
                    sizeBreakDownInternal(field.type, &array, depth + 1);
                }
            }
            array.writeMany("};");
        } else {
            array.writeMany("\t0,\n");
        }
    } else {
        array.writeOne('\t');
        array.writeFormat(fmt.ud64(@sizeOf(T)));
        array.writeOne('\n');
    }
    array.writeOne('\n');
    file.noexcept.write(2, array.readAll());
    return array.readAll().len;
}
const Static = struct {
    const Allocator = mem.GenericArenaAllocator(.{
        .arena_index = 64,
        .errors = preset.allocator.errors.noexcept,
    });
    const Array = Allocator.StructuredVector(u8);
    var address_space: Allocator.allocator_spec.AddressSpace = .{};
    var allocator: ?Allocator = null;
    var array: ?Array = null;
};

pub fn printN(comptime n: usize, any: anytype) void {
    var array: mem.StaticString(n) = undefined;
    array.undefineAll();
    array.writeAny(preset.reinterpret.fmt, any);
    file.noexcept.write(2, array.readAll());
}

pub fn print(any: anytype) void {
    const allocator: *Static.Allocator = blk: {
        if (Static.allocator) |*allocator| {
            break :blk allocator;
        }
        Static.allocator = Static.Allocator.init(&Static.address_space) catch {
            return;
        };
        break :blk &Static.allocator.?;
    };
    const array: *Static.Array = blk: {
        if (Static.array) |*array| {
            break :blk array;
        }
        Static.array = Static.Array.init(allocator, 1024 * 4096) catch {
            return;
        };
        break :blk &Static.array.?;
    };
    defer array.undefineAll();
    array.writeAny(preset.reinterpret.fmt, any);
    file.noexcept.write(2, array.readAll());
}
