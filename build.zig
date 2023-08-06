pub const zl = @import("./zig_lib.zig");
const spec = zl.spec;
const build = zl.build;
const Node = build.GenericNode(.{});
const build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .omit_frame_pointer = false,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .reference_trace = true,
    .error_tracing = true,
    .single_threaded = true,
    .function_sections = true,
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
pub fn testGroup(allocator: *build.Allocator, @"test": *Node) void {
    @"test".descr = "";
    var test_build_cmd: build.BuildCommand = build_cmd;
    const decls: *Node = @"test".addBuild(allocator, test_build_cmd, "decls", "test/decl-test.zig");
    const builtin: *Node = @"test".addBuild(allocator, test_build_cmd, "builtin", "test/builtin-test.zig");
    const meta: *Node = @"test".addBuild(allocator, test_build_cmd, "meta", "test/meta-test.zig");
    const gen: *Node = @"test".addBuild(allocator, test_build_cmd, "gen", "test/gen-test.zig");
    const math: *Node = @"test".addBuild(allocator, test_build_cmd, "math", "test/math-test.zig");
    const file: *Node = @"test".addBuild(allocator, test_build_cmd, "file", "test/file-test.zig");
    const list: *Node = @"test".addBuild(allocator, test_build_cmd, "list", "test/list-test.zig");
    const fmt: *Node = @"test".addBuild(allocator, test_build_cmd, "fmt", "test/fmt-test.zig");
    const render: *Node = @"test".addBuild(allocator, test_build_cmd, "render", "test/render-test.zig");
    const thread: *Node = @"test".addBuild(allocator, test_build_cmd, "thread", "test/thread-test.zig");
    const virtual: *Node = @"test".addBuild(allocator, test_build_cmd, "virtual", "test/virtual-test.zig");
    const time: *Node = @"test".addBuild(allocator, test_build_cmd, "time", "test/time-test.zig");
    const size: *Node = @"test".addBuild(allocator, test_build_cmd, "size", "test/size_per_config.zig");
    const parse: *Node = @"test".addBuild(allocator, test_build_cmd, "parse", "test/parse-test.zig");
    const crypto: *Node = @"test".addBuild(allocator, test_build_cmd, "crypto", "test/crypto-test.zig");
    const zig: *Node = @"test".addBuild(allocator, test_build_cmd, "zig", "test/zig-test.zig");
    const mem: *Node = @"test".addBuild(allocator, test_build_cmd, "mem", "test/mem-test.zig");
    const mem2: *Node = @"test".addBuild(allocator, test_build_cmd, "mem2", "test/mem2-test.zig");
    const proc: *Node = @"test".addBuild(allocator, test_build_cmd, "proc", "test/proc-test.zig");
    const rng: *Node = @"test".addBuild(allocator, test_build_cmd, "rng", "test/rng-test.zig");
    const ecdsa: *Node = @"test".addBuild(allocator, test_build_cmd, "ecdsa", "test/crypto/ecdsa-test.zig");
    const aead: *Node = @"test".addBuild(allocator, test_build_cmd, "aead", "test/crypto/aead-test.zig");
    const auth: *Node = @"test".addBuild(allocator, test_build_cmd, "auth", "test/crypto/auth-test.zig");
    const dh: *Node = @"test".addBuild(allocator, test_build_cmd, "dh", "test/crypto/dh-test.zig");
    const tls: *Node = @"test".addBuild(allocator, test_build_cmd, "tls", "test/crypto/tls-test.zig");
    const core: *Node = @"test".addBuild(allocator, test_build_cmd, "core", "test/crypto/core-test.zig");
    const utils: *Node = @"test".addBuild(allocator, test_build_cmd, "utils", "test/crypto/utils-test.zig");
    const hash: *Node = @"test".addBuild(allocator, test_build_cmd, "hash", "test/crypto/hash-test.zig");
    const pcurves: *Node = @"test".addBuild(allocator, test_build_cmd, "pcurves", "test/crypto/pcurves-test.zig");
    const cmdline_writer: *Node = @"test".addBuild(allocator, test_build_cmd, "cmdline_writer", "test/cmdline-writer-test.zig");
    const cmdline_parser: *Node = @"test".addBuild(allocator, test_build_cmd, "cmdline_parser", "test/cmdline-parser-test.zig");
    test_build_cmd.mode = .ReleaseFast;
    const algo: *Node = @"test".addBuild(allocator, test_build_cmd, "algo", "test/algo-test.zig");
    test_build_cmd.mode = .Debug;
    test_build_cmd.strip = false;
    const elf: *Node = @"test".addBuild(allocator, test_build_cmd, "elf", "test/elf-test.zig");
    const debug: *Node = @"test".addBuild(allocator, test_build_cmd, "debug", "test/debug-test.zig");
    test_build_cmd.emit_asm = .{ .yes = null };
    test_build_cmd.strip = true;
    const fmt_cmp: *Node = @"test".addBuild(allocator, test_build_cmd, "fmt_cmp", "test/fmt_cmp-test.zig");
    test_build_cmd.emit_asm = null;
    test_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    test_build_cmd.dependencies = &.{.{ .name = "@build" }};
    const build_stress: *Node = @"test".addBuild(allocator, test_build_cmd, "build_stress", "test/build-test.zig");
    test_build_cmd.strip = false;
    const serial: *Node = @"test".addBuild(allocator, test_build_cmd, "serial", "test/serial-test.zig");
    const build_runner: *Node = @"test".addBuild(allocator, test_build_cmd, "build_runner", "build_runner.zig");
    const zls_build_runner: *Node = @"test".addBuild(allocator, test_build_cmd, "zls_build_runner", "zls_build_runner.zig");
    test_build_cmd.kind = .obj;
    test_build_cmd.gc_sections = false;
    test_build_cmd.modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
    test_build_cmd.dependencies = &.{.{ .name = "zig_lib" }};
    const debug2_test: *Node = @"test".addBuild(allocator, test_build_cmd, "debug2_test", "test/debug2-test.zig");
    decls.descr = "Test compilation of all public declarations recursively";
    builtin.descr = "Test builtin functions";
    meta.descr = "Test meta functions";
    gen.descr = "Test generic code generation functions";
    math.descr = "Test math functions";
    file.descr = "Test low level file system operation functions";
    list.descr = "Test library generic linked list";
    fmt.descr = "Test user formatting functions";
    render.descr = "Test library value rendering functions";
    thread.descr = "Test clone and thread-safe compound/tagged sets";
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
    elf.descr = "Test ELF iterator";
    debug.descr = "Test debugging functions";
    fmt_cmp.descr = "Compare formatting methods";
    build_stress.descr = "Try to produce builder errors";
    serial.descr = "Test data serialisation functions";
    build_runner.descr = "Test library build runner using the library build program";
    zls_build_runner.descr = "Test ZLS special build runner";
    cmdline_writer.addToplevelArgs(allocator);
    debug.dependOnFull(allocator, .build, debug2_test, .build);
    build_stress.addToplevelArgs(allocator);
    serial.addToplevelArgs(allocator);
    build_runner.addToplevelArgs(allocator);
    zls_build_runner.addToplevelArgs(allocator);
}
pub fn userGroup(allocator: *build.Allocator, user: *Node) void {
    user.descr = "";
    var user_build_cmd: build.BuildCommand = build_cmd;
    const user_std_lib_cfg_pkg: *Node = user.addBuild(allocator, user_build_cmd, "user_std_lib_cfg_pkg", "test/user/std_lib_cfg_pkg.zig");
    const user_std_lib_pkg: *Node = user.addBuild(allocator, user_build_cmd, "user_std_lib_pkg", "test/user/std_lib_pkg.zig");
    user_build_cmd.modules = &.{};
    user_build_cmd.dependencies = &.{};
    const user_std_lib_cfg: *Node = user.addBuild(allocator, user_build_cmd, "user_std_lib_cfg", "test/user/std_lib_cfg.zig");
    const user_std_lib: *Node = user.addBuild(allocator, user_build_cmd, "user_std_lib", "test/user/std_lib.zig");
    user_std_lib_cfg.descr = "Standard builtin, with build configuration, without library package";
    user_std_lib.descr = "Standard builtin, without build configuration, without library package";
    user_std_lib_cfg_pkg.descr = "Standard builtin, with build configuration, library package";
    user_std_lib_pkg.descr = "Standard builtin, without build configuration, with library package";
}
pub fn exampleGroup(allocator: *build.Allocator, example: *Node) void {
    example.descr = "";
    var example_build_cmd: build.BuildCommand = build_cmd;
    example_build_cmd.mode = .ReleaseSmall;
    const readdir: *Node = example.addBuild(allocator, example_build_cmd, "readdir", "examples/dir_iterator.zig");
    const dynamic: *Node = example.addBuild(allocator, example_build_cmd, "dynamic", "examples/dynamic_alloc.zig");
    const @"addrspace": *Node = example.addBuild(allocator, example_build_cmd, "addrspace", "examples/addrspace.zig");
    const allocators: *Node = example.addBuild(allocator, example_build_cmd, "allocators", "examples/allocators.zig");
    const display: *Node = example.addBuild(allocator, example_build_cmd, "display", "examples/display.zig");
    const mca: *Node = example.addBuild(allocator, example_build_cmd, "mca", "examples/mca.zig");
    const itos: *Node = example.addBuild(allocator, example_build_cmd, "itos", "examples/itos.zig");
    const catz: *Node = example.addBuild(allocator, example_build_cmd, "catz", "examples/catz.zig");
    const perf: *Node = example.addBuild(allocator, example_build_cmd, "perf", "examples/perf_events.zig");
    const cleanup: *Node = example.addBuild(allocator, example_build_cmd, "cleanup", "examples/cleanup.zig");
    const hello: *Node = example.addBuild(allocator, example_build_cmd, "hello", "examples/hello.zig");
    const pathsplit: *Node = example.addBuild(allocator, example_build_cmd, "pathsplit", "examples/pathsplit.zig");
    const declprint: *Node = example.addBuild(allocator, example_build_cmd, "declprint", "examples/declprint.zig");
    const pipeout: *Node = example.addBuild(allocator, example_build_cmd, "pipeout", "examples/pipeout.zig");
    const treez: *Node = example.addBuild(allocator, example_build_cmd, "treez", "examples/treez.zig");
    example_build_cmd.mode = .Debug;
    example_build_cmd.strip = false;
    const statz: *Node = example.addBuild(allocator, example_build_cmd, "statz", "examples/statz.zig");
    readdir.descr = "Shows how to iterate directory entries";
    dynamic.descr = "Shows how to allocate dynamic memory";
    @"addrspace".descr = "Shows a complex custom address space";
    allocators.descr = "Shows how to use many allocators";
    display.descr = "Shows using `ioctl` to get display resources (idkso)";
    mca.descr = "Example program useful for extracting section from assembly for machine code analysis";
    itos.descr = "Example program useful for converting between a variety of integer formats and bases";
    catz.descr = "Shows how to map and write a file to standard output";
    perf.descr = "Integrated performance";
    cleanup.descr = "Shows more advanced operations on a mapped file";
    hello.descr = "Shows various ways of printing 'Hello, world!'";
    pathsplit.descr = "Useful for splitting paths into dirnames and basename";
    declprint.descr = "Useful for printing declarations";
    pipeout.descr = "Shows how to redirect child process output to file";
    treez.descr = "Example program useful for listing the contents of directories in a tree-like format";
    statz.descr = "Build statistics file reader";
}
pub fn memgenGroup(allocator: *build.Allocator, memgen: *Node) void {
    memgen.descr = "";
    var memgen_build_cmd: build.BuildCommand = build_cmd;
    var memgen_format_cmd: build.FormatCommand = format_cmd;
    const specs: *Node = memgen.addBuild(allocator, memgen_build_cmd, "specs", "top/mem/gen/specs.zig");
    const ptr_impls: *Node = memgen.addBuild(allocator, memgen_build_cmd, "ptr_impls", "top/mem/gen/ptr_impls.zig");
    const ctn_impls: *Node = memgen.addBuild(allocator, memgen_build_cmd, "ctn_impls", "top/mem/gen/ctn_impls.zig");
    const alloc_impls: *Node = memgen.addBuild(allocator, memgen_build_cmd, "alloc_impls", "top/mem/gen/alloc_impls.zig");
    const ctn_kinds: *Node = memgen.addFormat(allocator, memgen_format_cmd, "ctn_kinds", "top/mem/gen/ctn_kinds.zig");
    const ctn: *Node = memgen.addFormat(allocator, memgen_format_cmd, "ctn", "top/mem/ctn.zig");
    const ptr: *Node = memgen.addFormat(allocator, memgen_format_cmd, "ptr", "top/mem/ptr.zig");
    memgen_format_cmd.ast_check = false;
    const alloc: *Node = memgen.addFormat(allocator, memgen_format_cmd, "alloc", "top/mem/allocator.zig");
    specs.descr = "Generate specification types for containers and pointers";
    ptr_impls.descr = "Generate reference implementations";
    ctn_impls.descr = "Generate container implementations";
    alloc_impls.descr = "Generate allocator implementations";
    ctn_kinds.descr = "Reformat generated container function kind switch functions into canonical form";
    ctn.descr = "Reformat generated generic containers into canonical form";
    ptr.descr = "Reformat generated generic pointers into canonical form";
    alloc.descr = "Reformat generated generic allocators into canonical form";
    ptr_impls.dependOnFull(allocator, .build, specs, .build);
    ctn_impls.dependOnFull(allocator, .build, specs, .build);
    alloc_impls.dependOnFull(allocator, .build, ptr_impls, .build);
    ctn_kinds.dependOnFull(allocator, .format, specs, .run);
    ctn.dependOnFull(allocator, .format, ctn_impls, .run);
    ptr.dependOnFull(allocator, .format, ptr_impls, .run);
    alloc.dependOnFull(allocator, .format, alloc_impls, .run);
}
pub fn regenGroup(allocator: *build.Allocator, regen: *Node) void {
    regen.descr = "";
    var regen_format_cmd: build.FormatCommand = format_cmd;
    const _regen = regen.addGroup(allocator, "_regen");
    var _regen_build_cmd: build.BuildCommand = build_cmd;
    _regen_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    _regen_build_cmd.dependencies = &.{.{ .name = "@build" }};
    const rebuild_impls: *Node = _regen.addBuild(allocator, _regen_build_cmd, "rebuild_impls", "top/build/gen/rebuild_impls.zig");
    const rebuild: *Node = regen.addFormat(allocator, regen_format_cmd, "rebuild", "top/build/rebuild.zig");
    rebuild_impls.descr = "Regenerate build program maybe adding new elements";
    rebuild.descr = "Reformat regenerated build program into canonical form";
    rebuild_impls.addToplevelArgs(allocator);
    rebuild_impls.dependOnFull(allocator, .build, Node.special.fmt, .archive);
    rebuild.dependOnFull(allocator, .format, rebuild_impls, .run);
}
pub fn buildgenGroup(allocator: *build.Allocator, buildgen: *Node) void {
    buildgen.descr = "";
    var buildgen_format_cmd: build.FormatCommand = format_cmd;
    const _buildgen = buildgen.addGroup(allocator, "_buildgen");
    var _buildgen_build_cmd: build.BuildCommand = build_cmd;
    const tasks_impls: *Node = _buildgen.addBuild(allocator, _buildgen_build_cmd, "tasks_impls", "top/build/gen/tasks_impls.zig");
    const hist_tasks_impls: *Node = _buildgen.addBuild(allocator, _buildgen_build_cmd, "hist_tasks_impls", "top/build/gen/hist_tasks_impls.zig");
    const parsers_impls: *Node = _buildgen.addBuild(allocator, _buildgen_build_cmd, "parsers_impls", "top/build/gen/parsers_impls.zig");
    const tasks: *Node = buildgen.addFormat(allocator, buildgen_format_cmd, "tasks", "top/build/tasks.zig");
    const hist_tasks: *Node = buildgen.addFormat(allocator, buildgen_format_cmd, "hist_tasks", "top/build/hist_tasks.zig");
    const parsers: *Node = buildgen.addFormat(allocator, buildgen_format_cmd, "parsers", "top/build/parsers.zig");
    tasks_impls.descr = "Generate builder command line data structures";
    hist_tasks_impls.descr = "Generate packed summary types for builder history";
    parsers_impls.descr = "exports for builder task command line parser functions";
    tasks.descr = "Reformat generated builder command line data structures into canonical form";
    hist_tasks.descr = "Reformat generated history task data structures into canonical form";
    parsers.descr = "Reformat exports for builder task command line parser functions into canonical form";
    hist_tasks_impls.dependOnFull(allocator, .build, tasks, .format);
    tasks.dependOnFull(allocator, .format, tasks_impls, .run);
    hist_tasks.dependOnFull(allocator, .format, hist_tasks_impls, .run);
    parsers.dependOnFull(allocator, .format, parsers_impls, .run);
}
pub fn targetgenGroup(allocator: *build.Allocator, targetgen: *Node) void {
    targetgen.descr = "";
    var targetgen_format_cmd: build.FormatCommand = format_cmd;
    const _targetgen = targetgen.addGroup(allocator, "_targetgen");
    var _targetgen_build_cmd: build.BuildCommand = build_cmd;
    const arch_impls: *Node = _targetgen.addBuild(allocator, _targetgen_build_cmd, "arch_impls", "top/target/gen/arch_impls.zig");
    const target_impl: *Node = _targetgen.addBuild(allocator, _targetgen_build_cmd, "target_impl", "top/target/gen/target_impl.zig");
    const arch: *Node = targetgen.addFormat(allocator, targetgen_format_cmd, "arch", "top/target");
    const target: *Node = targetgen.addFormat(allocator, targetgen_format_cmd, "target", "top/target.zig");
    arch_impls.descr = "Generate target information for supported architectures";
    arch.descr = "Reformat generated builder command line data structures into canonical form";
    target_impl.dependOnFull(allocator, .build, arch_impls, .build);
    arch.dependOnFull(allocator, .format, arch_impls, .run);
    target.dependOnFull(allocator, .format, target_impl, .run);
}
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    toplevel.descr = "";
    testGroup(allocator, toplevel.addGroupWithTask(allocator, "test", .build));
    userGroup(allocator, toplevel.addGroupWithTask(allocator, "user", .build));
    exampleGroup(allocator, toplevel.addGroupWithTask(allocator, "example", .build));
    memgenGroup(allocator, toplevel.addGroupWithTask(allocator, "memgen", .format));
    regenGroup(allocator, toplevel.addGroupWithTask(allocator, "regen", .format));
    buildgenGroup(allocator, toplevel.addGroupWithTask(allocator, "buildgen", .format));
    targetgenGroup(allocator, toplevel.addGroupWithTask(allocator, "targetgen", .format));
}
