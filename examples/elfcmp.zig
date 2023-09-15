const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const debug = zl.debug;
const virtual = zl.virtual;

pub usingnamespace zl.start;

pub const want_stack_traces: bool = true;

pub const LoaderSpace = virtual.GenericDiscreteAddressSpace(.{
    .index_type = u8,
    .label = "ld",
    .list = &[2]mem.Arena{
        .{ .lb_addr = 0x400000000, .up_addr = 0x800000000 },
        .{ .lb_addr = 0x800000000, .up_addr = 0xc00000000 },
    },
});
pub const DynamicLoader = zl.elf.GenericDynamicLoader(.{
    .options = .{},
    .logging = .{
        .hide_unchanged_sections = false,
        .show_elf_header = true,
        .show_relocations = true,
    },
    .errors = .{},
    .AddressSpace = LoaderSpace,
});
const about_s: fmt.AboutSrc = fmt.about("xelf");
pub fn main(args: [][*:0]u8) !void {
    var allocator: mem.SimpleAllocator = .{};
    var info1: *DynamicLoader.Info = @ptrFromInt(8);
    var info2: *DynamicLoader.Info = @ptrFromInt(8);
    var buf: [*]u8 = @ptrFromInt(allocator.allocateRaw(1024 *% 1024, 1));
    var end: [*]u8 = @ptrFromInt(1);
    var ld: DynamicLoader = .{};
    if (args.len >= 2) {
        info1 = try ld.load(mem.terminate(args[1], 0));
    }
    if (args.len == 2) {
        end = DynamicLoader.about.writeBinary(about_s, info1, buf);
    } else {
        info2 = try ld.load(mem.terminate(args[2], 0));
        end = DynamicLoader.about.writeBinaryDifference(about_s, info1, info2, buf);
    }
    debug.write(buf[0..fmt.strlen(end, buf)]);
}
