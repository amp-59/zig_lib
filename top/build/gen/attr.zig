const builtin = @import("../../builtin.zig");
const types = struct {
    pub usingnamespace @import("./types.zig");
    pub usingnamespace @import("../types.zig");
};
const string_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init([]const u8),
};
const optional_string_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?[]const u8),
};
const optional_repeatable_string_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?[]const []const u8),
};
const integer_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(usize),
};
const listen_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?types.Listen" } },
    .parse = &types.ProtoTypeDescr.init(types.Listen),
};
const optional_integer_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?usize),
};
const auto_on_off_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?types.AutoOnOff" } },
    .parse = &types.ProtoTypeDescr.init(types.AutoOnOff),
};
const optional_path_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?types.Path" } },
    .parse = &.{ .type_decl = .{ .name = "types.Path" } },
};
const paths_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "[]const types.Path" } },
    .write = &.{ .type_decl = .{ .name = "types.Path" } },
};
const optional_macro_slice_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?[]const types.Macro" } },
    .write = &.{ .type_decl = .{ .name = "types.Macros" } },
    .parse = &.{ .type_decl = .{ .name = "types.Macro" } },
};
const optional_module_slice_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?[]const types.Module" } },
    .write = &.{ .type_decl = .{ .name = "types.Modules" } },
    .parse = &.{ .type_decl = .{ .name = "types.Module" } },
};
const optional_dependencies_slice_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?[]const types.ModuleDependency" } },
    .write = &.{ .type_decl = .{ .name = "types.ModuleDependencies" } },
    .parse = &.{ .type_decl = .{ .name = "types.ModuleDependencies" } },
};
const build_id_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?types.BuildId" } },
    .parse = &types.ProtoTypeDescr.init(types.BuildId),
};
const link_flags_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?[]const types.LinkFlags),
    .parse = &.{ .type_decl = .{ .name = "types.LinkFlags" } },
};
const optimize_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?builtin.OptimizeMode" } },
    .parse = &types.ProtoTypeDescr.init(builtin.OptimizeMode),
};
const code_model_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?builtin.CodeModel" } },
    .parse = &types.ProtoTypeDescr.init(builtin.CodeModel),
};
const output_mode_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "types.BinaryOutput" } },
};
const output_format_type: types.ProtoTypeDescrMap = .{
    .store = &.{ .type_decl = .{ .name = "?builtin.ObjectFormat" } },
    .parse = &types.ProtoTypeDescr.init(builtin.ObjectFormat),
};
const flags_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?[]const []const u8),
    .write = &.{ .type_decl = .{ .name = "types.ExtraFlags" } },
    .parse = &.{ .type_decl = .{ .name = "types.ExtraFlags" } },
};
pub const scope: []const types.ProtoTypeDescr.Declaration = &.{
    .{ .name = "PathUnion", .defn = .{
        .spec = "union(enum)",
        .fields = &.{ .{
            .name = "yes",
            .type = .{ .type_decl = .{ .name = "?types.Path" } },
        }, .{
            .name = "no",
        } },
    } },
};
pub const zig_build_command_attributes: types.Attributes = .{
    .type_name = "BuildCommand",
    .fn_name = "build",
    .type_fn_name = "GenericBuildCommand",
    .params = &.{
        .{
            .name = "zig_exe",
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .string = "build-",
            .tag = .{ .literal = .string },
            .char = types.ParamSpec.immediate,
        },
        .{
            .name = "kind",
            .tag = .{ .field = .tag },
            .type = output_mode_type,
        },
        .{
            .name = "emit_bin",
            .string = "-femit-bin",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-bin" },
            .descr = &.{"(default=yes) Output machine code"},
        },
        .{
            .name = "emit_asm",
            .string = "-femit-asm",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-asm" },
            .descr = &.{"(default=no) Output assembly code (.s)"},
        },
        .{
            .name = "emit_llvm_ir",
            .string = "-femit-llvm-ir",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-llvm-ir" },
            .descr = &.{"(default=no) Output optimized LLVM IR (.ll)"},
        },
        .{
            .name = "emit_llvm_bc",
            .string = "-femit-llvm-bc",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-llvm-bc" },
            .descr = &.{"(default=no) Output optimized LLVM BC (.bc)"},
        },
        .{
            .name = "emit_h",
            .string = "-femit-h",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-h" },
            .descr = &.{"(default=no) Output a C header file (.h)"},
        },
        .{
            .name = "emit_docs",
            .string = "-femit-docs",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-docs" },
            .descr = &.{"(default=no) Output documentation (.html)"},
        },
        .{
            .name = "emit_analysis",
            .string = "-femit-analysis",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-analysis" },
            .descr = &.{"(default=no) Output analysis (.json)"},
        },
        .{
            .name = "emit_implib",
            .string = "-femit-implib",
            .tag = .{ .optional_field = .formatter },
            .type = optional_path_type,
            .and_no = .{ .string = "-fno-emit-implib" },
            .descr = &.{"(default=yes) Output an import when building a Windows DLL (.lib)"},
        },
        .{
            .name = "cache_root",
            .string = "--cache-dir",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Override the local cache directory"},
        },
        .{
            .name = "global_cache_root",
            .string = "--global-cache-dir",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Override the global cache directory"},
        },
        .{
            .name = "zig_lib_root",
            .string = "--zig-lib-dir",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Override Zig installation lib directory"},
        },
        .{
            .name = "listen",
            .string = "--listen",
            .tag = .{ .optional_field = .tag },
            .type = listen_type,
            .descr = &.{"[MISSING]"},
        },
        .{
            .name = "target",
            .string = "-target",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"<arch><sub>-<os>-<abi> see the targets command"},
        },
        .{
            .name = "cpu",
            .string = "-mcpu",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Specify target CPU and feature set"},
        },
        .{
            .name = "code_model",
            .string = "-mcmodel",
            .tag = .{ .optional_field = .tag },
            .type = code_model_type,
            .descr = &.{"Limit range of code and data virtual addresses"},
        },
        .{
            .name = "red_zone",
            .string = "-mred-zone",
            .and_no = .{ .string = "-mno-red-zone" },
            .descr = &.{"Enable the \"red-zone\""},
        },
        .{
            .name = "implicit_builtins",
            .string = "-fbuiltin",
            .and_no = .{ .string = "-fno-builtin" },
            .descr = &.{"Enable implicit builtin knowledge of functions"},
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
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"(WASI) Execution model"},
        },
        .{
            .name = "name",
            .string = "--name",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Override root name"},
        },
        .{
            .name = "soname",
            .string = "-fsoname",
            .tag = .{ .field = .string },
            .type = string_type,
            .and_no = .{ .string = "-fno-soname" },
            .descr = &.{"Override the default SONAME value"},
        },
        .{
            .name = "mode",
            .string = "-O",
            .tag = .{ .optional_field = .tag },
            .type = optimize_type,
            .descr = &.{
                "Choose what to optimize for:",
                "  Debug          Optimizations off, safety on",
                "  ReleaseSafe    Optimizations on, safety on",
                "  ReleaseFast    Optimizations on, safety off",
                "  ReleaseSmall   Size optimizations on, safety off",
            },
            .flags = .{ .do_parse = true },
        },
        .{
            .name = "passes",
            .string = "-fopt-bisect-limit",
            .tag = .{ .optional_field = .integer },
            .char = '=',
            .type = optional_integer_type,
            .descr = &.{"Only run [limit] first LLVM optimization passes"},
        },
        .{
            .name = "main_pkg_path",
            .string = "--main-pkg-path",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
            .string = "-fstack-protector",
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
            .descr = &.{"Places each function in a separate section"},
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
            .char = '=',
            .tag = .{ .optional_field = .tag },
            .type = output_format_type,
            .descr = &.{
                "Override target object format:",
                "  elf                    Executable and Linking Format",
                "  c                      C source code",
                "  wasm                   WebAssembly",
                "  coff                   Common Object File Format (Windows)",
                "  macho                  macOS relocatables",
                "  spirv                  Standard, Portable Intermediate Representation V (SPIR-V)",
                "  plan9                  Plan 9 from Bell Labs object format",
                "  hex (planned feature)  Intel IHEX",
                "  raw (planned feature)  Dump machine code directly",
            },
        },
        .{
            .name = "dirafter",
            .string = "-idirafter",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Add directory to AFTER include search path"},
        },
        .{
            .name = "system",
            .string = "-isystem",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Add directory to SYSTEM include search path"},
        },
        .{
            .name = "libc",
            .string = "--libc",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Provide a file which specifies libc paths"},
        },
        .{
            .name = "library",
            .string = "--library",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Link against system library (only if actually used)"},
        },
        .{
            .name = "include",
            .string = "-I",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .descr = &.{"Add directories to include search path"},
        },
        .{
            .name = "needed_library",
            .string = "--needed-library",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .descr = &.{"Link against system library (even if unused)"},
        },
        .{
            .name = "library_directory",
            .string = "--library-directory",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .descr = &.{"Add a directory to the library search path"},
        },
        .{
            .name = "link_script",
            .string = "--script",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Use a custom linker script"},
        },
        .{
            .name = "version_script",
            .string = "--version-script",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Provide a version .map file"},
        },
        .{
            .name = "dynamic_linker",
            .string = "--dynamic-linker",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Set the dynamic interpreter path"},
        },
        .{
            .name = "sysroot",
            .string = "--sysroot",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Set the system root directory"},
        },
        .{
            .name = "entry",
            .string = "--entry",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
            .string = "--build-id",
            .tag = .{ .optional_field = .tag },
            .char = '=',
            .type = build_id_type,
            .descr = &.{"Help coordinate stripped binaries with debug symbols"},
        },
        .{
            .name = "eh_frame_hdr",
            .string = "--eh-frame-hdr",
            .descr = &.{"Enable C++ exception handling by passing --eh-frame-hdr to linker"},
        },
        .{
            .name = "emit_relocs",
            .string = "--emit-relocs",
            .descr = &.{"Enable output of relocation sections for post build tools"},
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
            .tag = .{ .optional_field = .integer },
            .type = optional_integer_type,
            .descr = &.{"Override default stack size"},
        },
        .{
            .name = "image_base",
            .string = "--image-base",
            .tag = .{ .optional_field = .integer },
            .type = optional_integer_type,
            .descr = &.{"Set base address for executable image"},
        },
        .{
            .name = "macros",
            .tag = .{ .optional_field = .repeatable_formatter },
            .type = optional_macro_slice_type,
            .descr = &.{"Define C macros available within the `@cImport` namespace"},
            .string = "-D",
        },
        .{
            .name = "modules",
            .tag = .{ .optional_field = .repeatable_formatter },
            .type = optional_module_slice_type,
            .descr = &.{"Define modules available as dependencies for the current target"},
            .string = "--mod",
        },
        .{
            .name = "dependencies",
            .string = "--deps",
            .tag = .{ .optional_field = .mapped },
            .type = optional_dependencies_slice_type,
            .descr = &.{"Define module dependencies for the current target"},
        },
        .{
            .name = "cflags",
            .string = "-cflags",
            .tag = .{ .optional_field = .mapped },
            .type = flags_type,
            .descr = &.{"Set extra flags for the next position C source files"},
        },
        .{
            .name = "rcflags",
            .string = "-rcflags",
            .tag = .{ .optional_field = .mapped },
            .type = flags_type,
            .descr = &.{"Set extra flags for the next positional .rc source files"},
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
            .name = "link_flags",
            .string = "-z",
            .tag = .{ .optional_field = .repeatable_tag },
            .type = link_flags_type,
            .descr = &.{
                "Set linker extension flags:",
                "  nodelete                   Indicate that the object cannot be deleted from a process",
                "  notext                     Permit read-only relocations in read-only segments",
                "  defs                       Force a fatal error if any undefined symbols remain",
                "  undefs                     Reverse of -z defs",
                "  origin                     Indicate that the object must have its origin processed",
                "  nocopyreloc                Disable the creation of copy relocations",
                "  now (default)              Force all relocations to be processed on load",
                "  lazy                       Don't force all relocations to be processed on load",
                "  relro (default)            Force all relocations to be read-only after processing",
                "  norelro                    Don't force all relocations to be read-only after processing",
                "  common-page-size=[bytes]   Set the common page size for ELF binaries",
                "  max-page-size=[bytes]      Set the max page size for ELF binaries",
            },
            .flags = .{ .do_parse = false },
        },
        .{
            .name = "files",
            .tag = .{ .param = .repeatable_formatter },
            .type = paths_type,
            .descr = &.{"Add auxiliary files to the current target"},
        },
        // Other options
        .{
            .name = "color",
            .string = "--color",
            .tag = .{ .optional_field = .tag },
            .type = auto_on_off_type,
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
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
const Format = enum {
    default,
    gnu,
    darwin,
    bsd,
    bigarchive,
};
const Operation = enum {
    d,
    m,
    q,
    r,
    s,
    x,
};

const archive_format_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?Format),
    .parse = &types.ProtoTypeDescr.init(Format),
};
const archive_operation_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(Operation),
};
pub const zig_ar_command_attributes: types.Attributes = .{
    .type_name = "ArchiveCommand",
    .fn_name = "archive",
    .params = &.{
        .{
            .name = "zig_exe",
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .string = "ar",
            .tag = .{ .literal = .string },
        },
        .{
            .name = "format",
            .string = "--format",
            .tag = .{ .optional_field = .tag },
            .type = archive_format_type,
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
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
            .char = types.ParamSpec.immediate,
            .descr = &.{"Put [files] after [relpos]"},
        },
        .{
            .name = "before",
            .string = "b",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Put [files] before [relpos] (same as [i])"},
        },
        .{
            .name = "create",
            .string = "c",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Do not warn if archive had to be created"},
        },
        .{
            .name = "zero_ids",
            .string = "D",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Use zero for timestamps and uids/gids (default)"},
        },
        .{
            .name = "real_ids",
            .string = "U",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Use actual timestamps and uids/gids"},
        },
        .{
            .name = "append",
            .string = "L",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Add archive's contents"},
        },
        .{
            .name = "preserve_dates",
            .string = "o",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Preserve original dates"},
        },
        .{
            .name = "index",
            .string = "s",
            .char = types.ParamSpec.immediate,
            .descr = &.{"Create an archive index (cf. ranlib)"},
        },
        .{
            .name = "no_symbol_table",
            .string = "S",
            .char = types.ParamSpec.immediate,
            .descr = &.{"do not build a symbol table"},
        },
        .{
            .name = "update",
            .string = "u",
            .char = types.ParamSpec.immediate,
            .descr = &.{"update only [files] newer than archive contents"},
        },
        .{
            .name = "operation",
            .tag = .{ .field = .tag },
            .type = archive_operation_type,
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
            .name = "files",
            .tag = .{ .param = .repeatable_formatter },
            .type = paths_type,
            .descr = &.{"Add auxiliary files to the current target"},
        },
    },
};
pub const zig_fetch_command_attributes: types.Attributes = .{
    .type_name = "FetchCommand",
    .fn_name = "fetch",
    .type_fn_name = "GenericBuildCommand",
    .params = &.{
        .{
            .name = "zig_exe",
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .string = "fetch",
            .tag = .{ .literal = .string },
            .char = types.ParamSpec.immediate,
        },
        .{
            .name = "global_cache_root",
            .string = "--global-cache-dir",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Override the global cache directory"},
        },
    },
};

