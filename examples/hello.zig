const zl = @import("../zig_lib.zig");
const sys = zl.sys;
const mem = zl.mem;
const file = zl.file;
const builtin = zl.builtin;

const hello_world = "Hello, world!\n";

fn NTuple(comptime n: usize) type {
    return @TypeOf(@as(struct { u8 }, undefined) ** n);
}

pub export fn _start() void {
    @setAlignStack(16);
    if (true) {
        return builtin.debug.write(hello_world);
    }
    if (false) {
        const x: []const u8 = (comptime mem.view("Hello, world!\n")).readAll();
        builtin.debug.write(x);
    }
    if (false) {
        var array: mem.StaticString(4096) = undefined;
        array.impl.ub_word = 0;
        array.writeAny(mem.follow_wr_spec, .{ "Hello", ",", " World", "!", "\n" });
        builtin.debug.write(array.readAll());
    }
    if (true) {
        var array: mem.StaticString(4096) = undefined;
        array.undefineAll();
        array.writeMany("Hello, world!\n");
        builtin.debug.write(array.readAll());
    }
    if (false) {
        const S = struct {
            len: u64 = 0,
            auto: [256]u8 align(1) = undefined,
        };
        var s: S = .{};
        var z: S = .{};
        inline for (hello_world, 0..) |c, i| s.auto[i] = c;
        builtin.debug.write(z.auto[0..hello_world.len]);
    }
    builtin.proc.exit(0);
}
