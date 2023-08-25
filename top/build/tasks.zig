const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const debug = @import("../debug.zig");
const parse = @import("../parse.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const safety: bool = false;
pub const PathUnion = union(enum) {
    yes: ?types.Path,
    no,
};
pub const BuildCommand = struct {
    kind: types.OutputMode,
    /// (default=yes) Output machine code
    emit_bin: ?PathUnion = null,
    /// (default=no) Output assembly code (.s)
    emit_asm: ?PathUnion = null,
    /// (default=no) Output optimized LLVM IR (.ll)
    emit_llvm_ir: ?PathUnion = null,
    /// (default=no) Output optimized LLVM BC (.bc)
    emit_llvm_bc: ?PathUnion = null,
    /// (default=no) Output a C header file (.h)
    emit_h: ?PathUnion = null,
    /// (default=no) Output documentation (.html)
    emit_docs: ?PathUnion = null,
    /// (default=no) Output analysis (.json)
    emit_analysis: ?PathUnion = null,
    /// (default=yes) Output an import when building a Windows DLL (.lib)
    emit_implib: ?PathUnion = null,
    /// Override the local cache directory
    cache_root: ?[]const u8 = null,
    /// Override the global cache directory
    global_cache_root: ?[]const u8 = null,
    /// Override Zig installation lib directory
    zig_lib_root: ?[]const u8 = null,
    /// [MISSING]
    listen: ?types.Listen = null,
    /// <arch><sub>-<os>-<abi> see the targets command
    target: ?[]const u8 = null,
    /// Specify target CPU and feature set
    cpu: ?[]const u8 = null,
    /// Limit range of code and data virtual addresses
    code_model: ?builtin.CodeModel = null,
    /// Enable the "red-zone"
    red_zone: ?bool = null,
    /// Enable implicit builtin knowledge of functions
    implicit_builtins: ?bool = null,
    /// Omit the stack frame pointer
    omit_frame_pointer: ?bool = null,
    /// (WASI) Execution model
    exec_model: ?[]const u8 = null,
    /// Override root name
    name: ?[]const u8 = null,
    /// Override the default SONAME value
    soname: ?union(enum) {
        yes: []const u8,
        no,
    } = null,
    /// Choose what to optimize for:
    ///   Debug          Optimizations off, safety on
    ///   ReleaseSafe    Optimizations on, safety on
    ///   ReleaseFast    Optimizations on, safety off
    ///   ReleaseSmall   Size optimizations on, safety off
    mode: ?builtin.OptimizeMode = null,
    /// Only run [limit] first LLVM optimization passes
    passes: ?usize = null,
    /// Set the directory of the root package
    main_pkg_path: ?[]const u8 = null,
    /// Enable Position Independent Code
    pic: ?bool = null,
    /// Enable Position Independent Executable
    pie: ?bool = null,
    /// Enable Link Time Optimization
    lto: ?bool = null,
    /// Enable stack probing in unsafe builds
    stack_check: ?bool = null,
    /// Enable stack protection in unsafe builds
    stack_protector: ?bool = null,
    /// Enable C undefined behaviour detection in unsafe builds
    sanitize_c: ?bool = null,
    /// Include valgrind client requests in release builds
    valgrind: ?bool = null,
    /// Enable thread sanitizer
    sanitize_thread: ?bool = null,
    /// Always produce unwind table entries for all functions
    unwind_tables: ?bool = null,
    /// How many lines of reference trace should be shown per compile error
    reference_trace: ?bool = null,
    /// Enable error tracing in `ReleaseFast` mode
    error_tracing: ?bool = null,
    /// Code assumes there is only one thread
    single_threaded: ?bool = null,
    /// Places each function in a separate sections
    function_sections: ?bool = null,
    /// Omit debug symbols
    strip: ?bool = null,
    /// Enable formatted safety panics
    formatted_panics: ?bool = null,
    /// Override target object format:
    ///   elf                    Executable and Linking Format
    ///   c                      C source code
    ///   wasm                   WebAssembly
    ///   coff                   Common Object File Format (Windows)
    ///   macho                  macOS relocatables
    ///   spirv                  Standard, Portable Intermediate Representation V (SPIR-V)
    ///   plan9                  Plan 9 from Bell Labs object format
    ///   hex (planned feature)  Intel IHEX
    ///   raw (planned feature)  Dump machine code directly
    format: ?builtin.ObjectFormat = null,
    /// Add directory to AFTER include search path
    dirafter: ?[]const u8 = null,
    /// Add directory to SYSTEM include search path
    system: ?[]const u8 = null,
    /// Provide a file which specifies libc paths
    libc: ?[]const u8 = null,
    /// Link against system library (only if actually used)
    library: ?[]const u8 = null,
    /// Add directories to include search path
    include: ?[]const []const u8 = null,
    /// Link against system library (even if unused)
    needed_library: ?[]const []const u8 = null,
    /// Add a directory to the library search path
    library_directory: ?[]const []const u8 = null,
    /// Use a custom linker script
    link_script: ?[]const u8 = null,
    /// Provide a version .map file
    version_script: ?[]const u8 = null,
    /// Set the dynamic interpreter path
    dynamic_linker: ?[]const u8 = null,
    /// Set the system root directory
    sysroot: ?[]const u8 = null,
    /// Set the entrypoint symbol name
    entry: ?[]const u8 = null,
    /// Use LLD as the linker
    lld: ?bool = null,
    /// (default) Include compiler-rt symbols in output
    compiler_rt: ?bool = null,
    /// Add directory to the runtime library search path
    rpath: ?[]const u8 = null,
    /// Ensure adding rpath for each used dynamic library
    each_lib_rpath: ?bool = null,
    /// Allow undefined symbols in shared libraries
    allow_shlib_undefined: ?bool = null,
    /// Help coordinate stripped binaries with debug symbols
    build_id: ?types.BuildId = null,
    /// Enable C++ exception handling by passing --eh-frame-hdr to linker
    eh_frame_hdr: bool = false,
    /// Enable output of relocation sections for post build tools
    emit_relocs: bool = false,
    /// Force removal of functions and data that are unreachable
    /// by the entry point or exported symbols
    gc_sections: ?bool = null,
    /// Override default stack size
    stack: ?usize = null,
    /// Set base address for executable image
    image_base: ?usize = null,
    /// Define C macros available within the `@cImport` namespace
    macros: ?[]const types.Macro = null,
    /// Define modules available as dependencies for the current target
    modules: ?[]const types.Module = null,
    /// Define module dependencies for the current target
    dependencies: ?[]const types.ModuleDependency = null,
    /// Set extra flags for the next position C source files
    cflags: ?[]const []const u8 = null,
    /// Link libc
    link_libc: bool = false,
    /// Add all symbols to the dynamic symbol table
    rdynamic: bool = false,
    /// Force output to be dynamically linked
    dynamic: bool = false,
    /// Force output to be statically linked
    static: bool = false,
    /// Bind global references locally
    symbolic: bool = false,
    /// Set linker extension flags:
    ///   nodelete                   Indicate that the object cannot be deleted from a process
    ///   notext                     Permit read-only relocations in read-only segments
    ///   defs                       Force a fatal error if any undefined symbols remain
    ///   undefs                     Reverse of -z defs
    ///   origin                     Indicate that the object must have its origin processed
    ///   nocopyreloc                Disable the creation of copy relocations
    ///   now (default)              Force all relocations to be processed on load
    ///   lazy                       Don't force all relocations to be processed on load
    ///   relro (default)            Force all relocations to be read-only after processing
    ///   norelro                    Don't force all relocations to be read-only after processing
    ///   common-page-size=[bytes]   Set the common page size for ELF binaries
    ///   max-page-size=[bytes]      Set the max page size for ELF binaries
    lflags: ?[]const enum(u4) {
        nodelete = 0,
        notext = 1,
        defs = 2,
        origin = 3,
        nocopyreloc = 4,
        now = 5,
        lazy = 6,
        relro = 7,
        norelro = 8,
    } = null,
    /// Enable or disable colored error messages
    color: ?types.AutoOnOff = null,
    /// Print timing diagnostics
    time_report: bool = false,
    /// Print stack size diagnostics
    stack_report: bool = false,
    /// Display linker invocations
    verbose_link: bool = false,
    /// Display C compiler invocations
    verbose_cc: bool = false,
    /// Enable compiler debug output for Zig AIR
    verbose_air: bool = false,
    /// Enable compiler debug output for Zig MIR
    verbose_mir: bool = false,
    /// Enable compiler debug output for LLVM IR
    verbose_llvm_ir: bool = false,
    /// Enable compiler debug output for C imports
    verbose_cimport: bool = false,
    /// Enable compiler debug output for LLVM CPU features
    verbose_llvm_cpu_features: bool = false,
    /// Enable printing debug/info log messages for scope
    debug_log: ?[]const u8 = null,
    /// Crash with helpful diagnostics at the first compile error
    debug_compiler_errors: bool = false,
    /// Enable dumping of the linker's state in JSON
    debug_link_snapshot: bool = false,
    pub fn formatWriteBuf(cmd: *types.BuildCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        @memcpy(ptr, zig_exe);
        ptr += zig_exe.len;
        ptr[0] = 0;
        ptr += 1;
        ptr[0..6].* = "build-".*;
        ptr += 6;
        @memcpy(ptr, @tagName(cmd.kind));
        ptr += @tagName(cmd.kind).len;
        ptr[0] = 0;
        ptr += 1;
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..11].* = "-femit-bin\x3d".*;
                        ptr += 11;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..11].* = "-femit-bin\x00".*;
                        ptr += 11;
                    }
                },
                .no => {
                    ptr[0..14].* = "-fno-emit-bin\x00".*;
                    ptr += 14;
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..11].* = "-femit-asm\x3d".*;
                        ptr += 11;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..11].* = "-femit-asm\x00".*;
                        ptr += 11;
                    }
                },
                .no => {
                    ptr[0..14].* = "-fno-emit-asm\x00".*;
                    ptr += 14;
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..15].* = "-femit-llvm-ir\x3d".*;
                        ptr += 15;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..15].* = "-femit-llvm-ir\x00".*;
                        ptr += 15;
                    }
                },
                .no => {
                    ptr[0..18].* = "-fno-emit-llvm-ir\x00".*;
                    ptr += 18;
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..15].* = "-femit-llvm-bc\x3d".*;
                        ptr += 15;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..15].* = "-femit-llvm-bc\x00".*;
                        ptr += 15;
                    }
                },
                .no => {
                    ptr[0..18].* = "-fno-emit-llvm-bc\x00".*;
                    ptr += 18;
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..9].* = "-femit-h\x3d".*;
                        ptr += 9;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..9].* = "-femit-h\x00".*;
                        ptr += 9;
                    }
                },
                .no => {
                    ptr[0..12].* = "-fno-emit-h\x00".*;
                    ptr += 12;
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..12].* = "-femit-docs\x3d".*;
                        ptr += 12;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..12].* = "-femit-docs\x00".*;
                        ptr += 12;
                    }
                },
                .no => {
                    ptr[0..15].* = "-fno-emit-docs\x00".*;
                    ptr += 15;
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..16].* = "-femit-analysis\x3d".*;
                        ptr += 16;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..16].* = "-femit-analysis\x00".*;
                        ptr += 16;
                    }
                },
                .no => {
                    ptr[0..19].* = "-fno-emit-analysis\x00".*;
                    ptr += 19;
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr[0..14].* = "-femit-implib\x3d".*;
                        ptr += 14;
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr[0..14].* = "-femit-implib\x00".*;
                        ptr += 14;
                    }
                },
                .no => {
                    ptr[0..17].* = "-fno-emit-implib\x00".*;
                    ptr += 17;
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            ptr[0..12].* = "--cache-dir\x00".*;
            ptr += 12;
            @memcpy(ptr, cache_root);
            ptr += cache_root.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            ptr[0..19].* = "--global-cache-dir\x00".*;
            ptr += 19;
            @memcpy(ptr, global_cache_root);
            ptr += global_cache_root.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            ptr[0..14].* = "--zig-lib-dir\x00".*;
            ptr += 14;
            @memcpy(ptr, zig_lib_root);
            ptr += zig_lib_root.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.listen) |listen| {
            ptr[0..9].* = "--listen\x00".*;
            ptr += 9;
            @memcpy(ptr, @tagName(listen));
            ptr += @tagName(listen).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.target) |target| {
            ptr[0..8].* = "-target\x00".*;
            ptr += 8;
            @memcpy(ptr, target);
            ptr += target.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.cpu) |cpu| {
            ptr[0..6].* = "-mcpu\x00".*;
            ptr += 6;
            @memcpy(ptr, cpu);
            ptr += cpu.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.code_model) |code_model| {
            ptr[0..9].* = "-mcmodel\x00".*;
            ptr += 9;
            @memcpy(ptr, @tagName(code_model));
            ptr += @tagName(code_model).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                ptr[0..11].* = "-mred-zone\x00".*;
                ptr += 11;
            } else {
                ptr[0..14].* = "-mno-red-zone\x00".*;
                ptr += 14;
            }
        }
        if (cmd.implicit_builtins) |implicit_builtins| {
            if (implicit_builtins) {
                ptr[0..10].* = "-fbuiltin\x00".*;
                ptr += 10;
            } else {
                ptr[0..13].* = "-fno-builtin\x00".*;
                ptr += 13;
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                ptr[0..21].* = "-fomit-frame-pointer\x00".*;
                ptr += 21;
            } else {
                ptr[0..24].* = "-fno-omit-frame-pointer\x00".*;
                ptr += 24;
            }
        }
        if (cmd.exec_model) |exec_model| {
            ptr[0..13].* = "-mexec-model\x00".*;
            ptr += 13;
            @memcpy(ptr, exec_model);
            ptr += exec_model.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.name) |name| {
            ptr[0..7].* = "--name\x00".*;
            ptr += 7;
            @memcpy(ptr, name);
            ptr += name.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    ptr[0..9].* = "-fsoname\x00".*;
                    ptr += 9;
                    @memcpy(ptr, arg);
                    ptr += arg.len;
                    ptr[0] = 0;
                    ptr += 1;
                },
                .no => {
                    ptr[0..12].* = "-fno-soname\x00".*;
                    ptr += 12;
                },
            }
        }
        if (cmd.mode) |mode| {
            ptr[0..3].* = "-O\x00".*;
            ptr += 3;
            @memcpy(ptr, @tagName(mode));
            ptr += @tagName(mode).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.passes) |passes| {
            ptr[0..19].* = "-fopt-bisect-limit\x3d".*;
            ptr += 19;
            ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = passes }, ptr);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.main_pkg_path) |main_pkg_path| {
            ptr[0..16].* = "--main-pkg-path\x00".*;
            ptr += 16;
            @memcpy(ptr, main_pkg_path);
            ptr += main_pkg_path.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.pic) |pic| {
            if (pic) {
                ptr[0..6].* = "-fPIC\x00".*;
                ptr += 6;
            } else {
                ptr[0..9].* = "-fno-PIC\x00".*;
                ptr += 9;
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                ptr[0..6].* = "-fPIE\x00".*;
                ptr += 6;
            } else {
                ptr[0..9].* = "-fno-PIE\x00".*;
                ptr += 9;
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                ptr[0..6].* = "-flto\x00".*;
                ptr += 6;
            } else {
                ptr[0..9].* = "-fno-lto\x00".*;
                ptr += 9;
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                ptr[0..14].* = "-fstack-check\x00".*;
                ptr += 14;
            } else {
                ptr[0..17].* = "-fno-stack-check\x00".*;
                ptr += 17;
            }
        }
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                ptr[0..18].* = "-fstack-protector\x00".*;
                ptr += 18;
            } else {
                ptr[0..21].* = "-fno-stack-protector\x00".*;
                ptr += 21;
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                ptr[0..13].* = "-fsanitize-c\x00".*;
                ptr += 13;
            } else {
                ptr[0..16].* = "-fno-sanitize-c\x00".*;
                ptr += 16;
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                ptr[0..11].* = "-fvalgrind\x00".*;
                ptr += 11;
            } else {
                ptr[0..14].* = "-fno-valgrind\x00".*;
                ptr += 14;
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                ptr[0..18].* = "-fsanitize-thread\x00".*;
                ptr += 18;
            } else {
                ptr[0..21].* = "-fno-sanitize-thread\x00".*;
                ptr += 21;
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                ptr[0..16].* = "-funwind-tables\x00".*;
                ptr += 16;
            } else {
                ptr[0..19].* = "-fno-unwind-tables\x00".*;
                ptr += 19;
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                ptr[0..18].* = "-freference-trace\x00".*;
                ptr += 18;
            } else {
                ptr[0..21].* = "-fno-reference-trace\x00".*;
                ptr += 21;
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                ptr[0..16].* = "-ferror-tracing\x00".*;
                ptr += 16;
            } else {
                ptr[0..19].* = "-fno-error-tracing\x00".*;
                ptr += 19;
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                ptr[0..18].* = "-fsingle-threaded\x00".*;
                ptr += 18;
            } else {
                ptr[0..21].* = "-fno-single-threaded\x00".*;
                ptr += 21;
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                ptr[0..20].* = "-ffunction-sections\x00".*;
                ptr += 20;
            } else {
                ptr[0..23].* = "-fno-function-sections\x00".*;
                ptr += 23;
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                ptr[0..8].* = "-fstrip\x00".*;
                ptr += 8;
            } else {
                ptr[0..11].* = "-fno-strip\x00".*;
                ptr += 11;
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                ptr[0..19].* = "-fformatted-panics\x00".*;
                ptr += 19;
            } else {
                ptr[0..22].* = "-fno-formatted-panics\x00".*;
                ptr += 22;
            }
        }
        if (cmd.format) |format| {
            ptr[0..6].* = "-ofmt\x3d".*;
            ptr += 6;
            @memcpy(ptr, @tagName(format));
            ptr += @tagName(format).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.dirafter) |dirafter| {
            ptr[0..11].* = "-idirafter\x00".*;
            ptr += 11;
            @memcpy(ptr, dirafter);
            ptr += dirafter.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.system) |system| {
            ptr[0..9].* = "-isystem\x00".*;
            ptr += 9;
            @memcpy(ptr, system);
            ptr += system.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.libc) |libc| {
            ptr[0..7].* = "--libc\x00".*;
            ptr += 7;
            @memcpy(ptr, libc);
            ptr += libc.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.library) |library| {
            ptr[0..10].* = "--library\x00".*;
            ptr += 10;
            @memcpy(ptr, library);
            ptr += library.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                ptr[0..3].* = "-I\x00".*;
                ptr += 3;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                ptr[0..17].* = "--needed-library\x00".*;
                ptr += 17;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                ptr[0..20].* = "--library-directory\x00".*;
                ptr += 20;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.link_script) |link_script| {
            ptr[0..9].* = "--script\x00".*;
            ptr += 9;
            @memcpy(ptr, link_script);
            ptr += link_script.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.version_script) |version_script| {
            ptr[0..17].* = "--version-script\x00".*;
            ptr += 17;
            @memcpy(ptr, version_script);
            ptr += version_script.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            ptr[0..17].* = "--dynamic-linker\x00".*;
            ptr += 17;
            @memcpy(ptr, dynamic_linker);
            ptr += dynamic_linker.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.sysroot) |sysroot| {
            ptr[0..10].* = "--sysroot\x00".*;
            ptr += 10;
            @memcpy(ptr, sysroot);
            ptr += sysroot.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.entry) |entry| {
            ptr[0..8].* = "--entry\x00".*;
            ptr += 8;
            @memcpy(ptr, entry);
            ptr += entry.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.lld) |lld| {
            if (lld) {
                ptr[0..6].* = "-fLLD\x00".*;
                ptr += 6;
            } else {
                ptr[0..9].* = "-fno-LLD\x00".*;
                ptr += 9;
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                ptr[0..14].* = "-fcompiler-rt\x00".*;
                ptr += 14;
            } else {
                ptr[0..17].* = "-fno-compiler-rt\x00".*;
                ptr += 17;
            }
        }
        if (cmd.rpath) |rpath| {
            ptr[0..7].* = "-rpath\x00".*;
            ptr += 7;
            @memcpy(ptr, rpath);
            ptr += rpath.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                ptr[0..17].* = "-feach-lib-rpath\x00".*;
                ptr += 17;
            } else {
                ptr[0..20].* = "-fno-each-lib-rpath\x00".*;
                ptr += 20;
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                ptr[0..24].* = "-fallow-shlib-undefined\x00".*;
                ptr += 24;
            } else {
                ptr[0..27].* = "-fno-allow-shlib-undefined\x00".*;
                ptr += 27;
            }
        }
        if (cmd.build_id) |build_id| {
            ptr[0..11].* = "--build-id\x3d".*;
            ptr += 11;
            @memcpy(ptr, @tagName(build_id));
            ptr += @tagName(build_id).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.eh_frame_hdr) {
            ptr[0..15].* = "--eh-frame-hdr\x00".*;
            ptr += 15;
        }
        if (cmd.emit_relocs) {
            ptr[0..14].* = "--emit-relocs\x00".*;
            ptr += 14;
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                ptr[0..14].* = "--gc-sections\x00".*;
                ptr += 14;
            } else {
                ptr[0..17].* = "--no-gc-sections\x00".*;
                ptr += 17;
            }
        }
        if (cmd.stack) |stack| {
            ptr[0..8].* = "--stack\x00".*;
            ptr += 8;
            ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = stack }, ptr);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.image_base) |image_base| {
            ptr[0..13].* = "--image-base\x00".*;
            ptr += 13;
            ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = image_base }, ptr);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.macros) |macros| {
            for (macros) |value| {
                ptr += value.formatWriteBuf(ptr);
            }
        }
        if (cmd.modules) |modules| {
            for (modules) |value| {
                ptr += value.formatWriteBuf(ptr);
            }
        }
        if (cmd.dependencies) |dependencies| {
            ptr += types.ModuleDependencies.formatWriteBuf(.{ .value = dependencies }, ptr);
        }
        if (cmd.cflags) |cflags| {
            ptr += types.CFlags.formatWriteBuf(.{ .value = cflags }, ptr);
        }
        if (cmd.link_libc) {
            ptr[0..4].* = "-lc\x00".*;
            ptr += 4;
        }
        if (cmd.rdynamic) {
            ptr[0..10].* = "-rdynamic\x00".*;
            ptr += 10;
        }
        if (cmd.dynamic) {
            ptr[0..9].* = "-dynamic\x00".*;
            ptr += 9;
        }
        if (cmd.static) {
            ptr[0..8].* = "-static\x00".*;
            ptr += 8;
        }
        if (cmd.symbolic) {
            ptr[0..11].* = "-Bsymbolic\x00".*;
            ptr += 11;
        }
        if (cmd.lflags) |lflags| {
            for (lflags) |value| {
                ptr[0..3].* = "-z\x00".*;
                ptr += 3;
                @memcpy(ptr, @tagName(value));
                ptr += @tagName(value).len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        for (files) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
        if (cmd.color) |color| {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
            @memcpy(ptr, @tagName(color));
            ptr += @tagName(color).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.time_report) {
            ptr[0..14].* = "-ftime-report\x00".*;
            ptr += 14;
        }
        if (cmd.stack_report) {
            ptr[0..15].* = "-fstack-report\x00".*;
            ptr += 15;
        }
        if (cmd.verbose_link) {
            ptr[0..15].* = "--verbose-link\x00".*;
            ptr += 15;
        }
        if (cmd.verbose_cc) {
            ptr[0..13].* = "--verbose-cc\x00".*;
            ptr += 13;
        }
        if (cmd.verbose_air) {
            ptr[0..14].* = "--verbose-air\x00".*;
            ptr += 14;
        }
        if (cmd.verbose_mir) {
            ptr[0..14].* = "--verbose-mir\x00".*;
            ptr += 14;
        }
        if (cmd.verbose_llvm_ir) {
            ptr[0..18].* = "--verbose-llvm-ir\x00".*;
            ptr += 18;
        }
        if (cmd.verbose_cimport) {
            ptr[0..18].* = "--verbose-cimport\x00".*;
            ptr += 18;
        }
        if (cmd.verbose_llvm_cpu_features) {
            ptr[0..28].* = "--verbose-llvm-cpu-features\x00".*;
            ptr += 28;
        }
        if (cmd.debug_log) |debug_log| {
            ptr[0..12].* = "--debug-log\x00".*;
            ptr += 12;
            @memcpy(ptr, debug_log);
            ptr += debug_log.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.debug_compiler_errors) {
            ptr[0..23].* = "--debug-compile-errors\x00".*;
            ptr += 23;
        }
        if (cmd.debug_link_snapshot) {
            ptr[0..22].* = "--debug-link-snapshot\x00".*;
            ptr += 22;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.BuildCommand, zig_exe: []const u8, files: []const types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= zig_exe.len;
        len +%= 1;
        len +%= 6;
        len +%= @tagName(cmd.kind).len;
        len +%= 1;
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 11;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 11;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 15;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 15;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 9;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 12;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 16;
                        len +%= arg.formatLength();
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
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 14;
                        len +%= arg.formatLength();
                    } else {
                        len +%= 14;
                    }
                },
                .no => {
                    len +%= 17;
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            len +%= 12;
            len +%= cache_root.len;
            len +%= 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            len +%= 19;
            len +%= global_cache_root.len;
            len +%= 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            len +%= 14;
            len +%= zig_lib_root.len;
            len +%= 1;
        }
        if (cmd.listen) |listen| {
            len +%= 9;
            len +%= @tagName(listen).len;
            len +%= 1;
        }
        if (cmd.target) |target| {
            len +%= 8;
            len +%= target.len;
            len +%= 1;
        }
        if (cmd.cpu) |cpu| {
            len +%= 6;
            len +%= cpu.len;
            len +%= 1;
        }
        if (cmd.code_model) |code_model| {
            len +%= 9;
            len +%= @tagName(code_model).len;
            len +%= 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                len +%= 11;
            } else {
                len +%= 14;
            }
        }
        if (cmd.implicit_builtins) |implicit_builtins| {
            if (implicit_builtins) {
                len +%= 10;
            } else {
                len +%= 13;
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                len +%= 21;
            } else {
                len +%= 24;
            }
        }
        if (cmd.exec_model) |exec_model| {
            len +%= 13;
            len +%= exec_model.len;
            len +%= 1;
        }
        if (cmd.name) |name| {
            len +%= 7;
            len +%= name.len;
            len +%= 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    len +%= 9;
                    len +%= arg.len;
                    len +%= 1;
                },
                .no => {
                    len +%= 12;
                },
            }
        }
        if (cmd.mode) |mode| {
            len +%= 3;
            len +%= @tagName(mode).len;
            len +%= 1;
        }
        if (cmd.passes) |passes| {
            len +%= 19;
            len +%= fmt.Type.Ud64.formatLength(.{ .value = passes });
            len +%= 1;
        }
        if (cmd.main_pkg_path) |main_pkg_path| {
            len +%= 16;
            len +%= main_pkg_path.len;
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
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                len +%= 18;
            } else {
                len +%= 21;
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
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                len +%= 16;
            } else {
                len +%= 19;
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                len +%= 18;
            } else {
                len +%= 21;
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                len +%= 16;
            } else {
                len +%= 19;
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
        if (cmd.format) |format| {
            len +%= 6;
            len +%= @tagName(format).len;
            len +%= 1;
        }
        if (cmd.dirafter) |dirafter| {
            len +%= 11;
            len +%= dirafter.len;
            len +%= 1;
        }
        if (cmd.system) |system| {
            len +%= 9;
            len +%= system.len;
            len +%= 1;
        }
        if (cmd.libc) |libc| {
            len +%= 7;
            len +%= libc.len;
            len +%= 1;
        }
        if (cmd.library) |library| {
            len +%= 10;
            len +%= library.len;
            len +%= 1;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                len +%= 3;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                len +%= 17;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                len +%= 20;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.link_script) |link_script| {
            len +%= 9;
            len +%= link_script.len;
            len +%= 1;
        }
        if (cmd.version_script) |version_script| {
            len +%= 17;
            len +%= version_script.len;
            len +%= 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            len +%= 17;
            len +%= dynamic_linker.len;
            len +%= 1;
        }
        if (cmd.sysroot) |sysroot| {
            len +%= 10;
            len +%= sysroot.len;
            len +%= 1;
        }
        if (cmd.entry) |entry| {
            len +%= 8;
            len +%= entry.len;
            len +%= 1;
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
        if (cmd.rpath) |rpath| {
            len +%= 7;
            len +%= rpath.len;
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
            len +%= 11;
            len +%= @tagName(build_id).len;
            len +%= 1;
        }
        if (cmd.eh_frame_hdr) {
            len +%= 15;
        }
        if (cmd.emit_relocs) {
            len +%= 14;
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                len +%= 14;
            } else {
                len +%= 17;
            }
        }
        if (cmd.stack) |stack| {
            len +%= 8;
            len +%= fmt.Type.Ud64.formatLength(.{ .value = stack });
            len +%= 1;
        }
        if (cmd.image_base) |image_base| {
            len +%= 13;
            len +%= fmt.Type.Ud64.formatLength(.{ .value = image_base });
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            for (macros) |value| {
                len +%= value.formatLength();
            }
        }
        if (cmd.modules) |modules| {
            for (modules) |value| {
                len +%= value.formatLength();
            }
        }
        if (cmd.dependencies) |dependencies| {
            len +%= types.ModuleDependencies.formatLength(.{ .value = dependencies });
        }
        if (cmd.cflags) |cflags| {
            len +%= types.CFlags.formatLength(.{ .value = cflags });
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
        if (cmd.lflags) |lflags| {
            for (lflags) |value| {
                len +%= 3;
                len +%= @tagName(value).len;
                len +%= 1;
            }
        }
        for (files) |value| {
            len +%= value.formatLength();
        }
        if (cmd.color) |color| {
            len +%= 8;
            len +%= @tagName(color).len;
            len +%= 1;
        }
        if (cmd.time_report) {
            len +%= 14;
        }
        if (cmd.stack_report) {
            len +%= 15;
        }
        if (cmd.verbose_link) {
            len +%= 15;
        }
        if (cmd.verbose_cc) {
            len +%= 13;
        }
        if (cmd.verbose_air) {
            len +%= 14;
        }
        if (cmd.verbose_mir) {
            len +%= 14;
        }
        if (cmd.verbose_llvm_ir) {
            len +%= 18;
        }
        if (cmd.verbose_cimport) {
            len +%= 18;
        }
        if (cmd.verbose_llvm_cpu_features) {
            len +%= 28;
        }
        if (cmd.debug_log) |debug_log| {
            len +%= 12;
            len +%= debug_log.len;
            len +%= 1;
        }
        if (cmd.debug_compiler_errors) {
            len +%= 23;
        }
        if (cmd.debug_link_snapshot) {
            len +%= 22;
        }
        return len;
    }
    pub fn formatWrite(cmd: *types.BuildCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(zig_exe);
        array.writeOne(0);
        array.writeMany("build-");
        array.writeMany(@tagName(cmd.kind));
        array.writeOne(0);
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-bin\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-asm\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-llvm-ir\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-llvm-bc\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-h\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-docs\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-analysis\x3d");
                        array.writeFormat(arg);
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
                .yes => |yes| {
                    if (yes) |arg| {
                        array.writeMany("-femit-implib\x3d");
                        array.writeFormat(arg);
                    } else {
                        array.writeMany("-femit-implib\x00");
                    }
                },
                .no => {
                    array.writeMany("-fno-emit-implib\x00");
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            array.writeMany("--cache-dir\x00");
            array.writeMany(cache_root);
            array.writeOne(0);
        }
        if (cmd.global_cache_root) |global_cache_root| {
            array.writeMany("--global-cache-dir\x00");
            array.writeMany(global_cache_root);
            array.writeOne(0);
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            array.writeMany("--zig-lib-dir\x00");
            array.writeMany(zig_lib_root);
            array.writeOne(0);
        }
        if (cmd.listen) |listen| {
            array.writeMany("--listen\x00");
            array.writeMany(@tagName(listen));
            array.writeOne(0);
        }
        if (cmd.target) |target| {
            array.writeMany("-target\x00");
            array.writeMany(target);
            array.writeOne(0);
        }
        if (cmd.cpu) |cpu| {
            array.writeMany("-mcpu\x00");
            array.writeMany(cpu);
            array.writeOne(0);
        }
        if (cmd.code_model) |code_model| {
            array.writeMany("-mcmodel\x00");
            array.writeMany(@tagName(code_model));
            array.writeOne(0);
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                array.writeMany("-mred-zone\x00");
            } else {
                array.writeMany("-mno-red-zone\x00");
            }
        }
        if (cmd.implicit_builtins) |implicit_builtins| {
            if (implicit_builtins) {
                array.writeMany("-fbuiltin\x00");
            } else {
                array.writeMany("-fno-builtin\x00");
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                array.writeMany("-fomit-frame-pointer\x00");
            } else {
                array.writeMany("-fno-omit-frame-pointer\x00");
            }
        }
        if (cmd.exec_model) |exec_model| {
            array.writeMany("-mexec-model\x00");
            array.writeMany(exec_model);
            array.writeOne(0);
        }
        if (cmd.name) |name| {
            array.writeMany("--name\x00");
            array.writeMany(name);
            array.writeOne(0);
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    array.writeMany("-fsoname\x00");
                    array.writeMany(arg);
                    array.writeOne(0);
                },
                .no => {
                    array.writeMany("-fno-soname\x00");
                },
            }
        }
        if (cmd.mode) |mode| {
            array.writeMany("-O\x00");
            array.writeMany(@tagName(mode));
            array.writeOne(0);
        }
        if (cmd.passes) |passes| {
            array.writeMany("-fopt-bisect-limit\x3d");
            array.writeFormat(fmt.ud64(passes));
            array.writeOne(0);
        }
        if (cmd.main_pkg_path) |main_pkg_path| {
            array.writeMany("--main-pkg-path\x00");
            array.writeMany(main_pkg_path);
            array.writeOne(0);
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
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                array.writeMany("-fstack-protector\x00");
            } else {
                array.writeMany("-fno-stack-protector\x00");
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
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                array.writeMany("-funwind-tables\x00");
            } else {
                array.writeMany("-fno-unwind-tables\x00");
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                array.writeMany("-freference-trace\x00");
            } else {
                array.writeMany("-fno-reference-trace\x00");
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                array.writeMany("-ferror-tracing\x00");
            } else {
                array.writeMany("-fno-error-tracing\x00");
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
        if (cmd.format) |format| {
            array.writeMany("-ofmt\x3d");
            array.writeMany(@tagName(format));
            array.writeOne(0);
        }
        if (cmd.dirafter) |dirafter| {
            array.writeMany("-idirafter\x00");
            array.writeMany(dirafter);
            array.writeOne(0);
        }
        if (cmd.system) |system| {
            array.writeMany("-isystem\x00");
            array.writeMany(system);
            array.writeOne(0);
        }
        if (cmd.libc) |libc| {
            array.writeMany("--libc\x00");
            array.writeMany(libc);
            array.writeOne(0);
        }
        if (cmd.library) |library| {
            array.writeMany("--library\x00");
            array.writeMany(library);
            array.writeOne(0);
        }
        if (cmd.include) |include| {
            for (include) |value| {
                array.writeMany("-I\x00");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                array.writeMany("--needed-library\x00");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                array.writeMany("--library-directory\x00");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.link_script) |link_script| {
            array.writeMany("--script\x00");
            array.writeMany(link_script);
            array.writeOne(0);
        }
        if (cmd.version_script) |version_script| {
            array.writeMany("--version-script\x00");
            array.writeMany(version_script);
            array.writeOne(0);
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            array.writeMany("--dynamic-linker\x00");
            array.writeMany(dynamic_linker);
            array.writeOne(0);
        }
        if (cmd.sysroot) |sysroot| {
            array.writeMany("--sysroot\x00");
            array.writeMany(sysroot);
            array.writeOne(0);
        }
        if (cmd.entry) |entry| {
            array.writeMany("--entry\x00");
            array.writeMany(entry);
            array.writeOne(0);
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
        if (cmd.rpath) |rpath| {
            array.writeMany("-rpath\x00");
            array.writeMany(rpath);
            array.writeOne(0);
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
            array.writeMany("--build-id\x3d");
            array.writeMany(@tagName(build_id));
            array.writeOne(0);
        }
        if (cmd.eh_frame_hdr) {
            array.writeMany("--eh-frame-hdr\x00");
        }
        if (cmd.emit_relocs) {
            array.writeMany("--emit-relocs\x00");
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                array.writeMany("--gc-sections\x00");
            } else {
                array.writeMany("--no-gc-sections\x00");
            }
        }
        if (cmd.stack) |stack| {
            array.writeMany("--stack\x00");
            array.writeFormat(fmt.ud64(stack));
            array.writeOne(0);
        }
        if (cmd.image_base) |image_base| {
            array.writeMany("--image-base\x00");
            array.writeFormat(fmt.ud64(image_base));
            array.writeOne(0);
        }
        if (cmd.macros) |macros| {
            for (macros) |value| {
                array.writeFormat(value);
            }
        }
        if (cmd.modules) |modules| {
            for (modules) |value| {
                array.writeFormat(value);
            }
        }
        if (cmd.dependencies) |dependencies| {
            array.writeFormat(types.ModuleDependencies{ .value = dependencies });
        }
        if (cmd.cflags) |cflags| {
            array.writeFormat(types.CFlags{ .value = cflags });
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
        if (cmd.lflags) |lflags| {
            for (lflags) |value| {
                array.writeMany("-z\x00");
                array.writeMany(@tagName(value));
                array.writeOne(0);
            }
        }
        for (files) |value| {
            array.writeFormat(value);
        }
        if (cmd.color) |color| {
            array.writeMany("--color\x00");
            array.writeMany(@tagName(color));
            array.writeOne(0);
        }
        if (cmd.time_report) {
            array.writeMany("-ftime-report\x00");
        }
        if (cmd.stack_report) {
            array.writeMany("-fstack-report\x00");
        }
        if (cmd.verbose_link) {
            array.writeMany("--verbose-link\x00");
        }
        if (cmd.verbose_cc) {
            array.writeMany("--verbose-cc\x00");
        }
        if (cmd.verbose_air) {
            array.writeMany("--verbose-air\x00");
        }
        if (cmd.verbose_mir) {
            array.writeMany("--verbose-mir\x00");
        }
        if (cmd.verbose_llvm_ir) {
            array.writeMany("--verbose-llvm-ir\x00");
        }
        if (cmd.verbose_cimport) {
            array.writeMany("--verbose-cimport\x00");
        }
        if (cmd.verbose_llvm_cpu_features) {
            array.writeMany("--verbose-llvm-cpu-features\x00");
        }
        if (cmd.debug_log) |debug_log| {
            array.writeMany("--debug-log\x00");
            array.writeMany(debug_log);
            array.writeOne(0);
        }
        if (cmd.debug_compiler_errors) {
            array.writeMany("--debug-compile-errors\x00");
        }
        if (cmd.debug_link_snapshot) {
            array.writeMany("--debug-link-snapshot\x00");
        }
    }
    pub fn formatParseArgs(cmd: *types.BuildCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("-femit-bin", arg[0..10])) {
                if (arg.len > 11 and arg[10] == '=') {
                    cmd.emit_bin = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[11..],
                    ) };
                } else {
                    cmd.emit_bin = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-bin", arg)) {
                cmd.emit_bin = .no;
            } else if (mem.testEqualString("-femit-asm", arg[0..10])) {
                if (arg.len > 11 and arg[10] == '=') {
                    cmd.emit_asm = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[11..],
                    ) };
                } else {
                    cmd.emit_asm = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-asm", arg)) {
                cmd.emit_asm = .no;
            } else if (mem.testEqualString("-femit-llvm-ir", arg[0..14])) {
                if (arg.len > 15 and arg[14] == '=') {
                    cmd.emit_llvm_ir = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[15..],
                    ) };
                } else {
                    cmd.emit_llvm_ir = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-llvm-ir", arg)) {
                cmd.emit_llvm_ir = .no;
            } else if (mem.testEqualString("-femit-llvm-bc", arg[0..14])) {
                if (arg.len > 15 and arg[14] == '=') {
                    cmd.emit_llvm_bc = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[15..],
                    ) };
                } else {
                    cmd.emit_llvm_bc = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-llvm-bc", arg)) {
                cmd.emit_llvm_bc = .no;
            } else if (mem.testEqualString("-femit-h", arg[0..8])) {
                if (arg.len > 9 and arg[8] == '=') {
                    cmd.emit_h = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[9..],
                    ) };
                } else {
                    cmd.emit_h = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-h", arg)) {
                cmd.emit_h = .no;
            } else if (mem.testEqualString("-femit-docs", arg[0..11])) {
                if (arg.len > 12 and arg[11] == '=') {
                    cmd.emit_docs = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[12..],
                    ) };
                } else {
                    cmd.emit_docs = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-docs", arg)) {
                cmd.emit_docs = .no;
            } else if (mem.testEqualString("-femit-analysis", arg[0..15])) {
                if (arg.len > 16 and arg[15] == '=') {
                    cmd.emit_analysis = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[16..],
                    ) };
                } else {
                    cmd.emit_analysis = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-analysis", arg)) {
                cmd.emit_analysis = .no;
            } else if (mem.testEqualString("-femit-implib", arg[0..13])) {
                if (arg.len > 14 and arg[13] == '=') {
                    cmd.emit_implib = .{ .yes = types.Path.formatParseArgs(
                        allocator,
                        args,
                        &args_idx,
                        arg[14..],
                    ) };
                } else {
                    cmd.emit_implib = .{ .yes = null };
                }
            } else if (mem.testEqualString("-fno-emit-implib", arg)) {
                cmd.emit_implib = .no;
            } else if (mem.testEqualString("--cache-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.cache_root = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--global-cache-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.global_cache_root = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--zig-lib-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.zig_lib_root = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--listen", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("none", arg)) {
                    cmd.listen = .none;
                } else if (mem.testEqualString("-", arg)) {
                    cmd.listen = .@"-";
                } else if (mem.testEqualString("ipv4", arg)) {
                    cmd.listen = .ipv4;
                }
            } else if (mem.testEqualString("-target", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.target = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-mcpu", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.cpu = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-mcmodel", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("default", arg)) {
                    cmd.code_model = .default;
                } else if (mem.testEqualString("tiny", arg)) {
                    cmd.code_model = .tiny;
                } else if (mem.testEqualString("small", arg)) {
                    cmd.code_model = .small;
                } else if (mem.testEqualString("kernel", arg)) {
                    cmd.code_model = .kernel;
                } else if (mem.testEqualString("medium", arg)) {
                    cmd.code_model = .medium;
                } else if (mem.testEqualString("large", arg)) {
                    cmd.code_model = .large;
                }
            } else if (mem.testEqualString("-mred-zone", arg)) {
                cmd.red_zone = true;
            } else if (mem.testEqualString("-mno-red-zone", arg)) {
                cmd.red_zone = false;
            } else if (mem.testEqualString("-fbuiltin", arg)) {
                cmd.implicit_builtins = true;
            } else if (mem.testEqualString("-fno-builtin", arg)) {
                cmd.implicit_builtins = false;
            } else if (mem.testEqualString("-fomit-frame-pointer", arg)) {
                cmd.omit_frame_pointer = true;
            } else if (mem.testEqualString("-fno-omit-frame-pointer", arg)) {
                cmd.omit_frame_pointer = false;
            } else if (mem.testEqualString("-mexec-model", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.exec_model = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--name", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.name = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-fsoname", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                cmd.soname = .{ .yes = arg };
            } else if (mem.testEqualString("-fno-soname", arg)) {
                cmd.soname = .no;
            } else if (mem.testEqualString("-O", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (mem.testEqualString("Debug", arg)) {
                    cmd.mode = .Debug;
                } else if (mem.testEqualString("ReleaseSafe", arg)) {
                    cmd.mode = .ReleaseSafe;
                } else if (mem.testEqualString("ReleaseFast", arg)) {
                    cmd.mode = .ReleaseFast;
                } else if (mem.testEqualString("ReleaseSmall", arg)) {
                    cmd.mode = .ReleaseSmall;
                }
            } else if (mem.testEqualString("-fopt-bisect-limit", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.passes = parse.ud(usize, mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("--main-pkg-path", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.main_pkg_path = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-fPIC", arg)) {
                cmd.pic = true;
            } else if (mem.testEqualString("-fno-PIC", arg)) {
                cmd.pic = false;
            } else if (mem.testEqualString("-fPIE", arg)) {
                cmd.pie = true;
            } else if (mem.testEqualString("-fno-PIE", arg)) {
                cmd.pie = false;
            } else if (mem.testEqualString("-flto", arg)) {
                cmd.lto = true;
            } else if (mem.testEqualString("-fno-lto", arg)) {
                cmd.lto = false;
            } else if (mem.testEqualString("-fstack-check", arg)) {
                cmd.stack_check = true;
            } else if (mem.testEqualString("-fno-stack-check", arg)) {
                cmd.stack_check = false;
            } else if (mem.testEqualString("-fstack-protector", arg)) {
                cmd.stack_protector = true;
            } else if (mem.testEqualString("-fno-stack-protector", arg)) {
                cmd.stack_protector = false;
            } else if (mem.testEqualString("-fsanitize-c", arg)) {
                cmd.sanitize_c = true;
            } else if (mem.testEqualString("-fno-sanitize-c", arg)) {
                cmd.sanitize_c = false;
            } else if (mem.testEqualString("-fvalgrind", arg)) {
                cmd.valgrind = true;
            } else if (mem.testEqualString("-fno-valgrind", arg)) {
                cmd.valgrind = false;
            } else if (mem.testEqualString("-fsanitize-thread", arg)) {
                cmd.sanitize_thread = true;
            } else if (mem.testEqualString("-fno-sanitize-thread", arg)) {
                cmd.sanitize_thread = false;
            } else if (mem.testEqualString("-funwind-tables", arg)) {
                cmd.unwind_tables = true;
            } else if (mem.testEqualString("-fno-unwind-tables", arg)) {
                cmd.unwind_tables = false;
            } else if (mem.testEqualString("-freference-trace", arg)) {
                cmd.reference_trace = true;
            } else if (mem.testEqualString("-fno-reference-trace", arg)) {
                cmd.reference_trace = false;
            } else if (mem.testEqualString("-ferror-tracing", arg)) {
                cmd.error_tracing = true;
            } else if (mem.testEqualString("-fno-error-tracing", arg)) {
                cmd.error_tracing = false;
            } else if (mem.testEqualString("-fsingle-threaded", arg)) {
                cmd.single_threaded = true;
            } else if (mem.testEqualString("-fno-single-threaded", arg)) {
                cmd.single_threaded = false;
            } else if (mem.testEqualString("-ffunction-sections", arg)) {
                cmd.function_sections = true;
            } else if (mem.testEqualString("-fno-function-sections", arg)) {
                cmd.function_sections = false;
            } else if (mem.testEqualString("-fstrip", arg)) {
                cmd.strip = true;
            } else if (mem.testEqualString("-fno-strip", arg)) {
                cmd.strip = false;
            } else if (mem.testEqualString("-fformatted-panics", arg)) {
                cmd.formatted_panics = true;
            } else if (mem.testEqualString("-fno-formatted-panics", arg)) {
                cmd.formatted_panics = false;
            } else if (mem.testEqualString("-ofmt", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("coff", arg)) {
                    cmd.format = .coff;
                } else if (mem.testEqualString("dxcontainer", arg)) {
                    cmd.format = .dxcontainer;
                } else if (mem.testEqualString("elf", arg)) {
                    cmd.format = .elf;
                } else if (mem.testEqualString("macho", arg)) {
                    cmd.format = .macho;
                } else if (mem.testEqualString("spirv", arg)) {
                    cmd.format = .spirv;
                } else if (mem.testEqualString("wasm", arg)) {
                    cmd.format = .wasm;
                } else if (mem.testEqualString("c", arg)) {
                    cmd.format = .c;
                } else if (mem.testEqualString("hex", arg)) {
                    cmd.format = .hex;
                } else if (mem.testEqualString("raw", arg)) {
                    cmd.format = .raw;
                } else if (mem.testEqualString("plan9", arg)) {
                    cmd.format = .plan9;
                } else if (mem.testEqualString("nvptx", arg)) {
                    cmd.format = .nvptx;
                }
            } else if (mem.testEqualString("-idirafter", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.dirafter = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-isystem", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.system = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--libc", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.libc = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--library", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.library = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-I", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (cmd.include) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.include = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.include = dest[0..1];
                }
            } else if (mem.testEqualString("--needed-library", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (cmd.needed_library) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.needed_library = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.needed_library = dest[0..1];
                }
            } else if (mem.testEqualString("--library-directory", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (cmd.library_directory) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.library_directory = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.library_directory = dest[0..1];
                }
            } else if (mem.testEqualString("--script", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.link_script = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--version-script", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.version_script = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--dynamic-linker", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.dynamic_linker = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--sysroot", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.sysroot = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--entry", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.entry = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-fLLD", arg)) {
                cmd.lld = true;
            } else if (mem.testEqualString("-fno-LLD", arg)) {
                cmd.lld = false;
            } else if (mem.testEqualString("-fcompiler-rt", arg)) {
                cmd.compiler_rt = true;
            } else if (mem.testEqualString("-fno-compiler-rt", arg)) {
                cmd.compiler_rt = false;
            } else if (mem.testEqualString("-rpath", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.rpath = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("-feach-lib-rpath", arg)) {
                cmd.each_lib_rpath = true;
            } else if (mem.testEqualString("-fno-each-lib-rpath", arg)) {
                cmd.each_lib_rpath = false;
            } else if (mem.testEqualString("-fallow-shlib-undefined", arg)) {
                cmd.allow_shlib_undefined = true;
            } else if (mem.testEqualString("-fno-allow-shlib-undefined", arg)) {
                cmd.allow_shlib_undefined = false;
            } else if (mem.testEqualString("--build-id", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("fast", arg)) {
                    cmd.build_id = .fast;
                } else if (mem.testEqualString("uuid", arg)) {
                    cmd.build_id = .uuid;
                } else if (mem.testEqualString("sha1", arg)) {
                    cmd.build_id = .sha1;
                } else if (mem.testEqualString("md5", arg)) {
                    cmd.build_id = .md5;
                } else if (mem.testEqualString("none", arg)) {
                    cmd.build_id = .none;
                }
            } else if (mem.testEqualString("--eh-frame-hdr", arg)) {
                cmd.eh_frame_hdr = true;
            } else if (mem.testEqualString("--emit-relocs", arg)) {
                cmd.emit_relocs = true;
            } else if (mem.testEqualString("--gc-sections", arg)) {
                cmd.gc_sections = true;
            } else if (mem.testEqualString("--no-gc-sections", arg)) {
                cmd.gc_sections = false;
            } else if (mem.testEqualString("--stack", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.stack = parse.ud(usize, mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("--image-base", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.image_base = parse.ud(usize, mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("-D", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (cmd.macros) |src| {
                    const dest: [*]types.Macro = @ptrFromInt(allocator.allocateRaw(
                        @sizeOf(types.Macro) *% (src.len +% 1),
                        @alignOf(types.Macro),
                    ));
                    @memcpy(dest, src);
                    dest[src.len] = types.Macro.formatParseArgs(allocator, args, &args_idx, arg);
                    cmd.macros = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*]types.Macro = @ptrFromInt(allocator.allocateRaw(
                        @sizeOf(types.Macro),
                        @alignOf(types.Macro),
                    ));
                    dest[0] = types.Macro.formatParseArgs(allocator, args, &args_idx, arg);
                    cmd.macros = dest[0..1];
                }
            } else if (mem.testEqualString("--mod", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (cmd.modules) |src| {
                    const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(
                        @sizeOf(types.Module) *% (src.len +% 1),
                        @alignOf(types.Module),
                    ));
                    @memcpy(dest, src);
                    dest[src.len] = types.Module.formatParseArgs(allocator, args, &args_idx, arg);
                    cmd.modules = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(
                        @sizeOf(types.Module),
                        @alignOf(types.Module),
                    ));
                    dest[0] = types.Module.formatParseArgs(allocator, args, &args_idx, arg);
                    cmd.modules = dest[0..1];
                }
            } else if (mem.testEqualString("-lc", arg)) {
                cmd.link_libc = true;
            } else if (mem.testEqualString("-rdynamic", arg)) {
                cmd.rdynamic = true;
            } else if (mem.testEqualString("-dynamic", arg)) {
                cmd.dynamic = true;
            } else if (mem.testEqualString("-static", arg)) {
                cmd.static = true;
            } else if (mem.testEqualString("-Bsymbolic", arg)) {
                cmd.symbolic = true;
            } else if (mem.testEqualString("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("auto", arg)) {
                    cmd.color = .auto;
                } else if (mem.testEqualString("off", arg)) {
                    cmd.color = .off;
                } else if (mem.testEqualString("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mem.testEqualString("-ftime-report", arg)) {
                cmd.time_report = true;
            } else if (mem.testEqualString("-fstack-report", arg)) {
                cmd.stack_report = true;
            } else if (mem.testEqualString("--verbose-link", arg)) {
                cmd.verbose_link = true;
            } else if (mem.testEqualString("--verbose-cc", arg)) {
                cmd.verbose_cc = true;
            } else if (mem.testEqualString("--verbose-air", arg)) {
                cmd.verbose_air = true;
            } else if (mem.testEqualString("--verbose-mir", arg)) {
                cmd.verbose_mir = true;
            } else if (mem.testEqualString("--verbose-llvm-ir", arg)) {
                cmd.verbose_llvm_ir = true;
            } else if (mem.testEqualString("--verbose-cimport", arg)) {
                cmd.verbose_cimport = true;
            } else if (mem.testEqualString("--verbose-llvm-cpu-features", arg)) {
                cmd.verbose_llvm_cpu_features = true;
            } else if (mem.testEqualString("--debug-log", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.debug_log = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--debug-compile-errors", arg)) {
                cmd.debug_compiler_errors = true;
            } else if (mem.testEqualString("--debug-link-snapshot", arg)) {
                cmd.debug_link_snapshot = true;
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(build_help);
            }
        }
    }
};
pub const FormatCommand = struct {
    /// Enable or disable colored error messages
    color: ?types.AutoOnOff = null,
    /// Format code from stdin; output to stdout
    stdin: bool = false,
    /// List non-conforming files and exit with an error if the list is non-empty
    check: bool = false,
    /// Run zig ast-check on every file
    ast_check: bool = false,
    /// Exclude file or directory from formatting
    exclude: ?[]const u8 = null,
    pub fn formatWriteBuf(cmd: *types.FormatCommand, zig_exe: []const u8, pathname: types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        @memcpy(ptr, zig_exe);
        ptr += zig_exe.len;
        ptr[0] = 0;
        ptr += 1;
        ptr[0..4].* = "fmt\x00".*;
        ptr += 4;
        if (cmd.color) |color| {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
            @memcpy(ptr, @tagName(color));
            ptr += @tagName(color).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.stdin) {
            ptr[0..8].* = "--stdin\x00".*;
            ptr += 8;
        }
        if (cmd.check) {
            ptr[0..8].* = "--check\x00".*;
            ptr += 8;
        }
        if (cmd.ast_check) {
            ptr[0..12].* = "--ast-check\x00".*;
            ptr += 12;
        }
        if (cmd.exclude) |exclude| {
            ptr[0..10].* = "--exclude\x00".*;
            ptr += 10;
            @memcpy(ptr, exclude);
            ptr += exclude.len;
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += pathname.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.FormatCommand, zig_exe: []const u8, pathname: types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= zig_exe.len;
        len +%= 1;
        len +%= 4;
        if (cmd.color) |color| {
            len +%= 8;
            len +%= @tagName(color).len;
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
        if (cmd.exclude) |exclude| {
            len +%= 10;
            len +%= exclude.len;
            len +%= 1;
        }
        len +%= pathname.formatLength();
        return len;
    }
    pub fn formatWrite(cmd: *types.FormatCommand, zig_exe: []const u8, pathname: types.Path, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(zig_exe);
        array.writeOne(0);
        array.writeMany("fmt\x00");
        if (cmd.color) |color| {
            array.writeMany("--color\x00");
            array.writeMany(@tagName(color));
            array.writeOne(0);
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
        if (cmd.exclude) |exclude| {
            array.writeMany("--exclude\x00");
            array.writeMany(exclude);
            array.writeOne(0);
        }
        array.writeFormat(pathname);
    }
    pub fn formatParseArgs(cmd: *types.FormatCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("auto", arg)) {
                    cmd.color = .auto;
                } else if (mem.testEqualString("off", arg)) {
                    cmd.color = .off;
                } else if (mem.testEqualString("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mem.testEqualString("--stdin", arg)) {
                cmd.stdin = true;
            } else if (mem.testEqualString("--check", arg)) {
                cmd.check = true;
            } else if (mem.testEqualString("--ast-check", arg)) {
                cmd.ast_check = true;
            } else if (mem.testEqualString("--exclude", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.exclude = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(format_help);
            }
            _ = allocator;
        }
    }
};
pub const ArchiveCommand = struct {
    /// Archive format to create
    format: ?enum(u3) {
        default = 0,
        gnu = 1,
        darwin = 2,
        bsd = 3,
        bigarchive = 4,
    } = null,
    /// Ignored for compatibility
    plugin: bool = false,
    /// Extraction target directory
    output: ?[]const u8 = null,
    /// Create a thin archive
    thin: bool = false,
    /// Put [files] after [relpos]
    after: bool = false,
    /// Put [files] before [relpos] (same as [i])
    before: bool = false,
    /// Do not warn if archive had to be created
    create: bool = false,
    /// Use zero for timestamps and uids/gids (default)
    zero_ids: bool = false,
    /// Use actual timestamps and uids/gids
    real_ids: bool = false,
    /// Add archive's contents
    append: bool = false,
    /// Preserve original dates
    preserve_dates: bool = false,
    /// Create an archive index (cf. ranlib)
    index: bool = false,
    /// do not build a symbol table
    no_symbol_table: bool = false,
    /// update only [files] newer than archive contents
    update: bool = false,
    /// d  Delete [files] from the archive
    /// m  Move [files] in the archive
    /// q  Quick append [files] to the archive
    /// r  Replace or insert [files] into the archive
    /// s  Act as ranlib
    /// x  Extract [files] from the archive
    operation: enum(u3) {
        d = 0,
        m = 1,
        q = 2,
        r = 3,
        s = 4,
        x = 5,
    },
    pub fn formatWriteBuf(cmd: *types.ArchiveCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        @memcpy(ptr, zig_exe);
        ptr += zig_exe.len;
        ptr[0] = 0;
        ptr += 1;
        ptr[0..3].* = "ar\x00".*;
        ptr += 3;
        if (cmd.format) |format| {
            ptr[0..9].* = "--format\x00".*;
            ptr += 9;
            @memcpy(ptr, @tagName(format));
            ptr += @tagName(format).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.plugin) {
            ptr[0..9].* = "--plugin\x00".*;
            ptr += 9;
        }
        if (cmd.output) |output| {
            ptr[0..9].* = "--output\x00".*;
            ptr += 9;
            @memcpy(ptr, output);
            ptr += output.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.thin) {
            ptr[0..7].* = "--thin\x00".*;
            ptr += 7;
        }
        if (cmd.after) {
            ptr[0..1].* = "a".*;
            ptr += 1;
        }
        if (cmd.before) {
            ptr[0..1].* = "b".*;
            ptr += 1;
        }
        if (cmd.create) {
            ptr[0..1].* = "c".*;
            ptr += 1;
        }
        if (cmd.zero_ids) {
            ptr[0..1].* = "D".*;
            ptr += 1;
        }
        if (cmd.real_ids) {
            ptr[0..1].* = "U".*;
            ptr += 1;
        }
        if (cmd.append) {
            ptr[0..1].* = "L".*;
            ptr += 1;
        }
        if (cmd.preserve_dates) {
            ptr[0..1].* = "o".*;
            ptr += 1;
        }
        if (cmd.index) {
            ptr[0..1].* = "s".*;
            ptr += 1;
        }
        if (cmd.no_symbol_table) {
            ptr[0..1].* = "S".*;
            ptr += 1;
        }
        if (cmd.update) {
            ptr[0..1].* = "u".*;
            ptr += 1;
        }
        @memcpy(ptr, @tagName(cmd.operation));
        ptr += @tagName(cmd.operation).len;
        ptr[0] = 0;
        ptr += 1;
        for (files) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.ArchiveCommand, zig_exe: []const u8, files: []const types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= zig_exe.len;
        len +%= 1;
        len +%= 3;
        if (cmd.format) |format| {
            len +%= 9;
            len +%= @tagName(format).len;
            len +%= 1;
        }
        if (cmd.plugin) {
            len +%= 9;
        }
        if (cmd.output) |output| {
            len +%= 9;
            len +%= output.len;
            len +%= 1;
        }
        if (cmd.thin) {
            len +%= 7;
        }
        if (cmd.after) {
            len +%= 1;
        }
        if (cmd.before) {
            len +%= 1;
        }
        if (cmd.create) {
            len +%= 1;
        }
        if (cmd.zero_ids) {
            len +%= 1;
        }
        if (cmd.real_ids) {
            len +%= 1;
        }
        if (cmd.append) {
            len +%= 1;
        }
        if (cmd.preserve_dates) {
            len +%= 1;
        }
        if (cmd.index) {
            len +%= 1;
        }
        if (cmd.no_symbol_table) {
            len +%= 1;
        }
        if (cmd.update) {
            len +%= 1;
        }
        len +%= @tagName(cmd.operation).len;
        len +%= 1;
        for (files) |value| {
            len +%= value.formatLength();
        }
        return len;
    }
    pub fn formatWrite(cmd: *types.ArchiveCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(zig_exe);
        array.writeOne(0);
        array.writeMany("ar\x00");
        if (cmd.format) |format| {
            array.writeMany("--format\x00");
            array.writeMany(@tagName(format));
            array.writeOne(0);
        }
        if (cmd.plugin) {
            array.writeMany("--plugin\x00");
        }
        if (cmd.output) |output| {
            array.writeMany("--output\x00");
            array.writeMany(output);
            array.writeOne(0);
        }
        if (cmd.thin) {
            array.writeMany("--thin\x00");
        }
        if (cmd.after) {
            array.writeMany("a");
        }
        if (cmd.before) {
            array.writeMany("b");
        }
        if (cmd.create) {
            array.writeMany("c");
        }
        if (cmd.zero_ids) {
            array.writeMany("D");
        }
        if (cmd.real_ids) {
            array.writeMany("U");
        }
        if (cmd.append) {
            array.writeMany("L");
        }
        if (cmd.preserve_dates) {
            array.writeMany("o");
        }
        if (cmd.index) {
            array.writeMany("s");
        }
        if (cmd.no_symbol_table) {
            array.writeMany("S");
        }
        if (cmd.update) {
            array.writeMany("u");
        }
        array.writeMany(@tagName(cmd.operation));
        array.writeOne(0);
        for (files) |value| {
            array.writeFormat(value);
        }
    }
    pub fn formatParseArgs(cmd: *types.ArchiveCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--format", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("default", arg)) {
                    cmd.format = .default;
                } else if (mem.testEqualString("gnu", arg)) {
                    cmd.format = .gnu;
                } else if (mem.testEqualString("darwin", arg)) {
                    cmd.format = .darwin;
                } else if (mem.testEqualString("bsd", arg)) {
                    cmd.format = .bsd;
                } else if (mem.testEqualString("bigarchive", arg)) {
                    cmd.format = .bigarchive;
                }
            } else if (mem.testEqualString("--plugin", arg)) {
                cmd.plugin = true;
            } else if (mem.testEqualString("--output", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.output = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--thin", arg)) {
                cmd.thin = true;
            } else if (mem.testEqualString("a", arg)) {
                cmd.after = true;
            } else if (mem.testEqualString("b", arg)) {
                cmd.before = true;
            } else if (mem.testEqualString("c", arg)) {
                cmd.create = true;
            } else if (mem.testEqualString("D", arg)) {
                cmd.zero_ids = true;
            } else if (mem.testEqualString("U", arg)) {
                cmd.real_ids = true;
            } else if (mem.testEqualString("L", arg)) {
                cmd.append = true;
            } else if (mem.testEqualString("o", arg)) {
                cmd.preserve_dates = true;
            } else if (mem.testEqualString("s", arg)) {
                cmd.index = true;
            } else if (mem.testEqualString("S", arg)) {
                cmd.no_symbol_table = true;
            } else if (mem.testEqualString("u", arg)) {
                cmd.update = true;
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(archive_help);
            }
            _ = allocator;
        }
    }
};
pub const ObjcopyCommand = struct {
    output_target: ?[]const u8 = null,
    only_section: ?[]const u8 = null,
    pad_to: ?usize = null,
    strip_debug: bool = false,
    strip_all: bool = false,
    debug_only: bool = false,
    add_gnu_debuglink: ?[]const u8 = null,
    extract_to: ?[]const u8 = null,
    pub fn formatWriteBuf(cmd: *types.ObjcopyCommand, zig_exe: []const u8, file: types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        @memcpy(ptr, zig_exe);
        ptr += zig_exe.len;
        ptr[0] = 0;
        ptr += 1;
        ptr[0..8].* = "objcopy\x00".*;
        ptr += 8;
        if (cmd.output_target) |output_target| {
            ptr[0..16].* = "--output-target\x00".*;
            ptr += 16;
            @memcpy(ptr, output_target);
            ptr += output_target.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.only_section) |only_section| {
            ptr[0..15].* = "--only-section\x00".*;
            ptr += 15;
            @memcpy(ptr, only_section);
            ptr += only_section.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.pad_to) |pad_to| {
            ptr[0..9].* = "--pad-to\x00".*;
            ptr += 9;
            ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = pad_to }, ptr);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.strip_debug) {
            ptr[0..14].* = "--strip-debug\x00".*;
            ptr += 14;
        }
        if (cmd.strip_all) {
            ptr[0..12].* = "--strip-all\x00".*;
            ptr += 12;
        }
        if (cmd.debug_only) {
            ptr[0..18].* = "--only-keep-debug\x00".*;
            ptr += 18;
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            ptr[0..20].* = "--add-gnu-debuglink\x00".*;
            ptr += 20;
            @memcpy(ptr, add_gnu_debuglink);
            ptr += add_gnu_debuglink.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.extract_to) |extract_to| {
            ptr[0..13].* = "--extract-to\x00".*;
            ptr += 13;
            @memcpy(ptr, extract_to);
            ptr += extract_to.len;
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += file.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.ObjcopyCommand, zig_exe: []const u8, file: types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= zig_exe.len;
        len +%= 1;
        len +%= 8;
        if (cmd.output_target) |output_target| {
            len +%= 16;
            len +%= output_target.len;
            len +%= 1;
        }
        if (cmd.only_section) |only_section| {
            len +%= 15;
            len +%= only_section.len;
            len +%= 1;
        }
        if (cmd.pad_to) |pad_to| {
            len +%= 9;
            len +%= fmt.Type.Ud64.formatLength(.{ .value = pad_to });
            len +%= 1;
        }
        if (cmd.strip_debug) {
            len +%= 14;
        }
        if (cmd.strip_all) {
            len +%= 12;
        }
        if (cmd.debug_only) {
            len +%= 18;
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            len +%= 20;
            len +%= add_gnu_debuglink.len;
            len +%= 1;
        }
        if (cmd.extract_to) |extract_to| {
            len +%= 13;
            len +%= extract_to.len;
            len +%= 1;
        }
        len +%= file.formatLength();
        return len;
    }
    pub fn formatWrite(cmd: *types.ObjcopyCommand, zig_exe: []const u8, file: types.Path, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(zig_exe);
        array.writeOne(0);
        array.writeMany("objcopy\x00");
        if (cmd.output_target) |output_target| {
            array.writeMany("--output-target\x00");
            array.writeMany(output_target);
            array.writeOne(0);
        }
        if (cmd.only_section) |only_section| {
            array.writeMany("--only-section\x00");
            array.writeMany(only_section);
            array.writeOne(0);
        }
        if (cmd.pad_to) |pad_to| {
            array.writeMany("--pad-to\x00");
            array.writeFormat(fmt.ud64(pad_to));
            array.writeOne(0);
        }
        if (cmd.strip_debug) {
            array.writeMany("--strip-debug\x00");
        }
        if (cmd.strip_all) {
            array.writeMany("--strip-all\x00");
        }
        if (cmd.debug_only) {
            array.writeMany("--only-keep-debug\x00");
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            array.writeMany("--add-gnu-debuglink\x00");
            array.writeMany(add_gnu_debuglink);
            array.writeOne(0);
        }
        if (cmd.extract_to) |extract_to| {
            array.writeMany("--extract-to\x00");
            array.writeMany(extract_to);
            array.writeOne(0);
        }
        array.writeFormat(file);
    }
    pub fn formatParseArgs(cmd: *types.ObjcopyCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--output-target", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.output_target = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--only-section", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.only_section = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--pad-to", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.pad_to = parse.ud(usize, mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("--strip-debug", arg)) {
                cmd.strip_debug = true;
            } else if (mem.testEqualString("--strip-all", arg)) {
                cmd.strip_all = true;
            } else if (mem.testEqualString("--only-keep-debug", arg)) {
                cmd.debug_only = true;
            } else if (mem.testEqualString("--add-gnu-debuglink", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.add_gnu_debuglink = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--extract-to", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.extract_to = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(objcopy_help);
            }
            _ = allocator;
        }
    }
};
pub const TableGenCommand = struct {
    /// Use colors in output (default=autodetect)
    color: ?types.AutoOnOff = null,
    /// Define macros
    macros: ?[]const types.Macro = null,
    /// Add directories to include search path
    include: ?[]const []const u8 = null,
    /// Add file dependencies
    dependencies: ?[]const []const u8 = null,
    /// Print all records to stdout (default)
    print_records: bool = false,
    /// Print full details of all records to stdout
    print_detailed_records: bool = false,
    /// Do nothing after parsing (useful for timing)
    null_backend: bool = false,
    /// Dump all records as machine-readable JSON
    dump_json: bool = false,
    /// Generate machine code emitter
    gen_emitter: bool = false,
    /// Generate registers and register classes info
    gen_register_info: bool = false,
    /// Generate instruction descriptions
    gen_instr_info: bool = false,
    /// Generate instruction documentation
    gen_instr_docs: bool = false,
    /// Generate calling convention descriptions
    gen_callingconv: bool = false,
    /// Generate assembly writer
    gen_asm_writer: bool = false,
    /// Generate disassembler
    gen_disassembler: bool = false,
    /// Generate pseudo instruction lowering
    gen_pseudo_lowering: bool = false,
    /// Generate RISCV compressed instructions.
    gen_compress_inst_emitter: bool = false,
    /// Generate assembly instruction matcher
    gen_asm_matcher: bool = false,
    /// Generate a DAG instruction selector
    gen_dag_isel: bool = false,
    /// Generate DFA Packetizer for VLIW targets
    gen_dfa_packetizer: bool = false,
    /// Generate a "fast" instruction selector
    gen_fast_isel: bool = false,
    /// Generate subtarget enumerations
    gen_subtarget: bool = false,
    /// Generate intrinsic enums
    gen_intrinsic_enums: bool = false,
    /// Generate intrinsic information
    gen_intrinsic_impl: bool = false,
    /// Print enum values for a class
    print_enums: bool = false,
    /// Print expanded sets for testing DAG exprs
    print_sets: bool = false,
    /// Generate option definitions
    gen_opt_parser_defs: bool = false,
    /// Generate option RST
    gen_opt_rst: bool = false,
    /// Generate ctags-compatible index
    gen_ctags: bool = false,
    /// Generate attributes
    gen_attrs: bool = false,
    /// Generate generic binary-searchable table
    gen_searchable_tables: bool = false,
    /// Generate GlobalISel selector
    gen_global_isel: bool = false,
    /// Generate GlobalISel combiner
    gen_global_isel_combiner: bool = false,
    /// Generate X86 EVEX to VEX compress tables
    gen_x86_EVEX2VEX_tables: bool = false,
    /// Generate X86 fold tables
    gen_x86_fold_tables: bool = false,
    /// Generate X86 mnemonic tables
    gen_x86_mnemonic_tables: bool = false,
    /// Generate registers bank descriptions
    gen_register_bank: bool = false,
    /// Generate llvm-exegesis tables
    gen_exegesis: bool = false,
    /// Generate generic automata
    gen_automata: bool = false,
    /// Generate directive related declaration code (header file)
    gen_directive_decl: bool = false,
    /// Generate directive related implementation code
    gen_directive_impl: bool = false,
    /// Generate DXIL operation information
    gen_dxil_operation: bool = false,
    /// Generate the list of CPU for RISCV
    gen_riscv_target_def: bool = false,
    /// Output file
    output: ?[]const u8 = null,
    pub fn formatWriteBuf(cmd: *types.TableGenCommand, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        if (cmd.color) |color| {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
            @memcpy(ptr, @tagName(color));
            ptr += @tagName(color).len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.macros) |macros| {
            ptr += types.Macros.formatWriteBuf(.{ .value = macros }, ptr);
        }
        if (cmd.include) |include| {
            for (include) |value| {
                ptr[0..2].* = "-I".*;
                ptr += 2;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                ptr[0..3].* = "-d\x00".*;
                ptr += 3;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.print_records) {
            ptr[0..16].* = "--print-records\x00".*;
            ptr += 16;
        }
        if (cmd.print_detailed_records) {
            ptr[0..25].* = "--print-detailed-records\x00".*;
            ptr += 25;
        }
        if (cmd.null_backend) {
            ptr[0..15].* = "--null-backend\x00".*;
            ptr += 15;
        }
        if (cmd.dump_json) {
            ptr[0..12].* = "--dump-json\x00".*;
            ptr += 12;
        }
        if (cmd.gen_emitter) {
            ptr[0..14].* = "--gen-emitter\x00".*;
            ptr += 14;
        }
        if (cmd.gen_register_info) {
            ptr[0..20].* = "--gen-register-info\x00".*;
            ptr += 20;
        }
        if (cmd.gen_instr_info) {
            ptr[0..17].* = "--gen-instr-info\x00".*;
            ptr += 17;
        }
        if (cmd.gen_instr_docs) {
            ptr[0..17].* = "--gen-instr-docs\x00".*;
            ptr += 17;
        }
        if (cmd.gen_callingconv) {
            ptr[0..18].* = "--gen-callingconv\x00".*;
            ptr += 18;
        }
        if (cmd.gen_asm_writer) {
            ptr[0..17].* = "--gen-asm-writer\x00".*;
            ptr += 17;
        }
        if (cmd.gen_disassembler) {
            ptr[0..19].* = "--gen-disassembler\x00".*;
            ptr += 19;
        }
        if (cmd.gen_pseudo_lowering) {
            ptr[0..22].* = "--gen-pseudo-lowering\x00".*;
            ptr += 22;
        }
        if (cmd.gen_compress_inst_emitter) {
            ptr[0..28].* = "--gen-compress-inst-emitter\x00".*;
            ptr += 28;
        }
        if (cmd.gen_asm_matcher) {
            ptr[0..18].* = "--gen-asm-matcher\x00".*;
            ptr += 18;
        }
        if (cmd.gen_dag_isel) {
            ptr[0..15].* = "--gen-dag-isel\x00".*;
            ptr += 15;
        }
        if (cmd.gen_dfa_packetizer) {
            ptr[0..21].* = "--gen-dfa-packetizer\x00".*;
            ptr += 21;
        }
        if (cmd.gen_fast_isel) {
            ptr[0..16].* = "--gen-fast-isel\x00".*;
            ptr += 16;
        }
        if (cmd.gen_subtarget) {
            ptr[0..16].* = "--gen-subtarget\x00".*;
            ptr += 16;
        }
        if (cmd.gen_intrinsic_enums) {
            ptr[0..22].* = "--gen-intrinsic-enums\x00".*;
            ptr += 22;
        }
        if (cmd.gen_intrinsic_impl) {
            ptr[0..21].* = "--gen-intrinsic-impl\x00".*;
            ptr += 21;
        }
        if (cmd.print_enums) {
            ptr[0..14].* = "--print-enums\x00".*;
            ptr += 14;
        }
        if (cmd.print_sets) {
            ptr[0..13].* = "--print-sets\x00".*;
            ptr += 13;
        }
        if (cmd.gen_opt_parser_defs) {
            ptr[0..22].* = "--gen-opt-parser-defs\x00".*;
            ptr += 22;
        }
        if (cmd.gen_opt_rst) {
            ptr[0..14].* = "--gen-opt-rst\x00".*;
            ptr += 14;
        }
        if (cmd.gen_ctags) {
            ptr[0..12].* = "--gen-ctags\x00".*;
            ptr += 12;
        }
        if (cmd.gen_attrs) {
            ptr[0..12].* = "--gen-attrs\x00".*;
            ptr += 12;
        }
        if (cmd.gen_searchable_tables) {
            ptr[0..24].* = "--gen-searchable-tables\x00".*;
            ptr += 24;
        }
        if (cmd.gen_global_isel) {
            ptr[0..18].* = "--gen-global-isel\x00".*;
            ptr += 18;
        }
        if (cmd.gen_global_isel_combiner) {
            ptr[0..27].* = "--gen-global-isel-combiner\x00".*;
            ptr += 27;
        }
        if (cmd.gen_x86_EVEX2VEX_tables) {
            ptr[0..26].* = "--gen-x86-EVEX2VEX-tables\x00".*;
            ptr += 26;
        }
        if (cmd.gen_x86_fold_tables) {
            ptr[0..22].* = "--gen-x86-fold-tables\x00".*;
            ptr += 22;
        }
        if (cmd.gen_x86_mnemonic_tables) {
            ptr[0..26].* = "--gen-x86-mnemonic-tables\x00".*;
            ptr += 26;
        }
        if (cmd.gen_register_bank) {
            ptr[0..20].* = "--gen-register-bank\x00".*;
            ptr += 20;
        }
        if (cmd.gen_exegesis) {
            ptr[0..15].* = "--gen-exegesis\x00".*;
            ptr += 15;
        }
        if (cmd.gen_automata) {
            ptr[0..15].* = "--gen-automata\x00".*;
            ptr += 15;
        }
        if (cmd.gen_directive_decl) {
            ptr[0..21].* = "--gen-directive-decl\x00".*;
            ptr += 21;
        }
        if (cmd.gen_directive_impl) {
            ptr[0..21].* = "--gen-directive-impl\x00".*;
            ptr += 21;
        }
        if (cmd.gen_dxil_operation) {
            ptr[0..21].* = "--gen-dxil-operation\x00".*;
            ptr += 21;
        }
        if (cmd.gen_riscv_target_def) {
            ptr[0..23].* = "--gen-riscv-target_def\x00".*;
            ptr += 23;
        }
        if (cmd.output) |output| {
            ptr[0..3].* = "-o\x00".*;
            ptr += 3;
            @memcpy(ptr, output);
            ptr += output.len;
            ptr[0] = 0;
            ptr += 1;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.TableGenCommand) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        if (cmd.color) |color| {
            len +%= 8;
            len +%= @tagName(color).len;
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            len +%= types.Macros.formatLength(.{ .value = macros });
        }
        if (cmd.include) |include| {
            for (include) |value| {
                len +%= 2;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                len +%= 3;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.print_records) {
            len +%= 16;
        }
        if (cmd.print_detailed_records) {
            len +%= 25;
        }
        if (cmd.null_backend) {
            len +%= 15;
        }
        if (cmd.dump_json) {
            len +%= 12;
        }
        if (cmd.gen_emitter) {
            len +%= 14;
        }
        if (cmd.gen_register_info) {
            len +%= 20;
        }
        if (cmd.gen_instr_info) {
            len +%= 17;
        }
        if (cmd.gen_instr_docs) {
            len +%= 17;
        }
        if (cmd.gen_callingconv) {
            len +%= 18;
        }
        if (cmd.gen_asm_writer) {
            len +%= 17;
        }
        if (cmd.gen_disassembler) {
            len +%= 19;
        }
        if (cmd.gen_pseudo_lowering) {
            len +%= 22;
        }
        if (cmd.gen_compress_inst_emitter) {
            len +%= 28;
        }
        if (cmd.gen_asm_matcher) {
            len +%= 18;
        }
        if (cmd.gen_dag_isel) {
            len +%= 15;
        }
        if (cmd.gen_dfa_packetizer) {
            len +%= 21;
        }
        if (cmd.gen_fast_isel) {
            len +%= 16;
        }
        if (cmd.gen_subtarget) {
            len +%= 16;
        }
        if (cmd.gen_intrinsic_enums) {
            len +%= 22;
        }
        if (cmd.gen_intrinsic_impl) {
            len +%= 21;
        }
        if (cmd.print_enums) {
            len +%= 14;
        }
        if (cmd.print_sets) {
            len +%= 13;
        }
        if (cmd.gen_opt_parser_defs) {
            len +%= 22;
        }
        if (cmd.gen_opt_rst) {
            len +%= 14;
        }
        if (cmd.gen_ctags) {
            len +%= 12;
        }
        if (cmd.gen_attrs) {
            len +%= 12;
        }
        if (cmd.gen_searchable_tables) {
            len +%= 24;
        }
        if (cmd.gen_global_isel) {
            len +%= 18;
        }
        if (cmd.gen_global_isel_combiner) {
            len +%= 27;
        }
        if (cmd.gen_x86_EVEX2VEX_tables) {
            len +%= 26;
        }
        if (cmd.gen_x86_fold_tables) {
            len +%= 22;
        }
        if (cmd.gen_x86_mnemonic_tables) {
            len +%= 26;
        }
        if (cmd.gen_register_bank) {
            len +%= 20;
        }
        if (cmd.gen_exegesis) {
            len +%= 15;
        }
        if (cmd.gen_automata) {
            len +%= 15;
        }
        if (cmd.gen_directive_decl) {
            len +%= 21;
        }
        if (cmd.gen_directive_impl) {
            len +%= 21;
        }
        if (cmd.gen_dxil_operation) {
            len +%= 21;
        }
        if (cmd.gen_riscv_target_def) {
            len +%= 23;
        }
        if (cmd.output) |output| {
            len +%= 3;
            len +%= output.len;
            len +%= 1;
        }
        return len;
    }
    pub fn formatWrite(cmd: *types.TableGenCommand, array: anytype) void {
        @setRuntimeSafety(false);
        if (cmd.color) |color| {
            array.writeMany("--color\x00");
            array.writeMany(@tagName(color));
            array.writeOne(0);
        }
        if (cmd.macros) |macros| {
            array.writeFormat(types.Macros{ .value = macros });
        }
        if (cmd.include) |include| {
            for (include) |value| {
                array.writeMany("-I");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                array.writeMany("-d\x00");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.print_records) {
            array.writeMany("--print-records\x00");
        }
        if (cmd.print_detailed_records) {
            array.writeMany("--print-detailed-records\x00");
        }
        if (cmd.null_backend) {
            array.writeMany("--null-backend\x00");
        }
        if (cmd.dump_json) {
            array.writeMany("--dump-json\x00");
        }
        if (cmd.gen_emitter) {
            array.writeMany("--gen-emitter\x00");
        }
        if (cmd.gen_register_info) {
            array.writeMany("--gen-register-info\x00");
        }
        if (cmd.gen_instr_info) {
            array.writeMany("--gen-instr-info\x00");
        }
        if (cmd.gen_instr_docs) {
            array.writeMany("--gen-instr-docs\x00");
        }
        if (cmd.gen_callingconv) {
            array.writeMany("--gen-callingconv\x00");
        }
        if (cmd.gen_asm_writer) {
            array.writeMany("--gen-asm-writer\x00");
        }
        if (cmd.gen_disassembler) {
            array.writeMany("--gen-disassembler\x00");
        }
        if (cmd.gen_pseudo_lowering) {
            array.writeMany("--gen-pseudo-lowering\x00");
        }
        if (cmd.gen_compress_inst_emitter) {
            array.writeMany("--gen-compress-inst-emitter\x00");
        }
        if (cmd.gen_asm_matcher) {
            array.writeMany("--gen-asm-matcher\x00");
        }
        if (cmd.gen_dag_isel) {
            array.writeMany("--gen-dag-isel\x00");
        }
        if (cmd.gen_dfa_packetizer) {
            array.writeMany("--gen-dfa-packetizer\x00");
        }
        if (cmd.gen_fast_isel) {
            array.writeMany("--gen-fast-isel\x00");
        }
        if (cmd.gen_subtarget) {
            array.writeMany("--gen-subtarget\x00");
        }
        if (cmd.gen_intrinsic_enums) {
            array.writeMany("--gen-intrinsic-enums\x00");
        }
        if (cmd.gen_intrinsic_impl) {
            array.writeMany("--gen-intrinsic-impl\x00");
        }
        if (cmd.print_enums) {
            array.writeMany("--print-enums\x00");
        }
        if (cmd.print_sets) {
            array.writeMany("--print-sets\x00");
        }
        if (cmd.gen_opt_parser_defs) {
            array.writeMany("--gen-opt-parser-defs\x00");
        }
        if (cmd.gen_opt_rst) {
            array.writeMany("--gen-opt-rst\x00");
        }
        if (cmd.gen_ctags) {
            array.writeMany("--gen-ctags\x00");
        }
        if (cmd.gen_attrs) {
            array.writeMany("--gen-attrs\x00");
        }
        if (cmd.gen_searchable_tables) {
            array.writeMany("--gen-searchable-tables\x00");
        }
        if (cmd.gen_global_isel) {
            array.writeMany("--gen-global-isel\x00");
        }
        if (cmd.gen_global_isel_combiner) {
            array.writeMany("--gen-global-isel-combiner\x00");
        }
        if (cmd.gen_x86_EVEX2VEX_tables) {
            array.writeMany("--gen-x86-EVEX2VEX-tables\x00");
        }
        if (cmd.gen_x86_fold_tables) {
            array.writeMany("--gen-x86-fold-tables\x00");
        }
        if (cmd.gen_x86_mnemonic_tables) {
            array.writeMany("--gen-x86-mnemonic-tables\x00");
        }
        if (cmd.gen_register_bank) {
            array.writeMany("--gen-register-bank\x00");
        }
        if (cmd.gen_exegesis) {
            array.writeMany("--gen-exegesis\x00");
        }
        if (cmd.gen_automata) {
            array.writeMany("--gen-automata\x00");
        }
        if (cmd.gen_directive_decl) {
            array.writeMany("--gen-directive-decl\x00");
        }
        if (cmd.gen_directive_impl) {
            array.writeMany("--gen-directive-impl\x00");
        }
        if (cmd.gen_dxil_operation) {
            array.writeMany("--gen-dxil-operation\x00");
        }
        if (cmd.gen_riscv_target_def) {
            array.writeMany("--gen-riscv-target_def\x00");
        }
        if (cmd.output) |output| {
            array.writeMany("-o\x00");
            array.writeMany(output);
            array.writeOne(0);
        }
    }
    pub fn formatParseArgs(cmd: *types.TableGenCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("auto", arg)) {
                    cmd.color = .auto;
                } else if (mem.testEqualString("off", arg)) {
                    cmd.color = .off;
                } else if (mem.testEqualString("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mem.testEqualString("-I", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (cmd.include) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.include = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.include = dest[0..1];
                }
            } else if (mem.testEqualString("-d", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (cmd.dependencies) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.dependencies = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.dependencies = dest[0..1];
                }
            } else if (mem.testEqualString("--print-records", arg)) {
                cmd.print_records = true;
            } else if (mem.testEqualString("--print-detailed-records", arg)) {
                cmd.print_detailed_records = true;
            } else if (mem.testEqualString("--null-backend", arg)) {
                cmd.null_backend = true;
            } else if (mem.testEqualString("--dump-json", arg)) {
                cmd.dump_json = true;
            } else if (mem.testEqualString("--gen-emitter", arg)) {
                cmd.gen_emitter = true;
            } else if (mem.testEqualString("--gen-register-info", arg)) {
                cmd.gen_register_info = true;
            } else if (mem.testEqualString("--gen-instr-info", arg)) {
                cmd.gen_instr_info = true;
            } else if (mem.testEqualString("--gen-instr-docs", arg)) {
                cmd.gen_instr_docs = true;
            } else if (mem.testEqualString("--gen-callingconv", arg)) {
                cmd.gen_callingconv = true;
            } else if (mem.testEqualString("--gen-asm-writer", arg)) {
                cmd.gen_asm_writer = true;
            } else if (mem.testEqualString("--gen-disassembler", arg)) {
                cmd.gen_disassembler = true;
            } else if (mem.testEqualString("--gen-pseudo-lowering", arg)) {
                cmd.gen_pseudo_lowering = true;
            } else if (mem.testEqualString("--gen-compress-inst-emitter", arg)) {
                cmd.gen_compress_inst_emitter = true;
            } else if (mem.testEqualString("--gen-asm-matcher", arg)) {
                cmd.gen_asm_matcher = true;
            } else if (mem.testEqualString("--gen-dag-isel", arg)) {
                cmd.gen_dag_isel = true;
            } else if (mem.testEqualString("--gen-dfa-packetizer", arg)) {
                cmd.gen_dfa_packetizer = true;
            } else if (mem.testEqualString("--gen-fast-isel", arg)) {
                cmd.gen_fast_isel = true;
            } else if (mem.testEqualString("--gen-subtarget", arg)) {
                cmd.gen_subtarget = true;
            } else if (mem.testEqualString("--gen-intrinsic-enums", arg)) {
                cmd.gen_intrinsic_enums = true;
            } else if (mem.testEqualString("--gen-intrinsic-impl", arg)) {
                cmd.gen_intrinsic_impl = true;
            } else if (mem.testEqualString("--print-enums", arg)) {
                cmd.print_enums = true;
            } else if (mem.testEqualString("--print-sets", arg)) {
                cmd.print_sets = true;
            } else if (mem.testEqualString("--gen-opt-parser-defs", arg)) {
                cmd.gen_opt_parser_defs = true;
            } else if (mem.testEqualString("--gen-opt-rst", arg)) {
                cmd.gen_opt_rst = true;
            } else if (mem.testEqualString("--gen-ctags", arg)) {
                cmd.gen_ctags = true;
            } else if (mem.testEqualString("--gen-attrs", arg)) {
                cmd.gen_attrs = true;
            } else if (mem.testEqualString("--gen-searchable-tables", arg)) {
                cmd.gen_searchable_tables = true;
            } else if (mem.testEqualString("--gen-global-isel", arg)) {
                cmd.gen_global_isel = true;
            } else if (mem.testEqualString("--gen-global-isel-combiner", arg)) {
                cmd.gen_global_isel_combiner = true;
            } else if (mem.testEqualString("--gen-x86-EVEX2VEX-tables", arg)) {
                cmd.gen_x86_EVEX2VEX_tables = true;
            } else if (mem.testEqualString("--gen-x86-fold-tables", arg)) {
                cmd.gen_x86_fold_tables = true;
            } else if (mem.testEqualString("--gen-x86-mnemonic-tables", arg)) {
                cmd.gen_x86_mnemonic_tables = true;
            } else if (mem.testEqualString("--gen-register-bank", arg)) {
                cmd.gen_register_bank = true;
            } else if (mem.testEqualString("--gen-exegesis", arg)) {
                cmd.gen_exegesis = true;
            } else if (mem.testEqualString("--gen-automata", arg)) {
                cmd.gen_automata = true;
            } else if (mem.testEqualString("--gen-directive-decl", arg)) {
                cmd.gen_directive_decl = true;
            } else if (mem.testEqualString("--gen-directive-impl", arg)) {
                cmd.gen_directive_impl = true;
            } else if (mem.testEqualString("--gen-dxil-operation", arg)) {
                cmd.gen_dxil_operation = true;
            } else if (mem.testEqualString("--gen-riscv-target_def", arg)) {
                cmd.gen_riscv_target_def = true;
            } else if (mem.testEqualString("-o", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                cmd.output = arg;
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(tblgen_help);
            }
        }
    }
};
pub const HarecCommand = struct {
    arch: ?[]const u8 = null,
    /// Define identifiers
    defs: ?[]const types.Macro = null,
    /// Output file
    output: ?[]const u8 = null,
    tags: ?[]const []const u8 = null,
    typedefs: bool = false,
    namespace: bool = false,
    pub fn formatWriteBuf(cmd: *types.HarecCommand, harec_exe: []const u8, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        @memcpy(ptr, harec_exe);
        ptr += harec_exe.len;
        ptr[0] = 0;
        ptr += 1;
        if (cmd.arch) |arch| {
            ptr[0..3].* = "-a\x00".*;
            ptr += 3;
            @memcpy(ptr, arch);
            ptr += arch.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.defs) |defs| {
            ptr += types.Macros.formatWriteBuf(.{ .value = defs }, ptr);
        }
        if (cmd.output) |output| {
            ptr[0..3].* = "-o\x00".*;
            ptr += 3;
            @memcpy(ptr, output);
            ptr += output.len;
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                ptr[0..2].* = "-T".*;
                ptr += 2;
                @memcpy(ptr, value);
                ptr += value.len;
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.typedefs) {
            ptr[0..3].* = "-t\x00".*;
            ptr += 3;
        }
        if (cmd.namespace) {
            ptr[0..3].* = "-N\x00".*;
            ptr += 3;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *types.HarecCommand, harec_exe: []const u8) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= harec_exe.len;
        len +%= 1;
        if (cmd.arch) |arch| {
            len +%= 3;
            len +%= arch.len;
            len +%= 1;
        }
        if (cmd.defs) |defs| {
            len +%= types.Macros.formatLength(.{ .value = defs });
        }
        if (cmd.output) |output| {
            len +%= 3;
            len +%= output.len;
            len +%= 1;
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                len +%= 2;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.typedefs) {
            len +%= 3;
        }
        if (cmd.namespace) {
            len +%= 3;
        }
        return len;
    }
    pub fn formatWrite(cmd: *types.HarecCommand, harec_exe: []const u8, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(harec_exe);
        array.writeOne(0);
        if (cmd.arch) |arch| {
            array.writeMany("-a\x00");
            array.writeMany(arch);
            array.writeOne(0);
        }
        if (cmd.defs) |defs| {
            array.writeFormat(types.Macros{ .value = defs });
        }
        if (cmd.output) |output| {
            array.writeMany("-o\x00");
            array.writeMany(output);
            array.writeOne(0);
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                array.writeMany("-T");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.typedefs) {
            array.writeMany("-t\x00");
        }
        if (cmd.namespace) {
            array.writeMany("-N\x00");
        }
    }
    pub fn formatParseArgs(cmd: *types.HarecCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("-a", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                cmd.arch = arg;
            } else if (mem.testEqualString("-o", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                cmd.output = arg;
            } else if (mem.testEqualString("-T", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (cmd.tags) |src| {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16 *% (src.len +% 1), 8));
                    @memcpy(dest, src);
                    dest[src.len] = arg;
                    cmd.tags = dest[0 .. src.len +% 1];
                } else {
                    const dest: [*][]const u8 = @ptrFromInt(allocator.allocateRaw(16, 8));
                    dest[0] = arg;
                    cmd.tags = dest[0..1];
                }
            } else if (mem.testEqualString("-t", arg)) {
                cmd.typedefs = true;
            } else if (mem.testEqualString("-N", arg)) {
                cmd.namespace = true;
            } else if (mem.testEqualString("--help", arg)) {
                debug.write(harec_help);
            }
        }
    }
};
const build_help: [:0]const u8 = 
    \\    build-
    \\    -f[no-]emit-bin                 (default=yes) Output machine code
    \\    -f[no-]emit-asm                 (default=no) Output assembly code (.s)
    \\    -f[no-]emit-llvm-ir             (default=no) Output optimized LLVM IR (.ll)
    \\    -f[no-]emit-llvm-bc             (default=no) Output optimized LLVM BC (.bc)
    \\    -f[no-]emit-h                   (default=no) Output a C header file (.h)
    \\    -f[no-]emit-docs                (default=no) Output documentation (.html)
    \\    -f[no-]emit-analysis            (default=no) Output analysis (.json)
    \\    -f[no-]emit-implib              (default=yes) Output an import when building a Windows DLL (.lib)
    \\    --cache-dir                     Override the local cache directory
    \\    --global-cache-dir              Override the global cache directory
    \\    --zig-lib-dir                   Override Zig installation lib directory
    \\    --listen                        [MISSING]
    \\    -target                         <arch><sub>-<os>-<abi> see the targets command
    \\    -mcpu                           Specify target CPU and feature set
    \\    -mcmodel                        Limit range of code and data virtual addresses
    \\    -m[no-]red-zone                 Enable the "red-zone"
    \\    -f[no-]builtin                  Enable implicit builtin knowledge of functions
    \\    -f[no-]omit-frame-pointer       Omit the stack frame pointer
    \\    -mexec-model                    (WASI) Execution model
    \\    --name                          Override root name
    \\    -f[no-]soname                   Override the default SONAME value
    \\    -O                              Choose what to optimize for:
    \\                                      Debug          Optimizations off, safety on
    \\                                      ReleaseSafe    Optimizations on, safety on
    \\                                      ReleaseFast    Optimizations on, safety off
    \\                                      ReleaseSmall   Size optimizations on, safety off
    \\    -fopt-bisect-limit              Only run [limit] first LLVM optimization passes
    \\    --main-pkg-path                 Set the directory of the root package
    \\    -f[no-]PIC                      Enable Position Independent Code
    \\    -f[no-]PIE                      Enable Position Independent Executable
    \\    -f[no-]lto                      Enable Link Time Optimization
    \\    -f[no-]stack-check              Enable stack probing in unsafe builds
    \\    -f[no-]stack-protector          Enable stack protection in unsafe builds
    \\    -f[no-]sanitize-c               Enable C undefined behaviour detection in unsafe builds
    \\    -f[no-]valgrind                 Include valgrind client requests in release builds
    \\    -f[no-]sanitize-thread          Enable thread sanitizer
    \\    -f[no-]unwind-tables            Always produce unwind table entries for all functions
    \\    -f[no-]reference-trace          How many lines of reference trace should be shown per compile error
    \\    -f[no-]error-tracing            Enable error tracing in `ReleaseFast` mode
    \\    -f[no-]single-threaded          Code assumes there is only one thread
    \\    -f[no-]function-sections        Places each function in a separate sections
    \\    -f[no-]strip                    Omit debug symbols
    \\    -f[no-]formatted-panics         Enable formatted safety panics
    \\    -ofmt                           Override target object format:
    \\                                      elf                    Executable and Linking Format
    \\                                      c                      C source code
    \\                                      wasm                   WebAssembly
    \\                                      coff                   Common Object File Format (Windows)
    \\                                      macho                  macOS relocatables
    \\                                      spirv                  Standard, Portable Intermediate Representation V (SPIR-V)
    \\                                      plan9                  Plan 9 from Bell Labs object format
    \\                                      hex (planned feature)  Intel IHEX
    \\                                      raw (planned feature)  Dump machine code directly
    \\    -idirafter                      Add directory to AFTER include search path
    \\    -isystem                        Add directory to SYSTEM include search path
    \\    --libc                          Provide a file which specifies libc paths
    \\    --library                       Link against system library (only if actually used)
    \\    -I                              Add directories to include search path
    \\    --needed-library                Link against system library (even if unused)
    \\    --library-directory             Add a directory to the library search path
    \\    --script                        Use a custom linker script
    \\    --version-script                Provide a version .map file
    \\    --dynamic-linker                Set the dynamic interpreter path
    \\    --sysroot                       Set the system root directory
    \\    --entry                         Set the entrypoint symbol name
    \\    -f[no-]LLD                      Use LLD as the linker
    \\    -f[no-]compiler-rt              (default) Include compiler-rt symbols in output
    \\    -rpath                          Add directory to the runtime library search path
    \\    -f[no-]each-lib-rpath           Ensure adding rpath for each used dynamic library
    \\    -f[no-]allow-shlib-undefined    Allow undefined symbols in shared libraries
    \\    --build-id                      Help coordinate stripped binaries with debug symbols
    \\    --eh-frame-hdr                  Enable C++ exception handling by passing --eh-frame-hdr to linker
    \\    --emit-relocs                   Enable output of relocation sections for post build tools
    \\    --[no-]gc-sections              Force removal of functions and data that are unreachable
    \\                                    by the entry point or exported symbols
    \\    --stack                         Override default stack size
    \\    --image-base                    Set base address for executable image
    \\    -D                              Define C macros available within the `@cImport` namespace
    \\    --mod                           Define modules available as dependencies for the current target
    \\    -lc                             Link libc
    \\    -rdynamic                       Add all symbols to the dynamic symbol table
    \\    -dynamic                        Force output to be dynamically linked
    \\    -static                         Force output to be statically linked
    \\    -Bsymbolic                      Bind global references locally
    \\    -z                              Set linker extension flags:
    \\                                      nodelete                   Indicate that the object cannot be deleted from a process
    \\                                      notext                     Permit read-only relocations in read-only segments
    \\                                      defs                       Force a fatal error if any undefined symbols remain
    \\                                      undefs                     Reverse of -z defs
    \\                                      origin                     Indicate that the object must have its origin processed
    \\                                      nocopyreloc                Disable the creation of copy relocations
    \\                                      now (default)              Force all relocations to be processed on load
    \\                                      lazy                       Don't force all relocations to be processed on load
    \\                                      relro (default)            Force all relocations to be read-only after processing
    \\                                      norelro                    Don't force all relocations to be read-only after processing
    \\                                      common-page-size=[bytes]   Set the common page size for ELF binaries
    \\                                      max-page-size=[bytes]      Set the max page size for ELF binaries
    \\    --color                         Enable or disable colored error messages
    \\    -ftime-report                   Print timing diagnostics
    \\    -fstack-report                  Print stack size diagnostics
    \\    --verbose-link                  Display linker invocations
    \\    --verbose-cc                    Display C compiler invocations
    \\    --verbose-air                   Enable compiler debug output for Zig AIR
    \\    --verbose-mir                   Enable compiler debug output for Zig MIR
    \\    --verbose-llvm-ir               Enable compiler debug output for LLVM IR
    \\    --verbose-cimport               Enable compiler debug output for C imports
    \\    --verbose-llvm-cpu-features     Enable compiler debug output for LLVM CPU features
    \\    --debug-log                     Enable printing debug/info log messages for scope
    \\    --debug-compile-errors          Crash with helpful diagnostics at the first compile error
    \\    --debug-link-snapshot           Enable dumping of the linker's state in JSON
;
const format_help: [:0]const u8 = 
    \\    fmt
    \\    --color         Enable or disable colored error messages
    \\    --stdin         Format code from stdin; output to stdout
    \\    --check         List non-conforming files and exit with an error if the list is non-empty
    \\    --ast-check     Run zig ast-check on every file
    \\    --exclude       Exclude file or directory from formatting
;
const archive_help: [:0]const u8 = 
    \\    ar
    \\    --format    Archive format to create
    \\    --plugin    Ignored for compatibility
    \\    --output    Extraction target directory
    \\    --thin      Create a thin archive
    \\    a           Put [files] after [relpos]
    \\    b           Put [files] before [relpos] (same as [i])
    \\    c           Do not warn if archive had to be created
    \\    D           Use zero for timestamps and uids/gids (default)
    \\    U           Use actual timestamps and uids/gids
    \\    L           Add archive's contents
    \\    o           Preserve original dates
    \\    s           Create an archive index (cf. ranlib)
    \\    S           do not build a symbol table
    \\    u           update only [files] newer than archive contents
;
const objcopy_help: [:0]const u8 = 
    \\    objcopy
    \\    --output-target
    \\    --only-section
    \\    --pad-to
    \\    --strip-debug
    \\    --strip-all
    \\    --only-keep-debug
    \\    --add-gnu-debuglink
    \\    --extract-to
;
const tblgen_help: [:0]const u8 = 
    \\    --color                         Use colors in output (default=autodetect)
    \\    -I                              Add directories to include search path
    \\    -d                              Add file dependencies
    \\    --print-records                 Print all records to stdout (default)
    \\    --print-detailed-records        Print full details of all records to stdout
    \\    --null-backend                  Do nothing after parsing (useful for timing)
    \\    --dump-json                     Dump all records as machine-readable JSON
    \\    --gen-emitter                   Generate machine code emitter
    \\    --gen-register-info             Generate registers and register classes info
    \\    --gen-instr-info                Generate instruction descriptions
    \\    --gen-instr-docs                Generate instruction documentation
    \\    --gen-callingconv               Generate calling convention descriptions
    \\    --gen-asm-writer                Generate assembly writer
    \\    --gen-disassembler              Generate disassembler
    \\    --gen-pseudo-lowering           Generate pseudo instruction lowering
    \\    --gen-compress-inst-emitter     Generate RISCV compressed instructions.
    \\    --gen-asm-matcher               Generate assembly instruction matcher
    \\    --gen-dag-isel                  Generate a DAG instruction selector
    \\    --gen-dfa-packetizer            Generate DFA Packetizer for VLIW targets
    \\    --gen-fast-isel                 Generate a "fast" instruction selector
    \\    --gen-subtarget                 Generate subtarget enumerations
    \\    --gen-intrinsic-enums           Generate intrinsic enums
    \\    --gen-intrinsic-impl            Generate intrinsic information
    \\    --print-enums                   Print enum values for a class
    \\    --print-sets                    Print expanded sets for testing DAG exprs
    \\    --gen-opt-parser-defs           Generate option definitions
    \\    --gen-opt-rst                   Generate option RST
    \\    --gen-ctags                     Generate ctags-compatible index
    \\    --gen-attrs                     Generate attributes
    \\    --gen-searchable-tables         Generate generic binary-searchable table
    \\    --gen-global-isel               Generate GlobalISel selector
    \\    --gen-global-isel-combiner      Generate GlobalISel combiner
    \\    --gen-x86-EVEX2VEX-tables       Generate X86 EVEX to VEX compress tables
    \\    --gen-x86-fold-tables           Generate X86 fold tables
    \\    --gen-x86-mnemonic-tables       Generate X86 mnemonic tables
    \\    --gen-register-bank             Generate registers bank descriptions
    \\    --gen-exegesis                  Generate llvm-exegesis tables
    \\    --gen-automata                  Generate generic automata
    \\    --gen-directive-decl            Generate directive related declaration code (header file)
    \\    --gen-directive-impl            Generate directive related implementation code
    \\    --gen-dxil-operation            Generate DXIL operation information
    \\    --gen-riscv-target_def          Generate the list of CPU for RISCV
    \\    -o                              Output file
;
const harec_help: [:0]const u8 = 
    \\    -a
    \\    -o      Output file
    \\    -T
    \\    -t
    \\    -N
;
pub const Fns = struct {
    formatParseArgsBuildCommand: *fn (*types.BuildCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufBuildCommand: *fn (*types.BuildCommand, [*]const u8, usize, [*]const types.Path, usize, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthBuildCommand: *fn (*types.BuildCommand, [*]const u8, usize, [*]const types.Path, usize) callconv(.C) usize = @ptrFromInt(8),
    formatParseArgsFormatCommand: *fn (*types.FormatCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufFormatCommand: *fn (*types.FormatCommand, [*]const u8, usize, types.Path, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthFormatCommand: *fn (*types.FormatCommand, [*]const u8, usize, types.Path) callconv(.C) usize = @ptrFromInt(8),
    formatParseArgsArchiveCommand: *fn (*types.ArchiveCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufArchiveCommand: *fn (*types.ArchiveCommand, [*]const u8, usize, [*]const types.Path, usize, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthArchiveCommand: *fn (*types.ArchiveCommand, [*]const u8, usize, [*]const types.Path, usize) callconv(.C) usize = @ptrFromInt(8),
    formatParseArgsObjcopyCommand: *fn (*types.ObjcopyCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufObjcopyCommand: *fn (*types.ObjcopyCommand, [*]const u8, usize, types.Path, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthObjcopyCommand: *fn (*types.ObjcopyCommand, [*]const u8, usize, types.Path) callconv(.C) usize = @ptrFromInt(8),
    formatParseArgsTableGenCommand: *fn (*types.TableGenCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufTableGenCommand: *fn (*types.TableGenCommand, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthTableGenCommand: *fn (*types.TableGenCommand) callconv(.C) usize = @ptrFromInt(8),
    formatParseArgsHarecCommand: *fn (*types.HarecCommand, *types.Allocator, [*][*:0]u8, usize) void = @ptrFromInt(8),
    formatWriteBufHarecCommand: *fn (*types.HarecCommand, [*]const u8, usize, [*]u8) callconv(.C) usize = @ptrFromInt(8),
    formatLengthHarecCommand: *fn (*types.HarecCommand, [*]const u8, usize) callconv(.C) usize = @ptrFromInt(8),
};
