const zig_lib = @import("../zig_lib.zig");
const proc = zig_lib.proc;
const mem1 = zig_lib.mem;
const builtin = zig_lib.builtin;
const mem = struct {
    usingnamespace @import("../top/mem/ctn.zig");
};
pub usingnamespace proc.start;
pub fn main() void {
    if (false) {
        const Auto = mem.AutomaticStructuredReadWriteResize(.{
            .count = 256,
            .child = u8,
            .low_alignment = null,
            .sentinel = null,
        });
        var auto: Auto = undefined;
        auto.undefineAll();
        auto.writeMany("Hello, world!\n");
        builtin.debug.write(auto.readAll());
    } else {
        const Auto = mem1.StaticString(256);
        var auto: Auto = undefined;
        auto.undefineAll();
        auto.writeMany("Hello, world!\n");
        builtin.debug.write(auto.readAll());
    }
}
