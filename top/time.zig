const sys = @import("./sys.zig");
const mach = @import("./mach.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub const TimeSpec = extern struct { sec: u64 = 0, nsec: u64 = 0 };
pub const MonotonicClock = enum { raw, coarse };
pub const RealClock = enum { alarm, coarse };
pub const BootClock = enum { alarm };
pub const CPUClock = enum { thread, process };

pub const days_in_month: [12]u8 = .{ 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, 31, 29 };
pub const days_per_year: u64 = 365;
pub const days_per_4y: u64 = (days_per_year * 4) + 1;
pub const days_per_400y: u64 = (days_per_year * 400) + 97;
pub const days_per_100y: u64 = (days_per_year * 100) + 24;
pub const leap_epoch: u64 = 946_684_800 + (86_400 * (31 + 29));

pub const Kind = enum(u64) {
    realtime = CLOCK.REALTIME,
    monotonic = CLOCK.MONOTONIC,
    process_cputime_id = CLOCK.PROCESS_CPUTIME_ID,
    thread_cputime_id = CLOCK.THREAD_CPUTIME_ID,
    monotonic_raw = CLOCK.MONOTONIC_RAW,
    realtime_coarse = CLOCK.REALTIME_COARSE,
    monotonic_coarse = CLOCK.MONOTONIC_COARSE,
    boottime = CLOCK.BOOTTIME,
    realtime_alarm = CLOCK.REALTIME_ALARM,
    boottime_alarm = CLOCK.BOOTTIME_ALARM,
    tai = CLOCK.TAI,
    const CLOCK = sys.CLOCK;
};
pub const Month = enum {
    January,
    February,
    March,
    April,
    May,
    June,
    July,
    August,
    September,
    October,
    November,
    December,
};
pub const ClockSpec = struct {
    errors: sys.ErrorPolicy = .{ .throw = sys.clock_get_errors },
};
pub fn get(comptime clock_spec: ClockSpec, kind: Kind) sys.Call(clock_spec.errors.throw, TimeSpec) {
    var ts: TimeSpec = undefined;
    if (meta.wrap(sys.call(.clock_gettime, clock_spec.errors, void, .{ @enumToInt(kind), @ptrToInt(&ts) }))) {
        return ts;
    } else |clock_error| {
        return clock_error;
    }
}
pub fn nanoSleepB(req: TimeSpec) !void {
    try sys.nanosleep(@ptrToInt(&req), 0);
}
pub fn nanoSleepA(req: TimeSpec) !TimeSpec {
    var rem: TimeSpec = undefined;
    try sys.nanosleep(@ptrToInt(&req), @ptrToInt(&rem));
    return rem;
}
const SleepSpec = struct {
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = sys.nanosleep_errors },
    pub usingnamespace sys.FunctionInterfaceSpec(SleepSpec);
};
pub fn sleep(comptime spec: SleepSpec, ts: TimeSpec) sys.Call(spec.errors.throw, void) {
    spec.call(.nanosleep, .{ @ptrToInt(&ts), 0 }) catch |nanosleep_error| {
        return nanosleep_error;
    };
}
pub fn diff(arg1: TimeSpec, arg2: TimeSpec) TimeSpec {
    var ret: TimeSpec = .{
        .sec = arg1.sec -% arg2.sec,
        .nsec = arg1.nsec -% arg2.nsec,
    };
    const j: bool = ret.nsec >= 1_000_000_000;
    ret.sec -%= mach.cmov64z(j, 1);
    ret.nsec +%= mach.cmov64z(j, 1_000_000_000);
    return ret;
}
pub const DateTime = extern struct {
    sec: u8,
    min: u8,
    hour: u8,
    mday: u8,
    wday: u8,
    mon: u8,
    yday: u16,
    year: u64,
    pub fn getSecond(dt: DateTime) u8 {
        return dt.sec;
    }
    pub fn getMinute(dt: DateTime) u8 {
        return dt.min;
    }
    pub fn getHour(dt: DateTime) u8 {
        return dt.hour;
    }
    pub fn getYear(dt: DateTime) u64 {
        return dt.year + 2000;
    }
    pub fn getMonth(dt: DateTime) u8 {
        return dt.mon + 1;
    }
    pub fn getWeekDay(dt: DateTime) u8 {
        return dt.wday + 1;
    }
    pub fn getMonthDay(dt: DateTime) u8 {
        return dt.mday + 1;
    }
    pub fn getYearDay(dt: DateTime) u16 {
        return dt.yday + 1;
    }
    pub inline fn init(epoch_seconds: u64) DateTime {
        if (epoch_seconds < leap_epoch) {
            builtin.debug.logFault("TODO: Dates before epoch");
        } else {
            const secs: u64 = epoch_seconds - leap_epoch;
            const days: u64 = secs / 86_400;
            var rem_secs: u64 = secs % 86_400;
            var rem_days: u64 = days % days_per_400y;
            const qc_cycles: u64 = days / days_per_400y;
            const c_cycles: u64 = blk: {
                const cycles: u64 = rem_days / days_per_100y;
                break :blk cycles - builtin.int(u64, cycles == 4);
            };
            rem_days -= c_cycles * days_per_100y;
            const q_cycles: u64 = blk: {
                const cycles: u64 = rem_days / days_per_4y;
                break :blk cycles - builtin.int(u64, cycles == 25);
            };
            rem_days -= q_cycles * days_per_4y;
            const rem_years: u64 = blk: {
                const rem: u64 = rem_days / days_per_year;
                break :blk rem - builtin.int(u64, rem == 4);
            };
            rem_days -= rem_years * days_per_year;
            const years: u64 = rem_years +
                (4 * q_cycles) + (100 * c_cycles) + (400 * qc_cycles);
            const leap_day: u64 = blk: {
                const b0: bool = rem_years == 0;
                const b1: bool = builtin.int2v(bool, q_cycles != 0, c_cycles == 0);
                break :blk builtin.int2v(u64, b0, b1);
            };
            const year_day: u64 = blk: {
                const leap_days: u64 = rem_days + 31 + 28 + leap_day;
                const leap_year: u64 = days_per_year + leap_day;
                break :blk leap_days - mach.cmov64z(leap_year < leap_days, leap_year);
            };
            var months: u8 = 0;
            while (rem_days > days_in_month[months]) : (months += 1) {
                rem_days -= days_in_month[months];
            }
            months -%= mach.cmov8z(months > 9, 12);
            const year: u64 = years + builtin.int(u64, months > 9);
            return .{
                .yday = @intCast(u16, year_day),
                .mday = @intCast(u8, rem_days),
                .wday = @intCast(u8, (days + 3) % 7),
                .mon = @intCast(u8, months +% 2),
                .hour = @intCast(u8, rem_secs / 3600),
                .min = @intCast(u8, (rem_secs / 60) % 60),
                .sec = @intCast(u8, rem_secs % 60),
                .year = year,
            };
        }
    }
};
