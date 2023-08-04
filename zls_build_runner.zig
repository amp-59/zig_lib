const root = @import("@build");
const zl = blk: {
    if (@hasDecl(root, "zl")) {
        break :blk root.zl;
    }
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const mem = zl.mem;
const sys = zl.sys;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const mach = zl.mach;
const spec = zl.spec;
const build = zl.build;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
const Node = if (@hasDecl(root, "Node"))
    root.Node
else
    build.GenericNode(.{});
pub const BuildConfig = struct {
    packages: []Pkg,
    include_dirs: []const []const u8,
    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,
    };
};
const tab = .{
    .name = "\"name\":",
    .path = "\"path\":",
    .packages = "\"packages\":",
    .include_dirs = "\"include_dirs\":",
};
fn jsonLength(cfg: *const BuildConfig) usize {
    @setRuntimeSafety(false);
    var len: usize = 1 +% tab.packages.len;
    if (cfg.packages.len == 0) {
        len +%= 3;
    } else {
        len +%= 8 +%
            tab.name.len +% cfg.packages[0].name.len +%
            tab.path.len +% cfg.packages[0].path.len;
        var pkg_idx: usize = 1;
        while (pkg_idx != cfg.packages.len) : (pkg_idx +%= 1) {
            len +%= 8 +%
                tab.name.len +% cfg.packages[pkg_idx].name.len +%
                tab.path.len +% cfg.packages[pkg_idx].path.len;
        }
        len +%= 2;
    }
    len +%= tab.include_dirs.len;
    if (cfg.include_dirs.len == 0) {
        len +%= 2;
    } else {
        len +%= 3 +% cfg.include_dirs[0].len;
        var dir_idx: usize = 1;
        while (dir_idx != cfg.include_dirs.len) : (dir_idx +%= 1) {
            len +%= 3 +% cfg.include_dirs[dir_idx].len;
        }
        len +%= 1;
    }
    return len +% 1;
}
fn jsonWriteBuf(cfg: *const BuildConfig, buf: [*]u8) usize {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr[0] = '{';
    ptr = ptr + 1;
    ptr[0..11].* = tab.packages.*;
    ptr = ptr + tab.packages.len;
    if (cfg.packages.len == 0) {
        ptr[0..3].* = "[],".*;
        ptr = ptr + 3;
    } else {
        ptr[0] = '[';
        ptr[1] = '{';
        ptr = ptr + 2;
        ptr[0..7].* = tab.name.*;
        ptr = ptr + tab.name.len;
        ptr[0] = '"';
        ptr = ptr + 1;
        @memcpy(ptr, cfg.packages[0].name);
        ptr = ptr + cfg.packages[0].name.len;
        ptr[0] = '"';
        ptr[1] = ',';
        ptr = ptr + 2;
        ptr[0..7].* = tab.path.*;
        ptr = ptr + tab.path.len;
        ptr[0] = '"';
        ptr = ptr + 1;
        @memcpy(ptr, cfg.packages[0].path);
        ptr = ptr + cfg.packages[0].path.len;
        ptr[0] = '"';
        ptr[1] = '}';
        ptr = ptr + 2;
        var pkg_idx: usize = 1;
        while (pkg_idx != cfg.packages.len) : (pkg_idx +%= 1) {
            ptr[0] = ',';
            ptr[1] = '{';
            ptr = ptr + 2;
            ptr[0..7].* = tab.name.*;
            ptr = ptr + tab.name.len;
            ptr[0] = '"';
            ptr = ptr + 1;
            @memcpy(ptr, cfg.packages[pkg_idx].name);
            ptr = ptr + cfg.packages[pkg_idx].name.len;
            ptr[0] = '"';
            ptr[1] = ',';
            ptr = ptr + 2;
            ptr[0..7].* = tab.path.*;
            ptr = ptr + tab.path.len;
            ptr[0] = '"';
            ptr = ptr + 1;
            @memcpy(ptr, cfg.packages[pkg_idx].path);
            ptr = ptr + cfg.packages[pkg_idx].path.len;
            ptr[0] = '"';
            ptr[1] = '}';
            ptr = ptr + 2;
        }
        ptr[0] = ']';
        ptr[1] = ',';
        ptr = ptr + 2;
    }
    ptr[0..15].* = tab.include_dirs.*;
    ptr = ptr + tab.include_dirs.len;
    if (cfg.include_dirs.len == 0) {
        ptr[0..2].* = "[]".*;
        ptr = ptr + 2;
    } else {
        ptr[0] = '[';
        ptr[1] = '"';
        ptr = ptr + 2;
        @memcpy(ptr, cfg.include_dirs[0]);
        ptr = ptr + cfg.include_dirs[0].len;
        ptr[0] = '"';
        ptr = ptr + 1;
        var dir_idx: usize = 1;
        while (dir_idx != cfg.include_dirs.len) : (dir_idx +%= 1) {
            ptr[0] = ',';
            ptr[1] = '"';
            ptr = ptr + 2;
            @memcpy(ptr, cfg.include_dirs[dir_idx]);
            ptr = ptr + cfg.include_dirs[dir_idx].len;
            ptr[0] = '"';
            ptr = ptr + 1;
        }
        ptr[0] = ']';
        ptr = ptr + 1;
    }
    ptr[0] = '}';
    ptr = ptr + 1;
    return @intFromPtr(ptr - @intFromPtr(buf));
}
fn lengthModules(node: *Node) usize {
    @setRuntimeSafety(false);
    var len: usize = 0;
    for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
        if (sub_node.tag == .group) {
            len +%= lengthModules(sub_node);
        }
        if (sub_node.tag == .worker and sub_node.task.tag == .build) {
            if (sub_node.task.cmd.build.modules) |mods| {
                len +%= mods.len;
            }
        }
    }
    return len;
}
fn writeModulesBuf(pkgs: [*]BuildConfig.Pkg, node: *Node) usize {
    @setRuntimeSafety(false);
    var len: usize = 0;
    for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
        if (sub_node.tag == .group) {
            len +%= writeModulesBuf(pkgs, sub_node);
        }
        if (sub_node.tag == .worker and sub_node.task.tag == .build) {
            if (sub_node.task.cmd.build.modules) |mods| {
                for (mods) |mod| {
                    pkgs[len] = .{ .name = mod.name, .path = mod.path };
                    len +%= 1;
                }
            }
        }
    }
    return len;
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    var allocator: build.Allocator = build.Allocator.init_arena(Node.AddressSpace.arena(Node.max_thread_count));
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    Node.initState(args, vars);
    const toplevel: *Node = Node.init(&allocator);
    try meta.wrap(
        root.buildMain(&allocator, toplevel),
    );
    const pkgs_len: u64 = lengthModules(toplevel);
    const pkgs: []BuildConfig.Pkg = try meta.wrap(
        allocator.allocate(BuildConfig.Pkg, pkgs_len),
    );
    const cfg: BuildConfig = .{
        .packages = pkgs[0..writeModulesBuf(pkgs.ptr, toplevel)],
        .include_dirs = &.{},
    };
    const buf: []u8 = try meta.wrap(
        allocator.allocate(u8, jsonLength(&cfg)),
    );
    try file.write(.{}, 1, buf[0..jsonWriteBuf(&cfg, buf.ptr)]);
}
