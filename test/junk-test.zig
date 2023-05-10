const top = @import("../zig_lib.zig");
const proc = top.proc;
const testing = top.testing;

pub usingnamespace proc.start;

const print = testing.print;

pub fn main() !void {
    print(.{ '\n', "Hello,", " ", "World", "!", 42, '\n' });
}
