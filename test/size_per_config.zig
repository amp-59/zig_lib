const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const mach = srg.mach;
const meta = srg.meta;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace mach;

// pub const AddressSpace = mem.GenericRegularAddressSpace(.{
//    .lb_addr = 0x0,
//    .lb_offset = 0x40000000,
//    .divisions = 64,
pub const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .errors = spec.address_space.errors.noexcept,
    .logging = spec.address_space.logging.silent,
    .options = .{},
});
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    //.arena_index = 0,
    .errors = spec.allocator.errors.noexcept,
    .logging = spec.allocator.logging.silent,
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
pub export fn _start() void {
    //try meta.wrap(testImpactOfTrivialForwardedOperations());
    try meta.wrap(testDifferenceBetweenHighAndLowLevelMemoryManagement());
    //try meta.wrap(testDifferenceBetweenMutMethods());

    sys.call(.exit, .{}, noreturn, .{0});
}
