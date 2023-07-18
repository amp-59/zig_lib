const zl = @import("../zig_lib.zig");
const fmt = zl.fmt;
const mem = zl.mem;
const meta = zl.meta;
const file = zl.file;
const proc = zl.proc;
const builtin = zl.builtin;
const testing = zl.testing;
pub usingnamespace zl.start;
pub const runtime_assertions: bool = true;
pub fn main() !void {
    try @import("./parse/float.zig").floatTestMain();
}
