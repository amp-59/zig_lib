const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const debug = @import("../debug.zig");
const parse = @import("../parse.zig");
const builtin = @import("../builtin.zig");
const types = @import("types.zig");
const tasks = @import("tasks.zig");
pub const PathUnion = union(enum) {
    yes: ?types.Path,
    no,
};
pub const StringUnion = union(enum) {
    yes: ?[]const u8,
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
    cpu: ?enum(u7) {
        alderlake = 0,
        amdfam10 = 1,
        athlon = 2,
        athlon64 = 3,
        athlon64_sse3 = 4,
        athlon_4 = 5,
        athlon_fx = 6,
        athlon_mp = 7,
        athlon_tbird = 8,
        athlon_xp = 9,
        atom = 10,
        atom_sse4_2_movbe = 11,
        barcelona = 12,
        bdver1 = 13,
        bdver2 = 14,
        bdver3 = 15,
        bdver4 = 16,
        bonnell = 17,
        broadwell = 18,
        btver1 = 19,
        btver2 = 20,
        c3 = 21,
        c3_2 = 22,
        cannonlake = 23,
        cascadelake = 24,
        cooperlake = 25,
        core2 = 26,
        corei7 = 27,
        emeraldrapids = 28,
        generic = 29,
        geode = 30,
        goldmont = 31,
        goldmont_plus = 32,
        grandridge = 33,
        graniterapids = 34,
        graniterapids_d = 35,
        haswell = 36,
        i386 = 37,
        i486 = 38,
        i586 = 39,
        i686 = 40,
        icelake_client = 41,
        icelake_server = 42,
        ivybridge = 43,
        k6 = 44,
        k6_2 = 45,
        k6_3 = 46,
        k8 = 47,
        k8_sse3 = 48,
        knl = 49,
        knm = 50,
        lakemont = 51,
        meteorlake = 52,
        nehalem = 53,
        nocona = 54,
        opteron = 55,
        opteron_sse3 = 56,
        penryn = 57,
        pentium = 58,
        pentium2 = 59,
        pentium3 = 60,
        pentium3m = 61,
        pentium4 = 62,
        pentium_m = 63,
        pentium_mmx = 64,
        pentiumpro = 65,
        prescott = 66,
        raptorlake = 67,
        rocketlake = 68,
        sandybridge = 69,
        sapphirerapids = 70,
        sierraforest = 71,
        silvermont = 72,
        skx = 73,
        skylake = 74,
        skylake_avx512 = 75,
        slm = 76,
        tigerlake = 77,
        tremont = 78,
        westmere = 79,
        winchip2 = 80,
        winchip_c6 = 81,
        x86_64 = 82,
        x86_64_v2 = 83,
        x86_64_v3 = 84,
        x86_64_v4 = 85,
        yonah = 86,
        znver1 = 87,
        znver2 = 88,
        znver3 = 89,
        znver4 = 90,
    } = null,
    /// Limit range of code and data virtual addresses
    code_model: ?builtin.CodeModel = null,
    /// Enable the "red-zone"
    red_zone: ?bool = null,
    /// Enable implicit builtin knowledge of functions
    implicit_builtins: ?bool = null,
    /// Enables panic causes:
    ///   memcpy_argument_aliasing
    ///   memcpy_argument_lengths_mismatched
    ///   for_loop_capture_lengths_mismatched
    panic_mismatched_arguments: ?bool = null,
    /// Enables panic causes:
    ///   message
    ///   discarded_error
    ///   corrupt_switch
    ///   returned_noreturn
    ///   reached_unreachable
    ///   accessed_null_value
    panic_reached_unreachable: ?bool = null,
    /// Enables panic causes:
    ///   accessed_out_of_bounds
    ///   accessed_out_of_order
    ///   accessed_inactive_field
    panic_accessed_invalid_memory: ?bool = null,
    /// Enables panic causes:
    ///   mismatched_sentinel
    ///   mismatched_non_scalar_sentinel
    panic_mismatched_sentinel: ?bool = null,
    /// Enables panic causes:
    ///   div_with_remainder
    ///   shl_overflowed
    ///   shr_overflowed
    ///   shift_amt_overflowed
    panic_arith_lost_precision: ?bool = null,
    /// Enables panic causes:
    ///   mul_overflowed
    ///   add_overflowed
    ///   sub_overflowed
    panic_arith_overflowed: ?bool = null,
    /// Enables panic causes:
    ///   cast_to_int_from_invalid
    ///   cast_truncated_data
    ///   cast_to_unsigned_from_negative
    ///   cast_to_pointer_from_invalid
    ///   cast_to_enum_from_invalid
    ///   cast_to_error_from_invalid
    panic_cast_from_invalid: ?bool = null,
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
    /// Override the default entry symbol name
    entry: ?union(enum) {
        yes: []const u8,
        no,
    } = null,
    /// Use LLD as the linker
    lld: ?bool = null,
    /// Use LLVM as the codegen backend
    llvm: ?bool = null,
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
    /// Force removal of functions and data that are unreachable by the entry point or exported symbols
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
                        ptr = fmt.strcpyEqu(ptr, "-femit-bin\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-bin\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-bin\x00");
                },
            }
        }
        if (cmd.emit_asm) |emit_asm| {
            switch (emit_asm) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-asm\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-asm\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-asm\x00");
                },
            }
        }
        if (cmd.emit_llvm_ir) |emit_llvm_ir| {
            switch (emit_llvm_ir) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-llvm-ir\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-llvm-ir\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-llvm-ir\x00");
                },
            }
        }
        if (cmd.emit_llvm_bc) |emit_llvm_bc| {
            switch (emit_llvm_bc) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-llvm-bc\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-llvm-bc\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-llvm-bc\x00");
                },
            }
        }
        if (cmd.emit_h) |emit_h| {
            switch (emit_h) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-h\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-h\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-h\x00");
                },
            }
        }
        if (cmd.emit_docs) |emit_docs| {
            switch (emit_docs) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-docs\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-docs\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-docs\x00");
                },
            }
        }
        if (cmd.emit_analysis) |emit_analysis| {
            switch (emit_analysis) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-analysis\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-analysis\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-analysis\x00");
                },
            }
        }
        if (cmd.emit_implib) |emit_implib| {
            switch (emit_implib) {
                .yes => |yes| {
                    if (yes) |arg| {
                        ptr = fmt.strcpyEqu(ptr, "-femit-implib\x3d");
                        ptr += arg.formatWriteBuf(ptr);
                    } else {
                        ptr = fmt.strcpyEqu(ptr, "-femit-implib\x00");
                    }
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-emit-implib\x00");
                },
            }
        }
        if (cmd.cache_root) |cache_root| {
            ptr = fmt.strcpyEqu(ptr, "--cache-dir\x00");
            ptr = fmt.strcpyEqu(ptr, cache_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            ptr = fmt.strcpyEqu(ptr, "--global-cache-dir\x00");
            ptr = fmt.strcpyEqu(ptr, global_cache_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            ptr = fmt.strcpyEqu(ptr, "--zig-lib-dir\x00");
            ptr = fmt.strcpyEqu(ptr, zig_lib_root);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.listen) |listen| {
            ptr = fmt.strcpyEqu(ptr, "--listen\x00");
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
            ptr = fmt.strcpyEqu(ptr, @tagName(cpu));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.code_model) |code_model| {
            ptr = fmt.strcpyEqu(ptr, "-mcmodel\x00");
            ptr = fmt.strcpyEqu(ptr, @tagName(code_model));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.red_zone) |red_zone| {
            if (red_zone) {
                ptr = fmt.strcpyEqu(ptr, "-mred-zone\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-mno-red-zone\x00");
            }
        }
        if (cmd.implicit_builtins) |implicit_builtins| {
            if (implicit_builtins) {
                ptr = fmt.strcpyEqu(ptr, "-fbuiltin\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-builtin\x00");
            }
        }
        if (cmd.panic_mismatched_arguments) |panic_mismatched_arguments| {
            if (panic_mismatched_arguments) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-mismatched-arguments\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-mismatched-arguments\x00");
            }
        }
        if (cmd.panic_reached_unreachable) |panic_reached_unreachable| {
            if (panic_reached_unreachable) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-reached-unreachable\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-reached-unreachable\x00");
            }
        }
        if (cmd.panic_accessed_invalid_memory) |panic_accessed_invalid_memory| {
            if (panic_accessed_invalid_memory) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-accessed-invalid-memory\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-accessed-invalid-memory\x00");
            }
        }
        if (cmd.panic_mismatched_sentinel) |panic_mismatched_sentinel| {
            if (panic_mismatched_sentinel) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-mismatched-sentinel\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-mismatched-sentinel\x00");
            }
        }
        if (cmd.panic_arith_lost_precision) |panic_arith_lost_precision| {
            if (panic_arith_lost_precision) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-arith-lost-precision\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-arith-lost-precision\x00");
            }
        }
        if (cmd.panic_arith_overflowed) |panic_arith_overflowed| {
            if (panic_arith_overflowed) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-arith-overflowed\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-arith-overflowed\x00");
            }
        }
        if (cmd.panic_cast_from_invalid) |panic_cast_from_invalid| {
            if (panic_cast_from_invalid) {
                ptr = fmt.strcpyEqu(ptr, "-fpanic-cast-from-invalid\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-panic-cast-from-invalid\x00");
            }
        }
        if (cmd.omit_frame_pointer) |omit_frame_pointer| {
            if (omit_frame_pointer) {
                ptr = fmt.strcpyEqu(ptr, "-fomit-frame-pointer\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-omit-frame-pointer\x00");
            }
        }
        if (cmd.exec_model) |exec_model| {
            ptr = fmt.strcpyEqu(ptr, "-mexec-model\x00");
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
                    ptr = fmt.strcpyEqu(ptr, "-fsoname\x00");
                    ptr = fmt.strcpyEqu(ptr, arg);
                    ptr[0] = 0;
                    ptr += 1;
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-soname\x00");
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
            ptr = fmt.strcpyEqu(ptr, "-fopt-bisect-limit\x3d");
            ptr = fmt.Ud64.write(ptr, passes);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.main_mod_path) |main_mod_path| {
            ptr = fmt.strcpyEqu(ptr, "--main-mod-path\x00");
            ptr = fmt.strcpyEqu(ptr, main_mod_path);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.pic) |pic| {
            if (pic) {
                ptr[0..6].* = "-fPIC\x00".*;
                ptr += 6;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-PIC\x00");
            }
        }
        if (cmd.pie) |pie| {
            if (pie) {
                ptr[0..6].* = "-fPIE\x00".*;
                ptr += 6;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-PIE\x00");
            }
        }
        if (cmd.lto) |lto| {
            if (lto) {
                ptr[0..6].* = "-flto\x00".*;
                ptr += 6;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-lto\x00");
            }
        }
        if (cmd.stack_check) |stack_check| {
            if (stack_check) {
                ptr = fmt.strcpyEqu(ptr, "-fstack-check\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-stack-check\x00");
            }
        }
        if (cmd.stack_protector) |stack_protector| {
            if (stack_protector) {
                ptr = fmt.strcpyEqu(ptr, "-fstack-protector\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-stack-protector\x00");
            }
        }
        if (cmd.sanitize_c) |sanitize_c| {
            if (sanitize_c) {
                ptr = fmt.strcpyEqu(ptr, "-fsanitize-c\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-c\x00");
            }
        }
        if (cmd.valgrind) |valgrind| {
            if (valgrind) {
                ptr = fmt.strcpyEqu(ptr, "-fvalgrind\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-valgrind\x00");
            }
        }
        if (cmd.sanitize_thread) |sanitize_thread| {
            if (sanitize_thread) {
                ptr = fmt.strcpyEqu(ptr, "-fsanitize-thread\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-sanitize-thread\x00");
            }
        }
        if (cmd.unwind_tables) |unwind_tables| {
            if (unwind_tables) {
                ptr = fmt.strcpyEqu(ptr, "-funwind-tables\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-unwind-tables\x00");
            }
        }
        if (cmd.reference_trace) |reference_trace| {
            if (reference_trace) {
                ptr = fmt.strcpyEqu(ptr, "-freference-trace\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-reference-trace\x00");
            }
        }
        if (cmd.error_tracing) |error_tracing| {
            if (error_tracing) {
                ptr = fmt.strcpyEqu(ptr, "-ferror-tracing\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-error-tracing\x00");
            }
        }
        if (cmd.single_threaded) |single_threaded| {
            if (single_threaded) {
                ptr = fmt.strcpyEqu(ptr, "-fsingle-threaded\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-single-threaded\x00");
            }
        }
        if (cmd.function_sections) |function_sections| {
            if (function_sections) {
                ptr = fmt.strcpyEqu(ptr, "-ffunction-sections\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-function-sections\x00");
            }
        }
        if (cmd.data_sections) |data_sections| {
            if (data_sections) {
                ptr = fmt.strcpyEqu(ptr, "-fdata-sections\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-data-sections\x00");
            }
        }
        if (cmd.strip) |strip| {
            if (strip) {
                ptr[0..8].* = "-fstrip\x00".*;
                ptr += 8;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-strip\x00");
            }
        }
        if (cmd.formatted_panics) |formatted_panics| {
            if (formatted_panics) {
                ptr = fmt.strcpyEqu(ptr, "-fformatted-panics\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-formatted-panics\x00");
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
            ptr = fmt.strcpyEqu(ptr, "-idirafter\x00");
            ptr = fmt.strcpyEqu(ptr, dirafter);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.system) |system| {
            ptr = fmt.strcpyEqu(ptr, "-isystem\x00");
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
            ptr = fmt.strcpyEqu(ptr, "--library\x00");
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
                ptr = fmt.strcpyEqu(ptr, "--needed-library\x00");
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                ptr = fmt.strcpyEqu(ptr, "--library-directory\x00");
                ptr = fmt.strcpyEqu(ptr, value);
                ptr[0] = 0;
                ptr += 1;
            }
        }
        if (cmd.link_script) |link_script| {
            ptr = fmt.strcpyEqu(ptr, "--script\x00");
            ptr = fmt.strcpyEqu(ptr, link_script);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.version_script) |version_script| {
            ptr = fmt.strcpyEqu(ptr, "--version-script\x00");
            ptr = fmt.strcpyEqu(ptr, version_script);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            ptr = fmt.strcpyEqu(ptr, "--dynamic-linker\x00");
            ptr = fmt.strcpyEqu(ptr, dynamic_linker);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.sysroot) |sysroot| {
            ptr = fmt.strcpyEqu(ptr, "--sysroot\x00");
            ptr = fmt.strcpyEqu(ptr, sysroot);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.entry) |entry| {
            switch (entry) {
                .yes => |arg| {
                    ptr[0..8].* = "-fentry\x3d".*;
                    ptr += 8;
                    ptr = fmt.strcpyEqu(ptr, arg);
                    ptr[0] = 0;
                    ptr += 1;
                },
                .no => {
                    ptr = fmt.strcpyEqu(ptr, "-fno-entry\x00");
                },
            }
        }
        if (cmd.lld) |lld| {
            if (lld) {
                ptr[0..6].* = "-flld\x00".*;
                ptr += 6;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-lld\x00");
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                ptr[0..7].* = "-fllvm\x00".*;
                ptr += 7;
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-llvm\x00");
            }
        }
        if (cmd.compiler_rt) |compiler_rt| {
            if (compiler_rt) {
                ptr = fmt.strcpyEqu(ptr, "-fcompiler-rt\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-compiler-rt\x00");
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
                ptr = fmt.strcpyEqu(ptr, "-feach-lib-rpath\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-each-lib-rpath\x00");
            }
        }
        if (cmd.allow_shlib_undefined) |allow_shlib_undefined| {
            if (allow_shlib_undefined) {
                ptr = fmt.strcpyEqu(ptr, "-fallow-shlib-undefined\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "-fno-allow-shlib-undefined\x00");
            }
        }
        if (cmd.build_id) |build_id| {
            ptr = fmt.strcpyEqu(ptr, "--build-id\x3d");
            ptr = fmt.strcpyEqu(ptr, @tagName(build_id));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.eh_frame_hdr) {
            ptr = fmt.strcpyEqu(ptr, "--eh-frame-hdr\x00");
        }
        if (cmd.emit_relocs) {
            ptr = fmt.strcpyEqu(ptr, "--emit-relocs\x00");
        }
        if (cmd.gc_sections) |gc_sections| {
            if (gc_sections) {
                ptr = fmt.strcpyEqu(ptr, "--gc-sections\x00");
            } else {
                ptr = fmt.strcpyEqu(ptr, "--no-gc-sections\x00");
            }
        }
        if (cmd.stack) |stack| {
            ptr[0..8].* = "--stack\x00".*;
            ptr += 8;
            ptr = fmt.Ud64.write(ptr, stack);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.image_base) |image_base| {
            ptr = fmt.strcpyEqu(ptr, "--image-base\x00");
            ptr = fmt.Ud64.write(ptr, image_base);
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
            ptr = fmt.strcpyEqu(ptr, "-rdynamic\x00");
        }
        if (cmd.dynamic) {
            ptr = fmt.strcpyEqu(ptr, "-dynamic\x00");
        }
        if (cmd.static) {
            ptr[0..8].* = "-static\x00".*;
            ptr += 8;
        }
        if (cmd.symbolic) {
            ptr = fmt.strcpyEqu(ptr, "-Bsymbolic\x00");
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
            ptr = fmt.strcpyEqu(ptr, "--debug-incremental\x00");
        }
        if (cmd.time_report) {
            ptr = fmt.strcpyEqu(ptr, "-ftime-report\x00");
        }
        if (cmd.stack_report) {
            ptr = fmt.strcpyEqu(ptr, "-fstack-report\x00");
        }
        if (cmd.verbose_link) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-link\x00");
        }
        if (cmd.verbose_cc) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-cc\x00");
        }
        if (cmd.verbose_air) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-air\x00");
        }
        if (cmd.verbose_mir) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-mir\x00");
        }
        if (cmd.verbose_llvm_ir) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-llvm-ir\x00");
        }
        if (cmd.verbose_cimport) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-cimport\x00");
        }
        if (cmd.verbose_llvm_cpu_features) {
            ptr = fmt.strcpyEqu(ptr, "--verbose-llvm-cpu-features\x00");
        }
        if (cmd.debug_log) |debug_log| {
            ptr = fmt.strcpyEqu(ptr, "--debug-log\x00");
            ptr = fmt.strcpyEqu(ptr, debug_log);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.debug_compiler_errors) {
            ptr = fmt.strcpyEqu(ptr, "--debug-compile-errors\x00");
        }
        if (cmd.debug_link_snapshot) {
            ptr = fmt.strcpyEqu(ptr, "--debug-link-snapshot\x00");
        }
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *BuildCommand, zig_exe: []const u8, files: []const types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 8 +% zig_exe.len +% @tagName(cmd.kind).len;
        if (cmd.emit_bin) |emit_bin| {
            switch (emit_bin) {
                .yes => |yes| {
                    if (yes) |arg| {
                        len +%= 11 +% arg.formatLength();
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
                        len +%= 11 +% arg.formatLength();
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
                        len +%= 15 +% arg.formatLength();
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
                        len +%= 15 +% arg.formatLength();
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
                        len +%= 9 +% arg.formatLength();
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
                        len +%= 12 +% arg.formatLength();
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
                        len +%= 16 +% arg.formatLength();
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
                        len +%= 14 +% arg.formatLength();
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
            len +%= 13 +% cache_root.len;
        }
        if (cmd.global_cache_root) |global_cache_root| {
            len +%= 20 +% global_cache_root.len;
        }
        if (cmd.zig_lib_root) |zig_lib_root| {
            len +%= 15 +% zig_lib_root.len;
        }
        if (cmd.listen) |listen| {
            len +%= 10 +% @tagName(listen).len;
        }
        if (cmd.target) |target| {
            len +%= 9 +% target.len;
        }
        if (cmd.cpu) |cpu| {
            len +%= 7 +% @tagName(cpu).len;
        }
        if (cmd.code_model) |code_model| {
            len +%= 10 +% @tagName(code_model).len;
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
        if (cmd.panic_mismatched_arguments) |panic_mismatched_arguments| {
            if (panic_mismatched_arguments) {
                len +%= 29;
            } else {
                len +%= 32;
            }
        }
        if (cmd.panic_reached_unreachable) |panic_reached_unreachable| {
            if (panic_reached_unreachable) {
                len +%= 28;
            } else {
                len +%= 31;
            }
        }
        if (cmd.panic_accessed_invalid_memory) |panic_accessed_invalid_memory| {
            if (panic_accessed_invalid_memory) {
                len +%= 32;
            } else {
                len +%= 35;
            }
        }
        if (cmd.panic_mismatched_sentinel) |panic_mismatched_sentinel| {
            if (panic_mismatched_sentinel) {
                len +%= 28;
            } else {
                len +%= 31;
            }
        }
        if (cmd.panic_arith_lost_precision) |panic_arith_lost_precision| {
            if (panic_arith_lost_precision) {
                len +%= 29;
            } else {
                len +%= 32;
            }
        }
        if (cmd.panic_arith_overflowed) |panic_arith_overflowed| {
            if (panic_arith_overflowed) {
                len +%= 25;
            } else {
                len +%= 28;
            }
        }
        if (cmd.panic_cast_from_invalid) |panic_cast_from_invalid| {
            if (panic_cast_from_invalid) {
                len +%= 26;
            } else {
                len +%= 29;
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
            len +%= 14 +% exec_model.len;
        }
        if (cmd.name) |name| {
            len +%= 8 +% name.len;
        }
        if (cmd.soname) |soname| {
            switch (soname) {
                .yes => |arg| {
                    len +%= 10 +% arg.len;
                },
                .no => {
                    len +%= 12;
                },
            }
        }
        if (cmd.mode) |mode| {
            len +%= 4 +% @tagName(mode).len;
        }
        if (cmd.passes) |passes| {
            len +%= 20 +% fmt.Ud64.length(passes);
        }
        if (cmd.main_mod_path) |main_mod_path| {
            len +%= 17 +% main_mod_path.len;
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
            len +%= 7 +% @tagName(format).len;
        }
        if (cmd.dirafter) |dirafter| {
            len +%= 12 +% dirafter.len;
        }
        if (cmd.system) |system| {
            len +%= 10 +% system.len;
        }
        if (cmd.libc) |libc| {
            len +%= 8 +% libc.len;
        }
        if (cmd.library) |library| {
            len +%= 11 +% library.len;
        }
        if (cmd.include) |include| {
            for (include) |value| {
                len +%= 4 +% value.len;
            }
        }
        if (cmd.needed_library) |needed_library| {
            for (needed_library) |value| {
                len +%= 18 +% value.len;
            }
        }
        if (cmd.library_directory) |library_directory| {
            for (library_directory) |value| {
                len +%= 21 +% value.len;
            }
        }
        if (cmd.link_script) |link_script| {
            len +%= 10 +% link_script.len;
        }
        if (cmd.version_script) |version_script| {
            len +%= 18 +% version_script.len;
        }
        if (cmd.dynamic_linker) |dynamic_linker| {
            len +%= 18 +% dynamic_linker.len;
        }
        if (cmd.sysroot) |sysroot| {
            len +%= 11 +% sysroot.len;
        }
        if (cmd.entry) |entry| {
            switch (entry) {
                .yes => |arg| {
                    len +%= 9 +% arg.len;
                },
                .no => {
                    len +%= 11;
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
        if (cmd.llvm) |llvm| {
            if (llvm) {
                len +%= 7;
            } else {
                len +%= 10;
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
            len +%= 8 +% rpath.len;
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
            len +%= 12 +% @tagName(build_id).len;
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
            len +%= 9 +% fmt.Ud64.length(stack);
        }
        if (cmd.image_base) |image_base| {
            len +%= 14 +% fmt.Ud64.length(image_base);
        }
        if (cmd.macros) |macros| {
            for (macros) |value| {
                len = len +% value.formatLength();
            }
        }
        if (cmd.modules) |modules| {
            for (modules) |value| {
                len = len +% value.formatLength();
            }
        }
        if (cmd.dependencies) |dependencies| {
            len = len +% types.ModuleDependencies.formatLength(.{ .value = dependencies });
        }
        if (cmd.cflags) |cflags| {
            len = len +% types.ExtraFlags.formatLength(.{ .value = cflags });
        }
        if (cmd.rcflags) |rcflags| {
            len = len +% types.ExtraFlags.formatLength(.{ .value = rcflags });
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
                len +%= 4 +% @tagName(value).len;
            }
        }
        for (files) |value| {
            len = len +% value.formatLength();
        }
        if (cmd.color) |color| {
            len +%= 9 +% @tagName(color).len;
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
            len +%= 13 +% debug_log.len;
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
            array.writeMany(@tagName(cpu));
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
        if (cmd.panic_mismatched_arguments) |panic_mismatched_arguments| {
            if (panic_mismatched_arguments) {
                array.writeMany("-fpanic-mismatched-arguments\x00");
            } else {
                array.writeMany("-fno-panic-mismatched-arguments\x00");
            }
        }
        if (cmd.panic_reached_unreachable) |panic_reached_unreachable| {
            if (panic_reached_unreachable) {
                array.writeMany("-fpanic-reached-unreachable\x00");
            } else {
                array.writeMany("-fno-panic-reached-unreachable\x00");
            }
        }
        if (cmd.panic_accessed_invalid_memory) |panic_accessed_invalid_memory| {
            if (panic_accessed_invalid_memory) {
                array.writeMany("-fpanic-accessed-invalid-memory\x00");
            } else {
                array.writeMany("-fno-panic-accessed-invalid-memory\x00");
            }
        }
        if (cmd.panic_mismatched_sentinel) |panic_mismatched_sentinel| {
            if (panic_mismatched_sentinel) {
                array.writeMany("-fpanic-mismatched-sentinel\x00");
            } else {
                array.writeMany("-fno-panic-mismatched-sentinel\x00");
            }
        }
        if (cmd.panic_arith_lost_precision) |panic_arith_lost_precision| {
            if (panic_arith_lost_precision) {
                array.writeMany("-fpanic-arith-lost-precision\x00");
            } else {
                array.writeMany("-fno-panic-arith-lost-precision\x00");
            }
        }
        if (cmd.panic_arith_overflowed) |panic_arith_overflowed| {
            if (panic_arith_overflowed) {
                array.writeMany("-fpanic-arith-overflowed\x00");
            } else {
                array.writeMany("-fno-panic-arith-overflowed\x00");
            }
        }
        if (cmd.panic_cast_from_invalid) |panic_cast_from_invalid| {
            if (panic_cast_from_invalid) {
                array.writeMany("-fpanic-cast-from-invalid\x00");
            } else {
                array.writeMany("-fno-panic-cast-from-invalid\x00");
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
            switch (entry) {
                .yes => |arg| {
                    array.writeMany("-fentry\x3d");
                    array.writeMany(arg);
                    array.writeOne(0);
                },
                .no => {
                    array.writeMany("-fno-entry\x00");
                },
            }
        }
        if (cmd.lld) |lld| {
            if (lld) {
                array.writeMany("-flld\x00");
            } else {
                array.writeMany("-fno-lld\x00");
            }
        }
        if (cmd.llvm) |llvm| {
            if (llvm) {
                array.writeMany("-fllvm\x00");
            } else {
                array.writeMany("-fno-llvm\x00");
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
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                if (mem.testEqualString("alderlake", arg)) {
                    cmd.cpu = .alderlake;
                } else if (mem.testEqualString("amdfam10", arg)) {
                    cmd.cpu = .amdfam10;
                } else if (mem.testEqualString("athlon", arg)) {
                    cmd.cpu = .athlon;
                } else if (mem.testEqualString("athlon64", arg)) {
                    cmd.cpu = .athlon64;
                } else if (mem.testEqualString("athlon64_sse3", arg)) {
                    cmd.cpu = .athlon64_sse3;
                } else if (mem.testEqualString("athlon_4", arg)) {
                    cmd.cpu = .athlon_4;
                } else if (mem.testEqualString("athlon_fx", arg)) {
                    cmd.cpu = .athlon_fx;
                } else if (mem.testEqualString("athlon_mp", arg)) {
                    cmd.cpu = .athlon_mp;
                } else if (mem.testEqualString("athlon_tbird", arg)) {
                    cmd.cpu = .athlon_tbird;
                } else if (mem.testEqualString("athlon_xp", arg)) {
                    cmd.cpu = .athlon_xp;
                } else if (mem.testEqualString("atom", arg)) {
                    cmd.cpu = .atom;
                } else if (mem.testEqualString("atom_sse4_2_movbe", arg)) {
                    cmd.cpu = .atom_sse4_2_movbe;
                } else if (mem.testEqualString("barcelona", arg)) {
                    cmd.cpu = .barcelona;
                } else if (mem.testEqualString("bdver1", arg)) {
                    cmd.cpu = .bdver1;
                } else if (mem.testEqualString("bdver2", arg)) {
                    cmd.cpu = .bdver2;
                } else if (mem.testEqualString("bdver3", arg)) {
                    cmd.cpu = .bdver3;
                } else if (mem.testEqualString("bdver4", arg)) {
                    cmd.cpu = .bdver4;
                } else if (mem.testEqualString("bonnell", arg)) {
                    cmd.cpu = .bonnell;
                } else if (mem.testEqualString("broadwell", arg)) {
                    cmd.cpu = .broadwell;
                } else if (mem.testEqualString("btver1", arg)) {
                    cmd.cpu = .btver1;
                } else if (mem.testEqualString("btver2", arg)) {
                    cmd.cpu = .btver2;
                } else if (mem.testEqualString("c3", arg)) {
                    cmd.cpu = .c3;
                } else if (mem.testEqualString("c3_2", arg)) {
                    cmd.cpu = .c3_2;
                } else if (mem.testEqualString("cannonlake", arg)) {
                    cmd.cpu = .cannonlake;
                } else if (mem.testEqualString("cascadelake", arg)) {
                    cmd.cpu = .cascadelake;
                } else if (mem.testEqualString("cooperlake", arg)) {
                    cmd.cpu = .cooperlake;
                } else if (mem.testEqualString("core2", arg)) {
                    cmd.cpu = .core2;
                } else if (mem.testEqualString("corei7", arg)) {
                    cmd.cpu = .corei7;
                } else if (mem.testEqualString("emeraldrapids", arg)) {
                    cmd.cpu = .emeraldrapids;
                } else if (mem.testEqualString("generic", arg)) {
                    cmd.cpu = .generic;
                } else if (mem.testEqualString("geode", arg)) {
                    cmd.cpu = .geode;
                } else if (mem.testEqualString("goldmont", arg)) {
                    cmd.cpu = .goldmont;
                } else if (mem.testEqualString("goldmont_plus", arg)) {
                    cmd.cpu = .goldmont_plus;
                } else if (mem.testEqualString("grandridge", arg)) {
                    cmd.cpu = .grandridge;
                } else if (mem.testEqualString("graniterapids", arg)) {
                    cmd.cpu = .graniterapids;
                } else if (mem.testEqualString("graniterapids_d", arg)) {
                    cmd.cpu = .graniterapids_d;
                } else if (mem.testEqualString("haswell", arg)) {
                    cmd.cpu = .haswell;
                } else if (mem.testEqualString("i386", arg)) {
                    cmd.cpu = .i386;
                } else if (mem.testEqualString("i486", arg)) {
                    cmd.cpu = .i486;
                } else if (mem.testEqualString("i586", arg)) {
                    cmd.cpu = .i586;
                } else if (mem.testEqualString("i686", arg)) {
                    cmd.cpu = .i686;
                } else if (mem.testEqualString("icelake_client", arg)) {
                    cmd.cpu = .icelake_client;
                } else if (mem.testEqualString("icelake_server", arg)) {
                    cmd.cpu = .icelake_server;
                } else if (mem.testEqualString("ivybridge", arg)) {
                    cmd.cpu = .ivybridge;
                } else if (mem.testEqualString("k6", arg)) {
                    cmd.cpu = .k6;
                } else if (mem.testEqualString("k6_2", arg)) {
                    cmd.cpu = .k6_2;
                } else if (mem.testEqualString("k6_3", arg)) {
                    cmd.cpu = .k6_3;
                } else if (mem.testEqualString("k8", arg)) {
                    cmd.cpu = .k8;
                } else if (mem.testEqualString("k8_sse3", arg)) {
                    cmd.cpu = .k8_sse3;
                } else if (mem.testEqualString("knl", arg)) {
                    cmd.cpu = .knl;
                } else if (mem.testEqualString("knm", arg)) {
                    cmd.cpu = .knm;
                } else if (mem.testEqualString("lakemont", arg)) {
                    cmd.cpu = .lakemont;
                } else if (mem.testEqualString("meteorlake", arg)) {
                    cmd.cpu = .meteorlake;
                } else if (mem.testEqualString("nehalem", arg)) {
                    cmd.cpu = .nehalem;
                } else if (mem.testEqualString("nocona", arg)) {
                    cmd.cpu = .nocona;
                } else if (mem.testEqualString("opteron", arg)) {
                    cmd.cpu = .opteron;
                } else if (mem.testEqualString("opteron_sse3", arg)) {
                    cmd.cpu = .opteron_sse3;
                } else if (mem.testEqualString("penryn", arg)) {
                    cmd.cpu = .penryn;
                } else if (mem.testEqualString("pentium", arg)) {
                    cmd.cpu = .pentium;
                } else if (mem.testEqualString("pentium2", arg)) {
                    cmd.cpu = .pentium2;
                } else if (mem.testEqualString("pentium3", arg)) {
                    cmd.cpu = .pentium3;
                } else if (mem.testEqualString("pentium3m", arg)) {
                    cmd.cpu = .pentium3m;
                } else if (mem.testEqualString("pentium4", arg)) {
                    cmd.cpu = .pentium4;
                } else if (mem.testEqualString("pentium_m", arg)) {
                    cmd.cpu = .pentium_m;
                } else if (mem.testEqualString("pentium_mmx", arg)) {
                    cmd.cpu = .pentium_mmx;
                } else if (mem.testEqualString("pentiumpro", arg)) {
                    cmd.cpu = .pentiumpro;
                } else if (mem.testEqualString("prescott", arg)) {
                    cmd.cpu = .prescott;
                } else if (mem.testEqualString("raptorlake", arg)) {
                    cmd.cpu = .raptorlake;
                } else if (mem.testEqualString("rocketlake", arg)) {
                    cmd.cpu = .rocketlake;
                } else if (mem.testEqualString("sandybridge", arg)) {
                    cmd.cpu = .sandybridge;
                } else if (mem.testEqualString("sapphirerapids", arg)) {
                    cmd.cpu = .sapphirerapids;
                } else if (mem.testEqualString("sierraforest", arg)) {
                    cmd.cpu = .sierraforest;
                } else if (mem.testEqualString("silvermont", arg)) {
                    cmd.cpu = .silvermont;
                } else if (mem.testEqualString("skx", arg)) {
                    cmd.cpu = .skx;
                } else if (mem.testEqualString("skylake", arg)) {
                    cmd.cpu = .skylake;
                } else if (mem.testEqualString("skylake_avx512", arg)) {
                    cmd.cpu = .skylake_avx512;
                } else if (mem.testEqualString("slm", arg)) {
                    cmd.cpu = .slm;
                } else if (mem.testEqualString("tigerlake", arg)) {
                    cmd.cpu = .tigerlake;
                } else if (mem.testEqualString("tremont", arg)) {
                    cmd.cpu = .tremont;
                } else if (mem.testEqualString("westmere", arg)) {
                    cmd.cpu = .westmere;
                } else if (mem.testEqualString("winchip2", arg)) {
                    cmd.cpu = .winchip2;
                } else if (mem.testEqualString("winchip_c6", arg)) {
                    cmd.cpu = .winchip_c6;
                } else if (mem.testEqualString("x86_64", arg)) {
                    cmd.cpu = .x86_64;
                } else if (mem.testEqualString("x86_64_v2", arg)) {
                    cmd.cpu = .x86_64_v2;
                } else if (mem.testEqualString("x86_64_v3", arg)) {
                    cmd.cpu = .x86_64_v3;
                } else if (mem.testEqualString("x86_64_v4", arg)) {
                    cmd.cpu = .x86_64_v4;
                } else if (mem.testEqualString("yonah", arg)) {
                    cmd.cpu = .yonah;
                } else if (mem.testEqualString("znver1", arg)) {
                    cmd.cpu = .znver1;
                } else if (mem.testEqualString("znver2", arg)) {
                    cmd.cpu = .znver2;
                } else if (mem.testEqualString("znver3", arg)) {
                    cmd.cpu = .znver3;
                } else if (mem.testEqualString("znver4", arg)) {
                    cmd.cpu = .znver4;
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
            } else if (mem.testEqualString("-fpanic-mismatched-arguments", arg)) {
                cmd.panic_mismatched_arguments = true;
            } else if (mem.testEqualString("-fno-panic-mismatched-arguments", arg)) {
                cmd.panic_mismatched_arguments = false;
            } else if (mem.testEqualString("-fpanic-reached-unreachable", arg)) {
                cmd.panic_reached_unreachable = true;
            } else if (mem.testEqualString("-fno-panic-reached-unreachable", arg)) {
                cmd.panic_reached_unreachable = false;
            } else if (mem.testEqualString("-fpanic-accessed-invalid-memory", arg)) {
                cmd.panic_accessed_invalid_memory = true;
            } else if (mem.testEqualString("-fno-panic-accessed-invalid-memory", arg)) {
                cmd.panic_accessed_invalid_memory = false;
            } else if (mem.testEqualString("-fpanic-mismatched-sentinel", arg)) {
                cmd.panic_mismatched_sentinel = true;
            } else if (mem.testEqualString("-fno-panic-mismatched-sentinel", arg)) {
                cmd.panic_mismatched_sentinel = false;
            } else if (mem.testEqualString("-fpanic-arith-lost-precision", arg)) {
                cmd.panic_arith_lost_precision = true;
            } else if (mem.testEqualString("-fno-panic-arith-lost-precision", arg)) {
                cmd.panic_arith_lost_precision = false;
            } else if (mem.testEqualString("-fpanic-arith-overflowed", arg)) {
                cmd.panic_arith_overflowed = true;
            } else if (mem.testEqualString("-fno-panic-arith-overflowed", arg)) {
                cmd.panic_arith_overflowed = false;
            } else if (mem.testEqualString("-fpanic-cast-from-invalid", arg)) {
                cmd.panic_cast_from_invalid = true;
            } else if (mem.testEqualString("-fno-panic-cast-from-invalid", arg)) {
                cmd.panic_cast_from_invalid = false;
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
                    cmd.passes = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
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
            } else if (mem.testEqualString("-fentry", arg)) {
                args_idx +%= 1;
                if (args_idx == args.len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
                cmd.entry = .{ .yes = arg };
            } else if (mem.testEqualString("-fno-entry", arg)) {
                cmd.entry = .no;
            } else if (mem.testEqualString("-flld", arg)) {
                cmd.lld = true;
            } else if (mem.testEqualString("-fno-lld", arg)) {
                cmd.lld = false;
            } else if (mem.testEqualString("-fllvm", arg)) {
                cmd.llvm = true;
            } else if (mem.testEqualString("-fno-llvm", arg)) {
                cmd.llvm = false;
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
                    cmd.stack = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
                } else {
                    return;
                }
            } else if (mem.testEqualString("--image-base", arg)) {
                args_idx +%= 1;
                if (args_idx != args.len) {
                    cmd.image_base = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
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
            ptr = fmt.strcpyEqu(ptr, "--format\x00");
            ptr = fmt.strcpyEqu(ptr, @tagName(format));
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.plugin) {
            ptr = fmt.strcpyEqu(ptr, "--plugin\x00");
        }
        if (cmd.output) |output| {
            ptr = fmt.strcpyEqu(ptr, "--output\x00");
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
        var len: usize = 4 +% zig_exe.len;
        if (cmd.format) |format| {
            len +%= 10 +% @tagName(format).len;
        }
        if (cmd.plugin) {
            len +%= 9;
        }
        if (cmd.output) |output| {
            len +%= 10 +% output.len;
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
        len +%= 1 +% @tagName(cmd.operation).len;
        for (files) |value| {
            len = len +% value.formatLength();
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
            ptr = fmt.strcpyEqu(ptr, "--output-target\x00");
            ptr = fmt.strcpyEqu(ptr, output_target);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.only_section) |only_section| {
            ptr = fmt.strcpyEqu(ptr, "--only-section\x00");
            ptr = fmt.strcpyEqu(ptr, only_section);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.pad_to) |pad_to| {
            ptr = fmt.strcpyEqu(ptr, "--pad-to\x00");
            ptr = fmt.Ud64.write(ptr, pad_to);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.strip_debug) {
            ptr = fmt.strcpyEqu(ptr, "--strip-debug\x00");
        }
        if (cmd.strip_all) {
            ptr = fmt.strcpyEqu(ptr, "--strip-all\x00");
        }
        if (cmd.debug_only) {
            ptr = fmt.strcpyEqu(ptr, "--only-keep-debug\x00");
        }
        if (cmd.add_gnu_debuglink) |add_gnu_debuglink| {
            ptr = fmt.strcpyEqu(ptr, "--add-gnu-debuglink\x00");
            ptr = fmt.strcpyEqu(ptr, add_gnu_debuglink);
            ptr[0] = 0;
            ptr += 1;
        }
        if (cmd.extract_to) |extract_to| {
            ptr = fmt.strcpyEqu(ptr, "--extract-to\x00");
            ptr = fmt.strcpyEqu(ptr, extract_to);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += path.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *ObjcopyCommand, zig_exe: []const u8, path: types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 9 +% zig_exe.len;
        if (cmd.output_target) |output_target| {
            len +%= 17 +% output_target.len;
        }
        if (cmd.only_section) |only_section| {
            len +%= 16 +% only_section.len;
        }
        if (cmd.pad_to) |pad_to| {
            len +%= 10 +% fmt.Ud64.length(pad_to);
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
            len +%= 21 +% add_gnu_debuglink.len;
        }
        if (cmd.extract_to) |extract_to| {
            len +%= 14 +% extract_to.len;
        }
        return len +% path.formatLength();
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
                    cmd.pad_to = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
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
            _ = &arg;
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
            ptr = fmt.strcpyEqu(ptr, "--ast-check\x00");
        }
        if (cmd.exclude) |exclude| {
            ptr = fmt.strcpyEqu(ptr, "--exclude\x00");
            ptr = fmt.strcpyEqu(ptr, exclude);
            ptr[0] = 0;
            ptr += 1;
        }
        ptr += pathname.formatWriteBuf(ptr);
        return @intFromPtr(ptr) -% @intFromPtr(buf);
    }
    pub fn formatLength(cmd: *FormatCommand, zig_exe: []const u8, pathname: types.Path) usize {
        @setRuntimeSafety(false);
        var len: usize = 5 +% zig_exe.len;
        if (cmd.color) |color| {
            len +%= 9 +% @tagName(color).len;
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
            len +%= 11 +% exclude.len;
        }
        return len +% pathname.formatLength();
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
    \\    -femit-bin=<string>                     (default=yes) Output machine code
    \\    -fno-emit-bin
    \\    -femit-asm=<string>                     (default=no) Output assembly code (.s)
    \\    -fno-emit-asm
    \\    -femit-llvm-ir=<string>                 (default=no) Output optimized LLVM IR (.ll)
    \\    -fno-emit-llvm-ir
    \\    -femit-llvm-bc=<string>                 (default=no) Output optimized LLVM BC (.bc)
    \\    -fno-emit-llvm-bc
    \\    -femit-h=<string>                       (default=no) Output a C header file (.h)
    \\    -fno-emit-h
    \\    -femit-docs=<string>                    (default=no) Output documentation (.html)
    \\    -fno-emit-docs
    \\    -femit-analysis=<string>                (default=no) Output analysis (.json)
    \\    -fno-emit-analysis
    \\    -femit-implib=<string>                  (default=yes) Output an import when building a Windows DLL (.lib)
    \\    -fno-emit-implib
    \\    --cache-dir=<string>                    Override the local cache directory
    \\    --global-cache-dir=<string>             Override the global cache directory
    \\    --zig-lib-dir=<string>                  Override Zig installation lib directory
    \\    --listen=<tag>                          [MISSING]
    \\    -target=<string>                        <arch><sub>-<os>-<abi> see the targets command
    \\    -mcpu=<tag>                             Specify target CPU and feature set
    \\    -mcmodel=<tag>                          Limit range of code and data virtual addresses
    \\    -m[no-]red-zone                         Enable the "red-zone"
    \\    -f[no-]builtin                          Enable implicit builtin knowledge of functions
    \\    -f[no-]panic-mismatched-arguments       Enables panic causes:
    \\                                              memcpy_argument_aliasing
    \\                                              memcpy_argument_lengths_mismatched
    \\                                              for_loop_capture_lengths_mismatched
    \\    -f[no-]panic-reached-unreachable        Enables panic causes:
    \\                                              message
    \\                                              discarded_error
    \\                                              corrupt_switch
    \\                                              returned_noreturn
    \\                                              reached_unreachable
    \\                                              accessed_null_value
    \\    -f[no-]panic-accessed-invalid-memory    Enables panic causes:
    \\                                              accessed_out_of_bounds
    \\                                              accessed_out_of_order
    \\                                              accessed_inactive_field
    \\    -f[no-]panic-mismatched-sentinel        Enables panic causes:
    \\                                              mismatched_sentinel
    \\                                              mismatched_non_scalar_sentinel
    \\    -f[no-]panic-arith-lost-precision       Enables panic causes:
    \\                                              div_with_remainder
    \\                                              shl_overflowed
    \\                                              shr_overflowed
    \\                                              shift_amt_overflowed
    \\    -f[no-]panic-arith-overflowed           Enables panic causes:
    \\                                              mul_overflowed
    \\                                              add_overflowed
    \\                                              sub_overflowed
    \\    -f[no-]panic-cast-from-invalid          Enables panic causes:
    \\                                              cast_to_int_from_invalid
    \\                                              cast_truncated_data
    \\                                              cast_to_unsigned_from_negative
    \\                                              cast_to_pointer_from_invalid
    \\                                              cast_to_enum_from_invalid
    \\                                              cast_to_error_from_invalid
    \\    -f[no-]omit-frame-pointer               Omit the stack frame pointer
    \\    -mexec-model=<string>                   (WASI) Execution model
    \\    --name=<string>                         Override root name
    \\    -fsoname=<string>                       Override the default SONAME value
    \\    -fno-soname
    \\    -O<tag>                                 Choose what to optimize for:
    \\                                              Debug          Optimizations off, safety on
    \\                                              ReleaseSafe    Optimizations on, safety on
    \\                                              ReleaseFast    Optimizations on, safety off
    \\                                              ReleaseSmall   Size optimizations on, safety off
    \\    -fopt-bisect-limit=<integer>            Only run [limit] first LLVM optimization passes
    \\    --main-mod-path=<string>                Set the directory of the root package
    \\    -f[no-]PIC                              Enable Position Independent Code
    \\    -f[no-]PIE                              Enable Position Independent Executable
    \\    -f[no-]lto                              Enable Link Time Optimization
    \\    -f[no-]stack-check                      Enable stack probing in unsafe builds
    \\    -f[no-]stack-protector                  Enable stack protection in unsafe builds
    \\    -f[no-]sanitize-c                       Enable C undefined behaviour detection in unsafe builds
    \\    -f[no-]valgrind                         Include valgrind client requests in release builds
    \\    -f[no-]sanitize-thread                  Enable thread sanitizer
    \\    -f[no-]unwind-tables                    Always produce unwind table entries for all functions
    \\    -f[no-]reference-trace                  How many lines of reference trace should be shown per compile error
    \\    -f[no-]error-tracing                    Enable error tracing in `ReleaseFast` mode
    \\    -f[no-]single-threaded                  Code assumes there is only one thread
    \\    -f[no-]function-sections                Places each function in a separate section
    \\    -f[no-]data-sections                    Places data in separate sections
    \\    -f[no-]strip                            Omit debug symbols
    \\    -f[no-]formatted-panics                 Enable formatted safety panics
    \\    -ofmt=<tag>                             Override target object format:
    \\                                              elf                    Executable and Linking Format
    \\                                              c                      C source code
    \\                                              wasm                   WebAssembly
    \\                                              coff                   Common Object File Format (Windows)
    \\                                              macho                  macOS relocatables
    \\                                              spirv                  Standard, Portable Intermediate Representation V (SPIR-V)
    \\                                              plan9                  Plan 9 from Bell Labs object format
    \\                                              hex (planned feature)  Intel IHEX
    \\                                              raw (planned feature)  Dump machine code directly
    \\    -idirafter=<string>                     Add directory to AFTER include search path
    \\    -isystem=<string>                       Add directory to SYSTEM include search path
    \\    --libc=<string>                         Provide a file which specifies libc paths
    \\    --library=<string>                      Link against system library (only if actually used)
    \\    -I<string>                              Add directories to include search path
    \\    --needed-library=<string>               Link against system library (even if unused)
    \\    --library-directory=<string>            Add a directory to the library search path
    \\    --script=<string>                       Use a custom linker script
    \\    --version-script=<string>               Provide a version .map file
    \\    --dynamic-linker=<string>               Set the dynamic interpreter path
    \\    --sysroot=<string>                      Set the system root directory
    \\    -fentry=<string>                        Override the default entry symbol name
    \\    -fno-entry
    \\    -f[no-]lld                              Use LLD as the linker
    \\    -f[no-]llvm                             Use LLVM as the codegen backend
    \\    -f[no-]compiler-rt                      (default) Include compiler-rt symbols in output
    \\    -rpath=<string>                         Add directory to the runtime library search path
    \\    -f[no-]each-lib-rpath                   Ensure adding rpath for each used dynamic library
    \\    -f[no-]allow-shlib-undefined            Allow undefined symbols in shared libraries
    \\    --build-id=<tag>                        Help coordinate stripped binaries with debug symbols
    \\    --eh-frame-hdr                          Enable C++ exception handling by passing --eh-frame-hdr to linker
    \\    --emit-relocs                           Enable output of relocation sections for post build tools
    \\    --[no-]gc-sections                      Force removal of functions and data that are unreachable by the entry point or exported symbols
    \\    --stack=<integer>                       Override default stack size
    \\    --image-base=<integer>                  Set base address for executable image
    \\    -D<string>                              Define C macros available within the `@cImport` namespace
    \\    --mod=<string>                          Define modules available as dependencies for the current target
    \\    --deps=<string>                         Define module dependencies for the current target
    \\    -cflags=<string>                        Set extra flags for the next position C source files
    \\    -rcflags=<string>                       Set extra flags for the next positional .rc source files
    \\    -lc                                     Link libc
    \\    -rdynamic                               Add all symbols to the dynamic symbol table
    \\    -dynamic                                Force output to be dynamically linked
    \\    -static                                 Force output to be statically linked
    \\    -Bsymbolic                              Bind global references locally
    \\    -z<string>                              Set linker extension flags:
    \\                                              nodelete                   Indicate that the object cannot be deleted from a process
    \\                                              notext                     Permit read-only relocations in read-only segments
    \\                                              defs                       Force a fatal error if any undefined symbols remain
    \\                                              undefs                     Reverse of -z defs
    \\                                              origin                     Indicate that the object must have its origin processed
    \\                                              nocopyreloc                Disable the creation of copy relocations
    \\                                              now (default)              Force all relocations to be processed on load
    \\                                              lazy                       Don't force all relocations to be processed on load
    \\                                              relro (default)            Force all relocations to be read-only after processing
    \\                                              norelro                    Don't force all relocations to be read-only after processing
    \\                                              common-page-size=[bytes]   Set the common page size for ELF binaries
    \\                                              max-page-size=[bytes]      Set the max page size for ELF binaries
    \\    --color=<tag>                           Enable or disable colored error messages
    \\    --debug-incremental                     Enable experimental feature: incremental compilation
    \\    -ftime-report                           Print timing diagnostics
    \\    -fstack-report                          Print stack size diagnostics
    \\    --verbose-link                          Display linker invocations
    \\    --verbose-cc                            Display C compiler invocations
    \\    --verbose-air                           Enable compiler debug output for Zig AIR
    \\    --verbose-mir                           Enable compiler debug output for Zig MIR
    \\    --verbose-llvm-ir                       Enable compiler debug output for LLVM IR
    \\    --verbose-cimport                       Enable compiler debug output for C imports
    \\    --verbose-llvm-cpu-features             Enable compiler debug output for LLVM CPU features
    \\    --debug-log=<string>                    Enable printing debug/info log messages for scope
    \\    --debug-compile-errors                  Crash with helpful diagnostics at the first compile error
    \\    --debug-link-snapshot                   Enable dumping of the linker's state in JSON
    \\
    \\
;
const archive_help: [:0]const u8 =
    \\    --format=<tag>          Archive format to create
    \\    --plugin                Ignored for compatibility
    \\    --output=<string>       Extraction target directory
    \\    --thin                  Create a thin archive
    \\    a                       Put [files] after [relpos]
    \\    b                       Put [files] before [relpos] (same as [i])
    \\    c                       Do not warn if archive had to be created
    \\    D                       Use zero for timestamps and uids/gids (default)
    \\    U                       Use actual timestamps and uids/gids
    \\    L                       Add archive's contents
    \\    o                       Preserve original dates
    \\    s                       Create an archive index (cf. ranlib)
    \\    S                       do not build a symbol table
    \\    u                       update only [files] newer than archive contents
    \\
    \\
;
const objcopy_help: [:0]const u8 =
    \\    --output-target=<string>
    \\    --only-section=<string>
    \\    --pad-to=<integer>
    \\    --strip-debug
    \\    --strip-all
    \\    --only-keep-debug
    \\    --add-gnu-debuglink=<string>
    \\    --extract-to=<string>
    \\
    \\
;
const format_help: [:0]const u8 =
    \\    --color=<tag>           Enable or disable colored error messages
    \\    --stdin                 Format code from stdin; output to stdout
    \\    --check                 List non-conforming files and exit with an error if the list is non-empty
    \\    --ast-check             Run zig ast-check on every file
    \\    --exclude=<string>      Exclude file or directory from formatting
    \\
    \\
;
pub const Command = struct {
    build: *BuildCommand,
    archive: *ArchiveCommand,
    objcopy: *ObjcopyCommand,
    format: *FormatCommand,
};
