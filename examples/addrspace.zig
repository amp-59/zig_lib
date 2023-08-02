const zl = @import("../zig_lib.zig");
const mem = zl.mem;
const fmt = zl.fmt;
const proc = zl.proc;
const meta = zl.meta;
const file = zl.file;
const virtual = zl.virtual;
const testing = zl.testing;

pub usingnamespace zl.start;

pub fn main() !void {
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

    {
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
    zl.debug.write(&[1]u8{0xa});
    const builder_like_address_space = virtual.RegularAddressSpaceSpec{
        .label = "builder_space",
        .lb_addr = 0x40000000,
        .up_addr = 0x80000000,
        .divisions = 1,
        .alignment = 4096,
        .subspace = virtual.genericSlice(.{
            .{
                .label = "DyLib",
                .list = &[1]mem.Arena{.{
                    .lb_addr = 0x40000000,
                    .up_addr = 0x50000000,
                }},
            },
            .{
                .label = "Heap",
                .lb_addr = 0x60000000,
                .up_addr = 0x70000000,
                .divisions = 16,
                .alignment = 4096,
                .options = .{ .thread_safe = false },
            },
            .{
                .label = "Stack",
                .lb_addr = 0x70000000,
                .up_addr = 0x80000000,
                .divisions = 16,
                .alignment = 4096,
                .options = .{ .thread_safe = true },
            },
        }),
    };
    {
        const SuperSpace = builder_like_address_space.instantiate();
        const SubSpace0 = SuperSpace.SubSpace("DyLib");
        const SubSpace1 = SuperSpace.SubSpace("Heap");
        const SubSpace2 = SuperSpace.SubSpace("Stack");

        meta.refAllDecls(SuperSpace, null);
        meta.refAllDecls(SubSpace0, null);
        meta.refAllDecls(SubSpace1, null);
        meta.refAllDecls(SubSpace2, null);

        var super_space: SuperSpace = .{};
        var sub_space_0: SubSpace0 = .{};
        var sub_space_1: SubSpace1 = .{};
        var sub_space_2: SubSpace2 = .{};

        try zl.debug.expect(!super_space.set(0));

        const rspec = .{ .omit_default_fields = false, .radix = 2 };
        testing.printN(16384, .{
            fmt.render(rspec, super_space), '\n',
            fmt.render(rspec, sub_space_0), '\n',
            fmt.render(rspec, sub_space_1), '\n',
            fmt.render(rspec, sub_space_2), '\n',
        });
    }
}
