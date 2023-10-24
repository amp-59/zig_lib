const sys = @import("./sys.zig");
const bits = @import("./bits.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");
pub const TimeSpec = extern struct {
    sec: u64 = 0,
    nsec: u64 = 0,
};
pub const TimeVal = extern struct {
    sec: u64 = 0,
    usec: u64 = 0,
};
pub const TimeZone = extern struct {
    mins: u32 = 0,
    dst: u32 = 0,
};
pub const Weekday = enum(u8) {
    Sunday = 0,
    Monday = 1,
    Tuesday = 2,
    Wednesday = 3,
    Thursday = 4,
    Friday = 5,
    Saturday = 6,
};
pub const MonotonicClock = enum { raw, coarse };
pub const RealClock = enum { alarm, coarse };
pub const BootClock = enum { alarm };
pub const CPUClock = enum { thread, process };
pub const days_in_month: [12]u8 = .{ 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, 31, 29 };
pub const days_per_year = 365;
pub const days_per_4y = (days_per_year * 4) + 1;
pub const days_per_400y = (days_per_year * 400) + 97;
pub const days_per_100y = (days_per_year * 100) + 24;
pub const secs_per_hour = 3600;
pub const secs_per_day = 86400;
pub const leap_epoch = 946_684_800 + (86_400 * (31 + 29));
pub const ns_per_us = 1000;
pub const ns_per_ms = 1000 * ns_per_us;
pub const ns_per_s = 1000 * ns_per_ms;
pub const ns_per_min = 60 * ns_per_s;
pub const ns_per_hour = 60 * ns_per_min;
pub const ns_per_day = 24 * ns_per_hour;
pub const ns_per_week = 7 * ns_per_day;
pub const us_per_ms = 1000;
pub const us_per_s = 1000 * us_per_ms;
pub const us_per_min = 60 * us_per_s;
pub const us_per_hour = 60 * us_per_min;
pub const us_per_day = 24 * us_per_hour;
pub const us_per_week = 7 * us_per_day;
pub const ms_per_s = 1000;
pub const ms_per_min = 60 * ms_per_s;
pub const ms_per_hour = 60 * ms_per_min;
pub const ms_per_day = 24 * ms_per_hour;
pub const ms_per_week = 7 * ms_per_day;
pub const s_per_min = 60;
pub const s_per_hour = s_per_min * 60;
pub const s_per_day = s_per_hour * 24;
pub const s_per_week = s_per_day * 7;
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
pub const Month = enum(u8) {
    January = 1,
    February = 2,
    March = 3,
    April = 4,
    May = 5,
    June = 6,
    July = 7,
    August = 8,
    September = 9,
    October = 10,
    November = 11,
    December = 12,
};
pub const ClockSpec = struct {
    return_type: type = TimeSpec,
    errors: sys.ErrorPolicy = .{ .throw = spec.clock_get.errors.all },
};
pub const ClockGetTime = *fn (Kind, *TimeSpec) u64;
pub const GetTimeOfDay = *fn (*TimeVal, *TimeZone) u64;
pub fn get(comptime clock_spec: ClockSpec, kind: Kind) sys.ErrorUnion(clock_spec.errors, TimeSpec) {
    var ts: TimeSpec = undefined;
    if (meta.wrap(sys.call(.clock_gettime, clock_spec.errors, void, .{ @intFromEnum(kind), @intFromPtr(&ts) }))) {
        return ts;
    } else |clock_error| {
        return clock_error;
    }
}
pub const SleepSpec = struct {
    return_type: type = void,
    errors: sys.ErrorPolicy = .{ .throw = spec.nanosleep.errors.all },
};
pub fn sleep(comptime sleep_spec: SleepSpec, ts: TimeSpec) sys.ErrorUnion(sleep_spec.errors, void) {
    meta.wrap(sys.call(.nanosleep, sleep_spec.errors, sleep_spec.return_type, .{ @intFromPtr(&ts), 0 })) catch |nanosleep_error| {
        return nanosleep_error;
    };
}
pub fn diff(arg1: TimeSpec, arg2: TimeSpec) TimeSpec {
    var ret: TimeSpec = .{
        .sec = arg1.sec -% arg2.sec,
        .nsec = arg1.nsec -% arg2.nsec,
    };
    const j: bool = ret.nsec >= 1_000_000_000;
    ret.sec -%= bits.cmov64z(j, 1);
    ret.nsec +%= bits.cmov64z(j, 1_000_000_000);
    return ret;
}
pub const DateTime = packed struct {
    sec: u8,
    min: u8,
    hour: u8,
    mday: u8,
    yday: u16,
    year: u64,
    wday: Weekday,
    mon: Month,
    pub fn init(epoch_seconds: usize) DateTime {
        var secs: isize = @bitCast(epoch_seconds);
        secs -%= leap_epoch;
        var days: isize = @divTrunc(secs, secs_per_day);
        var remsecs: isize = @truncate(@rem(secs, secs_per_day));
        if (remsecs < 0) {
            remsecs +%= secs_per_day;
            days -%= 1;
        }
        var remdays: isize = @truncate(@rem(days, days_per_400y));
        var wday: isize = @truncate(@rem(3 +% days, 7));
        if (wday < 0) {
            wday +%= 7;
        }
        var qc_cycles: isize = @divTrunc(days, days_per_400y);
        if (remdays < 0) {
            remdays +%= days_per_400y;
            qc_cycles -%= 1;
        }
        var c_cycles: isize = @divTrunc(remdays, days_per_100y);
        if (c_cycles == 4) {
            c_cycles -%= 1;
        }
        remdays -%= c_cycles *% days_per_100y;
        var q_cycles: isize = @divTrunc(remdays, days_per_4y);
        if (q_cycles == 25) {
            q_cycles -%= 1;
        }
        remdays -%= q_cycles *% days_per_4y;
        var remyears: isize = @divTrunc(remdays, days_per_year);
        if (remyears == 4) {
            remyears -%= 1;
        }
        remdays -%= remyears *% days_per_year;
        var leap: isize = @intFromBool(!(remyears != 0) and ((q_cycles != 0) or !(c_cycles != 0)));
        var yday: isize = remdays +% 59 +% leap;
        if (yday >= days_per_year +% leap) {
            yday -%= days_per_year +% leap;
        }
        var years: isize = (remyears +% (4 *% q_cycles) +% (100 *% c_cycles)) +% (400 *% qc_cycles);
        var months: usize = 0;
        while (days_in_month[months] <= remdays) : (months +%= 1) {
            remdays -%= days_in_month[months];
        }
        if (months >= 10) {
            months -%= 12;
            years +%= 1;
        }
        return .{
            .year = @intCast(years +% 2000),
            .mon = @enumFromInt(months +% 3),
            .mday = @intCast(remdays +% 1),
            .wday = @enumFromInt(wday),
            .yday = @intCast(yday),
            .hour = @intCast(@divTrunc(remsecs, secs_per_hour)),
            .min = @intCast(@rem(@divTrunc(remsecs, 60), 60)),
            .sec = @intCast(@rem(remsecs, 60)),
        };
    }
};
pub const PackedDateTime = extern struct {
    bits: u64,
    pub fn getYear(pdt: PackedDateTime) u64 {
        return bits.shr64(pdt.bits, 48) +% 1900;
    }
    pub fn getSecond(pdt: PackedDateTime) u8 {
        return bits.mask8L(pdt.bits);
    }
    pub fn getMinute(pdt: PackedDateTime) u8 {
        return bits.shr64T(u8, pdt.bits, 8);
    }
    pub fn getHour(pdt: PackedDateTime) u8 {
        return bits.shr64TM(u8, pdt.bits, 16, 5);
    }
    pub fn getMonthDay(pdt: PackedDateTime) u8 {
        return bits.shr64TM(u8, pdt.bits, 24, 5);
    }
    pub fn getYearDay(pdt: PackedDateTime) u16 {
        return bits.shr64TM(u16, pdt.bits, 32, 9) +% 1;
    }
    pub fn getMonth(pdt: PackedDateTime) Month {
        return @enumFromInt(bits.shr64TM(u8, pdt.bits, 41, 4) +% 1);
    }
    pub fn getWeekDay(pdt: PackedDateTime) Weekday {
        return @enumFromInt(bits.shr64TM(u8, pdt.bits, 45, 3));
    }
    pub fn unpack(pdt: PackedDateTime) DateTime {
        return .{
            .sec = pdt.getSecond(),
            .min = pdt.getMinute(),
            .hour = pdt.getHour(),
            .mday = pdt.getMonthDay(),
            .wday = pdt.getWeekDay(),
            .mon = pdt.getMonth(),
            .yday = pdt.getYearDay(),
            .year = pdt.getYear(),
        };
    }
};
pub const spec = struct {
    pub const nanosleep = struct {
        pub const errors = struct {
            pub const all = &.{
                .INTR, .FAULT, .INVAL, .OPNOTSUPP,
            };
        };
    };
    pub const clock_get = struct {
        pub const errors = struct {
            pub const all = &.{ .ACCES, .FAULT, .INVAL, .NODEV, .OPNOTSUPP, .PERM };
        };
    };
};
