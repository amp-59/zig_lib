const types = @import("./types.zig");

const string_type = types.ProtoTypeDescr.init([]const u8);
const optional_string_type = types.ProtoTypeDescr.init(?[]const u8);
const repeatable_string_type = types.ProtoTypeDescr.init(?[]const []const u8);
const integer_type = types.ProtoTypeDescr.init(usize);
const optional_integer_type = types.ProtoTypeDescr.init(?usize);

pub const zig_build_command_attributes: types.Attributes = .{
    .type_name = "BuildCommand",
    .fn_name = "build",
    .params = &.{
        .{
            .name = "zig_exe",
            .info = .{ .tag = .string_param, .type = string_type },
        },
        .{
            .string = "build-",
            .info = .{ .tag = .string_literal, .char = types.ParamInfo.immediate },
        },
        .{
            .name = "kind",
            .info = .{
                .tag = .tag_field,
                .type = .{ .type_name = "types.OutputMode" },
            },
        },
        .{
            .name = "emit_bin",
            .string = "-femit-bin",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-bin" },
            .descr = &.{"(default=yes) Output machine code"},
        },
        .{
            .name = "emit_asm",
            .string = "-femit-asm",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-asm" },
            .descr = &.{"(default=no) Output assembly code (.s)"},
        },
        .{
            .name = "emit_llvm_ir",
            .string = "-femit-llvm-ir",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-llvm-ir" },
            .descr = &.{"(default=no) Output optimized LLVM IR (.ll)"},
        },
        .{
            .name = "emit_llvm_bc",
            .string = "-femit-llvm-bc",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-llvm-bc" },
            .descr = &.{"(default=no) Output optimized LLVM BC (.bc)"},
        },
        .{
            .name = "emit_h",
            .string = "-femit-h",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-h" },
            .descr = &.{"(default=no) Output a C header file (.h)"},
        },
        .{
            .name = "emit_docs",
            .string = "-femit-docs",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-docs" },
            .descr = &.{"(default=no) Output documentation (.html)"},
        },
        .{
            .name = "emit_analysis",
            .string = "-femit-analysis",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-analysis" },
            .descr = &.{"(default=no) Output analysis (.json)"},
        },
        .{
            .name = "emit_implib",
            .string = "-femit-implib",
            .info = .{
                .tag = .optional_formatter_field,
                .type = .{ .type_name = "?types.Path" },
            },
            .and_no = .{ .string = "-fno-emit-implib" },
            .descr = &.{"(default=yes) Output an import when building a Windows DLL (.lib)"},
        },
        .{
            .name = "cache_root",
            .string = "--cache-dir",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Override the local cache directory"},
        },
        .{
            .name = "global_cache_root",
            .string = "--global-cache-dir",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Override the global cache directory"},
        },
        .{
            .name = "zig_lib_root",
            .string = "--zig-lib-dir",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Override Zig installation lib directory"},
        },
        .{
            .name = "listen",
            .string = "--listen",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { none, @"-", ipv4 }),
            },
            .descr = &.{"[MISSING]"},
        },
        .{
            .name = "target",
            .string = "-target",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"<arch><sub>-<os>-<abi> see the targets command"},
        },
        .{
            .name = "cpu",
            .string = "-mcpu",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Specify target CPU and feature set"},
        },
        .{
            .name = "code_model",
            .string = "-mcmodel",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { default, tiny, small, kernel, medium, large }),
            },
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
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"(WASI) Execution model"},
        },
        .{
            .name = "name",
            .string = "--name",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Override root name"},
        },
        .{
            .name = "soname",
            .string = "-fsoname",
            .info = .{ .tag = .string_field, .type = string_type },
            .and_no = .{ .string = "-fno-soname" },
            .descr = &.{"Override the default SONAME value"},
        },
        .{
            .name = "mode",
            .string = "-O",
            .info = .{
                .tag = .optional_tag_field,
                .type = .{ .type_name = "?@TypeOf(@import(\"builtin\").mode)" },
            },
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
            .info = .{ .tag = .optional_integer_field, .char = '=', .type = types.ProtoTypeDescr.init(?u64) },
            .descr = &.{"Only run [limit] first LLVM optimization passes"},
        },
        .{
            .name = "main_pkg_path",
            .string = "--main-pkg-path",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
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
            .info = .{ .tag = .optional_tag_field, .char = '=', .type = types.ProtoTypeDescr.init(
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
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Add directory to AFTER include search path"},
        },
        .{
            .name = "system",
            .string = "-isystem",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Add directory to SYSTEM include search path"},
        },
        .{
            .name = "libc",
            .string = "--libc",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Provide a file which specifies libc paths"},
        },
        .{
            .name = "library",
            .string = "--library",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Link against system library (only if actually used)"},
        },
        .{
            .name = "include",
            .string = "-I",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
            },
            .descr = &.{"Add directories to include search path"},
        },
        .{
            .name = "needed_library",
            .string = "--needed-library",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
            },
            .descr = &.{"Link against system library (even if unused)"},
        },
        .{
            .name = "library_directory",
            .string = "--library-directory",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
            },
            .descr = &.{"Add a directory to the library search path"},
        },
        .{
            .name = "link_script",
            .string = "--script",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Use a custom linker script"},
        },
        .{
            .name = "version_script",
            .string = "--version-script",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Provide a version .map file"},
        },
        .{
            .name = "dynamic_linker",
            .string = "--dynamic-linker",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Set the dynamic interpreter path"},
        },
        .{
            .name = "sysroot",
            .string = "--sysroot",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Set the system root directory"},
        },
        .{
            .name = "entry",
            .string = "--entry",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
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
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
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
            .info = .{ .tag = .optional_integer_field, .type = optional_integer_type },
            .descr = &.{"Override default stack size"},
        },
        .{
            .name = "image_base",
            .string = "--image-base",
            .info = .{ .tag = .optional_integer_field, .type = optional_integer_type },
            .descr = &.{"Set base address for executable image"},
        },
        .{
            .name = "macros",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.Macro" },
            },
            .descr = &.{"Define C macros available within the `@cImport` namespace"},
        },
        .{
            .name = "modules",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.Module" },
            },
            .descr = &.{"Define modules available as dependencies for the current target"},
        },
        .{
            .name = "dependencies",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.ModuleDependency" },
            },
            .descr = &.{"Define module dependencies for the current target"},
        },
        .{
            .name = "cflags",
            .info = .{
                .tag = .optional_mapped_field,
                .type = repeatable_string_type,
            },
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
            .info = .{
                .tag = .repeatable_tag_field,
                .type = types.ProtoTypeDescr.init(?[]const enum { nodelete, notext, defs, origin, nocopyreloc, now, lazy, relro, norelro }),
            },
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
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.Path" },
            },
            .descr = &.{"Add auxiliary files to the current target"},
        },
        // Other options
        .{
            .name = "color",
            .string = "--color",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { on, off, auto }),
            },
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
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
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
        .{
            .name = "root_path",
            .info = .{ .tag = .formatter_param, .type = .{ .type_name = "types.Path" } },
        },
    },
};

