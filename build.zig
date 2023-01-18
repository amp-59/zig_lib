pub const build = if (true) @import("build/build-aux.zig").main else main;
pub const srg = @import("./zig_lib.zig");

const mem = srg.mem;
const meta = srg.meta;
const builder = srg.builder;
const builtin = srg.builtin;

const BuildCmd = builder.BuildCmd;

fn get(comptime T: type) *T {
    var ret: T = 0;
    return &ret;
}
const Static = struct {
    const count: *u64 = get(u64);
};

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
pub fn main(ctx: *builder.Context) !void {
    var cmds: mem.StaticArray(BuildCmd, 64) = .{};

    const packages = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};
    const minor_test_args = .{ .is_correct = true, .is_verbose = true, .packages = packages };
    const algo_test_args = .{ .is_correct = true, .is_verbose = true, .build_mode = .ReleaseSmall, .packages = packages };
    const fmt_test_args = .{ .is_correct = true, .is_verbose = true, .build_mode = .Debug, .packages = packages };
    const perf_test_args = .{ .is_correct = false, .is_verbose = false, .packages = packages };
    const fast_test_args = .{ .is_correct = false, .is_verbose = false, .build_mode = .ReleaseFast, .packages = packages };
    const small_test_args = .{ .is_correct = false, .is_verbose = false, .build_mode = .ReleaseSmall, .packages = packages };

    cmds.writeOne(addProjectExecutable(ctx, "builtin_test", "top/builtin-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "meta_test", "top/meta-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "mem_test", "top/mem-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "algo_test", "top/algo-test.zig", algo_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "file_test", "top/file-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "list_test", "top/list-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "fmt_test", "top/fmt-test.zig", fmt_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "render_test", "top/render-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "thread_test", "top/thread-test.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "virtual_test", "top/virtual-test.zig", minor_test_args));

    // More complete test programs:
    cmds.writeOne(addProjectExecutable(ctx, "buildgen", "test/buildgen.zig", perf_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "mca", "test/mca.zig", fast_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "treez", "test/treez.zig", small_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "itos", "test/itos.zig", small_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "cat", "test/cat.zig", fast_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "hello", "test/hello.zig", small_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "readelf", "test/readelf.zig", minor_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "parsedir", "test/parsedir.zig", fast_test_args));
    cmds.writeOne(addProjectExecutable(ctx, "example", "test/example.zig", minor_test_args));

    // Other test programs:
    cmds.writeOne(addProjectExecutable(ctx, "impl_test", "top/impl-test.zig", .{ .is_large_test = true }));
    cmds.writeOne(addProjectExecutable(ctx, "container_test", "top/container-test.zig", .{ .is_large_test = true }));
    cmds.writeOne(addProjectExecutable(ctx, "parse_test", "top/parse-test.zig", .{ .is_correct = true, .is_verbose = true, .is_large_test = true }));

    for (ctx.args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualMany(u8, name, "all")) {
            for (cmds.readAll()) |cmd| {
                _ = try cmd.exec(ctx.vars);
            }
            return;
        }
        for (cmds.readAll()) |cmd| {
            if (cmd.name) |cmd_name| {
                if (mem.testEqualMany(u8, name, cmd_name)) {
                    _ = try cmd.exec(ctx.vars);
                }
            }
        }
    }
}
fn Args(comptime name: [:0]const u8) type {
    return struct {
        make_step_name: [:0]const u8 = name,
        make_step_desc: [:0]const u8 = "Build " ++ name,
        run_step_name: [:0]const u8 = "run-" ++ name,
        run_step_desc: [:0]const u8 = "...",
        emit_bin_path: ?[:0]const u8 = "zig-out/bin/" ++ name,
        emit_asm_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".s",
        emit_analysis_path: ?[:0]const u8 = "zig-out/bin/" ++ name ++ ".analysis",

        build_mode: ?@TypeOf(builtin.zig.mode) = null,
        build_working_directory: bool = false,

        is_test: ?bool = null,
        is_support: ?bool = null,

        is_correct: ?bool = null,
        is_perf: ?bool = null,
        is_verbose: ?bool = null,
        is_tolerant: ?bool = null,

        define_build_root: bool = true,
        define_build_working_directory: bool = true,

        is_large_test: bool = false,
        strip: bool = true,

        packages: ?builder.Packages = null,
        macros: ?builder.Macros = null,

        fn setMacro(
            comptime args: @This(),
            comptime macros: []const builder.Macro,
            comptime field_name: [:0]const u8,
        ) []const builder.Macro {
            comptime {
                if (@field(args, field_name)) |field| {
                    if (field) {
                        return meta.concat(
                            builder.Macro,
                            macros,
                            .{ .name = field_name, .value = "1" },
                        );
                    } else {
                        return meta.concat(
                            builder.Macro,
                            macros,
                            .{ .name = field_name, .value = "0" },
                        );
                    }
                }
                return macros;
            }
        }
    };
}

fn addProjectExecutable(ctx: *builder.Context, comptime name: [:0]const u8, comptime path: [:0]const u8, comptime args: Args(name)) BuildCmd {
    var ret: BuildCmd = .{
        .root = path,
        .cmd = .exe,
        .name = name,
    };
    ret.zig_exe = ctx.zig_exe;
    if (args.build_mode) |build_mode| {
        ret.O = build_mode;
    }
    if (args.emit_bin_path) |bin_path| {
        ret.emit_bin = .{ .yes = ctx.path(bin_path) };
    }
    if (args.emit_asm_path) |asm_path| {
        ret.emit_asm = .{ .yes = ctx.path(asm_path) };
    }
    comptime var macros: []const builder.Macro = args.macros orelse meta.empty;

    macros = comptime args.setMacro(macros, "is_correct");
    macros = comptime args.setMacro(macros, "is_perf");
    macros = comptime args.setMacro(macros, "is_tolerant");
    macros = comptime args.setMacro(macros, "is_verbose");

    ret.omit_frame_pointer = false;
    ret.single_threaded = true;
    ret.static = true;
    ret.enable_cache = true;
    ret.compiler_rt = false;
    ret.strip = true;
    ret.main_pkg_path = ctx.build_root;
    ret.macros = macros;
    ret.packages = args.packages;
    return ret;
}
