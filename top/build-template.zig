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
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = builtin.AddressSpace(),
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});
pub const String = Allocator.StructuredVectorLowAligned(u8, 8);
pub const Pointers = Allocator.StructuredVector([*:0]u8);
pub const StaticString = mem.StructuredAutomaticVector(u8, null, max_len, 8, .{});
pub const StaticPointers = mem.StructuredAutomaticVector([*:0]u8, null, max_args, 8, .{});
pub const Dependencies = Allocator.StructuredVector(Dependency);

const max_len: u64 = 65536;
const max_args: u64 = 512;
pub const Builder = struct {
    zig_exe: [:0]const u8,
    build_root: [:0]const u8,
    cache_dir: [:0]const u8,
    global_cache_dir: [:0]const u8,
    options: GlobalOptions,
    args: [][*:0]u8,
    vars: [][*:0]u8,
    allocator: *Allocator,
    array: *ArrayU,
    targets: ArrayC = .{},
    const ArrayC = mem.StaticArray(Target, 64);
    pub const ArrayU = Allocator.UnstructuredHolder(8, 8);
    pub fn addBuild(builder: *Builder, build_cmd: BuildCommand) *BuildCommand {
        builder.array.writeOne(BuildCommand, build_cmd);
        return builder.array.referOneBack(BuildCommand);
    }
    pub fn addFormat(builder: *Builder, fmt_cmd: FormatCommand) *FormatCommand {
        builder.array.writeOne(FormatCommand, fmt_cmd);
        return builder.array.referOneBack(FormatCommand);
    }
    pub fn addRun(builder: *Builder, run_cmd: RunCommand) *RunCommand {
        builder.array.writeOne(RunCommand, run_cmd);
        return builder.array.referOneBack(FormatCommand);
    }
    pub fn zigExePathMacro(builder: *const Builder) Macro {
        const value: Macro.Value = .{ .path = zigExePath(builder) };
        return .{ .name = "zig_exe", .value = value };
    }
    pub fn buildRootPathMacro(builder: *const Builder) Macro {
        const value: Macro.Value = .{ .path = buildRootPath(builder) };
        return .{ .name = "build_root", .value = value };
    }
    pub fn cacheDirPathMacro(builder: *const Builder) Macro {
        const value: Macro.Value = .{ .path = cacheDirPath(builder) };
        return .{ .name = "cache_dir", .value = value };
    }
    pub fn globalCacheDirPathMacro(builder: *const Builder) Macro {
        const value: Macro.Value = .{ .path = globalCacheDirPath(builder) };
        return .{ .name = "global_cache_dir", .value = value };
    }
    pub fn sourceRootPathMacro(builder: *const Builder, root: [:0]const u8) Macro {
        const value: Macro.Value = .{ .path = builder.sourceRootPath(root) };
        return .{ .name = "root", .value = value };
    }
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
    pub fn path(builder: *const Builder, name: [:0]const u8) Path {
        return .{ .builder = builder, .pathname = name };
    }
    pub fn dupe(builder: *const Builder, comptime T: type, value: T) *T {
        builder.writeOne(T, value);
        return builder.array.referOneBack(T);
    }
    pub fn dupeMany(
        builder: *const Builder,
        comptime T: type,
        values: []const T,
    ) []const T {
        if (@ptrToInt(values.ptr) < builtin.AddressSpace.low(0)) {
            return values;
        }
        builder.array.writeMany(T, values);
        return builder.array.referManyBack(T, .{ .count = values.len });
    }
    pub fn dupeWithSentinel(
        builder: *const Builder,
        comptime T: type,
        comptime sentinel: T,
        values: [:sentinel]const T,
    ) [:sentinel]const T {
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
        comptime var macros: []const Macro = args.macros orelse meta.empty;
        macros = comptime args.setMacro(macros, "runtime_assertions");
        macros = comptime args.setMacro(macros, "is_verbose");
        builder.targets.writeOne(.{
            .root = pathname,
            .build_cmd = builder.addBuild(.{
                .name = name,
                .macros = macros,
                .kind = .exe,
                .omit_frame_pointer = false,
                .single_threaded = true,
                .static = true,
                .enable_cache = true,
                .compiler_rt = false,
                .strip = true,
                .formatted_panics = false,
                .main_pkg_path = builder.build_root,
            }),
            .fmt_cmd = builder.addFormat(.{
                .ast_check = true,
            }),
            .builder = builder,
        });
        const ret: *Target = builder.targets.referOneBack();
        if (args.build_mode) |build_mode| {
            ret.build_cmd.O = build_mode;
        }
        if (args.modules) |modules| {
            const Static = struct {
                var deps: [modules.len][]const u8 = undefined;
                var len: u64 = 0;
            };
            for (modules) |module| {
                Static.deps[Static.len] = module.name;
                Static.len +%= 1;
            }
            ret.build_cmd.modules = modules;
            ret.build_cmd.dependencies = Static.deps[0..Static.len];
        }
        if (builder.options.build_mode) |build_mode| {
            ret.build_cmd.O = build_mode;
        }
        if (args.emit_bin_path) |bin_path| {
            ret.build_cmd.emit_bin = .{ .yes = builder.path(bin_path) };
        }
        return ret;
    }
    fn exec(builder: Builder, args: [][*:0]u8) !void {
        if (0 != try proc.command(.{}, builder.zig_exe, args, builder.vars)) {
            return error.UnexpectedExitStatus;
        }
    }
    pub fn init(
        options: GlobalOptions,
        allocator: *Allocator,
        array: *ArrayU,
        args: [][*:0]u8,
        vars: [][*:0]u8,
    ) Builder {
        return .{
            .zig_exe = builtin.zig_exe.?,
            .build_root = builtin.build_root.?,
            .cache_dir = builtin.cache_dir.?,
            .global_cache_dir = builtin.global_cache_dir.?,
            .options = options,
            .args = args,
            .vars = vars,
            .allocator = allocator,
            .array = array,
        };
    }
};
pub const OutputMode = enum {
    exe,
    lib,
    obj,
    run,
};
pub const BuildCommand = struct {
    kind: OutputMode,
    __compile_command: void,
};
pub const FormatCommand = struct {
    __format_command: void,
};
pub const RunCommand = struct {
    args: Pointers,
    vars: Pointers,
};
pub const Target = struct {
    root: [:0]const u8,
    build_cmd: *BuildCommand,
    fmt_cmd: ?*FormatCommand = null,
    run_cmd: ?*RunCommand = null,
    r_flag: bool = false,
    f_flag: bool = false,
    b_flag: bool = false,
    deps: ?Dependencies = null,

    builder: *Builder,
    fn buildLength(target: Target) u64 {
        const cmd: *const BuildCommand = target.build_cmd;
        var len: u64 = 4;
        switch (cmd.kind) {
            .lib, .exe, .obj => {
                len += 6 + @tagName(cmd.kind).len + 1;
            },
            .run => {
                len += @tagName(cmd.kind).len + 1;
            },
        }
        len +%= Macro.formatLength(target.builder.zigExePathMacro());
        len +%= Macro.formatLength(target.builder.buildRootPathMacro());
        len +%= Macro.formatLength(target.builder.cacheDirPathMacro());
        len +%= Macro.formatLength(target.builder.globalCacheDirPathMacro());
        cmd = buildLength;
        len +%= Path.formatLength(target.builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn buildWrite(target: Target, array: anytype) u64 {
        const cmd: *const BuildCommand = target.build_cmd;
        array.writeMany("zig\x00");
        switch (cmd.kind) {
            .lib, .exe, .obj => {
                array.writeMany("build-");
                array.writeMany(@tagName(cmd.kind));
                array.writeOne('\x00');
            },
            .run => {
                array.writeMany(@tagName(cmd.kind));
                array.writeOne('\x00');
            },
        }
        array.writeFormat(target.builder.zigExePathMacro());
        array.writeFormat(target.builder.buildRootPathMacro());
        array.writeFormat(target.builder.cacheDirPathMacro());
        array.writeFormat(target.builder.globalCacheDirPathMacro());
        cmd = buildWrite;
        array.writeFormat(target.builder.sourceRootPath(target.root));
        array.writeOne('\x00');
        return countArgs(array);
    }
    fn formatLength(target: Target) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd orelse {
            var buf: [4096]u8 = undefined;
            builtin.debug.logFaultAIO(&buf, &.{ "format command undefined for source: ", target.root, "\n" });
        };
        var len: u64 = 8;
        cmd = formatLength;
        len +%= Path.formatLength(target.builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(target: Target, array: anytype) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd orelse {
            var buf: [4096]u8 = undefined;
            builtin.debug.logFaultAIO(&buf, &.{ "format command undefined for source: ", target.root, "\n" });
        };
        array.writeMany("zig\x00");
        array.writeMany("fmt\x00");
        cmd = formatWrite;
        array.writeFormat(target.builder.sourceRootPath(target.root));
        array.writeOne('\x00');
        return countArgs(array);
    }
    pub fn buildA(target: *Target, allocator: *Allocator) !void {
        if (target.fmt_cmd != null) _ = try target.format();
        var array: String = try meta.wrap(String.init(allocator, target.buildLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, target.buildWrite(&array)));
        defer args.deinit(allocator);
        builtin.assertBelowOrEqual(u64, array.len(), max_len);
        builtin.assertBelowOrEqual(u64, makeArgs(array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.buildLength());
        target.b_flag = true;
        return target.builder.exec(args.referAllDefined());
    }
    pub fn build(target: *Target) !void {
        try target.maybeInvokeDependencies();
        if (target.fmt_cmd != null) _ = try target.format();
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        builtin.assertBelowOrEqual(u64, target.buildWrite(&array), max_args);
        builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.buildLength());
        target.b_flag = true;
        return target.builder.exec(args.referAllDefined());
    }
    pub fn formatA(target: *Target, allocator: *Allocator) !void {
        var array: String = try meta.wrap(String.init(allocator, target.formatLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, target.buildWrite(&array)));
        defer args.deinit(allocator);
        builtin.assertBelowOrEqual(u64, array.len(), max_len);
        builtin.assertBelowOrEqual(u64, makeArgs(array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.buildLength());
        target.f_flag = true;
        return target.builder.exec(args.referAllDefined());
    }
    pub fn format(target: *Target) !void {
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        builtin.assertBelowOrEqual(u64, target.formatWrite(&array), max_args);
        builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
        builtin.assertEqual(u64, array.len(), target.formatLength());
        target.f_flag = true;
        return target.builder.exec(args.referAllDefined());
    }
    pub fn run(_: Target) !void {}
    pub fn dependOn(target: *Target, dependency: Dependency) void {
        if (target.deps) |*deps| {
            deps.writeOne(dependency);
        } else {
            target.deps = Dependencies.init(target.builder.allocator, 8);
            return target.dependOn(dependency);
        }
    }
    fn maybeInvokeDependencies(target: *Target) anyerror!void {
        if (target.deps) |deps| {
            for (deps.referAllDefined()) |dep| {
                switch (dep.cmd) {
                    .build => |cmd| {
                        if (cmd) |build_cmd| {
                            var tmp = dep.target.*;
                            tmp.build_cmd = build_cmd;
                            _ = try tmp.build();
                        } else {
                            _ = try dep.target.build();
                        }
                    },
                    .run => |cmd| {
                        if (cmd) |run_cmd| {
                            var tmp = dep.target.*;
                            tmp.run_cmd = run_cmd;
                            _ = try tmp.run();
                        } else {
                            _ = try dep.target.run();
                        }
                    },
                    .fmt => |cmd| {
                        if (cmd) |fmt_cmd| {
                            var tmp = dep.target.*;
                            tmp.fmt_cmd = fmt_cmd;
                            _ = try tmp.format();
                        } else {
                            _ = try dep.target.format();
                        }
                    },
                }
            }
        }
    }
};
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
    for (array.readAll(), 0..) |c, i| {
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
/// All dependencies are build dependencies
pub const Dependency = struct {
    target: *Target,
    cmd: DependCommand,
    pub const DependCommand = union(enum) {
        fmt: ?*FormatCommand,
        run: ?*RunCommand,
        build: ?*BuildCommand,
    };
};
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const @This() = null,
    pub fn formatWrite(mod: Module, array: anytype) void {
        array.writeMany("--mod\x00");
        array.writeMany(mod.name);
        array.writeOne(':');
        if (mod.deps) |deps| {
            for (deps) |dep| {
                array.writeMany(dep.name);
                array.writeOne(',');
            }
            if (deps.len != 0) {
                array.undefine(1);
            }
        }
        array.writeOne(':');
        array.writeMany(mod.path);
        array.writeOne(0);
    }
    pub fn formatLength(mod: Module) u64 {
        var len: u64 = 0;
        len +%= 6;
        len +%= mod.name.len;
        len +%= 1;
        if (mod.deps) |deps| {
            for (deps) |dep| {
                len +%= dep.name.len;
                len +%= 1;
            }
        }
        len +%= mod.path.len;
        len +%= 1;
        return len;
    }
};
pub const Macro = struct {
    name: []const u8,
    value: Value,
    const Format = @This();
    const Value = union(enum) {
        string: [:0]const u8,
        symbol: [:0]const u8,
        constant: usize,
        path: Path,
    };
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
        modules: ?[]const Module = null,
        macros: ?[]const Macro = null,
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
// start-document option-functions.zig
fn lengthOptionalWhatNoArgWhatNot(
    option: anytype,
    len_equ: u64,
    len_yes: u64,
    len_no: u64,
) u64 {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    return len_equ +% mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg) +% 1;
                } else {
                    return len_yes;
                }
            },
            .no => {
                return len_no;
            },
        }
    }
    return 0;
}
fn lengthNonOptionalWhatNoArgWhatNot(
    option: anytype,
    len_yes: u64,
    len_no: u64,
) u64 {
    if (option) |value| {
        switch (value) {
            .yes => |yes_arg| {
                return len_yes +% mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg) +% 1;
            },
            .no => {
                return len_no;
            },
        }
    }
    return 0;
}
fn lengthWhatOrWhatNot(
    option: anytype,
    len_yes: u64,
    len_no: u64,
) u64 {
    if (option) |value| {
        if (value) {
            return len_yes;
        } else {
            return len_no;
        }
    }
    return 0;
}
fn lengthWhatHow(
    option: anytype,
    len_yes: u64,
) u64 {
    if (option) |how| {
        return len_yes +% mem.reinterpret.lengthAny(u8, fmt_spec, how) +% 1;
    }
    return 0;
}
fn lengthWhat(option: bool, len_yes: u64) u64 {
    if (option) {
        return len_yes;
    }
    return 0;
}
fn lengthHow(
    option: anytype,
) u64 {
    if (option) |how| {
        return mem.reinterpret.lengthAny(u8, fmt_spec, how);
    }
    return 0;
}
fn writeOptionalWhatNoArgWhatNot(
    array: anytype,
    option: anytype,
    equ_switch: []const u8,
    yes_switch: []const u8,
    no_switch: []const u8,
) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany(equ_switch);
                    array.writeAny(fmt_spec, yes_arg);
                    array.writeOne('\x00');
                } else {
                    array.writeMany(yes_switch);
                }
            },
            .no => {
                array.writeMany(no_switch);
            },
        }
    }
}
fn writeNonOptionalWhatNoArgWhatNot(
    array: anytype,
    option: anytype,
    yes_switch: []const u8,
    no_switch: []const u8,
) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_arg| {
                array.writeMany(yes_switch);
                array.writeAny(fmt_spec, yes_arg);
                array.writeOne('\x00');
            },
            .no => {
                array.writeMany(no_switch);
            },
        }
    }
}
fn writeWhatOrWhatNot(
    array: anytype,
    option: anytype,
    yes_switch: []const u8,
    no_switch: []const u8,
) void {
    if (option) |value| {
        if (value) {
            array.writeMany(yes_switch);
        } else {
            array.writeMany(no_switch);
        }
    }
}
fn writeWhatHow(
    array: anytype,
    option: anytype,
    yes_switch: []const u8,
) void {
    if (option) |value| {
        array.writeMany(yes_switch);
        array.writeAny(fmt_spec, value);
        array.writeOne('\x00');
    }
}
fn writeWhat(
    array: anytype,
    option: bool,
    yes_switch: []const u8,
) void {
    if (option) {
        array.writeMany(yes_switch);
    }
}
fn writeHow(
    array: anytype,
    option: anytype,
) void {
    if (option) |how| {
        array.writeAny(fmt_spec, how);
    }
}
// finish-document option-functions.zig
