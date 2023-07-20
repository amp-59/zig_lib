const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const debug = zl.debug;
const builtin = zl.builtin;

extern fn otherMain(x: u64) void;

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = .{};

pub const trace = builtin.my_trace;

fn nested0(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @intFromPtr(&x);
    return otherMain(y);
}
pub fn main() !void {
    var b: bool = true;
    if (b) {
        try nested0(8);
    } else {
        otherMain(8);
    }
}
