const zl = @import("../zig_lib.zig");

const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const file = zl.file;
const spec = zl.spec;
const builtin = zl.builtin;

pub const AddressSpace = spec.address_space.regular_128;
pub usingnamespace zl.start;

const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = spec.allocator.logging.silent,
    .errors = spec.allocator.errors.noexcept,
});
const Array = Allocator.StructuredHolder(u8);

pub fn main() !void {
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator);
    defer array.deinit(&allocator);

    array.appendAny(spec.reinterpret.fmt, &allocator, .{
        "example ",
        fmt.ud64(@intFromPtr(&allocator)),
        " using dynamic memory\n",
    });

    builtin.debug.write(array.readAll(allocator));
}
