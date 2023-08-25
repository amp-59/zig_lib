const zl = @import("../../zig_lib.zig");

pub usingnamespace zl.start;
const debug = zl.debug;

pub const runtime_assertions: bool = true;

pub fn main() !void {
    var slice_u8: []const u8 = &.{};
    var slice_u16: []const u16 = &.{};
    var slice_u32: []const u32 = &.{};
    var slice_usize: []const usize = &.{};
    const struct_u8 = @as(*const struct { usize, usize }, @ptrCast(&slice_u8));
    const struct_u16 = @as(*const struct { usize, usize }, @ptrCast(&slice_u16));
    const struct_u32 = @as(*const struct { usize, usize }, @ptrCast(&slice_u32));
    const struct_usize = @as(*const struct { usize, usize }, @ptrCast(&slice_usize));
    try zl.debug.expectEqual(usize, 1, struct_u8[0]);
    try zl.debug.expectEqual(usize, 0, struct_u8[1]);
    try zl.debug.expectEqual(usize, 2, struct_u16[0]);
    try zl.debug.expectEqual(usize, 0, struct_u16[1]);
    try zl.debug.expectEqual(usize, 4, struct_u32[0]);
    try zl.debug.expectEqual(usize, 0, struct_u32[1]);
    try zl.debug.expectEqual(usize, 8, struct_usize[0]);
    try zl.debug.expectEqual(usize, 0, struct_usize[1]);
    @as(*const fn (str: []const u8) void, @ptrCast(&callWithSliceU8))(slice_u8);
    @as(*const fn (ints: []const u16) void, @ptrCast(&callWithSliceU16))(slice_u16);
    @as(*const fn (ints: []const u32) void, @ptrCast(&callWithSliceU32))(slice_u32);
    @as(*const fn (ints: []const usize) void, @ptrCast(&callWithSliceUsize))(slice_usize);
}
fn callWithSliceU8(str: [*]u8, str_len: usize) callconv(.C) void {
    zl.debug.assertEqual(usize, 1, @intFromPtr(str));
    zl.debug.assertEqual(usize, 0, str_len);
}
fn callWithSliceU16(str: [*]u8, str_len: usize) callconv(.C) void {
    zl.debug.assertEqual(usize, 2, @intFromPtr(str));
    zl.debug.assertEqual(usize, 0, str_len);
}
fn callWithSliceU32(str: [*]u8, str_len: usize) callconv(.C) void {
    zl.debug.assertEqual(usize, 4, @intFromPtr(str));
    zl.debug.assertEqual(usize, 0, str_len);
}
fn callWithSliceUsize(ints: [*]usize, ints_len: usize) callconv(.C) void {
    zl.debug.assertEqual(usize, 8, @intFromPtr(ints));
    zl.debug.assertEqual(usize, 0, ints_len);
}
