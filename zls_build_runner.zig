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
pub usingnamespace root;
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
inline fn cpy(buf: []u8, any: anytype) u64 {
    @as(*@TypeOf(any), @ptrCast(buf.ptr)).* = any;
    return any.len;
}
fn lengthJSON(cfg: *const BuildConfig) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 34;
    if (cfg.packages.len == 0) {
        len +%= 3;
    } else {
        len +%= 27 +% cfg.packages[0].name.len +%
            cfg.packages[0].path.len +%
            cfg.packages[1..].len *% 43;
        for (cfg.packages[1..]) |pkg| {
            len +%= pkg.name.len +% pkg.path.len;
        }
        len +%= 3;
    }
    if (cfg.include_dirs.len == 0) {
        len +%= 2;
    } else {
        len +%= 3 +% cfg.include_dirs[0].len +%
            cfg.include_dirs[1..].len *% 23;
        for (cfg.include_dirs[1..]) |dir| {
            len +%= dir.len;
        }
        len +%= 1;
    }
    return len;
}
fn writeJSON(cfg: *const BuildConfig, buf: []u8) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    len +%= cpy(buf[len..], "{ \"packages\": ".*);
    if (cfg.packages.len == 0) {
        len +%= cpy(buf[len..], "[],".*);
    } else {
        len +%= cpy(buf[len..], "[{ \"name\": \"".*);
        @memcpy(buf[len..], cfg.packages[0].name);
        len +%= cfg.packages[0].name.len;
        len +%= cpy(buf[len..], "\", \"path\": \"".*);
        @memcpy(buf[len..], cfg.packages[0].path);
        len +%= cfg.packages[0].path.len;
        len +%= cpy(buf[len..], "\" }".*);
        for (cfg.packages[1..]) |pkg| {
            len +%= cpy(buf[len..], ",\n               { \"name\": \"".*);
            @memcpy(buf[len..], pkg.name);
            len +%= pkg.name.len;
            len +%= cpy(buf[len..], "\", \"path\": \"".*);
            @memcpy(buf[len..], pkg.path);
            len +%= pkg.path.len;
            len +%= cpy(buf[len..], "\" }".*);
        }
        len +%= cpy(buf[len..], "],\n".*);
    }
    len +%= cpy(buf[len..], "  \"include_dirs\": ".*);
    if (cfg.include_dirs.len == 0) {
        len +%= cpy(buf[len..], "[]".*);
    } else {
        len +%= cpy(buf[len..], "[\"".*);
        @memcpy(buf[len..], cfg.include_dirs[0]);
        len +%= cfg.include_dirs[0].len;
        len +%= cpy(buf[len..], "\"".*);
        for (cfg.include_dirs[1..]) |dir| {
            len +%= cpy(buf[len..], ",\n                   \"".*);
            @memcpy(buf[len..], dir.ptr);
            len +%= dir.len;
            len +%= cpy(buf[len..], "\"".*);
        }
        len +%= cpy(buf[len..], "]".*);
    }
    len +%= cpy(buf[len..], "}\n".*);
    return len;
}
fn lengthModules(node: *Node) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
        if (sub_node.tag == .group) {
            len +%= lengthModules(node);
        }
        if (node.tag == .worker and node.task.tag == .build) {
            if (node.task.info.build.modules) |mods| {
                len +%= mods.len;
            }
        }
    }
    return len;
}
fn writeModulesBuf(pkgs: [*]BuildConfig.Pkg, node: *Node) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    for (node.impl.nodes[0..node.impl.nodes_len]) |sub_node| {
        if (sub_node.tag == .group) {
            len +%= writeModulesBuf(pkgs, node);
        }
        if (node.tag == .worker and node.task.tag == .build) {
            if (node.task.info.build.modules) |mods| {
                for (mods) |mod| {
                    pkgs[len] = .{ .name = mod.name, .path = mod.path };
                    len +%= 1;
                }
            }
        }
    }
    return len;
}
pub const tracing_override: bool = false;
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
        allocator.allocate(u8, lengthJSON(&cfg)),
    );
    try file.write(.{}, 1, buf[0..writeJSON(&cfg, buf)]);
}
