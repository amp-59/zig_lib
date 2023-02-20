const srg = @import("zig_lib");
const proc = srg.proc;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub fn main(args: anytype) u8 {
    if (args.len == 0) {
        return 0;
    }
    return builtin.parse.any(u8, args[1]) catch 255;
}
