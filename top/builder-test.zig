const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const builder = @import("./builder.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = true;
pub const is_correct: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
});

const try_multi_threaded: bool = false;

const thread_spec = proc.CloneSpec{
    .errors = sys.clone_errors,
    .return_type = void,
    .options = .{},
};

const general_macros: builder.Macros = &.{
    .{ .name = "is_verbose", .value = .{ .constant = 0 } },
    .{ .name = "is_correct", .value = .{ .constant = 0 } },
    .{ .name = "build_root", .value = .{ .string = builtin.build_root.? } },
};
const parsedir_std_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = .{ .string = "std" } }};
const parsedir_lib_macros: builder.Macros = general_macros ++ [1]builder.Macro{.{ .name = "test_subject", .value = .{ .string = "lib" } }};

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: builtin.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: builder.Context.ArrayU = builder.Context.ArrayU.init(&allocator);
    var ctx: builder.Context = .{
        .zig_exe = builtin.zig_exe.?,
        .build_root = builtin.build_root.?,
        .cache_dir = builtin.cache_dir.?,
        .global_cache_dir = builtin.global_cache_dir.?,
        .options = .{},
        .args = args_in,
        .vars = vars,
        .allocator = &allocator,
        .array = &array,
    };
    var cmd: builder.BuildCmd = .{
        .ctx = &ctx,
        .root = "top/builder-test.zig",
        .cmd = .run,
        .name = "builder_test",
        .O = .ReleaseFast,
        .strip = true,
        .enable_cache = true,
        .global_cache_dir = null,
        .cache_dir = null,
        .stack = 8388608,
        .macros = general_macros,
        .packages = &.{
            .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
        },
    };
    _ = try cmd.allocateExec(&allocator);
}
