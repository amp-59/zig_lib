const zig_lib = @import("../zig_lib.zig");
const fmt = zig_lib.fmt;
const file = zig_lib.file;
const spec = zig_lib.spec;
const meta = zig_lib.meta;
const build = zig_lib.build;
const testing = zig_lib.testing;
const builtin = zig_lib.builtin;

pub usingnamespace zig_lib.proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

pub fn main(args: [][*:0]u8) !void {
    var rcd_buf: [4096]build.Record = undefined;
    for (args[1..]) |arg| {
        const fd: u64 = try file.open(.{}, meta.manyToSlice(arg));
        for (rcd_buf[0..try file.read(.{ .child = build.Record }, fd, &rcd_buf)]) |rcd| {
            testing.print(.{ fmt.any(rcd), '\n' });
        }
    }
}
