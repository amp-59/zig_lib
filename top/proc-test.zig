const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const file = @import("./file.zig");
const build = @import("./build.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

pub const runtime_assertions: bool = true;
pub const is_silent: bool = false;
pub const is_verbose: bool = false;

pub const AddressSpace = preset.address_space.exact_8;

const exec_spec: proc.ExecuteSpec = .{ .options = .{} };

fn makeArgs(buf: [:0]u8, any: anytype) [any.len + 2][*:0]u8 {
    var ptrs: [any.len +% 2][*:0]u8 = undefined;
    var off: u64 = 0;
    var len: u64 = 0;
    inline for (.{""} ++ any) |arg| {
        for (arg, 0..) |c, i| buf[off + i] = c;
        buf[off +% arg.len] = 0;
        ptrs[len] = buf[off .. off + arg.len :0];
        off +%= arg.len +% 1;
        len +%= 1;
    }
    return ptrs;
}
pub fn main(args: [][*:0]u8, vars: [][*:0]u8, aux: *const anyopaque) !void {
    const pid: u64 = try proc.fork(.{});
    if (pid == 0) {
        const build_args = .{
            .modules = &.{.{ .name = "zig_lib", .path = builtin.build_root.? ++ "/zig_lib.zig" }},
            .build_mode = .ReleaseSmall,
        };
        var address_space: AddressSpace = .{};
        var allocator: build.Allocator = try build.Allocator.init(&address_space);
        var array: build.Builder.ArrayU = build.Builder.ArrayU.init(&allocator);
        var builder: build.Builder = build.Builder.init(.{}, &allocator, &array, args, vars);

        const target: *build.Target = builder.addExecutable("exit_with_code", builtin.build_root.? ++ "/test/exit_with_code.zig", build_args);
        try target.build();

        var args_buf: [4096:0]u8 = undefined;
        try proc.exec(.{}, builtin.build_root.? ++ "/zig-out/bin/exit_with_code", &makeArgs(&args_buf, .{"88"}), vars);
    } else {
        var status: u32 = 0;
        builtin.assertEqual(u64, pid, try proc.waitPid(.{}, .{ .pid = pid }, &status));
        testing.printN(4096, .{ fmt.ud64(proc.Status.exitStatus(status)), '\n' });
    }
    {
        file.unlink(.{}, "./dump") catch {};
        const fd: u64 = try file.create(.{}, "./dump");
        var array: mem.StaticString(8192) = .{};
        array.writeMany(@intToPtr(*const [8192]u8, proc.auxiliaryValue(aux, .vdso_addr).?));
        try file.write(.{}, fd, array.readAll());
        file.close(.{ .errors = .{} }, fd);
        file.unlink(.{}, "./dump") catch {};
    }
}
