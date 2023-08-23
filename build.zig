pub const zl = @import("./zig_lib.zig");
const spec = zl.spec;
const build = zl.build;
pub const Node = build.GenericNode(.{
    .options = .{ .max_thread_count = 8 },
});
const build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .omit_frame_pointer = false,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = false,
    .strip = true,
    .compiler_rt = false,
    .gc_sections = true,
    .image_base = 65536,
    .modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }},
    .dependencies = &.{.{ .name = "zig_lib" }},
};
const format_cmd: build.FormatCommand = .{
    .ast_check = true,
};
pub const enable_debugging: bool = false;
pub fn langGroup(allocator: *build.Allocator, group: *Node) void {
    var lang_build_cmd: build.BuildCommand = build_cmd;
    const slice_layout: *Node = group.addBuild(allocator, lang_build_cmd, "slice_layout", "test/lang/slice_layout.zig");
    slice_layout.descr = "Verify slice layout";
}
pub fn traceGroup(allocator: *build.Allocator, group: *Node) void {
    var trace_build_cmd: build.BuildCommand = build_cmd;
    trace_build_cmd.strip = false;
    const access_inactive: *Node = group.addBuild(allocator, trace_build_cmd, "access_inactive", "test/trace/access_inactive.zig");
    const assertion_failed: *Node = group.addBuild(allocator, trace_build_cmd, "assertion_failed", "test/trace/assertion_failed.zig");
    const out_of_bounds: *Node = group.addBuild(allocator, trace_build_cmd, "out_of_bounds", "test/trace/out_of_bounds.zig");
    const reach_unreachable: *Node = group.addBuild(allocator, trace_build_cmd, "reach_unreachable", "test/trace/reach_unreachable.zig");
    const sentinel_mismatch: *Node = group.addBuild(allocator, trace_build_cmd, "sentinel_mismatch", "test/trace/sentinel_mismatch.zig");
    const stack_overflow: *Node = group.addBuild(allocator, trace_build_cmd, "stack_overflow", "test/trace/stack_overflow.zig");
    const start_gt_end: *Node = group.addBuild(allocator, trace_build_cmd, "start_gt_end", "test/trace/start_gt_end.zig");
    const static_exe: *Node = group.addBuild(allocator, trace_build_cmd, "static_exe", "test/trace/static_exe.zig");
    trace_build_cmd.kind = .obj;
    trace_build_cmd.gc_sections = false;
    const static_obj: *Node = group.addBuild(allocator, trace_build_cmd, "static_obj", "test/trace/static_obj.zig");
    access_inactive.descr = "Test stack trace for accessing inactive union field (panicInactiveUnionField)";
    assertion_failed.descr = "Test stack trace for assertion failed";
    out_of_bounds.descr = "Test stack trace for out-of-bounds (panicOutOfBounds)";
    reach_unreachable.descr = "Test stack trace for reaching unreachable code";
    sentinel_mismatch.descr = "Test stack trace for sentinel mismatch (panicSentinelMismatch)";
    stack_overflow.descr = "Test stack trace for stack overflow";
    start_gt_end.descr = "Test stack trace for out-of-bounds (panicStartGreaterThanEnd)";
    static_exe.dependOn(allocator, static_obj);
}
pub fn testGroup(allocator: *build.Allocator, group: *Node) void {
    var test_build_cmd: build.BuildCommand = build_cmd;
    const decls: *Node = group.addBuild(allocator, test_build_cmd, "decls", "test/decl.zig");
    const builtin: *Node = group.addBuild(allocator, test_build_cmd, "builtin", "test/builtin.zig");
    const meta: *Node = group.addBuild(allocator, test_build_cmd, "meta", "test/meta.zig");
    const gen: *Node = group.addBuild(allocator, test_build_cmd, "gen", "test/gen.zig");
    const math: *Node = group.addBuild(allocator, test_build_cmd, "math", "test/math.zig");
    const file: *Node = group.addBuild(allocator, test_build_cmd, "file", "test/file.zig");
    const list: *Node = group.addBuild(allocator, test_build_cmd, "list", "test/list.zig");
    const fmt: *Node = group.addBuild(allocator, test_build_cmd, "fmt", "test/fmt.zig");
    const render: *Node = group.addBuild(allocator, test_build_cmd, "render", "test/render.zig");
    //const thread: *Node = group.addBuild(allocator, test_build_cmd, "thread", "test/thread.zig");
    const virtual: *Node = group.addBuild(allocator, test_build_cmd, "virtual", "test/virtual.zig");
    const time: *Node = group.addBuild(allocator, test_build_cmd, "time", "test/time.zig");
    const size: *Node = group.addBuild(allocator, test_build_cmd, "size", "test/size_per_config.zig");
    const parse: *Node = group.addBuild(allocator, test_build_cmd, "parse", "test/parse.zig");
    const crypto: *Node = group.addBuild(allocator, test_build_cmd, "crypto", "test/crypto.zig");
    const zig: *Node = group.addBuild(allocator, test_build_cmd, "zig", "test/zig.zig");
    const mem: *Node = group.addBuild(allocator, test_build_cmd, "mem", "test/mem.zig");
    mem.flags.want_stack_traces = true;
    const mem2: *Node = group.addBuild(allocator, test_build_cmd, "mem2", "test/mem2.zig");
    const x86: *Node = group.addBuild(allocator, test_build_cmd, "x86", "test/x86.zig");
    const proc: *Node = group.addBuild(allocator, test_build_cmd, "proc", "test/proc.zig");
    const rng: *Node = group.addBuild(allocator, test_build_cmd, "rng", "test/rng.zig");
    const ecdsa: *Node = group.addBuild(allocator, test_build_cmd, "ecdsa", "test/crypto/ecdsa.zig");
    const aead: *Node = group.addBuild(allocator, test_build_cmd, "aead", "test/crypto/aead.zig");
    const auth: *Node = group.addBuild(allocator, test_build_cmd, "auth", "test/crypto/auth.zig");
    const dh: *Node = group.addBuild(allocator, test_build_cmd, "dh", "test/crypto/dh.zig");
    const tls: *Node = group.addBuild(allocator, test_build_cmd, "tls", "test/crypto/tls.zig");
    const core: *Node = group.addBuild(allocator, test_build_cmd, "core", "test/crypto/core.zig");
    const utils: *Node = group.addBuild(allocator, test_build_cmd, "utils", "test/crypto/utils.zig");
    const hash: *Node = group.addBuild(allocator, test_build_cmd, "hash", "test/crypto/hash.zig");
    const pcurves: *Node = group.addBuild(allocator, test_build_cmd, "pcurves", "test/crypto/pcurves.zig");
    const cmdline_writer: *Node = group.addBuild(allocator, test_build_cmd, "cmdline_writer", "test/cmdline-writer.zig");
    const cmdline_parser: *Node = group.addBuild(allocator, test_build_cmd, "cmdline_parser", "test/cmdline-parser.zig");
    const algo: *Node = group.addBuild(allocator, test_build_cmd, "algo", "test/algo.zig");
    const fmt_cmp: *Node = group.addBuild(allocator, test_build_cmd, "fmt_cmp", "test/fmt_cmp.zig");
    test_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    test_build_cmd.dependencies = &.{.{ .name = "@build" }};
    const build_stress: *Node = group.addBuild(allocator, test_build_cmd, "build_stress", "test/build.zig");
    const elf: *Node = group.addBuild(allocator, test_build_cmd, "elf", "test/elf.zig");
    test_build_cmd.strip = false;
    const serial: *Node = group.addBuild(allocator, test_build_cmd, "serial", "test/serial.zig");
    const build_runner: *Node = group.addBuild(allocator, test_build_cmd, "build_runner", "build_runner.zig");
    const zls_build_runner: *Node = group.addBuild(allocator, test_build_cmd, "zls_build_runner", "zls_build_runner.zig");
    test_build_cmd.kind = .lib;
    test_build_cmd.mode = .ReleaseSmall;
    test_build_cmd.strip = false;
    test_build_cmd.dynamic = true;
    x86.flags.want_stack_traces = true;
    build_runner.flags.want_stack_traces = false;
    const test_writers: *Node = group.addBuild(allocator, test_build_cmd, "test_writers", "top/build/writers.zig");
    const test_parsers: *Node = group.addBuild(allocator, test_build_cmd, "test_parsers", "top/build/parsers.zig");
    test_build_cmd.strip = true;
    const test_symbols: *Node = group.addBuild(allocator, test_build_cmd, "test_symbols", "test/symbols.zig");
    langGroup(allocator, group.addGroup(allocator, "lang"));
    traceGroup(allocator, group.addGroup(allocator, "trace"));
    x86.descr = "Test x86 assembler/disassembler";
    decls.descr = "Test compilation of all public declarations recursively";
    builtin.descr = "Test builtin functions";
    meta.descr = "Test meta functions";
    gen.descr = "Test generic code generation functions";
    math.descr = "Test math functions";
    file.descr = "Test low level file system operation functions";
    list.descr = "Test library generic linked list";
    fmt.descr = "Test user formatting functions";
    render.descr = "Test library value rendering functions";
    //thread.descr = "Test clone and thread-safe compound/tagged sets";
    virtual.descr = "Test address spaces, sub address spaces, and arenas";
    time.descr = "Test time related functions";
    size.descr = "Test sizes of various things";
    parse.descr = "Test generic parsing function";
    crypto.descr = "Test crypto related functions";
    zig.descr = "Test Zig language related functions";
    mem.descr = "Test low level memory management functions and basic container/allocator usage";
    mem2.descr = "Test v2 low level memory implementation";
    proc.descr = "Test process related functions";
    rng.descr = "Test random number generation functions";
    ecdsa.descr = "Test ECDSA";
    aead.descr = "Test authenticated encryption functions and types";
    auth.descr = "Test authentication";
    dh.descr = "Test many 25519-related functions";
    tls.descr = "Test TLS";
    core.descr = "Test core crypto functions and types";
    utils.descr = "Test crypto utility functions";
    hash.descr = "Test hashing functions";
    pcurves.descr = "Test point curve operations";
    cmdline_writer.descr = "Test generated command line writer functions";
    cmdline_parser.descr = "Test generated command line parser functions";
    algo.descr = "Test sorting and compression functions";
    fmt_cmp.descr = "Compare formatting methods";
    build_stress.descr = "Try to produce builder errors";
    serial.descr = "Test data serialisation functions";
    build_runner.descr = "Test library build runner using the library build program";
    zls_build_runner.descr = "Test ZLS special build runner";
    elf.descr = "Test ELF iterator";
    cmdline_writer.addToplevelArgs(allocator);
    build_stress.addToplevelArgs(allocator);
    serial.addToplevelArgs(allocator);
    build_runner.addToplevelArgs(allocator);
    zls_build_runner.addToplevelArgs(allocator);
    elf.dependOn(allocator, test_symbols);
    elf.dependOn(allocator, test_parsers);
    elf.dependOn(allocator, test_writers);
}
pub fn userGroup(allocator: *build.Allocator, group: *Node) void {
    var user_build_cmd: build.BuildCommand = build_cmd;
    user_build_cmd.modules = &.{};
    user_build_cmd.dependencies = &.{};
    const std_lib_cfg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_cfg", "test/user/std_lib_cfg.zig");
    const _std_lib: *Node = group.addBuild(allocator, user_build_cmd, "_std_lib", "test/user/std_lib.zig");
    user_build_cmd.modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
    user_build_cmd.dependencies = &.{.{ .name = "zig_lib" }};
    const std_lib_cfg_pkg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_cfg_pkg", "test/user/std_lib_cfg_pkg.zig");
    const std_lib_pkg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_pkg", "test/user/std_lib_pkg.zig");
    std_lib_cfg.descr = "Standard builtin, with build configuration, without library package";
    _std_lib.descr = "Standard builtin, without build configuration, without library package";
    std_lib_cfg_pkg.descr = "Standard builtin, with build configuration, library package";
    std_lib_pkg.descr = "Standard builtin, without build configuration, with library package";
}
pub fn exampleGroup(allocator: *build.Allocator, group: *Node) void {
    var example_build_cmd: build.BuildCommand = build_cmd;
    example_build_cmd.mode = .ReleaseSmall;
    const extract: *Node = group.addBuild(allocator, example_build_cmd, "extract", "examples/extract.zig");
    const cp: *Node = group.addBuild(allocator, example_build_cmd, "cp", "examples/cp.zig");
    const readdir: *Node = group.addBuild(allocator, example_build_cmd, "readdir", "examples/dir_iterator.zig");
    const dynamic: *Node = group.addBuild(allocator, example_build_cmd, "dynamic", "examples/dynamic_alloc.zig");
    const @"addrspace": *Node = group.addBuild(allocator, example_build_cmd, "addrspace", "examples/addrspace.zig");
    const allocators: *Node = group.addBuild(allocator, example_build_cmd, "allocators", "examples/allocators.zig");
    const mca: *Node = group.addBuild(allocator, example_build_cmd, "mca", "examples/mca.zig");
    const itos: *Node = group.addBuild(allocator, example_build_cmd, "itos", "examples/itos.zig");
    const perf: *Node = group.addBuild(allocator, example_build_cmd, "perf", "examples/perf_events.zig");
    const pathsplit: *Node = group.addBuild(allocator, example_build_cmd, "pathsplit", "examples/pathsplit.zig");
    const declprint: *Node = group.addBuild(allocator, example_build_cmd, "declprint", "examples/declprint.zig");
    const treez: *Node = group.addBuild(allocator, example_build_cmd, "treez", "examples/treez.zig");
    const typefs: *Node = group.addBuild(allocator, example_build_cmd, "typefs", "examples/typefs.zig");
    example_build_cmd.mode = .Debug;
    example_build_cmd.strip = false;
    const statz: *Node = group.addBuild(allocator, example_build_cmd, "statz", "examples/statz.zig");
    extract.descr = "Extract named sections from binaries";
    cp.descr = "Shows copying from one file system path to another";
    readdir.descr = "Shows how to iterate directory entries";
    dynamic.descr = "Shows how to allocate dynamic memory";
    @"addrspace".descr = "Shows a complex custom address space";
    allocators.descr = "Shows how to use many allocators";
    mca.descr = "Example program useful for extracting section from assembly for machine code analysis";
    itos.descr = "Example program useful for converting between a variety of integer formats and bases";
    perf.descr = "Integrated performance";
    pathsplit.descr = "Useful for splitting paths into dirnames and basename";
    declprint.descr = "Useful for printing declarations";
    treez.descr = "Example program useful for listing the contents of directories in a tree-like format";
    typefs.descr = "Example program useful for generating type hierarchies from filesystems";
    statz.descr = "Build statistics file reader";
}
pub fn memgenGroup(allocator: *build.Allocator, group: *Node) void {
    var memgen_format_cmd: build.FormatCommand = format_cmd;
    memgen_format_cmd.ast_check = false;
    const impls = group.addGroup(allocator, "impls");
    impls.flags.is_hidden = true;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const impls_specs: *Node = impls.addBuild(allocator, impls_build_cmd, "specs", "top/mem/gen/specs.zig");
    const impls_ptr: *Node = impls.addBuild(allocator, impls_build_cmd, "ptr", "top/mem/gen/ptr_impls.zig");
    const impls_ctn: *Node = impls.addBuild(allocator, impls_build_cmd, "ctn", "top/mem/gen/ctn_impls.zig");
    const impls_alloc: *Node = impls.addBuild(allocator, impls_build_cmd, "alloc", "top/mem/gen/alloc_impls.zig");
    const generate: *Node = group.addFormat(allocator, memgen_format_cmd, "generate", "top/mem");
    impls_specs.descr = "Generate specification types for containers and pointers";
    impls_ptr.descr = "Generate reference implementations";
    impls_ctn.descr = "Generate container implementations";
    impls_alloc.descr = "Generate allocator implementations";
    impls_ptr.dependOnFull(allocator, .run, impls_specs, .run);
    impls_ctn.dependOnFull(allocator, .run, impls_specs, .run);
    impls_alloc.dependOnFull(allocator, .run, impls_specs, .run);
    generate.dependOnFull(allocator, .format, impls_ptr, .run);
    generate.dependOnFull(allocator, .format, impls_ctn, .run);
    generate.dependOnFull(allocator, .format, impls_alloc, .run);
}
pub fn regenGroup(allocator: *build.Allocator, group: *Node) void {
    var regen_format_cmd: build.FormatCommand = format_cmd;
    const impls = group.addGroup(allocator, "impls");
    impls.flags.is_hidden = true;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    impls_build_cmd.kind = .obj;
    impls_build_cmd.gc_sections = false;
    impls_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    impls_build_cmd.dependencies = &.{.{ .name = "@build" }};
    const impls_build_cmd_fn: *Node = impls.addBuild(allocator, impls_build_cmd, "build_cmd_fn", "top/build/build.h.zig");
    const impls_format_cmd_fn: *Node = impls.addBuild(allocator, impls_build_cmd, "format_cmd_fn", "top/build/format.h.zig");
    const impls_archive_cmd_fn: *Node = impls.addBuild(allocator, impls_build_cmd, "archive_cmd_fn", "top/build/archive.h.zig");
    const impls_objcopy_cmd_fn: *Node = impls.addBuild(allocator, impls_build_cmd, "objcopy_cmd_fn", "top/build/objcopy.h.zig");
    impls_build_cmd.kind = .exe;
    impls_build_cmd.gc_sections = true;
    const impls_rebuild: *Node = impls.addBuild(allocator, impls_build_cmd, "rebuild", "top/build/gen/rebuild_impls.zig");
    const format: *Node = group.addFormat(allocator, regen_format_cmd, "format", "top/build/rebuild.zig");
    impls_rebuild.descr = "Regenerate build program maybe adding new elements";
    format.descr = "Reformat regenerated build program into canonical form";
    impls_rebuild.addToplevelArgs(allocator);
    impls_rebuild.dependOn(allocator, impls_build_cmd_fn);
    impls_rebuild.dependOn(allocator, impls_format_cmd_fn);
    impls_rebuild.dependOn(allocator, impls_archive_cmd_fn);
    impls_rebuild.dependOn(allocator, impls_objcopy_cmd_fn);
    format.dependOnFull(allocator, .format, impls_rebuild, .run);
}
pub fn buildgenGroup(allocator: *build.Allocator, group: *Node) void {
    var buildgen_format_cmd: build.FormatCommand = format_cmd;
    const impls = group.addGroup(allocator, "impls");
    impls.flags.is_hidden = true;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const impls_tasks: *Node = impls.addBuild(allocator, impls_build_cmd, "tasks", "top/build/gen/tasks_impls.zig");
    const impls_hist_tasks: *Node = impls.addBuild(allocator, impls_build_cmd, "hist_tasks", "top/build/gen/hist_tasks_impls.zig");
    const impls_parsers: *Node = impls.addBuild(allocator, impls_build_cmd, "parsers", "top/build/gen/parsers_impls.zig");
    const impls_writers: *Node = impls.addBuild(allocator, impls_build_cmd, "writers", "top/build/gen/writers_impls.zig");
    const impls_libs: *Node = impls.addBuild(allocator, impls_build_cmd, "libs", "top/build/gen/libs_impls.zig");
    const format: *Node = group.addFormat(allocator, buildgen_format_cmd, "format", "top/build");
    impls_tasks.descr = "Generate builder command line data structures";
    impls_hist_tasks.descr = "Generate packed summary types for builder history";
    impls_parsers.descr = "Generate exports for builder task command line parser functions";
    impls_libs.descr = "Generate headers and exporters for dynamic loaded functions";
    format.descr = "Reformat generated source code into canonical form";
    impls_hist_tasks.dependOnFull(allocator, .build, impls_tasks, .run);
    impls_parsers.dependOnFull(allocator, .build, impls_hist_tasks, .run);
    impls_writers.dependOnFull(allocator, .build, impls_hist_tasks, .run);
    impls_libs.dependOnFull(allocator, .build, impls_parsers, .run);
    impls_libs.dependOnFull(allocator, .build, impls_writers, .run);
    format.dependOnFull(allocator, .format, impls_libs, .run);
}
pub fn targetgenGroup(allocator: *build.Allocator, group: *Node) void {
    var targetgen_format_cmd: build.FormatCommand = format_cmd;
    const impls = group.addGroup(allocator, "impls");
    impls.flags.is_hidden = true;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const impls_arch: *Node = impls.addBuild(allocator, impls_build_cmd, "arch", "top/target/gen/arch_impls.zig");
    const impls_target: *Node = impls.addBuild(allocator, impls_build_cmd, "target", "top/target/gen/target_impl.zig");
    const format: *Node = group.addFormat(allocator, targetgen_format_cmd, "format", "top/target");
    impls_arch.descr = "Generate target information for supported architectures";
    format.descr = "Reformat generated target information into canonical form";
    impls_target.dependOn(allocator, impls_arch);
    format.dependOnFull(allocator, .format, impls_target, .run);
}
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    testGroup(allocator, toplevel.addGroupWithTask(allocator, "test", .build));
    userGroup(allocator, toplevel.addGroupWithTask(allocator, "user", .build));
    exampleGroup(allocator, toplevel.addGroupWithTask(allocator, "example", .build));
    memgenGroup(allocator, toplevel.addGroupWithTask(allocator, "memgen", .format));
    regenGroup(allocator, toplevel.addGroupWithTask(allocator, "regen", .format));
    buildgenGroup(allocator, toplevel.addGroupWithTask(allocator, "buildgen", .format));
    targetgenGroup(allocator, toplevel.addGroupWithTask(allocator, "targetgen", .format));
}
pub fn install(b: *@import("std").Build.Builder) void {
    const run_install = b.addSystemCommand(&.{ "bash", zl.builtin.lib_root ++ "/support/install.sh" });
    b.default_step.dependOn(&run_install.step);
}
pub usingnamespace struct {
    pub const build = if (@hasDecl(@import("root"), "dependencies")) install else zl.build;
};
