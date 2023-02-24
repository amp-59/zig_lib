const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const mach = srg.mach;
const preset = srg.preset;

// pub const AddressSpace = mem.GenericRegularAddressSpace(.{
//    .lb_addr = 0x0,
//    .lb_offset = 0x40000000,
//    .divisions = 64,
pub const AddressSpace = mem.GenericElementaryAddressSpace(.{
    .errors = preset.address_space.errors.noexcept,
    .logging = preset.address_space.logging.silent,
    .options = .{},
});
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    //.arena_index = 0,
    .arena_index = null,
    .errors = preset.allocator.errors.noexcept,
    .logging = preset.allocator.logging.silent,
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

noinline fn main() !void {
    @setAlignStack(16);
    @setEvalBranchQuota(~@as(u32, 0));
    comptime var i: u64 = 0;
    inline while (i != 1000) : (i +%= 1) {
        var address_space: AddressSpace = .{};
        var allocator: Allocator = Allocator.init(&address_space);
        allocator.deinit(&address_space);

        //mem.map(map_spec, 0x40000000, 4096);
        //mem.unmap(unmap_spec, 0x40000000, 4096);
    }
}
pub export fn _start() void {
    main() catch {};
    sys.call(.exit, .{}, noreturn, .{0});
}
