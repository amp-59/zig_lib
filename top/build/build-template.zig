const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const file = @import("../file.zig");
const meta = @import("../meta.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const time = @import("../time.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
// start-document build-struct.zig
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = builtin.AddressSpace(),
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.small,
});
pub const ArgsString = mem.StructuredAutomaticVector(u8, &@as(u8, 0), max_len, 8, .{});
pub const ArgsPointers = mem.StructuredAutomaticVector([*:0]u8, null, max_args, 8, .{});

pub const max_len: u64 = builtin.define("max_command_len", u64, 65536);
pub const max_args: u64 = builtin.define("max_command_args", u64, 512);
pub const max_relevant_depth: u64 = builtin.define("max_relevant_depth", u64, 0);

pub const OutputMode = enum { exe, lib, obj };
pub const GlobalOptions = struct {
    mode: ?builtin.Mode = null,
    strip: bool = true,
    verbose: bool = false,
    cmd: Target.Tag = .build,
    emit_bin: bool = true,
    emit_asm: bool = false,
    pub const Map = proc.GenericOptions(GlobalOptions);
};
pub const BuilderSpec = struct {
    logging: struct {
        path: builtin.Logging.AcquireErrorFault = .{},
        fstatat: builtin.Logging.SuccessErrorFault = .{},
        command: builtin.Logging.SuccessErrorFault = .{},
    },
    errors: struct {
        path: sys.ErrorPolicy = sys.open_errors,
        fstatat: sys.ErrorPolicy = sys.stat_errors,
        command: sys.ErrorPolicy = sys.execve_errors,
        gettime: sys.ErrorPolicy = sys.clock_get_errors,
    },
};
pub const BuildCommand = struct {
    kind: OutputMode,
    __compile_command: void,
};
pub const FormatCommand = struct {
    __format_command: void,
};
pub const RunCommand = struct {
    array: ArgsString = undefined,
    pub fn addRunArgument(run_cmd: *RunCommand, any: anytype) void {
        if (@typeInfo(@TypeOf(any)) == .Struct) {
            run_cmd.array.writeAny(preset.reinterpret.fmt, any);
        } else {
            run_cmd.array.writeMany(any);
        }
        if (run_cmd.array.readOneBack() != 0) {
            run_cmd.array.writeOne(0);
        }
    }
};
pub fn saveString(allocator: *Allocator, values: []const u8) [:0]u8 {
    var buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, values.len, 0);
    mach.memcpy(buf.ptr, values.ptr, values.len);
    return buf;
}
pub fn saveStrings(allocator: *Allocator, values: []const []const u8) [][:0]u8 {
    var buf: [][:0]u8 = allocator.allocateIrreversible([:0]u8, values.len);
    var idx: u64 = 0;
    for (values) |value| {
        buf[idx] = saveString(allocator, value);
        idx +%= 1;
    }
}
pub fn concatStrings(allocator: *Allocator, values: []const []const u8) [:0]u8 {
    var len: u64 = 0;
    for (values) |value| len +%= value.len;
    const buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, len, 0);
    var idx: u64 = 0;
    for (values) |value| {
        mach.memcpy(buf[idx..].ptr, value.ptr, value.len);
        idx +%= value.len;
    }
    return buf;
}
pub const Builder = struct {
    paths: Paths,
    options: GlobalOptions,
    groups: GroupList,
    args: [][*:0]u8,
    vars: [][*:0]u8,
    run_args: [][*:0]u8 = &.{},
    dir_fd: u64,
    depth: u64 = 0,
    pub const Paths = struct {
        zig_exe: [:0]const u8,
        build_root: [:0]const u8,
        cache_dir: [:0]const u8,
        global_cache_dir: [:0]const u8,
    };
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
        return builder.path(builder.paths.zig_exe);
    }
    pub fn buildRootPath(builder: *const Builder) Path {
        return builder.path(builder.paths.build_root);
    }
    pub fn cacheDirPath(builder: *const Builder) Path {
        return builder.path(builder.paths.cache_dir);
    }
    pub fn globalCacheDirPath(builder: *const Builder) Path {
        return builder.path(builder.paths.global_cache_dir);
    }
    pub fn sourceRootPath(builder: *const Builder, root: [:0]const u8) Path {
        return builder.path(root);
    }
    pub fn path(builder: *const Builder, name: [:0]const u8) Path {
        return .{ .absolute = builder.paths.build_root, .pathname = name };
    }
    pub inline fn addTarget(
        builder: *Builder,
        comptime spec: TargetSpec,
        allocator: *Allocator,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
    ) *Target {
        return builder.groups.left.this.addTarget(spec, allocator, name, pathname);
    }
    pub fn addGroup(
        builder: *Builder,
        allocator: *Allocator,
        comptime name: [:0]const u8,
    ) *Group {
        defer builder.groups.head();
        return builder.groups.create(allocator, .{
            .name = name,
            .builder = builder,
            .targets = TargetList.init(allocator),
        });
    }
    fn exec(builder: Builder, args: [][*:0]u8, ts: *time.TimeSpec) !u8 {
        const start: time.TimeSpec = try time.get(.{}, .realtime);
        const rc: u8 = try proc.command(.{}, builder.paths.zig_exe, args, builder.vars);
        const finish: time.TimeSpec = try time.get(.{}, .realtime);
        ts.* = time.diff(finish, start);
        return rc;
    }
    fn system(builder: Builder, args: [][*:0]u8, ts: *time.TimeSpec) !u8 {
        const start: time.TimeSpec = try time.get(.{}, .realtime);
        const ret: u8 = try proc.command(.{}, meta.manyToSlice(args[0]), args, builder.vars);
        const finish: time.TimeSpec = try time.get(.{}, .realtime);
        ts.* = time.diff(finish, start);
        return ret;
    }
    pub fn init(allocator: *Allocator, paths: Paths, options: GlobalOptions, args: [][*:0]u8, vars: [][*:0]u8) !Builder {
        const dir_fd: u64 = try file.path(.{}, paths.build_root);
        try writeEnv(allocator, paths);
        return .{
            .paths = paths,
            .options = options,
            .args = args,
            .vars = vars,
            .groups = GroupList.init(allocator),
            .dir_fd = dir_fd,
        };
    }
    fn stat(builder: *Builder, name: [:0]const u8) ?file.FileStatus {
        return file.fstatAt(.{ .logging = preset.logging.success_error_fault.silent }, builder.dir_fd, name) catch null;
    }
    fn buildLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const BuildCommand = target.build_cmd;
        var len: u64 = 4;
        len +%= 6 +% @tagName(cmd.kind).len +% 1;
        len +%= Macro.formatLength(builder.zigExePathMacro());
        len +%= Macro.formatLength(builder.buildRootPathMacro());
        len +%= Macro.formatLength(builder.cacheDirPathMacro());
        len +%= Macro.formatLength(builder.globalCacheDirPathMacro());
        cmd = buildLength;
        len +%= Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        ModuleDependency.l_leader = true;
        return len;
    }
    fn buildWrite(builder: *Builder, target: *const Target, array: anytype) void {
        const cmd: *const BuildCommand = target.build_cmd;
        array.writeMany("zig\x00build-");
        array.writeMany(@tagName(cmd.kind));
        array.writeOne('\x00');
        array.writeFormat(builder.zigExePathMacro());
        array.writeFormat(builder.buildRootPathMacro());
        array.writeFormat(builder.cacheDirPathMacro());
        array.writeFormat(builder.globalCacheDirPathMacro());
        cmd = buildWrite;
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
        ModuleDependency.w_leader = true;
    }
    fn formatLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd;
        var len: u64 = 8;
        cmd = formatLength;
        len +%= Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(builder: *Builder, target: *const Target, array: anytype) void {
        const cmd: *const FormatCommand = target.fmt_cmd;
        array.writeMany("zig\x00fmt\x00");
        cmd = formatWrite;
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
    }
    pub fn build(builder: *Builder, target: *Target) !void {
        try format(builder, target);
        if (target.done(.build)) return;
        if (target.have(.build)) {
            target.do(.build);
            builder.depth +%= 1;
            try invokeDependencies(builder, target);
            var array: ArgsString = undefined;
            array.undefineAll();
            var build_args: ArgsPointers = undefined;
            build_args.undefineAll();
            var build_time: time.TimeSpec = undefined;
            const bin_path: [:0]const u8 = target.binPath().pathname;
            const old_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
            builder.buildWrite(target, &array);
            makeArgs(&array, &build_args);
            const rc: u8 = try builder.exec(build_args.referAllDefined(), &build_time);
            const new_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
            builder.depth -%= 1;
            if (builder.depth <= max_relevant_depth) {
                debug.buildNotice(target.name, build_time, old_size, new_size);
            }
            if (rc != 0) {
                builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
            }
        }
    }
    pub fn format(builder: *Builder, target: *Target) !void {
        if (target.done(.fmt)) return;
        if (target.have(.fmt)) {
            target.do(.fmt);
            try invokeDependencies(builder, target);
            var array: ArgsString = undefined;
            array.undefineAll();
            var format_args: ArgsPointers = undefined;
            format_args.undefineAll();
            var format_time: time.TimeSpec = undefined;
            builder.formatWrite(target, &array);
            makeArgs(&array, &format_args);
            const rc: u8 = try builder.exec(format_args.referAllDefined(), &format_time);
            if (builder.depth <= max_relevant_depth) {
                debug.formatNotice(target.name, format_time);
            }
            if (rc != 0) {
                builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
            }
        }
    }
    pub fn run(builder: *Builder, target: *Target) !void {
        if (target.done(.run)) return;
        if (target.have(.run) and target.have(.build)) {
            target.do(.run);
            try build(builder, target);
            var run_args: ArgsPointers = undefined;
            run_args.undefineAll();
            var run_time: time.TimeSpec = undefined;
            makeArgs(&target.run_cmd.array, &run_args);
            const rc: u8 = try builder.system(run_args.referAllDefined(), &run_time);
            if (rc != 0 or builder.depth <= max_relevant_depth) {
                debug.runNotice(target.name, run_time, rc);
            }
            if (rc != 0) {
                builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
            }
        }
    }
    fn invokeDependencies(builder: *Builder, target: *Target) anyerror!void {
        target.deps.head();
        while (target.deps.next()) |node| : (target.deps.node = node) {
            switch (target.deps.node.this.tag) {
                .build => try build(builder, target.deps.node.this.target),
                .run => try run(builder, target.deps.node.this.target),
                .fmt => try format(builder, target.deps.node.this.target),
            }
        }
    }
};
pub const TargetSpec = struct {
    build: ?OutputMode = .exe,
    run: bool = true,
    fmt: bool = false,
    mode: builtin.Mode = .Debug,
    mods: []const Module = &.{},
    deps: []const ModuleDependency = &.{},
    macros: []const Macro = &.{},
};
pub const GroupList = GenericList(Group);
pub const Group = struct {
    name: [:0]const u8,
    targets: TargetList,
    builder: *Builder,
    pub fn addTarget(
        group: *Group,
        spec: TargetSpec,
        allocator: *Allocator,
        name: [:0]const u8,
        pathname: [:0]const u8,
    ) *Target {
        const mode: builtin.Mode = group.builder.options.mode orelse spec.mode;
        const ret: *Target = group.targets.create(allocator, .{
            .name = saveString(allocator, name),
            .root = saveString(allocator, pathname),
            .deps = Target.DependencyList.init(allocator),
        });
        if (spec.fmt) {
            const fmt_cmd: *FormatCommand = allocator.createIrreversible(FormatCommand);
            mach.memset(@ptrCast([*]u8, fmt_cmd), 0, @sizeOf(FormatCommand));
            ret.fmt_cmd = fmt_cmd;
            ret.give(.fmt);
        }
        if (spec.build) |kind| {
            const bin_path: Path = group.builder.path(concatStrings(allocator, switch (kind) {
                .exe => &.{ "zig-out/bin/", name },
                .obj => &.{ "zig-out/bin/", name, ".o" },
                .lib => &.{ "zig-out/lib/", name, ".so" },
            }));
            const asm_path: Path = group.builder.path(concatStrings(
                allocator,
                &.{ "zig-out/bin/", name, ".s" },
            ));
            const build_cmd: *BuildCommand = allocator.createIrreversible(BuildCommand);
            mach.memset(@ptrCast([*]u8, build_cmd), 0, @sizeOf(BuildCommand));
            build_cmd.main_pkg_path = group.builder.paths.build_root;
            build_cmd.emit_bin = if (group.builder.options.emit_bin) .{ .yes = bin_path } else null;
            build_cmd.emit_asm = if (group.builder.options.emit_asm) .{ .yes = asm_path } else null;
            build_cmd.name = name;
            build_cmd.kind = kind;
            build_cmd.omit_frame_pointer = false;
            build_cmd.single_threaded = true;
            build_cmd.static = true;
            build_cmd.enable_cache = true;
            build_cmd.gc_sections = kind == .exe;
            build_cmd.function_sections = true;
            build_cmd.compiler_rt = false;
            build_cmd.strip = group.builder.options.strip;
            build_cmd.image_base = 0x10000;
            build_cmd.modules = spec.mods;
            build_cmd.dependencies = spec.deps;
            build_cmd.mode = mode;
            build_cmd.macros = spec.macros;
            build_cmd.reference_trace = true;
            ret.build_cmd = build_cmd;
            ret.give(.build);
        }
        if (spec.run) {
            const run_cmd: *RunCommand = allocator.createIrreversible(RunCommand);
            mach.memset(@ptrCast([*]u8, run_cmd), 0, @sizeOf(RunCommand));
            run_cmd.array.writeFormat(ret.binPath());
            run_cmd.array.writeOne(0);
            ret.run_cmd = run_cmd;
            ret.give(.run);
        }
        return ret;
    }
};
pub const TargetList = GenericList(Target);
pub const Target = struct {
    name: [:0]const u8,
    root: [:0]const u8,
    descr: ?[:0]const u8 = null,
    build_cmd: *BuildCommand = undefined,
    fmt_cmd: *FormatCommand = undefined,
    run_cmd: *RunCommand = undefined,
    deps: DependencyList,
    flags: u8 = 0,

    pub const Process = enum { explicit, dependency };
    pub const Tag = enum {
        fmt,
        build,
        run,
        fn have(comptime tag: Tag) u8 {
            const shift_amt: u8 = @enumToInt(tag);
            return 1 << (2 *% shift_amt);
        }
        fn done(comptime tag: Tag) u8 {
            const shift_amt: u8 = @enumToInt(tag);
            return 1 << (2 *% shift_amt +% 1);
        }
    };
    inline fn give(target: *Target, comptime tag: Tag) void {
        target.flags |= comptime Tag.have(tag);
    }
    inline fn take(target: *Target, comptime tag: Tag) void {
        target.flags &= ~comptime Tag.have(tag);
    }
    inline fn have(target: *Target, comptime tag: Tag) bool {
        return (target.flags & comptime Tag.have(tag)) != 0;
    }
    inline fn do(target: *Target, comptime tag: Tag) void {
        target.flags |= comptime Tag.done(tag);
    }
    inline fn undo(target: *Target, comptime tag: Tag) void {
        target.flags |= comptime Tag.done(tag);
    }
    inline fn done(target: *Target, comptime tag: Tag) bool {
        return (target.flags & comptime Tag.done(tag)) != 0;
    }
    inline fn assertHave(target: *const Target, comptime tag: Tag, comptime src: builtin.SourceLocation) void {
        mach.assert(target.have(tag), src.fn_name ++ ": missing " ++ @tagName(tag));
    }
    inline fn assertDone(target: *const Target, comptime tag: Tag, comptime src: builtin.SourceLocation) void {
        mach.assert(target.have(tag), src.fn_name ++ ": outstanding " ++ @tagName(tag));
    }
    const DependencyList = GenericList(Dependency);
    /// All dependencies are build dependencies
    pub const Dependency = struct { tag: Tag, target: *Target };
    pub fn asmPath(target: *const Target) Path {
        return target.build_cmd.emit_asm.?.yes.?;
    }
    pub fn binPath(target: *const Target) Path {
        return target.build_cmd.emit_bin.?.yes.?;
    }
    pub fn analysisPath(target: *const Target) Path {
        return target.build_cmd.emit_analysis.?.yes.?;
    }
    pub fn llvmIrPath(target: *const Target) Path {
        return target.build_cmd.emit_llvm_ir.?.yes.?;
    }
    pub fn llvmBcPath(target: *const Target) Path {
        return target.build_cmd.emit_llvm_bc.?.yes.?;
    }
    pub fn addFormat(target: *Target, allocator: *Allocator, fmt_cmd: FormatCommand) void {
        target.fmt_cmd = allocator.duplicateIrreversible(FormatCommand, fmt_cmd);
        target.give(.fmt);
    }
    pub fn addBuild(target: *Target, allocator: *Allocator, build_cmd: BuildCommand) void {
        target.build_cmd = allocator.duplicateIrreversible(BuildCommand, build_cmd);
        target.give(.build);
    }
    pub fn addRun(target: *Target, allocator: *Allocator, run_cmd: RunCommand) void {
        target.run_cmd = allocator.duplicateIrreversible(RunCommand, run_cmd);
        target.run_cmd.array.writeFormat(target.build_cmd.emit_bin.?.yes.?);
        target.run_cmd.array.writeOne(0);
        target.give(.run);
    }
    pub fn addFile(target: *Target, allocator: *Allocator, path: Path) void {
        if (target.build_cmd.files) |*files| {
            files.paths[files.len] = path;
            files.len +%= 1;
        } else {
            target.build_cmd.files = .{ .paths = allocator.allocateIrreversible(Path, 128) };
            target.addFile(allocator, path);
        }
    }
    pub fn addFiles(target: *Target, allocator: *Allocator, paths: []const Path) void {
        for (paths) |path| {
            target.addFile(allocator, path);
        }
    }
    pub fn dependOnBuild(target: *Target, allocator: *Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .build });
    }
    pub fn dependOnRun(target: *Target, allocator: *Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .run });
    }
    pub fn dependOnFormat(target: *Target, allocator: *Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .fmt });
    }
    pub fn dependOn(target: *Target, allocator: *Allocator, dependency: *Dependency) void {
        target.deps.create(allocator, .{ .target = dependency, .tag = .fmt });
    }
    pub fn dependOnObject(target: *Target, allocator: *Allocator, dependency: *Target) void {
        target.dependOnBuild(allocator, dependency);
        target.addFile(allocator, dependency.binPath());
    }
};
fn countArgs(array: anytype) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count +%= 1;
        }
    }
    return count +% 1;
}
fn makeArgs(array: anytype, args: anytype) void {
    var idx: u64 = 0;
    for (array.readAll(), 0..) |c, i| {
        if (c == 0) {
            args.writeOne(array.referManyWithSentinelAt(0, idx).ptr);
            idx = i +% 1;
        }
    }
    if (args.len() != 0) {
        mem.set(args.impl.undefined_byte_address(), @as(u64, 0), 1);
    }
}
// finish-document build-struct.zig
// start-document build-types.zig
pub const Module = struct {
    name: []const u8,
    path: []const u8,
    deps: ?[]const []const u8 = null,
    pub fn formatWrite(mod: Module, array: anytype) void {
        array.writeMany("--mod\x00");
        array.writeMany(mod.name);
        array.writeOne(':');
        if (mod.deps) |deps| {
            for (deps) |dep_name| {
                array.writeMany(dep_name);
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
            for (deps) |dep_name| {
                len +%= dep_name.len;
                len +%= 1;
            }
            if (deps.len != 0) {
                len -%= 1;
            }
        }
        len +%= 1;
        len +%= mod.path.len;
        len +%= 1;
        return len;
    }
};
pub const ModuleDependency = struct {
    import: ?[]const u8 = null,
    name: []const u8,

    var w_leader: bool = true;
    var l_leader: bool = true;

    pub fn formatWrite(mod_dep: ModuleDependency, array: anytype) void {
        defer w_leader = false;
        if (w_leader) {
            array.writeMany("--deps\x00");
        } else {
            array.overwriteOneBack(',');
        }
        if (mod_dep.import) |name| {
            array.writeMany(name);
            array.writeOne('=');
        }
        array.writeMany(mod_dep.name);
        array.writeOne(0);
    }
    pub fn formatLength(mod_dep: ModuleDependency) u64 {
        defer l_leader = false;
        var len: u64 = 0;
        if (l_leader) {
            len +%= 7;
        }
        if (mod_dep.import) |name| {
            len +%= name.len +% 1;
        }
        len +%= mod_dep.name.len +% 1;
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
            .constant => |constant| {
                array.writeAny(preset.reinterpret.print, constant);
            },
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
        }
        array.writeOne(0);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 2;
        len +%= format.name.len;
        len +%= 1;
        switch (format.value) {
            .constant => |constant| {
                len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, constant);
            },
            .string => |string| {
                len +%= 1 +% string.len +% 1;
            },
            .path => |path| {
                len +%= 1 +% path.formatLength() +% 1;
            },
            .symbol => |symbol| {
                len +%= symbol.len;
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
        array.writeMany("--\x00");
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        len +%= 8;
        for (format.flags) |flag| {
            len +%= flag.len;
            len +%= 1;
        }
        len +%= 3;
        return len;
    }
};
pub const Path = struct {
    absolute: [:0]const u8,
    pathname: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.pathname[0] != '/') {
            array.writeMany(format.absolute);
            array.writeOne('/');
        }
        array.writeMany(format.pathname);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.pathname[0] != '/') {
            len +%= format.absolute.len;
            len +%= 1;
        }
        len +%= format.pathname.len;
        return len;
    }
};
pub const Files = struct {
    paths: []Path,
    len: u64 = 0,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        for (format.paths[0..format.len]) |path| {
            array.writeFormat(path);
            array.writeOne(0);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.paths[0..format.len]) |path| {
            len +%= path.formatLength();
            len +%= 1;
        }
        return len;
    }
};
pub fn GenericList(comptime T: type) type {
    return struct {
        left: *Node,
        node: *Node,
        len: u64 = 0,
        pos: u64 = 0,
        const List = @This();
        const Node = struct { this: *T, next: *Node };

        fn create(list: *List, allocator: *Allocator, value: T) *T {
            list.tail();
            const ret: *T = allocator.duplicateIrreversible(T, value);
            add(list, allocator, ret);
            return ret;
        }
        fn save(list: *List, allocator: *Allocator, value: T) void {
            list.tail();
            add(list, allocator, allocator.duplicateIrreversible(T, value));
        }
        fn add(list: *List, allocator: *Allocator, value: *T) void {
            list.tail();
            const node: *Node = allocator.createIrreversible(Node);
            list.node.next = node;
            list.node.this = value;
            list.node = node;
            list.pos +%= 1;
            list.len +%= 1;
        }
        pub fn itr(list: *List) List {
            var ret: List = list.*;
            ret.head();
            return ret;
        }
        pub fn next(list: *List) ?*Node {
            if (list.pos == list.len) {
                list.head();
                return null;
            }
            return list.node.next;
        }
        pub inline fn head(list: *List) void {
            list.node = list.left;
            list.pos = 0;
        }
        pub fn tail(list: *List) void {
            while (list.pos != list.len) : (list.pos += 1) {
                list.node = list.node.next;
            }
        }
        fn init(allocator: *Allocator) List {
            const node: *Node = allocator.createIrreversible(Node);
            return .{ .left = node, .node = node };
        }
    };
}

