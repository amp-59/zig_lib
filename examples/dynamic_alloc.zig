const zig_lib = @import("../zig_lib.zig");

const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const file = zig_lib.file;
const spec = zig_lib.spec;
const builtin = zig_lib.builtin;

pub const AddressSpace = spec.address_space.regular_128;
pub usingnamespace proc.start;

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
        fmt.ud64(@ptrToInt(&allocator)),
        " using dynamic memory\n",
    });

    builtin.debug.write(array.readAll(allocator));
}
