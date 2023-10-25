const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const debug = @import("../debug.zig");
const parse = @import("../parse.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");
const tasks = @import("./tasks.zig");
pub const PathUnion = union(enum) {
    yes: ?types.Path,
    no,
};
pub const BuildCommand = struct {
    kind: types.BinaryOutput,
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
    main_mod_path: ?[]const u8 = null,
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
    /// Places each function in a separate section
    function_sections: ?bool = null,
    /// Places data in separate sections
    data_sections: ?bool = null,
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
    /// Set extra flags for the next positional .rc source files
    rcflags: ?[]const []const u8 = null,
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
    link_flags: ?[]const enum(u4) {
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
    /// Enable experimental feature: incremental compilation
    incremental_compilation: bool = false,
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, zig_exe);
        ptr[0] = 0;
        ptr += 1;
        ptr[0..6].* = "build-".*;
        ptr += 6;
        ptr = fmt.strcpyEqu(ptr, @tagName(cmd.kind));
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
            ptr = fmt.strcpyEqu(ptr, cache_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            ptr[0..19].* = "--global-cache-dir\x00".*;
            ptr += 19;
            ptr = fmt.strcpyEqu(ptr, global_cache_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            ptr[0..14].* = "--zig-lib-dir\x00".*;
            ptr += 14;
            ptr = fmt.strcpyEqu(ptr, zig_lib_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.listen) |listen| {
            ptr[0..9].* = "--listen\x00".*;
            ptr += 9;
            ptr = fmt.strcpyEqu(ptr, @tagName(listen));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.target) |target| {
            ptr[0..8].* = "-target\x00".*;
            ptr += 8;
            ptr = fmt.strcpyEqu(ptr, target);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.cpu) |cpu| {
            ptr[0..6].* = "-mcpu\x00".*;
            ptr += 6;
            ptr = fmt.strcpyEqu(ptr, cpu);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.code_model) |code_model| {
            ptr[0..9].* = "-mcmodel\x00".*;
            ptr += 9;
            ptr = fmt.strcpyEqu(ptr, @tagName(code_model));
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
            ptr = fmt.strcpyEqu(ptr, exec_model);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.name) |name| {
            ptr[0..7].* = "--name\x00".*;
            ptr += 7;
            ptr = fmt.strcpyEqu(ptr, name);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    ptr[0..9].* = "-fsoname\x00".*;
                    ptr += 9;
                    ptr = fmt.strcpyEqu(ptr, arg);
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
            ptr = fmt.strcpyEqu(ptr, @tagName(mode));
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
        if (cmd.main_mod_path) |main_mod_path| {
            ptr[0..16].* = "--main-mod-path\x00".*;
            ptr += 16;
            ptr = fmt.strcpyEqu(ptr, main_mod_path);
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
        if (cmd.data_sections) |data_sections| {
            if (data_sections) {
                ptr[0..16].* = "-fdata-sections\x00".*;
                ptr += 16;
            } else {
                ptr[0..19].* = "-fno-data-sections\x00".*;
                ptr += 19;
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
            ptr = fmt.strcpyEqu(ptr, @tagName(format));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.dirafter) |dirafter| {
            ptr[0..11].* = "-idirafter\x00".*;
            ptr += 11;
            ptr = fmt.strcpyEqu(ptr, dirafter);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.system) |system| {
            ptr[0..9].* = "-isystem\x00".*;
            ptr += 9;
            ptr = fmt.strcpyEqu(ptr, system);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.libc) |libc| {
            ptr[0..7].* = "--libc\x00".*;
            ptr += 7;
            ptr = fmt.strcpyEqu(ptr, libc);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.library) |library| {
            ptr[0..10].* = "--library\x00".*;
            ptr += 10;
            ptr = fmt.strcpyEqu(ptr, library);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                ptr[0..3].* = "-I\x00".*;
                ptr += 3;
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                ptr[0..17].* = "--needed-library\x00".*;
                ptr += 17;
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                ptr[0..20].* = "--library-directory\x00".*;
                ptr += 20;
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.link_script) |link_script| {
            ptr[0..9].* = "--script\x00".*;
            ptr += 9;
            ptr = fmt.strcpyEqu(ptr, link_script);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.version_script) |version_script| {
            ptr[0..17].* = "--version-script\x00".*;
            ptr += 17;
            ptr = fmt.strcpyEqu(ptr, version_script);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            ptr[0..17].* = "--dynamic-linker\x00".*;
            ptr += 17;
            ptr = fmt.strcpyEqu(ptr, dynamic_linker);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.sysroot) |sysroot| {
            ptr[0..10].* = "--sysroot\x00".*;
            ptr += 10;
            ptr = fmt.strcpyEqu(ptr, sysroot);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.entry) |entry| {
            ptr[0..8].* = "--entry\x00".*;
            ptr += 8;
            ptr = fmt.strcpyEqu(ptr, entry);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.lld) |lld| {
            if (lld) {
                ptr[0..6].* = "-flld\x00".*;
                ptr += 6;
            } else {
                ptr[0..9].* = "-fno-lld\x00".*;
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
            ptr = fmt.strcpyEqu(ptr, rpath);
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
            ptr = fmt.strcpyEqu(ptr, @tagName(build_id));
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
            ptr += types.ExtraFlags.formatWriteBuf(.{ .value = cflags }, ptr);
        }
        if (cmd.rcflags) |rcflags| {
            ptr += types.ExtraFlags.formatWriteBuf(.{ .value = rcflags }, ptr);
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
        if (cmd.link_flags) |link_flags| {
            for (link_flags) |value| {
                ptr[0..3].* = "-z\x00".*;
                ptr += 3;
                ptr = fmt.strcpyEqu(ptr, @tagName(value));
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
            ptr = fmt.strcpyEqu(ptr, @tagName(color));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.incremental_compilation) {
            ptr[0..20].* = "--debug-incremental\x00".*;
            ptr += 20;
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
            ptr = fmt.strcpyEqu(ptr, debug_log);
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
    pub fn formatLength(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path) usize {
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
        if (cmd.main_mod_path) |main_mod_path| {
            len +%= 16;
            len +%= main_mod_path.len;
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
        if (cmd.data_sections) |data_sections| {
            if (data_sections) {
                len +%= 16;
            } else {
                len +%= 19;
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
            len +%= types.ExtraFlags.formatLength(.{ .value = cflags });
        }
        if (cmd.rcflags) |rcflags| {
            len +%= types.ExtraFlags.formatLength(.{ .value = rcflags });
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
        if (cmd.link_flags) |link_flags| {
            for (link_flags) |value| {
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
        if (cmd.incremental_compilation) {
            len +%= 20;
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
    pub fn formatWrite(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
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
        if (cmd.main_mod_path) |main_mod_path| {
            array.writeMany("--main-mod-path\x00");
            array.writeMany(main_mod_path);
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
        if (cmd.data_sections) |data_sections| {
            if (data_sections) {
                array.writeMany("-fdata-sections\x00");
            } else {
                array.writeMany("-fno-data-sections\x00");
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
                array.writeMany("-flld\x00");
            } else {
                array.writeMany("-fno-lld\x00");
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
            array.writeFormat(types.ExtraFlags{ .value = cflags });
        }
        if (cmd.rcflags) |rcflags| {
            array.writeFormat(types.ExtraFlags{ .value = rcflags });
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
        if (cmd.link_flags) |link_flags| {
            for (link_flags) |value| {
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
        if (cmd.incremental_compilation) {
            array.writeMany("--debug-incremental\x00");
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
    pub fn formatParseArgs(cmd: *BuildCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("-femit-bin", arg[0..@min(arg.len, 10)])) {
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
            } else if (mem.testEqualString("-femit-asm", arg[0..@min(arg.len, 10)])) {
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
            } else if (mem.testEqualString("-femit-llvm-ir", arg[0..@min(arg.len, 14)])) {
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
            } else if (mem.testEqualString("-femit-llvm-bc", arg[0..@min(arg.len, 14)])) {
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
            } else if (mem.testEqualString("-femit-h", arg[0..@min(arg.len, 8)])) {
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
            } else if (mem.testEqualString("-femit-docs", arg[0..@min(arg.len, 11)])) {
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
            } else if (mem.testEqualString("-femit-analysis", arg[0..@min(arg.len, 15)])) {
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
            } else if (mem.testEqualString("-femit-implib", arg[0..@min(arg.len, 13)])) {
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
            } else if (mem.testEqualString("-O", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("--main-mod-path", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.main_mod_path = mem.terminate(args[args_idx], 0);
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
            } else if (mem.testEqualString("-fdata-sections", arg)) {
                cmd.data_sections = true;
            } else if (mem.testEqualString("-fno-data-sections", arg)) {
                cmd.data_sections = false;
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
            } else if (mem.testEqualString("-I", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-flld", arg)) {
                cmd.lld = true;
            } else if (mem.testEqualString("-fno-lld", arg)) {
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
            } else if (mem.testEqualString("-D", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("--deps", arg)) {
                cmd.dependencies = types.ModuleDependencies.formatParseArgs(allocator, args, &args_idx, arg);
            } else if (mem.testEqualString("-cflags", arg)) {
                cmd.cflags = types.ExtraFlags.formatParseArgs(allocator, args, &args_idx, arg);
            } else if (mem.testEqualString("-rcflags", arg)) {
                cmd.rcflags = types.ExtraFlags.formatParseArgs(allocator, args, &args_idx, arg);
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
            } else if (mem.testEqualString("--debug-incremental", arg)) {
                cmd.incremental_compilation = true;
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
            } else {
                debug.write(build_help);
            }
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, zig_exe);
        ptr[0] = 0;
        ptr += 1;
        ptr[0..3].* = "ar\x00".*;
        ptr += 3;
        if (cmd.format) |format| {
            ptr[0..9].* = "--format\x00".*;
            ptr += 9;
            ptr = fmt.strcpyEqu(ptr, @tagName(format));
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
            ptr = fmt.strcpyEqu(ptr, output);
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
        ptr = fmt.strcpyEqu(ptr, @tagName(cmd.operation));
        ptr[0] = 0;
        ptr += 1;
        for (files) |value| {
            ptr += value.formatWriteBuf(ptr);
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path) usize {
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
    pub fn formatWrite(cmd: *ArchiveCommand, zig_exe: []const u8, files: []const types.Path, array: anytype) void {
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
    pub fn formatParseArgs(cmd: *ArchiveCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
            } else {
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *ObjcopyCommand, zig_exe: []const u8, path: types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, zig_exe);
        ptr[0] = 0;
        ptr += 1;
        ptr[0..8].* = "objcopy\x00".*;
        ptr += 8;
        if (cmd.output_target) |output_target| {
            ptr[0..16].* = "--output-target\x00".*;
            ptr += 16;
            ptr = fmt.strcpyEqu(ptr, output_target);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.only_section) |only_section| {
            ptr[0..15].* = "--only-section\x00".*;
            ptr += 15;
            ptr = fmt.strcpyEqu(ptr, only_section);
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
            ptr = fmt.strcpyEqu(ptr, add_gnu_debuglink);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.extract_to) |extract_to| {
            ptr[0..13].* = "--extract-to\x00".*;
            ptr += 13;
            ptr = fmt.strcpyEqu(ptr, extract_to);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += path.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *ObjcopyCommand, zig_exe: []const u8, path: types.Path) usize {
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
        len +%= path.formatLength();
        return len;
    }
    pub fn formatWrite(cmd: *ObjcopyCommand, zig_exe: []const u8, path: types.Path, array: anytype) void {
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
        array.writeFormat(path);
    }
    pub fn formatParseArgs(cmd: *ObjcopyCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
            } else {
                debug.write(objcopy_help);
            }
            _ = allocator;
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *HarecCommand, harec_exe: []const u8, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, harec_exe);
        ptr[0] = 0;
        ptr += 1;
        if (cmd.arch) |arch| {
            ptr[0..3].* = "-a\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, arch);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.defs) |defs| {
            ptr += types.Macros.formatWriteBuf(.{ .value = defs }, ptr);
        }
        if (cmd.output) |output| {
            ptr[0..3].* = "-o\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, output);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.tags) |tags| {
            for (tags) |value| {
                ptr[0..2].* = "-T".*;
                ptr += 2;
                ptr = fmt.strcpyEqu(ptr, value);
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
    pub fn formatLength(cmd: *HarecCommand, harec_exe: []const u8) usize {
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
    pub fn formatWrite(cmd: *HarecCommand, harec_exe: []const u8, array: anytype) void {
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
    pub fn formatParseArgs(cmd: *HarecCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("-a", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-o", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-T", arg[0..@min(arg.len, 2)])) {
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
            } else {
                debug.write(harec_help);
            }
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *TableGenCommand, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        if (cmd.color) |color| {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
            ptr = fmt.strcpyEqu(ptr, @tagName(color));
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
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.dependencies) |dependencies| {
            for (dependencies) |value| {
                ptr[0..3].* = "-d\x00".*;
                ptr += 3;
                ptr = fmt.strcpyEqu(ptr, value);
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
            ptr = fmt.strcpyEqu(ptr, output);
            ptr[0] = 0;
            ptr += 1;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *TableGenCommand) usize {
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
    pub fn formatWrite(cmd: *TableGenCommand, array: anytype) void {
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
    pub fn formatParseArgs(cmd: *TableGenCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
            } else if (mem.testEqualString("-I", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-d", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-o", arg[0..@min(arg.len, 2)])) {
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
            } else {
                debug.write(tblgen_help);
            }
        }
    }
};
pub const LLCCommand = struct {
    /// Use colors in output (default=autodetect)
    color: bool = false,
    /// Add directories to include search path
    include: ?[]const []const u8 = null,
    /// Optimization level. [-O0, -O1, -O2, or -O3] (default='-O2')
    optimize: ?enum(u2) {
        @"0" = 0,
        @"1" = 1,
        @"2" = 2,
        @"3" = 3,
    } = null,
    /// Emit an address-significance table
    emit_addrsig: bool = false,
    /// Default alignment for loops
    align_loops: ?usize = null,
    /// Enable the use of AA during codegen.
    aarch64_use_aa: bool = false,
    /// Abort when the max iterations for devirtualization CGSCC repeat pass is reached
    abort_on_max_devirt_iterations_reached: bool = false,
    /// Allow G_INSERT to be considered an artifact. Hack around AMDGPU test infinite loops.
    allow_ginsert_as_artifact: bool = false,
    /// Skip 64-bit divide for dynamic 32-bit values
    amdgpu_bypass_slow_div: bool = false,
    /// Do not align and prefetch loops
    amdgpu_disable_loop_alignment: bool = false,
    /// Enable DPP combiner
    amdgpu_dpp_combine: bool = false,
    /// Dump AMDGPU HSA Metadata
    amdgpu_dump_hsa_metadata: bool = false,
    /// Merge and hoist M0 initializations
    amdgpu_enable_merge_m0: bool = false,
    /// Enable scheduling to minimize mAI power bursts
    amdgpu_enable_power_sched: bool = false,
    /// Enable SDWA peepholer
    amdgpu_sdwa_peephole: bool = false,
    /// Enable the use of AA during codegen.
    amdgpu_use_aa_in_codegen: bool = false,
    /// Verify AMDGPU HSA Metadata
    amdgpu_verify_hsa_metadata: bool = false,
    /// Use GPR indexing mode instead of movrel for vector indexing
    amdgpu_vgpr_index_mode: bool = false,
    /// Emit internal instruction representation to assembly file
    asm_show_inst: bool = false,
    /// Add comments to directives.
    asm_verbose: bool = false,
    /// Do counter update using atomic fetch add  for promoted counters only
    atomic_counter_update_promoted: bool = false,
    /// Use atomic fetch add for first counter in a function (usually the entry counter)
    atomic_first_counter: bool = false,
    /// Use one trap block per function
    bounds_checking_single_trap: bool = false,
    /// Perform context sensitive PGO instrumentation
    cs_profile_generate: bool = false,
    /// Emit data into separate sections
    data_sections: bool = false,
    /// Enable debug info for the debug entry values.
    debug_entry_values: bool = false,
    /// Use debug info to correlate profiles.
    debug_info_correlate: bool = false,
    /// Suppress verbose debugify output
    debugify_quiet: bool = false,
    /// Disable promote alloca to LDS
    disable_promote_alloca_to_lds: bool = false,
    /// Disable promote alloca to vector
    disable_promote_alloca_to_vector: bool = false,
    /// Disable simplify-libcalls
    disable_simplify_libcalls: bool = false,
    /// Never emit tail calls
    disable_tail_calls: bool = false,
    /// Do counter register promotion
    do_counter_promotion: bool = false,
    /// Generate debugging info in the 64-bit DWARF format
    dwarf64: bool = false,
    /// Emit call site debug information, if debug information is enabled.
    emit_call_site_info: bool = false,
    /// Use emulated TLS model
    emulated_tls: bool = false,
    /// Enable FP math optimizations that assume approx func
    enable_approx_func_fp_math: bool = false,
    /// Should enable CSE in irtranslator
    enable_cse_in_irtranslator: bool = false,
    /// Should enable CSE in Legalizer
    enable_cse_in_legalizer: bool = false,
    /// WebAssembly Emscripten-style exception handling
    enable_emscripten_cxx_exceptions: bool = false,
    /// WebAssembly Emscripten-style setjmp/longjmp handling
    enable_emscripten_sjlj: bool = false,
    /// Enable the GVN hoisting pass (default = off)
    enable_gvn_hoist: bool = false,
    /// Enable the GVN sinking pass (default = off)
    enable_gvn_sink: bool = false,
    /// Instrument functions with a call to __CheckForDebuggerJustMyCode
    enable_jmc_instrument: bool = false,
    /// Enable name/filename string compression
    enable_name_compression: bool = false,
    /// Enable FP math optimizations that assume no +-Infs
    enable_no_infs_fp_math: bool = false,
    /// Enable FP math optimizations that assume no NaNs
    enable_no_nans_fp_math: bool = false,
    /// Enable FP math optimizations that assume the sign of 0 is insignificant
    enable_no_signed_zeros_fp_math: bool = false,
    /// Enable setting the FP exceptions build attribute not to use exceptions
    enable_no_trapping_fp_math: bool = false,
    /// [MISSING]
    enable_split_backedge_in_load_pre: bool = false,
    /// Enable optimizations that may decrease FP precision
    enable_unsafe_fp_math: bool = false,
    /// Use experimental new value-tracking variable locations
    experimental_debug_variable_locations: bool = false,
    /// Treat warnings as errors
    fatal_warnings: bool = false,
    /// Always emit a debug frame section.
    force_dwarf_frame_section: bool = false,
    /// Emit functions into separate sections
    function_sections: bool = false,
    /// When generating nested context-sensitive profiles, always generate extra base profile for function with all its context profiles merged into it.
    generate_merged_base_profiles: bool = false,
    /// Rename counter variable of a comdat function based on cfg hash
    hash_based_counter_split: bool = false,
    /// Enable hot-cold splitting pass
    hot_cold_split: bool = false,
    /// Not emit the visibility attribute for asm in AIX OS or give all symbols 'unspecified' visibility in XCOFF object file
    ignore_xcoff_visibility: bool = false,
    /// Import all external functions in index.
    import_all_index: bool = false,
    /// When used with filetype=obj, emit an object file which can be used with an incremental linker
    incremental_linker_compatible: bool = false,
    /// Enable code sinking
    instcombine_code_sinking: bool = false,
    /// Should we attempt to sink negations?
    instcombine_negator_enabled: bool = false,
    /// Make all profile counter updates atomic (for testing only)
    instrprof_atomic_counter_update_all: bool = false,
    /// Enable mips16 constant islands.
    mips16_constant_islands: bool = false,
    /// Enable mips16 hard float.
    mips16_hard_float: bool = false,
    /// Should mir-strip-debug only strip debug info from debugified modules by default
    mir_strip_debugify_only: bool = false,
    /// Disable looking for compound instructions for Hexagon
    mno_compound: bool = false,
    /// Disable fixing up resolved relocations for Hexagon
    mno_fixup: bool = false,
    /// Expand double precision loads and stores to their single precision counterparts
    mno_ldc1_sdc1: bool = false,
    /// Disable looking for duplex instructions for Hexagon
    mno_pairing: bool = false,
    /// Warn for missing parenthesis around predicate registers
    mwarn_missing_parenthesis: bool = false,
    /// Warn for register names that arent contigious
    mwarn_noncontigious_register: bool = false,
    /// Warn for mismatching a signed and unsigned value
    mwarn_sign_mismatch: bool = false,
    /// Suppress all deprecated warnings
    no_deprecated_warn: bool = false,
    /// Disable generation of discriminator information.
    no_discriminators: bool = false,
    /// Suppress type errors (Wasm)
    no_type_check: bool = false,
    /// Suppress all warnings
    no_warn: bool = false,
    /// Don't emit xray_fn_idx section
    no_xray_index: bool = false,
    /// Don't place zero-initialized symbols into bss section
    nozero_initialized_in_bss: bool = false,
    /// NVPTX Specific: schedule for register pressue
    nvptx_sched4reg: bool = false,
    /// Use opaque pointers
    opaque_pointers: bool = false,
    /// Check that returns are non-poison (for testing)
    poison_checking_function_local: bool = false,
    /// Print a '-passes' compatible string describing the pipeline (best-effort only).
    print_pipeline_passes: bool = false,
    /// Use StructurizeCFG IR pass
    r600_ir_structurize: bool = false,
    /// -
    rdf_dump: bool = false,
    /// Emit GOTPCRELX/REX_GOTPCRELX instead of GOTPCREL on x86-64 ELF
    relax_elf_relocations: bool = false,
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *LLCCommand, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        if (cmd.color) {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                ptr[0..3].* = "-I\x00".*;
                ptr += 3;
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.optimize) |optimize| {
            ptr[0..3].* = "-O\x00".*;
            ptr += 3;
            ptr = fmt.strcpyEqu(ptr, @tagName(optimize));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.emit_addrsig) {
            ptr[0..10].* = "--addrsig\x00".*;
            ptr += 10;
        }
        if (cmd.align_loops) |align_loops| {
            ptr[0..14].* = "--align-loops\x00".*;
            ptr += 14;
            ptr += fmt.Type.Ud64.formatWriteBuf(.{ .value = align_loops }, ptr);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.aarch64_use_aa) {
            ptr[0..17].* = "--aarch64-use-aa\x00".*;
            ptr += 17;
        }
        if (cmd.abort_on_max_devirt_iterations_reached) {
            ptr[0..41].* = "--abort-on-max-devirt-iterations-reached\x00".*;
            ptr += 41;
        }
        if (cmd.allow_ginsert_as_artifact) {
            ptr[0..28].* = "--allow-ginsert-as-artifact\x00".*;
            ptr += 28;
        }
        if (cmd.amdgpu_bypass_slow_div) {
            ptr[0..25].* = "--amdgpu-bypass-slow-div\x00".*;
            ptr += 25;
        }
        if (cmd.amdgpu_disable_loop_alignment) {
            ptr[0..32].* = "--amdgpu-disable-loop-alignment\x00".*;
            ptr += 32;
        }
        if (cmd.amdgpu_dpp_combine) {
            ptr[0..21].* = "--amdgpu-dpp-combine\x00".*;
            ptr += 21;
        }
        if (cmd.amdgpu_dump_hsa_metadata) {
            ptr[0..27].* = "--amdgpu-dump-hsa-metadata\x00".*;
            ptr += 27;
        }
        if (cmd.amdgpu_enable_merge_m0) {
            ptr[0..25].* = "--amdgpu-enable-merge-m0\x00".*;
            ptr += 25;
        }
        if (cmd.amdgpu_enable_power_sched) {
            ptr[0..28].* = "--amdgpu-enable-power-sched\x00".*;
            ptr += 28;
        }
        if (cmd.amdgpu_sdwa_peephole) {
            ptr[0..23].* = "--amdgpu-sdwa-peephole\x00".*;
            ptr += 23;
        }
        if (cmd.amdgpu_use_aa_in_codegen) {
            ptr[0..27].* = "--amdgpu-use-aa-in-codegen\x00".*;
            ptr += 27;
        }
        if (cmd.amdgpu_verify_hsa_metadata) {
            ptr[0..29].* = "--amdgpu-verify-hsa-metadata\x00".*;
            ptr += 29;
        }
        if (cmd.amdgpu_vgpr_index_mode) {
            ptr[0..25].* = "--amdgpu-vgpr-index-mode\x00".*;
            ptr += 25;
        }
        if (cmd.asm_show_inst) {
            ptr[0..16].* = "--asm-show-inst\x00".*;
            ptr += 16;
        }
        if (cmd.asm_verbose) {
            ptr[0..14].* = "--asm-verbose\x00".*;
            ptr += 14;
        }
        if (cmd.atomic_counter_update_promoted) {
            ptr[0..33].* = "--atomic-counter-update-promoted\x00".*;
            ptr += 33;
        }
        if (cmd.atomic_first_counter) {
            ptr[0..23].* = "--atomic-first-counter\x00".*;
            ptr += 23;
        }
        if (cmd.bounds_checking_single_trap) {
            ptr[0..30].* = "--bounds-checking-single-trap\x00".*;
            ptr += 30;
        }
        if (cmd.cs_profile_generate) {
            ptr[0..22].* = "--cs-profile-generate\x00".*;
            ptr += 22;
        }
        if (cmd.data_sections) {
            ptr[0..16].* = "--data-sections\x00".*;
            ptr += 16;
        }
        if (cmd.debug_entry_values) {
            ptr[0..21].* = "--debug-entry-values\x00".*;
            ptr += 21;
        }
        if (cmd.debug_info_correlate) {
            ptr[0..23].* = "--debug-info-correlate\x00".*;
            ptr += 23;
        }
        if (cmd.debugify_quiet) {
            ptr[0..17].* = "--debugify-quiet\x00".*;
            ptr += 17;
        }
        if (cmd.disable_promote_alloca_to_lds) {
            ptr[0..32].* = "--disable-promote-alloca-to-lds\x00".*;
            ptr += 32;
        }
        if (cmd.disable_promote_alloca_to_vector) {
            ptr[0..35].* = "--disable-promote-alloca-to-vector\x00".*;
            ptr += 35;
        }
        if (cmd.disable_simplify_libcalls) {
            ptr[0..28].* = "--disable-simplify-libcalls\x00".*;
            ptr += 28;
        }
        if (cmd.disable_tail_calls) {
            ptr[0..21].* = "--disable-tail-calls\x00".*;
            ptr += 21;
        }
        if (cmd.do_counter_promotion) {
            ptr[0..23].* = "--do-counter-promotion\x00".*;
            ptr += 23;
        }
        if (cmd.dwarf64) {
            ptr[0..10].* = "--dwarf64\x00".*;
            ptr += 10;
        }
        if (cmd.emit_call_site_info) {
            ptr[0..22].* = "--emit-call-site-info\x00".*;
            ptr += 22;
        }
        if (cmd.emulated_tls) {
            ptr[0..15].* = "--emulated-tls\x00".*;
            ptr += 15;
        }
        if (cmd.enable_approx_func_fp_math) {
            ptr[0..29].* = "--enable-approx-func-fp-math\x00".*;
            ptr += 29;
        }
        if (cmd.enable_cse_in_irtranslator) {
            ptr[0..29].* = "--enable-cse-in-irtranslator\x00".*;
            ptr += 29;
        }
        if (cmd.enable_cse_in_legalizer) {
            ptr[0..26].* = "--enable-cse-in-legalizer\x00".*;
            ptr += 26;
        }
        if (cmd.enable_emscripten_cxx_exceptions) {
            ptr[0..35].* = "--enable-emscripten-cxx-exceptions\x00".*;
            ptr += 35;
        }
        if (cmd.enable_emscripten_sjlj) {
            ptr[0..25].* = "--enable-emscripten-sjlj\x00".*;
            ptr += 25;
        }
        if (cmd.enable_gvn_hoist) {
            ptr[0..19].* = "--enable-gvn-hoist\x00".*;
            ptr += 19;
        }
        if (cmd.enable_gvn_sink) {
            ptr[0..18].* = "--enable-gvn-sink\x00".*;
            ptr += 18;
        }
        if (cmd.enable_jmc_instrument) {
            ptr[0..24].* = "--enable-jmc-instrument\x00".*;
            ptr += 24;
        }
        if (cmd.enable_name_compression) {
            ptr[0..26].* = "--enable-name-compression\x00".*;
            ptr += 26;
        }
        if (cmd.enable_no_infs_fp_math) {
            ptr[0..25].* = "--enable-no-infs-fp-math\x00".*;
            ptr += 25;
        }
        if (cmd.enable_no_nans_fp_math) {
            ptr[0..25].* = "--enable-no-nans-fp-math\x00".*;
            ptr += 25;
        }
        if (cmd.enable_no_signed_zeros_fp_math) {
            ptr[0..33].* = "--enable-no-signed-zeros-fp-math\x00".*;
            ptr += 33;
        }
        if (cmd.enable_no_trapping_fp_math) {
            ptr[0..29].* = "--enable-no-trapping-fp-math\x00".*;
            ptr += 29;
        }
        if (cmd.enable_split_backedge_in_load_pre) {
            ptr[0..24].* = "--enable-unsafe-fp-math\x00".*;
            ptr += 24;
        }
        if (cmd.enable_unsafe_fp_math) {
            ptr[0..24].* = "--enable-unsafe-fp-math\x00".*;
            ptr += 24;
        }
        if (cmd.experimental_debug_variable_locations) {
            ptr[0..40].* = "--experimental-debug-variable-locations\x00".*;
            ptr += 40;
        }
        if (cmd.fatal_warnings) {
            ptr[0..17].* = "--fatal-warnings\x00".*;
            ptr += 17;
        }
        if (cmd.force_dwarf_frame_section) {
            ptr[0..28].* = "--force-dwarf-frame-section\x00".*;
            ptr += 28;
        }
        if (cmd.function_sections) {
            ptr[0..20].* = "--function-sections\x00".*;
            ptr += 20;
        }
        if (cmd.generate_merged_base_profiles) {
            ptr[0..32].* = "--generate-merged-base-profiles\x00".*;
            ptr += 32;
        }
        if (cmd.hash_based_counter_split) {
            ptr[0..27].* = "--hash-based-counter-split\x00".*;
            ptr += 27;
        }
        if (cmd.hot_cold_split) {
            ptr[0..17].* = "--hot-cold-split\x00".*;
            ptr += 17;
        }
        if (cmd.ignore_xcoff_visibility) {
            ptr[0..26].* = "--ignore-xcoff-visibility\x00".*;
            ptr += 26;
        }
        if (cmd.import_all_index) {
            ptr[0..19].* = "--import-all-index\x00".*;
            ptr += 19;
        }
        if (cmd.incremental_linker_compatible) {
            ptr[0..32].* = "--incremental-linker-compatible\x00".*;
            ptr += 32;
        }
        if (cmd.instcombine_code_sinking) {
            ptr[0..27].* = "--instcombine-code-sinking\x00".*;
            ptr += 27;
        }
        if (cmd.instcombine_negator_enabled) {
            ptr[0..30].* = "--instcombine-negator-enabled\x00".*;
            ptr += 30;
        }
        if (cmd.instrprof_atomic_counter_update_all) {
            ptr[0..38].* = "--instrprof-atomic-counter-update-all\x00".*;
            ptr += 38;
        }
        if (cmd.mips16_constant_islands) {
            ptr[0..26].* = "--mips16-constant-islands\x00".*;
            ptr += 26;
        }
        if (cmd.mips16_hard_float) {
            ptr[0..20].* = "--mips16-hard-float\x00".*;
            ptr += 20;
        }
        if (cmd.mir_strip_debugify_only) {
            ptr[0..26].* = "--mir-strip-debugify-only\x00".*;
            ptr += 26;
        }
        if (cmd.mno_compound) {
            ptr[0..15].* = "--mno-compound\x00".*;
            ptr += 15;
        }
        if (cmd.mno_fixup) {
            ptr[0..12].* = "--mno-fixup\x00".*;
            ptr += 12;
        }
        if (cmd.mno_ldc1_sdc1) {
            ptr[0..16].* = "--mno-ldc1-sdc1\x00".*;
            ptr += 16;
        }
        if (cmd.mno_pairing) {
            ptr[0..14].* = "--mno-pairing\x00".*;
            ptr += 14;
        }
        if (cmd.mwarn_missing_parenthesis) {
            ptr[0..28].* = "--mwarn-missing-parenthesis\x00".*;
            ptr += 28;
        }
        if (cmd.mwarn_noncontigious_register) {
            ptr[0..31].* = "--mwarn-noncontigious-register\x00".*;
            ptr += 31;
        }
        if (cmd.mwarn_sign_mismatch) {
            ptr[0..22].* = "--mwarn-sign-mismatch\x00".*;
            ptr += 22;
        }
        if (cmd.no_deprecated_warn) {
            ptr[0..21].* = "--no-deprecated-warn\x00".*;
            ptr += 21;
        }
        if (cmd.no_discriminators) {
            ptr[0..20].* = "--no-discriminators\x00".*;
            ptr += 20;
        }
        if (cmd.no_type_check) {
            ptr[0..16].* = "--no-type-check\x00".*;
            ptr += 16;
        }
        if (cmd.no_warn) {
            ptr[0..10].* = "--no-warn\x00".*;
            ptr += 10;
        }
        if (cmd.no_xray_index) {
            ptr[0..16].* = "--no-xray-index\x00".*;
            ptr += 16;
        }
        if (cmd.nozero_initialized_in_bss) {
            ptr[0..28].* = "--nozero-initialized-in-bss\x00".*;
            ptr += 28;
        }
        if (cmd.nvptx_sched4reg) {
            ptr[0..18].* = "--nvptx-sched4reg\x00".*;
            ptr += 18;
        }
        if (cmd.opaque_pointers) {
            ptr[0..18].* = "--opaque-pointers\x00".*;
            ptr += 18;
        }
        if (cmd.poison_checking_function_local) {
            ptr[0..33].* = "--poison-checking-function-local\x00".*;
            ptr += 33;
        }
        if (cmd.print_pipeline_passes) {
            ptr[0..24].* = "--print-pipeline-passes\x00".*;
            ptr += 24;
        }
        if (cmd.r600_ir_structurize) {
            ptr[0..22].* = "--r600-ir-structurize\x00".*;
            ptr += 22;
        }
        if (cmd.rdf_dump) {
            ptr[0..11].* = "--rdf-dump\x00".*;
            ptr += 11;
        }
        if (cmd.relax_elf_relocations) {
            ptr[0..24].* = "--relax-elf-relocations\x00".*;
            ptr += 24;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *LLCCommand) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        if (cmd.color) {
            len +%= 8;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                len +%= 3;
                len +%= value.len;
                len +%= 1;
            }
        }
        if (cmd.optimize) |optimize| {
            len +%= 3;
            len +%= @tagName(optimize).len;
            len +%= 1;
        }
        if (cmd.emit_addrsig) {
            len +%= 10;
        }
        if (cmd.align_loops) |align_loops| {
            len +%= 14;
            len +%= fmt.Type.Ud64.formatLength(.{ .value = align_loops });
            len +%= 1;
        }
        if (cmd.aarch64_use_aa) {
            len +%= 17;
        }
        if (cmd.abort_on_max_devirt_iterations_reached) {
            len +%= 41;
        }
        if (cmd.allow_ginsert_as_artifact) {
            len +%= 28;
        }
        if (cmd.amdgpu_bypass_slow_div) {
            len +%= 25;
        }
        if (cmd.amdgpu_disable_loop_alignment) {
            len +%= 32;
        }
        if (cmd.amdgpu_dpp_combine) {
            len +%= 21;
        }
        if (cmd.amdgpu_dump_hsa_metadata) {
            len +%= 27;
        }
        if (cmd.amdgpu_enable_merge_m0) {
            len +%= 25;
        }
        if (cmd.amdgpu_enable_power_sched) {
            len +%= 28;
        }
        if (cmd.amdgpu_sdwa_peephole) {
            len +%= 23;
        }
        if (cmd.amdgpu_use_aa_in_codegen) {
            len +%= 27;
        }
        if (cmd.amdgpu_verify_hsa_metadata) {
            len +%= 29;
        }
        if (cmd.amdgpu_vgpr_index_mode) {
            len +%= 25;
        }
        if (cmd.asm_show_inst) {
            len +%= 16;
        }
        if (cmd.asm_verbose) {
            len +%= 14;
        }
        if (cmd.atomic_counter_update_promoted) {
            len +%= 33;
        }
        if (cmd.atomic_first_counter) {
            len +%= 23;
        }
        if (cmd.bounds_checking_single_trap) {
            len +%= 30;
        }
        if (cmd.cs_profile_generate) {
            len +%= 22;
        }
        if (cmd.data_sections) {
            len +%= 16;
        }
        if (cmd.debug_entry_values) {
            len +%= 21;
        }
        if (cmd.debug_info_correlate) {
            len +%= 23;
        }
        if (cmd.debugify_quiet) {
            len +%= 17;
        }
        if (cmd.disable_promote_alloca_to_lds) {
            len +%= 32;
        }
        if (cmd.disable_promote_alloca_to_vector) {
            len +%= 35;
        }
        if (cmd.disable_simplify_libcalls) {
            len +%= 28;
        }
        if (cmd.disable_tail_calls) {
            len +%= 21;
        }
        if (cmd.do_counter_promotion) {
            len +%= 23;
        }
        if (cmd.dwarf64) {
            len +%= 10;
        }
        if (cmd.emit_call_site_info) {
            len +%= 22;
        }
        if (cmd.emulated_tls) {
            len +%= 15;
        }
        if (cmd.enable_approx_func_fp_math) {
            len +%= 29;
        }
        if (cmd.enable_cse_in_irtranslator) {
            len +%= 29;
        }
        if (cmd.enable_cse_in_legalizer) {
            len +%= 26;
        }
        if (cmd.enable_emscripten_cxx_exceptions) {
            len +%= 35;
        }
        if (cmd.enable_emscripten_sjlj) {
            len +%= 25;
        }
        if (cmd.enable_gvn_hoist) {
            len +%= 19;
        }
        if (cmd.enable_gvn_sink) {
            len +%= 18;
        }
        if (cmd.enable_jmc_instrument) {
            len +%= 24;
        }
        if (cmd.enable_name_compression) {
            len +%= 26;
        }
        if (cmd.enable_no_infs_fp_math) {
            len +%= 25;
        }
        if (cmd.enable_no_nans_fp_math) {
            len +%= 25;
        }
        if (cmd.enable_no_signed_zeros_fp_math) {
            len +%= 33;
        }
        if (cmd.enable_no_trapping_fp_math) {
            len +%= 29;
        }
        if (cmd.enable_split_backedge_in_load_pre) {
            len +%= 24;
        }
        if (cmd.enable_unsafe_fp_math) {
            len +%= 24;
        }
        if (cmd.experimental_debug_variable_locations) {
            len +%= 40;
        }
        if (cmd.fatal_warnings) {
            len +%= 17;
        }
        if (cmd.force_dwarf_frame_section) {
            len +%= 28;
        }
        if (cmd.function_sections) {
            len +%= 20;
        }
        if (cmd.generate_merged_base_profiles) {
            len +%= 32;
        }
        if (cmd.hash_based_counter_split) {
            len +%= 27;
        }
        if (cmd.hot_cold_split) {
            len +%= 17;
        }
        if (cmd.ignore_xcoff_visibility) {
            len +%= 26;
        }
        if (cmd.import_all_index) {
            len +%= 19;
        }
        if (cmd.incremental_linker_compatible) {
            len +%= 32;
        }
        if (cmd.instcombine_code_sinking) {
            len +%= 27;
        }
        if (cmd.instcombine_negator_enabled) {
            len +%= 30;
        }
        if (cmd.instrprof_atomic_counter_update_all) {
            len +%= 38;
        }
        if (cmd.mips16_constant_islands) {
            len +%= 26;
        }
        if (cmd.mips16_hard_float) {
            len +%= 20;
        }
        if (cmd.mir_strip_debugify_only) {
            len +%= 26;
        }
        if (cmd.mno_compound) {
            len +%= 15;
        }
        if (cmd.mno_fixup) {
            len +%= 12;
        }
        if (cmd.mno_ldc1_sdc1) {
            len +%= 16;
        }
        if (cmd.mno_pairing) {
            len +%= 14;
        }
        if (cmd.mwarn_missing_parenthesis) {
            len +%= 28;
        }
        if (cmd.mwarn_noncontigious_register) {
            len +%= 31;
        }
        if (cmd.mwarn_sign_mismatch) {
            len +%= 22;
        }
        if (cmd.no_deprecated_warn) {
            len +%= 21;
        }
        if (cmd.no_discriminators) {
            len +%= 20;
        }
        if (cmd.no_type_check) {
            len +%= 16;
        }
        if (cmd.no_warn) {
            len +%= 10;
        }
        if (cmd.no_xray_index) {
            len +%= 16;
        }
        if (cmd.nozero_initialized_in_bss) {
            len +%= 28;
        }
        if (cmd.nvptx_sched4reg) {
            len +%= 18;
        }
        if (cmd.opaque_pointers) {
            len +%= 18;
        }
        if (cmd.poison_checking_function_local) {
            len +%= 33;
        }
        if (cmd.print_pipeline_passes) {
            len +%= 24;
        }
        if (cmd.r600_ir_structurize) {
            len +%= 22;
        }
        if (cmd.rdf_dump) {
            len +%= 11;
        }
        if (cmd.relax_elf_relocations) {
            len +%= 24;
        }
        return len;
    }
    pub fn formatWrite(cmd: *LLCCommand, array: anytype) void {
        @setRuntimeSafety(false);
        if (cmd.color) {
            array.writeMany("--color\x00");
        }
        if (cmd.include) |include| {
            for (include) |value| {
                array.writeMany("-I\x00");
                array.writeMany(value);
                array.writeOne(0);
            }
        }
        if (cmd.optimize) |optimize| {
            array.writeMany("-O\x00");
            array.writeMany(@tagName(optimize));
            array.writeOne(0);
        }
        if (cmd.emit_addrsig) {
            array.writeMany("--addrsig\x00");
        }
        if (cmd.align_loops) |align_loops| {
            array.writeMany("--align-loops\x00");
            array.writeFormat(fmt.ud64(align_loops));
            array.writeOne(0);
        }
        if (cmd.aarch64_use_aa) {
            array.writeMany("--aarch64-use-aa\x00");
        }
        if (cmd.abort_on_max_devirt_iterations_reached) {
            array.writeMany("--abort-on-max-devirt-iterations-reached\x00");
        }
        if (cmd.allow_ginsert_as_artifact) {
            array.writeMany("--allow-ginsert-as-artifact\x00");
        }
        if (cmd.amdgpu_bypass_slow_div) {
            array.writeMany("--amdgpu-bypass-slow-div\x00");
        }
        if (cmd.amdgpu_disable_loop_alignment) {
            array.writeMany("--amdgpu-disable-loop-alignment\x00");
        }
        if (cmd.amdgpu_dpp_combine) {
            array.writeMany("--amdgpu-dpp-combine\x00");
        }
        if (cmd.amdgpu_dump_hsa_metadata) {
            array.writeMany("--amdgpu-dump-hsa-metadata\x00");
        }
        if (cmd.amdgpu_enable_merge_m0) {
            array.writeMany("--amdgpu-enable-merge-m0\x00");
        }
        if (cmd.amdgpu_enable_power_sched) {
            array.writeMany("--amdgpu-enable-power-sched\x00");
        }
        if (cmd.amdgpu_sdwa_peephole) {
            array.writeMany("--amdgpu-sdwa-peephole\x00");
        }
        if (cmd.amdgpu_use_aa_in_codegen) {
            array.writeMany("--amdgpu-use-aa-in-codegen\x00");
        }
        if (cmd.amdgpu_verify_hsa_metadata) {
            array.writeMany("--amdgpu-verify-hsa-metadata\x00");
        }
        if (cmd.amdgpu_vgpr_index_mode) {
            array.writeMany("--amdgpu-vgpr-index-mode\x00");
        }
        if (cmd.asm_show_inst) {
            array.writeMany("--asm-show-inst\x00");
        }
        if (cmd.asm_verbose) {
            array.writeMany("--asm-verbose\x00");
        }
        if (cmd.atomic_counter_update_promoted) {
            array.writeMany("--atomic-counter-update-promoted\x00");
        }
        if (cmd.atomic_first_counter) {
            array.writeMany("--atomic-first-counter\x00");
        }
        if (cmd.bounds_checking_single_trap) {
            array.writeMany("--bounds-checking-single-trap\x00");
        }
        if (cmd.cs_profile_generate) {
            array.writeMany("--cs-profile-generate\x00");
        }
        if (cmd.data_sections) {
            array.writeMany("--data-sections\x00");
        }
        if (cmd.debug_entry_values) {
            array.writeMany("--debug-entry-values\x00");
        }
        if (cmd.debug_info_correlate) {
            array.writeMany("--debug-info-correlate\x00");
        }
        if (cmd.debugify_quiet) {
            array.writeMany("--debugify-quiet\x00");
        }
        if (cmd.disable_promote_alloca_to_lds) {
            array.writeMany("--disable-promote-alloca-to-lds\x00");
        }
        if (cmd.disable_promote_alloca_to_vector) {
            array.writeMany("--disable-promote-alloca-to-vector\x00");
        }
        if (cmd.disable_simplify_libcalls) {
            array.writeMany("--disable-simplify-libcalls\x00");
        }
        if (cmd.disable_tail_calls) {
            array.writeMany("--disable-tail-calls\x00");
        }
        if (cmd.do_counter_promotion) {
            array.writeMany("--do-counter-promotion\x00");
        }
        if (cmd.dwarf64) {
            array.writeMany("--dwarf64\x00");
        }
        if (cmd.emit_call_site_info) {
            array.writeMany("--emit-call-site-info\x00");
        }
        if (cmd.emulated_tls) {
            array.writeMany("--emulated-tls\x00");
        }
        if (cmd.enable_approx_func_fp_math) {
            array.writeMany("--enable-approx-func-fp-math\x00");
        }
        if (cmd.enable_cse_in_irtranslator) {
            array.writeMany("--enable-cse-in-irtranslator\x00");
        }
        if (cmd.enable_cse_in_legalizer) {
            array.writeMany("--enable-cse-in-legalizer\x00");
        }
        if (cmd.enable_emscripten_cxx_exceptions) {
            array.writeMany("--enable-emscripten-cxx-exceptions\x00");
        }
        if (cmd.enable_emscripten_sjlj) {
            array.writeMany("--enable-emscripten-sjlj\x00");
        }
        if (cmd.enable_gvn_hoist) {
            array.writeMany("--enable-gvn-hoist\x00");
        }
        if (cmd.enable_gvn_sink) {
            array.writeMany("--enable-gvn-sink\x00");
        }
        if (cmd.enable_jmc_instrument) {
            array.writeMany("--enable-jmc-instrument\x00");
        }
        if (cmd.enable_name_compression) {
            array.writeMany("--enable-name-compression\x00");
        }
        if (cmd.enable_no_infs_fp_math) {
            array.writeMany("--enable-no-infs-fp-math\x00");
        }
        if (cmd.enable_no_nans_fp_math) {
            array.writeMany("--enable-no-nans-fp-math\x00");
        }
        if (cmd.enable_no_signed_zeros_fp_math) {
            array.writeMany("--enable-no-signed-zeros-fp-math\x00");
        }
        if (cmd.enable_no_trapping_fp_math) {
            array.writeMany("--enable-no-trapping-fp-math\x00");
        }
        if (cmd.enable_split_backedge_in_load_pre) {
            array.writeMany("--enable-unsafe-fp-math\x00");
        }
        if (cmd.enable_unsafe_fp_math) {
            array.writeMany("--enable-unsafe-fp-math\x00");
        }
        if (cmd.experimental_debug_variable_locations) {
            array.writeMany("--experimental-debug-variable-locations\x00");
        }
        if (cmd.fatal_warnings) {
            array.writeMany("--fatal-warnings\x00");
        }
        if (cmd.force_dwarf_frame_section) {
            array.writeMany("--force-dwarf-frame-section\x00");
        }
        if (cmd.function_sections) {
            array.writeMany("--function-sections\x00");
        }
        if (cmd.generate_merged_base_profiles) {
            array.writeMany("--generate-merged-base-profiles\x00");
        }
        if (cmd.hash_based_counter_split) {
            array.writeMany("--hash-based-counter-split\x00");
        }
        if (cmd.hot_cold_split) {
            array.writeMany("--hot-cold-split\x00");
        }
        if (cmd.ignore_xcoff_visibility) {
            array.writeMany("--ignore-xcoff-visibility\x00");
        }
        if (cmd.import_all_index) {
            array.writeMany("--import-all-index\x00");
        }
        if (cmd.incremental_linker_compatible) {
            array.writeMany("--incremental-linker-compatible\x00");
        }
        if (cmd.instcombine_code_sinking) {
            array.writeMany("--instcombine-code-sinking\x00");
        }
        if (cmd.instcombine_negator_enabled) {
            array.writeMany("--instcombine-negator-enabled\x00");
        }
        if (cmd.instrprof_atomic_counter_update_all) {
            array.writeMany("--instrprof-atomic-counter-update-all\x00");
        }
        if (cmd.mips16_constant_islands) {
            array.writeMany("--mips16-constant-islands\x00");
        }
        if (cmd.mips16_hard_float) {
            array.writeMany("--mips16-hard-float\x00");
        }
        if (cmd.mir_strip_debugify_only) {
            array.writeMany("--mir-strip-debugify-only\x00");
        }
        if (cmd.mno_compound) {
            array.writeMany("--mno-compound\x00");
        }
        if (cmd.mno_fixup) {
            array.writeMany("--mno-fixup\x00");
        }
        if (cmd.mno_ldc1_sdc1) {
            array.writeMany("--mno-ldc1-sdc1\x00");
        }
        if (cmd.mno_pairing) {
            array.writeMany("--mno-pairing\x00");
        }
        if (cmd.mwarn_missing_parenthesis) {
            array.writeMany("--mwarn-missing-parenthesis\x00");
        }
        if (cmd.mwarn_noncontigious_register) {
            array.writeMany("--mwarn-noncontigious-register\x00");
        }
        if (cmd.mwarn_sign_mismatch) {
            array.writeMany("--mwarn-sign-mismatch\x00");
        }
        if (cmd.no_deprecated_warn) {
            array.writeMany("--no-deprecated-warn\x00");
        }
        if (cmd.no_discriminators) {
            array.writeMany("--no-discriminators\x00");
        }
        if (cmd.no_type_check) {
            array.writeMany("--no-type-check\x00");
        }
        if (cmd.no_warn) {
            array.writeMany("--no-warn\x00");
        }
        if (cmd.no_xray_index) {
            array.writeMany("--no-xray-index\x00");
        }
        if (cmd.nozero_initialized_in_bss) {
            array.writeMany("--nozero-initialized-in-bss\x00");
        }
        if (cmd.nvptx_sched4reg) {
            array.writeMany("--nvptx-sched4reg\x00");
        }
        if (cmd.opaque_pointers) {
            array.writeMany("--opaque-pointers\x00");
        }
        if (cmd.poison_checking_function_local) {
            array.writeMany("--poison-checking-function-local\x00");
        }
        if (cmd.print_pipeline_passes) {
            array.writeMany("--print-pipeline-passes\x00");
        }
        if (cmd.r600_ir_structurize) {
            array.writeMany("--r600-ir-structurize\x00");
        }
        if (cmd.rdf_dump) {
            array.writeMany("--rdf-dump\x00");
        }
        if (cmd.relax_elf_relocations) {
            array.writeMany("--relax-elf-relocations\x00");
        }
    }
    pub fn formatParseArgs(cmd: *LLCCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--color", arg)) {
                cmd.color = true;
            } else if (mem.testEqualString("-I", arg[0..@min(arg.len, 2)])) {
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
            } else if (mem.testEqualString("-O", arg[0..@min(arg.len, 2)])) {
                if (arg.len == 2) {
                    args_idx +%= 1;
                    if (args_idx == args.len) {
                        return;
                    }
                    arg = mem.terminate(args[args_idx], 0);
                } else {
                    arg = arg[2..];
                }
                if (mem.testEqualString("0", arg)) {
                    cmd.optimize = .@"0";
                } else if (mem.testEqualString("1", arg)) {
                    cmd.optimize = .@"1";
                } else if (mem.testEqualString("2", arg)) {
                    cmd.optimize = .@"2";
                } else if (mem.testEqualString("3", arg)) {
                    cmd.optimize = .@"3";
                }
            } else if (mem.testEqualString("--addrsig", arg)) {
                cmd.emit_addrsig = true;
            } else if (mem.testEqualString("--align-loops", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.align_loops = parse.ud(usize, mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("--aarch64-use-aa", arg)) {
                cmd.aarch64_use_aa = true;
            } else if (mem.testEqualString("--abort-on-max-devirt-iterations-reached", arg)) {
                cmd.abort_on_max_devirt_iterations_reached = true;
            } else if (mem.testEqualString("--allow-ginsert-as-artifact", arg)) {
                cmd.allow_ginsert_as_artifact = true;
            } else if (mem.testEqualString("--amdgpu-bypass-slow-div", arg)) {
                cmd.amdgpu_bypass_slow_div = true;
            } else if (mem.testEqualString("--amdgpu-disable-loop-alignment", arg)) {
                cmd.amdgpu_disable_loop_alignment = true;
            } else if (mem.testEqualString("--amdgpu-dpp-combine", arg)) {
                cmd.amdgpu_dpp_combine = true;
            } else if (mem.testEqualString("--amdgpu-dump-hsa-metadata", arg)) {
                cmd.amdgpu_dump_hsa_metadata = true;
            } else if (mem.testEqualString("--amdgpu-enable-merge-m0", arg)) {
                cmd.amdgpu_enable_merge_m0 = true;
            } else if (mem.testEqualString("--amdgpu-enable-power-sched", arg)) {
                cmd.amdgpu_enable_power_sched = true;
            } else if (mem.testEqualString("--amdgpu-sdwa-peephole", arg)) {
                cmd.amdgpu_sdwa_peephole = true;
            } else if (mem.testEqualString("--amdgpu-use-aa-in-codegen", arg)) {
                cmd.amdgpu_use_aa_in_codegen = true;
            } else if (mem.testEqualString("--amdgpu-verify-hsa-metadata", arg)) {
                cmd.amdgpu_verify_hsa_metadata = true;
            } else if (mem.testEqualString("--amdgpu-vgpr-index-mode", arg)) {
                cmd.amdgpu_vgpr_index_mode = true;
            } else if (mem.testEqualString("--asm-show-inst", arg)) {
                cmd.asm_show_inst = true;
            } else if (mem.testEqualString("--asm-verbose", arg)) {
                cmd.asm_verbose = true;
            } else if (mem.testEqualString("--atomic-counter-update-promoted", arg)) {
                cmd.atomic_counter_update_promoted = true;
            } else if (mem.testEqualString("--atomic-first-counter", arg)) {
                cmd.atomic_first_counter = true;
            } else if (mem.testEqualString("--bounds-checking-single-trap", arg)) {
                cmd.bounds_checking_single_trap = true;
            } else if (mem.testEqualString("--cs-profile-generate", arg)) {
                cmd.cs_profile_generate = true;
            } else if (mem.testEqualString("--data-sections", arg)) {
                cmd.data_sections = true;
            } else if (mem.testEqualString("--debug-entry-values", arg)) {
                cmd.debug_entry_values = true;
            } else if (mem.testEqualString("--debug-info-correlate", arg)) {
                cmd.debug_info_correlate = true;
            } else if (mem.testEqualString("--debugify-quiet", arg)) {
                cmd.debugify_quiet = true;
            } else if (mem.testEqualString("--disable-promote-alloca-to-lds", arg)) {
                cmd.disable_promote_alloca_to_lds = true;
            } else if (mem.testEqualString("--disable-promote-alloca-to-vector", arg)) {
                cmd.disable_promote_alloca_to_vector = true;
            } else if (mem.testEqualString("--disable-simplify-libcalls", arg)) {
                cmd.disable_simplify_libcalls = true;
            } else if (mem.testEqualString("--disable-tail-calls", arg)) {
                cmd.disable_tail_calls = true;
            } else if (mem.testEqualString("--do-counter-promotion", arg)) {
                cmd.do_counter_promotion = true;
            } else if (mem.testEqualString("--dwarf64", arg)) {
                cmd.dwarf64 = true;
            } else if (mem.testEqualString("--emit-call-site-info", arg)) {
                cmd.emit_call_site_info = true;
            } else if (mem.testEqualString("--emulated-tls", arg)) {
                cmd.emulated_tls = true;
            } else if (mem.testEqualString("--enable-approx-func-fp-math", arg)) {
                cmd.enable_approx_func_fp_math = true;
            } else if (mem.testEqualString("--enable-cse-in-irtranslator", arg)) {
                cmd.enable_cse_in_irtranslator = true;
            } else if (mem.testEqualString("--enable-cse-in-legalizer", arg)) {
                cmd.enable_cse_in_legalizer = true;
            } else if (mem.testEqualString("--enable-emscripten-cxx-exceptions", arg)) {
                cmd.enable_emscripten_cxx_exceptions = true;
            } else if (mem.testEqualString("--enable-emscripten-sjlj", arg)) {
                cmd.enable_emscripten_sjlj = true;
            } else if (mem.testEqualString("--enable-gvn-hoist", arg)) {
                cmd.enable_gvn_hoist = true;
            } else if (mem.testEqualString("--enable-gvn-sink", arg)) {
                cmd.enable_gvn_sink = true;
            } else if (mem.testEqualString("--enable-jmc-instrument", arg)) {
                cmd.enable_jmc_instrument = true;
            } else if (mem.testEqualString("--enable-name-compression", arg)) {
                cmd.enable_name_compression = true;
            } else if (mem.testEqualString("--enable-no-infs-fp-math", arg)) {
                cmd.enable_no_infs_fp_math = true;
            } else if (mem.testEqualString("--enable-no-nans-fp-math", arg)) {
                cmd.enable_no_nans_fp_math = true;
            } else if (mem.testEqualString("--enable-no-signed-zeros-fp-math", arg)) {
                cmd.enable_no_signed_zeros_fp_math = true;
            } else if (mem.testEqualString("--enable-no-trapping-fp-math", arg)) {
                cmd.enable_no_trapping_fp_math = true;
            } else if (mem.testEqualString("--enable-unsafe-fp-math", arg)) {
                cmd.enable_split_backedge_in_load_pre = true;
            } else if (mem.testEqualString("--enable-unsafe-fp-math", arg)) {
                cmd.enable_unsafe_fp_math = true;
            } else if (mem.testEqualString("--experimental-debug-variable-locations", arg)) {
                cmd.experimental_debug_variable_locations = true;
            } else if (mem.testEqualString("--fatal-warnings", arg)) {
                cmd.fatal_warnings = true;
            } else if (mem.testEqualString("--force-dwarf-frame-section", arg)) {
                cmd.force_dwarf_frame_section = true;
            } else if (mem.testEqualString("--function-sections", arg)) {
                cmd.function_sections = true;
            } else if (mem.testEqualString("--generate-merged-base-profiles", arg)) {
                cmd.generate_merged_base_profiles = true;
            } else if (mem.testEqualString("--hash-based-counter-split", arg)) {
                cmd.hash_based_counter_split = true;
            } else if (mem.testEqualString("--hot-cold-split", arg)) {
                cmd.hot_cold_split = true;
            } else if (mem.testEqualString("--ignore-xcoff-visibility", arg)) {
                cmd.ignore_xcoff_visibility = true;
            } else if (mem.testEqualString("--import-all-index", arg)) {
                cmd.import_all_index = true;
            } else if (mem.testEqualString("--incremental-linker-compatible", arg)) {
                cmd.incremental_linker_compatible = true;
            } else if (mem.testEqualString("--instcombine-code-sinking", arg)) {
                cmd.instcombine_code_sinking = true;
            } else if (mem.testEqualString("--instcombine-negator-enabled", arg)) {
                cmd.instcombine_negator_enabled = true;
            } else if (mem.testEqualString("--instrprof-atomic-counter-update-all", arg)) {
                cmd.instrprof_atomic_counter_update_all = true;
            } else if (mem.testEqualString("--mips16-constant-islands", arg)) {
                cmd.mips16_constant_islands = true;
            } else if (mem.testEqualString("--mips16-hard-float", arg)) {
                cmd.mips16_hard_float = true;
            } else if (mem.testEqualString("--mir-strip-debugify-only", arg)) {
                cmd.mir_strip_debugify_only = true;
            } else if (mem.testEqualString("--mno-compound", arg)) {
                cmd.mno_compound = true;
            } else if (mem.testEqualString("--mno-fixup", arg)) {
                cmd.mno_fixup = true;
            } else if (mem.testEqualString("--mno-ldc1-sdc1", arg)) {
                cmd.mno_ldc1_sdc1 = true;
            } else if (mem.testEqualString("--mno-pairing", arg)) {
                cmd.mno_pairing = true;
            } else if (mem.testEqualString("--mwarn-missing-parenthesis", arg)) {
                cmd.mwarn_missing_parenthesis = true;
            } else if (mem.testEqualString("--mwarn-noncontigious-register", arg)) {
                cmd.mwarn_noncontigious_register = true;
            } else if (mem.testEqualString("--mwarn-sign-mismatch", arg)) {
                cmd.mwarn_sign_mismatch = true;
            } else if (mem.testEqualString("--no-deprecated-warn", arg)) {
                cmd.no_deprecated_warn = true;
            } else if (mem.testEqualString("--no-discriminators", arg)) {
                cmd.no_discriminators = true;
            } else if (mem.testEqualString("--no-type-check", arg)) {
                cmd.no_type_check = true;
            } else if (mem.testEqualString("--no-warn", arg)) {
                cmd.no_warn = true;
            } else if (mem.testEqualString("--no-xray-index", arg)) {
                cmd.no_xray_index = true;
            } else if (mem.testEqualString("--nozero-initialized-in-bss", arg)) {
                cmd.nozero_initialized_in_bss = true;
            } else if (mem.testEqualString("--nvptx-sched4reg", arg)) {
                cmd.nvptx_sched4reg = true;
            } else if (mem.testEqualString("--opaque-pointers", arg)) {
                cmd.opaque_pointers = true;
            } else if (mem.testEqualString("--poison-checking-function-local", arg)) {
                cmd.poison_checking_function_local = true;
            } else if (mem.testEqualString("--print-pipeline-passes", arg)) {
                cmd.print_pipeline_passes = true;
            } else if (mem.testEqualString("--r600-ir-structurize", arg)) {
                cmd.r600_ir_structurize = true;
            } else if (mem.testEqualString("--rdf-dump", arg)) {
                cmd.rdf_dump = true;
            } else if (mem.testEqualString("--relax-elf-relocations", arg)) {
                cmd.relax_elf_relocations = true;
            } else {
                debug.write(llc_help);
            }
        }
    }
};
pub const FetchCommand = struct {
    /// Override the global cache directory
    global_cache_root: ?[]const u8 = null,
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *FetchCommand, zig_exe: []const u8, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, zig_exe);
        ptr[0] = 0;
        ptr += 1;
        ptr[0..5].* = "fetch".*;
        ptr += 5;
        if (cmd.global_cache_root) |global_cache_root| {
            ptr[0..19].* = "--global-cache-dir\x00".*;
            ptr += 19;
            ptr = fmt.strcpyEqu(ptr, global_cache_root);
            ptr[0] = 0;
            ptr += 1;
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *FetchCommand, zig_exe: []const u8) usize {
        @setRuntimeSafety(false);
        var len: usize = 0;
        len +%= zig_exe.len;
        len +%= 1;
        len +%= 5;
        if (cmd.global_cache_root) |global_cache_root| {
            len +%= 19;
            len +%= global_cache_root.len;
            len +%= 1;
        }
        return len;
    }
    pub fn formatWrite(cmd: *FetchCommand, zig_exe: []const u8, array: anytype) void {
        @setRuntimeSafety(false);
        array.writeMany(zig_exe);
        array.writeOne(0);
        array.writeMany("fetch");
        if (cmd.global_cache_root) |global_cache_root| {
            array.writeMany("--global-cache-dir\x00");
            array.writeMany(global_cache_root);
            array.writeOne(0);
        }
    }
    pub fn formatParseArgs(cmd: *FetchCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
            if (mem.testEqualString("--global-cache-dir", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.global_cache_root = mem.terminate(args[args_idx], 0);
                } else {
                    return;
                }
            } else {
                debug.write(fetch_help);
            }
            _ = allocator;
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
    pub const size_of: comptime_int = @sizeOf(@This());
    pub const align_of: comptime_int = @alignOf(@This());
    pub fn formatWriteBuf(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path, buf: [*]u8) usize {
        @setRuntimeSafety(false);
        var ptr: [*]u8 = buf;
        ptr = fmt.strcpyEqu(ptr, zig_exe);
        ptr[0] = 0;
        ptr += 1;
        ptr[0..4].* = "fmt\x00".*;
        ptr += 4;
        if (cmd.color) |color| {
            ptr[0..8].* = "--color\x00".*;
            ptr += 8;
            ptr = fmt.strcpyEqu(ptr, @tagName(color));
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
            ptr = fmt.strcpyEqu(ptr, exclude);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += pathname.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path) usize {
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
    pub fn formatWrite(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path, array: anytype) void {
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
    pub fn formatParseArgs(cmd: *FormatCommand, allocator: *types.Allocator, args: [][*:0]u8) void {
        @setRuntimeSafety(builtin.is_safe);
        var args_idx: usize = 0;
        while (args_idx != args.len) : (args_idx +%= 1) {
            var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
            } else {
                debug.write(format_help);
            }
            _ = allocator;
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
    \\    --main-mod-path                 Set the directory of the root package
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
    \\    -f[no-]function-sections        Places each function in a separate section
    \\    -f[no-]data-sections            Places data in separate sections
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
    \\    -f[no-]lld                      Use LLD as the linker
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
    \\    --deps                          Define module dependencies for the current target
    \\    -cflags                         Set extra flags for the next position C source files
    \\    -rcflags                        Set extra flags for the next positional .rc source files
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
    \\    --debug-incremental             Enable experimental feature: incremental compilation
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
    \\
    \\
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
    \\
    \\
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
    \\
    \\
;
const harec_help: [:0]const u8 =
    \\    -a
    \\    -o      Output file
    \\    -T
    \\    -t
    \\    -N
    \\
    \\
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
    \\
    \\
;
const llc_help: [:0]const u8 =
    \\    --color                                     Use colors in output (default=autodetect)
    \\    -I                                          Add directories to include search path
    \\    -O                                          Optimization level. [-O0, -O1, -O2, or -O3] (default='-O2')
    \\    --addrsig                                   Emit an address-significance table
    \\    --align-loops                               Default alignment for loops
    \\    --aarch64-use-aa                            Enable the use of AA during codegen.
    \\    --abort-on-max-devirt-iterations-reached    Abort when the max iterations for devirtualization CGSCC repeat pass is reached
    \\    --allow-ginsert-as-artifact                 Allow G_INSERT to be considered an artifact. Hack around AMDGPU test infinite loops.
    \\    --amdgpu-bypass-slow-div                    Skip 64-bit divide for dynamic 32-bit values
    \\    --amdgpu-disable-loop-alignment             Do not align and prefetch loops
    \\    --amdgpu-dpp-combine                        Enable DPP combiner
    \\    --amdgpu-dump-hsa-metadata                  Dump AMDGPU HSA Metadata
    \\    --amdgpu-enable-merge-m0                    Merge and hoist M0 initializations
    \\    --amdgpu-enable-power-sched                 Enable scheduling to minimize mAI power bursts
    \\    --amdgpu-sdwa-peephole                      Enable SDWA peepholer
    \\    --amdgpu-use-aa-in-codegen                  Enable the use of AA during codegen.
    \\    --amdgpu-verify-hsa-metadata                Verify AMDGPU HSA Metadata
    \\    --amdgpu-vgpr-index-mode                    Use GPR indexing mode instead of movrel for vector indexing
    \\    --asm-show-inst                             Emit internal instruction representation to assembly file
    \\    --asm-verbose                               Add comments to directives.
    \\    --atomic-counter-update-promoted            Do counter update using atomic fetch add  for promoted counters only
    \\    --atomic-first-counter                      Use atomic fetch add for first counter in a function (usually the entry counter)
    \\    --bounds-checking-single-trap               Use one trap block per function
    \\    --cs-profile-generate                       Perform context sensitive PGO instrumentation
    \\    --data-sections                             Emit data into separate sections
    \\    --debug-entry-values                        Enable debug info for the debug entry values.
    \\    --debug-info-correlate                      Use debug info to correlate profiles.
    \\    --debugify-quiet                            Suppress verbose debugify output
    \\    --disable-promote-alloca-to-lds             Disable promote alloca to LDS
    \\    --disable-promote-alloca-to-vector          Disable promote alloca to vector
    \\    --disable-simplify-libcalls                 Disable simplify-libcalls
    \\    --disable-tail-calls                        Never emit tail calls
    \\    --do-counter-promotion                      Do counter register promotion
    \\    --dwarf64                                   Generate debugging info in the 64-bit DWARF format
    \\    --emit-call-site-info                       Emit call site debug information, if debug information is enabled.
    \\    --emulated-tls                              Use emulated TLS model
    \\    --enable-approx-func-fp-math                Enable FP math optimizations that assume approx func
    \\    --enable-cse-in-irtranslator                Should enable CSE in irtranslator
    \\    --enable-cse-in-legalizer                   Should enable CSE in Legalizer
    \\    --enable-emscripten-cxx-exceptions          WebAssembly Emscripten-style exception handling
    \\    --enable-emscripten-sjlj                    WebAssembly Emscripten-style setjmp/longjmp handling
    \\    --enable-gvn-hoist                          Enable the GVN hoisting pass (default = off)
    \\    --enable-gvn-sink                           Enable the GVN sinking pass (default = off)
    \\    --enable-jmc-instrument                     Instrument functions with a call to __CheckForDebuggerJustMyCode
    \\    --enable-name-compression                   Enable name/filename string compression
    \\    --enable-no-infs-fp-math                    Enable FP math optimizations that assume no +-Infs
    \\    --enable-no-nans-fp-math                    Enable FP math optimizations that assume no NaNs
    \\    --enable-no-signed-zeros-fp-math            Enable FP math optimizations that assume the sign of 0 is insignificant
    \\    --enable-no-trapping-fp-math                Enable setting the FP exceptions build attribute not to use exceptions
    \\    --enable-unsafe-fp-math                     [MISSING]
    \\    --enable-unsafe-fp-math                     Enable optimizations that may decrease FP precision
    \\    --experimental-debug-variable-locations     Use experimental new value-tracking variable locations
    \\    --fatal-warnings                            Treat warnings as errors
    \\    --force-dwarf-frame-section                 Always emit a debug frame section.
    \\    --function-sections                         Emit functions into separate sections
    \\    --generate-merged-base-profiles             When generating nested context-sensitive profiles, always generate extra base profile for function with all its context profiles merged into it.
    \\    --hash-based-counter-split                  Rename counter variable of a comdat function based on cfg hash
    \\    --hot-cold-split                            Enable hot-cold splitting pass
    \\    --ignore-xcoff-visibility                   Not emit the visibility attribute for asm in AIX OS or give all symbols 'unspecified' visibility in XCOFF object file
    \\    --import-all-index                          Import all external functions in index.
    \\    --incremental-linker-compatible             When used with filetype=obj, emit an object file which can be used with an incremental linker
    \\    --instcombine-code-sinking                  Enable code sinking
    \\    --instcombine-negator-enabled               Should we attempt to sink negations?
    \\    --instrprof-atomic-counter-update-all       Make all profile counter updates atomic (for testing only)
    \\    --mips16-constant-islands                   Enable mips16 constant islands.
    \\    --mips16-hard-float                         Enable mips16 hard float.
    \\    --mir-strip-debugify-only                   Should mir-strip-debug only strip debug info from debugified modules by default
    \\    --mno-compound                              Disable looking for compound instructions for Hexagon
    \\    --mno-fixup                                 Disable fixing up resolved relocations for Hexagon
    \\    --mno-ldc1-sdc1                             Expand double precision loads and stores to their single precision counterparts
    \\    --mno-pairing                               Disable looking for duplex instructions for Hexagon
    \\    --mwarn-missing-parenthesis                 Warn for missing parenthesis around predicate registers
    \\    --mwarn-noncontigious-register              Warn for register names that arent contigious
    \\    --mwarn-sign-mismatch                       Warn for mismatching a signed and unsigned value
    \\    --no-deprecated-warn                        Suppress all deprecated warnings
    \\    --no-discriminators                         Disable generation of discriminator information.
    \\    --no-type-check                             Suppress type errors (Wasm)
    \\    --no-warn                                   Suppress all warnings
    \\    --no-xray-index                             Don't emit xray_fn_idx section
    \\    --nozero-initialized-in-bss                 Don't place zero-initialized symbols into bss section
    \\    --nvptx-sched4reg                           NVPTX Specific: schedule for register pressue
    \\    --opaque-pointers                           Use opaque pointers
    \\    --poison-checking-function-local            Check that returns are non-poison (for testing)
    \\    --print-pipeline-passes                     Print a '-passes' compatible string describing the pipeline (best-effort only).
    \\    --r600-ir-structurize                       Use StructurizeCFG IR pass
    \\    --rdf-dump                                  -
    \\    --relax-elf-relocations                     Emit GOTPCRELX/REX_GOTPCRELX instead of GOTPCREL on x86-64 ELF
    \\
    \\
;
const fetch_help: [:0]const u8 =
    \\    fetch
    \\    --global-cache-dir      Override the global cache directory
    \\
    \\
;
const format_help: [:0]const u8 =
    \\    fmt
    \\    --color         Enable or disable colored error messages
    \\    --stdin         Format code from stdin; output to stdout
    \\    --check         List non-conforming files and exit with an error if the list is non-empty
    \\    --ast-check     Run zig ast-check on every file
    \\    --exclude       Exclude file or directory from formatting
    \\
    \\
;
pub const Command = struct {
    build: *BuildCommand,
    archive: *ArchiveCommand,
    objcopy: *ObjcopyCommand,
    harec: *HarecCommand,
    tblgen: *TableGenCommand,
    llc: *LLCCommand,
    fetch: *FetchCommand,
    format: *FormatCommand,
};
