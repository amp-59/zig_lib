const sys = @import("./sys.zig");
const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = false;

const default_errors: bool = !@hasDecl(@import("root"), "errors");
const logging = true;
const errors = null;

const move_spec = if (default_errors) .{
    .options = mem.move_opts,
    .logging = logging,
} else .{
    .options = mem.move_opts,
    .logging = logging,
    .errors = builtin.root.errors,
};
const map_spec = if (default_errors)
.{
    .options = mem.map_opts,
    .logging = logging,
} else .{
    .options = mem.map_opts,
    .logging = logging,
    .errors = builtin.root.errors,
};
const resize_spec = if (default_errors)
.{
    .options = mem.resize_opts,
    .logging = logging,
} else .{
    .options = mem.resize_opts,
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

const advise_spec = if (default_errors)
.{
    .options = .{ .property = .{ .dump = true } },
    .logging = logging,
} else .{
    .options = .{ .property = .{ .dump = true } },
    .logging = logging,
    .errors = builtin.root.errors,
};

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
