const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const file = zl.file;
const debug = zl.debug;
const builtin = zl.builtin;

pub const AddressSpace = mem.spec.address_space.regular_128;
pub usingnamespace zl.start;

const Allocator = mem.dynamic.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
    .logging = mem.dynamic.spec.logging.silent,
    .errors = mem.dynamic.spec.errors.noexcept,
});
const Array = Allocator.StructuredHolder(u8);

pub fn main() !void {
    var address_space: Allocator.AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Array = Array.init(&allocator);
    defer array.deinit(&allocator);

    array.appendAny(mem.array.spec.reinterpret.fmt, &allocator, .{
        "example ",
        fmt.ud64(@intFromPtr(&allocator)),
        " using dynamic memory\n",
    });

    debug.write(array.readAll(allocator));
}
