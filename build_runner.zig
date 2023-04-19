const root = @import("@build");
const srg = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};

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
    const build_fn = root.buildMain;
    var builder: Builder = try srg.meta.wrap(Builder.init(args, vars));
    try build_fn(&allocator, &builder);
    var target_task: srg.build2.Task = .build;
    var idx: u64 = 5;

    lo: while (idx < builder.args_len) : (idx +%= 1) {
        const command: []const u8 = srg.meta.manyToSlice(args[idx]);

        // Process builtin commands:
        if (builder.args_len == builder.args.len) {
            if (srg.mach.testEqualMany8(command, "build")) {
                target_task = .build;
                continue :lo;
            }
            if (srg.mach.testEqualMany8(command, "--")) {
                builder.args_len = idx;
                continue :lo;
            }
            if (srg.mach.testEqualMany8(command, "run")) {
                target_task = .run;
                continue :lo;
            }
            if (srg.mach.testEqualMany8(command, "list")) {
                Builder.debug.builderCommandNotice(&builder, true, true, true);
                continue :lo;
            }
        }

        // For each group, attempt to match the command line argument with name.
        // Then attempt to match against each target within that group.
        // All matches are valid.
        for (builder.groups()) |group| {
            if (srg.mach.testEqualMany8(command, group.name)) {
                builder.args_len = idx +% 1;
                try srg.meta.wrap(group.executeToplevel(&address_space, &thread_space, &allocator, target_task));
                continue :lo;
            }
            for (group.targets()) |target| {
                if (srg.mach.testEqualMany8(command, target.name)) {
                    builder.args_len = idx +% 1;
                    try srg.meta.wrap(target.executeToplevel(&address_space, &thread_space, &allocator, &builder, target_task));
                    continue :lo;
                }
            }
        }
        srg.builtin.proc.exitWithError(error.TargetDoesNotExist, 2);
    }
}
