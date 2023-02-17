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

pub const runtime_assertions: bool = true;

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
        //.lb_addr = 0x10000000000,
        //.up_addr = 0x40400000000,
        //.divisions = 16,
        //.options = .{ .thread_safe = true },
        .list = list,
    })}),
});
const list = meta.slice(mem.Arena, .{
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
const ThreadSpace = AddressSpace.SubSpace(0);

const PrintArray = mem.StaticString(4096);
const ThreadAllocatorSpec = struct {
    AddressSpace: type,
};
fn ThreadAllocator(comptime spec: ThreadAllocatorSpec) type {
    return struct {
        pub const allocator_spec: ThreadAllocatorSpec = spec;
    };
}

pub fn main() !void {
    var address_space: AddressSpace = .{};
    var thread_space: ThreadSpace = .{};

    comptime var thread_index: u8 = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try mem.static.acquire(ThreadSpace, &thread_space, thread_index);
    }
    thread_index = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        mem.static.release(ThreadSpace, &thread_space, thread_index);
    }

    var array: PrintArray = .{};

    array.writeAny(preset.reinterpret.fmt, .{ fmt.render(.{ .radix = 2, .omit_default_fields = false }, address_space), '\n' });
    array.writeAny(preset.reinterpret.fmt, .{ fmt.render(.{ .radix = 2, .omit_default_fields = false }, thread_space), '\n' });
    builtin.debug.write(array.readAll());
}
