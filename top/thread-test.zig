const lit = @import("./lit.zig");
const sys = @import("./sys.zig");
const fmt = @import("./fmt.zig");
const mem = @import("./mem.zig");
const mach = @import("./mach.zig");
const proc = @import("./proc.zig");
const meta = @import("./meta.zig");
const file = @import("./file.zig");
const time = @import("./time.zig");
const thread = @import("./thread.zig");
const preset = @import("./preset.zig");
const virtual = @import("./virtual.zig");
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = preset.logging.override.verbose;

const discrete_list: []const mem.Arena = meta.slice(mem.Arena, .{
    .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
    .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
    .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
    .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
    .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
    .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
    .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
    .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
    .{ .lb_addr = 0x80000000000, .up_addr = 0x90000000000 },
});
const list: []const mem.Arena = meta.slice(mem.Arena, .{
    .{ .lb_addr = 0x10000000000, .up_addr = 0x10100000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x10100000000, .up_addr = 0x10200000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x10200000000, .up_addr = 0x10300000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x10300000000, .up_addr = 0x10400000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x20000000000, .up_addr = 0x20100000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x20100000000, .up_addr = 0x20200000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x20200000000, .up_addr = 0x20300000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x20300000000, .up_addr = 0x20400000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x30000000000, .up_addr = 0x30100000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x30100000000, .up_addr = 0x30200000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x30200000000, .up_addr = 0x30300000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x30300000000, .up_addr = 0x30400000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x40000000000, .up_addr = 0x40100000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x40100000000, .up_addr = 0x40200000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x40200000000, .up_addr = 0x40300000000, .options = .{ .thread_safe = true } },
    .{ .lb_addr = 0x40300000000, .up_addr = 0x40400000000, .options = .{ .thread_safe = true } },
});

const PrintArray = mem.StaticString(4096);

fn testThreadSafeRegular() !void {
    const AddressSpace = mem.GenericDiscreteAddressSpace(.{
        .label = "super",
        .list = meta.slice(mem.Arena, .{
            .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
            .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
            .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
            .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
            .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
            .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
            .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
            .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
            .{ .lb_addr = 0x80000000000, .up_addr = 0x90000000000 },
        }),
        .subspace = meta.slice(meta.Generic, .{virtual.generic(.{
            .label = "thread",
            .tag_type = enum(u8) {
                unset = 0,
                working = 0b1010101,
                set = 255,
            },
            .lb_addr = 0x10000000000,
            .up_addr = 0x40400000000,
            .divisions = 16,
            .options = .{ .thread_safe = true },
            //.list = list,
        })}),
    });
    const ThreadSpace = AddressSpace.SubSpace(0);

    var address_space: AddressSpace = .{};
    _ = address_space;
    var thread_space: ThreadSpace = .{};

    var thread_index: u8 = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        if (thread_space.atomicTransform(thread_index, .unset, .set)) {}
    }
    thread_index = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicTransform(thread_index, .set, .working));
    }
    thread_index = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicTransform(thread_index, .working, .unset));
    }

    var array: PrintArray = .{};
    _ = array;
}
fn testThreadSafeDiscrete() !void {
    const AddressSpace = mem.GenericDiscreteAddressSpace(.{
        .label = "super",
        .list = discrete_list,
        .subspace = meta.slice(meta.Generic, .{virtual.generic(.{
            .label = "thread",
            .tag_type = enum(u8) {
                unset = 0,
                working = 1,
                set = 255,
            },
            .list = list,
        })}),
    });
    const ThreadSpace = AddressSpace.SubSpace(0);

    var address_space: AddressSpace = .{};
    _ = address_space;
    var thread_space: ThreadSpace = .{};

    comptime var thread_index: u8 = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        if (thread_space.atomicTransform(thread_index, .unset, .set)) {}
    }
    thread_index = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicTransform(thread_index, .set, .working));
    }
    thread_index = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicTransform(thread_index, .working, .unset));
    }

    var array: PrintArray = .{};
    _ = array;
}

pub fn main() !void {
    try meta.wrap(testThreadSafeDiscrete());
    try meta.wrap(testThreadSafeDiscrete());
}
