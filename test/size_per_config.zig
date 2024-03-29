const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const sys = zl.sys;
const fmt = zl.fmt;
const proc = zl.proc;
const time = zl.time;
const meta = zl.meta;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

// pub const AddressSpace = mem.GenericRegularAddressSpace(.{
//    .lb_addr = 0x0,
//    .lb_offset = 0x40000000,
//    .divisions = 64,
pub const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .errors = mem.spec.address_space.errors.noexcept,
    .logging = mem.spec.address_space.logging.silent,
    .options = .{},
});
const Allocator = mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    //.arena_index = 0,
    .errors = mem.dynamic.spec.errors.noexcept,
    .logging = mem.dynamic.spec.logging.silent,
});

const map_spec: mem.MapSpec = .{
    .errors = .{}, // .{ .throw = &.{}, .abort = &.{} }, //.{ .throw = null, .abort = null },
    .logging = .{ .Acquire = false, .Error = false, .Fault = false },
    .options = .{},
};
const unmap_spec: mem.UnmapSpec = .{
    .errors = .{}, // .{ .throw = &.{}, .abort = &.{} }, //.{ .throw = null, .abort = null },
    .logging = .{ .Release = false, .Error = false, .Fault = false },
};

//inline fn subPerc(x: u64, y: u64) u64 {
inline fn subPerc(x: u64, y: u64) u64 {
    return x -% y;
}
//inline fn sub(x: u64, y: u64) u64 {
fn sub(x: u64, y: u64) u64 {
    return x - y;
}
noinline fn testImpactOfTrivialForwardedOperations() !void {
    @setEvalBranchQuota(~@as(u32, 0));
    var x: u64 = 0;
    comptime var i: u64 = 0;
    inline while (i != 0x1000) : (i +%= 1) {
        //x -= 1;
        //x = sub(x, 1);
        x = subPerc(x, 1);
        //x -%= 1;
        //x -= 1;
    }
}
pub fn mut(comptime T: type) type {
    const type_info: builtin.Type = @typeInfo(T);
    if (type_info == .Pointer) {
        var ret: builtin.Type = type_info;
        const child_type_info: builtin.Type = @typeInfo(type_info.Pointer.child);
        ret.Pointer.is_const = false;
        if (child_type_info == .Pointer) {
            ret.Pointer.child = mut(type_info.Pointer.child);
        }
        return @Type(.{ .Pointer = ret.Pointer });
    }
    return T;
}
pub fn mut2(comptime T: type) type {
    if (@typeInfo(T) != .Pointer) {
        return T;
    }
    var ret: builtin.Type = @typeInfo(@TypeOf(@constCast(@as(T, undefined))));
    ret.Pointer.child = mut2(ret.Pointer.child);
    return @Type(ret);
}

noinline fn testDifferenceBetweenMutMethods() !void {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime var i: u64 = 0;

    inline while (i != 0x10000) : (i +%= 1) {
        const T = []const []const []const @Type(.{ .Int = .{ .bits = i, .signedness = .unsigned } });
        _ = mut2(T);
    }
}
noinline fn testDifferenceBetweenHighAndLowLevelMemoryManagement() !void {
    @setAlignStack(16);
    @setEvalBranchQuota(~@as(u32, 0));
    comptime var i: u64 = 0;
    inline while (i != 1000) : (i +%= 1) {
        // High:
        var address_space: AddressSpace = .{};
        var allocator: Allocator = Allocator.init(&address_space);
        allocator.deinit(&address_space);

        // Low:
        //mem.map(map_spec, 0x40000000, 4096);
        //mem.unmap(unmap_spec, 0x40000000, 4096);
    }
}

const Target = struct {
    name: []const u8,

    build_cmd: struct {
        kind: enum { exe, obj, lib },
        mode: enum {
            Debug,
            ReleaseSmall,
            ReleaseFast,
            RelaseSafe,
        },
    },
};
pub fn main() void {
    try testDifferenceBetweenHighAndLowLevelMemoryManagement();
}
