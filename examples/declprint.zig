const zl = @import("../zig_lib.zig");
pub usingnamespace zl.start;
pub const AddressSpace = zl.mem.spec.address_space.exact_8;
const descr_spec: zl.fmt.TypeDescrFormatSpec = .{ .decls = true };
pub fn main() !void {
    const Allocator = zl.mem.dynamic.GenericArenaAllocator(.{
        .AddressSpace = AddressSpace,
        .arena_index = 0,
    });
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);
    defer allocator.deinit(&address_space);
    try zl.file.write(.{}, 1, zl.fmt.typeDescr(descr_spec, zl.file));
}
