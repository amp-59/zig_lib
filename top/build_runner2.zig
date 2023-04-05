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

pub usingnamespace proc.start;

pub const runtime_assertions: bool = false;

const Builder = build.types.GenericBuilder(.{
    .errors = spec.builder.errors.noexcept,
    .logging = spec.builder.logging.silent,
});

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: build.types.AddressSpace = .{};
    var thread_space: build.types.ThreadSpace = .{};
    var allocator: build.types.Allocator = build.types.Allocator.init(&address_space, build.types.thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const cmds: [][*:0]u8 = args[5..];
    const build_fn: fn (*build.Allocator, *build.Builder) anyerror!void = root.buildMain;
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
            Builder.debug.builderCommandNotice(&builder);
        } else for (builder.groups()) |*group| {
            if (mach.testEqualMany8(command, group.name)) {
                try meta.wrap(group.acquireLock(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |*target| {
                if (mach.testEqualMany8(command, target.name)) {
                    try meta.wrap(target.acquireLock(&address_space, &thread_space, &allocator, &builder, target_task, build.types.thread_count, 0));
                }
            }
        }
    }
}
