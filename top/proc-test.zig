const proc = @import("./proc.zig");
const file = @import("./file.zig");
const spec = @import("./spec.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;

pub fn main(_: [][*:0]u8, vars: [][*:0]u8, aux: *const anyopaque) !void {
    const home: ?[:0]const u8 = proc.environmentValue(vars, "HOME");
    _ = home.?;
    _ = proc.auxiliaryValue(aux, .vdso_addr).?;

    const pid: u64 = try proc.fork(.{});
    if (pid == 0) {}
}
