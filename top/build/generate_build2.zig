const mem = @import("../mem.zig");
const sys = @import("../sys.zig");
const fmt = @import("../fmt.zig");
const proc = @import("../proc.zig");
const mach = @import("../mach.zig");
const file = @import("../file.zig");
const meta = @import("../meta.zig");
const spec = @import("../spec.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types.zig");

pub usingnamespace proc.start;

pub const AddressSpace = spec.address_space.regular_128;
pub const is_verbose: bool = false;
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;
pub const runtime_assertions: bool = false;
const prefer_inline: bool = true;
const write_fn_name: bool = false;
const commit_write: bool = true;
const build_root: [:0]const u8 = builtin.buildRoot();
const initial_indent: u64 = 0;
const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 24,
    .options = spec.allocator.options.small,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
    .AddressSpace = AddressSpace,
});
const Array = Allocator.StructuredHolder(u8);
const Variant = enum(u1) { length, write };
const ws: [28]u8 = .{' '} ** 28;
const kill_spaces: u64 = (initial_indent + 1) * 4;
const build_members_loc_token: []const u8 = "__compile_command: void,";
const format_members_loc_token: []const u8 = "__format_command: void,";
const build_len_fn_body_loc_token: []const u8 = "cmd = buildLength;";
const build_write_fn_body_loc_token: []const u8 = "cmd = buildWrite;";
const format_len_fn_body_loc_token: []const u8 = "cmd = formatLength;";
const format_write_fn_body_loc_token: []const u8 = "cmd = formatWrite;";

const tasks_path: [:0]const u8 = build_root ++ "/top/build/tasks.zig";
const tasks_template_path: [:0]const u8 = build_root ++ "/top/build/tasks-template.zig";
const command_line_path: [:0]const u8 = build_root ++ "/top/build/command_line.zig";
const command_line_template_path: [:0]const u8 = build_root ++ "/top/build/command_line-template.zig";

pub const open_spec: file.OpenSpec = .{
    .options = .{ .read = true, .write = .append },
};
pub const OptionSpec = struct {
    /// Command struct field name
    name: []const u8 = "",
    /// Command line flag/switch
    string: ?[]const u8 = null,
    /// Simple argument type
    arg_type: ?type = null,
    /// Any argument type name; must be defined in build-template.zig
    arg_type_name: ?[]const u8 = null,
    /// For options with -f<name> and -fno-<name> variants
    and_no: ?*const OptionSpec = null,
    /// Maybe define default value of this field. Should be false or null, but
    /// allow the exception.
    default_value: ?*const anyopaque = null,
    /// Description to be inserted above the field as documentation comment
    descr: ?[]const []const u8 = null,
};

const format_command_options: []const OptionSpec = &.{
    .{
        .name = "color",
        .string = "--color",
        .arg_type = enum { auto, off, on },
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
        .default_value = &true,
        .descr = &.{"Run zig ast-check on every file"},
    },
    .{
        .name = "exclude",
        .string = "--exclude",
        .arg_type = []const u8,
        .descr = &.{"Exclude file or directory from formatting"},
    },
};

