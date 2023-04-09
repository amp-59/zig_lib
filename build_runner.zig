const root = @import("@build");
const srg = root.srg;

pub usingnamespace root;
pub usingnamespace srg.proc.start;

const Builder = if (@hasDecl(root, "Builder"))
    root.Builder
else
    srg.build2.Builder(srg.spec.builder.default);

pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    defer allocator.deinit(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const cmds: [][*:0]u8 = args[5..];
    const build_fn = root.buildMain;
    var builder: Builder = try srg.meta.wrap(Builder.init(args, vars));
    try build_fn(&allocator, &builder);
    var target_task: srg.build2.Task = .build;
    for (cmds, 0..) |arg, idx| {
        const command: []const u8 = srg.meta.manyToSlice(arg);
        if (builder.args_len == builder.args.len) {
            if (srg.mach.testEqualMany8(command, "build")) {
                target_task = .build;
                continue;
            } else if (srg.mach.testEqualMany8(command, "--")) {
                builder.args_len = idx +% 6;
                continue;
            } else if (srg.mach.testEqualMany8(command, "run")) {
                target_task = .run;
                continue;
            } else if (srg.mach.testEqualMany8(command, "show")) {
                return Builder.debug.builderCommandNotice(&builder, true, true, true);
            }
        }
        for (builder.groups()) |group| {
            if (srg.mach.testEqualMany8(command, group.name)) {
                try srg.meta.wrap(group.executeToplevel(&address_space, &thread_space, &allocator, target_task));
            } else for (group.targets()) |target| {
                if (srg.mach.testEqualMany8(command, target.name)) {
                    try srg.meta.wrap(target.executeToplevel(&address_space, &thread_space, &allocator, &builder, target_task));
                }
            }
        }
    }
}
