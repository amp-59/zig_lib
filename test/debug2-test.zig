const top = @import("../zig_lib.zig");
const proc = top.proc;
const time = top.time;
const file = top.file;
const spec = top.spec;
const build = top.build;
const builtin = top.builtin;
pub usingnamespace proc.start;
comptime {
    _ = top.mach;
}
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
fn nested0(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @ptrToInt(&x);
    return nested5(y);
}
fn nested5(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z +% @ptrToInt(&x);
    return nested6(y);
}
fn nested6(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @ptrToInt(&x);
    if (y != 0) {
        nestedOOB(y);
    }
}
fn nestedOOB(x: u64) void {
    var buf: [512]u8 = undefined;
    buf[x] = 252;
}
fn nestedNOMEM(x: u64) void {
    var y: u64 = 0;
    y *= x;
    var buf: [512]u8 = undefined;
    buf[0..y][x] = 25;
}
pub export fn otherMain(x: u64) void {
    nested0(x) catch unreachable;
}
