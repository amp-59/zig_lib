const mach = @import("../mach.zig");
const file = @import("../file.zig");
const proc = @import("../proc.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");

const build = @import("./build-template.zig");
const build2 = @import("./build2.zig");
const types2 = @import("./build/types2.zig");

export fn rewind(builder: *build.Builder) callconv(.C) void {
    var groups: build.GroupList = builder.groups.itr();
    while (groups.next()) |group_node| : (groups.node = group_node) {
        groups.node.this.targets.head();
    }
}
export fn writeAllCommands(builder: *build.Builder, buf: *[1024 * 1024]u8, name_max_width: u64) callconv(.C) u64 {
    @setRuntimeSafety(false);
    var groups: build.GroupList = builder.groups;
    var len: u64 = 0;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        len +%= builtin.debug.writeMulti(buf[len..], &.{ groups.node.this.name, ":\n" });
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            mach.memset(buf[len..].ptr, ' ', 4);
            len +%= 4;
            mach.memcpy(buf[len..].ptr, targets.node.this.name.ptr, targets.node.this.name.len);
            len +%= targets.node.this.name.len;
            const count: u64 = name_max_width - targets.node.this.name.len;
            mach.memset(buf[len..].ptr, ' ', count);
            len +%= count;
            mach.memcpy(buf[len..].ptr, targets.node.this.root.ptr, targets.node.this.root.len);
            len +%= targets.node.this.root.len;
            buf[len] = '\n';
            len +%= 1;
        }
    }
    return len;
}
fn writeEnvDecls(env_fd: u64, paths: *const build.Builder.Paths) void {
    for (&[_][]const u8{
        "pub const zig_exe: [:0]const u8 = \"",               paths.zig_exe.absolute,
        "\";\npub const build_root: [:0]const u8 = \"",       paths.build_root.absolute,
        "\";\npub const cache_dir: [:0]const u8 = \"",        paths.cache_dir.absolute,
        "\";\npub const global_cache_dir: [:0]const u8 = \"", paths.global_cache_dir.absolute,
        "\";\n",
    }) |s| {
        file.write(.{ .errors = .{} }, env_fd, s);
    }
}
export fn maxWidths(builder: *build.Builder) extern struct { u64, u64 } {
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
export fn nameMaxWidths(builder: *build.Builder) u64 {
    const alignment: u64 = 8;
    var name_max_width: u64 = 0;
    var groups: build.GroupList = builder.groups;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            name_max_width = @max(name_max_width, (targets.node.this.name.len));
        }
    }
    name_max_width += alignment;
    return name_max_width & ~(alignment - 1);
}
export fn targetErrorInternal(builder: *build.Builder, arg: [*:0]const u8, arg_len: u64) void {
    var buf: [4096 +% 128]u8 = undefined;
    var len: u64 = 0;
    len += builtin.debug.writeMany(buf[len..], debug.about_target_1_s);
    buf[len] = '\'';
    len +%= 1;
    len += builtin.debug.writeMany(buf[len..], arg[0..arg_len]);
    len += builtin.debug.writeMany(buf[len..], "'\n");
    len +%= 2;
    var groups: build.GroupList = builder.groups;
    while (groups.next()) |group_node| : (groups.node = group_node) {
        var targets: build.TargetList = groups.node.this.targets;
        while (targets.next()) |target_node| : (targets.node = target_node) {
            const name: []const u8 = targets.node.this.name;
            const min: u64 = len;
            const mats: u64 = blk: {
                var l_idx: u64 = 0;
                var mats: u64 = 0;
                lo: while (true) : (l_idx += 1) {
                    var r_idx: u64 = 0;
                    while (r_idx < name.len) : (r_idx += 1) {
                        if (l_idx +% mats >= arg_len) {
                            break :lo;
                        }
                        mats += @boolToInt(arg[l_idx +% mats] == name[r_idx]);
                    }
                }
                break :blk mats;
            };
            if (builtin.diff(u64, mats, name.len) < 2) {
                len += builtin.debug.writeMany(buf[len..], debug.about_target_0_s);
                len += builtin.debug.writeMany(buf[len..], name);
            }
            if (min != len) {
                buf[len] = '\'';
                len +%= 1;
                if (targets.node.this.descr) |descr| {
                    buf[len] = '\t';
                    len += 1;
                    len += builtin.debug.writeMany(buf[len..], descr);
                }
                buf[len] = '\n';
                len +%= 1;
            }
        }
    }
    builtin.debug.write(buf[0..len]);
}
const Builder = build.GenericBuilder(.{
    .errors = preset.builder.errors.noexcept,
    .logging = preset.builder.logging.silent,
});
export fn forwardToExecuteCloneThreaded(
    builder: *Builder,
    address_space: *types2.AddressSpace,
    thread_space: *types2.ThreadSpace,
    target: *Builder.Target,
    task: build.Task,
    arena_index: types2.AddressSpace.Index,
    depth: u64,
    stack_address: u64,
) void {
    _ = proc.callClone(.{ .errors = .{} }, stack_address, {}, Builder.executeCommandThreaded, .{
        builder, address_space, thread_space, target, task, arena_index, depth,
    });
}

const debug = struct {
    const about_target_0_s: [:0]const u8 = builtin.debug.about("target");
    const about_target_1_s: [:0]const u8 = builtin.debug.about("target-error");
};
