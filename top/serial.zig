const mem = @import("mem.zig");
const fmt = @import("fmt.zig");
const sys = @import("sys.zig");
const file = @import("file.zig");
const meta = @import("meta.zig");
const bits = @import("bits.zig");
const math = @import("math.zig");
const debug = @import("debug.zig");
const builtin = @import("builtin.zig");
const testing = @import("testing.zig");
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
    const Pointer = @TypeOf(ptr);
    const type_info: builtin.Type = @typeInfo(Pointer);
    switch (type_info.Pointer.size) {
        .Slice => return (ptr.ptr - (addr / @sizeOf(type_info.Pointer.child)))[0..ptr.len],
        .Many => return @as(@TypeOf(ptr), @ptrFromInt(@intFromPtr(ptr) -% addr)),
        else => return @as(@TypeOf(ptr), @ptrFromInt(@intFromPtr(ptr) -% addr)),
    }
}
fn toAddress(ptr: anytype, addr: u64) @TypeOf(ptr) {
    @setRuntimeSafety(false);
    const Pointer = @TypeOf(ptr);
    const type_info: builtin.Type = @typeInfo(Pointer);
    switch (type_info.Pointer.size) {
        .Slice => return (ptr.ptr + (addr / @sizeOf(type_info.Pointer.child)))[0..ptr.len],
        .Many => return @as(Pointer, @ptrFromInt(@intFromPtr(ptr) +% addr)),
        else => return @as(Pointer, @ptrFromInt(@intFromPtr(ptr) +% addr)),
    }
}
fn readStruct(comptime struct_info: builtin.Type.Struct, addr: u64, offset: u64, any: anytype) u64 {
    @setRuntimeSafety(false);
    var len: u64 = offset;
    inline for (struct_info.fields) |field| {
        len = readAny(addr, len, &@field(any, field.name));
    }
    return len;
}
fn readUnion(comptime union_info: builtin.Type.Union, addr: u64, offset: u64, any: anytype) u64 {
    @setRuntimeSafety(false);
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            if (any.* == @field(tag_type, field.name)) {
                return readAny(addr, offset, &@field(any, field.name));
            }
        }
    }
    return offset;
}
fn writeStruct(comptime struct_info: builtin.Type.Struct, allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload(@TypeOf(any)) {
    @setRuntimeSafety(false);
    const T: type = @TypeOf(any);
    var ret: T = any;
    inline for (struct_info.fields) |field| {
        @field(ret, field.name) = try meta.wrap(
            writeAny(allocator, addr, @field(any, field.name)),
        );
    }
    return ret;
}
fn writeUnion(comptime union_info: builtin.Type.Union, allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload(@TypeOf(any)) {
    @setRuntimeSafety(false);
    const T: type = @TypeOf(any);
    if (union_info.tag_type) |tag_type| {
        inline for (union_info.fields) |field| {
            if (any == @field(tag_type, field.name)) {
                return @unionInit(T, field.name, try meta.wrap(
                    writeAny(allocator, addr, @field(any, field.name)),
                ));
            }
        }
    }
    return any;
}
fn readPointerOne(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    @setRuntimeSafety(false);
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    len = math.sub64(bits.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child);
    len = readAny(addr, len, next);
    any.* = next;
    return len;
}
fn readPointerSlice(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    @setRuntimeSafety(false);
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    len = math.sub64(bits.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (next.len +% @intFromBool(pointer_info.sentinel != null));
    for (next) |*value| {
        len = readAny(addr, len, value);
    }
    any.* = next;
    return len;
}
fn readPointerMany(comptime pointer_info: builtin.Type.Pointer, addr: u64, offset: u64, any: anytype) u64 {
    @setRuntimeSafety(false);
    const next: @TypeOf(any.*) = toAddress(any.*, addr);
    var len: u64 = offset;
    var idx: u64 = 0;
    while (next[idx] != comptime mem.pointerOpaque(pointer_info.child, pointer_info.sentinel.?).*) idx +%= 1;
    len = math.sub64(bits.alignA64(addr +% len, @alignOf(pointer_info.child)), addr);
    len +%= @sizeOf(pointer_info.child) *% (idx +% 1);
    for (next[0..idx]) |*value| {
        len = readAny(addr, len, value);
    }
    any.* = next;
    return len;
}
fn writePointerOne(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*)
    .allocate_payload(@TypeOf(any)) {
    @setRuntimeSafety(false);
    if (@typeInfo(pointer_info.child) == .Fn) {
        return any;
    }
    const ret: @TypeOf(any) = try meta.wrap(
        allocator.create(pointer_info.child),
    );
    ret.* = try meta.wrap(
        writeAny(allocator, addr, any.*),
    );
    return toOffset(ret, addr);
}
fn writePointerSlice(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*)
    .allocate_payload(@TypeOf(any)) {
    @setRuntimeSafety(false);
    if (pointer_info.sentinel) |sentinel_ptr| {
        const sentinel: pointer_info.child = comptime mem.pointerOpaque(pointer_info.child, sentinel_ptr).*;
        const ret: []pointer_info.child = try meta.wrap(
            allocator.allocate(pointer_info.child, any.len +% 1),
        );
        ret.ptr[ret.len] = sentinel;
        for (ret, 0..) |*ptr, i| {
            ptr.* = try meta.wrap(
                writeAny(allocator, addr, any[i]),
            );
        }
        return toOffset(ret, addr)[0.. :sentinel];
    } else {
        const ret: []pointer_info.child = try meta.wrap(
            allocator.allocate(pointer_info.child, any.len),
        );
        for (ret, 0..) |*ptr, i| {
            ptr.* = try meta.wrap(
                writeAny(allocator, addr, any[i]),
            );
        }
        return toOffset(ret, addr);
    }
}
fn writePointerMany(comptime pointer_info: builtin.Type.Pointer, allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*)
    .allocate_payload(@TypeOf(any)) {
    const ret = try meta.wrap(writePointerSlice(pointer_info, allocator, addr, meta.manyToSlice(any)));
    return ret.ptr;
}
pub fn writeAny(allocator: anytype, addr: u64, any: anytype) @TypeOf(allocator.*)
    .allocate_payload(@TypeOf(any)) {
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
pub fn readAny(addr: u64, offset: u64, any: anytype) u64 {
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
            writeAny(allocator, s_up_addr, any),
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
        return readAny(s_up_addr, t_aligned_bytes, any);
    } else for (any.*) |*value| {
        t_aligned_bytes = genericDeserializeValuesLoop(T, s_up_addr, t_aligned_bytes, value);
    }
    return t_aligned_bytes;
}
pub fn genericSerializeInternal(allocator: anytype, s_ab_addr: u64, any: anytype) @TypeOf(allocator.*).allocate_payload([]u8) {
    @setRuntimeSafety(false);
    const S: type = @TypeOf(any);
    const T: type = meta.SliceChild(S);
    const s_up_addr: u64 = s_ab_addr +% length(T, any);
    try meta.wrap(
        allocator.mapBelow(s_up_addr),
    );
    allocator.increment(s_up_addr);
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
    pub const Logging = packed struct {
        create: debug.Logging.AcquireError = .{},
        open: debug.Logging.AttemptAcquireError = .{},
        read: debug.Logging.SuccessError = .{},
        write: debug.Logging.SuccessError = .{},
        close: debug.Logging.ReleaseError = .{},
        stat: debug.Logging.SuccessErrorFault = .{},
    };
    pub const Errors = struct {
        create: sys.ErrorPolicy = .{ .throw = file.spec.open.errors.all },
        open: sys.ErrorPolicy = .{ .throw = file.spec.open.errors.all },
        stat: sys.ErrorPolicy = .{ .throw = file.spec.stat.errors.all },
        read: sys.ErrorPolicy = .{ .throw = file.spec.read.errors.all },
        write: sys.ErrorPolicy = .{ .throw = file.spec.write.errors.all },
        close: sys.ErrorPolicy = .{ .abort = file.spec.close.errors.all },
    };
};

pub fn GenericSerializer(comptime serial_spec: SerialSpec) type {
    const T = struct {
        pub fn serialWrite(comptime S: type, allocator: *serial_spec.Allocator, pathname: [:0]const u8, value: S) sys.ErrorUnion(.{
            .throw = serial_spec.Allocator.map_error_policy.throw ++ serial_spec.errors.create.throw ++
                serial_spec.errors.open.throw ++ serial_spec.errors.write.throw ++ serial_spec.errors.close.throw,
            .abort = serial_spec.Allocator.map_error_policy.abort ++ serial_spec.errors.create.abort ++
                serial_spec.errors.open.abort ++ serial_spec.errors.write.abort ++ serial_spec.errors.close.abort,
        }, void) {
            const save = allocator.save();
            defer allocator.restore(save);
            const s_ab_addr: u64 = allocator.alignAbove(16);
            const bytes: []const u8 = try meta.wrap(
                genericSerializeInternal(allocator, s_ab_addr, value),
            );
            const fd: usize = try meta.wrap(
                file.create(create(), .{ .exclusive = false, .truncate = true }, pathname, file.mode.regular),
            );
            try meta.wrap(
                file.write(write(), fd, bytes),
            );
            try meta.wrap(
                file.close(close(), fd),
            );
        }
        pub fn serialRead(comptime S: type, allocator: *serial_spec.Allocator, pathname: [:0]const u8) sys.ErrorUnion(.{
            .throw = serial_spec.Allocator.map_error_policy.throw ++
                serial_spec.errors.open.throw ++ serial_spec.errors.read.throw ++ serial_spec.errors.close.throw,
            .abort = serial_spec.Allocator.map_error_policy.abort ++
                serial_spec.errors.open.abort ++ serial_spec.errors.read.abort ++ serial_spec.errors.close.abort,
        }, meta.Mutable(S)) {
            const t_ab_addr: u64 = allocator.alignAbove(16);
            const fd: usize = try meta.wrap(
                file.open(open(), .{}, pathname),
            );
            const st: file.Status = try meta.wrap(
                file.getStatus(stat(), fd),
            );
            const buf: []u8 = try meta.wrap(
                allocator.allocate(u8, st.size),
            );
            try meta.wrap(
                file.read(read(), fd, buf[0..st.size]),
            );
            try meta.wrap(
                file.close(close(), fd),
            );
            return try meta.wrap(
                genericDeserializeInternal(meta.Mutable(S), t_ab_addr),
            );
        }

        fn stat() file.StatusSpec {
            return .{
                .logging = serial_spec.logging.stat,
                .errors = serial_spec.errors.stat,
            };
        }
        fn read() file.ReadSpec {
            return .{
                .return_type = void,
                .logging = serial_spec.logging.read,
                .errors = serial_spec.errors.read,
            };
        }
        fn write() file.WriteSpec {
            return .{
                .logging = serial_spec.logging.read,
                .errors = serial_spec.errors.read,
            };
        }
        fn close() file.CloseSpec {
            return .{
                .logging = serial_spec.logging.close,
                .errors = serial_spec.errors.close,
            };
        }
        fn create() file.CreateSpec {
            return .{
                .logging = serial_spec.logging.create,
                .errors = serial_spec.errors.create,
            };
        }
        fn open() file.OpenSpec {
            return .{
                .logging = serial_spec.logging.open,
                .errors = serial_spec.errors.open,
            };
        }
    };
    return T;
}
pub const spec = struct {
    pub const serializer = struct {
        pub const errors = struct {
            pub const noexcept: SerialSpec.Errors = .{
                .create = .{},
                .open = .{},
                .close = .{},
                .stat = .{},
                .read = .{},
                .write = .{},
            };
            pub const all: SerialSpec.Errors = .{
                .create = .{ .throw = sys.open.errors.all },
                .open = .{ .throw = sys.open.errors.all },
                .close = .{ .throw = sys.close.errors.all },
                .stat = .{ .throw = sys.stat.errors.all },
                .read = .{ .throw = sys.read.errors.all },
                .write = .{ .throw = sys.write.errors.all },
            };
        };
        pub const logging = struct {
            pub const verbose: SerialSpec.Logging = builtin.all(SerialSpec.Logging);
            pub const silent: SerialSpec.Logging = builtin.zero(SerialSpec.Logging);
        };
    };
};
