const mem = @import("../mem.zig");
const types = @import("./types.zig");
pub usingnamespace @import("../start.zig");
export fn build(cmd: *types.BuildCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("-femit-bin", arg[0..10])) {
            if (arg.len > 11 and arg[10] == '=') {
                cmd.emit_bin = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[11..]) };
            } else {
                cmd.emit_bin = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-bin", arg)) {
            cmd.emit_bin = .no;
        } else if (mem.testEqualString("-femit-asm", arg[0..10])) {
            if (arg.len > 11 and arg[10] == '=') {
                cmd.emit_asm = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[11..]) };
            } else {
                cmd.emit_asm = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-asm", arg)) {
            cmd.emit_asm = .no;
        } else if (mem.testEqualString("-femit-llvm-ir", arg[0..14])) {
            if (arg.len > 15 and arg[14] == '=') {
                cmd.emit_llvm_ir = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[15..]) };
            } else {
                cmd.emit_llvm_ir = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-llvm-ir", arg)) {
            cmd.emit_llvm_ir = .no;
        } else if (mem.testEqualString("-femit-llvm-bc", arg[0..14])) {
            if (arg.len > 15 and arg[14] == '=') {
                cmd.emit_llvm_bc = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[15..]) };
            } else {
                cmd.emit_llvm_bc = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-llvm-bc", arg)) {
            cmd.emit_llvm_bc = .no;
        } else if (mem.testEqualString("-femit-h", arg[0..8])) {
            if (arg.len > 9 and arg[8] == '=') {
                cmd.emit_h = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[9..]) };
            } else {
                cmd.emit_h = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-h", arg)) {
            cmd.emit_h = .no;
        } else if (mem.testEqualString("-femit-docs", arg[0..11])) {
            if (arg.len > 12 and arg[11] == '=') {
                cmd.emit_docs = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[12..]) };
            } else {
                cmd.emit_docs = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-docs", arg)) {
            cmd.emit_docs = .no;
        } else if (mem.testEqualString("-femit-analysis", arg[0..15])) {
            if (arg.len > 16 and arg[15] == '=') {
                cmd.emit_analysis = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[16..]) };
            } else {
                cmd.emit_analysis = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-analysis", arg)) {
            cmd.emit_analysis = .no;
        } else if (mem.testEqualString("-femit-implib", arg[0..13])) {
            if (arg.len > 14 and arg[13] == '=') {
                cmd.emit_implib = .{ .yes = types.Path.formatParseArgs(allocator, args[0..args_len], &args_idx, arg[14..]) };
            } else {
                cmd.emit_implib = .{ .yes = null };
            }
        } else if (mem.testEqualString("-fno-emit-implib", arg)) {
            cmd.emit_implib = .no;
        } else if (mem.testEqualString("--cache-dir", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.cache_root = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--global-cache-dir", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.global_cache_root = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--zig-lib-dir", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.zig_lib_root = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--listen", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.target = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-mcpu", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.cpu = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-mcmodel", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.exec_model = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--name", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.name = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-fsoname", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
                return;
            }
            arg = mem.terminate(args[args_idx], 0);
            cmd.soname = .{ .yes = arg };
        } else if (mem.testEqualString("-fno-soname", arg)) {
            cmd.soname = .no;
        } else if (mem.testEqualString("-O", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
        } else if (mem.testEqualString("--main-pkg-path", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.main_pkg_path = mem.terminate(args[args_idx], 0);
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
        } else if (mem.testEqualString("-fLLVM", arg)) {
            cmd.llvm = true;
        } else if (mem.testEqualString("-fno-LLVM", arg)) {
            cmd.llvm = false;
        } else if (mem.testEqualString("-fClang", arg)) {
            cmd.clang = true;
        } else if (mem.testEqualString("-fno-Clang", arg)) {
            cmd.clang = false;
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
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.dirafter = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-isystem", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.system = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--libc", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.libc = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--library", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.library = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-I", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
            if (args_idx == args_len) {
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
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.link_script = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--version-script", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.version_script = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--dynamic-linker", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.dynamic_linker = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--sysroot", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.sysroot = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--entry", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.entry = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("-fLLD", arg)) {
            cmd.lld = true;
        } else if (mem.testEqualString("-fno-LLD", arg)) {
            cmd.lld = false;
        } else if (mem.testEqualString("-fcompiler-rt", arg)) {
            cmd.compiler_rt = true;
        } else if (mem.testEqualString("-fno-compiler-rt", arg)) {
            cmd.compiler_rt = false;
        } else if (mem.testEqualString("-rpath", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
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
            if (args_idx == args_len) {
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
        } else if (mem.testEqualString("--gc-sections", arg)) {
            cmd.gc_sections = true;
        } else if (mem.testEqualString("--no-gc-sections", arg)) {
            cmd.gc_sections = false;
        } else if (mem.testEqualString("-D", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
                dest[src.len] = types.Macro.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
                cmd.macros = dest[0 .. src.len +% 1];
            } else {
                const dest: [*]types.Macro = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(types.Macro),
                    @alignOf(types.Macro),
                ));
                dest[0] = types.Macro.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
                cmd.macros = dest[0..1];
            }
        } else if (mem.testEqualString("--mod", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
                return;
            }
            arg = mem.terminate(args[args_idx], 0);
            if (cmd.modules) |src| {
                const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(types.Module) *% (src.len +% 1),
                    @alignOf(types.Module),
                ));
                @memcpy(dest, src);
                dest[src.len] = types.Module.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
                cmd.modules = dest[0 .. src.len +% 1];
            } else {
                const dest: [*]types.Module = @ptrFromInt(allocator.allocateRaw(
                    @sizeOf(types.Module),
                    @alignOf(types.Module),
                ));
                dest[0] = types.Module.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
                cmd.modules = dest[0..1];
            }
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
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.debug_log = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--debug-compile-errors", arg)) {
            cmd.debug_compiler_errors = true;
        } else if (mem.testEqualString("--debug-link-snapshot", arg)) {
            cmd.debug_link_snapshot = true;
        }
    }
}
export fn format(cmd: *types.FormatCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("--color", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.exclude = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        }
        _ = allocator;
    }
}
export fn archive(cmd: *types.ArchiveCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("--format", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
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
        }
        _ = allocator;
    }
}
export fn objcopy(cmd: *types.ObjcopyCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("--output-target", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.output_target = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--only-section", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.only_section = mem.terminate(args[args_idx], 0);
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
            if (args_idx != args_len) {
                cmd.add_gnu_debuglink = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        } else if (mem.testEqualString("--extract-to", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.extract_to = mem.terminate(args[args_idx], 0);
            } else {
                return;
            }
        }
        _ = allocator;
    }
}
export fn tblgen(cmd: *types.TableGenCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("--color", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
        } else if (mem.testEqualString("-I", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
        } else if (mem.testEqualString("-d", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
        } else if (mem.testEqualString("-o", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
            } else {
                arg = arg[2..];
            }
            cmd.output = arg;
        }
    }
}
export fn harec(cmd: *types.HarecCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(false);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]const u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("-a", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
            } else {
                arg = arg[2..];
            }
            cmd.arch = arg;
        } else if (mem.testEqualString("-o", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
                    return;
                }
                arg = mem.terminate(args[args_idx], 0);
            } else {
                arg = arg[2..];
            }
            cmd.output = arg;
        } else if (mem.testEqualString("-T", arg[0..2])) {
            if (arg.len == 2) {
                args_idx +%= 1;
                if (args_idx == args_len) {
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
        }
    }
}
const build_help: [*:0]const u8 = 
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
    \\    --main-pkg-path                 Set the directory of the root package
    \\    -f[no-]PIC                      Enable Position Independent Code
    \\    -f[no-]PIE                      Enable Position Independent Executable
    \\    -f[no-]lto                      Enable Link Time Optimization
    \\    -f[no-]stack-check              Enable stack probing in unsafe builds
    \\    -f[no-]stack-protector          Enable stack protection in unsafe builds
    \\    -f[no-]sanitize-c               Enable C undefined behaviour detection in unsafe builds
    \\    -f[no-]valgrind                 Include valgrind client requests in release builds
    \\    -f[no-]sanitize-thread          Enable thread sanitizer
    \\    -f[no-]unwind-tables            Always produce unwind table entries for all functions
    \\    -f[no-]LLVM                     Use LLVM as the codegen backend
    \\    -f[no-]Clang                    Use Clang as the C/C++ compilation backend
    \\    -f[no-]reference-trace          How many lines of reference trace should be shown per compile error
    \\    -f[no-]error-tracing            Enable error tracing in `ReleaseFast` mode
    \\    -f[no-]single-threaded          Code assumes there is only one thread
    \\    -f[no-]function-sections        Places each function in a separate sections
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
    \\    -f[no-]LLD                      Use LLD as the linker
    \\    -f[no-]compiler-rt              (default) Include compiler-rt symbols in output
    \\    -rpath                          Add directory to the runtime library search path
    \\    -f[no-]each-lib-rpath           Ensure adding rpath for each used dynamic library
    \\    -f[no-]allow-shlib-undefined    Allow undefined symbols in shared libraries
    \\    --build-id                      Help coordinate stripped binaries with debug symbols
    \\    --[no-]gc-sections              Force removal of functions and data that are unreachable
    \\                                    by the entry point or exported symbols
    \\    --stack                         Override default stack size
    \\    --image-base                    Set base address for executable image
    \\    -D                              Define C macros available within the `@cImport` namespace
    \\    --mod                           Define modules available as dependencies for the current target
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
;
const format_help: [*:0]const u8 = 
    \\    fmt
    \\    --color         Enable or disable colored error messages
    \\    --stdin         Format code from stdin; output to stdout
    \\    --check         List non-conforming files and exit with an error if the list is non-empty
    \\    --ast-check     Run zig ast-check on every file
    \\    --exclude       Exclude file or directory from formatting
;
const archive_help: [*:0]const u8 = 
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
;
const objcopy_help: [*:0]const u8 = 
    \\    objcopy
    \\    --output-target
    \\    --only-section
    \\    --pad-to
    \\    --strip-debug
    \\    --strip-all
    \\    --only-keep-debug
    \\    --add-gnu-debuglink
    \\    --extract-to
;
const tblgen_help: [*:0]const u8 = 
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
;
const harec_help: [*:0]const u8 = 
    \\    -a
    \\    -o      Output file
    \\    -T
    \\    -t
    \\    -N
;
