//! start
// start-document build-struct.zig
const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const proc = @import("./proc.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
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

pub const CompileCommand = struct {
    kind: enum { exe, lib, obj, run },
    _: void,
};
pub const Target = struct {
    root: [:0]const u8,
    cmd: *CompileCommand,
    flag: bool = false,

    builder: *Builder,

    fn buildLength(target: Target) u64 {
        var len: u64 = 4;
        switch (target.cmd.kind) {
            .lib, .exe, .obj => {
                len += 6 + @tagName(target.cmd.kind).len + 1;
            },
            .run => {
                len += @tagName(target.cmd.kind).len + 1;
            },
        }
        len +%= Macro.formatLength(target.builder.zigExePathMacro());
        len +%= Macro.formatLength(target.builder.buildRootPathMacro());
        len +%= Macro.formatLength(target.builder.cacheDirPathMacro());
        len +%= Macro.formatLength(target.builder.globalCacheDirPathMacro());
        _ = buildLength;
        len +%= Path.formatLength(target.builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn buildWrite(target: Target, array: anytype) u64 {
        array.writeMany("zig\x00");
        switch (target.cmd.kind) {
            .lib, .exe, .obj => {
                array.writeMany("build-");
                array.writeMany(@tagName(target.cmd.kind));
                array.writeOne('\x00');
            },
            .run => {
                array.writeMany(@tagName(target.cmd.kind));
                array.writeOne('\x00');
            },
        }
        array.writeFormat(target.builder.zigExePathMacro());
        array.writeFormat(target.builder.buildRootPathMacro());
        array.writeFormat(target.builder.cacheDirPathMacro());
        array.writeFormat(target.builder.globalCacheDirPathMacro());
        _ = buildWrite;
        array.writeFormat(target.builder.sourceRootPath(target.root));
        array.writeOne('\x00');
        return countArgs(array);
    }
    pub fn compileA(target: Target, allocator: *Allocator) !u64 {
        var array: String = try meta.wrap(String.init(allocator, target.buildLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, target.buildWrite(&array)));
        defer args.deinit(allocator);
        builtin.assertBelowOrEqual(u64, array.len(), max_len);
        builtin.assertBelowOrEqual(u64, makeArgs(array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.buildLength());
        return target.builder.exec(args.referAllDefined());
    }
    pub fn compile(target: Target) !u64 {
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        builtin.assertBelowOrEqual(u64, target.buildWrite(&array), max_args);
        builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.buildLength());
        return target.builder.exec(args.referAllDefined());
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
        mem.set(args.impl.undefined_byte_address(), @as(u64, 0), 1);
    }
    return args.len();
}
// finish-document build-struct.zig
// start-document build-types.zig
pub const Packages = []const Pkg;
pub const Macros = []const Macro;
pub const Pkg = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(pkg: Pkg, array: anytype) void {
        array.writeMany("--pkg-begin\x00");
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
        array.writeMany("--pkg-end\x00");
    }
    pub fn formatLength(pkg: Pkg) u64 {
        var len: u64 = 0;
        len +%= 12;
        len +%= pkg.name.len +% 1;
        len +%= pkg.path.len +% 1;
        if (pkg.deps) |deps| {
            for (deps) |dep| {
                len +%= 1;
                len +%= dep.formatLength();
            }
        }
        len +%= 10;
        return len;
    }
};
/// Zig says value does not need to be defined, in which case default to 1
pub const Macro = struct {
    name: []const u8,
    value: union(enum) {
        string: [:0]const u8,
        symbol: [:0]const u8,
        constant: usize,
        path: Path,
    },
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-D");
        array.writeMany(format.name);
        array.writeMany("=");
        switch (format.value) {
            .string => |string| {
                array.writeOne('"');
                array.writeMany(string);
                array.writeOne('"');
            },
            .path => |path| {
                array.writeOne('"');
                array.writeFormat(path);
                array.writeOne('"');
            },
            .symbol => |symbol| {
                array.writeMany(symbol);
            },
            .constant => |constant| {
                array.writeAny(fmt_spec, constant);
            },
        }
        array.writeOne(0);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        len +%= 1;
        switch (format.value) {
            .string => |string| {
                len +%= 1 +% string.len +% 1;
            },
            .path => |path| {
                len +%= 1 +% path.formatLength() +% 1;
            },
            .symbol => |symbol| {
                len +%= symbol.len;
            },
            .constant => |constant| {
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, constant);
            },
        }
        len +%= 1;
        return len;
    }
};
pub const CFlags = struct {
    flags: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        array.writeMany("-cflags");
        array.writeOne(0);
        for (format.flags) |flag| {
            array.writeMany(flag);
            array.writeOne(0);
        }
        array.writeOne("--\x00");
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 8;
        for (format.flags) |flag| {
            len +%= flag.len;
            len +%= 1;
        }
        len +%= 3;
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
    pub const release_fast = &(.ReleaseFast);
    pub const release_safe = &(.ReleaseSafe);
    pub const release_small = &(.ReleaseSmall);

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
pub const Builder = struct {
    zig_exe: [:0]const u8,
    build_root: [:0]const u8,
    cache_dir: [:0]const u8,
    global_cache_dir: [:0]const u8,
    options: GlobalOptions,
    args: [][*:0]u8,
    vars: [][*:0]u8,
    allocator: *Allocator,
    targets: ArrayC = .{},
    array: *ArrayU,
    const ArrayC = mem.StaticArray(Target, 64);
    pub const ArrayU = Allocator.UnstructuredHolder(8, 8);

    pub fn zigExePath(builder: *const Builder) Path {
        return builder.path(builder.zig_exe);
    }
    pub fn buildRootPath(builder: *const Builder) Path {
        return builder.path(builder.build_root);
    }
    pub fn cacheDirPath(builder: *const Builder) Path {
        return builder.path(builder.cache_dir);
    }
    pub fn globalCacheDirPath(builder: *const Builder) Path {
        return builder.path(builder.global_cache_dir);
    }
    pub fn sourceRootPath(builder: *const Builder, root: [:0]const u8) Path {
        return builder.path(root);
    }
    pub fn zigExePathMacro(builder: *const Builder) Macro {
        return .{ .name = "zig_exe", .value = .{ .path = zigExePath(builder) } };
    }
    pub fn buildRootPathMacro(builder: *const Builder) Macro {
        return .{ .name = "build_root", .value = .{ .path = buildRootPath(builder) } };
    }
    pub fn cacheDirPathMacro(builder: *const Builder) Macro {
        return .{ .name = "cache_dir", .value = .{ .path = cacheDirPath(builder) } };
    }
    pub fn globalCacheDirPathMacro(builder: *const Builder) Macro {
        return .{ .name = "global_cache_dir", .value = .{ .path = globalCacheDirPath(builder) } };
    }
    pub fn sourceRootPathMacro(builder: *const Builder, root: [:0]const u8) Macro {
        return .{ .name = "root", .value = .{ .path = builder.sourceRootPath(root) } };
    }
    pub fn path(builder: *const Builder, name: [:0]const u8) Path {
        return .{ .builder = builder, .pathname = name };
    }
    pub fn dupe(builder: *const Builder, comptime T: type, value: T) *T {
        builder.writeOne(T, value);
        return builder.array.referOneBack(T);
    }
    pub fn dupeMany(builder: *const Builder, comptime T: type, values: []const T) []const T {
        if (@ptrToInt(values.ptr) < builtin.AddressSpace.low(0)) {
            return values;
        }
        builder.array.writeMany(T, values);
        return builder.array.referManyBack(T, .{ .count = values.len });
    }
    pub fn dupeWithSentinel(builder: *const Builder, comptime T: type, comptime sentinel: T, values: [:sentinel]const T) [:sentinel]const T {
        if (@ptrToInt(values.ptr) < builtin.AddressSpace.low(0)) {
            return values;
        }
        defer builder.array.define(T, .{ .count = 1 });
        builder.array.writeMany(T, values);
        builder.array.referOneUndefined(T).* = sentinel;
        return builder.array.referManyWithSentinelBack(T, 0, .{ .count = values.len });
    }
    pub fn addExecutable(
        builder: *Builder,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
        comptime args: Args(name),
    ) *Target {
        const ret: *Target = builder.targets.referOneUndefined();
        const cmd: *CompileCommand = builder.array.referOneUndefined(CompileCommand);
        builder.array.define(CompileCommand, .{ .count = 1 });
        ret.* = .{
            .root = pathname,
            .cmd = cmd,
            .builder = builder,
        };
        comptime var macros: []const Macro = args.macros orelse meta.empty;
        macros = comptime args.setMacro(macros, "runtime_assertions");
        macros = comptime args.setMacro(macros, "is_verbose");
        if (args.build_mode) |build_mode| {
            ret.cmd.O = build_mode;
        }
        if (builder.options.build_mode) |build_mode| {
            ret.cmd.O = build_mode;
        }
        if (args.emit_bin_path) |bin_path| {
            ret.cmd.emit_bin = .{ .yes = builder.path(bin_path) };
        }
        ret.cmd.* = .{
            .kind = .exe,
            .name = name,
            .omit_frame_pointer = false,
            .single_threaded = true,
            .static = true,
            .enable_cache = true,
            .compiler_rt = false,
            .strip = true,
            .formatted_panics = false,
            .main_pkg_path = builder.build_root,
            .macros = macros,
            .packages = args.packages,
        };
        builder.targets.define(1);
        return ret;
    }
    fn exec(builder: Builder, args: [][*:0]u8) !u64 {
        return proc.command(.{}, builder.zig_exe, args, builder.vars);
    }
};
pub const Path = struct {
    builder: ?*const Builder = null,
    pathname: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.builder) |builder| {
            if (format.pathname[0] != '/') {
                array.writeMany(builder.build_root);
                array.writeOne('/');
            }
        }
        array.writeMany(format.pathname);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.builder) |builder| {
            if (format.pathname[0] != '/') {
                len +%= builder.build_root.len;
                len +%= 1;
            }
        }
        len +%= format.pathname.len;
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
        runtime_assertions: ?bool = null,
        is_perf: ?bool = null,
        is_verbose: ?bool = null,
        is_silent: ?bool = null,
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
                        .value = .{ .constant = if (field) 1 else 0 },
                    });
                }
                return macros;
            }
        }
    };
}
// finish-document build-types.zig
