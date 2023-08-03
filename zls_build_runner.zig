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
const dependencies = @import("@dependencies");
pub usingnamespace zl.start;
pub const is_debug: bool = false;
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
fn jsonLength(cfg: *const BuildConfig) usize {
    var len: usize = 39;
    if (cfg.packages.len != 0) {
        len +%= 27 +% cfg.packages.len +% cfg.packages[0].path.len;
        len +%= 43 *% cfg.packages[1..].len;
        for (cfg.packages[1..]) |pkg| {
            len +%= pkg.name.len +% pkg.path.len;
        }
    }
    if (cfg.include_dirs.len != 0) {
        len +%= 2 +% cfg.include_dirs[0].len;
        len +%= 23 +% cfg.include_dirs[1..].len;
        for (cfg.include_dirs[1..]) |dir| {
            len +%= dir.len;
        }
    }
    return len;
}
fn jsonWriteBuf(cfg: *const BuildConfig, buf: [*]u8) usize {
    @setRuntimeSafety(false);
    var ptr: [*]u8 = buf;
    ptr[0..14].* = "{ \"packages\": ".*;
    ptr = ptr + 14;
    if (cfg.packages.len == 0) {
        ptr[0..3].* = "[],".*;
        ptr = ptr + 3;
    } else {
        ptr[0..12].* = "[{ \"name\": \"".*;
        ptr = ptr + 12;
        @memcpy(ptr, cfg.packages[0].name);
        ptr = ptr + cfg.packages[0].name.len;
        ptr[0..12].* = "\", \"path\": \"".*;
        ptr = ptr + 12;
        @memcpy(ptr, cfg.packages[0].path);
        ptr = ptr + cfg.packages[0].path.len;
        ptr[0..3].* = "\" }".*;
        ptr = ptr + 3;
        for (cfg.packages[1..]) |pkg| {
            ptr[0..28].* = ",\n               { \"name\": \"".*;
            ptr = ptr + 28;
            @memcpy(ptr, pkg.name);
            ptr = ptr + pkg.name.len;
            ptr[0..12].* = "\", \"path\": \"".*;
            ptr = ptr + 12;
            @memcpy(ptr, pkg.path);
            ptr = ptr + pkg.path.len;
            ptr[0..3].* = "\" }".*;
            ptr = ptr + 3;
        }
        ptr[0..3].* = "],\n".*;
        ptr = ptr + 3;
    }
    ptr[0..18].* = "  \"include_dirs\": ".*;
    ptr = ptr + 18;
    if (cfg.include_dirs.len == 0) {
        ptr[0..2].* = "[]".*;
        ptr = ptr + 2;
    } else {
        ptr[0..2].* = "[\"".*;
        ptr = ptr + 2;
        @memcpy(ptr, cfg.include_dirs[0]);
        ptr = ptr + cfg.include_dirs[0].len;
        ptr[0] = '"';
        ptr = ptr + 1;
        for (cfg.include_dirs[1..]) |dir| {
            ptr[0..22].* = ",\n                   \"".*;
            ptr = ptr + 22;
            @memcpy(ptr, dir);
            ptr = ptr + dir.len;
            ptr[0] = '"';
            ptr = ptr + 1;
        }
        ptr[0] = ']';
        ptr = ptr + 1;
    }
    ptr[0..2].* = "}\n".*;
    ptr = ptr + 2;
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
