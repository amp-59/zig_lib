const root = @import("@build");

const srg = root.srg;

const mem = srg.mem;
const sys = srg.sys;
const proc = srg.proc;
const file = srg.file;
const preset = srg.preset;
const builder = srg.builder;
const builtin = srg.builtin;

pub const AddressSpace = builder.AddressSpace;
pub const is_verbose: bool = false;

pub usingnamespace proc.start;

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
    try root.build(&ctx);
    sys.exit(0);
}
