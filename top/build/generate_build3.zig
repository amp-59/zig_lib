const fmt = @import("../fmt.zig");
const mem = @import("../mem.zig");
const proc = @import("../proc.zig");
const file = @import("../file.zig");
const spec = @import("../spec.zig");
const testing = @import("../testing.zig");
const builtin = @import("../builtin.zig");
const types = @import("types.zig");
pub usingnamespace proc.start;
pub const runtime_assertions: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

const build_root: [:0]const u8 = builtin.buildRoot();
const tasks_path: [:0]const u8 = build_root ++ "/top/build/tasks3.zig";
const tasks_template_path: [:0]const u8 = build_root ++ "/top/build/tasks-template.zig";
const command_line_path: [:0]const u8 = build_root ++ "/top/build/command_line3.zig";
const command_line_template_path: [:0]const u8 = build_root ++ "/top/build/command_line-template.zig";

const Array = mem.StaticString(1024 * 1024);
const ProtoTypeDescr = fmt.GenericTypeDescrFormat(.{
    .options = .{ .default_field_values = true, .identifier_name = true },
    .tokens = .{ .lbrace = "{\n", .equal = "=", .rbrace = "}", .next = ",\n", .colon = ":", .indent = "" },
});
const Variant = enum(u1) {
    length,
    write,
};
const ArgInfo = struct {
    /// Describes how the argument should be written to the command line buffer
    tag: Tag,
    /// Describes how the field type should be written to the command struct
    type: ProtoTypeDescr,
    const Tag = enum(u8) {
        boolean = 0,
        string = 1,
        tag = 2,
        integer = 3,
        formatter = 4,
        mapped = 5,
        optional_boolean = 8,
        optional_string = 9,
        optional_tag = 10,
        optional_integer = 11,
        optional_formatter = 12,
        optional_mapped = 13,
    };
    fn isOptional(arg_info: ArgInfo) bool {
        return @enumToInt(arg_info.tag) > 5;
    }
    fn isBoolean(arg_info: ArgInfo) bool {
        return @enumToInt(arg_info.tag) == 0 or @enumToInt(arg_info.tag) == 8;
    }
    fn optionalTypeDescr(any: anytype) ProtoTypeDescr {
        if (@TypeOf(any) == type) {
            return optional(&ProtoTypeDescr.init(any));
        } else {
            return optional(&.{ .type_name = any });
        }
    }
    fn boolean() ArgInfo {
        return .{ .tag = .boolean, .type = ProtoTypeDescr.init(bool) };
    }
    fn string(comptime T: type) ArgInfo {
        return .{ .tag = .string, .type = ProtoTypeDescr.init(T) };
    }
    fn tag(comptime T: type) ArgInfo {
        return .{ .tag = .tag, .type = ProtoTypeDescr.init(T) };
    }
    fn integer(comptime T: type) ArgInfo {
        return .{ .tag = .integer, .type = ProtoTypeDescr.init(T) };
    }
    fn formatter(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .formatter, .type = .{ .type_name = type_name } };
    }
    fn mapped(comptime type_name: [:0]const u8) ArgInfo {
        return .{ .tag = .mapped, .type = .{ .type_name = type_name } };
    }
    fn optional(@"type": *const ProtoTypeDescr) ProtoTypeDescr {
        return .{ .type_refer = .{ .spec = "?", .type = @"type" } };
    }
    fn optional_boolean() ArgInfo {
        return .{ .tag = .optional_boolean, .type = optionalTypeDescr(bool) };
    }
    fn optional_string(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_string, .type = optionalTypeDescr(any) };
    }
    fn optional_tag(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_tag, .type = optionalTypeDescr(any) };
    }
    fn optional_integer(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_integer, .type = optionalTypeDescr(any) };
    }
    fn optional_formatter(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_formatter, .type = optionalTypeDescr(any) };
    }
    fn optional_mapped(comptime any: anytype) ArgInfo {
        return .{ .tag = .optional_mapped, .type = optionalTypeDescr(any) };
    }
};
const OptionSpec = struct {
    /// Command struct field name
    name: []const u8,
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = ArgInfo.boolean(),
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?InverseOptionSpec = null,
    /// Maybe define default value of this field. Should be false or null, but
    /// allow the exception.
    default_value: ?[]const u8 = null,
    /// Description to be inserted above the field as documentation comment
    descr: ?[]const []const u8 = null,
};
const InverseOptionSpec = struct {
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_info: ArgInfo = ArgInfo.boolean(),
};
const format_command_options: []const OptionSpec = &.{
    .{
        .name = "color",
        .string = "--color",
        .arg_info = ArgInfo.optional_tag(enum { auto, off, on }),
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
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Exclude file or directory from formatting"},
    },
};
pub const build_command_options: []const OptionSpec = &.{
    .{
        .name = "color",
        .string = "--color",
        .arg_info = ArgInfo.optional_tag(enum { on, off, auto }),
        .descr = &.{"Enable or disable colored error messages"},
    },
    .{
        .name = "emit_bin",
        .string = "-femit-bin",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-bin" },
        .descr = &.{"(default=yes) Output machine code"},
    },
    .{
        .name = "emit_asm",
        .string = "-femit-asm",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-asm" },
        .descr = &.{"(default=no) Output assembly code (.s)"},
    },
    .{
        .name = "emit_llvm_ir",
        .string = "-femit-llvm-ir",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-llvm-ir" },
        .descr = &.{"(default=no) Output optimized LLVM IR (.ll)"},
    },
    .{
        .name = "emit_llvm_bc",
        .string = "-femit-llvm-bc",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-llvm-bc" },
        .descr = &.{"(default=no) Output optimized LLVM BC (.bc)"},
    },
    .{
        .name = "emit_h",
        .string = "-femit-h",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-h" },
        .descr = &.{"(default=no) Output a C header file (.h)"},
    },
    .{
        .name = "emit_docs",
        .string = "-femit-docs",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-docs" },
        .descr = &.{"(default=no) Output documentation (.html)"},
    },
    .{
        .name = "emit_analysis",
        .string = "-femit-analysis",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-analysis" },
        .descr = &.{"(default=no) Output analysis (.json)"},
    },
    .{
        .name = "emit_implib",
        .string = "-femit-implib",
        .arg_info = ArgInfo.formatter("types.Path"),
        .and_no = .{ .string = "-fno-emit-implib" },
        .descr = &.{"(default=yes) Output an import when building a Windows DLL (.lib)"},
    },
    .{
        .name = "cache_root",
        .string = "--cache-dir",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Override the local cache directory"},
    },
    .{
        .name = "global_cache_root",
        .string = "--global-cache-dir",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Override the global cache directory"},
    },
    .{
        .name = "zig_lib_root",
        .string = "--zig-lib-dir",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Override Zig installation lib directory"},
    },
    .{
        .name = "listen",
        .string = "--listen",
        .arg_info = ArgInfo.optional_tag(enum { none, @"-", ipv4 }),
        .descr = &.{"[MISSING]"},
    },
    //.{
    //    .name = "enable_cache",
    //    .string = "--enable-cache",
    //    .default_value = &true,
    //},
    .{
        .name = "target",
        .string = "-target",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"<arch><sub>-<os>-<abi> see the targets command"},
    },
    .{
        .name = "cpu",
        .string = "-mcpu",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Specify target CPU and feature set"},
    },
    .{
        .name = "code_model",
        .string = "-mcmodel",
        .arg_info = ArgInfo.optional_tag(enum { default, tiny, small, kernel, medium, large }),
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
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"(WASI) Execution model"},
    },
    .{
        .name = "name",
        .string = "--name",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Override root name"},
    },
    .{
        .name = "soname",
        .string = "-fsoname",
        .arg_info = ArgInfo.string([]const u8),
        .and_no = .{ .string = "-fno-soname" },
        .descr = &.{"Override the default SONAME value"},
    },
    .{
        .name = "mode",
        .string = "-O",
        .arg_info = ArgInfo.optional_tag("builtin.Mode"),
        .descr = &.{
            "Choose what to optimize for:",
            "Debug          Optimizations off, safety on",
            "ReleaseSafe    Optimizations on, safety on",
            "ReleaseFast    Optimizations on, safety off",
            "ReleaseSmall   Size optimizations on, safety off",
        },
    },
    .{
        .name = "main_pkg_path",
        .string = "--main-pkg-path",
        .arg_info = ArgInfo.optional_string([]const u8),
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
        .name = "fmt",
        .string = "-ofmt",
        .arg_info = ArgInfo.optional_tag(enum { elf, c, wasm, coff, macho, spirv, plan9, hex, raw }),
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
        .string = "-dirafter",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to AFTER include search path"},
    },
    .{
        .name = "system",
        .string = "-isystem",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to SYSTEM include search path"},
    },
    .{
        .name = "include",
        .string = "-I",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Add directory to include search path"},
    },
    .{
        .name = "libc",
        .string = "--libc",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Provide a file which specifies libc paths"},
    },
    .{
        .name = "library",
        .string = "--library",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Link against system library (only if actually used)"},
    },
    .{
        .name = "needed_library",
        .string = "--needed-library",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Link against system library (even if unused)"},
    },
    .{
        .name = "library_directory",
        .string = "--library-directory",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Add a directory to the library search path"},
    },
    .{
        .name = "link_script",
        .string = "--script",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Use a custom linker script"},
    },
    .{
        .name = "version_script",
        .string = "--version-script",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Provide a version .map file"},
    },
    .{
        .name = "dynamic_linker",
        .string = "--dynamic-linker",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the dynamic interpreter path"},
    },
    .{
        .name = "sysroot",
        .string = "--sysroot",
        .arg_info = ArgInfo.optional_string([]const u8),
        .descr = &.{"Set the system root directory"},
    },
    .{
        .name = "entry",
        .string = "--entry",
        .arg_info = ArgInfo.optional_string([]const u8),
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
        .arg_info = ArgInfo.optional_string([]const u8),
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
        .string = "--compress-debug-sections",
        .arg_info = ArgInfo.optional_tag(enum { none, zlib }),
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
        .arg_info = ArgInfo.optional_integer(u64),
        .descr = &.{"Override default stack size"},
    },
    .{
        .name = "image_base",
        .string = "--image-base",
        .arg_info = ArgInfo.optional_integer(u64),
        .descr = &.{"Set base address for executable image"},
    },
    .{
        .name = "macros",
        .arg_info = ArgInfo.optional_mapped("[]const types.Macro"),
        .descr = &.{"Define C macros available within the `@cImport` namespace"},
    },
    .{
        .name = "modules",
        .arg_info = ArgInfo.optional_mapped("[]const types.Module"),
        .descr = &.{"Define modules available as dependencies for the current target"},
    },
    .{
        .name = "dependencies",
        .arg_info = ArgInfo.optional_mapped("[]const types.ModuleDependency"),
        .descr = &.{"Define module dependencies for the current target"},
    },
    .{
        .name = "cflags",
        .arg_info = ArgInfo.optional_formatter("types.CFlags"),
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
        .arg_info = ArgInfo.optional_tag(enum { nodelete, notext, defs, origin, nocopyreloc, now, lazy, relro, norelro }),
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
        .arg_info = ArgInfo.optional_mapped("[]const types.Path"),
        .descr = &.{"Add auxiliary files to the current target"},
    },
    // Debug Options (Zig Compiler Development):
    //   -ftime-report                Print timing diagnostics
    //   -fstack-report               Print stack size diagnostics
    //   --verbose-link               Display linker invocations
    //   --verbose-cc                 Display C compiler invocations
    //   --verbose-air                Enable compiler debug output for Zig AIR
    //   --verbose-mir                Enable compiler debug output for Zig MIR
    //   --verbose-llvm-ir            Enable compiler debug output for LLVM IR
    //   --verbose-cimport            Enable compiler debug output for C imports
    //   --verbose-llvm-cpu-features  Enable compiler debug output for LLVM CPU features
    //   --debug-log [scope]          Enable printing debug/info log messages for scope
    //   --debug-compile-errors       Crash with helpful diagnostics at the first compile error
    //   --debug-link-snapshot        Enable dumping of the linker's state in JSON
};
fn writeIf(array: *Array, value: []const u8) void {
    array.writeMany("if(");
    array.writeMany(value);
    array.writeMany("){\n");
}
fn writeIfField(array: *Array, field_name: []const u8) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeIfOptionalField(array: *Array, field_name: []const u8) void {
    array.writeMany("if(cmd.");
    array.writeMany(field_name);
    array.writeMany(")|");
    array.writeMany(field_name);
    array.writeMany("|{\n");
}
fn writeYesOptionalIf(array: *Array) void {
    array.writeMany("if(yes_optional_arg)|yes_arg|{\n");
}
fn writeNoOptionalIf(array: *Array) void {
    array.writeMany("if(no_optional_arg)|no_arg|{\n");
}
fn writeSwitch(array: *Array, field_name: []const u8) void {
    array.writeMany("switch(");
    array.writeMany(field_name);
    array.writeMany("){\n");
}
fn writeDefaultProng(array: *Array) void {
    array.writeMany(".default=>{\n");
}
fn writeExplicitProng(array: *Array) void {
    array.writeMany(".explicit=>|how|{\n");
}
fn writeNoProng(array: *Array) void {
    array.writeMany(".no=>{\n");
}
fn writeYesProng(array: *Array) void {
    array.writeMany(".yes=>{\n");
}
fn writeNoRequiredProng(array: *Array) void {
    array.writeMany(".no=>|no_arg|{\n");
}
fn writeYesRequiredProng(array: *Array) void {
    array.writeMany(".yes=>|yes_arg|{\n");
}
fn writeYesOptionalProng(array: *Array) void {
    array.writeMany(".yes=>|yes_optional_arg|{\n");
}
fn writeNoOptionalProng(array: *Array) void {
    array.writeMany(".no=>|no_optional_arg|{\n");
}
fn writeElse(array: *Array) void {
    array.writeMany("}else{\n");
}
fn writeIfClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeSwitchClose(array: *Array) void {
    array.writeMany("}\n");
}
fn writeProngClose(array: *Array) void {
    array.writeMany("},\n");
}
fn writeNull(
    array: *Array,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany("len=len+%1;\n");
        },
        .write => {
            array.writeMany("buf[len]=0;\nlen=len+%1;\n");
        },
    }
}
fn writeOne(
    array: *Array,
    one: u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany("len=len+%1;\n");
        },
        .write => {
            array.writeMany("buf[len]=");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(";\n");
            writeOne(array, one, .length);
        },
    }
}
fn writeIntegerString(array: *Array, arg_string: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("const s: []const u8 = builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll();\n");
            array.writeMany("@memcpy(buf+len,s.ptr,s.len);\n");
            writeOptString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%builtin.fmt.ud64(");
            array.writeMany(arg_string);
            array.writeMany(").readAll().len;\n");
        },
    }
}
fn writeTagString(array: *Array, arg_string: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,");
            array.writeMany("@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").ptr");
            array.writeMany(",");
            array.writeMany("@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len);\n");
            writeOptString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%@tagName(");
            array.writeMany(arg_string);
            array.writeMany(").len;\n");
        },
    }
}
fn writeOptString(array: *Array, opt_string: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,");
            array.writeOne('"');
            array.writeMany(opt_string);
            array.writeMany("\\x00");
            array.writeOne('"');
            array.writeMany(",");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(");\n");
            writeOptString(array, opt_string, .length);
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeFormat(fmt.ud64(opt_string.len +% 1));
            array.writeMany(";\n");
        },
    }
}
fn writeArgString(array: *Array, arg_string: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("@memcpy(buf+len,");
            array.writeMany(arg_string);
            array.writeMany(".ptr,");
            array.writeMany(arg_string);
            array.writeMany(".len);\n");
            writeArgString(array, arg_string, .length);
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".len;\n");
        },
    }
}
fn writeOptArgInteger(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: Variant) void {
    writeOptString(array, opt_string, variant);
    writeIntegerString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptArgString(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: Variant) void {
    writeOptString(array, opt_string, variant);
    writeArgString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeOptTagString(array: *Array, opt_string: []const u8, arg_string: []const u8, variant: Variant) void {
    writeOptString(array, opt_string, variant);
    writeTagString(array, arg_string, variant);
    writeNull(array, variant);
}
fn writeFormatter(array: *Array, opt_switch_string: ?[]const u8, arg_string: []const u8, variant: Variant) void {
    if (opt_switch_string) |switch_string| {
        writeOptString(array, switch_string, variant);
    }
    switch (variant) {
        .write => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".formatWriteBuf(buf+len);\n");
        },
        .length => {
            array.writeMany("len=len+%");
            array.writeMany(arg_string);
            array.writeMany(".formatLength();\n");
        },
    }
}
fn writeMapped(array: *Array, opt_switch_string: ?[]const u8, arg_string: []const u8, variant: Variant) void {
    if (opt_switch_string) |switch_string| {
        writeOptString(array, switch_string, variant);
    }
    switch (variant) {
        .write => {
            array.writeMany("len=len+%formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatWriteBuf(buf+len);\n");
        },
        .length => {
            array.writeMany("len=len+%formatMap(");
            array.writeMany(arg_string);
            array.writeMany(").formatLength();\n");
        },
    }
}
pub fn writeFunctionBody(array: *Array, options: []const OptionSpec, variant: Variant) void {
    for (options) |opt_spec| {
        if (opt_spec.and_no) |no_opt_spec| {
            if (opt_spec.arg_info.tag == .boolean) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeIf(array, opt_spec.name);
                    writeOptString(array, opt_spec.string.?, variant);
                    writeElse(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            if (opt_spec.arg_info.tag == .string) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeSwitch(array, opt_spec.name);
                    writeYesRequiredProng(array);
                    writeOptArgString(array, opt_spec.string.?, "yes_arg", variant);
                    writeProngClose(array);
                    writeNoProng(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeProngClose(array);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            if (opt_spec.arg_info.tag == .formatter) {
                if (no_opt_spec.arg_info.tag == .boolean) {
                    writeIfOptionalField(array, opt_spec.name);
                    writeSwitch(array, opt_spec.name);
                    writeYesRequiredProng(array);
                    writeFormatter(array, opt_spec.string, "yes_arg", variant);
                    writeProngClose(array);
                    writeNoProng(array);
                    writeOptString(array, no_opt_spec.string.?, variant);
                    writeProngClose(array);
                    writeIfClose(array);
                    writeIfClose(array);
                    continue;
                }
            }
            unhandledCommandFieldAndNo(opt_spec, no_opt_spec);
        } else {
            if (opt_spec.arg_info.tag == .boolean) {
                writeIfField(array, opt_spec.name);
                writeOptString(array, opt_spec.string.?, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_string) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptArgString(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_tag) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptTagString(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_integer) {
                writeIfOptionalField(array, opt_spec.name);
                writeOptArgInteger(array, opt_spec.string.?, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_formatter) {
                writeIfOptionalField(array, opt_spec.name);
                writeFormatter(array, opt_spec.string, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            if (opt_spec.arg_info.tag == .optional_mapped) {
                writeIfOptionalField(array, opt_spec.name);
                writeMapped(array, opt_spec.string, opt_spec.name, variant);
                writeIfClose(array);
                continue;
            }
            unhandledCommandField(opt_spec);
        }
    }
}
fn unhandledCommandFieldAndNo(opt_spec: OptionSpec, no_opt_spec: InverseOptionSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.arg_info.tag), "+", @tagName(no_opt_spec.arg_info.tag),
    });
    builtin.proc.exitWithFaultMessage(buf[0..len], 2);
}
fn unhandledCommandField(opt_spec: OptionSpec) void {
    var buf: [4096]u8 = undefined;
    var len: u64 = builtin.debug.writeMulti(&buf, &.{
        opt_spec.name, ": ", @tagName(opt_spec.arg_info.tag), "\n",
    });
    builtin.proc.exitWithFaultMessage(buf[0..len], 2);
}
fn writeFields(array: *Array, opt_specs: []const OptionSpec) void {
    for (opt_specs) |opt_spec| {
        if (opt_spec.descr) |field_descr| {
            for (field_descr) |line| {
                array.writeMany("/// ");
                array.writeMany(line);
                array.writeMany("\n");
            }
        }
        array.writeMany(opt_spec.name);
        array.writeMany(":");
        if (opt_spec.and_no) |no_opt_spec| {
            const yes_bool: bool = opt_spec.arg_info.tag == .boolean;
            const no_bool: bool = no_opt_spec.arg_info.tag == .boolean;
            if (yes_bool != no_bool) {
                const tmp: ProtoTypeDescr = .{ .type_decl = .{ .Composition = .{
                    .spec = "union(enum)",
                    .fields = &.{
                        .{ .name = "yes", .type = if (yes_bool) null else opt_spec.arg_info.type },
                        .{ .name = "no", .type = if (no_bool) null else no_opt_spec.arg_info.type },
                    },
                } } };
                array.writeFormat(ArgInfo.optional(&tmp));
            } else {
                array.writeFormat(ArgInfo.optional(&ProtoTypeDescr.init(bool)));
            }
            array.writeMany("=null,\n");
        } else {
            if (opt_spec.arg_info.tag == .boolean) {
                array.writeFormat(opt_spec.arg_info.type);
                array.writeMany("=false,\n");
            } else {
                array.writeFormat(opt_spec.arg_info.type);
                array.writeMany("=null,\n");
            }
        }
    }
}
fn writeFile(array: Array, pathname: [:0]const u8) !void {
    const build_fd: u64 = try file.create(.{ .options = .{ .exclusive = false } }, pathname, file.file_mode);
    try file.writeSlice(.{}, build_fd, array.readAll());
    try file.close(.{}, build_fd);
}
pub fn main() !void {
    var array: Array = undefined;
    array.undefineAll();
    var st: file.Status = try file.pathStatus(.{}, tasks_template_path);
    var fd: u64 = try file.open(.{}, tasks_template_path);
    array.define(try file.readSlice(.{}, fd, array.referAllUndefined()[0..st.size]));
    try file.close(.{}, fd);
    array.writeMany("pub const BuildCommand=struct{\n");
    array.writeMany("kind:OutputMode,\n");
    writeFields(&array, build_command_options);
    array.writeMany("};\n");
    array.writeMany("pub const FormatCommand=struct{\n");
    writeFields(&array, format_command_options);
    array.writeMany("};\n");
    try writeFile(array, tasks_path);
    array.undefineAll();
    st = try file.pathStatus(.{}, command_line_path);
    fd = try file.open(.{}, command_line_template_path);
    array.define(try file.readSlice(.{}, fd, array.referAllUndefined()[0..st.size]));
    try file.close(.{}, fd);
    array.writeMany("pub fn buildWrite(cmd:*const types.BuildCommand,buf:[*]u8)u64{\n");
    array.writeMany("var len:u64=0;\n");
    writeFunctionBody(&array, build_command_options, .write);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn buildLength(cmd: *const types.BuildCommand)u64{\n");
    array.writeMany("var len:u64=0;\n");
    writeFunctionBody(&array, build_command_options, .length);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn formatLength(cmd:*const types.FormatCommand)u64{\n");
    array.writeMany("var len: u64 = 0;\n");
    writeFunctionBody(&array, format_command_options, .length);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn formatWrite(cmd:*const types.FormatCommand,buf:[*]u8)u64{\n");
    array.writeMany("var len: u64 = 0;\n");
    writeFunctionBody(&array, format_command_options, .write);
    array.writeMany("return len;\n");
    array.writeMany("}\n");
    try writeFile(array, command_line_path);
    array.undefineAll();
}
