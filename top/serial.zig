const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub fn maxAlignment(comptime types: []const type) comptime_int {
    const T = types[types.len - 1];
    switch (@typeInfo(T)) {
        .Struct => |struct_info| {
            var ret: usize = @alignOf(T);
            lo: for (struct_info.fields) |field| {
                for (types[0 .. types.len - 1]) |unique| {
                    if (field.type == unique) continue :lo;
                }
                ret = @max(ret, maxAlignment(types ++ .{field.type}));
            }
            return ret;
        },
        .Union => |union_info| {
            var ret: usize = @alignOf(T);
            lo: for (union_info.fields) |field| {
                for (types[0 .. types.len - 1]) |unique| {
                    if (field.type == unique) continue :lo;
                }
                ret = @max(ret, maxAlignment(types ++ .{field.type}));
            }
            return ret;
        },
        .Pointer => |pointer_info| {
            for (types[0 .. types.len - 1]) |unique| {
                if (pointer_info.child == unique) return @alignOf(T);
            }
            return @max(@alignOf(T), maxAlignment(types ++ .{pointer_info.child}));
        },
        else => return @alignOf(T),
    }
}
pub fn length(comptime T: type, any: anytype) u64 {
    const S = @TypeOf(any);
    if (T == S) {
        return @sizeOf(T);
    }
    var len: u64 = @sizeOf(S);
    for (any) |value| {
        len +%= length(T, value);
    }
    return len;
}
pub fn read(comptime T: type, addr: u64, offset: u64, any: *T) u64 {
    var len: u64 = offset;
    switch (@typeInfo(T)) {
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                len = read(field.type, addr, len, &@field(any, field.name));
            }
            return len;
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                inline for (union_info.fields) |field| {
                    if (any.* == @field(tag_type, field.name)) {
                        return read(field.type, addr, len, &@field(any, field.name));
                    }
                }
            }
            return len;
        },
        .Pointer => |pointer_info| {
            const next = toAddress(any.*, addr);
            defer any.* = next;
            if (pointer_info.size == .One) {
                len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
                len +%= @sizeOf(pointer_info.child);
                len = read(pointer_info.child, addr, len, next);
            }
            if (pointer_info.size == .Slice) {
                len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
                len +%= @sizeOf(pointer_info.child) *% (next.len +% @boolToInt(pointer_info.sentinel != null));
                for (next) |*value| {
                    len = read(pointer_info.child, addr, len, value);
                }
            }
            if (pointer_info.size == .Many) {
                const sentinel: pointer_info.child = comptime meta.sentinel(T).?;
                var idx: u64 = 0;
                while (next[idx] != sentinel) idx +%= 1;
                len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
                len +%= @sizeOf(pointer_info.child) *% (idx +% 1);
                for (next[0..idx]) |*value| {
                    len = read(pointer_info.child, addr, len, value);
                }
            }
            return len;
        },
        else => return len,
    }
}
fn addrAdd(ptr: anytype, offset: u64) @TypeOf(@constCast(ptr)) {
    switch (@typeInfo(@TypeOf(ptr)).Pointer.size) {
        .Slice => return @intToPtr(@TypeOf(@constCast(ptr.ptr)), @ptrToInt(ptr.ptr) +% offset)[0..ptr.len],
        .Many => return @intToPtr(@TypeOf(@constCast(ptr)), @ptrToInt(ptr.ptr) +% offset),
        else => return @intToPtr(@TypeOf(@constCast(ptr)), @ptrToInt(ptr) +% offset),
    }
}
fn addrSub(ptr: anytype, offset: u64) @TypeOf(ptr) {
    switch (@typeInfo(@TypeOf(ptr)).Pointer.size) {
        .Slice => return @intToPtr(@TypeOf(ptr.ptr), @ptrToInt(ptr.ptr) -% offset)[0..ptr.len],
        .Many => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr.ptr) -% offset),
        else => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) -% offset),
    }
}

fn toOffset(ptr: anytype, addr: u64) @TypeOf(@constCast(ptr)) {
    @setRuntimeSafety(false);
    return addrSub(ptr, addr);
}
fn toAddress(ptr: anytype, addr: u64) @TypeOf(@constCast(ptr)) {
    @setRuntimeSafety(false);
    return addrAdd(ptr, addr);
}