pub const build_command_options: []const OptionSpec = &.{
    .{
        .name = "builtin",
        .string = "-fbuiltin",
        .descr = &.{"Enable implicit builtin knowledge of functions"},
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
        .name = "color",
        .string = "--color",
        .arg_type = enum { on, off, auto },
        .descr = &.{"Enable or disable colored error messages"},
    },
    .{
        .name = "emit_bin",
        .string = "-femit-bin",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-bin" },
        .descr = &.{"(default=yes) Output machine code"},
    },
    .{
        .name = "emit_asm",
        .string = "-femit-asm",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-asm" },
        .descr = &.{"(default=no) Output assembly code (.s)"},
    },
    .{
        .name = "emit_llvm_ir",
        .string = "-femit-llvm-ir",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-llvm-ir" },
        .descr = &.{"(default=no) Output optimized LLVM IR (.ll)"},
    },
    .{
        .name = "emit_llvm_bc",
        .string = "-femit-llvm-bc",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-llvm-bc" },
        .descr = &.{"(default=no) Output optimized LLVM BC (.bc)"},
    },
    .{
        .name = "emit_h",
        .string = "-femit-h",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-h" },
        .descr = &.{"(default=no) Output a C header file (.h)"},
    },
    .{
        .name = "emit_docs",
        .string = "-femit-docs",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-docs" },
        .descr = &.{"(default=no) Output documentation (.html)"},
    },
    .{
        .name = "emit_analysis",
        .string = "-femit-analysis",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-analysis" },
        .descr = &.{"(default=no) Output analysis (.json)"},
    },
    .{
        .name = "emit_implib",
        .string = "-femit-implib",
        .arg_type = ?types.Path,
        .arg_type_name = "Path",
        .and_no = &.{ .string = "-fno-emit-implib" },
        .descr = &.{"(default=yes) Output an import when building a Windows DLL (.lib)"},
    },
    .{
        .name = "cache_root",
        .string = "--cache-dir",
        .arg_type = []const u8,
        .descr = &.{"Override the local cache directory"},
    },
    .{
        .name = "global_cache_root",
        .string = "--global-cache-dir",
        .arg_type = []const u8,
        .descr = &.{"Override the global cache directory"},
    },
    .{
        .name = "zig_lib_root",
        .string = "--zig-lib-dir",
        .arg_type = []const u8,
        .descr = &.{"Override Zig installation lib directory"},
    },
    .{
        .name = "listen",
        .string = "--listen",
        .arg_type = enum { none, @"-", ipv4 },
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
        .arg_type = []const u8,
        .descr = &.{"<arch><sub>-<os>-<abi> see the targets command"},
    },
    .{
        .name = "cpu",
        .string = "-mcpu",
        .arg_type = []const u8,
        .descr = &.{"Specify target CPU and feature set"},
    },
    .{
        .name = "code_model",
        .string = "-mcmodel",
        .arg_type = enum { default, tiny, small, kernel, medium, large },
        .descr = &.{"Limit range of code and data virtual addresses"},
    },
    .{
        .name = "red_zone",
        .string = "-mred-zone",
        .and_no = &.{ .string = "-mno-red-zone" },
        .descr = &.{"Enable the \"red-zone\""},
    },
    .{
        .name = "omit_frame_pointer",
        .string = "-fomit-frame-pointer",
        .and_no = &.{ .string = "-fno-omit-frame-pointer" },
        .descr = &.{"Omit the stack frame pointer"},
    },
    .{
        .name = "exec_model",
        .string = "-mexec-model",
        .arg_type = []const u8,
        .descr = &.{"(WASI) Execution model"},
    },
    .{
        .name = "name",
        .string = "--name",
        .arg_type = []const u8,
        .descr = &.{"Override root name"},
    },
    .{
        .name = "mode",
        .string = "-O",
        .arg_type = builtin.Mode,
        .arg_type_name = "builtin.Mode",
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
        .arg_type = []const u8,
        .descr = &.{"Set the directory of the root package"},
    },
    .{
        .name = "pic",
        .string = "-fPIC",
        .and_no = &.{ .string = "-fno-PIC" },
        .descr = &.{"Enable Position Independent Code"},
    },
    .{
        .name = "pie",
        .string = "-fPIE",
        .and_no = &.{ .string = "-fno-PIE" },
        .descr = &.{"Enable Position Independent Executable"},
    },
    .{
        .name = "lto",
        .string = "-flto",
        .and_no = &.{ .string = "-fno-lto" },
        .descr = &.{"Enable Link Time Optimization"},
    },
    .{
        .name = "stack_check",
        .string = "-fstack-check",
        .and_no = &.{ .string = "-fno-stack-check" },
        .descr = &.{"Enable stack probing in unsafe builds"},
    },
    .{
        .name = "stack_protector",
        .string = "-fstack-check",
        .and_no = &.{ .string = "-fno-stack-protector" },
        .descr = &.{"Enable stack protection in unsafe builds"},
    },
    .{
        .name = "sanitize_c",
        .string = "-fsanitize-c",
        .and_no = &.{ .string = "-fno-sanitize-c" },
        .descr = &.{"Enable C undefined behaviour detection in unsafe builds"},
    },
    .{
        .name = "valgrind",
        .string = "-fvalgrind",
        .and_no = &.{ .string = "-fno-valgrind" },
        .descr = &.{"Include valgrind client requests in release builds"},
    },
    .{
        .name = "sanitize_thread",
        .string = "-fsanitize-thread",
        .and_no = &.{ .string = "-fno-sanitize-thread" },
        .descr = &.{"Enable thread sanitizer"},
    },
    .{
        .name = "unwind_tables",
        .string = "-funwind-tables",
        .and_no = &.{ .string = "-fno-unwind-tables" },
        .descr = &.{"Always produce unwind table entries for all functions"},
    },
    .{
        .name = "llvm",
        .string = "-fLLVM",
        .and_no = &.{ .string = "-fno-LLVM" },
        .descr = &.{"Use LLVM as the codegen backend"},
    },
    .{
        .name = "clang",
        .string = "-fClang",
        .and_no = &.{ .string = "-fno-Clang" },
        .descr = &.{"Use Clang as the C/C++ compilation backend"},
    },
    .{
        .name = "reference_trace",
        .string = "-freference-trace",
        .and_no = &.{ .string = "-fno-reference-trace" },
        .descr = &.{"How many lines of reference trace should be shown per compile error"},
    },
    .{
        .name = "error_tracing",
        .string = "-ferror-tracing",
        .and_no = &.{ .string = "-fno-error-tracing" },
        .descr = &.{"Enable error tracing in `ReleaseFast` mode"},
    },
    .{
        .name = "single_threaded",
        .string = "-fsingle-threaded",
        .and_no = &.{ .string = "-fno-single-threaded" },
        .descr = &.{"Code assumes there is only one thread"},
    },
    .{
        .name = "function_sections",
        .string = "-ffunction-sections",
        .and_no = &.{ .string = "-fno-function-sections" },
        .descr = &.{"Places each function in a separate sections"},
    },
    .{
        .name = "strip",
        .string = "-fstrip",
        .and_no = &.{ .string = "-fno-strip" },
        .descr = &.{"Omit debug symbols"},
    },
    .{
        .name = "formatted_panics",
        .string = "-fformatted-panics",
        .and_no = &.{ .string = "-fno-formatted-panics" },
        .descr = &.{"Enable formatted safety panics"},
    },
    .{
        .name = "fmt",
        .string = "-ofmt",
        .arg_type = enum { elf, c, wasm, coff, macho, spirv, plan9, hex, raw },
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
        .arg_type = []const u8,
        .descr = &.{"Add directory to AFTER include search path"},
    },
    .{
        .name = "system",
        .string = "-isystem",
        .arg_type = []const u8,
        .descr = &.{"Add directory to SYSTEM include search path"},
    },
    .{
        .name = "include",
        .string = "-I",
        .arg_type = []const u8,
        .descr = &.{"Add directory to include search path"},
    },
    .{
        .name = "libc",
        .string = "--libc",
        .arg_type = []const u8,
        .descr = &.{"Provide a file which specifies libc paths"},
    },
    .{
        .name = "library",
        .string = "--library",
        .arg_type = []const u8,
        .descr = &.{"Link against system library (only if actually used)"},
    },
    .{
        .name = "needed_library",
        .string = "--needed-library",
        .arg_type = []const u8,
        .descr = &.{"Link against system library (even if unused)"},
    },
    .{
        .name = "library_directory",
        .string = "--library-directory",
        .arg_type = []const u8,
        .descr = &.{"Add a directory to the library search path"},
    },
    .{
        .name = "link_script",
        .string = "--script",
        .arg_type = []const u8,
        .descr = &.{"Use a custom linker script"},
    },
    .{
        .name = "version_script",
        .string = "--version-script",
        .arg_type = []const u8,
        .descr = &.{"Provide a version .map file"},
    },
    .{
        .name = "dynamic_linker",
        .string = "--dynamic-linker",
        .arg_type = []const u8,
        .descr = &.{"Set the dynamic interpreter path"},
    },
    .{
        .name = "sysroot",
        .string = "--sysroot",
        .arg_type = []const u8,
        .descr = &.{"Set the system root directory"},
    },
    .{ .name = "version", .string = "--version" },
    .{
        .name = "entry",
        .string = "--entry",
        .arg_type = []const u8,
        .descr = &.{"Set the entrypoint symbol name"},
    },
    .{
        .name = "soname",
        .string = "-fsoname",
        .arg_type = []const u8,
        .and_no = &.{ .string = "-fno-soname" },
        .descr = &.{"Override the default SONAME value"},
    },
    .{
        .name = "lld",
        .string = "-fLLD",
        .and_no = &.{ .string = "-fno-LLD" },
        .descr = &.{"Use LLD as the linker"},
    },
    .{
        .name = "compiler_rt",
        .string = "-fcompiler-rt",
        .and_no = &.{ .string = "-fno-compiler-rt" },
        .descr = &.{"(default) Include compiler-rt symbols in output"},
    },
    .{
        .name = "rpath",
        .string = "-rpath",
        .arg_type = []const u8,
        .descr = &.{"Add directory to the runtime library search path"},
    },
    .{
        .name = "each_lib_rpath",
        .string = "-feach-lib-rpath",
        .and_no = &.{ .string = "-fno-each-lib-rpath" },
        .descr = &.{"Ensure adding rpath for each used dynamic library"},
    },
    .{
        .name = "allow_shlib_undefined",
        .string = "-fallow-shlib-undefined",
        .and_no = &.{ .string = "-fno-allow-shlib-undefined" },
        .descr = &.{"Allow undefined symbols in shared libraries"},
    },
    .{
        .name = "build_id",
        .string = "-fbuild-id",
        .and_no = &.{ .string = "-fno-build-id" },
        .descr = &.{"Help coordinate stripped binaries with debug symbols"},
    },
    .{
        .name = "compress_debug_sections",
        .string = "--compress-debug-sections",
        .arg_type = enum { none, zlib },
        .descr = &.{
            "Debug section compression:",
            "none   No compression",
            "zlib   Compression with deflate/inflate",
        },
    },
    .{
        .name = "gc_sections",
        .string = "--gc-sections",
        .and_no = &.{ .string = "--no-gc-sections" },
        .descr = &.{
            "Force removal of functions and data that are unreachable",
            "by the entry point or exported symbols",
        },
    },
    .{
        .name = "stack",
        .string = "--stack",
        .arg_type = u64,
        .descr = &.{"Override default stack size"},
    },
    .{
        .name = "image_base",
        .string = "--image-base",
        .arg_type = u64,
        .descr = &.{"Set base address for executable image"},
    },
    .{
        .name = "macros",
        .arg_type = []const types.Macro,
        .arg_type_name = "[]const types.Macro",
        .descr = &.{"Define C macros available within the `@cImport` namespace"},
    },
    .{
        .name = "modules",
        .arg_type = []const types.Module,
        .arg_type_name = "[]const types.Module",
        .descr = &.{"Define modules available as dependencies for the current target"},
    },
    .{
        .name = "dependencies",
        .arg_type = []const types.ModuleDependency,
        .arg_type_name = "[]const types.ModuleDependency",
        .descr = &.{"Define module dependencies for the current target"},
    },
    .{
        .name = "cflags",
        .arg_type = types.CFlags,
        .arg_type_name = "CFlags",
        .descr = &.{"Set extra flags for the next position C source files"},
    },
    .{
        .name = "z",
        .string = "-z",
        .arg_type = enum { nodelete, notext, defs, origin, nocopyreloc, now, lazy, relro, norelro },
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
        .arg_type = []const types.Path,
        .arg_type_name = "[]const types.Path",
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
pub fn inaccurateGuessWarning(comptime string: []const u8, guess: u64, actual: u64) void {
    const max_len: u64 = 16 + 19 + 41 + string.len + 3 + 19 + 13 + 19 + 2;
    var buf: [max_len]u8 = undefined;
    builtin.debug.logErrorAIO(&buf, &.{
        "guess-warn:     ",                          builtin.fmt.ud64(guess).readAll(),
        ", better guess for starting position of '", string,
        "': ",                                       builtin.fmt.ud64(actual).readAll(),
        "\n",
    });
}
pub fn nullGuessWarning(comptime string: []const u8) void {
    builtin.debug.logError("source does not contain string '" ++ string ++ "'\n");
}
pub fn guessSourceOffset(src: []const u8, comptime string: []const u8, guess: u64) !u64 {
    if (guess > src.len) {
        return guessSourceOffset(src, string, src.len / 2);
    }
    if (mem.propagateSearch(u8, string, src, guess)) |actual| {
        const diff: u64 = builtin.diff(u64, actual, guess);
        if (diff != 0) {
            inaccurateGuessWarning(string, guess, actual);
        }
        try builtin.expectEqual([]const u8, string, src[actual .. actual + string.len]);
        return actual;
    }
    nullGuessWarning(string);
    return error.SourceDoesNotContainArray;
}
fn subTemplate(src: [:0]const u8, comptime sub_name: [:0]const u8) ?[]const u8 {
    const start_s: []const u8 = "// start-document " ++ sub_name ++ "\n";
    const finish_s: []const u8 = "// finish-document " ++ sub_name ++ "\n";
    if (mem.indexOfFirstEqualMany(u8, start_s, src)) |after| {
        if (mem.indexOfFirstEqualMany(u8, finish_s, src[after..])) |before| {
            const ret: []const u8 = src[after + start_s.len .. after + before];
            return ret;
        } else {
            builtin.debug.write("missing: " ++ finish_s ++ "\n");
            return null;
        }
    } else {
        builtin.debug.write("missing: " ++ start_s ++ "\n");
        return null;
    }
}
pub fn writeImport(array: anytype, name: []const u8, pathname: []const u8) void {
    array.writeMany("const ");
    array.writeMany(name);
    array.writeMany(" = @import(\"");
    array.writeMany(pathname);
    array.writeMany("\");\n");
}
pub fn writeAsm(array: anytype, pathname: []const u8) void {
    array.writeMany("comptime {\n");
    array.writeMany("    asm (@embedFile(\"");
    array.writeMany(pathname);
    array.writeMany("\"));\n");
    array.writeMany("}\n");
}
pub fn writeIndent(array: *Array, width: u64, values: []const u8) void {
    try array.increment(values.len * 6);
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
    if (mem.testEqualMany(u8, "\n    ", array.readManyBack(5))) {
        array.undefine(4);
    }
}
fn unhandledSpecification(comptime what_field: []const u8, comptime opt_spec: OptionSpec) noreturn {
    @compileError("todo: " ++ @tagName(getOptKind(opt_spec)) ++ ": " ++ what_field);
}
pub fn formatCompositeLiteral(
    array: *Array,
    comptime T: type,
    comptime subst: ?struct { import_type: type, type_name: []const u8 },
) void {
    const type_name: []const u8 = @typeName(T);
    const type_info: builtin.Type = @typeInfo(T);
    array.writeMany(comptime builtin.fmt.typeDeclSpecifier(type_info) ++ " {");
    switch (type_info) {
        .Enum => |enum_info| {
            inline for (enum_info.fields) |field| {
                array.writeMany(" ");
                array.writeFormat(fmt.IdentifierFormat{ .value = field.name });
                array.writeMany(" = ");
                array.writeFormat(comptime fmt.any(field.value));
                array.writeMany(",");
            }
            array.undefine(1);
            array.writeMany(" }");
        },
        .Union => |union_info| {
            inline for (union_info.fields) |field| {
                array.writeMany(" " ++ field.name ++ ": ");
                if (subst) |s| {
                    if (field.type == s.import_type) {
                        array.writeMany(s.type_name);
                    } else {
                        switch (@typeInfo(field.type)) {
                            .Enum, .Struct, .Union => {
                                try formatCompositeLiteral(array, field.type, subst);
                            },
                            else => {
                                array.writeMany(@typeName(field.type));
                            },
                        }
                    }
                } else {
                    switch (@typeInfo(field.type)) {
                        .Enum, .Struct, .Union => {
                            try formatCompositeLiteral(array, field.type, subst);
                        },
                        else => {
                            array.writeMany(@typeName(field.type));
                        },
                    }
                }
                array.writeOne(',');
            }
            array.undefine(1);
            array.writeMany(" }");
        },
        .Struct => |struct_info| {
            inline for (struct_info.fields) |field| {
                array.writeMany(" " ++ field.name ++ ": ");
                switch (@typeInfo(field.type)) {
                    .Enum, .Struct, .Union => {
                        try formatCompositeLiteral(array, field.type, subst);
                    },
                    else => {
                        array.writeMany(@typeName(field.type));
                    },
                }
                array.writeOne(',');
            }
            array.undefine(1);
            array.writeMany(" }");
        },
        else => @compileError("???" ++ type_name),
    }
}
fn writeIf(array: *Array, width: *u64, what_field: []const u8) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (cmd.");
    array.writeMany(what_field);
    array.writeMany(") {\n");
    width.* += 4;
}
fn writeYesOptionalIf(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (yes_optional_arg) |yes_arg| {\n");
    width.* += 4;
}
fn writeNoOptionalIf(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (no_optional_arg) |no_arg| {\n");
    width.* += 4;
}
fn writeIfHow(array: *Array, width: *u64, what_field: []const u8) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (cmd.");
    array.writeMany(what_field);
    array.writeMany(") |how| {\n");
    width.* += 4;
}
fn writeIfWhat(array: *Array, width: *u64, what_field: []const u8) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (cmd.");
    array.writeMany(what_field);
    array.writeMany(") |");
    array.writeMany(what_field);
    array.writeMany("| {\n");
    width.* += 4;
}
fn writeIfOr(array: *Array, width: *u64, what_field: []const u8) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("if (");
    array.writeMany(what_field);
    array.writeMany(") {\n");
    width.* += 4;
}
fn writeSwitch(array: *Array, width: *u64, what_field: []const u8) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany("switch (");
    array.writeMany(what_field);
    array.writeMany(") {\n");
    width.* += 4;
}
fn writeDefaultProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".default => {\n");
    width.* += 4;
}
fn writeExplicitProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".explicit => |how| {\n");
    width.* += 4;
}
fn writeNoProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".no => {\n");
    width.* += 4;
}
fn writeYesProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".yes => {\n");
    width.* += 4;
}
fn writeNoRequiredProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".no => |no_arg| {\n");
    width.* += 4;
}
fn writeYesRequiredProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".yes => |yes_arg| {\n");
    width.* += 4;
}
fn writeYesOptionalProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".yes => |yes_optional_arg| {\n");
    width.* += 4;
}
fn writeNoOptionalProng(array: *Array, width: *u64) void {
    array.writeMany(ws[0..width.*]);
    array.writeMany(".no => |no_optional_arg| {\n");
    width.* += 4;
}
fn writeElse(array: *Array, width: *u64) void {
    width.* -= 4;
    array.writeMany(ws[0..width.*]);
    array.writeMany("} else {\n");
    width.* += 4;
}
fn writeIfClose(array: *Array, width: *u64) void {
    width.* -= 4;
    array.writeMany(ws[0..width.*]);
    array.writeMany("}\n");
}
fn writeSwitchClose(array: *Array, width: *u64) void {
    width.* -= 4;
    array.writeMany(ws[0..width.*]);
    array.writeMany("}\n");
}
fn writeProngClose(array: *Array, width: *u64) void {
    width.* -= 4;
    array.writeMany(ws[0..width.*]);
    array.writeMany("},\n");
}
fn writeNull(
    array: *Array,
    width: u64,
    variant: Variant,
) void {
    array.writeMany(ws[0..width]);
    switch (variant) {
        .length => {
            array.writeMany("len +%= 1;\n");
        },
        .write => {
            array.writeMany("array.writeOne(\'\\x00\');\n");
        },
    }
}
fn writeMany(
    array: *Array,
    width: u64,
    many: []const u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany(ws[0..width]);
            array.writeMany("len +%= ");
            array.writeMany(many);
            array.writeMany(".len;\n");
        },
        .write => {
            array.writeMany(ws[0..width]);
            array.writeMany("array.writeMany(");
            array.writeMany(many);
            array.writeMany(");\n");
        },
    }
}
fn writeOne(
    array: *Array,
    width: u64,
    one: u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany(ws[0..width]);
            array.writeMany("len +%= 1;\n");
        },
        .write => {
            array.writeMany(ws[0..width]);
            array.writeMany("array.writeOne(");
            array.writeFormat(fmt.ud8(one));
            array.writeMany(");\n");
        },
    }
}
fn writeArg(
    array: *Array,
    width: u64,
    what_arg: []const u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany(ws[0..width]);
            array.writeMany("len +%= mem.reinterpret.lengthAny(u8, reinterpret_spec, ");
            array.writeMany(what_arg);
            array.writeMany(");\n");
        },
        .write => {
            array.writeMany(ws[0..width]);
            array.writeMany("array.writeAny(reinterpret_spec, ");
            array.writeMany(what_arg);
            array.writeMany(");\n");
        },
    }
}
fn writeSwitchNoAssign(
    array: *Array,
    width: u64,
    what_switch: []const u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany(ws[0..width]);
            array.writeMany("len +%= ");
            array.writeFormat(fmt.ud64(what_switch.len + 1));
            array.writeMany(";\n");
        },
        .write => {
            array.writeMany(ws[0..width]);
            array.writeMany("array.writeMany(\"");
            array.writeMany(what_switch);
            array.writeMany("\\x00\");\n");
        },
    }
}
fn writeSwitchAssign(
    array: *Array,
    width: u64,
    what_switch: []const u8,
    variant: Variant,
) void {
    switch (variant) {
        .length => {
            array.writeMany(ws[0..width]);
            array.writeMany("len +%= ");
            array.writeFormat(fmt.ud64(what_switch.len + 1));
            array.writeMany(";\n");
        },
        .write => {
            array.writeMany(ws[0..width]);
            array.writeMany("array.writeMany(\"");
            array.writeMany(what_switch);
            array.writeMany("=\");\n");
        },
    }
}
fn writeSwitchWithMandatoryArg(
    array: *Array,
    width: *u64,
    what_switch: []const u8,
    what_arg: []const u8,
    variant: Variant,
) void {
    writeSwitchNoAssign(array, width.*, what_switch, variant);
    writeArg(array, width.*, what_arg, variant);
    writeNull(array, width.*, variant);
}
fn writeSwitchWithOptionalArg(
    array: *Array,
    width: *u64,
    what_switch: []const u8,
    what_arg: []const u8,
    variant: Variant,
) void {
    writeSwitchAssign(array, width.*, what_switch, variant);
    writeArg(array, width.*, what_arg, variant);
    writeNull(array, width.*, variant);
}
fn writeHow(
    array: *Array,
    width: *u64,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (what_switch) |string| {
        writeSwitchWithMandatoryArg(array, width, string, "how", variant);
    } else {
        writeArg(array, width.*, "how", variant);
    }
}
fn writeExplicit(
    array: *Array,
    width: *u64,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (what_switch) |string| {
        writeSwitchWithMandatoryArg(array, width, string, "how", variant);
    } else {
        writeArg(array, width, "how", variant);
    }
}
fn writeNoRequiredArg(
    array: *Array,
    width: *u64,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    if (what_not_switch) |string| {
        writeSwitchWithMandatoryArg(array, width, string, "no_arg", variant);
    } else {
        writeArg(array, width, "no_arg", variant);
    }
}
fn writeYesRequiredArg(
    array: *Array,
    width: *u64,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (what_switch) |string| {
        writeSwitchWithMandatoryArg(array, width, string, "yes_arg", variant);
    } else {
        writeArg(array, width.*, "yes_arg", variant);
    }
}
pub fn writeWhat(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeIf(array, width, what_field);
    writeSwitchNoAssign(array, width.*, what_switch.?, variant);
    writeIfClose(array, width);
}
pub fn writeWhatHow(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeIfHow(array, width, what_field);
    writeHow(array, width, what_switch, variant);
    writeIfClose(array, width);
}
pub fn writeWhatOrWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: ?[]const u8,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeIfWhat(array, width, what_field);
    writeIfOr(array, width, what_field);
    writeSwitchNoAssign(array, width.*, what_switch.?, variant);
    writeElse(array, width);
    writeSwitchNoAssign(array, width.*, what_not_switch.?, variant);
    writeIfClose(array, width);
    writeIfClose(array, width);
}
pub fn writeOptionalWhat(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeIfWhat(array, width, what_field);
    writeSwitch(array, width, what_field);
    writeYesOptionalProng(array, width);
    writeYesOptionalIf(array, width);
    writeSwitchWithOptionalArg(array, width, what_switch.?, "yes_arg", variant);
    writeElse(array, width);
    writeSwitchNoAssign(array, width.*, what_switch.?, variant);
    writeIfClose(array, width);
    writeProngClose(array, width);
}
pub fn writeNonOptionalWhat(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeIfWhat(array, width, what_field);
    writeSwitch(array, width, what_field);
    writeYesRequiredProng(array, width);
    writeYesRequiredArg(array, width, what_switch, variant);
    writeProngClose(array, width);
}
pub fn writeOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeNoOptionalProng(array, width);
    writeNoOptionalIf(array, width);
    writeSwitchWithOptionalArg(array, width, what_not_switch.?, "no_arg", variant);
    writeElse(array, width);
    writeSwitchNoAssign(array, width, what_not_switch.?, variant);
    writeIfClose(array, width);
    writeProngClose(array, width);
    writeSwitchClose(array, width);
    writeIfClose(array, width);
}
pub fn writeNonOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeNoRequiredProng(array, width);
    writeNoRequiredArg(array, width, what_not_switch, variant);
    writeProngClose(array, width);
    writeSwitchClose(array, width);
    writeIfClose(array, width);
}
pub fn writeNoArgWhatNot(
    array: *Array,
    width: *u64,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    if (write_fn_name) fnNameComment(array, @src());
    writeNoProng(array, width);
    writeSwitchNoAssign(array, width.*, what_not_switch.?, variant);
    writeProngClose(array, width);
    writeSwitchClose(array, width);
    writeIfClose(array, width);
}
fn fnNameComment(array: *Array, comptime src: builtin.SourceLocation) void {
    array.writeMany("// " ++ src.fn_name ++ "\n");
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
fn writeFieldAccess(array: *Array, what_field: []const u8) void {
    array.writeMany("cmd.");
    array.writeMany(what_field);
}
fn writeOpenCall(array: *Array, fn_name: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("write");
            array.writeMany(fn_name);
            array.writeMany("(array, ");
        },
        .length => {
            array.writeMany("len +%= length");
            array.writeMany(fn_name);
            array.writeMany("(");
        },
    }
}
fn writeCall0(
    array: *Array,
    fn_name: []const u8,
    width: *u64,
    what_field: []const u8,
    variant: Variant,
) void {
    array.writeMany(ws[0..width.*]);
    writeOpenCall(array, fn_name, variant);
    writeFieldAccess(array, what_field);
    array.writeMany(");\n");
}
fn writeCall1(
    array: *Array,
    fn_name: []const u8,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    variant: Variant,
) void {
    array.writeMany(ws[0..width.*]);
    writeOpenCall(array, fn_name, variant);
    writeFieldAccess(array, what_field);
    array.writeMany(", ");
    writeTerminatedArgument(array, what_switch, variant);
    array.writeMany(");\n");
}
fn writeCall2(
    array: *Array,
    fn_name: []const u8,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    array.writeMany(ws[0..width.*]);
    writeOpenCall(array, fn_name, variant);
    writeFieldAccess(array, what_field);
    array.writeMany(", ");
    writeTerminatedArgument(array, what_switch, variant);
    array.writeMany(", ");
    writeTerminatedArgument(array, what_not_switch, variant);
    array.writeMany(");\n");
}
fn writeCall3(
    array: *Array,
    fn_name: []const u8,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    array.writeMany(ws[0..width.*]);
    writeOpenCall(array, fn_name, variant);
    writeFieldAccess(array, what_field);
    array.writeMany(", ");
    writeEqualArgument(array, what_switch, variant);
    array.writeMany(", ");
    writeTerminatedArgument(array, what_switch, variant);
    array.writeMany(", ");
    writeTerminatedArgument(array, what_not_switch, variant);
    array.writeMany(");\n");
}
fn writeTerminatedArgument(array: *Array, what_switch: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("\"");
            array.writeMany(what_switch);
            array.writeMany("\\x00\"");
        },
        .length => {
            array.writeFormat(fmt.ud64(1 + what_switch.len + 2));
        },
    }
}
fn writeEqualArgument(array: *Array, what_switch: []const u8, variant: Variant) void {
    switch (variant) {
        .write => {
            array.writeMany("\"");
            array.writeMany(what_switch);
            array.writeMany("=\"");
        },
        .length => {
            array.writeFormat(fmt.ud64(1 + what_switch.len + 2));
        },
    }
}
fn writeCallHow(array: *Array, width: *u64, what_field: []const u8, variant: Variant) void {
    writeCall0(array, "How", width, what_field, variant);
}
fn writeCallWhat(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    variant: Variant,
) void {
    writeCall1(array, "What", width, what_field, what_switch, variant);
}
fn writeCallWhatHow(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    variant: Variant,
) void {
    writeCall1(array, "WhatHow", width, what_field, what_switch, variant);
}
fn writeCallWhatOrWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall2(array, "WhatOrWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallOptionalWhatOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall3(array, "OptionalWhatOptionalWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallOptionalWhatNonOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall3(array, "OptionalWhatNonOptionalWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallOptionalWhatNoArgWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall3(array, "OptionalWhatNoArgWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallNonOptionalWhatOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: ?[]const u8,
    variant: Variant,
) void {
    writeCall3(array, "NonOptionalWhatOptionalWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallNonOptionalWhatNonOptionalWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall3(array, "NonOptionalWhatNonOptionalWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
fn writeCallNonOptionalWhatNoArgWhatNot(
    array: *Array,
    width: *u64,
    what_field: []const u8,
    what_switch: []const u8,
    what_not_switch: []const u8,
    variant: Variant,
) void {
    writeCall2(array, "NonOptionalWhatNoArgWhatNot", width, what_field, what_switch, what_not_switch, variant);
}
pub fn writeFunctionBody(comptime options: []const OptionSpec, array: *Array, variant: Variant) void {
    var width: u64 = (initial_indent * 4) + 4;
    inline for (options) |opt_spec| {
        const what_field: []const u8 = opt_spec.name;
        const what_switch: ?[]const u8 = opt_spec.string;
        if (opt_spec.arg_type) |arg_type| {
            if (@typeInfo(arg_type) == .Optional) {
                if (opt_spec.and_no) |inverse| {
                    const what_not_switch: ?[]const u8 = inverse.*.string;
                    if (inverse.*.arg_type) |no_arg_type| {
                        if (@typeInfo(no_arg_type) == .Optional) {
                            if (prefer_inline) {
                                writeOptionalWhat(array, &width, what_field, what_switch, variant);
                                writeOptionalWhatNot(array, &width, what_not_switch, variant);
                            } else {
                                writeCallOptionalWhatOptionalWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                            }
                        } else {
                            if (prefer_inline) {
                                writeOptionalWhat(array, &width, what_field, what_switch, variant);
                                writeNonOptionalWhatNot(array, &width, what_not_switch, variant);
                            } else {
                                writeCallOptionalWhatNonOptionalWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                            }
                        }
                    } else {
                        if (prefer_inline) {
                            writeOptionalWhat(array, &width, what_field, what_switch, variant);
                            writeNoArgWhatNot(array, &width, what_not_switch, variant);
                        } else {
                            writeCallOptionalWhatNoArgWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                        }
                    }
                } else {
                    unhandledSpecification(what_field, opt_spec);
                }
            } else {
                if (opt_spec.and_no) |inverse| {
                    const what_not_switch: ?[]const u8 = inverse.*.string;
                    if (inverse.*.arg_type) |no_arg_type| {
                        if (@typeInfo(no_arg_type) == .Optional) {
                            if (prefer_inline) {
                                writeNonOptionalWhat(array, &width, what_field, what_switch, variant);
                                writeOptionalWhatNot(array, &width, what_not_switch, variant);
                            } else {
                                writeCallNonOptionalWhatOptionalWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                            }
                        } else {
                            if (prefer_inline) {
                                writeNonOptionalWhat(array, &width, what_field, what_switch, variant);
                                writeNonOptionalWhatNot(array, &width, what_not_switch, variant);
                            } else {
                                writeCallNonOptionalWhatNonOptionalWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                            }
                        }
                    } else {
                        if (prefer_inline) {
                            writeNonOptionalWhat(array, &width, what_field, what_switch, variant);
                            writeNoArgWhatNot(array, &width, what_not_switch, variant);
                        } else {
                            writeCallNonOptionalWhatNoArgWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                        }
                    }
                } else {
                    if (prefer_inline) {
                        writeWhatHow(array, &width, what_field, what_switch, variant);
                    } else {
                        if (what_switch) |yes_switch| {
                            writeCallWhatHow(array, &width, what_field, yes_switch, variant);
                        } else {
                            writeCallHow(array, &width, what_field, variant);
                        }
                    }
                }
            }
        } else {
            if (opt_spec.and_no) |inverse| {
                const what_not_switch: ?[]const u8 = inverse.*.string;
                if (inverse.*.arg_type != null) {
                    unhandledSpecification(what_field, opt_spec);
                } else {
                    if (prefer_inline) {
                        writeWhatOrWhatNot(array, &width, what_field, what_switch, what_not_switch, variant);
                    } else {
                        writeCallWhatOrWhatNot(array, &width, what_field, what_switch.?, what_not_switch.?, variant);
                    }
                }
            } else {
                if (prefer_inline) {
                    writeWhat(array, &width, what_field, what_switch, variant);
                } else {
                    writeCallWhat(array, &width, what_field, what_switch.?, variant);
                }
            }
        }
    }
}
pub fn writeStructMembers(comptime options: []const OptionSpec, array: *Array) void {
    const width: u64 = 4;
    inline for (options) |opt_spec| {
        const field_type: type = getOptType(opt_spec);
        const what_field: []const u8 = opt_spec.name;
        if (opt_spec.descr) |field_descr| {
            inline for (field_descr) |line| {
                array.writeMany(ws[0..width] ++ "/// " ++ line ++ "\n");
            }
        }
        array.writeMany(ws[0..width] ++ what_field ++ ": ");
        switch (@typeInfo(field_type)) {
            .Bool => {
                if (opt_spec.default_value) |default_value| {
                    array.writeMany(@typeName(field_type) ++ " = " ++ comptime builtin.fmt.cx(default_value) ++ ",\n");
                } else {
                    array.writeMany(@typeName(field_type) ++ " = false,\n");
                }
            },
            .Optional => |optional_info| {
                array.writeOne('?');
                if (opt_spec.arg_type_name) |type_name| {
                    if (!@hasDecl(types, type_name)) {
                        array.writeMany(type_name ++ " = null,\n");
                    } else {
                        const import_type: type = @field(types, type_name);
                        switch (@typeInfo(optional_info.child)) {
                            .Enum, .Struct, .Union => {
                                if (!@hasDecl(optional_info.child, "formatWrite")) {
                                    formatCompositeLiteral(array, optional_info.child, .{
                                        .import_type = ?import_type,
                                        .type_name = "?types." ++ type_name,
                                    });
                                } else {
                                    array.writeMany("types." ++ opt_spec.arg_type_name.?);
                                }
                                array.writeMany(" = null,\n");
                            },
                            else => {
                                array.writeMany(type_name ++ " = null,\n");
                            },
                        }
                    }
                } else {
                    switch (@typeInfo(optional_info.child)) {
                        .Enum, .Struct, .Union => {
                            if (!@hasDecl(optional_info.child, "formatWrite")) {
                                formatCompositeLiteral(array, optional_info.child, null);
                            } else {
                                array.writeMany(opt_spec.arg_type_name);
                            }
                            array.writeMany(" = null,\n");
                        },
                        else => {
                            array.writeMany(@typeName(optional_info.child) ++ " = null,\n");
                        },
                    }
                }
            },
            else => {
                if (opt_spec.arg_type_name) |type_name| {
                    if (!@hasDecl(types, type_name)) {
                        array.writeMany(type_name);
                    } else {
                        const import_type: type = @field(types, type_name);
                        switch (@typeInfo(field_type)) {
                            .Enum, .Struct, .Union => {
                                if (!@hasDecl(opt_spec.arg_type.?, "formatWrite")) {
                                    formatCompositeLiteral(array, field_type, .{
                                        .import_type = import_type,
                                        .type_name = "types." ++ type_name,
                                    });
                                } else {
                                    array.writeMany("types." ++ opt_spec.arg_type_name ++ ",\n");
                                }
                            },
                            else => {
                                array.writeMany("types." ++ type_name ++ ",\n");
                            },
                        }
                    }
                } else {
                    switch (@typeInfo(field_type)) {
                        .Enum, .Struct, .Union => {
                            if (!@hasDecl(field_type.child, "formatWrite")) {
                                formatCompositeLiteral(array, field_type, null);
                            } else {
                                array.writeMany("types." ++ opt_spec.arg_type_name ++ ",\n");
                            }
                        },
                        else => {
                            array.writeMany(@typeName(field_type) ++ ",\n");
                        },
                    }
                }
            },
        }
    }
}
const Options = struct {
    output: ?[:0]const u8 = null,
    pub const Map = proc.GenericOptions(Options);
    const about_output_s: []const u8 = "write to output to pathname";
    const pathname = .{ .argument = "pathname" };
};
fn srcArray(comptime count: usize, comptime pathname: [:0]const u8) !mem.StaticArray(count) {
    var ret: mem.StaticArray(count) = .{};
    const fd: u64 = try file.open(open_spec, builtin.absolutePath(pathname));
    defer file.close(.{}, fd);
    ret.define(try file.read(fd, ret.referAllUndefined(), count));
    return ret;
}
fn writeFile(allocator: Allocator, array: Array, pathname: [:0]const u8) !void {
    const build_fd: u64 = try file.create(.{ .options = .{ .exclusive = false } }, pathname, file.file_mode);
    try file.write(.{}, build_fd, array.readAll(allocator));
    try file.close(.{}, build_fd);
}
fn killIndent(src: []const u8) []const u8 {
    var idx: u64 = src.len;
    while (idx != 0) {
        idx -%= 1;
        if (src[idx] == '\n') {
            return src[0 .. idx + 1 :' '];
        }
    }
    unreachable;
}
const Split = struct {
    below: []const u8,
    above: []const u8,
};
pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator);
    defer array.deinit(&allocator);
    array.increment(&allocator, 1024 * 1024);

    var st: file.Status = try file.pathStatus(.{}, tasks_template_path);
    var fd: u64 = try file.open(.{}, tasks_template_path);
    array.define(try file.read(.{}, fd, array.referAllUndefined(allocator), st.size));
    try file.close(.{}, fd);

    array.writeMany("pub const BuildCommand = struct {\n");
    array.writeMany("    kind: OutputMode,\n");
    writeStructMembers(build_command_options, &array);
    array.writeMany("};\n");
    array.writeMany("pub const FormatCommand = struct {\n");
    writeStructMembers(format_command_options, &array);
    array.writeMany("};\n");
    try writeFile(allocator, array, tasks_path);
    array.undefineAll(allocator);

    st = try file.pathStatus(.{}, command_line_path);
    fd = try file.open(.{}, command_line_template_path);
    array.define(try file.read(.{}, fd, array.referAllUndefined(allocator), st.size));
    try file.close(.{}, fd);

    array.writeMany("pub fn buildLength(cmd: *const types.BuildCommand) u64 {\n");
    array.writeMany("    var len: u64 = 0;\n");
    writeFunctionBody(build_command_options, &array, .length);
    array.writeMany("    return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn buildWrite(cmd: *const types.BuildCommand, array: anytype) void {\n");
    writeFunctionBody(build_command_options, &array, .write);
    array.writeMany("}\n");
    array.writeMany("pub fn formatLength(cmd: *const types.FormatCommand) u64 {\n");
    array.writeMany("    var len: u64 = 0;\n");
    writeFunctionBody(format_command_options, &array, .length);
    array.writeMany("    return len;\n");
    array.writeMany("}\n");
    array.writeMany("pub fn formatWrite(cmd: *const types.FormatCommand, array: anytype) void {\n");
    writeFunctionBody(format_command_options, &array, .write);
    array.writeMany("}\n");
    try writeFile(allocator, array, command_line_path);
}
