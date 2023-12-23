const zl = @import("../../zig_lib.zig");
pub usingnamespace zl.start;
const do_it: bool = true;
pub const want_stack_traces = false;
pub const panic_return_value: u8 = 0;
pub const logging_override: zl.debug.Logging.Override = .{
    .Attempt = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Success = true,
    .Fault = true,
};
pub const logging_default: zl.debug.Logging.Default = .{
    .Attempt = true,
    .Acquire = true,
    .Release = true,
    .Error = true,
    .Success = true,
    .Fault = true,
};
fn causePanicSentinelMismatch() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        var a: [4096]u8 = undefined;
        const c: [:0]u8 = a[0..512 :0];
        c[256] = 'b';
    }
}
fn causePanicSentinelMismatchNonScalarSentinel() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        const S = struct { x: usize = 0 };
        var a: [256:.{}]S = undefined;
        a[0] = .{ .x = 25 };
        a[1] = .{};
        const c: u8 = @intCast(a[0..2 :.{}][0].x);
        _ = c;
    }
}
fn causePanicReachedUnreachable() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        var x: u64 = 0;
        x = 0x10000;
        var y: u64 = 0;
        y = 0x10010;
        if (x < y) {
            unreachable;
        }
    }
}
fn causePanicInactiveUnionField() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        var u: union(enum(u8)) {
            a: u64 = 0,
            b: u32 = 1,
        } = .{ .a = 25 };
        u.a = u.b;
    }
}
fn causePanicUnwrapError(err: anyerror, idx: usize) void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        if (idx != 5) {
            causePanicUnwrapError(err, idx +% 1);
            err catch unreachable;
        }
    }
}
fn causePanicStartGreaterThanEnd() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        var a: [512]u8 = undefined;
        const s: []u8 = a[@intFromPtr(&a)..256];
        s[0] = 'a';
    }
}
fn causePanicOutOfBounds() void {
    var b: bool = zl.mem.unstable(bool, false);
    b = do_it;
    if (b) {
        var a: [512]u8 = undefined;
        var idx: usize = 0;
        idx = 512;
        a[idx] = 'a';
    }
}
pub fn main() void {
    //var b: bool = zl.mem.unstable(bool, true);
    //if (b) {
    @import("stack_overflow.zig").main();
    causePanicSentinelMismatchNonScalarSentinel();
    causePanicOutOfBounds();
    causePanicInactiveUnionField();
    causePanicReachedUnreachable();
    causePanicSentinelMismatch();
    causePanicStartGreaterThanEnd();
    causePanicUnwrapError(error.Which, 1);
    //}
}
