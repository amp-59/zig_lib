const top = @import("../zig_lib.zig");
const fmt = top.fmt;
const mem = top.mem;
const meta = top.meta;
const file = top.file;
const proc = top.proc;
const builtin = top.builtin;
const testing = top.testing;
pub usingnamespace proc.start;
pub const runtime_assertions: bool = true;
pub fn main() !void {
    try @import("./parse/float.zig").floatTestMain();
}
