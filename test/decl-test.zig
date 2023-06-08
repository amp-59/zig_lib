const zig_lib = @import("../zig_lib.zig");

pub usingnamespace zig_lib.proc.start;

pub const logging_override: zig_lib.builtin.Logging.Override = zig_lib.spec.logging.override.verbose;
pub const AddressSpace = zig_lib.spec.address_space.exact_8;
const Allocator0 = zig_lib.mem.GenericArenaAllocator(.{
    .arena_index = 0,
    .AddressSpace = zig_lib.spec.address_space.regular_128,
});
const Allocator1 = zig_lib.mem.GenericArenaAllocator(.{
    .arena_index = 1,
    .AddressSpace = zig_lib.spec.address_space.exact_8,
});
const Builder = zig_lib.build.GenericNode(.{});
const render = struct {
    pub const UnionFormat = zig_lib.fmt.UnionFormat(.{}, union { one: u64, two: struct { u32, u32 } });
    pub const StructForm = zig_lib.fmt.UnionFormat(.{}, struct { one: u64, two: *u64, three: []u8 });
    pub const EnumFormat = zig_lib.fmt.UnionFormat(.{}, enum { one, two, three });
};
pub fn main() void {
    _ = zig_lib.testing.refAllDecls(zig_lib);
    _ = zig_lib.testing.refAllDecls(render.UnionFormat);
    _ = zig_lib.testing.refAllDecls(render.StructForm);
    _ = zig_lib.testing.refAllDecls(render.EnumFormat);
    _ = zig_lib.testing.refAllDecls(Builder);
    _ = zig_lib.testing.refAllDecls(Allocator0);
    _ = zig_lib.testing.refAllDecls(Allocator1);
}
