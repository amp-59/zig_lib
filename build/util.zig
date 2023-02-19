const std = @import("std");
const build = std.build;

// BOILERPLATE ////////////////////////////////////////////////////////////////

pub const Context = opaque {
    var build_mode: std.builtin.Mode = .Debug;
    var build_mode_explicit: bool = undefined;
    var output_mode: std.builtin.OutputMode = undefined;
    var builder: *build.Builder = undefined;
    var test_step: *build.Step = undefined;
    var test_all_step: *build.Step = undefined;
    var run_step: *build.Step = undefined;
    var install_step: *build.Step = undefined;
    var fmt_step: *build.Step = undefined;
    var srg: *std.build.Module = undefined;
    const always_strip: bool = true;
    pub fn init(b: *build.Builder) void {
        builder = b;
        Context.builder.reference_trace = 100;
        Context.build_mode = builder.standardOptimizeOption(.{});
        Context.test_step = builder.step("test", "Run most tests");
        Context.test_all_step = builder.step("test-all", "Run all tests");
        Context.test_all_step.dependOn(Context.test_step);
        Context.run_step = builder.step("run", "Run programs");
        Context.srg = b.createModule(.{ .source_file = .{ .path = "zig_lib.zig" } });
        Context.build_mode_explicit = build_mode != .Debug;
    }
};

const Utility = opaque {
    fn endsWith(end: anytype, seq: anytype) bool {
        if (end.len > seq.len) {
            return false;
        }
        const del: u64 = seq.len - end.len;
        for (end) |v, i| {
            if (seq[i + del] != v) return false;
        }
        return true;
    }
};
fn defineBuildRoot(builder: *build.Builder, exe: *build.LibExeObjStep) void {
    var build_root_s: [4098]u8 = .{0} ** 4098;
    {
        const len: u64 = builder.build_root.path.?.len;
        build_root_s[0] = '"';
        for (builder.build_root.path.?) |c, i| build_root_s[i + 1] = c;
        build_root_s[len + 1] = '"';
        exe.defineCMacro("build_root", build_root_s[0 .. len + 2]);
        build_root_s[len] = 0;
    }
}
fn defineRootSourceAboslutePath(builder: *build.Builder, exe: *build.LibExeObjStep) void {
    var root_source_s: [4098]u8 = .{0} ** 4098;
    var len: u64 = 0;
    root_source_s[len] = '"';
    len += 1;
    for (builder.build_root) |c, i| root_source_s[i + 1] = c;
    len += builder.build_root.len;
    root_source_s[len] = '/';
    len += 1;
    for (exe.root_src.?.path) |c, i| root_source_s[i + 1] = c;
    len += exe.root_src.?.path.len;
    root_source_s[len + 1] = '"';
    exe.defineCMacro("root_src_file", root_source_s[0 .. len + 2]);
    root_source_s[len] = 0;
}
fn defineMacroPath(exe: *build.LibExeObjStep, name: []const u8, pathname: []const u8) void {
    var quoted_pathname: [4098]u8 = .{0} ** 4098;
    var len: u64 = 0;
    quoted_pathname[len] = '"';
    len +%= 1;
    for (pathname) |c, i| quoted_pathname[i + 1] = c;
    len +%= pathname.len;
    quoted_pathname[len] = '"';
    quoted_pathname[len + 1] = 0;
    exe.defineCMacro(name, quoted_pathname[0 .. len + 2]);
}
fn defineConfig(exe: *build.LibExeObjStep, name: []const u8, value: bool) void {
    if (value) {
        exe.defineCMacro(name, "1");
    } else {
        exe.defineCMacro(name, "0");
    }
}
pub fn Args(comptime name: [:0]const u8) type {
    return struct {
        is_test: ?bool = null,
        is_support: ?bool = null,
        make_step_name: [:0]const u8 = name,
        make_step_desc: [:0]const u8 = "Build " ++ name,
        run_step_name: [:0]const u8 = "run-" ++ name,
        run_step_desc: [:0]const u8 = "...",
        emit_asm_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".s",
        emit_analysis_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".analysis",
        build_mode: ?std.builtin.Mode = null,
        build_root: bool = true,
        root_src_file: bool = true,
        build_working_directory: bool = false,
        runtime_assertions: ?bool = null,
        is_silent: ?bool = null,
        is_perf: ?bool = null,
        is_verbose: ?bool = null,
        is_tolerant: ?bool = null,
        is_large_test: bool = false,
        strip: bool = Context.always_strip,
    };
}
pub fn addProjectExecutable(builder: *build.Builder, comptime name: [:0]const u8, comptime path: [:0]const u8, args: Args(name)) *build.LibExeObjStep {
    const ret: *build.LibExeObjStep = builder.addExecutable(.{ .name = name, .root_source_file = .{ .path = path } });
    ret.optimize = if (Context.build_mode_explicit) Context.build_mode else args.build_mode orelse Context.build_mode;
    ret.omit_frame_pointer = false;
    ret.single_threaded = false;
    ret.image_base = 0x10000;
    ret.linkage = .static;
    ret.main_pkg_path = builder.build_root.path;
    ret.bundle_compiler_rt = false;
    ret.strip = (args.strip or
        Context.build_mode == .ReleaseFast or
        Context.build_mode == .ReleaseSmall) or
        Context.output_mode == .Lib;

    const make_step: *build.Step = builder.step(args.make_step_name, args.make_step_desc);
    const run_step: *build.Step = builder.step(args.run_step_name, args.run_step_desc);
    if (args.build_root) {
        defineBuildRoot(builder, ret);
    }
    if (args.runtime_assertions) |runtime_assertions| {
        defineConfig(ret, "runtime_assertions", runtime_assertions);
    }
    if (args.is_silent) |is_silent| {
        defineConfig(ret, "is_silent", is_silent);
    }
    if (args.is_verbose) |is_verbose| {
        defineConfig(ret, "is_verbose", is_verbose);
    }
    if (args.is_perf) |is_perf| {
        defineConfig(ret, "is_perf", is_perf);
    }

    ret.addModule("zig_lib", Context.srg);
    ret.install();
    ret.link_gc_sections = true;
    ret.link_function_sections = true;
    ret.disable_stack_probing = true;
    ret.code_model = .kernel;
    defineMacroPath(ret, "zig_exe", builder.zig_exe);
    defineMacroPath(ret, "build_root", builder.build_root.path.?);
    defineMacroPath(ret, "cache_dir", builder.cache_root.path.?);
    defineMacroPath(ret, "global_cache_dir", builder.global_cache_root.path.?);
    make_step.dependOn(&ret.step);
    make_step.dependOn(&ret.install_step.?.step);
    run_step.dependOn(make_step);
    run_step.dependOn(&ret.run().step);

    if (args.is_support orelse Utility.endsWith("-aux.zig", path)) {
        Context.run_step.dependOn(&ret.run().step);
    }
    if (args.is_large_test or
        args.is_test orelse Utility.endsWith("-test.zig", path))
    {
        if (args.is_large_test) {
            Context.test_all_step.dependOn(&ret.run().step);
        } else {
            Context.test_step.dependOn(&ret.run().step);
        }
    }
    return ret;
}
