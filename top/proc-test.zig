const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const file = @import("./file.zig");
const preset = @import("./preset.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const is_silent: bool = true;
pub const is_verbose: bool = false;

pub const AddressSpace = preset.address_space.exact_8;

pub fn main(_: anytype, _: anytype, aux: *const anyopaque) !void {
    file.unlink(.{}, "./dump") catch {};
    const fd: u64 = try file.create(.{}, "./dump");
    defer file.close(.{ .errors = null }, fd);
    var array: mem.StaticString(8192) = .{};
    array.writeMany(@intToPtr(*const [8192]u8, proc.auxiliaryValue(aux, .vdso_addr).?));
    try file.write(fd, array.readAll());
}
