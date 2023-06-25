const top = @import("../zig_lib.zig");
const lit = top.lit;
const sys = top.sys;
const fmt = top.fmt;
const mem = top.mem;
const mach = top.mach;
const proc = top.proc;
const meta = top.meta;
const file = top.file;
const time = top.time;
const spec = top.spec;
const virtual = top.virtual;
const testing = top.testing;
const builtin = top.builtin;

pub usingnamespace proc.start;

pub const logging_override: builtin.Logging.Override = spec.logging.override.verbose;
pub const runtime_assertions: bool = true;

const discrete_list: []const mem.Arena = &.{
    .{ .lb_addr = 0x00040000000, .up_addr = 0x10000000000 },
    .{ .lb_addr = 0x10000000000, .up_addr = 0x20000000000 },
    .{ .lb_addr = 0x20000000000, .up_addr = 0x30000000000 },
    .{ .lb_addr = 0x30000000000, .up_addr = 0x40000000000 },
    .{ .lb_addr = 0x40000000000, .up_addr = 0x50000000000 },
    .{ .lb_addr = 0x50000000000, .up_addr = 0x60000000000 },
    .{ .lb_addr = 0x60000000000, .up_addr = 0x70000000000 },
    .{ .lb_addr = 0x70000000000, .up_addr = 0x80000000000 },
    .{ .lb_addr = 0x80000000000, .up_addr = 0x90000000000 },
};
const list: []const mem.Arena = &.{
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
};

const PrintArray = mem.StaticString(4096);
const three_state: type = enum(u8) {
    idle = 0,
    working = 1,
    done = 255,
};

fn testThreadSafeRegular() !void {
    const AddressSpace = mem.GenericDiscreteAddressSpace(.{
        .label = "super",
        .list = discrete_list,
        .subspace = &[_]meta.Generic{virtual.generic(.{
            .label = "thread",
            .val_type = three_state,
            .lb_addr = 0x10000000000,
            .up_addr = 0x40400000000,
            .divisions = 16,
            .options = .{ .thread_safe = true },
        })},
    });
    const ThreadSpace = AddressSpace.SubSpace(0);
    var thread_space: ThreadSpace = .{};
    var thread_index: u8 = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        if (thread_space.atomicExchange(thread_index, .idle, .working)) {}
    }
    thread_index = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicExchange(thread_index, .working, .done));
    }
    thread_index = 0;
    while (thread_index != ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicExchange(thread_index, .done, .idle));
    }
}
fn testThreadSafeDiscrete() !void {
    const AddressSpace = mem.GenericDiscreteAddressSpace(.{
        .label = "super",
        .list = discrete_list,
        .subspace = &[_]meta.Generic{virtual.generic(.{
            .label = "thread",
            .val_type = three_state,
            .list = list,
        })},
    });
    const ThreadSpace = AddressSpace.SubSpace(0);
    var thread_space: ThreadSpace = .{};
    comptime var thread_index: u8 = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        if (thread_space.atomicExchange(thread_index, .idle, .working)) {}
    }
    thread_index = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicExchange(thread_index, .working, .done));
    }
    thread_index = 0;
    inline while (thread_index != comptime ThreadSpace.addr_spec.count()) : (thread_index += 1) {
        try builtin.expect(thread_space.atomicExchange(thread_index, .done, .idle));
    }
}
fn testQuickThread() !void {
    const ThreadSpace = mem.GenericRegularAddressSpace(.{
        .label = "thread",
        .val_type = three_state,
        .lb_addr = 0x10000000000,
        .up_addr = 0x10000000000 +% (16 *% 1024 * 1024),
        .divisions = 16,
        .options = .{ .thread_safe = true },
    });
    var thread_space: ThreadSpace = .{};
    const S = struct {
        export fn getIt(ts: *ThreadSpace, thread_index: ThreadSpace.Index, y: u64) u64 {
            const ret: u64 = y;
            builtin.assert(ts.atomicExchange(thread_index, .working, .done));
            return ret;
        }
    };
    var stack_buf: [16384]u8 = undefined;
    var stack_addr: u64 = @intFromPtr(&stack_buf);
    if (thread_space.atomicExchange(0, .idle, .working)) {
        try proc.callClone(.{ .return_type = void }, stack_addr, stack_buf.len, &stack_addr, S.getIt, .{ &thread_space, 0, stack_addr });
    }
    try time.sleep(.{}, .{ .nsec = 100 });
}

pub fn main() !void {
    try meta.wrap(testThreadSafeRegular());
    try meta.wrap(testThreadSafeDiscrete());
    try meta.wrap(testQuickThread());
}
