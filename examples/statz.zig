const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const file = zl.file;
const spec = zl.spec;
const meta = zl.meta;
const build = zl.build;
const debug = zl.debug;
const testing = zl.testing;
const builtin = zl.builtin;

pub usingnamespace zl.start;
pub const logging_override: debug.Logging.Override = spec.logging.override.silent;

pub fn main(args: [][*:0]u8) !void {
    var rcd_buf: [4096]build.Record = undefined;
    for (args[1..]) |arg| {
        const fd: u64 = try file.open(.{}, meta.manyToSlice(arg));
        for (rcd_buf[0..try file.read(.{ .child = build.Record }, fd, &rcd_buf)]) |rcd| {
            testing.print(.{ fmt.any(rcd), '\n' });
        }
    }
}
