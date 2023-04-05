const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types2.zig");

pub const OutputMode = enum {
    exe,
    lib,
    obj,
};
pub const AuxOutputMode = enum {
    @"asm",
    llvm_ir,
    llvm_bc,
    h,
    docs,
    analysis,
    implib,
};
pub const RunCommand = struct {
    args: types.Args,
    pub fn addRunArgument(run_cmd: *RunCommand, allocator: *types.Allocator, any: anytype) void {
        run_cmd.args.appendAny(spec.reinterpret.fmt, allocator, any);
        run_cmd.args.appendOne(allocator, 0);
    }
};
pub const BuildCommand = struct {
    kind: OutputMode,
    watch: bool = false, // T1
    show_builtin: bool = false, // T1
    builtin: bool = false, // T1
    link_libc: bool = false, // T1
    rdynamic: bool = false, // T1
    dynamic: bool = false, // T1
    static: bool = false, // T1
    symbolic: bool = false, // T1
    /// Enable or disable colored error messages
    color: ?enum(u2) { on = 0, off = 1, auto = 2 } = null, // T6
    /// (default=yes) Output machine code
    emit_bin: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output assembly code (.s)
    emit_asm: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output optimized LLVM IR (.ll)
    emit_llvm_ir: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output optimized LLVM BC (.bc)
    emit_llvm_bc: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output a C header file (.h)
    emit_h: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output documentation (.html)
    emit_docs: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=no) Output analysis (.json)
    emit_analysis: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    /// (default=yes) Output an import when building a Windows DLL (.lib)
    emit_implib: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    cache_root: ?[]const u8 = null, // T7
    global_cache_root: ?[]const u8 = null, // T7
    zig_lib_dir: ?[]const u8 = null, // T7
    enable_cache: bool = true, // T0
    /// <arch><sub>-<os>-<abi> see the targets command
    target: ?[]const u8 = null, // T7
    /// Specify target CPU and feature set
    cpu: ?[]const u8 = null, // T7
    /// Limit range of code and data virtual addresses
    code_model: ?enum(u3) { default = 0, tiny = 1, small = 2, kernel = 3, medium = 4, large = 5 } = null, // T6
    /// Enable the "red-zone"
    red_zone: ?bool = null, // T7
    /// Omit the stack frame pointer
    omit_frame_pointer: ?bool = null, // T7
    /// (WASI) Execution model
    exec_model: ?[]const u8 = null, // T7
    /// Override root name
    name: ?[]const u8 = null, // T7
    /// Choose what to optimize for:
    /// Debug          Optimizations off, safety on
    /// ReleaseSafe    Optimizations on, safety on
    /// ReleaseFast    Optimizations on, safety off
    /// ReleaseSmall   Size optimizations on, safety off
    mode: ?@TypeOf(builtin.zig.mode) = null, // T2
    /// Set the directory of the root package
    main_pkg_path: ?[]const u8 = null, // T7
    /// Enable Position Independent Code
    pic: ?bool = null, // T7
    /// Enable Position Independent Executable
    pie: ?bool = null, // T7
    /// Enable Link Time Optimization
    lto: ?bool = null, // T7
    /// Enable stack probing in unsafe builds
    stack_check: ?bool = null, // T7
    /// Enable stack protection in unsafe builds
    stack_protector: ?bool = null, // T7
    /// Enable C undefined behaviour detection in unsafe builds
    sanitize_c: ?bool = null, // T7
    /// Include valgrind client requests in release builds
    valgrind: ?bool = null, // T7
    /// Enable thread sanitizer
    sanitize_thread: ?bool = null, // T7
    /// Always produce unwind table entries for all functions
    unwind_tables: ?bool = null, // T7
    /// Use LLVM as the codegen backend
    llvm: ?bool = null, // T7
    /// Use Clang as the C/C++ compilation backend
    clang: ?bool = null, // T7
    /// How many lines of reference trace should be shown per compile error
    reference_trace: ?bool = null, // T7
    /// Enable error tracing in `ReleaseFast` mode
    error_tracing: ?bool = null, // T7
    /// Code assumes there is only one thread
    single_threaded: ?bool = null, // T7
    /// Places each function in a separate sections
    function_sections: ?bool = null, // T7
    /// Omit debug symbols
    strip: ?bool = null, // T7
    /// Enable formatted safety panics
    formatted_panics: ?bool = null, // T7
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
    fmt: ?enum(u4) { elf = 0, c = 1, wasm = 2, coff = 3, macho = 4, spirv = 5, plan9 = 6, hex = 7, raw = 8 } = null, // T6
    /// Add directory to AFTER include search path
    dirafter: ?[]const u8 = null, // T7
    /// Add directory to SYSTEM include search path
    system: ?[]const u8 = null, // T7
    /// Add directory to include search path
    include: ?[]const u8 = null, // T7
    /// Provide a file which specifies libc paths
    libc: ?[]const u8 = null, // T7
    /// Link against system library (only if actually used)
    library: ?[]const u8 = null, // T7
    /// Link against system library (even if unused)
    needed_library: ?[]const u8 = null, // T7
    /// Add a directory to the library search path
    library_directory: ?[]const u8 = null, // T7
    /// Use a custom linker script
    link_script: ?[]const u8 = null, // T7
    /// Provide a version .map file
    version_script: ?[]const u8 = null, // T7
    /// Set the dynamic interpreter path
    dynamic_linker: ?[]const u8 = null, // T7
    /// Set the system root directory
    sysroot: ?[]const u8 = null, // T7
    version: bool = false, // T1
    /// Set the entrypoint symbol name
    entry: ?[]const u8 = null, // T7
    /// Override the default SONAME value
    soname: ?union(enum) { yes: []const u8, no: void } = null, // T6
    /// Use LLD as the linker
    lld: ?bool = null, // T7
    /// (default) Include compiler-rt symbols in output
    compiler_rt: ?bool = null, // T7
    /// Add directory to the runtime library search path
    rpath: ?[]const u8 = null, // T7
    /// Ensure adding rpath for each used dynamic library
    each_lib_rpath: ?bool = null, // T7
    /// Allow undefined symbols in shared libraries
    allow_shlib_undefined: ?bool = null, // T7
    /// Help coordinate stripped binaries with debug symbols
    build_id: ?bool = null, // T7
    /// Debug section compression:
    /// none   No compression
    /// zlib   Compression with deflate/inflate
    compress_debug_sections: ?enum(u1) { none = 0, zlib = 1 } = null, // T6
    /// Force removal of functions and data that are unreachable
    /// by the entry point or exported symbols
    gc_sections: ?bool = null, // T7
    /// Override default stack size
    stack: ?u64 = null, // T7
    /// Set base address for executable image
    image_base: ?u64 = null, // T7
    /// Define C macros available within the `@cImport` namespace
    macros: ?[]const types.Macro = null, // T2
    /// Define modules available as dependencies for the current target
    modules: ?[]const types.Module = null, // T2
    /// Define module dependencies for the current target
    dependencies: ?[]const types.ModuleDependency = null, // T2
    /// Set extra flags for the next position C source files
    cflags: ?types.CFlags = null, // T3
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
    z: ?enum(u4) { nodelete = 0, notext = 1, defs = 2, origin = 3, nocopyreloc = 4, now = 5, lazy = 6, relro = 7, norelro = 8 } = null, // T6
    /// Add auxiliary files to the current target
    files: ?[]const types.Path = null, // T2
};
pub const FormatCommand = struct {
    /// Enable or disable colored error messages
    color: ?enum(u2) { auto = 0, off = 1, on = 2 } = null, // T6
    /// Format code from stdin; output to stdout
    stdin: bool = false, // T1
    /// List non-conforming files and exit with an error if the list is non-empty
    check: bool = false, // T1
    /// Run zig ast-check on every file
    ast_check: bool = true, // T0
    /// Exclude file or directory from formatting
    exclude: ?[]const u8 = null, // T7
};
