const fmt = @import("../fmt.zig");
const perf = @import("../perf.zig");
const types = @import("./types.zig");

pub const omni_lock = .{ .bytes = .{
    .null,  .ready, .ready, .ready,
    .ready, .ready, .null,
} };
pub const obj_lock = .{ .bytes = .{
    .null, .null, .null, .ready,
    .null, .null, .null,
} };
pub const exe_lock = .{ .bytes = .{
    .null,  .null, .null, .ready,
    .ready, .null, .null,
} };
pub const run_lock = .{ .bytes = .{
    .null,  .null, .null, .null,
    .ready, .null, .null,
} };
pub const format_lock = .{ .bytes = .{
    .null, .null, .ready, .null,
    .null, .null, .null,
} };
pub const archive_lock = .{ .bytes = .{
    .null, .null,  .null, .null,
    .null, .ready, .null,
} };
pub const ar_s: fmt.AboutSrc = fmt.about("ar");
pub const run_s: fmt.AboutSrc = fmt.about("run");
pub const add_s: fmt.AboutSrc = fmt.about("add");
pub const mem_s: fmt.AboutSrc = fmt.about("mem");
pub const fmt_s: fmt.AboutSrc = fmt.about("fmt");
pub const perf_s: fmt.AboutSrc = fmt.about("perf");
pub const size_s: fmt.AboutSrc = fmt.about("size");
pub const unknown_s: fmt.AboutSrc = fmt.about("unknown");
pub const cmd_args_s: fmt.AboutSrc = fmt.about("cmd-args");
pub const run_args_s: fmt.AboutSrc = fmt.about("run-args");
pub const build_exe_s: fmt.AboutSrc = fmt.about("build-exe");
pub const build_obj_s: fmt.AboutSrc = fmt.about("build-obj");
pub const build_lib_s: fmt.AboutSrc = fmt.about("build-lib");
pub const state_s: fmt.AboutSrc = fmt.about("state");
pub const state_1_s: fmt.AboutSrc = fmt.about("state-fault");
pub const waiting_s: fmt.AboutSrc = fmt.about("waiting");

pub const null_s = "(null)";
pub const bytes_s = " bytes, ";
pub const green_s = "\x1b[92;1m";
pub const red_s = "\x1b[91;1m";
pub const new_s = "\x1b[0m\n";
pub const reset_s = "\x1b[0m";
pub const gold_s = "\x1b[93m";
pub const bold_s = "\x1b[1m";
pub const faint_s = "\x1b[2m";
pub const hi_green_s = "\x1b[38;5;46m";
pub const hi_red_s = "\x1b[38;5;196m";
pub const special_s = "\x1b[38;2;54;208;224;1m";

pub const extensions = .{
    .core = .{
        .name = "core",
        .path = "top/build/config_core.auto.zig",
        .offset = @offsetOf(types.VTable, "core"),
    },
    .proc = .{
        .name = "proc",
        .path = "top/build/multi_exec.auto.zig",
        .offset = @offsetOf(types.VTable, "proc"),
    },
    .build = .{
        .name = "build",
        .path = "top/build/build_core.auto.zig",
        .offset = @offsetOf(types.VTable, "build"),
    },
    .build_extra = .{
        .name = "build_extra",
        .path = "top/build/build_extra.auto.zig",
        .offset = @offsetOf(types.VTable, "build_extra"),
    },
    .format = .{
        .name = "format",
        .path = "top/build/format_core.auto.zig",
        .offset = @offsetOf(types.VTable, "format"),
    },
    .format_extra = .{
        .name = "format_extra",
        .path = "top/build/format_extra.auto.zig",
        .offset = @offsetOf(types.VTable, "format_extra"),
    },
    .archive = .{
        .name = "archive",
        .path = "top/build/archive_core.auto.zig",
        .offset = @offsetOf(types.VTable, "archive"),
    },
    .archive_extra = .{
        .name = "archive_extra",
        .path = "top/build/archive_extra.auto.zig",
        .offset = @offsetOf(types.VTable, "archive_extra"),
    },
    .objcopy = .{
        .name = "objcopy",
        .path = "top/build/objcopy_core.auto.zig",
        .offset = @offsetOf(types.VTable, "objcopy"),
    },
    .objcopy_extra = .{
        .name = "objcopy_extra",
        .path = "top/build/objcopy_extra.auto.zig",
        .offset = @offsetOf(types.VTable, "objcopy_extra"),
    },
    .trace = .{
        .name = "trace",
        .path = "top/trace.zig",
    },
};
