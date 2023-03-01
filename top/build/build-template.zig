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
    .options = preset.allocator.options.fast,
});
pub const String = Allocator.StructuredVectorLowAligned(u8, 8);
pub const Pointers = Allocator.StructuredVector([*:0]u8);
pub const ArgsString = mem.StructuredAutomaticVector(u8, null, max_len, 8, .{});
pub const ArgsPointers = mem.StructuredAutomaticVector([*:0]u8, null, max_args, 8, .{});
pub const max_len: u64 = builtin.define("max_command_len", u64, 65536);
pub const max_args: u64 = builtin.define("max_command_args", u64, 512);
pub const GlobalOptions = struct {
    mode: ?builtin.Mode = null,
    strip: bool = true,
    verbose: bool = false,
    cmd: Target.Tag = .build,
    pub const Map = proc.GenericOptions(GlobalOptions);
};
pub const Builder = struct {
    paths: Paths,
    options: GlobalOptions,
    groups: GroupList,
    args: [][*:0]u8,
    vars: [][*:0]u8,
    pub const Paths = struct {
        zig_exe: [:0]const u8,
        build_root: [:0]const u8,
        cache_dir: [:0]const u8,
        global_cache_dir: [:0]const u8,
        pub fn define() Paths {
            return .{
                .zig_exe = builtin.zig_exe.?,
                .build_root = builtin.build_root.?,
                .cache_dir = builtin.cache_dir.?,
                .global_cache_dir = builtin.global_cache_dir.?,
            };
        }
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
        return .{ .builder = builder, .pathname = name };
    }
    pub inline fn addTarget(
        builder: *Builder,
        comptime spec: TargetSpec,
        allocator: *Allocator,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
    ) *Target {
        return join(
            allocator,
            builder,
            &builder.groups.node.this.targets,
            name,
            pathname,
            spec.fmt,
            spec.build,
            spec.run,
            builder.options.mode orelse spec.mode,
            spec.deps,
            spec.mods,
            spec.macros,
            "zig-out/bin/" ++ name,
        );
    }
    pub fn addGroup(
        builder: *Builder,
        allocator: *Allocator,
        comptime name: [:0]const u8,
    ) *Group {
        const ret: *Group = builder.groups.create(allocator, .{
            .name = name,
            .builder = builder,
            .targets = TargetList.init(allocator),
        });
        builder.groups.head();
        return ret;
    }
    fn exec(builder: Builder, args: [][*:0]u8) !time.TimeSpec {
        const start: time.TimeSpec = try time.get(.{}, .realtime);
        if (0 != try proc.command(.{}, builder.paths.zig_exe, args, builder.vars)) {
            return error.UnexpectedExitStatus;
        }
        const finish: time.TimeSpec = try time.get(.{}, .realtime);
        return time.diff(finish, start);
    }
    fn system(builder: Builder, args: [][*:0]u8) !time.TimeSpec {
        const start: time.TimeSpec = try time.get(.{}, .realtime);
        if (0 != try proc.command(.{}, meta.manyToSlice(args[0]), args, builder.vars)) {
            return error.UnexpectedExitStatus;
        }
        const finish: time.TimeSpec = try time.get(.{}, .realtime);
        return time.diff(finish, start);
    }
    pub fn init(
        allocator: *Allocator,
        paths: Paths,
        options: GlobalOptions,
        args: [][*:0]u8,
        vars: [][*:0]u8,
    ) Builder {
        var ret: Builder = .{
            .paths = paths,
            .options = options,
            .args = args,
            .vars = vars,
            .groups = GroupList.init(allocator),
        };
        return ret;
    }
};
pub const TargetSpec = struct {
    build: bool = true,
    run: bool = true,
    fmt: bool = false,
    mode: builtin.Mode = .Debug,
    deps: []const []const u8 = &.{},
    mods: []const Module = &.{},
    macros: []const Macro = &.{},
};
fn join(
    allocator: *Allocator,
    builder: *Builder,
    targets: *TargetList,
    name: [:0]const u8,
    pathname: [:0]const u8,
    spec_fmt: bool,
    spec_build: bool,
    spec_run: bool,
    mode: builtin.Mode,
    spec_deps: []const []const u8,
    spec_mods: []const Module,
    spec_macros: []const Macro,
    bin_path: [:0]const u8,
) *Target {
    const ret: *Target = targets.create(allocator, .{
        .name = name,
        .root = pathname,
        .builder = builder,
        .deps = Target.DependencyList.init(allocator),
    });
    if (spec_fmt) ret.addFormat(allocator, .{});
    if (spec_build) ret.addBuild(allocator, .{
        .main_pkg_path = builder.paths.build_root,
        .emit_bin = .{ .yes = builder.path(bin_path) },
        .name = name,
        .kind = .exe,
        .omit_frame_pointer = false,
        .single_threaded = true,
        .static = true,
        .enable_cache = true,
        .compiler_rt = false,
        .strip = true,
        .formatted_panics = false,
        .modules = spec_mods,
        .dependencies = spec_deps,
        .mode = mode,
        .macros = spec_macros,
    });
    if (spec_run) ret.addRun(allocator, .{});
    return ret;
}
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
    array: ArgsString = undefined,
    pub fn addRunArgument(run_cmd: *RunCommand, any: anytype) void {
        if (@typeInfo(@TypeOf(any)) == .Struct) {
            run_cmd.array.writeFormat(preset.reinterpret.fmt, any);
        } else {
            run_cmd.array.writeMany(any);
        }
        if (run_cmd.array.readOneBack() != 0) {
            run_cmd.array.writeOne(0);
        }
    }
};
pub const GroupList = GenericList(Group);
pub const Group = struct {
    name: [:0]const u8,
    targets: TargetList,
    builder: *Builder,
    pub inline fn addTarget(
        group: *Group,
        comptime spec: TargetSpec,
        allocator: *Allocator,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
    ) *Target {
        return join(
            allocator,
            group.builder,
            &group.targets,
            name,
            pathname,
            spec.fmt,
            spec.build,
            spec.run,
            group.builder.options.mode orelse spec.mode,
            spec.deps,
            spec.mods,
            spec.macros,
            "zig-out/bin/" ++ name,
        );
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
    builder: *Builder,
    flags: u8 = 0,
    /// Specify command for target
    pub const Tag = enum {
        fmt,
        build,
        run,
        fn have(comptime tag: Tag) u8 {
            const shift_amt: u8 = @enumToInt(tag);
            return 1 << (2 * shift_amt);
        }
        fn done(comptime tag: Tag) u8 {
            const shift_amt: u8 = @enumToInt(tag);
            return 1 << (2 * shift_amt + 1);
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

    const DependencyList = GenericList(Dependency);
    /// All dependencies are build dependencies
    pub const Dependency = struct {
        tag: Tag,
        target: *Target,
    };
    pub fn addFormat(target: *Target, allocator: *Allocator, fmt_cmd: FormatCommand) void {
        target.fmt_cmd = allocator.duplicateIrreversible(FormatCommand, fmt_cmd);
        target.give(.fmt);
    }
    pub fn addBuild(target: *Target, allocator: *Allocator, build_cmd: BuildCommand) void {
        target.build_cmd = allocator.duplicateIrreversible(BuildCommand, build_cmd);
        target.give(.build);
    }
    pub fn addRun(target: *Target, allocator: *Allocator, run_cmd: RunCommand) void {
        mach.assert(target.have(.build), "tried to add run command without build command");
        target.run_cmd = allocator.duplicateIrreversible(RunCommand, run_cmd);
        target.run_cmd.array.writeFormat(target.build_cmd.emit_bin.?.yes.?);
        target.run_cmd.array.writeOne(0);
        target.give(.run);
    }
    pub fn dependOnBuild(target: *Target, allocator: *Allocator, dependency: *Target) void {
        return target.deps.save(allocator, .{ .target = dependency, .tag = .build });
    }
    pub fn dependOnRun(target: *Target, allocator: *Allocator, dependency: *Target) void {
        return target.deps.save(allocator, .{ .target = dependency, .tag = .run });
    }
    pub fn dependOnFormat(target: *Target, allocator: *Allocator, dependency: *Target) void {
        return target.deps.save(allocator, .{ .target = dependency, .tag = .fmt });
    }
    pub fn dependOn(target: *Target, allocator: *Allocator, dependency: *Dependency) void {
        target.deps.create(allocator, .{ .target = dependency, .tag = .fmt });
    }
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
        array.writeMany("\x00\x00");
        array.undefine(1);
        return countArgs(array);
    }
    fn formatLength(target: Target) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd;
        var len: u64 = 8;
        cmd = formatLength;
        len +%= Path.formatLength(target.builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(target: Target, array: anytype) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd;
        array.writeMany("zig\x00");
        array.writeMany("fmt\x00");
        cmd = formatWrite;
        array.writeFormat(target.builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
        return countArgs(array);
    }
    pub fn build(target: *Target) !void {
        try target.format();
        if (target.done(.build)) return;
        if (target.have(.build)) {
            target.do(.build);
            try target.maybeInvokeDependencies();
            var array: ArgsString = undefined;
            var args: ArgsPointers = undefined;
            array.undefineAll();
            args.undefineAll();
            builtin.assertBelowOrEqual(u64, target.buildWrite(&array), max_args);
            builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
            builtin.assertEqual(u64, array.len(), target.buildLength());
            debug.buildNotice(target.name, target.build_cmd.emit_bin.?.yes.?, try target.builder.exec(args.referAllDefined()));
        }
    }
    pub fn format(target: *Target) !void {
        if (target.done(.fmt)) return;
        if (target.have(.fmt)) {
            target.do(.fmt);
            try target.maybeInvokeDependencies();
            var array: ArgsString = undefined;
            var args: ArgsPointers = undefined;
            array.undefineAll();
            args.undefineAll();
            builtin.assertBelowOrEqual(u64, target.formatWrite(&array), max_args);
            builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
            builtin.assertEqual(u64, array.len(), target.formatLength());
            const format_time: time.TimeSpec = try target.builder.exec(args.referAllDefined());
            debug.formatNotice(target.name, format_time);
        }
    }
    pub fn run(target: *Target) !void {
        if (target.done(.run)) return;
        if (target.have(.run) and target.have(.build)) {
            target.do(.run);
            try target.build();
            var args: ArgsPointers = undefined;
            args.undefineAll();
            builtin.assertBelowOrEqual(u64, makeArgs(&target.run_cmd.array, &args), max_args);
            const run_time: time.TimeSpec = try target.builder.system(args.referAllDefined());
            debug.runNotice(target.name, run_time);
        }
    }
    fn maybeInvokeDependencies(target: *Target) anyerror!void {
        target.deps.head();
        while (target.deps.next()) |node| : (target.deps.node = node) {
            switch (target.deps.node.this.tag) {
                .build => try target.deps.node.this.target.build(),
                .run => try target.deps.node.this.target.run(),
                .fmt => try target.deps.node.this.target.format(),
            }
        }
    }
    const debug = struct {
        const about_run_s: [:0]const u8 = "run:            ";
        const about_build_s: [:0]const u8 = "build:          ";
        const about_format_s: [:0]const u8 = "format:         ";
        fn buildNotice(name: [:0]const u8, bin_path: Path, durat: time.TimeSpec) void {
            var array: mem.StaticString(4096) = undefined;
            array.undefineAll();
            array.writeFormat(bin_path);
            array.writeOne(0);
            array.undefine(1);
            const stat: file.Stat = (file.stat(.{}, array.readAllWithSentinel(0)) catch return);
            array.undefineAll();
            array.writeMany(about_build_s);
            array.writeMany(name);
            array.writeMany(", ");
            array.writeFormat(fmt.bytes(stat.size));
            array.writeMany(", ");
            array.writeFormat(fmt.ud64(durat.sec));
            array.writeMany(".");
            array.writeFormat(fmt.nsec(durat.nsec));
            array.writeMany("s\n");
            builtin.debug.write(array.readAll());
        }
        fn simpleTimedNotice(about: [:0]const u8, name: [:0]const u8, durat: time.TimeSpec) void {
            var array: mem.StaticString(4096) = undefined;
            array.undefineAll();
            array.writeMany(about);
            array.writeMany(name);
            array.writeMany(", ");
            array.writeFormat(fmt.ud64(durat.sec));
            array.writeMany(".");
            array.writeFormat(fmt.nsec(durat.nsec));
            array.writeMany("s\n");
            builtin.debug.write(array.readAll());
        }
        inline fn runNotice(name: [:0]const u8, durat: time.TimeSpec) void {
            simpleTimedNotice(about_run_s, name, durat);
        }
        inline fn formatNotice(name: [:0]const u8, durat: time.TimeSpec) void {
            simpleTimedNotice(about_format_s, name, durat);
        }
    };
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
fn makeArgs(array: anytype, args: anytype) u64 {
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
    return args.len();
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
                array.writeAny(fmt_spec, constant);
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
                len +%= mem.reinterpret.lengthAny(u8, fmt_spec, constant);
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
pub const Path = struct {
    builder: ?*const Builder = null,
    pathname: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.builder) |builder| {
            if (format.pathname[0] != '/') {
                array.writeMany(builder.paths.build_root);
                array.writeOne('/');
            }
        }
        array.writeMany(format.pathname);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.builder) |builder| {
            if (format.pathname[0] != '/') {
                len +%= builder.paths.build_root.len;
                len +%= 1;
            }
        }
        len +%= format.pathname.len;
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
            const node: *Node = allocator.createIrreversible(Node);
            list.node.next = node;
            list.node.this = ret;
            list.node = node;
            list.pos +%= 1;
            list.len +%= 1;
            return ret;
        }
        fn save(list: *List, allocator: *Allocator, value: T) void {
            list.tail();
            const saved: *T = allocator.duplicateIrreversible(T, value);
            const node: *Node = allocator.createIrreversible(Node);
            list.node.next = node;
            list.node.this = saved;
            list.node = node;
            list.pos +%= 1;
            list.len +%= 1;
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
// finish-document build-types.zig
// start-document option-functions.zig
fn lengthOptionalWhatNoArgWhatNot(option: anytype, len_equ: u64, len_yes: u64, len_no: u64) u64 {
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
fn lengthNonOptionalWhatNoArgWhatNot(option: anytype, len_yes: u64, len_no: u64) u64 {
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
fn lengthHow(option: anytype) u64 {
    if (option) |how| {
        return mem.reinterpret.lengthAny(u8, fmt_spec, how);
    }
    return 0;
}
fn writeOptionalWhatNoArgWhatNot(array: anytype, option: anytype, equ_switch: []const u8, yes_switch: []const u8, no_switch: []const u8) void {
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
fn writeNonOptionalWhatNoArgWhatNot(array: anytype, option: anytype, yes_switch: []const u8, no_switch: []const u8) void {
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
        array.writeAny(fmt_spec, value);
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
        array.writeAny(fmt_spec, how);
    }
}
// finish-document option-functions.zig