pub fn write(allocator: anytype, comptime T: type, addr: u64, any: T) @TypeOf(allocator.*).allocate_payload(T) {
    switch (@typeInfo(T)) {
        .Struct => |struct_info| {
            var ret: T = any;
            inline for (struct_info.fields) |field| {
                @field(ret, field.name) = try meta.wrap(write(allocator, field.type, addr, @field(any, field.name)));
            }
            return ret;
        },
        .Union => |union_info| {
            if (union_info.tag_type) |tag_type| {
                inline for (union_info.fields) |field| {
                    if (any == @field(tag_type, field.name)) {
                        return @unionInit(T, field.name, try meta.wrap(write(allocator, field.type, @field(any, field.name))));
                    }
                }
            }
            return any;
        },
        .Pointer => |pointer_info| {
            if (pointer_info.size == .Many) {
                return try meta.wrap(write(allocator, meta.ManyToSlice(T), meta.manyToSlice(any)));
            }
            if (pointer_info.size == .One) {
                var ret: *pointer_info.child = try meta.wrap(allocator.createIrreversible(pointer_info.child));
                ret.* = try meta.wrap(write(allocator, pointer_info.child, any.*));
                return ret;
            }
            if (pointer_info.size == .Slice) {
                const ret: meta.Var(T) = blk: {
                    if (comptime meta.sentinel(T)) |sentinel| {
                        break :blk try meta.wrap(allocator.allocateWithSentinelIrreversible(pointer_info.child, any.len, sentinel));
                    } else {
                        break :blk try meta.wrap(allocator.allocateIrreversible(pointer_info.child, any.len));
                    }
                };
                for (ret, 0..) |*ptr, i| {
                    ptr.* = try meta.wrap(write(allocator, pointer_info.child, any[i]));
                }
                return ret;
            }
        },
        else => return any,
    }
}

fn deserialize3Internal(comptime T: type, addr: u64) [][][]T {
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
fn deserialize2Internal(comptime T: type, addr: u64) [][]T {
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
fn deserialize1Internal(comptime T: type, addr: u64) []T {
    const T1 = []T;
    const l0: *T1 = mem.pointerOne(T1, addr);
    l0.* = mem.pointerMany(T, addr + @sizeOf(T1), l0.len);
    return l0.*;
}
fn serializeInternal(comptime T: type, allocator: anytype, pathname: [:0]const u8, comptime function: anytype, sets: anytype) !void {
    const save: @TypeOf(allocator.*).Save = allocator.save();
    defer allocator.restore(save);
    const bytes: []const u8 = try meta.wrap(function(T, allocator, sets));
    const fd: u64 = try file.create(.{ .options = .{ .exclusive = false, .read = false, .write = .truncate } }, pathname);
    defer file.close(.{ .errors = .{} }, fd);
    try file.write(.{}, fd, bytes);
}
fn deserializeInternal(comptime T: type, comptime S: type, allocator: anytype, pathname: [:0]const u8, comptime function: anytype) !S {
    const fd: u64 = try file.open(.{ .options = .{ .read = true, .write = null } }, pathname);
    defer file.close(.{ .errors = .{} }, fd);
    const st: file.Stat = try file.fstat(.{}, fd);
    allocator.alignAbove(16);
    const buf: []u8 = try meta.wrap(allocator.allocateIrreversible(u8, st.size));
    builtin.assertEqual(u64, st.size, try file.read(.{}, fd, buf, st.size));
    return try meta.wrap(function(T, @ptrToInt(buf.ptr)));
}
pub fn serialize3(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const []const []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize3Internal, sets);
}
pub fn serialize2(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize2Internal, sets);
}
pub fn serialize1(comptime T: type, allocator: anytype, pathname: [:0]const u8, sets: []const T) !void {
    return serializeInternal(T, allocator, pathname, serialize1Internal, sets);
}
pub fn deserialize3(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![][][]T {
    return deserializeInternal(T, [][][]T, allocator, pathname, deserialize3Internal);
}
pub fn deserialize2(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![][]T {
    return deserializeInternal(T, [][]T, allocator, pathname, deserialize2Internal);
}
pub fn deserialize1(comptime T: type, allocator: anytype, pathname: [:0]const u8) ![]T {
    return deserializeInternal(T, []T, allocator, pathname, deserialize1Internal);
}
