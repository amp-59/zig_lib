pub const zig_lib = {};
pub const builtin = @import("builtin.zig");
pub const tab = @import("tab.zig");
pub const sys = @import("sys.zig");
pub const mem = @import("mem.zig");
pub const elf = @import("elf.zig");
pub const gen = @import("gen.zig");
pub const rng = @import("rng.zig");
pub const fmt = @import("fmt.zig");
pub const proc = @import("proc.zig");
pub const meta = @import("meta.zig");
pub const math = @import("math.zig");
pub const file = @import("file.zig");
pub const algo = @import("algo.zig");
pub const time = @import("time.zig");
pub const parse = @import("parse.zig");
pub const start = @import("start.zig");
pub const debug = @import("debug.zig");
pub const build = @import("build.zig");
pub const trace = @import("trace.zig");
pub const dwarf = @import("dwarf.zig");
pub const crypto = @import("crypto.zig");
pub const serial = @import("serial.zig");
pub const target = @import("target.zig");
pub const testing = @import("testing.zig");

pub const Target = target.Target;
comptime {
    _ = start;
}
