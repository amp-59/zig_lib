const top = @import("../zig_lib.zig");
const proc = top.proc;
const time = top.time;
const file = top.file;
const spec = top.spec;
const build = top.build;
const builtin = top.builtin;

pub usingnamespace proc.start;

//pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
pub const runtime_assertions: bool = false;
pub const signal_handlers: builtin.SignalHandlers = .{
    .SegmentationFault = true,
    .BusError = true,
    .IllegalInstruction = true,
    .FloatingPointError = true,
    .Trap = true,
};
pub const discard_errors = true;
extern fn otherMain(x: u64) void;

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