const debug = struct {
    const about_run_s: [:0]const u8 = builtin.debug.about("run");
    const about_build_s: [:0]const u8 = builtin.debug.about("build");
    const about_format_s: [:0]const u8 = builtin.debug.about("format");
    const ChangedSize = fmt.ChangedBytesFormat(.{
        .dec_style = "\x1b[92m-",
        .inc_style = "\x1b[91m+",
    });
    fn buildNotice(name: [:0]const u8, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        array.writeMany(about_build_s);
        array.writeMany(name);
        array.writeMany(", ");
        array.writeFormat(ChangedSize.init(old_size, new_size));
        array.writeMany(", ");
        array.writeFormat(fmt.ud64(durat.sec));
        array.writeMany(".");
        array.writeFormat(fmt.nsec(durat.nsec));
        array.undefine(6);
        array.writeMany("s\n");
        builtin.debug.write(array.readAll());
    }
    fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec, rc: ?u8) void {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        array.writeMany(about);
        array.writeMany(name);
        array.writeMany(", ");
        if (rc) |return_code| {
            array.writeMany("rc=");
            array.writeFormat(fmt.ud8(return_code));
            array.writeMany(", ");
        }
        array.writeFormat(fmt.ud64(durat.sec));
        array.writeMany(".");
        array.writeFormat(fmt.nsec(durat.nsec));
        array.undefine(6);
        array.writeMany("s\n");
        builtin.debug.write(array.readAll());
    }
    inline fn runNotice(name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
        simpleTimedNotice(about_run_s, name, durat, rc);
    }
    inline fn formatNotice(name: [:0]const u8, durat: time.TimeSpec) void {
        simpleTimedNotice(about_format_s, name, durat, null);
    }
};
fn writeEnv(allocator: *Allocator, paths: Builder.Paths) !void {
    file.makeDir(.{ .errors = .{} }, paths.cache_dir);
    const env_pathname: [:0]const u8 = concatStrings(allocator, &.{ paths.cache_dir, "/env.zig" });
    const env_fd: u64 = try file.create(.{ .options = .{ .exclusive = false, .write = .truncate } }, env_pathname);
    try file.write(.{}, env_fd, concatStrings(allocator, &.{
        "pub const zig_exe: [:0]const u8 = \"",          paths.zig_exe,          "\";\n",
        "pub const build_root: [:0]const u8 = \"",       paths.build_root,       "\";\n",
        "pub const cache_dir: [:0]const u8 = \"",        paths.cache_dir,        "\";\n",
        "pub const global_cache_dir: [:0]const u8 = \"", paths.global_cache_dir, "\";\n",
    }));
}
// finish-document build-types.zig
// start-document option-functions.zig
fn lengthOptionalWhatNoArgWhatNot(option: anytype, len_equ: u64, len_yes: u64, len_no: u64) u64 {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    return len_equ +% mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg) +% 1;
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
fn lengthNonOptionalWhatNoArgWhatNot(option: anytype, len_yes: u64, len_no: u64) u64 {
    if (option) |value| {
        switch (value) {
            .yes => |yes_arg| {
                return len_yes +% mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg) +% 1;
            },
            .no => {
                return len_no;
            },
        }
    }
    return 0;
}
fn lengthWhatOrWhatNot(option: anytype, len_yes: u64, len_no: u64) u64 {
    if (option) |value| {
        if (value) {
            return len_yes;
        } else {
            return len_no;
        }
    }
    return 0;
}
fn lengthWhatHow(option: anytype, len_yes: u64) u64 {
    if (option) |how| {
        return len_yes +% mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how) +% 1;
    }
    return 0;
}
fn lengthWhat(option: bool, len_yes: u64) u64 {
    if (option) {
        return len_yes;
    }
    return 0;
}
fn lengthHow(option: anytype) u64 {
    if (option) |how| {
        return mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
    }
    return 0;
}
fn writeOptionalWhatNoArgWhatNot(array: anytype, option: anytype, equ_switch: []const u8, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany(equ_switch);
                    array.writeAny(preset.reinterpret.print, yes_arg);
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
fn writeNonOptionalWhatNoArgWhatNot(array: anytype, option: anytype, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_arg| {
                array.writeMany(yes_switch);
                array.writeAny(preset.reinterpret.print, yes_arg);
                array.writeOne('\x00');
            },
            .no => {
                array.writeMany(no_switch);
            },
        }
    }
}
fn writeWhatOrWhatNot(array: anytype, option: anytype, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        if (value) {
            array.writeMany(yes_switch);
        } else {
            array.writeMany(no_switch);
        }
    }
}
fn writeWhatHow(array: anytype, option: anytype, yes_switch: []const u8) void {
    if (option) |value| {
        array.writeMany(yes_switch);
        array.writeAny(preset.reinterpret.print, value);
        array.writeOne('\x00');
    }
}
fn writeWhat(array: anytype, option: bool, yes_switch: []const u8) void {
    if (option) {
        array.writeMany(yes_switch);
    }
}
fn writeHow(array: anytype, option: anytype) void {
    if (option) |how| {
        array.writeAny(preset.reinterpret.print, how);
    }
}
// finish-document option-functions.zig
// start-document mach.zig
pub extern fn asmMaxWidths(builder: *Builder) extern struct { u64, u64 };
pub extern fn asmWriteAllCommands(builder: *Builder, buf: [*]u8, name_max_width: u64) callconv(.C) u64;
pub extern fn asmRewind(builder: *Builder) callconv(.C) void;
// finish-document mach.zig
