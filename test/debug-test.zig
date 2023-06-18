const top = @import("../zig_lib.zig");
const proc = top.proc;
const time = top.time;
const file = top.file;
const spec = top.spec;
const build = top.build;
const builtin = top.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
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
        //nestedNOMEM(y);
    }
}
fn nestedOOB(x: u64) void {
    _ = x;
    otherMain();
}
fn nestedNOMEM(x: u64) void {
    var y: u64 = 0;
    y *= x;
    var buf: [512]u8 = undefined;
    buf[0..y][x] = 25;
}

extern fn otherMain() void;

pub fn main() !void {
    var b: bool = true;
    if (b) {
        try nested0(8);
    } else {
        otherMain();
    }
}
