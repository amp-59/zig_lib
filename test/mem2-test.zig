const zl = @import("../zig_lib.zig");
const proc = zl.proc;
const mem1 = zl.mem;
const builtin = zl.builtin;
const mem = struct {
    usingnamespace @import("../top/mem/ctn.zig");
};
pub usingnamespace zl.start;
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
