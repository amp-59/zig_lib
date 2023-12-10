const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const logging_override = zl.debug.spec.logging.override.silent;
const MirrorCache = zl.cache.GenericMirrorCache(.{ .AddressSpace = zl.mem.spec.address_space.exact_8 });
pub fn main(args: [][*:0]u8) !void {
    var mirror: MirrorCache = undefined;
    zl.mem.zero(MirrorCache, &mirror);
    if (try mirror.scan(
        try zl.file.openAt(.{}, .{}, zl.file.cwd, zl.mem.terminate(args[2], 0)),
        zl.mem.terminate(args[3], 0),
        zl.mem.terminate(args[5], 0),
    )) {
        zl.debug.write("OK\n");
    }
}
