const zl = struct {
    const mem2 = @import("../top/mem/ctn.zig");
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
fn standardLibFormatter(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    const std = @import("std");
    var buf: [4096]u8 = undefined;
    var fbu = std.io.fixedBufferStream(&buf);
    std.fmt.format(fbu.writer(), "{s}futex1=@0x{x}, word1={}, max1={}, futex2=@0x{x}, word2={}, max2={}, res={}\n", .{
        about, @intFromPtr(futex1), futex1.*, count1, @intFromPtr(futex2), futex2.*, count2, ret,
    }) catch {};
    zl.debug.write(fbu.buffer[0..fbu.pos]);
}
fn zigLibContainerFormatter(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    var array: zl.mem.array.StaticArray(u8, 4096) = undefined;
    array.undefineAll();
    array.writeAny(zl.mem.array.spec.reinterpret.fmt, .{
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
fn zigLibContainerWriteSlices(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    var array: zl.mem.array.StaticArray(u8, 4096) = undefined;
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
fn zigLibContainerWriteArrays(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    var array: zl.mem.array.StaticArray(u8, 4096) = undefined;
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
fn zigLibContainerV2WriteSlices(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    var array: zl.mem2.AutomaticStructuredReadWriteResize(.{
        .child = u8,
        .count = 4096,
        .low_alignment = 1,
        .sentinel = null,
    }) = undefined;
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
fn zigLibOptimisedMessage(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var ux64: zl.fmt.Ux64 = .{ .value = @intFromPtr(futex1) };
    var ud64: zl.fmt.Ud64 = .{ .value = futex1.* };
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
fn zigLibOptimisedMessage2(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var ux64: zl.fmt.Ux64 = .{ .value = @intFromPtr(futex1) };
    var ud64: zl.fmt.Ud64 = .{ .value = futex1.* };
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
/// This technique is better for every measurement in every build mode.
fn zigLibOptimisedMessage3(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    buf[0..about.len].* = about.*;
    var ptr: [*]u8 = buf[about.len..];
    ptr[0..8].* = "futex1=@".*;
    ptr = zl.fmt.Ux64.write(ptr + 8, @intFromPtr(futex1));
    ptr[0..8].* = ", word1=".*;
    ptr = zl.fmt.Ud64.write(ptr + 8, futex1.*);
    ptr[0..7].* = ", max1=".*;
    ptr = zl.fmt.Ud64.write(ptr + 7, count1);
    ptr[0..10].* = ", futex2=@".*;
    ptr = zl.fmt.Ux64.write(ptr + 10, @intFromPtr(futex2));
    ptr[0..8].* = ", word2=".*;
    ptr = zl.fmt.Ud64.write(ptr + 8, futex2.*);
    ptr[0..7].* = ", max2=".*;
    ptr = zl.fmt.Ud64.write(ptr + 7, count2);
    ptr[0..6].* = ", res=".*;
    ptr = zl.fmt.Ud64.write(ptr + 6, ret);
    ptr[0] = '\n';
    zl.debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
}
/// This program will execute ~8% fewer instructions, but is difficult to write,
/// and takes longer to compile.
fn zigLibOptimisedMessage4(futex1: *const u32, futex2: *const u32, count1: u32, count2: u32, ret: u64) void {
    @setRuntimeSafety(false);
    var buf: [4096]u8 = undefined;
    var buf1: [16]u8 = undefined;
    var buf2: [16]u8 = undefined;
    var buf3: [16]u8 = undefined;
    var buf4: [16]u8 = undefined;
    var buf5: [16]u8 = undefined;
    var buf6: [16]u8 = undefined;
    var buf7: [16]u8 = undefined;
    const end1: [*]u8 = zl.fmt.Ux64.write(&buf1, @intFromPtr(futex1));
    const end4: [*]u8 = zl.fmt.Ux64.write(&buf4, @intFromPtr(futex2));
    const end2: [*]u8 = zl.fmt.Ud64.write(&buf2, futex1.*);
    const end5: [*]u8 = zl.fmt.Ud64.write(&buf5, futex2.*);
    const end3: [*]u8 = zl.fmt.Ud64.write(&buf3, count1);
    const end6: [*]u8 = zl.fmt.Ud64.write(&buf6, count2);
    const end7: [*]u8 = zl.fmt.Ud64.write(&buf7, ret);
    buf[0..about.len].* = about.*;
    var ptr: [*]u8 = buf[about.len..];
    if (@import("builtin").mode == .Debug) {
        ptr[0..8].* = "futex1=@".*;
        ptr[8..24].* = buf1;
        ptr += @intFromPtr(end1 + 8) -% @intFromPtr(&buf1);
        ptr[0..8].* = ", word1=".*;
        ptr[8..24].* = buf2;
        ptr += @intFromPtr(end2 + 8) -% @intFromPtr(&buf2);
        ptr[0..7].* = ", max1=".*;
        ptr[7..23].* = buf3;
        ptr += @intFromPtr(end3 + 7) -% @intFromPtr(&buf3);
        ptr[0..10].* = ", futex2=@".*;
        ptr[10..26].* = buf4;
        ptr += @intFromPtr(end4 + 10) -% @intFromPtr(&buf4);
        ptr[0..8].* = ", word2=".*;
        ptr[8..24].* = buf5;
        ptr += @intFromPtr(end5 + 8) -% @intFromPtr(&buf5);
        ptr[0..7].* = ", max2=".*;
        ptr[7..23].* = buf6;
        ptr += @intFromPtr(end6 + 7) -% @intFromPtr(&buf6);
        ptr[0..6].* = ", res=".*;
        ptr[6..22].* = buf7;
        ptr += @intFromPtr(end7 + 7) -% @intFromPtr(&buf7);
    } else {
        ptr[0..24].* = ("futex1=@" ++ buf1).*;
        ptr += @intFromPtr(end1 + 8) -% @intFromPtr(&buf1);
        ptr[0..24].* = (", word1=" ++ buf2).*;
        ptr += @intFromPtr(end2 + 8) -% @intFromPtr(&buf2);
        ptr[0..23].* = (", max1=" ++ buf3).*;
        ptr += @intFromPtr(end3 + 7) -% @intFromPtr(&buf3);
        ptr[0..26].* = (", futex2=@" ++ buf4).*;
        ptr += @intFromPtr(end4 + 10) -% @intFromPtr(&buf4);
        ptr[0..24].* = (", word2=" ++ buf5).*;
        ptr += @intFromPtr(end5 + 8) -% @intFromPtr(&buf5);
        ptr[0..23].* = (", max2=" ++ buf6).*;
        ptr += @intFromPtr(end6 + 7) -% @intFromPtr(&buf6);
        ptr[0..22].* = (", res=" ++ buf7).*;
        ptr += @intFromPtr(end7 + 6) -% @intFromPtr(&buf7);
    }
    ptr[0] = '\n';
    zl.debug.write(buf[0..(@intFromPtr(ptr + 1) -% @intFromPtr(&buf))]);
}
pub fn main() void {
    const futex0: u32 = 0xf0;
    const futex1: u32 = 0xf1;
    const count1: u32 = 1;
    const count2: u32 = 0;
    const ret: u64 = 2;
    //standardLibFormatter(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerFormatter(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerWriteSlices(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerWriteArrays(&futex0, &futex1, count1, count2, ret);
    //zigLibOptimisedMessage(&futex0, &futex1, count1, count2, ret);
    //zigLibOptimisedMessage2(&futex0, &futex1, count1, count2, ret);
    zigLibOptimisedMessage3(&futex0, &futex1, count1, count2, ret);
    //zigLibOptimisedMessage4(&futex0, &futex1, count1, count2, ret);
}
