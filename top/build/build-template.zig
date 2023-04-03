const sys = @import("../sys.zig");
const mem = @import("../mem.zig");
const fmt = @import("../fmt.zig");
const file = @import("../file.zig");
const meta = @import("../meta.zig");
const mach = @import("../mach.zig");
const proc = @import("../proc.zig");
const time = @import("../time.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("../types.zig");
// start-document build-struct.zig
pub usingnamespace types;
pub const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = builtin.AddressSpace(),
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
    .options = spec.allocator.options.small,
});
pub const ArgsString = mem.StructuredVector(u8, &@as(u8, 0), 8, Allocator, .{});
pub const ArgsPointers = mem.StructuredVector([*:0]u8, null, 8, Allocator, .{});
pub const GlobalOptions = struct {
    mode: ?builtin.Mode = null,
    strip: bool = true,
    sections: bool = true,
    verbose: bool = false,
    cmd: Target.Tag = .build,
    emit_bin: bool = true,
    emit_asm: bool = false,
    pub const Map = proc.GenericOptions(GlobalOptions);
};
pub const BuilderSpec = @import("./build2.zig").BuilderSpec;

pub const BuildCommand = struct {
    kind: types.OutputMode,
    __compile_command: void,
};
pub const FormatCommand = struct {
    __format_command: void,
};
pub const RunCommand = struct {
    args: ArgsPointers,
    pub fn addRunArgument(run_cmd: *RunCommand, allocator: *Allocator, any: anytype) void {
        const len: u64 = mem.reinterpret.lengthAny(u8, spec.reinterpret.print, any);
        var arg: ArgsString = ArgsString.init(allocator, len);
        arg.writeAny(spec.reinterpret.print, any);
        run_cmd.args.writeOne(arg.referAllDefinedWithSentinel(0));
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
const build_spec: BuilderSpec = .{
    .options = .{},
    .errors = spec.builder.errors.noexcept,
    .logging = spec.builder.logging.silent,
};
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
    pub fn zigExePathMacro(builder: *const Builder) types.Macro {
        return .{ .name = "zig_exe", .value = .{ .path = zigExePath(builder) } };
    }
    pub fn buildRootPathMacro(builder: *const Builder) types.Macro {
        return .{ .name = "build_root", .value = .{ .path = buildRootPath(builder) } };
    }
    pub fn cacheDirPathMacro(builder: *const Builder) types.Macro {
        return .{ .name = "cache_dir", .value = .{ .path = cacheDirPath(builder) } };
    }
    pub fn globalCacheDirPathMacro(builder: *const Builder) types.Macro {
        return .{ .name = "global_cache_dir", .value = .{ .path = globalCacheDirPath(builder) } };
    }
    pub fn sourceRootPathMacro(builder: *const Builder, root: [:0]const u8) types.Macro {
        return .{ .name = "root", .value = .{ .path = builder.sourceRootPath(root) } };
    }
    pub fn zigExePath(builder: *const Builder) types.Path {
        return .{ .absolute = builder.paths.zig_exe };
    }
    pub fn buildRootPath(builder: *const Builder) types.Path {
        return .{ .absolute = builder.paths.build_root };
    }
    pub fn cacheDirPath(builder: *const Builder) types.Path {
        return .{ .absolute = builder.paths.cache_dir };
    }
    pub fn globalCacheDirPath(builder: *const Builder) types.Path {
        return .{ .absolute = builder.paths.global_cache_dir };
    }
    pub fn sourceRootPath(builder: *const Builder, root: [:0]const u8) types.Path {
        return builder.path(root);
    }
    pub fn path(builder: *const Builder, name: [:0]const u8) types.Path {
        return .{ .absolute = builder.paths.build_root, .relative = name };
    }
    const exec_error_policy: sys.ErrorPolicy = .{
        .throw = build_spec.errors.command.fork.throw ++ build_spec.errors.command.execve.throw ++
            build_spec.errors.command.waitpid.throw ++ build_spec.errors.clock.throw,
        .abort = build_spec.errors.command.fork.abort ++ build_spec.errors.command.execve.abort ++
            build_spec.errors.command.waitpid.abort ++ build_spec.errors.clock.throw,
    };
    const init_error_policy: sys.ErrorPolicy = .{
        .throw = Allocator.map_error_policy.throw ++ build_spec.errors.mkdir.throw ++ build_spec.errors.path.throw ++
            build_spec.errors.close.throw ++ build_spec.errors.create.throw,
        .abort = Allocator.map_error_policy.abort ++ build_spec.errors.mkdir.abort ++ build_spec.errors.path.abort ++
            build_spec.errors.close.abort ++ build_spec.errors.create.abort,
    };
    fn exec(builder: Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(exec_error_policy, u8) {
        const clock_spec: time.ClockSpec = comptime build_spec.clock();
        const command_spec: proc.CommandSpec = comptime build_spec.command();
        const start: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
        const rc: u8 = try meta.wrap(proc.command(command_spec, builder.paths.zig_exe, args, builder.vars));
        const finish: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
        ts.* = time.diff(finish, start);
        return rc;
    }
    fn system(builder: Builder, args: [][*:0]u8, ts: *time.TimeSpec) sys.Call(exec_error_policy, u8) {
        const clock_spec: time.ClockSpec = comptime build_spec.clock();
        const command_spec: proc.CommandSpec = comptime build_spec.command();
        const start: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
        const ret: u8 = try meta.wrap(proc.command(command_spec, meta.manyToSlice(args[0]), args, builder.vars));
        const finish: time.TimeSpec = try meta.wrap(time.get(clock_spec, .realtime));
        ts.* = time.diff(finish, start);
        return ret;
    }
    pub fn init(allocator: *Allocator, paths: Paths, options: GlobalOptions, args: [][*:0]u8, vars: [][*:0]u8) sys.Call(init_error_policy, Builder) {
        const mkdir_spec: file.MakeDirSpec = comptime build_spec.mkdir();
        const path_spec: file.PathSpec = comptime build_spec.path();
        const create_spec: file.CreateSpec = comptime build_spec.create();
        const close_spec: file.CloseSpec = comptime build_spec.close();
        try meta.wrap(file.makeDir(mkdir_spec, paths.cache_dir, file.dir_mode));
        var dir_fd: u64 = try meta.wrap(file.path(path_spec, paths.cache_dir));
        const env_fd: u64 = try meta.wrap(file.createAt(create_spec, dir_fd, "env.zig", file.file_mode));
        writeEnvDecls(env_fd, &paths);
        try meta.wrap(file.close(close_spec, dir_fd));
        return .{
            .paths = paths,
            .options = options,
            .args = args,
            .vars = vars,
            .groups = try meta.wrap(GroupList.init(allocator)),
            .dir_fd = try meta.wrap(file.path(comptime build_spec.path(), paths.build_root)),
        };
    }
    fn stat(builder: *Builder, name: [:0]const u8) ?file.FileStatus {
        return file.fstatAt(.{ .logging = spec.logging.success_error_fault.silent }, builder.dir_fd, name) catch null;
    }
    fn buildLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const BuildCommand = target.build_cmd;
        var len: u64 = 4;
        len +%= 6 +% @tagName(cmd.kind).len +% 1;
        cmd = buildLength;
        len +%= types.Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        types.ModuleDependency.l_leader = true;
        return len;
    }
    fn buildWrite(builder: *Builder, target: *const Target, array: *ArgsString) void {
        const cmd: *const BuildCommand = target.build_cmd;
        array.writeMany("zig\x00build-");
        array.writeMany(@tagName(cmd.kind));
        array.writeOne('\x00');
        cmd = buildWrite;
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
        types.ModuleDependency.w_leader = true;
    }
    fn formatLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd;
        var len: u64 = 8;
        cmd = formatLength;
        len +%= types.Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(builder: *Builder, target: *const Target, array: *ArgsString) void {
        const cmd: *const FormatCommand = target.fmt_cmd;
        array.writeMany("zig\x00fmt\x00");
        cmd = formatWrite;
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
    }
    pub fn build(builder: *Builder, allocator: *Allocator, target: *Target) sys.Call(.{
        .throw = Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        try meta.wrap(format(builder, allocator, target));
        if (!target.have(.build)) return;
        if (target.done(.build)) return;
        target.do(.build);
        builder.depth +%= 1;
        try meta.wrap(invokeDependencies(builder, allocator, target));
        var array: ArgsString = try meta.wrap(ArgsString.init(allocator, build_spec.options.max_command_line));
        var build_args: ArgsPointers = try meta.wrap(ArgsPointers.init(allocator, build_spec.options.max_command_args));
        const bin_path: [:0]const u8 = target.binPath().relative.?;
        const old_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
        builder.buildWrite(target, &array);
        makeArgs(&array, &build_args);
        var build_time: time.TimeSpec = undefined;
        const rc: u8 = try meta.wrap(builder.exec(build_args.referAllDefined(), &build_time));
        const new_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
        builder.depth -%= 1;
        if (builder.depth <= build_spec.options.max_relevant_depth) {
            debug.buildNotice(target.name, build_time, old_size, new_size);
        }
        if (rc != 0) {
            builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
        }
    }
    pub fn format(builder: *Builder, allocator: *Allocator, target: *Target) sys.Call(.{
        .throw = Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        if (!target.have(.fmt)) return;
        if (target.done(.fmt)) return;
        target.do(.fmt);
        try meta.wrap(invokeDependencies(builder, allocator, target));
        var array: ArgsString = try meta.wrap(ArgsString.init(allocator, build_spec.options.max_command_line));
        var format_args: ArgsPointers = try meta.wrap(ArgsPointers.init(allocator, build_spec.options.max_command_args));
        builder.formatWrite(target, &array);
        makeArgs(&array, &format_args);
        var format_time: time.TimeSpec = undefined;
        const rc: u8 = try meta.wrap(builder.exec(format_args.referAllDefined(), &format_time));
        if (builder.depth <= build_spec.options.max_relevant_depth) {
            debug.formatNotice(target.name, format_time);
        }
        if (rc != 0) {
            builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
        }
    }
    pub fn run(builder: *Builder, allocator: *Allocator, target: *Target) sys.Call(.{
        .throw = Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        if (!target.have(.run)) return;
        if (!target.have(.build)) return;
        if (target.done(.run)) return;
        target.do(.run);
        try meta.wrap(build(builder, allocator, target));
        var run_time: time.TimeSpec = undefined;
        for (builder.run_args) |run_arg| {
            target.run_cmd.addRunArgument(allocator, run_arg);
        }
        const rc: u8 = try meta.wrap(builder.system(target.run_cmd.args.referAllDefined(), &run_time));
        if (rc != 0 or builder.depth <= build_spec.options.max_relevant_depth) {
            debug.runNotice(target.name, run_time, rc);
        }
        if (rc != 0) {
            builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
        }
    }
    fn invokeDependencies(builder: *Builder, allocator: *Allocator, target: *Target) sys.Call(.{
        .throw = Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        target.deps.head();
        while (target.deps.next()) |node| : (target.deps.node = node) {
            switch (target.deps.node.this.tag) {
                .build => try meta.wrap(build(builder, allocator, target.deps.node.this.target)),
                .run => try meta.wrap(run(builder, allocator, target.deps.node.this.target)),
                .fmt => try meta.wrap(format(builder, allocator, target.deps.node.this.target)),
            }
        }
    }
    pub fn addTarget(builder: *Builder, spec: TargetSpec, allocator: *Allocator, name: [:0]const u8, pathname: [:0]const u8) Allocator.allocate_payload(*Target) {
        return builder.groups.left.this.addTarget(spec, allocator, name, pathname);
    }
    pub fn addGroup(builder: *Builder, allocator: *Allocator, comptime name: [:0]const u8) Allocator.allocate_payload(*Group) {
        defer builder.groups.head();
        const ret: *Group = try meta.wrap(allocator.createIrreversible(Group));
        try meta.wrap(builder.groups.add(allocator, ret));
        ret.name = name;
        ret.builder = builder;
        ret.targets = try meta.wrap(TargetList.init(allocator));
        return ret;
    }
};
pub const TargetSpec = struct {
    build: ?types.OutputMode = .exe,
    run: bool = true,
    fmt: bool = false,
    mode: builtin.Mode = .Debug,
    mods: []const types.Module = &.{},
    deps: []const types.ModuleDependency = &.{},
    macros: []const types.Macro = &.{},
};
pub const GroupList = GenericList(Group);
pub const Group = struct {
    name: [:0]const u8,
    targets: TargetList,
    builder: *Builder,
    pub fn addTarget(group: *Group, spec: TargetSpec, allocator: *Allocator, name: [:0]const u8, pathname: [:0]const u8) Allocator.allocate_payload(*Target) {
        const mode: builtin.Mode = group.builder.options.mode orelse spec.mode;
        const ret: *Target = allocator.createIrreversible(Target);
        ret.name = saveString(allocator, name);
        ret.root = saveString(allocator, pathname);
        ret.deps = Target.DependencyList.init(allocator);
        group.targets.add(allocator, ret);
        if (spec.fmt) {
            const fmt_cmd: *FormatCommand = allocator.createIrreversible(FormatCommand);
            ret.fmt_cmd = fmt_cmd;
            ret.give(.fmt);
        }
        if (spec.build) |kind| {
            const bin_path: types.Path = group.builder.path(concatStrings(allocator, switch (kind) {
                .exe => &.{ "zig-out/bin/", name },
                .obj => &.{ "zig-out/bin/", name, ".o" },
                .lib => &.{ "zig-out/lib/", name, ".so" },
            }));
            const asm_path: types.Path = group.builder.path(concatStrings(
                allocator,
                &.{ "zig-out/bin/", name, ".s" },
            ));
            const build_cmd: *BuildCommand = allocator.createIrreversible(BuildCommand);
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
            build_cmd.main_pkg_path = group.builder.paths.build_root;
            build_cmd.emit_bin = if (group.builder.options.emit_bin) .{ .yes = bin_path } else null;
            build_cmd.emit_asm = if (group.builder.options.emit_asm) .{ .yes = asm_path } else null;
            ret.give(.build);
            ret.build_cmd = build_cmd;
        }
        if (spec.run) {
            const run_cmd: *RunCommand = allocator.createIrreversible(RunCommand);
            run_cmd.args = ArgsPointers.init(allocator, build_spec.options.max_command_args);
            run_cmd.addRunArgument(allocator, ret.binPath());
            ret.give(.run);
            ret.run_cmd = run_cmd;
        }
        return ret;
    }
};
pub const TargetList = GenericList(Target);
pub const Target = struct {
    name: [:0]const u8,
    root: [:0]const u8,
    descr: ?[:0]const u8 = null,
    build_cmd: *BuildCommand,
    fmt_cmd: *FormatCommand,
    run_cmd: *RunCommand,
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
    pub fn asmPath(target: *const Target) types.Path {
        return target.build_cmd.emit_asm.?.yes.?;
    }
    pub fn binPath(target: *const Target) types.Path {
        return target.build_cmd.emit_bin.?.yes.?;
    }
    pub fn analysisPath(target: *const Target) types.Path {
        return target.build_cmd.emit_analysis.?.yes.?;
    }
    pub fn llvmIrPath(target: *const Target) types.Path {
        return target.build_cmd.emit_llvm_ir.?.yes.?;
    }
    pub fn llvmBcPath(target: *const Target) types.Path {
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
        target.run_cmd.addRunArgument(target.binPath());
        target.give(.run);
    }
    pub fn addFile(target: *Target, allocator: *Allocator, path: types.Path) void {
        if (target.build_cmd.files) |*files| {
            files.paths[files.len] = path;
            files.len +%= 1;
        } else {
            target.build_cmd.files = .{ .paths = allocator.allocateIrreversible(types.Path, 128) };
            target.addFile(allocator, path);
        }
    }
    pub fn addFiles(target: *Target, allocator: *Allocator, paths: []const types.Path) void {
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
fn countArgs(array: *ArgsString) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count +%= 1;
        }
    }
    return count +% 1;
}
fn makeArgs(array: *ArgsString, args: anytype) void {
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
pub fn GenericList(comptime T: type) type {
    return struct {
        left: *Node,
        node: *Node,
        len: u64 = 0,
        pos: u64 = 0,
        const List = @This();
        const Node = struct { this: *T, next: *Node };
        fn save(list: *List, allocator: *Allocator, value: T) Allocator.allocate_void {
            list.tail();
            add(list, allocator, allocator.duplicateIrreversible(T, value));
        }
        fn add(list: *List, allocator: *Allocator, value: *T) Allocator.allocate_void {
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
        fn init(allocator: *Allocator) Allocator.allocate_payload(List) {
            const node: *Node = try meta.wrap(allocator.createIrreversible(Node));
            return .{ .left = node, .node = node };
        }
    };
}
const debug = struct {
    const about_run_s: [:0]const u8 = builtin.debug.about("run");
    const about_build_s: [:0]const u8 = builtin.debug.about("build");
    const about_format_s: [:0]const u8 = builtin.debug.about("format");
    const new_style: [:0]const u8 = "\x1b[93m";
    const ChangedSize = fmt.ChangedBytesFormat(.{
        .dec_style = "\x1b[92m-",
        .inc_style = "\x1b[91m+",
    });
    const no_style: [:0]const u8 = "*\x1b[0m";
    fn buildNotice(name: [:0]const u8, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        array.writeMany(about_build_s);
        array.writeMany(name);
        array.writeMany(", ");
        if (old_size == 0) {
            array.writeMany(new_style);
            array.writeFormat(fmt.bytes(new_size));
            array.writeMany(no_style);
        } else {
            array.writeFormat(ChangedSize.init(old_size, new_size));
        }
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
fn writeEnvDecls(env_fd: u64, paths: *const Builder.Paths) void {
    for ([_][]const u8{
        "pub const zig_exe: [:0]const u8 = \"",               paths.zig_exe,
        "\";\npub const build_root: [:0]const u8 = \"",       paths.build_root,
        "\";\npub const cache_dir: [:0]const u8 = \"",        paths.cache_dir,
        "\";\npub const global_cache_dir: [:0]const u8 = \"", paths.global_cache_dir,
        "\";\n",
    }) |s| {
        file.write(.{ .errors = .{} }, env_fd, s);
    }
}
// finish-document build-types.zig
// start-document option-functions.zig
fn lengthOptionalWhatNoArgWhatNot(option: anytype, len_equ: u64, len_yes: u64, len_no: u64) u64 {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    return len_equ +% mem.reinterpret.lengthAny(u8, spec.reinterpret.print, yes_arg) +% 1;
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
                return len_yes +% mem.reinterpret.lengthAny(u8, spec.reinterpret.print, yes_arg) +% 1;
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
        return len_yes +% mem.reinterpret.lengthAny(u8, spec.reinterpret.print, how) +% 1;
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
        return mem.reinterpret.lengthAny(u8, spec.reinterpret.print, how);
    }
    return 0;
}
fn writeOptionalWhatNoArgWhatNot(array: *ArgsString, option: anytype, equ_switch: []const u8, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_optional_arg| {
                if (yes_optional_arg) |yes_arg| {
                    array.writeMany(equ_switch);
                    array.writeAny(spec.reinterpret.print, yes_arg);
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
fn writeNonOptionalWhatNoArgWhatNot(array: *ArgsString, option: anytype, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        switch (value) {
            .yes => |yes_arg| {
                array.writeMany(yes_switch);
                array.writeAny(spec.reinterpret.print, yes_arg);
                array.writeOne('\x00');
            },
            .no => {
                array.writeMany(no_switch);
            },
        }
    }
}
fn writeWhatOrWhatNot(array: *ArgsString, option: anytype, yes_switch: []const u8, no_switch: []const u8) void {
    if (option) |value| {
        if (value) {
            array.writeMany(yes_switch);
        } else {
            array.writeMany(no_switch);
        }
    }
}
fn writeWhatHow(array: *ArgsString, option: anytype, yes_switch: []const u8) void {
    if (option) |value| {
        array.writeMany(yes_switch);
        array.writeAny(spec.reinterpret.print, value);
        array.writeOne('\x00');
    }
}
fn writeWhat(array: *ArgsString, option: bool, yes_switch: []const u8) void {
    if (option) {
        array.writeMany(yes_switch);
    }
}
fn writeHow(array: *ArgsString, option: anytype) void {
    if (option) |how| {
        array.writeAny(spec.reinterpret.print, how);
    }
}
// finish-document option-functions.zig
// start-document mach.zig
pub extern fn asmMaxWidths(builder: *Builder) extern struct { u64, u64 };
pub extern fn asmWriteAllCommands(builder: *Builder, buf: [*]u8, name_max_width: u64) callconv(.C) u64;
pub extern fn asmRewind(builder: *Builder) callconv(.C) void;
// finish-document mach.zig
