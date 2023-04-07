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
    const tok = struct {
        const lbrace_0 = "{\n";
        const pkgs = "    \"packages\": [\n";
        const lbrace_1 = "        {\n";
        const name = "            \"name\": \"";
        const path = "            \"path\": \"";
        const rbrace_1 = "        },\n";
        const incl = "    \"include_dirs\": [\n";
        const quot = "        \",\n";
        const rbrack_1 = "    ],\n";
        const line = "\",\n";
        const rbrace_0 = "}\n";
    };
    pub fn formatWrite(cfg: BuildConfig, array: anytype) void {
        array.writeMany(tok.lbrace_0 ++ tok.pkgs);
        for (cfg.packages) |pkg| {
            array.writeMany(tok.lbrace_1);
            array.writeMany(tok.name);
            array.writeMany(pkg.name);
            array.writeMany(tok.line);
            array.writeMany(tok.path);
            array.writeMany(pkg.path);
            array.writeMany(tok.line);
            array.writeMany(tok.rbrace_1);
        }
        array.writeMany(tok.rbrack_1);
        array.writeMany(tok.incl);
        for (cfg.include_dirs) |dir| {
            array.writeMany(tok.quot);
            array.writeMany(dir);
            array.writeMany(tok.line);
        }
        array.writeMany(tok.rbrack_1);
        array.writeMany(tok.rbrace_0);
    }
    pub fn formatLength(cfg: BuildConfig) u64 {
        var len: u64 = 0;
        len +%= (tok.lbrace_0 ++ tok.pkgs).len;
        for (cfg.packages) |pkg| {
            len +%= tok.lbrace_1.len;
            len +%= tok.name.len;
            len +%= pkg.name.len;
            len +%= tok.line.len;
            len +%= tok.path.len;
            len +%= pkg.path.len;
            len +%= tok.line.len;
            len +%= tok.rbrace_1.len;
        }
        len +%= tok.rbrack_1.len;
        len +%= tok.incl.len;
        for (cfg.include_dirs) |dir| {
            len +%= tok.quot.len;
            len +%= dir.len;
            len +%= tok.line.len;
        }
        len +%= tok.rbrack_1.len;
        len +%= tok.rbrace_0.len;
    }
};
const PkgArray = Builder.Allocator.StructuredVector(BuildConfig.Pkg);
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
    var pkg_array: PkgArray = PkgArray.init(&allocator, 32);
    for (builder.groups()) |group| {
        for (group.targets()) |target| {
            if (target.build_cmd.modules) |mods| {
                for (mods) |mod| {
                    pkg_array.appendOne(&allocator, .{ .name = mod.name, .path = mod.path });
                }
            }
        }
    }
    var str_array: String = String.init(&allocator, 1024 * 1024);
    str_array.writeFormat(BuildConfig{
        .packages = pkg_array.referAllDefined(),
        .include_dirs = &.{},
    });
    try file.write(.{}, 1, str_array.readAll());
}
