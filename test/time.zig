const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const time = zl.time;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

const tab = @import("tab.zig");
pub const logging_override: debug.Logging.Override = debug.spec.logging.override.verbose;
pub const runtime_assertions: bool = true;
pub usingnamespace zl.start;
pub fn main() !void {
    var dt: time.DateTime = time.DateTime.init(1683108561);
    try debug.expectEqual(u64, dt.hour, 10);
    try debug.expectEqual(u64, dt.min, 9);
    try debug.expectEqual(u64, dt.sec, 21);
    try debug.expectEqual(u64, dt.mday, 3);
    try debug.expectEqual(time.Month, dt.mon, .May);
    try debug.expectEqual(u64, dt.year, 2023);
    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    dt = time.DateTime.init(ts.sec);
    dt = time.DateTime.init(0);
    try debug.expectEqual(usize, @intCast(dt.mday), 1);
    try debug.expectEqual(usize, @intCast(dt.year), 1970);
    try debug.expectEqual(usize, @intCast(dt.hour), 0);
    try debug.expectEqual(usize, @intCast(dt.min), 0);
    try debug.expectEqual(usize, @intCast(dt.sec), 0);
    try debug.expectEqual(time.Month, dt.mon, .January);
    try debug.expectEqual(time.Weekday, dt.wday, .Thursday);
    var buf: [4096]u8 = undefined;
    var len: usize = 0;
    for (tab.time_pairs) |pair| {
        len = fmt.dt(time.DateTime.init(pair[0])).formatWriteBuf(&buf);
        try testing.expectEqualString(pair[1], buf[0..len]);
    }
}
