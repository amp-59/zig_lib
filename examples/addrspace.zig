const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const virtual = zl.virtual;
const testing = zl.testing;

pub usingnamespace zl.start;

const regular_address_space_with_two_subspaces = virtual.RegularAddressSpaceSpec{
    .label = "regular-4x5B",
    .lb_addr = 0,
    .up_addr = 20,
    .divisions = 4,
    .alignment = 1,
    .subspace = virtual.genericSlice(.{
        .{
            .label = "discrete-1x10B+1x3B",
            .list = &[2]mem.Arena{
                .{ .lb_addr = 7, .up_addr = 17 },
                .{ .lb_addr = 17, .up_addr = 20 },
            },
        },
        .{
            .label = "regular-5x1B",
            .lb_addr = 0,
            .up_addr = 5,
            .divisions = 5,
            .alignment = 1,
            .options = .{ .thread_safe = true },
        },
    }),
};
pub fn main() void {
    const SuperSpace = regular_address_space_with_two_subspaces.instantiate();
    const SubSpace0 = SuperSpace.SubSpace("discrete-1x10B+1x3B");
    const SubSpace1 = SuperSpace.SubSpace("regular-5x1B");

    meta.refAllDecls(SuperSpace, null);
    meta.refAllDecls(SubSpace0, null);
    meta.refAllDecls(SubSpace1, null);

    var super_space: SuperSpace = .{};
    var sub_space_0: SubSpace0 = .{};
    var sub_space_1: SubSpace1 = .{};

    const rspec = .{ .omit_default_fields = false, .radix = 2 };
    testing.printN(16384, .{
        fmt.render(rspec, super_space), '\n',
        fmt.render(rspec, sub_space_0), '\n',
        fmt.render(rspec, sub_space_1), '\n',
    });
}
