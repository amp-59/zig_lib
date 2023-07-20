const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const time = zl.time;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

pub const logging_override: debug.Logging.Override = spec.logging.override.verbose;

pub usingnamespace zl.start;

pub fn main() !void {
    var dt: time.DateTime = time.DateTime.init(1683108561);
    try debug.expectEqual(u64, dt.getHour(), 10);
    try debug.expectEqual(u64, dt.getMinute(), 9);
    try debug.expectEqual(u64, dt.getSecond(), 21);
    try debug.expectEqual(u64, dt.getMonthDay(), 3);
    try debug.expectEqual(u64, dt.getMonth(), 5);
    try debug.expectEqual(u64, dt.getYear(), 2023);

    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    dt = time.DateTime.init(ts.sec);
    const pdt: time.PackedDateTime = dt.pack();

    try debug.expectEqual(u64, dt.getHour(), pdt.getHour());
    try debug.expectEqual(u64, dt.getMinute(), pdt.getMinute());
    try debug.expectEqual(u64, dt.getSecond(), pdt.getSecond());
    try debug.expectEqual(u64, dt.getWeekDay(), pdt.getWeekDay());
    try debug.expectEqual(u64, dt.getMonthDay(), pdt.getMonthDay());
    try debug.expectEqual(u64, dt.getMonth(), pdt.getMonth());
    try debug.expectEqual(u64, dt.getYear(), pdt.getYear());
}
