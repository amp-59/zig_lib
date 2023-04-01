const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const types = @import("./build/types2.zig");
const tasks = @import("./build/tasks.zig");
comptime {
    asm (@embedFile("./build/build-template.s"));
}
pub usingnamespace types;

const reinterpret_spec: mem.ReinterpretSpec = blk: {
    var tmp: mem.ReinterpretSpec = preset.reinterpret.print;
    tmp.composite.map = &.{
        .{ .in = []const types.ModuleDependency, .out = types.ModuleDependencies },
    };
    break :blk tmp;
};

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

pub fn saveString(allocator: *types.Allocator, values: []const u8) [:0]u8 {
    var buf: [:0]u8 = allocator.allocateWithSentinelIrreversible(u8, values.len, 0);
    mach.memcpy(buf.ptr, values.ptr, values.len);
    return buf;
}
pub fn saveStrings(allocator: *types.Allocator, values: []const []const u8) [][:0]u8 {
    var buf: [][:0]u8 = allocator.allocateIrreversible([:0]u8, values.len);
    var idx: u64 = 0;
    for (values) |value| {
        buf[idx] = saveString(allocator, value);
        idx +%= 1;
    }
}
pub fn concatStrings(allocator: *types.Allocator, values: []const []const u8) [:0]u8 {
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
fn makeArgPtrs(allocator: *types.Allocator, args: [:0]u8) [][*:0]u8 {
    const ptrs: [][*:0]u8 = argsPointers(allocator, args);
    var len: u64 = 0;
    var idx: u64 = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0) {
            ptrs[len] = args[pos..idx :0];
            len +%= 1;
            pos = idx +% 1;
        }
    }
    ptrs[len] = builtin.zero([*:0]u8);
    return ptrs[0..len];
}
fn argsPointers(allocator: *types.Allocator, args: [:0]u8) [][*:0]u8 {
    var count: u64 = 0;
    for (args) |value| {
        count +%= @boolToInt(value == 0);
    }
    return allocator.allocateIrreversible([*:0]u8, count +% 1);
}
const build_spec: BuilderSpec = .{
    .options = .{},
    .errors = preset.builder.errors.noexcept,
    .logging = preset.builder.logging.silent,
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
        .throw = types.Allocator.map_error_policy.throw ++ build_spec.errors.mkdir.throw ++ build_spec.errors.path.throw ++
            build_spec.errors.close.throw ++ build_spec.errors.create.throw,
        .abort = types.Allocator.map_error_policy.abort ++ build_spec.errors.mkdir.abort ++ build_spec.errors.path.abort ++
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
    pub fn init(allocator: *types.Allocator, paths: Paths, options: GlobalOptions, args: [][*:0]u8, vars: [][*:0]u8) sys.Call(init_error_policy, Builder) {
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
        return file.fstatAt(.{ .logging = preset.logging.success_error_fault.silent }, builder.dir_fd, name) catch null;
    }
    fn buildLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const tasks.BuildCommand = target.build_cmd;
        var len: u64 = 4;
        len +%= 6 +% @tagName(cmd.kind).len +% 1;
        if (cmd.watch) {
            len +%= 8;
        }
        if (cmd.show_builtin) {
            len +%= 15;
        }
        if (cmd.builtin) {
            len +%= 10;
        }
        if (cmd.link_libc) {
            len +%= 4;
        }
        if (cmd.rdynamic) {
            len +%= 10;
        }
        if (cmd.dynamic) {
            len +%= 9;
        }
        if (cmd.static) {
            len +%= 8;
        }
        if (cmd.symbolic) {
            len +%= 11;
        }
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 11;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 11;
                    }
                },
                .no => {
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 11;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 11;
                    }
                },
                .no => {
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 15;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 15;
                    }
                },
                .no => {
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 15;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 15;
                    }
                },
                .no => {
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 9;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 9;
                    }
                },
                .no => {
                    len +%= 12;
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 12;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 12;
                    }
                },
                .no => {
                    len +%= 15;
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 16;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 16;
                    }
                },
                .no => {
                    len +%= 19;
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 14;
                        len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                        len +%= 1;
                    } else {
                        len +%= 14;
                    }
                },
                .no => {
                    len +%= 17;
                },
            }
        }
        if (cmd.cache_dir) |how| {
            len +%= 12;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.global_cache_dir) |how| {
            len +%= 19;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.zig_lib_dir) |how| {
            len +%= 14;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.enable_cache) {
            len +%= 15;
        }
        if (cmd.target) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.cpu) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.code_model) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                len +%= 21;
            } else {
                len +%= 24;
            }
        }
        if (cmd.exec_model) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.name) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.mode) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.main_pkg_path) |how| {
            len +%= 16;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.pic) |pic| {
            if (pic) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                len +%= 13;
            } else {
                len +%= 16;
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (cmd.dll_export_fns) |dll_export_fns| {
            if (dll_export_fns) {
                len +%= 17;
            } else {
                len +%= 20;
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                len +%= 16;
            } else {
                len +%= 19;
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                len +%= 7;
            } else {
                len +%= 10;
            }
        }
        if (cmd.clang) |clang| {
            if (clang) {
                len +%= 8;
            } else {
                len +%= 11;
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (cmd.error_trace) |error_trace| {
            if (error_trace) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                len +%= 20;
            } else {
                len +%= 23;
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                len +%= 8;
            } else {
                len +%= 11;
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                len +%= 19;
            } else {
                len +%= 22;
            }
        }
        if (cmd.fmt) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.dirafter) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.system) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.include) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.libc) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.library) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.library_directory) |how| {
            len +%= 20;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.link_script) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.version_script) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.dynamic_linker) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.sysroot) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.version) {
            len +%= 10;
        }
        if (cmd.entry) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    len +%= 9;
                    len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, yes_arg);
                    len +%= 1;
                },
                .no => {
                    len +%= 12;
                },
            }
        }
        if (cmd.lld) |lld| {
            if (lld) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (cmd.rpath) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                len +%= 17;
            } else {
                len +%= 20;
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                len +%= 24;
            } else {
                len +%= 27;
            }
        }
        if (cmd.build_id) |build_id| {
            if (build_id) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (cmd.compress_debug_sections) |how| {
            len +%= 26;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (cmd.stack) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.image_base) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.macros) |how| {
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        }
        if (cmd.modules) |how| {
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        }
        if (cmd.dependencies) |how| {
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        }
        if (cmd.cflags) |how| {
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        }
        if (cmd.z) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.files) |how| {
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
        }
        len +%= types.Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        types.ModuleDependency.l_leader = true;
        return len;
    }
    fn buildWrite(builder: *Builder, target: *const Target, array: *types.Args) void {
        const cmd: *const tasks.BuildCommand = target.build_cmd;
        array.writeMany("zig\x00build-");
        array.writeMany(@tagName(cmd.kind));
        array.writeOne('\x00');
        if (cmd.watch) {
            array.writeMany("--watch\x00");
        }
        if (cmd.show_builtin) {
            array.writeMany("--show-builtin\x00");
        }
        if (cmd.builtin) {
            array.writeMany("-fbuiltin\x00");
        }
        if (cmd.link_libc) {
            array.writeMany("-lc\x00");
        }
        if (cmd.rdynamic) {
            array.writeMany("-rdynamic\x00");
        }
        if (cmd.dynamic) {
            array.writeMany("-dynamic\x00");
        }
        if (cmd.static) {
            array.writeMany("-static\x00");
        }
        if (cmd.symbolic) {
            array.writeMany("-Bsymbolic\x00");
        }
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-bin=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-bin\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-bin\x00");
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-asm=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-asm\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-asm\x00");
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-llvm-ir=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-llvm-ir\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-llvm-ir\x00");
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-llvm-bc=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-llvm-bc\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-llvm-bc\x00");
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-h=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-h\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-h\x00");
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-docs=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-docs\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-docs\x00");
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-analysis=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-analysis\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-analysis\x00");
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-implib=");
                        array.writeAny(reinterpret_spec, yes_arg);
                        array.writeOne('\x00');
                    } else {
                        array.writeMany("-femit-implib\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-implib\x00");
                },
            }
        }
        if (cmd.cache_root) |how| {
            array.writeMany("--cache-dir\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.global_cache_root) |how| {
            array.writeMany("--global-cache-dir\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.zig_lib_dir) |how| {
            array.writeMany("--zig-lib-dir\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.enable_cache) {
            array.writeMany("--enable-cache\x00");
        }
        if (cmd.target) |how| {
            array.writeMany("-target\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.cpu) |how| {
            array.writeMany("-mcpu\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.code_model) |how| {
            array.writeMany("-mcmodel\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                array.writeMany("-mred-zone\x00");
            } else {
                array.writeMany("-mno-red-zone\x00");
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                array.writeMany("-fomit-frame-pointer\x00");
            } else {
                array.writeMany("-fno-omit-frame-pointer\x00");
            }
        }
        if (cmd.exec_model) |how| {
            array.writeMany("-mexec-model\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.name) |how| {
            array.writeMany("--name\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.mode) |how| {
            array.writeMany("-O\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.main_pkg_path) |how| {
            array.writeMany("--main-pkg-path\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.pic) |pic| {
            if (pic) {
                array.writeMany("-fPIC\x00");
            } else {
                array.writeMany("-fno-PIC\x00");
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                array.writeMany("-fPIE\x00");
            } else {
                array.writeMany("-fno-PIE\x00");
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                array.writeMany("-flto\x00");
            } else {
                array.writeMany("-fno-lto\x00");
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                array.writeMany("-fstack-check\x00");
            } else {
                array.writeMany("-fno-stack-check\x00");
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                array.writeMany("-fsanitize-c\x00");
            } else {
                array.writeMany("-fno-sanitize-c\x00");
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                array.writeMany("-fvalgrind\x00");
            } else {
                array.writeMany("-fno-valgrind\x00");
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                array.writeMany("-fsanitize-thread\x00");
            } else {
                array.writeMany("-fno-sanitize-thread\x00");
            }
        }
        if (cmd.dll_export_fns) |dll_export_fns| {
            if (dll_export_fns) {
                array.writeMany("-fdll-export-fns\x00");
            } else {
                array.writeMany("-fno-dll-export-fns\x00");
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                array.writeMany("-funwind-tables\x00");
            } else {
                array.writeMany("-fno-unwind-tables\x00");
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                array.writeMany("-fLLVM\x00");
            } else {
                array.writeMany("-fno-LLVM\x00");
            }
        }
        if (cmd.clang) |clang| {
            if (clang) {
                array.writeMany("-fClang\x00");
            } else {
                array.writeMany("-fno-Clang\x00");
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                array.writeMany("-freference-trace\x00");
            } else {
                array.writeMany("-fno-reference-trace\x00");
            }
        }
        if (cmd.error_trace) |error_trace| {
            if (error_trace) {
                array.writeMany("-ferror-trace\x00");
            } else {
                array.writeMany("-fno-error-trace\x00");
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                array.writeMany("-fsingle-threaded\x00");
            } else {
                array.writeMany("-fno-single-threaded\x00");
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                array.writeMany("-ffunction-sections\x00");
            } else {
                array.writeMany("-fno-function-sections\x00");
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                array.writeMany("-fstrip\x00");
            } else {
                array.writeMany("-fno-strip\x00");
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                array.writeMany("-fformatted-panics\x00");
            } else {
                array.writeMany("-fno-formatted-panics\x00");
            }
        }
        if (cmd.fmt) |how| {
            array.writeMany("-ofmt\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.dirafter) |how| {
            array.writeMany("-dirafter\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.system) |how| {
            array.writeMany("-isystem\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.include) |how| {
            array.writeMany("-I\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.libc) |how| {
            array.writeMany("--libc\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.library) |how| {
            array.writeMany("--library\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.library_directory) |how| {
            array.writeMany("--library-directory\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.link_script) |how| {
            array.writeMany("--script\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.version_script) |how| {
            array.writeMany("--version-script\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.dynamic_linker) |how| {
            array.writeMany("--dynamic-linker\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.sysroot) |how| {
            array.writeMany("--sysroot\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.version) {
            array.writeMany("--version\x00");
        }
        if (cmd.entry) |how| {
            array.writeMany("--entry\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    array.writeMany("-fsoname\x00");
                    array.writeAny(reinterpret_spec, yes_arg);
                    array.writeOne('\x00');
                },
                .no => {
                    array.writeMany("-fno-soname\x00");
                },
            }
        }
        if (cmd.lld) |lld| {
            if (lld) {
                array.writeMany("-fLLD\x00");
            } else {
                array.writeMany("-fno-LLD\x00");
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                array.writeMany("-fcompiler-rt\x00");
            } else {
                array.writeMany("-fno-compiler-rt\x00");
            }
        }
        if (cmd.rpath) |how| {
            array.writeMany("-rpath\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                array.writeMany("-feach-lib-rpath\x00");
            } else {
                array.writeMany("-fno-each-lib-rpath\x00");
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                array.writeMany("-fallow-shlib-undefined\x00");
            } else {
                array.writeMany("-fno-allow-shlib-undefined\x00");
            }
        }
        if (cmd.build_id) |build_id| {
            if (build_id) {
                array.writeMany("-fbuild-id\x00");
            } else {
                array.writeMany("-fno-build-id\x00");
            }
        }
        if (cmd.compress_debug_sections) |how| {
            array.writeMany("--compress-debug-sections\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                array.writeMany("--gc-sections\x00");
            } else {
                array.writeMany("--no-gc-sections\x00");
            }
        }
        if (cmd.stack) |how| {
            array.writeMany("--stack\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.image_base) |how| {
            array.writeMany("--image-base\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.macros) |how| {
            array.writeAny(reinterpret_spec, how);
        }
        if (cmd.modules) |how| {
            array.writeAny(reinterpret_spec, how);
        }
        if (cmd.dependencies) |how| {
            array.writeAny(reinterpret_spec, how);
        }
        if (cmd.cflags) |how| {
            array.writeAny(reinterpret_spec, how);
        }
        if (cmd.z) |how| {
            array.writeMany("-z\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.files) |how| {
            array.writeAny(reinterpret_spec, how);
        }
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
    }
    fn formatLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const tasks.FormatCommand = target.fmt_cmd;
        var len: u64 = 8;
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        if (cmd.stdin) {
            len +%= 8;
        }
        if (cmd.check) {
            len +%= 8;
        }
        if (cmd.ast_check) {
            len +%= 12;
        }
        if (cmd.exclude) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, how);
            len +%= 1;
        }
        len +%= types.Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(builder: *Builder, target: *const Target, array: *types.Args) void {
        const cmd: *const tasks.FormatCommand = target.fmt_cmd;
        array.writeMany("zig\x00fmt\x00");
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.stdin) {
            array.writeMany("--stdin\x00");
        }
        if (cmd.check) {
            array.writeMany("--check\x00");
        }
        if (cmd.ast_check) {
            array.writeMany("--ast-check\x00");
        }
        if (cmd.exclude) |how| {
            array.writeMany("--exclude\x00");
            array.writeAny(reinterpret_spec, how);
            array.writeOne('\x00');
        }
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
    }
    pub fn build(builder: *Builder, allocator: *types.Allocator, target: *Target) sys.Call(.{
        .throw = types.Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = types.Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        try meta.wrap(format(builder, allocator, target));
        if (!target.have(.build)) return;
        if (target.done(.build)) return;
        target.do(.build);
        builder.depth +%= 1;
        try meta.wrap(invokeDependencies(builder, allocator, target));
        var array: types.Args = try meta.wrap(types.Args.init(allocator, build_spec.options.max_command_line));
        var build_args: types.Ptrs = try meta.wrap(types.Ptrs.init(allocator, build_spec.options.max_command_args));
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
    pub fn format(builder: *Builder, allocator: *types.Allocator, target: *Target) sys.Call(.{
        .throw = types.Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = types.Allocator.map_error_policy.abort ++ exec_error_policy.abort,
    }, void) {
        if (!target.have(.fmt)) return;
        if (target.done(.fmt)) return;
        target.do(.fmt);
        try meta.wrap(invokeDependencies(builder, allocator, target));
        var array: types.Args = try meta.wrap(types.Args.init(allocator, build_spec.options.max_command_line));
        var format_args: types.Ptrs = try meta.wrap(types.Ptrs.init(allocator, build_spec.options.max_command_args));
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
    pub fn run(builder: *Builder, allocator: *types.Allocator, target: *Target) sys.Call(.{
        .throw = types.Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = types.Allocator.map_error_policy.abort ++ exec_error_policy.abort,
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
        const ptrs: [][*:0]u8 = makeArgPtrs(allocator, target.run_cmd.args.referAllDefinedWithSentinel(0));
        const rc: u8 = try meta.wrap(builder.system(ptrs, &run_time));
        if (rc != 0 or builder.depth <= build_spec.options.max_relevant_depth) {
            debug.runNotice(target.name, run_time, rc);
        }
        if (rc != 0) {
            builtin.proc.exitWithError(error.UnexpectedReturnCode, rc);
        }
    }
    fn invokeDependencies(builder: *Builder, allocator: *types.Allocator, target: *Target) sys.Call(.{
        .throw = types.Allocator.map_error_policy.throw ++ exec_error_policy.throw,
        .abort = types.Allocator.map_error_policy.abort ++ exec_error_policy.abort,
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
    pub fn addTarget(builder: *Builder, spec: TargetSpec, allocator: *types.Allocator, name: [:0]const u8, pathname: [:0]const u8) types.Allocator.allocate_payload(*Target) {
        return builder.groups.left.this.addTarget(spec, allocator, name, pathname);
    }
    pub fn addGroup(builder: *Builder, allocator: *types.Allocator, comptime name: [:0]const u8) types.Allocator.allocate_payload(*Group) {
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
    build: ?tasks.OutputMode = .exe,
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
    pub fn addTarget(group: *Group, spec: TargetSpec, allocator: *types.Allocator, name: [:0]const u8, pathname: [:0]const u8) types.Allocator.allocate_payload(*Target) {
        const mode: builtin.Mode = group.builder.options.mode orelse spec.mode;
        const ret: *Target = allocator.createIrreversible(Target);
        ret.name = saveString(allocator, name);
        ret.root = saveString(allocator, pathname);
        ret.deps = Target.DependencyList.init(allocator);
        group.targets.add(allocator, ret);
        if (spec.fmt) {
            const fmt_cmd: *tasks.FormatCommand = allocator.createIrreversible(tasks.FormatCommand);
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
            const build_cmd: *tasks.BuildCommand = allocator.createIrreversible(tasks.BuildCommand);
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
            const run_cmd: *tasks.RunCommand = allocator.createIrreversible(tasks.RunCommand);
            run_cmd.args = types.Args.init(allocator, 65536);
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
    build_cmd: *tasks.BuildCommand,
    fmt_cmd: *tasks.FormatCommand,
    run_cmd: *tasks.RunCommand,
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
    pub fn addFormat(target: *Target, allocator: *types.Allocator, fmt_cmd: tasks.FormatCommand) void {
        target.fmt_cmd = allocator.duplicateIrreversible(tasks.FormatCommand, fmt_cmd);
        target.give(.fmt);
    }
    pub fn addBuild(target: *Target, allocator: *types.Allocator, build_cmd: tasks.BuildCommand) void {
        target.build_cmd = allocator.duplicateIrreversible(tasks.BuildCommand, build_cmd);
        target.give(.build);
    }
    pub fn addRun(target: *Target, allocator: *types.Allocator, run_cmd: tasks.RunCommand) void {
        target.run_cmd = allocator.duplicateIrreversible(tasks.RunCommand, run_cmd);
        target.run_cmd.addRunArgument(target.binPath());
        target.give(.run);
    }
    pub fn addFile(target: *Target, allocator: *types.Allocator, path: types.Path) void {
        if (target.build_cmd.files) |*files| {
            files.paths[files.len] = path;
            files.len +%= 1;
        } else {
            target.build_cmd.files = .{ .paths = allocator.allocateIrreversible(types.Path, 128) };
            target.addFile(allocator, path);
        }
    }
    pub fn addFiles(target: *Target, allocator: *types.Allocator, paths: []const types.Path) void {
        for (paths) |path| {
            target.addFile(allocator, path);
        }
    }
    pub fn dependOnBuild(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .build });
    }
    pub fn dependOnRun(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .run });
    }
    pub fn dependOnFormat(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
        target.deps.save(allocator, .{ .target = dependency, .tag = .fmt });
    }
    pub fn dependOn(target: *Target, allocator: *types.Allocator, dependency: *Dependency) void {
        target.deps.create(allocator, .{ .target = dependency, .tag = .fmt });
    }
    pub fn dependOnObject(target: *Target, allocator: *types.Allocator, dependency: *Target) void {
        target.dependOnBuild(allocator, dependency);
        target.addFile(allocator, dependency.binPath());
    }
};
fn countArgs(array: *type.Args) u64 {
    var count: u64 = 0;
    for (array.readAll()) |value| {
        if (value == 0) {
            count +%= 1;
        }
    }
    return count +% 1;
}
fn makeArgs(array: *types.Args, args: anytype) void {
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
pub fn GenericList(comptime T: type) type {
    return struct {
        left: *Node,
        node: *Node,
        len: u64 = 0,
        pos: u64 = 0,
        const List = @This();
        const Node = struct { this: *T, next: *Node };
        fn save(list: *List, allocator: *types.Allocator, value: T) types.Allocator.allocate_void {
            list.tail();
            add(list, allocator, allocator.duplicateIrreversible(T, value));
        }
        fn add(list: *List, allocator: *types.Allocator, value: *T) types.Allocator.allocate_void {
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
        fn init(allocator: *types.Allocator) types.Allocator.allocate_payload(List) {
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
pub extern fn asmMaxWidths(builder: *Builder) extern struct { u64, u64 };
pub extern fn asmWriteAllCommands(builder: *Builder, buf: [*]u8, name_max_width: u64) callconv(.C) u64;
pub extern fn asmRewind(builder: *Builder) callconv(.C) void;