pub const zig_format_command_attributes: types.Attributes = .{
    .type_name = "FormatCommand",
    .fn_name = "format",
    .params = &.{
        .{
            .name = "zig_exe",
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .string = "fmt",
            .tag = .{ .literal = .string },
        },
        .{
            .name = "color",
            .string = "--color",
            .tag = .{ .optional_field = .tag },
            .type = auto_on_off_type,
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
            .descr = &.{"Run zig ast-check on every file"},
        },
        .{
            .name = "exclude",
            .string = "--exclude",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Exclude file or directory from formatting"},
        },
        .{
            .name = "pathname",
            .tag = .{ .param = .formatter },
            .type = .{ .store = &.{ .type_decl = .{ .name = "types.Path" } } },
            .descr = &.{"File system target for formatting operation. May be a file or a directory."},
        },
    },
};

pub const zig_objcopy_command_attributes: types.Attributes = .{
    .type_name = "ObjcopyCommand",
    .fn_name = "objcopy",
    .params = &.{
        .{
            .name = "zig_exe",
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .string = "objcopy",
            .tag = .{ .literal = .string },
        },
        .{
            .name = "output_target",
            .tag = .{ .optional_field = .string },
            .string = "--output-target",
            .type = optional_string_type,
        },
        .{
            .name = "only_section",
            .tag = .{ .optional_field = .string },
            .string = "--only-section",
            .type = optional_string_type,
        },
        .{
            .name = "pad_to",
            .string = "--pad-to",
            .tag = .{ .optional_field = .integer },
            .type = optional_integer_type,
        },
        .{
            .name = "strip_debug",
            .string = "--strip-debug",
        },
        .{
            .name = "strip_all",
            .string = "--strip-all",
        },
        .{
            .name = "debug_only",
            .string = "--only-keep-debug",
        },
        .{
            .name = "add_gnu_debuglink",
            .tag = .{ .optional_field = .string },
            .string = "--add-gnu-debuglink",
            .type = optional_string_type,
        },
        .{
            .name = "extract_to",
            .tag = .{ .optional_field = .string },
            .string = "--extract-to",
            .type = optional_string_type,
        },
        .{
            .name = "path",
            .tag = .{ .param = .formatter },
            .type = .{ .store = &.{ .type_decl = .{ .name = "types.Path" } } },
            .descr = &.{"Target binary"},
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
            .tag = .{ .optional_field = .tag },
            .type = auto_on_off_type,
            .descr = &.{"Use colors in output (default=autodetect)"},
        },
        .{
            .name = "macros",
            .tag = .{ .optional_field = .mapped },
            .type = optional_macro_slice_type,
            .descr = &.{"Define macros"},
        },
        .{
            .name = "include",
            .string = "-I",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .char = types.ParamSpec.immediate,
            .descr = &.{"Add directories to include search path"},
        },
        .{
            .name = "dependencies",
            .string = "-d",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
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
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
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
            .tag = .{ .param = .string },
            .type = string_type,
        },
        .{
            .name = "arch",
            .string = "-a",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
        },
        .{
            .name = "defs",
            .tag = .{ .optional_field = .mapped },
            .type = optional_macro_slice_type,
            .descr = &.{"Define identifiers"},
        },
        .{
            .name = "output",
            .string = "-o",
            .tag = .{ .optional_field = .string },
            .type = optional_string_type,
            .descr = &.{"Output file"},
        },
        .{
            .name = "tags",
            .string = "-T",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .char = types.ParamSpec.immediate,
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
const O = enum {
    @"0",
    @"1",
    @"2",
    @"3",
};
const llc_optimize_type: types.ProtoTypeDescrMap = .{
    .store = &types.ProtoTypeDescr.init(?O),
    .parse = &types.ProtoTypeDescr.init(O),
};

pub const llvm_llc_command_attributes: types.Attributes = .{
    .type_name = "LLCCommand",
    .fn_name = "llc",
    .params = &.{
        .{
            .name = "color",
            .string = "--color",
            .descr = &.{"Use colors in output (default=autodetect)"},
        },
        .{
            .name = "include",
            .string = "-I",
            .tag = .{ .optional_field = .repeatable_string },
            .type = optional_repeatable_string_type,
            .descr = &.{"Add directories to include search path"},
        },
        .{
            .name = "optimize",
            .string = "-O",
            .tag = .{ .optional_field = .tag },
            .type = llc_optimize_type,
            .descr = &.{"Optimization level. [-O0, -O1, -O2, or -O3] (default='-O2')"},
        },
        .{
            .name = "emit_addrsig",
            .string = "--addrsig",
            .descr = &.{"Emit an address-significance table"},
        },
        .{
            .name = "align_loops",
            .string = "--align-loops",
            .tag = .{ .optional_field = .integer },
            .type = optional_integer_type,
            .descr = &.{"Default alignment for loops"},
        },
        .{
            .name = "aarch64_use_aa",
            .string = "--aarch64-use-aa",
            .descr = &.{"Enable the use of AA during codegen."},
        },
        .{
            .name = "abort_on_max_devirt_iterations_reached",
            .string = "--abort-on-max-devirt-iterations-reached",
            .descr = &.{"Abort when the max iterations for devirtualization CGSCC repeat pass is reached"},
        },
        .{
            .name = "allow_ginsert_as_artifact",
            .string = "--allow-ginsert-as-artifact",
            .descr = &.{"Allow G_INSERT to be considered an artifact. Hack around AMDGPU test infinite loops."},
        },

        //General options:
        //
        //  --aarch64-neon-syntax=<value>                                         - Choose style of NEON code to emit from AArch64 backend:
        //    =generic                                                            -   Emit generic NEON assembly
        //    =apple                                                              -   Emit Apple-style NEON assembly

        .{
            .name = "amdgpu_bypass_slow_div",
            .string = "--amdgpu-bypass-slow-div",
            .descr = &.{"Skip 64-bit divide for dynamic 32-bit values"},
        },
        .{
            .name = "amdgpu_disable_loop_alignment",
            .string = "--amdgpu-disable-loop-alignment",
            .descr = &.{"Do not align and prefetch loops"},
        },
        .{
            .name = "amdgpu_dpp_combine",
            .string = "--amdgpu-dpp-combine",
            .descr = &.{"Enable DPP combiner"},
        },
        .{
            .name = "amdgpu_dump_hsa_metadata",
            .string = "--amdgpu-dump-hsa-metadata",
            .descr = &.{"Dump AMDGPU HSA Metadata"},
        },
        .{
            .name = "amdgpu_enable_merge_m0",
            .string = "--amdgpu-enable-merge-m0",
            .descr = &.{"Merge and hoist M0 initializations"},
        },
        .{
            .name = "amdgpu_enable_power_sched",
            .string = "--amdgpu-enable-power-sched",
            .descr = &.{"Enable scheduling to minimize mAI power bursts"},
        },

        //  --amdgpu-promote-alloca-to-vector-limit=<uint>                        - Maximum byte size to consider promote alloca to vector

        .{
            .name = "amdgpu_sdwa_peephole",
            .string = "--amdgpu-sdwa-peephole",
            .descr = &.{"Enable SDWA peepholer"},
        },
        .{
            .name = "amdgpu_use_aa_in_codegen",
            .string = "--amdgpu-use-aa-in-codegen",
            .descr = &.{"Enable the use of AA during codegen."},
        },
        .{
            .name = "amdgpu_verify_hsa_metadata",
            .string = "--amdgpu-verify-hsa-metadata",
            .descr = &.{"Verify AMDGPU HSA Metadata"},
        },
        .{
            .name = "amdgpu_vgpr_index_mode",
            .string = "--amdgpu-vgpr-index-mode",
            .descr = &.{"Use GPR indexing mode instead of movrel for vector indexing"},
        },
        //  --arm-add-build-attributes                                            -
        //  --arm-implicit-it=<value>                                             - Allow conditional instructions outdside of an IT block
        //    =always                                                             -   Accept in both ISAs, emit implicit ITs in Thumb
        //    =never                                                              -   Warn in ARM, reject in Thumb
        //    =arm                                                                -   Accept in ARM, reject in Thumb
        //    =thumb                                                              -   Warn in ARM, emit implicit ITs in Thumb

        .{
            .name = "asm_show_inst",
            .string = "--asm-show-inst",
            .descr = &.{"Emit internal instruction representation to assembly file"},
        },
        .{
            .name = "asm_verbose",
            .string = "--asm-verbose",
            .descr = &.{"Add comments to directives."},
        },
        .{
            .name = "atomic_counter_update_promoted",
            .string = "--atomic-counter-update-promoted",
            .descr = &.{"Do counter update using atomic fetch add  for promoted counters only"},
        },
        .{
            .name = "atomic_first_counter",
            .string = "--atomic-first-counter",
            .descr = &.{"Use atomic fetch add for first counter in a function (usually the entry counter)"},
        },
        .{
            .name = "bounds_checking_single_trap",
            .string = "--bounds-checking-single-trap",
            .descr = &.{"Use one trap block per function"},
        },

        //  --basic-block-sections=<all | <function list (file)> | labels | none> - Emit basic blocks into separate sections
        //  --cfg-hide-cold-paths=<number>                                        - Hide blocks with relative frequency below the given value

        //  --cfg-hide-deoptimize-paths                                           -
        //  --cfg-hide-unreachable-paths                                          -

        //  --code-model=<value>                                                  - Choose code model
        //    =tiny                                                               -   Tiny code model
        //    =small                                                              -   Small code model
        //    =kernel                                                             -   Kernel code model
        //    =medium                                                             -   Medium code model
        //    =large                                                              -   Large code model

        //  --cost-kind=<value>                                                   - Target cost kind
        //    =throughput                                                         -   Reciprocal throughput
        //    =latency                                                            -   Instruction latency
        //    =code-size                                                          -   Code size
        //    =size-latency                                                       -   Code size and latency
        .{
            .name = "cs_profile_generate",
            .string = "--cs-profile-generate",
            .descr = &.{"Perform context sensitive PGO instrumentation"},
        },
        //  --cs-profile-path=<string>                                            - Context sensitive profile file path
        .{
            .name = "data_sections",
            .string = "--data-sections",
            .descr = &.{"Emit data into separate sections"},
        },
        .{
            .name = "debug_entry_values",
            .string = "--debug-entry-values",
            .descr = &.{"Enable debug info for the debug entry values."},
        },
        .{
            .name = "debug_info_correlate",
            .string = "--debug-info-correlate",
            .descr = &.{"Use debug info to correlate profiles."},
        },
        //  --debugger-tune=<value>                                               - Tune debug info for a particular debugger
        //    =gdb                                                                -   gdb
        //    =lldb                                                               -   lldb
        //    =dbx                                                                -   dbx
        //    =sce                                                                -   SCE targets (e.g. PS4)
        //  --debugify-func-limit=<ulong>                                         - Set max number of processed functions per pass.
        //  --debugify-level=<value>                                              - Kind of debug info to add
        //    =locations                                                          -   Locations only
        //    =location+variables                                                 -   Locations and Variables
        .{
            .name = "debugify_quiet",
            .string = "--debugify-quiet",
            .descr = &.{"Suppress verbose debugify output"},
        },
        //  --denormal-fp-math=<value>                                            - Select which denormal numbers the code is permitted to require
        //    =ieee                                                               -   IEEE 754 denormal numbers
        //    =preserve-sign                                                      -   the sign of a  flushed-to-zero number is preserved in the sign of 0
        //    =positive-zero                                                      -   denormals are flushed to positive zero
        //  --denormal-fp-math-f32=<value>                                        - Select which denormal numbers the code is permitted to require for float
        //    =ieee                                                               -   IEEE 754 denormal numbers
        //    =preserve-sign                                                      -   the sign of a  flushed-to-zero number is preserved in the sign of 0
        //    =positive-zero                                                      -   denormals are flushed to positive zero
        //  --disable-i2p-p2i-opt                                                 - Disables inttoptr/ptrtoint roundtrip optimization
        .{
            .name = "disable_promote_alloca_to_lds",
            .string = "--disable-promote-alloca-to-lds",
            .descr = &.{"Disable promote alloca to LDS"},
        },
        .{
            .name = "disable_promote_alloca_to_vector",
            .string = "--disable-promote-alloca-to-vector",
            .descr = &.{"Disable promote alloca to vector"},
        },
        .{
            .name = "disable_simplify_libcalls",
            .string = "--disable-simplify-libcalls",
            .descr = &.{"Disable simplify-libcalls"},
        },
        .{
            .name = "disable_tail_calls",
            .string = "--disable-tail-calls",
            .descr = &.{"Never emit tail calls"},
        },
        .{
            .name = "do_counter_promotion",
            .string = "--do-counter-promotion",
            .descr = &.{"Do counter register promotion"},
        },
        //  --dot-cfg-mssa=<file name for generated dot file>                     - file name for generated dot file
        //  --dwarf-version=<int>                                                 - Dwarf version
        .{
            .name = "dwarf64",
            .string = "--dwarf64",
            .descr = &.{"Generate debugging info in the 64-bit DWARF format"},
        },
        .{
            .name = "emit_call_site_info",
            .string = "--emit-call-site-info",
            .descr = &.{"Emit call site debug information, if debug information is enabled."},
        },
        //  --emit-dwarf-unwind=<value>                                           - Whether to emit DWARF EH frame entries.
        //    =always                                                             -   Always emit EH frame entries
        //    =no-compact-unwind                                                  -   Only emit EH frame entries when compact unwind is not available
        //    =default                                                            -   Use target platform default
        //  --emscripten-cxx-exceptions-allowed=<string>                          - The list of function names in which Emscripten-style exception handling is enabled (see emscripten EMSCRIPTEN_CATCHING_ALLOWED options)
        .{
            .name = "emulated_tls",
            .string = "--emulated-tls",
            .descr = &.{"Use emulated TLS model"},
        },
        .{
            .name = "enable_approx_func_fp_math",
            .string = "--enable-approx-func-fp-math",
            .descr = &.{"Enable FP math optimizations that assume approx func"},
        },
        .{
            .name = "enable_cse_in_irtranslator",
            .string = "--enable-cse-in-irtranslator",
            .descr = &.{"Should enable CSE in irtranslator"},
        },
        .{
            .name = "enable_cse_in_legalizer",
            .string = "--enable-cse-in-legalizer",
            .descr = &.{"Should enable CSE in Legalizer"},
        },
        .{
            .name = "enable_emscripten_cxx_exceptions",
            .string = "--enable-emscripten-cxx-exceptions",
            .descr = &.{"WebAssembly Emscripten-style exception handling"},
        },
        .{
            .name = "enable_emscripten_sjlj",
            .string = "--enable-emscripten-sjlj",
            .descr = &.{"WebAssembly Emscripten-style setjmp/longjmp handling"},
        },
        .{
            .name = "enable_gvn_hoist",
            .string = "--enable-gvn-hoist",
            .descr = &.{"Enable the GVN hoisting pass (default = off)"},
        },
        //  --enable-gvn-memdep                                                   -
        .{
            .name = "enable_gvn_sink",
            .string = "--enable-gvn-sink",
            .descr = &.{"Enable the GVN sinking pass (default = off)"},
        },
        .{
            .name = "enable_jmc_instrument",
            .string = "--enable-jmc-instrument",
            .descr = &.{"Instrument functions with a call to __CheckForDebuggerJustMyCode"},
        },
        //  --enable-load-in-loop-pre                                             -
        //  --enable-load-pre                                                     -
        //  --enable-loop-simplifycfg-term-folding                                -
        .{
            .name = "enable_name_compression",
            .string = "--enable-name-compression",
            .descr = &.{"Enable name/filename string compression"},
        },
        .{
            .name = "enable_no_infs_fp_math",
            .string = "--enable-no-infs-fp-math",
            .descr = &.{"Enable FP math optimizations that assume no +-Infs"},
        },
        .{
            .name = "enable_no_nans_fp_math",
            .string = "--enable-no-nans-fp-math",
            .descr = &.{"Enable FP math optimizations that assume no NaNs"},
        },
        .{
            .name = "enable_no_signed_zeros_fp_math",
            .string = "--enable-no-signed-zeros-fp-math",
            .descr = &.{"Enable FP math optimizations that assume the sign of 0 is insignificant"},
        },
        .{
            .name = "enable_no_trapping_fp_math",
            .string = "--enable-no-trapping-fp-math",
            .descr = &.{"Enable setting the FP exceptions build attribute not to use exceptions"},
        },
        .{
            .name = "enable_split_backedge_in_load_pre",
            .string = "--enable-unsafe-fp-math",
            .descr = &.{"[MISSING]"},
        },
        .{
            .name = "enable_unsafe_fp_math",
            .string = "--enable-unsafe-fp-math",
            .descr = &.{"Enable optimizations that may decrease FP precision"},
        },
        //  --exception-model=<value>                                             - exception model
        //    =default                                                            -   default exception handling model
        //    =dwarf                                                              -   DWARF-like CFI based exception handling
        //    =sjlj                                                               -   SjLj exception handling
        //    =arm                                                                -   ARM EHABI exceptions
        //    =wineh                                                              -   Windows exception model
        //    =wasm                                                               -   WebAssembly exception handling
        .{
            .name = "experimental_debug_variable_locations",
            .string = "--experimental-debug-variable-locations",
            .descr = &.{"Use experimental new value-tracking variable locations"},
        },
        .{
            .name = "fatal_warnings",
            .string = "--fatal-warnings",
            .descr = &.{"Treat warnings as errors"},
        },
        //  --filetype=<value>                                                    - Choose a file type (not all types are supported by all targets):
        //    =asm                                                                -   Emit an assembly ('.s') file
        //    =obj                                                                -   Emit a native object ('.o') file
        //    =null                                                               -   Emit nothing, for performance testing
        //  --float-abi=<value>                                                   - Choose float ABI type
        //    =default                                                            -   Target default float ABI type
        //    =soft                                                               -   Soft float ABI (implied by -soft-float)
        //    =hard                                                               -   Hard float ABI (uses FP registers)
        .{
            .name = "force_dwarf_frame_section",
            .string = "--force-dwarf-frame-section",
            .descr = &.{"Always emit a debug frame section."},
        },
        //  --fp-contract=<value>                                                 - Enable aggressive formation of fused FP ops
        //    =fast                                                               -   Fuse FP ops whenever profitable
        //    =on                                                                 -   Only fuse 'blessed' FP ops.
        //    =off                                                                -   Only fuse FP ops when the result won't be affected.
        //  --frame-pointer=<value>                                               - Specify frame pointer elimination optimization
        //    =all                                                                -   Disable frame pointer elimination
        //    =non-leaf                                                           -   Disable frame pointer elimination for non-leaf frame
        //    =none                                                               -   Enable frame pointer elimination
        //  --fs-profile-debug-bw-threshold=<uint>                                - Only show debug message if the source branch weight is greater  than this value.
        //  --fs-profile-debug-prob-diff-threshold=<uint>                         - Only show debug message if the branch probility is greater than this value (in percentage).
        .{
            .name = "function_sections",
            .string = "--function-sections",
            .descr = &.{"Emit functions into separate sections"},
        },
        .{
            .name = "generate_merged_base_profiles",
            .string = "--generate-merged-base-profiles",
            .descr = &.{"When generating nested context-sensitive profiles, always generate extra base profile for function with all its context profiles merged into it."},
        },
        //  --gpsize=<uint>                                                       - Global Pointer Addressing Size.  The default size is 8.
        .{
            .name = "hash_based_counter_split",
            .string = "--hash-based-counter-split",
            .descr = &.{"Rename counter variable of a comdat function based on cfg hash"},
        },
        .{
            .name = "hot_cold_split",
            .string = "--hot-cold-split",
            .descr = &.{"Enable hot-cold splitting pass"},
        },
        .{
            .name = "ignore_xcoff_visibility",
            .string = "--ignore-xcoff-visibility",
            .descr = &.{"Not emit the visibility attribute for asm in AIX OS or give all symbols 'unspecified' visibility in XCOFF object file"},
        },
        .{
            .name = "import_all_index",
            .string = "--import-all-index",
            .descr = &.{"Import all external functions in index."},
        },
        .{
            .name = "incremental_linker_compatible",
            .string = "--incremental-linker-compatible",
            .descr = &.{"When used with filetype=obj, emit an object file which can be used with an incremental linker"},
        },
        .{
            .name = "instcombine_code_sinking",
            .string = "--instcombine-code-sinking",
            .descr = &.{"Enable code sinking"},
        },
        //  --instcombine-guard-widening-window=<uint>                            - How wide an instruction window to bypass looking for another guard
        //  --instcombine-max-iterations=<uint>                                   - Limit the maximum number of instruction combining iterations
        //  --instcombine-max-num-phis=<uint>                                     - Maximum number phis to handle in intptr/ptrint folding
        //  --instcombine-max-sink-users=<uint>                                   - Maximum number of undroppable users for instruction sinking
        //  --instcombine-maxarray-size=<uint>                                    - Maximum array size considered when doing a combine
        .{
            .name = "instcombine_negator_enabled",
            .string = "--instcombine-negator-enabled",
            .descr = &.{"Should we attempt to sink negations?"},
        },
        //  --instcombine-negator-max-depth=<uint>                                - What is the maximal lookup depth when trying to check for viability of negation sinking.
        .{
            .name = "instrprof_atomic_counter_update_all",
            .string = "--instrprof-atomic-counter-update-all",
            .descr = &.{"Make all profile counter updates atomic (for testing only)"},
        },
        //  --internalize-public-api-file=<filename>                              - A file containing list of symbol names to preserve
        //  --internalize-public-api-list=<list>                                  - A list of symbol names to preserve
        //  --iterative-counter-promotion                                         - Allow counter promotion across the whole loop nest.
        //  --load=<pluginfilename>                                               - Load the specified plugin
        //  --lower-global-dtors-via-cxa-atexit                                   - Lower llvm.global_dtors (global destructors) via __cxa_atexit
        //  --lto-aix-system-assembler=<path>                                     - Path to a system assembler, picked up on AIX only
        //  --lto-embed-bitcode=<value>                                           - Embed LLVM bitcode in object files produced by LTO
        //    =none                                                               -   Do not embed
        //    =optimized                                                          -   Embed after all optimization passes
        //    =post-merge-pre-opt                                                 -   Embed post merge, but before optimizations
        //  --lto-pass-remarks-filter=<regex>                                     - Only record optimization remarks from passes whose names match the given regular expression
        //  --lto-pass-remarks-format=<format>                                    - The format used for serializing remarks (default: YAML)
        //  --lto-pass-remarks-output=<filename>                                  - Output filename for pass remarks
        //  --march=<string>                                                      - Architecture to generate code for (see --version)
        //  --matrix-default-layout=<value>                                       - Sets the default matrix layout
        //    =column-major                                                       -   Use column-major layout
        //    =row-major                                                          -   Use row-major layout
        //  --matrix-print-after-transpose-opt                                    -
        //  --mattr=<a1,+a2,-a3,...>                                              - Target specific attributes (-mattr=help for details)
        //  --max-counter-promotions=<int>                                        - Max number of allowed counter promotions
        //  --max-counter-promotions-per-loop=<uint>                              - Max number counter promotions per loop to avoid increasing register pressure too much
        //  --mc-relax-all                                                        - When used with filetype=obj, relax all fixups in the emitted object file
        //  --mcabac                                                              - tbd
        //  --mcpu=<cpu-name>                                                     - Target a specific cpu type (-mcpu=help for details)
        //  --meabi=<value>                                                       - Set EABI type (default depends on triple):
        //    =default                                                            -   Triple default EABI version
        //    =4                                                                  -   EABI version 4
        //    =5                                                                  -   EABI version 5
        //    =gnu                                                                -   EABI GNU
        //  --merror-missing-parenthesis                                          - Error for missing parenthesis around predicate registers
        //  --merror-noncontigious-register                                       - Error for register names that aren't contigious
        //  --mhvx                                                                - Enable Hexagon Vector eXtensions
        //  --mhvx=<value>                                                        - Enable Hexagon Vector eXtensions
        //    =v60                                                                -   Build for HVX v60
        //    =v62                                                                -   Build for HVX v62
        //    =v65                                                                -   Build for HVX v65
        //    =v66                                                                -   Build for HVX v66
        //    =v67                                                                -   Build for HVX v67
        //    =v68                                                                -   Build for HVX v68
        //    =v69                                                                -   Build for HVX v69
        //    =v71                                                                -   Build for HVX v71
        //    =v73                                                                -   Build for HVX v73
        //  --mips-compact-branches=<value>                                       - MIPS Specific: Compact branch policy.
        //    =never                                                              -   Do not use compact branches if possible.
        //    =optimal                                                            -   Use compact branches where appropriate (default).
        //    =always                                                             -   Always use compact branches if possible.
        .{
            .name = "mips16_constant_islands",
            .string = "--mips16-constant-islands",
            .descr = &.{"Enable mips16 constant islands."},
        },
        .{
            .name = "mips16_hard_float",
            .string = "--mips16-hard-float",
            .descr = &.{"Enable mips16 hard float."},
        },
        .{
            .name = "mir_strip_debugify_only",
            .string = "--mir-strip-debugify-only",
            .descr = &.{"Should mir-strip-debug only strip debug info from debugified modules by default"},
        },
        //  --misexpect-tolerance=<uint>                                          - Prevents emiting diagnostics when profile counts are within N% of the threshold..
        .{
            .name = "mno_compound",
            .string = "--mno-compound",
            .descr = &.{"Disable looking for compound instructions for Hexagon"},
        },
        .{
            .name = "mno_fixup",
            .string = "--mno-fixup",
            .descr = &.{"Disable fixing up resolved relocations for Hexagon"},
        },
        .{
            .name = "mno_ldc1_sdc1",
            .string = "--mno-ldc1-sdc1",
            .descr = &.{"Expand double precision loads and stores to their single precision counterparts"},
        },
        .{
            .name = "mno_pairing",
            .string = "--mno-pairing",
            .descr = &.{"Disable looking for duplex instructions for Hexagon"},
        },
        //  --mtriple=<string>                                                    - Override target triple for module
        .{
            .name = "mwarn_missing_parenthesis",
            .string = "--mwarn-missing-parenthesis",
            .descr = &.{"Warn for missing parenthesis around predicate registers"},
        },
        .{
            .name = "mwarn_noncontigious_register",
            .string = "--mwarn-noncontigious-register",
            .descr = &.{"Warn for register names that arent contigious"},
        },
        .{
            .name = "mwarn_sign_mismatch",
            .string = "--mwarn-sign-mismatch",
            .descr = &.{"Warn for mismatching a signed and unsigned value"},
        },
        .{
            .name = "no_deprecated_warn",
            .string = "--no-deprecated-warn",
            .descr = &.{"Suppress all deprecated warnings"},
        },
        .{
            .name = "no_discriminators",
            .string = "--no-discriminators",
            .descr = &.{"Disable generation of discriminator information."},
        },
        .{
            .name = "no_type_check",
            .string = "--no-type-check",
            .descr = &.{"Suppress type errors (Wasm)"},
        },
        .{
            .name = "no_warn",
            .string = "--no-warn",
            .descr = &.{"Suppress all warnings"},
        },
        .{
            .name = "no_xray_index",
            .string = "--no-xray-index",
            .descr = &.{"Don't emit xray_fn_idx section"},
        },
        .{
            .name = "nozero_initialized_in_bss",
            .string = "--nozero-initialized-in-bss",
            .descr = &.{"Don't place zero-initialized symbols into bss section"},
        },
        .{
            .name = "nvptx_sched4reg",
            .string = "--nvptx-sched4reg",
            .descr = &.{"NVPTX Specific: schedule for register pressue"},
        },
        //  -o <filename>                                                         - Output filename
        .{
            .name = "opaque_pointers",
            .string = "--opaque-pointers",
            .descr = &.{"Use opaque pointers"},
        },
        //  --pass-remarks-filter=<regex>                                         - Only record optimization remarks from passes whose names match the given regular expression
        //  --pass-remarks-format=<format>                                        - The format used for serializing remarks (default: YAML)
        //  --pass-remarks-output=<filename>                                      - Output filename for pass remarks
        .{
            .name = "poison_checking_function_local",
            .string = "--poison-checking-function-local",
            .descr = &.{"Check that returns are non-poison (for testing)"},
        },
        .{
            .name = "print_pipeline_passes",
            .string = "--print-pipeline-passes",
            .descr = &.{"Print a '-passes' compatible string describing the pipeline (best-effort only)."},
        },
        .{
            .name = "r600_ir_structurize",
            .string = "--r600-ir-structurize",
            .descr = &.{"Use StructurizeCFG IR pass"},
        },
        .{
            .name = "rdf_dump",
            .string = "--rdf-dump",
            .descr = &.{"-"},
        },
        //  --rdf-limit=<uint>                                                    -
        .{
            .name = "relax_elf_relocations",
            .string = "--relax-elf-relocations",
            .descr = &.{"Emit GOTPCRELX/REX_GOTPCRELX instead of GOTPCREL on x86-64 ELF"},
        },
        //enum {
        //    static,
        //    pic,
        //    dynamic_no_pic,
        //    ropi,
        //    rwpi,
        //    @"ropi-rwpi",
        //};
        //  --relocation-model=<value>                                            - Choose relocation model
        //    =static                                                             -   Non-relocatable code
        //    =pic                                                                -   Fully relocatable, position independent code
        //    =dynamic-no-pic                                                     -   Relocatable external references, non-relocatable code
        //    =ropi                                                               -   Code and read-only data relocatable, accessed PC-relative
        //    =rwpi                                                               -   Read-write data relocatable, accessed relative to static base
        //    =ropi-rwpi                                                          -   Combination of ropi and rwpi
        //  --run-pass=<pass-name>                                                - Run compiler only for specified passes (comma separated list)
        //  --runtime-counter-relocation                                          - Enable relocating counters at runtime.
        //  --safepoint-ir-verifier-print-only                                    -
        //  --sample-profile-check-record-coverage=<N>                            - Emit a warning if less than N% of records in the input profile are matched to the IR.
        //  --sample-profile-check-sample-coverage=<N>                            - Emit a warning if less than N% of samples in the input profile are matched to the IR.
        //  --sample-profile-max-propagate-iterations=<uint>                      - Maximum number of iterations to go through when propagating sample block/edge weights through the CFG.
        //  --skip-ret-exit-block                                                 - Suppress counter promotion if exit blocks contain ret.
        //  --speculative-counter-promotion-max-exiting=<uint>                    - The max number of exiting blocks of a loop to allow  speculative counter promotion
        //  --speculative-counter-promotion-to-loop                               - When the option is false, if the target block is in a loop, the promotion will be disallowed unless the promoted counter  update can be further/iteratively promoted into an acyclic  region.
        //  --split-dwarf-file=<string>                                           - Specify the name of the .dwo file to encode in the DWARF output
        //  --split-dwarf-output=<filename>                                       - .dwo output filename
        //  --split-machine-functions                                             - Split out cold basic blocks from machine functions based on profile information
        //  --stack-size-section                                                  - Emit a section containing stack size metadata
        //  --stack-symbol-ordering                                               - Order local stack symbols.
        //  --stackrealign                                                        - Force align the stack to the minimum alignment
        //  --strict-dwarf                                                        - use strict dwarf
        //  --summary-file=<string>                                               - The summary file to use for function importing.
        //  --sve-tail-folding=<string>                                           - Control the use of vectorisation using tail-folding for SVE:
        //                                                                          disabled    No loop types will vectorize using tail-folding
        //                                                                          default     Uses the default tail-folding settings for the target CPU
        //                                                                          all         All legal loop types will vectorize using tail-folding
        //                                                                          simple      Use tail-folding for simple loops (not reductions or recurrences)
        //                                                                          reductions  Use tail-folding for loops containing reductions
        //                                                                          recurrences Use tail-folding for loops containing fixed order recurrences
        //  --swift-async-fp=<value>                                              - Determine when the Swift async frame pointer should be set
        //    =auto                                                               -   Determine based on deployment target
        //    =always                                                             -   Always set the bit
        //    =never                                                              -   Never set the bit
        //  --tail-predication=<value>                                            - MVE tail-predication pass options
        //    =disabled                                                           -   Don't tail-predicate loops
        //    =enabled-no-reductions                                              -   Enable tail-predication, but not for reduction loops
        //    =enabled                                                            -   Enable tail-predication, including reduction loops
        //    =force-enabled-no-reductions                                        -   Enable tail-predication, but not for reduction loops, and force this which might be unsafe
        //    =force-enabled                                                      -   Enable tail-predication, including reduction loops, and force this which might be unsafe
        //  --tailcallopt                                                         - Turn fastcc calls into tail calls by (potentially) changing ABI.
        //  --thinlto-assume-merged                                               - Assume the input has already undergone ThinLTO function importing and the other pre-optimization pipeline changes.
        //  --thread-model=<value>                                                - Choose threading model
        //    =posix                                                              -   POSIX thread model
        //    =single                                                             -   Single thread model
        //  --threads=<int>                                                       -
        //  --time-trace                                                          - Record time trace
        //  --time-trace-file=<filename>                                          - Specify time trace file destination
        //  --tls-size=<uint>                                                     - Bit size of immediate TLS offsets
        //  --type-based-intrinsic-cost                                           - Calculate intrinsics cost based only on argument types
        //  --unique-basic-block-section-names                                    - Give unique names to every basic block section
        //  --unique-section-names                                                - Give unique names to every section
        //  --use-ctors                                                           - Use .ctors instead of .init_array.
        //  --vec-extabi                                                          - Enable the AIX Extended Altivec ABI.
        //  --verify-region-info                                                  - Verify region info (time consuming)
        //  --vp-counters-per-site=<number>                                       - The average number of profile counters allocated per value profiling site.
        //  --vp-static-alloc                                                     - Do static counter allocation for value profiler
        //  --wasm-enable-eh                                                      - WebAssembly exception handling
        //  --wasm-enable-sjlj                                                    - WebAssembly setjmp/longjmp handling
        //  -x <string>                                                           - Input language ('ir' or 'mir')
        //
        //  --x86-align-branch=<string>                                           - Specify types of branches to align (plus separated list of types):
        //                                                                          jcc      indicates conditional jumps
        //                                                                          fused    indicates fused conditional jumps
        //                                                                          jmp      indicates direct unconditional jumps
        //                                                                          call     indicates direct and indirect calls
        //                                                                          ret      indicates rets
        //                                                                          indirect indicates indirect unconditional jumps
        //
        //  --x86-align-branch-boundary=<uint>                                    - Control how the assembler should align branches with NOP. If the boundary's size is not 0, it should be a power of 2 and no less than 32. Branches will be aligned to prevent from being across or against the boundary of specified size. The default value 0 does not align branches.
        //  --x86-branches-within-32B-boundaries                                  - Align selected instructions to mitigate negative performance impact of Intel's micro code update for errata skx102.  May break assumptions about labels corresponding to particular instructions, and should be used with caution.
        //  --x86-pad-max-prefix-size=<uint>                                      - Maximum number of prefixes to use for padding
        //  --xcoff-traceback-table                                               - Emit the XCOFF traceback table
        //
        //Generic Options:
        //
        //  --help                                                                - Display available options (--help-hidden for more)
        //  --help-list                                                           - Display list of available options (--help-list-hidden for more)
        //  --version                                                             - Display the version of this program
    },
};

const NeonSyntax = enum { apple, generic };

pub const all: []const types.Attributes = &.{
    zig_build_command_attributes,
    zig_ar_command_attributes,
    zig_objcopy_command_attributes,
    harec_attributes,
    llvm_tblgen_command_attributes,
    llvm_llc_command_attributes,
    zig_fetch_command_attributes,
    zig_format_command_attributes,
};
