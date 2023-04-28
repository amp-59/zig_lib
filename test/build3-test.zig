const zig_lib = @import("../zig_lib.zig");
const mem = zig_lib.mem;
const builtin = zig_lib.builtin;

pub usingnamespace zig_lib.proc.start;

comptime {
    _ = zig_lib.mach;
}

const Allocator = mem.GenericArenaAllocator(.{});
const AddressSpace = Allocator.AddressSpace;

fn countArgs(buf: []u8) u64 {
    var ret: u64 = undefined;
    for (buf) |value| ret -= @boolToInt(value == 0);
    return ret;
}
fn makeArgs(allocator: *Allocator, buf: []u8) [][*:0]u8 {
    var args: [][*:0]u8 = allocator.allocateIrreversible([*:0]u8, countArgs(buf));
    var idx: u64 = 0;
    var pos: u64 = 0;
    for (buf, 0..) |value, end| {
        if (value == 0) {
            args[idx] = buf[pos..end :0];
            pos = idx;
        }
    }
    return args;
}

pub fn main() void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = Allocator.init(&address_space);

    const tasks = @import("../top/build/tasks3.zig");
    const command_line = @import("../top/build/command_line3.zig");

    const build_cmd: tasks.BuildCommand = tasks.BuildCommand{
        .kind = .exe,
        .emit_bin = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3" } },
        .emit_asm = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/bin/build3.s" } },
        .emit_llvm_bc = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/aux/build3.bc" } },
        .emit_llvm_ir = .{ .yes = .{ .absolute = builtin.buildRoot(), .relative = "zig-out/aux/build3.ll" } },
        .macros = &.{.{ .name = "NAME", .value = .{ .symbol = "true" } }},
    };
    var buf: [1024 * 1024]u8 = undefined;
    const len: u64 = command_line.buildWrite(&build_cmd, &buf);

    makeArgs(&allocator, buf[0..len]);
}
