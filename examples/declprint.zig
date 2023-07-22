const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const spec = zl.spec;
const debug = zl.debug;
const builtin = zl.builtin;

pub usingnamespace zl.start;

pub const AddressSpace = spec.address_space.exact_8;

pub fn main() !void {
    const Allocator = mem.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    var array: Allocator.StructuredHolder(u8) = Allocator.StructuredHolder(u8).init(&allocator);
    try array.appendAny(spec.reinterpret.fmt, &allocator, comptime fmt.render(.{
        .omit_container_decls = false,
        .inline_field_types = false,
        .infer_type_names = false,
    }, zl.file));
    debug.write(array.readAll(allocator));
}
