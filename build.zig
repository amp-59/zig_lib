pub const zl = @import("./zig_lib.zig");
const spec = zl.spec;
const build = zl.build;
pub const Builder = build.GenericBuilder(.{});
const Node = Builder.Node;

const build_cmd: build.BuildCommand = .{
    .kind = .exe,
    .omit_frame_pointer = false,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .valgrind = false,
    .unwind_tables = true,
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
pub fn sysgenGroup(allocator: *build.Allocator, group: *Builder.Node) void {
    var sysgen_format_cmd: build.FormatCommand = format_cmd;
    sysgen_format_cmd.ast_check = false;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const flags: *Builder.Node = group.addBuild(allocator, impls_build_cmd, "flags", "top/sys/gen/flags.zig");
    const format: *Builder.Node = group.addFormat(allocator, sysgen_format_cmd, "format", "top/sys");
    flags.descr = "Generate system function option bit field struct definitions";
    format.addDepn(allocator, .format, flags, .run);
}
pub fn traceGroup(allocator: *build.Allocator, group: *Node) void {
    var trace_build_cmd: build.BuildCommand = .{ .kind = .exe, .function_sections = true, .gc_sections = false };
    const debug: *Node = group.addBuild(allocator, trace_build_cmd, "debug", "test/debug.zig");
    const access_inactive: *Node = group.addBuild(allocator, trace_build_cmd, "access_inactive", "test/trace/access_inactive.zig");
    const assertion_failed: *Node = group.addBuild(allocator, trace_build_cmd, "assertion_failed", "test/trace/assertion_failed.zig");
    const out_of_bounds: *Node = group.addBuild(allocator, trace_build_cmd, "out_of_bounds", "test/trace/out_of_bounds.zig");
    const reach_unreachable: *Node = group.addBuild(allocator, trace_build_cmd, "reach_unreachable", "test/trace/reach_unreachable.zig");
    const sentinel_mismatch: *Node = group.addBuild(allocator, trace_build_cmd, "sentinel_mismatch", "test/trace/sentinel_mismatch.zig");
    const stack_overflow: *Node = group.addBuild(allocator, trace_build_cmd, "stack_overflow", "test/trace/stack_overflow.zig");
    const start_gt_end: *Node = group.addBuild(allocator, trace_build_cmd, "start_gt_end", "test/trace/start_gt_end.zig");
    const static_exe: *Node = group.addBuild(allocator, trace_build_cmd, "static_exe", "test/trace/static_exe.zig");
    const minimal_full: *Node = group.addBuild(allocator, trace_build_cmd, "minimal_full", "test/trace/minimal_full.zig");
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
    minimal_full.descr = "Test binary composition with all traces possible";
    debug.descr = "Test debug";
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
    const time: *Node = group.addBuild(allocator, test_build_cmd, "time", "test/time.zig");
    const size: *Node = group.addBuild(allocator, test_build_cmd, "size", "test/size_per_config.zig");
    const parse: *Node = group.addBuild(allocator, test_build_cmd, "parse", "test/parse.zig");
    const crypto: *Node = group.addBuild(allocator, test_build_cmd, "crypto", "test/crypto.zig");
    const zig: *Node = group.addBuild(allocator, test_build_cmd, "zig", "test/zig.zig");
    const mem: *Node = group.addBuild(allocator, test_build_cmd, "mem", "test/mem.zig");
    const proc: *Node = group.addBuild(allocator, test_build_cmd, "proc", "test/proc.zig");
    const elfcmp: *Node = group.addBuild(allocator, test_build_cmd, "elfcmp", "test/elfcmp.zig");
    const mem2: *Node = group.addBuild(allocator, test_build_cmd, "mem2", "test/mem2.zig");
    const x86: *Node = group.addBuild(allocator, test_build_cmd, "x86", "test/x86.zig");
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
    const algo: *Node = group.addBuild(allocator, test_build_cmd, "algo", "test/algo.zig");
    const fmt_cmp: *Node = group.addBuild(allocator, test_build_cmd, "fmt_cmp", "test/fmt_cmp.zig");
    const grep: *Node = group.addRun(allocator, "grep", &.{ "/usr/bin/grep", "Node", "./build.zig" });

    mem.flags.want_stack_traces = true;
    traceGroup(allocator, group.addGroup(allocator, "trace", null));

    elfcmp.dependOn(allocator, meta);
    elfcmp.dependOn(allocator, builtin);
    meta.tasks.cmd.build.strip = false;
    builtin.tasks.cmd.build.strip = false;
    elfcmp.addRunArg(allocator).* = meta.getPath(.{ .tag = .output_generic }).?.concatenate(allocator);
    elfcmp.addRunArg(allocator).* = builtin.getPath(.{ .tag = .output_generic }).?.concatenate(allocator);

    test_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    test_build_cmd.dependencies = &.{.{ .name = "@build" }};
    const build_stress: *Node = group.addBuild(allocator, test_build_cmd, "build_stress", "test/build.zig");
    const elf: *Node = group.addBuild(allocator, test_build_cmd, "elf", "test/elf.zig");
    test_build_cmd.strip = false;
    const serial: *Node = group.addBuild(allocator, test_build_cmd, "serial", "test/serial.zig");
    test_build_cmd.kind = .lib;
    test_build_cmd.mode = .ReleaseSmall;
    test_build_cmd.strip = false;
    test_build_cmd.dynamic = true;
    x86.flags.want_stack_traces = true;
    const test_writers: *Node = group.addBuild(allocator, test_build_cmd, "test_writers", "top/build/writers.zig");
    const test_parsers: *Node = group.addBuild(allocator, test_build_cmd, "test_parsers", "top/build/parsers.zig");
    test_build_cmd.strip = true;
    x86.flags.want_stack_traces = true;
    const test_symbols: *Node = group.addBuild(allocator, test_build_cmd, "test_symbols", "test/symbols.zig");
    langGroup(allocator, group.addGroup(allocator, "lang", null));
    build_stress.addToplevelArgs(allocator);
    serial.addToplevelArgs(allocator);
    elf.dependOn(allocator, test_symbols);
    elf.dependOn(allocator, test_parsers);
    elf.dependOn(allocator, test_writers);

    x86.descr = "Test x86 assembler/disassembler";
    decls.descr = "Test compilation of all public declarations recursively";
    builtin.descr = "Test builtin functions";
    meta.descr = "Test meta functions";
    gen.descr = "Test generic code generation functions";
    math.descr = "Test math functions";
    file.descr = "Test low level file system operation functions";
    list.descr = "Test library generic linked list";
    fmt.descr = "Test user formatting functions";
    time.descr = "Test time related functions";
    size.descr = "Test sizes of various things";
    parse.descr = "Test generic parsing function";
    crypto.descr = "Test crypto related functions";
    zig.descr = "Test Zig language related functions";
    mem.descr = "Test low level memory management functions and basic container/allocator usage";
    mem2.descr = "Test v2 low level memory implementation";
    proc.descr = "Test process related functions";
    grep.descr = "Test run command works";
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
    algo.descr = "Test sorting and compression functions";
    fmt_cmp.descr = "Compare formatting methods";
    build_stress.descr = "Try to produce builder errors";
    serial.descr = "Test data serialisation functions";
    elf.descr = "Test ELF iterator";
    elfcmp.descr = "Test ELF comparison";
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
    const elfcmp: *Node = group.addBuild(allocator, example_build_cmd, "elfcmp", "examples/elfcmp.zig");
    example_build_cmd.mode = .Debug;
    example_build_cmd.strip = false;
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
    elfcmp.descr = "Wrapper for ELF size comparison";
}
pub fn memgenGroup(allocator: *build.Allocator, group: *Node) void {
    var memgen_format_cmd: build.FormatCommand = format_cmd;
    memgen_format_cmd.ast_check = false;
    const impls = group.addGroupWithTask(allocator, "impls", .format);
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
    impls_ptr.addDepn(allocator, .run, impls_specs, .run);
    impls_ctn.addDepn(allocator, .run, impls_specs, .run);
    impls_alloc.addDepn(allocator, .run, impls_specs, .run);
    generate.addDepn(allocator, .format, impls_ptr, .run);
    generate.addDepn(allocator, .format, impls_ctn, .run);
    generate.addDepn(allocator, .format, impls_alloc, .run);
}
pub fn buildRunnerTestGroup(allocator: *build.Allocator, group: *Node) void {
    var test_build_cmd: build.BuildCommand = build_cmd;
    test_build_cmd.strip = false;
    const dynamic_extensions: *Node = group.addBuild(allocator, test_build_cmd, "dynamic_extensions", "test/build/dynamic_extensions.zig");
    test_build_cmd.dependencies = &.{.{ .name = "@build" }};
    test_build_cmd.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    const build_runner: *Node = group.addBuild(allocator, test_build_cmd, "build_runner", "build_runner.zig");
    build_runner.flags.want_binary_analysis = true;
    build_runner.flags.want_perf_events = true;
    const zls_build_runner: *Node = group.addBuild(allocator, test_build_cmd, "zls_build_runner", "zls_build_runner.zig");
    build_runner.flags.want_stack_traces = false;
    dynamic_extensions.flags.want_stack_traces = false;
    test_build_cmd.dependencies = &.{
        .{ .name = "@build" },
        .{ .name = "zl" },
    };
    test_build_cmd.modules = &.{ .{
        .name = "@build",
        .path = "./build.zig",
    }, .{
        .name = "zl",
        .path = "./zig_lib.zig",
    } };
    test_build_cmd.kind = .lib;
    test_build_cmd.dynamic = true;
    const proc_auto: *Node = group.addBuild(allocator, test_build_cmd, "proc", "top/build/proc.auto.zig");
    const about_auto: *Node = group.addBuild(allocator, test_build_cmd, "about", "top/build/about.auto.zig");
    const build_auto: *Node = group.addBuild(allocator, test_build_cmd, "build", "top/build/build.auto.zig");
    const format_auto: *Node = group.addBuild(allocator, test_build_cmd, "format", "top/build/format.auto.zig");
    const archive_auto: *Node = group.addBuild(allocator, test_build_cmd, "archive", "top/build/archive.auto.zig");
    const objcopy_auto: *Node = group.addBuild(allocator, test_build_cmd, "objcopy", "top/build/objcopy.auto.zig");
    build_runner.descr = "Test library build runner using the library build program";
    dynamic_extensions.descr = "Test library build runner usage of dynamic extensions";
    zls_build_runner.descr = "Test ZLS special build runner";
    proc_auto.descr = "source root for `executeCommandThreaded`";
    build_auto.descr = "source root for `BuilderCommand` functions";
    format_auto.descr = "source root for `FormatCommand` functions";
    archive_auto.descr = "source root for `ArchiveCommand` functions";
    objcopy_auto.descr = "source root for `ObjcopyCommand` functions";
    for ([_]*Node{
        build_runner, dynamic_extensions, zls_build_runner,
    }) |node| {
        node.addToplevelArgs(allocator);
    }
    for ([_]*Node{
        proc_auto,   about_auto,   build_auto,
        format_auto, archive_auto, objcopy_auto,
    }) |node| {
        node.flags.want_builder_decl = true;
    }
}
pub fn buildgenGroup(allocator: *build.Allocator, group: *Node) void {
    var buildgen_format_cmd: build.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    impls.flags.is_hidden = false;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const impls_tasks: *Node = impls.addBuild(allocator, impls_build_cmd, "tasks", "top/build/gen/tasks_impls.zig");
    const impls_parsers: *Node = impls.addBuild(allocator, impls_build_cmd, "parsers", "top/build/gen/parsers_impls.zig");
    const impls_writers: *Node = impls.addBuild(allocator, impls_build_cmd, "writers", "top/build/gen/writers_impls.zig");
    const impls_libs: *Node = impls.addBuild(allocator, impls_build_cmd, "libs", "top/build/gen/libs_impls.zig");
    const format: *Node = group.addFormat(allocator, buildgen_format_cmd, "format", "top/build");
    impls_tasks.descr = "Generate builder command line data structures";
    impls_parsers.descr = "Generate exports for builder task command line parser functions";
    impls_libs.descr = "Generate headers and exporters for dynamic loaded functions";
    format.descr = "Reformat generated source code into canonical form";
    impls_parsers.addDepn(allocator, .build, impls_tasks, .run);
    impls_writers.addDepn(allocator, .build, impls_tasks, .run);
    impls_libs.addDepn(allocator, .build, impls_parsers, .run);
    impls_libs.addDepn(allocator, .build, impls_writers, .run);
    format.addDepn(allocator, .format, impls_libs, .run);
}
pub fn targetgenGroup(allocator: *build.Allocator, group: *Node) void {
    var targetgen_format_cmd: build.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    impls.flags.is_hidden = true;
    var impls_build_cmd: build.BuildCommand = build_cmd;
    const impls_arch: *Node = impls.addBuild(allocator, impls_build_cmd, "arch", "top/target/gen/arch_impls.zig");
    const impls_target: *Node = impls.addBuild(allocator, impls_build_cmd, "target", "top/target/gen/target_impl.zig");
    const format: *Node = group.addFormat(allocator, targetgen_format_cmd, "format", "top/target");
    impls_arch.descr = "Generate target information for supported architectures";
    format.descr = "Reformat generated target information into canonical form";
    impls_target.dependOn(allocator, impls_arch);
    format.addDepn(allocator, .format, impls_target, .run);
}
fn regenGroup(allocator: *build.Allocator, group: *Node) void {
    const regen: *Node = group.addBuild(allocator, build_cmd, "rebuild", "top/build/gen/rebuild_impls.zig");
    regen.tasks.cmd.build.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    regen.tasks.cmd.build.dependencies = &.{.{ .name = "@build" }};
}
pub fn buildMain(allocator: *build.Allocator, toplevel: *Node) void {
    buildRunnerTestGroup(allocator, toplevel.addGroupWithTask(allocator, "br", .build));
    testGroup(allocator, toplevel.addGroupWithTask(allocator, "test", .build));
    if (false) {
        userGroup(allocator, toplevel.addGroupWithTask(allocator, "user", .build));
        exampleGroup(allocator, toplevel.addGroupWithTask(allocator, "examples", .build));
        memgenGroup(allocator, toplevel.addGroupWithTask(allocator, "memgen", .format));
        sysgenGroup(allocator, toplevel.addGroupWithTask(allocator, "sysgen", .format));
        buildgenGroup(allocator, toplevel.addGroupWithTask(allocator, "buildgen", .format));
        targetgenGroup(allocator, toplevel.addGroupWithTask(allocator, "targetgen", .format));
    }
}
pub fn install(b: *@import("std").Build.Builder) void {
    const run_install = b.addSystemCommand(&.{ "bash", zl.builtin.lib_root ++ "/support/install.sh" });
    b.default_step.dependOn(&run_install.step);
}
pub usingnamespace struct {
    pub const build = if (@hasDecl(@import("root"), "dependencies")) install else zl.build;
};
