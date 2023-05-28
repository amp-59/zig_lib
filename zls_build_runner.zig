const root = @import("@build");
const zig_lib = blk: {
    if (@hasDecl(root, "srg")) {
        break :blk root.srg;
    }
    if (@hasDecl(root, "zig_lib")) {
        break :blk root.zig_lib;
    }
};
const mem = zig_lib.mem;
const proc = zig_lib.proc;
const meta = zig_lib.meta;
const file = zig_lib.file;
const mach = zig_lib.mach;
const spec = zig_lib.spec;
const build = zig_lib.build;
const builtin = zig_lib.builtin;
const dependencies = @import("@dependencies");
pub usingnamespace root;
pub usingnamespace proc.start;
pub const is_debug: bool = false;
const Builder = if (@hasDecl(root, "Builder"))
    root.Builder
else
    build.GenericBuilder(spec.builder.default);
pub const BuildConfig = struct {
    packages: []Pkg,
    include_dirs: []const []const u8,
    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,
    };
};
inline fn cpy(buf: []u8, any: anytype) u64 {
    @ptrCast(*@TypeOf(any), buf.ptr).* = any;
    return any.len;
}
pub fn lengthJSON(cfg: *const BuildConfig) u64 {
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
pub fn writeJSON(cfg: *const BuildConfig, buf: []u8) u64 {
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
fn lengthModules(builder: *Builder) u64 {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    for (builder.grps[0..builder.grps_len]) |group| {
        for (group.trgs[0..group.trgs_len]) |target| {
            if (target.task != .build) {
                continue;
            }
            if (target.task_cmd.build.modules) |mods| {
                len +%= mods.len;
            }
        }
    }
    return len;
}
fn writeModules(pkgs: []BuildConfig.Pkg, builder: *Builder) []BuildConfig.Pkg {
    @setRuntimeSafety(false);
    var len: u64 = 0;
    for (builder.grps[0..builder.grps_len]) |group| {
        for (group.trgs[0..group.trgs_len]) |target| {
            if (target.task != .build) {
                continue;
            }
            if (target.task_cmd.build.modules) |mods| {
                for (mods) |mod| {
                    pkgs[len] = .{ .name = mod.name, .path = mod.path };
                    len +%= 1;
                }
            }
        }
    }
    return pkgs[0..len];
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8) !void {
    @setRuntimeSafety(false);
    var address_space: Builder.AddressSpace = .{};
    var allocator: Builder.Allocator = if (Builder.Allocator == mem.SimpleAllocator)
        Builder.Allocator.init_arena(Builder.AddressSpace.arena(Builder.max_thread_count))
    else
        Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try meta.wrap(
        root.buildMain(&allocator, &builder),
    );
    const pkgs_len: u64 = lengthModules(&builder);
    const pkgs: []BuildConfig.Pkg = try meta.wrap(
        allocator.allocate(BuildConfig.Pkg, pkgs_len),
    );
    const cfg: BuildConfig = .{
        .packages = writeModules(pkgs, &builder),
        .include_dirs = &.{},
    };
    const buf: []u8 = try meta.wrap(
        allocator.allocate(u8, lengthJSON(&cfg)),
    );
    try file.write(.{}, 1, buf[0..writeJSON(&cfg, buf)]);
}
