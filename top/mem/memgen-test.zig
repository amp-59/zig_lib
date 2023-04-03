const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const file = gen.file;
const meta = gen.meta;
const spec = gen.spec;
const serial = gen.serial;
const builtin = gen.builtin;
const testing = gen.testing;

const config = @import("./config.zig");
const attr = @import("./attr.zig");

pub usingnamespace proc.start;

pub const render_spec = .{ .radix = 16 };
pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;

pub const runtime_assertions: bool = false;

const Array = mem.StaticString(2 * 1024 * 1024);

const DeserializeAllocator = config.DeserializeAllocator;
const SerializeAllocator = config.SerializeAllocator;

pub fn main() !void {
    var address_space: config.AddressSpace = .{};
    var allocator: DeserializeAllocator = DeserializeAllocator.init(&address_space);
    _ = allocator;
}
