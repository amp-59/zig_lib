const std = @import("std");
const mem = @import("mem.zig");
const meta = @import("meta.zig");
const builder = @import("builder.zig");
const Builder = @import("root").Builder;
fn convertBuild(
    allocator: *builder.types.Allocator,
    b: *std.Build,
    target: anytype,
    optimize: anytype,
    node: *Builder.Node,
) void {
    var itr: Builder.Node.Iterator = Builder.Node.Iterator.init(node);
    while (itr.next()) |sub_node| {
        if (sub_node.flags.is_group) {
            convertBuild(allocator, b, target, optimize, sub_node);
        } else if (sub_node.tasks.tag == .build and
            sub_node.flags.have_task_data)
        {
            if (sub_node.getPath(.{ .tag = .input_zig })) |input_zig| {
                const absolute_path: [:0]const u8 = input_zig.concatenate(allocator);
                const relative_path: [:0]const u8 = absolute_path[node.buildRoot().len +% 1 ..];
                const exe = switch (sub_node.tasks.cmd.build.kind) {
                    .exe => b.addExecutable(.{
                        .name = sub_node.name,
                        .root_source_file = .{ .path = relative_path },
                        .target = target,
                        .optimize = optimize,
                    }),
                    .obj, .lib => b.addObject(.{
                        .name = sub_node.name,
                        .root_source_file = .{ .path = relative_path },
                        .target = target,
                        .optimize = optimize,
                    }),
                };
                b.step(sub_node.name, "").dependOn(&exe.step);
                var fs_idx: usize = 0;
                for (sub_node.lists.mods) |mod| {
                    for (sub_node.lists.files[fs_idx..], fs_idx..) |fs, next| {
                        if (fs.key.tag == .input_zig) {
                            exe.root_module.addAnonymousImport(
                                mod.name.?,
                                .{ .root_source_file = .{ .path = sub_node.lists.paths[fs.path_idx].concatenate(allocator) } },
                            );
                            fs_idx = next +% 1;
                            break;
                        }
                    }
                }
            }
        }
    }
}
pub fn build(b: *std.Build) void {
    const arena = Builder.AddressSpace.arena(Builder.specification.options.max_thread_count);
    mem.map(.{
        .errors = .{},
        .logging = .{ .Acquire = false },
    }, .{}, .{}, arena.lb_addr, 4096);
    var allocator: builder.types.Allocator = .{
        .start = arena.lb_addr,
        .next = arena.lb_addr,
        .finish = arena.lb_addr +% 4096,
    };
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    const top: *Builder.Node = Builder.Node.init(&allocator, std.os.argv, std.os.environ);
    top.sh.as.lock = &address_space;
    top.sh.ts.lock = &thread_space;
    try meta.wrap(build.buildMain(&allocator, top));
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    convertBuild(&allocator, b, target, optimize, top);
}
