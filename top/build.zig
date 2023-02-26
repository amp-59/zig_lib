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
    enable_cache: bool = false,
    target: ?[]const u8 = null,
    cpu: ?[]const u8 = null,
    code_model: ?enum(u3) { default = 0, tiny = 1, small = 2, kernel = 3, medium = 4, large = 5 } = null,
    red_zone: ?bool = null,
    omit_frame_pointer: ?bool = null,
    exec_model: ?[]const u8 = null,
    name: ?[]const u8 = null,
    O: ?@TypeOf(builtin.zig.mode) = null,
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
    stage1: ?bool = null,
    single_threaded: ?bool = null,
    builtin: bool = false,
    function_sections: ?bool = null,
    strip: ?bool = null,
    formatted_panics: ?bool = null,
    fmt: ?enum(u4) { elf = 0, c = 1, wasm = 2, coff = 3, macho = 4, spirv = 5, plan9 = 6, hex = 7, raw = 8 } = null,
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
    entry: bool = false,
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
    dependencies: ?[]const []const u8 = null,
    cflags: ?struct { flags: []const []const u8 } = null,
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
    ast_check: bool = false,
    exclude: ?[]const u8 = null,
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
        if (cmd.watch) {
            len +%= 8;
        }
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        len +%= 11;
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
                        len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.global_cache_dir) |how| {
            len +%= 19;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.zig_lib_dir) |how| {
            len +%= 14;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.enable_cache) {
            len +%= 15;
        }
        if (cmd.target) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.cpu) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.code_model) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.name) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.O) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.main_pkg_path) |how| {
            len +%= 16;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
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
        if (cmd.stage1) |stage1| {
            if (stage1) {
                len +%= 9;
            } else {
                len +%= 12;
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.dirafter) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.system) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.include) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.libc) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.library) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.library_directory) |how| {
            len +%= 20;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.link_script) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.version_script) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.dynamic_linker) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.sysroot) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.version) {
            len +%= 10;
        }
        if (cmd.entry) {
            len +%= 8;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    len +%= 9;
                    len +%= mem.reinterpret.lengthAny(u8, fmt_spec, yes_arg);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.image_base) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.macros) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (cmd.modules) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (cmd.dependencies) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (cmd.cflags) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (cmd.z) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
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
        if (cmd.watch) {
            array.writeMany("--watch\x00");
        }
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes_optional_arg| {
                    if (yes_optional_arg) |yes_arg| {
                        array.writeMany("-femit-bin=");
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
                        array.writeAny(fmt_spec, yes_arg);
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
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.global_cache_dir) |how| {
            array.writeMany("--global-cache-dir\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.zig_lib_dir) |how| {
            array.writeMany("--zig-lib-dir\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.enable_cache) {
            array.writeMany("--enable-cache\x00");
        }
        if (cmd.target) |how| {
            array.writeMany("-target\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.cpu) |how| {
            array.writeMany("-mcpu\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.code_model) |how| {
            array.writeMany("-mcmodel\x00");
            array.writeAny(fmt_spec, how);
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
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.name) |how| {
            array.writeMany("--name\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.O) |how| {
            array.writeMany("-O\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.main_pkg_path) |how| {
            array.writeMany("--main-pkg-path\x00");
            array.writeAny(fmt_spec, how);
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
        if (cmd.stage1) |stage1| {
            if (stage1) {
                array.writeMany("-fstage1\x00");
            } else {
                array.writeMany("-fno-stage1\x00");
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
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.dirafter) |how| {
            array.writeMany("-dirafter\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.system) |how| {
            array.writeMany("-isystem\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.include) |how| {
            array.writeMany("-I\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.libc) |how| {
            array.writeMany("--libc\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.library) |how| {
            array.writeMany("--library\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.library_directory) |how| {
            array.writeMany("--library-directory\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.link_script) |how| {
            array.writeMany("--script\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.version_script) |how| {
            array.writeMany("--version-script\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.dynamic_linker) |how| {
            array.writeMany("--dynamic-linker\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.sysroot) |how| {
            array.writeMany("--sysroot\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.version) {
            array.writeMany("--version\x00");
        }
        if (cmd.entry) {
            array.writeMany("--entry\x00");
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |yes_arg| {
                    array.writeMany("-fsoname\x00");
                    array.writeAny(fmt_spec, yes_arg);
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
            array.writeAny(fmt_spec, how);
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
            array.writeAny(fmt_spec, how);
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
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.image_base) |how| {
            array.writeMany("--image-base\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.macros) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (cmd.modules) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (cmd.dependencies) |how| {
            array.writeMany("--deps\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.cflags) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (cmd.z) |how| {
            array.writeMany("-z\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
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
        if (cmd.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
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
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
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
        if (cmd.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (cmd.stdin) {
            array.writeMany("--sdtin\x00");
        }
        if (cmd.check) {
            array.writeMany("--check\x00");
        }
        if (cmd.ast_check) {
            array.writeMany("--ast-check\x00");
        }
        if (cmd.exclude) |how| {
            array.writeMany("--exclude\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
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
