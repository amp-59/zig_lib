const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const mem = zl.mem;
const spec = zl.spec;
const proc = zl.proc;
const mach = zl.mach;
const time = zl.time;
const builtin = zl.builtin;

pub usingnamespace proc.start;

pub const message_style = "\x1b[96;1m";

pub const signal_handlers = .{
    .SegmentationFault = false,
    .IllegalInstruction = false,
    .BusError = false,
    .FloatingPointError = false,
    .Trap = false,
};
const about = builtin.fmt.about("futex");

// Debug: Equal fastest build
// Debug: Worst performance
// Release: Worst performance
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
// Debug: Equal fastest build
// Debug: Best performance
// Release: Best performance
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
    //zigLibContainerWriteArray(&futex0, &futex1, count1, count2, ret);
    //zigLibContainerWriteSlices(&futex0, &futex1, count1, count2, ret);
    //zigLibBasicMessage(&futex0, &futex1, count1, count2, ret);
    zigLibOptimisedMessage(&futex0, &futex1, count1, count2, ret);
}
