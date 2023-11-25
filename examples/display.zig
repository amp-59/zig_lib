const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
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
    var array: zl.mem.array.StaticString(4096) = undefined;
    array.undefineAll();
    var fd = try zl.file.open(.{}, .{ .read_write = true }, "/dev/dri/card0");
    defer zl.file.close(.{ .errors = .{} }, fd);
    var res: ModeRes = undefined;
    zl.mem.zero(ModeRes, &res);
    const ioc: Ioc = .{
        .read = true,
        .write = true,
        .type = .d,
        .number = 0xA0,
        .size = @sizeOf(ModeRes),
    };
    try zl.sys.call(.ioctl, .{ .throw = zl.file.spec.ioctl.errors.all }, void, .{
        fd,
        @as(u32, @bitCast(ioc)),
        @intFromPtr(&res),
    });
    array.writeFormat(zl.fmt.any(res));
    array.writeOne('\n');
    zl.debug.write(array.readAll());
}
