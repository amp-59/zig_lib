const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const meta = zl.meta;
const proc = zl.proc;
const math = zl.math;
const spec = zl.spec;
const mach = zl.mach;
const file = zl.file;
const time = zl.time;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;

const perf = @import("../top/perf.zig");

pub usingnamespace zl.start;

pub const logging_override: debug.Logging.Override = spec.logging.override.silent;

const path_spec: file.PathSpec = .{ .errors = .{} };
const close_spec: file.CloseSpec = .{ .errors = .{} };
const fork_spec: proc.ForkSpec = .{ .errors = .{} };
const wait_spec: proc.WaitSpec = .{ .errors = .{}, .return_type = void };

comptime {
    _ = mach;
}

fn findPathFd(vars: [][*:0]u8, name: [:0]const u8) !u64 {
    var dir_fd: usize = 100;
    dir_fd = -%dir_fd;
    if (name[0] == '/') {
        return dir_fd;
    }
    if (file.accessAt(.{}, dir_fd, name, .{ .exec = true })) {
        return dir_fd;
    } else |err| {
        if (err != error.NoSuchFileOrDirectory and
            err != error.Access)
        {
            return err;
        }
    }
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    while (itr.next()) |dirname| {
        dir_fd = file.path(path_spec, .{}, dirname);
        if (file.accessAt(.{}, dir_fd, name, .{ .exec = true })) {
            itr.done();
            return dir_fd;
        } else |_| {
            file.close(close_spec, dir_fd);
        }
    }
    return error.NoExecutableInPath;
}
fn forwardExec(args: [][*:0]u8, vars: [][*:0]u8, dir_fd: usize, name: [:0]const u8) !void {
    const pid: usize = proc.fork(fork_spec);
    if (pid == 0) {
        return file.execAt(.{}, dir_fd, name, args[1..], vars);
    }
    proc.waitPid(wait_spec, .{ .pid = pid });
}
const PerfEvents = perf.GenericPerfEvents(.{});

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    if (args.len <= 1) {
        return error.MissingArguments;
    }
    const name: [:0]const u8 = meta.manyToSlice(args[1]);
    const dir_fd: usize = try findPathFd(vars, name);
    defer file.close(close_spec, dir_fd);
    var pes: PerfEvents = .{};
    var buf: [4096]u8 = undefined;
    try pes.openFds();
    try forwardExec(args, vars, dir_fd, name);
    try pes.readResults();
    const ptr: [*]u8 = pes.writeResults(&buf);
    debug.write(buf[0..fmt.strlen(ptr, &buf)]);
}
