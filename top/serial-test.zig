const mem = @import("./mem.zig");
const proc = @import("./proc.zig");
const serial = @import("./serial.zig");
const preset = @import("./preset.zig");
const builtin = @import("./builtin.zig");
const testing = @import("./testing.zig");

pub usingnamespace proc.start;

const AddressSpace = preset.address_space.regular_128;
const Allocator = mem.GenericArenaAllocator(.{
    .AddressSpace = AddressSpace,
    .arena_index = 0,
});

const S = struct {
    t: u64 = 0,
    s: struct {
        s: *const struct {
            s0: []const u8,
            s1: [*:0]const u8,
        },
    },
    u: union(enum) {
        s: []const u8,
        ss: []const []const u8,
    },
};

pub fn main() !void {
    var address_space: AddressSpace = .{};
    var allocator: Allocator = try Allocator.init(&address_space);

    var ss: S = .{
        .t = 25,
        .u = .{
            .ss = &.{
                "one,two,three",
                "four,five,six",
            },
        },
        .s = .{
            .s = &.{
                .s0 = "seven,eight,nine",
                .s1 = "ten,eleven,twelve",
            },
        },
    };

    serial.length(S, ss);
    serial.length(@TypeOf(ss.s.s), ss.s.s);

    const s2 = serial.write(allocator, S, ss);

    serial.length(S, s2);
    serial.length(@TypeOf(s2.s.s), s2.s.s);

    const x = allocator.ub_addr - allocator.lb_addr;
    _ = x;
}
