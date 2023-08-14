const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const debug = zl.debug;
const builtin = zl.builtin;

extern fn otherMain(x: u64) void;

pub usingnamespace zl.start;

pub const logging_default: debug.Logging.Default = zl.spec.logging.default.silent;
pub const trace = builtin.my_trace;

pub const want_stack_traces: bool = true;

fn nested0(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @intFromPtr(&x);
    return otherMain(y);
}
pub fn main() !void {
    var x: usize = 0;
    try nested0(x);
    x -= 1;
}
