const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const file = zl.file;
const proc = zl.proc;
const mach = zl.mach;
const spec = zl.spec;
const meta = zl.meta;
const builtin = zl.builtin;
const testing = zl.testing;

pub usingnamespace zl.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

const Array = mem.StaticString(0x1000000);

const pipe_spec = .{ .options = .{ .close_on_exec = false } };
const create_spec = .{ .options = .{ .read = true, .exclusive = false } };
const targets_pathname: [:0]const u8 = builtin.root.cache_root ++ "targets.json";

pub fn main(_: anytype, vars: [][*:0]u8) !void {
    const fd: u64 = try file.create(create_spec, targets_pathname, file.mode.regular);
    const pid: u64 = try proc.fork(.{});
    if (pid == 0) {
        var args: [2:builtin.zero([*:0]u8)][*:0]u8 = .{ @constCast(builtin.root.zig_exe), @constCast("targets") };
        var out: file.Pipe = try file.makePipe(pipe_spec);
        try file.close(.{}, out.read);
        try file.duplicateTo(.{}, fd, 1);
        try file.execPath(.{}, builtin.root.zig_exe, &args, vars);
    }
    try proc.waitPid(.{ .return_type = void }, .{ .pid = pid });
    try file.seek(.{ .return_type = void }, fd, 0, .end);
    try file.close(.{}, fd);
}
