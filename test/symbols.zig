const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

export fn sayIt(string: [*:0]u8) void {
    zl.debug.write(zl.mem.terminate(string, 0));
}

export const the_line = "Hello, world!\n";
