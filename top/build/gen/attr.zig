const types = @import("./types.zig");
pub const build_command_options: []const types.OptionSpec = &.{
    .{
        .name = "emit_bin",
        .string = "-femit-bin",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-bin" },
        .descr = &.{"(default=yes) Output machine code"},
    },
    .{
        .name = "emit_asm",
        .string = "-femit-asm",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-asm" },
        .descr = &.{"(default=no) Output assembly code (.s)"},
    },
    .{
        .name = "emit_llvm_ir",
        .string = "-femit-llvm-ir",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-llvm-ir" },
        .descr = &.{"(default=no) Output optimized LLVM IR (.ll)"},
    },
    .{
        .name = "emit_llvm_bc",
        .string = "-femit-llvm-bc",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-llvm-bc" },
        .descr = &.{"(default=no) Output optimized LLVM BC (.bc)"},
    },
    .{
        .name = "emit_h",
        .string = "-femit-h",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-h" },
        .descr = &.{"(default=no) Output a C header file (.h)"},
    },
    .{
        .name = "emit_docs",
        .string = "-femit-docs",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-docs" },
        .descr = &.{"(default=no) Output documentation (.html)"},
    },
    .{
        .name = "emit_analysis",
        .string = "-femit-analysis",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-analysis" },
        .descr = &.{"(default=no) Output analysis (.json)"},
    },
    .{
        .name = "emit_implib",
        .string = "-femit-implib",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-implib" },
        .descr = &.{"(default=yes) Output an import when building a Windows DLL (.lib)"},
    },
    .{
        .name = "cache_root",
        .string = "--cache-dir",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Override the local cache directory"},
    },
    .{
        .name = "global_cache_root",
        .string = "--global-cache-dir",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Override the global cache directory"},
    },
    .{
        .name = "zig_lib_root",
        .string = "--zig-lib-dir",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Override Zig installation lib directory"},
    },
    .{
        .name = "listen",
        .string = "--listen",
        .arg_info = types.ArgInfo.optional_tag(enum { none, @"-", ipv4 }),
        .descr = &.{"[MISSING]"},
    },
    .{
        .name = "target",
        .string = "-target",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"<arch><sub>-<os>-<abi> see the targets command"},
    },
    .{
        .name = "cpu",
        .string = "-mcpu",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Specify target CPU and feature set"},
    },
    .{
        .name = "code_model",
        .string = "-mcmodel",
        .arg_info = types.ArgInfo.optional_tag(enum { default, tiny, small, kernel, medium, large }),
        .descr = &.{"Limit range of code and data virtual addresses"},
    },
    .{
        .name = "red_zone",
        .string = "-mred-zone",
        .and_no = .{ .string = "-mno-red-zone" },
        .descr = &.{"Enable the \"red-zone\""},
    },
    .{
        .name = "omit_frame_pointer",
        .string = "-fomit-frame-pointer",
        .and_no = .{ .string = "-fno-omit-frame-pointer" },
        .descr = &.{"Omit the stack frame pointer"},
    },
    .{
        .name = "exec_model",
        .string = "-mexec-model",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"(WASI) Execution model"},
    },
    .{
        .name = "name",
        .string = "--name",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Override root name"},
    },
    .{
        .name = "soname",
        .string = "-fsoname",
        .arg_info = types.ArgInfo.string([]const u8),
        .and_no = .{ .string = "-fno-soname" },
        .descr = &.{"Override the default SONAME value"},
    },
    .{
        .name = "mode",
        .string = "-O",
        .arg_info = types.ArgInfo.optional_tag("@TypeOf(@import(\"builtin\").mode)"),
        .descr = &.{
            "Choose what to optimize for:",
            "Debug          Optimizations off, safety on",
            "ReleaseSafe    Optimizations on, safety on",
            "ReleaseFast    Optimizations on, safety off",
            "ReleaseSmall   Size optimizations on, safety off",
        },
    },
    .{
        .name = "passes",
        .string = "-fopt-bisect-limit",
        .arg_info = .{ .tag = .optional_integer, .char = '=', .type = types.ProtoTypeDescr.init(?u64) },
        .descr = &.{"Only run [limit] first LLVM optimization passes"},
    },
    .{
        .name = "main_pkg_path",
        .string = "--main-pkg-path",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the directory of the root package"},
    },
    .{
        .name = "pic",
        .string = "-fPIC",
        .and_no = .{ .string = "-fno-PIC" },
        .descr = &.{"Enable Position Independent Code"},
    },
    .{
        .name = "pie",
        .string = "-fPIE",
        .and_no = .{ .string = "-fno-PIE" },
        .descr = &.{"Enable Position Independent Executable"},
    },
    .{
        .name = "lto",
        .string = "-flto",
        .and_no = .{ .string = "-fno-lto" },
        .descr = &.{"Enable Link Time Optimization"},
    },
    .{
        .name = "stack_check",
        .string = "-fstack-check",
        .and_no = .{ .string = "-fno-stack-check" },
        .descr = &.{"Enable stack probing in unsafe builds"},
    },
    .{
        .name = "stack_protector",
        .string = "-fstack-check",
        .and_no = .{ .string = "-fno-stack-protector" },
        .descr = &.{"Enable stack protection in unsafe builds"},
    },
    .{
        .name = "sanitize_c",
        .string = "-fsanitize-c",
        .and_no = .{ .string = "-fno-sanitize-c" },
        .descr = &.{"Enable C undefined behaviour detection in unsafe builds"},
    },
    .{
        .name = "valgrind",
        .string = "-fvalgrind",
        .and_no = .{ .string = "-fno-valgrind" },
        .descr = &.{"Include valgrind client requests in release builds"},
    },
    .{
        .name = "sanitize_thread",
        .string = "-fsanitize-thread",
        .and_no = .{ .string = "-fno-sanitize-thread" },
        .descr = &.{"Enable thread sanitizer"},
    },
    .{
        .name = "unwind_tables",
        .string = "-funwind-tables",
        .and_no = .{ .string = "-fno-unwind-tables" },
        .descr = &.{"Always produce unwind table entries for all functions"},
    },
    .{
        .name = "llvm",
        .string = "-fLLVM",
        .and_no = .{ .string = "-fno-LLVM" },
        .descr = &.{"Use LLVM as the codegen backend"},
    },
    .{
        .name = "clang",
        .string = "-fClang",
        .and_no = .{ .string = "-fno-Clang" },
        .descr = &.{"Use Clang as the C/C++ compilation backend"},
    },
    .{
        .name = "reference_trace",
        .string = "-freference-trace",
        .and_no = .{ .string = "-fno-reference-trace" },
        .descr = &.{"How many lines of reference trace should be shown per compile error"},
    },
    .{
        .name = "error_tracing",
        .string = "-ferror-tracing",
        .and_no = .{ .string = "-fno-error-tracing" },
        .descr = &.{"Enable error tracing in `ReleaseFast` mode"},
    },
    .{
        .name = "single_threaded",
        .string = "-fsingle-threaded",
        .and_no = .{ .string = "-fno-single-threaded" },
        .descr = &.{"Code assumes there is only one thread"},
    },
    .{
        .name = "function_sections",
        .string = "-ffunction-sections",
        .and_no = .{ .string = "-fno-function-sections" },
        .descr = &.{"Places each function in a separate sections"},
    },
    .{
        .name = "strip",
        .string = "-fstrip",
        .and_no = .{ .string = "-fno-strip" },
        .descr = &.{"Omit debug symbols"},
    },
    .{
        .name = "formatted_panics",
        .string = "-fformatted-panics",
        .and_no = .{ .string = "-fno-formatted-panics" },
        .descr = &.{"Enable formatted safety panics"},
    },
    .{
        .name = "format",
        .string = "-ofmt",
        .arg_info = .{ .tag = .optional_tag, .char = '=', .type = types.ProtoTypeDescr.init(
            ?enum { elf, c, wasm, coff, macho, spirv, plan9, hex, raw },
        ) },
        .descr = &.{
            "Override target object format:",
            "elf                    Executable and Linking Format",
            "c                      C source code",
            "wasm                   WebAssembly",
            "coff                   Common Object File Format (Windows)",
            "macho                  macOS relocatables",
            "spirv                  Standard, Portable Intermediate Representation V (SPIR-V)",
            "plan9                  Plan 9 from Bell Labs object format",
            "hex (planned feature)  Intel IHEX",
            "raw (planned feature)  Dump machine code directly",
        },
    },
    .{
        .name = "dirafter",
        .string = "-idirafter",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to AFTER include search path"},
    },
    .{
        .name = "system",
        .string = "-isystem",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to SYSTEM include search path"},
    },
    .{
        .name = "libc",
        .string = "--libc",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Provide a file which specifies libc paths"},
    },
    .{
        .name = "library",
        .string = "--library",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Link against system library (only if actually used)"},
    },
    .{
        .name = "include",
        .string = "-I",
        .arg_info = types.ArgInfo.repeatable_string([]const []const u8),
        .descr = &.{"Add directories to include search path"},
    },
    .{
        .name = "needed_library",
        .string = "--needed-library",
        .arg_info = types.ArgInfo.repeatable_string([]const []const u8),
        .descr = &.{"Link against system library (even if unused)"},
    },
    .{
        .name = "library_directory",
        .string = "--library-directory",
        .arg_info = types.ArgInfo.repeatable_string([]const []const u8),
        .descr = &.{"Add a directory to the library search path"},
    },
    .{
        .name = "link_script",
        .string = "--script",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Use a custom linker script"},
    },
    .{
        .name = "version_script",
        .string = "--version-script",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Provide a version .map file"},
    },
    .{
        .name = "dynamic_linker",
        .string = "--dynamic-linker",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the dynamic interpreter path"},
    },
    .{
        .name = "sysroot",
        .string = "--sysroot",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the system root directory"},
    },
    .{
        .name = "entry",
        .string = "--entry",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the entrypoint symbol name"},
    },
    .{
        .name = "lld",
        .string = "-fLLD",
        .and_no = .{ .string = "-fno-LLD" },
        .descr = &.{"Use LLD as the linker"},
    },
    .{
        .name = "compiler_rt",
        .string = "-fcompiler-rt",
        .and_no = .{ .string = "-fno-compiler-rt" },
        .descr = &.{"(default) Include compiler-rt symbols in output"},
    },
    .{
        .name = "rpath",
        .string = "-rpath",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to the runtime library search path"},
    },
    .{
        .name = "each_lib_rpath",
        .string = "-feach-lib-rpath",
        .and_no = .{ .string = "-fno-each-lib-rpath" },
        .descr = &.{"Ensure adding rpath for each used dynamic library"},
    },
    .{
        .name = "allow_shlib_undefined",
        .string = "-fallow-shlib-undefined",
        .and_no = .{ .string = "-fno-allow-shlib-undefined" },
        .descr = &.{"Allow undefined symbols in shared libraries"},
    },
    .{
        .name = "build_id",
        .string = "-fbuild-id",
        .and_no = .{ .string = "-fno-build-id" },
        .descr = &.{"Help coordinate stripped binaries with debug symbols"},
    },
    .{
        .name = "compress_debug_sections",
        .string = "--compress-debug-sections=zlib",
        .and_no = .{ .string = "--compress-debug-sections=none" },
        .descr = &.{
            "Debug section compression:",
            "none   No compression",
            "zlib   Compression with deflate/inflate",
        },
    },
    .{
        .name = "gc_sections",
        .string = "--gc-sections",
        .and_no = .{ .string = "--no-gc-sections" },
        .descr = &.{
            "Force removal of functions and data that are unreachable",
            "by the entry point or exported symbols",
        },
    },
    .{
        .name = "stack",
        .string = "--stack",
        .arg_info = types.ArgInfo.optional_integer(u64),
        .descr = &.{"Override default stack size"},
    },
    .{
        .name = "image_base",
        .string = "--image-base",
        .arg_info = types.ArgInfo.optional_integer(u64),
        .descr = &.{"Set base address for executable image"},
    },
    .{
        .name = "macros",
        .arg_info = types.ArgInfo.optional_mapped("[]const types.Macro"),
        .descr = &.{"Define C macros available within the `@cImport` namespace"},
    },
    .{
        .name = "modules",
        .arg_info = types.ArgInfo.optional_mapped("[]const types.Module"),
        .descr = &.{"Define modules available as dependencies for the current target"},
    },
    .{
        .name = "dependencies",
        .arg_info = types.ArgInfo.optional_mapped("[]const types.ModuleDependency"),
        .descr = &.{"Define module dependencies for the current target"},
    },
    .{
        .name = "cflags",
        .arg_info = types.ArgInfo.optional_mapped([]const []const u8),
        .descr = &.{"Set extra flags for the next position C source files"},
    },
    .{
        .name = "link_libc",
        .string = "-lc",
        .descr = &.{"Link libc"},
    },
    .{
        .name = "rdynamic",
        .string = "-rdynamic",
        .descr = &.{"Add all symbols to the dynamic symbol table"},
    },
    .{
        .name = "dynamic",
        .string = "-dynamic",
        .descr = &.{"Force output to be dynamically linked"},
    },
    .{
        .name = "static",
        .string = "-static",
        .descr = &.{"Force output to be statically linked"},
    },
    .{
        .name = "symbolic",
        .string = "-Bsymbolic",
        .descr = &.{"Bind global references locally"},
    },
    .{
        .name = "z",
        .string = "-z",
        .arg_info = types.ArgInfo.repeatable_tag([]const enum { nodelete, notext, defs, origin, nocopyreloc, now, lazy, relro, norelro }),
        .descr = &.{
            "Set linker extension flags:",
            "nodelete                   Indicate that the object cannot be deleted from a process",
            "notext                     Permit read-only relocations in read-only segments",
            "defs                       Force a fatal error if any undefined symbols remain",
            "undefs                     Reverse of -z defs",
            "origin                     Indicate that the object must have its origin processed",
            "nocopyreloc                Disable the creation of copy relocations",
            "now (default)              Force all relocations to be processed on load",
            "lazy                       Don't force all relocations to be processed on load",
            "relro (default)            Force all relocations to be read-only after processing",
            "norelro                    Don't force all relocations to be read-only after processing",
            "common-page-size=[bytes]   Set the common page size for ELF binaries",
            "max-page-size=[bytes]      Set the max page size for ELF binaries",
        },
    },
    .{
        .name = "files",
        .arg_info = types.ArgInfo.optional_mapped("[]const types.Path"),
        .descr = &.{"Add auxiliary files to the current target"},
    },
    // Other options
    .{
        .name = "color",
        .string = "--color",
        .arg_info = types.ArgInfo.optional_tag(enum { on, off, auto }),
        .descr = &.{"Enable or disable colored error messages"},
    },
    .{
        .name = "time_report",
        .string = "-ftime-report",
        .descr = &.{"Print timing diagnostics"},
    },
    .{
        .name = "stack_report",
        .string = "-fstack-report",
        .descr = &.{"Print stack size diagnostics"},
    },
    .{
        .name = "verbose_link",
        .string = "--verbose-link",
        .descr = &.{"Display linker invocations"},
    },
    .{
        .name = "verbose_cc",
        .string = "--verbose-cc",
        .descr = &.{"Display C compiler invocations"},
    },
    .{
        .name = "verbose_air",
        .string = "--verbose-air",
        .descr = &.{"Enable compiler debug output for Zig AIR"},
    },
    .{
        .name = "verbose_mir",
        .string = "--verbose-mir",
        .descr = &.{"Enable compiler debug output for Zig MIR"},
    },
    .{
        .name = "verbose_llvm_ir",
        .string = "--verbose-llvm-ir",
        .descr = &.{"Enable compiler debug output for LLVM IR"},
    },
    .{
        .name = "verbose_cimport",
        .string = "--verbose-cimport",
        .descr = &.{"Enable compiler debug output for C imports"},
    },
    .{
        .name = "verbose_llvm_cpu_features",
        .string = "--verbose-llvm-cpu-features",
        .descr = &.{"Enable compiler debug output for LLVM CPU features"},
    },
    .{
        .name = "debug_log",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .string = "--debug-log",
        .descr = &.{"Enable printing debug/info log messages for scope"},
    },
    .{
        .name = "debug_compiler_errors",
        .string = "--debug-compile-errors",
        .descr = &.{"Crash with helpful diagnostics at the first compile error"},
    },
    .{
        .name = "debug_link_snapshot",
        .string = "--debug-link-snapshot",
        .descr = &.{"Enable dumping of the linker's state in JSON"},
    },
};
pub const ranlib_command_options: []const types.OptionSpec = &.{
    .{
        .name = "real_ids",
        .string = "-U",
        .descr = &.{"Use actual timestamps and uids/gids"},
        .and_no = .{
            .string = "-D",
        },
    },
};
pub const archive_command_options: []const types.OptionSpec = &.{
    .{
        .name = "format",
        .string = "--format",
        .arg_info = types.ArgInfo.optional_tag(enum { default, gnu, darwin, bsd, bigarchive }),
        .descr = &.{"Archive format to create"},
    },
    .{
        .name = "plugin",
        .string = "--plugin",
        .descr = &.{"Ignored for compatibility"},
    },
    .{
        .name = "output",
        .string = "--output",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Extraction target directory"},
    },
    .{
        .name = "thin",
        .string = "--thin",
        .descr = &.{"Create a thin archive"},
    },
    .{
        .name = "after",
        .string = "a",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Put [files] after [relpos]"},
    },
    .{
        .name = "before",
        .string = "b",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Put [files] before [relpos] (same as [i])"},
    },
    .{
        .name = "create",
        .string = "c",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Do not warn if archive had to be created"},
    },
    .{
        .name = "zero_ids",
        .string = "D",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Use zero for timestamps and uids/gids (default)"},
    },
    .{
        .name = "real_ids",
        .string = "U",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Use actual timestamps and uids/gids"},
    },
    .{
        .name = "append",
        .string = "L",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Add archive's contents"},
    },
    .{
        .name = "preserve_dates",
        .string = "o",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Preserve original dates"},
    },
    .{
        .name = "index",
        .string = "s",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"Create an archive index (cf. ranlib)"},
    },
    .{
        .name = "no_symbol_table",
        .string = "S",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"do not build a symbol table"},
    },
    .{
        .name = "update",
        .string = "u",
        .arg_info = .{ .char = types.ArgInfo.immediate },
        .descr = &.{"update only [files] newer than archive contents"},
    },
    .{
        .name = "operation",
        .arg_info = types.ArgInfo.tag(enum { d, m, q, r, s, x }),
        .descr = &.{
            "d  Delete [files] from the archive",
            "m  Move [files] in the archive",
            "q  Quick append [files] to the archive",
            "r  Replace or insert [files] into the archive",
            "s  Act as ranlib",
            "x  Extract [files] from the archive",
        },
    },
    .{
        .name = "archive",
        .arg_info = types.ArgInfo.optional_formatter("types.Path"),
        .descr = &.{"Target archive"},
    },
    .{
        .name = "files",
        .arg_info = types.ArgInfo.optional_mapped("[]const types.Path"),
        .descr = &.{"Add auxiliary files to the current archive"},
    },
};

pub const format_command_options: []const types.OptionSpec = &.{
    .{
        .name = "color",
        .string = "--color",
        .arg_info = types.ArgInfo.optional_tag(enum { auto, off, on }),
        .descr = &.{"Enable or disable colored error messages"},
    },
    .{
        .name = "stdin",
        .string = "--stdin",
        .descr = &.{"Format code from stdin; output to stdout"},
    },
    .{
        .name = "check",
        .string = "--check",
        .descr = &.{"List non-conforming files and exit with an error if the list is non-empty"},
    },
    .{
        .name = "ast_check",
        .string = "--ast-check",
        .default_value = "true",
        .descr = &.{"Run zig ast-check on every file"},
    },
    .{
        .name = "exclude",
        .string = "--exclude",
        .arg_info = types.ArgInfo.optional_string([]const u8),
        .descr = &.{"Exclude file or directory from formatting"},
    },
};
