//! Example program using zl:
pub const zl = @import("../zig_lib/zig_lib.zig");

const fmt = zl.fmt;
const debug = zl.debug;

pub fn main() void {
    debug.write(fmt.typeDescr(.{ .decls = true }, @import("std").builtin));
}
