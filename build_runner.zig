const root = @import("@build");

const srg = root.srg;

const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const file = srg.file;
const meta = srg.meta;
const opts = srg.opts;
const preset = srg.preset;
const builder = srg.builder;
const builtin = srg.builtin;

pub const AddressSpace = builder.AddressSpace;
pub const is_verbose: bool = false;

pub usingnamespace proc.start;

const Options = builder.GlobalOptions;
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "build_mode", .long = "-Drelease-fast", .assign = Options.release_fast, .descr = "speed++" },
    .{ .field_name = "build_mode", .long = "-Drelease-small", .assign = Options.release_small, .descr = "size--" },
    .{ .field_name = "build_mode", .long = "-Drelease-safe", .assign = Options.release_safe, .descr = "safety++" },
    .{ .field_name = "build_mode", .long = "-Ddebug", .assign = Options.debug, .descr = "crashing++ " },
    .{ .field_name = "strip", .long = "-fstrip", .assign = Options.yes, .descr = "do not emit debug symbols" },
    .{ .field_name = "strip", .long = "-fno-strip", .assign = Options.no, .descr = "emit debug symbols" },
    .{ .field_name = "verbose", .long = "--verbose", .assign = Options.yes, .descr = "show compile commands when executing" },
});

 pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: builder.Allocator = try builder.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: builder.Context.ArrayU = builder.Context.ArrayU.init(&allocator);
    array.increment(void, &allocator, .{ .bytes = 16 * 1024 * 1024 });
    defer array.deinit(&allocator);
    var args: [][*:0]u8 = args_in;
    if (args.len < 4) {
        file.noexcept.write(2, "Expected path to zig compiler, " ++
            "build root directory path, " ++
            "cache root directory path, " ++
            "global cache root directory path");
        sys.exit(2);
    }
    const zig_exe: [:0]const u8 = meta.manyToSlice(args[0]);
    const build_root: [:0]const u8 = meta.manyToSlice(args[1]);
    const cache_dir: [:0]const u8 = meta.manyToSlice(args[2]);
    const global_cache_dir: [:0]const u8 = meta.manyToSlice(args[3]);
    args = args[4..];
    const options: Options = proc.getOpts(Options, &args, opts_map);
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
    for (args) |arg| {
        const name: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.testEqualMany(u8, name, "all")) {
            for (ctx.cmds.readAll()) |cmd| {
                builtin.assertNotEqual(u64, 0, try cmd.exec(vars));
            }
            return;
        }
        for (ctx.cmds.readAll()) |cmd| {
            if (cmd.name) |cmd_name| {
                if (mem.testEqualMany(u8, name, cmd_name)) {
                    builtin.assertNotEqual(u64, 0, try cmd.exec(vars));
                }
            }
        }
    }
    sys.exit(0);
}
