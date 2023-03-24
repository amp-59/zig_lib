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
    watch: bool = false,
    color: ?enum(u2) { on = 0, off = 1, auto = 2 } = null,
    emit_bin: ?union(enum) { yes: ?Path, no: void } = null,
    emit_asm: ?union(enum) { yes: ?Path, no: void } = null,
    emit_llvm_ir: ?union(enum) { yes: ?Path, no: void } = null,
    emit_llvm_bc: ?union(enum) { yes: ?Path, no: void } = null,
    emit_h: ?union(enum) { yes: ?Path, no: void } = null,
    emit_docs: ?union(enum) { yes: ?Path, no: void } = null,
    emit_analysis: ?union(enum) { yes: ?Path, no: void } = null,
    emit_implib: ?union(enum) { yes: ?Path, no: void } = null,
    show_builtin: bool = false,
    cache_dir: ?[]const u8 = null,
    global_cache_dir: ?[]const u8 = null,
    zig_lib_dir: ?[]const u8 = null,
    enable_cache: bool = true,
    target: ?[]const u8 = null,
    cpu: ?[]const u8 = null,
    code_model: ?enum(u3) { default = 0, tiny = 1, small = 2, kernel = 3, medium = 4, large = 5 } = null,
    red_zone: ?bool = null,
    omit_frame_pointer: ?bool = null,
    exec_model: ?[]const u8 = null,
    name: ?[]const u8 = null,
    mode: ?@TypeOf(builtin.zig.mode) = null,
    main_pkg_path: ?[]const u8 = null,
    pic: ?bool = null,
    pie: ?bool = null,
    lto: ?bool = null,
    stack_check: ?bool = null,
    sanitize_c: ?bool = null,
    valgrind: ?bool = null,
    sanitize_thread: ?bool = null,
    dll_export_fns: ?bool = null,
    unwind_tables: ?bool = null,
    llvm: ?bool = null,
    clang: ?bool = null,
    reference_trace: ?bool = null,
    error_trace: ?bool = null,
    single_threaded: ?bool = null,
    builtin: bool = false,
    function_sections: ?bool = null,
    strip: ?bool = null,
    formatted_panics: ?bool = null,
    fmt: ?enum(u4) { elf = 0, c = 1, wasm = 2, coff = 3, macho = 4, spirv = 5, plan9 = 6, hex = 7, raw = 8 } = null,
    files: ?Files = null,
    dirafter: ?[]const u8 = null,
    system: ?[]const u8 = null,
    include: ?[]const u8 = null,
    libc: ?[]const u8 = null,
    library: ?[]const u8 = null,
    library_directory: ?[]const u8 = null,
    link_script: ?[]const u8 = null,
    version_script: ?[]const u8 = null,
    dynamic_linker: ?[]const u8 = null,
    sysroot: ?[]const u8 = null,
    version: bool = false,
    entry: ?[]const u8 = null,
    soname: ?union(enum) { yes: []const u8, no: void } = null,
    lld: ?bool = null,
    compiler_rt: ?bool = null,
    rdynamic: bool = false,
    rpath: ?[]const u8 = null,
    each_lib_rpath: ?bool = null,
    allow_shlib_undefined: ?bool = null,
    build_id: ?bool = null,
    dynamic: bool = false,
    static: bool = false,
    symbolic: bool = false,
    compress_debug_sections: ?enum(u1) { none = 0, zlib = 1 } = null,
    gc_sections: ?bool = null,
    stack: ?u64 = null,
    image_base: ?u64 = null,
    macros: ?[]const Macro = null,
    modules: ?[]const Module = null,
    dependencies: ?[]const ModuleDependency = null,
    cflags: ?CFlags = null,
    z: ?enum(u4) { nodelete = 0, notext = 1, defs = 2, origin = 3, nocopyreloc = 4, now = 5, lazy = 6, relro = 7, norelro = 8 } = null,
    test_filter: ?[]const u8 = null,
    test_name_prefix: ?[]const u8 = null,
    test_cmd: bool = false,
    test_cmd_bin: bool = false,
    test_evented_io: bool = false,
    test_no_exec: bool = false,
};
pub const FormatCommand = struct {
    color: ?enum(u2) { auto = 0, off = 1, on = 2 } = null,
    stdin: bool = false,
    check: bool = false,
    ast_check: bool = true,
    exclude: ?[]const u8 = null,
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
        return .{ .absolute = builder.paths.build_root, .pathname = name };
    }
    pub inline fn addTarget(
        builder: *Builder,
        comptime spec: TargetSpec,
        allocator: *Allocator,
        comptime name: [:0]const u8,
        comptime pathname: [:0]const u8,
    ) *Target {
        const emit_bin: bool = builder.options.emit_bin;
        const bin_path: [:0]const u8 = "zig-out/bin/" ++ name;
        const emit_asm: bool = builder.options.emit_asm;
        const asm_path: [:0]const u8 = "zig-out/bin/" ++ name ++ ".s";
        const mode: builtin.Mode = builder.options.mode orelse spec.mode;
        const target_list: *TargetList = &builder.groups.node.this.targets;
        return @call(.auto, join, .{
            allocator,   builder,    target_list, name,      pathname,
            spec.fmt,    spec.build, spec.run,    mode,      emit_bin,
            bin_path,    emit_asm,   asm_path,    spec.deps, spec.mods,
            spec.macros,
        });
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
    pub fn init(
        allocator: *Allocator,
        paths: Paths,
        options: GlobalOptions,
        args: [][*:0]u8,
        vars: [][*:0]u8,
    ) !Builder {
        var ret: Builder = .{
            .paths = paths,
            .options = options,
            .args = args,
            .vars = vars,
            .groups = GroupList.init(allocator),
            .dir_fd = try file.path(.{}, paths.build_root),
        };
        return ret;
    }
    fn stat(builder: *Builder, name: [:0]const u8) ?file.FileStatus {
        return file.fstatAt(.{ .logging = .{ .Error = false } }, builder.dir_fd, name) catch null;
    }
    fn buildLength(builder: *Builder, target: *const Target) u64 {
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
        len +%= Macro.formatLength(builder.zigExePathMacro());
        len +%= Macro.formatLength(builder.buildRootPathMacro());
        len +%= Macro.formatLength(builder.cacheDirPathMacro());
        len +%= Macro.formatLength(builder.globalCacheDirPathMacro());
        if (cmd.watch) {
            len +%= 8;
        }
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 11;
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
        if (cmd.show_builtin) {
            len +%= 15;
        }
        if (cmd.cache_dir) |how| {
            len +%= 12;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.global_cache_dir) |how| {
            len +%= 19;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.zig_lib_dir) |how| {
            len +%= 14;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.enable_cache) {
            len +%= 15;
        }
        if (cmd.target) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.cpu) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.code_model) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
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
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.name) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.mode) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.main_pkg_path) |how| {
            len +%= 16;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
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
        if (cmd.builtin) {
            len +%= 10;
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
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.files) |how| {
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
        }
        if (cmd.dirafter) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.system) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.include) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.libc) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.library) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.library_directory) |how| {
            len +%= 20;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.link_script) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.version_script) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.dynamic_linker) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.sysroot) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.version) {
            len +%= 10;
        }
        if (cmd.entry) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    len +%= 9;
                    len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, yes_arg);
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
        if (cmd.rdynamic) {
            len +%= 10;
        }
        if (cmd.rpath) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
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
        if (cmd.dynamic) {
            len +%= 9;
        }
        if (cmd.static) {
            len +%= 8;
        }
        if (cmd.symbolic) {
            len +%= 11;
        }
        if (cmd.compress_debug_sections) |how| {
            len +%= 26;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
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
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.image_base) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        if (cmd.macros) |how| {
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
        }
        if (cmd.modules) |how| {
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
        }
        if (cmd.dependencies) |how| {
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
        }
        if (cmd.cflags) |how| {
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
        }
        if (cmd.z) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        len +%= Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        ModuleDependency.l_leader = true;
        return len;
    }
    fn buildWrite(builder: *Builder, target: *const Target, array: anytype) void {
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
        array.writeFormat(builder.zigExePathMacro());
        array.writeFormat(builder.buildRootPathMacro());
        array.writeFormat(builder.cacheDirPathMacro());
        array.writeFormat(builder.globalCacheDirPathMacro());
        if (cmd.watch) {
            array.writeMany("--watch\x00");
        }
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-bin=");
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
                        array.writeAny(preset.reinterpret.print, yes_arg);
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
        if (cmd.show_builtin) {
            array.writeMany("--show-builtin\x00");
        }
        if (cmd.cache_dir) |how| {
            array.writeMany("--cache-dir\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.global_cache_dir) |how| {
            array.writeMany("--global-cache-dir\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.zig_lib_dir) |how| {
            array.writeMany("--zig-lib-dir\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.enable_cache) {
            array.writeMany("--enable-cache\x00");
        }
        if (cmd.target) |how| {
            array.writeMany("-target\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.cpu) |how| {
            array.writeMany("-mcpu\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.code_model) |how| {
            array.writeMany("-mcmodel\x00");
            array.writeAny(preset.reinterpret.print, how);
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
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.name) |how| {
            array.writeMany("--name\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.mode) |how| {
            array.writeMany("-O\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.main_pkg_path) |how| {
            array.writeMany("--main-pkg-path\x00");
            array.writeAny(preset.reinterpret.print, how);
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
        if (cmd.builtin) {
            array.writeMany("-fbuiltin\x00");
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
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.files) |how| {
            array.writeAny(preset.reinterpret.print, how);
        }
        if (cmd.dirafter) |how| {
            array.writeMany("-dirafter\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.system) |how| {
            array.writeMany("-isystem\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.include) |how| {
            array.writeMany("-I\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.libc) |how| {
            array.writeMany("--libc\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.library) |how| {
            array.writeMany("--library\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.library_directory) |how| {
            array.writeMany("--library-directory\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.link_script) |how| {
            array.writeMany("--script\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.version_script) |how| {
            array.writeMany("--version-script\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.dynamic_linker) |how| {
            array.writeMany("--dynamic-linker\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.sysroot) |how| {
            array.writeMany("--sysroot\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.version) {
            array.writeMany("--version\x00");
        }
        if (cmd.entry) |how| {
            array.writeMany("--entry\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    array.writeMany("-fsoname\x00");
                    array.writeAny(preset.reinterpret.print, yes_arg);
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
        if (cmd.rdynamic) {
            array.writeMany("-rdynamic\x00");
        }
        if (cmd.rpath) |how| {
            array.writeMany("-rpath\x00");
            array.writeAny(preset.reinterpret.print, how);
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
        if (cmd.dynamic) {
            array.writeMany("-dynamic\x00");
        }
        if (cmd.static) {
            array.writeMany("-static\x00");
        }
        if (cmd.symbolic) {
            array.writeMany("-Bsymbolic\x00");
        }
        if (cmd.compress_debug_sections) |how| {
            array.writeMany("--compress-debug-sections\x00");
            array.writeAny(preset.reinterpret.print, how);
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
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.image_base) |how| {
            array.writeMany("--image-base\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        if (cmd.macros) |how| {
            array.writeAny(preset.reinterpret.print, how);
        }
        if (cmd.modules) |how| {
            array.writeAny(preset.reinterpret.print, how);
        }
        if (cmd.dependencies) |how| {
            array.writeAny(preset.reinterpret.print, how);
        }
        if (cmd.cflags) |how| {
            array.writeAny(preset.reinterpret.print, how);
        }
        if (cmd.z) |how| {
            array.writeMany("-z\x00");
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
        array.writeFormat(builder.sourceRootPath(target.root));
        array.writeMany("\x00\x00");
        array.undefine(1);
        ModuleDependency.w_leader = true;
    }
    fn formatLength(builder: *Builder, target: *const Target) u64 {
        const cmd: *const FormatCommand = target.fmt_cmd;
        var len: u64 = 8;
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
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
            len +%= mem.reinterpret.lengthAny(u8, preset.reinterpret.print, how);
            len +%= 1;
        }
        len +%= Path.formatLength(builder.sourceRootPath(target.root));
        len +%= 1;
        return len;
    }
    fn formatWrite(builder: *Builder, target: *const Target, array: anytype) void {
        const cmd: *const FormatCommand = target.fmt_cmd;
        array.writeMany("zig\x00fmt\x00");
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(preset.reinterpret.print, how);
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
            array.writeAny(preset.reinterpret.print, how);
            array.writeOne('\x00');
        }
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
            var build_time: time.TimeSpec = undefined;
            var build_args: ArgsPointers = undefined;
            array.undefineAll();
            build_args.undefineAll();
            const bin_path: [:0]const u8 = target.build_cmd.emit_bin.?.yes.?.pathname;
            const old_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
            builder.buildWrite(target, &array);
            makeArgs(&array, &build_args);
            const rc: u8 = try builder.exec(build_args.referAllDefined(), &build_time);
            const new_size: u64 = if (builder.stat(bin_path)) |st| st.size else 0;
            builder.depth -%= 1;
            if (builder.depth <= max_relevant_depth) {
                debug.buildNotice(target.name, bin_path, build_time, old_size, new_size);
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
            var format_args: ArgsPointers = undefined;
            var format_time: time.TimeSpec = undefined;
            array.undefineAll();
            format_args.undefineAll();
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
            var run_time: time.TimeSpec = undefined;
            var run_args: ArgsPointers = undefined;
            run_args.undefineAll();
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
    build: bool = true,
    run: bool = true,
    fmt: bool = false,
    mode: builtin.Mode = .Debug,
    mods: []const Module = &.{},
    deps: []const ModuleDependency = &.{},
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
    emit_bin: bool,
    bin_path: [:0]const u8,
    emit_asm: bool,
    asm_path: [:0]const u8,
    spec_deps: []const ModuleDependency,
    spec_mods: []const Module,
    spec_macros: []const Macro,
) *Target {
    const ret: *Target = targets.create(allocator, .{
        .name = name,
        .root = pathname,
        .deps = Target.DependencyList.init(allocator),
    });
    if (spec_fmt) ret.addFormat(allocator, .{});
    if (spec_build) ret.addBuild(allocator, .{
        .main_pkg_path = builder.paths.build_root,
        .emit_bin = if (emit_bin) .{ .yes = builder.path(bin_path) } else null,
        .emit_asm = if (emit_asm) .{ .yes = builder.path(asm_path) } else null,
        .name = name,
        .kind = .exe,
        .omit_frame_pointer = false,
        .single_threaded = true,
        .static = true,
        .enable_cache = true,
        .gc_sections = true,
        .function_sections = true,
        .compiler_rt = false,
        .strip = builder.options.strip,
        .image_base = 0x10000,
        .modules = spec_mods,
        .dependencies = spec_deps,
        .mode = mode,
        .macros = spec_macros,
        .reference_trace = true,
    });
    if (spec_run) ret.addRun(allocator, .{});
    return ret;
}
pub const OutputMode = enum { exe, lib, obj, run };

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
        const emit_bin: bool = group.builder.options.emit_bin;
        const bin_path: [:0]const u8 = "zig-out/bin/" ++ name;
        const emit_asm: bool = group.builder.options.emit_asm;
        const asm_path: [:0]const u8 = "zig-out/bin/" ++ name ++ ".s";
        const mode: builtin.Mode = group.builder.options.mode orelse spec.mode;
        return @call(.auto, join, .{
            allocator,   group.builder, &group.targets, name,      pathname,
            spec.fmt,    spec.build,    spec.run,       mode,      emit_bin,
            bin_path,    emit_asm,      asm_path,       spec.deps, spec.mods,
            spec.macros,
        });
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
    inline fn assertHave(target: *Target, comptime tag: Tag, comptime src: builtin.SourceLocation) void {
        mach.assert(target.have(tag), src.fn_name ++ ": missing " ++ @tagName(tag));
    }
    inline fn assertDone(target: *Target, comptime tag: Tag, comptime src: builtin.SourceLocation) void {
        mach.assert(target.have(tag), src.fn_name ++ ": outstanding " ++ @tagName(tag));
    }
    const DependencyList = GenericList(Dependency);
    /// All dependencies are build dependencies
    pub const Dependency = struct { tag: Tag, target: *Target };
    fn getAsmPath(target: *const Target) Path {
        target.assertHave(.build, @src());
        return target.build_cmd.emit_asm.?.yes.?;
    }
    fn getBinPath(target: *const Target) Path {
        target.assertHave(.build, @src());
        return target.build_cmd.emit_bin.?.yes.?;
    }
    fn getAnalysisPath(target: *const Target) Path {
        target.assertHave(.build, @src());
        return target.build_cmd.emit_analysis.?.yes.?;
    }
    fn getLlvmIrPath(target: *const Target) Path {
        target.assertHave(.build, @src());
        return target.build_cmd.emit_llvm_ir.?.yes.?;
    }
    fn getLlvmBcPath(target: *const Target) Path {
        target.assertHave(.build, @src());
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
    pub fn addFiles(target: *Target, allocator: *Allocator, files: []const []const u8) void {
        _ = allocator;
        target.build_cmd.files = .{ .paths = files };
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
    absolute: ?[:0]const u8 = null,
    pathname: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.absolute) |absolute| {
            if (format.pathname[0] != '/') {
                array.writeMany(absolute);
                array.writeOne('/');
            }
        }
        array.writeMany(format.pathname);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.absolute) |absolute| {
            if (format.pathname[0] != '/') {
                len +%= absolute.len;
                len +%= 1;
            }
        }
        len +%= format.pathname.len;
        return len;
    }
};
pub const Files = struct {
    paths: []const []const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        for (format.paths) |name| {
            array.writeMany(name);
            array.writeOne(0);
        }
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        for (format.paths) |name| {
            len +%= name.len;
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
const debug = struct {
    const about_run_s: [:0]const u8 = builtin.debug.about("run");
    const about_build_s: [:0]const u8 = builtin.debug.about("build");
    const about_format_s: [:0]const u8 = builtin.debug.about("format");
    const ChangedSize = fmt.ChangedBytesFormat(.{
        .dec_style = "\x1b[92m-",
        .inc_style = "\x1b[91m+",
    });
    fn buildNotice(name: [:0]const u8, bin_path: [:0]const u8, durat: time.TimeSpec, old_size: u64, new_size: u64) void {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        array.writeMany(bin_path);
        array.writeOne(0);
        array.undefine(1);
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
        array.writeFormat(fmt.ud64(durat.sec));
        array.writeMany(".");
        array.writeFormat(fmt.nsec(durat.nsec));
        array.undefine(6);
        if (rc) |return_code| {
            array.writeMany("s, ->");
            array.writeFormat(fmt.ud8(return_code));
        } else {
            array.writeMany("s");
        }
        array.writeMany("\n");
        builtin.debug.write(array.readAll());
    }
    inline fn runNotice(name: [:0]const u8, durat: time.TimeSpec, rc: u8) void {
        simpleTimedNotice(about_run_s, name, durat, rc);
    }
    inline fn formatNotice(name: [:0]const u8, durat: time.TimeSpec) void {
        simpleTimedNotice(about_format_s, name, durat, null);
    }
};
