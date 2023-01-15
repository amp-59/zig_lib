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
const builtin = @import("./builtin.zig");

pub usingnamespace proc.start;

pub const is_correct: bool = true;
pub const AddressSpace = preset.address_space.exact_8;

const ThreadSpace = mem.GenericDiscreteSubAddressSpace(.{
    .list = meta.slice(mem.Arena, .{
        .{ .lb_addr = 0x40000000, .up_addr = 0x41000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x41000000, .up_addr = 0x42000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x42000000, .up_addr = 0x43000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x43000000, .up_addr = 0x44000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x44000000, .up_addr = 0x45000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x45000000, .up_addr = 0x46000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x46000000, .up_addr = 0x47000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x47000000, .up_addr = 0x48000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x48000000, .up_addr = 0x49000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x49000000, .up_addr = 0x4a000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4a000000, .up_addr = 0x4b000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4b000000, .up_addr = 0x4c000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4c000000, .up_addr = 0x4d000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4d000000, .up_addr = 0x4e000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4e000000, .up_addr = 0x4f000000, .options = .{ .thread_safe = true } },
        .{ .lb_addr = 0x4f000000, .up_addr = 0x50000000, .options = .{ .thread_safe = true } },
    }),
}, AddressSpace);

const PrintArray = mem.StaticString(4096);

fn renderExactList(
    comptime SuperAddressSpace: type,
    comptime arena_index: SuperAddressSpace.Index,
    comptime thread_count: u8,
    comptime stack_size: u64,
) void {
    const render_spec: fmt.RenderSpec = .{
        .radix = 16,
        .omit_trailing_comma = true,
        .infer_type_names = true,
        .infer_type_names_recursively = true,
    };
    const lb_addr: u64 = SuperAddressSpace.low(arena_index);
    var list: [16]mem.Arena = undefined;
    var thread_index: u8 = 0;
    var offset: u64 = 0;
    var array: PrintArray = undefined;
    array.impl.ub_word = 0;
    while (thread_index != thread_count) : (thread_index += 1) {
        list[thread_index] = .{
            .lb_addr = lb_addr + offset,
            .up_addr = lb_addr + offset + stack_size,
            .options = .{ .thread_safe = true },
        };
        offset += list[thread_index].capacity();
    }
    array.writeAny(preset.reinterpret.fmt, meta.tuple(.{fmt.render(render_spec, list)}));
    file.noexcept.write(2, array.readAll());
}

const ThreadAllocatorSpec = struct {
    AddressSpace: type,
};
fn ThreadAllocator(comptime spec: ThreadAllocatorSpec) type {
    return struct {
        pub const allocator_spec: ThreadAllocatorSpec = spec;
    };
}

pub fn main() !void {
    comptime var address_space: AddressSpace = .{};
    var thread_space: ThreadSpace = address_space.reserve(ThreadSpace);

    comptime var thread_index: u8 = 0;
    inline while (thread_index != ThreadSpace.addr_spec.list.len) : (thread_index += 1) {
        try mem.static.acquire(.{}, ThreadSpace, &thread_space, thread_index);
    }
    thread_index = 0;
    inline while (thread_index != ThreadSpace.addr_spec.list.len) : (thread_index += 1) {
        try mem.static.release(.{}, ThreadSpace, &thread_space, thread_index);
    }
}
