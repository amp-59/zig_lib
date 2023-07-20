const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const fmt = zl.fmt;
const mem = zl.mem;
const meta = zl.meta;
const proc = zl.proc;
const math = zl.math;
const spec = zl.spec;
const mach = zl.spec;
const file = zl.file;
const time = zl.time;
const debug = zl.debug;
const builtin = zl.builtin;
const testing = zl.testing;
const perf = @import("../top/perf.zig");
pub usingnamespace zl.start;
pub const logging_override: debug.Logging.Override = spec.logging.override.silent;
const event_spec: perf.PerfEventSpec = .{ .errors = .{} };
const event_ctl_spec: perf.PerfEventControlSpec = .{ .errors = .{} };
const read_spec: file.ReadSpec = .{ .errors = .{}, .return_type = void, .child = u64 };
const wait_spec: proc.WaitSpec = .{ .errors = .{}, .return_type = void };
const close_spec: file.CloseSpec = .{ .errors = .{} };
const fork_spec: proc.ForkSpec = .{ .errors = .{} };
const path_spec: file.PathSpec = .{ .errors = .{} };
const Array = mem.StaticString(1024 *% 1024);
const about = fmt.about("perf");
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
const Fds = struct {
    hw: [hw_counters.len]u64,
    sw: [sw_counters.len]u64,
    fn init() Fds {
        var hw_fds: [hw_counters.len]u64 = undefined;
        var sw_fds: [sw_counters.len]u64 = undefined;
        hw_fds[0] = ~@as(u32, 0);
        const event_flags: perf.Event.Flags = .{
            .disabled = true,
            .exclude_kernel = true,
            .exclude_hv = true,
            .inherit = true,
            .enable_on_exec = true,
        };
        var event: perf.Event = .{ .flags = event_flags };
        var idx: usize = 0;
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
        return .{ .hw = hw_fds, .sw = sw_fds };
    }
    fn deinit(fds: *Fds) void {
        for (fds.hw) |fd| {
            file.close(close_spec, fd);
        }
        for (fds.sw) |fd| {
            file.close(close_spec, fd);
        }
    }
    fn print(fds: *Fds) void {
        var array: Array = undefined;
        array.undefineAll();
        var result: usize = 0;
        var idx: usize = 0;
        while (idx != hw_counters.len) : (idx +%= 1) {
            file.readOne(read_spec, fds.hw[idx], &result);
            array.writeAny(spec.reinterpret.fmt, .{ hw_counters[idx].name, fmt.udh(result), '\n' });
        }
        idx = 0;
        while (idx != sw_counters.len) : (idx +%= 1) {
            file.readOne(read_spec, fds.sw[idx], &result);
            array.writeAny(spec.reinterpret.fmt, .{ sw_counters[idx].name, fmt.udh(result), '\n' });
        }
        debug.write(array.readAll());
        fds.reset();
    }
    fn reset(fds: *Fds) void {
        fds.deinit();
        fds.* = init();
    }
};
fn findPathFd(vars: [][*:0]u8, name: [:0]const u8) !u64 {
    var dir_fd: u64 = 100;
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
        dir_fd = file.path(path_spec, dirname);
        if (file.accessAt(.{}, dir_fd, name, .{ .exec = true })) {
            itr.done();
            return dir_fd;
        } else |_| {
            file.close(close_spec, dir_fd);
        }
    }
    return error.NoExecutableInPath;
}
fn forwardExec(args: [][*:0]u8, vars: [][*:0]u8, dir_fd: u64, name: [:0]const u8) !void {
    const pid: u64 = proc.fork(fork_spec);
    if (pid == 0) {
        return file.execAt(.{}, dir_fd, name, args[1..], vars);
    }
    proc.waitPid(wait_spec, .{ .pid = pid });
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    if (args.len <= 1) {
        return error.MissingArguments;
    }
    const name: [:0]const u8 = meta.manyToSlice(args[1]);
    const dir_fd: u64 = try findPathFd(vars, name);
    defer file.close(close_spec, dir_fd);
    var fds: Fds = Fds.init();
    defer fds.deinit();
    try forwardExec(args, vars, dir_fd, name);
    fds.print();
}
