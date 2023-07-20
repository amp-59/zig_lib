const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const debug = zl.debug;
const testing = zl.testing;

pub usingnamespace zl.start;

const print = testing.print;

pub fn main() !void {
    print(.{ '\n', "Hello,", " ", "World", "!", 42, '\n' });
}
