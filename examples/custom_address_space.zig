const zig_lib = @import("zig_lib");
const mem = zig_lib.mem;
const fmt = zig_lib.fmt;
const proc = zig_lib.proc;
const file = zig_lib.file;
const preset = zig_lib.preset;
const virtual = zig_lib.virtual;
const testing = zig_lib.testing;

pub usingnamespace proc.start;

const regular_address_space_with_two_subspaces = virtual.RegularAddressSpaceSpec{
    .label = "regular-4x5B",
    .lb_addr = 0,
    .ab_addr = 0,
    .xb_addr = 20,
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
            .ab_addr = 0,
            .xb_addr = 5,
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
