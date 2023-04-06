const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const proc = srg.proc;
const mach = srg.mach;
const meta = srg.meta;
const spec = srg.spec;
const build = srg.build2;
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

pub const Builder =
    if (@hasDecl(root, "Builder"))
    root.Builder
else
    build.GenericBuilder(.{
        .errors = spec.builder.errors.noexcept,
        .logging = spec.builder.logging.silent,
    });

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const cmds: [][*:0]u8 = args[5..];
    const build_fn = root.buildMain;
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try build_fn(&allocator, &builder);
    var target_task: build.Task = .build;
    for (cmds) |arg| {
        const command: []const u8 = meta.manyToSlice(arg);
        if (mach.testEqualMany8(command, "build")) {
            target_task = .build;
        } else if (mach.testEqualMany8(command, "run")) {
            target_task = .run;
        } else if (mach.testEqualMany8(command, "show")) {
            Builder.debug.builderCommandNotice(&builder, true, true, true);
        } else for (builder.groups()) |group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.acquireLock(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |target| {
                if (mach.testEqualMany8(command, target.name)) {
                    try meta.wrap(target.acquireLock(&address_space, &thread_space, &allocator, &builder, target_task, Builder.max_thread_count, 0));
                }
            }
        }
    }
}
