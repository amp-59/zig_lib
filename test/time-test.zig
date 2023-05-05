const zig_lib = @import("../zig_lib.zig");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const time = zig_lib.time;
const spec = zig_lib.spec;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

pub usingnamespace proc.start;

pub fn main() !void {
    var dt: time.DateTime = time.DateTime.init(1683108561);
    try builtin.expectEqual(u64, dt.getHour(), 10);
    try builtin.expectEqual(u64, dt.getMinute(), 9);
    try builtin.expectEqual(u64, dt.getSecond(), 21);
    try builtin.expectEqual(u64, dt.getMonthDay(), 3);
    try builtin.expectEqual(u64, dt.getMonth(), 5);
    try builtin.expectEqual(u64, dt.getYear(), 2023);

    const ts: time.TimeSpec = try time.get(.{}, .realtime);
    dt = time.DateTime.init(ts.sec);
    const pdt: time.PackedDateTime = dt.pack();

    try builtin.expectEqual(u64, dt.getHour(), pdt.getHour());
    try builtin.expectEqual(u64, dt.getMinute(), pdt.getMinute());
    try builtin.expectEqual(u64, dt.getSecond(), pdt.getSecond());
    try builtin.expectEqual(u64, dt.getWeekDay(), pdt.getWeekDay());
    try builtin.expectEqual(u64, dt.getMonthDay(), pdt.getMonthDay());
    try builtin.expectEqual(u64, dt.getMonth(), pdt.getMonth());
    try builtin.expectEqual(u64, dt.getYear(), pdt.getYear());
}
