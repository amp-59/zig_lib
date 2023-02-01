const root = @import("@build");
const srg = root.srg;
const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const file = srg.file;
const meta = srg.meta;
const preset = srg.preset;
const builder = srg.builder;
const testing = srg.testing;
const builtin = srg.builtin;

pub const AddressSpace = builder.AddressSpace;
pub const is_verbose: bool = true;
pub const is_correct: bool = false;
pub const is_silent: bool = true;

pub usingnamespace proc.start;

const Options = builder.GlobalOptions;
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
fn showAllCommands(ctx: builder.Context) void {
    builtin.debug.write("commands:\n");
    for (ctx.cmds.readAll()) |cmd| {
        var buf: [128 + 4096 + 512]u8 = undefined;
        builtin.debug.logAlwaysAIO(&buf, &.{ @tagName(cmd.cmd), "\t", cmd.name.?, "\t", cmd.root, "\n" });
    }
}
fn execAllCommands(ctx: builder.Context) !void {
    for (ctx.cmds.readAll()) |cmd| {
        builtin.assertNotEqual(u64, 0, try cmd.exec());
    }
}
pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: builder.Allocator = try builder.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: builder.Context.ArrayU = builder.Context.ArrayU.init(&allocator);
    array.increment(void, &allocator, .{ .bytes = 1024 * 1024 * 16 });
    defer array.deinit(&allocator);
    var args: [][*:0]u8 = args_in;
    const options: Options = proc.getOpts(Options, &args, opts_map);
    if (args.len < 5) {
        file.noexcept.write(2, "Expected path to zig compiler, " ++
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
    var ctx: builder.Context = .{
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
    try root.build(&ctx);
    const Cmd = @TypeOf(ctx.cmds.readOneAt(0).cmd);
    for (args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualMany(u8, name, "all")) {
            return execAllCommands(ctx);
        }
        if (mem.testEqualMany(u8, name, "show")) {
            showAllCommands(ctx);
        }
        inline for (@typeInfo(Cmd).Enum.fields) |field| {
            if (mem.testEqualMany(u8, name, field.name)) {
                for (ctx.cmds.referAllDefined()) |*cmd| cmd.cmd = @field(Cmd, field.name);
            }
        }
    }
    for (args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        for (ctx.cmds.readAll()) |cmd| {
            if (mem.testEqualMany(u8, name, cmd.name.?)) {
                builtin.assertNotEqual(u64, 0, try cmd.exec());
            }
        }
    }
    sys.exit(0);
}
