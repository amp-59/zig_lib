const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");

fn maxAlignment(comptime T: type, comptime in: comptime_int) comptime_int {
    switch (@typeInfo(T)) {
        inline .Struct, .Union => |info| {
            var max: comptime_int = @max(in, @alignOf(T));
            inline for (info.fields) |field| {
                max = @max(max, maxAlignment(field.type, max));
            }
            return max;
        },
        .Pointer => |pointer_info| {
            return maxAlignment(pointer_info.child, @max(in, @alignOf(T)));
        },
        else => return @max(in, @alignOf(T)),
    }
}
fn length3(comptime T: type, sss: []const []const []const T) u64 {
    var ret: u64 = 16 +% (sss.len *% 16);
    for (sss) |ss| {
        ret +%= ss.len *% @sizeOf(T);
        for (ss) |values| {
            ret +%= values.len *% @sizeOf(T);
        }
    }
    return ret;
}
fn length2(comptime T: type, ss: []const []const T) u64 {
    var ret: u64 = 16 +% (ss.len *% 16);
    for (ss) |values| {
        ret +%= values.len *% @sizeOf(T);
    }
    return ret;
}
fn length1(comptime T: type, s: []const T) u64 {
    return 16 +% (s.len *% @sizeOf(T));
}
fn serialize1Internal(comptime T: type, allocator: anytype, s: []const T) ![]u8 {
    allocator.alignAbove(maxAlignment(@TypeOf(s), @alignOf(T)));
    const UVector = @TypeOf(allocator.*).UnstructuredVector(1, 1);
    var array: UVector = UVector.init(allocator, length1(T, s));
    array.writeOne(u64, 0);
    array.writeOne(u64, s.len);
    for (s) |value| {
        array.writeOne(T, value);
    }
    return array.referAllDefined(u8);
}
inline fn serialize2Internal(comptime T: type, allocator: anytype, ss: []const []const T) ![]u8 {
    const UVector = @TypeOf(allocator.*).UnstructuredVector(@sizeOf(T), @alignOf(T));
    var array: UVector = UVector.init(allocator, 16);
    try meta.wrap(array.appendOne(u64, allocator, 0));
    try meta.wrap(array.appendOne(u64, allocator, ss.len));
    for (ss) |values| {
        try meta.wrap(array.appendOne(u64, allocator, 0));
        try meta.wrap(array.appendOne(u64, allocator, values.len));
    }
    for (ss) |values| {
        for (values) |value| {
            try meta.wrap(array.appendOne(T, allocator, value));
        }
    }
    return array.referAllDefined(u8);
}
inline fn serialize3Internal(comptime T: type, allocator: anytype, sss: []const []const []const T) ![]u8 {
    const UVector = @TypeOf(allocator.*).UnstructuredVector(@sizeOf(T), @alignOf(T));
    var array: UVector = try meta.wrap(UVector.init(allocator, 16));
    try meta.wrap(array.appendOne(u64, allocator, 0));
    try meta.wrap(array.appendOne(u64, allocator, sss.len));
    for (sss) |ss| {
        try meta.wrap(array.appendOne(u64, allocator, 0));
        try meta.wrap(array.appendOne(u64, allocator, ss.len));
    }
    for (sss) |ss| {
        for (ss) |values| {
            try meta.wrap(array.appendOne(u64, allocator, 0));
            try meta.wrap(array.appendOne(u64, allocator, values.len));
        }
    }
    for (sss) |ss| {
        for (ss) |values| {
            for (values) |value| {
                try meta.wrap(array.appendOne(T, allocator, value));
            }
        }
    }
    return array.referAllDefined(u8);
}
inline fn deserialize3Internal(comptime T: type, addr: u64) [][][]T {
    const T1 = []T;
    const T2 = []T1;
    const T3 = []T2;
    const l0: *T3 = mem.pointerOne(T3, addr);
    l0.* = mem.pointerMany(T2, addr + @sizeOf(T3), l0.len);
    const offset_0: u64 = @sizeOf(T3);
    const offset_1: u64 = offset_0 +% (l0.len *% @sizeOf(T2));
    var offset_2: u64 = offset_1;
    for (l0.*) |*l1| {
        l1.* = mem.pointerMany(T1, addr +% offset_2, l1.len);
        offset_2 +%= l1.len *% @sizeOf(T1);
    }
    var offset_3: u64 = offset_2;
    offset_2 = offset_1;
    for (l0.*) |l1| {
        for (l1) |*l2| {
            l2.* = mem.pointerMany(T, addr +% offset_3, l2.len);
            offset_3 +%= l2.len *% @sizeOf(T);
        }
        offset_2 +%= l1.len *% @sizeOf(T1);
    }
    return l0.*;
}
inline fn deserialize2Internal(comptime T: type, addr: u64) [][]T {
    const T1 = []T;
    const T2 = []T1;
    const l0: *T2 = mem.pointerOne(T2, addr);
    l0.* = mem.pointerMany(T1, addr +% @sizeOf(T2), l0.len);
    const offset_0: u64 = @sizeOf(T2);
    const offset_1: u64 = offset_0 +% (l0.len *% @sizeOf(T1));
    var offset_2: u64 = offset_1;
    for (l0.*) |*l1| {
        l1.* = mem.pointerMany(T, addr +% offset_2, l1.len);
        offset_2 +%= l1.len * @sizeOf(T);
    }
    return l0.*;
}
inline fn deserialize1Internal(comptime T: type, addr: u64) []T {
    const T1 = []T;
    const l0: *T1 = mem.pointerOne(T1, addr);
    l0.* = mem.pointerMany(T, addr + @sizeOf(T1), l0.len);
    return l0.*;
}
inline fn serializeInternal(comptime T: type, allocator: anytype, pathname: [:0]const u8, comptime function: anytype, sets: anytype) !void {
    const save: @TypeOf(allocator.*).Save = allocator.save();
    defer allocator.restore(save);
    const bytes: []const u8 = try meta.wrap(function(T, allocator, sets));
    const fd: u64 = try file.create(.{ .options = .{ .exclusive = false, .read = false, .write = .truncate } }, pathname);
    defer file.close(.{ .errors = .{} }, fd);
    try file.write(.{}, fd, bytes);
}
inline fn deserializeInternal(comptime T: type, comptime S: type, allocator: anytype, pathname: [:0]const u8, comptime function: anytype) !S {
    const fd: u64 = try file.open(.{ .options = .{ .read = true, .write = null } }, pathname);
    defer file.close(.{ .errors = .{} }, fd);
    const st: file.Stat = try file.fstat(.{}, fd);
    const buf: []u8 = try meta.wrap(allocator.allocateIrreversible(u8, st.size));
    builtin.assertEqual(u64, st.size, try file.read(.{}, fd, buf, st.size));
    return try meta.wrap(function(T, @ptrToInt(buf.ptr)));
}
pub inline fn serialize3(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const []const []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize3Internal, sets);
}
pub inline fn serialize2(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize2Internal, sets);
}
pub inline fn serialize1(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize1Internal, sets);
}
pub inline fn deserialize3(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![][][]T {
    return deserializeInternal(T, [][][]T, allocator, pathname, deserialize3Internal);
}
pub inline fn deserialize2(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![][]T {
    return deserializeInternal(T, [][]T, allocator, pathname, deserialize2Internal);
}
pub inline fn deserialize1(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![]T {
    return deserializeInternal(T, []T, allocator, pathname, deserialize1Internal);
}
