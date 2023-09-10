const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");

pub const Allocator = mem.SimpleAllocator;

pub fn duplicate(allocator: *Allocator, values: []const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    if (@intFromPtr(values.ptr) < 0x40000000) {
        return @constCast(values.ptr)[0..values.len :0];
    }
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(values.len +% 1, 1));
    @memcpy(buf, values);
    buf[values.len] = 0;
    return buf[0..values.len :0];
}
pub fn concatenate(allocator: *Allocator, values: []const []const u8) [:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var len: usize = 0;
    for (values) |value| {
        len +%= value.len;
    }
    const buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(len +% 1, 1));
    var idx: usize = 0;
    for (values) |value| {
        @memcpy(buf + idx, value);
        idx +%= value.len;
    }
    buf[len] = 0;
    return buf[0..len :0];
}
pub fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
    @setRuntimeSafety(builtin.is_safe);
    var count: u64 = 0;
    for (args) |value| {
        count +%= @intFromBool(value == 0);
    }
    const ret: [*][*:0]u8 = @ptrFromInt(allocator.allocateRaw(8 *% (count +% 1), 8));
    var len: usize = 0;
    var idx: usize = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0 or
            args[idx] == '\n')
        {
            ret[len] = args[pos..idx :0];
            len +%= 1;
            pos = idx +% 1;
        }
    }
    ret[len] = @ptrFromInt(8);
    ret[len] -= 8;
    return ret[0..len];
}
pub fn testExtension(name: []const u8, str: []const u8) bool {
    @setRuntimeSafety(builtin.is_safe);
    return str.len < name.len and
        mem.testEqualString(str, name[name.len -% str.len ..]);
}
