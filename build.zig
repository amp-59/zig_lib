pub const srg = @import("./zig_lib.zig");
const proc = srg.proc;
const spec = srg.spec;
const build = srg.build;
const builtin = srg.builtin;

pub const Node = build.GenericNode(.{});
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

var build_cmd: build.tasks.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .stack_check = false,
    .stack_protector = false,
    .image_base = 0x10000,
    .strip = true,
    .compiler_rt = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .omit_frame_pointer = false,
};
const format_cmd: build.tasks.FormatCommand = .{
    .ast_check = true,
};
fn setSmall(node: *Node) void {
    node.task.info.build.mode = .ReleaseSmall;
    node.task.info.build.strip = true;
}
fn setFast(node: *Node) void {
    node.task.info.build.mode = .ReleaseFast;
    node.task.info.build.strip = true;
}
fn setDebug(node: *Node) void {
    node.task.info.build.mode = .Debug;
    node.task.info.build.strip = true;
}
fn addTracer(node: *Node) void {
    node.task.info.build.mode = .Debug;
    node.task.info.build.strip = false;
}
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) !void {
    tests(allocator, toplevel.addGroup(allocator, "tests"));
    examples(allocator, toplevel.addGroup(allocator, "examples"));
    memgen(allocator, toplevel.addGroup(allocator, "memgen"));
    buildgen(allocator, toplevel.addGroup(allocator, "buildgen"));
}
fn memgen(allocator: *build.Allocator, node: *Node) void {
    const mg_aux: *Node = node.addGroup(allocator, "_memgen");
    const mg_specs: *Node = mg_aux.addBuild(allocator, build_cmd, "mg_specs", "top/mem/gen/specs.zig");
    const mg_ptr_impls: *Node = mg_aux.addBuild(allocator, build_cmd, "mg_ptr_impls", "top/mem/gen/ptr_impls.zig");
    const mg_ctn_impls: *Node = mg_aux.addBuild(allocator, build_cmd, "mg_ctn_impls", "top/mem/gen/ctn_impls.zig");
    const mg_alloc_impls: *Node = mg_aux.addBuild(allocator, build_cmd, "mg_alloc_impls", "top/mem/gen/alloc_impls.zig");
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
    mg_alloc_impls.dependOn(allocator, mg_specs, .run);
    mg_ptr_impls.dependOn(allocator, mg_specs, .run);
    mg_ctn_impls.dependOn(allocator, mg_specs, .run);
    mg_alloc.dependOn(allocator, mg_alloc_impls, .run);
    mg_ptr.dependOn(allocator, mg_ptr_impls, .run);
    mg_ctn.dependOn(allocator, mg_ctn_impls, .run);
    mg_ctn_kinds.dependOn(allocator, mg_specs, .run);
    mg_specs.task.info.build.mode = .Debug;
    node.task.tag = .format;
}
fn examples(allocator: *build.Allocator, node: *Node) void {
    build_cmd.kind = .exe;
    build_cmd.strip = true;
    build_cmd.mode = .ReleaseSmall;
    const readdir: *Node = node.addBuild(allocator, build_cmd, "readdir", "examples/dir_iterator.zig");
    const dynamic: *Node = node.addBuild(allocator, build_cmd, "dynamic", "examples/dynamic_alloc.zig");
    const custom: *Node = node.addBuild(allocator, build_cmd, "addrspace", "examples/addrspace.zig");
    const allocators: *Node = node.addBuild(allocator, build_cmd, "allocators", "examples/allocators.zig");
    const display: *Node = node.addBuild(allocator, build_cmd, "display", "examples/display.zig");
    const mca: *Node = node.addBuild(allocator, build_cmd, "mca", "examples/mca.zig");
    const treez: *Node = node.addBuild(allocator, build_cmd, "treez", "examples/treez.zig");
    const itos: *Node = node.addBuild(allocator, build_cmd, "itos", "examples/itos.zig");
    const catz: *Node = node.addBuild(allocator, build_cmd, "catz", "examples/catz.zig");
    const statz: *Node = node.addBuild(allocator, build_cmd, "statz", "examples/statz.zig");
    const perf: *Node = node.addBuild(allocator, build_cmd, "perf", "examples/perf_events.zig");
    const cleanup: *Node = node.addBuild(allocator, build_cmd, "cleanup", "examples/cleanup.zig");
    const hello: *Node = node.addBuild(allocator, build_cmd, "hello", "examples/hello.zig");
    const pathsplit: *Node = node.addBuild(allocator, build_cmd, "pathsplit", "examples/pathsplit.zig");
    const declprint: *Node = node.addBuild(allocator, build_cmd, "declprint", "examples/declprint.zig");
    readdir.descr = "Shows how to iterate directory entries";
    dynamic.descr = "Shows how to allocate dynamic memory";
    custom.descr = "Shows a complex custom address space";
    allocators.descr = "Shows how to use many allocators";
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
    statz.task.info.build.mode = .Debug;
    statz.task.info.build.strip = false;
    node.task.tag = .build;
}
fn tests(allocator: *build.Allocator, node: *Node) void {
    const debug_exe = spec.add(build_cmd, .{ .mode = .Debug, .strip = false });
    const debug_obj = spec.add(debug_exe, .{ .kind = .obj, .gc_sections = false });
    const builder_exe = spec.add(debug_exe, .{
        .modules = &.{.{ .name = "@build", .path = "./build.zig" }},
        .dependencies = &.{.{ .name = "@build" }},
    });
    const decl_test: *Node = node.addBuild(allocator, build_cmd, "decl_test", "test/decl-test.zig");
    const builtin_test: *Node = node.addBuild(allocator, build_cmd, "builtin_test", "test/builtin-test.zig");
    addTracer(builtin_test);
    const meta_test: *Node = node.addBuild(allocator, build_cmd, "meta_test", "test/meta-test.zig");
    const gen_test: *Node = node.addBuild(allocator, build_cmd, "gen_test", "test/gen-test.zig");
    const algo_test: *Node = node.addBuild(allocator, build_cmd, "algo_test", "test/algo-test.zig");
    const math_test: *Node = node.addBuild(allocator, build_cmd, "math_test", "test/math-test.zig");
    const file_test: *Node = node.addBuild(allocator, build_cmd, "file_test", "test/file-test.zig");
    const list_test: *Node = node.addBuild(allocator, build_cmd, "list_test", "test/list-test.zig");
    const fmt_test: *Node = node.addBuild(allocator, build_cmd, "fmt_test", "test/fmt-test.zig");
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
    const build_stress_test: *Node = node.addBuild(allocator, builder_exe, "build_stress_test", "test/build-test.zig");
    const build_runner_test: *Node = node.addBuild(allocator, builder_exe, "build_runner_test", "build_runner.zig");
    const zls_build_runner_test: *Node = node.addBuild(allocator, builder_exe, "zls_build_runner_test", "zls_build_runner.zig");
    const cmdline_writer_test: *Node = node.addBuild(allocator, builder_exe, "cmdline_test", "test/cmdline-test.zig");
    const serial_test: *Node = node.addBuild(allocator, builder_exe, "serial_test", "test/serial-test.zig");
    builtin_test.descr = "Test builtin functions";
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
    build_runner_test.descr = "Test library build runner using the library build program";
    zls_build_runner_test.descr = "Test ZLS special build runner";
    cmdline_writer_test.descr = "Test generated command line writer functions";
    build_stress_test.descr = "Try to produce builder errors";
    algo_test.task.info.build.mode = .ReleaseFast;
    cryptoTests(allocator, node.addGroup(allocator, "crypto_tests"));
    for ([_]*Node{
        build_runner_test,
        zls_build_runner_test,
        cmdline_writer_test,
        serial_test,
        build_stress_test,
    }) |target| {
        target.addToplevelArgs(allocator);
    }
    node.task.tag = .build;
    addTracer(proc_test);
    debug2_test.flags.do_update = true;
    debug_test.dependOnObject(allocator, debug2_test);
}
fn cryptoTests(allocator: *build.Allocator, node: *Node) void {
    const mode_save: ?builtin.Mode = build_cmd.mode;
    const strip_save: ?bool = build_cmd.strip;
    build_cmd.mode = .Debug;
    build_cmd.strip = true;
    defer {
        build_cmd.mode = mode_save;
        build_cmd.strip = strip_save;
    }
    const rng_test: *Node = node.addBuild(allocator, build_cmd, "rng_test", "test/rng-test.zig");
    //const kyber_test: *Node = node.addBuild(allocator, build_cmd, "kyber_test", "test/crypto/kyber-test.zig");
    const ecdsa_test: *Node = node.addBuild(allocator, build_cmd, "ecdsa_test", "test/crypto/ecdsa-test.zig");
    //const aead_test: *Node = node.addBuild(allocator, build_cmd, "aead_test", "test/crypto/aead-test.zig");
    //const auth_test: *Node = node.addBuild(allocator, build_cmd, "auth_test", "test/crypto/auth-test.zig");
    const dh_test: *Node = node.addBuild(allocator, build_cmd, "dh_test", "test/crypto/dh-test.zig");
    //const tls_test: *Node = node.addBuild(allocator, build_cmd, "tls_test", "test/crypto/tls-test.zig");
    const core_test: *Node = node.addBuild(allocator, build_cmd, "core_test", "test/crypto/core-test.zig");
    const utils_test: *Node = node.addBuild(allocator, build_cmd, "utils_test", "test/crypto/utils-test.zig");
    const hash_test: *Node = node.addBuild(allocator, build_cmd, "hash_test", "test/crypto/hash-test.zig");
    const pcurves_test: *Node = node.addBuild(allocator, build_cmd, "pcurves_test", "test/crypto/pcurves-test.zig");
    rng_test.descr = "Test random number generation functions";
    //kyber_test.descr = "Test post-quantum 'Kyber' key exchange functions and types";
    ecdsa_test.descr = "Test ECDSA";
    //aead_test.descr = "Test authenticated encryption functions and types";
    //auth_test.descr = "Test authentication";
    dh_test.descr = "Test many 25519-related functions";
    //tls_test.descr = "Test TLS";
    core_test.descr = "Test core crypto functions and types";
    utils_test.descr = "Test crypto utility functions";
    hash_test.descr = "Test hashing functions";
    pcurves_test.descr = "Test point curve operations";
}
fn buildgen(allocator: *build.Allocator, node: *Node) void {
    const bg_aux: *Node = node.addGroup(allocator, "_buildgen");
    const bg_tasks_impls: *Node = bg_aux.addBuild(allocator, build_cmd, "bg_tasks_impls", "top/build/gen/tasks_impls.zig");
    const bg_tasks: *Node = node.addFormat(allocator, format_cmd, "bg_tasks", "top/build/tasks.zig");
    bg_tasks.dependOn(allocator, bg_tasks_impls, .run);
    bg_tasks_impls.descr = "Generate builder command line data structures";
    bg_tasks.descr = "Reformat generated builder command line data structures into canonical form";
    const bg_hist_tasks_impls: *Node = bg_aux.addBuild(allocator, build_cmd, "bg_hist_tasks_impls", "top/build/gen/hist_tasks_impls.zig");
    const bg_hist_tasks: *Node = node.addFormat(allocator, format_cmd, "bg_hist_tasks", "top/build/hist_tasks.zig");
    bg_hist_tasks_impls.dependOn(allocator, bg_tasks, .format);
    bg_hist_tasks.dependOn(allocator, bg_hist_tasks_impls, .run);
    bg_hist_tasks_impls.descr = "Generate packed summary types for builder history";
    bg_hist_tasks.descr = "Reformat generated history task data structures into canonical form";
    node.task.tag = .format;
}
fn targetgen(allocator: *build.Allocator, node: *Node) void {
    const tg_cpu_impl: *Node = node.addBuild(allocator, build_cmd, "tg_feat_impls", "top/target/gen/feat_impls.zig");
    tg_cpu_impl.descr = "";
}
pub const message_style: [:0]const u8 = "\x1b[2m";
