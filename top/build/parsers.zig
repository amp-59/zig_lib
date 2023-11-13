const mem = @import("../mem.zig");
const debug = @import("../debug.zig");
const parse = @import("../parse.zig");
const builtin = @import("../builtin.zig");
const tasks = @import("tasks.zig");
const types = @import("types.zig");
pub usingnamespace @import("../start.zig");
export fn formatParseArgsBuildCommand(cmd: *tasks.BuildCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
        if (mem.testEqualString("-femit-bin", arg[0..@min(arg.len, 10)])) {
            if (arg.len > 11 and arg[10] == '=') {
                cmd.emit_bin = .{ .yes = types.Path.formatParseArgs(
                    allocator,
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
                    args[0..args_len],
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
            if (args_idx == args_len) {
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
        } else if (mem.testEqualString("-O", arg[0..@min(arg.len, 2)])) {
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
        } else if (mem.testEqualString("-fopt-bisect-limit", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.passes = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
            } else {
                return;
            }
        } else if (mem.testEqualString("--main-mod-path", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
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
        } else if (mem.testEqualString("-I", arg[0..@min(arg.len, 2)])) {
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
        } else if (mem.testEqualString("-fentry", arg)) {
            args_idx +%= 1;
            if (args_idx == args_len) {
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
            if (args_idx != args_len) {
                cmd.stack = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
            } else {
                return;
            }
        } else if (mem.testEqualString("--image-base", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
                cmd.image_base = parse.noexcept.unsigned(mem.terminate(args[args_idx], 0));
            } else {
                return;
            }
        } else if (mem.testEqualString("-D", arg[0..@min(arg.len, 2)])) {
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
        } else if (mem.testEqualString("--deps", arg)) {
            cmd.dependencies = types.ModuleDependencies.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
        } else if (mem.testEqualString("-cflags", arg)) {
            cmd.cflags = types.ExtraFlags.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
        } else if (mem.testEqualString("-rcflags", arg)) {
            cmd.rcflags = types.ExtraFlags.formatParseArgs(allocator, args[0..args_len], &args_idx, arg);
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
            if (args_idx != args_len) {
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
export fn formatParseArgsArchiveCommand(cmd: *tasks.ArchiveCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
        } else {
            debug.write(archive_help);
        }
        _ = allocator;
    }
}
export fn formatParseArgsObjcopyCommand(cmd: *tasks.ObjcopyCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
        } else if (mem.testEqualString("--pad-to", arg)) {
            args_idx +%= 1;
            if (args_idx != args_len) {
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
        } else {
            debug.write(objcopy_help);
        }
        _ = allocator;
    }
}
export fn formatParseArgsFormatCommand(cmd: *tasks.FormatCommand, allocator: *types.Allocator, args: [*][*:0]u8, args_len: usize) void {
    @setRuntimeSafety(builtin.is_safe);
    var args_idx: usize = 0;
    while (args_idx != args_len) : (args_idx +%= 1) {
        var arg: [:0]u8 = mem.terminate(args[args_idx], 0);
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
        } else {
            debug.write(format_help);
        }
        _ = allocator;
    }
}
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
