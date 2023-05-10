//! Before the value renderer can be used this import is a place for all
//! miscellaneous testing functions which will not be used in the long term.
//! Still more infrastructure is needed.

const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const lit = @import("./lit.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const spec = @import("./spec.zig");
const algo = @import("./algo.zig");
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
    for ("{ ", 0..) |c, i| buf[len + i] = c;
    len += 2;
    for (s, 0..) |c, i| {
        if (c == 0) {
            for ("0x0", 0..) |b, j| buf[len + j] = b;
            len += 3;
        } else {
            for ([_]u8{ '\'', c, '\'' }, 0..) |b, j| buf[len + j] = b;
            len += 3;
        }
        if (i != s.len - 1) {
            for (", ", 0..) |b, j| buf[len + j] = b;
            len += 2;
        }
    }
    for (" }\n", 0..) |c, i| buf[len + i] = c;
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
    builtin.debug.write(buf[0..len]);
    builtin.debug.write(arg1);
    builtin.debug.write("\n");
    builtin.debug.write(arg2);
    builtin.debug.write("\n");
}

// Q: Why not put this in builtin, according to specification?
// A: Because without a low level value renderer it can only serve special
// cases. fault-error-test requires the former two variants render the error
// value. That is not yet possible.
pub fn expectEqualMany(comptime T: type, arg1: []const T, arg2: []const T) builtin.Error!void {
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
pub fn arbitraryFieldOrder(comptime T: type) void {
    const s = struct {
        fn ascName(comptime x: builtin.Type.StructField, comptime y: builtin.Type.StructField) bool {
            const min = @min(x.name.len, y.name.len);
            for (x.name[0..min], y.name[0..min]) |xx, yy| {
                if (xx > yy) return true;
                if (yy > xx) return false;
            }
        }
        fn ascSize(comptime x: builtin.Type.StructField, comptime y: builtin.Type.StructField) bool {
            return algo.asc(@bitSizeOf(x.type), @bitSizeOf(y.type));
        }
    };
    const fields: []const builtin.Type.StructField = @typeInfo(T).Struct.fields;
    var values: [fields.len]builtin.Type.StructField =
        @ptrCast(*const [fields.len]builtin.Type.StructField, fields.ptr).*;
    algo.shellSort(builtin.Type.StructField, s.ascName, builtin.identity, &values);
    algo.shellSort(builtin.Type.StructField, s.ascSize, builtin.identity, &values);
    for (values, 0..) |field, index| {
        if (!mem.testEqualMany(u8, field.name, fields[index].name)) {
            @compileError("bad name: expected " ++ field.name ++ ", found " ++ fields[index].name);
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
    builtin.debug.write(array.readAll());
    return array.readAll().len;
}
const reinterpret_spec: mem.ReinterpretSpec = builtin.define("reinterpret_spec", mem.ReinterpretSpec, blk: {
    var tmp: mem.ReinterpretSpec = spec.reinterpret.fmt;
    tmp.integral = .{ .format = .dec };
    break :blk tmp;
});
pub fn printN(comptime n: usize, any: anytype) void {
    var array: mem.StaticString(n) = undefined;
    array.undefineAll();
    array.writeAny(reinterpret_spec, any);
    builtin.debug.write(array.readAll());
}
const Static = struct {
    const Allocator = mem.GenericArenaAllocator(.{
        .arena_index = 48,
        .errors = spec.allocator.errors.noexcept,
        .logging = spec.allocator.logging.silent,
        .AddressSpace = spec.address_space.regular_128,
    });
    const Array = Allocator.StructuredVector(u8);
    var address_space: Allocator.allocator_spec.AddressSpace = .{};
    var allocator: ?Allocator = null;
    var array: ?Array = null;
};
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
        Static.array = Static.Array.init(allocator, 1024 * 4096);
        break :blk &Static.array.?;
    };
    array.undefineAll();
    array.writeAny(reinterpret_spec, any);
    builtin.debug.write(array.readAll());
}
pub fn uniqueSet(comptime T: type, set: []const T) void {
    var l_index: usize = 0;
    while (l_index != set.len) : (l_index +%= 1) {
        var r_index: usize = l_index;
        while (r_index != set.len) : (r_index +%= 1) {
            if (l_index != r_index) {
                if (builtin.testEqual(T, set[l_index], set[r_index])) {
                    printN(4096, .{
                        "non-unique: ", l_index,
                        " == ",         r_index,
                        '\n',           set[l_index],
                        " == ",         set[r_index],
                        '\n',
                    });
                }
            }
        }
    }
}
const black_list: []const []const u8 = &.{
    "panicUnwrapError",
};
pub fn refAllDecls(comptime T: type) void {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime {
        if (@typeInfo(T) == .Struct or
            @typeInfo(T) == .Union or
            @typeInfo(T) == .Enum or
            @typeInfo(T) == .Opaque)
        {
            lo: inline for (meta.resolve(@typeInfo(T)).decls) |decl| {
                for (black_list) |name| {
                    if (builtin.testEqualMemory([]const u8, decl.name, name)) {
                        continue :lo;
                    }
                }
                if (@hasDecl(T, decl.name)) {
                    if (@TypeOf(@field(T, decl.name)) == type) {
                        refAllDecls(@field(T, decl.name));
                    }
                }
            }
        }
    }
}
