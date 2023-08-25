const zl = @import("../zig_lib.zig");

pub usingnamespace zl.start;

export fn sayIt(string: [*:0]u8) void {
    zl.debug.write(string);
}

export const the_line = "Hello, world!\n";