pub const ranlib_command_options: []const types.ParamSpec = &.{
    .{
        .name = "real_ids",
        .string = "-U",
        .descr = &.{"Use actual timestamps and uids/gids"},
        .and_no = .{
            .string = "-D",
        },
    },
};
pub const zig_ar_command_attributes: types.Attributes = .{
    .type_name = "ArchiveCommand",
    .fn_name = "archive",
    .params = &.{
        .{
            .name = "zig_exe",
            .info = .{ .tag = .string_param, .type = string_type },
        },
        .{
            .string = "ar",
            .info = .{ .tag = .string_literal },
        },
        .{
            .name = "format",
            .string = "--format",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { default, gnu, darwin, bsd, bigarchive }),
            },
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
            .info = .{
                .tag = .optional_string_field,
                .type = optional_string_type,
            },
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
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Put [files] after [relpos]"},
        },
        .{
            .name = "before",
            .string = "b",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Put [files] before [relpos] (same as [i])"},
        },
        .{
            .name = "create",
            .string = "c",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Do not warn if archive had to be created"},
        },
        .{
            .name = "zero_ids",
            .string = "D",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Use zero for timestamps and uids/gids (default)"},
        },
        .{
            .name = "real_ids",
            .string = "U",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Use actual timestamps and uids/gids"},
        },
        .{
            .name = "append",
            .string = "L",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Add archive's contents"},
        },
        .{
            .name = "preserve_dates",
            .string = "o",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Preserve original dates"},
        },
        .{
            .name = "index",
            .string = "s",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"Create an archive index (cf. ranlib)"},
        },
        .{
            .name = "no_symbol_table",
            .string = "S",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"do not build a symbol table"},
        },
        .{
            .name = "update",
            .string = "u",
            .info = .{ .char = types.ParamInfo.immediate },
            .descr = &.{"update only [files] newer than archive contents"},
        },
        .{
            .name = "operation",
            .info = .{ .tag = .tag_field, .type = types.ProtoTypeDescr.init(enum { d, m, q, r, s, x }) },
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
            .info = .{
                .tag = .formatter_param,
                .type = .{ .type_name = "types.Path" },
            },
        },
        .{
            .name = "files",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.Path" },
            },
            .descr = &.{"Add auxiliary files to the current archive"},
        },
    },
};
pub const zig_format_command_attributes: types.Attributes = .{
    .type_name = "FormatCommand",
    .fn_name = "format",
    .params = &.{
        .{
            .name = "zig_exe",
            .info = .{ .tag = .string_param, .type = string_type },
        },
        .{
            .string = "fmt",
            .info = .{ .tag = .string_literal },
        },
        .{
            .name = "color",
            .string = "--color",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { auto, off, on }),
            },
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
            .info = .{
                .tag = .optional_string_field,
                .type = optional_string_type,
            },
            .descr = &.{"Exclude file or directory from formatting"},
        },
        .{
            .name = "root_path",
            .info = .{
                .tag = .formatter_param,
                .type = .{ .type_name = "types.Path" },
            },
        },
    },
};
pub const llvm_tblgen_command_attributes: types.Attributes = .{
    .type_name = "TableGenCommand",
    .fn_name = "tblgen",
    .params = &.{
        .{
            .name = "color",
            .string = "--color",
            .info = .{
                .tag = .optional_tag_field,
                .type = types.ProtoTypeDescr.init(?enum { on, off, auto }),
            },
            .descr = &.{"Use colors in output (default=autodetect)"},
        },
        .{
            .name = "macros",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.Macro" },
            },
            .descr = &.{"Define macros available within the `@cImport` namespace"},
        },
        .{
            .name = "include",
            .string = "-I",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
                .char = types.ParamInfo.immediate,
            },
            .descr = &.{"Add directories to include search path"},
        },
        .{
            .name = "dependencies",
            .string = "-d",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
            },
            .descr = &.{"Add file dependencies"},
        },
        .{
            .name = "print_records",
            .string = "--print-records",
            .descr = &.{"Print all records to stdout (default)"},
        },
        .{
            .name = "print_detailed_records",
            .string = "--print-detailed-records",
            .descr = &.{"Print full details of all records to stdout"},
        },
        .{
            .name = "null_backend",
            .string = "--null-backend",
            .descr = &.{"Do nothing after parsing (useful for timing)"},
        },
        .{
            .name = "dump_json",
            .string = "--dump-json",
            .descr = &.{"Dump all records as machine-readable JSON"},
        },
        .{
            .name = "gen_emitter",
            .string = "--gen-emitter",
            .descr = &.{"Generate machine code emitter"},
        },
        .{
            .name = "gen_register_info",
            .string = "--gen-register-info",
            .descr = &.{"Generate registers and register classes info"},
        },
        .{
            .name = "gen_instr_info",
            .string = "--gen-instr-info",
            .descr = &.{"Generate instruction descriptions"},
        },
        .{
            .name = "gen_instr_docs",
            .string = "--gen-instr-docs",
            .descr = &.{"Generate instruction documentation"},
        },
        .{
            .name = "gen_callingconv",
            .string = "--gen-callingconv",
            .descr = &.{"Generate calling convention descriptions"},
        },
        .{
            .name = "gen_asm_writer",
            .string = "--gen-asm-writer",
            .descr = &.{"Generate assembly writer"},
        },
        .{
            .name = "gen_disassembler",
            .string = "--gen-disassembler",
            .descr = &.{"Generate disassembler"},
        },
        .{
            .name = "gen_pseudo_lowering",
            .string = "--gen-pseudo-lowering",
            .descr = &.{"Generate pseudo instruction lowering"},
        },
        .{
            .name = "gen_compress_inst_emitter",
            .string = "--gen-compress-inst-emitter",
            .descr = &.{"Generate RISCV compressed instructions."},
        },
        .{
            .name = "gen_asm_matcher",
            .string = "--gen-asm-matcher",
            .descr = &.{"Generate assembly instruction matcher"},
        },
        .{
            .name = "gen_dag_isel",
            .string = "--gen-dag-isel",
            .descr = &.{"Generate a DAG instruction selector"},
        },
        .{
            .name = "gen_dfa_packetizer",
            .string = "--gen-dfa-packetizer",
            .descr = &.{"Generate DFA Packetizer for VLIW targets"},
        },
        .{
            .name = "gen_fast_isel",
            .string = "--gen-fast-isel",
            .descr = &.{"Generate a \"fast\" instruction selector"},
        },
        .{
            .name = "gen_subtarget",
            .string = "--gen-subtarget",
            .descr = &.{"Generate subtarget enumerations"},
        },
        .{
            .name = "gen_intrinsic_enums",
            .string = "--gen-intrinsic-enums",
            .descr = &.{"Generate intrinsic enums"},
        },
        .{
            .name = "gen_intrinsic_impl",
            .string = "--gen-intrinsic-impl",
            .descr = &.{"Generate intrinsic information"},
        },
        .{
            .name = "print_enums",
            .string = "--print-enums",
            .descr = &.{"Print enum values for a class"},
        },
        .{
            .name = "print_sets",
            .string = "--print-sets",
            .descr = &.{"Print expanded sets for testing DAG exprs"},
        },
        .{
            .name = "gen_opt_parser_defs",
            .string = "--gen-opt-parser-defs",
            .descr = &.{"Generate option definitions"},
        },
        .{
            .name = "gen_opt_rst",
            .string = "--gen-opt-rst",
            .descr = &.{"Generate option RST"},
        },
        .{
            .name = "gen_ctags",
            .string = "--gen-ctags",
            .descr = &.{"Generate ctags-compatible index"},
        },
        .{
            .name = "gen_attrs",
            .string = "--gen-attrs",
            .descr = &.{"Generate attributes"},
        },
        .{
            .name = "gen_searchable_tables",
            .string = "--gen-searchable-tables",
            .descr = &.{"Generate generic binary-searchable table"},
        },
        .{
            .name = "gen_global_isel",
            .string = "--gen-global-isel",
            .descr = &.{"Generate GlobalISel selector"},
        },
        .{
            .name = "gen_global_isel_combiner",
            .string = "--gen-global-isel-combiner",
            .descr = &.{"Generate GlobalISel combiner"},
        },
        .{
            .name = "gen_x86_EVEX2VEX_tables",
            .string = "--gen-x86-EVEX2VEX-tables",
            .descr = &.{"Generate X86 EVEX to VEX compress tables"},
        },
        .{
            .name = "gen_x86_fold_tables",
            .string = "--gen-x86-fold-tables",
            .descr = &.{"Generate X86 fold tables"},
        },
        .{
            .name = "gen_x86_mnemonic_tables",
            .string = "--gen-x86-mnemonic-tables",
            .descr = &.{"Generate X86 mnemonic tables"},
        },
        .{
            .name = "gen_register_bank",
            .string = "--gen-register-bank",
            .descr = &.{"Generate registers bank descriptions"},
        },
        .{
            .name = "gen_exegesis",
            .string = "--gen-exegesis",
            .descr = &.{"Generate llvm-exegesis tables"},
        },
        .{
            .name = "gen_automata",
            .string = "--gen-automata",
            .descr = &.{"Generate generic automata"},
        },
        .{
            .name = "gen_directive_decl",
            .string = "--gen-directive-decl",
            .descr = &.{"Generate directive related declaration code (header file)"},
        },
        .{
            .name = "gen_directive_impl",
            .string = "--gen-directive-impl",
            .descr = &.{"Generate directive related implementation code"},
        },
        .{
            .name = "gen_dxil_operation",
            .string = "--gen-dxil-operation",
            .descr = &.{"Generate DXIL operation information"},
        },
        .{
            .name = "gen_riscv_target_def",
            .string = "--gen-riscv-target_def",
            .descr = &.{"Generate the list of CPU for RISCV"},
        },
        .{
            .name = "output",
            .string = "-o",
            .info = .{ .tag = .optional_string_field, .type = optional_string_type },
            .descr = &.{"Output file"},
        },
    },
};
pub const harec_attributes: types.Attributes = .{
    .type_name = "HarecCommand",
    .fn_name = "harec",
    .params = &.{
        .{
            .name = "harec_exe",
            .info = .{ .tag = .string_param, .type = string_type },
        },
        .{
            .name = "arch",
            .string = "-a",
            .info = .{
                .tag = .optional_string_field,
                .type = optional_string_type,
            },
        },
        .{
            .name = "defs",
            .info = .{
                .tag = .optional_mapped_field,
                .type = .{ .type_name = "?[]const types.HMacro" },
            },
            .descr = &.{"Define identifiers"},
        },
        .{
            .name = "output",
            .string = "-o",
            .info = .{
                .tag = .optional_string_field,
                .type = optional_string_type,
            },
            .descr = &.{"Output file"},
        },
        .{
            .name = "tags",
            .string = "-T",
            .info = .{
                .tag = .repeatable_string_field,
                .type = repeatable_string_type,
                .char = types.ParamInfo.immediate,
            },
        },
        .{
            .name = "typedefs",
            .string = "-t",
        },
        .{
            .name = "namespace",
            .string = "-N",
        },
    },
};
