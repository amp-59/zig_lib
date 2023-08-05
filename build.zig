pub const zl = @import("./zig_lib.zig");
const proc = zl.proc;
const spec = zl.spec;
const build = zl.build;
const debug = zl.debug;
const builtin = zl.builtin;

pub const Node = build.GenericNode(.{ .options = .{} });

const build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .image_base = 0x10000,
    .strip = true,
    .error_tracing = true,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .compiler_rt = false,
    .omit_frame_pointer = false,
    .dependencies = &.{.{ .name = "zig_lib" }},
    .modules = &.{.{ .name = "zig_lib", .path = build.root ++ "/zig_lib.zig" }},
};
const format_cmd: build.FormatCommand = .{ .ast_check = true };

fn setStripped(node: *Node) void {
    node.task.cmd.build.strip = true;
}
fn setSmall(node: *Node) void {
    node.task.cmd.build.mode = .ReleaseSmall;
    node.task.cmd.build.strip = true;
}
fn setFast(node: *Node) void {
    node.task.cmd.build.mode = .ReleaseFast;
    node.task.cmd.build.strip = true;
}
fn setDebug(node: *Node) void {
    node.task.cmd.build.mode = .Debug;
    node.task.cmd.build.strip = true;
}
fn addTracer(node: *Node) void {
    node.task.cmd.build.mode = .Debug;
    node.task.cmd.build.strip = false;
}
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) !void {
    tests(allocator, toplevel.addGroup(allocator, "tests"));
    useCaseTests(allocator, toplevel.addGroup(allocator, "use_case_tests"));
    examples(allocator, toplevel.addGroup(allocator, "examples"));
    memgen(allocator, toplevel.addGroup(allocator, "memgen"));
    regen(allocator, toplevel.addGroup(allocator, "regen"));
    buildgen(allocator, toplevel.addGroup(allocator, "buildgen"));
    targetgen(allocator, toplevel.addGroup(allocator, "targetgen"));
}
fn memgen(allocator: *build.Allocator, node: *Node) void {
    var mg_build_cmd: build.BuildCommand = build_cmd;
    mg_build_cmd.mode = .Debug;
    mg_build_cmd.strip = true;
    const mg_aux: *Node = node.addGroup(allocator, "_memgen");
    const mg_specs: *Node = mg_aux.addBuild(allocator, mg_build_cmd, "mg_specs", "top/mem/gen/specs.zig");
    const mg_ptr_impls: *Node = mg_aux.addBuild(allocator, mg_build_cmd, "mg_ptr_impls", "top/mem/gen/ptr_impls.zig");
    const mg_ctn_impls: *Node = mg_aux.addBuild(allocator, mg_build_cmd, "mg_ctn_impls", "top/mem/gen/ctn_impls.zig");
    const mg_alloc_impls: *Node = mg_aux.addBuild(allocator, mg_build_cmd, "mg_alloc_impls", "top/mem/gen/alloc_impls.zig");
    const mg_ctn_kinds: *Node = node.addFormat(allocator, format_cmd, "mg_ctn_kinds", "top/mem/gen/ctn_kinds.zig");
    const mg_ctn: *Node = node.addFormat(allocator, format_cmd, "mg_ctn", "top/mem/ctn.zig");
    const mg_ptr: *Node = node.addFormat(allocator, format_cmd, "mg_ptr", "top/mem/ptr.zig");
    const mg_alloc: *Node = node.addFormat(allocator, format_cmd, "mg_alloc", "top/mem/allocator.zig");
    mg_specs.descr = "Generate specification types for containers and pointers";
    mg_ptr_impls.descr = "Generate reference implementations";
    mg_ctn_impls.descr = "Generate container implementations";
    mg_alloc_impls.descr = "Generate allocator implementations";
    mg_ctn_kinds.descr = "Reformat generated container function kind switch functions into canonical form";
    mg_ptr.descr = "Reformat generated generic pointers into canonical form";
    mg_ctn.descr = "Reformat generated generic containers into canonical form";
    mg_alloc.descr = "Reformat generated generic allocators into canonical form";
    mg_ptr_impls.dependOn(allocator, mg_specs);
    mg_ctn_impls.dependOn(allocator, mg_specs);
    mg_alloc_impls.dependOn(allocator, mg_ptr_impls);
    mg_alloc.dependOnFull(allocator, .format, mg_alloc_impls, .run);
    mg_ptr.dependOnFull(allocator, .format, mg_ptr_impls, .run);
    mg_ctn.dependOnFull(allocator, .format, mg_ctn_impls, .run);
    mg_ctn_kinds.dependOnFull(allocator, .format, mg_specs, .run);
    mg_specs.task.cmd.build.mode = .Debug;
    mg_alloc.task.cmd.format.ast_check = false;
    node.task.tag = .format;
}
fn examples(allocator: *build.Allocator, node: *Node) void {
    var eg_build_cmd: build.BuildCommand = build_cmd;
    eg_build_cmd.kind = .exe;
    eg_build_cmd.strip = true;
    eg_build_cmd.mode = .ReleaseSmall;
    const readdir: *Node = node.addBuild(allocator, eg_build_cmd, "readdir", "examples/dir_iterator.zig");
    const dynamic: *Node = node.addBuild(allocator, eg_build_cmd, "dynamic", "examples/dynamic_alloc.zig");
    const custom: *Node = node.addBuild(allocator, eg_build_cmd, "addrspace", "examples/addrspace.zig");
    const allocators: *Node = node.addBuild(allocator, eg_build_cmd, "allocators", "examples/allocators.zig");
    const display: *Node = node.addBuild(allocator, eg_build_cmd, "display", "examples/display.zig");
    const mca: *Node = node.addBuild(allocator, eg_build_cmd, "mca", "examples/mca.zig");
    const itos: *Node = node.addBuild(allocator, eg_build_cmd, "itos", "examples/itos.zig");
    const catz: *Node = node.addBuild(allocator, eg_build_cmd, "catz", "examples/catz.zig");
    const statz: *Node = node.addBuild(allocator, eg_build_cmd, "statz", "examples/statz.zig");
    const perf: *Node = node.addBuild(allocator, eg_build_cmd, "perf", "examples/perf_events.zig");
    const cleanup: *Node = node.addBuild(allocator, eg_build_cmd, "cleanup", "examples/cleanup.zig");
    const hello: *Node = node.addBuild(allocator, eg_build_cmd, "hello", "examples/hello.zig");
    const pathsplit: *Node = node.addBuild(allocator, eg_build_cmd, "pathsplit", "examples/pathsplit.zig");
    const declprint: *Node = node.addBuild(allocator, eg_build_cmd, "declprint", "examples/declprint.zig");
    const pipeout: *Node = node.addBuild(allocator, eg_build_cmd, "pipeout", "examples/pipeout.zig");
    const treez: *Node = node.addBuild(allocator, eg_build_cmd, "treez", "examples/treez.zig");
    readdir.descr = "Shows how to iterate directory entries";
    dynamic.descr = "Shows how to allocate dynamic memory";
    custom.descr = "Shows a complex custom address space";
    allocators.descr = "Shows how to use many allocators";
    pipeout.descr = "Shows how to redirect child process output to file";
    display.descr = "Shows using `ioctl` to get display resources (idkso)";
    mca.descr = "Example program useful for extracting section from assembly for machine code analysis";
    statz.descr = "Build statistics file reader";
    treez.descr = "Example program useful for listing the contents of directories in a tree-like format";
    itos.descr = "Example program useful for converting between a variety of integer formats and bases";
    catz.descr = "Shows how to map and write a file to standard output";
    cleanup.descr = "Shows more advanced operations on a mapped file";
    hello.descr = "Shows various ways of printing 'Hello, world!'";
    declprint.descr = "Useful for printing declarations";
    pathsplit.descr = "Useful for splitting paths into dirnames and basename";
    perf.descr = "Integrated performance";
    statz.task.cmd.build.mode = .Debug;
    statz.task.cmd.build.strip = false;
    node.task.tag = .build;
}
fn useCaseTests(allocator: *build.Allocator, node: *Node) void {
    var uc_build_cmd: build.BuildCommand = build_cmd;
    const std_lib_cfg_pkg: *Node = node.addBuild(allocator, uc_build_cmd, "user_std_lib_cfg_pkg", "test/user/std_lib_cfg_pkg.zig");
    const std_lib_pkg: *Node = node.addBuild(allocator, uc_build_cmd, "user_std_lib_pkg", "test/user/std_lib_pkg.zig");
    const std_lib_cfg: *Node = node.addBuild(allocator, uc_build_cmd, "user_std_lib_cfg", "test/user/std_lib_cfg.zig");
    const std_lib: *Node = node.addBuild(allocator, uc_build_cmd, "user_std_lib", "test/user/std_lib.zig");
    std_lib_cfg_pkg.descr = "Standard builtin, with build configuration, library package";
    std_lib_cfg.descr = "Standard builtin, with build configuration, without library package";
    std_lib_pkg.descr = "Standard builtin, without build configuration, with library package";
    std_lib.descr = "Standard builtin, without build configuration, without library package";
    std_lib_pkg.flags.build.do_configure = false;
    std_lib.flags.build.do_configure = false;
    std_lib_cfg.task.cmd.build.dependencies = &.{};
    std_lib.task.cmd.build.dependencies = &.{};
    std_lib_cfg.task.cmd.build.modules = &.{};
    std_lib.task.cmd.build.modules = &.{};
    node.task.tag = .build;
}
fn tests(allocator: *build.Allocator, node: *Node) void {
    var quick_exe: build.BuildCommand = build_cmd;
    quick_exe.mode = .Debug;
    var debug_exe: build.BuildCommand = quick_exe;
    debug_exe.strip = false;
    var debug_obj: build.BuildCommand = debug_exe;
    debug_obj.kind = .obj;
    debug_obj.gc_sections = false;
    var builder_exe: build.BuildCommand = debug_exe;
    builder_exe.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    builder_exe.dependencies = &.{.{ .name = "@build" }};
    const decl_test: *Node = node.addBuild(allocator, build_cmd, "decl_test", "test/decl-test.zig");
    const builtin_test: *Node = node.addBuild(allocator, build_cmd, "builtin_test", "test/builtin-test.zig");
    const meta_test: *Node = node.addBuild(allocator, build_cmd, "meta_test", "test/meta-test.zig");
    const gen_test: *Node = node.addBuild(allocator, build_cmd, "gen_test", "test/gen-test.zig");
    const algo_test: *Node = node.addBuild(allocator, build_cmd, "algo_test", "test/algo-test.zig");
    const math_test: *Node = node.addBuild(allocator, build_cmd, "math_test", "test/math-test.zig");
    const file_test: *Node = node.addBuild(allocator, build_cmd, "file_test", "test/file-test.zig");
    const list_test: *Node = node.addBuild(allocator, build_cmd, "list_test", "test/list-test.zig");
    const fmt_test: *Node = node.addBuild(allocator, build_cmd, "fmt_test", "test/fmt-test.zig");
    const elf_test: *Node = node.addBuild(allocator, debug_exe, "elf_test", "test/elf-test.zig");
    const fmt_cmp_test: *Node = node.addBuild(allocator, build_cmd, "fmt_cmp_test", "test/fmt_cmp-test.zig");
    const render_test: *Node = node.addBuild(allocator, build_cmd, "render_test", "test/render-test.zig");
    const thread_test: *Node = node.addBuild(allocator, build_cmd, "thread_test", "test/thread-test.zig");
    const virtual_test: *Node = node.addBuild(allocator, build_cmd, "virtual_test", "test/virtual-test.zig");
    const time_test: *Node = node.addBuild(allocator, build_cmd, "time_test", "test/time-test.zig");
    const size_test: *Node = node.addBuild(allocator, build_cmd, "size_test", "test/size_per_config.zig");
    const parse_test: *Node = node.addBuild(allocator, build_cmd, "parse_test", "test/parse-test.zig");
    const crypto_test: *Node = node.addBuild(allocator, build_cmd, "crypto_test", "test/crypto-test.zig");
    const zig_test: *Node = node.addBuild(allocator, build_cmd, "zig_test", "test/zig-test.zig");
    const mem_test: *Node = node.addBuild(allocator, build_cmd, "mem_test", "test/mem-test.zig");
    const mem2_test: *Node = node.addBuild(allocator, build_cmd, "mem2_test", "test/mem2-test.zig");
    const proc_test: *Node = node.addBuild(allocator, build_cmd, "proc_test", "test/proc-test.zig");
    const debug_test: *Node = node.addBuild(allocator, debug_exe, "debug_test", "test/debug-test.zig");
    const debug2_test: *Node = node.addBuild(allocator, debug_obj, "debug2_test", "test/debug2-test.zig");
    const serial_test: *Node = node.addBuild(allocator, builder_exe, "serial_test", "test/serial-test.zig");
    builtin_test.descr = "Test builtin functions";
    elf_test.descr = "Test ELF iterator";
    mem_test.descr = "Test low level memory management functions and basic container/allocator usage";
    mem2_test.descr = "Test v2 low level memory implementation";
    gen_test.descr = "Test generic code generation functions";
    meta_test.descr = "Test meta functions";
    algo_test.descr = "Test sorting and compression functions";
    math_test.descr = "Test math functions";
    file_test.descr = "Test low level file system operation functions";
    list_test.descr = "Test library generic linked list";
    crypto_test.descr = "Test crypto related functions";
    fmt_test.descr = "Test user formatting functions";
    fmt_cmp_test.descr = "Compare formatting methods";
    parse_test.descr = "Test generic parsing function";
    proc_test.descr = "Test process related functions";
    render_test.descr = "Test library value rendering functions";
    time_test.descr = "Test time related functions";
    zig_test.descr = "Test Zig language related functions";
    decl_test.descr = "Test compilation of all public declarations recursively";
    serial_test.descr = "Test data serialisation functions";
    thread_test.descr = "Test clone and thread-safe compound/tagged sets";
    virtual_test.descr = "Test address spaces, sub address spaces, and arenas";
    size_test.descr = "Test sizes of various things";
    debug_test.descr = "Test debugging functions";
    algo_test.task.cmd.build.mode = .ReleaseFast;
    const rng_test: *Node = node.addBuild(allocator, build_cmd, "rng_test", "test/rng-test.zig");
    const ecdsa_test: *Node = node.addBuild(allocator, build_cmd, "ecdsa_test", "test/crypto/ecdsa-test.zig");
    const aead_test: *Node = node.addBuild(allocator, build_cmd, "aead_test", "test/crypto/aead-test.zig");
    const auth_test: *Node = node.addBuild(allocator, build_cmd, "auth_test", "test/crypto/auth-test.zig");
    const dh_test: *Node = node.addBuild(allocator, build_cmd, "dh_test", "test/crypto/dh-test.zig");
    const tls_test: *Node = node.addBuild(allocator, build_cmd, "tls_test", "test/crypto/tls-test.zig");
    const core_test: *Node = node.addBuild(allocator, build_cmd, "core_test", "test/crypto/core-test.zig");
    const utils_test: *Node = node.addBuild(allocator, build_cmd, "utils_test", "test/crypto/utils-test.zig");
    const hash_test: *Node = node.addBuild(allocator, build_cmd, "hash_test", "test/crypto/hash-test.zig");
    const pcurves_test: *Node = node.addBuild(allocator, build_cmd, "pcurves_test", "test/crypto/pcurves-test.zig");
    rng_test.descr = "Test random number generation functions";
    ecdsa_test.descr = "Test ECDSA";
    aead_test.descr = "Test authenticated encryption functions and types";
    auth_test.descr = "Test authentication";
    dh_test.descr = "Test many 25519-related functions";
    tls_test.descr = "Test TLS";
    core_test.descr = "Test core crypto functions and types";
    utils_test.descr = "Test crypto utility functions";
    hash_test.descr = "Test hashing functions";
    pcurves_test.descr = "Test point curve operations";
    const build_stress_test: *Node = node.addBuild(allocator, builder_exe, "build_stress_test", "test/build-test.zig");
    const build_runner_test: *Node = node.addBuild(allocator, builder_exe, "build_runner_test", "build_runner.zig");
    const zls_build_runner_test: *Node = node.addBuild(allocator, builder_exe, "zls_build_runner_test", "zls_build_runner.zig");
    const cmdline_writer_test: *Node = node.addBuild(allocator, quick_exe, "cmdline_writer_test", "test/cmdline-writer-test.zig");
    const cmdline_parser_test: *Node = node.addBuild(allocator, quick_exe, "cmdline_parser_test", "test/cmdline-parser-test.zig");
    build_runner_test.descr = "Test library build runner using the library build program";
    zls_build_runner_test.descr = "Test ZLS special build runner";
    cmdline_writer_test.descr = "Test generated command line writer functions";
    cmdline_parser_test.descr = "Test generated command line parser functions";
    build_stress_test.descr = "Try to produce builder errors";
    for ([_]*Node{
        build_runner_test,   zls_build_runner_test,
        cmdline_writer_test, serial_test,
        build_stress_test,
    }) |builder_test_node| {
        builder_test_node.addToplevelArgs(allocator);
    }
    build_stress_test.task.cmd.build.mode = .Debug;
    build_stress_test.task.cmd.build.strip = true;
    build_runner_test.flags.build.want_stack_traces = false;
    fmt_cmp_test.task.cmd.build.mode = .Debug;
    fmt_cmp_test.task.cmd.build.strip = true;
    fmt_cmp_test.task.cmd.build.emit_asm = .{ .yes = null };
    node.task.tag = .build;
    debug2_test.flags.do_update = true;
    debug_test.dependOnObject(allocator, debug2_test);
}
fn buildgen(allocator: *build.Allocator, node: *Node) void {
    var bg_build_cmd: build.BuildCommand = build_cmd;
    var bg_format_cmd: build.FormatCommand = format_cmd;
    bg_build_cmd.mode = .Debug;
    bg_build_cmd.strip = true;
    const bg_aux: *Node = node.addGroup(allocator, "_buildgen");
    const bg_tasks_impls: *Node = bg_aux.addBuild(allocator, bg_build_cmd, "bg_tasks_impls", "top/build/gen/tasks_impls.zig");
    const bg_tasks: *Node = node.addFormat(allocator, bg_format_cmd, "bg_tasks", "top/build/tasks.zig");
    const bg_hist_tasks_impls: *Node = bg_aux.addBuild(allocator, bg_build_cmd, "bg_hist_tasks_impls", "top/build/gen/hist_tasks_impls.zig");
    const bg_hist_tasks: *Node = node.addFormat(allocator, bg_format_cmd, "bg_hist_tasks", "top/build/hist_tasks.zig");
    const bg_parsers_impls: *Node = bg_aux.addBuild(allocator, bg_build_cmd, "bg_parsers_impls", "top/build/gen/parsers_impls.zig");
    const bg_parsers: *Node = node.addFormat(allocator, bg_format_cmd, "bg_parsers", "top/build/parsers.zig");
    bg_tasks.dependOnFull(allocator, .format, bg_tasks_impls, .run);
    bg_hist_tasks_impls.dependOn(allocator, bg_tasks);
    bg_hist_tasks.dependOnFull(allocator, .format, bg_hist_tasks_impls, .run);
    bg_parsers.dependOnFull(allocator, .format, bg_parsers_impls, .run);
    bg_tasks_impls.descr = "Generate builder command line data structures";
    bg_tasks.descr = "Reformat generated builder command line data structures into canonical form";
    bg_hist_tasks_impls.descr = "Generate packed summary types for builder history";
    bg_hist_tasks.descr = "Reformat generated history task data structures into canonical form";
    bg_parsers_impls.descr = "Generate exports for builder task command line parser functions";
    bg_parsers_impls.descr = "exports for builder task command line parser functions";
    bg_parsers.descr = "Reformat exports for builder task command line parser functions into canonical form";
    node.task.tag = .format;
}
fn regen(allocator: *build.Allocator, node: *Node) void {
    if (return) {}
    var rg_build_cmd: build.BuildCommand = build_cmd;
    var rg_format_cmd: build.FormatCommand = format_cmd;
    rg_build_cmd.mode = .Debug;
    rg_build_cmd.strip = true;
    const rg_aux: *Node = node.addGroup(allocator, "_regen");
    const rg_rebuild_impls: *Node = rg_aux.addBuild(allocator, rg_build_cmd, "rg_rebuild_impls", "top/build/gen/rebuild_impls.zig");
    const rg_rebuild: *Node = node.addFormat(allocator, rg_format_cmd, "rg_rebuild", "top/build/rebuild.zig");
    rg_rebuild_impls.dependOnArchive(allocator, Node.special.fmt);
    rg_rebuild_impls.addToplevelArgs(allocator);
    rg_rebuild.dependOnFull(allocator, .format, rg_rebuild_impls, .run);
    rg_rebuild_impls.descr = "Regenerate build program maybe adding new elements";
    rg_rebuild.descr = "Reformat regenerated build program into canonical form";
    node.task.tag = .format;
}
fn targetgen(allocator: *build.Allocator, node: *Node) void {
    var tg_build_cmd: build.BuildCommand = build_cmd;
    var tg_format_cmd: build.FormatCommand = format_cmd;
    tg_build_cmd.mode = .Debug;
    tg_build_cmd.strip = true;
    const tg_aux: *Node = node.addGroup(allocator, "_targetgen");
    const tg_arch_impls: *Node = tg_aux.addBuild(allocator, tg_build_cmd, "tg_arch_impls", "top/target/gen/arch_impls.zig");
    const tg_arch: *Node = node.addFormat(allocator, tg_format_cmd, "tg_arch", "top/target");
    const tg_target_impl: *Node = tg_aux.addBuild(allocator, tg_build_cmd, "tg_target_impl", "top/target/gen/target_impl.zig");
    const tg_target: *Node = node.addFormat(allocator, tg_format_cmd, "tg_target", "top/target.zig");
    tg_target_impl.dependOn(allocator, tg_arch_impls);
    tg_arch.dependOnFull(allocator, .format, tg_arch_impls, .run);
    tg_target.dependOnFull(allocator, .format, tg_target_impl, .run);
    tg_arch_impls.descr = "Generate target information for supported architectures";
    tg_arch.descr = "Reformat generated builder command line data structures into canonical form";
    node.task.tag = .format;
}
