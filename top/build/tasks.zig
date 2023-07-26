const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const safety: bool = false;
pub const BuildCommand = struct {
    kind: types.OutputMode,
    /// (default=yes) Output machine code
    emit_bin: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output assembly code (.s)
    emit_asm: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output optimized LLVM IR (.ll)
    emit_llvm_ir: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output optimized LLVM BC (.bc)
    emit_llvm_bc: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output a C header file (.h)
    emit_h: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output documentation (.html)
    emit_docs: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=no) Output analysis (.json)
    emit_analysis: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
    /// (default=yes) Output an import when building a Windows DLL (.lib)
    emit_implib: ?union(enum) {
        yes: ?types.Path,
        no,
    } = null,
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
    /// Debug          Optimizations off, safety on
    /// ReleaseSafe    Optimizations on, safety on
    /// ReleaseFast    Optimizations on, safety off
    /// ReleaseSmall   Size optimizations on, safety off
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
    /// Use LLVM as the codegen backend
    llvm: ?bool = null,
    /// Use Clang as the C/C++ compilation backend
    clang: ?bool = null,
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
    /// elf                    Executable and Linking Format
    /// c                      C source code
    /// wasm                   WebAssembly
    /// coff                   Common Object File Format (Windows)
    /// macho                  macOS relocatables
    /// spirv                  Standard, Portable Intermediate Representation V (SPIR-V)
    /// plan9                  Plan 9 from Bell Labs object format
    /// hex (planned feature)  Intel IHEX
    /// raw (planned feature)  Dump machine code directly
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
    /// Debug section compression:
    /// none   No compression
    /// zlib   Compression with deflate/inflate
    compress_debug_sections: ?bool = null,
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
    /// nodelete                   Indicate that the object cannot be deleted from a process
    /// notext                     Permit read-only relocations in read-only segments
    /// defs                       Force a fatal error if any undefined symbols remain
    /// undefs                     Reverse of -z defs
    /// origin                     Indicate that the object must have its origin processed
    /// nocopyreloc                Disable the creation of copy relocations
    /// now (default)              Force all relocations to be processed on load
    /// lazy                       Don't force all relocations to be processed on load
    /// relro (default)            Force all relocations to be read-only after processing
    /// norelro                    Don't force all relocations to be read-only after processing
    /// common-page-size=[bytes]   Set the common page size for ELF binaries
    /// max-page-size=[bytes]      Set the max page size for ELF binaries
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
    pub fn formatWrite(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
                array.writeMany("-fstack-check\x00");
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
        if (cmd.compress_debug_sections) |compress_debug_sections| {
            if (compress_debug_sections) {
                array.writeMany("--compress-debug-sections=zlib\x00");
            } else {
                array.writeMany("--compress-debug-sections=none\x00");
            }
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
        array.writeFormat(types.Files{ .value = files });
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
    pub fn formatWriteBuf(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @as(*[6]u8, @ptrCast(buf + len)).* = "build-".*;
        len +%= 6;
        @memcpy(buf + len, @tagName(cmd.kind));
        len +%= @tagName(cmd.kind).len;
        buf[len] = 0;
        len +%= 1;
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[11]u8, @ptrCast(buf + len)).* = "-femit-bin\x3d".*;
                        len +%= 11;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[11]u8, @ptrCast(buf + len)).* = "-femit-bin\x00".*;
                        len +%= 11;
                    }
                },
                .no => {
                    @as(*[14]u8, @ptrCast(buf + len)).* = "-fno-emit-bin\x00".*;
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[11]u8, @ptrCast(buf + len)).* = "-femit-asm\x3d".*;
                        len +%= 11;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[11]u8, @ptrCast(buf + len)).* = "-femit-asm\x00".*;
                        len +%= 11;
                    }
                },
                .no => {
                    @as(*[14]u8, @ptrCast(buf + len)).* = "-fno-emit-asm\x00".*;
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[15]u8, @ptrCast(buf + len)).* = "-femit-llvm-ir\x3d".*;
                        len +%= 15;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[15]u8, @ptrCast(buf + len)).* = "-femit-llvm-ir\x00".*;
                        len +%= 15;
                    }
                },
                .no => {
                    @as(*[18]u8, @ptrCast(buf + len)).* = "-fno-emit-llvm-ir\x00".*;
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[15]u8, @ptrCast(buf + len)).* = "-femit-llvm-bc\x3d".*;
                        len +%= 15;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[15]u8, @ptrCast(buf + len)).* = "-femit-llvm-bc\x00".*;
                        len +%= 15;
                    }
                },
                .no => {
                    @as(*[18]u8, @ptrCast(buf + len)).* = "-fno-emit-llvm-bc\x00".*;
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[9]u8, @ptrCast(buf + len)).* = "-femit-h\x3d".*;
                        len +%= 9;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[9]u8, @ptrCast(buf + len)).* = "-femit-h\x00".*;
                        len +%= 9;
                    }
                },
                .no => {
                    @as(*[12]u8, @ptrCast(buf + len)).* = "-fno-emit-h\x00".*;
                    len +%= 12;
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[12]u8, @ptrCast(buf + len)).* = "-femit-docs\x3d".*;
                        len +%= 12;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[12]u8, @ptrCast(buf + len)).* = "-femit-docs\x00".*;
                        len +%= 12;
                    }
                },
                .no => {
                    @as(*[15]u8, @ptrCast(buf + len)).* = "-fno-emit-docs\x00".*;
                    len +%= 15;
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[16]u8, @ptrCast(buf + len)).* = "-femit-analysis\x3d".*;
                        len +%= 16;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[16]u8, @ptrCast(buf + len)).* = "-femit-analysis\x00".*;
                        len +%= 16;
                    }
                },
                .no => {
                    @as(*[19]u8, @ptrCast(buf + len)).* = "-fno-emit-analysis\x00".*;
                    len +%= 19;
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @as(*[14]u8, @ptrCast(buf + len)).* = "-femit-implib\x3d".*;
                        len +%= 14;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @as(*[14]u8, @ptrCast(buf + len)).* = "-femit-implib\x00".*;
                        len +%= 14;
                    }
                },
                .no => {
                    @as(*[17]u8, @ptrCast(buf + len)).* = "-fno-emit-implib\x00".*;
                    len +%= 17;
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--cache-dir\x00".*;
            len +%= 12;
            @memcpy(buf + len, cache_root);
            len +%= cache_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            @as(*[19]u8, @ptrCast(buf + len)).* = "--global-cache-dir\x00".*;
            len +%= 19;
            @memcpy(buf + len, global_cache_root);
            len +%= global_cache_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--zig-lib-dir\x00".*;
            len +%= 14;
            @memcpy(buf + len, zig_lib_root);
            len +%= zig_lib_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.listen) |listen| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--listen\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(listen));
            len +%= @tagName(listen).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.target) |target| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "-target\x00".*;
            len +%= 8;
            @memcpy(buf + len, target);
            len +%= target.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.cpu) |cpu| {
            @as(*[6]u8, @ptrCast(buf + len)).* = "-mcpu\x00".*;
            len +%= 6;
            @memcpy(buf + len, cpu);
            len +%= cpu.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.code_model) |code_model| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "-mcmodel\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(code_model));
            len +%= @tagName(code_model).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                @as(*[11]u8, @ptrCast(buf + len)).* = "-mred-zone\x00".*;
                len +%= 11;
            } else {
                @as(*[14]u8, @ptrCast(buf + len)).* = "-mno-red-zone\x00".*;
                len +%= 14;
            }
        }
        if (cmd.implicit_builtins) |implicit_builtins| {
            if (implicit_builtins) {
                @as(*[10]u8, @ptrCast(buf + len)).* = "-fbuiltin\x00".*;
                len +%= 10;
            } else {
                @as(*[13]u8, @ptrCast(buf + len)).* = "-fno-builtin\x00".*;
                len +%= 13;
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                @as(*[21]u8, @ptrCast(buf + len)).* = "-fomit-frame-pointer\x00".*;
                len +%= 21;
            } else {
                @as(*[24]u8, @ptrCast(buf + len)).* = "-fno-omit-frame-pointer\x00".*;
                len +%= 24;
            }
        }
        if (cmd.exec_model) |exec_model| {
            @as(*[13]u8, @ptrCast(buf + len)).* = "-mexec-model\x00".*;
            len +%= 13;
            @memcpy(buf + len, exec_model);
            len +%= exec_model.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.name) |name| {
            @as(*[7]u8, @ptrCast(buf + len)).* = "--name\x00".*;
            len +%= 7;
            @memcpy(buf + len, name);
            len +%= name.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    @as(*[9]u8, @ptrCast(buf + len)).* = "-fsoname\x00".*;
                    len +%= 9;
                    @memcpy(buf + len, arg);
                    len +%= arg.len;
                    buf[len] = 0;
                    len +%= 1;
                },
                .no => {
                    @as(*[12]u8, @ptrCast(buf + len)).* = "-fno-soname\x00".*;
                    len +%= 12;
                },
            }
        }
        if (cmd.mode) |mode| {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-O\x00".*;
            len +%= 3;
            @memcpy(buf + len, @tagName(mode));
            len +%= @tagName(mode).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.passes) |passes| {
            @as(*[19]u8, @ptrCast(buf + len)).* = "-fopt-bisect-limit\x3d".*;
            len +%= 19;
            len +%= fmt.Type.Ud64.formatWriteBuf(.{ .value = passes }, buf + len);
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.main_pkg_path) |main_pkg_path| {
            @as(*[16]u8, @ptrCast(buf + len)).* = "--main-pkg-path\x00".*;
            len +%= 16;
            @memcpy(buf + len, main_pkg_path);
            len +%= main_pkg_path.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.pic) |pic| {
            if (pic) {
                @as(*[6]u8, @ptrCast(buf + len)).* = "-fPIC\x00".*;
                len +%= 6;
            } else {
                @as(*[9]u8, @ptrCast(buf + len)).* = "-fno-PIC\x00".*;
                len +%= 9;
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                @as(*[6]u8, @ptrCast(buf + len)).* = "-fPIE\x00".*;
                len +%= 6;
            } else {
                @as(*[9]u8, @ptrCast(buf + len)).* = "-fno-PIE\x00".*;
                len +%= 9;
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                @as(*[6]u8, @ptrCast(buf + len)).* = "-flto\x00".*;
                len +%= 6;
            } else {
                @as(*[9]u8, @ptrCast(buf + len)).* = "-fno-lto\x00".*;
                len +%= 9;
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                @as(*[14]u8, @ptrCast(buf + len)).* = "-fstack-check\x00".*;
                len +%= 14;
            } else {
                @as(*[17]u8, @ptrCast(buf + len)).* = "-fno-stack-check\x00".*;
                len +%= 17;
            }
        }
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                @as(*[14]u8, @ptrCast(buf + len)).* = "-fstack-check\x00".*;
                len +%= 14;
            } else {
                @as(*[21]u8, @ptrCast(buf + len)).* = "-fno-stack-protector\x00".*;
                len +%= 21;
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                @as(*[13]u8, @ptrCast(buf + len)).* = "-fsanitize-c\x00".*;
                len +%= 13;
            } else {
                @as(*[16]u8, @ptrCast(buf + len)).* = "-fno-sanitize-c\x00".*;
                len +%= 16;
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                @as(*[11]u8, @ptrCast(buf + len)).* = "-fvalgrind\x00".*;
                len +%= 11;
            } else {
                @as(*[14]u8, @ptrCast(buf + len)).* = "-fno-valgrind\x00".*;
                len +%= 14;
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                @as(*[18]u8, @ptrCast(buf + len)).* = "-fsanitize-thread\x00".*;
                len +%= 18;
            } else {
                @as(*[21]u8, @ptrCast(buf + len)).* = "-fno-sanitize-thread\x00".*;
                len +%= 21;
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                @as(*[16]u8, @ptrCast(buf + len)).* = "-funwind-tables\x00".*;
                len +%= 16;
            } else {
                @as(*[19]u8, @ptrCast(buf + len)).* = "-fno-unwind-tables\x00".*;
                len +%= 19;
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                @as(*[7]u8, @ptrCast(buf + len)).* = "-fLLVM\x00".*;
                len +%= 7;
            } else {
                @as(*[10]u8, @ptrCast(buf + len)).* = "-fno-LLVM\x00".*;
                len +%= 10;
            }
        }
        if (cmd.clang) |clang| {
            if (clang) {
                @as(*[8]u8, @ptrCast(buf + len)).* = "-fClang\x00".*;
                len +%= 8;
            } else {
                @as(*[11]u8, @ptrCast(buf + len)).* = "-fno-Clang\x00".*;
                len +%= 11;
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                @as(*[18]u8, @ptrCast(buf + len)).* = "-freference-trace\x00".*;
                len +%= 18;
            } else {
                @as(*[21]u8, @ptrCast(buf + len)).* = "-fno-reference-trace\x00".*;
                len +%= 21;
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                @as(*[16]u8, @ptrCast(buf + len)).* = "-ferror-tracing\x00".*;
                len +%= 16;
            } else {
                @as(*[19]u8, @ptrCast(buf + len)).* = "-fno-error-tracing\x00".*;
                len +%= 19;
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                @as(*[18]u8, @ptrCast(buf + len)).* = "-fsingle-threaded\x00".*;
                len +%= 18;
            } else {
                @as(*[21]u8, @ptrCast(buf + len)).* = "-fno-single-threaded\x00".*;
                len +%= 21;
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                @as(*[20]u8, @ptrCast(buf + len)).* = "-ffunction-sections\x00".*;
                len +%= 20;
            } else {
                @as(*[23]u8, @ptrCast(buf + len)).* = "-fno-function-sections\x00".*;
                len +%= 23;
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                @as(*[8]u8, @ptrCast(buf + len)).* = "-fstrip\x00".*;
                len +%= 8;
            } else {
                @as(*[11]u8, @ptrCast(buf + len)).* = "-fno-strip\x00".*;
                len +%= 11;
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                @as(*[19]u8, @ptrCast(buf + len)).* = "-fformatted-panics\x00".*;
                len +%= 19;
            } else {
                @as(*[22]u8, @ptrCast(buf + len)).* = "-fno-formatted-panics\x00".*;
                len +%= 22;
            }
        }
        if (cmd.format) |format| {
            @as(*[6]u8, @ptrCast(buf + len)).* = "-ofmt\x3d".*;
            len +%= 6;
            @memcpy(buf + len, @tagName(format));
            len +%= @tagName(format).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.dirafter) |dirafter| {
            @as(*[11]u8, @ptrCast(buf + len)).* = "-idirafter\x00".*;
            len +%= 11;
            @memcpy(buf + len, dirafter);
            len +%= dirafter.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.system) |system| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "-isystem\x00".*;
            len +%= 9;
            @memcpy(buf + len, system);
            len +%= system.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.libc) |libc| {
            @as(*[7]u8, @ptrCast(buf + len)).* = "--libc\x00".*;
            len +%= 7;
            @memcpy(buf + len, libc);
            len +%= libc.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.library) |library| {
            @as(*[10]u8, @ptrCast(buf + len)).* = "--library\x00".*;
            len +%= 10;
            @memcpy(buf + len, library);
            len +%= library.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                @as(*[3]u8, @ptrCast(buf + len)).* = "-I\x00".*;
                len +%= 3;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                @as(*[17]u8, @ptrCast(buf + len)).* = "--needed-library\x00".*;
                len +%= 17;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                @as(*[20]u8, @ptrCast(buf + len)).* = "--library-directory\x00".*;
                len +%= 20;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.link_script) |link_script| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--script\x00".*;
            len +%= 9;
            @memcpy(buf + len, link_script);
            len +%= link_script.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.version_script) |version_script| {
            @as(*[17]u8, @ptrCast(buf + len)).* = "--version-script\x00".*;
            len +%= 17;
            @memcpy(buf + len, version_script);
            len +%= version_script.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            @as(*[17]u8, @ptrCast(buf + len)).* = "--dynamic-linker\x00".*;
            len +%= 17;
            @memcpy(buf + len, dynamic_linker);
            len +%= dynamic_linker.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.sysroot) |sysroot| {
            @as(*[10]u8, @ptrCast(buf + len)).* = "--sysroot\x00".*;
            len +%= 10;
            @memcpy(buf + len, sysroot);
            len +%= sysroot.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.entry) |entry| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--entry\x00".*;
            len +%= 8;
            @memcpy(buf + len, entry);
            len +%= entry.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.lld) |lld| {
            if (lld) {
                @as(*[6]u8, @ptrCast(buf + len)).* = "-fLLD\x00".*;
                len +%= 6;
            } else {
                @as(*[9]u8, @ptrCast(buf + len)).* = "-fno-LLD\x00".*;
                len +%= 9;
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                @as(*[14]u8, @ptrCast(buf + len)).* = "-fcompiler-rt\x00".*;
                len +%= 14;
            } else {
                @as(*[17]u8, @ptrCast(buf + len)).* = "-fno-compiler-rt\x00".*;
                len +%= 17;
            }
        }
        if (cmd.rpath) |rpath| {
            @as(*[7]u8, @ptrCast(buf + len)).* = "-rpath\x00".*;
            len +%= 7;
            @memcpy(buf + len, rpath);
            len +%= rpath.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                @as(*[17]u8, @ptrCast(buf + len)).* = "-feach-lib-rpath\x00".*;
                len +%= 17;
            } else {
                @as(*[20]u8, @ptrCast(buf + len)).* = "-fno-each-lib-rpath\x00".*;
                len +%= 20;
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                @as(*[24]u8, @ptrCast(buf + len)).* = "-fallow-shlib-undefined\x00".*;
                len +%= 24;
            } else {
                @as(*[27]u8, @ptrCast(buf + len)).* = "-fno-allow-shlib-undefined\x00".*;
                len +%= 27;
            }
        }
        if (cmd.build_id) |build_id| {
            @as(*[11]u8, @ptrCast(buf + len)).* = "--build-id\x3d".*;
            len +%= 11;
            @memcpy(buf + len, @tagName(build_id));
            len +%= @tagName(build_id).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.compress_debug_sections) |compress_debug_sections| {
            if (compress_debug_sections) {
                @as(*[31]u8, @ptrCast(buf + len)).* = "--compress-debug-sections=zlib\x00".*;
                len +%= 31;
            } else {
                @as(*[31]u8, @ptrCast(buf + len)).* = "--compress-debug-sections=none\x00".*;
                len +%= 31;
            }
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                @as(*[14]u8, @ptrCast(buf + len)).* = "--gc-sections\x00".*;
                len +%= 14;
            } else {
                @as(*[17]u8, @ptrCast(buf + len)).* = "--no-gc-sections\x00".*;
                len +%= 17;
            }
        }
        if (cmd.stack) |stack| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--stack\x00".*;
            len +%= 8;
            len +%= fmt.Type.Ud64.formatWriteBuf(.{ .value = stack }, buf + len);
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.image_base) |image_base| {
            @as(*[13]u8, @ptrCast(buf + len)).* = "--image-base\x00".*;
            len +%= 13;
            len +%= fmt.Type.Ud64.formatWriteBuf(.{ .value = image_base }, buf + len);
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            for (macros) |value| {
                len +%= value.formatWriteBuf(buf + len);
            }
        }
        if (cmd.modules) |modules| {
            for (modules) |value| {
                len +%= value.formatWriteBuf(buf + len);
            }
        }
        if (cmd.dependencies) |dependencies| {
            len +%= types.ModuleDependencies.formatWriteBuf(.{ .value = dependencies }, buf + len);
        }
        if (cmd.cflags) |cflags| {
            len +%= types.CFlags.formatWriteBuf(.{ .value = cflags }, buf + len);
        }
        if (cmd.link_libc) {
            @as(*[4]u8, @ptrCast(buf + len)).* = "-lc\x00".*;
            len +%= 4;
        }
        if (cmd.rdynamic) {
            @as(*[10]u8, @ptrCast(buf + len)).* = "-rdynamic\x00".*;
            len +%= 10;
        }
        if (cmd.dynamic) {
            @as(*[9]u8, @ptrCast(buf + len)).* = "-dynamic\x00".*;
            len +%= 9;
        }
        if (cmd.static) {
            @as(*[8]u8, @ptrCast(buf + len)).* = "-static\x00".*;
            len +%= 8;
        }
        if (cmd.symbolic) {
            @as(*[11]u8, @ptrCast(buf + len)).* = "-Bsymbolic\x00".*;
            len +%= 11;
        }
        if (cmd.lflags) |lflags| {
            for (lflags) |value| {
                @as(*[3]u8, @ptrCast(buf + len)).* = "-z\x00".*;
                len +%= 3;
                @memcpy(buf + len, @tagName(value));
                len +%= @tagName(value).len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        len +%= types.Files.formatWriteBuf(.{ .value = files }, buf + len);
        if (cmd.color) |color| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--color\x00".*;
            len +%= 8;
            @memcpy(buf + len, @tagName(color));
            len +%= @tagName(color).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.time_report) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "-ftime-report\x00".*;
            len +%= 14;
        }
        if (cmd.stack_report) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "-fstack-report\x00".*;
            len +%= 15;
        }
        if (cmd.verbose_link) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--verbose-link\x00".*;
            len +%= 15;
        }
        if (cmd.verbose_cc) {
            @as(*[13]u8, @ptrCast(buf + len)).* = "--verbose-cc\x00".*;
            len +%= 13;
        }
        if (cmd.verbose_air) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--verbose-air\x00".*;
            len +%= 14;
        }
        if (cmd.verbose_mir) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--verbose-mir\x00".*;
            len +%= 14;
        }
        if (cmd.verbose_llvm_ir) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--verbose-llvm-ir\x00".*;
            len +%= 18;
        }
        if (cmd.verbose_cimport) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--verbose-cimport\x00".*;
            len +%= 18;
        }
        if (cmd.verbose_llvm_cpu_features) {
            @as(*[28]u8, @ptrCast(buf + len)).* = "--verbose-llvm-cpu-features\x00".*;
            len +%= 28;
        }
        if (cmd.debug_log) |debug_log| {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--debug-log\x00".*;
            len +%= 12;
            @memcpy(buf + len, debug_log);
            len +%= debug_log.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.debug_compiler_errors) {
            @as(*[23]u8, @ptrCast(buf + len)).* = "--debug-compile-errors\x00".*;
            len +%= 23;
        }
        if (cmd.debug_link_snapshot) {
            @as(*[22]u8, @ptrCast(buf + len)).* = "--debug-link-snapshot\x00".*;
            len +%= 22;
        }
        return len;
    }
    pub fn formatLength(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
                len +%= 14;
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
        if (cmd.compress_debug_sections) |compress_debug_sections| {
            if (compress_debug_sections) {
                len +%= 31;
            } else {
                len +%= 31;
            }
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
        len +%= types.Files.formatLength(.{ .value = files });
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
    pub fn formatParseArgs(cmd: *BuildCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("-femit-bin", arg[0..10])) {
                if (arg.len > 11 and arg[10] == '=') {
                    cmd.emit_bin = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[11..]) };
                } else {
                    cmd.emit_bin = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-bin", arg)) {
                cmd.emit_bin = .no;
            } else if (mach.testEqualMany8("-femit-asm", arg[0..10])) {
                if (arg.len > 11 and arg[10] == '=') {
                    cmd.emit_asm = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[11..]) };
                } else {
                    cmd.emit_asm = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-asm", arg)) {
                cmd.emit_asm = .no;
            } else if (mach.testEqualMany8("-femit-llvm-ir", arg[0..14])) {
                if (arg.len > 15 and arg[14] == '=') {
                    cmd.emit_llvm_ir = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[15..]) };
                } else {
                    cmd.emit_llvm_ir = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-llvm-ir", arg)) {
                cmd.emit_llvm_ir = .no;
            } else if (mach.testEqualMany8("-femit-llvm-bc", arg[0..14])) {
                if (arg.len > 15 and arg[14] == '=') {
                    cmd.emit_llvm_bc = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[15..]) };
                } else {
                    cmd.emit_llvm_bc = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-llvm-bc", arg)) {
                cmd.emit_llvm_bc = .no;
            } else if (mach.testEqualMany8("-femit-h", arg[0..8])) {
                if (arg.len > 9 and arg[8] == '=') {
                    cmd.emit_h = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[9..]) };
                } else {
                    cmd.emit_h = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-h", arg)) {
                cmd.emit_h = .no;
            } else if (mach.testEqualMany8("-femit-docs", arg[0..11])) {
                if (arg.len > 12 and arg[11] == '=') {
                    cmd.emit_docs = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[12..]) };
                } else {
                    cmd.emit_docs = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-docs", arg)) {
                cmd.emit_docs = .no;
            } else if (mach.testEqualMany8("-femit-analysis", arg[0..15])) {
                if (arg.len > 16 and arg[15] == '=') {
                    cmd.emit_analysis = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[16..]) };
                } else {
                    cmd.emit_analysis = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-analysis", arg)) {
                cmd.emit_analysis = .no;
            } else if (mach.testEqualMany8("-femit-implib", arg[0..13])) {
                if (arg.len > 14 and arg[13] == '=') {
                    cmd.emit_implib = .{ .yes = types.Path.formatParseArgs(allocator, args, &args_idx, arg[14..]) };
                } else {
                    cmd.emit_implib = .{ .yes = null };
                }
            } else if (mach.testEqualMany8("-fno-emit-implib", arg)) {
                cmd.emit_implib = .no;
            } else if (mach.testEqualMany8("--cache-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.cache_root = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--global-cache-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.global_cache_root = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--zig-lib-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.zig_lib_root = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--listen", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("none", arg)) {
                    cmd.listen = .none;
                } else if (mach.testEqualMany8("-", arg)) {
                    cmd.listen = .@"-";
                } else if (mach.testEqualMany8("ipv4", arg)) {
                    cmd.listen = .ipv4;
                }
            } else if (mach.testEqualMany8("-target", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.target = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-mcpu", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.cpu = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-mcmodel", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("default", arg)) {
                    cmd.code_model = .default;
                } else if (mach.testEqualMany8("tiny", arg)) {
                    cmd.code_model = .tiny;
                } else if (mach.testEqualMany8("small", arg)) {
                    cmd.code_model = .small;
                } else if (mach.testEqualMany8("kernel", arg)) {
                    cmd.code_model = .kernel;
                } else if (mach.testEqualMany8("medium", arg)) {
                    cmd.code_model = .medium;
                } else if (mach.testEqualMany8("large", arg)) {
                    cmd.code_model = .large;
                }
            } else if (mach.testEqualMany8("-mred-zone", arg)) {
                cmd.red_zone = true;
            } else if (mach.testEqualMany8("-mno-red-zone", arg)) {
                cmd.red_zone = false;
            } else if (mach.testEqualMany8("-fbuiltin", arg)) {
                cmd.implicit_builtins = true;
            } else if (mach.testEqualMany8("-fno-builtin", arg)) {
                cmd.implicit_builtins = false;
            } else if (mach.testEqualMany8("-fomit-frame-pointer", arg)) {
                cmd.omit_frame_pointer = true;
            } else if (mach.testEqualMany8("-fno-omit-frame-pointer", arg)) {
                cmd.omit_frame_pointer = false;
            } else if (mach.testEqualMany8("-mexec-model", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.exec_model = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--name", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.name = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-fsoname", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                cmd.soname = .{ .yes = arg };
            } else if (mach.testEqualMany8("-fno-soname", arg)) {
                cmd.soname = .no;
            } else if (mach.testEqualMany8("-O", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
                } else {
                    arg = arg[2..];
                }
                if (mach.testEqualMany8("Debug", arg)) {
                    cmd.mode = .Debug;
                } else if (mach.testEqualMany8("ReleaseSafe", arg)) {
                    cmd.mode = .ReleaseSafe;
                } else if (mach.testEqualMany8("ReleaseFast", arg)) {
                    cmd.mode = .ReleaseFast;
                } else if (mach.testEqualMany8("ReleaseSmall", arg)) {
                    cmd.mode = .ReleaseSmall;
                }
            } else if (mach.testEqualMany8("--main-pkg-path", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.main_pkg_path = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-fPIC", arg)) {
                cmd.pic = true;
            } else if (mach.testEqualMany8("-fno-PIC", arg)) {
                cmd.pic = false;
            } else if (mach.testEqualMany8("-fPIE", arg)) {
                cmd.pie = true;
            } else if (mach.testEqualMany8("-fno-PIE", arg)) {
                cmd.pie = false;
            } else if (mach.testEqualMany8("-flto", arg)) {
                cmd.lto = true;
            } else if (mach.testEqualMany8("-fno-lto", arg)) {
                cmd.lto = false;
            } else if (mach.testEqualMany8("-fstack-check", arg)) {
                cmd.stack_check = true;
            } else if (mach.testEqualMany8("-fno-stack-check", arg)) {
                cmd.stack_check = false;
            } else if (mach.testEqualMany8("-fstack-check", arg)) {
                cmd.stack_protector = true;
            } else if (mach.testEqualMany8("-fno-stack-protector", arg)) {
                cmd.stack_protector = false;
            } else if (mach.testEqualMany8("-fsanitize-c", arg)) {
                cmd.sanitize_c = true;
            } else if (mach.testEqualMany8("-fno-sanitize-c", arg)) {
                cmd.sanitize_c = false;
            } else if (mach.testEqualMany8("-fvalgrind", arg)) {
                cmd.valgrind = true;
            } else if (mach.testEqualMany8("-fno-valgrind", arg)) {
                cmd.valgrind = false;
            } else if (mach.testEqualMany8("-fsanitize-thread", arg)) {
                cmd.sanitize_thread = true;
            } else if (mach.testEqualMany8("-fno-sanitize-thread", arg)) {
                cmd.sanitize_thread = false;
            } else if (mach.testEqualMany8("-funwind-tables", arg)) {
                cmd.unwind_tables = true;
            } else if (mach.testEqualMany8("-fno-unwind-tables", arg)) {
                cmd.unwind_tables = false;
            } else if (mach.testEqualMany8("-fLLVM", arg)) {
                cmd.llvm = true;
            } else if (mach.testEqualMany8("-fno-LLVM", arg)) {
                cmd.llvm = false;
            } else if (mach.testEqualMany8("-fClang", arg)) {
                cmd.clang = true;
            } else if (mach.testEqualMany8("-fno-Clang", arg)) {
                cmd.clang = false;
            } else if (mach.testEqualMany8("-freference-trace", arg)) {
                cmd.reference_trace = true;
            } else if (mach.testEqualMany8("-fno-reference-trace", arg)) {
                cmd.reference_trace = false;
            } else if (mach.testEqualMany8("-ferror-tracing", arg)) {
                cmd.error_tracing = true;
            } else if (mach.testEqualMany8("-fno-error-tracing", arg)) {
                cmd.error_tracing = false;
            } else if (mach.testEqualMany8("-fsingle-threaded", arg)) {
                cmd.single_threaded = true;
            } else if (mach.testEqualMany8("-fno-single-threaded", arg)) {
                cmd.single_threaded = false;
            } else if (mach.testEqualMany8("-ffunction-sections", arg)) {
                cmd.function_sections = true;
            } else if (mach.testEqualMany8("-fno-function-sections", arg)) {
                cmd.function_sections = false;
            } else if (mach.testEqualMany8("-fstrip", arg)) {
                cmd.strip = true;
            } else if (mach.testEqualMany8("-fno-strip", arg)) {
                cmd.strip = false;
            } else if (mach.testEqualMany8("-fformatted-panics", arg)) {
                cmd.formatted_panics = true;
            } else if (mach.testEqualMany8("-fno-formatted-panics", arg)) {
                cmd.formatted_panics = false;
            } else if (mach.testEqualMany8("-ofmt", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("coff", arg)) {
                    cmd.format = .coff;
                } else if (mach.testEqualMany8("dxcontainer", arg)) {
                    cmd.format = .dxcontainer;
                } else if (mach.testEqualMany8("elf", arg)) {
                    cmd.format = .elf;
                } else if (mach.testEqualMany8("macho", arg)) {
                    cmd.format = .macho;
                } else if (mach.testEqualMany8("spirv", arg)) {
                    cmd.format = .spirv;
                } else if (mach.testEqualMany8("wasm", arg)) {
                    cmd.format = .wasm;
                } else if (mach.testEqualMany8("c", arg)) {
                    cmd.format = .c;
                } else if (mach.testEqualMany8("hex", arg)) {
                    cmd.format = .hex;
                } else if (mach.testEqualMany8("raw", arg)) {
                    cmd.format = .raw;
                } else if (mach.testEqualMany8("plan9", arg)) {
                    cmd.format = .plan9;
                } else if (mach.testEqualMany8("nvptx", arg)) {
                    cmd.format = .nvptx;
                }
            } else if (mach.testEqualMany8("-idirafter", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.dirafter = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-isystem", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.system = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--libc", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.libc = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--library", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.library = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-I", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("--needed-library", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("--library-directory", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("--script", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.link_script = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--version-script", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.version_script = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--dynamic-linker", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.dynamic_linker = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--sysroot", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.sysroot = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--entry", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.entry = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-fLLD", arg)) {
                cmd.lld = true;
            } else if (mach.testEqualMany8("-fno-LLD", arg)) {
                cmd.lld = false;
            } else if (mach.testEqualMany8("-fcompiler-rt", arg)) {
                cmd.compiler_rt = true;
            } else if (mach.testEqualMany8("-fno-compiler-rt", arg)) {
                cmd.compiler_rt = false;
            } else if (mach.testEqualMany8("-rpath", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.rpath = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("-feach-lib-rpath", arg)) {
                cmd.each_lib_rpath = true;
            } else if (mach.testEqualMany8("-fno-each-lib-rpath", arg)) {
                cmd.each_lib_rpath = false;
            } else if (mach.testEqualMany8("-fallow-shlib-undefined", arg)) {
                cmd.allow_shlib_undefined = true;
            } else if (mach.testEqualMany8("-fno-allow-shlib-undefined", arg)) {
                cmd.allow_shlib_undefined = false;
            } else if (mach.testEqualMany8("--build-id", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("fast", arg)) {
                    cmd.build_id = .fast;
                } else if (mach.testEqualMany8("uuid", arg)) {
                    cmd.build_id = .uuid;
                } else if (mach.testEqualMany8("sha1", arg)) {
                    cmd.build_id = .sha1;
                } else if (mach.testEqualMany8("md5", arg)) {
                    cmd.build_id = .md5;
                } else if (mach.testEqualMany8("none", arg)) {
                    cmd.build_id = .none;
                }
            } else if (mach.testEqualMany8("--compress-debug-sections=zlib", arg)) {
                cmd.compress_debug_sections = true;
            } else if (mach.testEqualMany8("--compress-debug-sections=none", arg)) {
                cmd.compress_debug_sections = false;
            } else if (mach.testEqualMany8("--gc-sections", arg)) {
                cmd.gc_sections = true;
            } else if (mach.testEqualMany8("--no-gc-sections", arg)) {
                cmd.gc_sections = false;
            } else if (mach.testEqualMany8("-D", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("--mod", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("-lc", arg)) {
                cmd.link_libc = true;
            } else if (mach.testEqualMany8("-rdynamic", arg)) {
                cmd.rdynamic = true;
            } else if (mach.testEqualMany8("-dynamic", arg)) {
                cmd.dynamic = true;
            } else if (mach.testEqualMany8("-static", arg)) {
                cmd.static = true;
            } else if (mach.testEqualMany8("-Bsymbolic", arg)) {
                cmd.symbolic = true;
            } else if (mach.testEqualMany8("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("auto", arg)) {
                    cmd.color = .auto;
                } else if (mach.testEqualMany8("off", arg)) {
                    cmd.color = .off;
                } else if (mach.testEqualMany8("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mach.testEqualMany8("-ftime-report", arg)) {
                cmd.time_report = true;
            } else if (mach.testEqualMany8("-fstack-report", arg)) {
                cmd.stack_report = true;
            } else if (mach.testEqualMany8("--verbose-link", arg)) {
                cmd.verbose_link = true;
            } else if (mach.testEqualMany8("--verbose-cc", arg)) {
                cmd.verbose_cc = true;
            } else if (mach.testEqualMany8("--verbose-air", arg)) {
                cmd.verbose_air = true;
            } else if (mach.testEqualMany8("--verbose-mir", arg)) {
                cmd.verbose_mir = true;
            } else if (mach.testEqualMany8("--verbose-llvm-ir", arg)) {
                cmd.verbose_llvm_ir = true;
            } else if (mach.testEqualMany8("--verbose-cimport", arg)) {
                cmd.verbose_cimport = true;
            } else if (mach.testEqualMany8("--verbose-llvm-cpu-features", arg)) {
                cmd.verbose_llvm_cpu_features = true;
            } else if (mach.testEqualMany8("--debug-log", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.debug_log = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--debug-compile-errors", arg)) {
                cmd.debug_compiler_errors = true;
            } else if (mach.testEqualMany8("--debug-link-snapshot", arg)) {
                cmd.debug_link_snapshot = true;
            }
        }
    }
    pub usingnamespace types.GenericBuildCommand(BuildCommand);
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
    pub fn formatWrite(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatWriteBuf(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @as(*[4]u8, @ptrCast(buf + len)).* = "fmt\x00".*;
        len +%= 4;
        if (cmd.color) |color| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--color\x00".*;
            len +%= 8;
            @memcpy(buf + len, @tagName(color));
            len +%= @tagName(color).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.stdin) {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--stdin\x00".*;
            len +%= 8;
        }
        if (cmd.check) {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--check\x00".*;
            len +%= 8;
        }
        if (cmd.ast_check) {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--ast-check\x00".*;
            len +%= 12;
        }
        if (cmd.exclude) |exclude| {
            @as(*[10]u8, @ptrCast(buf + len)).* = "--exclude\x00".*;
            len +%= 10;
            @memcpy(buf + len, exclude);
            len +%= exclude.len;
            buf[len] = 0;
            len +%= 1;
        }
        len +%= pathname.formatWriteBuf(buf + len);
        return len;
    }
    pub fn formatLength(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatParseArgs(cmd: *FormatCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("auto", arg)) {
                    cmd.color = .auto;
                } else if (mach.testEqualMany8("off", arg)) {
                    cmd.color = .off;
                } else if (mach.testEqualMany8("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mach.testEqualMany8("--stdin", arg)) {
                cmd.stdin = true;
            } else if (mach.testEqualMany8("--check", arg)) {
                cmd.check = true;
            } else if (mach.testEqualMany8("--ast-check", arg)) {
                cmd.ast_check = true;
            } else if (mach.testEqualMany8("--exclude", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.exclude = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
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
    pub fn formatWrite(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
        array.writeFormat(types.Files{ .value = files });
    }
    pub fn formatWriteBuf(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @as(*[3]u8, @ptrCast(buf + len)).* = "ar\x00".*;
        len +%= 3;
        if (cmd.format) |format| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--format\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(format));
            len +%= @tagName(format).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.plugin) {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--plugin\x00".*;
            len +%= 9;
        }
        if (cmd.output) |output| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--output\x00".*;
            len +%= 9;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.thin) {
            @as(*[7]u8, @ptrCast(buf + len)).* = "--thin\x00".*;
            len +%= 7;
        }
        if (cmd.after) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "a".*;
            len +%= 1;
        }
        if (cmd.before) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "b".*;
            len +%= 1;
        }
        if (cmd.create) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "c".*;
            len +%= 1;
        }
        if (cmd.zero_ids) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "D".*;
            len +%= 1;
        }
        if (cmd.real_ids) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "U".*;
            len +%= 1;
        }
        if (cmd.append) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "L".*;
            len +%= 1;
        }
        if (cmd.preserve_dates) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "o".*;
            len +%= 1;
        }
        if (cmd.index) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "s".*;
            len +%= 1;
        }
        if (cmd.no_symbol_table) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "S".*;
            len +%= 1;
        }
        if (cmd.update) {
            @as(*[1]u8, @ptrCast(buf + len)).* = "u".*;
            len +%= 1;
        }
        @memcpy(buf + len, @tagName(cmd.operation));
        len +%= @tagName(cmd.operation).len;
        buf[len] = 0;
        len +%= 1;
        len +%= types.Files.formatWriteBuf(.{ .value = files }, buf + len);
        return len;
    }
    pub fn formatLength(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
        len +%= types.Files.formatLength(.{ .value = files });
        return len;
    }
    pub fn formatParseArgs(cmd: *ArchiveCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("--format", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("default", arg)) {
                    cmd.format = .default;
                } else if (mach.testEqualMany8("gnu", arg)) {
                    cmd.format = .gnu;
                } else if (mach.testEqualMany8("darwin", arg)) {
                    cmd.format = .darwin;
                } else if (mach.testEqualMany8("bsd", arg)) {
                    cmd.format = .bsd;
                } else if (mach.testEqualMany8("bigarchive", arg)) {
                    cmd.format = .bigarchive;
                }
            } else if (mach.testEqualMany8("--plugin", arg)) {
                cmd.plugin = true;
            } else if (mach.testEqualMany8("--output", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.output = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--thin", arg)) {
                cmd.thin = true;
            } else if (mach.testEqualMany8("a", arg)) {
                cmd.after = true;
            } else if (mach.testEqualMany8("b", arg)) {
                cmd.before = true;
            } else if (mach.testEqualMany8("c", arg)) {
                cmd.create = true;
            } else if (mach.testEqualMany8("D", arg)) {
                cmd.zero_ids = true;
            } else if (mach.testEqualMany8("U", arg)) {
                cmd.real_ids = true;
            } else if (mach.testEqualMany8("L", arg)) {
                cmd.append = true;
            } else if (mach.testEqualMany8("o", arg)) {
                cmd.preserve_dates = true;
            } else if (mach.testEqualMany8("s", arg)) {
                cmd.index = true;
            } else if (mach.testEqualMany8("S", arg)) {
                cmd.no_symbol_table = true;
            } else if (mach.testEqualMany8("u", arg)) {
                cmd.update = true;
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
    pub fn formatWrite(cmd: *ObjcopyCommand, zig_exe: []const u8, file: types.Path, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatWriteBuf(cmd: *ObjcopyCommand, zig_exe: []const u8, file: types.Path, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @as(*[8]u8, @ptrCast(buf + len)).* = "objcopy\x00".*;
        len +%= 8;
        if (cmd.output_target) |output_target| {
            @as(*[16]u8, @ptrCast(buf + len)).* = "--output-target\x00".*;
            len +%= 16;
            @memcpy(buf + len, output_target);
            len +%= output_target.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.only_section) |only_section| {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--only-section\x00".*;
            len +%= 15;
            @memcpy(buf + len, only_section);
            len +%= only_section.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.pad_to) |pad_to| {
            @as(*[9]u8, @ptrCast(buf + len)).* = "--pad-to\x00".*;
            len +%= 9;
            len +%= fmt.Type.Ud64.formatWriteBuf(.{ .value = pad_to }, buf + len);
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.strip_debug) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--strip-debug\x00".*;
            len +%= 14;
        }
        if (cmd.strip_all) {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--strip-all\x00".*;
            len +%= 12;
        }
        if (cmd.debug_only) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--only-keep-debug\x00".*;
            len +%= 18;
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            @as(*[20]u8, @ptrCast(buf + len)).* = "--add-gnu-debuglink\x00".*;
            len +%= 20;
            @memcpy(buf + len, add_gnu_debuglink);
            len +%= add_gnu_debuglink.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.extract_to) |extract_to| {
            @as(*[13]u8, @ptrCast(buf + len)).* = "--extract-to\x00".*;
            len +%= 13;
            @memcpy(buf + len, extract_to);
            len +%= extract_to.len;
            buf[len] = 0;
            len +%= 1;
        }
        len +%= file.formatWriteBuf(buf + len);
        return len;
    }
    pub fn formatLength(cmd: *ObjcopyCommand, zig_exe: []const u8, file: types.Path) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatParseArgs(cmd: *ObjcopyCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("--output-target", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.output_target = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--only-section", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.only_section = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--strip-debug", arg)) {
                cmd.strip_debug = true;
            } else if (mach.testEqualMany8("--strip-all", arg)) {
                cmd.strip_all = true;
            } else if (mach.testEqualMany8("--only-keep-debug", arg)) {
                cmd.debug_only = true;
            } else if (mach.testEqualMany8("--add-gnu-debuglink", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.add_gnu_debuglink = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
            } else if (mach.testEqualMany8("--extract-to", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.extract_to = mach.manyToSlice80(args[args_idx]);
                } else {
                    return;
                }
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
    pub fn formatWrite(cmd: *TableGenCommand, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatWriteBuf(cmd: *TableGenCommand, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        if (cmd.color) |color| {
            @as(*[8]u8, @ptrCast(buf + len)).* = "--color\x00".*;
            len +%= 8;
            @memcpy(buf + len, @tagName(color));
            len +%= @tagName(color).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            len +%= types.Macros.formatWriteBuf(.{ .value = macros }, buf + len);
        }
        if (cmd.include) |include| {
            for (include) |value| {
                @as(*[2]u8, @ptrCast(buf + len)).* = "-I".*;
                len +%= 2;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                @as(*[3]u8, @ptrCast(buf + len)).* = "-d\x00".*;
                len +%= 3;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.print_records) {
            @as(*[16]u8, @ptrCast(buf + len)).* = "--print-records\x00".*;
            len +%= 16;
        }
        if (cmd.print_detailed_records) {
            @as(*[25]u8, @ptrCast(buf + len)).* = "--print-detailed-records\x00".*;
            len +%= 25;
        }
        if (cmd.null_backend) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--null-backend\x00".*;
            len +%= 15;
        }
        if (cmd.dump_json) {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--dump-json\x00".*;
            len +%= 12;
        }
        if (cmd.gen_emitter) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--gen-emitter\x00".*;
            len +%= 14;
        }
        if (cmd.gen_register_info) {
            @as(*[20]u8, @ptrCast(buf + len)).* = "--gen-register-info\x00".*;
            len +%= 20;
        }
        if (cmd.gen_instr_info) {
            @as(*[17]u8, @ptrCast(buf + len)).* = "--gen-instr-info\x00".*;
            len +%= 17;
        }
        if (cmd.gen_instr_docs) {
            @as(*[17]u8, @ptrCast(buf + len)).* = "--gen-instr-docs\x00".*;
            len +%= 17;
        }
        if (cmd.gen_callingconv) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--gen-callingconv\x00".*;
            len +%= 18;
        }
        if (cmd.gen_asm_writer) {
            @as(*[17]u8, @ptrCast(buf + len)).* = "--gen-asm-writer\x00".*;
            len +%= 17;
        }
        if (cmd.gen_disassembler) {
            @as(*[19]u8, @ptrCast(buf + len)).* = "--gen-disassembler\x00".*;
            len +%= 19;
        }
        if (cmd.gen_pseudo_lowering) {
            @as(*[22]u8, @ptrCast(buf + len)).* = "--gen-pseudo-lowering\x00".*;
            len +%= 22;
        }
        if (cmd.gen_compress_inst_emitter) {
            @as(*[28]u8, @ptrCast(buf + len)).* = "--gen-compress-inst-emitter\x00".*;
            len +%= 28;
        }
        if (cmd.gen_asm_matcher) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--gen-asm-matcher\x00".*;
            len +%= 18;
        }
        if (cmd.gen_dag_isel) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--gen-dag-isel\x00".*;
            len +%= 15;
        }
        if (cmd.gen_dfa_packetizer) {
            @as(*[21]u8, @ptrCast(buf + len)).* = "--gen-dfa-packetizer\x00".*;
            len +%= 21;
        }
        if (cmd.gen_fast_isel) {
            @as(*[16]u8, @ptrCast(buf + len)).* = "--gen-fast-isel\x00".*;
            len +%= 16;
        }
        if (cmd.gen_subtarget) {
            @as(*[16]u8, @ptrCast(buf + len)).* = "--gen-subtarget\x00".*;
            len +%= 16;
        }
        if (cmd.gen_intrinsic_enums) {
            @as(*[22]u8, @ptrCast(buf + len)).* = "--gen-intrinsic-enums\x00".*;
            len +%= 22;
        }
        if (cmd.gen_intrinsic_impl) {
            @as(*[21]u8, @ptrCast(buf + len)).* = "--gen-intrinsic-impl\x00".*;
            len +%= 21;
        }
        if (cmd.print_enums) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--print-enums\x00".*;
            len +%= 14;
        }
        if (cmd.print_sets) {
            @as(*[13]u8, @ptrCast(buf + len)).* = "--print-sets\x00".*;
            len +%= 13;
        }
        if (cmd.gen_opt_parser_defs) {
            @as(*[22]u8, @ptrCast(buf + len)).* = "--gen-opt-parser-defs\x00".*;
            len +%= 22;
        }
        if (cmd.gen_opt_rst) {
            @as(*[14]u8, @ptrCast(buf + len)).* = "--gen-opt-rst\x00".*;
            len +%= 14;
        }
        if (cmd.gen_ctags) {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--gen-ctags\x00".*;
            len +%= 12;
        }
        if (cmd.gen_attrs) {
            @as(*[12]u8, @ptrCast(buf + len)).* = "--gen-attrs\x00".*;
            len +%= 12;
        }
        if (cmd.gen_searchable_tables) {
            @as(*[24]u8, @ptrCast(buf + len)).* = "--gen-searchable-tables\x00".*;
            len +%= 24;
        }
        if (cmd.gen_global_isel) {
            @as(*[18]u8, @ptrCast(buf + len)).* = "--gen-global-isel\x00".*;
            len +%= 18;
        }
        if (cmd.gen_global_isel_combiner) {
            @as(*[27]u8, @ptrCast(buf + len)).* = "--gen-global-isel-combiner\x00".*;
            len +%= 27;
        }
        if (cmd.gen_x86_EVEX2VEX_tables) {
            @as(*[26]u8, @ptrCast(buf + len)).* = "--gen-x86-EVEX2VEX-tables\x00".*;
            len +%= 26;
        }
        if (cmd.gen_x86_fold_tables) {
            @as(*[22]u8, @ptrCast(buf + len)).* = "--gen-x86-fold-tables\x00".*;
            len +%= 22;
        }
        if (cmd.gen_x86_mnemonic_tables) {
            @as(*[26]u8, @ptrCast(buf + len)).* = "--gen-x86-mnemonic-tables\x00".*;
            len +%= 26;
        }
        if (cmd.gen_register_bank) {
            @as(*[20]u8, @ptrCast(buf + len)).* = "--gen-register-bank\x00".*;
            len +%= 20;
        }
        if (cmd.gen_exegesis) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--gen-exegesis\x00".*;
            len +%= 15;
        }
        if (cmd.gen_automata) {
            @as(*[15]u8, @ptrCast(buf + len)).* = "--gen-automata\x00".*;
            len +%= 15;
        }
        if (cmd.gen_directive_decl) {
            @as(*[21]u8, @ptrCast(buf + len)).* = "--gen-directive-decl\x00".*;
            len +%= 21;
        }
        if (cmd.gen_directive_impl) {
            @as(*[21]u8, @ptrCast(buf + len)).* = "--gen-directive-impl\x00".*;
            len +%= 21;
        }
        if (cmd.gen_dxil_operation) {
            @as(*[21]u8, @ptrCast(buf + len)).* = "--gen-dxil-operation\x00".*;
            len +%= 21;
        }
        if (cmd.gen_riscv_target_def) {
            @as(*[23]u8, @ptrCast(buf + len)).* = "--gen-riscv-target_def\x00".*;
            len +%= 23;
        }
        if (cmd.output) |output| {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-o\x00".*;
            len +%= 3;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        return len;
    }
    pub fn formatLength(cmd: *TableGenCommand) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatParseArgs(cmd: *TableGenCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("--color", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mach.manyToSlice80(args[args_idx]);
                if (mach.testEqualMany8("auto", arg)) {
                    cmd.color = .auto;
                } else if (mach.testEqualMany8("off", arg)) {
                    cmd.color = .off;
                } else if (mach.testEqualMany8("on", arg)) {
                    cmd.color = .on;
                }
            } else if (mach.testEqualMany8("-I", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("-d", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("--print-records", arg)) {
                cmd.print_records = true;
            } else if (mach.testEqualMany8("--print-detailed-records", arg)) {
                cmd.print_detailed_records = true;
            } else if (mach.testEqualMany8("--null-backend", arg)) {
                cmd.null_backend = true;
            } else if (mach.testEqualMany8("--dump-json", arg)) {
                cmd.dump_json = true;
            } else if (mach.testEqualMany8("--gen-emitter", arg)) {
                cmd.gen_emitter = true;
            } else if (mach.testEqualMany8("--gen-register-info", arg)) {
                cmd.gen_register_info = true;
            } else if (mach.testEqualMany8("--gen-instr-info", arg)) {
                cmd.gen_instr_info = true;
            } else if (mach.testEqualMany8("--gen-instr-docs", arg)) {
                cmd.gen_instr_docs = true;
            } else if (mach.testEqualMany8("--gen-callingconv", arg)) {
                cmd.gen_callingconv = true;
            } else if (mach.testEqualMany8("--gen-asm-writer", arg)) {
                cmd.gen_asm_writer = true;
            } else if (mach.testEqualMany8("--gen-disassembler", arg)) {
                cmd.gen_disassembler = true;
            } else if (mach.testEqualMany8("--gen-pseudo-lowering", arg)) {
                cmd.gen_pseudo_lowering = true;
            } else if (mach.testEqualMany8("--gen-compress-inst-emitter", arg)) {
                cmd.gen_compress_inst_emitter = true;
            } else if (mach.testEqualMany8("--gen-asm-matcher", arg)) {
                cmd.gen_asm_matcher = true;
            } else if (mach.testEqualMany8("--gen-dag-isel", arg)) {
                cmd.gen_dag_isel = true;
            } else if (mach.testEqualMany8("--gen-dfa-packetizer", arg)) {
                cmd.gen_dfa_packetizer = true;
            } else if (mach.testEqualMany8("--gen-fast-isel", arg)) {
                cmd.gen_fast_isel = true;
            } else if (mach.testEqualMany8("--gen-subtarget", arg)) {
                cmd.gen_subtarget = true;
            } else if (mach.testEqualMany8("--gen-intrinsic-enums", arg)) {
                cmd.gen_intrinsic_enums = true;
            } else if (mach.testEqualMany8("--gen-intrinsic-impl", arg)) {
                cmd.gen_intrinsic_impl = true;
            } else if (mach.testEqualMany8("--print-enums", arg)) {
                cmd.print_enums = true;
            } else if (mach.testEqualMany8("--print-sets", arg)) {
                cmd.print_sets = true;
            } else if (mach.testEqualMany8("--gen-opt-parser-defs", arg)) {
                cmd.gen_opt_parser_defs = true;
            } else if (mach.testEqualMany8("--gen-opt-rst", arg)) {
                cmd.gen_opt_rst = true;
            } else if (mach.testEqualMany8("--gen-ctags", arg)) {
                cmd.gen_ctags = true;
            } else if (mach.testEqualMany8("--gen-attrs", arg)) {
                cmd.gen_attrs = true;
            } else if (mach.testEqualMany8("--gen-searchable-tables", arg)) {
                cmd.gen_searchable_tables = true;
            } else if (mach.testEqualMany8("--gen-global-isel", arg)) {
                cmd.gen_global_isel = true;
            } else if (mach.testEqualMany8("--gen-global-isel-combiner", arg)) {
                cmd.gen_global_isel_combiner = true;
            } else if (mach.testEqualMany8("--gen-x86-EVEX2VEX-tables", arg)) {
                cmd.gen_x86_EVEX2VEX_tables = true;
            } else if (mach.testEqualMany8("--gen-x86-fold-tables", arg)) {
                cmd.gen_x86_fold_tables = true;
            } else if (mach.testEqualMany8("--gen-x86-mnemonic-tables", arg)) {
                cmd.gen_x86_mnemonic_tables = true;
            } else if (mach.testEqualMany8("--gen-register-bank", arg)) {
                cmd.gen_register_bank = true;
            } else if (mach.testEqualMany8("--gen-exegesis", arg)) {
                cmd.gen_exegesis = true;
            } else if (mach.testEqualMany8("--gen-automata", arg)) {
                cmd.gen_automata = true;
            } else if (mach.testEqualMany8("--gen-directive-decl", arg)) {
                cmd.gen_directive_decl = true;
            } else if (mach.testEqualMany8("--gen-directive-impl", arg)) {
                cmd.gen_directive_impl = true;
            } else if (mach.testEqualMany8("--gen-dxil-operation", arg)) {
                cmd.gen_dxil_operation = true;
            } else if (mach.testEqualMany8("--gen-riscv-target_def", arg)) {
                cmd.gen_riscv_target_def = true;
            } else if (mach.testEqualMany8("-o", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
                } else {
                    arg = arg[2..];
                }
                cmd.output = arg;
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
    pub fn formatWrite(cmd: *HarecCommand, harec_exe: []const u8, array: anytype) void {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatWriteBuf(cmd: *HarecCommand, harec_exe: []const u8, buf: [*]u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
        var len: usize = 0;
        @memcpy(buf + len, harec_exe);
        len +%= harec_exe.len;
        buf[len] = 0;
        len +%= 1;
        if (cmd.arch) |arch| {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-a\x00".*;
            len +%= 3;
            @memcpy(buf + len, arch);
            len +%= arch.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.defs) |defs| {
            len +%= types.Macros.formatWriteBuf(.{ .value = defs }, buf + len);
        }
        if (cmd.output) |output| {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-o\x00".*;
            len +%= 3;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                @as(*[2]u8, @ptrCast(buf + len)).* = "-T".*;
                len +%= 2;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.typedefs) {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-t\x00".*;
            len +%= 3;
        }
        if (cmd.namespace) {
            @as(*[3]u8, @ptrCast(buf + len)).* = "-N\x00".*;
            len +%= 3;
        }
        return len;
    }
    pub fn formatLength(cmd: *HarecCommand, harec_exe: []const u8) u64 {
        @setRuntimeSafety(builtin.is_safe);
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
    pub fn formatParseArgs(cmd: *HarecCommand, allocator: anytype, args: [][*:0]u8) void {
        @setRuntimeSafety(false);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]const u8 = mach.manyToSlice80(args[args_idx]);
            if (mach.testEqualMany8("-a", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
                } else {
                    arg = arg[2..];
                }
                cmd.arch = arg;
            } else if (mach.testEqualMany8("-o", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
                } else {
                    arg = arg[2..];
                }
                cmd.output = arg;
            } else if (mach.testEqualMany8("-T", arg[0..2])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mach.manyToSlice80(args[args_idx]);
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
            } else if (mach.testEqualMany8("-t", arg)) {
                cmd.typedefs = true;
            } else if (mach.testEqualMany8("-N", arg)) {
                cmd.namespace = true;
            }
        }
    }
};
