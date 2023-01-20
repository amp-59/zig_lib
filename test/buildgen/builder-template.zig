//! start
const srg = @import("zig_lib");
const mem = srg.mem;
const sys = srg.sys;
const fmt = srg.fmt;
const proc = srg.proc;
const file = srg.file;
const meta = srg.meta;
const preset = srg.preset;
const builtin = srg.builtin;
// start-document builder-struct.zig
const fmt_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.fmt;
    tmp.integral = .{ .format = .dec };
    break :blk tmp;
};
pub const BuildCmdSpec = struct {
    max_len: u64 = 1024 * 1024,
    max_args: u64 = 1024,
    Allocator: ?type = null,
};
pub const AddressSpace = preset.address_space.exact_8;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
pub const String = Allocator.StructuredVectorLowAligned(u8, 8);
pub const Pointers = Allocator.StructuredVector([*:0]u8);
pub const StaticString = mem.StructuredAutomaticVector(u8, null, max_len, 8, .{});
pub const StaticPointers = mem.StructuredAutomaticVector([*:0]u8, null, max_args, 8, .{});
const max_len: u64 = 65536;
const max_args: u64 = 512;
pub const BuildCmd = struct {
    const Builder: type = @This();
    const zig: [:0]const u8 = "zig";
    zig_exe: ?[:0]const u8 = null,
    cmd: enum { exe, lib, obj, fmt, ast_check, run },
    root: [:0]const u8,
    _: void,
    pub fn allocateExec(build: Builder, vars: [][*:0]u8, allocator: *Allocator) !u64 {
        var array: String = try meta.wrap(String.init(allocator, build.buildLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, build.buildWrite(&array)));
        builtin.assertAboveOrEqual(u64, max_args, makeArgs(array, &args));
        builtin.assertAboveOrEqual(u64, max_len, array.len());
        defer args.deinit(allocator);
        return build.genericExec(args.referAllDefined(), vars);
    }
    pub fn exec(build: Builder, vars: [][*:0]u8) !u64 {
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        _ = build.buildWrite(&array);
        _ = makeArgs(&array, &args);
        return build.genericExec(args.referAllDefined(), vars);
    }
    fn genericExec(builder: Builder, args: [][*:0]u8, vars: [][*:0]u8) !u64 {
        return proc.command(.{}, builder.zig_exe.?, args, vars);
    }
};
/// Environment variables needed to find user home directory
pub fn zigCacheDirGlobal(vars: [][*:0]u8, buf: [:0]u8) ![:0]u8 {
    const home_pathname: [:0]const u8 = try file.home(vars);
    var len: u64 = 0;
    for (home_pathname) |c, i| buf[len + i] = c;
    len += home_pathname.len;
    for ("/.cache/zig") |c, i| buf[len + i] = c;
    return buf[0 .. len + 11 :0];
}
fn countArgs(array: anytype) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count += 1;
        }
    }
    return count + 1;
}
fn makeArgs(array: anytype, args: anytype) u64 {
    var idx: u64 = 0;
    for (array.readAll()) |c, i| {
        if (c == 0) {
            args.writeOne(array.referManyWithSentinelAt(0, idx).ptr);
            idx = i + 1;
        }
    }
    if (args.len() != 0) {
        mem.set(args.impl.next(), @as(u64, 0), 1);
    }
    return args.len();
}
// finish-document builder-struct.zig
// start-document builder-types.zig
pub const Packages = []const Pkg;
pub const Macros = []const Macro;
pub const Pkg = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(pkg: Pkg, array: anytype) void {
        array.writeMany("--pkg-begin");
        array.writeOne(0);
        array.writeMany(pkg.name);
        array.writeOne(0);
        array.writeMany(pkg.path);
        array.writeOne(0);
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                array.writeOne(0);
                dep.formatWrite(array);
            }
        }
        array.writeMany("--pkg-end");
        array.writeOne(0);
    }
    pub fn formatLength(pkg: Pkg) u64 {
        var len: u64 = 0;
        len +%= 11;
        len +%= 1;
        len +%= pkg.name.len;
        len +%= 1;
        len +%= pkg.path.len;
        len +%= 1;
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                len +%= 1;
                len +%= dep.formatLength();
            }
        }
        len +%= 9;
        len +%= 1;
        return len;
    }
};
/// Zig says value does not need to be defined, in which case default to 1
pub const Macro = struct {
    name: []const u8,
    value: ?[]const u8,
    quote: bool = false,
    const Format = @This();
    fn looksLikePath(format: Format) bool {
        var no_sep: u64 = 0;
        if (format.value) |value| {
            for (value) |c| {
                if (c == '/') no_sep += 1;
            }
        }
        return no_sep > 1;
    }
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        if (format.value) |value| {
            array.writeMany("=");
            if (format.quote or format.looksLikePath()) {
                array.writeOne('"');
                array.writeMany(value);
                array.writeOne('"');
            } else {
                array.writeMany(value);
            }
        }
        array.writeOne(0);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        if (format.value) |value| {
            len +%= 1;
            if (format.quote or format.looksLikePath()) {
                len +%= 1;
                len +%= value.len;
                len +%= 1;
            } else {
                len +%= value.len;
            }
        }
        len +%= 1;
        return len;
    }
};
pub const GlobalOptions = struct {
    build_mode: ?@TypeOf(builtin.zig.mode) = null,
    strip: bool = true,
    verbose: bool = false,

    pub const Map = proc.GenericOptions(GlobalOptions);
    pub const yes = .{ .boolean = true };
    pub const no = .{ .boolean = false };
    pub const debug = .{ .action = setDebug };
    pub const release_fast = .{ .action = setReleaseFast };
    pub const release_safe = .{ .action = setReleaseFast };
    pub const release_small = .{ .action = setReleaseFast };

    pub fn setReleaseFast(options: *GlobalOptions) void {
        options.build_mode = .ReleaseFast;
    }
    pub fn setReleaseSmall(options: *GlobalOptions) void {
        options.build_mode = .ReleaseSmall;
    }
    pub fn setReleaseSafe(options: *GlobalOptions) void {
        options.build_mode = .ReleaseSafe;
    }
    pub fn setDebug(options: *GlobalOptions) void {
        options.build_mode = .Debug;
    }
};
pub const Context = struct {
    zig_exe: [:0]const u8,
    build_root: [:0]const u8,
    cache_dir: [:0]const u8,
    global_cache_dir: [:0]const u8,
    options: GlobalOptions,
    cmds: ArrayC = .{},
    args: [][*:0]u8,
    vars: [][*:0]u8,
    allocator: *Allocator,
    array: *ArrayU,

    const ArrayC = mem.StaticArray(BuildCmd, 64);
    pub const ArrayU = Allocator.UnstructuredHolder(8, 8);
    pub fn path(ctx: *Context, name: [:0]const u8) Path {
        return .{ .ctx = ctx, .relative = ctx.dupeWithSentinel(u8, 0, name) };
    }
    pub fn dupe(ctx: *Context, comptime T: type, values: []const T) []const T {
        ctx.array.writeMany(T, values);
        return ctx.array.referManyBack(T, .{ .count = values.len });
    }
    pub fn dupeWithSentinel(
        ctx: *Context,
        comptime T: type,
        comptime sentinel: T,
        values: [:sentinel]const T,
    ) [:sentinel]const T {
        ctx.array.writeMany(T, values);
        ctx.array.referOneUndefined(T).* = sentinel;
        defer ctx.array.define(T, .{ .count = 1 });
        return ctx.array.referManyWithSentinelBack(T, 0, .{ .count = values.len });
    }
    pub fn addExecutable(
        ctx: *Context,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
        comptime args: Args(name),
    ) *BuildCmd {
        const ret: *BuildCmd = ctx.cmds.referOneUndefined();
        ret.* = .{
            .root = pathname,
            .cmd = .exe,
            .name = name,
        };
        ret.zig_exe = ctx.zig_exe;
        comptime var macros: []const Macro = args.macros orelse meta.empty;
        macros = comptime args.setMacro(macros, "is_correct");
        macros = comptime args.setMacro(macros, "is_verbose");
        if (args.build_mode) |build_mode| {
            ret.O = build_mode;
        }
        if (ctx.options.build_mode) |build_mode| {
            ret.O = build_mode;
        }
        if (args.emit_bin_path) |bin_path| {
            ret.emit_bin = .{ .yes = ctx.path(bin_path) };
        }
        if (args.emit_asm_path) |asm_path| {
            ret.emit_asm = .{ .yes = ctx.path(asm_path) };
        }
        ret.omit_frame_pointer = false;
        ret.single_threaded = true;
        ret.static = true;
        ret.enable_cache = true;
        ret.compiler_rt = false;
        ret.strip = true;
        ret.main_pkg_path = ctx.build_root;
        ret.macros = macros;
        ret.packages = args.packages;
        ctx.cmds.define(1);
        return ret;
    }
};
pub const Path = struct {
    ctx: *Context,
    relative: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany(format.ctx.build_root);
        array.writeOne('/');
        array.writeMany(format.relative);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= format.ctx.build_root.len;
        len +%= 1;
        len +%= format.relative.len;
        return len;
    }
};
fn Args(comptime name: [:0]const u8) type {
    return struct {
        make_step_name: [:0]const u8 = name,
        make_step_desc: [:0]const u8 = "Build " ++ name,
        run_step_name: [:0]const u8 = "run-" ++ name,
        run_step_desc: [:0]const u8 = "...",
        emit_bin_path: ?[:0]const u8 = "zig-out/bin/" ++ name,
        emit_asm_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".s",
        emit_analysis_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".analysis",
        build_mode: ?@TypeOf(builtin.zig.mode) = null,
        build_working_directory: bool = false,
        is_test: ?bool = null,
        is_support: ?bool = null,
        is_correct: ?bool = null,
        is_perf: ?bool = null,
        is_verbose: ?bool = null,
        is_tolerant: ?bool = null,
        define_build_root: bool = true,
        define_build_working_directory: bool = true,
        is_large_test: bool = false,
        strip: bool = true,
        packages: ?Packages = null,
        macros: ?Macros = null,
        fn setMacro(
            comptime args: @This(),
            comptime macros: []const Macro,
            comptime field_name: [:0]const u8,
        ) []const Macro {
            comptime {
                if (@field(args, field_name)) |field| {
                    return meta.concat(Macro, macros, .{
                        .name = field_name,
                        .value = if (field) "1" else "0",
                    });
                }
                return macros;
            }
        }
    };
}
// finish-document builder-types.zig
