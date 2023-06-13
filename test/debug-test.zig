const top = @import("../zig_lib.zig");
const mem = top.mem;
const sys = top.sys;
const fmt = top.fmt;
const exe = top.exe;
const proc = top.proc;
const mach = top.mach;
const time = top.time;
const meta = top.meta;
const file = top.file;
const spec = top.spec;
const debug = top.debug;
const build = top.build;
const builtin = top.builtin;
const testing = top.testing;

pub usingnamespace proc.start;
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

extern fn printCompileUnits() void;

pub fn main() !void {
    printCompileUnits();
    var allocator: mem.SimpleAllocator = .{};
    var dwarf: debug.DwarfInfo = debug.self(&allocator);
    try dwarf.scanAllCompileUnits(&allocator);
    const unit = try dwarf.findCompileUnit(@returnAddress());
    _ = unit;
}
