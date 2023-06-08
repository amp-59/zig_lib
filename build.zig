pub const srg = @import("./zig_lib.zig");
const proc = srg.proc;
const spec = srg.spec;
const build = srg.build;
const builtin = srg.builtin;

pub const Node = build.GenericNode(.{});
pub const logging_override: builtin.Logging.Override = spec.logging.override.silent;

pub const runtime_assertions: bool = false;
pub const message_style: [:0]const u8 = "\x1b[2m";

const deps: []const build.ModuleDependency = &.{
    .{ .name = "env" }, .{ .name = "zig_lib" }, .{ .name = "@build" },
};
const mods: []const build.Module = &.{
    .{ .name = "env", .path = "zig-cache/env.zig" },
    .{ .name = "zig_lib", .path = "zig_lib.zig" },
    .{ .name = "@build", .path = "./build.zig" },
};
var build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .mode = .ReleaseSmall,
    .dependencies = deps[0..1],
    .modules = mods[0..1],
    .image_base = 0x10000,
    .strip = true,
    .compiler_rt = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .gc_sections = true,
    .omit_frame_pointer = false,
};
const format_cmd: build.FormatCommand = .{
    .ast_check = true,
};
pub fn buildMain(allocator: *Node.Allocator, toplevel: *Node) !void {
    tests(allocator, try toplevel.addGroup(allocator, "tests"));
    examples(allocator, try toplevel.addGroup(allocator, "examples"));
    memgen(allocator, try toplevel.addGroup(allocator, "memgen"));
    buildgen(allocator, try toplevel.addGroup(allocator, "buildgen"));
}
fn memgen(allocator: *Node.Allocator, node: *Node) void {
    const mg_aux: *Node = try node.addGroup(allocator, "_memgen");
    const mg_touch: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_touch", "top/mem/gen/touch.zig");
    const mg_specs: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_specs", "top/mem/gen/specs.zig");
    const mg_ctn_kinds: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_ctn_kinds", "top/mem/gen/ctn_kinds.zig");
    const mg_ptr_impls: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_ptr_impls", "top/mem/gen/ptr_impls.zig");
    const mg_ctn_impls: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_ctn_impls", "top/mem/gen/ctn_impls.zig");
    const mg_alloc_impls: *Node = try mg_aux.addBuild(allocator, build_cmd, "mg_alloc_impls", "top/mem/gen/alloc_impls.zig");
    const mg_ctn: *Node = try node.addFormat(allocator, format_cmd, "mg_ctn", "top/mem/ctn.zig");
    const mg_ptr: *Node = try node.addFormat(allocator, format_cmd, "mg_ptr", "top/mem/ptr.zig");
    const mg_alloc: *Node = try node.addFormat(allocator, format_cmd, "mg_alloc", "top/mem/allocator.zig");
    mg_specs.dependOn(allocator, mg_touch, .run);
    mg_ctn_kinds.dependOn(allocator, mg_touch, .run);
    mg_ptr_impls.dependOn(allocator, mg_touch, .run);
    mg_ptr.dependOn(allocator, mg_ptr_impls, .run);
    mg_ctn_impls.dependOn(allocator, mg_specs, .run);
    mg_ctn_impls.dependOn(allocator, mg_ctn_kinds, .run);
    mg_ctn.dependOn(allocator, mg_ctn_impls, .run);
    mg_alloc.dependOn(allocator, mg_alloc_impls, .run);
    mg_touch.addDescr("Create placeholder files");
    mg_specs.addDescr("Generate specification types for containers and pointers");
    mg_ctn_kinds.addDescr("Generate function kind switch functions for container functions");
    mg_ptr_impls.addDescr("Generate reference implementations");
    mg_ctn_impls.addDescr("Generate container implementations");
    mg_ptr.addDescr("Reformat generated generic pointers into canonical form");
    mg_ctn.addDescr("Reformat generated generic containers into canonical form");
    mg_alloc.addDescr("Reformat generated generic allocators into canonical form");
    node.task = .format;
}
fn examples(allocator: *Node.Allocator, node: *Node) void {
    const readdir: *Node = try node.addBuild(allocator, build_cmd, "readdir", "examples/dir_iterator.zig");
    const dynamic: *Node = try node.addBuild(allocator, build_cmd, "dynamic", "examples/dynamic_alloc.zig");
    const custom: *Node = try node.addBuild(allocator, build_cmd, "addrspace", "examples/addrspace.zig");
    const allocators: *Node = try node.addBuild(allocator, build_cmd, "allocators", "examples/allocators.zig");
    const display: *Node = try node.addBuild(allocator, build_cmd, "display", "examples/display.zig");
    const mca: *Node = try node.addBuild(allocator, build_cmd, "mca", "examples/mca.zig");
    const treez: *Node = try node.addBuild(allocator, build_cmd, "treez", "examples/treez.zig");
    const itos: *Node = try node.addBuild(allocator, build_cmd, "itos", "examples/itos.zig");
    const catz: *Node = try node.addBuild(allocator, build_cmd, "catz", "examples/catz.zig");
    const cleanup: *Node = try node.addBuild(allocator, build_cmd, "cleanup", "examples/cleanup.zig");
    const hello: *Node = try node.addBuild(allocator, build_cmd, "hello", "examples/hello.zig");
    const readelf: *Node = try node.addBuild(allocator, build_cmd, "readelf", "examples/readelf.zig");
    const pathsplit: *Node = try node.addBuild(allocator, build_cmd, "pathsplit", "examples/pathsplit.zig");
    const declprint: *Node = try node.addBuild(allocator, build_cmd, "declprint", "examples/declprint.zig");
    readdir.addDescr("Shows how to iterate directory entries");
    dynamic.addDescr("Shows how to allocate dynamic memory");
    custom.addDescr("Shows a complex custom address space");
    allocators.addDescr("Shows how to use many allocators");
    display.addDescr("Shows using `ioctl` to get display resources (idkso)");
    mca.addDescr("Example program useful for extracting section from assembly for machine code analysis");
    treez.addDescr("Example program useful for listing the contents of directories in a tree-like format");
    itos.addDescr("Example program useful for converting between a variety of integer formats and bases");
    catz.addDescr("Shows how to map and write a file to standard output");
    cleanup.addDescr("Shows more advanced operations on a mapped file");
    hello.addDescr("Shows various ways of printing 'Hello, world!'");
    readelf.addDescr("Example program (defunct) for parsing and displaying information about ELF binaries");
    declprint.addDescr("Useful for printing declarations");
    pathsplit.addDescr("Useful for splitting paths into dirnames and basename");
    node.task = .build;
}
fn tests(allocator: *Node.Allocator, node: *Node) void {
    const serial_test: *Node = try node.addBuild(allocator, build_cmd, "serial_test", "test/serial-test.zig");
    const decl_test: *Node = try node.addBuild(allocator, build_cmd, "decl_test", "test/decl-test.zig");
    const builtin_test: *Node = try node.addBuild(allocator, build_cmd, "builtin_test", "test/builtin-test.zig");
    const meta_test: *Node = try node.addBuild(allocator, build_cmd, "meta_test", "test/meta-test.zig");
    const algo_test: *Node = try node.addBuild(allocator, build_cmd, "algo_test", "test/algo-test.zig");
    const math_test: *Node = try node.addBuild(allocator, build_cmd, "math_test", "test/math-test.zig");
    const file_test: *Node = try node.addBuild(allocator, build_cmd, "file_test", "test/file-test.zig");
    const list_test: *Node = try node.addBuild(allocator, build_cmd, "list_test", "test/list-test.zig");
    const fmt_test: *Node = try node.addBuild(allocator, build_cmd, "fmt_test", "test/fmt-test.zig");
    const render_test: *Node = try node.addBuild(allocator, build_cmd, "render_test", "test/render-test.zig");
    const thread_test: *Node = try node.addBuild(allocator, build_cmd, "thread_test", "test/thread-test.zig");
    const virtual_test: *Node = try node.addBuild(allocator, build_cmd, "virtual_test", "test/virtual-test.zig");
    const time_test: *Node = try node.addBuild(allocator, build_cmd, "time_test", "test/time-test.zig");
    const size_test: *Node = try node.addBuild(allocator, build_cmd, "size_test", "test/size_per_config.zig");
    const rng_test: *Node = try node.addBuild(allocator, build_cmd, "rng_test", "test/rng-test.zig");
    const parse_test: *Node = try node.addBuild(allocator, build_cmd, "parse_test", "test/parse-test.zig");
    const crypto_test: *Node = try node.addBuild(allocator, build_cmd, "crypto_test", "test/crypto-test.zig");
    const mem_test: *Node = try node.addBuild(allocator, build_cmd, "mem_test", "test/mem-test.zig");
    const mem2_test: *Node = try node.addBuild(allocator, build_cmd, "mem2_test", "test/mem2-test.zig");
    const proc_test: *Node = try node.addBuild(allocator, build_cmd, "proc_test", "test/proc-test.zig");
    const debug_test: *Node = try node.addBuild(allocator, build_cmd, "debug_test", "test/debug-test.zig");
    builtin_test.addDescr("Test builtin functions");
    mem_test.addDescr("Test low level memory management functions and basic container/allocator usage");
    mem2_test.addDescr("Test v2 low level memory implementation");
    meta_test.addDescr("Test meta functions");
    algo_test.addDescr("Test sorting and compression functions");
    math_test.addDescr("Test math functions");
    file_test.addDescr("Test low level file system operation functions");
    list_test.addDescr("Test library generic linked list");
    rng_test.addDescr("Test random number generation functions");
    crypto_test.addDescr("Test crypto related functions");
    fmt_test.addDescr("Test user formatting functions");
    parse_test.addDescr("Test generic parsing function");
    proc_test.addDescr("Test process related functions");
    render_test.addDescr("Test library value rendering functions");
    time_test.addDescr("Test time related functions");
    decl_test.addDescr("Test compilation of all public declarations recursively");
    serial_test.addDescr("Test data serialisation functions");
    thread_test.addDescr("Test clone and thread-safe compound/tagged sets");
    virtual_test.addDescr("Test address spaces, sub address spaces, and arenas");
    size_test.addDescr("Test sizes of various things");
    debug_test.addDescr("Test debugging functions");
    builderTests(allocator, try node.addGroup(allocator, "builder_tests"));
    cryptoTests(allocator, try node.addGroup(allocator, "crypto_tests"));
    node.task = .build;
    debug_test.task_info.build.mode = .Debug;
    debug_test.task_info.build.strip = false;
    parse_test.task_info.build.mode = .Debug;
}
fn cryptoTests(allocator: *Node.Allocator, node: *Node) void {
    const mode_save: ?builtin.Mode = build_cmd.mode;
    const strip_save: ?bool = build_cmd.strip;
    build_cmd.mode = .Debug;
    build_cmd.strip = true;
    defer {
        build_cmd.mode = mode_save;
        build_cmd.strip = strip_save;
    }
    if (false) {
        const auth_test: *Node = try node.addBuild(allocator, build_cmd, "auth_test", "test/crypto/auth-test.zig");
        const aead_test: *Node = try node.addBuild(allocator, build_cmd, "aead_test", "test/crypto/aead-test.zig");
        const ecdsa_test: *Node = try node.addBuild(allocator, build_cmd, "ecdsa_test", "test/crypto/ecdsa-test.zig");
        const kyber_test: *Node = try node.addBuild(allocator, build_cmd, "kyber_test", "test/crypto/kyber-test.zig");
        const dh_test: *Node = try node.addBuild(allocator, build_cmd, "dh_test", "test/crypto/dh-test.zig");
        const tls_test: *Node = try node.addBuild(allocator, build_cmd, "tls_test", "test/crypto/tls-test.zig");
        auth_test.addDescr("Test authentication");
        aead_test.addDescr("Test authenticated encryption functions and types");
        dh_test.addDescr("Test for many 25519-related functions");
        kyber_test.addDescr("Test for post-quantum 'Kyber' key exchange functions and types");
        ecdsa_test.addDescr("Test ECDSA");
        tls_test.addDescr("Test TLS");
    } else {
        const core_test: *Node = try node.addBuild(allocator, build_cmd, "core_test", "test/crypto/core-test.zig");
        const utils_test: *Node = try node.addBuild(allocator, build_cmd, "utils_test", "test/crypto/utils-test.zig");
        const hash_test: *Node = try node.addBuild(allocator, build_cmd, "hash_test", "test/crypto/hash-test.zig");
        const pcurves_test: *Node = try node.addBuild(allocator, build_cmd, "pcurves_test", "test/crypto/pcurves-test.zig");
        core_test.addDescr("Test core crypto functions and types");
        utils_test.addDescr("Test crypto utility functions");
        hash_test.addDescr("Test hashing functions");
        pcurves_test.addDescr("Test point curve operations");
    }
}
fn builderTests(allocator: *Node.Allocator, node: *Node) void {
    //
    const build_runner_test: *Node = try node.addBuild(allocator, build_cmd, "build_runner_test", "build_runner.zig");
    const zls_build_runner_test: *Node = try node.addBuild(allocator, build_cmd, "zls_build_runner_test", "zls_build_runner.zig");
    const cmdline_writer_test: *Node = try node.addBuild(allocator, build_cmd, "cmdline_test", "test/cmdline-test.zig");
    build_runner_test.addDescr("Test library build runner using the library build program");
    zls_build_runner_test.addDescr("Test ZLS special build runner");
    cmdline_writer_test.addDescr("Test generated command line writer functions");
    for ([_]*Node{ build_runner_test, zls_build_runner_test, cmdline_writer_test }) |target| {
        target.addToplevelArgs(allocator);
        target.task_info.build.modules = mods;
        target.task_info.build.dependencies = deps;
        target.task_info.build.mode = .Debug;
        target.task_info.build.strip = false;
    }
}
fn buildgen(allocator: *Node.Allocator, node: *Node) void {
    const bg_aux: *Node = try node.addGroup(allocator, "_buildgen");
    const bg_tasks_impls: *Node = try bg_aux.addBuild(allocator, build_cmd, "bg_tasks_impls", "top/build/gen/tasks_impls.zig");
    const bg_tasks: *Node = try node.addFormat(allocator, format_cmd, "bg_tasks", "top/build/tasks.zig");
    bg_tasks.dependOn(allocator, bg_tasks_impls, .run);
    bg_tasks_impls.addDescr("Generate builder command line data structures");
    bg_tasks.addDescr("Reformat generated builder command line data structures into canonical form");
    node.task = .format;
}
fn targetgen(allocator: *Node.Allocator, node: *Node) void {
    const tg_cpu_impl: *Node = try node.addBuild(allocator, build_cmd, "tg_feat_impls", "top/target/gen/feat_impls.zig");
    tg_cpu_impl.addDescr("");
}
