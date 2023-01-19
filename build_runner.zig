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

// zig fmt: off
const opts_map: []const Options.Map = meta.slice(proc.GenericOptions(Options), .{
    .{ .field_name = "build_mode", .long = "-Drelease-fast",    .assign = Options.yes, .descr = "speed++" },
    .{ .field_name = "build_mode", .long = "-Drelease-small",   .assign = Options.yes, .descr = "size--" },
    .{ .field_name = "build_mode", .long = "-Dreleae-safe",     .assign = Options.no,  .descr = "safety++" },
    .{ .field_name = "build_mode", .long = "-Ddebug",           .assign = Options.yes, .descr = "crashing++ " },
    .{ .field_name = "strip",      .long = "-fstrip",           .assign = Options.yes, .descr = "do not emit debug symbols" },
    .{ .field_name = "strip",      .long = "-fno-strip",        .assign = Options.no,  .descr = "emit debug symbols" },
}); // zig fmt: on

const Options = struct {
    build_mode: ?@TypeOf(builtin.zig.mode) = null,
    strip: bool = true,

    const yes = .{ .boolean = true };
    const no = .{ .boolean = false };
};

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: AddressSpace = .{};
    var allocator: builder.Allocator = try builder.Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: builder.Context.ArrayU = builder.Context.ArrayU.init(&allocator);
    defer array.deinit(&allocator);

    const args: [][*:0]u8 = args_in;
    var args_itr = proc.ArgsIterator.init(args);

    const zig_exe: [:0]const u8 = args_itr.readOne() orelse {
        file.noexcept.write(2, "Expected path to zig compiler\n");
        sys.exit(2);
    };
    const build_root: [:0]const u8 = args_itr.readOne() orelse {
        file.noexcept.write(2, "Expected build root directory path\n");
        sys.exit(2);
    };
    const cache_dir: [:0]const u8 = args_itr.readOne() orelse {
        file.noexcept.write(2, "Expected cache root directory path\n");
        sys.exit(2);
    };
    const global_cache_dir: [:0]const u8 = args_itr.readOne() orelse {
        file.noexcept.write(2, "Expected global cache root directory path\n");
        sys.exit(2);
    };

    var ctx: builder.Context = .{
        .zig_exe = zig_exe,
        .build_root = build_root,
        .cache_dir = cache_dir,
        .global_cache_dir = global_cache_dir,
        .args = args[4..],
        .vars = vars,
        .allocator = &allocator,
        .array = &array,
    };

    for (args[4..]) |arg| {
        const slice: [:0]const u8 = meta.manyToSlice(arg);
        if (mem.readAfterFirstEqualMany(u8, "-Dsmall", slice)) |mode| {
            file.noexcept.write(2, mode);
        }
        if (mem.readAfterFirstEqualMany(u8, "-Dfast", slice)) |mode| {
            file.noexcept.write(2, mode);
        }
        if (mem.readAfterFirstEqualMany(u8, "-Dsafe", slice)) |mode| {
            file.noexcept.write(2, mode);
        }
    }

    try root.build(&ctx);
    sys.exit(0);
}
