const zig_lib = @import("../zig_lib.zig");
const sys = zig_lib.sys;
const fmt = zig_lib.fmt;
const mem = zig_lib.mem;
const meta = zig_lib.meta;
const proc = zig_lib.proc;
const math = zig_lib.math;
const spec = zig_lib.spec;
const mach = zig_lib.spec;
const file = zig_lib.file;
const time = zig_lib.time;
const builtin = zig_lib.builtin;
const testing = zig_lib.testing;
const perf = @import("../top/perf.zig");

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
const event_spec: perf.PerfEventSpec = .{ .errors = .{} };
const read_spec: file.ReadSpec = .{ .errors = .{}, .return_type = void, .child = u64 };
const wait_spec: proc.WaitSpec = .{ .errors = .{} };
const close_spec: file.CloseSpec = .{ .errors = .{} };
const fork_spec: proc.ForkSpec = .{ .errors = .{} };
const path_spec: file.PathSpec = .{ .errors = .{} };
const Array = mem.StaticString(1024 *% 1024);

const about = builtin.fmt.about("perf");

const hw_counters: []const perf.Measurement = &.{
    .{ .name = about ++ "cycles\t\t\t", .config = .{ .hardware = .cpu_cycles } },
    .{ .name = about ++ "instructions\t\t", .config = .{ .hardware = .instructions } },
    .{ .name = about ++ "cache-references\t", .config = .{ .hardware = .cache_references } },
    .{ .name = about ++ "cache-misses\t\t", .config = .{ .hardware = .cache_misses } },
    // .{ .name = about ++ "branches\t\t", .config = .{ .hardware = .branch_instructions } },
    .{ .name = about ++ "branch-misses\t\t", .config = .{ .hardware = .branch_misses } },
};
const sw_counters: []const perf.Measurement = &.{
    .{ .name = about ++ "cpu-clock\t\t", .config = .{ .software = .cpu_clock } },
    .{ .name = about ++ "task-clock\t\t", .config = .{ .software = .task_clock } },
    .{ .name = about ++ "page-faults\t\t", .config = .{ .software = .page_faults } },
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    const event_flags: perf.Event.Flags = .{
        .disabled = true,
        .exclude_kernel = true,
        .exclude_hv = true,
        .inherit = true,
        .enable_on_exec = true,
    };
    if (args.len <= 1) {
        return error.MissingArguments;
    }
    var hw_fds: [hw_counters.len]u64 = undefined;
    hw_fds[0] = ~@as(u32, 0);
    var sw_fds: [sw_counters.len]u64 = undefined;
    sw_fds[0] = ~@as(u32, 0);
    var result: u64 = 0;
    var event: perf.Event = .{ .flags = event_flags };
    var idx: u64 = 0;
    event.type = .hardware;
    while (idx != hw_counters.len) : (idx +%= 1) {
        event.config = hw_counters[idx].config;
        hw_fds[idx] = perf.eventOpen(event_spec, &event, .self, .any, hw_fds[0], .{ .fd_close_on_exec = true });
    }
    event.type = .software;
    idx = 0;
    while (idx != sw_counters.len) : (idx +%= 1) {
        event.config = sw_counters[idx].config;
        sw_fds[idx] = perf.eventOpen(event_spec, &event, .self, .any, hw_fds[0], .{ .fd_close_on_exec = true });
    }
    const leader_fd: u64 = hw_fds[0];
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    const name: [:0]const u8 = meta.manyToSlice(args[1]);
    const dir_fd: u64 = while (itr.next()) |dirname| {
        const dir_fd: u64 = file.path(path_spec, dirname);
        if (file.accessAt(.{}, dir_fd, name, .{ .exec = true })) {
            itr.done();
            break dir_fd;
        } else |err| {
            if (err == error.NoSuchFileOrDirectory or
                err == error.Access)
                file.close(close_spec, dir_fd);
        }
    } else {
        return error.NoExecutableInPath;
    };
    try perf.eventControl(.{}, leader_fd, .reset, true);
    const pid: u64 = proc.fork(fork_spec);
    if (pid == 0) {
        return file.execAt(.{}, dir_fd, name, args[1..], vars);
    }
    const ret: proc.Return = proc.waitPid(wait_spec, .{ .pid = pid });
    _ = ret;
    try perf.eventControl(.{}, leader_fd, .disable, true);
    var array: Array = undefined;
    array.undefineAll();
    idx = 0;
    while (idx != hw_counters.len) : (idx +%= 1) {
        file.readOne(read_spec, hw_fds[idx], &result);
        array.writeAny(spec.reinterpret.fmt, .{ hw_counters[idx].name, fmt.udh(result), '\n' });
    }
    idx = 0;
    while (idx != sw_counters.len) : (idx +%= 1) {
        file.readOne(read_spec, sw_fds[idx], &result);
        array.writeAny(spec.reinterpret.fmt, .{ sw_counters[idx].name, fmt.udh(result), '\n' });
    }
    builtin.debug.write(array.readAll());
    for (hw_fds ++ sw_fds) |fd| {
        file.close(close_spec, fd);
    }
    file.close(close_spec, dir_fd);
}
