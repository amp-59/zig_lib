const srg = @import("zig_lib");
const sys = srg.sys;
const mem = srg.mem;
const file = srg.file;
const builtin = srg.builtin;

comptime {
    _ = builtin;
}

const hello_world = "Hello, world!\n";

fn NTuple(comptime n: usize) type {
    return @TypeOf(@as(struct { u8 }, undefined) ** n);
}

pub export fn _start() void {
    @setAlignStack(16);
    if (false) {
        file.noexcept.write(2, hello_world);
    }
    if (false) {
        const x: []const u8 = (comptime mem.view("Hello, world!\n")).readAll();
        file.noexcept.write(2, x);
    }
    if (false) {
        var array: mem.StaticString(4096) = undefined;
        array.impl.ub_word = 0;
        array.writeAny(mem.follow_wr_spec, .{ "Hello", ",", " World", "!", "\n" });
        file.noexcept.write(2, array.readAll());
    }
    if (false) {
        var array: mem.StaticString(4096) = .{};
        array.undefineAll();
        array.writeMany("Hello, world!\n");
        file.noexcept.write(2, array.readAll());
    }
    if (true) {
        const S = struct {
            len: u64 = 0,
            auto: [256]u8 align(1) = undefined,
        };
        var s: S = .{};
        var z: S = .{};
        inline for (hello_world) |c, i| s.auto[i] = c;
        file.noexcept.write(2, z.auto[0..hello_world.len]);
    }
    sys.exit(0);
}
