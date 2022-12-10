const std = @import("std");
const build = std.build;
const srg: std.build.Pkg = .{ .name = "zig_lib", .source = .{ .path = "zig_lib.zig" } };
const Context = opaque {
    var build_mode: std.builtin.Mode = undefined;
    var output_mode: std.builtin.OutputMode = undefined;
    var builder: *build.Builder = undefined;
    var test_step: *build.Step = undefined;
    var run_step: *build.Step = undefined;
    var install_step: *build.Step = undefined;
    var fmt_step: *build.Step = undefined;
    var always_strip: bool = true;
    fn init() void {
        Context.builder.reference_trace = 100;
        Context.build_mode = builder.standardReleaseOptions();
        Context.test_step = builder.step("test", "Run tests");
        Context.run_step = builder.step("run", "Run programs");
    }
};

// PROGRAM FILES ///////////////////////////////////////////////////////////////

pub fn main(builder: *build.Builder) !void {
    Context.builder = builder;
    Context.init();

    _ = addProjectExecutable(builder, "builtin_test", "top/builtin-test.zig", .{ .need_build_root = true });
    _ = addProjectExecutable(builder, "meta_test", "top/meta-test.zig", .{});
    _ = addProjectExecutable(builder, "mem_test", "top/mem-test.zig", .{});
    _ = addProjectExecutable(builder, "algo_test", "top/algo-test.zig", .{});
    _ = addProjectExecutable(builder, "file_test", "top/file-test.zig", .{});
}

// BOILERPLATE ////////////////////////////////////////////////////////////////

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
        const len: u64 = builder.build_root.len;
        build_root_s[0] = '"';
        for (builder.build_root) |c, i| build_root_s[i + 1] = c;
        build_root_s[len + 1] = '"';
        exe.defineCMacro("build_root", build_root_s[0 .. len + 2]);
        build_root_s[len] = 0;
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
        need_build_root: bool = false,
    };
}
fn addProjectExecutable(
    builder: *build.Builder,
    comptime name: [:0]const u8,
    comptime path: [:0]const u8,
    args: Args(name),
) *build.LibExeObjStep {
    const ret: *build.LibExeObjStep = builder.addExecutableSource(name, build.FileSource.relative(path));

    ret.build_mode = Context.build_mode;
    ret.omit_frame_pointer = false;
    ret.single_threaded = false;
    ret.image_base = 0x10000;
    ret.linkage = .static;
    ret.main_pkg_path = builder.build_root;
    ret.strip = (Context.always_strip or
        Context.build_mode == .ReleaseFast or
        Context.build_mode == .ReleaseSmall) or
        Context.output_mode == .Lib;

    const make_step: *build.Step = builder.step(args.make_step_name, args.make_step_desc);
    const run_step: *build.Step = builder.step(args.run_step_name, args.run_step_desc);
    if (args.need_build_root) {
        defineBuildRoot(builder, ret);
    }
    ret.addPackage(srg);
    ret.install();
    make_step.dependOn(&ret.step);
    make_step.dependOn(&ret.install_step.?.step);
    run_step.dependOn(make_step);
    run_step.dependOn(&ret.run().step);
    if (args.is_support orelse Utility.endsWith("-aux.zig", path)) {
        Context.run_step.dependOn(&ret.run().step);
    }
    if (args.is_test orelse Utility.endsWith("-test.zig", path)) {
        Context.test_step.dependOn(&ret.run().step);
    }
    return ret;
}
