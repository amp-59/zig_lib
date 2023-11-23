const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub fn main() !void {
    zl.meta.refAllDecls(zl.crypto, &.{});
}
