const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const fmt = @import("./fmt.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const build = @import("./build.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;
pub usingnamespace proc.exception;

pub const AddressSpace = preset.address_space.regular_128;
pub const runtime_assertions: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .AddressSpace = AddressSpace,
});

const modules = &.{.{ .name = "zig_lib", .path = "./zig_lib.zig" }};

const minor_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
};
const algo_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .build_mode = .ReleaseSmall,
    .modules = modules,
};
const fmt_test_args = .{
    .runtime_assertions = true,
    .is_verbose = true,
    .modules = modules,
};
const fast_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseFast,
    .modules = modules,
};
const small_test_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .build_mode = .ReleaseSmall,
    .modules = modules,
};
const lib_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_lib_macros,
    .modules = modules,
};
const std_parser_args = .{
    .runtime_assertions = false,
    .is_verbose = false,
    .is_silent = true,
    .build_mode = .ReleaseFast,
    .macros = parsedir_std_macros,
    .modules = modules,
};
const parsedir_std_macros: []const build.Macro = meta.slice(build.Macro, .{.{
    .name = "test_subject",
    .value = .{ .string = "std" },
}});
const parsedir_lib_macros: []const build.Macro = meta.slice(build.Macro, .{.{
    .name = "test_subject",
    .value = .{ .string = "lib" },
}});

const Options = build.GlobalOptions;

const general_macros: []const build.Macro = &.{
    .{ .name = "is_verbose", .value = .{ .constant = 0 } },
    .{ .name = "runtime_assertions", .value = .{ .constant = 0 } },
    .{ .name = "build_root", .value = .{ .string = builtin.build_root.? } },
};
const zig_lib: []const build.Module = &.{
    .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
};

const release_fast_s: [:0]const u8 = "prioritise low runtime";
const release_small_s: [:0]const u8 = "prioritise small executable size";
const release_safe_s: [:0]const u8 = "prioritise correctness";
const debug_s: [:0]const u8 = "prioritise comptime performance";
const strip_s: [:0]const u8 = "do not emit debug symbols";
const no_strip_s: [:0]const u8 = "emit debug symbols";
const verbose_s: [:0]const u8 = "show compile commands when executing";
const silent_s: [:0]const u8 = "do not show compile commands when executing";
const run_cmd_s: [:0]const u8 = "run commands for subsequent targets";
const build_cmd_s: [:0]const u8 = "build commands for subsequent targets";
const fmt_cmd_s: [:0]const u8 = "fmt commands for subsequent targets";

// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "build_mode",  .long = "--fast",       .assign = .{ .any = &(.ReleaseFast) },  .descr = release_fast_s },
    .{ .field_name = "build_mode",  .long = "--small",      .assign = .{ .any = &(.ReleaseSmall) }, .descr = release_small_s },
    .{ .field_name = "build_mode",  .long = "--safe",       .assign = .{ .any = &(.ReleaseSafe) },  .descr = release_safe_s },
    .{ .field_name = "build_mode",  .long = "--debug",      .assign = .{ .any = &(.Debug) },        .descr = debug_s },
    .{ .field_name = "strip",       .long = "-fstrip",      .assign = .{ .boolean = true },         .descr = strip_s },
    .{ .field_name = "strip",       .long = "-fno-strip",   .assign = .{ .boolean = false },        .descr = no_strip_s },
    .{ .field_name = "verbose",     .long = "--verbose",    .assign = .{ .boolean = true },         .descr = verbose_s },
    .{ .field_name = "verbose",     .long = "--silent",     .assign = .{ .boolean = false },        .descr = silent_s },
    .{ .field_name = "cmd",         .long = "--run",        .assign = .{ .any = &(.run) },          .descr = run_cmd_s },
    .{ .field_name = "cmd",         .long = "--build",      .assign = .{ .any = &(.build) },        .descr = build_cmd_s },
    .{ .field_name = "cmd",         .long = "--fmt",        .assign = .{ .any = &(.fmt) },          .descr = fmt_cmd_s },
});
// zig fmt: on
//
pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var args: [][*:0]u8 = args_in;
    var options: Options = proc.getOpts(Options, &args, opts_map);
    var allocator: Allocator = try Allocator.init(&address_space);
    var builder: build.Builder = build.Builder.init(&allocator, build.Builder.Paths.define(), .{}, args_in, vars);
    _ = builder.addGroup(&allocator, "all");
    do_build(&allocator, &builder);

    var index: u64 = 0;

    while (index != args_in.len) {
        const name: [:0]const u8 = meta.manyToSlice(args_in[index]);
        if (mem.testEqualMany(u8, name, "--")) {
            break;
        }
        var groups: build.GroupList = builder.groups.itr();
        while (groups.next()) |group_node| : (groups.node = group_node) {
            const match_all: bool = mem.testEqualMany(u8, name, groups.node.this.name);
            var targets: build.TargetList = groups.node.this.targets.itr();
            while (targets.next()) |target_node| : (targets.node = target_node) {
                if (match_all or mem.testEqualMany(u8, name, targets.node.this.build_cmd.name orelse continue)) {
                    switch (options.cmd) {
                        .fmt => try targets.node.this.format(),
                        .run => try targets.node.this.run(),
                        .build => try targets.node.this.build(),
                    }
                }
            }
        }
        index +%= 1;
    }
}

