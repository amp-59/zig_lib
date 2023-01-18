pub const build = if (false) @import("build/build-aux.zig").main else main;

pub const srg = @import("./zig_lib.zig");
const sys = srg.sys;
const mem = srg.mem;
const proc = srg.proc;
const time = srg.time;
const meta = srg.meta;
const file = srg.file;
const thread = srg.thread;
const preset = srg.preset;
const builder = srg.builder;
const builtin = srg.builtin;

pub fn main(ctx: *builder.Context) !void {
    try addProjectExecutable(ctx, "builtin_test", "top/builtin-test.zig", .{ .build_root = true, .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "meta_test", "top/meta-test.zig", .{ .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "mem_test", "top/mem-test.zig", .{ .is_correct = true, .is_verbose = true, .strip = true });
    try addProjectExecutable(ctx, "algo_test", "top/algo-test.zig", .{ .build_mode = .ReleaseSmall, .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "file_test", "top/file-test.zig", .{ .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "list_test", "top/list-test.zig", .{ .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "fmt_test", "top/fmt-test.zig", .{ .build_mode = .Debug, .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "render_test", "top/render-test.zig", .{ .is_correct = true, .is_verbose = true });
    try addProjectExecutable(ctx, "parse_test", "top/parse-test.zig", .{ .is_correct = true, .is_verbose = true, .is_test = false });
    try addProjectExecutable(ctx, "thread_test", "top/thread-test.zig", .{ .is_test = true, .build_root = true });
    try addProjectExecutable(ctx, "virtual_test", "top/virtual-test.zig", .{ .is_correct = true, .is_verbose = true });

    // More complete test programs:
    try addProjectExecutable(ctx, "buildgen", "test/buildgen.zig", .{ .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "mca", "test/mca.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "treez", "test/treez.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "itos", "test/itos.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "cat", "test/cat.zig", .{ .build_mode = .ReleaseFast, .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "hello", "test/hello.zig", .{ .build_mode = .ReleaseSmall, .is_correct = false, .is_verbose = false });
    try addProjectExecutable(ctx, "readelf", "test/readelf.zig", .{ .build_root = true });
    try addProjectExecutable(ctx, "parsedir", "test/parsedir.zig", .{ .build_mode = .ReleaseFast, .build_root = true });
    // try addProjectExecutable(ctx, "pathsplit", "test/pathsplit.zig", .{ .build_root = true });
    try addProjectExecutable(ctx, "example", "test/example.zig", .{ .build_root = true });

    // Other test programs:
    try addProjectExecutable(ctx, "impl_test", "top/impl-test.zig", .{ .is_large_test = true, .build_root = true });
    try addProjectExecutable(ctx, "container_test", "top/container-test.zig", .{ .is_large_test = true, .build_root = true });
}
fn relative(ctx: *builder.Context, relative_pathname: [:0]const u8) mem.StaticString(4096) {
    var ret: mem.StaticString(4096) = .{};
    ret.writeMany(ctx.build_root);
    ret.writeOne('/');
    ret.writeMany(relative_pathname);
    return ret;
}
fn macroString(pathname: [:0]const u8) mem.StaticString(4096) {
    var ret: mem.StaticString(4096) = .{};
    ret.writeOne('\"');
    ret.writeMany(pathname);
    ret.writeOne('\"');
    return ret;
}
fn addProjectExecutable(ctx: *builder.Context, comptime name: [:0]const u8, path: [:0]const u8, args: struct {
    is_test: ?bool = null,
    is_support: ?bool = null,
    make_step_name: [:0]const u8 = name,
    make_step_desc: [:0]const u8 = "Build " ++ name,
    run_step_name: [:0]const u8 = "run-" ++ name,
    run_step_desc: [:0]const u8 = "...",
    emit_bin_path: ?[:0]const u8 = "zig-out/bin/" ++ name,
    emit_asm_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".s",
    emit_analysis_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".analysis",
    build_mode: ?@TypeOf(builtin.zig.mode) = null,
    build_root: bool = true,
    root_src_file: bool = true,
    build_working_directory: bool = false,
    is_correct: ?bool = null,
    is_perf: ?bool = null,
    is_verbose: ?bool = null,
    is_tolerant: ?bool = null,
    is_large_test: bool = false,
    strip: bool = true,
}) !void {
    var ret: builder.BuildCmd(.{}) = .{ .root = path, .cmd = .run };
    ret.O = args.build_mode;
    ret.omit_frame_pointer = false;
    ret.single_threaded = true;
    ret.static = true;
    ret.enable_cache = true;
    ret.main_pkg_path = ctx.build_root;
    ret.compiler_rt = false;
    ret.strip = true;
    if (args.emit_bin_path) |pathname| {
        ret.emit_bin = .{ .yes = relative(ctx, pathname).readAll() };
    }
    //if (args.emit_asm_path) |pathname| {
    //    ret.emit_asm = .{ .yes = relative(ctx, pathname).readAll() };
    //}
    ret.macros = &.{.{ .name = "build_root", .value = macroString(ctx.build_root).readAll() }};
    ret.packages = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
    _ = try ret.exec(ctx.vars);
}
