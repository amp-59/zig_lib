const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const LoaderSpace = zl.mem.GenericDiscreteAddressSpace(.{
    .index_type = u8,
    .label = "dl",
    .list = &[2]zl.mem.Arena{
        .{ .lb_addr = 0x400000000, .up_addr = 0x800000000 },
        .{ .lb_addr = 0x800000000, .up_addr = 0xc00000000 },
    },
});
pub const DynamicLoader = zl.elf.GenericDynamicLoader(.{
    .logging = .{ .show_elf_header = true },
    .errors = .{},
    .AddressSpace = LoaderSpace,
});
const about_s: zl.fmt.AboutSrc = zl.fmt.about("xelf");
const width: usize = zl.fmt.aboutCentre(about_s);

pub fn main(args: [][*:0]u8) !void {
    var dl: DynamicLoader = .{};
    const info1: *DynamicLoader.Info = try dl.load(zl.mem.terminate(args[1], 0));
    const info2: *DynamicLoader.Info = try dl.load(zl.mem.terminate(args[2], 0));
    var allocator: zl.mem.SimpleAllocator = .{};
    var buf: []u8 = allocator.allocate(u8, 1024 *% 1024);
    zl.debug.write(buf[0..zl.fmt.strlen(DynamicLoader.compare.writeBinaryDifference(buf.ptr, info1, info2, width), buf.ptr)]);
}
