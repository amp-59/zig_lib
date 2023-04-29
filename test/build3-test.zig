const zig_lib = @import("../zig_lib.zig");
const mem = zig_lib.mem;
const file = zig_lib.file;
const spec = zig_lib.spec;
const builtin = zig_lib.builtin;

pub usingnamespace zig_lib.proc.start;

pub const logging_override = spec.logging.override.verbose;

const AddressSpace = mem.GenericDiscreteAddressSpace(.{
    .list = &.{
        .{ .lb_addr = 0x40000000, .up_addr = 0x100000000 },
    },
    .errors = spec.address_space.errors.noexcept,
    .logging = spec.address_space.logging.silent,
});
const BigAllocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .errors = spec.allocator.errors.noexcept,
    .logging = spec.allocator.logging.silent,
    .options = spec.allocator.options.small,
    .arena_index = 0,
});
const Allocator = mem.SimpleAllocator;

fn makeArgPtrs(allocator: *Allocator, args: [:0]u8) [][*:0]u8 {
    @setRuntimeSafety(false);
    var count: u64 = 0;
    for (args) |value| count +%= @boolToInt(value == 0);
    const ptrs: [][*:0]u8 = allocator.allocate([*:0]u8, count +% 1);
    var len: u64 = 0;
    var idx: u64 = 0;
    var pos: u64 = 0;
    while (idx != args.len) : (idx +%= 1) {
        if (args[idx] == 0) {
            ptrs[len] = args[pos..idx :0];
            len = len +% 1;
            pos = idx +% 1;
        }
    }
    ptrs[len] = builtin.zero([*:0]u8);
    return ptrs[0..len];
}
fn addArg(buf: [*]u8, arg: []const u8) u64 {
    @memcpy(buf, arg.ptr, arg.len);
    buf[arg.len] = 0;
    return arg.len +% 1;
}
pub fn main(_: anytype, vars: anytype) !void {
    var allocator: Allocator = .{};
    const tasks = @import("../top/build/tasks3.zig");
    const command_line = @import("../top/build/command_line3.zig");
    const build_cmd: tasks.BuildCommand = tasks.BuildCommand{
        .kind = .exe,
        .emit_bin = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3" } },
        .emit_asm = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3.s" } },
        .emit_llvm_ir = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3.ll" } },
        .emit_llvm_bc = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3.bc" } },
        .macros = &.{.{ .name = "NAME", .value = .{ .symbol = "true" } }},
        .dependencies = &.{ .{ .name = "zig_lib" }, .{ .name = "env" } },
        .modules = &.{ .{ .name = "zig_lib", .path = "zig_lib.zig" }, .{ .name = "env", .path = "zig-cache/env.zig" } },
        .mode = .ReleaseSmall,
        .main_pkg_path = builtin.buildRoot(),
    };
    var buf: [1024 * 1024]u8 = undefined;
    var len: u64 = 0;
    len = len +% addArg(&buf, builtin.zigExe());
    len = len +% addArg(buf[len..].ptr, "build-exe");
    len = len +% addArg(buf[len..].ptr, comptime builtin.buildRoot() ++ "/test/build3-test.zig");
    len = len +% command_line.buildWrite(&build_cmd, buf[len..].ptr);

    buf[len] = 0;
    const args: [][*:0]u8 = makeArgPtrs(&allocator, buf[0..len :0]);

    try file.execPath(.{}, builtin.zigExe(), args, vars);
}
