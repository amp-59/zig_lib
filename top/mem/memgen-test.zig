const gen = @import("./gen.zig");
const mem = gen.mem;
const fmt = gen.fmt;
const proc = gen.proc;
const file = gen.file;
const meta = gen.meta;
const preset = gen.preset;
const serial = gen.serial;
const builtin = gen.builtin;
const testing = gen.testing;

const attr = @import("./attr.zig");

pub usingnamespace proc.start;

pub const render_spec = .{ .radix = 16 };
pub const logging_override: builtin.Logging.Override = preset.logging.override.verbose;

pub const runtime_assertions: bool = false;

const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.small,
});
const FAllocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 1,
    .logging = preset.allocator.logging.silent,
    .errors = preset.allocator.errors.noexcept,
    .options = preset.allocator.options.small,
});
const AddressSpace = mem.GenericRegularAddressSpace(.{
    .lb_offset = 0x40000000,
    .divisions = 128,
    .logging = preset.address_space.logging.silent,
    .errors = preset.address_space.errors.noexcept,
    .options = .{},
});

const Array = mem.StaticString(2 * 1024 * 1024);
pub fn main() !void {
    if (return) {}
    var address_space: AddressSpace = .{};
    var fallocator: FAllocator = FAllocator.init(&address_space);

    @setEvalBranchQuota(3000);
    const strings = try serial.deserialize3(attr.Specifier, &fallocator, gen.auxiliaryFile("spec_sets"));
    try serial.serialize3(attr.Specifier, &fallocator, gen.auxiliaryFile("spec_sets"), strings);
}
