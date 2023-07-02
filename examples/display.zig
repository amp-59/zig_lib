const srg = @import("../zig_lib.zig");
const sys = srg.sys;
const fmt = srg.fmt;
const file = srg.file;
const mem = srg.mem;
const proc = srg.proc;
const meta = srg.meta;
const spec = srg.spec;
const builtin = srg.builtin;
const testing = srg.testing;

pub usingnamespace proc.start;

const ModeRes = extern struct {
    fbs: [*]u32,
    crtcs: [*]u32,
    conns: [*]u32,
    encoders: [*]u32,
    nfbs: u32,
    ncrtcs: u32,
    nconns: u32,
    nencoders: u32,
    min_width: u32,
    max_width: u32,
    min_height: u32,
    max_height: u32,
};
const Ioc = packed struct(u32) {
    number: u8,
    type: enum(u8) { d = 'd' },
    size: u14,
    write: bool,
    read: bool,
};
pub fn main() !void {
    var array: mem.StaticString(4096) = undefined;
    array.undefineAll();
    var fd = try file.open(.{ .options = .{ .read_write = true } }, "/dev/dri/card0");
    defer file.close(.{ .errors = .{} }, fd);
    var res = comptime builtin.zero(ModeRes);
    const ioc: Ioc = .{
        .read = true,
        .write = true,
        .type = .d,
        .number = 0xA0,
        .size = @sizeOf(ModeRes),
    };
    try sys.call(.ioctl, .{ .throw = sys.ioctl_errors }, void, .{
        fd,
        @as(u32, @bitCast(ioc)),
        @intFromPtr(&res),
    });
    array.writeFormat(fmt.any(res));
    array.writeOne('\n');
}
