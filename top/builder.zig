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
pub const BuildCmd = struct {
    const Builder: type = @This();
    ctx: *const Context,
    cmd: enum { exe, lib, obj, fmt, ast_check, run },
    root: [:0]const u8,
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
    macros: ?Macros = null,
    packages: ?Packages = null,
    cflags: ?struct { flags: []const []const u8 } = null,
    z: ?enum(u4) { nodelete = 0, notext = 1, defs = 2, origin = 3, nocopyreloc = 4, now = 5, lazy = 6, relro = 7, norelro = 8 } = null,
    test_filter: ?[]const u8 = null,
    test_name_prefix: ?[]const u8 = null,
    test_cmd: bool = false,
    test_cmd_bin: bool = false,
    test_evented_io: bool = false,
    test_no_exec: bool = false,
    fn buildLength(build: Builder) u64 {
        var len: u64 = 4;
        switch (build.cmd) {
            .lib, .exe, .obj => {
                len += 6 + @tagName(build.cmd).len + 1;
            },
            .fmt, .ast_check, .run => {
                len += @tagName(build.cmd).len + 1;
            },
        }
        len +%= Macro.formatLength(build.ctx.zigExePathMacro());
        len +%= Macro.formatLength(build.ctx.buildRootPathMacro());
        len +%= Macro.formatLength(build.ctx.cacheDirPathMacro());
        len +%= Macro.formatLength(build.ctx.globalCacheDirPathMacro());
        if (build.watch) {
            len +%= 8;
        }
        if (build.color) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.emit_bin) |emit_bin| {
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
        if (build.emit_asm) |emit_asm| {
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
        if (build.emit_llvm_ir) |emit_llvm_ir| {
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
        if (build.emit_llvm_bc) |emit_llvm_bc| {
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
        if (build.emit_h) |emit_h| {
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
        if (build.emit_docs) |emit_docs| {
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
        if (build.emit_analysis) |emit_analysis| {
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
        if (build.emit_implib) |emit_implib| {
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
        if (build.show_builtin) {
            len +%= 15;
        }
        if (build.cache_dir) |how| {
            len +%= 12;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.global_cache_dir) |how| {
            len +%= 19;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.zig_lib_dir) |how| {
            len +%= 14;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.enable_cache) {
            len +%= 15;
        }
        if (build.target) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.cpu) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.code_model) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.red_zone) |red_zone| {
            if (red_zone) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (build.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                len +%= 21;
            } else {
                len +%= 24;
            }
        }
        if (build.exec_model) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.name) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.O) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.main_pkg_path) |how| {
            len +%= 16;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.pic) |pic| {
            if (pic) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (build.pie) |pie| {
            if (pie) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (build.lto) |lto| {
            if (lto) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (build.stack_check) |stack_check| {
            if (stack_check) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (build.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                len +%= 13;
            } else {
                len +%= 16;
            }
        }
        if (build.valgrind) |valgrind| {
            if (valgrind) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (build.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (build.dll_export_fns) |dll_export_fns| {
            if (dll_export_fns) {
                len +%= 17;
            } else {
                len +%= 20;
            }
        }
        if (build.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                len +%= 16;
            } else {
                len +%= 19;
            }
        }
        if (build.llvm) |llvm| {
            if (llvm) {
                len +%= 7;
            } else {
                len +%= 10;
            }
        }
        if (build.clang) |clang| {
            if (clang) {
                len +%= 8;
            } else {
                len +%= 11;
            }
        }
        if (build.stage1) |stage1| {
            if (stage1) {
                len +%= 9;
            } else {
                len +%= 12;
            }
        }
        if (build.single_threaded) |single_threaded| {
            if (single_threaded) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (build.builtin) {
            len +%= 10;
        }
        if (build.function_sections) |function_sections| {
            if (function_sections) {
                len +%= 20;
            } else {
                len +%= 23;
            }
        }
        if (build.strip) |strip| {
            if (strip) {
                len +%= 8;
            } else {
                len +%= 11;
            }
        }
        if (build.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                len +%= 19;
            } else {
                len +%= 22;
            }
        }
        if (build.fmt) |how| {
            len +%= 6;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.dirafter) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.system) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.include) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.libc) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.library) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.library_directory) |how| {
            len +%= 20;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.link_script) |how| {
            len +%= 9;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.version_script) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.dynamic_linker) |how| {
            len +%= 17;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.sysroot) |how| {
            len +%= 10;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.version) {
            len +%= 10;
        }
        if (build.entry) {
            len +%= 8;
        }
        if (build.soname) |soname| {
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
        if (build.lld) |lld| {
            if (lld) {
                len +%= 6;
            } else {
                len +%= 9;
            }
        }
        if (build.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (build.rdynamic) {
            len +%= 10;
        }
        if (build.rpath) |how| {
            len +%= 7;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                len +%= 17;
            } else {
                len +%= 20;
            }
        }
        if (build.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                len +%= 24;
            } else {
                len +%= 27;
            }
        }
        if (build.build_id) |build_id| {
            if (build_id) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (build.dynamic) {
            len +%= 9;
        }
        if (build.static) {
            len +%= 8;
        }
        if (build.symbolic) {
            len +%= 11;
        }
        if (build.compress_debug_sections) |how| {
            len +%= 26;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.gc_sections) |gc_sections| {
            if (gc_sections) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (build.stack) |how| {
            len +%= 8;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.image_base) |how| {
            len +%= 13;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.macros) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (build.packages) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (build.cflags) |how| {
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
        }
        if (build.z) |how| {
            len +%= 3;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.test_filter) |how| {
            len +%= 14;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.test_name_prefix) |how| {
            len +%= 19;
            len +%= mem.reinterpret.lengthAny(u8, fmt_spec, how);
            len +%= 1;
        }
        if (build.test_cmd) {
            len +%= 11;
        }
        if (build.test_cmd_bin) {
            len +%= 15;
        }
        if (build.test_evented_io) {
            len +%= 18;
        }
        if (build.test_no_exec) {
            len +%= 15;
        }
        len +%= Path.formatLength(build.ctx.sourceRootPath(build.root));
        len +%= 1;
        return len;
    }
    fn buildWrite(build: Builder, array: anytype) u64 {
        array.writeMany("zig\x00");
        switch (build.cmd) {
            .lib, .exe, .obj => {
                array.writeMany("build-");
                array.writeMany(@tagName(build.cmd));
                array.writeOne('\x00');
            },
            .fmt, .ast_check, .run => {
                array.writeMany(@tagName(build.cmd));
                array.writeOne('\x00');
            },
        }
        array.writeFormat(build.ctx.zigExePathMacro());
        array.writeFormat(build.ctx.buildRootPathMacro());
        array.writeFormat(build.ctx.cacheDirPathMacro());
        array.writeFormat(build.ctx.globalCacheDirPathMacro());
        if (build.watch) {
            array.writeMany("--watch\x00");
        }
        if (build.color) |how| {
            array.writeMany("--color\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.emit_bin) |emit_bin| {
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
        if (build.emit_asm) |emit_asm| {
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
        if (build.emit_llvm_ir) |emit_llvm_ir| {
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
        if (build.emit_llvm_bc) |emit_llvm_bc| {
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
        if (build.emit_h) |emit_h| {
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
        if (build.emit_docs) |emit_docs| {
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
        if (build.emit_analysis) |emit_analysis| {
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
        if (build.emit_implib) |emit_implib| {
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
        if (build.show_builtin) {
            array.writeMany("--show-builtin\x00");
        }
        if (build.cache_dir) |how| {
            array.writeMany("--cache-dir\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.global_cache_dir) |how| {
            array.writeMany("--global-cache-dir\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.zig_lib_dir) |how| {
            array.writeMany("--zig-lib-dir\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.enable_cache) {
            array.writeMany("--enable-cache\x00");
        }
        if (build.target) |how| {
            array.writeMany("-target\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.cpu) |how| {
            array.writeMany("-mcpu\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.code_model) |how| {
            array.writeMany("-mcmodel\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.red_zone) |red_zone| {
            if (red_zone) {
                array.writeMany("-mred-zone\x00");
            } else {
                array.writeMany("-mno-red-zone\x00");
            }
        }
        if (build.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                array.writeMany("-fomit-frame-pointer\x00");
            } else {
                array.writeMany("-fno-omit-frame-pointer\x00");
            }
        }
        if (build.exec_model) |how| {
            array.writeMany("-mexec-model\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.name) |how| {
            array.writeMany("--name\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.O) |how| {
            array.writeMany("-O\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.main_pkg_path) |how| {
            array.writeMany("--main-pkg-path\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.pic) |pic| {
            if (pic) {
                array.writeMany("-fPIC\x00");
            } else {
                array.writeMany("-fno-PIC\x00");
            }
        }
        if (build.pie) |pie| {
            if (pie) {
                array.writeMany("-fPIE\x00");
            } else {
                array.writeMany("-fno-PIE\x00");
            }
        }
        if (build.lto) |lto| {
            if (lto) {
                array.writeMany("-flto\x00");
            } else {
                array.writeMany("-fno-lto\x00");
            }
        }
        if (build.stack_check) |stack_check| {
            if (stack_check) {
                array.writeMany("-fstack-check\x00");
            } else {
                array.writeMany("-fno-stack-check\x00");
            }
        }
        if (build.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                array.writeMany("-fsanitize-c\x00");
            } else {
                array.writeMany("-fno-sanitize-c\x00");
            }
        }
        if (build.valgrind) |valgrind| {
            if (valgrind) {
                array.writeMany("-fvalgrind\x00");
            } else {
                array.writeMany("-fno-valgrind\x00");
            }
        }
        if (build.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                array.writeMany("-fsanitize-thread\x00");
            } else {
                array.writeMany("-fno-sanitize-thread\x00");
            }
        }
        if (build.dll_export_fns) |dll_export_fns| {
            if (dll_export_fns) {
                array.writeMany("-fdll-export-fns\x00");
            } else {
                array.writeMany("-fno-dll-export-fns\x00");
            }
        }
        if (build.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                array.writeMany("-funwind-tables\x00");
            } else {
                array.writeMany("-fno-unwind-tables\x00");
            }
        }
        if (build.llvm) |llvm| {
            if (llvm) {
                array.writeMany("-fLLVM\x00");
            } else {
                array.writeMany("-fno-LLVM\x00");
            }
        }
        if (build.clang) |clang| {
            if (clang) {
                array.writeMany("-fClang\x00");
            } else {
                array.writeMany("-fno-Clang\x00");
            }
        }
        if (build.stage1) |stage1| {
            if (stage1) {
                array.writeMany("-fstage1\x00");
            } else {
                array.writeMany("-fno-stage1\x00");
            }
        }
        if (build.single_threaded) |single_threaded| {
            if (single_threaded) {
                array.writeMany("-fsingle-threaded\x00");
            } else {
                array.writeMany("-fno-single-threaded\x00");
            }
        }
        if (build.builtin) {
            array.writeMany("-fbuiltin\x00");
        }
        if (build.function_sections) |function_sections| {
            if (function_sections) {
                array.writeMany("-ffunction-sections\x00");
            } else {
                array.writeMany("-fno-function-sections\x00");
            }
        }
        if (build.strip) |strip| {
            if (strip) {
                array.writeMany("-fstrip\x00");
            } else {
                array.writeMany("-fno-strip\x00");
            }
        }
        if (build.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                array.writeMany("-fformatted-panics\x00");
            } else {
                array.writeMany("-fno-formatted-panics\x00");
            }
        }
        if (build.fmt) |how| {
            array.writeMany("-ofmt\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.dirafter) |how| {
            array.writeMany("-dirafter\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.system) |how| {
            array.writeMany("-isystem\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.include) |how| {
            array.writeMany("-I\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.libc) |how| {
            array.writeMany("--libc\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.library) |how| {
            array.writeMany("--library\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.library_directory) |how| {
            array.writeMany("--library-directory\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.link_script) |how| {
            array.writeMany("--script\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.version_script) |how| {
            array.writeMany("--version-script\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.dynamic_linker) |how| {
            array.writeMany("--dynamic-linker\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.sysroot) |how| {
            array.writeMany("--sysroot\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.version) {
            array.writeMany("--version\x00");
        }
        if (build.entry) {
            array.writeMany("--entry\x00");
        }
        if (build.soname) |soname| {
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
        if (build.lld) |lld| {
            if (lld) {
                array.writeMany("-fLLD\x00");
            } else {
                array.writeMany("-fno-LLD\x00");
            }
        }
        if (build.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                array.writeMany("-fcompiler-rt\x00");
            } else {
                array.writeMany("-fno-compiler-rt\x00");
            }
        }
        if (build.rdynamic) {
            array.writeMany("-rdynamic\x00");
        }
        if (build.rpath) |how| {
            array.writeMany("-rpath\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                array.writeMany("-feach-lib-rpath\x00");
            } else {
                array.writeMany("-fno-each-lib-rpath\x00");
            }
        }
        if (build.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                array.writeMany("-fallow-shlib-undefined\x00");
            } else {
                array.writeMany("-fno-allow-shlib-undefined\x00");
            }
        }
        if (build.build_id) |build_id| {
            if (build_id) {
                array.writeMany("-fbuild-id\x00");
            } else {
                array.writeMany("-fno-build-id\x00");
            }
        }
        if (build.dynamic) {
            array.writeMany("-dynamic\x00");
        }
        if (build.static) {
            array.writeMany("-static\x00");
        }
        if (build.symbolic) {
            array.writeMany("-Bsymbolic\x00");
        }
        if (build.compress_debug_sections) |how| {
            array.writeMany("--compress-debug-sections\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.gc_sections) |gc_sections| {
            if (gc_sections) {
                array.writeMany("--gc-sections\x00");
            } else {
                array.writeMany("--no-gc-sections\x00");
            }
        }
        if (build.stack) |how| {
            array.writeMany("--stack\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.image_base) |how| {
            array.writeMany("--image-base\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.macros) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (build.packages) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (build.cflags) |how| {
            array.writeAny(fmt_spec, how);
        }
        if (build.z) |how| {
            array.writeMany("-z\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.test_filter) |how| {
            array.writeMany("--test-filter\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.test_name_prefix) |how| {
            array.writeMany("--test-name-prefix\x00");
            array.writeAny(fmt_spec, how);
            array.writeOne('\x00');
        }
        if (build.test_cmd) {
            array.writeMany("--test-cmd\x00");
        }
        if (build.test_cmd_bin) {
            array.writeMany("--test-cmd-bin\x00");
        }
        if (build.test_evented_io) {
            array.writeMany("--test-evented-io\x00");
        }
        if (build.test_no_exec) {
            array.writeMany("--test-no-exec\x00");
        }
        array.writeFormat(build.ctx.sourceRootPath(build.root));
        array.writeOne('\x00');
        return countArgs(array);
    }
    pub fn allocateExec(builder: Builder, allocator: *Allocator) !u64 {
        var array: String = try meta.wrap(String.init(allocator, builder.buildLength()));
        defer array.deinit(allocator);
        var args: Pointers = try meta.wrap(Pointers.init(allocator, builder.buildWrite(&array)));
        defer args.deinit(allocator);
        builtin.assertBelowOrEqual(u64, array.len(), max_len);
        builtin.assertBelowOrEqual(u64, makeArgs(array, &args), max_args);
        builtin.assertEqual(u64, array.len(), builder.buildLength());
        return builder.genericExec(args.referAllDefined());
    }
    pub fn exec(builder: Builder) !u64 {
        var array: StaticString = .{};
        var args: StaticPointers = .{};
        builtin.assertBelowOrEqual(u64, builder.buildWrite(&array), max_args);
        builtin.assertBelowOrEqual(u64, makeArgs(&array, &args), max_args);
        builtin.assertEqual(u64, array.len(), builder.buildLength());
        return builder.genericExec(args.referAllDefined());
    }
    fn genericExec(builder: Builder, args: [][*:0]u8) !u64 {
        return proc.command(.{}, builder.ctx.zig_exe, args, builder.ctx.vars);
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
    args: [][*:0]u8,
    vars: [][*:0]u8,
    allocator: *Allocator,
    cmds: ArrayC = .{},
    array: *ArrayU,
    const ArrayC = mem.StaticArray(BuildCmd, 64);
    pub const ArrayU = Allocator.UnstructuredHolder(8, 8);

    pub fn zigExePath(ctx: *const Context) Path {
        return ctx.path(ctx.zig_exe);
    }
    pub fn buildRootPath(ctx: *const Context) Path {
        return ctx.path(ctx.build_root);
    }
    pub fn cacheDirPath(ctx: *const Context) Path {
        return ctx.path(ctx.cache_dir);
    }
    pub fn globalCacheDirPath(ctx: *const Context) Path {
        return ctx.path(ctx.global_cache_dir);
    }
    pub fn sourceRootPath(ctx: *const Context, root: [:0]const u8) Path {
        return ctx.path(root);
    }
    pub fn zigExePathMacro(ctx: *const Context) Macro {
        return .{ .name = "zig_exe", .value = .{ .path = zigExePath(ctx) } };
    }
    pub fn buildRootPathMacro(ctx: *const Context) Macro {
        return .{ .name = "build_root", .value = .{ .path = buildRootPath(ctx) } };
    }
    pub fn cacheDirPathMacro(ctx: *const Context) Macro {
        return .{ .name = "cache_dir", .value = .{ .path = cacheDirPath(ctx) } };
    }
    pub fn globalCacheDirPathMacro(ctx: *const Context) Macro {
        return .{ .name = "global_cache_dir", .value = .{ .path = globalCacheDirPath(ctx) } };
    }
    pub fn sourceRootPathMacro(ctx: *const Context, root: [:0]const u8) Macro {
        return .{ .name = "root", .value = .{ .path = ctx.sourceRootPath(root) } };
    }
    pub fn path(ctx: *const Context, name: [:0]const u8) Path {
        return .{ .ctx = ctx, .pathname = name };
    }
    pub fn dupe(ctx: *const Context, comptime T: type, value: T) *T {
        ctx.writeOne(T, value);
        return ctx.array.referOneBack(T);
    }
    pub fn dupeMany(ctx: *const Context, comptime T: type, values: []const T) []const T {
        if (@ptrToInt(values.ptr) < builtin.AddressSpace.low(0)) {
            return values;
        }
        ctx.array.writeMany(T, values);
        return ctx.array.referManyBack(T, .{ .count = values.len });
    }
    pub fn dupeWithSentinel(ctx: *const Context, comptime T: type, comptime sentinel: T, values: [:sentinel]const T) [:sentinel]const T {
        if (@ptrToInt(values.ptr) < builtin.AddressSpace.low(0)) {
            return values;
        }
        defer ctx.array.define(T, .{ .count = 1 });
        ctx.array.writeMany(T, values);
        ctx.array.referOneUndefined(T).* = sentinel;
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
            .ctx = ctx,
            .root = pathname,
            .cmd = .exe,
            .name = name,
        };
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
        //if (args.emit_asm_path) |asm_path| {
        //    ret.emit_asm = .{ .yes = ctx.path(asm_path) };
        //}
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
    ctx: ?*const Context = null,
    pathname: [:0]const u8,
    const Format = @This();
    pub fn formatWrite(format: Format, array: anytype) void {
        if (format.ctx) |ctx| {
            if (format.pathname[0] != '/') {
                array.writeMany(ctx.build_root);
                array.writeOne('/');
            }
        }
        array.writeMany(format.pathname);
    }
    pub fn formatLength(format: Format) u64 {
        var len: u64 = 0;
        if (format.ctx) |ctx| {
            if (format.pathname[0] != '/') {
                len +%= ctx.build_root.len;
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
        is_correct: ?bool = null,
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
