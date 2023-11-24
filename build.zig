pub const zl = @import("zig_lib.zig");
pub const Builder = zl.build.GenericBuilder(.{
    .options = .{ .extensions_policy = .emergency },
});
const Node = Builder.Node;
const build_cmd: zl.build.BuildCommand = .{
    .kind = .exe,
    .omit_frame_pointer = false,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .reference_trace = true,
    .single_threaded = true,
    .function_sections = true,
    .valgrind = false,
    .unwind_tables = false,
    .strip = true,
    .compiler_rt = false,
    .gc_sections = true,
    .image_base = 65536,
    .modules = &.{.{ .name = "zig_lib", .path = zl.builtin.lib_root ++ "/zig_lib.zig" }},
    .dependencies = &.{.{ .name = "zig_lib" }},
};
const format_cmd: zl.build.FormatCommand = .{
    .ast_check = true,
};
pub const enable_debugging: bool = false;
pub fn traceGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    var trace_build_cmd: zl.build.BuildCommand = .{
        .kind = .exe,
        .function_sections = true,
        .gc_sections = false,
        .unwind_tables = false,
        .compiler_rt = false,
    };
    const access_inactive: *Node = group.addBuild(allocator, trace_build_cmd, "access_inactive", "test/trace/access_inactive.zig");
    const assertion_failed: *Node = group.addBuild(allocator, trace_build_cmd, "assertion_failed", "test/trace/assertion_failed.zig");
    const out_of_bounds: *Node = group.addBuild(allocator, trace_build_cmd, "out_of_bounds", "test/trace/out_of_bounds.zig");
    const reach_unreachable: *Node = group.addBuild(allocator, trace_build_cmd, "reach_unreachable", "test/trace/reach_unreachable.zig");
    const sentinel_mismatch: *Node = group.addBuild(allocator, trace_build_cmd, "sentinel_mismatch", "test/trace/sentinel_mismatch.zig");
    const stack_overflow: *Node = group.addBuild(allocator, trace_build_cmd, "stack_overflow", "test/trace/stack_overflow.zig");
    const start_gt_end: *Node = group.addBuild(allocator, trace_build_cmd, "start_gt_end", "test/trace/start_gt_end.zig");
    const static_exe: *Node = group.addBuild(allocator, trace_build_cmd, "static_exe", "test/trace/static_exe.zig");
    const minimal_full: *Node = group.addBuild(allocator, trace_build_cmd, "minimal_full", "test/trace/minimal_full.zig");
    static_exe.flags.want_stack_traces = true;
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
    static_exe.dependOn(allocator, static_obj);
}
pub fn memgenGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var memgen_format_cmd: zl.build.FormatCommand = format_cmd;
    memgen_format_cmd.ast_check = false;
    const impls = group.addGroupWithTask(allocator, "impls", .format);
    impls.flags.is_hidden = true;
    var impls_build_cmd: zl.build.BuildCommand = build_cmd;
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
pub fn sysgenGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var sysgen_format_cmd: zl.build.FormatCommand = format_cmd;
    sysgen_format_cmd.ast_check = false;
    var impls_build_cmd: zl.build.BuildCommand = build_cmd;
    const flags: *Builder.Node = group.addBuild(allocator, impls_build_cmd, "flags", "top/sys/gen/flags.zig");
    const fns: *Builder.Node = group.addBuild(allocator, impls_build_cmd, "fns", "top/sys/gen/fns.zig");
    const format: *Builder.Node = group.addFormat(allocator, sysgen_format_cmd, "format", "top/sys");
    flags.descr = "Generate system function option bit field struct definitions";
    fns.descr = "Generate system function wrapper functions";
    format.addDepn(allocator, .format, flags, .run);
}
pub fn buildgenGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var buildgen_format_cmd: zl.build.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    impls.flags.is_hidden = false;
    var impls_build_cmd: zl.build.BuildCommand = build_cmd;
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
pub fn targetgenGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var targetgen_format_cmd: zl.build.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    impls.flags.is_hidden = true;
    var impls_build_cmd: zl.build.BuildCommand = build_cmd;
    const impls_arch: *Node = impls.addBuild(allocator, impls_build_cmd, "arch", "top/target/gen/arch_impls.zig");
    const impls_target: *Node = impls.addBuild(allocator, impls_build_cmd, "target", "top/target/gen/target_impl.zig");
    const format: *Node = group.addFormat(allocator, targetgen_format_cmd, "format", "top/target");
    impls_arch.descr = "Generate target information for supported architectures";
    format.descr = "Reformat generated target information into canonical form";
    impls_target.dependOn(allocator, impls_arch);
    format.addDepn(allocator, .format, impls_target, .run);
}
pub fn generators(allocator: *zl.build.types.Allocator, toplevel: *Node) void {
    memgenGroup(allocator, toplevel.addGroupWithTask(allocator, "memgen", .format));
    sysgenGroup(allocator, toplevel.addGroupWithTask(allocator, "sysgen", .format));
    buildgenGroup(allocator, toplevel.addGroupWithTask(allocator, "buildgen", .format));
    targetgenGroup(allocator, toplevel.addGroupWithTask(allocator, "targetgen", .format));
}
pub fn userGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    var user_build_cmd: zl.build.BuildCommand = build_cmd;
    user_build_cmd.modules = &.{};
    user_build_cmd.dependencies = &.{};
    const std_lib_cfg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_cfg", "test/user/std_lib_cfg.zig");
    const _std_lib: *Node = group.addBuild(allocator, user_build_cmd, "_std_lib", "test/user/std_lib.zig");
    user_build_cmd.modules = &.{.{
        .name = "zig_lib",
        .path = zl.builtin.lib_root ++ "/zig_lib.zig",
    }};
    user_build_cmd.dependencies = &.{.{ .name = "zig_lib" }};
    const std_lib_cfg_pkg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_cfg_pkg", "test/user/std_lib_cfg_pkg.zig");
    const std_lib_pkg: *Node = group.addBuild(allocator, user_build_cmd, "std_lib_pkg", "test/user/std_lib_pkg.zig");
    std_lib_cfg.descr = "Standard builtin, with build configuration, without library package";
    _std_lib.descr = "Standard builtin, without build configuration, without library package";
    std_lib_cfg_pkg.descr = "Standard builtin, with build configuration, library package";
    std_lib_pkg.descr = "Standard builtin, without build configuration, with library package";
}
pub fn exampleGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    const imports: *Node = group.addBuild(allocator, build_cmd, "imports", "examples/imports.zig");
    const itos: *Node = group.addBuild(allocator, build_cmd, "itos", "examples/itos.zig");
    const treez: *Node = group.addBuild(allocator, build_cmd, "treez", "examples/treez.zig");
    const elfcmp: *Node = group.addBuild(allocator, build_cmd, "elfcmp", "examples/elfcmp.zig");
    const buildgen: *Node = group.addBuild(allocator, build_cmd, "buildgen", "examples/buildgen.zig");
    const declprint: *Node = group.addBuild(allocator, build_cmd, "declprint", "examples/declprint.zig");

    imports.addToplevelArgs(allocator);
    buildgen.addToplevelArgs(allocator);

    treez.descr = "Example program useful for listing the contents of directories in a tree-like format";
    elfcmp.descr = "Wrapper for ELF size comparison";
    itos.descr = "Example program for integer base conversion";
    imports.descr = "List files imported from root";
    buildgen.descr = "Example WIP program for generating builder statements";
    declprint.descr = "Print declarations (large)";
}
pub fn buildRunnerTestGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    var test_build_cmd: zl.build.BuildCommand = build_cmd;
    test_build_cmd.strip = false;
    const dynamic_extensions: *Node = group.addBuild(allocator, test_build_cmd, "dynamic_extensions", "test/build/dynamic_extensions.zig");
    test_build_cmd.dependencies = &.{.{ .name = "@build" }};
    test_build_cmd.modules = &.{.{
        .name = "@build",
        .path = zl.builtin.lib_root ++ "/build.zig",
    }};
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
        .path = zl.builtin.lib_root ++ "/build.zig",
    }, .{
        .name = "zl",
        .path = zl.builtin.lib_root ++ "/zig_lib.zig",
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
fn regenGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    const regen: *Node = group.addBuild(allocator, build_cmd, "rebuild", "top/build/gen/rebuild_impls.zig");
    regen.tasks.cmd.build.modules = &.{.{ .name = "@build", .path = "./build.zig" }};
    regen.tasks.cmd.build.dependencies = &.{.{ .name = "@build" }};
}
fn topGroup(allocator: *zl.build.types.Allocator, group: *Node) void {
    group.addBuild(allocator, build_cmd, "decls", "test/decl.zig").descr = "Test miscellaneous declarations";
    group.addBuild(allocator, build_cmd, "builtin", "test/builtin.zig").descr = "Test builtin functions";
    group.addBuild(allocator, build_cmd, "meta", "test/meta.zig").descr = "Test meta functions";
    group.addBuild(allocator, build_cmd, "gen", "test/gen.zig").descr = "Test generic code generation functions";
    group.addBuild(allocator, build_cmd, "math", "test/math.zig").descr = "Test math functions";
    group.addBuild(allocator, build_cmd, "file", "test/file.zig").descr = "Test file functions";
    group.addBuild(allocator, build_cmd, "list", "test/list.zig").descr = "Test library generic linked list";
    group.addBuild(allocator, build_cmd, "fmt", "test/fmt.zig").descr = "Test general purpose formatting function";
    group.addBuild(allocator, build_cmd, "parse", "test/parse.zig").descr = "Test general purpose parsing functions";
    group.addBuild(allocator, build_cmd, "time", "test/time.zig").descr = "Test time-related functions";
    group.addBuild(allocator, build_cmd, "zig", "test/zig.zig").descr = "Test library Zig tokeniser";
    group.addBuild(allocator, build_cmd, "mem", "test/mem.zig").descr = "Test low level memory management functions";
    group.addBuild(allocator, build_cmd, "proc", "test/proc.zig").descr = "Test process-related functions";
    group.addBuild(allocator, build_cmd, "mem2", "test/mem2.zig").descr = "Test version 2 memory implementation";
    group.addBuild(allocator, build_cmd, "x86", "test/x86.zig").descr = "Test x86 assembler and disassembler";
    group.addBuild(allocator, build_cmd, "rng", "test/rng.zig").descr = "Test crytpo-RNG";
    group.addBuild(allocator, build_cmd, "crypto", "test/crypto.zig").descr = "Test crypto namespace (refAllDecls)";
    group.addBuild(allocator, build_cmd, "ecdsa", "test/crypto/ecdsa.zig").descr = "Test ECDSA";
    group.addBuild(allocator, build_cmd, "aead", "test/crypto/aead.zig").descr = "Test authenticated encryption functions and types";
    group.addBuild(allocator, build_cmd, "auth", "test/crypto/auth.zig").descr = "Test authentication";
    group.addBuild(allocator, build_cmd, "dh", "test/crypto/dh.zig").descr = "Test many 25519-related functions";
    group.addBuild(allocator, build_cmd, "tls", "test/crypto/tls.zig").descr = "Test TLS";
    group.addBuild(allocator, build_cmd, "core", "test/crypto/core.zig").descr = "test core crypto functionality";
    group.addBuild(allocator, build_cmd, "utils", "test/crypto/utils.zig").descr = "Test crypto utility functions";
    group.addBuild(allocator, build_cmd, "hash", "test/crypto/hash.zig").descr = "Test hashing functions";
    group.addBuild(allocator, build_cmd, "pcurves", "test/crypto/pcurves.zig").descr = "Test point curve operations";
    group.addBuild(allocator, build_cmd, "algo", "test/algo.zig").descr = "Test sorting and compression functions";
    group.addBuild(allocator, build_cmd, "fmt_cmp", "test/fmt_cmp.zig").descr = "Compare formatting methods";
    group.addBuild(allocator, build_cmd, "safety", "test/safety.zig").descr = "Test safety overhaul prototype";
}
pub fn buildMain(allocator: *zl.build.types.Allocator, toplevel: *Node) void {
    const build_runner: *Node = toplevel.addBuild(allocator, .{ .kind = .exe }, "build_runner", "build_runner.zig");
    build_runner.tasks.cmd.build.modules = &.{.{ .name = "@build", .path = zl.builtin.lib_root ++ "/build.zig" }};
    build_runner.tasks.cmd.build.dependencies = &.{.{ .name = "@build" }};
    build_runner.flags.want_build_config = false;
    build_runner.flags.want_stack_traces = false;
    const safety: *Node = toplevel.addBuild(allocator, build_cmd, "safety", "test/safety.zig");
    safety.flags.want_perf_events = true;
    safety.tasks.cmd.build.strip = false;
    traceGroup(allocator, toplevel.addGroupWithTask(allocator, "trace", .build));
    topGroup(allocator, toplevel.addGroupWithTask(allocator, "top", .build));
    exampleGroup(allocator, toplevel.addGroupWithTask(allocator, "examples", .build));
}
pub fn install(b: *@import("std").Build.Builder) void {
    const run_install = b.addSystemCommand(&.{ "bash", zl.builtin.lib_root ++ "/support/install.sh" });
    b.default_step.dependOn(&run_install.step);
}
pub usingnamespace struct {
    pub const build = if (@hasDecl(@import("root"), "dependencies")) install else zl.build;
};
