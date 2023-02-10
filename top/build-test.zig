const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const time = @import("./time.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const build = @import("./build.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const AddressSpace = preset.address_space.regular_128;
pub const is_verbose: bool = false;
pub const is_silent: bool = true;
pub const runtime_assertions: bool = false;

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

const general_macros: []const build.Macro = &.{
    .{ .name = "is_verbose", .value = .{ .constant = 0 } },
    .{ .name = "runtime_assertions", .value = .{ .constant = 0 } },
    .{ .name = "build_root", .value = .{ .string = builtin.build_root.? } },
};
const parsedir_std_macros: []const build.Macro = general_macros ++ [1]build.Macro{.{ .name = "test_subject", .value = .{ .string = "std" } }};
const parsedir_lib_macros: []const build.Macro = general_macros ++ [1]build.Macro{.{ .name = "test_subject", .value = .{ .string = "lib" } }};
const zig_lib: []const build.Pkg = &.{
    .{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" },
};

pub fn main(args_in: [][*:0]u8, vars: [][*:0]u8) !void {
    var address_space: builtin.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    var array: build.Builder.ArrayU = build.Builder.ArrayU.init(&allocator);
    var builder: build.Builder = .{
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
    const target: *build.Target = builder.addExecutable("builtin_test", "top/builtin-test.zig", .{
        .build_mode = .ReleaseFast,
        .macros = general_macros,
        .packages = zig_lib,
    });
    try target.build();
}
