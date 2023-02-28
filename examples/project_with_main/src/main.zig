const srg = @import("zig_lib");
const mem = srg.mem;
const proc = srg.proc;
const meta = srg.meta;
const builtin = srg.builtin;

// Use zl startup code to speed compilation and reduce binary size.
pub usingnamespace proc.start;

pub fn main(args: [:0][]u8, vars: [:0][]u8) !void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();

    builtin.debug.write("args:\n");
    var idx: u64 = 1;
    while (idx != args.len) : (idx +%= 1) {
        builtin.debug.write(args[idx]);
        builtin.debug.write("\n");
    }
    idx = 0;

    builtin.debug.write("vars:\n");
    while (idx != args.len) : (idx +%= 1) {
        builtin.debug.write(vars[idx]);
        builtin.debug.write("\n");
    }
}
