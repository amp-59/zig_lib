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
    pub fn init(epoch_seconds: u64) DateTime {
        if (epoch_seconds < leap_epoch) {
            proc.exitGroupFault("TODO: Dates before epoch", 2);
        } else {
            @setRuntimeSafety(false);
            const secs: u64 = epoch_seconds - leap_epoch;
            const days: u64 = secs / 86_400;
            var rem_secs: u64 = secs % 86_400;
            var rem_days: u64 = days % days_per_400y;
            const qc_cycles: u64 = days / days_per_400y;
            const c_cycles: u64 = blk: {
                const cycles: u64 = rem_days / days_per_100y;
                break :blk cycles - builtin.int(u64, cycles == 4);
            };
            rem_days -%= c_cycles *% days_per_100y;
            const q_cycles: u64 = blk: {
                const cycles: u64 = rem_days / days_per_4y;
                break :blk cycles - builtin.int(u64, cycles == 25);
            };
            rem_days -%= q_cycles *% days_per_4y;
            const rem_years: u64 = blk: {
                const rem: u64 = rem_days / days_per_year;
                break :blk rem - builtin.int(u64, rem == 4);
            };
            rem_days -%= rem_years *% days_per_year;
            const years: u64 = rem_years +%
                (4 *% q_cycles) +% (100 *% c_cycles) +% (400 *% qc_cycles);
            const leap_day: u64 = blk: {
                const b0: bool = rem_years == 0;
                const b1: bool = builtin.int2v(bool, q_cycles != 0, c_cycles == 0);
                break :blk builtin.int2v(u64, b0, b1);
            };
            const year_day: u64 = blk: {
                const leap_days: u64 = rem_days +% 31 +% 28 +% leap_day;
                const leap_year: u64 = days_per_year +% leap_day;
                break :blk leap_days - bits.cmov64z(leap_year < leap_days, leap_year);
            };
            var months: u8 = 0;
            while (rem_days > days_in_month[months]) : (months +%= 1) {
                rem_days -%= days_in_month[months];
            }
            months -%= bits.cmov8z(months > 9, 12);
            const year: u64 = years +% builtin.int(u64, months > 9);
            return .{
                .yday = @intCast(year_day),
                .mday = @intCast(rem_days),
                .wday = @intCast((days +% 3) % 7),
                .mon = @intCast(months +% 2),
                .hour = @intCast(rem_secs / 3600),
                .min = @intCast((rem_secs / 60) % 60),
                .sec = @intCast(rem_secs % 60),
                .year = year,
            };
        }
    }
    pub fn pack(dt: DateTime) PackedDateTime {
        return .{
            .bits = bits.shl64(dt.year, 48) |
                bits.shl64(dt.wday, 45) | bits.shl64(dt.mon, 41) |
                bits.shl64(dt.yday, 32) | bits.shl64(dt.mday, 24) |
                bits.shl64(dt.hour, 16) | bits.shl64(dt.min, 8) |
                dt.sec,
        };
    }
};
pub const PackedDateTime = extern struct {
    bits: u64,
    pub fn getYear(pdt: PackedDateTime) u64 {
        return bits.shr64(pdt.bits, 48) + 2000;
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
    pub fn getMonth(pdt: PackedDateTime) u8 {
        return bits.shr64TM(u8, pdt.bits, 41, 4) + 1;
    }
    pub fn getWeekDay(pdt: PackedDateTime) u8 {
        return bits.shr64TM(u8, pdt.bits, 45, 3) + 1;
    }
    pub fn getMonthDay(pdt: PackedDateTime) u8 {
        return bits.shr64TM(u8, pdt.bits, 24, 5) + 1;
    }
    pub fn getYearDay(pdt: PackedDateTime) u16 {
        return bits.shr64TM(u16, pdt.bits, 32, 9) + 1;
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
