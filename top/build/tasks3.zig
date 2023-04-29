const mem = @import("../mem.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");

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
pub const BuildCommand = struct {
    kind: OutputMode,
    /// Enable or disable colored error messages
    color: ?enum(u2) {
        on = 0,
        off = 1,
        auto = 2,
    } = null,
    /// (default=yes) Output machine code
    emit_bin: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output assembly code (.s)
    emit_asm: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output optimized LLVM IR (.ll)
    emit_llvm_ir: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output optimized LLVM BC (.bc)
    emit_llvm_bc: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output a C header file (.h)
    emit_h: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output documentation (.html)
    emit_docs: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=no) Output analysis (.json)
    emit_analysis: ?union(enum) {
        yes: types.Path,
        no,
    } = null,
    /// (default=yes) Output an import when building a Windows DLL (.lib)
    emit_implib: ?union(enum) {
        yes: types.Path,
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
    mode: ?builtin.Mode = null,
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
    fmt: ?enum(u4) {
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
    /// Add directory to include search path
    include: ?[]const u8 = null,
    /// Provide a file which specifies libc paths
    libc: ?[]const u8 = null,
    /// Link against system library (only if actually used)
    library: ?[]const u8 = null,
    /// Link against system library (even if unused)
    needed_library: ?[]const u8 = null,
    /// Add a directory to the library search path
    library_directory: ?[]const u8 = null,
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
    build_id: ?bool = null,
    /// Debug section compression:
    /// none   No compression
    /// zlib   Compression with deflate/inflate
    compress_debug_sections: ?enum(u1) {
        none = 0,
        zlib = 1,
    } = null,
    /// Force removal of functions and data that are unreachable
    /// by the entry point or exported symbols
    gc_sections: ?bool = null,
    /// Override default stack size
    stack: ?u64 = null,
    /// Set base address for executable image
    image_base: ?u64 = null,
    /// Define C macros available within the `@cImport` namespace
    macros: ?[]const types.Macro = null,
    /// Define modules available as dependencies for the current target
    modules: ?[]const types.Module = null,
    /// Define module dependencies for the current target
    dependencies: ?[]const types.ModuleDependency = null,
    /// Set extra flags for the next position C source files
    cflags: ?types.CFlags = null,
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
    z: ?enum(u4) {
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
    /// Add auxiliary files to the current target
    files: ?[]const types.Path = null,
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
};
