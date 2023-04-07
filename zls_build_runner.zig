const root = @import("@build");
pub const dependencies = @import("@dependencies");
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
const file = srg.file;
const meta = srg.meta;
const spec = srg.spec;
const build = srg.build2;
const builtin = srg.builtin;

pub usingnamespace proc.start;

pub const BuildConfig = struct {
    packages: []Pkg,
    include_dirs: []const []const u8,
    pub const Pkg = struct {
        name: []const u8,
        path: []const u8,
    };
    pub fn formatWrite(cfg: BuildConfig, array: anytype) void {
        array.writeMany("{ \"packages\": ");
        if (cfg.packages.len == 0) {
            array.writeMany("[],");
        } else {
            array.writeMany("[");
            array.writeMany("{ \"name\": \"");
            array.writeMany(cfg.packages[0].name);
            array.writeMany("\", \"path\": \"");
            array.writeMany(cfg.packages[0].path);
            array.writeMany("\" }");
            for (cfg.packages[1..]) |pkg| {
                array.writeMany(",\n               { \"name\": \"");
                array.writeMany(pkg.name);
                array.writeMany("\", \"path\": \"");
                array.writeMany(pkg.path);
                array.writeMany("\" }");
            }
            array.writeMany("],\n");
        }
        array.writeMany("  \"include_dirs\": ");
        if (cfg.include_dirs.len == 0) {
            array.writeMany("[]");
        } else {
            array.writeMany("[\"");
            array.writeMany(cfg.include_dirs[0]);
            array.writeMany("\"");
            for (cfg.include_dirs[1..]) |dir| {
                array.writeMany(",\n                   \"");
                array.writeMany(dir);
                array.writeMany("\"");
            }
            array.writeMany("]");
        }
        array.writeMany("}\n");
    }
    pub fn formatLength(cfg: BuildConfig) u64 {
        var len: u64 = 0;
        len +%= "{ \"packages\": ".len;
        if (cfg.packages.len == 0) {
            len +%= "[],".len;
        } else {
            len +%= "[".len;
            len +%= "{ \"name\": \"".len;
            len +%= cfg.packages[0].name.len;
            len +%= "\", \"path\": \"".len;
            len +%= cfg.packages[0].path.len;
            len +%= "\" }".len;
            for (cfg.packages[1..]) |pkg| {
                len +%= ",\n               { \"name\": \"".len;
                len +%= pkg.name.len;
                len +%= "\", \"path\": \"".len;
                len +%= pkg.path.len;
                len +%= " }".len;
            }
            len +%= "],\n".len;
        }
        len +%= "  \"include_dirs\": ".len;
        if (cfg.include_dirs.len == 0) {
            len +%= "[]".len;
        } else {
            len +%= "[\"".len;
            len +%= cfg.include_dirs[0].len;
            len +%= "\"".len;
            for (cfg.include_dirs[1..]) |dir| {
                len +%= ",\n                   \"".len;
                len +%= dir.len;
                len +%= "\"".len;
            }
            len +%= "]".len;
        }
        len +%= "}\n".len;
        return len;
    }
};
const Packages = Builder.Allocator.StructuredVector(BuildConfig.Pkg);
const String = Builder.Allocator.StructuredVector(u8);

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
    var allocator: Builder.Allocator = Builder.Allocator.init(&address_space, Builder.max_thread_count);
    if (args.len < 5) {
        return error.MissingEnvironmentPaths;
    }
    const build_fn = root.buildMain;
    var builder: Builder = try meta.wrap(Builder.init(args, vars));
    try build_fn(&allocator, &builder);

    var pkg_array: Packages = Packages.init(&allocator, 32);
    for (builder.groups()) |group| {
        for (group.targets()) |target| {
            if (target.build_cmd.modules) |mods| {
                for (mods) |mod| {
                    pkg_array.appendOne(&allocator, .{ .name = mod.name, .path = mod.path });
                }
            }
        }
    }
    const cfg: BuildConfig = .{
        .packages = pkg_array.referAllDefined(),
        .include_dirs = &.{},
    };
    var str_array: String = String.init(&allocator, cfg.formatLength());
    str_array.writeFormat(cfg);
    try file.write(.{}, 1, str_array.readAll());
}
