const root = @import("@build");
const build_fn: fn (*build.Allocator, *build.Builder) anyerror!void = root.buildMain;
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const mach = srg.mach;
const meta = srg.meta;
const build = srg.build;
const spec = srg.spec;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const message_style: [:0]const u8 =
    if (@hasDecl(root, "message_style")) root.message_style else "\x1b[2m";

pub const logging_override: builtin.Logging.Override =
    if (@hasDecl(root, "logging_override")) root.logging_override else .{
    .Success = null,
    .Acquire = null,
    .Release = null,
    .Error = null,
    .Fault = null,
};
pub const logging_default: builtin.Logging.Default =
    if (@hasDecl(root, "logging_default")) root.logging_default else .{
    .Success = false,
    .Acquire = false,
    .Release = false,
    .Error = true,
    .Fault = true,
};
pub const signal_handlers: builtin.SignalHandlers =
    if (@hasDecl(root, "signal_handlers")) root.signal_handlers else .{
    .segmentation_fault = true,
    .floating_point_error = false,
    .illegal_instruction = false,
    .bus_error = false,
};
pub const runtime_assertions: bool =
    if (@hasDecl(root, "runtime_assertions")) root.runtime_assertions else false;
pub const max_relevant_depth: u64 =
    if (@hasDecl(root, "max_relevant_depth")) root.max_relevant_depth else 0;

fn showAllCommands(builder: *build.Builder) void {
    var buf: [1024 * 1024]u8 = undefined;
    builtin.debug.logAlways(buf[0..build.asmWriteAllCommands(builder, &buf, build.asmMaxWidths(builder)[0])]);
}
fn showHelpAndCommands(builder: *build.Builder) void {
    builtin.debug.logAlways(help_s);
    showAllCommands(builder);
}
const Options = build.GlobalOptions;
const release_fast_s: [:0]const u8 = "prioritise low runtime";
const release_small_s: [:0]const u8 = "prioritise small executable size";
const release_safe_s: [:0]const u8 = "prioritise correctness";
const debug_s: [:0]const u8 = "prioritise comptime performance";
const strip_s: [:0]const u8 = "do not emit debug symbols";
const no_strip_s: [:0]const u8 = "emit debug symbols";
const verbose_s: [:0]const u8 = "show compile commands when executing";
const silent_s: [:0]const u8 = "do not show compile commands when executing";
const run_cmd_s: [:0]const u8 = "run commands for subsequent targets";
const build_cmd_s: [:0]const u8 = "build commands for subsequent targets";
const fmt_cmd_s: [:0]const u8 = "fmt commands for subsequent targets";
const bin_s: [:0]const u8 = "build emits binary";
const no_bin_s: [:0]const u8 = "build does not emit binary";
const asm_s: [:0]const u8 = "build emits assembly";
const no_asm_s: [:0]const u8 = "build does not emit assembly";
const help_s: []const u8 = Options.Map.helpMessage(opts_map);
const arg_error_s: []const u8 =
    "Expected path to zig compiler, " ++
    "build root directory path, " ++
    "cache root directory path, " ++
    "global cache root directory path";
// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "mode",    .long = "--fast",       .assign = .{ .any = &(.ReleaseFast) },  .descr = release_fast_s },
    .{ .field_name = "mode",    .long = "--small",      .assign = .{ .any = &(.ReleaseSmall) }, .descr = release_small_s },
 // .{ .field_name = "mode",    .long = "--safe",       .assign = .{ .any = &(.ReleaseSafe) },  .descr = release_safe_s }, // Never used
 // .{ .field_name = "strip",   .long = "--strip",      .assign = .{ .boolean = true },         .descr = strip_s }, // Default
    .{ .field_name = "strip",   .long = "--no-strip",   .assign = .{ .boolean = false },        .descr = no_strip_s },
    .{ .field_name = "mode",    .long = "--debug",      .assign = .{ .any = &(.Debug) },        .descr = debug_s },
    .{ .field_name = "cmd",     .long = "--run",        .assign = .{ .any = &(.run) },          .descr = run_cmd_s },
    .{ .field_name = "cmd",     .long = "--build",      .assign = .{ .any = &(.build) },        .descr = build_cmd_s },
    .{ .field_name = "cmd",     .long = "--fmt",        .assign = .{ .any = &(.fmt) },          .descr = fmt_cmd_s },
 // .{ .field_name = "emit_bin",    .long = "--bin",    .short = "-x",  .assign = .{ .boolean = true },     .descr = bin_s }, // Default
    .{ .field_name = "emit_asm",    .long = "--asm",    .short = "-s",  .assign = .{ .boolean = true },     .descr = asm_s },
    .{ .field_name = "emit_bin",    .long = "--no-bin", .short = "-X",  .assign = .{ .boolean = false },    .descr = no_bin_s },
 // .{ .field_name = "emit_asm",    .long = "--no-asm", .short = "-S",  .assign = .{ .boolean = false },    .descr = no_asm_s }, // Default
});
// zig fmt: on

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: build.AddressSpace = .{};
    var allocator: build.Allocator = build.Allocator.init(&address_space, 0);
    defer allocator.deinit(&address_space, 0);
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    if (args.len < 5) {
        builtin.proc.exitWithFault(arg_error_s, 2);
    }
    const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
    const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
    const cache_dir: [:0]const u8 = meta.manyToSlice(args[3]);
    const global_cache_dir: [:0]const u8 = meta.manyToSlice(args[4]);
    args = args[5..];
    const paths: build.Builder.Paths = .{
        .zig_exe = zig_exe,
        .build_root = build_root,
        .cache_dir = cache_dir,
        .global_cache_dir = global_cache_dir,
    };
    var builder: build.Builder = try meta.wrap(build.Builder.init(&allocator, paths, options, args, vars));
    _ = try meta.wrap(builder.addGroup(&allocator, "all"));
    try build_fn(&allocator, &builder);
    build.asmRewind(&builder);
    var idx: u64 = 0;
    while (idx != args.len) {
        const name: [:0]const u8 = meta.manyToSlice(args[idx]);
        if (builtin.testEqualMemory([]const u8, name, "--")) {
            builder.run_args = args[idx +% 1 ..];
            break;
        }
        idx +%= 1;
    }
    const max_idx: u64 = idx;
    idx = 0;
    while (idx != max_idx) {
        const name: [:0]const u8 = meta.manyToSlice(args[idx]);
        if (mach.testEqualMany8(name, "show")) {
            return showHelpAndCommands(&builder);
        }
        if (builtin.testEqualMemory([]const u8, name, "--")) {
            break;
        }
        var groups: build.GroupList = builder.groups;
        group: while (groups.next()) |group_node| : (groups.node = group_node) {
            if (mach.testEqualMany8(name, groups.node.this.name)) {
                try invokeTargetGroup(&builder, &allocator, groups);
                break :group;
            } else {
                var targets: build.TargetList = groups.node.this.targets;
                while (targets.next()) |target_node| : (targets.node = target_node) {
                    if (mach.testEqualMany8(name, targets.node.this.name)) {
                        try invokeTarget(&builder, &allocator, targets.node.this);
                        break :group;
                    }
                }
            }
        } else {
            showHelpAndCommands(&builder);
            return error.CommandNotFound;
        }
        idx +%= 1;
    }
}
fn invokeTargetGroup(builder: *build.Builder, allocator: *build.Allocator, groups: build.GroupList) !void {
    var targets: build.TargetList = groups.node.this.targets.itr();
    while (targets.next()) |target_node| : (targets.node = target_node) {
        try meta.wrap(invokeTarget(builder, allocator, targets.node.this));
    }
}
fn invokeTarget(builder: *build.Builder, allocator: *build.Allocator, target: *build.Target) !void {
    switch (builder.options.cmd) {
        .fmt => return meta.wrap(builder.format(allocator, target)),
        .run => return meta.wrap(builder.run(allocator, target)),
        .build => return meta.wrap(builder.build(allocator, target)),
    }
}
