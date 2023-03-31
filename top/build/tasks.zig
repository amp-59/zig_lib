const mem = @import("../mem.zig");
const preset = @import("../preset.zig");
const builtin = @import("../builtin.zig");
const types = @import("./types2.zig");

pub const OutputMode = enum {
    exe,
    lib,
    obj,
};
pub const RunCommand = struct {
    args: types.Args,
    pub fn addRunArgument(run_cmd: *RunCommand, allocator: *types.Allocator, any: anytype) void {
        run_cmd.args.appendAny(preset.reinterpret.fmt, allocator, any);
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
    color: ?enum(u2) { on = 0, off = 1, auto = 2 } = null, // T6
    emit_bin: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_asm: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_llvm_ir: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_llvm_bc: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_h: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_docs: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_analysis: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    emit_implib: ?union(enum) { yes: ?types.Path, no: void } = null, // T3
    cache_root: ?[]const u8 = null, // T7
    global_cache_root: ?[]const u8 = null, // T7
    zig_lib_dir: ?[]const u8 = null, // T7
    enable_cache: bool = true, // T0
    target: ?[]const u8 = null, // T7
    cpu: ?[]const u8 = null, // T7
    code_model: ?enum(u3) { default = 0, tiny = 1, small = 2, kernel = 3, medium = 4, large = 5 } = null, // T6
    red_zone: ?bool = null, // T7
    omit_frame_pointer: ?bool = null, // T7
    exec_model: ?[]const u8 = null, // T7
    name: ?[]const u8 = null, // T7
    mode: ?@TypeOf(builtin.zig.mode) = null, // T2
    main_pkg_path: ?[]const u8 = null, // T7
    pic: ?bool = null, // T7
    pie: ?bool = null, // T7
    lto: ?bool = null, // T7
    stack_check: ?bool = null, // T7
    sanitize_c: ?bool = null, // T7
    valgrind: ?bool = null, // T7
    sanitize_thread: ?bool = null, // T7
    dll_export_fns: ?bool = null, // T7
    unwind_tables: ?bool = null, // T7
    llvm: ?bool = null, // T7
    clang: ?bool = null, // T7
    reference_trace: ?bool = null, // T7
    error_trace: ?bool = null, // T7
    single_threaded: ?bool = null, // T7
    function_sections: ?bool = null, // T7
    strip: ?bool = null, // T7
    formatted_panics: ?bool = null, // T7
    fmt: ?enum(u4) { elf = 0, c = 1, wasm = 2, coff = 3, macho = 4, spirv = 5, plan9 = 6, hex = 7, raw = 8 } = null, // T6
    dirafter: ?[]const u8 = null, // T7
    system: ?[]const u8 = null, // T7
    include: ?[]const u8 = null, // T7
    libc: ?[]const u8 = null, // T7
    library: ?[]const u8 = null, // T7
    library_directory: ?[]const u8 = null, // T7
    link_script: ?[]const u8 = null, // T7
    version_script: ?[]const u8 = null, // T7
    dynamic_linker: ?[]const u8 = null, // T7
    sysroot: ?[]const u8 = null, // T7
    version: bool = false, // T1
    entry: ?[]const u8 = null, // T7
    soname: ?union(enum) { yes: []const u8, no: void } = null, // T6
    lld: ?bool = null, // T7
    compiler_rt: ?bool = null, // T7
    rpath: ?[]const u8 = null, // T7
    each_lib_rpath: ?bool = null, // T7
    allow_shlib_undefined: ?bool = null, // T7
    build_id: ?bool = null, // T7
    compress_debug_sections: ?enum(u1) { none = 0, zlib = 1 } = null, // T6
    gc_sections: ?bool = null, // T7
    stack: ?u64 = null, // T7
    image_base: ?u64 = null, // T7
    macros: ?[]const types.Macro = null, // T2
    modules: ?[]const types.Module = null, // T2
    dependencies: ?[]const types.ModuleDependency = null, // T2
    cflags: ?types.CFlags = null, // T3
    z: ?enum(u4) { nodelete = 0, notext = 1, defs = 2, origin = 3, nocopyreloc = 4, now = 5, lazy = 6, relro = 7, norelro = 8 } = null, // T6
    files: ?types.Files = null, // T3
    test_filter: ?[]const u8 = null, // T7
    test_name_prefix: ?[]const u8 = null, // T7
    test_cmd: bool = false, // T1
    test_cmd_bin: bool = false, // T1
    test_evented_io: bool = false, // T1
    test_no_exec: bool = false, // T1
};
pub const FormatCommand = struct {
    color: ?enum(u2) { auto = 0, off = 1, on = 2 } = null, // T6
    stdin: bool = false, // T1
    check: bool = false, // T1
    ast_check: bool = true, // T0
    exclude: ?[]const u8 = null, // T7
};
