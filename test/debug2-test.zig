const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const time = zl.time;
const file = zl.file;
const spec = zl.spec;
const build = zl.build;
const builtin = zl.builtin;

const root = @import("./debug-test.zig");

pub usingnamespace zl.start;

pub const trace: builtin.Trace = root.trace;
pub const have_stack_traces: bool = true;

fn nested0(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @intFromPtr(&x);
    return nested5(y);
}
fn nested5(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z +% @intFromPtr(&x);
    return nested6(y);
}
fn nested6(z: u64) !void {
    var x: u64 = 0;
    const y: u64 = z + @intFromPtr(&x);
    if (y != 0) {
        nestedOOB(y);
    }
}
fn nestedOOB(x: u64) void {
    var buf: [512]u8 = undefined;
    @as(*align(1) u16, @ptrCast(&buf[x])).* = 252;
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
