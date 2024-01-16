pub const zl = @import("zig_lib.zig");
pub const Builder = zl.builder.GenericBuilder(.{
    .options = .{ .extensions_policy = .emergency },
});
const build_cmd = .{
    .kind = .exe,
    .reference_trace = true,
    .function_sections = true,
    .compiler_rt = false,
    .gc_sections = true,
    .image_base = 65536,
};
const build_mod = .{
    .omit_frame_pointer = false,
    .mode = .Debug,
    .stack_check = false,
    .stack_protector = false,
    .single_threaded = true,
    .valgrind = false,
    .unwind_tables = false,
    .strip = true,
};
const format_cmd = .{
    .ast_check = true,
};
pub const enable_debugging: bool = true;
const Node = Builder.Node;
pub fn memgenGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var memgen_format_cmd: zl.builder.FormatCommand = format_cmd;
    memgen_format_cmd.ast_check = false;
    const impls = group.addGroupWithTask(allocator, "impls", .format);
    impls.flags.is_hidden = true;
    const impls_build_cmd: zl.builder.BuildCommand = build_cmd;
    const impls_specs: *Node = impls.addBuild(allocator, impls_build_cmd, build_mod, "specs", "top/mem/gen/specs.zig");
    const impls_ptr: *Node = impls.addBuild(allocator, impls_build_cmd, build_mod, "ptr", "top/mem/gen/ptr_impls.zig");
    const impls_ctn: *Node = impls.addBuild(allocator, impls_build_cmd, build_mod, "ctn", "top/mem/gen/ctn_impls.zig");
    const impls_alloc: *Node = impls.addBuild(allocator, impls_build_cmd, build_mod, "alloc", "top/mem/gen/alloc_impls.zig");
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
pub fn sysgenGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    var sysgen_format_cmd: zl.builder.FormatCommand = format_cmd;
    sysgen_format_cmd.ast_check = false;
    const flags: *Builder.Node = group.addBuild(allocator, build_cmd, build_mod, "flags", "top/sys/gen/flags.zig");
    const fns: *Builder.Node = group.addBuild(allocator, build_cmd, build_mod, "fns", "top/sys/gen/fns.zig");
    const format: *Builder.Node = group.addFormat(allocator, sysgen_format_cmd, "format", "top/sys");
    flags.descr = "Generate system function option bit field struct definitions";
    fns.descr = "Generate system function wrapper functions";
    format.addDepn(allocator, .format, flags, .run);
    format.addDepn(allocator, .format, fns, .run);
}
pub fn buildgenGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    const buildgen_format_cmd: zl.builder.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    const cmd: zl.builder.BuildCommand = build_cmd;
    const mod: zl.builder.BuildCommand.Module = build_mod;
    const impls_tasks: *Node = impls.addBuild(allocator, cmd, mod, "tasks", "top/build/gen/tasks_impls.zig");
    const impls_parsers: *Node = impls.addBuild(allocator, cmd, mod, "parsers", "top/build/gen/parsers_impls.zig");
    const impls_libs: *Node = impls.addBuild(allocator, cmd, mod, "libs", "top/build/gen/libs_impls.zig");
    const format: *Node = group.addFormat(allocator, buildgen_format_cmd, "format", "top/build");
    impls_tasks.descr = "Generate builder command line data structures";
    impls_parsers.descr = "Generate exports for builder task command line parser functions";
    impls_libs.descr = "Generate headers and exporters for dynamic loaded functions";
    format.descr = "Reformat generated source code into canonical form";
    impls_parsers.addDepn(allocator, .build, impls_tasks, .run);
    impls_libs.addDepn(allocator, .build, impls_parsers, .run);
    format.addDepn(allocator, .format, impls_libs, .run);
}
pub fn targetgenGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    const targetgen_format_cmd: zl.builder.FormatCommand = format_cmd;
    const impls = group.addGroupWithTask(allocator, "impls", .run);
    impls.flags.is_hidden = true;
    const impls_build_cmd: zl.builder.BuildCommand = build_cmd;
    const impls_arch: *Node = impls.addBuild(allocator, impls_build_cmd, "arch", "top/target/gen/arch_impls.zig");
    const impls_target: *Node = impls.addBuild(allocator, impls_build_cmd, "target", "top/target/gen/target_impl.zig");
    const format: *Node = group.addFormat(allocator, targetgen_format_cmd, "format", "top/target");
    impls_arch.descr = "Generate target information for supported architectures";
    format.descr = "Reformat generated target information into canonical form";
    impls_target.dependOn(allocator, impls_arch);
    format.addDepn(allocator, .format, impls_target, .run);
}
pub fn sliceTestGenGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    @setRuntimeSafety(false);
    const slicegen_format_cmd: zl.builder.FormatCommand = format_cmd;
    const impls = group.addGroup(allocator, "impls", .{
        .zig_exe = "../zig/zig-out/bin/zig-safety_rework-fast",
        .build_root = group.buildRoot(),
        .cache_root = group.cacheRoot(),
        .global_cache_root = group.globalCacheRoot(),
    });
    impls.tasks.tag = .run;
    impls.flags.is_hidden = true;
    const impls_build_cmd: zl.builder.BuildCommand = .{
        .kind = .exe,
        .modules = build_cmd.modules,
        .dependencies = build_cmd.dependencies,
        .compiler_rt = false,
        .extra_slice_analysis = true,
    };
    const impls_clean: *Node = impls.addBuild(allocator, impls_build_cmd, "clean", "top/mem/gen/test_clean.zig");
    const impls_test: *Node = impls.addBuild(allocator, impls_build_cmd, "impls", "top/mem/gen/test_impls.zig");
    const format_src: *Node = group.addFormat(allocator, slicegen_format_cmd, "format_src", "test/safety/slice");
    const format_build: *Node = group.addFormat(allocator, slicegen_format_cmd, "format_build", "slice_test.zig");
    impls_clean.descr = "Remove existing test source files";
    impls_test.descr = "Generate slice behaviour tests for every permutation";
    format_src.descr = "Reformat generated slice permutation attributes and test sources";
    impls_test.addDepn(allocator, .build, impls_clean, .run);
    format_src.addDepn(allocator, .format, impls_test, .run);
    format_build.addDepn(allocator, .format, format_src, .format);
}
pub fn generators(allocator: *zl.builder.types.Allocator, toplevel: *Node) void {
    memgenGroup(allocator, toplevel.addGroupWithTask(allocator, "memgen", .format));
    sysgenGroup(allocator, toplevel.addGroupWithTask(allocator, "sysgen", .format));
    buildgenGroup(allocator, toplevel.addGroupWithTask(allocator, "buildgen", .format));
    if (return) {}
    //targetgenGroup(allocator, toplevel.addGroupWithTask(allocator, "targetgen", .format));
    sliceTestGenGroup(allocator, toplevel.addGroupWithTask(allocator, "slicegen", .format));
}
pub fn userGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    var user_build_cmd: zl.builder.BuildCommand = build_cmd;
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
pub fn exampleGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    for ([_]struct { [:0]const u8, [:0]const u8, [:0]const u8 }{
        .{ "imports", "examples/imports.zig", "List files imported from root" },
        .{ "itos", "examples/itos.zig", "Example program for integer base conversion" },
        .{ "elfcmp", "examples/elfcmp.zig", "Wrapper for ELF size comparison" },
        .{ "buildgen", "examples/buildgen.zig", "Example WIP program for generating builder statements" },
        .{ "declprint", "examples/declprint.zig", "Print declarations (large)" },
        .{ "display", "examples/display.zig", "Example usage of ioctl (and other system calls without a wrapper)" },
        .{ "touch", "examples/touch.zig", "Example usage of open, write, and truncate (maybe futimens) to COW a hard-linked file" },
        .{ "slices", "examples/slice_test.zig", "Generate tests for every slice permutation and every outcome" },
    }) |args| {
        const node: *Node = group.addBuild(allocator, build_cmd, build_mod, args[0], args[1]);
        node.descr = args[2];
    }
    group.find("imports").addToplevelArgs(allocator);
    group.find("buildgen").addToplevelArgs(allocator);
}
fn topGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    for ([_]struct { [:0]const u8, [:0]const u8, [:0]const u8 }{
        .{ "decls", "test/decl.zig", "Test miscellaneous declarations" },
        .{ "builtin", "test/builtin.zig", "Test builtin functions" },
        .{ "meta", "test/meta.zig", "Test meta functions" },
        .{ "gen", "test/gen.zig", "Test generic code generation functions" },
        .{ "math", "test/math.zig", "Test math functions" },
        .{ "file", "test/file.zig", "Test file functions" },
        .{ "list", "test/list.zig", "Test library generic linked list" },
        .{ "fmt", "test/fmt.zig", "Test general purpose formatting function" },
        .{ "parse", "test/parse.zig", "Test general purpose parsing functions" },
        .{ "time", "test/time.zig", "Test time-related functions" },
        .{ "zig", "test/zig.zig", "Test library Zig tokeniser" },
        .{ "mem", "test/mem.zig", "Test low level memory management functions" },
        .{ "proc", "test/proc.zig", "Test process-related functions" },
        .{ "mem2", "test/mem2.zig", "Test version 2 memory implementation" },
        .{ "x86", "test/x86.zig", "Test x86 assembler and disassembler" },
        .{ "rng", "test/rng.zig", "Test crytpo-RNG" },
        .{ "ecdsa", "test/crypto/ecdsa.zig", "Test ECDSA" },
        .{ "aead", "test/crypto/aead.zig", "Test authenticated encryption functions and types" },
        .{ "auth", "test/crypto/auth.zig", "Test authentication" },
        .{ "dh", "test/crypto/dh.zig", "Test many 25519-related functions" },
        .{ "tls", "test/crypto/tls.zig", "Test TLS" },
        .{ "core", "test/crypto/core.zig", "Test core crypto functionality" },
        .{ "utils", "test/crypto/utils.zig", "Test crypto utility functions" },
        .{ "hash", "test/crypto/hash.zig", "Test hashing functions" },
        .{ "pcurves", "test/crypto/pcurves.zig", "Test point curve operations" },
        .{ "algo", "test/algo.zig", "Test sorting and compression functions" },
        .{ "safety", "test/safety.zig", "Test safety overhaul prototype" },
    }) |args| {
        const node: *Node = group.addBuild(allocator, build_cmd, build_mod, args[0], args[1]);
        node.descr = args[2];
    }
    group.find("fmt").tasks.cmd.build.compiler_rt = true;
}
pub fn traceGroup(allocator: *zl.builder.types.Allocator, group: *Node) void {
    var mod: zl.builder.BuildCommand.Module = build_mod;
    mod.omit_frame_pointer = false;
    mod.unwind_tables = false;
    for ([_]struct { [:0]const u8, [:0]const u8, [:0]const u8 }{
        .{ "access_inactive", "test/trace/access_inactive.zig", "Test stack trace for accessing inactive union field (panicInactiveUnionField)" },
        .{ "assertion_failed", "test/trace/assertion_failed.zig", "Test stack trace for assertion failed" },
        .{ "out_of_bounds", "test/trace/out_of_bounds.zig", "Test stack trace for out-of-bounds (panicOutOfBounds)" },
        .{ "reach_unreachable", "test/trace/reach_unreachable.zig", "Test stack trace for reaching unreachable code" },
        .{ "sentinel_mismatch", "test/trace/sentinel_mismatch.zig", "Test stack trace for sentinel mismatch (panicSentinelMismatch)" },
        .{ "stack_overflow", "test/trace/stack_overflow.zig", "Test stack trace for stack overflow" },
        .{ "start_gt_end", "test/trace/start_gt_end.zig", "Test stack trace for out-of-bounds (panicStartGreaterThanEnd)" },
    }) |args| {
        const node: *Node = group.addBuild(allocator, build_cmd, mod, args[0], args[1]);
        node.descr = args[2];
    }
}
pub fn buildMain(allocator: *zl.builder.types.Allocator, toplevel: *Node) void {
    topGroup(allocator, toplevel.addGroupWithTask(allocator, "top", .build));
    exampleGroup(allocator, toplevel.addGroupWithTask(allocator, "examples", .build));
    traceGroup(allocator, toplevel.addGroupWithTask(allocator, "trace", .build));
    generators(allocator, toplevel);
}
// This thing enables ZLS modules:
// Figure out some way to make this easily used. `usingnamespace` prone to dependency loops.
const std = @import("std");
fn convertBuild(
    allocator: *zl.builder.types.Allocator,
    b: *std.Build,
    target: anytype,
    optimize: anytype,
    node: *Builder.Node,
) void {
    var itr: Builder.Node.Iterator = Builder.Node.Iterator.init(node);
    while (itr.next()) |sub_node| {
        if (sub_node.flags.is_group) {
            convertBuild(allocator, b, target, optimize, sub_node);
        } else if (sub_node.tasks.tag == .build and
            sub_node.flags.have_task_data)
        {
            if (sub_node.getPath(.{ .tag = .input_zig })) |input_zig| {
                const absolute_path: [:0]const u8 = input_zig.concatenate(allocator);
                const relative_path: [:0]const u8 = absolute_path[node.buildRoot().len +% 1 ..];
                const exe = switch (sub_node.tasks.cmd.build.kind) {
                    .exe => b.addExecutable(.{
                        .name = sub_node.name,
                        .root_source_file = .{ .path = relative_path },
                        .target = target,
                        .optimize = optimize,
                    }),
                    .obj, .lib => b.addObject(.{
                        .name = sub_node.name,
                        .root_source_file = .{ .path = relative_path },
                        .target = target,
                        .optimize = optimize,
                    }),
                };
                b.step(sub_node.name, "").dependOn(&exe.step);
                var fs_idx: usize = 0;
                for (sub_node.lists.mods) |mod| {
                    for (sub_node.lists.files[fs_idx..], fs_idx..) |fs, next| {
                        if (fs.key.tag == .input_zig) {
                            exe.root_module.addAnonymousImport(
                                mod.name.?,
                                .{ .root_source_file = .{ .path = sub_node.lists.paths[fs.path_idx].concatenate(allocator) } },
                            );
                            fs_idx = next +% 1;
                            break;
                        }
                    }
                }
            }
        }
    }
}
pub fn build(b: *std.Build) void {
    const arena = Builder.AddressSpace.arena(Builder.specification.options.max_thread_count);
    zl.mem.map(.{
        .errors = .{},
        .logging = .{ .Acquire = false },
    }, .{}, .{}, arena.lb_addr, 4096);
    var allocator: zl.builder.types.Allocator = .{
        .start = arena.lb_addr,
        .next = arena.lb_addr,
        .finish = arena.lb_addr +% 4096,
    };
    var address_space: Builder.AddressSpace = .{};
    var thread_space: Builder.ThreadSpace = .{};
    const top: *Builder.Node = Builder.Node.init(&allocator, std.os.argv, std.os.environ);
    top.sh.as.lock = &address_space;
    top.sh.ts.lock = &thread_space;
    try zl.meta.wrap(buildMain(&allocator, top));
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});
    convertBuild(&allocator, b, target, optimize, top);
}
