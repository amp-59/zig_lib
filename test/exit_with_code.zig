const zl = @import("zig_lib");
const proc = zl.proc;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub fn main(args: anytype) u8 {
    if (args.len == 0) {
        return 0;
    }
    return builtin.parse.any(u8, args[1]) catch 255;
}
