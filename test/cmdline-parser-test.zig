const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const mach = zl.mach;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub fn main(args: anytype) void {
    @setRuntimeSafety(false);
    var allocator: mem.SimpleAllocator = .{};
    var cmd: build.BuildCommand = .{ .kind = .exe };
    var buf: []u8 = allocator.allocate(u8, 65536);
    cmd.formatParseArgs(&allocator, args);
    var len: usize = cmd.formatWriteBuf(builtin.root.zig_exe, &.{}, buf.ptr);

    var pos: usize = 0;
    for (buf[0..len], 0..) |byte, idx| {
        if (byte == 0) {
            debug.write(buf[pos..idx]);
            debug.write("\n");
            pos = idx +% 1;
        }
    }
}
