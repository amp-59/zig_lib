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
const preset = srg.preset;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const is_verbose: bool = if (@hasDecl(root, "is_verbose")) root.is_verbose else false;
pub const is_silent: bool = if (@hasDecl(root, "is_silent")) root.is_silent else true;
pub const runtime_assertions: bool = if (@hasDecl(root, "runtime_assertions")) root.runtime_assertions else false;

pub const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_addr = 0,
    .lb_offset = 0x40000000,
    .divisions = 64,
    .logging = preset.address_space.logging.silent,
});
const Options = build.GlobalOptions;

fn maxWidths(builder: *build.Builder) extern struct { u64, u64 } {
    const alignment: u64 = 8;
    var name_max_width: u64 = 0;
    var root_max_width: u64 = 0;
    var groups: build.GroupList = builder.groups;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            name_max_width = @max(name_max_width, (targets.node.this.name.len));
            root_max_width = @max(root_max_width, (targets.node.this.root.len));
        }
    }
    name_max_width += alignment;
    root_max_width += alignment;
    return .{ name_max_width & ~(alignment - 1), root_max_width & ~(alignment - 1) };
}
fn showAllCommands(builder: *build.Builder) void {
    var buf: [1024 * 1024]u8 = undefined;
    var len: u64 = 0;
    var groups: build.GroupList = builder.groups;
    const max_widths: [2]u64 = maxWidths(builder);
    var spaces: [256]u8 = [1]u8{' '} ** 256;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        len +%= builtin.debug.writeMulti(buf[len..], &.{ groups.node.this.name, ":\n" });
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            len +%= builtin.debug.writeMany(buf[len..], "    ");
            len +%= builtin.debug.writeMulti(buf[len..], &.{
                targets.node.this.name, spaces[0 .. max_widths[0] - targets.node.this.name.len],
                targets.node.this.root, spaces[0 .. max_widths[1] - targets.node.this.root.len],
                "\n",
            });
        }
    }
    builtin.debug.logAlways(buf[0..len]);
}
fn showHelpAndCommands(builder: *build.Builder) void {
    builtin.debug.logAlways(comptime Options.Map.helpMessage(opts_map));
    showAllCommands(builder);
}
fn rewind(builder: *build.Builder) void {
    var groups: build.GroupList = builder.groups.itr();
    while (groups.next()) |group_node| : (groups.node = group_node) {
        groups.node.this.targets.head();
    }
}

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

// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "mode",    .long = "--fast",       .assign = .{ .any = &(.ReleaseFast) },  .descr = release_fast_s },
    .{ .field_name = "mode",    .long = "--small",      .assign = .{ .any = &(.ReleaseSmall) }, .descr = release_small_s },
    .{ .field_name = "mode",    .long = "--safe",       .assign = .{ .any = &(.ReleaseSafe) },  .descr = release_safe_s },
    .{ .field_name = "mode",    .long = "--debug",      .assign = .{ .any = &(.Debug) },        .descr = debug_s },
    //.{ .field_name = "strip",       .long = "-fstrip",      .assign = .{ .boolean = true },         .descr = strip_s },
    //.{ .field_name = "strip",       .long = "-fno-strip",   .assign = .{ .boolean = false },        .descr = no_strip_s },
    //.{ .field_name = "verbose",     .long = "--verbose",    .assign = .{ .boolean = true },         .descr = verbose_s },
    //.{ .field_name = "verbose",     .long = "--silent",     .assign = .{ .boolean = false },        .descr = silent_s },
    .{ .field_name = "cmd",     .long = "--run",        .assign = .{ .any = &(.run) },          .descr = run_cmd_s },
    .{ .field_name = "cmd",     .long = "--build",      .assign = .{ .any = &(.build) },        .descr = build_cmd_s },
    .{ .field_name = "cmd",     .long = "--fmt",        .assign = .{ .any = &(.fmt) },          .descr = fmt_cmd_s },
});
// zig fmt: on

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: build.Allocator = try build.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    if (args.len < 5) {
        builtin.debug.logAlways("Expected path to zig compiler, " ++
            "build root directory path, " ++
            "cache root directory path, " ++
            "global cache root directory path");
        sys.call(.exit, .{}, noreturn, .{2});
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
    var builder: build.Builder = build.Builder.init(&allocator, paths, options, args, vars);
    _ = builder.addGroup(&allocator, "all");
    try build_fn(&allocator, &builder);
    rewind(&builder);
    var index: u64 = 0;
    while (index != args.len) {
        const name: [:0]const u8 = meta.manyToSlice(args[index]);
        if (mach.testEqualMany8(name, "show")) {
            return showHelpAndCommands(&builder);
        }
        if (mach.testEqualMany8(name, "--")) {
            break;
        }
        var groups: build.GroupList = builder.groups;
        group: while (groups.next()) |group_node| : (groups.node = group_node) {
            if (mach.testEqualMany8(name, groups.node.this.name)) {
                try invokeTargetGroup(&allocator, &builder, groups);
                break :group;
            } else {
                var targets: build.TargetList = groups.node.this.targets;
                while (targets.next()) |target_node| : (targets.node = target_node) {
                    if (mach.testEqualMany8(name, targets.node.this.name)) {
                        try invokeTarget(&allocator, &builder, targets.node.this);
                        break :group;
                    }
                }
            }
        } else {
            showHelpAndCommands(&builder);
            return error.CommandNotFound;
        }
        index +%= 1;
    }
}
fn invokeTargetGroup(allocator: *build.Allocator, builder: *build.Builder, groups: build.GroupList) !void {
    var targets: build.TargetList = groups.node.this.targets.itr();
    while (targets.next()) |target_node| : (targets.node = target_node) {
        try invokeTarget(allocator, builder, targets.node.this);
    }
}
fn invokeTarget(allocator: *build.Allocator, builder: *build.Builder, target: *build.Target) !void {
    const save: build.Allocator.Save = allocator.save();
    defer allocator.restore(save);
    switch (builder.options.cmd) {
        .fmt => try target.format(),
        .run => try target.run(),
        .build => try target.build(),
    }
}
