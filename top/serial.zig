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
fn toOffset(ptr: anytype, addr: u64) @TypeOf(ptr) {
    @setRuntimeSafety(false);
    switch (@typeInfo(@TypeOf(ptr)).Pointer.size) {
        .Slice => return @intToPtr(@TypeOf(ptr.ptr), @ptrToInt(ptr.ptr) -% addr)[0..ptr.len],
        .Many => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr.ptr) -% addr),
        else => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) -% addr),
    }
}
fn toAddress(ptr: anytype, addr: u64) @TypeOf(ptr) {
    @setRuntimeSafety(false);
    switch (@typeInfo(@TypeOf(ptr)).Pointer.size) {
        .Slice => return @intToPtr(@TypeOf(ptr.ptr), @ptrToInt(ptr.ptr) +% addr)[0..ptr.len],
        .Many => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr.ptr) +% addr),
        else => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) +% addr),
    }
}
fn readStruct(comptime struct_info: builtin.Type.Struct, addr: u64, offset: u64, any: anytype) u64 {
    var len: u64 = offset;
    inline for (struct_info.fields) |field| {
        len = read(addr, len, &@field(any, field.name));
    }
    return len;
}
fn readUnion(comptime union_info: builtin.Type.Union, addr: u64, offset: u64, any: anytype) u64 {
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            if (any.* == @field(tag_type, field.name)) {
                return read(addr, offset, &@field(any, field.name));
            }
        }
    }
    return offset;
}
fn readPointerOne(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next = toAddress(any.*, addr);
    defer any.* = next;

    var len: u64 = offset;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child);
    len = read(addr, len, next);
    return len;
}
fn readPointerSlice(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next = toAddress(any.*, addr);
    defer any.* = next;

    var len: u64 = offset;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (next.len +% @boolToInt(pointer_info.sentinel != null));
    for (next) |*value| {
        len = read(addr, len, value);
    }
    return len;
}
fn readPointerMany(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next = toAddress(any.*, addr);
    defer any.* = next;

    const sentinel: pointer_info.child = mem.pointerOpaque(pointer_info.child, pointer_info.sentinel);
    var len: u64 = offset;
    var idx: u64 = 0;
    while (next[idx] != sentinel) idx +%= 1;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (idx +% 1);
    for (next[0..idx]) |*value| {
        len = read(pointer_info.child, addr, len, value);
    }
    return len;
}
pub fn read(addr: u64, offset: u64, any: anytype) u64 {
    switch (@typeInfo(@TypeOf(any.*))) {
        .Struct => |struct_info| {
            return readStruct(struct_info, addr, offset, any);
        },
        .Union => |union_info| {
            return readUnion(union_info, addr, offset, any);
        },
        .Pointer => |pointer_info| {
            if (pointer_info.size == .One) {
                return readPointerOne(pointer_info, addr, offset, @constCast(any));
            }
            if (pointer_info.size == .Slice) {
                return readPointerSlice(pointer_info, addr, offset, @constCast(any));
            }
            if (pointer_info.size == .Many) {
                return readPointerMany(pointer_info, addr, offset, @constCast(any));
            }
        },
        else => return offset,
    }
}
fn writeStruct(comptime struct_info: builtin.Type.Struct, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const T: type = @TypeOf(any);
    var ret: T = any;
    inline for (struct_info.fields) |field| {
        @field(ret, field.name) = try meta.wrap(write(allocator, addr, @field(any, field.name)));
    }
    return ret;
}
fn writeUnion(comptime union_info: builtin.Type.Union, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const T: type = @TypeOf(any);
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            if (any == @field(tag_type, field.name)) {
                return @unionInit(T, field.name, try meta.wrap(write(allocator, addr, @field(any, field.name))));
            }
        }
    }
    return any;
}
fn writePointerOne(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    return toOffset(try meta.wrap(allocator.duplicateIrreversible(pointer_info.child, try meta.wrap(write(allocator, addr, any.*)))), addr);
}
fn writePointerSliceWithSentinel(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype, comptime sentinel: pointer_info.child) @TypeOf(any) {
    const ret: @TypeOf(@constCast(any)) = try meta.wrap(allocator.allocateWithSentinelIrreversible(pointer_info.child, any.len, sentinel));
    for (ret, 0..) |*ptr, i| {
        ptr.* = try meta.wrap(write(allocator, pointer_info.child, addr, any[i]));
    }
    return toOffset(ret, addr);
}
fn writePointerSlice(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const ret: @TypeOf(@constCast(any)) = try meta.wrap(allocator.allocateIrreversible(pointer_info.child, any.len));
    for (ret, 0..) |*ptr, i| {
        ptr.* = try meta.wrap(write(allocator, addr, any[i]));
    }
    return toOffset(ret, addr);
}
fn writePointerMany(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype, comptime sentinel: pointer_info.child) @TypeOf(any) {
    var idx: u64 = 0;
    while (any[idx] != sentinel) idx +%= 1;
    return writePointerSliceWithSentinel(pointer_info, allocator, addr, any[0..idx], sentinel).ptr;
}
pub fn write(allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload(@TypeOf(any)) {
    switch (@typeInfo(@TypeOf(any))) {
        .Struct => |struct_info| {
            return writeStruct(struct_info, allocator, addr, any);
        },
        .Union => |union_info| {
            return writeUnion(union_info, allocator, addr, any);
        },
        .Pointer => |pointer_info| {
            if (pointer_info.size == .One) {
                return writePointerOne(pointer_info, allocator, addr, any);
            }
            if (pointer_info.size == .Slice) {
                if (pointer_info.sentinel) |sentinel| {
                    return writePointerSliceWithSentinel(pointer_info, allocator, addr, any, sentinel);
                } else {
                    return writePointerSlice(pointer_info, allocator, addr, any);
                }
            }
            if (pointer_info.size == .Many) {
                return writePointerMany(pointer_info, allocator, addr, any);
            }
        },
        else => return any,
    }
}
fn genericSerializeSlicesLoop(comptime T: type, comptime lvl: u64, s_ab_addr: u64, any: anytype) u64 {
    var t_ab_addr: u64 = s_ab_addr;
    if (lvl == 0) {
        mem.pointerCount(u64, t_ab_addr, 2).* = .{ 0, any.len };
        return t_ab_addr +% @sizeOf([2]u64);
    } else for (any) |value| {
        t_ab_addr = genericSerializeSlicesLoop(T, lvl - 1, t_ab_addr, value);
    }
    return t_ab_addr;
}
fn genericDeserializeSlicesLoop(comptime S: type, comptime lvl: u64, addr: u64, s_aligned_bytes: u64, any: anytype) u64 {
    var t_aligned_bytes: u64 = s_aligned_bytes;
    if (lvl == 0) {
        any.* = mem.pointerMany(S, addr +% s_aligned_bytes, any.len);
        return s_aligned_bytes +% (any.len *% @sizeOf(S));
    } else for (any.*) |*value| {
        t_aligned_bytes = genericDeserializeSlicesLoop(meta.Child(S), lvl - 1, addr, t_aligned_bytes, value);
    }
    return t_aligned_bytes;
}
fn genericSerializeValuesLoop(comptime T: type, allocator: anytype, s_ab_addr: u64, s_up_addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload(u64) {
    var t_ab_addr: u64 = s_ab_addr;
    if (@TypeOf(any) == T) {
        mem.pointerOne(T, t_ab_addr).* = try meta.wrap(write(allocator, s_up_addr, any));
        return t_ab_addr +% @sizeOf(T);
    } else for (any) |value| {
        t_ab_addr = try meta.wrap(genericSerializeValuesLoop(T, allocator, t_ab_addr, s_up_addr, value));
    }
    return t_ab_addr;
}
fn genericDeserializeValuesLoop(comptime T: type, s_up_addr: u64, s_aligned_bytes: u64, any: anytype) u64 {
    var t_aligned_bytes: u64 = s_aligned_bytes;
    if (@TypeOf(any) == *T) {
        return read(s_up_addr, t_aligned_bytes, any);
    } else for (any.*) |*value| {
        t_aligned_bytes = genericDeserializeValuesLoop(T, s_up_addr, t_aligned_bytes, value);
    }
    return t_aligned_bytes;
}
pub fn genericSerializeInternal(allocator: anytype, s_ab_addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload([]u8) {
    const S: type = @TypeOf(any);
    const T: type = meta.SliceChild(S);
    const s_up_addr: u64 = s_ab_addr +% length(T, any);
    try meta.wrap(allocator.mapBelow(s_up_addr));
    try meta.wrap(allocator.allocate(s_up_addr));
    var t_ab_addr: u64 = s_ab_addr;
    inline for (0..comptime meta.sliceLevel(S)) |lvl| {
        t_ab_addr = try meta.wrap(genericSerializeSlicesLoop(T, lvl, t_ab_addr, any));
    } else {
        t_ab_addr = try meta.wrap(genericSerializeValuesLoop(T, allocator, t_ab_addr, s_up_addr, any));
    }
    return mem.pointerMany(u8, s_ab_addr, allocator.unallocated_byte_address() - s_ab_addr);
}
pub fn genericDeserializeInternal(comptime S: type, s_ab_addr: u64) S {
    const ret: *S = mem.pointerOne(S, s_ab_addr);
    var s_aligned_bytes: u64 = @sizeOf(S);
    var t_aligned_bytes: u64 = 0;
    inline for (0..comptime meta.sliceLevel(S)) |lvl| {
        s_aligned_bytes = genericDeserializeSlicesLoop(meta.Child(S), lvl, s_ab_addr, s_aligned_bytes, ret);
    } else {
        t_aligned_bytes = genericDeserializeValuesLoop(meta.SliceChild(S), s_ab_addr + s_aligned_bytes, t_aligned_bytes, ret);
    }
    return ret.*;
}
const create_spec: file.CreateSpec = .{ .options = .{ .exclusive = false, .read = false, .write = .truncate } };
const read_spec: file.ReadSpec = .{ .return_value = void };
const open_spec: file.OpenSpec = .{ .options = .{ .read = true, .write = null } };
const write_spec: file.WriteSpec = .{};
const stat_spec: file.StatSpec = .{};
const close_spec: file.CloseSpec = .{};

pub fn serialize(allocator: anytype, pathname: [:0]const u8, sets: anytype) !void {
    const save = allocator.save();
    defer allocator.restore(save);
    const s_ab_addr: u64 = allocator.alignAbove(16);
    const bytes: []const u8 = try meta.wrap(genericSerializeInternal(allocator, s_ab_addr, sets));
    const fd: u64 = try file.create(create_spec, pathname);
    try file.write(write_spec, fd, bytes);
    try file.close(close_spec, fd);
}
pub fn deserialize(comptime S: type, allocator: anytype, pathname: [:0]const u8) !S {
    const fd: u64 = try file.open(open_spec, pathname);
    const t_ab_addr: u64 = allocator.alignAbove(16);
    const st: file.Stat = try file.fstat(stat_spec, fd);
    const buf: []u8 = try meta.wrap(allocator.allocateIrreversible(u8, st.size));
    try file.read(read_spec, fd, buf, st.size);
    try file.close(close_spec, fd);
    return try meta.wrap(genericDeserializeInternal(S, t_ab_addr));
}

fn allocateFile(allocator: anytype, pathname: [:0]const u8) !void {
    const fd: u64 = try file.open(open_spec, pathname);
    const st: file.Stat = try file.fstat(stat_spec, fd);
    const buf: []u8 = try meta.wrap(allocator.allocateIrreversible(u8, st.size));
    try file.read(read_spec, fd, buf, st.size);
    try file.close(close_spec, fd);
}