fn do_build(allocator: *build.Allocator, builder: *build.Builder) void {
    const builtin_test: *build.Target = builder.addTarget(.{}, allocator, "builtin_test", "top/builtin-test.zig");
    const meta_test: *build.Target = builder.addTarget(.{}, allocator, "meta_test", "top/meta-test.zig");
    const mem_test: *build.Target = builder.addTarget(.{}, allocator, "mem_test", "top/mem-test.zig");
    const algo_test: *build.Target = builder.addTarget(.{}, allocator, "algo_test", "top/algo-test.zig");
    const file_test: *build.Target = builder.addTarget(.{}, allocator, "file_test", "top/file-test.zig");
    const list_test: *build.Target = builder.addTarget(.{}, allocator, "list_test", "top/list-test.zig");
    const fmt_test: *build.Target = builder.addTarget(.{}, allocator, "fmt_test", "top/fmt-test.zig");
    const render_test: *build.Target = builder.addTarget(.{}, allocator, "render_test", "top/render-test.zig");
    const thread_test: *build.Target = builder.addTarget(.{}, allocator, "thread_test", "top/thread-test.zig");
    const virtual_test: *build.Target = builder.addTarget(.{}, allocator, "virtual_test", "top/virtual-test.zig");
    const build_test: *build.Target = builder.addTarget(.{}, allocator, "build_test", "top/build-test.zig");
    for ([_]*build.Target{
        builtin_test, meta_test,    mem_test,   algo_test,
        file_test,    list_test,    fmt_test,   render_test,
        thread_test,  virtual_test, build_test,
    }) |_| {}

    // More complete test programs:
    const mca: *build.Target = builder.addTarget(.{}, allocator, "mca", "test/mca.zig");
    const treez: *build.Target = builder.addTarget(.{}, allocator, "treez", "test/treez.zig");
    const itos: *build.Target = builder.addTarget(.{}, allocator, "itos", "test/itos.zig");
    const cat: *build.Target = builder.addTarget(.{}, allocator, "cat", "test/cat.zig");
    const hello: *build.Target = builder.addTarget(.{}, allocator, "hello", "test/hello.zig");
    const readelf: *build.Target = builder.addTarget(.{}, allocator, "readelf", "test/readelf.zig");
    const parsedir: *build.Target = builder.addTarget(.{}, allocator, "parsedir", "test/parsedir.zig");
    for (.{ mca, treez, itos, cat, hello, readelf, parsedir }) |_| {}

    // Other test programs:
    const impl_test: *build.Target = builder.addTarget(.{}, allocator, "impl_test", "top/impl-test.zig");
    const container_test: *build.Target = builder.addTarget(.{}, allocator, "container_test", "top/container-test.zig");
    const parse_test: *build.Target = builder.addTarget(.{}, allocator, "parse_test", "top/parse-test.zig");
    const lib_parser_test: *build.Target = builder.addTarget(.{}, allocator, "lib_parser", "test/parsedir.zig");
    const std_parser_test: *build.Target = builder.addTarget(.{}, allocator, "std_parser", "test/parsedir.zig");
    for (.{ impl_test, container_test, parse_test, lib_parser_test, std_parser_test }) |_| {}

    // Examples
    const readdir: *build.Target = builder.addTarget(.{}, allocator, "readdir", "examples/iterate_dir_entries.zig");
    const dynamic: *build.Target = builder.addTarget(.{}, allocator, "dynamic", "examples/dynamic_alloc.zig");
    const address_space: *build.Target = builder.addTarget(.{}, allocator, "address_space", "examples/custom_address_space.zig");
    for (.{ readdir, dynamic, address_space }) |_| {}

    const expr_test = builder.addTarget(.{}, allocator, "expr_test", "top/mem/expr-test.zig");
    _ = expr_test;
}
