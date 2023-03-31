const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const sys = @import("./sys.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

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
        .Slice => return @ptrCast(@TypeOf(ptr), @intToPtr(@TypeOf(ptr.ptr), @ptrToInt(ptr.ptr) -% addr)[0..ptr.len]),
        .Many => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) -% addr),
        else => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) -% addr),
    }
}
fn toAddress(ptr: anytype, addr: u64) @TypeOf(ptr) {
    @setRuntimeSafety(false);
    switch (@typeInfo(@TypeOf(ptr)).Pointer.size) {
        .Slice => return @ptrCast(@TypeOf(ptr), @intToPtr(@TypeOf(ptr.ptr), @ptrToInt(ptr.ptr) +% addr)[0..ptr.len]),
        .Many => return @intToPtr(@TypeOf(ptr), @ptrToInt(ptr) +% addr),
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
fn writeStruct(comptime struct_info: builtin.Type.Struct, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const T: type = @TypeOf(any);
    var ret: T = any;
    inline for (struct_info.fields) |field| {
        @field(ret, field.name) = try meta.wrap(
            write(allocator, addr, @field(any, field.name)),
        );
    }
    return ret;
}
fn writeUnion(comptime union_info: builtin.Type.Union, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const T: type = @TypeOf(any);
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            if (any == @field(tag_type, field.name)) {
                return @unionInit(T, field.name, try meta.wrap(
                    write(allocator, addr, @field(any, field.name)),
                ));
            }
        }
    }
    return any;
}
fn readPointerOne(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child);
    len = read(addr, len, next);
    any.* = next;
    return len;
}
fn readPointerSlice(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (next.len +% @boolToInt(pointer_info.sentinel != null));
    for (next) |*value| {
        len = read(addr, len, value);
    }
    any.* = next;
    return len;
}
fn readPointerMany(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    var idx: u64 = 0;
    while (next[idx] != mem.pointerOpaque(pointer_info.child, pointer_info.sentinel.?).*) idx +%= 1;
    len = mach.sub64(mach.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (idx +% 1);
    for (next[0..idx]) |*value| {
        len = read(addr, len, value);
    }
    any.* = next;
    return len;
}
fn writePointerOne(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    const ret: @TypeOf(any) = try meta.wrap(
        allocator.createIrreversible(pointer_info.child),
    );
    ret.* = try meta.wrap(
        write(allocator, addr, any.*),
    );
    return toOffset(ret, addr);
}
fn writePointerSlice(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    if (pointer_info.sentinel) |sentinel_ptr| {
        const sentinel: pointer_info.child =
            comptime mem.pointerOpaque(pointer_info.child, sentinel_ptr).*;
        const ret: @TypeOf(any) = try meta.wrap(
            allocator.allocateWithSentinelIrreversible(pointer_info.child, any.len, sentinel),
        );
        for (ret, 0..) |*ptr, i| {
            ptr.* = try meta.wrap(
                write(allocator, addr, any[i]),
            );
        }
        return toOffset(ret, addr);
    } else {
        const ret: @TypeOf(any) = try meta.wrap(
            allocator.allocateIrreversible(pointer_info.child, any.len),
        );
        for (ret, 0..) |*ptr, i| {
            ptr.* = try meta.wrap(
                write(allocator, addr, any[i]),
            );
        }
        return toOffset(ret, addr);
    }
}
fn writePointerMany(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(any) {
    return writePointerSlice(pointer_info, allocator, addr, meta.manyToSlice(any)).ptr;
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
                return writePointerOne(pointer_info, allocator, addr, @constCast(any));
            }
            if (pointer_info.size == .Slice) {
                return writePointerSlice(pointer_info, allocator, addr, @constCast(any));
            }
            if (pointer_info.size == .Many) {
                return writePointerMany(pointer_info, allocator, addr, @constCast(any));
            }
        },
        else => return any,
    }
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
fn genericSerializeSlicesLoop(comptime T: type, comptime lvl: u64, s_ab_addr: u64, any: anytype) u64 {
    var t_ab_addr: u64 = s_ab_addr;
    if (lvl == 0) {
        mem.pointerCount(u64, t_ab_addr, 2).* = .{ 0, any.len };
        return t_ab_addr +% @sizeOf([]const void);
    } else for (any) |value| {
        t_ab_addr = genericSerializeSlicesLoop(T, lvl - 1, t_ab_addr, value);
    }
    return t_ab_addr;
}
fn genericDeserializeSlicesLoop(comptime S: type, comptime lvl: u64, addr: u64, s_aligned_bytes: u64, any: anytype) u64 {
    var t_aligned_bytes: u64 = s_aligned_bytes;
    if (lvl == 0) {
        @constCast(any).* = mem.pointerSlice(S, addr +% s_aligned_bytes, any.len);
        return s_aligned_bytes +% (any.len *% @sizeOf(S));
    } else {
        for (any.*) |*value| {
            t_aligned_bytes = genericDeserializeSlicesLoop(meta.Child(S), lvl - 1, addr, t_aligned_bytes, value);
        }
    }
    return t_aligned_bytes;
}
fn genericSerializeValuesLoop(comptime T: type, allocator: anytype, s_ab_addr: u64, s_up_addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload(u64) {
    var t_ab_addr: u64 = s_ab_addr;
    if (@TypeOf(any) == T) {
        mem.pointerOne(T, t_ab_addr).* = try meta.wrap(
            write(allocator, s_up_addr, any),
        );
        return t_ab_addr +% @sizeOf(T);
    } else for (any) |value| {
        t_ab_addr = try meta.wrap(
            genericSerializeValuesLoop(T, allocator, t_ab_addr, s_up_addr, value),
        );
    }
    return t_ab_addr;
}
fn genericDeserializeValuesLoop(comptime T: type, s_up_addr: u64, s_aligned_bytes: u64, any: anytype) u64 {
    var t_aligned_bytes: u64 = s_aligned_bytes;
    if (@TypeOf(@constCast(any)) == *T) {
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
    try meta.wrap(
        allocator.mapBelow(s_up_addr),
    );
    allocator.allocate(s_up_addr);
    var t_ab_addr: u64 = s_ab_addr;
    inline for (0..comptime meta.sliceLevel(S)) |lvl| {
        t_ab_addr = try meta.wrap(
            genericSerializeSlicesLoop(T, lvl, t_ab_addr, any),
        );
    } else {
        t_ab_addr = try meta.wrap(
            genericSerializeValuesLoop(T, allocator, t_ab_addr, s_up_addr, any),
        );
    }
    return mem.pointerSlice(u8, s_ab_addr, allocator.unallocated_byte_address() - s_ab_addr);
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
pub const SerialSpec = struct {
    Allocator: type,
    errors: Errors = .{},
    logging: Logging = .{},

    pub const Logging = struct {
        create: builtin.Logging.AcquireErrorFault = .{},
        open: builtin.Logging.AcquireErrorFault = .{},
        stat: builtin.Logging.SuccessErrorFault = .{},
        read: builtin.Logging.SuccessErrorFault = .{},
        write: builtin.Logging.SuccessErrorFault = .{},
        close: builtin.Logging.ReleaseErrorFault = .{},
    };
    pub const Errors = struct {
        create: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        open: sys.ErrorPolicy = .{ .throw = sys.open_errors },
        stat: sys.ErrorPolicy = .{ .throw = sys.stat_errors },
        read: sys.ErrorPolicy = .{ .throw = sys.read_errors },
        write: sys.ErrorPolicy = .{ .throw = sys.write_errors },
        close: sys.ErrorPolicy = .{ .abort = sys.close_errors },
    };
    fn stat(comptime spec: SerialSpec) file.StatSpec {
        return .{ .logging = spec.logging.stat, .errors = spec.errors.stat };
    }
    fn read(comptime spec: SerialSpec) file.ReadSpec {
        return .{ .return_value = void, .logging = spec.logging.read, .errors = spec.errors.read };
    }
    fn write(comptime spec: SerialSpec) file.WriteSpec {
        return .{ .logging = spec.logging.read, .errors = spec.errors.read };
    }
    fn close(comptime spec: SerialSpec) file.CloseSpec {
        return .{ .logging = spec.logging.close, .errors = spec.errors.close };
    }
    fn create(comptime spec: SerialSpec) file.CreateSpec {
        return .{
            .logging = spec.logging.create,
            .errors = spec.errors.create,
            .options = .{ .exclusive = false, .read = false, .write = .truncate },
        };
    }
    fn open(comptime spec: SerialSpec) file.OpenSpec {
        return .{
            .logging = spec.logging.open,
            .errors = spec.errors.open,
            .options = .{ .read = true, .write = null },
        };
    }
};
pub fn serialWrite(comptime spec: SerialSpec, comptime S: type, allocator: *spec.Allocator, pathname: [:0]const u8, value: S) sys.Call(.{
    .throw = spec.Allocator.map_error_policy.throw ++ spec.errors.create.throw ++
        spec.errors.open.throw ++ spec.errors.write.throw ++ spec.errors.close.throw,
    .abort = spec.Allocator.map_error_policy.abort ++ spec.errors.create.abort ++
        spec.errors.open.abort ++ spec.errors.write.abort ++ spec.errors.close.abort,
}, void) {
    const create_spec: file.CreateSpec = comptime spec.create();
    const write_spec: file.WriteSpec = comptime spec.write();
    const close_spec: file.CloseSpec = comptime spec.close();
    const save = allocator.save();
    defer allocator.restore(save);
    const s_ab_addr: u64 = allocator.alignAbove(16);
    const bytes: []const u8 = try meta.wrap(
        genericSerializeInternal(allocator, s_ab_addr, value),
    );
    const fd: u64 = try meta.wrap(
        file.create(create_spec, pathname, file.file_mode),
    );
    try meta.wrap(
        file.write(write_spec, fd, bytes),
    );
    try meta.wrap(
        file.close(close_spec, fd),
    );
}
pub fn serialRead(comptime spec: SerialSpec, comptime S: type, allocator: *spec.Allocator, pathname: [:0]const u8) sys.Call(.{
    .throw = spec.Allocator.map_error_policy.throw ++
        spec.errors.open.throw ++ spec.errors.read.throw ++ spec.errors.close.throw,
    .abort = spec.Allocator.map_error_policy.abort ++
        spec.errors.open.abort ++ spec.errors.read.abort ++ spec.errors.close.abort,
}, meta.Mutable(S)) {
    const open_spec: file.OpenSpec = comptime spec.open();
    const stat_spec: file.StatSpec = comptime spec.stat();
    const read_spec: file.ReadSpec = comptime spec.read();
    const close_spec: file.CloseSpec = comptime spec.close();
    const t_ab_addr: u64 = allocator.alignAbove(16);
    const fd: u64 = try meta.wrap(
        file.open(open_spec, pathname),
    );
    const st: file.Stat = try meta.wrap(
        file.fstat(stat_spec, fd),
    );
    const buf: []u8 = try meta.wrap(
        allocator.allocateIrreversible(u8, st.size),
    );
    try meta.wrap(
        file.read(read_spec, fd, buf, st.size),
    );
    try meta.wrap(
        file.close(close_spec, fd),
    );
    return try meta.wrap(
        genericDeserializeInternal(meta.Mutable(S), t_ab_addr),
    );
}
