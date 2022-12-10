const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;

const default_errors: bool = !@hasDecl(@import("root"), "errors");

const move_spec = if (default_errors) .{
    .options = .{},
    .logging = logging,
} else .{
    .options = .{},
    .logging = logging,
    .errors = builtin.root.errors,
};
const map_spec = if (default_errors)
.{
    .options = .{},
    .logging = logging,
} else .{
    .options = .{},
    .logging = logging,
    .errors = builtin.root.errors,
};
const resize_spec = if (default_errors)
.{
    .logging = logging,
} else .{
    .logging = logging,
    .errors = builtin.root.errors,
};
const unmap_spec = if (default_errors)
.{
    .logging = logging,
} else .{
    .logging = logging,
    .errors = builtin.root.errors,
};
const advice_opts = .{ .property = .{ .dump = true } };
const advise_spec = if (default_errors)
.{
    .options = advice_opts,
    .logging = logging,
} else .{
    .options = advice_opts,
    .logging = logging,
    .errors = builtin.root.errors,
};

const logging = false;
const errors = null;

fn testLowSystemMemoryOperations() !void {
    var addr: u64 = 0x7000000;
    const end: u64 = 0x10000000;
    var len: u64 = end - addr;
    try meta.wrap(mem.map(map_spec, addr, len));
    try meta.wrap(mem.move(move_spec, addr, len, addr + len));
    addr += len;
    try meta.wrap(mem.resize(resize_spec, addr, len, len * 2));
    len *= 2;
    try meta.wrap(mem.advise(advise_spec, addr, len));
    try meta.wrap(mem.unmap(unmap_spec, addr, len));
}
pub fn main() !void {
    try meta.wrap(testLowSystemMemoryOperations());
}
