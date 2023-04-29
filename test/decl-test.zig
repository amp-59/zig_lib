const zig_lib = @import("../zig_lib.zig");

pub usingnamespace zig_lib.proc.start;

pub const AddressSpace = zig_lib.spec.address_space.regular_128;

pub fn main() void {
    _ = zig_lib.testing.refAllDecls(zig_lib.algo);
    _ = zig_lib.testing.refAllDecls(zig_lib.exe);
    _ = zig_lib.testing.refAllDecls(zig_lib.file);
    _ = zig_lib.testing.refAllDecls(zig_lib.meta);
    _ = zig_lib.testing.refAllDecls(zig_lib.proc);
    _ = zig_lib.testing.refAllDecls(zig_lib.lit);
    _ = zig_lib.testing.refAllDecls(zig_lib.mach);
    _ = zig_lib.testing.refAllDecls(zig_lib.sys);
    _ = zig_lib.testing.refAllDecls(zig_lib.time);
}
