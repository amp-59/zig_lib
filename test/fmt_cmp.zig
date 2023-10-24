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
//const zl = @import("../zig_lib.zig");
const zl = struct {
    const mem = @import("../top/mem.zig");
    const fmt = @import("../top/fmt.zig");
    const debug = @import("../top/debug.zig");
    const start = @import("../top/start.zig");
};
pub usingnamespace zl.start;

pub const signal_handlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
};
const about = zl.fmt.about("futex");

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
    const std = @import("std");
    var buf: [4096]u8 = undefined;
    var fbu = std.io.fixedBufferStream(&buf);
    std.fmt.format(fbu.writer(), "{s}futex1=@0x{x}, word1={}, max1={}, futex2=@0x{x}, word2={}, max2={}, res={}\n", .{
        about, @intFromPtr(futex1), futex1.*, count1, @intFromPtr(futex2), futex2.*, count2, ret,
    }) catch {};
    zl.debug.write(fbu.buffer[0..fbu.pos]);
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
    var array: zl.mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeAny(zl.mem.spec.reinterpret.fmt, .{
        about,                            "futex1=@",
        zl.fmt.ux64(@intFromPtr(futex1)), ", word1=",
        zl.fmt.ud64(futex1.*),            ", max1=",
        zl.fmt.ud64(count1),              ", futex2=@",
        zl.fmt.ux64(@intFromPtr(futex2)), ", word2=",
        zl.fmt.ud64(futex2.*),            ", max2=",
        zl.fmt.ud64(count2),              ", res=",
        zl.fmt.ud64(ret),                 '\n',
    });
    zl.debug.write(array.readAll());
}
//fn zigLibContainerV2Formatter(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
//    var array: mem2.ctn.AutomaticStructuredReadWriteResize(.{ .child = u8, .count = 4096, .low_alignment = 1, .sentinel = null }) = undefined;
//    array.undefineAll();
//    array.writeAny(.{}, .{
//        about,                         "futex1=@",
//        fmt.ux64(@intFromPtr(futex1)), ", word1=",
//        fmt.ud64(futex1.*),            ", max1=",
//        fmt.ud64(count1),              ", futex2=@",
//        fmt.ux64(@intFromPtr(futex2)), ", word2=",
//        fmt.ud64(futex2.*),            ", max2=",
//        fmt.ud64(count2),              ", res=",
//        fmt.ud64(ret),                 '\n',
//    });
//    debug.write(array.readAll());
//}
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
    var array: zl.mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeMany(about);
    array.writeMany("futex1=@");
    array.writeFormat(zl.fmt.ux64(@intFromPtr(futex1)));
    array.writeMany(", word1=");
    array.writeFormat(zl.fmt.ud64(futex1.*));
    array.writeMany(", max1=");
    array.writeFormat(zl.fmt.ud64(count1));
    array.writeMany(", futex2=@");
    array.writeFormat(zl.fmt.ux64(@intFromPtr(futex2)));
    array.writeMany(", word2=");
    array.writeFormat(zl.fmt.ud64(futex2.*));
    array.writeMany(", max2=");
    array.writeFormat(zl.fmt.ud64(count2));
    array.writeMany(", res=");
    array.writeFormat(zl.fmt.ud64(ret));
    array.writeMany("\n");
    zl.debug.write(array.readAll());
}
/// build-exe:      test.fmt_cmp => ./zig-out/bin/test-fmt_cmp, ReleaseFast, stripped, exit=[updated] [1]
///      size:      2.117KiB
///         1:      .text: size=1.403KiB
///         2:      .bss: size=8B
///         3:      .comment: size=19B
///         4:      .shstrtab: size=31B
///      perf:      0.150s
///         0:      cycles		240,141,342
///         1:      instructions	247,805,504
///         2:      cache-references	22,079,486
///         3:      cache-misses	5,811,580
///         4:      branch-misses	2,343,267
///         0:      cpu-clock		247,479,840
///         1:      task-clock		243,930,840
///         2:      page-faults		6,547
/// futex:          futex1=@0x7ffe4104fa04, word1=240, max1=1, futex2=@0x7ffe4104fa00, word2=241, max2=0, res=2
/// build-run:      test.fmt_cmp, exit=0 [0]
///      perf:      0.000s
///         0:      cycles		2,011
///         1:      instructions	928
///         2:      cache-references	74
///         3:      cache-misses	2
///         4:      branch-misses	32
///         0:      cpu-clock		107,070
///         1:      task-clock		102,970
///         2:      page-faults		2
fn zigLibContainerWriteArrays(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    var array: zl.mem.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeCount(about.len, about.*);
    array.writeCount(8, "futex1=@".*);
    array.writeFormat(zl.fmt.ux64(@intFromPtr(futex1)));
    array.writeCount(8, ", word1=".*);
    array.writeFormat(zl.fmt.ud64(futex1.*));
    array.writeCount(7, ", max1=".*);
    array.writeFormat(zl.fmt.ud64(count1));
    array.writeCount(10, ", futex2=@".*);
    array.writeFormat(zl.fmt.ux64(@intFromPtr(futex2)));
    array.writeCount(8, ", word2=".*);
    array.writeFormat(zl.fmt.ud64(futex2.*));
    array.writeCount(7, ", max2=".*);
    array.writeFormat(zl.fmt.ud64(count2));
    array.writeCount(6, ", res=".*);
    array.writeFormat(zl.fmt.ud64(ret));
    array.writeCount(1, "\n".*);
    zl.debug.write(array.readAll());
}
//fn zigLibContainerV2WriteSlices(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
//    var array: mem2.ctn.AutomaticStructuredReadWriteResize(.{ .child = u8, .count = 4096 }) = undefined;
//    array.undefineAll();
//    array.writeMany(about);
//    array.writeMany("futex1=@");
//    array.writeFormat(fmt.ux64(@intFromPtr(futex1)));
//    array.writeMany(", word1=");
//    array.writeFormat(fmt.ud64(futex1.*));
//    array.writeMany(", max1=");
//    array.writeFormat(fmt.ud64(count1));
//    array.writeMany(", futex2=@");
//    array.writeFormat(fmt.ux64(@intFromPtr(futex2)));
//    array.writeMany(", word2=");
//    array.writeFormat(fmt.ud64(futex2.*));
//    array.writeMany(", max2=");
//    array.writeFormat(fmt.ud64(count2));
//    array.writeMany(", res=");
//    array.writeFormat(fmt.ud64(ret));
//    array.writeMany("\n");
//    debug.write(array.readAll());
//}
/// Debug: Equal fastest build
/// Debug: Best performance
/// Release: Best performance
///
/// build-exe:      test.fmt_cmp => ./zig-out/bin/test-fmt_cmp, ReleaseFast, stripped, exit=[updated] [1]
///      size:      2.117KiB(-568B) => 1.562KiB
///         2:      .text: addr=0x11170, size=1.403KiB(-656B) => 781B
///         3:      .bss: size=8B
///         4:      .comment: size=19B
///         5:      .shstrtab: size=31B(+8B) => 39B
///      perf:      0.129s
///         0:      cycles		143,067,107
///         1:      instructions	128,161,384
///         2:      cache-references	12,529,475
///         3:      cache-misses	3,760,978
///         4:      branch-misses	1,510,359
///         0:      cpu-clock		236,627,510
///         1:      task-clock		232,678,460
///         2:      page-faults		5,753
/// futex:          futex1=@0x7ffdafde0374, word1=240, max1=1, futex2=@0x7ffdafde0370, word2=241, max2=0, res=2
/// build-run:      test.fmt_cmp, exit=0 [0]
///      perf:      0.000s
///         0:      cycles		2,346
///         1:      instructions	824
///         2:      cache-references	68
///         3:      cache-misses	5
///         4:      branch-misses	27
///         0:      cpu-clock		91,580
///         1:      task-clock		88,140
///         2:      page-faults		3
fn zigLibOptimisedMessage(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var ux64: zl.fmt.Type.Ux64 = .{ .value = @intFromPtr(futex1) };
    var ud64: zl.fmt.Type.Ud64 = .{ .value = futex1.* };
    var bytes: [4096]u8 = undefined;
    var buf: [*]u8 = &bytes;
    @as(*[about.len]u8, @ptrCast(buf)).* = about.*;
    var len: usize = about.len;
    @as(*[8]u8, @ptrCast(buf + len)).* = "futex1=@".*;
    len +%= 8;
    len +%= ux64.formatWriteBuf(buf + len);
    @as(*[8]u8, @ptrCast(buf + len)).* = ", word1=".*;
    len +%= 8;
    len +%= ud64.formatWriteBuf(buf + len);
    @as(*[7]u8, @ptrCast(buf + len)).* = ", max1=".*;
    len +%= 7;
    ud64.value = count1;
    len +%= ud64.formatWriteBuf(buf + len);
    @as(*[10]u8, @ptrCast(buf + len)).* = ", futex2=@".*;
    len +%= 10;
    ux64.value = @intFromPtr(futex2);
    len +%= ux64.formatWriteBuf(buf + len);
    @as(*[8]u8, @ptrCast(buf + len)).* = ", word2=".*;
    len +%= 8;
    ud64.value = futex2.*;
    len +%= ud64.formatWriteBuf(buf + len);
    @as(*[7]u8, @ptrCast(buf + len)).* = ", max2=".*;
    len +%= 7;
    ud64.value = count2;
    len +%= ud64.formatWriteBuf(buf + len);
    @as(*[6]u8, @ptrCast(buf + len)).* = ", res=".*;
    len +%= 6;
    ud64.value = ret;
    len +%= ud64.formatWriteBuf(buf + len);
    buf[len] = '\n';
    zl.debug.write(buf[0 .. len +% 1]);
}
fn zigLibOptimisedMessage2(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var ux64: zl.fmt.Type.Ux64 = .{ .value = @intFromPtr(futex1) };
    var ud64: zl.fmt.Type.Ud64 = .{ .value = futex1.* };
    var buf: [4096]u8 = undefined;
    buf[0..about.len].* = about.*;
    var ptr: [*]u8 = buf[about.len..];
    ptr[0..8].* = "futex1=@".*;
    ptr += 8;
    ptr += ux64.formatWriteBuf(ptr);
    ptr[0..8].* = ", word1=".*;
    ptr += 8;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..7].* = ", max1=".*;
    ptr += 7;
    ud64.value = count1;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..10].* = ", futex2=@".*;
    ptr += 10;
    ux64.value = @intFromPtr(futex2);
    ptr += ux64.formatWriteBuf(ptr);
    ptr[0..8].* = ", word2=".*;
    ptr += 8;
    ud64.value = futex2.*;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..7].* = ", max2=".*;
    ptr += 7;
    ud64.value = count2;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0..6].* = ", res=".*;
    ptr += 6;
    ud64.value = ret;
    ptr += ud64.formatWriteBuf(ptr);
    ptr[0] = '\n';
    zl.debug.write(buf[0 .. (@intFromPtr(ptr) -% @intFromPtr(&buf)) +% 1]);
}
fn zigLibOptimisedMessage3(futex1: *u32, futex2: *u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    buf[0..about.len].* = about.*;
    var ptr: [*]u8 = buf[about.len..];
    ptr[0..8].* = "futex1=@".*;
    ptr += 8;
    ptr = zl.fmt.writeUx64(ptr, @intFromPtr(futex1));
    ptr[0..8].* = ", word1=".*;
    ptr += 8;
    ptr = zl.fmt.writeUx64(ptr, futex1.*);
    ptr[0..7].* = ", max1=".*;
    ptr += 7;
    ptr = zl.fmt.writeUd64(ptr, count1);
    ptr[0..10].* = ", futex2=@".*;
    ptr += 10;
    ptr = zl.fmt.writeUx64(ptr, @intFromPtr(futex2));
    ptr[0..8].* = ", word2=".*;
    ptr += 8;
    ptr = zl.fmt.writeUx64(ptr, futex2.*);
    ptr[0..7].* = ", max2=".*;
    ptr += 7;
    ptr = zl.fmt.writeUd64(ptr, count2);
    ptr[0..6].* = ", res=".*;
    ptr += 6;
    ptr = zl.fmt.writeUd64(ptr, ret);
    ptr[0] = '\n';
    zl.debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
}
pub fn main() void {
    var futex0: u32 = 0xf0;
    var futex1: u32 = 0xf1;
    var count1: u32 = 1;
    var count2: u32 = 0;
    var ret: u64 = 2;
    const import = @cImport({});
    if (@hasDecl(import, "std")) {
        standardLibFormatter(&futex0, &futex1, count1, count2, ret);
    } else if (@hasDecl(import, "zl")) {
        zigLibContainerFormatter(&futex0, &futex1, count1, count2, ret);
    } else if (@hasDecl(import, "arraySlice")) {
        zigLibContainerWriteSlices(&futex0, &futex1, count1, count2, ret);
    } else if (@hasDecl(import, "arrayCount")) {
        zigLibContainerWriteArrays(&futex0, &futex1, count1, count2, ret);
    } else if (@hasDecl(import, "O1")) {
        zigLibOptimisedMessage(&futex0, &futex1, count1, count2, ret);
    } else if (@hasDecl(import, "O2")) {
        zigLibOptimisedMessage2(&futex0, &futex1, count1, count2, ret);
    } else {
        zigLibOptimisedMessage3(&futex0, &futex1, count1, count2, ret);
    }
}
//
