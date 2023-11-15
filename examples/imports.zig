const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;

pub const signal_handlers: zl.debug.SignalHandlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
};

pub fn main(args: [][*:0]u8) !void {
    var mirror: zl.cache.GenericMirrorCache(.{ .AddressSpace = zl.mem.spec.address_space.exact_8 }) = .{};

    const build_root: [:0]const u8 = zl.mem.terminate(args[2], 0);
    const cache_root: [:0]const u8 = zl.mem.terminate(args[3], 0);
    const pathname: [:0]const u8 = zl.mem.terminate(args[5], 0);

    const build_root_fd: usize = try zl.file.openAt(.{}, .{}, zl.file.cwd, build_root);

    if (try mirror.scan(build_root, build_root_fd, cache_root, pathname)) {
        zl.debug.write("OK\n");
    }
}
