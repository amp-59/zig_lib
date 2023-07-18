//! Control:
//! build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 624 bytes, 0.065s [0]
//! perf:           cycles		131,246,822
//! perf:           instructions	144,186,557
//! perf:           cache-references	8,106,756
//! perf:           cache-misses	1,770,227
//! perf:           branch-misses	1,127,291
//! perf:           cpu-clock		183,594,554
//! perf:           task-clock		179,082,099
//! perf:           page-faults		7,259
//! run:            perf, exit=0, 0.122s [0]
//! perf:           cycles		452
//! perf:           instructions	9
//! perf:           cache-references	28
//! perf:           cache-misses	25
//! perf:           branch-misses	2
//! perf:           cpu-clock		52,600
//! perf:           task-clock		50,470
//! perf:           page-faults		1
const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const mem = zl.mem;
const spec = zl.spec;
const proc = zl.proc;
const mach = zl.mach;
const time = zl.time;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const signal_handlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
};
const about = builtin.fmt.about("futex");

/// build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 624(+1584) => 2208 bytes, 0.197s [0]
/// perf:           cycles		530,416,380
/// perf:           instructions	598,895,286
/// perf:           cache-references	46,521,612
/// perf:           cache-misses	11,254,502
/// perf:           branch-misses	5,779,951
/// perf:           cpu-clock		309,958,313
/// perf:           task-clock		304,879,320
/// perf:           page-faults		8,719
/// run:            perf, exit=0, 0.225s [0]
/// perf:           cycles		2,080
/// perf:           instructions	611
/// perf:           cache-references	92
/// perf:           cache-misses	45
/// perf:           branch-misses	11
/// perf:           cpu-clock		76,500
/// perf:           task-clock		72,940
/// perf:           page-faults		3
fn standardLibFormatter(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    comptime _ = mach;
    const std = @import("std");
    var buf: [4096]u8 = undefined;
    var fbu = std.io.fixedBufferStream(&buf);
    std.fmt.format(fbu.writer(), "{s}futex1=@0x{x}, word1={}, max1={}, futex2=@0x{x}, word2={}, max2={}, res={}\n", .{
        about, @intFromPtr(futex1), futex1.*, count1, @intFromPtr(futex2), futex2.*, count2, ret,
    }) catch {};
    builtin.debug.write(fbu.buffer[0..fbu.pos]);
}
/// build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 2208(-144) => 2064 bytes, 0.186s [0]
/// perf:           cycles		517,930,037
/// perf:           instructions	615,558,402
/// perf:           cache-references	46,600,316
/// perf:           cache-misses	9,631,825
/// perf:           branch-misses	4,696,804
/// perf:           cpu-clock		302,816,120
/// perf:           task-clock		298,008,628
/// perf:           page-faults		8,426
/// run:            perf, exit=0, 0.230s [0]
/// perf:           cycles		1,737
/// perf:           instructions	574
/// perf:           cache-references	88
/// perf:           cache-misses	48
/// perf:           branch-misses	12
/// perf:           cpu-clock		79,470
/// perf:           task-clock		75,690
/// perf:           page-faults		3
fn zigLibContainerFormatter(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    var array: mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeAny(spec.reinterpret.fmt, .{
        about,                         "futex1=@",
        fmt.ux64(@intFromPtr(futex1)), ", word1=",
        fmt.ud64(futex1.*),            ", max1=",
        fmt.ud64(count1),              ", futex2=@",
        fmt.ux64(@intFromPtr(futex2)), ", word2=",
        fmt.ud64(futex2.*),            ", max2=",
        fmt.ud64(count2),              ", res=",
        fmt.ud64(ret),                 '\n',
    });
    builtin.debug.write(array.readAll());
}
/// build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 2064(+184) => 2248 bytes, 0.149s [0]
/// perf:           cycles		340,785,354
/// perf:           instructions	400,799,176
/// perf:           cache-references	28,501,272
/// perf:           cache-misses	6,252,746
/// perf:           branch-misses	3,268,673
/// perf:           cpu-clock		267,432,823
/// perf:           task-clock		262,182,302
/// perf:           page-faults		8,114
/// run:            perf, exit=0, 0.189s [0]
/// perf:           cycles		2,112
/// perf:           instructions	699
/// perf:           cache-references	107
/// perf:           cache-misses	55
/// perf:           branch-misses	27
/// perf:           cpu-clock		81,560
/// perf:           task-clock		78,320
/// perf:           page-faults		3
fn zigLibContainerWriteSlices(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    var array: mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeMany(about);
    array.writeMany("futex1=@");
    array.writeFormat(fmt.ux64(@intFromPtr(futex1)));
    array.writeMany(", word1=");
    array.writeFormat(fmt.ud64(futex1.*));
    array.writeMany(", max1=");
    array.writeFormat(fmt.ud64(count1));
    array.writeMany(", futex2=@");
    array.writeFormat(fmt.ux64(@intFromPtr(futex2)));
    array.writeMany(", word2=");
    array.writeFormat(fmt.ud64(futex2.*));
    array.writeMany(", max2=");
    array.writeFormat(fmt.ud64(count2));
    array.writeMany(", res=");
    array.writeFormat(fmt.ud64(ret));
    array.writeMany("\n");
    builtin.debug.write(array.readAll());
}
/// Debug: Equal fastest build
/// Debug: Worst performance
/// Release: Worst performance
///
/// build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 2248(-336) => 1912 bytes, 0.095s [0]
/// perf:           cycles		212,928,489
/// perf:           instructions	243,001,296
/// perf:           cache-references	14,988,114
/// perf:           cache-misses	3,529,613
/// perf:           branch-misses	2,007,214
/// perf:           cpu-clock		200,010,117
/// perf:           task-clock		195,777,735
/// perf:           page-faults		7,796
/// run:            perf, exit=0, 0.146s [0]
/// perf:           cycles		2,798
/// perf:           instructions	1,376
/// perf:           cache-references	129
/// perf:           cache-misses	45
/// perf:           branch-misses	34
/// perf:           cpu-clock		76,040
/// perf:           task-clock		71,780
/// perf:           page-faults		3
fn zigLibBasicMessage(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    const addr1_s: []const u8 = builtin.fmt.ux64(@intFromPtr(futex1)).readAll();
    const word1_s: []const u8 = builtin.fmt.ud64(futex1.*).readAll();
    const addr2_s: []const u8 = builtin.fmt.ux64(@intFromPtr(futex2)).readAll();
    const word2_s: []const u8 = builtin.fmt.ud64(futex2.*).readAll();
    const count1_s: []const u8 = builtin.fmt.ud64(count1).readAll();
    const count2_s: []const u8 = builtin.fmt.ud64(count2).readAll();
    const ret_s: []const u8 = builtin.fmt.ud64(ret).readAll();
    var buf: [4096]u8 = undefined;
    builtin.debug.logAlwaysAIO(&buf, &[_][]const u8{
        about,    "futex1=@", addr1_s,  ", word1=",
        word1_s,  ", max1=",  count1_s, ", futex2=@",
        addr2_s,  ", word2=", word2_s,  ", max2=",
        count2_s, ", res=",   ret_s,    "\n",
    });
}
/// Debug: Equal fastest build
/// Debug: Best performance
/// Release: Best performance
///
/// build-exe:      fmt_cmp_test, ReleaseFast, stripped, exit=[updated,0], 1912(-672) => 1240 bytes, 0.104s [0]
/// perf:           cycles		232,995,260
/// perf:           instructions	253,933,468
/// perf:           cache-references	18,027,332
/// perf:           cache-misses	4,348,917
/// perf:           branch-misses	2,307,413
/// perf:           cpu-clock		209,579,110
/// perf:           task-clock		205,246,128
/// perf:           page-faults		7,691
/// run:            perf, exit=0, 0.167s [0]
/// perf:           cycles		1,658
/// perf:           instructions	513
/// perf:           cache-references	72
/// perf:           cache-misses	30
/// perf:           branch-misses	15
/// perf:           cpu-clock		77,590
/// perf:           task-clock		73,380
/// perf:           page-faults		3
fn zigLibOptimisedMessage(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var fmt_ux64: fmt.Type.Ux64 = .{ .value = @intFromPtr(futex1) };
    var fmt_ud64: fmt.Type.Ud64 = .{ .value = futex1.* };
    var bytes: [4096]u8 = undefined;
    var buf: [*]u8 = &bytes;
    @as(*[about.len]u8, @ptrCast(buf)).* = about.*;
    var len: usize = about.len;
    @as(*[8]u8, @ptrCast(buf + len)).* = "futex1=@".*;
    len +%= 8;
    len +%= fmt_ux64.formatWriteBuf(buf + len);
    @as(*[8]u8, @ptrCast(buf + len)).* = ", word1=".*;
    len +%= 8;
    len +%= fmt_ud64.formatWriteBuf(buf + len);
    @as(*[7]u8, @ptrCast(buf + len)).* = ", max1=".*;
    len +%= 7;
    fmt_ud64.value = count1;
    len +%= fmt_ud64.formatWriteBuf(buf + len);
    @as(*[10]u8, @ptrCast(buf + len)).* = ", futex2=@".*;
    len +%= 10;
    fmt_ux64.value = @intFromPtr(futex2);
    len +%= fmt_ux64.formatWriteBuf(buf + len);
    @as(*[8]u8, @ptrCast(buf + len)).* = ", word2=".*;
    len +%= 8;
    fmt_ud64.value = futex2.*;
    len +%= fmt_ud64.formatWriteBuf(buf + len);
    @as(*[7]u8, @ptrCast(buf + len)).* = ", max2=".*;
    len +%= 7;
    fmt_ud64.value = count2;
    len +%= fmt_ud64.formatWriteBuf(buf + len);
    @as(*[6]u8, @ptrCast(buf + len)).* = ", res=".*;
    len +%= 6;
    fmt_ud64.value = ret;
    len +%= fmt_ud64.formatWriteBuf(buf + len);
    buf[len] = '\n';
    builtin.debug.write(buf[0 .. len +% 1]);
}
pub fn main() void {
    var futex0: u32 = 0xf0;
    var futex1: u32 = 0xf1;
    var count1: u32 = 1;
    var count2: u32 = 0;
    var ret: u64 = 2;
    //standardLibFormatter(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerFormatter(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerWriteSlices(&futex0, &futex1, count1, count2, ret);
    //zigLibBasicMessage(&futex0, &futex1, count1, count2, ret);
    zigLibOptimisedMessage(&futex0, &futex1, count1, count2, ret);
}
