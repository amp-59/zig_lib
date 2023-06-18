const ud64 = @import("../builtin.zig").fmt.ud64;
const fmt = @import("../fmt.zig");
const mach = @import("../mach.zig");
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
    listen: ?enum(u2) {
        none = 0,
        @"-" = 1,
        ipv4 = 2,
    } = null,
    /// <arch><sub>-<os>-<abi> see the targets command
    target: ?[]const u8 = null,
    /// Specify target CPU and feature set
    cpu: ?[]const u8 = null,
    /// Limit range of code and data virtual addresses
    code_model: ?enum(u3) {
        default = 0,
        tiny = 1,
        small = 2,
        kernel = 3,
        medium = 4,
        large = 5,
    } = null,
    /// Enable the "red-zone"
    red_zone: ?bool = null,
    /// Enable implicit builtin knowledge of functions
    builtin: ?bool = null,
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
    mode: ?@TypeOf(@import("builtin").mode) = null,
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
    format: ?enum(u4) {
        elf = 0,
        c = 1,
        wasm = 2,
        coff = 3,
        macho = 4,
        spirv = 5,
        plan9 = 6,
        hex = 7,
        raw = 8,
    } = null,
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
    build_id: ?enum(u8) {
        fast = 0,
        uuid = 1,
        sha1 = 2,
        md5 = 3,
        none = 4,
    } = null,
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
    z: ?[]const enum(u4) {
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
    color: ?enum(u2) {
        auto = 0,
        off = 1,
        on = 2,
    } = null,
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
        @setRuntimeSafety(safety);
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
        if (cmd.builtin) |builtin| {
            if (builtin) {
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
            array.writeFormat(types.Macros{ .value = macros });
        }
        if (cmd.modules) |modules| {
            array.writeFormat(types.Modules{ .value = modules });
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
        if (cmd.z) |z| {
            for (z) |value| {
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
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @ptrCast(*[6]u8, buf + len).* = "build-".*;
        len +%= 6;
        @memcpy(buf + len, @tagName(cmd.kind));
        len +%= @tagName(cmd.kind).len;
        buf[len] = 0;
        len +%= 1;
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[11]u8, buf + len).* = "-femit-bin\x3d".*;
                        len +%= 11;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[11]u8, buf + len).* = "-femit-bin\x00".*;
                        len +%= 11;
                    }
                },
                .no => {
                    @ptrCast(*[14]u8, buf + len).* = "-fno-emit-bin\x00".*;
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[11]u8, buf + len).* = "-femit-asm\x3d".*;
                        len +%= 11;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[11]u8, buf + len).* = "-femit-asm\x00".*;
                        len +%= 11;
                    }
                },
                .no => {
                    @ptrCast(*[14]u8, buf + len).* = "-fno-emit-asm\x00".*;
                    len +%= 14;
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-ir\x3d".*;
                        len +%= 15;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-ir\x00".*;
                        len +%= 15;
                    }
                },
                .no => {
                    @ptrCast(*[18]u8, buf + len).* = "-fno-emit-llvm-ir\x00".*;
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-bc\x3d".*;
                        len +%= 15;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[15]u8, buf + len).* = "-femit-llvm-bc\x00".*;
                        len +%= 15;
                    }
                },
                .no => {
                    @ptrCast(*[18]u8, buf + len).* = "-fno-emit-llvm-bc\x00".*;
                    len +%= 18;
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[9]u8, buf + len).* = "-femit-h\x3d".*;
                        len +%= 9;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[9]u8, buf + len).* = "-femit-h\x00".*;
                        len +%= 9;
                    }
                },
                .no => {
                    @ptrCast(*[12]u8, buf + len).* = "-fno-emit-h\x00".*;
                    len +%= 12;
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[12]u8, buf + len).* = "-femit-docs\x3d".*;
                        len +%= 12;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[12]u8, buf + len).* = "-femit-docs\x00".*;
                        len +%= 12;
                    }
                },
                .no => {
                    @ptrCast(*[15]u8, buf + len).* = "-fno-emit-docs\x00".*;
                    len +%= 15;
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[16]u8, buf + len).* = "-femit-analysis\x3d".*;
                        len +%= 16;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[16]u8, buf + len).* = "-femit-analysis\x00".*;
                        len +%= 16;
                    }
                },
                .no => {
                    @ptrCast(*[19]u8, buf + len).* = "-fno-emit-analysis\x00".*;
                    len +%= 19;
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes| {
                    if (yes) |arg| {
                        @ptrCast(*[14]u8, buf + len).* = "-femit-implib\x3d".*;
                        len +%= 14;
                        len +%= arg.formatWriteBuf(buf + len);
                    } else {
                        @ptrCast(*[14]u8, buf + len).* = "-femit-implib\x00".*;
                        len +%= 14;
                    }
                },
                .no => {
                    @ptrCast(*[17]u8, buf + len).* = "-fno-emit-implib\x00".*;
                    len +%= 17;
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            @ptrCast(*[12]u8, buf + len).* = "--cache-dir\x00".*;
            len +%= 12;
            @memcpy(buf + len, cache_root);
            len +%= cache_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            @ptrCast(*[19]u8, buf + len).* = "--global-cache-dir\x00".*;
            len +%= 19;
            @memcpy(buf + len, global_cache_root);
            len +%= global_cache_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            @ptrCast(*[14]u8, buf + len).* = "--zig-lib-dir\x00".*;
            len +%= 14;
            @memcpy(buf + len, zig_lib_root);
            len +%= zig_lib_root.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.listen) |listen| {
            @ptrCast(*[9]u8, buf + len).* = "--listen\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(listen));
            len +%= @tagName(listen).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.target) |target| {
            @ptrCast(*[8]u8, buf + len).* = "-target\x00".*;
            len +%= 8;
            @memcpy(buf + len, target);
            len +%= target.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.cpu) |cpu| {
            @ptrCast(*[6]u8, buf + len).* = "-mcpu\x00".*;
            len +%= 6;
            @memcpy(buf + len, cpu);
            len +%= cpu.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.code_model) |code_model| {
            @ptrCast(*[9]u8, buf + len).* = "-mcmodel\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(code_model));
            len +%= @tagName(code_model).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                @ptrCast(*[11]u8, buf + len).* = "-mred-zone\x00".*;
                len +%= 11;
            } else {
                @ptrCast(*[14]u8, buf + len).* = "-mno-red-zone\x00".*;
                len +%= 14;
            }
        }
        if (cmd.builtin) |builtin| {
            if (builtin) {
                @ptrCast(*[10]u8, buf + len).* = "-fbuiltin\x00".*;
                len +%= 10;
            } else {
                @ptrCast(*[13]u8, buf + len).* = "-fno-builtin\x00".*;
                len +%= 13;
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                @ptrCast(*[21]u8, buf + len).* = "-fomit-frame-pointer\x00".*;
                len +%= 21;
            } else {
                @ptrCast(*[24]u8, buf + len).* = "-fno-omit-frame-pointer\x00".*;
                len +%= 24;
            }
        }
        if (cmd.exec_model) |exec_model| {
            @ptrCast(*[13]u8, buf + len).* = "-mexec-model\x00".*;
            len +%= 13;
            @memcpy(buf + len, exec_model);
            len +%= exec_model.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.name) |name| {
            @ptrCast(*[7]u8, buf + len).* = "--name\x00".*;
            len +%= 7;
            @memcpy(buf + len, name);
            len +%= name.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    @ptrCast(*[9]u8, buf + len).* = "-fsoname\x00".*;
                    len +%= 9;
                    @memcpy(buf + len, arg);
                    len +%= arg.len;
                    buf[len] = 0;
                    len +%= 1;
                },
                .no => {
                    @ptrCast(*[12]u8, buf + len).* = "-fno-soname\x00".*;
                    len +%= 12;
                },
            }
        }
        if (cmd.mode) |mode| {
            @ptrCast(*[3]u8, buf + len).* = "-O\x00".*;
            len +%= 3;
            @memcpy(buf + len, @tagName(mode));
            len +%= @tagName(mode).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.passes) |passes| {
            @ptrCast(*[19]u8, buf + len).* = "-fopt-bisect-limit\x3d".*;
            len +%= 19;
            const s: []const u8 = ud64(passes).readAll();
            @memcpy(buf + len, s);
            len = len + s.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.main_pkg_path) |main_pkg_path| {
            @ptrCast(*[16]u8, buf + len).* = "--main-pkg-path\x00".*;
            len +%= 16;
            @memcpy(buf + len, main_pkg_path);
            len +%= main_pkg_path.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.pic) |pic| {
            if (pic) {
                @ptrCast(*[6]u8, buf + len).* = "-fPIC\x00".*;
                len +%= 6;
            } else {
                @ptrCast(*[9]u8, buf + len).* = "-fno-PIC\x00".*;
                len +%= 9;
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                @ptrCast(*[6]u8, buf + len).* = "-fPIE\x00".*;
                len +%= 6;
            } else {
                @ptrCast(*[9]u8, buf + len).* = "-fno-PIE\x00".*;
                len +%= 9;
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                @ptrCast(*[6]u8, buf + len).* = "-flto\x00".*;
                len +%= 6;
            } else {
                @ptrCast(*[9]u8, buf + len).* = "-fno-lto\x00".*;
                len +%= 9;
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                @ptrCast(*[14]u8, buf + len).* = "-fstack-check\x00".*;
                len +%= 14;
            } else {
                @ptrCast(*[17]u8, buf + len).* = "-fno-stack-check\x00".*;
                len +%= 17;
            }
        }
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                @ptrCast(*[14]u8, buf + len).* = "-fstack-check\x00".*;
                len +%= 14;
            } else {
                @ptrCast(*[21]u8, buf + len).* = "-fno-stack-protector\x00".*;
                len +%= 21;
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                @ptrCast(*[13]u8, buf + len).* = "-fsanitize-c\x00".*;
                len +%= 13;
            } else {
                @ptrCast(*[16]u8, buf + len).* = "-fno-sanitize-c\x00".*;
                len +%= 16;
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                @ptrCast(*[11]u8, buf + len).* = "-fvalgrind\x00".*;
                len +%= 11;
            } else {
                @ptrCast(*[14]u8, buf + len).* = "-fno-valgrind\x00".*;
                len +%= 14;
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                @ptrCast(*[18]u8, buf + len).* = "-fsanitize-thread\x00".*;
                len +%= 18;
            } else {
                @ptrCast(*[21]u8, buf + len).* = "-fno-sanitize-thread\x00".*;
                len +%= 21;
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                @ptrCast(*[16]u8, buf + len).* = "-funwind-tables\x00".*;
                len +%= 16;
            } else {
                @ptrCast(*[19]u8, buf + len).* = "-fno-unwind-tables\x00".*;
                len +%= 19;
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                @ptrCast(*[7]u8, buf + len).* = "-fLLVM\x00".*;
                len +%= 7;
            } else {
                @ptrCast(*[10]u8, buf + len).* = "-fno-LLVM\x00".*;
                len +%= 10;
            }
        }
        if (cmd.clang) |clang| {
            if (clang) {
                @ptrCast(*[8]u8, buf + len).* = "-fClang\x00".*;
                len +%= 8;
            } else {
                @ptrCast(*[11]u8, buf + len).* = "-fno-Clang\x00".*;
                len +%= 11;
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                @ptrCast(*[18]u8, buf + len).* = "-freference-trace\x00".*;
                len +%= 18;
            } else {
                @ptrCast(*[21]u8, buf + len).* = "-fno-reference-trace\x00".*;
                len +%= 21;
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                @ptrCast(*[16]u8, buf + len).* = "-ferror-tracing\x00".*;
                len +%= 16;
            } else {
                @ptrCast(*[19]u8, buf + len).* = "-fno-error-tracing\x00".*;
                len +%= 19;
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                @ptrCast(*[18]u8, buf + len).* = "-fsingle-threaded\x00".*;
                len +%= 18;
            } else {
                @ptrCast(*[21]u8, buf + len).* = "-fno-single-threaded\x00".*;
                len +%= 21;
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                @ptrCast(*[20]u8, buf + len).* = "-ffunction-sections\x00".*;
                len +%= 20;
            } else {
                @ptrCast(*[23]u8, buf + len).* = "-fno-function-sections\x00".*;
                len +%= 23;
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                @ptrCast(*[8]u8, buf + len).* = "-fstrip\x00".*;
                len +%= 8;
            } else {
                @ptrCast(*[11]u8, buf + len).* = "-fno-strip\x00".*;
                len +%= 11;
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                @ptrCast(*[19]u8, buf + len).* = "-fformatted-panics\x00".*;
                len +%= 19;
            } else {
                @ptrCast(*[22]u8, buf + len).* = "-fno-formatted-panics\x00".*;
                len +%= 22;
            }
        }
        if (cmd.format) |format| {
            @ptrCast(*[6]u8, buf + len).* = "-ofmt\x3d".*;
            len +%= 6;
            @memcpy(buf + len, @tagName(format));
            len +%= @tagName(format).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.dirafter) |dirafter| {
            @ptrCast(*[11]u8, buf + len).* = "-idirafter\x00".*;
            len +%= 11;
            @memcpy(buf + len, dirafter);
            len +%= dirafter.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.system) |system| {
            @ptrCast(*[9]u8, buf + len).* = "-isystem\x00".*;
            len +%= 9;
            @memcpy(buf + len, system);
            len +%= system.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.libc) |libc| {
            @ptrCast(*[7]u8, buf + len).* = "--libc\x00".*;
            len +%= 7;
            @memcpy(buf + len, libc);
            len +%= libc.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.library) |library| {
            @ptrCast(*[10]u8, buf + len).* = "--library\x00".*;
            len +%= 10;
            @memcpy(buf + len, library);
            len +%= library.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                @ptrCast(*[3]u8, buf + len).* = "-I\x00".*;
                len +%= 3;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                @ptrCast(*[17]u8, buf + len).* = "--needed-library\x00".*;
                len +%= 17;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                @ptrCast(*[20]u8, buf + len).* = "--library-directory\x00".*;
                len +%= 20;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.link_script) |link_script| {
            @ptrCast(*[9]u8, buf + len).* = "--script\x00".*;
            len +%= 9;
            @memcpy(buf + len, link_script);
            len +%= link_script.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.version_script) |version_script| {
            @ptrCast(*[17]u8, buf + len).* = "--version-script\x00".*;
            len +%= 17;
            @memcpy(buf + len, version_script);
            len +%= version_script.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            @ptrCast(*[17]u8, buf + len).* = "--dynamic-linker\x00".*;
            len +%= 17;
            @memcpy(buf + len, dynamic_linker);
            len +%= dynamic_linker.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.sysroot) |sysroot| {
            @ptrCast(*[10]u8, buf + len).* = "--sysroot\x00".*;
            len +%= 10;
            @memcpy(buf + len, sysroot);
            len +%= sysroot.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.entry) |entry| {
            @ptrCast(*[8]u8, buf + len).* = "--entry\x00".*;
            len +%= 8;
            @memcpy(buf + len, entry);
            len +%= entry.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.lld) |lld| {
            if (lld) {
                @ptrCast(*[6]u8, buf + len).* = "-fLLD\x00".*;
                len +%= 6;
            } else {
                @ptrCast(*[9]u8, buf + len).* = "-fno-LLD\x00".*;
                len +%= 9;
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                @ptrCast(*[14]u8, buf + len).* = "-fcompiler-rt\x00".*;
                len +%= 14;
            } else {
                @ptrCast(*[17]u8, buf + len).* = "-fno-compiler-rt\x00".*;
                len +%= 17;
            }
        }
        if (cmd.rpath) |rpath| {
            @ptrCast(*[7]u8, buf + len).* = "-rpath\x00".*;
            len +%= 7;
            @memcpy(buf + len, rpath);
            len +%= rpath.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.each_lib_rpath) |each_lib_rpath| {
            if (each_lib_rpath) {
                @ptrCast(*[17]u8, buf + len).* = "-feach-lib-rpath\x00".*;
                len +%= 17;
            } else {
                @ptrCast(*[20]u8, buf + len).* = "-fno-each-lib-rpath\x00".*;
                len +%= 20;
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                @ptrCast(*[24]u8, buf + len).* = "-fallow-shlib-undefined\x00".*;
                len +%= 24;
            } else {
                @ptrCast(*[27]u8, buf + len).* = "-fno-allow-shlib-undefined\x00".*;
                len +%= 27;
            }
        }
        if (cmd.build_id) |build_id| {
            @ptrCast(*[11]u8, buf + len).* = "--build-id\x3d".*;
            len +%= 11;
            @memcpy(buf + len, @tagName(build_id));
            len +%= @tagName(build_id).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.compress_debug_sections) |compress_debug_sections| {
            if (compress_debug_sections) {
                @ptrCast(*[31]u8, buf + len).* = "--compress-debug-sections=zlib\x00".*;
                len +%= 31;
            } else {
                @ptrCast(*[31]u8, buf + len).* = "--compress-debug-sections=none\x00".*;
                len +%= 31;
            }
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                @ptrCast(*[14]u8, buf + len).* = "--gc-sections\x00".*;
                len +%= 14;
            } else {
                @ptrCast(*[17]u8, buf + len).* = "--no-gc-sections\x00".*;
                len +%= 17;
            }
        }
        if (cmd.stack) |stack| {
            @ptrCast(*[8]u8, buf + len).* = "--stack\x00".*;
            len +%= 8;
            const s: []const u8 = ud64(stack).readAll();
            @memcpy(buf + len, s);
            len = len + s.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.image_base) |image_base| {
            @ptrCast(*[13]u8, buf + len).* = "--image-base\x00".*;
            len +%= 13;
            const s: []const u8 = ud64(image_base).readAll();
            @memcpy(buf + len, s);
            len = len + s.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            len +%= types.Macros.formatWriteBuf(.{ .value = macros }, buf + len);
        }
        if (cmd.modules) |modules| {
            len +%= types.Modules.formatWriteBuf(.{ .value = modules }, buf + len);
        }
        if (cmd.dependencies) |dependencies| {
            len +%= types.ModuleDependencies.formatWriteBuf(.{ .value = dependencies }, buf + len);
        }
        if (cmd.cflags) |cflags| {
            len +%= types.CFlags.formatWriteBuf(.{ .value = cflags }, buf + len);
        }
        if (cmd.link_libc) {
            @ptrCast(*[4]u8, buf + len).* = "-lc\x00".*;
            len +%= 4;
        }
        if (cmd.rdynamic) {
            @ptrCast(*[10]u8, buf + len).* = "-rdynamic\x00".*;
            len +%= 10;
        }
        if (cmd.dynamic) {
            @ptrCast(*[9]u8, buf + len).* = "-dynamic\x00".*;
            len +%= 9;
        }
        if (cmd.static) {
            @ptrCast(*[8]u8, buf + len).* = "-static\x00".*;
            len +%= 8;
        }
        if (cmd.symbolic) {
            @ptrCast(*[11]u8, buf + len).* = "-Bsymbolic\x00".*;
            len +%= 11;
        }
        if (cmd.z) |z| {
            for (z) |value| {
                @ptrCast(*[3]u8, buf + len).* = "-z\x00".*;
                len +%= 3;
                @memcpy(buf + len, @tagName(value));
                len +%= @tagName(value).len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        len +%= types.Files.formatWriteBuf(.{ .value = files }, buf + len);
        if (cmd.color) |color| {
            @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
            len +%= 8;
            @memcpy(buf + len, @tagName(color));
            len +%= @tagName(color).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.time_report) {
            @ptrCast(*[14]u8, buf + len).* = "-ftime-report\x00".*;
            len +%= 14;
        }
        if (cmd.stack_report) {
            @ptrCast(*[15]u8, buf + len).* = "-fstack-report\x00".*;
            len +%= 15;
        }
        if (cmd.verbose_link) {
            @ptrCast(*[15]u8, buf + len).* = "--verbose-link\x00".*;
            len +%= 15;
        }
        if (cmd.verbose_cc) {
            @ptrCast(*[13]u8, buf + len).* = "--verbose-cc\x00".*;
            len +%= 13;
        }
        if (cmd.verbose_air) {
            @ptrCast(*[14]u8, buf + len).* = "--verbose-air\x00".*;
            len +%= 14;
        }
        if (cmd.verbose_mir) {
            @ptrCast(*[14]u8, buf + len).* = "--verbose-mir\x00".*;
            len +%= 14;
        }
        if (cmd.verbose_llvm_ir) {
            @ptrCast(*[18]u8, buf + len).* = "--verbose-llvm-ir\x00".*;
            len +%= 18;
        }
        if (cmd.verbose_cimport) {
            @ptrCast(*[18]u8, buf + len).* = "--verbose-cimport\x00".*;
            len +%= 18;
        }
        if (cmd.verbose_llvm_cpu_features) {
            @ptrCast(*[28]u8, buf + len).* = "--verbose-llvm-cpu-features\x00".*;
            len +%= 28;
        }
        if (cmd.debug_log) |debug_log| {
            @ptrCast(*[12]u8, buf + len).* = "--debug-log\x00".*;
            len +%= 12;
            @memcpy(buf + len, debug_log);
            len +%= debug_log.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.debug_compiler_errors) {
            @ptrCast(*[23]u8, buf + len).* = "--debug-compile-errors\x00".*;
            len +%= 23;
        }
        if (cmd.debug_link_snapshot) {
            @ptrCast(*[22]u8, buf + len).* = "--debug-link-snapshot\x00".*;
            len +%= 22;
        }
        return len;
    }
    pub fn formatLength(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
        if (cmd.builtin) |builtin| {
            if (builtin) {
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
            len +%= ud64(passes).readAll().len;
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
            len +%= ud64(stack).readAll().len;
            len +%= 1;
        }
        if (cmd.image_base) |image_base| {
            len +%= 13;
            len +%= ud64(image_base).readAll().len;
            len +%= 1;
        }
        if (cmd.macros) |macros| {
            len +%= types.Macros.formatLength(.{ .value = macros });
        }
        if (cmd.modules) |modules| {
            len +%= types.Modules.formatLength(.{ .value = modules });
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
        if (cmd.z) |z| {
            for (z) |value| {
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
};
pub const FormatCommand = struct {
    /// Enable or disable colored error messages
    color: ?enum(u2) {
        auto = 0,
        off = 1,
        on = 2,
    } = null,
    /// Format code from stdin; output to stdout
    stdin: bool = false,
    /// List non-conforming files and exit with an error if the list is non-empty
    check: bool = false,
    /// Run zig ast-check on every file
    ast_check: bool = false,
    /// Exclude file or directory from formatting
    exclude: ?[]const u8 = null,
    pub fn formatWrite(cmd: *FormatCommand, zig_exe: []const u8, root_path: types.Path, array: anytype) void {
        @setRuntimeSafety(safety);
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
        array.writeFormat(root_path);
    }
    pub fn formatWriteBuf(cmd: *FormatCommand, zig_exe: []const u8, root_path: types.Path, buf: [*]u8) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @ptrCast(*[4]u8, buf + len).* = "fmt\x00".*;
        len +%= 4;
        if (cmd.color) |color| {
            @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
            len +%= 8;
            @memcpy(buf + len, @tagName(color));
            len +%= @tagName(color).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.stdin) {
            @ptrCast(*[8]u8, buf + len).* = "--stdin\x00".*;
            len +%= 8;
        }
        if (cmd.check) {
            @ptrCast(*[8]u8, buf + len).* = "--check\x00".*;
            len +%= 8;
        }
        if (cmd.ast_check) {
            @ptrCast(*[12]u8, buf + len).* = "--ast-check\x00".*;
            len +%= 12;
        }
        if (cmd.exclude) |exclude| {
            @ptrCast(*[10]u8, buf + len).* = "--exclude\x00".*;
            len +%= 10;
            @memcpy(buf + len, exclude);
            len +%= exclude.len;
            buf[len] = 0;
            len +%= 1;
        }
        len +%= root_path.formatWriteBuf(buf + len);
        return len;
    }
    pub fn formatLength(cmd: *FormatCommand, zig_exe: []const u8, root_path: types.Path) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
        len +%= root_path.formatLength();
        return len;
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
        @setRuntimeSafety(safety);
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
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        @memcpy(buf + len, zig_exe);
        len +%= zig_exe.len;
        buf[len] = 0;
        len +%= 1;
        @ptrCast(*[3]u8, buf + len).* = "ar\x00".*;
        len +%= 3;
        if (cmd.format) |format| {
            @ptrCast(*[9]u8, buf + len).* = "--format\x00".*;
            len +%= 9;
            @memcpy(buf + len, @tagName(format));
            len +%= @tagName(format).len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.plugin) {
            @ptrCast(*[9]u8, buf + len).* = "--plugin\x00".*;
            len +%= 9;
        }
        if (cmd.output) |output| {
            @ptrCast(*[9]u8, buf + len).* = "--output\x00".*;
            len +%= 9;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.thin) {
            @ptrCast(*[7]u8, buf + len).* = "--thin\x00".*;
            len +%= 7;
        }
        if (cmd.after) {
            @ptrCast(*[1]u8, buf + len).* = "a".*;
            len +%= 1;
        }
        if (cmd.before) {
            @ptrCast(*[1]u8, buf + len).* = "b".*;
            len +%= 1;
        }
        if (cmd.create) {
            @ptrCast(*[1]u8, buf + len).* = "c".*;
            len +%= 1;
        }
        if (cmd.zero_ids) {
            @ptrCast(*[1]u8, buf + len).* = "D".*;
            len +%= 1;
        }
        if (cmd.real_ids) {
            @ptrCast(*[1]u8, buf + len).* = "U".*;
            len +%= 1;
        }
        if (cmd.append) {
            @ptrCast(*[1]u8, buf + len).* = "L".*;
            len +%= 1;
        }
        if (cmd.preserve_dates) {
            @ptrCast(*[1]u8, buf + len).* = "o".*;
            len +%= 1;
        }
        if (cmd.index) {
            @ptrCast(*[1]u8, buf + len).* = "s".*;
            len +%= 1;
        }
        if (cmd.no_symbol_table) {
            @ptrCast(*[1]u8, buf + len).* = "S".*;
            len +%= 1;
        }
        if (cmd.update) {
            @ptrCast(*[1]u8, buf + len).* = "u".*;
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
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
    pub fn formatWrite(cmd: *ObjcopyCommand, array: anytype) void {
        @setRuntimeSafety(safety);
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
    }
    pub fn formatWriteBuf(cmd: *ObjcopyCommand, buf: [*]u8) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        if (cmd.output_target) |output_target| {
            @ptrCast(*[16]u8, buf + len).* = "--output-target\x00".*;
            len +%= 16;
            @memcpy(buf + len, output_target);
            len +%= output_target.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.only_section) |only_section| {
            @ptrCast(*[15]u8, buf + len).* = "--only-section\x00".*;
            len +%= 15;
            @memcpy(buf + len, only_section);
            len +%= only_section.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.pad_to) |pad_to| {
            @ptrCast(*[9]u8, buf + len).* = "--pad-to\x00".*;
            len +%= 9;
            const s: []const u8 = ud64(pad_to).readAll();
            @memcpy(buf + len, s);
            len = len + s.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.strip_debug) {
            @ptrCast(*[14]u8, buf + len).* = "--strip-debug\x00".*;
            len +%= 14;
        }
        if (cmd.strip_all) {
            @ptrCast(*[12]u8, buf + len).* = "--strip-all\x00".*;
            len +%= 12;
        }
        if (cmd.debug_only) {
            @ptrCast(*[18]u8, buf + len).* = "--only-keep-debug\x00".*;
            len +%= 18;
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            @ptrCast(*[20]u8, buf + len).* = "--add-gnu-debuglink\x00".*;
            len +%= 20;
            @memcpy(buf + len, add_gnu_debuglink);
            len +%= add_gnu_debuglink.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.extract_to) |extract_to| {
            @ptrCast(*[13]u8, buf + len).* = "--extract-to\x00".*;
            len +%= 13;
            @memcpy(buf + len, extract_to);
            len +%= extract_to.len;
            buf[len] = 0;
            len +%= 1;
        }
        return len;
    }
    pub fn formatLength(cmd: *ObjcopyCommand) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
            len +%= ud64(pad_to).readAll().len;
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
        return len;
    }
};
pub const TableGenCommand = struct {
    /// Use colors in output (default=autodetect)
    color: ?enum(u2) {
        auto = 0,
        off = 1,
        on = 2,
    } = null,
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
        @setRuntimeSafety(safety);
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
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        if (cmd.color) |color| {
            @ptrCast(*[8]u8, buf + len).* = "--color\x00".*;
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
                @ptrCast(*[2]u8, buf + len).* = "-I".*;
                len +%= 2;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                @ptrCast(*[3]u8, buf + len).* = "-d\x00".*;
                len +%= 3;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.print_records) {
            @ptrCast(*[16]u8, buf + len).* = "--print-records\x00".*;
            len +%= 16;
        }
        if (cmd.print_detailed_records) {
            @ptrCast(*[25]u8, buf + len).* = "--print-detailed-records\x00".*;
            len +%= 25;
        }
        if (cmd.null_backend) {
            @ptrCast(*[15]u8, buf + len).* = "--null-backend\x00".*;
            len +%= 15;
        }
        if (cmd.dump_json) {
            @ptrCast(*[12]u8, buf + len).* = "--dump-json\x00".*;
            len +%= 12;
        }
        if (cmd.gen_emitter) {
            @ptrCast(*[14]u8, buf + len).* = "--gen-emitter\x00".*;
            len +%= 14;
        }
        if (cmd.gen_register_info) {
            @ptrCast(*[20]u8, buf + len).* = "--gen-register-info\x00".*;
            len +%= 20;
        }
        if (cmd.gen_instr_info) {
            @ptrCast(*[17]u8, buf + len).* = "--gen-instr-info\x00".*;
            len +%= 17;
        }
        if (cmd.gen_instr_docs) {
            @ptrCast(*[17]u8, buf + len).* = "--gen-instr-docs\x00".*;
            len +%= 17;
        }
        if (cmd.gen_callingconv) {
            @ptrCast(*[18]u8, buf + len).* = "--gen-callingconv\x00".*;
            len +%= 18;
        }
        if (cmd.gen_asm_writer) {
            @ptrCast(*[17]u8, buf + len).* = "--gen-asm-writer\x00".*;
            len +%= 17;
        }
        if (cmd.gen_disassembler) {
            @ptrCast(*[19]u8, buf + len).* = "--gen-disassembler\x00".*;
            len +%= 19;
        }
        if (cmd.gen_pseudo_lowering) {
            @ptrCast(*[22]u8, buf + len).* = "--gen-pseudo-lowering\x00".*;
            len +%= 22;
        }
        if (cmd.gen_compress_inst_emitter) {
            @ptrCast(*[28]u8, buf + len).* = "--gen-compress-inst-emitter\x00".*;
            len +%= 28;
        }
        if (cmd.gen_asm_matcher) {
            @ptrCast(*[18]u8, buf + len).* = "--gen-asm-matcher\x00".*;
            len +%= 18;
        }
        if (cmd.gen_dag_isel) {
            @ptrCast(*[15]u8, buf + len).* = "--gen-dag-isel\x00".*;
            len +%= 15;
        }
        if (cmd.gen_dfa_packetizer) {
            @ptrCast(*[21]u8, buf + len).* = "--gen-dfa-packetizer\x00".*;
            len +%= 21;
        }
        if (cmd.gen_fast_isel) {
            @ptrCast(*[16]u8, buf + len).* = "--gen-fast-isel\x00".*;
            len +%= 16;
        }
        if (cmd.gen_subtarget) {
            @ptrCast(*[16]u8, buf + len).* = "--gen-subtarget\x00".*;
            len +%= 16;
        }
        if (cmd.gen_intrinsic_enums) {
            @ptrCast(*[22]u8, buf + len).* = "--gen-intrinsic-enums\x00".*;
            len +%= 22;
        }
        if (cmd.gen_intrinsic_impl) {
            @ptrCast(*[21]u8, buf + len).* = "--gen-intrinsic-impl\x00".*;
            len +%= 21;
        }
        if (cmd.print_enums) {
            @ptrCast(*[14]u8, buf + len).* = "--print-enums\x00".*;
            len +%= 14;
        }
        if (cmd.print_sets) {
            @ptrCast(*[13]u8, buf + len).* = "--print-sets\x00".*;
            len +%= 13;
        }
        if (cmd.gen_opt_parser_defs) {
            @ptrCast(*[22]u8, buf + len).* = "--gen-opt-parser-defs\x00".*;
            len +%= 22;
        }
        if (cmd.gen_opt_rst) {
            @ptrCast(*[14]u8, buf + len).* = "--gen-opt-rst\x00".*;
            len +%= 14;
        }
        if (cmd.gen_ctags) {
            @ptrCast(*[12]u8, buf + len).* = "--gen-ctags\x00".*;
            len +%= 12;
        }
        if (cmd.gen_attrs) {
            @ptrCast(*[12]u8, buf + len).* = "--gen-attrs\x00".*;
            len +%= 12;
        }
        if (cmd.gen_searchable_tables) {
            @ptrCast(*[24]u8, buf + len).* = "--gen-searchable-tables\x00".*;
            len +%= 24;
        }
        if (cmd.gen_global_isel) {
            @ptrCast(*[18]u8, buf + len).* = "--gen-global-isel\x00".*;
            len +%= 18;
        }
        if (cmd.gen_global_isel_combiner) {
            @ptrCast(*[27]u8, buf + len).* = "--gen-global-isel-combiner\x00".*;
            len +%= 27;
        }
        if (cmd.gen_x86_EVEX2VEX_tables) {
            @ptrCast(*[26]u8, buf + len).* = "--gen-x86-EVEX2VEX-tables\x00".*;
            len +%= 26;
        }
        if (cmd.gen_x86_fold_tables) {
            @ptrCast(*[22]u8, buf + len).* = "--gen-x86-fold-tables\x00".*;
            len +%= 22;
        }
        if (cmd.gen_x86_mnemonic_tables) {
            @ptrCast(*[26]u8, buf + len).* = "--gen-x86-mnemonic-tables\x00".*;
            len +%= 26;
        }
        if (cmd.gen_register_bank) {
            @ptrCast(*[20]u8, buf + len).* = "--gen-register-bank\x00".*;
            len +%= 20;
        }
        if (cmd.gen_exegesis) {
            @ptrCast(*[15]u8, buf + len).* = "--gen-exegesis\x00".*;
            len +%= 15;
        }
        if (cmd.gen_automata) {
            @ptrCast(*[15]u8, buf + len).* = "--gen-automata\x00".*;
            len +%= 15;
        }
        if (cmd.gen_directive_decl) {
            @ptrCast(*[21]u8, buf + len).* = "--gen-directive-decl\x00".*;
            len +%= 21;
        }
        if (cmd.gen_directive_impl) {
            @ptrCast(*[21]u8, buf + len).* = "--gen-directive-impl\x00".*;
            len +%= 21;
        }
        if (cmd.gen_dxil_operation) {
            @ptrCast(*[21]u8, buf + len).* = "--gen-dxil-operation\x00".*;
            len +%= 21;
        }
        if (cmd.gen_riscv_target_def) {
            @ptrCast(*[23]u8, buf + len).* = "--gen-riscv-target_def\x00".*;
            len +%= 23;
        }
        if (cmd.output) |output| {
            @ptrCast(*[3]u8, buf + len).* = "-o\x00".*;
            len +%= 3;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        return len;
    }
    pub fn formatLength(cmd: *TableGenCommand) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
        @setRuntimeSafety(safety);
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
        @setRuntimeSafety(safety);
        var len: u64 = 0;
        @memcpy(buf + len, harec_exe);
        len +%= harec_exe.len;
        buf[len] = 0;
        len +%= 1;
        if (cmd.arch) |arch| {
            @ptrCast(*[3]u8, buf + len).* = "-a\x00".*;
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
            @ptrCast(*[3]u8, buf + len).* = "-o\x00".*;
            len +%= 3;
            @memcpy(buf + len, output);
            len +%= output.len;
            buf[len] = 0;
            len +%= 1;
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                @ptrCast(*[2]u8, buf + len).* = "-T".*;
                len +%= 2;
                @memcpy(buf + len, value);
                len +%= value.len;
                buf[len] = 0;
                len +%= 1;
            }
        }
        if (cmd.typedefs) {
            @ptrCast(*[3]u8, buf + len).* = "-t\x00".*;
            len +%= 3;
        }
        if (cmd.namespace) {
            @ptrCast(*[3]u8, buf + len).* = "-N\x00".*;
            len +%= 3;
        }
        return len;
    }
    pub fn formatLength(cmd: *HarecCommand, harec_exe: []const u8) u64 {
        @setRuntimeSafety(safety);
        var len: u64 = 0;
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
};
