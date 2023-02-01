const mem = @import("./mem.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const mach = @import("./mach.zig");
const file = @import("./file.zig");
const meta = @import("./meta.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const types = @import("./builder-template.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = false;
pub const is_correct: bool = false;

const Variant = enum(u1) { length, write };

const use_function_type: bool = false;
const initial_indent: u64 = if (use_function_type) 2 else 1;
const alloc_options = .{
    .count_allocations = false,
    .require_filo_free = false,
    .require_geometric_growth = true,
    .trace_state = false,
};
const alloc_logging = .{
    .arena = builtin.Logging.silent,
    .map = builtin.Logging.silent,
    .unmap = builtin.Logging.silent,
    .remap = builtin.Logging.silent,
};
const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 24,
    .options = alloc_options,
    .logging = alloc_logging,
});
const Allocator1 = mem.GenericArenaAllocator(.{
    .arena_index = 32,
    .options = alloc_options,
    .logging = alloc_logging,
});
const String = Allocator.StructuredHolder(u8);
const String1 = Allocator1.StructuredHolder(u8);
const create_spec: file.CreateSpec = .{
    .options = .{
        .write = .truncate,
        .read = false,
        .exclusive = false,
    },
    .logging = .{},
};
const close_spec: file.CloseSpec = .{
    .logging = .{},
    .errors = null,
};
const ws: [28]u8 = .{' '} ** 28;
pub const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = .append },
};
pub const OptionSpec = struct {
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_type: ?type = null,
    /// Any argument type name; must be defined in builder-template.zig
    arg_type_name: ?[]const u8 = null,
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?*const OptionSpec = null,
};
const SimpleInverse = struct {
    /// Do not output machine code
    pub const no_emit_bin_opt_spec: OptionSpec = .{ .string = "-fno-emit-bin" };
    /// (default) Do not output .s (assembly code)
    pub const no_emit_asm_opt_spec: OptionSpec = .{ .string = "-fno-emit-asm" };
    /// (default) Do not produce a .ll file with LLVM IR
    pub const no_emit_llvm_ir_opt_spec: OptionSpec = .{ .string = "-fno-emit-llvm-ir" };
    /// (default) Do not produce a LLVM module as a .bc file
    pub const no_emit_llvm_bc_opt_spec: OptionSpec = .{ .string = "-fno-emit-llvm-bc" };
    /// (default) Do not generate a C header file (.h)
    pub const no_emit_h_opt_spec: OptionSpec = .{ .string = "-fno-emit-h" };
    /// (default) Do not produce docs/ dir with html documentation
    pub const no_emit_docs_opt_spec: OptionSpec = .{ .string = "-fno-emit-docs" };
    /// (default) Do not write analysis JSON file with type information
    pub const no_emit_analysis_opt_spec: OptionSpec = .{ .string = "-fno-emit-analysis" };
    /// Do not produce an import .lib when building a Windows DLL
    pub const no_emit_implib_opt_spec: OptionSpec = .{ .string = "-fno-emit-implib" };
    /// -mno-red-zone               Force-disable the "red-zone"
    pub const no_red_zone_opt_spec: OptionSpec = .{ .string = "-mno-red-zone" };
    /// -fno-omit-frame-pointer     Store the stack frame pointer
    pub const no_omit_frame_pointer_opt_spec: OptionSpec = .{ .string = "-fno-omit-frame-pointer" };
    /// -fno-PIC                    Force-disable Position Independent Code
    pub const no_pic_opt_spec: OptionSpec = .{ .string = "-fno-PIC" };
    /// -fno-PIE                    Force-disable Position Independent Executable
    pub const no_pie_opt_spec: OptionSpec = .{ .string = "-fno-PIE" };
    /// -fno-lto                    Force-disable Link Time Optimization
    pub const no_lto_opt_spec: OptionSpec = .{ .string = "-fno-lto" };
    /// -fno-stack-check            Disable stack probing in safe builds
    pub const no_stack_check_opt_spec: OptionSpec = .{ .string = "-fno-stack-check" };
    /// -fno-sanitize-c             Disable C undefined behavior detection in safe builds
    pub const no_sanitize_c_opt_spec: OptionSpec = .{ .string = "-fno-sanitize-c" };
    /// -fno-valgrind               Omit valgrind client requests in debug builds
    pub const no_valgrind_opt_spec: OptionSpec = .{ .string = "-fno-valgrind" };
    /// -fno-sanitize-thread        Disable Thread Sanitizer
    pub const no_sanitize_thread_opt_spec: OptionSpec = .{ .string = "-fno-sanitize-thread" };
    /// -fno-dll-export-fns         Force-disable marking exported functions as DLL exports
    pub const no_dll_export_fns_opt_spec: OptionSpec = .{ .string = "-fno-dll-export-fns" };
    /// -fno-unwind-tables          Never produce unwind table entries
    pub const no_unwind_tables_opt_spec: OptionSpec = .{ .string = "-fno-unwind-tables" };
    /// -fno-LLVM                   Prevent using LLVM as the codegen backend
    pub const no_llvm_opt_spec: OptionSpec = .{ .string = "-fno-LLVM" };
    /// -fno-Clang                  Prevent using Clang as the C/C++ compilation backend
    pub const no_clang_opt_spec: OptionSpec = .{ .string = "-fno-Clang" };
    /// -fno-stage1                 Prevent using bootstrap compiler as the codegen backend
    pub const no_stage1_opt_spec: OptionSpec = .{ .string = "-fno-stage1" };
    /// -fno-single-threaded        Code may not assume there is only one thread
    pub const no_single_threaded_opt_spec: OptionSpec = .{ .string = "-fno-single-threaded" };
    /// -fno-builtin                Disable implicit builtin knowledge of functions
    pub const no_builtin_opt_spec: OptionSpec = .{ .string = "-fno-builtin" };
    /// -fno-function-sections      All functions go into same section
    pub const no_function_sections_opt_spec: OptionSpec = .{ .string = "-fno-function-sections" };
    /// --no-gc-sections            Don't force removal of unreachable functions and data
    pub const no_gc_sections_opt_spec: OptionSpec = .{ .string = "--no-gc-sections" };
    /// -fno-strip                   Do no omit debug symbols
    pub const no_strip_opt_spec: OptionSpec = .{ .string = "-fno-strip" };
    ///   -fno-soname                    Disable emitting a SONAME
    pub const no_soname_opt_spec: OptionSpec = .{ .string = "-fno-soname" };
    ///   -fno-compiler-rt               Prevent including compiler-rt symbols in output
    pub const no_compiler_rt_opt_spec: OptionSpec = .{ .string = "-fno-compiler-rt" };
};
pub const ExecutableOptions = opaque {
    // Enable compiler REPL
    pub const watch_opt_spec: OptionSpec = .{ .string = "--watch" };
    // Enable or disable colored error messages
    pub const color_opt_spec: OptionSpec = .{ .string = "--color", .arg_type = enum { on, off, auto } };
    // (default) Output machine code
    pub const emit_bin_opt_spec: OptionSpec = .{
        .string = "-femit-bin",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_bin_opt_spec,
    };
    // Output .s (assembly code)
    pub const emit_asm_opt_spec: OptionSpec = .{
        .string = "-femit-asm",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_asm_opt_spec,
    };
    // Produce a .ll file with LLVM IR (requires LLVM extensions)
    pub const emit_llvm_ir_opt_spec: OptionSpec = .{
        .string = "-femit-llvm-ir",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_llvm_ir_opt_spec,
    };
    // Produce a LLVM module as a .bc file (requires LLVM extensions)
    pub const emit_llvm_bc_opt_spec: OptionSpec = .{
        .string = "-femit-llvm-bc",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_llvm_bc_opt_spec,
    };
    // Generate a C header file (.h)
    pub const emit_h_opt_spec: OptionSpec = .{
        .string = "-femit-h",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_h_opt_spec,
    };
    // Create a docs/ dir with html documentation
    pub const emit_docs_opt_spec: OptionSpec = .{
        .string = "-femit-docs",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_docs_opt_spec,
    };
    // Write analysis JSON file with type information
    pub const emit_analysis_opt_spec: OptionSpec = .{
        .string = "-femit-analysis",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_analysis_opt_spec,
    };
    // (default) Produce an import .lib when building a Windows DLL
    pub const emit_implib_opt_spec: OptionSpec = .{
        .string = "-femit-implib",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &SimpleInverse.no_emit_implib_opt_spec,
    };
    // Output the source of @import(pub const builtin_opt_spec: OptionSpec = .{ .string = "builtin" } ) then exit
    pub const show_builtin_opt_spec: OptionSpec = .{ .string = "--show-builtin" };
    // Override the local cache directory
    pub const cache_dir_opt_spec: OptionSpec = .{ .string = "--cache-dir", .arg_type = []const u8 };
    // Override the global cache directory
    pub const global_cache_dir_opt_spec: OptionSpec = .{ .string = "--global-cache-dir", .arg_type = []const u8 };
    // Override path to Zig installation lib directory
    pub const zig_lib_dir_opt_spec: OptionSpec = .{ .string = "--zig-lib-dir", .arg_type = []const u8 };
    // Output to cache directory; print path to stdout
    pub const enable_cache_opt_spec: OptionSpec = .{ .string = "--enable-cache" };
    // Compile Options:
    ///  -target [name]            <arch><sub>-<os>-<abi> see the targets command
    pub const target_opt_spec: OptionSpec = .{ .string = "-target", .arg_type = []const u8 };
    /// -mcpu [cpu]               Specify target CPU and feature set
    pub const cpu_opt_spec: OptionSpec = .{ .string = "-mcpu", .arg_type = []const u8 };
    ///  -mcmodel=[default|tiny|   Limit range of code and data virtual addresses
    ///            small|kernel|
    ///            medium|large]
    pub const cmodel_opt_spec: OptionSpec = .{ .string = "-mcmodel", .arg_type = enum { default, tiny, small, kernel, medium, large } };
    /// -mred-zone                Force-enable the "red-zone"
    pub const red_zone_opt_spec: OptionSpec = .{ .string = "-mred-zone", .and_no = &SimpleInverse.no_red_zone_opt_spec };
    /// -fomit-frame-pointer      Omit the stack frame pointer
    pub const omit_frame_pointer_opt_spec: OptionSpec = .{ .string = "-fomit-frame-pointer", .and_no = &SimpleInverse.no_omit_frame_pointer_opt_spec };
    /// -mexec-model=[value]      (WASI) Execution model
    pub const exec_model_opt_spec: OptionSpec = .{ .string = "-mexec-model", .arg_type = []const u8 };
    /// --name [name]             Override root name (not a file path)
    pub const name_opt_spec: OptionSpec = .{ .string = "--name", .arg_type = []const u8 };
    /// -O [mode]                 Choose what to optimize for
    ///    Debug                   (default) Optimizations off, safety on
    ///    ReleaseFast             Optimizations on, safety off
    ///    ReleaseSafe             Optimizations on, safety on
    ///    ReleaseSmall            Optimize for small binary, safety off
    //pub const O_opt_spec: OptionSpec = .{ .string = "-O", .arg_type = enum { Debug, ReleaseSafe, ReleaseSmall, ReleaseFast } };
    pub const O_opt_spec: OptionSpec = .{ .string = "-O", .arg_type = @TypeOf(builtin.zig.mode), .arg_type_name = "@TypeOf(builtin.zig.mode)" };
    // pub const pkg_end_opt_spec: OptionSpec = .{ .string = "--pkg-end" };
    /// --main-pkg-path           Set the directory of the root package
    pub const main_pkg_path_opt_spec: OptionSpec = .{ .string = "--main-pkg-path", .arg_type = []const u8 };
    /// -fPIC                     Force-enable Position Independent Code
    pub const pic_opt_spec: OptionSpec = .{ .string = "-fPIC", .and_no = &SimpleInverse.no_pic_opt_spec };
    /// -fPIE                     Force-enable Position Independent Executable
    pub const pie_opt_spec: OptionSpec = .{ .string = "-fPIE", .and_no = &SimpleInverse.no_pie_opt_spec };
    /// -flto                     Force-enable Link Time Optimization (requires LLVM extensions)
    pub const lto_opt_spec: OptionSpec = .{ .string = "-flto", .and_no = &SimpleInverse.no_lto_opt_spec };
    /// -fstack-check             Enable stack probing in unsafe builds
    pub const stack_check_opt_spec: OptionSpec = .{ .string = "-fstack-check", .and_no = &SimpleInverse.no_stack_check_opt_spec };
    /// -fsanitize-c              Enable C undefined behavior detection in unsafe builds
    pub const sanitize_c_opt_spec: OptionSpec = .{ .string = "-fsanitize-c", .and_no = &SimpleInverse.no_sanitize_c_opt_spec };
    /// -fvalgrind                Include valgrind client requests in release builds
    pub const valgrind_opt_spec: OptionSpec = .{ .string = "-fvalgrind", .and_no = &SimpleInverse.no_valgrind_opt_spec };
    /// -fsanitize-thread         Enable Thread Sanitizer
    pub const sanitize_thread_opt_spec: OptionSpec = .{ .string = "-fsanitize-thread", .and_no = &SimpleInverse.no_sanitize_thread_opt_spec };
    /// -fdll-export-fns          Mark exported functions as DLL exports (Windows)
    pub const dll_export_fns_opt_spec: OptionSpec = .{ .string = "-fdll-export-fns", .and_no = &SimpleInverse.no_dll_export_fns_opt_spec };
    /// -funwind-tables           Always produce unwind table entries for all functions
    pub const unwind_tables_opt_spec: OptionSpec = .{ .string = "-funwind-tables", .and_no = &SimpleInverse.no_unwind_tables_opt_spec };
    /// -fLLVM                    Force using LLVM as the codegen backend
    pub const llvm_opt_spec: OptionSpec = .{ .string = "-fLLVM", .and_no = &SimpleInverse.no_llvm_opt_spec };
    /// -fClang                   Force using Clang as the C/C++ compilation backend
    pub const clang_opt_spec: OptionSpec = .{ .string = "-fClang", .and_no = &SimpleInverse.no_clang_opt_spec };
    /// -fstage1                  Force using bootstrap compiler as the codegen backend
    pub const stage1_opt_spec: OptionSpec = .{ .string = "-fstage1", .and_no = &SimpleInverse.no_stage1_opt_spec };
    /// -fsingle-threaded         Code assumes there is only one thread
    pub const single_threaded_opt_spec: OptionSpec = .{ .string = "-fsingle-threaded", .and_no = &SimpleInverse.no_single_threaded_opt_spec };
    /// -fbuiltin                 Enable implicit builtin knowledge of functions
    pub const builtin_opt_spec: OptionSpec = .{ .string = "-fbuiltin" };
    /// -ffunction-sections       Places each function in a separate section
    pub const function_sections_opt_spec: OptionSpec = .{ .string = "-ffunction-sections", .and_no = &SimpleInverse.no_function_sections_opt_spec };
    /// -fstrip                   Omit debug symbols
    pub const strip_opt_spec: OptionSpec = .{ .string = "-fstrip", .and_no = &SimpleInverse.no_strip_opt_spec };
    /// -ofmt=[mode]              Override target object format
    ///   elf                     Executable and Linking Format
    ///   c                       C source code
    ///   wasm                    WebAssembly
    ///   coff                    Common Object File Format (Windows)
    ///   macho                   macOS relocatables
    ///   spirv                   Standard, Portable Intermediate Representation V (SPIR-V)
    ///   plan9                   Plan 9 from Bell Labs object format
    ///   hex  (planned feature)  Intel IHEX
    ///   raw  (planned feature)  Dump machine code directly
    pub const fmt_opt_spec: OptionSpec = .{ .string = "-ofmt", .arg_type = enum { elf, c, wasm, coff, macho, spirv, plan9, hex, raw } };
    /// -dirafter [dir]           Add directory to AFTER include search path
    pub const dirafter_opt_spec: OptionSpec = .{ .string = "-dirafter", .arg_type = []const u8 };
    /// -isystem  [dir]           Add directory to SYSTEM include search path
    pub const system_opt_spec: OptionSpec = .{ .string = "-isystem", .arg_type = []const u8 };
    /// -I[dir]                   Add directory to include search path
    pub const include_opt_spec: OptionSpec = .{ .string = "-I", .arg_type = []const u8 };
    /// -D[macro]=[value]         Define C [macro] to [value] (1 if [value] omitted)
    pub const macros_opt_spec: OptionSpec = .{ .arg_type = types.Macros, .arg_type_name = "Macros" };
    /// --pkg-begin [name] [path] Make pkg available to import and push current pkg
    pub const packages_opt_spec: OptionSpec = .{ .arg_type = types.Packages, .arg_type_name = "Packages" };
    // --pkg-end                 Pop current pkg
    /// --libc [file]             Provide a file which specifies libc paths
    /// -cflags [flags] --        Set extra flags for the next positional C source files
    /// Link Options:
    ///   -l[lib], --library [lib]       Link against system library (only if actually used)
    ///   -needed-l[lib],                Link against system library (even if unused)
    ///     --needed-library [lib]
    ///   -L[d], --library-directory [d] Add a directory to the library search path
    ///   -T[script], --script [script]  Use a custom linker script
    ///   --version-script [path]        Provide a version .map file
    ///   --dynamic-linker [path]        Set the dynamic interpreter path (usually ld.so)
    ///   --sysroot [path]               Set the system root directory (usually /)
    ///   --version [ver]                Dynamic library semver
    ///   --entry [name]                 Set the entrypoint symbol name
    ///   -fsoname[=name]                Override the default SONAME value
    pub const soname_opt_spec: OptionSpec = .{ .string = "-fsoname", .arg_type = []const u8, .and_no = &SimpleInverse.no_soname_opt_spec };
    ///   -fLLD                          Force using LLD as the linker
    ///   -fno-LLD                       Prevent using LLD as the linker
    ///   -fcompiler-rt                  Always include compiler-rt symbols in output
    pub const compiler_rt_opt_spec: OptionSpec = .{ .string = "-fcompiler-rt", .and_no = &SimpleInverse.no_compiler_rt_opt_spec };
    ///   -rdynamic                      Add all symbols to the dynamic symbol table
    ///   -rpath [path]                  Add directory to the runtime library search path
    pub const path_opt_spec: OptionSpec = .{ .string = "-rpath", .arg_type = []const u8 };
    ///   -feach-lib-rpath               Ensure adding rpath for each used dynamic library
    pub const each_lib_rpath_opt_spec: OptionSpec = .{ .string = "-feach-lib-rpath", .and_no = &no_each_lib_rpath_opt_spec };
    ///   -fno-each-lib-rpath            Prevent adding rpath for each used dynamic library
    pub const no_each_lib_rpath_opt_spec: OptionSpec = .{ .string = "-fno-each-lib-rpath" };
    ///   -fallow-shlib-undefined        Allows undefined symbols in shared libraries
    pub const allow_shlib_undefined_opt_spec: OptionSpec = .{ .string = "-fallow-shlib-undefined", .and_no = &no_allow_shlib_undefined_opt_spec };
    ///   -fno-allow-shlib-undefined     Disallows undefined symbols in shared libraries
    pub const no_allow_shlib_undefined_opt_spec: OptionSpec = .{ .string = "-fno-allow-shlib-undefined" };
    ///   -fbuild-id                     Helps coordinate stripped binaries with debug symbols
    pub const build_id_opt_spec: OptionSpec = .{ .string = "-fbuild-id", .and_no = &no_build_id_opt_spec };
    ///   -fno-build-id                  (default) Saves a bit of time linking
    pub const no_build_id_opt_spec: OptionSpec = .{ .string = "-fno-build-id" };
    ///   --eh-frame-hdr                 Enable C++ exception handling by passing --eh-frame-hdr to linker
    ///   --emit-relocs                  Enable output of relocation sections for post build tools
    /// -dynamic                       Force output to be dynamically linked
    pub const dynamic_opt_spec: OptionSpec = .{ .string = "-dynamic" };
    /// -static                        Force output to be statically linked
    pub const static_opt_spec: OptionSpec = .{ .string = "-static" };
    ///   -Bsymbolic                     Bind global references locally
    ///   --compress-debug-sections=[e]  Debug section compression settings
    ///       none                       No compression
    ///       zlib                       Compression with deflate/inflate
    ///   --gc-sections                  Force removal of functions and data that are unreachable by the entry point or exported symbols
    pub const gc_sections_opt_spec: OptionSpec = .{ .string = "--gc-sections", .and_no = &SimpleInverse.no_gc_sections_opt_spec };
    ///   --subsystem [subsystem]        (Windows) /SUBSYSTEM:<subsystem> to the linker
    ///   --stack [size]                 Override default stack size
    pub const stack_opt_spec: OptionSpec = .{ .string = "--stack", .arg_type = u64 };
    ///   --image-base [addr]            Set base address for executable image
    ///   -weak-l[lib]                   (Darwin) link against system library and mark it and all referenced symbols as weak
    ///     -weak_library [lib]
    ///   -framework [name]              (Darwin) link against framework
    ///   -needed_framework [name]       (Darwin) link against framework (even if unused)
    ///   -needed_library [lib]          (Darwin) link against system library (even if unused)
    ///   -weak_framework [name]         (Darwin) link against framework and mark it and all referenced symbols as weak
    ///   -F[dir]                        (Darwin) add search path for frameworks
    ///   -install_name=[value]          (Darwin) add dylib's install name
    ///   --entitlements [path]          (Darwin) add path to entitlements file for embedding in code signature
    ///   -pagezero_size [value]         (Darwin) size of the __PAGEZERO segment in hexadecimal notation
    ///   -search_paths_first            (Darwin) search each dir in library search paths for `libx.dylib` then `libx.a`
    ///   -search_dylibs_first           (Darwin) search `libx.dylib` in each dir in library search paths, then `libx.a`
    ///   -headerpad [value]             (Darwin) set minimum space for future expansion of the load commands in hexadecimal notation
    ///   -headerpad_max_install_names   (Darwin) set enough space as if all paths were MAXPATHLEN
    ///   -dead_strip                    (Darwin) remove functions and data that are unreachable by the entry point or exported symbols
    ///   -dead_strip_dylibs             (Darwin) remove dylibs that are unreachable by the entry point or exported symbols
    ///   --import-memory                (WebAssembly) import memory from the environment
    ///   --import-table                 (WebAssembly) import function table from the host environment
    ///   --export-table                 (WebAssembly) export function table to the host environment
    ///   --initial-memory=[bytes]       (WebAssembly) initial size of the linear memory
    ///   --max-memory=[bytes]           (WebAssembly) maximum size of the linear memory
    ///   --shared-memory                (WebAssembly) use shared linear memory
    ///   --global-base=[addr]           (WebAssembly) where to start to place global data
    ///   --export=[value]               (WebAssembly) Force a symbol to be exported
    ///
    /// Test Options:
    ///   --test-filter [text]           Skip tests that do not match filter
    ///   --test-name-prefix [text]      Add prefix to all tests
    ///   --test-cmd [arg]               Specify test execution command one arg at a time
    ///   --test-cmd-bin                 Appends test binary path to test cmd args
    ///   --test-evented-io              Runs the test in evented I/O mode
    ///   --test-no-exec                 Compiles test binary without running it
    ///
    /// Debug Options (Zig Compiler Development):
    ///   -ftime-report                Print timing diagnostics
    ///   -fstack-report               Print stack size diagnostics
    ///   --verbose-link               Display linker invocations
    ///   --verbose-cc                 Display C compiler invocations
    ///   --verbose-air                Enable compiler debug output for Zig AIR
    ///   --verbose-mir                Enable compiler debug output for Zig MIR
    ///   --verbose-llvm-ir            Enable compiler debug output for LLVM IR
    ///   --verbose-cimport            Enable compiler debug output for C imports
    ///   --verbose-llvm-cpu-features  Enable compiler debug output for LLVM CPU features
    ///   --debug-log [scope]          Enable printing debug/info log messages for scope
    ///   --debug-compile-errors       Crash with helpful diagnostics at the first compile error
    ///   --debug-link-snapshot        Enable dumping of the linker's state in JSON
    ///   -z [arg]                       Set linker extension flags
    ///     nodelete                     Indicate that the object cannot be deleted from a process
    ///     notext                       Permit read-only relocations in read-only segments
    ///     defs                         Force a fatal error if any undefined symbols remain
    ///     origin                       Indicate that the object must have its origin processed
    ///     nocopyreloc                  Disable the creation of copy relocations
    ///     now                          (default) Force all relocations to be processed on load
    ///     lazy                         Don't force all relocations to be processed on load
    ///     relro                        (default) Force all relocations to be read-only after processing
    ///     norelro                      Don't force all relocations to be read-only after processing
    pub const z_opt_spec: OptionSpec = .{ .string = "-z", .arg_type = enum { nodelete, notext, defs, origin, nocopyreloc, now, lazy, relro, norelro } };
};
/// These are the various states of definition of options. The 'how not' and
/// 'maybe how not' do not have any examples, but it is easier to think about if
/// symmetrical.
const Kind = enum {
    /// Simple boolean switches.
    what,
    /// Switch requires an argument.
    what_how,
    /// Switch requests some behaviour, and lets the compiler decide how if no
    /// argument follows.
    what_maybe_how,
    /// The inverse behaviour is also explicit.
    what_and_not,
    what_and_how_not,
    what_and_maybe_how_not,
    what_how_and_not,
    what_how_and_how_not,
    what_how_and_maybe_how_not,
    what_maybe_how_and_not,
    what_maybe_how_and_how_not,
    what_maybe_how_and_maybe_how_not,
};
pub fn inaccurateGuessWarning(comptime string: []const u8, guess: u64, actual: u64, delta: u64) !void {
    const max_len: u64 = 16 + 19 + 41 + string.len + 3 + 19 + 13 + 19 + 2;
    var msg: [max_len]u8 = undefined;
    var len: u64 = 0;
    inline for (.{
        "guess-warn:     ",                          builtin.fmt.ud64(guess).readAll(),
        ", better guess for starting position of '", string,
        "': ",                                       builtin.fmt.ud64(actual).readAll(),
        " (abs.diff = ",                             builtin.fmt.ud64(delta).readAll(),
        ")\n",
    }) |s| {
        for (s) |c, i| msg[len + i] = c;
        len += s.len;
    }
    sys.noexcept.write(2, @ptrToInt(&msg), len);
}
pub fn nullGuessWarning(comptime string: []const u8) !void {
    const msg: []const u8 = "source does not contain string '" ++ string ++ "'\n";
    sys.noexcept.write(2, @ptrToInt(msg.ptr), msg.len);
}
pub fn guessSourceOffset(src: []const u8, comptime string: []const u8, guess: u64) !u64 {
    if (guess > src.len) {
        return guessSourceOffset(src, string, src.len / 2);
    }
    if (mem.propagateSearch(u8, string, src, guess)) |actual| {
        const diff: u64 = builtin.diff(u64, actual, guess);
        if (diff != 0) {
            try inaccurateGuessWarning(string, guess, actual, diff);
        }
        try builtin.expectEqual([]const u8, string, src[actual .. actual + string.len]);
        return actual;
    }
    try nullGuessWarning(string);
    return error.SourceDoesNotContainString;
}
pub fn guessSourceOffsetStatic(comptime src: []const u8, comptime string: []const u8, comptime guess: u64) u64 {
    @setEvalBranchQuota(~@as(u32, 0));
    comptime {
        if (mem.propagateSearch(string, src, guess)) |actual| {
            const delta = @max(actual, guess) - @min(actual, guess);
            if (delta != 0) {
                const g_dec = builtin.fmt.ud(guess);
                const a_dec = builtin.fmt.ud(actual);
                const d_dec = builtin.fmt.ud(delta);
                @compileError("inaccurate guess: " ++ g_dec.auto[g_dec.ub_word..] ++
                    ", better guess for starting position of '" ++ string ++ "': " ++ a_dec.auto[a_dec.ub_word..] ++
                    " (abs.diff = " ++ d_dec.auto[d_dec.ub_word..] ++ ")");
            }
            return actual;
        }
        @compileError("source does not contain string '" ++ string ++ "'");
    }
}
fn subTemplate(src: [:0]const u8, comptime sub_name: [:0]const u8) ?[]const u8 {
    const start_s: []const u8 = "// start-document " ++ sub_name;
    const finish_s: []const u8 = "// finish-document " ++ sub_name;
    if (mem.indexOfFirstEqualMany(u8, start_s, src)) |after| {
        if (mem.indexOfFirstEqualMany(u8, finish_s, src[after..])) |before| {
            const ret: []const u8 = src[after + start_s.len .. after + before];
            return ret;
        } else {
            file.noexcept.write(2, "missing: " ++ finish_s ++ "\n");
            return null;
        }
    } else {
        file.noexcept.write(2, "missing: " ++ start_s ++ "\n");
        return null;
    }
}
pub fn writeIndent(allocator: *Allocator, array: *String, width: u64, values: []const u8) !void {
    try array.increment(allocator, values.len * 6);
    var l_idx: u64 = 0;
    var r_idx: u64 = 0;
    while (r_idx != values.len) : (r_idx += 1) {
        if (values[r_idx] == '\n') {
            while (r_idx + 1 != values.len and values[r_idx + 1] == '\n') r_idx += 1;
            array.writeMany(ws[0 .. width * 4]);
            array.writeMany(values[l_idx .. r_idx + 1]);
            l_idx = r_idx + 1;
        }
    }
    if (l_idx == 0) {
        array.writeMany(ws[0 .. width * 4]);
    }
    array.writeMany(values[l_idx..r_idx]);
    if (mem.testEqualManyBack(u8, "\n    ", array.readAll(allocator.*))) {
        array.undefine(4);
    }
}
fn unhandledSpecification(comptime what_field: []const u8, comptime opt_spec: OptionSpec) noreturn {
    @compileError("todo: " ++ @tagName(getOptKind(opt_spec)) ++ ": " ++ what_field);
}
pub fn formatCompositeLiteral(allocator: *Allocator, array: *String, comptime T: type, comptime subst: ?struct { import_type: type, type_name: []const u8 }) !void {
    const type_name: []const u8 = @typeName(T);
    const type_info: builtin.Type = @typeInfo(T);
    try array.appendMany(allocator, comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {");
    switch (type_info) {
        .Enum => |enum_info| {
            inline for (enum_info.fields) |field| {
                try array.appendMany(allocator, " " ++ field.name ++ " = ");
                try array.appendFormat(allocator, comptime fmt.any(field.value));
                try array.appendMany(allocator, ",");
            }
            array.undefine(1);
            try array.appendMany(allocator, " }");
        },
        .Union => |union_info| {
            inline for (union_info.fields) |field| {
                try array.appendMany(allocator, " " ++ field.name ++ ": ");
                if (subst) |s| {
                    if (field.type == s.import_type) {
                        try array.appendMany(allocator, s.type_name);
                    } else {
                        switch (@typeInfo(field.type)) {
                            .Enum, .Struct, .Union => {
                                try formatCompositeLiteral(allocator, array, field.type, subst);
                            },
                            else => {
                                try array.appendMany(allocator, @typeName(field.type));
                            },
                        }
                    }
                } else {
                    switch (@typeInfo(field.type)) {
                        .Enum, .Struct, .Union => {
                            try formatCompositeLiteral(allocator, array, field.type, subst);
                        },
                        else => {
                            try array.appendMany(allocator, @typeName(field.type));
                        },
                    }
                }
                try array.appendOne(allocator, ',');
            }
            array.undefine(1);
            try array.appendMany(allocator, " }");
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                try array.appendMany(allocator, " " ++ field.name ++ ": ");
                switch (@typeInfo(field.type)) {
                    .Enum, .Struct, .Union => {
                        try formatCompositeLiteral(allocator, array, field.type, subst);
                    },
                    else => {
                        try array.appendMany(allocator, @typeName(field.type));
                    },
                }
                try array.appendOne(allocator, ',');
            }
            array.undefine(1);
            try array.appendMany(allocator, " }");
        },
        else => @compileError("???" ++ type_name),
    }
}
fn writeIf(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (build.");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, ") {\n");
    width.* += 4;
}
fn writeYesOptionalIf(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (yes_optional_arg) |yes_arg| {\n");
    width.* += 4;
}
fn writeNoOptionalIf(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (no_optional_arg) |no_arg| {\n");
    width.* += 4;
}
fn writeIfHow(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (build.");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, ") |how| {\n");
    width.* += 4;
}
fn writeIfWhat(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (build.");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, ") |");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, "| {\n");
    width.* += 4;
}
fn writeIfOr(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "if (");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, ") {\n");
    width.* += 4;
}
fn writeSwitch(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "switch (");
    try array.appendMany(allocator, what_field);
    try array.appendMany(allocator, ") {\n");
    width.* += 4;
}
fn writeDefaultProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".default => {\n");
    width.* += 4;
}
fn writeExplicitProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".explicit => |how| {\n");
    width.* += 4;
}
fn writeNoProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".no => {\n");
    width.* += 4;
}
fn writeYesProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".yes => {\n");
    width.* += 4;
}
fn writeNoRequiredProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".no => |no_arg| {\n");
    width.* += 4;
}
fn writeYesRequiredProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".yes => |yes_arg| {\n");
    width.* += 4;
}
fn writeYesOptionalProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".yes => |yes_optional_arg| {\n");
    width.* += 4;
}
fn writeNoOptionalProng(allocator: *Allocator, array: *String, width: *u64) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, ".no => |no_optional_arg| {\n");
    width.* += 4;
}
fn writeElse(allocator: *Allocator, array: *String, width: *u64) !void {
    width.* -= 4;
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "} else {\n");
    width.* += 4;
}
fn writeIfClose(allocator: *Allocator, array: *String, width: *u64) !void {
    width.* -= 4;
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "}\n");
}
fn writeSwitchClose(allocator: *Allocator, array: *String, width: *u64) !void {
    width.* -= 4;
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "}\n");
}
fn writeProngClose(allocator: *Allocator, array: *String, width: *u64) !void {
    width.* -= 4;
    try array.appendMany(allocator, ws[0..width.*]);
    try array.appendMany(allocator, "},\n");
}
fn writeNull(allocator: *Allocator, array: *String, width: *u64, variant: Variant) !void {
    try array.appendMany(allocator, ws[0..width.*]);
    switch (variant) {
        .length => try array.appendMany(allocator, "len +%= 1;\n"),
        .write => try array.appendMany(allocator, "array.writeOne(\'\\x00\');\n"),
    }
}
fn writeArg(allocator: *Allocator, array: *String, width: *u64, what_arg: []const u8, variant: Variant) !void {
    switch (variant) {
        .length => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "len +%= mem.reinterpret.lengthAny(u8, fmt_spec, ");
            try array.appendMany(allocator, what_arg);
            try array.appendMany(allocator, ");\n");
        },
        .write => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "array.writeAny(fmt_spec, ");
            try array.appendMany(allocator, what_arg);
            try array.appendMany(allocator, ");\n");
        },
    }
}
fn writeSwitchNoAssign(allocator: *Allocator, array: *String, width: *u64, what_switch: []const u8, variant: Variant) !void {
    switch (variant) {
        .length => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "len +%= ");
            try array.appendFormat(allocator, fmt.ud64(what_switch.len + 3));
            try array.appendMany(allocator, ";\n");
        },
        .write => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "array.writeMany(\"");
            try array.appendMany(allocator, what_switch);
            try array.appendMany(allocator, "\\x00\");\n");
        },
    }
}
fn writeSwitchAssign(allocator: *Allocator, array: *String, width: *u64, what_switch: []const u8, variant: Variant) !void {
    switch (variant) {
        .length => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "len +%= ");
            try array.appendFormat(allocator, fmt.ud64(what_switch.len + 3));
            try array.appendMany(allocator, ";\n");
        },
        .write => {
            try array.appendMany(allocator, ws[0..width.*]);
            try array.appendMany(allocator, "array.writeMany(\"");
            try array.appendMany(allocator, what_switch);
            try array.appendMany(allocator, "=\");\n");
        },
    }
}
fn writeSwitchWithMandatoryArg(allocator: *Allocator, array: *String, width: *u64, what_switch: []const u8, what_arg: []const u8, variant: Variant) !void {
    try writeSwitchNoAssign(allocator, array, width, what_switch, variant);
    try writeArg(allocator, array, width, what_arg, variant);
    try writeNull(allocator, array, width, variant);
}
fn writeSwitchWithOptionalArg(allocator: *Allocator, array: *String, width: *u64, what_switch: []const u8, what_arg: []const u8, variant: Variant) !void {
    try writeSwitchAssign(allocator, array, width, what_switch, variant);
    try writeArg(allocator, array, width, what_arg, variant);
    try writeNull(allocator, array, width, variant);
}
fn writeHow(allocator: *Allocator, array: *String, width: *u64, what_switch: ?[]const u8, variant: Variant) !void {
    if (what_switch) |string| {
        try writeSwitchWithMandatoryArg(allocator, array, width, string, "how", variant);
    } else {
        try writeArg(allocator, array, width, "how", variant);
    }
}
fn writeExplicit(allocator: *Allocator, array: *String, width: *u64, what_switch: ?[]const u8, variant: Variant) !void {
    if (what_switch) |string| {
        try writeSwitchWithMandatoryArg(allocator, array, width, string, "how", variant);
    } else {
        try writeArg(allocator, array, width, "how", variant);
    }
}
fn writeNoRequiredArg(allocator: *Allocator, array: *String, width: *u64, what_not_switch: ?[]const u8, variant: Variant) !void {
    if (what_not_switch) |string| {
        try writeSwitchWithMandatoryArg(allocator, array, width, string, "no_arg", variant);
    } else {
        try writeArg(allocator, array, width, "no_arg", variant);
    }
}
fn writeYesRequiredArg(allocator: *Allocator, array: *String, width: *u64, what_switch: ?[]const u8, variant: Variant) !void {
    if (what_switch) |string| {
        try writeSwitchWithMandatoryArg(allocator, array, width, string, "yes_arg", variant);
    } else {
        try writeArg(allocator, array, width, "yes_arg", variant);
    }
}
pub fn getOptKind(comptime opt_spec: OptionSpec) Kind {
    if (opt_spec.arg_type) |arg_type| {
        if (@typeInfo(arg_type) == .Optional) {
            if (opt_spec.and_no) |inverse| {
                if (inverse.*.arg_type) |no_arg_type| {
                    if (@typeInfo(no_arg_type) == .Optional) {
                        return .what_maybe_how_and_maybe_how_not;
                    } else {
                        return .what_maybe_how_and_how_not;
                    }
                } else {
                    return .what_maybe_how_and_not;
                }
            } else {
                return .what_maybe_how;
            }
        } else {
            if (opt_spec.and_no) |inverse| {
                if (inverse.*.arg_type) |no_arg_type| {
                    if (@typeInfo(no_arg_type) == .Optional) {
                        return .what_how_and_maybe_how_not;
                    } else {
                        return .what_how_and_how_not;
                    }
                } else {
                    return .what_how_and_not;
                }
            } else {
                return .what_how;
            }
        }
    } else {
        if (opt_spec.and_no) |inverse| {
            if (inverse.*.arg_type) |no_arg_type| {
                if (@typeInfo(no_arg_type) == .Optional) {
                    return .what_and_maybe_how_not;
                } else {
                    return .what_and_how_not;
                }
            } else {
                return .what_and_not;
            }
        } else {
            return .what;
        }
    }
}
pub fn getOptType(comptime opt_spec: OptionSpec) type {
    if (@as(?type, blk: {
        if (opt_spec.arg_type_name) |type_name| {
            if (@hasDecl(types, type_name)) {
                const import_type: type = @field(types, type_name);
                if (?import_type == opt_spec.arg_type) {
                    break :blk ?import_type;
                } else {
                    break :blk import_type;
                }
            }
        }
        break :blk opt_spec.arg_type;
    })) |arg_type| {
        if (@typeInfo(arg_type) == .Optional) {
            if (opt_spec.and_no) |inverse| {
                if (inverse.*.arg_type) |no_arg_type| {
                    return ?union(enum) { yes: arg_type, no: no_arg_type };
                } else {
                    return ?union(enum) { yes: arg_type, no };
                }
            } else {
                return ?union(enum) { explicit: arg_type, default };
            }
        } else {
            if (opt_spec.and_no) |inverse| {
                if (inverse.*.arg_type) |no_arg_type| {
                    return ?union(enum) { yes: arg_type, no: no_arg_type };
                } else {
                    return ?union(enum) { yes: arg_type, no };
                }
            } else {
                return ?arg_type;
            }
        }
    } else {
        if (opt_spec.and_no) |inverse| {
            if (inverse.*.arg_type) |no_arg_type| {
                return ?union(enum) {
                    yes,
                    no: no_arg_type,
                };
            } else {
                return ?bool;
            }
        } else {
            return bool;
        }
    }
}
pub fn writeWhat(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8, what_switch: ?[]const u8, variant: Variant) !void {
    try writeIf(allocator, array, width, what_field);
    try writeSwitchNoAssign(allocator, array, width, what_switch.?, variant);
    try writeIfClose(allocator, array, width);
}
pub fn writeWhatHow(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8, what_switch: ?[]const u8, variant: Variant) !void {
    try writeIfHow(allocator, array, width, what_field);
    try writeHow(allocator, array, width, what_switch, variant);
    try writeIfClose(allocator, array, width);
}
pub fn writeWhatOrWhatNot(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8, what_switch: ?[]const u8, what_not_switch: ?[]const u8, variant: Variant) !void {
    try writeIfWhat(allocator, array, width, what_field);
    try writeIfOr(allocator, array, width, what_field);
    try writeSwitchNoAssign(allocator, array, width, what_switch.?, variant);
    try writeElse(allocator, array, width);
    try writeSwitchNoAssign(allocator, array, width, what_not_switch.?, variant);
    try writeIfClose(allocator, array, width);
    try writeIfClose(allocator, array, width);
}
pub fn writeOptionalWhat(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8, what_switch: ?[]const u8, variant: Variant) !void {
    try writeIfWhat(allocator, array, width, what_field);
    try writeSwitch(allocator, array, width, what_field);
    try writeYesOptionalProng(allocator, array, width);
    try writeYesOptionalIf(allocator, array, width);
    try writeSwitchWithOptionalArg(allocator, array, width, what_switch.?, "yes_arg", variant);
    try writeElse(allocator, array, width);
    try writeSwitchNoAssign(allocator, array, width, what_switch.?, variant);
    try writeIfClose(allocator, array, width);
    try writeProngClose(allocator, array, width);
}
pub fn writeNonOptionalWhat(allocator: *Allocator, array: *String, width: *u64, what_field: []const u8, what_switch: ?[]const u8, variant: Variant) !void {
    try writeIfWhat(allocator, array, width, what_field);
    try writeSwitch(allocator, array, width, what_field);
    try writeYesRequiredProng(allocator, array, width);
    try writeYesRequiredArg(allocator, array, width, what_switch, variant);
    try writeProngClose(allocator, array, width);
}
pub fn writeOptionalWhatNot(allocator: *Allocator, array: *String, width: *u64, what_not_switch: ?[]const u8, variant: Variant) !void {
    try writeNoOptionalProng(allocator, array, width);
    try writeNoOptionalIf(allocator, array, width);
    try writeSwitchWithOptionalArg(allocator, array, width, what_not_switch.?, "no_arg", variant);
    try writeElse(allocator, array, width);
    try writeSwitchNoAssign(allocator, array, width, what_not_switch.?, variant);
    try writeIfClose(allocator, array, width);
    try writeProngClose(allocator, array, width);
    try writeSwitchClose(allocator, array, width);
    try writeIfClose(allocator, array, width);
}
pub fn writeNonOptionalWhatNot(allocator: *Allocator, array: *String, width: *u64, what_not_switch: ?[]const u8, variant: Variant) !void {
    try writeNoRequiredProng(allocator, array, width);
    try writeNoRequiredArg(allocator, array, width, what_not_switch, variant);
    try writeProngClose(allocator, array, width);
    try writeSwitchClose(allocator, array, width);
    try writeIfClose(allocator, array, width);
}
pub fn writeNoArgWhatNot(allocator: *Allocator, array: *String, width: *u64, what_not_switch: ?[]const u8, variant: Variant) !void {
    try writeNoProng(allocator, array, width);
    try writeSwitchNoAssign(allocator, array, width, what_not_switch.?, variant);
    try writeProngClose(allocator, array, width);
    try writeSwitchClose(allocator, array, width);
    try writeIfClose(allocator, array, width);
}
pub fn writeStructMembers(allocator: *Allocator, array: *String) !void {
    const width: u64 = (initial_indent * 4);
    inline for (@typeInfo(ExecutableOptions).Opaque.decls) |decl| {
        const opt_spec: OptionSpec = @field(ExecutableOptions, decl.name);
        const field_type: type = getOptType(opt_spec);
        const what_field: []const u8 = decl.name[0 .. decl.name.len - 9];
        try array.appendMany(allocator, ws[0..width] ++ what_field ++ ": ");
        switch (@typeInfo(field_type)) {
            .Bool => {
                try array.appendMany(allocator, @typeName(field_type) ++ " = false");
            },
            .Optional => |optional_info| {
                try array.appendOne(allocator, '?');
                if (opt_spec.arg_type_name) |type_name| {
                    if (!@hasDecl(types, type_name)) {
                        try array.appendMany(allocator, type_name ++ " = null");
                    } else {
                        const import_type: type = @field(types, type_name);
                        switch (@typeInfo(optional_info.child)) {
                            .Enum, .Struct, .Union => {
                                try formatCompositeLiteral(allocator, array, optional_info.child, .{
                                    .import_type = ?import_type,
                                    .type_name = "?" ++ type_name,
                                });
                                try array.appendMany(allocator, " = null");
                            },
                            else => {
                                try array.appendMany(allocator, type_name ++ " = null");
                            },
                        }
                    }
                } else {
                    switch (@typeInfo(optional_info.child)) {
                        .Enum, .Struct, .Union => {
                            try formatCompositeLiteral(allocator, array, optional_info.child, null);
                            try array.appendMany(allocator, " = null");
                        },
                        else => {
                            try array.appendMany(allocator, @typeName(optional_info.child) ++ " = null");
                        },
                    }
                }
            },
            else => {
                unhandledSpecification(what_field, opt_spec);
            },
        }
        try array.appendMany(allocator, ",\n");
    }
}
pub fn writeFunctionBody(allocator: *Allocator, array: *String, variant: Variant) !void {
    var width: u64 = (initial_indent * 4) + 4;
    inline for (@typeInfo(ExecutableOptions).Opaque.decls) |decl| {
        const decl_type: type = @TypeOf(@field(ExecutableOptions, decl.name));
        if (decl_type != OptionSpec) {
            continue;
        }
        const opt_spec: OptionSpec = @field(ExecutableOptions, decl.name);
        const what_field: []const u8 = decl.name[0 .. decl.name.len - 9];
        const what_switch: ?[]const u8 = opt_spec.string;
        if (opt_spec.arg_type) |arg_type| {
            if (@typeInfo(arg_type) == .Optional) {
                if (opt_spec.and_no) |inverse| {
                    try writeOptionalWhat(allocator, array, &width, what_field, what_switch, variant);
                    const what_not_switch: ?[]const u8 = inverse.*.string;
                    if (inverse.*.arg_type) |no_arg_type| {
                        if (@typeInfo(no_arg_type) == .Optional) {
                            try writeOptionalWhatNot(allocator, array, &width, what_not_switch, variant);
                        } else {
                            try writeNonOptionalWhatNot(allocator, array, &width, what_not_switch, variant);
                        }
                    } else {
                        try writeNoArgWhatNot(allocator, array, &width, what_not_switch, variant);
                    }
                } else {
                    unhandledSpecification(what_field, opt_spec);
                }
            } else {
                if (opt_spec.and_no) |inverse| {
                    const what_not_switch: ?[]const u8 = inverse.*.string;
                    try writeNonOptionalWhat(allocator, array, &width, what_field, what_switch, variant);
                    if (inverse.*.arg_type) |no_arg_type| {
                        if (@typeInfo(no_arg_type) == .Optional) {
                            try writeOptionalWhatNot(allocator, array, &width, what_not_switch, variant);
                        } else {
                            try writeNonOptionalWhatNot(allocator, array, &width, what_not_switch, variant);
                        }
                    } else {
                        try writeNoArgWhatNot(allocator, array, &width, what_not_switch, variant);
                    }
                } else {
                    try writeWhatHow(allocator, array, &width, what_field, what_switch, variant);
                }
            }
        } else {
            if (opt_spec.and_no) |inverse| {
                const what_not_switch: ?[]const u8 = inverse.*.string;
                if (inverse.*.arg_type) |no_arg_type| {
                    if (@typeInfo(no_arg_type) == .Optional) {
                        unhandledSpecification(what_field, opt_spec);
                    } else {
                        unhandledSpecification(what_field, opt_spec);
                    }
                } else {
                    try writeWhatOrWhatNot(allocator, array, &width, what_field, what_switch, what_not_switch, variant);
                }
            } else {
                try writeWhat(allocator, array, &width, what_field, what_switch, variant);
            }
        }
    }
}
const Options = struct {
    output: ?[:0]const u8 = null,
    pub const Map = proc.GenericOptions(Options);
    const about_output_s: []const u8 = "write to output to pathname";
    const pathname = .{ .argument = "pathname" };
};
const opt_map: []const Options.Map = meta.slice(Options.Map, .{ // zig fmt: off
    .{ .field_name = "output",          .short = "-o", .long = "--output",  .assign = Options.pathname, .descr = Options.about_output_s },
}); // zig fmt: on
fn srcString(comptime count: usize, comptime pathname: [:0]const u8) !mem.StaticString(count) {
    var ret: mem.StaticString(count) = .{};
    const fd: u64 = try file.open(open_spec, builtin.absolutePath(pathname));
    defer file.close(close_spec, fd);
    ret.define(try file.read(fd, ret.referAllUndefined(), count));
    return ret;
}
pub fn main(args_in: [][*:0]u8) !void {
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opt_map);

    const members_loc_token: []const u8 = "_: void,";
    const len_fn_body_loc_token: []const u8 = "_ = buildLength;";
    const write_fn_body_loc_token: []const u8 = "_ = buildWrite;";

    var address_space: AddressSpace = .{};

    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);

    var array: String = String.init(&allocator);
    try array.increment(&allocator, @embedFile("./builder.zig").len);
    defer array.deinit(&allocator);

    const guess_i: u64 = 1332;
    const guess_j: u64 = 1690;
    const guess_k: u64 = 2243;

    const fd: u64 = try file.open(open_spec, builtin.build_root.? ++ "/top/builder-template.zig");
    try mem.acquire(.{}, AddressSpace, &address_space, 1);
    const arena_1: mem.Arena = AddressSpace.arena(1);

    const lb_addr: u64 = arena_1.lb_addr;
    const ub_addr: u64 = try file.map(.{ .options = .{} }, lb_addr, fd);
    const up_addr: u64 = mach.alignA64(ub_addr, 4096);

    const template_src: [:0]const u8 = mem.pointerManyWithSentinel(u8, lb_addr, ub_addr - lb_addr, 0);
    const builder_src: []const u8 = subTemplate(template_src, "builder-struct.zig").?;
    const types_src: []const u8 = subTemplate(template_src, "builder-types.zig").?;

    const members_offset: u64 = try guessSourceOffset(builder_src, members_loc_token, guess_i);
    const length_fn_body_offset: u64 = try guessSourceOffset(builder_src, len_fn_body_loc_token, guess_j);
    const write_fn_body_offset: u64 = try guessSourceOffset(builder_src, write_fn_body_loc_token, guess_k);

    try array.appendMany(&allocator, builder_src[0 .. members_offset - (initial_indent * 4)]);
    try writeStructMembers(&allocator, &array);

    const kill_spaces: u64 = (initial_indent + 1) * 4;
    try array.appendMany(&allocator, builder_src[members_offset + members_loc_token.len + 1 .. length_fn_body_offset - kill_spaces]);
    try writeFunctionBody(&allocator, &array, .length);

    try array.appendMany(&allocator, builder_src[length_fn_body_offset + len_fn_body_loc_token.len + 1 .. write_fn_body_offset - kill_spaces]);
    try writeFunctionBody(&allocator, &array, .write);

    try array.appendMany(&allocator, builder_src[write_fn_body_offset + write_fn_body_loc_token.len + 1 ..]);
    try array.appendMany(&allocator, types_src);

    if (options.output) |pathname| {
        const builder_fd: u64 = try file.create(create_spec, pathname);
        defer file.close(close_spec, builder_fd);
        try file.write(builder_fd, array.readAll(allocator));
    } else {
        try file.write(1, array.readAll(allocator));
    }
    mem.unmap(.{ .errors = null }, lb_addr, up_addr - lb_addr);
}
