const top = @import("../zig_lib.zig");
const proc = top.proc;
const builtin = top.builtin;

extern fn otherMain(x: u64) void;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = .{};

pub const trace = .{};

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
