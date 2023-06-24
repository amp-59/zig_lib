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

const Array = mem.StaticString(1024 *% 1024);

const hw_counters = [_]perf.Measurement{
    .{ .name = about.perf ++ "cycles", .config = .{ .hardware = .cpu_cycles } },
    .{ .name = about.perf ++ "instructions", .config = .{ .hardware = .instructions } },
    .{ .name = about.perf ++ "cache-references", .config = .{ .hardware = .cache_references } },
    .{ .name = about.perf ++ "cache-misses", .config = .{ .hardware = .cache_misses } },
    .{ .name = about.perf ++ "branches", .config = .{ .hardware = .branch_instructions } },
    //.{ .name = about.perf ++ "branch-misses", .config = .{ .hardware = .branch_misses } },
};
const sw_counters = [_]perf.Measurement{
    .{ .name = about.perf ++ "cpu-clock", .config = .{ .software = .cpu_clock } },
    .{ .name = about.perf ++ "task-clock", .config = .{ .software = .task_clock } },
    .{ .name = about.perf ++ "page-faults", .config = .{ .software = .page_faults } },
};
const about = .{
    .perf = builtin.fmt.about("perf"),
    .bytes_s = " bytes, ",
    .green_s = "\x1b[92;1m",
    .red_s = "\x1b[91;1m",
    .new_s = "\x1b[0m\n",
    .reset_s = "\x1b[0m",
    .gold_s = "\x1b[93m",
    .bold_s = "\x1b[1m",
    .faint_s = "\x1b[2m",
    .grey_s = "\x1b[0;38;5;250;1m",
    .trace_s = "\x1b[38;5;247m",
    .hi_green_s = "\x1b[38;5;46m",
    .hi_red_s = "\x1b[38;5;196m",
};
fn printUnit(array: *Array, x: f64, unit: enum { count, nanoseconds, bytes }) !void {
    const int = @floatToInt(u64, @round(x));
    switch (unit) {
        .count => array.writeFormat(fmt.udh(int)),
        .nanoseconds => array.writeFormat(fmt.nsec(int)),
        .bytes => array.writeFormat(fmt.bytes(int)),
    }
}
const event_flags: perf.Event.Flags = .{
    .disabled = true,
    .exclude_kernel = true,
    .exclude_hv = true,
    .inherit = true,
    .enable_on_exec = true,
};
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    if (args.len <= 1) {
        return error.MissingArguments;
    }
    var hw_fds: [hw_counters.len]u64 = .{0} ** hw_counters.len;
    hw_fds[0] <<= 32;
    hw_fds[0] -%= 1;
    var sw_fds: [sw_counters.len]u64 = .{0} ** sw_counters.len;
    sw_fds[0] <<= 32;
    sw_fds[0] -%= 1;
    var result: u64 = 0;
    for (hw_counters, 0..) |counter, idx| {
        hw_fds[idx] = try perf.eventOpen(.{}, &.{ .type = .hardware, .config = counter.config, .flags = event_flags }, .self, .any, hw_fds[0], .{ .fd_close_on_exec = true });
    }
    for (sw_counters, 0..) |counter, idx| {
        sw_fds[idx] = try perf.eventOpen(.{}, &.{ .type = .software, .config = counter.config, .flags = event_flags }, .self, .any, hw_fds[0], .{ .fd_close_on_exec = true });
    }
    const leader_fd: u64 = hw_fds[0];
    var itr: proc.PathIterator = .{
        .paths = proc.environmentValue(vars, "PATH").?,
    };
    const name: [:0]const u8 = meta.manyToSlice(args[1]);
    const dir_fd: u64 = while (itr.next()) |dirname| {
        const dir_fd: u64 = try file.path(.{}, dirname);
        if (file.accessAt(.{}, dir_fd, name, .{ .exec = true })) {
            itr.done();
            break dir_fd;
        } else |err| {
            if (err == error.NoSuchFileOrDirectory or
                err == error.Access)
                try file.close(.{}, dir_fd);
        }
    } else {
        return error.NoExecutableInPath;
    };
    try perf.eventControl(.{}, leader_fd, .reset, true);
    const pid: u64 = try proc.fork(.{});
    if (pid == 0) {
        return file.execAt(.{ .logging = .{ .Attempt = true } }, dir_fd, name, args[1..], vars);
    }
    const ret: proc.Return = try proc.waitPid(.{}, .{ .pid = pid });
    try perf.eventControl(.{}, leader_fd, .disable, true);
    var array: Array = .{};
    array.undefineAll();
    if (ret.status == 0) {
        for (hw_counters, 0..) |counter, idx| {
            try file.readOne(.{ .return_type = void, .child = u64 }, hw_fds[idx], &result);
            array.writeMany(counter.name);
            array.writeOne('\t');
            array.writeFormat(fmt.udh(result));
            array.writeOne('\n');
        }
        for (sw_counters, 0..) |counter, idx| {
            try file.readOne(.{ .return_type = void, .child = u64 }, sw_fds[idx], &result);
            array.writeMany(counter.name);
            array.writeOne('\t');
            array.writeFormat(fmt.udh(result));
            array.writeOne('\n');
        }
        builtin.debug.write(array.readAll());
    }
    for (hw_fds ++ sw_fds) |fd| {
        try file.close(.{}, fd);
    }
    try file.close(.{}, dir_fd);
}
