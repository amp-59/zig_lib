const root = @import("@build");
const srg = root.srg;
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const meta = srg.meta;
const build = srg.build;
const preset = srg.preset;
const builtin = srg.builtin;

pub const AddressSpace = build.AddressSpace;
pub const is_verbose: bool = true;
pub const runtime_assertions: bool = false;
pub const is_silent: bool = false;

pub usingnamespace proc.start;

const Options = build.GlobalOptions;
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "build_mode", .long = "-Drelease-fast", .assign = .{ .any = &(.ReleaseFast) }, .descr = "speed++" },
    .{ .field_name = "build_mode", .long = "-Drelease-small", .assign = .{ .any = &(.ReleaseSmall) }, .descr = "size--" },
    .{ .field_name = "build_mode", .long = "-Drelease-safe", .assign = .{ .any = &(.ReleaseSafe) }, .descr = "safety++" },
    .{ .field_name = "build_mode", .long = "-Ddebug", .assign = Options.debug, .descr = "crashing++ " },
    .{ .field_name = "strip", .long = "-fstrip", .assign = Options.yes, .descr = "do not emit debug symbols" },
    .{ .field_name = "strip", .long = "-fno-strip", .assign = Options.no, .descr = "emit debug symbols" },
    .{ .field_name = "verbose", .long = "--verbose", .assign = Options.yes, .descr = "show compile commands when executing" },
    .{ .field_name = "verbose", .long = "--silent", .assign = Options.no, .descr = "do not show compile commands when executing" },
});
fn commandNotFoundException(builder: *const build.Builder, arg: [:0]const u8) !void {
    var buf: [128 + 4096 + 512]u8 = undefined;
    builtin.debug.logAlwaysAIO(&buf, &.{ "command not found: ", arg, "\n" });
    builtin.debug.logAlways(comptime Options.Map.helpMessage(opts_map));
    showAllCommands(builder);
    return error.CommandNotFound;
}
fn showAllCommands(builder: *const build.Builder) void {
    var buf: [128 + 4096 + 512]u8 = undefined;
    builtin.debug.logAlways("commands:\n");
    for (builder.targets.readAll()) |target, index| {
        const cmd_name: []const u8 = target.cmd.name orelse builtin.fmt.ud64(index).readAll();
        builtin.debug.logAlwaysAIO(&buf, &.{ "    ", @tagName(target.cmd.kind), "\t", cmd_name, "\t", target.root, "\n" });
    }
}
fn setAllCommands(builder: *const build.Builder, cmd_mode: meta.Field(build.CompileCommand, "kind")) void {
    for (builder.targets.referAllDefined()) |*target| {
        target.cmd.kind = cmd_mode;
    }
}
fn execAllCommands(builder: *const build.Builder) !void {
    for (builder.targets.readAll()) |target| {
        builtin.assertNotEqual(u64, 0, try target.compile());
    }
}
pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: build.Allocator = try build.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: build.Builder.ArrayU = build.Builder.ArrayU.init(&allocator);
    array.increment(void, &allocator, .{ .bytes = 1024 * 1024 * 16 });
    defer array.deinit(&allocator);
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    if (args.len < 5) {
        builtin.debug.logAlways("Expected path to zig compiler, " ++
            "build root directory path, " ++
            "cache root directory path, " ++
            "global cache root directory path");
        sys.exit(2);
    }
    const zig_exe: [:0]const u8 = meta.manyToSlice(args[1]);
    const build_root: [:0]const u8 = meta.manyToSlice(args[2]);
    const cache_dir: [:0]const u8 = meta.manyToSlice(args[3]);
    const global_cache_dir: [:0]const u8 = meta.manyToSlice(args[4]);
    args = args[5..];
    var builder: build.Builder = .{
        .zig_exe = zig_exe,
        .build_root = build_root,
        .cache_dir = cache_dir,
        .global_cache_dir = global_cache_dir,
        .options = options,
        .args = args,
        .vars = vars,
        .allocator = &allocator,
        .array = &array,
    };
    try root.build(&builder);
    var index: u64 = 0;
    while (index != args.len) {
        const name: [:0]const u8 = meta.manyToSlice(args[index]);

        if (mem.testEqualMany(u8, name, "lib")) {
            setAllCommands(&builder, .lib);
            proc.shift(&args, index);
            continue;
        }
        if (mem.testEqualMany(u8, name, "obj")) {
            setAllCommands(&builder, .lib);
            proc.shift(&args, index);
            continue;
        }
        if (mem.testEqualMany(u8, name, "exe")) {
            setAllCommands(&builder, .exe);
            proc.shift(&args, index);
            continue;
        }
        if (mem.testEqualMany(u8, name, "run")) {
            setAllCommands(&builder, .run);
            proc.shift(&args, index);
            continue;
        }
        if (mem.testEqualMany(u8, name, "show")) {
            showAllCommands(&builder);
            return;
        }
        if (mem.testEqualMany(u8, name, "all")) {
            try execAllCommands(&builder);
            proc.shift(&args, index);
            continue;
        }
        index +%= 1;
    }
    index = 0;
    while (index != args.len) {
        const name: [:0]const u8 = meta.manyToSlice(args[index]);
        if (mem.testEqualMany(u8, name, "--")) {
            break;
        }
        for (builder.targets.readAll()) |target| {
            const cmd_name: []const u8 = target.cmd.name orelse continue;
            if (mem.testEqualMany(u8, name, cmd_name)) {
                builder.args = builder.args[index..];
                builtin.assertNotEqual(u64, 0, try target.compile());
                break;
            }
        } else {
            return commandNotFoundException(&builder, name);
        }
        index +%= 1;
    }
}
